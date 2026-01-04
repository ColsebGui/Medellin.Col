; =============================================================================
; MEDELLIN.COL - STAGE 0: LEXER
; =============================================================================
; Tokenizes Medellin.Col source code
; Handles UTF-8 for Spanish characters (á, é, í, ó, ú, ñ, ü)
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern util_is_digit
extern util_is_alpha
extern util_is_alnum
extern util_is_space
extern util_parse_int
extern util_memcmp
extern strings_intern_len
extern error_report
extern error_line
extern error_column

; -----------------------------------------------------------------------------
; Token types
; -----------------------------------------------------------------------------
%define TOKEN_EOF           0
%define TOKEN_NUMERO        1
%define TOKEN_TEXTO         2
%define TOKEN_VERDAD        3
%define TOKEN_FALSO         4
%define TOKEN_IDENT         10
%define TOKEN_KEYWORD       11
%define TOKEN_MAS           20
%define TOKEN_MENOS         21
%define TOKEN_POR           22
%define TOKEN_ENTRE         23
%define TOKEN_MODULO        24
%define TOKEN_IGUAL         30
%define TOKEN_NO_IGUAL      31
%define TOKEN_MAYOR         32
%define TOKEN_MENOR         33
%define TOKEN_MAYOR_IGUAL   34
%define TOKEN_MENOR_IGUAL   35
%define TOKEN_Y             40
%define TOKEN_O             41
%define TOKEN_NO            42
%define TOKEN_PAREN_IZQ     50
%define TOKEN_PAREN_DER     51
%define TOKEN_CORCHETE_IZQ  52
%define TOKEN_CORCHETE_DER  53
%define TOKEN_DOS_PUNTOS    54
%define TOKEN_COMA          55
%define TOKEN_PUNTO         56
%define TOKEN_NEWLINE       57

; Keyword tokens
%define TOKEN_KW_PARCERO    100
%define TOKEN_KW_FIN        101
%define TOKEN_KW_SI         102
%define TOKEN_KW_ENTONCES   103
%define TOKEN_KW_SINO       104
%define TOKEN_KW_LISTO      105
%define TOKEN_KW_MIENTRAS   106
%define TOKEN_KW_HAGA       107
%define TOKEN_KW_DESDE      108
%define TOKEN_KW_SIENDO     109
%define TOKEN_KW_HASTA      110
%define TOKEN_KW_DEVUELVASE 111
%define TOKEN_KW_CON        112
%define TOKEN_KW_DIGA       113
%define TOKEN_KW_NUMERO     114
%define TOKEN_KW_TEXTO      115
%define TOKEN_KW_BOOLEANO   116
%define TOKEN_KW_ES         117
%define TOKEN_KW_DEVUELVE   120
%define TOKEN_KW_SUME       121
%define TOKEN_KW_QUITE      122
%define TOKEN_KW_NADA       123

; Token structure size
%define TOKEN_SIZE          24

; Token structure offsets
%define TOKEN_TYPE          0
%define TOKEN_VALUE         8
%define TOKEN_LINE          16
%define TOKEN_COLUMN        20

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global lexer_init
global lexer_next
global lexer_peek
global lexer_expect
global token_type_name

; Export token buffer for parser
global token_buffer
global token_count
global current_token

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Keyword table: [string, length, token_type]
    keywords:
        dq kw_parcero,      7,  TOKEN_KW_PARCERO
        dq kw_fin,          3,  TOKEN_KW_FIN
        dq kw_si,           2,  TOKEN_KW_SI
        dq kw_entonces,     8,  TOKEN_KW_ENTONCES
        dq kw_sino,         4,  TOKEN_KW_SINO
        dq kw_listo,        5,  TOKEN_KW_LISTO
        dq kw_mientras,     8,  TOKEN_KW_MIENTRAS
        dq kw_haga,         4,  TOKEN_KW_HAGA
        dq kw_desde,        5,  TOKEN_KW_DESDE
        dq kw_siendo,       6,  TOKEN_KW_SIENDO
        dq kw_hasta,        5,  TOKEN_KW_HASTA
        dq kw_devuelvase,  10,  TOKEN_KW_DEVUELVASE
        dq kw_con,          3,  TOKEN_KW_CON
        dq kw_diga,         4,  TOKEN_KW_DIGA
        dq kw_numero,       6,  TOKEN_KW_NUMERO
        dq kw_texto,        5,  TOKEN_KW_TEXTO
        dq kw_booleano,     8,  TOKEN_KW_BOOLEANO
        dq kw_es,           2,  TOKEN_KW_ES
        dq kw_devuelve,     8,  TOKEN_KW_DEVUELVE
        dq kw_sume,         4,  TOKEN_KW_SUME
        dq kw_quite,        5,  TOKEN_KW_QUITE
        dq kw_nada,         4,  TOKEN_KW_NADA
        dq kw_verdad,       6,  TOKEN_VERDAD
        dq kw_falso,        5,  TOKEN_FALSO
        dq kw_mas,          3,  TOKEN_MAS
        dq kw_menos,        5,  TOKEN_MENOS
        dq kw_por,          3,  TOKEN_POR
        dq kw_entre,        5,  TOKEN_ENTRE
        dq kw_modulo,       6,  TOKEN_MODULO
        dq kw_y,            1,  TOKEN_Y
        dq kw_o,            1,  TOKEN_O
        dq kw_no,           2,  TOKEN_NO
        dq kw_es_igual,     8,  TOKEN_IGUAL
        dq kw_es_mayor,     8,  TOKEN_MAYOR
        dq kw_es_menor,     8,  TOKEN_MENOR
        dq kw_mayor_igual,  11, TOKEN_MAYOR_IGUAL
        dq kw_menor_igual,  11, TOKEN_MENOR_IGUAL
        dq 0, 0, 0          ; End marker

    ; Keyword strings
    kw_parcero:     db "parcero", 0
    kw_fin:         db "fin", 0
    kw_si:          db "si", 0
    kw_entonces:    db "entonces", 0
    kw_sino:        db "sino", 0
    kw_listo:       db "listo", 0
    kw_mientras:    db "mientras", 0
    kw_haga:        db "haga", 0
    kw_desde:       db "desde", 0
    kw_siendo:      db "siendo", 0
    kw_hasta:       db "hasta", 0
    kw_devuelvase:  db "devuelvase", 0
    kw_con:         db "con", 0
    kw_diga:        db "diga", 0
    kw_numero:      db "numero", 0
    kw_texto:       db "texto", 0
    kw_booleano:    db "booleano", 0
    kw_es:          db "es", 0
    kw_devuelve:    db "devuelve", 0
    kw_sume:        db "sume", 0
    kw_quite:       db "quite", 0
    kw_nada:        db "nada", 0
    kw_verdad:      db "verdad", 0
    kw_falso:       db "falso", 0
    kw_mas:         db "mas", 0
    kw_menos:       db "menos", 0
    kw_por:         db "por", 0
    kw_entre:       db "entre", 0
    kw_modulo:      db "modulo", 0
    kw_y:           db "y", 0
    kw_o:           db "o", 0
    kw_no:          db "no", 0
    kw_es_igual:    db "es_igual", 0
    kw_es_mayor:    db "es_mayor", 0
    kw_es_menor:    db "es_menor", 0
    kw_mayor_igual: db "mayor_igual", 0
    kw_menor_igual: db "menor_igual", 0

    ; Error messages
    err_unexpected_char:    db "Caracter inesperado", 0
    err_unterminated_str:   db "Texto sin cerrar", 0

section .bss
    ; Source buffer
    source_ptr:     resq 1          ; Current position in source
    source_end:     resq 1          ; End of source
    source_start:   resq 1          ; Start of source

    ; Token buffer (max 64K tokens)
    alignb 8
    token_buffer:   resb 24 * 65536
    token_count:    resq 1
    current_token:  resq 1          ; Index of current token

    ; Current position
    current_line:   resq 1
    current_col:    resq 1

section .text

