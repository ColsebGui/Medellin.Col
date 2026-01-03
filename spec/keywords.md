# Medellin.Col Keywords

Complete list of reserved keywords in Colombian Spanish.

## Declaration Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `parcero` | function | Function declaration |
| `cosa` | struct | Structure declaration |
| `tipo` | type | Type alias/sum type declaration |
| `rasgo` | trait | Trait/interface declaration |
| `constante` | const | Constant declaration |
| `traiga` | import | Module import |
| `paquete` | package | Package declaration |

## Type Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `numero` | int64 | 64-bit signed integer (default) |
| `numero8` | int8 | 8-bit signed integer |
| `numero16` | int16 | 16-bit signed integer |
| `numero32` | int32 | 32-bit signed integer |
| `numero64` | int64 | 64-bit signed integer |
| `natural` | uint64 | 64-bit unsigned integer (default) |
| `natural8` | uint8 | 8-bit unsigned integer |
| `natural16` | uint16 | 16-bit unsigned integer |
| `natural32` | uint32 | 32-bit unsigned integer |
| `natural64` | uint64 | 64-bit unsigned integer |
| `decimal` | float64 | 64-bit floating point (default) |
| `decimal32` | float32 | 32-bit floating point |
| `decimal64` | float64 | 64-bit floating point |
| `texto` | string | UTF-8 string |
| `booleano` | bool | Boolean |
| `byte` | byte | 8-bit unsigned |
| `nada` | void | No value |
| `quizas` | Option | Optional type |
| `lista` | Vec | Dynamic array |
| `arreglo` | array | Fixed-size array |
| `mapa` | HashMap | Hash map |
| `conjunto` | HashSet | Hash set |
| `lineal` | linear | Linear type modifier |

## Control Flow Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `si` | if | Conditional |
| `entonces` | then | Conditional block start |
| `si no` | else | Else branch |
| `listo` | end | Block terminator |
| `mientras` | while | While loop |
| `haga` | do | Loop/block body start |
| `desde` | for | For loop start |
| `siendo` | from | Loop initial value |
| `hasta` | to | Loop end value |
| `paso` | step | Loop increment |
| `para` | for | For-each start |
| `cada` | each | For-each iterator |
| `en` | in | For-each collection |
| `cuando` | match | Pattern matching |
| `sea` | is | Pattern match body |
| `fin` | end | Declaration end |

## Function Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `devuelve` | returns | Return type declaration |
| `devuélvase` | return | Return statement |
| `con` | with | Return value, effects |

## Ownership Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `es` | is/= | Assignment/declaration |
| `preste` | borrow | Borrow reference |
| `mut` | mutable | Mutable borrow |
| `tome` | take/move | Move ownership |
| `region` | region | Memory region |

## Operators (Word Form)

| Keyword | English Equivalent | Operator |
|---------|-------------------|----------|
| `sume` | add | += |
| `quite` | subtract | -= |
| `mas` | plus | + |
| `menos` | minus | - |
| `por` | times | * |
| `entre` | divided by | / |
| `modulo` | modulo | % |
| `y` | and | && |
| `o` | or | \|\| |
| `no` | not | ! |

## Comparison Keywords

| Keyword | English Equivalent | Operator |
|---------|-------------------|----------|
| `es igual a` | equals | == |
| `no es` | not equals | != |
| `es mayor que` | greater than | > |
| `es menor que` | less than | < |
| `es al menos` | at least | >= |
| `es máximo` | at most | <= |

## Boolean Literals

| Keyword | English Equivalent | Value |
|---------|-------------------|-------|
| `verdad` | true | true |
| `falso` | false | false |

## Error Handling Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `error` | error | Error type |
| `falle` | fail | Throw error |
| `intente` | try | Try block/expression |
| `falla` | fails | Catch clause |
| `siempre` | always | Finally clause |
| `bien` | ok | Success pattern |
| `mal` | err | Error pattern |

## Effect & Capability Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `efecto` | effect | Effect annotation |
| `efectos` | effects | Effect list |
| `sin` | without | No effects |
| `requiere` | requires | Capability requirement |
| `capacidades` | capabilities | Capability list |

## Built-in Capabilities

| Keyword | English Equivalent | Access |
|---------|-------------------|--------|
| `Archivos` | Files | File system |
| `Red` | Network | Network access |
| `Sistema` | System | System calls |
| `Tiempo` | Time | System time |
| `Aleatorio` | Random | Random numbers |

## I/O Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `diga` | print | Print to stdout |
| `pregunte` | ask | Read input |
| `guarde` | save | Store result |

## Assertion Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `asuma` | assume | Verified assertion |
| `afirme` | assert | Test assertion |
| `donde` | where | Refinement predicate |
| `tiene` | has | Option check |
| `valor` | value | Option unwrap |

## Concurrency Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `tarea` | task | Task declaration |
| `paralelo` | parallel | Parallel block |
| `canal` | channel | Channel type |
| `envie` | send | Send to channel |
| `reciba` | receive | Receive from channel |
| `nuevo` | new | Create new |

## Annotation Keywords

| Keyword | English Equivalent | Usage |
|---------|-------------------|-------|
| `@total` | @total | Termination checked |
| `@publico` | @public | Public visibility |
| `@privado` | @private | Private visibility |
| `@intrinseco` | @intrinsic | Compiler intrinsic |
| `@vectorizar` | @vectorize | SIMD hint |

## Special Identifiers

| Identifier | Usage |
|------------|-------|
| `principal` | Program entry point |
| `self` | Self reference in methods |
| `_` | Wildcard pattern |

## Operator Precedence (Highest to Lowest)

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `()` `[]` `.` | Left |
| 2 | `no` `-` (unary) | Right |
| 3 | `por` `entre` `modulo` `*` `/` `%` | Left |
| 4 | `mas` `menos` `+` `-` | Left |
| 5 | `es igual a` `no es` `es mayor que` etc. | Left |
| 6 | `y` `&&` | Left |
| 7 | `o` `||` | Left |
| 8 | `es` (assignment) | Right |

## Reserved for Future

These keywords are reserved but not yet implemented:

| Keyword | Planned Usage |
|---------|---------------|
| `clase` | Class (if OOP added) |
| `hereda` | Inheritance |
| `implementa` | Implements trait |
| `asincrono` | Async function |
| `espere` | Await |
| `suspenda` | Yield |
| `genere` | Generator |

## Token Types for Lexer

```
TOKEN_KEYWORD       ; Reserved keyword
TOKEN_IDENT         ; Identifier
TOKEN_NUMERO        ; Integer literal
TOKEN_DECIMAL       ; Float literal
TOKEN_TEXTO         ; String literal
TOKEN_BOOLEANO      ; Boolean literal
TOKEN_OP_ARIT       ; Arithmetic operator
TOKEN_OP_COMP       ; Comparison operator
TOKEN_OP_LOGIC      ; Logical operator
TOKEN_PAREN_IZQ     ; (
TOKEN_PAREN_DER     ; )
TOKEN_CORCHETE_IZQ  ; [
TOKEN_CORCHETE_DER  ; ]
TOKEN_DOS_PUNTOS    ; :
TOKEN_COMA          ; ,
TOKEN_PUNTO         ; .
TOKEN_NEWLINE       ; Line break
TOKEN_COMENTARIO    ; Comment
TOKEN_EOF           ; End of file
```
