; =============================================================================
; MEDELLIN.COL - STAGE 0: CODE GENERATOR
; =============================================================================
; Generates x86-64 machine code from typed AST
; Emits code directly to memory buffer
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern symbols_lookup
extern symbols_get_type
extern symbols_enter_scope
extern symbols_leave_scope
extern symbols_define
extern util_strlen

; Symbol constants
%define SYM_VARIABLE    1
%define SYM_FUNCTION    2
%define SYM_PARAMETER   3
%define SYM_OFFSET      24

; Type IDs
%define TYPE_NUMERO     114
%define TYPE_TEXTO      115
%define TYPE_BOOLEANO   116

; -----------------------------------------------------------------------------
; AST Node Types
; -----------------------------------------------------------------------------
%define AST_PROGRAMA        1
%define AST_PARCERO         2
%define AST_VARIABLE        4
%define AST_BLOQUE          20
%define AST_SI              21
%define AST_MIENTRAS        22
%define AST_DESDE           23
%define AST_DEVUELVASE      24
%define AST_DIGA            25
%define AST_ASIGNACION      26
%define AST_BINARIO         40
%define AST_UNARIO          41
%define AST_LLAMADA         42
%define AST_IDENT           43
%define AST_NUMERO_LIT      44
%define AST_TEXTO_LIT       45
%define AST_BOOL_LIT        46

; AST offsets
%define AST_KIND            0
%define AST_TYPE_ID         8

%define AST_PROGRAMA_FUNCS  16
%define AST_PROGRAMA_COUNT  24

%define AST_PARCERO_NAME    16
%define AST_PARCERO_PARAMS  24
%define AST_PARCERO_PCOUNT  32
%define AST_PARCERO_RETTYPE 40
%define AST_PARCERO_BODY    48

%define AST_VARIABLE_NAME   16
%define AST_VARIABLE_TYPE   24
%define AST_VARIABLE_INIT   32

%define AST_BLOQUE_STMTS    16
%define AST_BLOQUE_COUNT    24

%define AST_SI_COND         16
%define AST_SI_THEN         24
%define AST_SI_ELSE         32

%define AST_MIENTRAS_COND   16
%define AST_MIENTRAS_BODY   24

%define AST_DESDE_VAR       16
%define AST_DESDE_START     24
%define AST_DESDE_END       32
%define AST_DESDE_BODY      40

%define AST_DEVUELVASE_VAL  16
%define AST_DIGA_VAL        16

%define AST_ASIGNACION_TGT  16
%define AST_ASIGNACION_VAL  24

%define AST_BINARIO_OP      16
%define AST_BINARIO_LEFT    24
%define AST_BINARIO_RIGHT   32

%define AST_UNARIO_OP       16
%define AST_UNARIO_OPERAND  24

%define AST_LLAMADA_CALLEE  16
%define AST_LLAMADA_ARGS    24
%define AST_LLAMADA_COUNT   32

%define AST_IDENT_NAME      16
%define AST_LIT_VAL         16

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

%define OP_NEG              20
%define OP_NO               21

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global codegen_generate
global code_buffer
global code_size
global data_buffer
global data_size

; Function info for linking
global func_table
global func_count

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Runtime function names
    rt_diga:            db "_medellin_diga", 0
    rt_diga_numero:     db "_medellin_diga_numero", 0

section .bss
    ; Code buffer (4MB)
    alignb 16
    code_buffer:        resb 4 * 1024 * 1024
    code_ptr:           resq 1
    code_size:          resq 1

    ; Data buffer (1MB)
    alignb 8
    data_buffer:        resb 1024 * 1024
    data_ptr:           resq 1
    data_size:          resq 1

    ; Function table (name, offset pairs)
    alignb 8
    func_table:         resb 8192       ; 256 functions max
    func_count:         resq 1

    ; Current function state
    current_func_name:  resq 1
    stack_size:         resq 1
    label_counter:      resq 1

    ; For loops - track variable offsets
    loop_var_offset:    resq 1
    loop_end_offset:    resq 1

section .text

