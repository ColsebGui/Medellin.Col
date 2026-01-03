# Stage 0 Compiler Architecture

Hand-written x86-64 assembly compiler for minimal Medellin.Col subset.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           STAGE 0 PIPELINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Source (.col)                                                              │
│       │                                                                     │
│       ▼                                                                     │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌───────┐ │
│  │  Lexer  │────▶│ Parser  │────▶│  Types  │────▶│ Codegen │────▶│  ELF  │ │
│  └─────────┘     └─────────┘     └─────────┘     └─────────┘     └───────┘ │
│       │               │               │               │               │     │
│       ▼               ▼               ▼               ▼               ▼     │
│    Tokens           AST          Typed AST        x86-64          Binary   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Memory Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              MEMORY MAP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  0x00000000 ─┬─ Source Buffer (read-only)                                  │
│              │   - Raw source code bytes                                   │
│              │   - Max 1MB                                                  │
│  0x00100000 ─┼─ Token Buffer                                               │
│              │   - Array of Token structs                                  │
│              │   - Max 64K tokens                                          │
│  0x00200000 ─┼─ AST Arena                                                  │
│              │   - All AST nodes allocated here                            │
│              │   - Max 4MB                                                  │
│  0x00600000 ─┼─ String Table                                               │
│              │   - Interned strings                                        │
│              │   - Max 1MB                                                  │
│  0x00700000 ─┼─ Symbol Table                                               │
│              │   - Variables, functions                                    │
│              │   - Max 1MB                                                  │
│  0x00800000 ─┼─ Code Buffer                                                │
│              │   - Generated x86-64 bytes                                  │
│              │   - Max 4MB                                                  │
│  0x00C00000 ─┼─ Data Buffer                                                │
│              │   - String literals, constants                              │
│              │   - Max 1MB                                                  │
│  0x00D00000 ─┴─ Scratch Space                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Structures

### Token (24 bytes)

```
┌────────────────┬────────────────┬────────────────┐
│  type (1)      │  padding (7)   │  value (8)     │
├────────────────┴────────────────┼────────────────┤
│  line (4)      │  column (4)    │                │
└────────────────┴────────────────┴────────────────┘

type:     Token type (see TOKEN_* constants)
value:    Depends on type:
          - IDENT/KEYWORD: pointer to string table
          - NUMBER: literal value
          - STRING: pointer to string table
line:     Source line number (1-based)
column:   Source column number (1-based)
```

### AST Node Header (16 bytes)

```
┌────────────────┬────────────────┬────────────────┐
│  kind (1)      │  flags (1)     │  padding (6)   │
├────────────────┴────────────────┴────────────────┤
│  type_id (8)   - Type of this expression         │
└──────────────────────────────────────────────────┘

Followed by kind-specific data.
```

### Symbol Entry (48 bytes)

```
┌────────────────────────────────────────────────────┐
│  name (8)      - Pointer to string table           │
├────────────────────────────────────────────────────┤
│  type_id (8)   - Type of this symbol               │
├────────────────────────────────────────────────────┤
│  kind (1)      - VAR, FUNC, PARAM, CONST           │
│  scope (1)     - Scope depth                       │
│  flags (2)     - Mutable, initialized, etc.        │
│  padding (4)                                       │
├────────────────────────────────────────────────────┤
│  offset (8)    - Stack offset or global address    │
├────────────────────────────────────────────────────┤
│  next (8)      - Next symbol in hash chain         │
└────────────────────────────────────────────────────┘
```

## Token Types

