`timescale 1ns / 1ps

module hazard_detection_unit_tb;

logic mem_read_ex;
logic [4:0] rd_addr_ex;
logic [4:0] rs1_addr_id;
logic [4:0] rs2_addr_id;    
logic pc_write;      
logic if_id_write;   
logic id_ex_bubble;   

hazard_detection_unit dut (
    .mem_read_ex (mem_read_ex),
    .rd_addr_ex (rd_addr_ex),
    .rs1_addr_id (rs1_addr_id),
    .rs2_addr_id (rs2_addr_id),
    .pc_write (pc_write),
    .if_id_write (if_id_write),
    .id_ex_bubble (id_ex_bubble)
);

    int errors = 0;

    task check(
        input string name,
        input [2:0] actual, 
        input [2:0] expected
    );
        
        if (actual === expected) begin
            $display("PASS: %0s (pc_write/if_id_write/id_ex_bubble = %b)", name, actual);
        end
        
        else begin
            $display("FAIL: %0s (pc_write/if_id_write/id_ex_bubble = %b), expected = %b", name, actual, expected);
            errors++;
        end
        
    endtask

    initial begin   
        
        // Test 1: No load in EX, rd_ex address matches rs1_id address ---> no stall
        mem_read_ex = 1'b0;
        rd_addr_ex = 5'd10;
        rs1_addr_id = 5'd10;
        rs2_addr_id = 5'd0; 
        #1;
        check("Test 1: No load in EX", {pc_write, if_id_write, id_ex_bubble}, 3'b110);
        
        // Test 2: Load in EX, rd_ex address matches rs1_id address ---> stall
        mem_read_ex = 1'b1;
        rd_addr_ex = 5'd10;
        rs1_addr_id = 5'd10;
        rs2_addr_id = 5'd0; 
        #1;
        check("Test 2: Load in EX, rd_addr_ex = rs1_addr_id", {pc_write, if_id_write, id_ex_bubble}, 3'b001);
        
        // Test 3: Load in EX, rd_ex address matches rs2_id address ---> stall
        mem_read_ex = 1'b1;
        rd_addr_ex = 5'd10;
        rs1_addr_id = 5'd0;
        rs2_addr_id = 5'd10; 
        #1;
        check("Test 3: Load in EX, rd_addr_ex = rs2_addr_id", {pc_write, if_id_write, id_ex_bubble}, 3'b001);
        
        // Test 4: Load in EX, rd_ex address does not match rs1_id and rs2_id address ---> no stall
        mem_read_ex = 1'b1;
        rd_addr_ex = 5'd10;
        rs1_addr_id = 5'd1;
        rs2_addr_id = 5'd2; 
        #1;
        check("Test 4: Load in EX, rd_addr_ex != rs1_addr_id or rs2_addr_id", {pc_write, if_id_write, id_ex_bubble}, 3'b110);
        
        // Test 5: Load in EX, rd_ex address matches rs1_id address at 0 ---> no stall (x0 guard)
        mem_read_ex = 1'b1;
        rd_addr_ex = 5'd0;
        rs1_addr_id = 5'd0;
        rs2_addr_id = 5'd2; 
        #1;
        check("Test 5: Load in EX, rd_addr_ex = rs1_addr_id = 0 (x0 guard)", {pc_write, if_id_write, id_ex_bubble}, 3'b110);
        
         // Test 6: Load in EX, rd_ex address matches rs1_id and rs2_id ---> stall
        mem_read_ex = 1'b1;
        rd_addr_ex = 5'd1;
        rs1_addr_id = 5'd1;
        rs2_addr_id = 5'd1; 
        #1;
        check("Test 6: Load in EX, rd_addr_ex = rs1_addr_id = rs2_addr_id", {pc_write, if_id_write, id_ex_bubble}, 3'b001);
        
        if (errors == 0) begin 
            $display("ALL TESTS PASSED");
        end
            
        else begin
            $display("%0d FAIL(S)", errors);
        end
            
        $finish;
    
    end

endmodule
