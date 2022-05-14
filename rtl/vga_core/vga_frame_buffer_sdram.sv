/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/13/2022
 * ---------------------------------------------------------------
 * Frame buffer using SDRAM
 *
 * The frame buffer needs two separate ports for the pixel generation
 * logic and the vga controller. The two ports also run in different
 * clock domains. The pixel clock is generally slow and we want to run
 * the sdram in the system clock so the pixel gneration can generate the
 * pixel as fast as possible.
 *
 * To make the SDRAM having 2 separate port and also cross clock domains
 * for the pixel clock.
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vga_frame_buffer_sdram #(

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
    parameter tRAS          = 42,       // ACTIVE-to-PRECHARGE command (ns)
    parameter tRC           = 55,       // ACTIVE-to-ACTIVE command period (ns)
    parameter tRCD          = 15,       // ACTIVE-to-READ or WRITE delay (ns)
    parameter tRFC          = 55,       // AUTO REFRESH period (ns)
    parameter tRP           = 15,       // PRECHARGE command period (ns)
    parameter tRRD          = 10,       // ACTIVE bank a to ACTIVE bank b command (ns)
    parameter tREF          = 64,       // Refresh period (ms)

    parameter RGB_SIZE      = 12,
    parameter BUFFER_SIZE   = 8
)(
    input                       sys_clk,
    input                       sys_rst,

    input                       pixel_clk,
    input                       pixel_rst,

    // the vga interface is a stream interface
    input                       vga_read,
    output [RGB_SIZE-1:0]       vga_rgb,
    output reg                  vga_start,

    // the source interface is a memory mapped
    input                       src_read,
    input                       src_write,
    input  [`H_SIZE-1:0]        src_x,
    input  [`V_SIZE-1:0]        src_y,
    input  [AVS_DW-1:0]         src_writedata,
    output [AVS_DW-1:0]         src_readdata,
    output                      src_readdatavalid,
    output                      src_rdy,

    output                      sdram_cs_n,
    output                      sdram_ras_n,
    output                      sdram_cas_n,
    output                      sdram_we_n,
    output                      sdram_cke,
    output [SDRAM_ROW-1:0]      sdram_addr,
    output [SDRAM_BA-1:0]       sdram_ba,
    output [SDRAM_DATA/8-1:0]   sdram_dqm,
    inout  [SDRAM_DATA-1:0]     sdram_dq
);

    // ------------------------------
    // Sginal Declaration
    // ------------------------------

    /*AUTOWIRE*/

    /*AUTOREG*/

    // internal counter for sdram access
    reg [`H_SIZE-1:0]       h_counter;
    reg [`V_SIZE-1:0]       v_counter;
    reg                     pending_vga_sdram_read;

    logic                   h_counter_fire;
    logic                   v_counter_fire;

    logic [AVS_DW-1:0]      async_fifo_dout;
    logic [AVS_DW-1:0]      async_fifo_din;
    logic                   async_fifo_empty;
    logic                   async_fifo_afull;
    logic                   async_fifo_full;
    logic                   async_fifo_read;
    logic                   async_fifo_write;

    logic                   vga_sdram_read;
    logic [AVS_AW-1:0]      vga_sdram_address;
    logic [AVS_AW-1:0]      src_sdram_address;
    logic                   vga_sdram_grant;

    logic                   avs_read;
    logic                   avs_write;
    logic [AVS_AW-1:0]      avs_address;
    logic [AVS_DW-1:0]      avs_writedata;
    logic [AVS_DW/8-1:0]    avs_byteenable;

    logic [AVS_DW-1:0]      avs_readdata;
    logic                   avs_waitrequest;
    logic                   avs_readdatavalid;

    // ------------------------------
    // Main logic
    // ------------------------------

    // internal h_counter and v_counter for the vga side sdram address

    assign h_counter_fire = (h_counter == `H_DISPLAY-1);
    assign v_counter_fire = (v_counter == `V_DISPLAY-1);

    // address = h_counter + v_counter * 640
    // 640 = 512 + 128 so we use shift and add instead of multiplication
    /* verilator lint_off WIDTH */
    assign vga_sdram_address = h_counter + (v_counter << 9) + (v_counter << 7);
    assign src_sdram_address = src_x + (src_y << 9) + (src_y << 7);
    /* verilator lint_on WIDTH */
    assign vga_sdram_read = ~async_fifo_afull & ~pending_vga_sdram_read & ~avs_waitrequest;

    assign async_fifo_write = pending_vga_sdram_read & src_readdatavalid;
    assign async_fifo_din = sdram_dq;

    assign async_fifo_read = vga_read;
    assign vga_rgb = async_fifo_dout[RGB_SIZE-1:0];

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            h_counter <= '0;
            v_counter <= '0;
            pending_vga_sdram_read <= 'b0;
        end
        else begin
            // FIXME this can be optimized since the sdram can take few outstanding read
            if (vga_sdram_read) begin
                pending_vga_sdram_read <= 1'b1;
            end
            else if (src_readdatavalid) begin
                pending_vga_sdram_read <= 1'b0;
            end

            if (vga_sdram_read) begin
                if (h_counter_fire) h_counter <= 'b0;
                else h_counter <= h_counter + 1'b1;
                if (h_counter_fire) begin
                    if (v_counter_fire) v_counter <= 'b0;
                    else v_counter <= v_counter + 1'b1;
                end
            end
        end
    end

    // arbitration between the sdram access

    assign vga_sdram_grant = vga_sdram_read;

    assign src_rdy = ~vga_sdram_grant & ~avs_waitrequest;
    assign src_readdata = avs_readdata;
    assign src_readdatavalid = avs_readdatavalid;

    assign avs_read = vga_sdram_read | src_read;
    assign avs_write = ~vga_sdram_grant & src_write & ~avs_waitrequest;

    assign avs_byteenable = (1 << (SDRAM_DATA/8)) - 1;
    assign avs_address = vga_sdram_grant ? vga_sdram_address : src_sdram_address;
    assign avs_writedata = src_writedata;

    // for better synchronization, we should fill up the fifo before vga start.
    // ideally we should have a cdc logic here for async_fifo_full but since
    // vga_start is quasi static so we should be good.
    always @(posedge pixel_clk) begin
        if (pixel_rst) vga_start <= 1'b0;
        else if (!vga_start && async_fifo_afull) vga_start <= 1'b1;
    end

    // ------------------------------
    // Module initialization
    // ------------------------------

    vga_async_fifo
    #(
      // Parameters
      .WIDTH        (SDRAM_DATA),
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

    avalon_sdram_controller
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
      .tREF                             (tREF))
    u_avalon_sdram_controller
    (
     // Outputs
     .sdram_cs_n                        (sdram_cs_n),
     .sdram_ras_n                       (sdram_ras_n),
     .sdram_cas_n                       (sdram_cas_n),
     .sdram_we_n                        (sdram_we_n),
     .sdram_cke                         (sdram_cke),
     .sdram_addr                        (sdram_addr),
     .sdram_ba                          (sdram_ba),
     .sdram_dqm                         (sdram_dqm),
     .avs_readdata                      (avs_readdata),
     .avs_waitrequest                   (avs_waitrequest),
     .avs_readdatavalid                 (avs_readdatavalid),
     // Inouts
     .sdram_dq                          (sdram_dq),
     // Inputs
     .avs_read                          (avs_read),
     .avs_write                         (avs_write),
     .avs_address                       (avs_address),
     .avs_writedata                     (avs_writedata),
     .avs_byteenable                    (avs_byteenable),
     .reset                             (sys_rst),
     .clk                               (sys_clk));

endmodule

// Local Variables:
// verilog-library-flags:("-y ../../ip/sdram/ ")
// End:
