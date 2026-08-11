`timescale 1ns / 1ps

module hazard_detection_unit(
    input logic mem_read_ex,
    input logic [4:0] rd_addr_ex,
    input logic [4:0] rs1_addr_id,
    input logic [4:0] rs2_addr_id,
    
    output logic pc_write,      // 1'b1 = normal operation
    output logic if_id_write,   // 1'b1 = normal operation
    output logic id_ex_bubble   // 1'b1 = inject NOP
    );
    
    
    always_comb begin
    
        // Stall detection
        if (mem_read_ex && (rd_addr_ex != 0) && ((rd_addr_ex == rs1_addr_id || rd_addr_ex == rs2_addr_id))) begin
            pc_write = 1'b0;
            if_id_write = 1'b0;
            id_ex_bubble = 1'b1;
        end
        
        // No stall
        else begin
            pc_write = 1'b1;
            if_id_write = 1'b1;
            id_ex_bubble = 1'b0;
        end
     
     end
     
endmodule
