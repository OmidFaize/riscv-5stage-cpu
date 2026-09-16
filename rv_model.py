#!/usr/bin/env python3

import random

M32 = 0xFFFFFFFF
IMEM_WORDS = 256
DMEM_WORDS = 256
NOP = 0x00000013
# The prologue is one addi per register x1..x31, so it always retires exactly 31 commits before the random body begins.
PROLOGUE_COMMITS = 31


def u32(v):
    return v & M32


def sgn(v):
    v &= M32
    return v - (1 << 32) if v & 0x80000000 else v


# Encoding (turning instruction into 32-bit binary)
R_OPS = {
    "add": (0b000, 0b0000000), "sub": (0b000, 0b0100000),
    "sll": (0b001, 0b0000000), "slt": (0b010, 0b0000000),
    "sltu": (0b011, 0b0000000), "xor": (0b100, 0b0000000),
    "srl": (0b101, 0b0000000), "sra": (0b101, 0b0100000),
    "or": (0b110, 0b0000000), "and": (0b111, 0b0000000),
}
I_OPS = {
    "addi": (0b000, None), "slti": (0b010, None), "sltiu": (0b011, None),
    "xori": (0b100, None), "ori": (0b110, None), "andi": (0b111, None),
    "slli": (0b001, 0b0000000), "srli": (0b101, 0b0000000),
    "srai": (0b101, 0b0100000),
}
B_OPS = {"beq": 0b000, "bne": 0b001, "blt": 0b100,
         "bge": 0b101, "bltu": 0b110, "bgeu": 0b111}


def enc_r(op, rd, rs1, rs2):
    f3, f7 = R_OPS[op]
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0110011


def enc_i(op, rd, rs1, imm):
    f3, f7 = I_OPS[op]
    if f7 is not None:
        return (f7 << 25) | ((imm & 0x1F) << 20) | (rs1 << 15) | (f3 << 12) \
               | (rd << 7) | 0b0010011
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0010011


def enc_lw(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (0b010 << 12) | (rd << 7) | 0b0000011


def enc_sw(rs1, rs2, imm):
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (0b010 << 12) \
           | ((imm & 0x1F) << 7) | 0b0100011


def enc_b(op, rs1, rs2, imm):
    f3 = B_OPS[op]
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) \
           | (rs1 << 15) | (f3 << 12) | (((imm >> 1) & 0xF) << 8) \
           | (((imm >> 11) & 1) << 7) | 0b1100011


def enc_jal(rd, imm):
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) \
           | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) \
           | (rd << 7) | 0b1101111


