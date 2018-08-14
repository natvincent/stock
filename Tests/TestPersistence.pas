unit TestPersistence;

interface
uses
  DUnitX.TestFramework,
  Persistence.Interfaces,
  FireDAC.Comp.Client,
  Delphi.Mocks;

type

  [TestFixture]
  TestQuery = class
  private
    FFDConnection: TFDConnection;
    FFDQuery: TFDQuery;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure SetSQL;
    [Test] procedure OpenAndReadFields;
    [Test] procedure SetParametersAndExecute;
    [Test] procedure FindParam;

  end;

  [TestFixture]
  TestConnection = class
  private
    FFDConnection: TFDConnection;

  public
    [Setup] procedure Setup;

    [Test] procedure DatabaseName;
    [Test] procedure CreateQuery;

  end;

  [TestFixture]
  TTestConnectionFactory = class
  public
    [Test] procedure DatabasePathMustBeSet;
  end;

  [TestFixture]
  TTestDataObject = class
  public
   [Test] procedure IsDirty;
   [Test] procedure Changed;

  end;

  [TestFixture]
  TestDataObjectList = class
  public
    [Test] procedure AddObject;
    [Test] procedure DeleteObject;
  end;

  [TestFixture]
  TTestContext = class
  private
    FSelectBuilder: TMock<IStatementBuilder>;
    FInsertBuilder: TMock<IStatementBuilder>;
    FUpdateBuilder: TMock<IStatementBuilder>;
    FStatementCache: TMock<IStatementCache>;
    FConnectionFactory: TMock<IConnectionFactory>;
    FConnection: TMock<IConnection>;
    FQuery: TMock<IQuery>;

  public
    [Setup] procedure Setup;

    [Test] procedure CreateContext;
    [Test] procedure LoadObjects;
    [Test] procedure LoadClearsList;
    [Test] procedure LoadObjectsWithCriteria;
    [Test] procedure LoadObject;
    [Test] procedure SaveObjects;
    [Test] procedure SaveObject;
    [Test] procedure SaveNewObjectUpdatesKey;
  end;

  [TestFixture]
  TTestStatementCache = class
  private
    FStatementBuilderFactory: TMock<IStatementBuilderFactory>;
    FSelectBuilder: TMock<ISelectBuilder>;
    FUpdateBuilder: TMock<IUpdateInsertBuilder>;
    FInsertBuilder: TMock<IUpdateInsertBuilder>;
  public
    [Setup] procedure Setup;

    [Test] procedure CreateSelectForClass;
    [Test] procedure CreateUpdateForClass;
    [Test] procedure CreateInsertForClass;
    [Test] procedure AddStatement;
  end;

  [TestFixture]
  TestSelectBuilder = class
  public
    [Test] procedure BuildSQL;
    [Test] procedure BuildSQLWithTemporaryWhere;
    [Test] procedure RaisesExceptionWhenFieldsMissing;
    [Test] procedure RaisesExceotionWhenTableMissing;
  end;

  [TestFixture]
  TTestInsertBuilder = class
  public
    [Test] procedure BuildSQL;
    [Test] procedure RaisesExceptionWhenFieldsMissing;
    [Test] procedure RiasesExceptionWhenMissingInto;
    [Test] procedure RaisesExceptionWhenWhereFieldUsed;
  end;

  [TestFixture]
  TTestUpdateBuilder = class
  public
    [Test] procedure BuildSQL;
    [Test] procedure RaisesExceptionWhenFieldsMissing;
    [Test] procedure RaisesExceptionWhenUpdateTableMissing;
  end;

  [TestFixture]
  TTestEchoBuilder = class
  public
    [Test] procedure ReturnsWhatItWasGiven;
  end;

  [TestFixture]
  TestEndToEnd = class
  private
    FFDQuery: TFDQuery;
    FFDConnection: TFDConnection;

  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure TestEndToEnd;
    [Test] procedure TestGetLastIdentityValue;
    [Test] procedure SaveNewLevel;
    [Test] procedure LoadLevel;
    [Test] procedure LoadOnHand;

  end;

implementation

uses
  Persistence.FireDAC.SQLite,
  System.SysUtils,
  Persistence.Types,
  FireDAC.Stan.Param,
  Persistence.Context,
  System.Classes,
  System.Rtti,
  Persistence.StatementCache,
  Persistence.DB,
  Stock.Domain,
  Stock.DomainQueries;

const
  CDatabaseFilename = 'TestDatabase.sdb';
  CQueryText =
              'select'
   + #13#10 + ' *'
   + #13#10 + 'from'
   + #13#10 + ' stock';

procedure TestQuery.Setup;
begin
  if FileExists(CDatabaseFilename) then
    DeleteFile(CDatabaseFilename);

  FFDConnection := TFDConnection.Create(nil);
  FFDConnection.DriverName := 'SQLite';
  FFDConnection.Params.DriverID := 'SQLite';
  FFDConnection.Params.Database := CDatabaseFilename;
  FFDConnection.Params.Values['OpenMode'] := 'CreateUTF16';
  FFDConnection.Open;

  FFDConnection.ExecSQL(
              'create table stock ('
   + #13#10 + '  StockItemID integer primary key,'
   + #13#10 + '  Name varchar(200),'
   + #13#10 + '  Description text'
   + #13#10 + ')'
  );
  FFDConnection.ExecSQL(
              'insert into stock ('
   + #13#10 + '  Name,'
   + #13#10 + '  Description'
   + #13#10 + ') values ('
   + #13#10 + '  ''Carrots, loose'','
   + #13#10 + '  ''Loose carrots fresh every day'''
   + #13#10 + ')'
  );
  FFDQuery := TFDQuery.Create(nil);
  FFDQuery.Connection := FFDConnection;
end;

procedure TestQuery.TearDown;
begin
  FFDConnection.Free;
end;

procedure TestQuery.FindParam;
var
  LQuery: IQuery;
  LParam: IParam;
begin
  LQuery := TFireDACQuery.Create(FFDQuery);

  LQuery.SQL :=
              'insert into stock ('
   + #13#10 + '  Name,'
   + #13#10 + '  Description'
   + #13#10 + ') values ('
   + #13#10 + '  :Name,'
   + #13#10 + '  :Description'
   + #13#10 + ')';

  Assert.IsTrue(LQuery.FindParam('Name', LParam));

  Assert.IsFalse(LQuery.FindParam('Blah', LParam));
