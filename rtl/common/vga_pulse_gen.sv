/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/25/2022
 * ---------------------------------------------------------------
 * Generate a single sycle pulse
 * ---------------------------------------------------------------
 */

module vga_pulse_gen (
    input clk,
    input rst,
    input in,
    output pulse
);

    reg in_ff;

    always @(posedge clk) begin
        if (rst) in_ff <= 0;
        else in_ff <= in;
    end

    assign pulse = in & ~in_ff;

endmodule