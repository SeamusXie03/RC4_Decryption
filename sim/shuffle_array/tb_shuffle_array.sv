`timescale 1ns/1ps

module tb_shuffle_array();

    reg clk;
    reg rst_n;
    reg start;
    reg [23:0] secret_key;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire [7:0] address_out;
    wire is_write;
    wire shuffle_finish;

    integer i;

    // Instantiate the shuffle_array module
    shuffle_array DUT(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .secret_key(secret_key),
        .data_in(data_in),
        .data_out(data_out),
        .address_out(address_out),
        .is_write(is_write),
        .shuffle_finish(shuffle_finish)
    );

    initial forever begin
        clk = 0; #5;
        clk = 1; #5;
    end

    initial begin
        // Initialize inputs
        rst_n = 0;
        start = 0;
        secret_key = 24'h0;
        data_in = 8'h0;

        // Reset the design
        #5 rst_n = 0;
        #10 rst_n = 1;

        // Apply test vectors
        #15 secret_key = 24'h123456;

        #10 start = 1;  // assert start
        // #10 start = 0;  // deassert start


        // Loop through all possible input data values to traverse all the states
        for(i = 0; i <= 10; i = i + 1) begin
            #10 data_in = i;
        end

        // Ensure that the design is idle before finishing the simulation
        #20 $stop;
    end


endmodule
