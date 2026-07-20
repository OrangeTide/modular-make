# Sub-project exercising shared libraries and per-target flag isolation.
#
# A per-target LDFLAGS must not follow the link into a shared library the
# target depends on. Target-specific variables are inherited by prerequisites,
# so "LDFLAGS += ..." on dynapp would append dynapp's private flags to
# libdyn.so's own link line, and libdyn.so's contents would then depend on
# whether the build was entered through "make dyn" or "make dynapp".
ROOT := $(dir $(lastword $(MAKEFILE_LIST)))
SUBDIRS = libdyn

EXECUTABLES += dynapp
dynapp_DIR  := $(ROOT)
dynapp_SRCS  = dynmain.c
dynapp_LIBS  = dyn
dynapp_LDFLAGS = -L/tmp/modular-make-exe-only
