unit FormMain;

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
  System.Actions,
  Vcl.ActnList,
  Vcl.ToolWin,
  Vcl.ActnMan,
  Vcl.ActnCtrls,
  Vcl.PlatformDefaultStyleActnCtrls,
  VirtualTrees,
  Stock.Interfaces,
  Stock.StockListController, Vcl.Menus, Vcl.ActnPopup, System.ImageList,
  Vcl.ImgList, PngImageList;

type
  TMainForm = class(TForm)
    StockTree: TVirtualStringTree;
    ActionManager: TActionManager;
    ActionToolBar1: TActionToolBar;
    AddItemAction: TAction;
    EditItemAction: TAction;
    StockHistoryAction: TAction;
    Popup: TPopupActionBar;
    AddItem1: TMenuItem;
    EditItem1: TMenuItem;
    StockHistory1: TMenuItem;
    ButtonImages: TPngImageList;
    procedure AddItemActionExecute(Sender: TObject);
    procedure EditItemActionExecute(Sender: TObject);
    procedure StockTreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure StockTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure StockTreeBeforeItemErase(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
      var ItemColor: TColor; var EraseAction: TItemEraseAction);
    procedure EditItemActionUpdate(Sender: TObject);
    procedure StockHistoryActionExecute(Sender: TObject);
    procedure StockHistoryActionUpdate(Sender: TObject);
  private
    FController: IStockListController;
    procedure ControllerListChange(ASender: TObject);
    procedure SetController(const Value: IStockListController);
  public
    property Controller: IStockListController read FController write SetController;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Stock.Domain,
  Vcl.GraphUtil,
  FormEditItem,
  FormStockHistory;

{$R *.dfm}

const
  COnHandColumn = 0;
  CProductIDColumn = 1;
  CNameColumn = 2;
  CDescriptionColumn = 3;

procedure TMainForm.AddItemActionExecute(Sender: TObject);
begin
  if ShowNewItemEditor(
    FController.Context
  ) then
    FController.Load;
end;

procedure TMainForm.ControllerListChange(ASender: TObject);
begin
  StockTree.RootNodeCount := FCOntroller.StockList.Count;
  StockTree.ReinitNode(nil, True);
  StockTree.Invalidate;
end;

procedure TMainForm.EditItemActionExecute(Sender: TObject);
var
  LItem: TStockListItem;
begin
  if Assigned(StockTree.FocusedNode) then
  begin
    LItem := StockTree.FocusedNode.GetData<TStockListItem>;
    if ShowItemEditor(
      FController.Context,
      LItem.StockItemID
    ) then
      FController.Load;
  end;
end;

procedure TMainForm.EditItemActionUpdate(Sender: TObject);
begin
  EditItemAction.Enabled := Assigned(StockTree.FocusedNode);
end;

procedure TMainForm.SetController(const Value: IStockListController);
begin
  if Assigned(FController) then
    FController.OnListChanged := nil;

  FController := Value;

  if Assigned(FController) then
    FController.OnListChanged := ControllerListChange;

  FController.Load;
end;

procedure TMainForm.StockHistoryActionExecute(Sender: TObject);
var
  LItem: TStockListItem;
begin
  if Assigned(StockTree.FocusedNode) then
  begin
    LItem := StockTree.FocusedNode.GetData<TStockListItem>;
    ShowStockHistoryForItem(FController.Context, LItem.StockItemID);
  end;
end;

procedure TMainForm.StockHistoryActionUpdate(Sender: TObject);
begin
  StockHistoryAction.Enabled := Assigned(StockTree.FocusedNode);
end;

procedure TMainForm.StockTreeBeforeItemErase(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
  var ItemColor: TColor; var EraseAction: TItemEraseAction);
begin
  if Node.Index mod 2 = 0 then
    ItemColor := GetShadowColor(StockTree.Color, -10);
end;

procedure TMainForm.StockTreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  LItem: TStockListItem;
begin
  LItem := Node.GetData<TStockListItem>;
  case Column of
    COnHandColumn: CellText := IntToStr(LItem.OnHand);
    CProductIDColumn: CellText := LItem.ProductID;
    CNameColumn: CellText := LItem.Name;
    CDescriptionColumn: CellText := LItem.Description;
  end;
end;

procedure TMainForm.StockTreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Node.SetData<TStockListItem>(FController.StockList[Node.Index]);
end;

end.
