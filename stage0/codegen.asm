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
extern symbols_alloc_extra
extern util_strlen
extern util_strcmp
extern strings_intern

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
%define AST_ARREGLO_TIPO    47
%define AST_ARREGLO_ACCESO  48

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

%define AST_ARREGLO_TIPO_LEN    16
%define AST_ARREGLO_TIPO_ELEM   24
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
global data_relocs
global data_relocs_count

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
    ; Main function name
    str_principal:      db "principal", 0
    ; Built-in I/O function names
    str_leer_byte:      db "leer_byte", 0
    str_escribir_byte:  db "escribir_byte", 0

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

    ; Data relocations (code_offset, data_offset) pairs
    ; code_offset = offset within code_buffer where to patch
    ; data_offset = offset within data_buffer of the target
    data_relocs:        resq 2048       ; 1024 relocations max
    data_relocs_count:  resq 1

    ; Call patches (code_offset, func_name) pairs
    ; code_offset = where the call's rel32 operand is
    ; func_name = interned string pointer for target function
    call_patches:       resq 2048       ; 1024 calls max
    call_patches_count: resq 1

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
    mov     qword [data_relocs_count], 0
    mov     qword [call_patches_count], 0

    ; Intern "principal" for startup code
    lea     rdi, [str_principal]
    call    strings_intern
    mov     r15, rax                    ; Save interned principal

    ; Emit startup code (_start)
    ; This calls principal() and exits with return value
    mov     rdi, r15                    ; Pass interned principal name
    call    emit_startup_code

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
    ; Patch all function calls to correct offsets
    call    patch_calls

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
    shl     rcx, 4                      ; rcx * 16
    add     rdx, rcx
    mov     [rdx], rax                  ; Name
    mov     rax, [code_ptr]
    lea     rbx, [code_buffer]
    sub     rax, rbx
    mov     [rdx + 8], rax              ; Offset
    inc     qword [func_count]

    ; Calculate stack size (8 bytes per local + alignment)
    ; Allocate 4096 bytes for locals to support larger arrays
    ; (256 was too small - arrays of 36+ elements overflowed)
    mov     qword [stack_size], 4096

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
    push    rax                         ; Save param node
    mov     rdi, [rax + 16]             ; Name
    mov     rsi, SYM_PARAMETER
    xor     rdx, rdx
    xor     rcx, rcx
    call    symbols_define
    ; rax now has symbol pointer

    ; Store parameter from register to stack
    ; Parameters come in rdi, rsi, rdx, rcx, r8, r9
    mov     rcx, rbx
    cmp     rcx, 6
    jge     .param_done_pop             ; Only handle first 6 for now

    ; Calculate offset: -8, -16, -24, etc.
    inc     rcx
    neg     rcx
    shl     rcx, 3

    ; Update symbol's offset so identifier access works
    mov     [rax + SYM_OFFSET], rcx

    ; mov [rbp + offset], reg
    push    rbx
    push    rax                         ; Save symbol ptr
    mov     rdi, rcx
    mov     rsi, rbx                    ; Param index = which register
    call    emit_store_param
    pop     rax
    pop     rbx

.param_done_pop:
    pop     rax                         ; Discard saved param node

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
    push    r13

    mov     r12, rdi

    ; Check if type is array and pre-allocate extra space
    ; parse_type returns small int for primitives, pointer for arrays
    mov     rax, [r12 + AST_VARIABLE_TYPE]
    cmp     rax, 0x1000                 ; Pointers are > 4096
    jb      .not_array

    ; Check if it's actually an array type node
    movzx   ecx, byte [rax]             ; Get AST node kind
    cmp     cl, AST_ARREGLO_TIPO
    jne     .not_array

    ; Array type - get size N and allocate (N-1)*8 extra bytes
    mov     rax, [rax + AST_ARREGLO_TIPO_LEN]
    mov     r13, rax                    ; Save array size
    dec     rax                         ; N-1
    jz      .not_array                  ; If N=1, no extra allocation needed
    shl     rax, 3                      ; (N-1)*8
    mov     rdi, rax
    call    symbols_alloc_extra

