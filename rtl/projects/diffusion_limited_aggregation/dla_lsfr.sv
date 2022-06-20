/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * LSFR to generate random number
 * https://en.wikipedia.org/wiki/Linear-feedback_shift_register
 * ---------------------------------------------------------------
 */

module dla_lsfr #(
    parameter WIDTH = 16,
    parameter TAP = 'hD008,
    parameter SEED = 'hffff
) (
    input               clk,
    input               rst,
    input               shift,
    output [WIDTH-1:0]  value
);


    reg [WIDTH-1:0]     lsfr;
    logic [WIDTH-1:0]   lsfr_tapped;

    assign value = lsfr;

    always @(posedge clk) begin
        if (rst) begin
            lsfr <= SEED;
        end
        else begin
            if (shift) begin
                lsfr <= lsfr_tapped;
            end
        end
    end

    genvar i;
    generate

        if (TAP[0] == 1) assign lsfr_tapped[0] = lsfr[WIDTH-1] ^ lsfr[WIDTH-1];
        else             assign lsfr_tapped[0] = lsfr[WIDTH-1];

        for (i = 1; i < WIDTH; i++) begin: tap
            if (TAP[i] == 1) assign lsfr_tapped[i] = lsfr[i-1] ^ lsfr[WIDTH-1];
            else             assign lsfr_tapped[i] = lsfr[i-1];
        end
    endgenerate

endmodule