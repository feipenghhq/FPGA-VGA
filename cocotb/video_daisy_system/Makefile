# ==================================================================================
# Makefile
# ==================================================================================




GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD 	 = $(shell pwd)

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

COMMON			= $(GIT_ROOT)/rtl/common
VGA_CORE 		= $(GIT_ROOT)/rtl/vga_core
VIDEO_SYSTEM 	= $(GIT_ROOT)/rtl/video_system
VIDEO_CORE		= $(GIT_ROOT)/rtl/video_core

VERILOG_SOURCES += $(VGA_CORE)/vga_async_fifo.sv
VERILOG_SOURCES += $(VGA_CORE)/vga_dsync.sv
VERILOG_SOURCES += $(VGA_CORE)/vga_frame_counter.sv
VERILOG_SOURCES += $(VGA_CORE)/vga_line_buffer.sv
VERILOG_SOURCES += $(VGA_CORE)/vga_sync_core.sv
VERILOG_SOURCES += $(VGA_CORE)/vga_sync.sv

VERILOG_SOURCES += $(VIDEO_SYSTEM)/video_daisy_system.sv

VERILOG_SOURCES += $(COMMON)/video_core_pipeline.sv

VERILOG_SOURCES += $(VIDEO_CORE)/bar_core/video_bar_core.sv
VERILOG_SOURCES += $(VIDEO_CORE)/bar_core/video_bar_gen.sv

TOPLEVEL = video_daisy_system

MODULE 	 = test

DUMP ?= 0
COVR ?= 0

ifeq ($(SIM),verilator)
EXTRA_ARGS += -I$(GIT_ROOT)/rtl/common
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
