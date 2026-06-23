# ============================================================
# Makefile - BIT 4220 Task 3: Mini Arithmetic Logic Unit for
#            an Embedded Billing Device
# ============================================================
ASM = nasm
ASMFLAGS = -f elf64
LD = ld

TARGETS = alu

all: $(TARGETS)

alu: alu.o
	$(LD) alu.o -o alu

alu.o: alu.asm
	$(ASM) $(ASMFLAGS) alu.asm -o alu.o

run: all
	@echo "----- Running alu (interactive - type your menu choices) -----"
	@./alu

debug: alu.asm
	$(ASM) $(ASMFLAGS) -g -F dwarf alu.asm -o alu_dbg.o
	$(LD) alu_dbg.o -o alu_dbg
	@echo "Built alu_dbg with debug symbols. Run: gdb ./alu_dbg"

clean:
	rm -f *.o $(TARGETS) alu_dbg

.PHONY: all run debug clean
