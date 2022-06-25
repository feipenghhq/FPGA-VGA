/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/22/2022
 * ---------------------------------------------------------------
 * mandelbrot solver
 *
 * Calculate the mandelbrot iteration: Zn+1 = (Zn)^2 + C
 *
 * Where: Zn = Rn + In * i, C = Rc + Ic * i
 *
 *  (Zn)^2 = (Rn + In * i) * (Rn + In * i)
 *         = (Rn)^2 - (In)^2 + (2 * Rn * In) * i
 *  Zn+1   = (Zn)^2 + C
 *         = (Rn)^2 - (In)^2 + (2 * Rn * In) * i + (Rc + Ic * i)
 *         = ((Rn)^2 - (In)^2 + Rc) + (2 * Rn * In + Ic) * i
 *
 *  Rn+1   = (Rn)^2 - (In)^2 + Rc   (1)
 *  In+1   = 2 * Rn * In + Ic       (2)

 * We also need to calculate the (Rn)^2 + (In)^2 to check if it isdiverged
 *
 * ---------------------------------------------------------------
 *
 * The calculation is divided into 2 stages
 *
 *  Stage 0: Calculate the multiplcation:
 *      - (Rn)^2, (In)^2, Rn * In
 *  Stage 1: Calculate the addition/subtraction:
 *      - (Rn)^2 - (In)^2 + Rc
 *      - 2 * Rn * In + Ic
 *      - (Rn)^2 + (In)^2
 *
 * ---------------------------------------------------------------
 */

module mandelbrot_solver #(
    parameter ITERW     = 16,   // Iteration width
    parameter DATAW     = 32,   // data width
    parameter IMAGW     = 28    // imag width
) (
    input                 clk,
    input                 rst,

    input [ITERW-1:0]     max_iteration,

    input                 request,    // this should be a 1 clock cycle pulse
    input  [DATAW-1:0]    realc,
    input  [DATAW-1:0]    imagc,

    output reg             valid,
    output reg [ITERW-1:0] iteration,
    output reg             diverged
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam REALW = DATAW - IMAGW;
    localparam THRESHOLD = 4 << IMAGW;

    // stage 0
    reg                 vld_s0;
    reg  [DATAW-1:0]    real_s0;
    reg  [DATAW-1:0]    imag_s0;
    reg  [DATAW-1:0]    z_modulus_squre_s0;

    // stage 1
    reg                 vld_s1;
    logic  [DATAW-1:0]  real_square_s1;
    logic  [DATAW-1:0]  imag_square_s1;
    logic  [DATAW-1:0]  real_imag_s1;

    logic               iteration_completed;
    logic               threshold_exceeded;

    // --------------------------------
    // Main logic
    // --------------------------------

    // -- stage 0 -- //

    always @(posedge clk) begin
        if (rst) vld_s1 <= 0;
        else vld_s1 <= vld_s0 & ~valid;
    end

    // perform the multiplication
    mandelbrot_multiplier #(.RW(REALW), .IW(IMAGW)) real_square_multiplier(.clk, .rst, .a(real_s0), .b(real_s0), .o(real_square_s1));
    mandelbrot_multiplier #(.RW(REALW), .IW(IMAGW)) imag_square_multiplier(.clk, .rst, .a(imag_s0), .b(imag_s0), .o(imag_square_s1));
    mandelbrot_multiplier #(.RW(REALW), .IW(IMAGW)) real_imag_multiplier(.clk, .rst, .a(real_s0), .b(imag_s0), .o(real_imag_s1));

    // -- stage 1 -- //

    always @(posedge clk) begin
        if (rst) vld_s0 <= 0;
        else vld_s0 <= (vld_s1 & ~valid) | request;
    end

    always @(posedge clk) begin
        if (request) begin
            real_s0 <= 0;
            imag_s0 <= 0;
            z_modulus_squre_s0 <= 0;
        end
        else if (vld_s1) begin
            real_s0 <= real_square_s1 - imag_square_s1 + realc;
            imag_s0 <= (real_imag_s1 << 1) + imagc;   // use left shift for x2
            z_modulus_squre_s0 <= real_square_s1 + imag_square_s1;
        end
    end

    assign threshold_exceeded = (z_modulus_squre_s0 >= THRESHOLD);
    assign iteration_completed = (iteration == max_iteration);

    always @(posedge clk) begin
        if (request || rst) begin
            iteration <= 0;
            valid <= 0;
            diverged <= 0;
        end
        else begin
            valid <= 0;
            diverged <= 0;

            if (vld_s1) iteration <= iteration + 1'b1;

            if (vld_s0) begin
                diverged <= threshold_exceeded;
                valid <= threshold_exceeded | iteration_completed;
            end
        end
    end

endmodule
