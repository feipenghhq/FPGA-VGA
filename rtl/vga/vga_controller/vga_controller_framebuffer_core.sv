/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/27/2022
 * ---------------------------------------------------------------
 * VGA core with frame buffer core logic
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

module vga_controller_framebuffer_core #(
    parameter AVN_AW        = 19,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    parameter BUF_SIZE      = 32,   // prefetch bufer size
    parameter START_DELAY   = 10,
    parameter MAX_READ      = 4     // max pending read for the pipelined interface
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

    // vga side avalon interface - sys_clkc
    output                  vga_avn_read,
    output                  vga_avn_write,
    output [AVN_AW-1:0]     vga_avn_address,
    output [AVN_DW-1:0]     vga_avn_writedata,
    output [AVN_DW/8-1:0]   vga_avn_byteenable,
    input  [AVN_DW-1:0]     vga_avn_readdata,
    input                   vga_avn_readdatavalid,
    input                   vga_avn_waitrequest
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    localparam NUM_BYTE = AVN_DW / 8;


    reg                 video_on;
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

    reg [$clog2(MAX_READ+1)-1:0] vga_read_cnt;
    logic               vga_avn_read_fire;

    // ------------------------------
    // Main logic
    // ------------------------------

    // the prefetch buffer logic talks to ram port 2
    assign vga_avn_write = 0;
    assign vga_avn_writedata = 0;
    assign vga_avn_byteenable = {NUM_BYTE{1'b1}};
    assign vga_avn_address = ({{(AVN_AW-`H_SIZE){1'b0}}, h_counter} + v_counter * `H_DISPLAY);

    // whenever there are space in the prefetch buffer, fill it.
    assign vga_avn_read = ~vga_prefetch_buffer_afull & (vga_read_cnt < MAX_READ);
    assign vga_avn_read_fire = vga_avn_read && !vga_avn_waitrequest;

    // because we use avalon pipelined interface here, we need to keep track of the read request we send
    // if we have already send enough read request to the memory, we should wait
    always @(posedge sys_clk) begin
        if (sys_rst) vga_read_cnt <= 0;
        else begin
            case ({vga_avn_read_fire, vga_avn_readdatavalid})
                2'b00: vga_read_cnt <= vga_read_cnt;
                2'b01: vga_read_cnt <= vga_read_cnt - 1;
                2'b10: vga_read_cnt <= vga_read_cnt + 1;
                2'b11: vga_read_cnt <= vga_read_cnt;
            endcase
        end
    end

    // push the data into the prefetch fifo when the read data is available
    assign vga_prefetch_buffer_write = vga_avn_readdatavalid;
    assign vga_prefetch_buffer_din = vga_avn_readdata;

    // fetch the data from the prefetch fifo when vga display is on
    assign vga_prefetch_buffer_read = vga_sync_video_on;

    // !! The RGB value needs to be cleared to zero when the video is not on. otherwise the display
    // will be creepy
    assign {vga_r, vga_g, vga_b} = video_on ? vga_prefetch_buffer_dout[`RGB_SIZE-1:0] : 'b0;

    // internal h_counter and v_counter for the vram address
    assign h_counter_fire = (h_counter == `H_DISPLAY-1);
    assign v_counter_fire = (v_counter == `V_DISPLAY-1);

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            h_counter <= '0;
            v_counter <= '0;
        end
        // when the read request is taken, advance the counter
        else if (vga_avn_read_fire) begin
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
        video_on <= vga_sync_video_on;
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
