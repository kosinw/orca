SOURCES := 										\
	hdl/										\
	obj/										\
	xdc/										\
	sim/										\
	ip/											\

.PHONY: flash
flash:
	openFPGALoader -b arty_s7_50 obj/final.bit

.PHONY: build
build:
	./remote/r.py build.py build.tcl $(SOURCES)

.PHONY: clean
clean:
	rm -rf obj/*
	rm -rf vcd/*
	rm -rf vivado.log
