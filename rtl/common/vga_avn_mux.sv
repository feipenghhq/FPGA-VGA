/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/27/2022
 * ---------------------------------------------------------------
 * VGA Avalon pipelined bus multiplixer
 * ---------------------------------------------------------------
 *
 * The framebuffer needs 2 rw port memory. However, many FPGA
 * off-chip memory only has 1 port such as sram, sdram.
 *
 * This module provide a muxing logic to expend the 1 rw port
 * memory to 2 rw ports.
 *
 * Port 2 has priority over port 1.
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_avn_mux #(
    parameter AVN_AW        = 18,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    parameter PENDING_READ  = 4     // maximum pending read
)(
    input                   clk,
    input                   rst,

    // port 1 avalon interface
    input                   port1_avn_read,
    input                   port1_avn_write,
    input  [AVN_AW-1:0]     port1_avn_address,
    input  [AVN_DW-1:0]     port1_avn_writedata,
    input  [AVN_DW/8-1:0]   port1_avn_byteenable,
    output [AVN_DW-1:0]     port1_avn_readdata,
    output                  port1_avn_readdatavalid,
    output                  port1_avn_waitrequest,

    // port 2 avalon interface
    input                   port2_avn_read,
    input                   port2_avn_write,
    input  [AVN_AW-1:0]     port2_avn_address,
    input  [AVN_DW-1:0]     port2_avn_writedata,
    input  [AVN_DW/8-1:0]   port2_avn_byteenable,
    output [AVN_DW-1:0]     port2_avn_readdata,
    output                  port2_avn_readdatavalid,
    output                  port2_avn_waitrequest,

    // output avalon interface
    output                  out_avn_read,
    output                  out_avn_write,
    output [AVN_AW-1:0]     out_avn_address,
    output [AVN_DW-1:0]     out_avn_writedata,
    output [AVN_DW/8-1:0]   out_avn_byteenable,
    input  [AVN_DW-1:0]     out_avn_readdata,
    input                   out_avn_readdatavalid,
    input                   out_avn_waitrequest
);

    logic       fifo_full;
    logic       fifo_write;
    logic       fifo_read;

    logic       port2_grant;
    logic       port2_read_pending;

    assign port2_grant = port2_avn_read | port2_avn_write;

    assign out_avn_read         = (port2_grant ? port2_avn_read : port1_avn_read) & ~fifo_full;
    assign out_avn_write        = port2_grant ? port2_avn_write : port1_avn_write;
    assign out_avn_address      = port2_grant ? port2_avn_address : port1_avn_address;
    assign out_avn_byteenable   = port2_grant ? port2_avn_byteenable : port1_avn_byteenable;
    assign out_avn_writedata    = port2_grant ? port2_avn_writedata : port1_avn_writedata;

    assign port1_avn_readdata       = out_avn_readdata;
    assign port1_avn_waitrequest    = out_avn_waitrequest | port2_grant | (port1_avn_read & fifo_full);
    assign port1_avn_readdatavalid  = out_avn_readdatavalid & ~port2_read_pending;

    assign port2_avn_readdata       = out_avn_readdata;
    assign port2_avn_waitrequest    = out_avn_waitrequest | (port2_avn_read & fifo_full);
    assign port2_avn_readdatavalid  = out_avn_readdatavalid & port2_read_pending;

    assign fifo_read = out_avn_readdatavalid;
    assign fifo_write = out_avn_read & ~out_avn_waitrequest;

    vga_fifo #(
        .WIDTH  (1),
        .DEPTH  (PENDING_READ)
    )
    u_read_pending_fifo(
        .reset  (rst),
        .clk    (clk),
        .push   (fifo_write),
        .pop    (fifo_read),
        .din    (port2_grant),
        .dout   (port2_read_pending),
        .full   (fifo_full),
        .empty  ()
    );

endmodule
