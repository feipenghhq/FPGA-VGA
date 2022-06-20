/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * This module walks a random particle
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module dla_particle_walk #(
    parameter AVN_AW    = 19,
    parameter AVN_DW    = 16
) (
    input                   clk,
    input                   rst,

    input [`H_SIZE-1:0]     walk_init_x,
    input [`V_SIZE-1:0]     walk_init_y,
    input                   walk_start,
    output logic            walk_done,
    output logic            walk_valid,

    output [AVN_AW-1:0]     vram_avn_address,
    output logic            vram_avn_write,
    output [AVN_DW-1:0]     vram_avn_writedata,
    input                   vram_avn_waitrequest,

    // check the particle
    output [`H_SIZE-1:0]    check_x,
    output [`V_SIZE-1:0]    check_y,
    output logic            check_start,
    input                   check_done,
    input                   hit_boundary,
    input                   hit_neighbor
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam LSFR_WIDTH   = 16;

    localparam S_IDLE       = 0,
               S_CHECK      = 1,   // check the particle
               S_CHECK_WAIT = 2,   // waiit for the check result
               S_MOVE       = 3,   // move the particle
               S_WRITE      = 4;   // write the particle
    reg [4:0]   state;
    logic [4:0] state_next;


    reg [`H_SIZE-1:0]       cur_x;
    reg [`V_SIZE-1:0]       cur_y;
    logic                   move;
    logic [`H_SIZE-1:0]     cur_x_next;
    logic [`V_SIZE-1:0]     cur_y_next;
    logic [`H_SIZE-1:0]     cur_x_minus_one;
    logic [`H_SIZE-1:0]     cur_x_plus_one;
    logic [`V_SIZE-1:0]     cur_y_minus_one;
    logic [`V_SIZE-1:0]     cur_y_plus_one;
    logic [LSFR_WIDTH-1:0]  lsfr_random;
    logic [2:0]             direction;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign check_x = cur_x;
    assign check_y = cur_y;

    assign vram_avn_writedata = {AVN_DW{1'b1}};
    assign vram_avn_address = {{(AVN_AW-`H_SIZE){1'b0}}, cur_x} + cur_y * `H_DISPLAY;

    always @* begin
        walk_done = 0;
        walk_valid = 0;
        check_start = 0;
        move = 0;
        vram_avn_write = 0;
        state_next = 0;
        case(1)
            state[S_IDLE]: begin
                if (walk_start) state_next[S_CHECK] = 1;
                else            state_next[S_IDLE] = 1;
            end
            state[S_CHECK]: begin
                check_start = 1;
                state_next[S_CHECK_WAIT] = 1;
            end
            state[S_CHECK_WAIT]: begin
                // wait till the check completes
                if (check_done) begin
                    // if we hit the neighbor or hit a boundary, then we are done walking otherwise continue moving
                    // if we hit the boundary, discard the particle
                    if (hit_boundary) begin
                        walk_done = 1;
                                state_next[S_IDLE] = 1;
                    end
                    // if we hit the neighbor, write the particle to the screen
                    else if (hit_neighbor)
                                state_next[S_WRITE] = 1;
                    else
                                state_next[S_MOVE] = 1;
                end
                else            state_next[S_CHECK_WAIT] = 1;
            end
            state[S_MOVE]: begin
                move = 1;
                state_next[S_CHECK] = 1;
            end
            state[S_WRITE]: begin
                vram_avn_write = 1;
                walk_done = ~vram_avn_waitrequest;
                walk_valid = ~vram_avn_waitrequest;
                if (!vram_avn_waitrequest)
                                state_next[S_IDLE] = 1;
                else            state_next[S_WRITE] = 1;
            end
        endcase
    end


    assign cur_x_minus_one = cur_x - 1;
    assign cur_x_plus_one = cur_x + 1;

    assign cur_y_minus_one = cur_y - 1;
    assign cur_y_plus_one = cur_y + 1;

    assign direction = lsfr_random[2:0];

    /*
        The particale can move to 8 direction
        Here is the direction and the lsfr_random[2:0] value:
        0  1  2
        3     4
        5  6  7
    */

    always @* begin
        cur_x_next = cur_x;
        cur_y_next = cur_y;
        case(direction)
            0: begin
                cur_x_next = cur_x_minus_one;
                cur_y_next = cur_y_minus_one;
            end
            1: begin
                cur_y_next = cur_y_minus_one;
            end
            2: begin
                cur_x_next = cur_x_plus_one;
                cur_y_next = cur_y_minus_one;
            end
            3: begin
                cur_x_next = cur_x_minus_one;
            end
            4: begin
                cur_x_next = cur_x_plus_one;
            end
            5: begin
                cur_x_next = cur_x_minus_one;
                cur_y_next = cur_y_plus_one;
            end
            6: begin
                cur_y_next = cur_y_plus_one;
            end
            7: begin
                cur_x_next = cur_x_plus_one;
                cur_y_next = cur_y_plus_one;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= 1;
        end
        else begin
            state <= state_next;
        end
    end

    always @(posedge clk) begin
        if (walk_start && state[S_IDLE]) begin
            cur_x <= walk_init_x;
            cur_y <= walk_init_y;
        end
        else begin
            if (move) begin
                cur_x <= cur_x_next;
                cur_y <= cur_y_next;
            end
        end
    end

    // --------------------------------
    // Module initialization
    // --------------------------------


    dla_lsfr #(.WIDTH(LSFR_WIDTH), .TAP('hD008), .SEED('hffff))
    u_dla_lsfr (.clk(clk), .rst(rst), .shift(move), .value(lsfr_random));


endmodule