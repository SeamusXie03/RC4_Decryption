`default_nettype none
module trap_edge 
	(
		input wire clk, 
		input wire reset, 
		input wire restart,
		input wire async_sig, 
		output wire trapped_edge
	);
	wire q1, q2;

	flip_flop f1(.clk(async_sig), .clr(reset), .restart(restart), .data_in(1'b1), .data_out(q1));
	flip_flop f2(.clk(clk), .clr(reset), .restart(restart), .data_in(q1), .data_out(q2));
	flip_flop f3(.clk(clk), .clr(reset), .restart(restart), .data_in(q2), .data_out(trapped_edge));
endmodule

module flip_flop (input wire clk, input wire clr, input wire restart, input wire data_in, output reg data_out);
	always_ff @(posedge clk, posedge clr) 
		if (clr) data_out <= 1'b0;
		else if (restart) data_out <= 1'b0;
		else data_out <= data_in;
endmodule
`default_nettype wire
