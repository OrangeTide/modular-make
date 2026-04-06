#include <cstdio>
#include <greet_c.h>

extern "C" void
greet_cpp(void)
{
    greet_c();
    std::puts("Hello from C++!");
}
