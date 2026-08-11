`timescale 1ns / 1ps

module tb_mem_wb_reg;

logic clk;
logic reset;
logic reg_write_mem;
logic mem_read_mem;
logic [31:0] alu_result_mem;
logic [31:0] read_data_mem;
logic [4:0] rd_addr_mem;
logic jump_mem; 
logic [31:0] link_value_mem;

logic reg_write_wb;
logic mem_read_wb;
logic [31:0] alu_result_wb;
logic [31:0] read_data_wb;
logic [4:0] rd_addr_wb;
logic jump_wb; 
logic [31:0] link_value_wb;
 
mem_wb_reg dut (
    .clk (clk),
    .reset (reset),
    .reg_write_mem (reg_write_mem),
    .mem_read_mem (mem_read_mem),
    .alu_result_mem (alu_result_mem),
    .read_data_mem (read_data_mem),
    .rd_addr_mem (rd_addr_mem),
    .jump_mem (jump_mem),
    .link_value_mem (link_value_mem),
    .reg_write_wb (reg_write_wb),
    .mem_read_wb (mem_read_wb),
    .alu_result_wb (alu_result_wb),
    .read_data_wb (read_data_wb),
    .rd_addr_wb (rd_addr_wb),
    .jump_wb (jump_wb),            
    .link_value_wb (link_value_wb)  
);

    initial clk = 0;
    always #5 clk = ~clk;  // 1 clk cycle = 10 ns
    
    initial begin
        
        reset = 0;
        
        // Test 1: Normal latch
        @(negedge clk);
        reg_write_mem = 1'b1;
        mem_read_mem = 1'b1;
        alu_result_mem = 32'hAAAAAAAA;
        read_data_mem = 32'hBBBBBBBB;
        rd_addr_mem = 5'b11111;
        
        @(negedge clk);
        if ((reg_write_wb == 1'b1) && (mem_read_wb == 1'b1) && (alu_result_wb == 32'hAAAAAAAA) && (read_data_wb == 32'hBBBBBBBB) && (rd_addr_wb == 5'b11111)) begin
            $display ("Test 1 PASS");
        end
        
        else begin
            $display ("Test 1 FAIL: reg_write_wb=%b, mem_read_wb=%b, alu_result_wb=%b, read_data_wb=%b, rd_addr_wb=%b", reg_write_wb, mem_read_wb, alu_result_wb, read_data_wb, rd_addr_wb);
        end
        
        // Test 2: Reset
        #10;
        reset = 1;
        
        #5;
        @(negedge clk);
        
        reset = 0;
        
        if ((reg_write_wb == 1'b0) && (mem_read_wb == 1'b0)) begin
            $display ("Test 2 PASS");
        end
            
        else begin
            $display ("Test 2 FAIL: reg_write_wb=%b, mem_read_wb=%b", reg_write_wb, mem_read_wb);
        end
        
        // Test 3: Reset dominance
        @(negedge clk);
        reg_write_mem = 1'b1; 
        mem_read_mem = 1'b1; 
        alu_result_mem = 32'hCCCCCCCC;
        read_data_mem = 32'hDDDDDDDD;
        
        reset = 1;
                
        @(negedge clk);
        if ((reg_write_wb == 1'b0) && (mem_read_wb == 1'b0)) begin
            $display ("Test 3 PASS");
        end
            
        else begin
            $display ("Test 3 FAIL: reg_write_wb=%b, mem_read_wb=%b", reg_write_wb, mem_read_wb);
        end
        
        $finish;
        
    end

endmodule
