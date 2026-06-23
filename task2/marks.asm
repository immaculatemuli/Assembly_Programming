; ============================================================
; BIT 4220 - Task 2: Student Marks Processor
; Using Registers and Addressing Modes
;
; Demonstrates: immediate, register, direct, indirect,
;               indexed, and based addressing modes
;
; Computes: total, average, highest, lowest mark
; Classifies each mark into: Fail (0-39), Pass (40-59),
;               Credit (60-69), Distinction (70-100)
;
; Build (Linux/WSL Ubuntu):
;   nasm -f elf64 marks.asm -o marks.o
;   ld marks.o -o marks
;   ./marks
; ============================================================

section .data
    ; ---- DIRECT ADDRESSING: each label below IS a memory
    ; address. Referring to `marks` directly is direct addressing.
    marks       db 55, 39, 100, 0, 70, 69, 40, 85, 60, 23, 90, 47
    NUM_MARKS   equ 12          ; count of marks (constant, not memory)

    header      db "=== Student Marks Report ===", 10, 0
    msg_total   db "Total: ", 0
    msg_avg     db "Average: ", 0
    msg_high    db "Highest: ", 0
    msg_low     db "Lowest: ", 0
    msg_fail    db "Fail (0-39): ", 0
    msg_pass    db "Pass (40-59): ", 0
    msg_credit  db "Credit (60-69): ", 0
    msg_dist    db "Distinction (70-100): ", 0
    newline     db 10, 0

section .bss
    total       resq 1          ; sum of all marks (use qword to avoid overflow)
    average     resb 1
    highest     resb 1
    lowest      resb 1
    fail_cnt    resb 1
    pass_cnt    resb 1
    credit_cnt  resb 1
    dist_cnt    resb 1
    numbuf      resb 8          ; scratch buffer for printing numbers

section .text
global _start

_start:
    ; ---------------------------------------------------------
    ; Step 1: compute TOTAL using a loop (INDEXED ADDRESSING)
    ; ---------------------------------------------------------
    mov qword [total], 0        ; DIRECT addressing: write straight to the
                                 ; named memory location `total`
    mov rcx, 0                  ; rcx = loop index i, starts at 0 (IMMEDIATE)
sum_loop:
    cmp rcx, NUM_MARKS           ; IMMEDIATE addressing: compare against
                                  ; the literal constant NUM_MARKS
    jge sum_done
    mov al, [marks + rcx]        ; INDEXED addressing: base label (marks)
                                  ; + index register (rcx) -> marks[i]
    movzx rax, al
    add [total], rax             ; accumulate into memory directly
    inc rcx                      ; REGISTER addressing: operate on rcx itself
    jmp sum_loop
sum_done:

    ; ---------------------------------------------------------
    ; Step 2: AVERAGE = total / NUM_MARKS (integer division)
    ; ---------------------------------------------------------
    mov rax, [total]
    xor rdx, rdx
    mov rbx, NUM_MARKS
    div rbx                      ; rax = quotient (average), rdx = remainder
    mov [average], al

    ; ---------------------------------------------------------
    ; Step 3: find HIGHEST and LOWEST using BASED addressing
    ; (a base register holding the array's start address,
    ;  dereferenced with an offset register added to it)
    ; ---------------------------------------------------------
    mov rsi, marks                ; rsi = BASE register, holds array start
    mov al, [rsi]                 ; first mark seeds both highest & lowest
    mov [highest], al
    mov [lowest], al
    mov rcx, 1                    ; start comparing from index 1

minmax_loop:
    cmp rcx, NUM_MARKS
    jge minmax_done
    mov al, [rsi + rcx]            ; BASED addressing: base (rsi) + offset (rcx)
    cmp al, [highest]
    jle .not_high
    mov [highest], al
.not_high:
    cmp al, [lowest]
    jge .not_low
    mov [lowest], al
.not_low:
    inc rcx
    jmp minmax_loop
