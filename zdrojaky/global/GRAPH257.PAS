unit Graph257;
{$C FIXED PRELOAD PERMANENT}
interface
uses VESA_EMM, WinApi;

const
      MaxFMIndex = 50;
      NormalPut = 0;
      XorPut = 1;
      Allocate = 0;
      NoAllocate = 1;
      NormalDirect = 0;
      ReverseDirect = 1;
      NoCompr = 0;
      Compr = 1;
      NoRGB = 0;
      RGB = 1;
      NoCreateNew = 0;
      CreateNew = 1;
      EMS = 1;
      Conventional = 0;
      _5x6Font = 0;
      EgaFont = 1;
      VgaFont = 2;
var
     IO_Result:Word;
     IO_ResultString:String[100];
     MemoryBanka:Byte;
     { ****************** }
{ * } EMS_line_adding:Word; { sirka cele obrazovky v EMS }
{ * } EMS_handle:Word; { ovladac pro pamet, pouzitou v Speed..Image..Mem }
      MapSegment:Word;
      EXPSegment:Word;
    { ****************** }

function AllocateGlobalMemory(Memory:LongInt):Boolean;
procedure InitSmallMemory;
function  GraphInit(PixelsX,PixelsY,PixelsX2,PixelsY2:Word):Word;
procedure GraphInitLight(PixelsX,PixelsY,PixelsX2,PixelsY2:Word);
procedure CloseGraph;
procedure SetColor( Colors:Byte);
procedure GetColor( var Colors:Byte );
procedure SetRGB(Colors,Red,Green,Blue:Byte);
procedure GetRGB( Colors:Byte; var Red,Green,Blue:Byte );
function  GetPixel( X,Y:Word ):Byte;
procedure ColorPixel( X,Y:Word; Colors:Byte );
procedure Pixel( X,Y:Word );
procedure NLine( X1,Y1,X2,Y2:Word );
procedure GetImage(X1,Y1,X2,Y2:Word; Segment,Offsets:Word; Direction:Word);
procedure PutImage(X1,Y1,Segment,Offsets:Word; Direction:Word);
procedure XPutImage(X1,Y1,XSize,YSize,Segment,Offsets:Word);
procedure PutImage2(X1,Y1,Segment,Offsets:Word; Direction:Word);
procedure GetMemory(Bytes:LongInt; var Segment,Offsets:Word );
procedure PutMemory(Bytes:Longint; var Segment,Offsets:Word);
procedure Window( X1,Y1,X2,Y2:Word);
function  GetFreeMem:LongInt;
procedure ClearScreen;
procedure SaveRGB(BeginNumber,EndNumber:Byte; Way:String);
procedure LoadRGB(BeginNumber:Byte; Way:String);
function OpenImage(Way:String; OpenType:Word):Word;
procedure SaveImageGBM(Segment,Offsets:Word; Name:String);
procedure SaveImageBMP(Segment,Offsets:Word);
procedure LoadImageGBM(Segment,Offsets:Word; Name:String; Pos:Word);
procedure LoadImageBMP(Segment,Offsets:Word; RGBs:Word);
procedure GetXYImageCoordinatesGBM(var X,Y:Word; Name:String);
procedure GetXYImageCoordinatesBMP(var X,Y:Word);
procedure SetVisualPage(Page:Word);
procedure ScrollScreen(X,Y:Word);
procedure SpeedPutImage(X, Y:Word; Segment, Offsets:Word);
procedure SpeedPutImage2(X, Y:Word; Segment, Offsets:Word);
procedure SpeedPutImage3(X, Y:Word; Segment, Offsets:Word; Color:Byte);
procedure SpecSpeedPutImage3(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word; Color:Byte);
procedure SpeedGetImage(X, Y, X2, Y2:Word; Segment, Offsets:Word);
procedure PutImageMem(X, Y:Word; Segment, Offsets, S,O :Word);
procedure PutImageMem2(X, Y:Word; Segment, Offsets, S,O :Word);
procedure Transfer(X, Y, XVRAM, YVRAM, XSize, YSize, S, O :Word);
procedure OutText(X,Y:Word; Msg:String);
procedure OutTextColor(X,Y:Word; Color:Byte; Msg:String);
procedure OutTextColorMem(S,O,XSize:Word; Color:Byte; Msg:String);
procedure Rectangle(X1,Y1,X2,Y2:Word; Color:Byte);
procedure Rectangle2(X1,Y1,X2,Y2:Word; Color:Byte);
procedure RectangleMem(X1,Y1,X2,Y2:Word; Color:Byte);
procedure Frame(X1,Y1,X2,Y2:Word; Color:Byte);
procedure Frame2(X1,Y1,X2,Y2:Word; Color:Byte);
procedure XORFrame(X1,Y1,X2,Y2:Word; Color:Byte);
procedure FrameMem(X1,Y1,X2,Y2:Word; Color:Byte);
procedure FrameMem2(X1,Y1,X2,Y2,LineLenght:Word; Color:Byte);
procedure SpecSpeedPutImageMem(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word);
procedure SpecSpeedPutImage2Mem(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word);
procedure SpecSpeedPutImageMemUnit(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word; Color:Byte);
procedure SpecMenuRectangle(X1,Y1,X2,Y2:Word);
procedure ScreenOn;
procedure ScreenOff;
procedure Convert_to_gray(Color,Count:Word);
procedure GetMaxRes(var MaxRes:Word);
procedure Graph257_save;
procedure Graph257_load;

implementation

uses Data_glb;
const MaxMem1028bIndex = 0;
      MaxMem1448bIndex = 0;
type TMem1028array = array[0..MaxMem1028bIndex] of record
                        S,O:Word;
                      end;
     TMem1448array = array[0..MaxMem1448bIndex] of record
                        S,O:Word;
                      end;

var GlobalMemory:Pointer;
    GlobalMemory2:Pointer;
    LogPage:Word; { citac log. stranek (po 16Kb) }

    Color, PixelStyle, FMIndex :Byte;

    RelX ,RelY ,MaximalniX ,MaximalniY ,MaxX ,Max1_4 ,MaxY:Word;

    YRes : Word; { skutecne graficke rozliseni v y-ove ose }

    FreeMemory:array[1..MaxFMIndex] of record
                                  SegmentOrg, OffsetOrg:Word;
                                  Length:LongInt;
                                end;
    { pro komprimaci: }
    S, O : Word;
    Buff:Pointer;
    ImageAttribute:Word;
    ImageFile:File;
    ImageFileWay:String[80];

    { pro pametove operace: }
    MemArray1028b : ^ TMem1028array;
    MemArray1448b : ^ TMem1448array;
    Mem1028bIndex, Mem1448bIndex:Word;
    MaxMem1028bIndex2, MaxMem1448bIndex2:Word;

{ ************************************************************************** }

{ ***** }
function AllocateGlobalMemory(Memory:LongInt):Boolean;
{ procedura naaalokuje souvisly pas pameti Memory pro pouziti programem.
  Vraci True, pokud se alokace podarila. POZOR! Lze zavolat pouze DVAKRAT
  za celou dobu programu! (alokace se rusi volanim CloseGraph, po jejim
  zavolani a opetnem InitGraph je samozrejme mozne AllocateGlobalMemory
  zavolat znovu )
}
var Pom, Pomocna:LongInt;
    Res:Boolean;
