# Medellin.Col - Lenguaje Ensamblador Universal

**El lenguaje ensamblador en español colombiano que escribe a todas las máquinas.**

---

## Filosofía

Medellin.Col es un lenguaje ensamblador diseñado con sintaxis en español colombiano, honrando a los grandes líderes, empresarios, y héroes de Colombia. Compila a Windows, macOS, Linux, y FreeBSD.

> *"Colombia es pasión."*

---

## Plataformas Objetivo

| Plataforma | Arquitecturas Soportadas |
|------------|-------------------------|
| Windows    | x86, x64, ARM64         |
| macOS      | x64, ARM64 (Apple Silicon) |
| Linux      | x86, x64, ARM, ARM64, RISC-V |
| FreeBSD    | x86, x64, ARM64         |

---

## Registros (Los Próceres)

### Registros de Propósito General (64-bit)

| Registro | Nombre Completo | Honra a | Propósito |
|----------|-----------------|---------|-----------|
| `URIBE` | Álvaro Uribe Vélez | Presidente 58º de Colombia | Acumulador principal |
| `DUQUE` | Iván Duque Márquez | Presidente 60º de Colombia | Base de datos |
| `PASTRANA` | Andrés Pastrana | Presidente 57º de Colombia | Contador/índice |
| `LAUREANO` | Laureano Gómez | Presidente 42º de Colombia | Puntero de pila |
| `OSPINA` | Mariano Ospina Pérez | Presidente 40º de Colombia | Puntero base |
| `TURBAY` | Julio César Turbay | Presidente 50º de Colombia | Fuente de datos |
| `SARMIENTO` | Luis Carlos Sarmiento | Empresario, hombre más rico de Colombia | Destino de datos |
| `GILINSKI` | Jaime Gilinski | Empresario y banquero | Propósito general |
| `SANTODOMINGO` | Julio Mario Santo Domingo | Empresario y magnate | Propósito general |
| `ARDILA` | Carlos Ardila Lülle | Empresario RCN/Postobón | Propósito general |
| `CALLE` | Arturo Calle | Empresario de moda | Propósito general |
| `BOLIVAR` | Simón Bolívar | El Libertador | Propósito general |
| `SANTANDER` | Francisco de Paula Santander | El Hombre de las Leyes | Registro de banderas |
| `NARIÑO` | Antonio Nariño | Precursor de la Independencia | Puntero de instrucción |
| `POLICARPA` | Policarpa Salavarrieta | Heroína de la Independencia | Registro de segmento |
| `LLERAS` | Alberto Lleras Camargo | Presidente y estadista | Registro de control |

### Registros de 32-bit (Sufijo -32)
```
URIBE32, DUQUE32, PASTRANA32, LAUREANO32, OSPINA32...
```

### Registros de 16-bit (Sufijo -16)
```
URIBE16, DUQUE16, PASTRANA16, LAUREANO16, OSPINA16...
```

### Registros de 8-bit (Sufijo -8)
```
URIBE8, DUQUE8, PASTRANA8, LAUREANO8, OSPINA8...
```

---

## Conjunto de Instrucciones (En Español Colombiano)

### Transferencia de Datos

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `MOVER` | dest, src | Mover datos | `MOVER URIBE, 42` |
| `CARGAR` | dest, [mem] | Cargar desde memoria | `CARGAR PASTRANA, [0x1000]` |
| `GUARDAR` | [mem], src | Guardar en memoria | `GUARDAR [0x1000], URIBE` |
| `INTERCAMBIAR` | op1, op2 | Intercambiar valores | `INTERCAMBIAR URIBE, DUQUE` |
| `EMPUJAR` | src | Empujar a la pila | `EMPUJAR URIBE` |
| `SACAR` | dest | Sacar de la pila | `SACAR DUQUE` |
| `LIMPIAR` | dest | Poner en cero | `LIMPIAR URIBE` |

### Aritmética

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `SUMAR` | dest, src | Suma | `SUMAR URIBE, 10` |
| `RESTAR` | dest, src | Resta | `RESTAR URIBE, 5` |
| `MULTIPLICAR` | dest, src | Multiplicación | `MULTIPLICAR URIBE, PASTRANA` |
| `DIVIDIR` | dest, src | División | `DIVIDIR URIBE, 2` |
| `MODULO` | dest, src | Resto de división | `MODULO URIBE, 3` |
| `INCREMENTAR` | dest | Incrementar en 1 | `INCREMENTAR PASTRANA` |
| `DECREMENTAR` | dest | Decrementar en 1 | `DECREMENTAR PASTRANA` |
| `NEGAR` | dest | Negación aritmética | `NEGAR URIBE` |

### Operaciones Lógicas

