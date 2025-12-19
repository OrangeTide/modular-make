ROOT := $(dir $(lastword $(MAKEFILE_LIST)))
# project: "hello"
hello_DIR := $(ROOT)
hello_SRCS = hello.c
hello_LIBS = myprint
hello_CPPFLAGS = -I"$(myprint_DIR)"
hello_SUBDIRS = myprint
EXECUTABLES += hello
# project: "world"
world_DIR := $(ROOT)
world_SRCS = world.c
world_LIBS = myprint
world_CPPFLAGS = -I"$(myprint_DIR)"
EXECUTABLES += world
