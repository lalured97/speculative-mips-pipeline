module tb_mips_pipeline;

    logic clk;
    logic reset;

    mips_pipeline uut(
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_mips_pipeline);

        clk = 0;
        reset = 1;

        #20;
        reset = 0;

        #300;

        $finish;
    end

endmodule