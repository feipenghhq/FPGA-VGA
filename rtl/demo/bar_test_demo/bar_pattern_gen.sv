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
    output logic [9:0]      vga_r,
    output logic [9:0]      vga_g,
    output logic [9:0]      vga_b
);

    always @* begin
        if (vga_vc < `V_DISPLAY / 3) begin  // grayscale
            vga_r = {vga_hc[9:4], 4'hFF};
            vga_g = {vga_hc[9:4], 4'hFF};
            vga_b = {vga_hc[9:4], 4'hFF};
        end
        else if (vga_vc < (`V_DISPLAY / 3) * 2) begin // primary color
            vga_r = {10{vga_hc[8]}};
            vga_g = {10{vga_hc[7]}};
            vga_b = {10{vga_hc[6]}};
        end
        else begin
            vga_r = {{vga_hc[9]}, vga_hc[6:0], 2'b0};
            vga_g = {{vga_hc[8]}, vga_hc[6:0], 2'b0};
            vga_b = {{vga_hc[7]}, vga_hc[6:0], 2'b0};
        end
    end

endmodule
