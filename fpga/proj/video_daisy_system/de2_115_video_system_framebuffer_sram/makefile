
#########################################################
# Makefile for project
#########################################################

GIT_ROOT = $(shell git rev-parse --show-toplevel)
PWD		 = $(shell pwd)

PROJECT  = video_daisy_system
TOP		 = de2_115_top

include $(GIT_ROOT)/rtl/projects/video_daisy_system/makefile.video_system_framebuffer_sram.inc
VERILOG  	+= $(PWD)/src/altpllvga.v
VERILOG  	+= $(PWD)/src/de2_115_top.sv
SEARCH   	+= $(GIT_ROOT)/rtl/include

SDC	     	+= $(PWD)/src/de2_115_top.sdc
PIN      	+= $(PWD)/src/de2_115_pin.tcl

include $(GIT_ROOT)/tools/quartus/makefile.nonqsys.mk

pre: $(OUT_DIR)
	cp -rfl $(GIT_ROOT)/utils/sprites/*.mem $(OUT_DIR)/.
