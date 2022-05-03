/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/29/2022
 * ---------------------------------------------------------------
 * VGA sync core
 * Generate VGA hsync/vsync signal based on VGA timing
 * ---------------------------------------------------------------
 */

`include "vga_timing.svh"

module vga_sync #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
) (
    input                   pixel_clk,
    input                   pixel_rst,

    input [RGB_SIZE:0]      vga_src_rgb,
    input                   vga_src_vld,
    output logic            vga_src_rdy,

    output reg [RSIZE-1:0]  vga_r,
    output reg [GSIZE-1:0]  vga_g,
    output reg [BSIZE-1:0]  vga_b,

    output reg              vga_hsync,
    output reg              vga_vsync
);

    // --------------------------------
    // Signal Declaration
    // --------------------------------

    localparam          S_SYNC = 0,
                        S_DISP = 1;
    reg                 state;

    reg [RGB_SIZE:0]    buffer;
    reg                 buffer_vld;
    reg [`H_SIZE-1:0]   h_counter;
    reg [`V_SIZE-1:0]   v_counter;

    logic               h_counter_fire;
    logic               v_counter_fire;

    logic               h_video_on;
    logic               v_video_on;
    logic               video_on;

    logic               scan_end;
    logic               h_disp_end;
    logic               v_disp_end;

    logic               vga_stream_start;

    // --------------------------------
    // main logic
    // --------------------------------


    // horizontal and vertical counter logic
    assign h_counter_fire = h_counter == `H_COUNT-1;
    assign v_counter_fire = v_counter == `V_COUNT-1;

    always @(posedge pixel_clk) begin
        vga_hsync <= (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                     (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
        vga_vsync <= (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                     (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);
        {vga_r, vga_g, vga_b} <= vga_src_rgb[RGB_SIZE-1:0];
    end

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

    // displays synchronization logic
    assign scan_end   = h_counter_fire & v_counter_fire;
    assign h_disp_end = h_counter == `H_DISPLAY-1;
    assign v_disp_end = v_counter == `V_DISPLAY-1;

    assign h_video_on = h_counter <= `H_DISPLAY - 1;
    assign v_video_on = v_counter <= `V_DISPLAY - 1;
    assign video_on   = h_video_on & v_video_on;

    assign vga_stream_start = vga_src_rgb[RGB_SIZE];

    always @(posedge pixel_clk) begin
        if (pixel_rst) begin
            state <= S_SYNC;
        end
        else begin
            if (scan_end && vga_stream_start) begin
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
                vga_src_rdy = ~vga_stream_start; // pop the remaining frames out of the fifo
            end
            S_DISP: begin
                vga_src_rdy = video_on;
            end
        endcase
    end

endmodule
