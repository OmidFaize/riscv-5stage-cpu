`timescale 1ns / 1ps

module imm_gen(
    input logic [31:0] instr,
    input logic [2:0] imm_sel,
        
    output logic [31:0] imm_out 
    );
    
    always_comb begin
        
        case (imm_sel)
            // I-type Immediate
            3'b000: imm_out = {{21{instr[31]}}, instr[30:20]};
            // S-type Immediate
            3'b001: imm_out = {{21{instr[31]}}, instr[30:25], instr[11:7]};
            // B-type Immediate
            3'b010: imm_out = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            // U-type Immedate
            3'b011: imm_out = {instr[31:12], 12'b0};
            // J-type Immediate
            3'b100: imm_out = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm_out = 32'b0;
        endcase
    
    end
        
endmodule
