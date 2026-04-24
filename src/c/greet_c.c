#include <stdio.h>
#include "config.h"

#ifndef CONFIG_GREETING_STR
#define CONFIG_GREETING_STR "Hello"
#endif

void
greet_c(void)
{
    printf("%s from C!\n", CONFIG_GREETING_STR);
}
