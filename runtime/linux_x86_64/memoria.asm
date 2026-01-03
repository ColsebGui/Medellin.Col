; =============================================================================
; MEDELLIN.COL - RUNTIME: MEMORY ALLOCATOR
; =============================================================================
; Simple bump allocator for Stage 0
; Will be replaced with more sophisticated allocator in Stage 1
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern _medellin_brk
extern _medellin_mmap
extern _medellin_munmap
extern _medellin_panic

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
%define HEAP_INITIAL_SIZE   (16 * 1024 * 1024)   ; 16 MB initial heap
%define HEAP_GROW_SIZE      (4 * 1024 * 1024)    ; 4 MB growth increment
%define ALIGNMENT           16                    ; 16-byte alignment

; mmap flags (from syscalls.asm)
%define PROT_READ       0x1
%define PROT_WRITE      0x2
%define MAP_PRIVATE     0x02
%define MAP_ANONYMOUS   0x20

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global _medellin_memoria_iniciar
global _medellin_memoria_pedir
global _medellin_memoria_liberar
global _medellin_memoria_estadisticas

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Allocator state
    _heap_inicio:       dq 0        ; Start of heap
    _heap_actual:       dq 0        ; Current allocation pointer
    _heap_fin:          dq 0        ; End of heap
    _heap_total:        dq 0        ; Total bytes allocated
    _heap_usado:        dq 0        ; Bytes in use

    ; Error messages
    msg_sin_memoria:    db "PANIC: Sin memoria disponible", 10, 0
    msg_sin_memoria_len equ $ - msg_sin_memoria

; -----------------------------------------------------------------------------
; Text section
; -----------------------------------------------------------------------------
section .text

; -----------------------------------------------------------------------------
; _medellin_memoria_iniciar - Initialize the memory allocator
; -----------------------------------------------------------------------------
; Input:  none
; Output: rax = 0 on success, -1 on failure
; Clobbers: rdi, rsi, rdx, r10, r8, r9
; -----------------------------------------------------------------------------
_medellin_memoria_iniciar:
    push    rbp
    mov     rbp, rsp

    ; Request initial heap via mmap
    xor     rdi, rdi                        ; addr = NULL (let kernel choose)
    mov     rsi, HEAP_INITIAL_SIZE          ; length
    mov     rdx, PROT_READ | PROT_WRITE     ; prot
    mov     r10, MAP_PRIVATE | MAP_ANONYMOUS ; flags
    mov     r8, -1                          ; fd = -1 (anonymous)
    xor     r9, r9                          ; offset = 0
    call    _medellin_mmap

    ; Check for error (negative return)
    test    rax, rax
    js      .error

    ; Initialize allocator state
    mov     [_heap_inicio], rax
    mov     [_heap_actual], rax
    add     rax, HEAP_INITIAL_SIZE
    mov     [_heap_fin], rax
    mov     qword [_heap_total], HEAP_INITIAL_SIZE
    mov     qword [_heap_usado], 0

    ; Success
    xor     rax, rax
    pop     rbp
    ret

.error:
    mov     rax, -1
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; _medellin_memoria_pedir - Allocate memory (bump allocator)
; -----------------------------------------------------------------------------
; Input:  rdi = size in bytes
; Output: rax = pointer to allocated memory (aligned to 16 bytes)
;         Returns 0 on failure
; Clobbers: rdi, rsi, rdx
; -----------------------------------------------------------------------------
_medellin_memoria_pedir:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    ; Save requested size
    mov     r12, rdi

    ; Align size to 16 bytes
    add     rdi, ALIGNMENT - 1
    and     rdi, ~(ALIGNMENT - 1)
    mov     rbx, rdi                        ; rbx = aligned size

    ; Get current pointer
    mov     rax, [_heap_actual]

    ; Align current pointer
    add     rax, ALIGNMENT - 1
    and     rax, ~(ALIGNMENT - 1)

    ; Calculate new pointer
    mov     rdx, rax
    add     rdx, rbx                        ; rdx = new heap_actual

    ; Check if we have enough space
    cmp     rdx, [_heap_fin]
    ja      .grow_heap

.allocate:
    ; Update heap pointer
    mov     [_heap_actual], rdx

    ; Update statistics
    add     [_heap_usado], rbx

    ; Return aligned pointer
    ; rax already has the aligned pointer

    pop     r12
    pop     rbx
    pop     rbp
    ret

.grow_heap:
    ; Need to grow the heap
    ; For simplicity in Stage 0, we'll allocate a new block
    ; and chain them (or just fail for now)

    ; Try to allocate more memory
    push    rax                             ; Save current pointer

    xor     rdi, rdi
    mov     rsi, HEAP_GROW_SIZE
    mov     rdx, PROT_READ | PROT_WRITE
    mov     r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov     r8, -1
    xor     r9, r9
    call    _medellin_mmap

    test    rax, rax
    js      .out_of_memory

    ; Update heap to new block
    mov     [_heap_inicio], rax             ; Note: loses old block (Stage 0 limitation)
    mov     [_heap_actual], rax
    add     rax, HEAP_GROW_SIZE
    mov     [_heap_fin], rax
    add     qword [_heap_total], HEAP_GROW_SIZE

    pop     rax                             ; Discard old pointer

    ; Retry allocation
    mov     rax, [_heap_actual]
    add     rax, ALIGNMENT - 1
    and     rax, ~(ALIGNMENT - 1)
    mov     rdx, rax
    add     rdx, rbx
    jmp     .allocate

.out_of_memory:
    pop     rax                             ; Clean stack

    ; Panic - out of memory
    lea     rdi, [msg_sin_memoria]
    mov     rsi, msg_sin_memoria_len
    call    _medellin_panic

    ; Should not return, but just in case
    xor     rax, rax
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; _medellin_memoria_liberar - Free memory (no-op in bump allocator)
; -----------------------------------------------------------------------------
; Input:  rdi = pointer to memory
;         rsi = size in bytes
; Output: none
; Note: Bump allocator doesn't actually free - memory reclaimed on exit
; -----------------------------------------------------------------------------
_medellin_memoria_liberar:
    ; In bump allocator, we don't actually free
    ; This is a placeholder for Stage 1's proper allocator
    ret

; -----------------------------------------------------------------------------
; _medellin_memoria_estadisticas - Get memory statistics
; -----------------------------------------------------------------------------
; Input:  rdi = pointer to stats structure (3 qwords)
; Output: Fills structure with [total, usado, disponible]
; -----------------------------------------------------------------------------
_medellin_memoria_estadisticas:
    mov     rax, [_heap_total]
    mov     [rdi], rax

    mov     rax, [_heap_usado]
    mov     [rdi + 8], rax

    mov     rax, [_heap_fin]
    sub     rax, [_heap_actual]
    mov     [rdi + 16], rax

    ret

; =============================================================================
; END OF FILE
; =============================================================================
