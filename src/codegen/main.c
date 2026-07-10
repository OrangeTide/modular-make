#include <stdio.h>
#include "version_info.h"	/* generated into _build, found via automatic -I */

int main(void)
{
	printf("version: %s\n", version_info);
	return 0;
}
