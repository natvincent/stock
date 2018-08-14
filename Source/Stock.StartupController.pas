unit Stock.StartupController;

interface

uses
  Stock.Interfaces,
  Persistence.Interfaces;

const

  CDefaultDatabaseName = 'Stock.sdb';

type

  TStockStartupController = class (TInterfacedObject, IStockStartupController)
  private
    FConnectionFactory: IConnectionFactory;
    FStatementCache: IStatementCache;
    FDataLocation: string;
    function GetDataLocation: string;
    procedure SetupDataFolder(const AExePath: string);
    function CreateContext: IContext;
  public
    constructor Initialise(
      const AConnectionFactory: IConnectionFactory;
      const AStatementBuilderFactory: IStatementBuilderFactory;
      const AStatementCache: IStatementCache;
      const AExeFolder: string
    );
  end;

implementation

uses
  Stock.DomainQueries,
  Persistence.Types,
  Stock.Domain,
  Winapi.ShlObj,
  Winapi.Windows,
  Winapi.KnownFolders,
  System.SysUtils,
  Winapi.ActiveX,
  System.StrUtils,
  Persistence.Context;

{ TStockStartupController }

function TStockStartupController.CreateContext: IContext;
begin
  result := TContext.Create(
    FConnectionFactory,
    FStatementCache
  );
end;

function TStockStartupController.GetDataLocation: string;
begin
  result := FDataLocation;
end;

constructor TStockStartupController.Initialise(
  const AConnectionFactory: IConnectionFactory;
  const AStatementBuilderFactory: IStatementBuilderFactory;
  const AStatementCache: IStatementCache;
  const AExeFolder: string
);
var
  LEchoBuilder: IStatementBuilder;
begin
  FConnectionFactory := AConnectionFactory;
  FStatementCache := AStatementCache;

  SetupDataFolder(AExeFolder);

  LEchoBuilder := AStatementBuilderFactory.CreateEchoBuilder(
    CStockListItemSelect
  );
  AStatementCache.AddStatement(stSelect, TStockListItem, LEchoBuilder);

  LEchoBuilder := AStatementBuilderFactory.CreateEchoBuilder(
    CStockItemsOnHand
  );
  AStatementCache.AddStatement(stSelect, TStockItemsOnHand, LEchoBuilder);
end;

procedure TStockStartupController.SetupDataFolder(const AExePath: string);

  function GetKnownPath(const AKnownFolder: TGUID): string;
  var
    LPath: PWideChar;
  begin
    result := '';
    if Succeeded(SHGetKnownFolderPath(AKnownFolder, 0, 0, LPath)) then
    begin
      result := IncludeTrailingPathDelimiter(LPath);
      CoTaskMemFree(LPath);
    end;
  end;

var
  LProgramFiles: string;
const
  CProgramDataFolder = 'Stock\';
  CDataFolder = 'Data\';
begin
  LProgramFiles := GetKnownPath(FOLDERID_ProgramFiles);
  if SameText(LeftStr(AExePath, Length(LProgramFiles)), LProgramFiles) then
    FDataLocation := GetKnownPath(FOLDERID_ProgramData) + CProgramDataFolder
  else
    FDataLocation := AExePath + CDataFolder;
  FConnectionFactory.DatabasePath := FDataLocation + CDefaultDatabaseName;
end;

end.
