# project: "myprint"
myprint_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
myprint_SRCS = myprint.c
LIBRARIES += myprint
