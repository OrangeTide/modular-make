#include <stdio.h>
#include "foo.h"
#include "baz.h"

int main(void)
{
	printf("app: foo_val=%d baz_val=%d\n", foo_val(), baz_val());
	return 0;
}
