/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/30/2022
 * ---------------------------------------------------------------
 * Bar pattern generator core
 *
 * Register Spec
 * - 0x0 ctrl
 *  - bit [0:0] bypass = 0
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

`include "vga.svh"

 module video_bar_core #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12,
    parameter PIPELINE  = 1
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

    logic [11:0]        bar_rgb;
    logic [3:0]         bar_b;  // FIXED to 3 bits
    logic [3:0]         bar_g;
    logic [3:0]         bar_r;

    logic [RSIZE-1:0]   bar_b_resized;
    logic [GSIZE-1:0]   bar_g_resized;
    logic [BSIZE-1:0]   bar_r_resized;

    logic [RGB_SIZE-1:0] bar_rgb_resized;
    logic [RGB_SIZE-1:0] to_snk_rgb;

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

    // resize the data resolution
    assign {bar_r, bar_g, bar_b} = bar_rgb;
    assign bar_r_resized = BSIZE > 4 ? {bar_r[3:0], {(RSIZE-4){1'b0}}} : bar_r[3:(4-RSIZE)];
    assign bar_g_resized = GSIZE > 4 ? {bar_g[3:0], {(GSIZE-4){1'b0}}} : bar_g[3:(4-GSIZE)];
    assign bar_b_resized = BSIZE > 4 ? {bar_b[3:0], {(BSIZE-4){1'b0}}} : bar_b[3:(4-BSIZE)];
    assign bar_rgb_resized = {bar_r_resized, bar_g_resized, bar_b_resized};

    assign to_snk_rgb = ctrl_bypass ? src_rgb : bar_rgb_resized;

    // --------------------------------
    // Module Declaration
    // --------------------------------

        /* video_core_pipeline AUTO_TEMPLATE (
        .pipe_in_rgb        (to_snk_rgb[]),
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
     .pipe_in_rgb                       (to_snk_rgb[RGB_SIZE-1:0]), // Templated
     .pipe_out_rdy                      (snk_rdy));               // Templated


    /* video_bar_gen AUTO_TEMPLATE (
        .hc     (src_fc.hc[]),
        .vc     (src_fc.vc[]),
    )
    */
    video_bar_gen
    u_video_bar_gen
    (/*AUTOINST*/
     // Outputs
     .bar_rgb                           (bar_rgb[11:0]),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .hc                                (src_fc.hc[`H_SIZE-1:0]), // Templated
     .vc                                (src_fc.vc[`V_SIZE-1:0])); // Templated

endmodule

// Local Variables:
// verilog-library-flags:("-y ../../common/")
// End:


