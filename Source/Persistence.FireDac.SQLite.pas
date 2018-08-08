unit Persistence.FireDac.SQLite;

interface

uses
  FireDAC.Comp.Client,
  Persistence.Interfaces,
  System.Classes,
  FireDAC.Phys.SQLite,
  FireDAC.DApt,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param;

type

  TFireDACConnection = class (TInterfacedObject, IConnection)
  private
    FConnection: TFDConnection;
    function GetDatabase: string;
    procedure SetDatabase(const AValue: string);
    function CreateQuery: IQuery;

  public
    constructor Create;
    destructor Destroy; override;

  end;

  TFireDACParam = class (TInterfacedObject, IParam)
  private
    FParam: TFDParam;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetName: string;
    procedure SetAsInteger(const AValue: Integer);
    procedure SetAsString(const AValue: string);

  public
    constructor Create(const AParam: TFDParam);

  end;

  TFireDACQuery = class (TInterfacedObject, IQuery)
  private
    FQuery: TFDQuery;

    function GetSQL: string;
    procedure SetSQL(const ASQL: string);
    function GetEOF: Boolean;

    procedure Execute;
    procedure Open;

    function FieldByName(const AName: string): IField;
    function ParamByName(const AName: string): IParam;

  public
    constructor Create(const AFDQuery: TFDQuery);
    destructor Destroy; override;

  end;

  TFireDACConnectionFactory = class (TInterfacedObject, IConnectionFactory)
  private
    FDatabaseFilename: string;
    function CreateConnection: IConnection;

  public
    constructor Create(const ADatabaseFilename: string);
  end;

implementation

uses
  Persistence.Types,
  Persistence.DB;

{ TFireDACQuery }

constructor TFireDACQuery.Create(const AFDQuery: TFDQuery);
begin
  inherited Create;
  FQuery := AFDQuery;
end;

destructor TFireDACQuery.Destroy;
begin
  FQuery.Free;
  inherited;
end;

procedure TFireDACQuery.Execute;
begin
  FQuery.ExecSQL;
end;

function TFireDACQuery.FieldByName(const AName: string): IField;
begin
  result := TPersistenceField.Create(
    FQuery.FieldByName(AName)
  );
end;

function TFireDACQuery.GetEOF: Boolean;
begin
  result := FQuery.Eof;
end;

function TFireDACQuery.GetSQL: string;
begin
  result := FQuery.SQL.Text;
end;

procedure TFireDACQuery.Open;
begin
  FQuery.Open;
end;

function TFireDACQuery.ParamByName(const AName: string): IParam;
begin
  result := TFireDACParam.Create(
    FQuery.ParamByName(AName)
  );
end;

procedure TFireDACQuery.SetSQL(const ASQL: string);
begin
  FQuery.SQL.Text := ASQL;
end;

{ TFireDACParam }

constructor TFireDACParam.Create(const AParam: TFDParam);
begin
  inherited Create;
  FParam := AParam;
end;

function TFireDACParam.GetAsInteger: Integer;
begin
  result := FParam.AsInteger;
end;

function TFireDACParam.GetAsString: string;
begin
  result := FParam.AsString;
end;

function TFireDACParam.GetName: string;
begin
  result := FParam.Name;
end;

procedure TFireDACParam.SetAsInteger(const AValue: Integer);
begin
  FParam.AsInteger := AValue;
end;

procedure TFireDACParam.SetAsString(const AValue: string);
begin
  FParam.AsString := AValue;
end;

{ TFireDACConnection }

constructor TFireDACConnection.Create;
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Values['OpenMode'] := 'CreateUTF16';
end;

function TFireDACConnection.CreateQuery: IQuery;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  LQuery.Connection := FConnection;
  result := TFireDACQuery.Create(LQuery);
end;

destructor TFireDACConnection.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TFireDACConnection.GetDatabase: string;
begin
  result := FConnection.Params.Database;
end;

procedure TFireDACConnection.SetDatabase(const AValue: string);
begin
  FConnection.Params.Database := AValue;
end;

{ TFireDACConnectionFactory }

constructor TFireDACConnectionFactory.Create(const ADatabaseFilename: string);
begin
  inherited Create;
  FDatabaseFilename := ADatabaseFilename;
end;

function TFireDACConnectionFactory.CreateConnection: IConnection;
begin
  result := TFireDACConnection.Create;
  result.Database := FDatabaseFilename;
end;

end.