; -----------------------------------------------------------------------------
; codegen_generate - Generate code for program
; -----------------------------------------------------------------------------
; Input:  rdi = AST_PROGRAMA node
; Output: rax = code size, or 0 on error
; -----------------------------------------------------------------------------
codegen_generate:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rdi                    ; Program node

    ; Initialize
    lea     rax, [code_buffer]
    mov     [code_ptr], rax

    lea     rax, [data_buffer]
    mov     [data_ptr], rax

    mov     qword [code_size], 0
    mov     qword [data_size], 0
    mov     qword [func_count], 0
    mov     qword [label_counter], 0

    ; Generate code for each function
    mov     r13, [r12 + AST_PROGRAMA_FUNCS]
    mov     r14, [r12 + AST_PROGRAMA_COUNT]

.func_loop:
    test    r14, r14
    jz      .done

    mov     rdi, [r13]
    call    gen_parcero

    add     r13, 8
    dec     r14
    jmp     .func_loop

.done:
    ; Calculate final code size
    mov     rax, [code_ptr]
    lea     rcx, [code_buffer]
    sub     rax, rcx
    mov     [code_size], rax

    ; Calculate data size
    mov     rax, [data_ptr]
    lea     rcx, [data_buffer]
    sub     rax, rcx
    mov     [data_size], rax

    mov     rax, [code_size]

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_parcero - Generate code for function
; -----------------------------------------------------------------------------
gen_parcero:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 8

    mov     r12, rdi                    ; Function node

    ; Record function in table
    mov     rax, [r12 + AST_PARCERO_NAME]
    mov     [current_func_name], rax

    mov     rcx, [func_count]
    lea     rdx, [func_table]
    mov     [rdx + rcx * 16], rax       ; Name
    mov     rax, [code_ptr]
    lea     rbx, [code_buffer]
    sub     rax, rbx
    mov     [rdx + rcx * 16 + 8], rax   ; Offset
    inc     qword [func_count]

    ; Calculate stack size (8 bytes per local + alignment)
    ; For now, allocate 256 bytes for locals
    mov     qword [stack_size], 256

    ; Function prologue
    ; push rbp
    call    emit_push_rbp

    ; mov rbp, rsp
    call    emit_mov_rbp_rsp

    ; sub rsp, stack_size
    mov     rdi, [stack_size]
    call    emit_sub_rsp_imm

    ; Save callee-saved registers we use
    ; push rbx
    call    emit_push_rbx

    ; push r12-r15
    call    emit_push_r12
    call    emit_push_r13
    call    emit_push_r14
    call    emit_push_r15

    ; Enter scope
    call    symbols_enter_scope

    ; Register parameters
    mov     r13, [r12 + AST_PARCERO_PARAMS]
    mov     r14, [r12 + AST_PARCERO_PCOUNT]
    xor     rbx, rbx                    ; Parameter index

.param_loop:
    cmp     rbx, r14
    jge     .gen_body

    mov     rax, [r13 + rbx * 8]        ; Parameter node

    ; Define in symbol table
    push    rdi
    push    rsi
    mov     rdi, [rax + 16]             ; Name
    mov     rsi, SYM_PARAMETER
    xor     rdx, rdx
    xor     rcx, rcx
    call    symbols_define
    pop     rsi
    pop     rdi

    ; Store parameter from register to stack
    ; Parameters come in rdi, rsi, rdx, rcx, r8, r9
    mov     rcx, rbx
    cmp     rcx, 6
    jge     .param_done                 ; Only handle first 6 for now

    ; Calculate offset: -8, -16, -24, etc.
    inc     rcx
    neg     rcx
    shl     rcx, 3

    ; mov [rbp + offset], reg
    push    rbx
    mov     rdi, rcx
    mov     rsi, rbx                    ; Param index = which register
    call    emit_store_param
    pop     rbx

.param_done:
    inc     rbx
    jmp     .param_loop

.gen_body:
    ; Generate body
    mov     rdi, [r12 + AST_PARCERO_BODY]
    call    gen_bloque

    ; Leave scope
    call    symbols_leave_scope

    ; Function epilogue
    ; pop r15-r12
    call    emit_pop_r15
    call    emit_pop_r14
    call    emit_pop_r13
    call    emit_pop_r12
    call    emit_pop_rbx

    ; mov rsp, rbp
    call    emit_mov_rsp_rbp

    ; pop rbp
    call    emit_pop_rbp

    ; ret
    call    emit_ret

    add     rsp, 8
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_bloque - Generate code for block
; -----------------------------------------------------------------------------
gen_bloque:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi

    mov     rbx, [r12 + AST_BLOQUE_STMTS]
    mov     r13, [r12 + AST_BLOQUE_COUNT]

