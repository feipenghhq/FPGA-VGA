/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/16/2022
 * ---------------------------------------------------------------
 * 1 Dimensional Cellular Automaton Core
 *
 * This design is a circuit which runs a state machine to compute
 * and display a binary, nearest-neighbor, one-dimensional CA on a
 * VGA monitor.
 *
 * This design use the FPGA internal memory to store the CA value
 *
 * Reference:
 * 1. https://people.ece.cornell.edu/land/courses/ece5760/LABS/s2016/lab1.html
 * 2. https://mathworld.wolfram.com/ElementaryCellularAutomaton.html
 *
 * ---------------------------------------------------------------
 */

/*

General Algorithm for the design

1. The calculation is divided into 3 pipeline stages:

Read Memory => Calculate Result => Write Memory/VRAM

Read Memory:        Read the pattern from the ping pong buffer
Calculate Result:   Calculate the result for the next value and Write back the result to ping pong buffer
Write Memory/VRAM:  Write the data to VRAM

2. Since we send the data into the VRAM, we use a ping pong buffer to store
   the previous pattern and the current pattern. When we are done with the current
   line, we switch the ping pong buffer


3. To eliminate the corner cases, we add additional space on the left and right.

Here is an example. Let's assume each line has 4 location: x0, x1, x2, x3
We add 2 extra location on the left and 2 extra location on the right

Address :           A0 A1 A2 A3 A4 A5 A6 A7
Actual line index:  NA NA X0 X1 X2 X3 NA NA
Valid address range: addr-2 >= 0 and addr-2<= `H_COUNT-1

So the actual valid range is A2 to A5

*/

`include "vga.svh"

module cellular_automaton_core #(
    parameter AVN_AW    = 19,
    parameter AVN_DW    = 16
) (
    input               sys_clk,
    input               sys_rst,

    // vram avalon interface
    output              vram_avn_write,
    output [AVN_AW-1:0] vram_avn_address,
    output [AVN_DW-1:0] vram_avn_writedata,
    input               vram_avn_waitrequest,

    // ca rule
    input [7:0]         ca_rule
);

    // --------------------------------
    // Signal declarations
    // --------------------------------


    localparam MEM_SIZE     = `H_DISPLAY + 4; // 4 extra location is added to eliminate the corner case.
    localparam MEM_DEPTH    = $clog2(MEM_SIZE);
    localparam VRAM_SIZE    = `H_DISPLAY * `V_DISPLAY;

    reg [MEM_SIZE-1:0]      buf0;   // ping pong buffer 0
    reg [MEM_SIZE-1:0]      buf1;   // ping pong buffer 1

    logic                   stall;

    // stage 0
    reg                     pp_ptr_s0; // pointer to ping pong buffer
    reg [MEM_DEPTH-1:0]     addr_s0;
    logic                   addr_fire_s0;
    logic                   buf_value_s0;

    // stage 1
    reg                     pp_ptr_s1;
    reg [2:0]               pattern_s1;
    reg                     valid_s1;
    reg [MEM_DEPTH-1:0]     addr_s1;
    logic [MEM_DEPTH-1:0]   buf_addr_s1;
    logic                   cal_value_s1;

    // stage 2
    reg                     value_s2;
    reg                     valid_s2;
    reg [AVN_AW-1:0]        vram_address_s2;
    logic                   done_s2;

    // --------------------------------
    // Main logic
    // --------------------------------


    // PIPELINE Stage 0: Read the pattern from the current buffer

    assign addr_fire_s0 = addr_s0 == (MEM_SIZE - 1'b1);

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            addr_s0 <= 0;
            pp_ptr_s0 <= 0;
        end
        else if (!stall) begin
            if (addr_fire_s0) addr_s0 <= 0;
            else addr_s0 <= addr_s0 + 1'b1;
            if (addr_fire_s0) pp_ptr_s0 <= ~pp_ptr_s0;
        end
    end

    assign buf_value_s0 = pp_ptr_s0 ? buf1[addr_s0] : buf0[addr_s0];

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            pattern_s1 <= 0;
            valid_s1 <= 0;
            pp_ptr_s1 <= 0;
            addr_s1 <= 0;
        end
        else if (!stall) begin
            valid_s1 <= (addr_s0 >= 2) && (addr_s0 <= MEM_SIZE-1-2);
            pattern_s1 <= {pattern_s1[1:0], buf_value_s0};
            pp_ptr_s1 <= pp_ptr_s0;
            addr_s1 <= addr_s0;
        end
    end

    // PIPELINE Stage 1: Calculate the next pattern
    assign cal_value_s1 = ca_rule[pattern_s1];

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            value_s2 <= 0;
            valid_s2 <= 0;
        end
        else if (!stall) begin
            valid_s2 <= valid_s1;
            value_s2 <= pattern_s1[0]; // write the current generation to the vram
        end
    end

    // We need to read 3 patterns out in order to get the curent pattern so we need to minus the addr by 1 to
    // get the address of the current pixel
    assign buf_addr_s1 = addr_s1 - 1;
    always @(posedge sys_clk) begin
        if (sys_rst) begin
            buf0 <= 1'b1 << (MEM_SIZE / 2);
            buf1 <= 0;
        end
        else if (!stall) begin
            if (pp_ptr_s1 && valid_s1) begin
                buf1[buf_addr_s1] <= cal_value_s1;
            end
            if (!pp_ptr_s1 && valid_s1) begin
                buf0[buf_addr_s1] <= cal_value_s1;
            end
        end
    end

    // PIPELINE Stage 2: Write the data to the VRAM

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            vram_address_s2 <= '0;
        end
        else if(!stall) begin
            if (valid_s2) vram_address_s2 <= vram_address_s2 + 1'b1;
        end
    end

    assign vram_avn_write = valid_s2 & ~stall;
    assign vram_avn_address = vram_address_s2;
    assign vram_avn_writedata = {AVN_DW{~value_s2}};

    assign done_s2 = vram_address_s2 == VRAM_SIZE - 1;
    assign stall = done_s2 | vram_avn_waitrequest;

endmodule