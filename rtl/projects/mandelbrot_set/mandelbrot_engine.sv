/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/23/2022
 * ---------------------------------------------------------------
 * mandelbrot engine
 *
 * Processing a rectangle area of the mandelbrot set
 * Each engine has 1 solver
 * ---------------------------------------------------------------
 */

module mandelbrot_engine #(
    parameter ITERW = 16,   // Iteration width
    parameter DATAW = 32,   // data width
    parameter IMAGW = 28,   // imag width
    parameter RCNTW = 10,   // real counter width
    parameter ICNTW = 10    // imag counter width
) (
    input                       clk,
    input                       rst,

    input [ITERW-1:0]           max_iteration,

    input                       start,
    input                       stall,

    // starting position of the mandelbrot and delta value
    input [DATAW-1:0]           start_real,
    input [DATAW-1:0]           start_imag,

    input [DATAW-1:0]           delta_real,
    input [DATAW-1:0]           delta_imag,

    // number of real and imag to be calculated
    input [RCNTW-1:0]           real_size,
    input [ICNTW-1:0]           imag_size,

    output reg [RCNTW-1:0]      real_cnt,
    output reg [ICNTW-1:0]      imag_cnt,
    output reg [ITERW-1:0]      iteration,
    output reg                  valid,
    output reg                  diverged
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam IDLE     = 0;
    localparam START    = 1;
    localparam CAL      = 2;
    localparam CHECK    = 3;
    localparam WAIT     = 4;

    reg [2:0]           state;

    reg                 solver_request;
    reg                 complete;
    reg [DATAW-1:0]     cur_real;
    reg [DATAW-1:0]     cur_imag;

    logic [2:0]         state_next;
    logic               x_complete;
    logic               y_complete;

    logic               solver_valid;
    logic [ITERW-1:0]   solver_iteration;
    logic               solver_diverged;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign x_complete = real_cnt == real_size;
    assign y_complete = imag_cnt == imag_size;

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= state_next;
    end

    always @* begin
        state_next = state;
        case(state)
            IDLE: begin
                if (start)          state_next = START;
            end
            START: begin
                                    state_next = CAL;
            end
            CAL: begin
                if (solver_valid)   state_next = CHECK;
            end
            CHECK: begin
                if (complete)       state_next = IDLE;
                else if (stall)     state_next = WAIT;
                else                state_next = START;
            end
            WAIT: begin
                if (!stall)         state_next = START;
            end
        endcase
    end

    always @(posedge clk) begin

        valid <= 0;
        solver_request <= 0;
        complete <= 0;

        case(state)
            IDLE: begin
                if (start) begin
                    real_cnt <= 0;
                    imag_cnt <= 0;
                    cur_real <= start_real;
                    cur_imag <= start_imag;
                    solver_request <= 1'b1;
                end
            end
            CAL: begin
                iteration <= solver_iteration;
                diverged <= solver_diverged;
                complete <= x_complete & y_complete;
                valid <= solver_valid;
            end
            CHECK: begin
                solver_request <= ~complete & ~stall;

                if (x_complete) begin
                    cur_imag <= cur_imag + delta_imag;
                    imag_cnt <= imag_cnt + 1'b1;
                end

                if (x_complete) begin
                    cur_real <= start_real;
                    real_cnt <= 0;
                end
                else begin
                    cur_real <= cur_real + delta_real;
                    real_cnt <= real_cnt + 1'b1;
                end
            end
            WAIT: begin
                if (!stall) solver_request <= 1'b1;
            end
        endcase
    end

    // --------------------------------
    // Module initialization
    // --------------------------------

    mandelbrot_solver #(
      .ITERW            (ITERW),
      .DATAW            (DATAW),
      .IMAGW            (IMAGW))
    u_mandelbrot_solver (
      .clk              (clk),
      .rst              (rst),
      .max_iteration    (max_iteration),
      .request          (solver_request),
      .realc            (cur_real),
      .imagc            (cur_imag),
      .valid            (solver_valid),
      .iteration        (solver_iteration),
      .diverged         (solver_diverged)
    );

endmodule