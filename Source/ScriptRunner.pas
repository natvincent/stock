unit ScriptRunner;

interface

procedure ExecuteScript(
  const AScriptFilename: string;
  const ATargetDatabaseFilename: string
);

implementation

uses
  FireDAC.Phys.SQLite,
  FireDAC.DApt,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Comp.Client,
  FireDAC.Comp.Script,
  FireDAC.Comp.ScriptCommands,
  FireDAC.UI.Intf,
  System.SysUtils;

type

  TEventSink = class
  public
    procedure ConsolePut(
      AEngine: TFDScript;
      const AMessage: String;
      AKind: TFDScriptOutputKind
    );
    procedure Error(
      ASender, AInitiator: TObject;
      var AException: Exception
    );
  end;

procedure ExecuteScript(
  const AScriptFilename: string;
  const ATargetDatabaseFilename: string
);
var
  LConnection: TFDConnection;
  LScriptRunner: TFDScript;
  LSink: TEventSink;
begin
  LSink := TEventSink.Create;
  try
    LConnection := TFDConnection.Create(nil);
    try
      LConnection.Params.DriverID := 'SQLite';
      LConnection.Params.Values['OpenMode'] := 'CreateUTF16';
      LConnection.Params.Database := ATargetDatabaseFilename;

      LScriptRunner := TFDScript.Create(nil);;
      try
        LScriptRunner.OnConsolePut := LSink.ConsolePut;
        LScriptRunner.OnError := LSink.Error;
        LScriptRunner.Connection := LConnection;
        LScriptRunner.ExecuteFile(AScriptFilename);
      finally
        LScriptRunner.Free;
      end;

    finally
      LConnection.Free;
    end;
  finally
    LSink.Free;
  end;
end;

{ TEventSink }

procedure TEventSink.ConsolePut(
  AEngine: TFDScript;
  const AMessage: String;
  AKind: TFDScriptOutputKind
);
begin
  WriteLn(AMessage);
end;

procedure TEventSink.Error(ASender, AInitiator: TObject;
  var AException: Exception);
begin
  WriteLn(Format('Exception %s %s', [AException.ClassName, AException.Message]));
end;

end.
