LIBRARIES += baz
baz_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
baz_SRCS  = baz.cpp
baz_EXPORTED_CPPFLAGS = -I$(baz_DIR)
