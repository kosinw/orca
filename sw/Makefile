# Remove random Makefile defaults.
override MAKEFLAGS += -rR

# Target architecture and toolchain.
ARCH := riscv32-unknown-linux-gnu
CC := $(ARCH)-gcc
OBJCOPY := $(ARCH)-objcopy
OBJDUMP := $(ARCH)-objdump

# Use "find" to glob all *.S, *.rs, and *.ld files in the tree and obtain the
# object and header dependency file names.
ASMFILES := $(shell cd src && find -L * -type f -name '*.S')
CFILES := $(shell cd src && find -L * -type f -name '*.c')
OBJFILES := $(addprefix build/,$(ASMFILES:.S=.o) $(CFILES:.c=.o))
BINFILES := $(OBJFILES:.o=.bin)
HEADER_DEPS := $(addprefix build/dep/,$(ASMFILES:.S=.S.d) $(CFILES:.c=.c.o))

-include $(HEADER_DEPS)

.PHONY: all
all: $(BINFILES)

# Compilation rule for .bin files
build/%.bin: build/%.o linker.ld
	mkdir -p "$$(dirname $@)"
	$(CC) -march=rv32i -mabi=ilp32 -ffreestanding -O2 -nostdlib -Tlinker.ld -o $@.elf $<
	$(OBJCOPY) -O binary -I elf32-littleriscv $@.elf $@
	$(OBJDUMP) -D $@.elf -M numeric > $@.S
	rm -f build/temp

# Compilation rules for .o files
build/%.o: src/%.S Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) -march=rv32i -mabi=ilp32 -ffreestanding -O2 -nostdlib -o $@ -c $<