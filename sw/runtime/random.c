#include <runtime.h>

static uint32_t state = 0xdeadbeef;

uint32_t
xorshift32(void)
{
	uint32_t x = state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
    state = x;
	return x;
}

void
srand(void)
{
    state = entropy();
}

uint32_t
entropy(void)
{
    return *(uint32_t*)MMIO_ENTROPY;
}