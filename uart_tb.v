// uart testbench, rx and tx via loopback


`timescale 10ns/10ns

module uart_tb();
    localparam CLOCK_PERIOD_NS = 20, CLKS_PER_BIT = 434, BIT_PERIOD = 43400;

    reg r_clk = 0;
    reg r_tx_byte_rdy = 0;
    wire w_tx_done;
    reg [7:0] r_tx_byte = 0;
    reg r_rx = 1;
    wire [7:0] w_rx_byte;

    task WRITE;
        input   [7:0] i_byte;
        integer i;
        begin
            r_rx <= 1'b0;
            #(BIT_PERIOD);
            #1000

            r_rx <= i_byte[0];
            #(BIT_PERIOD);
            r_rx <= i_byte[1];
            #(BIT_PERIOD);
            r_rx <= i_byte[2];
            #(BIT_PERIOD);
            r_rx <= i_byte[3];
            #(BIT_PERIOD);
            r_rx <= i_byte[4];
            #(BIT_PERIOD);
            r_rx <= i_byte[5];
            #(BIT_PERIOD);
            r_rx <= i_byte[6];
            #(BIT_PERIOD);
            r_rx <= i_byte[7];
            #(BIT_PERIOD);

            r_rx <= 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_TX_I1
        (
            .i_clk(r_clk),
            .i_tx_byte_rdy(r_tx_byte_rdy),
            .i_tx_byte(r_tx_byte),
            .o_tx_busy(),
            .o_tx(),
            .o_tx_done(w_tx_done)
        );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_I1
        (
            .i_clk(r_clk),
            .i_rx(r_rx),
            .o_rx_byte_rdy(),
            .o_rx_byte(w_rx_byte)
        );

    // toggle clock on the half period
    always #(CLOCK_PERIOD_NS/2) r_clk <= !r_clk;

    initial
        begin
            @(posedge r_clk);
            @(posedge r_clk);
            r_tx_byte <= 8'hAB;
            r_tx_byte_rdy <= 1'b1;
            @(posedge r_clk);
            r_tx_byte_rdy <= 1'b0;
            @(posedge w_tx_done);

            @(posedge r_clk);
            WRITE(8'h3F);
            @(posedge r_clk);

            if (w_rx_byte == 8'h3F)
                $display("tx/rx test passed");
            else
                $display("tx/rx test failed");
        end

endmodule
    
