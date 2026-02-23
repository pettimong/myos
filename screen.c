#include "screen.h"

#define VGA_MEMORY 0xB8000
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

static uint16_t* const vga_buffer = (uint16_t*) VGA_MEMORY;

static size_t cursor_row = 0;
static size_t cursor_col = 0;
static uint8_t current_color;  // 修正済み

/* ===== ヘルパ関数 ===== */

static uint16_t make_vga_entry(char c, uint8_t color) {
    return (uint16_t)c | (uint16_t)color << 8;
}

static uint8_t make_color(uint8_t fg, uint8_t bg) {
    return fg | bg << 4;
}

static void clear_screen(void) {
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            size_t index = y * VGA_WIDTH + x;
            vga_buffer[index] = make_vga_entry(' ', current_color);
        }
    }
}

/* ===== 公開関数 ===== */

void screen_init(void) {
    cursor_row = 0;
    cursor_col = 0;
    set_color(15, 0);  // WHITE on BLACK
    clear_screen();
}

void set_color(uint8_t fg, uint8_t bg) {
    current_color = make_color(fg, bg);
}

void putc(char c) {
    if (c == '\n') {
        cursor_col = 0;
        cursor_row++;
        return;
    }

    size_t index = cursor_row * VGA_WIDTH + cursor_col;
    vga_buffer[index] = make_vga_entry(c, current_color);

    cursor_col++;
    if (cursor_col >= VGA_WIDTH) {
        cursor_col = 0;
        cursor_row++;
    }
}

void puts(const char* str) {
    for (size_t i = 0; str[i] != '\0'; i++) {
        putc(str[i]);
    }
}
