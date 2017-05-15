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
    reg r_tx_done = 1;
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
                                r_tx_done <= 1'b0;
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

                        if (r_count < (CLKS_PER_BIT-1))
                            begin
                                r_count <= r_count + 1;
                                r_state <= STATE_STOP;
                            end
                        else
                            begin
                                r_count = 0;
                                r_state = STATE_RESET;
                            end
                    end
                STATE_RESET:
                    begin
                        r_tx_done <= 1'b1;
                        r_tx_busy <= 1'b0;
                        r_state <= STATE_IDLE;
                    end

                default:
                    r_state <= STATE_IDLE;
            endcase
        end

    assign o_tx_busy = r_tx_busy;
    assign o_tx_done = r_tx_done;

endmodule // uart_tx
