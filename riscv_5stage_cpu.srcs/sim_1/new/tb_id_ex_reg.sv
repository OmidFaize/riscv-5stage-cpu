`timescale 1ns / 1ps

module tb_id_ex_reg;

logic clk; 
logic reset;
logic flush;          // from EX branch logic
logic bubble;         // from ID hazard unit
logic reg_write_id;
logic mem_read_id;
logic mem_write_id;
logic branch_id;
logic jump_id;
logic alu_src_id;
logic [1:0] alu_op_id;
logic [2:0] funct3_id;
logic [31:0] rs1_data_id;
logic [31:0] rs2_data_id;
logic [31:0] imm_id;
logic [31:0] pc_id;
logic [4:0] rd_addr_id;
logic [4:0] rs1_addr_id;
logic [4:0] rs2_addr_id;
logic funct7_5_id;
logic jalr_id;
    
logic reg_write_ex;
logic mem_read_ex;
logic mem_write_ex;
logic branch_ex;
logic jump_ex;
logic alu_src_ex;
logic [1:0] alu_op_ex;
logic [2:0] funct3_ex;
logic [31:0] rs1_data_ex;
logic [31:0] rs2_data_ex;
logic [31:0] imm_ex;
logic [31:0] pc_ex;
logic [4:0] rd_addr_ex;
logic [4:0] rs1_addr_ex;
logic [4:0] rs2_addr_ex;
logic funct7_5_ex;
logic jalr_ex;

id_ex_reg dut (
    .clk (clk),
    .reset (reset),
    .flush (flush),                 // from EX branch logic
    .bubble (bubble),               // from ID hazard unit
    .reg_write_id (reg_write_id),
    .mem_read_id (mem_read_id),
    .mem_write_id (mem_write_id),
    .branch_id (branch_id),
    .jump_id (jump_id),
    .alu_src_id (alu_src_id),
    .alu_op_id (alu_op_id),
    .funct3_id (funct3_id),
    .rs1_data_id (rs1_data_id),
    .rs2_data_id (rs2_data_id),
    .imm_id (imm_id),
    .pc_id (pc_id),
    .rd_addr_id (rd_addr_id),
    .rs1_addr_id (rs1_addr_id),
    .rs2_addr_id (rs2_addr_id),
    .funct7_5_id (funct7_5_id),
    .jalr_id (jalr_id),
    .reg_write_ex (reg_write_ex),
    .mem_read_ex (mem_read_ex),
    .mem_write_ex (mem_write_ex),
    .branch_ex (branch_ex),
    .jump_ex (jump_ex),
    .alu_src_ex (alu_src_ex),
    .alu_op_ex (alu_op_ex),
    .funct3_ex (funct3_ex),
    .rs1_data_ex (rs1_data_ex),
    .rs2_data_ex (rs2_data_ex),
    .imm_ex (imm_ex),
    .pc_ex (pc_ex),
    .rd_addr_ex (rd_addr_ex),
    .rs1_addr_ex (rs1_addr_ex),
    .rs2_addr_ex (rs2_addr_ex),
    .funct7_5_ex (funct7_5_ex),
    .jalr_ex (jalr_ex)
);

    initial clk = 0;
    always #5 clk = ~clk;  // 1 clk cycle = 10 ns
    
    initial begin
        
        reset = 0;
        flush = 0;
        bubble = 0;
        
        // Test 1: Normal latch
        
        @(negedge clk);
        reg_write_id = 1'b1;
        mem_read_id = 1'b1;
        mem_write_id = 1'b1;
        branch_id = 1'b1;
        jump_id = 1'b1;
        alu_src_id = 1'b1;
        alu_op_id = 2'b11;
        funct3_id = 3'b111;
        rs1_data_id = 32'hAAAAAAAA;
        rs2_data_id = 32'hAAAAAAAA;
        imm_id = 32'hAAAAAAAA;
        pc_id = 32'hAAAAAAAA;
        rd_addr_id = 5'b11111;
        rs1_addr_id = 5'b11111;
        rs2_addr_id = 5'b11111;
        funct7_5_id = 1'b1;
        
        @(negedge clk);
        if ((reg_write_ex == 1'b1) && (mem_read_ex == 1'b1) && (mem_write_ex == 1'b1) && (branch_ex == 1'b1) && (jump_ex == 1'b1) && (alu_src_ex == 1'b1) && (alu_op_ex == 2'b11) && (funct3_ex == 3'b111) && (rs1_data_ex == 32'hAAAAAAAA) && (rs2_data_ex == 32'hAAAAAAAA) && (imm_ex == 32'hAAAAAAAA) && (pc_ex == 32'hAAAAAAAA) && (rd_addr_ex == 5'b11111) && (rs1_addr_ex == 5'b11111) && (rs2_addr_ex == 5'b11111) && (funct7_5_ex == 1'b1)) begin
            $display ("Test 1 PASS");
        end
        
        else begin
            $display ("Test 1 FAIL: reg_write_ex=%b, mem_read_ex=%b, mem_write_ex=%b, branch_ex=%b, jump_ex=%b, alu_src_ex=%b, alu_op_ex=%b, funct3_ex=%b, rs1_data_ex=%h, rs2_data_ex=%h, imm_ex=%h, pc_ex=%h, rd_addr_ex=%h, rs1_addr_ex=%h, rs2_addr_ex=%h, funct7_5_ex=%b", reg_write_ex, mem_read_ex, mem_write_ex, branch_ex, jump_ex, alu_src_ex, alu_op_ex, funct3_ex, rs1_data_ex, rs2_data_ex, imm_ex, pc_ex, rd_addr_ex, rs1_addr_ex, rs2_addr_ex, funct7_5_ex);
        end
        
        // Test 2: Reset
        #10;
        reset = 1;
        
        #5;
        @(negedge clk);
        if ((reg_write_ex == 1'b0) && (mem_read_ex == 1'b0) && (mem_write_ex == 1'b0) && (branch_ex == 1'b0) && (jump_ex == 1'b0)) begin
            $display ("Test 2 PASS");
        end
            
        else begin
            $display ("Test 2 FAIL: reg_write_ex=%b, mem_read_ex=%b, mem_write_ex=%b, branch_ex=%b, jump_ex=%b", reg_write_ex, mem_read_ex, mem_write_ex, branch_ex, jump_ex);
        end
        
        // Test 3: Bubble
        #10;
        reset = 0;
        
        #10;
        bubble = 1;
        
        #5;
        @(negedge clk);
        if ((reg_write_ex == 1'b0) && (mem_read_ex == 1'b0) && (mem_write_ex == 1'b0) && (branch_ex == 1'b0) && (jump_ex == 1'b0)) begin
            $display ("Test 3 PASS");
        end
            
        else begin
            $display ("Test 3 FAIL: reg_write_ex=%b, mem_read_ex=%b, mem_write_ex=%b, branch_ex=%b, jump_ex=%b", reg_write_ex, mem_read_ex, mem_write_ex, branch_ex, jump_ex);
        end
        
        // Test 4: Flush
        #10;
        bubble = 0;
        
        #10;
        flush = 1;
        
        #5;
        @(negedge clk);
        if ((reg_write_ex == 1'b0) && (mem_read_ex == 1'b0) && (mem_write_ex == 1'b0) && (branch_ex == 1'b0) && (jump_ex == 1'b0)) begin
            $display ("Test 4 PASS");
        end
            
        else begin
            $display ("Test 4 FAIL: reg_write_ex=%b, mem_read_ex=%b, mem_write_ex=%b, branch_ex=%b, jump_ex=%b", reg_write_ex, mem_read_ex, mem_write_ex, branch_ex, jump_ex);
        end
        
        $finish;
    
    end

endmodule
