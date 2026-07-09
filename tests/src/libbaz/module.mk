LIBRARIES += baz
baz_DIR  := $(dir $(lastword $(MAKEFILE_LIST)))
baz_SRCS  = baz.cpp
# baz depends on bar too. Combined with foo -> bar, this makes bar a shared
# (diamond) dependency of app: app -> foo -> bar and app -> baz -> bar.
# Exercises that a diamond is not misreported as a circular _LIBS dependency
# and that bar is linked exactly once, ordered after both foo and baz.
baz_LIBS  = bar
baz_EXPORTED_CPPFLAGS = -I$(baz_DIR)