.not_array:
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
    pop     r13
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
    push    rax                         ; Save patch location for end jmp

    ; Patch else jump to here (rbx has the jz patch location)
    mov     rdi, rbx
    call    emit_patch_jump

    ; Generate else block
    call    symbols_enter_scope
    mov     rdi, [r12 + AST_SI_ELSE]
    call    gen_bloque
    call    symbols_leave_scope

    ; Patch end jump
    pop     rdi                         ; Get the jmp patch location
    call    emit_patch_jump
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
    ; Check if it's a literal or variable
    mov     rdi, [r12 + AST_DIGA_VAL]
    movzx   eax, byte [rdi]
    cmp     al, AST_TEXTO_LIT
    jne     .print_string_var

    ; String literal - get pointer and length
    mov     rbx, [rdi + AST_LIT_VAL]    ; Interned string pointer

    ; Add string to data section and get offset
    mov     rdi, rbx
    call    add_string_to_data
    mov     r12, rax                    ; Data offset

    ; Calculate string length first (before we clobber rbx)
    mov     rdi, rbx
    call    util_strlen
    push    rax                         ; Save length

    ; Emit inline write syscall:
    ; rdi = 1 (stdout), rsi = buffer, rdx = length, rax = 1 (sys_write)

    ; lea rsi, [rel data_offset] - load string address into rsi
    ; We'll use emit_lea_rdi_data then move to rsi
    mov     rdi, r12
    call    emit_lea_rdi_data           ; lea rdi, [rel string]
    call    emit_mov_rsi_rdi            ; mov rsi, rdi

    ; mov rdx, length
    pop     rdi                         ; Restore length
    call    emit_mov_rdx_imm            ; mov rdx, length

    ; mov rdi, 1 (stdout)
    mov     rdi, 1
    call    emit_mov_rdi_imm            ; mov rdi, 1

    ; mov eax, 1 (sys_write)
    mov     rdi, 1
    call    emit_mov_eax_imm            ; mov eax, 1

    ; syscall
    call    emit_syscall
    jmp     .done

.print_string_var:
    ; String variable - not fully supported in Stage 0
    ; For now, just skip (Stage 0 only requires string literals per roadmap)
    ; TODO: Implement runtime string printing for Stage 1
    jmp     .done

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
    push    r13

    mov     r12, rdi

    ; Generate value (result in rax)
    mov     rdi, [r12 + AST_ASIGNACION_VAL]
    call    gen_expression

    ; Check if target is array access
    mov     rdi, [r12 + AST_ASIGNACION_TGT]
    movzx   eax, byte [rdi]
    cmp     al, AST_ARREGLO_ACCESO
    je      .array_target

    ; Simple variable target
    mov     rdi, [r12 + AST_ASIGNACION_TGT]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    symbols_lookup
    mov     rbx, [rax + SYM_OFFSET]

    ; Store
    mov     rdi, rbx
    call    emit_store_rax_to_stack
    jmp     .done

.array_target:
    ; Target is arr[idx] - first push the value
    call    emit_push_rax

    mov     r13, [r12 + AST_ASIGNACION_TGT]  ; AST_ARREGLO_ACCESO node

    ; Get array base offset
    mov     rdi, [r13 + AST_ARREGLO_ACCESO_ARR]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    symbols_lookup
    mov     rbx, [rax + SYM_OFFSET]         ; Array base offset

    ; Generate index expression (result in rax)
    mov     rdi, [r13 + AST_ARREGLO_ACCESO_IDX]
    call    gen_expression

    ; Emit: mov rdi, rax (index)
    call    emit_mov_rdi_rax

    ; Emit: shl rdi, 3 (multiply by 8)
    mov     dil, 0x48                   ; REX.W
    call    emit_byte
    mov     dil, 0xC1                   ; shl r/m64, imm8
    call    emit_byte
    mov     dil, 0xE7                   ; ModRM: rdi
    call    emit_byte
    mov     dil, 3                      ; shift by 3 (multiply by 8)
    call    emit_byte

    ; Emit: lea rcx, [rbp + offset] (array base)
    mov     dil, 0x48                   ; REX.W
    call    emit_byte
    mov     dil, 0x8D                   ; lea
    call    emit_byte
    mov     dil, 0x8D                   ; ModRM: rcx, [rbp+disp32]
    call    emit_byte
    mov     rdi, rbx                    ; Array base offset
    call    emit_dword

    ; Emit: add rcx, rdi (base + index*8)
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x01                   ; add r/m64, r64
    call    emit_byte
    mov     dil, 0xF9                   ; ModRM: rcx, rdi
    call    emit_byte

    ; Emit: pop rax (get value)
    call    emit_pop_rax

    ; Emit: mov [rcx], rax
    mov     dil, 0x48                   ; REX.W
    call    emit_byte
    mov     dil, 0x89                   ; mov r/m64, r64
    call    emit_byte
    mov     dil, 0x01                   ; ModRM: [rcx], rax
    call    emit_byte

