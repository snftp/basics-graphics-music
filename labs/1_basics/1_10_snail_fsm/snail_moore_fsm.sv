// Asynchronous reset here is needed for some FPGA boards we use

`include "config.svh"

module snail_moore_fsm
(
    input  clk,
    input  rst,
    input  en,
    input  a,
    output y
);

    typedef enum bit [2:0]
    {
        S0 = 3'd0,
        S1 = 3'd1,
        S2 = 3'd2,
        S3 = 3'd3,
        S4 = 3'd4,
        S5 = 3'd5
    }
    state_e;

    state_e state, next_state;

    // State register

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            state <= S0;
        else if (en)
            state <= next_state;

    // Next state logic

    always_comb
    begin
        next_state = state;

        case (state)
        S0:
            if (  a) next_state = S1;

        S1:
            if (~ a) next_state = S2;

        S2:
            if (  a) next_state = S3;
            else     next_state = S0;

        S3:
            if (  a) next_state = S4;
            else     next_state = S0;

        S4: if (~ a) next_state = S5;
            else     next_state = S1;

        // S5: next_state = a ? S3 : S0;

        S5: if (a)
                    next_state = S3;
                else
                    next_state = S0;

        endcase
    end

    // Output logic based on current state

    assign y = (state == S5);

endmodule
