# Medellin.Col Roadmap

A phased approach to building a systems programming language from pure assembly to self-hosting compiler with full safety guarantees.

---

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MEDELLIN.COL ROADMAP                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PHASE 1          PHASE 2          PHASE 3          PHASE 4          PHASE 5
│  Foundation       Stage 0          Stage 1          Full Language    Ecosystem
│  ───────────      ───────          ───────          ────────────     ─────────
│  ▪ Spec           ▪ ASM Lexer      ▪ Self-compile   ▪ Refinements   ▪ Std Lib
│  ▪ Grammar        ▪ ASM Parser     ▪ Full types     ▪ Effects       ▪ Tooling
│  ▪ Runtime        ▪ ASM Codegen    ▪ Regions        ▪ Capabilities  ▪ Package Mgr
│  ▪ Memory         ▪ ELF Output     ▪ Generics       ▪ Linear types  ▪ IDE Support
│                                                                             │
│  Duration: ~3mo   Duration: ~4mo   Duration: ~4mo   Duration: ~3mo  Ongoing │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation

**Goal:** Establish specifications, design decisions, and minimal runtime.

### 1.1 Language Specification

- [ ] **Formal grammar** — Complete BNF/EBNF grammar for Medellin.Col
- [ ] **Keyword list** — All Colombian Spanish keywords finalized
- [ ] **Operator precedence** — Arithmetic, logical, comparison operators
- [ ] **Type system spec** — Primitive types, composite types, type rules
- [ ] **Ownership rules** — Region-based memory model specification
- [ ] **Effect system spec** — Effect categories and propagation rules
- [ ] **Capability system spec** — Capability types and restrictions

### 1.2 Core Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Integer sizes | 8, 16, 32, 64 bit signed/unsigned | Match hardware |
| Default integer | 64-bit signed (`numero`) | Modern, safe from overflow |
| String encoding | UTF-8 | International support, Colombian characters |
| Array indexing | 0-based | Industry standard |
| Entry point | `parcero principal()` | Clear, Colombian |
| File extension | `.col` | Short, distinctive |

### 1.3 Assembly Runtime (Linux x86-64)

Minimal runtime in pure assembly:

- [ ] **Entry point** — `_start`, stack setup, call `principal`
- [ ] **Exit** — `sys_exit` wrapper
- [ ] **Memory allocator** — Bump allocator for Stage 0
- [ ] **Print** — `sys_write` to stdout
- [ ] **Panic handler** — Error message, exit with code

### 1.4 Deliverables

| Artifact | Description |
|----------|-------------|
| `spec/grammar.ebnf` | Formal grammar |
| `spec/types.md` | Type system specification |
| `spec/ownership.md` | Memory/ownership model |
| `runtime/linux_x86_64/` | Assembly runtime |

---

## Phase 2: Stage 0 Compiler

**Goal:** Hand-written assembly compiler that can compile minimal Medellin.Col.

### 2.1 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        STAGE 0 COMPILER                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Source (.col) ──► Lexer ──► Parser ──► Type Check ──► Codegen │
│                      │          │           │             │     │
│                      ▼          ▼           ▼             ▼     │
│                   Tokens      AST       Typed AST      x86-64   │
│                                                           │     │
│                                                           ▼     │
│                                                     ELF Binary  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Lexer (Assembly)

- [ ] **Token types** — Keywords, identifiers, literals, operators, punctuation
- [ ] **String handling** — UTF-8 aware, escape sequences
- [ ] **Number parsing** — Integer literals, decimal literals
- [ ] **Comment handling** — Line comments (`;`)
- [ ] **Error reporting** — Line/column tracking

### 2.3 Parser (Assembly)

- [ ] **Recursive descent** — Hand-written parser
- [ ] **AST nodes** — Expression, statement, declaration types
- [ ] **Precedence climbing** — For expressions
- [ ] **Error recovery** — Basic synchronization

### 2.4 Type Checker (Assembly)

- [ ] **Type inference** — Local variable types
- [ ] **Type checking** — Expression type validation
- [ ] **Ownership tracking** — Simple scope-based ownership
- [ ] **Borrow checking** — Basic borrow validation

### 2.5 Code Generator (Assembly)