.done:
    pop     r13
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
    cmp     al, AST_ARREGLO_ACCESO
    je      .arreglo_acceso

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
    jmp     .done

.arreglo_acceso:
    ; Generate array element access: base + index * 8
    push    r12
    push    r13
    mov     r12, rbx                    ; Save AST node

    ; Get array base address
    mov     rdi, [r12 + AST_ARREGLO_ACCESO_ARR]
    mov     rdi, [rdi + AST_IDENT_NAME]
    call    symbols_lookup
    mov     r13, [rax + SYM_OFFSET]     ; Array base offset on stack

    ; Generate index expression (result in rax)
    mov     rdi, [r12 + AST_ARREGLO_ACCESO_IDX]
    call    gen_expression

    ; Emit: mov rdi, rax (index)
    call    emit_mov_rdi_rax

    ; Emit: shl rdi, 3 (multiply by 8 for 64-bit elements)
    mov     dil, 0x48                   ; REX.W
    call    emit_byte
    mov     dil, 0xC1                   ; shl r/m64, imm8
    call    emit_byte
    mov     dil, 0xE7                   ; ModRM: rdi
    call    emit_byte
    mov     dil, 3                      ; shift by 3 (multiply by 8)
    call    emit_byte

    ; Emit: lea rax, [rbp + offset]
    mov     dil, 0x48                   ; REX.W
    call    emit_byte
    mov     dil, 0x8D                   ; lea
    call    emit_byte
    mov     dil, 0x85                   ; ModRM: rax, [rbp+disp32]
    call    emit_byte
    mov     rdi, r13                    ; Array base offset
    call    emit_dword

    ; Emit: add rax, rdi (base + index*8)
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x01                   ; add
    call    emit_byte
    mov     dil, 0xF8                   ; ModRM: rax, rdi
    call    emit_byte

    ; Emit: mov rax, [rax] (load element)
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8B
    call    emit_byte
    mov     dil, 0x00                   ; ModRM: rax, [rax]
    call    emit_byte

    pop     r13
    pop     r12
    jmp     .done

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
    push    rdi                         ; Save function name

    ; Check for built-in leer_byte
    lea     rsi, [str_leer_byte]
    call    util_strcmp
    test    rax, rax
    jz      .builtin_leer_byte

    ; Check for built-in escribir_byte
    pop     rdi
    push    rdi
    lea     rsi, [str_escribir_byte]
    call    util_strcmp
    test    rax, rax
    jz      .builtin_escribir_byte

    ; Regular function call
    pop     rdi
    call    emit_call_func
    jmp     .llamada_done

