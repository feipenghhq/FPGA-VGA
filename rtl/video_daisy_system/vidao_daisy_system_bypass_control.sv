/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/02/2022
 * ---------------------------------------------------------------
 * VGA daisy system avalon control module
 * This is a simple avalon control module that write to the bypass
 * register of each core.
 * Assumes the bypass register is in address 0 of each core memory space
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module vidao_daisy_system_bypass_control #(
  parameter NUM = 4
) (
    input                   sys_clk,
    input                   sys_rst,
    input                   bypass_write,
    output                  avs_write
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    /*AUTOREG*/

    /*AUTOREGINPUT*/

    /*AUTOWIRE*/

    reg [1:0] bypass_write_stage;
    logic     bypass_write_trigger;

    // --------------------------------
    // Main logic
    // --------------------------------

    always @(posedge sys_clk) begin
      if (sys_rst) begin
        bypass_write_stage <= 0;
      end
      else begin
        bypass_write_stage <= {bypass_write_stage[0], bypass_write};
      end
    end

    assign bypass_write_trigger = bypass_write_stage[0] & ~bypass_write_stage[1];

    assign avs_write = bypass_write_trigger;

endmodule
