unit Unite;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, Menus;

type
  TForm1 = class(TForm)
    StatusBar1 : TStatusBar;
    MainMenu1: TMainMenu;
    Choisir1: TMenuItem;
    Quitter1: TMenuItem;
    ListBox1: TListBox;
    Apropos1: TMenuItem;
    procedure FormActivate(Sender : TObject);
    procedure FormMouseDown(Sender : TObject;Button : TMouseButton;
              Shift : TShiftState;X,Y : Integer);
    procedure MenuClick(Sender : TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;
const
     cote = 32;
     nivMax = 20;
     but : array[1..nivMax] of Integer =
                    (6,31,27,13,11,24,30,18,41,13,18,5,14,15,14,28,17,38,26,27);
type
    Pvue = ^Tvue;
    Tvue = record
                 pt : TPoint;
                 c,d,a,v : Byte; { c : En cours
                                   d : Début
                                   a : Précédent
                                   v : Vide (sol ou cible)
                                valeur
                                    0 = extérieur         rouge
                                    1 = mur               noir
                                    2 = sol               blanc
                                    3 = caisse            jaune
                                    4 = cible             bleue
                                    5 = caisse sur cible  grise
                                    6 .. 9 = clark        vert
                                    10..13 = leve         type de clark}
           end;
var
   Form1 : TForm1;
   Abi : array[1..9] of TBitmap;    // Eléments du décor
   sens,                            // 0 à gauche, 1 à droite, 2 en haut, 3 en bas
   nivo : Byte;
   gauche,tete,                     // Marges
   long,haut,                       // Dimensions du décor
   sco : Integer;                   // Score
   cible,place : TPoint;            // Déplacement de l'élévateur
   Lvue : TList;

implementation

{$R *.DFM}
{$R DECOR.RES}
{$R ETAGE.RES}

uses
    Apropos;

procedure Montre(bmp : TBitmap;x,y : Integer);
begin
     Form1.Canvas.Draw(x,y,bmp);
end;

procedure Decode(var bmx,bmp : TBitmap);
//Trace le décor en lisant le bitmap
var
   i,j : Byte;
   c : TColor;
begin
     for i := 0 to cote do
     for j := 0 to cote do
     begin
          c := bmx.Canvas.Pixels[i,j];
          with bmp.Canvas do
          if c = RGB(255,0,0) then Pixels[i,j] := Abi[2].Canvas.Pixels[i,j]
                              else Pixels[i,j] := c;
     end;
end;

procedure Vignette;
var
   i : Byte;

   procedure TourneH(B1,B2 : TBitMap);
   begin
        StretchBlt(B2.Canvas.Handle,0,0,B2.Width,B2.Height,
        B1.Canvas.Handle,B1.Width,0,- B1.Width,B1.Height,srcCopy);
   end;

   procedure TourneV(B1,B2 : TBitMap);
   begin
        StretchBlt(B2.Canvas.Handle,0,0,B2.Width,B2.Height,
        B1.Canvas.Handle,0,B1.Height,B1.Width,- B1.Height,srcCopy);
   end;

   procedure TourneX(B1,B2 : TBitMap);
   var
      i,j : Integer;
      c : TColor;
   begin
        for i := 0 to B1.Width do for j := 0 to B1.Height do
        begin
             c := B1.Canvas.Pixels[i,j];
             B2.Canvas.Pixels[B1.Height - 1 - j,i] := c;
        end;
   end;

begin
     for i := 1 to 9 do
     begin
          Abi[i] := TBitmap.Create;
          with Abi[i] do
          begin
               Width := cote;
               Height := cote;
               case i of
                    1 : LoadFromResourceName(HInstance,'MUR');
                    2 : LoadFromResourceName(HInstance,'SOL');
                    3 : LoadFromResourceName(HInstance,'CAISSE');
                    4 : begin
                             LoadFromResourceName(HInstance,'CIBLE');
                             Decode(Abi[i],Abi[i]);
                        end;
                    5 : LoadFromResourceName(HInstance,'PLACE');
                    6 : begin
                             LoadFromResourceName(HInstance,'CLARK');
                             Decode(Abi[i],Abi[i]);
                        end;
                    7 : TourneH(Abi[6],Abi[i]);
                    8 : TourneX(Abi[6],Abi[i]);
                    9 : TourneV(Abi[6],Abi[i]);
               end;
          end;
     end;
end;

procedure Construction;
var
   i,j,k,x,y : Integer;
   st : string;
   Avue : Pvue;
   coul : TColor;
   des1 : TBitmap;
begin
     Form1.Refresh;
     Lvue.Clear;
     st := IntToStr(nivo);
     Form1.StatusBar1.Panels[0].Text := 'Meilleur score : ' +
                               IntToStr(but[nivo]);
     Form1.StatusBar1.Panels[1].Text := '';
     if Length(st) < 2 then st := '0' + st;
     st := 'NIV' + st;
     des1 := TBitmap.Create;
     with des1 do
     begin
          LoadFromResourceName(HInstance,st);
          long := Width;
          haut := Height;
     end;
     with Form1 do
     begin
          i := cote * haut;
          j := cote * long;
          gauche := (ClientWidth - j) div 2;
          tete := (ClientHeight - i) div 2;

          Caption :=  'Le déménageur est au niveau ' + IntToStr(nivo);
     end;
     for j := 0 to haut - 1 do for i := 0 to long - 1 do
     begin
          x := i * cote + gauche;
          y := j * cote + tete;
          coul := des1.Canvas.Pixels[i,j];                   // Couleur du pixel
          if coul = RGB(255,0,0) then k := 0                 // rouge = extérieur
          else
          if coul = RGB(0,0,0) then k := 1                   // noir = mur
          else
          if coul = RGB(255,255,255) then k := 2             // blanc = sol
          else
          if coul = RGB(255,255,0) then k := 3               // jaune = caisse
          else
          if coul = RGB(0,0,255) then k := 4                 // bleu = cible
          else
          if coul = RGB(128,128,128) then k := 5             // gris = cible occupée
          else
          if coul = RGB(0,255,0) then k := 6;                // vert = clark
          if (k > 0) and (k < 7) then Montre(Abi[k],x,y);
          if k = 6 then
          begin
               place.x := x;
               place.y := y;
               k := 2;
          end;
          if k > 1 then
          begin
               New(Avue);
               with Avue^ do
               begin
                    pt.x := x;
                    pt.y := y;
                    c := k;
                    d := k;
                    a := k;
                    if (k = 2) or (k = 3) or (k = 6) then v := 2;
                    if (k = 4) or (k = 5) then v := 4;
               end;
               Lvue.Add(Avue);
          end;
     end;
     des1.Free;
     cible := place;
end;

procedure TForm1.FormActivate(Sender: TObject);
var
   i : Byte;
begin
     nivo := 1;
     sco := 0;
     with Form1 do
     begin
          Caption := 'Rangez toutes les caisses.';
          Color := clInfoBk;
          Color := RGB(5,165,57);
          Width := 560;
          Height := 630;
          Left := (Screen.Width - Width) div 2;
          Top := (Screen.Height - Height) div 2;
          Refresh;
     end;
     for i := 1 to nivMax do ListBox1.Items.Add('Niveau ' + IntToStr(i));
     ListBox1.Height := ListBox1.ItemHeight * (nivMax + 1);
     ListBox1.Top := 2;
     ListBox1.Visible := False;
     Vignette;
     Construction;
end;

procedure FinNiveau;
var
   st : string;
begin
     st := 'Vous avez terminé le niveau ' + IntToStr(nivo) + #13#10;
     if but[nivo] = sco then st := st + 'Vous égalez le meilleur score (' +
                             IntToStr(sco) + ')' + #13#10 +
                             'C''est du bon travail !!'
     else
     if but[nivo] < sco then st := st + 'Votre score (' +
                             IntToStr(sco) + ') peut être amélioré.' + #13#10 +
                             'Peut mieux faire !!'
     else
     if but[nivo] > sco then st := st + 'Votre score (' +
                             IntToStr(sco) + ') est inférieur.' + #13#10 +
                             'Vous êtes le meilleur !!';
     ShowMessagePos(st,Form1.Left - 100,Form1.Top - 50);
     Form1.Refresh;
     Inc(nivo);
     sco := 0;
     if nivo <= nivMax then Construction
                       else
     begin
          Form1.Caption :=  'Le déménageur va se reposer';
          ShowMessage('Le rangement est terminé.' +
                            #13#10 + 'A bientôt j''espère.');
     end;
end;

function Xy(p : TPoint) : Pvue;
var
   ok : Boolean;
   i : Integer;
   Xvue : Pvue;
begin
     i := 0;
     ok := True;
     while (i < Lvue.Count) and ok do
     begin
          Xvue := Lvue.Items[i];
          if (Xvue^.pt.x = p.x) and (Xvue^.pt.y = p.y) then ok := False
                                                       else Inc(i);
     end;
     if ok then Result := nil
           else Result := Xvue;
end;

procedure Deplace;
{valeur
       0 = extérieur
       1 = mur
       2 = sol
       3 = caisse
       4 = cible
       5 = caisse sur cible
       6 .. 9 = clark
       10..13 = leve }
var
   mur,ok : Boolean;
   i,px,cx : Integer;
   avt,k : TPoint;
   Avue,Bvue,Cvue : Pvue;
begin
     mur := True;
     for i := 0 to Lvue.Count - 1 do
     begin
          Avue := Lvue.Items[i];
          Avue^.a := Avue^.c;
     end;
     px := place.x + place.y;
     cx := cible.x + cible.y;
     k.x := 0;
     k.y := 0;
     case sens of
          0 : k.x := - cote;      // vers gauche
          1 : k.x := cote;        // vers droite
          2 : k.y := - cote;      // vers haut
          3 : k.y := cote;        // vers bas
     end;
     while (px <> cx) and mur do
     begin
          Avue := Xy(place);
          avt := place;
          Bvue := nil;
          Cvue := nil;
          ok := False;
          if Avue <> nil then
          begin
               avt.x := avt.x + k.x;
               avt.y := avt.y + k.y;
               Bvue := Xy(avt);
               if Bvue <> nil then
               begin
                    if (BVue^.c = 2) or (BVue^.c = 4) then ok := True  { sol ou cible }
                    else
                    if (BVue^.c = 3) or (BVue^.c = 5) then             { caisse }
                    begin
                         avt.x := avt.x + k.x;
                         avt.y := avt.y + k.y;
                         Cvue := Xy(avt);
                         if Cvue <> nil then
                         begin
                              if CVue^.c = 2 then  { sol }
                              begin
                                   CVue^.c := 3;   { caisse }
                                   ok := True;
                              end
                              else
                              if CVue^.c = 4 then  { cible }
                              begin
                                   CVue^.c := 5;   { caisse sur cible }
                                   ok := True;
                              end
                              else mur := False;
                         end
                         else mur := False;
                    end
                    else mur := False;
               end
               else mur := False;
          end
          else mur := False;
          if ok then
          begin
               AVue^.c := AVue^.v;
               Montre(Abi[AVue^.c],AVue^.pt.x,AVue^.pt.y);
               if CVue <> nil then
               begin
                    BVue^.c := 6 + sens;
                    Montre(Abi[BVue^.c],BVue^.pt.x,BVue^.pt.y);
                    Montre(Abi[CVue^.c],CVue^.pt.x,CVue^.pt.y);
                    Inc(sco);
                    Form1.StatusBar1.Panels[1].Text := ' Votre score : ' + IntToStr(sco);
               end
               else
               begin
                    BVue^.c := 6 + sens;
                    Montre(Abi[BVue^.c],BVue^.pt.x,BVue^.pt.y);
               end;
               place := BVue^.pt;
               px := place.x + place.y;
          end;
     end;
     i := 0;
     mur := True;
     while (i < Lvue.Count) and mur do
     begin
          Avue := Lvue.Items[i];
          if Avue^.c = 3 then mur := False     { caisse }
                         else Inc(i);
     end;
     if mur then FinNiveau;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
     x := ((x - gauche) div cote) * cote + gauche;
     y := ((y - tete) div cote) * cote + tete;
     sens := 4;
     if y = place.y then
     begin
          if x < place.x then sens := 0       // vers gauche
          else
          if x > place.x then sens := 1;      // vers droite
     end
     else
     if x = place.x then
     begin
          if y < place.y then sens := 2       // vers haut
          else
          if y > place.y then sens := 3;      // vers bas
     end;
     if sens < 4 then
     begin
          cible.x := x;
          cible.y := y;
          Deplace;
     end;
end;

procedure TForm1.MenuClick(Sender: TObject);
var
   id : Byte;
begin
     id := (Sender as TMenuItem).Tag;
     case id of
        1 : begin
                 ListBox1.Visible := True;
                 ListBox1.ItemIndex := nivo - 1;
                 ListBox1.SetFocus;
            end;
        2 : Apropos.AboutBox.ShowModal;
        3 : begin
                 for id := 1 to 9 do Abi[id].Free;
                 Application.Terminate
            end;
     end;
end;

procedure TForm1.ListBox1Click(Sender: TObject);
begin
     nivo := ListBox1.ItemIndex + 1;
     ListBox1.Visible := False;
     sco := 0;
     Construction;
end;

initialization
// Création de la liste
  Lvue := TList.Create;

finalization
// Destruction de la liste
  Lvue.Free;

end.
