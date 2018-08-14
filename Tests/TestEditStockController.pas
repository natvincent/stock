unit TestEditStockController;

interface

uses
  DUnitX.TestFramework,
  Persistence.Interfaces,
  Delphi.Mocks,
  Stock.Interfaces,
  Stock.Domain;

type

  [TestFixture]
  TTestEditStockController = class
  private
    FContext: TMock<IContext>;

  public
    [Setup] procedure Setup;

    [Test] procedure LoadItem;
    [Test] procedure NewItem;
    [Test] procedure SaveItem;
    [Test] procedure DontLevelWhenNoChange;
    [Test] procedure IsNew;
  end;

implementation

uses
  System.Rtti,
  Stock.EditItemController,
  System.DateUtils,
  Persistence.Types;

{ TTestEditStockController }

procedure TTestEditStockController.DontLevelWhenNoChange;
var
  LController: IEditItemController;
begin
  FContext.Setup
    .Expect.Exactly('Save', 1);
  FContext.Setup
    .WillExecute(
      'Save',
      function(const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        Assert.IsTrue(args[1].IsObject);
        if args[1].AsObject is TStockLevel then
        begin
          Assert.Fail();
        end;
      end
    );

  LController := TEditItemController.Create(FContext);

  LController.StockLevel := 0;  //same as the default

  LController.SaveItem;

  Assert.AreEqual('', FContext.CheckExpectations);
end;

procedure TTestEditStockController.IsNew;
var
  LController: IEditItemController;
begin
  LController := TEditItemController.Create(FContext);

  Assert.IsFalse(LController.IsNewItem);

  LController.NewItem;

  Assert.IsTrue(LController.IsNewItem);
end;

procedure TTestEditStockController.LoadItem;
var
  LController: IEditItemController;
const
  CTestStockItemID = 42;
begin
  FContext.Setup
    .Expect.Exactly('Load', 2);
  FContext.Setup
    .WillExecute(
      'Load',
      function(const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      var
        LItem: TStockItem;
        LOnHand: TStockItemsOnHand;
      begin
        Assert.IsTrue(args[1].IsObject);
        if args[1].AsObject is TStockItem then
        begin
          Assert.AreEqual(CTestStockItemID, args[2].AsInteger);
          LItem := TStockItem(args[1].AsObject);

          LItem.StockItemID := CTestStockItemID;
          LItem.Name := 'Carrots';
          LItem.Description := 'Orange';
        end
        else if args[1].AsObject is TStockItemsOnHand then
        begin
          Assert.AreEqual(CTestStockItemID, args[2].AsInteger);
          LOnHand := TStockItemsOnHand(args[1].AsObject);
          LOnHand.OnHand := 20;
        end;
      end
    );

  LController := TEditItemController.Create(FContext);

  LController.LoadItem(CTestStockItemID);

  Assert.AreEqual(CTestStockItemID, LController.Item.StockItemID);
  Assert.AreEqual(20, LController.StockLevel);

  Assert.AreEqual('', FContext.CheckExpectations);

end;

procedure TTestEditStockController.NewItem;
var
  LController: IEditItemController;
begin
  LController := TEditItemController.Create(FContext);

  LController.NewItem;

  Assert.AreEqual(dsNew, LController.Item.DataState);

end;

procedure TTestEditStockController.SaveItem;
var
  LController: IEditItemController;
  LSaveItem: boolean;
  LSaveLevel: boolean;
begin
  LSaveItem := False;
  LSaveLevel := False;
  FContext.Setup
    .Expect.Exactly('Save', 2);
  FContext.Setup
    .WillExecute(
      'Save',
      function(const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      var
        LLevel: TStockLevel;
      begin
        Assert.IsTrue(args[1].IsObject);
        if args[1].AsObject is TStockItem then
        begin
          LSaveItem := True;
        end
        else if args[1].AsObject is TStockLevel then
        begin
          LLevel := TStockLevel(args[1].AsObject);
          Assert.AreEqual(100, LLevel.StockItemID);
          Assert.AreNotEqual<TDateTime>(0, LLevel.DateTime);
          Assert.AreEqual(dsNew, LLevel.DataState);
          LSaveLevel := True;
        end;
      end
    );

  LController := TEditItemController.Create(FContext);

  LController.Item.StockItemID := 100;

  LController.StockLevel := 50;

  LController.SaveItem;

  Assert.AreEqual('', FContext.CheckExpectations);
  Assert.IsTrue(LSaveItem);
  Assert.IsTrue(LSaveLevel);
end;

procedure TTestEditStockController.Setup;
begin
  FContext := TMock<IContext>.Create;
end;

end.
