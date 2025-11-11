//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts single-bit serial data to the multi-bit parallel value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits and receiving last 'serial_valid' input,
    // the module should assert the 'parallel_valid' at the same clock cycle
    // and output 'parallel_data' value.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.

    localparam W_SHIFT_REG = width - 1;
    localparam W_COUNTER   = $clog2(W_SHIFT_REG);
    
    logic [W_SHIFT_REG - 1 : 0] shift_reg;
    logic [W_COUNTER   - 1 : 0] cnt;

    always_ff @(posedge clk) begin

        if (rst || (serial_valid && cnt == '0))
            cnt <= W_SHIFT_REG;

        else if (serial_valid)
            cnt <= cnt - 1'b1;
    end

    always_ff @(posedge clk) begin
        if (rst) 
            shift_reg <= '0;

        else if (serial_valid)
            shift_reg <= { serial_data, shift_reg[W_SHIFT_REG - 1 : 1] };
    end

    assign parallel_data  = { serial_data, shift_reg };
    assign parallel_valid = serial_valid && cnt == '0;

endmodule
