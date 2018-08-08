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
    FConnectionFactory: TMock<IConnectionFactory>;
    FConnection: TMock<IConnection>;
    FQuery: TMock<IQuery>;

  public
    [Setup] procedure Setup;

    [Test] procedure CreateContext;
    [Test] procedure LoadObjects;
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
  System.Rtti;

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

  LContext := TContext.Create(LConnectionFactory);

  Assert.AreEqual('', LConnectionFactory.CheckExpectations);
end;

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

  FQuery.Setup.Expect.Once.When.SQL :=
              'select'
   + #13#10 + '  StringProperty,'
   + #13#10 + '  IntegerProperty'
   + #13#10 + 'from'
   + #13#10 + '  SomeTestData';

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

  LContext := TContext.Create(FConnectionFactory);

  LList := TDataObjectList<TSomeTestDataObject>.Create;
  try
    LContext.Load(LList);
  finally
    LList.Free;
  end;

  Assert.AreEqual('', FConnection.CheckExpectations);
  Assert.AreEqual('', FQuery.CheckExpectations);
  Assert.AreEqual('', LField.CheckExpectations);
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

end;

initialization
  TDUnitX.RegisterTestFixture(TestQuery);
end.
