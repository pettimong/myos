#include "itoa.h"

void itoa(int n, char *buf)
{
    int i = 0;
    int temp = n;

    // 桁数を数える
    while (temp > 0)
    {
        temp /= 10;
        i++;
    }

    buf[i] = '\0';

    // 後ろから埋める
    while (i > 0)
    {
        buf[--i] = (n % 10) + '0';
        n /= 10;
    }
}
