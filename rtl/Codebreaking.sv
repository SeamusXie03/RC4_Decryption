`default_nettype none
module Codebreaking 
	(
		input wire CLOCK_50, 
		input wire [3:0] KEY, 
		input wire [9:0] SW,
		output wire [9:0] LEDR, 
		output wire [6:0] HEX0, 
		output wire [6:0] HEX1, 
		output wire [6:0] HEX2,
		output wire [6:0] HEX3, 
		output wire [6:0] HEX4,	
		output wire [6:0] HEX5
	); 
	// controller
	wire TAK, KEY_WRONG;
	wire restart_check;
	wire success_flag, unsuccess_flag;
	wire select_DMB, select_SA, select_FM;
	core_controller core_ctr					// core_controller is the module that hadle the order of our decryption
	(
	    .clk(CLOCK_50),
	    .rst_n(1'b1),
	    .start(1'b1),
	    .TAK(TAK),
	    .key_wrong(KEY_WRONG),
	    .finish_RK(finish_request_key),			// first, request for the key
	    .finish_FM(finish_filling),				// then, filling mem   (first loop)
	    .finish_SA(finish_shuffle),				// then, shuffle array (second loop)
	    .finish_DMB(finish_decrypt),			// then, decryptMessageByte (third loop)
	    .finish_LSBC(finish_check),				// after, finish checking the last byte, we done.
	
    	.select_DMB(select_DMB),
     	.select_SA(select_SA), 
    	.select_FM(select_FM), 
	    .restart(restart_check),
	    .start_RK(start_request_key),
	    .start_FM(start_filling),
	    .start_SA(start_shuffle),
	    .start_DMB(start_decrypt),
	    .success_flag(success_flag),			// finally, the desgin would rise a flag base on the result
	    .unsuccess_flag(unsuccess_flag)
	);

	wire [2:0] is_write;
	wire [7:0] request_address 	[2:0];			// three different address, each address have 8bits
	wire [7:0] data_to_s_ram 	[2:0];
	
	assign address_out 		= select_FM ? request_address[0] :					// if doing filling memory, select address for filling mem
								(select_SA ? request_address[1] : 				// else if doing shhffle array, select address for shffle array
								(select_DMB ? request_address[2] : 8'bx));		// else if doing decryptMessageByte, select address for decryptMessageByte
	assign write_data_out 	= select_FM ? data_to_s_ram[0] :					
								(select_SA ? data_to_s_ram[1] : 				// same as above but selecting data for sram
								(select_DMB ? data_to_s_ram[2] : 8'bx));
	assign wren 			= select_FM ? is_write[0] :							// same as above but selecting is_wirte signal which can write into mem block
								(select_SA ? is_write[1] : 
								(select_DMB ? is_write[2] : 8'bx));

	// individual for loop
	wire start_filling, finish_filling;
	fill_memory fill_memory_inst
	(
		.clk(CLOCK_50), 
		.rst_n(1'b1), 
		.start(start_filling), 
		.is_write(is_write[0]), 
		.address_out(request_address[0]), 
		.data_out(data_to_s_ram[0]), 
		.finish(finish_filling)
	);

	wire finish_shuffle, start_shuffle;
	shuffle_array SA
	(
		.clk(CLOCK_50), 
		.rst_n(1'b1), 
		.start(start_shuffle), 
		.secret_key(reg_secret_key),
		.data_in(data_out),
		.data_out(data_to_s_ram[1]),
		.address_out(request_address[1]),
		.is_write(is_write[1]), 
		.shuffle_finish(finish_shuffle)
	);

	wire start_decrypt, finish_decrypt;
	decryptMessageByte DMB
	(
		.clk(CLOCK_50),
		.rst_n(1'b1),
		.start(start_decrypt),
		.key_is_wrong(KEY_WRONG),
		.encrypted_input(encrypted_input),
		.data_from_s(data_out),
		.is_write_s(is_write[2]), 
		.address_out_s(request_address[2]), 
		.data_to_s(data_to_s_ram[2]), 
		.address_out_enc(address_out_enc), 
		.decrypted_output(decrypted_output), 
		.address_out_dec(address_out_dec), 
		.decrypted_wren(decrypted_wren), 
		.finish(finish_decrypt)
	);

	wire start_check, finish_check;
	assign start_check = decrypted_wren; 			// check while writing
	check_decrypted_message check_inst
	(
		.clk(CLOCK_50),
		.rst_n(1'b1),
		.start(start_check),
		.restart(restart_check),
		.data_decrypted(decrypted_output),
		.key_is_wrong(KEY_WRONG),
		.finish(finish_check)
	);

	// generate key
	wire start_request_key, finish_request_key;
	wire [23:0] secret_key;
	key_counter 
	key_counter_inst								// design for counting and generate the secertKey, when all key tried for one serectkey, then return TAK
	(
	    .clk(CLOCK_50),
	    .rst_n(1'b1),
	    .start(start_request_key),
	    .TAK(TAK),
	    .s_Key(secret_key),
	    .keyCounter_finish(finish_request_key)
	);

	reg [23:0] reg_secret_key;
	always_ff @(posedge CLOCK_50)
		if (finish_request_key & ~TAK)
			reg_secret_key <= secret_key;

	wire wren;
	wire [7:0] address_out;
	wire [7:0] write_data_out, data_out;
	s_memory s_mem_inst
	(
		.clock(CLOCK_50), 
		.address(address_out), 
		.wren(wren), 
		.data(write_data_out), 
		.q(data_out)
	);

	wire [4:0] address_out_enc;
	wire [7:0] encrypted_input;
	en_rom en_rom_inst
	(
		.clock(CLOCK_50),
		.address(address_out_enc),
		.q(encrypted_input)
	);

	wire [7:0] decrypted_output;
	wire [4:0] address_out_dec;
	wire decrypted_wren;
	de_ram de_ram_inst
	(
		.clock(CLOCK_50),
		.address(address_out_dec),
		.data(decrypted_output),
		.wren(decrypted_wren),
		.q()
	);

	// seven segment display for secret_key
	wire [3:0] Seven_Seg_Data [5:0];
	wire [6:0] Seven_Seg_Val [5:0];
	assign Seven_Seg_Data[0] = reg_secret_key[3:0]; 
	assign Seven_Seg_Data[1] = reg_secret_key[7:4]; 
	assign Seven_Seg_Data[2] = reg_secret_key[11:8]; 
	assign Seven_Seg_Data[3] = reg_secret_key[15:12]; 
	assign Seven_Seg_Data[4] = reg_secret_key[19:16]; 
	assign Seven_Seg_Data[5] = reg_secret_key[23:20]; 

	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst0(.ssOut(Seven_Seg_Val[0]), .nIn(Seven_Seg_Data[0]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst1(.ssOut(Seven_Seg_Val[1]), .nIn(Seven_Seg_Data[1]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst2(.ssOut(Seven_Seg_Val[2]), .nIn(Seven_Seg_Data[2]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst3(.ssOut(Seven_Seg_Val[3]), .nIn(Seven_Seg_Data[3]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst4(.ssOut(Seven_Seg_Val[4]), .nIn(Seven_Seg_Data[4]));
	SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst5(.ssOut(Seven_Seg_Val[5]), .nIn(Seven_Seg_Data[5]));
	
	assign HEX0 = Seven_Seg_Val[0];
	assign HEX1 = Seven_Seg_Val[1];
	assign HEX2 = Seven_Seg_Val[2];
	assign HEX3 = Seven_Seg_Val[3];
	assign HEX4 = Seven_Seg_Val[4];
	assign HEX5 = Seven_Seg_Val[5];
	
	assign LEDR[0] = success_flag;			// LEDR[0] would lights up if we find the right key
	assign LEDR[1] = unsuccess_flag;		// LEDR[1] would lights up if we tried all keys and no one is right
endmodule
`default_nettype wire