| Instrucción | Operandos | Descripción | Ejemplo |
|-------------|-----------|-------------|---------|
| `Y` | dest, src | AND lógico | `Y URIBE, 0xFF` |
| `O` | dest, src | OR lógico | `O URIBE, 0x0F` |
| `OX` | dest, src | XOR lógico | `OX URIBE, DUQUE` |
| `NO` | dest | NOT lógico | `NO URIBE` |
| `DESPLAZAR_IZQ` | dest, n | Shift izquierda | `DESPLAZAR_IZQ URIBE, 4` |
| `DESPLAZAR_DER` | dest, n | Shift derecha | `DESPLAZAR_DER URIBE, 2` |
| `ROTAR_IZQ` | dest, n | Rotar izquierda | `ROTAR_IZQ URIBE, 1` |
| `ROTAR_DER` | dest, n | Rotar derecha | `ROTAR_DER URIBE, 1` |

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
| `COMPARAR` | op1, op2 | Comparar valores | `COMPARAR URIBE, 100` |
| `LLAMAR` | etiqueta | Llamar subrutina | `LLAMAR calcular` |
| `RETORNAR` | - | Retornar de subrutina | `RETORNAR` |
| `BUCLE` | etiqueta | Decrementar PASTRANA y saltar si no cero | `BUCLE repetir` |

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
| `ENTRADA` | dest, puerto | Leer de puerto | `ENTRADA URIBE, 0x60` |
| `SALIDA` | puerto, src | Escribir a puerto | `SALIDA 0x60, URIBE` |
| `IMPRIMIR` | src | Imprimir valor | `IMPRIMIR URIBE` |
| `LEER` | dest | Leer entrada | `LEER URIBE` |

---

## Directivas (Los Mandatos)

| Directiva | Descripción | Ejemplo |
|-----------|-------------|---------|
| `.PATRIA` | Inicio de sección de código | `.PATRIA` |
| `.EMPRESA` | Inicio de sección de datos | `.EMPRESA` |
| `.HACIENDA` | Sección de datos no inicializados | `.HACIENDA` |
| `.CONSTANTE` | Definir constante | `.CONSTANTE VICTORIA 1` |
| `.DEFINIR` | Definir macro | `.DEFINIR EXITO 0` |
| `.BYTE` | Declarar byte | `.BYTE 0xFF` |
| `.PALABRA` | Declarar palabra (16-bit) | `.PALABRA 0xFFFF` |
| `.DOBLE` | Declarar doble palabra (32-bit) | `.DOBLE 0xFFFFFFFF` |
| `.CUADRUPLE` | Declarar cuádruple (64-bit) | `.CUADRUPLE 0xFFFFFFFFFFFFFFFF` |
| `.CADENA` | Declarar cadena | `.CADENA "¡Viva Colombia!"` |
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
; Argumentos: GILINSKI, SANTODOMINGO, ARDILA, CALLE (primeros 4)
; Retorno: URIBE
; Preservar: DUQUE, PASTRANA, LAUREANO, OSPINA
```

#### System V (Linux/macOS/FreeBSD)
```asm
; Argumentos: GILINSKI, SANTODOMINGO, ARDILA, CALLE, TURBAY, SARMIENTO (primeros 6)
; Retorno: URIBE
; Preservar: DUQUE, OSPINA, y registros 12-15
```

---

## Símbolos Patrios (Símbolos Especiales)

| Símbolo | Significado | Uso |
|---------|-------------|-----|
| `@DORADO` | Puntero al heap | Memoria dinámica (El Dorado) |
| `@CONDOR` | Código de salida | Estado del programa |
| `@TRICOLOR` | Bandera de éxito | Operación exitosa |
| `@MACHETE` | Bandera de error | Error detectado |
| `@CONSTITUCION` | Tabla de vectores | Interrupciones |
| `@FRONTERA` | Límite de pila | Stack boundary |
| `@INDEPENDENCIA` | Entry point | Punto de entrada |

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
.local_paisa:        ; Etiqueta local
```

### Números
```asm
MOVER URIBE, 42            ; Decimal
MOVER URIBE, 0x2A          ; Hexadecimal
MOVER URIBE, 0b101010      ; Binario
MOVER URIBE, 0o52          ; Octal
```

### Direccionamiento
```asm
MOVER URIBE, 42                      ; Inmediato
MOVER URIBE, DUQUE                   ; Registro
MOVER URIBE, [0x1000]                ; Directo
MOVER URIBE, [DUQUE]                 ; Indirecto
MOVER URIBE, [DUQUE + 8]             ; Base + desplazamiento
MOVER URIBE, [DUQUE + PASTRANA*4]    ; Base + índice escalado
MOVER URIBE, [DUQUE + PASTRANA*4 + 16] ; Completo
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

.EMPRESA
    mensaje: .CADENA "¡Hola Mundo desde Medellín, Colombia!\n"
    longitud: .CUADRUPLE 40

.PATRIA
    .GLOBAL @INDEPENDENCIA

@INDEPENDENCIA:
    ; Preparar para escribir
    MOVER URIBE, 1               ; syscall write
    MOVER GILINSKI, 1            ; stdout
    CARGAR SANTODOMINGO, mensaje ; buffer
    CARGAR ARDILA, longitud      ; tamaño
    SISTEMA 1

    ; Salir con éxito
    MOVER URIBE, 60              ; syscall exit
    MOVER GILINSKI, EXITO        ; código 0
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

*"¡Por Colombia, por la patria!"*

**Medellin.Col v0.1.0** - Hecho con orgullo paisa 🇨🇴
