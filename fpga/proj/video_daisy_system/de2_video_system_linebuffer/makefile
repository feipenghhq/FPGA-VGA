
#########################################################
# Makefile for project
#########################################################

GIT_ROOT = $(shell git rev-parse --show-toplevel)
OUT_DIR  = $(shell pwd)/quartus
PWD		 = $(shell pwd)

PROJECT  = video_daisy_system_linebuffer
TOP		 = de2_top

include $(GIT_ROOT)/rtl/video_daisy_system/makefile.video_system_linebuffer.inc
VERILOG  	+= $(PWD)/src/altpllvga.v
VERILOG  	+= $(PWD)/src/de2_top.sv

SEARCH   	+= $(GIT_ROOT)/rtl/common
SDC	     	+= $(PWD)/src/de2_top.sdc
PIN      	+= $(PWD)/src/DE2_pin_assignment.tcl

include $(GIT_ROOT)/fpga/scripts/makefile.intel.noqsys.mk

pre: $(OUT_DIR)
	cp -rfl $(GIT_ROOT)/utils/sprites/*.mem $(OUT_DIR)/.