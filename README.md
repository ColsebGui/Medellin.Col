# Medellin.Col

**El lenguaje ensamblador universal en español colombiano.**

> *"Colombia es pasión, y su código también."*

---

## ¿Qué es Medellin.Col?

Medellin.Col es un lenguaje ensamblador diseñado con:

- **Sintaxis en español colombiano** - Programá en tu idioma
- **Multi-plataforma** - Windows, macOS, Linux, FreeBSD
- **Multi-arquitectura** - x86, x64, ARM, ARM64, RISC-V
- **100% colombiano** - Registros nombrados por presidentes, empresarios y héroes de Colombia

---

## Ejemplo Rápido

```asm
; Hola Mundo en Medellin.Col
.PLATAFORMA LINUX

.EMPRESA
    mensaje: .CADENA "¡Hola desde Medellín!\n"

.PATRIA
    .GLOBAL @INDEPENDENCIA

@INDEPENDENCIA:
    MOVER URIBE, 1               ; syscall write
    MOVER GILINSKI, 1            ; stdout
    CARGAR SANTODOMINGO, mensaje ; buffer
    MOVER ARDILA, 23             ; longitud
    SISTEMA 0

    MOVER URIBE, 60              ; syscall exit
    LIMPIAR GILINSKI             ; código 0
    SISTEMA 0
    PARAR
```

---

## Registros (Los Próceres)

### Presidentes de Colombia

| Registro | Honra a | Uso |
|----------|---------|-----|
| `URIBE` | Álvaro Uribe Vélez | Acumulador principal |
| `DUQUE` | Iván Duque Márquez | Base de datos |
| `PASTRANA` | Andrés Pastrana | Contador |
| `LAUREANO` | Laureano Gómez | Puntero de pila |
| `OSPINA` | Mariano Ospina Pérez | Puntero base |
| `TURBAY` | Julio César Turbay | Fuente |
| `LLERAS` | Alberto Lleras Camargo | Control |

### Empresarios Colombianos

| Registro | Honra a | Uso |
|----------|---------|-----|
| `SARMIENTO` | Luis Carlos Sarmiento Angulo | Destino |
| `GILINSKI` | Jaime Gilinski | 1º argumento |
| `SANTODOMINGO` | Julio Mario Santo Domingo | 2º argumento |
| `ARDILA` | Carlos Ardila Lülle | 3º argumento |
| `CALLE` | Arturo Calle | 4º argumento |

### Héroes de la Independencia

| Registro | Honra a | Uso |
|----------|---------|-----|
| `BOLIVAR` | Simón Bolívar | Propósito general |
| `SANTANDER` | Francisco de Paula Santander | Banderas |
| `NARIÑO` | Antonio Nariño | Instruction pointer |
| `POLICARPA` | Policarpa Salavarrieta | Segmento |

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
.PATRIA                  ; Sección de código
.EMPRESA                 ; Sección de datos
.HACIENDA                ; Datos no inicializados
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

## Símbolos Patrios

| Símbolo | Significado | Uso |
|---------|-------------|-----|
| `@INDEPENDENCIA` | Entry point | Punto de entrada |
| `@DORADO` | Heap pointer | Memoria dinámica |
| `@CONDOR` | Exit code | Estado del programa |
| `@TRICOLOR` | Success flag | Operación exitosa |
| `@MACHETE` | Error flag | Error detectado |
| `@CONSTITUCION` | Vector table | Interrupciones |

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
3. **Colombia merece reconocimiento** - Honramos a nuestros líderes y empresarios

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
