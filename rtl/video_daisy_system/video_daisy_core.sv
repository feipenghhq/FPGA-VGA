/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Version 05/15/2022:
 * Redeisgned the module: move the vga module out of the module
 * ---------------------------------------------------------------
 * This module contains a daisy chain of different video cores
 * ---------------------------------------------------------------
 */

/*
  _________      ______      _____________      _____________      __________
 |  Frame  |    | bar  |    |   pikachu   |    |   pacman    |    | rgb2gray |
 | counter | -> | core | -> | sprite core | -> | sprite core | -> |   core   | -> Downstream
 |_________|    |______|    |_____________|    |_____________|    |__________|

*/


`include "vga.svh"

module video_daisy_core #(
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

    // video daisy core output
    output vga_fc_t         daisy_system_fc,
    output [RGB_SIZE-1:0]   daisy_system_rgb,
    output                  daisy_system_vld,
    input                   daisy_system_rdy,

    // avalon interface for the cores
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

    localparam PIPELINE = 1;
    localparam SPRITE_HSIZE  = 32;
    localparam SPRITE_VSIZE  = 32;
    localparam SPRITE_RAM_AW = 10;

    logic [`H_SIZE-1:0]     fc_hcount;
    logic [`V_SIZE-1:0]     fc_vcount;
    logic                   fc_enable;
    logic                   frame_start;
    logic                   frame_display;

    vga_fc_t                bar_core_src_fc;
    logic                   bar_core_src_rdy;
    logic [RGB_SIZE-1:0]    bar_core_src_rgb;
    logic                   bar_core_src_vld;

    vga_fc_t                pikachu_core_src_fc;
    logic                   pikachu_core_src_rdy;
    logic [RGB_SIZE-1:0]    pikachu_core_src_rgb;
    logic                   pikachu_core_src_vld;

    vga_fc_t                pacman_core_src_fc;
    logic                   pacman_core_src_rdy;
    logic [RGB_SIZE-1:0]    pacman_core_src_rgb;
    logic                   pacman_core_src_vld;

    vga_fc_t                rgb2gray_core_src_fc;
    logic                   rgb2gray_core_src_rdy;
    logic  [RGB_SIZE-1:0]   rgb2gray_core_src_rgb;
    logic                   rgb2gray_core_src_vld;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign fc_enable = bar_core_src_rdy;

    assign bar_core_src_fc.hc = fc_hcount;
    assign bar_core_src_fc.vc = fc_vcount;
    assign bar_core_src_fc.frame_start = frame_start;
    assign bar_core_src_vld = frame_display;
    assign bar_core_src_rgb = 0;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* vga_frame_counter AUTO_TEMPLATE (
     .clk       (sys_clk),
     .rst       (sys_rst),
     .fc_clear  (1'b0),
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
     .fc_clear                          (1'b0),                  // Templated
     .fc_enable                         (fc_enable));

    /* video_bar_core AUTO_TEMPLATE (
     //
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_video_bar_core_\1),
     .src_\(.*\)    (bar_core_src_\1),
     .snk_\(.*\)    (pikachu_core_src_\1),
    );
    */
    video_bar_core
    #(
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE),
      .PIPELINE                         (PIPELINE))
    u_bar_core
    (/*AUTOINST*/
     // Interfaces
     .src_fc                            (bar_core_src_fc),       // Templated
     .snk_fc                            (pikachu_core_src_fc),   // Templated
     // Outputs
     .src_rdy                           (bar_core_src_rdy),      // Templated
     .snk_vld                           (pikachu_core_src_vld),  // Templated
     .snk_rgb                           (pikachu_core_src_rgb),  // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_bar_core_write), // Templated
     .avs_address                       (avs_video_bar_core_address), // Templated
     .avs_writedata                     (avs_video_bar_core_writedata), // Templated
     .src_vld                           (bar_core_src_vld),      // Templated
     .src_rgb                           (bar_core_src_rgb),      // Templated
     .snk_rdy                           (pikachu_core_src_rdy));  // Templated

    /* video_sprite_core AUTO_TEMPLATE (
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_video_sprite_core_\1),
     .src_\(.*\)    (pikachu_core_src_\1),
     .snk_\(.*\)    (pacman_core_src_\1),

    );
    */
    video_sprite_core
    #(
      .MEM_FILE                         ("pikachu_32x32.mem"),
      .RGB_SIZE                         (RGB_SIZE),
      .SPRITE_HSIZE                     (SPRITE_HSIZE),
      .SPRITE_VSIZE                     (SPRITE_VSIZE),
      .SPRITE_RAM_AW                    (SPRITE_RAM_AW),
      .X_ORIGIN                         (32),
      .Y_ORIGIN                         (32))
    u_pikachu_core
    (/*AUTOINST*/
     // Interfaces
     .src_fc                            (pikachu_core_src_fc),   // Templated
     .snk_fc                            (pacman_core_src_fc),    // Templated
     // Outputs
     .src_rdy                           (pikachu_core_src_rdy),  // Templated
     .snk_vld                           (pacman_core_src_vld),   // Templated
     .snk_rgb                           (pacman_core_src_rgb),   // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_sprite_core_write), // Templated
     .avs_address                       (avs_video_sprite_core_address), // Templated
     .avs_writedata                     (avs_video_sprite_core_writedata), // Templated
     .src_vld                           (pikachu_core_src_vld),  // Templated
     .src_rgb                           (pikachu_core_src_rgb),  // Templated
     .snk_rdy                           (pacman_core_src_rdy));   // Templated

    /* video_sprite_animation_core AUTO_TEMPLATE (
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_pacman_core_\1),
     .src_\(.*\)    (pacman_core_src_\1),
     .snk_\(.*\)    (rgb2gray_core_src_\1),

    );
    */
    localparam PACMAN_SPRITE_IDXW = 2;
    localparam PACMAN_SPRITE_NUM = 4;

    video_sprite_animation_core
    #(
      .RGB_SIZE       (RGB_SIZE),
      .SPRITE_HSIZE   (SPRITE_HSIZE),
      .SPRITE_VSIZE   (SPRITE_VSIZE),
      .SPRITE_AW      (SPRITE_RAM_AW),
      .SPRITE_IDXW    (PACMAN_SPRITE_IDXW),
      .SPRITE_RAM_AW  (SPRITE_RAM_AW+PACMAN_SPRITE_IDXW),
      .SPRITE_NUM     (PACMAN_SPRITE_NUM),
      .MEM_FILE       ("pacman.mem"),
      .X_ORIGIN       (64),
      .Y_ORIGIN       (64),
      .SPRITE_RATE    (10000000)
    )
    u_pacman_core
    (/*AUTOINST*/
     // Interfaces
     .src_fc                            (pacman_core_src_fc),    // Templated
     .snk_fc                            (rgb2gray_core_src_fc),  // Templated
     // Outputs
     .src_rdy                           (pacman_core_src_rdy),   // Templated
     .snk_vld                           (rgb2gray_core_src_vld), // Templated
     .snk_rgb                           (rgb2gray_core_src_rgb), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_pacman_core_write), // Templated
     .avs_address                       (avs_pacman_core_address), // Templated
     .avs_writedata                     (avs_pacman_core_writedata), // Templated
     .src_vld                           (pacman_core_src_vld),   // Templated
     .src_rgb                           (pacman_core_src_rgb),   // Templated
     .snk_rdy                           (rgb2gray_core_src_rdy)); // Templated


    /* video_rgb2gray_core AUTO_TEMPLATE (
     //
     .clk           (sys_clk),
     .rst           (sys_rst),
     .avs_\(.*\)    (avs_video_rgb2gray_core_\1),
     .src_\(.*\)    (rgb2gray_core_src_\1),
     .snk_\(.*\)    (daisy_system_\1),
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
     .src_fc                            (rgb2gray_core_src_fc),  // Templated
     .snk_fc                            (daisy_system_fc),       // Templated
     // Outputs
     .src_rdy                           (rgb2gray_core_src_rdy), // Templated
     .snk_vld                           (daisy_system_vld),      // Templated
     .snk_rgb                           (daisy_system_rgb),      // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .avs_write                         (avs_video_rgb2gray_core_write), // Templated
     .avs_address                       (avs_video_rgb2gray_core_address), // Templated
     .avs_writedata                     (avs_video_rgb2gray_core_writedata), // Templated
     .src_vld                           (rgb2gray_core_src_vld), // Templated
     .src_rgb                           (rgb2gray_core_src_rgb), // Templated
     .snk_rdy                           (daisy_system_rdy));      // Templated

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/")
// End:
