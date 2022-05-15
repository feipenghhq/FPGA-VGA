# ==================================================================================
# Makefile
# ==================================================================================


GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD 	 = $(shell pwd)

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

include $(GIT_ROOT)/rtl/video_daisy_system/makefile.video_daisy_system_fbsd.inc
VERILOG_SOURCES += $(VERILOG)
VERILOG_SOURCES += $(PWD)/sdr_sdram/sdr_parameters.vh
VERILOG_SOURCES += $(PWD)/sdr_sdram/sdr.v

VERILOG_SOURCES += $(PWD)/tb.sv
TOPLEVEL = video_daisy_system_fbsd_tb

MODULE 	 = test

# Macros for Micron SDRAM
COMPILE_ARGS += -Dden256Mb
COMPILE_ARGS += -Dsg6a
COMPILE_ARGS += -Dx16

# Include path
COMPILE_ARGS += -I$(PWD)/sdr_sdram
COMPILE_ARGS += -I$(GIT_ROOT)/rtl/common
COMPILE_ARGS += -I$(GIT_ROOT)/ip/sdram

DUMP ?= 0
ifeq ($(DUMP), 1)
	COMPILE_ARGS += -DDUMP
endif


# Other variable
export COCOTB_RESOLVE_X=RANDOM
export PYTHONPATH = $(GIT_ROOT)/cocotb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
