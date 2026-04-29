module sr_IF_stage #(
    parameter           ROM_SIZE
) (
    input  logic        clk,
    input  logic        rst, 

    input  logic        i_jal_comb,
    input  logic [31:0] i_immJ_comb,

    input  logic        i_beq,
    input  logic        i_bne,
    input  logic [31:0] i_immB,
    input  logic        i_alu_zero_comb,

    output logic [31:0] o_instr_addr,
    
    // Hazard
    input  logic        i_valid,
    input  logic        i_ID_o_valid,
    output logic        o_misprediction,
    output logic        o_valid,

    // Debug
    output logic [31:0] o_debug_pc
);

    logic [31:0] pc_prev;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic        branch;
    logic        was_reset;
    
    assign branch       = i_beq & i_alu_zero_comb | i_bne & ~i_alu_zero_comb;
    assign o_instr_addr = o_valid ? (pc_next >> 2) : (pc >> 2);
    
    always_comb begin 
        o_misprediction = '0;
        pc_next         = pc + 32'd4;

        if (i_ID_o_valid & branch) begin
            o_misprediction = '1;
            pc_next         = pc_prev + i_immB;
        end else if ((pc_next >> 2) == ROM_SIZE) begin
            pc_next         = '0;
        end
    end

    // Registering
    
    always_ff @(posedge clk)
        if (rst)
            was_reset = '1;
        else
            was_reset = '0;
    
    always_ff @(posedge clk)
        if (rst)          
            pc <= '0;
        else if (i_valid & ~was_reset) 
            { pc_prev, pc } <= { pc, pc_next };

    always_ff @(posedge clk)
        if (rst)          
            o_valid <= '0;
        else              
            o_valid <= i_valid;
    
    // Debug
    assign o_debug_pc = pc;

endmodule
