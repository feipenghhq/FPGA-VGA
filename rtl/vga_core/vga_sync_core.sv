/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA sync core
 *  - VGA sync logic
 *  - Line buffer
 * ---------------------------------------------------------------
 */


module vga_sync_core #(
    parameter RSIZE = 4,
    parameter GSIZE = 4,
    parameter BSIZE = 4,
    parameter RGB_SIZE  = 12,
    parameter START_DELAY = 12
) (
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    // line buffer source
    input [RGB_SIZE:0]      line_buffer_data,
    input                   line_buffer_vld,
    output                  line_buffer_rdy,

    // vga interface
    output [RSIZE-1:0]      vga_r,
    output [GSIZE-1:0]      vga_g,
    output [BSIZE-1:0]      vga_b,

    output                  vga_hsync,
    output                  vga_vsync
);

    /*AUTOREG*/

    /*AUTOWIRE*/

    logic               vga_src_rdy;
    logic [RGB_SIZE:0]  vga_src_rgb;
    logic               vga_src_vld;

    /* vga_line_buffer AUTO_TEMPLATE (
        // from source
        .src_rst    (sys_rst),
        .src_clk    (sys_clk),
        .src_data   (line_buffer_data),
        .src_vld    (line_buffer_vld),
        .src_rdy    (line_buffer_rdy),
        // to sink
        .snk_rst    (pixel_rst),
        .snk_clk    (pixel_clk),
        .snk_data   (vga_src_rgb[]),
        .snk_vld    (vga_src_vld),
        .snk_rdy    (vga_src_rdy),
    );
    */
    vga_line_buffer
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RGB_SIZE                         (RGB_SIZE))
    u_vga_line_buffer
    (/*AUTOINST*/
     // Outputs
     .src_rdy                           (line_buffer_rdy),       // Templated
     .snk_data                          (vga_src_rgb[RGB_SIZE:0]), // Templated
     .snk_vld                           (vga_src_vld),           // Templated
     // Inputs
     .src_rst                           (sys_rst),               // Templated
     .src_clk                           (sys_clk),               // Templated
     .src_data                          (line_buffer_data),      // Templated
     .src_vld                           (line_buffer_vld),       // Templated
     .snk_rst                           (pixel_rst),             // Templated
     .snk_clk                           (pixel_clk),             // Templated
     .snk_rdy                           (vga_src_rdy));           // Templated

    vga_sync
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE),
      .START_DELAY                      (START_DELAY))
    u_vga_sync
    (/*AUTOINST*/
     // Outputs
     .vga_src_rdy                       (vga_src_rdy),
     .vga_r                             (vga_r[RSIZE-1:0]),
     .vga_g                             (vga_g[GSIZE-1:0]),
     .vga_b                             (vga_b[BSIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_src_rgb                       (vga_src_rgb[RGB_SIZE:0]),
     .vga_src_vld                       (vga_src_vld));

endmodule
