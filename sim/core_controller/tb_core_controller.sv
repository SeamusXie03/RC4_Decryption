`timescale 1ns / 1ps
module tb_core_controller();
	// Inputs
	reg clk, rst_n, start, TAK, key_wrong, finish_FM, finish_SA, finish_DMB, finish_LSBC;
	
	// Outputs
	wire restart, start_RK, start_FM, start_SA, start_DMB, success_flag, unsuccess_flag;
	
	core_controller dut (
	    .clk(clk), .rst_n(rst_n), .start(start),
	    .TAK(TAK), .key_wrong(key_wrong), .finish_FM(finish_FM),
	    .finish_SA(finish_SA), .finish_DMB(finish_DMB), .finish_LSBC(finish_LSBC),
	    .restart(restart), .start_RK(start_RK), .start_FM(start_FM),
	    .start_SA(start_SA), .start_DMB(start_DMB), .success_flag(success_flag),
	    .unsuccess_flag(unsuccess_flag)
	);
	
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end
	initial begin
	    // Initialize inputs
	    start = 0;
	    TAK = 0;
	    key_wrong = 0;
	    finish_FM = 0;
	    finish_SA = 0;
	    finish_DMB = 0;
	    finish_LSBC = 0;

		rst_n = 0; #10; rst_n = 1; #10;
		$display("right first time");
		start = 1; #10; start = 0; #10;
		#30;
		finish_FM = 1; #10; finish_FM = 0; #10;
		#30;
		finish_SA = 1; #10; finish_SA = 0; #10;
		#30;
		finish_DMB = 1; #10; finish_DMB = 0; #10;
		#30;
		finish_LSBC = 1; #10; finish_LSBC = 0; #10;
		$stop;

		rst_n = 0; #10; rst_n = 1; #10;
		$display("right third time");
		start = 1; #10; start = 0; #10;
		for (int i = 0; i < 3; i++) begin
			#30;
			finish_FM = 1; #10; finish_FM = 0; #10;
			#30;
			finish_SA = 1; #10; finish_SA = 0; #10;
			#30;
			if (i == 0)
				key_wrong = 1; #10; key_wrong = 0; #10;
			finish_DMB = 1; #10; finish_DMB = 0; #10;

			if (i == 1)
				key_wrong = 1; #10; key_wrong = 0; #10;
			#30;
			finish_LSBC = 1; #10; finish_LSBC = 0; #10;
		end
		#50;
		$stop;

		rst_n = 0; #10; rst_n = 1; #10;
		$display("TAK");
		start = 1; #10; start = 0; #10;
		#30;
		TAK = 1; #10; TAK = 0; #10;
		#50;
		$stop;
	end
	
endmodule
