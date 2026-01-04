; =============================================================================
; MEDELLIN.COL - STAGE 0: TYPE CHECKER
; =============================================================================
; Performs semantic analysis and type checking
; Traverses AST and validates types, builds symbol table
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern symbols_init
extern symbols_enter_scope
extern symbols_leave_scope
extern symbols_define
extern symbols_lookup
extern symbols_set_type
extern symbols_get_type
extern error_report

; Symbol kinds
%define SYM_VARIABLE    1
%define SYM_FUNCTION    2
%define SYM_PARAMETER   3

; Symbol flags
%define SYM_FLAG_MUTABLE    0x01
%define SYM_FLAG_INIT       0x02

; -----------------------------------------------------------------------------
; Type IDs
; -----------------------------------------------------------------------------
%define TYPE_UNKNOWN    0
%define TYPE_NUMERO     114
%define TYPE_TEXTO      115
%define TYPE_BOOLEANO   116
%define TYPE_NADA       123
%define TYPE_BYTE       126
%define TYPE_ARREGLO    200

; -----------------------------------------------------------------------------
; AST Node Types (from parser)
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
%define AST_ARREGLO_TIPO    47
%define AST_ARREGLO_ACCESO  48

; AST structure offsets
%define AST_KIND            0
%define AST_TYPE_ID         8

; Program offsets
%define AST_PROGRAMA_FUNCS  16
%define AST_PROGRAMA_COUNT  24

; Parcero offsets
%define AST_PARCERO_NAME    16
%define AST_PARCERO_PARAMS  24
%define AST_PARCERO_PCOUNT  32
%define AST_PARCERO_RETTYPE 40
%define AST_PARCERO_BODY    48

; Parametro offsets
%define AST_PARAMETRO_NAME  16
%define AST_PARAMETRO_TYPE  24

; Variable offsets
%define AST_VARIABLE_NAME   16
%define AST_VARIABLE_TYPE   24
%define AST_VARIABLE_INIT   32

; Bloque offsets
%define AST_BLOQUE_STMTS    16
%define AST_BLOQUE_COUNT    24

; Si offsets
%define AST_SI_COND         16
%define AST_SI_THEN         24
%define AST_SI_ELSE         32

; Mientras offsets
%define AST_MIENTRAS_COND   16
%define AST_MIENTRAS_BODY   24

; Desde offsets
%define AST_DESDE_VAR       16
%define AST_DESDE_START     24
%define AST_DESDE_END       32
%define AST_DESDE_BODY      40

; Devuelvase offsets
%define AST_DEVUELVASE_VAL  16

; Diga offsets
%define AST_DIGA_VAL        16

; Asignacion offsets
%define AST_ASIGNACION_TGT  16
%define AST_ASIGNACION_VAL  24

; Binario offsets
%define AST_BINARIO_OP      16
%define AST_BINARIO_LEFT    24
%define AST_BINARIO_RIGHT   32

; Unario offsets
%define AST_UNARIO_OP       16
%define AST_UNARIO_OPERAND  24

; Llamada offsets
%define AST_LLAMADA_CALLEE  16
%define AST_LLAMADA_ARGS    24
%define AST_LLAMADA_COUNT   32

; Ident offsets
%define AST_IDENT_NAME      16

; Literal offsets
%define AST_LIT_VAL         16

; Arreglo tipo offsets
%define AST_ARREGLO_TIPO_LEN    16
%define AST_ARREGLO_TIPO_ELEM   24

; Arreglo acceso offsets
%define AST_ARREGLO_ACCESO_ARR  16
%define AST_ARREGLO_ACCESO_IDX  24

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
global types_check
global types_get_error_count

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Error messages
    err_type_mismatch:      db "Tipos no coinciden", 0
    err_undefined_var:      db "Variable no definida: ", 0
    err_undefined_func:     db "Funcion no definida: ", 0
    err_redefinition:       db "Redefinicion de: ", 0
    err_wrong_argc:         db "Numero incorrecto de argumentos", 0
    err_not_callable:       db "No es una funcion", 0
    err_not_numeric:        db "Se esperaba tipo numerico", 0
    err_not_boolean:        db "Se esperaba tipo booleano", 0
    err_return_type:        db "Tipo de retorno incorrecto", 0

