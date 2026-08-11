`timescale 1ns / 1ps

module pc(
    input logic clk,
    input logic reset,
    input logic pc_write,
    input logic [31:0] pc_next,
    
    output logic [31:0] pc_out
    );
    
    always_ff @(posedge clk) begin
        
        // Resets PC to addr 0 when reset is enabled
        if (reset)
            pc_out <= 32'd0;
            
        // Sets pc_out to be pc_next when write is enabled
        else if (pc_write)
            pc_out <= pc_next;
        
        // pc_out remains the same if pc_write is not enabled
    
    end

endmodule
