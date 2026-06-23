# BIT 4220 — Task 3: Mini Arithmetic Logic Unit for an Embedded Billing Device

## Overview
This repository folder contains a menu-driven ALU simulator for a prepaid
utility meter, built as a single NASM x86-64 assembly program:

- `alu.asm` — reads two single-digit numbers via Linux `sys_read` and
  performs the operation chosen from an on-screen menu: ADD, SUBTRACT,
  MULTIPLY, DIVIDE, AND, OR, XOR, and NOT. The bitwise operations model the
  "apply bit masks for device status" requirement from the brief.

The program loops continuously, re-printing the menu after every
operation, until the user selects EXIT (option 9) or stdin reaches EOF.

## Menu

```
=== Prepaid Meter ALU Simulator ===
1) ADD       (add units)
2) SUBTRACT  (subtract usage)
3) MULTIPLY  (multiply rate)
4) DIVIDE    (divide balance)
5) AND       (status mask)
6) OR        (status mask)
7) XOR       (status mask)
8) NOT       (invert first value only)
9) EXIT
Choose an option (1-9):
```

Options 1–7 prompt for two single digits (0–9). Option 8 (NOT) only prompts
for one digit, since NOT is a unary operation.

## Environment Setup (WSL / Ubuntu / Debian-based Linux)

```bash
sudo apt update
sudo apt install -y nasm gdb binutils build-essential
```

## Repository Structure

```
task3/
├── alu.asm              # ALU simulator source
├── Makefile              # Build automation
├── README.md             # This file
└── technical_note.md     # Flag analysis table and overflow discussion
```

## Build Process

### Option A — Using the Makefile (recommended)

```bash
make            # builds alu
make run        # builds and runs alu interactively
make debug      # builds alu_dbg with debug symbols, for use with gdb
make clean      # removes object files and binaries
```

### Option B — Manual build

```bash
nasm -f elf64 alu.asm -o alu.o
ld alu.o -o alu
./alu
```

## Example Session

```
$ ./alu
=== Prepaid Meter ALU Simulator ===
1) ADD       (add units)
2) SUBTRACT  (subtract usage)
3) MULTIPLY  (multiply rate)
4) DIVIDE    (divide balance)
5) AND       (status mask)
6) OR        (status mask)
7) XOR       (status mask)
8) NOT       (invert first value only)
9) EXIT
Choose an option (1-9): 1
Enter first single digit (0-9): 7
Enter second single digit (0-9): 3
Result: 10

=== Prepaid Meter ALU Simulator ===
...
Choose an option (1-9): 9
Shutting down ALU simulator.
```

## Test Cases

| # | Operation | Input | Expected | Got | Notes |
|---|---|---|---|---|---|
| 1 | ADD | 7, 3 | 10 | 10 | |
| 2 | SUBTRACT | 7, 3 | 4 | 4 | |
| 3 | SUBTRACT | 3, 7 | -4 | -4 | Negative result, signed printing |
| 4 | MULTIPLY | 7, 3 | 21 | 21 | |
| 5 | DIVIDE | 9, 3 | 3 | 3 | |
| 6 | DIVIDE | 9, 0 | error message | error message | Division by zero caught before `div` executes |
| 7 | AND | 6, 3 | 2 | 2 | |
| 8 | OR | 6, 3 | 7 | 7 | |
| 9 | XOR | 6, 3 | 5 | 5 | |
| 10 | NOT | 5 | 250 | 250 | `NOT` on a single byte: `~00000101 = 11111010` |
| 11 | Invalid menu choice | `x` | rejected, re-prompts | rejected, re-prompts | |
| 12 | Invalid digit | `x` | rejected, re-prompts | rejected, re-prompts | |

All cases were run directly against the built `alu` executable and the
printed output matched the expected value exactly.

## A Note on a Bug We Found and Fixed

An early version of this program had a genuine bug worth recording, since
the brief asks the group to understand register usage deeply: the menu
choice was read into `al`, but then **`al` was immediately overwritten**
by the calls to read the two operands (since `read_operand1` /
`read_operand2` also return their digit value in `al`). By the time the
program checked "which operation did the user choose?", `al` no longer
held the menu choice — it held the second operand's value instead.

This caused, for example, choosing ADD with inputs 7 and 3 to silently
execute MULTIPLY instead (7 × 3 = 21), because the comparison chain was
testing the leftover value `3` against `cmp al, 1`, `cmp al, 2`, `cmp al,
3`... and matching option 3 (MULTIPLY) instead of option 1 (ADD).

**Fix:** the menu choice is now saved to a dedicated memory location
(`menu_choice` in `.bss`) immediately after it is read, and reloaded into
`al` right before each comparison that depends on it. This is a direct,
real-world illustration of why register contents cannot be assumed to
survive a `call` unless the callee is known to preserve them, or the value
is saved somewhere safe first.

## Debugging & Flag Inspection Evidence

See `technical_note.md` for the full flag analysis table. Example GDB
session used to capture flag state after the ADD operation:

```bash
make debug
gdb ./alu_dbg
```

```
(gdb) break op_add
(gdb) run
7
3
(gdb) stepi 3
(gdb) info registers eflags
(gdb) print $rax
```

> **Screenshot placeholder:** Insert screenshots of GDB sessions for each
> of the six+ tested operations here, as required by the deliverable
> "Screenshots of register and flag inspection."

## Validation & Overflow Discussion

- **Divide by zero** is checked explicitly with `cmp rbx, 0` / `je
  .div_zero` *before* the `div` instruction executes — letting the CPU
  execute `div` with a zero divisor would raise a `SIGFPE` and crash the
  program, so the check must happen first.
- **Invalid menu choices and invalid digits** are validated by range
  checks (`cmp`/`jl`/`jg`) immediately after reading input, with a clear
  error message and a re-prompt, rather than letting bad input flow into
  arithmetic.
- **Overflow**: with single-digit inputs (0–9), `ADD` and `SUBTRACT` can
  never overflow a 64-bit register, and `MULTIPLY` of two single digits
  (max 9 × 9 = 81) never overflows either. The program still includes an
  overflow check after `MULTIPLY` (`cmp rdx, 0` after `mul`, since `mul`
  places any overflow into `rdx`) so the logic is correct and would catch
  genuine overflow if larger operand ranges were used in a future version.
  This matters in real billing systems because silently wrapping a balance
  or usage figure on overflow could under- or over-charge a customer.

## Deliverables Checklist

- [x] `alu.asm` — ALU simulator source code reading input via Linux syscalls
- [x] `Makefile` — build automation
- [x] README with setup, usage, test cases, and bug-fix notes
- [x] Flag analysis table with more than six tested operations (`technical_note.md`)
- [ ] Screenshots of register and flag inspection (to be added by group — see placeholder above)
- [x] Discussion on why overflow matters in real systems
- [x] Validation for invalid menu choices and division by zero
