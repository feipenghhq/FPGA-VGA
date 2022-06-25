/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/24/2022
 * ---------------------------------------------------------------
 * Give color to mandelbrot set
 * ---------------------------------------------------------------
 * Reference:
 * https://vanhunteradams.com/DE1/Mandelbrot/Mandelbrot.html#Increasing-resolution-and-colorizing
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module mandelbrot_coloring #(
    parameter ITERW = 16    // iteration width
) (
    input [ITERW-1:0]               max_iteration,
    input [ITERW-1:0]               iteration,
    input                           diverged,
    output logic [`RGB_SIZE-1:0]    color
);

    logic [`R_SIZE-1:0] r;
    logic [`G_SIZE-1:0] g;
    logic [`B_SIZE-1:0] b;

    `define MS_COLOR_3

    `ifdef MS_COLOR_0
    // map iteration directly to RGB color
    assign color = diverged ? iteration[`RGB_SIZE-1:0] : 0;
    `endif

    `ifdef MS_COLOR_1
    // use only black and white color
    assign color = diverged ? {`RGB_SIZE{1'b1}} : 0;
    `endif

    `ifdef MS_COLOR_2
    // map iteration mod 8 to 8 color patterns
    assign r = {`R_SIZE{iteration[2]}};
    assign g = {`R_SIZE{iteration[1]}};
    assign b = {`R_SIZE{iteration[0]}};
    assign color = diverged ? {r, g, b} : 0;
    `endif

    `ifdef MS_COLOR_3
    logic r0, g0, b0;
    logic [7:0] pattern;

    genvar i;
    generate
        for (i = 0; i < 7; i++) begin: gen_pattern
            assign pattern[i] = (iteration[i*2+1:i*2] > 0);
        end
    endgenerate

    always @* begin
        casez(pattern)
            8'b1???_????: {r0, g0, b0} = 3'd7;
            8'b01??_????: {r0, g0, b0} = 3'd6;
            8'b001?_????: {r0, g0, b0} = 3'd5;
            8'b0001_????: {r0, g0, b0} = 3'd4;
            8'b0000_1???: {r0, g0, b0} = 3'd3;
            8'b0000_01??: {r0, g0, b0} = 3'd2;
            8'b0000_001?: {r0, g0, b0} = 3'd1;
            8'b0000_0001: {r0, g0, b0} = 3'd0;
            default: {r0, g0, b0} = 3'd0;
        endcase
    end

    assign r = {`R_SIZE{r0}};
    assign g = {`G_SIZE{g0}};
    assign b = {`B_SIZE{b0}};
    assign color = diverged ? {r, g, b} : 0;

    `endif

endmodule