/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA daisy system
 * ---------------------------------------------------------------
 */

`include "vga_timing.svh"

module video_daisy_system #(
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
    input  [31:0]           avs_video_bar_core_writedata
);

    localparam HSIZE     = 10;
    localparam VSIZE     = 10;
    localparam VDISPLAY  = 480;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOREGINPUT*/

    /*AUTOWIRE*/


    logic [`H_SIZE-1:0]     hcount;
    logic [`V_SIZE-1:0]     vcount;
    logic                   frame_start;
    logic                   frame_display;

    logic [RGB_SIZE:0]      line_buffer_data;
    logic                   line_buffer_vld;
    logic                   line_buffer_rdy;

    logic [RGB_SIZE-1:0]    video_bar_core_snk_rgb;

    // --------------------------------
    // Glue Logic
    // --------------------------------

    assign line_buffer_data = {frame_start, video_bar_core_snk_rgb};
    assign line_buffer_vld  = frame_display & line_buffer_rdy;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* vga_frame_counter AUTO_TEMPLATE (
     .clk       (sys_clk),
     .rst       (sys_rst),
     .clear     (0),
     .frame_end (),
    );
    */
    vga_frame_counter
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_vga_frame_counter
    (/*AUTOINST*/
     // Outputs
     .hcount                            (hcount[`H_SIZE-1:0]),
     .vcount                            (vcount[`V_SIZE-1:0]),
     .frame_start                       (frame_start),
     .frame_end                         (),                      // Templated
     .frame_display                     (frame_display),
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .clear                             (0));                     // Templated

    /* video_bar_core AUTO_TEMPLATE (
     .clk           (sys_clk),
     .rst           (sys_rst),
     .snk_rgb       (video_bar_core_snk_rgb[]),
     .avs_\(.*\)    (avs_video_bar_core_\1[]),
     .hc            (hcount),
     .vc            (vcount),
     .src_rgb       (0),
    );
    */
    video_bar_core
    #(
      /*AUTOINSTPARAM*/
      // Parameters
      .HSIZE                            (HSIZE),
      .VSIZE                            (VSIZE),
      .VDISPLAY                         (VDISPLAY),
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_video_bar_core
    (/*AUTOINST*/
     // Outputs
     .snk_rgb                           (video_bar_core_snk_rgb[RGB_SIZE-1:0]), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_bar_core_write), // Templated
     .avs_address                       (avs_video_bar_core_address), // Templated
     .avs_writedata                     (avs_video_bar_core_writedata[31:0]), // Templated
     .hc                                (hcount),                // Templated
     .vc                                (vcount),                // Templated
     .src_rgb                           (0));                     // Templated

    vga_sync_core
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_vga_sync_core
    (/*AUTOINST*/
     // Outputs
     .line_buffer_rdy                   (line_buffer_rdy),
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
     .line_buffer_data                  (line_buffer_data[RGB_SIZE:0]),
     .line_buffer_vld                   (line_buffer_vld));

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/bar_core")
// End:
