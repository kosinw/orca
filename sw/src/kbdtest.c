#include <runtime.h>

bool
keyboardpoll(uint8_t keys[], uint32_t *len_out)
{
    // First read from the control register.
    uint8_t ctrl = keyboard_rdctrl();

    printf("%x\n", (uint32_t)ctrl);

    // If not available then return immediately.
    if ((ctrl & KEYBOARD_CTRL_READY) == 0) {
        *len_out = 0;
        return false;
    }

    // Otherwise read the number of characters and do a memcpy.
    uint32_t num_chars = KEYBOARD_NUM_CHARS(ctrl);
    uint8_t *char_buf = (uint8_t*)MMIO_KEYBOARD_BUF;

    memcpy(keys, char_buf, num_chars);
    *len_out = num_chars;

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
            printf("seen!\n");
            for (int i = 0; i < len; i++) {
                printf("%x ", (uint32_t)buf[i]);
            }
            printf("\n");
            videoenablecursor(1);
            nanosleep(10000);
            keyboard_wrctrl();
        } else {
            nanosleep(10000);
        }
    }
}