/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA core with line buffer
 *
 * Contains the following components:
 *  - vga_sync
 *  - vga_line_buffer
 * Data flow:
 *  vga_line_buffer => vga_sync
 *
 * ---------------------------------------------------------------
 * 05/12/2022:
 *  - merged the vga_sync module with vga_sync_core and rename the
 *    module to vga_core_line_buffer
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_core_line_buffer #(
    parameter RSIZE = 4,
    parameter GSIZE = 4,
    parameter BSIZE = 4,
    parameter RGB_SIZE    = 12,
    parameter START_DELAY = 12
) (
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    // line buffer source
    input [RGB_SIZE:0]      line_buffer_data,
    input                   line_buffer_vld,
    output                  line_buffer_rdy,

    // vga interface
    output reg [RSIZE-1:0]  vga_r,
    output reg [GSIZE-1:0]  vga_g,
    output reg [BSIZE-1:0]  vga_b,

    output reg              vga_hsync,
    output reg              vga_vsync
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    localparam            S_SYNC = 0,
                          S_DISP = 1;
    reg                   state;

    logic                 vga_frame_start;
    logic                 vga_src_rdy;
    logic [RGB_SIZE:0]    vga_src_data;
    logic [RGB_SIZE-1:0]  vga_src_rgb;
    logic                 vga_src_vld;

    reg [`H_SIZE-1:0]     h_counter;
    reg [`V_SIZE-1:0]     v_counter;

    logic                 h_counter_fire;
    logic                 v_counter_fire;
    logic                 h_video_on;
    logic                 v_video_on;
    logic                 video_on;
    logic                 scan_end;
    logic                 h_disp_end;
    logic                 v_disp_end;

    // --------------------------------
    // main logic
    // --------------------------------

    // horizontal and vertical counter
    assign h_counter_fire = h_counter == `H_COUNT-1;
    assign v_counter_fire = v_counter == `V_COUNT-1;

    always @(posedge pixel_clk) begin
        if (pixel_rst) begin
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

    // generate hsync/vsync and drive rgb rolor value
    always @(posedge pixel_clk) begin
        vga_hsync <= (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                     (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
        vga_vsync <= (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                     (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);
        {vga_r, vga_g, vga_b} <= video_on ? vga_src_rgb[RGB_SIZE-1:0] : 0;
    end

    // displays synchronization logic

    assign vga_src_rgb     = vga_src_data[RGB_SIZE-1:0];
    assign vga_frame_start = vga_src_data[RGB_SIZE];

    assign scan_end   = h_counter_fire & v_counter_fire;
    assign h_disp_end = h_counter == `H_DISPLAY-1;
    assign v_disp_end = v_counter == `V_DISPLAY-1;

    // SPECIAL NOTES:
    // Not sure why, but we need to delay the h_video_on by some amount
    // after the display area to make the picture showing correctly for the *DE2 board*
    assign h_video_on = (h_counter >= START_DELAY) && (h_counter <= `H_DISPLAY+START_DELAY-1);
    assign v_video_on = v_counter <= `V_DISPLAY-1;
    assign video_on   = h_video_on & v_video_on;

    always @(posedge pixel_clk) begin
        if (pixel_rst) begin
            state <= S_SYNC;
        end
        else begin
            if (scan_end && vga_frame_start) begin
                state <= S_DISP;
            end
            else if (h_disp_end && v_disp_end) begin
                state <= S_SYNC;
            end
        end
    end

    always @* begin
        vga_src_rdy = 1'b0;
        case(state)
            S_SYNC: begin
                vga_src_rdy = ~vga_frame_start; // pop the remaining frames out of the fifo
            end
            S_DISP: begin
                vga_src_rdy = video_on;
            end
        endcase
    end

    // --------------------------------
    // Module initialization
    // --------------------------------

    vga_line_buffer
    #(
      .RGB_SIZE                         (RGB_SIZE))
    u_vga_line_buffer
    (
     // Outputs
     .src_rdy                           (line_buffer_rdy),
     .snk_data                          (vga_src_data[RGB_SIZE:0]),
     .snk_vld                           (vga_src_vld),
     // Inputs
     .src_rst                           (sys_rst),
     .src_clk                           (sys_clk),
     .src_data                          (line_buffer_data),
     .src_vld                           (line_buffer_vld),
     .snk_rst                           (pixel_rst),
     .snk_clk                           (pixel_clk),
     .snk_rdy                           (vga_src_rdy));


endmodule
