GIT_ROOT     = $(shell git rev-parse --show-toplevel)

COMMON       = $(GIT_ROOT)/rtl/common
VGA_CORE     = $(GIT_ROOT)/rtl/vga_core
VGA_CTRL     = $(GIT_ROOT)/rtl/vga_controller
VIDEO_CORE   = $(GIT_ROOT)/rtl/video_core
VIDEO_SYSTEM = $(GIT_ROOT)/rtl/video_daisy_system

VERILOG 	+= $(COMMON)/video_core_pipeline.sv
VERILOG 	+= $(COMMON)/video_data_pipeline.sv
VERILOG 	+= $(COMMON)/video_core_stages.sv
VERILOG 	+= $(COMMON)/vga_dsync.sv
VERILOG 	+= $(COMMON)/vga_async_fifo.sv
VERILOG 	+= $(COMMON)/vga_fifo.sv
VERILOG 	+= $(COMMON)/vga_avn_mux.sv

VERILOG 	+= $(VGA_CORE)/vga_frame_counter.sv
VERILOG 	+= $(VGA_CORE)/vga_sync.sv
VERILOG 	+= $(VGA_CORE)/vga_core_framebuffer.sv
VERILOG 	+= $(VGA_CORE)/vga_core_framebuffer_1rw.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_sram.sv

VERILOG 	+= $(VIDEO_CORE)/dummy_core/video_dummy_core.sv
VERILOG 	+= $(VIDEO_CORE)/bar_core/video_bar_core.sv
VERILOG 	+= $(VIDEO_CORE)/bar_core/video_bar_gen.sv
VERILOG 	+= $(VIDEO_CORE)/rgb2gray_core/video_rgb2gray_core.sv
VERILOG 	+= $(VIDEO_CORE)/rgb2gray_core/video_rgb2gray_gen.sv
VERILOG 	+= $(VIDEO_CORE)/sprite_core/video_sprite_core.sv
VERILOG 	+= $(VIDEO_CORE)/sprite_core/video_sprite_gen.sv
VERILOG 	+= $(VIDEO_CORE)/sprite_core/video_sprite_ram.sv
VERILOG 	+= $(VIDEO_CORE)/sprite_core/video_sprite_animation_core.sv
VERILOG 	+= $(VIDEO_CORE)/sprite_core/video_sprite_animation_gen.sv

VERILOG 	+= $(VIDEO_SYSTEM)/video_daisy_core.sv
VERILOG 	+= $(VIDEO_SYSTEM)/video_system_framebuffer_sram.sv

VERILOG 	+= $(GIT_ROOT)/ip/sram/avalon_sram_controller.sv