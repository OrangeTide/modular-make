# library: "greet_c"
greet_c_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_c_SRCS = greet_c.c
greet_c_EXPORTED_CPPFLAGS = -I$(greet_c_DIR)
LIBRARIES += greet_c
