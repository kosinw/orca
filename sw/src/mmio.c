#define VIDEO_RAM       0x000020000
#define MMIO_COUNTER    0x000010000
#define MMIO_ENTROPY    0x000010004

static char digits[] = "0123456789abcdef";

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

void
main(void)
{
    clearscreen('\x0f');

    while (1) {
        unsigned long *counter = (unsigned long *)MMIO_COUNTER;
        unsigned long *entropy = (unsigned long *)MMIO_ENTROPY;

        int r = 1;
        int c = 1;

        puts("COUNTER: 0x", &r, &c);
        printint(*counter, 16, &r, &c);

        r = 2;
        c = 1;

        puts("ENTROPY: 0x", &r, &c);
        printint(*entropy, 16, &r, &c);
    }
}