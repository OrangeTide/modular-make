#include <greet_c.h>
#include <greet_objc.h>
#include <greet_objcxx.h>
#ifdef HAVE_PASCAL
#include <greet_pascal.h>
#endif
#include <greet_m2.h>

int
main(void)
{
    greet_c();
    greet_objc();
    greet_objcxx();
#ifdef HAVE_PASCAL
    greet_pascal();
#endif
    greet_m2();
    return 0;
}
