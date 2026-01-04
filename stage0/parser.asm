; =============================================================================
; MEDELLIN.COL - STAGE 0: PARSER
; =============================================================================
; Recursive descent parser for Medellin.Col
; Builds AST from token stream
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern lexer_next
extern lexer_peek
extern lexer_expect
extern error_report
extern error_line
extern error_column
extern util_memcpy

; Import token constants
extern token_buffer
extern token_count
extern current_token

; Token structure offsets
%define TOKEN_TYPE          0
%define TOKEN_VALUE         8
%define TOKEN_LINE          16
%define TOKEN_COLUMN        20
%define TOKEN_SIZE          24

; Token types from lexer
%define TOKEN_EOF           0
%define TOKEN_NUMERO        1
%define TOKEN_TEXTO         2
%define TOKEN_VERDAD        3
%define TOKEN_FALSO         4
%define TOKEN_IDENT         10
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
%define TOKEN_KW_NADA       123

; -----------------------------------------------------------------------------
; AST Node Types
; -----------------------------------------------------------------------------
%define AST_PROGRAMA        1
%define AST_PARCERO         2
%define AST_PARAMETRO       3
%define AST_VARIABLE        4
%define AST_BLOQUE          20
%define AST_SI              21
%define AST_MIENTRAS        22
%define AST_DESDE           23
%define AST_DEVUELVASE      24
%define AST_DIGA            25
%define AST_ASIGNACION      26
%define AST_EXPR_STMT       27
%define AST_BINARIO         40
%define AST_UNARIO          41
%define AST_LLAMADA         42
%define AST_IDENT           43
%define AST_NUMERO_LIT      44
%define AST_TEXTO_LIT       45
%define AST_BOOL_LIT        46

; -----------------------------------------------------------------------------
; AST Node Sizes
; -----------------------------------------------------------------------------
; Header: kind(1) + flags(1) + padding(6) + type_id(8) = 16 bytes
%define AST_HEADER_SIZE     16

; AST_PROGRAMA: header(16) + functions(8) + func_count(8) = 32
%define AST_PROGRAMA_SIZE   32
%define AST_PROGRAMA_FUNCS  16
%define AST_PROGRAMA_COUNT  24

; AST_PARCERO: header(16) + name(8) + params(8) + param_count(8) +
;              return_type(8) + body(8) = 56
%define AST_PARCERO_SIZE    56
%define AST_PARCERO_NAME    16
%define AST_PARCERO_PARAMS  24
%define AST_PARCERO_PCOUNT  32
%define AST_PARCERO_RETTYPE 40
%define AST_PARCERO_BODY    48

; AST_PARAMETRO: header(16) + name(8) + type(8) = 32
%define AST_PARAMETRO_SIZE  32
%define AST_PARAMETRO_NAME  16
%define AST_PARAMETRO_TYPE  24

; AST_VARIABLE: header(16) + name(8) + type(8) + init(8) = 40
%define AST_VARIABLE_SIZE   40
%define AST_VARIABLE_NAME   16
%define AST_VARIABLE_TYPE   24
%define AST_VARIABLE_INIT   32

; AST_BLOQUE: header(16) + stmts(8) + stmt_count(8) = 32
%define AST_BLOQUE_SIZE     32
%define AST_BLOQUE_STMTS    16
%define AST_BLOQUE_COUNT    24

; AST_SI: header(16) + condition(8) + then_block(8) + else_block(8) = 40
%define AST_SI_SIZE         40
%define AST_SI_COND         16
%define AST_SI_THEN         24
%define AST_SI_ELSE         32

; AST_MIENTRAS: header(16) + condition(8) + body(8) = 32
%define AST_MIENTRAS_SIZE   32
%define AST_MIENTRAS_COND   16
%define AST_MIENTRAS_BODY   24

; AST_DESDE: header(16) + var(8) + start(8) + end(8) + body(8) = 48
%define AST_DESDE_SIZE      48
%define AST_DESDE_VAR       16
%define AST_DESDE_START     24
%define AST_DESDE_END       32
%define AST_DESDE_BODY      40

; AST_DEVUELVASE: header(16) + value(8) = 24
%define AST_DEVUELVASE_SIZE 24
%define AST_DEVUELVASE_VAL  16

; AST_DIGA: header(16) + value(8) = 24
%define AST_DIGA_SIZE       24
%define AST_DIGA_VAL        16

; AST_ASIGNACION: header(16) + target(8) + value(8) = 32
%define AST_ASIGNACION_SIZE 32
%define AST_ASIGNACION_TGT  16
%define AST_ASIGNACION_VAL  24

; AST_BINARIO: header(16) + op(8) + left(8) + right(8) = 40
%define AST_BINARIO_SIZE    40
%define AST_BINARIO_OP      16
%define AST_BINARIO_LEFT    24
%define AST_BINARIO_RIGHT   32

; AST_UNARIO: header(16) + op(8) + operand(8) = 32
%define AST_UNARIO_SIZE     32
%define AST_UNARIO_OP       16
%define AST_UNARIO_OPERAND  24

; AST_LLAMADA: header(16) + callee(8) + args(8) + arg_count(8) = 40
%define AST_LLAMADA_SIZE    40
%define AST_LLAMADA_CALLEE  16
%define AST_LLAMADA_ARGS    24
%define AST_LLAMADA_COUNT   32

; AST_IDENT: header(16) + name(8) = 24
%define AST_IDENT_SIZE      24
%define AST_IDENT_NAME      16

; AST_NUMERO_LIT: header(16) + value(8) = 24
%define AST_NUMERO_LIT_SIZE 24
%define AST_NUMERO_LIT_VAL  16

; AST_TEXTO_LIT: header(16) + value(8) = 24
%define AST_TEXTO_LIT_SIZE  24
%define AST_TEXTO_LIT_VAL   16

; AST_BOOL_LIT: header(16) + value(1) + padding(7) = 24
%define AST_BOOL_LIT_SIZE   24
%define AST_BOOL_LIT_VAL    16

; Binary operators
%define OP_MAS              1
%define OP_MENOS            2
%define OP_POR              3
%define OP_ENTRE            4
%define OP_MODULO           5
%define OP_IGUAL            6
%define OP_NO_IGUAL         7
%define OP_MAYOR            8
%define OP_MENOR            9
%define OP_MAYOR_IGUAL      10
%define OP_MENOR_IGUAL      11
%define OP_Y                12
%define OP_O                13

; Unary operators
%define OP_NEG              20
%define OP_NO               21

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global parser_parse
global ast_arena
global ast_arena_ptr

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Error messages
    err_expect_parcero:     db "Se esperaba 'parcero'", 0
    err_expect_ident:       db "Se esperaba un identificador", 0
    err_expect_paren_izq:   db "Se esperaba '('", 0
    err_expect_paren_der:   db "Se esperaba ')'", 0
    err_expect_devuelve:    db "Se esperaba 'devuelve'", 0
    err_expect_fin:         db "Se esperaba 'fin'", 0
    err_expect_entonces:    db "Se esperaba 'entonces'", 0
    err_expect_listo:       db "Se esperaba 'listo'", 0
    err_expect_haga:        db "Se esperaba 'haga'", 0
    err_expect_siendo:      db "Se esperaba 'siendo'", 0
    err_expect_hasta:       db "Se esperaba 'hasta'", 0
    err_expect_con:         db "Se esperaba 'con'", 0
    err_expect_es:          db "Se esperaba 'es'", 0
    err_expect_expr:        db "Se esperaba una expresion", 0
    err_expect_type:        db "Se esperaba un tipo", 0
    err_expect_newline:     db "Se esperaba nueva linea", 0
    err_unexpected:         db "Token inesperado", 0

section .bss
    ; AST arena (4MB)
    alignb 8
    ast_arena:          resb 4 * 1024 * 1024
    ast_arena_ptr:      resq 1
    ast_arena_end:      resq 1

    ; Temporary storage for lists
    temp_list:          resq 256        ; Max 256 items in a list
    temp_list_count:    resq 1

section .text

; -----------------------------------------------------------------------------
; parser_parse - Parse entire program
; -----------------------------------------------------------------------------
; Output: rax = pointer to AST_PROGRAMA node, or 0 on error
; -----------------------------------------------------------------------------
parser_parse:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    ; Initialize arena
    lea     rax, [ast_arena]
    mov     [ast_arena_ptr], rax
    lea     rax, [ast_arena + 4 * 1024 * 1024]
    mov     [ast_arena_end], rax

    ; Clear error state
    xor     r15, r15

    ; Allocate program node
    mov     rdi, AST_PROGRAMA_SIZE
    call    arena_alloc
    mov     r12, rax                    ; r12 = program node

    ; Initialize program node
    mov     byte [r12], AST_PROGRAMA
    mov     byte [r12 + 1], 0           ; flags
    mov     qword [r12 + 8], 0          ; type_id
    mov     qword [r12 + AST_PROGRAMA_COUNT], 0

    ; Parse functions
    lea     r13, [temp_list]            ; Function list
    xor     r14, r14                    ; Function count

.parse_loop:
    ; Skip newlines
    call    skip_newlines

    ; Check for EOF
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_EOF
    je      .done

    ; Expect 'parcero'
    cmp     cl, TOKEN_KW_PARCERO
    jne     .error_expect_parcero

    ; Parse function
    call    parse_parcero
    test    rax, rax
    jz      .error

    ; Add to list
    mov     [r13 + r14 * 8], rax
    inc     r14

    jmp     .parse_loop

.done:
    ; Allocate function array
    mov     rdi, r14
    shl     rdi, 3                      ; * 8
    call    arena_alloc
    mov     [r12 + AST_PROGRAMA_FUNCS], rax
    mov     [r12 + AST_PROGRAMA_COUNT], r14

    ; Copy function pointers
    mov     rdi, rax
    lea     rsi, [temp_list]
    mov     rcx, r14
.copy_loop:
    test    rcx, rcx
    jz      .copy_done
    mov     rax, [rsi]
    mov     [rdi], rax
    add     rdi, 8
    add     rsi, 8
    dec     rcx
    jmp     .copy_loop

