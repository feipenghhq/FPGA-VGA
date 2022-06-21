/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/25/2022
 * ---------------------------------------------------------------
 * This module does the entire simulation of the dla.
 *
 * 1. Initialize the sreen (memory)
 * 2. Randonly generate a particle
 * 3. Walk the particle.
 * 4. Repeat steps 2 & 3 till we have generated N particles.
 * ---------------------------------------------------------------
 * 06/20/2022:
 * Added a bram to store the dla pattern to speed up the process
 * ---------------------------------------------------------------
 */

`include "vga.svh"

module dla_simulate #(
    parameter N         = 20000,
    parameter AVN_AW    = 19,
    parameter AVN_DW    = 16
) (
    input                       clk,
    input                       rst,
    input                       dla_type,
    output [AVN_AW-1:0]         dla_avn_address,
    output                      dla_avn_write,
    output [AVN_DW-1:0]         dla_avn_writedata,
    input                       dla_avn_waitrequest
);

    // --------------------------------
    // Signal declarations
    // --------------------------------

    localparam LSFR_WIDTH = 16;
    localparam N_SIZE = $clog2(N);

    /*AUTOWIRE*/

    /*AUTOREG*/

    localparam S_IDLE   = 0,    // IDLE state
               S_INIT   = 1,    // Initialize the vram
               S_NEW    = 2,    // Create a new particle
               S_WALK   = 3,    // Walk the particle
               S_WRITE  = 4,    // Write the particle to the vram
               S_DONE   = 5;    // Done dla simulate
    reg [5:0]   state;
    logic [5:0] state_next;

    reg [N_SIZE-1:0]        par_count;

    logic                   init_start;
    logic                   init_done;
    logic                   init_vram_avn_waitrequest;
    logic [AVN_AW-1:0]      init_vram_avn_address;
    logic                   init_vram_avn_write;
    logic                   init_vram_avn_writedata;

    logic                   check_done;
    logic                   check_start;
    logic                   check_vram_avn_readdata;
    logic                   check_vram_avn_readdatavalid;
    logic                   check_vram_avn_waitrequest;
    logic [AVN_AW-1:0]      check_vram_avn_address;
    logic                   check_vram_avn_read;
    logic [`H_SIZE-1:0]     check_x;
    logic [`V_SIZE-1:0]     check_y;
    logic                   hit_boundary;
    logic                   hit_neighbor;

    logic                   walk_start;
    logic [`H_SIZE-1:0]     walk_init_x;
    logic [`V_SIZE-1:0]     walk_init_y;
    logic                   walk_done;
    logic [`H_SIZE-1:0]     walk_final_x;
    logic [`V_SIZE-1:0]     walk_final_y;
    logic                   walk_valid;
    logic [AVN_AW-1:0]      walk_vram_avn_address;
    logic                   walk_vram_avn_write;
    logic                   walk_vram_avn_writedata;
    logic                   walk_vram_avn_waitrequest;

    logic [LSFR_WIDTH-1:0]  lsfr_x;
    logic [LSFR_WIDTH-1:0]  lsfr_y;
    logic                   sim_done;

    logic [AVN_AW-1:0]      vram_avn_address;
    logic                   vram_avn_write;
    logic                   vram_avn_read;
    logic                   vram_avn_writedata;
    logic                   vram_avn_waitrequest;
    logic                   vram_avn_readdata;
    logic                   vram_avn_readdatavalid;

    // --------------------------------
    // Main logic
    // --------------------------------

    assign vram_avn_waitrequest = dla_avn_waitrequest;
    assign init_vram_avn_waitrequest = vram_avn_waitrequest;
    assign walk_vram_avn_waitrequest = vram_avn_waitrequest;

    assign check_vram_avn_readdata = vram_avn_readdata;
    assign check_vram_avn_readdatavalid = vram_avn_readdatavalid;
    assign check_vram_avn_waitrequest = vram_avn_waitrequest;

    assign walk_init_x = lsfr_x[`H_SIZE-1:0];
    assign walk_init_y = lsfr_y[`V_SIZE-1:0];

    assign sim_done = par_count == 0;

    assign vram_avn_write = init_vram_avn_write | walk_vram_avn_write;
    assign vram_avn_read = check_vram_avn_read;
    assign vram_avn_address = init_vram_avn_write ? init_vram_avn_address :
                              walk_vram_avn_write ? walk_vram_avn_address : check_vram_avn_address;
    assign vram_avn_writedata = init_vram_avn_write ? init_vram_avn_writedata : walk_vram_avn_writedata;

    assign dla_avn_address = vram_avn_address;
    assign dla_avn_write = vram_avn_write;
    assign dla_avn_writedata = {AVN_DW{vram_avn_writedata}};

    always @* begin

        init_start = 0;
        walk_start = 0;
        state_next = 0;
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
            state[S_WALK]: begin
                if (walk_done)  state_next[S_WRITE] = 1;
                else            state_next[S_WALK] = 1;
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
            state <= 1;
            par_count <= N;
            vram_avn_readdatavalid <= 0;
        end
        else begin
            state <= state_next;
            vram_avn_readdatavalid <= vram_avn_read;
            if (walk_valid) par_count <= par_count - 1;
        end
    end


    // --------------------------------
    // Module initialization
    // --------------------------------

    dla_vram_init
    #(
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (1))
    u_dla_vram_init
    (
     .clk                               (clk),
     .rst                               (rst),
     .init_type                         (dla_type),
     .init_start                        (init_start),
     .init_done                         (init_done),
     .vram_avn_address                  (init_vram_avn_address),
     .vram_avn_write                    (init_vram_avn_write),
     .vram_avn_writedata                (init_vram_avn_writedata),
     .vram_avn_waitrequest              (init_vram_avn_waitrequest));


    dla_particle_check
    #(
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (1))
    u_dla_particle_check
    (
     .clk                               (clk),
     .rst                               (rst),
     .check_x                           (check_x),
     .check_y                           (check_y),
     .check_start                       (check_start),
     .check_done                        (check_done),
     .hit_boundary                      (hit_boundary),
     .hit_neighbor                      (hit_neighbor),
     .vram_avn_address                  (check_vram_avn_address),
     .vram_avn_read                     (check_vram_avn_read),
     .vram_avn_readdata                 (check_vram_avn_readdata),
     .vram_avn_waitrequest              (check_vram_avn_waitrequest),
     .vram_avn_readdatavalid            (check_vram_avn_readdatavalid));



    dla_particle_walk
    #(
      .AVN_AW                           (AVN_AW),
      .AVN_DW                           (1))
    u_dla_particle_walk
    (
     .clk                               (clk),
     .rst                               (rst),
     .walk_init_x                       (walk_init_x),
     .walk_init_y                       (walk_init_y),
     .walk_start                        (walk_start),
     .walk_done                         (walk_done),
     .walk_valid                        (walk_valid),
     .vram_avn_address                  (walk_vram_avn_address),
     .vram_avn_write                    (walk_vram_avn_write),
     .vram_avn_writedata                (walk_vram_avn_writedata),
     .vram_avn_waitrequest              (walk_vram_avn_waitrequest),
     .check_x                           (check_x),
     .check_y                           (check_y[`V_SIZE-1:0]),
     .check_start                       (check_start),
     .check_done                        (check_done),
     .hit_boundary                      (hit_boundary),
     .hit_neighbor                      (hit_neighbor));

    vga_ram_1rw #(
      .AW       (AVN_AW),
      .DW       (1)
    )
    u_dla_ram (
      .clk      (clk),
      .we       (vram_avn_write),
      .addr     (vram_avn_address),
      .din      (vram_avn_writedata),
      .dout     (vram_avn_readdata)
    );

    dla_lsfr
    #(
     .WIDTH     (LSFR_WIDTH),
     .TAP       ('hD008),
     .SEED      ('habcd))
    u_dla_lsfr_x
    (.clk       (clk),
     .rst       (rst),
     .shift     (walk_start),
     .value     (lsfr_x));

    dla_lsfr
    #(
      .WIDTH    (LSFR_WIDTH),
      .TAP      ('hD008),
      .SEED     ('h1234))
    u_dla_lsfr_y
    (.clk       (clk),
     .rst       (rst),
     .shift     (walk_start),
     .value     (lsfr_y));

endmodule