end;

procedure TestQuery.OpenAndReadFields;
var
  LQuery: IQuery;
begin
  LQuery := TFireDACQuery.Create(FFDQuery);

  LQuery.SQL := CQueryText;

  LQuery.Open;

  Assert.IsFalse(LQuery.EOF);

  Assert.AreEqual('Carrots, loose', LQuery.FieldByName('Name').AsString);
  Assert.AreEqual('Loose carrots fresh every day', LQuery.FieldByName('Description').AsString);
end;

procedure TestQuery.SetParametersAndExecute;
var
  LQuery: IQuery;
  LParam: IParam;
const
  CTomatoName = 'Tomatoes, loose';
  CTomatoDescription = 'Fresh juicy tomatoes staight of the vine';
begin
  LQuery := TFireDACQuery.Create(FFDQuery);

  LQuery.SQL :=
              'insert into stock ('
   + #13#10 + '  Name,'
   + #13#10 + '  Description'
   + #13#10 + ') values ('
   + #13#10 + '  :Name,'
   + #13#10 + '  :Description'
   + #13#10 + ')';

  LParam := LQuery.ParamByName('Name');
  Assert.IsNotNull(LParam);
  Assert.AreEqual('Name', LParam.Name);

  LParam.AsString := CTomatoName;
  Assert.AreEqual(CTomatoName, FFDQuery.ParamByName('Name').AsString);

  LQuery.ParamByName('Description').AsString := CTomatoDescription;

  LQuery.Execute;

  LQuery.SQL := CQueryText
   + #13#10 + 'where'
   + #13#10 + '  Name = :Name';

  LQuery.ParamByName('Name').AsString := CTomatoName;

  LQuery.Open;

  Assert.IsFalse(LQuery.EOF);

  Assert.AreEqual(CTomatoDescription, LQuery.FieldByName('Description').AsString);
end;

procedure TestQuery.SetSQL;
var
  LQuery: IQuery;
begin
  LQuery := TFireDACQuery.Create(FFDQuery);

  LQuery.SQL := CQueryText;

  Assert.AreEqual(CQueryText, FFDQuery.SQL.Text);

  LQuery := nil;
end;

{ TestConnection }

procedure TestConnection.CreateQuery;
var
  LConnection: IConnection;
  LQuery: IQuery;
begin
  LConnection := TFireDACConnection.Create;

  LQuery := LConnection.CreateQuery;
  Assert.IsNotNull(LQuery);
end;

procedure TestConnection.DatabaseName;
var
  LConnection: IConnection;
begin
  LConnection := TFireDACConnection.Create;

  LConnection.Database := CDatabaseFilename;
  Assert.AreEqual(CDatabaseFilename, LConnection.Database);
end;

procedure TestConnection.Setup;
begin
  FFDConnection := TFDConnection.Create(nil);
end;

{ TestEndToEnd }

procedure TestEndToEnd.LoadLevel;
var
  LConnectionFactory: IConnectionFactory;
  LStatementCache: IStatementCache;
  LStatementBuilderFactory: IStatementBuilderFactory;
  LContext: IContext;
  LLevelList: TStockLevelList;
begin
  LConnectionFactory := TFireDACConnectionFactory.Create;
  LConnectionFactory.DatabasePath := CDatabaseFilename;
  LStatementBuilderFactory := TSQLiteStatementBuilderfactory.Create;
  LStatementCache := TStatementCache.Create(LStatementBuilderFactory);

  LContext := TContext.Create(
    LConnectionFactory,
    LStatementCache
  );

  LLevelList := TStockLevelList.Create;
  try
    LContext.Load(LLevelList);

    Assert.AreEqual(2, LLevelList.Count);
    Assert.AreEqual(30, LLevellist[0].OnHand);
    Assert.AreEqual(2, LLevelList[0].StockItemID);
    Assert.AreNotEqual<TDateTime>(0, LLevelList[0].DateTime);

  finally
    LLevelList.Free;
  end;
end;

procedure TestEndToEnd.LoadOnHand;
var
  LConnectionFactory: IConnectionFactory;
  LStatementCache: IStatementCache;
  LStatementBuilderFactory: IStatementBuilderFactory;
  LContext: IContext;
  LOnHand: TStockItemsOnHand;
begin
  LConnectionFactory := TFireDACConnectionFactory.Create;
  LConnectionFactory.DatabasePath := CDatabaseFilename;
  LStatementBuilderFactory := TSQLiteStatementBuilderfactory.Create;
  LStatementCache := TStatementCache.Create(LStatementBuilderFactory);

  LStatementCache.AddStatement(
    stSelect,
    TStockItemsOnHand,
    LStatementBuilderFactory.CreateEchoBuilder(CStockItemsOnHand)
  );

  LContext := TContext.Create(
    LConnectionFactory,
    LStatementCache
  );

  LOnHand := TStockItemsOnHand.Create;
  try
    LContext.Load(LOnHand, 2);

    Assert.AreEqual(40, LOnHand.OnHand);
  finally
    LOnHand.Free;
  end;
end;

procedure TestEndToEnd.SaveNewLevel;
var
  LConnectionFactory: IConnectionFactory;
  LConnection: IConnection;
  LStatementCache: IStatementCache;
  LStatementBuilderFactory: IStatementBuilderFactory;
  LContext: IContext;
  LLevel: TStockLevel;
  LQuery: IQuery;
begin
  LConnectionFactory := TFireDACConnectionFactory.Create;
  LConnectionFactory.DatabasePath := CDatabaseFilename;
  LStatementBuilderFactory := TSQLiteStatementBuilderfactory.Create;
  LStatementCache := TStatementCache.Create(LStatementBuilderFactory);

  LContext := TContext.Create(
    LConnectionFactory,
    LStatementCache
  );

  LLevel := TStockLevel.CreateNew;
  try
    LLevel.OnHand := 20;

    LContext.Save(LLevel);

    LConnection := LConnectionFactory.CreateConnection;
    LQuery := LConnection.CreateQuery;
    LQuery.SQL := 'select * from StockLevels where StockLevelID = :StockLevelID';
    LQuery.ParamByName('StockLevelID').AsInteger := LLevel.StockLevelID;
    LQuery.Open;
    Assert.IsFalse(LQuery.EOF);
    Assert.AreEqual(1, LQuery.RecordCount);
    Assert.AreEqual(20, LQuery.FieldByName('OnHand').AsInteger);
  finally
    LLevel.Free;
  end;

