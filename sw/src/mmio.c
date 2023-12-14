#include <runtime.h>

void
main(void)
{
    videoinit(FOREGROUND_WHITE | BACKGROUND_BLACK);

    while (1) {
        printf("COUNTER: %p\n", time());
        printf("ENTROPY: %p\n", entropy());

        videomovecursor(0, 0);
    }
}