program global;
{$C FIXED PRELOAD PERMANENT}
uses SBSound, Dos, Crt, Data_GLB, vesa_emm, Graph257, GlobGraf, Buttons,
     mouse,SpecGraf, _research, GlobalKod, GlobKod2, GlobKod3;

label Konec2, Konec, Znovu, Proceed;
var I,J,X,Y,X2,Y2,K,S,O:Word;
    Butt, Scn,AScii:Word;
    Color:Byte;
    Character:Char;
    Size:LongInt;
    GAMETIME,POMTIME:Word;
    Pom:Single; {///////}
    Single,PomTag:Boolean;
    First:Boolean;
    Scan:Byte;
    _GameUniqueNum:LongInt;
    OldExitProc:Pointer;
    MyLostB, MyLostU, MyKilledB, MyKilledU:LongInt;
    Score, Time:LongInt;

{ ***** }
procedure TimerOn; assembler;
{ nastartuje mereni casoveho intervalu
}
asm
   mov Ah,00h
   int 1ah
   mov GAMETIME,Dx
   mov POMTIME,Cx
   mov Ax,Del1
   add GAMETIME,Ax{}

@end:
end;

{ ***** }
procedure TimerWait; assembler;
{ ceka do uplynuti intervalu
}
asm
@again:
   mov Ah,00h
   int 1ah
   cmp Cx,POMTIME
   ja @end
   cmp Dx,GAMETIME
   jb @again

@end:
end;{}

{ ***** }
procedure FinishGame;
var ErFile:fILE;
    Pom, PomStr:String;
begin
   ExitProc:=OldExitProc;
   FinishMouse;
   Shutdown;
   CloseGraph;{}
   if (ExitCode <> 0) then begin
      if (ExitCode = 65535) then Write(ErrorString)
      else begin
         Assign(ErFile,'error.log'); Rewrite(ErFile,1); IO_Result:=IOResult;
         Str(ExitCode,Pom); PomStr:='Error program termination: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(TimeSlot,Pom); PomStr:='TimeSlot: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(GlobalStep,Pom); PomStr:='GlobalStep: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(GlobalJ,Pom); PomStr:='GlobalJ: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(bebex,Pom); PomStr:='bebex: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(bebey,Pom); PomStr:='bebey: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(save1,Pom); PomStr:='save1: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;
         {x}
         {Str(save2,Pom); PomStr:='save2: '+Pom+Chr($0d)+Chr($0a);
         BlockWrite(ErFile,PomStr[1],Length(PomStr)); IO_Result:=IOResult;{}

         Close(ErFile);
      end;
   end;

end;

{ ***** }
procedure DeleteSaveFiles(Path:string);
{
}
label Konec;
var Rec:SearchRec;
    DResult:Word;
begin
   FindFirst(Path,Directory,Rec);
   DResult:=DosError;
   if ((DResult = 3) or (DResult = 18)) then begin
   { cesta neexistuje  }
      DResult:=0;
   end else begin
     if ((DResult = 2) or (DResult = 0)) then begin
     { adresar existuje - vymaz ho }
       FindFirst(Path+'\*.*',AnyFile,Rec); DResult:=DosError;
       while (DResult = 0) do begin
         if ((Rec.Attr <> Directory) and (Rec.Name <> 'NAME')) then begin
           Assign(IOFile,Path+'\'+Rec.Name);
           Erase(IOFile); DResult:=IOResult;
         end;
         FindNext(Rec); DResult:=DosError;
       end;
     end else begin
     { nejaka chyba ! }
       DResult:=DResult; GoTo KOnec;
     end;
   end;
Konec:
end;

{ ***** }
procedure LoadMissionResult(var MyLostB, MyLostU, MyKilledB, MyKilledU, Score, Time:LongInt);
{ nahraje vysledek mise z disku
}
var IOFile:File;
    Temp1, Temp2:Word;
begin
   Assign(IOFile,PathStrGlobal+'result'); Reset(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,PlayerId,SizeOf(PlayerId));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,Game,SizeOf(Game));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,Campaign,SizeOf(Campaign));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,Victory,SizeOf(Victory));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,POI,SizeOf(POI));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,VICTORYPOI,SizeOf(VICTORYPOI));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,CoreInfo,SizeOf(CoreInfo));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,_GameUniqueNum,SizeOf(_GameUniqueNum));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');

