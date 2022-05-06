
#########################################################
# Makefile for project
#########################################################

GIT_ROOT = $(shell git rev-parse --show-toplevel)
OUT_DIR  = $(shell pwd)/quartus
PWD		 = $(shell pwd)

PROJECT  = video_daisy_system
TOP		 = de2_top

COMMON			= $(GIT_ROOT)/rtl/common
VGA_CORE 		= $(GIT_ROOT)/rtl/vga_core
VIDEO_SYSTEM 	= $(GIT_ROOT)/rtl/video_system
VIDEO_CORE		= $(GIT_ROOT)/rtl/video_core

VERILOG 	+= $(VGA_CORE)/vga_async_fifo.sv
VERILOG 	+= $(VGA_CORE)/vga_dsync.sv
VERILOG 	+= $(VGA_CORE)/vga_frame_counter.sv
VERILOG 	+= $(VGA_CORE)/vga_line_buffer.sv
VERILOG 	+= $(VGA_CORE)/vga_sync_core.sv
VERILOG 	+= $(VGA_CORE)/vga_sync.sv
VERILOG 	+= $(COMMON)/video_core_pipeline.sv
VERILOG 	+= $(COMMON)/video_core_stages.sv
VERILOG 	+= $(VIDEO_CORE)/bar_core/video_bar_core.sv
VERILOG 	+= $(VIDEO_CORE)/bar_core/video_bar_gen.sv
VERILOG 	+= $(VIDEO_CORE)/rgb2gray_core/video_rgb2gray_core.sv
VERILOG 	+= $(VIDEO_CORE)/rgb2gray_core/video_rgb2gray_gen.sv
VERILOG 	+= $(VIDEO_SYSTEM)/video_daisy_system.sv
VERILOG 	+= $(VIDEO_SYSTEM)/vidao_daisy_system_avalon_control.sv

VERILOG  	+= $(GIT_ROOT)/fpga/common/rtl/altpllvga.v
VERILOG  	+= $(PWD)/src/de2_top.sv

SEARCH   	+= $(GIT_ROOT)/rtl/common

SDC	     	+= $(PWD)/src/de2_top.sdc
PIN      	+= $(PWD)/src/DE2_pin_assignment.tcl

include $(GIT_ROOT)/fpga/scripts/makefile.intel.noqsys.mk
