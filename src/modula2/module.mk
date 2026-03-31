# library: "greet_m2"
greet_m2_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_m2_SRCS = m2greet.mod cstdio_wrap.c
greet_m2_GM2FLAGS = -I$(greet_m2_DIR)
greet_m2_EXPORTED_CPPFLAGS = -I$(greet_m2_DIR)
greet_m2_EXPORTED_LDLIBS = -lm2pim -lm2iso -lstdc++ -lm -lpthread
LIBRARIES += greet_m2
