#include "screen.h"
#include <stdint.h>

/* Multiboot header */
__attribute__((section(".multiboot")))
const uint32_t multiboot_header[] = {
    0x1BADB002,        // magic
    0x00,              // flags
    -(0x1BADB002)      // checksum
};

void kernel_main(void) {

	screen_init();

	puts("Default white\n");

	set_color(COLOR_RED, COLOR_BLACK);
	puts("Red text\n");

	set_color(COLOR_GREEN, COLOR_BLACK);
	puts("Green text\n");

    while (1);
}
