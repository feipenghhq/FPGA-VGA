/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 04/19/2022
 * ---------------------------------------------------------------
 * General SRAM controller with avalon inteface
 *
 * Note: The address of avalon MM interface is "WORD" address
 *       instead of "BYTE" address
 * ---------------------------------------------------------------
 */

module avalon_sram_controller #(
    parameter SRAM_AW = 18,   // SRAM address width
    parameter SRAM_DW = 16,   // SRAM data width
    parameter AVN_AW = 18,    // Input bus address
    parameter AVN_DW = 16     // Input bus data width
) (
    input                   clk,
    input                   reset,
    // Avalon interface bus
    input                   avn_read,
    input                   avn_write,
    input  [AVN_AW-1:0]     avn_address,    // NOTE: the address is the word address instead of byte address
    input  [AVN_DW-1:0]     avn_writedata,
    input  [AVN_DW/8-1:0]   avn_byteenable,
    output [AVN_DW-1:0]     avn_readdata,
    // sram interface
    output                  sram_ce_n,
    output                  sram_oe_n,
    output                  sram_we_n,
    output [SRAM_DW/8-1:0]  sram_be_n,
    output [SRAM_AW-1:0]    sram_addr,
    inout [SRAM_DW-1:0]     sram_dq
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic [SRAM_DW-1:0]   sram_dq_write;
    logic                 sram_dq_en;

    reg                   avn_read_s0;
    reg                   avn_write_s0;
    reg  [AVN_AW-1:0]     avn_address_s0;
    reg  [AVN_DW-1:0]     avn_writedata_s0;
    reg  [AVN_DW/8-1:0]   avn_byteenable_s0;

    // --------------------------------------------
    //  main logic
    // --------------------------------------------

    assign sram_dq = sram_dq_en ? sram_dq_write : 'z;

    // register the user bus
    always @(posedge clk) begin
        if (reset) begin
            avn_read_s0 <= 0;
            avn_write_s0 <= 0;
        end
        else begin
            avn_read_s0 <= avn_read;
            avn_write_s0 <= avn_write;
        end
    end

    always @(posedge clk) begin
        avn_address_s0 <= avn_address;
        avn_writedata_s0 <= avn_writedata;
        avn_byteenable_s0 <= avn_byteenable;
    end

    // drive the sram interface
    assign sram_addr = avn_address_s0;
    assign sram_ce_n = ~(avn_read_s0 | avn_write_s0);
    assign sram_oe_n = ~avn_read_s0;
    assign sram_we_n = ~avn_write_s0;
    assign sram_be_n = ~avn_byteenable_s0;
    assign sram_dq_write = avn_writedata_s0;
    assign sram_dq_en = avn_write_s0;

    // read data to user bus
    assign avn_readdata = sram_dq;

endmodule


