program Stock;

uses
  System.SysUtils,
  Vcl.Forms,
  Persistence.Interfaces,
  Persistence.FireDac.SQLite,
  Persistence.StatementCache,
  Stock.Interfaces,
  Stock.StartupController,
  Stock.StockListController,
  FormMain in 'Source\FormMain.pas' {MainForm},
  FormEditItem in 'Source\FormEditItem.pas' {EditItemForm},
  FormStockHistory in 'Source\FormStockHistory.pas' {StockHistoryForm};

{$R stock.res}

var
  LStartupController: IStockStartupController;
  LStatementFactory: IStatementBuilderFactory;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  LStatementFactory := TSQLiteStatementBuilderFactory.Create;
  LStartupController := TStockStartupController.Initialise(
    TFireDacConnectionFactory.Create,
    LStatementFactory,
    TStatementCache.Create(LStatementFactory),
    ExtractFilePath(ParamStr(0))
  );

  Application.CreateForm(TMainForm, MainForm);

  MainForm.Controller := TStockListController.Create(LStartupController.CreateContext);

  Application.Run;
end.
