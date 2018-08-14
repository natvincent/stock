unit Persistence.Types;

interface

uses
  Data.DB,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Rtti;

type

  TDataState = (dsClean, dsDirty, dsNew);
  TStatementType = (stSelect, stInsert, stUpdate);

const
  CStateToStatementTypeMap: array [TDataState] of TStatementType = (
    stSelect,
    stUpdate,
    stInsert
  );

type

  TTableNameAttribute = class (TCustomAttribute)
  private
    FTableName: string;
  public
    constructor Create(const ATableName: string);

    property TableName: string read FTableName;
  end;
  TableNameAttribute = TTableNameAttribute;

  TKeyFieldAttribute = class (TCustomAttribute);
  KeyFieldAttribute = TKeyFieldAttribute;

  TIdentityFieldAttribute = class (TKeyFieldAttribute);
  IdentityFieldAttribute = TIdentityFieldAttribute;

  TReadOnlyFieldAttribute = class (TCustomAttribute);
  ReadOnlyFieldAttribute = TReadOnlyFieldAttribute;

  TDataObject = class
  private
    FDataState: TDataState;
    function GetIsDirty: boolean;

  protected
    procedure Changed; virtual;
    procedure DoChanged; virtual;

  public
    constructor CreateNew; virtual;
    constructor Create; virtual;

    property DataState: TDataState read FDataState write FDataState;
    property IsDirty: boolean read GetIsDirty;
  end;

  TDataObjectClass = class of TDataObject;

  TDataObjectList = class
  private
    FList: TObjectList<TDataObject>;
    function GetItem(const AIndex: integer): TDataObject;
    function GetCount: integer;

  public
    constructor Create;
    destructor Destroy; override;

    function ListClass: TDataObjectClass; virtual; abstract;

    function GetEnumerator: TEnumerator<TDataObject>;

    function Add(const ADataObject: TDataObject): integer;
    procedure Delete(const AIndex: integer);
    function Extract(const AIndex: integer): TDataObject;
    procedure Sort(const AComparer: IComparer<TDataObject>); overload;
    procedure Clear;

    property Items[const AIndex: integer]: TDataObject read GetItem; default;
    property Count: integer read GetCount;

  end;

  TDataObjectList<T: TDataObject> = class (TDataObjectList)
  private
    function GetItem(const AIndex: integer): T;
  public
    function ListClass: TDataObjectClass; override;

    function Add(const ADataObject: T): integer;
    function Extract(const AIndex: integer): T;

    property Items[const AIndex: integer]: T read GetItem; default;

  end;

function IsIdentityProperty(const AProperty: TRttiProperty): boolean;
function IsReadOnlyProperty(const AProperty: TRttiProperty): boolean;

implementation

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

function IsReadOnlyProperty(const AProperty: TRttiProperty): boolean;
var
  LAttribute: TCustomAttribute;
begin
  for LAttribute in AProperty.GetAttributes do
  begin
    if LAttribute is TReadOnlyFieldAttribute then
      Exit(True);
  end;
  result := False;
end;


{ TDataObject }

procedure TDataObject.Changed;
begin
  if FDataState = dsClean then
    FDataState := dsDirty;
  DoChanged;
end;

constructor TDataObject.Create;
begin
  inherited Create;
end;

constructor TDataObject.CreateNew;
begin
  inherited Create;
  FDataState := dsNew;
end;

procedure TDataObject.DoChanged;
begin
end;

function TDataObject.GetIsDirty: boolean;
begin
  result := FDataState in [dsNew, dsDirty];
end;

{ TDataObjectList<T> }

function TDataObjectList<T>.Add(const ADataObject: T): integer;
begin
  result := FList.Add(ADataObject);
end;

function TDataObjectList<T>.Extract(const AIndex: integer): T;
begin
  result := T(inherited Extract(AIndex));
end;

function TDataObjectList<T>.GetItem(const AIndex: integer): T;
begin
  result := T(inherited Items[AIndex]);
end;

function TDataObjectList<T>.ListClass: TDataObjectClass;
begin
  result := T;
end;

{ TDataObjectList }

function TDataObjectList.Add(const ADataObject: TDataObject): integer;
begin
  result := FList.Add(ADataObject);
end;

procedure TDataObjectList.Clear;
begin
  FList.Clear;
end;

constructor TDataObjectList.Create;
begin
  inherited Create;
  FList := TObjectList<TDataObject>.Create;
end;

procedure TDataObjectList.Delete(const AIndex: integer);
begin
  FList.Delete(AIndex);
end;

destructor TDataObjectList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TDataObjectList.Extract(const AIndex: integer): TDataObject;
begin
  result := FList.Extract(FList.Items[AIndex]);
end;

function TDataObjectList.GetCount: integer;
begin
  result := FList.Count;
end;

function TDataObjectList.GetEnumerator: TEnumerator<TDataObject>;
begin
  result := FList.GetEnumerator;
end;

function TDataObjectList.GetItem(const AIndex: integer): TDataObject;
begin
  result := FList[AIndex];
end;

procedure TDataObjectList.Sort(const AComparer: IComparer<TDataObject>);
begin
  FList.Sort(AComparer);
end;

{ TTableNameAttribute }

constructor TTableNameAttribute.Create(const ATableName: string);
begin
  inherited Create;
  FTableName := ATableName;
end;

end.
