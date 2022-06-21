/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * FWFT Asynchronous FIFO for VGA
 * ---------------------------------------------------------------
 */


module vga_async_fifo_fwft #(
    parameter WIDTH  = 32,              // Data width
    parameter DEPTH  = 16,              // FIFO depth
    parameter AWIDTH = $clog2(DEPTH),
    parameter AFULL_THRES = 1
) (
    // Read side
    input               rst_rd,
    input               clk_rd,
    input               read,
    output [WIDTH-1:0]  dout,
    output              empty,
    // Write side
    input               rst_wr,
    input               clk_wr,
    input [WIDTH-1:0]   din,
    input               write,
    output              full,
    output              afull
);

    reg         preloaded;
    wire        fifo_empty;
    wire        fifo_read;

    always @(posedge clk_rd) begin
        if (rst_rd) begin
            preloaded <= 1'b0;
        end
        else begin
            // set preloaded: when not preload and fifo is not empty => preload the data to fifo output port
            if (fifo_read) preloaded <= 1'b1;
            // clear preloaded: when fifo is empty (meaning no more data in the fifo) and we are still reading
            // (it is ok to read at this time because we have preloaded the fifo)
            else if (fifo_empty && read) preloaded <= 1'b0;
        end
    end

    // when not preloaded, fifo is empty
    assign empty = ~preloaded;

    // when not preload and fifo is not empty => preload the data to fifo output port
    assign fifo_read = (~preloaded & ~fifo_empty) | (read & ~fifo_empty);

    vga_async_fifo #(
      .WIDTH          (WIDTH),
      .DEPTH          (DEPTH),
      .AFULL_THRES    (AFULL_THRES))
    u_vga_async_fifo
    (
      .rst_rd       (rst_rd),
      .clk_rd       (clk_rd),
      .read         (fifo_read),
      .dout         (dout),
      .empty        (fifo_empty),
      .rst_wr       (rst_wr),
      .clk_wr       (clk_wr),
      .din          (din),
      .write        (write),
      .full         (full),
      .afull        (afull)
    );

endmodule