end;

procedure TestEndToEnd.Setup;
begin
  if FileExists(CDatabaseFilename) then
    Assert.IsTrue(DeleteFile(CDatabaseFilename));

  FFDConnection := TFDConnection.Create(nil);
  FFDConnection.DriverName := 'SQLite';
  FFDConnection.Params.DriverID := 'SQLite';
  FFDConnection.Params.Database := CDatabaseFilename;
  FFDConnection.Params.Values['OpenMode'] := 'CreateUTF16';
  FFDConnection.Open;

  FFDConnection.ExecSQL(
              'create table stock ('
   + #13#10 + '  StockItemID integer primary key autoincrement,'
   + #13#10 + '  Name varchar(200),'
   + #13#10 + '  Description text'
   + #13#10 + ')'
  );
  FFDConnection.ExecSQL(
              'insert into stock ('
   + #13#10 + '  Name,'
   + #13#10 + '  Description'
   + #13#10 + ') values ('
   + #13#10 + '  ''Broccoli'','
   + #13#10 + '  ''Just another Brasicca'''
   + #13#10 + ')'
  );

  FFDConnection.ExecSQL(
              'create table stocklevels ('
   + #13#10 + '  StockLevelID integer primary key autoincrement,'
   + #13#10 + '  StockItemID integer,'
   + #13#10 + '  OnHand integer ,'
   + #13#10 + '  DateTime varchar(24) default current_timestamp'
   + #13#10 + ')'
  );
  FFDConnection.ExecSQL(
              'insert into stocklevels ('
   + #13#10 + '  OnHand,'
   + #13#10 + '  StockItemID'
   + #13#10 + ') values ('
   + #13#10 + '  30,'
   + #13#10 + '  2'
   + #13#10 + ')'
  );
  FFDConnection.ExecSQL(
              'insert into stocklevels ('
   + #13#10 + '  OnHand,'
   + #13#10 + '  StockItemID'
   + #13#10 + ') values ('
   + #13#10 + '  40,'
   + #13#10 + '  2'
   + #13#10 + ')'
  );
  FFDQuery := TFDQuery.Create(nil);
  FFDQuery.Connection := FFDConnection;
end;

procedure TestEndToEnd.TearDown;
begin
  FFDQuery.Free;
  FFDConnection.Free;
end;

procedure TestEndToEnd.TestEndToEnd;
var
  LConnectionFactory: IConnectionFactory;
  LConnection: IConnection;
  LQuery: IQuery;
begin
  LConnectionFactory := TFireDACConnectionFactory.Create;
  LConnectionFactory.DatabasePath := CDatabaseFilename;

  LConnection := LConnectionFactory.CreateConnection;

  LQuery := LConnection.CreateQuery;

  LQuery.SQL := CQueryText
   + #13#10 + 'where'
   + #13#10 + '  Name = :Name';

  LQuery.ParamByName('Name').AsString := 'Broccoli';

  LQuery.Open;

  Assert.IsFalse(LQuery.EOF);

  Assert.AreEqual('Just another Brasicca', LQuery.FieldByName('Description').AsString);
end;

procedure TestEndToEnd.TestGetLastIdentityValue;
var
  LConnectionFactory: IConnectionFactory;
  LConnection: IConnection;
  LQuery: IQuery;
begin
  LConnectionFactory := TFireDACConnectionFactory.Create;
  LConnectionFactory.DatabasePath := CDatabaseFilename;

  LConnection := LConnectionFactory.CreateConnection;

  LQuery := LConnection.CreateQuery;

  LQuery.SQL :=
               'insert into stock ('
    + #13#10 + '  name,'
    + #13#10 + '  description'
    + #13#10 + ') values ('
    + #13#10 + '  ''Mushrooms'','
    + #13#10 + '  ''Fungus'''
    + #13#10 + ')';

  LQuery.Execute;

  Assert.AreEqual<int64>(2, LConnection.GetLastIdentityValue);

end;

{ TTestDataObject }

type

  {$m+}
  [TableName('SomeTestData')]
  TSomeTestDataObject = class (TDataObject)
  private
    FStringProperty: string;
    FIntegerProperty: integer;
    procedure SetStringProperty(const Value: string);
    procedure SetIntegerProperty(const Value: integer);

  published
    property StringProperty: string read FStringProperty write SetStringProperty;

    [KeyField]
    [IdentityField]
    property IntegerProperty: integer read FIntegerProperty write SetIntegerProperty;

  end;

  [TableName('SomeTestData')]
  TAnotherTestDataObject = class (TSomeTestDataObject)
  private
    FAnotherIntegerProperty: integer;

  published
    [ReadOnlyField]
    property AnotherIntegerProperty: integer read FAnotherIntegerProperty write FAnotherIntegerProperty;
  end;
  {$m-}

procedure TTestDataObject.Changed;
var
  LDataObject: TSomeTestDataObject;
begin
  LDataObject := TSomeTestDataObject.CreateNew;
  try
    Assert.AreEqual(dsNew, LDataObject.DataState);

    LDataObject.StringProperty := 'Some value';

    Assert.AreEqual(dsNew, LDataObject.DataState);

    LDataObject.DataState := dsClean;

    LDataObject.StringProperty := 'Some other value';

    Assert.AreEqual(dsDirty, LDataObject.DataState);


  finally
    LDataObject.Free;
  end;
end;

procedure TTestDataObject.IsDirty;
var
  LDataObject: TDataObject;
begin
  LDataObject := TDataObject.Create;
  try

    Assert.AreEqual(dsClean, LDataObject.DataState);

    Assert.IsFalse(LDataObject.IsDirty);

    LDataObject.DataState := dsDirty;
    Assert.IsTrue(LDataObject.IsDirty);

    LDataObject.DataState := dsNew;
    Assert.IsTrue(LDataObject.IsDirty);
  finally
    LDataObject.Free;
  end;
