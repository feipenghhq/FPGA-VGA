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

module vga_sync (
    input                   pixel_clk,
    input                   pixel_rst,
    output                  vga_hsync,
    output                  vga_vsync,
    output [`H_SIZE-1:0]    vga_hc,      // horizontal count
    output [`V_SIZE-1:0]    vga_vc,      // vertical count
    output                  vga_on
);

    // --------------------------------
    // Signal Declaration
    // --------------------------------


    reg [`H_SIZE-1:0] h_counter;
    reg [`V_SIZE-1:0] v_counter;

    logic h_counter_fire;
    logic v_counter_fire;

    logic h_video_on;
    logic v_video_on;

    // --------------------------------
    // main logic
    // --------------------------------

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

    assign vga_hc = h_counter;
    assign vga_vc = v_counter;

    assign h_video_on = vga_hc <= `H_DISPLAY - 1;
    assign v_video_on = vga_vc <= `V_DISPLAY - 1;

    assign vga_on = h_video_on & v_video_on;

    assign vga_hsync = (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                       (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
    assign vga_vsync = (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                       (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);

endmodule
