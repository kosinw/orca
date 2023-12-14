#include <runtime.h>

void
aescopyin(uint8_t *buffer, uint32_t size)
{
    // align to 16 byte boundary
    uint32_t aligned_size = (size + 15) & ~15;
    uint8_t *aes_buffer_in = (uint8_t*)MMIO_AES_BUFFER_IN;
    int i;


    if (aligned_size > MMIO_AES_LEN)
        return;

    for (i = 0; i < size; i++) {
        aes_buffer_in[i] = buffer[i];
    }

    for (i = size; i < aligned_size; i++) {
        aes_buffer_in[i] = 0x00;
    }

    // at the end of the buffer put deadbeef
    aes_buffer_in[i]   = 0xef;
    aes_buffer_in[i+1] = 0xbe;
    aes_buffer_in[i+2] = 0xad;
    aes_buffer_in[i+3] = 0xde;
    // aes_buffer_in[i]   = 0xde;
    // aes_buffer_in[i+1] = 0xad;
    // aes_buffer_in[i+2] = 0xbe;
    // aes_buffer_in[i+3] = 0xef;
}

void
aescopyout(uint8_t *buffer, uint32_t *size_out)
{
    // go to start of
    uint8_t *aes_buffer_out = (uint8_t*)MMIO_AES_BUFFER_OUT;
    uint32_t *out_buffer = (uint32_t*)buffer;

    uint32_t copied = 0;

    while (1) {
        if (copied > (MMIO_AES_LEN / 4))
            break;

        if (aes_buffer_out[copied] == 0xdeadbeef)
            break;

        out_buffer[copied] = aes_buffer_out[copied];
        copied++;
    }

    aes_buffer_out[copied] = 0x00;

    *size_out = copied * 4;
}

void
aesencrypt(void)
{
    uint8_t *aes_ctrl_reg = (uint8_t *)MMIO_AES_CTRL;
    *aes_ctrl_reg = 0b001;
}

void
aesdecrypt(void)
{
    uint8_t *aes_ctrl_reg = (uint8_t *)MMIO_AES_CTRL;
    *aes_ctrl_reg = 0b010;
}

bool
aespoll(void)
{
    uint8_t *aes_ctrl_reg = (uint8_t *)MMIO_AES_CTRL;
    // printf("%p\n", *aes_ctrl_reg);
    return (*aes_ctrl_reg & 0b100) != 0;
}

void
aesack(void)
{
    uint8_t *aes_ctrl_reg = (uint8_t *)MMIO_AES_CTRL;
    *aes_ctrl_reg = 0b000;
}