end;

procedure TSomeTestDataObject.SetIntegerProperty(const Value: integer);
begin
  FIntegerProperty := Value;
  Changed;
end;

procedure TSomeTestDataObject.SetStringProperty(const Value: string);
begin
  FStringProperty := Value;
  Changed;
end;

{ TestDataObjectList }

procedure TestDataObjectList.AddObject;
var
  LList: TDataObjectList<TSomeTestDataObject>;
  LItem: TSomeTestDataObject;
begin
  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LItem := TSomeTestDataObject.Create;
    Assert.AreEqual(0, LList.Add(LItem));
    Assert.AreEqual(1, LList.Count);
    Assert.AreSame(LItem, LList[0]);
  finally
    LList.Free;
  end;
end;

procedure TestDataObjectList.DeleteObject;
var
  LList: TDataObjectList<TSomeTestDataObject>;
  LItem: TSomeTestDataObject;
begin
  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LItem := TSomeTestDataObject.Create;
    Assert.AreEqual(0, LList.Add(LItem));
    Assert.AreEqual(1, LList.Count);

    LList.Delete(0);

    Assert.AreEqual(0, LList.Count);

  finally
    LList.Free;
  end;
end;

{ TTestConext }

procedure TTestContext.CreateContext;
var
  LContext: IContext;
  LConnectionFactory: TMock<IConnectionFactory>;
  LConnection: TMock<IConnection>;
begin
  LConnection := TMock<IConnection>.Create;

  LConnectionFactory := TMock<IConnectionFactory>.Create;
  LConnectionFactory.Setup
    .Expect.Once.When.CreateConnection;
  LConnectionFactory.Setup
    .WillReturn(LConnection.InstanceAsValue).When.CreateConnection;

  LContext := TContext.Create(LConnectionFactory, FStatementCache);

  Assert.AreEqual('', LConnectionFactory.CheckExpectations);
end;

const
  CContextTestSelectStatement =
              'select'
   + #13#10 + '  StringProperty,'
   + #13#10 + '  IntegerProperty'
   + #13#10 + 'from'
   + #13#10 + '  SomeTestData';


procedure TTestContext.LoadClearsList;
var
  LContext: IContext;
  LList: TDataObjectList<TSomeTestDataObject>;
  LItem: TSomeTestDataObject;
begin
  FQuery.Setup.WillReturn(True).When.GetEOF;
  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LItem := TSomeTestDataObject.Create;
    LList.Add(LItem);
    LItem := TSomeTestDataObject.Create;
    LList.Add(LItem);
    LItem := TSomeTestDataObject.Create;
    LList.Add(LItem);

    LContext.Load(LList);

    Assert.AreEqual(0, LList.Count);
  finally
    LList.Free;
  end;
end;

procedure TTestContext.LoadObject;
var
  LField: TMock<IField>;
  LParam: TMock<IParam>;
  LContext: IContext;
  LItem: TSomeTestDataObject;
const
  CSomeID = 42;
begin
  FConnection.Setup.Expect.Once.When.CreateQuery;

  LField := TMock<IField>.Create;
  LField.Setup.Expect.Once.When.GetAsString;
  LField.Setup.WillReturn('Some data').When.GetAsString;

  LField.Setup.Expect.Once.When.GetAsInteger;
  LField.Setup.WillReturn(42).When.GetAsInteger;

  LParam := TMock<IParam>.Create;
  LParam.Setup
    .Expect.Once.When.SetAsInteger(CSomeID);

  FQuery.Setup.Expect.Once.When.SQL := CContextTestSelectStatement;

  FQuery.Setup.Expect.Once.When.Open;
  FQuery.Setup.Expect.AtLeastOnce.When.GetEOF;
  FQuery.Setup.WillReturn(False).When.GetEof;
  FQuery.Setup.Expect.Once.When.FieldByName('StringProperty');
  FQuery.Setup
    .WillReturn(LField.InstanceAsValue).When.FieldByName('StringProperty');

  FQuery.Setup.Expect.Once.When.FieldByName('IntegerProperty');
  FQuery.Setup
    .WillReturn(LField.InstanceAsValue).When.FieldByName('IntegerProperty');

  FQuery.Setup
    .Expect.Once.When.ParamByName('IntegerProperty');
  FQuery.Setup
    .WillReturn(LParam.InstanceAsValue).When.ParamByName('IntegerProperty');

  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stSelect, TSomeTestDataObject);

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  LItem := TSomeTestDataObject.Create;
  try
    Assert.IsTrue(LContext.Load(LItem, CSomeID));

    Assert.AreEqual('Some data', LItem.StringProperty);
    Assert.AreEqual(CSomeID, LItem.IntegerProperty);
    Assert.AreEqual(dsClean, LItem.DataState);
  finally
    Litem.Free;
  end;

  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', FStatementCache.CheckExpectations);
  Assert.AreEqual('', FQuery.CheckExpectations);
  Assert.AreEqual('', LField.CheckExpectations);
end;

procedure TTestContext.LoadObjects;
var
  LField: TMock<IField>;
  LContext: IContext;
  LList: TDataObjectList<TSomeTestDataObject>;
  LLoopCount: integer;
  LNextCount: integer;
