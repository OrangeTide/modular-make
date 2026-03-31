ROOT := $(dir $(lastword $(MAKEFILE_LIST)))
SUBDIRS = c cpp d fortran objc objcxx pascal modula2

# executable: "hello" -- demonstrates C, C++, D, and Fortran
EXECUTABLES += hello
hello_DIR := $(ROOT)
hello_SRCS = hello.c
hello_LIBS = greet_c greet_cpp greet_d greet_fortran
define hello_TESTCMD
$(hello_EXEC)
endef
TEST_TARGETS += hello

# executable: "world" -- demonstrates Objective-C, Objective-C++, Pascal, and Modula-2
EXECUTABLES += world
world_DIR := $(ROOT)
world_SRCS = world.c
world_LIBS = greet_c greet_objc greet_objcxx greet_pascal greet_m2
define world_TESTCMD
$(world_EXEC)
endef
TEST_TARGETS += world
