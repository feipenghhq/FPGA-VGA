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

module video_system_framebuffer_sram #(
    parameter AVN_AW   = 18,
    parameter AVN_DW   = 16
) (
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
    output                  vga_vsync,

    // the sram interface
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output [AVN_DW/8-1:0]   sram_be_n,
    output [AVN_AW-1:0]     sram_addr,
    inout  [AVN_DW-1:0]     sram_dq
);

    localparam BUF_SIZE = 16;
    localparam START_DELAY = 12;

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
    logic                sram_avn_waitrequest;

    logic                framebuffer_avn_write;
    logic                framebuffer_avn_read;
    logic [AVN_DW/8-1:0] framebuffer_avn_byteenable;
    logic                framebuffer_avn_waitrequest;
    logic [AVN_AW-1:0]   framebuffer_avn_address;
    logic [AVN_DW-1:0]   framebuffer_avn_writedata;

    vga_frame_t           daisy_system_frame;
    logic [`RGB_SIZE-1:0] daisy_system_rgb;
    logic                 daisy_system_vld;

    logic                 stall;

    // --------------------------------
    // Main logic
    // --------------------------------


    assign framebuffer_avn_address = ({{(AVN_AW-`H_SIZE){1'b0}},daisy_system_frame.hc} + (daisy_system_frame.vc * `H_DISPLAY));
    assign framebuffer_avn_byteenable = {AVN_DW/8{1'b1}};
    assign framebuffer_avn_write = daisy_system_vld;
    assign framebuffer_avn_read = 0;

    assign stall = framebuffer_avn_waitrequest;
    assign daisy_system_rgb = {daisy_system_frame.r, daisy_system_frame.g, daisy_system_frame.b};

    always @* begin
        framebuffer_avn_writedata = 0;
        framebuffer_avn_writedata[`RGB_SIZE-1:0] = daisy_system_rgb;
    end

    // --------------------------------
    // Module Declaration
    // --------------------------------

    video_daisy_core
    u_video_daisy_core
    (/*AUTOINST*/
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


    /* vga_controller_sram AUTO_TEMPLATE (
      .framebuffer_avn_read         (1'b0),
      .framebuffer_avn_readdata     (),
      .framebuffer_avn_readdatavalid(),
      .framebuffer_avn_write        (framebuffer_avn_write),
    )
    */
    vga_controller_sram
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .BUF_SIZE                         (BUF_SIZE),
      .START_DELAY                      (START_DELAY))
    u_vga_controller_sram
    (/*AUTOINST*/
     // Outputs
     .vga_r                             (vga_r[`R_SIZE-1:0]),
     .vga_g                             (vga_g[`G_SIZE-1:0]),
     .vga_b                             (vga_b[`B_SIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .framebuffer_avn_readdata          (),                      // Templated
     .framebuffer_avn_readdatavalid     (),                      // Templated
     .framebuffer_avn_waitrequest       (framebuffer_avn_waitrequest),
     .sram_ce_n                         (sram_ce_n),
     .sram_oe_n                         (sram_oe_n),
     .sram_we_n                         (sram_we_n),
     .sram_be_n                         (sram_be_n[AVN_DW/8-1:0]),
     .sram_addr                         (sram_addr[AVN_AW-1:0]),
     // Inouts
     .sram_dq                           (sram_dq[AVN_DW-1:0]),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .framebuffer_avn_read              (1'b0),                  // Templated
     .framebuffer_avn_write             (framebuffer_avn_write), // Templated
     .framebuffer_avn_address           (framebuffer_avn_address[AVN_AW-1:0]),
     .framebuffer_avn_writedata         (framebuffer_avn_writedata[AVN_DW-1:0]),
     .framebuffer_avn_byteenable        (framebuffer_avn_byteenable[AVN_DW/8-1:0]));


endmodule

// Local Variables:
// verilog-library-flags:("-y ../../vga/vga_controller_wrapper/  -y ../../vga/video_core -y ../../ip/sram/")
// End:
