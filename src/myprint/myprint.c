#include "myprint.h"
#include <stdio.h>

void
myprint(const char *msg)
{
    fputs(msg, stdout);
    fflush(stdout);
}

void
myprintln(const char *msg)
{
    fprintf(stdout, "%s\n", msg);
}
