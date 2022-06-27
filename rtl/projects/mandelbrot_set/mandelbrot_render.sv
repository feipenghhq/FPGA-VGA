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

    input                   zoom_in,            // zoom in the picture
    input                   zoom_out,           // zoom out the picture
    output reg [3:0]        zoom_level,         // zoom level

    input                   start_ovd,
    input [DATAW-1:0]       start_real_ovd,
    input [DATAW-1:0]       start_imag_ovd,

    output reg [AVN_AW-1:0] mandelbrot_avn_address,
    output reg              mandelbrot_avn_write,
    output reg [AVN_DW-1:0] mandelbrot_avn_writedata,
    input                   mandelbrot_avn_waitrequest
);

    localparam [DATAW-1:0] DELTA_REAL = (3 << IMAGW) / `H_DISPLAY;
    localparam [DATAW-1:0] DELTA_IMAG = (2 << IMAGW) / `V_DISPLAY;
    localparam signed [DATAW-1:0] START_REAL = (-2) << IMAGW;
    localparam signed [DATAW-1:0] START_IMAG = (-1) << IMAGW;
    localparam [DATAW-1-4:0] REAL_RANGE_DELTA = (3 << IMAGW) >> 4;
    localparam [DATAW-1-4:0] IMAG_RANGE_DELTA = (2 << IMAGW) >> 4;

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

    reg [DATAW-1:0]         delta_real;
    reg [DATAW-1:0]         delta_imag;
    reg [DATAW-1:0]         start_real;
    reg [DATAW-1:0]         start_imag;

    // --------------------------------
    // main logic
    // --------------------------------

    // determine the zoom level, starting point and delta value
    always @(posedge clk) begin
        if (rst) zoom_level <= 0;
        else begin
            if (zoom_in) zoom_level <= zoom_level + 1;
            else if (zoom_out) zoom_level <= zoom_level - 1;
        end
    end

    always @(posedge clk) begin
        delta_real = DELTA_REAL >>> zoom_level;
        delta_imag = DELTA_IMAG >>> zoom_level;
        start_real <= start_ovd ? start_real_ovd : START_REAL;
        start_imag <= start_ovd ? start_imag_ovd : START_IMAG;
    end

    // write the color to vram
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
      .delta_real       (delta_real),
      .delta_imag       (delta_imag),
      .start_real       (start_real),
      .start_imag       (start_imag),
      .real_size        (`H_DISPLAY),
      .imag_size        (`V_DISPLAY),
      .real_cnt         (engine_cur_real_cnt),
      .imag_cnt         (engine_cur_imag_cnt),
      .color            (engine_color),
      .valid            (engine_valid)
    );

endmodule