; -----------------------------------------------------------------------------
; lexer_init - Initialize lexer with source code
; -----------------------------------------------------------------------------
; Input:  rdi = source buffer pointer
;         rsi = source length
; Output: none
; -----------------------------------------------------------------------------
lexer_init:
    push    rbp
    mov     rbp, rsp

    ; Store source info
    mov     [source_start], rdi
    mov     [source_ptr], rdi
    lea     rax, [rdi + rsi]
    mov     [source_end], rax

    ; Initialize position
    mov     qword [current_line], 1
    mov     qword [current_col], 1

    ; Clear token buffer
    mov     qword [token_count], 0
    mov     qword [current_token], 0

    ; Tokenize entire source
    call    tokenize_all

    pop     rbp
    ret

; -----------------------------------------------------------------------------
; tokenize_all - Tokenize entire source into buffer
; -----------------------------------------------------------------------------
tokenize_all:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    lea     r12, [token_buffer]         ; Token write pointer

.loop:
    ; Skip whitespace (but not newlines)
    call    skip_whitespace

    ; Check for end of source
    mov     rax, [source_ptr]
    cmp     rax, [source_end]
    jge     .eof

    ; Get current character
    movzx   eax, byte [rax]

    ; Check for newline
    cmp     al, 10
    je      .newline

    ; Check for comment
    cmp     al, ';'
    je      .comment

    ; Check for string literal
    cmp     al, '"'
    je      .string

    ; Check for number
    mov     rdi, rax
    call    util_is_digit
    test    rax, rax
    jnz     .number

    ; Check for identifier/keyword
    mov     rax, [source_ptr]
    movzx   edi, byte [rax]
    call    util_is_alpha
    test    rax, rax
    jnz     .identifier

    ; Check for operators and punctuation
    mov     rax, [source_ptr]
    movzx   eax, byte [rax]

    cmp     al, '+'
    je      .op_plus
    cmp     al, '-'
    je      .op_minus
    cmp     al, '*'
    je      .op_star
    cmp     al, '/'
    je      .op_slash
    cmp     al, '%'
    je      .op_percent
    cmp     al, '('
    je      .op_lparen
    cmp     al, ')'
    je      .op_rparen
    cmp     al, '['
    je      .op_lbracket
    cmp     al, ']'
    je      .op_rbracket
    cmp     al, ':'
    je      .op_colon
    cmp     al, ','
    je      .op_comma
    cmp     al, '.'
    je      .op_dot
    cmp     al, '>'
    je      .op_greater
    cmp     al, '<'
    je      .op_less
    cmp     al, '='
    je      .op_equal
    cmp     al, '!'
    je      .op_bang

    ; Unknown character - error
    lea     rdi, [err_unexpected_char]
    call    error_report
    inc     qword [source_ptr]
    jmp     .loop

.newline:
    ; Emit newline token
    mov     byte [r12 + TOKEN_TYPE], TOKEN_NEWLINE
    mov     qword [r12 + TOKEN_VALUE], 0
    mov     eax, [current_line]
    mov     [r12 + TOKEN_LINE], eax
    mov     eax, [current_col]
    mov     [r12 + TOKEN_COLUMN], eax
    add     r12, TOKEN_SIZE
    inc     qword [token_count]

    ; Update position
    inc     qword [current_line]
    mov     qword [current_col], 1
    inc     qword [source_ptr]
    jmp     .loop

.comment:
    ; Skip to end of line
.skip_comment:
    mov     rax, [source_ptr]
    cmp     rax, [source_end]
    jge     .loop
    movzx   eax, byte [rax]
    cmp     al, 10
    je      .loop
    inc     qword [source_ptr]
    jmp     .skip_comment

.string:
    call    scan_string
    ; Token stored by scan_string
    add     r12, TOKEN_SIZE
    inc     qword [token_count]
    jmp     .loop

.number:
    call    scan_number
    add     r12, TOKEN_SIZE
    inc     qword [token_count]
    jmp     .loop

.identifier:
    call    scan_identifier
    add     r12, TOKEN_SIZE
    inc     qword [token_count]
    jmp     .loop

