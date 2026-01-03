# =============================================================================
# MEDELLIN.COL - STAGE 0 COMPILER MAKEFILE
# =============================================================================

# Tools
NASM = nasm
NASM_FLAGS = -f elf64 -g -F dwarf -I../runtime/linux_x86_64/
LD = ld
LD_FLAGS = -nostdlib -static

# Output
COMPILER = medellin0

# Source files (order matters for dependencies)
ASM_SOURCES = \
	main.asm \
	utils.asm \
	strings.asm \
	errors.asm \
	lexer.asm \
	parser.asm \
	symbols.asm \
	types.asm \
	codegen.asm \
	elf.asm

# Object files
OBJECTS = $(ASM_SOURCES:.asm=.o)

# Runtime library
RUNTIME = ../runtime/linux_x86_64/libmedellin_rt.a

# Default target
.PHONY: all clean test runtime

all: $(COMPILER)

# Build compiler
$(COMPILER): $(OBJECTS) $(RUNTIME)
	$(LD) $(LD_FLAGS) -o $@ $(OBJECTS) $(RUNTIME)
	@echo "Stage 0 compiler built: $@"

# Build runtime first
$(RUNTIME):
	$(MAKE) -C ../runtime/linux_x86_64/

# Compile assembly files
%.o: %.asm
	$(NASM) $(NASM_FLAGS) -o $@ $<

# Clean
clean:
	rm -f $(OBJECTS) $(COMPILER)
	rm -f test_output test_output.o

# Test with hello world
test: $(COMPILER)
	./$(COMPILER) ../examples/hola_mundo.col -o test_output
	./test_output
	@echo "Test passed!"

# Dependencies
main.o: main.asm
utils.o: utils.asm
strings.o: strings.asm
errors.o: errors.asm
lexer.o: lexer.asm
parser.o: parser.asm
symbols.o: symbols.asm
types.o: types.asm
codegen.o: codegen.asm
elf.o: elf.asm
