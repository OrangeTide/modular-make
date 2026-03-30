# GNUmakefile -- Modular top-level build file [v1.0.1]
# Requires GNU Make (tested with 4.x).
#
# ============================================================================
# OVERVIEW
# ============================================================================
#
# This build system compiles C projects, static libraries, and shared
# libraries from a tree of module.mk descriptor files.  Each module.mk
# declares one or more build targets and their sources, flags, and
# dependencies.  The top-level GNUmakefile provides the rules; the
# module.mk files provide the data.
#
# ============================================================================
# DIRECTORY LAYOUT
# ============================================================================
#
# Source tree (input):
#
#   src/
#     module.mk              <-- declares your central project
#     yourprog.c
#     lib/
#       module.mk            <-- declares a library used by yourprog
#       util.c
#
# Build tree (output, per target triplet):
#
#   _build/<triplet>/        object files (.o) and dependency files (.d)
#   _out/<triplet>/bin/      executable binaries
#   _out/<triplet>/lib/      shared libraries (.so / .dylib / .dll)
#
# Static archives (.a) are placed under _build/<triplet>/ alongside the
# objects, since they are intermediate build artifacts rather than
# installable outputs.
#
# The triplet (e.g. x86_64-linux-gnu) is obtained from $(CC) -dumpmachine
# so that cross-compiled artifacts do not clobber native ones.
#
# ============================================================================
# MODULE.MK FILES
# ============================================================================
#
# A module.mk file declares build targets by appending to one of three
# lists and setting per-target variables.  The general pattern is:
#
#   EXECUTABLES += mytool           # executable binary
#   LIBRARIES   += mystaticlib      # static archive (.a)
#   SHARED_LIBS += mysharedlib      # shared library (.so/.dylib/.dll)
#
# Every target must define at minimum:
#
#   <name>_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
#   <name>_SRCS  = file1.c file2.c
#
# The _DIR line is boilerplate -- it captures the directory containing the
# module.mk so that source paths resolve correctly regardless of where
# the file is included from.  Source file names in _SRCS are relative to
# _DIR (the build system prepends _DIR automatically).
#
# Optional per-target variables:
#
#   <name>_CFLAGS    Extra compiler flags (e.g. -Wall -O2)
#   <name>_CPPFLAGS  Preprocessor flags (e.g. -I paths, -D defines)
#   <name>_LDFLAGS   Linker flags        (projects only)
#   <name>_LDLIBS    Link libraries       (projects only, e.g. -lm)
#   <name>_LIBS      Names of library targets this target depends on.
#                     Works for both static and shared libraries --
#                     the build system resolves each name to its .a or
#                     .so output automatically.  (projects only)
#   <name>_SUBDIRS   Subdirectories (relative to _DIR) whose module.mk
#                     files should be included.  This drives the
#                     recursive module discovery described below.
#
# Example -- an executable that depends on a static library:
#
#   # src/module.mk
#   EXECUTABLES += hello
#   hello_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
#   hello_SRCS  = hello.c
#   hello_LIBS  = myutil
#   hello_CPPFLAGS  = -I$(myutil_DIR)
#   hello_SUBDIRS   = lib
#
#   # src/lib/module.mk
#   LIBRARIES += myutil
#   myutil_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
#   myutil_SRCS  = myutil.c
#
# Example -- a shared library:
#
#   SHARED_LIBS += myplugin
#   myplugin_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
#   myplugin_SRCS  = plugin.c hooks.c
#   myplugin_CFLAGS = -Wall
#
# Objects for shared libraries are compiled with -fPIC automatically.
#
# ============================================================================
# RECURSIVE MODULE DISCOVERY
# ============================================================================
#
# Module.mk files are discovered by a recursive loader seeded from
# src/module.mk.  After each round of includes:
#
#   1. Every target in EXECUTABLES, LIBRARIES, and SHARED_LIBS is scanned
#      for a _SUBDIRS variable.
#   2. For each subdirectory d listed in <name>_SUBDIRS, the file
#      $(<name>_DIR)/d/module.mk is queued for inclusion (if not
#      already loaded).
#   3. If new files were queued, the loader runs another pass.
#   4. The process repeats until no new module.mk files are found.
#
# This means the tree of module.mk files is driven entirely by _SUBDIRS
# declarations -- there is no filesystem scanning or globbing.
#
# ============================================================================
# DEPENDENCY TRACKING
# ============================================================================
#
# The compile command emits GCC-style dependency files (.d) via -MMD.
# These are included at the bottom of this makefile so that changes to
# headers trigger recompilation of the affected objects.  On a clean
# build the .d files do not yet exist; the -include directive silently
# ignores the missing files.
#
# Library dependencies declared via _LIBS are expressed as makefile
# prerequisites: the library archive or shared object is listed as a
# prerequisite of the executable link step.  This means Make will build
# (or rebuild) any required libraries before linking the project.  The
# library files are passed to the linker through $^ (the prerequisite
# list), so no manual -l flags are needed for internal libraries.
#
# ============================================================================
# MAKE TARGETS
# ============================================================================
#
#   make              Build all projects (default).
#   make <name>       Build a single project or library by target name.
#   make clean        Remove all generated objects, dependency files,
#                     archives, shared libraries, and binaries.
#   make clean_<name> Remove generated files for a single target.
#   make clean-all    Like clean, then also remove empty build/output
#                     directories (deepest first).
#
# ============================================================================
# CUSTOMIZATION
# ============================================================================
#
# The following variables can be overridden on the command line or in
# the environment:
#
#   CC          C compiler                         (default: cc)
#   AR          Archiver                           (default: ar)
#   ARFLAGS     Archiver flags                     (default: rvD)
#   MKDIR_P     Directory creation command          (default: mkdir -p)
#   RMDIR       Directory removal command           (default: rmdir)
#
# Per-target CFLAGS, CPPFLAGS, LDFLAGS, and LDLIBS are set via
# target-specific variables and do not inherit the global values.
# This is intentional -- it keeps each target's flags self-contained
# and avoids surprising flag leakage between unrelated targets.
#
# ============================================================================

# Host Commands
MKDIR_P ?= mkdir -p
RMDIR   ?= rmdir
ARFLAGS  = rvD

# Command Macros
link.c    = $(CC) -o $@ $(LDFLAGS) $(if $(LIBDIR),-L$(LIBDIR)) $^ $(LDLIBS)
link.a    = $(RM) $@ && $(AR) $(ARFLAGS) $@ $^
link.so   = $(CC) -shared -o $@ $(LDFLAGS) $^ $(LDLIBS)
compile.c = $(CC) -c -o $@ $< -MMD $(CFLAGS) $(CPPFLAGS)

# Utility Macros
# explode_dirs: explode a path list into every intermediate directory.
# Recursion depth is bounded by the deepest path (~5-10 levels).
explode_dirs = $(sort $(filter-out .,$(if $1,$(call explode_dirs,$(filter-out $1,$(patsubst %/,%,$(dir $1))))) $(patsubst %/,%,$1)))

# --- Directories ------------------------------------------------------------
# Object files go under _build/<triplet>/ so cross-compiles don't clobber
# each other.  Binaries and libraries go under _out/<triplet>/bin and
# _out/<triplet>/lib respectively.

TARGET_TRIPLET := $(shell $(CC) -dumpmachine 2>/dev/null)
ifdef TARGET_TRIPLET
  BUILDDIR := _build/$(TARGET_TRIPLET)
  OUTDIR := _out/$(TARGET_TRIPLET)
else
  BUILDDIR := _build
  OUTDIR := _out
endif
# for executables
BINDIR = $(OUTDIR)/bin
# for shared libraries
LIBDIR = $(OUTDIR)/lib

# Shared library extension (platform-dependent)
ifneq ($(findstring darwin,$(TARGET_TRIPLET)),)
  SO_EXT := .dylib
else ifneq ($(findstring mingw,$(TARGET_TRIPLET)),)
  SO_EXT := .dll
else ifneq ($(findstring cygwin,$(TARGET_TRIPLET)),)
  SO_EXT := .dll
else
  SO_EXT := .so
endif

# Delete built-in implicit rules -- they conflict with the out-of-tree
# build layout (objects go to BUILDDIR, not alongside sources).
% : %.o
% : %.c
%.o : %.c

### Module Loader ###

# Recursive module.mk discovery.  Seed with top-level module files;
# after each round of includes, scan every target's $(p)_SUBDIRS for
# new module.mk files (resolved relative to $(p)_DIR).  Repeat until
# no new files remain.
.DEFAULT_GOAL := all

_module_files   := src/module.mk
_modules_loaded :=

define _load_modules
$(foreach f,$(filter-out $(_modules_loaded),$(_module_files)),\
  $(eval _modules_loaded += $f)\
  $(eval include $f))
$(foreach p,$(EXECUTABLES) $(LIBRARIES) $(SHARED_LIBS),\
  $(foreach d,$($p_SUBDIRS),\
    $(if $(filter $($p_DIR)$d/module.mk,$(_modules_loaded)),,\
      $(eval _module_files += $($p_DIR)$d/module.mk))))
$(if $(filter-out $(_modules_loaded),$(_module_files)),\
  $(eval $(value _load_modules)))
endef

$(eval $(value _load_modules))

### Rules ###

get_objs     = $(patsubst %.c,$(BUILDDIR)/%.o,$(addprefix $($1_DIR),$($1_SRCS)))
get_lib      = $(BUILDDIR)/$1.a
get_so       = $(LIBDIR)/lib$1$(SO_EXT)
get_lib_file = $(if $(filter $1,$(LIBRARIES)),$(call get_lib,$1),$(call get_so,$1))

# _all_dirs: every directory that contains a build artifact (used by clean-all)
_all_dirs = $(sort $(dir \
  $(foreach p,$(EXECUTABLES),$(BINDIR)/$p $(call get_objs,$p)) \
  $(foreach l,$(LIBRARIES),$(call get_lib,$l) $(call get_objs,$l)) \
  $(foreach s,$(SHARED_LIBS),$(call get_so,$s) $(call get_objs,$s))))

.SECONDEXPANSION:
all :: $$(EXECUTABLES)
clean : $$(addprefix clean_,$$(EXECUTABLES) $$(LIBRARIES) $$(SHARED_LIBS))
clean-all : clean
	-printf '%s\n' $(call explode_dirs,$(_all_dirs)) | sort -r | while read -r d; do $(RMDIR) "$$d" 2>/dev/null; done; true
.PHONY : all clean clean-all clean_% $(EXECUTABLES) $(LIBRARIES) $(SHARED_LIBS)

# Create directories
%/ : ; $(MKDIR_P) $@
.PRECIOUS : %/

# Per-library rules: compile objects and pack into a static archive.
define library_rules
$1 : $(call get_lib,$1)
$(call get_lib,$1) : $$(call get_objs,$1) | $$(@D)/
	$$(link.a)
$(call get_objs,$1) : CFLAGS=$$($1_CFLAGS)
$(call get_objs,$1) : CPPFLAGS=$$($1_CPPFLAGS)
clean_$1 :
	$$(RM) $$(call get_objs,$1) $$(patsubst %.o,%.d,$$(call get_objs,$1))
	$$(RM) $(call get_lib,$1)
endef
$(foreach l,$(LIBRARIES),$(eval $(call library_rules,$l)))

# Per-shared-library rules: compile with -fPIC, link with -shared.
define shared_library_rules
$1 : $(call get_so,$1)
$(call get_so,$1) : $$(call get_objs,$1) | $$(@D)/
	$$(link.so)
$(call get_objs,$1) : CFLAGS=-fPIC $$($1_CFLAGS)
$(call get_objs,$1) : CPPFLAGS=$$($1_CPPFLAGS)
clean_$1 :
	$$(RM) $$(call get_objs,$1) $$(patsubst %.o,%.d,$$(call get_objs,$1))
	$$(RM) $(call get_so,$1)
endef
$(foreach s,$(SHARED_LIBS),$(eval $(call shared_library_rules,$s)))

# Per-project rules: compile objects and link with libraries from LIBS.
# The compile rule is per-project so that CFLAGS/CPPFLAGS are set correctly
# for each object — target-specific variables on the link target do not
# reliably propagate to prerequisite pattern rules in GNU Make.
define project_rules
$1 : $(BINDIR)/$1
$(BINDIR)/$1 : $$(call get_objs,$1) $(foreach d,$($1_LIBS),$(call get_lib_file,$d)) | $(BINDIR)/
	$$(link.c)
$(BINDIR)/$1 : LDFLAGS=$$($1_LDFLAGS)
$(BINDIR)/$1 : LDLIBS=$$($1_LDLIBS)
$(call get_objs,$1) : CFLAGS=$$($1_CFLAGS)
$(call get_objs,$1) : CPPFLAGS=$$($1_CPPFLAGS)
clean_$1 :
	$$(RM) $$(call get_objs,$1) $$(patsubst %.o,%.d,$$(call get_objs,$1))
	$$(RM) $(BINDIR)/$1
endef
$(foreach p,$(EXECUTABLES),$(eval $(call project_rules,$p)))

# Compile (fallback pattern rule — project_rules above sets flags via
# target-specific variables on the individual .o files)
$(BUILDDIR)/%.o : %.c | $$(@D)/ ; $(compile.c)

# Pull in generated dependency files (silent on first build)
-include $(patsubst %.o,%.d,$(foreach p,$(EXECUTABLES) $(LIBRARIES) $(SHARED_LIBS),$(call get_objs,$p)))

##### END #####