.builtin_leer_byte:
    ; leer_byte() - read one byte from stdin
    ; Generated code:
    ;   sub rsp, 16          ; Allocate buffer on stack
    ;   xor eax, eax         ; sys_read = 0
    ;   xor edi, edi         ; fd = stdin = 0
    ;   lea rsi, [rsp]       ; buf = stack
    ;   mov edx, 1           ; count = 1
    ;   syscall
    ;   test rax, rax        ; Check return value
    ;   jg .read_ok          ; If > 0, got a byte
    ;   mov rax, -1          ; Return -1 on EOF/error
    ;   jmp .read_done
    ;   .read_ok:
    ;   movzx rax, byte [rsp] ; Get the byte
    ;   .read_done:
    ;   add rsp, 16          ; Restore stack

    pop     rdi                         ; Discard function name

    ; sub rsp, 16 = 48 83 EC 10
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x83
    call    emit_byte
    mov     dil, 0xEC
    call    emit_byte
    mov     dil, 0x10
    call    emit_byte

    ; xor eax, eax = 31 C0
    mov     dil, 0x31
    call    emit_byte
    mov     dil, 0xC0
    call    emit_byte

    ; xor edi, edi = 31 FF
    mov     dil, 0x31
    call    emit_byte
    mov     dil, 0xFF
    call    emit_byte

    ; lea rsi, [rsp] = 48 8D 34 24
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     dil, 0x34
    call    emit_byte
    mov     dil, 0x24
    call    emit_byte

    ; mov edx, 1 = BA 01 00 00 00
    mov     dil, 0xBA
    call    emit_byte
    mov     edi, 1
    call    emit_dword

    ; syscall = 0F 05
    call    emit_syscall

    ; test rax, rax = 48 85 C0
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x85
    call    emit_byte
    mov     dil, 0xC0
    call    emit_byte

    ; jg .read_ok (9 bytes forward: 7 for mov rax,-1 + 2 for jmp) = 7F 09
    mov     dil, 0x7F
    call    emit_byte
    mov     dil, 0x09
    call    emit_byte

    ; mov rax, -1 = 48 C7 C0 FF FF FF FF
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xC7
    call    emit_byte
    mov     dil, 0xC0
    call    emit_byte
    mov     dil, 0xFF
    call    emit_byte
    mov     dil, 0xFF
    call    emit_byte
    mov     dil, 0xFF
    call    emit_byte
    mov     dil, 0xFF
    call    emit_byte

    ; jmp .read_done (5 bytes) = EB 05
    mov     dil, 0xEB
    call    emit_byte
    mov     dil, 0x05
    call    emit_byte

    ; .read_ok: movzx rax, byte [rsp] = 48 0F B6 04 24
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0xB6
    call    emit_byte
    mov     dil, 0x04
    call    emit_byte
    mov     dil, 0x24
    call    emit_byte

    ; .read_done: add rsp, 16 = 48 83 C4 10
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x83
    call    emit_byte
    mov     dil, 0xC4
    call    emit_byte
    mov     dil, 0x10
    call    emit_byte

    jmp     .llamada_done

.builtin_escribir_byte:
    ; escribir_byte(b) - write one byte to stdout
    ; rdi already has the byte value from argument handling
    ; Generated code:
    ;   sub rsp, 16          ; Allocate buffer on stack
    ;   mov [rsp], dil       ; Store byte
    ;   mov eax, 1           ; sys_write = 1
    ;   mov edi, 1           ; fd = stdout = 1
    ;   lea rsi, [rsp]       ; buf = stack
    ;   mov edx, 1           ; count = 1
    ;   syscall
    ;   add rsp, 16          ; Restore stack

    pop     rdi                         ; Discard function name

    ; sub rsp, 16 = 48 83 EC 10
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x83
    call    emit_byte
    mov     dil, 0xEC
    call    emit_byte
    mov     dil, 0x10
    call    emit_byte

    ; mov [rsp], dil = 40 88 3C 24
    mov     dil, 0x40
    call    emit_byte
    mov     dil, 0x88
    call    emit_byte
    mov     dil, 0x3C
    call    emit_byte
    mov     dil, 0x24
    call    emit_byte

    ; mov eax, 1 = B8 01 00 00 00
    mov     dil, 0xB8
    call    emit_byte
    mov     edi, 1
    call    emit_dword

    ; mov edi, 1 = BF 01 00 00 00
    mov     dil, 0xBF
    call    emit_byte
    mov     edi, 1
    call    emit_dword

    ; lea rsi, [rsp] = 48 8D 34 24
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     dil, 0x34
    call    emit_byte
    mov     dil, 0x24
    call    emit_byte

    ; mov edx, 1 = BA 01 00 00 00
    mov     dil, 0xBA
    call    emit_byte
    mov     edi, 1
    call    emit_dword

    ; syscall = 0F 05
    call    emit_syscall

    ; add rsp, 16 = 48 83 C4 10
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x83
    call    emit_byte
    mov     dil, 0xC4
    call    emit_byte
    mov     dil, 0x10
    call    emit_byte

    jmp     .llamada_done

