# library: "greet_pascal" -- only when fpc is available
ifneq ($(shell command -v $(FPC) 2>/dev/null),)
greet_pascal_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_pascal_SRCS = greetpascal.pas
greet_pascal_FPCFLAGS = -Cg
greet_pascal_EXPORTED_CPPFLAGS = -I$(greet_pascal_DIR) -DHAVE_PASCAL
LIBRARIES += greet_pascal
endif
