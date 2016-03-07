unit Mouse;
{$C FIXED PRELOAD PERMANENT}
interface

var XCursorSize, YCursorSize:Word;  { x-ova a y-ova velikost kurzoru }

    Grouping : Boolean; { True, pokud se s pomoci mysi + shift vytvari skupina }
    IGroup, JGroup : Word; { levy horni roh grupovaciho obdelniku }
    XGroup, YGroup : Word; { levy horni roh grupovaciho obdelniku }
    ButtonClick : Word;    { stav tlacitek minuleho stisku }
    XClick, YClick : Word; { pozice, pri niz doslo naposledy
                             ke stisku tlacitka }
    BlockMouse : Boolean;  { True = ovladac se jakoby odinstaluje }
    Button:Word;           { stav tlacitek mysi }

    XMouse, YMouse:Word;   { pozice minuleho kurzoru }

    CursorVisibility:Word;              { = 0 ... kurzor neviditelny
                                          = 1 ... kurzor viditelny  }
    CursorSegment,CursorOffsets : Word; { ukazatel na predlohu kurzoru }

const XORColor = 31;

function InitMouse(X,Y:Word):Boolean;
procedure CursorOn;
procedure CursorOff;
procedure ChangeCursor(XSize,YSize:Word);
procedure SetCursorPicture(Segment, Offsets : Word);
procedure SetCursorSize(X,Y:Word);
procedure SetCursorPos(X,Y:Word);
procedure GetCursorPos(var X,Y,Buttons:Word);
procedure GetMouseClick(var X,Y,Buttons:Word);
procedure SetCursorRange(X,Y,X2,Y2:Word);
function GetMouseReleases(Buttons:Word; var X,Y:Word):Word;
function TestMouse(X,Y,XEnd,YEnd:Word):Boolean;
function TestMouseLeftTop(X,Y,XEnd,YEnd:Word):Boolean;
procedure GetXYMouse(var X,Y:Word);
procedure FinishMouse;
procedure Mouse_save;
procedure Mouse_load;

implementation
uses Graph257, Data_glb;
const Sipka:array[0..199] of Byte =
            (13,0,13,0,
             15,15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             15,15,15,15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0,15,15,15,15,15, 0, 0, 0, 0, 0, 0, 0, 0,
              0,15,15,15,15,15,15,15, 0, 0, 0, 0, 0, 0,
              0, 0,15,15,15,15,15,15,15,15, 0, 0, 0, 0,
              0, 0,15,15,15,15,15, 0, 0,15,15, 0, 0, 0,
              0, 0, 0,15,15,15,15,15, 0, 0, 0, 0, 0, 0,
              0, 0, 0,15,15, 0,15,15,15, 0, 0, 0, 0, 0,
              0, 0, 0, 0,15, 0, 0,15,15,15, 0, 0, 0, 0,
              0, 0, 0, 0,15,15, 0, 0,15,15,15, 0, 0, 0,
              0, 0, 0, 0, 0,15, 0, 0, 0,15,15,15, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0,15,15,15, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,15,15,15,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,15,15
            );
       XCursorConstSize = 13;
       YCursorConstSize = 13;

var K,I,J:Integer;                      { pomocne promenne }
    X,Y:Word;                           { pomocne promenne }
    Color:Word;                         { pomocna promenna }

    XMouseStep, YMouseStep:Word;        { pocet bodu, o ktere se bude
                                          posouvat kurzor }
    Background:array[0..1023] of Byte;  { pole s pozadim }

    MaxX, MaxY:Word;                    { sirka a vyska obrazovky }
    SegBackground, OffsBackground:Word; { sem se uschova pozadi pod kurzorem }
    VRAMBank : Byte;                    { pro prechodnou uschovu MemoryBanky }

{ ***** }
{$F+}
{ ***** }
procedure MouseHandle; far; assembler;
asm
     cli
     pusha
     push Ds
     push Di
     push Si

     mov Ax,SEG @Data
     mov Ds,Ax
     { docasne "odinstalovani" ovladace }
     cmp BlockMouse,0
     je  @Skipi     { skok = jakoby "neodinstalovani" ovladace }
     jmp @Preskoc   { jakoby "odinstalovani" ovladace }
