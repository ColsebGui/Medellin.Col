# Medellin.Col - Lenguaje Ensamblador Universal

**El lenguaje ensamblador en español colombiano que escribe a todas las máquinas.**

---

## Filosofía

Medellin.Col es un lenguaje ensamblador diseñado con sintaxis en español colombiano, honrando a los gigantes del libre mercado, la empresa, y el liderazgo conservador. Compila a Windows, macOS, Linux, y FreeBSD.

> *"El gobierno no es la solución a nuestro problema; el gobierno es el problema."* — Ronald Reagan

---

## Plataformas Objetivo

| Plataforma | Arquitecturas Soportadas |
|------------|-------------------------|
| Windows    | x86, x64, ARM64         |
| macOS      | x64, ARM64 (Apple Silicon) |
| Linux      | x86, x64, ARM, ARM64, RISC-V |
| FreeBSD    | x86, x64, ARM64         |

---

## Registros (Los Titanes)

### Registros de Propósito General (64-bit)

| Registro | Nombre Completo | Honra a | Propósito |
|----------|-----------------|---------|-----------|
| `REAGAN` | Ronald Reagan | 40º Presidente EEUU | Acumulador principal |
| `THATCHER` | Margaret Thatcher | Primera Ministra UK | Base de datos |
| `HAYEK` | Friedrich Hayek | Economista austríaco | Contador/índice |
| `MISES` | Ludwig von Mises | Economista austríaco | Puntero de pila |
| `FRIEDMAN` | Milton Friedman | Economista Chicago | Puntero base |
| `RAND` | Ayn Rand | Filósofa objetivista | Fuente de datos |
| `ROCKEFELLER` | John D. Rockefeller | Magnate del petróleo | Destino de datos |
| `CARNEGIE` | Andrew Carnegie | Magnate del acero | Propósito general |
| `FORD` | Henry Ford | Magnate automotriz | Propósito general |
| `MORGAN` | J.P. Morgan | Magnate financiero | Propósito general |
| `VANDERBILT` | Cornelius Vanderbilt | Magnate ferroviario | Propósito general |
| `BOLSONARO` | Jair Bolsonaro | 38º Presidente Brasil | Propósito general |
| `MILEI` | Javier Milei | Presidente Argentina | Registro de banderas |
| `BUKELE` | Nayib Bukele | Presidente El Salvador | Puntero de instrucción |
| `PINOCHET` | Augusto Pinochet | Líder chileno | Registro de segmento |
| `URIBE` | Álvaro Uribe | Presidente Colombia | Registro de control |

### Registros de 32-bit (Sufijo -32)
```
REAGAN32, THATCHER32, HAYEK32, MISES32, FRIEDMAN32...
```

### Registros de 16-bit (Sufijo -16)
```
REAGAN16, THATCHER16, HAYEK16, MISES16, FRIEDMAN16...
```

### Registros de 8-bit (Sufijo -8)
```
REAGAN8, THATCHER8, HAYEK8, MISES8, FRIEDMAN8...
```

---

## Conjunto de Instrucciones (En Español Colombiano)

### Transferencia de Datos

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `MOVER` | dest, src | Mover datos | `MOVER REAGAN, 42` |
| `CARGAR` | dest, [mem] | Cargar desde memoria | `CARGAR HAYEK, [0x1000]` |
| `GUARDAR` | [mem], src | Guardar en memoria | `GUARDAR [0x1000], REAGAN` |
| `INTERCAMBIAR` | op1, op2 | Intercambiar valores | `INTERCAMBIAR REAGAN, THATCHER` |
| `EMPUJAR` | src | Empujar a la pila | `EMPUJAR REAGAN` |
| `SACAR` | dest | Sacar de la pila | `SACAR THATCHER` |
| `LIMPIAR` | dest | Poner en cero | `LIMPIAR REAGAN` |

### Aritmética

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `SUMAR` | dest, src | Suma | `SUMAR REAGAN, 10` |
| `RESTAR` | dest, src | Resta | `RESTAR REAGAN, 5` |
| `MULTIPLICAR` | dest, src | Multiplicación | `MULTIPLICAR REAGAN, HAYEK` |
| `DIVIDIR` | dest, src | División | `DIVIDIR REAGAN, 2` |
| `MODULO` | dest, src | Resto de división | `MODULO REAGAN, 3` |
| `INCREMENTAR` | dest | Incrementar en 1 | `INCREMENTAR HAYEK` |
| `DECREMENTAR` | dest | Decrementar en 1 | `DECREMENTAR HAYEK` |
| `NEGAR` | dest | Negación aritmética | `NEGAR REAGAN` |