- [ ] **x86-64 instruction selection** — Map operations to instructions
- [ ] **Register allocation** — Simple linear scan
- [ ] **Stack frame layout** — Locals, arguments, saved registers
- [ ] **Function calls** — System V AMD64 ABI
- [ ] **Syscall emission** — Direct Linux syscalls

### 2.6 ELF Output (Assembly)

- [ ] **ELF64 header** — Proper header generation
- [ ] **Program headers** — PT_LOAD for code and data
- [ ] **Section headers** — .text, .data, .bss
- [ ] **Symbol table** — For debugging (optional)

### 2.7 Minimal Language Subset

Stage 0 must compile this subset:

| Feature | Syntax | Notes |
|---------|--------|-------|
| Integer variables | `numero x es 5` | 64-bit signed |
| Boolean variables | `booleano b es verdad` | true/false |
| String variables | `texto s es "hola"` | UTF-8 |
| Arithmetic | `sume`, `quite`, `por`, `entre` | +, -, *, / |
| Comparison | `es igual`, `es mayor`, `es menor` | ==, >, < |
| If/else | `si... entonces... si no... listo` | Conditionals |
| While loop | `mientras... haga... listo` | Loops |
| Functions | `parcero nombre() ... fin parcero` | Procedures |
| Return | `devuélvase con valor` | Return value |
| Print | `diga "mensaje"` | stdout output |
| Function calls | `resultado es funcion(args)` | Call and assign |

### 2.8 Deliverables

| Artifact | Description |
|----------|-------------|
| `stage0/lexer.asm` | Tokenizer |
| `stage0/parser.asm` | Parser and AST builder |
| `stage0/types.asm` | Type checker |
| `stage0/codegen.asm` | x86-64 code generator |
| `stage0/elf.asm` | ELF file writer |
| `stage0/main.asm` | Driver program |
| `medellin0` | Compiled Stage 0 binary |

### 2.9 Testing

- [ ] Lexer tests — Token output validation
- [ ] Parser tests — AST structure validation
- [ ] End-to-end tests — Compile and run simple programs
- [ ] Comparison tests — Output matches expected

---

## Phase 3: Stage 1 Compiler

**Goal:** Compiler written in Medellin.Col, compiled by Stage 0, with full type system.

### 3.1 Self-Compilation

Stage 1 is written in Medellin.Col and compiled by Stage 0:

```
stage0/medellin0 compiles stage1/*.col ──► medellin1
medellin1 compiles stage1/*.col ──► medellin1' (verify identical)
```

### 3.2 Full Type System

- [ ] **Primitive types** — `numero`, `decimal`, `texto`, `booleano`, `byte`
- [ ] **Sized integers** — `numero8`, `numero16`, `numero32`, `numero64`
- [ ] **Unsigned** — `natural`, `natural8`, `natural16`, `natural32`, `natural64`
- [ ] **Option type** — `quizas T`
- [ ] **Result type** — `T o error`
- [ ] **Arrays** — `lista de T`, `arreglo[N] de T`
- [ ] **Structs** — `cosa Nombre ... fin cosa`
- [ ] **Enums** — `tipo Nombre es A | B | C fin tipo`
- [ ] **Tuples** — `(T1, T2, T3)`

### 3.3 Region-Based Memory

- [ ] **Region declarations** — `region nombre haga ... fin region`
- [ ] **Automatic region inference** — Compiler assigns regions
- [ ] **Region escape analysis** — Prevent escaping references
- [ ] **Nested regions** — Proper lifetime ordering

### 3.4 Generics

- [ ] **Type parameters** — `cosa Lista[T] ... fin cosa`
- [ ] **Generic functions** — `parcero intercambiar[T](a: T, b: T)`
- [ ] **Constraints** — `parcero ordenar[T: Ordenable](lista: Lista[T])`
- [ ] **Monomorphization** — Generate specialized code

### 3.5 Pattern Matching

```
cuando valor sea
    Exito(x): procesar(x)
    Falla(e): manejar(e)
listo
```

- [ ] **Match expressions** — `cuando... sea... listo`
- [ ] **Destructuring** — Extract values from enums/structs
- [ ] **Exhaustiveness** — Compiler ensures all cases covered
- [ ] **Guards** — `Numero(n) si n > 0: ...`

### 3.6 Improved Error Messages

- [ ] **Source location** — File, line, column
- [ ] **Context display** — Show relevant code
- [ ] **Suggestions** — "Did you mean...?"
- [ ] **Colombian personality** — Friendly, professional messages

