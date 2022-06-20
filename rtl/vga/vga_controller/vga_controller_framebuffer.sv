/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/27/2022
 * ---------------------------------------------------------------
 * VGA core with frame buffer
 * ---------------------------------------------------------------
 *
 * The frame buffer is generally a 2 RW ports memory.
 * It holds the pixel for the entire frame displayed on the screen.
 *
 * 1 RW port is accessed by the upstream pixel processing logic.
 * 1 RW port is accessed by the vga core to retrieve the pixel data.
 *
 * This module is a wrapper for the memory, it provides 2 avalon
 * interface to access the actual memory so the memory can be
 * build with different memory such as FPGA onchip memory,
 * off-chip sram or off-chip sdram.
 *
 * On the VGA read side, we use an asynchronous FIFO as a prefetch
 * buffer. The pixel is prefetched from the memory into the fifo
 * to hide the latency of the memory in case the memory needs several
 * clock cycles to return the data.
 *
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_controller_framebuffer #(
    parameter AVN_AW        = 19,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    parameter BUF_SIZE      = 32,   // prefetch bufer size
    parameter START_DELAY   = 12
)(
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // vga interface
    output [`R_SIZE-1:0]    vga_r,
    output [`G_SIZE-1:0]    vga_g,
    output [`B_SIZE-1:0]    vga_b,
    output reg              vga_hsync,
    output reg              vga_vsync,

    // source avalon interface
    input                   framebuffer_avn_read,
    input                   framebuffer_avn_write,
    input  [AVN_AW-1:0]     framebuffer_avn_address,
    input  [AVN_DW-1:0]     framebuffer_avn_writedata,
    input  [AVN_DW/8-1:0]   framebuffer_avn_byteenable,
    output [AVN_DW-1:0]     framebuffer_avn_readdata,
    output                  framebuffer_avn_readdatavalid,
    output                  framebuffer_avn_waitrequest,

    // memory port 1 avalon interface - sys_clk, used by the pixel processing logic
    output                  pro_avn_read,
    output                  pro_avn_write,
    output [AVN_AW-1:0]     pro_avn_address,
    output [AVN_DW-1:0]     pro_avn_writedata,
    output [AVN_DW/8-1:0]   pro_avn_byteenable,
    input  [AVN_DW-1:0]     pro_avn_readdata,
    input                   pro_avn_readdatavalid,
    input                   pro_avn_waitrequest,

    // memory port 2 avalon interface - sys_clk, used by the vga sync logic
    output                  pxl_avn_read,
    output                  pxl_avn_write,
    output [AVN_AW-1:0]     pxl_avn_address,
    output [AVN_DW-1:0]     pxl_avn_writedata,
    output [AVN_DW/8-1:0]   pxl_avn_byteenable,
    input  [AVN_DW-1:0]     pxl_avn_readdata,
    input                   pxl_avn_readdatavalid,
    input                   pxl_avn_waitrequest
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    localparam NUM_BYTE = AVN_DW / 8;
    localparam MAX_READ = 4;

    logic               vga_sync_vga_hsync;
    logic               vga_sync_vga_vsync;
    logic               vga_sync_video_on;
    logic               vga_sync_vga_start;

    logic [AVN_DW-1:0]  vga_prefetch_buffer_dout;
    logic [AVN_DW-1:0]  vga_prefetch_buffer_din;
    logic               vga_prefetch_buffer_empty;
    logic               vga_prefetch_buffer_afull;
    logic               vga_prefetch_buffer_read;
    logic               vga_prefetch_buffer_write;

    reg [`H_SIZE-1:0]   h_counter;
    reg [`V_SIZE-1:0]   v_counter;

    logic               h_counter_fire;
    logic               v_counter_fire;

    reg [$clog2(MAX_READ+1)-1:0] pxl_read_cnt;
    logic               pxl_avn_read_fire;

    // ------------------------------
    // Main logic
    // ------------------------------

    assign pro_avn_read = framebuffer_avn_read;
    assign pro_avn_write = framebuffer_avn_write;
    assign pro_avn_address = framebuffer_avn_address;
    assign pro_avn_writedata = framebuffer_avn_writedata;
    assign pro_avn_byteenable = framebuffer_avn_byteenable;

    assign framebuffer_avn_readdata = pro_avn_readdata;
    assign framebuffer_avn_readdatavalid = pro_avn_readdatavalid;
    assign framebuffer_avn_waitrequest = pro_avn_waitrequest;

    // the prefetch buffer logic talks to ram port 2
    assign pxl_avn_write = 0;
    assign pxl_avn_writedata = 0;
    assign pxl_avn_byteenable = {NUM_BYTE{1'b1}};
    assign pxl_avn_address = ({{(AVN_AW-`H_SIZE){1'b0}}, h_counter} + v_counter * `H_DISPLAY);

    // whenever there are space in the prefetch buffer, fill it.
    assign pxl_avn_read = ~vga_prefetch_buffer_afull & (pxl_read_cnt < MAX_READ);
    assign pxl_avn_read_fire = pxl_avn_read && !pxl_avn_waitrequest;

    // because we use avalon pipelined interface here, we need to keep track of the read request we send
    // if we have already send enough read request to the memory, we should wait
    always @(posedge sys_clk) begin
        if (sys_rst) pxl_read_cnt <= 0;
        else begin
            case ({pxl_avn_read_fire, pxl_avn_readdatavalid})
                2'b00: pxl_read_cnt <= pxl_read_cnt;
                2'b01: pxl_read_cnt <= pxl_read_cnt - 1;
                2'b10: pxl_read_cnt <= pxl_read_cnt + 1;
                2'b11: pxl_read_cnt <= pxl_read_cnt;
            endcase
        end
    end

    // push the data into the prefetch fifo when the read data is available
    assign vga_prefetch_buffer_write = pxl_avn_readdatavalid;
    assign vga_prefetch_buffer_din = pxl_avn_readdata;

    // fetch the data from the prefetch fifo when vga display is on
    assign vga_prefetch_buffer_read = vga_sync_video_on;

    assign {vga_r, vga_g, vga_b} = vga_prefetch_buffer_dout[`RGB_SIZE-1:0];

    // internal h_counter and v_counter for the vram address
    assign h_counter_fire = (h_counter == `H_DISPLAY-1);
    assign v_counter_fire = (v_counter == `V_DISPLAY-1);

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            h_counter <= '0;
            v_counter <= '0;
        end
        // when the read request is taken, advance the counter
        else if (pxl_avn_read_fire) begin
            if (h_counter_fire) h_counter <= 'b0;
            else h_counter <= h_counter + 1'b1;
            if (h_counter_fire) begin
                if (v_counter_fire) v_counter <= 'b0;
                else v_counter <= v_counter + 1'b1;
            end
        end
    end

    // For better synchronization, we should fill up the fifo before vga start, so we have
    // enough data in the fifo for the vga size to read.
    // Ideally we need to have a cdc logic here for vga_prefetch_buffer_afull as it is in the write sde but since
    // vga_start is quasi static so we should be good

    always @(posedge pixel_clk) begin
        if (pixel_rst) vga_sync_vga_start <= 0;
        else vga_sync_vga_start <= vga_sync_vga_start | vga_prefetch_buffer_afull;
    end

    always @(posedge pixel_clk) begin
        vga_hsync <= vga_sync_vga_hsync;
        vga_vsync <= vga_sync_vga_vsync;
    end

    // ------------------------------
    // Module initialization
    // ------------------------------

    vga_sync #(
        .START_DELAY    (START_DELAY),
        .SCAN_END       (0),
        .DISP_END       (0)
    )
    u_vga_sync
    (
        .pixel_clk      (pixel_clk),
        .pixel_rst      (pixel_rst),
        .vga_start      (vga_sync_vga_start),
        .vga_hsync      (vga_sync_vga_hsync),
        .vga_vsync      (vga_sync_vga_vsync),
        .video_on       (vga_sync_video_on),
        .scan_end       (),
        .disp_end       ()
    );

    vga_async_fifo
    #(
      // Parameters
      .WIDTH        (AVN_DW),
      .DEPTH        (BUF_SIZE),
      .AFULL_THRES  (MAX_READ))
    u_vga_prefetch_buffer
    (
     // Outputs
     .dout                              (vga_prefetch_buffer_dout),
     .empty                             (vga_prefetch_buffer_empty),
     .full                              (),
     .afull                             (vga_prefetch_buffer_afull),
     // Inputs
     .rst_rd                            (pixel_rst),
     .clk_rd                            (pixel_clk),
     .read                              (vga_prefetch_buffer_read),
     .rst_wr                            (sys_rst),
     .clk_wr                            (sys_clk),
     .din                               (vga_prefetch_buffer_din),
     .write                             (vga_prefetch_buffer_write));

endmodule
