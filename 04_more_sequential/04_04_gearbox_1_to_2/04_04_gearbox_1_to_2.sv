//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals

    logic               storing_data;
    logic [width - 1:0] r_data;

    always_ff @(posedge clk)
        if (rst)            storing_data <= '0;
        else if (up_vld)    storing_data <= ~storing_data;

    always_ff @(posedge clk)
        if (rst)            r_data <= '0;
        else if (up_vld)    r_data <= up_data;
        
    assign down_vld  = storing_data && up_vld;
    assign down_data = { r_data, up_data };

endmodule
