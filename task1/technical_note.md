# Technical Note: Data Representation in Computer Systems
## BIT 4220 Assembly Programming — Group Work Session 1, Task 1
**Date:** June 2026 | **Target Audience:** First-year IT students

---

## 1. Introduction

When a CPU processes information, it does not understand words, images, or
numbers the way humans do. Everything inside a computer — from a letter you type
to a price in a billing system — is stored and manipulated as a sequence of
**binary digits (bits)**. Understanding how data is represented at this level is
the foundation of assembly programming, reverse engineering, digital forensics,
and embedded systems development.

This note explains five key representation schemes: binary, hexadecimal, ASCII,
two's complement, and little-endian storage.

---

## 2. Binary Representation

A **bit** is the smallest unit of data in a computer — it holds either a 0 or a 1.
Eight bits form a **byte**, which is the standard unit for measuring data sizes
in assembly programming.

In binary (base-2), each digit position represents a power of 2:

```
Bit position:  7    6    5    4    3    2    1    0
Place value:  128   64   32   16    8    4    2    1

Example — the number 65:
  65 = 64 + 1 = 01000001 in binary
```

In NASM assembly, you can write binary literals with the `b` suffix:

```nasm
mov al, 01000001b   ; load 65 (decimal) into register AL
```

Binary is significant because CPU logic gates operate on individual bits, and
understanding binary is essential for tasks like reading status registers,
decoding network packets, and analysing malware.

---

## 3. Hexadecimal Representation

Binary numbers become long and hard to read quickly. **Hexadecimal (base-16)**
is a compact alternative where each hex digit represents exactly 4 bits:

| Decimal | Binary | Hex |
|---------|--------|-----|
| 0       | 0000   | 0   |
| 9       | 1001   | 9   |
| 10      | 1010   | A   |
| 15      | 1111   | F   |
| 65      | 01000001 | 41 |
| 255     | 11111111 | FF |

A byte (8 bits) always maps to exactly **two hex digits**, making hex the
preferred notation in debuggers, memory dumps, and exploit analysis.

In NASM, hex literals are prefixed with `0x` or suffixed with `h`:

```nasm
mov al, 0x41        ; load 65 (the letter 'A') into AL
mov bx, 0xFF00      ; load a 16-bit word into BX
```

When reading a memory dump in GDB or a forensic tool, you will see rows of hex
values representing raw bytes. Recognising common patterns — such as `0x41`
through `0x5A` for uppercase letters, or `0x7F 0x45 0x4C 0x46` as the ELF file
magic number — is an essential skill.

---

## 4. ASCII Encoding

**ASCII (American Standard Code for Information Interchange)** assigns a
numeric code between 0 and 127 to each printable character and several
control codes. Since these values fit in 7 bits (one byte), ASCII characters
are stored as single bytes in memory.

| Character | Decimal | Hex  | Binary   |
|-----------|---------|------|----------|
| 'A'       | 65      | 0x41 | 01000001 |
| 'B'       | 66      | 0x42 | 01000010 |
| 'a'       | 97      | 0x61 | 01100001 |
| '0'       | 48      | 0x30 | 00110000 |
| newline   | 10      | 0x0A | 00001010 |
| space     | 32      | 0x20 | 00100000 |

A useful pattern: lowercase letters are exactly 32 (0x20) more than their
uppercase equivalents. This means toggling bit 5 of a byte converts between
upper and lowercase — a trick commonly used in both optimisation and obfuscation.

In our `data_demo.asm` program, the string `"ABCDE"` is stored in memory as
the five consecutive bytes: `41 42 43 44 45` (hex). The CPU does not know
these are letters — it only sees bytes. The terminal interprets them as
characters when they are printed.

---

## 5. Two's Complement

Computers need to represent **negative integers** as well as positive ones.
The dominant method on all modern CPUs (including x86-64) is **two's complement**.

For an n-bit number:

1. Positive numbers are stored in standard binary.
2. To find the negative of a number: **flip all bits, then add 1**.

**Example — representing −5 in 8 bits:**

```
Step 1: Write +5 in binary    →  00000101
Step 2: Flip all bits          →  11111010
Step 3: Add 1                  →  11111011   ← this is −5
```

Verification: adding +5 and −5 should equal 0:

```
  00000101  (+5)
+ 11111011  (−5)
──────────
 100000000  → the 9th carry bit is dropped → result = 00000000 = 0 ✓
```

Two's complement is why the `IDIV` (signed divide) and `IMUL` (signed multiply)
instructions exist alongside their unsigned counterparts `DIV` and `MUL` in
x86 assembly. It also explains why the **sign flag (SF)** and **overflow flag (OF)**
in the CPU flags register are critical for detecting arithmetic errors in signed
arithmetic.

---

## 6. Little-Endian Memory Storage

When a multi-byte value (such as a 32-bit integer) is stored in memory, there
are two possible orderings for its bytes:

- **Big-endian:** Most significant byte stored at the lowest address (network byte order).
- **Little-endian:** Least significant byte stored at the lowest address (x86/x64 default).

**Example — storing 0x12345678 at address 0x1000:**

| Address | Big-endian | Little-endian |
|---------|-----------|---------------|
| 0x1000  | 0x12      | 0x78          |
| 0x1001  | 0x34      | 0x56          |
| 0x1002  | 0x56      | 0x34          |
| 0x1003  | 0x78      | 0x12          |

All x86 and x86-64 processors (your PC or WSL environment) use **little-endian**
storage. This means that when NASM stores:

```nasm
word_val  dw  0x4142    ; stored in memory as: 42 41
dword_val dd  0x41424344 ; stored as: 44 43 42 41
```

This matters enormously in reverse engineering and forensics: when examining a
memory dump, you must read multi-byte values in reverse byte order compared to
how they appear in source code.

---

## 7. Practical Relevance

| Application | Concept Used |
|-------------|-------------|
| Reverse engineering binaries | Hex + ASCII to read strings from executables |
| Exploit development | Endianness when injecting return addresses |
| Network forensics | Big-endian IP/port headers vs little-endian host values |
| Firmware analysis | Direct binary/hex reading of device memory |
| Cryptography (bitwise ops) | XOR and bit masking on raw bytes |
| Debugging integer bugs | Two's complement overflow detection |

---

## 8. Conclusion

Binary, hexadecimal, ASCII, two's complement, and little-endian storage are not
merely academic concepts. They are the language that the CPU uses internally.
Every security researcher, firmware developer, and systems programmer must be
able to read memory dumps in hex, mentally convert between representations, and
know how signed arithmetic behaves at the bit level. The programs in this project
demonstrate these concepts running directly on real hardware with no abstractions.

---

*BIT 4220 Group Work Session 1 | Submitted: 10 June 2026*
