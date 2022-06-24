/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/22/2022
 * ---------------------------------------------------------------
 * calculate the mandbort iteration
 * ---------------------------------------------------------------
 *
 * General Mandbort iteration Zn+1 = (Zn)^2 + C
 * Where: Zn = Rn + In * i, C = Rc + Ic * i
 *
 *  (Zn)^2 = (Rn + In * i) * (Rn + In * i)
 *         = (Rn)^2 - (In)^2 + (2 * Rn * In) * i
 *  Zn+1   = (Zn)^2 + C
 *         = (Rn)^2 - (In)^2 + (2 * Rn * In) * i + Rc + Ic * i
 *         = ((Rn)^2 - (In)^2 + Rc) + (2 * Rn * In + Ic) * i
 *
 * So we need to calculate the following for 1 iteration
 *    Rn+1 = (Rn)^2 - (In)^2 + Rc   (1)
 *    In+1 = 2 * Rn * In + Ic       (2)
 * We also need to calculate the abs value of Zn which is
 *    abs(Zn) = sqrt(Rn*Rn + In*In) (3)
 * ---------------------------------------------------------------
 *
 * We use fixed point to represent decimals
 * The width is 16 bits, 4 bit used for integer and 12 bits used for decimals
 *
 * Fixed point multiplcation:
 *      XXXX YYYYYYYYYYYY * XXXX YYYYYYYYYYYY (16 bits * 16 bits)
 * we will get 32 bits:
 *      XXXX AAAA BBBBBBBBBBBB YYYYYYYYYYYY (4 + 4 + 12 + 12) bits
 * Now we need to convert the 32 bits back to 16 bits.
 * In order to do so, we discard the upper 4 bits and the lower 12 bits
 * so we get AAAA BBBBBBBBBBBB
 *
 * Check the following webpage for more information regarding fixed point
 * https://www.allaboutcircuits.com/technical-articles/fixed-point-representation-the-q-format-and-addition-examples/
 * https://www.allaboutcircuits.com/technical-articles/multiplication-examples-using-the-fixed-point-representation/
 *
 * ---------------------------------------------------------------
 *
 *  For timing purpose, we divide the calculation of (1), (2) and (3)
 *  into different stages:
 *
 *  Stage 0: Calculate the multiplcation using fixed point
 *      - This include Rn * Rn, In * In and Rn * In
 *  Stage 1: Calculate the addition and subtraction part
 *
 * ---------------------------------------------------------------
 */

module mandbort_cal_core #(
    parameter WIDTH     = 16,       // totoal size of the number
    parameter REALW     = 4,        // size of the real part
    parameter MAX_ITER  = 100,
    parameter THRESHOLD = 4 << 12,  // use 4 here bcause we don't do the sqrt
    parameter ITERW     = $clog2(MAX_ITER)
) (
    input               clk,
    input               rst,

    input               req,        // this should be a 1 clock cycle pulse
    input  signed [WIDTH-1:0] Rc,
    input  signed [WIDTH-1:0] Ic,

    output              vld,
    output [ITERW-1:0]  iter
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam IMGW = WIDTH - REALW;

    reg [ITERW-1:0]             count;
    reg                         exceed;
    reg                         count_done;

    // stage 0
    reg                         vld_s0;
    reg signed [WIDTH-1:0]      real_s0;
    reg signed [WIDTH-1:0]      img_s0;
    reg signed [WIDTH-1:0]      real_img_s0;

    // stage 1
    logic signed [WIDTH-1:0]    real_real_resize_s1;
    logic signed [WIDTH-1:0]    img_img_resize_s1;
    logic signed [WIDTH-1:0]    real_img_resize_s1;

    logic signed [WIDTH-1:0]    nxt_real_s1;
    logic signed [WIDTH-1:0]    nxt_img_s1;

    reg                         vld_s1;
    reg signed [2*WIDTH-1:0]    real_real_s1;   // R x R
    reg signed [2*WIDTH-1:0]    img_img_s1;     // I x I
    reg signed [2*WIDTH-1:0]    real_img_s1;    // R x I


    // --------------------------------
    // Main logic
    // --------------------------------

    // -- stage 0 -- //

    // control signals
    always @(posedge clk) begin
        if (rst) vld_s1 <= 0;
        else vld_s1 <= vld_s0 & ~vld;
    end

    // perform the multiplication
    always @(posedge clk) begin
        real_real_s1 <= real_s0 * real_s0;
        img_img_s1 <= img_s0 * img_s0;
        real_img_s1 <= real_s0 * img_s0;
    end

    // -- stage 1 -- //

    // FIXME: Here we are doing truncatation.
    // It's better to do saturation overflow
    `define RESIZE(x)           (x[IMGW+WIDTH-1:IMGW])

    assign real_real_resize_s1  = `RESIZE(real_real_s1);
    assign img_img_resize_s1    = `RESIZE(img_img_s1);
    assign real_img_resize_s1   = `RESIZE(real_img_s1);

    assign nxt_real_s1 = real_real_resize_s1 - img_img_resize_s1 + Rc;
    assign nxt_img_s1 = (real_img_resize_s1 << 1) + Ic;

    // this actaully go back to stage 0
    always @(posedge clk) begin
        if (rst) vld_s0 <= 0;
        else vld_s0 <= vld_s1 & ~vld | req;
    end
    always @(posedge clk) begin
        real_s0 <= req ? 0 : nxt_real_s1;
        img_s0 <= req ? 0 : nxt_img_s1;
        real_img_s0 <= real_img_resize_s1;
    end

    // -- other -- //

    assign vld = exceed | count_done;
    assign iter = count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            exceed <= 0;
            count_done <= 0;
        end
        else begin
            if (req) count <= 0;
            else if (vld_s0) count <= count + 1'b1;

            exceed <= real_img_s0 >= THRESHOLD;
            count_done <= (count == MAX_ITER);
        end
    end

endmodule