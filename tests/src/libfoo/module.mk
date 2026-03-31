LIBRARIES += foo
foo_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
foo_SRCS  = foo.c
foo_LIBS  = bar
foo_EXPORTED_CPPFLAGS = -I$(foo_DIR)
