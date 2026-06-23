; ============================================================
; BIT 4220 - Task 3: Mini Arithmetic Logic Unit for an
;            Embedded Billing Device
;
; A menu-driven ALU simulator for a prepaid utility meter.
; Reads two single-digit numbers via Linux system calls and
; performs arithmetic (add/subtract/multiply/divide) and
; bitwise/logical operations (AND/OR/XOR/NOT) used to model
; device-status bit masks.
;
; Build (Linux/WSL Ubuntu):
;   nasm -f elf64 alu.asm -o alu.o
;   ld alu.o -o alu
;   ./alu
; ============================================================

section .data
    menu        db 10, "=== Prepaid Meter ALU Simulator ===", 10
                db "1) ADD       (add units)", 10
                db "2) SUBTRACT  (subtract usage)", 10
                db "3) MULTIPLY  (multiply rate)", 10
                db "4) DIVIDE    (divide balance)", 10
                db "5) AND       (status mask)", 10
                db "6) OR        (status mask)", 10
                db "7) XOR       (status mask)", 10
                db "8) NOT       (invert first value only)", 10
                db "9) EXIT", 10
                db "Choose an option (1-9): ", 0
    menu_len    equ $ - menu - 1   ; -1 to exclude the trailing 0 byte

    prompt1     db "Enter first single digit (0-9): ", 0
    prompt1_len equ $ - prompt1 - 1
    prompt2     db "Enter second single digit (0-9): ", 0
    prompt2_len equ $ - prompt2 - 1

    msg_result  db "Result: ", 0
    msg_invalid_menu db "Invalid menu choice. Please enter 1-9.", 10, 0
    msg_invalid_digit db "Invalid input: please enter a single digit 0-9.", 10, 0
    msg_divzero db "Error: division by zero is not allowed.", 10, 0
    msg_overflow db "Note: result exceeded expected range (overflow case).", 10, 0
    msg_bye     db "Shutting down ALU simulator.", 10, 0
    msg_neg     db "-", 0

    newline     db 10, 0

section .bss
    inbuf       resb 4          ; scratch buffer for sys_read (menu choice / digit)
    menu_choice resb 1          ; preserved menu choice (1-9), since al gets clobbered
    val1        resb 1          ; first operand (binary value, not ASCII)
    val2        resb 1          ; second operand (binary value, not ASCII)
    result      resq 1          ; result stored as signed 64-bit to allow negatives
    numbuf      resb 24         ; scratch buffer for printing numbers

section .text
global _start

_start:
main_loop:
    call print_menu
    call read_menu_choice       ; returns choice (1-9) in al, or 0 if invalid
    mov [menu_choice], al        ; save choice immediately - al gets clobbered
                                  ; by the operand-reading calls below

    cmp al, 0
    je .invalid_choice
    cmp al, 9
    je do_exit

    ; ---- read the two operands (skipped for NOT, which only needs one) ----
    call read_operand1
    cmp byte [val1], 255         ; sentinel for "invalid digit entered"
    je main_loop

    mov al, [menu_choice]         ; restore choice (read_operand1 clobbered al)
    cmp al, 8                   ; NOT only needs one operand
    je .have_operands

    call read_operand2
    cmp byte [val2], 255
    je main_loop

.have_operands:
    mov al, [menu_choice]         ; restore choice again (read_operand2 clobbered al)
    cmp al, 1
    je op_add
    cmp al, 2
    je op_sub
    cmp al, 3
    je op_mul
    cmp al, 4
    je op_div
    cmp al, 5
    je op_and
    cmp al, 6
    je op_or
    cmp al, 7
    je op_xor
    cmp al, 8
    je op_not
    jmp main_loop

.invalid_choice:
    mov rsi, msg_invalid_menu
    mov rdx, 39
    call print_buf
    jmp main_loop

; ============================================================
; Arithmetic operations
; ============================================================
op_add:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    add rax, rbx                ; flags set here: CF/OF/ZF/SF reflect this add
    mov [result], rax
    call print_result_signed
    jmp main_loop

op_sub:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    sub rax, rbx                 ; flags set here: SF set if val1 < val2 (negative result)
    mov [result], rax
    call print_result_signed
    jmp main_loop

op_mul:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    mul rbx                      ; unsigned multiply; flags: OF/CF set if rdx != 0
    mov [result], rax
    cmp rdx, 0
    jne .mul_overflow
    call print_result_signed
    jmp main_loop
.mul_overflow:
    call print_result_signed
    mov rsi, msg_overflow
    mov rdx, 56
    call print_buf
    jmp main_loop

op_div:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    cmp rbx, 0
    je .div_zero
    xor rdx, rdx
    div rbx                       ; flags after DIV are undefined per spec, but
                                  ; ZF/SF on the quotient check below are well-defined
    mov [result], rax
    call print_result_signed
    jmp main_loop
.div_zero:
    mov rsi, msg_divzero
    mov rdx, 41
    call print_buf
    jmp main_loop

; ============================================================
; Logical / bitwise operations (device-status bit masks)
; ============================================================
op_and:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    and rax, rbx                 ; flags: ZF set if result is 0, OF/CF always cleared
    mov [result], rax
    call print_result_signed
    jmp main_loop

