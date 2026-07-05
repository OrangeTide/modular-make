/* Made by a machine. PUBLIC DOMAIN (CC0-1.0) */
#include <math.h>
#include <stdio.h>

/* Uses argc so the call is not constant-folded away, forcing a real
 * reference to libm.  Exercises the _PKGS = m path (built-in table). */
int main(int argc, char **argv)
{
    (void)argv;
    double x = sqrt((double)(argc + 8));    /* argc==1 -> sqrt(9) == 3 */
    printf("pkg_sqrt=%d\n", (int)x);
    return 0;
}
