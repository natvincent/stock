#define MyAppName "Stock"
#define MyAppVersion GetFileVersion("Win32\Release\Stock.exe")
#define MyAppPublisher "Natalie Vincent"
#define MyAppURL "https://github.com/natvincent/stock"
#define MyAppExeName "Stock.exe"

[Setup]
AppId={{91D94C79-8DAC-46E5-AE39-8EC017DF5BB5}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Win32\Release
OutputBaseFilename=SetupStock
Compression=lzma
SolidCompression=yes
SetupIconFile=stock.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "Win32\Release\Stock.exe"; DestDir: "{app}"; 
Source: "Data\Stock.sdb"; DestDir: {code:DataDirectory}; Flags: IgnoreVersion;

[Dirs]
Name: "{code:DataDirectory}"; Permissions: everyone-full;

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]

const
  CProgramDirectory = '{#MyAppName}\';

function InstallInProgramFiles: boolean;
begin
  result := Pos(ExpandConstant('{pf}'), ExpandConstant('{app}')) > 0;
end;

function AppData(Param: string): string;
begin
  if InstallInProgramFiles() then
  begin
    result := ExpandConstant('{commonappdata}');
    result := result + '\' + CProgramDirectory
  end
  else
    result := ExpandConstant('{app}');
end;
	
function DataDirectory(Param: string): string;
begin
  if InstallInProgramFiles() then
    result := AppData(Param)
  else
    result := AppData(Param) + 'Data\';
end;
