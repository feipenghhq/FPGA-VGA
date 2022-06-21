/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/20/2022
 * ---------------------------------------------------------------
 * A 1RW memory
 * ---------------------------------------------------------------
 */

module vga_ram_1rw #(
    parameter AW = 10,
    parameter DW = 12,
    parameter MEM_FILE = ""
) (
    input               clk,
    input               we,
    input [AW-1:0]      addr,
    input [DW-1:0]      din,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] ram[0:(1<<AW)-1];

    always @(posedge clk) begin
        if (we) ram[addr] <= din;
        dout <= ram[addr];
    end

    generate
        /* verilator lint_off WIDTH */
        if (MEM_FILE != "") begin
            initial $readmemh(MEM_FILE, ram);
        end
        /* verilator lint_on WIDTH */
    endgenerate

endmodule
