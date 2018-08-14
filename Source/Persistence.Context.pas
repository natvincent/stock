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
    ); overload;
    function Load(
      const ADataObject: TDataObject;
      const AID: integer
    ): boolean; overload;
    procedure Save(const AList: TDataObjectList); overload;
    procedure Save(const ADataObject: TDataObject); overload;
    procedure SaveObject(
      const AObject: TDataObject;
      const ATypeInfo: TRttiType;
      const AQuery: IQuery
    );
    procedure LoadProperties(const AInstance: TDataObject;
      const AProperties: TArray<TRttiProperty>; const AQuery: IQuery);
  public
    constructor Create(
      const AConnectionFactory: IConnectionFactory;
      const AStatementCache: IStatementCache
    );

  end;

implementation

uses
  Persistence.Consts,
  System.TypInfo, 
  System.DateUtils;

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

procedure TContext.LoadProperties(
  const AInstance: TDataObject;
  const AProperties: TArray<TRttiProperty>;
  const AQuery: IQuery
);
var
  LProperty: TRttiProperty;
  LField: IField;
begin
  for LProperty in AProperties do
  begin
    if LProperty.Visibility = mvPublished then
    begin
      LField := AQuery.FieldByName(LProperty.Name);
      case LProperty.PropertyType.TypeKind of
        tkInteger: LProperty.SetValue(AInstance, LField.AsInteger);
        tkChar,
        tkString,
        tkUString,
        tkWString,
        tkWideChar: LProperty.SetValue(AInstance, LField.AsString);
        tkFloat:
          if (LProperty.PropertyType.Name = 'TDateTime')
            and (LField.AsString <> '') then
            LProperty.SetValue(AInstance, ISO8601ToDate(LField.AsString));
      end;
    end;
  end;
  AInstance.DataState := dsClean;
end;

procedure TContext.Load(
  const AList: TDataObjectList;
  const ACriteria: string
);
var
  LProperties: TArray<TRttiProperty>;
  LType: TRTTIType;
  LQuery: IQuery;
  LInstance: TDataObject;
  LStatementBuilder: IStatementBuilder;
begin
  AList.Clear;
  LType := FRTTIContext.GetType(AList.ListClass);
  LProperties := LType.GetProperties;

  LQuery := FConnection.CreateQuery;
  LStatementBuilder := FStatementCache.GetStatement(stSelect, AList.ListClass);
  if ACriteria <> '' then
    LStatementBuilder.AddAdditionalWhereAnd(ACriteria);
  LQuery.SQL := LStatementBuilder.Generate;
  LQuery.Open;
  while not LQuery.EOF do
  begin
    LInstance := AList.ListClass.Create;
    LoadProperties(LInstance, LProperties, LQuery);
    AList.Add(LInstance);
    LQuery.Next;
  end;
end;

function TContext.Load(
  const ADataObject: TDataObject;
  const AID: integer
): boolean;
var
  LProperties: TArray<TRttiProperty>;
  LIdentityProperty: TRttiProperty;
  LType: TRTTIType;
  LQuery: IQuery;
  LStatementBuilder: IStatementBuilder;

  function FindIdentityProperty: TRttiProperty;
  var
    LProperty: TRttiProperty;
  begin
    for LProperty in LProperties do
      if IsIdentityProperty(LProperty)
        and (LProperty.PropertyType.TypeKind in [tkInteger, tkInt64]) then
        Exit(LProperty);
    raise EDataObjectMustHaveIntegerIdentity.CreateFmt(CMustHaveIntegerIdentityProperty, [ADataObject.ClassName]);
  end;

begin
  LType := FRTTIContext.GetType(ADataObject.ClassType);
  LProperties := LType.GetProperties;

  LQuery := FConnection.CreateQuery;
  LStatementBuilder := FStatementCache.GetStatement(stSelect, TDataObjectClass(ADataObject.ClassType));

  LIdentityProperty := FindIdentityProperty;

  LStatementBuilder.AddAdditionalWhereAnd(
    LIdentityProperty.Name + ' = :' + LIdentityProperty.Name
  );

  LQuery.SQL := LStatementBuilder.Generate;

  LQuery.ParamByName(LIdentityProperty.Name).AsInteger := AID;

  LQuery.Open;
  result := not LQuery.EOF;
  if result then
  begin
    LoadProperties(
      ADataObject,
      LProperties,
      LQuery
    );
  end;
end;

procedure TContext.Save(const ADataObject: TDataObject);
var
  LQuery: IQuery;
  LTypeInfo: TRttiType;
begin
  LTypeInfo := FRTTIContext.GetType(ADataObject.ClassType);
  LQuery := FConnection.CreateQuery;
  LQuery.SQL := FStatementCache.GetStatement(
    CStateToStatementTypeMap[ADataObject.DataState],
    TDataObjectClass(ADataObject.ClassType)
  ).Generate;
  if not ADataObject.IsDirty then Exit;
  SaveObject(
    ADataObject,
    LTypeInfo,
    LQuery
  );
end;

procedure TContext.SaveObject(
  const AObject: TDataObject;
  const ATypeInfo: TRttiType;
  const AQuery: IQuery
);
var
  LProperty: TRttiProperty;
  LIdentityProperty: TRttiProperty;
  LParam: IParam;
begin
  LIdentityProperty := nil;
  for LProperty in ATypeInfo.GetProperties do
  begin
    if (LProperty.Visibility = mvPublished)
      and AQuery.FindParam(LProperty.Name, LParam) then
    begin
      case LProperty.PropertyType.TypeKind of
        tkInteger: LParam.AsInteger := LProperty.GetValue(AObject).AsInteger;
        tkChar,
        tkString,
        tkUString,
        tkWString,
        tkWideChar: LParam.AsString := LProperty.GetValue(AObject).AsString;
        tkFloat:
          if LProperty.PropertyType.Name = 'TDateTime' then
            LParam.AsString := DateToISO8601(LProperty.GetValue(AObject).AsExtended);
      end;
    end;
    if IsIdentityProperty(LProperty) then
    begin
      if Assigned(LIdentityProperty) then
        raise EOnlyOneIdentityPropertyAllowed.Create(COnlyOneIdentityPropertyAllowed);
      LIdentityProperty := LProperty;
    end;
  end;

  AQuery.Execute;

  if Assigned(LIdentityProperty) then
  begin
    LIdentityProperty.SetValue(AObject, FConnection.GetLastIdentityValue);
  end;
  AObject.DataState := dsClean;
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

begin
  LInsertQuery := nil;
  LUpdateQuery := nil;
  LTypeInfo := FRTTIContext.GetType(AList.ListClass);
  for LObject in AList do
  begin
    if not LObject.IsDirty then Continue;
    SaveObject(
      LObject,
      LTypeInfo,
      PopulateQuery(CStateToStatementTypeMap[LObject.DataState])
    );
  end;
end;

end.
