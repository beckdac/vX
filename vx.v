// uart testbench, rx and tx via loopback


`timescale 10ns/10ns

module vx
    (
        input wire i_clk,
        input wire i_rx,
        output wire o_tx,
        output wire o_tx_busy
    );

    wire w_tx_byte_rdy;
    wire [7:0] w_tx_byte;
    //wire w_tx_busy; tied to led instead
    wire w_tx_done;

    wire w_rx_byte_rdy;
    wire [7:0] w_rx_byte;

    uart UART_I1 
        (
            .i_clk(i_clk),
            .i_rx(i_rw),
            .o_tx(o_tx),
            .i_tx_byte_rdy(w_tx_byte_rdy),
            .i_tx_byte(w_tx_byte),
            .o_tx_busy(o_tx_busy),
            .o_tx_done(w_tx_done),
            .o_rx_byte_rdy(w_rx_byte_rdy),
            .o_rx_byte(w_rx_byte)
        );

    fifo LOOPFIFO
        (
            .clk(i_clk),
            .rst(),
            .buf_in(w_rx_byte),
            .buf_out(w_tx_byte),
            .wr_en(w_rx_byte_rdy),
            .rd_en(w_tx_byte_rdy),
            .buf_empty(),
            .buf_full(),
            .fifo_counter()
        );

endmodule
