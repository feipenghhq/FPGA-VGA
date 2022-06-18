GIT_ROOT     = $(shell git rev-parse --show-toplevel)

SRAM         = $(GIT_ROOT)/ip/sram
COMMON       = $(GIT_ROOT)/rtl/common
VGA_CTRL     = $(GIT_ROOT)/rtl/vga/vga_controller
VIDEO_CORE   = $(GIT_ROOT)/rtl/vga/video_core
VIDEO_SYSTEM = $(GIT_ROOT)/rtl/projects/video_daisy_system

VERILOG 	+= $(SRAM)/avalon_sram_controller.sv

VERILOG 	+= $(COMMON)/vga_dsync.sv
VERILOG 	+= $(COMMON)/vga_async_fifo.sv
VERILOG 	+= $(COMMON)/vga_fifo.sv
VERILOG 	+= $(COMMON)/vga_ram_1r1w.sv
VERILOG 	+= $(COMMON)/vga_avn_mux.sv

VERILOG 	+= $(VGA_CTRL)/vga_sync.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_framebuffer.sv
VERILOG 	+= $(VGA_CTRL)/vga_frame_counter.sv

VERILOG 	+= $(VGA_CTRL)/vga_controller_framebuffer_1rw.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_sram.sv

VERILOG 	+= $(VIDEO_CORE)/video_bar_core.sv
VERILOG 	+= $(VIDEO_CORE)/video_rgb2gray_core.sv
VERILOG 	+= $(VIDEO_CORE)/video_sprite_core.sv
VERILOG 	+= $(VIDEO_CORE)/video_daisy_core.sv

VERILOG 	+= $(VIDEO_CORE)/video_sprite_animation_core.sv
VERILOG 	+= $(VIDEO_SYSTEM)/video_system_framebuffer_sram.sv