.copy_done:
    mov     rax, r12
    jmp     .return

.error_expect_parcero:
    lea     rdi, [err_expect_parcero]
    call    error_report

.error:
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
; parse_parcero - Parse function declaration
; -----------------------------------------------------------------------------
; Output: rax = pointer to AST_PARCERO node
; -----------------------------------------------------------------------------
parse_parcero:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 136                    ; Local space for up to 16 params (128) + alignment (8)

    ; Consume 'parcero'
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_PARCERO_SIZE
    call    arena_alloc
    mov     r12, rax                    ; r12 = parcero node

    ; Initialize
    mov     byte [r12], AST_PARCERO
    mov     byte [r12 + 1], 0
    mov     qword [r12 + 8], 0

    ; Expect identifier (function name)
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_IDENT
    jne     .error_expect_ident

    mov     rax, [rax + TOKEN_VALUE]    ; Get name string
    mov     [r12 + AST_PARCERO_NAME], rax
    call    lexer_next                  ; Consume

    ; Expect '('
    mov     rdi, TOKEN_PAREN_IZQ
    call    lexer_expect
    test    rax, rax
    jz      .error_expect_paren

    ; Parse parameters - use stack-local array
    lea     r13, [rbp - 40 - 136]       ; Point to local array (rsp after sub)
    xor     r14, r14                    ; Param count

    ; Check for ')'
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_PAREN_DER
    je      .params_done

.param_loop:
    ; Parse parameter: name: type
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_IDENT
    jne     .error_expect_ident

    mov     rbx, [rax + TOKEN_VALUE]    ; Param name
    call    lexer_next

    ; Expect ':'
    mov     rdi, TOKEN_DOS_PUNTOS
    call    lexer_expect
    test    rax, rax
    jz      .error_expect_colon

    ; Parse type
    call    parse_type
    mov     r15, rax                    ; Type

    ; Create parameter node
    mov     rdi, AST_PARAMETRO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_PARAMETRO
    mov     [rax + AST_PARAMETRO_NAME], rbx
    mov     [rax + AST_PARAMETRO_TYPE], r15

    ; Add to list
    mov     [r13 + r14 * 8], rax
    inc     r14

    ; Check for ',' or ')'
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_COMA
    jne     .params_done
    call    lexer_next                  ; Consume comma
    jmp     .param_loop

.params_done:
    ; Store params
    mov     [r12 + AST_PARCERO_PCOUNT], r14
    test    r14, r14
    jz      .no_params

    ; Allocate param array
    mov     rdi, r14
    shl     rdi, 3
    call    arena_alloc
    mov     [r12 + AST_PARCERO_PARAMS], rax

    ; Copy params from local array (r13)
    mov     rdi, rax
    mov     rsi, r13                    ; Use local array, not temp_list
    mov     rcx, r14
.copy_params:
    test    rcx, rcx
    jz      .no_params
    mov     rax, [rsi]
    mov     [rdi], rax
    add     rdi, 8
    add     rsi, 8
    dec     rcx
    jmp     .copy_params

.no_params:
    ; Expect ')'
    mov     rdi, TOKEN_PAREN_DER
    call    lexer_expect
    test    rax, rax
    jz      .error_expect_paren_r

    ; Check for 'devuelve' (return type)
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_KW_DEVUELVE
    jne     .no_return_type

    call    lexer_next                  ; Consume 'devuelve'
    call    parse_type
    mov     [r12 + AST_PARCERO_RETTYPE], rax
    jmp     .parse_body

.no_return_type:
    mov     qword [r12 + AST_PARCERO_RETTYPE], 0

.parse_body:
    ; Expect newline
    call    skip_newlines_required

    ; Parse body
    call    parse_bloque
    mov     [r12 + AST_PARCERO_BODY], rax

    ; Expect 'fin' 'parcero'
    mov     rdi, TOKEN_KW_FIN
    call    lexer_expect
    test    rax, rax
    jz      .error_expect_fin

    mov     rdi, TOKEN_KW_PARCERO
    call    lexer_expect
    test    rax, rax
    jz      .error_expect_parcero

    ; Success
    mov     rax, r12
    jmp     .return

.error_expect_ident:
    lea     rdi, [err_expect_ident]
    call    error_report
    jmp     .error

.error_expect_paren:
.error_expect_paren_r:
    lea     rdi, [err_expect_paren_izq]
    call    error_report
    jmp     .error

.error_expect_colon:
    lea     rdi, [err_expect_type]
    call    error_report
    jmp     .error

.error_expect_fin:
    lea     rdi, [err_expect_fin]
    call    error_report
    jmp     .error

.error_expect_parcero:
    lea     rdi, [err_expect_parcero]
    call    error_report
    jmp     .error

.error:
    xor     rax, rax

