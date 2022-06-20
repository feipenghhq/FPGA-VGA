/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/30/2022
 * ---------------------------------------------------------------
 * Bar pattern generator core
 *
 * This core generate 3 patterns
 * 1. 16 shade of gray color
 * 2. 8 prime color
 * 3. a continuous rainbow color spectrum
 *
 * ---------------------------------------------------------------
 */


`include "vga.svh"

module video_bar_core (
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

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic [3:0]     up;
    logic [3:0]     down;
    logic [3:0]     bar_r;  // size is fixed to 4 bits here
    logic [3:0]     bar_g;
    logic [3:0]     bar_b;

    logic [`R_SIZE-1:0]  frame_r;
    logic [`G_SIZE-1:0]  frame_g;
    logic [`B_SIZE-1:0]  frame_b;

    // --------------------------------
    // Main logic
    // --------------------------------

    // bar generation logic
    assign up = source_frame.hc[6:3];
    assign down = 4'd15 - source_frame.hc[6:3];

    always @* begin
        // 16 shade of gray
        if (source_frame.vc < `V_DISPLAY / 3) begin
            bar_r = {source_frame.hc[8:5]};
            bar_g = {source_frame.hc[8:5]};
            bar_b = {source_frame.hc[8:5]};
        end
        // 8 primary color
        else if (source_frame.vc < (`V_DISPLAY / 3) * 2) begin
            bar_r = {4{source_frame.hc[8]}};
            bar_g = {4{source_frame.hc[7]}};
            bar_b = {4{source_frame.hc[6]}};
        end
        // a continuous "rain bow" color spectrum
        else begin
            case(source_frame.hc[9:7])
                3'b000: begin
                    bar_r = 4'b1111;
                    bar_g = up;
                    bar_b = 4'b0000;
                end
                3'b001: begin
                    bar_r = down;
                    bar_g = 4'b1111;
                    bar_b = 4'b0000;
                end
                3'b010: begin
                    bar_r = 4'b0000;
                    bar_g = 4'b1111;
                    bar_b = up;
                end
                3'b011: begin
                    bar_r = 4'b0000;
                    bar_g = down;
                    bar_b = 4'b1111;
                end
                3'b100: begin
                    bar_r = up;
                    bar_g = 4'b0000;
                    bar_b = 4'b1111;
                end
                3'b101: begin
                    bar_r = 4'b1111;
                    bar_g = 4'b0000;
                    bar_b = down;
                end
                default: begin
                    bar_r = 4'b1111;
                    bar_g = 4'b1111;
                    bar_b = 4'b1111;
                end
            endcase
        end
    end

    // assume the frame rgb size is greater then or equal to the bar rgb
    assign frame_r = bar_r;
    assign frame_g = bar_g;
    assign frame_b = bar_b;

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
            sink_frame.r <= bypass ? source_frame.r : frame_r;
            sink_frame.g <= bypass ? source_frame.g : frame_g;
            sink_frame.b <= bypass ? source_frame.b : frame_b;
        end
    end

endmodule
