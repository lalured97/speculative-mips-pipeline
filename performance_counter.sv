// =============================================================================
// performance_counter.sv
// Branch Prediction Performance Analysis Unit
//
// Tracks:
//   1. total_branches      — all branch instructions executed
//   2. correct_predictions — predicted correctly (no flush)
//   3. mispredictions      — wrong prediction → flush triggered
//   4. flush_cycles        — total cycles wasted due to mispredictions
//   5. prediction_accuracy — (correct / total) as integer percentage (0–100)
// =============================================================================

module performance_counter (
    input  logic        clk,
    input  logic        rst_n,

    // Events
    input  logic        branch_executed,    // A branch instruction completed in EX
    input  logic        misprediction,      // Misprediction occurred
    input  logic        flush_active,       // Pipeline is currently flushing

    // Outputs — all counters
    output logic [15:0] total_branches,
    output logic [15:0] correct_predictions,
    output logic [15:0] mispredictions,
    output logic [15:0] flush_cycles,
    output logic [6:0]  prediction_accuracy  // Percentage 0–100
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_branches      <= 16'b0;
            correct_predictions <= 16'b0;
            mispredictions      <= 16'b0;
            flush_cycles        <= 16'b0;
        end else begin
            // Count every branch that resolves
            if (branch_executed) begin
                total_branches <= total_branches + 16'd1;
                if (misprediction) begin
                    mispredictions <= mispredictions + 16'd1;
                end else begin
                    correct_predictions <= correct_predictions + 16'd1;
                end
            end

            // Count cycles spent in flush recovery
            if (flush_active) begin
                flush_cycles <= flush_cycles + 16'd1;
            end
        end
    end

    // Prediction accuracy (integer division approximation)
    // accuracy = (correct_predictions * 100) / total_branches
    always_comb begin
        if (total_branches == 16'b0) begin
            prediction_accuracy = 7'd0;     // No branches yet
        end else begin
            prediction_accuracy = (correct_predictions[6:0] * 7'd100) / total_branches[6:0];
        end
    end

endmodule
