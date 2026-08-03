#include "blink.h"
#include "gpio.h"

void main(void)
{
gpio_init();

while (1)
{
    blink_once();
}

}
