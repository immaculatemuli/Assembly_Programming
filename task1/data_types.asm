; ============================================================
; data_types.asm
; BIT 4220 - Task 1: Digital Representation Toolkit
; Purpose: Demonstrate storage of byte, word and doubleword
;          sized data, show their ASCII interpretation where
;          appropriate, and illustrate little-endian storage
;          and two's complement representation.
; ============================================================

section .data
    ; --- byte, word, doubleword storage ---
    my_byte   db 0x41              ; 1 byte  -> 'A'
    my_word   dw 0x4243            ; 2 bytes -> stored as 43 42 (little-endian)
    my_dword  dd 0x44454647        ; 4 bytes -> stored as 47 46 45 44 (little-endian)

    ; --- two's complement example ---
    pos_val   dd 5                 ; +5  -> 00000005
    neg_val   dd -5                ; -5  -> FFFFFFFB (two's complement)

    label1 db "Byte  (1 byte)  as char       : "
    l1_len equ $ - label1
    label2 db "Word  (2 bytes) low byte char : "
    l2_len equ $ - label2
    label3 db "Dword (4 bytes) as 4 chars    : "
    l3_len equ $ - label3
    label4 db "Dword raw bytes in hex (LE)   : "
    l4_len equ $ - label4
    label5 db "neg_val (-5) raw bytes (hex)  : "
    l5_len equ $ - label5

    newline db 0xA
    hexchars db "0123456789ABCDEF"

section .bss
    hexbuf resb 16      ; scratch buffer for printing hex bytes

section .text
    global _start

_start:
    ; ---------------------------------------------------------
    ; 1) Print my_byte as a character ('A')
    ; ---------------------------------------------------------
    call print_label1
    mov rsi, my_byte
    mov rdx, 1
    call print_bytes
    call print_newline

    ; ---------------------------------------------------------
    ; 2) Print low byte of my_word as a character
    ;    my_word = 0x4243 -> low byte in memory is 0x43 ('C')
    ; ---------------------------------------------------------
    call print_label2
    mov rsi, my_word
    mov rdx, 1
    call print_bytes
    call print_newline

    ; ---------------------------------------------------------
    ; 3) Print all 4 bytes of my_dword as characters
    ;    Value 0x44454647 stored in memory (low->high) as:
    ;    47 46 45 44  ->  'G' 'F' 'E' 'D'
    ; ---------------------------------------------------------
    call print_label3
    mov rsi, my_dword
    mov rdx, 4
    call print_bytes
    call print_newline

    ; ---------------------------------------------------------
    ; 4) Print raw hex bytes of my_dword to show little-endian
    ;    layout explicitly (not just as ASCII)
    ; ---------------------------------------------------------
    call print_label4
    mov rsi, my_dword
    mov rcx, 4
    call print_hex_bytes
    call print_newline

    ; ---------------------------------------------------------
    ; 5) Print raw hex bytes of neg_val to show two's complement
    ;    -5 stored as 0xFFFFFFFB
    ; ---------------------------------------------------------
    call print_label5
    mov rsi, neg_val
    mov rcx, 4
    call print_hex_bytes
    call print_newline

    ; ---- exit(0) ----
    mov rax, 60
    mov rdi, 0
    syscall

; ============================================================
; Helper subroutines
; ============================================================

print_label1:
    mov rax, 1
    mov rdi, 1
    mov rsi, label1
    mov rdx, l1_len
    syscall
    ret

print_label2:
    mov rax, 1
    mov rdi, 1
    mov rsi, label2
    mov rdx, l2_len
    syscall
    ret

print_label3:
    mov rax, 1
    mov rdi, 1
    mov rsi, label3
    mov rdx, l3_len
    syscall
    ret

print_label4:
    mov rax, 1
    mov rdi, 1
    mov rsi, label4
    mov rdx, l4_len
    syscall
    ret

print_label5:
    mov rax, 1
    mov rdi, 1
    mov rsi, label5
    mov rdx, l5_len
    syscall
    ret

print_newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; print_bytes: prints rdx raw bytes starting at rsi as characters
print_bytes:
    push rsi
    push rdx
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdx
    pop rsi
    ret

; print_hex_bytes: prints rcx bytes starting at rsi as "XX " hex pairs
print_hex_bytes:
    push rsi
    push rcx
    push rbx
.hex_loop:
    cmp rcx, 0
    je .hex_done
    movzx rbx, byte [rsi]      ; load one byte
    ; high nibble
    mov rax, rbx
    shr rax, 4
    and rax, 0xF
    lea rdx, [hexchars]
    add rdx, rax
    mov al, [rdx]
    mov [hexbuf], al
    ; low nibble
    mov rax, rbx
    and rax, 0xF
    lea rdx, [hexchars]
    add rdx, rax
    mov al, [rdx]
    mov [hexbuf+1], al
    mov byte [hexbuf+2], ' '
    ; print this pair
    push rsi
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, hexbuf
    mov rdx, 3
    syscall
    pop rcx
    pop rsi
    inc rsi
    dec rcx
    jmp .hex_loop
.hex_done:
    pop rbx
    pop rcx
    pop rsi
    ret
