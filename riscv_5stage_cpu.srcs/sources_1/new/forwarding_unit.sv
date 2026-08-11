`timescale 1ns / 1ps

module forwarding_unit(
    input logic [4:0] rs1_addr_ex,
    input logic [4:0] rs2_addr_ex,
    input logic [4:0] rd_addr_mem,  // Dest. of instr. in EX/MEM
    input logic reg_write_mem,      // EX/MEM instr. write enable
    input logic [4:0] rd_addr_wb,   // Dest of instr. in MEM/WB
    input logic reg_write_wb,       // MEM/WB instr. write enable
    
    output logic [1:0] forward_a,   // Select for ALU operand A mux
    output logic [1:0] forward_b    // Select for ALU operand B mux
    );
    
    always_comb begin
    
        // Operand A
        
        // EX/MEM hazard detection (tested first to ensure newest write is used)
        if (reg_write_mem && (rd_addr_mem != 0) && (rd_addr_mem == rs1_addr_ex)) begin
            forward_a = 2'b10;
        end
        
        // MEM/WB hazard detection
        else if (reg_write_wb && (rd_addr_wb != 0) && (rd_addr_wb == rs1_addr_ex)) begin
            forward_a = 2'b01;
        end
        
        // Has ALU use regfile read for operand A
        else begin
            forward_a = 2'b00;
        end
        
        // Operand B
        
        // EX/MEM hazard detection (tested first to ensure newest write is used)
        if (reg_write_mem && (rd_addr_mem != 0) && (rd_addr_mem == rs2_addr_ex)) begin
            forward_b = 2'b10;
        end
        
        // MEM/WB hazard detection
        else if (reg_write_wb && (rd_addr_wb != 0) && (rd_addr_wb == rs2_addr_ex)) begin
            forward_b = 2'b01;
        end
        
        // Has ALU use regfile read for operand B
        else begin
            forward_b = 2'b00;
        end
    
    end
    
endmodule
