unit GlobalKod;
{$C FIXED PRELOAD PERMANENT}
interface

procedure Get_units_data;
procedure ClearCoreSelection;
procedure InitCoreStruct(All:Boolean);
procedure CorePanel;
procedure InitGlobalModif;
procedure GameLost;
function DrawMissionSelect:Byte;
procedure OfferNewCoreUnit;
procedure OfferSpecialCoreUnit(UnType:Word; Levl:Byte; Nam:String);
procedure BuildInfoRecord;
procedure SetActionLevel(ActionLev:Byte);
procedure SetGlobalModif;
procedure SaveGlobalModif;

var GlobalInfoStr:array[0..15] of String[80];
    MaxUsedGlobalInfo:Byte;
    Mission1InfoStr:array[0..15] of String[80];
    MaxUsedMission1Info:Byte;
    Mission2InfoStr:array[0..15] of String[80];
    MaxUsedMission2Info:Byte;

implementation

uses Crt, Data_glb, GlobGraf, Specgraf, Buttons, Mouse, Graph257;

type TCach = array[0..15000] of Byte;
const Speed : array[0..6] of TSpeedArray =
            ((1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,1,1,1,1,1,1,1,1,1),
             (2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1),
             (2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,1,1,1,1,1,1,1,1,1,1),
             (3,3,3,3,3,3,3,3,3,3,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (5,6,5,5,6,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1));

var Cach:^TCach; { /// }
    EndCach:Word;{ /// }
    CachUk:Word;  { /// }
    Row : Byte; { /// }
    TUI:TUnitInfo;
    CfgFile:File;
    RenamePressed:Boolean; { True, bylo-li stisknuto tlacitko "Prejmenovat" }

{ ***** }
procedure FileRead(var Doomy:File; var Buffer:Char; Size:Word);
{
}
begin
   if (CachUk < EndCach) then begin
     Buffer:=Char(Cach^[CachUk]);
     Inc(CachUk);
   end;
end;

{ ***** }
function EOF(var Doomy:File):Boolean;
{
}
begin
   if (CachUk >= EndCach) then EOF:=True else EOF:=False;
end;

{ ***** }
procedure UnGet(var Doomy:File);
{
}
begin
   if (CachUk > 0) then Dec(CachUk);
end;

{ ***** }
procedure Get_Character(var Units_data:File; var Row: Byte; var Number,Number2:Byte; var Ret:String);
{ ziska cislo a retezec, ktery je na aktualni pozici v souboru Units_data;
  Row je cislo prave zpracovavane jednotky;
  Number2 je druha hranice pro dve cisla, oddelene pomlckou
}
var Ch:Char;
    Result,Pom:Word;
    Konec:Boolean;
    Num:Byte;
begin
   Ret:=''; Konec:=False; Number:=0; Number2:=0;
   while ((not Konec) and (not Eof(Units_data))) do begin
     FileRead(Units_data,Ch,1);
     Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
     case (Ch) of
        ';': begin { nasleduje nazev vozidla - vynecha se }
               Inc(Row);
               FileRead(Units_data,Ch,1);
               Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               while ((Ch <> ' ') and (not Eof(Units_data))) do begin
               { vynech vsechny znaky do mezery }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
               while ((Ch = ' ') and (not Eof(Units_data))) do begin
               { vynech vsechny mezery }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Error(0,'Neocekavany konec souboru');
               UnGet(Units_data);
               Konec:=True;
             end;
        ' ': begin { mezera - vynecha se }
               while ((Ch = ' ') and (not Eof(Units_data))) do begin
               { vynech vsechny mezery }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Error(0,'Neocekavany konec souboru');
               UnGet(Units_data);
             end;
        ':': begin
               { nasleduje cislo }
               FileRead(Units_data,Ch,1);
               Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               while (Ch in ['0'..'9']) and (not Eof(Units_data)) do begin
               { nacti vsechna cisla }
                  Val(Ch,Num,Pom);
                  Number:=Number*10+Num;
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Error(0,'Neocekavany konec souboru');
               if (Ch = '-') then begin { dve cisla, oddelana pomlckou }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
                  while (Ch in ['0'..'9']) and (not Eof(Units_data)) do begin
                  { nacti vsechna cisla }
                    Val(Ch,Num,Pom);
                    Number2:=Number2*10+Num;
                    FileRead(Units_data,Ch,1);
                    Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
                  end;
                 if (Eof(Units_data)) then Error(0,'Neocekavany konec souboru');
               end;
               UnGet(Units_data);
               Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
               Konec:=True;
             end;
        Chr($0d): begin {EOL} { vynecha se }
                      ;
                  end;
        Chr($0a): begin {EOL} { vynecha se }
                  end;
     else
       while (Ch <> ':') and (not Eof(Units_data)) do begin
       { nacti retezec }
          if ((Ch <> #9) and (Ch <> ' ')) then
             Ret:=Ret+Ch;
          FileRead(Units_data,Ch,1);
          Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
       end;
       if (Eof(Units_data)) then Error(0,'Neocekavany konec souboru');
       UnGet(Units_data);
       Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
     end;{}
   end;
   if (Eof(Units_data)) then Ret:='EndOfFile';
end;

{ ***** }
procedure Get_units_data;
{ ziska nektere parametry jednotek z disku
}
var Units_data:File;
    Ch:Char;
    Result,Pom:Word;
    Number, Number2:Byte;
    Ret:String;
begin
   New(Cach);
   {Writeln('pracuji...');{}
   { ENEMY }
   Assign(Units_data,PathStr+'missions\units'+MissionNameString+'e.dbg');
   Reset(Units_data,1);
   Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
   BlockRead(Units_data,Cach^,FileSize(Units_data));
   EndCach:=FileSize(Units_data);
   CachUk:=0;

   Row:=0;
   while (not Eof(Units_data)) do begin
      Get_Character(Units_data,Row,Number,Number2,Ret);
      if (Ret = 'L1') then begin
         Unit_types^[Row,0].LightAttack1:=Number;
      end;
      if (Ret = 'T1') then begin
                  Unit_types^[Row,0].HeavyAttack1:=Number;
               end;
      if (Ret = 'A1') then begin
                  Unit_types^[Row,0].AirAttack1:=Number;
               end;
      if (Ret = 'DOSTREL1') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types^[Row,0].ShootRange1:=Pom;
                    end;
     if (Ret = 'KADENCE1') then begin
                       Unit_types^[Row,0].ShootSpeed1:=Number;
                    end;
     if (Ret = 'L2') then begin
                  Unit_types^[Row,0].LightAttack2:=Number;
               end;
      if (Ret = 'T2') then begin
                  Unit_types^[Row,0].HeavyAttack2:=Number;
               end;
      if (Ret = 'A2') then begin
                  Unit_types^[Row,0].AirAttack2:=Number;
               end;
      if (Ret = 'DOSTREL2') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types^[Row,0].ShootRange2:=Pom;
                    end;
      if (Ret = 'KADENCE2') then begin
                       Unit_types^[Row,0].ShootSpeed2:=Number;
                    end;
      if (Ret = 'OBRANA') then begin
                      Unit_types^[Row,0].DefenceStrength:=Number;
                   end;
      if (Ret = 'RYCHLOST') then begin
                     if (Number > 0) then begin
                         Unit_types^[Row,0].SpeedLevel:=Number-1;
                         Unit_types^[Row,0].MovementAdding:=Speed[Number-1];
                     end;
                 end;
      if (Ret = 'BP') then begin
                  Unit_types^[Row,0].BP:=Number;
               end;
      if (Ret = 'PL') then begin
                  Unit_types^[Row,0].PL:=Number;
               end;
      if (Ret = 'EE') then begin
                  Unit_types^[Row,0].EE:=Number;
               end;
      if (Ret = 'EXP') then begin
                  Unit_types^[Row,0].EX:=Number;
                end;{}
      if (Ret = 'PAUSETYPE1') then begin
                  Unit_types^[Row,0].ShootType1:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY1') then begin
                  Unit_types^[Row,0].ShootDelay1:=Number;
                end;{}
       if (Ret = 'PAUSETYPE2') then begin
                  Unit_types^[Row,0].ShootType2:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY2') then begin
                  Unit_types^[Row,0].ShootDelay2:=Number;
                end;{}
      if (Ret = 'CAPACITY') then begin
                  Unit_types^[Row,0].Capacity:=Number;
                end;{}
      if (Ret = 'SIGHT') then begin
                  Unit_types^[Row,0].Sight:=Number;
                end;{}
   end;
   Close(Units_data); IO_Result:=IOResult;

   { ALLY }
   Assign(Units_data,PathStr+'missions\units'+MissionNameString+'f.dbg');
   Reset(Units_data,1);
   Result:=IOResult; if (Result <> 0) then Error(Result,'Chyba pri praci se souborem units.dbg');
   BlockRead(Units_data,Cach^,FileSize(Units_data));
   EndCach:=FileSize(Units_data);
   CachUk:=0;

   Row:=0;
   while (not Eof(Units_data)) do begin
      Get_Character(Units_data,Row,Number,Number2,Ret);
      if (Ret = 'L1') then begin
         Unit_types^[Row,1].LightAttack1:=Number;
      end;
      if (Ret = 'T1') then begin
                  Unit_types^[Row,1].HeavyAttack1:=Number;
               end;
      if (Ret = 'A1') then begin
                  Unit_types^[Row,1].AirAttack1:=Number;
               end;
      if (Ret = 'DOSTREL1') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types^[Row,1].ShootRange1:=Pom;
                    end;
     if (Ret = 'KADENCE1') then begin
                       Unit_types^[Row,1].ShootSpeed1:=Number;
                    end;
     if (Ret = 'L2') then begin
                  Unit_types^[Row,1].LightAttack2:=Number;
               end;
      if (Ret = 'T2') then begin
                  Unit_types^[Row,1].HeavyAttack2:=Number;
               end;
      if (Ret = 'A2') then begin
                  Unit_types^[Row,1].AirAttack2:=Number;
               end;
      if (Ret = 'DOSTREL2') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types^[Row,1].ShootRange2:=Pom;
                    end;
      if (Ret = 'KADENCE2') then begin
                       Unit_types^[Row,1].ShootSpeed2:=Number;
                    end;
      if (Ret = 'OBRANA') then begin
                      Unit_types^[Row,1].DefenceStrength:=Number;
                   end;
      if (Ret = 'RYCHLOST') then begin
                    if (Number > 0) then begin
                       Unit_types^[Row,1].SpeedLevel:=Number-1;
                       Unit_types^[Row,1].MovementAdding:=Speed[Number-1];
                    end;
                 end;
      if (Ret = 'BP') then begin
                  Unit_types^[Row,1].BP:=Number;
               end;
      if (Ret = 'PL') then begin
                  Unit_types^[Row,1].PL:=Number;
               end;
      if (Ret = 'EE') then begin
                  Unit_types^[Row,1].EE:=Number;
               end;
      if (Ret = 'EXP') then begin
                  Unit_types^[Row,1].EX:=Number;
                end;{}
      if (Ret = 'PAUSETYPE1') then begin
                  Unit_types^[Row,1].ShootType1:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY1') then begin
                  Unit_types^[Row,1].ShootDelay1:=Number;
                end;{}
       if (Ret = 'PAUSETYPE2') then begin
                  Unit_types^[Row,1].ShootType2:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY2') then begin
                  Unit_types^[Row,1].ShootDelay2:=Number;
                end;{}
      if (Ret = 'CAPACITY') then begin
                  Unit_types^[Row,1].Capacity:=Number;
                end;{}
      if (Ret = 'SIGHT') then begin
                  Unit_types^[Row,1].Sight:=Number;
                end;{}
   end;
   Dispose(Cach); Cach:=Nil;
   Close(Units_data); IO_Result:=IOResult;
end;

{ ***** }
procedure ClearCoreSelection;
{ vymaze vsechny vybery jednotek jadra (inicializace na zacatku hry)
}
var I:Word;
begin
  for I:=0 to ((MaxCoreUnits-1) div 3) do with (CoreStruct[I]) do begin
     with (CoreStruct[I*3]) do begin
        Selected:=False;
     end;
     with (CoreStruct[I*3+1]) do begin
        Selected:=False;
     end;
     with (CoreStruct[I*3+2]) do begin
        Selected:=False;
     end;
  end;
end;

{ ***** }
procedure InitCoreStruct(All:Boolean);
{  inicializuje struktury jadra;
   All=True inicializuje vse, All=False inicializuje pouze souradnice
}
const XSize = 22*XFontSize-1; YSize = 43;
var X,Y,X2,Y2,I,XSpace,YSpace:Word;
    TUI:TUnitInfo; {//TEMP//}
begin
  if (All) then Core.Init;

  X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;{}
  Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;{}

  XSpace:=(X2-X-40-3*XSize) shr 1;
  YSpace:=(Y2-Y-70-(MaxCoreUnits div 3 + 1)*YSize) div (MaxCoreUnits div 3);
  Inc(X,20); Inc(Y,16);
  for I:=0 to ((MaxCoreUnits-1) div 3) do with (CoreStruct[I]) do begin
     with (CoreStruct[I*3]) do begin
        if (All) then begin
          Activity:=False;  UniqueNumber:=65535;
        end;
        X1:=X; X2:=X1+XSize; Y1:=Y; Y2:=Y1+YSize;
        XPicture:=X1+4; YPicture:=Y1+3;
        XName:=XPicture+48; YName:=Y1+(YSize-2*YFontSize) shr 1;
        XRank:=XName; YRank:=YName+YFontSize+YFontSize shr 2;
        if (All) then Selected:=False;
     end;
     with (CoreStruct[I*3+1]) do begin
        if (All) then begin
          Activity:=False;  UniqueNumber:=65535;
        end;
        X1:=X+XSpace+XSize; X2:=X1+XSize; Y1:=Y; Y2:=Y1+YSize;
        XPicture:=X1+4; YPicture:=Y1+3;
        XName:=XPicture+48; YName:=Y1+(YSize-2*YFontSize) shr 1;
        XRank:=XName; YRank:=YName+YFontSize+YFontSize shr 2;
        if (All) then Selected:=False;
     end;
     with (CoreStruct[I*3+2]) do begin
        if (All) then begin
          Activity:=False;  UniqueNumber:=65535;
        end;
        X1:=X+2*XSpace+2*XSize; X2:=X1+XSize; Y1:=Y; Y2:=Y1+YSize;
        XPicture:=X1+4; YPicture:=Y1+3;
        XName:=XPicture+48; YName:=Y1+(YSize-2*YFontSize) shr 1;
        XRank:=XName; YRank:=YName+YFontSize+YFontSize shr 2;
        if (All) then Selected:=False;
     end;
     Inc(Y,YSize+YSpace);
  end;
  if (OSNPlayer and All) then begin
     if (Rand(RndUk) mod 2 = 0) then begin
      {//x//} TUI.UnitType:=15; TUI.Level:=0; TUI.Name:='5.OSN RANGERS'; TUI.Experience:=0; TUI.Kills:=0; Core.Insert(TUI);
     end else begin
      {//x//} TUI.UnitType:=7; TUI.Level:=2; TUI.Name:='1.PARA OSN'; TUI.Experience:=0; TUI.Kills:=0; Core.Insert(TUI);
      {//x//} TUI.UnitType:=7; TUI.Level:=2; TUI.Name:='1.PARA OSN'; TUI.Experience:=0; TUI.Kills:=0; Core.Insert(TUI);
     end;
     if (Rand(RndUk) mod 2 = 0) then begin
      {//x//} TUI.UnitType:=12; TUI.Level:=2; TUI.Name:='3.OSN APCs'; TUI.Experience:=0; TUI.Kills:=0; Core.Insert(TUI);
     end else begin
      {//x//} TUI.UnitType:=9; TUI.Level:=0; TUI.Name:='1.PARA OSN'; TUI.Experience:=0; TUI.Kills:=0; Core.Insert(TUI);
     end;
  end;
end;

{+}{ xxx }
{+}procedure DrawCoreUnitInfo(TUI:TUnitInfo; Slot:Word);
{+}{ vykresli nazev jednotky UnitType do slotu Slot
{+}
{+}var Ret:String;
{+}begin
{+}  CursorOff;
{+}  with (CoreStruct[Slot]) do begin
{+}    Activity:=True;
{+}    Rectangle2(XName,YName,XName+XFontSize*15,YName+YFontSize,75);
{+}    OutTextColor(XName,YName,64,TUI.Name);
{+}    if (Selected) then begin
{+}      Frame2(X1+1,Y1+1,X2+1,Y2+1,164);
{+}      Frame2(X1,Y1,X2,Y2,160);
{+}    end else begin
{+}      Frame2(X1+1,Y1+1,X2+1,Y2+1,72);
{+}      Frame2(X1,Y1,X2,Y2,68);
{+}    end;
{+}    Rectangle(XPicture,YPicture,XPicture+37,YPicture+37,75);
{+}    Frame(XPicture,YPicture,XPicture+37,YPicture+37,72);
{+}    SpecSpeedPutImage3(XPicture,YPicture,
{+}                       Unit_pictures[TUI.UnitType].S,
{+}                       Unit_pictures[TUI.UnitType].O,
{+}                       0,0,37,37,176);
{+}     Str(TUI.Level,Ret); Ret:='HODNOST: '+Ret;
{+}     OutTextColor(XRank,YRank,68,Ret);
{+}  end;
{+}  CursorOn;
{+}end;

{ ***** }
{+}function TestCoreSlots(X,Y:Word):Byte;
{+}{ vraci 255 pro neuspech, jinak cislo slotu, ktery je uvnitr pozice X,Y
   }
{+}var I:Word;
{+}begin
{+}  TestCoreSlots:=255;
{+}  for I:=0 to MaxCoreUnits-1 do with (CoreStruct[I]) do begin
{+}     if ((X >= X1) and (X <= X2) and (Y >= Y1) and (Y <= Y2))
{+}     then TestCoreSlots:=I;
{+}  end;
{+}end;

{ ***** }
procedure DrawCoreInfo;
{ vrati informace o posilach
{
}
var TUI:TUnitInfo;
    X,Y,I, J:Word;
    Ret,Ret2:String;
begin
   for I:=0 to MaxCoreUnits-1 do CoreStruct[I].Activity:=False;

   Core.First; I:=0;
   while (not Core.Invalid) do begin
     if (Core.GetActive(TUI)) then with (CoreStruct[I]) do begin
        Activity:=True;
        UniqueNumber:=TUI.UniqueNumber;
        Inc(I);
     end;
     Core.Next;
   end;
   for I:=0 to MaxCoreUnits-1 do with (CoreStruct[I]) do
   if (Activity) then begin { vykresleni }
     if (Core.GetUnique(UniqueNumber,TUI)) then begin
        DrawCoreUnitInfo(TUI,I);
     end;
   end;

   X:=(XResolution-XResearchInfoSize) shr 1;
   X:=X+(XResearchInfoSize-Length(' DO NaSLEDUJeCe MISE:   (MAX.  )')*XFontSize) shr 1;
   Y:=(YResolution-YResearchInfoSize) shr 1;
   Y:=Y+YResearchInfoSize-2*BigButtonYSize-2*YFontSize;
   Str(CoreSelectedCount,Ret);
   Str(MaxMissionCoreUnits,Ret2); Ret2:=' (MAX. '+Ret2+')';
   CursorOff;
   Rectangle2(X,Y,X+Length(' DO NaSLEDUJeCe MISE:  '+Ret2)*XFontSize,Y+YFontSize,0);
   OutTextColor(X,Y,64,' DO NaSLEDUJeCe MISE: '+Ret+Ret2);
   CursorOn;
end;

{ ***** }
procedure CorePanel;
{  panel pro ovladani voleb jadra
}
label Again;
var X,Y,X2,Y2:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
    I:Word;
    Slot:Byte;
    TUI:TUnitInfo;
    Ret, Ret2:String;
{ xxx }
begin
   SetPasive(ResearchButton,256);
   SetPasive(DalsiTydenButton,256);
   SetPasive(CoreButton,256);
   SetPasive(InfoButton,256);
   SetPasive(OptionButton,256);
   SetPasive(SaveButton,256);
   SetPasive(LoadButton,256);
   SetPasive(EndButton,256);
   SetPasive(StartButton,256);

   ScreenOff;
   X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
   Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
   ShowInfoPanel(X,Y,X2,Y2,0); ScreenOff;
   CursorOff;
   GetImage(X,Y,X2,Y2,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;

Again:
   X:=(XResolution-XResearchInfoSize) shr 1 + (XResearchInfoSize-2*BigButtonXSize-SmallButtonXSize) shr 1;
   Y:=(YResolution-YResearchInfoSize) shr 1;
   Y:=Y+YResearchInfoSize-2*BigButtonYSize;
   CreateButton(X,Y,0,0,False,_Temp1); ButtonText(_Temp1,65,'KONEC');
   Inc(X,BigButtonXSize+SmallButtonXSize);
   CreateButton(X,Y,0,0,False,_Temp2); ButtonText(_Temp2,65,'PfEJMENOVAT');

   CursorOff;
   Release(_Temp1); Release(_Temp2);
   CursorOn;
   SetActive(_Temp1); SetActive(_Temp2);
   ScreenOn;

   { ** vlastni prace s informacnim panelem ** }
   Konec:=False; DrawCoreInfo; RenamePressed:=False;
   while not (Konec) do begin
      Button:=0;
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
          0          : if (Scan = $01) then Konec:=True { Esc }
                       else begin { klavesy }
                         if (Button <> 0) then begin
                            SoundPlay(0,0,0,0);
                            Slot:=TestCoreSlots(X,Y);
                            if ((Slot <> 255) and (CoreStruct[Slot].Activity))
                            then begin
                              if (not RenamePressed) then begin
                                 if (CoreStruct[Slot].Selected) then begin
                                   CoreStruct[Slot].Selected:=False;
                                   CoreSelectedCount:=CoreSelectedCount-1;
                                 end else begin
                                   if (CoreSelectedCount <  MaxMissionCoreUnits) then begin
                                     CoreStruct[Slot].Selected:=True;
                                     CoreSelectedCount:=CoreSelectedCount+1;
                                   end;
                                 end;
                                 if (Core.GetUnique(CoreStruct[Slot].UniqueNumber,TUI)) then begin
                                   CursorOff;
                                   DrawCoreUnitInfo(TUI,Slot);
                                   X:=(XResolution-XResearchInfoSize) shr 1;
                                   X:=X+(XResearchInfoSize-Length(' DO NaSLEDUJeCe MISE:   (MAX.  )')*XFontSize) shr 1;
                                   Y:=(YResolution-YResearchInfoSize) shr 1;
                                   Y:=Y+YResearchInfoSize-2*BigButtonYSize-2*YFontSize;
                                   Str(CoreSelectedCount,Ret);
                                   Str(MaxMissionCoreUnits,Ret2); Ret2:=' (MAX. '+Ret2+')';
                                   CursorOff;
                                   Rectangle2(X,Y,X+Length(' DO NaSLEDUJeCe MISE:  '+Ret2)*XFontSize,Y+YFontSize,0);
                                   OutTextColor(X,Y,64,' DO NaSLEDUJeCe MISE: '+Ret+Ret2);
                                   CursorOn;

                                   CursorOn;
                                 end;
                                 Delay(100);
                                 Mouse.ButtonClick:=0; Mouse.Button:=0;
                              end else begin
                                RenamePressed:=False;
                                if (GetString(15,Ret)) then
                                  if (Core.GetUnique(CoreStruct[Slot].UniqueNumber,TUI)) then begin
                                    TUI.Name:=Ret;
                                    Core.UpDate(CoreStruct[Slot].UniqueNumber,TUI);
                                    CursorOff;
                                    DrawCoreUnitInfo(TUI,Slot);
                                    CursorOn;
                                  end;
                              end;
                            end;
                         end;
                      end;
         _Temp1     : begin  { Konec }
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                      end;
         _Temp2     : begin  { Prejmenovani }
                        SoundPlay(0,0,0,0);
                        RenamePressed:=True;
                      end;
      end;
   end;
   { ** konec prace s informacnim panelem ** }
   RenamePressed:=False;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   CloseInfoPanel;

   SetActive(ResearchButton);
   SetActive(DalsiTydenButton);
   SetActive(CoreButton);
   SetActive(InfoButton);
   SetActive(OptionButton);
   SetActive(SaveButton);
   SetActive(LoadButton);
   SetActive(EndButton);
   SetActive(StartButton);
end;

{ ***** }
procedure InitGlobalModif;
{ inicializuje zmeny parametru pro danou misi
}
var I:Word;
begin
   { nastaveni pred ulozenim }
   GlobalModify.PlayerId:=PlayerId; { identifikace hrace }
   GlobalModify.Game:=Game;         { identifikace hry }
   GlobalModify.Campaign:=Campaign; { identifikace kampane }
   with (GlobalModify) do begin
      { modifikace typu jednotek: }
      UnitTypes:=Unit_types^;{}

      { nasledujici promenne urcuji pritomnost jednotek
        s nastavenym nejvyssim bitem SpecNumber: }
      FriendlySpecialUnitsPresent:=False;
      EnemySpecialUnitsPresent:=False;

      { True pro pritomnost spec. nepratelskych posil }
      EnemySpecialReinforcementPresent:=False;

      { nyni schema pro nasledujici hodnoty:
        0..False, 1..True, > 1..nezmeneno }
      UnknownTerrain:=2; FogOfWar:=2; AllyFog:=2;
      { modifikatory typu rasy:
        bud hodnota, nebo 255=zustat nezmenene }
      for I:=0 to MaxRace do
         RaceTypeModifiers[I]:=255;
      { modifikatory materialu v misi :
        bud hodnota zmeny v %, nebo MaxInt=zustat nezmenene }
      for I:=0 to MaxRace do with (RaceMaterialModifiers[I]) do begin
         BPModif:=MaxInt; PLModif:=MaxInt;
         EEModif:=MaxInt; ExpMOdif:=MaxInt;
      end;
      for I:=0 to MaxRace do RaceInitLevelModifier[I]:=255;
      for I:=0 to MaxCoreUnits-1 do CoreInfo[I].Active:=False;
      Temp1:=255; Temp2:=255; Temp3:=255;
      for I:=0 to 20 do Temp4[I]:=255;
   end;
end;

{ ***** }
procedure DrawEndOfGame;
{ vykresli zduvodneni konce hry
}
var X,Y,YSize,I,J:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
begin
   CursorOff;
   SetColor(160);
   YSize:=0;
   if (MaxUsedGlobalInfo <> 255) then YSize:=(YFontSize+1)*(MaxUsedGlobalInfo+1);

   Y:=(YResolution-YSize) shr 1+16;
   X:=(XResolution-XFontSize*77) shr 1;
   if (MaxUsedGlobalInfo <> 255) then begin
     for I:=0 to MaxUsedGlobalInfo do begin
       OutTextColor(X+1,Y+1,DarkBlue,GlobalInfoStr[I]);
       OutTextColor(X,Y,Blue,GlobalInfoStr[I]);
       Inc(Y,YFontSize+1);
     end;
   end;
   Inc(Y,40);

   Y:=YResolution-BigButtonYSize shl 1;
   X:=(XResolution-BigButtonXSize) shr 1;

   { VYTVORENI TLACITEK }
   CreateButton(X,Y,0,0,False,_Temp1);
   ButtonText(_Temp1,TextColor,'OK');
   Release(_Temp1); SetActive(_Temp1);
   CursorOn;

   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         _Temp1     : begin { mise a) }
                        SoundPlay(0,0,0,0);
                        Konec:=True;
                      end;
      end;
   end;
   CursorOff;
   DeleteButton(_Temp1,256);
   ClearScreen;
   LoadRGB(0,PathStrGlobal+'data\paleta1.rgb');
   Blue:=98; DarkBlue:=108; Yellow:=160; DarkYellow:=165; White:=66;
   OpenImage(PathStrGlobal+'data\buttons.glb',NoCreateNew);
   LoadImageGBM(On1Seg,On1Offs,'on1',0);
   LoadImageGBM(Off1Seg,Off1Offs,'off1',0);
   {X}
   OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
   LoadImageGBM(CursorSegment,CursorOffsets,'normal',0);
   {X}
   CursorOn;
end;


{ ***** }
procedure GameLost;
{
}
begin
 if ((VICTORYPOINTS < VPointsPerMission) or
      (POINTS < PointsPerMission)) then begin
     GlobalInfoStr[0]:='   NEhSPdCHY VAgEHO VELENe ZPiSOBILY OSN VYSOKc FINANbNe ZTRaTY. ZA TcTO';
     GlobalInfoStr[1]:='SITUACE NEMikETE DaLE SETRVAT VE SVc FUNKCI. ROZHODNUTeM NEJVYggeHO VELENe';
     GlobalInfoStr[2]:='JSTE OKAMkITd ODVOLaN.';
     MaxUsedGlobalInfo:=2;
 end else begin
   if (Campaign=1) then begin
    case (Game) of
       1 : begin { uvodni mise }
              GlobalInfoStr[0]:='   BOHUkEL, VAg NEhSPdCH MdL TdkKc DiSLEDKY PRO DALge POSTUP OPERACE.';
              GlobalInfoStr[1]:='SPOJENECKc SeLY POD VELENeM GENERaLMAJORA W.SMITHE JEN S OBTekEMI';
              GlobalInfoStr[2]:='ZeSKALY PLaNOVANE POZICE. PODLE ROZHODNUTe NEJVYggeHO VELENe JSTE';
              GlobalInfoStr[3]:='ZE SVc FUNKCE OKAMkITd ODVOLaN.';
              MaxUsedGlobalInfo:=3;
           end;
       12: begin {}
              GlobalInfoStr[0]:='   BOHUkEL, VAg NEhSPdCH MdL TdkKc DiSLEDKY PRO NAgE SeLY V OBLASTI.';
              GlobalInfoStr[1]:='NA kaDOST GENERaLNeHO TAJEMNeKA OSN JSTE BYL ZE SVc FUNKCE ODVOLaN.';
              MaxUsedGlobalInfo:=1;
           end;
       20: begin {}
              GlobalInfoStr[0]:='   NAgE ODDeLY BYLY PORAkENY. JIk NENe NA SVdTd kaDNa SeLA, KTERa BY';
              GlobalInfoStr[1]:='DOKaZALA ROBOTiM VZDOROVAT. POSLEDNe MeSTA ODPORU NaRODNeCH ARMaD JSOU';
              GlobalInfoStr[2]:='NEMILOSRDNd LIKVIDOVaNA. baST LIDe SE PRO JISTOTU, VEDENA ZISKUCHTIVOSTe,';
              GlobalInfoStr[3]:='PfIDALA K VeTdZiM A PODeLe SE NA RABOVaNe A NaSILNOSTECH. JAKj OSUD NaS,';
              GlobalInfoStr[4]:='PORAkENc A SLABc bEKa ?';
              MaxUsedGlobalInfo:=4;
           end;
       26: begin {}
              GlobalInfoStr[0]:='   POMOC ODBOJE JE PRO NaS NEPOSTRADATELNa. PROTOkE JSME SELHALI V JEHO';
              GlobalInfoStr[1]:='PODPOfE, BYL ZLIKVIDOVaN. ROBOTI A JEJICH LIDgTe PfISLUHOVAbI SOUSTfEDILI';
              GlobalInfoStr[2]:='VgECHNY SVOJE SeLY NA NaS. TOMUTO NaPORU NEJSME SCHOPNI ODOLAT. POD hTOKY';
              GlobalInfoStr[3]:='NEPfaTELSKjCH SIL SE NAgE OBRANA ZCELA ZHROUTILA. TO JE KONEC.';
              MaxUsedGlobalInfo:=3;
           end;
       27: begin {}
              GlobalInfoStr[0]:='   POMOC ODBOJE JE PRO NaS NEPOSTRADATELNa. PROTOkE JSME SELHALI V JEHO';
              GlobalInfoStr[1]:='PODPOfE, BYL ZLIKVIDOVaN. ROBOTI A JEJICH LIDgTe PfISLUHOVAbI SOUSTfEDILI';
              GlobalInfoStr[2]:='VgECHNY SVOJE SeLY NA NaS. TOMUTO NaPORU NEJSME SCHOPNI ODOLAT. POD hTOKY';
              GlobalInfoStr[3]:='NEPfaTELSKjCH SIL SE NAgE OBRANA ZCELA ZHROUTILA. TO JE KONEC.';
              MaxUsedGlobalInfo:=3;
           end;
    34,35: begin
              GlobalInfoStr[0]:='   VZDEJME bEST MLADcMU DiSTOJNeKOVI, KTERj V TdkKjCH CHVeLeCH LIDSTVA VEDL';
              GlobalInfoStr[1]:='SVc MUkE K JEDINcMU CeLI: BOJOVAT POD VLAJKOU OSN ZA MeR A SPRAVEDLNOST.';
              GlobalInfoStr[2]:='PRO TENTO CeL OBdTOVAL VgE, I SViJ kIVOT. JEHO SMRT NEBYLA ZBYTEbNa. DRUHa';
              GlobalInfoStr[3]:='baST OPERACE "METHEOR" POD VEDENeM GENERaLA CRAMERA BYLA hSPdgNa.';
              MaxUsedGlobalInfo:=3;
           end;
    end;
   end; { if (Campaign=1) then begin }
 end; { if ((VICTORYPOINTS < VPointsPerMission) or
            (POINTS < PointsPerMission)) then .. else }
 DrawEndOfGame;
end;

{ ***** }
procedure OfferNewCoreUnit;
{ nabidne ke koupi novou jednotku jadra
}
var CoreSet:array[0..30] of Byte;
    Index,Pom:Integer;
    TUI:TUnitInfo;
    Price, VictoryPrice:LongInt;
    Str1, Str2, Str3:String;
begin
   Index:=-1;
   if ((ReserchAssign[5,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(5) < 4))
   then begin Inc(Index); CoreSet[Index]:=5; end;
   if ((ReserchAssign[6,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(6) < 4))
   then begin Inc(Index); CoreSet[Index]:=6; end;
   if ((ReserchAssign[7,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(7) < 8))
   then begin Inc(Index); CoreSet[Index]:=7; end;
   if ((ReserchAssign[9,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(9) < 8))
   then begin Inc(Index); CoreSet[Index]:=9; end;
   if ((ReserchAssign[13,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(13) < 8))
   then begin Inc(Index); CoreSet[Index]:=13; end;
   if ((ReserchAssign[14,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(14) < 2))
   then begin Inc(Index); CoreSet[Index]:=14; end;
   if ((ReserchAssign[15,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(15) < 3))
   then begin Inc(Index); CoreSet[Index]:=15; end;
   if ((ReserchAssign[16,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(16) < 3))
   then begin Inc(Index); CoreSet[Index]:=16; end;
   if ((ReserchAssign[10,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(10) < 5))
   then begin Inc(Index); CoreSet[Index]:=10; end;
   if ((ReserchAssign[11,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(11) < 5))
   then begin Inc(Index); CoreSet[Index]:=11; end;
   if ((ReserchAssign[12,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(12) < 3))
   then begin Inc(Index); CoreSet[Index]:=12; end;
   if ((ReserchAssign[35,1].UnitAvail > 0) and (Core.GetThisUnitTypeCount(35) < 5))
   then begin Inc(Index); CoreSet[Index]:=35; end;
   if ((Game >= 10) and (Core.GetThisUnitTypeCount(28) < 1)) then begin Inc(Index); CoreSet[Index]:=28; end;
   if ((Game >= 10) and (Core.GetThisUnitTypeCount(28) <= 4)) then begin Inc(Index); CoreSet[Index]:=28; end;

   if ((Game > 7) and (Game < 13) or (Game = 20)) then begin
     if (Game >= 8) then begin Inc(Index); CoreSet[Index]:=22; end;
     if ((Game >= 8) and (Core.GetThisUnitTypeCount(22) = 0)) then begin Inc(Index); CoreSet[Index]:=22; end;
     if ((Game >= 8) and (Core.GetThisUnitTypeCount(22) = 0)) then begin Inc(Index); CoreSet[Index]:=22; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(36) = 0)) then begin Inc(Index); CoreSet[Index]:=36; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(36) = 0)) then begin Inc(Index); CoreSet[Index]:=36; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(36) <= 1)) then begin Inc(Index); CoreSet[Index]:=36; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(36) <= 1)) then begin Inc(Index); CoreSet[Index]:=36; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(36) <= 1)) then begin Inc(Index); CoreSet[Index]:=36; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(25) <= 1)) then begin Inc(Index); CoreSet[Index]:=25; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(25) = 0)) then begin Inc(Index); CoreSet[Index]:=25; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(25) = 0)) then begin Inc(Index); CoreSet[Index]:=25; end;
     if ((Game >= 9) and (Core.GetThisUnitTypeCount(25) = 0)) then begin Inc(Index); CoreSet[Index]:=25; end;
   end;

   if ((Index >= 0) and (not Core.Full)) then begin
      repeat
        Pom:=Random(Index+1);
      until (((CoreSet[Pom] <> 14) or ((Rand(RndUk)+1) mod 3 <> 0)) and
             ((CoreSet[Pom] <> 15) or ((Rand(RndUk)+1) mod 3 <> 0)) and
             ((CoreSet[Pom] <> 5) or ((Rand(RndUk)+1) mod 3 <> 0)) and
             ((CoreSet[Pom] <> 6) or ((Rand(RndUk)+1) mod 3 <> 0)));

      with (TUI) do begin
         UnitType:=CoreSet[Pom];
         Experience:=0;
         Kills:=0;
         Level:=Rand(RndUk) shr 1;
         Name:=Unit_types^[UnitType,1].Name;
         VictoryPrice:=0;
         case (UnitType) of
            5 : Price:=420+Level*50+Rand(RndUk) shr 2;
            6 : Price:=420+Level*50+Rand(RndUk) shr 2;
            7 : Price:=510+Level*60+Rand(RndUk) shr 2;
            9 : Price:=620+Level*65+Rand(RndUk) shr 2;
            13: Price:=670+Level*65+Rand(RndUk) shr 2;
            14: Price:=1550+Level*100+Rand(RndUk) shr 2;
            15: Price:=1200+Level*100+Rand(RndUk) shr 2;
            16: Price:=950+Level*90+Rand(RndUk) shr 2;
            10: Price:=680+Level*60+Rand(RndUk) shr 2;
            11: Price:=700+Level*60+Rand(RndUk) shr 2;
            12: Price:=530+Level*60+Rand(RndUk) shr 2;
            22: Price:=420+Level*50+Rand(RndUk) shr 2;
            25: Price:=660+Level*80+Rand(RndUk) shr 2;
            28: Price:=660+Level*80+Rand(RndUk) shr 2;
            35: Price:=520+Level*50+Rand(RndUk) shr 2;
            36: Price:=760+Level*90+Rand(RndUk) shr 2;
         else
           Price:=1000+Level*50+Rand(RndUk) shr 2;
         end;
      end;
      if (POINTS > 0) then Price:=Price+Random(Round(POINTS/18));
      if ((Price > 450) and (Rand(RndUk) > 6)) then begin
         Price:=Price-450; Inc(VictoryPrice);
         if ((Price > 450) and (Rand(RndUk) > 5)) then begin
            Price:=Price-450; Inc(VictoryPrice);
         end;
      end;
      if ((Price > 450) and (Rand(RndUk) > 7)) then begin
         Price:=Price-450; Inc(VictoryPrice);
      end;

      if ((POINTS >= Price) and (VICTORYPOINTS >= VictoryPrice)) then begin
        Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
        Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
        Str(Price,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: ';
        Str(VictoryPrice,Str1); Str3:=Str3+Str1;
        Str(TUI.Level,Str1);
        if (SpecWideDialogBox(TUI.UnitType,'NABeZe SE VaM JEDNOTKA "'+TUI.Name+'" HODNOSTI:"'+Str1+'" ZA CENU:',
                              Str3,Str2,_YES_NO)=YES)
        then begin
          POINTS:=POINTS-Price; Core.Insert(TUI);
        end;
      end;
   end;
end;

{ ***** }
procedure OfferSpecialCoreUnit(UnType:Word; Levl:Byte; Nam:String);
{ nabidne novou specialni jednotku jadra
}
var CoreSet:array[0..15] of Byte;
    Index,Pom:Integer;
    TUI:TUnitInfo;
    Price, VictoryPrice:LongInt;
    Str1, Str2, Str3:String;
begin
   if (not Core.Full) then begin
      with (TUI) do begin
         UnitType:=UnType;
         Experience:=0;
         Kills:=0;
         Level:=Levl;
         Name:=Nam;
         Price:=0;
         VictoryPrice:=0;
         Str(TUI.Level,Str1);
         if (SpecWideDialogBox(TUI.UnitType,'                                                     ',
                               'CHCE SE K VaM PfIDAT "'+TUI.Name+'" HODNOSTI:"'+Str1+'"',
                               '',_YES_NO)=YES)
         then Core.Insert(TUI);
      end;
   end;
end;

{ ***** }
function DrawMissionSelect:Byte;
{
}
var X,Y,YSize,I,J:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
    Ret:String;
begin
   CursorOff;
   SetColor(160);
   YSize:=0;
   if (MaxUsedGlobalInfo <> 255) then YSize:=(YFontSize+1)*(MaxUsedGlobalInfo+1);
   YSize:=YSize + 70;
   if (MaxUsedMission1Info <> 255) then YSize:=YSize+YFontSize*(MaxUsedMission1Info+1);
   YSize:=YSize + 70;
   if (MaxUsedMission2Info <> 255) then YSize:=YSize+YFontSize*(MaxUsedMission2Info+1);
   YSize:=YSize + 35;

   Y:=(YResolution-YSize) shr 1+16;
   X:=(XResolution-XFontSize*77) shr 1;
   if (MaxUsedGlobalInfo <> 255) then begin
     for I:=0 to MaxUsedGlobalInfo do begin
       OutTextColor(X+1,Y+1,DarkBlue,GlobalInfoStr[I]);
       OutTextColor(X,Y,Blue,GlobalInfoStr[I]);
       Inc(Y,YFontSize+1);
     end;
   end;
   Inc(Y,26); SetColor(Yellow);
   if (MaxUsedMission2Info <> 255) then begin
     X:=(XResolution-XFontSize*7) shr 1;
     OutTextColor(X,Y,YELLOW,'MISE A)');
     NLine(X,Y+YFontSize+1,X+XFontSize*7,Y+YFontSize+1);
   end else begin
     Str(MissionNum,Ret); Ret:='MISE '+Ret;
     X:=(XResolution-XFontSize*(Length(Ret))) shr 1;
     OutTextColor(X,Y,YELLOW,Ret);
     NLine(X,Y+YFontSize+1,X+XFontSize*(Length(Ret)),Y+YFontSize+1);
   end;
   Inc(Y,26);
   for I:=0 to MaxUsedMission1Info do begin
     X:=(XResolution-XFontSize*Length(Mission1InfoStr[I])) shr 1;
     OutTextColor(X+1,Y+1,DarkBlue,Mission1InfoStr[I]);
     OutTextColor(X,Y,White,Mission1InfoStr[I]);
     Inc(Y,YFontSize);
   end;

   SetColor(Yellow);
   if (MaxUsedMission2Info <> 255) then begin
     Inc(Y,26); X:=(XResolution-XFontSize*7) shr 1;
     OutTextColor(X,Y,YELLOW,'MISE B)'); NLine(X,Y+YFontSize+1,X+XFontSize*7,Y+YFontSize+1);
     Inc(Y,26);
     for I:=0 to MaxUsedMission2Info do begin
       X:=(XResolution-XFontSize*Length(Mission2InfoStr[I])) shr 1;
       OutTextColor(X+1,Y+1,DarkBlue,Mission2InfoStr[I]);
       OutTextColor(X,Y,White,Mission2InfoStr[I]);
       Inc(Y,YFontSize);
     end;
   end;

   Y:=YResolution-BigButtonYSize shl 1;
   if (MaxUsedMission2Info <> 255) then X:=(XResolution-2*BigButtonXSize) div 3
   else X:=(XResolution-BigButtonXSize) shr 1;

   { VYTVORENI TLACITEK }
   CreateButton(X,Y,0,0,False,_Temp1);
   if (MaxUsedMission2Info <> 255) then ButtonText(_Temp1,TextColor,'MISE A)')
   else ButtonText(_Temp1,TextColor,'MISE');
   CreateButton(X+X+BigButtonXSize,Y,0,0,False,_Temp2);
   ButtonText(_Temp2,TextColor,'MISE B)');
   Release(_Temp1); SetActive(_Temp1);
   if (MaxUsedMission2Info <> 255) then begin
     Release(_Temp2); SetActive(_Temp2);
   end;
   CursorOn;

   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         _Temp1     : begin { mise a) }
                        SoundPlay(0,0,0,0);
                        DrawMissionSelect:=1;
                        Konec:=True;
                      end;
         _Temp2     : begin { mise b) }
                        SoundPlay(0,0,0,0);
                        DrawMissionSelect:=2;
                        Konec:=True;
                      end;
      end;
   end;
   CursorOff; DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   ClearScreen;
   LoadRGB(0,PathStrGlobal+'data\paleta1.rgb');
   Blue:=98; DarkBlue:=108; Yellow:=160; DarkYellow:=165; White:=66;
   InvalidateCache;
   OpenImage(PathStrGlobal+'data\buttons.glb',NoCreateNew);
   LoadImageGBM(On1Seg,On1Offs,'on1',0);
   LoadImageGBM(Off1Seg,Off1Offs,'off1',0);
   {X}
   OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
   LoadImageGBM(CursorSegment,CursorOffsets,'normal',0);
   {X}
   CursorOn;
end;

{ ***** }
procedure BuildInfoRecord;
{  sestavi "info zaznam pro pouziti informaci"
}
var I,J:Word;
begin
   for I:=1 to MaxTypesOfUnits do UnitsInfoRecord.Rec[I]:=0;
   for I:=1 to MaxTypesOfBuildings do BuildingsInfoRecord.Rec[I]:=0;
   UnitsInfoRecord.MaxIndex:=0; BuildingsInfoRecord.MaxIndex:=0;

   for I:=1 to MaxTypesOfUnits do begin
      if (((MyUnitsForMission[I] or ReserchAssign[I,1].ForPlayer) and
           (ReserchAssign[I,1].UnitAvail <> 0) or OtherUnitsForMission[I]) and
          (Unit_types^[I,1].TargetTyp = 0))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if (((MyUnitsForMission[I] or ReserchAssign[I,1].ForPlayer) and
           (ReserchAssign[I,1].UnitAvail <> 0) or OtherUnitsForMission[I]) and
          (Unit_types^[I,1].TargetTyp = 1))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if (((MyUnitsForMission[I] or ReserchAssign[I,1].ForPlayer) and
           (ReserchAssign[I,1].UnitAvail <> 0) or OtherUnitsForMission[I]) and
          (Unit_types^[I,1].TargetTyp = 2) and (Unit_types^[I,1].UnitLevel <> 255))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if (((MyUnitsForMission[I] or ReserchAssign[I,1].ForPlayer) and
           (ReserchAssign[I,1].UnitAvail <> 0) or OtherUnitsForMission[I]) and
          (Unit_types^[I,1].TargetTyp = 2) and (Unit_types^[I,1].UnitLevel = 255) and
          (I <> 41))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if (((MyUnitsForMission[I] or ReserchAssign[I,1].ForPlayer) and
           (ReserchAssign[I,1].UnitAvail <> 0) or OtherUnitsForMission[I]) and
          (Unit_types^[I,1].TargetTyp = 3) and (I <> 41))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if (((MyUnitsForMission[I] or ReserchAssign[I,1].ForPlayer) and
           (ReserchAssign[I,1].UnitAvail <> 0) or OtherUnitsForMission[I]) and
          (Unit_types^[I,1].TargetTyp = 4))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;

   {XXXXXXXXX  BUDOVY XXXXXXXXXX}
   for I:=1 to MaxTypesOfBuildings do begin
      if ((BuildingsForMission[I]) and ((I <= 15) or (I = 21)))
      then begin
        BuildingsInfoRecord.Rec[BuildingsInfoRecord.MaxIndex+1]:=I;
        Inc(BuildingsInfoRecord.MaxIndex);
      end;
   end;
end;

{ ***** }
procedure SetEnemyResearch;
{
}
begin
 { MUTANT LEPSI AUTOMATICKY }
  with GlobalModify.UnitTypes[29,0] do begin
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+25));
    ShootSpeed1:=ShootSpeed1+1; ShootSpeed2:=ShootSpeed2+1;
  end;
  { vylepseny aligator }
  if (Game > 9) and (not (Game in [50,51,52])) then with GlobalModify.UnitTypes[11,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+20));
    PL:=Round(((1.0*PL)/100)*(100+33));
    EE:=Round(((1.0*EE)/100)*(100+10));
    EX:=Round(((1.0*EX)/100)*(100+100)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+15));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+33));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+33));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+25));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+25));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +25));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +25));
    Sight:=Sight+1;
  end;
  { vylepsena pechota }
  if (Game > 12) and (not (Game in [50,51,52])) then begin
     with GlobalModify.UnitTypes[7,0] do begin
     {xxx}
       BP:=Round(((1.0*BP)/100)*(100+50)); PL:=Round(((1.0*PL)/100)*(100+66));
       EE:=Round(((1.0*EE)/100)*(100+20)); EX:=Round(((1.0*EX)/100)*(100+0)); {}
       DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+15));
       LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+25));
       LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+26));
       HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+25));
       HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+28));
       AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +80));
       AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +140));
       ShootRange1:=4 shl 8+2; ShootRange2:=1 shl 8+1;
       Sight:=Sight+1;
     end;
     with GlobalModify.UnitTypes[5,0] do begin
     {xxx}
       BP:=Round(((1.0*BP)/100)*(100+60)); PL:=Round(((1.0*PL)/100)*(100+66));
       EE:=Round(((1.0*EE)/100)*(100+50)); EX:=Round(((1.0*EX)/100)*(100+0)); {}
       DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+12));
       LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+22));
       LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+0));
       HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+22));
       HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+0));
       AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +0));
       AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +0));
       ShootRange1:=3 shl 8+1; ShootRange2:=0;
       Sight:=Sight+1;
     end;
     with GlobalModify.UnitTypes[6,0] do begin
     {xxx}
       BP:=Round(((1.0*BP)/100)*(100+60)); PL:=Round(((1.0*PL)/100)*(100+66));
       EE:=Round(((1.0*EE)/100)*(100+50)); EX:=Round(((1.0*EX)/100)*(100+0)); {}
       DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+12));
       LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+22));
       LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+0));
       HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+22));
       HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+0));
       AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +50));
       AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +0));
       ShootRange1:=4 shl 8+1; ShootRange2:=0;
       Sight:=Sight+1;
     end;
  end;
  { vylepseny robot }
  if (Game > 23) and (not (Game in [50,51,52])) then with GlobalModify.UnitTypes[22,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+33));
    PL:=Round(((1.0*PL)/100)*(100+60));
    EE:=Round(((1.0*EE)/100)*(100+30));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+10));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+30));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+30));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+20));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+20));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +0));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +0));
    ShootRange1:=3 shl 8+1;
    ShootRange2:=0;
    {Sight:=Sight+Round(_s);}
  end;
  { vylepseny skorpion }
  if (Game > 23) and (not (Game in [50,51,52])) then with GlobalModify.UnitTypes[10,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+25));
    PL:=Round(((1.0*PL)/100)*(100+40));
    EE:=Round(((1.0*EE)/100)*(100+8));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+10));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+20));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+5));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+30));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+10));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +25));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +50));
{   ShootRange1:=3 shl 8+1;
    ShootRange2:=0;{}
    Sight:=Sight+1;
  end;
  { vylepseny MLRS }
  if (Game > 28) and (not (Game in [50,51,52,60])) then with GlobalModify.UnitTypes[28,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+20));
    PL:=Round(((1.0*PL)/100)*(100-10));
    EE:=Round(((1.0*EE)/100)*(100+25));
    EX:=Round(((1.0*EX)/100)*(100+30)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100-8));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100-5));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100-5));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100-10));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100-10));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +0));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +0));
    ShootSpeed1:=ShootSpeed1+1;
    ShootRange1:=9 shl 8+2;
    ShootRange2:=0;
    Sight:=7;{}
  end;
  { vylepseny STIHAC LIDI }
  if (Game > 29) and (not (Game in [50,51,52,60])) then with GlobalModify.UnitTypes[18,1] do begin
  {xxx}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+10));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+10));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+10));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+10));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+10));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +10));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +10));
    Sight:=Sight+1;{}
  end;
  { vylepseny TERMINATOR LIDI }
  if (Game > 29) and (not (Game in [50,51,52,60])) then with GlobalModify.UnitTypes[19,1] do begin
  {xxx}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+10));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+10));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+10));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+10));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+10));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +10));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +10));
    Sight:=Sight+1;{}
  end;
  { vylepseny STIHAC }
  if ((Game >= 33) or (Game = 30)) and (not (Game in [50,51,52,60,61,62,63,64])) then with GlobalModify.UnitTypes[18,0]
  do begin
  {xxx}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+10));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+10));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+10));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+10));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+10));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +10));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +10));
    Sight:=Sight+1;{}
  end;
  { vylepseny TERMINATOR }
  if ((Game >= 33) or (Game = 30)) and (not (Game in [50,51,52,60,61,62,63,64])) then with GlobalModify.UnitTypes[19,0]
  do begin
  {xxx}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+10));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+10));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+10));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+10));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+10));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +10));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +10));
    Sight:=Sight+1;{}
  end;
  { vylepseny tezky tank }
  if ((Game = 30) or (Game > 31) and (not (Game in [50,51,52,60,61,62,63,64])))
  then with GlobalModify.UnitTypes[16,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+40));
    PL:=Round(((1.0*PL)/100)*(100+30));
    EE:=Round(((1.0*EE)/100)*(100+10));
    EX:=Round(((1.0*EX)/100)*(100+100)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100-5));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100-10));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100-10));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100-15));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +0));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +0));
    ShootSpeed1:=ShootSpeed1+2;
    {ShootRange1:=9 shl 8+2;
    ShootRange2:=0;
    {Sight:=Sight+1;{}
  end;
  { vylepsena lehka pevnost }
  if (Game > 28) and (not (Game in [50,51,52,60])) then with GlobalModify.UnitTypes[20,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+15));
    PL:=Round(((1.0*PL)/100)*(100+0));
    EE:=Round(((1.0*EE)/100)*(100+0));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+2));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+16));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+16));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+20));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+20));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +15));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +15));
  end;
  { vylepsena tezka pevnost }
  if (Game > 28) and (not (Game in [50,51,52,60])) then with GlobalModify.UnitTypes[21,0] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+15));
    PL:=Round(((1.0*PL)/100)*(100+0));
    EE:=Round(((1.0*EE)/100)*(100+0));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
    DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+0));
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+20));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+20));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+17));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+17));
    AirAttack1:=Round(((1.0*AirAttack1)/100)*(100    +15));
    AirAttack2:=Round(((1.0*AirAttack2)/100)*(100    +15));
  end;
  { zdrazena lehka pevnost }
  with GlobalModify.UnitTypes[20,1] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+12));
    PL:=Round(((1.0*PL)/100)*(100+0));
    EE:=Round(((1.0*EE)/100)*(100+0));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
  end;
  { zdrazena tezka pevnost }
  with GlobalModify.UnitTypes[21,1] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+12));
    PL:=Round(((1.0*PL)/100)*(100+0));
    EE:=Round(((1.0*EE)/100)*(100+0));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
  end;
  { zdrazeny SAM }
  with GlobalModify.UnitTypes[32,1] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100+0));
    PL:=Round(((1.0*PL)/100)*(100+95));
    EE:=Round(((1.0*EE)/100)*(100+30));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
  end;
  { zdrazena raketova vez }
  with GlobalModify.UnitTypes[31,1] do begin
  {xxx}
    BP:=Round(((1.0*BP)/100)*(100));
    PL:=Round(((1.0*PL)/100)*(100+95));
    EE:=Round(((1.0*EE)/100)*(100+30));
    EX:=Round(((1.0*EX)/100)*(100+0)); {}
  end;
  { vylepseny autodetonator }
  with GlobalModify.UnitTypes[23,0] do begin
  {xxx}
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+90));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+90));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+50));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+50));
  end;
  with GlobalModify.UnitTypes[23,1] do begin
  {xxx}
    LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+90));
    LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+90));
    HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+50));
    HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+50));
  end;
