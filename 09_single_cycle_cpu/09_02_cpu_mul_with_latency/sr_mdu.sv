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

module sr_mdu
# (
    parameter n_delay = 2
)
(
    input               clk,
    input               rst,

    input               i_vld,
    input        [31:0] srcA,
    input        [31:0] srcB,
    output              o_vld,
    output logic [31:0] result,
    output              busy
);

    logic [n_delay - 1:0] shift_valid;

    always_ff @(posedge clk)
        if (rst)    shift_valid <= '0;
        else        shift_valid <= { shift_valid[n_delay - 2:0], i_vld };
        
    assign o_vld =  shift_valid[n_delay - 1];
    assign busy  = |shift_valid;

    shift_register_with_valid #(
        .width      ( 32            ),
        .depth      ( n_delay       )
    ) shift_data (
        .clk        ( clk           ),
        .valid      ( { shift_valid[n_delay - 2:0], i_vld } ),
        .in_data    ( srcA * srcB   ),
        .out_data   ( result        )
    );

endmodule

//----------------------------------------------------------------------------

module shift_register_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input  [depth - 1:0] valid,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);
    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
    begin
        if (valid[0])
            data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            if (valid[i])
                data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule

