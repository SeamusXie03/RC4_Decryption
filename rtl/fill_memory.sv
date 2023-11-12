`default_nettype none
module fill_memory 
	(
		input wire clk, 
		input wire rst_n, 
		input wire start, 
		output wire is_write, 
		output wire [7:0] address_out, 
		output wire [7:0] data_out, 
		output wire finish
	);

	// mem_start, is_write, increment, finish
	typedef enum logic [5:0] {
		idle 				= 6'b00_0000,
		fill_data 			= 6'b01_1110,
		wait_write_finish	= 6'b10_0100,
		finish_state		= 6'b11_0001
	} statetype;

	statetype state;

	reg [7:0] count;
	wire increment, reset_count;

	assign address_out 	= count;
	assign data_out 	= count;

	assign is_write 		= state[2];
	assign increment 		= state[1];
	assign finish 			= state[0];

	// control (state transition)
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n) 
			state <= idle;
		else
			case (state)
				idle: 				state <= start ? fill_data : idle;
				fill_data: 			state <= wait_write_finish;
				wait_write_finish: 	state <= (count == 8'hFF) ? finish_state : fill_data;
				finish_state: 		state <= idle;
			endcase

	// datapath (a counter to fill and calculate the address)
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n) 
			count <= 8'h00;
		else if (finish)
			count <= 8'h00;
		else if (increment) 
			count <= count + 8'h01;
endmodule
`default_nettype wire
