/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/02/2022
 * ---------------------------------------------------------------
 * Header file for VGA
 * ---------------------------------------------------------------
 */


`ifndef __VGA__
`define __VGA__

`include "vga_timing.svh"

// Horizontal and vertical counter size
`define H_SIZE  ($clog2(`H_COUNT))
`define V_SIZE  ($clog2(`V_COUNT))

`define PIXELS      (`H_DISPLAY * `V_DISPLAY)
`define PIXELS_SIZE ($clog2(`PIXELS))


// RGN color size
`define R_SIZE      4
`define G_SIZE      4
`define B_SIZE      4
`define RGB_SIZE    (`R_SIZE + `G_SIZE + `B_SIZE)

typedef struct packed {
    logic [`H_SIZE-1:0]     hc;
    logic [`V_SIZE-1:0]     vc;
    logic [`R_SIZE-1:0]     r;
    logic [`G_SIZE-1:0]     g;
    logic [`B_SIZE-1:0]     b;
    logic                   start;
} vga_frame_t;

`endif