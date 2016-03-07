unit GlobGraf;
{$C FIXED PRELOAD PERMANENT}
interface
uses Dos, data_glb, graph257, mouse;

procedure Init_graph(Tag:Boolean);
procedure ShowInfoPanel(X,Y,X2,Y2:Word; Tag:Byte);
procedure ShowInfoPanel2(X,Y,X2,Y2:Word; Tag:Byte);
procedure CloseInfoPanel;
procedure AnimationInit(var AnimRec:TAnimRec);
procedure Animation(var AnimRec:TAnimRec);
procedure LoadMissionData;
procedure MenuOptions;
function SelectGameSlot(OnlyActive:Boolean):Boolean;
procedure SaveScreen;
function InitScreen:Word;
procedure SetGrModeVariables(Light,NotInitGr:Boolean);

implementation

uses buttons, _research, GlobalKod, SpecGraf, GlobKod3;
const Ws : set of Byte = [$0d,$20,$0a];

var XInfoPanel, YInfoPanel:Word;
    MapCfgFile:File;
    MapCfgFileWay:String;
    Character:Char;

{ ***** }
procedure Init_gr_mode(X,Y:Word);
{ nainicializuje graficky rezim v rozliseni X*Y; pokud dojde k chybe
  pri detekci SVGA karty nebo EMS manazeru, nahlasi chybu a ukonci program
}
var Result:Word;
begin
   if (Debug) then Result:=GraphInit(X,Y,X,Y)
   else Result:=GraphInit(X,Y,X+40,Y);
   if (Result = 1) then Error(0,' videokarta nepodporuje VESA standard');
   if (Result = 2) then Error(0,' videokarta dane rozliseni nepodporuje');
   if (Result > 2) then Error(0,' nespecifikovana chyba pri graficke inicializaci');
   if (not InitMouse(X,Y)) then Error(0,' neuspesna inicializace mysi');{}
   ClearScreen;
   SetCursorRange(0,0,X-4,Y-4);{}
end;

procedure Init_gr_mode_light(X,Y:Word);
{ nainicializuje graficky rezim v rozliseni X*Y; pokud dojde k chybe
  pri detekci SVGA karty nebo EMS manazeru, nahlasi chybu a ukonci program
}
var Result:Word;
begin
   CursorOff;
   if (Debug) then GraphInitLight(X,Y,X,Y)
   else GraphInitLight(X,Y,X+40,Y);
   ClearScreen;
   SetCursorRange(0,0,X-4,Y-4);{}
   LoadRGB(0,PathStrGlobal+'data\paleta1.rgb');{}
   if (IO_Result <> 0) then Error(IO_Result,'chyba pri nahravani data\paleta1.rgb');
   CursorOn;
end;


{ ***** }
procedure Init_graph(Tag:Boolean);
{ inicializace grafiky
}
var I,X,Y:Word;
    Memory:LongInt;
