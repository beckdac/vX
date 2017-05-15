// uart testbench, rx and tx via loopback

module uart
    (
        input wire i_clk,
        input wire i_rx,
        output wire o_tx,

        input wire i_tx_byte_rdy,
        input wire [7:0] i_tx_byte,
        output wire o_tx_busy,
        output wire o_tx_done,

        output wire o_rx_byte_rdy,        
        output wire [7:0] o_rx_byte
    );
    // setup for 115200 baud at 50,000,000 Hz
    localparam CLOCK_PERIOD_NS = 20, CLKS_PER_BIT = 434, BIT_PERIOD = 43400;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_TX_I1
        (
            .i_clk(i_clk),
            .i_tx_byte_rdy(i_tx_byte_rdy),
            .i_tx_byte(i_tx_byte),
            .o_tx_busy(o_tx_busy),
            .o_tx(o_tx),
            .o_tx_done(o_tx_done)
        );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_I1
        (
            .i_clk(i_clk),
            .i_rx(i_rx),
            .o_rx_byte_rdy(o_rx_byte_rdy),
            .o_rx_byte(o_rx_byte)
        );

endmodule
  
