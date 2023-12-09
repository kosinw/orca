#include <runtime.h>

void
swap(char *a, char *b)
{
    char temp = *a;
    *a = *b;
    *b = temp;
}

void
sort(char arr[], int size)
{
    for (int i = 0; i < size - 1; i++) {
        int min_index = i;

        for (int j = i + 1; j < size; j++) {
            if (arr[j] < arr[min_index]) {
                min_index = j;
            }
        }

        if (min_index != i) {
            swap(&arr[i], &arr[min_index]);
        }
    }
}

void
main(void)
{
    char array[] = {8, 5, 4, 2, 1, 9, 3, 3, 3, 8, 7, 2, 4, 5};
    // char *p = "The quick brown fox jumped over the lazy dog.";
    // char *w = "Hello, world. This is a test message.";

    // for (int i = 0; i < 160*2*45; i += 2)
    // {
    //     *((volatile char*)(0x20000 + i)) = '\x00';
    //     *((volatile char*)(0x20001 + i)) = '\x00';
    // }

    for (int i = 0; i < sizeof(array); ++i)
    {
        *((volatile char*)(0x20002 + i*2)) = (char)(array[i] + '0');
        *((volatile char*)(0x20003 + i*2)) = '\x4f';
    }

    sort(array, sizeof(array));

    for (int i = 0; i < sizeof(array); ++i)
    {
        *((volatile char*)(0x20142 + i*2)) = (char)(array[i] + '0');
        *((volatile char*)(0x20143 + i*2)) = '\x4f';
    }

    // for (int j = 0; *w != '\0'; j += 2)
    // {
    //     *((volatile char*)(0x20140 + j)) = *w;
    //     *((volatile char*)(0x20141 + j)) = '\x4f';
    //     w++;
    // }
}