//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    logic               no_data_registered;
    logic [width - 1:0] r_data;

    always_ff @(posedge clock)
        if (reset)         no_data_registered <= '1;
        else if (up_valid) no_data_registered <= '0;

    always_ff @(posedge clock)
        if (reset)         r_data <= 'x;
        else if (up_valid) r_data <= up_data;

    assign down_valid = up_valid && !no_data_registered;
    assign down_last  = up_first;
    assign down_data  = r_data;

endmodule
