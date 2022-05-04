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

`include "vga.svh"

 module video_dummy_core #(
    parameter RGB_SIZE  = 12,
    parameter PIPELINE  = 1
) (
    input                       clk,
    input                       rst,

    // vga interface
    input                       src_vld,
    output                      src_rdy,
    input  vga_fc_t             src_fc,
    input  [RGB_SIZE-1:0]       src_rgb,

    input                       snk_rdy,
    output reg                  snk_vld,
    output vga_fc_t             snk_fc,
    output reg [RGB_SIZE-1:0]   snk_rgb
);

    // --------------------------------
    // Module initialization
    // --------------------------------

    /* video_core_pipeline AUTO_TEMPLATE (
        .pipe_in_\(.*\)     (src_\1),
        .pipe_out_\(.*\)    (snk_\1),
    );
    */
    video_core_pipeline
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RGB_SIZE                         (RGB_SIZE),
      .PIPELINE                         (PIPELINE))
    u_video_core_pipeline
    (/*AUTOINST*/
     // Interfaces
     .pipe_in_fc                        (src_fc),                // Templated
     .pipe_out_fc                       (snk_fc),                // Templated
     // Outputs
     .pipe_in_rdy                       (src_rdy),               // Templated
     .pipe_out_vld                      (snk_vld),               // Templated
     .pipe_out_rgb                      (snk_rgb),               // Templated
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .pipe_in_vld                       (src_vld),               // Templated
     .pipe_in_rgb                       (src_rgb),               // Templated
     .pipe_out_rdy                      (snk_rdy));               // Templated


endmodule

// Local Variables:
// verilog-library-flags:("-y ../../common/")
// End:
