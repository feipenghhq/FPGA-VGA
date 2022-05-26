/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * This module walks a random particle
 * ---------------------------------------------------------------
 */

module dla_particle_walk #(
    parameter AVN_AW    = 18,
    parameter AVN_DW    = 16,
    parameter HSIZE     = 640,
    parameter VSIZE     = 480
) (
    input                       clk,
    input                       rst,

    input [$clog2(HSIZE)-1:0]   walk_init_x,
    input [$clog2(VSIZE)-1:0]   walk_init_y,
    input                       walk_start,
    output logic                walk_done,

    output [AVN_AW-1:0]         vram_avn_address,
    output logic                vram_avn_write,
    output [AVN_DW-1:0]         vram_avn_writedata,
    input                       vram_avn_waitrequest,

    // check the particle
    output [$clog2(HSIZE)-1:0]  check_x,
    output [$clog2(VSIZE)-1:0]  check_y,
    output logic                check_start,
    input                       check_done,
    input                       hit_boundary,
    input                       hit_neighbor
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


    reg [$clog2(HSIZE)-1:0]     cur_x;
    reg [$clog2(VSIZE)-1:0]     cur_y;
    reg                         walk_valid;

    logic                       move;
    logic [$clog2(HSIZE)-1:0]   cur_x_next;
    logic [$clog2(VSIZE)-1:0]   cur_y_next;

    logic [LSFR_WIDTH-1:0]      lsfr_x;
    logic [LSFR_WIDTH-1:0]      lsfr_y;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign check_x = cur_x;
    assign check_y = cur_y;

    assign vram_avn_writedata = {AVN_DW{1'b1}};
    assign vram_avn_address = {{(AVN_AW-$clog2(HSIZE)){1'b0}}, cur_x} + cur_y * HSIZE;

    always @* begin
        walk_done = 0;
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
                walk_done = check_done & (hit_neighbor | hit_neighbor);
                if (walk_done)  state_next[S_WRITE] = 1;
                else            state_next[S_MOVE] = 1;
            end
            state[S_MOVE]: begin
                move = 1;
                state_next[S_CHECK] = 1;
            end
            state[S_WRITE]: begin
                vram_avn_write = walk_valid;
                if (!vram_avn_waitrequest)
                                state_next[S_IDLE] = 1;
                else            state_next[S_WRITE] = 1;
            end
        endcase
    end


    always @* begin
        cur_x_next = cur_x;
        cur_y_next = cur_y;
        case(1)
            lsfr_x[0]: cur_x_next = cur_x - 1;
            lsfr_x[1]: cur_x_next = cur_x;
            lsfr_x[2]: cur_x_next = cur_x + 1;
        endcase
        case(1)
            lsfr_y[0]: cur_y_next = cur_y - 1;
            lsfr_y[1]: cur_y_next = cur_y;
            lsfr_y[2]: cur_y_next = cur_y + 1;
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
        if (check_done & hit_neighbor & state[S_CHECK_WAIT]) begin
            walk_valid <= 1;
        end
        else if (state[S_IDLE]) begin
            walk_valid <= 0;
        end

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


    dla_lsfr #(.WIDTH(LSFR_WIDTH), .TAP(16), .SEED(16))
    u_dla_lsfr_x (.clk(clk), .rst(rst), .shift(move), .value(lsfr_x));

    dla_lsfr #(.WIDTH(LSFR_WIDTH), .TAP(16), .SEED(32))
    u_dla_lsfr_y (.clk(clk), .rst(rst), .shift(move), .value(lsfr_y));

endmodule