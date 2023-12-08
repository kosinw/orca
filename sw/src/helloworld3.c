#include <runtime.h>

void
main(void)
{
    char *p = "The quick brown fox jumped over the lazy dog.";
    int i;

    for (i = 0; *p != '\0'; i += 2)
    {
        *((volatile char*)(0x20000 + i)) = *p;
        p++;
    }

    *((volatile char*)(0x20142)) = ((i*i) + '0');
}