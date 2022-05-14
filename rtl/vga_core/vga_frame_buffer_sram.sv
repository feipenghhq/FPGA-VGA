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
    parameter SRAM_AW       = 18,   // SRAM address width
    parameter SRAM_DW       = 16,   // SRAM data width
    parameter RGB_SIZE      = 12,
    parameter BUFFER_SIZE   = 8
)(
    input                   sys_clk,
    input                   sys_rst,

    input                   pixel_clk,
    input                   pixel_rst,

    // the vga interface is a stream interface
    input                   vga_read,
    output [RGB_SIZE-1:0]   vga_rgb,
    output reg              vga_start,

    // the source interface is a memory mapped
    input                   src_read,
    input                   src_write,
    input  [`H_SIZE-1:0]    src_x,
    input  [`V_SIZE-1:0]    src_y,
    input  [SRAM_DW-1:0]    src_writedata,
    output [SRAM_DW-1:0]    src_readdata,
    output                  src_rdy,

    // the sram interface
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output [SRAM_DW/8-1:0]  sram_be_n,
    output [SRAM_AW-1:0]    sram_addr,
    output [SRAM_DW-1:0]    sram_dq_write,
    output                  sram_dq_en,
    input  [SRAM_DW-1:0]    sram_dq_read
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    /*AUTOWIRE*/

    /*AUTOREG*/

    // internal counter for sram access
    reg [`H_SIZE-1:0]   h_counter;
    reg [`V_SIZE-1:0]   v_counter;

    logic               h_counter_fire;
    logic               v_counter_fire;

    logic [SRAM_DW-1:0] async_fifo_dout;
    logic [SRAM_DW-1:0] async_fifo_din;
    logic               async_fifo_empty;
    logic               async_fifo_afull;
    logic               async_fifo_full;
    logic               async_fifo_read;
    logic               async_fifo_write;

    reg                 vga_sram_read_s1;
    logic               vga_sram_read;
    logic [SRAM_AW-1:0] vga_sram_address;

    logic [SRAM_AW-1:0] src_sram_address;

    reg                 sram_read_s0;
    reg                 sram_write_s0;
    reg [SRAM_AW-1:0]   sram_address_s0;
    reg [SRAM_DW-1:0]   sram_writedata_s0;

    // ------------------------------
    // Main logic
    // ------------------------------

    // internal h_counter and v_counter for the vga side sram address

    assign h_counter_fire = (h_counter == `H_DISPLAY-1);
    assign v_counter_fire = (v_counter == `V_DISPLAY-1);

    // address = h_counter + v_counter * 640
    // 640 = 512 + 128 so we use shift and add instead of multiplication
    /* verilator lint_off WIDTH */
    assign vga_sram_address = h_counter + (v_counter << 9) + (v_counter << 7);
    /* verilator lint_on WIDTH */
    assign vga_sram_read = ~async_fifo_afull;

    assign async_fifo_write = vga_sram_read_s1;
    assign async_fifo_din = sram_dq_read;

    assign async_fifo_read = vga_read;
    assign vga_rgb = async_fifo_dout[RGB_SIZE-1:0];

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            h_counter <= '0;
            v_counter <= '0;
            vga_sram_read_s1 <= 'b0;
        end
        else begin
            vga_sram_read_s1 <= vga_sram_read;
            if (vga_sram_read) begin
                if (h_counter_fire) h_counter <= 'b0;
                else h_counter <= h_counter + 1'b1;
                if (h_counter_fire) begin
                    if (v_counter_fire) v_counter <= 'b0;
                    else v_counter <= v_counter + 1'b1;
                end
            end
        end
    end

    // arbitration between the sram access
    // the vga logic has higher priority than the pixel generation logic

    assign src_rdy = ~vga_sram_read;
    /* verilator lint_off WIDTH */
    assign src_sram_address = src_x + (src_y << 9) + (src_y << 7);
    /* verilator lint_on WIDTH */
    assign src_readdata = sram_dq_read;

    // register the input request for sram
    always @(posedge sys_clk) begin
        if (sys_rst) begin
            sram_read_s0 <= 0;
            sram_write_s0 <= 0;
        end
        else begin
            sram_read_s0 <= src_rdy ? src_read : 1'b1;
            sram_write_s0 <= src_rdy ? src_write : 1'b0;
        end
    end

    always @(posedge sys_clk) begin
        sram_address_s0 <= src_rdy ? src_sram_address : vga_sram_address;
        sram_writedata_s0 <= src_writedata;
    end

    // drive the sram interface
    assign sram_addr = sram_address_s0;
    assign sram_ce_n = ~(sram_read_s0 | sram_write_s0);
    assign sram_oe_n = ~sram_read_s0;
    assign sram_we_n = ~sram_write_s0;
    assign sram_be_n = 0;
    assign sram_dq_write = sram_writedata_s0;
    assign sram_dq_en = sram_write_s0;


    // for better synchronization, we should fill up the fifo before vga start.
    // ideally we should have a cdc logic here for async_fifo_full but since
    // vga_start is quasi static so we should be good.
    always @(posedge pixel_clk) begin
        if (pixel_rst)                          vga_start <= 1'b0;
        else if (!vga_start && async_fifo_full) vga_start <= 1'b1;
    end

    // ------------------------------
    // Module initialization
    // ------------------------------

    vga_async_fifo
    #(
      // Parameters
      .WIDTH        (SRAM_DW),
      .DEPTH        (BUFFER_SIZE),
      .AFULL_THRES  (1))
    u_vga_async_fifo
    (
     // Outputs
     .dout                              (async_fifo_dout),
     .empty                             (async_fifo_empty),
     .full                              (async_fifo_full),
     .afull                             (async_fifo_afull),
     // Inputs
     .rst_rd                            (pixel_rst),
     .clk_rd                            (pixel_clk),
     .read                              (async_fifo_read),
     .rst_wr                            (sys_rst),
     .clk_wr                            (sys_clk),
     .din                               (async_fifo_din),
     .write                             (async_fifo_write));

endmodule