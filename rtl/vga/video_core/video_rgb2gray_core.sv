/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/30/2022
 * ---------------------------------------------------------------
 * rgb2gray generator - convert the RGB color to Gray scale
 *
 * We use luminosity algorithm to convert RGB to GRAY
 * Luminosity method: gray = 0.21 ∗ r + 0.72 ∗ g + 0.07 ∗ b
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_rgb2gray_core (
    input                   clk,
    input                   rst,

    input                   stall,
    input                   bypass,

    // up stream
    input                   source_vld,
    input vga_frame_t       source_frame,

    // down stream
    output reg              sink_vld,
    output vga_frame_t      sink_frame
);

    // conver the weight into 8 bit values
    localparam logic [7:0] RW = 53;   // 21 / 100 * 256
    localparam logic [7:0] GW = 184;  // 72 / 100 * 256
    localparam logic [7:0] BW = 18;   //  7 / 100 * 256

    localparam GRAY_SIZE = `RGB_SIZE / 3;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic [`R_SIZE-1:0]         s0_r;
    logic [`G_SIZE-1:0]         s0_g;
    logic [`B_SIZE-1:0]         s0_b;
    logic [`RGB_SIZE-1:0]       s0_result;
    logic [GRAY_SIZE-1:0]       s0_gray;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign s0_r = source_frame.r;
    assign s0_g = source_frame.g;
    assign s0_b = source_frame.b;

    assign s0_result = s0_r * RW + s0_g * GW + s0_b * BW;
    assign s0_gray  = s0_result[`RGB_SIZE-1-:GRAY_SIZE];

    // pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            sink_vld <= 0;
        end
        else if (!stall) begin
            sink_vld <= source_vld;
        end
    end

    always @(posedge clk) begin
        if (!stall) begin
            sink_frame.hc <= source_frame.hc;
            sink_frame.vc <= source_frame.vc;
            sink_frame.start <= source_frame.start;
            sink_frame.r <= bypass ? source_frame.r : s0_gray;
            sink_frame.g <= bypass ? source_frame.g : s0_gray;
            sink_frame.b <= bypass ? source_frame.b : s0_gray;
        end
    end

endmodule
