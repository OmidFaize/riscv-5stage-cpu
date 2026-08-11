`timescale 1ns / 1ps

module tb_ex_mem_reg;

logic clk;
logic reset;
logic reg_write_ex;
logic mem_read_ex;
logic mem_write_ex;
logic [31:0] alu_result_ex;
logic [31:0] rs2_data_ex;
logic [4:0] rd_addr_ex;
logic jump_ex;
logic [31:0] link_value_ex;
 
logic reg_write_mem;
logic mem_read_mem;
logic mem_write_mem;
logic [31:0] alu_result_mem;
logic [31:0] rs2_data_mem;
logic [4:0] rd_addr_mem;
logic jump_mem;
logic [31:0] link_value_mem;

ex_mem_reg dut (
    .clk (clk),
    .reset (reset),
    .reg_write_ex (reg_write_ex),
    .mem_read_ex (mem_read_ex),
    .mem_write_ex (mem_write_ex),
    .alu_result_ex (alu_result_ex),
    .rs2_data_ex (rs2_data_ex),
    .rd_addr_ex (rd_addr_ex),
    .jump_ex (jump_ex),
    .link_value_ex (link_value_ex),
    .reg_write_mem (reg_write_mem),
    .mem_read_mem (mem_read_mem),
    .mem_write_mem (mem_write_mem),
    .alu_result_mem (alu_result_mem),
    .rs2_data_mem (rs2_data_mem),
    .rd_addr_mem (rd_addr_mem),
    .jump_mem (jump_mem),
    .link_value_mem (link_value_mem)
);

    initial clk = 0;
    always #5 clk = ~clk;  // 1 clk cycle = 10 ns
    
    initial begin
        
        reset = 0;
        
        // Test 1: Normal latch
        @(negedge clk);
        reg_write_ex = 1'b1;
        mem_read_ex = 1'b1;
        mem_write_ex = 1'b1;
        alu_result_ex = 32'hAAAAAAAA;
        rs2_data_ex = 32'hBBBBBBBB;
        rd_addr_ex = 5'b11111; 
        
        @(negedge clk);
        if ((reg_write_mem == 1'b1) && (mem_read_mem == 1'b1) && (mem_write_mem == 1'b1) && (alu_result_mem == 32'hAAAAAAAA) && (rs2_data_mem == 32'hBBBBBBBB) && (rd_addr_mem == 5'b11111)) begin
            $display ("Test 1 PASS");
        end
        
        else begin
            $display ("Test 1 FAIL: reg_write_mem=%b, mem_read_mem=%b, mem_write_mem=%b, alu_result_mem=%b, rs2_data_mem=%b, rd_addr_mem=%b", reg_write_mem, mem_read_mem, mem_write_mem, alu_result_mem, rs2_data_mem, rd_addr_mem);
        end
        
        // Test 2: Reset
        #10;
        reset = 1;
        
        #5;
        @(negedge clk);
        
        reset = 0;
        
        if ((reg_write_mem == 1'b0) && (mem_read_mem == 1'b0) && (mem_write_mem == 1'b0)) begin
            $display ("Test 2 PASS");
        end
            
        else begin
            $display ("Test 2 FAIL: reg_write_mem=%b, mem_read_mem=%b, mem_write_mem=%b", reg_write_mem, mem_read_mem, mem_write_mem);
        end
        
        
        // Test 3: Reset dominance
        @(negedge clk);
        reg_write_ex = 1'b1; 
        mem_read_ex = 1'b1; 
        mem_write_ex = 1'b1;
        alu_result_ex = 32'hCCCCCCCC;
        
        reset = 1;
                
        @(negedge clk);
        if ((reg_write_mem == 1'b0) && (mem_read_mem == 1'b0) && (mem_write_mem == 1'b0)) begin
            $display ("Test 3 PASS");
        end
            
        else begin
            $display ("Test 3 FAIL: reg_write_mem=%b, mem_read_mem=%b, mem_write_mem=%b", reg_write_mem, mem_read_mem, mem_write_mem);
        end
        
        $finish;
        
        
    end

endmodule
