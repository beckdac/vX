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

// uart rx

module uart_rx
    #(parameter CLKS_PER_BIT)
    (
        input   i_clk,
        input   i_rx,
        output  o_rx_byte_rdy,
        output  [7:0] o_rx_byte
    );

    // receiver states in one hot encoding
    localparam  STATE_IDLE=5'b00001, STATE_START=5'b00010, STATE_DATA=5'b00100, 
                STATE_STOP=5'b01000, STATE_RESET=5'b10000;

    // double registers
    reg r_rx_data_r = 1'b1;
    reg r_rx_data = 1'b1;

    // internals
    reg [13:0] r_count = 0;     // 14 bit number is 16384 max value counter counter
    reg [2:0] r_bit_idx = 0;
    reg [7:0] r_rx_byte = 0;
    reg r_rx_byte_rdy = 0;
    reg [4:0] r_state = STATE_IDLE;

    // double buffer to avoid metastbality issues
    always @(posedge i_clk)
        begin
            r_rx_data_r <= i_rx;
            r_rx_data <= r_rx_data_r;
        end

    // main state machine
    always @(posedge i_clk)
        begin
            case (r_state)
                STATE_IDLE:
                    begin
                        r_rx_byte_rdy <= 1'b0;
                        r_count = 0;
                        r_bit_idx = 0;

                        if (r_rx_data == 1'b0)
                            r_state = STATE_START;
                        else
                            r_state = STATE_IDLE;
                    end
                STATE_START:
                    begin
                        if (r_count == (CLKS_PER_BIT-1)/2)
                            begin
                                if (r_rx_data == 1'b0)
                                    begin
                                        r_count = 0;
                                        r_state = STATE_DATA;
                                    end
                                else // bad start
                                    r_state = STATE_IDLE;
                            end
                        else
                            begin
                                r_count = r_count + 1;
                                r_state = STATE_START;
                            end
                    end
                STATE_DATA:
                    begin
                        if (r_count < (CLKS_PER_BIT-1))
                            begin
                                r_count = r_count + 1;
                                r_state = STATE_DATA;
                            end
                        else
                            begin
                                r_count = 0;
                                r_rx_byte[r_bit_idx] <= r_rx_data;

                                if (r_bit_idx < 7)
                                    begin
                                        r_bit_idx = r_bit_idx + 1;
                                        r_state = STATE_DATA;
                                    end
                                else
                                    begin
                                        r_bit_idx = 0;
                                        r_state = STATE_STOP;
                                    end
                            end
                    end
                STATE_STOP:
                    begin
                        if (r_count < (CLKS_PER_BIT-1))
                            begin
                                r_count = r_count + 1;
                                r_state = STATE_STOP;
                            end
                        else
                            begin
                                r_rx_byte_rdy = 1'b1;
                                r_count = 0;
                                r_state = STATE_RESET;
                            end
                    end
                // the r_rx_byte_rdy will have been high for one clock.
                STATE_RESET:
                    begin
                        r_state = STATE_IDLE;
                        r_rx_byte_rdy = 1'b0;
                    end
                default:
                    r_state <= STATE_IDLE;
            endcase
        end

    assign o_rx_byte_rdy = r_rx_byte_rdy;
    assign o_rx_byte = r_rx_byte;

endmodule // uart_rx

// uart tx

module uart_tx
    #(parameter CLKS_PER_BIT)
    (
        input   i_clk,
        input   i_tx_byte_rdy,
        input   [7:0] i_tx_byte,
        output  o_tx_busy,
        output  reg o_tx,
        output  o_tx_done
    );

    localparam  STATE_IDLE=5'b00001, STATE_START=5'b00010, STATE_DATA=5'b00100,
                STATE_STOP=5'b01000, STATE_RESET=5'b10000;

    reg [13:0] r_count = 0;             // 14 bit number is 16384 max value counter counter
    reg [2:0] r_bit_idx = 0;
    reg [7:0] r_tx_byte;
    reg r_tx_done = 0;
    reg r_tx_busy = 0;
    reg [4:0] r_state = STATE_IDLE;

    always @(posedge i_clk)
        begin
            case (r_state)
                STATE_IDLE:
                    begin
                        o_tx <= 1'b1;
                        r_tx_done <= 1'b1;
                        r_count <= 0;
                        r_bit_idx <= 0;

                        if (i_tx_byte_rdy == 1'b1)
                            begin
                                r_tx_busy <= 1'b1;
                                r_tx_byte <= i_tx_byte;
                                r_state <= STATE_START;
                            end
                        else
                            r_state <= STATE_IDLE;
                    end
                STATE_START:
                    begin
                        o_tx <= 1'b0;

                        if (r_count < (CLKS_PER_BIT-1))
                            begin
                                r_count <= r_count + 1;
                                r_state <= STATE_START;
                            end
                        else
                            begin
                                r_count <= 0;
                                r_state <= STATE_DATA;
                            end
                    end
                STATE_DATA:
                    begin
                        o_tx <= r_tx_byte[r_bit_idx];

                        if (r_count < (CLKS_PER_BIT-1))
                            begin
                                r_count <= r_count + 1;
                                r_state <= STATE_DATA;
                            end
                        else
                            begin
                                r_count <= 0;

                                if (r_bit_idx < 7)
                                    begin
                                        r_bit_idx <= r_bit_idx + 1;
                                        r_state <= STATE_DATA;
                                    end
                                else
                                    begin
                                        r_bit_idx <= 0;
                                        r_state <= STATE_STOP;
                                    end
                            end
                    end
                STATE_STOP:
                    begin
                        o_tx <= 1'b1;

                        if (r_count <- (CLKS_PER_BIT-1))
                            begin
                                r_count <= r_count + 1;
                                r_state <= STATE_STOP;
                            end
                        else
                            begin
                                r_tx_done <= 1'b1;
                                r_tx_busy <= 1'b1;
                                r_count = 0;
                                r_state = STATE_RESET;
                            end
                    end
                STATE_RESET:
                    begin
                        r_tx_done <= 1'b1;
                        r_state <= STATE_IDLE;
                    end

                default:
                    r_state <= STATE_IDLE;
            endcase
        end

    assign o_tx_busy = r_tx_busy;
    assign o_tx_done = r_tx_done;

endmodule // uart_tx

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

            for (i=0; i < 8; i=i+1)
                begin
                    r_rx <= i_byte[i];
                    #(BIT_PERIOD);
                end

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
    