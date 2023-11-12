`default_nettype none
module decryptMessageByte 
	(
		input wire clk,
		input wire rst_n,
		input wire start,
		input wire key_is_wrong,
		input wire [7:0] encrypted_input,
		input wire [7:0] data_from_s,
		output wire is_write_s, 
		output reg [7:0] address_out_s, 
		output reg [7:0] data_to_s, 
		output wire [4:0] address_out_enc,
		output wire [7:0] decrypted_output,
		output wire [4:0] address_out_dec,
		output wire decrypted_wren,
		output wire finish
	);

	localparam NUM_INDEX = 3;
	localparam NUM_REGISTER = 3;

	wire [7:0] address_f;


	// address bus in generate
	reg [7:0] address [NUM_INDEX-1:0];
	wire [7:0] address_i = address[2];
	wire [7:0] address_j = address[1];
	wire [4:0] address_k = address[0];
	// right operand in generate
	wire [7:0] right_op [NUM_INDEX-1:0];


	// memory bus in generate
	reg [7:0] register [NUM_REGISTER-1:0];
	wire [7:0] s_i = register[2];
	wire [7:0] s_j = register[1];
	wire [7:0] f = register[0];

	// decrypted_wren, start_request_s, is_write_s, 
	// select_address_i, select_address_j, select_address_f, 
	// select_si, select_sj, 
	// update_en_si, update_en_sj, update_en_f, 
	// update_address_en_i, update_address_en_j, update_address_en_k, finish
	typedef enum logic [17:0] {
		idle 					= 18'b0000_00_0000_0000_0000,
		update_address_i 		= 18'b0001_00_0000_0000_1000,
		read_si 				= 18'b0010_00_1000_0000_0000,
		register_si 			= 18'b0011_00_1000_0100_0000,
		update_address_j		= 18'b0100_00_0000_0000_0100,
		read_sj 				= 18'b0101_00_0100_0000_0000,
		register_sj 			= 18'b0110_00_0100_0010_0000,
		write_si_to_j 			= 18'b0111_01_0101_0000_0000,
		write_sj_to_i			= 18'b1001_01_1000_1000_0000,
		read_f					= 18'b1011_00_0010_0000_0000,
		register_f				= 18'b1100_00_0010_0001_0000,
		write_decrypted_data	= 18'b1101_10_0000_0000_0010,
		finish_state			= 18'b1110_00_0000_0000_0001
	} statetype;

	statetype state;

	wire update_en_si, update_en_sj, update_en_f;
	wire update_address_en_i, update_address_en_j, update_address_en_k;
	wire select_address_i, select_address_j, select_address_f; 
	wire select_si, select_sj; 

	assign decrypted_wren 		= state[13];
	assign is_write_s			= state[12]; 
	assign select_address_i		= state[11];	
	assign select_address_j		= state[10];
	assign select_address_f		= state[9]; 
	assign select_si			= state[8]; 
	assign select_sj			= state[7]; 
	assign update_en_si			= state[6];
	assign update_en_sj			= state[5];
	assign update_en_f			= state[4]; 
	assign update_address_en_i	= state[3];
	assign update_address_en_j	= state[2]; 
	assign update_address_en_k	= state[1]; 
	assign finish				= state[0];

	// the encrypted_input is gurrented to be unchanged by the time we cares
	// about it
	assign decrypted_output = f ^ encrypted_input;
	assign address_out_enc = address_k;
	assign address_out_dec = address_k;
	assign address_f = s_i + s_j;

	// state transition block
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n) 
			state <= idle;
		else if (key_is_wrong)
			state <= finish_state;
		else
			case (state)
				idle: 					state <= start ? update_address_i : idle;
				update_address_i: 		state <= read_si;
				read_si: 				state <= register_si;
				register_si: 			state <= update_address_j;
				update_address_j:		state <= read_sj;
				read_sj: 				state <= register_sj;
				register_sj: 			state <= write_si_to_j;
				write_si_to_j: 			state <= write_sj_to_i;
				write_sj_to_i:			state <= read_f;
				read_f:					state <= register_f;
				register_f:				state <= write_decrypted_data;
				write_decrypted_data:	state <= (address_k == 5'd31) ? finish_state : update_address_i;
				finish_state: 			state <= idle;
			endcase

	// enabler bus
	wire [NUM_REGISTER-1:0] update_data_en;
	assign update_data_en = {update_en_si, update_en_sj, update_en_f};
	genvar j;
	generate
		for (j = 0; j < NUM_REGISTER; j++) begin: generate_data_register
			always_ff @(posedge clk, negedge rst_n)
				if (~rst_n)
					register[j] <= 8'b0;
				else if (finish) 
					register[j] <= 8'b0;
				else if (update_data_en[j])
					register[j] <= data_from_s;
		end
	endgenerate



	// enabler bus
	wire [NUM_INDEX-1:0] update_address_en;
	assign update_address_en = {update_address_en_i, update_address_en_j, update_address_en_k};
	assign right_op[2] = 8'b1;
	assign right_op[1] = s_i;
	assign right_op[0] = 8'b1;
	genvar i;
	generate 
		for (i = 0; i < NUM_INDEX; i++) begin: generate_address_register
			always_ff @(posedge clk, negedge rst_n)
				if (~rst_n)
					address[i] <= 8'b0;
				else if (finish) 
					address[i] <= 8'b0;
				else if (update_address_en[i])
					address[i] <= address[i] + right_op[i];
		end
	endgenerate

	// they won't occur at the same time, and they are in the state encoding
	always_comb
		case ({select_address_i, select_address_j, select_address_f})
			3'b100: address_out_s = address_i;
			3'b010: address_out_s = address_j;
			3'b001: address_out_s = address_f;
			default: address_out_s = 8'b0;
		endcase
	
	// they won't occur at the same time, and they are in the state encoding
	always_comb
		case ({select_si, select_sj})
			2'b10: data_to_s = s_i;
			2'b01: data_to_s = s_j;
			default: data_to_s = 8'b0;
		endcase
endmodule
`default_nettype wire
