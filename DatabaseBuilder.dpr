program DatabaseBuilder;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  ScriptRunner in 'Source\ScriptRunner.pas';

procedure ShowHeader;
begin
  WriteLn('SQLite Database Builder');
  WriteLn;
end;

procedure ShowHelp;
begin
  WriteLn('  databasebuilder.exe <script-filename> <target-database>');
  WriteLn('  <script-filename>   the file containing the script to build the database');
  WriteLn('  <target-database>   the database file to build');
  WriteLn('                      NOTE: if it exists, the database will be deleted first!');
  WriteLn;
end;

var
  LScriptFilename: string;
  LTargetDatabase: string;
begin
  try
    ShowHeader;
    LScriptFilename := ParamStr(1);
    if not FileExists(LScriptFilename) then
    begin
      ShowHelp;
      Writeln(Format('The script file %s was not found.', [LScriptFilename]));
      {$ifdef debug}
      ReadLn;
      {$endif}
      Halt(1)
    end;

    LTargetDatabase := ParamStr(2);
    if FileExists(LTargetDatabase) and not DeleteFile(LTargetDatabase) then
    begin
      WriteLn(Format('Unable to delete the database at %s', [LTargetDatabase]));
      {$ifdef debug}
      ReadLn;
      {$endif}
      Halt(1);
    end;

    ExecuteScript(LScriptFilename, LTargetDatabase);

    {$ifdef debug}
    ReadLn;
    {$endif}

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
