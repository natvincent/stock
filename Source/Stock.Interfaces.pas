unit Stock.Interfaces;

interface

uses
  Stock.Domain,
  System.Classes,
  Persistence.Interfaces;

type

  IStockListController = interface
    ['{2FF350CC-4209-407F-B587-09E73D4CCEA8}']
    {$REGION 'Getters and Setters'}
    function GetOnListChanged: TNotifyEvent;
    procedure SetOnListChanged(const AEvent: TNotifyEvent);
    function GetStockList: TStockListItemList;
    function GetContext: IContext;
    {$ENDREGION}

    procedure Load;

    property StockList: TStockListItemList read GetStockList;
    property Context: IContext read GetContext;

    property OnListChanged: TNotifyEvent read GetOnListChanged write SetOnListChanged;
  end;

  IStockStartupController = interface
    ['{D684D214-7CC9-4AD6-988E-8B6523DC9821}']
    {$REGION 'Getters and Setters'}
    function GetDataLocation: string;
    {$ENDREGION}

    function CreateContext: IContext;

    property DataLocation: string read GetDataLocation;
  end;

  IEditItemController = interface
    ['{54917E1B-86A3-4B64-A79A-D3DC40DBE418}']
    {$REGION 'Getters and Setters'}
    function GetItem: TStockItem;
    function GetStockLevel: integer;
    procedure SetStockLevel(const ALevel: integer);
    {$ENDREGION}

    procedure NewItem;
    procedure LoadItem(const AStockItemID: integer);
    procedure SaveItem;

    property StockLevel: integer read GetStockLevel write SetStockLevel;
    property Item: TStockItem read GetItem;
  end;

  IStockHistoryController = interface
    ['{27C9F02C-8DB6-4A24-8639-033A7578D822}']
    {$REGION 'Getters and Setters'}
    function GetLevelHistory: TStockLevelList;
    function GetItem: TStockItem;
    {$ENDREGION}

    procedure Load(const AStockItemID: integer);

    property Item: TStockItem read GetItem;
    property StockHistory: TStockLevelList read GetLevelHistory;

  end;

implementation

end.
