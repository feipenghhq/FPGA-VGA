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
 * NOTES: This module has fixed latency of 2 (dut to multiplication)
 *
 * ---------------------------------------------------------------
 */

`define video_rgb2gray_gen_max(x, y)  (x > y ? x : y)

module video_rgb2gray_gen #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = RSIZE + GSIZE + BSIZE
) (
    input                   clk,
    input                   rst,
    input                   rgb_in_vld,
    output                  rgb_in_rdy,
    input  [RGB_SIZE-1:0]   rgb_in,
    output                  rgb_out_vld,
    input                   rgb_out_rdy,
    output [RGB_SIZE-1:0]   rgb_out
);

    // conver the weight into 8 bit values
    localparam RW = 53;   // 21 / 100 * 256
    localparam GW = 184;  // 72 / 100 * 256
    localparam BW = 18;   // 7 / 100 * 256

    localparam SIZE = RGB_SIZE / 3;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic [RSIZE-1:0]       s0_r;
    logic [GSIZE-1:0]       s0_g;
    logic [BSIZE-1:0]       s0_b;
    logic [SIZE-1:0]        gray;

    logic                   s0_rdy;
    logic                   s0_vld;
    logic [RGB_SIZE-1:0]    s0_data;
    logic [RGB_SIZE-1:0]    s0_data_post;

    logic [RGB_SIZE-1:0]    s1_data;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign {s0_r, s0_g, s0_b} = s0_data;
    assign s0_data_post = s0_r * RW + s0_g * GW + s0_b * BW;
    assign gray = s1_data[RGB_SIZE-1-:SIZE];
    assign rgb_out = {gray, gray, gray};

    // --------------------------------
    // Pipeline module
    // --------------------------------

    video_data_pipeline
    #(.WIDTH(RGB_SIZE), .PIPELINE(1))
    u_stage_0
    (.clk(clk),                  .rst(rst),
     .pipe_in_vld(rgb_in_vld),   .pipe_in_rdy(rgb_in_rdy),   .pipe_in_data(rgb_in),
     .pipe_out_rdy(s0_rdy),      .pipe_out_vld(s0_vld),      .pipe_out_data(s0_data)
    );

    video_data_pipeline
    #(.WIDTH(RGB_SIZE), .PIPELINE(1))
    u_stage_1
    (.clk(clk),                     .rst(rst),
     .pipe_in_vld(s0_vld),          .pipe_in_rdy(s0_rdy),       .pipe_in_data(s0_data_post),
     .pipe_out_rdy(rgb_out_rdy),    .pipe_out_vld(rgb_out_vld), .pipe_out_data(s1_data)
    );


endmodule
