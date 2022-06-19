/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/09/2022
 * ---------------------------------------------------------------
 * Sprite display logic with animation
 *
 * - The main function is similar to video_sprite_core
 * Here is the difference:
 * - The sprite ram contains multiple sprite images to show animation.
 * - The upper bits of the sprite ram address are index to different sprite images
 * - The sprite image will be changing in a fixed rate to create the animation
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_sprite_animation_core #(
    parameter SPRITE_HSIZE  = 32,
    parameter SPRITE_VSIZE  = 32,
    parameter SPRITE_AW     = 10,
    parameter SPRITE_IDXW   = 2,                        // Sprite image index width
    parameter SPRITE_RAM_AW = SPRITE_AW + SPRITE_IDXW,  // Sprite RAM address width
    parameter SPRITE_NUM    = 4,                        // number of sprite images in the sprite ram
    parameter KEY_COLOR     = 0,
    parameter MEM_FILE      = ""
) (
    input                       clk,
    input                       rst,

    input                       stall,
    input                       bypass,
    input [31:0]                sprite_rate,

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

    // stage 0
    logic signed [`H_SIZE-1:0]  x_s0;
    logic signed [`V_SIZE-1:0]  y_s0;
    logic [SPRITE_AW-1:0]       sprite_position_s0;
    logic [SPRITE_RAM_AW-1:0]   sprite_ram_addr_r_s0;
    logic                       x_in_region_s0;
    logic                       y_in_region_s0;
    logic                       in_region_s0;

    reg [SPRITE_IDXW-1:0]       sprite_idx_s0;
    reg [31:0]                  sprite_rate_counter_s0;
    logic                       sprite_rate_counter_fire_s0;

    // stage 1
    vga_frame_t                 source_frame_s1;
    reg                         source_vld_s1;
    reg                         in_region_s1;

    logic [`RGB_SIZE-1:0]       sprite_ram_dout_s1;
    logic [`R_SIZE-1:0]         sprite_r_s1;
    logic [`G_SIZE-1:0]         sprite_g_s1;
    logic [`B_SIZE-1:0]         sprite_b_s1;

    logic                       key_match_s1;
    logic                       bypass_final_s1;

     // --------------------------------
    // Main logic
    // --------------------------------

    //
    // stage 0: calculate the position of the sprite and read the sprite memory
    //

    //
    // The sprite ram is one-dimensional but the sprite coordinates is two-dimensional,
    // so we need to map the sprite coordinates x, y into one-dimension value to index the memory.
    // To do this, we use the following mapping funtion:
    //      ram_addr = x + y * SPRITE_X_SIZE        (1)

    // substract the hc, vc coordinates from its origin to get the sprite coordinates
    assign x_s0 = source_frame.hc - x0[`H_SIZE-1:0];
    assign y_s0 = source_frame.vc - y0[`V_SIZE-1:0];

    // check if the x, y coordinates is in the sprite region or not,
    assign x_in_region_s0 = x_s0 >= 0 & (x_s0 < SPRITE_HSIZE);
    assign y_in_region_s0 = y_s0 >= 0 & (y_s0 < SPRITE_VSIZE);
    assign in_region_s0 = x_in_region_s0 & y_in_region_s0;

    // convert the x,y coordinates to ram address
    assign sprite_position_s0 = x_s0 + y_s0 * SPRITE_HSIZE;
    assign sprite_ram_addr_r_s0 = {sprite_idx_s0, sprite_position_s0};

    // sprite index
    assign sprite_rate_counter_fire_s0 = sprite_rate_counter_s0 == 0;
    always @(posedge clk) begin
        if (rst) begin
            sprite_rate_counter_s0 <= 0;
            sprite_idx_s0 <= 0;
        end
        else begin
            if (sprite_rate_counter_fire_s0) sprite_rate_counter_s0 <= sprite_rate;
            else if (source_vld && !stall) sprite_rate_counter_s0 <= sprite_rate_counter_s0 - 1'b1;
            if (sprite_rate_counter_fire_s0) begin
                if (sprite_idx_s0 == SPRITE_NUM[SPRITE_IDXW-1:0]-1) sprite_idx_s0 <= 0;
                else sprite_idx_s0 <= sprite_idx_s0 + 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) source_vld_s1 <= 0;
        else if (!stall) source_vld_s1 <= source_vld;
    end

    always @(posedge clk) begin
        if (!stall) begin
            // stage 0
            in_region_s1 <= in_region_s0;
            source_frame_s1 <= source_frame;
        end
    end



    //
    // stage 1: get the sprite pixel data from the sprite ram
    //

    assign key_match_s1 = sprite_ram_dout_s1 == KEY_COLOR; // chroma−key blending and multiplixing
    assign bypass_final_s1 = bypass | ~in_region_s1 | key_match_s1;
    assign {sprite_r_s1, sprite_g_s1, sprite_b_s1} = sprite_ram_dout_s1;

    always @(posedge clk) begin
        if (rst) sink_vld <= 0;
        else if (!stall) sink_vld <= source_vld_s1;
    end

    always @(posedge clk) begin
        if (!stall) begin
            sink_frame.hc <= source_frame_s1.hc;
            sink_frame.vc <= source_frame_s1.vc;
            sink_frame.start <= source_frame_s1.start;
            sink_frame.r <= bypass_final_s1 ? source_frame_s1.r : sprite_r_s1;
            sink_frame.g <= bypass_final_s1 ? source_frame_s1.g : sprite_g_s1;
            sink_frame.b <= bypass_final_s1 ? source_frame_s1.b : sprite_b_s1;
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
        .en     (~stall),
        .addr_w (sprite_ram_addr_w),
        .addr_r (sprite_ram_addr_r_s0),
        .din    (sprite_ram_din),
        .dout   (sprite_ram_dout_s1)
    );

endmodule
