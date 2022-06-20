/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/27/2022
 * ---------------------------------------------------------------
 * VGA core with frame buffe
 * ---------------------------------------------------------------
 *
 * The frame buffer is generally a 2 RW ports memory.
 * It holds the pixel for the entire frame displayed on the screen.
 *
 * 1 RW port is accessed by the upstream pixel processing logic.
 * 1 RW port is accessed by the vga core to retrieve the pixel data.
 *
 * This module is a wrapper for the memory, it provides 2 avalon
 * interface to access the actual memory so the memory can be
 * build with different memory such as FPGA onchip memory,
 * off-chip sram or off-chip sdram.
 *
 * On the VGA read side, we use an asynchronous FIFO as a prefetch
 * buffer. The pixel is prefetched from the memory into the fifo
 * to hide the latency of the memory in case the memory needs several
 * clock cycles to return the data.
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_controller_framebuffer #(
    parameter AVN_AW        = 19,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    parameter BUF_SIZE      = 16,   // prefetch bufer size
    parameter START_DELAY   = 10
)(
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // vga interface
    output [`R_SIZE-1:0]    vga_r,
    output [`G_SIZE-1:0]    vga_g,
    output [`B_SIZE-1:0]    vga_b,
    output                  vga_hsync,
    output                  vga_vsync,

    // source avalon interface
    input                   framebuffer_avn_read,
    input                   framebuffer_avn_write,
    input  [AVN_AW-1:0]     framebuffer_avn_address,
    input  [AVN_DW-1:0]     framebuffer_avn_writedata,
    input  [AVN_DW/8-1:0]   framebuffer_avn_byteenable,
    output [AVN_DW-1:0]     framebuffer_avn_readdata,
    output                  framebuffer_avn_readdatavalid,
    output                  framebuffer_avn_waitrequest,

    // avalon interface to vram
    output                  vram_avn_read,
    output                  vram_avn_write,
    output [AVN_AW-1:0]     vram_avn_address,
    output [AVN_DW-1:0]     vram_avn_writedata,
    output [AVN_DW/8-1:0]   vram_avn_byteenable,
    input  [AVN_DW-1:0]     vram_avn_readdata,
    input                   vram_avn_readdatavalid,
    input                   vram_avn_waitrequest
);

    localparam              MAX_READ = 4;

    logic                   vga_avn_read;
    logic                   vga_avn_write;
    logic [AVN_AW-1:0]      vga_avn_address;
    logic [AVN_DW-1:0]      vga_avn_writedata;
    logic [AVN_DW/8-1:0]    vga_avn_byteenable;
    logic [AVN_DW-1:0]      vga_avn_readdata;
    logic                   vga_avn_readdatavalid;
    logic                   vga_avn_waitrequest;

    vga_controller_framebuffer_core
    #(
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .BUF_SIZE                         (BUF_SIZE),
      .START_DELAY                      (START_DELAY),
      .MAX_READ                         (MAX_READ))
    u_vga_controller_framebuffer_core
    (
      // clock and reset
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_r                             (vga_r[`R_SIZE-1:0]),
     .vga_g                             (vga_g[`G_SIZE-1:0]),
     .vga_b                             (vga_b[`B_SIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .vga_avn_read                      (vga_avn_read),
     .vga_avn_write                     (vga_avn_write),
     .vga_avn_address                   (vga_avn_address[AVN_AW-1:0]),
     .vga_avn_writedata                 (vga_avn_writedata[AVN_DW-1:0]),
     .vga_avn_byteenable                (vga_avn_byteenable[AVN_DW/8-1:0]),
     .vga_avn_readdata                  (vga_avn_readdata[AVN_DW-1:0]),
     .vga_avn_readdatavalid             (vga_avn_readdatavalid),
     .vga_avn_waitrequest               (vga_avn_waitrequest));

    vga_avn_mux
    #(
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .MAX_READ                         (MAX_READ))
    u_vga_avn_mux
    (
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .port1_avn_readdata                (framebuffer_avn_readdata[AVN_DW-1:0]),
     .port1_avn_readdatavalid           (framebuffer_avn_readdatavalid),
     .port1_avn_waitrequest             (framebuffer_avn_waitrequest),
     .port1_avn_read                    (framebuffer_avn_read),
     .port1_avn_write                   (framebuffer_avn_write),
     .port1_avn_address                 (framebuffer_avn_address[AVN_AW-1:0]),
     .port1_avn_writedata               (framebuffer_avn_writedata[AVN_DW-1:0]),
     .port1_avn_byteenable              (framebuffer_avn_byteenable[AVN_DW/8-1:0]),
     .port2_avn_readdata                (vga_avn_readdata[AVN_DW-1:0]),
     .port2_avn_readdatavalid           (vga_avn_readdatavalid),
     .port2_avn_waitrequest             (vga_avn_waitrequest),
     .port2_avn_read                    (vga_avn_read),
     .port2_avn_write                   (vga_avn_write),
     .port2_avn_address                 (vga_avn_address[AVN_AW-1:0]),
     .port2_avn_writedata               (vga_avn_writedata[AVN_DW-1:0]),
     .port2_avn_byteenable              (vga_avn_byteenable[AVN_DW/8-1:0]),
     .out_avn_readdata                  (vram_avn_readdata[AVN_DW-1:0]),
     .out_avn_read                      (vram_avn_read),
     .out_avn_write                     (vram_avn_write),
     .out_avn_address                   (vram_avn_address[AVN_AW-1:0]),
     .out_avn_writedata                 (vram_avn_writedata[AVN_DW-1:0]),
     .out_avn_byteenable                (vram_avn_byteenable[AVN_DW/8-1:0]),
     .out_avn_readdatavalid             (vram_avn_readdatavalid),
     .out_avn_waitrequest               (vram_avn_waitrequest));

endmodule

// Local Variables:
// verilog-library-flags:("-y ../common/ ")
// End:
