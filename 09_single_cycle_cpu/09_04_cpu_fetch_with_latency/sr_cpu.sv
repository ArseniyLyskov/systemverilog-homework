//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

`include "sr_cpu.svh"

module sr_cpu # (
    parameter            ROM_SIZE = 12
) (
    input  logic         clk,      // clock
    input  logic         rst,      // reset

    output logic [31:0]  imAddr,   // instruction memory address
    input  logic [31:0]  imData,   // instruction memory data

    input  logic [ 4:0]  regAddr,  // debug access reg address
    output logic [31:0]  regData   // debug access reg data
);

    ///////////////////////////////////////////////////////////////////////
    // 1) INSTRUCTION FETCH STAGE
    ///////////////////////////////////////////////////////////////////////

    logic        IF_i_jal_comb;
    logic [31:0] IF_i_immJ_comb;

    logic        IF_i_beq;
    logic        IF_i_bne;
    logic [31:0] IF_i_immB;
    logic        IF_i_alu_zero_comb;

    logic [31:0] IF_o_instr;
    
    // Hazard
    logic        IF_i_valid;
    logic        IF_i_ID_o_valid;
    logic        IF_o_misprediction;
    logic        IF_o_valid;

    // Debug
    logic [31:0] IF_o_debug_pc;


    sr_IF_stage #(
        .ROM_SIZE           ( ROM_SIZE              )
    ) IF_stage (
        .clk                ( clk                   ),
        .rst                ( rst                   ),

        .i_jal_comb         ( IF_i_jal_comb         ),
        .i_immJ_comb        ( IF_i_immJ_comb        ),

        .i_beq              ( IF_i_beq              ),
        .i_bne              ( IF_i_bne              ),
        .i_immB             ( IF_i_immB             ),
        .i_alu_zero_comb    ( IF_i_alu_zero_comb    ),

        .o_instr_addr       ( imAddr                ),

        .i_valid            ( IF_i_valid            ),
        .i_ID_o_valid       ( IF_i_ID_o_valid       ),
        .o_misprediction    ( IF_o_misprediction    ),
        .o_valid            ( IF_o_valid            ),

        .o_debug_pc         ( IF_o_debug_pc         )
    );
    
    assign IF_o_instr = imData;
    


    ///////////////////////////////////////////////////////////////////////
    // 2) INSTRUCTION DECODE STAGE
    ///////////////////////////////////////////////////////////////////////
    
    logic [31:0] ID_i_instr;
    logic        ID_i_rfwe_comb;
    logic [ 4:0] ID_i_a3_comb;
    logic [31:0] ID_i_wd3_comb;

    logic [31:0] ID_o_rd1;
    logic [31:0] ID_o_rd2;

    logic        ID_o_jal_comb;
    logic [31:0] ID_o_immJ_comb;

    logic [31:0] ID_o_immI;
    logic [31:0] ID_o_immB; 
    logic [31:0] ID_o_immU; 

    logic        ID_o_beq;
    logic        ID_o_bne;
    logic [ 2:0] ID_o_aluOp;
    logic [ 1:0] ID_o_srcA;
    logic [ 2:0] ID_o_srcB;
    logic        ID_o_rfwe;
    logic [ 4:0] ID_o_a3;

    // Hazard
    logic        ID_i_valid;
    logic        ID_i_WB_o_valid_comb;
    logic [ 4:0] ID_o_a1;
    logic [ 4:0] ID_o_a2;
    logic        ID_o_valid;

    // Debug
    logic [ 4:0] ID_i_debug_a0;
    logic [31:0] ID_o_debug_rd0;


    sr_ID_stage ID_stage (
        .clk                ( clk                   ),
        .rst                ( rst                   ),

        .i_instr            ( ID_i_instr            ),

        .i_rfwe_comb        ( ID_i_rfwe_comb        ),
        .i_a3_comb          ( ID_i_a3_comb          ),
        .i_wd3_comb         ( ID_i_wd3_comb         ),

        .o_rd1              ( ID_o_rd1              ),
        .o_rd2              ( ID_o_rd2              ),

        .o_jal_comb         ( ID_o_jal_comb         ),
        .o_immJ_comb        ( ID_o_immJ_comb        ),

        .o_immI             ( ID_o_immI             ),
        .o_immB             ( ID_o_immB             ),
        .o_immU             ( ID_o_immU             ),

        .o_beq              ( ID_o_beq              ),
        .o_bne              ( ID_o_bne              ),
        .o_aluOp            ( ID_o_aluOp            ),
        .o_srcA             ( ID_o_srcA             ),
        .o_srcB             ( ID_o_srcB             ),
        .o_rfwe             ( ID_o_rfwe             ),
        .o_a3               ( ID_o_a3               ),
        
        .i_valid            ( ID_i_valid            ),
        .i_WB_o_valid_comb  ( ID_i_WB_o_valid_comb  ),
        .o_a1               ( ID_o_a1               ),
        .o_a2               ( ID_o_a2               ),
        .o_valid            ( ID_o_valid            ),

        .i_debug_a0         ( ID_i_debug_a0         ),
        .o_debug_rd0        ( ID_o_debug_rd0        )
    );



    ///////////////////////////////////////////////////////////////////////
    // 3) EXECUTE STAGE
    ///////////////////////////////////////////////////////////////////////

    logic [31:0] EX_i_rd1;
    logic [31:0] EX_i_rd2;

    logic [31:0] EX_i_immI;
    logic [31:0] EX_i_immB; 
    logic [31:0] EX_i_immU; 
    
    logic [ 2:0] EX_i_aluOp;
    logic [ 1:0] EX_i_srcA;
    logic [ 2:0] EX_i_srcB;
    logic        EX_i_rfwe;
    logic [ 4:0] EX_i_a3;

    logic        EX_o_alu_zero_comb;
    logic [31:0] EX_o_alu_result;
    logic        EX_o_rfwe;
    logic [ 4:0] EX_o_a3;

    // Hazard
    logic        EX_i_valid;
    logic        EX_i_forwarding_rd1;
    logic        EX_i_forwarding_rd2;
    logic [31:0] EX_i_HU_rd1;
    logic [31:0] EX_i_HU_rd2;
    logic        EX_o_valid;


    sr_EX_stage EX_stage (
        .clk                ( clk                   ),
        .rst                ( rst                   ),

        .i_rd1              ( EX_i_rd1              ),
        .i_rd2              ( EX_i_rd2              ),

        .i_immI             ( EX_i_immI             ),
        .i_immB             ( EX_i_immB             ),
        .i_immU             ( EX_i_immU             ),

        .i_aluOp            ( EX_i_aluOp            ),
        .i_srcA             ( EX_i_srcA             ),
        .i_srcB             ( EX_i_srcB             ),
        .i_rfwe             ( EX_i_rfwe             ),
        .i_a3               ( EX_i_a3               ),

        .o_alu_zero_comb    ( EX_o_alu_zero_comb    ),
        .o_alu_result       ( EX_o_alu_result       ),
        .o_rfwe             ( EX_o_rfwe             ),
        .o_a3               ( EX_o_a3               ),
        
        .i_valid            ( EX_i_valid            ),
        .i_forwarding_rd1   ( EX_i_forwarding_rd1   ),
        .i_forwarding_rd2   ( EX_i_forwarding_rd2   ),
        .i_HU_rd1           ( EX_i_HU_rd1           ),
        .i_HU_rd2           ( EX_i_HU_rd2           ),
        .o_valid            ( EX_o_valid            )
    );
    

    
    ///////////////////////////////////////////////////////////////////////
    // 4) WRITEBACK STAGE
    ///////////////////////////////////////////////////////////////////////

    logic        WB_i_rfwe;
    logic [ 4:0] WB_i_a3;
    logic [31:0] WB_i_alu_result;

    logic        WB_o_rfwe_comb;
    logic [ 4:0] WB_o_a3_comb;
    logic [31:0] WB_o_wd3_comb;
    
    // Hazard
    logic        WB_i_valid;
    logic        WB_o_valid_comb;
    
    sr_WB_stage WB_stage (
        .clk                ( clk                   ),
        .rst                ( rst                   ),

        .i_rfwe             ( WB_i_rfwe             ),
        .i_a3               ( WB_i_a3               ),
        .i_alu_result       ( WB_i_alu_result       ),

        .o_rfwe_comb        ( WB_o_rfwe_comb        ),
        .o_a3_comb          ( WB_o_a3_comb          ),
        .o_wd3_comb         ( WB_o_wd3_comb         ),

        .i_valid            ( WB_i_valid            ),
        .o_valid_comb       ( WB_o_valid_comb       )
    );



    ///////////////////////////////////////////////////////////////////////
    // HAZARD UNIT
    ///////////////////////////////////////////////////////////////////////
    
    logic        HU_i_misprediction;
    logic [ 4:0] HU_i_a1;
    logic [ 4:0] HU_i_a2;
    logic        HU_i_rfwe;
    logic [ 4:0] HU_i_a3;
    logic [31:0] HU_i_alu_result;

    logic        HU_i_IF_o_valid;
    logic        HU_i_ID_o_valid;
    logic        HU_i_EX_o_valid;
    logic        HU_o_IF_i_valid;
    logic        HU_o_ID_i_valid;
    logic        HU_o_EX_i_valid;
    logic        HU_o_WB_i_valid;
    
    logic        HU_o_forwarding_rd1;
    logic        HU_o_forwarding_rd2;
    logic [31:0] HU_o_rd1;
    logic [31:0] HU_o_rd2;
    
    sr_hazard_unit hazard_unit (
        .clk                ( clk                   ),
        .rst                ( rst                   ),

        .i_misprediction    ( HU_i_misprediction    ),
        .i_a1               ( HU_i_a1               ),
        .i_a2               ( HU_i_a2               ),
        .i_rfwe             ( HU_i_rfwe             ),
        .i_a3               ( HU_i_a3               ),
        .i_alu_result       ( HU_i_alu_result       ),

        .i_IF_o_valid       ( HU_i_IF_o_valid       ),
        .i_ID_o_valid       ( HU_i_ID_o_valid       ),
        .i_EX_o_valid       ( HU_i_EX_o_valid       ),
        .o_IF_i_valid       ( HU_o_IF_i_valid       ),
        .o_ID_i_valid       ( HU_o_ID_i_valid       ),
        .o_EX_i_valid       ( HU_o_EX_i_valid       ),
        .o_WB_i_valid       ( HU_o_WB_i_valid       ),

        .o_forwarding_rd1   ( HU_o_forwarding_rd1   ),
        .o_forwarding_rd2   ( HU_o_forwarding_rd2   ),
        .o_rd1              ( HU_o_rd1              ),
        .o_rd2              ( HU_o_rd2              )
    );


    
    ///////////////////////////////////////////////////////////////////////
    // CONNECTIONS
    ///////////////////////////////////////////////////////////////////////
    
    assign IF_i_jal_comb        = ID_o_jal_comb;
    assign IF_i_immJ_comb       = ID_o_immJ_comb;
    assign IF_i_beq             = ID_o_beq;
    assign IF_i_bne             = ID_o_bne;
    assign IF_i_immB            = ID_o_immB;
    assign IF_i_alu_zero_comb   = EX_o_alu_zero_comb;
    
    assign ID_i_instr           = IF_o_instr;
    assign ID_i_rfwe_comb       = WB_o_rfwe_comb;
    assign ID_i_a3_comb         = WB_o_a3_comb;
    assign ID_i_wd3_comb        = WB_o_wd3_comb;

    assign EX_i_rd1             = ID_o_rd1;
    assign EX_i_rd2             = ID_o_rd2;
    assign EX_i_immI            = ID_o_immI;
    assign EX_i_immB            = ID_o_immB;
    assign EX_i_immU            = ID_o_immU;
    assign EX_i_aluOp           = ID_o_aluOp;
    assign EX_i_srcA            = ID_o_srcA;
    assign EX_i_srcB            = ID_o_srcB;
    assign EX_i_rfwe            = ID_o_rfwe;
    assign EX_i_a3              = ID_o_a3;

    assign WB_i_rfwe            = EX_o_rfwe;
    assign WB_i_a3              = EX_o_a3;
    assign WB_i_alu_result      = EX_o_alu_result;


    // HAZARD

    assign HU_i_misprediction   = IF_o_misprediction;
    assign HU_i_a1              = ID_o_a1;
    assign HU_i_a2              = ID_o_a2;
    assign HU_i_rfwe            = EX_o_rfwe;
    assign HU_i_a3              = EX_o_a3;
    assign HU_i_alu_result      = EX_o_alu_result;

    assign HU_i_IF_o_valid      = IF_o_valid;
    assign HU_i_ID_o_valid      = ID_o_valid;
    assign HU_i_EX_o_valid      = EX_o_valid;
    assign IF_i_valid           = HU_o_IF_i_valid;
    assign ID_i_valid           = HU_o_ID_i_valid;
    assign EX_i_valid           = HU_o_EX_i_valid;
    assign WB_i_valid           = HU_o_WB_i_valid;
    
    assign IF_i_ID_o_valid      = ID_o_valid;

    assign ID_i_WB_o_valid_comb = WB_o_valid_comb;

    assign EX_i_forwarding_rd1  = HU_o_forwarding_rd1;
    assign EX_i_forwarding_rd2  = HU_o_forwarding_rd2;
    assign EX_i_HU_rd1          = HU_o_rd1;
    assign EX_i_HU_rd2          = HU_o_rd2;

    
    // DEBUG REGISTER ACCESS

    assign ID_i_debug_a0        = regAddr;
    assign regData              = (regAddr != '0) ? ID_o_debug_rd0 : IF_o_debug_pc;

endmodule
