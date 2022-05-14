/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/14/2022
 * ---------------------------------------------------------------
 * VGA core with frame buffer using sdram
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_core_frame_buffer_sdram #(

    // Avalon Bus Parameter
    parameter AVS_DW        = 16,     // Avalon data width
    parameter AVS_AW        = 23,     // Avalon address width

    // SDRAM Architecture
    parameter SDRAM_DATA    = 16,      // SDRAM data width
    parameter SDRAM_BANK    = 4,       // SDRAM bank number
    parameter SDRAM_ROW     = 12,      // SDRAM row number
    parameter SDRAM_COL     = 8,       // SDRAM column number
    parameter SDRAM_BA      = 2,       // SDRAM BA width
    parameter SDRAM_BL      = 1,       // SDRAM burst length

    // SDRAM Timing
    parameter CLK_PERIOD    = 10,       // Clock period in ns
    parameter INIT_REF_CNT  = 2,        // Refresh count in initialization process
    parameter CL            = 2,        // CAS latency (cycle)
    parameter tINIT         = 100,      // Initialization time (us)
    parameter tRAS          = 40,       // ACTIVE-to-PRECHARGE command (ns)
    parameter tRC           = 55,       // ACTIVE-to-ACTIVE command period (ns)
    parameter tRCD          = 15,       // ACTIVE-to-READ or WRITE delay (ns)
    parameter tRFC          = 55,       // AUTO REFRESH period (ns)
    parameter tRP           = 15,       // PRECHARGE command period (ns)
    parameter tRRD          = 10,       // ACTIVE bank a to ACTIVE bank b command (ns)
    parameter tREF          = 64,       // Refresh period (ms)

    parameter RSIZE         = 4,
    parameter GSIZE         = 4,
    parameter BSIZE         = 4,
    parameter RGB_SIZE      = 12,
    parameter SRAM_AW       = 18,   // SRAM address width
    parameter SRAM_DW       = 16,   // SRAM data width
    parameter START_DELAY   = 12
) (
    // clock and reset
    input   pixel_clk,
    input   pixel_rst,
    input   sys_clk,
    input   sys_rst,

    // the source interface
    input                       src_read,
    input                       src_write,
    input   [`H_SIZE-1:0]       src_x,
    input   [`V_SIZE-1:0]       src_y,
    input   [SRAM_DW-1:0]       src_writedata,
    output  [SRAM_DW-1:0]       src_readdata,
    output                      src_readdatavalid,
    output                      src_rdy,

    // sdram interface
    output                      sdram_cs_n,
    output                      sdram_ras_n,
    output                      sdram_cas_n,
    output                      sdram_we_n,
    output                      sdram_cke,
    output [SDRAM_ROW-1:0]      sdram_addr,
    output [SDRAM_BA-1:0]       sdram_ba,
    output [SDRAM_DATA/8-1:0]   sdram_dqm,
    inout  [SDRAM_DATA-1:0]     sdram_dq,

    // vga interface
    output [RSIZE-1:0]          vga_r,
    output [GSIZE-1:0]          vga_g,
    output [BSIZE-1:0]          vga_b,
    output reg                  vga_hsync,
    output reg                  vga_vsync
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    /*AUTOWIRE*/

    /*AUTOREG*/

    reg [`H_SIZE-1:0]       h_counter;
    reg [`V_SIZE-1:0]       v_counter;
    reg                     video_on_s1;

    logic                   vga_start;
    logic [RGB_SIZE-1:0]    vga_rgb;
    logic                   h_counter_fire;
    logic                   v_counter_fire;
    logic                   h_video_on;
    logic                   v_video_on;
    logic                   video_on;

    // --------------------------------
    // main logic
    // --------------------------------

    // horizontal and vertical counter
    assign h_counter_fire = h_counter == `H_COUNT-1;
    assign v_counter_fire = v_counter == `V_COUNT-1;

    always @(posedge pixel_clk) begin
        if (pixel_rst || !vga_start) begin
            h_counter <= '0;
            v_counter <= '0;
            video_on_s1 <= '0;
        end
        else begin
            video_on_s1 <= video_on;

            if (h_counter_fire) h_counter <= 'b0;
            else h_counter <= h_counter + 1'b1;

            if (h_counter_fire) begin
                if (v_counter_fire) v_counter <= 'b0;
                else v_counter <= v_counter + 1'b1;
            end
        end
    end

    // generate hsync/vsync and drive rgb rolor value
    always @(posedge pixel_clk) begin
        vga_hsync <= (h_counter <= `H_DISPLAY+`H_FRONT_PORCH-1) ||
                     (h_counter >= `H_DISPLAY+`H_FRONT_PORCH+`H_SYNC_PULSE);
        vga_vsync <= (v_counter <= `V_DISPLAY+`V_FRONT_PORCH-1) ||
                     (v_counter >= `V_DISPLAY+`V_FRONT_PORCH+`V_SYNC_PULSE);
    end

    // SPECIAL NOTES:
    // Not sure why, but we need to delay the h_video_on by some amount
    // after the display area to make the picture showing correctly for the *DE2 board*
    /* verilator lint_off UNSIGNED */
    assign h_video_on = (h_counter >= START_DELAY) && (h_counter <= `H_DISPLAY+START_DELAY-1);
    /* verilator lint_on UNSIGNED */
    assign v_video_on = v_counter <= `V_DISPLAY-1;
    assign video_on = h_video_on & v_video_on;
    assign {vga_r, vga_g, vga_b} = video_on_s1 ? vga_rgb : 0;

    // --------------------------------
    // Module initialization
    // --------------------------------

    vga_frame_buffer_sdram
    #(
      // Parameters
      .AVS_DW                           (AVS_DW),
      .AVS_AW                           (AVS_AW),
      .SDRAM_DATA                       (SDRAM_DATA),
      .SDRAM_BANK                       (SDRAM_BANK),
      .SDRAM_ROW                        (SDRAM_ROW),
      .SDRAM_COL                        (SDRAM_COL),
      .SDRAM_BA                         (SDRAM_BA),
      .SDRAM_BL                         (SDRAM_BL),
      .CLK_PERIOD                       (CLK_PERIOD),
      .INIT_REF_CNT                     (INIT_REF_CNT),
      .CL                               (CL),
      .tINIT                            (tINIT),
      .tRAS                             (tRAS),
      .tRC                              (tRC),
      .tRCD                             (tRCD),
      .tRFC                             (tRFC),
      .tRP                              (tRP),
      .tRRD                             (tRRD),
      .tREF                             (tREF),
      .RGB_SIZE                         (RGB_SIZE))
    u_vga_frame_buffer_sdram
    (
     // Outputs
     .vga_rgb                           (vga_rgb[RGB_SIZE-1:0]),
     .vga_start                         (vga_start),
     .src_readdata                      (src_readdata[SRAM_DW-1:0]),
     .src_readdatavalid                 (src_readdatavalid),
     .src_rdy                           (src_rdy),
     .sdram_cs_n                        (sdram_cs_n),
     .sdram_ras_n                       (sdram_ras_n),
     .sdram_cas_n                       (sdram_cas_n),
     .sdram_we_n                        (sdram_we_n),
     .sdram_cke                         (sdram_cke),
     .sdram_addr                        (sdram_addr[SDRAM_ROW-1:0]),
     .sdram_ba                          (sdram_ba[SDRAM_BA-1:0]),
     .sdram_dqm                         (sdram_dqm[SDRAM_DATA/8-1:0]),
     // Inouts
     .sdram_dq                          (sdram_dq[SDRAM_DATA-1:0]),
     // Inputs
     .sys_clk                           (sys_clk),
     .sys_rst                           (sys_rst),
     .pixel_clk                         (pixel_clk),
     .pixel_rst                         (pixel_rst),
     .vga_read                          (video_on),
     .src_read                          (src_read),
     .src_write                         (src_write),
     .src_x                             (src_x[`H_SIZE-1:0]),
     .src_y                             (src_y[`V_SIZE-1:0]),
     .src_writedata                     (src_writedata[SRAM_DW-1:0]));


endmodule
