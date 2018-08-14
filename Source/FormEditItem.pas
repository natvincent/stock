unit FormEditItem;

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
  VirtualTrees,
  Vcl.StdCtrls,
  Stock.Interfaces,
  Persistence.Interfaces;

type
  TEditItemForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    NameEdit: TEdit;
    DescriptionMemo: TMemo;
    Label3: TLabel;
    OnHandEdit: TEdit;
    OKButton: TButton;
    CancelButton: TButton;
    Label5: TLabel;
    ProductIDEdit: TEdit;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FController: IEditItemController;
    procedure SetController(const Value: IEditItemController);
  public
    procedure Load;

    property Controller: IEditItemController read FController write SetController;
  end;

function ShowItemEditor(
  const AContext: IContext;
  const AStockItemID: integer
): boolean;

function ShowNewItemEditor(
  const AContext: IContext
): boolean;

implementation

uses
  Stock.EditItemController,
  Stock.Domain,
  Vcl.GraphUtil;

{$R *.dfm}

function ShowItemEditor(
  const AContext: IContext;
  const AStockItemID: integer
): boolean;
var
  LForm: TEditItemForm;
begin
  LForm := TEditItemForm.Create(nil);
  try
    LForm.Controller := TEditItemController.Create(AContext);
    LForm.Controller.LoadItem(AStockItemID);
    LForm.Load;
    result := LForm.ShowModal = mrOK;
  finally
    LForm.Free;
  end;
end;

function ShowNewItemEditor(
  const AContext: IContext
): boolean;
var
  LForm: TEditItemForm;
begin
  LForm := TEditItemForm.Create(nil);
  try
    LForm.Controller := TEditItemController.Create(AContext);
    LForm.Controller.NewItem;
    LForm.Load;
    result := LForm.ShowModal = mrOK;
  finally
    LForm.Free;
  end;
end;

{ TEditItemForm }

procedure TEditItemForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  LNewStockLevel: integer;
begin
    if ModalResult = mrOK then
  begin
    if not TryStrToInt(OnHandEdit.Text, LNewStockLevel) then
    begin
      CanClose := False;
      if OnHandEdit.CanFocus then
        OnHandEdit.SetFocus;
      MessageDlg('Please provide a stock level for this item as a whole number.', mtError, [mbOK], 0);
      Exit;
    end;

    FController.Item.ProductID := ProductIDEdit.Text;
    FController.Item.Name := NameEdit.Text;
    FController.Item.Description := DescriptionMemo.Lines.Text;
    FController.StockLevel := LNewStockLevel;
    FController.SaveItem;
  end;
end;

procedure TEditItemForm.Load;
begin
  ProductIDEdit.Text := Controller.Item.ProductID;
  NameEdit.Text := Controller.Item.Name;
  DescriptionMemo.Lines.Text := Controller.Item.Description;
  OnHandEdit.Text := IntToStr(Controller.StockLevel);
  if FController.IsNewItem then
    Caption := 'New Item';
end;

procedure TEditItemForm.SetController(const Value: IEditItemController);
begin
  FController := Value;
end;

end.