begin
   GetMaxRes(MaxRes);
   Init_gr_mode(XResolution,YResolution);
   LoadRGB(0,PathStrGlobal+'data\paleta1.rgb');{}
   if (IO_Result <> 0) then Error(IO_Result,'chyba pri nahravani data\paleta1.rgb');
   case (MaxRes) of
     0 : begin
           if (not AllocateGlobalMemory(640*480+4+65535))
           then Error(0,'Nedostatek   pameti');
           GetMemory(640*480+4,SScreen,OScreen);
           if (SScreen = 0) then Error(0,'Nedostatek globalni pameti');
         end;
     1 : begin
           if (not AllocateGlobalMemory(800*600+4+65535))
           then Error(0,'Nedostatek   pameti');
           GetMemory(800*600+4,SScreen,OScreen);
           if (SScreen = 0) then Error(0,'Nedostatek globalni pameti');
         end;
     2 : begin
           if (not AllocateGlobalMemory(1024*768+4+65535))
           then Error(0,'Nedostatek   pameti');
           GetMemory(1024*768+4,SScreen,OScreen);
           if (SScreen = 0) then Error(0,'Nedostatek globalni pameti');
         end;
     3 : begin
           if (not AllocateGlobalMemory(1200*1024+4+65535))
           then Error(0,'Nedostatek   pameti');
           GetMemory(1200*1024+4,SScreen,OScreen);
           if (SScreen = 0) then Error(0,'Nedostatek globalni pameti');
         end;
   else
     if (not AllocateGlobalMemory(1200*1024+4+65535))
     then Error(0,'Nedostatek   pameti');
     GetMemory(1200*1024+4,SScreen,OScreen);
     if (SScreen = 0) then Error(0,'Nedostatek globalni pameti');
   end;

   if (not AllocateGlobalMemory(4400000))
   then Error(0,'Nedostatek   pameti');
   GetMemory(WindowMemory,Win1BckSeg,Win1BckOfs);
   if (Win1BckSeg = 0) then Error(0,'Nedostatek   pameti');
   if (Win1BckOfs <> 0) then begin
     Win1BckOfs:=0; Inc(Win1BckSeg,SelectorInc);
   end;
   {x}
   GetMemory(Window1Memory,TempSeg2, TempOfs2);
   if (TempSeg2 = 0) then Error(0,'Nedostatek   pameti');
   if (TempOfs2 <> 0) then begin
     TempOfs2:=0; Inc(TempSeg2,SelectorInc);
   end;
   {x}
   GetMemory(TempPictureMemory,TempSeg,TempOfs);
   if (TempSeg = 0) then Error(0,'Nedostatek   pameti');
   if (TempOfs <> 0) then begin
     TempOfs:=0; Inc(TempSeg,SelectorInc);
   end;
   {x}
   GetMemory(MissionScreenMemory, SMissionScreen, OMissionScreen);
   if (SMissionScreen = 0) then Error(0,'Nedostatek   pameti');
   if (OMissionScreen <> 0) then begin
     OMissionScreen:=0; Inc(SMissionScreen,SelectorInc);
   end;
   {x}
   GetMemory(GetStringBckMemory,GetStringBckSeg,GetStringBckOfs);
   if (GetStringBckSeg = 0) then Error(0,'Nedostatek   pameti');
   {x}
   InternalCache:=True;
   CacheInit;

   { * nahrani fontu * }
   GetMemory(60000, FontSegment, FontOffsets);
   if (FontSegment = 0) then Error(0,'Nedostatek   pameti');
   OpenImage(PathStrGlobal+'data\font8_16',NoCreateNew);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\font8_16');
   LoadImageGBM(FontSegment, FontOffsets,'font8_16',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\font8_16');
   Inc(FontOffsets,4);

   { * OKNA * }
   InvalidateCache;
   OpenImage(PathStr+'data\windows',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\windows');
   GetMemory(Window1Memory,Win1Seg,Win1Ofs);
   if (Win1Seg = 0) then Error(0,' nedostatek   pameti');
   if (Win1Ofs > 0) then begin
      Win1Ofs:=0; Inc(Win1Seg,SelectorInc);
   end;
{   GetMemory(Window1Memory,Win1BckSeg,Win1BckOfs);
   if (Win1BckSeg = 0) then Error(0,' nedostatek   pameti');{}
   LoadImageGBM(Win1Seg, Win1Ofs,'win1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\windows');

   OpenImage(PathStrGlobal+'data\back.bmp',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\back.bmp');
   GetMemory(LongInt(640)*480+4,SBack, OBack);
   if (SBack = 0) then Error(0,' nedostatek   pameti');
   if (OBack <> 0) then begin
      Inc(SBack,SelectorInc); OBack:=0;
   end;
   LoadImageBMP(SBack,OBack,NORGB);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\back.bmp');

   { * NAHRANI KURZORU MYSI * }
   GetMemory(XCursor*YCursor+4,NormalCursorSeg, NormalCursorOfs);
   if (NormalCursorSeg = 0) then Error(0,'Nedostatek   pameti');
   OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\cursors.glb');
   LoadImageGBM(NormalCursorSeg, NormalCursorOfs,'normal',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\cursors.glb');
   SetCursorSize(XCursor-1,YCursor-1);
   SetCursorPicture(NormalCursorSeg, NormalCursorOfs);

   LoadButtonFile(PathStrGlobal+'data\buttons.glb',2,1);
   { * NAHRANI SOUBORU HLP.GLB * }
   OpenImage(PathStrGlobal+'data\hlp.glb',NoCreateNew);
   if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani souboru hlp.glb'); end;
   GetXYIMageCoordinatesGBM(X,Y,'body');
   Memory:=X*Y+4; GetMemory(Memory,PointsSeg, PointsOfs);
   if (PointsSeg = 0) then Error(0,'nedostatek pameti');
   LoadImageGBM(PointsSeg, PointsOfs,'body',0);
   if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani souboru hlp.glb'); end;

   GetXYIMageCoordinatesGBM(X,Y,'vbody');
   Memory:=X*Y+4; GetMemory(Memory,VictoryPointsSeg, VictoryPointsOfs);
   if (VictoryPointsSeg = 0) then Error(0,'nedostatek pameti');
   LoadImageGBM(VictoryPointsSeg, VictoryPointsOfs,'vbody',0);
   if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani souboru hlp.glb'); end;

   Memory:=10000;
   GetMemory(Memory,PointsBckSeg, PointsBckOfs);
   if (PointsBckSeg = 0) then Error(0,'nedostatek pameti');
   GetMemory(Memory,VictoryPointsBckSeg, VictoryPointsBckOfs);
   if (VictoryPointsBckSeg = 0) then Error(0,'nedostatek pameti');

   { * PRO OBRAZKY 128x128 * }
   for I:=0 to 11 do with (Pictures128[I]) do begin { obrazky 128x128 }
     GetMemory(LongInt(128)*128+4,S,O);
     Max:=0; { max. pouzita faze }
   end;


   if (Tag) then SetGrModeVariables(False,False)
   else begin
       case (XResolution) of
          640 : begin
                  XTable:=470; YTable:=20;
                  XBeginMission:=470; YBeginMission:=100;
                  XSingle:=470; YSingle:=180;
                  XPokracovat:=470; YPokracovat:=260;
                  XLoadGlobal:=470; YLoadGlobal:=340;
                  XKonec:=470; YKonec:=420;
                  {xxx}
                  with (AnimRec) do begin
                     X1:=5; Y1:=70; X2:=464; Y2:=439;
                  end;
                  {xxx}
                end;
          800 : begin
                  XTable:=555; YTable:=65;
                  XBeginMission:=555; YBeginMission:=155;
                  XSingle:=555; YSingle:=245;
                  XPokracovat:=555; YPokracovat:=335;
                  XLoadGlobal:=555; YLoadGlobal:=425;
                  XKonec:=555; YKonec:=515;
                  {xxx}
                  with (AnimRec) do begin
                     X1:=90; Y1:=120; X2:=549; Y2:=489;
                  end;
                  {xxx}
                end;
          1024: begin
                end;
          1280: begin
                end;
       end;
   end;

   CursorOn;{}
end;

{ ***** }
procedure ShowInfoPanel(X,Y,X2,Y2:Word; Tag:Byte);
{ procedura zobrazi informacni panel
  Tag = 0 .. klasicke pozadi
      = 1 .. pozadi je bitmapa
}
var I,J:Word;
    Color:Byte;
begin
   XInfoPanel:=X; YInfoPanel:=Y;
   CursorOff; ScreenOff;
   GetImage(X,Y,X2,Y2,Win1BckSeg,Win1BckOfs,NormalDirect);
   case (Tag) of
     0 : SpecMenuRectangle(X+2,Y+2,X2-2,Y2-2);
     1 : begin
            XPutImage(X+2,Y+2,X2-2-(X+2)+1,Y2-2-(Y+2)+1,SBack,OBack);
         end;
   end;
   Frame(X+1,Y+1,X2-1,Y2-1,66);
   Frame(X,Y,X2,Y2,70);
   ScreenOn; CursorOn;
end;

{ ***** }
procedure ShowInfoPanel2(X,Y,X2,Y2:Word; Tag:Byte);
{ procedura zobrazi informacni panel s cernym pozadim;
  uzavira se CloseInfoPanel. Nelze soucasne kombinovat s ShowInfoPanel !!
  Tag = 0 .. klasicke pozadi
      = 1 .. pozadi je bitmapa
}
var I,J:Word;
    Color:Byte;
begin
   XInfoPanel:=X; YInfoPanel:=Y;
   CursorOff; ScreenOff;
   GetImage(X,Y,X2,Y2,Win1BckSeg,Win1BckOfs,NormalDirect);
   case (Tag) of
     0 : Rectangle(X+2,Y+2,X2-2,Y2-2,0);
     1 : begin
            XPutImage(X+2,Y+2,X2-2-(X+2)+1,Y2-2-(Y+2)+1,SBack,OBack);
         end;
   end;
   Frame(X+1,Y+1,X2-1,Y2-1,66);
   Frame(X,Y,X2,Y2,70);
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

{ ***** }
procedure AnimationInit(var AnimRec:TAnimRec);
{ animuje text na obrazovce
}
var Size:LongInt;
    I,J,Sg,Os:Word;
    Uk:^Word;
    U:^Byte;
begin
  with (AnimRec) do begin
    EMS_line_adding:=512;

    Size:=LongInt(EMS_line_adding)*(LongInt(Y2-Y1+1)+2*YFontSize+2)+65535;
    GetMemory(Size,S,O);
    if (S = 0) then Error(0,'NEDOSTATEK GLOBALNI PAMETI');
    if (O <> 0) then begin
      O:=0; Inc(S,SelectorInc);
    end;
    if (Size < 65000) then Speed:=True else Speed:=False;

    { alokovani pameti pro predlohy textu }
    for I:=0 to MaxAnimTextRows-1 do begin
       Size:=60*XFontSize*YFontSize+4;
       GetMemory(Size,AnimTextMem[I].S,AnimTextMem[I].O);
       if (S = 0) then Error(0,'NEDOSTATEK GLOBALNI PAMETI');
       Sg:=S; Os:=O;
       for J:=0 to Size-1 do begin
         U:=Ptr(Sg,Os); U^:=0; Inc(Os);
       end;
    end;
    XFirstPos:=3; YFirstPos:=Y2-Y1{+YFontSize{};
  end;
end;

{ ***** }
procedure Animation(var AnimRec:TAnimRec);
{ animuje text na obrazovce
}
var I,X,Y,YYY,YY,YSize:Integer;
    Mous:Boolean;
begin
  with (AnimRec) do begin
    PutImageMem(0,YFontSize,SMissionScreen,OMissionScreen,S,O);{}

    X:=XFirstPos; Y:=YFirstPos;
    Dec(YFirstPos,YAnimAdd);

    for I:=0 to JTextSize do begin
       if ((Y > 0) and (Y <= (Y2-Y1+YFontSize))) then begin
         PutImageMem2(X,Y,AnimTextMem[I].S,AnimTextMem[I].O,S,O);
       end;

       Inc(Y,YFontSize); Inc(Y,YRowAdd);
    end;

    if (Y < YFontSize) then begin { nova runda }
      YFirstPos:=Y2-Y1+YFontSize;
    end;

    { nyni souradnice na obrazovce }
    if (YFirstPos < YFontSize) then YY:=Y1 else YY:=Y1+YFirstPos-YFontSize;
    YSize:=(JTextSize+1)*(YFontSize+YRowAdd)+YAnimAdd;
    if ((YY+YSize) > Y2) then YSize:=Y2-YY+1;
    { a nyni pocatek prenasene pameti }
    if (YFirstPos < YFontSize) then YYY:=YFontSize
    else YYY:=YFirstPos;

    Mous:=TestMouse(X1,YY,X2{-X1+1},YY+YSize);
    if (Mous) then CursorOff;
    Transfer(0,YYY,X1,YY,X2-X1+1,YSize,S,O);
    if (Mous) then CursorOn;
  end;
end;

{ ****** }
procedure OpenMapCfgFile(Way:String);
{
}
begin
   MapCfgFileWay:=Way; InvalidateCache; Assign(MapCfgFile,Way);

   if (InternalCache) then begin
     IO_Result:=CacheFetch(Way);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + +MapCfgFileWay);
   end else begin
     Reset(MapCfgFile,1); IO_Result:=IOResult;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + +MapCfgFileWay);
   end;
end;

{ ****** }
procedure ReadString(var Ret:String);
{
}
begin
   Ret:='';
   while (Ord(Character) in Ws) do begin
     CacheBlockRead(MapCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapCfgFileWay);
   end;

   repeat
     Ret:=Ret+Character;
     CacheBlockRead(MapCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapCfgFileWay);
   until (Ord(Character) in Ws);
end;

{ ****** }
procedure ReadWord(var Num:Word);
{
}
begin
   Num:=0;
   while (not (Character in ['0'..'9'])) do begin
     CacheBlockRead(MapCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapCfgFileWay);
   end;

   repeat
     Num:=Num*10+(Ord(Character)-Ord('0'));
     CacheBlockRead(MapCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapCfgFileWay);
   until (not (Character in ['0'..'9']));
end;

{ ***** }
procedure Load_cfg(Way:String);
{ nahraje konfiguracni data
}
var Ret:String;
    ReinfoTyp,I,J,A,B,P,E,X,Num,Race,RndFact,Typ,Rank,TGNum:Word;
    Temp:Word;
    Time:LongInt;
    Ok,Core:Boolean;
begin
   OpenMapCfgFile(Way);
   { vycentrovani obrazovky }
   ReadString(Ret);
   ReadWord(Temp); ReadWord(Temp);
   { nejprve zdroje ras: RASAx BP= xxx PL = xxx EE= xxx Exp= xxx }
   for I:=0 to MaxRace do begin
      ReadString(Ret);
      ReadString(Ret); ReadWord(Temp);
      ReadString(Ret); ReadWord(Temp);
      ReadString(Ret); ReadWord(Temp);
      ReadString(Ret); ReadWord(Temp);
      ReadString(Ret); ReadWord(Temp);
      ReadString(Ret); ReadWord(Temp);
   end;

   for I:=1 to MaxTypesOfUnits do begin
     MyUnitsForMission[I]:=False;
     OtherUnitsForMission[I]:=False;
   end;
   for I:=1 to MaxTypesOfBuildings do begin
     BuildingsForMission[I]:=False;
   end;

   { nyni definujeme cisla jednotek, ktere je mozne vyrabet }
   for I:=0 to MaxRace do begin
      { nejprve jednotky }
      ReadString(Ret);
      ReadWord(Num); J:=1;
      while (Num <> 255) do begin
        if (I = 0) then MyUnitsForMission[Num]:=True
        else OtherUnitsForMission[Num]:=True;
        ReadWord(Num); Inc(J);
      end;
      { nyni budovy }
      ReadString(Ret);
      ReadWord(Num); J:=1;
      while (Num <> 255) do begin
        BuildingsForMission[Num]:=True;
        ReadWord(Num); Inc(J);
      end;{}
   end;
end;

{ ***** }
procedure LoadMissionData;
{ nahraje vsechna data, vztahujici se k dane misi
  cislo mise se vztahuje k MissionNameString
}
var Uk:^Word;
    Ret:String;
    I:Word;
begin
  Get_units_data;
  { ***** }
  with (AnimRec) do begin
     ITextSize:=58; JTextSize:=15; { velikost datoveho pole }
     OpenMapTxtFile(PathStr+'missions\mapa'+MissionNameString+'.inf');
     ReadTxtString(Ret); { prvni radek je komentar }
     ReadTxtString(Ret); { druhy radek je komentar }
     { nasleduji 2 wordy velikosti}
     ReadTxtWord(ITextSize); ReadTxtWord(JTextSize); Dec(JTextSize);{}
     I:=0;
     while ReadTxtString(AnimText[I]) do begin
       Uk:=Ptr(AnimTextMem[I].S,AnimTextMem[I].O);
       if (Length(AnimText[I]) = 0) then Uk^:=0 else Uk^:=(Length(AnimText[I]))*XFontSize+1;
       Inc(AnimTextMem[I].O,2);
       Uk:=Ptr(AnimTextMem[I].S,AnimTextMem[I].O); Uk^:=YFontSize-1;
       Inc(AnimTextMem[I].O,2);
       OutTextColorMem(AnimTextMem[I].S,AnimTextMem[I].O,(Length(AnimText[I])*XFontSize+2),64,AnimText[I]);
       Dec(AnimTextMem[I].O,4);
       {PutImage2(0,30,AnimTextMem[I].S,AnimTextMem[I].O,NormalDirect);{}
       Inc(I);
     end;{}

     SpaceBetweenRows:=4;
  end;

  OpenImage(PathStr+'missions\mapa'+MissionNameString+'.bmp',NoCreateNew);
  if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\missions\mapa'+MissionNameString+'.bmp');
  LoadImageBMP(SMissionScreen, OMissionScreen,NoRGB);
  if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\missions\mapa'+MissionNameString+'.bmp');
  {//}
  CursorOff;
  with (AnimRec) do begin
    PutImage(X1,Y1,SMissionScreen,OMissionScreen, ReverseDirect);
    GetImage(X1,Y1,X2,Y2,SMissionScreen,OMissionScreen,NormalDirect);
{    Frame2(X1-1,Y1-1,X2+1,Y2+1,70);
    Frame2(X1-2,Y1-2,X2+2,Y2+2,74);{}
  end;
  CursorOn;

  { nyni nahrani povolene vyroby v misi }
  Load_cfg(PathStr+'missions\mapa'+MissionNameString+'.cfg');
end;

{ ***** }
procedure CreateMenuRozliseni;
{ vytvori obrazovku s prvnim menu
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   GetMaxRes(MaxRes);
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*(MaxRes+1) <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*(MaxRes+1)) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 4 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-10*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'ROZLIgENe:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+10*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_640x480); ButtonText(_640x480,TextColor,'640 x 480');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_800x600); ButtonText(_800x600,TextColor,'800 x 600');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_1024x768); ButtonText(_1024x768,TextColor,'1024 x 768');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_1200x1024); ButtonText(_1200x1024,TextColor,'1280 x 1024');

   if (MaxRes >= 0) then Release(_640x480);
   if (MaxRes >= 1) then Release(_800x600);
   if (MaxRes >= 2) then Release(_1024x768);
   if (MaxRes >= 3) then Release(_1200x1024);
   if (MaxRes >= 0) then SetActive(_640x480);
   if (MaxRes >= 1) then SetActive(_800x600);
   if (MaxRes >= 2) then SetActive(_1024x768);
   if (MaxRes >= 3) then SetActive(_1200x1024);
   CursorOff;
   if (XResolution = 640) then ButtonFrame(_640x480,64)
   else
     if (XResolution = 800) then ButtonFrame(_800x600,64)
     else
       if (XResolution = 1024) then ButtonFrame(_1024x768,64)
       else
         if (XResolution = 1280) then ButtonFrame(_1200x1024,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _640x480   : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         XResolution:=640; YResolution:=480;
                         SetGrModeVariables(False,False);
                         LoadMissionData;
                         DrawPoints; { /// }
                         DrawVictoryPoints; { /// }
                         if (GlobalSelectedResearch > 0) then begin
                             Draw_active_research(GlobalSelectedResearch,
                                                  Research^[GlobalSelectedResearch].PercState,
                                                  True);
                         end;
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                      end;
         _800x600   : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         XResolution:=800; YResolution:=600;
                         SetGrModeVariables(False,False);
                         LoadMissionData;
                         DrawPoints; { /// }
                         DrawVictoryPoints; { /// }
                         if (GlobalSelectedResearch > 0) then begin
                             Draw_active_research(GlobalSelectedResearch,
                                                  Research^[GlobalSelectedResearch].PercState,
                                                  True);
                         end;
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                      end;
         _1024x768  : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         XResolution:=1024; YResolution:=768;
                         SetGrModeVariables(False,False);
                         LoadMissionData;
                         DrawPoints; { /// }
                         DrawVictoryPoints; { /// }
                         if (GlobalSelectedResearch > 0) then begin
                             Draw_active_research(GlobalSelectedResearch,
                                                  Research^[GlobalSelectedResearch].PercState,
                                                  True);
                         end;
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                      end;
         _1200x1024 : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         XResolution:=1280; YResolution:=1024;
                         SetGrModeVariables(False,False);
                         LoadMissionData;
                         DrawPoints; { /// }
                         DrawVictoryPoints; { /// }
                         if (GlobalSelectedResearch > 0) then begin
                             Draw_active_research(GlobalSelectedResearch,
                                                  Research^[GlobalSelectedResearch].PercState,
                                                  True);
                         end;
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                      end;
      end;
   end;
   SaveGameCfg;
   DeleteButton(_640x480,256); DeleteButton(_800x600,256); DeleteButton(_1024x768,256);
   DeleteButton(_1200x1024,256);
end;

{ ***** }
procedure SetGameDifficulty;
{ vytvori obrazovku s prvnim menu
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   Scan:=0;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*5 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*5) shr 1+Scan
   else YAdd:=0;
   { !!!!!!!!!! pozn. 5 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
{   GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);{}
Again:
   CursorOff;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-14*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'OBTekNOST HRY:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+14*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp1); ButtonText(_Temp1,TextColor,'DdTSKa');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp2); ButtonText(_Temp2,TextColor,'NeZKa');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp3); ButtonText(_Temp3,TextColor,'TcMdf NORMaLNe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp4); ButtonText(_Temp4,TextColor,'NORMaLNe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp5); ButtonText(_Temp5,TextColor,'VYSOKa');
   Release(_Temp1); Release(_Temp2); Release(_Temp3); Release(_Temp4); Release(_Temp5);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3); SetActive(_Temp4); SetActive(_Temp5);
   if (_GameLevel = 0) then ButtonFrame(_Temp1,64)
   else
     if (_GameLevel = 1) then ButtonFrame(_Temp2,64)
     else
       if (_GameLevel = 2) then ButtonFrame(_Temp3,64)
       else
         if (_GameLevel = 3) then ButtonFrame(_Temp4,64)
         else ButtonFrame(_Temp5,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin { * detska * }
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.GameLevel:=0;
                         _GameLevel:=0;
                      end;
         _Temp2     : begin { * velmi nizka * }
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.GameLevel:=1;
                         _GameLevel:=1;
                      end;
         _Temp3     : begin { * temer normalni * }
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.GameLevel:=2;
                         _GameLevel:=2;
                      end;
         _Temp4      : begin { * normalni * }
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.GameLevel:=3;
                         _GameLevel:=3;
                       end;
         _Temp5      : begin { * vysoka * }
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.GameLevel:=4;
                         _GameLevel:=4;
                       end;
      end;
   end;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256); DeleteButton(_Temp5,256);
end;

{ ***** }
procedure SetActionLevel;
{ vytvori obrazovku s prvnim menu
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   Scan:=0;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*5 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*5) shr 1+Scan
   else YAdd:=0;
   { !!!!!!!!!! pozn. 5 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
{   GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);{}
Again:
   CursorOff;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-11*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'AKbNOST HRY:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+11*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp3); ButtonText(_Temp3,TextColor,'AKbNd-STRATEGICKa');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp4); ButtonText(_Temp4,TextColor,'STRATEGICKa POMALa');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp5); ButtonText(_Temp5,TextColor,'STRATEGICKa');
   Inc(Y,BigButtonYSize+YFontSize);
   Release(_Temp3); Release(_Temp4); Release(_Temp5);
   SetActive(_Temp3); SetActive(_Temp4); SetActive(_Temp5);
   if (GlobalModify.ActionLevel = 2) then ButtonFrame(_Temp3,64)
   else
     if (GlobalModify.ActionLevel = 3) then ButtonFrame(_Temp4,64)
     else ButtonFrame(_Temp5,64);

   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp3      : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.ActionLevel:=2;
                       end;
         _Temp4      : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.ActionLevel:=3;
                       end;
         _Temp5      : begin
                         SoundPlay(0,0,0,0);
                         Konec:=True;{}
                         GlobalModify.ActionLevel:=4;
                       end;
      end;
   end;
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256); DeleteButton(_Temp5,256);
end;

{ ***** }
procedure CreateMenu;
{ vytvori obrazovku s prvnim menu
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   Scan:=0;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*5 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*5) shr 1+Scan
   else YAdd:=0;
   { !!!!!!!!!! pozn. 5 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,TempSeg2,TempOfs2,NormalDirect);{}
Again:
   CursorOff;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-10*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'VOLBY HRY:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+10*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp1); ButtonText(_Temp1,TextColor,'GRAFIKA');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp2); ButtonText(_Temp2,TextColor,'OBTekNOST HRY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp3); ButtonText(_Temp3,TextColor,'AKbNOST HRY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp4); ButtonText(_Temp4,TextColor,'??');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,0,0,False,_Temp5); ButtonText(_Temp5,TextColor,'ZPdT');
   Inc(Y,BigButtonYSize+YFontSize);
   Release(_Temp1); Release(_Temp2); Release(_Temp3); Release(_Temp4);
   Release(_Temp5);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3);
   SetActive(_Temp4); SetActive(_Temp5);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin { * grafika * }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256);
                         {Konec:=True;{}
                         CreateMenuRozliseni;
                         GoTo Again;
                      end;
         _Temp2      : begin { * obtiznost hry * }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256);
                         SetGameDifficulty;
                         {Konec:=True;{}
                         GoTo Again;
                       end;
         _Temp3      : begin { * akcnost hry * }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256);
                         SetActionLevel;
                         {Konec:=True;{}
                         GoTo Again;
                       end;
         _Temp4      : begin { * empty * }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256);
                         {Konec:=True;{}
                         GoTo Again;
                      end;
         _Temp5      : begin { * konec * }
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                         {Exec('c:\vc.com','');{}
                      end;
      end;
   end;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   DeleteButton(_Temp5,256);
end;

{ ***** }
procedure MenuOptions;
{ umozni volit z menu
}
var X,Y,X1,Y1:Word;
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
   CreateMenu;
   { ukonceni menu }
   X:=(XResolution-XWindow1Size) shr 1{}; Y:=(YResolution-YWindow1Size) shr 1{};
   CursorOff;
   PutImage2(X,Y,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;
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
function SelectPlayerId:Boolean;
{ inicializacni obrazovka
}
var Num:Word;
    X,Y,Button,Scan,Ascii:Word;
    Konec:Boolean;
    Names:array[0..3] of String[15];
begin
   SetPasive(_Temp6,256);
   SelectPlayerId:=True;
   Assign(IOFile,PathStr+'save\hrac1\name'); Reset(IOFile,1); DResult:=IOResult;
   {x}BlockRead(IOFile,Names[0],SizeOf(Names[0])); DResult:=IOResult;
   if (DResult <> 0) then Names[0]:='HRab1'; Close(IOFile); DResult:=IOResult;
   Assign(IOFile,PathStr+'save\hrac2\name'); Reset(IOFile,1); DResult:=IOResult;
   {x}BlockRead(IOFile,Names[1],SizeOf(Names[1])); DResult:=IOResult;
   if (DResult <> 0) then Names[1]:='HRab2'; Close(IOFile); DResult:=IOResult;
   Assign(IOFile,PathStr+'save\hrac3\name'); Reset(IOFile,1); DResult:=IOResult;
   {x}BlockRead(IOFile,Names[2],SizeOf(Names[2])); DResult:=IOResult;
   if (DResult <> 0) then Names[2]:='HRab3'; Close(IOFile); DResult:=IOResult;
   Assign(IOFile,PathStr+'save\hrac4\name'); Reset(IOFile,1); DResult:=IOResult;
   {x}BlockRead(IOFile,Names[3],SizeOf(Names[3])); DResult:=IOResult;
   if (DResult <> 0) then Names[3]:='HRab4'; Close(IOFile); DResult:=IOResult;

   Scan:=0; CursorOff; ClearScreen;
   CreateButton(XBeginMission,YBeginMission,0,0,False,_Temp1); ButtonText(_Temp1,TextColor,Names[0]);
   CreateButton(XSingle,YSingle,0,0,False,_Temp2); ButtonText(_Temp2,TextColor,Names[1]);
   CreateButton(XPokracovat,YPokracovat,0,0,False,_Temp3); ButtonText(_Temp3,TextColor,Names[2]);
   CreateButton(XLoadGlobal,YLoadGlobal,0,0,False,_Temp4); ButtonText(_Temp4,TextColor,Names[3]);
   CreateButton(XKonec,YKonec,0,0,False,_Temp5); ButtonText(_Temp5,TextColor,'ZPdT');
   Release(_Temp1); Release(_Temp2); Release(_Temp3); Release(_Temp4); Release(_Temp5);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3); SetActive(_Temp4); SetActive(_Temp5);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         _Temp1     : begin {}
                         SoundPlay(0,0,0,0);
                         PlayerId:='HRAC1';
                         PlayerName:=Names[0];
                         Konec:=True;{}
                      end;
         _Temp2      : begin {}
                         SoundPlay(0,0,0,0);
                         PlayerId:='HRAC2';
                         PlayerName:=Names[1];
                         Konec:=True;{}
                       end;
         _Temp3      : begin {}
                         SoundPlay(0,0,0,0);
                         PlayerId:='HRAC3';
                         PlayerName:=Names[2];
                         Konec:=True;{}
                       end;
         _Temp4      : begin {}
                         SoundPlay(0,0,0,0);
                         PlayerId:='HRAC4';
                         PlayerName:=Names[3];
                         Konec:=True;{}
                       end;
         _Temp5      : begin {}
                         SoundPlay(0,0,0,0);
                         PlayerId:='';
                         SelectPlayerId:=False;
                         Konec:=True;{}
                       end;
      end;
   end;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   DeleteButton(_Temp5,256);
end;

{ ***** }
function SelectGameSlot(OnlyActive:Boolean):Boolean;
{ inicializacni obrazovka
  pro OnlyActive da nabidku tech slotu, kam uz se zapisovalo

  vraci True, pokud byl vyber v poradku
}
label Kanec;
var Num:Word;
    X,Y,X1,Y1,Button,Scan,Ascii:Word;
    Konec:Boolean;
    Name1, Name2, Name3, Name4, Ret:String;
    dt:DateTime;
    fTime:LongInt;
begin

   Name1:=''; Name2:=''; Name3:=''; Name4:=''; SelectGameSlot:=True;
   {*}
   Assign(IOFile,PathStr+'save\'+PlayerId+'\global1');
   Reset(IOFile,1); DResult:=IOResult;
   if (DResult = 0)   then begin
     GetFTime(IOFile,fTime); DResult:=IOResult;
     if (DResult = 0) then begin
       UnpackTime(ftime,dt);
       Str(dt.Day,Ret); Name1:=Name1+Ret+'.'; Str(dt.Month,Ret);Name1:=Name1+Ret+'.';
       Str(dt.Year,Ret);Name1:=Name1+Ret+', ';Str(dt.Hour:2,Ret); Name1:=Name1+Ret+':';
       Str(dt.Min,Ret);
       if (Length(Ret) = 1) then Name1:=Name1+'0'+Ret+':' else Name1:=Name1+Ret+':';
       Str(dt.Sec,Ret);
       if (Length(Ret) = 1) then Name1:=Name1+'0'+Ret else Name1:=Name1+Ret;
     end;
   end else ;
   Close(IOFile); DResult:=IOResult;
   {*}
   Assign(IOFile,PathStr+'save\'+PlayerId+'\global2');
   Reset(IOFile,1); DResult:=IOResult;
   if (DResult = 0)   then begin
     GetFTime(IOFile,fTime); DResult:=IOResult;
     if (DResult = 0) then begin
       UnpackTime(ftime,dt);
       Str(dt.Day,Ret); Name2:=Name2+Ret+'.'; Str(dt.Month,Ret);Name2:=Name2+Ret+'.';
       Str(dt.Year,Ret);Name2:=Name2+Ret+', ';Str(dt.Hour:2,Ret); Name2:=Name2+Ret+':';
       Str(dt.Min:2,Ret);
       if (Length(Ret) = 1) then Name2:=Name2+'0'+Ret+':' else Name2:=Name2+Ret+':';
       Str(dt.Sec:2,Ret);
       if (Length(Ret) = 1) then Name2:=Name2+'0'+Ret else Name2:=Name2+Ret;
     end;
   end else ;
   Close(IOFile); DResult:=IOResult;
   {*}
   Assign(IOFile,PathStr+'save\'+PlayerId+'\global3');
   Reset(IOFile,1); DResult:=IOResult;
   if (DResult = 0)   then begin
     GetFTime(IOFile,fTime); DResult:=IOResult;
     if (DResult = 0) then begin
       UnpackTime(ftime,dt);
       Str(dt.Day,Ret); Name3:=Name3+Ret+'.'; Str(dt.Month,Ret);Name3:=Name3+Ret+'.';
       Str(dt.Year,Ret);Name3:=Name3+Ret+', ';Str(dt.Hour:2,Ret); Name3:=Name3+Ret+':';
       Str(dt.Min:2,Ret);
       if (Length(Ret) = 1) then Name3:=Name1+'0'+Ret+':' else Name3:=Name3+Ret+':';
       Str(dt.Sec:2,Ret);
       if (Length(Ret) = 1) then Name3:=Name1+'0'+Ret else Name3:=Name3+Ret;
     end;
   end else ;
   Close(IOFile); DResult:=IOResult;
   {*}
   Assign(IOFile,PathStr+'save\'+PlayerId+'\global4');
   Reset(IOFile,1); DResult:=IOResult;
   if (DResult = 0)   then begin
     GetFTime(IOFile,fTime); DResult:=IOResult;
     if (DResult = 0) then begin
       UnpackTime(ftime,dt);
       Str(dt.Day,Ret); Name4:=Name4+Ret+'.'; Str(dt.Month,Ret);Name4:=Name4+Ret+'.';
       Str(dt.Year,Ret);Name4:=Name4+Ret+', ';Str(dt.Hour:2,Ret); Name4:=Name4+Ret+':';
       Str(dt.Min:2,Ret);
       if (Length(Ret) = 1) then Name1:=Name4+'0'+Ret+':' else Name4:=Name4+Ret+':';
       Str(dt.Sec:2,Ret);
       if (Length(Ret) = 1) then Name1:=Name4+'0'+Ret else Name4:=Name4+Ret;
     end;
   end else ;
   Close(IOFile); DResult:=IOResult;

   if (OnlyActive and (Name1 = '') and (Name2 = '') and (Name3 = '') and (Name4 = ''))
   then begin SelectGameSlot:=False; GoTo Kanec; end;
   if ((Name1 = '') and (not OnlyActive)) then Name1:='NEPOUkITO';
   if ((Name2 = '') and (not OnlyActive)) then Name2:='NEPOUkITO';
   if ((Name3 = '') and (not OnlyActive)) then Name3:='NEPOUkITO';
   if ((Name4 = '') and (not OnlyActive)) then Name4:='NEPOUkITO';

   {***}
   Scan:=0;
   X:=(XResolution-2*BigButtonXSize) shr 1;
   Y:=(YResolution-4*BigButtonYSize-5*30) shr 1;
   X1:=X+BigButtonXSize shr 1; Y1:=Y+30;
   CursorOff;
   if ((not OnlyActive) or (Name1 <> '')) then begin
     CreateButton(X1,Y1,0,0,False,_Temp1); ButtonText(_Temp1,TextColor,Name1);
     Inc(Y1,30+BigButtonYSize);
   end;
   if ((not OnlyActive) or (Name2 <> '')) then begin
     CreateButton(X1,Y1,0,0,False,_Temp2); ButtonText(_Temp2,TextColor,Name2);
     Inc(Y1,30+BigButtonYSize);
   end;
   if ((not OnlyActive) or (Name3 <> '')) then begin
     CreateButton(X1,Y1,0,0,False,_Temp3); ButtonText(_Temp3,TextColor,Name3);
     Inc(Y1,30+BigButtonYSize);
   end;
   if ((not OnlyActive) or (Name4 <> '')) then begin
     CreateButton(X1,Y1,0,0,False,_Temp4); ButtonText(_Temp4,TextColor,Name4);
     Inc(Y1,30+BigButtonYSize);
   end;
   ShowInfoPanel2(X,Y,X+2*BigButtonXSize-1,Y1,0);
   Release(_Temp1); Release(_Temp2); Release(_Temp3); Release(_Temp4);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3); SetActive(_Temp4);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then begin
                        SoundPlay(0,0,0,0);
                        SelectGameSlot:=False;
                        Konec:=True;{}
                      end;
         _Temp1     : begin {}
                         SoundPlay(0,0,0,0);
                         SaveSlotId:='global1';
                         Konec:=True;{}
                      end;
         _Temp2      : begin {}
                         SoundPlay(0,0,0,0);
                         SaveSlotId:='global2';
                         Konec:=True;{}
                       end;
         _Temp3      : begin {}
                         SoundPlay(0,0,0,0);
                         SaveSlotId:='global3';
                         Konec:=True;{}
                       end;
         _Temp4      : begin {}
                         SoundPlay(0,0,0,0);
                         SaveSlotId:='global4';
                         Konec:=True;{}
                       end;
      end;
   end;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   CloseInfoPanel;
Kanec:
end;

{ ***** }
procedure SaveScreen;
{
}
label Konec;
const ScreenShot = True;
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
         Ret:=PathStr+'scrshots/glob'+Ret+'.bmp';
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
function InitScreen:Word;
{ inicializacni obrazovka
}
label Again;
var Num:Word;
    X,Y,Button,Scan,Ascii,XSize,YSize:Word;
    Konec:Boolean;
    Ret:String[15];
begin
   { vlastni vytvoreni }
   SetPasive(ResearchButton,256);
   SetPasive(ResearchButton,256);
   SetPasive(DalsiTydenButton,256);
   SetPasive(CoreButton,256);
   SetPasive(InfoButton,256);
   SetPasive(OptionButton,256);
   SetPasive(SaveButton,256);
   SetPasive(LoadButton,256);
   SetPasive(EndButton,256);
   SetPasive(StartButton,256);
Again:
   Scan:=0;
   CursorOff;
   ClearScreen;
   OpenImage(PathStrGlobal+'data\intro.bmp',NoCreateNew);
   if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani intro.bmp'); end;
   GetXYImageCoordinatesBMP(XSize,YSize);
   if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani intro.bmp'); end;
   LoadImageBMP(SScreen,OScreen,NoRGB);
   if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani intro.bmp'); end;
   PutImage((XResolution-XSize) shr 1,(YResolution-YSize) shr 1,SScreen,OScreen,ReverseDirect);
   {*}
   CreateButton(XBeginMission,YBeginMission,0,0,False,_Temp1); ButtonText(_Temp1,TextColor,'OSN ZASAHUJE');
   CreateButton(XSingle,YSingle,0,0,False,_Temp2); ButtonText(_Temp2,TextColor,'SAMOSTATNa MISE');
   CreateButton(XPokracovat,YPokracovat,0,0,False,_Temp3); ButtonText(_Temp3,TextColor,'POKRAbOVAT');
   CreateButton(XLoadGlobal,YLoadGlobal,0,0,False,_Temp4); ButtonText(_Temp4,TextColor,'NAHRaT GLOBAL');
   CreateButton(XKonec,YKonec,0,0,False,_Temp5); ButtonText(_Temp5,TextColor,'KONEC');
   CreateButton(XTable,YTable,0,0,False,_Temp6); ButtonText(_Temp6,TextColor,'TABULKA hSPdCHi');
   Release(_Temp1); Release(_Temp2); Release(_Temp3); Release(_Temp4);
   Release(_Temp5); Release(_Temp6);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3); SetActive(_Temp4);
   SetActive(_Temp5); SetActive(_Temp6);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         _Temp1     : begin { nova kampan }
                         SoundPlay(0,0,0,0);
                         InitScreen:=_Temp1-_Temp1;
                         if (not SelectPlayerId) then begin
                            DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                            DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                            DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                            GoTo Again;
                         end;
                         if (DialogBox('ZaZNAMY ULOkENc NA TOMTO MeSTd SE VYMAkOU. CHCETE POKRAbOVAT?',_YES_NO) = NO)
                         then begin
                            DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                            DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                            DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                            GoTo Again;
                         end;
                         if (GetString(15,Ret)) then begin
                           Assign(IOFile,PathStr+'save\'+PlayerId+'\name');
                           ReWrite(IOFile,1); DResult:=IOResult;
                           {x}BlockWrite(IOFile,Ret,SizeOf(Ret));
                           DResult:=IOResult;if(DResult<>0)then begin Close(IOFile); Erase(IOFile);end;
                           Close(IOFile); DResult:=IOResult;
                           PlayerName:=Ret;
                         end;
                         Konec:=True;{}
                      end;
         _Temp2      : begin { single mise }
                         SoundPlay(0,0,0,0);
                         InitScreen:=_Temp2-_Temp1;
                         Konec:=True;{}
                       end;
         _Temp3      : begin { pokracovat }
                         SoundPlay(0,0,0,0);
                         InitScreen:=_Temp3-_Temp1;
                         if (not SelectPlayerId) then begin
                            DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                            DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                            DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                            GoTo Again;
                         end;
                         Konec:=True;{}
                       end;
         _Temp4      : begin { nahrat global }
                         SoundPlay(0,0,0,0);
                         InitScreen:=_Temp4-_Temp1;
                         if (not SelectPlayerId) then begin
                            DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                            DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                            DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                            GoTo Again;
                         end;
                         if (not SelectGameSlot(True))
                         then InitScreen:=_Temp1-_Temp1;
                         Konec:=True;{}
                       end;
         _Temp5      : begin { konec }
                         SoundPlay(0,0,0,0);
                         InitScreen:=_Temp5-_Temp1;
                         Konec:=True;{}
                       end;
        _Temp6      : begin { tabulka }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);
                         DrawBestTable;
                         GoTo Again;
                       end;
      end;
   end;
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);

{ ************************************************************************** }
   if (Num <> _Temp5) then begin
      InitGlobalModif;
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
end;

{ ***** }
procedure SetGrModeVariables(Light,NotInitGr:Boolean);
{ nastavi vsechny potrebne promenne pro dany graficky rezim
  Light = True pouze pro urcitou inicializaci
  NotInitGr = neprovede se"lehka" inicializace grafiky
}
var Memory:LongInt;
    Ret:String;
begin
  if (not NotInitGr) then Init_gr_mode_light(XResolution,YResolution);
  CursorOff;
  case (XResolution) of
     640 : begin
             if (not Light) then begin
                OpenImage(PathStrGlobal+'data\640.bmp',NoCreateNew);
                if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani obrazku pozadi'); end;
                LoadImageBMP(SScreen,OScreen,NoRGB);
                if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani obrazku pozadi'); end;
                PutImage(0,0,SScreen,OScreen,ReverseDirect);
                {x}
                if (CreateButton(5,22,0,0,False,ResearchButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,22,0,0,False,DalsiTydenButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,140,0,0,False,CoreButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,200,0,0,False,InfoButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,240,0,0,False,OptionButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,310,0,0,False,SaveButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,350,0,0,False,LoadButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(150,450,0,0,False,StartButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(472,440,0,0,False,EndButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');

                {xxx}
                with (AnimRec) do begin
                   X1:=2; Y1:=70; X2:=469; Y2:=439;
                end;
                {xxx}

                if (ReserchInfoBckSeg <> 0) then begin
                   PutMemory(ReserchInfoBckMemory,ReserchInfoBckSeg,ReserchInfoBckOfs);
                end;
                { informace o obdelniku, v nemz se nachazi popis aktualniho vyzkumu: }
                X1RsrchInfo:=178; Y1RsrchInfo:=8;
                X2RsrchInfo:=454; Y2RsrchInfo:=60;
                { zacatek nazvu aktualniho vyzkumu: }
                XResearchLeftTopText:=178;
                YResearchLeftTopText:=(Y2RsrchInfo-Y1RsrchInfo-YFontSize) shr 1 +
                                       Y1RsrchInfo;
                { levy horni bod prubehu aktualniho vyzkumu: }
                X1ResearchFrame:=XResearchLeftTopText+XFontSize*9+16;
                { vyska boxu je udana cislem "50": }
                Y1ResearchFrame:=(Y2RsrchInfo-Y1RsrchInfo-28) shr 1 +
                                  Y1RsrchInfo-1;
                { pravy dolni bod prubehu aktualniho vyzkumu: }
                X2ResearchFrame:=X2RsrchInfo-2;
                Y2ResearchFrame:=Y1ResearchFrame+28;

                { ulozene pozadi: }
                ReserchInfoBckMemory:=LongInt(X2RsrchInfo-X1RsrchInfo+1)*
                                      (Y2RsrchInfo-Y1RsrchInfo+1)+4;
                GetMemory(ReserchInfoBckMemory,ReserchInfoBckSeg,ReserchInfoBckOfs);
                if (ReserchInfoBckMemory < 65000) then
                 GetImage(X1RsrchInfo,Y1RsrchInfo,X2RsrchInfo,Y2RsrchInfo,
                          ReserchInfoBckSeg,ReserchInfoBckOfs,NormalDirect)
                else
                  GetImage(X1RsrchInfo,Y1RsrchInfo,X2RsrchInfo,Y2RsrchInfo,
                           ReserchInfoBckSeg,ReserchInfoBckOfs,NormalDirect);
             end;
             {xxx}
             X1Points:=10; Y1Points:=448;
             X1PointsInfo:=52; Y1PointsInfo:=451;
             X2PointsInfo:=140; Y2PointsInfo:=476;
             {}
             X1VictoryPoints:=326; Y1VictoryPoints:=448;
             X1VictoryPointsInfo:=368; Y1VictoryPointsInfo:=451;
             X2VictoryPointsInfo:=456; Y2VictoryPointsInfo:=476;
             {xxx}
             XTable:=470; YTable:=20;
             XBeginMission:=470; YBeginMission:=100;
             XSingle:=470; YSingle:=180;
             XPokracovat:=470; YPokracovat:=260;
             XLoadGlobal:=470; YLoadGlobal:=340;
             XKonec:=470; YKonec:=420;
             {xxx}
           end;
     800 : begin
             if (not Light) then begin
                OpenImage(PathStrGlobal+'data\800.bmp',NoCreateNew);
                if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani obrazku pozadi'); end;
                LoadImageBMP(SScreen,OScreen,NoRGB);
                if (IO_Result <> 0) then begin Error(0,'Chyba pri nahravani obrazku pozadi'); end;
                PutImage(0,0,SScreen,OScreen,ReverseDirect);
                {x}
                if (CreateButton(50,26,0,0,False,ResearchButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,80,0,0,False,DalsiTydenButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,190,0,0,False,CoreButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,250,0,0,False,InfoButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,290,0,0,False,OptionButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,360,0,0,False,SaveButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,400,0,0,False,LoadButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(245,550,0,0,False,StartButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');
                if (CreateButton(620,490,0,0,False,EndButton) <> 0) then Error(0,'Chyba pri vytvareni tlacitek');

                {xxx}
                with (AnimRec) do begin
                   X1:=86; Y1:=120; X2:=553; Y2:=489;
                end;
                {xxx}

                if (ReserchInfoBckSeg <> 0) then begin
                   PutMemory(ReserchInfoBckMemory,ReserchInfoBckSeg,ReserchInfoBckOfs);
                end;
                { informace o obdelniku, v nemz se nachazi popis aktualniho vyzkumu: }
                X1RsrchInfo:=241; Y1RsrchInfo:=8;
                X2RsrchInfo:=534; Y2RsrchInfo:=70;
                { zacatek nazvu aktualniho vyzkumu: }
                XResearchLeftTopText:=240;
                YResearchLeftTopText:=(Y2RsrchInfo-Y1RsrchInfo-YFontSize) shr 1 +
                                       Y1RsrchInfo-1;
                { levy horni bod prubehu aktualniho vyzkumu: }
                X1ResearchFrame:=XResearchLeftTopText+XFontSize*10+16;
                { vyska boxu je udana cislem "50": }
                Y1ResearchFrame:=(Y2RsrchInfo-Y1RsrchInfo-28) shr 1 +
                                  Y1RsrchInfo;
                { pravy dolni bod prubehu aktualniho vyzkumu: }
                X2ResearchFrame:=X2RsrchInfo-2;
                Y2ResearchFrame:=Y1ResearchFrame+28;

                { ulozene pozadi: }
                ReserchInfoBckMemory:=LongInt(X2RsrchInfo-X1RsrchInfo+1)*
                                      (Y2RsrchInfo-Y1RsrchInfo+1)+4;
                GetMemory(ReserchInfoBckMemory,ReserchInfoBckSeg,ReserchInfoBckOfs);
                if (ReserchInfoBckMemory < 65000) then
                  GetImage(X1RsrchInfo,Y1RsrchInfo,X2RsrchInfo,Y2RsrchInfo,
                                ReserchInfoBckSeg,ReserchInfoBckOfs,NormalDirect)
                else
                  GetImage(X1RsrchInfo,Y1RsrchInfo,X2RsrchInfo,Y2RsrchInfo,
                           ReserchInfoBckSeg,ReserchInfoBckOfs,NormalDirect);
             end;
             {xxx}
             X1Points:=50; Y1Points:=548;
             X1PointsInfo:=92; Y1PointsInfo:=551;
             X2PointsInfo:=180; Y2PointsInfo:=576;
             {}
             X1VictoryPoints:=466; Y1VictoryPoints:=548;
             X1VictoryPointsInfo:=508; Y1VictoryPointsInfo:=551;
             X2VictoryPointsInfo:=596; Y2VictoryPointsInfo:=576;
             {xxx}
             XTable:=555; YTable:=65;
             XBeginMission:=555; YBeginMission:=155;
             XSingle:=555; YSingle:=245;
             XPokracovat:=555; YPokracovat:=335;
             XLoadGlobal:=555; YLoadGlobal:=425;
             XKonec:=555; YKonec:=515;
             {xxx}
           end;
     1024: begin
           end;
     1280: begin
           end;
  end;
  SpeedGetImage(X1VictoryPointsInfo,Y1VictoryPointsInfo,
                X2VictoryPointsInfo-1,Y2VictoryPointsInfo-1,
                VictoryPointsBckSeg,VictoryPointsBckOfs);{}
  SpeedGetImage(X1PointsInfo,Y1PointsInfo,
                X2PointsInfo-1,Y2PointsInfo-1,
                PointsBckSeg,PointsBckOfs);{}
  if (not Light) then begin
     InitCoreStruct(False);
     ButtonText(ResearchButton,TextColor,'VjZKUM');
     Str(Week+1,Ret); ButtonText(DalsiTydenButton,TextColor,Ret+'. TjDEN');
     ButtonText(CoreButton,TextColor,'JaDRO');
     ButtonText(InfoButton,TextColor,'INFORMACE');
     ButtonText(OptionButton,TextColor,'VOLBY');
     ButtonText(LoadButton,TextColor,'NAHRaT');
     ButtonText(SaveButton,TextColor,'ULOkIT');
     ButtonText(EndButton,TextColor,'KONEC');
     ButtonText(StartButton,TextColor,'START MISE');
     {x}
     SetActive(ResearchButton);
     SetActive(DalsiTydenButton);
     SetActive(CoreButton);
     SetActive(InfoButton);
     SetActive(OptionButton);
     SetActive(SaveButton);
     SetActive(LoadButton);
     SetActive(EndButton);
     SetActive(StartButton);
     {x}
     Release(ResearchButton);
     Release(DalsiTydenButton);
     Release(CoreButton);
     Release(InfoButton);
     Release(OptionButton);
     Release(SaveButton);
     Release(LoadButton);
     Release(EndButton);
     Release(StartButton);
  end;

  CursorOn;
  if (not Light) then begin AssignResearchObject.Init; end;
end;

{ ************************************************************************* }
begin
end.
