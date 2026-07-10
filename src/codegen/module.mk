# src/codegen/module.mk -- demonstrates _GENERATED_SRCS and _GENERATED_HDRS
#
# version_info.c and version_info.h are generated into BUILDDIR at build time
# from version.txt.  main.c includes the generated header; the build system
# puts its build directory on the include path and orders it ahead of main.o
# automatically, so no -I or order-only prerequisite is written by hand.

EXECUTABLES += codegen_demo
codegen_demo_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
codegen_demo_SRCS = main.c
codegen_demo_GENERATED_SRCS = version_info.c
codegen_demo_GENERATED_HDRS = version_info.h

define codegen_demo_TESTCMD
$(codegen_demo_RUN)
endef
TEST_TARGETS += codegen_demo

# Rules to generate version_info.c and version_info.h from version.txt.  The
# generated files land in BUILDDIR under the same relative path as the module
# directory, so _GENERATED_SRCS / _GENERATED_HDRS find them automatically.
# Each output has its own recipe (make re-stats what it builds), so a change to
# version.txt rebuilds both and, through the header, main.o.
$(BUILDDIR)/$(codegen_demo_DIR)version_info.c : $(codegen_demo_DIR)version.txt
	printf '/* generated -- do not edit */\n#include "version_info.h"\nconst char *version_info = "%s";\n' \
		"$$(cat $<)" > $@
$(BUILDDIR)/$(codegen_demo_DIR)version_info.h : $(codegen_demo_DIR)version.txt
	printf '/* generated -- do not edit */\nextern const char *version_info;\n' > $@
