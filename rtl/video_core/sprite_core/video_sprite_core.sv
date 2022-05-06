/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/05/2022
 * ---------------------------------------------------------------
 * Sprite core
 *
 * Register Spec
 * - 0x0 ctrl
 *      - bit [0:0] bypass = 0
 * - 0x4 x_origin
 *      - bit [31:0] value = 0
 * - 0x8 y_origin
 *      - bit [31:0] value = 0
 * - 0x10 ~ sprite ram
 *      - sprite ram addr = avalon addr [MSB:1]
 *
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

`include "vga.svh"

 module video_sprite_core #(
    parameter RGB_SIZE      = 12,
    parameter SPRITE_HSIZE  = 32,   // 32x32 pixel sprite
    parameter SPRITE_VSIZE  = 32,
    parameter SPRITE_RAM_AW = 10
) (
    input                       clk,
    input                       rst,

    // avalon interface
    input                       avs_write,
    input [SPRITE_RAM_AW:0]     avs_address,
    input [31:0]                avs_writedata,

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
    // Signal declarations
    // --------------------------------

    // Register interface
    // 0x0 ctrl
    reg                 ctrl_bypass;
    logic               ctrl_wen;
    // 0x4 x_origin
    reg [31:0]          x_origin;
    logic               x_origin_wen;
    // 0x8 y_origin
    reg [31:0]          y_origin;
    logic               y_origin_wen;

    /*AUTOWIRE*/

    /*AUTOREG*/

    /*AUTOREGINPUT*/

    logic [RGB_SIZE-1:0]        pipe_out_rgb;

    logic [RGB_SIZE-1:0]        sprite_rgb;
    logic [SPRITE_RAM_AW-1:0]   sprite_ram_addr_w;
    logic [RGB_SIZE-1:0]        sprite_ram_din;
    logic                       sprite_ram_we;

    // --------------------------------
    // Register interface
    // --------------------------------

    assign ctrl_wen = avs_write & (avs_address == 0);
    assign x_origin_wen = avs_write & (avs_address == 4);
    assign y_origin_wen = avs_write & (avs_address == 8);

    always @(posedge clk) begin
        if (rst) begin
            ctrl_bypass <= '0;
            x_origin <= '0;
            y_origin <= '0;
        end
        else begin
            if (ctrl_wen) begin
                ctrl_bypass <= avs_writedata[0];
            end
            if (x_origin_wen) begin
                x_origin <= avs_writedata;
            end
            if (y_origin_wen) begin
                y_origin <= avs_writedata;
            end
        end
    end

    // --------------------------------
    // Main logic
    // --------------------------------

    assign sprite_ram_we = avs_write & (avs_address > 8);
    assign sprite_ram_din = avs_writedata[RGB_SIZE-1:0];
    assign sprite_ram_addr_w = avs_address[SPRITE_RAM_AW:1];

    assign snk_rgb = sprite_rgb;

    // --------------------------------
    // Module initialization
    // --------------------------------

     /* video_sprite_gen AUTO_TEMPLATE (
         .x0        (x_origin),
         .y0        (y_origin),
         .xx        (src_fc.hc),
         .yy        (src_fc.vc),
         .src_rgb   (pipe_out_rgb),
    );
    */
    video_sprite_gen
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RGB_SIZE                         (RGB_SIZE),
      .SPRITE_HSIZE                     (SPRITE_HSIZE),
      .SPRITE_VSIZE                     (SPRITE_VSIZE),
      .SPRITE_RAM_AW                    (SPRITE_RAM_AW))
    u_video_sprite_gen
    (/*AUTOINST*/
     // Outputs
     .sprite_rgb                        (sprite_rgb[RGB_SIZE-1:0]),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .x0                                (x_origin),              // Templated
     .y0                                (y_origin),              // Templated
     .sprite_ram_we                     (sprite_ram_we),
     .sprite_ram_addr_w                 (sprite_ram_addr_w[SPRITE_RAM_AW-1:0]),
     .sprite_ram_din                    (sprite_ram_din[RGB_SIZE-1:0]),
     .xx                                (src_fc.hc),             // Templated
     .yy                                (src_fc.vc),             // Templated
     .src_rgb                           (pipe_out_rgb));          // Templated


    /* video_core_pipeline AUTO_TEMPLATE (
        .pipe_in_\(.*\)     (src_\1),
        .pipe_out_rgb       (pipe_out_rgb[]),
        .pipe_out_\(.*\)    (snk_\1),
    );
    */
    video_core_pipeline
    #(
      // Parameters
      .RGB_SIZE                         (RGB_SIZE),
      .PIPELINE                         (1))
    u_video_core_pipeline
    (/*AUTOINST*/
     // Interfaces
     .pipe_in_fc                        (src_fc),                // Templated
     .pipe_out_fc                       (snk_fc),                // Templated
     // Outputs
     .pipe_in_rdy                       (src_rdy),               // Templated
     .pipe_out_vld                      (snk_vld),               // Templated
     .pipe_out_rgb                      (pipe_out_rgb[RGB_SIZE-1:0]), // Templated
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
