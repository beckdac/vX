module status
    (
        input   i_clk,
        output  reg o_hz_clk
    );

    reg [31:0] r_count; 

    always @(posedge i_clk) begin
        if (r_count <= 25000000)
            begin
                r_count <= r_count + 1;
            end
        else
            begin
                r_count <= 0;
                o_hz_clk <= ~o_hz_clk;
            end
    end
endmodule
