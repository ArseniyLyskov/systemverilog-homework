//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module parallel_to_serial
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      parallel_valid,
    input        [width - 1:0] parallel_data,

    output logic               busy,
    output logic               serial_valid,
    output logic               serial_data
);
    // Task:
    // Implement a module that converts multi-bit parallel value to the single-bit serial data.
    //
    // The module should accept 'width' bit input parallel data when 'parallel_valid' input is asserted.
    // At the same clock cycle as 'parallel_valid' is asserted, the module should output
    // the least significant bit of the input data. In the following clock cycles the module
    // should output all the remaining bits of the parallel_data.
    // Together with providing correct 'serial_data' value, module should also assert the 'serial_valid' output.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.

    localparam W_SHIFT_REG = width - 1;
    localparam W_COUNTER   = $clog2(W_SHIFT_REG);
    
    logic [W_SHIFT_REG - 1 : 0] shift_reg;
    logic [W_COUNTER   - 1 : 0] cnt;
    logic                       data_accepting;

    assign data_accepting = !busy && parallel_valid;
    
    always_ff @(posedge clk) begin
        if (rst)
            busy <= '0;
        else if (data_accepting)
            busy <= '1;
        else if (busy && cnt == '0)
            busy <= '0;
    end

    always_ff @(posedge clk) begin
        if (rst || cnt == '0)
            cnt <= W_SHIFT_REG;
        else if (serial_valid)
            cnt <= cnt - 1'b1;
    end

    always_ff @(posedge clk) begin
        if (rst)
            shift_reg <= '0;
        else if (data_accepting)
            shift_reg <= parallel_data[width - 1 : 1];
        else if (busy)
            shift_reg <= { 1'b0, shift_reg[W_SHIFT_REG - 1 : 1] };
    end

    assign serial_valid = parallel_valid || busy;

    always_comb begin
        serial_data = '0;

        if (data_accepting)
            serial_data = parallel_data[0];
        else if (busy)
            serial_data = shift_reg[0];
    end

endmodule
