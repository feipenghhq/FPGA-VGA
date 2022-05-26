/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * Initialize the vram
 * ---------------------------------------------------------------
 */

module dla_vram_init #(
    parameter AVN_AW    = 18,
    parameter AVN_DW    = 16,
    parameter HSIZE     = 640,
    parameter VSIZE     = 480
) (
    input                       clk,
    input                       rst,

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
                S_CLEAR = 1,
                S_SET   = 2,
                S_DONE  = 3;
    reg [3:0]   state;
    logic [3:0] state_next;


    reg [AVN_AW-1:0] address;

    logic clear_done;

    // --------------------------------
    // Main logic
    // --------------------------------


    always @* begin

        vram_avn_writedata = 0;
        vram_avn_write = 0;
        vram_avn_address = address;

        clear_done = address == HSIZE * VSIZE - 1;
        init_done = 0;

        state_next = 0;
        case(1)
            state[S_IDLE]: begin
                if (init_start) state_next[S_CLEAR] = 1;
                else            state_next[S_IDLE] = 1;
            end
            state[S_CLEAR]: begin
                vram_avn_write = 1;
                if (clear_done & !vram_avn_waitrequest)
                                state_next[S_SET] = 1;
                else            state_next[S_CLEAR] = 1;
            end
            state[S_SET]: begin
                vram_avn_write = 1;
                if (!vram_avn_waitrequest)
                                state_next[S_DONE] = 1;
                else            state_next[S_SET] = 1;
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
            state <= 1;
        end
        else begin
            state <= state_next;

            if (state_next[S_IDLE]) begin
                address <= 0;
            end
            else if (state_next[S_SET]) begin
                address <= HSIZE / 2 + (VSIZE / 2) * HSIZE; // middle of the screen
            end
            else if (state[S_CLEAR] && !vram_avn_waitrequest) begin
                address <= address + 1;
            end
        end
    end

endmodule