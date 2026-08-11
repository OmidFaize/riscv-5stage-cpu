`timescale 1ns / 1ps

module tb_jump;

logic clk, reset;
logic [31:0] pc_id, instr_id;
logic dbg_reg_write_wb;
logic [4:0] dbg_rd_addr_wb;
logic [31:0] dbg_wb_data;

core_top #(.PROGRAM("program_jump.hex")) dut (
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
        
    for (int n = 0; n < 30; n++) begin
        @(posedge clk);
        #1;
           
        if (dbg_reg_write_wb && dbg_rd_addr_wb != 0) begin
            arch[dbg_rd_addr_wb] = dbg_wb_data;
        end    
        
    end
    
    
    check("x1", arch[1],  32'd11);
    check("x5 (JAL link = PC+4)", arch[5],  32'd8);
    check("x2 (flushed by jal)", arch[2],  32'hDEADBEEF);
    check("x3 (flushed by jal)", arch[3],  32'hDEADBEEF);
    check("x4 (jal skipped it)", arch[4],  32'hDEADBEEF);
    check("x6 (jal target ran; link read)", arch[6],  32'd8);
    check("x7", arch[7],  32'd44);
    check("x8 (JALR link = PC+4)", arch[8],  32'd32);
    check("x9 (flushed by jalr)", arch[9],  32'hDEADBEEF);
    check("x10 (flushed by jalr)", arch[10], 32'hDEADBEEF);
    check("x14 (jalr skipped it)", arch[14], 32'hDEADBEEF);
    check("x11 (jalr target ran; link read)", arch[11], 32'd32);
    check("x12", arch[12], 32'd61);
    check("x13 (JALR link, odd base)", arch[13], 32'd56);
    check("x15 (flushed by jalr)", arch[15], 32'hDEADBEEF);
    check("x16 (LSB MASK: 0x3d -> 0x3c)", arch[16], 32'd160);
    check("x17 (link after masked jalr)", arch[17], 32'd56);
    check("x18", arch[18], 32'd180);
    check("x19 (JAL after JALR: link)", arch[19], 32'd76);
    check("x20 (flushed by jal)", arch[20], 32'hDEADBEEF);
    check("x21 (JAL target after JALR)", arch[21], 32'd210);
    
    if (errors == 0) begin 
        $display("ALL TESTS PASSED");
    end
        
    else begin
        $display("%0d FAIL(S)", errors);
    end
        
    $finish; 
        
end


endmodule