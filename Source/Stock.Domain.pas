unit Stock.Domain;

interface

uses
  Persistence.Types;

type

  {$m+}
  [TableName('Stock')]
  TStockItem = class (TDataObject)
  private
    FStockItemID: integer;
    FName: string;
    FDescription: string;
    FProductID: string;
    procedure SetStockItemID(const Value: integer);
    procedure SetName(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetProductID(const Value: string);
  published
    [IdentityField]
    property StockItemID: integer read FStockItemID write SetStockItemID;
    property ProductID: string read FProductID write SetProductID;
    property Name: string read FName write SetName;
    property Description: string read FDescription write SetDescription;
  end;

  TStockItemList = class (TDataObjectList<TStockItem>);

  [TableName('StockLevels')]
  TStockLevel = class (TDataObject)
  private
    FDateTime: TDateTime;
    FOnHand: integer;
    FStockLevelID: integer;
    FStockItemID: integer;
    procedure SetDateTime(const Value: TDateTime);
    procedure SetOnHand(const Value: integer);
    procedure SetStockLevelID(const Value: integer);
    procedure SetStockItemID(const Value: integer);
  published
    [IdentityField]
    property StockLevelID: integer read FStockLevelID write SetStockLevelID;
    property StockItemID: integer read FStockItemID write SetStockItemID;
    property OnHand: integer read FOnHand write SetOnHand;
    property DateTime: TDateTime read FDateTime write SetDateTime;
  end;

  TStockLevelList = class (TDataObjectList<TStockLevel>);

  TStockListItem = class (TStockItem)
  private
    FOnHand: integer;
    FLastLevelChanged: TDateTime;
    procedure SetLastLevelChanged(const Value: TDateTime);
    procedure SetOnHand(const Value: integer);

  published
    property OnHand: integer read FOnHand write SetOnHand;
    property LastChanged: TDateTime read FLastLevelChanged write SetLastLevelChanged;
  end;

  TStockListItemList = class (TDataObjectList<TStockListItem>);

  TStockItemsOnHand = class (TDataObject)
  private
    FOnHand: integer;
    FStockItemID: integer;
  published
    [IdentityField]
    property StockItemID: integer read FStockItemID write FStockItemID;
    property OnHand: integer read FOnHand write FOnHand;
  end;
  {$m-}

implementation

{ TSockItem }

procedure TStockItem.SetDescription(const Value: string);
begin
  if Value = FDescription then Exit; //======>
  FDescription := Value;
  Changed;
end;

procedure TStockItem.SetName(const Value: string);
begin
  if Value = FName then Exit; //======>
  FName := Value;
  Changed;
end;

procedure TStockItem.SetProductID(const Value: string);
begin
  if Value = FProductID then Exit; //======>
  FProductID := Value;
  Changed;
end;

procedure TStockItem.SetStockItemID(const Value: integer);
begin
  if Value = FStockItemID then Exit; //======>
  FStockItemID := Value;
  Changed;
end;

{ TStockListItem }

procedure TStockListItem.SetLastLevelChanged(const Value: TDateTime);
begin
  if Value = FLastLevelChanged then Exit; //======>
  FLastLevelChanged := Value;
  Changed;
end;

procedure TStockListItem.SetOnHand(const Value: integer);
begin
  if Value = FOnHand then Exit; //======>
  FOnHand := Value;
  Changed;
end;

{ TSockLevel }

procedure TStockLevel.SetDateTime(const Value: TDateTime);
begin
  if Value = FDateTime then Exit; //======>
  FDateTime := Value;
  Changed;
end;

procedure TStockLevel.SetOnHand(const Value: integer);
begin
  if Value = FOnHand then Exit; //======>
  FOnHand := Value;
  Changed;
end;

procedure TStockLevel.SetStockItemID(const Value: integer);
begin
  if Value = FStockItemID then Exit; //======>
  FStockItemID := Value;
  Changed;
end;

procedure TStockLevel.SetStockLevelID(const Value: integer);
begin
  if Value = FStockLevelID then Exit; //======>
  FStockLevelID := Value;
  Changed;
end;

end.
