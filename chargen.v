module chargen
	(
		input	i_clk,
		input i_tx_rdy,
		output reg [7:0] o_char = 33,
		output reg o_char_rdy = 0
	);
	
	always @(posedge i_clk)
		begin
			if (i_tx_rdy == 1)
				begin
					if (o_char == 126)
						o_char <= 33;
					else
						o_char <= char + 1;
					o_char_rdy = 1;
				end
			else
				o_char_rdy = 0;
		end

endmodule	