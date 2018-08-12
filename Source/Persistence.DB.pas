unit Persistence.DB;

interface

uses
  Data.DB,
  Persistence.Interfaces;

type

  TPersistenceField = class (TInterfacedObject, IField)
  private
    FField: TField;
    function GetAsInteger: Integer;
    function GetAsString: string;
  public
    constructor Create(const AField: TField);
  end;

  TStatementBuilder = class (TInterfacedObject, IStatementBuilder)
  protected
    function Generate: string; virtual; abstract;
    procedure AddAdditionalWhereAnd(const APredicate: string); virtual;

  end;

implementation

{ TPersistenceField }

constructor TPersistenceField.Create(const AField: TField);
begin
  inherited Create;
  FField := AField;
end;

function TPersistenceField.GetAsInteger: Integer;
begin
  result := FField.AsInteger;
end;

function TPersistenceField.GetAsString: string;
begin
  result := FField.AsString;
end;


{ TStatementBuilder }

procedure TStatementBuilder.AddAdditionalWhereAnd(const APredicate: string);
begin
end;

end.