.return:
    add     rsp, 136                    ; Deallocate local param array
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_bloque - Parse statement block
; -----------------------------------------------------------------------------
; Output: rax = pointer to AST_BLOQUE node
; -----------------------------------------------------------------------------
parse_bloque:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 512                    ; Local space for up to 64 statements

    ; Allocate block node
    mov     rdi, AST_BLOQUE_SIZE
    call    arena_alloc
    mov     r12, rax

    mov     byte [r12], AST_BLOQUE
    mov     byte [r12 + 1], 0
    mov     qword [r12 + 8], 0
    mov     qword [r12 + AST_BLOQUE_COUNT], 0

    ; Parse statements - use stack-local array instead of global temp_list
    lea     r13, [rbp - 32 - 512]       ; Point to local array
    xor     r14, r14

.stmt_loop:
    ; Skip newlines
    call    skip_newlines

    ; Check for block terminators
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_EOF
    je      .done
    cmp     cl, TOKEN_KW_FIN
    je      .done
    cmp     cl, TOKEN_KW_LISTO
    je      .done
    cmp     cl, TOKEN_KW_SINO
    je      .done

    ; Parse statement
    call    parse_statement
    test    rax, rax
    jz      .error

    ; Add to list
    mov     [r13 + r14 * 8], rax
    inc     r14

    jmp     .stmt_loop

.done:
    ; Store statements
    mov     [r12 + AST_BLOQUE_COUNT], r14
    test    r14, r14
    jz      .no_stmts

    ; Allocate statement array
    mov     rdi, r14
    shl     rdi, 3
    call    arena_alloc
    mov     [r12 + AST_BLOQUE_STMTS], rax

    ; Copy statements from local array (r13)
    mov     rdi, rax
    mov     rsi, r13                    ; Use local array, not temp_list
    mov     rcx, r14
.copy_stmts:
    test    rcx, rcx
    jz      .no_stmts
    mov     rax, [rsi]
    mov     [rdi], rax
    add     rdi, 8
    add     rsi, 8
    dec     rcx
    jmp     .copy_stmts

.no_stmts:
    mov     rax, r12
    jmp     .return

.error:
    xor     rax, rax

.return:
    add     rsp, 512                    ; Deallocate local array
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_statement - Parse a single statement
; -----------------------------------------------------------------------------
; Output: rax = pointer to statement node
; -----------------------------------------------------------------------------
parse_statement:
    push    rbp
    mov     rbp, rsp
    push    rbx

    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    ; Check statement type
    cmp     cl, TOKEN_KW_SI
    je      .parse_si
    cmp     cl, TOKEN_KW_MIENTRAS
    je      .parse_mientras
    cmp     cl, TOKEN_KW_DESDE
    je      .parse_desde
    cmp     cl, TOKEN_KW_DEVUELVASE
    je      .parse_devuelvase
    cmp     cl, TOKEN_KW_DIGA
    je      .parse_diga
    cmp     cl, TOKEN_KW_NUMERO
    je      .parse_variable
    cmp     cl, TOKEN_KW_TEXTO
    je      .parse_variable
    cmp     cl, TOKEN_KW_BOOLEANO
    je      .parse_variable
    cmp     cl, TOKEN_IDENT
    je      .parse_ident_stmt

    ; Unknown statement
    lea     rdi, [err_unexpected]
    call    error_report
    xor     rax, rax
    jmp     .return

.parse_si:
    call    parse_si
    jmp     .return

.parse_mientras:
    call    parse_mientras
    jmp     .return

.parse_desde:
    call    parse_desde
    jmp     .return

.parse_devuelvase:
    call    parse_devuelvase
    jmp     .return

.parse_diga:
    call    parse_diga
    jmp     .return

.parse_variable:
    call    parse_variable
    jmp     .return

.parse_ident_stmt:
    ; Could be assignment or function call
    call    parse_ident_or_assign
    jmp     .return

.return:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_si - Parse if statement
; -----------------------------------------------------------------------------
parse_si:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    ; Consume 'si'
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_SI_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_SI
    mov     byte [r12 + 1], 0
    mov     qword [r12 + 8], 0
    mov     qword [r12 + AST_SI_ELSE], 0

    ; Parse condition
    call    parse_expression
    test    rax, rax
    jz      .error
    mov     [r12 + AST_SI_COND], rax

    ; Expect 'entonces'
    mov     rdi, TOKEN_KW_ENTONCES
    call    lexer_expect
    test    rax, rax
    jz      .error_entonces

    ; Skip newlines
    call    skip_newlines_required

    ; Parse then block
    call    parse_bloque
    mov     [r12 + AST_SI_THEN], rax

    ; Check for 'si no' (else)
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_KW_SINO
    jne     .check_listo

    call    lexer_next                  ; Consume 'si no'
    call    skip_newlines_required
    call    parse_bloque
    mov     [r12 + AST_SI_ELSE], rax

.check_listo:
    ; Expect 'listo'
    mov     rdi, TOKEN_KW_LISTO
    call    lexer_expect
    test    rax, rax
    jz      .error_listo

    mov     rax, r12
    jmp     .return

.error_entonces:
    lea     rdi, [err_expect_entonces]
    call    error_report
    jmp     .error

.error_listo:
    lea     rdi, [err_expect_listo]
    call    error_report

.error:
    xor     rax, rax

