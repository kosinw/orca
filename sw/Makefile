# Remove random Makefile defaults.
override MAKEFLAGS += -rR

# Final target to build.
KERNEL := target/kernel
PROFILE ?= dev

ifeq ($(PROFILE), dev)
    PROFILE_DIR := debug
else ifeq ($(PROFILE), release)
    PROFILE_DIR := release
else
    $(error Unsupported PROFILE value: $(PROFILE))
endif

# Target architecture and toolchain.
QEMU := qemu-system-x86_64
ARCH := x86_64-elf
AS := nasm
CC := $(ARCH)-gcc
GDB := $(ARCH)-gdb
CARGO := cargo
OBJCOPY := $(ARCH)-objcopy
OBJDUMP := $(ARCH)-objdump

# Use "find" to glob all *.S, *.rs, and *.ld files in the tree and obtain the
# object and header dependency file names.
ASMFILES := $(shell cd kernel && find -L * -type f -name '*.S')
LINKERFILE := $(shell find -L * -type f -name '*.ld')
RUSTFILES := $(shell find -L * -type f -name '*.rs')
OBJFILES := $(addprefix target/obj/, $(ASMFILES:.S=.S.o))
HEADER_DEPS := $(addprefix target/obj/,$(ASMFILES:.S=.S.d))

# Options for running the QEMU emulator.
QEMUOPTS := -machine microvm,acpi=off,ioapic2=off
QEMUOPTS += -no-reboot -nodefaults
QEMUOPTS += -serial mon:stdio
QEMUOPTS += -device isa-debug-exit,iobase=0x604,iosize=0x04
QEMUOPTS += -nographic
QEMUOPTS += -cpu qemu64,fsgsbase,msr -m 512M
QEMUOPTS += -netdev user,id=net0,hostfwd=tcp::5555-:5555
QEMUOPTS += -device virtio-net-device,netdev=net0
QEMUOPTS += -d int

# Default target.
.PHONY: all
all: kernel

# Run qemu
qemu: $(KERNEL)
	$(QEMU) $(QEMUOPTS) -kernel $(KERNEL)

qemu-gdb: $(KERNEL)
	$(QEMU) -S -s $(QEMUOPTS) -kernel $(KERNEL)

gdb:
	$(GDB) -x cfg/.gdbinit

# Check for errors.
.PHONY: check
check:
	$(CARGO) clippy \
	--profile $(PROFILE) \
	-Z build-std-features=compiler-builtins-mem \
	-Z build-std=alloc,core,compiler_builtins

# Check for errors.
.PHONY: fix
fix:
	$(CARGO) fix \
	--profile $(PROFILE) \
	-Z build-std-features=compiler-builtins-mem \
	-Z build-std=alloc,core,compiler_builtins

# Build the kernel.
.PHONY: kernel
kernel: $(KERNEL)

$(KERNEL): target/obj/kernel.o $(OBJFILES) $(LINKERFILE)
	$(CC) -z noexecstack -ffreestanding -O2 -nostdlib -T $(LINKERFILE) -o target/obj/kernel.elf $(OBJFILES) target/obj/kernel.o
	$(OBJCOPY) --input-target=elf64-x86-64 --output-target=elf32-i386 target/obj/kernel.elf $@
	$(OBJDUMP) -M intel -S target/obj/kernel.elf > target/kernel.S
	$(OBJDUMP) -t target/obj/kernel.elf > target/kernel.sym
	$(OBJDUMP) -x target/obj/kernel.elf > target/kernel.header

# Compilation rules for kernel.o
target/obj/kernel.o: $(RUSTFILES) Makefile
	@echo "Building with PROFILE: $(PROFILE)"
	@echo "Building with PROFILE_DIR: $(PROFILE_DIR)"
	mkdir -p "$$(dirname $@)"
	$(CARGO) build \
	--profile $(PROFILE) \
	-Z build-std-features=compiler-builtins-mem \
	-Z build-std=alloc,core,compiler_builtins \
	cp target/lithium/$(PROFILE_DIR)/libkernel.a $@

# Compilation rules for *.S files.
target/obj/%.S.o: kernel/%.S Makefile
	mkdir -p "$$(dirname $@)"
	$(AS) -f elf64 -Wall -F dwarf -g $< -o $@

# Clean up folders
.PHONY: clean
clean:
	$(CARGO) clean

.PHONY: distclean
distclean:
	rm -rf target

# Include header deps.
-include $(HEADER_DEPS)