.llamada_done:
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

; mov rdi, imm64 = 48 BF imm64
emit_mov_rdi_imm:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xBF
    call    emit_byte
    pop     rdi
    jmp     emit_qword

; mov rdx, imm64 = 48 BA imm64
emit_mov_rdx_imm:
    push    rdi
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0xBA
    call    emit_byte
    pop     rdi
    jmp     emit_qword

; mov eax, imm32 = B8 imm32
emit_mov_eax_imm:
    push    rdi
    mov     dil, 0xB8
    call    emit_byte
    pop     rdi
    jmp     emit_dword

; mov rsi, rdi = 48 89 FE
emit_mov_rsi_rdi:
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xFE
    jmp     emit_byte

; syscall = 0F 05
emit_syscall:
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x05
    jmp     emit_byte

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
    push    rbx
    mov     rbx, rdi                    ; Save offset in callee-saved register

    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte

    ; Check if offset fits in signed byte
    movsx   rax, bl
    cmp     rax, rbx
    jne     .use_dword

    mov     dil, 0x45                   ; [rbp + disp8]
    call    emit_byte
    mov     dil, bl                     ; Emit offset as byte
    pop     rbx
    jmp     emit_byte

.use_dword:
    mov     dil, 0x85                   ; [rbp + disp32]
    call    emit_byte
    mov     rdi, rbx                    ; Offset for dword emit
    pop     rbx
    jmp     emit_dword

; Load rax from [rbp + offset]
emit_load_rax_from_stack:
    push    rbx
    mov     rbx, rdi                    ; Save offset in callee-saved register

    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8B
    call    emit_byte

    ; Check if offset fits in signed byte
    movsx   rax, bl
    cmp     rax, rbx
    jne     .use_dword

    mov     dil, 0x45                   ; [rbp + disp8]
    call    emit_byte
    mov     dil, bl                     ; Emit offset as byte
    pop     rbx
    jmp     emit_byte

.use_dword:
    mov     dil, 0x85                   ; [rbp + disp32]
    call    emit_byte
    mov     rdi, rbx                    ; Offset for dword emit
    pop     rbx
    jmp     emit_dword

; Load rcx from [rbp + offset]
emit_load_rcx_from_stack:
    push    rbx
    mov     rbx, rdi                    ; Save offset in callee-saved register

    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8B
    call    emit_byte

    ; Check if offset fits in signed byte
    movsx   rax, bl
    cmp     rax, rbx
    jne     .use_dword

    mov     dil, 0x4D                   ; [rbp + disp8] with rcx
    call    emit_byte
    mov     dil, bl                     ; Emit offset as byte
    pop     rbx
    jmp     emit_byte

.use_dword:
    mov     dil, 0x8D                   ; [rbp + disp32] with rcx
    call    emit_byte
    mov     rdi, rbx                    ; Offset for dword emit
    pop     rbx
    jmp     emit_dword

; Store parameter register to stack
; rdi = offset (negative)
; rsi = param index (0=rdi, 1=rsi, 2=rdx, 3=rcx, 4=r8, 5=r9)
emit_store_param:
    push    rbx
    push    r12
    mov     rbx, rdi                    ; Save offset
    mov     r12, rsi                    ; Save param index

    ; REX prefix - 0x48 for rdi/rsi/rdx/rcx, 0x4C for r8/r9
    cmp     r12, 4
    jge     .rex_extended
    mov     dil, 0x48
    jmp     .emit_rex
