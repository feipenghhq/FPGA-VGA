# ==================================================================================
# Makefile
# ==================================================================================


GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD 	 = $(shell pwd)

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

include $(GIT_ROOT)/rtl/projects/video_daisy_system/makefile.video_system_linebuffer.inc
VERILOG_SOURCES += $(VERILOG)
TOPLEVEL = video_system_linebuffer

MODULE 	 = test

DUMP ?= 0
COVR ?= 0
LINT ?= 0


ifeq ($(SIM),verilator)
EXTRA_ARGS += -I$(GIT_ROOT)/rtl/include
ifeq ($(COVR), 1)
	EXTRA_ARGS += --coverage
endif
ifeq ($(DUMP), 1)
	EXTRA_ARGS += --trace-fst --trace-structs
endif
ifeq ($(LINT), 1)
	EXTRA_ARGS += --lint-only
endif
endif

# Other variable
export COCOTB_RESOLVE_X=RANDOM
export PYTHONPATH = $(GIT_ROOT)/cocotb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