begin
  LLoopCount := 1;
  LNextCount := 1;
  FConnection.Setup.Expect.Once.When.CreateQuery;

  LField := TMock<IField>.Create;
  LField.Setup.Expect.Once.When.GetAsString;
  LField.Setup.WillReturn('Some data').When.GetAsString;

  LField.Setup.Expect.Once.When.GetAsInteger;
  LField.Setup.WillReturn(42).When.GetAsInteger;

  FQuery.Setup.Expect.Once.When.SQL := CContextTestSelectStatement;

  FQuery.Setup.Expect.Once.When.Open;
  FQuery.Setup.Expect.AtLeastOnce.When.GetEOF;
  FQuery.Setup.Expect.Once.When.Next;
  FQuery.Setup.WillExecute(
    'GetEOF',
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      result := LLoopCount = 0;
      Assert.AreEqual(LLoopCount, LNextCount);
      dec(LLoopCount);
    end
  );
  FQuery.Setup.WillExecute(
    'Next',
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      dec(LNextCount);
    end
  );
  FQuery.Setup.Expect.Once.When.FieldByName('StringProperty');
  FQuery.Setup
    .WillReturn(LField.InstanceAsValue).When.FieldByName('StringProperty');

  FQuery.Setup.Expect.Once.When.FieldByName('IntegerProperty');
  FQuery.Setup
    .WillReturn(LField.InstanceAsValue).When.FieldByName('IntegerProperty');

  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stSelect, TSomeTestDataObject);

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LContext.Load(LList);

    Assert.AreEqual(1, LList.Count);
    Assert.AreEqual('Some data', LList[0].StringProperty);
    Assert.AreEqual(42, LList[0].IntegerProperty);
    Assert.AreEqual(dsClean, LList[0].DataState);
  finally
    LList.Free;
  end;

  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', FStatementCache.CheckExpectations);
  Assert.AreEqual('', FQuery.CheckExpectations);
  Assert.AreEqual('', LField.CheckExpectations);
end;

const
  CAdditionalAnd = 'IntegerProperty < 54';
  CAdditionalWhere =
      #13#10 + 'where 1 = 1'
    + #13#10 + '  and ' + CAdditionalAnd;

procedure TTestContext.LoadObjectsWithCriteria;
var
  LField: TMock<IField>;
  LContext: IContext;
  LList: TDataObjectList<TSomeTestDataObject>;
  LLoopCount: integer;
begin
  LLoopCount := 1;
  FConnection.Setup.Expect.Once.When.CreateQuery;

  LField := TMock<IField>.Create;
  LField.Setup.Expect.Once.When.GetAsString;
  LField.Setup.WillReturn('Some data').When.GetAsString;

  LField.Setup.Expect.Once.When.GetAsInteger;
  LField.Setup.WillReturn(42).When.GetAsInteger;

  FSelectBuilder.Setup
    .Expect.Once.When.AddAdditionalWhereAnd(CAdditionalAnd);
  FSelectBuilder.Setup
    .WillReturn(CContextTestSelectStatement + CAdditionalWhere).When.Generate;

  FQuery.Setup.Expect.Once.When.SetSQL(
    CContextTestSelectStatement + CAdditionalWhere
  );

  FQuery.Setup.Expect.Once.When.Open;
  FQuery.Setup.Expect.AtLeastOnce.When.GetEOF;
  FQuery.Setup.WillExecute(
    'GetEOF',
    function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
    begin
      result := LLoopCount = 0;
      dec(LLoopCount);
    end
  );
  FQuery.Setup
    .WillReturn(LField.InstanceAsValue).When.FieldByName('StringProperty');

  FQuery.Setup
    .WillReturn(LField.InstanceAsValue).When.FieldByName('IntegerProperty');

  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stSelect, TSomeTestDataObject);

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LContext.Load(LList, CAdditionalAnd);

    Assert.AreEqual(1, LList.Count);
    Assert.AreEqual('Some data', LList[0].StringProperty);
    Assert.AreEqual(42, LList[0].IntegerProperty);

  finally
    LList.Free;
  end;

  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', FStatementCache.CheckExpectations);
  Assert.AreEqual('', FQuery.CheckExpectations);
  Assert.AreEqual('', LField.CheckExpectations);
end;

type

  {$m+}
  TSomeOtherDataObject = class (TDataObject)
  private
    FID: integer;
    FStringProperty: string;
  published
    property StringProperty: string read FStringProperty write FStringProperty;

    [IdentityField]
    property ID: integer read FID write FID;
  end;
  {$m-}

const
  CSomeOtherDataObjectInsert =
   'insert into SomeOtherData';

procedure TTestContext.SaveNewObjectUpdatesKey;
var
  LStringParam: TMock<IParam>;
  LIntegerParam: TMock<IParam>;
  LContext: IContext;
  LList: TDataObjectList<TSomeOtherDataObject>;
  LItem: TSomeOtherDataObject;
const
  CTestIdentity = 54;
begin
  LStringParam := TMock<IParam>.Create;
  LIntegerParam := TMock<IParam>.Create;

  FConnection.Setup
    .Expect.Exactly(1).When.CreateQuery;
  FConnection.Setup
    .Expect.Exactly(1).When.GetLastIdentityValue;
  FConnection.Setup
    .WillReturn(CTestIdentity).When.GetLastIdentityValue;

  FQuery.Setup
    .WillExecute(
      'FindParam',
      function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        result := True;
        if args[1].AsString = 'StringProperty' then
          args[2] := LStringParam.InstanceAsValue
        else if args[1].AsString = 'ID' then
          args[2] := LIntegerParam.InstanceAsValue;
      end
    );

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  FStatementCache.Setup
    .WillReturn(FUpdateBuilder.InstanceAsValue).When.GetStatement(stInsert, TSomeOtherDataObject);
  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stInsert, TSomeTestDataObject);

  LList := TDataObjectList<TSomeOtherDataObject>.Create;
  try
    LItem := TSomeOtherDataObject.CreateNew;
    LItem.StringProperty := 'String Value 1';
    LList.Add(LItem);

    LContext.Save(LList);

    Assert.AreEqual(CTestIdentity, LItem.ID);

  finally
    LList.Free;
  end;

  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', LStringParam.CheckExpectations);
  Assert.AreEqual('', LIntegerParam.CheckExpectations);

end;

const
  CContextTestInsertStatement =
               'insert into SomeTestData ('
    + #13#10 + '  StringProperty,'
    + #13#10 + '  IntegerProperty'
    + #13#10 + ') values ('
    + #13#10 + '  :StringProperty,'
    + #13#10 + '  :IntegerProperty'
    + #13#10 + ')';

  CContextTestUpdateStatement =
               'update SomeTestData set'
    + #13#10 + '  StringProperty = :StringProperty'
    + #13#10 + 'where'
    + #13#10 + '  IntegerProperty = :IntegerProperty';

procedure TTestContext.SaveObject;
var
  LStringParam: TMock<IParam>;
  LIntegerParam: TMock<IParam>;
  LContext: IContext;
  LItem: TSomeTestDataObject;
