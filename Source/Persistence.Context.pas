unit Persistence.Context;

interface

uses
  Persistence.Interfaces,
  Persistence.Types,
  System.SysUtils,
  System.Rtti;

type

  EContextException = class (Exception);

  TContext = class (TInterfacedObject, IContext)
  private
    FConnection: IConnection;
    FStatementCache: IStatementCache;
    FRTTIContext: TRTTIContext;
    procedure Load(
      const AList: TDataObjectList;
      const ACriteria: string
    );
    procedure Save(const AList: TDataObjectList);
  public
    constructor Create(
      const AConnectionFactory: IConnectionFactory;
      const AStatementCache: IStatementCache
    );

  end;

implementation

uses
  Persistence.Consts,
  System.TypInfo;

{ TContext }

constructor TContext.Create(
  const AConnectionFactory: IConnectionFactory;
  const AStatementCache: IStatementCache
);
begin
  inherited Create;
  FRTTIContext := TRttiContext.Create;
  FConnection := AConnectionFactory.CreateConnection;
  FStatementCache := AStatementCache;
end;

procedure TContext.Load(
  const AList: TDataObjectList;
  const ACriteria: string
);
var
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LType: TRTTIType;
  LSQL: string;
  LQuery: IQuery;
  LInstance: TDataObject;
  LStatementBuilder: IStatementBuilder;
begin
  LType := FRTTIContext.GetType(AList.ListClass);
  LProperties := LType.GetDeclaredProperties;

  LQuery := FConnection.CreateQuery;
  LStatementBuilder := FStatementCache.GetStatement(stSelect, AList.ListClass);
  if ACriteria <> '' then
    LStatementBuilder.AddAdditionalWhereAnd(ACriteria);
  LQuery.SQL := LStatementBuilder.Generate;
  LQuery.Open;
  while not LQuery.EOF do
  begin
    LInstance := AList.ListClass.Create;
    for LProperty in LProperties do
    begin
      case LProperty.PropertyType.TypeKind of
        tkInteger: LProperty.SetValue(LInstance, LQuery.FieldByName(LProperty.Name).AsInteger);
        tkChar,
        tkString,
        tkUString,
        tkWString,
        tkWideChar: LProperty.SetValue(LInstance, LQuery.FieldByName(LProperty.Name).AsString);
      end;
    end;
    LInstance.DataState := dsClean;
    AList.Add(LInstance);
  end;
end;

function IsIdentityProperty(const AProperty: TRttiProperty): boolean;
var
  LAttribute: TCustomAttribute;
begin
  for LAttribute in AProperty.GetAttributes do
  begin
    if LAttribute is TIdentityFieldAttribute then
      Exit(True);
  end;
  result := False;
end;

procedure TContext.Save(const AList: TDataObjectList);
var
  LInsertQuery: IQuery;
  LUpdateQuery: IQuery;
  LObject: TDataObject;
  LTypeInfo: TRttiType;

  function PopulateQuery(const AStatementType: TStatementType): IQuery;
  begin
    result := nil;
    case AStatementType of
      stUpdate:
      begin
        if not Assigned(LUpdateQuery) then
        begin
          LUpdateQuery := FConnection.CreateQuery;
          LUpdateQuery.SQL := FStatementCache.GetStatement(stUpdate, AList.ListClass).Generate;
        end;
        result := LUpdateQuery;
      end;
      stInsert:
      begin
        if not Assigned(LInsertQuery) then
        begin
          LInsertQuery := FConnection.CreateQuery;
          LInsertQuery.SQL := FStatementCache.GetStatement(stInsert, AList.ListClass).Generate;
        end;
        result := LInsertQuery;
      end;
    end;
  end;

  procedure SaveObject(const AObject: TDataObject);
  var
    LQuery: IQuery;
    LProperty: TRttiProperty;
    LIdentityProperty: TRttiProperty;
    LParam: IParam;
  begin
    if not AObject.IsDirty then Exit; //======>

    LQuery := PopulateQuery(CStateToStatementTypeMap[AObject.DataState]);

    for LProperty in LTypeInfo.GetProperties do
    begin
      if LProperty.Visibility = mvPublished then
      begin
        LParam := LQuery.ParamByName(LProperty.Name);
        case LProperty.PropertyType.TypeKind of
          tkInteger: LParam.AsInteger := LProperty.GetValue(AObject).AsInteger;
          tkChar,
          tkString,
          tkUString,
          tkWString,
          tkWideChar: LParam.AsString := LProperty.GetValue(AObject).AsString;
        end;
        if IsIdentityProperty(LProperty) then
        begin
          if Assigned(LIdentityProperty) then
            raise EOnlyOneIdentityPropertyAllowed.Create(COnlyOneIdentityPropertyAllowed);
          LIdentityProperty := LProperty;
        end;
        AObject.DataState := dsClean;
      end;
    end;

    LQuery.Execute;

    if Assigned(LIdentityProperty) then
    begin
      LIdentityProperty.SetValue(AObject, FConnection.GetLastIdentityValue);
    end;
  end;

begin
  LInsertQuery := nil;
  LUpdateQuery := nil;
  LTypeInfo := FRTTIContext.GetType(AList.ListClass);
  for LObject in AList do
    SaveObject(LObject);
end;

end.
