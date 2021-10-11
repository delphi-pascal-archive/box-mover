program Demenage;

uses
  Forms,
  Unite in 'Unite.pas' {Form1},
  Apropos in 'Apropos.pas' {AboutBox};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Déménagement';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
