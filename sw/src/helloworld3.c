#include <runtime.h>

void
main(void)
{
    char *p = "The quick brown fox jumped over the lazy dog.";
    char *w = "Hello, world. This is a test message.s";

    // for (int i = 0; i < 160*2; i += 2)
    // {
    //     *((volatile char*)(0x20000 + i)) = '\x00';
    //     *((volatile char*)(0x20001 + i)) = '\x00';
    // }

    for (int i = 0; *p != '\0'; i += 2)
    {
        *((volatile char*)(0x20000 + i)) = *p;
        *((volatile char*)(0x20001 + i)) = '\x4f';
        p++;
    }

    for (int j = 0; *w != '\0'; j += 2)
    {
        *((volatile char*)(0x20140 + j)) = *w;
        *((volatile char*)(0x20141 + j)) = '\x4f';
        w++;
    }
}