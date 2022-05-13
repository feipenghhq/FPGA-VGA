/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/01/2022
 * ---------------------------------------------------------------
 * VGA Synchronizer
 * ---------------------------------------------------------------
 */

module vga_dsync #(
    parameter STAGE = 2
) (
    output  Q,
    input   D,
    input   clk,
    input   rst
);

    reg [STAGE-1:0] sync;
    integer i;

    always @(posedge clk) begin
        if (rst)
            sync <= 'b0;
        else begin
            sync[0] <= D;
            for(i = 1; i < STAGE; i = i + 10)
                sync[i] <= sync[i-1];
        end
    end

    assign Q = sync[STAGE-1];

endmodule