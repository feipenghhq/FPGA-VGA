// ---------------------------------------------------------------
// Copyright (c) 2022 Heqing Huang
//
// Template taken from ECE5760
// https://people.ece.cornell.edu/land/courses/ece5760/DE2/DDS_Example/sine_wave.v
//
// ---------------------------------------------------------------


module de2_top (
    // Clock Input
    input         CLOCK_50,    // 50 MHz
    // Push Button
    input  [3:0]  KEY,         // Pushbutton[3:0]
    // DPDT Switch
    input  [17:0] SW,          // Toggle Switch[17:0]
    // VGA
    output        VGA_CLK,     // VGA Clock
    output        VGA_HS,      // VGA H_SYNC
    output        VGA_VS,      // VGA V_SYNC
    output        VGA_BLANK,   // VGA BLANK
    output        VGA_SYNC,    // VGA SYNC
    output [9:0]  VGA_R,       // VGA Red[9:0]
    output [9:0]  VGA_G,       // VGA Green[9:0]
    output [9:0]  VGA_B        // VGA Blue[9:0]
);


    /////////////////////////////////////////////

    logic pixel_clk;
    logic pixel_rst;
    logic sys_clk;
    logic sys_rst;

    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;

    assign VGA_R = {vga_r, {6{vga_r[3]}}};
    assign VGA_G = {vga_g, {6{vga_g[3]}}};
    assign VGA_B = {vga_b, {6{vga_b[3]}}};

    assign VGA_BLANK = 1'b1;
    assign VGA_SYNC  = 1'b0;

    assign sys_rst = ~KEY[3];
    assign pixel_rst = ~KEY[3];

    altpllvga u_altpllvga
    (
        .inclk0 (CLOCK_50),
        .c0     (sys_clk),
        .c1     (VGA_CLK)
    );

    video_system_linebuffer
    u_video_system_linebuffer (
        .pixel_clk                          (VGA_CLK),
        .pixel_rst                          (pixel_rst),
        .sys_clk                            (sys_clk),
        .sys_rst                            (sys_rst),
        .vga_r                              (vga_r),
        .vga_g                              (vga_g),
        .vga_b                              (vga_b),
        .vga_hsync                          (VGA_HS),
        .vga_vsync                          (VGA_VS),
        .bar_core_bypass                    (SW[0]),
        .pikachu_core_bypass                (SW[1]),
        .pacman_core_bypass                 (SW[2]),
        .rgb2gray_core_bypass               (SW[3]),
    );

endmodule
