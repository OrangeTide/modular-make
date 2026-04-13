#include <stdio.h>

extern const char *version_info;

int main(void)
{
	printf("version: %s\n", version_info);
	return 0;
}
