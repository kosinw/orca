#include <runtime.h>

void
main(void)
{
    videoinit(BACKGROUND_BLACK | FOREGROUND_BLUE);
    videosetcolumn(80);
    srand();

    while (1) {
        videomovecursor(VIDEO_BUFFER_HEIGHT - 1, 80);
        for (int round = 0; round < 10; round++) {
            printf("ROUND%d: %p\n", round, xorshift32());
        }
        videoenablecursor(1);
    }
}