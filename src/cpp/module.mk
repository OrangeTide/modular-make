# library: "greet_cpp"
greet_cpp_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_cpp_SRCS = greet_cpp.cpp
greet_cpp_EXPORTED_CPPFLAGS = -I$(greet_cpp_DIR)
greet_cpp_EXPORTED_LDLIBS = -lstdc++
LIBRARIES += greet_cpp
