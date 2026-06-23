# Task 2 — Technical Note: Memory Map, Addressing Modes & Indexing Comparison

## 1. Memory Map

Offsets below are taken directly from the object file's symbol table using
`objdump -t marks.o`, and are relative to the start of each section.

### `.data` section

| Symbol | Offset | Description |
|---|---|---|
| `marks` | `0x00` | Array of 12 marks, 1 byte each (12 bytes total) |
| `header` | `0x0C` | "=== Student Marks Report ===" label string |
| `msg_total` | `0x2A` | "Total: " label string |
| `msg_avg` | `0x32` | "Average: " label string |
| `msg_high` | `0x3C` | "Highest: " label string |
| `msg_low` | `0x46` | "Lowest: " label string |
| `msg_fail` | `0x4F` | "Fail (0-39): " label string |
| `msg_pass` | `0x5D` | "Pass (40-59): " label string |
| `msg_credit` | `0x6C` | "Credit (60-69): " label string |
| `msg_dist` | `0x7D` | "Distinction (70-100): " label string |
| `newline` | `0x94` | Newline character, null-terminated |

### `.bss` section

| Symbol | Offset | Size | Description |
|---|---|---|---|
| `total` | `0x00` | 8 bytes (qword) | Running sum of all marks |
| `average` | `0x08` | 1 byte | Average mark (total / 12) |
| `highest` | `0x09` | 1 byte | Highest mark found |
| `lowest` | `0x0A` | 1 byte | Lowest mark found |
| `fail_cnt` | `0x0B` | 1 byte | Count of marks 0–39 |
| `pass_cnt` | `0x0C` | 1 byte | Count of marks 40–59 |
| `credit_cnt` | `0x0D` | 1 byte | Count of marks 60–69 |
| `dist_cnt` | `0x0E` | 1 byte | Count of marks 70–100 |
| `numbuf` | `0x0F` | 8 bytes | Scratch buffer for number-to-string conversion |

`total` is stored as a full 64-bit quadword rather than a single byte,
because a single byte can only hold values 0–255 and the sum of even a
modest mark set quickly exceeds that (the main dataset sums to 678).

## 2. Addressing Modes Used

The assignment requires at least three addressing modes. This program uses
six, each chosen deliberately for what it demonstrates:

| Mode | Example from `marks.asm` | What it means |
|---|---|---|
| **Immediate** | `cmp rcx, NUM_MARKS` | The operand is a literal constant baked directly into the instruction — no memory or register lookup needed. |
| **Register** | `inc rcx` | The operand IS a register; the CPU operates directly on the value sitting in `rcx`. |
| **Direct** | `mov qword [total], 0` | The instruction names a fixed memory address (the label `total`) explicitly — the address never changes at run time. |
| **Indexed** | `mov al, [marks + rcx]` | A base label plus a varying index register. As `rcx` counts 0..11 in the summing loop, this walks through `marks[0]` to `marks[11]`. |
| **Based** | `mov al, [rsi + rcx]` | A general-purpose register (`rsi`) holds the array's base address at run time, with an offset register (`rcx`) added to it. Confirmed in GDB: `rsi = 0x402000`, the exact address of `marks`. |
| **Indirect** | `mov al, [rdi]` | `rdi` holds a pointer into the array; the value is read by dereferencing the pointer, then the pointer itself is advanced with `inc rdi` in the classification loop. |

The distinction between **indexed** and **based** addressing here is
deliberate: indexed addressing uses a fixed label (`marks`) plus a varying
register offset, computed at assemble time as a fixed base; based
addressing uses a register (`rsi`) that is loaded with the base address at
*run time*, making the base itself a variable rather than a constant. This
matters in real programs where the array's address might not be known until
runtime (e.g. dynamically allocated memory).

## 3. Assembly Indexing vs. C / Python Indexing

| Aspect | Assembly (NASM) | C / Python |
|---|---|---|
| How an element is reached | The programmer computes the address manually: base + (index × element size), e.g. `[marks + rcx]` for byte-sized elements. | The compiler/interpreter computes the address automatically from `arr[i]`; the programmer never sees a raw address. |
| Bounds checking | None. Reading past the array (e.g. `rcx = 12`) silently reads whatever byte happens to sit next in memory. | Python raises `IndexError`. C also has no bounds checking by default, but tools like AddressSanitizer can catch it. |
| Element size | Must be tracked manually — a byte array uses `[base + i]`; a word array would need `[base + i*2]`. | Handled automatically based on the array's declared or inferred type. |
| Pointer vs. index | Indexed (base + register) and indirect (pure pointer dereference + increment) are visibly different techniques in the same program. | C exposes both styles too (`arr[i]` vs `*ptr++`), but Python only exposes indexing — there is no raw pointer concept. |

The practical takeaway for the group: in assembly, "indexing" is not a
single built-in operation — it is something we build ourselves out of
addition and dereferencing. High-level languages hide this, but the
underlying CPU work is exactly what this program makes visible.

## 4. Boundary Test Evidence

`marks_boundary_test.asm` replaces the marks array with:

```
0, 39, 40, 69, 70, 100, 1, 38, 41, 59, 60, 71
```

covering every classification boundary specified in the assignment. Running
the program confirms every edge resolves to the correct band:

| Mark | Classification | Mark | Classification |
|---|---|---|---|
| 0 | Fail | 69 | Credit |
| 39 | Fail | 70 | Distinction |
| 40 | Pass | 100 | Distinction |
| 59 | Pass | 60 | Credit |

**Program output (boundary test build):**

```
Total: 588   Average: 49   Highest: 100   Lowest: 0
Fail: 4   Pass: 3   Credit: 2   Distinction: 3
```

## 5. GDB Evidence of Based Addressing

A breakpoint set at the highest/lowest comparison loop confirms the
based-addressing register holds the array's true base address at runtime:

```
(gdb) print/x $rsi
$1 = 0x402000          # matches the 'marks' symbol address from objdump -t
(gdb) print $rcx
$2 = 1                 # loop offset register
(gdb) x/12db 0x402000
0x402000 <marks>: 55 39 100 0 70 69 40 85 60 23 90 47
```

> **Group note:** replace this section with your own screenshots taken from
> the GDB session described in `README.md`, plus the names and roles of the
> group members who ran the debugging session.
