/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * difussion limited aggregation using SRAM frame buffer
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module dla_frame_buffer_sram #(
    parameter AVN_AW = 19,
    parameter AVN_DW = 16
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

    // the sram interface
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output [AVN_DW/8-1:0]   sram_be_n,
    output [AVN_AW-1:0]     sram_addr,
    inout  [AVN_DW-1:0]     sram_dq
);

    localparam N = 1000;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/

    logic [AVN_AW-1:0]   sram_avn_address;
    logic [AVN_DW/8-1:0] sram_avn_byteenable;
    logic                sram_avn_read;
    logic [AVN_DW-1:0]   sram_avn_readdata;
    logic                sram_avn_write;
    logic [AVN_DW-1:0]   sram_avn_writedata;

    logic                framebuffer_avn_waitrequest;
    logic [AVN_AW-1:0]   framebuffer_avn_address;
    logic [AVN_DW-1:0]   framebuffer_avn_writedata;
    logic [AVN_DW-1:0]   framebuffer_avn_readdata;
    logic                framebuffer_avn_write;
    logic                framebuffer_avn_read;
    logic                framebuffer_avn_readdatavalid;

    // --------------------------------
    // Main logic
    // --------------------------------


    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* dla_simulate AUTO_TEMPLATE (
      .vram_\(.*\)  (src_\1[]),
      .clk          (sys_clk),
      .rst          (sys_rst),
    )
    */
    dla_simulate
    #(/*AUTOINSTPARAM*/
      // Parameters
      .N                                (N),
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW))
    u_dla_simulate
    (/*AUTOINST*/
     // Outputs
     .vram_avn_address                  (framebuffer_avn_address[AVN_AW-1:0]), // Templated
     .vram_avn_write                    (framebuffer_avn_write),         // Templated
     .vram_avn_read                     (framebuffer_avn_read),          // Templated
     .vram_avn_writedata                (framebuffer_avn_writedata[AVN_DW-1:0]), // Templated
     // Inputs
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .vram_avn_waitrequest              (framebuffer_avn_waitrequest),   // Templated
     .vram_avn_readdata                 (framebuffer_avn_readdata[AVN_DW-1:0]), // Templated
     .vram_avn_readdatavalid            (framebuffer_avn_readdatavalid)); // Templated


    vga_controller_sram
    u_vga_controller_sram
    (
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_r                             (vga_r),
     .vga_g                             (vga_g),
     .vga_b                             (vga_b),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .framebuffer_avn_read              (framebuffer_avn_read),
     .framebuffer_avn_write             (framebuffer_avn_write),
     .framebuffer_avn_address           (framebuffer_avn_address),
     .framebuffer_avn_writedata         (framebuffer_avn_writedata),
     .framebuffer_avn_byteenable        ({AVN_DW/8{1'b1}}),
     .framebuffer_avn_readdata          (framebuffer_avn_readdata),
     .framebuffer_avn_readdatavalid     (framebuffer_avn_readdatavalid),
     .framebuffer_avn_waitrequest       (framebuffer_avn_waitrequest),
     .sram_ce_n                         (sram_ce_n),
     .sram_oe_n                         (sram_oe_n),
     .sram_we_n                         (sram_we_n),
     .sram_be_n                         (sram_be_n),
     .sram_addr                         (sram_addr),
     .sram_dq                           (sram_dq)
    );

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/ -y ../../ip/sram/")
// End:
