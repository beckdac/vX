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