### 3.7 Additional Platforms

- [ ] **FreeBSD x86-64** — ELF with BSD syscalls
- [ ] **Windows x86-64** — PE format, kernel32 imports
- [ ] **macOS x86-64** — Mach-O format

### 3.8 Deliverables

| Artifact | Description |
|----------|-------------|
| `stage1/lexer.col` | Tokenizer in Medellin.Col |
| `stage1/parser.col` | Parser in Medellin.Col |
| `stage1/types.col` | Type system in Medellin.Col |
| `stage1/regions.col` | Region inference |
| `stage1/codegen.col` | Code generator |
| `stage1/elf.col` | ELF writer |
| `stage1/pe.col` | PE writer (Windows) |
| `stage1/macho.col` | Mach-O writer (macOS) |
| `medellin1` | Stage 1 compiler binary |

---

## Phase 4: Full Language

**Goal:** Complete language with all safety features.

### 4.1 Refinement Types

Types with logical predicates verified at compile time:

```
tipo NumeroPositivo es numero donde valor > 0
tipo IndiceValido[N] es numero donde valor >= 0 y valor < N
```

- [ ] **Predicate syntax** — `donde` clause on types
- [ ] **SMT integration** — Z3 or similar solver
- [ ] **Inference** — Propagate refinements through code
- [ ] **Error messages** — Explain proof failures
- [ ] **Escape hatch** — `asuma` for unprovable cases (inserts runtime check)

### 4.2 Effect System

Track side effects in function signatures:

```
parcero pura(x: numero) devuelve numero
    ; No effects allowed
fin parcero

parcero con_io(ruta: texto) devuelve texto con efecto IO
    ; IO operations allowed
fin parcero
```

- [ ] **Effect categories** — `IO`, `Estado`, `Falla`
- [ ] **Effect inference** — Automatic effect detection
- [ ] **Effect polymorphism** — Generic over effects
- [ ] **Effect handlers** — Interpret effects

### 4.3 Capability-Based Security

Restrict what code can access:

```
parcero procesar(datos: texto) requiere [Archivos]
    ; Can only access filesystem
fin parcero

traiga dependencia con capacidades []
; Dependency cannot access anything
```

- [ ] **Capability types** — `Archivos`, `Red`, `Sistema`, `Tiempo`, `Aleatorio`
- [ ] **Capability checking** — Enforce at compile time
- [ ] **Capability delegation** — Pass capabilities explicitly
- [ ] **Dependency restriction** — Limit third-party code

### 4.4 Linear Types

Resources that must be used exactly once:

```
tipo Archivo es lineal

parcero usar_archivo(f: Archivo)
    ; Must consume f, cannot ignore
fin parcero
```

- [ ] **Linear modifier** — Mark types as linear
- [ ] **Consumption checking** — Verify linear values used
- [ ] **Explicit drop** — `descartar` for intentional disposal
- [ ] **Conditional handling** — Both branches must consume

### 4.5 Concurrency

Safe concurrent programming:

```
tarea procesar(datos: tome Lista de Numero)
    ; Task owns the data, no sharing
fin tarea

canal de Numero resultados es nuevo canal
envie 42 por resultados
numero valor es reciba de resultados
```

- [ ] **Tasks** — Lightweight concurrent execution
- [ ] **Channels** — Type-safe message passing
- [ ] **Ownership transfer** — Data moves between tasks
- [ ] **No shared mutable state** — Enforced by ownership

### 4.6 Advanced Features

- [ ] **Traits/Interfaces** — `rasgo Nombre ... fin rasgo`
- [ ] **Operator overloading** — Limited, for numeric types
- [ ] **Compile-time evaluation** — `comptime` blocks
- [ ] **Macros** — Hygienic, syntax-based
- [ ] **Inline assembly** — Compiler-verified, not `unsafe`

### 4.7 Deliverables

| Artifact | Description |
|----------|-------------|
| `stage2/refinements.col` | Refinement type checker |
| `stage2/effects.col` | Effect system |
| `stage2/capabilities.col` | Capability checker |
| `stage2/linear.col` | Linear type checker |
| `stage2/concurrency.col` | Task/channel runtime |
| `medellin` | Full compiler binary |

---

## Phase 5: Ecosystem

**Goal:** Production-ready toolchain and ecosystem.