.loop:
    test    r13, r13
    jz      .done

    mov     rdi, [rbx]
    call    gen_statement

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
; gen_statement - Generate code for statement
; -----------------------------------------------------------------------------
gen_statement:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi
    movzx   eax, byte [rbx]

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
    je      .call_expr

    jmp     .done

.variable:
    call    gen_variable
    jmp     .done

.si:
    call    gen_si
    jmp     .done

.mientras:
    call    gen_mientras
    jmp     .done

.desde:
    call    gen_desde
    jmp     .done

.devuelvase:
    call    gen_devuelvase
    jmp     .done

.diga:
    call    gen_diga
    jmp     .done

.asignacion:
    call    gen_asignacion
    jmp     .done

.call_expr:
    call    gen_expression              ; Result in rax, discarded

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_variable - Generate code for variable declaration
; -----------------------------------------------------------------------------
gen_variable:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi

    ; Define in symbol table to get offset
    mov     rdi, [r12 + AST_VARIABLE_NAME]
    mov     rsi, SYM_VARIABLE
    xor     rdx, rdx
    xor     rcx, rcx
    call    symbols_define
    mov     rbx, rax                    ; Symbol

    ; Check for initializer
    mov     rdi, [r12 + AST_VARIABLE_INIT]
    test    rdi, rdi
    jz      .done

    ; Generate initializer (result in rax)
    call    gen_expression

    ; Store to stack location
    mov     rdi, [rbx + SYM_OFFSET]
    call    emit_store_rax_to_stack

.done:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_si - Generate code for if statement
; -----------------------------------------------------------------------------
gen_si:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi

    ; Get unique labels
    mov     rax, [label_counter]
    mov     r13, rax
    add     qword [label_counter], 2

    ; Generate condition
    mov     rdi, [r12 + AST_SI_COND]
    call    gen_expression

    ; test rax, rax
    call    emit_test_rax_rax

    ; jz else_label
    mov     rdi, r13                    ; Else/end label
    call    emit_jz_forward

    ; Save patch location
    mov     rbx, rax

    ; Generate then block
    call    symbols_enter_scope
    mov     rdi, [r12 + AST_SI_THEN]
    call    gen_bloque
    call    symbols_leave_scope

    ; Check for else block
    mov     rdi, [r12 + AST_SI_ELSE]
    test    rdi, rdi
    jz      .no_else

    ; jmp end_label
    mov     rdi, r13
    inc     rdi
    call    emit_jmp_forward
    mov     r13, rax                    ; Save patch location for end

    ; Patch else jump
    call    emit_patch_jump
    push    rbx
    mov     rbx, rax

    ; Generate else block
    call    symbols_enter_scope
    mov     rdi, [r12 + AST_SI_ELSE]
    call    gen_bloque
    call    symbols_leave_scope

    ; Patch end jump
    mov     rdi, r13
    call    emit_patch_jump
    pop     rbx
    jmp     .done

.no_else:
    ; Patch the conditional jump to here
    mov     rdi, rbx
    call    emit_patch_jump

.done:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_mientras - Generate code for while loop
; -----------------------------------------------------------------------------
gen_mientras:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12, rdi

    ; Get unique labels
    mov     r13, [label_counter]
    add     qword [label_counter], 2

    ; Record loop start
    mov     r14, [code_ptr]

    ; Generate condition
    mov     rdi, [r12 + AST_MIENTRAS_COND]
    call    gen_expression

    ; test rax, rax
    call    emit_test_rax_rax

    ; jz end
    mov     rdi, r13
    call    emit_jz_forward
    mov     rbx, rax                    ; Save patch location

    ; Generate body
    call    symbols_enter_scope
    mov     rdi, [r12 + AST_MIENTRAS_BODY]
    call    gen_bloque
    call    symbols_leave_scope

    ; jmp start
    mov     rdi, r14
    call    emit_jmp_back

    ; Patch end jump
    mov     rdi, rbx
    call    emit_patch_jump

    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_desde - Generate code for for loop
