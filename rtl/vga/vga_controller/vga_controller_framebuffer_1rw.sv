/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/27/2022
 * ---------------------------------------------------------------
 * VGA core with frame buffer
 * ---------------------------------------------------------------
 *
 * The frame buffer is generally a 2 RW ports memory.
 * It holds the pixel for the entire frame displayed on the screen.
 *
 * 1 RW port is accessed by the upstream pixel processing logic.
 * 1 RW port is accessed by the vga core to retrieve the pixel data.
 *
 * This module is a wrapper for the memory, it provides 2 avalon
 * interface to access the actual memory so the memory can be
 * build with different memory such as FPGA onchip memory,
 * off-chip sram or off-chip sdram.
 *
 * On the VGA read side, we use an asynchronous FIFO as a prefetch
 * buffer. The pixel is prefetched from the memory into the fifo
 * to hide the latency of the memory in case the memory needs several
 * clock cycles to return the data.
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_controller_framebuffer_1rw #(
    parameter AVN_AW        = 18,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    parameter BUF_SIZE      = 16,   // prefetch bufer size
    parameter START_DELAY   = 12
)(
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // vga interface
    output [`R_SIZE-1:0]    vga_r,
    output [`G_SIZE-1:0]    vga_g,
    output [`B_SIZE-1:0]    vga_b,
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

    // avalon interface to vram
    output                  vram_avn_read,
    output                  vram_avn_write,
    output [AVN_AW-1:0]     vram_avn_address,
    output [AVN_DW-1:0]     vram_avn_writedata,
    output [AVN_DW/8-1:0]   vram_avn_byteenable,
    input  [AVN_DW-1:0]     vram_avn_readdata,
    input                   vram_avn_readdatavalid,
    input                   vram_avn_waitrequest
);

    localparam              PENDING_READ = 16;

    // memory port 1 avalon interface - sys_clk
    // used by the pixel processing logic
    logic                   pro_avn_read;
    logic                   pro_avn_write;
    logic [AVN_AW-1:0]      pro_avn_address;
    logic [AVN_DW-1:0]      pro_avn_writedata;
    logic [AVN_DW/8-1:0]    pro_avn_byteenable;
    logic [AVN_DW-1:0]      pro_avn_readdata;
    logic                   pro_avn_readdatavalid;
    logic                   pro_avn_waitrequest;

    // memory port 2 avalon interface - sys_clk
    // used by the vga sync logic
    logic                   pxl_avn_read;
    logic                   pxl_avn_write;
    logic [AVN_AW-1:0]      pxl_avn_address;
    logic [AVN_DW-1:0]      pxl_avn_writedata;
    logic [AVN_DW/8-1:0]    pxl_avn_byteenable;
    logic [AVN_DW-1:0]      pxl_avn_readdata;
    logic                   pxl_avn_readdatavalid;
    logic                   pxl_avn_waitrequest;

    vga_controller_framebuffer
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .BUF_SIZE                         (BUF_SIZE),
      .START_DELAY                      (START_DELAY))
    u_vga_controller_framebuffer
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
     .pro_avn_read                      (pro_avn_read),
     .pro_avn_write                     (pro_avn_write),
     .pro_avn_address                   (pro_avn_address[AVN_AW-1:0]),
     .pro_avn_writedata                 (pro_avn_writedata[AVN_DW-1:0]),
     .pro_avn_byteenable                (pro_avn_byteenable[AVN_DW/8-1:0]),
     .pxl_avn_read                      (pxl_avn_read),
     .pxl_avn_write                     (pxl_avn_write),
     .pxl_avn_address                   (pxl_avn_address[AVN_AW-1:0]),
     .pxl_avn_writedata                 (pxl_avn_writedata[AVN_DW-1:0]),
     .pxl_avn_byteenable                (pxl_avn_byteenable[AVN_DW/8-1:0]),
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
     .pro_avn_readdata                  (pro_avn_readdata[AVN_DW-1:0]),
     .pro_avn_readdatavalid             (pro_avn_readdatavalid),
     .pro_avn_waitrequest               (pro_avn_waitrequest),
     .pxl_avn_readdata                  (pxl_avn_readdata[AVN_DW-1:0]),
     .pxl_avn_readdatavalid             (pxl_avn_readdatavalid),
     .pxl_avn_waitrequest               (pxl_avn_waitrequest));

    /* vga_avn_mux AUTO_TEMPLATE (
        .port1_\(.*\)   (pro_\1[]),
        .port2_\(.*\)   (pxl_\1[]),
        .out_\(.*\)     (vram_\1[]),
        .clk            (sys_clk),
        .rst            (sys_rst),
    )
    */
    vga_avn_mux
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .PENDING_READ                     (PENDING_READ))
    u_vga_avn_mux
    (/*AUTOINST*/
     // Outputs
     .port1_avn_readdata                (pro_avn_readdata[AVN_DW-1:0]), // Templated
     .port1_avn_readdatavalid           (pro_avn_readdatavalid), // Templated
     .port1_avn_waitrequest             (pro_avn_waitrequest),   // Templated
     .port2_avn_readdata                (pxl_avn_readdata[AVN_DW-1:0]), // Templated
     .port2_avn_readdatavalid           (pxl_avn_readdatavalid), // Templated
     .port2_avn_waitrequest             (pxl_avn_waitrequest),   // Templated
     .out_avn_read                      (vram_avn_read),         // Templated
     .out_avn_write                     (vram_avn_write),        // Templated
     .out_avn_address                   (vram_avn_address[AVN_AW-1:0]), // Templated
     .out_avn_writedata                 (vram_avn_writedata[AVN_DW-1:0]), // Templated
     .out_avn_byteenable                (vram_avn_byteenable[AVN_DW/8-1:0]), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .port1_avn_read                    (pro_avn_read),          // Templated
     .port1_avn_write                   (pro_avn_write),         // Templated
     .port1_avn_address                 (pro_avn_address[AVN_AW-1:0]), // Templated
     .port1_avn_writedata               (pro_avn_writedata[AVN_DW-1:0]), // Templated
     .port1_avn_byteenable              (pro_avn_byteenable[AVN_DW/8-1:0]), // Templated
     .port2_avn_read                    (pxl_avn_read),          // Templated
     .port2_avn_write                   (pxl_avn_write),         // Templated
     .port2_avn_address                 (pxl_avn_address[AVN_AW-1:0]), // Templated
     .port2_avn_writedata               (pxl_avn_writedata[AVN_DW-1:0]), // Templated
     .port2_avn_byteenable              (pxl_avn_byteenable[AVN_DW/8-1:0]), // Templated
     .out_avn_readdata                  (vram_avn_readdata[AVN_DW-1:0]), // Templated
     .out_avn_readdatavalid             (vram_avn_readdatavalid), // Templated
     .out_avn_waitrequest               (vram_avn_waitrequest));  // Templated

endmodule

// Local Variables:
// verilog-library-flags:("-y ../common/ ")
// End:
