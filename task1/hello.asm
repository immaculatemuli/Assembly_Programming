; ============================================================
; hello.asm — BIT 4220 Task 1: Hello World Assembly Program
; Group Work Session 1
; Demonstrates: .data section, system calls, Linux syscall ABI
;
; Build:
;   nasm -f elf64 hello.asm -o hello.o
;   ld hello.o -o hello
; Run:
;   ./hello
; ============================================================

section .data
    ; Define a string in memory. Each character is stored as
    ; its ASCII byte value. 0x0A is the newline character (10 decimal).
    msg     db  "Hello, BIT 4220 Students!", 0x0A
    msglen  equ $ - msg          ; $ = current position, so this gives string length

    ; Extra messages to demonstrate the program
    line2   db  "Assembly sees everything as raw bytes.", 0x0A
    line2len equ $ - line2

    line3   db  "Welcome to low-level programming!", 0x0A
    line3len equ $ - line3

section .text
    global _start               ; Entry point must be visible to linker

_start:
    ; --- Print first message ---
    ; Linux system call: write(fd, buf, count)
    ;   syscall number 1  = sys_write
    ;   rdi = file descriptor (1 = stdout)
    ;   rsi = pointer to buffer
    ;   rdx = number of bytes to write
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    mov rsi, msg                ; buffer: address of msg
    mov rdx, msglen             ; count: length of msg
    syscall                     ; invoke kernel

    ; --- Print second message ---
    mov rax, 1
    mov rdi, 1
    mov rsi, line2
    mov rdx, line2len
    syscall

    ; --- Print third message ---
    mov rax, 1
    mov rdi, 1
    mov rsi, line3
    mov rdx, line3len
    syscall

    ; --- Exit program ---
    ; Linux system call: exit(status)
    ;   syscall number 60 = sys_exit
    ;   rdi = exit status code (0 = success)
    mov rax, 60                 ; syscall: sys_exit
    mov rdi, 0                  ; exit code 0 (success)
    syscall
