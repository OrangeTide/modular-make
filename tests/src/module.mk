ROOT := $(dir $(lastword $(MAKEFILE_LIST)))
SUBDIRS = libfoo libbar libbaz

# app: C executable, depends on foo (transitive -> bar), and baz (C++ lib).
# Tests: transitive _LIBS, EXPORTED_CPPFLAGS, CXX_MODE auto-detection.
EXECUTABLES += app
app_DIR  := $(ROOT)
app_SRCS  = main.c
app_LIBS  = foo baz
define app_TESTCMD
$(app_EXEC)
$(app_EXEC) | grep -q "foo_val=42"
$(app_EXEC) | grep -q "baz_val=99"
endef
TEST_TARGETS += app

# cxxapp: C++ executable, depends on foo only.
# Tests: direct C++ source, transitive _LIBS.
EXECUTABLES += cxxapp
cxxapp_DIR  := $(ROOT)
cxxapp_SRCS  = cxxmain.cpp
cxxapp_LIBS  = foo
define cxxapp_TESTCMD
$(cxxapp_EXEC)
$(cxxapp_EXEC) | grep -q "foo_val=42"
endef
TEST_TARGETS += cxxapp
