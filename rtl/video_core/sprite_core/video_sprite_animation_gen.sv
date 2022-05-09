/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/09/2022
 * ---------------------------------------------------------------
 * Sprite generation logic with animation
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

`include "vga.svh"

 module video_sprite_animation_gen #(
    parameter RGB_SIZE      = 12,
    parameter SPRITE_HSIZE  = 32,
    parameter SPRITE_VSIZE  = 32,
    parameter SPRITE_AW     = 10,
    parameter SPRITE_IDXW   = 2,
    parameter SPRITE_RAM_AW = SPRITE_AW + SPRITE_IDXW,
    parameter SPRITE_NUM    = 4,
    parameter KEY_COLOR     = 0,
    parameter MEM_FILE      = ""
) (
    input                       clk,
    input                       rst,

    // origin of othe sprite
    input [31:0]                x0,
    input [31:0]                y0,
    input [31:0]                sprite_rate,
    input                       sprite_vld,
    // sprite memory interface
    input                       sprite_ram_we,
    input [SPRITE_RAM_AW-1:0]   sprite_ram_addr_w,
    input [RGB_SIZE-1:0]        sprite_ram_din,

    // vga interface
    input [`H_SIZE-1:0]         xx,
    input [`V_SIZE-1:0]         yy,
    input  [RGB_SIZE-1:0]       src_rgb,
    output [RGB_SIZE-1:0]       sprite_rgb
);

    // --------------------------------
    // Signal Declaration
    // --------------------------------

    logic signed [`H_SIZE-1:0] x;
    logic signed [`V_SIZE-1:0] y;

    logic x_in_region;
    logic y_in_region;
    logic xy_in_region;
    logic key_match;

    logic [SPRITE_AW-1:0]       sprite_addr;
    logic [SPRITE_RAM_AW-1:0]   sprite_ram_addr_r;
    logic [RGB_SIZE-1:0]        sprite_ram_dout;

    reg [SPRITE_IDXW-1:0]       sprite_idx;
    reg [31:0]                  sprite_rate_counter;

    logic                       sprite_rate_counter_fire;

    // --------------------------------
    // Main logic
    // --------------------------------

    //
    // The sprite ram is one-dimensional but the sprite coordinates is two-dimensional,
    // so we need to map the sprite coordinates x, y into one-dimension value to index the memory.
    // To do this, we use the following mapping funtion:
    //      ram_addr = x + y * SPRITE_X_SIZE        (1)
    // To simplify the logic, we constraint the SPRITE_X_SIZE to be power of 2 so we can substitute
    // the * operation into left shift operation
    //      ram_addr = x | y << log2(SPRITE_X_SIZE) (2)
    // The sprite index is on the most sigificant bits of the ram_address
    // so we attach the sprite index to the ram_addr
    //      ram_addr = x | y << log2(SPRITE_X_SIZE) | idx << log2(SPRITE_X_SIZE+SPRITE_Y_SIZE) (3)
    //

    assign sprite_rate_counter_fire = sprite_rate_counter == 0;

    always @(posedge clk) begin
        if (rst) begin
            sprite_rate_counter <= 0;
            sprite_idx <= 0;
        end
        else begin
            if (sprite_rate_counter_fire) sprite_rate_counter <= sprite_rate;
            else if (sprite_vld) sprite_rate_counter <= sprite_rate_counter - 1'b1;
            if (sprite_rate_counter_fire) begin
                if (sprite_idx == SPRITE_NUM-1) sprite_idx <= 0;
                else sprite_idx <= sprite_idx + 1'b1;
            end
        end
    end

    // substract the hc,vc coordinates from its origin position to get the sprite coordinates
    assign x = xx - x0[`H_SIZE-1:0];
    assign y = yy - y0[`V_SIZE-1:0];

    // check if the x, y coordinates is in the sprite region or not,
    // if not then is it not showing the sprite
    assign x_in_region = x >= 0 & (x < SPRITE_HSIZE);
    assign y_in_region = y >= 0 & (y < SPRITE_VSIZE);
    assign xy_in_region = x_in_region & y_in_region;

    // convert the x,y coordinates to ram address
    assign sprite_addr = x | (y << $clog2(SPRITE_HSIZE));
    assign sprite_ram_addr_r[SPRITE_AW-1:0] = sprite_addr;
    assign sprite_ram_addr_r[SPRITE_RAM_AW-1:SPRITE_AW] = sprite_idx;

    // chroma−key blending and multiplixing
    assign key_match = sprite_ram_dout == KEY_COLOR;
    assign sprite_rgb = (xy_in_region && !key_match) ? sprite_ram_dout : src_rgb;

    // --------------------------------
    // Module initialization
    // --------------------------------

    video_sprite_ram
    #(
        .AW         (SPRITE_RAM_AW),
        .DW         (RGB_SIZE),
        .MEM_FILE   (MEM_FILE)
    )
    u_video_sprite_ram
    (
        .clk    (clk),
        .we     (sprite_ram_we),
        .addr_w (sprite_ram_addr_w),
        .addr_r (sprite_ram_addr_r),
        .din    (sprite_ram_din),
        .dout   (sprite_ram_dout)
    );



endmodule

// Local Variables:
// verilog-library-flags:("-y ../../common/")
// End:
