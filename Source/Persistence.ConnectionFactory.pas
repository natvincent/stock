unit Persistence.ConnectionFactory;

interface

uses
  Persistence.Interfaces;

function ConnectionFactory: IConnectionFactory;
procedure RegisterConnectionFactory(const AConnectionFactory: IConnectionFactory);

implementation

var
  MConnectionFactory: IConnectionFactory;

function ConnectionFactory: IConnectionFactory;
begin
  result := MConnectionFactory;
end;

procedure RegisterConnectionFactory(const AConnectionFactory: IConnectionFactory);
begin
  MConnectionFactory := AConnectionFactory;
end;

end.
