; =============================================================================
; MEDELLIN.COL - STAGE 0: STRING TABLE
; =============================================================================
; Interned string storage for identifiers and literals
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern util_strlen
extern util_streq
extern util_memcpy
extern util_memcmp

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
%define STRING_TABLE_SIZE   (1024 * 1024)   ; 1MB
%define HASH_TABLE_SIZE     4096            ; Hash buckets

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global strings_init
global strings_intern
global strings_intern_len
global strings_get

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .bss
    ; String storage area
    alignb 8
    string_buffer:      resb STRING_TABLE_SIZE
    string_buffer_pos:  resq 1

    ; Hash table for fast lookup
    ; Each entry: [ptr to string, next entry]
    alignb 8
    hash_table:         resq HASH_TABLE_SIZE * 2

section .data
    ; Pre-interned keywords (populated at init)
    kw_parcero:     dq 0
    kw_fin:         dq 0
    kw_si:          dq 0
    kw_entonces:    dq 0
    kw_sino:        dq 0
    kw_listo:       dq 0
    kw_mientras:    dq 0
    kw_haga:        dq 0
    kw_desde:       dq 0
    kw_siendo:      dq 0
    kw_hasta:       dq 0
    kw_devuelvase:  dq 0
    kw_con:         dq 0
    kw_diga:        dq 0
    kw_numero:      dq 0
    kw_texto:       dq 0
    kw_booleano:    dq 0
    kw_es:          dq 0
    kw_devuelve:    dq 0
    kw_sume:        dq 0
    kw_quite:       dq 0
    kw_nada:        dq 0
    kw_verdad:      dq 0
    kw_falso:       dq 0
    kw_mas:         dq 0
    kw_menos:       dq 0
    kw_por:         dq 0
    kw_entre:       dq 0
    kw_modulo:      dq 0
    kw_y:           dq 0
    kw_o:           dq 0
    kw_no:          dq 0
    kw_igual:       dq 0
    kw_mayor:       dq 0
    kw_menor:       dq 0
    kw_que:         dq 0
    kw_a:           dq 0

    ; String literals for keywords
    str_parcero:    db "parcero", 0
    str_fin:        db "fin", 0
    str_si:         db "si", 0
    str_entonces:   db "entonces", 0
    str_sino:       db "sino", 0
    str_listo:      db "listo", 0
    str_mientras:   db "mientras", 0
    str_haga:       db "haga", 0
    str_desde:      db "desde", 0
    str_siendo:     db "siendo", 0
    str_hasta:      db "hasta", 0
    str_devuelvase: db "devolverse", 0  ; Note: normalized form
    str_con:        db "con", 0
    str_diga:       db "diga", 0
    str_numero:     db "numero", 0
    str_texto:      db "texto", 0
    str_booleano:   db "booleano", 0
    str_es:         db "es", 0
    str_devuelve:   db "devuelve", 0
    str_sume:       db "sume", 0
    str_quite:      db "quite", 0
    str_nada:       db "nada", 0
    str_verdad:     db "verdad", 0
    str_falso:      db "falso", 0
    str_mas:        db "mas", 0
    str_menos:      db "menos", 0
    str_por:        db "por", 0
    str_entre:      db "entre", 0
    str_modulo:     db "modulo", 0
    str_y:          db "y", 0
    str_o:          db "o", 0
    str_no:         db "no", 0
    str_igual:      db "igual", 0
    str_mayor:      db "mayor", 0
    str_menor:      db "menor", 0
    str_que:        db "que", 0
    str_a:          db "a", 0

section .text

