ROOT := $(dir $(lastword $(MAKEFILE_LIST)))

# gen: a library whose source AND header are produced by a code generator.
# gen.sh reads gen.in and writes gen.c + gen.h into the build tree. Declaring
# _GENERATED_HDRS makes modular-make (1) create the output dir, (2) order the
# generated header before every object that may include it (this target's own
# and any dependent's, transitively), (3) add its build dir to the include path
# for this target and its dependents, and (4) clean it. No manual -I or
# order-only prerequisites are needed in this or any consuming module.mk.
LIBRARIES += gen
gen_DIR := $(ROOT)
gen_GENERATED_SRCS = gen.c
gen_GENERATED_HDRS = gen.h

# One generator invocation writes both outputs. gen.h must carry its own recipe
# (not just "gen.h: gen.c" with none) so make re-stats it after the generator
# runs; otherwise a header-only change would not rebuild consumers. The generator
# already wrote gen.h, so its recipe just bumps the mtime. On GNU Make 4.3+ a
# grouped target ("gen.c gen.h &: ...") is the cleaner equivalent.
$(BUILDDIR)/$(gen_DIR)gen.c: $(gen_DIR)gen.in $(gen_DIR)gen.sh
	sh $(gen_DIR)gen.sh $(gen_DIR)gen.in $(BUILDDIR)/$(gen_DIR)
$(BUILDDIR)/$(gen_DIR)gen.h: $(BUILDDIR)/$(gen_DIR)gen.c ; @touch -c $@
