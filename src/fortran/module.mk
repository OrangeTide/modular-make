# library: "greet_fortran"
greet_fortran_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
greet_fortran_SRCS = greet_fortran.f90
greet_fortran_EXPORTED_CPPFLAGS = -I$(greet_fortran_DIR)
greet_fortran_EXPORTED_LDLIBS = -lgfortran
LIBRARIES += greet_fortran
