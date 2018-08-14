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
  FireDAC.Stan.Param, 
  Persistence.DB;

type

  TFireDACConnection = class (TInterfacedObject, IConnection)
  private
    FConnection: TFDConnection;
    function GetDatabase: string;
    procedure SetDatabase(const AValue: string);
    function CreateQuery: IQuery;
    function GetLastIdentityValue: Int64;

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
    function GetRecordCount: Integer;

    procedure Execute;
    procedure Open;

    procedure Next;

    function FieldByName(const AName: string): IField;
    function ParamByName(const AName: string): IParam;
    function FindParam(const AName: string; out AParam: IParam): Boolean;

  public
    constructor Create(const AFDQuery: TFDQuery);
    destructor Destroy; override;

  end;

  TFireDACConnectionFactory = class (TInterfacedObject, IConnectionFactory)
  private
    FDatabasePath: string;
    function CreateConnection: IConnection;
    function GetDatabasePath: string;
    procedure SetDatabasePath(const APath: string);

  end;

  TSQLiteSelectBuilder = class (TStatementBuilder, ISelectBuilder)
  private
    FFromTable: string;
    FFields: TStringList;
    FWhere: TStringList;
    FAdditionalWhere: TStringList;

    function GenerateFields: string;
    function GenerateWhere: string;

    procedure AddField(const AFieldClause: string);
    procedure AddFrom(const ATableName: string);
    procedure AddWhereAnd(const APredicate: string);

  protected
    procedure AddAdditionalWhereAnd(const APredicate: string); override;
    function Generate: string; override;

  public
    constructor Create;
    destructor Destroy; override;
    
  end;

  TSQLiteInsertBuilder = class (TStatementBuilder, IUpdateInsertBuilder)
  private
    FFields: TStringList;
    FInsertInto: string;

    procedure AddFieldParam(const AFieldAndParamName: string);
    procedure AddUpdateInto(const ATableName: string);
    procedure AddWhereField(const AFieldAndParamName: string);

  protected
    function Generate: string; override;

  public
    constructor Create;
    destructor Destroy; override;
    
  end;
  
  TSQLiteUpdateBuilder = class (TStatementBuilder, IUpdateInsertBuilder)
  private
    FFields: TStringList;
    FWhereFields: TStringList;
    FUpdateTable: string;
    
    function GenerateSet: string;
    function GenerateWhere: string;

    procedure AddFieldParam(const AFieldAndParamName: string);
    procedure AddUpdateInto(const ATableName: string);
    procedure AddWhereField(const AFieldAndParamName: string);

  protected
    function Generate: string; override;
  
  public
    constructor Create; 
    destructor Destroy; override;
  end;
  
  TSQLiteStatementBuilderFactory = class (TInterfacedObject, IStatementBuilderFactory)
  private
    function CreateInsertBuilder: IUpdateInsertBuilder;
    function CreateSelectBuilder: ISelectBuilder;
    function CreateUpdateBuilder: IUpdateInsertBuilder;
    function CreateEchoBuilder(
      const AStatement: string
    ): IStatementBuilder;
  end;
  
implementation

uses
  Persistence.Types,
  Persistence.Consts,
  System.SysUtils;

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

function TFireDACQuery.FindParam(const AName: string;
  out AParam: IParam): Boolean;
var
  LIndex: integer;
  LParam: TFDParam;
begin
  for LIndex := 0 to FQuery.Params.Count - 1 do
  begin
    LParam := FQuery.Params[LIndex];
    if SameText(LParam.Name, AName) then
    begin
      AParam := TFireDACParam.Create(LParam);
      Exit(True);
    end;
  end;
  result := False;
end;

function TFireDACQuery.GetEOF: Boolean;
begin
  result := FQuery.Eof;
end;

function TFireDACQuery.GetRecordCount: Integer;
begin
  result := FQuery.RecordCount;
end;

function TFireDACQuery.GetSQL: string;
begin
  result := FQuery.SQL.Text;
end;

procedure TFireDACQuery.Next;
begin
  FQuery.Next;
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

function TFireDACConnection.GetLastIdentityValue: Int64;
begin
  result := Int64(FConnection.GetLastAutoGenValue(''));
end;

procedure TFireDACConnection.SetDatabase(const AValue: string);
begin
  FConnection.Params.Database := AValue;
end;

{ TFireDACConnectionFactory }

function TFireDACConnectionFactory.CreateConnection: IConnection;
begin
  if FDatabasePath = '' then
    raise EDatabasePathNotSet.Create(CDatabasePathNotSet);
  result := TFireDACConnection.Create;
  result.Database := FDatabasePath;
end;

function TFireDACConnectionFactory.GetDatabasePath: string;
begin
  result := FDatabasePath;
end;

procedure TFireDACConnectionFactory.SetDatabasePath(const APath: string);
begin
  FDatabasePath := APath;
end;

{ TSQLiteSelectBuilder }

procedure TSQLiteSelectBuilder.AddAdditionalWhereAnd(const APredicate: string);
begin
  FAdditionalWhere.Add(APredicate);
end;

procedure TSQLiteSelectBuilder.AddField(const AFieldClause: string);
begin
  FFields.Add(AFieldClause);
end;

procedure TSQLiteSelectBuilder.AddFrom(const ATableName: string);
begin
  FFromTable := ATableName;
end;

procedure TSQLiteSelectBuilder.AddWhereAnd(const APredicate: string);
begin
  FWhere.Add(APredicate);
end;

constructor TSQLiteSelectBuilder.Create;
begin
  inherited Create;
  FFields := TStringList.Create;
  FWhere := TStringList.Create;
  FAdditionalWhere := TStringList.Create;
end;

destructor TSQLiteSelectBuilder.Destroy;
begin
  FAdditionalWhere.Free;
  FWhere.Free;
  FFields.Free;
  inherited;
end;

function TSQLiteSelectBuilder.Generate: string;
const
  CSelect = 'select';
  CFrom = 
      #13#10 + 'from'
    + #13#10 + '  ';
begin
  if FFromTable = '' then
    raise EMissingFromClauseException.Create(CMissingFromMessage);
  result := CSelect
    + GenerateFields
    + CFrom + FFromTable
    + GenerateWhere;

  FAdditionalWhere.Clear;
end;

function TSQLiteSelectBuilder.GenerateFields: string;
var
  LField: string;
  LSeperator: string;
const
  CStartFields = 
    #13#10 + '  ';
  CFieldSeparator =
    ','
    + #13#10 + '  ';
begin
  if FFields.Count = 0 then
    raise EMissingFieldsException.Create(CMissingFieldsMessage);
  LSeperator := CStartFields;
  for LField in FFields do
  begin
    result := result + LSeperator + LField;
    LSeperator := CFieldSeparator;
  end;
end;

function TSQLiteSelectBuilder.GenerateWhere: string;
var
  LSeperator: string;
const
  CSeparator =
    #13#10 + '  and ';
  CStartWhere = 
    #13#10 + 'where 1 = 1'
    + CSeparator;

  procedure ProcessList(const AWhereList: TStringList);
  var
    LPredicate: string;
  begin
    for LPredicate in AWhereList do
    begin
      result := result + LSeperator + LPredicate;
      LSeperator := CSeparator;
    end;
  end;
  
begin
  LSeperator := CStartWhere;
  ProcessList(FWhere);
  ProcessList(FAdditionalWhere);
end;

{ TSQLiteInsertBuilder }

procedure TSQLiteInsertBuilder.AddFieldParam(const AFieldAndParamName: string);
begin
  FFields.Add(AFieldAndParamName);
end;

procedure TSQLiteInsertBuilder.AddUpdateInto(const ATableName: string);
begin
  FInsertInto := ATableName;
end;

procedure TSQLiteInsertBuilder.AddWhereField(const AFieldAndParamName: string);
begin
  raise EWhereFieldsNotSupportedForInserts.Create(CWhereFieldsNotSupported);
end;

constructor TSQLiteInsertBuilder.Create;
begin
  inherited Create;
  FFields := TStringList.Create;
