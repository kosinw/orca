#include <runtime.h>

void
main(void)
{
    char *p = "The quick brown fox jumped over the lazy dog.";
    char *w = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG!";

    videoinit((entropy() & 0x0F) | BACKGROUND_BLACK);

    printf("%s\n", p);
    printf("%s", w);

    videoenablecursor(1);
}