op_or:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    or rax, rbx                  ; flags: ZF set if result is 0, OF/CF always cleared
    mov [result], rax
    call print_result_signed
    jmp main_loop

op_xor:
    movzx rax, byte [val1]
    movzx rbx, byte [val2]
    xor rax, rbx                 ; flags: ZF set if both operands equal
    mov [result], rax
    call print_result_signed
    jmp main_loop

op_not:
    movzx rax, byte [val1]
    not al                       ; NOT does not affect any flags
    movzx rax, al
    mov [result], rax
    call print_result_signed
    jmp main_loop

do_exit:
    mov rsi, msg_bye
    mov rdx, 30
    call print_buf
    mov rax, 60
    xor rdi, rdi
    syscall

; ============================================================
; print_menu: prints the full menu text
; ============================================================
print_menu:
    mov rsi, menu
    mov rdx, menu_len
    call print_buf
    ret

; ============================================================
; read_menu_choice: reads one line from stdin, validates it
; is a single digit '1'-'9'.
; Returns: al = numeric choice (1-9), or al = 0 if invalid.
; ============================================================
read_menu_choice:
    push rdx
    push rsi
    push rdi
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; fd = stdin
    mov rsi, inbuf
    mov rdx, 1                  ; read exactly 1 byte (the choice digit)
    syscall

    cmp rax, 0                  ; EOF or read error
    jle .eof

    mov al, [inbuf]
    cmp al, '1'
    jl .bad
    cmp al, '9'
    jg .bad
    sub al, '0'                 ; convert ASCII digit to binary value
    call consume_rest_of_line
    jmp .done
.eof:
    mov al, 9                   ; treat EOF as "exit" so the program terminates cleanly
    jmp .done
.bad:
    call consume_rest_of_line
    mov al, 0
.done:
    pop rdi
    pop rsi
    pop rdx
    ret

; ============================================================
; read_operand1 / read_operand2: prompt and read a single
; digit 0-9 from stdin into val1 / val2.
; On invalid input, stores 255 as a sentinel and prints a
; message; caller checks for this sentinel.
; ============================================================
read_operand1:
    mov rsi, prompt1
    mov rdx, prompt1_len
    call print_buf
    call read_single_digit
    mov [val1], al
    ret

read_operand2:
    mov rsi, prompt2
    mov rdx, prompt2_len
    call print_buf
    call read_single_digit
    mov [val2], al
    ret

; ============================================================
; read_single_digit: reads one line from stdin, validates it
; is exactly one digit character 0-9.
; Returns: al = digit value (0-9), or al = 255 if invalid
; (and prints an error message in that case).
; ============================================================
read_single_digit:
    push rdx
    push rsi
    push rdi
    mov rax, 0
    mov rdi, 0
    mov rsi, inbuf
    mov rdx, 1                  ; read exactly 1 byte
    syscall

    cmp rax, 0
    jle .bad                    ; EOF treated as invalid input

    mov al, [inbuf]
    cmp al, '0'
    jl .bad
    cmp al, '9'
    jg .bad
    sub al, '0'
    call consume_rest_of_line
    jmp .done
.bad:
    call consume_rest_of_line
    pop rdi
    pop rsi
    pop rdx
    mov rsi, msg_invalid_digit
    mov rdx, 49
    push rsi
    push rdx
    call print_buf
    pop rdx
    pop rsi
    mov al, 255
    ret
.done:
    pop rdi
    pop rsi
    pop rdx
    ret

; ============================================================
; consume_rest_of_line: reads and discards bytes from stdin
; one at a time until a newline or EOF is seen. Used after
; reading a single digit so the trailing '\n' doesn't leak
; into the next read.
; ============================================================
consume_rest_of_line:
    push rax
    push rdx
    push rsi
    push rdi
.loop:
    mov rax, 0
    mov rdi, 0
    mov rsi, inbuf
    mov rdx, 1
    syscall
    cmp rax, 0
    jle .done                   ; EOF
    cmp byte [inbuf], 10        ; '\n'
    je .done
    jmp .loop
.done:
    pop rdi
    pop rsi
    pop rdx
    pop rax
    ret

; ============================================================
; print_buf: prints rdx bytes starting at rsi (sys_write)
; ============================================================
print_buf:
    push rax
    push rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    pop rax
    ret

; ============================================================
; print_result_signed: prints "Result: " followed by the
; signed 64-bit value in [result], then a newline.
; ============================================================
print_result_signed:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rsi, msg_result
    mov rdx, 8
    call print_buf

    mov rax, [result]
    test rax, rax
    jns .positive
    mov rsi, msg_neg
    mov rdx, 1
    call print_buf
    neg rax
.positive:
    mov rdi, numbuf + 23
    mov byte [rdi], 0
    mov rbx, 10

    test rax, rax
    jnz .conv_loop
    dec rdi
    mov byte [rdi], '0'
    jmp .print_it
.conv_loop:
    test rax, rax
    jz .print_it
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    jmp .conv_loop
.print_it:
    mov rsi, rdi
    mov rdi, numbuf + 23
    sub rdi, rsi
    mov rdx, rdi
    call print_buf

    mov rsi, newline
    mov rdx, 1
    call print_buf

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
