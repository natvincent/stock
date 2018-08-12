unit Persistence.StatementCache;

interface

uses
  Persistence.Interfaces,
  Persistence.Types,
  System.Rtti,
  System.Generics.Collections;

type

  TStatementKey = record
    StatementType: TStatementType;
    DataObjectClass: TDataObjectClass;
  end;

  TStatementCache = class (TInterfacedObject, IStatementCache)
  private
    FStatements: TDictionary<TStatementKey, string>;
    FStatementBuilderFactory: IStatementBuilderFactory;
    FRttiContext: TRttiContext;

    function FindTableNameAttribute(
      const ATypeInfo: TRttiType
    ): string;
    function CreateKey(
      const AStatementType: TStatementType;
      const AForClass: TDataObjectClass
    ): TStatementKey;
    function CreateSelect(const AClass: TDataObjectClass): string;
    function CreateUpdate(const AClass: TDataObjectClass): string;
    function CreateInsert(const AClass: TDataObjectClass): string;
    procedure AddStatement(
      const AStatementType: TStatementType;
      const AForClass: TDataObjectClass;
      const AStatement: string
    );
    function FindStatement(
      const AStatementType: TStatementType;
      const AForClass: TDataObjectClass;
      out AStatement: string
    ): boolean;

    function GetStatement(
      const AStatementType: TStatementType;
      const AForClass: TDataObjectClass
    ): string;

  public
    constructor Create(
      const AStatementBuilderFactory: IStatementBuilderFactory
    );
    destructor Destroy; override;
  end;

implementation

uses
  Persistence.Consts,
  Winapi.Windows;

{ TStatementCache }

procedure TStatementCache.AddStatement(
  const AStatementType: TStatementType;
  const AForClass: TDataObjectClass;
  const AStatement: string);
begin
  FStatements.Add(
    CreateKey(
      AStatementType,
      AForClass
    ),
    AStatement
  );
end;

constructor TStatementCache.Create(
  const AStatementBuilderFactory: IStatementBuilderFactory);
begin
  inherited Create;
  FStatements := TDictionary<TStatementKey, string>.Create;
  FStatementBuilderFactory := AStatementBuilderFactory;
  FRttiContext := TRttiContext.Create;
end;

function TStatementCache.CreateInsert(const AClass: TDataObjectClass): string;
var
  LInsertBuilder: IUpdateInsertBuilder;
  LTypeInfo: TRttiType;
  LProperty: TRttiProperty;
begin
  LInsertBuilder := FStatementBuilderFactory.CreateInsertBuilder;

  LTypeInfo := FRttiContext.GetType(AClass);

  LInsertBuilder.AddUpdateInto(FindTableNameAttribute(LTypeInfo));

  for LProperty in LTypeInfo.GetProperties do
    LInsertBuilder.AddFieldParam(LProperty.Name);
  
  result := LInsertBuilder.Generate;
end;

function TStatementCache.CreateSelect(const AClass: TDataObjectClass): string;
var
  LSelectBuilder: ISelectBuilder;
  LTypeInfo: TRttiType;
  LTableName: string;
  LProperty: TRttiProperty;
begin
  LSelectBuilder := FStatementBuilderFactory.CreateSelectBuilder;

  LTypeInfo := FRttiContext.GetType(AClass);

  LSelectBuilder.AddFrom(FindTableNameAttribute(LTypeInfo));

  for LProperty in LTypeInfo.GetProperties do
    LSelectBuilder.AddField(LProperty.Name);

  result := LSelectBuilder.Generate;
end;

function TStatementCache.CreateUpdate(const AClass: TDataObjectClass): string;
var
  LTypeInfo: TRttiType;
  LUpdateBuilder: IUpdateInsertBuilder;
  LProperty: TRttiProperty;

  function IsKeyProperty(const AProperty: TRttiProperty): boolean;
  var
    LAttribute: TCustomAttribute;
  begin
    for LAttribute in AProperty.GetAttributes do
    begin
      if LAttribute is TKeyFieldAttribute then
        Exit(True);
    end;
    result := False;
  end;

begin
  LUpdateBuilder := FStatementBuilderFactory.CreateUpdateBuilder;

  LTypeInfo := FRttiContext.GetType(AClass);

  LUpdateBuilder.AddUpdateInto(FindTableNameAttribute(LTypeInfo));

  for LProperty in LTypeInfo.GetProperties do
  begin
    if IsKeyProperty(LProperty) then
      LUpdateBuilder.AddWhereField(LProperty.Name)
    else
      LUpdateBuilder.AddFieldParam(LProperty.Name);
  end;

  result := LUpdateBuilder.Generate;
end;

destructor TStatementCache.Destroy;
begin
  FStatements.Free;
  inherited Destroy;
end;

function TStatementCache.CreateKey(const AStatementType: TStatementType; const AForClass: TDataObjectClass): TStatementKey;
begin
  ZeroMemory(@result, SizeOf(result));
  result.StatementType := AStatementType;
  result.DataObjectClass := AForClass;
end;

function TStatementCache.FindStatement(
  const AStatementType: TStatementType;
  const AForClass: TDataObjectClass;
  out AStatement: string
): boolean;
var
  LKey: TStatementKey;
begin
  LKey := CreateKey(AStatementType, AForClass);
  result := FStatements.TryGetValue(LKey, AStatement);
end;

function TStatementCache.FindTableNameAttribute(
  const ATypeInfo: TRttiType
): string;
var
  LAttribute: TCustomAttribute;
begin
  for LAttribute in ATypeInfo.GetAttributes do
  begin
    if LAttribute is TTableNameAttribute then
      Exit(TTableNameAttribute(LAttribute).TableName);
  end;
  raise ETableNameAttributeNotFound.CreateFmt(CTableNameAttributeNotFound, [ATypeInfo.Name])
end;

function TStatementCache.GetStatement(
  const AStatementType: TStatementType;
  const AForClass: TDataObjectClass
): string;
begin
  if not FindStatement(
    AStatementType,
    AForClass,
    result
  ) then
  begin
    case AStatementType of
      stSelect: result := CreateSelect(AForClass);
      stInsert: result := CreateInsert(AForClass);
      stUpdate: result := CreateUpdate(AForClass);
    end;
    AddStatement(
      AStatementType,
      AForClass,
      result
    );
  end;
end;

end.
