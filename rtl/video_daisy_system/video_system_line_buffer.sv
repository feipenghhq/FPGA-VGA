/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Version 05/15/2022:  Redeisgned the module
 * ---------------------------------------------------------------
 * VGA display system using line buffer
 * ---------------------------------------------------------------
 */


`include "vga.svh"

module video_system_line_buffer #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
) (
    // clock
    input                   pixel_clk,
    input                   pixel_rst,
    input                   sys_clk,
    input                   sys_rst,

    // vga interface
    output  [RSIZE-1:0]     vga_r,
    output  [GSIZE-1:0]     vga_g,
    output  [BSIZE-1:0]     vga_b,
    output                  vga_hsync,
    output                  vga_vsync,

    // video bar core avalon insterface
    input                   avs_video_bar_core_address,
    input                   avs_video_bar_core_write,
    input [31:0]            avs_video_bar_core_writedata,

    input [10:0]            avs_video_sprite_core_address,
    input                   avs_video_sprite_core_write,
    input [31:0]            avs_video_sprite_core_writedata,

    input [12:0]            avs_pacman_core_address,
    input                   avs_pacman_core_write,
    input [31:0]            avs_pacman_core_writedata,

    input                   avs_video_rgb2gray_core_address,
    input                   avs_video_rgb2gray_core_write,
    input [31:0]            avs_video_rgb2gray_core_writedata
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/

    vga_fc_t                daisy_system_fc;
    logic [RGB_SIZE-1:0]    daisy_system_rgb;
    logic [RGB_SIZE:0]      daisy_system_data;
    logic                   daisy_system_vld;
    logic                   daisy_system_rdy;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign daisy_system_data[RGB_SIZE]     = daisy_system_fc.frame_start;
    assign daisy_system_data[RGB_SIZE-1:0] = daisy_system_rgb;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    video_daisy_core
    #(
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_video_daisy_core
    (/*AUTOINST*/
     // Interfaces
     .daisy_system_fc                   (daisy_system_fc),
     // Outputs
     .daisy_system_rgb                  (daisy_system_rgb[RGB_SIZE-1:0]),
     .daisy_system_vld                  (daisy_system_vld),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .daisy_system_rdy                  (daisy_system_rdy),
     .avs_video_bar_core_address        (avs_video_bar_core_address),
     .avs_video_bar_core_write          (avs_video_bar_core_write),
     .avs_video_bar_core_writedata      (avs_video_bar_core_writedata[31:0]),
     .avs_video_sprite_core_address     (avs_video_sprite_core_address[10:0]),
     .avs_video_sprite_core_write       (avs_video_sprite_core_write),
     .avs_video_sprite_core_writedata   (avs_video_sprite_core_writedata[31:0]),
     .avs_pacman_core_address           (avs_pacman_core_address[12:0]),
     .avs_pacman_core_write             (avs_pacman_core_write),
     .avs_pacman_core_writedata         (avs_pacman_core_writedata[31:0]),
     .avs_video_rgb2gray_core_address   (avs_video_rgb2gray_core_address),
     .avs_video_rgb2gray_core_write     (avs_video_rgb2gray_core_write),
     .avs_video_rgb2gray_core_writedata (avs_video_rgb2gray_core_writedata[31:0]));


    /* vga_core_line_buffer AUTO_TEMPLATE (
      .line_buffer_\(.*\) (daisy_system_\1),
    )
    */
    vga_core_line_buffer
    #(
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE)
    )
    u_vga_core_line_buffer
    (/*AUTOINST*/
     // Outputs
     .line_buffer_rdy                   (daisy_system_rdy),      // Templated
     .vga_r                             (vga_r[RSIZE-1:0]),
     .vga_g                             (vga_g[GSIZE-1:0]),
     .vga_b                             (vga_b[BSIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .line_buffer_data                  (daisy_system_data),     // Templated
     .line_buffer_vld                   (daisy_system_vld));      // Templated

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/")
// End:
