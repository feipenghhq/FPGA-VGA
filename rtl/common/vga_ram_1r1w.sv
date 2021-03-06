/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/05/2022
 * ---------------------------------------------------------------
 * A 1R1W memory
 * ---------------------------------------------------------------
 */

module vga_ram_1r1w #(
    parameter AW = 10,
    parameter DW = 12,
    parameter MEM_FILE = ""
) (
    input               clk,
    input               we,
    input               en,
    input [AW-1:0]      addr_w,
    input [AW-1:0]      addr_r,
    input [DW-1:0]      din,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] ram[0:(1<<AW)-1];

    always @(posedge clk) begin
        if (we && en) ram[addr_w] <= din;
        if (en) dout <= ram[addr_r];
    end

    generate
        /* verilator lint_off WIDTH */
        if (MEM_FILE != "") begin
            initial $readmemh(MEM_FILE, ram);
        end
        /* verilator lint_on WIDTH */
    endgenerate

endmodule
