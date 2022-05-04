/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/29/2022
 * ---------------------------------------------------------------
 * Header file for VGA timing
 * http://tinyvga.com/vga-timing
 * ---------------------------------------------------------------
 */


`ifndef __VGA_TIMING__
`define __VGA_TIMING__


// VGA 640x480 resolution
`define H_DISPLAY       640
`define H_FRONT_PORCH   16
`define H_SYNC_PULSE    96
`define H_BACK_PORCH    48

`define V_DISPLAY       480
`define V_FRONT_PORCH   10
`define V_SYNC_PULSE    2
`define V_BACK_PORCH    33

`define H_COUNT         (`H_DISPLAY + `H_FRONT_PORCH + `H_SYNC_PULSE + `H_BACK_PORCH)
`define V_COUNT         (`V_DISPLAY + `V_FRONT_PORCH + `V_SYNC_PULSE + `V_BACK_PORCH)

`endif
