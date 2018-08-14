unit Stock.HistoryController;

interface

uses
  Stock.Interfaces,
  Stock.Domain,
  Persistence.Interfaces;

type

  TStockHistoryController = class (TInterfacedObject, IStockHistoryController)
  private
    FContext: IContext;
    FStockHistory: TStockLevelList;
    FItem: TStockItem;
    function GetLevelHistory: TStockLevelList;
    function GetItem: TStockItem;
    procedure Load(const AStockItemID: Integer);
  public
    constructor Create(const AContext: IContext);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Persistence.Types;

{ TStockHistoryController }

constructor TStockHistoryController.Create(const AContext: IContext);
begin
  inherited Create;
  FContext := AContext;
  FStockHistory := TStockLevelList.Create;
  FItem := TStockItem.Create;
end;

destructor TStockHistoryController.Destroy;
begin
  FStockHistory.Free;
  inherited;
end;

function TStockHistoryController.GetLevelHistory: TStockLevelList;
begin
  Result := FStockHistory;
end;

function TStockHistoryController.GetItem: TStockItem;
begin
  result := FItem;
end;

procedure TStockHistoryController.Load(const AStockItemID: Integer);
begin
  FContext.Load(FItem, AStockItemID);
  FContext.Load(FStockHistory, Format('StockItemID = %d', [AStockItemID]));
  if FStockHistory.Count > 0 then
  begin
    FStockHistory.Sort(
      TDelegatedComparer<TDataObject>.Create(
        function(const Left, Right: TDataObject): Integer
        begin
          result := TStockLevel(Right).StockLevelID - TStockLevel(Left).StockLevelID;
        end
      )
    );
  end;
end;

end.
