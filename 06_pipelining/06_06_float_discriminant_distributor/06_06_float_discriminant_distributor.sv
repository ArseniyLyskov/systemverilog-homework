module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.


    localparam N_COMPUTING_UNITS = 14;

    // Counter
    logic [N_COMPUTING_UNITS - 1:0] counter_onehot;

    always_ff @(posedge clk)
        if (rst) 
            counter_onehot <= 1'b1;
        else if (arg_vld) 
            counter_onehot <= { counter_onehot[N_COMPUTING_UNITS - 2 : 0], counter_onehot[N_COMPUTING_UNITS - 1] };
        
    // vld and arg registers
    logic [N_COMPUTING_UNITS - 1:0]               arg_vld_reg;
    logic [N_COMPUTING_UNITS - 1:0][FLEN*3 - 1:0] arg_data_reg;

    always_ff @(posedge clk)
        if (rst) arg_vld_reg <= '0;
        else     arg_vld_reg <= {N_COMPUTING_UNITS{arg_vld}} & counter_onehot;
        
    always_ff @(posedge clk)
        for (int i = 0; i < N_COMPUTING_UNITS; i++)
            if (arg_vld & counter_onehot[i])
                arg_data_reg[i] <= {a, b, c};
            
    // Computing units
    logic [N_COMPUTING_UNITS - 1:0]             cu_res_vld;
    logic [N_COMPUTING_UNITS - 1:0][FLEN - 1:0] cu_res; 
    logic [N_COMPUTING_UNITS - 1:0]             cu_res_negative; 
    logic [N_COMPUTING_UNITS - 1:0]             cu_err; 
    logic [N_COMPUTING_UNITS - 1:0]             cu_busy; 

    generate 
        for (genvar i = 0; i < N_COMPUTING_UNITS; i++) begin
            float_discriminant computing_unit (
                .clk          (clk                                 ),
                .rst          (rst                                 ),

                .arg_vld      (arg_vld_reg[i]                      ),
                .a            (arg_data_reg[i][FLEN*3 - 1 : FLEN*2]),
                .b            (arg_data_reg[i][FLEN*2 - 1 : FLEN*1]),
                .c            (arg_data_reg[i][FLEN*1 - 1 : FLEN*0]),

                .res_vld      (cu_res_vld[i]                       ),
                .res          (cu_res[i]                           ),
                .res_negative (cu_res_negative[i]                  ),
                .err          (cu_err[i]                           ),
                .busy         (cu_busy[i]                          )
            );
        end
    endgenerate
    
    // Outputs
    always_comb begin 
        res_vld      = '0;
        res          = '0;
        res_negative = '0;
        err          = '0;
        busy         = '0;

        for (int i = 0; i < N_COMPUTING_UNITS; i++)
            if (cu_res_vld[i]) begin 
                res_vld      = '1;
                res          = cu_res[i];
                res_negative = cu_res_negative[i];
                err          = cu_err[i];
                busy         = cu_busy[i];
            end
    end

endmodule
