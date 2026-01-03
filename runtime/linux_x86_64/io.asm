; =============================================================================
; MEDELLIN.COL - RUNTIME: INPUT/OUTPUT
; =============================================================================
; I/O primitives for Medellin.Col programs
; Implements 'diga' and basic file operations
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern _medellin_escribir
extern _medellin_leer

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
%define STDOUT  1
%define STDERR  2
%define STDIN   0

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global _medellin_diga
global _medellin_diga_texto
global _medellin_diga_numero
global _medellin_diga_linea
global _medellin_leer_linea

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    newline:    db 10               ; Newline character

section .bss
    ; Buffer for number to string conversion
    numbuf:     resb 32
    ; Buffer for reading input
    inputbuf:   resb 1024

; -----------------------------------------------------------------------------
; Text section
; -----------------------------------------------------------------------------
section .text

; -----------------------------------------------------------------------------
; _medellin_diga_texto - Print a string to stdout
; -----------------------------------------------------------------------------
; Input:  rdi = pointer to string
;         rsi = length in bytes
; Output: rax = bytes written
; -----------------------------------------------------------------------------
_medellin_diga_texto:
    push    rbp
    mov     rbp, rsp

    ; rdi = string pointer, rsi = length
    mov     rdx, rsi                ; length -> rdx
    mov     rsi, rdi                ; buffer -> rsi
    mov     rdi, STDOUT             ; fd -> rdi
    call    _medellin_escribir

    pop     rbp
    ret

; -----------------------------------------------------------------------------
; _medellin_diga - Print a string with newline
; -----------------------------------------------------------------------------
; Input:  rdi = pointer to string
;         rsi = length in bytes
; Output: rax = bytes written
; -----------------------------------------------------------------------------
_medellin_diga:
    push    rbp
    mov     rbp, rsp
    push    rbx

    ; Print the string
    mov     rdx, rsi                ; length
    mov     rsi, rdi                ; buffer
    mov     rdi, STDOUT
    call    _medellin_escribir
    mov     rbx, rax                ; Save bytes written

    ; Print newline
    mov     rdi, STDOUT
    lea     rsi, [newline]
    mov     rdx, 1
    call    _medellin_escribir

    ; Return total bytes
    lea     rax, [rbx + 1]

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; _medellin_diga_numero - Print a 64-bit signed integer
; -----------------------------------------------------------------------------
; Input:  rdi = number to print
; Output: rax = bytes written
; -----------------------------------------------------------------------------
_medellin_diga_numero:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi                ; Save number
    lea     r13, [numbuf + 31]      ; End of buffer
    mov     byte [r13], 0           ; Null terminator

    ; Handle negative numbers
    xor     rbx, rbx                ; Flag: 0 = positive
    test    r12, r12
    jns     .positive
    neg     r12
    mov     rbx, 1                  ; Flag: 1 = negative

.positive:
    ; Handle zero
    test    r12, r12
    jnz     .convert_loop
    dec     r13
    mov     byte [r13], '0'
    jmp     .done_convert

.convert_loop:
    test    r12, r12
    jz      .done_convert

    ; Divide by 10
    mov     rax, r12
    xor     rdx, rdx
    mov     rcx, 10
    div     rcx
    mov     r12, rax                ; Quotient

    ; Store digit
    add     dl, '0'
    dec     r13
    mov     [r13], dl

    jmp     .convert_loop

.done_convert:
    ; Add minus sign if negative
    test    rbx, rbx
    jz      .print_it
    dec     r13
    mov     byte [r13], '-'

.print_it:
    ; Calculate length
    lea     rax, [numbuf + 31]
    sub     rax, r13                ; Length

    ; Print
    mov     rdi, r13                ; String pointer
    mov     rsi, rax                ; Length
    call    _medellin_diga

    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; _medellin_diga_linea - Print just a newline
; -----------------------------------------------------------------------------
; Input:  none
; Output: rax = 1
; -----------------------------------------------------------------------------
_medellin_diga_linea:
    mov     rdi, STDOUT
    lea     rsi, [newline]
    mov     rdx, 1
    jmp     _medellin_escribir

; -----------------------------------------------------------------------------
; _medellin_leer_linea - Read a line from stdin
; -----------------------------------------------------------------------------
; Input:  rdi = buffer pointer
;         rsi = max length
; Output: rax = bytes read (including newline if present)
; -----------------------------------------------------------------------------
_medellin_leer_linea:
    push    rbp
    mov     rbp, rsp

    mov     rdx, rsi                ; max length
    mov     rsi, rdi                ; buffer
    mov     rdi, STDIN
    call    _medellin_leer

    pop     rbp
    ret

; =============================================================================
; END OF FILE
; =============================================================================
