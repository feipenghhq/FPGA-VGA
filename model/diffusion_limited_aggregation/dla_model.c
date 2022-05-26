/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 05/24/2022
 * ---------------------------------------------------------------
 *
 * A  C model for DLA.
 *
 * It generates the x, y positions for other tools to plot th picture
 *
 * ---------------------------------------------------------------
 */

#include <stdlib.h>
#include <stdio.h>

// size
#define WIDTH           (640)
#define HEIGHT          (480)
// Number of particles to draw
#define N               (20000)
#define OUTPUT_FILE     ("dla_model.csv")

int dla[WIDTH][HEIGHT];
int n = N;

/**
 * @brief Initializes the dla array
 *
 */
void init_dla(void) {
    for (int i = 0; i < WIDTH; i++) {
        for (int j = 0; j < HEIGHT; j++) {
            dla[i][j] = 0;
        }
    }
    dla[WIDTH/2][HEIGHT/2] = 1;
}

/**
 * @brief Check if the particle hits the neighborhood
 *
 * @param x
 * @param y
 * @return int
 */
int check_neighbor(int x, int y) {
    for (int xx = x-1; xx <= x+1; xx++) {
        for (int yy = y-1; yy <= y+1; yy++) {
            if (dla[xx][yy] == 1 && xx != x && yy != y) {
                return 1;
            }
        }
    }
    return 0;
}

/**
 * @brief Check if the particle hits the boundary
 *
 * @param x
 * @param y
 * @return int
 */
int check_boundary(int x, int y) {
    if (x == 0 || y == 0) return 1;
    if (x == WIDTH-1 || y == HEIGHT-1) return 1;
    return 0;
}

/**
 * @brief walk one particle
 *
 */
void walking(int x, int y) {
    while (1) {
        if (check_boundary(x, y)) return;
        if (check_neighbor(x, y)) {
            n--;
            dla[x][y] = 1;
            return;
        }
        x = x + (rand() % 3 - 1);
        y = y + (rand() % 3 - 1);
    }
}

/**
 * @brief DLA simulation
 *
 */
void dla_simulation(void) {
    int x, y;
    init_dla();
    while(n > 0) {
        x = rand() % (WIDTH - 1);
        y = rand() % (HEIGHT - 1);
        walking(x, y);
    }
}


/**
 * @brief Write the DLA result to a file
 *
 */
void write_dla_result(void) {
    FILE *fptr;
    fptr = fopen(OUTPUT_FILE, "w");
    fprintf(fptr, "%d, %d\n", WIDTH, HEIGHT);
    for (int x = 0; x < WIDTH; x++) {
        for (int y = 0; y < HEIGHT; y++) {
            if (dla[x][y] == 1) {
                fprintf(fptr, "%d, %d\n", x, y);
            }
        }
    }
    fclose(fptr);
}


int main(void) {
    printf("Starting DLA simulation\n");
    dla_simulation();
    printf("Completed DLA simulation\n");
    write_dla_result();
    return 0;
}