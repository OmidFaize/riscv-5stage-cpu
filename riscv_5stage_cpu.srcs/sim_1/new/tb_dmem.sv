`timescale 1ns / 1ps

module tb_dmem;

logic clk;
logic mem_write;
logic [31:0] addr;
logic [31:0] write_data;
logic [31:0] read_data;

dmem dut (
    .clk (clk),
    .mem_write (mem_write),
    .addr (addr),
    .write_data (write_data),
    .read_data (read_data)
);

    initial clk = 0;
    always #5 clk = ~clk;  // 1 clk cycle = 10 ns
    
    initial begin
        
        mem_write = 0;
        addr = 0;
        write_data = 0;
        
        // Test 1: Write then read
        @(negedge clk);
        mem_write = 1;
        addr = 32'h00000000;
        write_data = 32'h00000005;
        
        @(negedge clk);
        #1;
        
        if (read_data == 32'h00000005) begin
            $display("Test 1 PASS");
        end
        
        else begin
            $display("Test 1 FAIL: read_data=%h", read_data);
        end
        
        // Test 2: Write-enable gating
        @(negedge clk);
        mem_write = 0;
        write_data = 32'h00000006;
        
        @(negedge clk);
        #1;
        
        if (read_data == 32'h00000005) begin
            $display("Test 2 PASS");
        end
        
        else begin
            $display("Test 2 FAIL: read_data=%h", read_data);
        end
        
        // Test 3: Word addressing
        @(negedge clk);
        mem_write = 1;
        addr = 32'h00000000;
        write_data = 32'h00000001;
        
        @(negedge clk);
        addr = 32'h00000004;
        write_data = 32'h00000002;
        
        @(negedge clk);
        addr = 32'h00000008;
        write_data = 32'h00000003;
        
        @(negedge clk);
        addr = 32'h00000000;
        mem_write = 0;
        #1;
        if (read_data == 32'h00000001) begin
            $display("Test 3.1 PASS");
        end
        else begin
            $display("Test 3.1 FAIL: read_data_3.1=%h", read_data);
        end
        
        addr = 32'h00000004;
        #1;
        if (read_data == 32'h00000002) begin
            $display("Test 3.2 PASS");
        end
        else begin
            $display("Test 3.2 FAIL: read_data_3.2=%h", read_data);
        end
        
        addr = 32'h00000008;
        #1;
        if (read_data == 32'h00000003) begin
            $display("Test 3.3 PASS");
        end
        else begin
            $display("Test 3.3 FAIL: read_data_3.3=%h", read_data);
        end
        
        $finish;
        
    end

endmodule