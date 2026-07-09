#include "baz.h"

extern "C" {
#include "bar.h"
}

/* Calls into bar so the diamond dependency is exercised at link time: both
 * foo and baz pull symbols from the shared bar archive. 41 + 58 == 99. */
extern "C" int baz_val(void)
{
	return bar_val() + 58;
}
