# library: "greet_d"
greet_d_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_d_SRCS = greet_d.d
greet_d_DFLAGS = -fno-moduleinfo
greet_d_EXPORTED_CPPFLAGS = -I$(greet_d_DIR)
LIBRARIES += greet_d
