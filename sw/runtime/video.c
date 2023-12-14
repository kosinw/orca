#include <runtime.h>

struct video_char {
    char        character;
    uint8_t     color;
};

struct video_buffer {
    int                     row;     // current row of the cursor
    int                     col;     // current col of the cursor
    int                     dc;      // default column to move to
    struct video_char       *buf;    // buffer location
    uint8_t                 color;   // default color for printing
};

static struct video_buffer VIDEO;

void
videoinit(uint8_t color)
{
    VIDEO.row    = 0;
    VIDEO.col    = 0;
    VIDEO.dc     = 0;
    VIDEO.buf    = (struct video_char *)MMIO_VIDEO_RAM;
    VIDEO.color  = color;

    videoclear();
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
    VIDEO.color = c;
}

void
videosetcolumn(int d)
{
    VIDEO.col = d;
    VIDEO.dc = d;
}

void
videomovecursor(int r, int c)
{
    struct video_char ch = VIDEO.buf[VIDEO.row * VIDEO_BUFFER_WIDTH + VIDEO.col];
    int enabled = (ch.color & BLINK) != 0;

    videoenablecursor(0);

    VIDEO.row = r;
    VIDEO.col = c;

    if (enabled) {
        videoenablecursor(1);
    }
}

uint8_t
videogetcolor(void)
{
    return VIDEO.color;
}

void
videoenablecursor(int enable)
{
    if (enable) {
        videoputchar(' ', (VIDEO.color | BLINK), VIDEO.row, VIDEO.col);
    } else {
        videoputchar('\x00', VIDEO.color, VIDEO.row, VIDEO.col);
    }
}

void
videoputchar(char character, uint8_t color, int r, int c)
{
    VIDEO.buf[r * VIDEO_BUFFER_WIDTH + c] = (struct video_char){ .character = character, .color = color };
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
    VIDEO.buf[i].color = VIDEO.color;

    // nanosleep(20000000);
}

static void
videonextline(void)
{
    if ((VIDEO.row + 1) == VIDEO_BUFFER_HEIGHT) {
        videoscrollup(1);
        VIDEO.col = VIDEO.dc;
    } else {
        VIDEO.col = VIDEO.dc;
        VIDEO.row = VIDEO.row + 1;
    }
}

static void
videonextpos(void)
{
    if ((VIDEO.col + 1) == VIDEO_BUFFER_WIDTH) {
        videonextline();
    } else {
        VIDEO.col += 1;
    }
}

void
videoputc(char c)
{
    videoenablecursor(0);

    if (c == '\n') {
        videonextline();
    } else if (c == '\b') {
        videoputchar('\x00', VIDEO.color, VIDEO.row, VIDEO.col);
        if (VIDEO.col != 0) {
            VIDEO.col -= 1;
        } else {
            VIDEO.col = 159;
            VIDEO.row = VIDEO.row == 0 ? 0 : (VIDEO.row - 1);
        }
    } else {
        videoputchar(c, VIDEO.color, VIDEO.row, VIDEO.col);
        videonextpos();
    }
}