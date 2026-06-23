# BIT 4220 — Assembly Programming 

## Environment

All programs are written in NASM x86-64 assembly for a Linux environment
and were built/tested on WSL (Ubuntu) on Windows. The same toolchain works
on native Linux.

```bash
sudo apt update
sudo apt install -y nasm gdb binutils build-essential
```

Each task folder follows the same pattern:

```bash
cd taskN
make            # assemble + link
make run        # build and run
make debug      # build with debug symbols, for use with gdb
make clean      # remove build artifacts
```

## Task Index

| Task | Title | Status | Folder |
|---|---|---|---|
| 1 | Assembly Environment & Digital Representation Toolkit | ✅ Complete | [`task1/`](./task1) |
| 2 | Student Marks Processor Using Registers and Addressing Modes | ✅ Complete | [`task2/`](./task2) |
| 3 | Mini Arithmetic Logic Unit for an Embedded Billing Device | ✅ Complete | [`task3/`](./task3) |

## Task Summaries

### Task 1 — Assembly Environment & Digital Representation Toolkit
Two NASM programs: a minimal hello-world demonstrating the basic
assemble/link/run pipeline, and a data-types demo storing bytes, words,
and doublewords to show ASCII interpretation, two's complement, and
little-endian storage — all confirmed with GDB and `objdump` memory dumps.

### Task 2 — Student Marks Processor Using Registers and Addressing Modes
Processes a 12-mark array entirely in memory: total, average, highest,
lowest, and a four-band classification (Fail/Pass/Credit/Distinction).
Deliberately uses six addressing modes (immediate, register, direct,
indexed, based, indirect) and includes a dedicated boundary-value test
build covering marks 0, 39, 40, 59, 60, 69, 70, 100.

### Task 3 — Mini Arithmetic Logic Unit for an Embedded Billing Device
A menu-driven ALU simulator reading two single-digit numbers via Linux
system calls. Supports ADD, SUBTRACT, MULTIPLY, DIVIDE, AND, OR, XOR, and
NOT, with a GDB-verified flag analysis table covering seven operations,
explicit divide-by-zero protection, and input validation. The README
documents a real register-clobbering bug found and fixed during
development — useful reading for understanding why register values can't
be assumed to survive a `call`.



## Repository Conventions

- One folder per task, named `taskN` (lowercase, no spaces).
- Each task folder contains: source `.asm` file(s), a `Makefile`, a
  `README.md` (build/run instructions, test cases, example output), and a
  `technical_note.md` (the deeper technical writeup specific to that
  task's deliverables).
- Build artifacts (`.o` files and compiled executables) are currently
  committed alongside source for convenience. If the repository grows too
  large, the group may switch to a `.gitignore` excluding these — open to
  discussion.
- GDB/objdump screenshots are added by whoever runs the debugging session
  on their own machine, since these need to be captured interactively and
  can't be generated ahead of time.
