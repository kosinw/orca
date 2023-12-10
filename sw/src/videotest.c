#include <runtime.h>

void
main(void)
{
    char *p = "The quick brown fox jumped over the lazy dog.";
    char *w = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG!";

    videoinit(FOREGROUND_WHITE | BACKGROUND_RED);

    printf("%s\n", p);
    printf("%s", w);

    videoenablecursor(1);
}