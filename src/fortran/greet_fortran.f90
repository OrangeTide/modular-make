subroutine greet_fortran() bind(c, name="greet_fortran")
  implicit none
  print *, "Hello from Fortran!"
end subroutine greet_fortran