; -----------------------------------------------------------------------------
; strings_init - Initialize string table
; -----------------------------------------------------------------------------
; Input:  none
; Output: none
; Clobbers: rax, rdi, rsi, rdx
; -----------------------------------------------------------------------------
strings_init:
    push    rbp
    mov     rbp, rsp
    push    rbx

    ; Initialize buffer position
    lea     rax, [string_buffer]
    mov     [string_buffer_pos], rax

    ; Clear hash table
    lea     rdi, [hash_table]
    xor     rax, rax
    mov     rcx, HASH_TABLE_SIZE * 2
    rep stosq

    ; Intern keywords
    lea     rdi, [str_parcero]
    call    strings_intern
    mov     [kw_parcero], rax

    lea     rdi, [str_fin]
    call    strings_intern
    mov     [kw_fin], rax

    lea     rdi, [str_si]
    call    strings_intern
    mov     [kw_si], rax

    lea     rdi, [str_entonces]
    call    strings_intern
    mov     [kw_entonces], rax

    lea     rdi, [str_listo]
    call    strings_intern
    mov     [kw_listo], rax

    lea     rdi, [str_mientras]
    call    strings_intern
    mov     [kw_mientras], rax

    lea     rdi, [str_haga]
    call    strings_intern
    mov     [kw_haga], rax

    lea     rdi, [str_desde]
    call    strings_intern
    mov     [kw_desde], rax

    lea     rdi, [str_siendo]
    call    strings_intern
    mov     [kw_siendo], rax

    lea     rdi, [str_hasta]
    call    strings_intern
    mov     [kw_hasta], rax

    lea     rdi, [str_devuelvase]
    call    strings_intern
    mov     [kw_devuelvase], rax

    lea     rdi, [str_con]
    call    strings_intern
    mov     [kw_con], rax

    lea     rdi, [str_diga]
    call    strings_intern
    mov     [kw_diga], rax

    lea     rdi, [str_numero]
    call    strings_intern
    mov     [kw_numero], rax

    lea     rdi, [str_texto]
    call    strings_intern
    mov     [kw_texto], rax

    lea     rdi, [str_booleano]
    call    strings_intern
    mov     [kw_booleano], rax

    lea     rdi, [str_es]
    call    strings_intern
    mov     [kw_es], rax

    lea     rdi, [str_devuelve]
    call    strings_intern
    mov     [kw_devuelve], rax

    lea     rdi, [str_verdad]
    call    strings_intern
    mov     [kw_verdad], rax

    lea     rdi, [str_falso]
    call    strings_intern
    mov     [kw_falso], rax

    lea     rdi, [str_mas]
    call    strings_intern
    mov     [kw_mas], rax

    lea     rdi, [str_menos]
    call    strings_intern
    mov     [kw_menos], rax

    lea     rdi, [str_por]
    call    strings_intern
    mov     [kw_por], rax

    lea     rdi, [str_entre]
    call    strings_intern
    mov     [kw_entre], rax

    lea     rdi, [str_y]
    call    strings_intern
    mov     [kw_y], rax

    lea     rdi, [str_o]
    call    strings_intern
    mov     [kw_o], rax

    lea     rdi, [str_no]
    call    strings_intern
    mov     [kw_no], rax

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; hash_string - Compute hash of string
; -----------------------------------------------------------------------------
; Input:  rdi = string pointer
;         rsi = length
; Output: rax = hash value
; -----------------------------------------------------------------------------
hash_string:
    xor     rax, rax
    test    rsi, rsi
    jz      .done
.loop:
    movzx   ecx, byte [rdi]
    imul    rax, 31
    add     rax, rcx
    inc     rdi
    dec     rsi
    jnz     .loop
.done:
    and     rax, HASH_TABLE_SIZE - 1    ; Mask to table size
    ret

; -----------------------------------------------------------------------------
; strings_intern - Intern a null-terminated string
; -----------------------------------------------------------------------------
; Input:  rdi = null-terminated string
; Output: rax = interned string pointer
; -----------------------------------------------------------------------------
strings_intern:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi                    ; Save string

    ; Get length
    call    util_strlen
    mov     rsi, rax                    ; length

    ; Intern with length
    mov     rdi, r12
    call    strings_intern_len

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; strings_intern_len - Intern a string with known length
; -----------------------------------------------------------------------------
; Input:  rdi = string pointer
;         rsi = length
; Output: rax = interned string pointer
; -----------------------------------------------------------------------------
strings_intern_len:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12, rdi                    ; string
    mov     r13, rsi                    ; length

    ; Compute hash
    call    hash_string
    mov     r14, rax                    ; hash index

    ; Look up in hash table
    lea     rbx, [hash_table]
    shl     r14, 4                      ; index * 16 (2 qwords per entry)
    add     rbx, r14

.search_chain:
    mov     rax, [rbx]                  ; Get string pointer
    test    rax, rax
    jz      .not_found

    ; Compare strings (only compare length bytes, not null terminator
    ; since input string from source buffer is not null-terminated)
    push    rbx
    mov     rdi, rax
    mov     rsi, r12
    mov     rdx, r13
    call    util_memcmp
    pop     rbx
    test    rax, rax
    jz      .found

    ; Next in chain
    mov     rbx, [rbx + 8]
    test    rbx, rbx
    jnz     .search_chain

.not_found:
    ; Allocate space in string buffer
    mov     rax, [string_buffer_pos]
    mov     rbx, rax                    ; Save new string position

    ; Copy string
    mov     rdi, rax
    mov     rsi, r12
    mov     rdx, r13
    call    util_memcpy

    ; Add null terminator
    mov     rdi, [string_buffer_pos]
    add     rdi, r13
    mov     byte [rdi], 0

    ; Update buffer position (aligned)
    lea     rax, [rdi + 8]
    and     rax, ~7
    mov     [string_buffer_pos], rax

    ; Add to hash table
    lea     rax, [hash_table]
    shr     r14, 4                      ; Restore original index
    shl     r14, 4
    add     rax, r14

    ; Simple insert at head
    mov     [rax], rbx                  ; Store string pointer

    mov     rax, rbx                    ; Return new string
    jmp     .done

.found:
    mov     rax, [rbx]                  ; Return existing string

.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; strings_get - Get interned keyword by name
; -----------------------------------------------------------------------------
; Input:  rdi = keyword name string
; Output: rax = interned pointer, or 0 if not found
; -----------------------------------------------------------------------------
strings_get:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi

    ; Get length
    call    util_strlen
    mov     rsi, rax

    ; Compute hash
    mov     rdi, r12
    call    hash_string
    mov     rbx, rax

    ; Look up
    lea     rax, [hash_table]
    shl     rbx, 4
    add     rax, rbx
    mov     rax, [rax]                  ; Get string pointer

    pop     r12
    pop     rbx
    pop     rbp
    ret

; =============================================================================
; END OF FILE
; =============================================================================