begin
   { nejprve zarovname na nasobek 64Kb }
   Pomocna:=Memory mod 65536;
   if (Pomocna > 0) then Pomocna:=65536;
   Memory:=((Memory div 65536)*65536)+Pomocna;

   Res:=False; FMindex:=0;
   if (GlobalMemory <> Nil) then GlobalMemory2:=GlobalMemory;
   GlobalMemory:=Nil;
   Pom:={GlobalCompact({}Memory{){}; { pokus najit souvisly pas pameti }
   if (Pom >= Memory) then begin { pokus se zdaril }
      GlobalMemory:=GlobalAllocPtr(GMEM_FIXED,Memory);
      if (GlobalMemory <> Nil) then begin { allocation success }
         FMIndex:=1;
         FreeMemory[FMIndex].SegmentOrg:=Seg(GlobalMemory^);
         FreeMemory[FMIndex].OffsetOrg:=Ofs(GlobalMemory^);
         FreeMemory[FMIndex].Length:=Memory;
         Res:=True;
      end;
   end;
   AllocateGlobalMemory:=Res;
end;

{ ***** }
procedure InitSmallMemory;
{ inicializuje pomocne pole pro obrazky 1028b a 1448b
}
var I,Segment,Offsets:Word;
    PomUk:Pointer;
begin
   MaxMem1028bIndex2:=0; MaxMem1448bIndex2:=0;
   { nejprve inicializace pole 1028b }
   Mem1028bIndex:=65535;
   I:=0; Segment:=0; Offsets:=0;
   while (I <= MaxMem1028bIndex) do begin
     if ((Segment = 0) or (Offsets > (65535-1028))) then begin
       GetMem(PomUk,65500);
       if (PomUk <> Nil) then begin
       { success! }
          Segment:=Seg(PomUk^); Offsets:=Ofs(PomUk^);
       end else I:=65534;
     end;
     MemArray1028b^[I].S:=Segment; MemArray1028b^[I].O:=Offsets;
     Inc(Offsets,1028);
     Inc(I);
   end;
   if ((I <= (MaxMem1028bIndex+1)) and (I > 0)) then begin
      MaxMem1028bIndex2:=I-1;
      Mem1028bIndex:=0;
   end;

   {XXX}
   Mem1448bIndex:=65535;
   I:=0; Segment:=0; Offsets:=0;
   while (I <= MaxMem1448bIndex) do begin
     if ((Segment = 0) or (Offsets > (65535-1448))) then begin
       GetMem(PomUk,65500);
       if (PomUk <> Nil) then begin
       { success! }
          Segment:=Seg(PomUk^); Offsets:=Ofs(PomUk^);
       end else I:=65534;
     end;
     MemArray1448b^[I].S:=Segment; MemArray1448b^[I].O:=Offsets;
     Inc(Offsets,1448);
     Inc(I);
   end;
   if ((I <= (MaxMem1448bIndex+1)) and (I > 0)) then begin
      MaxMem1448bIndex2:=I-1;
      Mem1448bIndex:=0;
   end;
end;

{ ***** }
function GraphInit(PixelsX,PixelsY,PixelsX2,PixelsY2:Word):Word;
{ inicializuje grafiku
  v X,Y jsou souradnice pozadovaneho grafickeho rozliseni
  PixelsX2 ,PixelsY2 urcuje uzivatelsky rozmer  obrazovky
  (PixelsY-PixelsY2 = plocha, skryta "pod obrazovkou").
  Do skryte casti obrazovky lze napr. kreslit a pak s pomoci
  Get-PutImage obrazek najednou zobrazit.
  Sama fce vraci  0, je-li vse v poradku
  _ || _  _ || _  1, nejde-li o adapter VESA (vyjma modu 320x200, 256 barev)
  _ || _  _ || _  2, pokud adapter VESA dane rozliseni nepodporuje
  _ || _  _ || _  3, pokud jde o chybu pri nahravani fontu 5x6
  _ || _  _ || _  4, pokud jde o jinou chybu
}
label Error, Konec;
var Result, Count, S, O, Pom:Word;
    Free:LongInt;

begin
  FMIndex:=0;
  MaxX:=PixelsX2; MaxY:=PixelsY2; YRes:=PixelsY; Max1_4:=MaxX div 4;
  Result:=InitG(PixelsX,PixelsY,PixelsX2);
  RelX:=0; RelY:=0; MaximalniX:=MaxX-1; MaximalniY:=MaxY-1;
  if Result=0 then begin
    MemoryBanka:=0; Color:=15; ImageAttribute:=255;
    PixelStyle:=0; {LineStyle:=SolidLn;{}
  end else begin
    GraphInit:=Result;
    GoTo Konec;
  end;

  GraphInit:=Result;
  GoTo Konec;
Error:
  CloseGraph;
  GraphInit:=3;
Konec:
end;

{ ***** }
procedure GraphInitLight(PixelsX,PixelsY,PixelsX2,PixelsY2:Word);
{ inicializuje grafiku a nic jineho!! (je nedestruktivni)
  v X,Y jsou souradnice pozadovaneho grafickeho rozliseni
  PixelsX2 ,PixelsY2 urcuje uzivatelsky rozmer  obrazovky
  (PixelsY-PixelsY2 = plocha, skryta "pod obrazovkou").
  Do skryte casti obrazovky lze napr. kreslit a pak s pomoci
  Get-PutImage obrazek najednou zobrazit.
}
var Result:Word;

begin
  MaxX:=PixelsX2; MaxY:=PixelsY2; YRes:=PixelsY; Max1_4:=MaxX div 4;
  RelX:=0; RelY:=0; MaximalniX:=MaxX-1; MaximalniY:=MaxY-1;
  MemoryBanka:=0;
  Result:=InitG(PixelsX,PixelsY,PixelsX2);
end;

{ ***** }
procedure CloseGraph;
{ ukonci graficky mod a uvolni pamet
}
var S, O, Pom:Word;
begin
   if (GlobalMemory <> Nil) then GlobalFreePtr(GlobalMemory);
   if (GlobalMemory2 <> Nil) then GlobalFreePtr(GlobalMemory2);{}
   CloseGraphics;
   if (ImageAttribute = 0) then Close(ImageFile);
   Pom:=IOResult;
end;

{ ***** }
procedure Window(X1,Y1,X2,Y2:Word);
{ definuje 'kreslici okno'; vsechny kreslici procedury se pak budou
  vztahovat k nemu
}
var Pomocna:Word;
begin
   if (X1 > X2) then begin Pomocna:=X1; X1:=X2; X2:=Pomocna; end;
   if (Y1 > Y2) then begin Pomocna:=Y1; Y1:=Y2; Y2:=Pomocna; end;
   if (X1 > MaxX) then X1:=0;
   if (X2 >= MaxX) then X2:=MaxX-1;
   if (Y1 > MaxY) then Y1:=0;
   if (Y2 >= MaxY) then Y2:=MaxY-1;
   RelX:=X1; RelY:=Y1;
   MaximalniX:=X2-X1; MaximalniY:=Y2-Y1;
end;

{ ***** }
procedure SetColor(Colors:Byte); assembler;
{ nastavuje aktualni barvu
}
asm
   mov Al,Colors
   mov Color,Al
end;

{ ***** }
procedure GetColor(var Colors:Byte);
{ vraci aktualni barvu
}
begin
   Colors:=Color;
end;

{ ***** }
procedure SetDrawStyle(PixelStyl:Byte); assembler;
{ nastavuje zpusob zobrazovani - 0=normalne, 1=pomoci Xor
}
asm
   mov Al,PixelStyl
   mov PixelStyle,Al
end;

{ ***** }
procedure SetRGB(Colors,Red,Green,Blue:Byte);
{ nastavuje DAC registr
}
begin
   asm
      mov Ah,10h
      mov Al,10h
      mov Bl,Colors
      mov Ch,Green
      mov Cl,Blue
      mov Dh,Red
      Int 10h
   end;
end;

{ ***** }
procedure GetRGB(Colors:Byte;var Red,Green,Blue:Byte);
{ nacita DAC registr
}
var Zelena, Modra, Cervena:Byte;
begin
   asm
      mov Ah,10h
      mov Al,15h
      mov Bl,Colors
      Int 10h
      mov Zelena,Ch
      mov Modra,Cl
      mov Cervena,Dh
   end;
   Green:=Zelena; Blue:=Modra; Red:=Cervena;
end;

{ ***** }
function GetPixel(x,y:Word):Byte;
{ vrati barvu bodu na dane pozici
}
var Barva:Byte;
begin
   asm
     mov Cx,x
     cmp Cx,MaximalniX
     ja @end
     mov Ax,y
     cmp Ax,MaximalniY
     ja @end
     add Cx,RelX
     add Ax,RelY
     mov Di,MaxX
     mul Di
     add Ax,Cx
     jnc @No_Inc
     inc Dl
@No_Inc:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj:
     mov Ax,VRam
     mov Es,Ax
     mov Bl,Es:[Si]
     mov Barva,Bl
@end:
   end;
   GetPixel:=Barva;
end;

{ ***** }
procedure ColorPixel(x,y:Word; Colors:Byte); assembler;
{ vykresli bod predanou barvou podle parametru PutPixelType
}
var Barva:Byte;
asm
     cmp PixelStyle,0
     jne @xor
     mov Cx,x
     cmp Cx,MaximalniX
     ja @end
     mov Ax,y
     cmp Ax,MaximalniY
     ja @end
     add Cx,RelX
     add Ax,RelY;
     mov Bl,Colors
     mov Dx,MaxX
     mul Dx
     add Ax,Cx
     jnc @No_Inc
     inc Dl
@No_Inc:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj:
     mov Ax,VRam
     mov Es,Ax
     mov Es:[Si],Bl
     jmp @end
@xor:
     mov Cx,x
     cmp Cx,MaximalniX
     ja @end
     mov Ax,y
     cmp Ax,MaximalniY
     ja @end
     add Cx,RelX
     add Ax,RelY;
     mov Bl,Colors
     mov Dx,MaxX
     mul Dx
     add Ax,Cx
     jnc @No_Inc2
     inc Dl
@No_Inc2:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj2
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj2:
     mov Ax,VRam
     mov Es,Ax
     mov Cl,Es:[Si]
     xor Bl,Cl
     mov Es:[Si],Bl
@end:
end;

{ ***** }
procedure Pixel(x,y:Word); assembler;
{ vykresli bod aktualni barvou a podle parametru PutPixelType
}
asm
     cmp PixelStyle,0
     jne @xor
     mov Cx,x
     cmp Cx,MaximalniX
     ja @end
     mov Ax,y
     cmp Ax,MaximalniY
     ja @end
     add Cx,RelX
     add Ax,RelY;
     mov Bl,Color
     mov Dx,MaxX
     mul Dx
     add Ax,Cx
     jnc @No_Inc
     inc Dl
@No_Inc:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj:
     mov Ax,VRam
     mov Es,Ax
     mov Es:[Si],Bl
     jmp @end
@Xor:
     mov Cx,x
     cmp Cx,MaximalniX
     ja @end
     mov Ax,y
     cmp Ax,MaximalniY
     ja @end
     add Cx,RelX
     add Ax,RelY;
     mov Bl,Color
     mov Dx,MaxX
     mul Dx
     add Ax,Cx
     jnc @No_Inc2
     inc Dl
@No_Inc2:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj2
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj2:
     mov Ax,VRam
     mov Es,Ax
     mov Cl,Es:[Si]
     xor Bl,Cl
     mov Es:[Si],Bl
@end:
end;

{ ***** }
procedure LinePixel(X,Y:Word); assembler;
{ vykresli bod aktualni barvou a podle parametru PutPixelType }
asm
     mov Cx,X
     mov Ax,Y
     mov Bl,Color
     mov Dx,MaxX
     cmp PixelStyle,0
     jne @xor
     mul Dx
     add Ax,Cx
     jnc @No_Inc
     inc Dl
@No_Inc:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj:
     mov Ax,VRam
     mov Es,Ax
     mov Es:[Si],Bl
     jmp @end
@Xor:
     mul Dx
     add Ax,Cx
     jnc @No_Inc2
     inc Dl
@No_Inc2:
     mov Si,Ax
     cmp Dl,MemoryBanka
     je @Pokracuj2
     mov Al,Dl
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracuj2:
     mov Ax,VRam
     mov Es,Ax
     mov Cl,Es:[Si]
     xor Bl,Cl
     mov Es:[Si],Bl
@end:
end;

{ ***** }
procedure NLine(X1,Y1,X2,Y2:Word);
{ kresli "normalni" caru
}
var DeltaX, DeltaY, Konst1, Konst2, XIncr, YIncr, p:Integer;
    XInc, YInc:Boolean;
begin
   { upraveni max. hodnot }
   asm
      mov Dx,RelX
      mov Ax,X1
      cmp MaximalniX,Ax
      jae @1
      mov Ax,MaximalniX
      mov X1,Ax
@1:
      add X1,Dx   { relativne v okne }
      mov Ax,X2
      cmp MaximalniX,Ax
      jae @2
      mov Ax,MaximalniX
      mov X2,Ax
@2:
      add X2,Dx   { relativne v okne }
      mov Dx,RelY
      mov Ax,Y1
      cmp MaximalniY,Ax
      jae @3
      mov Ax,MaximalniY
      mov Y1,Ax
@3:
      add Y1,Dx   { relativne v okne }
      mov Ax,Y2
      cmp MaximalniY,Ax
      jae @4
      mov Ax,MaximalniY
      mov Y2,Ax
{ relativne v okne ... }
@4:
      add Y2,Dx   { relativne v okne }
   end;
   if (X1 > X2) then begin
      asm
         mov XInc,1
         mov Ax,X1
         mov Bx,X2
         mov X1,Bx
         mov X2,Ax
         sub Ax,Bx
         mov XIncr,Ax
      end;
   end else begin
      asm
         mov XInc,0
         mov XIncr,0
      end;
   end;
   if (Y1 > Y2) then begin
      asm
         mov YInc,1
         mov Ax,Y1
         mov Bx,Y2
         mov Y1,Bx
         mov Y2,Ax
         sub Ax,Bx
         mov YIncr,Ax
      end;
   end else begin
      asm
         mov YIncr,0
         mov YInc,0
      end;
   end;

   if (X1 = X2) then begin { svisla cara }
       while (Y1 <= Y2) do begin LinePixel(X1,Y1); Inc(Y1); end;
   end else begin
      DeltaX := X2 - X1;
      DeltaY := Y2 - Y1;
      if (DeltaX >= DeltaY) then begin  { X-ovy rozdil je vetsi }
         Konst1 := DeltaY+DeltaY;
         Konst2 := Konst1 - DeltaX - DeltaX;
         p := Konst1 - DeltaX;

         asm
            mov Bx,X1              { Bx = X1 }
            mov Cx,Y1              { Cx = Y1 }
            mov Di,p               { Di = p }
            { Si - adresa radku ve VRAM }
            { Dl - cislo aktualni videobanky }
            mov Ax,Y1
            add Ax,YIncr
            mul MaxX
            mov Si,Ax

            mov Ax,VRAM
            mov Es,Ax              { segmentova adresa VRAM }
            jmp @cont3             { uvodni LinePixel }
@again:
            cmp Bx,X2
            jl @continue   { X1 < X2 }
            jmp @end2      { X1 >= X2 }
@continue:
            inc Bx

            cmp Di,0       { if (p < 0) }
            jl @NoIncY     { then ... }
            inc Cx         { else ... }
            add Di,Konst2  { P:=P+Konst2 }
            cmp YInc,1     { if (YInc)  -  urcuje smer nahoru/dolu }
            jne @YAdrInc   { else dolu }
            sub Si,MaxX    { nahoru - sniz Y-ovou adresu radku }
            jnc @cont2
            dec Dl
            jmp @cont2
@YAdrInc:
            add Si,MaxX    { dolu - zvys Y-ovou adresu radku }
            jnc @cont2
            inc Dl
            jmp @cont2

@NoIncY:    add Di,Konst1  { p < 0 }
@cont2:
            cmp XInc,1     { if (XInc)  -  urcuje smer nahoru/dolu }
            jne @cont3     { else ... }
            sub XIncr,2    { then Dec(XIncr,2) }
@cont3:
            { volani LinePixel }
            push Si
            push Dx

            { LinePixel }
            mov Dh,Color
            cmp PixelStyle,0
            jne @xor
            mov Ax,Bx
            add Ax,XIncr
            add Si,Ax
            jnc @No_Inc
            inc Dl
@No_Inc:
            cmp Dl,MemoryBanka
            je @Pokracuj
            mov MemoryBanka,Dl
            mov Ax,4f05h
            int IntNum
@Pokracuj:
            mov Es:[Si],Dh
            pop Dx
            pop Si
            jmp @again

@Xor:
            mov Ax,Bx
            add Ax,XIncr
            add Si,Ax
            jnc @No_Inc2
            inc Dl
@No_Inc2:
            cmp Dl,MemoryBanka
            je @Pokracuj2
            mov MemoryBanka,Dl
            mov Ax,4f05h
            Int IntNum
@Pokracuj2:
            xor Es:[Si],Dh
@end:
            pop Dx
            pop Si
            jmp @again
@end2:
         end;
      end else begin     { Y-ovy rozdil je vetsi }
         Konst1 := 2*(DeltaX);
         Konst2 := Konst1 - 2*DeltaY;
         p := Konst1 - DeltaY;
         asm
            mov Cx,X1              { Cx = X1+XIncr }
            add Cx,XIncr
            mov Bx,Y1              { Bx = Y1 }
            mov Di,p               { Di = p }
            { Si - adresa radku ve VRAM }
            { Dl - cislo aktualni videobanky }
            mov Ax,Y1
            add Ax,YIncr
            mul MaxX
            mov Si,Ax

            mov Ax,VRAM
            mov Es,Ax              { segmentova adresa VRAM }
            jmp @cont2             { uvodni LinePixel }

@again:
            cmp Bx,Y2
            jl @continue   { Y1 < Y2 }
            jmp @end2      { Y1 >= Y2 }
@continue:
            inc Bx

            { Inc/Dec Y }
            cmp YInc,1     { if (YInc)  -  urcuje smer nahoru/dolu }
            jne @YAdrInc   { else dolu }
            sub Si,MaxX    { nahoru - sniz Y-ovou adresu radku }
            jnc @AdrNo_Inc
            dec Dl
            jmp @AdrNo_Inc
@YAdrInc:
            add Si,MaxX    { dolu - zvys Y-ovou adresu radku }
            jnc @AdrNo_Inc
            inc Dl
@AdrNo_Inc:
            { ***** }
            cmp Di,0       { if (p < 0) }
            jl @NoIncX     { then ... }

            { inc X1 }
            inc Cx
            add Di,Konst2  { p:=p+Konst2 }
            cmp XInc,1     { if (XInc)  -  urcuje smer nahoru/dolu }
            jne @cont2     { else ... }
            sub Cx,2       { then Dec(X1+XIncr,2) }
            jmp @cont2
@NoIncX:    add Di,Konst1  { p < 0 }

@cont2:
            { volani LinePixel }
            push Si
            push Dx

            { LinePixel }
            mov Dh,Color
            cmp PixelStyle,0
            jne @xor
            add Si,Cx
            jnc @No_Inc
            inc Dl
@No_Inc:
            cmp Dl,MemoryBanka
            je @Pokracuj
            mov MemoryBanka,Dl
            mov Ax,4f05h
            int IntNum
@Pokracuj:
            mov Es:[Si],Dh
            pop Dx
            pop Si
            jmp @again

@Xor:
            add Si,Cx
            jnc @No_Inc2
            inc Dl
@No_Inc2:
            cmp Dl,MemoryBanka
            je @Pokracuj2
            mov MemoryBanka,Dl
            mov Ax,4f05h
            Int IntNum
@Pokracuj2:
            xor Es:[Si],Dh
@end:
            pop Dx
            pop Si
            jmp @again
@end2:
         end;
      end; { if (DeltaX >= DeltaY) else }
   end; {if (X1 = X2) }
end;

{ ***** }
procedure GetImage(X1,Y1,X2,Y2:Word; Segment,Offsets:Word; Direction:Word);
{ ulozi obraz z daneho ctverce do ukazatele Segment-Offsets
  je-li Direction = 0, provede se normalni ulozeni obrazku odshora dolu,
  jinak odspodu nahoru. Upravuji se souradnice!
}
var Pomocna,Pomocna2,P2,P3,P4,P5:LongInt;
    Segment2,Offsets2,PomocnaX,PomocnaY:Word;
    X,Y,X22,Y22,I,J:Integer;
    Selector:Word;
    U:Pointer;
    P:Byte;
begin
   Selector:=SelectorInc;
   if (X1 > X2) then begin PomocnaX:=X1; X1:=X2; X2:=PomocnaX; end;
   if y1>y2 then begin PomocnaY:=y1; y1:=y2; y2:=PomocnaY; end;
   if x1>MaximalniX then x1:=MaximalniX;
   if y1>MaximalniY then y1:=MaximalniY;
   if x2>MaximalniX then x2:=MaximalniX;
   if y2>MaximalniY then y2:=MaximalniY;
   PomocnaX:=x2-x1; PomocnaY:=y2-y1; P2:=PomocnaX; P3:=PomocnaY;
   Pomocna:=P2*P3+4;
   Segment2:=Segment; Offsets2:=Offsets;
   asm
     mov Ax,Segment2; mov Es,Ax; mov Si,Offsets2;
     mov Bx,PomocnaX; mov Cx,PomocnaY;
     mov Es:[Si],Bx; inc Si; inc Si
     mov Es:[Si],Cx; inc Si; inc Si
     mov Offsets2,Si
   end;
   X22:=PomocnaX+X1; Y22:=PomocnaY+Y1;
   asm
{ relativne v okne }
       mov Ax,RelX
       add X1,Ax
       add X22,Ax
       mov Ax,X22
       mov X2,Ax

       mov Ax,RelY
       add Y1,Ax
       add Y22,Ax
       mov Ax,Y22
       mov Y2,Ax

     end;
     PomocnaX:=X2; PomocnaY:=Y2;
     y:=y1;
     if (Direction<>0) then  { ulozeni odspodu nahoru }
        y:=PomocnaY;

 while (y1 <= PomocnaY) do begin
       x:=x1;
       asm
{ v Es:Di jsou ulozeny hodnoty Segment2,Offsets2
  v Ds:Si je ulozena adresa predavaneho bodu z VRAM
  v Bx je promenna PomocnaX
  v Cx je ulozena promenna X
}
           mov Cx,x          { nacteni patricnych hodnot drive, nez bude }
           mov Ax,y          { zmenen registr Ds a promenne tak budou }
           mov Bx,PomocnaX   { nedostupne }
           mov Si,MaxX
           push Ds           { ulozeni skutecneho dat. segmentu }
           mov Dl,MemoryBanka
           xor Dh,Dh
           push Dx           { ulozeni hodnoty MemoryBanka }
           cld

           mov Di,Offsets2
           mov Es,Segment2
           mov Dx,VRam
           mov Ds,Dx

           mul Si            { vypocet adresy pro dany radek }
           add Ax,Cx
           jnc @No_Inc2
           inc Dl
@No_Inc2:
           mov Si,Ax
           jmp @No_Inc

@No_Inc:
           pop Ax   { zmena video bufferu; v Ax se nacte obsah promenne }
           push Ax  { MemoryBanka a ihned se zase ulozi }
           cmp Dl,Al
           je @Pokracuj
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum

@Pokracuj:
           cmp Di,64255
           ja @NoSpeed
           cmp Si,64255
           ja @NoSpeed
{ "rychla varianta" }
           sub Bx,Cx
           mov Cx,Bx
           inc Cx
rep        movsb     { presun dat z pameti do VRam }

           jmp @finallyend{ skok=ano, ukonci }

@NoSpeed:
           movsb     { presun dat z pameti do VRam }
           cmp Di,0        { dostali jsme se v pameti na konec segmentu ? }
           je @Inc_Segment { skok=ano }
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Si,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed    { skok=ne }
           inc Dl
           { ano }
@SwitchVRAMBuffer:
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
           jmp @NoSpeed

@Inc_Segment:              { konec aktualniho segmentu - nastav dalsi cast}
           pop Dx          { Memory banka }
           pop Ax          { Ds registr }

           push Ds         { stara Ds hodnota }
           push Dx         { Memory banka }
           mov Ds,Ax
           pop Dx
           pop Ax
           push Ds
           push Dx
           mov Ds,Ax

           mov Ax,Es
           add Ax,Selector
           mov Es,Ax

@Pokrac:
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Si,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed    { skok=ne }
           inc Dl
           jmp @SwitchVRAMBuffer  { skok=ano }

@finallyend:
           mov Ax,Es
           pop Dx          { vytahni ze zasobniku nejprve MemoryBanku }
           pop Ds          { a pote pascalovsky Ds }
           mov Offsets2,Di  { aktualizace promennych }
           mov Segment2,Ax
           mov MemoryBanka,Dl
       end;
       Inc(y1);
       if (Direction=0) then Inc(y) else Dec(y);
   end;
end;

{ ***** }
procedure PutImage(X1,Y1,Segment,Offsets:Word; Direction:Word);
{ ulozi obraz z daneho ukazatele Segment-Offsets na obrazovku
  je-li Direction = 0, provede se normalni ulozeni obrazku odshora dolu,
  jinak odspodu nahoru
}
var AddX,PomocnaX,PomocnaY,Priznak,Handle:Word;
    X,Y,X2,Y2,X3,Y3:Integer;
    Selector:Word;
begin
if Segment>0 then begin
     Selector:=SelectorInc;
     asm
       mov Ax,Segment; mov Es,Ax; mov Si,Offsets
       mov Bx,Es:[Si]; inc Si; inc Si
       mov Cx,Es:[Si]; inc Si; inc Si
       mov Offsets,Si; mov PomocnaX,Bx; mov PomocnaY,Cx
     end;
     X2:=PomocnaX+X1; Y2:=PomocnaY+Y1;
     asm
       mov Ax,X2
       mov X3,Ax
       mov Ax,VRam
       mov Es,Ax

      { upraveni max. hodnot }
       mov Cx,X1
       cmp MaximalniX,Cx
       jae @1
       mov Ax,MaximalniX
       mov X1,Ax
@1:
       mov Cx,X2
       cmp MaximalniX,Cx
       jae @2
       mov Ax,MaximalniX
       mov X2,Ax
       mov X3,Ax
@2:
       mov Ax,Y1
       cmp MaximalniY,Ax
       jae @3
       mov Ax,MaximalniY
       mov Y1,Ax
@3:
       mov Ax,Y2
       cmp MaximalniY,Ax
       jae @1dal
       mov Ax,MaximalniY
       mov Y2,Ax
       mov Y3,Ax
{ relativne v okne ... }
@1dal:
       mov Ax,RelX
       add X1,Ax
       add X2,Ax
       mov Ax,RelY
       add Y1,Ax
       add Y2,Ax
{ }
       mov Ax,Y2
       mov Y3,Ax
       mov Ax,X2
       mov X3,Ax

{ porovnani hodnot X1,X2 a Y1,Y2 }
       mov Ax,X1
       cmp X3,Ax
       jae @OK1
       mov X1,Bx
       mov X3,Ax
@OK1:
       mov Ax,Y1
       cmp Y3,Ax
       jae @OK2
       mov Cx,Y3
       mov Y1,Cx
       mov Y3,Ax
@OK2:
     end;
     AddX:=PomocnaX-(X3-X1);
     PomocnaX:=X3; PomocnaY:=Y3;
     Y:=Y1;
     if (Direction<>0) then  { ulozeni odspodu nahoru }
        Y:=PomocnaY;

  while (Y1 <= PomocnaY) do begin
      X:=X1;
      asm
{ v Ds:Si jsou ulozeny hodnoty Segment,Offsets (zdrojove informace)
  v Es:Di je ulozena adresa ukladaneho bodu ve VRAM
  v Bx je promenna PomocnaX
  v Cx je ulozena promenna X
}
           mov Cx,x          { nacteni patricnych hodnot drive, nez bude }
           mov Ax,y          { zmenen registr Ds a promenne tak budou }
           mov Bx,PomocnaX   { nedostupne }
           mov Di,MaxX
           push Ds           { ulozeni skutecneho dat. segmentu }
           mov Dl,MemoryBanka
           xor Dh,Dh
           push Dx           { ulozeni hodnoty MemoryBanka }
           cld

           mov Dx,VRam
           mov Es,Dx
           mov Si,Offsets
           mov Ds,Segment

           mul Di            { vypocet adresy pro dany radek }
           add Ax,Cx
           jnc @No_Inc2
           inc Dl
@No_Inc2:
           mov Di,Ax
           jmp @No_Inc

@No_Inc:
           pop Ax   { zmena video bufferu; v Ax se nacte obsah promenne }
           push Ax  { MemoryBanka a ihned se zase ulozi }
           cmp Dl,Al
           je @Pokracuj
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
@Pokracuj:
           cmp Di,64255
           ja @NoSpeed
           cmp Si,64255
           ja @NoSpeed
{ "rychla varianta" }
           sub Bx,Cx
           mov Cx,Bx
           inc Cx
rep        movsb     { presun dat z pameti do VRam }
           jmp @finallyend{ skok=ano, ukonci }

@NoSpeed:
           movsb     { presun dat z pameti do VRam }
           cmp Si,0d       { dostali jsme se v pameti na konec segmentu ? }
           je @Inc_Segment { skok=ano }
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Di,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed   { skok=ne }
           inc Dl
           { konec VRAM }
@SwitchVRAMBuffer:
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
           jmp @NoSpeed

@Inc_Segment:              { konec aktualniho segmentu - nastav dalsi cast}
           pop Dx          { Memory banka }
           pop Ax          { Ds registr }

           push Ds         { stara Ds hodnota }
           push Dx         { Memory banka }
           mov Ds,Ax

           pop Dx
           pop Ax
           push Ds
           push Dx

           add Ax,Selector
           mov Ds,Ax

@Pokrac:
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Di,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed    { skok=ne }
           inc Dl
           jmp @SwitchVRAMBuffer

@finallyend:
           mov Ax,Ds
           pop Dx          { vytahni ze zasobniku nejprve MemoryBanku }
           pop Ds          { a pote pascalovsky Ds }
           mov MemoryBanka,Dl
           cmp AddX,0      { ma se k offsetu pricist nejaka hodnota ? }
           je @No_Adding   { (to pro pripad definovaneho okna X-ove mensiho
                              nez ulozeneho obrazku) }
           mov Dx,AddX
           add Si,Dx
           jnc @No_Adding
           add Ax,Selector
@No_Adding:
           mov Offsets,Si  { aktualizace promennych }
           mov Segment,Ax
      end;
      Inc(y1);
      if (Direction=0) then Inc(y) else Dec(y);
   end;
  end;
end;

{ ***** }
procedure XPutImage(X1,Y1,XSize,YSize,Segment,Offsets:Word);
{
}
var AddX,PomocnaX,PomocnaY,Priznak,Handle:Word;
    X,Y,X2,Y2,X3,Y3:Integer;
    RozdilX,Selector:Word;
begin
if Segment>0 then begin
     Selector:=SelectorInc;
     asm
       mov Ax,Segment; mov Es,Ax; mov Si,Offsets
       mov Bx,Es:[Si]; inc Si; inc Si
       mov Cx,Es:[Si]; inc Si; inc Si
       mov Offsets,Si; mov PomocnaX,Bx; mov PomocnaY,Cx
     end;
     X2:=PomocnaX+X1; Y2:=PomocnaY+Y1;
     asm
       mov Ax,X2
       mov X3,Ax
       mov Ax,VRam
       mov Es,Ax

      { upraveni max. hodnot }
       mov Cx,X1
       cmp MaximalniX,Cx
       jae @1
       mov Ax,MaximalniX
       mov X1,Ax
@1:
       mov Cx,X2
       cmp MaximalniX,Cx
       jae @2
       mov Ax,MaximalniX
       mov X2,Ax
       mov X3,Ax
@2:
       mov Ax,Y1
       cmp MaximalniY,Ax
       jae @3
       mov Ax,MaximalniY
       mov Y1,Ax
@3:
       mov Ax,Y2
       cmp MaximalniY,Ax
       jae @1dal
       mov Ax,MaximalniY
       mov Y2,Ax
       mov Y3,Ax
{ relativne v okne ... }
@1dal:
       mov Ax,RelX
       add X1,Ax
       add X2,Ax
       mov Ax,RelY
       add Y1,Ax
       add Y2,Ax
{ }
       mov Ax,Y2
       mov Y3,Ax
       mov Ax,X2
       mov X3,Ax

{ porovnani hodnot X1,X2 a Y1,Y2 }
       mov Ax,X1
       cmp X3,Ax
       jae @OK1
       mov X1,Bx
       mov X3,Ax
@OK1:
       mov Ax,Y1
       cmp Y3,Ax
       jae @OK2
       mov Cx,Y3
       mov Y1,Cx
       mov Y3,Ax
@OK2:
     end;
     AddX:=PomocnaX-(X3-X1);
     PomocnaX:=X3; PomocnaY:=Y3;
     RozdilX:=PomocnaX-XSize-X1; PomocnaX:=XSize; PomocnaY:=YSize;
     Y:=Y1;{+PomocnaY;{} Y1:=0;

  while (Y1 <= PomocnaY) do begin
      X:=X1;
      asm
{ v Ds:Si jsou ulozeny hodnoty Segment,Offsets (zdrojove informace)
  v Es:Di je ulozena adresa ukladaneho bodu ve VRAM
  v Bx je promenna PomocnaX
  v Cx je ulozena promenna X
}
           mov Cx,x          { nacteni patricnych hodnot drive, nez bude }
           mov Ax,y          { zmenen registr Ds a promenne tak budou }
           mov Bx,PomocnaX   { nedostupne }
           mov Di,MaxX
           push Ds           { ulozeni skutecneho dat. segmentu }
           mov Dl,MemoryBanka
           xor Dh,Dh
           push Dx           { ulozeni hodnoty MemoryBanka }
           cld

           mov Dx,VRam
           mov Es,Dx
           mov Si,Offsets
           mov Ds,Segment

           mul Di            { vypocet adresy pro dany radek }
           add Ax,Cx
           jnc @No_Inc2
           inc Dl
@No_Inc2:
           mov Di,Ax
           jmp @No_Inc

@No_Inc:
           pop Ax   { zmena video bufferu; v Ax se nacte obsah promenne }
           push Ax  { MemoryBanka a ihned se zase ulozi }
           cmp Dl,Al
           je @Pokracuj
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
@Pokracuj:
           mov Cx,0
@NoSpeed:
           movsb     { presun dat z pameti do VRam }
           cmp Si,0d       { dostali jsme se v pameti na konec segmentu ? }
           je @Inc_Segment { skok=ano }
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Di,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed   { skok=ne }
           inc Dl
           { konec VRAM }
@SwitchVRAMBuffer:
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
           jmp @NoSpeed

@Inc_Segment:              { konec aktualniho segmentu - nastav dalsi cast}
           pop Dx          { Memory banka }
           pop Ax          { Ds registr }

           push Ds         { stara Ds hodnota }
           push Dx         { Memory banka }
           mov Ds,Ax

           pop Dx
           pop Ax
           push Ds
           push Dx

           add Ax,Selector
           mov Ds,Ax

@Pokrac:
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Di,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed    { skok=ne }
           inc Dl
           jmp @SwitchVRAMBuffer

@finallyend:
           mov Ax,Ds
           pop Dx          { vytahni ze zasobniku nejprve MemoryBanku }
           pop Ds          { a pote pascalovsky Ds }
           mov MemoryBanka,Dl
           cmp AddX,0      { ma se k offsetu pricist nejaka hodnota ? }
           je @No_Adding   { (to pro pripad definovaneho okna X-ove mensiho
                              nez ulozeneho obrazku) }
           mov Dx,AddX
           add Si,Dx
           jnc @No_Adding
           add Ax,Selector
@No_Adding:
           mov Offsets,Si  { aktualizace promennych }
           mov Segment,Ax
      end;
      Inc(y1); Inc(y);
      if ((65535-RozdilX) >= Offsets) then begin
         Offsets:=Offsets+RozdilX;
      end else begin
         Inc(Segment,SelectorInc);
         Inc(Offsets,RozdilX);
      end;
   end;
  end;
end;

{ ***** }
procedure PutImage2(X1,Y1,Segment,Offsets:Word; Direction:Word);
{ ulozi obraz z daneho ukazatele Segment-Offsets na obrazovku
  je-li Direction = 0, provede se normalni ulozeni obrazku odshora dolu,
  jinak odspodu nahoru; ignoruje cernou barvu predlohy
}
var AddX,PomocnaX,PomocnaY,Priznak,Handle:Word;
    X,Y,X2,Y2,X3,Y3:Integer;
    Selector:Word;
begin
if Segment>0 then begin
     Selector:=SelectorInc;
     asm
       mov Ax,Segment; mov Es,Ax; mov Si,Offsets
       mov Bx,Es:[Si]; inc Si; inc Si
       mov Cx,Es:[Si]; inc Si; inc Si
       mov Offsets,Si; mov PomocnaX,Bx; mov PomocnaY,Cx
     end;
     X2:=PomocnaX+X1; Y2:=PomocnaY+Y1;
     asm
       mov Ax,X2
       mov X3,Ax
       mov Ax,VRam
       mov Es,Ax

      { upraveni max. hodnot }
       mov Cx,X1
       cmp MaximalniX,Cx
       jae @1
       mov Ax,MaximalniX
       mov X1,Ax
@1:
       mov Cx,X2
       cmp MaximalniX,Cx
       jae @2
       mov Ax,MaximalniX
       mov X2,Ax
       mov X3,Ax
@2:
       mov Ax,Y1
       cmp MaximalniY,Ax
       jae @3
       mov Ax,MaximalniY
       mov Y1,Ax
@3:
       mov Ax,Y2
       cmp MaximalniY,Ax
       jae @1dal
       mov Ax,MaximalniY
       mov Y2,Ax
       mov Y3,Ax
{ relativne v okne ... }
@1dal:
       mov Ax,RelX
       add X1,Ax
       add X2,Ax
       mov Ax,RelY
       add Y1,Ax
       add Y2,Ax
{ }
       mov Ax,Y2
       mov Y3,Ax
       mov Ax,X2
       mov X3,Ax

{ porovnani hodnot X1,X2 a Y1,Y2 }
       mov Ax,X1
       cmp X3,Ax
       jae @OK1
       mov X1,Bx
       mov X3,Ax
@OK1:
       mov Ax,Y1
       cmp Y3,Ax
       jae @OK2
       mov Cx,Y3
       mov Y1,Cx
       mov Y3,Ax
@OK2:
     end;
     AddX:=PomocnaX-(X3-X1);
     PomocnaX:=X3; PomocnaY:=Y3;
     Y:=Y1;
     if (Direction<>0) then  { ulozeni odspodu nahoru }
        Y:=PomocnaY;

  while (Y1 <= PomocnaY) do begin
      X:=X1;
      asm
{ v Ds:Si jsou ulozeny hodnoty Segment,Offsets (zdrojove informace)
  v Es:Di je ulozena adresa ukladaneho bodu ve VRAM
  v Bx je promenna PomocnaX
  v Cx je ulozena promenna X
}
           mov Cx,x          { nacteni patricnych hodnot drive, nez bude }
           mov Ax,y          { zmenen registr Ds a promenne tak budou }
           mov Bx,PomocnaX   { nedostupne }
           mov Di,MaxX
           push Ds           { ulozeni skutecneho dat. segmentu }
           mov Dl,MemoryBanka
           xor Dh,Dh
           push Dx           { ulozeni hodnoty MemoryBanka }
           cld

           mov Dx,VRam
           mov Es,Dx
           mov Si,Offsets
           mov Ds,Segment

           mul Di            { vypocet adresy pro dany radek }
           add Ax,Cx
           jnc @No_Inc2
           inc Dl
@No_Inc2:
           mov Di,Ax
           jmp @No_Inc

@No_Inc:
           pop Ax   { zmena video bufferu; v Ax se nacte obsah promenne }
           push Ax  { MemoryBanka a ihned se zase ulozi }
           cmp Dl,Al
           je @Pokracuj
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
@Pokracuj:
           cmp Di,64255
           ja @NoSpeed{}
           cmp Si,64255
           ja @NoSpeed
{ "rychla varianta" }
           sub Bx,Cx
           mov Cx,Bx
           inc Cx
@again:    mov Al,Ds:[Si]
           cmp Al,0
           je @Skip
           mov Es:[Di],Al { presun dat z pameti do VRam }
@Skip:
           inc Di
           inc Si
           loop @again
           jmp @finallyend{ skok=ano, ukonci }

@NoSpeed:
@again2:   mov Al,Ds:[Si]
           cmp Al,0
           je @Skip2
           mov Es:[Di],Al { presun dat z pameti do VRam }
@Skip2:
           inc Di
           inc Si
           cmp Si,0d       { dostali jsme se v pameti na konec segmentu ? }
           je @Inc_Segment { skok=ano }
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Di,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed   { skok=ne }
           inc Dl
           { konec VRAM }
@SwitchVRAMBuffer:
           xor  Dh,Dh
           pop  Ax   { vyber MemoryBanku ze zasobniku }
           push Dx   { uloz novou hodnotu }
           mov Ax,4f05h
           Int IntNum
           jmp @NoSpeed

@Inc_Segment:              { konec aktualniho segmentu - nastav dalsi cast}
           pop Dx          { Memory banka }
           pop Ax          { Ds registr }

           push Ds         { stara Ds hodnota }
           push Dx         { Memory banka }
           mov Ds,Ax

           pop Dx
           pop Ax
           push Ds
           push Dx

           add Ax,Selector
           mov Ds,Ax

@Pokrac:
           inc Cx          { nyni testovani, zda radek cely vykreslen }
           cmp Bx,Cx
           jnae @finallyend{ skok=ano, ukonci }
           cmp Di,0        { dostali jsme se na konec VRam ? }
           jnz @NoSpeed    { skok=ne }
           inc Dl
           jmp @SwitchVRAMBuffer

@finallyend:
           mov Ax,Ds
           pop Dx          { vytahni ze zasobniku nejprve MemoryBanku }
           pop Ds          { a pote pascalovsky Ds }
           mov MemoryBanka,Dl
           cmp AddX,0      { ma se k offsetu pricist nejaka hodnota ? }
           je @No_Adding   { (to pro pripad definovaneho okna X-ove mensiho
                              nez ulozeneho obrazku) }
           mov Dx,AddX
           add Si,Dx
           jnc @No_Adding
           add Ax,Selector
@No_Adding:
           mov Offsets,Si  { aktualizace promennych }
           mov Segment,Ax
      end;
      Inc(y1);
      if (Direction=0) then Inc(y) else Dec(y);
   end;
  end;
end;

{ ***** }
procedure GetMemory(Bytes:LongInt; var Segment,Offsets:Word);
{ rezervuje pamet o velikosti Bytes; pri chybe vraci v promenne Segment
  cislo 0;
  Jde-li o alokaci pameti pod 65520 bytu, alokuje se klasicky pascalovsky
  s pomoci GetMem; jde-li o blok vetsi, zarovna se na cely nasobek 16kB
  a cely pozadavek je pak uspokojen z vlastni haldy, alokovane
  volanim AllocateGlobalMemory
}
var PomUk:Pointer;
    Pomocna, Pomocna2:LongInt;
    Konec:Boolean;
    I,J:Word;
begin
   Segment:=0; Offsets:=0;
   if (Bytes > 65520) then begin { alokovani vlastnim zpusobem }
      { nejprve zarovname na nasobek 16Kb }
      if (Bytes < 65536) then Bytes:=65536;
      Pomocna:=((Bytes mod 65536) div 16384)*16384;
      if (Bytes mod 16384 <> 0) then Inc(Pomocna,16384);
      Bytes:=((Bytes shr 16) shl 16); { div 65536 * 65536 }
      Inc(Bytes,Pomocna);
      { nyni hledame v poli, zda je mozne pozadavek uspokojit }
      I:=1; Konec:=False;
      while ((I <= FMIndex) and (not Konec)) do with (FreeMemory[I]) do begin
         if (Length >= Bytes) then begin { success! }
           Konec:=True;
           Segment:=SegmentOrg; Offsets:=OffsetOrg;
           { nyni je treba pamet odepsat z tabulky }
           Pomocna:=Bytes div 16384; { pozadavek rozdelim na 16kb stranky }
           if (Bytes mod 16384 <> 0) then begin
              Pomocna:=Pomocna; { error trap - for debugging only }
           end;
           Pomocna2:=OffsetOrg div 16384;
           { kolik 16kB stranek zbyva do konce segmentu ? }
           if (OffsetOrg mod 16384 <> 0) then begin
              Pomocna2:=Pomocna2; { error trap - for debugging only }
           end;
           { nyni zarovnam na cely segment (segment = 4 stranky) }
           Pomocna:=Pomocna-(4-Pomocna2);
           Inc(SegmentOrg,SelectorInc); OffsetOrg:=0;
           { pripocitani zbylych celych segmentu }
           Inc(SegmentOrg,SelectorInc*(Pomocna shr 2));
           { pripocitani pripadneho neceleho segmentu }
           if (Pomocna mod 4 <> 0) then OffsetOrg:=(Pomocna mod 4) * 16384;
           Dec(Length,Bytes);
         end else Inc(I);
      end;
   end else begin { alokovani klasicky pascalovsky }
      if ((Bytes = 1028) or (Bytes = 1448)) then begin
         if ((Bytes = 1028) and (Mem1028bIndex <= MaxMem1028bIndex2))
         then begin
            Segment:=MemArray1028b^[Mem1028bIndex].S;
            Offsets:=MemArray1028b^[Mem1028bIndex].O;
            Inc(Mem1028bIndex);
         end else
          if ((Bytes = 1448) and (Mem1448bIndex <= MaxMem1448bIndex2)) then begin
             Segment:=MemArray1448b^[Mem1448bIndex].S;
             Offsets:=MemArray1448b^[Mem1448bIndex].O;
             Inc(Mem1448bIndex);
          end else begin
             GetMem(PomUk,Word(Bytes));
             if (PomUk <> Nil) then begin
             { success! }
               Segment:=Seg(PomUk^); Offsets:=Ofs(PomUk^);
             end;
          end;
      end else begin
        GetMem(PomUk,Word(Bytes));
        if (PomUk <> Nil) then begin
        { success! }
           Segment:=Seg(PomUk^); Offsets:=Ofs(PomUk^);
        end;
      end;
   end;
end;

{ ***** }
procedure PutMemory(Bytes:Longint; var Segment,Offsets:Word);
{ opak GetMemory }
var PomUk:Pointer;
    S,O,S2,O2:Word;
begin
   if (Bytes > 65520) then begin { alokovani vlastnim zpusobem }
     if (FMIndex < MaxFMIndex) then begin { v poli je jeste misto }
       Inc(FMIndex);
       with (FreeMemory[FMIndex]) do begin
          SegmentOrg:=Segment; OffsetOrg:=Offsets; Length:=Bytes;
       end;
     end;
   end else begin { alokovani klasicky pascalovsky }
      S:=Seg(PomUk); O:=Ofs(PomUk); S2:=Segment; O2:=Offsets;
      asm
       mov Ax,S; mov Es,Ax; mov Di,O;
       mov Ax,O2; mov Es:[Di],Ax; add Di,2;
       mov Ax,S2; mov Es:[Di],Ax;
      end;
      if (PomUk <> Nil) then FreeMem(PomUk,Bytes);
   end;
   Segment:=0; Offsets:=0;
end;

{ ***** }
function GetFreeMem:LongInt;
{ vraci nejvetsi volnou pamet }
var Length,MaxLength:LongInt;
    I:Integer;
begin
   MaxLength:=0;
   if FMIndex>=1 then begin
      for I:=1 to FMIndex do begin
          Length:=FreeMemory[I].Length;
          if Length>MaxLength then MaxLength:=Length;
      end;
   end;
   GetFreeMem:=MaxLength;
end;

{ ***** }
procedure ClearScreen; assembler;
{ vymaze obrazovku }
var MaxBanka:Byte;
asm
     mov Ax,MaxX
     mul MaxY
     mov Bx,1024
     div Bx
     mov Cx,Vram
     mov Es,Cx
     mov Dl,64
     div Dl
     inc Al
     mov MaxBanka,Al
     mov Ah,12h
     mov Bl,36h
     mov al,1
     Int IntNum
     mov Dl,0
     mov Di,0
@31:
     mov Bx,Dx
     mov MemoryBanka,Dl
     mov Ax,4f05h
     Int IntNum
@Pokracovat:
     mov Ax,0
     mov Cx,32767{65535}
     cld
 rep stosw
     stosb
     stosb
{ **** }
    inc Dl
@dal:
    cmp Dl,MaxBanka
    jne @31
    mov Ah,12h
    mov Bl,36h
    mov al,0
    Int 10h
end;

{ ***** }
procedure SaveRGB(BeginNumber,EndNumber:Byte; Way:String);
{ ulozi do souboru, k nemuz je cesta Way RGB registry od barvy BeginNumber
  do barvy EndNumber. IO_Result vraciv 0, je-li vse OK }
label Konec;
var S,O,Segment,Offsets:Word;
    Pomocna:Word;
    RGBFile:File;
    Buff:Pointer;
    Buffer:array[1..800] of Byte;
begin
   Segment:=Seg(Buffer); Offsets:=Ofs(Buffer);
   if EndNumber<BeginNumber then begin
      Pomocna:=EndNumber;
      EndNumber:=BeginNumber;
      BeginNumber:=Pomocna;
   end;
   Pomocna:=EndNumber-BeginNumber+1;
   asm
      mov Ah,10h
      mov Al,17h
      mov Bl,BeginNumber
      mov Bh,0
      mov Cx,Pomocna
      mov Dx,Segment
      mov Es,Dx
      mov Dx,Offsets
      Int 10h
   end;
   S:=Seg(Buff); O:=Ofs(Buff);
   asm
     mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
     mov Cx,Segment; mov Es:[Si],Bx; add Si,2
     mov Es:[Si],Cx
   end;
   Assign(RGBFile,Way);
   Rewrite(RGBFile,2);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   BlockWrite(RGBFile,Pomocna,1);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;

   Reset(RGBFile,1);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   Seek(RGBFile,2);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   BlockWrite(RGBFile,Buff^,Pomocna*3);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;

   Close(RGBFile);
Konec:
end;

{ ***** }
procedure LoadRGB(BeginNumber:Byte; Way:String);
{ vybere ze souboru, k nemuz je cesta Way RGB registry a nastavi je od
  barvy BeginNumber. IO_Result vraci 0, je-li vse OK }
label Konec;
var S,O,Segment,Offsets:Word;
    Pomocna:Word;
    Buff:Pointer;
    RGBFile:File;
    Buffer:array[1..800] of Byte;
begin
   Segment:=Seg(Buffer); Offsets:=Ofs(Buffer);
   S:=Seg(Buff); O:=Ofs(Buff);
   Assign(RGBFile,Way);
   Reset(RGBFile,2);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   BlockRead(RGBFile,Pomocna,1);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   asm
     mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
     mov Cx,Segment; mov Es:[Si],Bx; add Si,2
     mov Es:[Si],Cx
   end;
   Reset(RGBFile,1);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   Seek(RGBFile,2);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   BlockRead(RGBFile,Buff^,Pomocna*3);
   IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   Close(RGBFile);
   if Pomocna>(255-BeginNumber) then Pomocna:=255-BeginNumber+1;
   asm
      mov Ah,10h
      mov Al,12h
      mov Bl,BeginNumber
      mov Bh,0
      mov Cx,Pomocna
      mov Dx,Segment
      mov Es,Dx
      mov Dx,Offsets
      Int 10h
   end;
Konec:
end;

{ ***** }
procedure BMPInit;
label Konec;
var Pomocna:Word;
    Help:Byte;
    Zacatek:LongInt;
    I:Integer;

begin
   Help:=0;
   Seek(ImageFile,0);
   for I:=0 to 53 do BlockWrite(ImageFile,Help,1); { vynulovani }

      Seek(ImageFile,0);
      Pomocna:=19778;     { identifikace 'BM' }
      BlockWrite(ImageFile,Pomocna,2);
      IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
      Seek(ImageFile,10);
      Zacatek:=1078;
      BlockWrite(ImageFile,Zacatek,4); { souradnice zacatku obrazku }
      IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
      Seek(ImageFile,28);
      Pomocna:=8;
      BlockWrite(ImageFile,Pomocna,2); { tento word udava pocet bitu na bod }
      IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
      Seek(ImageFile,14);
      Pomocna:=40;
      BlockWrite(ImageFile,Pomocna,2); {tento word velikost BitmapInfoHeader}
      IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
      Seek(ImageFile,26);
      Pomocna:=1;
      BlockWrite(ImageFile,Pomocna,2); {musi byt nastaveno na 1}
      IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
      Seek(ImageFile,46);
      Zacatek:=256;
      BlockWrite(ImageFile,Zacatek,4); { pocet RGB slozek }
      IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
Konec:
end;

{ ***** }
function OpenImage( Way:String; OpenType:Word ):Word;
{ Otevre pro praci obrazkovy soubor na disku dle parametru OpenType:
  0 = NoCreateNew .. pri neexistujicim hlasi chybu 2
  1 = CreateNew .. neexistuje-li soubor, vytvori jej
  Sama vraci hodnoty:
  - nastaveny nejmene vyznamny bit - soubor existuje; nenastaveny - nove
    vytvoren (1)
  - nastaveny druhy bit zprava - format GBM (2)
  - nastaveny treti bit zprava - format BMP (4)

  IO_Result    IO_ResultString
   30       Soubor neni bitmap (*.BMP)
   31       Soubor neni *.GBM
   32       Nejde o 256 - barevny *.BMP
   33       Nelze pouzit komprimovany BMP format
}
label Konec;
var Help:Word;
    I:Integer;
    Pom:LongInt;
begin
   if (ImageAttribute <> 255) then Close(ImageFile);
   Assign(ImageFile,Way);
   Reset(ImageFile,1);
   IO_Result:=IOResult;
   IO_ResultString:='';    { otevreni souboru }

   if (IO_Result = 1) or (IO_Result > 2) then GoTo Konec; { 'tvrda chyba' }

   Delete(Way,1,Length(Way)-3); { podle pripony zjisti typ (BMP nebo GBM) }
   Way[1]:=UpCase(Way[1]); Way[2]:=UpCase(Way[2]); Way[3]:=UpCase(Way[3]);

   if (IO_Result = 2) and (OpenType = CreateNew) then begin
   { neexistujici soubor , vytvor jej }
      Rewrite(ImageFile,1);
      IO_Result:=IOResult;
      if IO_Result<>0 then GoTo Konec;    { 'tvrda chyba' }
      if (Way='BMP') then begin      { BITMAP }
         OpenImage := 5;
         BMPInit;
         if IO_Result<>0 then GoTo Konec;
         ImageAttribute:=81;   { novy BMP }

      end else begin        { GBM }
         OpenImage := 3;
         Seek(ImageFile,0);
         Help:=$4247;     { identifikace 'GB' }
         BlockWrite(ImageFile,Help,2);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Help:=$444d;     { identifikace 'MP' }
         BlockWrite(ImageFile,Help,2);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Seek(ImageFile,4);
         Help:=0;     { pocet aktualnich obrazku }
         BlockWrite(ImageFile,Help,2);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Help:=500;     { max. pocet ulozitelnych obrazku }
         BlockWrite(ImageFile,Help,2);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Help:=30;     { Delka jednoho bloku udaju }
         BlockWrite(ImageFile,Help,1);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

         ImageAttribute:=80;   { novy GBM }
      end;

   end else begin
     if (IO_Result = 2) and (OpenType = NoCreateNew) then
        GoTo Konec { neexistujici soubor , hlas chybu }
     else begin
        { otevreni probehlo OK }
        if (Way='BMP') then begin      { BITMAP }
           OpenImage := 4;
           BlockRead(ImageFile,Help,2);
           IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
           if Help<>19778 then begin   { nejde o *.BMP }
              IO_Result:=30; IO_ResultString:='Soubor neni bitmap (*.BMP)';
              GoTo Konec;
           end else begin    {jde o *.BMP }
              Seek(ImageFile,28);
              BlockRead(ImageFile,Help,2); { tento word udava pocet bitu na bod }
              IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
              if Help<>8 then begin        { musi byt roven 8 }
                 IO_Result:=32; IO_ResultString:='Nejde o 256 - barevny *.BMP';
                 GoTo Konec;
              end;
              Seek(ImageFile,30);
              BlockRead(ImageFile,Help,2); { tento word udava pripadnou kompresi }
              IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
              if Help = 1 then begin             { komprimovan }
                 IO_Result:=33; IO_ResultString:='Komprimovany BMP format - nemozno pouzit';
                 GoTo Konec;
              end else ImageAttribute:=1;        { nekomprimovan }
           end;  {jde o *.BMP }

        end else begin              { GBM }
           OpenImage := 2;
           BlockRead(ImageFile,Help,2);
           IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
           if Help<>$4247 then begin   { nejde o *.GBM }
              IO_Result:=31; IO_ResultString:='Soubor neni *.GBM';
           end else begin
              BlockRead(ImageFile,Help,2);
              IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
              if (Help<>$504d) and (Help <> $444d) then begin   { nejde o *.GBM }
                 IO_Result:=31; IO_ResultString:='Soubor neni *.GBM';
              end else
                 if (Help = $504d) then  ImageAttribute:=0 { jde o *.GBMP }
                 else ImageAttribute:=100; { jde o *.GBMD }
           end;
        end;   { GBM }
     end; {}
   end;
Konec:
   if (IO_Result<>0) then ImageAttribute:=255
   else ImageFileWay:=Way;
end;

{ ***** }
procedure SaveImageGBM(Segment,Offsets:Word; Name:String);
{
  Je-li Segment=0, neudela nic.
  Nakopiruje  obrazek z predem alokovane pameti na disk. Je-li to BMP,
  hlasi chybu cislo 42.
  Je-li obrazek GBM, dle parametru Name se rozhodne, pod jakym jmenem se
  obrazek ulozi. Existuje-li jiz toto jmeno, obrazek se prepise.
  Je-li IO_Result=35 'Soubor s obrazky je naplnen (max. 100) ' ( pouze GBM )
  Je-li IO_Result=40 'Soubor s obrazkem nebyl otevren' (s pomoci OpenImage)
  Je-li IO_Result=42 'Chyba v grafickem formatu'
}

label Konec, Znovu;
const IdHeadLength=9; { delka v bytech uvodni identifikacni hlavicky }
      HeadLength=30; { sirka informacni hlavicky o kazdem obrazku }
var S,O,Remainder:Word;
    Segment2,Offsets2,HeadPos,Decrement,Width,Delka2,Delka3,Pomocna:Word;
    Buff:Pointer;
    Help,Help2:Word;
    X,Y,Zacatek,Delka:LongInt;
    I,J:Integer;
    Retezec:String[8];
begin
  LogPage:=4;
  if (ImageAttribute<>255) and (Segment<>0) then begin { neotevren or pamet }
    if (ImageAttribute=0) or (ImageAttribute=80) or (ImageAttribute=41) or
       (ImageAttribute=100) then begin
    { ***  GBM *** }
       Seek(ImageFile,4);
       IO_Result:=IOResult;
       if (ImageAttribute = 0) then begin
         Help:=0; Help2:=0;
         BlockRead(ImageFile,Help,1); { pocet ulozenych obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         BlockRead(ImageFile,Help2,1); { max. pocet obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         if (Help >= Help2) then begin  { GBM pole je naplnene }
            IO_Result:=35;
            IO_ResultString:='Dosazen maximalni pocet obrazku v souboru';
            GoTo Konec;
         end;
       end else begin
         BlockRead(ImageFile,Help,2); { pocet ulozenych obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         BlockRead(ImageFile,Help2,2); { max. pocet obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         if (Help >= Help2) then begin  { GBM pole je naplnene }
            IO_Result:=35;
            IO_ResultString:='Dosazen maximalni pocet obrazku v souboru';
            GoTo Konec;
         end;
       end;
       HeadPos:=Help*HeadLength+IdHeadLength;
       { zacatek identifikacni hlavicky obrazku }

       Retezec:=''; I:=IdHeadLength; J:=0;  { priznak neprepsani obrazku }
       while (I<=(Help*HeadLength)) and (Help<>0) do begin
       { Hledej, zda obrazek jiz neexistuje }
         Seek(ImageFile,I);
         BlockRead(ImageFile,Retezec,9);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         if (Retezec = Name) then begin   { konec, rovnaji se }
            HeadPos:=I;  { novy zacatek identifikacni hlavicky obrazku }
            I:=Help2*HeadLength+IdHeadLength;
            J:=1;
         end else I:=I+HeadLength;  { nerovnaji se, jdi dal }
       end;
       if (J = 0) then begin  { obrazek se nebude prepisovat }
          Help:=Help+1;
          Seek(ImageFile,4);  { zvyseni aktualniho poctu obrazku }
          if (ImageAttribute = 0) then begin
            BlockWrite(ImageFile,Help,1);
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          end else begin
            BlockWrite(ImageFile,Help,2);
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          end;
          Seek(ImageFile,HeadPos); { ulozeni nazvu obrazku }
          BlockWrite(ImageFile,Name,9);
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       end;

       asm
         mov Ax,Segment; mov Es,Ax; mov Si,Offsets
         mov Bx,Es:[Si]; inc Si; inc Si
         mov Cx,Es:[Si]; inc Si; inc Si
         mov Delka2,Bx; mov Delka3,Cx
       end;
       Delka2:=Delka2+1; Delka3:=Delka3+1;
       X:=Delka2; Y:=Delka3; Delka:=X*Y+4; { Delka obrazku }

       Seek(ImageFile,HeadPos+9);
       BlockWrite(ImageFile,Delka2,2); { ulozeni x-ove sirky obrazku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       BlockWrite(ImageFile,Delka3,2); { ulozeni y-ove sirky obrazku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       Seek(ImageFile,HeadPos+25); { ulozeni priznaku komprimovanosti }
       X:=0;
       BlockWrite(ImageFile,X,1); { puvodni komprimace, je jedno co tu je}
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       if (HeadPos = IdHeadLength) then  { 1. obrazek v souboru }
         Zacatek:=Help2*HeadLength+IdHeadLength+50
       else begin
         Seek(ImageFile,HeadPos+21-HeadLength);{ udaj o konci obrazku na disku }
         BlockRead(ImageFile,Zacatek,4);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Zacatek:=Zacatek+1; { zacatek obrazku na disku }
       end;
       Seek(ImageFile,HeadPos+17); { zacatek obrazku na disku }
       BlockWrite(ImageFile,Zacatek,4);
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

       { ***  vlastni ulozeni informace  *** }
       S:=Seg(Buff); O:=Ofs(Buff);
       { nastaveni ukazatele na zacatek obrazku v pameti }
       asm
         mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
         mov Cx,Segment; mov Es:[Si],Bl; inc Si; mov Es:[Si],Bh
         inc Si; mov Es:[Si],Cl; inc Si; mov Es:[Si],Ch; inc Si;
       end;
       Seek(ImageFile,Zacatek);
       { ukladani }

       Delka2:=Delka div 65536; Delka3:=Delka mod 65536;
       if (Delka2 > 0) then
         if (Delka3 > 65531) then begin
            Inc(Delka2); Delka3:=4-(65535-Delka3);
         end else Inc(Delka3,4);
       for I:=1 to Delka2 do begin  { ukladani celych bloku 65500 bytu }
         BlockWrite(ImageFile,Buff^,65488);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Offsets:=Offsets+65488;   { 1. cast ukladaneho 64kb bloku }
         asm   { posun hodnot ukazatele }
           mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
           mov Cx,Segment; mov Es:[Si],Bl; inc Si; mov Es:[Si],Bh
           inc Si; mov Es:[Si],Cl; inc Si; mov Es:[Si],Ch; inc Si;
         end;
         BlockWrite(ImageFile,Buff^,65536-Offsets);
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Inc(Segment,SelectorInc); Offsets:=0; { 2. cast ukladaneho 64kb bloku }
         asm    { zmen ukazatel v Buff }
            mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
            mov Cx,Segment; mov Es:[Di],Bx; add Di,2
            mov Es:[Di],Cx
         end;
       end;
       { ulozeni zbytku }
       BlockWrite(ImageFile,Buff^,Delka3);
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

       Zacatek:=FilePos(ImageFile);
       Zacatek:=Zacatek-1;{ v Zacatek je ulozen ukazatel na konec obrazku }
       Seek(ImageFile,HeadPos+21);
       BlockWrite(ImageFile,Zacatek,4); { ulozeni pozice konce obrazku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       if (ImageAttribute <> 0) then ImageAttribute:=100;

    end else begin
    { ***  BMP  *** }
        IO_Result:=42; IO_ResultString:='Chyba v grafickem formatu';
        GoTo Konec;
    end;  { BMP }
Konec:
  end else begin { if ImageAttribute=0 }
    if (ImageAttribute=255) then begin
        IO_Result:=40;
        IO_ResultString:='Soubor s obrazkem nebyl otevren';
    end;
 end;
end;

{ ***** }
procedure SaveImageBMP(Segment,Offsets:Word);
{
  Je-li Segment=0, neudela nic.
  Nakopiruje  obrazek z predem alokovane pameti na disk. Je-li to GBM,
  hlasi chybu cislo 42.
  Je-li IO_Result=35 'Soubor s obrazky je naplnen (max. 100) ' ( pouze GBM )
  Je-li IO_Result=38 'Nelze pouzit komprimaci' - (ve spojeni s Exp pameti)
  Je-li IO_Result=40 'Soubor s obrazkem nebyl otevren' (s pomoci OpenImage)
  Je-li IO_Result=42 'Chyba v grafickem formatu'
}

label Konec, Znovu;
const IdHeadLength=9; { delka v bytech uvodni identifikacni hlavicky }
      HeadLength=30; { sirka informacni hlavicky o kazdem obrazku }
var S,O,S2,O2,Remainder:Word;
    Segment2,Offsets2,HeadPos,Decrement,Width,Delka2,Delka3,Pomocna:Word;
    Buff:Pointer;
    Help,Help2:Byte;
    X,Y,Zacatek,Delka:LongInt;
    I,J:Integer;
    Retezec:String[8];
begin
  if (ImageAttribute<>255) and (Segment<>0) then begin { neotevren or pamet }
    if (ImageAttribute=0) or (ImageAttribute=80) or (ImageAttribute=41) then
    begin
    { ***  GBM *** }
       IO_Result:=42; IO_ResultString:='Chyba v grafickem formatu';
       GoTo Konec;

    end else begin
    { ***  BMP  *** }
       if (ImageAttribute=80) then begin  { novy BMP }

       end else begin    { stary BMP - prepis jej }
          Rewrite(ImageFile,1); { inicializace noveho obrazku }
          BMPInit;
          if IO_Result<>0 then GoTo Konec;
       end;
          GetMemory(10000,S2,O2);
          Segment2:=S2; Offsets2:=O2;
          if (Segment2 = 0) then begin
            IO_ResultString:='Nedostatek pomocne pameti'; IO_Result:=38;
            GoTo Konec;
          end;
          S:=Seg(Buff); O:=Ofs(Buff);
          asm
            mov Ah,10h
            mov Al,17h
            mov Bl,0        { pocatecni cislo barvy }
            mov Bh,0
            mov Cx,256      { pocet RGB slozek }
            mov Dx,Segment2
            mov Es,Dx
            mov Dx,Offsets2 { adresa ulozniho prostoru }
            Int 10h
          end;
          { vypocet skutecne RGB (zjistena RGB * 4) }
          asm
             mov Ax,Segment2; mov Es,Ax; mov Di,Offsets2;
             mov Cx,1024
@Opet:
             mov Al,Es:[Di]
             shl Al,2
             mov Es:[Di],Al
             inc Di
             loop @Opet
          end;

          { zacatek RGB bloku }
          Seek(ImageFile,54);      { 1. modra slozka }
          Delka:=256;
          for I:=1 to Delka do begin
             asm      { nastaveni ukazatele na 1.modrou slozku }
               mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets2
               add Bx,2
               mov Cx,Segment2; mov Es:[Di],Bx
               add Di,2; mov Es:[Di],Cx
             end;
             BlockWrite(ImageFile,Buff^,1); { uloz modrou slozku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             asm  { buff ukazuje o 1 zpet }
                mov Ax,S; mov Es,Ax; mov Di,O
                mov Bx,Es:[Di];
                dec Bx; mov Es:[Di],Bx
             end;
             BlockWrite(ImageFile,Buff^,1); { uloz zelenou slozku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             asm  { buff ukazuje o 1 zpet }
                mov Ax,S; mov Es,Ax; mov Di,O;
                mov Bx,Es:[Di]
                dec Bx; mov Es:[Di],Bx
             end;
             BlockWrite(ImageFile,Buff^,1); { uloz cervenou slozku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             Help:=0;
             BlockWrite(ImageFile,Help,1);  { nulova slozka }
             Offsets2:=Offsets2+3;
          end;
          { RGB ULOZENO !!! }
          PutMemory(10000,S2,O2);

          Seek(ImageFile,18);
          asm
            mov Ax,Segment; mov Es,Ax; mov Di,Offsets
            mov Ax,Es:[Di]; mov Pomocna,Ax
          end;
          Pomocna:=Pomocna+1;
          BlockWrite(ImageFile,Pomocna,2); { sirka obrazku }
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          Decrement:=Pomocna mod 4; { + finta pro vypocet }
          Width:=(Pomocna div 4)*4; { zarovnana sirka obrazku }
          if (Decrement<>0) then Width:=Width+4;
          Decrement:=Width-Pomocna; { + zarovnani obrazku }
          Delka:=Pomocna;

          Seek(ImageFile,22);
          asm
            mov Ax,Segment; mov Es,Ax; mov Di,Offsets; add Di,2;
            mov Ax,Es:[Di]; mov Pomocna,Ax
          end;
          Pomocna:=Pomocna+1;
          BlockWrite(ImageFile,Pomocna,2); { vyska obrazku }
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          Delka:=Delka*Pomocna;

          Zacatek:=1078+Delka;   { ulozeni delky obrazku }
          Seek(ImageFile,2);
          BlockWrite(ImageFile,Zacatek,4);

          Seek(ImageFile,1078);  { nastaveni na zacatek }
          { nahravani }

          S:=Seg(Buff); O:=Ofs(Buff); Inc(Offsets,4);
          asm  { nastaveni ukazatele na zacatek dat v pameti }
            mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
            mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
            mov Es:[Di],Cx
            mov Es, Cx
          end;

          { VLASTNI UKLADANI }
          if Decrement<>0 then begin   { zarovnany obrazek }
            if (Delka<65536) then begin
              for I:=1 to Pomocna+1 do begin   { jednotlive bloky }
                 BlockWrite(ImageFile,Buff^,Width); { uloz radek }
                 IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
                 Offsets:=Offsets+Width-Decrement;  { odstran zarovnani }
                 Help:=0;
                 asm  { zmen ukazatel v Buff }
                   mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                   mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
                   mov Es:[Di],Cx
                 end;
              end;
            end else begin { blok vetsi nez 64kB }
                Remainder:=0; Inc(Pomocna);
Znovu:
                Delka2:=(65536-Remainder) div (Width-Decrement);
                { Delka2 = pocet celych radku, ukladanych do 64Kb }
                Remainder:=(65536-Remainder) mod (Width-Decrement);
                { Remainder = delka neceleho radku do 64kb }
                for I:=1 to Delka2 do begin
                   BlockWrite(ImageFile,Buff^,Width); { uloz radek }
                   IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
                   Offsets:=Offsets+Width-Decrement;  { odstran zarovnani }
                   asm  { zmen ukazatel v Buff }
                      mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                      mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
                      mov Es:[Di],Cx
                    end;
                   Dec(Pomocna);
                   if (Pomocna = 0) then GoTo Konec;
                end;
                BlockWrite(ImageFile,Buff^,Remainder);
                Inc(Segment,SelectorInc); Offsets:=0;
                { nyni je ulozeno celych 64kb }

                Remainder:=Width-Remainder;
                BlockWrite(ImageFile,Buff^,Remainder);
                Offsets:=Offsets+Remainder-Decrement;
                { odstran zarovnani }
                asm  { zmen ukazatel v Buff }
                   mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                   mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
                   mov Es:[Di],Cx
                end;
                Dec(Pomocna);
                if (Pomocna = 0) then GoTo Konec;
                GoTo Znovu;
              { nyni je ulozen i zbytek radku z predchozich 64Kb }
             end;

          end else begin  { rychle ulozeni - obrazek neni zarovnan }
            Delka2:=Delka div 65536; Delka3:=Delka mod 65536;
            if (Delka2 > 0) then
               if (Delka3 > 65531) then begin
                  Inc(Delka2); Delka3:=4-(65535-Delka3);
               end else Inc(Delka3,4);{}
            for I:=1 to Delka2 do begin
               BlockWrite(ImageFile,Buff^,65488); { uloz obrazek }
               IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
               Offsets:=Offsets+65488;  { 1. cast bloku 64kb }
               asm    { zmen ukazatel v Buff }
                 mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                 mov Cx,Segment; mov Es:[Di],Bx; add Di,2
                 mov Es:[Di],Cx
               end;
               BlockWrite(ImageFile,Buff^,65536-Offsets); { uloz obrazek }
               IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
               Inc(Segment,SelectorInc); Offsets:=0; { 2. cast bloku 64kb }
               asm    { zmen ukazatel v Buff }
                 mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                 mov Cx,Segment; mov Es:[Di],Bx; add Di,2
                 mov Es:[Di],Cx
               end;
            end;
            BlockWrite(ImageFile,Buff^,Delka3);
            IO_Result:=IOResult;
            if IO_Result<>0 then GoTo Konec;
          end;
          ImageAttribute:=1;

    end;  { BMP }
Konec:
  end else begin { if ImageAttribute=0 }
    if (ImageAttribute=255) then begin
        IO_Result:=40;
        IO_ResultString:='Soubor s obrazkem nebyl otevren';
    end;
 end;
end;

{ ***** }
procedure LoadImageGBM(Segment,Offsets:Word; Name:String; Pos:Word);
{
  Je-li Segment=0, neudela nic.
  Nahraje do predem alokovane pameti obrazek z disku.
  Je-li obrazek GBM, rozhoduje Name, ktery obr. se nahraje.
  Pos = pozice obrazku v hlavicce (Pos=3 .. 3.obrazek)
  Je-li Pos = 0, prohledava se s pomoci Name

  Je-li IO_Result=36 'V BMP souboru nenalezeny RGB slozky'
  Je-li IO_Result=37 'Obrazek s danym nazvem nenalezen' ( pouze GBM )
  Je-li IO_Result=38 'Nelze pouzit komprimaci' - (ve spojeni s Exp pameti)
  Je-li IO_Result=39 'Obrazek nelze nahrat' ( zrejme nove vytvoren )
  Je-li IO_Result=40 'Soubor s obrazkem nebyl otevren' (s pomoci OpenImage)
  Je-li IO_Result=42 'Chyba v grafickem formatu'
}
label Konec,Znovu;
const IdHeadLength=9; { delka v bytech uvodni identifikacni hlavicky }
      HeadLength=30; { sirka informacni hlavicky o kazdem obrazku }
var S,O, Remainder:Word;
    I,J:Integer;
    X,Y,HeadPos,Decrement,Width,Segment2,Offsets2,Pomocna:Word;
    Buff:Pointer;
    Retezec:String[90];
    Nekompr_Delka,Zacatek,Delka,Delka2,Delka3:LongInt;
    Help,Help2:Word;
begin
 if (ImageAttribute<>255) and (Segment<>0) then begin { neotevren or pamet }
  if (ImageAttribute=80) or (ImageAttribute=81) then begin { nove obrazky }
    IO_Result:=39; IO_ResultString:='Obrazek nelze nahrat';
  end else begin
    if (not InternalCache or CacheDataInvalid(ImageFileWay)) then
       Reset(ImageFile,1);
    if (ImageAttribute=0) or (ImageAttribute = 41) or
       (ImageAttribute=100)
    then begin
    { ***  GBM  *** }

       if (ImageAttribute=0) then begin
         Help:=0; Help2:=0;
         CacheSeek(ImageFile,4);
         CacheBlockRead(ImageFile,@Help,1); { pocet ulozenych obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         CacheBlockRead(ImageFile,@Help2,1); { max. pocet obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       end else begin
         CacheSeek(ImageFile,4);
         CacheBlockRead(ImageFile,@Help,2); { pocet ulozenych obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         CacheBlockRead(ImageFile,@Help2,2); { max. pocet obrazku }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       end;

       Retezec:='';
       if (Pos <> 0) then begin { je primo zadana pozice }
          J:=1; { priznak nalezeni obrazku }
          I:=(Pos-1)*HeadLength+IdHeadLength;
          CacheSeek(ImageFile,I);
          CacheBlockRead(ImageFile,@Retezec,9);
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          if (Retezec = Name) then begin   { konec, rovnaji se }
                HeadPos:=I;  { zacatek identifikacni hlavicky obrazku }
                if (I = IdHeadLength) then Help:=1; { prvni obrazek }
                I:=Help2*HeadLength+IdHeadLength;
          end else J:=0; { nerovnaji se, hlas chybu }
       end else begin { je zadano pouze jmeno }
          I:=IdHeadLength;
          J:=0; { priznak nalezeni obrazku }
          while (I<=(Help*HeadLength)) and (Help<>0) do begin
          { Hledej obrazek }
             CacheSeek(ImageFile,I);
             CacheBlockRead(ImageFile,@Retezec,9);
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             if (Retezec = Name) then begin   { konec, rovnaji se }
                HeadPos:=I;  { zacatek identifikacni hlavicky obrazku }
                if (I = IdHeadLength) then Help:=1; { prvni obrazek }
                I:=Help2*HeadLength+IdHeadLength;
                J:=1;
             end else I:=I+HeadLength;  { nerovnaji se, jdi dal }
          end;
       end;
       if (J = 0) then begin  { chyba, obrazek nebyl nalezen }
         IO_Result:=37; IO_ResultString:='Obrazek s danym nazvem nenalezen';
         GoTo Konec;
       end;

       CacheSeek(ImageFile,HeadPos+9);
       CacheBlockRead(ImageFile,@X,2); { X-ova velikost }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

       CacheBlockRead(ImageFile,@Y,2); { Y-ova velikost }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       Nekompr_Delka:=LongInt(X) * LongInt(Y) + 4;

       CacheSeek(ImageFile,HeadPos+17);
       CacheBlockRead(ImageFile,@Zacatek,4); { pocatek obrazku na disku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       CacheBlockRead(ImageFile,@Delka,4); { konec obrazku na disku }
        IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       Delka:=Delka-Zacatek+1; { skutecna delka obrazku }
       if (Delka < 0) then begin
          IO_Result:=39;
          IO_ResultString:='Obrazek nelze nahrat';
          GoTo Konec;
       end;

       { ***  vlastni nahravani  *** }
       CacheSeek(ImageFile,HeadPos+25);
       Help:=0;
       CacheBlockRead(ImageFile,@Help,1); { komprimace }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

       Delka2:=Delka div 65536; Delka3:=Delka mod 65536;
       if (Delka2 > 0) then
         if (Delka3 > 65531) then begin
            Inc(Delka2); Delka3:=4-(65535-Delka3);
         end else Inc(Delka3,4);

       S:=Seg(Buff); O:=Ofs(Buff);
       asm   { nastaveni Buff^ }
          mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
          mov Cx,Segment; mov Es:[Si],Bx; add Si,2
          mov Es:[Si],Cx
       end;
       CacheSeek(ImageFile,Zacatek);
       for I:=1 to Delka2 do begin
         CacheBlockRead(ImageFile,Buff,65488); { nahrej obrazek }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Offsets:=Offsets+65488;   { 1. cast bloku 64Kb }
         asm  { zvyseni ukazatele v Buff^ }
           mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
           mov Cx,Segment; mov Es:[Si],Bx; add Si,2
           mov Es:[Si],Cx
         end;
         CacheBlockRead(ImageFile,Buff,65536-Offsets); { nahrej obrazek }
         IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
         Inc(Segment,SelectorInc); Offsets:=0; { 2. cast bloku 64Kb }
         asm  { zvyseni ukazatele v Buff^ }
           mov Ax,S; mov Es,Ax; mov Si,O; mov Bx,Offsets
           mov Cx,Segment; mov Es:[Si],Bx; add Si,2
           mov Es:[Si],Cx
         end;
       end;
       CacheBlockRead(ImageFile,Buff,Delka3);
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

    end else begin
    { ***  BMP  *** }
       IO_Result:=42; IO_ResultString:='Chyba v grafickem formatu';
       GoTo Konec;
    end;  { BMP }
  end;    { obrazek lze nahrat }

Konec:
 end else begin { if ImageAttribute=0 }
    if (ImageAttribute=255) then begin
        IO_Result:=40;
        IO_ResultString:='Soubor s obrazkem nebyl otevren';
    end;
 end;
end;

{ ***** }
procedure LoadImageBMP(Segment,Offsets:Word; RGBs:Word);
{
  Je-li Segment=0, neudela nic.
  Nahraje do predem alokovane pameti obrazek z disku.
  Je-li obrazek BMP, rozhoduje RGBs, zda se nahraji RGB slozky.

  Je-li IO_Result=36 'V BMP souboru nenalezeny RGB slozky'
  Je-li IO_Result=37 'Obrazek s danym nazvem nenalezen' ( pouze GBM )
  Je-li IO_Result=38 'Nedostatek pomocne pameti'
  Je-li IO_Result=39 'Obrazek nelze nahrat' ( zrejme nove vytvoren )
  Je-li IO_Result=40 'Soubor s obrazkem nebyl otevren' (s pomoci OpenImage)
  Je-li IO_Result=42 'Chyba v grafickem formatu'
}
label Konec,Znovu;
const IdHeadLength=9; { delka v bytech uvodni identifikacni hlavicky }
      HeadLength=30; { sirka informacni hlavicky o kazdem obrazku }
var S,O,S2,O2,Remainder:Word;
    I,J:Integer;
    HeadPos,Decrement,Width,Segment2,Offsets2,Pomocna:Word;
    Buff:Pointer;
    Retezec:String[90];
    Zacatek,Delka,Delka2,Delka3:LongInt;
    Help,Help2:Byte;
begin
 if (ImageAttribute<>255) and (Segment<>0) then begin { neotevren or pamet }
  if (ImageAttribute=80) or (ImageAttribute=81) then begin { nove obrazky }
    IO_Result:=39; IO_ResultString:='Obrazek nelze nahrat';
  end else begin
    Reset(ImageFile,1);
    if (ImageAttribute=0) or (ImageAttribute = 41) then begin
    { ***  GBM  *** }
       IO_Result:=42; IO_ResultString:='Chyba v grafickem formatu';
       GoTo Konec;

    end else begin
    { ***  BMP  *** }
       Seek(ImageFile,10);
       BlockRead(ImageFile,Zacatek,4); { souradnice zacatku obrazku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

       if (RGBs = 1) then begin  { nahrat RGB paletu }
          GetMemory(10000,S2,O2);
          Segment2:=S2; Offsets2:=O2;
          if (Segment2 = 0) then begin
            IO_ResultString:='Nedostatek pomocne pameti'; IO_Result:=38;
            GoTo Konec;
          end;
          S:=Seg(Buff); O:=Ofs(Buff);
          Seek(ImageFile,14);
          BlockRead(ImageFile,Pomocna,2); { velikost hlavicky }
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

          Seek(ImageFile,46);
          BlockRead(ImageFile,Delka,4); { pocet RGB slozek }
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          if (Delka = 0) then begin
             Delka:=256;
          end;
          Pomocna:=Pomocna+14;    { zacatek RGB bloku }
          Seek(ImageFile,Pomocna); { 1. modra slozka }
          if Delka>10000 then GoTo Konec; { pojistka }
          for I:=1 to Delka do begin
             asm  { nastaveni ukazatele na 1.modrou slozku }
               mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets2
               add Bx,2
               mov Cx,Segment2; mov Es:[Di],Bx; add Di,2;
               mov Es:[Di],Cx
             end;
             BlockRead(ImageFile,Buff^,1); { nahrej modrou slozku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             asm  { buff ukazuje o 1 zpet }
                mov Ax,S; mov Es,Ax; mov Di,O
                mov Bx,Es:[Di]
                dec Bx; mov Es:[Di],Bx
             end;
             BlockRead(ImageFile,Buff^,1); { nahrej zelenou slozku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             asm  { buff ukazuje o 1 zpet }
                mov Ax,S; mov Es,Ax; mov Di,O
                mov Bx,Es:[Di]
                dec Bx; mov Es:[Di],Bx
             end;
             BlockRead(ImageFile,Buff^,1); { nahrej cervenou slozku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             Pomocna:=Pomocna+4;
             Seek(ImageFile,Pomocna);
             Offsets2:=Offsets2+3;
          end;
          Pomocna:=Delka*3;

          Offsets2:=20;    { vypocet skutecne RGB (nahrana RGB div 4) }
          asm
             mov Ax,Segment2; mov Es,Ax; mov Di,Offsets2;
             mov Cx,Pomocna
@Opet:
             mov Al,Es:[Di]
             shr Al,2
             mov Es:[Di],Al
             inc Di
             loop @Opet
          end;
          Pomocna:=Delka;
          asm
            mov Ah,10h
            mov Al,12h
            mov Bl,0        { pocatecni cislo barvy }
            mov Bh,0
            mov Cx,Pomocna  { pocet RGB slozek }
            mov Dx,Segment2
            mov Es,Dx
            mov Dx,20       { puvodni Offsets2 }
            Int 10h
          end;
          PutMemory(10000,S2,O2);
       end;

       Seek(ImageFile,18);
       BlockRead(ImageFile,Pomocna,2); { sirka obrazku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       Decrement:=Pomocna mod 4; { + finta pro vypocet }
       Width:=(Pomocna div 4)*4; { zarovnana sirka obrazku }
       if (Decrement<>0) then Width:=Width+4;
       Decrement:=Width-Pomocna; { + zarovnani obrazku }
       Delka:=Pomocna;
       Pomocna:=Pomocna-1;
       asm
         mov Ax,Segment; mov Es,Ax; mov Di,Offsets
         mov Ax,Pomocna; mov Es:[Di],Ax
       end;

       Seek(ImageFile,22);
       BlockRead(ImageFile,Pomocna,2); { vyska obrazku }
       IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
       Delka:=Delka*Pomocna;
       Pomocna:=Pomocna-1;
       asm
         mov Ax,Segment; mov Es,Ax; mov Di,Offsets; inc Di; inc Di;
         mov Ax,Pomocna; mov Es:[Di],Ax
       end;
       Seek(ImageFile,Zacatek);  { nastaveni na zacatek }

       { ***  vlastni nahravani  *** }
       S:=Seg(Buff); O:=Ofs(Buff); Offsets:=Offsets+4;
       asm
         mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
         mov Cx,Segment; mov Es:[Di],Bl; inc Di; mov Es:[Di],Bh
         inc Di; mov Es:[Di],Cl; inc Di; mov Es:[Di],Ch
       end;
       if Decrement<>0 then begin   { zarovnany obrazek }
           if (Delka<65536) then begin
              for I:=1 to Pomocna+1 do begin   { jednotlive bloky }
                 BlockRead(ImageFile,Buff^,Width); { uloz radek }
                 IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
                 Offsets:=Offsets+Width-Decrement;  { odstran zarovnani }
                 Help:=0;
                 asm  { zmen ukazatel v Buff }
                   mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                   mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
                   mov Es:[Di],Cx
                 end;
              end;

           end else begin { obrazek je > 65536 }
                Remainder:=0; Inc(Pomocna);
Znovu:
                Delka2:=(65536-Remainder) div (Width-Decrement);
                { Delka2 = pocet celych radku, ukladanych do 64Kb }
                Remainder:=(65536-Remainder) mod (Width-Decrement);
                { Remainder = delka neceleho radku do 64kb }
                for I:=1 to Delka2 do begin
                    BlockRead(ImageFile,Buff^,Width); { uloz radek }
                    IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
                    Offsets:=Offsets+Width-Decrement;  { odstran zarovnani }
                    asm  { zmen ukazatel v Buff }
                      mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                      mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
                      mov Es:[Di],Cx
                    end;
                    Dec(Pomocna);
                    if (Pomocna = 0) then GoTo Konec;
                end;
                BlockRead(ImageFile,Buff^,Remainder);
                Inc(Segment,SelectorInc); Offsets:=0;
                { nyni je ulozeno celych 64kb }

                Remainder:=Width-Remainder;
                BlockRead(ImageFile,Buff^,Remainder);
                Offsets:=Offsets+Remainder-Decrement;
                { odstran zarovnani }
                asm  { zmen ukazatel v Buff }
                   mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                   mov Cx,Segment; mov Es:[Di],Bx; add Di,2;
                   mov Es:[Di],Cx
                end;
                Dec(Pomocna);
                if (Pomocna = 0) then GoTo Konec;
                GoTo Znovu;
              { nyni je ulozen i zbytek radku z predchozich 64Kb }
           end;

       end else begin  { rychle nacteni - obrazek neni zarovnan }
         Delka2:=Delka div 65536; Delka3:=Delka mod 65536;
         if (Delka2 > 0) then
           if (Delka3 > 65531) then begin
              Inc(Delka2); Delka3:=4-(65535-Delka3);
           end else Inc(Delka3,4);
         for I:=1 to Delka2 do begin
            BlockRead(ImageFile,Buff^,65488); { nahrej obrazek }
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
            Offsets:=Offsets+65488;  { 1. cast 64Kb bloku }
            asm   { zmen ukazatel v Buff }
              mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
              mov Cx,Segment; mov Es:[Di],Bx; add Di,2
              mov Es:[Di],Cx
            end;

            BlockRead(ImageFile,Buff^,65536-Offsets); { nahrej obrazek }
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
            Inc(Segment,SelectorInc); Offsets:=0;  { 2. cast 64Kb bloku }
            asm   { zmen ukazatel v Buff }
                mov Ax,S; mov Es,Ax; mov Di,O; mov Bx,Offsets
                mov Cx,Segment; mov Es:[Di],Bx; add Di,2
                mov Es:[Di],Cx
            end;
          end;
          BlockRead(ImageFile,Buff^,Delka3);
          IO_Result:=IOResult;
          if IO_Result<>0 then GoTo Konec;
       end;
    end;  { BMP }
  end;    { obrazek lze nahrat }

Konec:
 end else begin { if ImageAttribute=0 }
    if (ImageAttribute=255) then begin
        IO_Result:=40;
        IO_ResultString:='Soubor s obrazkem nebyl otevren';
    end;
 end;
end;

{ ***** }
procedure GetXYImageCoordinatesGBM(var X,Y:Word; Name:String);
{  Vraci X-ovou a Y-ovou sirku aktualniho obrazku (otevreneho na disku)
  Chyby:
   IO_Result = 37  'Obrazek s danym nazvem nenalezen'
   IO_Result = 40  'Soubor s obrazkem nebyl vytvoren'
   IO_Result = 41  'Informaci nelze zjisitit'
   IO_Result = 42  'Chyba v grafickem formatu'

}
label Konec;
const IdHeadLength=9; { delka v bytech uvodni identifikacni hlavicky }
      HeadLength=30; { sirka informacni hlavicky o kazdem obrazku }
var Retezec:String[90];
    I,J:Integer;
    Help,Help2:Word;
    HeadPos:Word;

begin
   Help:=0; Help2:=0;
   if (ImageAttribute = 80) or (ImageAttribute = 81) then begin
   { nove vytvoreny obrazek }
      IO_Result:=41; IO_ResultString:='Informaci nelze zjisitit'
   end else
    if (ImageAttribute = 255) then begin
    { nekorektne otevreny obrazek }
      IO_Result:=40; IO_ResultString:='Soubor s obrazkem nebyl vytvoren'
    end else begin
       if (ImageAttribute = 1) then begin
       { ***  BMP  *** }
          IO_Result:=42; IO_ResultString:='Chyba v grafickem formatu';
          GoTo Konec;
       end else begin
       { ***  GBM  *** }
          CacheSeek(ImageFile,4);
          if (ImageAttribute=0) then begin
            CacheBlockRead(ImageFile,@Help,1); { pocet ulozenych obrazku }
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
            CacheBlockRead(ImageFile,@Help2,1); { max. pocet obrazku }
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          end else begin
            CacheBlockRead(ImageFile,@Help,2); { pocet ulozenych obrazku }
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
            CacheBlockRead(ImageFile,@Help2,2); { max. pocet obrazku }
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          end;

          Retezec:=''; I:=IdHeadLength; J:=0; { priznak nalezeni obrazku }
          while (I<=(Help*HeadLength)) and (Help<>0) do begin
          { Hledej obrazek }
            CacheSeek(ImageFile,I);
            CacheBlockRead(ImageFile,@Retezec,9);
            IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
            if (Retezec = Name) then begin   { konec, rovnaji se }
               HeadPos:=I;  { zacatek identifikacni hlavicky obrazku }
               I:=Help2*HeadLength+IdHeadLength;
               J:=1;
            end else I:=I+HeadLength;  { nerovnaji se, jdi dal }
          end;

          if (J = 0) then begin  { chyba, obrazek nebyl nalezen }
             IO_Result:=37; IO_ResultString:='Obrazek s danym nazvem nenalezen';
             GoTo Konec;
          end else begin  { OK,vrat souradnice }
             CacheSeek(ImageFile,HeadPos+9);
             CacheBlockRead(ImageFile,@X,2); { sirka obrazku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
             CacheBlockRead(ImageFile,@Y,2); { vyska obrazku }
             IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          end;
       end;
    end;
Konec:
end;

{ ***** }
procedure GetXYImageCoordinatesBMP(var X,Y:Word);
{  Vraci X-ovou a Y-ovou sirku aktualniho obrazku (otevreneho na disku)
  Chyby:
   IO_Result = 37  'Obrazek s danym nazvem nenalezen'
   IO_Result = 40  'Soubor s obrazkem nebyl vytvoren'
   IO_Result = 41  'Informaci nelze zjisitit'
   IO_Result = 42  'Chyba v grafickem formatu'

}
label Konec;
const IdHeadLength=9; { delka v bytech uvodni identifikacni hlavicky }
      HeadLength=30; { sirka informacni hlavicky o kazdem obrazku }
var Retezec:String[90];
    I,J:Integer;
    Help,Help2:Byte;
    HeadPos:Word;

begin
   if (ImageAttribute = 80) or (ImageAttribute = 81) then begin
   { nove vytvoreny obrazek }
      IO_Result:=41; IO_ResultString:='Informaci nelze zjisitit'
   end else
    if (ImageAttribute = 255) then begin
    { nekorektne otevreny obrazek }
      IO_Result:=40; IO_ResultString:='Soubor s obrazkem nebyl vytvoren'
    end else begin
       if (ImageAttribute = 1) then begin
       { ***  BMP  *** }
          Seek(ImageFile,18);
          BlockRead(ImageFile,X,2); { sirka obrazku }
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;
          Seek(ImageFile,22);
          BlockRead(ImageFile,Y,2); { vyska obrazku }
          IO_Result:=IOResult; if IO_Result<>0 then GoTo Konec;

       end else begin
       { ***  GBM  *** }
          IO_Result:=42; IO_ResultString:='Chyba v grafickem formatu';
          GoTo Konec;
       end;
    end;
Konec:
end;

{ ***** }
procedure SetVisualPage(Page:Word);
{  Nastavi viditelnou stranku. (1. stranka ma cislo 0)
   Pred pouzitim je treba celou VRAM vycistit ! (ClearScreen)
}
var Pom:Word;
begin
   Pom:=YRes*Page;
   asm
     mov Ax,4f07h
     mov Bx,0
     mov Cx,0
     mov Dx,Pom
     int 10h
   end;
end;

{ ***** }
procedure ScrollScreen(X,Y:Word);
{  nastavi zacatek obrazovky na stanovene souradnice
}
begin
   asm
      mov Ax,4f07h
      mov Bx,0
      mov Cx,X
      mov Dx,Y
      int 10h
   end;
end;

{ ***** }
procedure SpeedPutImage(X, Y:Word; Segment, Offsets:Word); assembler;
{ specialni rychly PutImage; nutne je, aby sirka obrazku byla delitelna
  ctyrmi a velikost nepresahla 64Kb! Obrazek musi byt ulozeny v pameti tak,
  aby nebylo nutne pri vykreslovani menit segment(selector)

  Ax .. volny
  Bx .. x-ova sirka obrazku div 4
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
asm
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Ax, MaxX
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }

  mov Ax, VRAM
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, MaxX
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Ax, Di
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout VRAM }
  shr Cx,2    { x-ova sirka obrazku div 4 }
  db $f3,$66,$a5
{rep movsd  { presun radek z ExpSegment do pameti }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  movsb       { presun bod }
  cmp Di,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
@end2:
end;

{ ***** }
procedure SpeedPutImage2(X, Y:Word; Segment, Offsets:Word); assembler;
{ specialni rychly PutImage2; nutne je, aby sirka obrazku byla delitelna
  dvema a velikost nepresahla 64Kb. Vykresli obrazek tak, ze ignoruje
  barvu pozadi v predloze a na techto mistech ponecha barvu cile
  Ax .. volny
  Bx .. x-ova sirka obrazku div 2
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
asm
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Ax, MaxX
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }

  mov Ax, VRAM
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, MaxX
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Ax, Di
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout VRAM }
  shr Cx,1{}
@New_pixel:
  mov Ax,Ds:[Si]
  cmp Al,0
  jne @Loop2
  inc Di
  cmp Ah,0
  jne @Loop3
  add Si,2; inc Di
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line

@Loop2:
  mov Es:[Di],Al
  inc Di;
  cmp Ah,0
  jne @Loop3
  inc Di; add Si,2
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@Loop3:
  mov Es:[Di],Ah
  inc Di;
  add Si,2
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }

@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  mov Al,Ds:[Si] { presun data z pameti do VRAM }
  cmp Al,0
  je @Loop4
  mov Es:[Di],Al
@Loop4:
  inc Di; inc Si
  cmp Di,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
@end2:
end;

{ ***** }
procedure SpeedPutImage3(X, Y:Word; Segment, Offsets:Word; Color:Byte); assembler;
{ specialni rychly PutImage; nutne je, aby sirka obrazku byla delitelna
  dvema a velikost nepresahla 64Kb; Barvu od cisla 251 az do 255
  v predloze nahradi barvami Color,Color+1 atd.
  pr.  251=>Color  252=>Color+1 ... 255=>Color+5
  Ax .. volny
  Bx .. x-ova sirka obrazku div 2
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Color2:Byte;
asm
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Al,Color
  mov Color2,Al
  mov Ax, MaxX
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }

  mov Ax, VRAM
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, MaxX
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Ax, Di
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout VRAM }
  shr Cx,1{}
@New_pixel:
  mov Ax,Ds:[Si]
  cmp Al,251
  jb @proceed1
  sub Al,251
  add Al,Color
@proceed1:
  mov Es:[Di],Al
  inc Di;
  cmp Ah,251
  jb @proceed2
  sub Ah,251
  add Ah,Color
@proceed2:
  mov Es:[Di],Ah
  inc Di;
  add Si,2
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }

@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  mov Al,Ds:[Si] { presun data z pameti do ExpSegment }
  cmp Al,251
  jb @Pixel2
  sub Al,251
  add Al,Color
@Pixel2:
  mov Es:[Di],Al
  inc Di; inc Si
  cmp Di,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
@end2:
end;

{ ***** }
procedure SpecSpeedPutImage3(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word; Color:Byte); assembler;
{ specialni rychly PutImage; nutne je, aby sirka obrazku byla delitelna
  dvema a velikost nepresahla 64Kb; Chova se jednak jako PutImage2, navic barvu
  od cisla 251 az do 255 v predloze nahradi barvami Color,Color+1 atd.
  pr.  251=>Color  252=>Color+1 ... 255=>Color+5
  - z predlohy vykresli vyrez o souradnicich X1,Y1,X2,Y2
  (vzhledem k pocatku predlohy !)

  Ax .. volny
  Bx .. x-ova sirka obrazku
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Color2:Byte;
    X1,Y1,X2,Y2,X_Line_adding:Word;
asm
  mov Ax,X11; mov X1,Ax; mov Ax,X22; mov X2,Ax;
  mov Ax,Y11; mov Y1,Ax; mov Ax,Y22; mov Y2,Ax;

  cmp Segment,0
  je @end2
  mov Al,Color
  mov Color2,Al
  mov Ax,MaxX
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }

  mov Ax, VRAM
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, MaxX
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }
  cmp X2, Bx
  jbe @OK_below1
  mov X2,Bx
  dec X2
@OK_below1:
  cmp Y2, Dx
  jbe @OK_below2
  mov Y2,Dx
  dec Y2
@OK_below2:

  { * nyni uprava souradnic vzhledem k oknu * }
  { nejprve upravime adresu }
  push Dx
  mov Ax, Bx
  mul Y1
  add Ax,X1
  add Si,Ax  { posun zacatku zdrojoveho obrazku na zacatek vyrezu }
  pop Dx
  { nyni uprava souradnic }
  mov Ax,Y2
  sub Ax,Y1
  mov Dx,Ax
  inc Dx    { nova y-ova sirka vyrezu }
  mov Cx,Bx { Cx = zalohovane Bx }
  mov Ax,X2
  sub Ax,X1
  mov Bx,Ax
  inc Bx    { nova x-ova sirka vyrezu }
  sub Cx,Bx { X_Line_adding vypocet }
  mov X_Line_adding,Cx
  add New_line_adding,Cx

@New_row:
  mov Ax, Di
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout VRAM }
  shr Cx,1{}
@New_pixel:
  mov Ax,Ds:[Si]
  cmp Al,251
  jb @proceed1
  sub Al,251
  add Al,Color
@proceed1:
  cmp Al,0
  je @Skip1
  mov Es:[Di],Al
@Skip1:
  inc Di;
  cmp Ah,251
  jb @proceed2
  sub Ah,251
  add Ah,Color
@proceed2:
cmp Ah,0
  je @Skip2
  mov Es:[Di],Ah
@Skip2:
  inc Di;
  add Si,2
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }

@New_line:
  add Si,X_Line_adding { zvyseni zdrojove adresy }
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  mov Al,Ds:[Si] { presun data z pameti do ExpSegment }
  cmp Al,251
  jb @Pixel2
  sub Al,251
  add Al,Color
@Pixel2:
  cmp Al,0
  je @Skip3
  mov Es:[Di],Al
@Skip3:
  mov Es:[Di],Al
  inc Di; inc Si
  cmp Di,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
@end2:
end;


{ ***** }
procedure SpeedGetImage(X, Y, X2, Y2:Word; Segment, Offsets:Word); assembler;
{ specialni rychly GetImage; nutne je, aby sirka obrazku byla delitelna
  ctyrmi a velikost nepresahla 64Kb
  Ax .. volny
  Bx .. x-ova sirka obrazku div 4
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje (VRAM)
  Es:Di .. adresa cile (pamet)
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
asm
  { vlastni GetImage }
  cmp Segment,0
  je @end2
  mov Ax, MaxX
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }
  mov Bx, X2
  sub Bx, X;
  mov Dx, Y2
  sub Dx, Y;
  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  mov Si, Di
  mov Di, Offsets
  mov Ax, Segment
  mov Es, Ax
  mov Ax, VRAM
  push Ds
  mov Ds, Ax
  { zjistena adresa cile v pameti (Es:Di) a adresa zdroje (Ds:Si) a souradnice
    Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

  mov Es:[Di], Bx
  inc Di; inc Di; inc Bx
  mov Es:[Di], Dx
  inc Di; inc Di; inc Dx
  dec New_line_adding
  { ulozeny informace o obraze }

@New_row:
  mov Ax, Si
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout VRAM }
  shr Cx,2    { x-ova sirka obrazku div 4 }
  db $f3,$66,$a5
{rep movsd  { presun radek z ExpSegment do pameti }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Si,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  movsb       { presun bod }
  cmp Si,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
@end2:
end;

{ ***** }
procedure PutImageMem(X,Y:Word; Segment, Offsets, S,O:Word); assembler;
{ specialni rychly PutImage; nutne je, aby sirka obrazku byla delitelna
  ctyrmi a velikost nepresahla 64Kb;
  S,O : pamet cilova
  Segment, Offsets : pamet zdrojova
  Ax .. volny
  Bx .. x-ova sirka obrazku div 4
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Selector,ExpSegment:Word;
asm
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,S
  mov ExpSegment,Ax

  { vlastni PutImage  bez otoceni }
  cmp Segment,0
  je @end2
  mov Ax, EMS_line_adding
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax, ExpSegment
  mov Es, Ax

  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, EMS_line_adding
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Ax, Si
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout ExpSegment }
  shr Cx,2    { x-ova sirka obrazku div 4 }
  db $f3,$66,$a5 { presun radek z ExpSegment do pameti }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch12:

  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:
  mov Al,Ds:[Si]
  mov Es:[Di],Al
  inc Di
  inc Si
  jnz @xx
  mov Ax, Ds
  add Ax,Selector
  mov Ds,Ax
@xx:
  loop @Slow

  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch22 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch22:

  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure PutImageMem2(X,Y:Word; Segment, Offsets, S,O:Word); assembler;
{ specialni rychly PutImage; nutne je, aby sirka obrazku byla delitelna
  ctyrmi a velikost nepresahla 64Kb;
  S,O : pamet cilova
  Segment, Offsets : pamet zdrojova
  Ax .. volny
  Bx .. x-ova sirka obrazku div 4
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Selector,ExpSegment:Word;
asm
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,S
  mov ExpSegment,Ax

  { vlastni PutImage  bez otoceni }
  cmp Segment,0
  je @end2
  mov Ax, EMS_line_adding
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax, ExpSegment
  mov Es, Ax

  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, EMS_line_adding
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Ax, Si
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout ExpSegment }
  {shr Cx,2    { x-ova sirka obrazku div 4 }
@again:
  lodsb
  cmp Al,0
  je @Skip
  mov Es:[Di],Al
@Skip:
  inc Di
  loop @again
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch12:

  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:
@again2:
  mov Al,Ds:[Si]
  cmp Al,0
  je @Skip2
  mov Es:[Di],Al
@Skip2:
  inc Di
  inc Si
  jnz @xx
  mov Ax, Ds
  add Ax,Selector
  mov Ds,Ax
@xx:
  loop @Slow

  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch22 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch22:

  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure Transfer(X, Y, XVRAM, YVRAM, XSize, YSize, S, O :Word); assembler;
{ presune obrazek z Exp pameti do VRAM
  v Exp pameti je na pozici X,Y a ma sirku XSize, YSize
  a presouva se na obrazovku do oblasti XVRAM, YVRAM
  velikost MUSI byt cislo delitelne CTYRMI !
  Ax .. volny
  Bx .. x-ova sirka obrazku div 4
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje (ExpSegment)
  Es:Di .. adresa cile (obrazovka)
  NEPROVADI SE KONTROLA SOURADNIC !!!
  POUZIVA SE INSTRUKCE movsd
}
var New_line_adding, New_line_adding_EMS : Word;
    XPom, YPom:Word;
    Selector,ExpSegment:Word;
asm
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,S
  mov ExpSegment,Ax

  { nejprve nastavime prislusnou log. stranku }
  mov Ax, EMS_line_adding
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl
@No_Inc:
  mov Si,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  { nastaveni spravne Videobanky }
  mov Ax, MaxX
  mul YVRAM
  add Ax,XVRAM
  jnc @No_Inc2
  inc Dl
@No_Inc2:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }

  mov Bx, XSize
  mov Dx, YSize
  mov Cx, EMS_line_adding
  sub Cx, Bx
  mov New_line_adding_EMS, Cx
  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  { vypocteny prirustky pro nove radky }

  cld
  mov Ax, VRAM
  mov Es, Ax
  mov Ax, ExpSegment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile v pameti (Es:Di) a adresa zdroje (Ds:Si) a souradnice
    Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

  { ulozeny informace o obraze }
@New_row:
  mov Ax, Di
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout ExpSegment }
  shr Cx,2    { x-ova sirka obrazku div 4 }
  db $f3,$66,$a5
{rep movsd  { presun radek z ExpSegment do pameti }
{  rep movsw{}

@New_line:
  { zvyseni adresy o hodnotu New_line_adding_EMS }
  add Si,New_line_adding_EMS {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Ds
  add Ax,Selector
  mov Ds,Ax
@No_switch12:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch13 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax

@No_switch13:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  movsb       { presun bod }
  cmp Di,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
end;

{ ***** }
procedure SpecSpeedPutImage2(X, Y:Word; Color:Byte; Segment, Offsets:Word); assembler;
{ specialni rychly PutImage2; nutne je, aby sirka obrazku byla delitelna
  dvema a velikost nepresahla 64Kb
  Ax .. volny
  Bx .. x-ova sirka obrazku div 2
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
  ! pro pouziti OutText
}
const NewLineAdding = 232;
var New_line_adding:Word;
    Color2:Byte;
asm
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Al,Color
  add Al,2
  mov Color2,Al
  mov Ax, MaxX
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch:
  { vypoctena adresa prvniho bodu }

  mov Ax, VRAM
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx,XFontSize
  mov Dx,YFontSize
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, MaxX
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Ax, Di
  not Ax
  mov Cx, Bx
  cmp Ax, Bx
  jb @Slow    { skok, pokud na danem radku je nutne precvaknout VRAM }
  shr Cx,1{}
@New_pixel:
  mov Ax,Ds:[Si]
  cmp Al,0
  jne @Loop2
  inc Di
  cmp Ah,0
  jne @Loop3
  add Si,2; inc Di
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line

@Loop2:
  cmp Al,15
  je @Loop2Skip
  mov Al,Color2
  jmp @Loop2Skip2
@Loop2Skip:
  mov Al,Color
@Loop2Skip2:
  mov Es:[Di],Al
  inc Di;
  cmp Ah,0
  jne @Loop3
  inc Di; add Si,2
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@Loop3:
  cmp Ah,15
  je @Loop3Skip
  mov Ah,Color2
  jmp @Loop3Skip2
@Loop3Skip:
  mov Ah,Color
@Loop3Skip2:
  mov Es:[Di],Ah
  inc Di;
  add Si,2
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku }

@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Si,NewLineAdding { posun v predloze na dalsi radek }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row
  jmp @end

@Slow:        { na danem radku je nutne precvaknout VRAM }
  mov Al,Ds:[Si] { presun data z pameti do VRAM }
  cmp Al,0
  je @Loop4
  mov Es:[Di],Al
@Loop4:
  inc Di; inc Si
  cmp Di,0
  jne @Loop   { skok = neni nutne precvaknout VRAM }
  { precvaknuti VRAM }
  mov Ax, Ds
  pop Ds; push Ax; push Dx
  inc MemoryBanka { precvaknuti banky }
  mov Dl, MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx; mov Ax,Ds; pop Ds; push Ax
@Loop:
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  jmp @New_line
@end:
  pop Ds
@end2:
end;

{ ***** }
procedure TextSpeedPutImage2Mem(S,O,XSize:Word;Color:Byte;Segment, Offsets:Word);assembler;
{ prekopiruje text na pametovou pozici S:[O]
  ! pro pouziti OutText
}
const NewLineAdding = 232;
var New_line_adding:Word;
    Color2:Byte;
asm
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Al,Color
  add Al,2
  mov Color2,Al

  mov Ax, S
  mov Es, Ax
  mov Di, O
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx,XFontSize
  mov Dx,YFontSize
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, XSize
  mov Ds, Ax
  sub Cx, Bx
  {inc Cx{}
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Cx, Bx

@Slow:
  lodsb { presun data z pameti do VRAM }
  cmp Al,0
  je @Loop
  {x}
  cmp Al,15
  je @Loop2Skip
  mov Al,Color2
  jmp @Store
@Loop2Skip:
  mov Al,Color
@Store:
  stosb
  dec Di
@Loop:
  inc Di
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  { novy radek: }

@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Si,NewLineAdding { posun v predloze na dalsi radek }
  add Di,New_line_adding { posun v pameti na dalsi radek }
  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure TextSpeedPutImageXMem(S,O,XSize:Word;Color:Byte;Segment, Offsets:Word);assembler;
{ prekopiruje text na pametovou pozici S:[O]
  ! pro pouziti OutText
}
const NewLineAdding = 232;
var New_line_adding:Word;
    Color2:Byte;
asm
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Al,Color
  add Al,2
  mov Color2,Al

  mov Ax, S
  mov Es, Ax
  mov Di, O
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx,XFontSize
  mov Dx,YFontSize
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, XSize
  mov Ds, Ax
  sub Cx, Bx
  {inc Cx{}
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

@New_row:
  mov Cx, Bx

@Slow:
  lodsb { presun data z pameti do VRAM }
  cmp Al,0
  je @Loop
  {x}
  cmp Al,15
  je @Loop2Skip
  mov Al,Color2
  jmp @Loop
@Loop2Skip:
  mov Al,Color

@Loop:
  stosb
  loop @Slow  { je konec radku ?  Cx .. x-ova sirka obrazku }
  { novy radek: }

@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Si,NewLineAdding { posun v predloze na dalsi radek }
  add Di,New_line_adding { posun v pameti na dalsi radek }
  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure OutText(X,Y:Word; Msg:String);
{ vytiskne retezec Msg od pozice X,Y fontem 8x10 bodu
}
const FontPom = XFontSize * (YFontSize) * 30;
var Num, Pom :Byte;
    I : Word;
    Segment, Offsets, Add : Word;
begin
   {Color:=163;{}
   Num:=Length(Msg);
   for I:=1 to Num do begin
      Pom:=Ord(Msg[I])-32;
      Add:=(Pom div 30) * FontPom + (Pom mod 30) * XFontSize;
      { 32 = ordinalni cislo 1. znaku predlohy (zacina se od mezery) }
      SpecSpeedPutImage2(X,Y,Color,FontSegment,FontOffsets+Add);
      Inc(X,XFontSize);
   end;
end;

{ ***** }
procedure OutTextColor(X,Y:Word; Color:Byte; Msg:String);
{ vytiskne retezec Msg od pozice X,Y fontem 8x10 bodu
}
const FontPom = XFontSize * (YFontSize) * 30;
var Num, Pom :Byte;
    I : Word;
    Segment, Offsets, Add : Word;
begin
   Num:=Length(Msg);
   for I:=1 to Num do begin
      Pom:=Ord(Msg[I])-32;
      Add:=(Pom div 30) * FontPom + (Pom mod 30) * XFontSize;
      { 32 = ordinalni cislo 1. znaku predlohy (zacina se od mezery) }
      SpecSpeedPutImage2(X,Y,Color,FontSegment,FontOffsets+Add);
      Inc(X,XFontSize);
   end;
end;

{ ***** }
procedure OutTextColorMem(S,O,XSize:Word; Color:Byte; Msg:String);
{ vytiskne retezec Msg od pozice X,Y fontem 8x16 bodu do pameti S:[O]
}
const FontPom = XFontSize * (YFontSize) * 30;
var Num, Pom :Byte;
    I : Word;
    Segment, Offsets, Add, Add2, Add3 : Word;
begin
   Num:=Length(Msg);
   for I:=1 to Num do begin
      Pom:=Ord(Msg[I])-32;
      Add:=(Pom div 30) * FontPom + (Pom mod 30) * XFontSize;
      { 32 = ordinalni cislo 1. znaku predlohy (zacina se od mezery) }
      Add2:=(I-1)*XFontSize;

      {Add3:=((Ord('*')-32) div 30) * FontPom + ((Ord('*')-32) mod 30) * XFontSize;{}
      TextSpeedPutImagexMem(S,O+Add2,XSize,Color,FontSegment,FontOffsets+Add);{}
      {if (Num < 58) then{}
         TextSpeedPutImagexMem(S,O+Add2+2,XSize,75,FontSegment,FontOffsets+Add);{}
      TextSpeedPutImage2Mem(S,O+Add2,XSize,Color,FontSegment,FontOffsets+Add);{}
   end;
end;

{ ***** }
procedure Rectangle(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obdelnik, vyplneny barvou
  Color.
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne musi byt sude cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
asm
  mov Ax, MaxX
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch1
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch1:
  { vypoctena adresa prvniho bodu }
  mov Ax, VRAM
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

{ vlastni kresleni }
@Opet:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow  { skok = na danem radku nutno precvaknout VRAM }
  shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosw     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch:
  dec Dx
  jne @Opet
  jmp @end

@slow:
  mov Al,Color
  stosb
  cmp Di,0
  jne @No_Switch2
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch2:
  loop @slow
  jmp @New_line
@end:
end;

{ ***** }
procedure Rectangle2(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obdelnik, vyplneny barvou
  Color.
  Nekontroluji se souradnice !!!
  !! Vzdalenost X1 - X2 muze byt libovolna !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
asm
  mov Ax, MaxX
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch1
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch1:
  { vypoctena adresa prvniho bodu }
  mov Ax, VRAM
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

{ vlastni kresleni }
@Opet:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow  { skok = na danem radku nutno precvaknout VRAM }
  {shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosb     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch:
  dec Dx
  jne @Opet
  jmp @end

@slow:
  mov Al,Color
  stosb
  cmp Di,0
  jne @No_Switch2
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch2:
  loop @slow
  jmp @New_line
@end:
end;

{ ***** }
procedure RectangleMem(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obdelnik, vyplneny barvou
  Color, ale do Exp pameti!!!
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne musi byt sude cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
    Selector,ExpSegment:Word;
asm
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax

  mov Ax, EMS_line_adding
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax,ExpSegment
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, EMS_line_adding
  sub Cx, Bx;
  mov New_line_adding, Cx

{ vlastni kresleni }
@Opet:
  mov Cx,Bx
  shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosw     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch:
  dec Dx
  jne @Opet
@end:
end;

{ ***** }
procedure Frame(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obrys obdelniku barvou Color.
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne musi byt NENULOVE SUDE cislo !!
  Vzdalenost Y1 - Y2 vcetne musi byt SUDE cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
asm
  mov Ax, MaxX
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch1
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch1:
  { vypoctena adresa prvniho bodu }
  mov Ax, VRAM
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

{ vlastni kresleni }
{ * nejprve horni vodorovna cara }
@Opet:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow  { skok = na danem radku nutno precvaknout VRAM }
  shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosw     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch:
  dec Dx
  jmp @Proceed

@slow:
  mov Al,Color
  stosb
  cmp Di,0
  jne @No_Switch2
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch2:
  loop @slow
  jmp @New_line

@Proceed:
{ boky }
  mov Al,Color
  mov Es:[Di],Al           { 1. bod }
  { zjisteni adresy 2. bodu }
  dec Di
  add Di,Bx
  jnc @No_Switch3
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch3:
  mov Al,Color
  mov Es:[Di],Al           { 2. bod }
  mov Ax,New_line_adding; inc Ax
  add Di,Ax
  jnc @No_switch4 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch4:
  dec Dx
  cmp Dx,1
  ja @Proceed

{ * dolni vodorovna cara }
@Opet2:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow2  { skok = na danem radku nutno precvaknout VRAM }
  shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosw     { presun radek do VRAM }
  jmp @end

@slow2:
  mov Al,Color
  stosb
  cmp Di,0
  jne @No_Switch6
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch6:
  loop @slow2
@end:
end;

{ ***** }
procedure Frame2(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obrys obdelniku barvou Color.
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne muze byt LIBOVOLNE cislo !!
  Vzdalenost Y1 - Y2 vcetne muze byt LIBOVOLNE cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
asm
  mov Ax, MaxX
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch1
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch1:
  { vypoctena adresa prvniho bodu }
  mov Ax, VRAM
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

{ vlastni kresleni }
{ * nejprve horni vodorovna cara }
@Opet:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow  { skok = na danem radku nutno precvaknout VRAM }
  {shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosb     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch:
  dec Dx
  jmp @Proceed

@slow:
  mov Al,Color
  stosb
  cmp Di,0
  jne @No_Switch2
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch2:
  loop @slow
  jmp @New_line

@Proceed:
{ boky }
  mov Al,Color
  mov Es:[Di],Al           { 1. bod }
  { zjisteni adresy 2. bodu }
  dec Di
  add Di,Bx
  jnc @No_Switch3
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch3:
  mov Al,Color
  mov Es:[Di],Al           { 2. bod }
  mov Ax,New_line_adding; inc Ax
  add Di,Ax
  jnc @No_switch4 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch4:
  dec Dx
  cmp Dx,1
  ja @Proceed

{ * dolni vodorovna cara }
@Opet2:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow2  { skok = na danem radku nutno precvaknout VRAM }
  {shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosb     { presun radek do VRAM }
  jmp @end

@slow2:
  mov Al,Color
  stosb
  cmp Di,0
  jne @No_Switch6
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch6:
  loop @slow2
@end:
end;

{ ***** }
procedure FrameMem(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obrys obdelniku barvou Color
  do rozsirene pameti (ne na obrazovku !!)
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne musi byt NENULOVE SUDE cislo !!
  Vzdalenost Y1 - Y2 vcetne musi byt SUDE cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
    Selector,ExpSegment:Word;
asm
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax

  mov Ax, EMS_line_adding
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax,ExpSegment
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, EMS_line_adding
  sub Cx, Bx;
  mov New_line_adding, Cx

{ vlastni kresleni }
{ * nejprve horni vodorovna cara }
@Opet:
  mov Cx,Bx
  shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosw     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch:
  dec Dx

@Proceed:
{ boky }
  mov Al,Color
  mov Es:[Di],Al           { 1. bod }
  { zjisteni adresy 2. bodu }
  dec Di
  add Di,Bx
  mov Es:[Di],Al           { 2. bod }
  inc Di

  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch4 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch4:
  dec Dx
  cmp Dx,1
  ja @Proceed

{ * dolni vodorovna cara }
@Opet2:
  mov Cx,Bx
  shr Cx,1    { x-ova sirka obrazku div 2 }
  mov Al,Color
  mov Ah,Al
rep stosw     { presun radek do VRAM }

@end:
end;

{ ***** }
procedure FrameMem2(X1,Y1,X2,Y2,LineLenght:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obrys obdelniku barvou Color
  do pameti (ne na obrazovku !!)
  Jedna se o Frame, ktery ma cary pouze v rozich; delka car je LineLenght
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne musi byt NENULOVE SUDE cislo !!
  Vzdalenost Y1 - Y2 vcetne musi byt SUDE cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
    Selector,ExpSegment:Word;
    XLine_adding : Word; { pro VODOROVNE radky vzdalenost mezi koncem
    prvni carky o delce LineLenght a zacatkem druhe rohove carky }
    Yx : Word; { souradnice, rovna Y1+LineLenght }
asm
  mov Ax, Y2
  sub Ax,LineLenght
  mov Yx,Ax
  {}
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax

  mov Ax, EMS_line_adding
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax,ExpSegment
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, EMS_line_adding
  sub Cx, Bx;
  mov New_line_adding, Cx

  mov Ax,Bx
  sub Ax,LineLenght
  sub Ax,LineLenght
  mov XLine_adding,Ax

{ vlastni kresleni }
{ * nejprve horni vodorovna cara }
@Opet:
  mov Cx,LineLenght
  mov Al,Color
rep stosb     { presun radek do VRAM }
  add Di,XLine_adding
  mov Cx,LineLenght
  mov Al,Color
rep stosb     { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch:
  dec Dx

{ *  prvni cast boku }
  mov Cx,LineLenght
@Proceed:
  mov Al,Color
  mov Es:[Di],Al           { 1. bod }
  { zjisteni adresy 2. bodu }
  dec Di; add Di,Bx
  mov Es:[Di],Al           { 2. bod }
  inc Di
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch4 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch4:
  loop @Proceed

{ * vypocteni druhe casti adresy }
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax
  push Dx
  mov Ax, EMS_line_adding
  mul Yx
  add Ax,X1
  jnc @No_Inc2
  inc Dl
@No_Inc2:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }
  mov Ax,ExpSegment
  mov Es,Ax
  pop Dx

{ *  druha cast boku }
  mov Cx,LineLenght
@Proceed2:
  mov Al,Color
  mov Es:[Di],Al           { 1. bod }
  { zjisteni adresy 2. bodu }
  dec Di; add Di,Bx
  mov Es:[Di],Al           { 2. bod }
  inc Di
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch42 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch42:
  loop @Proceed2

{ * dolni vodorovna cara }
@Opet2:
  mov Cx,LineLenght
  mov Al,Color
rep stosb     { presun radek do VRAM }
  add Di,XLine_adding
  mov Cx,LineLenght
  mov Al,Color
rep stosb     { presun radek do VRAM }

@end:
end;

{ ***** }
procedure XORFrame(X1,Y1,X2,Y2:Word; Color:Byte); assembler;
{ Procedura vykresli na danych souradnicich obrys obdelniku barvou Color s
  pomoci operatoru XOR
  Nekontroluji se souradnice !!!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
asm
  { uprava souradnic }
   { porovnani hodnot X1,X2 a Y1,Y2 }
   mov Ax,X1
   cmp X2,Ax
   jae @OK1
   jmp @end
   mov Bx,X2
   mov X1,Bx
   mov X2,Ax
@OK1:
   mov Ax,Y1
   cmp Y2,Ax
   jae @OK2
   jmp @end
   mov Cx,Y2
   mov Y1,Cx
   mov Y2,Ax
@OK2:

   mov Ax, MaxX
   mul Y1
   add Ax,X1
   jnc @No_Inc
   inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch1
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch1:
  { vypoctena adresa prvniho bodu }
  mov Ax, VRAM
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

{ vlastni kresleni }
{ * nejprve horni vodorovna cara }
@Opet:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow  { skok = na danem radku nutno precvaknout VRAM }
  mov Al,Color
  mov Ah,Al
@again: { presun radek do VRAM }
  xor Es:[Di],Al
  inc Di;
  loop @again
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch:
  dec Dx
  cmp Dx,0
  je @end
  jmp @Proceed

@slow:
  mov Al,Color
  xor Es:[Di],Al
  inc Di
  cmp Di,0
  jne @No_Switch2
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch2:
  loop @slow
  jmp @New_line

@Proceed:
{ boky }
  mov Al,Color
  xor Es:[Di],Al           { 1. bod }
  { zjisteni adresy 2. bodu }
  mov Ax,Di
  dec Di
  add Di,Bx
  jnc @No_Switch3
  cmp Ax,0 { by-li Di =0, muze dojit vlivem dec Di k neopravenenmu
             preteceni!!!!!!!!! (tedy po add Di,Bx k dalsimu) }
  je @No_Switch3
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch3:
  mov Al,Color
  xor Es:[Di],Al           { 2. bod }
  mov Ax,New_line_adding; inc Ax
  add Di,Ax
  jnc @No_switch4 { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch4:
  dec Dx
  cmp Dx,1
  ja @Proceed

{ * dolni vodorovna cara }
@Opet2:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow2  { skok = na danem radku nutno precvaknout VRAM }
  mov Al,Color
@again2: { presun radek do VRAM }
  xor Es:[Di],Al
  inc Di;
  loop @again2
  jmp @end

@slow2:
  mov Al,Color
  xor Es:[Di],Al
  inc Di
  cmp Di,0
  jne @No_Switch6
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch6:
  loop @slow2
@end:
end;

{ ***** }
procedure SpecSpeedPutImageMem(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word); assembler;
{ specialni rychly PutImage; nutne je, aby sirka obrazku byla delitelna
  dvema a velikost nepresahla 64Kb;
  - z predlohy vykresli vyrez o souradnicich X1,Y1,X2,Y2
  (vzhledem k pocatku predlohy !)
  Ax .. volny
  Bx .. x-ova sirka obrazku div 4
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Selector,ExpSegment:Word;
    X1,Y1,X2,Y2,X_Line_adding:Word;
asm
  mov Ax,X11; mov X1,Ax; mov Ax,X22; mov X2,Ax;
  mov Ax,Y11; mov Y1,Ax; mov Ax,Y22; mov Y2,Ax;

  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax

  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Ax, EMS_line_adding
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax, ExpSegment
  mov Es, Ax

  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, EMS_line_adding
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

  { * nyni uprava souradnic vzhledem k oknu * }
  { nejprve upravime adresu }
  push Dx
  mov Ax, Bx
  mul Y1
  add Ax,X1
  add Si,Ax  { posun zacatku zdrojoveho obrazku na zacatek vyrezu }
  pop Dx
  { nyni uprava souradnic }
  mov Ax,Y2
  sub Ax,Y1
  mov Dx,Ax
  inc Dx    { nova y-ova sirka vyrezu }
  mov Cx,Bx { Cx = zalohovane Bx }
  mov Ax,X2
  sub Ax,X1
  mov Bx,Ax
  inc Bx    { nova x-ova sirka vyrezu }
  sub Cx,Bx { X_Line_adding vypocet }
  mov X_Line_adding,Cx
  add New_line_adding,Cx

@New_row:
  mov Cx,Bx
  {shr Cx,1    { x-ova sirka obrazku div 2 }
rep movsb       { presun radek z ExpSegment do pameti }
@New_line:
  add Si,X_Line_adding { zvyseni zdrojove adresy }
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure SpecSpeedPutImage2Mem(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word); assembler;
{ specialni rychly PutImage2; nutne je, aby sirka obrazku byla delitelna
  dvema a velikost nepresahla 64Kb; ingnoruje se cerna v barve prodlohy
  - z predlohy vykresli vyrez o souradnicich X1,Y1,X2,Y2
  (vzhledem k pocatku predlohy !)
  Ax .. volny
  Bx .. x-ova sirka obrazku div 2
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Selector,ExpSegment:Word;
    X1,Y1,X2,Y2,X_Line_adding:Word;
asm
  mov Ax,X11; mov X1,Ax; mov Ax,X22; mov X2,Ax;
  mov Ax,Y11; mov Y1,Ax; mov Ax,Y22; mov Y2,Ax;

  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax

  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Ax, EMS_line_adding
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax, ExpSegment
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, EMS_line_adding
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

  { * nyni uprava souradnic vzhledem k oknu * }
  { nejprve upravime adresu }
  push Dx
  mov Ax, Bx
  mul Y1
  add Ax,X1
  add Si,Ax  { posun zacatku zdrojoveho obrazku na zacatek vyrezu }
  pop Dx
  { nyni uprava souradnic }
  mov Ax,Y2
  sub Ax,Y1
  mov Dx,Ax
  inc Dx    { nova y-ova sirka vyrezu }
  mov Cx,Bx { Cx = zalohovane Bx }
  mov Ax,X2
  sub Ax,X1
  mov Bx,Ax
  inc Bx    { nova x-ova sirka vyrezu }
  sub Cx,Bx { X_Line_adding vypocet }
  mov X_Line_adding,Cx
  add New_line_adding,Cx

@New_row:
  mov Cx, Bx
  {shr Cx,1{}
@New_pixel:
  mov Al,Ds:[Si]{}
  cmp Al,0
  je @skip
  mov Es:[Di],Al{}
@skip:
  inc Si; inc Di
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku div 2 }

@New_line:
  add Si,X_Line_adding { zvyseni zdrojove adresy }
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure SpecSpeedPutImageMemUnit(X, Y:Word; Segment, Offsets, X11,Y11,X22,Y22:Word; Color:Byte); assembler;
{ specialni rychly PutImage2; NENI nutne, aby sirka obrazku byla delitelna
  dvema, ale velikost nesmi presahnout 64Kb
  - z predlohy vykresli vyrez o souradnicich X1,Y1,X2,Y2
  (vzhledem k pocatku predlohy !)
  a) ignoruje se barva 0 (ponecha se pozadi)
  b) barva s cislem >250 se nahradi barvou Color
  Ax .. volny
  Bx .. x-ova sirka obrazku div 2
  Cx .. volne
  Dx .. y-ova sirka obrazku
  Ds:Si .. adresa zdroje
  Es:Di .. adresa cile
  NEPROVADI SE KONTROLA SOURADNIC !!!
}
var New_line_adding:Word;
    Selector,ExpSegment:Word;
    Color2:Byte;
    X1,Y1,X2,Y2,X_Line_adding:Word;
asm
  mov Ax,X11; mov X1,Ax; mov Ax,X22; mov X2,Ax;
  mov Ax,Y11; mov Y1,Ax; mov Ax,Y22; mov Y2,Ax;

  mov Al,Color
  mov Color2,Al
  mov Ax,SelectorInc
  mov Selector,Ax
  mov Ax,MapSegment
  mov ExpSegment,Ax
  { vlastni PutImage }
  cmp Segment,0
  je @end2
  mov Ax, EMS_line_adding
  mul Y
  add Ax,X
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  xor Dh,Dh
  mov Ax,Selector { posun segmentu }
  mul Dx          { krat pocet segmentu }
  add ExpSegment,Ax
  { vypoctena adresa prvniho bodu }

  mov Ax, ExpSegment
  mov Es, Ax
  mov Si, Offsets
  mov Ax, Segment
  push Ds
  mov Ds, Ax
  { zjistena adresa cile (Es:Di) a adresa zdroje (Ds:Si) }
  mov Bx, Ds:[Si]
  inc Bx; inc Si; inc Si
  mov Dx, Ds:[Si]
  inc Dx
  inc Si; inc Si
  mov Ax, Ds; pop Ds; push Ds
  mov Cx, EMS_line_adding
  mov Ds, Ax
  sub Cx, Bx
  mov New_line_adding, Cx
  cld
  { Bx - x-ova sirka obrazku; Dx - y-ova sirka obrazku }

  { * nyni uprava souradnic vzhledem k oknu * }
  { nejprve upravime adresu }
  push Dx
  mov Ax, Bx
  mul Y1
  add Ax,X1
  add Si,Ax  { posun zacatku zdrojoveho obrazku na zacatek vyrezu }
  pop Dx
  { nyni uprava souradnic }
  mov Ax,Y2
  sub Ax,Y1
  mov Dx,Ax
  inc Dx    { nova y-ova sirka vyrezu }
  mov Cx,Bx { Cx = zalohovane Bx }
  mov Ax,X2
  sub Ax,X1
  mov Bx,Ax
  inc Bx    { nova x-ova sirka vyrezu }
  sub Cx,Bx { X_Line_adding vypocet }
  mov X_Line_adding,Cx
  add New_line_adding,Cx

@New_row:
  mov Cx, Bx
  {shr Cx,1{}
@New_pixel:
  mov Al,Ds:[Si]{}
  cmp Al,0
  jne @Loop2
  jmp @skip
@Loop2:
  cmp Al,251
  jb @loop21
  sub Al,251
  add Al,Color2
@Loop21:
  mov Es:[Di],Al{}
@skip:
  inc Si; inc Di
  dec Cx
  jnz @New_pixel  { je konec radku ?  Cx .. x-ova sirka obrazku div 2 }

@New_line:
  add Si,X_Line_adding { zvyseni zdrojove adresy }
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding {Cx}
  jnc @No_switch12 { skok, pokud se nastavenim na novy radek nemusi zmenit segment}
  { precvaknuti segmentu }
  mov Ax,Es
  add Ax,Selector
  mov Es,Ax
@No_switch12:
  dec Dx      { nastav novy radek }
  jne @New_row

@end:
  pop Ds
@end2:
end;

{ ***** }
procedure SpecMenuRectangle(X1,Y1,X2,Y2:Word); assembler;
{ Procedura vykresli na danych souradnicich obdelnik, vyplneny barvou
  Color.
  Nekontroluji se souradnice !!!
  Vzdalenost X1 - X2 vcetne musi byt sude cislo !!
  Bx - xova roztec
  Dx - yova roztec
  Es:Di - adresa ve VRAM
}
var New_line_adding : Word; { prirustek adresy na novy radek }
asm
  mov Ax, MaxX
  mul Y1
  add Ax,X1
  jnc @No_Inc
  inc Dl

@No_Inc:
  mov Di,Ax
  cmp Dl,MemoryBanka
  je @No_Switch1
  mov MemoryBanka,Dl
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
@No_Switch1:
  { vypoctena adresa prvniho bodu }
  mov Ax, VRAM
  mov Es,Ax

  mov Bx,X2
  sub Bx,X1
  inc Bx    { x-ova roztec }
  mov Dx,Y2
  sub Dx,Y1
  inc Dx    { y-ova roztec }

  mov Cx, MaxX
  sub Cx, Bx
  mov New_line_adding, Cx
  cld

{ vlastni kresleni }
@Opet:
  mov Cx,Bx
  mov Ax,Di
  add Ax,Cx
  jc @slow  { skok = na danem radku nutno precvaknout VRAM }
  {shr Cx,1    { x-ova sirka obrazku div 2 }
@again:
  mov Al,Es:[Di]
  xor Ah,Ah
  mov Si,Bx
  mov Bl,16
  div Bl
  mov Bx,Si
  mov Al,Ah
  add Al,39
  cmp Al,47
  jbe @not_above
  mov Al,47
@not_above:
  stosb
  loop @again
  { presun radek do VRAM }
@New_line:
  { zvyseni adresy o hodnotu New_line_adding }
  add Di,New_line_adding
  jnc @No_switch { skok, pokud se nastavenim na novy radek nemusi zmenit banka }
  { precvaknuti VRAM }
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_switch:
  dec Dx
  jne @Opet
  jmp @end

@slow:
  mov Al,Es:[Di]
  xor Ah,Ah
  mov Si,Bx
  mov Bl,16
  div Bl
  mov Bx,Si
  mov Al,Ah
  add Al,39
  cmp Al,47
  jbe @not_above2
  mov Al,47
@not_above2:
  stosb

  cmp Di,0
  jne @No_Switch2
  push Dx
  inc MemoryBanka
  mov Dl,MemoryBanka
  xor Dh,Dh
  mov Ax,4f05h
  Int IntNum
  pop Dx
@No_Switch2:
  loop @slow
  jmp @New_line
@end:
end;

{ ***** }
procedure ScreenOff;
{ zakaze zobrazovani na obrazovce
}
begin
{   asm
      mov Ah,12h
      mov Bl,36h
      mov Al,1
      int 10h
   end;{}
end;

{ ***** }
procedure ScreenOn;
{ povoli zobrazovani na obrazovce
}
begin
{   asm
     mov Ah,12h
     mov Bl,36h
     mov Al,0
     int 10h
   end;{}
end;

{ ***** }
procedure Convert_to_gray(Color,Count:Word);
{ procedura prevede Count barev od barvy Color na sedou skalu
}
begin
   asm
      mov Ah,10h
      mov Al,1bh
      mov Bx,Color
      mov Cx,Count
      int 10h
   end;
end;

{ ***** }
procedure GetMaxRes(var MaxRes:Word);
{
}
begin
   if (MaxResolution > 1) then MaxResolution:=1;
   MaxRes:=MaxResolution;
end;

{ ***** }
procedure Graph257_save;
{ pro potreby ulozeni hry
}
label K;

begin
{   vesa_emm_save;
   Assign(IOFile,'save\1'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); DResult:=IOResult;{}
end;

{ ***** }
procedure Graph257_load;
{ pro potreby ulozeni hry
}
label K;

begin
{  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
{  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  vesa_emm_load;
  Assign(IOFile,'save\1'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;{}
end;

{ ************************************************************************** }
begin
   GlobalMemory:=Nil; GlobalMemory2:=Nil;
   EMS_line_adding:=4096;
   Mem1028bIndex:=65535;
   Mem1448bIndex:=65535;
   New(MemArray1028b); New(MemArray1448b);
end.

