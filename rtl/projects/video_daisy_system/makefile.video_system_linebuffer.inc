GIT_ROOT     = $(shell git rev-parse --show-toplevel)

COMMON       = $(GIT_ROOT)/rtl/common
VGA_CTRL     = $(GIT_ROOT)/rtl/vga/vga_controller
VIDEO_CORE   = $(GIT_ROOT)/rtl/vga/video_core
VIDEO_SYSTEM = $(GIT_ROOT)/rtl/projects/video_daisy_system

VERILOG 	+= $(COMMON)/vga_dsync.sv
VERILOG 	+= $(COMMON)/vga_async_fifo.sv
VERILOG 	+= $(COMMON)/vga_ram_1r1w.sv

VERILOG 	+= $(VGA_CTRL)/vga_sync.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_linebuffer.sv
VERILOG 	+= $(VGA_CTRL)/vga_frame_counter.sv

VERILOG 	+= $(VIDEO_CORE)/video_bar_core.sv
VERILOG 	+= $(VIDEO_CORE)/video_rgb2gray_core.sv
VERILOG 	+= $(VIDEO_CORE)/video_sprite_core.sv
VERILOG 	+= $(VIDEO_CORE)/video_daisy_core.sv

VERILOG 	+= $(VIDEO_CORE)/video_sprite_animation_core.sv


VERILOG 	+= $(VIDEO_SYSTEM)/video_system_linebuffer.sv
