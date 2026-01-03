; =============================================================================
; MEDELLIN.COL - STAGE 0: ELF WRITER
; =============================================================================
; Writes ELF64 executable files for Linux x86-64
; =============================================================================

bits 64
default rel

; -----------------------------------------------------------------------------
; ELF Constants
; -----------------------------------------------------------------------------
; ELF Header
%define EI_MAG0         0x7F
%define EI_MAG1         'E'
%define EI_MAG2         'L'
%define EI_MAG3         'F'
%define ELFCLASS64      2
%define ELFDATA2LSB     1
%define EV_CURRENT      1
%define ELFOSABI_NONE   0
%define ET_EXEC         2
%define EM_X86_64       62

; Program header types
%define PT_NULL         0
%define PT_LOAD         1
%define PT_INTERP       3

; Program header flags
%define PF_X            1
%define PF_W            2
%define PF_R            4

; Section types
%define SHT_NULL        0
%define SHT_PROGBITS    1
%define SHT_SYMTAB      2
%define SHT_STRTAB      3
%define SHT_NOBITS      8

; Section flags
%define SHF_WRITE       1
%define SHF_ALLOC       2
%define SHF_EXECINSTR   4

; Sizes
%define ELF_HEADER_SIZE     64
%define PROGRAM_HEADER_SIZE 56
%define SECTION_HEADER_SIZE 64

; Virtual addresses
%define BASE_ADDR       0x400000
%define PAGE_SIZE       0x1000

; -----------------------------------------------------------------------------
; External dependencies
; -----------------------------------------------------------------------------
extern code_buffer
extern code_size
extern data_buffer
extern data_size
extern util_strlen
extern util_memcpy

; -----------------------------------------------------------------------------
; Exports
; -----------------------------------------------------------------------------
global elf_write
global elf_buffer
global elf_size

; -----------------------------------------------------------------------------
; Data section
; -----------------------------------------------------------------------------
section .data
    ; Section names
    shstrtab:
        db 0                            ; Null
    sh_text:
        db ".text", 0
    sh_data:
        db ".data", 0
    sh_rodata:
        db ".rodata", 0
    sh_bss:
        db ".bss", 0
    sh_shstrtab:
        db ".shstrtab", 0
    shstrtab_end:

    shstrtab_size equ shstrtab_end - shstrtab

section .bss
    ; Output buffer (16MB)
    alignb 16
    elf_buffer:         resb 16 * 1024 * 1024
    elf_ptr:            resq 1
    elf_size:           resq 1

    ; Section offsets (calculated during write)
    text_offset:        resq 1
    text_vaddr:         resq 1
    data_offset:        resq 1
    data_vaddr:         resq 1
    shstrtab_offset:    resq 1

section .text

; -----------------------------------------------------------------------------
; elf_write - Write ELF executable
; -----------------------------------------------------------------------------
; Input:  rdi = entry point offset within code section
; Output: rax = size of ELF file, or 0 on error
; -----------------------------------------------------------------------------
elf_write:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 8

    mov     r12, rdi                    ; Entry point offset

    ; Initialize
    lea     rax, [elf_buffer]
    mov     [elf_ptr], rax

    ; Calculate layout:
    ; - ELF header: 64 bytes
    ; - Program headers: 2 * 56 = 112 bytes (text + data)
    ; - .text section: code_size (page aligned)
    ; - .data section: data_size (page aligned)
    ; - .shstrtab section: shstrtab_size
    ; - Section headers: 5 * 64 = 320 bytes

    ; Headers start at offset 0
    ; Text starts after headers (page aligned)
    mov     rax, ELF_HEADER_SIZE
    add     rax, 2 * PROGRAM_HEADER_SIZE
    ; Align to page
    add     rax, PAGE_SIZE - 1
    and     rax, ~(PAGE_SIZE - 1)
    mov     [text_offset], rax

    ; Text virtual address
    mov     rcx, BASE_ADDR
    add     rcx, rax
    mov     [text_vaddr], rcx

    ; Data offset (after text, page aligned)
    mov     rax, [text_offset]
    add     rax, [code_size]
    add     rax, PAGE_SIZE - 1
    and     rax, ~(PAGE_SIZE - 1)
    mov     [data_offset], rax

    ; Data virtual address
    mov     rcx, BASE_ADDR
    add     rcx, rax
    mov     [data_vaddr], rcx

    ; Write ELF header
    call    write_elf_header

    ; Write program headers
    call    write_program_headers

    ; Pad to text section offset
    mov     rdi, [text_offset]
    call    pad_to_offset

    ; Write .text section (code)
    lea     rsi, [code_buffer]
    mov     rdi, [elf_ptr]
    mov     rcx, [code_size]
    call    copy_bytes
    mov     rax, [code_size]
    add     [elf_ptr], rax

    ; Pad to data section offset
    mov     rdi, [data_offset]
    call    pad_to_offset

    ; Write .data section
    lea     rsi, [data_buffer]
    mov     rdi, [elf_ptr]
    mov     rcx, [data_size]
    call    copy_bytes
    mov     rax, [data_size]
    add     [elf_ptr], rax

    ; Write .shstrtab section
    mov     rax, [elf_ptr]
    lea     rcx, [elf_buffer]
    sub     rax, rcx
    mov     [shstrtab_offset], rax

    lea     rsi, [shstrtab]
    mov     rdi, [elf_ptr]
    mov     rcx, shstrtab_size
    call    copy_bytes
    add     qword [elf_ptr], shstrtab_size

    ; Write section headers
    call    write_section_headers

    ; Calculate final size
    mov     rax, [elf_ptr]
    lea     rcx, [elf_buffer]
    sub     rax, rcx
    mov     [elf_size], rax

    add     rsp, 8
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; write_elf_header - Write 64-byte ELF header
; -----------------------------------------------------------------------------
write_elf_header:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, [elf_ptr]

    ; e_ident[0-3]: Magic number
    mov     byte [r12 + 0], EI_MAG0
    mov     byte [r12 + 1], EI_MAG1
    mov     byte [r12 + 2], EI_MAG2
    mov     byte [r12 + 3], EI_MAG3

    ; e_ident[4]: Class (64-bit)
    mov     byte [r12 + 4], ELFCLASS64

    ; e_ident[5]: Data encoding (little endian)
    mov     byte [r12 + 5], ELFDATA2LSB

    ; e_ident[6]: Version
    mov     byte [r12 + 6], EV_CURRENT

    ; e_ident[7]: OS/ABI
    mov     byte [r12 + 7], ELFOSABI_NONE

    ; e_ident[8-15]: Padding (zeros)
    xor     rax, rax
    mov     [r12 + 8], rax

    ; e_type (offset 16): Executable
    mov     word [r12 + 16], ET_EXEC

    ; e_machine (offset 18): x86-64
    mov     word [r12 + 18], EM_X86_64

    ; e_version (offset 20): Current
    mov     dword [r12 + 20], EV_CURRENT

    ; e_entry (offset 24): Entry point
    mov     rax, [text_vaddr]
    ; Add entry offset (for 'principal' function - first function)
    mov     [r12 + 24], rax

    ; e_phoff (offset 32): Program header offset
    mov     qword [r12 + 32], ELF_HEADER_SIZE

    ; e_shoff (offset 40): Section header offset
    ; Calculate: after all sections
    mov     rax, [shstrtab_offset]
    add     rax, shstrtab_size
    ; Align to 8
    add     rax, 7
    and     rax, ~7
    mov     [r12 + 40], rax

    ; e_flags (offset 48): None
    mov     dword [r12 + 48], 0

    ; e_ehsize (offset 52): ELF header size
    mov     word [r12 + 52], ELF_HEADER_SIZE

    ; e_phentsize (offset 54): Program header entry size
    mov     word [r12 + 54], PROGRAM_HEADER_SIZE

    ; e_phnum (offset 56): Number of program headers
    mov     word [r12 + 56], 2          ; text + data

    ; e_shentsize (offset 58): Section header entry size
    mov     word [r12 + 58], SECTION_HEADER_SIZE

    ; e_shnum (offset 60): Number of section headers
    mov     word [r12 + 60], 5          ; null, .text, .data, .bss, .shstrtab

    ; e_shstrndx (offset 62): Section header string table index
    mov     word [r12 + 62], 4          ; .shstrtab is section 4

    add     qword [elf_ptr], ELF_HEADER_SIZE

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; write_program_headers - Write program headers
; -----------------------------------------------------------------------------
write_program_headers:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12, [elf_ptr]

    ; Program header 1: .text (code)
    ; p_type: PT_LOAD
    mov     dword [r12 + 0], PT_LOAD

    ; p_flags: PF_R | PF_X
    mov     dword [r12 + 4], PF_R | PF_X

    ; p_offset: File offset
    mov     rax, [text_offset]
    mov     [r12 + 8], rax

    ; p_vaddr: Virtual address
    mov     rax, [text_vaddr]
    mov     [r12 + 16], rax

    ; p_paddr: Physical address (same as virtual)
    mov     [r12 + 24], rax

    ; p_filesz: Size in file
    mov     rax, [code_size]
    mov     [r12 + 32], rax

    ; p_memsz: Size in memory
    mov     [r12 + 40], rax

    ; p_align: Alignment
    mov     qword [r12 + 48], PAGE_SIZE

    add     r12, PROGRAM_HEADER_SIZE

    ; Program header 2: .data
    ; p_type: PT_LOAD
    mov     dword [r12 + 0], PT_LOAD

    ; p_flags: PF_R | PF_W
    mov     dword [r12 + 4], PF_R | PF_W

    ; p_offset: File offset
    mov     rax, [data_offset]
    mov     [r12 + 8], rax

    ; p_vaddr: Virtual address
    mov     rax, [data_vaddr]
    mov     [r12 + 16], rax

    ; p_paddr: Physical address
    mov     [r12 + 24], rax

    ; p_filesz: Size in file
    mov     rax, [data_size]
    mov     [r12 + 32], rax

    ; p_memsz: Size in memory
    mov     [r12 + 40], rax

    ; p_align: Alignment
    mov     qword [r12 + 48], PAGE_SIZE

    add     r12, PROGRAM_HEADER_SIZE

    mov     [elf_ptr], r12

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; write_section_headers - Write section headers
; -----------------------------------------------------------------------------
write_section_headers:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    ; Align to 8 bytes first
    mov     rax, [elf_ptr]
    add     rax, 7
    and     rax, ~7
    mov     [elf_ptr], rax
    mov     r12, rax

    ; Section 0: NULL
    xor     rax, rax
    mov     rcx, SECTION_HEADER_SIZE
