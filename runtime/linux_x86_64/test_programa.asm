; =============================================================================
; MEDELLIN.COL - RUNTIME TEST PROGRAM
; =============================================================================
; Tests the runtime primitives
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External runtime functions
; -----------------------------------------------------------------------------
extern _medellin_diga
extern _medellin_diga_numero
extern _medellin_memoria_pedir

; -----------------------------------------------------------------------------
; Export principal (entry point)
; -----------------------------------------------------------------------------
global principal

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    msg_hola:       db "Hola Mundo desde Medellin.Col!"
    msg_hola_len    equ $ - msg_hola

    msg_memoria:    db "Memoria asignada exitosamente"
    msg_memoria_len equ $ - msg_memoria

    msg_numero:     db "Numero de prueba:"
    msg_numero_len  equ $ - msg_numero

; -----------------------------------------------------------------------------
; Text section
; -----------------------------------------------------------------------------
section .text

; -----------------------------------------------------------------------------
; principal - Program entry point
; -----------------------------------------------------------------------------
; Output: rax = exit code (0 = success)
; -----------------------------------------------------------------------------
principal:
    push    rbp
    mov     rbp, rsp
    push    r12

    ; Test 1: Print hello world
    lea     rdi, [msg_hola]
    mov     rsi, msg_hola_len
    call    _medellin_diga

    ; Test 2: Print a number
    lea     rdi, [msg_numero]
    mov     rsi, msg_numero_len
    call    _medellin_diga

    mov     rdi, 42
    call    _medellin_diga_numero

    mov     rdi, -123
    call    _medellin_diga_numero

    mov     rdi, 1000000
    call    _medellin_diga_numero

    ; Test 3: Allocate memory
    mov     rdi, 1024               ; Request 1KB
    call    _medellin_memoria_pedir
    mov     r12, rax                ; Save pointer

    ; Check allocation succeeded
    test    r12, r12
    jz      .alloc_failed

    ; Write something to the memory
    mov     byte [r12], 'X'
    mov     byte [r12 + 1], 0

    lea     rdi, [msg_memoria]
    mov     rsi, msg_memoria_len
    call    _medellin_diga

    ; Success - return 0
    xor     rax, rax
    jmp     .done

.alloc_failed:
    ; Return error code
    mov     rax, 1

.done:
    pop     r12
    pop     rbp
    ret

; =============================================================================
; END OF FILE
; =============================================================================