; -----------------------------------------------------------------------------
gen_desde:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 24

    mov     r12, rdi

    ; Enter scope
    call    symbols_enter_scope

    ; Define loop variable
    mov     rdi, [r12 + AST_DESDE_VAR]
    mov     rsi, SYM_VARIABLE
    xor     rdx, rdx
    xor     rcx, rcx
    call    symbols_define
    mov     r13, rax                    ; Loop var symbol
    mov     rax, [r13 + SYM_OFFSET]
    mov     [rbp - 8], rax              ; Save var offset

    ; Generate start value
    mov     rdi, [r12 + AST_DESDE_START]
    call    gen_expression

    ; Store to loop variable
    mov     rdi, [rbp - 8]
    call    emit_store_rax_to_stack

    ; Generate end value and store temporarily
    mov     rdi, [r12 + AST_DESDE_END]
    call    gen_expression

    ; Store end value to temp stack location
    mov     rdi, -200                   ; Temp location
    call    emit_store_rax_to_stack
    mov     [rbp - 16], rdi

    ; Loop start
    mov     r14, [code_ptr]

    ; Load loop var
    mov     rdi, [rbp - 8]
    call    emit_load_rax_from_stack

    ; Compare with end
    ; mov rcx, [rbp + end_offset]
    mov     rdi, [rbp - 16]
    call    emit_load_rcx_from_stack

    ; cmp rax, rcx
    call    emit_cmp_rax_rcx

    ; jge end
    mov     rdi, [label_counter]
    inc     qword [label_counter]
    call    emit_jge_forward
    mov     r15, rax                    ; Patch location

    ; Generate body
    mov     rdi, [r12 + AST_DESDE_BODY]
    call    gen_bloque

    ; Increment loop variable
    mov     rdi, [rbp - 8]
    call    emit_load_rax_from_stack

    ; inc rax
    call    emit_inc_rax

    ; Store back
    mov     rdi, [rbp - 8]
    call    emit_store_rax_to_stack

    ; jmp start
    mov     rdi, r14
    call    emit_jmp_back

    ; Patch end jump
    mov     rdi, r15
    call    emit_patch_jump

    ; Leave scope
    call    symbols_leave_scope

    add     rsp, 24
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_devuelvase - Generate return statement
; -----------------------------------------------------------------------------
gen_devuelvase:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Generate return value if present
    mov     rdi, [rbx + AST_DEVUELVASE_VAL]
    test    rdi, rdi
    jz      .no_value

    call    gen_expression              ; Result in rax

.no_value:
    ; Jump to epilogue (simplified: just emit epilogue here)
    call    emit_pop_r15
    call    emit_pop_r14
    call    emit_pop_r13
    call    emit_pop_r12
    call    emit_pop_rbx
    call    emit_mov_rsp_rbp
    call    emit_pop_rbp
    call    emit_ret

    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_diga - Generate print statement
; -----------------------------------------------------------------------------
gen_diga:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi

    ; Get value to print
    mov     rdi, [r12 + AST_DIGA_VAL]

    ; Check type
    mov     rax, [rdi + AST_TYPE_ID]
    cmp     rax, TYPE_TEXTO
    je      .print_string

    ; Numeric - generate value in rax, then call print_numero
    mov     rdi, [r12 + AST_DIGA_VAL]
    call    gen_expression

    ; Move rax to rdi for call
    call    emit_mov_rdi_rax

    ; Call _medellin_diga_numero
    lea     rdi, [rt_diga_numero]
    call    emit_call_extern

    jmp     .done

.print_string:
    ; String literal - get pointer and length
    mov     rdi, [r12 + AST_DIGA_VAL]
    mov     rbx, [rdi + AST_LIT_VAL]    ; Interned string pointer

    ; Add string to data section and get offset
    mov     rdi, rbx
    call    add_string_to_data
    mov     r12, rax                    ; Data offset

    ; lea rdi, [rel data_offset]
    mov     rdi, r12
    call    emit_lea_rdi_data

    ; Calculate string length
    mov     rdi, rbx
    call    util_strlen
    mov     rdi, rax
    call    emit_mov_rsi_imm

    ; Call _medellin_diga
    lea     rdi, [rt_diga]
    call    emit_call_extern

.done:
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_asignacion - Generate assignment
; -----------------------------------------------------------------------------
gen_asignacion:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi

    ; Generate value
    mov     rdi, [r12 + AST_ASIGNACION_VAL]
    call    gen_expression

    ; Get target offset
    mov     rdi, [r12 + AST_ASIGNACION_TGT]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    symbols_lookup
    mov     rbx, [rax + SYM_OFFSET]

    ; Store
    mov     rdi, rbx
    call    emit_store_rax_to_stack

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_expression - Generate expression (result in rax)
; -----------------------------------------------------------------------------
gen_expression:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi
    movzx   eax, byte [rbx]

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

    ; Unknown - load 0
    xor     rdi, rdi
    call    emit_mov_rax_imm
    jmp     .done

