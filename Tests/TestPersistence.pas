unit TestPersistence;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TestQuery = class(TObject) 
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test1;

    [Test]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

procedure TestQuery.Setup;
begin

end;

procedure TestQuery.TearDown;
begin
end;

procedure TestQuery.Test1;
begin
end;

procedure TestQuery.Test2(const AValue1 : Integer;const AValue2 : Integer);
begin
end;

initialization
  TDUnitX.RegisterTestFixture(TestQuery);
end.
