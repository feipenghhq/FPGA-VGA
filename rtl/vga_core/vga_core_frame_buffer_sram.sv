/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA core with frame buffer using sram
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_core_frame_buffer_sram #(
    parameter AVN_AW    = 18,
    parameter AVN_DW    = 16,
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12,
    parameter PF_BUF_SIZE = 8,
    parameter START_DELAY = 12
) (
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // source avalon interface
    input                   src_avn_read,
    input                   src_avn_write,
    input  [AVN_AW-1:0]     src_avn_address,
    input  [AVN_DW-1:0]     src_avn_writedata,
    output [AVN_DW-1:0]     src_avn_readdata,
    output                  src_avn_waitrequest,

    // sram avalon interface
    output                  sram_avn_read,
    output                  sram_avn_write,
    output [AVN_AW-1:0]     sram_avn_address,
    output [AVN_DW-1:0]     sram_avn_writedata,
    output [AVN_DW/8-1:0]   sram_avn_byteenable,
    input  [AVN_DW-1:0]     sram_avn_readdata,

    // vga interface
    output [RSIZE-1:0]      vga_r,
    output [GSIZE-1:0]      vga_g,
    output [BSIZE-1:0]      vga_b,
    output reg              vga_hsync,
    output reg              vga_vsync
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    /*AUTOWIRE*/

    /*AUTOREG*/

    reg [`H_SIZE-1:0]       h_counter;
    reg [`V_SIZE-1:0]       v_counter;
    reg                     video_on_s1;

    logic                   vga_start;
    logic                   vga_read;
    logic [RGB_SIZE-1:0]    vga_rgb;
    logic                   h_counter_fire;
    logic                   v_counter_fire;
    logic                   h_video_on;
    logic                   v_video_on;
    logic                   video_on;

    // --------------------------------
    // main logic
    // --------------------------------

    assign h_counter_fire = h_counter == `H_COUNT-1;
    assign v_counter_fire = v_counter == `V_COUNT-1;
    always @(posedge pixel_clk) begin
        if (pixel_rst || !vga_start) begin
            h_counter <= '0;
            v_counter <= '0;
        end
        else begin
            if (h_counter_fire) h_counter <= 'b0;
            else h_counter <= h_counter + 1'b1;
            if (h_counter_fire) begin
                if (v_counter_fire) v_counter <= 'b0;
                else v_counter <= v_counter + 1'b1;
            end
        end
    end

    // delay video_on for 1 cycle
    always @(posedge pixel_clk) begin
        if (pixel_rst || !vga_start) video_on_s1 <= '0;
        else video_on_s1 <= video_on;
    end

    // generate hsync/vsync and drive rgb rolor value
    always @(posedge pixel_clk) begin
        vga_hsync <= (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                     (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
        vga_vsync <= (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                     (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);
    end

    // SPECIAL NOTES for FPGA DE2 board:
    // Not sure why, but we need to delay the h_video_on by some amount
    // after the display area to make the picture showing correctly
    assign h_video_on = (h_counter >= START_DELAY[`H_SIZE-1:0]) &&
                        (h_counter <= `H_DISPLAY + START_DELAY[`H_SIZE-1:0] - 1);
    assign v_video_on = v_counter <= `V_DISPLAY-1;
    assign video_on = h_video_on & v_video_on;
    assign {vga_r, vga_g, vga_b} = video_on_s1 ? vga_rgb : 0;

    assign vga_read = video_on;

    // --------------------------------
    // Module initialization
    // --------------------------------

    vga_frame_buffer_sram
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .RGB_SIZE                         (RGB_SIZE),
      .PF_BUF_SIZE                      (PF_BUF_SIZE))
    u_vga_frame_buffer_sram
    (/*AUTOINST*/
     // Outputs
     .vga_rgb                           (vga_rgb[RGB_SIZE-1:0]),
     .vga_start                         (vga_start),
     .src_avn_readdata                  (src_avn_readdata[AVN_DW-1:0]),
     .src_avn_waitrequest               (src_avn_waitrequest),
     .sram_avn_read                     (sram_avn_read),
     .sram_avn_write                    (sram_avn_write),
     .sram_avn_address                  (sram_avn_address[AVN_AW-1:0]),
     .sram_avn_writedata                (sram_avn_writedata[AVN_DW-1:0]),
     .sram_avn_byteenable               (sram_avn_byteenable[AVN_DW/8-1:0]),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_read                          (vga_read),
     .src_avn_read                      (src_avn_read),
     .src_avn_write                     (src_avn_write),
     .src_avn_address                   (src_avn_address[AVN_AW-1:0]),
     .src_avn_writedata                 (src_avn_writedata[AVN_DW-1:0]),
     .sram_avn_readdata                 (sram_avn_readdata[AVN_DW-1:0]));



endmodule
