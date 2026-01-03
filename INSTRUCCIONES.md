# Medellin.Col - Referencia de Instrucciones

## Codificación de Instrucciones

Medellin.Col usa un formato de instrucción variable que mapea directamente a las arquitecturas objetivo.

---

## Formato de Instrucción

```
[PREFIJO] OPERACIÓN DESTINO, FUENTE [; comentario]
```

### Prefijos Opcionales

| Prefijo | Significado | Ejemplo |
|---------|-------------|---------|
| `BLOQUEAR` | Operación atómica (LOCK) | `BLOQUEAR SUMAR [contador], 1` |
| `REPETIR` | Repetir mientras HAYEK > 0 | `REPETIR MOVER_CADENA` |
| `REPETIR_SI_IGUAL` | Repetir mientras igual | `REPETIR_SI_IGUAL COMPARAR_CADENA` |
| `REPETIR_SI_DIFERENTE` | Repetir mientras diferente | `REPETIR_SI_DIFERENTE BUSCAR_CADENA` |

---

## Instrucciones de Datos (La Riqueza)

### MOVER - Transferencia de Datos

**Sintaxis:** `MOVER destino, fuente`

**Descripción:** Copia el valor de la fuente al destino.

**Variantes:**
```asm
MOVER REAGAN, 0x1234           ; Inmediato a registro
MOVER REAGAN, THATCHER         ; Registro a registro
MOVER REAGAN, [memoria]        ; Memoria a registro
MOVER [memoria], REAGAN        ; Registro a memoria
MOVER [memoria], 0x1234        ; Inmediato a memoria
```

**Banderas afectadas:** Ninguna

---

### CARGAR - Cargar Dirección Efectiva

**Sintaxis:** `CARGAR destino, [dirección]`

**Descripción:** Calcula la dirección efectiva y la almacena en el destino.

```asm
CARGAR REAGAN, [THATCHER + HAYEK*8 + 16]
```

**Banderas afectadas:** Ninguna

---

### EMPUJAR / SACAR - Operaciones de Pila

**Sintaxis:**
```asm
EMPUJAR fuente      ; Push
SACAR destino       ; Pop
```

**Descripción:** Manipula la pila del sistema.

```asm
EMPUJAR REAGAN           ; Guardar REAGAN en pila
EMPUJAR 0x1234           ; Empujar inmediato
EMPUJAR [memoria]        ; Empujar desde memoria
SACAR THATCHER           ; Restaurar en THATCHER
SACAR [memoria]          ; Sacar a memoria
```

**Banderas afectadas:** Ninguna

---

### EMPUJAR_TODO / SACAR_TODO - Preservar Estado

**Sintaxis:**
```asm
EMPUJAR_TODO        ; Guardar todos los registros
SACAR_TODO          ; Restaurar todos los registros
```

---

## Instrucciones Aritméticas (El Capital)

### SUMAR - Adición

**Sintaxis:** `SUMAR destino, fuente`

**Operación:** `destino = destino + fuente`

```asm
SUMAR REAGAN, 10              ; REAGAN += 10
SUMAR REAGAN, THATCHER        ; REAGAN += THATCHER
SUMAR [contador], 1           ; Incrementar memoria
```

**Banderas afectadas:** @LIBERTAD (carry), @SERPIENTE (overflow), Cero, Signo

---

### SUMAR_CON_ACARREO - Adición con Carry

**Sintaxis:** `SUMAR_CON_ACARREO destino, fuente`

**Operación:** `destino = destino + fuente + @LIBERTAD`

---

### RESTAR - Sustracción

**Sintaxis:** `RESTAR destino, fuente`

**Operación:** `destino = destino - fuente`

```asm
RESTAR REAGAN, 5
RESTAR REAGAN, THATCHER
```

**Banderas afectadas:** @LIBERTAD (borrow), @SERPIENTE (overflow), Cero, Signo

---

### RESTAR_CON_ACARREO - Sustracción con Borrow

**Sintaxis:** `RESTAR_CON_ACARREO destino, fuente`

**Operación:** `destino = destino - fuente - @LIBERTAD`

---

### MULTIPLICAR - Multiplicación

**Sintaxis:** `MULTIPLICAR fuente`

**Operación:**
- 8-bit: `REAGAN16 = REAGAN8 * fuente`
- 16-bit: `THATCHER:REAGAN = REAGAN16 * fuente`
- 32-bit: `THATCHER:REAGAN = REAGAN32 * fuente`
- 64-bit: `THATCHER:REAGAN = REAGAN * fuente`

```asm
MOVER REAGAN, 10
MULTIPLICAR THATCHER         ; THATCHER:REAGAN = REAGAN * THATCHER
```

---

### MULTIPLICAR_FIRMADO - Multiplicación con Signo

**Sintaxis:** `MULTIPLICAR_FIRMADO destino, fuente[, inmediato]`

```asm
MULTIPLICAR_FIRMADO REAGAN, THATCHER        ; REAGAN *= THATCHER
MULTIPLICAR_FIRMADO REAGAN, THATCHER, 10    ; REAGAN = THATCHER * 10
```

---

### DIVIDIR - División

**Sintaxis:** `DIVIDIR fuente`

**Operación:**
- `REAGAN = THATCHER:REAGAN / fuente`
- `THATCHER = THATCHER:REAGAN % fuente` (residuo)

```asm
LIMPIAR THATCHER            ; Limpiar parte alta
MOVER REAGAN, 100
MOVER HAYEK, 7
DIVIDIR HAYEK               ; REAGAN = 14, THATCHER = 2
```

---

### DIVIDIR_FIRMADO - División con Signo

**Sintaxis:** `DIVIDIR_FIRMADO fuente`

---

## Instrucciones Lógicas (La Razón)

### Y - AND Lógico

**Sintaxis:** `Y destino, fuente`

**Operación:** `destino = destino & fuente`

```asm
Y REAGAN, 0xFF              ; Máscara de byte bajo
Y REAGAN, THATCHER
```

**Banderas afectadas:** Cero, Signo, Paridad. @LIBERTAD y @SERPIENTE = 0

---

### O - OR Lógico

**Sintaxis:** `O destino, fuente`

**Operación:** `destino = destino | fuente`

```asm
O REAGAN, 0x80              ; Establecer bit 7
```

---

### OX - XOR Lógico

**Sintaxis:** `OX destino, fuente`

**Operación:** `destino = destino ^ fuente`

```asm
OX REAGAN, REAGAN           ; Poner en cero (rápido)
OX REAGAN, 0xFF             ; Invertir byte bajo
```

---

### NO - NOT Lógico

**Sintaxis:** `NO destino`

**Operación:** `destino = ~destino`

```asm
NO REAGAN                   ; Complemento a uno
```

**Banderas afectadas:** Ninguna

---

### PROBAR - Test de Bits

**Sintaxis:** `PROBAR op1, op2`

**Operación:** Ejecuta AND pero descarta resultado, solo afecta banderas.

```asm
PROBAR REAGAN, 0x01         ; ¿Bit 0 activo?
SALTAR_SI_NO_CERO es_impar
```

---

## Instrucciones de Desplazamiento (El Apalancamiento)

### DESPLAZAR_IZQ - Shift Left

**Sintaxis:** `DESPLAZAR_IZQ destino, cantidad`

```asm
DESPLAZAR_IZQ REAGAN, 4     ; REAGAN *= 16
DESPLAZAR_IZQ REAGAN, HAYEK8 ; Cantidad en registro
```

---

### DESPLAZAR_DER - Shift Right (Lógico)

**Sintaxis:** `DESPLAZAR_DER destino, cantidad`

```asm
DESPLAZAR_DER REAGAN, 1     ; REAGAN /= 2 (sin signo)
```

---

### DESPLAZAR_DER_ARIT - Shift Right Aritmético

**Sintaxis:** `DESPLAZAR_DER_ARIT destino, cantidad`

**Descripción:** Preserva el bit de signo.

```asm
DESPLAZAR_DER_ARIT REAGAN, 2  ; División con signo por 4
```

---

### ROTAR_IZQ / ROTAR_DER - Rotaciones

**Sintaxis:**
```asm
ROTAR_IZQ destino, cantidad
ROTAR_DER destino, cantidad
```

---

### ROTAR_IZQ_ACARREO / ROTAR_DER_ACARREO

**Descripción:** Rotar a través del bit de acarreo.

---

## Instrucciones de Control (El Liderazgo)

### SALTAR - Salto Incondicional

**Sintaxis:** `SALTAR destino`

```asm
SALTAR inicio               ; Salto a etiqueta
SALTAR REAGAN               ; Salto indirecto
SALTAR [tabla + HAYEK*8]    ; Salto indexado
```

---

### COMPARAR - Comparación

**Sintaxis:** `COMPARAR op1, op2`

**Operación:** Resta op2 de op1, descarta resultado, establece banderas.

```asm
COMPARAR REAGAN, 100
SALTAR_SI_MAYOR exito
SALTAR_SI_MENOR fallo
```

---

### Saltos Condicionales

