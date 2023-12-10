# Remove random Makefile defaults.
override MAKEFLAGS += -rR

# Target architecture and toolchain.
ARCH := riscv32-unknown-linux-gnu
CC := $(ARCH)-gcc
OBJCOPY := $(ARCH)-objcopy
OBJDUMP := $(ARCH)-objdump

# Compiler flags
CFLAGS := -mstrict-align -mpreferred-stack-boundary=4
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -march=rv32im -mabi=ilp32
CFLAGS += -O2 -flto -g

ASMFILES := $(shell cd src && find -L * -type f -name '*.S')
CFILES := $(shell cd src && find -L * -type f -name '*.c')
RUNTIME := $(addprefix runtime/, $(shell cd runtime && find -L * -type f -name '*.c') $(shell cd runtime && find -L * -type f -name '*.S'))
OBJFILES := $(addprefix build/obj/,$(ASMFILES:.S=.S.o) $(CFILES:.c=.c.o))
BINFILES := $(OBJFILES:build/obj/%.S.o=build/%.bin) $(OBJFILES:build/obj/%.c.o=build/%.bin)
HEADER_DEPS := $(addprefix build/dep/,$(ASMFILES:.S=.d) $(CFILES:.c=.d))

-include $(HEADER_DEPS)

.PHONY: all
all: $(BINFILES)

# Compilation rule for .bin files
build/%.bin: build/obj/%.elf
	mkdir -p "$$(dirname $@)"
	$(OBJCOPY) -O binary -I elf32-littleriscv $< $@
	$(OBJDUMP) -D $< > $(basename $<).dump

# Compilation rule for .elf files
build/obj/%.elf: build/obj/%.S.o linker.ld
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) -Tlinker.ld -o $@ $< -Wl,--gc-sections

# Compilation rules for .c.o files
build/obj/%.elf: build/obj/%.c.o $(RUNTIME) linker.ld
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) -Iruntime -Tlinker.ld -o $@ $(RUNTIME) $< -Wl,--gc-sections

# Compilation rules for .c.o files
build/obj/%.c.o: src/%.c Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) -Iruntime -o $@ -c $<

# Compilation rules for .S.o files
build/obj/%.S.o: src/%.S Makefile
	mkdir -p "$$(dirname $@)"
	$(CC) $(CFLAGS) -o $@ -c $<

.PHONY: clean
clean:
	rm -rf build