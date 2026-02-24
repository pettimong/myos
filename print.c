#include "print.h"
#include "screen.h"

void mini_printf(const char* fmt)
{
    while (*fmt) {
        putc(*fmt);
        fmt++;
    }
}