.op_plus:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MAS
    jmp     .single_char_op

.op_minus:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MENOS
    jmp     .single_char_op

.op_star:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_POR
    jmp     .single_char_op

.op_slash:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_ENTRE
    jmp     .single_char_op

.op_percent:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MODULO
    jmp     .single_char_op

.op_lparen:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_PAREN_IZQ
    jmp     .single_char_op

.op_rparen:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_PAREN_DER
    jmp     .single_char_op

.op_lbracket:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_CORCHETE_IZQ
    jmp     .single_char_op

.op_rbracket:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_CORCHETE_DER
    jmp     .single_char_op

.op_colon:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_DOS_PUNTOS
    jmp     .single_char_op

.op_comma:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_COMA
    jmp     .single_char_op

.op_dot:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_PUNTO
    jmp     .single_char_op

.op_greater:
    ; Check for >=
    mov     rax, [source_ptr]
    inc     rax
    cmp     rax, [source_end]
    jge     .just_greater
    cmp     byte [rax], '='
    jne     .just_greater
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MAYOR_IGUAL
    inc     qword [source_ptr]
    jmp     .single_char_op
.just_greater:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MAYOR
    jmp     .single_char_op

.op_less:
    ; Check for <=
    mov     rax, [source_ptr]
    inc     rax
    cmp     rax, [source_end]
    jge     .just_less
    cmp     byte [rax], '='
    jne     .just_less
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MENOR_IGUAL
    inc     qword [source_ptr]
    jmp     .single_char_op
.just_less:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_MENOR
    jmp     .single_char_op

.op_equal:
    ; Check for ==
    mov     rax, [source_ptr]
    inc     rax
    cmp     rax, [source_end]
    jge     .just_equal
    cmp     byte [rax], '='
    jne     .just_equal
    mov     byte [r12 + TOKEN_TYPE], TOKEN_IGUAL
    inc     qword [source_ptr]
    jmp     .single_char_op
.just_equal:
    ; Single = is not valid as operator (use 'es')
    lea     rdi, [err_unexpected_char]
    call    error_report
    jmp     .single_char_op

.op_bang:
    ; Check for !=
    mov     rax, [source_ptr]
    inc     rax
    cmp     rax, [source_end]
    jge     .just_bang
    cmp     byte [rax], '='
    jne     .just_bang
    mov     byte [r12 + TOKEN_TYPE], TOKEN_NO_IGUAL
    inc     qword [source_ptr]
    jmp     .single_char_op
.just_bang:
    mov     byte [r12 + TOKEN_TYPE], TOKEN_NO
    jmp     .single_char_op

.single_char_op:
    mov     qword [r12 + TOKEN_VALUE], 0
    mov     eax, [current_line]
    mov     [r12 + TOKEN_LINE], eax
    mov     eax, [current_col]
    mov     [r12 + TOKEN_COLUMN], eax
    add     r12, TOKEN_SIZE
    inc     qword [token_count]
    inc     qword [source_ptr]
    inc     qword [current_col]
    jmp     .loop

.eof:
    ; Emit EOF token
    mov     byte [r12 + TOKEN_TYPE], TOKEN_EOF
    mov     qword [r12 + TOKEN_VALUE], 0
    mov     eax, [current_line]
    mov     [r12 + TOKEN_LINE], eax
    mov     eax, [current_col]
    mov     [r12 + TOKEN_COLUMN], eax
    inc     qword [token_count]

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; skip_whitespace - Skip spaces and tabs (not newlines)
; -----------------------------------------------------------------------------
skip_whitespace:
.loop:
    mov     rax, [source_ptr]
    cmp     rax, [source_end]
    jge     .done
    movzx   edi, byte [rax]
    cmp     dil, ' '
    je      .skip
    cmp     dil, 9                      ; Tab
    je      .skip
    cmp     dil, 13                     ; CR
    je      .skip
    jmp     .done
.skip:
    inc     qword [source_ptr]
    inc     qword [current_col]
    jmp     .loop
.done:
    ret

