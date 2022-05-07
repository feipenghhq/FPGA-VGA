/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/02/2022
 * ---------------------------------------------------------------
 * VGA daisy system avalon control module
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vidao_daisy_system_avalon_control (
    input                   sys_clk,
    input                   sys_rst,

    input                   bar_core_bypass,
    input                   rgb2gray_core_bypass,
    input                   avalon_write,

    output                  avs_video_bar_core_address,
    output                  avs_video_bar_core_write,
    output  [31:0]          avs_video_bar_core_writedata,

    output                  avs_video_rgb2gray_core_address,
    output                  avs_video_rgb2gray_core_write,
    output  [31:0]          avs_video_rgb2gray_core_writedata
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOREGINPUT*/

    /*AUTOWIRE*/

    reg [1:0] avalon_write_stage;
    logic     avalon_write_trigger;

    // --------------------------------
    // Main logic
    // --------------------------------

    always @(posedge sys_clk) begin
      if (sys_rst) begin
        avalon_write_stage <= 0;
      end
      else begin
        avalon_write_stage <= {avalon_write_stage[0], avalon_write};
      end
    end

    assign avalon_write_trigger = avalon_write_stage[0] & ~avalon_write_stage[1];

    assign avs_video_bar_core_address = 0;
    assign avs_video_bar_core_writedata = {31'b0, bar_core_bypass};
    assign avs_video_bar_core_write = avalon_write_trigger;

    assign avs_video_rgb2gray_core_address = 0;
    assign avs_video_rgb2gray_core_writedata = {31'b0, rgb2gray_core_bypass};
    assign avs_video_rgb2gray_core_write = avalon_write_trigger;

endmodule
