/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * Initialize the memory for DLA
 *
 * 1. Clear the entire screen to black.
 * 2. Add the initial seed to the screen.
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module dla_vram_init #(
    parameter AVN_AW    = 19,
    parameter AVN_DW    = 16
) (
    input                       clk,
    input                       rst,

    input                       init_type, // 0 = snowflake, 1 = forest
    input                       init_start,
    output logic                init_done,

    // vram avalon interface
    output [AVN_AW-1:0]         vram_avn_address,
    output                      vram_avn_write,
    output [AVN_DW-1:0]         vram_avn_writedata,
    input                       vram_avn_waitrequest

);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam  S_IDLE  = 0,
                S_CLEAR = 1,    // clear the screen
                S_SET   = 2,    // add the initial seed to the screen
                S_DONE  = 3;
    reg [3:0]   state;
    logic [3:0] state_next;

    reg [AVN_AW-1:0] address;
    reg [AVN_AW-1:0] h_count;

    logic clear_done;
    logic set_done;
    logic h_count_fire;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign h_count_fire =  (h_count == `H_DISPLAY-1);
    assign set_done = init_type ? h_count_fire : 1;

    always @* begin

        vram_avn_writedata = 0;
        vram_avn_write = 0;
        vram_avn_address = address;

        clear_done = address == `H_DISPLAY * `V_DISPLAY - 1;
        init_done = 0;

        state_next = 0;
        case(1)
            state[S_IDLE]: begin
                if (init_start) state_next[S_CLEAR] = 1;
                else            state_next[S_IDLE] = 1;
            end
            state[S_CLEAR]: begin
                vram_avn_write = 1;
                if (clear_done & !vram_avn_waitrequest) state_next[S_SET] = 1;
                else                                    state_next[S_CLEAR] = 1;
            end
            state[S_SET]: begin
                vram_avn_write = 1;
                vram_avn_writedata = {AVN_DW{1'b1}};
                if (set_done && !vram_avn_waitrequest)  state_next[S_DONE] = 1;
                else                                    state_next[S_SET] = 1;
            end
            state[S_DONE]: begin
                init_done = 1;
                state_next[S_IDLE] = 1;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            address <= 0;
            h_count <= 0;
            state <= 1;
        end
        else begin
            state <= state_next;

            if (state[S_IDLE]) begin
                address <= 0;
            end
            else if (state_next[S_SET]) begin
                // snowflake, add an particle at the middle of the screen
                if (!init_type) begin
                    address <= `H_DISPLAY / 2 + (`V_DISPLAY / 2) * `H_DISPLAY;
                end
                // forest, initialize the bottom of the screen
                else begin
                    if (!vram_avn_waitrequest) h_count <= h_count + 1;
                    address <= h_count + (`V_DISPLAY - 1) * `H_DISPLAY;
                end
            end
            else if (state[S_CLEAR] && !vram_avn_waitrequest) begin
                address <= address + 1;
            end

        end
    end

endmodule