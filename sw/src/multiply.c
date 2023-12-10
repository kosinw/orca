#include <runtime.h>

#define ARRAYCOUNT(x)  (sizeof(x) / sizeof(*x))

void
main(void)
{
    int dividends[] = {90, 72, 42, 55, 12, 34};
    int divisors[]  = {11, 10, 9, 8, 2, 3, 5, 6};

    videoinit(FOREGROUND_WHITE | BACKGROUND_BLACK);
    videoenablecursor(1);

    while (1) {
        for (int i = 0; i < ARRAYCOUNT(dividends); i++) {
            for (int j = 0; j < ARRAYCOUNT(divisors); j++) {
                int a = dividends[i];
                int b = divisors[j];

                printf("%d * %d = %d\n", a, b, a * b);
                nanosleep(100000000);
            }
        }
    }
}