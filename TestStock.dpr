program TestStock;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  TestPersistence in 'Tests\TestPersistence.pas',
  Persistence.FireDac.SQLite in 'Source\Persistence.FireDac.SQLite.pas',
  Persistence.Interfaces in 'Source\Persistence.Interfaces.pas',
  Persistence.Types in 'Source\Persistence.Types.pas',
  Persistence.DB in 'Source\Persistence.DB.pas',
  Persistence.ConnectionFactory in 'Source\Persistence.ConnectionFactory.pas',
  Persistence.Context in 'Source\Persistence.Context.pas',
  Persistence.Consts in 'Source\Persistence.Consts.pas',
  Persistence.StatementCache in 'Source\Persistence.StatementCache.pas',
  TestStockListController in 'Tests\TestStockListController.pas',
  Stock.Domain in 'Source\Stock.Domain.pas',
  Stock.Interfaces in 'Source\Stock.Interfaces.pas',
  Stock.StockListController in 'Source\Stock.StockListController.pas',
  Stock.DomainQueries in 'Source\Stock.DomainQueries.pas',
  TestStockStartupController in 'Tests\TestStockStartupController.pas',
  Stock.StartupController in 'Source\Stock.StartupController.pas',
  TestEditStockController in 'Tests\TestEditStockController.pas',
  Stock.EditItemController in 'Source\Stock.EditItemController.pas',
  TestStockHistoryController in 'Tests\TestStockHistoryController.pas',
  Stock.HistoryController in 'Source\Stock.HistoryController.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
