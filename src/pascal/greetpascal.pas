unit greetpascal;

{$mode objfpc}

interface

procedure greet_pascal; cdecl; public name 'greet_pascal';

implementation

function puts(s: PChar): Integer; cdecl; external;

procedure greet_pascal; cdecl;
begin
  puts('Hello from Pascal!');
end;

end.
