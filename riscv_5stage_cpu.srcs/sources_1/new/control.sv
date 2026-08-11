`timescale 1ns / 1ps

module control(
    input logic [6:0] opcode,
    
    output logic reg_write,     // Write result back to regfile
    output logic mem_read,      // Load (read dmem)
    output logic mem_write,     // Store (write dmem)
    output logic branch,
    output logic jump,
    output logic alu_src,       // ALU operand B: 0=rs2, 1=immediate
    output logic [1:0] alu_op,
    output logic [2:0] imm_sel,  // Immediate select: 000=I-type, 001=S-type, 010=B-type, 011=U-type, 100=J-type
    output logic jalr            // 1=jalr, 0=jal or no jump
    );
    
    always_comb begin
    
    // Default initializations
    reg_write = 1'b0;
    mem_write = 1'b0;
    mem_read = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    alu_src = 1'b0;
    alu_op = 2'b00;
    imm_sel = 3'b000;
    jalr = 1'b0;
    
        case (opcode)
        
            // R-type instruction class
            7'b0110011: begin
                reg_write = 1'b1;
                alu_op = 2'b10;
            end
            
            // I-type instruction class
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b11;
            end
            
            
            // Load (lw)
            7'b0000011: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
            end
            
            // Store (sw)
            7'b0100011: begin
                mem_write = 1'b1;
                alu_src = 1'b1;
                imm_sel = 3'b001;
            end
            
            // Branch
            7'b1100011: begin
                branch = 1'b1;
                alu_op = 2'b01;
                imm_sel = 3'b010;
            end
            
            // Jump and Link (jal)
            7'b1101111: begin
                reg_write = 1'b1;
                jump = 1'b1;
                imm_sel = 3'b100;
            end
            
            // Jump and Link Register (jalr)
            7'b1100111: begin
                reg_write = 1'b1;
                jump = 1'b1;
                alu_src = 1'b1;
                jalr = 1'b1;
            end
            
            // Load Upper Immediate (LUI)
            7'b0110111: begin
                reg_write = 1'b0; // Not implemented (retires as NOP)
                alu_src = 1'b1;
                imm_sel = 3'b011;
            end
            
            // Add Upper Immediate to Program Counter (AUIPC)
            7'b0010111: begin
                reg_write = 1'b0; // Not implemented (retires as NOP)
                alu_src = 1'b1;
                imm_sel = 3'b011;
            end
         
        endcase   
    
    end
            
endmodule