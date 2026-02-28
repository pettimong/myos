#include <stdint.h>
#include "isr.h"

/* I/O 出力関数（COM1） */
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

/* IDT エントリ構造 */
struct idt_entry {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t zero;
    uint8_t type_attr;
    uint16_t offset_high;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

struct idt_entry idt[256];
struct idt_ptr idtp;

/* ISR ハンドラ宣言 */
extern void isr3();

static void set_idt_gate(int n, uint32_t handler) {
    idt[n].offset_low  = handler & 0xFFFF;
    idt[n].selector    = 0x08;       // カーネルコードセグメント
    idt[n].zero        = 0;
    idt[n].type_attr   = 0x8E;       // 割り込みゲート
    idt[n].offset_high = (handler >> 16) & 0xFFFF;
}

/* IDT 初期化 */
void idt_init() {
    set_idt_gate(3, (uint32_t)isr3); // int3
    idtp.limit = sizeof(idt) - 1;
    idtp.base  = (uint32_t)&idt;
    __asm__ volatile("lidt %0" : : "m"(idtp));
}

/* ISR3 の実際の処理 */
void isr3_handler() {
    // VGA に表示
    volatile char* vga = (volatile char*)0xB8000;
    *vga = '3';
    *(vga+1) = 0x07; // 色属性

    // シリアル出力（デバッグ用）
    outb(0x3F8, '3'); // COM1

    __asm__ volatile("iret");
}

/* ISR3 エントリ（naked） */
__attribute__((naked)) void isr3() {
    __asm__ volatile(
        "cli;"            // 割り込み禁止
        "pushal;"         // 汎用レジスタ退避
        "call isr3_handler;"
        "popal;"          // レジスタ復帰
        "sti;"            // 割り込み許可
        "iret;"
    );
}
