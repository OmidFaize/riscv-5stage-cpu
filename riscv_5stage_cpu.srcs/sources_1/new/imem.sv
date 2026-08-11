`timescale 1ns / 1ps


module imem #(
    parameter PROGRAM = "program_full.hex"
)(
    input logic [31:0] addr,   
    output logic [31:0] instr
    );

   
    logic [31:0] memory [0:255]; // 256 words memory (1 KB)
     
    initial begin
        $readmemh(PROGRAM, memory);
    end
    
    assign instr = memory[addr[9:2]];

endmodule
