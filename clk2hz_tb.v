module clk2hz_tb();
    localparam CLOCK_PERIOD_NS = 20;

    reg r_clk = 0;
    reg o_clk = 0;

    clks2hz MUT(.i_clk(r_clk), o_hz_clk(o_clk));

    always #(CLOCK_PERIOD_NS/2) r_clk <= !r_clk;
endmodule
