#include <runtime.h>

#define ARRAYCOUNT(x)  (sizeof(x) / sizeof(*x))

void
swap(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

int
partition(int arr[], int low, int high)
{
    int pivot = arr[high];
    int i = low - 1;

    for (int j = low; j <= high - 1; j++) {
        if (arr[j] < pivot) {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }

    swap(&arr[i + 1], &arr[high]);
    return i + 1;
}

void
quicksort(int arr[], int low, int high)
{
    if (low < high) {
        int pi = partition(arr, low, high);

        quicksort(arr, low, pi - 1);
        quicksort(arr, pi + 1, high);
    }
}

void
main(void)
{
    int array[] = {91, 204, 233, 238, 164, 4, 17, 74, 216, 8, 121, 76, 43, 140, 216, 200, 249, 192, 188, 19};

    videoinit(BACKGROUND_BLUE | FOREGROUND_WHITE);
    videosetcolumn(1);

    printf("unsorted array: [");
    for (int i = 0; i < ARRAYCOUNT(array); i++) {
        printf("%d", array[i]);
        if (i != ARRAYCOUNT(array) - 1) {
            printf(", ");
        }
    }
    printf("]");

    printf("\n");

    quicksort(array, 0, ARRAYCOUNT(array) - 1);

    printf("  sorted array: [");
    for (int i = 0; i < ARRAYCOUNT(array); i++) {
        printf("%d", array[i]);
        if (i != ARRAYCOUNT(array) - 1) {
            printf(", ");
        }
    }
    printf("]");

    videoenablecursor(1);
}