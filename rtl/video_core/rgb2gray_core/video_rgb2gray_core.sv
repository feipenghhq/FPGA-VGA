/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Rgb2gray core
 *
 * Register Spec
 * - 0x0 ctrl
 *  - bit [0:0] bypass = 0
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_rgb2gray_core #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
) (
    input                       clk,
    input                       rst,

    // avalon interface
    input                       avs_write,
    input                       avs_address,
    input [31:0]                avs_writedata,

    // vga interface
    input                       src_vld,
    output                      src_rdy,
    input  vga_fc_t             src_fc,
    input  [RGB_SIZE-1:0]       src_rgb,

    input                       snk_rdy,
    output                      snk_vld,
    output vga_fc_t             snk_fc,
    output [RGB_SIZE-1:0]       snk_rgb
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    // Register interface
    // 0x0 ctrl
    reg                 ctrl_bypass;
    logic               ctrl_wen;

    /*AUTOREG*/

    /*AUTOWIRE*/

    // --------------------------------
    // Register interface
    // --------------------------------

    assign ctrl_wen = avs_write & (avs_address == 0);

    always @(posedge clk) begin
        if (rst) begin
            ctrl_bypass <= '0;
        end
        else begin
            if (ctrl_wen) begin
                ctrl_bypass <= avs_writedata[0];
            end
        end
    end

    // --------------------------------
    // Main logic
    // --------------------------------


    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* video_core_stages AUTO_TEMPLATE (
        .STAGE              (2),
        .stage_in_rgb       (0),
        .stage_out_rgb      (),
        .stage_in_\(.*\)    (src_\1),
        .stage_out_\(.*\)   (snk_\1),
    );
    */
    video_core_stages
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RGB_SIZE                         (RGB_SIZE),
      .STAGE                            (2))                     // Templated
    u_video_core_stages
    (/*AUTOINST*/
     // Interfaces
     .stage_in_fc                       (src_fc),                // Templated
     .stage_out_fc                      (snk_fc),                // Templated
     // Outputs
     .stage_in_rdy                      (src_rdy),               // Templated
     .stage_out_vld                     (snk_vld),               // Templated
     .stage_out_rgb                     (),                      // Templated
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .stage_in_vld                      (src_vld),               // Templated
     .stage_in_rgb                      (0),                     // Templated
     .stage_out_rdy                     (snk_rdy));               // Templated


    video_rgb2gray_gen
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_video_rgb2gray_gen
    (/*AUTOINST*/
     // Outputs
     .snk_rgb                           (snk_rgb[RGB_SIZE-1:0]),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .src_rgb                           (src_rgb[RGB_SIZE-1:0]));

endmodule

// Local Variables:
// verilog-library-flags:("-y ../../common/")
// End:
