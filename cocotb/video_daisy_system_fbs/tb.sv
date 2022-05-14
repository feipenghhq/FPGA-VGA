


module video_daisy_system_fbs_tb #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12,
    parameter SRAM_AW   = 18,   // SRAM address width
    parameter SRAM_DW   = 16    // SRAM data width
) (
    // clock
    input                   pixel_clk,
    input                   pixel_rst,

    input                   sys_clk,
    input                   sys_rst,

    // vga interface
    output  [RSIZE-1:0]     vga_r,
    output  [GSIZE-1:0]     vga_g,
    output  [BSIZE-1:0]     vga_b,

    output                  vga_hsync,
    output                  vga_vsync,

    // video bar core avalon insterface
    input                   avs_video_bar_core_address,
    input                   avs_video_bar_core_write,
    input [31:0]            avs_video_bar_core_writedata,

    input [10:0]            avs_video_sprite_core_address,
    input                   avs_video_sprite_core_write,
    input [31:0]            avs_video_sprite_core_writedata,

    input [12:0]            avs_pacman_core_address,
    input                   avs_pacman_core_write,
    input [31:0]            avs_pacman_core_writedata,

    input                   avs_video_rgb2gray_core_address,
    input                   avs_video_rgb2gray_core_write,
    input [31:0]            avs_video_rgb2gray_core_writedata
);


    // the sram interface
    logic                   sram_ce_n;
    logic                   sram_oe_n;
    logic                   sram_we_n;
    logic [SRAM_DW/8-1:0]   sram_be_n;
    logic [SRAM_AW-1:0]     sram_addr;
    logic [SRAM_DW-1:0]     sram_dq_write;
    logic                   sram_dq_en;
    logic  [SRAM_DW-1:0]    sram_dq_read;

    video_daisy_system_fbs u_video_daisy_system_fbs(.*);

    // sram model
    reg [SRAM_DW-1:0] sram_mem[(1<<SRAM_AW)-1:0];

    assign sram_dq_read = sram_mem[sram_addr];

    always @* begin
        if (!sram_ce_n && !sram_we_n) begin
            sram_mem[sram_addr] = sram_dq_write;
        end
    end

endmodule
