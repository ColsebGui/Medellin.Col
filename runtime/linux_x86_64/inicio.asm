; =============================================================================
; MEDELLIN.COL - RUNTIME: ENTRY POINT
; =============================================================================
; Linux x86-64 program entry point
; Initializes runtime and calls principal()
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External symbols (provided by compiled program)
; -----------------------------------------------------------------------------
extern principal           ; User's main function

; -----------------------------------------------------------------------------
; External runtime functions
; -----------------------------------------------------------------------------
extern _medellin_memoria_iniciar
extern _medellin_salir

; -----------------------------------------------------------------------------
; Runtime exports
; -----------------------------------------------------------------------------
global _start
global _medellin_argc
global _medellin_argv

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    _medellin_argc: dq 0           ; Argument count
    _medellin_argv: dq 0           ; Argument vector pointer

; -----------------------------------------------------------------------------
; BSS section (uninitialized data)
; -----------------------------------------------------------------------------
section .bss
    ; Stack for the program (1 MB)
    alignb 16
    _pila_base: resb 1048576
    _pila_tope:

; -----------------------------------------------------------------------------
; Text section (code)
; -----------------------------------------------------------------------------
section .text

; -----------------------------------------------------------------------------
; _start - Program entry point
; -----------------------------------------------------------------------------
; Called by the kernel. Sets up runtime and calls principal()
;
; Stack layout on entry (provided by kernel):
;   [rsp]       = argc
;   [rsp+8]     = argv[0]
;   [rsp+16]    = argv[1]
;   ...
;   [rsp+8+8*argc] = NULL
;   environ follows
; -----------------------------------------------------------------------------
_start:
    ; Preserve argc and argv
    mov     rax, [rsp]              ; argc
    mov     [_medellin_argc], rax
    lea     rax, [rsp + 8]          ; argv
    mov     [_medellin_argv], rax

    ; Initialize memory allocator
    call    _medellin_memoria_iniciar

    ; Clear direction flag (required by ABI)
    cld

    ; Align stack to 16 bytes (ABI requirement)
    and     rsp, -16

    ; Call the user's principal function
    ; principal() should return exit code in rax
    call    principal

    ; Exit with return value from principal
    mov     rdi, rax                ; Exit code
    call    _medellin_salir

    ; Should never reach here
    hlt

; =============================================================================
; END OF FILE
; =============================================================================
