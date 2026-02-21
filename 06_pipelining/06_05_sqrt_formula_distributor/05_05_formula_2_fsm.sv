//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // Task:
    //
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


    // FSM state register
    enum logic [1:0] {
        IDLE, WAIT_1, WAIT_2, WAIT_3
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    // FSM state transitions logic
    always_comb begin
        next_state = state;
        case (state) 
            IDLE:   if (arg_vld)     next_state = WAIT_1;
            WAIT_1: if (isqrt_y_vld) next_state = WAIT_2;
            WAIT_2: if (isqrt_y_vld) next_state = WAIT_3;
            WAIT_3: if (isqrt_y_vld) next_state = IDLE;
        endcase
    end


    // b, c registers
    logic [31:0] a_reg, b_reg;
    always_ff @(posedge clk)
        if ((state == IDLE) & arg_vld)
            {a_reg, b_reg} <= {a, b};


    // isqrt interface
    always_comb begin 
        isqrt_x = 'x;
        isqrt_x_vld = '0;

        case (state) 
            IDLE:   if (arg_vld    ) begin 
                isqrt_x = c; 
                isqrt_x_vld = '1;
            end
            WAIT_1: if (isqrt_y_vld) begin 
                isqrt_x = res + b_reg; 
                isqrt_x_vld = '1;
            end
            WAIT_2: if (isqrt_y_vld) begin 
                isqrt_x = res + a_reg; 
                isqrt_x_vld = '1;
            end
        endcase
    end


    // Result
    assign res     = isqrt_y;
    assign res_vld = isqrt_y_vld & (state == WAIT_3);

endmodule
