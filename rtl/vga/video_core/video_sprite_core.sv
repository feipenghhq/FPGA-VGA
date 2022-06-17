/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/05/2022
 * ---------------------------------------------------------------
 * Sprite display logic
 *
 * - Given a x, y coordinate of the current display pixel,
 *   read the pixel from sprite ram and return the RGB color of
 *   the pixel
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_sprite_core #(
    parameter SPRITE_HSIZE  = 32,
    parameter SPRITE_VSIZE  = 32,
    parameter SPRITE_RAM_AW = 10,
    parameter KEY_COLOR     = 0,
    parameter MEM_FILE      = ""
) (
    input                       clk,
    input                       rst,

    input                       stall,
    input                       bypass,

    // up stream
    input                       source_vld,
    input vga_frame_t           source_frame,

    // down stream
    output reg                  sink_vld,
    output vga_frame_t          sink_frame,

    // origin of the sprite
    input [31:0]                x0,
    input [31:0]                y0,

    // sprite memory interface
    input                       sprite_ram_we,
    input [SPRITE_RAM_AW-1:0]   sprite_ram_addr_w,
    input [`RGB_SIZE-1:0]       sprite_ram_din
);

    // --------------------------------
    // Signal Declaration
    // --------------------------------

    logic signed [`H_SIZE-1:0] x;
    logic signed [`V_SIZE-1:0] y;

    logic [SPRITE_RAM_AW-1:0]   sprite_ram_addr_r;
    logic [`RGB_SIZE-1:0]       sprite_ram_dout;

    reg                         x_in_region;
    reg                         y_in_region;

    logic                       key_match;
    logic                       bypass_final;

    logic [`R_SIZE-1:0]         sprite_r;
    logic [`G_SIZE-1:0]         sprite_g;
    logic [`B_SIZE-1:0]         sprite_b;

    vga_frame_t                 source_frame_s0;
    reg                         source_vld_s0;

    // --------------------------------
    // Main logic
    // --------------------------------

    //
    // The sprite ram is one-dimensional but the sprite coordinates is two-dimensional,
    // so we need to map the sprite coordinates x, y into one-dimension value to index the memory.
    // To do this, we use the following mapping funtion:
    //      ram_addr = x + y * SPRITE_X_SIZE        (1)

    // substract the hc, vc coordinates from its origin to get the sprite coordinates
    assign x = source_frame.hc - x0[`H_SIZE-1:0];
    assign y = source_frame.vc - y0[`V_SIZE-1:0];

    // check if the x, y coordinates is in the sprite region or not,
    always @(posedge clk) begin
        x_in_region <= x >= 0 & (x < SPRITE_HSIZE);
        y_in_region <= y >= 0 & (y < SPRITE_VSIZE);
    end

    // convert the x,y coordinates to ram address
    assign sprite_ram_addr_r = x + y * SPRITE_HSIZE;

    // chroma−key blending and multiplixing
    assign key_match = sprite_ram_dout == KEY_COLOR;
    assign bypass_final = bypass | ~x_in_region | ~y_in_region | key_match;
    assign {sprite_r, sprite_g, sprite_b} = sprite_ram_dout;

    // pipeline stage - 2 stages
    always @(posedge clk) begin
        if (rst) begin
            source_vld_s0 <= 0;
            sink_vld <= 0;
        end
        else if (!stall) begin
            source_vld_s0 <= source_vld;
            sink_vld <= source_vld_s0;
        end
    end

    always @(posedge clk) begin
        if (!stall) begin
            source_frame_s0 <= source_frame;

            sink_frame.hc <= source_frame_s0.hc;
            sink_frame.vc <= source_frame_s0.vc;
            sink_frame.start <= source_frame_s0.start;
            sink_frame.r <= bypass_final ? source_frame_s0.r : sprite_r;
            sink_frame.g <= bypass_final ? source_frame_s0.g : sprite_g;
            sink_frame.b <= bypass_final ? source_frame_s0.b : sprite_b;
        end
    end


    // --------------------------------
    // Module initialization
    // --------------------------------

    vga_ram_1r1w
    #(
        .AW         (SPRITE_RAM_AW),
        .DW         (`RGB_SIZE),
        .MEM_FILE   (MEM_FILE)
    )
    u_sprite_ram
    (
        .clk    (clk),
        .we     (sprite_ram_we),
        .addr_w (sprite_ram_addr_w),
        .addr_r (sprite_ram_addr_r),
        .din    (sprite_ram_din),
        .dout   (sprite_ram_dout)
    );

endmodule
