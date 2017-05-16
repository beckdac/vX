module rxtester
	(
		input i_rx_byte_rdy,
		input [7:0] i_rx_byte,
		output o_led
	);
	
	reg r_led = 1'b1;
	
	always @(posedge i_rx_byte_rdy)
		begin
			if (i_rx_byte == 65)
				r_led = 1'b0;
			else
				r_led = 1'b1;
		end
	
	assign o_led = r_led;
	
endmodule