/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/30/2022
 * ---------------------------------------------------------------
 * Rgb2gray generator
 *
 * We use luminosity to convert RGB to GRAY
 * Luminosity method: gray = 0.21 ∗ r + 0.72 ∗ g + 0.07 ∗ b
 *
 * This module has a latency of 2
 *
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */


module rgb2gray_gen #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = RSIZE + GSIZE + BSIZE
) (
    input                   clk,
    input                   rst,
    input  [RGB_SIZE-1:0]   src_rgb,
    output [RGB_SIZE-1:0]   snk_rgb
);

    // conver the weight into 8 bit values
    localparam RW = 53;   // 21 / 100 * 256
    localparam GW = 184;  // 72 / 100 * 256
    localparam BW = 18;   // 7 / 100 * 256

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic [RSIZE-1:0]     s0_r;
    logic [GSIZE-1:0]     s0_g;
    logic [BSIZE-1:0]     s0_b;

    logic [RSIZE-1:0]     snk_r;
    logic [GSIZE-1:0]     snk_g;
    logic [BSIZE-1:0]     snk_b;

    reg [RGB_SIZE-1:0]    rgb_s0;
    reg [RGB_SIZE+8-1:0]  rgb_s1;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign {s0_r, s0_g, s0_b} = rgb_s0;

    always @(posedge clk) begin
        rgb_s0 <= src_rgb;
        rgb_s1 <= s0_r * RW + s0_g * GW + s0_b * BW;
    end

    assign snk_r = rgb_s1[RGB_SIZE+8-1:RGB_SIZE+8-1-RSIZE+1];
    assign snk_g = rgb_s1[RGB_SIZE+8-1:RGB_SIZE+8-1-GSIZE+1];
    assign snk_b = rgb_s1[RGB_SIZE+8-1:RGB_SIZE+8-1-BSIZE+1];
    assign snk_rgb = {snk_r, snk_g, snk_b};

endmodule