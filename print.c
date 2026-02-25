#include <stdarg.h>
#include "print.h"
#include "screen.h"
#include "itoa.h"

void itoa(int value, char* buffer);  // さきほどの関数

void mini_printf(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);

    while (*fmt) {
        if (*fmt == '%') {
            fmt++;

            if (*fmt == 'd') {
                int value = va_arg(args, int);

                char buf[12];
                itoa(value, buf);

                char* p = buf;
                while (*p) {
                    putc(*p++);
                }
            }
        } else {
            putc(*fmt);
        }

        fmt++;
    }

    va_end(args);
}
