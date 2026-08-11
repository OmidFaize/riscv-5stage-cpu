`timescale 1ns / 1ps

module mem_wb_reg(
    input logic clk,
    input logic reset,
    input logic reg_write_mem,
    input logic mem_read_mem,
    input logic jump_mem,
    input logic [31:0] alu_result_mem,
    input logic [31:0] read_data_mem,
    input logic [4:0] rd_addr_mem,
    input logic [31:0] link_value_mem,
    
    output logic reg_write_wb,
    output logic mem_read_wb,
    output logic jump_wb,
    output logic [31:0] alu_result_wb,
    output logic [31:0] read_data_wb,
    output logic [4:0] rd_addr_wb,
    output logic [31:0] link_value_wb
    );
    
    
    always_ff @ (posedge clk) begin
        
        // Reset
        if (reset) begin
            reg_write_wb <= 1'b0;
            mem_read_wb <= 1'b0;
            jump_wb <= 1'b0;
        end
        
        // Normal latch operation
        else begin
            reg_write_wb <= reg_write_mem;
            mem_read_wb <= mem_read_mem;
            alu_result_wb <= alu_result_mem;
            read_data_wb <= read_data_mem;
            rd_addr_wb <= rd_addr_mem;
            jump_wb <= jump_mem;
            link_value_wb <= link_value_mem;
        end
        
    end
    
endmodule
