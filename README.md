# Medellin.Col

**El lenguaje de programación de sistemas para los emprendedores colombianos.**

A systems programming language with Colombian Spanish syntax, bootstrapped from pure assembly, delivering memory safety, logic safety, and native performance without garbage collection or unsafe escape hatches.

---

## Vision

Medellin.Col aims to be what Rust should have been: **memory-safe, logic-safe, and simple**.

We take the safety guarantees of Rust, the simplicity of Go, and add compile-time logic error detection — all with zero runtime overhead, no garbage collector, and no `unsafe` escape hatch.

Built from pure assembly. No C dependencies. No foreign runtime. Everything is ours.

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  "El que nada debe, nada teme"                                   ║
║                                                                  ║
║  Seguridad • Propiedad • Progreso                                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Why Medellin.Col?

| Problem | Our Solution |
|---------|--------------|
| Rust is too complex | Simpler ownership via regions, no lifetime annotations |
| Go has garbage collection | Ownership-based memory, deterministic destruction |
| C/C++ are unsafe | Memory safety guaranteed, no undefined behavior |
| All have `unsafe` escape hatches | No unsafe. Period. Total safety. |
| Logic errors slip through | Refinement types catch bugs at compile time |
| Supply chain attacks | Capability-based security restricts dependencies |

---

## Language Features

### Pure Colombian Spanish Syntax

```
traiga medellin/archivos

cosa Cliente
    texto nombre
    numero edad
    numero saldo
fin cosa

parcero crear_cliente(nombre: texto, edad: numero) devuelve Cliente
    devuélvase con Cliente
        nombre: nombre
        edad: edad
        saldo: 0
    fin
fin parcero

parcero principal()
    Cliente juan es crear_cliente("Juan", 30)

    si juan.edad >= 18 entonces
        diga "Cliente mayor de edad: " + juan.nombre
    listo
fin parcero
```

### Memory Safety Without Garbage Collection

Region-based memory management. No lifetime annotations. No GC pauses.

```
region datos haga
    lista de numero valores es [1, 2, 3, 4, 5]
    texto mensaje es "procesando..."

    procesar(valores)

fin region    ; Everything freed here, deterministically
```

### No Null - Ever

```
; Always has a value
texto nombre es "Juan"

; Might have a value - explicit
quizas texto apellido es buscar_apellido("Juan")

; Must check before use
si apellido tiene valor entonces
    diga apellido.valor
si no
    diga "No encontrado"
listo
```

### Errors Cannot Be Ignored

```
parcero dividir(a: numero, b: numero) devuelve numero o error
    si b es 0 entonces
        falle "División por cero"
    listo
    devuélvase con a entre b
fin parcero

; Must handle
cuando dividir(10, 0) sea
    bien(v): diga "Resultado: " + v
    mal(e): diga "Error: " + e
listo
```

### Refinement Types (Logic Safety)

Catch logic errors at compile time, not runtime.

```
tipo NumeroPositivo es numero donde valor > 0
tipo Porcentaje es numero donde valor >= 0 y valor <= 100

parcero aplicar_descuento(precio: NumeroPositivo, desc: Porcentaje) devuelve numero
    devuélvase con precio - (precio por desc entre 100)
fin parcero

aplicar_descuento(-50, 10)     ; COMPILE ERROR: -50 is not positive
aplicar_descuento(100, 150)    ; COMPILE ERROR: 150 is not valid percentage
aplicar_descuento(100, 10)     ; OK: returns 90
```

### Effect System

Track side effects in types. Know what functions can do.

```
parcero pura(x: numero) devuelve numero
    ; No effects - pure computation
    devuélvase con x por 2
fin parcero

parcero lee_config() devuelve texto con efecto IO
    ; Compiler knows this does I/O
    devuélvase con leer_archivo("config.txt")
fin parcero
```

### Capability-Based Security

Functions declare what they can access. Dependencies are restricted.

```
parcero procesar(datos: texto) requiere [Archivos, Red]
    ; Can access files and network
fin parcero

parcero calcular(x: numero) requiere []
    ; Pure - cannot access anything external
fin parcero

; Restrict third-party dependencies
traiga libreria_externa con capacidades []
; Now libreria_externa cannot access files, network, etc.
```

