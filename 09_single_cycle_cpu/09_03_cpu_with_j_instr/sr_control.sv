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

module sr_control
(
    input        [ 6:0] cmdOp,
    input        [ 2:0] cmdF3,
    input        [ 6:0] cmdF7,
    input               aluZero,
    output logic [ 1:0] pcSrc,
    output logic        regWrite,
    output logic        aluSrc,
    output logic [ 1:0] wdSrc,
    output logic [ 2:0] aluControl
);

    always_comb
    begin
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        wdSrc       = `WD_ALU;
        pcSrc       = `PC_PLUS4;
        aluControl  = `ALU_ADD;

        casez ({ cmdF7, cmdF3, cmdOp })
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = `WD_IMMU; end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin aluControl = `ALU_SUB; if ( aluZero) pcSrc = `PC_BRANCH; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin aluControl = `ALU_SUB; if (~aluZero) pcSrc = `PC_BRANCH; end
            
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_JAL  } : begin regWrite = 1'b1; wdSrc = `WD_IMMJ; pcSrc = `PC_JAL; end 
        endcase
    end

endmodule