.numero:
    mov     rdi, [rbx + AST_LIT_VAL]
    call    emit_mov_rax_imm
    jmp     .done

.texto:
    ; Return pointer to string in data section
    mov     rdi, [rbx + AST_LIT_VAL]
    call    add_string_to_data
    mov     rdi, rax
    call    emit_lea_rax_data
    jmp     .done

.bool:
    movzx   rdi, byte [rbx + AST_LIT_VAL]
    call    emit_mov_rax_imm
    jmp     .done

.ident:
    ; Load from stack
    mov     rdi, [rbx + AST_IDENT_NAME]
    call    symbols_lookup
    mov     rdi, [rax + SYM_OFFSET]
    call    emit_load_rax_from_stack
    jmp     .done

.binario:
    call    gen_binario
    jmp     .done

.unario:
    call    gen_unario
    jmp     .done

.llamada:
    call    gen_llamada

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_binario - Generate binary expression
; -----------------------------------------------------------------------------
gen_binario:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi

    ; Generate left operand
    mov     rdi, [r12 + AST_BINARIO_LEFT]
    call    gen_expression

    ; Push result
    call    emit_push_rax

    ; Generate right operand
    mov     rdi, [r12 + AST_BINARIO_RIGHT]
    call    gen_expression

    ; Pop left into rcx, right is in rax
    call    emit_pop_rcx

    ; Now rcx = left, rax = right
    ; For most ops we want left op right, so swap
    call    emit_xchg_rax_rcx

    ; Now rax = left, rcx = right
    mov     rbx, [r12 + AST_BINARIO_OP]

    cmp     rbx, OP_MAS
    je      .add
    cmp     rbx, OP_MENOS
    je      .sub
    cmp     rbx, OP_POR
    je      .mul
    cmp     rbx, OP_ENTRE
    je      .div
    cmp     rbx, OP_MODULO
    je      .mod
    cmp     rbx, OP_IGUAL
    je      .equal
    cmp     rbx, OP_NO_IGUAL
    je      .not_equal
    cmp     rbx, OP_MAYOR
    je      .greater
    cmp     rbx, OP_MENOR
    je      .less
    cmp     rbx, OP_MAYOR_IGUAL
    je      .greater_eq
    cmp     rbx, OP_MENOR_IGUAL
    je      .less_eq
    cmp     rbx, OP_Y
    je      .and
    cmp     rbx, OP_O
    je      .or

    jmp     .done

.add:
    call    emit_add_rax_rcx
    jmp     .done

.sub:
    call    emit_sub_rax_rcx
    jmp     .done

.mul:
    call    emit_imul_rax_rcx
    jmp     .done

.div:
    call    emit_cqo
    call    emit_idiv_rcx
    jmp     .done

.mod:
    call    emit_cqo
    call    emit_idiv_rcx
    call    emit_mov_rax_rdx            ; Remainder in rdx
    jmp     .done

.equal:
    call    emit_cmp_rax_rcx
    call    emit_sete_al
    call    emit_movzx_rax_al
    jmp     .done

.not_equal:
    call    emit_cmp_rax_rcx
    call    emit_setne_al
    call    emit_movzx_rax_al
    jmp     .done

.greater:
    call    emit_cmp_rax_rcx
    call    emit_setg_al
    call    emit_movzx_rax_al
    jmp     .done

.less:
    call    emit_cmp_rax_rcx
    call    emit_setl_al
    call    emit_movzx_rax_al
    jmp     .done

.greater_eq:
    call    emit_cmp_rax_rcx
    call    emit_setge_al
    call    emit_movzx_rax_al
    jmp     .done

.less_eq:
    call    emit_cmp_rax_rcx
    call    emit_setle_al
    call    emit_movzx_rax_al
    jmp     .done

.and:
    call    emit_and_rax_rcx
    jmp     .done

.or:
    call    emit_or_rax_rcx

.done:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_unario - Generate unary expression
; -----------------------------------------------------------------------------
gen_unario:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi

    ; Generate operand
    mov     rdi, [rbx + AST_UNARIO_OPERAND]
    call    gen_expression

    mov     rcx, [rbx + AST_UNARIO_OP]

    cmp     rcx, OP_NEG
    je      .neg
    cmp     rcx, OP_NO
    je      .not

    jmp     .done