section .bss
    ; Error count
    error_count:            resq 1

    ; Current function being checked (for return type validation)
    current_function:       resq 1

section .text

; -----------------------------------------------------------------------------
; types_check - Type check an AST
; -----------------------------------------------------------------------------
; Input:  rdi = pointer to AST_PROGRAMA node
; Output: rax = 0 on success, error count on failure
; -----------------------------------------------------------------------------
types_check:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi                    ; Save AST

    ; Initialize
    mov     qword [error_count], 0
    mov     qword [current_function], 0

    ; Initialize symbol table
    call    symbols_init

    ; Check program
    mov     rdi, r12
    call    check_programa

    ; Return error count
    mov     rax, [error_count]

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; types_get_error_count - Get number of type errors
; -----------------------------------------------------------------------------
types_get_error_count:
    mov     rax, [error_count]
    ret

; -----------------------------------------------------------------------------
; check_programa - Check program node
; -----------------------------------------------------------------------------
check_programa:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12, rdi                    ; Program node

    ; First pass: register all functions
    mov     r13, [r12 + AST_PROGRAMA_FUNCS]
    mov     r14, [r12 + AST_PROGRAMA_COUNT]

.register_loop:
    test    r14, r14
    jz      .check_loop_init

    mov     rdi, [r13]
    call    register_function

    add     r13, 8
    dec     r14
    jmp     .register_loop

.check_loop_init:
    ; Second pass: type check function bodies
    mov     r13, [r12 + AST_PROGRAMA_FUNCS]
    mov     r14, [r12 + AST_PROGRAMA_COUNT]

.check_loop:
    test    r14, r14
    jz      .done

    mov     rdi, [r13]
    call    check_parcero

    add     r13, 8
    dec     r14
    jmp     .check_loop

.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; register_function - Register function in symbol table
; -----------------------------------------------------------------------------
register_function:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi                    ; Function node

    ; Get function name
    mov     rdi, [rbx + AST_PARCERO_NAME]
    mov     rsi, SYM_FUNCTION
    mov     rdx, [rbx + AST_PARCERO_RETTYPE]
    xor     rcx, rcx
    call    symbols_define

    test    rax, rax
    jnz     .done

    ; Already defined
    lea     rdi, [err_redefinition]
    call    error_report
    inc     qword [error_count]

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_parcero - Check function body
; -----------------------------------------------------------------------------
check_parcero:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12, rdi                    ; Function node
    mov     [current_function], r12

    ; Enter function scope
    call    symbols_enter_scope

    ; Register parameters
    mov     r13, [r12 + AST_PARCERO_PARAMS]
    mov     r14, [r12 + AST_PARCERO_PCOUNT]

.param_loop:
    test    r14, r14
    jz      .check_body

    mov     rbx, [r13]                  ; Parameter node
    mov     rdi, [rbx + AST_PARAMETRO_NAME]
    mov     rsi, SYM_PARAMETER
    mov     rdx, [rbx + AST_PARAMETRO_TYPE]
    mov     rcx, SYM_FLAG_INIT          ; Parameters are initialized
    call    symbols_define

    add     r13, 8
    dec     r14
    jmp     .param_loop

.check_body:
    ; Check body
    mov     rdi, [r12 + AST_PARCERO_BODY]
    call    check_bloque

    ; Leave scope
    call    symbols_leave_scope

    mov     qword [current_function], 0

    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_bloque - Check block of statements
; -----------------------------------------------------------------------------
check_bloque:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi                    ; Block node

    mov     rbx, [r12 + AST_BLOQUE_STMTS]
    mov     r13, [r12 + AST_BLOQUE_COUNT]

.loop:
    test    r13, r13
    jz      .done

    mov     rdi, [rbx]
    call    check_statement

    add     rbx, 8
    dec     r13
    jmp     .loop

