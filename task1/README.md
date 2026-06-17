# BIT 4220 — Task 1: Assembly Environment & Digital Representation Toolkit

## Overview
This repository contains two NASM x86-64 assembly programs built for a Linux
environment, demonstrating:

1. `hello.asm` — a minimal "Hello World" program showing the basic structure
   of a NASM program and the `write`/`exit` Linux system calls.
2. `data_types.asm` — a program that stores byte, word and doubleword sized
   data and prints their ASCII interpretation, raw hex bytes, and
   demonstrates little-endian storage and two's complement representation.

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
task1/
├── hello.asm           # Hello world program
├── data_types.asm      # Byte/word/dword + ASCII + endianness demo
├── Makefile             # Build automation
└── README.md             # This file
```

## Build Process

### Option A — Using the Makefile (recommended)

```bash
make            # builds both hello and data_types
make run        # builds and runs both programs
make clean      # removes object files and binaries
```

### Option B — Manual build (step by step)

Each program is built in two stages: **assemble** (NASM converts `.asm`
source into an ELF object file) then **link** (`ld` converts the object
file into an executable).

```bash
# Assemble
nasm -f elf64 hello.asm -o hello.o

# Link
ld hello.o -o hello

# Run
./hello
```

```bash
nasm -f elf64 data_types.asm -o data_types.o
ld data_types.o -o data_types
./data_types
```

**What each flag means:**
| Command/Flag | Meaning |
|---|---|
| `-f elf64` | Tells NASM to produce a 64-bit ELF object file format |
| `-o file.o` | Output object file name |
| `ld file.o -o file` | Links the object file into a standalone executable named `file` |

## Expected Output

```
$ ./hello
Hello, BIT4220 students! Welcome to Assembly.

$ ./data_types
Byte  (1 byte)  as char       : A
Word  (2 bytes) low byte char : C
Dword (4 bytes) as 4 chars    : GFED
Dword raw bytes in hex (LE)   : 47 46 45 44
neg_val (-5) raw bytes (hex)  : FB FF FF FF
```

## Debugging & Memory Inspection Evidence

### Using GDB

```bash
gdb ./data_types
```

Inside GDB:

```
(gdb) break _start
(gdb) run
(gdb) x/8xb &my_dword      # examine 8 bytes in hex starting at my_dword
(gdb) x/1xw &my_dword      # examine the same memory as one 4-byte word
(gdb) x/4xb &neg_val       # examine the two's complement representation
(gdb) info registers
(gdb) stepi                # step one instruction at a time
(gdb) quit
```

**Sample captured output:**

```
(gdb) x/8xb &my_dword
0x402003:  0x47  0x46  0x45  0x44  0x05  0x00  0x00  0x00

(gdb) x/1xw &my_dword
0x402003:  0x44454647

(gdb) x/4xb &neg_val
0x40200b:  0xfb  0xff  0xff  0xff
```

> **Screenshot placeholder:** Insert a screenshot of this GDB session here
> (`x/8xb`, `x/1xw`, and `x/4xb` output) as required by the assignment
> deliverable "Use GDB or objdump to inspect memory layout and show
> evidence through screenshots."

**Interpretation:** `my_dword` was declared as `dd 0x44454647`. GDB shows the
actual bytes in memory are `47 46 45 44` — reversed from how the value is
written in source. This is direct evidence of **little-endian** storage: the
least-significant byte (`0x47`) is stored at the lowest memory address.

Similarly, `neg_val = -5` is stored as `0xfb 0xff 0xff 0xff`, which read as a
32-bit little-endian word is `0xFFFFFFFB` — the **two's complement**
representation of -5.

### Using objdump

```bash
# Disassemble the program's instructions
objdump -d data_types

# Dump the raw bytes of the .data section
objdump -s -j .data data_types
```

**Sample captured output:**

```
$ objdump -s -j .data data_types

data_types:     file format elf64-x86-64

Contents of section .data:
 402000 41434247 46454405 000000fb ffffff42  ACBGFED........B
 402010 79746520 20283120 62797465 29202061  yte  (1 byte)  a
 ...
```

> **Screenshot placeholder:** Insert a screenshot of the `objdump -s -j
> .data` output here, alongside `objdump -d` showing disassembled
> instructions, as evidence for the deliverable.

The first 15 bytes of `.data` (`41 43 42 47 46 45 44 05 00 00 00 fb ff ff
ff`) correspond exactly to: `my_byte` (`41`), `my_word` low byte (`43`),
`my_dword` four bytes (`47 46 45 44`), `pos_val` (`05 00 00 00`), and
`neg_val` (`fb ff ff ff`) — confirming the program's data layout matches
what was declared in source.

### Using readelf (alternative cross-check)

```bash
readelf -x .data data_types
```

This produces the same raw hex dump as `objdump -s` and can be used as a
second source of evidence.

## Tutorial for Other Students: Compile, Link & Run a NASM Program

If you are new to NASM on Linux/WSL, follow these steps for any program in
this repository:

1. **Write or open your `.asm` file** in a text editor (e.g. `nano`, VS
   Code).
2. **Assemble it** — this turns human-readable assembly into machine code
   stored in an object file:
   ```bash
   nasm -f elf64 yourprogram.asm -o yourprogram.o
   ```
3. **Link it** — this takes the object file and produces a runnable
   executable, resolving things like the entry point (`_start`):
   ```bash
   ld yourprogram.o -o yourprogram
   ```
4. **Run it**:
   ```bash
   ./yourprogram
   ```
5. **If something goes wrong**, common issues are:
   - Forgetting `global _start` at the top of `.text` — the linker won't
     know where the program begins.
   - Mismatched `-f elf64` flag if you're on a 32-bit system (use `-f
     elf32` instead, and adjust registers to 32-bit forms).
   - A `Segmentation fault` usually means a syscall was given a bad
     pointer or length — double check `rsi`/`rdx` before `syscall`.
6. **To debug**, use `gdb ./yourprogram` and set a breakpoint at `_start`
   before stepping through instructions one at a time with `stepi`.

This same four-step pipeline (assemble → link → run → debug) applies to
every program in this repository and in later tasks.

## Deliverables Checklist

- [x] `hello.asm` — hello world program
- [x] `data_types.asm` — byte/word/dword storage + ASCII interpretation
- [x] `Makefile` — build automation
- [x] README with setup steps, commands, and GDB/objdump evidence
- [ ] Screenshots of GDB and objdump sessions (to be added by group —
      see placeholders above)
- [x] Two-page technical note on data representation (`technical_note.md`)
