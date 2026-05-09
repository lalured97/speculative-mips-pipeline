module mips_pipeline(
    input logic clk,
    input logic reset
);

    // ============================================
    // PROGRAM COUNTER
    // ============================================

    logic [31:0] pc;
    logic [31:0] next_pc;

    // ============================================
    // INSTRUCTION MEMORY
    // ============================================

    logic [31:0] imem [0:31];
    logic [31:0] instr;

    integer i;

    initial begin

        // addi r1, r0, 1
        imem[0] = 32'h20010001;

        // addi r2, r0, 1
        imem[1] = 32'h20020001;

        // beq r1, r2, +2
        imem[2] = 32'h10220002;

        // WRONG PATH
        // addi r3, r0, 99
        imem[3] = 32'h20030063;

        // WRONG PATH
        // addi r4, r0, 88
        imem[4] = 32'h20040058;

        // CORRECT TARGET
        // addi r5, r0, 55
        imem[5] = 32'h20050037;

        // NOPs
        for(i = 6; i < 32; i = i + 1)
            imem[i] = 32'h00000000;
    end

    assign instr =
    (pc[6:2] < 32) ? imem[pc[6:2]] : 32'h00000000;

    // ============================================
    // REGISTER FILE
    // ============================================

    logic [31:0] regs [0:31];

    initial begin
        for(i = 0; i < 32; i = i + 1)
            regs[i] = 0;
    end

    // ============================================
    // PIPELINE REGISTERS
    // ============================================

    // IF/ID
    logic [31:0] ifid_instr;
    logic [31:0] ifid_pc;

    // ID/EX
    logic [31:0] idex_instr;
    logic [31:0] idex_pc;

    logic idex_pred_taken;

    // ============================================
    // DECODE SIGNALS
    // ============================================

    logic [5:0] opcode;

    logic [4:0] rs;
    logic [4:0] rt;

    logic [15:0] imm;

    logic [31:0] rs_val;
    logic [31:0] rt_val;

    assign opcode = idex_instr[31:26];

    assign rs = idex_instr[25:21];
    assign rt = idex_instr[20:16];

    assign imm = idex_instr[15:0];

    assign rs_val = regs[rs];
    assign rt_val = regs[rt];

    // ============================================
    // BRANCH PREDICTOR
    // ============================================

    logic [1:0] bht [0:15];

    logic pred_taken;

    logic [3:0] bht_index;

    initial begin
        for(i = 0; i < 16; i = i + 1)
            bht[i] = 2'b00; // weak taken
    end

    assign bht_index = pc[5:2];

    assign pred_taken = bht[bht_index][1];

    // ============================================
    // BRANCH RESOLUTION
    // ============================================

    logic actual_taken;
    logic mispredict;

    logic flush;

    logic [31:0] branch_target;

    assign branch_target =
        idex_pc + 4 +
        ({{14{idex_instr[15]}}, idex_instr[15:0], 2'b00});

    // actual branch result
    assign actual_taken =
        (opcode == 6'b000100) &&
        (rs_val == rt_val);

    // compare prediction vs actual
    assign mispredict =
        (opcode == 6'b000100) &&
        (actual_taken != idex_pred_taken);

    // ============================================
    // PERFORMANCE COUNTERS
    // ============================================

    integer total_branches;
    integer mispredictions;
    integer flush_cycles;

    // ============================================
    // NEXT PC LOGIC
    // ============================================

    always_comb begin

    // default sequential execution
    next_pc = pc + 4;

    // only redirect when branch instruction exists
    if(opcode == 6'b000100) begin

        // prediction was wrong
        if(mispredict) begin

            // branch actually taken
            if(actual_taken)
                next_pc = branch_target;

            // branch actually NOT taken
            else
                next_pc = idex_pc + 4;
        end
    end
end
    // ============================================
    // MAIN PIPELINE
    // ============================================

    always_ff @(posedge clk or posedge reset) begin

        if(reset) begin

            pc <= 32'd0;

            ifid_instr <= 0;
            ifid_pc <= 0;

            idex_instr <= 0;
            idex_pc <= 0;

            idex_pred_taken <= 0;

            total_branches <= 0;
            mispredictions <= 0;
            flush_cycles <= 0;

            flush <= 1'b0;
        end

        else begin

            // ====================================
            // UPDATE PC
            // ====================================

            pc <= next_pc;

            // ====================================
            // DEFAULT FLUSH
            // ====================================

            flush <= 0;

            // ====================================
            // NORMAL PIPELINE FLOW
            // ====================================

            ifid_instr <= instr;
            ifid_pc <= pc;

            idex_instr <= ifid_instr;
            idex_pc <= ifid_pc;

            idex_pred_taken <= pred_taken;

            // ====================================
            // ADDI
            // ====================================

            if(opcode == 6'b001000) begin

                regs[rt] <=
                    rs_val + {{16{imm[15]}}, imm};
            end

            // ====================================
            // BEQ
            // ====================================

            if(opcode == 6'b000100) begin

                total_branches <= total_branches + 1;

                // misprediction recovery
                if(mispredict) begin

                    flush <= 1;

                    flush_cycles <= flush_cycles + 1;

                    mispredictions <= mispredictions + 1;

                    // squash wrong-path instructions
                    ifid_instr <= 0;
                    idex_instr <= 0;
                end

                // predictor update
                if(actual_taken) begin

                    if(bht[idex_pc[5:2]] != 2'b11)
                        bht[idex_pc[5:2]]
                            <= bht[idex_pc[5:2]] + 1;
                end

                else begin

                    if(bht[idex_pc[5:2]] != 2'b00)
                        bht[idex_pc[5:2]]
                            <= bht[idex_pc[5:2]] - 1;
                end
            end
        end
    end

endmodule