.done:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_statement - Check a statement
; -----------------------------------------------------------------------------
check_statement:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi
    movzx   eax, byte [rbx + AST_KIND]

    cmp     al, AST_VARIABLE
    je      .variable
    cmp     al, AST_SI
    je      .si
    cmp     al, AST_MIENTRAS
    je      .mientras
    cmp     al, AST_DESDE
    je      .desde
    cmp     al, AST_DEVUELVASE
    je      .devuelvase
    cmp     al, AST_DIGA
    je      .diga
    cmp     al, AST_ASIGNACION
    je      .asignacion
    cmp     al, AST_LLAMADA
    je      .llamada

    ; Unknown - skip
    jmp     .done

.variable:
    call    check_variable
    jmp     .done

.si:
    call    check_si
    jmp     .done

.mientras:
    call    check_mientras
    jmp     .done

.desde:
    call    check_desde
    jmp     .done

.devuelvase:
    call    check_devuelvase
    jmp     .done

.diga:
    call    check_diga
    jmp     .done

.asignacion:
    call    check_asignacion
    jmp     .done

.llamada:
    call    check_expression
    jmp     .done

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_variable - Check variable declaration
; -----------------------------------------------------------------------------
check_variable:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi                    ; Variable node

    ; Define in symbol table
    mov     rdi, [r12 + AST_VARIABLE_NAME]
    mov     rsi, SYM_VARIABLE
    mov     rdx, [r12 + AST_VARIABLE_TYPE]
    mov     rcx, SYM_FLAG_MUTABLE
    call    symbols_define

    test    rax, rax
    jnz     .check_init

    ; Redefinition error
    lea     rdi, [err_redefinition]
    call    error_report
    inc     qword [error_count]
    jmp     .done

.check_init:
    mov     rbx, rax                    ; Save symbol

    ; Check initializer if present
    mov     rdi, [r12 + AST_VARIABLE_INIT]
    test    rdi, rdi
    jz      .done

    call    check_expression

    ; Verify type matches (allow byte/numero interop)
    mov     rcx, [r12 + AST_VARIABLE_TYPE]
    mov     rdx, [r12 + AST_VARIABLE_INIT]
    mov     rdx, [rdx + AST_TYPE_ID]

    cmp     rcx, rdx
    je      .done

    ; Check if both are numeric types (byte or numero)
    mov     rdi, rcx
    mov     rsi, rdx
    call    types_numeric_compat
    test    rax, rax
    jnz     .done

    ; Type mismatch
    lea     rdi, [err_type_mismatch]
    call    error_report
    inc     qword [error_count]

.done:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_si - Check if statement
; -----------------------------------------------------------------------------
check_si:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Check condition
    mov     rdi, [rbx + AST_SI_COND]
    call    check_expression

    ; Verify boolean
    mov     rdi, [rbx + AST_SI_COND]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_BOOLEANO
    je      .check_then

    lea     rdi, [err_not_boolean]
    call    error_report
    inc     qword [error_count]

.check_then:
    ; Enter scope for then block
    call    symbols_enter_scope
    mov     rdi, [rbx + AST_SI_THEN]
    call    check_bloque
    call    symbols_leave_scope

    ; Check else if present
    mov     rdi, [rbx + AST_SI_ELSE]
    test    rdi, rdi
    jz      .done

    call    symbols_enter_scope
    mov     rdi, [rbx + AST_SI_ELSE]
    call    check_bloque
    call    symbols_leave_scope

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_mientras - Check while loop
; -----------------------------------------------------------------------------
check_mientras:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Check condition
    mov     rdi, [rbx + AST_MIENTRAS_COND]
    call    check_expression

    ; Verify boolean
    mov     rdi, [rbx + AST_MIENTRAS_COND]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_BOOLEANO
    je      .check_body

    lea     rdi, [err_not_boolean]
    call    error_report
    inc     qword [error_count]

.check_body:
    call    symbols_enter_scope
    mov     rdi, [rbx + AST_MIENTRAS_BODY]
    call    check_bloque
    call    symbols_leave_scope

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_desde - Check for loop
; -----------------------------------------------------------------------------
check_desde:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     rbx, rdi

    ; Enter loop scope
    call    symbols_enter_scope

    ; Define loop variable
    mov     rdi, [rbx + AST_DESDE_VAR]
    mov     rsi, SYM_VARIABLE
    mov     rdx, TYPE_NUMERO
    mov     rcx, SYM_FLAG_INIT
    call    symbols_define

    ; Check start expression
    mov     rdi, [rbx + AST_DESDE_START]
    call    check_expression

    ; Verify numeric
    mov     rdi, [rbx + AST_DESDE_START]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_NUMERO
    je      .check_end

    lea     rdi, [err_not_numeric]
    call    error_report
    inc     qword [error_count]

