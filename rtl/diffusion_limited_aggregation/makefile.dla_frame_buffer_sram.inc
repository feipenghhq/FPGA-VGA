GIT_ROOT     = $(shell git rev-parse --show-toplevel)

COMMON       = $(GIT_ROOT)/rtl/common
VGA_CORE     = $(GIT_ROOT)/rtl/vga_core
VIDEO_CORE   = $(GIT_ROOT)/rtl/video_core
VIDEO_SYSTEM = $(GIT_ROOT)/rtl/video_daisy_system
DLA           = $(GIT_ROOT)/rtl/diffusion_limited_aggregation

VERILOG 	+= $(COMMON)/video_core_pipeline.sv
VERILOG 	+= $(COMMON)/video_data_pipeline.sv
VERILOG 	+= $(COMMON)/video_core_stages.sv
VERILOG 	+= $(COMMON)/vga_dsync.sv
VERILOG 	+= $(COMMON)/vga_async_fifo.sv

VERILOG 	+= $(VGA_CORE)/vga_frame_counter.sv
VERILOG 	+= $(VGA_CORE)/vga_frame_buffer_sram.sv
VERILOG 	+= $(VGA_CORE)/vga_core_frame_buffer_sram.sv

VERILOG     += $(DLA)/dla_lsfr.sv
VERILOG     += $(DLA)/dla_particle_check.sv
VERILOG     += $(DLA)/dla_particle_walk.sv
VERILOG     += $(DLA)/dla_simulate.sv
VERILOG     += $(DLA)/dla_vram_init.sv
VERILOG 	+= $(DLA)/dla_frame_buffer_sram.sv

VERILOG 	+= $(GIT_ROOT)/ip/sram/avalon_sram_controller.sv


