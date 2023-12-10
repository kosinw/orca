#include <runtime.h>

struct video_char {
    char        character;
    uint8_t     color;
};

struct video_buffer {
    int                     row;     // current row of the cursor
    int                     col;     // current col of the cursor
    struct video_char       *buf;    // buffer location
    uint8_t                 color;   // default color for printing
    uint8_t                 cursor;  // cursor color
};

static struct video_buffer VIDEO;

void
videoinit(uint8_t color)
{
    VIDEO.row    = 0;
    VIDEO.col    = 0;
    VIDEO.buf    = (struct video_char *)MMIO_VIDEO_RAM;
    VIDEO.color  = color;
    VIDEO.cursor = 0;

    videoclear();
    videomovecursor(0, 0);
}

void
videoclear(void)
{
    for (int r = 0; r < VIDEO_BUFFER_HEIGHT; r++) {
        for (int c = 0; c < VIDEO_BUFFER_WIDTH; c++) {
            videoputchar('\x00', VIDEO.color, r, c);
        }
    }
}

void
videosetcolor(uint8_t c)
{
    VIDEO.color = c & ~BACKGROUND_BLINK;
}

uint8_t
videogetcolor(void)
{
    return VIDEO.color;
}

void
videoenablecursor(int enable)
{
    VIDEO.cursor = (enable) ? BACKGROUND_BLINK : 0;
    videoputchar('\x00', VIDEO.color | VIDEO.cursor, VIDEO.row, VIDEO.col);
}

void
videoputchar(char character, uint8_t color, int r, int c)
{
    VIDEO.buf[r * VIDEO_BUFFER_WIDTH + c] = (struct video_char){ .character = character, .color = color };
}

void
videomovecursor(int r, int c)
{
    videoputchar('\x00', VIDEO.color, VIDEO.row, VIDEO.col);
    VIDEO.row = r;
    VIDEO.col = c;
    videoputchar('\x00', VIDEO.color | VIDEO.cursor, VIDEO.row, VIDEO.col);
}

void
videoscrollup(int lines)
{
    int i = 0;
    int buffer_size = VIDEO_BUFFER_WIDTH * VIDEO_BUFFER_HEIGHT;
    int scroll_size = lines * VIDEO_BUFFER_WIDTH;
    int copy_size = buffer_size - scroll_size;

    for (i = 0; i < copy_size; ++i) {
        VIDEO.buf[i] = VIDEO.buf[i + scroll_size];
    }

    for (i = copy_size; i < buffer_size; i++) {
        VIDEO.buf[i].character = '\x00';
        VIDEO.buf[i].color = VIDEO.color;
    }

    VIDEO.buf[i].character = '\x00';
    VIDEO.buf[i].color = VIDEO.color | VIDEO.cursor;
}

static void
videonextline(void)
{
    if ((VIDEO.row + 1) == VIDEO_BUFFER_HEIGHT) {
        videoscrollup(1);
        VIDEO.col = 0;
    } else {
        VIDEO.col = 0;
        VIDEO.row = VIDEO.row + 1;
    }
}

void
videoputc(char c)
{
    if (c == '\n') {
        videonextline();
    } else {
        videoputchar(c, VIDEO.color, VIDEO.row, VIDEO.col);

        if ((VIDEO.col + 1) == VIDEO_BUFFER_WIDTH) {
            videonextline();
        } else {
            VIDEO.col += 1;
        }
    }

    videomovecursor(VIDEO.row, VIDEO.col);
}