module tb_check_decrypted_message ();
	reg clk, rst_n, start, restart;
	reg [7:0] data_decrypted;
	wire key_is_wrong;

	check_decrypted_message dut
	(
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.restart(restart),
		.data_decrypted(data_decrypted),
		.key_is_wrong(key_is_wrong),
		.finish(finish)
	);

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
		start = 0;
		restart = 0;
		data_decrypted = 0;
		rst_n = 0; #10; 
		rst_n = 1; #10;

		$display("try wrong data");
		data_decrypted = 31;
		#10;
		start = 1; #10; start = 0; #10;
		$display("wait for key is wrong");
		while (!key_is_wrong) @(posedge clk);
		$display("success");

		$display("try restart");
		restart = 1; #10; restart = 0; #10;
		assert (key_is_wrong == 1'b0)
			$display("restart is right");
		else 
			$display("restart is wrong");

		$display("try all right");
		for (int i = 97; i <= 122; i++) begin
			data_decrypted = i;
			#10;
			start = 1; #10; start = 0; #10;
			while (!finish) @(posedge clk);
		end
		data_decrypted = 32;
		#10;
		start = 1; #10; start = 0; #10;
		while (!finish) @(posedge clk);
		$display("all is right");
		$stop;
	end
endmodule
