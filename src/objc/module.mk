# library: "greet_objc"
greet_objc_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_objc_SRCS = greet_objc.m
greet_objc_EXPORTED_CPPFLAGS = -I$(greet_objc_DIR)
greet_objc_EXPORTED_LDLIBS = -lobjc
LIBRARIES += greet_objc
