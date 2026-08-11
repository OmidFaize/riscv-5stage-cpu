`timescale 1ns / 1ps

module alu_control(
        input logic [1:0] alu_op,    // From main control: 00=L/S, 01=branch, 10=R-type, 11=I=type
        input logic [2:0] funct3,
        input logic funct7_5,        // 5th bit of funct7
        
        output logic [3:0] alu_ctrl  // Connects to ALU's alu_op port
    );
    
    always_comb begin
        
        alu_ctrl = 4'b0000; // ADD operation is default
        
        case(alu_op)
        
        // Load/Store instructions
        2'b00: alu_ctrl = 4'b0000; // ADD operation
        
        // Branch instructions
        2'b01:
               case(funct3) 
               // BEQ
                3'b000: alu_ctrl = 4'b0001; // SUB operation
               
               // BNE
               3'b001: alu_ctrl = 4'b0001; // SUB operation
               
               // BLT
               3'b100: alu_ctrl = 4'b1000; // SLT operation
               
               // BGE
               3'b101: alu_ctrl = 4'b1000; // SLT operation
               
               // BLTU
               3'b110: alu_ctrl = 4'b1001; // SLTU operation
               
               // BGEU
               3'b111: alu_ctrl = 4'b1001; // SLTU operation
               
               endcase
        
        // R-type instructions       
        2'b10: 
               case(funct3)
               
               // ADD or SUB
               3'b000:
                     
                     // SUB
                     if (funct7_5) begin
                        alu_ctrl = 4'b0001; // SUB operation
                     end
                     
                     // ADD
                     else begin
                        alu_ctrl = 4'b0000; // ADD operation
                     end 
               
               // SLL
               3'b001: alu_ctrl = 4'b0101; // SLL operation
               
               // SLT
               3'b010: alu_ctrl = 4'b1000; // SLT operation
               
               // SLTU
               3'b011: alu_ctrl = 4'b1001; // SLTU operation
               
               // XOR
               3'b100: alu_ctrl = 4'b0100; // XOR operation
               
               // SRL or SRA
               3'b101:
                     
                     // SRA
                     if (funct7_5) begin
                        alu_ctrl = 4'b0111; // SRA operation
                     end
                     
                     // SRL
                     else begin
                        alu_ctrl = 4'b0110; // SRL operation
                     end 
               
               // OR
               3'b110: alu_ctrl = 4'b0011; // OR operation
               
               // AND
               3'b111: alu_ctrl = 4'b0010; // AND operation
               
               endcase
        
        // I-type instructions       
        2'b11: 
               case(funct3)
               
               // ADDI
               3'b000: alu_ctrl = 4'b0000; // ADD operation
               
               // SLLI
               3'b001: alu_ctrl = 4'b0101; // SLL operation
               
               // SLTI
               3'b010: alu_ctrl = 4'b1000; // SLT operation
               
               // SLTIU
               3'b011: alu_ctrl = 4'b1001; // SLTU operation
               
               // XORI
               3'b100: alu_ctrl = 4'b0100; // XOR operation
               
               // SRLI or SRAI
               3'b101:
                     
                     // SRAI
                     if (funct7_5) begin
                        alu_ctrl = 4'b0111; // SRA operation
                     end
                     
                     // SRLI
                     else begin
                        alu_ctrl = 4'b0110; // SRL operation
                     end
               
               // ORI
               3'b110: alu_ctrl = 4'b0011; // OR operation
               
               // ANDI
               3'b111: alu_ctrl = 4'b0010; // AND operation
               
               endcase
           
        endcase
        
    end   
    
endmodule