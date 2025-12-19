# Modular GNUmakefile for C Projects

A single-file, drop-in build system for C projects. Supports multiple executables, static libraries, and shared libraries through a tree of lightweight `module.mk` descriptor files.

No configuration generators, no external dependencies -- just GNU Make.

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

Source paths in `_SRCS` are relative to `_DIR`.

### Optional Per-Target Variables

| Variable | Description |
|----------|-------------|
| `<name>_CFLAGS` | Compiler flags (e.g. `-Wall -O2`) |
| `<name>_CPPFLAGS` | Preprocessor flags (e.g. `-I`, `-D`) |
| `<name>_LDFLAGS` | Linker flags (executables only) |
| `<name>_LDLIBS` | Link libraries (executables only, e.g. `-lm`) |
| `<name>_LIBS` | Names of library targets this target depends on |
| `<name>_SUBDIRS` | Subdirectories containing additional `module.mk` files |

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
EXECUTABLES  += myapp
myapp_DIR    := $(dir $(lastword $(MAKEFILE_LIST)))
myapp_SRCS    = main.c
myapp_LIBS    = myutil
myapp_CPPFLAGS = -I$(myutil_DIR)
myapp_SUBDIRS  = util

# src/util/module.mk
LIBRARIES    += myutil
myutil_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
myutil_SRCS   = util.c
```

### Shared Library

```makefile
SHARED_LIBS    += myplugin
myplugin_DIR   := $(dir $(lastword $(MAKEFILE_LIST)))
myplugin_SRCS   = plugin.c hooks.c
myplugin_CFLAGS = -Wall
```

Objects for shared libraries are compiled with `-fPIC` automatically.

## Directory Layout

```
_build/<triplet>/    object files (.o) and dependency files (.d)
_out/<triplet>/bin/  executable binaries
_out/<triplet>/lib/  shared libraries
```

The triplet (e.g. `x86_64-linux-gnu`) comes from `$(CC) -dumpmachine`, so cross-compiled artifacts don't clobber native ones.

## Make Targets

| Target | Description |
|--------|-------------|
| `make` | Build all executables |
| `make <name>` | Build a single target by name |
| `make clean` | Remove generated files |
| `make clean_<name>` | Remove files for a single target |
| `make clean-all` | `clean` plus remove empty build directories |

## Customization

Override on the command line or in the environment:

| Variable | Default | Description |
|----------|---------|-------------|
| `CC` | `cc` | C compiler |
| `AR` | `ar` | Archiver |
| `ARFLAGS` | `rv` | Archiver flags |
| `MKDIR_P` | `mkdir -p` | Directory creation |
| `RMDIR` | `rmdir` | Directory removal |

Cross-compile example:

```sh
make CC=aarch64-linux-gnu-gcc
```

## Requirements

- GNU Make 4.x or later
- A C compiler (GCC, Clang, etc.)

## License

Public domain. Use however you like.