.return:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_mientras - Parse while loop
; -----------------------------------------------------------------------------
parse_mientras:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    ; Consume 'mientras'
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_MIENTRAS_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_MIENTRAS

    ; Parse condition
    call    parse_expression
    mov     [r12 + AST_MIENTRAS_COND], rax

    ; Expect 'haga'
    mov     rdi, TOKEN_KW_HAGA
    call    lexer_expect
    test    rax, rax
    jz      .error_haga

    call    skip_newlines_required

    ; Parse body
    call    parse_bloque
    mov     [r12 + AST_MIENTRAS_BODY], rax

    ; Expect 'listo'
    mov     rdi, TOKEN_KW_LISTO
    call    lexer_expect
    test    rax, rax
    jz      .error_listo

    mov     rax, r12
    jmp     .return

.error_haga:
    lea     rdi, [err_expect_haga]
    call    error_report
    jmp     .error

.error_listo:
    lea     rdi, [err_expect_listo]
    call    error_report

.error:
    xor     rax, rax

.return:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_desde - Parse for loop
; -----------------------------------------------------------------------------
parse_desde:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    ; Consume 'desde'
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_DESDE_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_DESDE

    ; Expect identifier (loop variable)
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_IDENT
    jne     .error_ident

    mov     rax, [rax + TOKEN_VALUE]
    mov     [r12 + AST_DESDE_VAR], rax
    call    lexer_next

    ; Expect 'siendo'
    mov     rdi, TOKEN_KW_SIENDO
    call    lexer_expect
    test    rax, rax
    jz      .error_siendo

    ; Parse start expression
    call    parse_expression
    mov     [r12 + AST_DESDE_START], rax

    ; Expect 'hasta'
    mov     rdi, TOKEN_KW_HASTA
    call    lexer_expect
    test    rax, rax
    jz      .error_hasta

    ; Parse end expression
    call    parse_expression
    mov     [r12 + AST_DESDE_END], rax

    ; Expect 'haga'
    mov     rdi, TOKEN_KW_HAGA
    call    lexer_expect
    test    rax, rax
    jz      .error_haga

    call    skip_newlines_required

    ; Parse body
    call    parse_bloque
    mov     [r12 + AST_DESDE_BODY], rax

    ; Expect 'listo'
    mov     rdi, TOKEN_KW_LISTO
    call    lexer_expect
    test    rax, rax
    jz      .error_listo

    mov     rax, r12
    jmp     .return

.error_ident:
    lea     rdi, [err_expect_ident]
    call    error_report
    jmp     .error

.error_siendo:
    lea     rdi, [err_expect_siendo]
    call    error_report
    jmp     .error

.error_hasta:
    lea     rdi, [err_expect_hasta]
    call    error_report
    jmp     .error

.error_haga:
    lea     rdi, [err_expect_haga]
    call    error_report
    jmp     .error

.error_listo:
    lea     rdi, [err_expect_listo]
    call    error_report

.error:
    xor     rax, rax

.return:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_devuelvase - Parse return statement
; -----------------------------------------------------------------------------
parse_devuelvase:
    push    rbp
    mov     rbp, rsp
    push    r12

    ; Consume 'devuélvase'
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_DEVUELVASE_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_DEVUELVASE
    mov     qword [r12 + AST_DEVUELVASE_VAL], 0

    ; Check for optional 'con' and skip it
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_KW_CON
    jne     .check_expr
    call    lexer_next                  ; Consume 'con'

.check_expr:
    ; Check if next token can start an expression
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_NEWLINE
    je      .done
    cmp     cl, TOKEN_EOF
    je      .done
    cmp     cl, TOKEN_KW_FIN
    je      .done
    cmp     cl, TOKEN_KW_LISTO
    je      .done
    cmp     cl, TOKEN_KW_SINO
    je      .done

    ; Parse return value
    call    parse_expression
    mov     [r12 + AST_DEVUELVASE_VAL], rax

.done:
    mov     rax, r12
    pop     r12
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_diga - Parse print statement
; -----------------------------------------------------------------------------
parse_diga:
    push    rbp
    mov     rbp, rsp
    push    r12

    ; Consume 'diga'
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_DIGA_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_DIGA

    ; Parse value to print
    call    parse_expression
    mov     [r12 + AST_DIGA_VAL], rax

    mov     rax, r12
    pop     r12
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_variable - Parse variable declaration
; -----------------------------------------------------------------------------
parse_variable:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    ; Get type token
    call    lexer_peek
    movzx   ebx, byte [rax + TOKEN_TYPE]
    call    lexer_next

    ; Allocate node
    mov     rdi, AST_VARIABLE_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_VARIABLE
    mov     [r12 + AST_VARIABLE_TYPE], rbx
    mov     qword [r12 + AST_VARIABLE_INIT], 0

    ; Expect identifier
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_IDENT
    jne     .error_ident

    mov     rax, [rax + TOKEN_VALUE]
    mov     [r12 + AST_VARIABLE_NAME], rax
    call    lexer_next

    ; Check for 'es' (initialization)
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_KW_ES
    jne     .done

    call    lexer_next                  ; Consume 'es'

    ; Parse initializer
    call    parse_expression
    mov     [r12 + AST_VARIABLE_INIT], rax

