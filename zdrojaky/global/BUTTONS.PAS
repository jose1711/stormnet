{ tato jednotka provadi testovani kurzoru mysi a z toho vyplyvajici akce
}
{$C FIXED PRELOAD PERMANENT}
unit Buttons;

interface
uses Crt, Graph257, Data_glb, Mouse, _research, GlobalKod;

const MaxButtons = 25;
      NotEnoughMemory = 256;
      XORColor = 31;
      ADRng1 = 4;
      ADRng2 = 8;
      ADRng3 = 16;
      ADRng4 = 200;
      DarkColor = 79;

procedure LoadButtonFile(Way:String; PushMovements1,PushMovements2:Word);
procedure LoadType3Button(Way, Name:String; PushMovements:Word; Index:Byte);
procedure ButtonsColors(Color1,Color2,Color3,Color4:Byte);
function CreateButton(X,Y:Word; _ButtonType,_Index:Word; StoreBackGround:Boolean;
                      Number:Word):Word;
procedure DeleteButton(Number,Color:Word);
procedure ButtonText(Number:Word; Color1:Word; ButtonText:String);
procedure SetActive(Number:Word);
procedure SetPasive(Number:Word; Color:Word);
procedure Release(Number:Word);
procedure PushDown(Number:Word);
procedure ButtonFrame(Number:Word; Color:Byte);
function Down(Number:Word):Boolean;
function Active(Number:Word):Boolean;
procedure ClearKeyboardBuffer;
function MousKeybClick(var X,Y,Butt,Scan,Ascii:Word):Word;
function MousKeybClick2(var X,Y,Butt,Scan,Ascii:Word):Word;
procedure Keyb(var Scan,Ascii:Word);
procedure TestButton(X,Y:Word; var Button:Byte);
procedure ButtonManager;
procedure Buttons_save;
procedure Buttons_load;

var On1Seg,On1Offs, Off1Seg,Off1Offs, On2Seg,On2Offs, Off2Seg,Off2Offs: Word;

implementation

uses GlobGraf, SpecGraf;
var Type3Pictures: array[1..MaxButtons] of record
                      OnSeg,OnOffs,OffSeg,OffOffs:Word;
                   end;

    { tlacitka }
    ButtonsInfo: array[1..MaxButtons] of record { zaznam o tlacitkach }
                   Exist:Boolean; { existuje tlacitko? }
                   X1,Y1,X2,Y2:Word; { souradnice tlacitka }
                   PushMovement:Word; { pohyb tlacitka (textu) pri jeho
                   stisknuti v bodech }
                   Segment,Offsets:Word; { pripadne uchovane pozadi pod
                   tlacitkem; pro Segment = 0 pozadi neuchovano }
                   Active:Boolean; { True - je aktivni; False - je pasivni }
                   XText,YText:Word; { vystredeni textu }
                   Color1:Byte; { Color textu }
                   ButtonText:String[20]; { text na tlacitku }
                   ButtonType:Word; { typ tlacitka 1-2-3 }
                   Down:Boolean; { True - tlacitko je stisknuto, jinak uvolneno }
                   Index:Byte; { pro tlacitka typu 3 index do pole obrazku }
                end;
      Button1Size, Button2Size, Button3Size:LongInt;
      { pametova narocnost tlacitek }
      Button1X,Button1Y,Button2X,Button2Y,
      Button3X,Button3Y:Word; { rozmery tlacitek }
      PushMovement1,PushMovement2,PushMovement3:Word;
      { pohyb tlacitek (textu) pri jeho stisknuti v bodech }

      Scrolling : Boolean;{ True, pokud probiha rolovani }
      XScroll, YScroll : Word; { referencni pozice pro rolovani }
      I:Integer;  { pomocna promenna }
      LeftButton, MiddleButton, RightButton : Byte;
      { pokud se rovnaji 0, pak je mozne tyto tlacitka akceptovat,
        jinak se ignoruji a promenne dekrementuji }
      SurfaceColor : Byte;
      LastName:String[15];
      LastRace:Byte;
      LastScroll:Boolean; { True, bylo-li v minulem slotu rolovano }
      LastX, LastY : Word; { souradnice mysi v minulem casovem slotu }
      MouseEqualCount : Byte; { souvisi s predchozim a udava pocet shod
      aktualni a minule pozice mysi za sebou (tyka se i Button) }
      ChangeCursorLevel : Boolean; { byla-li drzenim mysi na miste zmenena
      uroven kurzoru, nastavi se na True }
      CursorChanged : Boolean; { stejne jako predchozi }
      GAMETIME,POMTIME:Word;

