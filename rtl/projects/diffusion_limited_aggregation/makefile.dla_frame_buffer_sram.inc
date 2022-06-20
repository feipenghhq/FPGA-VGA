GIT_ROOT     = $(shell git rev-parse --show-toplevel)

SRAM         = $(GIT_ROOT)/ip/sram
COMMON       = $(GIT_ROOT)/rtl/common
VGA_CTRL     = $(GIT_ROOT)/rtl/vga/vga_controller
VIDEO_CORE   = $(GIT_ROOT)/rtl/vga/video_core
DLA          = $(GIT_ROOT)/rtl/projects/diffusion_limited_aggregation

VERILOG 	+= $(COMMON)/vga_dsync.sv
VERILOG 	+= $(COMMON)/vga_async_fifo.sv
VERILOG 	+= $(COMMON)/vga_fifo.sv
VERILOG 	+= $(COMMON)/vga_ram_1r1w.sv
VERILOG 	+= $(COMMON)/vga_avn_mux.sv

VERILOG 	+= $(VGA_CTRL)/vga_frame_counter.sv
VERILOG 	+= $(VGA_CTRL)/vga_sync.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_framebuffer_core.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_framebuffer.sv
VERILOG 	+= $(VGA_CTRL)/vga_controller_sram.sv

VERILOG     += $(DLA)/dla_lsfr.sv
VERILOG     += $(DLA)/dla_particle_check.sv
VERILOG     += $(DLA)/dla_particle_walk.sv
VERILOG     += $(DLA)/dla_simulate.sv
VERILOG     += $(DLA)/dla_vram_init.sv
VERILOG 	+= $(DLA)/dla_frame_buffer_sram.sv

VERILOG 	+= $(SRAM)/avalon_sram_controller.sv


