module clk2hz_tb();
    localparam CLOCK_PERIOD_NS = 20;

    reg r_clk = 0;
    wire o_clk;

    clk2hz MUT(.i_clk(r_clk), .o_hz_clk(o_clk));

    always #(CLOCK_PERIOD_NS/2) r_clk <= !r_clk;
endmodule
