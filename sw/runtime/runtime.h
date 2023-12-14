#pragma once

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

// mmio addresses

#define MMIO_VIDEO_RAM          0x20000
#define MMIO_COUNTER            0x10000
#define MMIO_ENTROPY            0x10004
#define MMIO_KEYBOARD_CTRL      0x30080
#define MMIO_KEYBOARD_BUF       0x30000
#define MMIO_KEYBOARD_LEN       0x80
#define MMIO_AES_CTRL           0x41000
#define MMIO_AES_BUFFER_IN      0x40000
#define MMIO_AES_BUFFER_OUT     0x40404
#define MMIO_AES_LEN            0x404

// string.c - string manipulation
int         memcmp(const void*, const void*, unsigned);
void*       memmove(void*, const void*, unsigned);
void*       memcpy(void*, const void*, unsigned int);
void*       memset(void*, int, unsigned);
int         strlen(const char*);
int         strncmp(const char*, const char*, unsigned);
char*       strncpy(char*, const char*, int);

// video.c - video buffer primitives
void        videoinit(uint8_t);
void        videoclear(void);
void        videosetcolor(uint8_t);
void        videosetcolumn(int);
void        videomovecursor(int, int);
uint8_t     videogetcolor(void);
void        videoenablecursor(int);
void        videoputchar(char, uint8_t, int, int);
void        videoscrollup(int);
void        videoputc(char);

// printf.c - printing formatted text
void        printf(char *fmt, ...);

// timer.c  - timing and what not
uint32_t    time(void);
void        nanosleep(uint32_t);

// random.c - randomness
uint32_t    entropy(void);
void        srand(void);
uint32_t    xorshift32(void);

// keyboard.c - keyboard
uint8_t     keyboard_rdctrl(void);
void        keyboard_wrctrl(void);
uint8_t     keyboard_getc(uint32_t);
bool        keyboardpoll(uint8_t*, uint32_t*);
char        keyboarditoa(uint8_t);

// aes.c - aes
void        aescopyin(uint8_t *, uint32_t);     // copy data into aes input buffer
void        aescopyout(uint8_t*, uint32_t*);    // copy data out of aes output buffer
void        aesencrypt(void);                   // tell aes coprocessor to encrypt
void        aesdecrypt(void);                   // tell aes coprocessor to decrypt
bool        aespoll(void);                      // 001 encrypt 010 decrypt 100 done 000 ack
void        aesack(void);                       // acknowledge that you have read from aes output buffer

#define KEYBOARD_CTRL_READY         0x01
#define KEYBOARD_NUM_CHARS(x)        (x >> 1)

// defines
#define COLOR_BLACK             0b000
#define COLOR_RED               0b001
#define COLOR_GREEN             0b010
#define COLOR_YELLOW            0b011
#define COLOR_BLUE              0b100
#define COLOR_FUCHSIA           0b101
#define COLOR_AQUA              0b110
#define COLOR_WHITE             0b111

#define FOREGROUND_LIGHT        1 << 3
#define BLINK                   1 << 7

#define FOREGROUND_BLACK        COLOR_BLACK
#define FOREGROUND_MAROON       COLOR_RED
#define FOREGROUND_GREEN        COLOR_GREEN
#define FOREGROUND_OLIVE        COLOR_YELLOW
#define FOREGROUND_NAVY         COLOR_BLUE
#define FOREGROUND_PURPLE       COLOR_FUSCHIA
#define FOREGROUND_TEAL         COLOR_AQUA
#define FOREGROUND_SILVER       COLOR_WHITE
#define FOREGROUND_GRAY         FOREGROUND_LIGHT | COLOR_BLACK
#define FOREGROUND_RED          FOREGROUND_LIGHT | COLOR_RED
#define FOREGROUND_LIME         FOREGROUND_LIGHT | COLOR_GREEN
#define FOREGROUND_YELLOW       FOREGROUND_LIGHT | COLOR_YELLOW
#define FOREGROUND_BLUE         FOREGROUND_LIGHT | COLOR_BLUE
#define FOREGROUND_FUSCHIA      FOREGROUND_LIGHT | COLOR_FUCHSIA
#define FOREGROUND_AQUA         FOREGROUND_LIGHT | COLOR_AQUA
#define FOREGROUND_WHITE        FOREGROUND_LIGHT | COLOR_WHITE

#define BACKGROUND_BLACK        COLOR_BLACK << 4
#define BACKGROUND_RED          COLOR_RED << 4
#define BACKGROUND_GREN         COLOR_GREEN << 4
#define BACKGROUND_YELLOW       COLOR_YELLOW << 4
#define BACKGROUND_BLUE         COLOR_BLUE << 4
#define BACKGROUND_FUSCHIA      COLOR_FUSCHIA << 4
#define BACKGROUND_AQUA         COLOR_AQUA << 4
#define BACKGROUND_WHITE        COLOR_WHITE << 4

#define VIDEO_BUFFER_WIDTH  160
#define VIDEO_BUFFER_HEIGHT 45

#define VIDEO_OPTION_CURSOR 1 << 0

// Horizontal Lines
#define BOX_HORIZONTAL '\xC4'
#define BOX_HORIZONTAL_DOUBLE '\xCD'
#define BOX_HORIZONTAL_LIGHT '\xB3'

// Vertical Lines
#define BOX_VERTICAL '\xB3'
#define BOX_VERTICAL_DOUBLE '\xBA'
#define BOX_VERTICAL_LIGHT '\xC4'

// Corners
#define BOX_TOP_LEFT '\xDA'
#define BOX_TOP_RIGHT '\xBF'
#define BOX_BOTTOM_LEFT '\xC0'
#define BOX_BOTTOM_RIGHT '\xD9'

// Intersections
#define BOX_INTERSECTION_TOP '\xC2'
#define BOX_INTERSECTION_BOTTOM '\xC1'
#define BOX_INTERSECTION_LEFT '\xC3'
#define BOX_INTERSECTION_RIGHT '\xB4'
#define BOX_INTERSECTION_CROSS '\xC5'

// T-Junctions
#define BOX_T_LEFT '\xC6'
#define BOX_T_RIGHT '\xC7'
#define BOX_T_TOP '\xC8'
#define BOX_T_BOTTOM '\xCA'

// Special Characters
#define BOX_CROSS '\xCE'
#define BOX_HORIZONTAL_SINGLE_DOUBLE '\xD5'
#define BOX_HORIZONTAL_DOUBLE_SINGLE '\xD6'
#define BOX_VERTICAL_SINGLE_DOUBLE '\xB9'
#define BOX_VERTICAL_DOUBLE_SINGLE '\xBA'

// Cursor
#define CURSOR_CHARACTER '\xB1'