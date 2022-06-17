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

module video_system_linebuffer  (
    // clock
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    input                   bar_core_bypass,
    input                   pikachu_core_bypass,
    input                   pacman_core_bypass,
    input                   rgb2gray_core_bypass,

    // vga interface
    output  [`R_SIZE-1:0]   vga_r,
    output  [`G_SIZE-1:0]   vga_g,
    output  [`B_SIZE-1:0]   vga_b,
    output                  vga_hsync,
    output                  vga_vsync
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/

    vga_frame_t             daisy_system_frame;
    logic [`RGB_SIZE-1:0]   daisy_system_rgb;
    logic [`RGB_SIZE:0]     daisy_system_data;
    logic                   daisy_system_vld;
    logic                   daisy_system_rdy;
    logic                   stall;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign daisy_system_data[`RGB_SIZE]     = daisy_system_frame.start;
    assign daisy_system_data[`RGB_SIZE-1:0] = {daisy_system_frame.r, daisy_system_frame.g, daisy_system_frame.b};

    assign stall = ~daisy_system_rdy;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    video_daisy_core
    u_video_daisy_core
    (
     // Interfaces
     .daisy_system_frame                (daisy_system_frame),
     // Outputs
     .daisy_system_vld                  (daisy_system_vld),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .stall                             (stall),
     .bar_core_bypass                   (bar_core_bypass),
     .pikachu_core_bypass               (pikachu_core_bypass),
     .pacman_core_bypass                (pacman_core_bypass),
     .rgb2gray_core_bypass              (rgb2gray_core_bypass));


    /* vga_controller_linebuffer AUTO_TEMPLATE (
      .linebuffer_\(.*\) (daisy_system_\1),
    )
    */
    vga_controller_linebuffer
    u_vga_controller_linebuffer
    (/*AUTOINST*/
     // Outputs
     .linebuffer_rdy                    (daisy_system_rdy),      // Templated
     .vga_r                             (vga_r[`R_SIZE-1:0]),
     .vga_g                             (vga_g[`G_SIZE-1:0]),
     .vga_b                             (vga_b[`B_SIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .linebuffer_data                   (daisy_system_data),     // Templated
     .linebuffer_vld                    (daisy_system_vld));      // Templated

endmodule

// Local Variables:
// verilog-library-flags:("-y ../../vga/vga_controller  -y ../../vga/video_core")
// End:
