# library: "greet_objcxx"
greet_objcxx_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_objcxx_SRCS = greet_objcxx.mm
greet_objcxx_EXPORTED_CPPFLAGS = -I$(greet_objcxx_DIR)
greet_objcxx_EXPORTED_LDLIBS = -lstdc++
LIBRARIES += greet_objcxx
