; =============================================================================
; MEDELLIN.COL - STAGE 0 COMPILER: MAIN
; =============================================================================
; Entry point for the Stage 0 bootstrap compiler
; Compiles a .col source file to an ELF executable
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; System calls
; -----------------------------------------------------------------------------
%define SYS_READ        0
%define SYS_WRITE       1
%define SYS_OPEN        2
%define SYS_CLOSE       3
%define SYS_FSTAT       5
%define SYS_MMAP        9
%define SYS_EXIT        60

%define O_RDONLY        0
%define O_WRONLY        1
%define O_CREAT         64
%define O_TRUNC         512

%define PROT_READ       1
%define PROT_WRITE      2
%define MAP_PRIVATE     2
%define MAP_ANONYMOUS   32

%define STDOUT          1
%define STDERR          2

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern lexer_init
extern parser_parse
extern types_check
extern codegen_generate
extern elf_write
extern elf_buffer
extern elf_size
extern error_report

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global _start

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Usage message
    msg_usage:      db "Uso: medellin <archivo.col> [salida]", 10
    msg_usage_len   equ $ - msg_usage

    ; Error messages
    msg_err_open:   db "Error: No se pudo abrir el archivo", 10
    msg_err_open_len equ $ - msg_err_open

    msg_err_read:   db "Error: No se pudo leer el archivo", 10
    msg_err_read_len equ $ - msg_err_read

    msg_err_parse:  db "Error: Fallo el analisis sintactico", 10
    msg_err_parse_len equ $ - msg_err_parse

    msg_err_types:  db "Error: Fallo la verificacion de tipos", 10
    msg_err_types_len equ $ - msg_err_types

    msg_err_codegen: db "Error: Fallo la generacion de codigo", 10
    msg_err_codegen_len equ $ - msg_err_codegen

    msg_err_write:  db "Error: No se pudo escribir el ejecutable", 10
    msg_err_write_len equ $ - msg_err_write

    ; Success messages
    msg_lexing:     db "Analizando lexico...", 10
    msg_lexing_len  equ $ - msg_lexing

    msg_parsing:    db "Analizando sintaxis...", 10
    msg_parsing_len equ $ - msg_parsing

    msg_typing:     db "Verificando tipos...", 10
    msg_typing_len  equ $ - msg_typing

    msg_codegen:    db "Generando codigo...", 10
    msg_codegen_len equ $ - msg_codegen

    msg_writing:    db "Escribiendo ejecutable...", 10
    msg_writing_len equ $ - msg_writing

    msg_success:    db "Compilacion exitosa!", 10
    msg_success_len equ $ - msg_success

    ; Default output name
    default_output: db "a.out", 0

section .bss
    ; Source buffer
    alignb 8
    source_buffer:  resb 1024 * 1024    ; 1MB max source
    source_size:    resq 1

    ; Command line args
    argc:           resq 1
    argv:           resq 1

    ; File descriptors
    input_fd:       resq 1
    output_fd:      resq 1

    ; Output filename
    output_name:    resq 1

section .text

; -----------------------------------------------------------------------------
; _start - Program entry point
; -----------------------------------------------------------------------------
_start:
    ; Get argc and argv from stack
    mov     rax, [rsp]              ; argc
    mov     [argc], rax
    lea     rax, [rsp + 8]          ; argv
    mov     [argv], rax

    ; Check argc >= 2
    mov     rax, [argc]
    cmp     rax, 2
    jl      .usage

    ; Get input filename (argv[1])
    mov     rax, [argv]
    mov     rdi, [rax + 8]          ; argv[1]

    ; Get output filename (argv[2] or default)
    mov     rax, [argc]
    cmp     rax, 3
    jl      .use_default_output

    mov     rax, [argv]
    mov     rax, [rax + 16]         ; argv[2]
    mov     [output_name], rax
    jmp     .open_input

.use_default_output:
    lea     rax, [default_output]
    mov     [output_name], rax

