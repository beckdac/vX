module loopback
    (
        input i_clk,
        input i_rx_byte_rdy,
        input [7:0] i_rx_byte,
        output o_tx_byte_rdy,
        output [7:0] o_tx_byte
    );

    reg r_tx_byte_rdy;
    reg [7:0] r_tx_byte;
    
    always @(i_rx_byte_rdy)
        begin
            r_tx_byte <= i_rx_byte;
            r_tx_byte_rdy = i_rx_byte_rdy;
        end

    assign o_tx_byte_rdy = r_tx_byte_rdy;
    assign o_tx_byte = r_tx_byte;
    
endmodule
