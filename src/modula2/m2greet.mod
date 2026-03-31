IMPLEMENTATION MODULE m2greet;

FROM SYSTEM IMPORT ADR;
FROM cstdio IMPORT puts;

PROCEDURE greet_m2;
VAR
  msg: ARRAY [0..20] OF CHAR;
  r: INTEGER;
BEGIN
  msg := "Hello from Modula-2!";
  r := puts(ADR(msg))
END greet_m2;

END m2greet.
