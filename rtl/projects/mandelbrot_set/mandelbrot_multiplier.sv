/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/25/2022
 * ---------------------------------------------------------------
 * mandelbrot multiplier
 *
 * Use fixed point notation to represent decimal numbers
 * ---------------------------------------------------------------
 */

module mandelbrot_multiplier #(
    parameter RW = 4,       // real part width
    parameter IW = 28,      // imag part width
    parameter W = RW + IW
) (
    input                   clk,
    input                   rst,
    input signed [W-1:0]    a,
    input signed [W-1:0]    b,
    output signed [W-1:0]   o
);


    reg signed [2*W-1:0] mult_result;

    always @(posedge clk) mult_result <= a * b;

    assign o = mult_result[W+IW-1:IW];

endmodule
