/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/05/2022
 * ---------------------------------------------------------------
 * Sprite generation logic
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

`include "vga.svh"

 module video_sprite_gen #(
    parameter RGB_SIZE      = 12,
    parameter SPRITE_HSIZE  = 32,   // 32x32 pixel sprite
    parameter SPRITE_VSIZE  = 32,
    parameter SPRITE_RAM_AW = 10,
    parameter MEM_FILE      = ""
) (
    input                       clk,
    input                       rst,

    // origin of othe sprite
    input [31:0]                x0,
    input [31:0]                y0,

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

    logic [`H_SIZE-1:0] x;
    logic [`V_SIZE-1:0] y;

    logic x_in_region;
    logic y_in_region;
    logic xy_in_region;

    logic [SPRITE_RAM_AW-1:0]   sprite_ram_addr_r;
    logic [RGB_SIZE-1:0]        sprite_ram_dout;

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
    //      ram_addr = x + y << log2(SPRITE_X_SIZE) (2)
    //

    // substract the hc,vc coordinates from its origin position to get the sprite coordinates
    assign x = xx - x0[`H_SIZE-1:0];
    assign y = yy - y0[`V_SIZE-1:0];

    // check if the x, y coordinates is in the sprite region or not,
    // if not then is it not showing the sprite
    assign x_in_region = ~x[`H_SIZE-1] & (x < SPRITE_HSIZE);
    assign y_in_region = ~y[`V_SIZE-1] & (y < SPRITE_VSIZE);
    assign xy_in_region = x_in_region & y_in_region;

    // convert the x,y coordinates to ram address
    assign sprite_ram_addr_r = x + y << $clog2(SPRITE_HSIZE);

    // blend the original pixel with the sprite pixel
    assign sprite_rgb = xy_in_region ? sprite_ram_dout : src_rgb;

    // --------------------------------
    // Module initialization
    // --------------------------------

    video_sprite_ram
    #(
        .AW(SPRITE_RAM_AW),
        .DW(RGB_SIZE),
        .MEM_FILE(MEM_FILE)
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
