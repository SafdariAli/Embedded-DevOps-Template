#include "unity.h"
#include "mock_gpio.h"
#include "mock_delay.h"
#include "blink.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_blink_once_should_turn_led_on_wait_and_turn_led_off(void)
{
    led_on_Expect();
    delay_ms_Expect(100);
    led_off_Expect();
    delay_ms_Expect(100);

    blink_once();
}