### 5.1 Standard Library

Core modules written in Medellin.Col:

| Module | Contents |
|--------|----------|
| `medellin/texto` | String manipulation |
| `medellin/lista` | Dynamic arrays |
| `medellin/mapa` | Hash maps |
| `medellin/conjunto` | Hash sets |
| `medellin/archivos` | File I/O |
| `medellin/red` | Networking (TCP, UDP, HTTP) |
| `medellin/tiempo` | Date, time, duration |
| `medellin/mates` | Math functions |
| `medellin/aleatorio` | Random number generation |
| `medellin/json` | JSON parsing/generation |
| `medellin/argumentos` | Command line parsing |
| `medellin/hilos` | Threading primitives |
| `medellin/crypto` | Cryptographic functions |

### 5.2 Package Manager (Gremio)

```bash
gremio iniciar                    # Create new project
gremio instalar paquete           # Install dependency
gremio actualizar                 # Update dependencies
gremio publicar                   # Publish package
gremio buscar "término"           # Search packages
```

- [ ] **Project initialization** — `Gremio.toml` generation
- [ ] **Dependency resolution** — Version solving
- [ ] **Lock file** — `gremio.lock` for reproducibility
- [ ] **Registry** — Central package registry
- [ ] **Semantic versioning** — Enforced by compiler

### 5.3 Formatter (Disciplina)

```bash
disciplina formatear src/         # Format files
disciplina verificar src/         # Check formatting
```

- [ ] **Canonical style** — One true format
- [ ] **Automatic formatting** — No configuration needed
- [ ] **Diff mode** — Show proposed changes

### 5.4 Linter (Fiscal)

```bash
fiscal revisar src/               # Run linter
fiscal arreglar src/              # Auto-fix issues
```

- [ ] **Style lints** — Naming conventions, structure
- [ ] **Bug detection** — Suspicious patterns
- [ ] **Performance hints** — Optimization suggestions
- [ ] **Security checks** — Common vulnerability patterns

### 5.5 Test Runner (Auditor)

```bash
auditor correr                    # Run all tests
auditor correr pruebas/test_x.col # Run specific test
auditor cobertura                 # Coverage report
```

- [ ] **Test discovery** — Find `prueba` functions
- [ ] **Assertions** — `afirme`, `afirme_igual`, `afirme_falla`
- [ ] **Coverage** — Line and branch coverage
- [ ] **Benchmarks** — Performance testing

### 5.6 IDE Support

- [ ] **Language Server Protocol** — LSP implementation
- [ ] **VS Code extension** — Syntax highlighting, diagnostics
- [ ] **Vim/Neovim plugin** — Syntax, completion
- [ ] **Tree-sitter grammar** — For editors using tree-sitter

### 5.7 Documentation Generator (Notario)

```bash
notario generar                   # Generate docs
notario servir                    # Local doc server
```

- [ ] **Doc comments** — `;;` documentation comments
- [ ] **HTML output** — Searchable documentation
- [ ] **Examples** — Runnable code examples
- [ ] **Cross-references** — Link between definitions

### 5.8 Debugger Support

- [ ] **DWARF debug info** — Standard debug format
- [ ] **GDB integration** — Use GDB for debugging
- [ ] **LLDB integration** — macOS debugging
- [ ] **Source mapping** — Map binary to source

---

## Milestones

### Milestone 1: "Hola Mundo"

- [ ] Stage 0 lexer complete
- [ ] Stage 0 parser complete
- [ ] Basic codegen working
- [ ] Can compile and run: `diga "Hola Mundo"`

### Milestone 2: "Fibonacci"

- [ ] Functions working
- [ ] Recursion working
- [ ] Conditionals working
- [ ] Can compile and run recursive fibonacci

### Milestone 3: "Self-Aware"

- [ ] Stage 0 complete
- [ ] Stage 1 compiles successfully
- [ ] Stage 1 can compile itself
- [ ] Identical output verification

### Milestone 4: "Safe"

- [ ] Region-based memory working
- [ ] Borrow checking working
- [ ] Option/Result types working
- [ ] No memory safety bugs possible

### Milestone 5: "Smart"

- [ ] Refinement types working
- [ ] Effect system working
- [ ] Capability system working
- [ ] Logic errors caught at compile time

### Milestone 6: "Complete"

