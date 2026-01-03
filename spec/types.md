# Medellin.Col Type System

Complete specification of the type system.

## Overview

Medellin.Col uses a static, strongly-typed type system with:

- Nominal typing (types are distinct by name)
- Parametric polymorphism (generics)
- Region-based memory management
- Affine types by default, linear types opt-in
- Refinement types for logic safety
- Effect tracking

## Primitive Types

### Integers

| Type | Size | Range | Description |
|------|------|-------|-------------|
| `numero` | 64-bit | -2^63 to 2^63-1 | Default signed integer |
| `numero8` | 8-bit | -128 to 127 | Signed byte |
| `numero16` | 16-bit | -32768 to 32767 | Short integer |
| `numero32` | 32-bit | -2^31 to 2^31-1 | Standard integer |
| `numero64` | 64-bit | -2^63 to 2^63-1 | Long integer |
| `natural` | 64-bit | 0 to 2^64-1 | Default unsigned integer |
| `natural8` | 8-bit | 0 to 255 | Unsigned byte |
| `natural16` | 16-bit | 0 to 65535 | Unsigned short |
| `natural32` | 32-bit | 0 to 2^32-1 | Unsigned standard |
| `natural64` | 64-bit | 0 to 2^64-1 | Unsigned long |

**Overflow behavior:** Defined as wrapping (two's complement). No undefined behavior.

### Floating Point

| Type | Size | Description |
|------|------|-------------|
| `decimal` | 64-bit | IEEE 754 double precision (default) |
| `decimal32` | 32-bit | IEEE 754 single precision |
| `decimal64` | 64-bit | IEEE 754 double precision |

### Boolean

| Type | Size | Values |
|------|------|--------|
| `booleano` | 8-bit | `verdad` (true), `falso` (false) |

### Text

| Type | Layout | Description |
|------|--------|-------------|
| `texto` | ptr + len | UTF-8 encoded string |

**String layout (16 bytes):**
```
┌────────────────┬────────────────┐
│  ptr (8 bytes) │  len (8 bytes) │
└────────────────┴────────────────┘
```

### Byte

| Type | Size | Description |
|------|------|-------------|
| `byte` | 8-bit | Raw byte (alias for natural8) |

### Unit

| Type | Size | Description |
|------|------|-------------|
| `nada` | 0-bit | No value (void equivalent) |

## Composite Types

### Arrays (Fixed Size)

```
arreglo[N] de T
```

- Fixed size known at compile time
- Stack allocated when size is known
- Bounds checked at compile time when possible
- Runtime bounds check otherwise

**Example:**
```
arreglo[10] de numero datos
datos[0] es 42
```

**Memory layout:**
```
┌────────┬────────┬────────┬─────┐
│  T[0]  │  T[1]  │  T[2]  │ ... │
└────────┴────────┴────────┴─────┘
```

### Lists (Dynamic)

```
lista de T
```

- Dynamic size
- Heap allocated
- Automatically grows
- Bounds checked

**Memory layout (24 bytes header):**
```
┌────────────────┬────────────────┬────────────────┐
│  ptr (8 bytes) │  len (8 bytes) │  cap (8 bytes) │
└────────────────┴────────────────┴────────────────┘
```

### Structs (Cosa)

```
cosa Nombre
    campo1: Tipo1
    campo2: Tipo2
fin cosa
```

**Example:**
```
cosa Persona
    texto nombre
    numero edad
    booleano activo
fin cosa
```

**Memory layout:** Fields laid out in declaration order with alignment padding.

### Enums (Sum Types)

```
tipo Nombre es
    Variante1
    Variante2(campo: Tipo)
    Variante3(a: Tipo1, b: Tipo2)
fin tipo
```

**Example:**
```
tipo Resultado[T, E] es
    Exito(valor: T)
    Falla(error: E)
fin tipo
```

**Memory layout:** Tag byte + largest variant payload.

### Tuples

```
(T1, T2, T3)
```

**Example:**
```
(numero, texto, booleano) triple es (42, "hola", verdad)
```

### Maps

```
mapa de K a V
```

- Hash map implementation
- Keys must implement `Hasheable` and `Igual`

### Sets

```
conjunto de T
```

- Hash set implementation
- Elements must implement `Hasheable` and `Igual`

## Optional Types

### Quizas (Option)

```
quizas T
```

**Variants:**
- `algo(valor: T)` - Has a value
- `nada` - No value

**Usage:**
```
quizas numero resultado es buscar(clave)

si resultado tiene valor entonces
    diga resultado.valor
listo
```

### Result (Error Handling)

```
T o error
```

**Variants:**
- `bien(valor: T)` - Success
- `mal(error: Error)` - Failure

**Usage:**
```
parcero dividir(a: numero, b: numero) devuelve numero o error
    si b es 0 entonces
        falle "División por cero"
    listo
    devuélvase con a entre b
fin parcero
```

## Ownership Types

### Owned (Default)

```
T
```

Value is owned. When scope ends, value is dropped.

### Borrowed (Immutable)

```
preste T
```

Immutable reference. Cannot outlive owner.

### Borrowed (Mutable)

```
preste mut T
```

Mutable reference. Exclusive access.

### Moved

```
tome T
```

Ownership transferred to callee.

## Refinement Types

Types with logical predicates:

```
tipo NumeroPositivo es numero donde valor > 0
tipo IndiceValido[N] es numero donde valor >= 0 y valor < N
tipo Porcentaje es numero donde valor >= 0 y valor <= 100
```

**Predicate language:**
- Arithmetic: `+`, `-`, `*`, `/`, `%`
- Comparison: `>`, `<`, `>=`, `<=`, `==`, `!=`
- Logical: `y` (and), `o` (or), `no` (not)
- Variables: `valor` (the value being refined)

**Verification:**
- Tier 1: Constant expressions - pattern matching
- Tier 2: Linear arithmetic - SMT solver
- Tier 3: Complex - background verification
- Tier 4: Unprovable - `asuma` + runtime check

## Linear Types

Types that must be used exactly once:

```
tipo Archivo es lineal cosa
    descriptor: numero
fin cosa
```

**Rules:**
1. Must be consumed (used in consuming function)
2. Cannot be dropped implicitly
3. Must use `descartar()` for explicit disposal
4. All branches must consume

## Generic Types

### Type Parameters

```
cosa Lista[T]
    datos: arreglo de T
    tamaño: numero
fin cosa

parcero primero[T](lista: preste Lista[T]) devuelve quizas T
```

### Constraints

```
parcero ordenar[T: Ordenable](lista: preste mut Lista[T])
```

### Multiple Constraints

```
parcero buscar[T: Hasheable + Igual](mapa: preste Mapa[T, V], clave: T)
```

## Built-in Traits

### Igual (Equality)

```
rasgo Igual
    parcero es_igual(self: preste Self, otro: preste Self) devuelve booleano
fin rasgo
```

### Ordenable (Ordering)

```
rasgo Ordenable
    parcero comparar(self: preste Self, otro: preste Self) devuelve Orden
fin rasgo

tipo Orden es
    Menor
    Igual
    Mayor
fin tipo
```

### Hasheable

```
rasgo Hasheable
    parcero hash(self: preste Self) devuelve natural64
fin rasgo
```

### Mostrable (Display)

```
rasgo Mostrable
    parcero mostrar(self: preste Self) devuelve texto
fin rasgo
```

### Clonable

```
rasgo Clonable
    parcero clonar(self: preste Self) devuelve Self
fin rasgo
```

## Type Inference

### Local Inference

Variable types can be inferred:

```
numero x es 5           ; Explicit
y es 10                 ; Inferred as numero (from literal)
z es x mas y            ; Inferred as numero (from expression)
```

### Function Inference

- Parameter types must be explicit
- Return types can be inferred (but recommended explicit)
- Generic parameters inferred from arguments when possible

## Type Coercion

Medellin.Col has **no implicit coercion**. All conversions must be explicit:

```
numero32 x es 100
numero64 y es como numero64(x)    ; Explicit widening

numero64 a es 1000
numero32 b es como numero32(a)    ; Explicit narrowing (may truncate)
```

## Size and Alignment

| Type | Size | Alignment |
|------|------|-----------|
| `numero8`, `natural8`, `byte`, `booleano` | 1 | 1 |
| `numero16`, `natural16` | 2 | 2 |
| `numero32`, `natural32`, `decimal32` | 4 | 4 |
| `numero64`, `natural64`, `numero`, `natural`, `decimal`, `decimal64` | 8 | 8 |
| `texto` | 16 | 8 |
| `lista de T` | 24 | 8 |
| `quizas T` | 1 + size(T) | align(T) |
| Pointers | 8 | 8 |

## Type Compatibility

### Structural Equality

Two types are equal if they have the same name and type parameters.

### Subtyping

No subtyping (no inheritance). Use traits for polymorphism.

### Variance

- Immutable borrows: covariant
- Mutable borrows: invariant
- Owned values: invariant

## Error Types

```
cosa Error
    texto mensaje
    quizas texto archivo
    quizas numero linea
fin cosa
```

Custom error types can implement `Mostrable` for display.
