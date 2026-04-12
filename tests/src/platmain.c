#include <stdio.h>
#include "plat.h"

int
main(void)
{
	printf("plat_has_arch=%d\n", plat_has_arch());
	printf("plat_os_name=%s\n", plat_os_name());
	return 0;
}
