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

module cpu_cluster
#(
    parameter nCPUs       = 3,
    parameter ROM_SIZE    = 64,
    parameter ROM_BANKS_W = 2
)
(
    input                        clk,      // clock
    input                        rst,      // reset

    input   [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input   [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output  [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

    localparam ROM_ADDR_W  = $clog2(ROM_SIZE);
    localparam ROM_N_BANKS = 2**ROM_BANKS_W;


    // CPUs
    
    logic [31:0] imAddr    [nCPUs - 1:0];
    logic [31:0] imData    [nCPUs - 1:0];
    logic        imDataVld [nCPUs - 1:0];
    
    generate 
        for (genvar i = 0; i < nCPUs; i++) begin : CPUs
            sr_cpu cpu (
                .clk        ( clk           ),
                .rst        ( rst           ),
                .rstPC      ( rstPC     [i] ),

                .imAddr     ( imAddr    [i] ),
                .imData     ( imData    [i] ),
                .imDataVld  ( imDataVld [i] ), 

                .regAddr    ( regAddr   [i] ),
                .regData    ( regData   [i] )
            );
        end
    endgenerate
    
    
    // Arbiters

    logic [7:0] arbiter_req [ROM_N_BANKS - 1:0];
    logic [7:0] arbiter_gnt [ROM_N_BANKS - 1:0];

    generate 
        for (genvar i = 0; i < ROM_N_BANKS; i++) begin : Arbiters
            round_robin_arbiter_8 round_robin_arbiter_8 (
                .clk    ( clk               ),
                .rst    ( rst               ),
                .req    ( arbiter_req[i]    ),
                .gnt    ( arbiter_gnt[i]    )
            );
        end
    endgenerate


    // Banked instruction ROM

    logic [ROM_ADDR_W - ROM_BANKS_W - 1:0] rom_address [ROM_N_BANKS - 1:0];
    logic [                          31:0] rom_data    [ROM_N_BANKS - 1:0];

    banked_instruction_rom #(
        .SIZE       ( ROM_SIZE      ),
        .BANKS_W    ( ROM_BANKS_W   )        
    ) banked_instruction_rom (
        .address    ( rom_address   ),
        .data       ( rom_data      )
    );
    

    // CPU connections
    
    always_comb begin : CPU_connections
        logic [ROM_BANKS_W - 1:0]              bank;
        logic [ROM_ADDR_W - ROM_BANKS_W - 1:0] address;
        logic                                  bank_granted;

        for (int bank = 0; bank < ROM_N_BANKS; bank++) begin 
            rom_address[bank] = 'x;
            arbiter_req[bank] = '0;
        end

        for (int cpu = 0; cpu < nCPUs; cpu++) begin 
                
            // Request bank by CPU
            { address, bank }      = imAddr[cpu];
            arbiter_req[bank][cpu] = 1'b1;

        end
            
        for (int cpu = 0; cpu < nCPUs; cpu++) begin 
            { address, bank }      = imAddr[cpu];

            // Arbiter response
            bank_granted           = arbiter_gnt[bank][cpu];
            imDataVld[cpu]         = bank_granted;
            
            // Select bank address if granted
            if (bank_granted)
                rom_address[bank]  = address;
            
            // Get instruction
            imData[cpu]            = rom_data[bank];
        end

    end

endmodule



module banked_instruction_rom #(
    parameter SIZE    = 64,
    parameter BANKS_W = 2
) (
    input  logic [$clog2(SIZE) - BANKS_W - 1:0] address [2**BANKS_W - 1:0],
    output logic [                        31:0] data    [2**BANKS_W - 1:0]
);
    localparam N_BANKS = 2**BANKS_W;

    logic [31:0] rom [0:SIZE - 1];

    always_comb 
        for (int i = 0; i < N_BANKS; i++) 
            data[i] = rom[{ address[i], BANKS_W'(i) }];

    initial $readmemh ("program.hex", rom);

endmodule