.open_input:
    ; Open input file
    mov     rax, [argv]
    mov     rdi, [rax + 8]          ; argv[1]
    mov     rsi, O_RDONLY
    xor     rdx, rdx
    mov     rax, SYS_OPEN
    syscall

    test    rax, rax
    js      .err_open

    mov     [input_fd], rax

    ; Read source file
    mov     rdi, rax
    lea     rsi, [source_buffer]
    mov     rdx, 1024 * 1024 - 1    ; Max size - 1 for null terminator
    mov     rax, SYS_READ
    syscall

    test    rax, rax
    js      .err_read

    mov     [source_size], rax

    ; Null terminate
    lea     rdi, [source_buffer]
    add     rdi, rax
    mov     byte [rdi], 0

    ; Close input file
    mov     rdi, [input_fd]
    mov     rax, SYS_CLOSE
    syscall

    ; Print lexing message
    mov     rdi, STDOUT
    lea     rsi, [msg_lexing]
    mov     rdx, msg_lexing_len
    mov     rax, SYS_WRITE
    syscall

    ; Phase 1: Lexical analysis
    lea     rdi, [source_buffer]
    mov     rsi, [source_size]
    call    lexer_init

    ; Print parsing message
    mov     rdi, STDOUT
    lea     rsi, [msg_parsing]
    mov     rdx, msg_parsing_len
    mov     rax, SYS_WRITE
    syscall

    ; Phase 2: Parse
    call    parser_parse
    test    rax, rax
    jz      .err_parse

    push    rax                     ; Save AST

    ; Print type checking message
    mov     rdi, STDOUT
    lea     rsi, [msg_typing]
    mov     rdx, msg_typing_len
    mov     rax, SYS_WRITE
    syscall

    ; Phase 3: Type check
    pop     rdi                     ; AST
    push    rdi                     ; Save again
    call    types_check
    test    rax, rax
    jnz     .err_types

    ; Print code generation message
    mov     rdi, STDOUT
    lea     rsi, [msg_codegen]
    mov     rdx, msg_codegen_len
    mov     rax, SYS_WRITE
    syscall

    ; Phase 4: Code generation
    pop     rdi                     ; AST
    call    codegen_generate
    test    rax, rax
    jz      .err_codegen

    ; Print writing message
    mov     rdi, STDOUT
    lea     rsi, [msg_writing]
    mov     rdx, msg_writing_len
    mov     rax, SYS_WRITE
    syscall

    ; Phase 5: Write ELF
    xor     rdi, rdi                ; Entry at offset 0 (first function)
    call    elf_write
    test    rax, rax
    jz      .err_write

    ; Open output file
    mov     rdi, [output_name]
    mov     rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov     rdx, 0o755              ; rwxr-xr-x
    mov     rax, SYS_OPEN
    syscall

    test    rax, rax
    js      .err_write

    mov     [output_fd], rax

    ; Write ELF to file
    mov     rdi, rax
    lea     rsi, [elf_buffer]
    mov     rdx, [elf_size]
    mov     rax, SYS_WRITE
    syscall

    ; Close output file
    mov     rdi, [output_fd]
    mov     rax, SYS_CLOSE
    syscall

    ; Print success message
    mov     rdi, STDOUT
    lea     rsi, [msg_success]
    mov     rdx, msg_success_len
    mov     rax, SYS_WRITE
    syscall

    ; Exit success
    xor     rdi, rdi
    mov     rax, SYS_EXIT
    syscall

.usage:
    mov     rdi, STDERR
    lea     rsi, [msg_usage]
    mov     rdx, msg_usage_len
    mov     rax, SYS_WRITE
    syscall
    jmp     .exit_error

.err_open:
    mov     rdi, STDERR
    lea     rsi, [msg_err_open]
    mov     rdx, msg_err_open_len
    mov     rax, SYS_WRITE
    syscall
    jmp     .exit_error

.err_read:
    mov     rdi, STDERR
    lea     rsi, [msg_err_read]
    mov     rdx, msg_err_read_len
    mov     rax, SYS_WRITE
    syscall
    jmp     .exit_error

.err_parse:
    mov     rdi, STDERR
    lea     rsi, [msg_err_parse]
    mov     rdx, msg_err_parse_len
    mov     rax, SYS_WRITE
    syscall
    jmp     .exit_error

.err_types:
    mov     rdi, STDERR
    lea     rsi, [msg_err_types]
    mov     rdx, msg_err_types_len
    mov     rax, SYS_WRITE
    syscall
    jmp     .exit_error

.err_codegen:
    mov     rdi, STDERR
    lea     rsi, [msg_err_codegen]
    mov     rdx, msg_err_codegen_len
    mov     rax, SYS_WRITE
    syscall
    jmp     .exit_error

.err_write:
    mov     rdi, STDERR
    lea     rsi, [msg_err_write]
    mov     rdx, msg_err_write_len
    mov     rax, SYS_WRITE
    syscall

.exit_error:
    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

; =============================================================================
; END OF FILE
; =============================================================================
