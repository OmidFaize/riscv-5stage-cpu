`timescale 1ns / 1ps

module tb_core_top;

logic clk;
logic reset;
logic [31:0] pc_id;
logic [31:0] instr_id;
logic dbg_reg_write_wb;       // WB write enable
logic [4:0] dbg_rd_addr_wb;   // WB destination register
logic [31:0] dbg_wb_data;     // WB data value


core_top #(.PROGRAM("program_full.hex")) dut (
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
    // Seeds all 32 entries with 0xDEADBEEF
    for (int i = 0; i < 32; i++) begin
        arch[i] = 32'hDEADBEEF;
    end

    reset = 1;
    @(posedge clk);
    #1;             
    reset = 0;
        
    for (int n = 0; n < 60; n++) begin
        @(posedge clk);
        #1;
           
        if (dbg_reg_write_wb && dbg_rd_addr_wb != 0) begin
            arch[dbg_rd_addr_wb] = dbg_wb_data;
        end    
        
    end
        
    check("x1", arch[1], 32'd100);
    check("x2", arch[2], 32'd7);
    check("x3 (RAW: both operands forwarded)", arch[3], 32'd107);
    check("x4", arch[4], 32'd5);
    check("x5 (RAW: MEM/WB + EX/MEM same instr)", arch[5], 32'd102);
    check("x6 (back to back RAW)", arch[6], 32'd109);
    check("x7", arch[7], 32'd77);
    check("x8 (lw after store-data forward)", arch[8], 32'd77);
    check("x9 (load-use stall)", arch[9], 32'd84);
    check("x10", arch[10], 32'd88);
    check("x11 (lw after store-data forward)", arch[11], 32'd88);
    check("x12 (flushed by beq - ID/EX)", arch[12], 32'hDEADBEEF);
    check("x13 (flushed by beq - IF/ID)", arch[13], 32'hDEADBEEF);
    check("x14 (beq target)", arch[14], 32'd140);
    check("x15 (forward right after flush)", arch[15], 32'd147);
    check("x16 (bne not taken)", arch[16], 32'd160);
    check("x17 (bne not taken)", arch[17], 32'd170);
    check("x18", arch[18], 32'd180);
    check("x19 (x0 guard)", arch[19], 32'd100);
    check("x20", arch[20], 32'd77);
    check("x21 (independent, no over-stall)", arch[21], 32'd210);
    check("x22 (MEM/WB + EX/MEM, no stall)", arch[22], 32'd287);
    check("x23", arch[23], 32'd99);
    check("x24", arch[24], 32'd8);
    check("x25 (loaded data, not address)", arch[25], 32'd99);
    check("x26 (bubble check: must execute)", arch[26], 32'd260);
    check("x27 (bubble check: must execute)", arch[27], 32'd270);
    check("x28 (beq target)", arch[28], 32'd280);
        
    if (errors == 0) begin 
        $display("ALL TESTS PASSED");
    end
        
    else begin
        $display("%0d FAIL(S)", errors);
    end
        
    $finish; 
        
end


endmodule