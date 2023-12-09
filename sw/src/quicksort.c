#define VIDEO_RAM       0x000020000

static char digits[] = "0123456789abcdef";
static int r = 0;
static int c = 0;

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
putc(char v)
{
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
swap(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

int
partition(int arr[], int low, int high)
{
    int pivot = arr[high];
    int i = low - 1;

    for (int j = low; j <= high - 1; j++) {
        if (arr[j] < pivot) {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }

    swap(&arr[i + 1], &arr[high]);
    return i + 1;
}

void
quicksort(int arr[], int low, int high)
{
    if (low < high) {
        int pi = partition(arr, low, high);

        quicksort(arr, low, pi - 1);
        quicksort(arr, pi + 1, high);
    }
}

void
main(void)
{
    int array[] = {91, 204, 233, 238, 164, 4, 17, 74, 216, 8, 121, 76, 43, 140, 216, 200, 249, 192, 188, 19};

    int size = sizeof(array) / sizeof(int);

    for (int r = 0; r < 45; r++) {
        for (int c = 0; c < 160; c++) {
            putchar(r, c, '\x00');
            putcolor(r, c, '\x0f');
        }
    }

    c = 10;

    for (int i = 0; i < size; ++i)
    {
        printint(array[i], 10, 0);

        if (i != size - 1) {
            putc(',');
            putc(' ');
        }
    }

    r += 1;
    c = 10;

    quicksort(array, 0, size-1);

    for (int i = 0; i < size; ++i)
    {
        printint(array[i], 10, 0);

        if (i != size - 1) {
            putc(',');
            putc(' ');
        }
    }
}