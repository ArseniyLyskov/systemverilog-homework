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

module sr_cpu
(
    input           clk,      // clock
    input           rst,      // reset

    output  [31:0]  imAddr,   // instruction memory address
    input   [31:0]  imData,   // instruction memory data

    input   [ 4:0]  regAddr,  // debug access reg address
    output  [31:0]  regData   // debug access reg data
);
    // control wires

    wire        aluZero;
    wire        pcSrc;
    wire        regWrite;
    wire        aluSrc;
    wire  [1:0] wdSrc;
    wire  [2:0] aluControl;
    wire        stall;

    // instruction decode wires

    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    // program counter

    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 32'd4;
    wire [31:0] pcNext   = pcSrc ? pcBranch : pcPlus4;

    register_with_rst_and_en r_pc
    (
        .clk      ( clk       ),
        .rst      ( rst       ),
        .en       ( ~stall    ),
        .d        ( pcNext    ),
        .q        ( pc        )
    );

    // program memory access

    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    // instruction decode

    sr_decode id
    (
        .instr      ( instr       ),
        .cmdOp      ( cmdOp       ),
        .rd         ( rd          ),
        .cmdF3      ( cmdF3       ),
        .rs1        ( rs1         ),
        .rs2        ( rs2         ),
        .cmdF7      ( cmdF7       ),
        .immI       ( immI        ),
        .immB       ( immB        ),
        .immU       ( immU        )
    );

    // register file

    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    logic [31:0] wd3;

    sr_register_file i_rf
    (
        .clk        ( clk         ),
        .a0         ( regAddr     ),
        .a1         ( rs1         ),
        .a2         ( rs2         ),
        .a3         ( rd          ),
        .rd0        ( rd0         ),
        .rd1        ( rd1         ),
        .rd2        ( rd2         ),
        .wd3        ( wd3         ),
        .we3        ( regWrite & ~stall
        )
    );

    // alu

    wire [31:0] srcB = aluSrc ? immI : rd2;
    wire [31:0] aluResult;

    sr_alu alu
    (
        .srcA       ( rd1         ),
        .srcB       ( srcB        ),
        .oper       ( aluControl  ),
        .zero       ( aluZero     ),
        .result     ( aluResult   )
    );

    // mdu

    wire        mdu_i_vld;
    wire        mdu_o_vld;
    wire [31:0] mdu_result;
    wire        mdu_busy;

    sr_mdu mdu
    (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .i_vld      ( mdu_i_vld   ),
        .srcA       ( rd1         ),
        .srcB       ( rd2         ),
        .o_vld      ( mdu_o_vld   ),
        .result     ( mdu_result  ),
        .busy       ( mdu_busy    )
    );

    // control

    sr_control sm_control
    (
        .cmdOp      ( cmdOp       ),
        .cmdF3      ( cmdF3       ),
        .cmdF7      ( cmdF7       ),
        .aluZero    ( aluZero     ),
        .pcSrc      ( pcSrc       ),
        .regWrite   ( regWrite    ),
        .aluSrc     ( aluSrc      ),
        .wdSrc      ( wdSrc       ),
        .aluControl ( aluControl  ),
        .mdu_i_vld  ( mdu_i_vld   ),
        .mdu_o_vld  ( mdu_o_vld   ),
        .mdu_busy   ( mdu_busy    ),
        .stall      ( stall       )
    );

    always_comb 
        case (wdSrc) 
            `WD_ALU  : wd3 = aluResult;
            `WD_IMMU : wd3 = immU;
            `WD_MDU  : wd3 = mdu_result;
            default  : wd3 = 'x;
        endcase

    // debug register access

    assign regData = (regAddr != '0) ? rd0 : pc;

endmodule
