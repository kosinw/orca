#include <runtime.h>

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
  char buf[16];
  int i;
  uint32_t x;

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
    videoputc(buf[i]);
}

static void
printptr(uint32_t x)
{
  int i;
  videoputc('0');
  videoputc('x');
  for (i = 0; i < (sizeof(uint32_t) * 2); i++, x <<= 4)
    videoputc(digits[x >> (sizeof(uint32_t) * 8 - 4)]);
}

void
printf(char *fmt, ...)
{
  va_list ap;
  int i, c;
  char *s;

  if (fmt == 0) return;

  va_start(ap, fmt);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    if(c != '%'){
      videoputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    case 'd':
      printint(va_arg(ap, int), 10, 1);
      break;
    case 'x':
      printint(va_arg(ap, int), 16, 1);
      break;
    case 'p':
      printptr(va_arg(ap, uint32_t));
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        videoputc(*s);
      break;
    case '%':
      videoputc('%');
      break;
    default:
      // Print unknown % sequence to draw attention.
      videoputc('%');
      videoputc(c);
      break;
    }
  }
  va_end(ap);
}