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

  TEchoStatementBuilder = class (TStatementBuilder)
  private
    FStatement: string;
  public
    constructor Create(const AStatement: string);
    function Generate: string; override;
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

{ TEchoStatementBuilder }

constructor TEchoStatementBuilder.Create(const AStatement: string);
begin
  inherited Create;
  FStatement := AStatement;
end;

function TEchoStatementBuilder.Generate: string;
begin
  result := FStatement;
end;

end.
