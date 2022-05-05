/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/04/2022
 * ---------------------------------------------------------------
 * Pipeline Stages for the Video core
 * Contianing multiple pipeline stages
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_core_stages #(
    parameter RGB_SIZE  = 12,
    parameter STAGE     = 2
) (
    input                       clk,
    input                       rst,

    // vga interface
    input                       stage_in_vld,
    output                      stage_in_rdy,
    input  vga_fc_t             stage_in_fc,
    input  [RGB_SIZE-1:0]       stage_in_rgb,

    input                       stage_out_rdy,
    output reg                  stage_out_vld,
    output vga_fc_t             stage_out_fc,
    output reg [RGB_SIZE-1:0]   stage_out_rgb
);

    /*AUTOREG*/

    /*AUTOWIRE*/

    logic    [STAGE-1:0]                    pipe_in_rdy;
    logic    [STAGE-1:0]                    pipe_in_vld;
    logic    [STAGE-1:0][RGB_SIZE-1:0]      pipe_in_rgb;
    vga_fc_t [STAGE-1:0]                    pipe_in_fc;

    /* verilator lint_off UNOPT */
    logic    [STAGE-1:0]                    pipe_out_rdy;
    /* verilator lint_on UNOPT */
    logic    [STAGE-1:0]                    pipe_out_vld;
    logic    [STAGE-1:0][RGB_SIZE-1:0]      pipe_out_rgb;
    vga_fc_t [STAGE-1:0]                    pipe_out_fc;

    /* video_core_pipeline AUTO_TEMPLATE
    (
        .RGB_SIZE   (RGB_SIZE),
        .PIPELINE   (1),

        .clk        (clk),
        .rst        (rst),

        .\(.*\)     (\1[i]),
    );
    */

    genvar i;
    generate
        for (i = 0; i < STAGE; i++) begin: pipe_stage

            video_core_pipeline
            #(/*AUTOINSTPARAM*/
              // Parameters
              .RGB_SIZE                 (RGB_SIZE),              // Templated
              .PIPELINE                 (1))                     // Templated
            u_video_core_pipeline
            (/*AUTOINST*/
             // Interfaces
             .pipe_in_fc                (pipe_in_fc[i]),         // Templated
             .pipe_out_fc               (pipe_out_fc[i]),        // Templated
             // Outputs
             .pipe_in_rdy               (pipe_in_rdy[i]),        // Templated
             .pipe_out_vld              (pipe_out_vld[i]),       // Templated
             .pipe_out_rgb              (pipe_out_rgb[i]),       // Templated
             // Inputs
             .clk                       (clk),                   // Templated
             .rst                       (rst),                   // Templated
             .pipe_in_vld               (pipe_in_vld[i]),        // Templated
             .pipe_in_rgb               (pipe_in_rgb[i]),        // Templated
             .pipe_out_rdy              (pipe_out_rdy[i]));       // Templated

            if (i != 0) begin
                assign pipe_out_rdy[i-1] = pipe_in_rdy[i];
                assign pipe_in_vld[i] = pipe_out_vld[i-1];
                assign pipe_in_rgb[i] = pipe_out_rgb[i-1];
                assign pipe_in_fc[i] = pipe_out_fc[i-1];
            end
        end
    endgenerate

    assign stage_in_rdy = pipe_in_rdy[0];
    assign pipe_in_vld[0] = stage_in_vld;
    assign pipe_in_rgb[0] = stage_in_rgb;
    assign pipe_in_fc[0] = stage_in_fc;

    assign pipe_out_rdy[STAGE-1] = stage_out_rdy;
    assign stage_out_vld = pipe_out_vld[STAGE-1];
    assign stage_out_rgb = pipe_out_rgb[STAGE-1];
    assign stage_out_fc = pipe_out_fc[STAGE-1];

endmodule
