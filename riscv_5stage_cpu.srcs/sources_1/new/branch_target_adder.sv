`timescale 1ns / 1ps

module branch_target_adder(
    input logic [31:0] pc,
    input logic [31:0] imm,
    
    output logic [31:0] branch_target
    );
    
    assign branch_target = pc + imm;
    
endmodule
