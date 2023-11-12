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
	util/text_rom_gen.py data/text.mem

# fix the dump file thing
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

.PHONY: clean
clean:
	rm -rf obj/*
	rm -rf vcd/*
	rm -rf vivado.log
