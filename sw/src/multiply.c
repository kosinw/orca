#define VIDEO_RAM       0x20000

static char digits[] = "0123456789abcdef";

void
putchar(int r, int c, char v)
{
    unsigned char *base = VIDEO_RAM;
    *(base + 160*r*2 + c*2) = v;
}

void
putcolor(int r, int c, char v)
{
    unsigned char *base = VIDEO_RAM;
    *(base + 160*r*2 + c*2 + 1) = v;
}

void
putc(char v)
{
    static int r = 0;
    static int c = 0;

    putchar(r, c, v);

    if (c + 1 == 160) {
        c = 0;
        r = (r + 1) % 45;
    } else {
        c++;
    }
}

void
printint(int xx, int base, int sign)
{
  char buf[16];
  int i;
  unsigned int x;

  if(sign && (sign = xx < 0))
    x = -xx;
  else
    x = xx;

  i = 0;
  do {
    buf[i++] = digits[x % base];
  } while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
    putc(buf[i]);
}

void
main(void)
{
    int dividends[] = {90, 72, 42, 55, 12, 34};
    int divisors[]  = {11, 10, 9, 8, 2, 3, 5, 6};

    for (int r = 0; r < 45; r++) {
        for (int c = 0; c < 160; c++) {
            putchar(r, c, ' ');
            putcolor(r, c, '\x4f');
        }
    }

    for (int i = 0; i < sizeof(dividends) / sizeof(int); i++) {
        for (int j = 0; j < sizeof(divisors) / sizeof(int); j++) {
            printint(dividends[i] * divisors[j], 10, 0);
            putc(' ');
        }
    }
}