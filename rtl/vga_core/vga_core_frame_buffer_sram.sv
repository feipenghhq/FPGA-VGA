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
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12,
    parameter SRAM_AW   = 18,   // SRAM address width
    parameter SRAM_DW   = 16,   // SRAM data width
    parameter START_DELAY = 12
) (
    input   pixel_clk,
    input   pixel_rst,

    input   sys_clk,
    input   sys_rst,

    // the source interface is a memory mapped
    input  logic                    src_read,
    input  logic                    src_write,
    input  logic [`H_SIZE-1:0]      src_x,
    input  logic [`V_SIZE-1:0]      src_y,
    input  logic [SRAM_DW-1:0]      src_writedata,
    output logic [SRAM_DW-1:0]      src_readdata,
    output logic                    src_rdy,

    // the sram interface
    output logic                    sram_ce_n,
    output logic                    sram_oe_n,
    output logic                    sram_we_n,
    output logic [SRAM_DW/8-1:0]    sram_be_n,
    output logic [SRAM_AW-1:0]      sram_addr,
    output logic [SRAM_DW-1:0]      sram_dq_write,
    output logic                    sram_dq_en,
    input  logic [SRAM_DW-1:0]      sram_dq_read,

    // vga interface
    output logic [RSIZE-1:0]        vga_r,
    output logic [GSIZE-1:0]        vga_g,
    output logic [BSIZE-1:0]        vga_b,

    output reg                      vga_hsync,
    output reg                      vga_vsync
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
    logic [RGB_SIZE-1:0]    vga_rgb;
    logic                   h_counter_fire;
    logic                   v_counter_fire;
    logic                   h_video_on;
    logic                   v_video_on;
    logic                   video_on;

    // --------------------------------
    // main logic
    // --------------------------------

    // horizontal and vertical counter
    assign h_counter_fire = h_counter == `H_COUNT-1;
    assign v_counter_fire = v_counter == `V_COUNT-1;

    always @(posedge pixel_clk) begin
        if (pixel_rst || !vga_start) begin
            h_counter <= '0;
            v_counter <= '0;
            video_on_s1 <= '0;
        end
        else begin
            video_on_s1 <= video_on;

            if (h_counter_fire) h_counter <= 'b0;
            else h_counter <= h_counter + 1'b1;

            if (h_counter_fire) begin
                if (v_counter_fire) v_counter <= 'b0;
                else v_counter <= v_counter + 1'b1;
            end
        end
    end

    // generate hsync/vsync and drive rgb rolor value
    always @(posedge pixel_clk) begin
        vga_hsync <= (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                     (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
        vga_vsync <= (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                     (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);
    end

    // SPECIAL NOTES:
    // Not sure why, but we need to delay the h_video_on by some amount
    // after the display area to make the picture showing correctly for the *DE2 board*
    /* verilator lint_off UNSIGNED */
    assign h_video_on = (h_counter >= START_DELAY) && (h_counter <= `H_DISPLAY+START_DELAY-1);
    /* verilator lint_on UNSIGNED */
    assign v_video_on = v_counter <= `V_DISPLAY-1;
    assign video_on = h_video_on & v_video_on;
    assign {vga_r, vga_g, vga_b} = video_on_s1 ? vga_rgb : 0;

    // --------------------------------
    // Module initialization
    // --------------------------------

    vga_frame_buffer_sram
    #(
      .SRAM_AW                          (SRAM_AW),
      .SRAM_DW                          (SRAM_DW),
      .RGB_SIZE                         (RGB_SIZE))
    u_vga_frame_buffer_sram
    (
     // Outputs
     .vga_rgb                           (vga_rgb),
     .vga_start                         (vga_start),
     .src_readdata                      (src_readdata),
     .src_rdy                           (src_rdy),
     .sram_ce_n                         (sram_ce_n),
     .sram_oe_n                         (sram_oe_n),
     .sram_we_n                         (sram_we_n),
     .sram_be_n                         (sram_be_n),
     .sram_addr                         (sram_addr),
     .sram_dq_write                     (sram_dq_write),
     .sram_dq_en                        (sram_dq_en),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_read                          (video_on),
     .src_read                          (src_read),
     .src_write                         (src_write),
     .src_x                             (src_x[`H_SIZE-1:0]),
     .src_y                             (src_y[`V_SIZE-1:0]),
     .src_writedata                     (src_writedata),
     .sram_dq_read                      (sram_dq_read));


endmodule
