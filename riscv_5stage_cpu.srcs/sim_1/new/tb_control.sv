`timescale 1ns / 1ps

module tb_control;

logic [6:0] opcode;
logic reg_write;
logic mem_read;
logic mem_write;
logic branch;
logic jump;
logic alu_src;
logic [1:0] alu_op;
logic [2:0] imm_sel;
logic jalr;


control dut (
    .opcode (opcode),
    .reg_write (reg_write),
    .mem_read (mem_read),
    .mem_write (mem_write),
    .branch (branch),
    .jump (jump),
    .alu_src (alu_src),
    .alu_op (alu_op),
    .imm_sel (imm_sel),
    .jalr (jalr)
);

    initial begin
    
        // Test 1: R-type instruction
        opcode = 7'b0110011;
        #1;
        
        if (reg_write && alu_op == 2'b10) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: reg_write=%b, alu_op=%b", reg_write, alu_op);
        end
        
        
        // Test 2: lw instruction
        opcode = 7'b0000011;
        #1;
        
        if (reg_write && mem_read && alu_src) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: reg_write=%b, mem_read=%b, alu_src=%b", reg_write, mem_read, alu_src);
        end
        
        // Test 3: sw instruction
        opcode = 7'b0100011;
        #1;
        
        if (mem_write && alu_src && imm_sel == 3'b001) begin
            $display("Test 3 PASS");
        end
        
        else begin
            $display("Test 3 FAIL: mem_write=%b, alu_src=%b, imm_sel=%b", mem_write, alu_src, imm_sel);
        end
        
        // Test 4: Branch instruction
        opcode = 7'b1100011;
        #1;
        
        if (branch && alu_op == 2'b01 && imm_sel == 3'b010) begin
            $display("Test 4 PASS");
        end
        
        else begin
            $display("Test 4 FAIL: branch=%b, alu_op=%b, imm_sel=%b", branch, alu_op, imm_sel);
        end
        
        // Test 5: JAL instruction
        opcode = 7'b1101111;
        #1;
        
        if (reg_write && jump && imm_sel == 3'b100) begin
            $display("Test 5 PASS");
        end
        
        else begin
            $display("Test 5 FAIL: reg_write=%b, jump=%b, imm_sel=%b", reg_write, jump, imm_sel);
        end
        
        $finish;
         
    end

endmodule
