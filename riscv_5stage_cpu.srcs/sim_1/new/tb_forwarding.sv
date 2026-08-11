`timescale 1ns / 1ps

module tb_forwarding;

logic clk;
logic reset;
logic [31:0] pc_id;
logic [31:0] instr_id;
logic dbg_reg_write_wb;       // WB write enable
logic [4:0] dbg_rd_addr_wb;   // WB destination register
logic [31:0] dbg_wb_data;     // WB data value


core_top #(.PROGRAM("program_forwarding.hex")) dut (
    .clk (clk),
    .reset (reset),
    .pc_id (pc_id),
    .instr_id (instr_id),
    .dbg_reg_write_wb (dbg_reg_write_wb),
    .dbg_rd_addr_wb (dbg_rd_addr_wb),
    .dbg_wb_data (dbg_wb_data)
);

    initial clk = 0;
    always #5 clk = ~clk;  // Clock toggles every 5 ns, 100 MHz clock/10 ns period
    
    logic [31:0] arch [0:31];
    int errors = 0;
    
task check(
    input string reg_name, 
    input [31:0] actual_val,
    input [31:0] expected_val
);
        
    if (actual_val === expected_val) begin
        $display("PASS: %0s = %0d", reg_name, actual_val);
    end
    
    else begin
        $display("FAIL: %0s = %0d (expected %0d)", reg_name, actual_val, expected_val);
        errors = errors + 1;
    end
        
endtask
    
initial begin
    reset = 1;
    @(posedge clk);
    #1;             
    reset = 0;
        
    for (int n = 0; n <= 15; n++) begin
        @(posedge clk);
        #1;
           
        if (dbg_reg_write_wb && dbg_rd_addr_wb != 0) begin
            arch[dbg_rd_addr_wb] = dbg_wb_data;
        end    
        
    end
        
    check("x1", arch[1], 5);
    check("x2", arch[2], 7);
    check("x3", arch[3], 12);
        
    if (errors == 0) begin 
        $display("ALL TESTS PASSED");
    end
        
    else begin
        $display("%0d FAIL(S)", errors);
    end
        
    $finish; 
        
end


endmodule