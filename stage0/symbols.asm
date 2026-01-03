; =============================================================================
; MEDELLIN.COL - STAGE 0: SYMBOL TABLE
; =============================================================================
; Symbol table for variable and function tracking
; Uses hash table with chaining for O(1) lookup
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern util_strlen
extern util_memcmp
extern strings_intern_len

; -----------------------------------------------------------------------------
; Symbol kinds
; -----------------------------------------------------------------------------
%define SYM_VARIABLE    1
%define SYM_FUNCTION    2
%define SYM_PARAMETER   3
%define SYM_CONSTANT    4

; -----------------------------------------------------------------------------
; Symbol flags
; -----------------------------------------------------------------------------
%define SYM_FLAG_MUTABLE    0x01
%define SYM_FLAG_INIT       0x02
%define SYM_FLAG_USED       0x04

; -----------------------------------------------------------------------------
; Type IDs (matches parser token types for primitives)
; -----------------------------------------------------------------------------
%define TYPE_UNKNOWN    0
%define TYPE_NUMERO     114     ; TOKEN_KW_NUMERO
%define TYPE_TEXTO      115     ; TOKEN_KW_TEXTO
%define TYPE_BOOLEANO   116     ; TOKEN_KW_BOOLEANO
%define TYPE_NADA       123     ; TOKEN_KW_NADA

; -----------------------------------------------------------------------------
; Symbol structure (48 bytes)
; -----------------------------------------------------------------------------
; struct Symbol {
;     char* name;         // 8 bytes - pointer to interned string
;     uint64_t type_id;   // 8 bytes - type of symbol
;     uint8_t kind;       // 1 byte  - SYM_VARIABLE, etc.
;     uint8_t scope;      // 1 byte  - scope depth
;     uint16_t flags;     // 2 bytes - mutable, initialized, etc.
;     uint32_t padding;   // 4 bytes
;     int64_t offset;     // 8 bytes - stack offset or address
;     Symbol* next;       // 8 bytes - next in hash chain
;     uint64_t reserved;  // 8 bytes - for future use
; }
; -----------------------------------------------------------------------------
%define SYM_SIZE        48
%define SYM_NAME        0
%define SYM_TYPE_ID     8
%define SYM_KIND        16
%define SYM_SCOPE       17
%define SYM_FLAGS       18
%define SYM_OFFSET      24
%define SYM_NEXT        32
%define SYM_RESERVED    40

; Hash table size (prime number for better distribution)
%define HASH_SIZE       1021

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global symbols_init
global symbols_enter_scope
global symbols_leave_scope
global symbols_define
global symbols_lookup
global symbols_lookup_local
global symbols_current_scope
global symbols_set_type
global symbols_get_type
global symbols_next_offset

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Built-in types
    str_numero:     db "numero", 0
    str_texto:      db "texto", 0
    str_booleano:   db "booleano", 0
    str_nada:       db "nada", 0

section .bss
    ; Hash table (array of pointers to symbol chains)
    alignb 8
    hash_table:     resq HASH_SIZE

    ; Symbol arena (1MB)
    alignb 8
    symbol_arena:   resb 1024 * 1024
    symbol_ptr:     resq 1

    ; Current scope depth
    current_scope:  resq 1

    ; Stack offset counter (for locals)
    stack_offset:   resq 1

    ; Scope markers (for cleanup on leave)
    ; Each scope records the first symbol defined in it
    scope_starts:   resq 256        ; Max 256 nested scopes

section .text

; -----------------------------------------------------------------------------
; symbols_init - Initialize symbol table
; -----------------------------------------------------------------------------
symbols_init:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    ; Clear hash table
    lea     rdi, [hash_table]
    mov     rcx, HASH_SIZE
    xor     rax, rax
.clear_loop:
    mov     [rdi], rax
    add     rdi, 8
    dec     rcx
    jnz     .clear_loop

    ; Initialize arena
    lea     rax, [symbol_arena]
    mov     [symbol_ptr], rax

    ; Start at scope 0 (global)
    mov     qword [current_scope], 0
    mov     qword [stack_offset], 0

    ; Clear scope markers
    lea     rdi, [scope_starts]
    mov     rcx, 256
    xor     rax, rax
