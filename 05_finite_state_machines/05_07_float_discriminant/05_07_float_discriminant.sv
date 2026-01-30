//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.


    localparam [FLEN - 1:0] FOUR = 64'h4010_0000_0000_0000;

    
    // FSM

    // WAIT_AC : mult(a , c  )
    // WAIT_4AC: mult(4 , ac )
    // WAIT_BB : mult(b , b  )
    // WAIT_RES: sub (bb, 4ac)
    enum logic [2:0] {
        IDLE, WAIT_AC, WAIT_4AC, WAIT_BB, WAIT_RES
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        next_state = state;

        case (state) 
            IDLE:        if (arg_vld        ) next_state = WAIT_AC;
            WAIT_AC:     if (mult_down_valid) next_state = WAIT_4AC;
            WAIT_4AC:    if (mult_down_valid) next_state = WAIT_BB;
            WAIT_BB:     if (mult_down_valid) next_state = WAIT_RES;
            WAIT_RES:    if ( sub_down_valid) next_state = IDLE;
        endcase

        if (err)
            next_state = IDLE;
    end


    // Temp register
    // Storing b for mult(b, b)
    // Then storing 4ac for sub(bb, 4ac)
    logic [FLEN-1:0] temp_reg;
    always_ff @(posedge clk)
        if ((state == IDLE) & arg_vld)
            temp_reg <= b;
        else if ((state == WAIT_4AC) & mult_down_valid)
            temp_reg <= mult_res;


    // f_mult interface
    logic [FLEN-1:0] mult_a, mult_b, mult_res;
    logic            mult_up_valid, mult_down_valid;
    logic            mult_busy, mult_error;

    f_mult f_mult_inst (
        .clk        ( clk             ),
        .rst        ( rst             ),
        .a          ( mult_a          ),
        .b          ( mult_b          ),
        .up_valid   ( mult_up_valid   ),

        .res        ( mult_res        ),
        .down_valid ( mult_down_valid ),
        .busy       ( mult_busy       ),
        .error      ( mult_error      )
    );

    always_comb begin
        mult_a = a;
        mult_b = c;
        mult_up_valid = '0;

        case (state) 
            IDLE:       
                if (arg_vld)
                    mult_up_valid = '1;

            WAIT_AC:    
                if (mult_down_valid) begin
                    mult_up_valid = '1;
                    mult_a = FOUR;
                    mult_b = mult_res;
                end

            WAIT_4AC:   
                if (mult_down_valid) begin 
                    mult_up_valid = '1;
                    mult_a = temp_reg;
                    mult_b = temp_reg;
                end
        endcase
    end


    // f_sub interface
    logic [FLEN-1:0]  sub_a, sub_b, sub_res;
    logic             sub_up_valid, sub_down_valid;
    logic             sub_busy, sub_error;

    f_sub f_sub_inst (
        .clk        ( clk            ),
        .rst        ( rst            ),
        .a          ( sub_a          ),
        .b          ( sub_b          ),
        .up_valid   ( sub_up_valid   ),

        .res        ( sub_res        ),
        .down_valid ( sub_down_valid ),
        .busy       ( sub_busy       ),
        .error      ( sub_error      )
    );

    assign sub_a        = mult_res;
    assign sub_b        = temp_reg;
    assign sub_up_valid = (state == WAIT_BB) & mult_down_valid;


    // Results
    assign res_vld      = err | ((state == WAIT_RES) & sub_down_valid);
    assign res          = sub_res;
    assign res_negative = res[FLEN - 1];
    assign busy         = state != IDLE;

    always_comb
        case (state) 
            WAIT_AC, WAIT_4AC, WAIT_BB: err = mult_error;
            WAIT_RES:                   err = sub_error;
            default:                    err = '0;
        endcase

endmodule
