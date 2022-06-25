// ---------------------------------------------------------------
// Copyright (c) 2022 Heqing Huang
//
// Template taken from ECE5760
// https://people.ece.cornell.edu/land/courses/ece5760/DE2/DDS_Example/sine_wave.v
//
// ---------------------------------------------------------------


module de2_115_top (
    // Clock Input
    input         CLOCK_50,    // 50 MHz
    // Push Button
    input  [3:0]  KEY,         // Pushbutton[3:0]
    // DPDT Switch
    input  [17:0] SW,          // Toggle Switch[17:0]
    // SRAM Interface
    inout  [15:0] SRAM_DQ,     // SRAM Data bus 16 Bits
    output [19:0] SRAM_ADDR,   // SRAM Address bus 18 Bits
    output        SRAM_UB_N,   // SRAM High-byte Data Mask
    output        SRAM_LB_N,   // SRAM Low-byte Data Mask
    output        SRAM_WE_N,   // SRAM Write Enable
    output        SRAM_CE_N,   // SRAM Chip Enable
    output        SRAM_OE_N,   // SRAM Output Enable
    // VGA
    output        VGA_CLK,     // VGA Clock
    output        VGA_HS,      // VGA H_SYNC
    output        VGA_VS,      // VGA V_SYNC
    output        VGA_BLANK_N, // VGA BLANK
    output        VGA_SYNC_N,  // VGA SYNC
    output [7:0]  VGA_R,       // VGA Red
    output [7:0]  VGA_G,       // VGA Green
    output [7:0]  VGA_B        // VGA Blue
);


    /////////////////////////////////////////////

    logic           pixel_clk;
    logic           pixel_rst;
    logic           sys_clk;
    logic           sys_rst;

    logic [3:0]     vga_r;
    logic [3:0]     vga_g;
    logic [3:0]     vga_b;

    assign VGA_R = {vga_r, 4'b0};
    assign VGA_G = {vga_g, 4'b0};
    assign VGA_B = {vga_b, 4'b0};

    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N  = 1'b0;

    assign sys_rst = ~KEY[3];
    assign pixel_rst = ~KEY[3];

    altpllvga u_altpllvga
    (
        .inclk0 (CLOCK_50),
        .c0     (sys_clk),
        .c1     (VGA_CLK)
    );

    mandbort_framebuffer_sram
    u_mandbort_framebuffer_sram (
        .pixel_clk                          (VGA_CLK),
        .pixel_rst                          (pixel_rst),
        .sys_clk                            (sys_clk),
        .sys_rst                            (sys_rst),
        .vga_r                              (vga_r),
        .vga_g                              (vga_g),
        .vga_b                              (vga_b),
        .vga_hsync                          (VGA_HS),
        .vga_vsync                          (VGA_VS),
        .start                              (~KEY[0]),
        .sram_addr                          (SRAM_ADDR),
        .sram_dq                            (SRAM_DQ),
        .sram_ce_n                          (SRAM_CE_N),
        .sram_oe_n                          (SRAM_OE_N),
        .sram_we_n                          (SRAM_WE_N),
        .sram_be_n                          ({SRAM_UB_N, SRAM_LB_N})
    );

endmodule
