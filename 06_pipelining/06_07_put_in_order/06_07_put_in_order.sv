module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.


    // Counter
    logic [n_inputs - 1:0] counter_onehot;

    always_ff @(posedge clk)
        if (rst) 
            counter_onehot <= 1'b1;
        else if (|(counter_onehot & vld_reg)) 
            counter_onehot <= { counter_onehot[n_inputs - 2 : 0], counter_onehot[n_inputs - 1] };
        
    // vld and data registers
    logic [n_inputs - 1:0]              vld_reg;
    logic [n_inputs - 1:0][width - 1:0] data_reg;
        
    always_ff @(posedge clk) begin
        if (rst)
            vld_reg <= '0;
        else
            for (int i = 0; i < n_inputs; i++) begin 
                if (up_vlds[i])
                    vld_reg[i] <= '1;
                else if (counter_onehot[i])
                    vld_reg[i] <= '0;
            end
    end

    always_ff @(posedge clk)
        for (int i = 0; i < n_inputs; i++)
            if (up_vlds[i]) 
                data_reg[i] <= up_data[i];

    // Outputs
    logic [width - 1:0] temp_down_data;

    assign down_vld = |(counter_onehot & vld_reg);

    always_comb begin 
        temp_down_data = '0;

        for (int i = 0; i < n_inputs; i++)
            if (counter_onehot[i] & vld_reg[i])
                temp_down_data = data_reg[i];
    end

    assign down_data = temp_down_data;

endmodule
