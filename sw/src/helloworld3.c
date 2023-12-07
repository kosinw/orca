#include <runtime.h>

void
main(void)
{
    char *p = "Hello, world!";
    int i;

    for (i = 0; *p != '\0'; i += 2)
    {
        *((volatile char*)(0x20000 + i)) = *p;
        p++;
    }

    *((volatile char*)(0x20000 + 322)) = ((i*i) + '0');
}