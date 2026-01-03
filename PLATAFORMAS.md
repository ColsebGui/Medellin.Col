# Medellin.Col - Guía de Plataformas

## Visión General

Medellin.Col compila código ensamblador a binarios nativos para múltiples plataformas. Esta guía detalla las especificaciones de cada sistema operativo objetivo.

> *"El libre mercado no conoce fronteras."*

---

## Windows

### Arquitecturas Soportadas
- x86 (32-bit)
- x64 (64-bit)
- ARM64

### Formato de Ejecutable
- **Formato**: PE (Portable Executable)
- **Extensión**: `.exe`, `.dll`

### Convención de Llamada (x64)

```
Argumentos enteros/punteros:
  1º: FORD (RCX)
  2º: MORGAN (RDX)
  3º: CARNEGIE (R8)
  4º: VANDERBILT (R9)
  5º+: Pila

Argumentos flotantes:
  XMM0, XMM1, XMM2, XMM3

Valor de retorno:
  REAGAN (RAX)

Registros preservados (callee-saved):
  THATCHER (RBX), FRIEDMAN (RBP),
  MISES (RSP), RAND (RSI),
  ROCKEFELLER (RDI), R12-R15

Shadow Space: 32 bytes reservados en pila
Alineación de pila: 16 bytes
```

### Llamadas al Sistema Windows

Windows usa la API de Win32. Los syscalls directos no son estables.

```asm
; Patrón Windows: usar funciones de kernel32.dll

.EXTERNO GetStdHandle
.EXTERNO WriteConsoleA
.EXTERNO ExitProcess

@EMPRESA:
    ; Obtener stdout handle
    MOVER FORD, -11              ; STD_OUTPUT_HANDLE
    LLAMAR EXTERNO GetStdHandle
    MOVER THATCHER, REAGAN       ; Guardar handle

    ; Escribir mensaje
    MOVER FORD, THATCHER         ; hConsoleOutput
    CARGAR MORGAN, mensaje       ; lpBuffer
    MOVER CARNEGIE, longitud     ; nNumberOfChars
    CARGAR VANDERBILT, bytes_escritos  ; lpNumberOfCharsWritten
    LIMPIAR RAND                 ; lpReserved
    LLAMAR EXTERNO WriteConsoleA

    ; Salir
    LIMPIAR FORD
    LLAMAR EXTERNO ExitProcess
```

### Constantes Windows Comunes

```asm
.CONSTANTE STD_INPUT_HANDLE     -10
.CONSTANTE STD_OUTPUT_HANDLE    -11
.CONSTANTE STD_ERROR_HANDLE     -12

.CONSTANTE GENERIC_READ         0x80000000
.CONSTANTE GENERIC_WRITE        0x40000000
.CONSTANTE FILE_SHARE_READ      0x00000001
.CONSTANTE OPEN_EXISTING        3
.CONSTANTE CREATE_ALWAYS        2
```

---

## Linux

### Arquitecturas Soportadas
- x86 (32-bit)
- x64 (64-bit)
- ARM (32-bit)
- ARM64 (AArch64)
- RISC-V (RV64)

### Formato de Ejecutable
- **Formato**: ELF (Executable and Linkable Format)
- **Extensión**: ninguna (convención Unix)

### Convención de Llamada System V AMD64

```
Argumentos enteros/punteros:
  1º: FORD (RDI)
  2º: MORGAN (RSI)
  3º: CARNEGIE (RDX)
  4º: VANDERBILT (RCX)
  5º: RAND (R8)
  6º: ROCKEFELLER (R9)
  7º+: Pila

Argumentos flotantes:
  XMM0-XMM7

Valores de retorno:
  REAGAN (RAX), THATCHER (RDX)

Registros preservados (callee-saved):
  THATCHER (RBX), FRIEDMAN (RBP),
  R12-R15

Alineación de pila: 16 bytes (antes de LLAMAR)
```

### Llamadas al Sistema Linux (x64)

```asm
; Número de syscall en REAGAN
; Argumentos en FORD, MORGAN, CARNEGIE, VANDERBILT, RAND, ROCKEFELLER
; Retorno en REAGAN

; syscall se invoca con SISTEMA 0

; Ejemplo: write(1, "hola", 4)
MOVER REAGAN, 1              ; __NR_write
MOVER FORD, 1                ; fd = stdout
CARGAR MORGAN, mensaje       ; buf
MOVER CARNEGIE, 4            ; count
SISTEMA 0
```

### Números de Syscall Linux (x64)

