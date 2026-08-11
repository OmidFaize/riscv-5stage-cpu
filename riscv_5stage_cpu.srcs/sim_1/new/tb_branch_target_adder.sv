`timescale 1ns / 1ps

module tb_branch_target_adder;

logic [31:0] pc;
logic [31:0] imm;
logic [31:0] branch_target;

branch_target_adder dut (
    .pc (pc),
    .imm (imm),
    .branch_target (branch_target)
);

    initial begin
    
        // Test 1: Forward branch
        pc = 32'h00000010;
        imm = 32'h00000020;
        #1;
        
        if (branch_target == 32'h00000030) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: branch_target=%h", branch_target);
        end
        
        // Test 2: Backwards branch
        pc = 32'h00000100;
        imm = 32'hFFFFFFF8;
        #1;
        
        if (branch_target == 32'h000000F8) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: branch_target=%h", branch_target);
        end
        
        // Test 3: Wraparound
        pc = 32'hFFFFFFF0;
        imm = 32'h00000020;
        #1;
        
        if (branch_target == 32'h00000010) begin
            $display("Test 3 PASS");
        end
        
        else begin
            $display("Test 3 FAIL: branch_target=%h", branch_target);
        end

    end

endmodule
