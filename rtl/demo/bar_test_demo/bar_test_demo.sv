/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/29/2022
 * ---------------------------------------------------------------
 * Demonstratation using VGA sync module and pattern generator
 * ---------------------------------------------------------------
 */

`include "vga_timing.svh"

module bar_test_demo (
    input           pixel_clk,
    input           reset,
    output          vga_hsync,
    output          vga_vsync,
    output [9:0]    vga_r,
    output [9:0]    vga_g,
    output [9:0]    vga_b,
    output          vga_on
);


    logic [`H_SIZE-1:0]  vga_hc;
    logic [`V_SIZE-1:0]  vga_vc;

    /*AUTOWIRE*/

    /*AUTOREG*/

    vga_sync u_vga_sync
    (/*AUTOINST*/
     // Outputs
     .vga_hsync                         (vga_hsync),
     .vga_vsync                         (vga_vsync),
     .vga_hc                            (vga_hc[`H_SIZE-1:0]),
     .vga_vc                            (vga_vc[`V_SIZE-1:0]),
     .vga_on                            (vga_on),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .reset                             (reset));


    bar_pattern_gen u_bar_pattern_gen
    (/*AUTOINST*/
     // Outputs
     .vga_r                             (vga_r[9:0]),
     .vga_g                             (vga_g[9:0]),
     .vga_b                             (vga_b[9:0]),
     // Inputs
     .pixel_clk                         (pixel_clk),
     .reset                             (reset),
     .vga_hc                            (vga_hc[`H_SIZE-1:0]),
     .vga_vc                            (vga_vc[`V_SIZE-1:0]));


endmodule

// Local Variables:
// verilog-library-flags:("-y ../../vga/")
// End:
