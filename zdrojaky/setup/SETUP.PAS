program Setup;
uses Crt,Dos,Detect,Strings,wav_test,DrvUti,Smix;
label Konec, Skip;
const InstallMemory = 24000000;
var CFGFile:File;
    Chyba:String;
    Scan,Pomocna:Byte;
    I:Integer;
    Error,Pozice:Word;
    Vram:Word;
    LineNo:Word;

    Title:array[0..4] of String[80]; { titulek k danemu menu }
    TitleLines:Word; { pocet vyuzitych radku titulku }
    TitleWidth:Word; { sirka titulku  ve znacich }
    Menu:array[0..23] of String[80]; { vlastni menu }
    MenuLines:Word; { pocet vyuzitych radku menu }
    MenuWidth:Word; { sirka menu ve znacich }
    Help:array[0..23] of String[80]; { text helpu }
    HelpLines:Word; { pocet vyuzitych radku helpu }

    MaxRes, MaxResHi, PomRes:Word;
    Granularity:Word;
    Vesa:File;
    Num1:Byte;
    VesaDetected:Word;
    SoundDetected:Boolean;
    PartialSound:Byte; { 0.. bez zvuku, 1..cast zvuku, 2.. vsechny zvuky }
    R1,R2:String;
    Snd:File;
    Install:Boolean;
    DiskList:TDiskList;
    II:Char;
    J:Word;
    InstallDrive:Char;
    Rec:SearchRec;

{ ***** }
procedure Hide; assembler;
{ Ukryje kurzor }
asm
   mov Ah,02
   mov Bh,0h
   mov Dh,25
   mov Dl,0
   Int 10h
end;

{ ***** }
procedure Frame(X1,Y1,X2,Y2:Word; Znak:Char; BarvaZnaku,BarvaPozadi:Byte );
{ Vytiskne primym pristupem do Vram znakem Znak 'obdelnik' }
var I,J:Integer;
    Pamet:Word;
    S,O:Word;
begin
   TextColor(BarvaZnaku); TextBackGround(BarvaPozadi);
   for J:=Y1 to Y2 do begin
     for I:=X1 to X2 do begin
        S:=VRAM; O:=(J-1)*160+(I-1) shl 1;
        Mem[S:O]:=Ord(Znak);
        Inc(O); Mem[S:O]:=BarvaZnaku + BarvaPozadi shl 4;
     end;
   end;
end;

{ ***** }
procedure ReadKey(var Scan:Byte); forward;

procedure Introduce;
var X,Y:Word;
begin
   TextMode(C80);
   Frame(1,1,79,24,Chr(176),1,0);
   if IOResult<>0 then begin
     Writeln(' Instalace standardniho textoveho VGA rezimu probehla neuspesne');
     Halt;
   end;
   TextColor(White);
   X:=15; Y:=2;
   TextColor(15); TextBackground(1);
   GoToXY(30,8); Writeln('  STORMNET  SETUP  '); Hide;
   TextColor(15);
   GoToXY(30,17); Writeln(' (c) 1999 GILIATH '); Hide;
   TextColor(3+Blink);
   GoToXY(24,23);
   Writeln('    Stisknete libovolnou klavesu '); Hide;
   ReadKey(Scan);
end;

{ ***** }
procedure ReadKey(var Scan:Byte);
{ ceka na stisk klavesy a vraci jeji hodnotu scan }
var Scans:Byte;
begin
  asm
@again:
    mov Ah,11h
    Int 16h
    jz @again
    mov Scans,Ah
    mov Ah,10h
    Int 16h
  end;
  Scan:=Scans;
end;

{ ***** }
function ReadKeys(var Ascii:Byte):Byte;
{ ceka na stisk klavesy a vraci jeji hodnotu ascii,scan }
var Asciis:Byte;
begin
    asm
@again:
      mov Ah,11h
      Int 16h
      jz @again
      mov Asciis,Al
      mov @Result,Ah
      mov Ah,10h
      Int 16h
    end;
  Ascii:=Asciis;
end;

{ ***** }
procedure ChgString_Number( Retezec:String; var Number:Byte );
{ prevede retezec na cislo }
var Nasobitel,Cislo:Byte;
    I:Integer;
begin
   Number:=0; Nasobitel:=1;
   for I:=Length(Retezec) downto 2 do begin
      Cislo:=ord(Retezec[I]);
      if Cislo in [$30..$39] then Cislo:=Cislo-$30 else begin
         if Cislo in [$41..$46] then Cislo:=Cislo-$41+10 else
            Cislo:=Cislo-$61+10;
      end;
      Number:=Nasobitel*Cislo+Number;
      Nasobitel:=16;
   end;
end;

{ ***** }
procedure UnWrapWindows(var TitleX,TitleY,MenuX,MenuY:Word);
{ plynule rozbali okna
}
var I,J:Word;
    X,Y,XSize,YSize:Word;
