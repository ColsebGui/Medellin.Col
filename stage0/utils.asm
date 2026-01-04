; =============================================================================
; MEDELLIN.COL - STAGE 0: UTILITIES
; =============================================================================
; Common utility functions for the compiler
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global util_strlen
global util_streq
global util_strcmp
global util_memcpy
global util_memset
global util_memcmp
global util_is_digit
global util_is_alpha
global util_is_alnum
global util_is_space
global util_parse_int
global util_int_to_str

section .text

; -----------------------------------------------------------------------------
; util_strlen - Calculate string length
; -----------------------------------------------------------------------------
; Input:  rdi = null-terminated string pointer
; Output: rax = length (not including null)
; -----------------------------------------------------------------------------
util_strlen:
    xor     rax, rax                ; length = 0
    test    rdi, rdi
    jz      .done
.loop:
    cmp     byte [rdi + rax], 0
    je      .done
    inc     rax
    jmp     .loop
.done:
    ret

; -----------------------------------------------------------------------------
; util_streq - Compare two strings for equality
; -----------------------------------------------------------------------------
; Input:  rdi = string 1
;         rsi = string 2
; Output: rax = 1 if equal, 0 if not
; -----------------------------------------------------------------------------
util_streq:
    push    rbx
.loop:
    mov     al, [rdi]
    mov     bl, [rsi]
    cmp     al, bl
    jne     .not_equal
    test    al, al
    jz      .equal
    inc     rdi
    inc     rsi
    jmp     .loop
.equal:
    mov     rax, 1
    pop     rbx
    ret
.not_equal:
    xor     rax, rax
    pop     rbx
    ret

; -----------------------------------------------------------------------------
; util_strcmp - Compare two strings (C-style)
; -----------------------------------------------------------------------------
; Input:  rdi = string 1
;         rsi = string 2
; Output: rax = 0 if equal, <0 if s1<s2, >0 if s1>s2
; -----------------------------------------------------------------------------
util_strcmp:
    push    rbx
.loop:
    movzx   eax, byte [rdi]
    movzx   ebx, byte [rsi]
    cmp     al, bl
    jne     .diff
    test    al, al
    jz      .equal
    inc     rdi
    inc     rsi
    jmp     .loop
.equal:
    xor     rax, rax
    pop     rbx
    ret
.diff:
    sub     eax, ebx
    pop     rbx
    ret

; -----------------------------------------------------------------------------
; util_memcpy - Copy memory
; -----------------------------------------------------------------------------
; Input:  rdi = destination
;         rsi = source
;         rdx = count
; Output: rax = destination
; -----------------------------------------------------------------------------
util_memcpy:
    mov     rax, rdi                ; Save destination
    mov     rcx, rdx
    test    rcx, rcx
    jz      .done
    cld
    rep movsb
.done:
    ret

; -----------------------------------------------------------------------------
; util_memset - Fill memory with byte
; -----------------------------------------------------------------------------
; Input:  rdi = destination
;         rsi = byte value (low 8 bits used)
;         rdx = count
; Output: rax = destination
; -----------------------------------------------------------------------------
util_memset:
    mov     rax, rdi                ; Save destination
    mov     rcx, rdx
    test    rcx, rcx
    jz      .done
    mov     al, sil                 ; Byte to fill
    cld
    rep stosb
    mov     rax, rdi
    sub     rax, rdx                ; Restore original destination
.done:
    ret

; -----------------------------------------------------------------------------
; util_memcmp - Compare memory
; -----------------------------------------------------------------------------
; Input:  rdi = pointer 1
;         rsi = pointer 2
;         rdx = count
; Output: rax = 0 if equal, <0 if p1<p2, >0 if p1>p2
; -----------------------------------------------------------------------------
util_memcmp:
    test    rdx, rdx
    jz      .equal
.loop:
    mov     al, [rdi]
    cmp     al, [rsi]
    jne     .not_equal
    inc     rdi
    inc     rsi
    dec     rdx
    jnz     .loop
.equal:
    xor     rax, rax
    ret
.not_equal:
    movzx   eax, byte [rdi]
    movzx   ecx, byte [rsi]
    sub     eax, ecx
    ret

; -----------------------------------------------------------------------------
; util_is_digit - Check if character is digit
; -----------------------------------------------------------------------------
; Input:  rdi = character
; Output: rax = 1 if digit, 0 if not
; -----------------------------------------------------------------------------
util_is_digit:
    cmp     dil, '0'
    jb      .no
    cmp     dil, '9'
    ja      .no
    mov     rax, 1
    ret
.no:
    xor     rax, rax
    ret

; -----------------------------------------------------------------------------
; util_is_alpha - Check if character is letter (including Spanish)
; -----------------------------------------------------------------------------
; Input:  rdi = character (may be UTF-8 lead byte)
; Output: rax = 1 if letter, 0 if not
; -----------------------------------------------------------------------------
util_is_alpha:
    ; Check ASCII letters
    cmp     dil, 'a'
    jb      .check_upper
    cmp     dil, 'z'
    jbe     .yes
.check_upper:
    cmp     dil, 'A'
    jb      .check_underscore
    cmp     dil, 'Z'
    jbe     .yes
.check_underscore:
    cmp     dil, '_'
    je      .yes
    ; Check for UTF-8 lead byte (Spanish accented chars)
    cmp     dil, 0xC3
    je      .yes                    ; Could be á, é, í, ó, ú, ñ, etc.
    cmp     dil, 0xC2
    je      .yes
    xor     rax, rax
    ret
