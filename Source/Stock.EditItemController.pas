unit Stock.EditItemController;

interface

uses
  Stock.Interfaces,
  Persistence.Interfaces,
  Stock.Domain;

type

  TEditItemController = class (TInterfacedObject, IEditItemController)
  private
    FContext: IContext;
    FStockItem: TStockItem;
    FStockLevel: integer;
    FOnHand: TStockItemsOnHand;
    FLevelChanged: boolean;
    function GetItem: TStockItem;
    function GetStockLevel: Integer;
    procedure SetStockLevel(const ALevel: Integer);
    procedure LoadItem(const AStockItemID: Integer);
    procedure SaveItem;
    procedure NewItem;
    function GetIsNewItem: Boolean;
  public
    constructor Create(const AContext: IContext);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  Persistence.Types,
  System.Generics.Defaults;

{ TEditItemController }

constructor TEditItemController.Create(const AContext: IContext);
begin
  inherited Create;
  FContext := AContext;
  FStockItem := TStockItem.Create;
  FOnHand := TStockItemsOnHand.Create;
end;

destructor TEditItemController.Destroy;
begin
  FOnHand.Free;
  FStockItem.Free;
  inherited;
end;

function TEditItemController.GetIsNewItem: Boolean;
begin
  result := FStockItem.DataState = dsNew;
end;

function TEditItemController.GetItem: TStockItem;
begin
  result := FStockItem;
end;

function TEditItemController.GetStockLevel: Integer;
begin
  result := FStockLevel;
end;

procedure TEditItemController.LoadItem(const AStockItemID: Integer);
begin
  FContext.Load(FStockItem, AStockItemID);
  FContext.Load(FOnHand, AStockItemID);
  FStockLevel := FOnHand.OnHand;
end;

procedure TEditItemController.NewItem;
begin
  FStockItem.DataState := dsNew;
end;

procedure TEditItemController.SaveItem;
var
  LNewLevel: TStockLevel;
begin
  FContext.Save(FStockItem);
  if FLevelChanged then
  begin
    LNewLevel := TStockLevel.CreateNew;
    try
      LNewLevel.OnHand := FStockLevel;
      LNewLevel.StockItemID := FStockItem.StockItemID;
      LNewLevel.DateTime := Now;
      FContext.Save(LNewLevel);
    finally
      LNewLevel.Free;
    end;
  end;
end;

procedure TEditItemController.SetStockLevel(const ALevel: Integer);
begin
  if ALevel = FStockLevel then Exit; //======>
  FStockLevel := ALevel;
  FLevelChanged := True;
end;

end.