.check_end:
    ; Check end expression
    mov     rdi, [rbx + AST_DESDE_END]
    call    check_expression

    ; Verify numeric
    mov     rdi, [rbx + AST_DESDE_END]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_NUMERO
    je      .check_body

    lea     rdi, [err_not_numeric]
    call    error_report
    inc     qword [error_count]

.check_body:
    mov     rdi, [rbx + AST_DESDE_BODY]
    call    check_bloque

    call    symbols_leave_scope

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_devuelvase - Check return statement
; -----------------------------------------------------------------------------
check_devuelvase:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Check return value if present
    mov     rdi, [rbx + AST_DEVUELVASE_VAL]
    test    rdi, rdi
    jz      .check_void

    call    check_expression

    ; Compare with function return type
    mov     rax, [current_function]
    test    rax, rax
    jz      .done

    mov     rcx, [rax + AST_PARCERO_RETTYPE]
    mov     rax, [rbx + AST_DEVUELVASE_VAL]
    mov     rdx, [rax + AST_TYPE_ID]

    cmp     rcx, rdx
    je      .done

    ; Check if both are numeric types (allow byte/numero interop)
    mov     rdi, rcx
    mov     rsi, rdx
    call    types_numeric_compat
    test    rax, rax
    jnz     .done

    lea     rdi, [err_return_type]
    call    error_report
    inc     qword [error_count]
    jmp     .done

.check_void:
    ; Check if function expects void
    mov     rax, [current_function]
    test    rax, rax
    jz      .done

    mov     rcx, [rax + AST_PARCERO_RETTYPE]
    test    rcx, rcx
    jz      .done
    cmp     rcx, TYPE_NADA
    je      .done

    lea     rdi, [err_return_type]
    call    error_report
    inc     qword [error_count]

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_diga - Check print statement
; -----------------------------------------------------------------------------
check_diga:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Check expression
    mov     rdi, [rbx + AST_DIGA_VAL]
    call    check_expression

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_asignacion - Check assignment
; -----------------------------------------------------------------------------
check_asignacion:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     rbx, rdi

    ; Check target - could be AST_IDENT or AST_ARREGLO_ACCESO
    mov     rdi, [rbx + AST_ASIGNACION_TGT]
    movzx   eax, byte [rdi]
    cmp     al, AST_ARREGLO_ACCESO
    je      .array_target

    ; Simple variable - get name directly
    mov     rdi, [rdi + AST_IDENT_NAME]
    jmp     .lookup_target

.array_target:
    ; Array access - get name from nested AST_IDENT
    mov     rdi, [rdi + AST_ARREGLO_ACCESO_ARR]
    mov     rdi, [rdi + AST_IDENT_NAME]

.lookup_target:
    call    symbols_lookup

    test    rax, rax
    jnz     .check_value

    lea     rdi, [err_undefined_var]
    call    error_report
    inc     qword [error_count]
    jmp     .done

.check_value:
    mov     r12, rax                    ; Save symbol

    ; Check value expression
    mov     rdi, [rbx + AST_ASIGNACION_VAL]
    call    check_expression

    ; For array targets, also check the index
    mov     rdi, [rbx + AST_ASIGNACION_TGT]
    movzx   eax, byte [rdi]
    cmp     al, AST_ARREGLO_ACCESO
    jne     .check_type

    ; Check index expression
    push    r12
    mov     rdi, [rdi + AST_ARREGLO_ACCESO_IDX]
    call    check_expression
    pop     r12

.check_type:
    ; Get symbol type
    mov     rdi, r12
    call    symbols_get_type
    mov     rcx, rax

    ; Get expression type
    mov     rdi, [rbx + AST_ASIGNACION_VAL]
    mov     rdx, [rdi + AST_TYPE_ID]

    ; For array assignment, simplified type check (element is numero or byte)
    cmp     qword rcx, 0x1000           ; If type is a pointer (array type)
    jae     .check_array_elem

    cmp     rcx, rdx
    je      .done

    ; Check if both are numeric (byte/numero compatible)
    mov     rdi, rcx
    mov     rsi, rdx
    call    types_numeric_compat
    test    rax, rax
    jnz     .done
    jmp     .type_error