.done:
    mov     rax, r12
    jmp     .return

.error_ident:
    lea     rdi, [err_expect_ident]
    call    error_report
    xor     rax, rax

.return:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_ident_or_assign - Parse identifier statement (assign or call)
; -----------------------------------------------------------------------------
parse_ident_or_assign:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    ; Get identifier
    call    lexer_peek
    mov     rbx, [rax + TOKEN_VALUE]    ; Name
    call    lexer_next

    ; Check next token
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    ; Check for 'es' (assignment)
    cmp     cl, TOKEN_KW_ES
    je      .assignment

    ; Check for '(' (function call)
    cmp     cl, TOKEN_PAREN_IZQ
    je      .call

    ; Just an identifier expression
    mov     rdi, AST_IDENT_SIZE
    call    arena_alloc
    mov     byte [rax], AST_IDENT
    mov     [rax + AST_IDENT_NAME], rbx
    jmp     .return

.assignment:
    call    lexer_next                  ; Consume 'es'

    ; Create ident node for target
    mov     rdi, AST_IDENT_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_IDENT
    mov     [r12 + AST_IDENT_NAME], rbx

    ; Parse value
    call    parse_expression
    mov     rbx, rax                    ; Value

    ; Create assignment node
    mov     rdi, AST_ASIGNACION_SIZE
    call    arena_alloc
    mov     byte [rax], AST_ASIGNACION
    mov     [rax + AST_ASIGNACION_TGT], r12
    mov     [rax + AST_ASIGNACION_VAL], rbx
    jmp     .return

.call:
    ; Create call node - reuse rbx as callee name
    ; First create callee ident
    mov     rdi, AST_IDENT_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_IDENT
    mov     [r12 + AST_IDENT_NAME], rbx

    call    parse_call_args
    ; rax = call node with args set
    mov     [rax + AST_LLAMADA_CALLEE], r12
    jmp     .return

.return:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_call_args - Parse function call arguments
; -----------------------------------------------------------------------------
; Expects '(' already peeked
; Output: rax = AST_LLAMADA node
; -----------------------------------------------------------------------------
parse_call_args:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 128                    ; Local space for up to 16 args

    ; Consume '('
    call    lexer_next

    ; Allocate call node
    mov     rdi, AST_LLAMADA_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_LLAMADA
    mov     qword [r12 + AST_LLAMADA_COUNT], 0

    ; Parse arguments - use stack-local array
    lea     r13, [rbp - 32 - 128]       ; Point to local array
    xor     r14, r14

    ; Check for ')'
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_PAREN_DER
    je      .args_done

.arg_loop:
    call    parse_expression
    mov     [r13 + r14 * 8], rax
    inc     r14

    ; Check for ',' or ')'
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_COMA
    jne     .args_done
    call    lexer_next                  ; Consume comma
    jmp     .arg_loop

.args_done:
    ; Expect ')'
    mov     rdi, TOKEN_PAREN_DER
    call    lexer_expect

    ; Store args
    mov     [r12 + AST_LLAMADA_COUNT], r14
    test    r14, r14
    jz      .no_args

    ; Allocate arg array
    mov     rdi, r14
    shl     rdi, 3
    call    arena_alloc
    mov     [r12 + AST_LLAMADA_ARGS], rax

    ; Copy args from local array (r13)
    mov     rdi, rax
    mov     rsi, r13                    ; Use local array, not temp_list
    mov     rcx, r14
.copy_args:
    test    rcx, rcx
    jz      .no_args
    mov     rax, [rsi]
    mov     [rdi], rax
    add     rdi, 8
    add     rsi, 8
    dec     rcx
    jmp     .copy_args

.no_args:
    mov     rax, r12
    add     rsp, 128                    ; Deallocate local array
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_expression - Parse expression (entry point)
; -----------------------------------------------------------------------------
parse_expression:
    jmp     parse_or

; -----------------------------------------------------------------------------
; parse_or - Parse 'o' (or) expression
; -----------------------------------------------------------------------------
parse_or:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    call    parse_and
    mov     r12, rax

.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_O
    jne     .done

    call    lexer_next

    ; Parse right side
    call    parse_and
    mov     rbx, rax

    ; Create binary node
    mov     rdi, AST_BINARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BINARIO
    mov     qword [rax + AST_BINARIO_OP], OP_O
    mov     [rax + AST_BINARIO_LEFT], r12
    mov     [rax + AST_BINARIO_RIGHT], rbx
    mov     r12, rax
    jmp     .loop

.done:
    mov     rax, r12
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_and - Parse 'y' (and) expression
; -----------------------------------------------------------------------------
parse_and:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    call    parse_equality
    mov     r12, rax

.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_Y
    jne     .done

    call    lexer_next

    call    parse_equality
    mov     rbx, rax

    mov     rdi, AST_BINARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BINARIO
    mov     qword [rax + AST_BINARIO_OP], OP_Y
    mov     [rax + AST_BINARIO_LEFT], r12
    mov     [rax + AST_BINARIO_RIGHT], rbx
    mov     r12, rax
    jmp     .loop

