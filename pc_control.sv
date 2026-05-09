// =============================================================================
// pc_control.sv
// Program Counter Control Unit
//
// Manages PC updates for:
//   1. Normal sequential execution (PC + 4)
//   2. Speculative branch prediction (jump to predicted target)
//   3. Misprediction correction (flush + jump to correct PC)
//   4. Jump instructions (unconditional)
// =============================================================================

module pc_control (
    input  logic        clk,
    input  logic        rst_n,

    // Branch predictor interface
    input  logic        pred_taken,         // Predictor says: take this branch
    input  logic [31:0] pred_target,        // Predictor's target address

    // From decode stage: jump instruction
    input  logic        is_jump,            // Unconditional jump decoded
    input  logic [31:0] jump_target,        // Jump target address

    // From execute stage: branch resolution
    input  logic        branch_resolved,    // Branch result is known
    input  logic        actual_taken,       // Was branch actually taken?
    input  logic [31:0] correct_pc,         // Correct PC after resolution
    input  logic        prediction_was_taken, // What did we predict?

    // Stall signal from hazard unit
    input  logic        stall,

    // Current PC output
    output logic [31:0] pc_out,

    // Flush signal to pipeline
    output logic        flush,              // 1 = flush speculatively fetched instr
    output logic        mispredicted        // 1 = misprediction occurred (for perf counter)
);

    logic [31:0] pc_reg;
    logic [31:0] next_pc;

    // Misprediction detection
    assign mispredicted = branch_resolved && (actual_taken != prediction_was_taken);

    // Flush pipeline when misprediction detected
    assign flush = mispredicted;

    // PC selection priority:
    //   1. Misprediction correction (highest priority)
    //   2. Jump instruction
    //   3. Speculative branch (predicted taken)
    //   4. Sequential (PC + 4)
    always_comb begin
        if (mispredicted) begin
            next_pc = correct_pc;           // Redirect to correct path
        end else if (is_jump) begin
            next_pc = jump_target;          // Unconditional jump
        end else if (pred_taken) begin
            next_pc = pred_target;          // Speculative: jump to predicted target
        end else begin
            next_pc = pc_reg + 32'd4;       // Sequential execution
        end
    end

    // PC register update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'h0000_0000;        // Reset to address 0
        end else if (!stall) begin
            pc_reg <= next_pc;
        end
    end

    assign pc_out = pc_reg;

endmodule
