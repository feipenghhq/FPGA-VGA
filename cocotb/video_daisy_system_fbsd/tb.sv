
module video_daisy_system_fbsd_tb #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
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

    // Avalon Bus Parameter
    parameter AVS_DW        = 16;     // Avalon data width
    parameter AVS_AW        = 25;     // Avalon address width
    // SDRAM Architecture
    parameter SDRAM_DATA    = 16;      // SDRAM data width
    parameter SDRAM_BANK    = 4;       // SDRAM bank number
    parameter SDRAM_ROW     = 13;      // SDRAM row number
    parameter SDRAM_COL     = 9;       // SDRAM column number
    parameter SDRAM_BA      = 2;       // SDRAM BA width
    parameter SDRAM_BL      = 1;       // SDRAM burst length
    // SDRAM Timing
    parameter CLK_PERIOD    = 10;       // Clock period in ns
    parameter INIT_REF_CNT  = 2;       // Refresh count in initialization process
    parameter CL            = 2;       // CAS latency (cycle)
    parameter tINIT         = 100;      // Initialization time (us)
    parameter tRAS          = 42;       // ACTIVE-to-PRECHARGE command (ns)
    parameter tRC           = 60;       // ACTIVE-to-ACTIVE command period (ns)
    parameter tRCD          = 18;       // ACTIVE-to-READ or WRITE delay (ns)
    parameter tRFC          = 60;       // AUTO REFRESH period (ns)
    parameter tRP           = 18;       // PRECHARGE command period (ns)
    parameter tRRD          = 12;       // ACTIVE bank a to ACTIVE bank b command (ns)
    parameter tREF          = 64;        // Refresh period (ms)

  wire [0:0]                sdram_cs_n;
  wire                      sdram_ras_n;
  wire                      sdram_cas_n;
  wire                      sdram_we_n;
  wire [12:0]               sdram_addr;
  wire [1:0]                sdram_ba;
  wire [15:0]               sdram_dq;
  wire [1:0]                sdram_dqm;
  wire                      sdram_cke;

  wire                      Clk;
  wire                      Cke;
  wire                      Cs_n;
  wire                      Ras_n;
  wire                      Cas_n;
  wire                      We_n;
  wire  [ADDR_BITS - 1 : 0] Addr;
  wire    [BA_BITS - 1 : 0] Ba;
  wire    [DM_BITS - 1 : 0] Dqm;

  assign Addr    = sdram_addr;
  assign Ba      = sdram_ba;
  assign Cas_n   = sdram_cas_n;
  assign Cke     = sdram_cke;
  assign Cs_n    = sdram_cs_n;
  assign Dqm     = sdram_dqm;
  assign Ras_n   = sdram_ras_n;
  assign We_n    = sdram_we_n;
  assign Clk     = sys_clk;

  video_daisy_system_fbsd #(
    .AVS_DW         (AVS_DW),
    .AVS_AW         (AVS_AW),
    .SDRAM_DATA     (SDRAM_DATA),
    .SDRAM_BANK     (SDRAM_BANK),
    .SDRAM_ROW      (SDRAM_ROW),
    .SDRAM_COL      (SDRAM_COL),
    .SDRAM_BA       (SDRAM_BA),
    .SDRAM_BL       (SDRAM_BL),
    .CLK_PERIOD     (CLK_PERIOD),
    .INIT_REF_CNT   (INIT_REF_CNT),
    .CL             (CL),
    .tINIT          (tINIT),
    .tRAS           (tRAS),
    .tRC            (tRC),
    .tRCD           (tRCD),
    .tRFC           (tRFC),
    .tRP            (tRP),
    .tRRD           (tRRD),
    .tREF           (tREF)
  ) u_video_daisy_system_fbsd(.*);

  sdr sdr(.Dq(sdram_dq), .*);

  `ifdef DUMP
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, u_video_daisy_system_fbsd);
  end
  `endif


endmodule
