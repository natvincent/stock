unit Persistence.Types;

interface

uses
  Data.DB,
  System.Generics.Collections;

type

  TDataState = (dsClean, dsDirty, dsNew);

  TTableNameAttribute = class (TCustomAttribute)
  private
    FTableName: string;
  public
    constructor Create(const ATableName: string);

    property TableName: string read FTableName;
  end;
  TableNameAttribute = TTableNameAttribute;

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

    function Add(const ADataObject: TDataObject): integer;
    procedure Delete(const AIndex: integer);

    property Items[const AIndex: integer]: TDataObject read GetItem; default;
    property Count: integer read GetCount;

  end;

  TDataObjectList<T: TDataObject> = class (TDataObjectList)
  private
    function GetItem(const AIndex: integer): T;
  public
    function ListClass: TDataObjectClass; override;

    function Add(const ADataObject: T): integer;

    property Items[const AIndex: integer]: T read GetItem; default;

  end;

implementation

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

function TDataObjectList.GetCount: integer;
begin
  result := FList.Count;
end;

function TDataObjectList.GetItem(const AIndex: integer): TDataObject;
begin
  result := FList[AIndex];
end;

{ TTableNameAttribute }

constructor TTableNameAttribute.Create(const ATableName: string);
begin
  inherited Create;
  FTableName := ATableName;
end;

end.