end;

{ ***** }
procedure SetActionLevel(ActionLev:Byte);
{ Nastavi uroven akcnosti hry:
  2 .. akcne strategicka
  3 .. strategicka pomala
  4 .. strategicka

  Celkem se pouzivaji 3 modifikatory hodnot, branych  z units.dbg:
  DefendChangeValue (Single) - nasobi obrannou silu jednotek
                               (standardne roven 6)
  AttackChangeValue (Single) - nasobi utocnou silu jednotek
  KadenceChangeValue (Single) - nasobi kadenci; je treba, aby se tato
                                hodnota byla nasobkem nejmene 0.2, aby
                                se to na kadenci trochu projevilo
  CostChangeValue (Single) - nasobi cenu objektu
  ProdSpeedChangeValue (Single) - nasobi rychlost vyroby objektu

!  pozn. ZMENY CEN SE NETYKAJI ELEKTRICKE ENERGIE  !
}
var I:Word;
    KAMIKADZEACHANGE:Single;
    DefendChangeValue, AttackChangeValue, KadenceChangeValue,
    CostChangeValue, UnitProdSpeedChangeValue,BuildProdSpeedChangeValue : Single;
begin
   case (ActionLev) of
      2 : begin { akcne strategicka }
             DefendChangeValue:=8.0; { klasicka hodnota }
             AttackChangeValue:=1.45;
             KadenceChangeValue:=1.8;
             CostChangeValue:=0.85;
             UnitProdSpeedChangeValue:=0.85;
             BuildProdSpeedChangeValue:=1.0;
          end;
      3 : begin { strategicka pomala }
             DefendChangeValue:=9.5;
             AttackChangeValue:=1.2;
             KadenceChangeValue:=2.0;
             CostChangeValue:=1.1;
             UnitProdSpeedChangeValue:=1.0;
             BuildProdSpeedChangeValue:=1.0;
          end;
      4 : begin { strategicka }
             DefendChangeValue:=8.2;
             AttackChangeValue:=1.25;
             KadenceChangeValue:=1.85;
             CostChangeValue:=1;
             UnitProdSpeedChangeValue:=1;
             BuildProdSpeedChangeValue:=1;
          end;
   else
       DefendChangeValue:=8.2;
       AttackChangeValue:=1.25;
       KadenceChangeValue:=1.84;
       CostChangeValue:=1;
       UnitProdSpeedChangeValue:=1;
       BuildProdSpeedChangeValue:=1;
   end;

   for I:=0 to 10 do
     Kadence[I]:=Round(KadenceChangeValue*Kadence[I]);
   {x}
   for I:=1 to MaxTypesOfUnits do with (GlobalModify.UnitTypes[I,0]) do begin
     if (I = 23) then KAMIKADZEACHANGE:=DefendChangeValue/6.5
     else KAMIKADZEACHANGE:=1;
     Production_time:=UnitProdSpeedChangeValue*Production_time;
     BP:=Round(CostChangeValue*BP); PL:=Round(CostChangeValue*PL);
     {EE:=Round(CostChangeValue*EE);{} EX:=Round(CostChangeValue*EX);
     LightAttack1:=Round(AttackChangeValue*LightAttack1*KAMIKADZEACHANGE);
     HeavyAttack1:=Round(AttackChangeValue*HeavyAttack1*KAMIKADZEACHANGE);
     AirAttack1:=Round(AttackChangeValue*AirAttack1*KAMIKADZEACHANGE);
     LightAttack2:=Round(AttackChangeValue*LightAttack2*KAMIKADZEACHANGE);
     HeavyAttack2:=Round(AttackChangeValue*HeavyAttack2*KAMIKADZEACHANGE);
     AirAttack2:=Round(AttackChangeValue*AirAttack2*KAMIKADZEACHANGE);
     DefenceStrength:=Round(DefendChangeValue*DefenceStrength*KAMIKADZEACHANGE);
{     case (TerrainCondition) of
        Clear: ;
        Snow : if (TargetTyp = 0) then DefenceStrength:=DefenceStrength+Round(0.1*DefenceStrength);
        Sand : if (TargetTyp = 0) then begin
                   LightAttack1:=LightAttack1-Round(0.15*LightAttack1);
                   HeavyAttack1:=HeavyAttack1-Round(0.15*HeavyAttack1);
                   AirAttack1:=AirAttack1-Round(0.15*AirAttack1);
                   LightAttack2:=LightAttack2-Round(0.15*LightAttack2);
                   HeavyAttack2:=HeavyAttack2-Round(0.15*HeavyAttack2);
                   AirAttack2:=AirAttack2-Round(0.15*AirAttack2);
               end;
        Night: if ((I < 22) or (I > 32) and (I <> 36) and (I <> 39)) then begin
                  if (_Sight > 2) then Dec(_Sight,2)
                  else
                    if (_Sight = 2) then Dec(_Sight);
               end;
        Rain : ;
     end;{}
   end;
   {x}
   for I:=1 to MaxTypesOfUnits do with (GlobalModify.UnitTypes[I,1]) do begin
     if (I = 23) then KAMIKADZEACHANGE:=DefendChangeValue/6.5
     else KAMIKADZEACHANGE:=1;
     Production_time:=UnitProdSpeedChangeValue*Production_time;
     BP:=Round(CostChangeValue*BP); PL:=Round(CostChangeValue*PL);
     {EE:=Round(CostChangeValue*EE);{} EX:=Round(CostChangeValue*EX);
     LightAttack1:=Round(AttackChangeValue*LightAttack1*KAMIKADZEACHANGE);
     HeavyAttack1:=Round(AttackChangeValue*HeavyAttack1*KAMIKADZEACHANGE);
     AirAttack1:=Round(AttackChangeValue*AirAttack1*KAMIKADZEACHANGE);
     LightAttack2:=Round(AttackChangeValue*LightAttack2*KAMIKADZEACHANGE);
     HeavyAttack2:=Round(AttackChangeValue*HeavyAttack2*KAMIKADZEACHANGE);
     AirAttack2:=Round(AttackChangeValue*AirAttack2*KAMIKADZEACHANGE);
     DefenceStrength:=Round(DefendChangeValue*DefenceStrength*KAMIKADZEACHANGE);
{     case (TerrainCondition) of
        Clear: ;
        Snow : if (TargetTyp = 0) then DefenceStrength:=DefenceStrength+Round(0.1*DefenceStrength);
        Sand : if (TargetTyp = 0) then begin
                   LightAttack1:=LightAttack1-Round(0.15*LightAttack1);
                   HeavyAttack1:=HeavyAttack1-Round(0.15*HeavyAttack1);
                   AirAttack1:=AirAttack1-Round(0.15*AirAttack1);
                   LightAttack2:=LightAttack2-Round(0.15*LightAttack2);
                   HeavyAttack2:=HeavyAttack2-Round(0.15*HeavyAttack2);
                   AirAttack2:=AirAttack2-Round(0.15*AirAttack2);
               end;
        Night: if ((I < 22) or (I > 32) and (I <> 36) and (I <> 39)) then begin
                  if (_Sight > 2) then Dec(_Sight,2)
                  else
                    if (_Sight = 2) then Dec(_Sight);
               end;
        Rain : ;
     end;{}
   end;
end;

{ ***** }
procedure SetGlobalModif;
{
}
var I,J:Word;
    Pom:Integer;
    TUI:TUnitInfo;
    DefenceChange, ResDChange, ResChange, Change:Integer;
begin
   { nastaveni pred ulozenim }
   UnAvailUnits:=[];
   for I:=1 to MaxTypesOfUnits do with (ReserchAssign[I,1]) do begin
     if (ForPlayer and (UnitAvail = 0)) then UnAvailUnits:=UnAvailUnits+[I];
   end;

   BuildInfoRecord;
   GlobalModify.Game:=Game; GlobalModify.PlayerId:=PlayerId;
   GlobalModify.Campaign:=Campaign;

   with (GlobalModify) do begin
      if (ResearchRandomStep > 0) then EnemySpecialUnitsPresent:=True;
      for I:=0 to MaxRace do begin
         if (I in EnemyRaces) then with (RaceMaterialModifiers[I]) do begin
            if (BPModif = MaxInt) then BPModif:=0; BPModif:=BPModif+Round(Week*1.5)+(Week div 5)*3;
            if (PLModif = MaxInt) then PLModif:=0; PLModif:=PLModif+Round(Week*1.5)+(Week div 5)*3;
            if (EEModif = MaxInt) then EEModif:=0; EEModif:=EEModif+Round(Week*1.5)+(Week div 5)*3;
            if (ExpModif = MaxInt) then ExpModif:=0; ExpModif:=ExpModif+Round(Week*2)+(Week div 5)*4;
         end;
      end;

      UnitTypes:=Unit_types^;{}
      { nyni modifikujeme vlastni jednotky }
      for J:=1 to 1 do
        for I:=1 to MaxTypesOfUnits do with UnitTypes[I,J] do
        with (ReserchAssign[I,J]) do
        if ((UnitAvail > 0) and  ForPlayer)
        then begin { _u je uz rozpocitano do slozek }
           BP:=Round(((1.0*BP)/100)*(100+_BP)); PL:=Round(((1.0*PL)/100)*(100+_PL));
           EE:=Round(((1.0*EE)/100)*(100+_EE)); EX:=Round(((1.0*EX)/100)*(100+_EX));
           DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+_o));
           LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+_lu));
           LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+_lu));
           HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+_tu));
           HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+_tu));
           AirAttack1:=Round(((1.0*AirAttack1)/100)*(100+_au));
           AirAttack2:=Round(((1.0*AirAttack2)/100)*(100+_au));
           Sight:=Sight+Round(_s);
           Pom:=Round(_d);
           if (Pom >= 0) then ShootRange1:=ShootRange1+Pom shl 8
           else ShootRange1:=ShootRange1-abs(Pom) shl 8;
           if ((_k+ShootSpeed1) <= 9) then ShootSpeed1:=ShootSpeed1+Round(_k);
           if ((_k+ShootSpeed2) <= 9) then ShootSpeed2:=ShootSpeed2+Round(_k);
           if ((SpeedLevel > 0) or (_r >= 0)) then
             if ((SpeedLevel+_r) <= 6) then begin
               SpeedLevel:=SpeedLevel+Round(_r);
               MovementAdding:=Speed[SpeedLevel];
             end;
           if ((Special1 = 11) or (Special2 = 11)) then GuidedMissile:=True;
           if ((Special1 = 31) or (Special2 = 31)) then Autorepair:=5;
           if ((Special1 = 32) or (Special1 = 32)) then Autorepair:=10;
           if ((Special1 = 20) or (Special1 = 20)) then Autorepair:=15;
        end;

      case (_GameLevel) of
        0 : begin DefenceChange:=-20; Change:=-20; end; { detska obtiznost }
        1 : begin DefenceChange:=-10; Change:=-10; end;
        2 : begin DefenceChange:=-10; Change:=0;   end;
        3 : begin DefenceChange:=0;   Change:=0;   end;
        4 : begin DefenceChange:=10;  Change:=10;  end;
      end;
      { nyni modifikujeme nepratelske jednotky }
      for J:=0 to 0 do
        for I:=1 to MaxTypesOfUnits do with UnitTypes[I,J] do begin
        {xxx}
           ResDChange:=0; ResChange:=0;
           if (I in [22..32,36,39]) then begin { roboti only }
             if ((Game > 29) and (not (Game in [50,51,52,60]))) then begin
               ResDChange:=11; ResChange:=5; Sight:=Sight+1;
             end else
                if ((Game > 23) and (not (Game in [50,51,52]))) then begin
                  ResDChange:=10; ResChange:=5;
                end;
           end;
           BP:=Round(((1.0*BP)/100)*(100+ResDChange));
           PL:=Round(((1.0*PL)/100)*(100+ResDChange));
           EE:=Round(((1.0*EE)/100)*(100+ResDChange));
           EX:=Round(((1.0*EX)/100)*(100+ResDChange)); {}
           DefenceStrength:=Round(((1.0*DefenceStrength)/100)*(100+DefenceChange+ResDChange));
           LightAttack1:=Round(((1.0*LightAttack1)/100)*(100+Change+ResChange));
           LightAttack2:=Round(((1.0*LightAttack2)/100)*(100+Change+ResChange));
           HeavyAttack1:=Round(((1.0*HeavyAttack1)/100)*(100+Change+ResChange));
           HeavyAttack2:=Round(((1.0*HeavyAttack2)/100)*(100+Change+ResChange));
           AirAttack1:=Round(((1.0*AirAttack1)/100)*(100+Change+ResChange));
           AirAttack2:=Round(((1.0*AirAttack2)/100)*(100+Change+ResChange));
           Sight:=Sight;
        end;
      SetEnemyResearch; { realizuje nepratelsky vyzkum na zaklade mise }
   end;