begin
  LStringParam := TMock<IParam>.Create;
  LStringParam.Setup
    .Expect.Once.When.SetAsString('String Value 1');

  LIntegerParam := TMock<IParam>.Create;
  LIntegerParam.Setup
    .Expect.Once.When.SetAsInteger(42);

  FConnection.Setup
    .Expect.Exactly(1).When.CreateQuery;

  FQuery.Setup
    .WillExecute(
      'FindParam',
      function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        result := True;
        if args[1].AsString = 'StringProperty' then
          args[2] := LStringParam.InstanceAsValue
        else if args[1].AsString = 'IntegerProperty' then
          args[2] := LIntegerParam.InstanceAsValue;
      end
    );
  FQuery.Setup
    .Expect.Exactly('FindParam', 2);

  FQuery.Setup
    .Expect.Once.When.SetSQL(CContextTestInsertStatement);
  FQuery.Setup
    .Expect.Exactly(1).When.Execute;

  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stInsert, TSomeTestDataObject);

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  LItem := TSomeTestDataObject.CreateNew;
  try
    LItem.StringProperty := 'String Value 1';
    LItem.IntegerProperty := 42;

    LContext.Save(LItem);

    Assert.AreEqual(dsClean, LItem.DataState);

  finally
    LItem.Free;
  end;

  Assert.AreEqual('', FConnectionFactory.CheckExpectations);
  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', FStatementCache.CheckExpectations);
  Assert.AreEqual('', LStringParam.CheckExpectations);
  Assert.AreEqual('', LIntegerParam.CheckExpectations);
  Assert.AreEqual('', FQuery.CheckExpectations);
end;

procedure TTestContext.SaveObjects;
var
  LStringParam: TMock<IParam>;
  LIntegerParam: TMock<IParam>;
  LContext: IContext;
  LList: TDataObjectList<TSomeTestDataObject>;
  LItem: TSomeTestDataObject;
begin
  LStringParam := TMock<IParam>.Create;
  LStringParam.Setup
    .Expect.Once.When.SetAsString('String Value 1');
  LStringParam.Setup
    .Expect.Once.When.SetAsString('String Value 2');

  LIntegerParam := TMock<IParam>.Create;
  LIntegerParam.Setup
    .Expect.Once.When.SetAsInteger(42);
  LIntegerParam.Setup
    .Expect.Once.When.SetAsInteger(12);

  FConnection.Setup
    .Expect.Exactly(2).When.CreateQuery;

  FQuery.Setup
    .WillExecute(
      'FindParam',
      function (const args : TArray<TValue>; const ReturnType : TRttiType) : TValue
      begin
        result := True;
        if args[1].AsString = 'StringProperty' then
          args[2] := LStringParam.InstanceAsValue
        else if args[1].AsString = 'IntegerProperty' then
          args[2] := LIntegerParam.InstanceAsValue;
      end
    );
  FQuery.Setup
    .Expect.Exactly('FindParam', 4);

  FQuery.Setup
    .Expect.Once.When.SetSQL(CContextTestInsertStatement);
  FQuery.Setup
    .Expect.Once.When.SetSQL(CContextTestUpdateStatement);
  FQuery.Setup
    .Expect.Exactly(2).When.Execute;

  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stUpdate, TSomeTestDataObject);
  FStatementCache.Setup
    .Expect.Once.When.GetStatement(stInsert, TSomeTestDataObject);

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LItem := TSomeTestDataObject.CreateNew;
    LItem.StringProperty := 'String Value 1';
    LItem.IntegerProperty := 42;
    LList.Add(LItem);

    LItem := TSomeTestDataObject.Create;
    LItem.StringProperty := 'String Value 2';
    LItem.IntegerProperty := 12;
    LList.Add(LItem);

    LContext.Save(LList);

    Assert.AreEqual(dsClean, LList[0].DataState);
    Assert.AreEqual(dsClean, LList[1].DataState);

  finally
    LList.Free;
  end;

  Assert.AreEqual('', FConnectionFactory.CheckExpectations);
  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', FStatementCache.CheckExpectations);
  Assert.AreEqual('', LStringParam.CheckExpectations);
  Assert.AreEqual('', LIntegerParam.CheckExpectations);
  Assert.AreEqual('', FQuery.CheckExpectations);

end;

procedure TTestContext.Setup;
begin
  FQuery := TMock<IQuery>.Create;

  FConnection := TMock<IConnection>.Create;
  FConnection.Setup
    .WillReturn(FQuery.InstanceAsValue).When.CreateQuery;
  FConnection.Setup
    .WillReturnDefault('GetLastIdentityValue', 42);

  FConnectionFactory := TMock<IConnectionFactory>.Create;
  FConnectionFactory.Setup
    .Expect.Once.When.CreateConnection;
  FConnectionFactory.Setup
    .WillReturn(FConnection.InstanceAsValue).When.CreateConnection;

  FSelectBuilder := TMock<IStatementBuilder>.Create;
  FSelectBuilder.Setup
    .WillReturnDefault('Generate', CContextTestSelectStatement);

  FInsertBuilder := TMock<IStatementBuilder>.Create;
  FInsertBuilder.Setup
    .WillReturnDefault('Generate', CContextTestInsertStatement);

  FUpdateBuilder := TMock<IStatementBuilder>.Create;
  FUpdateBuilder.Setup
    .WillReturnDefault('Generate', CContextTestUpdateStatement);

  FStatementCache := TMock<IStatementCache>.Create;
  FStatementCache.Setup
    .WillReturn(FSelectBuilder.InstanceAsValue).When.GetStatement(stSelect, TSomeTestDataObject);
  FStatementCache.Setup
    .WillReturn(FInsertBuilder.InstanceAsValue).When.GetStatement(stInsert, TSomeTestDataObject);
  FStatementCache.Setup
    .WillReturn(FUpdateBuilder.InstanceAsValue).When.GetStatement(stUpdate, TSomeTestDataObject);
end;

{ TestSelectBuilder }

procedure TestSelectBuilder.BuildSQL;
var
  LBuilder: ISelectBuilder;
const
  CSelect =
               'select'
    + #13#10 + '  IntegerField,'
    + #13#10 + '  StringField'
    + #13#10 + 'from'
    + #13#10 + '  SomeTestData'
    + #13#10 + 'where 1 = 1'
    + #13#10 + '  and IntegerField > 42';