- [ ] All platforms supported
- [ ] Standard library complete
- [ ] Package manager working
- [ ] Documentation complete

### Milestone 7: "Production"

- [ ] Real-world projects using Medellin.Col
- [ ] Performance competitive with Rust/C
- [ ] Community growing
- [ ] Third-party packages available

---

## Technical Specifications

### File Structure

```
Medellin.Col/
├── spec/                    # Language specification
│   ├── grammar.ebnf
│   ├── types.md
│   ├── ownership.md
│   ├── effects.md
│   └── capabilities.md
├── runtime/                 # Assembly runtime
│   ├── linux_x86_64/
│   ├── freebsd_x86_64/
│   ├── windows_x86_64/
│   └── macos_x86_64/
├── stage0/                  # Assembly compiler
│   ├── lexer.asm
│   ├── parser.asm
│   ├── types.asm
│   ├── codegen.asm
│   ├── elf.asm
│   └── main.asm
├── stage1/                  # Medellin.Col compiler
│   ├── lexer.col
│   ├── parser.col
│   ├── types.col
│   ├── regions.col
│   ├── codegen.col
│   └── main.col
├── stage2/                  # Full compiler
│   ├── refinements.col
│   ├── effects.col
│   ├── capabilities.col
│   ├── linear.col
│   └── main.col
├── stdlib/                  # Standard library
│   ├── texto.col
│   ├── lista.col
│   ├── mapa.col
│   └── ...
├── tools/                   # Toolchain
│   ├── gremio/             # Package manager
│   ├── disciplina/         # Formatter
│   ├── fiscal/             # Linter
│   ├── auditor/            # Test runner
│   └── notario/            # Doc generator
├── tests/                   # Test suite
│   ├── lexer/
│   ├── parser/
│   ├── types/
│   └── e2e/
├── docs/                    # Documentation
│   ├── tutorial/
│   ├── reference/
│   └── internals/
├── examples/                # Example programs
│   ├── hola_mundo.col
│   ├── fibonacci.col
│   └── ...
├── README.md
├── ROADMAP.md
└── LICENSE
```

### Assembly Style Guide (Stage 0)

```asm
; Medellin.Col Stage 0 - Assembly Style Guide
;
; 1. Use NASM syntax (Intel)
; 2. Labels: snake_case
; 3. Constants: SCREAMING_SNAKE_CASE
; 4. Comments: Spanish preferred, English acceptable
; 5. One instruction per line
; 6. Align operands with tabs

section .data
    BUFFER_SIZE equ 4096
    mensaje_error: db "Error: ", 0

section .text

; Función: imprimir_texto
; Entrada: rdi = puntero al texto, rsi = longitud
; Salida: rax = bytes escritos
imprimir_texto:
    push    rbp
    mov     rbp, rsp

    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    ; rsi ya tiene el buffer
    ; rdx ya tiene la longitud
    syscall

    pop     rbp
    ret
```

---

## Success Criteria

### Performance Targets

| Metric | Target | Comparison |
|--------|--------|------------|
| Compile speed | < 100ms for 10K lines | Faster than Rust |
| Binary size | < 2KB for Hello World | Smaller than Go |
| Runtime speed | Within 5% of C | Competitive |
| Memory usage | No overhead vs C | No GC cost |

### Safety Targets

| Property | Target |
|----------|--------|
| Memory bugs | 0 possible in safe code |
| Null dereferences | 0 possible |
| Buffer overflows | 0 possible |
| Data races | 0 possible |
| Resource leaks | 0 possible (linear types) |
| Logic errors | Significant reduction (refinement types) |

### Usability Targets

| Metric | Target |
|--------|--------|
| Time to Hello World | < 5 minutes |
| Learning curve | Easier than Rust |
| Error message quality | Best in class |
| Documentation | Complete for all features |

---

## How to Contribute

1. **Specification work** — Help refine language design
2. **Assembly runtime** — Build platform-specific runtimes
3. **Stage 0 compiler** — Write assembly compiler components
4. **Stage 1 compiler** — Write compiler in Medellin.Col
5. **Standard library** — Implement stdlib modules
6. **Tooling** — Build package manager, formatter, etc.
7. **Documentation** — Write tutorials and references
8. **Testing** — Create test cases

See individual component READMEs for specific contribution guidelines.

---

*"Paso a paso se llega lejos."*
