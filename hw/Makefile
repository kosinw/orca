SOURCES := 										\
	hdl/										\
	obj/										\
	xdc/										\
	sim/										\
	ip/											\
	data/										\

.PHONY: all
all: build flash

.PHONY: flash
flash:
	openFPGALoader -b arty_s7_50 obj/final.bit

.PHONY: build
build:
	rm -f build.py
	cp bc/build.py build.py
	./remote/r.py build.py build.tcl $(SOURCES)

.PHONY: remote_tb
remote_tb:
	rm -f build.py
	cp bc/sim.py build.py
	./remote/r.py build.py xsim_run.tcl $(SOURCES)
	rm dump.tar.gz
	mv dump.vcd vcd/remote_tb.vcd
	open vcd/remote_tb.vcd

.PHONY: font
font:
	util/font.py data/ibm-vga-8x16.fnt data/font.mem

.PHONY: text
text:
	util/text.py data/initial_video_bram.mem

.PHONY: program
program:
	util/program.py data/program.bin data/program.mem

.PHONY: video_tb
video_tb:
	iverilog -g2012 -o \
	 	vcd/video_controller.out 				\
		sim/video_controller_tb.sv 				\
		hdl/attribute_brom.sv	   				\
		hdl/font_brom.sv 						\
		hdl/pipeline.sv 						\
		hdl/video_bram.sv 						\
		hdl/video_controller.sv					\
		hdl/video_sig_gen.sv					\
		hdl/xilinx_single_port_ram_read_first.v	\
		hdl/xilinx_true_dual_port_read_first_byte_write_2_clock_ram.v
	vvp vcd/video_controller.out
	open vcd/video_controller.vcd

.PHONY: ps2_rx_tb
ps2_rx_tb:
	iverilog -g2012 -o 			\
		vcd/ps2_rx.out			\
		sim/ps2_rx_tb.sv		\
		hdl/ps2_rx.sv			\
		hdl/synchronizer.sv		\
		hdl/debouncer.sv
	vvp vcd/ps2_rx.out
	open vcd/ps2_rx.vcd

.PHONY: decode_tb
decode_tb:
	iverilog -g2012 -o 					\
		vcd/riscv_decode.out			\
		sim/riscv_decode_tb.sv			\
		hdl/riscv_constants.sv			\
		hdl/riscv_decode.sv
	vvp vcd/riscv_decode.out
	open vcd/riscv_decode.vcd

.PHONY: core_tb
core_tb:
	iverilog -g2012 -o 					\
		vcd/riscv_core.out				\
		sim/riscv_core_tb.sv			\
		hdl/riscv_constants.sv			\
		hdl/riscv_alu.sv				\
		hdl/riscv_decode.sv				\
		hdl/pipeline2.sv				\
		hdl/riscv_memory_iface.sv		\
		hdl/riscv_regfile.sv			\
		hdl/riscv_core.sv
	vvp vcd/riscv_core.out
	open vcd/riscv_core.vcd

.PHONY: alu_tb
alu_tb:
	iverilog -g2012 -o 				\
		vcd/riscv_alu.out			\
		sim/riscv_alu_tb.sv			\
		hdl/riscv_constants.sv		\
		hdl/riscv_alu.sv
	vvp vcd/riscv_alu.out
	open vcd/riscv_alu.vcd

.PHONY: clean
clean:
	rm -rf obj/*
	rm -rf vcd/*
	rm -rf vivado.log
