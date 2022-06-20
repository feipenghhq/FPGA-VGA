// ---------------------------------------------------------------
// Copyright (c) 2022 Heqing Huang
//
// ---------------------------------------------------------------


module de2_115_top (
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
    output        VGA_BLANK_N, // VGA BLANK
    output        VGA_SYNC_N,  // VGA SYNC
    output [7:0]  VGA_R,       // VGA Red[7:0]
    output [7:0]  VGA_G,       // VGA Green[7:0]
    output [7:0]  VGA_B        // VGA Blue[7:0]
);


    /////////////////////////////////////////////

    logic pixel_clk;
    logic pixel_rst;
    logic sys_clk;
    logic sys_rst;

    logic [3:0] vga_r;
    logic [3:0] vga_g;
    logic [3:0] vga_b;

    assign VGA_R = {vga_r, 4'b0};
    assign VGA_G = {vga_g, 4'b0};
    assign VGA_B = {vga_b, 4'b0};

    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N = 1'b0;

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