.neg:
    call    emit_neg_rax
    jmp     .done

.not:
    call    emit_test_rax_rax
    call    emit_setz_al
    call    emit_movzx_rax_al

.done:
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; gen_llamada - Generate function call
; -----------------------------------------------------------------------------
gen_llamada:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    sub     rsp, 8

    mov     r12, rdi

    ; Generate arguments (reverse order, push to stack)
    mov     r13, [r12 + AST_LLAMADA_ARGS]
    mov     r14, [r12 + AST_LLAMADA_COUNT]

    ; Generate each argument
    xor     rbx, rbx
.arg_loop:
    cmp     rbx, r14
    jge     .make_call

    mov     rdi, [r13 + rbx * 8]
    call    gen_expression

    ; Store in appropriate register based on index
    mov     rcx, rbx
    cmp     rcx, 0
    je      .arg_rdi
    cmp     rcx, 1
    je      .arg_rsi
    cmp     rcx, 2
    je      .arg_rdx
    cmp     rcx, 3
    je      .arg_rcx
    cmp     rcx, 4
    je      .arg_r8
    cmp     rcx, 5
    je      .arg_r9
    jmp     .next_arg               ; Skip if more than 6

.arg_rdi:
    call    emit_push_rax
    jmp     .next_arg
.arg_rsi:
    call    emit_mov_rsi_rax
    jmp     .next_arg
.arg_rdx:
    call    emit_mov_rdx_rax
    jmp     .next_arg
.arg_rcx:
    call    emit_mov_rcx_rax
    jmp     .next_arg
.arg_r8:
    call    emit_mov_r8_rax
    jmp     .next_arg
.arg_r9:
    call    emit_mov_r9_rax

.next_arg:
    inc     rbx
    jmp     .arg_loop

.make_call:
    ; Pop first arg into rdi if we have args
    test    r14, r14
    jz      .do_call
    call    emit_pop_rdi

.do_call:
    ; Get function name
    mov     rdi, [r12 + AST_LLAMADA_CALLEE]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    emit_call_func

    add     rsp, 8
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; add_string_to_data - Add string to data section
; -----------------------------------------------------------------------------
; Input:  rdi = string pointer
; Output: rax = offset in data section
; -----------------------------------------------------------------------------
add_string_to_data:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, rdi

    ; Calculate current offset
    mov     rax, [data_ptr]
    lea     rbx, [data_buffer]
    sub     rax, rbx
    push    rax                         ; Save offset

    ; Copy string
    mov     rdi, r12
    call    util_strlen
    mov     rcx, rax
    inc     rcx                         ; Include null terminator

    mov     rsi, r12
    mov     rdi, [data_ptr]
.copy:
    mov     al, [rsi]
    mov     [rdi], al
    inc     rsi
    inc     rdi
    dec     rcx
    jnz     .copy

    mov     [data_ptr], rdi

    pop     rax                         ; Return offset

    pop     r12
    pop     rbx
    pop     rbp
    ret

; =============================================================================
; CODE EMISSION HELPERS
; =============================================================================

; emit_byte - Emit a single byte
emit_byte:
    mov     rax, [code_ptr]
    mov     [rax], dil
    inc     qword [code_ptr]
    ret

; emit_dword - Emit 4 bytes (little endian)
emit_dword:
    mov     rax, [code_ptr]
    mov     [rax], edi
    add     qword [code_ptr], 4
    ret

; emit_qword - Emit 8 bytes
emit_qword:
    mov     rax, [code_ptr]
    mov     [rax], rdi
    add     qword [code_ptr], 8
    ret

; push rbp = 55
emit_push_rbp:
    mov     dil, 0x55
    jmp     emit_byte

; pop rbp = 5D
emit_pop_rbp:
    mov     dil, 0x5D
    jmp     emit_byte

; push rax = 50
emit_push_rax:
    mov     dil, 0x50
    jmp     emit_byte

; pop rax = 58
emit_pop_rax:
    mov     dil, 0x58
    jmp     emit_byte

; push rbx = 53
emit_push_rbx:
    mov     dil, 0x53
    jmp     emit_byte

; pop rbx = 5B
emit_pop_rbx:
    mov     dil, 0x5B
    jmp     emit_byte

