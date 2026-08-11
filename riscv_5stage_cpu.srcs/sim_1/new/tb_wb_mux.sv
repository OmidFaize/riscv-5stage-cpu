`timescale 1ns / 1ps

module tb_wb_mux;

logic jump_wb;
logic mem_read_wb;
logic [31:0] alu_result_wb;
logic [31:0] read_data_wb;
logic [31:0] wb_data;
logic [31:0] link_value_wb;

wb_mux dut (
    .jump_wb (jump_wb),
    .mem_read_wb (mem_read_wb),
    .alu_result_wb (alu_result_wb),
    .read_data_wb (read_data_wb),
    .link_value_wb (link_value_wb),
    .wb_data (wb_data)
);

    initial begin
        
        alu_result_wb = 32'hAAAAAAAA;
        read_data_wb = 32'hBBBBBBBB;
        link_value_wb = 32'hCCCCCCCC;
        
        // Test 1: alu_result_wb path
        mem_read_wb = 0;
        #1;
        
        if (wb_data == alu_result_wb) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: wb_data=%h", wb_data);
        end
        
        // Test 2: read_data_wb path
        mem_read_wb = 1;
        #1;
        
        if (wb_data == read_data_wb) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: wb_data=%h", wb_data);
        end
        
        // Test 3: link_value_wb path
        jump_wb = 1;
        #1;
        
        if (wb_data == link_value_wb) begin
            $display("Test 3 PASS");
        end
        
        else begin
            $display("Test 3 FAIL: link_value_wb=%h", link_value_wb);
        end
        
    end

endmodule
