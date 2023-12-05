#include <runtime.h>

char *HELLO_WORLD = "Hello, world!";

void
main(void)
{
    char *p;
    int i;
    int x = 1;

    for (i = 0, p = HELLO_WORLD; *p != '\0'; i += 2, p++)
    {
        *((volatile char*)(0x20000 + i)) = *p;
        *((volatile char*)(0x20140 + i)) = x;
        x = x * i;
    }
}