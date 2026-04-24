#include <stdio.h>
#include "config.h"

void
extra_info(void)
{
	printf("extra: label=%s\n", CONFIG_EXTRA_LABEL);
}
