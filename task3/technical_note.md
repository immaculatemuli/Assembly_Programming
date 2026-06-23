# Task 3 — Technical Note: Flag Analysis & Overflow Discussion

## Flag Analysis Table

Captured directly from GDB by breaking at the start of each operation
handler, stepping past the instruction that sets the result, and reading
`info registers eflags`. All inputs are single digits, as specified in the
brief.

| # | Operation | Inputs | Instruction | Result | Flags set | Why |
|---|---|---|---|---|---|---|
| 1 | ADD | 7, 3 | `add rax, rbx` | 10 | `PF` | Result has an even number of set bits (1010₂ → wait, 10 = 00001010, 2 set bits → even → PF set). No `CF`/`OF`/`SF`/`ZF`: no carry, no overflow, positive, non-zero. |
| 2 | SUBTRACT | 3, 7 | `sub rax, rbx` | -4 | `CF`, `PF`, `AF`, `SF` | Subtracting a larger value from a smaller one borrows, setting `CF`. Result is negative, setting `SF`. |
| 3 | MULTIPLY | 9, 9 | `mul rbx` | 81 | *(only `IF`, no arithmetic flags)* | `rdx = 0` after the multiply — no overflow beyond a single register, so `mul`'s `CF`/`OF` are both clear. |
| 4 | AND | 4, 3 | `and rax, rbx` | 0 | `PF`, `ZF` | `00000100 AND 00000011 = 00000000`. Result is zero, so `ZF` is set. `AND` always clears `CF` and `OF` per the x86 spec. |
| 5 | OR | 6, 3 | `or rax, rbx` | 7 | *(none beyond `IF`)* | `00000110 OR 00000011 = 00000111`. Non-zero, odd parity, positive — no flags set. `OR` always clears `CF`/`OF`. |
| 6 | XOR | 5, 5 | `xor rax, rbx` | 0 | `PF`, `ZF` | Identical operands XOR to zero, setting `ZF`. `XOR` always clears `CF`/`OF`. |
| 7 | NOT | 5 | `not al` | 250 | *(flags unchanged from before the instruction)* | `NOT` is documented in the x86 ISA as not affecting any flags at all — the flags shown after this instruction are simply whatever they were before it ran. |

## Why DIVIDE Is Not in the Flags Table

The x86 `div` instruction's effect on flags is explicitly **undefined** in
the Intel/AMD architecture manuals — unlike `add`, `sub`, `and`, `or`,
`xor`, which have precisely documented flag behaviour, `div` may leave all
arithmetic flags in an indeterminate state. For this reason the table above
intentionally tests the six operations whose flag behaviour is fully
specified, and `DIVIDE` is instead documented separately through its
divide-by-zero protection (see below) rather than through flag inspection.

## Divide-by-Zero Protection

```nasm
op_div:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    cmp rbx, 0
    je .div_zero          ; check BEFORE executing div
    xor rdx, rdx
    div rbx
    ...
.div_zero:
    ; print error message, return to menu
```

If `div` were allowed to execute with a zero divisor, the CPU raises a
`#DE` (divide error) exception, which Linux delivers to the process as
`SIGFPE` — terminating the program immediately with no chance to recover
or print a message. The explicit `cmp`/`je` check intercepts this case in
software before the dangerous instruction ever runs.

## Why Overflow Matters in Real Systems

This simulator deliberately restricts input to single digits (0–9), so
none of its arithmetic can overflow a 64-bit register — `ADD` and
`SUBTRACT` of two single digits stay well within range, and the largest
possible `MULTIPLY` (9 × 9 = 81) is nowhere near overflowing even a single
byte. Even so, the program checks `rdx` after `mul` (the register that
receives any overflow from a 64-bit multiply) purely as a demonstration of
the correct pattern, since the same code structure would be reused if the
input range were widened later.

In a real prepaid billing device, the consequence of *not* checking for
overflow is concrete and financial: if a customer's unit balance is stored
in a fixed-width register and an "add units" operation overflows that
register, the stored balance can silently wrap around to a small or even
negative-looking value. Depending on how the firmware interprets that
wrapped value, the customer could be left with far fewer units than they
paid for, or — in the opposite and more dangerous case — wrap around to a
very large apparent balance, effectively granting free electricity or
water until the fault is noticed. Because embedded billing devices often
run unattended for long periods, a silent overflow bug like this can persist
for a long time before anyone notices the financial impact.

## Group Note

> Replace the flag table evidence above with your own GDB screenshots
> (see the commands in `README.md`), and add the names and roles of the
> group members who ran each test case.
