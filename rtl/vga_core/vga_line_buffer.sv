/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA line buffer
 *
 * - Asynchronous FIFO storing ONE line of the frame.
 * - The source is from upstream processing/generation logic
 * - The sink goes to the vga_sync module
 * ---------------------------------------------------------------
 */

module vga_line_buffer #(
    parameter RGB_SIZE = 12
) (
    // from source
    input               src_rst,
    input               src_clk,
    input [RGB_SIZE:0]  src_data,
    input               src_vld,
    output              src_rdy,
    // to sink
    input               snk_rst,
    input               snk_clk,
    output [RGB_SIZE:0] snk_data,
    output              snk_vld,
    input               snk_rdy
);

    localparam WIDTH = RGB_SIZE+1;
    localparam DEPTH = 1024;

    logic [WIDTH-1:0]       din;
    logic [WIDTH-1:0]       dout;
    logic                   empty;
    logic                   full;
    logic                   read;
    logic                   write;

    /*AUTOREG*/

    /*AUTOWIRE*/

    assign src_rdy = ~full;
    assign snk_vld = ~empty;
    assign write = src_vld & src_rdy;
    assign read = snk_rdy & snk_vld;

    /* vga_async_fifo AUTO_TEMPLATE (
        .clk_wr     (src_clk),
        .rst_wr     (src_rst),
        .din        (src_data),
        .clk_rd     (snk_clk),
        .rst_rd     (snk_rst),
        .dout       (snk_data),
    );
    */
    vga_async_fifo
    #(
      // Parameters
      .WIDTH                            (WIDTH),
      .DEPTH                            (DEPTH))
    u_vga_async_fifo
    (/*AUTOINST*/
     // Outputs
     .dout                              (snk_data),              // Templated
     .empty                             (empty),
     .full                              (full),
     // Inputs
     .rst_rd                            (snk_rst),               // Templated
     .clk_rd                            (snk_clk),               // Templated
     .read                              (read),
     .rst_wr                            (src_rst),               // Templated
     .clk_wr                            (src_clk),               // Templated
     .din                               (src_data),              // Templated
     .write                             (write));


endmodule
