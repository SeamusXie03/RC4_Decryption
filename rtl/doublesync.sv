`default_nettype none
module doublesync 
	(
		input wire clk,
		input wire rst_n,
		input wire indata,
		output wire outdata
	);

	reg reg1, reg2;
	
	always_ff @(posedge clk, negedge rst_n) 
		if (~rst_n) begin
			reg1 <= 1'b0;
		   reg2 <= 1'b0;
		end else begin
			reg1 <= indata;
		   reg2 <= reg1;
		end
	
	assign outdata = reg2;
endmodule
`default_nettype wire
