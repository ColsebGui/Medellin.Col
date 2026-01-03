; =============================================================================
; MEDELLIN.COL - STAGE 0: ERROR HANDLING
; =============================================================================
; Compiler error reporting
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern _medellin_escribir
extern _medellin_salir
extern util_int_to_str

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
%define STDERR 2

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
    error_line:     dq 0
    error_column:   dq 0
    error_file:     dq 0            ; Pointer to filename
    error_count_v:  dq 0

    ; Message prefixes
    msg_error:      db "ERROR", 0
    msg_error_len   equ 5

    msg_at:         db " en ", 0
    msg_at_len      equ 4

    msg_line:       db " linea ", 0
    msg_line_len    equ 7

    msg_col:        db ", columna ", 0
    msg_col_len     equ 10

    msg_colon:      db ": ", 0
    msg_colon_len   equ 2

    newline:        db 10

    ; Common error messages
    err_unexpected_char:    db "Caracter inesperado", 0
    err_unexpected_token:   db "Token inesperado", 0
    err_expected_token:     db "Se esperaba token", 0
    err_undefined_var:      db "Variable no definida", 0
    err_undefined_func:     db "Funcion no definida", 0
    err_type_mismatch:      db "Tipos incompatibles", 0
    err_redefinition:       db "Redefinicion no permitida", 0
    err_not_callable:       db "No es invocable", 0
    err_wrong_args:         db "Numero incorrecto de argumentos", 0
    err_file_not_found:     db "Archivo no encontrado", 0
    err_out_of_memory:      db "Sin memoria", 0

section .bss
    ; Buffer for number formatting
    num_buffer:     resb 32

section .text

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

    mov     rbx, rdi                    ; Save message

    ; Print "ERROR"
    mov     rdi, STDERR
    lea     rsi, [msg_error]
    mov     rdx, msg_error_len
    call    _medellin_escribir

    ; Print " en "
    mov     rdi, STDERR
    lea     rsi, [msg_at]
    mov     rdx, msg_at_len
    call    _medellin_escribir

    ; Print filename if set
    mov     rax, [error_file]
    test    rax, rax
    jz      .no_file

    ; TODO: print filename

.no_file:
    ; Print " linea "
    mov     rdi, STDERR
    lea     rsi, [msg_line]
    mov     rdx, msg_line_len
    call    _medellin_escribir

    ; Print line number
    mov     rdi, [error_line]
    lea     rsi, [num_buffer]
    mov     rdx, 32
    call    util_int_to_str
    mov     rdx, rax                    ; Length

    mov     rdi, STDERR
    lea     rsi, [num_buffer]
    call    _medellin_escribir

    ; Print ", columna "
    mov     rdi, STDERR
    lea     rsi, [msg_col]
    mov     rdx, msg_col_len
    call    _medellin_escribir

    ; Print column number
    mov     rdi, [error_column]
    lea     rsi, [num_buffer]
    mov     rdx, 32
    call    util_int_to_str
    mov     rdx, rax

    mov     rdi, STDERR
    lea     rsi, [num_buffer]
    call    _medellin_escribir

    ; Print ": "
    mov     rdi, STDERR
    lea     rsi, [msg_colon]
    mov     rdx, msg_colon_len
    call    _medellin_escribir

    ; Print error message
    mov     rdi, rbx
    call    print_string

    ; Print newline
    mov     rdi, STDERR
    lea     rsi, [newline]
    mov     rdx, 1
    call    _medellin_escribir

    ; Increment error count
    inc     qword [error_count_v]

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; error_report_at - Report error at specific location
; -----------------------------------------------------------------------------
; Input:  rdi = error message
;         rsi = line number
;         rdx = column number
; Output: none
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
    call    _medellin_salir

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

; -----------------------------------------------------------------------------
; print_string - Print null-terminated string to stderr
; -----------------------------------------------------------------------------
; Input:  rdi = string
; Output: none
; -----------------------------------------------------------------------------
print_string:
    push    rbp
    mov     rbp, rsp
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
    mov     rdx, rax                    ; Length
    mov     rdi, STDERR
    mov     rsi, rbx
    call    _medellin_escribir

    pop     rbx
    pop     rbp
    ret

; =============================================================================
; END OF FILE
; =============================================================================
