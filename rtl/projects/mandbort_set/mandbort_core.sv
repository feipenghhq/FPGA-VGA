/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/23/2022
 * ---------------------------------------------------------------
 * mandbort set core
 *
 * Instantiates one or more ms_cal_cluster to calculate the mandbort
 * set and send the data to vram
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module mandbort_core #(
    parameter WIDTH     = 16,       // totoal size of the number
    parameter REALW     = 4,        // size of the real part
    parameter MAX_ITER  = 4095,     // we have 12 bit color so we use 4095 here
    parameter THRESHOLD = 4 << 12,  // use 4 here bcause we don't do the sqrt
    parameter ITERW     = $clog2(MAX_ITER),
    parameter AVN_AW    = 19,
    parameter AVN_DW    = 16
) (
    input                   clk,
    input                   rst,

    input                   start,

    output reg [AVN_AW-1:0] mandbort_avn_address,
    output reg              mandbort_avn_write,
    output reg [AVN_DW-1:0] mandbort_avn_writedata,
    input                   mandbort_avn_waitrequest
);

    localparam [WIDTH-1:0] DELTA_X = (3 << 12) / `H_DISPLAY;
    localparam [WIDTH-1:0] DELTA_Y = (2 << 12) / `V_DISPLAY;
    localparam [WIDTH-1:0] START_X = (-2) << 12;
    localparam [WIDTH-1:0] START_Y = (-1) << 12;

    // --------------------------------
    // Signal declarations
    // --------------------------------

    logic                   cluster_start;
    logic                   cluster_stall;
    logic [`H_SIZE-1:0]     cluster_cur_x_cnt;
    logic [`V_SIZE-1:0]     cluster_cur_y_cnt;
    logic [ITERW-1:0]       cluster_iter;
    logic                   cluster_iter_vld;

    // --------------------------------
    // main logic
    // --------------------------------

    always @(posedge clk) begin
        /* verilator lint_off WIDTH */
        mandbort_avn_address <= cluster_cur_x_cnt + cluster_cur_y_cnt * `H_DISPLAY;
        mandbort_avn_writedata <= cluster_iter;
        /* verilator lint_on WIDTH */
        mandbort_avn_write <= cluster_iter_vld | mandbort_avn_waitrequest & mandbort_avn_write;
    end

    assign cluster_stall = mandbort_avn_waitrequest;
    assign cluster_start = start;

    // --------------------------------
    // Module initialization
    // --------------------------------

    mandbort_cal_cluster #(
      .WIDTH        (WIDTH),
      .REALW        (REALW),
      .MAX_ITER     (MAX_ITER),
      .THRESHOLD    (THRESHOLD),
      .ITERW        (ITERW),
      .XCNT_SIZE    (`H_SIZE),
      .YCNT_SIZE    (`V_SIZE))
    u_mandbort_cal_cluster (
      .clk          (clk),
      .rst          (rst),
      .delta_x      (DELTA_X),
      .delta_y      (DELTA_Y),
      .start_x      (START_X),
      .start_y      (START_Y),
      .x_count      (`H_DISPLAY),
      .y_count      (`V_DISPLAY),
      .start        (cluster_start),
      .stall        (cluster_stall),
      .cur_x_cnt    (cluster_cur_x_cnt),
      .cur_y_cnt    (cluster_cur_y_cnt),
      .iter         (cluster_iter),
      .iter_vld     (cluster_iter_vld),
      .cal_done     ()
    );


endmodule