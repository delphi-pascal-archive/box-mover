unit Apropos;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Comments: TLabel;
    OKButton: TButton;
    procedure FormActivate(Sender: TObject);
   private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.dfm}

procedure TAboutBox.FormActivate(Sender: TObject);
begin
     Version.Caption := 'R�alis� d''apr�s le jeu Box World.' + #13 +'    Cr�er par : Jeng-Long Jiang.';
end;

end.