@Skipi:
     shr Cx,2       { x-ova souradnice mysi v Cx, y-ova souradnice mysi v Dx}
     shr Dx,2
     xor Bh,Bh{}
     mov Button,Bx
     cmp Bx,0
     je @Without_click  { skok = nebylo nic stisknuto }
     mov ButtonClick,Bx
     mov XClick, Cx
     mov YClick, Dx
@Without_click:
     cmp CursorVisibility,0
     jne  @Draw_Cursor   { skok = kurzor je viditelny }
     mov XMouse,Cx
     mov YMouse,Dx{}
     jmp  @Preskoc   { skok = kurzor je neviditelny }

@Draw_Cursor:
     cmp Cx,XMouse { pokud jsou soucastne souradnice rovne predchozim,}
     jne @Pokracuj { nedelej nic (jmp Preskoc) }
     cmp Dx,YMouse
     jne @Pokracuj
     jmp @Preskoc

@Pokracuj:
     mov Al, MemoryBanka
     mov VRAMBank, Al
     mov Al,25
     mov MemoryBanka,Al
     { vykresleni pozadi na puvodni pozici }
     mov Ax,XMouse
     mov Bx,YMouse
     mov XMouse, Cx
     mov YMouse, Dx
     push Ax
     push Bx
     push SegBackground
     push OffsBackground
     call SpeedPutImage

@Skip:
     mov Ax,XMouse
     mov Bx,YMouse
     push Ax
     push Bx
     add Ax, XCursorSize
     push Ax
     add Bx, YCursorSize
     push Bx
     push SegBackground
     push OffsBackground
     call SpeedGetImage

     { vykresleni predlohy na nove pozici }
     push XMouse
     push YMouse
     push CursorSegment
     push CursorOffsets
     call SpeedPutImage2

     { obnova VRAM banky }
     mov Al, MemoryBanka
     cmp VRAMBank, Al
     je @Preskoc  { shoduji se - netreba menit }
     mov Dl, VRAMBank { nastav puvodni video banku }
     mov MemoryBanka, Dl
     xor Dh,Dh
     mov Ax,4f05h
     Int 7fh

@Preskoc:
     pop Si
     pop Di
     pop Ds
     popa
     sti
end;
{$F-}

{ ***** }
function InitMouse(X,Y:Word):Boolean;
{ Vraci True, je-li software mysi OK, jinak vraci False
  Je-li vse OK, nastavi uvodni promenne a ovladac
  (v parameterch X,Y prevezme udaje o sirce a vysce obrazovky)
}
var PomX, PomY:Word;
begin
   XCursorSize:=XCursorConstSize;    { X - ova velikost kurzoru  }
   YCursorSize:=YCursorConstSize;    { Y - ova velikost kurzoru  }
   CursorSegment:=Seg(Sipka);
   CursorOffsets:=Ofs(Sipka);

   PomX:=X;
   if (PomX >= XCursorSize) then PomX:=PomX-XCursorSize; PomX:=PomX shl MovementStep;
   PomY:=Y;
   if (PomY >= YCursorSize) then PomY:=PomY-YCursorSize; PomY:=PomY shl MovementStep;

   asm
     mov Ax,0  { inicializace mysi }
     int 33h
     cmp Ax,0
     je @NotSuccesfull
     mov @Result,1      { vse je OK }

     mov Ax,15
     mov Cx,MovementStep
     mov Dx,MovementStep { nastaveni citlivosti mysi }
     int 33h

{ inicializace promennych }
     mov XMouse,0; mov YMouse,0;  { souradnice stareho bodu }
     mov XMouseStep,1; mov YMouseStep,1;  { krok kurzoru mysi }
     mov CursorVisibility,0       { kurzor bude neviditelny }
     mov BlockMouse,1             { kurzor bude neviditelny }
     mov Ax,X
     mov MaxX,Ax                  { sirka obrazovky }
     mov Ax,Y
     mov MaxY,Ax                  { vyska obrazovky }

     mov Ax,Seg MouseHandle       { instalace vlastniho handle }
     mov Es,Ax
     mov Dx,Offset MouseHandle
     mov Ax,12
     mov Cx,$001f
     int 33h

     mov Ax,04h { nastavi pozici mysi na souradnice 0,0 }
     mov Cx,0
     mov Dx,0
     int 33h

     mov Ax,07h { nastavi x - ove rozmezi pro pohyb kurzoru }
     mov Cx,0
     mov Dx,PomX
     int 33h

     mov Ax,08h { nastavi y - ove rozmezi pro pohyb kurzoru }
     mov Cx,0
     mov Dx,PomY
     int 33h

     jmp @Konec;

