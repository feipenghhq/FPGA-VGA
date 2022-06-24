/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 06/23/2022
 * ---------------------------------------------------------------
 * Calculate a mandbort set calculation cluster
 *
 * Each cluster instantiates a mandbort_cal_core and it will calculate
 * the mandbort set on it's assigned area
 * ---------------------------------------------------------------
 */

module mandbort_cal_cluster #(
    parameter WIDTH     = 16,       // totoal size of the number
    parameter REALW     = 4,        // size of the real part
    parameter MAX_ITER  = 100,
    parameter THRESHOLD = 4 << 12,  // use 4 here bcause we don't do the sqrt
    parameter ITERW     = $clog2(MAX_ITER),
    parameter XCNT_SIZE = 10,
    parameter YCNT_SIZE = 10
) (
    input                       clk,
    input                       rst,

    input [WIDTH-1:0]           delta_x,
    input [WIDTH-1:0]           delta_y,
    input [WIDTH-1:0]           start_x,
    input [WIDTH-1:0]           start_y,
    input [XCNT_SIZE-1:0]       x_count,
    input [YCNT_SIZE-1:0]       y_count,

    input                       start,
    input                       stall,
    output reg [XCNT_SIZE-1:0]  cur_x,
    output reg [YCNT_SIZE-1:0]  cur_y,
    output reg [ITERW-1:0]      iter,
    output reg                  iter_vld,
    output reg                  cal_done
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam IDLE     = 0;
    localparam START    = 1;
    localparam WAIT_CAL = 2;
    localparam FINISH   = 3;
    localparam DONE     = 4;
    localparam WAIT     = 5;

    reg [2:0]           state;
    reg [XCNT_SIZE-1:0] cur_x_cnt;
    reg [YCNT_SIZE-1:0] cur_y_cnt;
    reg                 cal_core_req;
    reg                 complete;

    logic [2:0]         state_next;
    logic               cal_core_vld;
    logic [ITERW-1:0]   cal_core_iter;
    logic               x_fire;
    logic               y_fire;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign x_fire = cur_x_cnt == x_count;
    assign y_fire = cur_y_cnt == y_count;

    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= state_next;
    end

    always @* begin
        state_next = state;
        case(state)
            IDLE: begin
                if (start) state_next = START;
            end
            START: begin
                state_next = WAIT_CAL;
            end
            WAIT_CAL: begin
                if (cal_core_vld) state_next = FINISH;
            end
            FINISH: begin
                if (complete) state_next = DONE;
                else if (!stall) state_next = START;
            end
        endcase
    end

    always @(posedge clk) begin

        iter_vld <= 0;
        cal_done <= 0;
        cal_core_req <= 0;
        complete <= 0;

        case(state)
            IDLE: begin
                if (start) begin
                    cur_x_cnt <= 0;
                    cur_y_cnt <= 0;
                    cur_x <= start_x;
                    cur_y <= start_y;
                    cal_core_req <= 1'b1;
                end
            end
            WAIT_CAL: begin
                if (cal_core_vld) begin
                    iter_vld <= 1;
                    iter <= cal_core_iter;
                    complete <= x_fire & y_fire;
                end
            end
            FINISH: begin
                if (complete) cal_done <= 1'b1;
                if (!stall) begin
                    cal_core_req <= ~complete;
                    if (x_fire) cur_x <= start_x;
                    else cur_x <= cur_x + delta_x;
                    if (x_fire) cur_y <= cur_y + delta_y;
                    cur_x_cnt <= cur_x_cnt + 1'b1;
                    cur_y_cnt <= cur_y_cnt + 1'b1;
                end
            end
        endcase
    end

    // --------------------------------
    // Module initialization
    // --------------------------------

    mandbort_cal_core #(
      .WIDTH        (WIDTH),
      .REALW        (REALW),
      .MAX_ITER     (MAX_ITER),
      .THRESHOLD    (THRESHOLD))
    u_mandbort_cal_core (
      .clk          (clk),
      .rst          (rst),
      .req          (cal_core_req),
      .Rc           (cur_x),
      .Ic           (cur_y),
      .vld          (cal_core_vld),
      .iter         (cal_core_iter)
    );

endmodule