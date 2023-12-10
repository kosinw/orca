#include <runtime.h>

void
main(void)
{
    char *p = "The quick brown fox jumped over the lazy dog.";
    char *w = "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG!";

    videoinit(FOREGROUND_RED | BACKGROUND_WHITE);
    videosetcursor(1);

    printf("%s\n", p);
    printf("%s\n", w);
}