```nasm
; Literals
TOKEN_EOF           equ 0
TOKEN_NUMERO        equ 1
TOKEN_TEXTO         equ 2
TOKEN_VERDAD        equ 3
TOKEN_FALSO         equ 4

; Identifiers and keywords
TOKEN_IDENT         equ 10
TOKEN_KEYWORD       equ 11

; Operators
TOKEN_MAS           equ 20   ; +, mas
TOKEN_MENOS         equ 21   ; -, menos
TOKEN_POR           equ 22   ; *, por
TOKEN_ENTRE         equ 23   ; /, entre
TOKEN_MODULO        equ 24   ; %, modulo

; Comparison
TOKEN_IGUAL         equ 30   ; ==, es igual a
TOKEN_NO_IGUAL      equ 31   ; !=, no es
TOKEN_MAYOR         equ 32   ; >, es mayor que
TOKEN_MENOR         equ 33   ; <, es menor que
TOKEN_MAYOR_IGUAL   equ 34   ; >=, es al menos
TOKEN_MENOR_IGUAL   equ 35   ; <=, es máximo

; Logical
TOKEN_Y             equ 40   ; &&, y
TOKEN_O             equ 41   ; ||, o
TOKEN_NO            equ 42   ; !, no

; Punctuation
TOKEN_PAREN_IZQ     equ 50   ; (
TOKEN_PAREN_DER     equ 51   ; )
TOKEN_CORCHETE_IZQ  equ 52   ; [
TOKEN_CORCHETE_DER  equ 53   ; ]
TOKEN_DOS_PUNTOS    equ 54   ; :
TOKEN_COMA          equ 55   ; ,
TOKEN_PUNTO         equ 56   ; .
TOKEN_NEWLINE       equ 57   ; \n

; Keywords (50+ reserved words)
TOKEN_KW_PARCERO    equ 100
TOKEN_KW_FIN        equ 101
TOKEN_KW_SI         equ 102
TOKEN_KW_ENTONCES   equ 103
TOKEN_KW_SINO       equ 104
TOKEN_KW_LISTO      equ 105
TOKEN_KW_MIENTRAS   equ 106
TOKEN_KW_HAGA       equ 107
TOKEN_KW_DESDE      equ 108
TOKEN_KW_SIENDO     equ 109
TOKEN_KW_HASTA      equ 110
TOKEN_KW_DEVUELVASE equ 111
TOKEN_KW_CON        equ 112
TOKEN_KW_DIGA       equ 113
TOKEN_KW_NUMERO     equ 114
TOKEN_KW_TEXTO      equ 115
TOKEN_KW_BOOLEANO   equ 116
TOKEN_KW_ES         equ 117
TOKEN_KW_COSA       equ 118
TOKEN_KW_TIPO       equ 119
TOKEN_KW_DEVUELVE   equ 120
TOKEN_KW_SUME       equ 121
TOKEN_KW_QUITE      equ 122
TOKEN_KW_NADA       equ 123
```

## AST Node Types

```nasm
; Declarations
AST_PROGRAMA        equ 1
AST_PARCERO         equ 2
AST_PARAMETRO       equ 3
AST_VARIABLE        equ 4

; Statements
AST_BLOQUE          equ 20
AST_SI              equ 21
AST_MIENTRAS        equ 22
AST_DESDE           equ 23
AST_DEVUELVASE      equ 24
AST_DIGA            equ 25
AST_ASIGNACION      equ 26
AST_EXPR_STMT       equ 27

; Expressions
AST_BINARIO         equ 40
AST_UNARIO          equ 41
AST_LLAMADA         equ 42
AST_IDENT           equ 43
AST_NUMERO_LIT      equ 44
AST_TEXTO_LIT       equ 45
AST_BOOL_LIT        equ 46
AST_ACCESO          equ 47
AST_INDICE          equ 48
```

## Calling Convention

Stage 0 uses System V AMD64 ABI:

- Arguments: RDI, RSI, RDX, RCX, R8, R9, then stack
- Return: RAX (and RDX for 128-bit)
- Caller-saved: RAX, RCX, RDX, RSI, RDI, R8-R11
- Callee-saved: RBX, RBP, R12-R15
- Stack: 16-byte aligned before CALL

## Register Usage in Compiler

| Register | Usage |
|----------|-------|
| RAX | Return values, scratch |
| RBX | Preserved, general |
| RCX | Scratch, string ops |
| RDX | Scratch |
| RSI | Source pointer |
| RDI | Destination pointer |
| RBP | Frame pointer |
| RSP | Stack pointer |
| R8-R11 | Scratch |
| R12 | Current token pointer |
| R13 | AST arena pointer |
| R14 | Code buffer pointer |
| R15 | Error state |

## Error Handling

Errors set R15 to non-zero and store error info:

```nasm
section .data
    error_line:     dq 0    ; Line number
    error_column:   dq 0    ; Column number
    error_message:  dq 0    ; Pointer to message
```

## File Structure

```
stage0/
├── ARCHITECTURE.md     ; This file
├── Makefile           ; Build system
├── main.asm           ; Entry point
├── lexer.asm          ; Tokenizer
├── parser.asm         ; Parser
├── types.asm          ; Type checker
├── codegen.asm        ; x86-64 generator
├── elf.asm            ; ELF file writer
├── strings.asm        ; String table
├── symbols.asm        ; Symbol table
├── errors.asm         ; Error handling
└── utils.asm          ; Utilities
```

## Compilation Phases

### Phase 1: Lexing
1. Read source file into buffer
2. Scan characters into tokens
3. Intern strings
4. Handle UTF-8 for identifiers

### Phase 2: Parsing
1. Recursive descent parser
2. Build AST in arena
3. Report syntax errors with location

### Phase 3: Type Checking
1. Build symbol table
2. Infer/check types
3. Check ownership (simple scope-based)
4. Report type errors

### Phase 4: Code Generation
1. Traverse typed AST
2. Emit x86-64 instructions
3. Allocate stack slots
4. Generate function prologues/epilogues

### Phase 5: ELF Output
1. Build ELF header
2. Create program headers
3. Write sections (.text, .data, .rodata)
4. Output executable file
