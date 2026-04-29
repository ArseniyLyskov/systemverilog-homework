module sr_ID_stage (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] i_instr,

    input  logic        i_rfwe_comb,
    input  logic [ 4:0] i_a3_comb,
    input  logic [31:0] i_wd3_comb,

    output logic [31:0] o_rd1,
    output logic [31:0] o_rd2,

    output logic        o_jal_comb,
    output logic [31:0] o_immJ_comb, 

    output logic [31:0] o_immI, 
    output logic [31:0] o_immB, 
    output logic [31:0] o_immU, 
    
    output logic        o_beq,
    output logic        o_bne,
    output logic [ 2:0] o_aluOp,
    output logic [ 1:0] o_srcA,
    output logic [ 2:0] o_srcB,
    output logic        o_rfwe,
    output logic [ 4:0] o_a3,
    
    // Hazard
    input  logic        i_valid,
    input  logic        i_WB_o_valid_comb,
    output logic [ 4:0] o_a1,
    output logic [ 4:0] o_a2,
    output logic        o_valid,

    // Debug
    input  logic [ 4:0] i_debug_a0,
    output logic [31:0] o_debug_rd0
);

    // Main decoder
    
    logic [ 4:0] rs1_comb;
    logic [ 4:0] rs2_comb;

    sr_main_decoder main_decoder (
        .clk                ( clk                   ),
        .rst                ( rst                   ),

        .rs1_comb           ( rs1_comb              ),
        .rs2_comb           ( rs2_comb              ),
        
        .valid              ( i_valid               ),
        .instr              ( i_instr               ),

        .jal_comb           ( o_jal_comb            ),
        .immJ_comb          ( o_immJ_comb           ),

        .immI               ( o_immI                ),
        .immB               ( o_immB                ),
        .immU               ( o_immU                ),

        .beq                ( o_beq                 ),
        .bne                ( o_bne                 ),
        .aluOp              ( o_aluOp               ),
        .srcA               ( o_srcA                ),
        .srcB               ( o_srcB                ),
        .rfwe               ( o_rfwe                ),
        .a3                 ( o_a3                  )
    );
    

    // Register file

    logic [31:0] rd1_comb;
    logic [31:0] rd2_comb;
    logic        we3;

    assign we3 = i_rfwe_comb & i_WB_o_valid_comb;

    sr_register_file register_file (
        .clk                ( clk                   ),
        .a0                 ( i_debug_a0            ),
        .a1                 ( rs1_comb              ),
        .a2                 ( rs2_comb              ),
        .a3                 ( i_a3_comb             ),
        .rd0                ( o_debug_rd0           ),
        .rd1                ( rd1_comb              ),
        .rd2                ( rd2_comb              ),
        .wd3                ( i_wd3_comb            ),
        .we3                ( we3                   )
    );
    
    // Registering

    always_ff @(posedge clk)
        if (rst) o_valid <= '0;
        else     o_valid <= i_valid;
        
    always_ff @(posedge clk)
        if (i_valid) begin
            o_a1  <= rs1_comb;
            o_a2  <= rs2_comb;
            o_rd1 <= rd1_comb;
            o_rd2 <= rd2_comb;
        end

endmodule
