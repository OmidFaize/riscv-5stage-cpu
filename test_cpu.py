# test_cpu.py - cocotb testbench for the RV32I-subset 5-stage pipelined CPU.

import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

from rv_model import (make_program, locate, disasm, listing,
                      IMEM_WORDS, DMEM_WORDS, PROLOGUE_COMMITS)

# Where failing programs are written as readable assembly.
DUMP_DIR = Path(os.environ.get("DUMP_DIR", "generated"))

CLK_NS = 10

# Create and start clock cycle that drives the CPU
async def start_clock(dut):
    """Each cocotb test gets a fresh task scheduler, so the clock must be
    started inside every test rather than once at module level."""
    cocotb.start_soon(Clock(dut.clk, CLK_NS, units="ns").start())
    dut.reset.value = 1
    await FallingEdge(dut.clk)

# Converts hardware signal values into Python integers
def _int(sig):
    """Read a handle, returning None if it holds X/Z."""
    try:
        return int(sig.value)
    except Exception:
        return None

# Saves a failing program to inspect faulty instruction
def dump_listing(prog, executed, gold, seed, mark_pc, log):
    """Write the failing program as assembly so the seed can be inspected."""
    try:
        DUMP_DIR.mkdir(parents=True, exist_ok=True)
        path = DUMP_DIR / f"seed_{seed}.asm.txt"
        path.write_text(listing(prog, executed, gold, mark_pc=mark_pc, seed=seed),
                        encoding="utf-8")
        log.info(f"wrote assembly listing: {path.resolve()}")
        return path
    except Exception as e:                       # never mask the real failure
        log.warning(f"could not write listing: {e}")
        return None

# Loads new program into instruction memory, and initializes data into data memory
async def load_memories(dut, prog, dmem):
    """Write the program and data memory directly through VPI."""
    for i in range(IMEM_WORDS):
        dut.imem_inst.memory[i].value = prog[i]
    for i in range(DMEM_WORDS):
        dut.dmem_inst.mem[i].value = dmem[i]

# Generate a random program and its golden results, reset the pipeline, load the new memories, and begin execution 
async def run_program(dut, seed, body_len, log):
    """Load one random program, run it, scoreboard every commit."""
    prog, gold, executed, dmem = make_program(seed, body_len)
    expected = gold.trace

    dut.reset.value = 1
    for _ in range(4):
        await FallingEdge(dut.clk)
    await load_memories(dut, prog, dmem)
    for _ in range(2):
        await FallingEdge(dut.clk)
    dut.reset.value = 0

    # Compares architectural register write-back from CPU against rv_model.py
    observed = []
    cycle = 0                       # cycles since reset was released
    budget = 2 * len(executed) + 2 * 31 + 60
    for _ in range(budget):
        await FallingEdge(dut.clk)
        cycle += 1
        if _int(dut.reset):
            continue
        we = _int(dut.dbg_reg_write_wb)
        rd = _int(dut.dbg_rd_addr_wb)
        if not we or not rd:
            continue
        val = _int(dut.dbg_wb_data)
        idx = len(observed)
        if idx >= len(expected):
            dump_listing(prog, executed, gold, seed, None, log)
            raise AssertionError(
                f"seed {seed}: DUT committed more writes than the model "
                f"expected ({len(expected)}); extra write x{rd} = "
                f"{'X' if val is None else format(val, '08x')} "
                f"at cycle {cycle}")
        exp_rd, exp_val = expected[idx]
        if rd != exp_rd or val != exp_val:
            pc, w = locate(executed, idx)
            where = (f"pc 0x{pc:03x}:  {disasm(w)}   [{w:08x}]"
                     if pc is not None
                     else f"the register-init prologue (commit {idx} of "
                          f"{PROLOGUE_COMMITS})")
            path = dump_listing(prog, executed, gold, seed, pc, log)
            raise AssertionError(
                f"seed {seed}: architectural write-back mismatch\n"
                f"    commit #  : {idx}\n"
                f"    expected  : x{exp_rd} = {exp_val:08x}\n"
                f"    actual    : x{rd} = "
                f"{'X' if val is None else format(val, '08x')}\n"
                f"    from      : {where}\n"
                f"    at cycle  : {cycle} (falling edges since reset released)\n"
                f"    listing   : {path}\n"
                f"    reproduce : python run_cocotb.py --seed {seed} --programs 1")
        observed.append((rd, val))

        # Waits additional clock cycles to ensure CPU has truly finished executing instructions
        if len(observed) == len(expected):
            for _ in range(16):
                await FallingEdge(dut.clk)
                cycle += 1
                if _int(dut.dbg_reg_write_wb) and _int(dut.dbg_rd_addr_wb):
                    dump_listing(prog, executed, gold, seed, None, log)
                    raise AssertionError(
                        f"seed {seed}: an extra register write arrived "
                        f"{16} cycles after the expected {len(expected)} "
                        f"commits were already observed -- the expected "
                        f"commit count itself may be wrong")
            break

    if len(observed) < len(expected):
        pc, w = locate(executed, len(observed))
        where = (f"pc 0x{pc:03x}:  {disasm(w)}" if pc is not None
                 else "the register-init prologue")
        path = dump_listing(prog, executed, gold, seed, pc, log)
        raise AssertionError(
            f"seed {seed}: DUT retired only {len(observed)} of "
            f"{len(expected)} expected writes after {cycle} cycles "
            f"(stalled, or an instruction was lost).\n"
            f"    next expected : {where}\n"
            f"    listing       : {path}")

    # A few idle cycles: nothing further should commit
    for _ in range(6):
        await FallingEdge(dut.clk)
        cycle += 1
        if _int(dut.dbg_reg_write_wb) and _int(dut.dbg_rd_addr_wb):
            dump_listing(prog, executed, gold, seed, None, log)
            raise AssertionError(
                f"seed {seed}: unexpected extra commit at cycle {cycle}, "
                f"after the program should have finished")

    # Checks if memory-writing instructions wrote to the correct address with the correct data
    for i in range(DMEM_WORDS):
        got = _int(dut.dmem_inst.mem[i])
        if got != gold.mem[i]:
            path = dump_listing(prog, executed, gold, seed, None, log)
            raise AssertionError(
                f"seed {seed}: data memory mismatch after {cycle} cycles\n"
                f"    dmem[{i}] (byte address 0x{i * 4:03x})\n"
                f"    expected  : {gold.mem[i]:08x}\n"
                f"    actual    : {'X' if got is None else format(got, '08x')}\n"
                f"    listing   : {path}")

    log.info(f"seed {seed:>10}: {len(executed):3d} instructions, "
             f"{len(expected):3d} commits, {cycle:4d} cycles, dmem clean")
    return len(executed)

