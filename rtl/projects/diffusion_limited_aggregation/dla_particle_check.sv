/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * This module checks the status of the particale:
 *  1. If the particle hit the boundary
 *  2. If the particle is close to an existing particle
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module dla_particle_check #(
    parameter AVN_AW    = 19,
    parameter AVN_DW    = 16
) (
    input                   clk,
    input                   rst,

    input [`H_SIZE-1:0]     check_x,
    input [`V_SIZE-1:0]     check_y,
    input                   check_start,
    output logic            check_done,
    output                  hit_boundary,
    output logic            hit_neighbor,

    // vram avalon interface
    output reg [AVN_AW-1:0] vram_avn_address,
    output                  vram_avn_read,
    input  [AVN_DW-1:0]     vram_avn_readdata,
    input                   vram_avn_waitrequest,
    input                   vram_avn_readdatavalid
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam S_IDLE  = 0,
               S_REQ   = 1,   // Send request to the vram
               S_READ  = 2,   // wait for the vram to get the read data back
               S_CHECK = 3,   // check the data
               S_BDR   = 4;   // hit the boundary
    reg [4:0]             state;
    logic [4:0]           state_next;

    reg [AVN_DW-1:0]      vram_avn_readdata_s0;
    reg [8:0]             pos_counter_oh; // onehot counter to calculate the x, y coordinates
    logic [2:0]           offset_x;
    logic [2:0]           offset_y;
    logic [`H_SIZE-1:0]   post_x;
    logic [`V_SIZE-1:0]   post_y;
    logic                 x_hit_boundary;
    logic                 y_hit_boundary;
    logic                 pos_counter_oh_shift;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign x_hit_boundary = (check_x == 0) | (check_x >= `H_DISPLAY-1);
    assign y_hit_boundary = (check_y == 0) | (check_y >= `V_DISPLAY-1);
    assign hit_boundary = x_hit_boundary | y_hit_boundary;
    assign hit_neighbor = vram_avn_readdata_s0 == {AVN_DW{1'b1}};


    // check the timing to see if we need to register the address to improve timing
    /*
        onehot bit that sets to 1 and the x, y coordinates
        |     | x-1 | x   | x+ 1 |
        | --- | --- | --- | ---- |
        | y-1 | 0   | 1   | 2    |
        | y   | 3   | 4   | 5    |
        | y+1 | 6   | 7   | 8    |
    */
    assign offset_x[0] = pos_counter_oh[0] | pos_counter_oh[3] | pos_counter_oh[6];
    assign offset_x[1] = pos_counter_oh[1] | pos_counter_oh[4] | pos_counter_oh[7];
    assign offset_x[2] = pos_counter_oh[2] | pos_counter_oh[5] | pos_counter_oh[8];

    assign offset_y[0] = pos_counter_oh[0] | pos_counter_oh[1] | pos_counter_oh[2];
    assign offset_y[1] = pos_counter_oh[3] | pos_counter_oh[4] | pos_counter_oh[5];
    assign offset_y[2] = pos_counter_oh[6] | pos_counter_oh[7] | pos_counter_oh[8];

    always @* begin
        post_x = check_x;
        post_y = check_y;
        case(1)
            offset_x[0]: post_x = check_x - 1;
            offset_x[1]: post_x = check_x;
            offset_x[2]: post_x = check_x + 1;
        endcase

        case(1)
            offset_y[0]: post_y = check_y - 1;
            offset_y[1]: post_y = check_y;
            offset_y[2]: post_y = check_y + 1;
        endcase
    end

    always @* begin

        check_done = 0;
        vram_avn_read = 0;
        pos_counter_oh_shift = 0;

        state_next = 0;
        case(1)

            state[S_IDLE]: begin
                if (check_start && !hit_boundary)
                                state_next[S_REQ] = 1;
                else if (check_start && hit_boundary)
                                state_next[S_BDR] = 1;
                else            state_next[S_IDLE] = 1;
            end

            state[S_REQ]: begin
                vram_avn_read = 1;
                pos_counter_oh_shift = !vram_avn_waitrequest;   // advance the address
                if (!vram_avn_waitrequest)
                                state_next[S_READ] = 1;
                else            state_next[S_REQ] = 1;
            end

            state[S_READ]: begin
                if (vram_avn_readdatavalid)
                                state_next[S_CHECK] = 1;
                else            state_next[S_READ] = 1;
            end

            state[S_CHECK]: begin
                // if we hit neighbor or we have checked all of the position then we are check_done
                check_done = hit_neighbor | pos_counter_oh[8];
                if (check_done) state_next[S_IDLE] = 1;
                else            state_next[S_REQ] = 1;
            end

            state[S_BDR]: begin
                check_done = 1;
                                state_next[S_IDLE] = 1;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= 1;
            pos_counter_oh <= 1;
        end
        else begin
            state <= state_next;
            if (pos_counter_oh_shift) begin
                pos_counter_oh <= {pos_counter_oh[7:0], pos_counter_oh[8]};
            end
        end
    end

    always @(posedge clk) begin
        vram_avn_readdata_s0 <= vram_avn_readdata;
        vram_avn_address <= {{(AVN_AW-`H_SIZE){1'b0}}, post_x} + post_y * `H_DISPLAY;
    end


endmodule