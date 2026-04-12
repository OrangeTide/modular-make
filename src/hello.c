#include <stdio.h>
#include <greet_c.h>
#include <greet_cpp.h>
#include <greet_d.h>
#include <greet_fortran.h>
#include <minmax.h>

int
main(void)
{
    float v[4] = {3.0f, 1.0f, 4.0f, 1.5f};
    float result[2];

    greet_c();
    greet_cpp();
    greet_d();
    greet_fortran();

    minmax_f32x4(v, result);
    printf("minmax({3, 1, 4, 1.5}) = min:%.1f max:%.1f\n",
           result[0], result[1]);
    return 0;
}
