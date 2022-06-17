/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * This module contains a daisy chain of different video cores
 * ---------------------------------------------------------------
 */

/*
  _________      ______      _____________      _____________      __________
 |  Frame  |    | bar  |    |   pikachu   |    |   pacman    |    | rgb2gray |
 | counter | -> | core | -> | sprite core | -> | sprite core | -> |   core   | -> Downstream
 |_________|    |______|    |_____________|    |_____________|    |__________|
*/


`include "vga.svh"

module video_daisy_core
(
    input                   sys_clk,
    input                   sys_rst,

    input                   stall,
    input                   bar_core_bypass,
    input                   pikachu_core_bypass,
    input                   pacman_core_bypass,
    input                   rgb2gray_core_bypass,

    // down stream
    output reg              daisy_system_vld,
    output vga_frame_t      daisy_system_frame
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOWIRE*/



    localparam PIPELINE = 1;
    localparam SPRITE_HSIZE  = 32;
    localparam SPRITE_VSIZE  = 32;
    localparam SPRITE_RAM_AW = 10;

    logic [`H_SIZE-1:0]     fc_hcount;
    logic [`V_SIZE-1:0]     fc_vcount;
    logic                   fc_enable;
    logic                   frame_start;
    logic                   frame_display;

    vga_frame_t             bar_core_src_frame;
    logic                   bar_core_src_vld;

    vga_frame_t             pikachu_core_src_frame;
    logic                   pikachu_core_src_vld;

    vga_frame_t             pacman_core_src_frame;
    logic                   pacman_core_src_vld;

    vga_frame_t             rgb2gray_core_src_frame;
    logic                   rgb2gray_core_src_vld;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign fc_enable = ~stall;

    assign bar_core_src_frame.hc = fc_hcount;
    assign bar_core_src_frame.vc = fc_vcount;
    assign bar_core_src_frame.start = frame_start;
    assign bar_core_src_vld = frame_display;

    // --------------------------------
    // Module Declaration
    // --------------------------------

    /* vga_frame_counter AUTO_TEMPLATE (
     .clk       (sys_clk),
     .rst       (sys_rst),
     .fc_clear  (1'b0),
     .frame_end (),
    );
    */
    vga_frame_counter
    u_vga_frame_counter
    (/*AUTOINST*/
     // Outputs
     .fc_hcount                         (fc_hcount[`H_SIZE-1:0]),
     .fc_vcount                         (fc_vcount[`V_SIZE-1:0]),
     .frame_start                       (frame_start),
     .frame_end                         (),                      // Templated
     .frame_display                     (frame_display),
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .fc_clear                          (1'b0),                  // Templated
     .fc_enable                         (fc_enable));

    /* video_bar_core AUTO_TEMPLATE (
     //
     .clk           (sys_clk),
     .rst           (sys_rst),
     .source_\(.*\) (bar_core_src_\1),
     .sink_\(.*\)   (pikachu_core_src_\1),
     .bypass        (bar_core_bypass),
    );
    */
    video_bar_core
    u_bar_core
    (/*AUTOINST*/
     // Interfaces
     .source_frame                      (bar_core_src_frame),    // Templated
     .sink_frame                        (pikachu_core_src_frame), // Templated
     // Outputs
     .sink_vld                          (pikachu_core_src_vld),  // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .stall                             (stall),
     .bypass                            (bar_core_bypass),       // Templated
     .source_vld                        (bar_core_src_vld));      // Templated

    /* video_sprite_core AUTO_TEMPLATE (
     .clk           (sys_clk),
     .rst           (sys_rst),
     .source_\(.*\) (pikachu_core_src_\1),
     .sink_\(.*\)   (pacman_core_src_\1),
     .bypass        (pikachu_core_bypass),
     .x0            (32),
     .y0            (32),
     .sprite_ram\(.*\) (0),
    );
    */
    video_sprite_core
    #(
      .MEM_FILE                         ("pikachu_32x32.mem"),
      .SPRITE_HSIZE                     (SPRITE_HSIZE),
      .SPRITE_VSIZE                     (SPRITE_VSIZE),
      .SPRITE_RAM_AW                    (SPRITE_RAM_AW))
    u_pikachu_core
    (/*AUTOINST*/
     // Interfaces
     .source_frame                      (pikachu_core_src_frame), // Templated
     .sink_frame                        (pacman_core_src_frame), // Templated
     // Outputs
     .sink_vld                          (pacman_core_src_vld),   // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .stall                             (stall),
     .bypass                            (pikachu_core_bypass),   // Templated
     .source_vld                        (pikachu_core_src_vld),  // Templated
     .x0                                (32),                    // Templated
     .y0                                (32),                    // Templated
     .sprite_ram_we                     (0),                     // Templated
     .sprite_ram_addr_w                 (0),                     // Templated
     .sprite_ram_din                    (0));                     // Templated

    /* video_sprite_animation_core AUTO_TEMPLATE (
     .clk           (sys_clk),
     .rst           (sys_rst),
     .source_\(.*\) (pacman_core_src_\1),
     .sink_\(.*\)   (rgb2gray_core_src_\1),
     .bypass        (pacman_core_bypass),
     .x0            (64),
     .y0            (64),
     .sprite_ram\(.*\) (0),
     .sprite_rate   (10000000),
    );
    */
    localparam PACMAN_SPRITE_IDXW = 2;
    localparam PACMAN_SPRITE_NUM = 4;

    video_sprite_animation_core
    #(
      .SPRITE_HSIZE   (SPRITE_HSIZE),
      .SPRITE_VSIZE   (SPRITE_VSIZE),
      .SPRITE_AW      (SPRITE_RAM_AW),
      .SPRITE_IDXW    (PACMAN_SPRITE_IDXW),
      .SPRITE_RAM_AW  (SPRITE_RAM_AW+PACMAN_SPRITE_IDXW),
      .SPRITE_NUM     (PACMAN_SPRITE_NUM),
      .MEM_FILE       ("pacman.mem")
    )
    u_pacman_core
    (/*AUTOINST*/
     // Interfaces
     .source_frame                      (pacman_core_src_frame), // Templated
     .sink_frame                        (rgb2gray_core_src_frame), // Templated
     // Outputs
     .sink_vld                          (rgb2gray_core_src_vld), // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .stall                             (stall),
     .bypass                            (pacman_core_bypass),    // Templated
     .sprite_rate                       (10000000),              // Templated
     .source_vld                        (pacman_core_src_vld),   // Templated
     .x0                                (64),                    // Templated
     .y0                                (64),                    // Templated
     .sprite_ram_we                     (0),                     // Templated
     .sprite_ram_addr_w                 (0),                     // Templated
     .sprite_ram_din                    (0));                     // Templated


    /* video_rgb2gray_core AUTO_TEMPLATE (
     //
     .clk           (sys_clk),
     .rst           (sys_rst),
     .source_\(.*\) (rgb2gray_core_src_\1),
     .sink_\(.*\)   (daisy_system_\1),
     .bypass        (rgb2gray_core_bypass),
    )
    */
    video_rgb2gray_core
    u_video_rgb2gray_core
    (/*AUTOINST*/
     // Interfaces
     .source_frame                      (rgb2gray_core_src_frame), // Templated
     .sink_frame                        (daisy_system_frame),    // Templated
     // Outputs
     .sink_vld                          (daisy_system_vld),      // Templated
     // Inputs
     .clk                               (sys_clk),               // Templated
     .rst                               (sys_rst),               // Templated
     .stall                             (stall),
     .bypass                            (rgb2gray_core_bypass),  // Templated
     .source_vld                        (rgb2gray_core_src_vld)); // Templated

endmodule

// Local Variables:
// verilog-library-flags:("-y ../vga_controller/  -y ../video_core/*/")
// End:
