/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Video Dummy core
 *
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

 module video_dummy_core #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
) (
    input                       clk,
    input                       rst,

    // vga interface
    input  [RGB_SIZE-1:0]       src_rgb,
    output logic [RGB_SIZE-1:0] snk_rgb
);

    // --------------------------------
    // Main logic
    // --------------------------------

    assign snk_rgb = src_rgb;

endmodule