; -----------------------------------------------------------------------------
; scan_number - Scan integer literal
; -----------------------------------------------------------------------------
; Uses: r12 = token write pointer
; -----------------------------------------------------------------------------
scan_number:
    push    rbp
    mov     rbp, rsp
    push    rbx

    ; Record position
    mov     eax, [current_line]
    mov     [r12 + TOKEN_LINE], eax
    mov     eax, [current_col]
    mov     [r12 + TOKEN_COLUMN], eax

    ; Parse number
    mov     rdi, [source_ptr]
    lea     rsi, [source_ptr]           ; Store end position back
    call    util_parse_int
    mov     rbx, rax                    ; Save value

    ; Calculate how many chars we consumed
    mov     rax, [source_ptr]
    sub     rax, rdi                    ; This is wrong, let's fix
    ; Actually util_parse_int updates source_ptr via rsi

    ; Store token
    mov     byte [r12 + TOKEN_TYPE], TOKEN_NUMERO
    mov     [r12 + TOKEN_VALUE], rbx

    ; Update column (approximate - count digits)
    mov     rdi, rbx
    test    rdi, rdi
    jns     .count_digits
    neg     rdi
    inc     qword [current_col]         ; For minus sign

.count_digits:
    test    rdi, rdi
    jz      .one_digit
    xor     rcx, rcx
.digit_loop:
    test    rdi, rdi
    jz      .done_digits
    xor     rdx, rdx
    mov     rax, rdi
    mov     r8, 10
    div     r8
    mov     rdi, rax
    inc     rcx
    jmp     .digit_loop
.one_digit:
    mov     rcx, 1
.done_digits:
    add     [current_col], rcx

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; scan_string - Scan string literal
; -----------------------------------------------------------------------------
; Uses: r12 = token write pointer
; -----------------------------------------------------------------------------
scan_string:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r13

    ; Record position
    mov     eax, [current_line]
    mov     [r12 + TOKEN_LINE], eax
    mov     eax, [current_col]
    mov     [r12 + TOKEN_COLUMN], eax

    ; Skip opening quote
    inc     qword [source_ptr]
    inc     qword [current_col]

    ; Remember start
    mov     rbx, [source_ptr]
    xor     r13, r13                    ; Length

.loop:
    mov     rax, [source_ptr]
    cmp     rax, [source_end]
    jge     .unterminated
    movzx   eax, byte [rax]

    ; Check for closing quote
    cmp     al, '"'
    je      .done

    ; Check for newline (error)
    cmp     al, 10
    je      .unterminated

    ; Check for escape sequence
    cmp     al, '\'
    je      .escape

    ; Regular character
    inc     qword [source_ptr]
    inc     qword [current_col]
    inc     r13
    jmp     .loop

.escape:
    ; Skip backslash and next char
    add     qword [source_ptr], 2
    add     qword [current_col], 2
    add     r13, 2                      ; Include escape in length for now
    jmp     .loop

.done:
    ; Skip closing quote
    inc     qword [source_ptr]
    inc     qword [current_col]

    ; Intern string
    mov     rdi, rbx
    mov     rsi, r13
    call    strings_intern_len

    ; Store token
    mov     byte [r12 + TOKEN_TYPE], TOKEN_TEXTO
    mov     [r12 + TOKEN_VALUE], rax

    pop     r13
    pop     rbx
    pop     rbp
    ret

.unterminated:
    lea     rdi, [err_unterminated_str]
    call    error_report

    ; Store empty string token
    mov     byte [r12 + TOKEN_TYPE], TOKEN_TEXTO
    mov     qword [r12 + TOKEN_VALUE], 0

    pop     r13
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; scan_identifier - Scan identifier or keyword
; -----------------------------------------------------------------------------
; Uses: r12 = token write pointer
; -----------------------------------------------------------------------------
scan_identifier:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r13
    push    r14

    ; Record position
    mov     eax, [current_line]
    mov     [r12 + TOKEN_LINE], eax
    mov     eax, [current_col]
    mov     [r12 + TOKEN_COLUMN], eax

    ; Remember start
    mov     rbx, [source_ptr]
    xor     r13, r13                    ; Length

