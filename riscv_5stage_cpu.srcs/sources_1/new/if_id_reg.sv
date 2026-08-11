`timescale 1ns / 1ps

module if_id_reg(
    input logic clk,
    input logic reset,
    input logic if_id_write,
    input logic if_id_flush,
    input logic [31:0] instr_in,
    input logic [31:0] pc_in,
    
    output logic [31:0] instr_out,
    output logic [31:0] pc_out
    );
    
    always_ff @ (posedge clk) begin
            
            // Reset
            if (reset) begin
                instr_out <= 32'h00000013; //NOP operation
                pc_out <= 32'd0;
            end
           
            // Flush
            else if (if_id_flush) begin
                instr_out <= 32'h00000013; //NOP operation
                pc_out <= 32'd0;
            end
            
            // Stall has if_id_write deasserted, hence no change to instr_out and pc_out
            
            // Normal operation (no hazards that need flush or stall)
            else if (if_id_write) begin
                instr_out <= instr_in;
                pc_out <= pc_in;
            end
        
    end
    
endmodule
