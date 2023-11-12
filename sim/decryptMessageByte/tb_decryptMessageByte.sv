module tb_decrypteMessageByte();
	reg clk, rst_n, start, restart;
	reg [7:0] encrypted_input, data_from_s;

	wire key_is_worng, is_write_s, finish, decrypted_wren;
	wire [7:0] address_out_s, data_to_s, decrypted_output;
	wire [4:0] address_out_enc, address_out_dec;
	decryptMessageByte dut
	(
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.encrypted_input(encrypted_input),
		.data_from_s(data_from_s),
		.is_write_s(is_write_s), 
		.address_out_s(address_out_s), 
		.data_to_s(data_to_s), 
		.address_out_enc(address_out_enc),
		.decrypted_output(decrypted_output),
		.address_out_dec(address_out_dec),
		.decrypted_wren(decrypted_wren),
		.finish(finish)
	);

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
		start = 0;
		encrypted_input = 8'b0;
		data_from_s = 8'b0;
		rst_n = 0; #10; rst_n = 1; #10;
		encrypted_input = 8'h55;

		$display("Start for loop");
		start = 1; #10; start = 0; #10;

		#30;
		data_from_s = 8'hFF;
		#20;

		#30;
		data_from_s = 8'h03;
		#20;

		#30;
		#20;

		#30;
		#20;

		#30;
		data_from_s = 8'h45;
		#20;
		
		$stop;
	end
endmodule
