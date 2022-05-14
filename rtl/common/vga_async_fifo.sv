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

    // Write side
    reg [AWIDTH:0]      wrptr_bin;
    reg [AWIDTH:0]      wrptr_gry;


    logic               wen;
    logic [AWIDTH:0]    rdptr_gry_clk_wr;
    logic [AWIDTH:0]    rdptr_bin_clk_wr;
    logic [AWIDTH:0]    wrptr_bin_next;
    logic [AWIDTH-1:0]  wr_addr;
    logic [AWIDTH:0]    wrptr_minus_rdptr;

    // -------------------------------
    // Main Logic
    // -------------------------------

    // FIFO control logic - Read side

    // CDC logic
    genvar i;
    generate
        for (i = 0; i <= AWIDTH; i = i + 1) begin: cdc_rd
            vga_dsync wrptr_gry_dsync(.D(wrptr_gry[i]), .Q(wrptr_gry_clk_rd[i]), .rst(rst_rd), .clk(clk_rd));
        end
    endgenerate

    // control
    assign ren = !empty & read;
    assign empty = (wrptr_bin_clk_rd - rdptr_bin) == 0;
    /* verilator lint_off WIDTH */
    assign rdptr_bin_next = rdptr_bin + ren;
    /* verilator lint_on WIDTH */
    assign wrptr_bin_clk_rd = grey2bin(wrptr_gry_clk_rd);

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

    // CDC logic
    genvar j;
    generate
        for (j = 0; j <= AWIDTH; j = j + 1) begin: cdc_wr
            vga_dsync wrptr_gry_dsync(.D(rdptr_gry[j]), .Q(rdptr_gry_clk_wr[j]), .rst(rst_wr), .clk(clk_wr));
        end
    endgenerate



    assign wrptr_minus_rdptr = wrptr_bin - rdptr_bin_clk_wr;
    assign full  = wrptr_minus_rdptr == DEPTH[AWIDTH:0];
    assign afull = wrptr_minus_rdptr >= (DEPTH - AFULL_THRES);
    assign wen = !full & write;
    /* verilator lint_off WIDTH */
    assign wrptr_bin_next = wrptr_bin + wen;
    /* verilator lint_on WIDTH */
    assign rdptr_bin_clk_wr = grey2bin(rdptr_gry_clk_wr);

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
        if (ren) begin
            data_out <= mem[rd_addr];
        end
    end

    assign wr_addr = wrptr_bin[AWIDTH-1:0];

    always @(posedge clk_wr) begin
        if (wen) begin
            mem[wr_addr] <= din;
        end
    end

    assign dout = data_out;


    // -----------------------------
    // Functions
    // -----------------------------

    // Grey2Bin
    function [AWIDTH:0] grey2bin;
        input [AWIDTH:0] grey;
        integer b;
        grey2bin[AWIDTH] = grey[AWIDTH];
        for (b = AWIDTH - 1; b >= 0 ; b = b - 1)
            grey2bin[b] = grey[b] ^ grey2bin[b+1];
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