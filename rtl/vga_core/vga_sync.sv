/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/27/2022
 * ---------------------------------------------------------------
 * VGA sync module
 * ---------------------------------------------------------------
 *
 * The VGA sync module is responsible for generating the vga sync
 * signals (hsync/vsync)
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_sync #(
    parameter START_DELAY = 12,
    parameter SCAN_END = 0,         // generate scan_end signal
    parameter DISP_END = 0          // generate disp_end signal
) (
    input           pixel_clk,
    input           pixel_rst,

    output reg      vga_hsync,
    output reg      vga_vsync,
    output reg      video_on,

    // other timing infor
    output reg      scan_end,
    output reg      disp_end
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------


    reg [`H_SIZE-1:0]     h_counter;
    reg [`V_SIZE-1:0]     v_counter;

    logic                 h_counter_fire;
    logic                 v_counter_fire;
    logic                 h_video_on;
    logic                 v_video_on;


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
            video_on <= 0;
        end
        else begin

            if (h_counter_fire) h_counter <= 'b0;
            else h_counter <= h_counter + 1'b1;

            if (h_counter_fire) begin
                if (v_counter_fire) v_counter <= 'b0;
                else v_counter <= v_counter + 1'b1;
            end

            video_on  <= h_video_on & v_video_on;
        end
    end

    // generate hsync/vsync and drive rgb rolor value
    always @(posedge pixel_clk) begin
        vga_hsync <= (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                     (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
        vga_vsync <= (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                     (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);
    end



    // SPECIAL NOTES for the *DE2 board*
    // Not sure why, but we need to delay the h_video_on by some amount
    // after the display area to make the picture showing correctly
    assign h_video_on = (h_counter >= START_DELAY) && (h_counter <= `H_DISPLAY+START_DELAY-1);
    assign v_video_on = v_counter <= `V_DISPLAY-1;


    // lgoci for additional timing information
    generate

        // scan end
        if (SCAN_END) begin: scan_end_logic
            always @(posedge pixel_clk) begin
                if (pixel_rst) scan_end  <= 0;
                else scan_end  <= h_counter_fire & v_counter_fire;
            end
        end
        else begin
            always @* scan_end = 0;
        end

        // display end
        if (DISP_END) begin: display_end_logic
            logic   h_disp_end;
            logic   v_disp_end;

            assign h_disp_end = h_counter == `H_DISPLAY-1;
            assign v_disp_end = v_counter == `V_DISPLAY-1;

            always @(posedge pixel_clk) begin
                if (pixel_rst) disp_end  <= 0;
                else disp_end  <= h_disp_end & v_disp_end;
            end
        end
        else begin
            always @* disp_end = 0;
        end

    endgenerate

endmodule
