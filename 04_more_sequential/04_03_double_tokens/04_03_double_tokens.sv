//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens
(
    input        clk,
    input        rst,
    input        a,
    output       b,
    output logic overflow
);
    // Task:
    // Implement a serial module that doubles each incoming token '1' two times.
    // The module should handle doubling for at least 200 tokens '1' arriving in a row.
    //
    // In case module detects more than 200 sequential tokens '1', it should assert
    // an overflow error. The overflow error should be sticky. Once the error is on,
    // the only way to clear it is by using the "rst" reset signal.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 10010011000110100001100100
    // b -> 11011011110111111001111110

    logic [7:0] tokens_to_double;

    always_ff @(posedge clk)
        if (rst) 
            tokens_to_double <= '0;
        else if (a)
            tokens_to_double <= tokens_to_double + 1;
        else if (!a && tokens_to_double > 0)
            tokens_to_double <= tokens_to_double - 1;

    always_ff @(posedge clk)
        if (rst) 
            overflow <= '0;
        else 
            overflow <= overflow || tokens_to_double >= 8'd200;

    assign b = a || tokens_to_double > '0;

endmodule
