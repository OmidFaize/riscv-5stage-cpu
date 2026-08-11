`timescale 1ns / 1ps

module ex_mem_reg(
    input logic clk,
    input logic reset,
    input logic reg_write_ex,
    input logic mem_read_ex,
    input logic mem_write_ex,
    input logic jump_ex,
    input logic [31:0] alu_result_ex,
    input logic [31:0] rs2_data_ex,
    input logic [4:0] rd_addr_ex,
    input logic [31:0] link_value_ex,
    
    output logic reg_write_mem,
    output logic mem_read_mem,
    output logic mem_write_mem,
    output logic jump_mem,
    output logic [31:0] alu_result_mem,
    output logic [31:0] rs2_data_mem,
    output logic [4:0] rd_addr_mem,
    output logic [31:0] link_value_mem
    );
    
    always_ff @(posedge clk) begin
        
        // Reset
        if (reset) begin
            reg_write_mem <= 1'b0;
            mem_write_mem <= 1'b0;
            mem_read_mem <= 1'b0;
            jump_mem <= 1'b0;
        end
        
        // Normal latch operation
        else begin
            reg_write_mem <= reg_write_ex;
            mem_read_mem <= mem_read_ex;
            mem_write_mem <= mem_write_ex;
            alu_result_mem <= alu_result_ex;
            rs2_data_mem <= rs2_data_ex;
            rd_addr_mem <= rd_addr_ex;
            jump_mem <= jump_ex;
            link_value_mem <= link_value_ex;
        end
        
    end
    
endmodule
