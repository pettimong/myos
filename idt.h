#ifndef IDT_H
#define IDT_H

#include <stdint.h>

#define IDT_SIZE 256

// IDTエントリ構造
struct idt_entry {
    uint16_t base_lo;
    uint16_t sel;
    uint8_t  always0;
    uint8_t  flags;
    uint16_t base_hi;
} __attribute__((packed));

// IDTポインタ構造
struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

extern void idt_flush(uint32_t);

void idt_init();
void isr3();

#endif
