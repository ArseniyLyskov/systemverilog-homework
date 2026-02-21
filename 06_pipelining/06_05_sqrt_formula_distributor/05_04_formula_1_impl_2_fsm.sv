//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
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

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the formula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


    // FSM state register
    enum logic [1:0] {
        IDLE, WAIT_A, WAIT_C
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;


    // FSM state transitions logic
    always_comb begin
        next_state = state;
        case (state) 
            IDLE:   if (arg_vld)       next_state = WAIT_A;
            WAIT_A: if (isqrt_1_y_vld) next_state = WAIT_C;
            WAIT_C: if (isqrt_1_y_vld) next_state = IDLE;
        endcase
    end


    // c register
    logic [31:0] c_reg;
    logic        c_sent;

    always_ff @(posedge clk)
        if ((state == IDLE) & arg_vld) 
            c_reg <= c;

    always_ff @(posedge clk)
        c_sent <= state == WAIT_A;


    // isqrt interface
    always_comb begin 
        isqrt_1_x = a;
        isqrt_2_x = b;
        isqrt_1_x_vld = '0;
        isqrt_2_x_vld = '0;
        
        case (state) 
            IDLE:   if (arg_vld) begin 
                isqrt_1_x_vld = '1;
                isqrt_2_x_vld = '1;
            end
            WAIT_A: if (!c_sent) begin 
                isqrt_1_x = c_reg;
                isqrt_1_x_vld = '1;
            end
        endcase
    end


    // isqrt(a) + isqrt(b) register (decrease latency)
    logic [31:0] sqrt_a_plus_sqrt_b;

    always_ff @(posedge clk)
        if ((state == WAIT_A) & isqrt_1_y_vld & isqrt_2_y_vld)
            sqrt_a_plus_sqrt_b <= isqrt_1_y + isqrt_2_y;

    // Result (latency = N + 1)
    assign res     = sqrt_a_plus_sqrt_b + isqrt_1_y;
    assign res_vld = (state == WAIT_C) & isqrt_1_y_vld;

endmodule
