/* bridge gm2's mangled cstdio_puts to libc puts */
#include <stdio.h>
int cstdio_puts(const char *s) { return puts(s); }
