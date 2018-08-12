unit Stock.StockListController;

interface

uses
  Stock.Interfaces,
  Persistence.Interfaces,
  Stock.Domain,
  System.Classes;

type

  TStockListController = class (TInterfacedObject, IStockListController)
  private
    FOnListChanged: TNotifyEvent;
    FContext: IContext;
    FStockList: TStockItemList;
    function GetOnListChanged: TNotifyEvent;
    procedure SetOnListChanged(const AEvent: TNotifyEvent);
    function GetStockList: TStockItemList;

    procedure Load;

  protected
    procedure DoListChanged;

  public
    constructor Create(
      const AContext: IContext;
      const AStockList: TStockItemList
    );
    destructor Destroy; override;

  end;

implementation

{ TStockListController }

constructor TStockListController.Create(
  const AContext: IContext;
  const AStockList: TStockItemList
);
begin
  inherited Create;
  FContext := AContext;
  FStockList := AStockList;
end;

destructor TStockListController.Destroy;
begin
  FStockList.Free;
  inherited;
end;

procedure TStockListController.DoListChanged;
begin
  if Assigned(FOnListChanged) then
    FOnListChanged(self);
end;

function TStockListController.GetOnListChanged: TNotifyEvent;
begin
  Result := FOnListChanged;
end;

function TStockListController.GetStockList: TStockItemList;
begin
  result := FStockList;
end;

procedure TStockListController.Load;
begin
  FContext.Load(FStockList);
  DoListChanged;
end;

procedure TStockListController.SetOnListChanged(const AEvent: TNotifyEvent);
begin
  FOnListChanged := AEvent;
end;

end.
