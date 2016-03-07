{ tato jednotka provadi testovani kurzoru mysi a z toho vyplyvajici akce
}
unit Buttons;
{$C FIXED PRELOAD PERMANENT}
interface
uses Crt, Graph257, Data, Mouse;

const MaxButtons = 23;
      NotEnoughMemory = 256;
      XORColor = 31;
      ADRng1 = 4;
      ADRng2 = 8;
      ADRng3 = 16;
      ADRng4 = 200;

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
function MousKeybClick(var X,Y,Butt,Scan,Ascii:Word):Word;
function MousKeybClick2(var X,Y,Butt,Scan,Ascii:Word):Word;
procedure Mouse_keyboard_manager;
procedure Buttons_save;
procedure Buttons_load;

implementation

uses Grafika, Grafika2, Grafika3, _units, _units2, _units3, _buildings,
     SBSound, Buttons2, Dos, _races;
var On1Seg,On1Offs, Off1Seg,Off1Offs, On2Seg,On2Offs, Off2Seg,Off2Offs: Word;
    Type3Pictures: array[1..MaxButtons] of record
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
      MousKeybTest:Boolean;
      LastScroll:Boolean; { True, bylo-li v minulem slotu rolovano }
      LastX, LastY : Word; { souradnice mysi v minulem casovem slotu }
      LastButton : Byte; { kod minuleho stisku mysi }
      MouseEqualCount : Byte; { souvisi s predchozim a udava pocet shod
      aktualni a minule pozice mysi za sebou (tyka se i Button) }
      ChangeCursorLevel : Boolean; { byla-li drzenim mysi na miste zmenena
      uroven kurzoru, nastavi se na True }
      CursorChanged : Boolean; { stejne jako predchozi }
      Price_drew : Boolean; { obdelnik s cenami je vykreslen }
      Dont_erase_price : Boolean; { obdelnik s cenami se nyni nesmi smazat }
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
{   if (On1Seg <> 0) then DisposeImage(On1Seg, On1Offs);
   if (Off1Seg <> 0) then DisposeImage(Off1Seg, Off1Offs);
   if (On2Seg <> 0) then DisposeImage(On2Seg, On2Offs);
   if (Off2Seg <> 0) then DisposeImage(Off2Seg, Off2Offs);{}
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
   if (ButtonsInfo[Number].Exist) then GoTo Konec; { exist check }

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
      {PutMemory(Button3Size,ButtonsInfo[Number].Segment,ButtonsInfo[Number].Offsets);{}
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
var Mouse:Boolean;
begin
   if (Number < MaxButtons) and (Number > 0) then
   with (ButtonsInfo[Number]) do begin { range check }
      if (TestMouse(X1,Y1,X2,Y2)) then Mouse:=True;
      Active:=True;
      SetColor(Color1);
      if (ButtonType < 2) then begin
        {if (Mouse) then CursorOff;{}
        OutText(XText,YText,ButtonText);
        {if (Mouse) then CursorOn; {}
      end else begin { typ2 }
        {if (Mouse) then CursorOff;{}
        SpeedPutImage2(X1,Y1,Type3Pictures[Index].OnSeg,
                            Type3Pictures[Index].OnOffs);
        {if (Mouse) then CursorOn;{}
      end;
   end;
end;

{ ***** }
procedure SetPasive(Number:Word; Color:Word);
{ tlacitko Number bude pasivni ("usne"); je-li Color < 256, pak se
  tlacitko prekresli barvou Color, jinak se neprekresli
}
var XX1, XX2, YY1, YY2 : Word;
    Mouse:Boolean;
begin
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
end;

{ ***** }
procedure Release(Number:Word);
{  zobrazi tlacitko Number jako "uvolnene" (nestisknute)
}
label Konec;
var Color:Byte;
begin
   if (Number < MaxButtons) and (Number > 0) then begin; { range check }
     with (ButtonsInfo[Number]) do begin
        if (not(Exist)) then GoTo Konec;
        ButtonClick:=0; Button:=0;
        if (Buttontype = 0) then begin
           SpeedPutImage2(X1,Y1,On1Seg,On1Offs);
           SetColor(Color1); {}
           OutText(XText,YText,ButtonText);
        end else
          if (Buttontype = 1) then begin
             SpeedPutImage2(X1,Y1,On2Seg,On2Offs);
             SetColor(Color1); {}
             OutText(XText,YText,ButtonText);
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
        PreparePlaySound(6,0,0,0); { zvuk clicknuti }
        ButtonClick:=0; Button:=0;
        if (ButtonType = 0) then begin
           SpeedPutImage2(X1,Y1,Off1Seg,Off1Offs);
           SetColor(Color1);
           OutText(XText+PushMovement,YText+PushMovement,ButtonText);
        end else
           if (Buttontype = 1) then begin
             SpeedPutImage2(X1,Y1,Off2Seg,Off2Offs);
             SetColor(Color1);
             OutText(XText+PushMovement,YText+PushMovement,ButtonText);
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
procedure Keyb(var Scan,Ascii:Word); { !!!! NEBUDE V INTERFACE !!!! }
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

{ ***** }
function MousKeybClick(var X,Y,Butt,Scan,Ascii:Word):Word;
{ V parametrech X,Y vraci souradnice stisku tlacitka mysi,
  v Butt kod stisknuteho tlacitka, a v Scan,Ascii kody klavesy.
  Sama funkce pak vraci cislo stisknuteho tlacitka nebo 0, byla-li
  mys stisknuta jinde nez na tlacitku nebo byla-li stisknuta klavesa.
  Pokud klavesa nebyla stisknuta, vraci se ve Scan cislo 0.
}
label Ukonceni;
var Number:Word;
    Konec:Boolean;
begin
   GetMouseClick(X,Y,Butt); Keyb(Scan,Ascii);
   while (Butt = 0) and (Scan = 0) do begin
      GetMouseClick(X,Y,Butt); { cekani na stisk }
      Keyb(Scan,Ascii);
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
  v Button kod stisknuteho tlacitka.
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
function Pomocna(X,Y:Word; var Scroll:Byte):Boolean;
{ pomocna procedura pro ReadMouse a Mouse_keyboard_manager;
  urcuje dle souradnic X,Y smer rolovani obrazovky (1-128 po mocninach 2)
}
var XPom, YPom : Integer;
    Slash : Boolean;
begin
   if (not Scrolling) then begin
     XScroll:=X; YScroll:=Y;
   end;
   Scrolling:=True;
   XPom:=Integer(XScroll) - X; YPom:=Integer(YScroll) - Y; Pomocna:=True;

   { dle pozice odchylky od stredu urci, zda pujde o jeden ze zakladnich
     smeru nebo smer sikmy }
   if ((YPom = 0) or (abs(XPom) div abs(YPom) >= 2) or
       (XPom = 0) or (abs(YPom) div abs(XPom) >= 2)) then Slash:=False
   else Slash:=True;

   if ((XPom <> 0) or (YPom <> 0)) then
     if (XPom > 0) then
       if (YPom < 0) then
         if (Slash) then Scroll:=64
         else
           if (abs(XPom) < abs(YPom)) then Scroll:=32 else Scroll:=128
       else
         if (Slash) then Scroll:=1
         else
           if (abs(XPom) < abs(YPom)) then Scroll:=2 else Scroll:=128
     else
       if (YPom < 0) then
         if (Slash) then Scroll:=16
         else
           if (abs(XPom) < abs(YPom)) then Scroll:=32 else Scroll:=8
       else
         if (Slash) then Scroll:=4
         else
           if (abs(XPom) < abs(YPom)) then Scroll:=2 else Scroll:=8
   else Pomocna:=False;

   {XScroll:=X; YScroll:=Y;{}
end;

{ ***** }
function Pomocna2(X,Y:Word; var Scroll:Byte):Boolean;
{ pomocna procedura pro ReadMouse a Mouse_keyboard_manager;
  urcuje dle souradnic X,Y smer rolovani obrazovky (1-128 po mocninach 2)
}
var XPom, YPom : Integer;
    Slash : Boolean;
begin
  if (not War2Scroll) then Pomocna2:=False
  else begin
     Pomocna2:=True;
     if (X <= 5) then begin
       if (Y < YResolution div 6) then Scroll:=1
       else
         if (Y > YResolution-YResolution div 6) then Scroll:=64
         else Scroll:=128;
     end else
      if (Y <= 5) then begin
         if (X < XResolution div 6) then Scroll:=1
         else
           if (X > XResolution-XResolution div 6) then Scroll:=4
           else Scroll:=2;
      end else
       if (X >= (XResolution-6)) then begin
          if (Y < YResolution div 6) then Scroll:=4
          else
           if (Y > YResolution-YResolution div 6) then Scroll:=16
           else Scroll:=8;
       end else
        if (Y >= (YResolution-6)) then begin
          if (X < XResolution div 6) then Scroll:=64
          else
           if (X > XResolution-XResolution div 6) then Scroll:=16
           else Scroll:=32;
        end else Pomocna2:=False;
  end;
end;

{ ***** }
procedure SetGroup(GroupNo : Byte);
{ ulozi aktivni skupinu do skupiny na pozici GroupNo
}
begin
   if (ActiveGroup < 254) then begin
      Groups[GroupNo]:=Groups[ActiveGroup];
   end;
end;

{ ***** }
procedure GetGroup(GroupNo : Byte; Center:Boolean);
{ jako aktivni nastavi skupinu ze skupiny na pozici GroupNo
  je-li Center = True, pak take vycentruje obtazovku
}
var I,J,K, L,ADefRange,IPom,JPom: Word;
    Enemy, Build, WithoutMovement, Load, Unit_building : Boolean;
    _unit:PUnit;
    PomUnit:PUnit;
begin
   if (Price_bck_rectangle_is_active) then begin
      Erase_price_bck_rectangle;
      Invalidate_price_bck_rectangle;
   end;
   Clear_group_slots; I:=65535; J:=65535;
   { nejprve se zrusi aktivita aktivni skupiny (je-li nejaka) }
   if (ActiveGroup < 254) then Deselect_group(ActiveGroup);
   for K:=0 to MaxGroupUnits-1 do with (Groups[MaxGroups]) do
     if (Un[K] <> NIL) then begin
        Un[K]^.Group:=254;
        Un[K]:=NIL;
     end;
   if (Groups[MaxGroups].Building <> Nil) then
      Groups[MaxGroups].Building^.Group:=254;
   Groups[MaxGroups].Building:=Nil; Enemy:=False; Build:=False;
   WithoutMovement:=False; Load:=False; Unit_building:=False;

   Groups[MaxGroups]:=Groups[GroupNo]; L:=0;
   with (Groups[MaxGroups]) do begin
     {Count:=0;{}
     if (Building = Nil) then begin
        for K:=0 to MaxGroupUnits-1 do begin
          if ((Un[K] <> Nil) and (Un[K]^.Activity) and (Un[K]^.Visibility))
          then with (Un[K]^) do begin
             Group:=MaxGroups;
             if (L = 0) then begin
                ADefRange:=ActiveDefenceRange;
                I:=IPos; J:=JPos;
                PomUnit:=Un[K];
             end;
             if (ADefRange <> ActiveDefenceRange) then ADefRange:=65535;
             GroupOrder:=K{L}; Inc(L);
             if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) then
                WithoutMovement:=True;
             if (UnitsInsideNum <> 0) then Load:=True;
             if (UnitType = 33) then Unit_building:=True;
             if (MyRace <> Race) then begin
                _unit:=Un[K];
                Enemy:=True;
             end;
             { ve skupine je nepratelska nebo neutralni jednotka }
          end else
            if ((Un[K] <> Nil) and ((not Un[K]^.Activity) or
                                    (not Un[K]^.Visibility))) then begin
               Un[K]:=Nil;
               Dec(Count);
            end;
        end;
     end else begin
        Building^.Group:=MaxGroups;
        Build:=True; { vymaz vsechna tlacitka }
        if (MyRace <> Building^.Race) then begin
           Enemy:=True;
        end;
        I:=Building^.IPos; J:=Building^.JPos;
     end;

     if ((not Active(Stop)) and (Count > 0) and (not Enemy)) then SetActive(Stop);
     if (Active(Stop) and ((Count = 0) or Enemy)) then SetPasive(Stop,256);
     if ((not Active(Patrol)) and (Count > 0) and (not Enemy) and (not Build))
     then SetActive(Patrol);
     if (Active(Patrol) and ((Count = 0) or Enemy or Build
         or (Count = 1) and WithoutMovement)) then SetPasive(Patrol,256);
     if ((GroupLevel = 0) and (Count > 0) and
         (not Active(Nalozit)) and (not Enemy)) then SetActive(Nalozit);
     if (Active(Nalozit) and ((GroupLevel = 1) or (Count = 0) or Enemy or
         Build or (Count = 1) and WithoutMovement)) then SetPasive(Nalozit,256);
     if ((not Active(Vylozit)) and (Count = 1) and Load and (not Enemy)) then begin
        if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
        SetActive(Vylozit);
     end else begin
       if (Active(Vylozit) and ((Count <> 1) or not Load)) then
          SetPasive(Vylozit,256);
       if (Active(Rozlozit) and ((Count <> 1) or (not Unit_building)))
       then SetPasive(Rozlozit,256)
       else
         if (not Active(Rozlozit) and (Count = 1) and Unit_building and (not Enemy))
         then SetActive(Rozlozit);
     end;
     if ((not Active(Opravit)) and (Count > 0) and (not Enemy)) then SetActive(Opravit);
     if (Active(Opravit) and ((Count = 0) or Enemy)) then SetPasive(Opravit,256);
     if ((not Active(ZvednoutMoralku)) and (Count > 0) and (MyRaceType <> 3) and
         (MyRaceType <> 6) and (not Enemy))
     then SetActive(ZvednoutMoralku);
     if (Active(ZvednoutMoralku) and ((Count = 0) or Enemy or Build)) then SetPasive(ZvednoutMoralku,256);
     ADefRng:=ADefRange;
     case (ADefRange) of
       ADRng1  : ADefRange:=0;
       ADRng2  : ADefRange:=1;
       ADRng3  : ADefRange:=2;
       ADRng4  : ADefRange:=3;
       65535   : ADefRange:=4;
     end;
     if ((not Build) and (not Enemy) and (Count > 0)) then begin
        SetActiveDefenceRangeSlotsActivity(ADefRange);
     end else ClearActiveDefenceRangeSlots;

     if ((Center) and (Count > 0) and (I < 65535) and (J < 65535)) then begin
       if ((I >= IScreenSizeShr2) and (J >= JScreenSizeShr2)) then begin
       { kontrola leveho horniho rohu }
         I:=I-IScreenSizeShr2; J:=J-JScreenSizeShr2;
       end else begin
         if (I < IScreenSizeShr2) then I:=0
         else I:=I-IScreenSizeShr2;
         if (J < JScreenSizeShr2) then J:=0
         else J:=J-JScreenSizeShr2;
       end;
       { nyni kontroly konce obrazovky }
       if ((I+IScreenSize) > IMax) then begin
          I:=IMax - IScreenSize + 1;
       end;
       if ((J+JScreenSize) > JMax) then begin
          J:=JMax - JScreenSize + 1;
       end;
       if (J mod 2 = 1) then Dec(J);
       if (I mod 2 = 1) then Dec(I);
       { nyni se obrazovka precvakne }
       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
       IPom:=IBeg; JPom:=JBeg;
       JBeg:=J; IBeg:=I;
       Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
       CursorOff;
       Draw_screen(IBeg,JBeg,0,0);
       RedrawRadarFrame(IPom,JPom);
       CursorOn;
     end;

     if (Count > 0) then Select_group(MaxGroups);
     if ((not Enemy) and (Count > 0)) then begin
        Click_on_group(ActiveGroup);
        if ((Count = 1) and (not Build) and (PomUnit^.UnitsInsideNum > 0))
        then begin
           Click_on_storage_unit(PomUnit);
        end;
        if (Count <> 0) then begin
          {if (NetType = 1) then begin { seriovy kabel }
          {   IPX_SendByte(0); IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
             IPX_SendByte(Count);
             SerialCheckSum:=0+Count;
             for K:=0 to MaxGroupUnits-1 do
                if (Un[K] <> NIL) then begin
                   IPX_SendWord(Un[K]^.Index);
                   SerialCheckSum:=SerialCheckSum+Un[K]^.Index;
                end;
             IPX_SendWord(SerialCheckSum);
             SerialCheckSum:=0;
          end; {}
        end;
     end else if (Count > 0) then begin
        if (Count <= 1)  then begin
           if (not Build) then Click_on_enemy_unit(_unit)
           else Click_on_group(ActiveGroup);
        end else Error(0,'Chyba v jednotce Buttons, procedura GetGroup');
     end;
   end;
end;

procedure Center_active_group;
{
}
var I,J,K,L,IPom,JPom :Word;
begin
 if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
   L:=0; I:=65535; J:=65535;
   if (Building = Nil) then begin
      for K:=0 to MaxGroupUnits-1 do begin
        if ((Un[K] <> Nil) and (Un[K]^.Activity) and (Un[K]^.Visibility))
        then with (Un[K]^) do begin
           if (L = 0) then begin
              I:=IPos; J:=JPos;
           end; Inc(L);
        end else
      end;
   end else begin
      I:=Building^.IPos; J:=Building^.JPos;
   end;

   if ((Count > 0) and (I < 65535) and (J < 65535)) then begin
       if ((I >= IScreenSizeShr2) and (J >= JScreenSizeShr2)) then begin
       { kontrola leveho horniho rohu }
         I:=I-IScreenSizeShr2; J:=J-JScreenSizeShr2;
       end else begin
         if (I < IScreenSizeShr2) then I:=0
         else I:=I-IScreenSizeShr2;
         if (J < JScreenSizeShr2) then J:=0
         else J:=J-JScreenSizeShr2;
       end;
       { nyni kontroly konce obrazovky }
       if ((I+IScreenSize) > IMax) then begin
          I:=IMax - IScreenSize + 1;
       end;
       if ((J+JScreenSize) > JMax) then begin
          J:=JMax - JScreenSize + 1;
       end;
       if (J mod 2 = 1) then Dec(J);
       if (I mod 2 = 1) then Dec(I);
       { nyni se obrazovka precvakne }
       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
       IPom:=IBeg; JPom:=JBeg;
       JBeg:=J; IBeg:=I;
       Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
       CursorOff;
       Draw_screen(IBeg,JBeg,0,0);
       RedrawRadarFrame(IPom,JPom);
       CursorOn;
     end;
 end;
end;

{ ***** }
function TestSlots(XX,YY:Word; var Slots:Byte):Boolean;
{ testuje, zda se pozice X,Y nanachazi uvnitr nejakeho slotu
  (0=1.slot)
}
var Konec : Boolean;
    K : Integer;
begin
   K:=0; Konec:=False;
   while (K < MaxGroupUnits) and (not Konec) do
   with (GroupsBck[K]) do begin
      if ((Active) and ((X) <= XX) and ((X+XPictureSize) >= XX) and
          ((Y) <= YY) and ((Y+YPictureSize) >= YY)) then begin
         Slots:=K; Konec:=True;
      end;
      Inc(K);
   end;
   TestSlots:=Konec;
end;

{ ***** }
function ReadMouse(var I,J,X,Y,Butt:Word; var Buttn:Byte; var Scroll:Byte;
                   var ADefSlots,Slots:Byte; var Radar:Boolean;
                   var Validity:Boolean):Boolean;
{ procedura nacte pozici mysi a vyhodnoti, ktere akce je nutne podniknout:
  - bud bylo clicknuto na Radar, pak vraci Radar = True a v I,J novy stred
    obrazovky
  - nebo byl pravym tlacitkem navolen nektery aktivni "slotovy" obrazek =>
    => pak se v promenne Slots vraci jeho cislo (1..MaxGroupUnits)
    ( pri neuspechu se ve Slots atypicky vraci hodnota 255)
  - nebo bylo clicknuto na slot se vzdalenosti aktivni obrany; pak se
    v ADefSlots vraci dane cislo
  - nebo prave tlacitko mysi chce rolovat obrazovku nebo
  - bylo stisknuto graficke tlacitko (Buttn) na obrazovce a vraci se jeho cislo
    nebo
  - bylo stisknuto leve,stredni tlacitko kdekoli na herni mape a pak se vraci
    pozice stisku a typ tlacitka (Butt)
  - Validity vraci True, jsou-li hodnoty, vracene funkci OK
  pozn. Je-li iniciovano rolovani s pomoci klavesnice, vraci se v Button
  1, jinak pri rolovani mysi se vraci 0
}
label Skip;
var Pom, PomButt,K,II: Word;
    XP,YP,XVal,YVal:Word;
    Pomocn:LongInt;
    Ascii:Byte;
    ChangeLevelWait0, ChangeLevelWait1:Byte;
    Bool, PomBool:Boolean;
begin
   bebex:=1000;
   Buttn:=0; Butt:=0; Scroll:=0; ReadMouse:=True; Radar:=False;
   Slots:=255; ADefSlots:=255;
   GetCursorPos(X,Y,Butt);
   if (Butt = 0) then{} GetMouseClick(X,Y,Butt);
   if (Butt and 2 = 2) then begin
     Pom:=Butt; GetCursorPos(X,Y,Butt);
     if (Butt and 2 = 2) then begin
        ButtonClick:=2;
        if (not War2Scroll) then Butt:=8;{}
     end else{} Butt:=Pom;
   end;{}
   PomButt:=Butt;
   if (Butt = 0) then begin
      GetCursorPos(X,Y,Butt);
      if ((Butt and 2 = 2) and (not War2Scroll)) then Butt:=8;{}
      if ((Butt and 1 = 1) and (ClickLevelBase = 0)) then begin
         Butt:=0; PomButt:=1;
      end else PomButt:=Butt;
   end;{}

   GetSpecKeysState; Ascii:=ReadKeys(PressedKey);
   if (ActuallCursor = GoInsideCursor) then begin
   { u techto kurzoru se pocita ne s levym hornim rohem, ale s prostredkem }
       X:=X{ + XCursorSize div 2{};
       Y:=Y{ + YCursorSize div 2{};
   end;

   bebex:=1001;
   if (LeftButton <> 0) then begin
      Dec(LeftButton);
      Butt:=Butt and 254;
   end;
   if (MiddleButton <> 0) then begin
      Dec(MiddleButton);
      Butt:=Butt and 251;
   end;
   if (RightButton <> 0) then begin
      Dec(RightButton);
      Butt:=Butt and 253;
   end;

   {if (PomButt <> LastButton) then MouseEqualCount:=0;{}

   bebex:=1002;
   if ((X >= XScreenBeg) and (Y >= YScreenBeg) and
       (X <= XScreenEnd) and (Y <= YScreenEnd)) then begin
      I:=(X-XScreenBeg) div XCellSize + IBeg;
      J:=(Y-YScreenBeg) div YCellSize + JBeg;
      if ((LastButton and 1 <> 0) and (PomButt and 1 <> 0) and
          (LastX <> X) and (LastY <> Y) or
          (LastButton and 16 <> 0) and (PomButt and 17 <> 0))
      then begin
         Butt:=16; { group selecting }
         PomButt:=16;
         X:=LastX; Y:=LastY;
      end;
   end;

   bebex:=1003;
   { osetri zmenu levelu po stisku ctrl }
   if (CtrlChangeLevel) then begin
     if ((ClickLevel = 0) and (Ctrl)) then begin
     { zmena z pozemni urovne na vzdusnou }
        ChangeCursorLevel:=False;
        CursorChanged:=True;
        {GoTo Skip;{}
     end else
       if ((ClickLevel = 1) and (not Ctrl)) then begin
       { zmena ze vzdusne urovne na pozemni }
          CursorChanged:=True;
          ChangeCursorLevel:=False;
          MouseEqualCount := 0;
       end else begin
       { zadna zmena }
          CursorChanged:=False;
          ChangeCursorLevel:=True;
       end;
   end;

   bebex:=1004;
   if (X >= 6) then XVal:=6 else XVal:=X;
   if (Y >= 6) then YVal:=6 else YVal:=Y;
   if ((LastX > (X-XVal)) and (LastX < (X+XVal)) and
       (LastY > (Y-YVal)) and (LastY < (Y+YVal)) and
       (LastButton = PomButt) and (PomButt <> 0) and
       ((ActuallCursor = NormalCursor) or
        (ActuallCursor = GroupingCursor)) and
       not LastScroll) then begin
     Scrolling:=False;
     Inc(MouseEqualCount);
     if ((ClickLevelBase = 0) and (ActuallCursor = GroupingCursor)) then begin
     { grupovani pozemnich jednotek - zvys interval }
       case (Delay1) of
          5 : begin ChangeLevelWait0:=1; ChangeLevelWait1:=1; end;
          4 : begin ChangeLevelWait0:=1; ChangeLevelWait1:=2; end;
          3 : begin ChangeLevelWait0:=1; ChangeLevelWait1:=3; end;
          2 : begin ChangeLevelWait0:=2; ChangeLevelWait1:=5; end;
          1 : begin ChangeLevelWait0:=4; ChangeLevelWait1:=8; end;
       else
         ChangeLevelWait0:=1; ChangeLevelWait1:=3;
       end;
     end else begin
       case (Delay1) of
          5 : begin ChangeLevelWait0:=1; ChangeLevelWait1:=1; end;
          4 : begin ChangeLevelWait0:=1; ChangeLevelWait1:=2; end;
          3 : begin ChangeLevelWait0:=1; ChangeLevelWait1:=3; end;
          2 : begin ChangeLevelWait0:=2; ChangeLevelWait1:=5; end;
          1 : begin ChangeLevelWait0:=4; ChangeLevelWait1:=8; end;
       else
         ChangeLevelWait0:=1; ChangeLevelWait1:=3;
       end;
     end;
Skip:
   end else begin
      if ((not ChangeCursorLevel) and (MouseEqualCount = 0) and
          CursorChanged) then begin
      { vrat uroven zpet }
         if (ClickLevelBase = 0) then begin
             if (ClickLevel = 0) then begin
               ClickLevel:=1;
               SetCursor(ActuallCursor);
             end;
             ClickLevelBase:=1;
         end else begin
             if (ClickLevel = 1) then begin
               ClickLevel:=0;
               SetCursor(ActuallCursor);
             end;
             ClickLevelBase:=0;
         end;
      end;
      MouseEqualCount:=0;
      if ((ChangeCursorLevel) and (PomButt <> LastButton) and
          ((PomButt <> 1) or (LastButton <> 16)) and
          ((PomButt <> 16) or (LastButton <> 1))) then
          ChangeCursorLevel:=False;
   end;

   bebex:=1005;
   if (Butt and 8 = 8) then begin { stisknuto prave tlacitko - scroll }
      PomBool:=Pomocna(X,Y,Scroll);
      ReadMouse:=PomBool;
      {if (not PomBool) then Butt:=2;{}
   end;
   if ((Butt <> 0) and (Butt <> 8)) then begin
   { doslo ke stisku tlacitka mysi; otestuje se, kde k tomu doslo a ktere
     akce je nutne podniknout }
     if (Butt and 16 = 16) then begin { grouping }
        ReadMouse:=True; Scrolling:=False;
     end else
        if ((Butt and 1 = 1) or (Butt and 4 = 4) or (Butt and 2 = 2){ or
            ((LastButton and 1 = 1) and (Butt and 1 = 0)){}) then begin
        { stisknuto leve nebo prostredni tlacitko }
           if ((X >= XScreenBeg) and (Y >= YScreenBeg) and
               (X <= XScreenEnd) and (Y <= YScreenEnd){ and
               (Butt <> 1){}) then begin
           { tlacitko bylo zmacknuto na mape }
              Scrolling:=False;
              Buttn:=0; if (Butt = 0) then Butt:=1;
           end else begin
           { zkus zjistit, zda bylo clicknuto na obrazovkove tlacitko }
              TestButton(X,Y,Buttn);
              if (Buttn = 0) then
                if ((X >= XRadarRealBeg) and (Y >= YRadarRealBeg) and
                    (X <= XRadarRealEnd) and (Y <= YRadarRealEnd)) then begin
                { testovani radaru }
                   if (Butt and 1 = 1) then begin
                   { leve tlacitko }
                      I:=X-XRadarRealBeg;
                      J:=Y-YRadarRealBeg;
                      Radar:=True;
                   end else begin
                   { jine nez leve tlacitko - realizuj presun }
                      I:=X-XRadarRealBeg;
                      J:=Y-YRadarRealBeg;
                      Scrolling:=False;
                      Buttn:=0;
                   end;
                end else begin
                  if (((Butt and 1 = 1) or (Butt and 2 = 2)) and
                      TestSlots(X,Y,Slots)) then
                  { testovani slotu }
                  else begin
                    Slots:=255;
                    ADefSlots:=TestActiveDefenceRangeSlots(X,Y);
                    if ((Butt and 1 = 1) and (ADefSlots <> 255)) then
                    { testovani slotu }
                    else begin
                       ReadMouse:=False;
                       ADefSlots:=255;
                    end;
                  end;
                end;
              Scrolling:=False;
           end;
        end else begin
           ReadMouse:=False;
           Scrolling:=False;
        end;
   end else begin
     if (Butt <> 8) then begin
       if (not Pomocna2(X,Y,Scroll)) then begin
         ReadMouse:=False;
         Scrolling:=False;
       end else ReadMouse:=True;
     end;
   end;
   if ((PressedKey = $48) or (PressedKey = $50) or (PressedKey = $4d) or
       (PressedKey = $4b) or (PressedKey = $47) or (PressedKey = $49) or
       (PressedKey = $51) or (PressedKey = $4f)) then begin
      ReadMouse:=True;
      case (PressedKey) of
         $47 : Scroll:=1; { Home }
         $48 : Scroll:=2; { Nahoru }
         $49 : Scroll:=4; { PgUp }
         $4d : Scroll:=8; { Vpravo }
         $51 : Scroll:=16; { PgDn }
         $50 : Scroll:=32; { Dolu }
         $4f : Scroll:=64; { End }
         $4b : Scroll:=128; { Vlevo }
      end;
      Buttn:=1;
   end;

   bebex:=1006;
   if ((TempWayPointMax = MaxWayPoint) and (WayPointDef <> 0))
   then PressedKey:=$1c; { prekrocen limit waypointu - ukonci editaci }

   LastX:=X; LastY:=Y; LastButton:=PomButt;
   if (LastScroll) then begin
      LastScroll:=False;
      if (GameTimming = 0) then RightButton:=1 else RightButton:=2;
   end;

   { otestovani klaves }
   case (PressedKey) of
      $4e : Slow:=False;
      $4a : Slow:=True;
      $1f : begin  { S }
              if (Active(Stop)) then begin
                 Buttn:=Stop;
                 ReadMouse:=True;
              end;
            end;
      $31 : begin  { N }
              if (Active(Nalozit)) then begin
                 Buttn:=Nalozit;
                 ReadMouse:=True;
              end;
            end;
      $2f : begin  { V }
              if (Active(Vylozit)) then begin
                 Buttn:=Vylozit;
                 ReadMouse:=True;
              end;
            end;
      $13  : begin { R }
                if (Active(Rozlozit)) then begin
                   Buttn:=Rozlozit;
                   ReadMouse:=True;
                end;
             end;
      $18  : begin { O }
                if (Active(Opravit)) then begin
                   Buttn:=Opravit;
                   ReadMouse:=True;
                end;
             end;
      $32  : begin { M }
                if (Active(ZvednoutMoralku)) then begin
                   Buttn:=ZvednoutMoralku;
                   ReadMouse:=True;
                end;
             end;
      $1E : if (Active(Patrol)) then begin { A }
                 Buttn:=Patrol;
                 ReadMouse:=True;
            end;
      $02..$0b : if (WayPointDef = 0) then begin
      { 1,2..,0 - vyber skupinu; +shift = vycentruj }
                    if ((Ascii >= $3a) or (Ascii <= $2f)) then
                      SetGroup(PressedKey-$02)
                    else GetGroup(PressedKey-$02,False);
                 end;

      { $78..$81 : if (WayPointDef = 0) then begin
      { alt + 1,2,..,0 = uloz skupinu }
      {              SetGroup(PressedKey-$78);
                  end;{}

      $3f..$42 : begin { F5-F8 = nastav ulozeny waypoint }
                   if (SavedWayPointsMax[PressedKey-$3f] <> 255) then begin
                   { neco je ulozene }
                     if ((ActiveGroup < 255) and (Groups[ActiveGroup].ClickStatus < 254))
                     then with (Groups[ActiveGroup]) do
                     { nejaka skupina je jiz namacknuta }
                     if ((ClickStatus <= 3) and (Building = NIL)) then begin
                     { skupina se muze presouvat nebo utocit }
                     { POKUS O PRESUN }
                       Bool:=True;
                       for II:=0 to SavedWayPointsMax[PressedKey-$3f] do
                       with (SavedWayPoints[PressedKey-$3f,II]) do begin
                          for K:=0 to MaxGroupUnits-1 do
                            if (Un[K] <> Nil) then
                            { testuje dostupnost cile pro vsechny jednotky }
                              Bool:=Bool and Free_place_three2(IAim,JAim,
                                           Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].IUnitSize,
                                           Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].JUnitSize,
                                           Level,Un[K]);
                       end;
                       if (Bool) then begin
                       { OK, waypoint mozne priradit }
                          for K:=0 to MaxGroupUnits-1 do
                            if (Un[K] <> NIL) then with (Un[K]^) do begin
                              WayPointUk:=0;
                              WayPointMax:=SavedWayPointsMax[PressedKey-$3f];
                              WayPoint:=SavedWayPoints[PressedKey-$3f];
                            end;
                          with (SavedWayPoints[PressedKey-$3f,0]) do begin
                            Set_move_active_group(IAim,JAim,Level,False,ClickStatus,MyRace);
                          end;
                       end else begin
                       { waypoint nemozno priradit }
                          NormCursor := GetAccurateDelay(4);
                          SetCursor(NoCursor);
                       end;
                     end else
                       if ((ActiveGroup < 255) and (Building <> Nil) and
                           (Building^.Race = MyRace) and
                           (Building_types[Building^.BuildingType].ProductionType < 1))
                       then with (Groups[ActiveGroup]) do with (Building^) do begin
                          WayPointUk:=0;
                          WayPointMax:=SavedWayPointsMax[PressedKey-$3f];
                          WayPoint:=SavedWayPoints[PressedKey-$3f];
                          Click_on_group(ActiveGroup);
                       end;
                   end;
                 end;
      $58..$5b : begin { shift+ F5-F8 = edituj waypoint pro ulozeni }
                    WayPointDef:=PressedKey-$58+3;
                    TempWayPointMax:=255;
                    SetCursor(NormalCursor);
                 end;
      $11 : begin { W - definice waypointu }
              if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                 TempWayPointMax:=255;
                 if ((Building <> Nil) and (Building^.Race = MyRace) and
                     (Building^.BuildPhase > 3)) then begin
                   if (Building_types[Building^.BuildingType].ProductionType < 1)
                   then WayPointDef:=2;
                 end else WayPointDef:=1;
                 SetCursor(NormalCursor);
              end;
            end;
      $1c : begin { Enter - konec definice waypointu }
               if (WayPointDef = 1) then begin
               { uloz a posli }
                 if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                   for K:=0 to MaxGroupUnits-1 do
                     if (Un[K] <> NIL) then with (Un[K]^) do begin
                       WayPointUk:=0;
                       WayPointMax:=TempWayPointMax;
                       WayPoint:=TempWayPoint;
                     end;
                   with (TempWayPoint[0]) do begin
                      Set_move_active_group(IAim,JAim,Level,False,ClickStatus,MyRace);
                   end;
                 end;
               end else
                 if (WayPointDef = 2) then begin
                 { budovy }
                   if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                     if (Building <> Nil) then with (Building^) do begin
                       WayPointUk:=0;
                       WayPointMax:=TempWayPointMax;
                       WayPoint:=TempWayPoint;
                       Click_on_group(ActiveGroup);
                     end;
                   end;
                 end else if (WayPointDef > 2) then begin
                   { pouze uloz }
                   SavedWayPointsMax[WayPointDef-3]:=TempWayPointMax;
                   SavedWayPoints[WayPointDef-3]:=TempWayPoint;
                 end;
               WayPointDef:=0; SetCursor(NormalCursor);
            end;
      $0e : begin { BckSpace - zruseni definice waypointu }
               if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                 if ((Building <> Nil) and (WayPointDef = 0)) then
                 with (Building^) do begin
                 { zrus waypoint u budovy, nejde-li o mod editace }
                    WayPointUk:=255; WayPointMax:=255;{}
                    if (Race = MyRace) then Click_on_group(ActiveGroup);
                 end;
               end;
               if (WayPointDef <> 0) then begin
                 WayPointDef:=0;
                 SetCursor(NormalCursor);
               end;
            end;
      $52 : begin  { INSERT }
              if (Active(StopButton)) then begin
                 Buttn:=StopButton;
                 ReadMouse:=True;
              end;
            end;
      $53 : begin  { DELETE = INSERT }
              if (Active(StopButton)) then begin
                 Buttn:=StopButton;
                 ReadMouse:=True;
              end;
            end;
      $0f: if (KillMode) then KillMode:=False else KillMode:=True; { Tab }
      $39: begin { mezernik }
      {       if (BuildRadarMod) then BuildRadarMod:=False
      {       else BuildRadarMod:=True; { Tab }
      {       CursorOff; DrawRadar; PushDown(RadarModButton); CursorOn;
             RadarModButtonPressed:=True;{}
             Center_active_group;
          end;{}
      $69: Draw_screen(IBeg,JBeg,0,0); { ALT + F2 ... refresh obrazovky }
      $44:  begin { F10 - menu }
              if (not Retreat) then begin
                CursorOff;
                PushDown(MenuButton);
                CursorOn;
                MenuPressed:=True;
                MenuActive:=True;
              end;
            end;
      $85 : begin { F11 - play }
              Exec('cdrom.exe','p');{}
            end;
      $86: begin { F12 - stop }
              Exec('cdrom.exe','s');
           end;
      $87: begin { shift F11 - skip forward }
              Exec('cdrom.exe','k');
           end;
      $88: begin { shift F12 - skip backward }
              Exec('cdrom.exe','b');
           end;
      $8b: begin { alt F11 = + volume }
              Exec('cdrom.exe','+');
           end;
      $8c: begin { alt F12 = - volume }
              Exec('cdrom.exe','-');
           end;
   end;
   {if (Alt) then Center_active_group;{}

 bebex:=1007;
 if (WayPointDef <> 0) then begin { definice waypointu - zrus ostatni akce }
   Buttn:=0; Slots:=255; ADefSlots:=255;
   if ((X >= XScreenBeg) and (Y >= YScreenBeg) and
       (X <= XScreenEnd) and (Y <= YScreenEnd)) then begin
   { stisk na mape }
      Butt:=Butt and 10;
   end else begin { stisk jinde se rusi }
      if ((Butt <> 0) and (not Radar) and (Scroll = 0)) then
         ReadMouse:=False;
   end;

 end;
 if (MousKeybTest) then MousKeybTest:=False
 else MousKeybTest:=True;
 Validity:=True;

 if (Retreat and (Scroll = 0) and (not Radar)) then Validity:=False;
end;

{ ***** }
procedure Click_or_move_group(I,J:Word; var Butt:Word);
{ bud oznaci jednotku nebo ji posune nebo zgrupuje;
  clicknuto pritom bylo na pozici I,J
}
label Skip, Not_succes1, Not_succes2, Not_succes3;
var Target, K, L, Pomocna:Word;
    Pom:Boolean;
    Unit_building, Load :Boolean;
    ADefRange:Word;
    PomUnit:PUnit;
    Id:Byte;
begin
   if (CtrlChangeLevel) then begin Button:=0; ButtonClick:=0; end;
   if (ClickLevel = 0) then with (Map^[I,J]) do begin { pozemni jednotky }
     {2}  if ((First_level <> 0) and (Level_type and 128 = 0) and
              ((Units[First_level]^.Race = MyRace) or
               (Butt and 2 <> 2)) and (Units[First_level]^.Visibility) and
               Units[First_level]^.Activity) then begin
             { OK, namacknuta nova jednotka }
             bebex:=101;
        {3}  if (Butt and 1 = 1) then with (Groups[MaxGroups]) do
             with (Units[First_level]^) do begin
                  bebex:=102;
                  Count:=1; { leve tlacitko }
                  if (Race <> MyRace) then
                    if (Races[MyRace].Friend[Race] > 1) then
                       ClickStatus:=254 { pratelska jednotka }
                    else ClickStatus:=255 { nepratelska, neutralni jednotka }
                  else ClickStatus:=1; { vlastni jednotka }
                  bebey:=10;
                  Clear_group_slots;
                  if (ActiveGroup < 254) then
                  { vlastni jednotka }
                     Deselect_group(ActiveGroup);
                  for K:=0 to MaxGroupUnits-1 do
                    if (Un[K] <> NIL) then begin
                       Un[K]^.Group:=254;
                       Un[K]:=NIL;
                    end;
                  bebey:=11;
                  if (Building <> Nil) then Building^.Group:=254;
                  Building:=Nil;
                  Un[0]:=Units[First_level];
                  Group:=MaxGroups;
                  GroupOrder:=0;
                  Select_group(MaxGroups);
                  if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3)
                  then GroupLevel:=1
                  else GroupLevel:=0;
                  bebey:=12;
                  if ((ClickStatus <> 255) or (EnemyStatus)) then
                     Click_on_group(ActiveGroup) { zobrazit vse}
                  else Click_on_enemy_unit(Units[First_level]); { nezobrazit vse }
                  if ((ClickStatus = 1) and
                      (UnitsInsideNum > 0)) then begin
                     Click_on_storage_unit(Units[First_level]);
                  end;
                  bebey:=13;
                  ADefRng:=ActiveDefenceRange;
             {4}  if (ClickStatus < 254) then begin
                  { vlastni jednotka }
                    if ((UnitType = 33) and (XOffset = 0) and (YOffset = 0)) then begin
                      bebey:=14;
                      if (not _building) then
                        Set_unit_building_shadow(IPos,JPos,1,1)
                      else
                        Set_unit_building_shadow(IPos,JPos,
                                          Building_types[BuildingType].IBuildingSize,
                                          Building_types[BuildingType].JBuildingSize);
                    end;
                    if (not Active(Stop)) then SetActive(Stop);
                    if (not Active(Patrol) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel < 255)) then
                       SetActive(Patrol)
                    else
                       if (Active(Patrol) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255)) then
                         SetPasive(Patrol,256);
                    if (not Active(Nalozit) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel < 255) and
                        (GroupLevel = 0)) then
                       SetActive(Nalozit)
                    else
                       if (Active(Nalozit) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255)
                           or (GroupLevel <> 0))
                       then SetPasive(Nalozit,256);
                    if ((not Active(Vylozit)) and (Unit_types[UnitType,Races[Race].Ally].Capacity > 0) and
                        (UnitsInsideNum > 0)) then begin
                       if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                       SetActive(Vylozit);
                    end else begin
                       if (Active(Vylozit) and ((Unit_types[UnitType,Races[Race].Ally].Capacity = 0) or
                           (UnitsInsideNum = 0))) then SetPasive(Vylozit,256);
                       if (Active(Rozlozit) and (UnitType <> 33)) then
                          SetPasive(Rozlozit,256)
                       else
                          if (UnitType = 33) then SetActive(Rozlozit);
                    end;
                    if (not Active(Opravit)) then SetActive(Opravit);
                    if ((not Active(ZvednoutMoralku)) and (MyRaceType <> 3) and
                        (MyRaceType <> 6))
                    then SetActive(ZvednoutMoralku);
                    bebey:=15;
                    case (ADefRng) of
                      ADRng1 : ADefRange:=0;
                      ADRng2 : ADefRange:=1;
                      ADRng3 : ADefRange:=2;
                      ADRng4 : ADefRange:=3;
                      65535  : ADefRange:=4;
                    end;
                    bebey:=16;
                    SetActiveDefenceRangeSlotsActivity(ADefRange);
                    case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                       0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                    end;
                    if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) then Id:=0;
                    if ((Races[MyRace].RaceType <> 3) and
                        (Races[MyRace].RaceType <> 6)) then
                      PreparePlaySound(0,0,0,Id)
                    else PreparePlaySound(1,0,0,Id);
                    bebey:=17;
                  end else begin {4}
                  { cizi jednotka }
                    if (Active(Stop)) then SetPasive(Stop,256);
                    if (Active(Patrol)) then SetPasive(Patrol,256);
                    if (Active(Nalozit)) then SetPasive(Nalozit,256);
                    if (Active(Vylozit)) then SetPasive(Vylozit,256);
                    if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                    if (Active(Opravit)) then SetPasive(Opravit,256);
                    if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                    ClearActiveDefenceRangeSlots;
                  end; {4}
                  bebey:=18;
                  SetCursor(NormalCursor);
             end else begin { if (Butt = 1) then ... else } { 3 }
               bebex:=103;
         {12}  if ((ActiveGroup < 254) and
                   (Groups[ActiveGroup].ClickStatus = 2) and
                   (Butt and 2 = 2)) then
               with (Groups[MaxGroups]) do
               with (Units[First_level]^) do begin
                  { NALOZIT }
                     bebex:=104;
                     if (Race = MyRace) then begin
                        Pomocna:=0; Id:=255;
                        for K:=0 to MaxGroupUnits-1 do begin
                        { zjisti naroky jednotek na misto }
                          if (Un[K] <> NIL) then begin
                            Inc(Pomocna,Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].NeedPlace);
                            if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                                (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) and
                                (Un[K]^.UnitType <> 7) and (Un[K]^.UnitType <> 9) and
                                (Un[K]^.UnitType <> 15))
                            then Inc(Pomocna,255); { do vysadkovych letadel
                            lze nalozit jen vysadkare - u ostatnich jednotek
                            umele zvys jejich naroky na misto a tak zabran
                            nalozeni }
                            if ((Unit_types[UnitType,Races[Race].Ally].TargetTyp < 3) and
                                (Un[K]^.TargetType > 1))
                            then Inc(Pomocna,255);
                            { do pozemnich vozidel nelze nalozit tezkou
                              jednotku }
                            if (Id = 255) then Id:=Unit_types[UnitType,Races[Race].Ally].TargetTyp;
                          end;
                        end;
                        if (((Pomocna+UnitsInsidePlace) <= Unit_types[UnitType,Races[Race].Ally].Capacity) and
                            (UnitsInsideNum < (MaxGroupUnits-1))) then
                        begin
                          { USPECH }
                          for K:=0 to MaxGroupUnits-1 do
                            if (Un[K] <> NIL) then begin
                               Un[K]^.WayPointMax:=0; Un[K]^.WayPointUk:=0;
                            end;
                          Set_move_active_group(I,J,0,True,ClickStatus,MyRace);
                          SetCursor(NormalCursor);
                          Set_ok_cursor_mark(I,J,0);
                          case (Id) of
                            0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                          end;
                          if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) then Id:=0;
                          if (Id < 255) then
                            if ((Races[MyRace].RaceType <> 3) and
                                (Races[MyRace].RaceType <> 6)) then
                               PreparePlaySound(0,0,8,Id)
                            else PreparePlaySound(1,0,8,Id);
                        end else begin
                          { NEUSPECH }
                          NormCursor :=GetAccurateDelay(1);
                          SetCursor(NoCursor);
                          ClickStatus:=1;
                          {Button:=0; ButtonClick:=0;{}
                        end;
                     end else begin
                        { NEUSPECH }
                        NormCursor := GetAccurateDelay(1);
                        SetCursor(NoCursor);
                        ClickStatus:=1;
                        {Button:=0; ButtonClick:=0;{}
                     end;
          {12} end else begin
                 bebex:=105;
                 if ((ActiveGroup < 255) and (Units[First_level]^.Race = MyRace)
                     and (Groups[ActiveGroup].GroupLevel = 0) and
                     (Groups[ActiveGroup].ClickStatus < 254))
             {5} then with (Groups[ActiveGroup]) do begin
                   ClickStatus:=1; { prave tlacitko - pridej/uber do/ze skupiny }
                   MiddleButton:=1; RightButton:=1;
              {6}  if (Units[First_level]^.Group = ActiveGroup) then begin
                    if (Count > 1) then begin
                    { jednotka ze skupiny bude "deselectovana" }
                      Dec(Count);
                      Clear_unit_slot(Units[First_level]);
                      Units[First_level]^.Group:=254;
                      Un[Units[First_level]^.GroupOrder]:=NIL;
                      Units[First_level]^.GroupOrder:=255;
                      Deselect_unit(Units[First_level]);
                      K:=1; L:=0; Load:=False;
                      { nyni zjistime vyskyt jednotek-budov respektive
                        nalozenych transporteru ve skupine }
                      Unit_building:=False; Load:=False;
                      while ((K <= MaxGroupUnits) and (L < Count)) do begin
                         if (Un[K-1] <> Nil) then with (Un[K-1]^) do begin
                           Inc(L);
                           if (UnitType = 33) then Unit_building:=True;
                           if (UnitsInsideNum <> 0) then begin
                              PomUnit:=Un[K-1];
                              Load:=True;
                           end;
                           if (L = 1) then  ADefRange:=ActiveDefenceRange;
                           if (ADefRange <> ActiveDefenceRange)
                           then ADefRange:=65535;
                         end;
                         Inc(K);
                      end;
                      if (Count = 0) then begin
                         ClearActiveDefenceRangeSlots;
                         Deselect_group(ActiveGroup);
                         if (Active(Stop)) then SetPasive(Stop,256);
                         if (Active(Patrol)) then SetPasive(Patrol,256);
                         if (Active(Nalozit)) then SetPasive(Nalozit,256);
                         if (Active(Vylozit)) then SetPasive(Vylozit,256);
                         if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                         if (Active(Opravit)) then SetPasive(Opravit,256);
                         if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                      end else begin
                        {if (NetType = 1) then begin { seriovy kabel }
                        {   IPX_SendByte(0);
                           IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
                           IPX_SendByte(Count);
                           SerialCheckSum:=0+Count;
                           for K:=0 to MaxGroupUnits-1 do
                             if (Un[K] <> NIL) then begin
                               IPX_SendWord(Un[K]^.Index);
                               SerialCheckSum:=SerialCheckSum+Un[K]^.Index;
                             end;
                           IPX_SendWord(SerialCheckSum);
                           SerialCheckSum:=0;
                        end; {}
                        ADefRng:=ADefRange;
                        case (ADefRange) of
                          ADRng1  : ADefRange:=0;
                          ADRng2  : ADefRange:=1;
                          ADRng3  : ADefRange:=2;
                          ADRng4  : ADefRange:=3;
                          65535   : ADefRange:=4;
                        end;
                        SetActiveDefenceRangeSlotsActivity(ADefRange);
                        if (Count = 1) then begin
                          if (Load) then begin
                             Clear_unit_slot(PomUnit);
                             PomUnit^.GroupOrder:=0;
                             Click_on_unit(PomUnit);
                             Click_on_storage_unit(PomUnit);
                          end;
                          if (not Active(Patrol)) then SetActive(Patrol);
                          if (not Active(Vylozit) and Load) then
                            SetActive(Vylozit)
                          else
                            if (not Active(Rozlozit) and Unit_building) then
                              SetActive(Rozlozit);{}
                        end else begin
                          if (Active(Vylozit)) then SetPasive(Vylozit,256);
                          if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                        end;
                      end;
                    end;
                   end else {6} if ((Count < MaxGroupUnits) and
                                    (Building = Nil)) then begin
                   { jednotka bude do skupiny pridana (nesmi byt
                     naclicknuta budova) }
                      K:=0; Inc(Count);
                      while ((K <= (MaxGroupUnits-1)) and (Un[K] <> NIL)) do begin
                        if (Un[K]^.Race <> MyRace) then GoTo Skip
                        else Inc(K);
                      end;
                      if (Count <> 1) then begin
                         if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                         if (Active(Vylozit)) then SetPasive(Vylozit,256);
                      end; {}
                      Un[K]:=Units[First_level];
                      Units[First_level]^.Group:=ActiveGroup;
                      Units[First_level]^.GroupOrder:=K;
                      Select_unit(Units[First_level]);
                      if (Count = 2) then begin
                        Clear_group_slots;
                        Click_on_group(ActiveGroup);
                      end else Click_on_unit(Units[First_level]);
                      if (ADefRng <> Units[First_level]^.ActiveDefenceRange)
                      then ADefRng:=65535;
                      case (ADefRng) of
                         ADRng1  : ADefRange:=0;
                         ADRng2  : ADefRange:=1;
                         ADRng3  : ADefRange:=2;
                         ADRng4  : ADefRange:=3;
                         65535   : ADefRange:=4;
                      end;
                      SetActiveDefenceRangeSlotsActivity(ADefRange);
                   end; {6}
                 end; {5}
               end; {12}
             end; {3}
          end else begin {2}
       {7}    if ((First_level <> 0) and (Level_type and 128 = 128) and
                  (Butt and 1 = 1) and Buildings[First_level]^.Activity)
              then begin
                bebex:=106;
                { OK, namacknuta nova BUDOVA }
                if ((Butt and 1 = 1) and ((ActiveGroup >= 254) or (ActiveGroup < 254) and
                    (Groups[ActiveGroup].ClickStatus <> 2)) and
                    (Buildings[First_level]^.Visibility))
                then with (Groups[MaxGroups]) do begin
                   Count:=1; { leve tlacitko }
                   ClearActiveDefenceRangeSlots;
                   if (Buildings[First_level]^.Race <> MyRace) then
                     if (Races[MyRace].Friend[Buildings[First_level]^.Race] > 1) then
                        ClickStatus:=254 { pratelska budova }
                     else ClickStatus:=255 { nepratelska budova }
                   else ClickStatus:=1; { vlastni budova }
                   Clear_group_slots;
                   if (ActiveGroup < 254) then Deselect_group(ActiveGroup);
                   for K:=0 to MaxGroupUnits-1 do
                     if (Un[K] <> NIL) then begin
                        Un[K]^.Group:=254;
                        Un[K]:=NIL;
                     end;
                   if (Building <> NIL) then Building^.Group:=254;
                   Building:=Buildings[First_level];
                   Building^.Group:=MaxGroups;
                   Select_group(MaxGroups);
                   GroupLevel:=0;
                   Click_on_group(ActiveGroup); { zobrazit vse}
                   if (ClickStatus < 254) then begin
                     {if (NetType = 1) then begin { seriovy kabel }
                     {   IPX_SendByte(1);
                        IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
                        IPX_SendWord(First_level);
                        SerialCheckSum:=1+First_level;
                        IPX_SendWord(SerialCheckSum);
                        SerialCheckSum:=0;
                     end;{}
                   end;
                   if ((not Active(Stop) and (Building^.Race = MyRace)))
                   then SetActive(Stop);
                   if (Active(Stop) and (Building^.Race <> MyRace))
                   then SetPasive(Stop,256);
                   if (Active(Patrol)) then SetPasive(Patrol,256);
                   if (Active(Nalozit)) then SetPasive(Nalozit,256);
                   if (Active(Vylozit)) then SetPasive(Vylozit,256);
                   if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                   if ((not Active(Opravit)) and (Building^.Race = MyRace))
                   then SetActive(Opravit);
                   if (Active(Opravit) and (Building^.Race <> MyRace))
                   then SetPasive(Opravit,256);
                   if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                end;
              end else begin {7}
            {8}  if ((ActiveGroup < 255) and (Groups[ActiveGroup].ClickStatus < 254) and
                     (Butt and 2 = 2)) then with (Groups[ActiveGroup]) do begin
                 { nejaka skupina je jiz namacknuta }
                    bebex:=107;
                    if (ActuallCursor = GoInsideCursor) then SetCursor(NormalCursor);
               {9}  if ((ClickStatus <= 3) and (Building = NIL)) then begin
                    { skupina se muze presouvat nebo utocit }
                       if ((First_level <> 0) and
                           ((Level_type and 128 = 0) and
                            (Units[First_level]^.Visibility) and
                            (Races[MyRace].Friend[Units[First_level]^.Race] = 0) or
                            (Level_type and 128 = 128) and
                            (Buildings[First_level]^.Visibility) and
                            (Races[MyRace].Friend[Buildings[First_level]^.Race] = 0)))
                       then begin
                       { * UTOK !! * }
                          bebex:=109;
                          Prepare_attack_group(I,J,8,MyRace,0);
                          K:=0;
                          while ((K <= (MaxGroupUnits-1)) and (Un[K] = NIL)) do
                            Inc(K);
                          Id:=Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].TargetTyp;
                          case (Id) of
                            0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                          end;
                          if (Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].UnitLevel = 255) then Id:=0;
                          if ((Races[MyRace].RaceType <> 3) and
                              (Races[MyRace].RaceType <> 6)) then
                             PreparePlaySound(0,0,2,Id)
                          else PreparePlaySound(1,0,2,Id);
                 {10}  end else begin
                       { POKUS O PRESUN }
                          Pom:=True; bebex:=108;
                          for K:=0 to MaxGroupUnits-1 do
                            if (Un[K] <> Nil) then with (Un[K]^) do begin
                            { testuje dostupnost cile pro vsechny jednotky }
                              Pom:=Pom and Free_place_three(I,J,
                                           Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                           Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                           0,Un[K]);
                              WayPointMax:=0; WayPointUk:=0;
                            end;
                    {11}  if (Pom) then begin
                          { OK, cil je dostupny pro vsechny - presunuj }
                            Set_ok_cursor_mark(I,J,0);
                            Set_move_active_group(I,J,0,False,ClickStatus,MyRace);
                            if (ClickStatus = 3) then ClickStatus:=1;
                            K:=0;
                            while ((K <= (MaxGroupUnits-1)) and (Un[K] = NIL)) do
                              Inc(K);
                            Id:=Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].TargetTyp;
                            case (Id) of
                              0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                            end;
                            if (Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].UnitLevel = 255) then Id:=0;
                            if ((Races[MyRace].RaceType <> 3) and
                                (Races[MyRace].RaceType <> 6)) then
                               PreparePlaySound(0,0,1,Id)
                            else PreparePlaySound(1,0,1,Id);
                          end else begin {11}
                          { neuspesny pokus o presun }
                             NormCursor := GetAccurateDelay(1);
                             SetCursor(NoCursor);
                             {Button:=0; ButtonClick:=0;{}
                          end; {11}
                       end; {10}
                    end; { if (ClickStatus = 1) } {9}
                 end else begin { if (ActiveGroup <> 255) } {8}
                 { clicknuto "nikam" - proved group select }
                    if (Butt = 1) then Butt:=16;
                 end;
              end; {7}
         end; {2}
{X}end else with (Map^[I,J]) do begin { letecke jednotky }
           if ((Second_level <> 0) and ((Units[Second_level]^.Race = MyRace) or
               (Butt and 2 <> 2)) and (Units[Second_level]^.Visibility) and
               Units[Second_level]^.Activity and
               (not Units[Second_level]^.Return_to_base)) then begin
              { OK, namacknuta nova jednotka }
             if (Butt and 1 = 1) then with (Groups[MaxGroups]) do begin
           {13} if ((ActiveGroup < 254) and
                    (Groups[ActiveGroup].ClickStatus = 2)) then begin
                { NALOZIT }
                { NIC SE NEDEJE - VZDUSNOU JEDNOTKU NELZE NALOZIT }
           {13} end else begin
                  bebex:=110;
                  Count:=1; { leve tlacitko }
                  if (Units[Second_level]^.Race <> MyRace) then
                    if (Races[MyRace].Friend[Units[Second_level]^.Race] > 1) then
                       ClickStatus:=254 { pratelska jednotka }
                    else ClickStatus:=255 { nepratelska jednotka }
                  else ClickStatus:=1; { vlastni jednotka }
                  Clear_group_slots;
                  if (ActiveGroup < 254) then
                     Deselect_group(ActiveGroup);
                  for K:=0 to MaxGroupUnits-1 do
                    if (Un[K] <> NIL) then begin
                       Un[K]^.Group:=254;
                       Un[K]:=NIL;
                    end;
                  if (Building <> Nil) then Building^.Group:=254;
                  Building:=Nil;
                  Un[0]:=Units[Second_level];
                  Units[Second_level]^.Group:=MaxGroups;
                  Units[Second_level]^.GroupOrder:=0;
                  Select_group(MaxGroups);
                  GroupLevel:=1;
                  if ((ClickStatus <> 255) or (EnemyStatus)) then
                     Click_on_group(ActiveGroup) { zobrazit vse}
                  else Click_on_enemy_unit(Units[Second_level]);
                  if ((ClickStatus <> 255) or (EnemyStatus)) then
                     Click_on_group(ActiveGroup) { zobrazit vse}
                  else Click_on_enemy_unit(Units[Second_level]);
                  if ((ClickStatus = 1) and
                      (Units[Second_level]^.UnitsInsideNum > 0)) then begin
                     Click_on_storage_unit(Units[Second_level]);
                  end;
                  { nezobrazit vse }
                  ADefRng:=Units[Second_level]^.ActiveDefenceRange;
                  if (ClickStatus < 254) then with (Units[Second_level]^) do begin
                  { vlastni jednotka }
                    {if (NetType = 1) then begin { seriovy kabel }
                    {   IPX_SendByte(0);
                       IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
                       IPX_SendByte(1);
                       IPX_SendWord(Second_level);
                       SerialCheckSum:=0+1+Second_level;
                       IPX_SendWord(SerialCheckSum);
                       SerialCheckSum:=0;
                    end; {}
                    if (not Active(Stop)) then SetActive(Stop);
                    if (not Active(Patrol)) then SetActive(Patrol);
                    if (Active(Nalozit)) then SetPasive(Nalozit,256);
                    if ((not Active(Vylozit)) and (Unit_types[UnitType,Races[Race].Ally].Capacity > 0) and
                        (UnitsInsideNum > 0)) then begin
                       if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                       SetActive(Vylozit);
                    end else begin
                       if (Active(Vylozit) and ((Unit_types[UnitType,Races[Race].Ally].Capacity = 0) or
                           (UnitsInsideNum = 0))) then SetPasive(Vylozit,256);
                       if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                    end;
                    if (not Active(Opravit)) then SetActive(Opravit);
                    if ((not Active(ZvednoutMoralku)) and (MyRaceType <> 3) and
                        (MyRaceType <> 6))
                    then SetActive(ZvednoutMoralku);
                    case (ADefRng) of
                      ADRng1  : ADefRange:=0;
                      ADRng2  : ADefRange:=1;
                      ADRng3  : ADefRange:=2;
                      ADRng4  : ADefRange:=3;
                      65535   : ADefRange:=4;
                    end;
                    SetActiveDefenceRangeSlotsActivity(ADefRange);
                    case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                       0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                    end;
                    if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) then Id:=0;
                    if ((Races[MyRace].RaceType <> 3) and
                        (Races[MyRace].RaceType <> 6)) then
                      PreparePlaySound(0,0,0,Id)
                    else PreparePlaySound(1,0,0,Id);
                  end else begin
                  { cizi jednotka }
                    if (Active(Stop)) then SetPasive(Stop,256);
                    if (Active(Patrol)) then SetPasive(Patrol,256);
                    if (Active(Nalozit)) then SetPasive(Nalozit,256);
                    if (Active(Vylozit)) then SetPasive(Vylozit,256);
                    if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                    if (Active(Opravit)) then SetPasive(Opravit,256);
                    if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                    ClearActiveDefenceRangeSlots;
                  end;
                end; {13}
             end else { if (Butt = 1) then ... else }
              if ((ActiveGroup < 255) and (Units[Second_level]^.Race = MyRace)
                  and (Groups[ActiveGroup].GroupLevel = 1) and
                  (Groups[ActiveGroup].ClickStatus < 254))
              then with (Groups[ActiveGroup]) do begin
                bebex:=111;
                ClickStatus:=1; { prostredni tlacitko - pridej/uber do/ze skupiny }
                MiddleButton:=1; RightButton:=1;
                if (Units[Second_level]^.Group = ActiveGroup) then begin
                 if (Count > 1) then begin
                 { jednotka ze skupiny bude "deselectovana" }
                   Dec(Count);
                   Clear_unit_slot(Units[Second_level]);
                   Units[Second_level]^.Group:=254;
                   Un[Units[Second_level]^.GroupOrder]:=NIL;
                   Deselect_unit(Units[Second_level]);
                   K:=1; L:=0; Load:=False;
                   while ((K <= MaxGroupUnits) and (L < Count)) do begin
                     if (Un[K-1] <> Nil) then with (Un[K-1]^) do begin
                        Inc(L);
                        if (UnitsInsideNum <> 0) then begin
                            PomUnit:=Un[K-1];
                            Load:=True;
                        end;
                        if (L = 1) then  ADefRange:=ActiveDefenceRange;
                        if (ADefRange <> ActiveDefenceRange)
                        then ADefRange:=65535;
                      end;
                      Inc(K);
                   end;
                   if (Count = 0) then begin
                      Deselect_group(ActiveGroup);
                      if (Active(Stop)) then SetPasive(Stop,256);
                      if (Active(Patrol)) then SetPasive(Patrol,256);
                      if (Active(Nalozit)) then SetPasive(Nalozit,256);
                      if (Active(Vylozit)) then SetPasive(Vylozit,256);
                      if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                      if (Active(Opravit)) then SetPasive(Opravit,256);
                      if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                      ClearActiveDefenceRangeSlots;
                   end else begin
                      ADefRng:=ADefRange;
                      case (ADefRange) of
                         ADRng1 : ADefRange:=0;
                         ADRng2 : ADefRange:=1;
                         ADRng3 : ADefRange:=2;
                         ADRng4 : ADefRange:=3;
                         65535  : ADefRange:=4;
                      end;
                      SetActiveDefenceRangeSlotsActivity(ADefRange);
                      {if (NetType = 1) then begin { seriovy kabel }
                      {   IPX_SendByte(0);
                         IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
                         IPX_SendByte(Count);
                         SerialCheckSum:=0+Count;
                         for K:=0 to MaxGroupUnits-1 do
                           if (Un[K] <> NIL) then begin
                                IPX_SendWord(Un[K]^.Index);
                                SerialCheckSum:=SerialCheckSum+Un[K]^.Index;
                             end;
                         IPX_SendWord(SerialCheckSum);
                         SerialCheckSum:=0;
                      end;{}
                   end;
                   if (Count = 1) then begin
                      if (Load) then begin
                         Clear_unit_slot(PomUnit);
                         PomUnit^.GroupOrder:=0;
                         Click_on_unit(PomUnit);
                         Click_on_storage_unit(PomUnit);
                         if (not Active(Vylozit)) then SetActive(Vylozit);
                      end;
                   end;{}
                 end;
                end else if (Count < MaxGroupUnits) then begin
                { jednotka bude do skupiny pridana }
                   bebex:=112;
                   K:=0; Inc(Count);
                   while ((K <= (MaxGroupUnits-1)) and (Un[K] <> NIL)) do begin
                      if (Un[K]^.Race <> MyRace) then GoTo Skip
                      else Inc(K);
                   end;
                   if (Count <> 1) then begin
                      if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                      if (Active(Vylozit)) then SetPasive(Vylozit,256);
                   end;
                   Un[K]:=Units[Second_level];
                   Units[Second_level]^.Group:=ActiveGroup;
                   Units[Second_level]^.GroupOrder:=K;
                   Select_unit(Units[Second_level]);
                   if (Count = 2) then begin
                      Clear_group_slots;
                      Click_on_group(ActiveGroup);
                   end else Click_on_unit(Units[Second_level]);
                   if (ADefRng <> Units[Second_level]^.ActiveDefenceRange)
                   then ADefRng:=65535;
                   case (ADefRng) of
                      ADRng1 : ADefRange:=0;
                      ADRng2 : ADefRange:=1;
                      ADRng3 : ADefRange:=2;
                      ADRng4 : ADefRange:=3;
                      65535  : ADefRange:=4;
                   end;
                   SetActiveDefenceRangeSlotsActivity(ADefRange);

                   {if (NetType = 1) then begin { seriovy kabel }
                   {    IPX_SendByte(0);
                       IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
                       IPX_SendByte(Count);
                       SerialCheckSum:=0+Count;
                       for K:=0 to MaxGroupUnits-1 do
                         if (Un[K] <> NIL) then begin
                               IPX_SendWord(Un[K]^.Index);
                               SerialCheckSum:=SerialCheckSum+Un[K]^.Index;
                            end;
                         IPX_SendWord(SerialCheckSum);
                         SerialCheckSum:=0;
                   end; {}
                end;
              end;
     {66}  end else if ((ActiveGroup <> 255) and
                        (Groups[ActiveGroup].ClickStatus < 254) and
                        (Butt and 2 = 2)) then
                    with (Groups[ActiveGroup]) do begin
                 { nejaka skupina je jiz namacknuta }
                 bebex:=113;
                 if (ActuallCursor = GoInsideCursor) then SetCursor(NormalCursor);
                 if (ClickStatus <= 3) then begin
                 { skupina se muze presouvat nebo utocit }
                    if ((Second_level <> 0) and (Units[Second_level]^.Visibility) and
                        (Races[MyRace].Friend[Units[Second_level]^.Race] = 0))
                    then begin
                    { * UTOK !! *  }
                        bebex:=114;
                        Prepare_attack_group(I,J,8,MyRace,1);
                        K:=0;
                        while ((K <= (MaxGroupUnits-1)) and (Un[K] = NIL)) do
                          Inc(K);
                        Id:=Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].TargetTyp;
                        case (Id) of
                          0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                        end;
                        if (Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].UnitLevel = 255) then Id:=0;
                        if ((Races[MyRace].RaceType <> 3) and
                            (Races[MyRace].RaceType <> 6)) then
                           PreparePlaySound(0,0,2,Id)
                        else PreparePlaySound(1,0,2,Id);
                    end else if (Groups[ActiveGroup].GroupLevel = 1) then begin
                    { POKUS O PRESUN }
                       Pom:=True;
                       for K:=0 to MaxGroupUnits-1 do
                         if (Un[K] <> Nil) then with (Un[K]^) do begin
                         { testuje dostupnost cile pro vsechny jednotky }
                           Pom:=Pom and Free_place_three(I,J,
                                        Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                        Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                        1,Un[K]) and (not Un[K]^.Return_to_base);
                            WayPointMax:=0; WayPointUk:=0;
                          end;
                       if (Pom) then begin
                       { OK, cil je dostupny pro vsechny - presunuj }
                         bebex:=115;
                         Set_ok_cursor_mark(I,J,1);
                         Set_move_active_group(I,J,1,False,ClickStatus,MyRace);
                         if (ClickStatus = 3) then ClickStatus:=1;
                         K:=0;
                         while ((K <= (MaxGroupUnits-1)) and (Un[K] = NIL)) do
                            Inc(K);
                         Id:=Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].TargetTyp;
                         case (Id) of
                           0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
                         end;
                         if (Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].UnitLevel = 255) then Id:=0;
                         if ((Races[MyRace].RaceType <> 3) and
                             (Races[MyRace].RaceType <> 6)) then
                            PreparePlaySound(0,0,1,Id)
                         else PreparePlaySound(1,0,1,Id);
                       end else begin
                       { neuspesny pokus o presun }
                          NormCursor := GetAccurateDelay(1);
                          SetCursor(NoCursor);
                          {Button:=0; ButtonClick:=0;{}
                       end;
                    end else begin
                       { neuspesny pokus o presun }
                        NormCursor := GetAccurateDelay(1);
                        SetCursor(NoCursor);
                        {Button:=0; ButtonClick:=0;{}
                    end;
                 end;
     {66}  end else begin {66} { if (ActiveGroup <> 255) }
              if ((ActiveGroup <> 255) and
                  (Groups[ActiveGroup].ClickStatus < 254) and
                  (Groups[ActiveGroup].GroupLevel = 0) and
                  (Butt and 2 = 2))
              then begin
                 NormCursor := GetAccurateDelay(1);
                 SetCursor(NoCursor);
                 {Button:=0; ButtonClick:=0;{}
              end else
                { clicknuto "nikam" - proved group select }
                if (Butt = 1) then Butt:=16;
           end; {66}
   end;
Skip:
end;

{ ***** }
procedure Click_and_waypointdef(I,J:Word; var Butt:Word);
{  pouziva pro definici waypointu
}
label Skip, Not_succes1, Not_succes2, Not_succes3;
var Target, K, L, Pomocna:Word;
    Pom:Boolean;
    Unit_building, Load :Boolean;
    ADefRange:Word;
    PomUnit:PUnit;
    Id:Byte;
begin
  if (CtrlChangeLevel) then begin Button:=0; ButtonClick:=0; end;
  if (WayPointDef = 1) then begin { waypoint pro konkretni jednotku }
      if (ClickLevel = 0) then with (Map^[I,J]) do begin { pozemni jednotky }
        {2}  if ((First_level <> 0) and (Level_type and 128 = 0) and
                 ((Units[First_level]^.Race = MyRace) or
                  (Butt and 2 <> 2)) and
                  Units[First_level]^.Activity) then begin
                { OK, namacknuta nova jednotka }
             end else begin {2}
          {7}    if ((First_level <> 0) and (Level_type and 128 = 128) and
                     (Butt and 1 = 1) and Buildings[First_level]^.Activity)
                 then begin
                 end else begin {7}
               {8}  if ((ActiveGroup < 255) and (Groups[ActiveGroup].ClickStatus < 254) and
                        (Butt and 2 = 2)) then with (Groups[ActiveGroup]) do begin
                    { nejaka skupina je jiz namacknuta }
                  {9}  if ((ClickStatus <= 3) and (Building = NIL)) then begin
                       { skupina se muze presouvat nebo utocit }
                          if (First_level <> 0) then begin
                          { * UTOK !! * }
                    {10}  end else begin
                          { POKUS O PRESUN }
                             Pom:=True;
                             for K:=0 to MaxGroupUnits-1 do
                               if (Un[K] <> Nil) then
                               { testuje dostupnost cile pro vsechny jednotky }
                                 Pom:=Pom and Free_place_three2(I,J,
                                              Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].IUnitSize,
                                              Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].JUnitSize,
                                              0,Un[K]);
                       {11}  if (Pom) then begin
                             { OK, cil je dostupny pro vsechny - presunuj }
                               Set_ok_cursor_mark(I,J,0);
                               if (TempWayPointMax=255) then begin
                                  TempWayPointMax:=0;
                                  TempWayPoint[TempWayPointMax].IAim:=I;
                                  TempWayPoint[TempWayPointMax].JAim:=J;
                                  TempWayPoint[TempWayPointMax].Level:=0;
                               end else begin
                                  Inc(TempWayPointMax);
                                  TempWayPoint[TempWayPointMax].IAim:=I;
                                  TempWayPoint[TempWayPointMax].JAim:=J;
                                  TempWayPoint[TempWayPointMax].Level:=0;
                               end;
                               {Set_move_active_group(I,J,0,False,ClickStatus,MyRace);{}
                               if (ClickStatus = 3) then ClickStatus:=1;
                             end else begin {11}
                             { neuspesny pokus o presun }
                                NormCursor := GetAccurateDelay(1);
                                SetCursor(NoCursor);
                                {Button:=0; ButtonClick:=0;{}
                             end; {11}
                          end; {10}
                       end; { if (ClickStatus = 1) } {9}
                    end else begin { if (ActiveGroup <> 255) } {8}
                    end;
                 end; {7}
            end; {2}
      end else with (Map^[I,J]) do begin { letecke jednotky }
              if ((Second_level <> 0) and ((Units[Second_level]^.Race = MyRace) or
                  (Butt and 2 <> 2)) and
                  Units[Second_level]^.Activity and
                  (not Units[Second_level]^.Return_to_base)) then begin
                 { OK, namacknuta nova jednotka }
        {66}  end else if ((ActiveGroup <> 255) and
                           (Groups[ActiveGroup].ClickStatus < 254) and
                           (Butt and 2 = 2)) then with (Groups[ActiveGroup]) do begin
                    { nejaka skupina je jiz namacknuta }
                    if (ClickStatus <= 3) then begin
                    { skupina se muze presouvat nebo utocit }
                       if ((Second_level <> 0) and
                           (Races[MyRace].Friend[Units[Second_level]^.Race] = 0))
                       then begin
                       { * UTOK !! * }

                       end else if (Groups[ActiveGroup].GroupLevel = 1) then begin
                       { POKUS O PRESUN }
                          Pom:=True;
                          for K:=0 to MaxGroupUnits-1 do
                            if (Un[K] <> Nil) then
                            { testuje dostupnost cile pro vsechny jednotky }
                              Pom:=Pom and Free_place_three2(I,J,
                                           Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].IUnitSize,
                                           Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].JUnitSize,
                                           1,Un[K]) and (not Un[K]^.Return_to_base);
                          if (Pom) then begin
                          { OK, cil je dostupny pro vsechny - presunuj }
                            Set_ok_cursor_mark(I,J,1);
                            {Set_move_active_group(I,J,1,False,ClickStatus,MyRace);{}
                            if (ClickStatus = 3) then ClickStatus:=1;
                            if (TempWayPointMax=255) then begin
                               TempWayPointMax:=0;
                               TempWayPoint[TempWayPointMax].IAim:=I;
                               TempWayPoint[TempWayPointMax].JAim:=J;
                               TempWayPoint[TempWayPointMax].Level:=1;
                            end else begin
                               Inc(TempWayPointMax);
                               TempWayPoint[TempWayPointMax].IAim:=I;
                               TempWayPoint[TempWayPointMax].JAim:=J;
                               TempWayPoint[TempWayPointMax].Level:=1;
                            end;
                          end else begin
                          { neuspesny pokus o presun }
                             NormCursor := GetAccurateDelay(1);
                             SetCursor(NoCursor);
                             {Button:=0; ButtonClick:=0;{}
                          end;
                       end else begin
                          { neuspesny pokus o presun }
                           NormCursor := GetAccurateDelay(1);
                           SetCursor(NoCursor);
                       end;
                    end;
        {66}  end else begin {66} { if (ActiveGroup <> 255) }
                 if ((ActiveGroup <> 255) and
                     (Groups[ActiveGroup].ClickStatus < 254) and
                     (Groups[ActiveGroup].GroupLevel = 0) and
                     (Butt and 2 = 2))
                 then begin
                    NormCursor := GetAccurateDelay(1);
                    SetCursor(NoCursor);
                 end;
              end; {66}
      end;
  end else begin
  { ULOZENI WAYPOINTU BEZ TESTOVANI }
      if (ClickLevel = 0) then with (Map^[I,J]) do begin { pozemni jednotky }
        {2}  if ((First_level <> 0) and (Level_type and 128 = 0) and
                 ((Units[First_level]^.Race = MyRace) or
                  (Butt and 2 <> 2)) and
                  Units[First_level]^.Activity) then begin
                { OK, namacknuta nova jednotka }
             end else begin {2}
                Set_ok_cursor_mark(I,J,0);
                if (TempWayPointMax=255) then begin
                   TempWayPointMax:=0;
                   TempWayPoint[TempWayPointMax].IAim:=I;
                   TempWayPoint[TempWayPointMax].JAim:=J;
                   TempWayPoint[TempWayPointMax].Level:=0;
                end else begin
                   Inc(TempWayPointMax);
                   TempWayPoint[TempWayPointMax].IAim:=I;
                   TempWayPoint[TempWayPointMax].JAim:=J;
                   TempWayPoint[TempWayPointMax].Level:=0;
                end;
            end; {2}
      end else with (Map^[I,J]) do begin { letecke jednotky }
              if ((Second_level <> 0) and ((Units[Second_level]^.Race = MyRace) or
                  (Butt and 2 <> 2)) and
                  Units[Second_level]^.Activity and
                  (not Units[Second_level]^.Return_to_base)) then begin
                 { OK, namacknuta nova jednotka }
        {66}  end else begin
              { skupina se muze presouvat }
                 Set_ok_cursor_mark(I,J,1);
                 {Set_move_active_group(I,J,1,False,ClickStatus,MyRace);{}
                 if (TempWayPointMax=255) then begin
                    TempWayPointMax:=0;
                    TempWayPoint[TempWayPointMax].IAim:=I;
                    TempWayPoint[TempWayPointMax].JAim:=J;
                    TempWayPoint[TempWayPointMax].Level:=1;
                 end else begin
                    Inc(TempWayPointMax);
                    TempWayPoint[TempWayPointMax].IAim:=I;
                    TempWayPoint[TempWayPointMax].JAim:=J;
                    TempWayPoint[TempWayPointMax].Level:=1;
                 end;
        {66}  end;
      end;
  end;
Skip:
end;

{ ***** }
procedure _Scrolling(Scroll:Byte; Keyboard:Boolean);
{ provadi rolovani podle smeru Scroll
  Keyboard = True, roluje-li se s pomoci klavesnice
}
var IPom, JPom, J, X, Y, K, L : Word;
    Pomocn:Byte;
    Border : Word;
    IBegPixel, JBegPixel, XOffset, YOffset : Word;
    Pom,Ascii, LastScan, LastAscii:Byte;
    ScrollSpeed:Byte;
    Bool:Boolean;
begin
    bebex:=10;
    if (not Keyboard) then ScrollSpeed:=Data.ScrollSpeed
    else ScrollSpeed:=2;
    if (ScrollSpeed = 1) then Border:=1 else Border:=0;
    IBegPixel:=IBeg shl XCellShl;
    JBegPixel:=JBeg shl YCellShl;
    CursorOff;
    BlockMouse:=False;
    bebex:=11; bebey:=0;
    repeat
       bebex:=1001;
       if (bebey<65535) then bebey:=bebey+1;
       if ((XMemBeg > (IMem2*32+64)) or (YMemBeg > (JMem2*32+64))) then
          BlockMouse:=False; { zkusebni zarazka }
       case (Scroll) of
         1  : begin  { vlevo nahoru }
                bebex:=1002;
                if ((JBeg > Border) and (IBeg > Border))
                then begin
                   bebex:=2000;
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   IPom:=IBeg; JPom:=JBeg;
                   Dec(IBegPixel,128 shr ScrollSpeed);
                   Dec(JBegPixel,128 shr ScrollSpeed);
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   bebex:=2002;
                   if (IBeg <> IPom) or (JBeg <> JPom) then begin
                     if (IMemPom > IMem1) and (JMemPom > JMem1)
                     then begin
                        bebex:=2003;
                        if (IBeg <> IPom) then begin
                          Dec(IMemPom,Border+1);
                          Dec(XMemBeg,(Border+1) shl XCellShl);
                        end;
                        if (JBeg <> JPom) then begin
                          Dec(JMemPom,Border+1);
                          Dec(YMemBeg,(Border+1) shl YCellShl);
                        end;
                        bebex:=2004;
                        Draw_map_frame(IBeg,IBeg+Border,JBeg,JBeg+JScreenSize{-1});
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+Border);{}
                     end else begin
                        bebex:=2005;
                        XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                        YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                        IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                        bebex:=2006;
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                     bebex:=2007;
                     RedrawRadarFrame(IPom,JPom);
                   end else begin
                     if (IMemPom > IMem1) and (JMemPom > JMem1)
                     then begin
                        bebex:=2008;
                        Draw_map_frame(IBeg,IBeg+Border,JBeg,JBeg+JScreenSize{-1});
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+Border);{}
                     end else begin
                        bebex:=2009;
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                   end;
                   bebex:=2010;
                   XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                   YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                   bebex:=2011;
                   GraphQueue.Work;
                   bebex:=2012;
                   Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                               XOffset, YOffset);
                end;
            end;
         2  : begin  { nahoru }
                bebex:=1003;
                if (JBeg > Border) then begin
                   bebex:=100;
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   IPom:=IBeg; JPom:=JBeg;
                   Dec(JBegPixel,128 shr ScrollSpeed);
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   bebex:=101;
                   if (JBeg <> JPom) then begin
                     bebex:=201;
                     if (JMemPom > JMem1)
                     then begin
                       bebex:=202;
                       Dec(JMemPom,(Border+1));
                       Dec(YMemBeg,(Border+1) shl YCellShl);
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+Border);{}
                     end else begin
                       bebex:=203;
                       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                     bebex:=204;
                     RedrawRadarFrame(IPom,JPom);
                   end else begin
                     bebex:=205;
                     if (JMemPom > JMem1)
                     then begin
                       bebex:=206;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+Border);{}
                     end else begin
                       bebex:=207;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                   end;
                   bebex:=102;
                   XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                   YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                   bebex:=103;
                   GraphQueue.Work;
                   bebex:=104;
                   Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                               XOffset, YOffset);
                end;
             end;
         4  : begin  { vpravo nahoru }
                bebex:=1004;
                if ((JBeg > Border) and ((IBeg+IScreenSize) <= (IMax-Border-1)))
                then begin
                   bebex:=2013;
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   IPom:=IBeg; JPom:=JBeg;
                   Inc(IBegPixel,128 shr ScrollSpeed);
                   Dec(JBegPixel,128 shr ScrollSpeed);
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   bebex:=2014;
                   if (IBeg <> IPom) or (JBeg <> JPom) then begin
                     if (IMemPom < IMem2) and (JMemPom > JMem1)
                     then begin
                        bebex:=2015;
                        if (IBeg <> IPom) then begin
                          Inc(IMemPom,(Border+1));
                          Inc(XMemBeg,(Border+1) shl XCellShl);
                        end;
                        if (JBeg <> JPom) then begin
                          Dec(JMemPom,(Border+1));
                          Dec(YMemBeg,(Border+1) shl YCellShl);
                        end;
                        bebex:=2016;
                        Draw_map_frame(IBeg+IScreenSize-(Border+1),IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+Border);{}
                     end else begin
                        bebex:=2017;
                        XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                        YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                        IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                        bebex:=2018;
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                     bebex:=2019;
                     RedrawRadarFrame(IPom,JPom);
                   end else begin
                     bebex:=2020;
                     if (IMemPom < IMem2) and (JMemPom > JMem1)
                     then begin
                        bebex:=2021;
                        Draw_map_frame(IBeg+IScreenSize-(Border+1),IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+Border);{}
                     end else begin
                        bebex:=2022;
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                   end;
                   bebex:=2023;
                   XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                   YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                   bebex:=2024;
                   GraphQueue.Work;
                   bebex:=2025;
                   Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                               XOffset, YOffset);
                end;
              end;
         8  : begin  { vpravo }
                 bebex:=1005;
                 if ((IBeg+IScreenSize) <= (IMax-Border)) then begin
                   bebex:=2026;
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   IPom:=IBeg; JPom:=JBeg;
                   Inc(IBegPixel,128 shr ScrollSpeed);
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   bebex:=2027;
                   if (IBeg <> IPom) then begin
                     if (IMemPom < IMem2)
                     then begin
                       bebex:=2028;
                       Inc(IMemPom,(Border+1));
                       Inc(XMemBeg,(Border+1) shl XCellShl);
                       bebex:=2029;
                       Draw_map_frame(IBeg+IScreenSize-(Border+1),IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end else begin
                       bebex:=2030;
                       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                       bebex:=2031;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                     bebex:=2032;
                     RedrawRadarFrame(IPom,JPom);
                   end else begin
                     bebex:=2033;
                     if (IMemPom < IMem2)
                     then begin
                       bebex:=2034;
                       Draw_map_frame(IBeg+IScreenSize-(Border+1),IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end else begin
                       bebex:=2035;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                   end;
                   bebex:=2036;
                   XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                   YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                   bebex:=2037;
                   GraphQueue.Work;
                   bebex:=2038;
                   Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                                XOffset, YOffset);
                 end;
              end;
         16 : begin  { vpravo dolu }
               bebex:=1006;
               if (((JBeg+JScreenSize) <= (JMax-Border)) and
                   ((IBeg+IScreenSize) <= (IMax-Border)))
               then begin
                  bebex:=2039;
                  IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                  IPom:=IBeg; JPom:=JBeg;
                  Inc(IBegPixel,128 shr ScrollSpeed);
                  Inc(JBegPixel,128 shr ScrollSpeed);
                  IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                  bebex:=2040;
                  if (IBeg <> IPom) or (JBeg <> JPom) then begin
                    if (IMemPom < IMem2) and (JMemPom < JMem2)
                    then begin
                      bebex:=2041;
                      if (IBeg <> IPom) then begin
                        Inc(IMemPom,(Border+1));
                        Inc(XMemBeg,(Border+1) shl XCellShl);
                      end;
                      if (JBeg <> JPom) then begin
                        Inc(JMemPom,(Border+1));
                        Inc(YMemBeg,(Border+1) shl YCellShl);
                      end;
                      bebex:=2042;
                      Draw_map_frame(IBeg+IScreenSize-(Border+1),IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                      Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg+JScreenSize-(Border+1),JBeg+JScreenSize{-1});{}
                    end else begin
                      bebex:=2043;
                      XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                      YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                      IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                      bebex:=2044;
                      Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                    end;
                    bebex:=2045;
                    RedrawRadarFrame(IPom,JPom);
                  end else begin
                    if (IMemPom < IMem2) and (JMemPom < JMem2)
                    then begin
                      bebex:=2046;
                      Draw_map_frame(IBeg+IScreenSize-(Border+1),IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                      Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg+JScreenSize-(Border+1),JBeg+JScreenSize{-1});{}
                    end else begin
                      bebex:=2047;
                      Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                    end;
                  end;
                  bebex:=2048;
                  XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                  YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                  bebex:=2049;
                  GraphQueue.Work;
                  bebex:=2050;
                  Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                              XOffset, YOffset);
               end;
              end;
         32 : begin  { dolu }
                bebex:=1007;
                if ((JBeg + JScreenSize) <= (JMax-Border)) then begin
                   bebex:=2051;
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   IPom:=IBeg; JPom:=JBeg;
                   Inc(JBegPixel,128 shr ScrollSpeed);
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   bebex:=2052;
                   if (JBeg <> JPom) then begin
                     if (JMemPom < JMem2)
                     then begin
                       bebex:=2053;
                       Inc(JMemPom,(Border+1));
                       Inc(YMemBeg,(Border+1) shl YCellShl);
                       bebex:=2054;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg+JScreenSize-(Border+1),JBeg+JScreenSize{-1});{}
                     end else begin
                       bebex:=2055;
                       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                       bebex:=2056;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                     bebex:=2057;
                     RedrawRadarFrame(IPom,JPom);
                   end else begin
                     bebex:=2058;
                     if (JMemPom < JMem2)
                     then begin
                       bebex:=2059;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg+JScreenSize-(Border+1),JBeg+JScreenSize{-1});{}
                     end else begin
                       bebex:=2060;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                   end;
                   bebex:=2061;
                   XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                   YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                   bebex:=2062;
                   GraphQueue.Work;
                   bebex:=2063;
                   Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                               XOffset, YOffset);
                end;
              end;
         64 : begin  { vlevo dolu }
                bebex:=1008;
                if (((JBeg+JScreenSize) <= (JMax-Border)) and (IBeg > Border))
                then begin
                   bebex:=2064;
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   IPom:=IBeg; JPom:=JBeg;
                   Dec(IBegPixel,128 shr ScrollSpeed);
                   Inc(JBegPixel,128 shr ScrollSpeed);
                   IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                   bebex:=2065;
                   if (IBeg <> IPom) or (JBeg <> JPom) then begin
                     bebex:=2066;
                     if (IMemPom > IMem1) and (JMemPom < JMem2)
                     then begin
                        if (IBeg <> IPom) then begin
                          Dec(IMemPom,(Border+1));
                          Dec(XMemBeg,(Border+1) shl XCellShl);
                        end;
                        if (JBeg <> JPom) then begin
                          Inc(JMemPom,(Border+1));
                          Inc(YMemBeg,(Border+1) shl YCellShl);
                        end;
                        bebex:=2067;
                        Draw_map_frame(IBeg,IBeg+Border,JBeg,JBeg+JScreenSize{-1});
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg+JScreenSize-(Border+1),JBeg+JScreenSize{-1});{}
                     end else begin
                        XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                        YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                        IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                        bebex:=2068;
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                     bebex:=2069;
                     RedrawRadarFrame(IPom,JPom);
                   end else begin
                     if (IMemPom > IMem1) and (JMemPom < JMem2)
                     then begin
                        bebex:=2070;
                        Draw_map_frame(IBeg,IBeg+Border,JBeg,JBeg+JScreenSize{-1});
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg+JScreenSize-(Border+1),JBeg+JScreenSize{-1});{}
                     end else begin
                        bebex:=2071;
                        Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                     end;
                   end;
                   bebex:=2072;
                   XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                   YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                   bebex:=2073;
                   GraphQueue.Work;
                   bebex:=2074;
                   Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                               XOffset, YOffset);
                end;
              end;
         128: begin  { vlevo }
               bebex:=1009;
               if (IBeg > Border) then begin
                  bebex:=2075;
                  IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                  IPom:=IBeg; JPom:=JBeg;
                  Dec(IBegPixel,128 shr ScrollSpeed);
                  IBeg:=IBegPixel shr XCellShl; JBeg:=JBegPixel shr YCellShl;
                  bebex:=2076;
                  if (IBeg <> IPom) then begin
                    if (IMemPom > IMem1)
                    then begin
                       Dec(IMemPom,(Border+1));
                       Dec(XMemBeg,(Border+1) shl XCellShl);
                       bebex:=2077;
                       Draw_map_frame(IBeg,IBeg+Border,JBeg,JBeg+JScreenSize{-1});{}
                    end else begin
                       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
                       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
                       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
                       bebex:=2078;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                    end;
                    bebex:=2079;
                    RedrawRadarFrame(IPom,JPom);
                  end else begin
                    if (IMemPom > IMem1)
                    then begin
                       bebex:=2080;
                       Draw_map_frame(IBeg,IBeg+Border,JBeg,JBeg+JScreenSize{-1});{}
                    end else begin
                       bebex:=2081;
                       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
                    end;
                  end;
                  bebex:=2082;
                  XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
                  YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
                  bebex:=2083;
                  GraphQueue.Work;
                  bebex:=2084;
                  Draw_screen(IBegPixel shr XCellShl,JBegPixel shr YCellShl,
                              XOffset, YOffset);
               end;
              end;
       end;
       {Pom:=Scroll;{}
       bebex:=105;
       if (ScrollSpeed = 7) then Delay(1);
       { tvrda prodleva pro superrychle computery }
       ReadKeys(PressedKey);
       if ((PressedKey = $48) or (PressedKey = $50) or (PressedKey = $4d) or
           (PressedKey = $4b) or (PressedKey = $47) or (PressedKey = $49) or
           (PressedKey = $51) or (PressedKey = $4f)) then begin
          Pomocn:=0; Ascii:=0;
          repeat
             LastScan:=Pomocn; LastAscii:=Ascii;
             Ascii:=ReadKeys(Pomocn);
          until (Pomocn = 0); {J:=2;{}
          if (LastScan <> 0) then asm
            mov Ah,05h
            mov Ch,LastScan
            mov Cl,LastAscii
            int 16h
          end;
          case (PressedKey) of
             $47 : Scroll:=1;
             $48 : Scroll:=2;
             $49 : Scroll:=4;
             $4d : Scroll:=8;
             $51 : Scroll:=16;
             $50 : Scroll:=32;
             $4f : Scroll:=64;
             $4b : Scroll:=128;
          end;
       end else begin
          bebex:=107;
          GetCursorPos(X,Y,J);
          if (not War2Scroll) then Pomocna(X,Y,Scroll)
          else Bool:=Pomocna2(X,Y,Scroll);
       end;
       if (RealTimeScroll) then J:=0;{}
       {if (Pom <> Scroll) then Change:=True else Change:=False;{}
       bebex:=108;
    until (J <> 2) and (not War2Scroll) or (War2Scroll) and (not Bool);
    bebex:=12;
    IPom:=IBeg; JPom:=JBeg;
    XOffset:=IBegPixel - ((IBegPixel shr XCellShl) shl XCellShl);
    YOffset:=JBegPixel - ((JBegPixel shr YCellShl) shl YCellShl);
    bebex:=13;
    if (XOffset <> 0) or (YOffset <> 0) then begin
      { nyni se provede " dorolovani" }
     repeat
       case (Scroll) of
         1   : begin  { vlevo nahoru }
                  if ((XOffset>0) and (XOffset<32)) then Dec(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Dec(YOffset,128 shr ScrollSpeed);
               end;
         2   : begin  { nahoru }
                  if ((XOffset>0) and (XOffset<32)) then Dec(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Dec(YOffset,128 shr ScrollSpeed);
               end;
         4   : begin  { vpravo nahoru }
                  if ((XOffset>0) and (XOffset<32)) then Inc(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Dec(YOffset,128 shr ScrollSpeed);
               end;
         8   : begin  { vpravo }
                  if ((XOffset>0) and (XOffset<32)) then Inc(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Dec(YOffset,128 shr ScrollSpeed);
               end;
         16  : begin  { vpravo dolu }
                  if ((XOffset>0) and (XOffset<32)) then Inc(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Inc(YOffset,128 shr ScrollSpeed);
               end;
         32  : begin  { dolu }
                  if ((XOffset>0) and (XOffset<32)) then Inc(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Inc(YOffset,128 shr ScrollSpeed);
               end;
         64  : begin  { vlevo dolu }
                  if ((XOffset>0) and (XOffset<32)) then Dec(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Inc(YOffset,128 shr ScrollSpeed);
               end;
         128 : begin  { vlevo }
                  if ((XOffset>0) and (XOffset<32)) then Dec(XOffset,128 shr ScrollSpeed);
                  if ((YOffset>0) and (YOffset<32)) then Dec(YOffset,128 shr ScrollSpeed);
               end;
      end;
      bebex:=14;
      GraphQueue.Work;
      bebex:=15;
      Draw_screen(IBeg,JBeg,XOffset,YOffset);
      bebex:=16;
     until (((XOffset = 0) or (XOffset =32)) and
             ((YOffset = 0) or (YOffset =32)));
     bebex:=17;
     case (Scroll) of
         1   : begin  { vlevo nahoru }
                  if (XOffset <> 32) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset <> 32) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         2   : begin  { nahoru }
                  if (XOffset <> 32) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset <> 32) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         4   : begin  { vpravo nahoru }
                  if (XOffset = 0) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset <> 32) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         8   : begin  { vpravo }
                  if (XOffset = 0) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset <> 32) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         16  : begin  { vpravo dolu }
                  if (XOffset = 0) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset = 0) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         32  : begin  { dolu }
                  if (XOffset = 0) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset = 0) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         64  : begin  { vlevo dolu }
                  if (XOffset <> 32) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset = 0) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
         128 : begin  { vlevo }
                  if (XOffset <> 32) then IBeg:=IBegPixel shr XCellShl
                  else begin
                    IBeg:=IBegPixel shr XCellShl + 1;
                    Inc(XMemBeg,(Border+1) shl XCellShl);
                  end;
                  if (YOffset <> 32) then JBeg:=JBegPixel shr YCellShl
                  else begin
                    JBeg:=JBegPixel shr YCellShl + 1;
                    Inc(YMemBeg,(Border+1) shl YCellShl);
                  end;
               end;
     end;
     bebex:=18;
     { osetreni "dojezdu" }
     if ((IMemPom >= IMem2) or (JMemPom >= JMem2) or
         (IMemPom <= IMem1) or (JMemPom <= JMem1)) then begin
       bebex:=19;
       XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
       YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
       IMemPom:=IScreenSize; JMemPom:=JScreenSize;
       Draw_map_frame(IBeg,IBeg+IScreenSize{-1},JBeg,JBeg+JScreenSize{-1});
       GraphQueue.Work;
     end;
     IMemPom:=(XMemBeg - 64) shr XCellShl;
     JMemPom:=(YMemBeg - 64) shr YCellShl;

     RedrawRadarFrame(IPom,JPom);
    end;
    bebex:=20;
    if (not RealTimeScroll) then ButtonClick:=0 else GraphQueue.Clear;
    LastScroll:=True;
    CursorOn;
end;

{ ***** }
procedure Mouse_keyboard_manager;
{ provadi nacitani klavesnice, mysi a provadi z toho vyplyvajici akce
}
label _Scroll, Konec;
var I,J,X,Y,K,L,M,N,IPom, JPom, Butt:Word;
    Buttn, Scroll, Slots, Pomocn, ADefSlots:Byte;
    Pom, Radar, Validity, Load:Boolean;
    Name:String[20];
    Ret:String;
    Race, PomLevel,R,G,B:Byte;
    ProdType:Word;
    IAirp, JAirp:Word;
    ADefRange:Word;
    PomUnit, PomGroundEnemyUnit, PomAirEnemyUnit:PUnit;
    Id:Byte;
    Vis:Boolean;
begin
   ActiveScrolling:=False; bebex:=0;
   { vraceni tlacitek do puvodniho stavu, byla-li stisknuta }
   if ((StopPressed = 1) and Active(Stop)) then begin
      CursorOff;
      Release(Stop);
      CursorOn;
      StopPressed:=0;
   end else if (StopPressed <> 0) then Dec(StopPressed);
   if ((PatrolPressed = 1) and Active(Patrol)) then begin
      CursorOff;
      Release(Patrol);
      CursorOn;
      PatrolPressed:=0;
   end else if (PatrolPressed <> 0) then Dec(PatrolPressed);
   if ((NalozitPressed = 1) and Active(Nalozit)) then begin
      CursorOff;
      Release(Nalozit);
      CursorOn;
      NalozitPressed:=0;
   end else if (NalozitPressed <> 0) then Dec(NalozitPressed);
   if ((VylozitPressed = 1) and Active(Vylozit)) then begin
      CursorOff;
      Release(Vylozit);
      CursorOn;
      VylozitPressed:=0;
   end else if (VylozitPressed <> 0) then Dec(VylozitPressed);
   if ((RozlozitPressed = 1) and Active(Rozlozit)) then begin
      CursorOff;
      Release(Rozlozit);
      CursorOn;
      RozlozitPressed:=0;
   end else if (RozlozitPressed <> 0) then Dec(RozlozitPressed);
   if ((OpravitPressed = 1) and Active(Opravit)) then begin
      CursorOff;
      Release(Opravit);
      CursorOn;
      OpravitPressed:=0;
   end else if (OpravitPressed <> 0) then Dec(OpravitPressed);
   if ((ZvednoutMoralkuPressed = 1) and Active(ZvednoutMoralku)) then begin
      CursorOff;
      Release(ZvednoutMoralku);
      CursorOn;
      ZvednoutMoralkuPressed:=0;
   end else if (ZvednoutMoralkuPressed <> 0) then Dec(ZvednoutMoralkuPressed);
   if ((MenuPressed) and Active(MenuButton)) then begin
      CursorOff;
      Release(MenuButton);
      CursorOn;
      MenuPressed:=False;
   end;
   if ((RadarModButtonPressed) and Active(RadarModButton)) then begin
      CursorOff;
      Release(RadarModButton);
      CursorOn;
      RadarModButtonPressed:=False;
   end;
   if (SellButtonPressed and Active(SellButton)) then begin
      CursorOff;
      Release(SellButton);
      CursorOn;
      SellButtonPressed:=False;
   end;
   if ((StopGamePressed) and Active(StopButton)) then begin
      CursorOff;
      Release(StopButton);
      CursorOn;
      StopGamePressed:=False;
   end;

   if (ReadMouse(I,J,X,Y,Butt,Buttn,Scroll,ADefSlots,Slots,Radar,Validity) and
       (not Grouping)) then begin
   { osetreni stisku tlacitka mysi }
     if (Scroll <> 0) then GoTo _Scroll;
     if (not Validity) then GoTo Konec;
     if (Radar) then begin
     { stisknuto bylo na radaru }
        bebex:=1;
        if ((I >= IScreenSizeShr2) and (J >= JScreenSizeShr2)) then begin
        { kontrola leveho horniho rohu }
          I:=I-IScreenSizeShr2; J:=J-JScreenSizeShr2;
        end else begin
          if (I < IScreenSizeShr2) then I:=0
          else I:=I-IScreenSizeShr2;
          if (J < JScreenSizeShr2) then J:=0
          else J:=J-JScreenSizeShr2;
        end;
        { nyni kontroly konce obrazovky }
        if ((I+IScreenSize) > IMax) then begin
           I:=IMax - IScreenSize + 1;
        end;
        if ((J+JScreenSize) > JMax) then begin
           J:=JMax - JScreenSize + 1;
        end;
        {if (J mod 2 = 1) then Dec(J);
        if (I mod 2 = 1) then Dec(I);
        { nyni se obrazovka precvakne }
        IMemPom:=IScreenSize; JMemPom:=JScreenSize;
        XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
        YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
        IPom:=IBeg; JPom:=JBeg;
        JBeg:=J; IBeg:=I;
        Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
        CursorOff;
        GraphQueue.Work;
        Draw_screen(IBeg,JBeg,0,0);
        RedrawRadarFrame(IPom,JPom);
        CursorOn;
        {Mouse.Button:=0;{}
     end else begin { if (Radar) then .. }
        if (Slots <> 255) then with (GroupsBck[Slots]) do begin
        { SLOTY }
          bebex:=2;
          Button:=0; ButtonClick:=0;
          PreparePlaySound(6,0,0,0); { zvuk clicknuti }
      {3} if ((Typ = 0) and (_unit <> Nil) and (ActiveGroup < 254) and
              (_unit^.Group = ActiveGroup) and (Butt and 1 = 1) and
              (Groups[ActiveGroup].Count > 1)) then begin
           { na levem panelu byla ze skupiny navolena jednotka; tato se
             zvoli samostatne }
             Butt:=1;
             Click_or_move_group(_unit^.IPos,_unit^.JPos,Butt);
          end else
            if ((Typ = 0) and (_unit <> Nil) and (ActiveGroup < 254) and
                (_unit^.Group = ActiveGroup) and (Butt and 2 = 2) and
                (Groups[ActiveGroup].Count > 1)) then begin
             { na levem panelu byla ze skupiny naclicknuta jednotka; tato se
               zvoli "odvoli" ze skupiny }
                Butt:=2; Id:=ClickLevel;
                if (_unit^.TargetType = 3) then ClickLevel:=1 else ClickLevel:=0;
                Click_or_move_group(_unit^.IPos,_unit^.JPos,Butt);
                ClickLevel:=Id;
            end else begin {3}
             if ((Typ = 0) and (_unit <> Nil) and (ActiveGroup < 254) and
                 (Slots > 0) and (Groups[ActiveGroup].Count = 1) and
                 (Groups[ActiveGroup].Un[0] <> Nil) and
                 (Groups[ActiveGroup].Un[0]^.UnitsInsideNum > 0)) then
        {2}  with (Groups[ActiveGroup].Un[0]^) do begin
             { na levem panelu byla navolena jednotka, nachazejici se
               uvnitr jine jednotky (ktera musi byt 1. v aktivni skupine) }
          {1}  {if (UnitsInside[_unit^.GroupOrder-1] = _unit^.Index) then begin
               { ano, jednotka ve slotu je skutecne obsazena v
                 "naclicknute jednotce"; pozn. GroupOrder znaci v podstate
                 cislo obsazeneho slotu
               }
                  if (_unit^.Selected) then begin
                  { jednotka je jiz zvolena - "odselectuj ji pro vylozeni"}
                     _unit^.Selected:=False;
                     Select_slot(Slots,False);
                     LeftButton:=1;
                  end else begin
                  { "selectuj jednotku pro vylozeni"}
                     _unit^.Selected:=True;
                     Select_slot(Slots,True);
                     LeftButton:=1;
                  end;
              { end; {1}
             end else begin {2}
             { testovani vyroby }
                if ((Groups[ActiveGroup].Building <> Nil) and
                    (Slots <> 0)) then with (Groups[ActiveGroup].Building^) do begin
                { zkus vyrabet! }
                    if (Production_type <> 0) then begin
                    { neco se jiz vyrabi - prave tlacitko zastavuje }
                      ProdType:=ProductType+1{};
                      if (ProdType = Production_type) then
                         if (Building_types[BuildingType].ProductionType = 0) then
                         with (Unit_types[Building_types[BuildingType].Production[ProdType-1],Races[Race].Ally]) do begin
                         { kliknuto na vyrabejici se jednotku - zastav vyrobu }
                            if (Butt and 2 = 2) then begin
                               Dec(Production_count);
                               Draw_building_production(Groups[ActiveGroup].Building);
                               if (Production_count = 0) then begin
                                  Production_phase:=0;
                                  Production_percentage:=0;
                                  Update_building_production(Groups[ActiveGroup].Building,Production_slot);
                                  Production_type:=0; Production_slot:=0;
                                  Inc(Races[MyRace].Building_credits,BP);
                                  Inc(Races[MyRace].Plastic_credits,PL);
                                  Inc(Races[MyRace].Electric_energy,EE);
                                  Inc(Races[MyRace].Battle_experience,EX);
                                  if (BP <> 0) then UpdateBP:=True;
                                  if (PL <> 0) then UpdatePL:=True;
                                  if (EE <> 0) then UpdateEEEnergy:=True;
                                  if (EX <> 0) then UpdateEXP:=True;
                                  OutBigMsg(12,'VjROBA JEDNOTKY ZASTAVENA');
                                  RightButton:=GetAccurateDelay(2) shl GameTimming;
                               end;
                            end else
                              if ((Butt and 1 = 1) and (Production_count < 10))
                              then begin
                                Inc(Production_count);
                                Draw_building_production(Groups[ActiveGroup].Building);
                              end;
                         end else
                         if (Building_types[BuildingType].ProductionType = 1) then
                         with (Building_types[Building_types[BuildingType].Production[ProdType-1]]) do begin
                         { kliknuto na vyrabejici se budovu - zastav vyrobu }
                            if (Butt and 2 = 2) then begin
                                Production_phase:=0;
                                Production_percentage:=0;
                                Update_building_production(Groups[ActiveGroup].Building,Production_slot);
                                Production_type:=0; Production_slot:=0;
                                Inc(Races[MyRace].Building_credits,BP);
                                Inc(Races[MyRace].Plastic_credits,PL);
                                Inc(Races[MyRace].Electric_energy,EE);
                                Inc(Races[MyRace].Battle_experience,EX);
                                if (BP <> 0) then UpdateBP:=True;
                                if (PL <> 0) then UpdatePL:=True;
                                if (EE <> 0) then UpdateEEEnergy:=True;
                                if (EX <> 0) then UpdateEXP:=True;
                                OutBigMsg(12,'VjROBA BUDOVY ZASTAVENA');
                                LeftButton:=GetAccurateDelay(2) shl GameTimming;
                            end;
                         end else
                           if ((Building_types[BuildingType].ProductionType = 2) and
                               (Typ = 3))
                           then with (Races[Race]) do begin
                           { kliknuto na vyrabejici se plasty - zastav vyrobu }
                               Production_phase:=0;
                               Production_percentage:=0;
                               Production_type:=0; Production_slot:=0;
                               Inc(Building_credits,PLProductionBPNeed);
                               Inc(Electric_energy,PLProductionEENeed);
                               if (Race = MyRace) then UpdateBP:=True;
                               if (Race = MyRace) then UpdateEEEnergy:=True;
                               OutBigMsg(12,'VjROBA PLASTi ZASTAVENA');
                               LeftButton:=GetAccurateDelay(2) shl GameTimming;
                               Click_on_group(ActiveGroup); { vymaz stop }
                           end;
                    end else if ((Production_type = 0) and (Butt and 1 = 1)) then begin
                    { rozjed danou vyrobu (staci-li material) }
                       ProdType:=ProductType+1{};
                       if (Building_types[BuildingType].ProductionType = 0)
                       then with (Unit_types[Building_types[BuildingType].Production[ProdType-1],Races[Race].Ally])
                       do begin
                       { vyroba jednotek }
                           if (((BP <= Races[MyRace].Building_credits) or (BP = 0)) and
                               ((PL <= Races[MyRace].Plastic_credits) or (PL = 0)) and
                               ((EE <= Races[MyRace].Electric_energy) or (EE = 0)) and
                               ((EX <= Races[MyRace].Battle_experience) or (Ex = 0))) then begin
                           { material staci! }
                              if (UnitLevel = 3) and (SpecAirLevel = 0) and
                                 (Races[MyRace].I_free_airport_space_max_index = 255)
                              then begin
                              { chybi letiste pro vzdusnou jednotku }
                                OutBigMsg(9,'NELZE VYRaBdT -NEDOSTATEK LETIgTNe KAPACITY');
                              end else begin
                                Inc(Production_count);
                                Dec(Races[MyRace].Building_credits,BP);
                                Dec(Races[MyRace].Plastic_credits,PL);
                                Dec(Races[MyRace].Electric_energy,EE);
                                Dec(Races[MyRace].Battle_experience,EX);
                                if (BP <> 0) then UpdateBP:=True;
                                if (PL <> 0) then UpdatePL:=True;
                                if (EE <> 0) then UpdateEEEnergy:=True;
                                if (EX <> 0) then UpdateEXP:=True;
                                Production_slot:=Slots;
                                Production_percentage:=0;
                                Production_type:=ProdType;
                                Production_phase:=0;
                                Draw_building_production(Groups[ActiveGroup].Building);
                                LeftButton:=GetAccurateDelay(2) shl GameTimming;
                              end;
                           end else begin
                           { nedostatek materialu }
                              OutBigMsg(5,'NELZE VYRaBdT - NEDOSTATEK MATERIaLU');
                           end;
                       end else
                       if (Building_types[BuildingType].ProductionType = 1) then
                       with (Building_types[Building_types[BuildingType].Production[ProdType-1]]) do begin
                       { vyroba budov }
                           if (((BP <= Races[MyRace].Building_credits) or (BP = 0)) and
                               ((PL <= Races[MyRace].Plastic_credits) or (PL = 0)) and
                               ((EE <= Races[MyRace].Electric_energy) or (EE = 0)) and
                               ((EX <= Races[MyRace].Battle_experience) or (EX = 0))) then begin
                           { material staci! }
                              Dec(Races[MyRace].Building_credits,BP);
                              Dec(Races[MyRace].Plastic_credits,PL);
                              Dec(Races[MyRace].Electric_energy,EE);
                              Dec(Races[MyRace].Battle_experience,EX);
                              if (BP <> 0) then UpdateBP:=True;
                              if (PL <> 0) then UpdatePL:=True;
                              if (EE <> 0) then UpdateEEEnergy:=True;
                              if (EX <> 0) then UpdateEXP:=True;
                              Production_slot:=Slots;
                              Production_percentage:=0;
                              Production_type:=ProdType;
                              Production_phase:=0;
                              LeftButton:=GetAccurateDelay(2) shl GameTimming;
                           end else begin
                           { nedostatek materialu }
                              OutBigMsg(5,'NELZE VYRaBdT - NEDOSTATEK MATERIaLU');
                           end;
                       end else
                         if ((Building_types[BuildingType].ProductionType = 2) and
                             (Typ = 2))
                         then with (Races[Race]) do begin
                         { produkce plastu }
                            if ((PLProductionBPNeed > Building_credits) or
                                (PLProductionEENeed > Electric_energy)) then begin
                            { nemozno produkovat - nedostatek energie }
                               Production_phase:=0;
                               Production_percentage:=0;
                               Production_type:=0;
                               if (Race = MyRace) then
                                  OutBigMsg(5,'NELZE VYRaBdT - NEDOSTATEK MATERIaLU');
                               Click_on_group(ActiveGroup); { vymaz stop }
                            end else begin
                             { lze produkovat dale }
                               Dec(Building_credits,PLProductionBPNeed);
                               Dec(Electric_energy,PLProductionEENeed);
                               if (Race = MyRace) then UpdateBP:=True;
                               if (Race = MyRace) then UpdateEEEnergy:=True;
                               Production_slot:=Slots;
                               Production_percentage:=0;
                               Production_type:=1;
                               Click_on_group(ActiveGroup); { nastav stop }
                            end;
                         end;
                    end;
                end;
             end; {2}
            end; {3}
           {Mouse.Button:=0;{}
        end else begin { if (Slots <> 0) then ... else }
         if (ADefSlots < 4) then begin
            bebex:=3;
            PreparePlaySound(6,0,0,0); { zvuk clicknuti }
            SetActiveDefenceRangeSlotsActivity(ADefSlots);
            case (ADefSlots) of
              0 : ADefRange:=ADRng1;
              1 : ADefRange:=ADRng2;
              2 : ADefRange:=ADRng3;
              3 : ADefRange:=ADRng4;
            end;
            with (Groups[ActiveGroup]) do begin
              for K:=0 to MaxGroupUnits-1 do
                if (Un[K] <> Nil) then with (Un[K]^) do begin
                  ActiveDefenceRange:=ADefRange;
                end;
            end;
            {Mouse.Button:=0;{}
         end else if (ADefSlots = 255) then begin
          if (Scroll <> 0) then begin
          { bude se rolovat }
_Scroll:
             if (GlobalStep < 100) then begin
               ActiveScrolling:=True;
               bebex:=4;
               if (Buttn <> 0) then _Scrolling(Scroll,True)
               else _Scrolling(Scroll,False);
             end;
          end else
           if (Buttn <> 0) then begin
           { osetreni stisku grafickeho tlacitka na obrazovce }
             bebex:=5;
             case (Buttn) of
               Stop : begin
                         CursorOff;
                         PushDown(Stop);
                         CursorOn;
                         StopPressed:=GetAccurateDelay(8);
                         if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                           if (Building <> Nil) then  with (Building^) do begin
                           { stop pro budovu }
                             if (Repair) then begin
                               Inc(Races[Race].RepairsAvailable,BuildingRepairCapacityNeed);
                               if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
                               DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                               {BPRepairRemainder:=0; PLRepairRemainder:=0;
                               EERepairRemainder:=0; EXRepairRemainder:=0;{}
                               RepairRemainder:=0;
                               Repair:=False;
                               if ((Race = MyRace) and
                                   (Building_types[BuildingType].ProductionType < 3) and
                                   (BuildPhase > 3) and (Group = ActiveGroup)) then begin
                               { obnov produkcni sloty }
                                  Clear_group_slots;
                                  Click_on_group(ActiveGroup);
                               end;
                             end;
                             { X vyroba X }
                             if (Production_type <> 0) then begin
                             { neco se jiz vyrabi - zrus vyrobu }
                                if (Building_types[BuildingType].ProductionType = 0) then
                                with (Unit_types[Building_types[BuildingType].Production[Production_type-1],
                                      Races[Race].Ally]) do begin
                                { vyrabejici se jednotka - zastav vyrobu }
                                   Production_count:=0;
                                   Draw_building_production(Groups[ActiveGroup].Building);
                                   Production_phase:=0;
                                   Production_percentage:=0;
                                   Update_building_production(Groups[ActiveGroup].Building,Production_slot);
                                   Production_type:=0; Production_slot:=0;
                                   Inc(Races[MyRace].Building_credits,BP);
                                   Inc(Races[MyRace].Plastic_credits,PL);
                                   Inc(Races[MyRace].Electric_energy,EE);
                                   Inc(Races[MyRace].Battle_experience,EX);
                                   if (BP <> 0) then UpdateBP:=True;
                                   if (PL <> 0) then UpdatePL:=True;
                                   if (EE <> 0) then UpdateEEEnergy:=True;
                                   if (EX <> 0) then UpdateEXP:=True;
                                   OutBigMsg(12,'VjROBA JEDNOTKY ZASTAVENA');
                                end else
                                if (Building_types[BuildingType].ProductionType = 1) then
                                with (Building_types[Building_types[BuildingType].Production[Production_type-1]])
                                do begin
                                { kliknuto na vyrabejici se budovu - zastav vyrobu }
                                  Production_count:=0;
                                  Production_phase:=0;
                                  Production_percentage:=0;
                                  Update_building_production(Groups[ActiveGroup].Building,Production_slot);
                                  Production_type:=0; Production_slot:=0;
                                  Inc(Races[MyRace].Building_credits,BP);
                                  Inc(Races[MyRace].Plastic_credits,PL);
                                  Inc(Races[MyRace].Electric_energy,EE);
                                  Inc(Races[MyRace].Battle_experience,EX);
                                  if (BP <> 0) then UpdateBP:=True;
                                  if (PL <> 0) then UpdatePL:=True;
                                  if (EE <> 0) then UpdateEEEnergy:=True;
                                  if (EX <> 0) then UpdateEXP:=True;
                                  OutBigMsg(12,'VjROBA BUDOVY ZASTAVENA');
                                end else
                                  if (Building_types[BuildingType].ProductionType = 2)
                                  then with (Races[Race]) do begin
                                  { kliknuto na vyrabejici se plasty - zastav vyrobu }
                                      Production_phase:=0;
                                      Production_percentage:=0;
                                      Production_type:=0; Production_slot:=0;
                                      Inc(Building_credits,PLProductionBPNeed);
                                      Inc(Electric_energy,PLProductionEENeed);
                                      if (Race = MyRace) then UpdateBP:=True;
                                      if (Race = MyRace) then UpdateEEEnergy:=True;
                                      OutBigMsg(12,'VjROBA PLASTi ZASTAVENA');
                                      Click_on_group(ActiveGroup); { vymaz stop }
                                  end;
                             end;
                           end else begin
                             for K:=0 to MaxGroupUnits-1 do
                               if ((Un[K] <> Nil) and (not Un[K]^.Return_to_base))
                               then with (Un[K]^) do begin
                               { stop pro jednotku }
                                 Target:=Nil; BTarget:=Nil;
                                 if (Status > 128) then Status:=0;
                                 if ((Status = 0) and (Repair)) then begin
                                 { zrus opravu }
                                   Repair:=False;
                                   Inc(Races[Race].RepairsAvailable,UnitRepairCapacityNeed);
                                   if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
                                   DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                                   {BPRepairRemainder:=0; PLRepairRemainder:=0;
                                   EERepairRemainder:=0; EXRepairRemainder:=0;{}
                                   RepairRemainder:=0;
                                 end;
                                 WayPointUk:=255; WayPointMax:=255;{}
                                 if ((Race = MyRace) and (Group = ActiveGroup))
                                 then Click_on_unit(Un[K]);
                                 MoveStatus:=0;
                                 STOP_:=True;
                                 GoInside:=False;
                               end;
                           end;
                           if (ClickStatus <> 1) then begin
                              ClickStatus:=1;
                           end;
                           if (ActuallCursor <> NormalCursor) then
                              SetCursor(NormalCursor);
                         end;
                      end;
               Patrol : begin
                           CursorOff;
                           PushDown(Patrol);
                           {NormCursor := 2;
                           SetCursor(PatrolCursor);{}
                           CursorOn;
                           PatrolPressed:=GetAccurateDelay(2);
                           if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                             Pom:=False;
                             for K:=0 to MaxGroupUnits-1 do
                               if ((Un[K] <> Nil) and (not Un[K]^.Return_to_base))
                               then if (Un[K]^.ActiveDefence) then Pom:=True;
                             for K:=0 to MaxGroupUnits-1 do
                               if ((Un[K] <> Nil) and (not Un[K]^.Return_to_base))
                               then with (Un[K]^) do begin
                                 if (Pom) then ActiveDefence:=False
                                 else ActiveDefence:=True;
                                 RequestDraw:=True;
                               end;
                           end;
                        end;
               Nalozit : begin
                            CursorOff;
                            PushDown(Nalozit);
                            SetCursor(GoInsideCursor);{}
                            NalozitPressed:=GetAccurateDelay(2);
                            if (ActiveGroup < 254) then
                               Groups[ActiveGroup].ClickStatus:=2;
                            CursorOn;
                         end;
               Vylozit : begin
                            CursorOff;
                            PushDown(Vylozit);
                            CursorOn;
                            if ((ActiveGroup < 254) and
                                (Groups[ActiveGroup].Un[0] <> Nil) and
                                (Groups[ActiveGroup].Un[0]^.Status = 0))
                            then { vylozeni nakladu }
                               UnLoad(Groups[ActiveGroup].Un[0]);
                            if (Groups[ActiveGroup].Un[0]^.UnitsInsideNum = 0)
                            then begin
                               CursorOff;
                               Release(Vylozit);
                               SetPasive(Vylozit,256);
                               CursorOn;
                            end else VylozitPressed:=GetAccurateDelay(8);
                         end;
               Rozlozit : begin
                            CursorOff;
                            PushDown(Rozlozit);
                            CursorOn;
                            RozlozitPressed:=GetAccurateDelay(8);
                            Rozloz_unit(True,Nil);
                          end;
               Opravit : begin
                            CursorOff;
                            PushDown(Opravit);
                            CursorOn;
                            OpravitPressed:=GetAccurateDelay(8);
                            RepairGroup(ActiveGroup);
                          end;
               ZvednoutMoralku : begin
                            CursorOff;
                            PushDown(ZvednoutMoralku);
                            CursorOn;
                            ZvednoutMoralkuPressed:=GetAccurateDelay(8);
                            Raise_group_morale(ActiveGroup);
                          end;
               MenuButton : begin
                               CursorOff;
                               PushDown(MenuButton);
                               CursorOn;
                               MenuPressed:=True;
                               MenuActive:=True;
                            end;
               RadarModButton : begin
                               CursorOff;
                               if (BuildRadarMod) then BuildRadarMod:=False
                               else BuildRadarMod:=True; { Tab }
                               DrawRadar;
                               PushDown(RadarModButton);
                               CursorOn;
                               RadarModButtonPressed:=True;
                            end;
               SellButton : begin
                               CursorOff;
                               SellActiveGroup;{}
                               PushDown(SellButton);
                               CursorOn;
                               SellButtonPressed:=True;
                            end;
               StopButton : begin
                                 StopGamePressed:=True;
                                 if (not GameStopped) then begin
                                    if (GameStopCount > 0) then begin
                                      Dec(GameStopCount);
                                      GameStopCountTimmer:=0;
                                      CursorOff;
                                      ButtonText(StopButton,15,'HRA');
                                      PushDown(StopButton);
                                      GameStopped:=True;
                                      OutBigMsg(255,'# HRA POZASTAVENA #');
                                      CursorOn;
                                    end;
                                 end else begin
                                    CursorOff;
                                    if (GameStopCount = 0) then begin
                                      ButtonText(StopButton,15,'');
                                      Release(StopButton);
                                      SetPasive(StopButton,256);
                                    end else begin
                                      Str(GameStopCount,Ret);
                                      ButtonText(StopButton,15,'('+Ret+')');
                                      PushDown(StopButton);
                                    end;
                                    GameStopped:=False;
                                    OutBigMsg(255,'! HRA Bdke !');
                                    CursorOn;
                                 end;
                            end;

             end;
             {Mouse.Button:=0;{}
           end else begin
           { bylo clicknuto nekam na pracovni obrazovku }
             with (Map^[I,J]) do begin
               if (Butt = 16) and (GlobalStep < 100){} then begin
               { grouping }
                 if ((not Grouping) and (I < 65535) and (J < 65535)) then begin
                    bebex:=8;
                    IGroup:=I; XGroup:=X;
                    JGroup:=J; YGroup:=Y;
                    SetCursor(GroupingCursor);
                    XP:=X+1; YP:=Y+1;
                    Grouping:=True;
                    DrawXORFRame:=True;
                    CursorOff;
                    XORFrame(XGroup,YGroup,XP,YP,XorColor);{}
                    CursorOn;{}
                    SetCursorRange(XScreenBeg,YScreenBeg,XScreenEnd,YScreenEnd);
                 end;
               end; { (Butt = 16) then begin }

               if ((Butt <> 0) and (not Grouping) and (not SHIFT)
                    {and (GlobalStep < 100){}) then begin
                  bebex:=10;
                  if (WayPointDef = 0) then
                     Click_or_move_group(I,J,Butt)
                  else
                     Click_and_waypointdef(I,J,Butt)
                  {}
               end;
             end; { with Map^[I,J] }
           end; {if (Button <> 0) then begin .. else}

         end;
         { if (ADefSlots <> 0) then .. else .. }
        end; { if (Slots <> 0) then .. else .. }
     end; { if (Radar) then .. else .. }
   end else begin
   { NIC NEBYLO STISKNUTO }
     bebex:=10000;
     if (Grouping and Validity and (Butt = 0)) then begin
     { dokonceno oznaceni skupiny }
       bebex:=10001;
       SetCursorRange(0,0,XRes-4,YRes-4);
       Grouping:=False;
       CursorOff;
       XORFrame(XGroup,YGroup,XP,YP,XorColor);{}
       CursorOn;{}
       DrawXORFRame:=False;
       SetCursor(NormalCursor); LeftButton:=1 shl GameTimming;
       if ((I <> 65535) and (J <> 65535)) then begin
       { grouping byl ukoncen na obrazovce }
           if (I < IGroup) then begin
          { uprava souradnic }
             K:=IGroup; IGroup:=I; I:=K;
          end;
          if (J < JGroup) then begin
          { uprava souradnic }
             L:=JGroup; JGroup:=J; J:=L;
          end;

          { nyni zajistime, zby se navolily jen ty policka, ktere lezi
            uvnitr plochy alespon z 66% }
          { XGroup, YGroup = levy horni bod grup. obdelniku }
          Dec(XGroup,XScreenBeg); Dec(YGroup,YScreenBeg);
          {if ((XGroup mod XCellSize > 19) and (IGroup < I)) then Inc(IGroup);
          if ((YGroup mod YCellSize > 19) and (JGroup < J)) then Inc(JGroup);
          if ((X mod XCellSize < 13) and (IGroup < I)) then Dec(I);
          if ((Y mod YCellSize < 13) and (JGroup < J)) then Dec(J);{}

          with (Groups[MaxGroups]) do begin
             { vycisti pomocny slot MaxGroup }
              Clear_group_slots;
              if (ActiveGroup < 254) then Deselect_group(ActiveGroup);
              Count:=0;
              for K:=0 to MaxGroupUnits-1 do
               if (Un[K] <> NIL) then begin
                 Un[K]^.Group:=254;
                 Un[K]:=NIL;
               end;
             if (Building <> Nil) then Building^.Group:=254;
             Building:=Nil;

             Pom:=False; Load:=False;
             { nova skupina }
             K:=IGroup; L:=JGroup; ADefRange:=1000;
             PomGroundEnemyUnit:=Nil; PomAirEnemyUnit:=Nil;
             if (ClickLevel = 0) then begin { pozemni jednotka }
               PomLevel:=255;
               while ((Count < MaxGroupUnits) and (L <= J)) do begin
                 while ((Count < MaxGroupUnits) and (K <= I)) do with Map^[K,L] do begin
                    if ((First_level <> 0) and (Level_type and 128 = 0) and
                        (Units[First_level]^.Race = MyRace) and
                        (Units[First_level]^.Temp = 0) and
                        (Units[First_level]^.Activity) and
                        (Unit_types[Units[First_level]^.UnitType,Races[Units[First_level]^.Race].Ally].UnitLevel <> 255)) then
                     with (Units[First_level]^) do begin
                      { jednotky typu raketova vez se nevoli }
                      { OK, nalezena jednotka }
                      { Temp zajisti, aby se nenavolila vicekrat }
                      { pokud je prvni jednotka pristata letecka jednotka,
                        skupina se bere jako letecka a ostatni pozemni
                        jednotky se ignoruji; u letadel s letistem lze
                        grupovat jen ty se spolecnym letistem }
                      if (ADefRange = 1000) then ADefRange:=ActiveDefenceRange;
                      if (ADefRange <> ActiveDefenceRange) then ADefRange:=65535;

                      if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                          (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) and
                          (PomLevel = 255))
                      then begin
                         PomLevel:=1; { potrebuje letiste }
                         IAirp:=IAirport; JAirp:=JAirport;
                      end else
                        if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                            (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 1) and
                            (PomLevel = 255))
                        then PomLevel:=1 { potrebuje letiste }
                        else
                          if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 3) and
                              (PomLevel = 255))
                          then PomLevel:=0;

                      if ((PomLevel = 0) and { pozemni }
                          (Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 3) or
                          (PomLevel = 1) and { nepotrebuje letiste }
                          (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3))
                      then begin
                         Un[Count]:=Units[First_level];
                         PomUnit:=Units[First_level];
                         Group:=MaxGroups;
                         GroupOrder:=Count;
                         if (UnitType = 33) then Pom:=True;
                         if (UnitsInsideNum <> 0) then
                            Load:=True;
                         Inc(Temp);
                         Inc(Count);
                      end;
                    end else
                      if ((First_level <> 0) and (Level_type and 128 = 0) and
                          (Units[First_level]^.Race <> MyRace) and
                          (Units[First_level]^.Activity) and
                          (Unit_types[Units[First_level]^.UnitType,Races[Units[First_level]^.Race].Ally].UnitLevel <> 255))
                      then begin
                      { cizi jednotka }
                         if (PomGroundEnemyUnit = Nil) then
                           PomGroundEnemyUnit:=Units[First_level];
                      end;
                    Inc(K);
                 end; { while }
                 Inc(L); K:=IGroup;
               end; { while }
             end else begin { letecke jednotky }
               PomLevel:=1;
               while ((Count < MaxGroupUnits) and (L <= J)) do begin
                 while ((Count < MaxGroupUnits) and (K <= I)) do with Map^[K,L] do begin
                    if ((Second_level <> 0) and
                        (Units[Second_level]^.Race = MyRace) and
                        (Units[Second_level]^.Temp = 0) and
                        Units[Second_level]^.Activity and
                        (not Units[Second_level]^.Return_to_base)) then
                    with (Units[Second_level]^) do begin
                      { OK, nalezena jednotka }
                      if (ADefRange = 1000) then ADefRange:=ActiveDefenceRange;
                      if (ADefRange <> ActiveDefenceRange) then ADefRange:=65535;
                      { Temp zajisti, aby se nenavolila vicekrat }
                      Un[Count]:=Units[Second_level];
                      PomUnit:=Units[Second_level];
                      Group:=MaxGroups;
                      GroupOrder:=Count;
                      Inc(Temp);
                      Inc(Count);
                    end else
                      if ((Second_level <> 0) and
                          (Units[Second_level]^.Race <> MyRace) and
                          Units[Second_level]^.Activity and
                          (not Units[Second_level]^.Return_to_base))
                      then begin
                      { cizi jednotka }
                         if (PomAirEnemyUnit = Nil) then
                           PomAirEnemyUnit:=Units[Second_level];
                      end;
                    Inc(K);
                 end; { while }
                 Inc(L); K:=IGroup;
               end; { while }
            end;

            if (Count > 0) then begin
            { nejake jednotky byly nalezeny }
               { vynuluj Temp }
               Id:=255;
               for K:=0 to MaxGroupUnits-1 do
                 if (Un[K] <> NIL) then begin
                    {if (NetType = 1) then begin
                       IPX_SendWord(Un[K]^.Index);
                    end;{}
                    Un[K]^.Temp:=0;
                    if (Id = 255) then begin
                       Id:=Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].TargetTyp;
                       if (Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].UnitLevel = 255) then Id:=0;
                    end;
                 end;
               ActiveGroup:=MaxGroups;
               ClickStatus:=1;
               Select_group(MaxGroups);
               Click_on_group(ActiveGroup);
               if ((Count = 1) and (PomUnit^.Race = MyRace) and
                   (PomUnit^.UnitsInsideNum > 0)) then begin
                  Click_on_storage_unit(PomUnit); Load:=True;
               end;
               {if (NetType = 1) then begin { seriovy kabel }
               {   IPX_SendByte(0);
                  IPX_SendByte(SendSeriallIndex); Inc(SendSeriallIndex);
                  IPX_SendByte(Count);
                  SerialCheckSum:=0+Count;
               end;{}
               case (Id) of
                  0:Id:=0; 1:Id:=0; 2:Id:=1; 3:Id:=2;
               end;
               if ((Races[MyRace].RaceType <> 3) and
                   (Races[MyRace].RaceType <> 6)) then
                  PreparePlaySound(0,0,0,Id)
               else PreparePlaySound(1,0,0,Id);
            end else begin
            end;
            if ((not Active(Stop)) and (Count > 0)) then SetActive(Stop);
            if ((not Active(Patrol)) and (Count > 0)) then SetActive(Patrol);
            if (Active(Stop) and (Count = 0)) then SetPasive(Stop,256);
            if (Active(Patrol) and (Count = 0)) then SetPasive(Patrol,256);
            if ((ClickLevel = 0) and (Count > 0) and (not Active(Nalozit)))
            then SetActive(Nalozit);
            if (((ClickLevel = 1)  or (Count = 0)) and
                Active(Nalozit)) then SetPasive(Nalozit,256);
            if (not Active(Vylozit) and (Load) and (Count = 1)) then begin
              if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
              SetActive(Vylozit);
            end else begin
              if (Active(Vylozit) and ((Load = False) or (Count <> 1))) then
                SetPasive(Vylozit,256);
              if (Active(Rozlozit) and ((Pom = False) or (Count <> 1))) then
                SetPasive(Rozlozit,256)
              else
                if (not Active(Rozlozit) and (Pom) and (Count = 1)) then
                SetActive(Rozlozit);
            end;
            if ((not Active(Opravit)) and (Count > 0)) then SetActive(Opravit);
            if (Active(Opravit) and (Count = 0)) then SetPasive(Opravit,256);
            if ((not Active(ZvednoutMoralku)) and (Count > 0) and (MyRaceType <> 3) and
                (MyRaceType <> 6))
            then SetActive(ZvednoutMoralku);
            if (Active(ZvednoutMoralku) and (Count = 0)) then SetPasive(ZvednoutMoralku,256);
            GroupLevel:=PomLevel;
            ADefRng:=ADefRange;
            case (ADefRange) of
               ADRng1  : ADefRange:=0;
               ADRng2  : ADefRange:=1;
               ADRng3  : ADefRange:=2;
               ADRng4  : ADefRange:=3;
               65535   : ADefRange:=4;
            end;
            if (Count > 0) then begin
              SetActiveDefenceRangeSlotsActivity(ADefRange);
            end else ClearActiveDefenceRangeSlots;

            if (Count = 0) then begin
              if ((PomGroundEnemyUnit <> Nil) and
                  (PomGroundEnemyUnit^.Visibility)) then begin
              { navol alespon 1 cizi jednotku  - POZEMNI }
                 Count:=1;
                 if (Races[MyRace].Friend[PomGroundEnemyUnit^.Race] > 1) then
                    ClickStatus:=254 { pratelska jednotka }
                 else ClickStatus:=255; { nepratelska, neutralni jednotka }
                 Un[0]:=Units[PomGroundEnemyUnit^.Index];
                 Units[PomGroundEnemyUnit^.Index]^.Group:=MaxGroups;
                 Units[PomGroundEnemyUnit^.Index]^.GroupOrder:=0;
                 Select_group(MaxGroups);
                 if (Unit_types[PomGroundEnemyUnit^.UnitType,Races[PomGroundEnemyUnit^.Race].Ally].UnitLevel = 3)
                 then GroupLevel:=1
                 else GroupLevel:=0;
                   if ((ClickStatus <> 255) or (EnemyStatus)) then
                     Click_on_group(ActiveGroup) { zobrazit vse}
                   else Click_on_enemy_unit(Units[PomGroundEnemyUnit^.Index]);
                   { nezobrazit vse }
              end else begin
                 if ((PomAirEnemyUnit <> Nil) and
                     (PomAirEnemyUnit^.Visibility)) then begin
                 { navol alespon 1 cizi jednotku  - VZDUSNOU }
                   Count:=1; { leve tlacitko }
                   if (Races[MyRace].Friend[PomAirEnemyUnit^.Race] > 1) then
                      ClickStatus:=254 { pratelska jednotka }
                   else ClickStatus:=255; { nepratelska, neutralni jednotka }
                   Un[0]:=Units[PomAirEnemyUnit^.Index];
                   Units[PomAirEnemyUnit^.Index]^.Group:=MaxGroups;
                   Units[PomAirEnemyUnit^.Index]^.GroupOrder:=0;
                   Select_group(MaxGroups);
                   if (Unit_types[PomAirEnemyUnit^.UnitType,Races[PomAirEnemyUnit^.Race].Ally].UnitLevel = 3)
                   then GroupLevel:=1
                   else GroupLevel:=0;
                     if ((ClickStatus <> 255) or (EnemyStatus)) then
                       Click_on_group(ActiveGroup) { zobrazit vse}
                     else Click_on_enemy_unit(Units[PomAirEnemyUnit^.Index]); { nezobrazit vse }
                 end;
              end;
            end;

          end; { with Groups[MaxGroup] }
       end; { Grouping byl uspesne dokoncen }
     end else if (Validity) then begin { if (Grouping) then ... else }
     { * K ZADNEMU STISKU NEDOSLO; TESTUJ ALESPON, ZDA SE POD KURZOREM
         NENACHAZI NEJAKA JEDNOTKA *}
       bebex:=10002;
       Name:='';  Race:=LastRace; Vis:=False;
       if (Butt = 0) then begin
           bebex:=10003;
           if ((X >= XScreenBeg) and (Y >= YScreenBeg) and
               (X <= XScreenEnd) and (Y <= YScreenEnd)) then begin
           { kurzor je nad hraci plochou }
               bebex:=10004;
               I:=(X-XScreenBeg) div XCellSize + IBeg;
               J:=(Y-YScreenBeg) div YCellSize + JBeg;
               with (Map^[I,J]) do begin
                 if (ClickLevel = 0) then begin { prioritni je 1. uroven }
                    bebex:=10005;
                    if (First_level <> 0) then begin
                       if (Level_type and 128 = 0) then begin
                          if (Units[First_level]^.Visibility) then begin
                            bebex:=10006;
                            if (KillMode) then begin
                              Str(Units[First_level]^.Kills,Name);
                              Name:='KILLS: '+Name;
                            end else Name:=Units[First_level]^.Name;
                            Race:=Units[First_level]^.Race;
                            Vis:=True;
                          end;
                       end else begin
                          bebex:=10007;
                          if (Buildings[First_level]^.Visibility) then begin
                            Name:=Building_types[Buildings[First_level]^.BuildingType].Name;
                            Race:=Buildings[First_level]^.Race;
                            Vis:=True;
                          end;
                       end;
                       if (Race <= MaxRace) then begin
                          bebex:=10008;
                          if (Races[Race].Friend[MyRace] = 0) then begin
                              bebex:=11008;
                              if (Vis) then SetAnimCursorType(AttackCursor)
                              else SetAnimCursorType(NormalCursor);
                          end else
                            if (Races[Race].Friend[MyRace] = 2) then begin
                              bebex:=12008;
                              if (Vis) then SetAnimCursorType(GroupingCursor)
                              else SetAnimCursorType(NormalCursor);
                            end else SetAnimCursorType(NormalCursor);
                       end;
                    end else begin
                      bebex:=10009;
                      if ((Second_level = 0) and
                          Above(MapBck^[I,J].BckType,Field) and
                          BelowEqual(MapBck^[I,J].BckType,Resrc) and
                          (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask  > 0))
                      then begin
                         bebex:=10010;
                         Str(Round(ResourceInfo[MapBck^[I,J].Info].Resource/4),Name);
                         Name:='MATERIaLU:'+Name;
                      end else
                        if ((Second_level = 0) and
                            Above(MapBck^[I,J].BckType,Airport) and
                            (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask  > 0))
                        then begin
                           Name:='RUNWAY';
                        end;
                      SetAnimCursorType(MoveCursor);{}
                      {SetAnimCursorType(NormalCursor);{}
                    end;
                 end else begin
                    { prioritni je 2. uroven }
                    if (Second_level <> 0) then begin
                       if (Units[Second_level]^.Visibility) then begin
                         if (KillMode) then begin
                            Str(Units[Second_level]^.Kills,Name);
                            Name:='KILLS: '+Name;
                         end else Name:=Units[Second_level]^.Name;
                         Race:=Units[Second_level]^.Race;
                         Vis:=True;
                       end;
                       if (Race <> 255) then begin
                          if (Races[Race].Friend[MyRace] = 0) then begin
                             if (Vis) then SetAnimCursorType(AttackCursor)
                             else SetAnimCursorType(NormalCursor);
                          end else
                             if (Races[Race].Friend[MyRace] = 2) then begin
                               if (Vis) then SetAnimCursorType(GroupingCursor)
                               else SetAnimCursorType(NormalCursor);
                             end else SetAnimCursorType(NormalCursor);
                       end;
                    end else begin
                      if ((First_level = 0) and
                          Above(MapBck^[I,J].BckType,Field) and
                          BelowEqual(MapBck^[I,J].BckType,Resrc) and
                          (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask  > 0))
                      then begin
                         Str(Round(ResourceInfo[MapBck^[I,J].Info].Resource / 4),Name);
                         Name:='MATERIaLU:'+Name;
                      end else {}
                        if ((First_level = 0) and
                            Above(MapBck^[I,J].BckType,Airport) and
                           (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask  > 0))
                        then begin
                           Name:='RUNWAY';
                        end;
                      SetAnimCursorType(MoveCursor);{}
                      {SetAnimCursorType(NormalCursor);{}
                    end;
                 end; { prioritni je 2. uroven }
               end; { with }
           end else begin
           { zkus zjistit, zda je kurzor nad obrazovkovym tlacitkem }
              bebex:=10011;
              SetAnimCursorType(NormalCursor);
              bebex:=10012;
              TestButton(X,Y,Buttn);
              bebex:=10013; bebey:=10013;
              if (Buttn = 0) then begin
                  if (TestSlots(X,Y,Slots)) then with (GroupsBck[Slots]) do begin
                  { testovani slotu }
                     bebex:=10014;
                     if (Typ = 0) then begin
                       if (_unit <> Nil) then begin{}
                          Race:=_unit^.Race;
                          Name:=_unit^.Name;
                          if (Name = '') then
                            Name:=Unit_types[ElementType,Races[Race].Ally].Name;
                       end else begin
                          Name:='';{}
                          if ((ActiveGroup < 254) and
                              (Groups[ActiveGroup].Building <> Nil))
                          then begin
                            Race:=Groups[ActiveGroup].Building^.Race;
                            if (_unit <> Nil) then
                              Name:=_unit^.Name;
                            if (Name = '') then begin
                              Name:=Unit_types[ElementType,Races[Race].Ally].Name;
                            end;
                          end;
                       end;
                       if ((ActiveGroup < 254) and
                           (Groups[ActiveGroup].Building <> Nil) and
                           (Groups[ActiveGroup].Building^.Production_type <> 0) and
                           (Groups[ActiveGroup].Building^.Production_type = Slots))
                       then Name:='ZASTAVIT VjROBU';
                       bebey:=3;
                       { nyni zkus zobrazit cenu jednotky }
                       if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                         if ((Building <> Nil) and (Slots > 0) and
                             (Building_types[Building^.BuildingType].ProductionType < 2) and
                             (Name <> LastName))
                         then begin
                           bebey:=4;
                           if (Price_drew) then begin
                             bebey:=5;
                             Erase_price_bck_rectangle;
                             Invalidate_price_bck_rectangle;
                           end;

                           bebey:=6;
                           Init_price_bck_rectangle(5+((Slots-1) mod 3)*XCellSize,Y+YPictureSize+12,
                                                    Unit_types[ElementType,Races[Race].Ally].BP,
                                                    Unit_types[ElementType,Races[Race].Ally].PL,
                                                    Unit_types[ElementType,Races[Race].Ally].EE,
                                                    Unit_types[ElementType,Races[Race].Ally].EX);
                           {Draw_price_bck_rectangle(0,0,XResolution,YResolution);{}
                           Price_drew:=True;
                           Dont_erase_price:=True;
                         end;
                       end;
                     end else
                     if (Typ = 1) then begin
                       if (Building <> Nil) then begin
                          Race:=Building^.Race;
                          Name:=Building_types[ElementType].Name;
                          if (UnitProductionPossible(MyRace,22) and
                              (ElementType = 2))
                          then Name:=Unit_types[15,Races[Race].Ally].Name;
                       end else begin
                          Name:='';{}
                          if ((ActiveGroup < 254) and
                              (Groups[ActiveGroup].Building <> Nil))
                          then begin
                            Race:=Groups[ActiveGroup].Building^.Race;
                            Name:=Building_types[ElementType].Name;
                          end;
                       end;

                       if ((ActiveGroup < 254) and
                           (Groups[ActiveGroup].Building <> Nil) and
                           (Groups[ActiveGroup].Building^.Production_type <> 0) and
                           (Groups[ActiveGroup].Building^.Production_type = Slots))
                       then Name:='ZASTAVIT VjROBU';
                       { nyni zkus zobrazit cenu budovy }
                       if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
                         if ((Building <> Nil) and (Slots > 0) and
                             (Building_types[Building^.BuildingType].ProductionType < 2) and
                             (Name <> LastName))
                         then begin
                           if (Price_drew) then begin
                              Erase_price_bck_rectangle;
                              Invalidate_price_bck_rectangle;
                           end;
                           Init_price_bck_rectangle(5+((Slots-1) mod 3)*XCellSize,Y+YPictureSize+12,
                                                    Building_types[ElementType].BP,
                                                    Building_types[ElementType].PL,
                                                    Building_types[ElementType].EE,
                                                    Building_types[ElementType].EX);
                           {Draw_price_bck_rectangle(0,0,XResolution,YResolution);{}
                           Price_drew:=True;
                           Dont_erase_price:=True;
                         end;
                       end;
                     end else
                      if (Typ = 2) then begin
                        Name:='PRODUKCE PLASTi';
                      end else
                         if (Typ = 3) then begin
                           Name:='STOP PRODUKCI';
                           if ((ActiveGroup < 254) and
                               (Groups[ActiveGroup].Building <> Nil) and
                               (Groups[ActiveGroup].Building^.Production_type <> 0))
                           then Name:='ZASTAVIT VjROBU';
                         end;
                  end else begin
                  { otestovani slotu s informacemi o materialu }
                     bebex:=10015; bebey:=10013;
                     if (( Y >= YMaterialPicture1) and
                         (Y <= (YMaterialPicture1+YMaterialSlotSize)))
                     then begin { Y-ove souradnice vyhovuji }
                        if ((X > XMaterialPicture1) and (X < (XMaterialPicture1+XMaterialSlotSize)))
                        then Name:='STAVEBNe MATER.';
                        if ((X > XMaterialPicture2) and (X < (XMaterialPicture2+XMaterialSlotSize)))
                        then Name:='PLASTY';
                        if ((X > XMaterialPicture3) and (X < (XMaterialPicture3+XMaterialSlotSize)))
                        then Name:='ELEKTR. ENERGIE';
                        if ((X > XMaterialPicture4) and (X < (XMaterialPicture4+XMaterialSlotSize)))
                        then Name:='BOJ. ZKUgENOST';
                     end;
                  end;
              end else begin
              { jo, jde o tlacitko }
                 if (not Retreat) then begin
                    bebex:=10017;
                    case (Buttn) of
                      Stop : Name:='STOP (S)';
                      Patrol : Name:='AGRESIVITA (A)';
                      Nalozit : Name:='NALOkIT (N)';
                      Vylozit : Name:='VYLOkIT (V)';
                      Rozlozit : Name:='ROZLOkIT (R)';
                      Opravit  : Name:='OPRAVIT (O)';
                      ZvednoutMoralku : Name:='MORaLKA (M)';
                      MenuButton : Name:='MENU (F10)';
                      RadarModButton : Name:='MOD RADARU';
                      SellButton : Name:='PRODAT';
                      StopButton : if (GameStopped) then Name:='SPUgTdNe HRY'
                                   else Name:='STOP HRY (INS)';
                      TabButton : Name:='DALge VOLBY (TAB)';
                    end;
                 end;
              end;
           end;

           if (Name <> LastName) then begin
              bebex:=10018;
              OutSmallMsg(Name);
              if (Price_drew) and (not Dont_erase_price) then begin
                 Erase_price_bck_rectangle;
                 Invalidate_price_bck_rectangle;
                 Price_drew:=False;
              end;
           end;
           if (Dont_erase_price) then Dont_erase_price:=False;
           if ((Race <> LastRace) or
                (Ord(LastName[0]) = 0) and (Ord(Name[0]) > 0) or
                (Ord(LastName[0]) > 0) and (Ord(Name[0]) = 0))
           then begin
              if ((Race <= MaxRace) and (Ord(Name[0]) > 0)) then begin
                R:=Races[Race].RRGB;
                G:=Races[Race].GRGB;
                B:=Races[Race].BRGB;
              end else begin
                R:=0; G:=0; B:=0;
              end;
              SetRGB(250,R,G,B);{}
           end;
           LastName:=Name;
           LastRace:=Race;
       end; { if (Butt = 0) then begin }
     end;

   end;
Konec:
   bebex:=6666;
   if (NormCursor <> 0) then begin
      Dec(NormCursor);
      if ((NormCursor = 0) and (AnimatedCursor = 0)) then SetCursor(NormalCursor);
   end;
   CursorChanged:=False; bebex:=0;
end;

{ ***** }
procedure Buttons_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'11'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Buttons_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'11'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

  LeftButton:=0; MiddleButton:=0; RightButton:=0;
  LastName:=''; LastRace:=255;
  LastX:=0; LastY:=0; LastButton:=0;
  MouseEqualCount:=0;
  ChangeCursorLevel:=False;
  CursorChanged:=False;
  Price_drew:=False;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
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

   Grouping:=False; Scrolling:=False; ClickLevel:=0;
   LeftButton:=0; MiddleButton:=0; RightButton:=0;
   NormCursor:=0; LastName:=''; LastScroll:=False;
   MenuPressed:=False; StopGamePressed:=False; RadarModButtonPressed:=False;
   SellButtonPressed:=False;
   LastX:=0; LastY:=0; LastButton:=0; MouseEqualCount:=0;
   ChangeCursorLevel:=False; CursorChanged:=False;
   Price_drew:=False; Dont_erase_price:=False;
   MousKeybTest:=True;
   LastRace:=255;
   On1Seg:=0; On2Seg:=0; Off1Seg:=0; Off2Seg:=0;
   for I:=1 to MaxButtons do begin
      ButtonsInfo[I].Exist:=False;
      ButtonsInfo[I].Segment:=0;
      ButtonsInfo[I].ButtonText:='';
   end;
end.