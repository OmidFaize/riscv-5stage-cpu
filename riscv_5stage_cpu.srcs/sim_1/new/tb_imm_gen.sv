`timescale 1ns / 1ps

module tb_imm_gen;

logic [31:0] instr;
logic [2:0] imm_sel;
logic [31:0] imm_out;

imm_gen dut (
    .instr (instr),
    .imm_sel (imm_sel),
    .imm_out (imm_out)
);

    initial begin
        
        // Test 1: Positive Immediate of I-type
        instr = 32'h00500093; // addi x1, x0, 5
        imm_sel = 3'b000;
        #1;
        
        if (imm_out == 32'h00000005) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: imm_out=%h", imm_out);
        end
        
        // Test 2: Negative Immediate of I-type
        instr = 32'hFFB00093; // addi x1, x0, -5
        imm_sel = 3'b000;
        #1;
        
        if (imm_out == 32'hFFFFFFFB) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: imm_out=%h", imm_out);
        end
        
        // Test 3: B-type
        instr = 32'h00108463; // beq x1, x1, 8
        imm_sel = 3'b010;
        #1;
        
        if (imm_out == 32'h00000008) begin
            $display("Test 3 PASS");
        end
        
        else begin
            $display("Test 3 FAIL: imm_out=%h", imm_out);
        end
        
        // Test 4: U-type
        instr = 32'h000072b7; // lui x5, 7
        imm_sel = 3'b011;
        #1;
        
        if (imm_out == 32'h00007000) begin
            $display("Test 4 PASS");
        end
        
        else begin
            $display("Test 4 FAIL: imm_out=%h", imm_out);
        end
        
        // Test 5: Default Case
        instr = 32'h00000000; 
        imm_sel = 3'b111;    // Immediate selection out of range
        #1;
        
        if (imm_out == 32'h00000000) begin
            $display("Test 5 PASS");
        end
        
        else begin
            $display("Test 5 FAIL: imm_out=%h", imm_out);
        end
    
        $finish;
    end

endmodule
