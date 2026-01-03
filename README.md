# Medellin.Col

**El lenguaje ensamblador universal en español colombiano.**

> *"La libertad no tiene fronteras, y tampoco nuestro código."*

---

## ¿Qué es Medellin.Col?

Medellin.Col es un lenguaje ensamblador diseñado con:

- **Sintaxis en español colombiano** - Programá en tu idioma
- **Multi-plataforma** - Windows, macOS, Linux, FreeBSD
- **Multi-arquitectura** - x86, x64, ARM, ARM64, RISC-V
- **Nombres que honran** - Registros e instrucciones nombrados por líderes del libre mercado

---

## Ejemplo Rápido

```asm
; Hola Mundo en Medellin.Col
.PLATAFORMA LINUX

.CAPITALISMO
    mensaje: .CADENA "¡Hola desde Medellín!\n"

.LIBRE_MERCADO
    .GLOBAL @EMPRESA

@EMPRESA:
    MOVER REAGAN, 1              ; syscall write
    MOVER FORD, 1                ; stdout
    CARGAR MORGAN, mensaje       ; buffer
    MOVER CARNEGIE, 23           ; longitud
    SISTEMA 0

    MOVER REAGAN, 60             ; syscall exit
    LIMPIAR FORD                 ; código 0
    SISTEMA 0
    PARAR
```

---

## Registros (Los Titanes)

| Registro | Honra a | Uso |
|----------|---------|-----|
| `REAGAN` | Ronald Reagan | Acumulador principal |
| `THATCHER` | Margaret Thatcher | Base de datos |
| `HAYEK` | Friedrich Hayek | Contador |
| `FRIEDMAN` | Milton Friedman | Puntero base |
| `MISES` | Ludwig von Mises | Puntero de pila |
| `RAND` | Ayn Rand | Fuente |
| `ROCKEFELLER` | John D. Rockefeller | Destino |
| `CARNEGIE` | Andrew Carnegie | Propósito general |
| `FORD` | Henry Ford | Propósito general |
| `MORGAN` | J.P. Morgan | Propósito general |
| `MILEI` | Javier Milei | Banderas |
| `BUKELE` | Nayib Bukele | Instruction pointer |
| `URIBE` | Álvaro Uribe | Control |

---

## Instrucciones Principales

### Transferencia
```asm
MOVER dest, src          ; Mover datos
CARGAR dest, [mem]       ; Cargar desde memoria
GUARDAR [mem], src       ; Guardar en memoria
EMPUJAR src              ; Push a pila
SACAR dest               ; Pop de pila
```

### Aritmética
```asm
SUMAR dest, src          ; Suma
RESTAR dest, src         ; Resta
MULTIPLICAR src          ; Multiplicación
DIVIDIR src              ; División
INCREMENTAR dest         ; +1
DECREMENTAR dest         ; -1
```

### Lógica
```asm
Y dest, src              ; AND
O dest, src              ; OR
OX dest, src             ; XOR
NO dest                  ; NOT
```

### Control
```asm
SALTAR etiqueta          ; Salto incondicional
COMPARAR op1, op2        ; Comparar
SALTAR_SI_IGUAL etq      ; Saltar si igual
LLAMAR subrutina         ; Llamar función
RETORNAR                 ; Retornar
```

### Sistema
```asm
SISTEMA n                ; Llamada al sistema
PARAR                    ; Detener ejecución
```

---

## Directivas

```asm
.PLATAFORMA LINUX/WINDOWS/DARWIN/FREEBSD/TODAS
.LIBRE_MERCADO           ; Sección de código
.CAPITALISMO             ; Sección de datos
.CONSTANTE nombre valor  ; Definir constante
.CADENA "texto"          ; String
.BYTE valor              ; Byte
.PALABRA valor           ; 16-bit
.DOBLE valor             ; 32-bit
.CUADRUPLE valor         ; 64-bit
.GLOBAL simbolo          ; Exportar símbolo
.EXTERNO simbolo         ; Importar símbolo
```

---

## Plataformas Soportadas

| OS | Arquitecturas | Estado |
|----|---------------|--------|
| Linux | x86, x64, ARM, ARM64, RISC-V | ✅ |
| Windows | x86, x64, ARM64 | ✅ |
| macOS | x64, ARM64 | ✅ |
| FreeBSD | x86, x64, ARM64 | ✅ |

---

## Estructura del Proyecto

```
Medellin.Col/
├── README.md              # Este archivo
├── ESPECIFICACION.md      # Especificación completa del lenguaje
├── INSTRUCCIONES.md       # Referencia detallada de instrucciones
├── PLATAFORMAS.md         # Guía de plataformas y syscalls
├── ejemplos/
│   ├── hola_mundo.col     # Hola Mundo
│   ├── fibonacci.col      # Secuencia Fibonacci
│   └── factorial.col      # Factorial recursivo
└── LICENSE
```

---

## Filosofía

Medellin.Col nace de la idea de que:

1. **La programación debe ser accesible** - Sintaxis en español para hispanohablantes
2. **El código debe ser libre** - Compila a cualquier plataforma
3. **Los nombres importan** - Honramos a quienes construyeron el mundo libre

---

## Extensiones de Archivo

| Extensión | Descripción |
|-----------|-------------|
| `.col` | Código fuente |
| `.col.o` | Objeto compilado |
| `.col.lib` | Biblioteca estática |

---

## Contribuir

¡Las contribuciones son bienvenidas! Este proyecto está en desarrollo activo.

---

## Licencia

MIT License - Ver [LICENSE](LICENSE)

---

*Hecho con orgullo paisa* 🇨🇴

**Medellin.Col v0.1.0**
