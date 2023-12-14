#include <runtime.h>

#define BOARD_WIDTH 160
#define BOARD_HEIGHT 45

#define MAX_INITIAL_CELLS 2400

void
initboard(bool *grid, int width, int height)
{
    int cells_left = MAX_INITIAL_CELLS;

    srand();

    for (int r = 0; r < height; r++) {
        for (int c = 0; c < width; c++) {
            if (cells_left > 0 && (xorshift32() % 100) < 20) {
                grid[width*r+c] = true;
                cells_left--;
            } else {
                grid[width*r+c] = false;
            }
        }
    }
}

void
updateboard(bool *grid, int width, int height)
{
    bool newgrid[width*height];
    int dxy[] = {-1,0,+1};

    for (int r = 0; r < height; r++) {
        for (int c = 0; c < width; c++) {
            int neighbors = 0;

            // Count neighbors.
            for (int x = 0; x < 3; x++) {
                for (int y = 0; y < 3; y++) {
                    int dx = dxy[x] + c;
                    int dy = dxy[y] + r;

                    if (dx == c && dy == r)
                        continue;

                    if (dx < 0 || dx >= width || dy < 0 || dy >= height)
                        continue;

                    if (grid[dx+dy*width]) {
                        neighbors++;
                    }
                }
            }

            // Do rules
            if (grid[c+r*width]) {
                if (neighbors < 2) {
                    newgrid[c+r*width] = false;
                } else if (neighbors > 3) {
                    newgrid[c+r*width] = false;
                } else {
                    newgrid[c+r*width] = true;
                }
            } else {
                if (neighbors == 3) {
                    newgrid[c+r*width] = true;
                } else {
                    newgrid[c+r*width] = false;
                }
            }
        }
    }

    for (int i = 0; i < height*width; i++) {
        grid[i] = newgrid[i];
    }
}

void
drawgrid(bool *grid, int width, int height)
{
    for (int r = 0; r < height; r++) {
        for (int c = 0; c < width; c++) {
            uint8_t color = !grid[width*r+c] ? (FOREGROUND_BLACK | BACKGROUND_WHITE) : (FOREGROUND_WHITE | BACKGROUND_BLACK);
            videoputchar(0xdb, color, r, c);
        }
    }
}

void
main(void)
{
    bool GRID[BOARD_WIDTH * BOARD_HEIGHT];

    videoinit(FOREGROUND_WHITE | BACKGROUND_BLACK);
    keyboard_wrctrl(); // flush the keyboard

    videomovecursor(0, 0);

    // Then sleep for like 2s
    // nanosleep(2000000000);

    // Initialize the board with random cells on.
    initboard(GRID, BOARD_WIDTH, BOARD_HEIGHT);

    while (1) {
        // First update the game
        updateboard(GRID, BOARD_WIDTH, BOARD_HEIGHT);

        // Then draw the cells
        drawgrid(GRID, BOARD_WIDTH, BOARD_HEIGHT);

        // Then sleep for like 300 ms
        nanosleep(50000000);
        // break;
    }
}