begin
  LBuilder := TSQLiteSelectBuilder.Create;

  LBuilder.AddField('IntegerField');
  LBuilder.AddField('StringField');
  LBuilder.AddFrom('SomeTestData');
  LBuilder.AddWhereAnd('IntegerField > 42');

  Assert.AreEqual(
    CSelect,
    LBuilder.Generate
  );

end;

procedure TestSelectBuilder.BuildSQLWithTemporaryWhere;
var
  LBuilder: ISelectBuilder;
const
  CSelect =
               'select'
    + #13#10 + '  IntegerField,'
    + #13#10 + '  StringField'
    + #13#10 + 'from'
    + #13#10 + '  SomeTestData'
    + #13#10 + 'where 1 = 1'
    + #13#10 + '  and IntegerField > 42';

  CFirstAdditionalAnd =
    #13#10 + '  and IntegerField < 54';

  CSecondAdditionalAnd =
    #13#10 + '  and StringField = ''SomeValue''';
begin
  LBuilder := TSQLiteSelectBuilder.Create;

  LBuilder.AddField('IntegerField');
  LBuilder.AddField('StringField');
  LBuilder.AddFrom('SomeTestData');
  LBuilder.AddWhereAnd('IntegerField > 42');

  LBuilder.AddAdditionalWhereAnd('IntegerField < 54');

  Assert.AreEqual(
    CSelect + CFirstAdditionalAnd,
    LBuilder.Generate
  );

  LBuilder.AddAdditionalWhereAnd('StringField = ''SomeValue''');

  Assert.AreEqual(
    CSelect + CSecondAdditionalAnd,
    LBuilder.Generate
  );

end;

procedure TestSelectBuilder.RaisesExceotionWhenTableMissing;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: ISelectBuilder;
    begin
      LBUilder := TSQLiteSelectBuilder.Create;

      LBUilder.AddField('IntegerField');

      LBuilder.Generate;
    end,
    EMissingFromClauseException
  );
end;

procedure TestSelectBuilder.RaisesExceptionWhenFieldsMissing;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: ISelectBuilder;
    begin
      LBUilder := TSQLiteSelectBuilder.Create;

      LBUilder.AddFrom('SomeTestData');

      LBuilder.Generate;
    end,
    EMissingFieldsException
  );
end;

{ TTestInsertBuilder }

procedure TTestInsertBuilder.BuildSQL;
var
  LBuilder: IUpdateInsertBuilder;
const
  CInsert =
               'insert into SomeTestData ('
    + #13#10 + '  IntegerField,'
    + #13#10 + '  StringField'
    + #13#10 + ') values ('
    + #13#10 + '  :IntegerField,'
    + #13#10 + '  :StringField'
    + #13#10 + ')';
begin
  LBuilder := TSQLiteInsertBuilder.Create;

  LBuilder.AddUpdateInto('SomeTestData');
  LBuilder.AddFieldParam('IntegerField');
  LBuilder.AddFieldParam('StringField');

  Assert.AreEqual(
    CInsert,
    LBuilder.Generate
  );
end;

procedure TTestInsertBuilder.RaisesExceptionWhenFieldsMissing;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: IUpdateInsertBuilder;
    begin
      LBUilder := TSQLiteInsertBuilder.Create;

      LBUilder.AddUpdateInto('SomeTestData');

      LBuilder.Generate;
    end,
    EMissingFieldsException
  );
end;

procedure TTestInsertBuilder.RaisesExceptionWhenWhereFieldUsed;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: IUpdateInsertBuilder;
    begin
      LBUilder := TSQLiteInsertBuilder.Create;

      LBUilder.AddWhereField('KeyField');
    end,
    EWhereFieldsNotSupportedForInserts
  );
end;

procedure TTestInsertBuilder.RiasesExceptionWhenMissingInto;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: IUpdateInsertBuilder;
    begin
      LBUilder := TSQLiteInsertBuilder.Create;

      LBUilder.AddFieldParam('IntegerField');

      LBuilder.Generate;
    end,
    EMissingIntoUpdateClauseException
  );
end;

{ TTestUpdateBuilder }

procedure TTestUpdateBuilder.BuildSQL;
var
  LBuilder: IUpdateInsertBuilder;
const
  CUpdate =
               'update SomeTestData set'
    + #13#10 + '  IntegerField = :IntegerField,'
    + #13#10 + '  StringField = :StringField'
    + #13#10 + 'where'
    + #13#10 + '  KeyField = :KeyField';
begin
  LBuilder := TSQLiteUpdateBuilder.Create;

  LBuilder.AddUpdateInto('SomeTestData');
  LBuilder.AddFieldParam('IntegerField');
  LBuilder.AddFieldParam('StringField');
  LBuilder.AddWhereField('KeyField');

  Assert.AreEqual(
    CUpdate,
    LBuilder.Generate
  );
end;

procedure TTestUpdateBuilder.RaisesExceptionWhenFieldsMissing;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: IUpdateInsertBuilder;
    begin
      LBUilder := TSQLiteUpdateBuilder.Create;

      LBUilder.AddUpdateInto('SomeTestData');

      LBuilder.Generate;
    end,
    EMissingFieldsException
  );
end;

procedure TTestUpdateBuilder.RaisesExceptionWhenUpdateTableMissing;
begin
  Assert.WillRaise(
    procedure
    var
      LBuilder: IUpdateInsertBuilder;
    begin
      LBUilder := TSQLiteUpdateBuilder.Create;

      LBUilder.AddFieldParam('IntegerField');

      LBuilder.Generate;
    end,
    EMissingIntoUpdateClauseException
  );
end;

{ TTestStatementCache }

const
  CSpecificSelectStatement =
    'select * /* special select statement */ from SomeTestData';

procedure TTestStatementCache.AddStatement;
var
  LCache: IStatementCache;
  LSelectStatement: TMock<ISelectBuilder>;
