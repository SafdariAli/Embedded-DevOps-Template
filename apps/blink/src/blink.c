//test
#include "blink.h"
#include "gpio.h"
#include "delay.h"

void blink_once(void)
{
    led_on();
    delay_ms(100);

    led_off();
    delay_ms(100);
}