`timescale 1ns / 1ps

module tb_forwarding_unit;

logic [4:0] rs1_addr_ex;
logic [4:0] rs2_addr_ex;
logic [4:0] rd_addr_mem;  
logic reg_write_mem;      
logic [4:0] rd_addr_wb;   
logic reg_write_wb;
logic [1:0] forward_a;   
logic [1:0] forward_b;    

forwarding_unit dut (
    .rs1_addr_ex (rs1_addr_ex),
    .rs2_addr_ex (rs2_addr_ex),
    .rd_addr_mem (rd_addr_mem),  
    .reg_write_mem (reg_write_mem),      
    .rd_addr_wb (rd_addr_wb),   
    .reg_write_wb (reg_write_wb),
    .forward_a (forward_a),   
    .forward_b (forward_b)
);

int errors = 0;

task check(
    input string name,
    input [1:0] actual_val_a, 
    input [1:0] expected_val_a,
    input [1:0] actual_val_b,
    input [1:0] expected_val_b
);
    
    if (actual_val_a === expected_val_a && actual_val_b === expected_val_b) begin
        $display("PASS: %0s (forward_a=%b forward_b=%b)", name, actual_val_a, actual_val_b);
    end
    
    else begin
        $display("FAIL: %0s got forward_a=%b forward_b=%b (expected_forward_a=%b expected_forward_b=%b)",
                 name, actual_val_a, actual_val_b, expected_val_a, expected_val_b);
        errors++;
    end
    
endtask

initial begin

    // Test 1: No hazards
    rs1_addr_ex = 5'b00001;
    rs2_addr_ex = 5'b00010;
    rd_addr_mem = 5'b00000;
    rd_addr_wb = 5'b00000;
    reg_write_mem = 1'b0;
    reg_write_wb = 1'b0;
    #1;
    check("No hazard", forward_a, 2'b00, forward_b, 2'b00);
    
    // Test 2: EX/MEM -> A
    rs1_addr_ex = 5'b00001;
    rd_addr_mem = 5'b00001;
    reg_write_mem = 1'b1;
    #1;
    check("EX/MEM -> A", forward_a, 2'b10, forward_b, 2'b00);
    
    rs1_addr_ex = 5'b00000;
    rd_addr_mem = 5'b00000;
    reg_write_mem = 1'b0;
    
    // Test 3: MEM/WB -> B
    rs2_addr_ex = 5'b00010;
    rd_addr_wb = 5'b00010;
    reg_write_wb = 1'b1;
    #1;
    check("MEM/WB -> B", forward_a, 2'b00, forward_b, 2'b01);
    
    // Test 4: Double on operand A, priority check
    rs1_addr_ex = 5'b00001;
    rs2_addr_ex = 5'b00011;
    rd_addr_mem = 5'b00001;
    rd_addr_wb = 5'b00001;
    reg_write_mem = 1'b1;
    reg_write_wb = 1'b1;
    #1;
    check("Double on operand A", forward_a, 2'b10, forward_b, 2'b00);
    
    // Test 5: x0 guard
    rs1_addr_ex = 5'b00000;
    rd_addr_mem = 5'b00000;
    reg_write_mem = 1'b1;
    #1;
    check("x0 guard", forward_a, 2'b00, forward_b, 2'b00);

    // Test 6: reg_write guard
    rs1_addr_ex = 5'b00101;
    rd_addr_mem = 5'b00101;
    reg_write_mem = 1'b0;
    #1;
    check("reg_write guard", forward_a, 2'b00, forward_b, 2'b00);
    
    if (errors == 0) begin 
        $display("ALL TESTS PASSED");
    end
        
    else begin
        $display("%0d FAIL(S)", errors);
    end
        
    $finish;
    
end        

endmodule
