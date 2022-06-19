
#########################################################
# Makefile for project
#########################################################

GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD		 = $(shell pwd)

PROJECT  = video_daisy_system_linebuffer
TOP		 = de2_top

include $(GIT_ROOT)/rtl/projects/video_daisy_system/makefile.video_system_linebuffer.inc
VERILOG  	+= $(PWD)/src/altpllvga.v
VERILOG  	+= $(PWD)/src/de2_top.sv
DEFINE		+= VGA_640x400
SEARCH   	+= $(GIT_ROOT)/rtl/include
SDC	     	+= $(PWD)/src/de2_top.sdc
PIN      	+= $(PWD)/src/de2_pin.tcl

include $(GIT_ROOT)/tools/quartus/makefile.nonqsys.mk

pre: $(OUT_DIR)
	cp -rfl $(GIT_ROOT)/utils/sprites/*.mem $(OUT_DIR)/.