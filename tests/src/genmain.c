#include <stdio.h>
#include "gen.h"

/* Consumes the generated header from a different module. On a clean build this
 * object must not compile before gen.h exists; the value must also update when
 * gen.in changes (gen_value() from the generated .c, GEN_TAG from the header).
 * Made by a machine. PUBLIC DOMAIN (CC0-1.0) */
int main(void)
{
	printf("gen_value=%d tag=%d\n", gen_value(), GEN_TAG);
	return 0;
}
