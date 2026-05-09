// =============================================================================
// branch_predictor.sv
// 2-bit Saturating Counter Branch Predictor
// 
// States (2-bit FSM):
//   00 = Strongly Not Taken (SNT)
//   01 = Weakly Not Taken   (WNT)
//   10 = Weakly Taken       (WT)
//   11 = Strongly Taken     (ST)
//
// Uses a Branch History Table (BHT) indexed by lower PC bits.
// =============================================================================

module branch_predictor #(
    parameter BHT_SIZE   = 16,          // Number of BHT entries
    parameter INDEX_BITS = 4            // log2(BHT_SIZE)
)(
    input  logic        clk,
    input  logic        rst_n,

    // Prediction interface (IF stage)
    input  logic [31:0] pc_fetch,       // PC of instruction being fetched
    output logic        pred_taken,     // 1 = predict taken
    output logic [31:0] pred_target,    // Predicted branch target (from BTB)

    // Branch target buffer write (ID stage, when branch decoded)
    input  logic        btb_we,         // Write enable for BTB
    input  logic [31:0] btb_pc,         // PC of branch instruction
    input  logic [31:0] btb_target,     // Actual branch target

    // Update interface (EX stage, when branch resolves)
    input  logic        update_en,      // 1 = branch resolved, update predictor
    input  logic [31:0] update_pc,      // PC of resolved branch
    input  logic        actual_taken    // 1 = branch was actually taken
);

    // -------------------------------------------------------------------------
    // Branch History Table (BHT) — 2-bit saturating counters
    // -------------------------------------------------------------------------
    logic [1:0] bht [0:BHT_SIZE-1];

    // Branch Target Buffer (BTB) — stores predicted target addresses
    logic [31:0] btb_targets [0:BHT_SIZE-1];
    logic        btb_valid   [0:BHT_SIZE-1];

    // Index extraction
    logic [INDEX_BITS-1:0] fetch_idx;
    logic [INDEX_BITS-1:0] update_idx;
    logic [INDEX_BITS-1:0] btb_write_idx;

    assign fetch_idx     = pc_fetch[INDEX_BITS+1:2];   // Word-aligned: skip 2 LSBs
    assign update_idx    = update_pc[INDEX_BITS+1:2];
    assign btb_write_idx = btb_pc[INDEX_BITS+1:2];

    // -------------------------------------------------------------------------
    // Prediction logic (combinational)
    // -------------------------------------------------------------------------
    assign pred_taken  = (bht[fetch_idx][1] == 1'b1) && btb_valid[fetch_idx];
    assign pred_target = btb_targets[fetch_idx];

    // -------------------------------------------------------------------------
    // Update BHT on branch resolution
    // -------------------------------------------------------------------------
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BHT_SIZE; i++) begin
                bht[i]        <= 2'b01;    // Initialize to Weakly Not Taken
                btb_valid[i]  <= 1'b0;
                btb_targets[i]<= 32'b0;
            end
        end else begin
            // Update BTB when branch is decoded
            if (btb_we) begin
                btb_targets[btb_write_idx] <= btb_target;
                btb_valid[btb_write_idx]   <= 1'b1;
            end

            // Update BHT when branch resolves (2-bit saturating counter)
            if (update_en) begin
                case (bht[update_idx])
                    2'b00: bht[update_idx] <= actual_taken ? 2'b01 : 2'b00; // SNT -> WNT or stay
                    2'b01: bht[update_idx] <= actual_taken ? 2'b10 : 2'b00; // WNT -> WT or SNT
                    2'b10: bht[update_idx] <= actual_taken ? 2'b11 : 2'b01; // WT -> ST or WNT
                    2'b11: bht[update_idx] <= actual_taken ? 2'b11 : 2'b10; // ST -> stay or WT
                endcase
            end
        end
    end

endmodule
