#include <runtime.h>

static const char kbd[] =
{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    '`', 0, 0, 0, 0, 0, 0, 'Q', '1', 0, 0, 0,
    'Z', 'S', 'A', 'W', '2', 0, 0, 'C', 'X', 'D',
    'E', '4', '3', 0, 0, ' ', 'V', 'F', 'T', 'R', '5',
    0, 0, 'N', 'B', 'H', 'G', 'Y', '6', 0, 0, 0, 'M',
    'J', 'U', '7', '8', 0, 0, ',', 'K', 'I', 'O', '0', '9',
    0, 0, '.', '/', 'L', ';', 'P', '-', 0, 0, 0, '\'', 0, '[',
    '=', 0, 0, 0, 0, '\n', ']', 0, '\\', 0, 0, 0, 0, 0, 0, 0, 0,
    '\b', 0, 0, '1', 0, '4', '7', 0, 0, 0, '0', '.', '2', '5', '6',
    '8', 0, 0, 0, '+', '3', '-', '*', '9', 0, 0
};

uint8_t
keyboard_rdctrl(void)
{
    uint8_t *ctrl_reg = (uint8_t*)MMIO_KEYBOARD_CTRL;
    return *ctrl_reg;
}

void
keyboard_wrctrl(void)
{
    volatile uint8_t *ctrl_reg = (volatile uint8_t*)MMIO_KEYBOARD_CTRL;
    *ctrl_reg = 0;
}

uint8_t
keyboard_getc(uint32_t i)
{
    if (i < 0 || i >= MMIO_KEYBOARD_LEN)
        return 0;

    volatile uint8_t *buf = (volatile uint8_t*)MMIO_KEYBOARD_BUF;
    return buf[i];
}

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

    uint8_t *char_buf = (uint8_t*)MMIO_KEYBOARD_BUF;

    for (int i = 0; i < num_chars; i++) {
        keys[i] = keyboard_getc(i);
    }

    *len_out = num_chars;

    // Acknowledge right away
    keyboard_wrctrl();

    return true;
}


char
keyboarditoa(uint8_t scancode)
{
    if (scancode > 0x7F)
        return '\x00';

    return kbd[scancode & 0x7F];
}