.done:
    mov     rax, r12
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_equality - Parse equality expressions
; -----------------------------------------------------------------------------
parse_equality:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    call    parse_comparison
    mov     r12, rax

.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_IGUAL
    je      .equal
    cmp     cl, TOKEN_NO_IGUAL
    je      .not_equal
    jmp     .done

.equal:
    mov     r13, OP_IGUAL
    jmp     .parse_right

.not_equal:
    mov     r13, OP_NO_IGUAL

.parse_right:
    call    lexer_next
    call    parse_comparison
    mov     rbx, rax

    mov     rdi, AST_BINARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BINARIO
    mov     [rax + AST_BINARIO_OP], r13
    mov     [rax + AST_BINARIO_LEFT], r12
    mov     [rax + AST_BINARIO_RIGHT], rbx
    mov     r12, rax
    jmp     .loop

.done:
    mov     rax, r12
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_comparison - Parse comparison expressions
; -----------------------------------------------------------------------------
parse_comparison:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    call    parse_term
    mov     r12, rax

.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_MAYOR
    je      .greater
    cmp     cl, TOKEN_MENOR
    je      .less
    cmp     cl, TOKEN_MAYOR_IGUAL
    je      .greater_eq
    cmp     cl, TOKEN_MENOR_IGUAL
    je      .less_eq
    jmp     .done

.greater:
    mov     r13, OP_MAYOR
    jmp     .parse_right
.less:
    mov     r13, OP_MENOR
    jmp     .parse_right
.greater_eq:
    mov     r13, OP_MAYOR_IGUAL
    jmp     .parse_right
.less_eq:
    mov     r13, OP_MENOR_IGUAL

.parse_right:
    call    lexer_next
    call    parse_term
    mov     rbx, rax

    mov     rdi, AST_BINARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BINARIO
    mov     [rax + AST_BINARIO_OP], r13
    mov     [rax + AST_BINARIO_LEFT], r12
    mov     [rax + AST_BINARIO_RIGHT], rbx
    mov     r12, rax
    jmp     .loop

.done:
    mov     rax, r12
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_term - Parse additive expressions
; -----------------------------------------------------------------------------
parse_term:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    call    parse_factor
    mov     r12, rax

.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_MAS
    je      .add
    cmp     cl, TOKEN_MENOS
    je      .sub
    jmp     .done

.add:
    mov     r13, OP_MAS
    jmp     .parse_right
.sub:
    mov     r13, OP_MENOS

.parse_right:
    call    lexer_next
    call    parse_factor
    mov     rbx, rax

    mov     rdi, AST_BINARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BINARIO
    mov     [rax + AST_BINARIO_OP], r13
    mov     [rax + AST_BINARIO_LEFT], r12
    mov     [rax + AST_BINARIO_RIGHT], rbx
    mov     r12, rax
    jmp     .loop

.done:
    mov     rax, r12
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_factor - Parse multiplicative expressions
; -----------------------------------------------------------------------------
parse_factor:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    call    parse_unary
    mov     r12, rax

.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_POR
    je      .mul
    cmp     cl, TOKEN_ENTRE
    je      .div
    cmp     cl, TOKEN_MODULO
    je      .mod
    jmp     .done

.mul:
    mov     r13, OP_POR
    jmp     .parse_right
.div:
    mov     r13, OP_ENTRE
    jmp     .parse_right
.mod:
    mov     r13, OP_MODULO

.parse_right:
    call    lexer_next
    call    parse_unary
    mov     rbx, rax

    mov     rdi, AST_BINARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BINARIO
    mov     [rax + AST_BINARIO_OP], r13
    mov     [rax + AST_BINARIO_LEFT], r12
    mov     [rax + AST_BINARIO_RIGHT], rbx
    mov     r12, rax
    jmp     .loop

.done:
    mov     rax, r12
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_unary - Parse unary expressions
; -----------------------------------------------------------------------------
parse_unary:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_MENOS
    je      .neg
    cmp     cl, TOKEN_NO
    je      .not

    ; Not a unary operator
    call    parse_primary
    jmp     .return

.neg:
    mov     r12, OP_NEG
    jmp     .parse_operand

.not:
    mov     r12, OP_NO

.parse_operand:
    call    lexer_next
    call    parse_unary                 ; Recursive for chained unary
    mov     rbx, rax

    mov     rdi, AST_UNARIO_SIZE
    call    arena_alloc
    mov     byte [rax], AST_UNARIO
    mov     [rax + AST_UNARIO_OP], r12
    mov     [rax + AST_UNARIO_OPERAND], rbx

.return:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_primary - Parse primary expressions
; -----------------------------------------------------------------------------
parse_primary:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    mov     rbx, [rax + TOKEN_VALUE]

    cmp     cl, TOKEN_NUMERO
    je      .number
    cmp     cl, TOKEN_TEXTO
    je      .string
    cmp     cl, TOKEN_VERDAD
    je      .true
    cmp     cl, TOKEN_FALSO
    je      .false
    cmp     cl, TOKEN_IDENT
    je      .ident
    cmp     cl, TOKEN_PAREN_IZQ
    je      .paren

    ; Error
    lea     rdi, [err_expect_expr]
    call    error_report
    xor     rax, rax
    jmp     .return

