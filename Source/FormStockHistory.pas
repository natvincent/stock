unit FormStockHistory;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  VirtualTrees,
  Stock.Interfaces,
  Vcl.GraphUtil,
  Persistence.Interfaces;

type

  TStockHistoryForm = class(TForm)
    Label1: TLabel;
    ProductIDLabel: TLabel;
    Label3: TLabel;
    NameLabel: TLabel;
    StockLevelTree: TVirtualStringTree;
    CloseButton: TButton;
    procedure StockLevelTreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure StockLevelTreeBeforeItemErase(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
      var ItemColor: TColor; var EraseAction: TItemEraseAction);
    procedure StockLevelTreeGetText(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: string);
  private
    FController: IStockHistoryController;

  public
    procedure Load;

    property Controller: IStockHistoryController read FController write FController;
  end;

procedure ShowStockHistoryForItem(
  const AContext: IContext;
  const AStockItemID: integer
);

implementation

uses
  Stock.Domain,
  Stock.HistoryController;

{$R *.dfm}

procedure ShowStockHistoryForItem(
  const AContext: IContext;
  const AStockItemID: integer
);
var
  LForm: TStockHistoryForm;
begin
  LForm := TStockHistoryForm.Create(nil);
  try
    LForm.Controller := TStockHistoryController.Create(AContext);
    LForm.Controller.Load(AStockItemID);
    LForm.Load;
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

const
  COnHandColumn = 0;
  CDateTimeColumn = 1;

{ TStockHistoryForm }

procedure TStockHistoryForm.Load;
begin
  ProductIDLabel.Caption := FController.Item.ProductID;
  NameLabel.Caption := FController.Item.Name;
  StockLevelTree.RootNodeCount := Controller.StockHistory.Count;
  StockLevelTree.ReinitNode(nil, True);
  StockLevelTree.Invalidate;
end;

procedure TStockHistoryForm.StockLevelTreeBeforeItemErase(
  Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
  ItemRect: TRect; var ItemColor: TColor; var EraseAction: TItemEraseAction);
begin
  if Node.Index mod 2 = 0 then
    ItemColor := GetShadowColor(StockLevelTree.Color, -10);
end;

procedure TStockHistoryForm.StockLevelTreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  LLevel: TStockLevel;
begin
  LLevel := Node.GetData<TStockLevel>;
  case Column of
    COnHandColumn: CellText := IntToStr(LLevel.OnHand);
    CDateTimeColumn: CellText := FormatDateTime('ddddd', LLevel.DateTime) + ' ' + FormatDateTime('t', LLevel.DateTime);
  end;
end;

procedure TStockHistoryForm.StockLevelTreeInitNode(Sender: TBaseVirtualTree;
  ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Node.SetData<TStockLevel>(FController.StockHistory[Node.Index]);
end;

end.