### Linear Types for Resources

Resources must be properly handled. No leaks.

```
tipo Archivo es lineal

parcero procesar_archivo(ruta: texto)
    Archivo f es abrir(ruta)
    texto contenido es leer(f)
    procesar(contenido)
    cerrar(f)    ; Must close - linear type enforces this
fin parcero
```

---

## Safety Guarantees

| Property | Guaranteed | Mechanism |
|----------|------------|-----------|
| No use-after-free | ✅ | Region-based ownership |
| No buffer overflow | ✅ | Bounds checking always |
| No null pointers | ✅ | `quizas` type, no null |
| No data races | ✅ | Ownership prevents sharing |
| No unhandled errors | ✅ | Result types, must handle |
| No resource leaks | ✅ | Linear types |
| No undefined behavior | ✅ | Everything defined |
| No unauthorized access | ✅ | Capability security |
| No logic errors (partial) | ✅ | Refinement types |

**No `unsafe` escape hatch.** The guarantees hold for ALL code.

---

## Research Innovations

Medellin.Col introduces novel combinations of programming language theory:

### Region-Based Memory (Simpler than Rust)

No lifetime annotations. 80% automatic inference, 20% guided.

```
; AUTOMATIC - compiler infers region from scope
parcero procesar()
    texto local es "temporal"
    ; Compiler: allocate in function region, free on return
fin parcero

; GUIDED - explicit for complex cases
region persistente haga
    Lista de Cliente clientes es cargar_clientes()
fin region
```

**Algorithm:** Scope-based allocation + escape analysis. If value escapes, promote to outer region.

### Verified Assertions (No Traditional Unsafe)

Instead of disabling safety, assert facts with runtime verification:

```
; NOT Rust-style unsafe blocks
; Instead: assertions that insert runtime checks

numero i es calculo_complejo()
asuma i >= 0 y i < 100    ; Developer asserts
arreglo[i]                 ; Compiler inserts runtime check

; Compiler message:
; NOTA: Se insertó verificación en tiempo de ejecución.
```

**Philosophy:** You can bypass static proof, but not safety checking.

### Tiered SMT Verification

Refinement type checking with predictable performance:

| Tier | Time | Example | Action |
|------|------|---------|--------|
| Trivial | < 1ms | `5 > 0` | Pattern match, no SMT |
| Simple | < 100ms | `x + y < 100` | SMT with timeout |
| Complex | < 5s | Quantified properties | Background verify, cache |
| Unprovable | - | SMT timeout | `asuma` + runtime check |

### Hierarchical Capabilities

Coarse-grained by default, refinable when needed:

```
; Level 1: Coarse (common)
parcero procesar() requiere [Archivos, Red]

; Level 2: Subcategory
parcero solo_lectura() requiere [Archivos.leer]

; Level 3: Specific (high security)
parcero restringido() requiere [Archivos.leer("/config/")]
```

### Affine Default, Linear Opt-in

Most values are affine (can drop). Resources opt-in to linear (must use):

```
; AFFINE (default) - can drop
numero x es 5    ; OK to ignore

; LINEAR (opt-in) - must use
tipo Archivo es lineal
Archivo f es abrir("x.txt")
; Must call cerrar(f) or descartar(f)
```

### Inferred Effects

Effects are inferred automatically, optionally annotated:

```
; INFERRED - compiler detects IO
parcero ejemplo()
    diga "hola"    ; Compiler: this has IO effect
fin parcero

; ENFORCED - explicit purity requirement
parcero pura(x: numero) devuelve numero sin efectos
    ; diga "debug" ← ERROR: no effects allowed
    devuélvase con x por 2
fin parcero
```

---

## Comparison

