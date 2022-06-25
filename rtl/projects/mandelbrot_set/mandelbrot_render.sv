/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/23/2022
 * ---------------------------------------------------------------
 * mandelbrot set render
 *
 * Render the mandelbrot set to the screen
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module mandelbrot_render #(
    parameter ITERW = 16,   // Iteration width
    parameter DATAW = 32,   // data width
    parameter IMAGW = 28,   // imag width
    parameter AVN_AW = 19,
    parameter AVN_DW = 16
) (
    input                   clk,
    input                   rst,

    input [ITERW-1:0]       max_iteration,
    input                   start,

    output reg [AVN_AW-1:0] mandelbrot_avn_address,
    output reg              mandelbrot_avn_write,
    output reg [AVN_DW-1:0] mandelbrot_avn_writedata,
    input                   mandelbrot_avn_waitrequest
);

    localparam [DATAW-1:0] DELTA_REAL = (3 << IMAGW) / `H_DISPLAY;
    localparam [DATAW-1:0] DELTA_IMAG = (2 << IMAGW) / `V_DISPLAY;
    localparam [DATAW-1:0] START_REAL = (-2) << IMAGW;
    localparam [DATAW-1:0] START_IMAG = (-1) << IMAGW;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic                   engine_start;
    logic                   engine_stall;
    logic [`H_SIZE-1:0]     engine_cur_real_cnt;
    logic [`V_SIZE-1:0]     engine_cur_imag_cnt;
    logic [ITERW-1:0]       engine_iteration;
    logic                   engine_diverged;
    logic                   engine_valid;

    logic [`RGB_SIZE-1:0]   engine_color;

    // --------------------------------
    // main logic
    // --------------------------------


    always @(posedge clk) begin
        /* verilator lint_off WIDTH */
        if (engine_valid) begin
            mandelbrot_avn_address <= engine_cur_real_cnt + engine_cur_imag_cnt * `H_DISPLAY;
            mandelbrot_avn_writedata <= engine_color;
        end
        /* verilator lint_on WIDTH */
        mandelbrot_avn_write <= engine_valid | (mandelbrot_avn_waitrequest & mandelbrot_avn_write);
    end

    assign engine_stall = mandelbrot_avn_waitrequest;
    assign engine_start = start;

    // --------------------------------
    // Module initialization
    // --------------------------------

    mandelbrot_engine_colored #(
      .IMAGW            (IMAGW),
      .DATAW            (DATAW),
      .ITERW            (ITERW),
      .RCNTW            (`H_SIZE),
      .ICNTW            (`V_SIZE))
    u_mandelbrot_engine_colored (
      .clk              (clk),
      .rst              (rst),
      .max_iteration    (max_iteration),
      .start            (engine_start),
      .stall            (engine_stall),
      .delta_real       (DELTA_REAL),
      .delta_imag       (DELTA_IMAG),
      .start_real       (START_REAL),
      .start_imag       (START_IMAG),
      .real_size        (`H_DISPLAY),
      .imag_size        (`V_DISPLAY),
      .real_cnt         (engine_cur_real_cnt),
      .imag_cnt         (engine_cur_imag_cnt),
      .color            (engine_color),
      .valid            (engine_valid)
    );

endmodule