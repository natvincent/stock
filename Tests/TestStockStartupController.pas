unit TestStockStartupController;

interface

uses
  DUnitX.TestFramework,
  Persistence.Interfaces,
  Delphi.Mocks,
  Stock.Interfaces;

type

  [TestFixture]
  TTestStockStartupController = class
  private
    FConnectionFactory: TMock<IConnectionFactory>;
    FConnection: TMock<IConnection>;
    FStatementBuilderFactory: TMock<IStatementBuilderFactory>;
    FEchoBuilder: TMock<IStatementBuilder>;
    FStatementCache: TMock<IStatementCache>;

  public
    [Setup] procedure Setup;

    [Test] procedure RegisterQueries;
    [Test] procedure ChooseDataLocationBasedOnStartupFolder;
    [Test] procedure SetupContext;
  end;


implementation

uses
  Stock.StartupController,
  Stock.DomainQueries,
  Stock.Domain,
  Persistence.Types;

{ TTestStockStartupController }

const
  CStartLocationInProgramFiles = 'C:\Program Files (x86)\Stock\';
  CStartLocationOutsideProgramFiles = 'C:\Projects\Stock\';
  CDataLocationInProgramData = 'C:\ProgramData\Stock\Stock.sdb';

procedure TTestStockStartupController.ChooseDataLocationBasedOnStartupFolder;
var
  LController: IStockStartupController;
begin
  LController := TStockStartupController.Initialise(
    FConnectionFactory,
    FStatementBuilderFactory,
    FStatementCache,
    CStartLocationInProgramFiles
  );

  Assert.AreEqual('C:\ProgramData\Stock\', LController.DataLocation);

  LController := TStockStartupController.Initialise(
    FConnectionFactory,
    FStatementBuilderFactory,
    FStatementCache,
    CStartLocationOutsideProgramFiles
  );

  Assert.AreEqual(CStartLocationOutsideProgramFiles + 'Data\', LController.DataLocation);
end;

procedure TTestStockStartupController.RegisterQueries;
var
  LController: IStockStartupController;
begin
  FStatementBuilderFactory.Setup
    .Expect.Exactly(1).When.CreateEchoBuilder(CStockListItemSelect);

  FStatementBuilderFactory.Setup
    .Expect.Exactly(1).When.CreateEchoBuilder(CStockItemsOnHand);

  FStatementCache := TMock<IStatementCache>.Create;

  LController := TStockStartupController.Initialise(
    FConnectionFactory,
    FStatementBuilderFactory,
    FStatementCache,
    CStartLocationOutsideProgramFiles
  );

  Assert.AreEqual('', FStatementBuilderFactory.CheckExpectations);
  Assert.AreEqual('', FStatementCache.CheckExpectations);
end;

procedure TTestStockStartupController.Setup;
begin
  FEchoBuilder := TMock<IStatementBuilder>.Create;

  FStatementBuilderFactory := TMock<IStatementBuilderFactory>.Create;
  FStatementBuilderFactory.Setup
    .WillReturnDefault('CreateEchoBuilder', FEchoBuilder.InstanceAsValue);

  FStatementCache := TMock<IStatementCache>.Create;

  FConnection := TMock<IConnection>.Create;

  FConnectionFactory := TMock<IConnectionFactory>.Create;
  FConnectionFactory.Setup
    .WillReturn(FConnection.InstanceAsValue).When.CreateConnection;
end;

procedure TTestStockStartupController.SetupContext;
var
  LController: IStockStartupController;
  LContext: IContext;
begin
  FConnectionFactory.Setup
    .Expect.Once.When.SetDatabasePath(CDataLocationInProgramData);

  FConnectionFactory.Setup
    .Expect.Once.When.CreateConnection;

  LController := TStockStartupController.Initialise(
    FConnectionFactory,
    FStatementBuilderFactory,
    FStatementCache,
    CStartLocationInProgramFiles
  );

  LContext := LController.CreateContext;

  Assert.IsNotNull(LContext);

  Assert.AreEqual('', FConnectionFactory.CheckExpectations);

end;

end.
