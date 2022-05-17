/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * Asynchronous FIFO for VGA
 * ---------------------------------------------------------------
 */


 module vga_async_fifo #(
    parameter WIDTH  = 32,              // Data width
    parameter DEPTH  = 16,              // FIFO depth
    parameter AWIDTH = $clog2(DEPTH),
    parameter AFULL_THRES = 1
) (
    // Read side
    input               rst_rd,
    input               clk_rd,
    input               read,
    output [WIDTH-1:0]  dout,
    output              empty,
    // Write side
    input               rst_wr,
    input               clk_wr,
    input [WIDTH-1:0]   din,
    input               write,
    output              full,
    output              afull
);

    reg [WIDTH-1:0]     mem[2**AWIDTH-1:0];   // Only this style works in vivado.

    // Read side
    reg [WIDTH-1:0]     data_out;
    reg [AWIDTH:0]      rdptr_bin;
    reg [AWIDTH:0]      rdptr_gry;

    logic               ren;
    logic [AWIDTH:0]    wrptr_gry_clk_rd;
    logic [AWIDTH:0]    wrptr_bin_clk_rd;
    logic [AWIDTH:0]    rdptr_bin_next;
    logic [AWIDTH-1:0]  rd_addr;
    logic [AWIDTH:0]    wrptr_minus_rdptr_clk_rd;

    // Write side
    reg [AWIDTH:0]      wrptr_bin;
    reg [AWIDTH:0]      wrptr_gry;


    logic               wen;
    logic [AWIDTH:0]    rdptr_gry_clk_wr;
    logic [AWIDTH:0]    rdptr_bin_clk_wr;
    logic [AWIDTH:0]    wrptr_bin_next;
    logic [AWIDTH-1:0]  wr_addr;
    logic [AWIDTH:0]    wrptr_minus_rdptr_clk_wr;

    // -------------------------------
    // Main Logic
    // -------------------------------

    // FIFO control logic - Read side

    vga_dsync wrptr_gry_dsync[AWIDTH:0] (.D(wrptr_gry), .Q(wrptr_gry_clk_rd), .rst(rst_rd), .clk(clk_rd));

    // control
    assign wrptr_bin_clk_rd = grey2bin(wrptr_gry_clk_rd);
    assign wrptr_minus_rdptr_clk_rd = wrptr_bin_clk_rd - rdptr_bin;
    assign empty = wrptr_minus_rdptr_clk_rd == 0;
    assign ren = !empty & read;
    assign rdptr_bin_next = ren ? rdptr_bin + 1'b1 : rdptr_bin;

    // read pointer
    always @(posedge clk_rd) begin
        if (rst_rd) begin
            rdptr_bin <= 'b0;
            rdptr_gry <= 'b0;
        end
        else begin
            rdptr_gry <= bin2grey(rdptr_bin_next);
            rdptr_bin <= rdptr_bin_next;
        end
    end


    // FIFO control logic - Write side

    vga_dsync rdptr_gry_dsync[AWIDTH:0] (.D(rdptr_gry), .Q(rdptr_gry_clk_wr), .rst(rst_wr), .clk(clk_wr));

    assign rdptr_bin_clk_wr = grey2bin(rdptr_gry_clk_wr);
    assign wrptr_minus_rdptr_clk_wr = wrptr_bin - rdptr_bin_clk_wr;
    assign full  = wrptr_minus_rdptr_clk_wr == DEPTH[AWIDTH:0];
    assign afull = wrptr_minus_rdptr_clk_wr >= (DEPTH - AFULL_THRES);
    assign wen = !full & write;
    assign wrptr_bin_next = wen ? wrptr_bin + 1'b1 : wrptr_bin;

    // write pointer
    always @(posedge clk_wr) begin
        if (rst_wr) begin
            wrptr_bin <= 'b0;
            wrptr_gry <= 'b0;
        end
        else begin
            wrptr_gry <= bin2grey(wrptr_bin_next);
            wrptr_bin <= wrptr_bin_next;
        end
    end

    // -----------------------------
    // RAM control logic
    // -----------------------------

    assign rd_addr = rdptr_bin[AWIDTH-1:0];
    always @(posedge clk_rd) begin
        if (ren) data_out <= mem[rd_addr];
    end

    assign wr_addr = wrptr_bin[AWIDTH-1:0];
    always @(posedge clk_wr) begin
        if (wen) mem[wr_addr] <= din;
    end

    assign dout = data_out;

    // -----------------------------
    // Functions
    // -----------------------------

    // Grey2Bin
    function [AWIDTH:0] grey2bin;
        input [AWIDTH:0] grey;
        integer b;
        logic [AWIDTH:0] bin;
        bin[AWIDTH] = grey[AWIDTH];
        for (b = AWIDTH - 1; b >= 0; b = b - 1)
            bin[b] = grey[b] ^ bin[b+1];
        grey2bin = bin;
    endfunction


    // Bin2Grey
    function [AWIDTH:0] bin2grey;
        input [AWIDTH:0] bin;
        integer a;
        for (a = 0; a < AWIDTH; a = a + 1)
            bin2grey[a] = bin[a] ^ bin[a+1];
        bin2grey[AWIDTH] = bin[AWIDTH];
    endfunction

endmodule