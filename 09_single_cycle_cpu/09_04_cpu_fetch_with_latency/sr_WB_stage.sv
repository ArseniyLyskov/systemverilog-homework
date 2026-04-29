module sr_WB_stage (
    input  logic        clk,
    input  logic        rst,
    
    input  logic        i_rfwe,
    input  logic [ 4:0] i_a3,
    input  logic [31:0] i_alu_result,

    output logic        o_rfwe_comb,
    output logic [ 4:0] o_a3_comb,
    output logic [31:0] o_wd3_comb,

    // Hazard
    input  logic        i_valid,
    output logic        o_valid_comb
);

    assign o_rfwe_comb  = i_rfwe;
    assign o_a3_comb    = i_a3;
    assign o_wd3_comb   = i_alu_result;
    assign o_valid_comb = i_valid;

endmodule
