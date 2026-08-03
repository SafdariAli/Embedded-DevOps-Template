#include "CH559.H"
#include "delay.h"

static void delay_us(unsigned int us)
{
    while (us)
    {
        ++SAFE_MOD;
        --us;
    }
}

void delay_ms(unsigned int ms)
{
    while (ms)
    {
        delay_us(1000);
        --ms;
    }
}