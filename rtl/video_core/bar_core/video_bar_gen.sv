/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/30/2022
 * ---------------------------------------------------------------
 * Bar pattern generator
 *
 * This core generate 3 pattern
 * 1. 16 shade of gray color
 * 2. 8 prime color
 * 3. a continuous rainbow color spectrum
 *
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */


`include "vga.svh"

module video_bar_gen (
    input                   clk,
    input                   rst,
    input  [`H_SIZE-1:0]    hc,
    input  [`V_SIZE-1:0]    vc,
    output [11:0]           bar_rgb
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic [3:0]     up;
    logic [3:0]     down;
    logic [3:0]     bar_r;  // size is fixed to 4 bits here
    logic [3:0]     bar_g;
    logic [3:0]     bar_b;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign up = hc[6:3];
    assign down = ~vc[6:3];
    assign bar_rgb = {bar_r, bar_g, bar_b};

    always @* begin
        // 16 shade of gray (for 640x480)
        if (vc < `V_DISPLAY / 3) begin
            bar_r = {hc[8:5]};
            bar_g = {hc[8:5]};
            bar_b = {hc[8:5]};
        end
        // 8 primary color
        else if (vc < (`V_DISPLAY / 3) * 2) begin
            bar_r = {4{hc[8]}};
            bar_g = {4{hc[7]}};
            bar_b = {4{hc[6]}};
        end
        // a continuous "rain bow" color spectrum
        else begin
            case(hc[9:7])
                3'b000: begin
                    bar_r = 4'b1111;
                    bar_g = up;
                    bar_b = 4'b0000;
                end
                3'b001: begin
                    bar_r = down;
                    bar_g = 4'b1111;
                    bar_b = 4'b0000;
                end
                3'b010: begin
                    bar_r = 4'b0000;
                    bar_g = 4'b1111;
                    bar_b = up;
                end
                3'b011: begin
                    bar_r = 4'b0000;
                    bar_g = down;
                    bar_b = 4'b1111;
                end
                3'b100: begin
                    bar_r = up;
                    bar_g = 4'b0000;
                    bar_b = 4'b1111;
                end
                3'b101: begin
                    bar_r = 4'b1111;
                    bar_g = 4'b0000;
                    bar_b = down;
                end
                default: begin
                    bar_r = 4'b1111;
                    bar_g = 4'b1111;
                    bar_b = 4'b1111;
                end
            endcase
        end
    end

endmodule