minmax_done:

    ; ---------------------------------------------------------
    ; Step 4: classify each mark using INDIRECT addressing
    ; (register holds a pointer, dereferenced with [reg])
    ; ---------------------------------------------------------
    mov byte [fail_cnt], 0
    mov byte [pass_cnt], 0
    mov byte [credit_cnt], 0
    mov byte [dist_cnt], 0

    mov rdi, marks                 ; rdi = pointer into the array
    mov rcx, 0
classify_loop:
    cmp rcx, NUM_MARKS
    jge classify_done
    mov al, [rdi]                  ; INDIRECT addressing: [rdi] dereferences
                                    ; the pointer rdi currently holds
    cmp al, 40
    jl .is_fail
    cmp al, 60
    jl .is_pass
    cmp al, 70
    jl .is_credit
    inc byte [dist_cnt]
    jmp .next
.is_fail:
    inc byte [fail_cnt]
    jmp .next
.is_pass:
    inc byte [pass_cnt]
    jmp .next
.is_credit:
    inc byte [credit_cnt]
.next:
    inc rdi                        ; advance the pointer itself (indirect style)
    inc rcx
    jmp classify_loop
classify_done:

    ; ---------------------------------------------------------
    ; Step 5: print the report
    ; ---------------------------------------------------------
    call print_header
    call print_total
    call print_average
    call print_highest
    call print_lowest
    call print_fail
    call print_pass
    call print_credit
    call print_dist

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

; ============================================================
; print_string: prints a null-terminated string
; expects address in rsi
; ============================================================
print_string:
    push rax
    push rdi
    push rdx
    push rsi
    mov rdi, rsi
    xor rdx, rdx
.strlen:
    cmp byte [rdi], 0
    je .strlen_done
    inc rdi
    inc rdx
    jmp .strlen
.strlen_done:
    mov rax, 1          ; sys_write
    mov rdi, 1          ; fd = stdout
    pop rsi             ; restore string pointer as buffer arg
    push rsi
    syscall
    pop rsi
    pop rdx
    pop rdi
    pop rax
    ret

; ============================================================
; print_num: prints the unsigned byte value in al as decimal
; (used for average, highest, lowest, classification counts -
;  all guaranteed to fit in 0-255)
; ============================================================
print_num:
    push rax
    movzx rax, al
    call print_num64
    pop rax
    ret

; ============================================================
; print_num64: prints the unsigned 64-bit value in rax as decimal
; (used for the running total, which can exceed 255)
; ============================================================
print_num64:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, numbuf + 7
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
    call print_string

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; ============================================================
; Output helper procedures
; ============================================================
print_header:
    mov rsi, header
    call print_string
    ret

print_total:
    mov rsi, msg_total
    call print_string
    mov rax, [total]
    call print_num64
    mov rsi, newline
    call print_string
    ret

print_average:
    mov rsi, msg_avg
    call print_string
    mov al, [average]
    call print_num
    mov rsi, newline
    call print_string
    ret

print_highest:
    mov rsi, msg_high
    call print_string
    mov al, [highest]
    call print_num
    mov rsi, newline
    call print_string
    ret

print_lowest:
    mov rsi, msg_low
    call print_string
    mov al, [lowest]
    call print_num
    mov rsi, newline
    call print_string
    ret

print_fail:
    mov rsi, msg_fail
    call print_string
    mov al, [fail_cnt]
    call print_num
    mov rsi, newline
    call print_string
    ret

print_pass:
    mov rsi, msg_pass
    call print_string
    mov al, [pass_cnt]
    call print_num
    mov rsi, newline
    call print_string
    ret

print_credit:
    mov rsi, msg_credit
    call print_string
    mov al, [credit_cnt]
    call print_num
    mov rsi, newline
    call print_string
    ret

print_dist:
    mov rsi, msg_dist
    call print_string
    mov al, [dist_cnt]
    call print_num
    mov rsi, newline
    call print_string
    ret
