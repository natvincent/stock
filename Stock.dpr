program Stock;

uses
  Vcl.Forms,
  FormMain in 'Source\FormMain.pas' {MainForm};

{$R stock.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
