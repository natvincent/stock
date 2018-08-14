unit TestStockListController;

interface

uses
  DUnitX.TestFramework,
  Persistence.Interfaces,
  Delphi.Mocks,
  Stock.Interfaces,
  Stock.Domain;

type

  [TestFixture]
  TTestStockListController = class
  private
    FContext: TMock<IContext>;

    FListChangedCalled: integer;

    procedure ControllerListChanged(ASender: TObject);
  public
    [Setup] procedure Setup;

    [Test] procedure ContextPassedThrough;
    [Test] procedure LoadList;
  end;

implementation

uses
  Stock.StockListController,
  System.Rtti;

{ TTestStockListController }

procedure TTestStockListController.ContextPassedThrough;
var
  LController: IStockListController;
begin
  LController := TStockListController.Create(FContext);
  Assert.AreSame(LController.Context, FContext.Instance);
end;

procedure TTestStockListController.ControllerListChanged(ASender: TObject);
begin
  inc(FListChangedCalled);
end;

procedure TTestStockListController.LoadList;
var
  LController: IStockListController;
begin
  FContext.Setup
    .Expect.Once('Load');
  FContext.Setup
    .WillExecute(
      'Load',
      function(const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      var
        LList: TStockListItemList;
        LItem: TStockListItem;
      begin
        Assert.IsTrue(
          args[1].IsObject
          and (args[1].AsObject is TStockListItemList)
        );
        LList := TStockListItemList(args[1].AsObject);

        LItem := TStockListItem.Create;
        LItem.Name := 'Carrots';
        LItem.Description := 'Orange';

        LList.Add(LItem);
      end
    );

  LController := TStockListController.Create(
    FContext
  );

  LController.OnListChanged := ControllerListChanged;

  LController.Load;

  Assert.AreEqual(1, LController.StockList.Count);
  Assert.AreEqual('Carrots', LController.StockList[0].Name);
  Assert.AreEqual('Orange', LController.StockList[0].Description);
  Assert.AreEqual('', FContext.CheckExpectations);
  Assert.AreEqual(1, FListChangedCalled);

end;

procedure TTestStockListController.Setup;
begin
  FListChangedCalled := 0;
  FContext := TMock<IContext>.Create;
end;

end.
