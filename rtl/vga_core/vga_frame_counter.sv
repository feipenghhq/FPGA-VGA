/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA Frame counter
 * ---------------------------------------------------------------
 */

`include "vga_timing.svh"

module vga_sync #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
) (
    input                   clk,
    input                   rst,

    input                   clear,
    output [`H_SIZE-1:0]    hcount,
    output [`V_SIZE-1:0]    vcount,

    output                  frame_start,
    output                  frame_end
);

    // --------------------------------
    // Signal Declaration
    // --------------------------------


    reg [`H_SIZE-1:0]   h_counter;
    reg [`V_SIZE-1:0]   v_counter;

    logic               h_counter_fire;
    logic               v_counter_fire;

    // --------------------------------
    // main logic
    // --------------------------------


    // horizontal and vertical counter logic
    assign h_counter_fire = h_counter == `H_COUNT-1;
    assign v_counter_fire = v_counter == `V_COUNT-1;

    assign frame_start = h_counter == 0 & v_counter == 0;
    assign frame_end   = h_counter_fire & v_counter_fire;

    assign hcount = h_counter;
    assign vcount = v_counter;

    always @(posedge clk) begin
        if (rst | clear) begin
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

endmodule