begin
  { nejprve horizontalne titulek }
  X:=TitleX + (2+TitleWidth) div 2 - 1;
  Y:=TitleY;
  XSize:=2; YSize:=1;
  for I:=1 to (TitleWidth div 2)+1 do begin
    Frame(X,Y,X+XSize-1,Y+YSize-1,' ',15,LightGray);
    Inc(XSize,2); Dec(X);
    Delay(20);
  end; TitleX:=X+1;
  { a vertikalne }
  for I:=1 to TitleLines-1 do begin
    Frame(X,Y,X+XSize-1,Y+YSize,' ',15,LightGray);
    Inc(YSize);
    Delay(50);
  end;
  { a vlastni text }
  for I:=0 to TitleLines-1 do begin
    X:=TitleX+1+(TitleWidth-Length(Title[I])) div 2;
    Y:=TitleY+I;
    TextColor(Black); TextBackGround(LightGray); GoToXY(X,Y);
    Write(Title[I]); Hide;
  end;

  { * nejprve horizontalne * }
  X:=MenuX + (2+MenuWidth) div 2 - 1;
  Y:=MenuY;
  XSize:=2; YSize:=1;
  for I:=1 to (MenuWidth+2) div 2 do begin
    Frame(X,Y,X+XSize-1,Y+YSize-1,' ',15,1);
    Inc(XSize,2); Dec(X);
    Delay(20);
  end; MenuX:=X;
  { a vertikalne }
  for I:=1 to (MenuLines+1) do begin
    Frame(X,Y,X+XSize-1,Y+YSize,' ',15,1);
    Inc(YSize);
    Delay(50);
  end;
  { a vlastni text }
  for I:=0 to MenuLines-1 do begin
    X:=MenuX+1{+(MenuWidth-Length(Menu[I])) div 2{};
    Y:=MenuY+I+1;
    TextColor(WHITE); TextBackGround(Blue); GoToXY(X,Y);
    Write(Menu[I]); Hide;
  end;
end;

{ ***** }
procedure HelpScreen;
{ procedura vypise obsah helpu na obrazovku
}
var I,J:Word;
    Scan:Byte;
    SaveScreen:array[0..79,0..24] of record
                 Character, Attribute:Byte;
               end;
    Znak,Atribut:Byte;

begin
   { save screen }
   for I:=0 to 79 do begin
     for J:=0 to 24 do begin
        asm  { nastaveni kurzoru }
          mov Ah,02h
          mov Bh,0
          mov Cx,I
          mov Dl,Cl
          mov Cx,J
          mov Dh,Cl
          int 10h
        end;
        asm  { nacteni znaku a atributu }
          mov Ah,08h
          mov Bh,0
          int 10h
          mov Znak,Al
          mov Atribut,Ah
        end;
        Hide;
        SaveScreen[I,J].Character:=Znak; SaveScreen[I,J].Attribute:=Atribut;
     end;
   end;

   Frame(1,1,79,24,Chr(176),1,0); TextColor(Yellow); GotoXY(4,2);
   Writeln('                         POMOC K PROGRAMU SETUP                          '); Hide;
   TextColor(White); TextBackground(Blue);
   for I:=1 to HelpLines do begin
     GoToXY(2+(76-Length(Help[I-1])) div 2,3+I);
     Writeln(Help[I-1]); Hide;
   end;
   TextColor(LightGray); GotoXY(28,22);
   Writeln('Stisknete libovolnou klavesu'); Hide;

   ReadKey(Scan);

   { restore screen }
   for I:=0 to 79 do begin
     for J:=0 to 24 do begin
        asm  { nastaveni kurzoru }
          mov Ah,02h
          mov Bh,0
          mov Cx,I
          mov Dl,Cl
          mov Cx,J
          mov Dh,Cl
          int 10h
        end;
        Znak:=SaveScreen[I,J].Character; Atribut:=SaveScreen[I,J].Attribute;
        asm { zmena atributu }
          mov Ah,09h
          mov Al,Znak
          mov Bh,0
          mov Bl,Atribut
          mov Cx,1
          int 10h
        end;
        Hide;
     end;
     Delay(1);{}
   end;
end;

{ ***** }
procedure ChangeBackground(X,Y,X2,Y2:Word);
{ zmeni barvu pozadi na jinou
}
var I,J:Word;
    Znak,Atribut:Byte;
begin
   for I:=X to X2 do
     for J:=Y to Y2 do begin
        asm  { nastaveni kurzoru }
          mov Ah,02h
          mov Bh,0
          mov Cx,I
          mov Dl,Cl
          mov Cx,J
          mov Dh,Cl
          int 10h
        end;
        asm  { nacteni znaku a atributu }
          mov Ah,08h
          mov Bh,0
          int 10h
          mov Znak,Al
          mov Atribut,Ah
        end;
        Atribut:=Atribut+1;
        asm { zmena atributu }
          mov Ah,09h
          mov Al,Znak
          mov Bh,0
          mov Bl,Atribut
          mov Cx,1
          int 10h
        end;
        Hide;
     end;
end;

{ ***** }
procedure ChangeBackground2(X,Y,X2,Y2:Word);
{ zmeni barvu pozadi na puvodni
}
var I,J:Word;
    Znak,Atribut:Byte;
begin
   for I:=X to X2 do
     for J:=Y to Y2 do begin
        asm  { nastaveni kurzoru }
          mov Ah,02h
          mov Bh,0
          mov Cx,I
          mov Dl,Cl
          mov Cx,J
          mov Dh,Cl
          int 10h
        end;
        asm  { nacteni znaku a atributu }
          mov Ah,08h
          mov Bh,0
          int 10h
          mov Znak,Al
          mov Atribut,Ah
        end;
        if (Atribut >= 1) then Atribut:=Atribut-1;
        asm { zmena atributu }
          mov Ah,09h
          mov Al,Znak
          mov Bh,0
          mov Bl,Atribut
          mov Cx,1
          int 10h
        end;
        Hide;
     end;
end;

{ ***** }
function KeyHandle(TitleX,TitleY,MenuX,MenuY,KeysType:Byte; var LineNo:Word):Byte;
{ funkce pohybuje kurzorem po okne; konci na Enter, Esc, F1; pokud je
  KeysType = 0, skonci po jakekoliv klavese a nezobrazi kurzor;
  pro KeysType = 2 skonci ihned
}
var Scan:Byte;
begin
  if (KeysType = 0) then begin
    ReadKey(Scan);
  end else
  if (KeysType = 1) then begin
  { pohyb kurzoru }
    ChangeBackground(MenuX-1,MenuY-1+LineNo-1,MenuX+MenuWidth-1,MenuY-1+LineNo-1);
    repeat
      ReadKey(Scan);
      case (Scan) of
        $01: begin { Esc }
             end;
        $3b: begin { F1 }
             end;
        $1c: begin { Enter }
             end;
        $50: begin { Dolu }
               if (LineNo < MenuLines) then begin
                 ChangeBackground2(MenuX-1,MenuY-1+LineNo-1,MenuX+MenuWidth-1,MenuY-1+LineNo-1);
                 Inc(LineNo);
                 ChangeBackground(MenuX-1,MenuY-1+LineNo-1,MenuX+MenuWidth-1,MenuY-1+LineNo-1);
               end;
             end;
        $48: begin { Nahoru }
                if (LineNo > 1) then begin
                 ChangeBackground2(MenuX-1,MenuY-1+LineNo-1,MenuX+MenuWidth-1,MenuY-1+LineNo-1);
                 Dec(LineNo);
                 ChangeBackground(MenuX-1,MenuY-1+LineNo-1,MenuX+MenuWidth-1,MenuY-1+LineNo-1);
               end;
             end;
      end;
    until ((Scan = $01) or (Scan = $3b) or (Scan = $1c));
  end;
  ChangeBackground2(MenuX-1,MenuY-1+LineNo-1,MenuX+MenuWidth-1,MenuY-1+LineNo-1);
  KeyHandle:=Scan;
end;

{ ***** }
procedure CreateMenu(KeysType:Word; var LineNo:Word);
{ podle nadefinovanych parametru vytvori menu a bude jej ovladat;
  KeysType:
  0 .. ukonci program po stisku jakekoli klavesy
  1 .. reaguje pouze na enter
  2 .. skonci ihned
  pozn. stisk F1 vyvola help
  LineNo vraci "odklepnuty radek"; pri LineNo = 65535 byl stisknut Esc
}
const MaxLines = 25; { max. pocet radku na obrazovce }
      LineChars = 80; { pocet znaku na radek }
var TitleX,TitleY,MenuX,MenuY:Word;
    Scan:Byte;
begin
   Frame(1,1,79,24,Chr(176),1,0);
   GotoXY(35,1); TextColor(LightGray); TextBackground(Blue);
   Write('STORMNET SETUP'); Hide;
   GotoXY(30,23); TextColor(DarkGray); TextBackground(Black);
   Writeln(' (c) 1999 GILIATH'); Hide;
   GotoXY(3,24); TextColor(LightGray); TextBackground(Blue);
   Write('F1 - pomoc                                    Esc - ukonceni aktualniho okna'); Hide;

   TitleX:=(LineChars - TitleWidth+3) div 2;
   TitleY:=3;
   MenuX:=(LineChars - MenuWidth+3) div 2;
   MenuY:=3+TitleLines+2;

   UnWrapWindows(TitleX,TitleY,MenuX,MenuY); { plynule rozbali okna }
   Inc(TitleX); Inc(TitleY);
   Inc(MenuX); Inc(MenuY);

   LineNo:=1;
   repeat
     Scan:=KeyHandle(TitleX,TitleY,MenuX,MenuY,KeysType,LineNo);
     case (Scan) of
       $3b : begin { F1 = help }
                Scan:=0;
                HelpScreen;
             end;
     end;
   until (Scan <> 0);
   if (Scan = $01) then LineNo:=65535; { Esc }
end;

{ ***** }
procedure Main(var LineNo:Word);
{
}
begin
  Title[0]:='Setup - hlavni volby';
  TitleLines:=1; { pocet vyuzitych radku titulku }
  TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
  Menu[0]:='        Video karta';
  Menu[1]:='        Zvuk';
  Menu[2]:='        Konec';
  MenuLines:=3; { pocet vyuzitych radku menu }
  MenuWidth:=25; { sirka menu ve znacich }
  Help[0]:='Pohybem kurzorovych klaves (sipek) a naslednym stiskem klavesy Enter';
  Help[1]:='si vyberte jednu z kategorii. Pro prvni spusteni setupu doporucujeme';
  Help[2]:='nastavit vsechny kategorie. Stisk klavesy "Esc" ukonci program';
  Help[3]:='';
  HelpLines:=4; { pocet vyuzitych radku helpu }

  CreateMenu(1,LineNo);
end;

{ ***** }
procedure VideoKarta(var LineNo:Word);
{
}
begin
  Title[0]:='Setup - nastaveni videokarty';
  TitleLines:=1; { pocet vyuzitych radku titulku }
  TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
  Menu[0]:='    Maximalni rozliseni';
  Menu[1]:='    Zpet';
  MenuLines:=2; { pocet vyuzitych radku menu }
  MenuWidth:=25; { sirka menu ve znacich }
  Help[0]:='Pohybem kurzorovych klaves (sipek) a naslednym stiskem klavesy Enter';
  Help[1]:='si vyberte jednu z kategorii. Pro prvni spusteni setupu doporucujeme';
  Help[2]:='nastavit vsechny kategorie. Stisk klavesy "Esc" ukonci program';
  Help[3]:='';
  HelpLines:=4; { pocet vyuzitych radku helpu }

  CreateMenu(1,LineNo);
end;

{ ***** }
procedure VesaTest;
{
}
var Vesa:File;
    Memory:Word;
    Pom:Pchar;
    Num1,Num2:Byte;
    Ret1, Ret2:String;
    Mode:Word;
begin
  Title[0]:='Setup - detekce videokarty';
  TitleLines:=1; { pocet vyuzitych radku titulku }
  TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }

  Exec('vesatest.exe','');
  if ((DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri spousteni programu vesatest.exe'); Halt(0);
  end;
  Assign(Vesa,'Vesa.$$$'); Reset(Vesa,1);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
  end;

  BlockRead(Vesa,VesaDetected,2);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
  end;
  if (VesaDetected <> 0) then begin
     Menu[0]:='Videokarta VESA kompatibilni';
     BlockRead(Vesa,Memory,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0);
       Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     Str(LongInt(Memory)*64,Ret1);
     Menu[1]:='Velikost pameti : '+Ret1+'Kb';
     { nazev vyrobce }
     GetMem(Pom,100);
     BlockRead(Vesa,Pom^,80);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0);
       Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     Menu[2]:=StrPas(Pom);
     { cislo vesa verze }
     BlockRead(Vesa,Num1,1);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0);
       Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     BlockRead(Vesa,Num2,1);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0);
       Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     Str(Num1,Ret1); Str(Num2,Ret2);
     Menu[3]:='VESA verze '+Ret1+'.'+Ret2;

     { granularita }
     BlockRead(Vesa,Granularity,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0);
       Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     Str(Granularity,Ret1);
     Menu[4]:='Granularita '+ Ret1;

     { jednotlive rezimy }
     MaxRes:=0; MaxResHi:=0;

     { 640x480 }
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 5) then Mode:=0;
     if (Mode = 0) then Menu[5]:='640x480 .. NENI K DISPOZICI'
     else begin Menu[5]:='640x480    .. 256 barev'; end;
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 10) then Mode:=0;
     if (Mode = 0) then Menu[5]:=Menu[5]+''
     else begin Menu[5]:=Menu[5]+', 32k barev'; end;
     {x}

     { 800x600 }
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 8) then Mode:=0;
     if (Mode = 0) then Menu[6]:='800x600 .. NENI K DISPOZICI'
     else begin Menu[6]:='800x600    .. 256 barev'; Inc(MaxRes); end;
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 16) then Mode:=0;
     if (Mode = 0) then Menu[6]:=Menu[6]+''
     else begin Menu[6]:=Menu[6]+', 32k barev'; Inc(MaxResHi); end;
     {x}

     { 1024x768 }
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 12) then Mode:=0;
     if (Mode = 0) then Menu[7]:='1024x768 .. NENI K DISPOZICI'
     else begin Menu[7]:='1024x768   .. 256 barev'; Inc(MaxRes); end;
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 24) then Mode:=0;
     if (Mode = 0) then Menu[7]:=Menu[7]+''
     else begin Menu[7]:=Menu[7]+', 32k barev'; Inc(MaxResHi); end;
     {x}

     { 1280x1024 }
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 20) then Mode:=0;
     if (Mode = 0) then Menu[8]:='1280x1024 .. NENI K DISPOZICI'
     else begin Menu[8]:='1280x1024  .. 256 barev'; end;
     BlockRead(Vesa,Mode,2);
     if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
       TextColor(15); TextBackGround(0); Writeln('Chyba pri nacitani souboru vesa.$$$'); Halt(0);
     end;
     if (Memory < 40) then Mode:=0;
     if (Mode = 0) then Menu[8]:=Menu[8]+''
     else begin Menu[8]:=Menu[8]+', 32k barev'; Inc(MaxResHi); end;
     {x}

     MenuLines:=9; { pocet vyuzitych radku menu }
     MenuWidth:=50; { sirka menu ve znacich }
  end else begin
     Menu[0]:='NEBYLA DETEKOVANA PODPORA VESA STANDARDU!';
     MenuLines:=1; { pocet vyuzitych radku menu }
     MenuWidth:=50; { sirka menu ve znacich }
  end;

  Help[0]:='Program zobrazil informace o videokarte. Stisknete libovolnou klavesu.';
  Help[1]:='POKUD NEBYLA DETEKOVANA PODPORA VESA STANDARDU, HRA NEBUDE FUNGOVAT!';
  HelpLines:=2; { pocet vyuzitych radku helpu }

  CreateMenu(0,LineNo);

  { nyni smazani vesa.$$$ a ulozeni vesa.cfg }
  Close(Vesa); Erase(Vesa);
  Assign(Vesa,'vesa.cfg'); ReWrite(Vesa,1);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
  end;
  BlockWrite(Vesa,MaxRes,2);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
  end;
  BlockWrite(Vesa,MaxResHi,2);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
  end;
  Num1:=VesaDetected;
  BlockWrite(Vesa,Num1,1);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
  end;
  BlockWrite(Vesa,Granularity,2);
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
    TextColor(15); TextBackGround(0);
    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
  end;
  Close(Vesa);
end;

{ ***** }
procedure SetMaxRes(var LineNo:Word);
{ procedura nastavi maximalni rozliseni pro hru
}
begin
  Title[0]:='Setup - nastaveni maximalniho rozliseni';
  TitleLines:=1; { pocet vyuzitych radku titulku }
  TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
  Menu[0]:='    640x480';
  if (MaxRes = 0) then Menu[1]:='    Zpet' else Menu[1]:='    800x600';
  if (MaxRes = 1) then Menu[2]:='    Zpet' else Menu[2]:='    1024x768';
  if (MaxRes = 2) then Menu[3]:='    Zpet' else Menu[3]:='    1200x1024';
  Menu[4]:='    Zpet';
  MenuLines:=MaxRes+2; { pocet vyuzitych radku menu }
  MenuWidth:=25; { sirka menu ve znacich }
  Help[0]:='Pohybem kurzorovych klaves (sipek) a naslednym stiskem klavesy Enter';
  Help[1]:='si vyberte maximalni rozliseni. Jde o maximalni rozliseni, vyuzitelne';
  Help[2]:='ve hre. Napr. zvolite-li 800x600, lze pouzivat rezimy 640x480 a 800x600.';
  Help[3]:='Vetsi rozliseni znamena nejen jemnejsi obraz, ale i vetsi naroky na pamet';
  Help[4]:='640x480   ..  2,6 Mb';
  Help[5]:='800x600   ..  3,2 Mb';
  Help[6]:='1024x768  ..  8,7 Mb';
  Help[7]:='1200x1024 ..  12,2 Mb';
  Help[8]:='pozn. pro rezim 1200x1024 je treba mit alespon 2Mb videokartu !';
  HelpLines:=9; { pocet vyuzitych radku helpu }

  CreateMenu(1,LineNo);
