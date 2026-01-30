//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.


    // FSM

    // 1: A <= B?
    // 2: A <= C?
    // 3: B <= C?
    enum logic [3:0] {
        IDLE, 
        S_AB, S_AB_AC, S_ABC, //  1,  2,  3
                       S_ACB, //  1,  2, ~3
              S_CAB,          //  1, ~2
        S_BA, S_BAC,          // ~1,  2
              S_BA_CA, S_BCA, // ~1, ~2,  3
                       S_CBA  // ~1, ~2, ~3
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        case (state) 
            default: if (valid_in & f_le_res) next_state = S_AB;
                     else if (valid_in)       next_state = S_BA;
                     else                     next_state = IDLE;
     
            S_AB:    if (f_le_res)            next_state = S_AB_AC;
                     else                     next_state = S_CAB;
     
            S_BA:    if (f_le_res)            next_state = S_BAC;
                     else                     next_state = S_BA_CA;

            S_AB_AC: if (f_le_res)            next_state = S_ABC;
                     else                     next_state = S_ACB;

            S_BA_CA: if (f_le_res)            next_state = S_BCA;
                     else                     next_state = S_CBA;
        endcase

        if (f_le_err)
            next_state = IDLE;
    end


    // f_less_or_equal interface
    always_comb
        case (state) 
            default: begin 
                f_le_a = unsorted[0]; 
                f_le_b = unsorted[1]; 
            end

            S_AB, S_BA: begin 
                f_le_a = unsorted[0]; 
                f_le_b = unsorted[2]; 
            end

            S_AB_AC, S_BA_CA: begin 
                f_le_a = unsorted[1]; 
                f_le_b = unsorted[2]; 
            end
        endcase


    // Result
    assign valid_out = f_le_err 
        | (state == S_ABC) | (state == S_ACB)
        | (state == S_BAC) | (state == S_BCA)
        | (state == S_CAB) | (state == S_CBA);

    always_comb
        case (state) 
            S_ABC: sorted = { unsorted[0], unsorted[1], unsorted[2] };
            S_ACB: sorted = { unsorted[0], unsorted[2], unsorted[1] };
            S_BAC: sorted = { unsorted[1], unsorted[0], unsorted[2] };
            S_BCA: sorted = { unsorted[1], unsorted[2], unsorted[0] };
            S_CAB: sorted = { unsorted[2], unsorted[0], unsorted[1] };
            S_CBA: sorted = { unsorted[2], unsorted[1], unsorted[0] };
            default: sorted = 'x;
        endcase

    assign err = f_le_err;

    assign busy = ~f_le_err & (
          (state == S_AB   ) | (state == S_BA   )
        | (state == S_AB_AC) | (state == S_BA_CA)
    );

endmodule
