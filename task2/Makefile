# ============================================================
# Makefile - BIT 4220 Task 2: Student Marks Processor Using
#            Registers and Addressing Modes
# ============================================================
ASM = nasm
ASMFLAGS = -f elf64
LD = ld

TARGETS = marks marks_boundary_test

all: $(TARGETS)

marks: marks.o
	$(LD) marks.o -o marks

marks.o: marks.asm
	$(ASM) $(ASMFLAGS) marks.asm -o marks.o

marks_boundary_test: marks_boundary_test.o
	$(LD) marks_boundary_test.o -o marks_boundary_test

marks_boundary_test.o: marks_boundary_test.asm
	$(ASM) $(ASMFLAGS) marks_boundary_test.asm -o marks_boundary_test.o

run: all
	@echo "----- Running marks (main dataset) -----"
	@./marks
	@echo "----- Running marks_boundary_test (boundary values) -----"
	@./marks_boundary_test

debug: marks.asm
	$(ASM) $(ASMFLAGS) -g -F dwarf marks.asm -o marks_dbg.o
	$(LD) marks_dbg.o -o marks_dbg
	@echo "Built marks_dbg with debug symbols. Run: gdb ./marks_dbg"

clean:
	rm -f *.o $(TARGETS) marks_dbg

.PHONY: all run debug clean
