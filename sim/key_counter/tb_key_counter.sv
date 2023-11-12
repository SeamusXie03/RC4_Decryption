`timescale 1ns / 1ps

module tb_key_counter;

    reg clk;
    reg rst_n;
    reg start;
    reg [23:0] count;
    wire TAK;
    wire keyCounter_finish;

    // instantiate the key_counter module
    key_counter #(.LOWER(0), .UPPER(15)) 
    key_counter_inst(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .TAK(TAK),
        .keyCounter_finish(keyCounter_finish)
    );

    // clock generator
    always begin
        #5 clk = ~clk;
    end

    // test sequence
    initial begin
        // initial conditions
        clk = 0;
        rst_n = 0;
        start = 0;

        #10 rst_n = 1;  // release reset
        #10 start = 1;  // start key counter
        #50 start = 0;  // stop the counter

        // increment the lower range and repeat
        for (count = 0; count < 15; count = count + 1) begin
            #10 start = 1;  // start key counter
            #50 start = 0;  // stop the counter
        end
        #10 $stop;  // stop the simulation
    end
endmodule