### Operaciones Lógicas

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `Y` | dest, src | AND lógico | `Y REAGAN, 0xFF` |
| `O` | dest, src | OR lógico | `O REAGAN, 0x0F` |
| `OX` | dest, src | XOR lógico | `OX REAGAN, THATCHER` |
| `NO` | dest | NOT lógico | `NO REAGAN` |
| `DESPLAZAR_IZQ` | dest, n | Shift izquierda | `DESPLAZAR_IZQ REAGAN, 4` |
| `DESPLAZAR_DER` | dest, n | Shift derecha | `DESPLAZAR_DER REAGAN, 2` |
| `ROTAR_IZQ` | dest, n | Rotar izquierda | `ROTAR_IZQ REAGAN, 1` |
| `ROTAR_DER` | dest, n | Rotar derecha | `ROTAR_DER REAGAN, 1` |

### Control de Flujo

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `SALTAR` | etiqueta | Salto incondicional | `SALTAR inicio` |
| `SALTAR_SI_IGUAL` | etiqueta | Saltar si igual | `SALTAR_SI_IGUAL fin` |
| `SALTAR_SI_DIFERENTE` | etiqueta | Saltar si diferente | `SALTAR_SI_DIFERENTE bucle` |
| `SALTAR_SI_MAYOR` | etiqueta | Saltar si mayor | `SALTAR_SI_MAYOR exito` |
| `SALTAR_SI_MENOR` | etiqueta | Saltar si menor | `SALTAR_SI_MENOR error` |
| `SALTAR_SI_MAYOR_IGUAL` | etiqueta | Saltar si >= | `SALTAR_SI_MAYOR_IGUAL ok` |
| `SALTAR_SI_MENOR_IGUAL` | etiqueta | Saltar si <= | `SALTAR_SI_MENOR_IGUAL retry` |
| `SALTAR_SI_CERO` | etiqueta | Saltar si cero | `SALTAR_SI_CERO vacio` |
| `SALTAR_SI_NO_CERO` | etiqueta | Saltar si no cero | `SALTAR_SI_NO_CERO continuar` |
| `COMPARAR` | op1, op2 | Comparar valores | `COMPARAR REAGAN, 100` |
| `LLAMAR` | etiqueta | Llamar subrutina | `LLAMAR calcular` |
| `RETORNAR` | - | Retornar de subrutina | `RETORNAR` |
| `BUCLE` | etiqueta | Decrementar HAYEK y saltar si no cero | `BUCLE repetir` |

### Sistema y Control

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `SISTEMA` | código | Llamada al sistema | `SISTEMA 1` |
| `INTERRUMPIR` | n | Interrupción software | `INTERRUMPIR 0x80` |
| `PARAR` | - | Detener ejecución | `PARAR` |
| `NADA` | - | No operación | `NADA` |
| `ESPERAR` | - | Esperar interrupción | `ESPERAR` |
| `DEPURAR` | - | Punto de depuración | `DEPURAR` |

### Entrada/Salida

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `ENTRADA` | dest, puerto | Leer de puerto | `ENTRADA REAGAN, 0x60` |
| `SALIDA` | puerto, src | Escribir a puerto | `SALIDA 0x60, REAGAN` |
| `IMPRIMIR` | src | Imprimir valor | `IMPRIMIR REAGAN` |
| `LEER` | dest | Leer entrada | `LEER REAGAN` |

---

## Directivas (Los Mandatos)

| Directiva | Descripción | Ejemplo |
|-----------|-------------|---------|
| `.LIBRE_MERCADO` | Inicio de sección de código | `.LIBRE_MERCADO` |
| `.CAPITALISMO` | Inicio de sección de datos | `.CAPITALISMO` |
| `.PROPIEDAD` | Sección de datos no inicializados | `.PROPIEDAD` |
| `.CONSTANTE` | Definir constante | `.CONSTANTE IMPUESTO 0` |
| `.DEFINIR` | Definir macro | `.DEFINIR EXITO 0` |
| `.BYTE` | Declarar byte | `.BYTE 0xFF` |
| `.PALABRA` | Declarar palabra (16-bit) | `.PALABRA 0xFFFF` |
| `.DOBLE` | Declarar doble palabra (32-bit) | `.DOBLE 0xFFFFFFFF` |
| `.CUADRUPLE` | Declarar cuádruple (64-bit) | `.CUADRUPLE 0xFFFFFFFFFFFFFFFF` |
| `.CADENA` | Declarar cadena | `.CADENA "¡Viva la libertad!"` |
| `.RESERVAR` | Reservar bytes | `.RESERVAR 1024` |
| `.ALINEAR` | Alinear a frontera | `.ALINEAR 16` |
| `.GLOBAL` | Símbolo global | `.GLOBAL principal` |
| `.EXTERNO` | Símbolo externo | `.EXTERNO malloc` |
| `.INCLUIR` | Incluir archivo | `.INCLUIR "biblioteca.col"` |

