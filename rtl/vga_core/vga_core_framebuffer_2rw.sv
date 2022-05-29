/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/29/2022
 * ---------------------------------------------------------------
 * VGA core frame buffer wrapper with 2 read/write ports
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_core_framebuffer_2rw #(
    parameter RSIZE         = 4,
    parameter GSIZE         = 4,
    parameter BSIZE         = 4,
    parameter RGB_SIZE      = 12,
    parameter AVN_AW        = 18,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    parameter BUF_SIZE      = 16,   // prefetch bufer size
    parameter START_DELAY   = 12
)(
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // vga interface
    output [RSIZE-1:0]      vga_r,
    output [GSIZE-1:0]      vga_g,
    output [BSIZE-1:0]      vga_b,
    output reg              vga_hsync,
    output reg              vga_vsync,

    // source avalon interface
    input                   framebuffer_avn_read,
    input                   framebuffer_avn_write,
    input  [AVN_AW-1:0]     framebuffer_avn_address,
    input  [AVN_DW-1:0]     framebuffer_avn_writedata,
    input [AVN_DW/8-1:0]    framebuffer_avn_byteenable,
    output [AVN_DW-1:0]     framebuffer_avn_readdata,
    output                  framebuffer_avn_readdatavalid,
    output                  framebuffer_avn_waitrequest,

    // memory port 1 avalon interface - sys_clk
    // used by the pixel processing logic
    output                  pro_avn_read,
    output                  pro_avn_write,
    output [AVN_AW-1:0]     pro_avn_address,
    output [AVN_DW-1:0]     pro_avn_writedata,
    output [AVN_DW/8-1:0]   pro_avn_byteenable,
    input  [AVN_DW-1:0]     pro_avn_readdata,
    input                   pro_avn_readdatavalid,
    input                   pro_avn_waitrequest,

    // memory port 2 avalon interface - sys_clk
    // used by the vga sync logic
    output                  pxl_avn_read,
    output                  pxl_avn_write,
    output [AVN_AW-1:0]     pxl_avn_address,
    output [AVN_DW-1:0]     pxl_avn_writedata,
    output [AVN_DW/8-1:0]   pxl_avn_byteenable,
    input  [AVN_DW-1:0]     pxl_avn_readdata,
    input                   pxl_avn_readdatavalid,
    input                   pxl_avn_waitrequest
);

    vga_core_framebuffer
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE),
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .BUF_SIZE                         (BUF_SIZE),
      .START_DELAY                      (START_DELAY))
    u_vga_core_framebuffer
    (/*AUTOINST*/
     // Outputs
     .vga_r                             (vga_r[RSIZE-1:0]),
     .vga_g                             (vga_g[GSIZE-1:0]),
     .vga_b                             (vga_b[BSIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .framebuffer_avn_readdata          (framebuffer_avn_readdata[AVN_DW-1:0]),
     .framebuffer_avn_readdatavalid     (framebuffer_avn_readdatavalid),
     .framebuffer_avn_waitrequest       (framebuffer_avn_waitrequest),
     .pro_avn_read                      (pro_avn_read),
     .pro_avn_write                     (pro_avn_write),
     .pro_avn_address                   (pro_avn_address[AVN_AW-1:0]),
     .pro_avn_writedata                 (pro_avn_writedata[AVN_DW-1:0]),
     .pro_avn_byteenable                (pro_avn_byteenable[AVN_DW/8-1:0]),
     .pxl_avn_read                      (pxl_avn_read),
     .pxl_avn_write                     (pxl_avn_write),
     .pxl_avn_address                   (pxl_avn_address[AVN_AW-1:0]),
     .pxl_avn_writedata                 (pxl_avn_writedata[AVN_DW-1:0]),
     .pxl_avn_byteenable                (pxl_avn_byteenable[AVN_DW/8-1:0]),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .framebuffer_avn_read              (framebuffer_avn_read),
     .framebuffer_avn_write             (framebuffer_avn_write),
     .framebuffer_avn_address           (framebuffer_avn_address[AVN_AW-1:0]),
     .framebuffer_avn_writedata         (framebuffer_avn_writedata[AVN_DW-1:0]),
     .framebuffer_avn_byteenable        (framebuffer_avn_byteenable[AVN_DW/8-1:0]),
     .pro_avn_readdata                  (pro_avn_readdata[AVN_DW-1:0]),
     .pro_avn_readdatavalid             (pro_avn_readdatavalid),
     .pro_avn_waitrequest               (pro_avn_waitrequest),
     .pxl_avn_readdata                  (pxl_avn_readdata[AVN_DW-1:0]),
     .pxl_avn_readdatavalid             (pxl_avn_readdatavalid),
     .pxl_avn_waitrequest               (pxl_avn_waitrequest));

endmodule
