unit Stock.Domain;

interface

uses
  Persistence.Types;

type

  [TableName('Stock')]
  TStockItem = class (TDataObject)
  private
    FStockItemID: integer;
    FName: string;
    FDescription: string;
    procedure SetStockItemID(const Value: integer);
    procedure SetName(const Value: string);
    procedure SetDescription(const Value: string);
  published
    [IdentityField]
    property StockItemID: integer read FStockItemID write SetStockItemID;
    property Name: string read FName write SetName;
    property Description: string read FDescription write SetDescription;
  end;

  TStockItemList = class (TDataObjectList<TStockItem>);

  TStockLevel = class (TDataObject)
  private
    FLastChanged: TDateTime;
    FOnHand: integer;
    FStockLevelID: integer;
    FStockItemID: integer;
    procedure SetLastChanged(const Value: TDateTime);
    procedure SetOnHand(const Value: integer);
    procedure SetStockLevelID(const Value: integer);
    procedure SetStockItemID(const Value: integer);
  published
    property StockLevelID: integer read FStockLevelID write SetStockLevelID;
    property StockItemID: integer read FStockItemID write SetStockItemID;
    property OnHand: integer read FOnHand write SetOnHand;
    property LastChanged: TDateTime read FLastChanged write SetLastChanged;
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
    property LastLevelChange: TDateTime read FLastLevelChanged write SetLastLevelChanged;
  end;

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

procedure TStockLevel.SetLastChanged(const Value: TDateTime);
begin
  if Value = FLastChanged then Exit; //======>
  FLastChanged := Value;
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
