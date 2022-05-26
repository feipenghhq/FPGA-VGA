/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * This module simulate the dla
 * ---------------------------------------------------------------
 */

module dla_simulate #(
    parameter N         = 2000,
    parameter AVN_AW    = 18,
    parameter AVN_DW    = 16,
    parameter HSIZE     = 640,
    parameter VSIZE     = 480
) (
    input                       clk,
    input                       rst,

    output [AVN_AW-1:0]         vram_avn_address,
    output                      vram_avn_write,
    output                      vram_avn_read,
    output [AVN_DW-1:0]         vram_avn_writedata,
    input                       vram_avn_waitrequest,
    input [AVN_DW-1:0]          vram_avn_readdata,
    input                       vram_avn_readdatavalid
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam LSFR_WIDTH = 16;

    /*AUTOWIRE*/

    /*AUTOREG*/

    /*AUTOREGINPUT*/


    localparam S_IDLE   = 0,    // IDLE state
               S_INIT   = 1,    // Initialize the vram
               S_NEW    = 2,    // Create a new particle
               S_WALK   = 3,    // Walk the particle
               S_WRITE  = 4,    // Write the particle to the vram
               S_DONE   = 5;    // Done dla simulate
    reg [5:0]   state;
    logic [5:0] state_next;

    reg [$clog2(N)-1:0]         par_count;

    logic                       init_start;
    logic                       init_done;
    logic                       init_vram_avn_waitrequest;
    logic [AVN_AW-1:0]          init_vram_avn_address;
    logic                       init_vram_avn_write;
    logic [AVN_DW-1:0]          init_vram_avn_writedata;

    logic                       check_done;
    logic                       check_start;
    logic [AVN_DW-1:0]          check_vram_avn_readdata;
    logic                       check_vram_avn_readdatavalid;
    logic                       check_vram_avn_waitrequest;
    logic [AVN_AW-1:0]          check_vram_avn_address;
    logic                       check_vram_avn_read;
    logic [$clog2(HSIZE)-1:0]   check_x;
    logic [$clog2(VSIZE)-1:0]   check_y;
    logic                       hit_boundary;
    logic                       hit_neighbor;

    logic                       walk_start;
    logic [$clog2(HSIZE)-1:0]   walk_init_x;
    logic [$clog2(VSIZE)-1:0]   walk_init_y;
    logic                       walk_done;
    logic [$clog2(HSIZE)-1:0]   walk_final_x;
    logic [$clog2(VSIZE)-1:0]   walk_final_y;
    logic                       walk_valid;
    logic [AVN_AW-1:0]          walk_vram_avn_address;
    logic                       walk_vram_avn_write;
    logic [AVN_DW-1:0]          walk_vram_avn_writedata;
    logic                       walk_vram_avn_waitrequest;

    logic [LSFR_WIDTH-1:0]      lsfr_x;
    logic [LSFR_WIDTH-1:0]      lsfr_y;
    logic                       sim_done;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign init_vram_avn_waitrequest = vram_avn_waitrequest;
    assign walk_vram_avn_waitrequest = vram_avn_waitrequest;
    assign check_vram_avn_readdata = vram_avn_readdata;
    assign check_vram_avn_readdatavalid = vram_avn_readdatavalid;
    assign check_vram_avn_waitrequest = vram_avn_waitrequest;

    assign walk_init_x = lsfr_x[$clog2(HSIZE)-1:0];
    assign walk_init_y = lsfr_y[$clog2(VSIZE)-1:0];

    assign sim_done = par_count == 0;

    assign vram_avn_write       = init_vram_avn_write | walk_vram_avn_write;
    assign vram_avn_read        = check_vram_avn_read;
    assign vram_avn_address     = init_vram_avn_write ? init_vram_avn_address :
                                  walk_vram_avn_write ? walk_vram_avn_address : check_vram_avn_address;
    assign vram_avn_writedata   = init_vram_avn_write ? init_vram_avn_writedata : walk_vram_avn_writedata;

    always @* begin

        init_start = 0;
        walk_start = 0;
        state_next = state;
        case(1)
            state[S_IDLE]: begin
                init_start = 1;
                                state_next[S_INIT] = 1;
            end
            state[S_INIT]: begin
                if (init_done)  state_next[S_NEW] = 1;
                else            state_next[S_INIT] = 1;
            end
            state[S_NEW]: begin
                walk_start = 1;
                                state_next[S_WALK] = 1;
            end
            state[S_WRITE]: begin
                if (walk_done)  state_next[S_WRITE] = 1;
                else            state_next[S_WRITE] = 1;
            end
            state[S_WRITE]: begin
                if (sim_done)   state_next[S_DONE] = 1;
                else            state_next[S_NEW] = 1;
            end
            state[S_DONE]: begin
                                state_next[S_DONE] = 1;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            par_count <= N;
        end
        else begin
            state <= state_next;
            if (walk_start) par_count <= par_count - 1;
        end
    end


    // --------------------------------
    // Module initialization
    // --------------------------------

    /* dla_vram_init AUTO_TEMPLATE (
        .vram_\(.*\)     (init_vram_\1[]),
    )
    */
    dla_vram_init
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .HSIZE                            (HSIZE),
      .VSIZE                            (VSIZE))
    u_dla_vram_init
    (/*AUTOINST*/
     // Outputs
     .init_done                         (init_done),
     .vram_avn_address                  (init_vram_avn_address[AVN_AW-1:0]), // Templated
     .vram_avn_write                    (init_vram_avn_write),   // Templated
     .vram_avn_writedata                (init_vram_avn_writedata[AVN_DW-1:0]), // Templated
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .init_start                        (init_start),
     .vram_avn_waitrequest              (init_vram_avn_waitrequest)); // Templated


    /* dla_particle_check AUTO_TEMPLATE (
        .vram_\(.*\)     (check_vram_\1[]),
    )
    */
    dla_particle_check
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .HSIZE                            (HSIZE),
      .VSIZE                            (VSIZE))
    u_dla_particle_check
    (/*AUTOINST*/
     // Outputs
     .check_done                        (check_done),
     .hit_boundary                      (hit_boundary),
     .hit_neighbor                      (hit_neighbor),
     .vram_avn_address                  (check_vram_avn_address[AVN_AW-1:0]), // Templated
     .vram_avn_read                     (check_vram_avn_read),   // Templated
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .check_x                           (check_x[$clog2(HSIZE)-1:0]),
     .check_y                           (check_y[$clog2(VSIZE)-1:0]),
     .check_start                       (check_start),
     .vram_avn_readdata                 (check_vram_avn_readdata[AVN_DW-1:0]), // Templated
     .vram_avn_waitrequest              (check_vram_avn_waitrequest), // Templated
     .vram_avn_readdatavalid            (check_vram_avn_readdatavalid)); // Templated


    /* dla_particle_walk AUTO_TEMPLATE (
        .vram_\(.*\)     (walk_vram_\1[]),
    )
    */
    dla_particle_walk
    #(/*AUTOINSTPARAM*/
      // Parameters
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (AVN_DW),
      .HSIZE                            (HSIZE),
      .VSIZE                            (VSIZE))
    u_dla_particle_walk
    (/*AUTOINST*/
     // Outputs
     .walk_done                         (walk_done),
     .vram_avn_address                  (walk_vram_avn_address[AVN_AW-1:0]), // Templated
     .vram_avn_write                    (walk_vram_avn_write),   // Templated
     .vram_avn_writedata                (walk_vram_avn_writedata[AVN_DW-1:0]), // Templated
     .check_x                           (check_x[$clog2(HSIZE)-1:0]),
     .check_y                           (check_y[$clog2(VSIZE)-1:0]),
     .check_start                       (check_start),
     // Inputs
     .clk                               (clk),
     .rst                               (rst),
     .walk_init_x                       (walk_init_x[$clog2(HSIZE)-1:0]),
     .walk_init_y                       (walk_init_y[$clog2(VSIZE)-1:0]),
     .walk_start                        (walk_start),
     .vram_avn_waitrequest              (walk_vram_avn_waitrequest), // Templated
     .check_done                        (check_done),
     .hit_boundary                      (hit_boundary),
     .hit_neighbor                      (hit_neighbor));


    dla_lsfr
    #(
     .WIDTH     (LSFR_WIDTH),
     .TAP       (16),
     .SEED      (16))
    u_dla_lsfr_x
    (.clk       (clk),
     .rst       (rst),
     .shift     (walk_start),
     .value     (lsfr_x));

    dla_lsfr
    #(
      .WIDTH    (LSFR_WIDTH),
      .TAP      (16),
      .SEED     (32))
    u_dla_lsfr_y
    (.clk       (clk),
     .rst       (rst),
     .shift     (walk_start),
     .value     (lsfr_y));

endmodule
