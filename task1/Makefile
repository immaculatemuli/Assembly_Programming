# ============================================================
# Makefile - BIT 4220 Task 1: Assembly Environment & Digital
#            Representation Toolkit
# ============================================================
ASM = nasm
ASMFLAGS = -f elf64
LD = ld

TARGETS = hello data_types

all: $(TARGETS)

hello: hello.o
	$(LD) hello.o -o hello

hello.o: hello.asm
	$(ASM) $(ASMFLAGS) hello.asm -o hello.o

data_types: data_types.o
	$(LD) data_types.o -o data_types

data_types.o: data_types.asm
	$(ASM) $(ASMFLAGS) data_types.asm -o data_types.o

run: all
	@echo "----- Running hello -----"
	@./hello
	@echo "----- Running data_types -----"
	@./data_types

clean:
	rm -f *.o $(TARGETS)

.PHONY: all run clean
