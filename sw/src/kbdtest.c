#include <runtime.h>

bool
keyboardpoll(uint8_t keys[], uint32_t *len_out)
{
    // First read from the control register.
    uint8_t ctrl = keyboard_rdctrl();

    // If not available then return immediately.
    if ((ctrl & KEYBOARD_CTRL_READY) == 0) {
        *len_out = 0;
        return false;
    }

    // Otherwise read the number of characters and do a memcpy.
    uint32_t num_chars = KEYBOARD_NUM_CHARS(ctrl);
    printf("COUNTER: %d\n", num_chars);

    uint8_t *char_buf = (uint8_t*)MMIO_KEYBOARD_BUF;

    for (int i = 0; i < num_chars; i++) {
        keys[i] = keyboard_getc(i);
    }

    *len_out = num_chars;

    // Acknowledge right away
    // keyboard_wrctrl();

    return true;
}

void
main(void)
{
    uint8_t buf[MMIO_KEYBOARD_LEN];
    uint32_t len;

    videoinit(FOREGROUND_FUSCHIA | BACKGROUND_WHITE);

    printf("starting:\n");

    while (1) {
        if (keyboardpoll(buf, &len)) {
            for (int i = 0; i < len; i++) {
                printf("%x ", (uint32_t)buf[i]);
            }
            printf("\n");
            videoenablecursor(1);
        } else {
            nanosleep(1);
        }
    }
}