; push rcx = 51
emit_push_rcx:
    mov     dil, 0x51
    jmp     emit_byte

; pop rcx = 59
emit_pop_rcx:
    mov     dil, 0x59
    jmp     emit_byte

; pop rdi = 5F
emit_pop_rdi:
    mov     dil, 0x5F
    jmp     emit_byte

; push r12 = 41 54
emit_push_r12:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x54
    jmp     emit_byte

; pop r12 = 41 5C
emit_pop_r12:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x5C
    jmp     emit_byte

; push r13 = 41 55
emit_push_r13:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x55
    jmp     emit_byte

; pop r13 = 41 5D
emit_pop_r13:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x5D
    jmp     emit_byte

; push r14 = 41 56
emit_push_r14:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x56
    jmp     emit_byte

; pop r14 = 41 5E
emit_pop_r14:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x5E
    jmp     emit_byte

; push r15 = 41 57
emit_push_r15:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x57
    jmp     emit_byte

; pop r15 = 41 5F
emit_pop_r15:
    mov     dil, 0x41
    call    emit_byte
    mov     dil, 0x5F
    jmp     emit_byte

; mov rbp, rsp = 48 89 E5
emit_mov_rbp_rsp:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xE5
    jmp     emit_byte

; mov rsp, rbp = 48 89 EC
emit_mov_rsp_rbp:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xEC
    jmp     emit_byte

; sub rsp, imm32 = 48 81 EC imm32
emit_sub_rsp_imm:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x81
    call    emit_byte
    mov     dil, 0xEC
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; ret = C3
emit_ret:
    mov     dil, 0xC3
    jmp     emit_byte

; mov rax, imm64 = 48 B8 imm64
emit_mov_rax_imm:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xB8
    call    emit_byte
    pop     rdi
    jmp     emit_qword

; mov rdi, rax = 48 89 C7
emit_mov_rdi_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC7
    jmp     emit_byte

; mov rsi, rax = 48 89 C6
emit_mov_rsi_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC6
    jmp     emit_byte

; mov rdx, rax = 48 89 C2
emit_mov_rdx_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC2
    jmp     emit_byte

; mov rcx, rax = 48 89 C1
emit_mov_rcx_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC1
    jmp     emit_byte

; mov r8, rax = 49 89 C0
emit_mov_r8_rax:
    mov     dil, 0x49
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; mov r9, rax = 49 89 C1
emit_mov_r9_rax:
    mov     dil, 0x49
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC1
    jmp     emit_byte

; mov rax, rdx = 48 89 D0
emit_mov_rax_rdx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xD0
    jmp     emit_byte

; mov rsi, imm64 = 48 BE imm64
emit_mov_rsi_imm:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xBE
    call    emit_byte
    pop     rdi
    jmp     emit_qword

; xchg rax, rcx = 48 91
emit_xchg_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x91
    jmp     emit_byte

; add rax, rcx = 48 01 C8
emit_add_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x01
    call    emit_byte
    mov     dil, 0xC8
    jmp     emit_byte

; sub rax, rcx = 48 29 C8
emit_sub_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x29
    call    emit_byte
    mov     dil, 0xC8
    jmp     emit_byte

; imul rax, rcx = 48 0F AF C1
emit_imul_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0xAF
    call    emit_byte
    mov     dil, 0xC1
    jmp     emit_byte

; cqo = 48 99
emit_cqo:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x99
    jmp     emit_byte

; idiv rcx = 48 F7 F9
emit_idiv_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xF7
    call    emit_byte
    mov     dil, 0xF9
    jmp     emit_byte

; cmp rax, rcx = 48 39 C8
emit_cmp_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x39
    call    emit_byte
    mov     dil, 0xC8
    jmp     emit_byte

; test rax, rax = 48 85 C0
emit_test_rax_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x85
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; and rax, rcx = 48 21 C8
emit_and_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x21
    call    emit_byte
    mov     dil, 0xC8
    jmp     emit_byte

; or rax, rcx = 48 09 C8
emit_or_rax_rcx:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x09
    call    emit_byte
    mov     dil, 0xC8
    jmp     emit_byte

; neg rax = 48 F7 D8
emit_neg_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xF7
    call    emit_byte
    mov     dil, 0xD8
    jmp     emit_byte

