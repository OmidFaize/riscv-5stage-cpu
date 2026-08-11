`timescale 1ns / 1ps

module core_top #(
    parameter PROGRAM = "program_full.hex"
)(
    input logic clk,
    input logic reset,
    
    output logic [31:0] pc_id,
    output logic [31:0] instr_id,
    output logic dbg_reg_write_wb,      // WB write enable
    output logic [4:0] dbg_rd_addr_wb,  // WB destination register
    output logic [31:0] dbg_wb_data     // WB data value
    );
    
    // 1) IF Stage
    logic [31:0] pc_if;
    logic [31:0] pc_next;
    logic [31:0] instr_if;
    
    // 2) ID Stage
    logic [6:0] opcode_id;
    logic [4:0] rs1_addr_id;
    logic [4:0] rs2_addr_id;
    logic [4:0] rd_addr_id;
    logic [2:0] funct3_id;
    logic funct7_5_id;
    
    // hazard_detection_unit
    logic pc_write;
    logic if_id_write;
    logic id_ex_bubble;
    
    assign opcode_id = instr_id[6:0];
    assign rs1_addr_id = instr_id[19:15];
    assign rs2_addr_id = instr_id[24:20];
    assign rd_addr_id = instr_id[11:7];
    assign funct3_id = instr_id[14:12];
    assign funct7_5_id = instr_id[30];
    
    // control
    logic reg_write_id;
    logic mem_read_id;
    logic mem_write_id;
    logic branch_id;
    logic jump_id;
    logic jalr_id;
    logic alu_src_id;
    logic [1:0] alu_op_id;
    logic [2:0] imm_sel_id;
    
    // regfile
    logic [31:0] rs1_data_id;
    logic [31:0] rs2_data_id;
    
    // imm_gen
    logic [31:0] imm_id;
    
    // ID/EX pipeline register
    logic reg_write_ex;
    logic mem_read_ex;
    logic mem_write_ex;
    logic branch_ex;
    logic jump_ex;
    logic jalr_ex;
    logic alu_src_ex;
    logic [1:0] alu_op_ex;
    logic [2:0] funct3_ex;
    logic [31:0] rs1_data_ex;
    logic [31:0] rs2_data_ex;
    logic [31:0] imm_ex;
    logic [31:0] pc_ex;
    logic [4:0] rd_addr_ex;
    logic [4:0] rs1_addr_ex;
    logic [4:0] rs2_addr_ex;
    logic funct7_5_ex;
    
    // 3) EX Stage
    logic [3:0] alu_ctrl_w;
    logic [31:0] operand_b;
    logic [31:0] alu_result_ex;
    logic zero_ex;
    logic [31:0] branch_target_ex;
    logic branch_taken;
    logic redirect;
    logic [31:0] link_value_ex;
    logic [31:0] pc_target_ex;
    
    // EX/MEM pipeline register
    logic reg_write_mem;
    logic mem_read_mem;
    logic mem_write_mem;
    logic jump_mem;
    logic [31:0] link_value_mem;
    logic [31:0] alu_result_mem;
    logic [31:0] rs2_data_mem;
    logic [4:0] rd_addr_mem;
    
    // 4) MEM Stage
    logic [31:0] read_data_mem;
    
    // MEM/WB pipeline register
    logic reg_write_wb;
    logic mem_read_wb;
    logic jump_wb;
    logic [31:0] link_value_wb;
    logic [31:0] alu_result_wb;
    logic [31:0] read_data_wb;
    logic [4:0] rd_addr_wb;
    
    // 5) WB Stage
    logic [31:0] wb_data;
    logic [1:0] forward_a, forward_b;
    logic [31:0] forwarded_a, forwarded_b;  // MUX outputs
    
pc pc_inst(
    .clk (clk),
    .reset (reset),
    .pc_write (pc_write),
    .pc_next (pc_next),        
    .pc_out (pc_if)
             
);

imem #(.PROGRAM(PROGRAM)) imem_inst(
    .addr (pc_if),
    .instr (instr_if)
);

if_id_reg if_id_reg_inst(
    .clk (clk),
    .reset (reset),
    .if_id_write (if_id_write),
    .if_id_flush (redirect),
    .instr_in (instr_if),
    .pc_in (pc_if),
    .instr_out (instr_id),
    .pc_out (pc_id)
);

control control_inst (
    .opcode (opcode_id),
    .reg_write (reg_write_id),
    .mem_read (mem_read_id),
    .mem_write (mem_write_id),
    .branch (branch_id),
    .jump (jump_id),
    .alu_src (alu_src_id),
    .alu_op (alu_op_id),
    .imm_sel (imm_sel_id),
    .jalr (jalr_id)
);

regfile regfile_inst (
    .clk (clk),
    .rs1_addr (rs1_addr_id),
    .rs2_addr (rs2_addr_id),
    .rd_addr (rd_addr_wb),
    .write_data (wb_data),
    .write_en (reg_write_wb),
    .rs1_data (rs1_data_id),
    .rs2_data (rs2_data_id)
);

imm_gen imm_gen_inst (
    .instr (instr_id),
    .imm_sel (imm_sel_id),
    .imm_out (imm_id)
);

id_ex_reg id_ex_reg_inst (
    .clk (clk),
    .reset (reset),
    .flush (redirect),       
    .bubble (id_ex_bubble),         
    .reg_write_id (reg_write_id),
    .mem_read_id (mem_read_id),
    .mem_write_id (mem_write_id),
    .branch_id (branch_id),
    .jump_id (jump_id),
    .alu_src_id (alu_src_id),
    .alu_op_id (alu_op_id),
    .funct3_id (funct3_id),
    .rs1_data_id (rs1_data_id),
    .rs2_data_id (rs2_data_id),
    .imm_id (imm_id),
    .pc_id (pc_id),
    .rd_addr_id (rd_addr_id),
    .rs1_addr_id (rs1_addr_id),
    .rs2_addr_id (rs2_addr_id),
    .funct7_5_id (funct7_5_id),
    .reg_write_ex (reg_write_ex),
    .mem_read_ex (mem_read_ex),
    .mem_write_ex (mem_write_ex),
    .branch_ex (branch_ex),
    .jump_ex (jump_ex),
    .alu_src_ex (alu_src_ex),
    .alu_op_ex (alu_op_ex),
    .funct3_ex (funct3_ex),
    .rs1_data_ex (rs1_data_ex),
    .rs2_data_ex (rs2_data_ex),
    .imm_ex (imm_ex),
    .pc_ex (pc_ex),
    .rd_addr_ex (rd_addr_ex),
    .rs1_addr_ex (rs1_addr_ex),
    .rs2_addr_ex (rs2_addr_ex),
    .funct7_5_ex (funct7_5_ex),
    .jalr_id (jalr_id),
    .jalr_ex (jalr_ex)
);

alu_control alu_control_inst (
    .alu_op (alu_op_ex),
    .funct3 (funct3_ex),
    .funct7_5 (funct7_5_ex),
    .alu_ctrl (alu_ctrl_w)
);

alu alu_inst (
    .a (forwarded_a),
    .b (operand_b),
    .alu_op (alu_ctrl_w),
    .result (alu_result_ex),
    .zero (zero_ex)
);

branch_target_adder branch_target_adder_inst (
    .pc (pc_ex),
    .imm (imm_ex),
    .branch_target (branch_target_ex)
);

ex_mem_reg ex_mem_reg_inst (
    .clk (clk),
    .reset (reset),
    .reg_write_ex (reg_write_ex),
    .mem_read_ex (mem_read_ex),
    .mem_write_ex (mem_write_ex),
    .alu_result_ex (alu_result_ex),
    .rs2_data_ex (forwarded_b),
    .rd_addr_ex (rd_addr_ex),
    .reg_write_mem (reg_write_mem),
    .mem_read_mem (mem_read_mem),
    .mem_write_mem (mem_write_mem),
    .alu_result_mem (alu_result_mem),
    .rs2_data_mem (rs2_data_mem),
    .rd_addr_mem (rd_addr_mem),
    .jump_ex (jump_ex),
    .jump_mem (jump_mem),
    .link_value_ex (link_value_ex),
    .link_value_mem (link_value_mem)
);

dmem dmem_inst (
    .clk (clk),
    .mem_write (mem_write_mem),
    .addr (alu_result_mem),
    .write_data (rs2_data_mem),
    .read_data (read_data_mem)
);

mem_wb_reg mem_wb_reg_inst (
    .clk (clk),
    .reset (reset),
    .reg_write_mem (reg_write_mem),
    .mem_read_mem (mem_read_mem),
    .alu_result_mem (alu_result_mem),
    .read_data_mem (read_data_mem),
    .rd_addr_mem (rd_addr_mem),
    .reg_write_wb (reg_write_wb),
    .mem_read_wb (mem_read_wb),
    .alu_result_wb (alu_result_wb),
    .read_data_wb (read_data_wb),
    .rd_addr_wb (rd_addr_wb),
    .jump_mem (jump_mem),
    .jump_wb (jump_wb),
    .link_value_mem (link_value_mem),
    .link_value_wb (link_value_wb)
);

wb_mux wb_mux_inst (
    .mem_read_wb (mem_read_wb),
    .alu_result_wb (alu_result_wb),
    .read_data_wb (read_data_wb),
    .wb_data (wb_data),
    .jump_wb (jump_wb),
    .link_value_wb (link_value_wb)
);

forwarding_unit forwarding_unit_inst (
    .rs1_addr_ex(rs1_addr_ex), 
    .rs2_addr_ex(rs2_addr_ex),
    .rd_addr_mem(rd_addr_mem), 
    .reg_write_mem(reg_write_mem),
    .rd_addr_wb(rd_addr_wb),   
    .reg_write_wb(reg_write_wb),
    .forward_a(forward_a),     
    .forward_b(forward_b)
);

hazard_detection_unit hazard_unit_inst (
    .mem_read_ex  (mem_read_ex),            // id_ex_reg output
    .rd_addr_ex   (rd_addr_ex),             // id_ex_reg output
    .rs1_addr_id  (instr_id[19:15]),        // Decoded from IF/ID instruction
    .rs2_addr_id  (instr_id[24:20]),
    .pc_write     (pc_write),
    .if_id_write  (if_id_write),
    .id_ex_bubble (id_ex_bubble)
);

// Two 3:1 forwarding muxes
assign forwarded_a = (forward_a == 2'b00) ? rs1_data_ex :
                     (forward_a == 2'b10) ? alu_result_mem :
                     (forward_a == 2'b01) ? wb_data : 32'b0;
                     
assign forwarded_b = (forward_b == 2'b00) ? rs2_data_ex :
                     (forward_b == 2'b10) ? alu_result_mem :
                     (forward_b == 2'b01) ? wb_data : 32'b0;
                     
// alu_src MUX
assign operand_b = alu_src_ex ? imm_ex : forwarded_b;

// Branch resolution
always_comb begin
    branch_taken = 1'b0;
    
    if (branch_ex) begin
    
        case(funct3_ex)
            3'b000: branch_taken = zero_ex;   // BEQ instr.
            3'b001: branch_taken = ~zero_ex;  // BNE instr.
            3'b100: branch_taken = ~zero_ex;  // BLT instr.
            3'b101: branch_taken = zero_ex;   // BGE instr.
            3'b110: branch_taken = ~zero_ex;  // BLTU instr.
            3'b111: branch_taken = zero_ex;   // BGEU instr.
            default: branch_taken = 1'b0;
        endcase
        
    end
    
end

// Link value for jal/jalr: return addr. = jump pc + 4
assign link_value_ex = pc_ex + 32'd4;

// Jump target: jalr (rs1+imm, LSB cleared), jal/branch (pc relative)
assign pc_target_ex = (jump_ex && jalr_ex) ? {alu_result_ex[31:1], 1'b0} : branch_target_ex;


assign redirect = branch_taken || jump_ex;
assign pc_next = redirect ? pc_target_ex : (pc_if + 32'd4);

assign dbg_reg_write_wb = reg_write_wb;
assign dbg_rd_addr_wb = rd_addr_wb;
assign dbg_wb_data = wb_data;


endmodule