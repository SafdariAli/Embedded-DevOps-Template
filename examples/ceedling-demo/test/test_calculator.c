#include "unity.h"
#include "calculator.h"

void setUp(void)
{
}

void tearDown(void)
{
}

void test_add_should_return_sum(void)
{
    TEST_ASSERT_EQUAL(5, add(2, 3));
}