.loop:
    mov     rax, [source_ptr]
    cmp     rax, [source_end]
    jge     .done
    movzx   edi, byte [rax]

    ; Check for UTF-8 continuation byte
    cmp     dil, 0x80
    jb      .check_alnum
    cmp     dil, 0xC0
    jb      .utf8_cont                  ; Continuation byte
    ; UTF-8 lead byte - include it
    inc     qword [source_ptr]
    inc     r13
    jmp     .loop

.utf8_cont:
    ; UTF-8 continuation - include it
    inc     qword [source_ptr]
    inc     r13
    jmp     .loop

.check_alnum:
    call    util_is_alnum
    test    rax, rax
    jz      .done

    inc     qword [source_ptr]
    inc     qword [current_col]
    inc     r13
    jmp     .loop

.done:
    ; Check if it's a keyword
    lea     r14, [keywords]

.keyword_loop:
    mov     rax, [r14]                  ; Keyword string
    test    rax, rax
    jz      .not_keyword

    mov     rcx, [r14 + 8]              ; Keyword length
    cmp     rcx, r13
    jne     .next_keyword

    ; Compare
    mov     rdi, rax
    mov     rsi, rbx
    mov     rdx, r13
    call    util_memcmp
    test    rax, rax
    jz      .is_keyword

.next_keyword:
    add     r14, 24                     ; Next entry (3 qwords)
    jmp     .keyword_loop

.is_keyword:
    ; Store keyword token
    mov     rax, [r14 + 16]             ; Token type
    mov     [r12 + TOKEN_TYPE], al

    ; Intern the string anyway for value
    mov     rdi, rbx
    mov     rsi, r13
    call    strings_intern_len
    mov     [r12 + TOKEN_VALUE], rax

    jmp     .finish

.not_keyword:
    ; Intern identifier
    mov     rdi, rbx
    mov     rsi, r13
    call    strings_intern_len

    ; Store identifier token
    mov     byte [r12 + TOKEN_TYPE], TOKEN_IDENT
    mov     [r12 + TOKEN_VALUE], rax

.finish:
    pop     r14
    pop     r13
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; lexer_next - Get next token
; -----------------------------------------------------------------------------
; Output: rax = pointer to token
; -----------------------------------------------------------------------------
lexer_next:
    mov     rax, [current_token]
    mov     rcx, [token_count]
    cmp     rax, rcx
    jge     .at_end

    ; Get token pointer
    imul    rax, TOKEN_SIZE
    lea     rax, [token_buffer + rax]

    ; Advance
    inc     qword [current_token]
    ret

.at_end:
    ; Return EOF token (last token)
    mov     rax, [token_count]
    dec     rax
    imul    rax, TOKEN_SIZE
    lea     rax, [token_buffer + rax]
    ret

; -----------------------------------------------------------------------------
; lexer_peek - Peek at current token without consuming
; -----------------------------------------------------------------------------
; Output: rax = pointer to token
; -----------------------------------------------------------------------------
lexer_peek:
    mov     rax, [current_token]
    mov     rcx, [token_count]
    cmp     rax, rcx
    jge     .at_end

    imul    rax, TOKEN_SIZE
    lea     rax, [token_buffer + rax]
    ret

.at_end:
    mov     rax, [token_count]
    dec     rax
    imul    rax, TOKEN_SIZE
    lea     rax, [token_buffer + rax]
    ret

; -----------------------------------------------------------------------------
; lexer_expect - Expect a specific token type
; -----------------------------------------------------------------------------
; Input:  rdi = expected token type
; Output: rax = pointer to token, or 0 on mismatch
; -----------------------------------------------------------------------------
lexer_expect:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi                    ; Expected type

    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, bl
    jne     .mismatch

    ; Consume token
    inc     qword [current_token]
    pop     rbx
    pop     rbp
    ret

.mismatch:
    xor     rax, rax
    pop     rbx
    pop     rbp
    ret

; =============================================================================
; END OF FILE
; =============================================================================
