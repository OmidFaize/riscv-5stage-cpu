`timescale 1ns / 1ps

module tb_alu;

logic [31:0] a;
logic [31:0] b;
logic [3:0] alu_op;
logic [31:0] result;
logic zero;

alu dut (
    .a (a),
    .b (b),
    .alu_op (alu_op),
    .result (result),
    .zero (zero)
);

    initial begin
        
        // Test 1: ADD (two positive operand values)
        a = 32'h00000001;
        b = 32'h00000002;
        alu_op = 4'b0000;
        #1;
        
        if (result == 32'h00000003) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: result=%h", result);
        end
        
        // Test 2: SUB (both operands equal)
        a = 32'h00000003; 
        b = 32'h00000003;
        alu_op = 4'b0001;
        #1;
        
        if ((result == 32'h00000000) && (zero == 1'b1)) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: result=%h, zero=%b", result, zero);
        end
        
        // Test 3: SRA (negative operand a)
        a = 32'h80000000;
        b = 32'h00000004; // Shift right by 4
        alu_op = 4'b0111;
        #1;
        
        if (result == 32'hF8000000) begin
            $display("Test 3 PASS");
        end
        
        else begin
            $display("Test 3 FAIL: result=%h", result);
        end
        
        // Test 4: SLT Overflow
        a = 32'h7FFFFFFF;
        b = 32'h80000000;
        alu_op = 4'b1000;
        #1;
        
        if (result == 32'h00000000) begin
            $display("Test 4 PASS");
        end
        
        else begin
            $display("Test 4 FAIL: result=%h", result);
        end
        
        // Test 5: SLTU
        a = 32'h7FFFFFFF;
        b = 32'h80000000;
        alu_op = 4'b1001;
        #1;
        
        if (result == 32'h00000001) begin
            $display("Test 5 PASS");
        end
        
        else begin
            $display("Test 5 FAIL: result=%h", result);
        end
        
        $finish;
        
    end
        

endmodule
