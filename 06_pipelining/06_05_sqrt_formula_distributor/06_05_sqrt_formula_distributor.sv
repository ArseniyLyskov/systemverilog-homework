module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
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
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    
    localparam N_COMPUTING_UNITS = 
        ((formula == 1) && (impl == 1)) ? 15 :
        ((formula == 1) && (impl == 2)) ? 19 :
        ((formula == 2))                ? 50 :
        50;

    // Counter
    logic [N_COMPUTING_UNITS - 1:0] counter_onehot;

    always_ff @(posedge clk)
        if (rst) 
            counter_onehot <= 1'b1;
        else if (arg_vld) 
            counter_onehot <= { counter_onehot[N_COMPUTING_UNITS - 2 : 0], counter_onehot[N_COMPUTING_UNITS - 1] };
        
    // vld and arg registers
    logic [N_COMPUTING_UNITS - 1:0]             arg_vld_reg;
    logic [N_COMPUTING_UNITS - 1:0][32*3 - 1:0] arg_data_reg;

    always_ff @(posedge clk)
        if (rst) arg_vld_reg <= '0;
        else     arg_vld_reg <= {N_COMPUTING_UNITS{arg_vld}} & counter_onehot;
        
    always_ff @(posedge clk)
        for (int i = 0; i < N_COMPUTING_UNITS; i++)
            if (arg_vld & counter_onehot[i])
                arg_data_reg[i] <= {a, b, c};
            
    // Computing units
    logic [N_COMPUTING_UNITS - 1:0]       isqrt_y_vld;
    logic [N_COMPUTING_UNITS - 1:0][31:0] isqrt_y; 

    generate 
        if ((formula == 1) & (impl == 1))
            for (genvar i = 0; i < N_COMPUTING_UNITS; i++) begin
                formula_1_impl_1_top f1i1_computing_unit (
                    .clk     (clk                             ),
                    .rst     (rst                             ),

                    .arg_vld (arg_vld_reg[i]                  ),
                    .a       (arg_data_reg[i][32*3 - 1 : 32*2]),
                    .b       (arg_data_reg[i][32*2 - 1 : 32*1]),
                    .c       (arg_data_reg[i][32*1 - 1 : 32*0]),

                    .res_vld (isqrt_y_vld[i]                  ),
                    .res     (isqrt_y[i]                      )
                );
            end
        else if ((formula == 1) & (impl == 2))
            for (genvar i = 0; i < N_COMPUTING_UNITS; i++) begin
                formula_1_impl_2_top f1i2_computing_unit (
                    .clk     (clk                             ),
                    .rst     (rst                             ),

                    .arg_vld (arg_vld_reg[i]                  ),
                    .a       (arg_data_reg[i][32*3 - 1 : 32*2]),
                    .b       (arg_data_reg[i][32*2 - 1 : 32*1]),
                    .c       (arg_data_reg[i][32*1 - 1 : 32*0]),

                    .res_vld (isqrt_y_vld[i]                  ),
                    .res     (isqrt_y[i]                      )
                );
            end
        else if (formula == 2) 
            for (genvar i = 0; i < N_COMPUTING_UNITS; i++) begin
                formula_2_top f2_computing_unit (
                    .clk     (clk                             ),
                    .rst     (rst                             ),

                    .arg_vld (arg_vld_reg[i]                  ),
                    .a       (arg_data_reg[i][32*3 - 1 : 32*2]),
                    .b       (arg_data_reg[i][32*2 - 1 : 32*1]),
                    .c       (arg_data_reg[i][32*1 - 1 : 32*0]),

                    .res_vld (isqrt_y_vld[i]                  ),
                    .res     (isqrt_y[i]                      )
                );
            end
    endgenerate
    
    // Outputs
    logic        temp_res_vld;
    logic [31:0] temp_res;

    always_comb begin 
        temp_res_vld = '0;
        temp_res     = '0;

        for (int i = 0; i < N_COMPUTING_UNITS; i++)
            if (isqrt_y_vld[i]) begin 
                temp_res_vld = '1;
                temp_res     = isqrt_y[i];
            end
    end
    
    assign res_vld = temp_res_vld;
    assign res     = temp_res;

endmodule
