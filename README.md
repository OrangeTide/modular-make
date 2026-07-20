# modular-make

A modular GNUmakefile for C, C++, D, Fortran, Objective-C, Objective-C++, Pascal, Modula-2, and Assembly projects.

A single-file, drop-in build system for mixed-language projects. Supports multiple executables, static libraries, and shared libraries through a tree of lightweight `module.mk` descriptor files.

No configuration generators, no external dependencies -- just GNU Make.

## Supported Languages

| Extension | Language | Compiler | Dep tracking |
|-----------|----------|----------|--------------|
| `.c` | C | `$(CC)` | yes |
| `.cc` `.cpp` | C++ | `$(CXX)` | yes |
| `.d` | D | `$(GDC)` | yes |
| `.m` | Objective-C | `$(CC)` | yes |
| `.mm` | Objective-C++ | `$(CXX)` | yes |
| `.f` `.f90` | Fortran | `$(FC)` | yes |
| `.S` | Assembly (preprocessed) | `$(CC)` | yes |
| `.asm` | Assembly (NASM) | `$(NASM)` | -- |
| `.pas` | Pascal | `$(FPC)` | -- |
| `.mod` | Modula-2 | `$(GM2)` | yes |

All languages produce standard `.o` files and can be freely mixed within a single target.

## Quick Start

1. Copy `GNUmakefile` into your project root.
2. Create `src/module.mk` to declare your targets.
3. Run `make`.

If you prefer a top-level `module.mk` instead of `src/module.mk`, the build system will use it automatically. In that case you are responsible for listing subdirectories in `SUBDIRS` (e.g. `SUBDIRS = src`).

### Minimal Example

```
project/
  GNUmakefile
  src/
    module.mk
    main.c
```

```makefile
# src/module.mk
EXECUTABLES += myapp
myapp_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
myapp_SRCS   = main.c
```

```sh
make        # builds _out/<triplet>/bin/myapp
```

## Module Files

Each `module.mk` declares build targets by appending to one of three lists:

| List | Output |
|------|--------|
| `EXECUTABLES` | Binary in `_out/<triplet>/bin/` |
| `LIBRARIES` | Static archive (`.a`) in `_build/<triplet>/` |
| `SHARED_LIBS` | Shared library (`.so`/`.dylib`/`.dll`) in `_out/<triplet>/lib/` |

Every target needs at minimum:

```makefile
<name>_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
<name>_SRCS  = file1.c file2.c
```

Source paths in `_SRCS` are relative to `_DIR`. Wildcards are supported (e.g. `*.c`). Sources may use any supported extension and can be mixed:

```makefile
myapp_SRCS = main.c accel.S utils.cpp
```

> **Always reference `<name>_DIR`, never a shared variable, in any value that
> expands lazily** (exported flags, generation recipes). A common convention is
> `ROOT := $(dir $(lastword $(MAKEFILE_LIST)))` followed by `foo_DIR := $(ROOT)`.
> That is safe only because `foo_DIR` freezes `ROOT` immediately with `:=`. The
> shared `ROOT` is reassigned by every `module.mk`, so a lazy (`=`) reference
> reads whichever one was included last:
>
> ```makefile
> foo_EXPORTED_CPPFLAGS = -I$(ROOT)      # WRONG -- resolves late, wrong dir
> foo_EXPORTED_CPPFLAGS = -I$(foo_DIR)   # right -- frozen per target
> ```
>
> A single-directory project never exposes this; it surfaces only once a second
> `module.mk` reassigns `ROOT`.

### Per-Target Variables

| Variable | Description |
|----------|-------------|
| `<name>_CFLAGS` | C / Objective-C compiler flags (e.g. `-Wall -O2`) |
| `<name>_CXXFLAGS` | C++ / Objective-C++ compiler flags (e.g. `-std=c++17`) |
| `<name>_CPPFLAGS` | Preprocessor flags (e.g. `-I`, `-D`) |
| `<name>_DFLAGS` | D compiler flags |
| `<name>_FFLAGS` | Fortran compiler flags |
| `<name>_ASFLAGS` | Assembler flags (`.S` files) |
| `<name>_NASMFLAGS` | NASM flags (`.asm` files) |
| `<name>_FPCFLAGS` | Free Pascal flags (`.pas` files) |
| `<name>_GM2FLAGS` | GCC Modula-2 flags (`.mod` files) |
| `<name>_GENERATED_SRCS` | Source files produced by a code generator; compiled from `_build/<triplet>/` instead of the source tree (see [Generated Sources and Headers](#generated-sources-and-headers)) |
| `<name>_GENERATED_HDRS` | Header files produced by a code generator; placed in `_build/<triplet>/`, ordered ahead of consumers and put on their include path automatically |
| `<name>_EXTRA_OBJS` | Additional pre-built `.o` files to link (not compiled or cleaned by this build system) |
| `<name>_LDFLAGS` | Linker flags (executables and shared libs) |
| `<name>_LDLIBS` | Link libraries (executables and shared libs, e.g. `-lm`) |
| `<name>_PKGS` | External packages, resolved to `--cflags`/`--libs` via the built-in table or `pkg-config` (e.g. `sdl3 gl m`) |
| `<name>_EXEC` | Set automatically -- full output path for executables |
| `<name>_LIBS` | Library dependencies (resolved transitively; works on libraries too) |
| `<name>_EXPORTED_CPPFLAGS` | Preprocessor flags exported to dependents (e.g. `-I`) |
| `<name>_EXPORTED_CFLAGS` | C flags exported to dependents |
| `<name>_EXPORTED_CXXFLAGS` | C++ flags exported to dependents |
| `<name>_EXPORTED_LDFLAGS` | Linker flags exported to dependents |
| `<name>_EXPORTED_LDLIBS` | Link libraries exported to dependents (e.g. `-lstdc++`) |
| `<name>_TESTCMD` | Test commands (use `define`/`endef`); run by `make run-tests` |

### Per-File and Global Variables

| Variable | Description |
|----------|-------------|
| `TEST_TARGETS` | Targets with `_TESTCMD` to run during `make run-tests` |
| `SUBDIRS` | Subdirectories containing additional `module.mk` files (per-file, not per-target). When using a top-level `module.mk`, add `src` here to load `src/module.mk`. |
| `TOP` | Absolute path to the project root (with trailing slash), available to all `module.mk` files |

### Executable with a Static Library

```
src/
  module.mk
  main.c
  util/
    module.mk
    util.c
    util.h
```

```makefile
# src/module.mk
SUBDIRS       = util
EXECUTABLES  += myapp
myapp_DIR    := $(dir $(lastword $(MAKEFILE_LIST)))
myapp_SRCS    = main.c
myapp_LIBS    = myutil

# src/util/module.mk
LIBRARIES    += myutil
myutil_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
myutil_SRCS   = util.c
myutil_EXPORTED_CPPFLAGS = -I$(myutil_DIR)
```

### Mixed C and C++

```makefile
EXECUTABLES    += myapp
myapp_DIR      := $(dir $(lastword $(MAKEFILE_LIST)))
myapp_SRCS      = main.c engine.cpp
myapp_CFLAGS    = -O2
myapp_CXXFLAGS  = -O2 -std=c++17
```

When any source file in the target or its transitive `_LIBS` dependencies is `.cc`, `.cpp`, or `.mm`, the linker is automatically set to `$(CXX)`.

### Shared Library

```makefile
SHARED_LIBS    += myplugin
myplugin_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
myplugin_SRCS   = plugin.c hooks.c
myplugin_CFLAGS = -Wall
```

Objects for shared libraries are compiled with `-fPIC` automatically (or `-Cg` for Pascal).

### Pascal with C

Pascal functions must use the `cdecl` calling convention to be callable from C:

```pascal
procedure greet(msg: PChar); cdecl; export;
```

Compile to `.o` with Free Pascal, then link alongside C objects. You may need to add FPC runtime libraries to `_LDLIBS`.

### Platform-Specific Suffixes

Most per-target variables accept `.<os>`, `.<arch>`, and `.<os>.<arch>` suffixes. After all `module.mk` files are loaded, suffixed values are appended to the base variable automatically. `<os>` follows the `uname -s` spelling (e.g. `Linux`, `Darwin`, `Windows_NT`) and `<arch>` follows `uname -m` (e.g. `x86_64`, `aarch64`, `riscv64`).

When cross-compiling (e.g. `CC=aarch64-linux-gnu-gcc`), the target OS and architecture are derived from the compiler's triplet, so the correct suffixes are selected automatically.

```makefile
# library with arch-specific SIMD and a portable C fallback
LIBRARIES    += minmax
minmax_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
minmax_SRCS           = minmax.c
minmax_SRCS.x86_64    = arch/minmax_x86_64.S
minmax_SRCS.aarch64   = arch/minmax_aarch64.S
minmax_LDLIBS.Linux   = -lm -ldl
minmax_CFLAGS.Linux.x86_64 = -msse4.2
```

The supported suffixed variables are: `_SRCS`, `_LIBS`, `_PKGS`, `_EXTRA_OBJS`, and all per-target compiler/linker flag variables (`_CFLAGS`, `_CXXFLAGS`, `_CPPFLAGS`, `_LDFLAGS`, `_LDLIBS`, `_ASFLAGS`, `_DFLAGS`, `_FFLAGS`, `_NASMFLAGS`, `_FPCFLAGS`, `_GM2FLAGS`, and the `_EXPORTED_*` variants).

### Conditional Compiler Detection

A `module.mk` can check whether its compiler is available and conditionally register its target. This is useful for optional dependencies or compilers that may not be installed (e.g. cross-compiling without Free Pascal):

```makefile
# library: "greet_pascal" -- only when fpc is available
ifneq ($(shell command -v $(FPC) 2>/dev/null),)
LIBRARIES += greet_pascal
greet_pascal_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_pascal_SRCS = greetpascal.pas
greet_pascal_EXPORTED_CPPFLAGS = -I$(greet_pascal_DIR) -DHAVE_PASCAL
endif
```

Dependents can use `$(filter)` to conditionally link against the optional library:

```makefile
world_LIBS = greet_c $(filter greet_pascal,$(LIBRARIES)) greet_m2
```

And guard the corresponding C code with the exported define:

```c
#ifdef HAVE_PASCAL
#include <greet_pascal.h>
#endif
```

### External Packages (`_PKGS`)

List external libraries a target needs in `<name>_PKGS`. Each token is
resolved once to compile and link flags, folded into the target's
`CPPFLAGS` (`--cflags`) and `LDLIBS` (`--libs`):

```makefile
# executable linked against SDL3 and the math and OpenGL libraries
EXECUTABLES  += game
game_DIR      := $(dir $(lastword $(MAKEFILE_LIST)))
game_SRCS     = game.c
game_PKGS     = sdl3 gl m
```

A token is resolved one of two ways:

- If it is in `KNOWN_PKGS`, its flags come from the built-in table
  (`PKG_<token>_CFLAGS` / `PKG_<token>_LDLIBS`, platform suffixes
  supported). No `pkg-config` is invoked, so these work on systems
  without it (e.g. macOS, Windows).
- Otherwise it is passed to `pkg-config --cflags/--libs <token>`.

The built-in table is limited to stable, path-free system libraries:

| Token | Purpose | Linux | macOS | Windows |
|-------|---------|-------|-------|---------|
| `m` | Math library | `-lm` | (in libSystem) | (in CRT) |
| `gl` | OpenGL | `-lGL` | `-framework OpenGL` | `-lopengl32` |
| `dl` | Dynamic loader | `-ldl` | (in libSystem) | |
| `rt` | Realtime/clock | `-lrt` | (in libSystem) | |
| `pthread` | POSIX threads | `-lpthread` | (in libSystem) | |

`_PKGS` accepts the same `.<os>`, `.<arch>`, and `.CONFIG_*` suffixes as
the other per-target variables, and package link flags declared on a
library propagate to any executable that links it.

To add a package to the table, or override an entry for one platform,
extend it from a `module.mk`:

```makefile
KNOWN_PKGS += glfw3
PKG_glfw3_LDLIBS.Linux      = -lglfw
PKG_glfw3_LDLIBS.Darwin     = -lglfw -framework Cocoa -framework IOKit
PKG_glfw3_LDLIBS.Windows_NT = -lglfw3
```

### Generated Sources and Headers

Code generators (an IDL compiler, `bin2c`, a shader packer) produce `.c` and
`.h` files. List them in `<name>_GENERATED_SRCS` and `<name>_GENERATED_HDRS`
and they are placed under `_build/<triplet>/` instead of being dropped in the
source tree. Paths are relative to `<name>_DIR`. You still write the rule that
runs the generator.

```makefile
LIBRARIES += proto
proto_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
proto_GENERATED_SRCS = proto.c
proto_GENERATED_HDRS = proto.h

# GNU Make 4.3+: one recipe, both outputs (a grouped target with &:).
$(BUILDDIR)/$(proto_DIR)proto.c $(BUILDDIR)/$(proto_DIR)proto.h &: $(proto_DIR)proto.idl
	my-idl-codegen $< -o $(BUILDDIR)/$(proto_DIR)
```

Declaring a header in `_GENERATED_HDRS` makes the build system, for that target
and every target that lists it in `_LIBS` (transitively):

- **order** the header ahead of any object that may `#include` it, so a clean
  parallel build never compiles a consumer before the header exists;
- **find** it: the header's build directory goes on the include path
  automatically, so consumers write `#include "proto.h"` with no manual `-I`;
- **rebuild** consumers when it changes (via the `.dep` files); and
- **clean** it.

This replaces the hand-written `-I$(BUILDDIR)/...` flags and
`obj : | generated.h` order-only prerequisites these generators used to
require. Change detection needs make to notice the header's new timestamp, so
the generation rule must give the header a recipe: use a grouped target
(`&:`, GNU Make 4.3+) as above, or on GNU Make 4.0-4.2 give each output its own
recipe:

```makefile
$(BUILDDIR)/$(proto_DIR)proto.c : $(proto_DIR)proto.idl
	my-idl-codegen $< -o $(BUILDDIR)/$(proto_DIR)
$(BUILDDIR)/$(proto_DIR)proto.h : $(BUILDDIR)/$(proto_DIR)proto.c ; @touch -c $@
```

A bare `proto.h : proto.c` with no recipe will not rebuild consumers when only
the header changes, because make never re-stats a target it did not run a
recipe for.

### Test Commands

Define test commands with `define`/`endef` and register the target:

```makefile
define myapp_TESTCMD
$(myapp_EXEC) --selftest
$(myapp_EXEC) < testdata/input.txt | diff - testdata/expected.txt
endef
TEST_TARGETS += myapp
```

The `<name>_EXEC` variable is set automatically for each executable (expands to the full output path).

Run all tests with `make run-tests`. Each line is a separate shell command; if any fails, make stops.

## Directory Layout

```
_build/<triplet>/    object files (.o) and dependency files (.dep)
_out/<triplet>/bin/  executable binaries
_out/<triplet>/lib/  shared libraries
```

The triplet (e.g. `x86_64-linux-gnu`) comes from `$(CC) -dumpmachine`, so cross-compiled artifacts don't clobber native ones.

### Build Variants

A build variant adds one more path component under the triplet, so objects compiled with different flags never share a path:

```
_build/<triplet>/<variant>/       objects for the variant
_out/<triplet>/<variant>/bin/     binaries for the variant
```

The variant tag comes from the build mode, the sanitizer list, and a free-form `VARIANT` value, joined with `-` in that order:

| Command | Build directory |
|---------|-----------------|
| `make` | `_build/<triplet>/` |
| `make RELEASE=1` | `_build/<triplet>/release/` |
| `make SANITIZE=address,undefined` | `_build/<triplet>/san-address+undefined/` |
| `make DEBUG=1 VARIANT=coverage` | `_build/<triplet>/debug-coverage/` |

A plain `make` has an empty tag and builds directly under the triplet, which is the layout earlier versions used. Because each variant owns its objects, switching between them does not force a rebuild and cannot mix incompatible objects. Sanitizer tokens are sorted, so `SANITIZE=address,undefined` and `SANITIZE=undefined,address` name the same directory.

`config.mk` and `config.h` stay at the triplet level and are shared by every variant, so a sanitizer build uses the same feature configuration as the ordinary one.

`make clean` and `make clean_<name>` act on the variant named by the current command line, so pass the same variant variables you built with:

```sh
make SANITIZE=address,undefined
make clean SANITIZE=address,undefined
```

`make clean-all` removes the shared config and prunes every empty directory under `_build` and `_out`, including other variants.

## Make Targets

| Target | Description |
|--------|-------------|
| `make` | Build all executables (default) |
| `make <name>` | Build a single target by name |
| `make clean` | Remove generated files for the current build variant |
| `make clean_<name>` | Remove files for a single target |
| `make clean-all` | `clean` plus remove `config.mk`, `config.h`, and every empty build directory |
| `make run-tests` | Build all test targets, then run their `_TESTCMD` |
| `make run-test-<name>` | Build and test a single target |
| `make defconfig` | Reset `config.mk` from `./defconfig` (auto-created on first build) |
| `make defconfig_<name>` | Generate `config.mk` from `configs/<name>.mk` |

## Customization

Override on the command line, in the environment, or in a `.env` file (copy `env.example` to `.env` for local settings):

| Variable | Default | Description |
|----------|---------|-------------|
| `USE_CLANG` | (unset) | Set to use `clang`/`clang++` instead of `cc`/`c++` |
| `CC` | `cc` | C compiler |
| `CXX` | `c++` | C++ compiler |
| `FC` | `gfortran` | Fortran compiler |
| `GDC` | `gdc` | D compiler |
| `NASM` | `nasm` | Netwide Assembler |
| `FPC` | `fpc` | Free Pascal compiler |
| `GM2` | `gm2` | GCC Modula-2 frontend |
| `AR` | `ar` | Archiver |
| `ARFLAGS` | `rvD` | Archiver flags |
| `DEBUG` | (unset) | Enable debug build flags (`-Og -g -fno-omit-frame-pointer`) |
| `RELEASE` | (unset) | Enable release build flags (`-O2`, LTO, `-DNDEBUG`, section GC) |
| `RELEASE_MARCH` | `native` | Target architecture for release builds (e.g. `x86-64-v2`) |
| `SANITIZE` | (unset) | Comma-separated sanitizer list passed to `-fsanitize` (e.g. `address,undefined`) |
| `VARIANT` | (unset) | Free-form variant name for a project's own flag set (coverage, profiling) |
| `MKDIR_P` | `mkdir -p` | Directory creation |
| `RMDIR` | `rmdir` | Directory removal |
| `V` | (unset) | Verbose output. `V=1` prints full command lines (recommended for CI/CD). Default shows short tags (`CC`, `LD`, `AR`, etc.) |
| `COLOR` | (auto) | Color for quiet-mode tags. Auto-detected by default. `COLOR=0` disables, `COLOR=1` forces on |

`DEBUG` and `RELEASE` are mutually exclusive. Build mode flags are injected into all GCC-based compile and link commands. LTO is auto-detected by probing the full toolchain (compile, archive, link). Uses `-flto=thin` with Clang and `-flto=auto` with GCC. Pascal (FPC) is not affected.

Use Clang instead of GCC:

```sh
make USE_CLANG=1
```

Debug build:

```sh
make DEBUG=1
```

Release build:

```sh
make RELEASE=1
make RELEASE=1 RELEASE_MARCH=x86-64-v3
```

Sanitizer build:

```sh
make SANITIZE=address,undefined
_out/*/san-address+undefined/bin/myapp
```

`SANITIZE` adds the flags to every compile and link command, along with `-g` and `-fno-omit-frame-pointer` for readable reports. It composes with the build mode. The default mode or `DEBUG=1` is the usual pairing, since `-O2` and LTO make sanitizer reports harder to read. Set runtime options in the environment, for example `ASAN_OPTIONS=detect_leaks=1`.

A project that needs its own flag set gives it a name with `VARIANT` and applies the flags from a `module.mk`:

```make
ifeq ($(VARIANT),coverage)
  PROJECT_CFLAGS += --coverage
  PROJECT_LDFLAGS += --coverage
endif
```

```sh
make VARIANT=coverage
```

Cross-compile example:

```sh
make CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++
```

Verbose output (recommended for CI/CD):

```sh
make V=1
make V=1 RELEASE=1
```

## Build Configuration (CONFIG_* Options)

Optional per-triplet feature toggles. A `config.mk` file in the build directory controls which features are enabled.

### Quick Start

If your project has a `defconfig` file, `config.mk` is auto-created from it on the first build. To reset or customize:

```sh
make defconfig          # reset _build/<triplet>/config.mk from ./defconfig
# edit _build/<triplet>/config.mk
make                    # rebuild with new settings
```

Without a `defconfig` or `config.mk`, the build works normally with all CONFIG options disabled.

After changing config options that add or remove source files, remove `_build/` manually before rebuilding (`make clean` only removes files known to the current config).

### How It Works

For each `CONFIG_FOO = y` in `config.mk`:

1. Per-target variables with a `.CONFIG_FOO` suffix are merged into their base variable:

   ```makefile
   myapp_SRCS.CONFIG_SSL = ssl.c
   myapp_LDLIBS.CONFIG_SSL = -lssl -lcrypto
   ```

2. `-DCONFIG_FOO=1` is added to all compile commands, so C/C++ code can use `#ifdef CONFIG_FOO`.

3. A `config.h` header is auto-generated in `_build/<triplet>/` (on the include path). Every `CONFIG_*` variable is emitted: `y` becomes `#define CONFIG_FOO 1`, and non-`y`/non-`n` values are written verbatim. Source files can `#include "config.h"` to access all config values without `-D` escaping.

### Non-Boolean Parameters

Non-boolean values use the `CONFIG_` prefix and are written verbatim into `config.h`:

```makefile
# config.mk
CONFIG_CUSTOM_GREETING = y
CONFIG_GREETING_STR = "What's up"
```

```c
/* greet.c */
#include "config.h"

#ifndef CONFIG_GREETING_STR
#define CONFIG_GREETING_STR "Hello"
#endif
```

Strings with spaces, quotes, and special characters work naturally because `config.h` is generated directly -- no shell escaping is involved.

### Conditional Module Registration

Entire modules can be gated on a CONFIG option:

```makefile
ifeq ($(CONFIG_LUA_SCRIPTING),y)
  LIBRARIES += lua_bridge
  lua_bridge_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
  lua_bridge_SRCS = lua_bridge.c
endif
```

### Named Configurations

Place named config templates in `configs/`:

```sh
make defconfig_minimal  # copies configs/minimal.mk to config.mk
```

Config options control features, not toolchains. Compiler selection (`CC`, `USE_CLANG`) and build modes (`DEBUG`, `RELEASE`) belong in `.env` or on the command line.

## Requirements

- GNU Make 4.0 or later (uses the `$(file)` function introduced in 4.0)
- A C compiler (GCC, Clang, etc.)
- Optional language compilers as needed by your project

### Installing Build Dependencies (Debian/Ubuntu)

Core build tools:

```sh
sudo apt-get install build-essential
```

Additional language compilers:

```sh
sudo apt-get install g++          # C++ (.cc, .cpp)
sudo apt-get install gdc          # D (.d)
sudo apt-get install gfortran     # Fortran (.f, .f90)
sudo apt-get install gobjc        # Objective-C (.m)
sudo apt-get install gobjc++      # Objective-C++ (.mm)
sudo apt-get install fpc          # Pascal (.pas)
sudo apt-get install gm2          # Modula-2 (.mod)
sudo apt-get install nasm         # Assembly (.asm)
```

Or install everything at once:

```sh
sudo apt-get install build-essential g++ gdc gfortran gobjc gobjc++ fpc gm2 nasm
```

## Testing

A self-contained test suite under `tests/` exercises build system features using only C and C++ (no exotic compilers needed):

```sh
tests/run-tests.sh              # test with default compiler
tests/run-tests.sh USE_CLANG=1  # test with clang
```

## License

Public domain. Use however you like.
