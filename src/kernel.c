#include <stdint.h>

/* COM1 シリアル出力 */
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

/* カーネル本体 */
void kernel_main() {
    // シリアル出力で動作確認
    outb(0x3F8, 'K');

    // VGA 左上にも表示（任意）
    volatile char* vga = (volatile char*)0xB8000;
    *vga = 'K';
    *(vga+1) = 0x07;

    while(1) {}  // 無限ループ
}
