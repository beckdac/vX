module loopback 
	(
		input i_clk,
		input wire i_tx_done,
		input wire i_rx_byte_rdy,
		input wire [7:0] i_rx_byte,
		input wire i_fifo_full,
		input wire i_fifo_empty,
		input wire [7:0] i_fifo_q,
		output wire [7:0] o_fifo_data,
		output wire [7:0] o_tx_byte,
		output wire o_tx_byte_rdy
	);
	
	always @(posedge i_clk)
		begin
			if (!i_fifo_empty && i_tx_done)
				begin
					o_tx_byte <= 
				end
			if (!i_fifo_full && i_rx_byte_rdy)
				begin
					i_fifo_wrreq <= 1'b1
					i_fifo_data <= i_rx_byte
				end
		end
		
endmodule