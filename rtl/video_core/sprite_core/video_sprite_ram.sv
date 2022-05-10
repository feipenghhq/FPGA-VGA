/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/05/2022
 * ---------------------------------------------------------------
 * Sprite ram
 *
 * A 1R1W memory
 * ---------------------------------------------------------------
 */

module video_sprite_ram #(
    parameter AW = 10,
    parameter DW = 12,
    parameter MEM_FILE = ""
) (
    input               clk,
    input               we,
    input [AW-1:0]      addr_w,
    input [AW-1:0]      addr_r,
    input [DW-1:0]      din,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] ram[0:(1<<AW)-1];

    always @(posedge clk) begin
        if (we) ram[addr_w] <= din;
        dout <= ram[addr_r];
    end

    generate
        /* verilator lint_off WIDTH */
        if (MEM_FILE != "") begin
            initial $readmemh(MEM_FILE, ram);
        end
        /* verilator lint_on WIDTH */
    endgenerate

endmodule