end;

{ ***** }
procedure SaveGlobalModif;
{ ulozi zmeny parametru pro danou misi
}
var I,J:Word;
    TUI:TUnitInfo;
    DefenceChange, ResDChange, ResChange, Change:Integer;
begin
   SetGlobalModif;
   GlobalModify.MyUnitsForMission:=MyUnitsForMission;
   with (GlobalModify) do begin
      { ************** ulozeni zaznamu o posilach ************** }
      for I:=0 to MaxCoreUnits-1 do begin
        if (CoreStruct[I].Activity and CoreStruct[I].Selected)
        then begin
           if (Core.GetUnique(CoreStruct[I].UniqueNumber,TUI))
           then CoreInfo[I]:=TUI;
        end;
      end;
   end;

{ ***************************** UKLADANI ******************************** }
   Assign(CfgFile,PathStr+'save\'+PlayerId+'\game.set');
   {PathStr+'save\'+SavePath+'\}
   Rewrite(CfgFile,1);
   DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri ukladani souboru game.set'); end;
{x}BlockWrite(CfgFile,GlobalModify,SizeOf(GlobalModify)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri ukladani souboru game.set'); end;
{x}BlockWrite(CfgFile,UnitsInfoRecord,SizeOf(UnitsInfoRecord)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri ukladani souboru game.set'); end;
{x}BlockWrite(CfgFile,BuildingsInfoRecord,SizeOf(BuildingsInfoRecord)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri ukladani souboru game.set'); end;
{x}BlockWrite(CfgFile,UnAvailUnits,SizeOf(UnAvailUnits)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri ukladani souboru game.set'); end;
{x}BlockWrite(CfgFile,GameUniqueNum,SizeOf(GameUniqueNum)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri ukladani souboru game.set'); end;

   Close(CfgFile); DResult:=IOResult;
end;

{ *********************************************************************** }
begin
   RenamePressed:=False;
   {Assign(CfgFile,PathStr+'game.set');
   Erase(CfgFile);{}
   DResult:=IOResult;
end.
