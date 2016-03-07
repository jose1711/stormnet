unit Grafika4;
{$C FIXED PRELOAD PERMANENT}
interface
uses Graph257, Mouse, Data, Crt, Grafika2, Buttons, SBSound, Smix;

procedure DrawResult;
procedure SaveScreen;
procedure ShowInfoPanel(X,Y,X2,Y2:Word);
procedure CloseInfoPanel;
procedure OpenMapTxtFile(Way:String);
function ReadTxtString(var Ret:String):Boolean;
procedure ReadTxtWord(var Num:Word);
procedure PrintMissionGoal(Way:String);
function DialogBox(Msg:String; DlgType:Byte):Byte;
function WideDialogBox(Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
procedure Print_material(Order:Byte; Value:Integer);
procedure PrintRealTime;
procedure CreateMenuZvuky;
procedure CreateMenuZvukHudba;
procedure CreateMenuExit;
procedure LoadDialog;
procedure CreateMenuUstup;
procedure CreateMenuAutosave;
procedure CreateMenuRychlostHry;
procedure CreateMenuRealTimeScroll;
procedure FinishGame;
procedure Grafika4_save;
procedure Grafika4_load;

var DrawScreen:Boolean; { prio Grafiku2 }

implementation

uses Grafika;

const Ws : set of Byte = [$0d,$0a];
      XGetStringSize = 300; YGetStringSize = YFontSize*5;
var XInfoPanel,YInfoPanel:Word;
    Character:Char;
    MapTxtFile:File;
    MapTxtFileWay:String;

{ ***** }
procedure SaveMissionResult(MyLostB, MyLostU, MyKilledB, MyKilledU:LongInt);
{ ulozi vysledek mise na disk
}
var IOFile:File;
    Temp1,Temp2,I, J, Limit:Word;
    Time:LOngInt;
begin
   Time:=Min_game_time*60+Sec_game_time;
   if (TimeOverflow) then Time:=3600;
   Assign(IOFile,'global\result'); Rewrite(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,PlayerId,SizeOf(PlayerId));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,Game,SizeOf(Game));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,Campaign,SizeOf(Campaign));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,Victory,SizeOf(Victory));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,POINTS,SizeOf(POINTS));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,VICTORYPOINTS,SizeOf(VICTORYPOINTS));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
   for I:=0 to MaxCoreUnits-1 do with (CoreInfo[I]) do begin
     if (not Destroyed) then begin
        J:=MyRace*MaxRaceUnits+1; Limit:=J+MaxRaceUnits;
        while ((J < Limit) and ((Units[J] = Nil) or (Units[J]^.UniqueNumber <> UniqueNumber)))
        do Inc(J);
        {XXX}
        if ((J < Limit) and (Units[J]^.UniqueNumber = UniqueNumber)) then begin
           Active:=True;
           Level:=Units[J]^.ExperienceLevel;
           Experience:=Units[J]^.Experience;
           Kills:=Units[J]^.Kills;
        end;
     end;
   end;

{x}BlockWrite(IOFile,CoreInfo,SizeOf(CoreInfo));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,GameUniqueNumber,SizeOf(GameUniqueNumber));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');

{x}BlockWrite(IOFile,MyLostB,SizeOf(MyLostB));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,MyLostU,SizeOf(MyLostU));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,MyKilledB,SizeOf(MyKilledB));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,MyKilledU,SizeOf(MyKilledU));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,Races[MyRace].Score,SizeOf(Races[MyRace].Score));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,Time,SizeOf(Time));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');

   Temp1:=0; Temp2:=0;
   if ((Game = 54) and Zrada) then Temp1:=1;
{x}BlockWrite(IOFile,Temp1,SizeOf(Temp1));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');
{x}BlockWrite(IOFile,Temp2,SizeOf(Temp2));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "result"');

   Close(IOFile); DResult:=IOResult;
end;

{ ***** }
function GetString(MaxChars:Byte; var Ret:String):Boolean;
{ Umozni uzivateli naeditovat retezec Ret
  -MaxChars udava maximalni pocet editovatelnych pismen
  -vraci True pri uspesnosti operace
}
var XPanel,YPanel:Word;
    Scan,Ascii:Byte;
    X,Y,X2,Y2:Word;
    RetPos:Byte;
    XRetPos,YRetPos:Word;
begin
   {!!!!!!!!!}GetString:=True;
   Ret:=''; RetPos:=1;

   X:=(XResolution-XGetStringSize) shr 1; Y:=(YResolution-YGetStringSize shl 1);
   X2:=X+XGetStringSize-1; Y2:=Y+YGetStringSize-1;
   { Draw panel }
   XPanel:=X; YPanel:=Y;
   CursorOff;
   ShowInfoPanel(X,Y,X2,Y2);
   CursorOff;
   XRetPos:=X+(X2-X-XFontSize*MaxChars) shr 1;
   YRetPos:=Y+(Y2-Y-2*YFontSize) shr 1+YFontSize+YFontSize shr 1;
   OutTextColor(X+(X2-X-XFontSize*18) shr 1,Y+YFontSize,64,'ZADEJTE SVc JMcNO:');
   Rectangle2(XRetPos,YRetPos,XRetPos+XFontSize*MaxChars,YRetPos+YFontSize,0);
   CursorOn;

   { end Draw panel }
   repeat
    repeat
      Ascii:=ReadKeys(Scan);
    until (Scan <> 0);
    if (Scan <> $01) then begin
      if (Scan = $0e) then begin
         if (RetPos > 1) then begin
            Dec(RetPos); Ret[0]:=Chr(RetPos-1);
            CursorOff;
            Rectangle2(XRetPos,YRetPos,XRetPos+XFontSize,YRetPos+YFontSize,0);
            CursorOn;
            Dec(XRetPos,XFontSize);
         end;
      end else
         if (RetPos <= 15) then begin
           case (Ascii) of
             32      : begin Ret[RetPos]:=Chr(Ascii); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             065..090: begin Ret[RetPos]:=Chr(Ascii); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             097..122: begin Ret[RetPos]:=Chr(Ascii-32); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             48..57  : begin Ret[RetPos]:=Chr(Ascii); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             33      : begin Ret[RetPos]:='+'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             54      : begin Ret[RetPos]:='.'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             64      : begin Ret[RetPos]:='d'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             35      : begin Ret[RetPos]:='g'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             36      : begin Ret[RetPos]:='b'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             37      : begin Ret[RetPos]:='f'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             94      : begin Ret[RetPos]:='k'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             38      : begin Ret[RetPos]:='j'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             40      : begin Ret[RetPos]:='e'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             41      : begin Ret[RetPos]:='c'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             42      : begin Ret[RetPos]:='a'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             Ord('[') : begin Ret[RetPos]:='h'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             Ord(';') : begin Ret[RetPos]:='i'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
           else
              Continue;
           end;
           Inc(XRetPos,XFontSize);
           CursorOff;
           OutTextColor(XRetPos,YRetPos,66,Ret[RetPos-1]);
           CursorOn;
         end;
    end;
   until ((Scan = $01) or (Scan = $1c));

   if (Scan = $01) then GetString:=False;
   { Erase panel }
   CloseInfoPanel;
   { end Erase panel }
end;


{ ***** }
procedure DrawResult;
{ v ramci procedury se vykresli vysledky boje
}
label Konec;
const XNadpis = 250;
      X1 = 0; { zacatek sloupce rasy (nazev) }
      X2 = 150; { zacatek sloupce budovy (vyrobene) }
      X3 = 220; { zacatek sloupce budovy (znicene) }
      X4 = 290; { zacatek sloupce jednotky (vyrobene) }
      X5 = 360; { zacatek sloupce jednotky (znicene) }
      X6 = 430; { zacatek sloupce jednotky (kills) }
      X7 = 500; { zacatek sloupce budovy (kills) }
      X8 = 570; { zacatek sloupce body }
      XEnd = 640;
      YNadpis = 0;
      Y1 = 70;   { prvni radek popisu }
      Y2 = 100;  { druhy radek popisu }
      Y3 = 130;  { nyni radky pro jednotlive rasy }
      Y4 = 160;
      Y5 = 190;
      Y6 = 220;
      Y7 = 250;
      Y8 = 280;
      YEnd = 310;

      Shadow = 75;
