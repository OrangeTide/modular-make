ROOT := $(dir $(lastword $(MAKEFILE_LIST)))
SUBDIRS = libfoo libbar libbaz libplat

# app: C executable, depends on foo (transitive -> bar), and baz (C++ lib).
# Tests: transitive _LIBS, EXPORTED_CPPFLAGS, CXX_MODE auto-detection.
EXECUTABLES += app
app_DIR  := $(ROOT)
app_SRCS  = main.c
app_SRCS.CONFIG_EXTRA = extra.c
app_LIBS  = foo baz
define app_TESTCMD
$(app_RUN)
$(app_RUN) | grep -q "foo_val=42"
$(app_RUN) | grep -q "baz_val=99"
endef
TEST_TARGETS += app

# cxxapp: C++ executable, depends on foo only.
# Tests: direct C++ source, transitive _LIBS.
EXECUTABLES += cxxapp
cxxapp_DIR  := $(ROOT)
cxxapp_SRCS  = cxxmain.cpp
cxxapp_LIBS  = foo
define cxxapp_TESTCMD
$(cxxapp_RUN)
$(cxxapp_RUN) | grep -q "foo_val=42"
endef
TEST_TARGETS += cxxapp

# platapp: C executable, depends on plat.
# Tests: platform-specific _SRCS.<arch> and _CPPFLAGS.<os> suffixes.
EXECUTABLES += platapp
platapp_DIR  := $(ROOT)
platapp_SRCS  = platmain.c
platapp_LIBS  = plat
define platapp_TESTCMD
$(platapp_RUN)
$(platapp_RUN) | grep -q "plat_has_arch=1"
endef
TEST_TARGETS += platapp

# pkgapp: C executable linked against the math library via _PKGS.
# Tests: _PKGS resolution through the built-in KNOWN_PKGS table (no
# pkg-config needed) and that the resulting -lm reaches the link line.
EXECUTABLES += pkgapp
pkgapp_DIR  := $(ROOT)
pkgapp_SRCS  = pkgmain.c
pkgapp_PKGS  = m
define pkgapp_TESTCMD
$(pkgapp_RUN)
$(pkgapp_RUN) | grep -q "pkg_sqrt=3"
endef
TEST_TARGETS += pkgapp
