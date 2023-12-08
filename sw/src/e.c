#include <runtime.h>

void
main(void)
{
    for (int i = 0; i < 160*45*2; i += 2)
    {
        *((volatile char*)(0x20000 + i)) = 'e';
        *((volatile char*)(0x20001 + i)) = '\x56';
    }
}