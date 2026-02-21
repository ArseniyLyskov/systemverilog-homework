//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    // up FSM
    enum logic [1:0] { 
        UP_READY, UP_SENDING_B, UP_SENDING_C 
    } up_state, up_next_state;

    always_ff @(posedge clk or posedge rst)
        if (rst) up_state <= UP_READY;
        else     up_state <= up_next_state;

    always_comb 
        case (up_state)
            UP_READY: if (arg_vld) up_next_state = UP_SENDING_B;
                      else         up_next_state = UP_READY;
            UP_SENDING_B:          up_next_state = UP_SENDING_C;
            UP_SENDING_C:          up_next_state = UP_READY;
        endcase
        
    // down FSM
    enum logic [1:0] {
        DOWN_IDLE, DOWN_RECEIVING_B, DOWN_RECEIVING_C 
    } down_state, down_next_state;

    always_ff @(posedge clk or posedge rst)
        if (rst) down_state <= DOWN_IDLE;
        else     down_state <= down_next_state;
        
    always_comb 
        case (down_state)
            DOWN_IDLE: if (isqrt_y_vld) down_next_state = DOWN_RECEIVING_B;
                       else             down_next_state = DOWN_IDLE;
            DOWN_RECEIVING_B:           down_next_state = DOWN_RECEIVING_C;
            DOWN_RECEIVING_C:           down_next_state = DOWN_IDLE;
        endcase

    // b      , c       stored here before calculating sqrt's
    // sqrt(a), sqrt(b) stored here before calculating sum
    logic [31:0] temp_ff1;
    logic [31:0] temp_ff2;
    
    always_ff @(posedge clk)
        if ((up_state == UP_READY) & arg_vld) begin
            temp_ff1 <= b;
            temp_ff2 <= c;
        end else if ((down_state == DOWN_IDLE) & isqrt_y_vld)
            temp_ff1 <= isqrt_y;
        else if (down_state == DOWN_RECEIVING_B)
            temp_ff2 <= isqrt_y;
            
    // isqrt interaction
    assign isqrt_x_vld = (up_state != UP_READY) | arg_vld;

    always_comb
        case (up_state) 
            UP_READY:     isqrt_x = a; 
            UP_SENDING_B: isqrt_x = b;
            UP_SENDING_C: isqrt_x = c;
        endcase
        
    // res
    assign res_vld = down_state == DOWN_RECEIVING_C;
    assign res     = temp_ff1 + temp_ff2 + isqrt_y;

endmodule
