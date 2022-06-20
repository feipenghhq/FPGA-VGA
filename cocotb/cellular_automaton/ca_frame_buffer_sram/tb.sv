
`include "vga.svh"

module tb #(
    parameter SRAM_AW   = 18,   // SRAM address width
    parameter SRAM_DW   = 16    // SRAM data width
) (
    // clock
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    // vga interface
    output  [`R_SIZE-1:0]   vga_r,
    output  [`G_SIZE-1:0]   vga_g,
    output  [`B_SIZE-1:0]   vga_b,

    output                  vga_hsync,
    output                  vga_vsync
);


    // the sram interface
    logic                   sram_ce_n;
    logic                   sram_oe_n;
    logic                   sram_we_n;
    logic [SRAM_DW/8-1:0]   sram_be_n;
    logic [SRAM_AW-1:0]     sram_addr;
    logic [SRAM_DW-1:0]     sram_dq_read;
    wire  [SRAM_DW-1:0]     sram_dq;

    logic [7:0]             ca_rule;
    logic                   ca_start;

    ca_frame_buffer_sram u_video_system_frame_buffer_sram(.*);
    sdram_model u_sdram_model(.*);


endmodule

module sdram_model #(
    parameter SRAM_AW   = 18,   // SRAM address width
    parameter SRAM_DW   = 16    // SRAM data width
) (
    // the sram interface
    input                   sram_ce_n,
    input                   sram_oe_n,
    input                   sram_we_n,
    input [SRAM_DW/8-1:0]   sram_be_n,
    input [SRAM_AW-1:0]     sram_addr,
    inout [SRAM_DW-1:0]     sram_dq
);

    /* verilator lint_off UNOPT */
    logic [SRAM_DW-1:0]     sram_dq_write;
    logic                   sram_dq_en;
    reg [SRAM_DW-1:0]       sram_mem[(1<<SRAM_AW)-1:0];
    /* verilator lint_on UNOPT */

    assign sram_dq_en = ~sram_ce_n & sram_we_n;
    assign sram_dq = sram_dq_en ? sram_dq_write : 'z;

    always @* begin
        if (!sram_ce_n && !sram_we_n) begin
            sram_mem[sram_addr] = sram_dq;
        end
    end

    always @* begin
        sram_dq_write = 0;
        if (!sram_ce_n && sram_we_n) begin
            sram_dq_write = sram_mem[sram_addr];
        end
    end

endmodule