| Instrucción | Condición | Banderas |
|-------------|-----------|----------|
| `SALTAR_SI_IGUAL` | Igual | Cero = 1 |
| `SALTAR_SI_DIFERENTE` | No igual | Cero = 0 |
| `SALTAR_SI_MAYOR` | Mayor (sin signo) | Carry=0 y Cero=0 |
| `SALTAR_SI_MENOR` | Menor (sin signo) | Carry = 1 |
| `SALTAR_SI_MAYOR_IGUAL` | Mayor o igual | Carry = 0 |
| `SALTAR_SI_MENOR_IGUAL` | Menor o igual | Carry=1 o Cero=1 |
| `SALTAR_SI_MAYOR_FIRMADO` | Mayor (con signo) | Signo = Overflow y Cero = 0 |
| `SALTAR_SI_MENOR_FIRMADO` | Menor (con signo) | Signo ≠ Overflow |
| `SALTAR_SI_CERO` | Es cero | Cero = 1 |
| `SALTAR_SI_NO_CERO` | No es cero | Cero = 0 |
| `SALTAR_SI_NEGATIVO` | Es negativo | Signo = 1 |
| `SALTAR_SI_POSITIVO` | Es positivo/cero | Signo = 0 |
| `SALTAR_SI_OVERFLOW` | Hay overflow | Overflow = 1 |
| `SALTAR_SI_NO_OVERFLOW` | No hay overflow | Overflow = 0 |
| `SALTAR_SI_ACARREO` | Hay carry | @LIBERTAD = 1 |
| `SALTAR_SI_NO_ACARREO` | No hay carry | @LIBERTAD = 0 |

---

### LLAMAR - Llamada a Subrutina

**Sintaxis:** `LLAMAR destino`

**Operación:** Empuja dirección de retorno, salta a destino.

```asm
LLAMAR calcular_impuesto
; ... continúa aquí después del retorno
```

---

### RETORNAR - Retorno de Subrutina

**Sintaxis:** `RETORNAR [n]`

**Operación:** Saca dirección de retorno, opcionalmente ajusta pila.

```asm
RETORNAR              ; Retorno simple
RETORNAR 16           ; Retorno y limpiar 16 bytes de argumentos
```

---

### BUCLE - Bucle con Contador

**Sintaxis:** `BUCLE destino`

**Operación:** Decrementa HAYEK, salta si no es cero.

```asm
MOVER HAYEK, 10
repetir:
    ; ... código del bucle ...
    BUCLE repetir       ; Repetir 10 veces
```

---

### BUCLE_SI_IGUAL / BUCLE_SI_DIFERENTE

**Descripción:** Combina BUCLE con condición adicional.

---

## Instrucciones de Sistema (El Gobierno)

### SISTEMA - Llamada al Sistema

**Sintaxis:** `SISTEMA n`

**Descripción:** Ejecuta llamada al sistema operativo. Los argumentos dependen de la plataforma.

#### Linux
```asm
; Escribir "Hola" a stdout
MOVER REAGAN, 1              ; sys_write
MOVER FORD, 1                ; fd = stdout
CARGAR MORGAN, mensaje       ; buffer
MOVER CARNEGIE, 4            ; longitud
SISTEMA 0                    ; syscall (0 = usar REAGAN como número)
```

#### Windows
```asm
; Usar convención de llamada Windows
CARGAR FORD, mensaje
LLAMAR EXTERNO WriteConsoleA
```

---

### INTERRUMPIR - Interrupción Software

**Sintaxis:** `INTERRUMPIR n`

```asm
INTERRUMPIR 0x80            ; Linux legacy syscall
INTERRUMPIR 0x2E            ; Windows syscall (legacy)
INTERRUMPIR 3               ; Breakpoint
```

---

### ENTRADA / SALIDA - I/O de Puerto

**Sintaxis:**
```asm
ENTRADA destino, puerto
SALIDA puerto, fuente
```

**Nota:** Requiere privilegios de kernel en la mayoría de sistemas.

```asm
ENTRADA REAGAN8, 0x60       ; Leer teclado
SALIDA 0x60, REAGAN8        ; Escribir a puerto
```

---

## Instrucciones de Cadena (La Comunicación)

### MOVER_CADENA - Mover String

**Sintaxis:** `MOVER_CADENA`

**Operación:** Copia de [RAND] a [ROCKEFELLER], actualiza ambos.

```asm
CARGAR RAND, origen
CARGAR ROCKEFELLER, destino
MOVER HAYEK, longitud
REPETIR MOVER_CADENA
```

