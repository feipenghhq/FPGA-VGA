/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/23/2022
 * ---------------------------------------------------------------
 * Mandbort Set using SRAM frame buffer
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module mandelbrot_framebuffer_sram #(
    parameter AVN_AW   = 19,
    parameter AVN_DW   = 16,
    parameter ITERW    = 16
) (
    // clock
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,
    input [ITERW-1:0]       max_iteration,
    input                   start,

    // vga interface
    output  [`R_SIZE-1:0]   vga_r,
    output  [`G_SIZE-1:0]   vga_g,
    output  [`B_SIZE-1:0]   vga_b,
    output                  vga_hsync,
    output                  vga_vsync,

    // the sram interface
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output [AVN_DW/8-1:0]   sram_be_n,
    output [AVN_AW-1:0]     sram_addr,
    inout  [AVN_DW-1:0]     sram_dq
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/

    logic                framebuffer_avn_waitrequest;
    logic [AVN_AW-1:0]   framebuffer_avn_address;
    logic [AVN_DW-1:0]   framebuffer_avn_writedata;
    logic                framebuffer_avn_write;

    logic                mandelbrot_avn_waitrequest;
    logic [AVN_AW-1:0]   mandelbrot_avn_address;
    logic [AVN_DW-1:0]   mandelbrot_avn_writedata;
    logic                mandelbrot_avn_write;

    logic                buffer_empty;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign framebuffer_avn_write = mandelbrot_avn_write;
    assign framebuffer_avn_writedata = mandelbrot_avn_writedata;
    assign framebuffer_avn_address = mandelbrot_avn_address;
    assign mandelbrot_avn_waitrequest = framebuffer_avn_waitrequest;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    mandelbrot_render #(
      .AVN_AW                     (AVN_AW),
      .AVN_DW                     (AVN_DW))
    u_mandelbrot_render
    (
      .clk                        (sys_clk),
      .rst                        (sys_rst),
      .max_iteration              (max_iteration),
      .start                      (start),
      .mandelbrot_avn_address     (mandelbrot_avn_address),
      .mandelbrot_avn_write       (mandelbrot_avn_write),
      .mandelbrot_avn_writedata   (mandelbrot_avn_writedata),
      .mandelbrot_avn_waitrequest (mandelbrot_avn_waitrequest)
    );

    vga_controller_sram
    #(
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW))
    u_vga_controller_sram
    (
     // Outputs
     .framebuffer_avn_readdata          (),
     .framebuffer_avn_readdatavalid     (),
     .framebuffer_avn_waitrequest       (framebuffer_avn_waitrequest),
     .sram_ce_n                         (sram_ce_n),
     .sram_oe_n                         (sram_oe_n),
     .sram_we_n                         (sram_we_n),
     .sram_be_n                         (sram_be_n),
     .sram_addr                         (sram_addr),
     .vga_r                             (vga_r),
     .vga_g                             (vga_g),
     .vga_b                             (vga_b),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     // Inouts
     .sram_dq                           (sram_dq),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .framebuffer_avn_read              (1'b0),
     .framebuffer_avn_write             (framebuffer_avn_write),
     .framebuffer_avn_address           (framebuffer_avn_address),
     .framebuffer_avn_byteenable        ({AVN_DW/8{1'b1}}),
     .framebuffer_avn_writedata         (framebuffer_avn_writedata));

endmodule