#include <runtime.h>

void
main(void)
{
    char *p = "H\x4fe\x4fl\x4fl\x4fo\x4f,\x4f \x4fw\x4fo\x4fr\x4fl\x4fd\x4f!\x4f";
    memmove((void*)0x20000, p, sizeof(p) - 1);
}