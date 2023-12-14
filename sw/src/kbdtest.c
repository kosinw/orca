#include <runtime.h>

char
tolower(char c)
{
	if (c >= 65 && c <= 90)
		c += 32;
	return (c);
}

void
main(void)
{
    uint8_t buf[MMIO_KEYBOARD_LEN];
    uint32_t len;

    videoinit(FOREGROUND_FUSCHIA | BACKGROUND_WHITE);
    keyboard_wrctrl(); // flush the keyboard

    printf("starting:\n");

    while (1) {
        if (keyboardpoll(buf, &len)) {
            for (int i = 0; i < len; i++) {
                char c = keyboarditoa(buf[i]);
                if (c != 0) {
                    printf("%c", (uint32_t)tolower(c));
                }
            }
            videoenablecursor(1);
        } else {
            nanosleep(1);
        }
    }
}