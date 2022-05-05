/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/03/2022
 * ---------------------------------------------------------------
 * Pipeline module for the Video core
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_core_pipeline #(
    parameter RGB_SIZE  = 12,
    parameter PIPELINE  = 1
) (
    input                       clk,
    input                       rst,

    // vga interface
    input                       pipe_in_vld,
    output                      pipe_in_rdy,
    input  vga_fc_t             pipe_in_fc,
    input  [RGB_SIZE-1:0]       pipe_in_rgb,

    input                       pipe_out_rdy,
    output reg                  pipe_out_vld,
    output vga_fc_t             pipe_out_fc,
    output reg [RGB_SIZE-1:0]   pipe_out_rgb
);

    // --------------------------------
    // Main logic
    // --------------------------------

    generate
        if (PIPELINE == 1) begin:pipeline

            reg pipe_vld;

            logic pipe_in_fire;
            logic pipe_out_fire;

            assign pipe_in_fire = pipe_in_vld & pipe_in_rdy;
            assign pipe_out_fire = pipe_out_vld & pipe_out_rdy;

            always @(posedge clk) begin
                if (pipe_in_fire) begin
                    pipe_out_fc <= pipe_in_fc;
                    pipe_out_rgb <= pipe_in_rgb;
                end
            end

            always @(posedge clk) begin
                if (rst) begin
                    pipe_vld <= 1'b0;
                end
                else begin
                    case({pipe_in_fire, pipe_out_fire})
                        2'b00: pipe_vld <= pipe_vld;
                        2'b01: pipe_vld <= 0;
                        2'b10: pipe_vld <= 1;
                        2'b11: pipe_vld <= 1;
                    endcase
                end
            end

            assign pipe_out_vld = pipe_vld;
            assign pipe_in_rdy = pipe_out_rdy;
        end
        else begin: non_pipeline

            assign pipe_out_fc  = pipe_in_fc;
            assign pipe_out_rgb = pipe_in_rgb;
            assign pipe_out_vld = pipe_in_vld;
            assign pipe_in_rdy  = pipe_out_rdy;

        end
    endgenerate

endmodule
