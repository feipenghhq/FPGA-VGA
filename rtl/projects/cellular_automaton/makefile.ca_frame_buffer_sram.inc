GIT_ROOT     = $(shell git rev-parse --show-toplevel)

SRAM         = $(GIT_ROOT)/ip/sram
COMMON       = $(GIT_ROOT)/rtl/common
VGA_CTRL     = $(GIT_ROOT)/rtl/vga/vga_controller
VIDEO_CORE   = $(GIT_ROOT)/rtl/vga/video_core
CA           = $(GIT_ROOT)/rtl/projects/cellular_automaton

VERILOG 	+= $(SRAM)/avalon_sram_controller.sv

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

VERILOG 	+= $(CA)/cellular_automaton_core.sv
VERILOG 	+= $(CA)/ca_frame_buffer_sram.sv
