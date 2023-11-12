module tb_fill_memory();
	reg clk, rst_n, start;
	wire is_write, finish;
	wire [7:0] address_out, data_out;

	fill_memory fill_inst(.clk(clk), .rst_n(rst_n), .start(start), 
					.is_write(is_write), .address_out(address_out), .data_out(data_out), .finish(finish));

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
		start = 0;
		$display("reset in the beginning");
		rst_n = 0; #5; rst_n = 1; #5;

		$display("filling start");
		start = 1; #10; start = 0; #10;

        #10;
        $display("Waiting for finish");
        while (!finish) @(posedge clk);
        $display("Filling completed");
		$stop;
	end
endmodule
