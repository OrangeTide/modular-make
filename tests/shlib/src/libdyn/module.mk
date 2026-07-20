SHARED_LIBS += dyn
dyn_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
dyn_SRCS  = dyn.c
dyn_LDFLAGS = -L/tmp/modular-make-lib-only
dyn_EXPORTED_CPPFLAGS = -I$(dyn_DIR)
