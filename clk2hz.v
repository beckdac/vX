// module to divide system clock to Hz

module clk2hz
    (
        input   i_clk,
        output  o_hz_clk
    );

    reg [15:0] r_1count = 0;
    reg [7:0] r_2count = 0;
    reg r_hz_clk = 0;

    always @(posedge i_clk)
        begin
            if (r_1count < 65535)
                r_1count <= r_1count + 1;
            else
                begin
                    r_1count = 0;
                    if (r_2count < 255)
                        r_2count <= r_2count + 1;
                        if (r_2count >= 127)
                            r_hz_clk <= 1'b1;
                    else
                        begin
                            r_2count <= 0;
                            r_hz_clk <= 1'b0;
                        end
                end
        end

endmodule
