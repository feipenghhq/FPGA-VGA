# ==================================================================================
# Makefile
# ==================================================================================


GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD 	 = $(shell pwd)

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

include $(GIT_ROOT)/rtl/projects/video_daisy_system/makefile.video_system_framebuffer_sram.inc
VERILOG_SOURCES += $(VERILOG)
VERILOG_SOURCES += tb.sv
TOPLEVEL = video_system_frame_buffer_sram_tb

MODULE 	 = test

DUMP ?= 0
COVR ?= 0

ifeq ($(SIM),verilator)
EXTRA_ARGS += -I$(GIT_ROOT)/rtl/include
EXTRA_ARGS += -DVGA_640x400
ifeq ($(COVR), 1)
	EXTRA_ARGS += --coverage
endif
ifeq ($(DUMP), 1)
	EXTRA_ARGS += --trace-fst --trace-structs
endif
endif

# Other variable
export COCOTB_RESOLVE_X=RANDOM
export PYTHONPATH = $(GIT_ROOT)/cocotb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
