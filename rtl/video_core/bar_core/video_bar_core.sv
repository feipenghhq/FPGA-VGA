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

 module video_bar_core #(
    parameter HSIZE     = 11,
    parameter VSIZE     = 11,
    parameter VDISPLAY  = 480,
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
    input  [HSIZE-1:0]          hc,
    input  [VSIZE-1:0]          vc,
    input  [RGB_SIZE-1:0]       src_rgb,
    output logic [RGB_SIZE-1:0] snk_rgb
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

    logic [RSIZE-1:0]   src_r;
    logic [GSIZE-1:0]   src_g;
    logic [BSIZE-1:0]   src_b;

    logic [RSIZE-1:0]   snk_r;
    logic [GSIZE-1:0]   snk_g;
    logic [BSIZE-1:0]   snk_b;

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

    assign {bar_r, bar_g, bar_b} = bar_rgb;
    assign bar_r_resized = BSIZE > 4 ? {bar_r[3:0], {(RSIZE-4){1'b0}}} : bar_r[3:(4-RSIZE)];
    assign bar_g_resized = GSIZE > 4 ? {bar_g[3:0], {(GSIZE-4){1'b0}}} : bar_g[3:(4-GSIZE)];
    assign bar_b_resized = BSIZE > 4 ? {bar_b[3:0], {(BSIZE-4){1'b0}}} : bar_b[3:(4-BSIZE)];

    assign {src_r, src_g, src_b} = src_rgb;
    assign snk_r = ctrl_bypass ? src_r : bar_r_resized;
    assign snk_g = ctrl_bypass ? src_g : bar_g_resized;
    assign snk_b = ctrl_bypass ? src_b : bar_b_resized;
    assign snk_rgb = {snk_r, snk_g, snk_b};

    // --------------------------------
    // Module Declaration
    // --------------------------------

    video_bar_gen
    #(/*AUTOINSTPARAM*/
      // Parameters
      .HSIZE                            (HSIZE),
      .VSIZE                            (VSIZE),
      .VDISPLAY                         (VDISPLAY))
    u_video_bar_gen
    (/*AUTOINST*/
     // Outputs
     .bar_rgb                           (bar_rgb[11:0]),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .hc                                (hc[HSIZE-1:0]),
     .vc                                (vc[VSIZE-1:0]));

endmodule
