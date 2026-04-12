/* Common platform code -- always compiled. */
#include "plat.h"

const char *
plat_os_name(void)
{
#ifdef PLAT_OS_NAME
	return PLAT_OS_NAME;
#else
	return "unknown";
#endif
}