---

## Plataformas y Llamadas al Sistema

### Directivas de Plataforma

```asm
.PLATAFORMA WINDOWS    ; Compilar para Windows
.PLATAFORMA DARWIN     ; Compilar para macOS
.PLATAFORMA LINUX      ; Compilar para Linux
.PLATAFORMA FREEBSD    ; Compilar para FreeBSD
.PLATAFORMA TODAS      ; Compilar para todas (default)
```

### Convenciones de Llamada

#### Windows (x64)
```asm
; Argumentos: FORD, MORGAN, CARNEGIE, VANDERBILT (primeros 4)
; Retorno: REAGAN
; Preservar: THATCHER, HAYEK, MISES, FRIEDMAN
```

#### System V (Linux/macOS/FreeBSD)
```asm
; Argumentos: FORD, MORGAN, CARNEGIE, VANDERBILT, RAND, ROCKEFELLER (primeros 6)
; Retorno: REAGAN
; Preservar: THATCHER, FRIEDMAN, y registros 12-15
```

---

## Mitología del Libre Mercado (Símbolos Especiales)

| Símbolo | Significado | Uso |
|---------|-------------|-----|
| `@MANO_INVISIBLE` | Puntero al heap | Memoria dinámica |
| `@AGUILA` | Código de salida | Estado del programa |
| `@LIBERTAD` | Bandera de éxito | Operación exitosa |
| `@SERPIENTE` | Bandera de error | Error detectado |
| `@CONSTITUCION` | Tabla de vectores | Interrupciones |
| `@FRONTERA` | Límite de pila | Stack boundary |
| `@EMPRESA` | Entry point | Punto de entrada |

---

## Sintaxis Colombiana Especial

### Comentarios
```asm
; Esto es un comentario (estilo clásico)
// Esto también es comentario (estilo moderno)
/* Comentario
   de múltiples
   líneas */
```

### Etiquetas
```asm
principal:           ; Etiqueta simple
.economia_local:     ; Etiqueta local
```

### Números
```asm
MOVER REAGAN, 42           ; Decimal
MOVER REAGAN, 0x2A         ; Hexadecimal
MOVER REAGAN, 0b101010     ; Binario
MOVER REAGAN, 0o52         ; Octal
```

### Direccionamiento
```asm
MOVER REAGAN, 42                    ; Inmediato
MOVER REAGAN, THATCHER              ; Registro
MOVER REAGAN, [0x1000]              ; Directo
MOVER REAGAN, [THATCHER]            ; Indirecto
MOVER REAGAN, [THATCHER + 8]        ; Base + desplazamiento
MOVER REAGAN, [THATCHER + HAYEK*4]  ; Base + índice escalado
MOVER REAGAN, [THATCHER + HAYEK*4 + 16] ; Completo
```

---

## Estructura de un Programa

```asm
; ============================================
; Programa: Hola Mundo
; Autor: Programador Paisa
; Plataforma: TODAS
; ============================================

.PLATAFORMA TODAS
.CONSTANTE EXITO 0

.CAPITALISMO
    mensaje: .CADENA "¡Hola Mundo desde Medellín!\n"
    longitud: .CUADRUPLE 29

.LIBRE_MERCADO
    .GLOBAL @EMPRESA

@EMPRESA:
    ; Preparar para escribir
    MOVER REAGAN, 1              ; syscall write
    MOVER FORD, 1                ; stdout
    CARGAR MORGAN, mensaje       ; buffer
    CARGAR CARNEGIE, longitud    ; tamaño
    SISTEMA 1

    ; Salir con éxito
    MOVER REAGAN, 60             ; syscall exit
    MOVER FORD, EXITO            ; código 0
    SISTEMA 1

    PARAR
```

---

## Extensión de Archivos

| Extensión | Descripción |
|-----------|-------------|
| `.col` | Código fuente Medellin.Col |
| `.col.o` | Objeto compilado |
| `.col.lib` | Biblioteca estática |
| `.col.dll` | Biblioteca dinámica (Windows) |
| `.col.so` | Biblioteca compartida (Linux/FreeBSD) |
| `.col.dylib` | Biblioteca dinámica (macOS) |

---

## Próximos Pasos

1. Implementar ensamblador
2. Implementar enlazador
3. Crear biblioteca estándar
4. Herramientas de depuración

---

*"La libertad no es gratis, pero el mercado sí lo es."*

**Medellin.Col v0.1.0** - Hecho con orgullo paisa 🇨🇴