.rex_extended:
    mov     dil, 0x4C                   ; REX.W + REX.R
.emit_rex:
    call    emit_byte

    ; Opcode 0x89 (mov r/m64, r64)
    mov     dil, 0x89
    call    emit_byte

    ; ModRM byte: mod=01 (disp8), r/m=101 (rbp)
    ; reg field: rdi=7, rsi=6, rdx=2, rcx=1, r8=0, r9=1
    cmp     r12, 0
    je      .modrm_rdi
    cmp     r12, 1
    je      .modrm_rsi
    cmp     r12, 2
    je      .modrm_rdx
    cmp     r12, 3
    je      .modrm_rcx
    cmp     r12, 4
    je      .modrm_r8
    cmp     r12, 5
    je      .modrm_r9
    jmp     .modrm_done                 ; Invalid index

.modrm_rdi:
    mov     dil, 0x7D                   ; 01 111 101
    jmp     .modrm_emit
.modrm_rsi:
    mov     dil, 0x75                   ; 01 110 101
    jmp     .modrm_emit
.modrm_rdx:
    mov     dil, 0x55                   ; 01 010 101
    jmp     .modrm_emit
.modrm_rcx:
    mov     dil, 0x4D                   ; 01 001 101
    jmp     .modrm_emit
.modrm_r8:
    mov     dil, 0x45                   ; 01 000 101
    jmp     .modrm_emit
.modrm_r9:
    mov     dil, 0x4D                   ; 01 001 101

.modrm_emit:
    call    emit_byte

    ; Emit offset as byte
    mov     rdi, rbx
    call    emit_byte

.modrm_done:
    pop     r12
    pop     rbx
    ret

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
; Input: rdi = data offset (within data_buffer)
; Records relocation for later fixup
emit_lea_rdi_data:
    push    rbx
    push    r12
    mov     r12, rdi                    ; Save data offset

    ; Emit opcode bytes (3 bytes)
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     dil, 0x3D
    call    emit_byte

    ; Record relocation: code_offset (where the 4-byte offset will be)
    mov     rax, [code_ptr]
    lea     rbx, [code_buffer]
    sub     rax, rbx                    ; Current code offset

    mov     rcx, [data_relocs_count]
    lea     rdx, [data_relocs]
    shl     rcx, 4                      ; * 16 (two qwords per entry)
    mov     [rdx + rcx], rax            ; code_offset
    mov     [rdx + rcx + 8], r12        ; data_offset
    inc     qword [data_relocs_count]

    ; Emit placeholder offset (will be patched later)
    xor     edi, edi
    call    emit_dword

    pop     r12
    pop     rbx
    ret

; lea rax, [rel data_offset]
; Input: rdi = data offset (within data_buffer)
; Records relocation for later fixup
emit_lea_rax_data:
    push    rbx
    push    r12
    mov     r12, rdi                    ; Save data offset

    ; Emit opcode bytes (3 bytes)
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x8D
    call    emit_byte
    mov     dil, 0x05
    call    emit_byte

    ; Record relocation
    mov     rax, [code_ptr]
    lea     rbx, [code_buffer]
    sub     rax, rbx                    ; Current code offset

    mov     rcx, [data_relocs_count]
    lea     rdx, [data_relocs]
    shl     rcx, 4                      ; * 16
    mov     [rdx + rcx], rax            ; code_offset
    mov     [rdx + rcx + 8], r12        ; data_offset
    inc     qword [data_relocs_count]

    ; Emit placeholder offset
    xor     edi, edi
    call    emit_dword

    pop     r12
    pop     rbx
    ret

; call extern (placeholder - needs linking)
emit_call_extern:
    push    rdi
    mov     dil, 0xE8
    call    emit_byte
    xor     edi, edi                    ; Will be patched by linker
    call    emit_dword
    pop     rdi
    ret

; -----------------------------------------------------------------------------
; patch_calls - Resolve all function call addresses
; -----------------------------------------------------------------------------
; After all code is generated, patches call instructions with correct offsets
patch_calls:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r14, [call_patches_count]
    test    r14, r14
    jz      .patch_done

    xor     r13, r13                    ; Patch index
