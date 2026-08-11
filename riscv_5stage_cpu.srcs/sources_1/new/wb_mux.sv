`timescale 1ns / 1ps

module wb_mux(
    input logic jump_wb,
    input logic mem_read_wb,
    input logic [31:0] alu_result_wb,
    input logic [31:0] read_data_wb, // From dmem
    input logic [31:0] link_value_wb,
    
    
    output logic [31:0] wb_data
    );
    
    // jump_wb = 1 ---> link_value_wb
    // mem_read_wb = 1 ---> read_data_wb
    // otherwise default to alu_result_wb
    always_comb begin
        wb_data = alu_result_wb;
        
        if (jump_wb) begin
            wb_data = link_value_wb;
        end
        
        else if (mem_read_wb) begin
            wb_data = read_data_wb;
        end
        
    end
    
endmodule