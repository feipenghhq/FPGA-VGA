GIT_ROOT     = $(shell git rev-parse --show-toplevel)

SRAM         = $(GIT_ROOT)/ip/sram
COMMON       = $(GIT_ROOT)/rtl/common
VGA_CTRL     = $(GIT_ROOT)/rtl/vga/vga_controller
VIDEO_CORE   = $(GIT_ROOT)/rtl/vga/video_core
MANDEL       = $(GIT_ROOT)/rtl/projects/mandelbrot_set

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

VERILOG 	+= $(MANDEL)/mandelbrot_multiplier.sv
VERILOG 	+= $(MANDEL)/mandelbrot_solver.sv
VERILOG 	+= $(MANDEL)/mandelbrot_engine.sv
VERILOG 	+= $(MANDEL)/mandelbrot_coloring.sv
VERILOG 	+= $(MANDEL)/mandelbrot_engine_colored.sv
VERILOG 	+= $(MANDEL)/mandelbrot_render.sv
VERILOG 	+= $(MANDEL)/mandelbrot_framebuffer_sram.sv
