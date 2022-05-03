
#########################################################
# Makefile for project
#########################################################

GIT_ROOT = $(shell git rev-parse --show-toplevel)
OUT_DIR  = $(shell pwd)/quartus
PWD		 = $(shell pwd)

PROJECT  = video_daisy_system
TOP		 = de2_top

VERILOG  += $(PWD)/src/de2_top.sv

SEARCH   += $(GIT_ROOT)/rtl/vga

SDC	     += $(PWD)/src/de2_top.sdc
PIN      += $(PWD)/src/DE2_pin_assignment.tcl

QSYS		= video_daisy_system_top
QSYS_DIR 	= $(PWD)/src
QSYS_SEARCH = $(GIT_ROOT)/rtl/video_system/*/**

include $(GIT_ROOT)/fpga/scripts/makefile.intel.mk