def enc_jalr(rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (0b000 << 12) | (rd << 7) | 0b1100111

# Decodes 32-bit binary into readable instruction
def disasm(w):
    op = w & 0x7F
    rd, rs1, rs2 = (w >> 7) & 0x1F, (w >> 15) & 0x1F, (w >> 20) & 0x1F
    f3, f7 = (w >> 12) & 7, (w >> 25) & 0x7F
    simm = sgn((w >> 20) | (0xFFFFF000 if w >> 31 else 0))
    if w == NOP:
        return "nop"
    if op == 0b0110011:
        for n, (a, b) in R_OPS.items():
            if a == f3 and b == f7:
                return f"{n} x{rd}, x{rs1}, x{rs2}"
    if op == 0b0010011:
        for n, (a, b) in I_OPS.items():
            if a == f3 and (b is None or b == f7):
                return f"{n} x{rd}, x{rs1}, {rs2 if b is not None else simm}"
    if op == 0b0000011:
        return f"lw x{rd}, {simm}(x{rs1})"
    if op == 0b0100011:
        raw = (f7 << 5) | rd
        return f"sw x{rs2}, {raw - 4096 if raw & 0x800 else raw}(x{rs1})"
    if op == 0b1100011:
        for n, a in B_OPS.items():
            if a == f3:
                return f"{n} x{rs1}, x{rs2}"
    if op == 0b1101111:
        return f"jal x{rd}"
    if op == 0b1100111:
        return f"jalr x{rd}, x{rs1}, {simm}"
    return f"<{w:08x}>"


# Create the Python golden CPU state, including its registers, memory, program counter, and expected register-write trace
class Golden:

    def __init__(self, dmem):
        self.x = [0] * 32
        self.mem = list(dmem)
        self.pc = 0
        self.trace = []                 # (rd, value) in retirement order

    def wr(self, rd, val):
        if rd:
            self.x[rd] = u32(val)
            self.trace.append((rd, u32(val)))

    # Execute one instruction in the golden CPU model and update its registers, memory, and program counter exactly as the RTL should
    def step(self, w):
        op = w & 0x7F
        rd, rs1, rs2 = (w >> 7) & 0x1F, (w >> 15) & 0x1F, (w >> 20) & 0x1F
        f3, f7 = (w >> 12) & 7, (w >> 25) & 0x7F
        a, b = self.x[rs1], self.x[rs2]
        nxt = u32(self.pc + 4)

        if op == 0b0110011:                                   # R-type
            sh = b & 0x1F
            r = {0b000: (u32(a - b) if f7 == 0b0100000 else u32(a + b)),
                 0b001: u32(a << sh),
                 0b010: int(sgn(a) < sgn(b)),
                 0b011: int(a < b),
                 0b100: a ^ b,
                 0b101: (u32(sgn(a) >> sh) if f7 == 0b0100000 else (a >> sh)),
                 0b110: a | b,
                 0b111: a & b}[f3]
            self.wr(rd, r)

        elif op == 0b0010011:                                 # I-type
            imm = sgn((w >> 20) | (0xFFFFF000 if w >> 31 else 0))
            sh = rs2
            r = {0b000: u32(a + imm),
                 0b001: u32(a << sh),
                 0b010: int(sgn(a) < imm),
                 0b011: int(a < u32(imm)),
                 0b100: a ^ u32(imm),
                 0b101: (u32(sgn(a) >> sh) if f7 == 0b0100000 else (a >> sh)),
                 0b110: a | u32(imm),
                 0b111: a & u32(imm)}[f3]
            self.wr(rd, r)

        elif op == 0b0000011:                                 # lw
            imm = sgn((w >> 20) | (0xFFFFF000 if w >> 31 else 0))
            self.wr(rd, self.mem[(u32(a + imm) >> 2) & 0xFF])

        elif op == 0b0100011:                                 # sw
            raw = (f7 << 5) | rd
            imm = raw - 4096 if raw & 0x800 else raw
            self.mem[(u32(a + imm) >> 2) & 0xFF] = u32(b)

        elif op == 0b1100011:                                 # branches
            taken = {0b000: a == b, 0b001: a != b,
                     0b100: sgn(a) < sgn(b), 0b101: sgn(a) >= sgn(b),
                     0b110: a < b, 0b111: a >= b}[f3]
            if taken:
                imm = (((w >> 31) & 1) << 12) | (((w >> 7) & 1) << 11) \
                      | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1)
                if imm & 0x1000:
                    imm -= 0x2000
                nxt = u32(self.pc + imm)

        elif op == 0b1101111:                                 # jal
            imm = (((w >> 31) & 1) << 20) | (((w >> 12) & 0xFF) << 12) \
                  | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1)
            if imm & 0x100000:
                imm -= 0x200000
            self.wr(rd, u32(self.pc + 4))
            nxt = u32(self.pc + imm)

        elif op == 0b1100111:                                 # jalr
            imm = sgn((w >> 20) | (0xFFFFF000 if w >> 31 else 0))
            tgt = u32(a + imm) & ~1
            self.wr(rd, u32(self.pc + 4))
            nxt = tgt

        self.pc = nxt
        return nxt


# Choose registers of recently-ran instructions to encourage frequent hazard testing
class Generator:

    def __init__(self, rng, body_len):
        self.rng = rng
        self.body_len = body_len

    def src(self, recent):
        r = self.rng
        if recent and r.random() < 0.55:
            return r.choice(recent)
        if r.random() < 0.08:
            return 0                       # exercise the x0 read path
        return r.randint(0, 31)

    def dst(self):
        if self.rng.random() < 0.10:
            return 0                       # exercise the x0 write guard
        return self.rng.randint(1, 31)

    # Randomly choose and encode the next instruction while controlling instruction types and branch/jump targets to create useful valid tests
    def pick(self, g, pc, body_end, recent):
        r = self.rng
        room = (body_end - pc) // 4
        kinds = ["r"] * 30 + ["i"] * 25 + ["lw"] * 12 + ["sw"] * 12
        if room > 2:
            kinds += ["b"] * 12 + ["jal"] * 5 + ["jalr"] * 4
        k = r.choice(kinds)
        rd = self.dst()
        rs1, rs2 = self.src(recent), self.src(recent)

        if k == "r":
            return enc_r(r.choice(list(R_OPS)), rd, rs1, rs2)
        if k == "i":
            op = r.choice(list(I_OPS))
            imm = r.randint(0, 31) if I_OPS[op][1] is not None else r.randint(-2048, 2047)
            return enc_i(op, rd, rs1, imm)
        if k == "lw":
            return enc_lw(rd, rs1, r.randint(-2048, 2047))
        if k == "sw":
            return enc_sw(rs1, rs2, r.randint(-2048, 2047))

        off = r.randrange(2, max(3, min(room, 7))) * 4        # forward only
        if k == "b":
            return enc_b(r.choice(list(B_OPS)), rs1, rs2, off)
        if k == "jal":
            return enc_jal(rd, off)

        tgt = pc + off
        cands = [q for q in range(32) if -2048 <= (tgt - sgn(g.x[q])) <= 2047]
        if not cands:
            return enc_r("add", rd, rs1, rs2)
        base = r.choice(cands)
        # aim one byte past sometimes, so the RTL's jalr LSB mask has work to do
        raw = tgt + r.choice([0, 0, 0, 1])
        imm = raw - sgn(g.x[base])
        if not -2048 <= imm <= 2047:
            imm = tgt - sgn(g.x[base])
        return enc_jalr(rd, base, imm)

    # Build a complete random program while simultaneously running it through the golden model to produce the expected results
    def generate(self, dmem):
        prog = [NOP] * IMEM_WORDS
        g = Golden(dmem)

        # Prologue: the register file has no reset, so every register must be written before anything reads it.
        pc = 0
        for r in range(1, 32):
            w = enc_i("addi", r, 0, self.rng.randint(-2048, 2047))
            prog[pc >> 2] = w
            g.step(w)
            pc += 4

        body_end = pc + self.body_len * 4
        executed, visited, recent = [], set(), []
        while g.pc < body_end:
            p = g.pc
            if p in visited:
                break                      # unreachable: control flow is forward-only
            visited.add(p)
            w = self.pick(g, p, body_end, recent)
            prog[p >> 2] = w
            executed.append((p, w))
            g.step(w)
            if (w & 0x7F) not in (0b1100011, 0b0100011):
                recent.insert(0, (w >> 7) & 0x1F)
                del recent[3:]
        return prog, g, executed

