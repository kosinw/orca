#include <runtime.h>

#define START_ADDR      MMIO_AES_CTRL
// #define START_ADDR      MMIO_AES_BUFFER_IN

void
main(void)
{
    videoinit(FOREGROUND_WHITE | BACKGROUND_BLACK);
    keyboard_wrctrl(); // flush the keyboard

    while (1) {
        videomovecursor(0, 0);

        int current_addr = START_ADDR;

        for (int lines = 0; lines < 44; lines++) {
            printf("%p: ", current_addr);

            for (int values = 0; values < 32; values += 4) {
                printf("%p ", *(uint32_t*)current_addr);
                current_addr += 4;
            }

            if (lines != 43) {
                printf("\n");
            }
        }


        nanosleep(900000000);
    }
}