; inc rax = 48 FF C0
emit_inc_rax:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xFF
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; sete al = 0F 94 C0
emit_sete_al:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x94
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; setne al = 0F 95 C0
emit_setne_al:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x95
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; setg al = 0F 9F C0
emit_setg_al:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x9F
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; setl al = 0F 9C C0
emit_setl_al:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x9C
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; setge al = 0F 9D C0
emit_setge_al:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x9D
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; setle al = 0F 9E C0
emit_setle_al:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x9E
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; setz al = 0F 94 C0
emit_setz_al:
    jmp     emit_sete_al

; movzx rax, al = 48 0F B6 C0
emit_movzx_rax_al:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0xB6
    call    emit_byte
    mov     dil, 0xC0
    jmp     emit_byte

; Store rax to [rbp + offset]
; mov [rbp + off8], rax = 48 89 45 xx (if off fits in byte)
; mov [rbp + off32], rax = 48 89 85 xxxxxxxx
emit_store_rax_to_stack:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    pop     rdi

    ; Check if offset fits in signed byte
    movsx   rax, dil
    cmp     rax, rdi
    jne     .use_dword

    mov     dil, 0x45                   ; [rbp + disp8]
    call    emit_byte
    pop     rdi
    push    rdi
    jmp     emit_byte

.use_dword:
    push    rdi
    mov     dil, 0x85                   ; [rbp + disp32]
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; Load rax from [rbp + offset]
emit_load_rax_from_stack:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8B
    call    emit_byte
    pop     rdi

    movsx   rax, dil
    cmp     rax, rdi
    jne     .use_dword

    push    rdi
    mov     dil, 0x45
    call    emit_byte
    pop     rdi
    jmp     emit_byte

.use_dword:
    push    rdi
    mov     dil, 0x85
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; Load rcx from [rbp + offset]
emit_load_rcx_from_stack:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8B
    call    emit_byte
    pop     rdi

    movsx   rax, dil
    cmp     rax, rdi
    jne     .use_dword

    push    rdi
    mov     dil, 0x4D                   ; rcx instead of rax
    call    emit_byte
    pop     rdi
    jmp     emit_byte

.use_dword:
    push    rdi
    mov     dil, 0x8D
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; Store parameter register to stack
; rsi = param index (0=rdi, 1=rsi, etc.)
emit_store_param:
    ; For simplicity, just store rdi (first param) for now
    ; mov [rbp + rdi], rdi
    push    rdi
    push    rsi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0x7D                   ; rdi to [rbp+disp8]
    call    emit_byte
    pop     rsi
    pop     rdi
    ; Emit offset as byte
    jmp     emit_byte

; jz rel32 - emit jump and return patch location
emit_jz_forward:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x84
    call    emit_byte
    mov     rax, [code_ptr]             ; Patch location
    push    rax
    xor     edi, edi
    call    emit_dword
    pop     rax
    ret

; jge rel32
emit_jge_forward:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     rax, [code_ptr]
    push    rax
    xor     edi, edi
    call    emit_dword
    pop     rax
    ret

; jmp rel32
emit_jmp_forward:
    mov     dil, 0xE9
    call    emit_byte
    mov     rax, [code_ptr]
    push    rax
    xor     edi, edi
    call    emit_dword
    pop     rax
    ret

; Patch a forward jump to current location
emit_patch_jump:
    mov     rax, [code_ptr]
    sub     rax, rdi
    sub     rax, 4                      ; Relative to end of instruction
    mov     [rdi], eax
    ret

; jmp back to address
emit_jmp_back:
    push    rdi
    mov     dil, 0xE9
    call    emit_byte
    pop     rdi
    mov     rax, rdi
    sub     rax, [code_ptr]
    sub     rax, 4
    mov     edi, eax
    jmp     emit_dword

; lea rdi, [rel data_offset]
emit_lea_rdi_data:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     dil, 0x3D
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; lea rax, [rel data_offset]
emit_lea_rax_data:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     dil, 0x05
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; call extern (placeholder - needs linking)
emit_call_extern:
    push    rdi
    mov     dil, 0xE8
    call    emit_byte
    xor     edi, edi                    ; Will be patched by linker
    call    emit_dword
    pop     rdi
    ret

; call function by name
emit_call_func:
    push    rdi
    mov     dil, 0xE8
    call    emit_byte
    xor     edi, edi                    ; Placeholder
    call    emit_dword
    pop     rdi
    ret

; =============================================================================
; END OF FILE
; =============================================================================
