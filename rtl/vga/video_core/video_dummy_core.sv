/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Video Dummy core
 * - Feed the input directly to the output
 * - Optional pipeline module
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_dummy_core (
    input                   clk,
    input                   rst,

    input                   stall,

    // up stream
    input                   source_vld,
    input vga_frame_t       source_frame,

    // down stream
    output reg              sink_vld,
    output vga_frame_t      sink_frame
);

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
            sink_frame <= source_frame;
        end
    end

endmodule