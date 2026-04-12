#ifndef PLAT_H
#define PLAT_H
/* Returns 1 if an arch-specific source was linked, 0 otherwise. */
int plat_has_arch(void);
/* Returns a string set via _CPPFLAGS.<os> (e.g. "Linux"). */
const char *plat_os_name(void);
#endif
