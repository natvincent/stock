unit TestStockHistoryController;

interface

uses
  DUnitX.TestFramework,
  Persistence.Interfaces,
  Delphi.Mocks,
  Stock.Interfaces,
  Stock.Domain;

type

  [TestFixture]
  TTestStockHistoryController = class
  private
    FContext: TMock<IContext>;
  public
    [Setup] procedure Setup;
    [Test] procedure LoadItemHistory;
  end;

implementation

uses
  System.Rtti,
  System.DateUtils,
  Stock.HistoryController;

procedure TTestStockHistoryController.LoadItemHistory;
var
  LController: IStockHistoryController;
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
        LLevel: TStockLevel;
        LLevelList: TStockLevelList;
      begin
        Assert.IsTrue(args[1].IsObject);
        if args[1].AsObject is TStockLevelList then
        begin
          Assert.AreEqual('StockItemID = 42', args[2].AsString);

          LLevelList := TStockLevelList(args[1].AsObject);

          LLevel := TStockLevel.Create;
          LLevel.StockLevelID:= 1;
          LLevel.OnHand := 10;
          LLevel.DateTime := ISO8601ToDate('2018-08-13T18:00');
          LLevelList.Add(LLevel);

          LLevel := TStockLevel.Create;
          LLevel.StockLevelID:= 2;
          LLevel.OnHand := 20;
          LLevel.DateTime := ISO8601ToDate('2018-08-13T17:00');
          LLevelList.Add(LLevel);
        end
        else if args[1].AsObject is TStockItem then
        begin
          LItem := TStockItem(args[1].AsObject);

          LItem.ProductID := '123456789';
          LItem.Name := 'Cornflakes';
        end;
      end
    );

  LController := TStockHistoryController.Create(FContext);

  LController.Load(CTestStockItemID);

  Assert.AreEqual(2, LController.StockHistory.Count);
  Assert.AreEqual(2, LController.StockHistory[0].StockLevelID);
  Assert.AreEqual(1, LController.StockHistory[1].StockLevelID);

  Assert.AreEqual('123456789', LController.Item.ProductID);
  Assert.AreEqual('Cornflakes', LController.Item.Name);

  Assert.AreEqual('', FContext.CheckExpectations);

end;

procedure TTestStockHistoryController.Setup;
begin
  FContext := TMock<IContext>.Create;
end;

end.
