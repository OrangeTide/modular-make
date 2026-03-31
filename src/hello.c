#include <greet_c.h>
#include <greet_cpp.h>
#include <greet_d.h>
#include <greet_fortran.h>

int
main(void)
{
    greet_c();
    greet_cpp();
    greet_d();
    greet_fortran();
    return 0;
}
