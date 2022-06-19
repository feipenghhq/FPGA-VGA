/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/29/2022
 * ---------------------------------------------------------------
 * VGA controller using SRAM as frame buffer
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_controller_sram #(
    parameter AVN_AW    = 18,
    parameter AVN_DW    = 16,
    parameter BUF_SIZE  = 16,
    parameter START_DELAY = 12

) (
    // clock
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    // vga interface
    output  [`R_SIZE-1:0]   vga_r,
    output  [`G_SIZE-1:0]   vga_g,
    output  [`B_SIZE-1:0]   vga_b,
    output                  vga_hsync,
    output                  vga_vsync,

    // source avalon interface
    input                   framebuffer_avn_read,
    input                   framebuffer_avn_write,
    input  [AVN_AW-1:0]     framebuffer_avn_address,
    input  [AVN_DW-1:0]     framebuffer_avn_writedata,
    input  [AVN_DW/8-1:0]   framebuffer_avn_byteenable,
    output [AVN_DW-1:0]     framebuffer_avn_readdata,
    output                  framebuffer_avn_readdatavalid,
    output                  framebuffer_avn_waitrequest,

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

    /*AUTOREGINPUT*/

    logic [AVN_AW-1:0]   sram_avn_address;
    logic [AVN_DW/8-1:0] sram_avn_byteenable;
    logic                sram_avn_read;
    logic [AVN_DW-1:0]   sram_avn_readdata;
    logic                sram_avn_write;
    logic [AVN_DW-1:0]   sram_avn_writedata;
    logic                sram_avn_waitrequest;
    logic                sram_avn_readdatavalid;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign sram_avn_waitrequest = 0;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* vga_controller_framebuffer_1rw AUTO_TEMPLATE (
      .vram_\(.*\)                  (sram_\1[]),
    )
    */
    vga_controller_framebuffer_1rw
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .BUF_SIZE                         (BUF_SIZE),
      .START_DELAY                      (START_DELAY))
    u_vga_controller_framebuffer_1rw
    (/*AUTOINST*/
     // Outputs
     .vga_r                             (vga_r[`R_SIZE-1:0]),
     .vga_g                             (vga_g[`G_SIZE-1:0]),
     .vga_b                             (vga_b[`B_SIZE-1:0]),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .framebuffer_avn_readdata          (framebuffer_avn_readdata[AVN_DW-1:0]),
     .framebuffer_avn_readdatavalid     (framebuffer_avn_readdatavalid),
     .framebuffer_avn_waitrequest       (framebuffer_avn_waitrequest),
     .vram_avn_read                     (sram_avn_read),         // Templated
     .vram_avn_write                    (sram_avn_write),        // Templated
     .vram_avn_address                  (sram_avn_address[AVN_AW-1:0]), // Templated
     .vram_avn_writedata                (sram_avn_writedata[AVN_DW-1:0]), // Templated
     .vram_avn_byteenable               (sram_avn_byteenable[AVN_DW/8-1:0]), // Templated
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .framebuffer_avn_read              (framebuffer_avn_read),
     .framebuffer_avn_write             (framebuffer_avn_write),
     .framebuffer_avn_address           (framebuffer_avn_address[AVN_AW-1:0]),
     .framebuffer_avn_writedata         (framebuffer_avn_writedata[AVN_DW-1:0]),
     .framebuffer_avn_byteenable        (framebuffer_avn_byteenable[AVN_DW/8-1:0]),
     .vram_avn_readdata                 (sram_avn_readdata[AVN_DW-1:0]), // Templated
     .vram_avn_readdatavalid            (sram_avn_readdatavalid), // Templated
     .vram_avn_waitrequest              (sram_avn_waitrequest));  // Templated


  /* avalon_sram_controller AUTO_TEMPLATE (
    .avn_\(.*\) (sram_avn_\1[]),
    .reset      (sys_rst),
    .clk        (sys_clk),
  )
  */
  avalon_sram_controller
  #(/*AUTOINSTPARAM*/
    // Parameters
    .AVN_AW                             (AVN_AW),
    .AVN_DW                             (AVN_DW))
  u_avalon_sram_controller
  (/*AUTOINST*/
   // Outputs
   .avn_readdata                        (sram_avn_readdata[AVN_DW-1:0]), // Templated
   .avn_readdatavalid                   (sram_avn_readdatavalid), // Templated
   .sram_ce_n                           (sram_ce_n),
   .sram_oe_n                           (sram_oe_n),
   .sram_we_n                           (sram_we_n),
   .sram_be_n                           (sram_be_n[AVN_DW/8-1:0]),
   .sram_addr                           (sram_addr[AVN_AW-1:0]),
   // Inouts
   .sram_dq                             (sram_dq[AVN_DW-1:0]),
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
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/ -y ../../../ip/sram/")
// End:
