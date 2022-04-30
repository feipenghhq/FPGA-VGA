
#########################################################
# Makefile for project
#########################################################

GIT_ROOT = $(shell git rev-parse --show-toplevel)
OUT_DIR  = $(shell pwd)/quartus
PWD		 = $(shell pwd)

PROJECT  = bar_test_demo
TOP		 = de2_top

VERILOG  += $(PWD)/src/de2_top.sv
VERILOG  += $(GIT_ROOT)/fpga/common/rtl/altpll25mhz.v
VERILOG  += $(GIT_ROOT)/rtl/vga/rtl/vga_sync.sv
VERILOG  += $(GIT_ROOT)/rtl/demo/bar_test_demo/bar_pattern_gen.sv
VERILOG  += $(GIT_ROOT)/rtl/demo/bar_test_demo/bar_test_demo.sv

SEARCH   += $(GIT_ROOT)/rtl/vga

SDC	     += $(PWD)/src/bar_test_demo.sdc
PIN      += $(PWD)/src/DE2_pin_assignment.tcl

include $(GIT_ROOT)/fpga/scripts/makefile.intel.noqsys.mk