end;

destructor TSQLiteInsertBuilder.Destroy;
begin
  FFields.Free;
  inherited;
end;

function TSQLiteInsertBuilder.Generate: string;
var
  LField: string;
  LFields: string;
  LValues: string;
  LSeparator: string;
const
  CLineStart = 
    #13#10 + '  ';
  CFieldSeparator = 
    ','
    + CLineStart;  
begin
  if FInsertInto = '' then
    raise EMissingIntoUpdateClauseException.Create(CMissingIntoUpdateMessage);
  if FFields.Count = 0 then
    raise EMissingFieldsException.Create(CMissingFieldsMessage);
  LSeparator := CLineStart;
  for LField in FFields do
  begin
    LFields := LFields + LSeparator + LField;
    LValues := LValues + LSeparator + ':' + LField;
    LSeparator := CFieldSeparator;
  end;
  result := 
    'insert into ' + FInsertInto + ' ('
    + LFields
    + #13#10 + ') values (' 
    + LValues
    + #13#10 + ')';
end;

{ TSQLiteUpdateBuilder }

procedure TSQLiteUpdateBuilder.AddFieldParam(const AFieldAndParamName: string);
begin
  FFields.Add(AFieldAndParamName);
end;

procedure TSQLiteUpdateBuilder.AddUpdateInto(const ATableName: string);
begin
  FUpdateTable := ATableName;
end;

procedure TSQLiteUpdateBuilder.AddWhereField(const AFieldAndParamName: string);
begin
  FWhereFields.Add(AFieldAndParamName); 
end;

constructor TSQLiteUpdateBuilder.Create;
begin
  inherited Create;
  FFields := TStringList.Create;
  FWhereFields := TStringList.Create;
end;

destructor TSQLiteUpdateBuilder.Destroy;
begin
  FWhereFields.Free;
  FFields.Free;
  inherited;
end;

function TSQLiteUpdateBuilder.GenerateSet: string;
var
  LSeparator: string;
  LField: string;
const
  CStart = 
    #13#10 + '  ';
  CFieldSeparator = 
    ',' 
    + CStart;
begin
  if FFields.Count = 0 then
    raise EMissingFieldsException.Create(CMissingFieldsMessage);
  LSeparator := CStart;
  for LField in FFields do
  begin
    result := result + LSeparator + LField + ' = :' + LField;
    LSeparator := CFieldSeparator;
  end;
end;

function TSQLiteUpdateBuilder.GenerateWhere: string;
var
  LSeparator: string;
  LWhereField: string;
const
  CStart = 
      #13#10 + 'where'
    + #13#10 + '  ';
  CFieldSeparator = 
    #13#10 + 'and ';
begin
  LSeparator := CStart;
  for LWhereField in FWhereFields do
  begin
    result := result + LSeparator + LWhereField + ' = :' + LWhereField;
    LSeparator := CFieldSeparator;
  end;
end;

function TSQLiteUpdateBuilder.Generate: string;
begin
  if FUpdateTable = '' then
    raise EMissingIntoUpdateClauseException.Create(CMissingIntoUpdateMessage);
  result := 'update ' + FUpdateTable + ' set'
  + GenerateSet
  + GenerateWhere;
end;

{ TSQLiteStatementBuilderFactory }

function TSQLiteStatementBuilderFactory.CreateEchoBuilder(
  const AStatement: string
): IStatementBuilder;
begin
  result := TEchoStatementBuilder.Create(AStatement);
end;

function TSQLiteStatementBuilderFactory.CreateInsertBuilder: IUpdateInsertBuilder;
begin
  result := TSQLiteInsertBuilder.Create;
end;

function TSQLiteStatementBuilderFactory.CreateSelectBuilder: ISelectBuilder;
begin
  result := TSQLiteSelectBuilder.Create;
end;

function TSQLiteStatementBuilderFactory.CreateUpdateBuilder: IUpdateInsertBuilder;
begin
  result := TSQLiteUpdateBuilder.Create;
end;

end.
