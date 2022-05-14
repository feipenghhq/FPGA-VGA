# ==================================================================================
# Makefile
# ==================================================================================


GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD 	 = $(shell pwd)

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

include $(GIT_ROOT)/rtl/video_daisy_system/makefile.video_daisy_system_fbs.inc
VERILOG_SOURCES += $(VERILOG)
VERILOG_SOURCES += tb.sv
TOPLEVEL = video_daisy_system_fbs_tb

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
