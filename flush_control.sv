// =============================================================================
// flush_control.sv
// Pipeline Flush Controller
//
// On misprediction:
//   - Inserts NOP bubbles into IF/ID and ID/EX pipeline registers
//   - Tracks how many cycles are lost (misprediction penalty)
//   - The "squashed" instructions are the speculatively fetched wrong-path instr
//
// Pipeline stages: IF -> ID -> EX -> MEM -> WB
// On flush: IF/ID reg and ID/EX reg are cleared (turned into NOPs/bubbles)
// =============================================================================

module flush_control (
    input  logic clk,
    input  logic rst_n,

    // Flush trigger from pc_control
    input  logic flush_in,              // 1 = misprediction detected, flush now

    // Outputs: bubble injection signals for each pipeline register
    output logic flush_IF_ID,           // Flush the IF/ID pipeline register
    output logic flush_ID_EX,           // Flush the ID/EX pipeline register

    // Penalty tracking
    output logic [7:0]  flush_cycle_count,  // Cycles spent flushing (for perf counter)
    output logic        flushing            // 1 = currently in flush state
);

    // Flush takes exactly 2 cycles (clear 2 pipeline stages)
    // Cycle 1: Flush signal arrives — inject bubble into ID/EX
    // Cycle 2: Stale IF/ID is also cleared
    
    logic [1:0] flush_state;    // 2-bit FSM for flush sequencing
    logic [7:0] penalty_count;

    localparam IDLE    = 2'b00;
    localparam FLUSH1  = 2'b01;   // First flush cycle
    localparam FLUSH2  = 2'b10;   // Second flush cycle

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flush_state   <= IDLE;
            penalty_count <= 8'b0;
        end else begin
            case (flush_state)
                IDLE: begin
                    if (flush_in) begin
                        flush_state   <= FLUSH1;
                        penalty_count <= penalty_count + 8'd1;
                    end
                end
                FLUSH1: begin
                    flush_state   <= FLUSH2;
                    penalty_count <= penalty_count + 8'd1;
                end
                FLUSH2: begin
                    flush_state <= IDLE;    // Flush complete
                end
                default: flush_state <= IDLE;
            endcase
        end
    end

    // Combinational outputs based on flush state
    always_comb begin
        case (flush_state)
            IDLE: begin
                flush_IF_ID = flush_in;     // Start immediately when flush arrives
                flush_ID_EX = flush_in;
                flushing    = flush_in;
            end
            FLUSH1: begin
                flush_IF_ID = 1'b1;
                flush_ID_EX = 1'b1;
                flushing    = 1'b1;
            end
            FLUSH2: begin
                flush_IF_ID = 1'b1;
                flush_ID_EX = 1'b0;
                flushing    = 1'b1;
            end
            default: begin
                flush_IF_ID = 1'b0;
                flush_ID_EX = 1'b0;
                flushing    = 1'b0;
            end
        endcase
    end

    assign flush_cycle_count = penalty_count;

endmodule
