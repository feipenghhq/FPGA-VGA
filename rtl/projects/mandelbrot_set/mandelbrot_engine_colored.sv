/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/25/2022
 * ---------------------------------------------------------------
 * mandelbrot engine with color
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module mandelbrot_engine_colored #(
    parameter ITERW = 16,   // Iteration width
    parameter DATAW = 32,   // data width
    parameter IMAGW = 28,   // imag width
    parameter RCNTW = 10,   // real counter width
    parameter ICNTW = 10    // imag counter width
) (
    input                       clk,
    input                       rst,

    input [ITERW-1:0]           max_iteration,

    input                       start,
    input                       stall,

    // starting position of the mandelbrot and delta value
    input [DATAW-1:0]           start_real,
    input [DATAW-1:0]           start_imag,

    input [DATAW-1:0]           delta_real,
    input [DATAW-1:0]           delta_imag,

    // number of real and imag to be calculated
    input [RCNTW-1:0]           real_size,
    input [ICNTW-1:0]           imag_size,

    output [RCNTW-1:0]          real_cnt,
    output [ICNTW-1:0]          imag_cnt,
    output [`RGB_SIZE-1:0]      color,
    output                      valid
);

    logic [ITERW-1:0]   engine_iteration;
    logic               engine_diverged;

    mandelbrot_engine #(
      .IMAGW            (IMAGW),
      .DATAW            (DATAW),
      .ITERW            (ITERW),
      .RCNTW            (RCNTW),
      .ICNTW            (ICNTW))
    u_mandelbrot_engine (
      .clk,
      .rst,
      .max_iteration,
      .start,
      .stall,
      .delta_real,
      .delta_imag,
      .start_real,
      .start_imag,
      .real_size,
      .imag_size,
      .real_cnt,
      .imag_cnt,
      .iteration (engine_iteration),
      .diverged (engine_diverged),
      .valid
    );

    mandelbrot_coloring #(
      .ITERW (ITERW))
    u_mandelbrot_coloring (
      .max_iteration,
      .diverged (engine_diverged),
      .iteration (engine_iteration),
      .color
    );

endmodule