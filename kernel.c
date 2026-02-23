#include <stdint.h>

/* Multiboot ヘッダ */
__attribute__((section(".multiboot")))
const uint32_t multiboot_header[] = {
    0x1BADB002,
    0x0,
    -(0x1BADB002)
};

/* 行・列を管理する */
#define VGA_WIDTH  80
#define VGA_HEIGHT 25

volatile uint16_t* vga = (uint16_t*)0xB8000;

int cursor_row = 0;
int cursor_col = 0;
uint8_t current_color = 0x0F; // 白文字・黒背景

/* scroll関数を作る */
void scroll() {
    // 2行目以降を1行上へコピー
    for (int row = 1; row < VGA_HEIGHT; row++) {
        for (int col = 0; col < VGA_WIDTH; col++) {
            vga[(row - 1) * VGA_WIDTH + col] =
                vga[row * VGA_WIDTH + col];
        }
    }

    // 最終行を空白にする
    for (int col = 0; col < VGA_WIDTH; col++) {
        vga[(VGA_HEIGHT - 1) * VGA_WIDTH + col] =
            (current_color << 8) | ' ';
    }
	
	cursor_row = VGA_HEIGHT - 1;
    cursor_col = 0;   // ← これが重要
}

/* 1文字出力関数を作る */
void putchar(char c) {
    if (c == '\n') {
        cursor_row++;
        cursor_col = 0;
    } else {

		int index = cursor_row * VGA_WIDTH + cursor_col;
		vga[index] = (current_color << 8) | c;

		cursor_col++;

		if (cursor_col >= VGA_WIDTH) {
			cursor_col = 0;
			cursor_row++;
		}	
	}

	if (cursor_row >= VGA_HEIGHT) {
		scroll();
	}
}

/* 文字列出力関数 */
void print(const char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        putchar(str[i]);
    }
}

void kernel_main(void) {

    // 画面クリア
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga[i] = (current_color << 8) | ' ';
    }

	for (int i = 0; i < 30; i++) {
		print("Line ");
		putchar('0' + (i / 10));
		putchar('0' + (i % 10));
		print("\n");
	}
    while (1) {
        __asm__("hlt");
    }
}
