# library: "greet_c"
greet_c_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_c_SRCS = greet_c.c
greet_c_EXPORTED_CPPFLAGS = -I$(greet_c_DIR)
LIBRARIES += greet_c

# library: "minmax" -- arch-specific SIMD with portable C fallback
# On x86-64 and aarch64 the assembly implementation is used; on other
# architectures the plain-C fallback (minmax.c) is compiled instead.
minmax_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
minmax_SRCS            =
minmax_SRCS.x86_64     = arch/minmax_x86_64.S
minmax_SRCS.aarch64    = arch/minmax_aarch64.S
minmax_EXPORTED_CPPFLAGS = -I$(minmax_DIR)
LIBRARIES += minmax
# Fallback: if no arch-specific source was selected, use the C version.
minmax_SRCS += $(if $(strip $(minmax_SRCS.$(_TARGET_ARCH))),, minmax.c)
