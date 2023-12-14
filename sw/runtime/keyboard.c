#include <runtime.h>

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