.zero_null:
    mov     byte [r12], 0
    inc     r12
    dec     rcx
    jnz     .zero_null

    ; Section 1: .text
    ; sh_name: offset in shstrtab
    mov     dword [r12 + 0], sh_text - shstrtab

    ; sh_type: PROGBITS
    mov     dword [r12 + 4], SHT_PROGBITS

    ; sh_flags: ALLOC | EXECINSTR
    mov     qword [r12 + 8], SHF_ALLOC | SHF_EXECINSTR

    ; sh_addr: Virtual address
    mov     rax, [text_vaddr]
    mov     [r12 + 16], rax

    ; sh_offset: File offset
    mov     rax, [text_offset]
    mov     [r12 + 24], rax

    ; sh_size: Size
    mov     rax, [code_size]
    mov     [r12 + 32], rax

    ; sh_link, sh_info: 0
    mov     dword [r12 + 40], 0
    mov     dword [r12 + 44], 0

    ; sh_addralign: 16
    mov     qword [r12 + 48], 16

    ; sh_entsize: 0
    mov     qword [r12 + 56], 0

    add     r12, SECTION_HEADER_SIZE

    ; Section 2: .data
    mov     dword [r12 + 0], sh_data - shstrtab
    mov     dword [r12 + 4], SHT_PROGBITS
    mov     qword [r12 + 8], SHF_ALLOC | SHF_WRITE
    mov     rax, [data_vaddr]
    mov     [r12 + 16], rax
    mov     rax, [data_offset]
    mov     [r12 + 24], rax
    mov     rax, [data_size]
    mov     [r12 + 32], rax
    mov     dword [r12 + 40], 0
    mov     dword [r12 + 44], 0
    mov     qword [r12 + 48], 8
    mov     qword [r12 + 56], 0

    add     r12, SECTION_HEADER_SIZE

    ; Section 3: .bss (empty for now)
    mov     dword [r12 + 0], sh_bss - shstrtab
    mov     dword [r12 + 4], SHT_NOBITS
    mov     qword [r12 + 8], SHF_ALLOC | SHF_WRITE
    mov     qword [r12 + 16], 0         ; addr
    mov     qword [r12 + 24], 0         ; offset
    mov     qword [r12 + 32], 0         ; size
    mov     dword [r12 + 40], 0
    mov     dword [r12 + 44], 0
    mov     qword [r12 + 48], 8
    mov     qword [r12 + 56], 0

    add     r12, SECTION_HEADER_SIZE

    ; Section 4: .shstrtab
    mov     dword [r12 + 0], sh_shstrtab - shstrtab
    mov     dword [r12 + 4], SHT_STRTAB
    mov     qword [r12 + 8], 0
    mov     qword [r12 + 16], 0         ; addr
    mov     rax, [shstrtab_offset]
    mov     [r12 + 24], rax             ; offset
    mov     qword [r12 + 32], shstrtab_size
    mov     dword [r12 + 40], 0
    mov     dword [r12 + 44], 0
    mov     qword [r12 + 48], 1
    mov     qword [r12 + 56], 0

    add     r12, SECTION_HEADER_SIZE

    mov     [elf_ptr], r12

    pop     r12
    pop     rbx
    pop     rbp
    ret