.yes:
    mov     rax, 1
    ret

; -----------------------------------------------------------------------------
; util_is_alnum - Check if character is alphanumeric
; -----------------------------------------------------------------------------
; Input:  rdi = character
; Output: rax = 1 if alphanumeric, 0 if not
; -----------------------------------------------------------------------------
util_is_alnum:
    push    rdi
    call    util_is_alpha
    test    rax, rax
    jnz     .done
    pop     rdi
    push    rdi
    call    util_is_digit
.done:
    add     rsp, 8
    ret

; -----------------------------------------------------------------------------
; util_is_space - Check if character is whitespace
; -----------------------------------------------------------------------------
; Input:  rdi = character
; Output: rax = 1 if whitespace, 0 if not
; -----------------------------------------------------------------------------
util_is_space:
    cmp     dil, ' '
    je      .yes
    cmp     dil, 9                  ; tab
    je      .yes
    cmp     dil, 13                 ; carriage return
    je      .yes
    xor     rax, rax
    ret
.yes:
    mov     rax, 1
    ret

; -----------------------------------------------------------------------------
; util_parse_int - Parse integer from string
; -----------------------------------------------------------------------------
; Input:  rdi = string pointer
;         rsi = pointer to store end position
; Output: rax = parsed value
;         Updates *rsi to point past last digit
; -----------------------------------------------------------------------------
util_parse_int:
    push    rbx
    push    r12
    xor     rax, rax                ; result = 0
    xor     r12, r12                ; negative flag
    mov     rbx, rdi                ; current position

    ; Check for minus sign
    cmp     byte [rbx], '-'
    jne     .check_hex
    inc     r12                     ; negative = true
    inc     rbx

.check_hex:
    ; Check for 0x prefix (hex number)
    cmp     byte [rbx], '0'
    jne     .parse_digits
    cmp     byte [rbx + 1], 'x'
    je      .parse_hex
    cmp     byte [rbx + 1], 'X'
    je      .parse_hex
    jmp     .parse_digits

.parse_hex:
    add     rbx, 2                  ; Skip "0x"
.parse_hex_loop:
    movzx   ecx, byte [rbx]
    ; Check 0-9
    cmp     cl, '0'
    jb      .done
    cmp     cl, '9'
    jbe     .hex_09
    ; Check a-f
    cmp     cl, 'a'
    jb      .check_upper
    cmp     cl, 'f'
    ja      .done
    sub     cl, 'a'
    add     cl, 10
    jmp     .hex_add
.check_upper:
    ; Check A-F
    cmp     cl, 'A'
    jb      .done
    cmp     cl, 'F'
    ja      .done
    sub     cl, 'A'
    add     cl, 10
    jmp     .hex_add
.hex_09:
    sub     cl, '0'
.hex_add:
    shl     rax, 4
    add     rax, rcx
    inc     rbx
    jmp     .parse_hex_loop

.parse_digits:
    movzx   ecx, byte [rbx]
    cmp     cl, '0'
    jb      .done
    cmp     cl, '9'
    ja      .done

    ; result = result * 10 + digit
    imul    rax, 10
    sub     cl, '0'
    add     rax, rcx
    inc     rbx
    jmp     .parse_digits

.done:
    ; Apply sign
    test    r12, r12
    jz      .store_end
    neg     rax

.store_end:
    test    rsi, rsi
    jz      .return
    mov     [rsi], rbx              ; Store end position

.return:
    pop     r12
    pop     rbx
    ret

; -----------------------------------------------------------------------------
; util_int_to_str - Convert integer to string
; -----------------------------------------------------------------------------
; Input:  rdi = value
;         rsi = buffer pointer
;         rdx = buffer size
; Output: rax = length of string
; -----------------------------------------------------------------------------
util_int_to_str:
    push    rbx
    push    r12
    push    r13

    mov     r12, rsi                ; buffer
    mov     r13, rdx                ; size
    xor     rbx, rbx                ; length

    ; Handle negative
    test    rdi, rdi
    jns     .positive
    mov     byte [r12], '-'
    inc     r12
    inc     rbx
    neg     rdi

.positive:
    ; Handle zero
    test    rdi, rdi
    jnz     .convert
    mov     byte [r12], '0'
    inc     rbx
    jmp     .null_terminate

.convert:
    ; Convert digits (in reverse)
    mov     rax, rdi
    lea     rsi, [r12 + 20]         ; End of temp area
    mov     rcx, rsi                ; Save end

.digit_loop:
    test    rax, rax
    jz      .reverse
    xor     rdx, rdx
    mov     r8, 10
    div     r8                      ; rax = quotient, rdx = remainder
    add     dl, '0'
    dec     rsi
    mov     [rsi], dl
    jmp     .digit_loop

.reverse:
    ; Copy digits from temp to buffer
.copy_loop:
    cmp     rsi, rcx
    jge     .null_terminate
    mov     al, [rsi]
    mov     [r12], al
    inc     rsi
    inc     r12
    inc     rbx
    jmp     .copy_loop

.null_terminate:
    mov     byte [r12], 0
    mov     rax, rbx

    pop     r13
    pop     r12
    pop     rbx
    ret

; =============================================================================
; END OF FILE
; =============================================================================
