/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA daisy system
 * ---------------------------------------------------------------
 */

`include "vga.svh"

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
    input  [31:0]           avs_video_bar_core_writedata,

    input [10:0]            avs_video_sprite_core_address,
    input                   avs_video_sprite_core_write,
    input [31:0]            avs_video_sprite_core_writedata,

    input                   avs_video_rgb2gray_core_address,
    input                   avs_video_rgb2gray_core_write,
    input  [31:0]           avs_video_rgb2gray_core_writedata
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOREGINPUT*/

    /*AUTOWIRE*/

    localparam PIPELINE = 1;
    localparam SPRITE_HSIZE  = 32;   // 32x32 pixel sprite
    localparam SPRITE_VSIZE  = 32;
    localparam SPRITE_RAM_AW = 10;

    logic [`H_SIZE-1:0]     fc_hcount;
    logic [`V_SIZE-1:0]     fc_vcount;
    logic                   fc_enable;
    logic                   frame_start;
    logic                   frame_display;

    vga_fc_t                video_bar_core_src_fc;
    logic                   video_bar_core_src_rdy;
    logic [RGB_SIZE-1:0]    video_bar_core_src_rgb;
    logic                   video_bar_core_src_vld;

    vga_fc_t                video_sprite_core_src_fc;
    logic                   video_sprite_core_src_rdy;
    logic [RGB_SIZE-1:0]    video_sprite_core_src_rgb;
    logic                   video_sprite_core_src_vld;

    vga_fc_t                video_rgb2gray_core_src_fc;
    logic                   video_rgb2gray_core_src_rdy;
    logic  [RGB_SIZE-1:0]   video_rgb2gray_core_src_rgb;
    logic                   video_rgb2gray_core_src_vld;

    vga_fc_t                line_buffer_fc;
    logic [RGB_SIZE-1:0]    line_buffer_rgb;
    logic [RGB_SIZE:0]      line_buffer_data;
    logic                   line_buffer_vld;
    logic                   line_buffer_rdy;


    // --------------------------------
    // Main logic
    // --------------------------------

    assign fc_enable = video_bar_core_src_rdy;

    assign video_bar_core_src_fc.hc = fc_hcount;
    assign video_bar_core_src_fc.vc = fc_vcount;
    assign video_bar_core_src_fc.frame_start = frame_start;

    assign video_bar_core_src_vld = frame_display;

    assign line_buffer_data[RGB_SIZE] = line_buffer_fc.frame_start;
    assign line_buffer_data[RGB_SIZE-1:0] = line_buffer_rgb;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* vga_frame_counter AUTO_TEMPLATE (
     .clk       (sys_clk),
     .rst       (sys_rst),
     .fc_clear  (0),
     .frame_end (),
    );
    */
    vga_frame_counter
    u_vga_frame_counter
    (/*AUTOINST*/
     // Outputs
     .fc_hcount                         (fc_hcount[`H_SIZE-1:0]),
     .fc_vcount                         (fc_vcount[`V_SIZE-1:0]),
     .frame_start                       (frame_start),
     .frame_end                         (),                      // Templated
     .frame_display                     (frame_display),
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .fc_clear                          (0),                     // Templated
     .fc_enable                         (fc_enable));

    /* video_bar_core AUTO_TEMPLATE (
     //
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_video_bar_core_\1),
     .src_\(.*\)    (video_bar_core_src_\1[]),
     .snk_\(.*\)    (video_sprite_core_src_\1[]),
    );
    */
    video_bar_core
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE),
      .PIPELINE                         (PIPELINE))
    u_video_bar_core
    (/*AUTOINST*/
     // Interfaces
     .src_fc                            (video_bar_core_src_fc), // Templated
     .snk_fc                            (video_sprite_core_src_fc), // Templated
     // Outputs
     .src_rdy                           (video_bar_core_src_rdy), // Templated
     .snk_vld                           (video_sprite_core_src_vld), // Templated
     .snk_rgb                           (video_sprite_core_src_rgb[RGB_SIZE-1:0]), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_bar_core_write), // Templated
     .avs_address                       (avs_video_bar_core_address), // Templated
     .avs_writedata                     (avs_video_bar_core_writedata), // Templated
     .src_vld                           (video_bar_core_src_vld), // Templated
     .src_rgb                           (video_bar_core_src_rgb[RGB_SIZE-1:0]), // Templated
     .snk_rdy                           (video_sprite_core_src_rdy)); // Templated

    /* video_sprite_core AUTO_TEMPLATE (
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_video_sprite_core_\1[]),
     .src_\(.*\)    (video_sprite_core_src_\1[]),
     .snk_\(.*\)    (video_rgb2gray_core_src_\1[]),

    );
    */
    video_sprite_core
    #(
      .MEM_FILE                         ("pikachu_32x32.mem"),
      /*AUTOINSTPARAM*/
      // Parameters
      .RGB_SIZE                         (RGB_SIZE),
      .SPRITE_HSIZE                     (SPRITE_HSIZE),
      .SPRITE_VSIZE                     (SPRITE_VSIZE),
      .SPRITE_RAM_AW                    (SPRITE_RAM_AW))
    u_video_sprite_core
    (/*AUTOINST*/
     // Interfaces
     .src_fc                            (video_sprite_core_src_fc), // Templated
     .snk_fc                            (video_rgb2gray_core_src_fc), // Templated
     // Outputs
     .src_rdy                           (video_sprite_core_src_rdy), // Templated
     .snk_vld                           (video_rgb2gray_core_src_vld), // Templated
     .snk_rgb                           (video_rgb2gray_core_src_rgb[RGB_SIZE-1:0]), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_sprite_core_write), // Templated
     .avs_address                       (avs_video_sprite_core_address[SPRITE_RAM_AW:0]), // Templated
     .avs_writedata                     (avs_video_sprite_core_writedata[31:0]), // Templated
     .src_vld                           (video_sprite_core_src_vld), // Templated
     .src_rgb                           (video_sprite_core_src_rgb[RGB_SIZE-1:0]), // Templated
     .snk_rdy                           (video_rgb2gray_core_src_rdy)); // Templated


    /* video_rgb2gray_core AUTO_TEMPLATE (
     //
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_video_rgb2gray_core_\1),
     .src_\(.*\)    (video_rgb2gray_core_src_\1[]),
     .snk_\(.*\)    (line_buffer_\1[]),
    )
    */
    video_rgb2gray_core
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_video_rgb2gray_core
    (/*AUTOINST*/
     // Interfaces
     .src_fc                            (video_rgb2gray_core_src_fc), // Templated
     .snk_fc                            (line_buffer_fc),        // Templated
     // Outputs
     .src_rdy                           (video_rgb2gray_core_src_rdy), // Templated
     .snk_vld                           (line_buffer_vld),       // Templated
     .snk_rgb                           (line_buffer_rgb[RGB_SIZE-1:0]), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_rgb2gray_core_write), // Templated
     .avs_address                       (avs_video_rgb2gray_core_address), // Templated
     .avs_writedata                     (avs_video_rgb2gray_core_writedata), // Templated
     .src_vld                           (video_rgb2gray_core_src_vld), // Templated
     .src_rgb                           (video_rgb2gray_core_src_rgb[RGB_SIZE-1:0]), // Templated
     .snk_rdy                           (line_buffer_rdy));       // Templated


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
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/")
// End:
