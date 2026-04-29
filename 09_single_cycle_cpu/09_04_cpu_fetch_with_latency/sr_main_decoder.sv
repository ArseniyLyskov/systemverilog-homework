`define SRC_A_RD1   2'b00
`define SRC_A_PC    2'b01
`define SRC_A_ZERO  2'b10

`define SRC_B_RD2   3'b000
`define SRC_B_IMMI  3'b001
`define SRC_B_IMMS  3'b010
`define SRC_B_IMMU  3'b011
`define SRC_B_4     3'b100

module sr_main_decoder (
    input  logic        clk,
    input  logic        rst,

    output logic [ 4:0] rs1_comb,
    output logic [ 4:0] rs2_comb,

    input  logic        valid,
    input  logic [31:0] instr,

    output logic        jal_comb,
    output logic [31:0] immJ_comb, 

    output logic [31:0] immI, 
    output logic [31:0] immB, 
    output logic [31:0] immU, 
    
    output logic        beq,
    output logic        bne,
    output logic [ 2:0] aluOp,
    output logic [ 1:0] srcA,
    output logic [ 2:0] srcB,
    output logic        rfwe,
    output logic [ 4:0] a3
);

    logic [ 6:0] cmdOp;
    logic [ 4:0] a3_comb;
    logic [ 2:0] cmdF3;
    logic [ 6:0] cmdF7;
    logic [31:0] immI_comb;
    logic [31:0] immB_comb;
    logic [31:0] immU_comb;

    sr_decode instr_partition (
        .instr              ( instr                 ),
        .cmdOp              ( cmdOp                 ),
        .rd                 ( a3_comb               ),
        .cmdF3              ( cmdF3                 ),
        .rs1                ( rs1_comb              ),
        .rs2                ( rs2_comb              ),
        .cmdF7              ( cmdF7                 ),
        .immI               ( immI_comb             ),
        .immB               ( immB_comb             ),
        .immU               ( immU_comb             )
    );
    
    logic       pcSrc;
    logic       rfwe_comb;
    logic       aluSrc;
    logic       wdSrc;
    logic [2:0] aluOp_comb;

    sr_control control_signals_decoding (
        .cmdOp              ( cmdOp                 ),
        .cmdF3              ( cmdF3                 ),
        .cmdF7              ( cmdF7                 ),
        .aluZero            ( '1                    ),
        .pcSrc              ( pcSrc                 ),
        .regWrite           ( rfwe_comb             ),
        .aluSrc             ( aluSrc                ),
        .wdSrc              ( wdSrc                 ),
        .aluControl         ( aluOp_comb            )
    );

    assign jal_comb  = '0; // TODO
    assign immJ_comb = 'x; // TODO
    
    // Registering
    
    always_ff @(posedge clk)
        if (rst) rfwe <= '0;
        else     rfwe <= rfwe_comb;

    always_ff @(posedge clk)
        if (valid) begin
            immI    <= immI_comb;
            immB    <= immB_comb;
            immU    <= immU_comb;
            
            beq     <= pcSrc;
            bne     <= '0; // TODO
            aluOp   <= aluOp_comb;
            a3      <= a3_comb;
            
            if (aluSrc) begin 
                srcA <= `SRC_A_RD1;
                srcB <= `SRC_B_IMMI;
            end else if (wdSrc) begin 
                srcA <= `SRC_A_ZERO;
                srcB <= `SRC_B_IMMU;
            end else begin
                srcA <= `SRC_A_RD1;
                srcB <= `SRC_B_RD2;
            end
        end

endmodule