.clear_scopes:
    mov     [rdi], rax
    add     rdi, 8
    dec     rcx
    jnz     .clear_scopes

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; symbols_enter_scope - Enter a new scope
; -----------------------------------------------------------------------------
symbols_enter_scope:
    inc     qword [current_scope]

    ; Record current symbol pointer as scope start
    mov     rax, [current_scope]
    lea     rcx, [scope_starts]
    mov     rdx, [symbol_ptr]
    mov     [rcx + rax * 8], rdx

    ret

; -----------------------------------------------------------------------------
; symbols_leave_scope - Leave current scope
; -----------------------------------------------------------------------------
; Removes all symbols defined in the current scope
; -----------------------------------------------------------------------------
symbols_leave_scope:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     rax, [current_scope]
    test    rax, rax
    jz      .done                       ; Can't leave global scope

    ; Get scope start marker
    lea     rcx, [scope_starts]
    mov     r12, [rcx + rax * 8]        ; First symbol of this scope

    ; Remove all symbols from this scope from hash chains
    mov     r13, [current_scope]

    ; Iterate through hash table
    lea     rbx, [hash_table]
    mov     rcx, HASH_SIZE

.hash_loop:
    push    rcx
    mov     rax, [rbx]                  ; Head of chain
    test    rax, rax
    jz      .next_bucket

    ; Check if head is in current scope
    cmp     byte [rax + SYM_SCOPE], r13b
    jne     .check_chain

    ; Remove head
    mov     rax, [rax + SYM_NEXT]
    mov     [rbx], rax
    jmp     .check_again

.check_chain:
    ; Walk chain and remove nodes in current scope
    mov     rdx, rax                    ; prev
.chain_loop:
    mov     rax, [rdx + SYM_NEXT]
    test    rax, rax
    jz      .next_bucket

    cmp     byte [rax + SYM_SCOPE], r13b
    jne     .advance

    ; Remove this node
    mov     rcx, [rax + SYM_NEXT]
    mov     [rdx + SYM_NEXT], rcx
    jmp     .chain_loop

.advance:
    mov     rdx, rax
    jmp     .chain_loop

.check_again:
    mov     rax, [rbx]
    test    rax, rax
    jz      .next_bucket
    cmp     byte [rax + SYM_SCOPE], r13b
    je      .check_again
    jmp     .check_chain

.next_bucket:
    pop     rcx
    add     rbx, 8
    dec     rcx
    jnz     .hash_loop

    ; Restore arena pointer (reclaim memory)
    mov     [symbol_ptr], r12

    ; Decrement scope
    dec     qword [current_scope]

.done:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; hash_string - Compute hash of string
; -----------------------------------------------------------------------------
; Input:  rdi = string pointer (interned, so just hash the pointer)
; Output: rax = hash value (0 to HASH_SIZE-1)
; -----------------------------------------------------------------------------
hash_string:
    ; For interned strings, we can just hash the pointer
    mov     rax, rdi
    ; Mix the bits
    mov     rcx, rax
    shr     rcx, 33
    xor     rax, rcx
    mov     rcx, 0xff51afd7ed558ccd
    imul    rax, rcx
    mov     rcx, rax
    shr     rcx, 33
    xor     rax, rcx
    mov     rcx, 0xc4ceb9fe1a85ec53
    imul    rax, rcx
    mov     rcx, rax
    shr     rcx, 33
    xor     rax, rcx

    ; Modulo HASH_SIZE
    xor     rdx, rdx
    mov     rcx, HASH_SIZE
    div     rcx
    mov     rax, rdx
    ret