| Feature | C | Go | Rust | Medellin.Col |
|---------|---|----|----- |--------------|
| Memory safe | ❌ | ⚠️ GC | ✅ | ✅ |
| No GC | ✅ | ❌ | ✅ | ✅ |
| No null | ❌ | ❌ | ✅ | ✅ |
| No data races | ❌ | ⚠️ | ✅ | ✅ |
| No undefined behavior | ❌ | ✅ | ⚠️ | ✅ |
| No unsafe escape | N/A | ⚠️ | ❌ | ✅ |
| Simple to learn | ⚠️ | ✅ | ❌ | ✅ |
| Fast compile | ✅ | ✅ | ❌ | ✅ |
| Logic error detection | ❌ | ❌ | ❌ | ✅ |
| Capability security | ❌ | ❌ | ❌ | ✅ |

---

## Technical Foundation

### Pure Assembly Bootstrap

Medellin.Col is bootstrapped from pure x86-64 assembly. No C compiler, no libc, no external dependencies.

```
Stage 0: Hand-written assembler (x86-64 ASM)
    ↓
Stage 1: Minimal compiler (written in Medellin.Col, compiled by Stage 0)
    ↓
Stage 2: Full compiler (self-hosting)
    ↓
Independence: Assembly no longer needed
```

### Native Code Generation

True native binaries for all major platforms:

| Platform | Format | Status |
|----------|--------|--------|
| Linux x86-64 | ELF | Primary target |
| FreeBSD x86-64 | ELF | Supported |
| Windows x86-64 | PE | Supported |
| macOS x86-64 | Mach-O | Supported |
| Linux ARM64 | ELF | Planned |
| macOS ARM64 | Mach-O | Planned |

### Zero Dependencies

The compiled binary depends on nothing but the kernel:

- No libc
- No dynamic linker
- No runtime library
- Direct syscalls only

---

## Toolchain

| Tool | Command | Purpose |
|------|---------|---------|
| Compiler | `medellin` | Compile source to native binary |
| Package Manager | `gremio` | Manage dependencies |
| Formatter | `disciplina` | Format source code |
| Linter | `fiscal` | Static analysis |
| Test Runner | `auditor` | Run tests |
| REPL | `tertulia` | Interactive exploration |

```bash
medellin compilar programa.col
medellin compilar programa.col --objetivo windows
medellin compilar programa.col --objetivo linux
medellin compilar programa.col --objetivo mac

gremio instalar paquete
gremio publicar

disciplina formatear src/
fiscal revisar src/
auditor correr
```

---

## Project Structure

```
mi_proyecto/
├── Gremio.toml          # Project manifest
├── gremio.lock          # Locked dependency versions
├── src/
│   ├── principal.col    # Entry point
│   └── lib/
│       ├── modulo.col
│       └── otro.col
├── pruebas/             # Tests
│   └── test_modulo.col
└── ejemplos/            # Examples
    └── demo.col
```

---

## Thesis

> **"A systems programming language can be memory-safe, logic-safe, and simple simultaneously by combining region-based memory management with refinement types and capability security, eliminating the need for unsafe escape hatches through a pure assembly foundation."**

This is Medellin.Col's research contribution. We prove that:

1. **Simpler than Rust** — Region-based memory without lifetime annotations
2. **Safer than Rust** — No `unsafe` blocks, verified assertions only
3. **Smarter than all** — Refinement types catch logic errors
4. **Secure by design** — Capability-based access control

---

## Philosophy

### The Manifesto

1. **La propiedad es sagrada** — Every resource has an owner. Clear ownership enables safety.

2. **La seguridad no se negocia** — No unsafe escape hatches. The guarantees are absolute.

3. **El orden genera progreso** — Discipline in structure. Clarity in syntax. Results in execution.

4. **El trabajo duro se premia** — Native performance. No runtime tax. Your code, your machine, your speed.

5. **Emprendimiento sobre dependencia** — Minimal dependencies. Self-sufficiency. Bootstrap from nothing.

6. **Lo nuestro primero** — Made in Medellín. Colombian Spanish syntax. For the world, but ours first.

---

## Getting Started

*Language is in active development. See [ROADMAP.md](ROADMAP.md) for progress.*

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for detailed development phases and milestones.

---

## Contributing

We welcome contributions from developers who share our vision for a safer, simpler systems programming language.

---

## License

Apache License 2.0 - See [LICENSE](LICENSE)

---

*"De cero a imperio — así se construye."*
