LIBRARIES += bar
bar_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
bar_SRCS  = bar.c
bar_EXPORTED_CPPFLAGS = -I$(bar_DIR)