{ ***** }
procedure LoadButtonFile(Way:String; PushMovements1,PushMovements2:Word);
{ nahraje soubor s definovanymi tlacitky; soubor musi byt ve formatu GBM
  a definovany celkem dve tlacitka, kazde ve dvou pozicich (vypnuto, zapnuto).
  Nazvy obrazku musi byt on1, off1, on2, off2.
  pozn. Musi platit : velikost on1 = off1; velikost on2 = off2 !!!
}
var X,Y:Word;
begin
   PushMovement1:=PushMovements1;
   PushMovement2:=PushMovements2;
   OpenImage(Way, NoCreateNew);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);

   GetXYImageCoordinatesGBM(Button1X,Button1Y,'on1');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
   { alokace pameti pro tlacitko on1 }
   Button1Size:=(LongInt (Button1X))*(LongInt (Button1Y))+4;
   GetMemory(Button1Size,On1Seg, On1Offs);
   if (On1Seg = 0) then Error(IO_Result,'- malo konvencni pameti');

   { alokace pameti pro tlacitko off1 }
   GetMemory(Button1Size,Off1Seg, Off1Offs);
   if (Off1Seg = 0) then Error(IO_Result,'- malo konvencni pameti');

   GetXYImageCoordinatesGBM(Button2X,Button2Y,'on2');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
   { alokace pameti pro tlacitko on2 }
   Button2Size:=(LongInt (Button2X))*(LongInt (Button2Y))+4;
   GetMemory(Button2Size,On2Seg, On2Offs);
   if (On2Seg = 0) then Error(IO_Result,'- malo konvencni pameti');

   { alokace pameti pro tlacitko off2 }
   GetMemory(Button2Size,Off2Seg, Off2Offs);
   if (Off2Seg = 0) then Error(IO_Result,'- malo konvencni pameti');

   { vlastni nahrani tlacitek }
   LoadImageGBM(On1Seg,On1Offs,'on1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
   LoadImageGBM(Off1Seg,Off1Offs,'off1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
   LoadImageGBM(On2Seg,On2Offs,'on2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
   LoadImageGBM(Off2Seg,Off2Offs,'off2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
end;

{ ***** }
procedure LoadType3Button(Way, Name:String; PushMovements:Word; Index:Byte);
{ nahraje soubor s definovanymi tlacitky typu 3; soubor musi byt ve
  formatu GBM s definovanym obrazkem Name+'on' a Name+'off'
}
var X,Y:Word;
begin
   PushMovement3:=PushMovements;
   if (Index <= MaxButtons) then with (Type3Pictures[Index]) do begin
{      if (OnSeg <> 0) then DisposeImage(OnSeg, OnOffs);
      if (OffSeg <> 0) then DisposeImage(OffSeg, OffOffs);{}
      OpenImage(Way, NoCreateNew);
      if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);

      GetXYImageCoordinatesGBM(Button3X,Button3Y,Name+'on');
      if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
      { alokace pameti pro tlacitko on }
      Button3Size:=(LongInt (Button3X))*(LongInt (Button3Y))+4;
      GetMemory(Button3Size,OnSeg, OnOffs);
      if (OnSeg = 0) then Error(IO_Result,'- malo konvencni pameti');
      { alokace pameti pro tlacitko off }
      GetMemory(Button3Size,OffSeg, OffOffs);
      if (OffSeg = 0) then Error(IO_Result,'- malo konvencni pameti');

      { vlastni nahrani tlacitek }
      LoadImageGBM(OnSeg,OnOffs,Name+'on',0);
      if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
      LoadImageGBM(OffSeg,OffOffs,Name+'off',0);
      if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Way);
   end;
end;

{ ***** }
procedure ButtonsColors(Color1,Color2,Color3,Color4:Byte);
{ Definuje barvy tlacitka:
  Color2 ... velmi svetla (levy a horni obrys)
  Color1 ... stredni  (povrch tlacitka)
  Color3 ... tmava  (pravy a spodni obrys)
  Color4 ... velmi tmava  (levy a horni obrys pri stisknutem tlacitku)
}
begin
  SurfaceColor:=Color1;
  if (On1Seg <> 0) and (On2Seg <> 0) and (Off1Seg <> 0) and (Off2Seg <> 0)
  then begin
    asm                 { ON1 }
       mov Ax,On1Seg
       mov Es,Ax
       mov Di,On1Offs
       add Di,4
       mov Dx,Button1Y  {!}
@again:
       mov Cx,Button1X  {!}
@row:
       mov Al,Es:[Di]
       cmp Al,1
       je @Color1
       cmp Al,2
       je @Color2
       cmp Al,3
       je @Color3
       cmp Al,4
       je @Color4
       jmp @Store
@Color1:
       mov Al,Color1
       jmp @Store
@Color2:
       mov Al,Color2
       jmp @Store
@Color3:
       mov Al,Color3
       jmp @Store
@Color4:
       mov Al,Color4

@Store:
       mov Es:[Di],Al
       inc Di
       loop @row
       dec Dx
       jnz @again
    end;  { asm }

    asm                 { OFF1 }
       mov Ax,Off1Seg
       mov Es,Ax
       mov Di,Off1Offs
       add Di,4
       mov Dx,Button1Y  {!}
@again:
       mov Cx,Button1X  {!}
@row:
       mov Al,Es:[Di]
       cmp Al,1
       je @Color1
       cmp Al,2
       je @Color2
       cmp Al,3
       je @Color3
       cmp Al,4
       je @Color4
       jmp @Store
@Color1:
       mov Al,Color1
       jmp @Store
@Color2:
       mov Al,Color2
       jmp @Store
@Color3:
       mov Al,Color3
       jmp @Store
@Color4:
       mov Al,Color4
@Store:
       mov Es:[Di],Al
       inc Di
       loop @row
       dec Dx
       jnz @again
    end;  { asm }

    asm                 { ON2 }
       mov Ax,On2Seg
       mov Es,Ax
       mov Di,On2Offs
       add Di,4
       mov Dx,Button2Y  {!}
@again:
       mov Cx,Button2X  {!}
@row:
       mov Al,Es:[Di]
       cmp Al,1
       je @Color1
       cmp Al,2
       je @Color2
       cmp Al,3
       je @Color3
       cmp Al,4
       je @Color4
       jmp @Store
@Color1:
       mov Al,Color1
       jmp @Store
@Color2:
       mov Al,Color2
       jmp @Store
@Color3:
       mov Al,Color3
       jmp @Store
@Color4:
       mov Al,Color4
@Store:
       mov Es:[Di],Al
       inc Di
       loop @row
       dec Dx
       jnz @again
    end;  { asm }

    asm                 { OFF2 }
       mov Ax,Off2Seg
       mov Es,Ax
       mov Di,Off2Offs
       add Di,4
       mov Dx,Button2Y  {!}
@again:
       mov Cx,Button2X  {!}
@row:
       mov Al,Es:[Di]
       cmp Al,1
       je @Color1
       cmp Al,2
       je @Color2
       cmp Al,3
       je @Color3
       cmp Al,4
       je @Color4
       jmp @Store
@Color1:
       mov Al,Color1
       jmp @Store
@Color2:
       mov Al,Color2
       jmp @Store
@Color3:
       mov Al,Color3
       jmp @Store
@Color4:
       mov Al,Color4
@Store:
       mov Es:[Di],Al
       inc Di
       loop @row
       dec Dx
       jnz @again
    end;  { asm }
  end;
end;

{ ***** }
function CreateButton(X,Y:Word; _ButtonType,_Index:Word; StoreBackGround:Boolean;
                      Number:Word):Word;
{ Vytvori (ale nezobrazi!) tlacitko cisla Number typu ButtonType na
  pozici X,Y.  Nastavi aktivitu na False.
  ButtonType muze byt 0 nebo 1 nebo 2; Index je Index pro tlacitko typu 2
  Je-li StoreBackGround = True, uchova pozadi pod tlacitkem.
  Sama funkce vraci 0, byla-li uspesna, 256 je-li nedostatek pameti
  a jine cisla :
  1 .. tlacitko daneho cisla jiz existuje
  2 .. chybne cislo tlacitka
}
label Konec;
var Pom:Word;
begin
   Pom:=2;
   if (Number > MaxButtons) or (Number < 1) then GoTo Konec; { range check }

   Pom:=1;
   {if (ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }

   with ButtonsInfo[Number] do begin { definovani X1,Y1,X2,Y2 }
     X1:=X;
     Y1:=Y;
     if (_ButtonType = 0) then begin
        X2:=X+Button1X;
        Y2:=Y+Button1Y;
        PushMovement:=PushMovement1;
     end else begin { typ 1 }
       if (_ButtonType = 1) then begin
         X2:=X+Button2X;
         Y2:=Y+Button2Y;
         PushMovement:=PushMovement2;
       end else begin { typ 2 }
          X2:=X+Button3X-1;
          Y2:=Y+Button3Y-1;
          PushMovement:=PushMovement3;
          Index:=_Index;
          GetMemory(Button3Size,Segment,Offsets);
          if (Segment = 0) then GoTo Konec;
          SpeedGetImage(X1,Y1,X2,Y2,Segment,Offsets);
       end;
     end;
     ButtonType:=_ButtonType;
     Down:=False;

     if (StoreBackGround) then begin { uchovat pozadi }
        Pom:=NotEnoughMemory;
        if (_ButtonType = 0) then
          GetMemory(Button1Size,Segment,Offsets)
        else
          GetMemory(Button2Size,Segment,Offsets);
        if (Segment = 0) then GoTo Konec;

        SpeedGetImage(X1,Y1,X2,Y2,Segment,Offsets);
     end;

     Exist:=True;
     Active:=False;
     Pom:=0;
   end;  { with }
Konec:
   CreateButton:=Pom;
end;

{ ***** }
function IsMouseInButtonRegion(Button:Word):Boolean;
{ je mys v regionu daneho tlacitka ?
}
label Konec;
begin
   if ((Button <= MaxButtons) and (Button >= 1) and
       (ButtonsInfo[Button].Exist) and (ButtonsInfo[Button].Active))
   then with (ButtonsInfo[Button]) do begin
      IsMouseInButtonRegion:=TestMouseLeftTop(X1,Y1,X2,Y2);
   end;
Konec:
end;

{ ***** }
function IsMouseInAnyButtonRegion:Byte;
{ vraci cislo tlacitka, nad nimz je mys, jinak vraci 255
}
label Konec;
var I:Word;
    Result:Boolean;
begin
   Result:=False; I:=1;
   while ((I < MaxButtons) and (not Result)) do
   with (ButtonsInfo[I]) do begin
     if (Exist and Active) then begin
        Result:=TestMouseLeftTop(X1,Y1,X2,Y2);
     end;
     if (not Result) then Inc(I);
   end;
   if (Result) then IsMouseInAnyButtonRegion:=I else IsMouseInAnyButtonRegion:=255;
Konec:
end;

{ ***** }
procedure RestoreButtonColor(Number:Word);
{ obnovi barvu tlacitka button
}
var Mous:Boolean;
    Add:Word;
begin
   if ((Number <= MaxButtons) and (Number >= 1) and
       (ButtonsInfo[Number].Exist) and (ButtonsInfo[Number].Active))
   then with (ButtonsInfo[Number]) do begin
      with (ButtonsInfo[Number]) do begin
        if (Down) then Add:=PushMovement else Add:=0;
        Mous:=TestMouse(X1,Y1,X2,Y2) and (CursorVisibility = 1);
        if (Mous) then CursorOff;
        if (Buttontype = 0) then begin
           OutTextColor(XText+2+Add,YText+2+Add,DarkColor,ButtonText);
           if (Yellow = 160) then SetColor(Color1+5) else SetColor(DarkYellow);
           OutText(XText,YText,ButtonText);
        end else
          if (Buttontype = 1) then begin
             OutTextColor(XText+2+Add,YText+2+Add,DarkColor,ButtonText);
             if (Yellow = 160) then SetColor(Color1+5) else SetColor(DarkYellow);
             OutText(XText,YText,ButtonText);
          end;
        if (Mous) then CursorOn;
      end;
   end;
end;

{ ***** }
procedure LightButtonColor(Number:Word);
{ obnovi barvu tlacitka button
}
var Mous:Boolean;
    Add:Word;
begin
   if ((Number <= MaxButtons) and (Number >= 1) and
       (ButtonsInfo[Number].Exist) and (ButtonsInfo[Number].Active))
   then with (ButtonsInfo[Number]) do begin
      with (ButtonsInfo[Number]) do begin
        if (Down) then Add:=PushMovement else Add:=0;
        Mous:=TestMouse(X1,Y1,X2,Y2) and (CursorVisibility = 1);
        if (Mous) then CursorOff;
        if (Buttontype = 0) then begin
           OutTextColor(XText+2+Add,YText+2+Add,DarkColor,ButtonText);
           if (Yellow = 160) then SetColor(Color1) else SetColor(Yellow);
           OutText(XText,YText,ButtonText);
        end else
          if (Buttontype = 1) then begin
             OutTextColor(XText+2+Add,YText+2+Add,DarkColor,ButtonText);
             if (Yellow = 160) then SetColor(Color1) else SetColor(Yellow);
             OutText(XText,YText,ButtonText);
          end;
        if (Mous) then CursorOn;
      end;
   end;
end;

{ ***** }
procedure DeleteButton(Number,Color:Word);
{ zrusi tlacitko Number prekreslenim barvou Color;
 je-li Color > 255, pak se tlacitko zrusi, ale na obrazovce nesmaze
}
label Konec;
var FillStyl,FillCol:Byte;
begin
   if (Number > MaxButtons) or (Number < 1) then GoTo Konec; { range check }
   if not(ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }
   ButtonsInfo[Number].Exist:=False;
   if ((ButtonsInfo[Number].Segment <> 0) and (ButtonsInfo[Number].ButtonType = 2))
   then begin { uchovano pozadi }
      PutMemory(Button3Size,ButtonsInfo[Number].Segment,ButtonsInfo[Number].Offsets);{}
   end else begin
     if (Color <= 255) then begin
       Rectangle(ButtonsInfo[Number].X1,ButtonsInfo[Number].Y1,
                 ButtonsInfo[Number].X2,ButtonsInfo[Number].Y2,Color);
     end;
   end;
Konec:
end;

{ ***** }
procedure ButtonText(Number:Word; Color1:Word; ButtonText:String);
{ U daneho tlacitka nastavi text a jeho atributy.
  Text se zobrazi po prvnim zavolani PushDown nebo Release
}
const FontLength = XFontSize;
      Height = YFontSize;
label Konec;
var TextLength:Word;
begin
   if (Number > MaxButtons) or (Number < 1) then GoTo Konec; { range check }
   if not(ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }

   TextLength:=Length(ButtonText)*FontLength;
   ButtonsInfo[Number].Color1:=Color1;
   ButtonsInfo[Number].ButtonText:=ButtonText;
   with (ButtonsInfo[Number]) do begin
     XText:=X1+(abs(X2-X1-TextLength-2*PushMovement)) div 2+PushMovement;
     YText:=Y1+(abs(Y2-Y1-Height-2*PushMovement)) div 2+PushMovement;
   end;
Konec:
end;

{ ***** }
procedure SetActive(Number:Word);
{ tlacitko Number bude aktivni - reagovat na kurzor mysi + clicknuti
}
label Konec;
var Mouse:Boolean;
    Color:Byte;
begin
   if not(ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }
   if (Number < MaxButtons) and (Number > 0) then
   with (ButtonsInfo[Number]) do begin { range check }
      if (Yellow = 160) then Color:=Color1+5 else Color:=DarkYellow;
      if (IsMouseInButtonRegion(Number)) then begin
         if (LastButton <> 255) then RestoreButtonColor(LastButton);
         LastButton:=Number;
         if (Yellow = 160) then Color:=Color1 else Color:=Yellow;
      end;
      if (TestMouse(X1,Y1,X2,Y2)) then Mouse:=True;
      Active:=True;
      if (ButtonType < 2) then begin
        OutTextColor(XText+2,YText+2,DarkColor,ButtonText);
        SetColor(Color); OutText(XText,YText,ButtonText);
      end else begin { typ2 }
        {if (Mouse) then CursorOff;{}
        SpeedPutImage2(X1,Y1,Type3Pictures[Index].OnSeg,
                            Type3Pictures[Index].OnOffs);
        {if (Mouse) then CursorOn;{}
      end;
   end;
Konec:
end;

{ ***** }
procedure SetPasive(Number:Word; Color:Word);
{ tlacitko Number bude pasivni ("usne"); je-li Color < 256, pak se
  tlacitko prekresli barvou Color, jinak se neprekresli
}
label Konec;
var XX1, XX2, YY1, YY2 : Word;
    Mouse:Boolean;
begin
   if not(ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }
   if (Number < MaxButtons) and (Number > 0) then
   with (ButtonsInfo[Number]) do begin { range check }
      Active:=False;
      if (TestMouse(X1,Y1,X2,Y2)) then Mouse:=True;
      if (ButtonsInfo[Number].ButtonType < 2) then begin
         XX1:=XText; YY1:=YText;
         XX2:=XX1+Length(ButtonText)*XFontSize;
         if ((XX2 - XX1) mod 2 = 0) then Inc(XX2);
         YY2:=YY1+YFontSize;
         {if (Mouse) then CursorOff;{}
         if (Color < 256) then
           Rectangle(XX1,YY1,XX2,YY2,Byte(Color));
         {if (Mouse) then CursorOn;{}
      end else begin { typ 2 }
         {if (Mouse) then CursorOff;{}
         SpeedPutImage(X1,Y1,Segment,Offsets);
         {if (Mouse) then CursorOn;{}
      end;
   end;
Konec:
end;

{ ***** }
procedure Release(Number:Word);
{  zobrazi tlacitko Number jako "uvolnene" (nestisknute)
}
label Konec;
var Color:Byte;
begin
   if not(ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }
   if (Number < MaxButtons) and (Number > 0) then begin; { range check }
     with (ButtonsInfo[Number]) do begin
        ButtonClick:=0; Button:=0;
        if (Yellow = 160) then Color:=Color1+5 else Color:=DarkYellow;
        if (IsMouseInButtonRegion(Number)) then begin
           if (LastButton <> 255) then RestoreButtonColor(LastButton);
           LastButton:=Number;
           if (Yellow = 160) then Color:=Color1 else Color:=Yellow;
        end;
        if (Buttontype = 0) then begin
           SpeedPutImage2(X1,Y1,On1Seg,On1Offs);
           OutTextColor(XText+2,YText+2,DarkColor,ButtonText);
           SetColor(Color); OutText(XText,YText,ButtonText);
        end else
          if (Buttontype = 1) then begin
             SpeedPutImage2(X1,Y1,On2Seg,On2Offs);
             OutTextColor(XText+2,YText+2,DarkColor,ButtonText);
             SetColor(Color); OutText(XText,YText,ButtonText);
          end else
             SpeedPutImage2(X1,Y1,Type3Pictures[Index].OnSeg,
                            Type3Pictures[Index].OnOffs);
     end; { with }
   end;
Konec:
end;

{ ***** }
procedure PushDown(Number:Word);
{  zobrazi tlacitko Number jako stisknute
}
label Konec;
var Color : Byte;

begin
   if (Number < MaxButtons) and (Number > 0) then begin; { range check }
     with (ButtonsInfo[Number]) do begin
        if (not(Exist)) then GoTo Konec;
        {PreparePlaySound(6,0,0,0); { zvuk clicknuti }
        ButtonClick:=0; Button:=0;
        if (Yellow = 160) then Color:=Color1+5 else Color:=DarkYellow;
        if (IsMouseInButtonRegion(Number)) then begin
           if (LastButton <> 255) then RestoreButtonColor(LastButton);
           LastButton:=Number;
           if (Yellow = 160) then Color:=Color1 else Color:=Yellow;
        end;
        if (ButtonType = 0) then begin
           SpeedPutImage2(X1,Y1,Off1Seg,Off1Offs);
           OutTextColor(XText+2+PushMovement,YText+2+PushMovement,DarkColor,ButtonText);
           SetColor(Color); OutText(XText+PushMovement,YText+PushMovement,ButtonText);
        end else
           if (Buttontype = 1) then begin
             SpeedPutImage2(X1,Y1,Off2Seg,Off2Offs);
             OutTextColor(XText+2+PushMovement,YText+2+PushMovement,DarkColor,ButtonText);
             SetColor(Color); OutText(XText+PushMovement,YText+PushMovement,ButtonText);
           end else
             SpeedPutImage2(X1,Y1,Type3Pictures[Index].OffSeg,
                            Type3Pictures[Index].OffOffs);

     end; { with }
   end;
Konec:
end;

{ ***** }
procedure ButtonFrame(Number:Word; Color:Byte);
{ vykresli ramecek kolem tlacitka Number
}
label Konec;
begin
   if (Number < MaxButtons) and (Number > 0) then begin; { range check }
     with (ButtonsInfo[Number]) do begin
        if (not(Exist)) then GoTo Konec;
           Frame(X1-3,Y1-3,X2+1,Y2+1,Color);
     end; { with }
   end;
Konec:
end;

{ ***** }
function Down(Number:Word):Boolean;
{ Vraci True, je-li dane tlacitko v poloze "stisknuto"
}
label Konec;
begin
   if ((Number > MaxButtons) or (Number <= 0)) then Goto Konec; { range check }
   if ButtonsInfo[Number].Down then Down:=True else Down:=False;
Konec:
end;

{ ***** }
function Active(Number:Word):Boolean;
{ Vraci True, je-li dane tlacitko aktivni
}
label Konec;
begin
   Active:=False;
   if not(ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }
   if ((Number > MaxButtons) or (Number <= 0)) then Goto Konec; { range check }
   if ButtonsInfo[Number].Active then Active:=True else Active:=False;
Konec:
end;

{ ***** }
function MouseClick(var X,Y,Button:Word):Word;
{ V parametrech X,Y vraci souradnice stisku tlacitka mysi,
  v Button kod stisknuteho tlacitka, sama funkce pak vraci
  cislo stisknuteho tlacitka nebo 0.
}
var Number:Word;
    Konec:Boolean;
begin
   GetCursorPos(X,Y,Button);
   while (Button = 0) do GetCursorPos(X,Y,Button); { cekani na stisk }
   Number:=1; Konec:=False; MouseClick:=0;
   while not(Konec) do begin
     with (ButtonsInfo[Number]) do begin
        if (Exist) and (Active) and (X1<=X) and (X2>=X) and { tlacitko }
           (Y1<=Y) and (Y2>=Y) then begin                   { nalezeno }
           Konec:=True;
           MouseClick:=Number;
        end else begin
          Number:=Number+1;
          Konec:=(Number>MaxButtons);
        end;
     end;   { with }
   end;   { while }
end;

{ ***** }
procedure Keyb(var Scan,Ascii:Word);
{ vraci stav klavesnice
}
var Sc,Asc:Word;
begin
   asm
      mov Ah,11h
      int 16h
      jz @EmptyBuffer
      mov Dx,0
      mov Dl,Al
      mov Asc,Dx
      mov Dl,Ah
      mov Sc,Dx

      mov Ah,10h   { vybere znak z bufferu }
      int 16h
      jmp @Konec
@EmptyBuffer:
      mov Sc,0
@Konec:
   end;
   Scan:=Sc; Ascii:=Asc;
end;

procedure ClearKeyboardBuffer;
{ vycisti buffer klavesnice
}
var Scan:Byte;
begin
   while (ReadKeys(Scan) <> 0) do;
end;

{ ***** }
function MousKeybClick(var X,Y,Butt,Scan,Ascii:Word):Word;
{ V parametrech X,Y vraci souradnice stisku tlacitka mysi,
  v Butt kod stisknuteho tlacitka, a v Scan,Ascii kody klavesy.
  Sama funkce pak vraci cislo stisknuteho tlacitka nebo 0, byla-li
  mys stisknuta jinde nez na tlacitku nebo byla-li stisknuta klavesa.
  Pokud klavesa nebyla stisknuta, vraci se ve Scan cislo 0.
}
label Ukonceni;
var Number, Temp:Word;
    Konec:Boolean;
begin
   GetMouseClick(X,Y,Butt); Keyb(Scan,Ascii);
   while (Butt = 0) and (Scan = 0) do begin
      GetMouseClick(X,Y,Butt); { cekani na stisk }
      Keyb(Scan,Ascii);
      Temp:=IsMouseInAnyButtonRegion;
      if ((Temp <> 255) and (Temp <> LastButton)) then begin
         if (LastButton <> 255) then RestoreButtonColor(LastButton);
         LastButton:=Temp; LightButtonColor(Temp);
      end else begin
         if (Temp = 255) then begin
           if (LastButton <> 255) then RestoreButtonColor(LastButton);
           LastButton:=255;
         end;
      end;
   end;
   MousKeybClick:=0;
   if (Scan <> 0) then GoTo Ukonceni; { klavesa }

   Number:=1; Konec:=False;
   while not(Konec) do begin
     with (ButtonsInfo[Number]) do begin
        if (Exist) and (Active) and (X1<=X) and (X2>=X) and { tlacitko }
           (Y1<=Y) and (Y2>=Y) then begin                   { nalezeno }
           Konec:=True;
           MousKeybClick:=Number;
           CursorOff;
           if (Down) then begin
             Release(Number);
             Delay(150);
             PushDown(Number);
           end else begin
             PushDown(Number);
             Delay(150);
             Release(Number);
           end;
           CursorOn;
        end else begin
          Number:=Number+1;
          Konec:=(Number>MaxButtons);
        end;
     end;   { with }
   end;   { while }
Ukonceni:
end;

{ ***** }
procedure TimerOn; assembler;
{ nastartuje mereni casoveho intervalu
}
asm
   mov Ah,00h
   int 1ah
   mov GAMETIME,Dx
   mov POMTIME,Cx
   mov Ax,3
   add GAMETIME,Ax{}
@end:
end;

{ ***** }
function IsTimerWait:Boolean;
{ ceka do uplynuti intervalu
}
var Res:Boolean;
begin
   asm
      mov Ah,00h
      int 1ah
      cmp Cx,POMTIME
      ja @end
      cmp Dx,GAMETIME
      jb @NotOk
      mov Res,1
      jmp @end
@NotOk:
      mov Res,0
   @end:
   end;{}
   IsTimerWait:=Res;
end;

{ ***** }
function MousKeybClick2(var X,Y,Butt,Scan,Ascii:Word):Word;
{ V parametrech X,Y vraci souradnice stisku tlacitka mysi,
  v Butt kod stisknuteho tlacitka, a v Scan,Ascii kody klavesy.
  Sama funkce pak vraci cislo stisknuteho tlacitka nebo 0, byla-li
  mys stisknuta jinde nez na tlacitku nebo byla-li stisknuta klavesa.
  Pokud klavesa nebyla stisknuta, vraci se ve Scan cislo 0.
  Vraci-li 255, nic se nestalo
}
label Ukonceni;
var Number, Temp:Word;
    Konec:Boolean;
begin
   GetMouseClick(X,Y,Butt); Keyb(Scan,Ascii); TimerOn;
   while ((Butt = 0) and (Scan = 0) and (not IsTimerWait)) do begin
      GetMouseClick(X,Y,Butt); { cekani na stisk }
      Keyb(Scan,Ascii);
      Temp:=IsMouseInAnyButtonRegion;
      if ((Temp <> 255) and (Temp <> LastButton)) then begin
         if (LastButton <> 255) then RestoreButtonColor(LastButton);
         LastButton:=Temp; LightButtonColor(Temp);
      end else begin
         if (Temp = 255) then begin
           if (LastButton <> 255) then RestoreButtonColor(LastButton);
           LastButton:=255;
         end;
      end;
   end;
   if (IsTimerWait) then begin
     MousKeybClick2:=255;
     GoTo Ukonceni;
   end;
   MousKeybClick2:=0;
   if (Scan <> 0) then GoTo Ukonceni; { klavesa }

   Number:=1; Konec:=False;
   while not(Konec) do begin
     with (ButtonsInfo[Number]) do begin
        if (Exist) and (Active) and (X1<=X) and (X2>=X) and { tlacitko }
           (Y1<=Y) and (Y2>=Y) then begin                   { nalezeno }
           Konec:=True;
           MousKeybClick2:=Number;
           CursorOff;
           if (Down) then begin
             Release(Number);
             Delay(150);
             PushDown(Number);
           end else begin
             PushDown(Number);
             Delay(150);
             Release(Number);
           end;
           CursorOn;
        end else begin
          Number:=Number+1;
          Konec:=(Number>MaxButtons);
        end;
     end;   { with }
   end;   { while }
Ukonceni:
end;

{ ***** }
procedure TestButton(X,Y:Word; var Button:Byte);
{ V parametrech X, Y se predavaji souradnice stisku tlacitka mysi,
  v Button kod stisknuteho tlacitka (je-li).
}
label Ukonceni;
var Number:Word;
    Konec:Boolean;
begin
   Number:=1; Konec:=False; Button:=0;
   while (not Konec) do begin
     with (ButtonsInfo[Number]) do begin
        if ((Exist) and (Active) and (X1<=X) and (X2>=X) and { tlacitko }
           (Y1<=Y) and (Y2>=Y)) then begin                   { nalezeno }
           Konec:=True;
           Button:=Number;
        end else begin
          Inc(Number);
          Konec:=(Number > MaxButtons);
        end;
     end;   { with }
   end;   { while }
Ukonceni:
end;

{ ***** }
function ReadMouse(var Button:Byte):Boolean;
{ procedura nacte pozici mysi a vyhodnoti, ktere akce je nutne podniknout:
  vraci True, bylo-li stisknuto nejake tlacitko, potom v Button vraci jeho
  cislo
}
var Butt,X,Y:Word;
begin
   Button:=0;
   GetCursorPos(X,Y,Butt);
   if (Butt = 0) then GetMouseClick(X,Y,Butt);
   if (Butt <> 0) then TestButton(X,Y,Button);

   if (Button = 0) then ReadMouse:=False else ReadMouse:=True;
end;

{ ***** }
procedure ButtonEndPressed;
{ stisknuto tlacitko End
}
const XSize = 281; YSize = 101;
var X,Y:Word;
    Konec:Boolean;
    Num,Button,Scan,Ascii : Word;
begin
   X:=(XResolution-XSize) shr 1; Y:=(YResolution-YSize) shr 1;
   if (CreateButton(X+65,Y+65,1,0,False,_Ano) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');{}
   if (CreateButton(X+180,Y+65,1,0,False,_Ne) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');{}
   ButtonText(_ANO,15,'ANO'); ButtonText(_NE,15,'NE');
   ShowInfoPanel(X,Y,X + XSize,Y + YSize,1);
   Inc(X,2); Inc(Y,2);
   CursorOff;
   OutTextColor(X+10,Y+10,66,'    OPRAVDU CHCETE SKONbIT ?');
   SetActive(_ANO); SetActive(_NE);
   Release(_ANO); Release(_NE);
   CursorOn;

   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                        Konec:=True; Temp:=True;
                      end;
         _Ne        : begin
                        Konec:=True;
                      end;
      end;
   end;

   CursorOff;
   DeleteButton(_ANO,256); DeleteButton(_NE,256); CloseInfoPanel;
   CursorOff; if (Num = _Ano) then ClearScreen;
   CursorOn;
end;

{ ***** }
procedure ButtonManager;
{ obsluha mysi, tlacitek ...
}
var Button:Byte;
    Temp:Word;
begin
   if ((ResearchPressed = 1) and Active(ResearchButton)) then begin
      CursorOff; Release(ResearchButton); CursorOn; ResearchPressed:=0;
   end else if (ResearchPressed <> 0) then Dec(ResearchPressed);

   if ((DalsiTydenPressed = 1) and Active(DalsiTydenButton)) then begin
      CursorOff; Release(DalsiTydenButton); CursorOn; DalsiTydenPressed:=0;
   end else if (DalsiTydenPressed <> 0) then Dec(DalsiTydenPressed);

   if ((CorePressed = 1) and Active(CoreButton)) then begin
      CursorOff; Release(CoreButton); CursorOn; CorePressed:=0;
   end else if (CorePressed <> 0) then Dec(CorePressed);

   if ((InfoPressed = 1) and Active(InfoButton)) then begin
      CursorOff; Release(InfoButton); CursorOn; InfoPressed:=0;
   end else if (InfoPressed <> 0) then Dec(InfoPressed);

   if ((OptionPressed = 1) and Active(OptionButton)) then begin
      CursorOff; Release(OptionButton); CursorOn; OptionPressed:=0;
   end else if (OptionPressed <> 0) then Dec(OptionPressed);

   if ((SavePressed = 1) and Active(SaveButton)) then begin
      CursorOff; Release(SaveButton); CursorOn; SavePressed:=0;
   end else if (SavePressed <> 0) then Dec(SavePressed);

   if ((LoadPressed = 1) and Active(LoadButton)) then begin
      CursorOff; Release(LoadButton); CursorOn; LoadPressed:=0;
   end else if (LoadPressed <> 0) then Dec(LoadPressed);

   if ((EndPressed = 1) and Active(EndButton)) then begin
      CursorOff; Release(EndButton); CursorOn; EndPressed:=0;
   end else if (EndPressed <> 0) then Dec(EndPressed);

   if ((StartPressed = 1) and Active(StartButton)) then begin
      CursorOff; Release(StartButton); CursorOn; StartPressed:=0;
   end else if (StartPressed <> 0) then Dec(StartPressed);


   Temp:=IsMouseInAnyButtonRegion;
   if ((Temp <> 255) and (Temp <> LastButton)) then begin
      if (LastButton <> 255) then RestoreButtonColor(LastButton);
      LastButton:=Temp; LightButtonColor(Temp);
   end else begin
      if (Temp = 255) then begin
        if (LastButton <> 255) then RestoreButtonColor(LastButton);
        LastButton:=255;
      end;
   end;

   if (ReadMouse(Button)) then case (Button) of
      ResearchButton : begin
                         SoundPlay(0,0,0,0);
                         ResearchPressed:=GetAccurateDelay(2);
                         CursorOff; PushDown(ResearchButton);
                         SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                         SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                         SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                         SetPasive(LoadButton,256); SetPasive(EndButton,256);
                         SetPasive(StartButton,256); CursorOn;
                         ResearchPanel;
                         CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                         SetActive(CoreButton);  SetActive(InfoButton);
                         SetActive(OptionButton);SetActive(SaveButton);
                         SetActive(LoadButton);  SetActive(EndButton);
                         SetActive(StartButton); CursorOn;
                       end;
      DalsiTydenButton : begin
                         SoundPlay(0,0,0,0);
                         DalsiTydenPressed:=GetAccurateDelay(2);
                         CursorOff;PushDown(DalsiTydenButton);CursorOn;
                         Delay(170);
                         CursorOff;Release(DalsiTydenButton);
                         SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                         SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                         SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                         SetPasive(LoadButton,256); SetPasive(EndButton,256);
                         SetPasive(StartButton,256); CursorOn;
                         ResearchStep;
                         CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                         SetActive(CoreButton);  SetActive(InfoButton);
                         SetActive(OptionButton);SetActive(SaveButton);
                         SetActive(LoadButton);  SetActive(EndButton);
                         SetActive(StartButton); CursorOn;
                       end;
      CoreButton     : begin
                         if (OSNPlayer) then begin
                           SoundPlay(0,0,0,0);
                           CorePressed:=GetAccurateDelay(2);
                           CursorOff; PushDown(CoreButton);
                           SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                           SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                           SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                           SetPasive(LoadButton,256); SetPasive(EndButton,256);
                           SetPasive(StartButton,256); CursorOn;
                           CorePanel;
                           CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                           SetActive(CoreButton);  SetActive(InfoButton);
                           SetActive(OptionButton);SetActive(SaveButton);
                           SetActive(LoadButton);  SetActive(EndButton);
                           SetActive(StartButton); CursorOn;
                         end;
                       end;
      InfoButton     : begin
                         SoundPlay(0,0,0,0);
                         InfoPressed:=GetAccurateDelay(2);
                         CursorOff; PushDown(InfoButton);
                         SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                         SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                         SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                         SetPasive(LoadButton,256); SetPasive(EndButton,256);
                         SetPasive(StartButton,256); CursorOn;
                         CreateMenuInfo;
                         CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                         SetActive(CoreButton);  SetActive(InfoButton);
                         SetActive(OptionButton);SetActive(SaveButton);
                         SetActive(LoadButton);  SetActive(EndButton);
                         SetActive(StartButton); CursorOn;
                       end;
      OptionButton   : begin
                         SoundPlay(0,0,0,0);
                         OptionPressed:=GetAccurateDelay(2);
                         CursorOff; PushDown(OptionButton);
                         SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                         SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                         SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                         SetPasive(LoadButton,256); SetPasive(EndButton,256);
                         SetPasive(StartButton,256); CursorOn;
                         MenuOptions;
                         CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                         SetActive(CoreButton);  SetActive(InfoButton);
                         SetActive(OptionButton);SetActive(SaveButton);
                         SetActive(LoadButton);  SetActive(EndButton);
                         SetActive(StartButton); CursorOn;
                       end;
      SaveButton     : begin
                         SoundPlay(0,0,0,0);
                         SavePressed:=GetAccurateDelay(2);
                         CursorOff; PushDown(SaveButton);
                         SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                         SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                         SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                         SetPasive(LoadButton,256); SetPasive(EndButton,256);
                         SetPasive(StartButton,256); CursorOn;
                         if (SelectGameSlot(False))
                         then GLB_save(SaveSlotId);
                         CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                         SetActive(CoreButton);  SetActive(InfoButton);
                         SetActive(OptionButton);SetActive(SaveButton);
                         SetActive(LoadButton);  SetActive(EndButton);
                         SetActive(StartButton); CursorOn;
                       end;
      LoadButton     : begin
                         SoundPlay(0,0,0,0);
                         LoadPressed:=GetAccurateDelay(2);
                         CursorOff; PushDown(LoadButton); CursorOn;
                         if (SelectGameSlot(True)) then begin
                             GLB_load(SaveSlotId);
                             if (DResult <> 0) then DialogBox('CHYBA PRI NAHRAVANI HRY!',_YES)
                             else begin
                               InitGlobalModif;
                               SetGrModeVariables(False,False);
                               LoadMissionData;
                               DrawPoints; { /// }
                               DrawVictoryPoints; { /// }
                               if (GlobalSelectedResearch > 0) then begin
                                 Draw_active_research(GlobalSelectedResearch,
                                                      Research^[GlobalSelectedResearch].PercState,
                                                      True);
                               end;
                               SaveGameCfg;
                             end;
                         end;
                       end;
      EndButton      : begin
                         SoundPlay(0,0,0,0);
                         EndPressed:=GetAccurateDelay(2);
                         CursorOff; PushDown(EndButton);
                         SetPasive(ResearchButton,256);SetPasive(DalsiTydenButton,256);
                         SetPasive(CoreButton,256);SetPasive(InfoButton,256);
                         SetPasive(OptionButton,256); SetPasive(SaveButton,256);
                         SetPasive(LoadButton,256); SetPasive(EndButton,256);
                         SetPasive(StartButton,256); CursorOn;
                         ButtonEndPressed;
                         CursorOff; SetActive(ResearchButton); SetActive(DalsiTydenButton);
                         SetActive(CoreButton);  SetActive(InfoButton);
                         SetActive(OptionButton);SetActive(SaveButton);
                         SetActive(LoadButton);  SetActive(EndButton);
                         SetActive(StartButton); CursorOn;
                       end;
      StartButton    : begin
                         SoundPlay(0,0,0,0);
                         if ((MaxMissionCoreUnits > 0) and
                             (CoreSelectedCount < MaxMissionCoreUnits) and
                             (DialogBox('NEMaTE VYBRaNY VgECHNY JEDNOTKY JaDRA PRO MISI. CHCETE POKRAbOVAT?',
                                       _YES_NO) = NO))
                         then else begin
                           StartPressed:=GetAccurateDelay(2);
                           SaveGlobalModif;
                           GLB_save('global.sim');
                           SaveMain;
                           EndOfGame:=True;
                           CursorOff; PushDown(StartButton); CursorOn;
                         end;
                       end;
   end;
end;

{***** }
procedure Buttons_save;
{ pro potreby ulozeni hry
}
label K;

begin
 {  Assign(IOFile,'save\11'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
    BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
    DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
K:
  Close(IOFile); DResult:=IOResult;{}
end;

{ ***** }
procedure Buttons_load;
{ pro potreby ulozeni hry
}
label K;

begin
  {Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  {if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\11'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

  LeftButton:=0; MiddleButton:=0; RightButton:=0;
  LastName:=''; LastRace:=255;
  LastX:=0; LastY:=0; LastButton:=0;
  MouseEqualCount:=0;
  ChangeCursorLevel:=False;
  CursorChanged:=False;
  Price_drew:=False;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;{}
end;

{ ************************************************************************** }
begin
   { Postup pri inicializaci:
     -LoadButtonFile
     -ButtonsColors
     -InitMouse

     Postup pri vytvareni tlacitka:
     -CreateButton
     -ButtonText
     -Release
     -SetActive

     Ruseni tlacitka:
     -DeleteButton

     Cekani na stisk tlacitka:
     -MouseClick nebo MousKeybClick
   }
   ResearchPressed:=0; CorePressed:=0; InfoPressed:=0; OptionPressed:=0;
   SavePressed:=0; LoadPressed:=0; EndPressed:=0; StartPressed:=0;

   On1Seg:=0; On2Seg:=0; Off1Seg:=0; Off2Seg:=0;
   for I:=1 to MaxButtons do begin
      ButtonsInfo[I].Exist:=False;
      ButtonsInfo[I].Segment:=0;
      ButtonsInfo[I].ButtonText:='';
   end;
end.