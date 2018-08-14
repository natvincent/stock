unit Persistence.Interfaces;

interface

uses
  System.Classes,
  Persistence.Types,
  System.SysUtils;

type

  EPersistenceException = class (Exception);

  {$m+}
  IField = interface
    ['{241CEBE7-F20B-41D3-ACDC-75A1786999E6}']
    {$REGION 'Getters and Setters'}
    function GetAsString: string;
    function GetAsInteger: integer;
    {$ENDREGION}
    property AsString: string read GetAsString;
    property AsInteger: integer read GetAsInteger;
  end;

  IParam = interface
    ['{D4C337C9-47B7-4DD8-8C8B-BF0752342C2D}']

    {$REGION 'Getters and Setters'}
    function GetName: string;
    function GetAsString: string;
    procedure SetAsString(const AValue: string);
    function GetAsInteger: integer;
    procedure SetAsInteger(const AValue: integer);
    {$ENDREGION}

    property Name: string read GetName;
    property AsString: string read GetAsString write SetAsString;
    property AsInteger: integer read GetAsInteger write SetAsInteger;
  end;

  IQuery = interface
    ['{6568B0A0-3EDF-4FDE-93D1-F4EB81C2A730}']

    {$REGION 'Getters and Setters'}
    function GetSQL: string;
    procedure SetSQL(const ASQL: string);
    function GetEOF: boolean;
    function GetRecordCount: integer;
    {$ENDREGION}

    procedure Execute;
    procedure Open;

    procedure Next;

    function FieldByName(const AName: string): IField;
    function ParamByName(const AName: string): IParam;
    function FindParam(const AName: string; out AParam: IParam): boolean;

    property SQL: string read GetSQL write SetSQL;
    property EOF: boolean read GetEOF;
    property RecordCount: integer read GetRecordCount;
  end;

  IConnection = interface
    ['{1F0822AD-5AD5-42A5-B6AB-46D131AEF79B}']

    {$REGION 'Getters and Setters'}
    function GetDatabase: string;
    procedure SetDatabase(const AValue: string);
    {$ENDREGION}

    function CreateQuery: IQuery;
    function GetLastIdentityValue: int64;

    property Database: string read GetDatabase write SetDatabase;
  end;

  EDatabasePathNotSet = class (EPersistenceException);

  IConnectionFactory = interface
    ['{590AA342-D7F4-4F67-BE7D-CFCCBAF9010A}']

    {$REGION 'Getters and Setters'}
    function GetDatabasePath: string;
    procedure SetDatabasePath(const APath: string);
    {$ENDREGION}

    function CreateConnection: IConnection;

    property DatabasePath: string read GetDatabasePath write SetDatabasePath;
  end;

  ESaveObjectError = class (EPersistenceException);
  ELoadObjectError = class (EPersistenceException);
  EOnlyOneIdentityPropertyAllowed = class (ESaveObjectError);
  EDataObjectMustHaveIntegerIdentity = class (ELoadObjectError);

  IContext = interface
    ['{33ADAA65-E3D6-498D-96E8-2CC0C380E6FC}']
    procedure Load(
      const AList: TDataObjectList;
      const ACriteria: string = ''
    ); overload;
    function Load(
      const ADataObject: TDataObject;
      const AID: integer
    ): boolean; overload;
    procedure Save(const AList: TDataObjectList); overload;
    procedure Save(const ADataObject: TDataObject); overload;
  end;

  IStatementBuilder = interface
    ['{D64C9EA2-9F23-4B27-8750-0DE0C908510B}']
    procedure AddAdditionalWhereAnd(const APredicate: string);
    function Generate: string;
  end;

  EQueryBuilderException = class (EPersistenceException);
  EMissingFieldsException = class (EQueryBuilderException);
  EMissingFromClauseException = class (EQueryBuilderException);

  ISelectBuilder = interface (IStatementBuilder)
    ['{D95ECE3B-1F3B-4274-A19F-B84D1D5FC4AE}']
    procedure AddField(const AFieldClause: string);
    procedure AddFrom(const ATableName: string);
    procedure AddWhereAnd(const APredicate: string);
    procedure AddAdditionalWhereAnd(const APredicate: string);
    function Generate: string;
  end;

  EMissingIntoUpdateClauseException = class (EQueryBuilderException);
  EWhereFieldsNotSupportedForInserts = class (EQueryBuilderException);

  IUpdateInsertBuilder = interface (IStatementBuilder)
    ['{E65F5DB4-EED7-405A-9E28-D5153DE2ABEF}']
    procedure AddFieldParam(const AFieldAndParamName: string);
    procedure AddUpdateInto(const ATableName: string);
    procedure AddWhereField(const AFieldAndParamName: string);
    function Generate: string;
  end;

  IStatementBuilderFactory = interface
    ['{CD22228C-69A3-4828-99A8-4D420D6B3E9E}']
    function CreateSelectBuilder: ISelectBuilder;
    function CreateInsertBuilder: IUpdateInsertBuilder;
    function CreateUpdateBuilder: IUpdateInsertBuilder;
    function CreateEchoBuilder(
      const AStatement: string
    ): IStatementBuilder;
  end;

  EStatementCacheException = class (EPersistenceException);
  ETableNameAttributeNotFound = class (EStatementCacheException);

  IStatementCache = interface
    ['{A47A657C-24CE-4880-A4F9-CC3FDBEF22C8}']
    function GetStatement(
      const AStatementType: TStatementType;
      const AForClass: TDataObjectClass
    ): IStatementBuilder;
    procedure AddStatement(
      const AStatementType: TStatementType;
      const AForClass: TDataObjectClass;
      const AStatement: IStatementBuilder
    );
  end;

implementation

end.
