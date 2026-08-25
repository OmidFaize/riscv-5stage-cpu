# RV32I 5-Stage Pipelined CPU

A 32-bit RISC-V processor implementing a subset of the RV32I base integer ISA,
written in SystemVerilog. This processor consists of a classic five-stage pipeline 
with full data forwarding, load-use interlock, and branch/jump flush logic.

Simulation only - verified in Vivado 2025.2 (XSim) and Icarus Verilog.

---

## Overview

The core is a five-stage pipeline (IF / ID / EX / MEM / WB) with a Harvard memory
model and synchronous active-high reset. Branch and jump instructions resolve in EX, giving a
two-cycle penalty on a redirect, with implicit predict-not-taken behaviour.

**29 instructions implemented:**

| Class | Instructions |
|---|---|
| R-type | `add` `sub` `sll` `slt` `sltu` `xor` `srl` `sra` `or` `and` |
| I-type arithmetic | `addi` `slti` `sltiu` `xori` `ori` `andi` `slli` `srli` `srai` |
| Load / Store | `lw` `sw` |
| Branch | `beq` `bne` `blt` `bge` `bltu` `bgeu` |
| Jump | `jal` `jalr` |

---

## Features

- **Full data forwarding** — EX/MEM → EX and MEM/WB → EX, on both ALU operands
- **Load-use interlock** — one-cycle stall in ID, resolved through the existing
  MEM/WB forwarding path
- **Branch and jump flush** — taken branches and jumps flush both IF/ID and ID/EX
- **Register file write bypass** — a WB write is visible to a same-cycle ID read
- **17 self-checking testbenches, 124 assertions** — 4 integration benches covering
  all three hazard classes, plus 13 unit benches
- **Mutation-validated** — every hazard mechanism was deliberately broken and the
  suite re-run to confirm the tests actually catch the failure
- **Parameterised test programs** — each testbench selects its own program, so no
  source edit is needed to switch tests

---

## Block Diagram

<!-- TODO: add draw.io diagram -->
<img width="3282" height="1980" alt="riscv_5stage_datapath" src="https://github.com/user-attachments/assets/789296bc-7b79-4816-923b-d2d209907842" />

---

## Project Structure

```
riscv_5stage_cpu.xpr                Vivado project file
riscv_5stage_cpu.srcs/
├── sources_1/new/                  RTL (17 modules)
│   ├── core_top.sv                 top level, forwarding muxes, branch resolution
│   ├── pc.sv                       program counter
│   ├── imem.sv                     instruction memory
│   ├── if_id_reg.sv                IF/ID pipeline register
│   ├── control.sv                  main control decoder
│   ├── regfile.sv                  register file with write bypass
│   ├── imm_gen.sv                  immediate generator
│   ├── id_ex_reg.sv                ID/EX pipeline register
│   ├── alu.sv                      ALU
│   ├── alu_control.sv              ALU operation decoder
│   ├── branch_target_adder.sv      pc + imm
│   ├── ex_mem_reg.sv               EX/MEM pipeline register
│   ├── dmem.sv                     data memory
│   ├── mem_wb_reg.sv               MEM/WB pipeline register
│   ├── wb_mux.sv                   writeback source select
│   ├── forwarding_unit.sv          data hazard detection
│   └── hazard_detection_unit.sv    load-use stall detection
└── sim_1/new/                      testbenches (17) and test programs
    ├── tb_core_top.sv              full integration, all hazard classes (28 checks)
    ├── tb_forwarding.sv            data forwarding (3 checks)
    ├── tb_branch.sv                all six branch types (15 checks)
    ├── tb_jump.sv                  jal / jalr (21 checks)
    ├── tb_*.sv                      13 unit benches (57 checks)
    ├── program_*.hex               test programs
    └── dmem_init.hex               data memory initialisation
```

---

## Running it

Get a copy of the project:

```bash
git clone https://github.com/yourusername/riscv-5stage-cpu.git
cd riscv-5stage-cpu
```

### Vivado

Open `riscv_5stage_cpu.xpr`. In the Sources panel, set the testbench you want as the
simulation top, then run **Run Simulation → Run Behavioral Simulation**. Results print
to the Tcl console.

### Icarus Verilog

Requires Icarus Verilog 12.0 or later. Run from the testbench directory, since
`$readmemh` resolves the `.hex` filenames relative to the working directory:

```bash
cd riscv_5stage_cpu.srcs/sim_1/new
iverilog -g2012 -o sim.vvp ../../sources_1/new/*.sv tb_core_top.sv
vvp sim.vvp
```

Substitute any other testbench name for `tb_core_top.sv`.

Icarus prints an informational note about constant selects in `always_*` blocks. It
does not affect results.

### Expected output

```
PASS: x1 = 100
PASS: x2 = 7
...
PASS: x28 (beq target) = 280
ALL TESTS PASSED
```
