`default_nettype none
module shuffle_array
	(
		input wire clk, 
		input wire rst_n, 
		input wire start, 
		input wire [23:0] secret_key,
		input wire [7:0] data_in,
		output reg [7:0] data_out,
		output reg [7:0] address_out,
		output wire is_write, 		// when is_write & start_request == 1, wirte data_out to address_out
		output wire shuffle_finish
	);

	typedef enum logic [10:0] { 
		IDLE 			= 11'b000_0000_0000,	// initial state
		req_si_kb 		= 11'b100_0000_0100,	// request to read data s[i]
		register_si		= 11'b000_0001_0000,	// register s[i]
		compute_j		= 11'b000_0010_0000,	// compute J
		req_sj 			= 11'b010_0000_0000,	// request to read data s[j]
		register_sj		= 11'b000_0000_1000,	// register s[j]
		write_si_to_j 	= 11'b011_0000_0010,	// (swap) store s[i] to address J
		write_sj_to_i 	= 11'b100_1000_0010,	// (swap) store s[j] tp address I
		update_i 		= 11'b000_0100_0000,	// i++
		DONE 			= 11'b000_0000_0001		// send out "finish" singal
	} state_t;

	state_t state;

	wire select_I, select_J, select_s_i, select_s_j;
	wire address_I_en, address_J_en, s_i_en, s_j_en, key_byte_en;

	assign select_I			= state[10];
	assign select_J			= state[9];
	assign select_s_i		= state[8];
	assign select_s_j		= state[7];
	assign address_I_en		= state[6];
	assign address_J_en		= state[5];
	assign s_i_en			= state[4];
	assign s_j_en			= state[3];
	assign key_byte_en		= state[2];
	assign is_write			= state[1];
	assign shuffle_finish	= state[0];

	wire [1:0] key_index;	// secret_key[key_index]; 8bits mod 3 would have max 3bits result

	reg [7:0] address_I;
	reg [7:0] address_J;
	reg [7:0] s_i;
	reg [7:0] s_j;
	reg [7:0] key_byte;

	assign key_index 	= address_I % 8'd3;
	assign address_out 	= select_I ? address_I : (select_J ? address_J : 8'bx);
	assign data_out 	= select_s_i ? s_i : (select_s_j ? s_j : 8'bx);

	always_ff @(posedge clk, negedge rst_n) 
		if (~rst_n) 
			state <= IDLE;
		else 
			case (state)
				IDLE:			state <= start ? req_si_kb : state;
				req_si_kb:		state <= register_si;
				register_si: 	state <= compute_j;
				compute_j: 		state <= req_sj;
				req_sj: 		state <= register_sj;
				register_sj: 	state <= write_si_to_j;
				write_si_to_j: 	state <= write_sj_to_i;
				write_sj_to_i: 	state <= (address_I < 8'hFF) ? update_i : DONE;		// if we already reach the max adress, then go o state DONE
				update_i: 		state <= req_si_kb;
				DONE: 			state <= IDLE;
			endcase
	
	// below we are using register to stroe the data, and also clear them when we finish this time shuffle
	// also only update the data when enable signal is high (which including in state encoding)
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			address_I <= 8'h00; 
		else if (shuffle_finish)
			address_I <= 8'h00; 
		else if (address_I_en)
			address_I <= address_I + 8'h01;

	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			address_J <= 8'h00; 
		else if (shuffle_finish)
			address_J <= 8'h00; 
		else if (address_J_en)
			address_J <= address_J + s_i + key_byte;

	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			s_i <= 8'h00; 
		else if (shuffle_finish)
			s_i <= 8'h00; 
		else if (s_i_en)
			s_i <= data_in;

	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			s_j <= 8'h00; 
		else if (shuffle_finish)
			s_j <= 8'h00; 
		else if (s_j_en)
			s_j <= data_in;

	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			key_byte <= 8'h00; 
		else if (key_byte_en)
			case (key_index)
				2'd2: key_byte <= secret_key[7:0];
				2'd1: key_byte <= secret_key[15:8];
				2'd0: key_byte <= secret_key[23:16];
				default: key_byte <= key_byte;
			endcase
endmodule
`default_nettype wire