```asm
.CONSTANTE SYS_READ           0
.CONSTANTE SYS_WRITE          1
.CONSTANTE SYS_OPEN           2
.CONSTANTE SYS_CLOSE          3
.CONSTANTE SYS_STAT           4
.CONSTANTE SYS_FSTAT          5
.CONSTANTE SYS_LSEEK          8
.CONSTANTE SYS_MMAP           9
.CONSTANTE SYS_MPROTECT       10
.CONSTANTE SYS_MUNMAP         11
.CONSTANTE SYS_BRK            12
.CONSTANTE SYS_IOCTL          16
.CONSTANTE SYS_PIPE           22
.CONSTANTE SYS_SELECT         23
.CONSTANTE SYS_DUP            32
.CONSTANTE SYS_DUP2           33
.CONSTANTE SYS_FORK           57
.CONSTANTE SYS_EXECVE         59
.CONSTANTE SYS_EXIT           60
.CONSTANTE SYS_WAIT4          61
.CONSTANTE SYS_KILL           62
.CONSTANTE SYS_GETPID         39
.CONSTANTE SYS_SOCKET         41
.CONSTANTE SYS_CONNECT        42
.CONSTANTE SYS_ACCEPT         43
.CONSTANTE SYS_BIND           49
.CONSTANTE SYS_LISTEN         50
```

---

## macOS (Darwin)

### Arquitecturas Soportadas
- x64 (Intel)
- ARM64 (Apple Silicon)

### Formato de Ejecutable
- **Formato**: Mach-O
- **Extensión**: ninguna (convención Unix)

### Convención de Llamada
Igual que System V AMD64 (misma que Linux x64).

### Llamadas al Sistema macOS

macOS usa un offset de `0x2000000` para syscalls Unix.

```asm
; Número de syscall = 0x2000000 + número_unix

.CONSTANTE SYS_DARWIN_EXIT    0x2000001
.CONSTANTE SYS_DARWIN_FORK    0x2000002
.CONSTANTE SYS_DARWIN_READ    0x2000003
.CONSTANTE SYS_DARWIN_WRITE   0x2000004
.CONSTANTE SYS_DARWIN_OPEN    0x2000005
.CONSTANTE SYS_DARWIN_CLOSE   0x2000006
.CONSTANTE SYS_DARWIN_MMAP    0x20000C5  ; 197

; Ejemplo: write
MOVER REAGAN, 0x2000004      ; sys_write
MOVER FORD, 1                ; stdout
CARGAR MORGAN, mensaje
MOVER CARNEGIE, longitud
SISTEMA 0
```

### Particularidades Apple Silicon (ARM64)

```asm
; En ARM64, los syscalls usan registros diferentes
; X0-X7: argumentos
; X16: número de syscall
; SVC #0x80: invocar syscall

.SI_ARQUITECTURA ARM64
    MOVER X16, 4             ; write
    MOVER X0, 1              ; stdout
    CARGAR X1, mensaje
    MOVER X2, longitud
    SISTEMA 0x80
.FIN_SI_ARQUITECTURA
```

---

## FreeBSD

### Arquitecturas Soportadas
- x86 (32-bit)
- x64 (64-bit)
- ARM64

### Formato de Ejecutable
- **Formato**: ELF
- **Extensión**: ninguna

### Convención de Llamada
Igual que System V AMD64.

### Llamadas al Sistema FreeBSD

```asm
; FreeBSD usa convención similar a Linux
; pero con números de syscall diferentes

.CONSTANTE SYS_BSD_EXIT       1
.CONSTANTE SYS_BSD_FORK       2
.CONSTANTE SYS_BSD_READ       3
.CONSTANTE SYS_BSD_WRITE      4
.CONSTANTE SYS_BSD_OPEN       5
.CONSTANTE SYS_BSD_CLOSE      6
.CONSTANTE SYS_BSD_MMAP       477

; Ejemplo: write
MOVER REAGAN, 4              ; SYS_write
MOVER FORD, 1                ; stdout
CARGAR MORGAN, mensaje
MOVER CARNEGIE, longitud
SISTEMA 0                    ; syscall
```

---

## Compilación Condicional

### Directivas de Plataforma

```asm
; Seleccionar plataforma objetivo
.PLATAFORMA WINDOWS          ; Solo Windows
.PLATAFORMA LINUX            ; Solo Linux
.PLATAFORMA DARWIN           ; Solo macOS
.PLATAFORMA FREEBSD          ; Solo FreeBSD
.PLATAFORMA TODAS            ; Todas (default)

; Código condicional por plataforma
.SI_PLATAFORMA LINUX
    ; Código específico para Linux
    MOVER REAGAN, 1          ; sys_write
    SISTEMA 0
.FIN_SI_PLATAFORMA

.SI_PLATAFORMA WINDOWS
    ; Código específico para Windows
    LLAMAR EXTERNO WriteConsoleA
.FIN_SI_PLATAFORMA
```