begin
  FSelectBuilder.Setup
    .Expect.Never.When.Generate;
  FStatementBuilderFactory.Setup
    .Expect.Never.When.CreateSelectBuilder;

  LSelectStatement := TMock<ISelectBuilder>.Create;

  LCache := TStatementCache.Create(FStatementBuilderFactory);

  LCache.AddStatement(
    stSelect,
    TSomeTestDataObject,
    LSelectStatement.Instance
  );

  Assert.AreSame(
    LSelectStatement.Instance,
    LCache.GetStatement(stSelect, TSomeTestDataObject)
  );

  Assert.AreEqual('', FSelectBuilder.CheckExpectations);
  Assert.AreEqual('', FStatementBuilderFactory.CheckExpectations);
end;

const
  CTestInsertStatement =
    'insert into SomeTestData ()';

procedure TTestStatementCache.CreateInsertForClass;
var
  LCache: IStatementCache;
begin
  FStatementBuilderFactory.Setup
    .Expect.Once.When.CreateInsertBuilder;

  FInsertBuilder.Setup
    .Expect.Never.When.AddFieldParam('IntegerProperty'); //identity
  FInsertBuilder.Setup
    .Expect.Once.When.AddFieldParam('StringProperty');
  FInsertBuilder.Setup
    .Expect.Once.When.AddUpdateInto('SomeTestData');
  FInsertBuilder.Setup
    .Expect.Never.When.AddUpdateInto('AnotherIntegerProperty'); //read only

  LCache := TStatementCache.Create(FStatementBuilderFactory);

  Assert.AreSame(
    FInsertBuilder,
    LCache.GetStatement(stInsert, TAnotherTestDataObject)
  );

  Assert.AreSame(
    FInsertBuilder,
    LCache.GetStatement(stInsert, TAnotherTestDataObject)
  );

  Assert.AreEqual('', FInsertBuilder.CheckExpectations);
  Assert.AreEqual('', FStatementBuilderFactory.CheckExpectations);
end;

const
  CTestSelectStatement =
    'select * from SomeTestData';

procedure TTestStatementCache.CreateSelectForClass;
var
  LCache: IStatementCache;
begin
  FStatementBuilderFactory.Setup
    .Expect.Once.When.CreateSelectBuilder;

  FSelectBuilder.Setup
    .Expect.Once.When.AddField('IntegerProperty');
  FSelectBuilder.Setup
    .Expect.Once.When.AddField('StringProperty');
  FSelectBuilder.Setup
    .Expect.Once.When.AddFrom('SomeTestData');

  LCache := TStatementCache.Create(FStatementBuilderFactory);

  Assert.AreSame(
    FSelectBuilder,
    LCache.GetStatement(stSelect, TSomeTestDataObject)
  );

  Assert.AreSame(
    FSelectBuilder,
    LCache.GetStatement(stSelect, TSomeTestDataObject)
  );

  Assert.AreEqual('', FSelectBuilder.CheckExpectations);
  Assert.AreEqual('', FStatementBuilderFactory.CheckExpectations);

end;

const
  CTestUpdateStatement =
    'update SomeTestData set';

procedure TTestStatementCache.CreateUpdateForClass;
var
  LCache: IStatementCache;
begin
  FStatementBuilderFactory.Setup
    .Expect.Once.When.CreateUpdateBuilder;

  FUpdateBuilder.Setup
    .Expect.Once.When.AddWhereField('IntegerProperty');
  FUpdateBuilder.Setup
    .Expect.Once.When.AddFieldParam('StringProperty');
  FUpdateBuilder.Setup
    .Expect.Once.When.AddUpdateInto('SomeTestData');

  LCache := TStatementCache.Create(FStatementBuilderFactory);

  Assert.AreSame(
    FUpdateBuilder,
    LCache.GetStatement(stUpdate, TSomeTestDataObject)
  );

  Assert.AreSame(
    FUpdateBuilder,
    LCache.GetStatement(stUpdate, TSomeTestDataObject)
  );

  Assert.AreEqual('', FUpdateBuilder.CheckExpectations);
  Assert.AreEqual('', FStatementBuilderFactory.CheckExpectations);
end;

procedure TTestStatementCache.Setup;
begin
  FSelectBuilder := TMock<ISelectBuilder>.Create;
  FSelectBuilder.Setup
    .WillReturn(CTestSelectStatement).When.Generate;

  FUpdateBuilder := TMock<IUpdateInsertBuilder>.Create;
  FUpdateBuilder.Setup
    .WillReturn(CTestUpdateStatement).When.Generate;

  FInsertBuilder := TMock<IUpdateInsertBuilder>.Create;
  FInsertBuilder.Setup
    .WillReturn(CTestInsertStatement).When.Generate;

  FStatementBuilderFactory := TMock<IStatementBuilderFactory>.Create;
  FStatementBuilderFactory.Setup
    .WillReturn(FSelectBuilder.InstanceAsValue).When.CreateSelectBuilder;
  FStatementBuilderFactory.Setup
    .WillReturn(FUpdateBuilder.InstanceAsValue).When.CreateUpdateBuilder;
  FStatementBuilderFactory.Setup
    .WillReturn(FInsertBuilder.InstanceAsValue).When.CreateInsertBuilder;
end;

{ TTestEchoBuilder }

procedure TTestEchoBuilder.ReturnsWhatItWasGiven;
var
  LEchoBuilder: IStatementBuilder;
const
  CTestStatement =
               'select'
    + #13#10 + '  *'
    + #13#10 + 'from'
    + #13#10 + '  table';
begin
  LEchoBuilder := TEchoStatementBuilder.Create(CTestStatement);

  Assert.AreEqual(CTestStatement, LEchoBuilder.Generate);
end;

{ TTestConnectionFactory }

procedure TTestConnectionFactory.DatabasePathMustBeSet;
var
  LConnectionFactory: IConnectionFactory;
  LConnection: IConnection;
const
  CTestDatabasePath = 'C:\Projects\Stock\Data\Stock.sdb';
begin
  LConnectionFactory := TFireDACConnectionFactory.Create;

  Assert.WillRaise(
    procedure
    begin
      LConnection := LConnectionFactory.CreateConnection;
    end,
    EDatabasePathNotSet
  );

  LConnectionFactory.DatabasePath := CTestDatabasePath;

  Assert.WillNotRaise(
    procedure
    begin
      LConnection := LConnectionFactory.CreateConnection;
    end
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TestQuery);
end.