.number:
    call    lexer_next
    mov     rdi, AST_NUMERO_LIT_SIZE
    call    arena_alloc
    mov     byte [rax], AST_NUMERO_LIT
    mov     [rax + AST_NUMERO_LIT_VAL], rbx
    jmp     .return

.string:
    call    lexer_next
    mov     rdi, AST_TEXTO_LIT_SIZE
    call    arena_alloc
    mov     byte [rax], AST_TEXTO_LIT
    mov     [rax + AST_TEXTO_LIT_VAL], rbx
    jmp     .return

.true:
    call    lexer_next
    mov     rdi, AST_BOOL_LIT_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BOOL_LIT
    mov     byte [rax + AST_BOOL_LIT_VAL], 1
    jmp     .return

.false:
    call    lexer_next
    mov     rdi, AST_BOOL_LIT_SIZE
    call    arena_alloc
    mov     byte [rax], AST_BOOL_LIT
    mov     byte [rax + AST_BOOL_LIT_VAL], 0
    jmp     .return

.ident:
    call    lexer_next

    ; Check for function call
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_PAREN_IZQ
    je      .ident_call

    ; Just an identifier
    mov     rdi, AST_IDENT_SIZE
    call    arena_alloc
    mov     byte [rax], AST_IDENT
    mov     [rax + AST_IDENT_NAME], rbx
    jmp     .return

.ident_call:
    ; Create callee ident
    mov     rdi, AST_IDENT_SIZE
    call    arena_alloc
    mov     r12, rax
    mov     byte [r12], AST_IDENT
    mov     [r12 + AST_IDENT_NAME], rbx

    call    parse_call_args
    mov     [rax + AST_LLAMADA_CALLEE], r12
    jmp     .return

.paren:
    call    lexer_next                  ; Consume '('
    call    parse_expression
    mov     rbx, rax

    mov     rdi, TOKEN_PAREN_DER
    call    lexer_expect

    mov     rax, rbx

.return:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; parse_type - Parse type annotation
; -----------------------------------------------------------------------------
; Output: rax = type token value
; -----------------------------------------------------------------------------
parse_type:
    push    rbp
    mov     rbp, rsp

    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]

    cmp     cl, TOKEN_KW_NUMERO
    je      .valid
    cmp     cl, TOKEN_KW_TEXTO
    je      .valid
    cmp     cl, TOKEN_KW_BOOLEANO
    je      .valid
    cmp     cl, TOKEN_KW_NADA
    je      .valid
    cmp     cl, TOKEN_IDENT
    je      .valid

    ; Error
    lea     rdi, [err_expect_type]
    call    error_report
    xor     rax, rax
    jmp     .return

.valid:
    movzx   rax, cl                     ; Return token type as type id
    push    rax                         ; Save type before consuming token
    call    lexer_next
    pop     rax                         ; Restore type as return value

.return:
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; skip_newlines - Skip newline tokens
; -----------------------------------------------------------------------------
skip_newlines:
.loop:
    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_NEWLINE
    jne     .done
    call    lexer_next
    jmp     .loop
.done:
    ret

; -----------------------------------------------------------------------------
; skip_newlines_required - Skip at least one newline
; -----------------------------------------------------------------------------
skip_newlines_required:
    push    rbp
    mov     rbp, rsp

    call    lexer_peek
    movzx   ecx, byte [rax + TOKEN_TYPE]
    cmp     cl, TOKEN_NEWLINE
    je      .has_newline

    ; No newline - error
    lea     rdi, [err_expect_newline]
    call    error_report
    pop     rbp
    ret

.has_newline:
    call    skip_newlines
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; arena_alloc - Allocate from AST arena
; -----------------------------------------------------------------------------
; Input:  rdi = size in bytes
; Output: rax = pointer to allocated memory (zero-filled)
; -----------------------------------------------------------------------------
arena_alloc:
    push    rbx
    push    rcx
    push    rdi

    ; Align to 8 bytes
    add     rdi, 7
    and     rdi, ~7

    mov     rax, [ast_arena_ptr]
    mov     rbx, rax
    add     rax, rdi

    ; Check overflow
    cmp     rax, [ast_arena_end]
    jge     .overflow

    mov     [ast_arena_ptr], rax

    ; Zero fill
    mov     rdi, rbx
    pop     rcx                         ; Original size
    push    rcx
    xor     rax, rax
.zero_loop:
    test    rcx, rcx
    jz      .zero_done
    mov     byte [rdi], 0
    inc     rdi
    dec     rcx
    jmp     .zero_loop

.zero_done:
    mov     rax, rbx
    pop     rdi
    pop     rcx
    pop     rbx
    ret

.overflow:
    ; Arena exhausted - return NULL
    xor     rax, rax
    pop     rdi
    pop     rcx
    pop     rbx
    ret

; =============================================================================
; END OF FILE
; =============================================================================
