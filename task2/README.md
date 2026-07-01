# BIT 4220 — Task 2: Student Marks Processor Using Registers and Addressing Modes
"We were required to write an assembly program that processes 12 student marks using registers and addressing modes. We have two programs — marks.asm which runs on real marks, and marks_boundary_test.asm which tests edge values to prove the classification logic is correct.
The program computes the total by looping through the array using indexed addressing. It finds the average using the DIV instruction. It finds highest and lowest using based addressing — where register rsi holds the array's address at runtime. It classifies marks using indirect addressing — a pointer in rdi that moves through the array one mark at a time.
We used GDB to pause the program mid-execution and prove that rsi holds address 0x402000 — the exact location of the marks array. We used objdump to confirm the symbol table and the raw data stored in memory."

## Overview
This repository folder contains a NASM x86-64 assembly program built for a
Linux environment, demonstrating how a small dataset can be processed
entirely at the register/memory level using multiple addressing modes:

1. `marks.asm` — defines an array of 12 student marks in memory and
   computes the total, average, highest, lowest, and classification counts
   (Fail / Pass / Credit / Distinction), using immediate, register, direct,
   indexed, based, and indirect addressing.
2. `marks_boundary_test.asm` — the same program with the marks array
   replaced by the exact boundary values required by the assignment
   (0, 39, 40, 69, 70, 100, plus extra values), used to prove the
   classification logic is correct at every band edge.

## Classification Bands

| Band | Range |
|---|---|
| Fail | 0 – 39 |
| Pass | 40 – 59 |
| Credit | 60 – 69 |
| Distinction | 70 – 100 |

## Environment Setup (WSL / Ubuntu / Debian-based Linux)

Install the required toolchain:

```bash
sudo apt update
sudo apt install -y nasm gdb binutils build-essential
```

Verify installation:

```bash
nasm -v          # NASM version 2.x
gdb --version    # GNU gdb
ld --version     # GNU linker
objdump --version
```

## Repository Structure

```
task2/
├── marks.asm                  # Main program (12-mark dataset)
├── marks_boundary_test.asm    # Same program, boundary-value dataset
├── Makefile                    # Build automation
├── README.md                   # This file
└── technical_note.md           # Memory map, addressing-mode commentary
```

## Build Process

### Option A — Using the Makefile (recommended)

```bash
make            # builds both marks and marks_boundary_test
make run        # builds and runs both programs
make debug      # builds marks_dbg with debug symbols, for use with gdb
make clean      # removes object files and binaries
```

### Option B — Manual build (step by step)

```bash
# Assemble
nasm -f elf64 marks.asm -o marks.o

# Link
ld marks.o -o marks

# Run
./marks
```

```bash
nasm -f elf64 marks_boundary_test.asm -o marks_boundary_test.o
ld marks_boundary_test.o -o marks_boundary_test
./marks_boundary_test
```

**What each flag means:**
| Command/Flag | Meaning |
|---|---|
| `-f elf64` | Tells NASM to produce a 64-bit ELF object file format |
| `-o file.o` | Output object file name |
| `ld file.o -o file` | Links the object file into a standalone executable named `file` |

## Expected Output

```
$ ./marks
=== Student Marks Report ===
Total: 678
Average: 56
Highest: 100
Lowest: 0
Fail (0-39): 3
Pass (40-59): 3
Credit (60-69): 2
Distinction (70-100): 4

$ ./marks_boundary_test
=== Student Marks Report ===
Total: 588
Average: 49
Highest: 100
Lowest: 0
Fail (0-39): 4
Pass (40-59): 3
Credit (60-69): 2
Distinction (70-100): 3
```

## Boundary Test Cases

| Mark | Expected classification | Confirmed |
|---|---|---|
| 0 | Fail | ✅ |
| 39 | Fail | ✅ |
| 40 | Pass | ✅ |
| 59 | Pass | ✅ |
| 60 | Credit | ✅ |
| 69 | Credit | ✅ |
| 70 | Distinction | ✅ |
| 100 | Distinction | ✅ |

## Debugging & Memory Inspection Evidence

### Using GDB

```bash
make debug
gdb ./marks_dbg
```

Inside GDB:

```
(gdb) break minmax_loop
(gdb) run
(gdb) print/x $rsi          # base address of the marks array (based addressing)
(gdb) print $rcx            # current loop offset register
(gdb) x/12db marks          # dump the 12 mark bytes in memory
(gdb) info registers rax rbx rcx rdx rsi rdi
(gdb) continue
(gdb) quit
```

**Sample captured output:**

```
Breakpoint 1, minmax_loop () at marks.asm:89
89          cmp rcx, NUM_MARKS
(gdb) print/x $rsi
$1 = 0x402000
(gdb) print $rcx
$2 = 1
(gdb) x/12db marks
0x402000 <marks>:  55  39  100  0  70  69  40  85
0x402008:          60  23  90  47
```

> **Screenshot placeholder:** Insert a screenshot of this GDB session here
> (the `break`, `print/x $rsi`, `print $rcx`, and `x/12db marks` output) as
> required by the assignment deliverable "Screenshots of register and flag
> inspection."

**Interpretation:** `rsi` holds `0x402000`, which is exactly the address of
the `marks` label confirmed by `objdump -t`. This is direct evidence of
**based addressing** — `rsi` acts as the base register, and `rcx` (shown as
`1` at this breakpoint) is added to it as the loop advances, accessing
`marks[1]`, `marks[2]`, and so on via `[rsi + rcx]`.

### Using objdump

```bash
# View symbol table with offsets (used for the memory map)
objdump -t marks.o

# Disassemble the program's instructions
objdump -d marks

# Dump the raw bytes of the .data section
objdump -s -j .data marks
```

**Sample captured output:**

```
$ objdump -t marks.o
0000000000000000 l       .data  0000000000000000 marks
000000000000000c l       .data  0000000000000000 header
...
0000000000000000 l       .bss   0000000000000000 total
0000000000000008 l       .bss   0000000000000000 average
0000000000000009 l       .bss   0000000000000000 highest
000000000000000a l       .bss   0000000000000000 lowest
000000000000000b l       .bss   0000000000000000 fail_cnt
```

> **Screenshot placeholder:** Insert a screenshot of `objdump -t marks.o`
> and `objdump -d marks` here as evidence for the deliverable.

The symbol table confirms `marks` sits at offset `0x00` in `.data`, and each
`.bss` counter/result variable sits at consecutive byte offsets — matching
exactly what is declared in source and detailed in `technical_note.md`.

### Using readelf (alternative cross-check)

```bash
readelf -x .data marks
```

This produces the same raw hex dump as `objdump -s` and can be used as a
second source of evidence.

## Tutorial: Compile, Link & Run This Program

If you are new to NASM on Linux/WSL, follow these steps:

1. **Write or open your `.asm` file** in a text editor (e.g. `nano`, VS
   Code).
2. **Assemble it** — turns human-readable assembly into machine code
   stored in an object file:
   ```bash
   nasm -f elf64 marks.asm -o marks.o
   ```
3. **Link it** — takes the object file and produces a runnable executable,
   resolving the entry point (`_start`):
   ```bash
   ld marks.o -o marks
   ```
4. **Run it**:
   ```bash
   ./marks
   ```
5. **If something goes wrong**, common issues are:
   - Forgetting `global _start` at the top of `.text`.
   - Mismatched `-f elf64` flag if you're on a 32-bit system.
   - A `Segmentation fault` usually means a syscall was given a bad
     pointer or length — double-check `rsi`/`rdx` before `syscall`.
6. **To debug**, use `gdb ./marks_dbg` (built via `make debug`) and set a
   breakpoint before stepping through instructions one at a time.

This same four-step pipeline (assemble → link → run → debug) applies to
every program in this repository.

## Deliverables Checklist

- [x] `marks.asm` — working NASM program (total, average, highest, lowest, classification)
- [x] `marks_boundary_test.asm` — boundary-value test build
- [x] `Makefile` — build automation
- [x] README with setup steps, commands, and GDB/objdump evidence
- [ ] Screenshots of GDB and objdump sessions (to be added by group — see placeholders above)
- [x] Memory map and addressing-mode commentary (`technical_note.md`)
- [x] Boundary test cases for marks 0, 39, 40, 69, 70, 100