Variantes: `MOVER_CADENA_BYTE`, `MOVER_CADENA_PALABRA`, `MOVER_CADENA_DOBLE`, `MOVER_CADENA_CUADRUPLE`

---

### COMPARAR_CADENA - Comparar String

**Sintaxis:** `COMPARAR_CADENA`

**Operación:** Compara [RAND] con [ROCKEFELLER].

---

### BUSCAR_CADENA - Buscar en String

**Sintaxis:** `BUSCAR_CADENA`

**Operación:** Busca REAGAN en [ROCKEFELLER].

---

### CARGAR_CADENA - Cargar desde String

**Sintaxis:** `CARGAR_CADENA`

**Operación:** Carga de [RAND] a REAGAN.

---

### GUARDAR_CADENA - Guardar a String

**Sintaxis:** `GUARDAR_CADENA`

**Operación:** Guarda REAGAN en [ROCKEFELLER].

---

## Instrucciones Condicionales (La Meritocracia)

### MOVER_SI_* - Move Condicional

| Instrucción | Condición |
|-------------|-----------|
| `MOVER_SI_IGUAL` | Si igual |
| `MOVER_SI_DIFERENTE` | Si diferente |
| `MOVER_SI_MAYOR` | Si mayor |
| `MOVER_SI_MENOR` | Si menor |
| `MOVER_SI_CERO` | Si cero |
| `MOVER_SI_NO_CERO` | Si no cero |

```asm
COMPARAR REAGAN, THATCHER
MOVER_SI_MAYOR HAYEK, REAGAN    ; HAYEK = max(REAGAN, THATCHER)
MOVER_SI_MENOR HAYEK, THATCHER
```

---

### ESTABLECER_SI_* - Set Byte Condicional

**Sintaxis:** `ESTABLECER_SI_MAYOR destino8`

**Operación:** Establece destino en 1 si condición es verdadera, 0 si no.

```asm
COMPARAR REAGAN, 100
ESTABLECER_SI_MAYOR HAYEK8     ; HAYEK8 = (REAGAN > 100) ? 1 : 0
```

---

## Instrucciones de Bit (La Precisión)

### PROBAR_BIT - Test Bit

**Sintaxis:** `PROBAR_BIT base, bit`

**Operación:** Copia bit especificado a @LIBERTAD.

```asm
PROBAR_BIT REAGAN, 7           ; ¿Bit 7 activo?
SALTAR_SI_ACARREO bit_activo
```

---

### ESTABLECER_BIT - Set Bit

**Sintaxis:** `ESTABLECER_BIT base, bit`

```asm
ESTABLECER_BIT REAGAN, 0       ; Establecer bit 0
```

---

### LIMPIAR_BIT - Clear Bit

**Sintaxis:** `LIMPIAR_BIT base, bit`

---

### COMPLEMENTAR_BIT - Toggle Bit

**Sintaxis:** `COMPLEMENTAR_BIT base, bit`

---

### CONTAR_CEROS_IZQ / CONTAR_CEROS_DER

**Sintaxis:** `CONTAR_CEROS_IZQ destino, fuente`

**Operación:** Cuenta bits cero desde el lado especificado.

---

### CONTAR_UNOS - Population Count

**Sintaxis:** `CONTAR_UNOS destino, fuente`

**Operación:** Cuenta bits en 1.

---

## Instrucciones Atómicas (El Contrato)

### COMPARAR_INTERCAMBIAR

**Sintaxis:** `COMPARAR_INTERCAMBIAR destino, fuente`

**Operación:** Si REAGAN == destino, entonces destino = fuente y @LIBERTAD = 0. Si no, REAGAN = destino y @LIBERTAD = 1.

```asm
MOVER REAGAN, valor_esperado
BLOQUEAR COMPARAR_INTERCAMBIAR [mutex], nuevo_valor
SALTAR_SI_NO_CERO retry
```

---

### INTERCAMBIAR_SUMAR

**Sintaxis:** `INTERCAMBIAR_SUMAR destino, fuente`

**Operación:** temp = destino; destino += fuente; fuente = temp

```asm
BLOQUEAR INTERCAMBIAR_SUMAR [contador], REAGAN  ; Atómico: REAGAN = old, contador += old_REAGAN
```

---

## Instrucciones SIMD (El Equipo)

*Próximamente: Extensiones vectoriales nombradas por equipos de libre mercado.*

| Registro | Inspiración |
|----------|-------------|
| `ATLAS0-15` | Atlas (mitología, cargando el mundo) |
| `FENIX0-15` | Fénix (renacimiento, resiliencia) |

---

*"Cada instrucción cuenta, como cada centavo en el libre mercado."*
