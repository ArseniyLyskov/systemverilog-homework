//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input              clk,
    input              rst,
    input        [1:0] requests,
    output logic [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01

    logic [1:0] next_requester;

    always_ff @(posedge clk) begin
        if (rst)
            next_requester <= 2'b01;
        else if (requests == 2'b11 || requests == next_requester)
            next_requester <= ~next_requester;
    end

    always_comb begin
        if (requests != 2'b11)
            grants = requests;
        else
            grants = next_requester;
    end

endmodule
