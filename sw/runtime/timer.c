#include <runtime.h>

uint32_t
time(void)
{
    return *(uint32_t*)MMIO_COUNTER;
}

void
nanosleep(uint32_t m)
{
    uint32_t ticks = m / 1000;
    volatile uint32_t first = time();

    while (1)
    {
        volatile uint32_t second = time();
        asm volatile("nop");
        if (second - first > ticks) {
            break;
        }
    }
}