@NotSuccesfull:
     mov @Result,0      { neuspech }
@Konec:
   end;
   GetMemory(1028,SegBackground,OffsBackground);
   if (SegBackground = 0) then InitMouse:=False;
end;

{ ***** }
procedure CursorOn;
{ Zobrazi kurzor (povoli zobrazovani)
}

begin
   BlockMouse:=True;
   if (CursorVisibility = 0) then begin
     {asm
        cli
     end;{}
     SpeedGetImage(XMouse,YMouse,XMouse+XCursorSize, YMouse+YCursorSize,
                   SegBackground,OffsBackground);
     SpeedPutImage2(XMouse,YMouse,CursorSegment,CursorOffsets);
     Inc(I);
     asm
        sti
     end;{}
   end;
   CursorVisibility:=1;
   BlockMouse:=False;
end;

{ ***** }
procedure CursorOff;
{ Smaze kurzor (zakaze zobrazovani)
}
begin
   if (CursorVisibility = 1) then begin
      BlockMouse:=True;
      CursorVisibility:=0;
      SpeedPutImage(XMouse,YMouse,SegBackground,OffsBackground);
      asm
        sti
      end; {}
   end;
end;

{ ***** }
procedure ChangeCursor(XSize,YSize:Word);
{ procedura zmeni kurzor podle JIZ nastavene predlohy;
  pozn. pred volanim nastavit BlockMouse na True
}
var LastVisibility:Word;
begin
   SpeedPutImage(XMouse,YMouse,SegBackground,OffsBackground);
   SetCursorSize(XSize,YSize);
   {SpeedGetImage(XMouse,YMouse,XMouse+XCursorSize, YMouse+YCursorSize,
                  SegBackground,OffsBackground);{}
   SpeedPutImage2(XMouse,YMouse,CursorSegment,CursorOffsets);
end;

{ ***** }
procedure SetCursorSize(X,Y:Word);
{ nastavi X-ovou a Y-ovou velikost kurzoru mysi; X*Y nesmi presahnout 1024;
  ( pouziti ve spojeni s predefinovanim kurzoru )
}
var Pom1,Pom2:LongInt;
begin
   Pom1:=X; Pom2:=Y;
   if (X*Y <= 1024) then begin
      XCursorSize:=X;
      YCursorSize:=Y;
   end;
end;

{ ***** }
procedure SetCursorPicture(Segment, Offsets : Word);
{ nastavi novou obrazkovou predlohu kurzoru
}
begin
   CursorSegment:=Segment;
   CursorOffsets:=Offsets;
end;

{ ***** }
procedure SetCursorPos(X,Y:Word);
{ nastavi mys na souradnice X,Y )
}
begin
   X:=X*4;
   Y:=Y*4;
   asm
     mov Cx,X
     mov Dx,Y
     mov Bx,0
     call MouseHandle

     mov Ax,04h
     mov Cx,X
     mov Dx,Y
     int 33h
   end;
end;

{ ***** }
procedure GetCursorPos(var X,Y,Buttons:Word);
{ vraci v parametrech X a Y aktualni pozici mysi a v Button stav tlacitek
  (Bit 0 = left button (2 button mode, 3 button mode)
   Bit 1 = right button (2 button mode, 3 button mode)
   Bit 2 = middle button (3 button mode)

}
begin
   X:=XMouse; Y:=YMouse; Buttons:=Button;{}
   {if (Button = ButtonClick) then ButtonClick:=0;{}
end;

{ ***** }
procedure GetMouseClick(var X,Y,Buttons:Word);
{ Vraci v parametrech X a Y pozici mysi, pri niz doslo naposledy ke stisku
  tlacitka. V Buttons se vraci stav tlacitek :
  (Bit 0 = left button (2 button mode, 3 button mode)
   Bit 1 = right button (2 button mode, 3 button mode)
   Bit 2 = middle button (3 button mode)

}
begin
   X:=XClick; Y:=YClick; Buttons:=ButtonClick;
   ButtonClick:=0;
end;

{ ***** }
procedure SetCursorRange(X,Y,X2,Y2:Word);
{ kurzor se bude pohybovat v rozmezi X-X2 a Y-Y2
}
begin
   X:=X*4;
   X2:=X2*4;
   Y:=Y*4;
   Y2:=Y2*4;

   asm
     mov Ax,07h { nastavi x - ove rozmezi pro pohyb kurzoru }
     mov Cx,X
     mov Dx,X2
     int 33h

     mov Ax,08h { nastavi y - ove rozmezi pro pohyb kurzoru }
     mov Cx,Y
     mov Dx,Y2
     int 33h
   end;
end;

{ ***** }
function GetMouseReleases(Buttons:Word; var X,Y:Word):Word;
{ V parametrech X,Y vraci souradnice posledniho uvolneni tlacitek mysi,
  specifikovanych v parametru Buttons:
  Bit 0 = left button (2 button mode, 3 button mode)
  Bit 1 = right button (2 button mode, 3 button mode)
  Bit 2 = middle button (3 button mode)
  Sama funkce pak vraci pocet uvolneni od posledniho volani.
}
var Number,Xs,Ys:Word;
begin
   asm
     mov Ax,6
     mov Bx,Buttons
     int 33h
     mov Number,Bx
     mov Xs,Cx
     mov Ys,Dx
   end;
   GetMouseReleases:=Number;
   X:=Xs div 4;
   Y:=Ys div 4;
end;

{ ***** }
function TestMouse(X,Y,XEnd,YEnd:Word):Boolean;
{ vraci True, nachazi-li se mys v danem obdelniku
}
begin
   if ((CursorVisibility = 1) and (X <= (XMouse+XCursorSize)) and
       (XEnd >= XMouse) and
       (Y <= (YMouse+YCursorSize)) and (YEnd >= YMouse)) then begin
     TestMouse:=True;
   end else TestMouse:=False;
end;

{ ***** }
function TestMouseLeftTop(X,Y,XEnd,YEnd:Word):Boolean;
{ vraci True, nachazi-li se mys v danem obdelniku
}
begin
   if ((CursorVisibility = 1) and (X <= XMouse) and
       (XEnd >= XMouse) and
       (Y <= YMouse) and (YEnd >= YMouse)) then begin
     TestMouseLeftTop:=True;
   end else TestMouseLeftTop:=False;
end;


procedure GetXYMouse(var X,Y:Word);
{
}
begin
  X:=XMouse; Y:=YMouse;            { pozice minuleho kurzoru }
end;

{ ***** }
procedure FinishMouse; assembler;
{ ukonci praci s mysi a de facto deinstaluje obsluznou rutinu
}
asm
     cli
     mov Ax,0
     mov Es,Ax
     mov Dx,0
     mov Ax,12
     mov Cx,$0
     int 33h
     sti
end;

{ ***** }
procedure Mouse_save;
{ pro potreby ulozeni hry
}
label K;

begin
{   Assign(IOFile,'save\15'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,MovementStep,SizeOf(MovementStep));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  {Close(IOFile); DResult:=IOResult;{}
end;

{ ***** }
procedure Mouse_load;
{ pro potreby ulozeni hry
}
label K;

begin
{   Reset(CheckFile,1); DResult:=IOResult;
   { existence souboru check znaci OK, jinak jde o chybu }
{   if (DResult <> 0) then GoTo K;
   Close(CheckFile);
   Assign(IOFile,'save\15'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockRead(IOFile,MovementStep,SizeOf(MovementStep));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  {Close(IOFile); Close(CheckFile); DResult:=IOResult;{}
end;

{ ************************************************************************* }

begin
   BlockMouse:=False;
   MovementStep:=3;
end.
