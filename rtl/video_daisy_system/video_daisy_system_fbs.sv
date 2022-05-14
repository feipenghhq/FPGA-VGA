/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/13/2022
 * ---------------------------------------------------------------
 * VGA daisy system using vga_core_fram_buffer_sram
 *
 * This module contains a daisy chain of different video cores
 *
 * ---------------------------------------------------------------
 */

/*
  _________      ______      _____________      _____________      __________      _______________
 |  Frame  |    | bar  |    |   pikachu   |    |   pacman    |    | rgb2gray |    | vga_core      |
 | counter | -> | core | -> | sprite core | -> | sprite core | -> |   core   | -> | _frame_buffer | => To Display
 |_________|    |______|    |_____________|    |_____________|    |__________|    |_______________|

*/


`include "vga.svh"

module video_daisy_system_fbs #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12,
    parameter SRAM_AW   = 18,   // SRAM address width
    parameter SRAM_DW   = 16    // SRAM data width
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
    input [31:0]            avs_video_rgb2gray_core_writedata,

    // the sram interface
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output [SRAM_DW/8-1:0]  sram_be_n,
    output [SRAM_AW-1:0]    sram_addr,
    output [SRAM_DW-1:0]    sram_dq_write,
    output                  sram_dq_en,
    input  [SRAM_DW-1:0]    sram_dq_read
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOREGINPUT*/



    // End of automatics

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

    vga_fc_t                frame_buffer_fc;
    logic                   frame_buffer_rdy;
    logic                   frame_buffer_vld;
    logic [RGB_SIZE-1:0]    frame_buffer_rgb;
    logic [SRAM_DW-1:0]     frame_buffer_writedata;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign fc_enable = bar_core_src_rdy;

    assign bar_core_src_fc.hc = fc_hcount;
    assign bar_core_src_fc.vc = fc_vcount;
    assign bar_core_src_fc.frame_start = 0;

    assign bar_core_src_vld = frame_display;

    always @* begin
      frame_buffer_writedata = 0;
      frame_buffer_writedata[RGB_SIZE-1:0] = frame_buffer_rgb;
    end

    // --------------------------------
    // Module Declaration
    // --------------------------------

    vga_frame_counter
    u_vga_frame_counter
    (
     // Outputs
     .fc_hcount                         (fc_hcount[`H_SIZE-1:0]),
     .fc_vcount                         (fc_vcount[`V_SIZE-1:0]),
     .frame_start                       (),
     .frame_end                         (),
     .frame_display                     (frame_display),
     // Inputs
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .fc_clear                          (0),
     .fc_enable                         (fc_enable));

    video_bar_core
    #(
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE),
      .PIPELINE                         (1))
    u_bar_core
    (
     // Interfaces
     .src_fc                            (bar_core_src_fc),
     .snk_fc                            (pikachu_core_src_fc),
     // Outputs
     .src_rdy                           (bar_core_src_rdy),
     .snk_vld                           (pikachu_core_src_vld),
     .snk_rgb                           (pikachu_core_src_rgb),
     // Inputs
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .avs_write                         (avs_video_bar_core_write),
     .avs_address                       (avs_video_bar_core_address),
     .avs_writedata                     (avs_video_bar_core_writedata),
     .src_vld                           (bar_core_src_vld),
     .src_rgb                           (bar_core_src_rgb),
     .snk_rdy                           (pikachu_core_src_rdy));


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
    (
     // Interfaces
     .src_fc                            (pikachu_core_src_fc),
     .snk_fc                            (pacman_core_src_fc),
     // Outputs
     .src_rdy                           (pikachu_core_src_rdy),
     .snk_vld                           (pacman_core_src_vld),
     .snk_rgb                           (pacman_core_src_rgb),
     // Inputs
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .avs_write                         (avs_video_sprite_core_write),
     .avs_address                       (avs_video_sprite_core_address),
     .avs_writedata                     (avs_video_sprite_core_writedata),
     .src_vld                           (pikachu_core_src_vld),
     .src_rgb                           (pikachu_core_src_rgb),
     .snk_rdy                           (pacman_core_src_rdy));


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
    (
     // Interfaces
     .src_fc                            (pacman_core_src_fc),
     .snk_fc                            (rgb2gray_core_src_fc),
     // Outputs
     .src_rdy                           (pacman_core_src_rdy),
     .snk_vld                           (rgb2gray_core_src_vld),
     .snk_rgb                           (rgb2gray_core_src_rgb),
     // Inputs
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .avs_write                         (avs_pacman_core_write),
     .avs_address                       (avs_pacman_core_address),
     .avs_writedata                     (avs_pacman_core_writedata),
     .src_vld                           (pacman_core_src_vld),
     .src_rgb                           (pacman_core_src_rgb),
     .snk_rdy                           (rgb2gray_core_src_rdy));



    video_rgb2gray_core
    #(
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_video_rgb2gray_core
    (
     // Interfaces
     .src_fc                            (rgb2gray_core_src_fc),
     .snk_fc                            (frame_buffer_fc),
     // Outputs
     .src_rdy                           (rgb2gray_core_src_rdy),
     .snk_vld                           (frame_buffer_vld),
     .snk_rgb                           (frame_buffer_rgb),
     // Inputs
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .avs_write                         (avs_video_rgb2gray_core_write),
     .avs_address                       (avs_video_rgb2gray_core_address),
     .avs_writedata                     (avs_video_rgb2gray_core_writedata),
     .src_vld                           (rgb2gray_core_src_vld),
     .src_rgb                           (rgb2gray_core_src_rgb),
     .snk_rdy                           (frame_buffer_rdy));


  vga_core_frame_buffer_sram
  #(
    .RSIZE                              (RSIZE),
    .GSIZE                              (GSIZE),
    .BSIZE                              (BSIZE),
    .RGB_SIZE                           (RGB_SIZE),
    .SRAM_AW                            (SRAM_AW),
    .SRAM_DW                            (SRAM_DW))
  u_vga_core_frame_buffer_sram
  (
   // Outputs
   .src_readdata                        (),
   .src_rdy                             (frame_buffer_rdy),
   .sram_ce_n                           (sram_ce_n),
   .sram_oe_n                           (sram_oe_n),
   .sram_we_n                           (sram_we_n),
   .sram_be_n                           (sram_be_n),
   .sram_addr                           (sram_addr),
   .sram_dq_write                       (sram_dq_write),
   .sram_dq_en                          (sram_dq_en),
   .vga_r                               (vga_r),
   .vga_g                               (vga_g),
   .vga_b                               (vga_b),
   .vga_hsync                           (vga_hsync),
   .vga_vsync                           (vga_vsync),
   // Inputs
   .pixel_clk                           (pixel_clk),
   .pixel_rst                           (pixel_rst),
   .sys_clk                             (sys_clk),
   .sys_rst                             (sys_rst),
   .src_read                            (0),
   .src_write                           (frame_buffer_vld),
   .src_x                               (frame_buffer_fc.hc),
   .src_y                               (frame_buffer_fc.vc),
   .src_writedata                       (frame_buffer_writedata),
   .sram_dq_read                        (sram_dq_read));

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/")
// End:
