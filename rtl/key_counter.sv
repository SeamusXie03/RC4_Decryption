module key_counter #(parameter LOWER = 24'd0, parameter UPPER = 24'd16777215)   // UPPER is 24'hFFFFFF
(
    input clk,
    input rst_n,
    input logic start,
    output logic TAK,           // tried all keys, now the top level should rise unsuccessful flag
    output logic [23:0] s_Key,
    output logic keyCounter_finish
);

    typedef enum logic [1:0] { 
        IDLE        =   2'b0_0,
        tryNextKey  =   2'b0_1,     // did not tried all keys, start try next key (only rise keyCounter_finish)
        allKeyTried =   2'b1_1      // all keys tried, return signal (rise both TAK and keyCounter_finish)
    } state_t;

    state_t state;

    assign TAK                  =   state[1];
    assign keyCounter_finish    =   state[0];

    reg [24:0] count = LOWER;   // need a carry bit to check, then we can use "(count > UPPER)"

    assign s_Key = count[23:0];
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            count <= LOWER;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start)              // edge condition, when count is 255, higher level needs to have the final try,
                        if (count > UPPER)  // so after I received "start" signal (after the final try), then I can move to allKeyTried
                            state <= allKeyTried;
                        else
                            state <= tryNextKey;
                    else
                        state <= IDLE;
                end

                tryNextKey: begin
                    state <= IDLE;
                    count <= count + 24'd1;
                end

                allKeyTried: begin
                    state <= allKeyTried;   
                end
            endcase
        end
    end

endmodule
