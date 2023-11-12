`default_nettype none
module check_decrypted_message
	(
		input wire clk,
		input wire rst_n,
		input wire start,
		input wire restart,
		input wire [7:0] data_decrypted,
		output wire key_is_wrong,
		output wire finish
	);

	localparam Char_a = 8'd97;
	localparam Char_z = 8'd122;
	localparam Char_space = 8'd32;

	// key_is_wrong, finish
	typedef enum logic [2:0] {
		idle					= 3'b0_00,
		check_data				= 3'b1_00,
		finish_state			= 3'b0_01,
		interrupt_process		= 3'b0_11
	} statetype;

	statetype state;

	assign key_is_wrong = state[1];
	assign finish = state[0];

	wire invalid;
	assign invalid = ~(((data_decrypted >= Char_a) && (data_decrypted <= Char_z)) || (data_decrypted == Char_space));
	// if the byte is not in the ascii range, then it is invalid

	// a state machine to check each byte we wrote into the memory
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			state <= idle;
		else if (restart)
			state <= idle;
		else
			case (state)
				idle: state <= start ? check_data : idle;
				check_data: state <= invalid ? interrupt_process : finish_state;
				finish_state: state <= idle;
				interrupt_process: state <= interrupt_process;
				// once an error occur, restart the program with a new key
			endcase
endmodule
`default_nettype wire
