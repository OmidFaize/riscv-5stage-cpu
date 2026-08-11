`timescale 1ns / 1ps

module tb_regfile;

logic clk;
logic [4:0] rs1_addr;
logic [4:0] rs2_addr;
logic [4:0] rd_addr;
logic [31:0] write_data;
logic write_en;
logic [31:0] rs1_data;
logic [31:0] rs2_data;

regfile dut (
    .clk (clk),
    .rs1_addr (rs1_addr),
    .rs2_addr (rs2_addr),
    .rd_addr (rd_addr),
    .write_data (write_data),
    .write_en (write_en),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data)
);

    initial clk = 0;
    always #5 clk = ~clk;  // 1 clk cycle = 10 ns
    
    initial begin
    
        write_en = 0;
        rd_addr = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        write_data = 0;
        
        // Test 1: Write then read
        @(negedge clk);
        write_en = 1;
        rd_addr = 5'd5;
        write_data = 32'hAAAAAAAA;
        
        @(negedge clk);
        write_en = 0;
        rs1_addr = 5'd5;
        #1;
        
        if (rs1_data == 32'hAAAAAAAA)
        $display ("Test 1 PASS");
        else
        $display ("Test 1 FAIL: rs1_data=%h", rs1_data);
        
        // Test 2: x0 register protection
        @(negedge clk);
        write_en = 1;
        rd_addr = 5'd0;
        write_data = 32'hBBBBBBBB;
        
        @(negedge clk);
        write_en = 0;
        rs1_addr = 5'd0;
        #1;
        
        if (rs1_data == 32'h0)
        $display ("Test 2 PASS");
        else
        $display ("Test 2 FAIL: rs1_data=%h", rs1_data);
         
        // Test 3: Write bypass
        @(negedge clk);
        write_en = 1;
        rd_addr = 5'd7;
        write_data = 32'h12345678;
        
        // Intentionally have read before x7 is written for bypass condition
        rs1_addr = 5'd7;
        #1;
        if (rs1_data == 32'h12345678)
        $display ("Test 3 PASS");
        else
        $display ("Test 3 FAIL: rs1_data=%h", rs1_data);
        
        
        $finish;
        
        
    end

endmodule
