#define VIDEO_RAM       0x000020000
#define MMIO_COUNTER    0x000010000
#define MMIO_ENTROPY    0x000010004

#include <stdint.h>

static char digits[] = "0123456789abcdef";

struct xorshift32_state {
    uint32_t a;
};

uint32_t xorshift32(struct xorshift32_state *state)
{
	uint32_t x = state->a;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	return state->a = x;
}

void
increment(int *r, int *c)
{
    if ((*c) + 1 == 160) {
        *c = 0;
        *r = (*r + 1) % 45;
    } else {
        *c = *c + 1;
    }
}

void
putchar(int r, int c, char v)
{
    unsigned char *base = (unsigned char*)VIDEO_RAM;
    *((unsigned char *)(base + 160*r*2 + c*2)) = v;
}

void
putcolor(int r, int c, char v)
{
    unsigned char *base = (unsigned char*)VIDEO_RAM;
    *((unsigned char *)(base + 160*r*2 + c*2 + 1)) = v;
}

void
puts(char *s, int *r, int *c)
{
    while (*s != 0) {
        putchar(*r, *c, *s);
        increment(r, c);
        s++;
    }
}

void
clearscreen(char color)
{
    for (int r = 0; r < 45; r++) {
        for (int c = 0; c < 160; c++) {
            putchar(r, c, '\x00');
            putcolor(r, c, color);
        }
    }
}

void
printint(unsigned long x, int base, int *r, int *c)
{
  char buf[32];
  int i;

  i = 0;
  do {
    buf[i++] = digits[x % base];
  } while((x /= base) != 0);

  while(--i >= 0) {
    putchar(*r, *c, buf[i]);
    increment(r, c);
  }
}

inline uint32_t
entropy(void)
{
    return *(uint32_t*)MMIO_ENTROPY;
}

inline uint32_t
counter(void)
{
    return *(uint32_t*)MMIO_COUNTER;
}

void
main(void)
{
    clearscreen('\x04');
    struct xorshift32_state state = { .a = entropy() };
    int r = 1;
    int c = 1;

    volatile uint32_t first = counter();

    while (1) {
        volatile uint32_t second = counter();
        if ((second - first) > 400000) {
            for (int round = 0; round < 10; round++) {
                puts("ROUND", &r, &c);
                printint(round, 10, &r, &c);
                puts(": 0x", &r, &c);
                printint(xorshift32(&state), 16, &r, &c);

                r++;
                c = 1;
            }
            r = 1;
            c = 1;
            first = second;
        }
    }
}