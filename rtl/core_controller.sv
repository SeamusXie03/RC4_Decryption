module core_controller (
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic TAK,
    input logic key_wrong,
    input logic finish_RK,
    input logic finish_FM,
    input logic finish_SA,
    input logic finish_DMB,
    input logic finish_LSBC,

    output logic select_DMB,
    output logic select_SA, 
    output logic select_FM, 
    output logic restart,
    output logic start_RK,
    output logic start_FM,
    output logic start_SA,
    output logic start_DMB,
    output logic success_flag,
    output logic unsuccess_flag
);

    typedef enum logic [11:0] { 
        IDLE        = 12'b00_000_0_0000_00,     // initial state
        REDO        = 12'b00_000_1_0000_00,     // any time when receive "key_wrong", state would be forced to REDO; sent out "restart" signal
        RK          = 12'b00_000_0_1000_00,     // start "request key"
        waitRK      = 12'b01_000_0_0000_00,     // wait for the key counter finish
        FM          = 12'b00_001_0_0100_00,     // start filling the mem
        waitFM      = 12'b00_001_0_0000_00,     // wait until "FM" is finished; we can assume "RK" can finished before "FM"
        SA          = 12'b00_010_0_0010_00,     // start "shuffle array" (the second loop)
        waitSA      = 12'b00_010_0_0000_00,     // wait "SA" finish
        DMB         = 12'b00_100_0_0001_00,     // start "decrypted message byte"(the third loop)
        waitDMB     = 12'b00_100_0_0000_00,     // wait "DMB" finish
        waitLSBC    = 12'b10_000_0_0000_00,     // wait until "the least significant byte check" is finished
        rightKey    = 12'b00_000_0_0000_10,     // if all secret_key[i] passed DMB test, rise the success_flag
        failedKey   = 12'b00_000_0_0000_01      // if any secret_key[i] does not passed DMB test, rise the unsuccess_flag
    } state_t;
    ////////////////////////////////////////
    // the most significant 2 bits are index
    ////////////////////////////////////////
    state_t state;

    assign select_DMB       = state[9];
    assign select_SA        = state[8];
    assign select_FM        = state[7];
    assign restart          = state[6];
    assign start_RK         = state[5];
    assign start_FM         = state[4];
    assign start_SA         = state[3];
    assign start_DMB        = state[2];
    assign success_flag     = state[1];
    assign unsuccess_flag   = state[0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state <= IDLE;
        // state change begin 
        else begin
            case (state)
                IDLE: begin
                    if (start)
                        state <= REDO;
                    else
                        state <= IDLE;
                end

                REDO: begin
                    state <= RK;
                end

                RK: begin
                    state <= waitRK;
                end

                waitRK: begin
                    if (finish_RK)
                        if (TAK)
                            state <= failedKey; // after secertKey++ (counter++), we need to see if allkey have been tired
                        else
                            state <= FM;
                    else
                        state <= waitRK;
                end

                FM: begin
                    state <= waitFM;
                end

                waitFM: begin
                    if (finish_FM)
                        state <= SA;
                    else
                        state <= waitFM;
                end

                SA: begin
                    state <= waitSA;
                end

                waitSA: begin
                    if (finish_SA)
                        state <= DMB;
                    else
                        state <= waitSA;
                end

                DMB: begin
                    state <= waitDMB;
                end

                waitDMB: begin
                    if (finish_DMB)
                        state <= waitLSBC;
                    else
                        state <= waitDMB;
                end

                waitLSBC: begin
                    if (finish_LSBC)
                        if (key_wrong)          // after finish checking the last byte, start to see whether the key we are checking is worng or not
                            state <= REDO;      // if it is worng, start to use the next secrect key
                        else
                            state <= rightKey;  // if we find the right key (!key_worng), then go to the dead state (rightKey)
                    else
                        state <= waitLSBC;
                end

                rightKey: begin
                    state <= rightKey;          // two dead states perpare for either the current key is the right key
                end

                failedKey: begin
                    state <= failedKey;         // or all secrectKey tired and no one is right
                end
            endcase
        end
    end

endmodule
