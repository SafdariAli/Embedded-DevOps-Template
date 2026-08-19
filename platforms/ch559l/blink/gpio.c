#include "CH559.h"
#include "gpio.h"

#define LED_MASK 0x10

void gpio_init(void)
{
    SAFE_MOD = 0x55;
    SAFE_MOD = 0xAA;

    PORT_CFG |= bP1_DRV;
    PORT_CFG &= ~bP1_OC;

    SAFE_MOD = 0x00;

    P1_DIR |= 0xF0;
    P1_PU  |= 0xF0;

    /* All LEDs OFF */
    P1 &= ~0xF0;
}

void led_on(void)
{
    P1 |= LED_MASK;
}

void led_off(void)
{
    P1 &= ~LED_MASK;
}