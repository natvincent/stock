unit Stock.Interfaces;

interface

uses
  Stock.Domain,
  System.Classes;

type

  IStockListController = interface
    ['{2FF350CC-4209-407F-B587-09E73D4CCEA8}']
    {$REGION 'Getters and Setters'}
    function GetOnListChanged: TNotifyEvent;
    procedure SetOnListChanged(const AEvent: TNotifyEvent);
    function GetStockList: TStockItemList;
    {$ENDREGION}

    procedure Load;

    property StockList: TStockItemList read GetStockList;

    property OnListChanged: TNotifyEvent read GetOnListChanged write SetOnListChanged;
  end;

implementation

end.
