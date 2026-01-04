; =============================================================================
; MEDELLIN.COL - STAGE 0: ERROR HANDLING
; =============================================================================
; Compiler error reporting (self-contained, no runtime deps)
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; System calls
; -----------------------------------------------------------------------------
%define SYS_WRITE       1
%define SYS_EXIT        60
%define STDERR          2

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern util_int_to_str

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global error_init
global error_report
global error_report_at
global error_fatal
global error_has_errors
global error_count

; Export error state for other modules
global error_line
global error_column
global error_file

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Error state
    error_line:     dq 1
    error_column:   dq 1
    error_file:     dq 0            ; Pointer to filename
    error_count_v:  dq 0

    ; Message prefixes
    msg_error:      db "ERROR"
    msg_error_len   equ 5

    msg_at:         db " en "
    msg_at_len      equ 4

    msg_line:       db "linea "
    msg_line_len    equ 6

    msg_col:        db ", columna "
    msg_col_len     equ 10

    msg_colon:      db ": "
    msg_colon_len   equ 2

    newline:        db 10

section .bss
    ; Buffer for number formatting
    num_buffer:     resb 32

section .text

; -----------------------------------------------------------------------------
; write_stderr - Write to stderr
; -----------------------------------------------------------------------------
; Input:  rdi = buffer
;         rsi = length
; -----------------------------------------------------------------------------
write_stderr:
    push    rax
    push    rcx
    push    r11
    push    rdi
    push    rsi

    mov     rdx, rsi                ; length
    mov     rsi, rdi                ; buffer
    mov     rdi, STDERR             ; fd
    mov     rax, SYS_WRITE
    syscall

    pop     rsi
    pop     rdi
    pop     r11
    pop     rcx
    pop     rax
    ret

; -----------------------------------------------------------------------------
; exit_program - Exit with code
; -----------------------------------------------------------------------------
; Input:  rdi = exit code
; -----------------------------------------------------------------------------
exit_program:
    mov     rax, SYS_EXIT
    syscall

; -----------------------------------------------------------------------------
; error_init - Initialize error system
; -----------------------------------------------------------------------------
error_init:
    mov     qword [error_line], 1
    mov     qword [error_column], 1
    mov     qword [error_count_v], 0
    ret

; -----------------------------------------------------------------------------
; error_report - Report an error with current location
; -----------------------------------------------------------------------------
; Input:  rdi = error message (null-terminated)
; Output: none
; -----------------------------------------------------------------------------
error_report:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     rbx, rdi                    ; Save message

    ; Print "ERROR"
    lea     rdi, [msg_error]
    mov     rsi, msg_error_len
    call    write_stderr

    ; Print " en "
    lea     rdi, [msg_at]
    mov     rsi, msg_at_len
    call    write_stderr

    ; Print "linea "
    lea     rdi, [msg_line]
    mov     rsi, msg_line_len
    call    write_stderr

    ; Print line number
    mov     rdi, [error_line]
    lea     rsi, [num_buffer]
    mov     rdx, 32
    call    util_int_to_str
    mov     r12, rax                    ; Length

    lea     rdi, [num_buffer]
    mov     rsi, r12
    call    write_stderr

    ; Print ", columna "
    lea     rdi, [msg_col]
    mov     rsi, msg_col_len
    call    write_stderr

    ; Print column number
    mov     rdi, [error_column]
    lea     rsi, [num_buffer]
    mov     rdx, 32
    call    util_int_to_str
    mov     r12, rax

    lea     rdi, [num_buffer]
    mov     rsi, r12
    call    write_stderr

    ; Print ": "
    lea     rdi, [msg_colon]
    mov     rsi, msg_colon_len
    call    write_stderr

    ; Print error message
    mov     rdi, rbx
    call    print_cstring

    ; Print newline
    lea     rdi, [newline]
    mov     rsi, 1
    call    write_stderr

    ; Increment error count
    inc     qword [error_count_v]

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; print_cstring - Print null-terminated string to stderr
; -----------------------------------------------------------------------------
; Input:  rdi = string
; -----------------------------------------------------------------------------
print_cstring:
    push    rbx
    mov     rbx, rdi

    ; Get length
    xor     rax, rax
.len_loop:
    cmp     byte [rbx + rax], 0
    je      .print
    inc     rax
    jmp     .len_loop

.print:
    mov     rsi, rax                    ; Length
    mov     rdi, rbx
    call    write_stderr

    pop     rbx
    ret

; -----------------------------------------------------------------------------
; error_report_at - Report error at specific location
; -----------------------------------------------------------------------------
; Input:  rdi = error message
;         rsi = line number
;         rdx = column number
; -----------------------------------------------------------------------------
error_report_at:
    push    rbp
    mov     rbp, rsp

    ; Save location
    mov     [error_line], rsi
    mov     [error_column], rdx

    ; Report error
    call    error_report

    pop     rbp
    ret

; -----------------------------------------------------------------------------
; error_fatal - Report error and exit
; -----------------------------------------------------------------------------
; Input:  rdi = error message
; Output: does not return
; -----------------------------------------------------------------------------
error_fatal:
    call    error_report

    mov     rdi, 1                      ; Exit code 1
    call    exit_program

; -----------------------------------------------------------------------------
; error_has_errors - Check if any errors occurred
; -----------------------------------------------------------------------------
; Output: rax = 1 if errors, 0 if none
; -----------------------------------------------------------------------------
error_has_errors:
    mov     rax, [error_count_v]
    test    rax, rax
    setnz   al
    movzx   rax, al
    ret

; -----------------------------------------------------------------------------
; error_count - Get error count
; -----------------------------------------------------------------------------
; Output: rax = number of errors
; -----------------------------------------------------------------------------
error_count:
    mov     rax, [error_count_v]
    ret

; =============================================================================
; END OF FILE
; =============================================================================
