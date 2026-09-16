#!/usr/bin/env python3
# run_cocotb.py - build and run the cocotb testbench.

import argparse
import os
import shutil
import sys
from pathlib import Path

# Handles multiple cocotb versions (2, 1.8, 1.9)
try:
    from cocotb_tools.runner import get_runner, get_results
    COCOTB_MAJOR = 2
except ImportError:                                    
    try:
        from cocotb.runner import get_runner, get_results
        COCOTB_MAJOR = 1
    except ImportError:
        sys.exit("error: cocotb is not installed.  pip install cocotb")


def main():
    # Create command-line options
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rtl", default="riscv_5stage_cpu.srcs/sources_1/new",
                    help="directory containing the RTL .sv files")
    ap.add_argument("--programs", type=int, default=20,
                    help="number of random programs (default 20)")
    ap.add_argument("--length", type=int, default=60,
                    help="random instructions per program (default 60)")
    ap.add_argument("--seed", type=int, default=1,
                    help="base seed; the same value reproduces the same run")
    ap.add_argument("--sim", default=os.environ.get("SIM", "icarus"),
                    help="simulator name (default icarus)")
    ap.add_argument("--waves", action="store_true", help="dump waveforms")
    ap.add_argument("--build-dir", default="sim_build")
    ap.add_argument("--dump-dir", default="generated",
                    help="where failing programs are written as assembly")
    ap.add_argument("--dump-seed", type=int, metavar="N",
                    help="write the assembly listing for seed N and exit "
                         "(no simulator needed)")
    a = ap.parse_args()

    dump_dir = Path(a.dump_dir).resolve()

    # --dump-seed inspects a program without running the simulator at all.
    if a.dump_seed is not None:
        from rv_model import make_program, listing
        prog, gold, executed, _ = make_program(a.dump_seed, a.length)
        dump_dir.mkdir(parents=True, exist_ok=True)
        out = dump_dir / f"seed_{a.dump_seed}.asm.txt"
        out.write_text(listing(prog, executed, gold, seed=a.dump_seed),
                       encoding="utf-8")
        print(f"wrote {out}")
        print(f"  {len(executed)} instructions executed, "
              f"{len(gold.trace)} register commits")
        return 0

    # Ensure correct Icarus Verilog is installed
    if not shutil.which("iverilog") and a.sim == "icarus":
        sys.exit("error: iverilog not found on PATH")

    # Finds all SystemVerilog RTL files and ensures top-level CPU file exists
    rtl = Path(a.rtl).resolve()
    sources = sorted(rtl.glob("*.sv"))
    if not any(p.name == "core_top.sv" for p in sources):
        sys.exit(f"error: core_top.sv not found in {rtl}  (use --rtl)")

    here = Path(__file__).resolve().parent
    build = Path(a.build_dir).resolve()
    build.mkdir(parents=True, exist_ok=True)

    # imem/dmem call $readmemh at time 0. cocotb overwrites both arrays before
    # releasing reset, but without these files Icarus prints an error for every
    # run, so drop harmless placeholders next to the simulation.
    for stub in ("program_full.hex", "dmem_init.hex"):
        f = build / stub
        if not f.exists():
            f.write_text("00000013\n" * 256)

    print(f"cocotb {COCOTB_MAJOR}.x   simulator: {a.sim}")
    print(f"RTL   : {rtl}  ({len(sources)} files)")
    print(f"run   : {a.programs} programs x {a.length} instructions, "
          f"base seed {a.seed}\n")

    # Gets simulator controller, set up compilation options, and compiles CPU
    runner = get_runner(a.sim)
    build_kwargs = dict(
        hdl_toplevel="core_top",
        always=True,
        build_dir=str(build),
        timescale=("1ns", "1ps"),
        build_args=["-g2012"],
    )
    # cocotb 2.x renamed verilog_sources -> sources
    if COCOTB_MAJOR >= 2:
        build_kwargs["sources"] = sources
    else:
        build_kwargs["verilog_sources"] = sources
    if a.waves:
        build_kwargs["waves"] = True

    runner.build(**build_kwargs)

    # Send test settings to test_cpu.py
    env = dict(os.environ)
    env.update(NUM_PROGRAMS=str(a.programs),
               PROG_LEN=str(a.length),
               BASE_SEED=str(a.seed),
               # absolute, because the simulator runs with build_dir as its cwd
               DUMP_DIR=str(dump_dir),
               PYTHONPATH=str(here) + os.pathsep + env.get("PYTHONPATH", ""))

    # Uses core_top.sv as CPU and test_cpu.py as Python testbench
    test_kwargs = dict(hdl_toplevel="core_top", test_module="test_cpu",
                       build_dir=str(build), extra_env=env)
    if a.waves:
        test_kwargs["waves"] = True

    # Starts simulation
    results_xml = runner.test(**test_kwargs)

    # runner.test() does not raise on a failing testcase, so read the xUnit
    # results file and turn a failure into a non-zero exit status.

    # Check pass/fail
    total, failed = get_results(results_xml)
    print()
    if failed:
        print(f"FAILED - {failed} of {total} cocotb test(s) failed")
        print(f"reproduce with: python run_cocotb.py --seed {a.seed} "
              f"--programs {a.programs} --length {a.length}")
        return 1
    print(f"PASS - {total} cocotb test(s) passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
