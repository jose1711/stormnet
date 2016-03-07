unit Grafika3;
{$C FIXED PRELOAD PERMANENT}
interface
uses Graph257, Mouse, Data, Crt, Grafika2, Grafika, Buttons;

procedure Init_gr_data;
procedure Second_init_gr_data;
procedure LoadShots;
procedure LoadExplosions;
procedure LoadExplosions2;
procedure SetFog(IP,JP:Word; Sight:Byte; Rac:Byte; Sets:Boolean);
procedure SetFog2(IP,JP,IP2,JP2:Word; Sight:Byte; Rac:Byte; Sets:Boolean);
function Get_fog_index(I,J:Word):Byte;
procedure MaintainMsg;
procedure DebrisManager;
procedure SpecialUnitInfo;
procedure Grafika3_save;
procedure Grafika3_load;

implementation
uses _units2, _units3, _buildings;

const QBckLength = 3200;
type TQArray = array[0..QBckLength] of record
                   X,Y:Word; { souradnice kresleneho mista }
               end;
type TBckQueue = object
                private
                  Q:^TQArray;
                  FrontUk, BackUk:Word;
                public
                  procedure Insert(X,Y:Word);
                  procedure Finish;
                  function Full:Boolean;
                  procedure Init;
                  constructor Initialize;
              end;

var Queue:TBckQueue;

{ +++++ }
constructor TBckQueue.Initialize;
{}
begin
   New(Q);
end;

{ +++++ }
procedure TBckQueue.Insert(X,Y:Word);
{ vlozi do fronty prvek; kontroluje se, zda prvek ve fronte jiz neni;
  v takovem pripade se do fronty nevlozi
}
   { +++++ }
   procedure PomInsert(X,Y:Word);
   begin
      if (Full) then begin { fronta je plna }
         Error(0,'units grafika3, procedura TBckQueue.Insert - preplneni fronty');
      end;
      MapBckTemp^[X,Y].Temp:=MapBckTemp^[X,Y].Temp and 254;
      Q^[BackUk].X:=X; Q^[BackUk].Y:=Y;
      Inc(BackUk);
   end;
   { +++++ }
begin
   PomInsert(X,Y);
   if (Smooth_fog_of_war) then begin
   { zarovnany fog_of_war }
      if (X > 0) then begin
        PomInsert(X-1,Y);
        if ((Y > 0)) then PomInsert(X-1,Y-1);
        if ((Y < IMax)) then PomInsert(X-1,Y+1);
      end;
      if (X < IMax) then begin
        PomInsert(X+1,Y);
        if ((Y > 0)) then PomInsert(X+1,Y-1);
        if ((Y < IMax)) then PomInsert(X+1,Y+1);
      end;
      if ((Y > 0)) then PomInsert(X,Y-1);
      if ((Y < JMax)) then PomInsert(X,Y+1);
   end;
end;

{ +++++ }
procedure TBckQueue.Finish;
{ zlikviduje celou frontu
}
var I:Word;
begin
   I:=FrontUk;
   while (I < BackUk) do with (Q^[I]) do with (MapBckTemp^[X,Y]) do begin
     if (Temp and 1 = 0) then begin
       Temp:=Temp or 1;
       Transfer_map_frame(X,Y,X,Y);
     end;
     Inc(I);
   end;
end;

{ +++++ }
procedure TBckQueue.Init;
{
}
begin
   FrontUk:=0; BackUk:=0;
end;

{ +++++ }
function TBckQueue.Full:Boolean;
{
}
begin
   if (BackUk >= QBckLength) then Full:=True else Full:=False;
end;

{ ***** }
procedure Second_init_gr_data;
{ kvuli neschopnosti Borland Pascalu bylo nutne rozdelit proceduru
  Init_gr_data na vice casti
}
var X,Y,XPom,YPom,XPos,YPos,I,J,K,Index:Word;
    Ret:String;
