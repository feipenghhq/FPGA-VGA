/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA controller with line buffer
 * ---------------------------------------------------------------
 *
 * A line buffer is generally an asynchronous FIFO that stores
 * ONE line of the frame. The upstream logic write the pixel rgb
 * data into the FIFO and the vga sync logic read pixel from the
 * FIFO.
 *
 * The FIFO can only hold the data for ONE line of the frame hance
 * the name line buffer.
 *
 * ---------------------------------------------------------------
 * 05/12/2022:
 *  Merged the vga_sync module with vga_sync_core and rename the
 *  module to vga_core_linebuffer
 * 05/27/2022:
 *  Redesigned the module. Moved the hsync/vsync logic into a
 *  separate module. Merged vga_linebuffer module.
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_controller_linebuffer #(
    parameter START_DELAY = 12
) (
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    // line buffer source
    input [`RGB_SIZE:0]     linebuffer_data,
    input                   linebuffer_vld,
    output                  linebuffer_rdy,

    // vga interface
    output reg [`R_SIZE-1:0]  vga_r,
    output reg [`G_SIZE-1:0]  vga_g,
    output reg [`B_SIZE-1:0]  vga_b,

    output reg              vga_hsync,
    output reg              vga_vsync
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    localparam              LINEBUFFER_DEPTH = 1024;
    localparam              LINEBUFFER_WIDTH = `RGB_SIZE+1;

    localparam logic        S_SYNC = 0;
    localparam logic        S_DISP = 1;
    reg                     state;

    logic                   vga_sync_vga_hsync;
    logic                   vga_sync_vga_vsync;
    logic                   vga_sync_video_on;
    logic                   vga_sync_scan_end;
    logic                   vga_sync_disp_end;
    logic                   vga_frame_start;

    logic                   linebuffer_empty;
    logic                   linebuffer_full;
    logic                   linebuffer_write;
    logic                   linebuffer_read;
    logic [`RGB_SIZE:0]     linebuffer_dout;


    // --------------------------------
    // main logic
    // --------------------------------

    always @(posedge pixel_clk) begin
        vga_hsync <= vga_sync_vga_hsync;
        vga_vsync <= vga_sync_vga_vsync;
        {vga_r, vga_g, vga_b} <= vga_sync_video_on ? linebuffer_dout[`RGB_SIZE-1:0] : '0;
    end

    always @(posedge pixel_clk) begin
        if (pixel_rst) begin
            state <= S_SYNC;
        end
        else begin
            if (vga_sync_scan_end && vga_frame_start)   state <= S_DISP;
            else if (vga_sync_disp_end)                 state <= S_SYNC;
        end
    end

    always @* begin
        linebuffer_read = 1'b0;
        case(state)
            S_SYNC: linebuffer_read = ~vga_frame_start; // pop the remaining frames out of the fifo
            S_DISP: linebuffer_read = vga_sync_video_on;
        endcase
    end

    assign linebuffer_write = linebuffer_vld & linebuffer_rdy;
    assign linebuffer_rdy = ~linebuffer_full;

    assign vga_frame_start = linebuffer_dout[`RGB_SIZE];

    // --------------------------------
    // Module initialization
    // --------------------------------


    vga_sync #(
        .START_DELAY    (START_DELAY),
        .SCAN_END       (1),
        .DISP_END       (1)
    )
    u_vga_sync
    (
        .pixel_clk      (pixel_clk),
        .pixel_rst      (pixel_rst),
        .vga_start      (1'b1),
        .vga_hsync      (vga_sync_vga_hsync),
        .vga_vsync      (vga_sync_vga_vsync),
        .video_on       (vga_sync_video_on ),
        .scan_end       (vga_sync_scan_end ),
        .disp_end       (vga_sync_disp_end )
    );

    vga_async_fifo
    #(
      .WIDTH            (LINEBUFFER_WIDTH),
      .DEPTH            (LINEBUFFER_DEPTH))
    u_vga_linebuffer
    (
     // Outputs
     .dout              (linebuffer_dout),
     .empty             (linebuffer_empty),
     .full              (linebuffer_full),
     .afull             (),
     // Inputs
     .rst_rd            (pixel_rst),
     .clk_rd            (pixel_clk),
     .read              (linebuffer_read),
     .rst_wr            (sys_rst),
     .clk_wr            (sys_clk),
     .din               (linebuffer_data),
     .write             (linebuffer_write));


endmodule
