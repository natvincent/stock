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
    FRTTIContext: TRTTIContext;
    procedure Load(const AList: TDataObjectList);
    function AssembleSelect(
      const AProperties: TArray<TRttiProperty>;
      const AListClass: TDataObjectClass
    ): string;
  public
    constructor Create(const AConnectionFactory: IConnectionFactory);
  end;

implementation

{ TContext }

constructor TContext.Create(const AConnectionFactory: IConnectionFactory);
begin
  inherited Create;
  FRTTIContext := TRttiContext.Create;
  FConnection := AConnectionFactory.CreateConnection;
end;

function TContext.AssembleSelect(
  const AProperties: TArray<TRttiProperty>;
  const AListClass: TDataObjectClass
): string;

  function FindTableName: string;
  var
    LAttribute: TCustomAttribute;
  begin
    for LAttribute in FRTTIContext.GetType(AListClass).GetAttributes do
    begin
      if LAttribute is TTableNameAttribute then
        Exit(TTableNameAttribute(LAttribute).TableName);
      raise EContextException.CreateFmt('The class %s must be decorated with a TableName attribute', [AListClass.ClassName]);
    end;
  end;

var
  LProperty: TRttiProperty;
  LLineSeperator: string;
const
  CLineSeperator = ',' + #13#10;
begin
  if Length(AProperties) = 0 then
    raise EContextException.CreateFmt('The type %s must have published properties to be loaded', [AListClass.ClassName]);

  Assert(Length(AProperties) > 0, '');
  result := 'select'+ #13#10;
  for LProperty in AProperties do
  begin
    result := result + LLineSeperator + '  ' + LProperty.Name;
    LLineSeperator := CLineSeperator;
  end;
  result := result
    + #13#10 + 'from'
    + #13#10 + '  ' + FindTableName;
end;

procedure TContext.Load(const AList: TDataObjectList);
var
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LType: TRTTIType;
  LSQL: string;
  LQuery: IQuery;
  LInstance: TDataObject;

begin
  LType := FRTTIContext.GetType(AList.ListClass);
  LProperties := LType.GetDeclaredProperties;

  LQuery := FConnection.CreateQuery;
  LQuery.SQL := AssembleSelect(LProperties, AList.ListClass);
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
    AList.Add(LInstance);
  end;
end;

end.
