//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    localparam N_PIPE_STAGES = 16;

    // intermediate calculations
    logic        isqrt2_up_vld;
    logic [31:0] isqrt2_up_data;
    
    always_ff @(posedge clk)
        if (rst) isqrt2_up_vld <= '0;
        else     isqrt2_up_vld <= isqrt1_down_vld;

    always_ff @(posedge clk)
        if (isqrt1_down_vld)
            isqrt2_up_data <= isqrt1_down_data + shift_reg1_data;

    logic        isqrt3_up_vld;
    logic [31:0] isqrt3_up_data;

    always_ff @(posedge clk)
        if (rst) isqrt3_up_vld <= '0;
        else     isqrt3_up_vld <= isqrt2_down_vld;

    always_ff @(posedge clk)
        if (isqrt2_down_vld)
            isqrt3_up_data <= isqrt2_down_data + shift_reg2_data;
        

    // shift register 1
    logic [31:0] shift_reg1_data;

    shift_register_with_valid #(
        .width    (32                 ),
        .depth    (N_PIPE_STAGES      )
    ) shift_reg1 (
        .clk      (clk                ),
        .rst      (rst                ),

        .in_vld   (arg_vld            ),
        .in_data  (b                  ),

        .out_vld  (                   ),
        .out_data (shift_reg1_data    )
    );

    // shift register 2
    logic [31:0] shift_reg2_data;

    shift_register_with_valid #(
        .width    (32                 ),
        .depth    (2*N_PIPE_STAGES + 1)
    ) shift_reg2 (
        .clk      (clk                ),
        .rst      (rst                ),

        .in_vld   (arg_vld            ),
        .in_data  (a                  ),

        .out_vld  (                   ),
        .out_data (shift_reg2_data    )
    );

    // isqrt1  
    logic        isqrt1_down_vld;
    logic [31:0] isqrt1_down_data;

    isqrt #(
        .n_pipe_stages(N_PIPE_STAGES)
    ) isqrt1 (
        .clk   (clk             ),
        .rst   (rst             ),

        .x_vld (arg_vld         ),
        .x     (c               ),

        .y_vld (isqrt1_down_vld ),
        .y     (isqrt1_down_data)
    );

    // isqrt2
    logic        isqrt2_down_vld;
    logic [31:0] isqrt2_down_data;

    isqrt #(
        .n_pipe_stages(N_PIPE_STAGES)
    ) isqrt2 (
        .clk   (clk             ),
        .rst   (rst             ),

        .x_vld (isqrt2_up_vld   ),
        .x     (isqrt2_up_data  ),

        .y_vld (isqrt2_down_vld ),
        .y     (isqrt2_down_data)
    );
    
    // isqrt3
    isqrt #(
        .n_pipe_stages(N_PIPE_STAGES)
    ) isqrt3 (
        .clk   (clk             ),
        .rst   (rst             ),

        .x_vld (isqrt3_up_vld   ),
        .x     (isqrt3_up_data  ),

        .y_vld (res_vld         ),
        .y     (res             )
    );

endmodule
