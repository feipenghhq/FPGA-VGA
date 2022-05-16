/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/12/2022
 * ---------------------------------------------------------------
 * Frame buffer using SRAM
 *
 * The frame buffer needs two separate ports for the pixel generation
 * logic and the vga controller. The two ports also run in different
 * clock domains. The pixel clock is generally slow and we want to run
 * the sram in the system clock so the pixel gneration can generate the
 * pixel as fast as possible.
 *
 * To make the SRAM having 2 separate port and also cross clock domains
 * for the pixel clock.
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_frame_buffer_sram #(
    // avalon bus parameters
    parameter AVN_AW        = 18,   // avalon address width
    parameter AVN_DW        = 16,   // avalon data width
    // frame buffer parameters
    parameter RGB_SIZE      = 12,
    parameter PF_BUF_SIZE   = 8     // prefetch bufer size
)(
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // the vga interface is a stream interface
    input                   vga_read,
    output [RGB_SIZE-1:0]   vga_rgb,
    output reg              vga_start,

    // source avalon interface
    input                   src_avn_read,
    input                   src_avn_write,
    input  [AVN_AW-1:0]     src_avn_address,
    input  [AVN_DW-1:0]     src_avn_writedata,
    output [AVN_DW-1:0]     src_avn_readdata,
    output                  src_avn_waitrequest,

    // sram avalon interface
    output                  sram_avn_read,
    output                  sram_avn_write,
    output [AVN_AW-1:0]     sram_avn_address,
    output [AVN_DW-1:0]     sram_avn_writedata,
    output [AVN_DW/8-1:0]   sram_avn_byteenable,
    input  [AVN_DW-1:0]     sram_avn_readdata
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    reg [`H_SIZE-1:0]   h_counter;
    reg [`V_SIZE-1:0]   v_counter;

    logic               h_counter_fire;
    logic               v_counter_fire;

    logic [AVN_DW-1:0]  vga_prefetch_buffer_dout;
    logic [AVN_DW-1:0]  vga_prefetch_buffer_din;
    logic               vga_prefetch_buffer_empty;
    logic               vga_prefetch_buffer_afull;
    logic               vga_prefetch_buffer_full;
    logic               vga_prefetch_buffer_read;
    logic               vga_prefetch_buffer_write;

    reg                 vga_sram_avn_read_s1;
    logic               vga_sram_avn_read;
    logic [AVN_AW-1:0]  vga_sram_avn_address;

    logic               vga_sram_avn_grant;

    // ------------------------------
    // Main logic
    // ------------------------------

    // ---- src side read/write logic -----

    assign src_avn_waitrequest = vga_sram_avn_grant;
    assign src_avn_readdata = sram_avn_readdata;

    // ---- VGA side read logic -----

    // let the synthesis figure out * operation
    assign vga_sram_avn_address = ({{(AVN_AW-`H_SIZE){1'b0}}, h_counter} + v_counter * `H_DISPLAY) ;
    assign vga_sram_avn_read = ~vga_prefetch_buffer_afull;

    assign vga_prefetch_buffer_write = vga_sram_avn_read_s1; // the sram has a read latency of 1
    assign vga_prefetch_buffer_din = sram_avn_readdata;
    assign vga_prefetch_buffer_read = vga_read;
    assign vga_rgb = vga_prefetch_buffer_dout[RGB_SIZE-1:0];

    // internal h_counter and v_counter for the vga side sram address
    assign h_counter_fire = (h_counter == `H_DISPLAY-1);
    assign v_counter_fire = (v_counter == `V_DISPLAY-1);
    always @(posedge sys_clk) begin
        if (sys_rst) begin
            h_counter <= '0;
            v_counter <= '0;
        end
        else if (vga_sram_avn_read) begin
            if (h_counter_fire) h_counter <= 'b0;
            else h_counter <= h_counter + 1'b1;
            if (h_counter_fire) begin
                if (v_counter_fire) v_counter <= 'b0;
                else v_counter <= v_counter + 1'b1;
            end
        end
    end

    always @(posedge sys_clk) begin
        if (sys_rst) vga_sram_avn_read_s1 <= 'b0;
        else vga_sram_avn_read_s1 <= vga_sram_avn_read;
    end

    // ---- arbitration between the sram access ----

    // the vga logic has higher priority than the pixel generation logic
    assign vga_sram_avn_grant = vga_sram_avn_read;

    assign sram_avn_write = vga_sram_avn_grant ? 1'b0 : src_avn_write;
    assign sram_avn_read = vga_sram_avn_grant ? vga_sram_avn_read : src_avn_read;
    assign sram_avn_address = vga_sram_avn_grant ? vga_sram_avn_address : src_avn_address;
    assign sram_avn_writedata = src_avn_writedata;
    assign sram_avn_byteenable = {(AVN_DW/8){1'b1}};

    // --- other logic ----

    // for better synchronization, we should fill up the fifo before vga start.
    // ideally we should have a cdc logic here for vga_prefetch_buffer_full but since
    // vga_start is quasi static so we should be good.
    always @(posedge pixel_clk) begin
        if (pixel_rst) vga_start <= 1'b0;
        else if (!vga_start && vga_prefetch_buffer_afull) vga_start <= 1'b1;
    end

    // ------------------------------
    // Module initialization
    // ------------------------------

    vga_async_fifo
    #(
      // Parameters
      .WIDTH        (AVN_DW),
      .DEPTH        (PF_BUF_SIZE),
      .AFULL_THRES  (1))
    u_vga_prefetch_buffer
    (
     // Outputs
     .dout                              (vga_prefetch_buffer_dout),
     .empty                             (vga_prefetch_buffer_empty),
     .full                              (vga_prefetch_buffer_full),
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