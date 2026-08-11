`timescale 1ns / 1ps


module dmem(
    input logic clk,
    input logic mem_write,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    
    output logic [31:0] read_data
    );
    
    logic [31:0] mem [0:255]; // 256 words = 1 kB
    
    // Write
    always_ff @ (posedge clk) begin
        if (mem_write) begin
            mem[addr[9:2]] <= write_data;
        end
    end
    
    
    // Read
    assign read_data = mem[addr[9:2]];
    
    initial begin
        $readmemh("dmem_init.hex", mem);
    end
    
endmodule
