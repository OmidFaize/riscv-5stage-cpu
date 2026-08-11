`timescale 1ns / 1ps

module tb_alu_control;

logic [1:0] alu_op;
logic [2:0] funct3;
logic funct7_5;
logic [3:0] alu_ctrl;

alu_control dut (
    .alu_op (alu_op),
    .funct3 (funct3),
    .funct7_5 (funct7_5),
    .alu_ctrl (alu_ctrl)
);

    initial begin
    
        // Test 1:  ADD
        alu_op = 2'b10;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #1;
        
        if (alu_ctrl == 4'b0000) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: alu_ctrl=%h", alu_ctrl);
        end
        
        // Test 2: SUB
        alu_op = 2'b10;
        funct3 = 3'b000;
        funct7_5 = 1'b1;
        #1;
        
        if (alu_ctrl == 4'b0001) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: alu_ctrl=%h", alu_ctrl);
        end
        
        // Test 3: ADDI (showing funct7[5] has no effect)
        alu_op = 2'b11;
        funct3 = 3'b000;
        funct7_5 = 1'b0;
        #1;
        
        // funct7[5] for ADD case
        if (alu_ctrl == 4'b0000) begin
            $display("Test 3 ADD case PASS");
        end
        
        else begin
            $display("Test 3 ADD case FAIL: alu_ctrl=%h", alu_ctrl);
        end
        
        // Changing funct7[5] for SUB case
        funct7_5 = 1'b1;
        #1;
        
        if (alu_ctrl == 4'b0000) begin
            $display("Test 3 SUB case PASS");
        end
        
        else begin
            $display("Test 3 SUB case FAIL: alu_ctrl=%h", alu_ctrl);
        end
        
        // Test 4: SRAI operation
        alu_op = 2'b11;
        funct3 = 3'b101;
        funct7_5 = 1'b1;
        #1;
        
        
        if (alu_ctrl == 4'b0111) begin
            $display("Test 4 PASS");
        end
        
        else begin
            $display("Test 4 FAIL: alu_ctrl=%h", alu_ctrl);
        end
        
        // Test 5: BLT operation
        alu_op = 2'b01;
        funct3 = 3'b100;
        #1;
        
        
        if (alu_ctrl == 4'b1000) begin
            $display("Test 5 PASS");
        end
        
        else begin
            $display("Test 5 FAIL: alu_ctrl=%h", alu_ctrl);
        end
        
        $finish;
        
    end
        
endmodule