# Generate new random test case when called by test_cpu.py
def make_program(seed, body_len=60):
    rng = random.Random(seed)
    dmem = [rng.getrandbits(32) for _ in range(DMEM_WORDS)]
    prog, gold, executed = Generator(rng, body_len).generate(dmem)
    return prog, gold, executed, dmem

# Map a failed register-write index back to the exact program counter and instruction that produced it
def locate(executed, idx):
    idx -= PROLOGUE_COMMITS
    if idx < 0:
        return None, None
    n = 0
    for pc, w in executed:
        rd, op = (w >> 7) & 0x1F, w & 0x7F
        if rd != 0 and op not in (0b1100011, 0b0100011):
            if n == idx:
                return pc, w
            n += 1
    return None, None

# Format a generated program into a readable assembly listing with addresses, execution order, and the location of a failure
def listing(prog, executed, gold, mark_pc=None, seed=None):
    order = {pc: i for i, (pc, _) in enumerate(executed)}
    out = []
    if seed is not None:
        out.append(f"; random program, seed {seed}")
    out.append(f"; {len(executed)} instructions executed, "
               f"{len(gold.trace)} register commits")
    out.append("; prologue = addi x1..x31 (the register file has no reset)")
    out.append(";")
    out.append(";  addr   word      exec#  instruction")
    out.append("; ------ --------  -----  -----------------------------")

    last = max((pc for pc, _ in executed), default=0)
    limit = max(last + 8, PROLOGUE_COMMITS * 4 + 8)
    for i in range(0, min(limit, IMEM_WORDS * 4), 4):
        w = prog[i >> 2]
        if i < PROLOGUE_COMMITS * 4:
            tag = "  pro "
        elif i in order:
            tag = f"{order[i]:5d} "
        else:
            tag = "   -  "
        flag = "  <<< HERE" if mark_pc is not None and i == mark_pc else ""
        if tag == "   -  " and w == NOP:
            note = "nop            ; not reached"
        else:
            note = disasm(w)
        out.append(f"  0x{i:04x} {w:08x}  {tag} {note}{flag}")
    return "\n".join(out) + "\n"


# Self-test the golden model against hand-calculated instruction results before using it to verify the real CPU
if __name__ == "__main__":
    # Sanity-check the golden model against hand-computed expectations
    g = Golden([0] * DMEM_WORDS)
    checks = [
        (enc_i("addi", 1, 0, -5), 1, u32(-5), "addi negative"),
        (enc_i("addi", 2, 0, 100), 2, 100, "addi positive"),
        (enc_r("sub", 3, 2, 1), 3, 105, "sub"),
        (enc_r("slt", 4, 1, 2), 4, 1, "slt signed (-5 < 100)"),
        (enc_r("sltu", 5, 1, 2), 5, 0, "sltu unsigned (huge > 100)"),
        (enc_i("srai", 6, 1, 1), 6, u32(-3), "srai arithmetic"),
        (enc_i("srli", 7, 1, 1), 7, (u32(-5)) >> 1, "srli logical"),
        (enc_i("slli", 8, 2, 33 & 0x1F), 8, u32(100 << 1), "slli shamt masks to 5 bits"),
    ]
    bad = 0
    for w, rd, exp, name in checks:
        g.step(w)
        got = g.x[rd]
        ok = got == exp
        bad += not ok
        print(f"  {'OK  ' if ok else 'FAIL'} {name:34s} x{rd} = {got:08x} (want {exp:08x})")
    prog, gold, ex, dm = make_program(1, 40)
    print(f"\n  generated program: {len(ex)} instructions executed, "
          f"{len(gold.trace)} commits")
    print("\n" + ("golden model self-check PASSED" if not bad
                  else f"{bad} SELF-CHECK FAILURE(S)"))
    raise SystemExit(1 if bad else 0)