.check_array_elem:
    ; Array element assignment - value should be numeric (numero or byte)
    cmp     rdx, TYPE_NUMERO
    je      .done
    cmp     rdx, TYPE_BYTE
    je      .done

.type_error:
    lea     rdi, [err_type_mismatch]
    call    error_report
    inc     qword [error_count]

.done:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_expression - Type check an expression
; -----------------------------------------------------------------------------
; Input:  rdi = expression node
; Output: Sets type_id in the node
; -----------------------------------------------------------------------------
check_expression:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi
    movzx   eax, byte [rbx + AST_KIND]

    cmp     al, AST_NUMERO_LIT
    je      .numero
    cmp     al, AST_TEXTO_LIT
    je      .texto
    cmp     al, AST_BOOL_LIT
    je      .bool
    cmp     al, AST_IDENT
    je      .ident
    cmp     al, AST_BINARIO
    je      .binario
    cmp     al, AST_UNARIO
    je      .unario
    cmp     al, AST_LLAMADA
    je      .llamada
    cmp     al, AST_ARREGLO_ACCESO
    je      .arreglo_acceso

    ; Unknown - set to unknown type
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .done

.numero:
    mov     qword [rbx + AST_TYPE_ID], TYPE_NUMERO
    jmp     .done

.texto:
    mov     qword [rbx + AST_TYPE_ID], TYPE_TEXTO
    jmp     .done

.bool:
    mov     qword [rbx + AST_TYPE_ID], TYPE_BOOLEANO
    jmp     .done

.ident:
    call    check_ident
    jmp     .done

.binario:
    call    check_binario
    jmp     .done

.unario:
    call    check_unario
    jmp     .done

.llamada:
    call    check_llamada
    jmp     .done

