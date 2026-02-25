#include "screen.h"
#include <stdint.h>
#include "print.h"

/* Multiboot header */
__attribute__((section(".multiboot")))
const uint32_t multiboot_header[] = {
    0x1BADB002,        // magic
    0x00,              // flags
    -(0x1BADB002)      // checksum
};

void kernel_main(void) {

		screen_init();
		mini_printf("value=%d\n", 42);
		
		while (1) {
			__asm__("hlt");
		}
}
