; =============================================================================
; MEDELLIN.COL - RUNTIME: PANIC HANDLER
; =============================================================================
; Handles runtime panics and errors
; Prints error message and exits with error code
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern _medellin_escribir
extern _medellin_salir

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
%define STDERR  2
%define EXIT_PANIC  101

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global _medellin_panic
global _medellin_panic_indice
global _medellin_panic_nulo
global _medellin_panic_asercion
global _medellin_panic_division

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Panic prefix
    msg_panic_prefix:       db 10, "=== PANIC ===" , 10, 0
    msg_panic_prefix_len    equ $ - msg_panic_prefix - 1

    ; Common panic messages
    msg_indice_invalido:    db "Indice fuera de limites", 10, 0
    msg_indice_invalido_len equ $ - msg_indice_invalido - 1

    msg_nulo:               db "Acceso a valor nulo (quizas vacio)", 10, 0
    msg_nulo_len            equ $ - msg_nulo - 1

    msg_asercion:           db "Asercion 'asuma' fallida", 10, 0
    msg_asercion_len        equ $ - msg_asercion - 1

    msg_division:           db "Division por cero", 10, 0
    msg_division_len        equ $ - msg_division - 1

    msg_ubicacion:          db "Ubicacion: ", 0
    msg_ubicacion_len       equ $ - msg_ubicacion - 1

    msg_linea:              db "Linea: ", 0
    msg_linea_len           equ $ - msg_linea - 1

    newline:                db 10

; -----------------------------------------------------------------------------
; Text section
; -----------------------------------------------------------------------------
section .text

; -----------------------------------------------------------------------------
; _medellin_panic - Generic panic with custom message
; -----------------------------------------------------------------------------
; Input:  rdi = message pointer
;         rsi = message length
; Output: does not return (exits with code 101)
; -----------------------------------------------------------------------------
_medellin_panic:
    push    rbp
    mov     rbp, rsp
    push    r12
    push    r13

    ; Save message
    mov     r12, rdi
    mov     r13, rsi

    ; Print panic prefix
    mov     rdi, STDERR
    lea     rsi, [msg_panic_prefix]
    mov     rdx, msg_panic_prefix_len
    call    _medellin_escribir

    ; Print the error message
    mov     rdi, STDERR
    mov     rsi, r12
    mov     rdx, r13
    call    _medellin_escribir

    ; Print newline
    mov     rdi, STDERR
    lea     rsi, [newline]
    mov     rdx, 1
    call    _medellin_escribir

    ; Exit with panic code
    mov     rdi, EXIT_PANIC
    call    _medellin_salir

    ; Should never reach here
    hlt

; -----------------------------------------------------------------------------
; _medellin_panic_indice - Panic for index out of bounds
; -----------------------------------------------------------------------------
; Input:  rdi = index that was accessed
;         rsi = array length
; Output: does not return
; -----------------------------------------------------------------------------
_medellin_panic_indice:
    push    rbp
    mov     rbp, rsp

    ; For now, just print generic message
    ; TODO: Include index and length in message
    lea     rdi, [msg_indice_invalido]
    mov     rsi, msg_indice_invalido_len
    call    _medellin_panic

    ; Never returns
    hlt

; -----------------------------------------------------------------------------
; _medellin_panic_nulo - Panic for null/None access
; -----------------------------------------------------------------------------
; Input:  none
; Output: does not return
; -----------------------------------------------------------------------------
_medellin_panic_nulo:
    lea     rdi, [msg_nulo]
    mov     rsi, msg_nulo_len
    call    _medellin_panic
    hlt

; -----------------------------------------------------------------------------
; _medellin_panic_asercion - Panic for failed 'asuma' assertion
; -----------------------------------------------------------------------------
; Input:  rdi = assertion message pointer (optional, can be 0)
;         rsi = assertion message length
; Output: does not return
; -----------------------------------------------------------------------------
_medellin_panic_asercion:
    push    rbp
    mov     rbp, rsp
    push    r12
    push    r13

    ; Save custom message
    mov     r12, rdi
    mov     r13, rsi

    ; Print panic prefix
    mov     rdi, STDERR
    lea     rsi, [msg_panic_prefix]
    mov     rdx, msg_panic_prefix_len
    call    _medellin_escribir

    ; Print generic assertion message
    mov     rdi, STDERR
    lea     rsi, [msg_asercion]
    mov     rdx, msg_asercion_len
    call    _medellin_escribir

    ; If we have a custom message, print it too
    test    r12, r12
    jz      .exit

    mov     rdi, STDERR
    mov     rsi, r12
    mov     rdx, r13
    call    _medellin_escribir

    mov     rdi, STDERR
    lea     rsi, [newline]
    mov     rdx, 1
    call    _medellin_escribir

.exit:
    mov     rdi, EXIT_PANIC
    call    _medellin_salir
    hlt

; -----------------------------------------------------------------------------
; _medellin_panic_division - Panic for division by zero
; -----------------------------------------------------------------------------
; Input:  none
; Output: does not return
; -----------------------------------------------------------------------------
_medellin_panic_division:
    lea     rdi, [msg_division]
    mov     rsi, msg_division_len
    call    _medellin_panic
    hlt

; =============================================================================
; END OF FILE
; =============================================================================