var XAdd, YAdd, X, Y, Count:Word;
    I,J,K:Word;
    ExistB, ProducedB, ExistU, ProducedU, KilledB, KilledU : Word;
    MyLostB, MyLostU, MyKilledB, MyKilledU:LongInt;
    PomRet,Ret:String;
    Butt,  Ascii, S , O : Word;
    Scan:Byte;
    Memory:LongInt;
    MyUnits, EnemyUnits, EnemyMyUnits, R1, R2,R:Single;
    CondOk, CondFail:Word;
    OutFile:File;
    BestScore:Word;
    BestTime,Time:LongInt;
    PlayerName, BestScoreName, BestTimeName:String[20];
    Kanec:Boolean;
    Num,Sc,As:Word;
begin
   Delay(200);
   InDrawResult:=True;
   Button:=0; ButtonClick:=0;
   while (KeyPressed) do ReadKey;
   CursorOff; Mouse.Grouping:=False; SetCursorRange(0,0,XResolution,YResolution);
   ClearScreen;
   XAdd:=(XResolution - XEnd) shr 1;
   YAdd:=(YResolution - YEnd - 100) shr 1;

   if (Victory < 0) then Ret:='prohra'
   else
     if (Victory = 0) then Ret:='remiza'
     else Ret:='vyhra';

   OpenImage('data\hlp',NoCreateNew);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   GetXYIMageCoordinatesGBM(X,Y,Ret);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X)*Y+8;
   GetMemory(Memory,S,O);
   if (S = 0) then Error(0,'nedostatek pameti');
   LoadImageGBM(S,O,Ret,0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   SpeedPutImage2(XNadpis+XAdd,YNadpis+YAdd,S,O);

   { nejprve vodorovne linky }
   SetColor(71);
   NLine(X2+XAdd,Y1+YAdd,XEnd+XAdd,Y1+YAdd);
   NLine(X2+XAdd,Y2+YAdd,XEnd+XAdd,Y2+YAdd);
   NLine(X1+XAdd,Y3+YAdd,XEnd+XAdd,Y3+YAdd);
   NLine(X1+XAdd,Y4+YAdd,XEnd+XAdd,Y4+YAdd);
   NLine(X1+XAdd,Y5+YAdd,XEnd+XAdd,Y5+YAdd);
   NLine(X1+XAdd,Y6+YAdd,XEnd+XAdd,Y6+YAdd);
   NLine(X1+XAdd,Y7+YAdd,XEnd+XAdd,Y7+YAdd);
   NLine(X1+XAdd,Y8+YAdd,XEnd+XAdd,Y8+YAdd);
   NLine(X1+XAdd,YEnd+YAdd,XEnd+XAdd,YEnd+YAdd);
   { nyni svisle linky }
   NLine(X1+XAdd,Y3+YAdd,X1+XAdd,YEnd+YAdd);
   NLine(X2+XAdd,Y1+YAdd,X2+XAdd,YEnd+YAdd);
   NLine(X3+XAdd,Y2+YAdd,X3+XAdd,YEnd+YAdd);
   NLine(X4+XAdd,Y1+YAdd,X4+XAdd,YEnd+YAdd);
   NLine(X5+XAdd,Y2+YAdd,X5+XAdd,YEnd+YAdd);
   NLine(X6+XAdd,Y1+YAdd,X6+XAdd,YEnd+YAdd);
   NLine(X7+XAdd,Y2+YAdd,X7+XAdd,YEnd+YAdd);
   NLine(X8+XAdd,Y2+YAdd,X8+XAdd,YEnd+YAdd);
   NLine(XEnd+XAdd,Y1+YAdd,XEnd+XAdd,YEnd+YAdd);
   { rasa 0 }
   Rectangle(X1+6+XAdd,Y3+6+YAdd,X2-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X2+6+XAdd,Y3+6+YAdd,X3-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X3+6+XAdd,Y3+6+YAdd,X4-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X4+6+XAdd,Y3+6+YAdd,X5-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X5+6+XAdd,Y3+6+YAdd,X6-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X6+6+XAdd,Y3+6+YAdd,X7-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X7+6+XAdd,Y3+6+YAdd,X8-5+XAdd,Y4-5+YAdd,Shadow);
   Rectangle(X8+6+XAdd,Y3+6+YAdd,XEnd-5+XAdd,Y4-5+YAdd,Shadow);
   { rasa 1 }
   Rectangle(X1+6+XAdd,Y4+6+YAdd,X2-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X2+6+XAdd,Y4+6+YAdd,X3-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X3+6+XAdd,Y4+6+YAdd,X4-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X4+6+XAdd,Y4+6+YAdd,X5-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X5+6+XAdd,Y4+6+YAdd,X6-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X6+6+XAdd,Y4+6+YAdd,X7-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X7+6+XAdd,Y4+6+YAdd,X8-5+XAdd,Y5-5+YAdd,Shadow);
   Rectangle(X8+6+XAdd,Y4+6+YAdd,XEnd-5+XAdd,Y5-5+YAdd,Shadow);
   { rasa 2 }
   Rectangle(X1+6+XAdd,Y5+6+YAdd,X2-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X2+6+XAdd,Y5+6+YAdd,X3-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X3+6+XAdd,Y5+6+YAdd,X4-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X4+6+XAdd,Y5+6+YAdd,X5-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X5+6+XAdd,Y5+6+YAdd,X6-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X6+6+XAdd,Y5+6+YAdd,X7-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X7+6+XAdd,Y5+6+YAdd,X8-5+XAdd,Y6-5+YAdd,Shadow);
   Rectangle(X8+6+XAdd,Y5+6+YAdd,XEnd-5+XAdd,Y6-5+YAdd,Shadow);
   { rasa 3 }
   Rectangle(X1+6+XAdd,Y6+6+YAdd,X2-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X2+6+XAdd,Y6+6+YAdd,X3-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X3+6+XAdd,Y6+6+YAdd,X4-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X4+6+XAdd,Y6+6+YAdd,X5-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X5+6+XAdd,Y6+6+YAdd,X6-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X6+6+XAdd,Y6+6+YAdd,X7-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X7+6+XAdd,Y6+6+YAdd,X8-5+XAdd,Y7-5+YAdd,Shadow);
   Rectangle(X8+6+XAdd,Y6+6+YAdd,XEnd-5+XAdd,Y7-5+YAdd,Shadow);
   { rasa 4 }
   Rectangle(X1+6+XAdd,Y7+6+YAdd,X2-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X2+6+XAdd,Y7+6+YAdd,X3-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X3+6+XAdd,Y7+6+YAdd,X4-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X4+6+XAdd,Y7+6+YAdd,X5-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X5+6+XAdd,Y7+6+YAdd,X6-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X6+6+XAdd,Y7+6+YAdd,X7-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X7+6+XAdd,Y7+6+YAdd,X8-5+XAdd,Y8-5+YAdd,Shadow);
   Rectangle(X8+6+XAdd,Y7+6+YAdd,XEnd-5+XAdd,Y8-5+YAdd,Shadow);
   { rasa 5 }
   Rectangle(X1+6+XAdd,Y8+6+YAdd,X2-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X2+6+XAdd,Y8+6+YAdd,X3-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X3+6+XAdd,Y8+6+YAdd,X4-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X4+6+XAdd,Y8+6+YAdd,X5-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X5+6+XAdd,Y8+6+YAdd,X6-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X6+6+XAdd,Y8+6+YAdd,X7-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X7+6+XAdd,Y8+6+YAdd,X8-5+XAdd,YEnd-5+YAdd,Shadow);
   Rectangle(X8+6+XAdd,Y8+6+YAdd,XEnd-5+XAdd,YEnd-5+YAdd,Shadow);

   { nyni text }
   OutText((X4-X2-6*XFontSize) shr 1 + X2+XAdd,
           (Y2-Y1-YFontSize) shr 1 + Y1+YAdd,'BUDOVY');
   OutText((X6-X4-8*XFontSize) shr 1 + X4+XAdd,
           (Y2-Y1-YFontSize) shr 1 + Y1+YAdd,'JEDNOTKY');
   OutText((XEnd-X6-5*XFontSize) shr 1 + X6+XAdd,
           (Y2-Y1-YFontSize) shr 1 + Y1+YAdd,'KILLS');

   OutText((X3-X2-8*XFontSize) shr 1 + X2+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'VYROBENc');
   OutText((X4-X3-8*XFontSize) shr 1 + X3+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'ZTRACENc');
   OutText((X5-X4-8*XFontSize) shr 1 + X4+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'VYROBENc');
   OutText((X6-X5-8*XFontSize) shr 1 + X5+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'ZTRACENc');
   OutText((X7-X6-8*XFontSize) shr 1 + X6+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'JEDNOTKY');
   OutText((X8-X7-6*XFontSize) shr 1 + X7+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'BUDOVY');
   OutText((XEnd-X8-4*XFontSize) shr 1 + X8+XAdd,
           (Y3-Y2-YFontSize) shr 1 + Y2+YAdd,'BODY');

   Count:=1;
   for K:=0 to MaxRace do with (Races[K]) do begin
     ExistB:=0; ProducedB:=0; ExistU:=0; ProducedU:=0; KilledB:=0; KilledU:=0;
     if ((not HelpRace) and (not ChangeOnVisib)) then begin
     { pomocna rasa se do skore nepocita }
       for I:=1 to MaxTypesOfBuildings do begin
           Inc(ExistB,ExistBuildings[I]);
           Inc(ProducedB,ProducedBuildings[I]);
           Inc(KilledB,KilledBuildings[I]);
       end;
       for I:=1 to MaxTypesOfUnits do begin
          Inc(ExistU,ExistUnits[I]);
          Inc(ProducedU,ProducedUnits[I]);
          Inc(KilledU,KilledUnits[I]);
       end;
     end;

     if (K = MyRace) then begin
        MyLostB:=ProducedB-ExistB-BuildingsSold;
        MyLostU:=ProducedU-ExistU-UnpackedBuildings-UnitsSold;
        MyKilledB:=KilledB;
        MyKilledU:=KilledU;
     end;

     if ((ExistB+ProducedB+ExistU+ProducedU+KilledB+KilledU) > 0) then begin
     { platne udaje }
        case (Count) of
          1 : begin
                Y:=(Y4-Y3-YFontSize) shr 1 + Y3 + YAdd;
                if (Races[MyRace].Friend[K] = 2) then
                  Frame(X1+4+XAdd,Y3+4+YAdd,X2-3+XAdd,Y4-3+YAdd,Races[MyRace].RaceColor);
                Rectangle(X1+6+XAdd,Y3+6+YAdd,X2-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X2+6+XAdd,Y3+6+YAdd,X3-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X3+6+XAdd,Y3+6+YAdd,X4-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X4+6+XAdd,Y3+6+YAdd,X5-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X5+6+XAdd,Y3+6+YAdd,X6-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X6+6+XAdd,Y3+6+YAdd,X7-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X7+6+XAdd,Y3+6+YAdd,X8-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
                Rectangle(X8+6+XAdd,Y3+6+YAdd,XEnd-5+XAdd,Y4-5+YAdd,Races[K].RaceColor);
              end;
          2 : begin
                Y:=(Y5-Y4-YFontSize) shr 1 + Y4 + YAdd;
                if (Races[MyRace].Friend[K] = 2) then
                  Frame(X1+4+XAdd,Y4+4+YAdd,X2-3+XAdd,Y5-3+YAdd,Races[MyRace].RaceColor);
                Rectangle(X1+6+XAdd,Y4+6+YAdd,X2-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X2+6+XAdd,Y4+6+YAdd,X3-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X3+6+XAdd,Y4+6+YAdd,X4-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X4+6+XAdd,Y4+6+YAdd,X5-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X5+6+XAdd,Y4+6+YAdd,X6-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X6+6+XAdd,Y4+6+YAdd,X7-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X7+6+XAdd,Y4+6+YAdd,X8-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
                Rectangle(X8+6+XAdd,Y4+6+YAdd,XEnd-5+XAdd,Y5-5+YAdd,Races[K].RaceColor);
              end;
          3 : begin
                Y:=(Y6-Y5-YFontSize) shr 1 + Y5 + YAdd;
                if (Races[MyRace].Friend[K] = 2) then
                  Frame(X1+4+XAdd,Y5+4+YAdd,X2-3+XAdd,Y6-3+YAdd,Races[MyRace].RaceColor);
                Rectangle(X1+6+XAdd,Y5+6+YAdd,X2-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X2+6+XAdd,Y5+6+YAdd,X3-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X3+6+XAdd,Y5+6+YAdd,X4-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X4+6+XAdd,Y5+6+YAdd,X5-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X5+6+XAdd,Y5+6+YAdd,X6-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X6+6+XAdd,Y5+6+YAdd,X7-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X7+6+XAdd,Y5+6+YAdd,X8-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
                Rectangle(X8+6+XAdd,Y5+6+YAdd,XEnd-5+XAdd,Y6-5+YAdd,Races[K].RaceColor);
              end;
          4 : begin
                Y:=(Y7-Y6-YFontSize) shr 1 + Y6 + YAdd;
                if (Races[MyRace].Friend[K] = 2) then
                  Frame(X1+4+XAdd,Y6+4+YAdd,X2-3+XAdd,Y7-3+YAdd,Races[MyRace].RaceColor);
                Rectangle(X1+6+XAdd,Y6+6+YAdd,X2-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X2+6+XAdd,Y6+6+YAdd,X3-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X3+6+XAdd,Y6+6+YAdd,X4-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X4+6+XAdd,Y6+6+YAdd,X5-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X5+6+XAdd,Y6+6+YAdd,X6-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X6+6+XAdd,Y6+6+YAdd,X7-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X7+6+XAdd,Y6+6+YAdd,X8-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
                Rectangle(X8+6+XAdd,Y6+6+YAdd,XEnd-5+XAdd,Y7-5+YAdd,Races[K].RaceColor);
              end;
          5 : begin
                Y:=(Y8-Y7-YFontSize) shr 1 + Y7 + YAdd;
                if (Races[MyRace].Friend[K] = 2) then
                  Frame(X1+4+XAdd,Y7+4+YAdd,X2-3+XAdd,Y8-3+YAdd,Races[MyRace].RaceColor);
                Rectangle(X1+6+XAdd,Y7+6+YAdd,X2-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X2+6+XAdd,Y7+6+YAdd,X3-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X3+6+XAdd,Y7+6+YAdd,X4-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X4+6+XAdd,Y7+6+YAdd,X5-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X5+6+XAdd,Y7+6+YAdd,X6-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X6+6+XAdd,Y7+6+YAdd,X7-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X7+6+XAdd,Y7+6+YAdd,X8-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
                Rectangle(X8+6+XAdd,Y7+6+YAdd,XEnd-5+XAdd,Y8-5+YAdd,Races[K].RaceColor);
              end;
          6 : begin
                Y:=(YEnd-Y8-YFontSize) shr 1 + Y8 + YAdd;
                if (Races[MyRace].Friend[K] = 2) then
                  Frame(X1+4+XAdd,Y8+4+YAdd,X2-3+XAdd,YEnd-3+YAdd,Races[MyRace].RaceColor);
                Rectangle(X1+6+XAdd,Y8+6+YAdd,X2-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X2+6+XAdd,Y8+6+YAdd,X3-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X3+6+XAdd,Y8+6+YAdd,X4-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X4+6+XAdd,Y8+6+YAdd,X5-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X5+6+XAdd,Y8+6+YAdd,X6-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X6+6+XAdd,Y8+6+YAdd,X7-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X7+6+XAdd,Y8+6+YAdd,X8-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
                Rectangle(X8+6+XAdd,Y8+6+YAdd,XEnd-5+XAdd,YEnd-5+YAdd,Races[K].RaceColor);
              end;
        end;
        Inc(Count);
        OutTextColor((X2-X1-Length(RaceName)*XFontSize) shr 1 +X1+XAdd,Y,76,RaceName);
        Str(ProducedB,Ret);
        OutTextColor((X3-X2-Length(Ret)*XFontSize) shr 1 +X2+XAdd,Y,76,Ret);
        if (K <> MyRace) then Str(ProducedB-ExistB,Ret)
        else Str(ProducedB-ExistB-BuildingsSold,Ret);
        OutTextColor((X4-X3-Length(Ret)*XFontSize) shr 1 +X3+XAdd,Y,76,Ret);
        Str(ProducedU-UnpackedBuildings,Ret);
        OutTextColor((X5-X4-Length(Ret)*XFontSize) shr 1 +X4+XAdd,Y,76,Ret);
        if (K <> MyRace) then Str(ProducedU-ExistU-UnpackedBuildings,Ret)
        else Str(ProducedU-ExistU-UnpackedBuildings-UnitsSold,Ret);
        OutTextColor((X6-X5-Length(Ret)*XFontSize) shr 1 +X5+XAdd,Y,76,Ret);
        Str(KilledU,Ret);
        OutTextColor((X7-X6-Length(Ret)*XFontSize) shr 1 +X6+XAdd,Y,76,Ret);
        Str(KilledB,Ret);
        OutTextColor((X8-X7-Length(Ret)*XFontSize) shr 1 +X7+XAdd,Y,76,Ret);
        Str(Score,Ret);
        OutTextColor((XEnd-X8-Length(Ret)*XFontSize) shr 1 +X8+XAdd,Y,76,Ret);
     end;
   end;

   POINTS:=0;
   VICTORYPOINTS:=0;
   {xxx}
   {
   _LostBuildings, _LostUnits : Single;{}

   with (Races[MyRace]) do begin
     POINTS:=POINTS+Round(_InGameProducedUnits/70+_InGameProducedBuildings/25);
     POINTS:=POINTS+Round(_KilledUnits/38+_KilledBuildings/5.5);
   end;

   MyUnits:=0; EnemyUnits:=0;
   for K:=0 to MaxRace do with (Races[K]) do begin
     if ((not Neutral) and (not HelpRace)) then begin
        if (Ally = 1) then begin
           MyUnits:=MyUnits+_ProducedUnitsAll;
        end else begin
           EnemyUnits:=EnemyUnits+_ProducedUnitsAll;
        end;
     end;
   end;
   if (MyUnits > 0) then EnemyMyUnits:=EnemyUnits/MyUnits
   else EnemyMyUnits:=1;
   if (EnemyMyUnits > 1) then begin
     EnemyMyUnits:=1+(EnemyMyUnits-1)/2;
     if (EnemyMyUnits > 2) then EnemyMyUnits:=2;
   end;
   if (EnemyMyUnits < 0.5) then begin
      EnemyMyUnits:=0.5;
   end;
   {x}

   { vypocteme procentualni pomer mezi ztracenymi jednotkami a mnou killnutymi }
   with (Races[MyRace]) do begin
     R2:=_KilledUnits*EnemyMyUnits-_LostUnits;
     R2:=R2/3.6; R2:=R2+Rand(RndUk);
     if (R2 > 2700) then R2:=2700-Rand(RndUk);
     POINTS:=POINTS+Round(R2);

     R2:=_KilledBuildings*EnemyMyUnits-_LostBuildings;
     R2:=R2/1.5; R2:=R2+Rand(RndUk);
     if (R2 > 1900) then R2:=1900-Rand(RndUk);
     POINTS:=POINTS+Round(R2);

     if ((_LostUnits+2*_LostBuildings) = 0)
     then R:=(_KilledUnits*EnemyMyUnits+2*_KilledBuildings*EnemyMyUnits)
     else
      R:=(_KilledUnits*EnemyMyUnits+2*_KilledBuildings*EnemyMyUnits)/
         (_LostUnits+2*_LostBuildings);

     {x} CondOk:=0; CondFail:=0; R1:=0;
     if (CondUk = -1) then begin
        if (Victory > 0) then begin R1:=500; CondOk:=1; end;
     end else begin
        for I:=0 to CondUk do with (VictoryConditions^[I]) do begin
          if (Result = 1) then Inc(CondOk,2);
          if (Result = 0) then Inc(CondOk);
          if (Result = -1) then Inc(CondFail);
          R1:=300/(CondUk+1); { pocet bodu na 1/2 podminky }
        end;
     end;
     POINTS:=POINTS+Round(R1*CondOk)-Round(R1*CondFail){};
     {x}

     if (Victory > 0) then begin
       POINTS:=POINTS+4000;
       if (POINTS > 10000) then begin
         POINTS:=10000-Rand(RndUk) shr 1;
         if (R >= 8) then VICTORYPOINTS:=4
         else
           if (R >= 5) then VICTORYPOINTS:=3
           else
             if (R >= 1.8) then VICTORYPOINTS:=2
             else VICTORYPOINTS:=1;
       end;
       if (_KilledUnits < 50) then VICTORYPOINTS:=2;
     end else
       if (Victory = 0) then begin
         if (POINTS > 6000) then POINTS:=6000-Rand(RndUk) shl 1;
         if (R >= 3) then VICTORYPOINTS:=1
         else
           if (R >= 5) then VICTORYPOINTS:=2;
       end else begin
         if (POINTS > 5000) then POINTS:=5000-Rand(RndUk) shl 1;
         if (R >= 3.5) then VICTORYPOINTS:=1
         else
           if (R >= 6.5) then VICTORYPOINTS:=2;
       end;
   end;

   if (POINTS < 0) then POINTS:=Rand(RndUk) shr 1;
   if (MissionNumber = 52) then begin
     POINTS:=1000; VICTORYPOINTS:=1;
   end;
   if ((MissionNumber = 33) and (Victory < 1)) then begin
     POINTS:=0; VICTORYPOINTS:=0;
   end;

   {xxx}
   Str(POINTS,Ret);
   OutTextColor(X2+XAdd,YEnd+30+YAdd,162,'ZeSKANjCH KREDITi: '+Ret);
   Str(VICTORYPOINTS,Ret);
   OutTextColor(X5+XAdd,YEnd+30+YAdd,162,'OBDRkENa PRESTIk: '+Ret);

   { hi skore:}
   if (Victory = 1) then Time:=LongInt(Min_game_time)*60+Sec_game_time
   else Time:=65535;
   Assign(OutFile,'missions\score'+MissionNameString);
   Reset(OutFile,1); IO_Result:=IOResult;
   if (IO_Result = 2) then begin
      ReWrite(OutFile,1); IO_Result:=IOResult;
      if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
      BestScore:=0; BestTime:=3600; BestScoreName:='UNKNOWN'; BestTimeName:='UNKNOWN';
   end else
     if (IO_Result = 0) then begin
       BlockRead(OutFile,BestScore,SizeOf(BestScore)); IO_Result:=IOResult;
       if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
       BlockRead(OutFile,BestScoreName,SizeOf(BestScoreName)); IO_Result:=IOResult;
       if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
       BlockRead(OutFile,BestTime,SizeOf(BestTime)); IO_Result:=IOResult;
       if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
       BlockRead(OutFile,BestTimeName,SizeOf(BestTimeName)); IO_Result:=IOResult;
       if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
       Close(OutFile); IO_Result:=IOResult;
       ReWrite(OutFile,1); IO_Result:=IOResult;
      if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;GoTo Konec;end;
     end else GoTo Konec;
   { nacteni bylo OK }
   PlayerName:='UNKNOWN'; CursorOff;
   if (Races[0].Score > BestScore) then begin
      BestScore:=Races[0].Score;
      if (PlayerName='UNKNOWN') then begin
        if (GetString(20,Ret)) then PlayerName:=Ret;
        CursorOff;
      end;
      BestScoreName:=PlayerName;
   end;
   if (Time < BestTime) then begin
      BestTime:=Time;
      CursorOff;
      if (PlayerName='UNKNOWN') then begin
        if (GetString(20,Ret)) then PlayerName:=Ret;
      end;
      CursorOff;
      BestTimeName:=PlayerName;
   end; CursorOff;
   { zapis nejlepsich vysledku: }
   BlockWrite(OutFile,BestScore,SizeOf(BestScore)); IO_Result:=IOResult;
   if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
   BlockWrite(OutFile,BestScoreName,SizeOf(BestScoreName)); IO_Result:=IOResult;
   if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
   BlockWrite(OutFile,BestTime,SizeOf(BestTime)); IO_Result:=IOResult;
   if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
   BlockWrite(OutFile,BestTimeName,SizeOf(BestTimeName)); IO_Result:=IOResult;
   if (IO_Result <> 0) then begin Close(OutFile);IO_Result:=IOResult;Erase(OutFile);IO_Result:=IOResult;GoTo Konec;end;
   Close(OutFile); IO_Result:=IOResult;
   Str(BestScore,Ret);
   OutTextColor(X2+XAdd,YEnd+60+YAdd,66,          'NEJLEPge SKORE:       '+BestScoreName+' '+Ret);
   Str(BestTime div 60,PomRet); Ret:=PomRet+':';
   Str(BestTime mod 60,PomRet); Ret:=Ret+PomRet;
   OutTextColor(X2+XAdd,YEnd+60+YFontSize+YAdd,66,'NEJLEPge VeTdZNj bAS: '+BestTimeName+' '+Ret);

   CreateButton((XResolution-BigButtonXSize) shr 1,
                YResolution-BigButtonYSize-8,1,0,False,_Temp1);
   ButtonText(_Temp1,15,'OK');
   SetActive(_Temp1); Release(_Temp1);

Konec:
   CursorOn;
   Kanec:=False;
   while not (Kanec) do begin
      Num:=MousKeybClick(X,Y,Button,Sc,As);
      case Num of
        0     : if (Sc = $1c) then Kanec:=True;
        _Temp1: Kanec:=True;
      end;
   end;

   DeleteButton(_Temp1,256); SaveMissionResult(MyLostB, MyLostU, MyKilledB, MyKilledU);
end;

{ ***** }
procedure SaveScreen;
{
}
label Konec;
var Ret :String;
    Memory:LongInt;
    I:Word;
    PomFile:File;
begin
  if (ScreenShot) then begin
     I:=0;
     { hledani volneho indexu }
     repeat
         Str(I,Ret);
         Ret:='scrshots/storm'+Ret+'.bmp';
         Inc(I);
         Assign(PomFile,Ret);
         Reset(PomFile,1); IO_Result:=IOResult;
         Close(PomFile);
     until ((IO_Result = 2) or (I > 999));
     IO_Result:=IOResult;
     if (I > 999) then GoTo Konec;

     OpenImage(Ret,CreateNew);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
     GetImage(0,0,XResolution-1,YResolution-1,SScreen,OScreen,ReverseDirect);
     SaveImageBMP(SScreen,OScreen);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
  end;
Konec:
end;

{ ***** }
procedure ShowInfoPanel(X,Y,X2,Y2:Word);
{ procedura zobrazi informacni panel
}
var I,J:Word;
    Color:Byte;
begin
   XInfoPanel:=X; YInfoPanel:=Y;
   CursorOff; ScreenOff;
   GetImage(X,Y,X2,Y2,Win1BckSeg,Win1BckOfs,NormalDirect);
   Frame(X+1,Y+1,X2-1,Y2-1,66);
   Frame(X,Y,X2,Y2,70);
   SpecMenuRectangle(X+2,Y+2,X2-2,Y2-2);
   {for J:=Y+2 to Y2-2 do
    for I:=X+2 to X2-2 do begin
       Color:=GetPixel(I,J);
       Color:=Color mod 16+32+3;
       if (Color >= 48) then Color:=47;
       ColorPixel(I,J,Color);
    end;{}
  ScreenOn; CursorOn;
end;

{ ***** }
procedure CloseInfoPanel;
{ procedura zavre informacni panel
}
begin
   CursorOff;
   PutImage(XInfoPanel,YInfoPanel,Win1BckSeg,Win1BckOfs,NormalDirect);
   CursorOn;
end;


{ ****** }
procedure OpenMapTxtFile(Way:String);
{
}
begin
   MapTxtFileWay:=Way; InvalidateCache;
   IO_Result:=CacheFetch(Way);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
end;

{ ****** }
function ReadTxtString(var Ret:String):Boolean;
{
}
begin
  if (CacheEof(MapTxtFile)) then ReadTxtString:=False
  else begin
     Ret:='';
     while ((Ord(Character) in Ws) and (not CacheEof(MapTxtFile))) do begin
       CacheBlockRead(MapTxtFile,@Character,1);
       if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
     end;

     if (CacheEof(MapTxtFile)) then ReadTxtString:=False
     else begin
       repeat
         Ret:=Ret+Character;
         CacheBlockRead(MapTxtFile,@Character,1);
         if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
       until ((Ord(Character) in Ws) or (CacheEof(MapTxtFile)));
     end;

     if (CacheEof(MapTxtFile)) then ReadTxtString:=False
     else ReadTxtString:=True;
  end;
end;

{ ****** }
procedure ReadTxtWord(var Num:Word);
{
}
begin
   Num:=0;
   while (not ((Character in ['0'..'9']) or (CacheEof(MapTxtFile)))) do begin
     CacheBlockRead(MapTxtFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
   end;

   repeat
     Num:=Num*10+(Ord(Character)-Ord('0'));
     CacheBlockRead(MapTxtFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
   until ((not (Character in ['0'..'9'])) or (CacheEof(MapTxtFile)));
end;

{ ***** }
procedure PrintMissionGoal(Way:String);
{ nahraje konfiguracni data
}
const YSpace = 2; XPlus = 10; YPlus = 40;
var Ret:String;
    I,J:Word;
    XP,YP,X,Y:Word;
    XOdsaz, YOdsaz, YButtonOdsaz:Word;
    Num,Scan,Ascii, Button:Word;
begin
   OpenMapTxtFile(Way);
   ReadTxtString(Ret); { prvni radek je komentar }
   ReadTxtString(Ret); { druhy radek je komentar }
   { nasleduji 2 wordy velikosti}
   ReadTxtWord(X); ReadTxtWord(Y);
   X:=X*XFontSize+XPlus; Y:=(Y+1)*(YFontSize+YSpace)+YPlus;
   XOdsaz:=XPlus shr 1; YOdsaz:=YPlus shr 2;
   { inicializace }
   XP:=XScreenBeg+(XScreenSize-X) shr 1;
   YP:=YScreenBeg+(YScreenSize-Y) shr 1;

   YButtonOdsaz:=10;
   ShowInfoPanel(XP,YP,XP+X-1,YP+Y-1);{}
   CursorOff;{}

   I:=0;
   while ReadTxtString(Ret) do begin
      OutTextColor(XP+XOdsaz,YP+YOdsaz+I*(YFontSize+YSpace),65,Ret);{}
      Inc(I);
   end;{}
   Inc(YP,YOdsaz+I*(YFontSize+YSpace)+YButtonOdsaz);
   XP:=XP+(X-BigButtonXSize) shr 1;
   CreateButton(XP,YP,1,0,False,_Ano); ButtonText(_Ano,15,'OK');
   Release(_Ano); SetActive(_Ano);
   CursorOn;

   repeat
     Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
   until ((Num = _Ano) or (Scan <> 0));
   DeleteButton(_Ano,256);
   CloseInfoPanel;{}
   I:=IOResult;
   InvalidateCache;
end;

{ ***** }
function DialogBox(Msg:String; DlgType:Byte):Byte;
{ vypise dialogovy box se zpravou Msg; muze byt nekolika typu:
  _YES, _YES_NO, _YES_NO_CANCEL a vraci kod stisknuteho tlacitka:
  YES - tlacitko Ano
  NO  - tlacitko Ne
  CANCEL  - tlacitko Storno
}
const XSpace = 35;
var X,Y,I,XLen,YLen:Word;
    Num, Button, Scan, Ascii:Word;
    Konec:Boolean;
begin
   XLen:=Length(Msg)*XFontSize;
   YLen:=YFontSize+BigButtonYSize+4*YFontSize;

   case (DlgType) of
     _YES           : begin
                        if (XLen < BigButtonXSize) then XLen:=BigButtonXSize;
                        XLen:=XLen+SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-BigButtonXSize) shr 1,Y+3*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,66,'ANO');
                      end;
     _YES_NO        : begin
                        if (XLen < (2*BigButtonXSize+XSpace)) then XLen:=2*BigButtonXSize+XSpace;
                        XLen:=XLen+SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-2*BigButtonXSize-XSpace) shr 1,Y+3*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,66,'ANO');
                        CreateButton(X+(XLen-2*BigButtonXSize-XSpace) shr 1+BigButtonXSize+XSpace,
                                     Y+3*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,66,'NE');
                      end;
     _YES_NO_CANCEL : begin
                        if (XLen < (3*BigButtonXSize+2*XSpace)) then XLen:=3*BigButtonXSize+2*XSpace;
                        XLen:=XLen+SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;

                        CreateButton(X+(XLen-3*BigButtonXSize-2*XSpace) shr 1,Y+3*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,66,'ANO');
                        CreateButton(X+(XLen-3*BigButtonXSize-2*XSpace) shr 1+BigButtonXSize+XSpace,
                                     Y+3*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,66,'NE');
                        CreateButton(X+(XLen-3*BigButtonXSize-2*XSpace) shr 1+2*BigButtonXSize+2*XSpace,
                                     Y+3*YFontSize,1,0,False,_Temp10);
                        ButtonText(_Temp10,66,'ZRUg');
                      end;
   end;

   ShowInfoPanel(X,Y,X+XLen-1,Y+YLen);
   ScreenOff; CursorOff;
   OutTextColor(X+(XLen-Length(Msg)*XFontSize) shr 1,Y+YFontSize,66,Msg);
   case (DlgType) of
     _YES           : begin
                        SetActive(_Temp8); Release(_Temp8);
                      end;
     _YES_NO        : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                      end;
     _YES_NO_CANCEL : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                        SetActive(_Temp10); Release(_Temp10);
                      end;
   end;
   ScreenOn; CursorOn;

   { ZPRACOVANI }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0         : begin
                       if ((Scan = $01) and (DlgType = _YES_NO_CANCEL))
                       then begin
                          DialogBox:=Cancel;
                          Konec:=True; { Esc }
                       end;
                       if (Scan = $1c) then begin
                          DialogBox:=YES;
                          Konec:=True; { Enter }
                       end;
                     end;
        _Temp8     : begin  { OK }
                        DialogBox:=YES;
                        Konec:=True;
                     end;
        _Temp9     : begin  { NO }
                        DialogBox:=No;
                        Konec:=True;
                     end;
        _Temp10     : begin  { CANCEL }
                        DialogBox:=Cancel;
                        Konec:=True;
                     end;
      end;
   end;

   ScreenOff; CursorOff;
   case (DlgType) of
     _YES           : begin
                        DeleteButton(_Temp8,256);
                      end;
     _YES_NO        : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                      end;
     _YES_NO_CANCEL : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                        DeleteButton(_Temp10,256);
                      end;
   end;
   CloseInfoPanel;
   ScreenOn; CursorOn;
end;

{ ***** }
function WideDialogBox(Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
{ vypise dialogovy box se zpravou Msg; muze byt nekolika typu:
  _YES, _YES_NO, _YES_NO_CANCEL a vraci kod stisknuteho tlacitka:
  YES - tlacitko Ano
  NO  - tlacitko Ne
  CANCEL  - tlacitko Storno
  (pro 3 samostatne retezce)
}
const XSpace = 40;
      TextColor = 66;
var X,Y,I,XLen,YLen:Word;
    Num, Button, Scan, Ascii:Word;
    Konec:Boolean;
begin
   XLen:=Length(Msg)*XFontSize;
   X:=Length(Msg1)*XFontSize; if (X > XLen) then XLen:=X;
   X:=Length(Msg2)*XFontSize; if (X > XLen) then XLen:=X;
   YLen:=4+3*YFontSize+SmallButtonYSize+3*YFontSize;

   case (DlgType) of
     _YES           : begin
                        if (XLen < SmallButtonXSize) then XLen:=SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-SmallButtonXSize) shr 1,Y+5*YFontSize,0,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                      end;
     _YES_NO        : begin
                        if (XLen < 2*SmallButtonXSize) then XLen:=2*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize+XSpace;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1,Y+5*YFontSize,0,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,0,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                      end;
     _YES_NO_CANCEL : begin
                        if (XLen < 3*SmallButtonXSize) then XLen:=3*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize+2*XSpace;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;

                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1,Y+5*YFontSize,0,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,0,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+2*SmallButtonXSize+2*XSpace,
                                     Y+5*YFontSize,0,0,False,_Temp10);
                        ButtonText(_Temp10,TextColor,'ZRUg');
                      end;
   end;

   CursorOff;
   ShowInfoPanel(X,Y,X+XLen-1,Y+YLen);
   CursorOff;
   OutTextColor(X+(XLen-Length(Msg)*XFontSize) shr 1,Y+YFontSize,96,Msg);
   OutTextColor(X+(XLen-Length(Msg1)*XFontSize) shr 1,Y+2*YFontSize+2,96,Msg1);
   OutTextColor(X+(XLen-Length(Msg2)*XFontSize) shr 1,Y+3*YFontSize+4,96,Msg2);
   case (DlgType) of
     _YES           : begin
                        SetActive(_Temp8); Release(_Temp8);
                      end;
     _YES_NO        : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                      end;
     _YES_NO_CANCEL : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                        SetActive(_Temp10); Release(_Temp10);
                      end;
   end;
   CursorOn;

   { ZPRACOVANI }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
           0       : begin
                       if ((Scan = $01) and (DlgType = _YES_NO_CANCEL)) then begin
                           WideDialogBox:=Cancel;
                           Konec:=True; { Esc }
                        end;
                        if (Scan = $1c) then begin
                           WideDialogBox:=YES;
                           Konec:=True;
                        end;
                     end;
        _Temp8     : begin  { OK }
                        WideDialogBox:=YES;
                        Konec:=True;
                     end;
        _Temp9     : begin  { NO }
                        WideDialogBox:=No;
                        Konec:=True;
                     end;
        _Temp10     : begin  { CANCEL }
                        WideDialogBox:=Cancel;
                        Konec:=True;
                     end;
      end;
   end;

   CursorOff;
   case (DlgType) of
     _YES           : begin
                        DeleteButton(_Temp8,256);
                      end;
     _YES_NO        : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                      end;
     _YES_NO_CANCEL : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                        DeleteButton(_Temp10,256);
                      end;
   end;
   CloseInfoPanel;
   CursorOn;
   Delay(250);
end;

{ ***** }
procedure Print_material(Order:Byte; Value:Integer);
{ vytiskne novy stav materialu Value dle promenne Order:
  1 .. stavebni material
  2 .. plasty
  3 .. elektricka energie
  4 .. bojova zkusenost
}
var X,Y,Pom:Word;
    Ret:String;
    Color:Byte;
begin
   case (Order) of
     1 : Rectangle2(XMaterialNumber1,YMaterialNumber1,XMaterialNumber1+XMaterialNumberLength,
                   YMaterialNumber1+YMaterialSlotSize,0);
     2 : Rectangle2(XMaterialNumber2,YMaterialNumber2,XMaterialNumber2+XMaterialNumberLength,
                   YMaterialNumber2+YMaterialSlotSize,0);
     3 : Rectangle2(XMaterialNumber3,YMaterialNumber3,XMaterialNumber3+XMaterialNumberLength,
                   YMaterialNumber3+YMaterialSlotSize,0);
     4 : Rectangle2(XMaterialNumber4,YMaterialNumber4,XMaterialNumber4+XMaterialNumberLength,
                   YMaterialNumber4+YMaterialSlotSize,0);
   end;

   Str(abs(Value),Ret);
   if (Value < 0) then Ret:='-'+Ret else Ret:=' '+Ret;
   if (abs(Value) < 10) then Ret:='   '+Ret else
     if (abs(Value) < 100) then Ret:='  '+Ret
     else
       if (abs(Value) < 1000) then Ret:=' '+Ret
       else
         if (abs(Value) < 10000) then Ret:=''+Ret
         else Ret:=''+Ret;


   if (Value > 100) then Color:=160
   else if (Value > 20) then Color:=128
        else Color:=80;


   case (Order) of
     1 : OutTextColor(XMaterialNumber1,YMaterialNumber1,Color,Ret);
     2 : OutTextColor(XMaterialNumber2,YMaterialNumber2,Color,Ret);
     3 : OutTextColor(XMaterialNumber3,YMaterialNumber3,Color,Ret);
     4 : OutTextColor(XMaterialNumber4,YMaterialNumber4,Color,Ret);
   end;
end;

{ ***** }
procedure PrintRealTime;
{ procedura tiskne realny cas
}
var Second:Byte;
    Ret, Ret2:String;
    X,Y:Word;
begin
  if (ReadRealTime(RealHourMin,Second) and (RealHourMin <> LastRealHourMin))
  then begin
    LastRealHourMin:=RealHourMin;
    Str(Hi(RealHourMin),Ret2); Ret:=Ret2+':';
    if (Length(Ret2) = 1) then Ret:='0'+Ret;
    Str(Lo(RealHourMin),Ret2);
    if (Length(Ret2) = 1) then Ret2:='0'+Ret2;
    Ret:=Ret+Ret2;
    Rectangle2(RealHourMinX1,RealHourMinY1,RealHourMinX2,RealHourMinY2,0);
    X:=(RealHourMinX2-RealHourMinX1-5*XFontSize) shr 1;
    Y:=(RealHourMinY2-RealHourMinY1-YFontSize) shr 1;
    OutTextColor(RealHourMinX1+X,RealHourMinY1+Y,8,Ret);
  end;
end;
{ ************************** MENU ZVUK/HUDBA ******************************* }

{ ***** }
procedure CreateMenuTemp21;
{ vytvori obrazovku s povolenim vsech zvuku
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-22*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'POVOLIT VgECHNY ZVUKY?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+22*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (GetSoundVariables(0)) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         SetSoundVariables(0,True);
                      end;
         _NE        : begin
                         Konec:=True;
                         SetSoundVariables(0,False);
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuTemp22;
{ vytvori obrazovku s povolenim zvuku jednotek
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-23*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'POVOLIT ZVUKY JEDNOTEK?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+23*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (GetSoundVariables(1)) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         SetSoundVariables(1,True);
                      end;
         _NE        : begin
                         Konec:=True;
                         SetSoundVariables(1,False);
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuTemp23;
{ vytvori obrazovku s povolenim vsech zvuku
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-23*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'POVOLIT ZVUKY VjSTfELi?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+23*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (GetSoundVariables(2)) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         SetSoundVariables(2,True);
                      end;
         _NE        : begin
                         Konec:=True;
                         SetSoundVariables(2,False);
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuTemp24;
{ vytvori obrazovku s povolenim vsech zvuku
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-22*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'POVOLIT ZVUKY EXPLOZe?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+22*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (GetSoundVariables(4)) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         SetSoundVariables(4,True);
                      end;
         _NE        : begin
                         Konec:=True;
                         SetSoundVariables(4,False);
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuTemp25;
{ vytvori obrazovku s povolenim vsech zvuku
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-25*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'POVOLIT SYSTcMOVc ZPRaVY?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+25*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (GetSoundVariables(5)) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         SetSoundVariables(5,True);
                      end;
         _NE        : begin
                         Konec:=True;
                         SetSoundVariables(5,False);
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuTemp26;
{ vytvori obrazovku s povolenim vsech zvuku
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-25*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'POVOLIT ZVUKY NA POZADe?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+25*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (GetSoundVariables(7)) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         SetSoundVariables(7,True);
                         PlaySound(7,0,0,0);
                      end;
         _NE        : begin
                         Konec:=True;
                         SetSoundVariables(7,False);
                         StopSound(10);
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuZvuky;
{ vytvori obrazovku s menu zvuku
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
Again:
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*7 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*7) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 7 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-16*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'NASTAVENe ZVUKU:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+16*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp1); ButtonText(_Temp1,15,'VgECHNY ZVUKY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp2); ButtonText(_Temp2,15,'ZVUKY JEDNOTEK');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp3); ButtonText(_Temp3,15,'VjSTfELY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp4); ButtonText(_Temp4,15,'EXPLOZE');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp5); ButtonText(_Temp5,15,'SYSTcMOVc ZPRaVY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp6); ButtonText(_Temp6,15,'ZVUKY NA POZADe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Zpet); ButtonText(_Zpet,15,'ZPdT');

   Release(_Temp1); Release(_Temp2); Release(_Temp3); Release(_Temp4);
   Release(_Temp5); Release(_Temp6); Release(_Zpet);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3); SetActive(_Temp4);
   SetActive(_Temp5); SetActive(_Temp6); SetActive(_Zpet);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                         DeleteButton(_Zpet,256);
                         CreateMenuTemp21;
                         Konec:=True;
                      end;
         _Temp2     : begin
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256);  DeleteButton(_Temp6,256);
                         DeleteButton(_Zpet,256);
                         CreateMenuTemp22;
                         Konec:=True;
                      end;
         _Temp3     : begin
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                         DeleteButton(_Zpet,256);
                         CreateMenuTemp23;
                         Konec:=True;
                      end;
         _Temp4     : begin
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                         DeleteButton(_Zpet,256);
                         CreateMenuTemp24;
                         Konec:=True;
                      end;
         _Temp5     : begin
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                         DeleteButton(_Zpet,256);
                         CreateMenuTemp25;
                         Konec:=True;
                      end;
         _Temp6     : begin
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                         DeleteButton(_Zpet,256);
                         CreateMenuTemp26;
                         Konec:=True;
                      end;
         _Zpet      : begin
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256); DeleteButton(_Temp3,256);
   DeleteButton(_Temp4,256); DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
   DeleteButton(_Zpet,256);
end;

{ ***** }
procedure CreateMenuZvukHudba;
{ vytvori obrazovku s hudebnimi a zvukovymi volbami
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
Again:
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*3 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*3) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 3 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-11*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'ZVUK/HUDBA:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+11*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_CD); ButtonText(_CD,15,'CD-HUDBA');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_SBBlaster); ButtonText(_SBBlaster,15,'ZVUK');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Zpet); ButtonText(_Zpet,15,'ZPdT');
   Release(_CD); Release(_SBBlaster); Release(_Zpet);
   SetActive(_CD); SetActive(_SBBlaster); SetActive(_Zpet);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _CD        : begin
                        DeleteButton(_CD,256); DeleteButton(_SBBlaster,256);
                        DeleteButton(_Zpet,256);
                        Konec:=True;
                      end;
         _SBBlaster : begin
                        DeleteButton(_CD,256); DeleteButton(_SBBlaster,256);
                        DeleteButton(_Zpet,256);
                        CreateMenuZvuky;
                        Konec:=True;
                      end;
         _Zpet      : begin
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_CD,256); DeleteButton(_SBBlaster,256); DeleteButton(_Zpet,256);
end;

{ **************************** MENU KONEC ********************************** }
{ ***** }
procedure CreateMenuExit;
{ vytvori obrazovku s nastavenim konce hry
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-24*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'SKUTEbNd CHCETE SKONbIT?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+24*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         DeleteButton(_ANO,256); DeleteButton(_NE,256);
                         EndOfGame:=True; EndOfGameChanged:=True;
                         Konec:=True;
                      end;
         _NE        : begin
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;


{ ***** }
procedure LoadDialog;
{ nahrat posl. pozici nebo autosave?
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-25*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'ZVOLTE SI ULOkENOU POZICI'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+25*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'POZICE 1');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'AUTOSAVE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      LoadGame:=0;
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True; LoadGame:=1;
                      end;
         _NE        : begin
                         Konec:=True; LoadGame:=255;
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{ ***** }
procedure CreateMenuUstup;
{ vytvori obrazovku s povolenim vsech zvuku
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-25*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'SKUTEbNd CHCETE USTOUPIT?'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+25*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'ANO');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'NE');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin { Ano, ustoupit ! }
                         Retreat:=True; { True = aktivovany ustup ze hry }
                         RetreatTimmer:=RetreatTimmerValue; { az je na nule, ustup (hra) konci }
                         Konec:=True;
                      end;
         _NE        : begin  { Neustupovat ! }
                         Retreat:=False; { True = aktivovany ustup ze hry }
                         RetreatTimmer:=0; { az je na nule, ustup (hra) konci }
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
   { ukonceni menu }
   CursorOff;
   DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
   DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
   DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
   DeleteButton(_Hra,256);
   X:=(XResolution-XWindow1Size) shr 1{}; Y:=(YResolution-YWindow1Size) shr 1{};
   PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
   if (DrawScreen) then begin
      Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
      Draw_screen(IBeg,JBeg,0,0);
   end;
   CursorOn;
end;

{ ***** }
procedure CreateMenuAutosave;
{ vytvori s volbami autosave
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*3 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*3) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-15*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'VOLBY AUTOSAVE:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+15*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Nizka); ButtonText(_Nizka,15,'kaDNj');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Vysoka); ButtonText(_Vysoka,15,'POMALj');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Normalni); ButtonText(_Normalni,15,'RYCHLj');
   Inc(Y,BigButtonYSize+YFontSize);

   Release(_Normalni); Release(_Vysoka); Release(_Nizka);
   SetActive(_Normalni); SetActive(_Vysoka); SetActive(_Nizka);
   CursorOff;
     if (AUTOSAVE = 0) then ButtonFrame(_Nizka,64)
     else
       if (AUTOSAVE = 1) then ButtonFrame(_Normalni,64)
       else ButtonFrame(_Vysoka,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0    : if (Scan = $01) then Konec:=True; { Esc }
         _Nizka  : begin
                        AUTOSAVE:=0;
                        Konec:=True;
                      end;
         _Normalni  : begin
                        AUTOSAVE:=1;
                        Konec:=True;
                      end;
         _Vysoka    : begin
                        AUTOSAVE:=2;
                        Konec:=True;
                      end;

      end;
   end;
   DeleteButton(_Normalni,256);DeleteButton(_Vysoka,256);DeleteButton(_Nizka,256);
end;

{ ***** }
procedure CreateMenuRychlostHry;
{ vytvori s volbami rychlosti hry
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-13*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'RYCHLOST HRY:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+13*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Normalni);
   if (GameSpeed = 0) then ButtonText(_Normalni,15,'POMALa')
   else ButtonText(_Normalni,15,'NORMaLNe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Vysoka);
   if (GameSpeed = 0) then ButtonText(_Vysoka,15,'NORMaLNe')
   else ButtonText(_Vysoka,15,'RYCHLa');
   Inc(Y,BigButtonYSize+YFontSize);

   Release(_Normalni); Release(_Vysoka);
   SetActive(_Normalni); SetActive(_Vysoka);
   CursorOff;
     if (Slow) then ButtonFrame(_Normalni,64)
     else ButtonFrame(_Vysoka,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0    : if (Scan = $01) then Konec:=True; { Esc }
         _Normalni  : begin
                        Konec:=True; Slow:=True;
                        {Delay1 := 2; SetDelay(Delay1); GameTimming:=1;{}
                      end;
         _Vysoka    : begin
                        Konec:=True; Slow:=False;
                        {Delay1 := 1; SetDelay(Delay1); GameTimming:=1; {}
                      end;
      end;
   end;
   DeleteButton(_Normalni,256); DeleteButton(_Vysoka,256);
end;

{ ***** }
procedure CreateMenuRealTimeScroll;
{ vytvori obrazovku s povoleni real-time rolovani
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*2 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*2) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 2 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-23*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'ZVOLTE SI STYL ROLOVaNe'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+27*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ano); ButtonText(_Ano,15,'KLASIKA');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ne); ButtonText(_Ne,15,'STORMNET');

   Release(_ANO); Release(_NE);
   SetActive(_ANO); SetActive(_NE);
   CursorOff;
   if (War2Scroll) then ButtonFrame(_ANO,64)
   else
     ButtonFrame(_NE,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _ANO       : begin
                         Konec:=True;
                         {RealTimeScroll:=True; ScrollSpeed:=2;{}
                         War2Scroll:=True;
                      end;
         _NE        : begin
                         Konec:=True;
                         {RealTimeScroll:=False;{}
                         War2Scroll:=False;
                      end;
      end;
   end;
   DeleteButton(_ANO,256); DeleteButton(_NE,256);
end;

{$F+}
{ ***** }
procedure FinishGame;
{ provede ukonceni hry + veskere odalokovani pameti
}
var ErFile:File;
    PomStr,Pom:String;
begin
   ExitProc:=OldExitProc;
   Shutdown; {}
   if (ExitCode <> 0) then begin
      if (ExitCode = MaxInt) then {Write(ErrorString){}
      else begin
         if ((GlobalStep = 65535) and (Units[GlobalJ] <> Nil)) then begin
           {Writeln;
           Write('ERROR unit info saved!');{}
           Assign(ErFile,'unit.log'); Rewrite(ErFile,1); IO_Result:=IOResult;
           BlockWrite(ErFile,Units[GlobalJ]^,SizeOf(Units[GlobalJ]^)); IO_Result:=IOResult;
           Close(ErFile); IO_Result:=IOResult;
         end;
      end;
   end;
   {x}
   if (ExitCode = 0) then DrawResult;{}
   {Disband_units; {}
   {Finish_shots;{}
   {Destroy_buildings;{}
   Dispose(Map); Dispose(MapBck); Dispose(MapBckTemp); Dispose(MapInfo);
   Dispose(SpecNumList); Dispose(BuildRadar); Dispose(DebrisInfo);
   Dispose(RacesTGInfo); Dispose(GlobalModify);{}
   Delay(50);{}
   Close_gr_mode;
   {Writeln;
   Write('Stormnet exit 1');{}
   asm
     sti
     mov Ah,03h
     mov Al,0h
     int 16h
   end;
{   asm { hide cursor }
{      mov Ah,02
      mov Bh,0h
      mov Dh,25
      mov Dl,0
      Int 10h
   end;{}
   {Writeln(ExitCode);{}
   {Writeln(ErrorString);{}
   IO_Result:=IOResult;
   if (ExitCode <> 0) then begin
      if (ExitCode = MaxInt) then begin
        Assign(ErFile,'error.log'); Rewrite(ErFile,1); IO_Result:=IOResult;
        BlockWrite(ErFile,ErrorString,Length(ErrorString)); IO_Result:=IOResult;
        Close(ErFile); IO_Result:=IOResult;
      end else begin
         Assign(ErFile,'error.msg'); Rewrite(ErFile,1); IO_Result:=IOResult;
         {x}
         Str(ExitCode,Pom); PomStr:='Error program termination: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         case (ExitCode) of
            1 : Pom:='Invalid function number';
            2 : Pom:='File not found';
            3 : Pom:='Path not found';
            4 : Pom:='Too many open files';
            5 : Pom:='File access denied';
            6 : Pom:='Invalid file handle';
           12 : Pom:='Invalid file access code';
           15 : Pom:='Invalid drive number';
           16 : Pom:='Cannot remove current directory';
           17 : Pom:='Cannot rename across drives';
           18 : Pom:='No more files';
          100 : Pom:='Disk read error';
          101 : Pom:='Disk write error';
          102 : Pom:='File not assigned';
          103 : Pom:='File not open';
          104 : Pom:='File not open for input';
          105 : Pom:='File not open for output';
          106 : Pom:='Invalid numeric format';
          150 : Pom:='Disk is write-protected';
          151 : Pom:='Bad drive request struct length';
          152 : Pom:='Drive not ready';
          154 : Pom:='CRC error in data';
          156 : Pom:='Disk seek error';
          157 : Pom:='Unknown media type';
          158 : Pom:='Sector Not Found';
          159 : Pom:='Printer out of paper';
          160 : Pom:='Device write fault';
          161 : Pom:='Device read fault';
          162 : Pom:='Hardware failure';
          200 : Pom:='Division by zero';
          201 : Pom:='Range check error';
          202 : Pom:='Stack overflow error';
          203 : Pom:='Heap overflow error';
          204 : Pom:='Invalid pointer operation';
          205 : Pom:='Floating point overflow';
          206 : Pom:='Floating point underflow';
          207 : Pom:='Invalid floating point operation';
          208 : Pom:='Overlay manager not installed';
          209 : Pom:='Overlay file read error';
          210 : Pom:='Object not initialized';
          211 : Pom:='Call to abstract method';
          212 : Pom:='Stream registration error';
          213 : Pom:='Collection index out of range';
          214 : Pom:='Collection overflow error';
          215 : Pom:='Arithmetic overflow error';
          216 : Pom:='General Protection fault';
         else
            Pom:=' ';
         end;
         PomStr:=Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         Close(ErFile); IO_Result:=IOResult;
         {x}
         Assign(ErFile,'error.log'); Rewrite(ErFile,1); IO_Result:=IOResult;
         {x}
         Str(TimeSlot,Pom); PomStr:='TimeSlot: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(GlobalStep,Pom); PomStr:='GlobalStep: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(GlobalJ,Pom); PomStr:='GlobalJ: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(bebex,Pom); PomStr:='bebex: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(bebey,Pom); PomStr:='bebey: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(save1,Pom); PomStr:='save1: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(save2,Pom); PomStr:='save2: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {x}
         Str(IMemPom,Pom); PomStr:='IMemPom: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(JMemPom,Pom); PomStr:='JMemPom: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(IBeg,Pom); PomStr:='IBeg: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(JBeg,Pom); PomStr:='JBeg: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(XMemBeg,Pom); PomStr:='XMemBeg: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Str(YMemBeg,Pom); PomStr:='YMemBeg: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Pom:=Locate; PomStr:='Misto: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         Close(ErFile); IO_Result:=IOResult;
         {x}
         Assign(ErFile,'error.adr'); Rewrite(ErFile,1); IO_Result:=IOResult;
         {x}
         if (ErrorAddr <> Nil) then begin
           Str(Seg(ErrorAddr^),Pom); PomStr:='adress: '+Pom;
           Str(Ofs(ErrorAddr^),Pom); PomStr:=PomStr+':'+Pom+Chr($0d)+Chr($0a);
           BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         end;
         Close(ErFile); IO_Result:=IOResult;
      end;
   end;
   {Delay(3000);
   {Writeln('  ! Stormnet user exit done');{}
end;

{ ***** }
procedure Grafika4_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'6'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Grafika4_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'6'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************ }
begin
   XInfoPanel:=0; YInfoPanel:=0;
end.
