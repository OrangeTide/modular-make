#include "foo.h"
#include "bar.h"

int foo_val(void)
{
	return bar_val() + 1;
}
