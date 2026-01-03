# =============================================================================
# MEDELLIN.COL - RUNTIME MAKEFILE
# =============================================================================
# Builds the Linux x86-64 runtime library
# =============================================================================

# Assembler
NASM = nasm
NASM_FLAGS = -f elf64 -g -F dwarf

# Linker
LD = ld
LD_FLAGS = -nostdlib -static

# Archiver
AR = ar
AR_FLAGS = rcs

# Output
RUNTIME_LIB = libmedellin_rt.a

# Source files
ASM_SOURCES = inicio.asm syscalls.asm memoria.asm io.asm panic.asm

# Object files
OBJECTS = $(ASM_SOURCES:.asm=.o)

# Default target
.PHONY: all clean test

all: $(RUNTIME_LIB)

# Build runtime library
$(RUNTIME_LIB): $(OBJECTS)
	$(AR) $(AR_FLAGS) $@ $^
	@echo "Runtime library built: $@"

# Compile assembly files
%.o: %.asm
	$(NASM) $(NASM_FLAGS) -o $@ $<

# Clean build artifacts
clean:
	rm -f $(OBJECTS) $(RUNTIME_LIB)
	rm -f test_runtime

# Build and run test
test: $(RUNTIME_LIB) test_programa.asm
	$(NASM) $(NASM_FLAGS) -o test_programa.o test_programa.asm
	$(LD) $(LD_FLAGS) -o test_runtime test_programa.o $(RUNTIME_LIB)
	./test_runtime
	@echo "Test passed!"

# Dependencies
inicio.o: inicio.asm
syscalls.o: syscalls.asm
memoria.o: memoria.asm
io.o: io.asm
panic.o: panic.asm