### Directivas de Arquitectura

```asm
.SI_ARQUITECTURA X64
    ; Código para 64-bit x86
.FIN_SI_ARQUITECTURA

.SI_ARQUITECTURA X86
    ; Código para 32-bit x86
.FIN_SI_ARQUITECTURA

.SI_ARQUITECTURA ARM64
    ; Código para ARM de 64-bit
.FIN_SI_ARQUITECTURA

.SI_ARQUITECTURA RISCV64
    ; Código para RISC-V 64-bit
.FIN_SI_ARQUITECTURA
```

---

## Mapeo de Registros por Arquitectura

### x64 (Windows/Linux/macOS/FreeBSD)

| Medellin.Col | x64 Real | Propósito |
|--------------|----------|-----------|
| REAGAN | RAX | Acumulador, retorno |
| THATCHER | RBX | Base, preservado |
| HAYEK | RCX | Contador |
| MISES | RSP | Puntero de pila |
| FRIEDMAN | RBP | Puntero base |
| RAND | RSI | Fuente |
| ROCKEFELLER | RDI | Destino |
| FORD | RDI/RCX* | 1º argumento |
| MORGAN | RSI/RDX* | 2º argumento |
| CARNEGIE | RDX/R8* | 3º argumento |
| VANDERBILT | RCX/R9* | 4º argumento |
| BOLSONARO | R10 | Propósito general |
| MILEI | R11 | Propósito general |
| BUKELE | RIP | Instruction pointer |
| URIBE | RFLAGS | Banderas |

*Windows usa RCX, RDX, R8, R9; Unix usa RDI, RSI, RDX, RCX

### ARM64

| Medellin.Col | ARM64 Real | Propósito |
|--------------|------------|-----------|
| REAGAN | X0 | Retorno, 1º arg |
| THATCHER | X1 | 2º argumento |
| HAYEK | X2 | 3º argumento |
| MISES | SP | Stack pointer |
| FRIEDMAN | X29/FP | Frame pointer |
| FORD-ROCKEFELLER | X0-X7 | Argumentos |
| BUKELE | PC | Program counter |

---

## Ejemplos Multi-Plataforma

### Plantilla Universal

```asm
; ============================================
; Programa multi-plataforma
; ============================================

.PLATAFORMA TODAS

.CAPITALISMO
    mensaje: .CADENA "¡Funciona en todas partes!\n"
    longitud: .CUADRUPLE 28

.LIBRE_MERCADO
    .GLOBAL @EMPRESA

@EMPRESA:
    LLAMAR escribir_mensaje
    LLAMAR salir

escribir_mensaje:
    .SI_PLATAFORMA LINUX
        MOVER REAGAN, 1
        MOVER FORD, 1
        CARGAR MORGAN, mensaje
        CARGAR CARNEGIE, [longitud]
        SISTEMA 0
    .FIN_SI_PLATAFORMA

    .SI_PLATAFORMA DARWIN
        MOVER REAGAN, 0x2000004
        MOVER FORD, 1
        CARGAR MORGAN, mensaje
        CARGAR CARNEGIE, [longitud]
        SISTEMA 0
    .FIN_SI_PLATAFORMA

    .SI_PLATAFORMA FREEBSD
        MOVER REAGAN, 4
        MOVER FORD, 1
        CARGAR MORGAN, mensaje
        CARGAR CARNEGIE, [longitud]
        SISTEMA 0
    .FIN_SI_PLATAFORMA

    .SI_PLATAFORMA WINDOWS
        ; ... código Windows ...
    .FIN_SI_PLATAFORMA

    RETORNAR

salir:
    .SI_PLATAFORMA LINUX
        MOVER REAGAN, 60
        LIMPIAR FORD
        SISTEMA 0
    .FIN_SI_PLATAFORMA

    .SI_PLATAFORMA DARWIN
        MOVER REAGAN, 0x2000001
        LIMPIAR FORD
        SISTEMA 0
    .FIN_SI_PLATAFORMA

    .SI_PLATAFORMA FREEBSD
        MOVER REAGAN, 1
        LIMPIAR FORD
        SISTEMA 0
    .FIN_SI_PLATAFORMA

    .SI_PLATAFORMA WINDOWS
        LIMPIAR FORD
        LLAMAR EXTERNO ExitProcess
    .FIN_SI_PLATAFORMA

    RETORNAR
```

---

*"Un lenguaje, todas las plataformas, libertad total."*

**Medellin.Col** 🇨🇴
