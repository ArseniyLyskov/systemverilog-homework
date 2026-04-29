module sr_hazard_unit (
    input  logic        clk,
    input  logic        rst,
    
    input  logic        i_misprediction,
    input  logic [ 4:0] i_a1,
    input  logic [ 4:0] i_a2,
    input  logic        i_rfwe,
    input  logic [ 4:0] i_a3,
    input  logic [31:0] i_alu_result,

    input  logic        i_IF_o_valid,
    input  logic        i_ID_o_valid,
    input  logic        i_EX_o_valid,
    output logic        o_IF_i_valid,
    output logic        o_ID_i_valid,
    output logic        o_EX_i_valid,
    output logic        o_WB_i_valid,
    
    output logic        o_forwarding_rd1,
    output logic        o_forwarding_rd2,
    output logic [31:0] o_rd1,
    output logic [31:0] o_rd2
);

    logic        stash_valid;
    logic        stash_rfwe;
    logic [ 4:0] stash_a3;
    logic [31:0] stash_alu_result;

    always_comb begin
        o_forwarding_rd1 = '0;
        o_forwarding_rd2 = '0;
        o_rd1            = 'x;
        o_rd2            = 'x;
        
        if (stash_valid & stash_rfwe) begin 
            if (i_a1 == stash_a3) begin 
                o_forwarding_rd1 = '1;
                o_rd1            = stash_alu_result;
            end
            if (i_a2 == stash_a3) begin 
                o_forwarding_rd2 = '1;
                o_rd2            = stash_alu_result;
            end
        end
        
        if (i_EX_o_valid & i_rfwe) begin 
            if (i_a1 == i_a3) begin 
                o_forwarding_rd1 = '1;
                o_rd1            = i_alu_result;
            end
            if (i_a2 == i_a3) begin 
                o_forwarding_rd2 = '1;
                o_rd2            = i_alu_result;
            end
        end
    end

    assign o_IF_i_valid = '1;
    assign o_ID_i_valid = i_IF_o_valid & ~i_misprediction;
    assign o_EX_i_valid = i_ID_o_valid;
    assign o_WB_i_valid = i_EX_o_valid;
    
    always_ff @(posedge clk)
        if (rst) begin
            stash_valid <= '0;
            stash_rfwe  <= '0;
        end else begin 
            stash_valid <= i_EX_o_valid;
            stash_rfwe  <= i_rfwe;
        end

    always_ff @(posedge clk)
        if (i_EX_o_valid) begin 
            stash_a3         <= i_a3;
            stash_alu_result <= i_alu_result;
        end

endmodule
