/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Rgb2gray core
 *
 * Register Spec
 * - 0x0 ctrl
 *  - bit [0:0] bypass = 0
 * ---------------------------------------------------------------
 * Reference: <fpga prototyping by vhdl examples: xilinx microblaze mcs soc>
 * ---------------------------------------------------------------
 */

 module rgb2gray_core #(
    parameter RSIZE     = 4,
    parameter GSIZE     = 4,
    parameter BSIZE     = 4,
    parameter RGB_SIZE  = 12
) (
    input                       clk,
    input                       rst,

    // avalon interface
    input                       avs_write,
    input                       avs_address,
    input [31:0]                avs_writedata,

    // vga interface
    input  [RGB_SIZE-1:0]       src_rgb,
    output logic [RGB_SIZE-1:0] snk_rgb
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    // Register interface
    // 0x0 ctrl
    reg                 ctrl_bypass;
    logic               ctrl_wen;

    /*AUTOREG*/

    /*AUTOWIRE*/

    // --------------------------------
    // Register interface
    // --------------------------------

    assign ctrl_wen = avs_write & (avs_address == 0);

    always @(posedge clk) begin
        if (rst) begin
            ctrl_bypass <= '0;
        end
        else begin
            if (ctrl_wen) begin
                ctrl_bypass <= avs_writedata[0];
            end
        end
    end

    // --------------------------------
    // Main logic
    // --------------------------------


    // --------------------------------
    // Module Declaration
    // --------------------------------

    rgb2gray_gen
    #(/*AUTOINSTPARAM*/
      // Parameters
      .RSIZE                            (RSIZE),
      .GSIZE                            (GSIZE),
      .BSIZE                            (BSIZE),
      .RGB_SIZE                         (RGB_SIZE))
    u_rgb2gray_gen
    (/*AUTOINST*/
     // Outputs
     .snk_rgb                           (snk_rgb[RGB_SIZE-1:0]),
     // Inputs
     .clk                         (clk),
     .rst                         (rst),
     .src_rgb                           (src_rgb[RGB_SIZE-1:0]));

endmodule
