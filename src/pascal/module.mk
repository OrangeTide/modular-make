# library: "greet_pascal"
greet_pascal_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_pascal_SRCS = greetpascal.pas
greet_pascal_FPCFLAGS = -Cg
greet_pascal_EXPORTED_CPPFLAGS = -I$(greet_pascal_DIR)
LIBRARIES += greet_pascal
