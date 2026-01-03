; =============================================================================
; MEDELLIN.COL - RUNTIME: SYSTEM CALLS
; =============================================================================
; Direct Linux x86-64 syscall wrappers
; No libc dependency - pure syscall interface
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; Syscall numbers (Linux x86-64)
; -----------------------------------------------------------------------------
%define SYS_READ        0
%define SYS_WRITE       1
%define SYS_OPEN        2
%define SYS_CLOSE       3
%define SYS_STAT        4
%define SYS_FSTAT       5
%define SYS_LSEEK       8
%define SYS_MMAP        9
%define SYS_MPROTECT    10
%define SYS_MUNMAP      11
%define SYS_BRK         12
%define SYS_EXIT        60
%define SYS_GETPID      39
%define SYS_CLOCK_GETTIME 228

; -----------------------------------------------------------------------------
; File descriptors
; -----------------------------------------------------------------------------
%define STDIN           0
%define STDOUT          1
%define STDERR          2

; -----------------------------------------------------------------------------
; mmap flags
; -----------------------------------------------------------------------------
%define PROT_READ       0x1
%define PROT_WRITE      0x2
%define MAP_PRIVATE     0x02
%define MAP_ANONYMOUS   0x20

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global _medellin_salir
global _medellin_escribir
global _medellin_leer
global _medellin_abrir
global _medellin_cerrar
global _medellin_mmap
global _medellin_munmap
global _medellin_brk

section .text

; -----------------------------------------------------------------------------
; _medellin_salir - Exit program
; -----------------------------------------------------------------------------
; Input:  rdi = exit code
; Output: does not return
; -----------------------------------------------------------------------------
_medellin_salir:
    mov     rax, SYS_EXIT
    syscall
    ; No return

; -----------------------------------------------------------------------------
; _medellin_escribir - Write to file descriptor
; -----------------------------------------------------------------------------
; Input:  rdi = file descriptor
;         rsi = buffer pointer
;         rdx = byte count
; Output: rax = bytes written (or negative error)
; -----------------------------------------------------------------------------
_medellin_escribir:
    mov     rax, SYS_WRITE
    syscall
    ret

; -----------------------------------------------------------------------------
; _medellin_leer - Read from file descriptor
; -----------------------------------------------------------------------------
; Input:  rdi = file descriptor
;         rsi = buffer pointer
;         rdx = max bytes to read
; Output: rax = bytes read (or negative error)
; -----------------------------------------------------------------------------
_medellin_leer:
    mov     rax, SYS_READ
    syscall
    ret

; -----------------------------------------------------------------------------
; _medellin_abrir - Open file
; -----------------------------------------------------------------------------
; Input:  rdi = pathname (null-terminated)
;         rsi = flags
;         rdx = mode
; Output: rax = file descriptor (or negative error)
; -----------------------------------------------------------------------------
_medellin_abrir:
    mov     rax, SYS_OPEN
    syscall
    ret

; -----------------------------------------------------------------------------
; _medellin_cerrar - Close file descriptor
; -----------------------------------------------------------------------------
; Input:  rdi = file descriptor
; Output: rax = 0 on success (or negative error)
; -----------------------------------------------------------------------------
_medellin_cerrar:
    mov     rax, SYS_CLOSE
    syscall
    ret

; -----------------------------------------------------------------------------
; _medellin_mmap - Map memory
; -----------------------------------------------------------------------------
; Input:  rdi = address hint (or 0)
;         rsi = length
;         rdx = protection flags
;         r10 = flags
;         r8  = file descriptor (-1 for anonymous)
;         r9  = offset
; Output: rax = mapped address (or negative error)
; -----------------------------------------------------------------------------
_medellin_mmap:
    mov     rax, SYS_MMAP
    syscall
    ret

; -----------------------------------------------------------------------------
; _medellin_munmap - Unmap memory
; -----------------------------------------------------------------------------
; Input:  rdi = address
;         rsi = length
; Output: rax = 0 on success (or negative error)
; -----------------------------------------------------------------------------
_medellin_munmap:
    mov     rax, SYS_MUNMAP
    syscall
    ret

; -----------------------------------------------------------------------------
; _medellin_brk - Adjust program break
; -----------------------------------------------------------------------------
; Input:  rdi = new break address (or 0 to query)
; Output: rax = current/new break address
; -----------------------------------------------------------------------------
_medellin_brk:
    mov     rax, SYS_BRK
    syscall
    ret

; =============================================================================
; END OF FILE
; =============================================================================
