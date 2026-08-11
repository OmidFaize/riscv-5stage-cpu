`timescale 1ns / 1ps

module regfile(
    input logic clk,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    input logic [31:0] write_data,
    input logic write_en,
    
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
    );
    
    logic [31:0] regs [0:31];
    
    // Write port
    always_ff @ (posedge clk) begin
    
        if (write_en && (rd_addr != 5'b0)) begin
            regs[rd_addr] <= write_data;
        end           
    end
    
    // Read port
    always_comb begin
        
        // RS1 Read Port:
        // Forces x0 register to remain 0
         if (rs1_addr == 5'b0) begin
            rs1_data = 32'b0;
         end
         
         // Write bypass
         else if (write_en && (rd_addr == rs1_addr)) begin
            rs1_data = write_data;
         end
         
         // Normal read operation
         else begin
            rs1_data = regs[rs1_addr];
         end
         
         // RS2 Read Port:
         // Forces x0 register to remain 0
         if (rs2_addr == 5'b0) begin
            rs2_data = 32'b0;
         end
         
         // Write bypass
         else if (write_en && (rd_addr == rs2_addr)) begin
            rs2_data = write_data;
         end
         
         // Normal read operation
         else begin
            rs2_data = regs[rs2_addr];
         end
    end

endmodule
