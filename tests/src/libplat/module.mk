# library: "plat" -- exercises platform-specific variable suffixes
LIBRARIES += plat
plat_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
plat_SRCS  = plat.c
plat_SRCS.x86_64  = plat_x86_64.c
plat_SRCS.aarch64 = plat_aarch64.c
plat_CPPFLAGS.Linux      = -DPLAT_OS_NAME='"Linux"'
plat_CPPFLAGS.Darwin     = -DPLAT_OS_NAME='"Darwin"'
plat_CPPFLAGS.Windows_NT = -DPLAT_OS_NAME='"Windows_NT"'
plat_EXPORTED_CPPFLAGS = -I$(plat_DIR)