# Verifies hand-written manual data/control hazards are handled
@cocotb.test()
async def directed_smoke_test(dut):
    from rv_model import enc_i, enc_r, enc_sw, enc_lw, NOP

    await start_clock(dut)
    prog = [
        enc_i("addi", 1, 0, 100),       # x1 = 100
        enc_i("addi", 2, 0, 7),         # x2 = 7
        enc_r("add", 3, 1, 2),          # x3 = 107   (EX/MEM forward, back to back)
        enc_r("sub", 4, 3, 2),          # x4 = 100   (forward again)
        enc_sw(0, 3, 16),               # mem[4] = 107
        enc_lw(5, 0, 16),               # x5 = 107
        enc_r("add", 6, 5, 2),          # x6 = 114   (load-use: needs a stall)
    ] + [NOP] * (IMEM_WORDS - 7)
    expect = [(1, 100), (2, 7), (3, 107), (4, 100), (5, 107), (6, 114)]

    await load_memories(dut, prog, [0] * DMEM_WORDS)
    await FallingEdge(dut.clk)
    dut.reset.value = 0

    seen = []
    for _ in range(40):
        await FallingEdge(dut.clk)
        if _int(dut.dbg_reg_write_wb) and _int(dut.dbg_rd_addr_wb):
            seen.append((_int(dut.dbg_rd_addr_wb), _int(dut.dbg_wb_data)))
        if len(seen) == len(expect):
            break
    assert seen == expect, f"smoke test: got {seen}, expected {expect}"
    assert _int(dut.dmem_inst.mem[4]) == 107, "smoke test: store did not land"
    dut._log.info("directed smoke test OK (forwarding, load-use stall, store/load)")

# Runs randomly-generated programs and verifies if they are correct according to Python model
@cocotb.test()
async def random_instruction_test(dut):
    n_prog = int(os.environ.get("NUM_PROGRAMS", 20))
    body = int(os.environ.get("PROG_LEN", 60))
    base = int(os.environ.get("BASE_SEED", 1))

    await start_clock(dut)

    rng = random.Random(base)
    seeds = [rng.randrange(1 << 30) for _ in range(n_prog)]

    dut._log.info(f"running {n_prog} random programs, {body} instructions each")
    total = 0
    for s in seeds:
        total += await run_program(dut, s, body, dut._log)

    dut._log.info(f"PASS - {n_prog} programs, {total} instructions, 0 mismatches")
