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

`define H_SIZE  $clog2(`H_COUNT)
`define V_SIZE  $clog2(`V_COUNT)

typedef struct packed {
    logic [`H_SIZE-1:0] hc;
    logic [`V_SIZE-1:0] vc;
    logic               frame_start;
} vga_fc_t;

`endif