{x}BlockRead(IOFile,MyLostB,SizeOf(MyLostB));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,MyLostU,SizeOf(MyLostU));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,MyKilledB,SizeOf(MyKilledB));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,MyKilledU,SizeOf(MyKilledU));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,Score,SizeOf(Score));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,Time,SizeOf(Time));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');

{x}BlockRead(IOFile,Temp1,SizeOf(Temp1));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
{x}BlockRead(IOFile,Temp2,SizeOf(Temp2));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri nahravani "result"');
   if ((Game = 54) and (Temp1 <> 0)) then begin
      Zrada:=True;
   end;

   Close(IOFile); DResult:=IOResult;
end;

{ ***** }
function GetPlayerUniqueNum:LongInt;
{
}
var PomNum:LongInt;
    A,B,C,D:Word;
begin
{   Assign(IOFile,PathStrGlobal+'unique.num'); Reset(IOFile,1); DResult:=IOResult;
   if (DResult = 0) then begin
     BlockRead(IOFile,PomNum,SizeOf(PomNum));
     DResult:=IOResult; if(DResult<>0) then Error(DResult,'chyba pri nahravani "unique.num"');
     PomNum:=PomNum+1;
     if (PomNum > 2147483646) then PomNum:=0;
   end else begin
     {GetTime(var Hour, Minute, Second, Sec100: Word);{}
   GetTime(A,B,C,D);
     { nove unikatni cislo na zaklade casu pocitace }
   PomNum:=LongInt(A)*360000+LongInt(B)*6000+LongInt(C)*100+LongInt(D);
     {GetDate(var Year, Month, Day, DayOfWeek: Word);{}
   GetDate(A,B,C,D);
   PomNum:=PomNum+10000000*(LongInt(C));
   {end;

   Assign(IOFile,PathStrGlobal+'unique.num'); Rewrite(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then Error(DResult,'chyba pri nahravani "unique.num"');
   BlockWrite(IOFile,PomNum,SizeOf(PomNum));
   DResult:=IOResult; if(DResult<>0) then Error(DResult,'chyba pri nahravani "unique.num"');{}
   GetPlayerUniqueNum:=PomNum;
end;

{ ***** }
begin
  OldExitProc:=ExitProc;
  ExitProc:=@FinishGame;

  Debug:=False;
  Demo:=False;
  PathStrGlobal:=''; { DEBUG  - adresar Global}
  PathStr:='..\';    { DEBUG - adresar nad Globalem }

  PathStrGlobal:='GLOBAL\'; { RELEASE  - adresar Global }
  PathStr:=''; { RELEASE - adresar nad Globalem }

   SoundInit;
   Single:=False; First:=True; GameUniqueNum:=-1;
   { ***** PRI KAZDEM SPUSTENI EXACE PRED VOLBOU MISE **** }
   {*}Kadence[0]:=100;
   {*}Kadence[1]:=30; Kadence[2]:=26; Kadence[3]:=22; Kadence[4]:=19;
   {*}Kadence[5]:=17; Kadence[6]:=15; Kadence[7]:=12; Kadence[8]:=9;
   {*}Kadence[9]:=6; Kadence[10]:=0;
   {*}MissionNameString:='0';
   {*}I:=0; LoadGameCfg;
   {*}Init_graph(False);
   {*}CursorOff; ClearScreen; CursorOn;
   {*}Load_unit_picture;{}
   {*}AnimationInit(AnimRec);{}
   {+} OSNPlayer:=True;
   {*}InitReasearchAssign;
   {*}{ ????????????????????????????????????? }
   {*}{?}PlayerId:='HRAC1'; { identifikace hrace }
   {*}{?}Game:=0; Campaign:=1; { identifikace hry }
   {*}{?}SavePath:=PlayerId;
   CancelGame:=False; Week:=0; EnemyRaces:=[];
   { ********************************* }

   if (ParamCount <> 1) then begin
   { pokracuj v rozpracovane misi }
       First:=False; LoadMissionResult(MyLostB, MyLostU, MyKilledB, MyKilledU, Score, Time);
       SavePath:=PlayerId;
       {x}
       if (Demo and (Game <> 52) and
           ((Game = 2) and (Victory = 1) or (Game >= 3))) then begin
         DialogBox('V DEMOVERZI NEMikETE DaLE POKRAbOVAT.',_YES);
         Goto Znovu;
       end;
       {x}
       Assign(IOFile,PathStr+'save\'+SavePath+'\$$$'); Reset(IOFile,1); DResult:=IOResult;
       if (DResult = 0) then begin
          Close(IOFile); DResult:=IOResult; GoTo Znovu;
       end;
       Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Reset(IOFile,1); DResult:=IOResult;
       if (DResult = 0) then begin Close(IOFile); DResult:=IOResult; GoTo Znovu; end;
       {x}
       Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Erase(IOFile); DResult:=IOResult;
       GLB_load('global.sim');
       if (DResult <> 0) then DialogBox('CHYBA PRI NAHRAVANI HRY!',_YES)
       else begin
         if (GameUniqueNum <> _GameUniqueNum) then begin
           DialogBox('CHYBA V beSLECH MISe!',_YES); GoTo Znovu;
         end;
         GameUniqueNum:=GameUniqueNum+1;
         InitGlobalModif;
         SetGrModeVariables(True,True); CursorOff;
         SetPasive(ResearchButton,256); SetPasive(DalsiTydenButton,256);
         SetPasive(CoreButton,256);     SetPasive(InfoButton,256);
         SetPasive(OptionButton,256);   SetPasive(SaveButton,256);
         SetPasive(LoadButton,256);     SetPasive(EndButton,256);
         SetPasive(StartButton,256); CursorOn;
         { nyni aktualizuj jadro }
         for I:=0 to MaxCoreUnits-1 do with (CoreInfo[I]) do
         if (UniqueNumber <> 65535) then begin
            if (Destroyed) then begin
              CORELOST:=CORELOST+1;
              Core.Delete(UniqueNumber);
            end else Core.Update(UniqueNumber,CoreInfo[I]);
         end;
         CoreSelectedCount:=0; Week:=0; ClearCoreSelection;
         LOSTB:=LOSTB+MyLostB; LOSTU:=LOSTU+MyLostU;
         KILLEDU:=KILLEDU+MyKilledU; KILLEDB:=KILLEDB+MyKilledB;
         TOTALPOINTS:=TOTALPOINTS+ComputeTotalPoints(Score,Time,MyLostU,MyLostB,CORELOST);
         if (Victory = 1) then begin
            VICTORYNUM:=VICTORYNUM+1;
         end;
         SaveBestTable; { ulozit prubezne vysledky na disk }
       end;
     { !!! ZDE NAHRAT RESULT, global.sav }
      { **** TOHLE VYMAZAT : *** }
      { OSNPlayer:=True;
       Points:= 800; VictoryPoints:=6;
       if (OSNPlayer) then OSNResearchInit else RobotResearchInit;
       GlobalModify.ActionLevel:=4;
       GlobalModify.GameLevel:=1;
       MissionNameString:='0';  {}
      { **** KONEC VYMAZANI **** }

   end else begin
   { spust uvodni obrazovku }
      if ((ParamCount = 1) and (ParamStr(1) = 'runnew') and First)
      then begin
         {Exec(PathStr+'cdrom.exe','p');{}
         First:=False;
      end else First:=False;
Znovu:
      case (InitScreen) of
         0 : begin { nova kampan }
                 { **** POUZE 1x za kampan: }
                 {+} OSNPlayer:=True;
                 {+} Points:= 2200; VictoryPoints:=3; MissionNum:=0;
                 {*} if (OSNPlayer) then OSNResearchInit else RobotResearchInit;
                 {*} GlobalModify.ActionLevel:=4; { typ hry   - uvodni inicializace }
                 {*} GlobalModify.GameLevel:=3;   { obtiznost - uvodni inicializace }
                 {*} _GameLevel:=3; GameUniqueNum:=Random(1000);
                 {*} PlayerUniqueNum:=GetPlayerUniqueNum; { SKUTECNE UNIQUE NUM}
                 {*} TOTALPOINTS:=0; LOSTB:=0; LOSTU:=0;
                 {*} KILLEDB:=0; KILLEDU:=0; VICTORYNUM:=0; CORELOST:=0;
                 { ************************ }
                 SaveBestTable; { ulozit prubezne vysledky na disk }
                 MissionNameString:='0';
                 {*}InitReasearchAssign;
                 {*} Game:=0; Campaign:=1;
                 {*} SavePath:=PlayerId;
                 InitGlobalModif; Week:=0;
                 InitCoreStruct(True); GlobalSelectedResearch:=0;
                 { * vymazani udaju z predchozi hry * }
                 DeleteSaveFiles(PathStr+'save\'+SavePath);
                 {Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Erase(IOFile); DResult:=IOResult;{}
             end;
         1 : begin { single mise }
                { vymaz gameset }
                SetGrModeVariables(True,True); GameUniqueNum:=0;
                if (SelectSingleMission) then begin
                  PlayerId:='SINGLE';
                  SaveMain;
                  GoTo Konec;
                end else begin
                  GoTo Znovu;
                end;
             end;
         2 : begin { pokracovat - nahrej }
                 SavePath:=PlayerId; PomTag:=True;
                 InitGlobalModif;
                 Assign(IOFile,PathStr+'save\'+SavePath+'\$$$'); Reset(IOFile,1); DResult:=IOResult;
                 if (DResult = 0) then begin
                   GLB_load('global.sim');
                   if (DResult <> 0) then begin
                      CursorOff; ClearScreen; CursorOn;
                      DialogBox('CHYBA PRI NAHRAVANI HRY!',_YES);
                      Goto Znovu;
                   end;
                   Goto Konec2;
                 end else begin
                   Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Reset(IOFile,1); DResult:=IOResult;
                   if (DResult <> 0) then PomTag:=False;
                   if (PomTag) then begin
                      CancelGame:=False; BlockRead(IOFile,Game,SizeOf(Game));
                      Close(IOFile); DResult:=IOResult;
                      SaveMain;
                      GoTo Konec;
                   end;
                   Close(IOFile); DResult:=IOResult;
                   if (not SelectGameSlot(True)) then GoTo Znovu;
                   GLB_load(SaveSlotId);
                   if (DResult <> 0) then begin
                      CursorOff; ClearScreen; CursorOn;
                      DialogBox('CHYBA PRI NAHRAVANI HRY!',_YES);
                      Goto Znovu;
                   end
                 end;
                 Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Erase(IOFile); DResult:=IOResult;
                 SetGrModeVariables(False,False);
                 LoadMissionData;
                 DrawPoints; { /// }
                 DrawVictoryPoints; { /// }
                 if (GlobalSelectedResearch > 0) then begin
                   Draw_active_research(GlobalSelectedResearch,
                                        Research^[GlobalSelectedResearch].PercState,
                                        True);
                 end; {CoreSelectedCount:=0;{}
                 GoTo Proceed;
             end;
         3 : begin { nahrej global }
                 InitGlobalModif;
                 SavePath:=PlayerId; PomTag:=True;
                 GLB_load(SaveSlotId);
                 if (DResult <> 0) then begin
                    CursorOff; ClearScreen; CursorOn;
                    DialogBox('CHYBA PRI NAHRAVANI HRY!',_YES);
                    Goto Znovu;
                 end;
                 Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Erase(IOFile); DResult:=IOResult;
                 SetGrModeVariables(False,False);
                 LoadMissionData;
                 DrawPoints; { /// }
                 DrawVictoryPoints; { /// }
                 if (GlobalSelectedResearch > 0) then begin
                   Draw_active_research(GlobalSelectedResearch,
                                        Research^[GlobalSelectedResearch].PercState,
                                        True);
                 end; {CoreSelectedCount:=0;{}
                 GoTo Proceed;
             end;
         4 : begin { konec }
                { nastav main.cfg }
                CancelGame:=True;
                SaveMain;
                GoTo Konec;
             end;
      end;
      { nastav Single, misi ... }
   end;

   if (Single) then begin
   { single mise }
   end else begin
   { pokracovani v kampani }
      InitCoreStruct(False);
      if ((Game = 37) or (Game = 38)) then begin
         CursorOff; ClearScreen; ClearKeyboardBuffer;
         OpenImage(PathStrGlobal+'data\victory.bmp',NoCreateNew);
         LoadImageBMP(SScreen,OScreen,NoRGB); LoadRGB(0,PathStrGlobal+'data\victory.rgb');{}
         if (IO_Result = 0) then
           PutImage((XResolution-640) shr 1,(YResolution-480) shr 1,SScreen,OScreen,ReverseDirect);
         InvalidateCache; MousKeybClick(X,Y,Butt,Scn,Ascii); CursorOn;
      end;
      if (((Game = 32) or (Game = 34) or (Game = 35) or (Game = 20) or
           (Game = 26) or (Game = 27) or (Game = 67)) and (Victory <= 0))
      then begin
         CursorOff; ClearScreen; ClearKeyboardBuffer;
         OpenImage(PathStrGlobal+'data\lose.bmp',NoCreateNew);
         LoadImageBMP(SScreen,OScreen,NoRGB); LoadRGB(0,PathStrGlobal+'data\lose.rgb');{}
         if (IO_Result = 0) then
           PutImage((XResolution-640) shr 1,(YResolution-480) shr 1,SScreen,OScreen,ReverseDirect);
         InvalidateCache; MousKeybClick(X,Y,Butt,Scn,Ascii); CursorOn;
      end;
      if ((Game = 67) and (Victory >= 1))
      then begin
         CursorOff; ClearScreen; ClearKeyboardBuffer;
         OpenImage(PathStrGlobal+'data\escape.bmp',NoCreateNew);
         LoadImageBMP(SScreen,OScreen,NoRGB); LoadRGB(0,PathStrGlobal+'data\escape.rgb');{}
         if (IO_Result = 0) then
           PutImage((XResolution-640) shr 1,(YResolution-480) shr 1,SScreen,OScreen,ReverseDirect);
         InvalidateCache; MousKeybClick(X,Y,Butt,Scn,Ascii); CursorOn;
      end;
      if (not SelectMission) then begin
        GameLost; CursorOff; ClearScreen; CursorOn; GoTo Znovu;
      end;
      SetGrModeVariables(False,True);{}

      { ***** PRI KAZDEM SPUSTENI EXACE PO VOLBE MISE **** }
      { !!! tyto udaje zjistit z manazer.pas: !!! }
      {*}LoadMissionData; { pro kazdou misi zvlast }
      {*}DrawPoints; { /// }
      {*}DrawVictoryPoints; { /// }
      {*}if (GlobalSelectedResearch > 0) then begin
      {*}   Draw_active_research(GlobalSelectedResearch,
      {*}                        Research^[GlobalSelectedResearch].PercState,
      {*}                        True);
      {*}end;
      { ********************************* }
Proceed:
      CursorOff; SetActive(ResearchButton);  SetActive(DalsiTydenButton);
      SetActive(CoreButton);      SetActive(InfoButton);
      SetActive(OptionButton);    SetActive(SaveButton);
      SetActive(LoadButton);      SetActive(EndButton);
      SetActive(StartButton); CursorOn;
      { ***** }
      SetDelay(1); TimeSlot:=0; Pom:=0; EndOfGame:=False;
      {!!!!!!} {for I:=1 to MaxResearch do Research^[I].PercState:=100; {!!!!!!}
      while (not EndOfGame) do begin
        TimerOn;{}
        Inc(TimeSlot);
        if (TimeSlot > 65000) then TimeSlot:=0;

        GetSpecKeysState;
        Animation(AnimRec);{}

        {/////}
        {/}ReadKeys(Scan);
        {/} if (Scan = $72) then SaveScreen; { ctrl+PrintScreen }
        {/////}

        Temp:=False;
        ButtonManager;{}
        if (Temp) then begin
           CursorOff; DeleteButton(ResearchButton,256);
           DeleteButton(DalsiTydenButton,256); DeleteButton(CoreButton,256);
           DeleteButton(InfoButton,256);       DeleteButton(OptionButton,256);
           DeleteButton(SaveButton,256);       DeleteButton(LoadButton,256);
           DeleteButton(EndButton,256);        DeleteButton(StartButton,256);
           ClearScreen; CursorOn;
           GoTo Znovu;
        end;
        ClearKeyboardBuffer;
        TimerWait; { synchronizace }
      end;
   end;

   Assign(IOFile,PathStr+'save\'+SavePath+'\continue'); Erase(IOFile); DResult:=IOResult;
Konec:
   Assign(IOFile,PathStr+'save\'+SavePath+'\$$$'); Erase(IOFile); DResult:=IOResult;
Konec2:
end.
