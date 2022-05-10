/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/09/2022
 * ---------------------------------------------------------------
 * Pipeline module for the video core internal logic data
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module video_data_pipeline #(
    parameter WIDTH     = 12,
    parameter PIPELINE  = 1
) (
    input                       clk,
    input                       rst,
    input                       pipe_in_vld,
    output                      pipe_in_rdy,
    input  [WIDTH-1:0]          pipe_in_data,
    input                       pipe_out_rdy,
    output reg                  pipe_out_vld,
    output reg [WIDTH-1:0]      pipe_out_data
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
                    pipe_out_data <= pipe_in_data;
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

            assign pipe_out_data = pipe_in_data;
            assign pipe_out_vld = pipe_in_vld;
            assign pipe_in_rdy = pipe_out_rdy;

        end
    endgenerate

endmodule
