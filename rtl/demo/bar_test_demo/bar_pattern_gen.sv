/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/29/2022
 * ---------------------------------------------------------------
 * Bar test pattern generator
 * ---------------------------------------------------------------
 */

`include "vga_timing.svh"

module bar_pattern_gen (
    input                   pixel_clk,
    input                   reset,
    input  [`H_SIZE-1:0]    vga_hc,
    input  [`V_SIZE-1:0]    vga_vc,
    output [9:0]            vga_r,
    output [9:0]            vga_g,
    output [9:0]            vga_b
);

    // FIXME
    assign vga_r = 0;
    assign vga_g = 'hFF;
    assign vga_b = 0;

endmodule
