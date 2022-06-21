/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * difussion limited aggregation using SRAM frame buffer
 * ---------------------------------------------------------------
 * 06/20/2022:
 *
 * To increase the speed of the process, we dvidie the design to
 * 2 clock domain: sys clock domain and pixel clock domain.
 *
 * - The dla logic is in sys clock and it can run as fast as possible.
 * - The vga control logic and frame buffer is in pixel clock domain.
 *   It runs at 25MHz
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

    input                   dla_type,

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

    localparam N = 20000;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/

    logic                framebuffer_avn_waitrequest;
    logic [AVN_AW-1:0]   framebuffer_avn_address;
    logic [AVN_DW-1:0]   framebuffer_avn_writedata;
    logic                framebuffer_avn_write;

    logic                dla_avn_waitrequest;
    logic [AVN_AW-1:0]   dla_avn_address;
    logic [AVN_DW-1:0]   dla_avn_writedata;
    logic                dla_avn_write;

    logic                cdc_fifo_full;
    logic                cdc_fifo_empty;
    logic                cdc_fifo_read;
    logic                cdc_fifo_write;

    logic [AVN_AW+AVN_DW-1:0] cdc_fifo_din;
    logic [AVN_AW+AVN_DW-1:0] cdc_fifo_dout;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign dla_avn_waitrequest = cdc_fifo_full;
    assign cdc_fifo_write = dla_avn_write & ~dla_avn_waitrequest;
    assign cdc_fifo_din = {dla_avn_address, dla_avn_writedata};

    assign cdc_fifo_read = ~cdc_fifo_empty & ~framebuffer_avn_waitrequest;
    assign {framebuffer_avn_address, framebuffer_avn_writedata} = cdc_fifo_dout;
    assign framebuffer_avn_write = cdc_fifo_read;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    dla_simulate
    #(
      .N                                (N),
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW))
    u_dla_simulate
    (
     .clk                               (sys_clk),
     .rst                               (sys_rst),
     .dla_type                          (dla_type),
     .dla_avn_address                   (dla_avn_address),
     .dla_avn_write                     (dla_avn_write),
     .dla_avn_writedata                 (dla_avn_writedata),
     .dla_avn_waitrequest               (dla_avn_waitrequest)
    );

    // Both the sys_clk and the pixel_clk are pixel_clk here.
    vga_controller_sram
    u_vga_controller_sram
    (
     .sys_clk                           (pixel_clk),
     .sys_rst                           (pixel_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_r                             (vga_r),
     .vga_g                             (vga_g),
     .vga_b                             (vga_b),
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .framebuffer_avn_read              (1'b0),
     .framebuffer_avn_write             (framebuffer_avn_write),
     .framebuffer_avn_address           (framebuffer_avn_address),
     .framebuffer_avn_writedata         (framebuffer_avn_writedata),
     .framebuffer_avn_byteenable        ({AVN_DW/8{1'b1}}),
     .framebuffer_avn_readdata          (),
     .framebuffer_avn_readdatavalid     (),
     .framebuffer_avn_waitrequest       (framebuffer_avn_waitrequest),
     .sram_ce_n                         (sram_ce_n),
     .sram_oe_n                         (sram_oe_n),
     .sram_we_n                         (sram_we_n),
     .sram_be_n                         (sram_be_n),
     .sram_addr                         (sram_addr),
     .sram_dq                           (sram_dq)
    );

  vga_async_fifo_fwft #(
     .WIDTH (AVN_AW+AVN_DW),
     .DEPTH (32)
  )
  u_vga_cdc_fifo_fwft
  (
    .rst_rd   (pixel_rst),
    .clk_rd   (pixel_clk),
    .read     (cdc_fifo_read),
    .dout     (cdc_fifo_dout),
    .empty    (cdc_fifo_empty),
    .rst_wr   (sys_rst),
    .clk_wr   (sys_clk),
    .din      (cdc_fifo_din),
    .write    (cdc_fifo_write),
    .full     (cdc_fifo_full),
    .afull    ()
);

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_core/  -y ../video_core/*/ -y ../../ip/sram/")
// End:
