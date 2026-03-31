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
| `<name>_EXTRA_OBJS` | Additional pre-built `.o` files to link (not compiled or cleaned by this build system) |
| `<name>_LDFLAGS` | Linker flags (executables and shared libs) |
| `<name>_LDLIBS` | Link libraries (executables and shared libs, e.g. `-lm`) |
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
| `SUBDIRS` | Subdirectories containing additional `module.mk` files (per-file, not per-target) |
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

## Make Targets

| Target | Description |
|--------|-------------|
| `make` | Build all executables (default) |
| `make <name>` | Build a single target by name |
| `make clean` | Remove generated files |
| `make clean_<name>` | Remove files for a single target |
| `make clean-all` | `clean` plus remove empty build directories |
| `make run-tests` | Build all test targets, then run their `_TESTCMD` |
| `make run-test-<name>` | Build and test a single target |

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
| `RELEASE` | (unset) | Enable release build flags (`-O2`, LTO, `-DNDEBUG`, section GC) |
| `RELEASE_MARCH` | `native` | Target architecture for release builds (e.g. `x86-64-v2`) |
| `MKDIR_P` | `mkdir -p` | Directory creation |
| `RMDIR` | `rmdir` | Directory removal |

Release flags are injected into all GCC-based compile and link commands. LTO uses `-flto=thin` with Clang and `-flto=auto` with GCC. Pascal (FPC) is not affected by release flags.

Use Clang instead of GCC:

```sh
make USE_CLANG=1
```

Release build:

```sh
make RELEASE=1
make RELEASE=1 RELEASE_MARCH=x86-64-v3
```

Cross-compile example:

```sh
make CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++
```

## Requirements

- GNU Make 4.x or later
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

## License

Public domain. Use however you like.
