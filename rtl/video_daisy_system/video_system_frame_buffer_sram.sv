/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/13/2022
 * ---------------------------------------------------------------
 * Version 05/15/2022:  Redeisgned the module
 * ---------------------------------------------------------------
 * VGA display system using SRAM frame buffer
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_system_frame_buffer_sram #(
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
    inout  [SRAM_DW-1:0]    sram_dq
);

    localparam AVN_AW    = 18;
    localparam AVN_DW    = 16;
    localparam BYTE_FIELD_WIDTH = $clog2(AVN_DW/8);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/

    /*AUTOREGINPUT*/

    logic [AVN_AW-1:0]   sram_avn_address;
    logic [AVN_DW/8-1:0] sram_avn_byteenable;
    logic                sram_avn_read;
    logic [AVN_DW-1:0]   sram_avn_readdata;
    logic                sram_avn_write;
    logic [AVN_DW-1:0]   sram_avn_writedata;

    logic                src_avn_waitrequest;
    logic [AVN_AW-1:0]   src_avn_address;
    logic [AVN_DW-1:0]   src_avn_writedata;

    vga_fc_t             daisy_system_fc;
    logic [RGB_SIZE-1:0] daisy_system_rgb;
    logic                daisy_system_vld;
    logic                daisy_system_rdy;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign daisy_system_rdy = ~src_avn_waitrequest;
    assign src_avn_address = ({{(AVN_AW-`H_SIZE){1'b0}},daisy_system_fc.hc} + (daisy_system_fc.vc * `H_DISPLAY));


    always @* begin
        src_avn_writedata = 0;
        src_avn_writedata[RGB_SIZE-1:0] = daisy_system_rgb;
    end

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


    /* vga_core_frame_buffer_sram AUTO_TEMPLATE (
      .src_avn_read       (),
      .src_avn_write      (daisy_system_vld),
      .src_avn_readdata   (),
    )
    */
    vga_core_frame_buffer_sram
    #(
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE)
    )
    u_vga_core_frame_buffer_sram
    (/*AUTOINST*/
     // Outputs
     .src_avn_readdata                  (),                      // Templated
     .src_avn_waitrequest               (src_avn_waitrequest),
     .sram_avn_read                     (sram_avn_read),
     .sram_avn_write                    (sram_avn_write),
     .sram_avn_address                  (sram_avn_address[AVN_AW-1:0]),
     .sram_avn_writedata                (sram_avn_writedata[AVN_DW-1:0]),
     .sram_avn_byteenable               (sram_avn_byteenable[AVN_DW/8-1:0]),
     .vga_r                             (vga_r[RSIZE-1:0]),
     .vga_g                             (vga_g[GSIZE-1:0]),
     .vga_b                             (vga_b[BSIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .src_avn_read                      (),                      // Templated
     .src_avn_write                     (daisy_system_vld),      // Templated
     .src_avn_address                   (src_avn_address[AVN_AW-1:0]),
     .src_avn_writedata                 (src_avn_writedata[AVN_DW-1:0]),
     .sram_avn_readdata                 (sram_avn_readdata[AVN_DW-1:0]));


  /* avalon_sram_controller AUTO_TEMPLATE (
    .avn_\(.*\) (sram_avn_\1[]),
    .reset      (sys_rst),
    .clk        (sys_clk),
  )
  */
  avalon_sram_controller
  #(/*AUTOINSTPARAM*/
    // Parameters
    .SRAM_AW                            (SRAM_AW),
    .SRAM_DW                            (SRAM_DW),
    .AVN_AW                             (AVN_AW),
    .AVN_DW                             (AVN_DW))
  u_avalon_sram_controller
  (/*AUTOINST*/
   // Outputs
   .avn_readdata                        (sram_avn_readdata[AVN_DW-1:0]), // Templated
   .sram_ce_n                           (sram_ce_n),
   .sram_oe_n                           (sram_oe_n),
   .sram_we_n                           (sram_we_n),
   .sram_be_n                           (sram_be_n[SRAM_DW/8-1:0]),
   .sram_addr                           (sram_addr[SRAM_AW-1:0]),
   // Inouts
   .sram_dq                             (sram_dq[SRAM_DW-1:0]),
   // Inputs
   .clk                                 (sys_clk),               // Templated
   .reset                               (sys_rst),               // Templated
   .avn_read                            (sram_avn_read),         // Templated
   .avn_write                           (sram_avn_write),        // Templated
   .avn_address                         (sram_avn_address[AVN_AW-1:0]), // Templated
   .avn_writedata                       (sram_avn_writedata[AVN_DW-1:0]), // Templated
   .avn_byteenable                      (sram_avn_byteenable[AVN_DW/8-1:0])); // Templated


endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/ -y ../../ip/sram/")
// End:
