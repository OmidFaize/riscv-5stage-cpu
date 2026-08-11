`timescale 1ns / 1ps

module id_ex_reg(
    input logic clk,
    input logic reset,
    input logic flush,          // from EX branch logic
    input logic bubble,         // from ID hazard unit
    input logic reg_write_id,
    input logic mem_read_id,
    input logic mem_write_id,
    input logic branch_id,
    input logic jump_id,
    input logic jalr_id,
    input logic alu_src_id,
    input logic [1:0] alu_op_id,
    input logic [2:0] funct3_id,
    input logic [31:0] rs1_data_id,
    input logic [31:0] rs2_data_id,
    input logic [31:0] imm_id,
    input logic [31:0] pc_id,
    input logic [4:0] rd_addr_id,
    input logic [4:0] rs1_addr_id,
    input logic [4:0] rs2_addr_id,
    input logic funct7_5_id,
    
    output logic reg_write_ex,
    output logic mem_read_ex,
    output logic mem_write_ex,
    output logic branch_ex,
    output logic jump_ex,
    output logic jalr_ex,
    output logic alu_src_ex,
    output logic [1:0] alu_op_ex,
    output logic [2:0] funct3_ex,
    output logic [31:0] rs1_data_ex,
    output logic [31:0] rs2_data_ex,
    output logic [31:0] imm_ex,
    output logic [31:0] pc_ex,
    output logic [4:0] rd_addr_ex,
    output logic [4:0] rs1_addr_ex,
    output logic [4:0] rs2_addr_ex,
    output logic funct7_5_ex
    );
    
    always_ff @ (posedge clk) begin
                
        // Branch flush or load-use stall bubble to inject a NOP
        if (reset || flush || bubble) begin
            reg_write_ex <= 1'b0;
            mem_write_ex <= 1'b0;
            mem_read_ex <= 1'b0;
            branch_ex <= 1'b0;
            jump_ex <= 1'b0;
            jalr_ex <= 1'b0;
        end
         
        // Normal latch operation
        else begin
            reg_write_ex <= reg_write_id;
            mem_read_ex <= mem_read_id;
            mem_write_ex <= mem_write_id;
            branch_ex <= branch_id;
            jump_ex <= jump_id;
            jalr_ex <= jalr_id;
            alu_src_ex <= alu_src_id;
            alu_op_ex <= alu_op_id;
            funct3_ex <= funct3_id;
            rs1_data_ex <= rs1_data_id;
            rs2_data_ex <= rs2_data_id;
            imm_ex <= imm_id;
            pc_ex <= pc_id;
            rd_addr_ex <= rd_addr_id;
            rs1_addr_ex <= rs1_addr_id;
            rs2_addr_ex <= rs2_addr_id;
            funct7_5_ex <= funct7_5_id;
        end
        
    end
    
endmodule