begin
{ NYNI SE NAHRAJE RAMECEK OKOLO HRACI PLOCHY }
   SetCursor(WaitCursor);
   { VYTVORENI MAPY V PAMETI }
   { pozadi }
   { nyni zkontrolujeme inicializacni nastaveni okenka radaru }
   if ((IBeg+IScreenSize) > IMax) then IBeg:=IMax-IScreenSize;
   if ((JBeg+JScreenSize) > JMax) then JBeg:=JMax-JScreenSize;
   for J:=JBeg to JBeg+JScreenSize do
     for I:=IBeg to IBeg+IScreenSize do with MapBck^[I,J] do begin
        {if (Fog_of_war) then Visibilit:=0 else Visibilit:=1;{}
        Index:=BckType; Info:=255;
        X:=I shl XCellShl+XMemBeg-IBeg shl XCellShl;
        Y:=J shl YCellShl+YMemBeg-JBeg shl YCellShl;
        SpeedPutImageMem(X,Y,BackGround[Index].Segment,BackGround[Index].Offsets);
     end; {}

   for J:=0 to JMaxSize do
     for I:=0 to IMaxSize do with Map^[I,J] do begin
        First_level:=0;
        Level_type:=0;
        Second_level:=0;
        if (Fog_of_war) then MapBckTemp^[I,J].Visibilit:=0
        else MapBckTemp^[I,J].Visibilit:=1;{}
        if (Unknown_terrain and Fog_of_war) then MapBckTemp^[I,J].Temp:=0
        else MapBckTemp^[I,J].Temp:=2;
        if (Fog_of_war) then MapBckTemp^[I,J].EnemyVisibilit:=0
        else MapBckTemp^[I,J].EnemyVisibilit:=1;{}
        BuildRadar^[I,J].B:=255;
        BuildRadar^[I,J].P:=False;
     end; {}
   SetCursor(WaitCursor);

   InvalidateCache; CursorOff;
   case (XResolution) of
      640  : OpenImage('data\640x480.bmp',NoCreateNew);
      800  : OpenImage('data\800x600.bmp',NoCreateNew);
      1024 : OpenImage('data\1024x768.bmp',NoCreateNew);
      1280 : OpenImage('data\1280x1024.bmp',NoCreateNew);
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor data\obr. desktop');
   LoadImageBMP(SScreen,OScreen,NoRGB);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor data\obr. desktop');
   PutImage(0,0,SScreen,OScreen,ReverseDirect);{}
   { RAMECEK OKOLO HRACI PLOCHY NAHRAN }
   GetSlotsInfo;
   Materials_info_init;
   RadarInit;
   { vytvoreni tlacitek typu 3}
   case (XResolution) of
     640 : begin
              {SpeedPutImage2(I,J,ButtonsBckSeg, ButtonsBckOfs);{}
              I:=19; J:=383;
              CreateButton(I,J,2,1,False,Stop); Inc(I,Button3XSize+2);
              CreateButton(I,J,2,2,False,Patrol); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,3,False,Nalozit); I:=19; J:=382+Button3YSize+4;
              CreateButton(I,J,2,4,False,Vylozit); CreateButton(I,J,2,5,False,Rozlozit);
              Inc(I,Button3XSize+2);
              CreateButton(I,J,2,6,False,Opravit); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,7,False,ZvednoutMoralku);
              {x}
              CreateButton(135,3,0,0,False,MenuButton);
              CreateButton(184,3,0,0,False,StopButton);
              CreateButton(93,124,0,0,False,RadarModButton);
              CreateButton(6,124,0,0,False,SellButton);
              ButtonText(SellButton,15,'');
              ButtonText(MenuButton,15,'MENU');
              Str(GameStopCount,Ret);
              ButtonText(StopButton,15,'('+Ret+')');
              ButtonText(RadarModButton,15,'MOD');{}
           end;
     800 : begin
              I:=30; J:=504;
              CreateButton(I,J,2,1,False,Stop); Inc(I,Button3XSize+2);
              CreateButton(I,J,2,2,False,Patrol); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,3,False,Nalozit);
              I:=30; J:=504+Button3YSize+3;
              CreateButton(I,J,2,4,False,Vylozit); CreateButton(I,J,2,5,False,Rozlozit);
              Inc(I,Button3XSize+2);
              CreateButton(I,J,2,6,False,Opravit); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,7,False,ZvednoutMoralku);
              {x}
              CreateButton(164,11,0,0,False,MenuButton);
              CreateButton(213,11,0,0,False,StopButton);
              CreateButton(110,190,0,0,False,RadarModButton);
              CreateButton(12,190,0,0,False,SellButton);
              ButtonText(SellButton,15,'');
              {CreateButton(I,J,1,0,False,TabButton);{}
              ButtonText(MenuButton,15,'MENU');
              Str(GameStopCount,Ret);
              ButtonText(StopButton,15,'('+Ret+')');
              ButtonText(RadarModButton,15,'MOD');{}
           end;
     1024 : begin
              I:=32; J:=673;
              CreateButton(I,J,2,1,False,Stop); Inc(I,Button3XSize+2);
              CreateButton(I,J,2,2,False,Patrol); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,3,False,Nalozit);
              I:=32; J:=673+Button3YSize+3;
              CreateButton(I,J,2,4,False,Vylozit); CreateButton(I,J,2,5,False,Rozlozit);
              Inc(I,Button3XSize+2);
              CreateButton(I,J,2,6,False,Opravit); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,7,False,ZvednoutMoralku);
              {x}
              CreateButton(214,16,0,0,False,MenuButton);
              CreateButton(263,16,0,0,False,StopButton);
              CreateButton(110,290,0,0,False,RadarModButton);
              CreateButton(12,290,0,0,False,SellButton);
              ButtonText(SellButton,15,'');
              {CreateButton(I,J,1,0,False,TabButton);{}
              ButtonText(MenuButton,15,'MENU');
              Str(GameStopCount,Ret);
              ButtonText(StopButton,15,'('+Ret+')');
              ButtonText(RadarModButton,15,'MOD');{}
           end;
   end;

   { OPET TLACITKA }
   SetActive(MenuButton); SetActive(StopButton); SetActive(RadarModButton);
   Release(MenuButton); Release(StopButton); Release(RadarModButton);
   Release(SellButton); SetPasive(SellButton,256);
   SetPasive(Stop,256); SetPasive(Patrol,256);
   SetPasive(Nalozit,256); SetPasive(Vylozit,256);
   SetPasive(Rozlozit,256); SetPasive(Opravit,256);
   SetPasive(ZvednoutMoralku,256);

   MsgInit;
   ActiveDefenceRangeSlotsInit;
   Min_game_time:=60; Sec_game_time:=60;
   Flag_game_time:=MaxFlag_game_time;
   Print_game_time(False);
   for I:=0 to MaxRace do with (Races[I]) do
     GetRGB(RaceColor,RRGB,GRGB,BRGB);


   CursorOn;
   SetCursor(NormalCursor);
end;

{ ***** }
procedure Init_gr_data;
{ provede nahrani dat z disku do pameti
}
label For_end_1, For_end_2, For_end_3, For_end_4;
label For_end_12, For_end_22, For_end_32, For_end_42;
var Memory:LongInt;
    I,J, K, Index:Integer;
    Pom, Pom2:String[90];
    Handle_file:File;
    Add,X,Y,XPos,YPos,XPom,YPom:Word;
    Result:Word;
    Konec:Boolean;
    Ret:String;

{ XXXXX }
procedure Init_gr_data3;
{
}
label For_end_1, For_end_2;
var I,J:Word;
begin
   { *** NAHRANI JEDNOTEK DO PAMETI *** }
   { nyni probehne nahravani obrazku lidi 1 }
   { nejprve pole vynulujeme }
   for I:=1 to MaxTypesOfUnits do with Unit_pictures[I] do begin
      S1:=0; S2:=0; S3:=0; S4:=0; S5:=0; S6:=0; S7:=0; S8:=0;
      S9:=0; S10:=0; S11:=0; S12:=0; S13:=0; S14:=0; S15:=0; S16:=0;
      S17:=0; S18:=0; S19:=0; S20:=0; S21:=0; S22:=0; S23:=0; S24:=0;
      S25:=0; S26:=0; S27:=0; S28:=0; S29:=0; S30:=0; S31:=0; S32:=0;
   end;
   { dale pole naplnime }
   case (TerrainCondition) of
     Clear: OpenImage('.\data\units',NoCreateNew);
     Night: OpenImage('.\data\units.nig',NoCreateNew);
   else
     OpenImage('.\data\units',NoCreateNew);
   end;
   if (InternalCache) then begin
      case (TerrainCondition) of
        Clear: Result:=CacheFetch('.\data\units');
        Night: Result:=CacheFetch('.\data\units.nig');
      else
        Result:=CacheFetch('.\data\units');
      end;
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   J:=1;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
   for I:=1 to 20 do begin
     SetCursor(WaitCursor);
     Str(I-1,Pom);  Index:=I;
     { zjisteni existence a velikosti obrazku }
     GetXYImageCoordinatesGBM(X,Y,Pom+'_1');
     if (IO_Result = 37) then GoTo For_end_1;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
     Memory:=LongInt(X) * LongInt(Y) + 4;
     with (Unit_types[I,0]) do with (Unit_pictures[Index]) do begin
        XUnitSize:=X; YUnitSize:=Y;
        IUnitSize:=X shr XCellShl; {if (X mod XCellSize <> 0) then Inc(IUnitSize);{}
        JUnitSize:=Y shr YCellShl; {if (Y mod YCellSize <> 0) then Inc(JUnitSize);{}
        Presah:=XUnitSize-IUnitSize shl XCellShl;
        { nahrani 1. obrazku }
        GetMemory(Memory,S1,O1); if (S1 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S2,O2); if (S2 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S3,O3); if (S3 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S4,O4); if (S4 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S5,O5); if (S5 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S6,O6); if (S6 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S7,O7); if (S7 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S8,O8); if (S8 = 0) then Error(0,'Nedostatek pameti');

        LoadImageGBM(S1,O1,Pom+'_1',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S2,O2,Pom+'_2',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S3,O3,Pom+'_3',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S4,O4,Pom+'_4',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S5,O5,Pom+'_5',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S6,O6,Pom+'_6',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S7,O7,Pom+'_7',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S8,O8,Pom+'_8',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');

        MaxPhase:=2;
        { zjisti existenci dalsich  8 obrazku (1 faze) }
        GetXYImageCoordinatesGBM(X,Y,Pom+'_9');
        if (IO_Result = 37) then GoTo For_end_1;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        GetMemory(Memory,S9,O9); if (S9 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S10,O10); if (S10 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S11,O11); if (S11 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S12,O12); if (S12 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S13,O13); if (S13 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S14,O14); if (S14 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S15,O15); if (S15 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S16,O16); if (S16 = 0) then Error(0,'Nedostatek pameti');
        LoadImageGBM(S9,O9,Pom+'_9',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S10,O10,Pom+'_10',J);Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S11,O11,Pom+'_11',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S12,O12,Pom+'_12',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S13,O13,Pom+'_13',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S14,O14,Pom+'_14',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S15,O15,Pom+'_15',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S16,O16,Pom+'_16',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');{}

        MaxPhase:=4;
        { zjisti existenci dalsich  8 obrazku (1 faze) }
        GetXYImageCoordinatesGBM(X,Y,Pom+'_17');
        if (IO_Result = 37) then GoTo For_end_1;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        MaxPhase:=6;
        GetMemory(Memory,S17,O17); if (S17 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S18,O18); if (S18 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S19,O19); if (S19 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S20,O20); if (S20 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S21,O21); if (S21 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S22,O22); if (S22 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S23,O23); if (S23 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S24,O24); if (S24 = 0) then Error(0,'Nedostatek pameti');

        LoadImageGBM(S17,O17,Pom+'_17',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S18,O18,Pom+'_18',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S19,O19,Pom+'_19',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S20,O20,Pom+'_20',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S21,O21,Pom+'_21',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S22,O22,Pom+'_22',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S23,O23,Pom+'_23',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S24,O24,Pom+'_24',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');

        { zjisti existenci dalsich  8 obrazku (1 faze) }
        GetXYImageCoordinatesGBM(X,Y,Pom+'_25');
        if (IO_Result = 37) then GoTo For_end_1;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        MaxPhase:=8;
        GetMemory(Memory,S25,O25); if (S25 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S26,O26); if (S26 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S27,O27); if (S27 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S28,O28); if (S28 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S29,O29); if (S29 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S30,O30); if (S30 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S31,O31); if (S31 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S32,O32); if (S32 = 0) then Error(0,'Nedostatek pameti');

        LoadImageGBM(S25,O25,Pom+'_25',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S26,O26,Pom+'_26',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S27,O27,Pom+'_27',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S28,O28,Pom+'_28',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S29,O29,Pom+'_29',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S30,O30,Pom+'_30',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S31,O31,Pom+'_31',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
        LoadImageGBM(S32,O32,Pom+'_32',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units');
     end;
For_end_1:
   end;
   InvalidateCache;

   J:=1;
   case (TerrainCondition) of
     Clear: OpenImage('.\data\units2',NoCreateNew);
     Night: OpenImage('.\data\units2.nig',NoCreateNew);
   else
     OpenImage('.\data\units2',NoCreateNew);
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
   if (InternalCache) then begin
      case (TerrainCondition) of
        Clear: Result:=CacheFetch('.\data\units2');
        Night: Result:=CacheFetch('.\data\units2.nig');
      else
        Result:=CacheFetch('.\data\units2');
      end;
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   for I:=21 to MaxTypesOfUnits do begin
     SetCursor(WaitCursor);
     Str(I-1,Pom);  Index:=I;
     { zjisteni existence a velikosti obrazku }
     GetXYImageCoordinatesGBM(X,Y,Pom+'_1');
     if (IO_Result = 37) then GoTo For_end_2;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
     Memory:=LongInt(X) * LongInt(Y) + 4;
     with (Unit_types[I,0]) do with (Unit_pictures[Index]) do begin
        XUnitSize:=X; YUnitSize:=Y;
        IUnitSize:=X shr XCellShl; {if (X mod XCellSize <> 0) then Inc(IUnitSize);{}
        JUnitSize:=Y shr YCellShl; {if (Y mod YCellSize <> 0) then Inc(JUnitSize);{}
        Presah:=XUnitSize-IUnitSize shl XCellShl;

        { nahrani 1. obrazku }
        GetMemory(Memory,S1,O1); if (S1 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S2,O2); if (S2 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S3,O3); if (S3 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S4,O4); if (S4 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S5,O5); if (S5 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S6,O6); if (S6 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S7,O7); if (S7 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S8,O8); if (S8 = 0) then Error(0,'Nedostatek pameti');
        LoadImageGBM(S1,O1,Pom+'_1',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S2,O2,Pom+'_2',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S3,O3,Pom+'_3',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S4,O4,Pom+'_4',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S5,O5,Pom+'_5',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S6,O6,Pom+'_6',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S7,O7,Pom+'_7',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S8,O8,Pom+'_8',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');

        MaxPhase:=2;
        { zjisti existenci dalsich 8 obrazku (2. faze) }
        GetXYImageCoordinatesGBM(X,Y,Pom+'_9');
        if (IO_Result = 37) then GoTo For_end_2;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        GetMemory(Memory,S9,O9); if (S9 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S10,O10); if (S10 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S11,O11); if (S11 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S12,O12); if (S12 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S13,O13); if (S13 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S14,O14); if (S14 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S15,O15); if (S15 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S16,O16); if (S16 = 0) then Error(0,'Nedostatek pameti');
        LoadImageGBM(S9,O9,Pom+'_9',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S10,O10,Pom+'_10',J);  Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S11,O11,Pom+'_11',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S12,O12,Pom+'_12',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S13,O13,Pom+'_13',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S14,O14,Pom+'_14',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S15,O15,Pom+'_15',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S16,O16,Pom+'_16',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');{}

        MaxPhase:=4;
        { zjisti existenci dalsich  16 obrazku (2 fazi) }
        GetXYImageCoordinatesGBM(X,Y,Pom+'_17');
        if (IO_Result = 37) then GoTo For_end_2;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        MaxPhase:=6;
        GetMemory(Memory,S17,O17); if (S17 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S18,O18); if (S18 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S19,O19); if (S19 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S20,O20); if (S20 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S21,O21); if (S21 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S22,O22); if (S22 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S23,O23); if (S23 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S24,O24); if (S24 = 0) then Error(0,'Nedostatek pameti');

        LoadImageGBM(S17,O17,Pom+'_17',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S18,O18,Pom+'_18',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S19,O19,Pom+'_19',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S20,O20,Pom+'_20',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S21,O21,Pom+'_21',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S22,O22,Pom+'_22',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S23,O23,Pom+'_23',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S24,O24,Pom+'_24',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');

        { zjisti existenci dalsich  8 obrazku (1 faze) }
        GetXYImageCoordinatesGBM(X,Y,Pom+'_25');
        if (IO_Result = 37) then GoTo For_end_2;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        MaxPhase:=8;
        GetMemory(Memory,S25,O25); if (S25 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S26,O26); if (S26 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S27,O27); if (S27 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S28,O28); if (S28 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S29,O29); if (S29 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S30,O30); if (S30 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S31,O31); if (S31 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S32,O32); if (S32 = 0) then Error(0,'Nedostatek pameti');

        LoadImageGBM(S25,O25,Pom+'_25',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S26,O26,Pom+'_26',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S27,O27,Pom+'_27',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S28,O28,Pom+'_28',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S29,O29,Pom+'_29',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S30,O30,Pom+'_30',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S31,O31,Pom+'_31',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
        LoadImageGBM(S32,O32,Pom+'_32',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\units2');
     end;
For_end_2:
   end;

   InvalidateCache;
   for I:=1 to MaxTypesOfUnits do begin
      Unit_types[I,1].IUnitSize:=Unit_types[I,0].IUnitSize;
      Unit_types[I,1].JUnitSize:=Unit_types[I,0].JUnitSize;
      Unit_types[I,1].XUnitSize:=Unit_types[I,0].XUnitSize;
      Unit_types[I,1].YUnitSize:=Unit_types[I,0].YUnitSize;
      Unit_types[I,1].Presah:=Unit_types[I,0].Presah;
   end;

   SetCursor(WaitCursor);
   { *** JEDNOTKY NAHRANY *** }
end;

{ XXXXX }
begin
    GetMaxRes(MaxRes);
    if (ScreenShot) then
      case (MaxRes) of
         0 : SaveScreenMemory:=  LongInt(640)*480+4; { 640x 480 }
         1 : SaveScreenMemory:=  LongInt(800)*600+4; { 800x 600 }
         2 : SaveScreenMemory:=  LongInt(1024)*768+4; { 1024x768 }
         3 : SaveScreenMemory:=1200*1024+4; { 1200x1024 }
      else
        SaveScreenMemory:=1000000;
      end
    else SaveScreenMemory:=0;
    { alokace pameti }
    if (MaxRes = 0) then begin { 640x 480 }
      if not AllocateGlobalMemory(4096*(LongInt(13)*3+4)*YCellSize+65535) then
          Error(0,'nedostatek globalni pameti');
      GetMemory(4096*(LongInt(13)*3+4)*YCellSize+64000,MapSegment,X);
    end else
      if (MaxRes = 1) then begin { 800x 600 }
        if not AllocateGlobalMemory(4096*(LongInt(16)*3+4)*YCellSize+65535) then
           Error(0,'nedostatek globalni pameti');
        GetMemory(4096*(LongInt(16)*3+4)*YCellSize+64000,MapSegment,X);
      end else begin { 1024x768 }
        if (MaxRes = 2) then begin
          if not AllocateGlobalMemory(4096*(LongInt(21)*3+4)*YCellSize+65535) then
             Error(0,'nedostatek globalni pameti');
          GetMemory(4096*(LongInt(21)*3+4)*YCellSize+64000,MapSegment,X);
        end else begin { 1200x1024 }
          if not AllocateGlobalMemory(4096*(LongInt(31)*3+4)*YCellSize+65535) then
             Error(0,'nedostatek globalni pameti');
          GetMemory(4096*(LongInt(31)*3+4)*YCellSize+64000,MapSegment,X);
        end;
      end;
    if (MapSegment = 0) then Error(0,'nedostek globalni pameti');
    Inc(MapSegment,SelectorInc);
    if not AllocateGlobalMemory(70000+SaveScreenMemory+WindowMemory) then
       Error(0,'nedostatek globalni pameti');{}

    InitSmallMemory;

    {"OCHRANNA BARIERA"}
    GetMemory(5,SPom,OPom);

    { * OKNA * }
    InvalidateCache;
    OpenImage('.\data\windows',NoCreateNew);  {  }
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\windows');
    GetMemory(Window1Memory,Win1Seg,Win1Ofs);
    if (Win1Seg = 0) then Error(0,' nedostatek   pameti');
    GetMemory(Window1Memory,Win1BckSeg,Win1BckOfs);
    if (Win1BckSeg = 0) then Error(0,' nedostatek   pameti');
    LoadImageGBM(Win1Seg, Win1Ofs,'win1',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\windows');

    { * PRO POTREBY SAVESCREEN }
    if (ScreenShot) then begin
      GetMemory(SaveScreenMemory,SScreen,OScreen);
      if (SScreen = 0) then Error(0,'nedostatek pameti');
      OScreen:=0; Inc(SScreen, SelectorInc);
    end;

    GetMemory(TempPictureMemory,TempSeg, TempOfs);
    if (TempSeg = 0) then Error(0,'nedostatek pameti');
    { pro ukladani pomocnych veci, velikost TempPictureMemory {}
    GetMemory(Window1Memory,TempSeg2, TempOfs2);
    if (TempSeg2 = 0) then Error(0,'nedostatek pameti');
    { pro ukladani pomocnych veci, velikost TempPictureMemory {}

    {GetMemory(128*1024,BckSegment,X); { pozadi ke slotum (GroupsBck) }
    GetMemory(30*1024,BckSegment,X); { pozadi ke slotum (GroupsBck) }
    if (BckSegment = 0) then Error(0,'nedostek globalni pameti');
    {Inc(BckSegment,SelectorInc);{}

    { * NAHRANI PALETY * }
    if (TerrainCondition <> Night) then
      LoadRGB(0,'data\paleta1.rgb')
    else
      LoadRGB(0,'data\paleta2.rgb');
    if (IO_Result <> 0) then Error(IO_Result,'- soubor data\paleta?.rgb');
    SetRGB(250,0,0,0);

    { * NAHRANI KURZORU MYSI * }
    for I:=0 to LastCursorType do with Cursors[I] do begin
       for J:=0 to MaxCursorPhase do begin
          with (Mem[J]) do begin
             GetMemory(XCursorSize*YCursorSize+4,S,O);
             if (S = 0) then Error(0,'Nedostatek   pameti');{}
          end;
          with (Mem2[J]) do begin
             GetMemory(XCursorSize*YCursorSize+4,S,O);
             if (S = 0) then Error(0,'Nedostatek   pameti');{}
          end;
       end;
       MaxPhase:=0;
    end;

    OpenImage('.\data\cursors',NoCreateNew);  {  }
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\cursors');
    if (InternalCache) then begin
      Result:=CacheFetch('.\data\cursors');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
    end;

    with (Cursors[WaitCursor]) do begin { WAITCURSOR }
      Pom:='wait'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
      { prekopirovani }
      for J:=0 to MaxCursorPhase do with (Mem2[J]) do begin
          S:=Mem[J].S; O:=Mem[J].O;
      end;
    end;
    {x}
    with (Cursors[GroupingCursor]) do begin { GROUPINGCURSOR }
      Pom:='group'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'1'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end; J:=0;  Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem2[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'2'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
    end;
    {x}
    with (Cursors[MoveCursor]) do begin { MOVECURSOR }
      Pom:='move'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'1'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end; J:=0;  Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem2[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'2'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
    end;
    {x}
    with (Cursors[GoInsideCursor]) do begin { GoInsideCursor }
      Pom:='goinsid'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
      { prekopirovani }
      for J:=0 to MaxCursorPhase do with (Mem2[J]) do begin
          S:=Mem[J].S; O:=Mem[J].O;
      end;
    end;
    {x}
    with (Cursors[AttackCursor]) do begin { ATTACKCURSOR }
      Pom:='attack'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'1'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end; J:=0;  Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem2[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'2'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
    end;
    {x}
    with (Cursors[WayPointRecCursor]) do begin { WAYPOINTRECCURSOR }
      Pom:='record'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'1'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem2[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'2'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
    end;
    {x}
    with (Cursors[NormalCursor]) do begin { NORMALCURSOR }
      Pom:='normal'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'1'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem2[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'2'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-2;
    end;
    {x}
    with (Cursors[NoCursor]) do begin { NOCURSOR }
      Pom:='no'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         LoadImageGBM(S,O,Pom,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-1; { prekopirovani }
      for J:=0 to MaxCursorPhase do with (Mem2[J]) do begin
          S:=Mem[J].S; O:=Mem[J].O;
      end;
    end;
    {x}
    with (Cursors[NoAttackCursor]) do begin { NOATTACK }
      Pom:='noattack'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         LoadImageGBM(S,O,Pom,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;
      MaxPhase:=J-1; { prekopirovani }
      for J:=0 to MaxCursorPhase do with (Mem2[J]) do begin
          S:=Mem[J].S; O:=Mem[J].O;
      end;
    end;
    {x}
    with (Cursors[LoadCursor]) do begin { MOVECURSOR }
      Pom:='load'; J:=0; Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'1'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end; {J:=0;  Konec:=False;
      while ((J <= MaxCursorPhase) and (not Konec)) do with (Mem2[J]) do begin
         Str(J+1,Pom2); LoadImageGBM(S,O,Pom+'2'+Pom2,0);
         if (IO_Result <> 0) then
           if ((IO_Result = 37) and (J > 0)) then Konec:=True { obrazek nenalezen }
{           else Error(IO_Result,'- soubor .\data\cursors');
         Inc(J);
      end;{}
      MaxPhase:=J-2;
    end;
    {x}

    SetCursor(WaitCursor);
    InvalidateCache;

    { * PRO OBRAZKY 128x128 * }
    for I:=0 to 11 do with (Pictures128[I]) do begin { obrazky 128x128 }
      GetMemory(LongInt(128)*128+4,S,O);
      Max:=0; { max. pouzita faze }
    end;

    { * NAHRANI FONTU * }
    GetMemory(10000,FontSegment, FontOffsets);
    if (FontSegment = 0) then Error(0,'Nedostatek   pameti');
    OpenImage('.\data\font',NoCreateNew);  {  }
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\font');
    LoadImageGBM(FontSegment, FontOffsets,'font8_10',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\font');
    Inc(FontOffsets,4);
    SetCursor(WaitCursor);

    {* NAHRANI TLACITEK *}
    LoadButtonFile('.\data\buttons', 1, 2);
    ButtonsColors(72,68,74,75);   { barvy tlacitek }

    LoadType3Button('.\data\buttons','stop',2,1);
    LoadType3Button('.\data\buttons','patr',2,2);
    LoadType3Button('.\data\buttons','naloz',2,3);
    LoadType3Button('.\data\buttons','vyloz',2,4);
    LoadType3Button('.\data\buttons','rozlo',2,5);
    LoadType3Button('.\data\buttons','oprav',2,6);
    LoadType3Button('.\data\buttons','moral',2,7);

    GetXYImageCoordinatesGBM(X,Y,'back');
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\buttons');
    Memory:=LongInt(X)*Y+4;
    GetMemory(Memory,ButtonsBckSeg, ButtonsBckOfs);
    if (ButtonsBckSeg = 0) then Error(0,'Nedostatek   pameti');
    LoadImageGBM(ButtonsBckSeg, ButtonsBckOfs,'back',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\buttons');

    { * POMOCNY PROSTOR * }
    GetMemory(Price_bck_memory,Price_bck_segment, Price_bck_offset);
    if (Price_bck_segment = 0) then Error(0,' nedostatek   pameti');
    GetMemory(Price_bck_memory,Price_segment, Price_offset);
    if (Price_segment = 0) then Error(0,' nedostatek   pameti');

    { * NAHRANI OBRAZKU S HODNOSTMI (ZKUSENOST) * }
    { alokace pameti }
    for I:=0 to MaxExperienceSerie do with ExperienceLevel[I] do begin
       GetMemory(300,Segment,Offsets);
       if (Segment = 0) then Error(0,' nedostatek   pameti');
    end;
    { nahrani }
    OpenImage('.\data\experien',NoCreateNew);  {  }
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\experien');
    with ExperienceLevel[0] do LoadImageGBM(Segment,Offsets,'bck',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\experien');
    with ExperienceLevel[1] do LoadImageGBM(Segment,Offsets,'frame',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\experien');
    with ExperienceLevel[2] do LoadImageGBM(Segment,Offsets,'wheel',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\experien');
    with ExperienceLevel[3] do LoadImageGBM(Segment,Offsets,'star',0);
    if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\experien');

    { * INICIALIZACE MAPY * }
    for J:=0 to JMax do
     for I:=0 to IMax do begin
        with (Map^[I,J]) do begin
           First_level:=0; Second_level:=0;
           Level_type:=0;
        end;
    end;
    SetCursor(WaitCursor);

   { *** NAHRANI POMOCNYCH OBRAZKU *** }
   OpenImage('.\data\hlp',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\hlp');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   GetXYImageCoordinatesGBM(X,Y,'cross');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,CrossSegment,CrossOffsets);
   if (CrossSegment = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(CrossSegment,CrossOffsets,'cross',0);

   GetXYImageCoordinatesGBM(X,Y,'plasty');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,PlastyProductSegment, PlastyProductOffset);
   if (PlastyProductSegment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,PlastyProductSegment2, PlastyProductOffset2);
   if (PlastyProductSegment2 = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(PlastyProductSegment, PlastyProductOffset,'plasty',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(PlastyProductSegment2, PlastyProductOffset2,'plasty2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetXYImageCoordinatesGBM(X,Y,'repairL1');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,RepairL1Segment, RepairL1Offset);
   if (RepairL1Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairL2Segment, RepairL2Offset);
   if (RepairL2Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairL3Segment, RepairL3Offset);
   if (RepairL3Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairL4Segment, RepairL4Offset);
   if (RepairL4Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairL5Segment, RepairL5Offset);
   if (RepairL5Segment = 0) then Error(0,'- nedostatek   pameti');

   LoadImageGBM(RepairL1Segment, RepairL1Offset,'repairL1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairL2Segment, RepairL2Offset,'repairL2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairL3Segment, RepairL3Offset,'repairL3',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairL4Segment, RepairL4Offset,'repairL4',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairL5Segment, RepairL5Offset,'repairL5',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetMemory(Memory,RepairH1Segment, RepairH1Offset);
   if (RepairH1Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairH2Segment, RepairH2Offset);
   if (RepairH2Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairH3Segment, RepairH3Offset);
   if (RepairH3Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairH4Segment, RepairH4Offset);
   if (RepairH4Segment = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,RepairH5Segment, RepairH5Offset);
   if (RepairH5Segment = 0) then Error(0,'- nedostatek   pameti');

   LoadImageGBM(RepairH1Segment, RepairH1Offset,'repairH1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairH2Segment, RepairH2Offset,'repairH2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairH3Segment, RepairH3Offset,'repairH3',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairH4Segment, RepairH4Offset,'repairH4',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(RepairH5Segment, RepairH5Offset,'repairH5',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetXYImageCoordinatesGBM(X,Y,'defmode');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,DefModeSegment,DefModeOffset);
   if (DefModeSegment = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(DefModeSegment,DefModeOffset,'defmode',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetXYImageCoordinatesGBM(X,Y,'ok1');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,SegOk1Cursor,OffsOk1Cursor);
   if (SegOk1Cursor = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(SegOk1Cursor,OffsOk1Cursor,'ok1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   GetMemory(Memory,SegOk2Cursor,OffsOk2Cursor);
   if (SegOk2Cursor = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(SegOk2Cursor,OffsOk2Cursor,'ok2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetMemory(Memory,SegOkAir1Cursor,OffsOkAir1Cursor);
   if (SegOkAir1Cursor = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(SegOkAir1Cursor,OffsOkAir1Cursor,'okair1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   GetMemory(Memory,SegOkAir2Cursor,OffsOkAir2Cursor);
   if (SegOkAir2Cursor = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(SegOkAir2Cursor,OffsOkAir2Cursor,'okair2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetXYImageCoordinatesGBM(X,Y,'attack1');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,SegAttack1Cursor,OffsAttack1Cursor);
   if (SegAttack1Cursor = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(SegAttack1Cursor,OffsAttack1Cursor,'attack1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   GetMemory(Memory,SegAttack2Cursor,OffsAttack2Cursor);
   if (SegAttack2Cursor = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(SegAttack2Cursor,OffsAttack2Cursor,'attack2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   GetXYImageCoordinatesGBM(X,Y,'ANotRed0');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,AirNotReady0Seg,AirNotReady0Ofs);
   if (AirNotReady0Seg = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(AirNotReady0Seg,AirNotReady0Ofs,'ANotRed0',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   {x}
   GetMemory(Memory,AirNotReady1Seg,AirNotReady1Ofs);
   if (AirNotReady1Seg = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(AirNotReady1Seg,AirNotReady1Ofs,'ANotRed1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   {x}
   GetMemory(Memory,AirNotReady2Seg,AirNotReady2Ofs);
   if (AirNotReady2Seg = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(AirNotReady2Seg,AirNotReady2Ofs,'ANotRed2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   {x}
   GetMemory(Memory,AirNotReady3Seg,AirNotReady3Ofs);
   if (AirNotReady3Seg = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(AirNotReady3Seg,AirNotReady3Ofs,'ANotRed3',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   SetCursor(WaitCursor);

   GetXYImageCoordinatesGBM(X,Y,'adm1');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;
   GetMemory(Memory,ADMSeg1,ADMOfs1);
   if (ADMSeg1 = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,ADMSeg2,ADMOfs2);
   if (ADMSeg2 = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,ADMSeg3,ADMOfs3);
   if (ADMSeg3 = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,ADMSeg4,ADMOfs4);
   if (ADMSeg4 = 0) then Error(0,'- nedostatek   pameti');
   GetMemory(Memory,ADMSeg5,ADMOfs5);
   if (ADMSeg5 = 0) then Error(0,'- nedostatek   pameti');
   LoadImageGBM(ADMSeg1,ADMOfs1,'adm1',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(ADMSeg2,ADMOfs2,'adm2',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(ADMSeg3,ADMOfs3,'adm3',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(ADMSeg4,ADMOfs4,'adm4',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(ADMSeg5,ADMOfs5,'adm5',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');

   { fog of war }
   GetXYImageCoordinatesGBM(X,Y,'grid1');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Memory:=LongInt(X) * LongInt(Y) + 4;

   for I:=0 to MaxGrids do with (Grids[I]) do begin
     Str(I+1,Pom);
     GetMemory(Memory,GridSeg, GridOfs);
     if (GridSeg = 0) then Error(0,'- nedostatek   pameti');
     LoadImageGBM(GridSeg, GridOfs,'grid'+Pom,0);
     if ((IO_Result <> 0) and (IO_Result <> 37)) then Error(IO_Result,'- soubor .\data\hlp');
   end;

   InvalidateCache;

   SetCursor(WaitCursor);

   { *** NAHRANI OBRAZKU DOSTRELU *** }
   OpenImage('.\data\range',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\range');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\range');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   for I:=0 to MaxRangeCheckArray do begin
      Str(I,Pom);
      LoadImageGBM(Seg(Range_check_array^[I]),Ofs(Range_check_array^[I]),Pom,I);
      if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\range');
   end;
   InvalidateCache;
   SetCursor(WaitCursor);

   { *** NAHRANI OBRAZKU KOURE *** }
   with (Fire) do begin
     OpenImage('.\data\fire',NoCreateNew);  {  }
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     if (InternalCache) then begin
       Result:=CacheFetch('.\data\fire');
       if (Result <> 0) then
         if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
     end;
     GetXYImageCoordinatesGBM(X,Y,'fire1_1');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     Memory:=LongInt(X) * LongInt(Y) + 8;
     GetMemory(Memory,S1,O1);
     if (S1 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,S2,O2);
     if (S2 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,S3,O3);
     if (S3 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,S4,O4);
     if (S4 = 0) then Error(0,'- nedostatek   pameti');
     LoadImageGBM(S1,O1,'fire1_1',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(S2,O2,'fire1_2',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(S3,O3,'fire1_3',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(S4,O4,'fire1_4',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');

     GetXYImageCoordinatesGBM(X,Y,'fire2_1');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     Memory:=LongInt(X) * LongInt(Y) + 8;
     GetMemory(Memory,S21,O21);
     if (S21 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,S22,O22);
     if (S22 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,S23,O23);
     if (S23 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,S24,O24);
     if (S24 = 0) then Error(0,'- nedostatek   pameti');
     LoadImageGBM(S21,O21,'fire2_1',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(S22,O22,'fire2_2',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(S23,O23,'fire2_3',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(S24,O24,'fire2_4',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');

     GetXYImageCoordinatesGBM(X,Y,'fire3_1');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     Memory:=LongInt(X) * LongInt(Y) + 8;
     GetMemory(Memory,SB1,OB1);
     if (SB1 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,SB2,OB2);
     if (SB2 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,SB3,OB3);
     if (SB3 = 0) then Error(0,'- nedostatek   pameti');
     GetMemory(Memory,SB4,OB4);
     if (SB4 = 0) then Error(0,'- nedostatek   pameti');
     LoadImageGBM(SB1,OB1,'fire3_1',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(SB2,OB2,'fire3_2',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(SB3,OB3,'fire3_3',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
     LoadImageGBM(SB4,OB4,'fire3_4',0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\fire');
   end;
   InvalidateCache;
   SetCursor(WaitCursor);

   { *** NAHRANI OBRAZKU POZADI *** }
   OpenImage('.\data\debris',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\debris');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\debris');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   SetCursor(WaitCursor); Memory:=DebrisPictureSize;
   for I:=0 to (DebrisGiveUpIndex-1)  do begin
     Str(I,Pom);
     with (DebrisPicture[I]) do begin
       GetMemory(Memory,DebrisSegment,Offsets);
       if (DebrisSegment = 0) then Error(0,'- nedostatek pameti');
       LoadImageGBM(DebrisSegment,Offsets,Pom,I+1);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\debris');
     end;
   end;
   {x}
   for I:=0 to 5 do with (DebrisPicture[DebrisFireIndex+I]) do begin
     Str(I+1,Pom);
     GetMemory(Memory,DebrisSegment,Offsets);
     if (DebrisSegment = 0) then Error(0,'- nedostatek pameti');
     LoadImageGBM(DebrisSegment,Offsets,'fire1_'+Pom,0);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\debris');
   end;
   {x}
   with (DebrisPicture[DebrisGiveUpIndex]) do begin
       GetMemory(Memory,DebrisSegment,Offsets);
       if (DebrisSegment = 0) then Error(0,'- nedostatek pameti');
       LoadImageGBM(DebrisSegment,Offsets,'givup1',0);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\debris');
   end;
   with (DebrisPicture[DebrisGiveUpIndex+1]) do begin
       GetMemory(Memory,DebrisSegment,Offsets);
       if (DebrisSegment = 0) then Error(0,'- nedostatek pameti');
       LoadImageGBM(DebrisSegment,Offsets,'givup2',0);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\debris');
   end;
   with (DebrisPicture[DebrisGiveUpIndex+2]) do begin
       GetMemory(Memory,DebrisSegment,Offsets);
       if (DebrisSegment = 0) then Error(0,'- nedostatek pameti');
       LoadImageGBM(DebrisSegment,Offsets,'givup3',0);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\debris');
   end;
   InvalidateCache;
   SetCursor(WaitCursor);

   { *** NAHRANI OBRAZKU STREL A ZABLESKU *** }
   LoadShots;
   LoadExplosions2;
   LoadExplosions;

   { *** NAHRANI POZADI DO PAMETI *** }

   Memory:=LongInt(XCellSize) * LongInt(YCellSize) + 4;
   { nyni probehne vlastni nahravani }
   case (TerrainCondition) of
     Clear: OpenImage('.\data\bck',NoCreateNew);  {  }
     Snow:  OpenImage('.\data\bck.snw',NoCreateNew);  {  }
     Sand:  OpenImage('.\data\bck.san',NoCreateNew);  {  }
     Night: OpenImage('.\data\bck.nig',NoCreateNew);  {  }
     Rain:  OpenImage('.\data\bck.rai',NoCreateNew);  {  }
   else
     OpenImage('.\data\bck',NoCreateNew);  {  }
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\bck');
   if (InternalCache) then begin
      case (TerrainCondition) of
        Clear: Result:=CacheFetch('.\data\bck');
        Snow:  Result:=CacheFetch('.\data\bck.snw');
        Sand:  Result:=CacheFetch('.\data\bck.san');
        Night: Result:=CacheFetch('.\data\bck.nig');
        Rain:  Result:=CacheFetch('.\data\bck.rai');
      else
        Result:=CacheFetch('.\data\bck');
      end;
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   SetCursor(WaitCursor);
   for I:=0 to 255 do begin
     Str(I,Pom);
     with (Background[I]) do begin
       GetMemory(Memory,Segment,Offsets); if (Segment = 0) then Error(0,'Nedostatek pameti');
       LoadImageGBM(Segment,Offsets,Pom,(I+1));
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\bck');
     end;
   end;
   InvalidateCache;
   SetCursor(WaitCursor);

   { pozadi 2 }
   case (TerrainCondition) of
     Clear: OpenImage('.\data\bck2',NoCreateNew);  {  }
     Snow:  OpenImage('.\data\bck2.snw',NoCreateNew);  {  }
     Sand:  OpenImage('.\data\bck2.san',NoCreateNew);  {  }
     Night: OpenImage('.\data\bck2.nig',NoCreateNew);  {  }
     Rain:  OpenImage('.\data\bck2.rai',NoCreateNew);  {  }
   else
     OpenImage('.\data\bck2',NoCreateNew);  {  }
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\bck2');
   if (InternalCache) then begin
      case (TerrainCondition) of
        Clear: Result:=CacheFetch('.\data\bck2');
        Snow:  Result:=CacheFetch('.\data\bck2.snw');
        Sand:  Result:=CacheFetch('.\data\bck2.san');
        Night: Result:=CacheFetch('.\data\bck2.nig');
        Rain:  Result:=CacheFetch('.\data\bck2.rai');
      else
        Result:=CacheFetch('.\data\bck2');
      end;
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   SetCursor(WaitCursor);
   for I:=0 to 255 do begin
     Str(I,Pom);
     with (Background[I+256]) do begin
       GetMemory(Memory,Segment,Offsets); if (Segment = 0) then Error(0,'Nedostatek pameti');
       LoadImageGBM(Segment,Offsets,Pom,(I+1));
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\bck2');
     end;
   end;
   InvalidateCache;
   SetCursor(WaitCursor);
   { *** POZADI NAHRANO *** }


   Init_gr_data3;

   { *** NAHRANI BUDOV DO PAMETI *** }
   { nejprve pole vynulujeme }
   for I:=1 to MaxTypesOfBuildings do with Building_types[I] do begin
      S1:=0; S2:=0; S3:=0; SBurn:=0; SmallPictS:=0; SmallPictO:=0;
      for J:=0 to MaxBuildingPhase do with (SO[J]) do begin
         S:=0; O:=0;
      end;
      MaxBuildPhase:=0;
   end;

   { NAHRANI MALYCH OBRAZKU BUDOV }
   { alokace pameti }
   I:=1;
   OpenImage('.\data\building.sml',NoCreateNew);  { lide 1 }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building.sml');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\building.sml');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   for I:=1 to MaxTypesOfBuildings do with (Building_types[I]) do begin
      GetMemory(LongInt(XPictureSize-1)*LongInt(YPictureSize-1)+4,SmallPictS, SmallPictO);
      if (SmallPictS = 0) then Error(0,' nedostatek   pameti');
      Str((I-1),Pom);
      LoadImageGBM(SmallPictS,SmallPictO,Pom,I);
      if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building.sml');
   end;
   InvalidateCache;

   { nyni probehne nahravani velkych obrazku }
   case (TerrainCondition) of
     Clear: OpenImage('.\data\building',NoCreateNew);
     Night: OpenImage('.\data\building.nig',NoCreateNew);
   else
     OpenImage('.\data\building',NoCreateNew);
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
   if (InternalCache) then begin
      case (TerrainCondition) of
        Clear: Result:=CacheFetch('.\data\building');
        Night: Result:=CacheFetch('.\data\building.nig');
      else
        Result:=CacheFetch('.\data\building');
      end;
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   J:=1;
   for I:=1 to MaxTypesOfBuildings do begin
     Str(I-1,Pom);
     { zjisteni existence a velikosti obrazku }
     GetXYImageCoordinatesGBM(X,Y,Pom+'_1');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
     Memory:=LongInt(X) * LongInt(Y) + 4;

     with (Building_types[I]) do begin
        XBuildingSize:=X; YBuildingSize:=Y;
        IBuildingSize:=X div XCellSize; if (X mod XCellSize <> 0) then Inc(IBuildingSize);
        JBuildingSize:=Y div YCellSize; if (Y mod YCellSize <> 0) then Inc(JBuildingSize);

        GetMemory(Memory,S1,O1); if (S1 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S2,O2); if (S2 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S3,O3); if (S3 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S6,O6); if (S6 = 0) then Error(0,'Nedostatek pameti');
        GetMemory(Memory,S7,O7); if (S7 = 0) then Error(0,'Nedostatek pameti');

        LoadImageGBM(S1,O1,Pom+'_1',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
        LoadImageGBM(S2,O2,Pom+'_2',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
        LoadImageGBM(S3,O3,Pom+'_3',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
        repeat
          with (SO[MaxBuildPhase]) do begin
            GetMemory(Memory,S,O); if (S = 0) then Error(0,'Nedostatek pameti');
            if (MaxBuildPhase > 0) then Str(MaxBuildPhase,Ret)
            else Ret:='';
            LoadImageGBM(S,O,Pom+'_4'+Ret,J); Inc(J);
            if ((IO_Result <> 0) and (IO_Result <> 37))
            then Error(IO_Result,'- soubor .\data\building');
          end;
          Inc(MaxBuildPhase);
        until ((IO_Result = 37) or (MaxBuildPhase > MaxBuildingPhase));
        if (IO_Result = 37) then Dec(J);
        Dec(MaxBuildPhase,2);

        LoadImageGBM(S6,O6,Pom+'_6',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
        LoadImageGBM(S7,O7,Pom+'_7',J); Inc(J);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\building');
     end;
For_end_12:
   end;
   InvalidateCache;
end;

{ ***** }
procedure LoadShots;
{ inicializace obrazku strel a zablesku
}
label Shots_end1, Shots_end2;
var I, J : Word;
    Pom:String;
    Result : Word;
begin
   OpenImage('.\data\shots',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\shots');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   { inicializace }
   for I:=0 to MaxShotTypes do with (Bullets[I]) do begin
      S1:=0; S2:=0; S3:=0; S4:=0; S5:=0; S6:=0; S7:=0; S8:=0;
      S9:=0; S10:=0; S11:=0; S12:=0; S13:=0; S14:=0; S15:=0; S16:=0;
   end;
   for I:=0 to MaxShotTypes do with (Flashs[I]) do begin
      S1:=0; S2:=0; S3:=0; S4:=0; S5:=0; S6:=0; S7:=0; S8:=0;
      S9:=0; S10:=0; S11:=0; S12:=0; S13:=0; S14:=0; S15:=0; S16:=0;
   end;

   {nyni nahrani strel } J:=1;
   for I:=0 to MaxShotTypes do with (Bullets[I]) do begin
     Str(I,Pom);
     { existuje 1. obrazek ? }
     GetXYImageCoordinatesGBM(XSize, YSize,'bulet'+Pom+'2');
     if (IO_Result = 37) then GoTo Shots_end1;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     GetMemory(MaxShotMemorySize,S2,O2);  if (S2 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S2,O2,'bulet'+Pom+'2',J); Inc(J);if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     { existuje nejaky dalsi obrazek ? }
     GetXYImageCoordinatesGBM(XSize, YSize,'bulet'+Pom+'1');
     if (IO_Result = 37) then begin GoTo Shots_end1; end;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     GetMemory(MaxShotMemorySize,S1,O1);  if (S1 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S3,O3); if (S3 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S4,O4);  if (S4 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S5,O5);  if (S5 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S6,O6);  if (S6 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S7,O7);  if (S7 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S8,O8);  if (S8 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S9,O9);  if (S9 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S10,O10);  if (S10 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S11,O11);  if (S11 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S12,O12);  if (S12 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S13,O13);  if (S13 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S14,O14);  if (S14 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S15,O15);  if (S15 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S16,O16);  if (S16 = 0) then Error(0,'Nedostatek pameti');

     LoadImageGBM(S3,O3,'bulet'+Pom+'3',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S4,O4,'bulet'+Pom+'4',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S5,O5,'bulet'+Pom+'5',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S6,O6,'bulet'+Pom+'6',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S7,O7,'bulet'+Pom+'7',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S8,O8,'bulet'+Pom+'8',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S1,O1,'bulet'+Pom+'1',J); Inc(J);  if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S10,O10,'bulet'+Pom+'10',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S11,O11,'bulet'+Pom+'11',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S12,O12,'bulet'+Pom+'12',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S13,O13,'bulet'+Pom+'13',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S14,O14,'bulet'+Pom+'14',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S15,O15,'bulet'+Pom+'15',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S16,O16,'bulet'+Pom+'16',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     LoadImageGBM(S9,O9,'bulet'+Pom+'9',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\shots');
     SetCursor(WaitCursor);
Shots_end1:
   end;
   InvalidateCache;

   OpenImage('.\data\flashs',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\flashs');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   { nyni nahrani zablesku } J:=1;
   for I:=0 to MaxShotTypes do with (Flashs[I]) do begin
     Str(I,Pom);
     { existuje 1. obrazek ? }
     GetXYImageCoordinatesGBM(XSize, YSize,'flash'+Pom+'2');
     if (IO_Result = 37) then GoTo Shots_end2;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     GetMemory(MaxShotMemorySize,S2,O2);  if (S2 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S2,O2,'flash'+Pom+'2',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     { existuje nejaky dalsi obrazek ? }
     GetXYImageCoordinatesGBM(XSize, YSize,'flash'+Pom+'1');
     if (IO_Result = 37) then begin Inc(J); GoTo Shots_end2; end;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     GetMemory(MaxShotMemorySize,S1,O1); if (S1 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S3,O3); if (S3 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S4,O4); if (S4 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S5,O5); if (S5 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S6,O6); if (S6 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S7,O7); if (S7 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S8,O8); if (S8 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S9,O9); if (S9 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S10,O10); if (S10 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S11,O11); if (S11 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S12,O12); if (S12 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S13,O13); if (S13 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S14,O14); if (S14 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S15,O15); if (S15 = 0) then Error(0,'Nedostatek pameti');
     GetMemory(MaxShotMemorySize,S16,O16); if (S16 = 0) then Error(0,'Nedostatek pameti');

     LoadImageGBM(S3,O3,'flash'+Pom+'3',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S4,O4,'flash'+Pom+'4',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S5,O5,'flash'+Pom+'5',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S6,O6,'flash'+Pom+'6',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S7,O7,'flash'+Pom+'7',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S8,O8,'flash'+Pom+'8',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S1,O1,'flash'+Pom+'1',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S10,O10,'flash'+Pom+'10',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S11,O11,'flash'+Pom+'11',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S12,O12,'flash'+Pom+'12',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S13,O13,'flash'+Pom+'13',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S14,O14,'flash'+Pom+'14',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S15,O15,'flash'+Pom+'15',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S16,O16,'flash'+Pom+'16',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     LoadImageGBM(S9,O9,'flash'+Pom+'9',J); Inc(J); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\flashs');
     SetCursor(WaitCursor);
Shots_end2:
   end;
   InvalidateCache;

   { zaverecne kopirovani }
   for I:=0 to MaxShotTypes do with (Bullets[I]) do begin
      if (S2 <> 0) and (S1 = 0) then begin { jeden obrazek pro vsechny }
         S1:=S2; S3:=S2; S4:=S2; S5:=S2; S6:=S2; S7:=S2; S8:=S2;
         S9:=S2; S10:=S2; S11:=S2; S12:=S2; S13:=S2; S14:=S2; S15:=S2; S16:=S2;
         O1:=O2; O3:=O2; O4:=O2; O5:=O2; O6:=O2; O7:=O2; O8:=O2;
         O9:=O2; O10:=O2; O11:=O2; O12:=O2; O13:=O2; O14:=O2; O15:=O2; O16:=O2;{}
      end;
   end;

   for I:=0 to MaxShotTypes do with (Flashs[I]) do begin
      if (S2 <> 0) and (S1 = 0) then begin { jeden obrazek pro vsechny }
         S1:=S2; S3:=S2; S4:=S2; S5:=S2; S6:=S2; S7:=S2; S8:=S2;
         S9:=S2; S10:=S2; S11:=S2; S12:=S2; S13:=S2; S14:=S2; S15:=S2; S16:=S2;
         O1:=O2; O3:=O2; O4:=O2; O5:=O2; O6:=O2; O7:=O2; O8:=O2;
         O9:=O2; O10:=O2; O11:=O2; O12:=O2; O13:=O2; O14:=O2; O15:=O2; O16:=O2;{}
      end;
   end;
end;

{ ***** }
procedure LoadExplosions;
{ inicializace obrazku explozi strel
}
label Explosions_end1;
var I : Word;
    Pom:String;
    Result:Word;
begin
   OpenImage('.\data\explosio',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\explosio');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   { inicializace }

   { nyni nahrani explozi }
   for I:=0 to MaxShotTypes do with (Explosions[I]) do begin
     MaxPhase:=0;
     Str(I,Pom);
     { existuje 1. obrazek ? }
     GetXYImageCoordinatesGBM(XShot,YShot,'explos'+Pom+'1');
     if (IO_Result = 37) then GoTo Explosions_end1;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     ShotMemory:=LongInt(XShot)*YShot+4;
     GetMemory(ShotMemory,S1,O1); if (S1 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S1,O1,'explos'+Pom+'1',0); if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     { existuje nejaky dalsi obrazek ? }
     GetMemory(ShotMemory,S2,O2); if (S2 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S2,O2,'explos'+Pom+'2',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     GetMemory(ShotMemory,S3,O3); if (S3 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S3,O3,'explos'+Pom+'3',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     GetMemory(ShotMemory,S4,O4); if (S4 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S4,O4,'explos'+Pom+'4',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     GetMemory(ShotMemory,S5,O5); if (S5 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S5,O5,'explos'+Pom+'5',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     GetMemory(ShotMemory,S6,O6); if (S6 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S6,O6,'explos'+Pom+'6',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     GetMemory(ShotMemory,S7,O7); if (S7 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S7,O7,'explos'+Pom+'7',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     GetMemory(ShotMemory,S8,O8); if (S8 = 0) then Error(0,'Nedostatek pameti');
     LoadImageGBM(S8,O8,'explos'+Pom+'8',0);
     if (IO_Result = 37) then GoTo Explosions_end1; if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio');
     Inc(MaxPhase);
     SetCursor(WaitCursor);
Explosions_end1:
   end;
   InvalidateCache;
end;

{ ***** }
procedure LoadExplosions2;
{ inicializace obrazku explozi
}
var I : Word;
    Pom:String;
    X, Y, Result : Word;
    ShotMemory : LongInt;
begin
   OpenImage('.\data\explosio.2',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
   if (InternalCache) then begin
      Result:=CacheFetch('.\data\explosio.2');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   { inicializace }

   { nyni nahrani explozi }
   with (Explosions2) do begin
     { existuje 1. obrazek ? }
     GetXYImageCoordinatesGBM(X,Y,'expl1_1');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
     ShotMemory:=LongInt(X)*Y+4;
     for I:=1 to MaxSmallExplosPhase do with Small[I] do begin
       Str(I,Pom);
       GetMemory(ShotMemory,S,O); if (S = 0) then Error(0,'Nedostatek pameti');
       LoadImageGBM(S,O,'expl'+Pom+'_1',0);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
     end;

     { existuje 1. obrazek ? }
     GetXYImageCoordinatesGBM(X,Y,'expl1_2');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
     ShotMemory:=LongInt(X)*Y+4;
     for I:=1 to MaxMediumExplosPhase do with Medium[I] do begin
       Str(I,Pom);
       GetMemory(ShotMemory,S,O); if (S = 0) then Error(0,'Nedostatek pameti');
       LoadImageGBM(S,O,'expl'+Pom+'_2',0);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
     end;

     { existuje 1. obrazek ? }
     GetXYImageCoordinatesGBM(X,Y,'expl1_3');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
     ShotMemory:=LongInt(X)*Y+4;
     for I:=1 to MaxBigExplosPhase do with Big[I] do begin
       Str(I,Pom);
       GetMemory(ShotMemory,S,O); if (S = 0) then Error(0,'Nedostatek pameti');
       LoadImageGBM(S,O,'expl'+Pom+'_3',0);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\explosio.2');
     end;

     SetCursor(WaitCursor);
   end;
   InvalidateCache;
end;

{ ***** }
procedure SetMapInfo(UnitType:Byte; Ix,Jx,DangerClass,ADangerClass:Word; Friend:Boolean);
{ pomocna procedura pro Set_fog
  Friend = True pro pro mne pratelskou jednotku
}
var PomClass:Byte;
begin
 if (Friend) then begin
    with (MapInfo^[Ix,Jx]) do begin
      { prekvalifikovani kategorie nebezpecnosti }
         if (DangerClass = 255) then PomClass:=255 else
          if (DangerClass <= 2) then PomClass:=0 else
           if (DangerClass <= 5) then PomClass:=1 else
            if (DangerClass <= 7) then PomClass:=2 else
                 Error(0,'unita grafika3, procedura   SetMapInfo, bod a');
         if (PomClass <> 255) then case (Unit_types[UnitType,Byte(Friend)].TargetTyp) of
             0 : with (MapInfo^[Ix,Jx]) do begin
                   Dec(HLLight[PomClass]); Inc(VLLight[PomClass]);
                 end;
             1 : with (MapInfo^[Ix,Jx]) do begin
                   Dec(HLight[PomClass]); Inc(VLight[PomClass]);
                 end;
             2 : with (MapInfo^[Ix,Jx]) do begin
                   Dec(HHeavy[PomClass]); Inc(VHeavy[PomClass]);
                 end;
             3 : with (MapInfo^[Ix,Jx]) do begin
                   Dec(HAir[PomClass]); Inc(VAir[PomClass]);
                 end;
             4 : ;
         else { case }
         end; { case }
         Dec(HTotall); Inc(VTotall);
         if ((UnitType = 33) or (UnitType = 2)) then begin
           Dec(HSpecial); Inc(VSpecial);
         end;
         if (ADangerClass <> 255) then begin
            Dec(HAAttack[ADangerClass]);
            Inc(VAAttack[ADangerClass]);
         end;
    end;
 end else with (MapInfo^[Ix,Jx]) do begin
    { prekvalifikovani kategorie nebezpecnosti }
       if (DangerClass = 255) then PomClass:=255 else
        if (DangerClass <= 2) then PomClass:=0 else
         if (DangerClass <= 5) then PomClass:=1 else
          if (DangerClass <= 7) then PomClass:=2 else
               Error(0,'unita grafika3, procedura SetMapInfo, bod b');
       if (PomClass <> 255) then case (Unit_types[UnitType,Byte(Friend)].TargetTyp) of
           0 : with (MapInfo^[Ix,Jx]) do begin
                 Dec(EnemyHLLight[PomClass]); Inc(EnemyVLLight[PomClass]);
               end;
           1 : with (MapInfo^[Ix,Jx]) do begin
                 Dec(EnemyHLight[PomClass]); Inc(EnemyVLight[PomClass]);
               end;
           2 : with (MapInfo^[Ix,Jx]) do begin
                 Dec(EnemyHHeavy[PomClass]); Inc(EnemyVHeavy[PomClass]);
               end;
           3 : with (MapInfo^[Ix,Jx]) do begin
                 Dec(EnemyHAir[PomClass]); Inc(EnemyVAir[PomClass]);
               end;
           4 : ;
       else { case }
       end; { case }
       Dec(EnemyHTotall); Inc(EnemyVTotall);
       if ((UnitType = 33) or (UnitType = 2)) then begin
         Dec(EnemyHSpecial); Inc(EnemyVSpecial);
       end;
       if (ADangerClass <> 255) then begin
          Dec(EnemyHAAttack[ADangerClass]);
          Inc(EnemyVAAttack[ADangerClass]);
       end;
   end;
end;

{ ***** }
procedure ClearMapInfo(UnitType:Byte; Ix,Jx,DangerClass,ADangerClass:Word; Friend:Boolean);
{ pomocna procedura pro Set_fog
  Friend = True pro mne pratelskou jednotku
}
var PomClass:Byte;
begin
 if (Friend) then begin
    with (MapInfo^[Ix,Jx]) do begin
      { prekvalifikovani kategorie nebezpecnosti }
         if (DangerClass = 255) then PomClass:=255 else
          if (DangerClass <= 2) then PomClass:=0 else
           if (DangerClass <= 5) then PomClass:=1 else
            if (DangerClass <= 7) then PomClass:=2 else
                 Error(0,'unita grafika3, procedura ClearMapInfo, bod a');
         if (PomClass <> 255) then case (Unit_types[UnitType,Byte(Friend)].TargetTyp) of
             0 : with (MapInfo^[Ix,Jx]) do begin
                   Inc(HLLight[PomClass]); Dec(VLLight[PomClass]);
                 end;
             1 : with (MapInfo^[Ix,Jx]) do begin
                   Inc(HLight[PomClass]); Dec(VLight[PomClass]);
                 end;
             2 : with (MapInfo^[Ix,Jx]) do begin
                   Inc(HHeavy[PomClass]); Dec(VHeavy[PomClass]);
                 end;
             3 : with (MapInfo^[Ix,Jx]) do begin
                   Inc(HAir[PomClass]); Dec(VAir[PomClass]);
                 end;
             4 : ;
         else { case }
         end; { case }
         Inc(HTotall); Dec(VTotall);
         if ((UnitType = 33) or (UnitType = 2)) then begin
           Inc(HSpecial); Dec(VSpecial);
         end;
         if (ADangerClass <> 255) then begin
            Inc(HAAttack[ADangerClass]);
            Dec(VAAttack[ADangerClass]);
         end;
    end;
 end else with (MapInfo^[Ix,Jx]) do begin
    { prekvalifikovani kategorie nebezpecnosti }
       if (DangerClass = 255) then PomClass:=255 else
        if (DangerClass <= 2) then PomClass:=0 else
         if (DangerClass <= 5) then PomClass:=1 else
          if (DangerClass <= 7) then PomClass:=2 else
               Error(0,'unita grafika3, procedura ClearMapInfo, bod b');
       if (PomClass <> 255) then case (Unit_types[UnitType,Byte(Friend)].TargetTyp) of
           0 : with (MapInfo^[Ix,Jx]) do begin
                 Inc(EnemyHLLight[PomClass]); Dec(EnemyVLLight[PomClass]);
               end;
           1 : with (MapInfo^[Ix,Jx]) do begin
                 Inc(EnemyHLight[PomClass]); Dec(EnemyVLight[PomClass]);
               end;
           2 : with (MapInfo^[Ix,Jx]) do begin
                 Inc(EnemyHHeavy[PomClass]); Dec(EnemyVHeavy[PomClass]);
               end;
           3 : with (MapInfo^[Ix,Jx]) do begin
                 Inc(EnemyHAir[PomClass]); Dec(EnemyVAir[PomClass]);
               end;
           4 : ;
       else { case }
       end; { case }
       Inc(EnemyHTotall); Dec(EnemyVTotall);
       if ((UnitType = 33) or (UnitType = 2)) then begin
         Inc(EnemyHSpecial); Dec(EnemyVSpecial);
       end;
       if (ADangerClass <> 255) then begin
          Inc(EnemyHAAttack[ADangerClass]);
          Dec(EnemyVAAttack[ADangerClass]);
       end;
   end;
end;

{ ***** }
procedure SetFog(IP,JP:Word; Sight:Byte; Rac:Byte; Sets:Boolean);
{ je-li Fog_of_war = True, pak pro objekt na miste IP,JP  bud nastavi
  viditelny vyrez (Sets = True), nebo jej vyrusi.
  Sight = "dohled", Friend je uroven "pratelskosti" objektu vuci me:
  0 .. nepritel
  1 .. neutral
  2 .. spojenec
}
var I,J,I1,I2,J1,J2,ISize,JSize,Ix,Jx:Word;
    Transfer, Visib, Mouse, BigDraw:Boolean;
    PomClass:Byte;
    Friend:Byte;
begin
 Friend:=Races[Rac].Friend[MyRace];
 if (Fog_of_war) then begin
   Queue.Init;
   if (Sight > IP) then I1:=0 else I1:=IP-Sight;
   if (Sight > JP) then J1:=0 else J1:=JP-Sight;
   if ((Sight+IP) > IMax) then I2:=IMax else I2:=IP+Sight;
   if ((Sight+JP) > JMax) then J2:=JMax else J2:=JP+Sight;
   if (Sets) then begin
   { NASTAVENI }
     for J:=J1 to J2 do
      for I:=I1 to I2 do begin
        if (Range_check(IP,JP,I,J,Sight)) then begin
        { inside sight range }

           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }
           if (Friend < 2) then with (MapBck^[I,J]) do
            with (MapBckTemp^[I,J]) do begin
           { jde o pohledy nepratelske jednotky }
              Inc(EnemyVisibilit);
              with (Map^[I,J]) do begin
                  {}
                  if (Second_level <> 0) then
                  if (Units[Second_level] <> Nil) then
                  with (Units[Second_level]^) do begin
                     if (not EnemyVisibility) then begin
                        EnemyVisibility:=True; {}
                        Ix:=IInfoPos; Jx:=JInfoPos;
                        if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                          SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                        end; { if (Races[Race].Friend[MyRace] = 2) then {}
                        Ix:=IPos; Jx:=JPos;
                     end; { if (not EnemyVisibility) then begin {}
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 0)) then
                  if (Units[First_level] <> Nil) then
                  with (Units[First_level]^) do begin
                     if (not EnemyVisibility) then begin
                        EnemyVisibility:=True;
                        Ix:=IInfoPos; Jx:=JInfoPos;
                        if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                           SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                        end; { if (Races[Race].Friend[MyRace] = 2) then {}
                        Ix:=IPos; Jx:=JPos;
                     end; { if (not EnemyVisibility) then begin {}
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 128)) then
                  if (Buildings[First_level] <> Nil) then
                  with (Buildings[First_level]^) do begin
                     {Visib:=False;
                     ISize:=Building_types[BuildingType].IBuildingSize;
                     JSize:=Building_types[BuildingType].JBuildingSize;
                     for Ix:=IPos to IPos+ISize-1 do
                       for Jx:=JPos to JPos+JSize-1 do
                         Visib:=Visib or (MapBck^[Ix,Jx].EnemyVisibilit <> 0);
                     {}
                     if (not EnemyVisibility) then begin
                        EnemyVisibility:=True;
                        Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                        if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then
                        with (MapInfo^[Ix,Jx]) do begin
                        { prekvalifikovani kategorie nebezpecnosti }
                           Dec(EnemyHBuildingsNum); { pocet nepr. neviditelnych budov }
                           Dec(EnemyHBuildingsWeight,GetBuildingWeight(BuildingType));
                           Inc(EnemyVBuildingsNum); { pocet nepr. viditelnych budov }
                           Inc(EnemyVBuildingsWeight,GetBuildingWeight(BuildingType));
                        end; Ix:=IPos; Jx:=JPos;
                     end; { if (not EnemyVisibility) {}
                  end; { with (Buildings[First_level]^) }
              end; { with Map^[I,J] }
           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }

           end else with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do begin
           { jde o pohledy pratelskeho objektu  }
             if ((Rac = MyRace) or (not AllyFog)) then begin
                Temp:=Temp or 2; BuildRadar^[I,J].P:=True;
             end;
             if ((Visibilit and Races[MyRace].VisMask  = 0) and
                 ((Rac = MyRace) or (not AllyFog))) then begin
             { zobraz zmeneny teren }
                if ((Rac = MyRace) or (not AllyFog)) then Inc(Visibilit)
                else Inc(Visibilit,1 shl 8);
                Transfer:=True;
                with (Map^[I,J]) do begin
                  {}
                  if (Second_level <> 0) then
                  if (Units[Second_level] <> Nil) then
                  with (Units[Second_level]^) do begin
                     if (not Visibility) then begin
                        Visibility:=True;
                        Ix:=IInfoPos; Jx:=JInfoPos;
                        if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                           SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                        end; { if (Races[Race].Friend[MyRace] = 0) then {}
                        Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 0)) then
                  if (Units[First_level] <> Nil) then
                  with (Units[First_level]^) do begin
                     if (not Visibility) then begin
                        Visibility:=True;
                        Ix:=IInfoPos; Jx:=JInfoPos;
                        if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                           SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                        end; { if (Races[Race].Friend[MyRace] = 0) then {}
                        Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 128)) then
                  if (Buildings[First_level] <> Nil) then
                  with (Buildings[First_level]^) do begin
                     ISize:=Building_types[BuildingType].IBuildingSize;
                     JSize:=Building_types[BuildingType].JBuildingSize;
                     for Ix:=IPos to IPos+ISize-1 do
                       for Jx:=JPos to JPos+JSize-1 do begin
                          if ((Rac = MyRace) or (not AllyFog)) then begin
                             BuildRadar^[Ix,Jx].B:=Race;
                             BuildRadar^[Ix,Jx].P:=True;
                          end;
                       end;
                     {x}
                     if (not Visibility) then begin
                        Visibility:=True;
                        Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                        if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                        with (MapInfo^[Ix,Jx]) do begin
                        { prekvalifikovani kategorie nebezpecnosti }
                           {Dec(FriendlyHBuildingsNum); { pocet nepr. neviditelnych budov }
                           {Dec(FriendlyHBuildingsWeight,GetBuildingWeight(BuildingType));
                           Inc(FriendlyVBuildingsNum); { pocet nepr. viditelnych budov }
                           {Inc(FriendlyVBuildingsWeight,GetBuildingWeight(BuildingType));{}
                        end; Ix:=IPos; Jx:=JPos;
                     end;
                  end else BuildRadar^[I,J].B:=255 else BuildRadar^[I,J].B:=255;
                end;
                if (Transfer) then Queue.Insert(I,J);
                { x update radaru x }
                Mouse:=TestMouse(I,J,I+XCursorSize,J+YCursorSize);
                if (Mouse) then CursorOff;
                DrawRadarPixel(I,J);
                if (((I = IBeg) or (I = (IBeg+IScreenSize-1))) and
                    (J >= JBeg) and (J <= (JBeg+JScreenSize)) or
                    ((J = JBeg) or (J = (JBeg+JScreenSize-1))) and
                    (I >= IBeg) and (I <= (IBeg+IScreenSize))) then
                { bily obdelnik }
                    SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                             YRadarRealBeg+JScreenSize+JBeg-1,65);
                if (Mouse) then CursorOn;
             end else begin
                if ((Rac = MyRace) or (not AllyFog)) then Inc(Visibilit)
                else Inc(Visibilit,1 shl 8){};
             end;
           end;
        end;
      end;
   end else begin
   { VYMAZANI }
     for J:=J1 to J2 do
      for I:=I1 to I2 do begin
        if (Range_check(IP,JP,I,J,Sight)) then begin
        { inside sight range }

           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }
           if (Friend < 2) then with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do begin
           { jde o pohledy nepratelske jednotky }
              Dec(EnemyVisibilit);
              with (Map^[I,J]) do begin
                {}
                if (Second_level <> 0) then
                if (Units[Second_level] <> Nil) then
                with (Units[Second_level]^) do begin
                   Visib:=False; ISize:=0; JSize:=0;
                   if (XOffset <> 0) then Inc(ISize);
                   if (YOffset <> 0) then Inc(JSize);
                   for Ix:=IPos to IPos+ISize do
                     for Jx:=JPos to JPos+JSize do
                       Visib:=Visib or (MapBckTemp^[Ix,Jx].EnemyVisibilit <> 0);
                   {}
                   if ((EnemyVisibility) and (not Visib)) then begin
                      EnemyVisibility:=False; {}
                      Ix:=IInfoPos; Jx:=JInfoPos;
                      if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                        ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                      end; { if (Races[Race].Friend[MyRace] = 2) then {}
                      Ix:=IPos; Jx:=JPos;
                   end; { if (not EnemyVisibility) then begin {}
                end;
                {}
                if ((First_level <> 0) and (Level_type and 128 = 0)) then
                if (Units[First_level] <> Nil) then
                with (Units[First_level]^) do begin
                   Visib:=False; ISize:=0; JSize:=0;
                   if (XOffset <> 0) then Inc(ISize);
                   if (YOffset <> 0) then Inc(JSize);
                   for Ix:=IPos to IPos+ISize do
                     for Jx:=JPos to JPos+JSize do
                       Visib:=Visib or (MapBckTemp^[Ix,Jx].EnemyVisibilit <> 0);
                   {}
                   if ((EnemyVisibility) and (not Visib)) then begin
                      EnemyVisibility:=False; {}
                      Ix:=IInfoPos; Jx:=JInfoPos;
                      if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                        ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                      end; { if (Races[Race].Friend[MyRace] = 2) then {}
                      Ix:=IPos; Jx:=JPos;
                   end; { if (not EnemyVisibility) then begin {}
                end;
                {}
                if ((First_level <> 0) and (Level_type and 128 = 128)) then
                if (Buildings[First_level] <> Nil) then
                with (Buildings[First_level]^) do begin
                   Visib:=False;
                   ISize:=Building_types[BuildingType].IBuildingSize;
                   JSize:=Building_types[BuildingType].JBuildingSize;
                   for Ix:=IPos to IPos+ISize-1 do
                     for Jx:=JPos to JPos+JSize-1 do
                       Visib:=Visib or (MapBckTemp^[Ix,Jx].EnemyVisibilit <> 0);
                   {}
                   if ((EnemyVisibility) and (not Visib)) then begin
                      EnemyVisibility:=False;
                      Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                      if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then
                      with (MapInfo^[Ix,Jx]) do begin
                      { prekvalifikovani kategorie nebezpecnosti }
                         Dec(EnemyVBuildingsNum); { pocet nepr. neviditelnych budov }
                         Dec(EnemyVBuildingsWeight,GetBuildingWeight(BuildingType));
                         Inc(EnemyHBuildingsNum); { pocet nepr. viditelnych budov }
                         Inc(EnemyHBuildingsWeight,GetBuildingWeight(BuildingType));
                      end; Ix:=IPos; Jx:=JPos;
                   end; { if (not EnemyVisibility) {}
                end; { with (Buildings[First_level]^) }
              end; { with Map^[I,J] }
           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }

           end else with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do begin
           { pohled PRATELSKEHO objektu }
             if ((Visibilit and Races[MyRace].VisMask  = 1) and
                 ((Rac = MyRace) or (not AllyFog))) then begin
             { zobraz zmeneny teren }
                if ((Rac = MyRace) or (not AllyFog)) then Dec(Visibilit)
                else Dec(Visibilit,1 shl 8);
                Transfer:=True;
                BigDraw:=False;
                with (Map^[I,J]) do begin
                  {}
                  if (Second_level <> 0) then
                  if (Units[Second_level] <> Nil) then
                  with (Units[Second_level]^) do  begin
                     Visib:=False; ISize:=0; JSize:=0;
                     if (XOffset <> 0) then Inc(ISize);
                     if (YOffset <> 0) then Inc(JSize);
                     for Ix:=IPos to IPos+ISize do
                       for Jx:=JPos to JPos+JSize do
                         Visib:=Visib or
                         (MapBckTemp^[Ix,Jx].Visibilit and Races[MyRace].VisMask <> 0);
                     {}
                     if ((Visibility) and (not Visib)) then begin
                       Erase_unit(Units[Index],True); BigDraw:=True;
                       Visibility:=False; {Transfer:=False;{}
                       Ix:=IInfoPos; Jx:=JInfoPos;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                         ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                       end; { if (Races[Race].Friend[MyRace] = 0) then {}
                       Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 0)) then
                  if (Units[First_level] <> Nil) then
                  with (Units[First_level]^) do begin
                     Visib:=False; ISize:=0; JSize:=0;
                     if (XOffset <> 0) then Inc(ISize);
                     if (YOffset <> 0) then Inc(JSize);
                     for Ix:=IPos to IPos+ISize do
                       for Jx:=JPos to JPos+JSize do
                         Visib:=Visib or
                         (MapBckTemp^[Ix,Jx].Visibilit and Races[MyRace].VisMask <> 0);
                     {}
                     if ((Visibility) and (not Visib)) then begin
                       Erase_unit(Units[Index],True); BigDraw:=True;
                       Visibility:=False; {Transfer:=False;{}
                       Ix:=IInfoPos; Jx:=JInfoPos;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                         ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                       end; { if (Races[Race].Friend[MyRace] = 0) then {}
                       Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 128)) then
                  if (Buildings[First_level] <> Nil) then
                  with (Buildings[First_level]^) do begin
                     Visib:=False;
                     ISize:=Building_types[BuildingType].IBuildingSize;
                     JSize:=Building_types[BuildingType].JBuildingSize;
                     for Ix:=IPos to IPos+ISize-1 do
                       for Jx:=JPos to JPos+JSize-1 do
                         Visib:=Visib or
                         (MapBckTemp^[Ix,Jx].Visibilit and Races[MyRace].VisMask  <> 0);
                     {}
                     if ((Visibility) and (not Visib)) then begin
                       Erase_building(Buildings[Index]); BigDraw:=True;
                       Visibility:=False; Transfer:=False;
                       Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                       with (MapInfo^[Ix,Jx]) do begin
                       { prekvalifikovani kategorie nebezpecnosti }
                         {Dec(FriendlyVBuildingsNum); { pocet nepr. neviditelnych budov }
                         {Dec(FriendlyVBuildingsWeight,GetBuildingWeight(BuildingType));
                         Inc(FriendlyHBuildingsNum); { pocet nepr. viditelnych budov }
                         {Inc(FriendlyHBuildingsWeight,GetBuildingWeight(BuildingType));{}
                       end; Ix:=IPos; Jx:=JPos;
                     end;
                  end else BuildRadar^[I,J].B:=255 else BuildRadar^[I,J].B:=255;
                end;
                if (Transfer) then Queue.Insert(I,J);
                Mouse:=TestMouse(I,J,I+XCursorSize,J+YCursorSize);
                RdrawRadarFrame:=False;
                if (Mouse) then CursorOff;
                if (BigDraw) then begin
                   DrawRadarPixel(Ix,Jx);
                   DrawRadarPixel(Ix+1,Jx);
                   DrawRadarPixel(Ix,Jx+1);
                   DrawRadarPixel(Ix+1,Jx+1);
                end else DrawRadarPixel(I,J);
                if (RdrawRadarFrame) then
                   SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                            YRadarRealBeg+JScreenSize+JBeg-1,65);
                if (Mouse) then CursorOn;
             end else begin
                if ((Rac = MyRace) or (not AllyFog)) then Dec(Visibilit)
                else Dec(Visibilit,1 shl 8){};
             end;
           end;
        end;
      end;
   end; { if (Sets) then .. else }
   Queue.Finish;
 end; { if (Fog_of_war) then begin }
end;

{ ***** }
procedure SetFog2(IP,JP,IP2,JP2:Word; Sight:Byte; Rac:Byte; Sets:Boolean);
{ je-li Fog_of_war = True, pak pro objekt na NOVEM miste IP,JP a aktualizuje
  mlhu pri posunu z pole IP2,JP2 a to bud nastavi viditelny vyrez
  (Sets = True), nebo jej vyrusi. Sight = "dohled", Friend je
  uroven "pratelskosti" objektu vuci me:
  0 .. nepritel
  1 .. neutral
  2 .. spojenec
}
var I,J,I1,I2,J1,J2,ISize,JSize,Ix,Jx:Word;
    Transfer, Visib, BigDraw, Mouse:Boolean;
    PomClass:Byte;
    Friend:Byte;
begin
 Friend:=Races[Rac].Friend[MyRace];

 if (Fog_of_war) then begin
   Queue.Init; Inc(Sight);
   if (Sight > IP) then I1:=0 else I1:=IP-Sight;
   if (Sight > JP) then J1:=0 else J1:=JP-Sight;
   if ((Sight+IP) > IMax) then I2:=IMax else I2:=IP+Sight;
   if ((Sight+JP) > JMax) then J2:=JMax else J2:=JP+Sight;
   Dec(Sight);
   for J:=J1 to J2 do
     for I:=I1 to I2 do begin
       BleX:=I; BLeY:=J;
       if (Range_check(IP,JP,I,J,Sight) and
           (not Range_check(IP2,JP2,I,J,Sight))) then begin
       { uvnitr aktualizovaneho dostrelu }

           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }
           if (Friend < 2) then with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do begin
           { jde o pohledy nepratelske jednotky }
              Inc(EnemyVisibilit);
              with (Map^[I,J]) do begin
                  {}
                  if ((Second_level <> 0) and (Units[Second_level] <> Nil)) then
                  with (Units[Second_level]^) do begin
                     if (not EnemyVisibility) then begin
                        EnemyVisibility:=True; {}
                        Ix:=IInfoPos; Jx:=JInfoPos;
                        if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                          SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                        end; { if (Races[Race].Friend[MyRace] = 2) then {}
                        Ix:=IPos; Jx:=JPos;
                     end; { if (not EnemyVisibility) then begin {}
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 0)) then
                  if (Units[First_level] <> Nil) then
                  with (Units[First_level]^) do begin
                     if (not EnemyVisibility) then begin
                        EnemyVisibility:=True;
                        Ix:=IInfoPos; Jx:=JInfoPos;
                        if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                          SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                        end; { if (Races[Race].Friend[MyRace] = 2) then {}
                        Ix:=IPos; Jx:=JPos;
                     end; { if (not EnemyVisibility) then begin {}
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 128)) then
                  if (Buildings[First_level] <> Nil) then
                  with (Buildings[First_level]^) do begin
                     if (not EnemyVisibility) then begin
                        EnemyVisibility:=True;
                        Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                        if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then
                        with (MapInfo^[Ix,Jx]) do begin
                        { prekvalifikovani kategorie nebezpecnosti }
                           Dec(EnemyHBuildingsNum); { pocet nepr. neviditelnych budov }
                           Dec(EnemyHBuildingsWeight,GetBuildingWeight(BuildingType));
                           Inc(EnemyVBuildingsNum); { pocet nepr. viditelnych budov }
                           Inc(EnemyVBuildingsWeight,GetBuildingWeight(BuildingType));
                        end; Ix:=IPos; Jx:=JPos;
                     end; { if (not EnemyVisibility) {}
                  end; { with (Buildings[First_level]^) }
              end; { with Map^[I,J] }
           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }

           end else with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do  begin
           { Jde o pohledy PRATELSKEHO objektu }
             if ((Rac = MyRace) or (not AllyFog)) then begin
               Temp:=Temp or 2; BuildRadar^[I,J].P:=True;
             end;
             if ((Visibilit and Races[MyRace].VisMask  = 0) and
                 ((Rac = MyRace) or (not AllyFog))) then begin
             { zobraz zmeneny teren }
                if ((Rac = MyRace) or (not AllyFog)) then Inc(Visibilit)
                else Inc(Visibilit,1 shl 8);
                Transfer:=True;
                with (Map^[I,J]) do begin
                  {}
                  if (Second_level <> 0) then
                  if (Units[Second_level] <> Nil) then
                  with (Units[Second_level]^) do begin
                     if (not Visibility) then begin
                       Visibility:=True;
                       Ix:=IInfoPos; Jx:=JInfoPos;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                           SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                       end; { if (Races[Race].Friend[MyRace] = 0) then {}
                       Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 0)) then
                  if (Units[First_level] <> Nil) then
                  with (Units[First_level]^) do begin
                     if (not Visibility) then begin
                       Visibility:=True;
                       Ix:=IInfoPos; Jx:=JInfoPos;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                           SetMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                       end; { if (Races[Race].Friend[MyRace] = 0) then {}
                       Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 128)) then
                  if (Buildings[First_level] <> Nil) then
                  with (Buildings[First_level]^) do begin
                     ISize:=Building_types[BuildingType].IBuildingSize;
                     JSize:=Building_types[BuildingType].JBuildingSize;
                     for Ix:=IPos to IPos+ISize-1 do
                       for Jx:=JPos to JPos+JSize-1 do begin
                         if ((Rac = MyRace) or (not AllyFog)) then begin
                            BuildRadar^[Ix,Jx].B:=Race;
                            BuildRadar^[Ix,Jx].P:=True;
                         end;
                       end;
                     {x}
                     if (not Visibility) then begin
                       Visibility:=True; {Transfer:=False;{}
                       RequestDraw:=True;
                       Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                       with (MapInfo^[Ix,Jx]) do begin
                       { prekvalifikovani kategorie nebezpecnosti }
                           {Dec(FriendlyHBuildingsNum); { pocet nepr. neviditelnych budov }
                           {Dec(FriendlyHBuildingsWeight,GetBuildingWeight(BuildingType));
                           Inc(FriendlyVBuildingsNum); { pocet nepr. viditelnych budov }
                           {Inc(FriendlyVBuildingsWeight,GetBuildingWeight(BuildingType));{}
                       end; Ix:=IPos; Jx:=JPos;
                     end;
                  end else BuildRadar^[I,J].B:=255 else BuildRadar^[I,J].B:=255;
                end;
                if (Transfer) then Queue.Insert(I,J);
                { x update radaru x }
                Mouse:=TestMouse(I,J,I+XCursorSize,J+YCursorSize);
                if (Mouse) then CursorOff;
                DrawRadarPixel(I,J);
                if (((I = IBeg) or (I = (IBeg+IScreenSize-1))) and
                    (J >= JBeg) and (J <= (JBeg+JScreenSize)) or
                    ((J = JBeg) or (J = (JBeg+JScreenSize-1))) and
                    (I >= IBeg) and (I <= (IBeg+IScreenSize))) then
                { bily obdelnik }
                    SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                             YRadarRealBeg+JScreenSize+JBeg-1,65);
                if (Mouse) then CursorOn;
             end else begin
                if ((Rac = MyRace) or (not AllyFog)) then Inc(Visibilit)
                else Inc(Visibilit,1 shl 8){};
             end;
           end;
       end else
{ XXX SMAZANI XXX }
       if ((Range_check(IP2,JP2,I,J,Sight)) and
            (not Range_check(IP,JP,I,J,Sight))) then begin
       { mimo aktualizovany dostrel - SMAZ }

           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }
           if (Friend < 2) then with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do begin
           { jde o pohledy nepratelske jednotky }
              Dec(EnemyVisibilit);
              with (Map^[I,J]) do begin
                {}
                if (Second_level <> 0) then
                if (Units[Second_level] <> Nil) then
                with (Units[Second_level]^) do begin
                   Visib:=False; ISize:=0; JSize:=0;
                   if (XOffset <> 0) then Inc(ISize);
                   if (YOffset <> 0) then Inc(JSize);
                   for Ix:=IPos to IPos+ISize do
                     for Jx:=JPos to JPos+JSize do
                       Visib:=Visib or (MapBckTemp^[Ix,Jx].EnemyVisibilit <> 0);
                   {}
                   if ((EnemyVisibility) and (not Visib)) then begin
                      EnemyVisibility:=False; {}
                      Ix:=IInfoPos; Jx:=JInfoPos;
                      if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                        ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                      end; { if (Races[Race].Friend[MyRace] = 2) then {}
                      Ix:=IPos; Jx:=JPos;
                   end; { if (not EnemyVisibility) then begin {}
                end;
                {}
                if ((First_level <> 0) and (Level_type and 128 = 0)) then
                if (Units[First_level] <> Nil) then
                with (Units[First_level]^) do begin
                   Visib:=False; ISize:=0; JSize:=0;
                   if (XOffset <> 0) then Inc(ISize);
                   if (YOffset <> 0) then Inc(JSize);
                   for Ix:=IPos to IPos+ISize do
                     for Jx:=JPos to JPos+JSize do
                       Visib:=Visib or (MapBckTemp^[Ix,Jx].EnemyVisibilit <> 0);
                   {}
                   if ((EnemyVisibility) and (not Visib)) then begin
                      EnemyVisibility:=False; {}
                      Ix:=IInfoPos; Jx:=JInfoPos;
                      if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                        ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,False);
                      end; { if (Races[Race].Friend[MyRace] = 2) then {}
                      Ix:=IPos; Jx:=JPos;
                   end; { if (not EnemyVisibility) then begin {}
                end;
                {}
                if ((First_level <> 0) and (Level_type and 128 = 128)) then
                if (Buildings[First_level] <> Nil) then
                with (Buildings[First_level]^) do begin
                   Visib:=False;
                   ISize:=Building_types[BuildingType].IBuildingSize;
                   JSize:=Building_types[BuildingType].JBuildingSize;
                   for Ix:=IPos to IPos+ISize-1 do
                     for Jx:=JPos to JPos+JSize-1 do
                       Visib:=Visib or (MapBckTemp^[Ix,Jx].EnemyVisibilit <> 0);
                   {}
                   if ((EnemyVisibility) and (not Visib)) then begin
                      EnemyVisibility:=False;
                      Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                      if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then
                      with (MapInfo^[Ix,Jx]) do begin
                      { prekvalifikovani kategorie nebezpecnosti }
                         Dec(EnemyVBuildingsNum); { pocet nepr. neviditelnych budov }
                         Dec(EnemyVBuildingsWeight,GetBuildingWeight(BuildingType));
                         Inc(EnemyHBuildingsNum); { pocet nepr. viditelnych budov }
                         Inc(EnemyHBuildingsWeight,GetBuildingWeight(BuildingType));
                      end; Ix:=IPos; Jx:=JPos;
                   end; { if (not EnemyVisibility) {}
                end; { with (Buildings[First_level]^) }
              end; { with Map^[I,J] }

           { XXXXXXXXXXXXXXXXXXXXXXXXXXX }

           end else with (MapBck^[I,J]) do
           with (MapBckTemp^[I,J]) do  begin
           { Jde o pohledy PRATELSKEHO objektu }
             if ((Visibilit and Races[MyRace].VisMask  = 1) and
                 ((Rac = MyRace) or (not AllyFog))) then begin
             { zobraz zmeneny teren }
                if ((Rac = MyRace) or (not AllyFog)) then Dec(Visibilit)
                else Dec(Visibilit,1 shl 8){};
                Transfer:=True;
                BigDraw:=False;
                with (Map^[I,J]) do begin
                  {}
                  if (Second_level <> 0) then
                  if (Units[Second_level] <> Nil) then
                  with (Units[Second_level]^) do  begin
                     Visib:=False; ISize:=0; JSize:=0;
                     if (XOffset <> 0) then Inc(ISize);
                     if (YOffset <> 0) then Inc(JSize);
                     for Ix:=IPos to IPos+ISize do
                       for Jx:=JPos to JPos+JSize do
                         Visib:=Visib or
                         (MapBckTemp^[Ix,Jx].Visibilit and Races[MyRace].VisMask  <> 0);
                     {}
                     if ((Visibility) and (not Visib)) then begin
                       Erase_unit(Units[Index],True); BigDraw:=True;
                       Visibility:=False; {Transfer:=False;{}
                       Ix:=IInfoPos; Jx:=JInfoPos;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                         ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                       end; { if (Races[Race].Friend[MyRace] = 0) then {}
                       Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 0)) then
                  if (Units[First_level] <> Nil) then
                  with (Units[First_level]^) do begin
                     Visib:=False; ISize:=0; JSize:=0;
                     if (XOffset <> 0) then Inc(ISize);
                     if (YOffset <> 0) then Inc(JSize);
                     for Ix:=IPos to IPos+ISize do
                       for Jx:=JPos to JPos+JSize do
                         Visib:=Visib or
                         (MapBckTemp^[Ix,Jx].Visibilit and Races[MyRace].VisMask  <> 0);
                     {}
                     if ((Visibility) and (not Visib)) then begin
                       Erase_unit(Units[Index],True); BigDraw:=True;
                       Visibility:=False; {Transfer:=False;{}
                       Ix:=IInfoPos; Jx:=JInfoPos;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                         ClearMapInfo(UnitType,Ix,Jx,DangerClass,ADangerClass,True);
                       end; { if (Races[Race].Friend[MyRace] = 0) then {}
                       Ix:=IPos; Jx:=JPos;
                     end;
                  end;
                  {}
                  if ((First_level <> 0) and (Level_type and 128 = 128)) then
                  if (Buildings[First_level] <> Nil) then
                  with (Buildings[First_level]^) do begin
                     Visib:=False;
                     ISize:=Building_types[BuildingType].IBuildingSize;
                     JSize:=Building_types[BuildingType].JBuildingSize;
                     for Ix:=IPos to IPos+ISize-1 do
                       for Jx:=JPos to JPos+JSize-1 do
                         Visib:=Visib or
                         (MapBckTemp^[Ix,Jx].Visibilit and Races[MyRace].VisMask  <> 0);
                     {}
                     if ((Visibility) and (not Visib)) then begin
                       Erase_building(Buildings[Index]); BigDraw:=True;
                       Visibility:=False; Transfer:=False;
                       Ix:=IPos div IInfoDiv; Jx:=JPos div JInfoDiv;
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                       with (MapInfo^[Ix,Jx]) do begin
                       { prekvalifikovani kategorie nebezpecnosti }
                          {Dec(FriendlyVBuildingsNum); { pocet nepr. neviditelnych budov }
                          {Dec(FriendlyVBuildingsWeight,GetBuildingWeight(BuildingType));
                          Inc(FriendlyHBuildingsNum); { pocet nepr. viditelnych budov }
                          {Inc(FriendlyHBuildingsWeight,GetBuildingWeight(BuildingType));{}
                       end; Ix:=IPos; Jx:=JPos;
                     end;
                  end else BuildRadar^[I,J].B:=255 else BuildRadar^[I,J].B:=255;
                end;
                if (Transfer) then Queue.Insert(I,J);
                { xx update radaru xx }
                Mouse:=TestMouse(I,J,I+XCursorSize,J+YCursorSize);
                RdrawRadarFrame:=False;
                if (Mouse) then CursorOff;
                if (BigDraw) then begin
                   DrawRadarPixel(Ix,Jx);
                   DrawRadarPixel(Ix+1,Jx);
                   DrawRadarPixel(Ix,Jx+1);
                   DrawRadarPixel(Ix+1,Jx+1);
                end else DrawRadarPixel(I,J);
                if (RdrawRadarFrame) then
                   SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                            YRadarRealBeg+JScreenSize+JBeg-1,65);
                if (Mouse) then CursorOn;
             end else begin
                if ((Rac = MyRace) or (not AllyFog)) then Dec(Visibilit)
                else Dec(Visibilit,1 shl 8){};
             end;
           end;
        end;
     end; { for }
   Queue.Finish;
 end; { if (Fog_of_war) then begin }
end;

{ ***** }
function Get_fog_index(I,J:Word):Byte;
{ vrati typ obrazku mlhy v zavislosti na okoli
}
label Konec;
var Result:Integer;
    Add:Byte;
begin
 if (Unknown_terrain and (MapBckTemp^[I,J].Temp and 2 = 0)) then Add:=GridAdd else Add:=0;
 if (not Smooth_fog_of_war) then begin
   if (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask  = 0) then Get_fog_index:=0+Add
   else Get_fog_index:=255;
 end else begin
    if (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask  = 0) then begin
    { *** NEVIDITELNA CAST *** }
      if (Unknown_terrain and (MapBckTemp^[I,J].Temp and 2 <> 0)) then begin
        { * nejprve typ 1 - white\black * }
        Result:=1;
        if (J > 0) then begin
           if (not Unknown_terrain or (MapBckTemp^[I,J-1].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if (I < IMax) then begin
           if (not Unknown_terrain or (MapBckTemp^[I+1,J].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if ((Result >= 0) and (J > 0) and (MapBckTemp^[I,J-1].Temp and 4 = 0))
        then begin Get_fog_index:=1+GridAdd; GoTo Konec; end;

        { * nyni typ 2 - black\white * }
        Result:=1;
        if (I > 0) then begin
          if (not Unknown_terrain or (MapBckTemp^[I-1,J].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if (J < JMax) then begin
          if (not Unknown_terrain or (MapBckTemp^[I,J+1].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if ((Result >= 0) and (J > 0)  and (MapBckTemp^[I,J-1].Temp and 4 = 0))
        then begin Get_fog_index:=2+GridAdd; GoTo Konec; end;

        { * nejprve typ 3 - black/white * }
        Result:=1;
        if (J > 0) then begin
          if (not Unknown_terrain or (MapBckTemp^[I,J-1].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if (I > 0) then begin
          if (not Unknown_terrain or (MapBckTemp^[I-1,J].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if ((Result >= 0) and (J > 0)  and (MapBckTemp^[I,J-1].Temp and 4 = 0))
        then begin Get_fog_index:=3+GridAdd; GoTo Konec; end;

        { * nyni typ 4 - white/black * }
        Result:=1;
        if (I < IMax) then begin
          if (not Unknown_terrain or (MapBckTemp^[I+1,J].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if (J < JMax) then begin
          if (not Unknown_terrain or (MapBckTemp^[I,J+1].Temp and 2 <> 0)) then Result:=-1;
        end else Dec(Result);
        if ((Result >= 0) and (J > 0)  and (MapBckTemp^[I,J-1].Temp and 4 = 0))
        then begin Get_fog_index:=4+GridAdd; GoTo Konec; end;
        {x}

        { * nejprve typ 1 - white\black * }
{        Result:=True;
        if (I > 0) then begin
          Result:=Result and (MapBck^[I-1,J].Visibilit > 0);
          if (J < JMax) then Result:=Result and (MapBck^[I-1,J+1].Visibilit > 0) else Result:=False;
        end else Result:=False;
        if (J < JMax) then Result:=Result and (MapBck^[I,J+1].Visibilit > 0) else Result:=False;
        if (Result) then begin Get_fog_index:=1+Add; GoTo Konec; end;

        { * nyni typ 2 - black\white * }
{        Result:=True;
        if (J > 0) then begin
          Result:=Result and (MapBck^[I,J-1].Visibilit > 0);
          if (I < IMax) then Result:=Result and (MapBck^[I+1,J-1].Visibilit > 0) else Result:=False;
        end else Result:=False;
        if (I < IMax) then Result:=Result and (MapBck^[I+1,J].Visibilit > 0) else Result:=False;
        if (Result) then begin Get_fog_index:=2+Add; GoTo Konec; end;
        {x}

        { * nejprve typ 3 - black/white * }
{        Result:=True;
        if (I < IMax) then begin
          Result:=Result and (MapBck^[I+1,J].Visibilit > 0);
          if (J < JMax) then Result:=Result and (MapBck^[I+1,J+1].Visibilit > 0) else Result:=False;
        end else Result:=False;
        if (J < JMax) then Result:=Result and (MapBck^[I,J+1].Visibilit > 0) else Result:=False;
        if (Result) then begin Get_fog_index:=3+Add; GoTo Konec; end;
        {x}

        { * nyni typ 4 - white/black * }
{        Result:=True;
        if (J > 0) then begin
          Result:=Result and (MapBck^[I,J-1].Visibilit > 0);
          if (I > 0) then Result:=Result and (MapBck^[I-1,J-1].Visibilit > 0) else Result:=False;
        end else Result:=False;
        if (I > 0) then Result:=Result and (MapBck^[I-1,J].Visibilit > 0) else Result:=False;
        if (Result) then begin Get_fog_index:=4+Add; GoTo Konec; end;
        {x}
        Get_fog_index:=0+Add;
      end else Get_fog_index:=0+Add;
    end else begin
    { *** VIDITELNA CAST *** }
       Get_fog_index:=255; Add:=0;
       { * nejprve typ 1 - white\black * }
       Result:=1; Add:=GridAdd;
       if (J > 0) then begin
          if (MapBckTemp^[I,J-1].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
          if (Unknown_terrain and (J > 0)  and (MapBckTemp^[I,J-1].Temp and 2 = 0)) then Add:=GridAdd else Add:=0;
       end else begin Dec(Result); end;
       if (I < IMax) then begin
          if (MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
          if (Unknown_terrain and (MapBckTemp^[I+1,J].Temp and 2 = 0) and (Add = GridAdd))
          then Add:=GridAdd else Add:=0;
       end else begin Dec(Result); end;
       if (Result >= 0) then begin Get_fog_index:=5+Add; GoTo Konec; end;

       { * nyni typ 2 - black\white * }
       Result:=1; Add:=GridAdd;
       if (I > 0) then begin
         if (MapBckTemp^[I-1,J].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
         if (Unknown_terrain and (J > 0)  and (MapBckTemp^[I-1,J].Temp and 2 = 0)) then Add:=GridAdd else Add:=0;
       end else begin Dec(Result); end;
       if (J < JMax) then begin
         if (MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
         if (Unknown_terrain and (MapBckTemp^[I,J+1].Temp and 2 = 0) and (Add = GridAdd))
         then Add:=GridAdd else Add:=0;
       end else begin Dec(Result); end;
       if (Result >= 0) then begin Get_fog_index:=6+Add; GoTo Konec; end;

        { * nejprve typ 3 - black/white * }
        Result:=1; Add:=GridAdd;
        if (J > 0) then begin
          if (MapBckTemp^[I,J-1].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
          if (Unknown_terrain and (J > 0)  and (MapBckTemp^[I,J-1].Temp and 2 = 0)) then Add:=GridAdd else Add:=0;
        end else begin Dec(Result); end;
        if (I > 0) then begin
           if (MapBckTemp^[I-1,J].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
           if (Unknown_terrain and (I > 0)  and (MapBckTemp^[I-1,J].Temp and 2 = 0) and (Add = GridAdd))
           then Add:=GridAdd else Add:=0;
        end else begin Dec(Result); end;
        if (Result >= 0) then begin Get_fog_index:=7+Add; GoTo Konec; end;

        { * nyni typ 4 - white/black * }
        Result:=1; Add:=GridAdd;
        if (I < IMax) then begin
          if (MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
          if (Unknown_terrain and (MapBckTemp^[I+1,J].Temp and 2 = 0)) then Add:=GridAdd else Add:=0;
        end else begin Dec(Result); end;
        if (J < JMax) then begin
           if (MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask  <> 0) then Result:=-1;
           if (Unknown_terrain and (MapBckTemp^[I,J+1].Temp and 2 = 0) and (Add = GridAdd))
           then Add:=GridAdd else Add:=0;
        end else begin Dec(Result); end;
        if (Result >= 0) then begin Get_fog_index:=8+Add; GoTo Konec; end;
        {x}

       Get_fog_index:=255;
    end;
Konec:
 end;
end;

{ ***** }
procedure MaintainMsg;
{ pokud je v malem nebo velkem slotu hlaska, hlida podle hodin, zda ji
  vymazat
}
var HourMin : Word;
    Sec : Byte;
begin
  with (MsgStruct) do begin
     if (ReadRealTime(HourMin, Sec)) then
     else Error(0,'Chyba pri cteni hodin realneho casu');

     { nejprve mala hlaska }
     if ((SmallTimeHourMin > 0) or (SmallTimeSec > 0)) then begin
     { vymaz puvodni hlasku }
        if ((HourMin > SmallTimeHourMin) or
            ((HourMin = SmallTimeHourMin) and (SmallTimeSec <= Sec)))
        then begin  { OK, cas se jiz naplnil }
           Mous:= TestMouse(SmallXBegin,SmallYBegin,
                       SmallXBegin+SmallMsgLen*XFontSize,SmallYBegin+YFontSize) or
                  TestMouse(SmallXBegin,SmallYBegin+SmallYMsgDistance,
                       SmallXBegin+SmallMsgLen*XFontSize,SmallYBegin+YFontSize+SmallYMsgDistance);
           if (Mous) then CursorOff;
           SpeedPutImage(SmallXBegin,SmallYBegin,
                         SmallMsgBckSeg, SmallMsgBckOffs);
           if (SmallYMsgDistance <> 0) then
             SpeedPutImage(SmallXBegin,SmallYBegin+SmallYMsgDistance,
                           SmallMsgBckSeg2, SmallMsgBckOffs2);
           if (Mous) then CursorOn;
           SmallTimeHourMin:=0; SmallTimeSec:=0;
        end;
     end;

     { nyni velka hlaska }
     if ((BigTimeHourMin > 0) or (BigTimeSec > 0)) then begin
     { vymaz puvodni hlasku }
        if ((HourMin > BigTimeHourMin) or
            ((HourMin = BigTimeHourMin) and (BigTimeSec <= Sec)))
        then begin  { OK, cas se jiz naplnil }
           Mous:=TestMouse(BigXBegin,BigYBegin,
                           BigXBegin+BigMsgLen*XFontSize,BigYBegin+YFontSize);
           if (Mous) then CursorOff;
           SpeedPutImage(BigXBegin,BigYBegin,
                         BigMsgBckSeg, BigMsgBckOffs);
           if (Mous) then CursorOn;
           BigTimeHourMin:=0; BigTimeSec:=0;
        end;
     end;
  end; { with (MsgStruct) do begin }
end;

{ ***** }
procedure DebrisManager;
{ provadi obsluhu trosek a koure
}
var I,J : Word;
    RequestDraw : Boolean;
begin
   I:=LowDebrisInfoIndex; RequestDraw:=False;
   while ((I <> DebrisInfoIndex) and (I <> 255))
   do with (DebrisInfo^[I]) do begin
     if (FireTimmer <> 0) then begin
       if (GameTimming = 0) then begin
          FireTimmer:=FireTimmer-2;
          FirePhase:=FirePhase+2;
       end else begin
          FireTimmer:=FireTimmer-1;
          FirePhase:=FirePhase+1;
       end;
       if (FirePhase > 11) then FirePhase:=0;
       RequestDraw:=True;
     end;
     if ((DebrisType >= DebrisGiveUpIndex) and (DebrisType < DebrisFireIndex))
     then begin { "mavani" vzdavajici se vlajeckou }
        Inc(GiveUpTimmer);
        if (GiveUpTimmer = 2) then begin
          RequestDraw:=True;
          DebrisType:=DebrisGiveUpIndex+1;
        end else
           if (GiveUpTimmer = 4) then begin
             RequestDraw:=True;
             DebrisType:=DebrisGiveUpIndex+2;
           end else
             if (GiveUpTimmer = 6) then begin
               GiveUpTimmer:=0;
               RequestDraw:=True;
               DebrisType:=DebrisGiveUpIndex;
             end;
     end;
     if (DebrisTimmer <> 0) then begin
       if (GameTimming = 0) then Dec(DebrisTimmer,2) else Dec(DebrisTimmer);
       if (DebrisTimmer = GetAccurateDelay(HalfDebrisTimmerValue)) then begin
          Inc(DebrisType);
          RequestDraw:=True;
       end;
       if (DebrisTimmer = 0) then begin { zrus trosky }
          RequestDraw:=True;
          MapBck^[IP,JP].Info:=255;
          Inc(LowDebrisInfoIndex);
          if (LowDebrisInfoIndex > MaxDebrisInfoIndex) then
             LowDebrisInfoIndex:=0;
       end;

     end;
     if ((RequestDraw) and (MapBckTemp^[IP,JP].Visibilit and Races[MyRace].VisMask  > 0)) then
        Transfer_map_frame(IP,JP,IP,JP);

     Inc(I); if (I > MaxDebrisInfoIndex) then I:=0;
   end;
end;

{ ***** }
procedure SpecialUnitInfo;
{
}
var I,J,K,L,X,Y,Butt:Word;
    Index:Word;
    Building, Ok:Boolean;
    Side:Word;
begin
   Ok:=False; Building:=False; Index:=255; Side:=1;
   GetCursorPos(X,Y,Butt);
   if ((X >= XScreenBeg) and (Y >= YScreenBeg) and
       (X <= XScreenEnd) and (Y <= YScreenEnd)) then begin
   { kurzor je na mape }
      I:=(X-XScreenBeg) div XCellSize + IBeg;
      J:=(Y-YScreenBeg) div YCellSize + JBeg;
      if (ClickLevel = 0) then with (Map^[I,J]) do begin
      { pozemni jednotky }
        if (First_level <> 0) then begin
          if (Level_type and 128 = 128) then begin
          { budova }
             if ((Buildings[First_level] <> Nil) and
                 (Buildings[First_level]^.Activity)) then begin
               for K:=1 to BuildingsInfoRecord.MaxIndex do
                 if (BuildingsInfoRecord.Rec[K] = Buildings[First_level]^.BuildingType)
                 then Index:=K;
               if (Index <> 255) then begin
                  Ok:=True; Building:=True;
               end;
             end;
          end else begin
          { jednotka }
             if ((Units[First_level] <> Nil) and
                 (Units[First_level]^.Activity)) then begin
               for K:=1 to UnitsInfoRecord.MaxIndex do
                 if (UnitsInfoRecord.Rec[K] = Units[First_level]^.UnitType)
                 then Index:=K;
               if (Index <> 255) then begin
                  Ok:=True; Building:=False;
                  if (Races[MyRace].Friend[Units[First_level]^.Race] < 1)
                  then Side:=0;
                  with (UINfo) do begin
                     Ind:=Units[First_level]^.UnitType; Valid:=True;
                     Name:=Units[First_level]^.Name;
                     Rank:=Units[First_level]^.ExperienceLevel;
                     LA1:=Unit_types[Ind,Side].LightAttack1+Units[First_level]^.LAttackBonus1;
                     HA1:=Unit_types[Ind,Side].HeavyAttack1+Units[First_level]^.HAttackBonus1;
                     AA1:=Unit_types[Ind,Side].AirAttack1+Units[First_level]^.AAttackBonus1;
                     LA2:=Unit_types[Ind,Side].LightAttack2+Units[First_level]^.LAttackBonus2;
                     HA2:=Unit_types[Ind,Side].HeavyAttack2+Units[First_level]^.HAttackBonus2;
                     AA2:=Unit_types[Ind,Side].AirAttack2+Units[First_level]^.AAttackBonus2;
                     DAMAGE:=Unit_types[Ind,Side].DefenceStrength+Units[First_level]^.DamageBonus;
                  end;
               end;
             end;
          end;
        end;
      end else with (Map^[I,J]) do begin
      { vzdusne jednotky }
         if ((Second_level <> 0) and (Units[Second_level] <> Nil) and
             (Units[Second_level]^.Activity)) then begin
               for K:=1 to UnitsInfoRecord.MaxIndex do
                 if (UnitsInfoRecord.Rec[K] = Units[Second_level]^.UnitType)
                 then Index:=K;
               if (Index <> 255) then begin
                  Ok:=True; Building:=False;
                  if (Races[MyRace].Friend[Units[Second_level]^.Race] < 1)
                  then Side:=0;
               end;
               with (UINfo) do begin
                  Ind:=Units[Second_level]^.UnitType; Valid:=True;
                  Name:=Units[Second_level]^.Name;
                  Rank:=Units[Second_level]^.ExperienceLevel;
                  LA1:=Unit_types[Ind,Side].LightAttack1+Units[Second_level]^.LAttackBonus1;
                  HA1:=Unit_types[Ind,Side].HeavyAttack1+Units[Second_level]^.HAttackBonus1;
                  AA1:=Unit_types[Ind,Side].AirAttack1+Units[Second_level]^.AAttackBonus1;
                  LA2:=Unit_types[Ind,Side].LightAttack2+Units[Second_level]^.LAttackBonus2;
                  HA2:=Unit_types[Ind,Side].HeavyAttack2+Units[Second_level]^.HAttackBonus2;
                  AA2:=Unit_types[Ind,Side].AirAttack2+Units[Second_level]^.AAttackBonus2;
                  DAMAGE:=Unit_types[Ind,Side].DefenceStrength+Units[Second_level]^.DamageBonus;
               end;

         end;
      end;

      if (OK) then begin
         CursorOff;
         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);{}
         CursorOn;
         {x}
         CreateMenuInfo(Index,Side,Building);
         {x}
         X:=(XResolution-XWindow1Size) shr 1{}; Y:=(YResolution-YWindow1Size) shr 1{};
         CursorOff;
         PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
{         if (DrawScreen) then begin
            Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
            Draw_screen(IBeg,JBeg,0,0);
         end;{}
         CursorOn;
      end;
   end;
end;

{ ***** }
procedure Grafika3_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'5'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Grafika3_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'5'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************* }
begin
  Queue.Initialize;
end.