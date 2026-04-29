`define SRC_A_RD1   2'b00
`define SRC_A_PC    2'b01
`define SRC_A_ZERO  2'b10

`define SRC_B_RD2   3'b000
`define SRC_B_IMMI  3'b001
`define SRC_B_IMMS  3'b010
`define SRC_B_IMMU  3'b011
`define SRC_B_4     3'b100

module sr_EX_stage (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] i_rd1,
    input  logic [31:0] i_rd2,

    input  logic [31:0] i_immI,
    input  logic [31:0] i_immB, 
    input  logic [31:0] i_immU, 
    
    input  logic [ 2:0] i_aluOp,
    input  logic [ 1:0] i_srcA,
    input  logic [ 2:0] i_srcB,
    input  logic        i_rfwe,
    input  logic [ 4:0] i_a3,

    output logic        o_alu_zero_comb,
    output logic [31:0] o_alu_result,
    output logic        o_rfwe,
    output logic [ 4:0] o_a3,

    // Hazard
    input  logic        i_valid,
    input  logic        i_forwarding_rd1,
    input  logic        i_forwarding_rd2,
    input  logic [31:0] i_HU_rd1,
    input  logic [31:0] i_HU_rd2,
    output logic        o_valid
);

    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] alu_result_comb;
    
    always_comb
        case (i_srcA)
            `SRC_A_RD1  : a = i_forwarding_rd1 ? i_HU_rd1 : i_rd1;
            `SRC_A_ZERO : a = '0;
            default     : a = 'x;
        endcase
        
    always_comb
        case (i_srcB)
            `SRC_B_RD2  : b = i_forwarding_rd2 ? i_HU_rd2 : i_rd2;
            `SRC_B_IMMI : b = i_immI;
            `SRC_B_IMMU : b = i_immU;
            `SRC_B_4    : b = 32'd4;
            default     : b = 'x;
        endcase

    sr_alu alu (
        .srcA               ( a                     ),
        .srcB               ( b                     ),
        .oper               ( i_aluOp               ),
        .zero               ( o_alu_zero_comb       ),
        .result             ( alu_result_comb       )
    );

    // Registering

    always_ff @(posedge clk)
        if (rst) begin 
            o_valid <= '0;
            o_rfwe  <= '0;
        end else begin     
            o_valid <= i_valid;
            o_rfwe  <= i_rfwe;
        end
        
    always_ff @(posedge clk)
        if (i_valid) begin
            o_alu_result  <= alu_result_comb;
            o_a3          <= i_a3;
        end

endmodule
