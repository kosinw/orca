#include <runtime.h>

char
tolower(char c)
{
	if (c >= 65 && c <= 90)
		c += 32;
	return (c);
}

#define ENTER_KEY       0x5A
#define CAPS_LOCK_KEY   0x58
#define BACKSPACE       0x66

void
main(void)
{
    uint8_t kbd[MMIO_KEYBOARD_LEN];
    uint8_t aesin[MMIO_AES_LEN];
    uint8_t aesout[MMIO_AES_LEN];

    memset(aesin, 0, MMIO_AES_LEN);
    memset(aesout, 0, MMIO_AES_LEN);

    uint32_t aeslen = 0;
    uint32_t aeslenout = 0;
    uint32_t len = 0;

    videoinit(FOREGROUND_WHITE | BACKGROUND_BLACK);
    keyboard_wrctrl(); // flush the keyboard

    while (1) {
        // First poll the keyboard
        // Update the buffer if the keyboard has new input that matters.
        // If hit update, then run aes encrypt and wait in a loop until
        // its ready
        if (keyboardpoll(kbd, &len)) {
            for (int i = 0; i < len; i++) {
                if (kbd[i] == ENTER_KEY) { // enter
                    aescopyin(aesin, aeslen);
                    uint32_t *aes_buffer_in = (uint32_t*)MMIO_AES_BUFFER_IN;
                    printf("\n");
                    uint32_t aligned_size = (aeslen + 15) & ~15;

                    aesencrypt();
                    while (!aespoll()) {
                        // videoclear();
                        videomovecursor(0, 0);
                        for (int i = 0; i < 100; i += 4) {
                            printf("aesbuf[%d]: %p \n", i, (aes_buffer_in)[i / 4]);
                        }
                        nanosleep(100);
                    }
                    aescopyout(aesout, &aeslenout);
                    aesack();
                } else if (kbd[i] == CAPS_LOCK_KEY) {

                } else {
                    if (kbd[i] == BACKSPACE) {
                        if (aeslen > 0) {
                            aesin[aeslen] = '\x00';
                            aeslen--;
                        }
                        continue;
                    }

                    aesin[aeslen] = keyboarditoa(kbd[i]);
                    aeslen = (aeslen + 1) % (MMIO_AES_LEN - 1);
                }
            }
        }

        // Render the screen
        // videoclear();
        videomovecursor(20, 0);
        printf("aes output buffer: ");
        printf("%s", aesout);

        videomovecursor(0, 0);
        for (int i = 0; i < 160; i++) { videoputc(' '); }
        videomovecursor(0, 0);
        printf("enter your message: ");
        printf("%s", aesin);

        videoenablecursor(1);

        nanosleep(100000000);
    }
}