.arreglo_acceso:
    ; Check array access - verify array is defined and index is numeric
    push    rbx
    push    r12

    mov     r12, rbx                    ; Save AST_ARREGLO_ACCESO node

    ; Look up array variable in symbol table
    mov     rdi, [r12 + AST_ARREGLO_ACCESO_ARR]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    symbols_lookup
    test    rax, rax
    jnz     .arreglo_found

    ; Array not defined
    lea     rdi, [err_undefined_var]
    call    error_report
    inc     qword [error_count]
    mov     qword [r12 + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .arreglo_done

.arreglo_found:
    ; Check index expression
    mov     rdi, [r12 + AST_ARREGLO_ACCESO_IDX]
    call    check_expression

    ; Set result type to numero (simplified for Stage 0)
    mov     qword [r12 + AST_TYPE_ID], TYPE_NUMERO

.arreglo_done:
    pop     r12
    pop     rbx
    jmp     .done

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_ident - Check identifier expression
; -----------------------------------------------------------------------------
check_ident:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Look up in symbol table
    mov     rdi, [rbx + AST_IDENT_NAME]
    call    symbols_lookup

    test    rax, rax
    jnz     .found

    lea     rdi, [err_undefined_var]
    call    error_report
    inc     qword [error_count]
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .done

.found:
    ; Get type from symbol
    mov     rdi, rax
    call    symbols_get_type
    mov     [rbx + AST_TYPE_ID], rax

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_binario - Check binary expression
; -----------------------------------------------------------------------------
check_binario:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     rbx, rdi

    ; Check left operand
    mov     rdi, [rbx + AST_BINARIO_LEFT]
    call    check_expression

    ; Check right operand
    mov     rdi, [rbx + AST_BINARIO_RIGHT]
    call    check_expression

    ; Get operator
    mov     rax, [rbx + AST_BINARIO_OP]

    ; Arithmetic operators require numeric
    cmp     rax, OP_MODULO
    jle     .arithmetic

    ; Comparison operators
    cmp     rax, OP_MENOR_IGUAL
    jle     .comparison

    ; Logical operators require boolean
    jmp     .logical

.arithmetic:
    ; Check both operands are numeric
    mov     rdi, [rbx + AST_BINARIO_LEFT]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_NUMERO
    jne     .type_error_numeric

    mov     rdi, [rbx + AST_BINARIO_RIGHT]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_NUMERO
    jne     .type_error_numeric

    mov     qword [rbx + AST_TYPE_ID], TYPE_NUMERO
    jmp     .done

.comparison:
    ; Result is boolean
    mov     qword [rbx + AST_TYPE_ID], TYPE_BOOLEANO
    jmp     .done

.logical:
    ; Check both operands are boolean
    mov     rdi, [rbx + AST_BINARIO_LEFT]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_BOOLEANO
    jne     .type_error_boolean

    mov     rdi, [rbx + AST_BINARIO_RIGHT]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_BOOLEANO
    jne     .type_error_boolean

    mov     qword [rbx + AST_TYPE_ID], TYPE_BOOLEANO
    jmp     .done

.type_error_numeric:
    lea     rdi, [err_not_numeric]
    call    error_report
    inc     qword [error_count]
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .done

.type_error_boolean:
    lea     rdi, [err_not_boolean]
    call    error_report
    inc     qword [error_count]
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN

.done:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_unario - Check unary expression
; -----------------------------------------------------------------------------
check_unario:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Check operand
    mov     rdi, [rbx + AST_UNARIO_OPERAND]
    call    check_expression

    ; Get operator
    mov     rax, [rbx + AST_UNARIO_OP]

    cmp     rax, OP_NEG
    je      .negate

    ; Logical not
    mov     rdi, [rbx + AST_UNARIO_OPERAND]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_BOOLEANO
    je      .bool_result

    lea     rdi, [err_not_boolean]
    call    error_report
    inc     qword [error_count]
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .done

.negate:
    mov     rdi, [rbx + AST_UNARIO_OPERAND]
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_NUMERO
    je      .num_result

    lea     rdi, [err_not_numeric]
    call    error_report
    inc     qword [error_count]
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .done

.num_result:
    mov     qword [rbx + AST_TYPE_ID], TYPE_NUMERO
    jmp     .done

.bool_result:
    mov     qword [rbx + AST_TYPE_ID], TYPE_BOOLEANO

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; check_llamada - Check function call
; -----------------------------------------------------------------------------
check_llamada:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     rbx, rdi

    ; Get callee name
    mov     rdi, [rbx + AST_LLAMADA_CALLEE]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    symbols_lookup

    test    rax, rax
    jnz     .found

    lea     rdi, [err_undefined_func]
    call    error_report
    inc     qword [error_count]
    mov     qword [rbx + AST_TYPE_ID], TYPE_UNKNOWN
    jmp     .done

.found:
    mov     r12, rax                    ; Symbol

    ; Get return type
    mov     rdi, r12
    call    symbols_get_type
    mov     [rbx + AST_TYPE_ID], rax

    ; Check arguments
    mov     r13, [rbx + AST_LLAMADA_ARGS]
    mov     r14, [rbx + AST_LLAMADA_COUNT]

.arg_loop:
    test    r14, r14
    jz      .done

    mov     rdi, [r13]
    call    check_expression

    add     r13, 8
    dec     r14
    jmp     .arg_loop

.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; types_numeric_compat - Check if two types are numeric-compatible
; -----------------------------------------------------------------------------
; Input:  rdi = type1, rsi = type2
; Output: rax = 1 if compatible, 0 if not
; Note:   byte and numero are considered compatible for implicit conversion
; -----------------------------------------------------------------------------
types_numeric_compat:
    ; Check if type1 is numeric (numero or byte)
    cmp     rdi, TYPE_NUMERO
    je      .type1_numeric
    cmp     rdi, TYPE_BYTE
    je      .type1_numeric
    xor     rax, rax
    ret

.type1_numeric:
    ; Check if type2 is numeric (numero or byte)
    cmp     rsi, TYPE_NUMERO
    je      .compatible
    cmp     rsi, TYPE_BYTE
    je      .compatible
    xor     rax, rax
    ret

.compatible:
    mov     rax, 1
    ret

; =============================================================================
; END OF FILE
; =============================================================================
