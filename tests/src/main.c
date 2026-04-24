#include <stdio.h>
#include "foo.h"
#include "baz.h"

#ifdef CONFIG_EXTRA
void extra_info(void);
#endif

int main(void)
{
	printf("app: foo_val=%d baz_val=%d\n", foo_val(), baz_val());
#ifdef CONFIG_EXTRA
	extra_info();
#endif
	return 0;
}
