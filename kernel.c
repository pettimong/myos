#include <stdint.h>

/* Multiboot ヘッダ */
__attribute__((section(".multiboot")))
const uint32_t multiboot_header[] = {
    0x1BADB002,
    0x0,
    -(0x1BADB002)
};

void kernel_main(void) {
    volatile uint16_t* vga = (uint16_t*)0xB8000;

    // 画面クリア
    for (int i = 0; i < 80*25; i++) {
        vga[i] = (0x0F << 8) | ' ';
    }

    const char* msg = "Hello, My OS";
    for (int i = 0; msg[i] != '\0'; i++) {
        vga[i] = (0x0F << 8) | msg[i];
    }

    while (1) {
        __asm__("hlt");
    }
}
