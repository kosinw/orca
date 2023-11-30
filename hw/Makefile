SOURCES := 										\
	hdl/										\
	obj/										\
	xdc/										\
	sim/										\
	ip/											\
	data/										\
	build.tcl									\

.PHONY: flash
flash:
	openFPGALoader -b arty_s7_50 obj/final.bit

.PHONY: build
build:
	./remote/r.py build.py $(SOURCES)

.PHONY: font
font:
	util/font_gen.py util/ibm-vga-8x16.fnt data/font.mem

.PHONY: text
text:
	util/text_gen.py data/text_codepoint.mem data/text_attribute.mem

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
		hdl/xilinx_true_dual_port_read_first_2_clock_ram.v
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

.PHONY: riscv_decode_tb
riscv_decode_tb:
	iverilog -g2012 -o 					\
		vcd/riscv_decode.out			\
		sim/riscv_decode_tb.sv			\
		hdl/riscv/riscv_types.sv		\
		hdl/riscv/riscv_instructions.sv	\
		hdl/riscv/riscv_decode.sv

	vvp vcd/riscv_decode.out
	open vcd/riscv_decode.vcd

.PHONY: clean
clean:
	rm -rf obj/*
	rm -rf vcd/*
	rm -rf vivado.log