.patch_loop:
    cmp     r13, r14
    jge     .patch_done

    ; Get patch entry
    mov     rax, r13
    shl     rax, 4                      ; * 16
    lea     rcx, [call_patches]
    mov     rbx, [rcx + rax]            ; code_offset (where rel32 is)
    mov     r12, [rcx + rax + 8]        ; function name

    ; Look up function in func_table
    mov     r15, [func_count]
    xor     rcx, rcx
.func_search:
    cmp     rcx, r15
    jge     .patch_next                 ; Function not found, skip

    lea     rdx, [func_table]
    mov     rax, rcx
    shl     rax, 4                      ; * 16
    cmp     r12, [rdx + rax]            ; Compare name pointers
    je      .func_found
    inc     rcx
    jmp     .func_search

.func_found:
    ; rax still has index * 16
    lea     rdx, [func_table]
    mov     rax, [rdx + rax + 8]        ; Get function offset

    ; Calculate relative offset: target - (call_site + 4)
    ; call_site = rbx, target = rax
    mov     rcx, rbx
    add     rcx, 4                      ; End of call instruction
    sub     rax, rcx                    ; Relative offset

    ; Write offset to code_buffer
    lea     rdx, [code_buffer]
    mov     [rdx + rbx], eax            ; Write 32-bit relative offset

.patch_next:
    inc     r13
    jmp     .patch_loop

.patch_done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; call function by name
; Input: rdi = function name (interned string)
emit_call_func:
    push    rbx
    push    r12
    mov     r12, rdi                    ; Save function name

    mov     dil, 0xE8
    call    emit_byte

    ; Record patch location (where the rel32 starts)
    mov     rax, [code_ptr]
    lea     rbx, [code_buffer]
    sub     rax, rbx                    ; code_offset
    mov     rbx, [call_patches_count]
    shl     rbx, 4                      ; * 16 (each entry is 2 qwords)
    lea     rcx, [call_patches]
    mov     [rcx + rbx], rax            ; Store code_offset
    mov     [rcx + rbx + 8], r12        ; Store function name
    inc     qword [call_patches_count]

    xor     edi, edi                    ; Placeholder
    call    emit_dword

    pop     r12
    pop     rbx
    ret

; -----------------------------------------------------------------------------
; emit_startup_code - Emit program entry point
; -----------------------------------------------------------------------------
; Input: rdi = interned "principal" name pointer
; Emits:
;   xor rbp, rbp          ; Clear frame pointer
;   and rsp, -16          ; Align stack
;   call principal        ; Call main (will be patched)
;   mov rdi, rax          ; Exit code = return value
;   mov eax, 60           ; sys_exit
;   syscall
; -----------------------------------------------------------------------------
emit_startup_code:
    push    rbp
    mov     rbp, rsp
    push    rbx
    mov     rbx, rdi                    ; Save principal name

    ; xor rbp, rbp = 48 31 ED
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x31
    call    emit_byte
    mov     dil, 0xED
    call    emit_byte

    ; and rsp, -16 = 48 83 E4 F0
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x83
    call    emit_byte
    mov     dil, 0xE4
    call    emit_byte
    mov     dil, 0xF0
    call    emit_byte

    ; call principal - use emit_call_func to record patch
    mov     rdi, rbx                    ; principal name
    call    emit_call_func

    ; mov rdi, rax = 48 89 C7
    mov     dil, 0x48
    call    emit_byte
    mov     dil, 0x89
    call    emit_byte
    mov     dil, 0xC7
    call    emit_byte

    ; mov eax, 60 = B8 3C 00 00 00
    mov     dil, 0xB8
    call    emit_byte
    mov     edi, 60
    call    emit_dword

    ; syscall = 0F 05
    mov     dil, 0x0F
    call    emit_byte
    mov     dil, 0x05
    call    emit_byte

    pop     rbx
    pop     rbp
    ret

; =============================================================================
; END OF FILE
; =============================================================================