; -----------------------------------------------------------------------------
; pad_to_offset - Pad buffer with zeros to reach offset
; -----------------------------------------------------------------------------
; Input: rdi = target offset
; -----------------------------------------------------------------------------
pad_to_offset:
    push    rbx
    mov     rbx, rdi                    ; Save target offset

    mov     rax, [elf_ptr]
    lea     rcx, [elf_buffer]
    sub     rax, rcx                    ; Current offset

    cmp     rax, rbx
    jge     .done

    mov     rcx, rbx
    sub     rcx, rax                    ; Bytes to pad

    mov     rdi, [elf_ptr]
.pad_loop:
    test    rcx, rcx
    jz      .done
    mov     byte [rdi], 0
    inc     rdi
    dec     rcx
    jmp     .pad_loop

.done:
    lea     rax, [elf_buffer]
    add     rax, rbx                    ; Use saved target offset
    mov     [elf_ptr], rax
    pop     rbx
    ret

; -----------------------------------------------------------------------------
; copy_bytes - Copy bytes from source to destination
; -----------------------------------------------------------------------------
; Input: rdi = dest, rsi = source, rcx = count
; -----------------------------------------------------------------------------
copy_bytes:
    test    rcx, rcx
    jz      .done
.loop:
    mov     al, [rsi]
    mov     [rdi], al
    inc     rsi
    inc     rdi
    dec     rcx
    jnz     .loop
.done:
    ret

; =============================================================================
; END OF FILE
; =============================================================================
