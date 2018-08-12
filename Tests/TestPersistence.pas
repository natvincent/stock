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
    FStatementCache: TMock<IStatementCache>;
    FConnectionFactory: TMock<IConnectionFactory>;
    FConnection: TMock<IConnection>;
    FQuery: TMock<IQuery>;

  public
    [Setup] procedure Setup;

    [Test] procedure CreateContext;
    [Test] procedure LoadObjects;
    [Test] procedure SaveObjects;
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
  TestEndToEnd = class
  private
    FFDQuery: TFDQuery;
    FFDConnection: TFDConnection;

  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure TestEndToEnd;

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
  Persistence.StatementCache;

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

procedure TestEndToEnd.Setup;
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
   + #13#10 + '  ''Broccoli'','
   + #13#10 + '  ''Just another Brasicca'''
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
  LConnectionFactory := TFireDACConnectionFactory.Create(CDatabaseFilename);

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
    property IntegerProperty: integer read FIntegerProperty write SetIntegerProperty;
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


procedure TTestContext.LoadObjects;
var
  LField: TMock<IField>;
  LContext: IContext;
  LList: TDataObjectList<TSomeTestDataObject>;
  LItem: TSomeTestDataObject;
  LLoopCount: integer;
begin
  LLoopCount := 1;
  FConnection.Setup.Expect.Once.When.CreateQuery;

  LField := TMock<IField>.Create;
  LField.Setup.Expect.Once.When.GetAsString;
  LField.Setup.WillReturn('Some data').When.GetAsString;

  LField.Setup.Expect.Once.When.GetAsInteger;
  LField.Setup.WillReturn(42).When.GetAsInteger;

  FQuery.Setup.Expect.Once.When.SQL := CContextTestSelectStatement;

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
    .WillReturn(LStringParam.InstanceAsValue).When.ParamByName('StringProperty');
  FQuery.Setup
    .WillReturn(LIntegerParam.InstanceAsValue).When.ParamByName('ID');

  LContext := TContext.Create(FConnectionFactory, FStatementCache);

  FStatementCache.Setup
    .WillReturn(CSomeOtherDataObjectInsert).When.GetStatement(stInsert, TSomeOtherDataObject);
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
    .WillReturn(LStringParam.InstanceAsValue).When.ParamByName('StringProperty');
  FQuery.Setup
    .Expect.Exactly(2).When.ParamByName('StringProperty');

  FQuery.Setup
    .WillReturn(LIntegerParam.InstanceAsValue).When.ParamByName('IntegerProperty');
  FQuery.Setup
    .Expect.Exactly(2).When.ParamByName('IntegerProperty');

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

  FConnectionFactory := TMock<IConnectionFactory>.Create;
  FConnectionFactory.Setup
    .Expect.Once.When.CreateConnection;
  FConnectionFactory.Setup
    .WillReturn(FConnection.InstanceAsValue).When.CreateConnection;

  FStatementCache := TMock<IStatementCache>.Create;
  FStatementCache.Setup
    .WillReturn(CContextTestSelectStatement).When.GetStatement(stSelect, TSomeTestDataObject);
  FStatementCache.Setup
    .WillReturn(CContextTestInsertStatement).When.GetStatement(stInsert, TSomeTestDataObject);
  FStatementCache.Setup
    .WillReturn(CContextTestUpdateStatement).When.GetStatement(stUpdate, TSomeTestDataObject);
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
begin
  FSelectBuilder.Setup
    .Expect.Never.When.Generate;
  FStatementBuilderFactory.Setup
    .Expect.Never.When.CreateSelectBuilder;

  LCache := TStatementCache.Create(FStatementBuilderFactory);

  LCache.AddStatement(
    stSelect,
    TSomeTestDataObject,
    CSpecificSelectStatement
  );

  Assert.AreEqual(
    CSpecificSelectStatement,
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
    .Expect.Once.When.AddFieldParam('IntegerProperty');
  FInsertBuilder.Setup
    .Expect.Once.When.AddFieldParam('StringProperty');
  FInsertBuilder.Setup
    .Expect.Once.When.AddUpdateInto('SomeTestData');

  LCache := TStatementCache.Create(FStatementBuilderFactory);

  Assert.AreEqual(
    CTestInsertStatement,
    LCache.GetStatement(stInsert, TSomeTestDataObject)
  );

  Assert.AreEqual(
    CTestInsertStatement,
    LCache.GetStatement(stInsert, TSomeTestDataObject)
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

  Assert.AreEqual(
    CTestSelectStatement,
    LCache.GetStatement(stSelect, TSomeTestDataObject)
  );

  Assert.AreEqual(
    CTestSelectStatement,
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

  Assert.AreEqual(
    CTestUpdateStatement,
    LCache.GetStatement(stUpdate, TSomeTestDataObject)
  );

  Assert.AreEqual(
    CTestUpdateStatement,
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

initialization
  TDUnitX.RegisterTestFixture(TestQuery);
end.