; -----------------------------------------------------------------------------
; symbols_define - Define a new symbol
; -----------------------------------------------------------------------------
; Input:  rdi = name (interned string pointer)
;         rsi = kind (SYM_VARIABLE, etc.)
;         rdx = type_id
;         rcx = flags
; Output: rax = pointer to symbol, or 0 if already defined in scope
; -----------------------------------------------------------------------------
symbols_define:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rdi                    ; name
    mov     r13, rsi                    ; kind
    mov     r14, rdx                    ; type_id
    mov     r15, rcx                    ; flags

    ; Check if already defined in current scope
    call    symbols_lookup_local
    test    rax, rax
    jnz     .already_defined

    ; Allocate symbol
    mov     rax, [symbol_ptr]
    mov     rbx, rax
    add     rax, SYM_SIZE
    mov     [symbol_ptr], rax

    ; Initialize symbol
    mov     [rbx + SYM_NAME], r12
    mov     [rbx + SYM_TYPE_ID], r14
    mov     [rbx + SYM_KIND], r13b
    mov     rax, [current_scope]
    mov     [rbx + SYM_SCOPE], al
    mov     [rbx + SYM_FLAGS], r15w

    ; Calculate offset for variables
    cmp     r13b, SYM_VARIABLE
    jne     .no_offset
    cmp     qword [current_scope], 0
    je      .no_offset                  ; Globals don't use stack offset

    ; Allocate stack space (8 bytes per variable)
    mov     rax, [stack_offset]
    sub     rax, 8
    mov     [stack_offset], rax
    mov     [rbx + SYM_OFFSET], rax
    jmp     .insert

.no_offset:
    mov     qword [rbx + SYM_OFFSET], 0

.insert:
    ; Hash the name
    mov     rdi, r12
    call    hash_string
    mov     rcx, rax

    ; Insert at head of chain
    lea     rdx, [hash_table]
    mov     rax, [rdx + rcx * 8]        ; Old head
    mov     [rbx + SYM_NEXT], rax
    mov     [rdx + rcx * 8], rbx

    mov     rax, rbx
    jmp     .return

.already_defined:
    xor     rax, rax

.return:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; symbols_lookup - Look up a symbol by name
; -----------------------------------------------------------------------------
; Input:  rdi = name (interned string pointer)
; Output: rax = pointer to symbol, or 0 if not found
; -----------------------------------------------------------------------------
symbols_lookup:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi                    ; name

    ; Hash the name
    call    hash_string
    mov     rcx, rax

    ; Search chain
    lea     rdx, [hash_table]
    mov     rax, [rdx + rcx * 8]

.search:
    test    rax, rax
    jz      .not_found

    ; Compare names (pointers for interned strings)
    cmp     [rax + SYM_NAME], r12
    je      .found

    mov     rax, [rax + SYM_NEXT]
    jmp     .search

.found:
    jmp     .return

.not_found:
    xor     rax, rax

.return:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; symbols_lookup_local - Look up symbol in current scope only
; -----------------------------------------------------------------------------
; Input:  rdi = name (interned string pointer)
; Output: rax = pointer to symbol, or 0 if not found in current scope
; -----------------------------------------------------------------------------
symbols_lookup_local:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi                    ; name
    mov     r13, [current_scope]

    ; Hash the name
    call    hash_string
    mov     rcx, rax

    ; Search chain
    lea     rdx, [hash_table]
    mov     rax, [rdx + rcx * 8]

.search:
    test    rax, rax
    jz      .not_found

    ; Check scope
    cmp     byte [rax + SYM_SCOPE], r13b
    jne     .next

    ; Compare names
    cmp     [rax + SYM_NAME], r12
    je      .found

.next:
    mov     rax, [rax + SYM_NEXT]
    jmp     .search

.found:
    jmp     .return

.not_found:
    xor     rax, rax

.return:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; symbols_current_scope - Get current scope depth
; -----------------------------------------------------------------------------
; Output: rax = current scope depth
; -----------------------------------------------------------------------------
symbols_current_scope:
    mov     rax, [current_scope]
    ret

; -----------------------------------------------------------------------------
; symbols_set_type - Set type of a symbol
; -----------------------------------------------------------------------------
; Input:  rdi = symbol pointer
;         rsi = type_id
; -----------------------------------------------------------------------------
symbols_set_type:
    mov     [rdi + SYM_TYPE_ID], rsi
    ret

; -----------------------------------------------------------------------------
; symbols_get_type - Get type of a symbol
; -----------------------------------------------------------------------------
; Input:  rdi = symbol pointer
; Output: rax = type_id
; -----------------------------------------------------------------------------
symbols_get_type:
    mov     rax, [rdi + SYM_TYPE_ID]
    ret

; -----------------------------------------------------------------------------
; symbols_next_offset - Get next stack offset for variable
; -----------------------------------------------------------------------------
; Output: rax = next available stack offset
; -----------------------------------------------------------------------------
symbols_next_offset:
    mov     rax, [stack_offset]
    ret

; =============================================================================
; END OF FILE
; =============================================================================
