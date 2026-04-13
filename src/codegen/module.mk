# src/codegen/module.mk -- demonstrates _GENERATED_SRCS
#
# version_info.c is generated into BUILDDIR at build time from
# version.txt, then compiled and linked like any other source file.

EXECUTABLES += codegen_demo
codegen_demo_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
codegen_demo_SRCS = main.c
codegen_demo_GENERATED_SRCS = version_info.c

define codegen_demo_TESTCMD
$(codegen_demo_EXEC)
endef
TEST_TARGETS += codegen_demo

# Rule to generate version_info.c from version.txt.
# The generated file lands in BUILDDIR under the same relative path as
# the module directory, so _GENERATED_SRCS finds it automatically.
$(BUILDDIR)/$(codegen_demo_DIR)version_info.c : $(codegen_demo_DIR)version.txt
	printf '/* generated -- do not edit */\nconst char *version_info = "%s";\n' \
		"$$(cat $<)" > $@