end;

{ ***** }
procedure Instalace(var LineNo:Word);
{
}
var I:Char;
    J:Word;
    M:LongInt;
    Ret:String;
begin
  Title[0]:='Instalace - vyber ciloveho disku';
  TitleLines:=1; { pocet vyuzitych radku titulku }
  TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
  GetDiskList(DiskList,InstallMemory);
  J:=0;
  for II:='C' to 'Z' do begin
     if ((DiskList[II]) and (J < 10)) then begin
        M:=DiskFree(Ord(II)-Ord('C')+3) div 1048576; Str(M,Ret);
        Menu[J]:='    Disk '+II+': Volne misto: '+Ret+'MB'; Inc(J);
     end;
  end;
  MenuLines:=J; { pocet vyuzitych radku menu }
  MenuWidth:=35; { sirka menu ve znacich }
  Help[0]:='Vyberte si cilovy disk';
  HelpLines:=1; { pocet vyuzitych radku helpu }

  CreateMenu(1,LineNo);
end;

{ ***** }
procedure Wait;
{
}
begin
   Title[0]:='Cekani';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   {Menu[0]:=' Cekejte prosim asi 10 s';{Menu definuje volajici}
   MenuLines:=1; { pocet vyuzitych radku menu }
   MenuWidth:=25; { sirka menu ve znacich }
   Help[0]:='';
   HelpLines:=1; { pocet vyuzitych radku helpu }

   CreateMenu(2,LineNo); { konec hned }
end;

{ ***** }
procedure _Error;
{
}
begin
   Title[0]:='CHYBA!';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   {Menu[0]:='';{Menu definuje volajici}
   MenuLines:=1; { pocet vyuzitych radku menu }
   MenuWidth:=72; { sirka menu ve znacich }
   Help[0]:='Nastala necekana chyba pri pokusu testovat zvuk';
   HelpLines:=1; { pocet vyuzitych radku helpu }

   CreateMenu(0,LineNo); { konec hned }
end;

{ ***** }
procedure _InstallError(Err:Word);
{
}
var Ret:String;
begin
   Title[0]:='CHYBA INSTALACE !';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   Str(Err,Ret);
   Menu[0]:='   Chyba cislo: '+Ret; {Menu definuje volajici}
   MenuLines:=1; { pocet vyuzitych radku menu }
   MenuWidth:=35; { sirka menu ve znacich }
   Help[0]:='Nastala necekana chyba pri instalaci';
   HelpLines:=1; { pocet vyuzitych radku helpu }

   CreateMenu(0,LineNo); { konec hned }
end;

{ ***** }
procedure _UnInstallError(Err:Word);
{
}
var Ret:String;
begin
   Title[0]:='CHYBA PRI ODINSTALOVANI !';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   Str(Err,Ret);
   Menu[0]:='   Chyba cislo: '+Ret; {Menu definuje volajici}
   MenuLines:=1; { pocet vyuzitych radku menu }
   MenuWidth:=35; { sirka menu ve znacich }
   Help[0]:='Nastala necekana chyba pri instalaci';
   HelpLines:=1; { pocet vyuzitych radku helpu }

   CreateMenu(0,LineNo); { konec hned }
end;

{ ***** }
procedure TestCasovace;
{
}
begin
end;

{ ***** }
procedure KorekceCasovace;
{
}
var Scan:Byte;
begin
end;

{ ***** }
procedure HandleSound(var LineNo:Word);
{
}
begin
   Title[0]:='Nastaveni zvuku';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   Menu[0]:=' Test zvukove karty';
   Menu[1]:=' Test zvuku';
   Menu[2]:=' Pestrost zvuku';
   Menu[3]:=' Zpet';
   MenuLines:=4; { pocet vyuzitych radku menu }
   MenuWidth:=25; { sirka menu ve znacich }
   Help[0]:='Pohybem kurzorovych klaves (sipek) a naslednym stiskem klavesy Enter ';
   Help[1]:='si vyberte jednu z kategorii. Test zvukove karty se pokusi detekovat ';
   Help[2]:='nastaveni zvukove karty (DMA,IRQ .. ). Test zvuku je akusticka zkouska,';
   Help[3]:='zda bylo nastaveni detekovano spravne.';
   Help[4]:='Pestrost zvuku udava pocet zvuku, ktere bude hra pouzivat';
   Help[5]:='(vice zvuku = vice pameti)';
   HelpLines:=6; { pocet vyuzitych radku helpu }

   CreateMenu(1,LineNo); { konec hned }
end;

{ ***** }
procedure TestZvukoveKarty;
{
}
begin
   Title[0]:='Testovani zvukove karty';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   MenuLines:=4; { pocet vyuzitych radku menu }
   MenuWidth:=68; { sirka menu ve znacich }
   Menu[0]:='                        CEKEJTE PROSIM';
   Menu[1]:='                 Autodetekce muze trvat az 20s';
   Menu[2]:=' Pokud nebude program po teto dobe reagovat, tak doslo k zaseknuti';
   Menu[3]:='     V pripade zaseknuti jeste zkuste stisknout nejakou klavesu';
   CreateMenu(2,LineNo);

   Title[0]:='Testovani zvukove karty';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   SoundDetected:=SoundTest(Menu[0],Menu[1]);
   MenuLines:=2; { pocet vyuzitych radku menu }
   MenuWidth:=72; { sirka menu ve znacich }
   Help[0]:='Nyni byly detekovany parametry zvukove karty. Pokud jsou chybne,';
   Help[1]:='muze jit o chybu karty, nebo o jeji spatne nastaveni (viz autoexec.bat)';
   HelpLines:=2; { pocet vyuzitych radku helpu }

   CreateMenu(0,LineNo); { konec na stisk klavesy }

   Title[0]:='UPOZORNENI';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   MenuLines:=1; { pocet vyuzitych radku menu }
   MenuWidth:=66; { sirka menu ve znacich }
   Menu[0]:='V pripade problemu se zvukem doporucujeme resetovat pocitac.';
   CreateMenu(0,LineNo);
end;

{ ***** }
procedure TestZvuku(var LineNo:Word);
{
}
begin
   Title[0]:='BYL ZVUK SLYSET ?';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   Menu[0]:=' ANO '; Menu[1]:=' NE ';
   MenuLines:=2; { pocet vyuzitych radku menu }
   MenuWidth:=8; { sirka menu ve znacich }
   Help[0]:='Nyni byla testovana zvukova karta. Pokud nebyl slyset zadny zvuk,';
   Help[1]:='muze jit o chybu karty, nebo o jeji spatne nastaveni (viz autoexec.bat)';
   HelpLines:=2; { pocet vyuzitych radku helpu }

   CreateMenu(1,LineNo); { konec na stisk klavesy }
end;

{ ***** }
procedure YES_NO(var LineNo:Word);
{ title 0 definuje volajici
}
begin
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   Menu[0]:=' ANO '; Menu[1]:=' NE ';
   MenuLines:=2; { pocet vyuzitych radku menu }
   MenuWidth:=8; { sirka menu ve znacich }
   Help[0]:='';
   HelpLines:=1; { pocet vyuzitych radku helpu }

   CreateMenu(1,LineNo); { konec na stisk klavesy }
end;

{ ***** }
procedure PestrostZvuku(var LineNo:Word);
{
}
begin
   Title[0]:='Pestrost zvuku';
   TitleLines:=1; { pocet vyuzitych radku titulku }
   TitleWidth:=Length(Title[0]); { sirka titulku  ve znacich }
   Menu[0]:=' Nahrat vsechny zvuky '; Menu[1]:=' Nahrat jen nektere zvuky ';
   Menu[2]:=' Zadne zvuky ';
   MenuLines:=3; { pocet vyuzitych radku menu }
   MenuWidth:=40; { sirka menu ve znacich }
   Help[0]:='Nahrat vsechny zvuky = pestrejsi "mluveni jednotek", vyzaduje 7Mb RAM';
   Help[1]:='Nahrat jen nektere zvuky = pestrost mensi asi o 50%, vyzaduje 4Mb RAM';
   Help[2]:='pozn. Ostatni efekty (mimo zvuku jednotek a zvuku pozadi), nejsou ';
   Help[3]:='volbami ovlivneny.';
   Help[4]:='Zadne zvuky = ve hre nebude pouzit zvuk';
   HelpLines:=5; { pocet vyuzitych radku helpu }

   CreateMenu(1,LineNo); { konec na stisk klavesy }
end;

{ ************************************************************************** }
begin
  Install:=True;
  Assign(Snd,'$$$.CFG');
  Rewrite(Snd,1); I:=IOResult; if (I = 0) then Install:=False;
  Close(Snd); Erase(Snd); I:=IOResult;{}

  VRam:=SegB800;
  Introduce; MaxRes:=0;
  Assign(Snd,'sound.cfg');
  Reset(Snd,1); I:=IOResult;
  BlockRead(Snd,SoundDetected,SizeOf(Boolean));
  if (IOResult <> 0) then begin
      SoundDetected:=False;
  end;
  BlockRead(Snd,PartialSound,SizeOf(Byte));
  if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
      PartialSound:=0;
  end;
  BlockRead(Snd,BaseIO,SizeOf(BaseIO));
  if (IOResult <> 0) then begin SoundDetected:=False; end;
  BlockRead(Snd,IRQ,SizeOf(IRQ));
  if (IOResult <> 0) then begin SoundDetected:=False; end;
  BlockRead(Snd,DMA,SizeOf(DMA));
  if (IOResult <> 0) then begin SoundDetected:=False; end;
  BlockRead(Snd,DMA16,SizeOf(DMA16));
  if (IOResult <> 0) then begin SoundDetected:=False; end;

  Close(Snd);
  I:=IOResult;
  { * }
  asm
      mov Ah,10h
      mov Al,10h
      mov Bl,2
      mov Ch,40
      mov Cl,0
      mov Dh,0
      Int 10h
  end;

  repeat
    Main(LineNo);
    case (LineNo) of
      1: begin { videokarta }
           repeat
             VideoKarta(LineNo);
             case (LineNo) of
                1 : begin { vesa test + maximalni rozliseni }
                       VesaTest;
                       SetMaxRes(LineNo);
                       case (LineNo) of
                         1 : begin
                               PomRes:=0;
                               Assign(Vesa,'vesa.cfg'); ReWrite(Vesa,1);
                               if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                  TextColor(15); TextBackGround(0);
                                  Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                               end;
                               BlockWrite(Vesa,PomRes,2);
                               Num1:=VesaDetected;
                               BlockWrite(Vesa,Num1,1);
                               if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                  TextColor(15); TextBackGround(0);
                                  Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                               end;
                               BlockWrite(Vesa,Granularity,2);
                               if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                 TextColor(15); TextBackGround(0);
                                 Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                               end;
                               Close(Vesa);
                             end;
                         2 : begin
                               if (MaxRes > 0) then begin
                                 PomRes:=1;
                                 Assign(Vesa,'vesa.cfg'); ReWrite(Vesa,1);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 BlockWrite(Vesa,PomRes,2);
                                 Num1:=VesaDetected;
                                 BlockWrite(Vesa,Num1,1);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 BlockWrite(Vesa,Granularity,2);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                   TextColor(15); TextBackGround(0);
                                  Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 Close(Vesa);
                               end else LineNo:=100;
                             end;
                         3 : begin
                               if (MaxRes > 1) then begin
                                 PomRes:=2;
                                 Assign(Vesa,'vesa.cfg'); ReWrite(Vesa,1);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 BlockWrite(Vesa,PomRes,2);
                                 Num1:=VesaDetected;
                                 BlockWrite(Vesa,Num1,1);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 BlockWrite(Vesa,Granularity,2);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                   TextColor(15); TextBackGround(0);
                                  Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 Close(Vesa);
                               end else LineNo:=100;
                             end;
                         4 : begin
                               if (MaxRes > 2) then begin
                                 PomRes:=3;
                                 Assign(Vesa,'vesa.cfg'); ReWrite(Vesa,1);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 BlockWrite(Vesa,PomRes,2);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 Num1:=VesaDetected;
                                 BlockWrite(Vesa,Num1,1);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                    TextColor(15); TextBackGround(0);
                                    Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 BlockWrite(Vesa,Granularity,2);
                                 if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                                   TextColor(15); TextBackGround(0);
                                  Writeln('Chyba pri zapisu do souboru vesa.cfg'); Halt(0);
                                 end;
                                 Close(Vesa);
                               end else LineNo:=100;
                             end;
                         5 : begin
                                 LineNo:=100;
                             end;
                       end;
                    end;
                2 : begin { zpet }
                       LineNo:=100;
                    end;
                 65535 : begin { Esc }
                       LineNo:=100;
                    end;
             end;
           until (LineNo = 100);
         end;
      2: begin { zvuk }
           repeat
             HandleSound(LineNo);
             case (LineNo) of
                1 : begin { test zvukove karty }
                       TestZvukoveKarty;
                       Assign(Snd,'sound.cfg');
                       ReWrite(Snd,1);
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                          TextColor(15); TextBackGround(0);
                          Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,SoundDetected,SizeOf(Boolean));
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                         TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,PartialSound,SizeOf(Byte));
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                         TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,BaseIO,SizeOf(BaseIO));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,IRQ,SizeOf(IRQ));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,DMA,SizeOf(DMA));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,DMA16,SizeOf(DMA16));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;

                       Close(Snd);
                    end;
                2 : if (SoundDetected) then begin { test zvuku }
                       Menu[0]:='    Probiha testovani';
                       Wait;
                       if (not TestingSound) then begin
                         LineNo:=2; { chyba! }
                         Menu[0]:='Chyba pri praci se souborem test.raw nebo pri praci se zvukovou kartou';
                         _Error;
                       end else begin
                         TestZvuku(LineNo);
                       end;
                       case (LineNo) of
                         1 : begin { zvuk byl slyset }
                                 SoundDetected:=True;
                             end;
                         2 : begin { zvuk nebyl slyset }
                                SoundDetected:=False;
                             end;
                       end;
                       Assign(Snd,'sound.cfg'); ReWrite(Snd,1);
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                          TextColor(15); TextBackGround(0);
                          Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,SoundDetected,SizeOf(Boolean));
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                         TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,PartialSound,SizeOf(Byte));
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                         TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,BaseIO,SizeOf(BaseIO));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,IRQ,SizeOf(IRQ));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,DMA,SizeOf(DMA));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,DMA16,SizeOf(DMA16));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;

                       Close(Snd);
                    end;
                3 : if (SoundDetected) then begin { partial sound }
                       PestrostZvuku(LineNo);
                       case (LineNo) of
                         1 : begin { vsechny efekty }
                                PartialSound:=2;
                             end;
                         2 : begin { cast efektu }
                                PartialSound:=1;
                             end;
                         3 : begin { zadne efekty }
                                PartialSound:=0;
                             end;
                       end;
                       Assign(Snd,'sound.cfg'); ReWrite(Snd,1);
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                          TextColor(15); TextBackGround(0);
                          Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,SoundDetected,SizeOf(Byte));
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                         TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,PartialSound,SizeOf(Byte));
                       if ((IOResult <> 0) or (DosExitCode <> 0) or (DosError <> 0)) then begin
                         TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0);
                       end;
                       BlockWrite(Snd,BaseIO,SizeOf(BaseIO));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,IRQ,SizeOf(IRQ));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,DMA,SizeOf(DMA));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;
                       BlockWrite(Snd,DMA16,SizeOf(DMA16));
                       if (IOResult <> 0) then begin TextColor(15); TextBackGround(0);
                         Writeln('Chyba pri zapisu do souboru sound.cfg'); Halt(0); end;

                       Close(Snd);
                    end;
               4 : begin { zpet }
                       LineNo:=100;
                    end;
               65535 : begin { Esc }
                       LineNo:=100;
                    end;
             end;
           until (LineNo = 100);
         end;
      3: begin { konec }
            LineNo:=65535;
         end;
    end;
  until (LineNo = 65535);

  ShutDown;
  TextMode(CO80);{}
end.