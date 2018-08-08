unit Persistence.Interfaces;

interface

uses
  System.Classes,
  Persistence.Types;

type

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
    {$ENDREGION}

    procedure Execute;
    procedure Open;

    function FieldByName(const AName: string): IField;
    function ParamByName(const AName: string): IParam;

    property SQL: string read GetSQL write SetSQL;
    property EOF: boolean read GetEOF;
  end;

  IConnection = interface
    ['{1F0822AD-5AD5-42A5-B6AB-46D131AEF79B}']

    {$REGION 'Getters and Setters'}
    function GetDatabase: string;
    procedure SetDatabase(const AValue: string);
    {$ENDREGION}

    function CreateQuery: IQuery;

    property Database: string read GetDatabase write SetDatabase;
  end;

  IConnectionFactory = interface
    ['{590AA342-D7F4-4F67-BE7D-CFCCBAF9010A}']
    function CreateConnection: IConnection;

  end;

  IContext = interface
    ['{33ADAA65-E3D6-498D-96E8-2CC0C380E6FC}']

    procedure Load(const AList: TDataObjectList);

  end;

implementation

end.
