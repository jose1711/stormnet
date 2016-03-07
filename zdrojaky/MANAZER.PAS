program Manazer;
{$C FIXED PRELOAD PERMANENT}
uses Graph257, Data, Grafika, Grafika2, Grafika3, _Units, _Buildings, Buttons, _Shot,
     _races, Mouse, Dos, Crt, _units2, _units3, _units4, AI, WinApi, SBSound,
     Grafika4, AI2, Buttons2, AI3, Smix;

type TCach = array[0..12000] of Byte;
const Speed : array[0..6] of TSpeedArray =
            ((1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,1,1,1,1,1,1,1,1,1),
             (2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1),
             (2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,1,1,1,1,1,1,1,1,1,1),
             (3,3,3,3,3,3,3,3,3,3,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (5,6,5,5,6,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1));
var M:LongInt; { xxx }
    Row : Byte; { /// }
    I,GAMETIME,POMTIME:Word;
    Cach:^TCach; { /// }
    J, EndCach:Word; { /// }
    CachUk:Word;  { /// }
    R,G,B:Byte;
    Pom:Double;
    {///}MaterInfoSwitch:Byte;{///}
    { nasleduji pomocne informace }
    ActionLevel:Byte;
    _RaceType:array [0..MaxRace] of Byte;
    ChangeRGB:Word;
    ErFile:File;

{ ***** }
procedure TimerOn; assembler;
{ nastartuje mereni casoveho intervalu
}
asm
   cmp GameSpeed,0
   je @safe
   mov Bx,0
   mov Cx,Del1
   mov Dx,Del2
   int 7eh
   jmp @end

@safe:
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
   cmp GameSpeed,0
   je @again
   mov Bx,1
   int 7eh
   jmp @end

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
function TimerOk:Boolean;
{ ceka do uplynuti intervalu
}
var Tag:Boolean;
begin
 Tag:=False;
 asm
   mov Ah,00h
   int 1ah
   cmp Cx,POMTIME
   ja @end
   cmp Dx,GAMETIME
   jb @again

   mov Tag,1
   jmp @end
@again:
   mov Tag,0
@end:
 end;
 TimerOk:=Tag;
end;{}

{ ***** }
procedure BuildInfoRecord;
{  sestavi "info zaznam pro pouziti informaci"
}
var I,J:Word;
begin
   { nastaveni myunits for this mission }
   for I:=1 to MaxTypesOfUnits do
     GlobalModify^.MyUnitsForMission[I]:=Races[MyRace].PermittedUnits[I];

   for I:=1 to MaxTypesOfUnits do UnitsInfoRecord.Rec[I]:=0;
   for I:=1 to MaxTypesOfBuildings do BuildingsInfoRecord.Rec[I]:=0;
   UnitsInfoRecord.MaxIndex:=0; BuildingsInfoRecord.MaxIndex:=0;

   for I:=1 to MaxTypesOfUnits do begin
      if (Unit_types[I,1].TargetTyp = 0) then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if (Unit_types[I,1].TargetTyp = 1) then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if ((Unit_types[I,1].TargetTyp = 2) and
          (Unit_types[I,1].UnitLevel <> 255) and (I <> 38) and (I < 41))
      then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if ((Unit_types[I,1].TargetTyp = 2) and (Unit_types[I,1].UnitLevel = 255) and
          (I <> 41)) then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
   for I:=1 to MaxTypesOfUnits do begin
      if ((Unit_types[I,1].TargetTyp = 3) and (I <> 38)) then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;
{   for I:=1 to MaxTypesOfUnits do begin
      if (Unit_types^[I,1].TargetTyp = 4) then begin
        UnitsInfoRecord.Rec[UnitsInfoRecord.MaxIndex+1]:=I;
        Inc(UnitsInfoRecord.MaxIndex);
      end;
   end;{}

   {XXXXXXXXX  BUDOVY XXXXXXXXXX}
   for I:=1 to MaxTypesOfBuildings do begin
      if ((I <= 15) or (I = 21))
      then begin
        BuildingsInfoRecord.Rec[BuildingsInfoRecord.MaxIndex+1]:=I;
        Inc(BuildingsInfoRecord.MaxIndex);
      end;
   end;
end;

{ ***** }
procedure Load_map(Way:String);
{ nahraje "map" soubor z disku do pocitace
}
var InFile:File;
    X,Y,CheckSum,Index, Pom:Word;
    I, J:Integer;
    Character:Char;
    Num:Byte;
    PomSCacheUk, PomOCacheUk:Word;
    PomCachePos:LongInt;

    IPos,JPos,Number:Word;
    Race,UnitType,Level,BuildingType,ExpLevel,SpecNumber:Byte;
    UnitName:String[15];
    TGInfo, TGAtt:Byte;

    Robot:Boolean; { True, jde-li o kolaboranty, nebo roboty }
    OSNNeutral,RobotNeutral,Ok:Boolean;

    TUI:TUnitInfo;
begin
   TotalRobotRaces:=0; TotalOSNRaces:=0;
   InvalidateCache; Assign(InFile,Way);
   if (InternalCache) then begin
     IO_Result:=CacheFetch(Way);
     if ((IO_Result <> 0) and (IO_Result <> 65535)) then
       Error(IO_Result,'- soubor ' + Way);
   end else begin
     Reset(InFile,1);
     IO_Result:=IOResult;
     if ((IO_Result <> 0) and (IO_Result <> 65535)) then
       Error(IO_Result,'- soubor ' + Way);
   end;

   { HLAVICKA }
   CheckSum:=0;
   CacheBlockRead(InFile,@Character,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   Inc(CheckSum,Ord(Character));
   CacheBlockRead(InFile,@Character,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   Inc(CheckSum,Ord(Character));
   CacheBlockRead(InFile,@Character,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   Inc(CheckSum,Ord(Character));
   { pocet hracu }
   { ! v budoucnu vyuzit ! }
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   Inc(CheckSum,Ord(Num));
   { reserved }
   CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   { xxx }
   CacheBlockRead(InFile,@IMax,2);  Dec(IMax);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   CacheBlockRead(InFile,@JMax,2);  Dec(JMax);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);

   J:=0;
   while (J <= JMax) do begin
     Inc(J);
     CacheBlockRead(InFile,@Number,2); IO_Result:=IOResult;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
     for I:=1 to (IMax+1) do begin
        MapBck^[I-1,J-1].BckType:=Number;

        { ****** }
      {  if (((I-1) div IInfoDiv) mod 2 = 0) then Num:=0 else Num:=1;
        if (((J-1) div JInfoDiv) mod 2 = 0) then begin
        end else begin
          if (Num = 0) then Num:=1 else Num:=0; { licha }
      {  end;
        if (Num = 0) then begin
           if (MapBck^[I-1,J-1].BckType <= Hill) then
             MapBck^[I-1,J-1].BckType:=28;
        end else begin
           if (MapBck^[I-1,J-1].BckType <= Hill) then
             MapBck^[I-1,J-1].BckType:=59;
        end;
        { ****** }

        MapBck^[I-1,J-1].Info:=255;
        CacheBlockRead(InFile,@Number,2); IO_Result:=IOResult;
        if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
     end; { while }
     CacheBlockRead(InFile,@Number,2); IO_Result:=IOResult; { zbytek EOLN }
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   end;  { while }
   if (InternalCache) then PomCachePos:=CachePos else PomCachePos:=FilePos(InFile);
   IO_Result:=IOResult; if ((IO_Result <> 0) and (IO_Result <> 65535)) then Error(IO_Result,'- soubor ' + Way);
   { check sum }
   CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (X <> CheckSum) then Error(0,'chyba ve formatu mapy');

   { nevyuzita hodnota }
   CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);

   { xxxxxxx NAHRANI INFA O RASACH xxxxxxxxx}
   { 6x konkretni rasa pro danou Race = 0..5:
   { 0..OSN; 1..Odboj; 2..Kolaboranti; 3..Roboti;
     4..OSNNeutral; 5..RobotiNeutral; 6..RobotiOSN }
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (_RaceType[0] <> 255) then Num:=_RaceType[0]; Races[0].RaceType:=Num;
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (_RaceType[1] <> 255) then Num:=_RaceType[1]; Races[1].RaceType:=Num;
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (_RaceType[2] <> 255) then Num:=_RaceType[2]; Races[2].RaceType:=Num;
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (_RaceType[3] <> 255) then Num:=_RaceType[3]; Races[3].RaceType:=Num;
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (_RaceType[4] <> 255) then Num:=_RaceType[4]; Races[4].RaceType:=Num;
   CacheBlockRead(InFile,@Num,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   if (_RaceType[5] <> 255) then Num:=_RaceType[5]; Races[5].RaceType:=Num;

   { nastaveni pole Friend }
   for I:=0 to MaxRace do with (Races[I]) do begin
      case (RaceType) of
         0 : begin Ally:=1; end;
         1 : begin Ally:=1; end;
         2 : begin Ally:=0; end;
         3 : begin Ally:=0; end;
         4 : begin Ally:=1; end;
         5 : begin Ally:=0; end;
         6 : begin Ally:=1; end;
      end;
      if (AllyFog and ((Ally = 1) or (I = MyRace))) then
        if (I = MyRace) then VisMask:=255 else VisMask:=65280;

      Robot:=(RaceType > 1) and (RaceType < 4); { roboti, kolaboranti }
      OSNNeutral:=RaceType = 4;
      RobotNeutral:=RaceType = 5;

      Neutral:=False;
      if (OSNNeutral or RobotNeutral) then Neutral:=True;
      for J:=0 to MaxRace do begin
        case (Races[J].RaceType) of
           0 : begin
                 if (Robot) then Friend[J]:=0
                 else if (OSNNeutral) then Friend[J]:=2
                      else if (RobotNeutral) then Friend[J]:=1
                           else Friend[J]:=2;
               end;
           1 : begin
                 if (Robot) then Friend[J]:=0
                 else if (OSNNeutral) then Friend[J]:=2
                      else if (RobotNeutral) then Friend[J]:=1
                           else Friend[J]:=2;
               end;
           2 : begin
                 if (Robot) then Friend[J]:=2
                 else if (OSNNeutral) then Friend[J]:=1
                      else if (RobotNeutral) then Friend[J]:=2
                           else Friend[J]:=0;
               end;
           3 : begin
                 if (Robot) then Friend[J]:=2
                 else if (OSNNeutral) then Friend[J]:=1
                      else if (RobotNeutral) then Friend[J]:=2
                           else Friend[J]:=0;
               end;
           4 : begin
                 if (Robot) then Friend[J]:=1
                 else if (OSNNeutral) then Friend[J]:=2
                      else if (RobotNeutral) then Friend[J]:=1
                           else Friend[J]:=2;
               end;
           5 : begin
                 if (Robot) then Friend[J]:=2
                 else if (OSNNeutral) then Friend[J]:=1
                      else if (RobotNeutral) then Friend[J]:=2
                           else Friend[J]:=1;
               end;
           6 : begin
                 if (Robot) then Friend[J]:=0
                 else if (OSNNeutral) then Friend[J]:=2
                      else if (RobotNeutral) then Friend[J]:=1
                           else Friend[J]:=2;
               end;
        end;
      end;
   end;
   { 2x nevyuzita hodnota }
   CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);

   {* cache zalohovani *}
   PomSCacheUk:=SCacheUk; PomOCacheUk:=OCacheUk;
   if (InternalCache) then PomCachePos:=CachePos else PomCachePos:=FilePos(InFile);
   IO_Result:=IOResult; if ((IO_Result <> 0) and (IO_Result <> 65535)) then Error(IO_Result,'- soubor ' + Way);

   InvalidateCache; ScreenOff;
   Second_init_gr_data; { grafika3 }

   { xxxxxxx NAHRANI JEDNOTEK xxxxxxxxx}
   { nejprve pocet jednotek na mape }
   InvalidateCache; Assign(InFile,Way);
   if (InternalCache) then begin
     IO_Result:=CacheFetch(Way);
     if ((IO_Result <> 0) and (IO_Result <> 65535)) then
       Error(IO_Result,'- soubor ' + Way);
     SCacheUk:=PomSCacheUk; OCacheUk:=PomOCacheUk;
     CachePos:=PomCachePos;
   end else begin
     Reset(InFile,1); IO_Result:=IOResult;
     if ((IO_Result <> 0) and (IO_Result <> 65535)) then Error(IO_Result,'- soubor ' + Way);
     Seek(InFile, PomCachePos); IO_Result:=IOResult;
     if ((IO_Result <> 0) and (IO_Result <> 65535)) then Error(IO_Result,'- soubor ' + Way);
   end;

   CacheBlockRead(InFile,@Pom,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   for I:=1 to Pom do begin
      { priznak rozsirujicich udaju }
      CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      { reserved }
      CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      { jednotlive udaje jednotky }
      CacheBlockRead(InFile,@IPos,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@JPos,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@Race,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@UnitType,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@BuildingType,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@ExpLevel,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      if (X and 1 = 1) then begin
      { nazev }
         CacheBlockRead(InFile,@UnitName,16); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      end else UnitName:='';
      SpecNumber:=0; Num:=100;
      if (X and 2 = 2) then begin
      { nazev }
         CacheBlockRead(InFile,@SpecNumber,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
         Num:=SpecNumber and 112; Num:=Num shr 4;
         Num:=100-Round(Num*12.5);
      end;

      TGInfo:=128;
      if (X and 4 = 4) then begin
      { cislo TG }
         CacheBlockRead(InFile,@TGInfo,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      end;

      {xxx}TGAtt:=0;
      {xxx}if (X and 8 = 8) then begin
      {xxx}{ nazev }
      {xxx}   CacheBlockRead(InFile,@TGAtt,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      {xxx}end;

      if (((Random(99)+1) <= Num) and
          ((SpecNumber and 128 = 0) or
           ((Races[Race].Ally = 1) and (FriendlySpecialUnitsPresent) or
            (Races[Race].Ally = 0) and (EnemySpecialUnitsPresent))))
      then begin
        Index:=65535;
        if (UnitType = 41) then with (Races[Race]) do begin
        { pouze sablona stredu zakladny }
        { novy stred }
           with (FreePlaces^[0,ActualFreeStructures]) do begin
              X:=IPos; Y:=JPos; PlaceType:=0;
           end;
           Inc(ActualFreeStructures);
           if (ActualFreeStructures > (MaxFreeStructures+1)) then begin
              Error(0,'manazer, procedura Load_map - prekrocen max. pocet zakladen 1 rasy');
           end;
        end else begin
           Ok:=False;
           if (UnitType > 41) then UnitType:=UnitType-1; { centrum_posil atd. }
           if ((Race = MyRace) and (TGInfo and 128 <> 128) and
               (Unit_types[UnitType,1].UnitLevel <> 255))
           then begin { zkus nahradit jednotky jednotkami jadra }
             if GetCoreUnit(UnitType,TUI) then begin
                Ok:=True;
                UnitType:=TUI.UnitType;
                ExpLevel:=TUI.Level;
             end;
           end;
           Index:=New_unit(IPos,JPos,UnitType,Race,ExpLevel,0,True,False,BuildingType);
           if (Ok) then begin
              Units[Index]^.Name:=TUI.Name;
              Units[Index]^.UniqueNumber:=TUI.UniqueNumber;
              Units[Index]^.Experience:=TUI.Experience;
              Units[Index]^.Kills:=TUI.Kills;
              Change_unit_experience_morale(Units[Index]);
              {doplnit damage na 100%}
              Units[Index]^.Damage:=Unit_types[Units[Index]^.UnitType,
                                               Races[MyRace].Ally].DefenceStrength+
                                    Units[Index]^.DamageBonus;
              Units[Index]^.UpdateDmg:=True;
           end;
        end;

        if (SpecNumber and 15 > 0) then begin
          SpecNumber:=SpecNumber and 15;
          Inc(SpecNumList^[SpecNumber].Count);
          Units[Index]^.SpecNumber:=SpecNumber;
        end;

        if (UnitName <> '') then Units[Index]^.Name:=UnitName;

        if (((TGInfo and 128) = 0) and (Index <> 65535) and (Race <> MyRace))
        then with (Races[Race]) do begin
        { platna cisla TG }
           if (TaskGroups^[TGInfo and 15].Validity) then begin
           { zarad jednotku do existujici TG }
              AssignTaskGroup(Race,TGInfo and 127,Units[Index]);
           end else begin
           { vytvor novou TG s danym cislem }
              if (CreateNewTaskGroup(Race,TGInfo and 127,
                                     Units[Index]) <> (TGInfo and 127))
              then Error(0,'manazer, procedura Load_map - chyba v cislu TG');
           end;
        end; { with (Races[Race]) do begin }

        case (Race) of
          1 : ThisCompRace1:=1;
          2 : ThisCompRace2:=2;
          3 : ThisCompRace3:=3;
          4 : ThisCompRace4:=4;
          5 : ThisCompRace5:=5;
        end;

        if ((UnitType = 2) and (Race <> MyRace))
        then begin
        { recyklatoru narid tezit skladky ! }
           TaskGroupCommand(Race,CreateNewTaskGroup(Race,InvalidTaskGroupNumber,Units[Index]),
                            HarvestCom,0,4,0,0,0)
        end;
      end; { if ((Random(99)+1) <= Num) then begin {}
   end;
   { 2x nevyuzita hodnota }
   CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);

   { xxxxxxx NAHRANI BUDOV xxxxxxxxx}
   CacheBlockRead(InFile,@Pom,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   for I:=1 to Pom do begin
      { 2x reserved }
      CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      { jednotlive udaje budov }
      CacheBlockRead(InFile,@IPos,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@JPos,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@Race,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@BuildingType,1); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);

      { !!!!!!!!! } Inc(BuildingType); { buhvi proc, ale musi to zde byt }

      if (BuildingType <> 11) then begin { ruzne od letiste }
        if (BuildingType > 25) then begin
        { pouze sablony pro computer }
          case (BuildingType) of
             26 : AddFreePlaceForBuilding(Race,IPos,JPos,1,0); { vyrobni }
             27 : AddFreePlaceForBuilding(Race,IPos,JPos,2,0); { nevyrobni }
             28 : AddFreePlaceForBuilding(Race,IPos,JPos,5,0); { letiste }
             29 : AddFreePlaceForBuilding(Race,IPos,JPos,6,0); { radar }
             30 : AddFreePlaceForBuilding(Race,IPos,JPos,7,0); { SAM,L.Pevnost1}
             31 : AddFreePlaceForBuilding(Race,IPos,JPos,8,0); { SAM,L.Pevnost2}
             32 : AddFreePlaceForBuilding(Race,IPos,JPos,9,0); { SAM,L.Pevnost3}
             33 : AddFreePlaceForBuilding(Race,IPos,JPos,10,0);{ R.V,T.Pevnost1}
             34 : AddFreePlaceForBuilding(Race,IPos,JPos,11,0);{ R.V.,T.Pevnost1}
             35 : AddFreePlaceForBuilding(Race,IPos,JPos,12,0);{ R.V.,T.Pevnost1}
             36 : AddFreePlaceForBuilding(Race,IPos,JPos,13,0);{ velka vyrobni}
             37 : AddFreePlaceForBuilding(Race,IPos,JPos,14,0); { velka nevyrobni}
             38 : AddFreePlaceForBuilding(Race,IPos,JPos,15,0); { elektrarna }
             39 : AddFreePlaceForBuilding(Race,IPos,JPos,16,0); { harvestrarna }
             40 : AddFreePlaceForBuilding(Race,IPos,JPos,17,0); { centrum posil }
          else
            Error(0,'manazer, nahravani mapy, chyba v sablonach budov');
          end;
        end else
          New_building(IPos,JPos,BuildingType,Race,True,4,False);
      end else
         New_building(IPos,JPos,BuildingType,Race,True,4,False);
     {end;{}
      case (Race) of
         1 : ThisCompRace1:=1;
         2 : ThisCompRace2:=2;
         3 : ThisCompRace3:=3;
         4 : ThisCompRace4:=4;
         5 : ThisCompRace5:=5;
      end;
   end;
   { 2x nevyuzita hodnota }
   CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);

   { RESOURCE }
   CacheBlockRead(InFile,@X,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   for I:=1 to X do begin
      CacheBlockRead(InFile,@IPos,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@JPos,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
      New_resource(IPos,JPos,Y);
      { reserved : }
      CacheBlockRead(InFile,@Y,2); if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
   end;

   { nyni spocitame celkovy pocet ras roboru a OSN }
   for I:=0 to MaxRace do with (Races[I]) do begin
     if ((I = MyRace) or (I = ThisCompRace1) or (I = ThisCompRace2) or
         (I = ThisCompRace3) or (I = ThisCompRace4) or (I = ThisCompRace5))
     then begin
       case (RaceType) of
         0 : begin Inc(TotalOSNRaces); end;
         1 : begin Inc(TotalOSNRaces); end;
         2 : begin Inc(TotalRobotRaces); end;
         3 : begin Inc(TotalRobotRaces); end;
         4 : begin end;
         5 : begin end;
         6 : begin Inc(TotalOSNRaces); end;
       end;
     end;
   end;

   { VICTORY CONDITIONS }
   CondUk:=-1;
   while (not CacheEof(InFile)) do begin
     Inc(CondUk);
     CacheBlockRead(InFile,@VictoryConditions^[CondUk],SizeOf(TVictoryCond));
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + Way);
     VictoryConditions^[CondUk].Result:=-1;
   end;

   InvalidateCache;
end;

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
     Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
     case (Ch) of
        ';': begin { nasleduje nazev vozidla - vynecha se }
               Inc(Row);
               FileRead(Units_data,Ch,1);
               Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
               while ((Ch <> ' ') and (not Eof(Units_data))) do begin
               { vynech vsechny znaky do mezery }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
               while ((Ch = ' ') and (not Eof(Units_data))) do begin
               { vynech vsechny mezery }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
               UnGet(Units_data);
               Konec:=True;
             end;
        ' ': begin { mezera - vynecha se }
               while ((Ch = ' ') and (not Eof(Units_data))) do begin
               { vynech vsechny mezery }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
               UnGet(Units_data);
             end;
        ':': begin
               { nasleduje cislo }
               FileRead(Units_data,Ch,1);
               Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
               while (Ch in ['0'..'9']) and (not Eof(Units_data)) do begin
               { nacti vsechna cisla }
                  Val(Ch,Num,Pom);
                  Number:=Number*10+Num;
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
               end;
               if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
               if (Ch = '-') then begin { dve cisla, oddelana pomlckou }
                  FileRead(Units_data,Ch,1);
                  Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
                  while (Ch in ['0'..'9']) and (not Eof(Units_data)) do begin
                  { nacti vsechna cisla }
                    Val(Ch,Num,Pom);
                    Number2:=Number2*10+Num;
                    FileRead(Units_data,Ch,1);
                    Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
                  end;
                 if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
               end;
               UnGet(Units_data);
               Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
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
          Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
       end;
       if (Eof(Units_data)) then Writeln(0,'Neocekavany konec souboru');
       UnGet(Units_data);
       Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
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
   Writeln('pracuji...');
   { ENEMY }
   if (MissionNumber < 100) then
     Assign(Units_data,'missions\units'+MissionNameString+'e.dbg')
   else
     Assign(Units_data,'missions\unit'+MissionNameString+'e.dbg');
   Reset(Units_data,1);
   Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
   BlockRead(Units_data,Cach^,FileSize(Units_data));
   EndCach:=FileSize(Units_data);
   CachUk:=0;

   Row:=0;
   while (not Eof(Units_data)) do begin
      Get_Character(Units_data,Row,Number,Number2,Ret);
      if (Ret = 'L1') then begin
         Unit_types[Row,0].LightAttack1:=Number;
      end;
      if (Ret = 'T1') then begin
                  Unit_types[Row,0].HeavyAttack1:=Number;
               end;
      if (Ret = 'A1') then begin
                  Unit_types[Row,0].AirAttack1:=Number;
               end;
      if (Ret = 'DOSTREL1') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types[Row,0].ShootRange1:=Pom;
                    end;
     if (Ret = 'KADENCE1') then begin
                       Unit_types[Row,0].ShootSpeed1:=Number;
                    end;
     if (Ret = 'L2') then begin
                  Unit_types[Row,0].LightAttack2:=Number;
               end;
      if (Ret = 'T2') then begin
                  Unit_types[Row,0].HeavyAttack2:=Number;
               end;
      if (Ret = 'A2') then begin
                  Unit_types[Row,0].AirAttack2:=Number;
               end;
      if (Ret = 'DOSTREL2') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types[Row,0].ShootRange2:=Pom;
                    end;
      if (Ret = 'KADENCE2') then begin
                       Unit_types[Row,0].ShootSpeed2:=Number;
                    end;
      if (Ret = 'OBRANA') then begin
                      Unit_types[Row,0].DefenceStrength:=Number;
                   end;
      if (Ret = 'RYCHLOST') then begin
                       if (Number > 0) then begin
                         Unit_types[Row,0].SpeedLevel:=Number-1;
                         Unit_types[Row,0].MovementAdding:=Speed[Number-1];
                       end;
                 end;
      if (Ret = 'BP') then begin
                  Unit_types[Row,0].BP:=Number;
               end;
      if (Ret = 'PL') then begin
                  Unit_types[Row,0].PL:=Number;
               end;
      if (Ret = 'EE') then begin
                  Unit_types[Row,0].EE:=Number;
               end;
      if (Ret = 'EXP') then begin
                  Unit_types[Row,0].EX:=Number;
                end;{}
      if (Ret = 'PAUSETYPE1') then begin
                  Unit_types[Row,0].ShootType1:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY1') then begin
                  Unit_types[Row,0].ShootDelay1:=Number;
                end;{}
       if (Ret = 'PAUSETYPE2') then begin
                  Unit_types[Row,0].ShootType2:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY2') then begin
                  Unit_types[Row,0].ShootDelay2:=Number;
                end;{}
      if (Ret = 'CAPACITY') then begin
                  Unit_types[Row,0].Capacity:=Number;
                end;{}
      if (Ret = 'SIGHT') then begin
                  Unit_types[Row,0]._Sight:=Number;
                end;{}
   end;
   Close(Units_data); IO_Result:=IOResult;

   { ALLY }
   New(Cach);
   Writeln('pracuji...');
   if (MissionNumber < 100) then
     Assign(Units_data,'missions\units'+MissionNameString+'f.dbg')
   else
     Assign(Units_data,'missions\unit'+MissionNameString+'f.dbg');
   Reset(Units_data,1);
   Result:=IOResult; if (Result <> 0) then Writeln(Result,'Chyba pri praci se souborem units.dbg');
   BlockRead(Units_data,Cach^,FileSize(Units_data));
   EndCach:=FileSize(Units_data);
   CachUk:=0;

   Row:=0;
   while (not Eof(Units_data)) do begin
      Get_Character(Units_data,Row,Number,Number2,Ret);
      if (Ret = 'L1') then begin
         Unit_types[Row,1].LightAttack1:=Number;
      end;
      if (Ret = 'T1') then begin
                  Unit_types[Row,1].HeavyAttack1:=Number;
               end;
      if (Ret = 'A1') then begin
                  Unit_types[Row,1].AirAttack1:=Number;
               end;
      if (Ret = 'DOSTREL1') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types[Row,1].ShootRange1:=Pom;
                    end;
     if (Ret = 'KADENCE1') then begin
                       Unit_types[Row,1].ShootSpeed1:=Number;
                    end;
     if (Ret = 'L2') then begin
                  Unit_types[Row,1].LightAttack2:=Number;
               end;
      if (Ret = 'T2') then begin
                  Unit_types[Row,1].HeavyAttack2:=Number;
               end;
      if (Ret = 'A2') then begin
                  Unit_types[Row,1].AirAttack2:=Number;
               end;
      if (Ret = 'DOSTREL2') then begin
                       asm
                         mov Ah,Number
                         mov Al,Number2
                         mov Pom,Ax
                       end;
                       Unit_types[Row,1].ShootRange2:=Pom;
                    end;
      if (Ret = 'KADENCE2') then begin
                       Unit_types[Row,1].ShootSpeed2:=Number;
                    end;
      if (Ret = 'OBRANA') then begin
                      Unit_types[Row,1].DefenceStrength:=Number;
                   end;
      if (Ret = 'RYCHLOST') then begin
                      if (Number > 0) then begin
                         Unit_types[Row,1].SpeedLevel:=Number-1;
                         Unit_types[Row,1].MovementAdding:=Speed[Number-1];
                       end;
                 end;
      if (Ret = 'BP') then begin
                  Unit_types[Row,1].BP:=Number;
               end;
      if (Ret = 'PL') then begin
                  Unit_types[Row,1].PL:=Number;
               end;
      if (Ret = 'EE') then begin
                  Unit_types[Row,1].EE:=Number;
               end;
      if (Ret = 'EXP') then begin
                  Unit_types[Row,1].EX:=Number;
                end;{}
      if (Ret = 'PAUSETYPE1') then begin
                  Unit_types[Row,1].ShootType1:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY1') then begin
                  Unit_types[Row,1].ShootDelay1:=Number;
                end;{}
       if (Ret = 'PAUSETYPE2') then begin
                  Unit_types[Row,1].ShootType2:=Number;
                end;{}
      if (Ret = 'PAUSEDELAY2') then begin
                  Unit_types[Row,1].ShootDelay2:=Number;
                end;{}
      if (Ret = 'CAPACITY') then begin
                  Unit_types[Row,1].Capacity:=Number;
                end;{}
      if (Ret = 'SIGHT') then begin
                  Unit_types[Row,1]._Sight:=Number;
                end;{}
   end;
   Dispose(Cach); Cach:=Nil;
   Close(Units_data); IO_Result:=IOResult;
end;

{ ***** }
function LoadGameSet:Boolean;
{ vraci True, pokud se podarilo nahrat soubor "game.set"
}
var F:Text;
    CfgFile:File;
    I,J,K:Word;
begin
   for I:=0 to MaxCoreUnits-1 do begin
      CoreInfo[I].UniqueNumber:=65535;
      CoreInfo[I].Destroyed:=False;
   end;
   LoadGameSet:=True;

   Assign(CfgFile,'save\'+PlayerId+'\game.set');
   Reset(CfgFile,1); DResult:=IOResult;
   if (DResult = 2) then begin LoadGameSet:=False; exit; end;
     if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri nahravani souboru game.set'); end;
{x}BlockRead(CfgFile,GlobalModify^,SizeOf(GlobalModify^)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri nahravani souboru game.set'); end;
{x}BlockRead(CfgFile,UnitsInfoRecord,SizeOf(UnitsInfoRecord)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri nahravani souboru game.set'); end;
{x}BlockRead(CfgFile,BuildingsInfoRecord,SizeOf(BuildingsInfoRecord)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri nahravani souboru game.set'); end;
{x}BlockRead(CfgFile,UnAvailUnits,SizeOf(UnAvailUnits)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri nahravani souboru game.set'); end;
{x}BlockRead(CfgFile,GameUniqueNumber,SizeOf(GameUniqueNumber)); DResult:=IOResult;
   if (DResult <> 0) then begin Close(CfgFile); Error(DResult,' pri nahravani souboru game.set'); end;


   for I:=1 to MaxTypesOfUnits do with (Races[MyRace]) do
     if (I in UnAvailUnits) then PermittedUnits[I]:=False;

   { *** uspesne nahrani *** }
   PlayerId:=GlobalModify^.PlayerId; { identifikace hrace }
   { identifikace hry: }
   Game:=GlobalModify^.Game; Campaign:=GlobalModify^.Campaign;
   { modifikace typu jednotek: }
   for J:=0 to 1 do
     for I:=1 to MaxTypesOfUnits do begin
       GlobalModify^.UnitTypes[I,J].Production_time:=Unit_types[I,J].Production_time;
       GlobalModify^.UnitTypes[I,J].MaxPhase:=Unit_types[I,J].MaxPhase;
       GlobalModify^.UnitTypes[I,J].AttackLevel1:=Unit_types[I,J].AttackLevel1;
       GlobalModify^.UnitTypes[I,J].AttackLevel2:=Unit_types[I,J].AttackLevel2;
       GlobalModify^.UnitTypes[I,J].Picture1:=Unit_types[I,J].Picture1;
       GlobalModify^.UnitTypes[I,J].Picture2:=Unit_types[I,J].Picture2;
       GlobalModify^.UnitTypes[I,J].UnitLevel:=Unit_types[I,J].UnitLevel;
       GlobalModify^.UnitTypes[I,J].SpecAirLevel:=Unit_types[I,J].SpecAirLevel;
       GlobalModify^.UnitTypes[I,J].PictureIndex:=Unit_types[I,J].PictureIndex;
       GlobalModify^.UnitTypes[I,J].IUnitSize:=Unit_types[I,J].IUnitSize;
       GlobalModify^.UnitTypes[I,J].JUnitSize:=Unit_types[I,J].JUnitSize;
       GlobalModify^.UnitTypes[I,J].XUnitSize:=Unit_types[I,J].XUnitSize;
       GlobalModify^.UnitTypes[I,J].YUnitSize:=Unit_types[I,J].YUnitSize;
       GlobalModify^.UnitTypes[I,J].Presah:=Unit_types[I,J].Presah;
       GlobalModify^.UnitTypes[I,J].Build:=Unit_types[I,J].Build;
       for K:=1 to 8 do begin
         GlobalModify^.UnitTypes[I,J].FlashPos[K].X:=Unit_types[I,J].FlashPos[K].X;
         GlobalModify^.UnitTypes[I,J].FlashPos[K].Y:=Unit_types[I,J].FlashPos[K].Y;
       end;
       GlobalModify^.UnitTypes[I,J].Parent:=Unit_types[I,J].Parent;
     end;

   Unit_types:=GlobalModify^.UnitTypes;
   { nasledujici promenne urcuji pritomnost jednotek
     s nastavenym nejvyssim bitem SpecNumber: }
   FriendlySpecialUnitsPresent:=GlobalModify^.FriendlySpecialUnitsPresent;
   EnemySpecialUnitsPresent:=GlobalModify^.EnemySpecialUnitsPresent;
   { True pro pritomnost spec. nepratelskych posil }
   EnemySpecialReinforcementPresent:=GlobalModify^.EnemySpecialReinforcementPresent;

   ActionLevel:=GlobalModify^.ActionLevel; { typ hry }
   GameLevel:=GlobalModify^.GameLevel;   { obtiznost hry }
   { nyni schema pro nasledujici hodnoty:
     0..False, 1..True, > 1..nezmeneno }
   if (GlobalModify^.UnknownTerrain <= 1) then begin
       if (GlobalModify^.UnknownTerrain = 0)
       then Unknown_terrain:=True else Unknown_terrain:=False;
   end;
   if (GlobalModify^.FogOfWar <= 1) then begin
       if (GlobalModify^.FogOfWar = 0)
       then Fog_of_war:=True else Fog_of_war:=False;
   end;
   if (GlobalModify^.AllyFog <= 1) then begin
       if (GlobalModify^.AllyFog = 0)
       then AllyFog:=True else AllyFog:=False;
   end;
   { modifikatory typu rasy: bud hodnota, nebo 255=zustat nezmenene }
   for I:=0 to MaxRace do _RaceType[I]:=GlobalModify^.RaceTypeModifiers[I];
   { modifikatory materialu v misi :
     bud hodnota zmeny v %, nebo MaxInt=zustat nezmenene }
   for I:=0 to MaxRace do
   with (GlobalModify^.RaceMaterialModifiers[I]) do begin
     if (BPModif < MaxInt) then begin
       Races[I].Building_credits:=Races[I].Building_credits+
                                  Round(((1.0*Races[I].Building_credits)/100)*BPModif);
     end;
     if (PLModif  < MaxInt) then begin
       Races[I].Plastic_credits:=Races[I].Plastic_credits+
                                  Round(((1.0*Races[I].Plastic_credits)/100)*PLModif);
     end;
     if (EEModif  < MaxInt) then begin
       Races[I].Electric_energy:=Races[I].Electric_energy+
                                  Round(((1.0*Races[I].Electric_energy)/100)*EEModif);
     end;
     if (ExpModif < MaxInt) then begin
       Races[I].Battle_experience:=Races[I].Battle_experience+
                                   Round(((1.0*Races[I].Battle_experience)/100)*ExpModif);
     end;
   end;
   {X}
   for I:=0 to MaxRace do begin
     if (GlobalModify^.RaceInitLevelModifier[I] <> 255) then
        Races[I].InitUnitLevel:=Races[I].InitUnitLevel+
                                GlobalModify^.RaceInitLevelModifier[I];
   end;
   {X}
   for I:=0 to MaxCoreUnits-1 do begin
      CoreInfo[I]:=GlobalModify^.CoreInfo[I];
      if (not CoreInfo[I].Active) then CoreInfo[I].UniqueNumber:=65535;
      CoreInfo[I].Destroyed:=False;
   end;
   { *** konec prenosu dat *** }

   Close(CfgFile); DResult:=IOResult;
{   Erase(CfgFile); DResult:=IOResult;{}

{   Assign(F,'__00.par');
   ReWrite(F);
   for I:=1 to MaxTypesOfUnits do
   with (Unit_types[I,1]) do begin
      Writeln(F,'*****************************************************');
      Writeln(F,'Jednotka: '+Name+' - ',I);
      Write(F,'BP:',BP);Write(F,' PL:',PL);Write(F,' EE:',EE);Writeln(F,' Ex:',Ex);
      Write(F,'L1, H1, A1: ',LightAttack1,'-',HeavyAttack1,'-',AirAttack1);
      Write(F,'    ShootRange1: ',Hi(ShootRange1),'-',Lo(ShootRange1));
      Writeln(F,'    ShootSpeed1: ',ShootSpeed1);
      Write(F,'L2, H2, A2: ',LightAttack2,'-',HeavyAttack2,'-',AirAttack2);
      Write(F,'    ShootRange2: ',Hi(ShootRange2),'-',Lo(ShootRange2));
      Writeln(F,'    ShootSpeed2: ',ShootSpeed2);
      Write(F,'Defence: ',DefenceStrength);
      Write(F,'    SpeedLevel: ',SpeedLevel);
      Write(F,'    Sight: ',Sight);
      Writeln(F,'    Autorepair: ',Autorepair);
   end;
   Close(F); {}
end;

{ ***** }
procedure Init_game;
{ provede vsechny potrebne pocatecni inicializace
}
var I,J:Integer;
    Pom:Byte;
    MaxRes:Word;
begin
   Randomize; ActionLevel:=4;
   GetMaxRes(MaxRes);
   case (MaxRes) of
     0 : begin
           XResolution:=640; YResolution:=480;
         end;
   else
      XResolution:=800; YResolution:=600;
   end;

   IBeg:=0; JBeg:=0;  { aktualni pozice obrazovky na mape }
   { z deviti pametovych obrazovek (3x3) se zvoli ta prostredni :
   }
   XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
   YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
   IMemPom:=IScreenSize; JMemPom:=JScreenSize;

   LoadGameCfg;
   SoundInit;
   Init_gr_mode(XResolution,YResolution); { grafika }
   {Map_init('data\map.m01');{}
   M:=GetFreeMem;
   if (InternalCache) then
     if (not CacheInit) then Error(0,'Nedostatek pameti pro vnitrni cache');

   Init_races; { races }
   ReadProductionSpeed(MissionNumber); { _units4 }
   Load_cfg('missions\mapa'+MissionNameString+'.cfg');{ unita _units3 }
   Init_gr_data; { grafika3 }
   Init_units; { _units3 }
   Init_units2; { _units3 }
   for I:=0 to MaxRace do _RaceType[I]:=255;
   if (MissionNumber < 100) then begin
     if (not LoadGameSet) then begin
       if (not Debug) then Error(255,'CHYBA V GAME.SET');{}
       BuildInfoRecord;
       Get_units_data;{}
     end;
   end else begin
     BuildInfoRecord;
     Get_units_data;
   end;
   if (Campaign = 2) then begin{}
      case (MissionNumber) of
         53 : begin
                Pom:=Races[0].RaceColor;
                Races[0].RaceColor:=Races[5].RaceColor;
                Races[5].RaceColor:=Pom;
                Pom:=Races[1].RaceColor;
                Races[1].RaceColor:=Races[3].RaceColor;
                Races[3].RaceColor:=Pom;
              end;
         65 : begin
                Pom:=Races[0].RaceColor;
                Races[0].RaceColor:=Races[5].RaceColor;
                Races[2].RaceColor:=Races[4].RaceColor;
                Races[4].RaceColor:=Races[1].RaceColor;
                Races[1].RaceColor:=Pom;
              end;
         66 : begin
                Pom:=Races[0].RaceColor;
                Races[0].RaceColor:=Races[5].RaceColor;
                Races[2].RaceColor:=Races[4].RaceColor;
                Races[4].RaceColor:=Races[1].RaceColor;
                Races[1].RaceColor:=Pom;
              end;
         67 : begin
                Pom:=Races[0].RaceColor;
                Races[0].RaceColor:=Races[5].RaceColor;
                Races[2].RaceColor:=Races[4].RaceColor;
                Races[4].RaceColor:=Races[1].RaceColor;
                Races[1].RaceColor:=Pom;
              end;
      else
        Pom:=Races[0].RaceColor; Races[0].RaceColor:=Races[5].RaceColor;
        Races[5].RaceColor:=Pom;
      end;
   end;{}
   Init_buildings; { _buildings }
   Init_shots; { shots }
   SetActionLevel(ActionLevel); { unita _races - LZE NAVOLIT POUZE 1x NA
                                  ZACATKU HRY !!! (!nelze menit v prubehu!) }
   Init_races2;

   Load_map('missions\mapa'+MissionNameString+'.m01');{}
   CursorOff;
   RadarInit;
   CursorOn;
   UnitParamsInit; { parametry jednotek; MUSI BYT AZ ZA VSEMI
                     INICIALIZACEMI JEDNOTEK }
   { souradnice pro pole umele inteligence }
   IMapInfoMax:=IMax div IInfoDiv-1;
   if (IMax mod IInfoDiv <> 0) then Inc(IMapInfoMax);
   JMapInfoMax:=JMax div JInfoDiv-1;
   if (JMax mod JInfoDiv <> 0) then Inc(JMapInfoMax);

   CursorOff;
   Draw_map_frame(IBeg,IBeg+IScreenSize,JBeg,JBeg+JScreenSize);
   Draw_screen(IBeg,JBeg,0,0);
   Retreat:=False; { True = aktivovany ustup ze hry }
   RetreatTimmer:=0; { az je na nule, ustup (hra) konci }
   DResult:=IOResult;
   Assign(IOFile,'save\'+PlayerId+'\continue'); Reset(IOFile,1); DResult:=IOResult;
   if (DResult <> 0) then begin
      Assign(IOFile,'save\'+PlayerId+'\$$$'); Reset(IOFile,1); DResult:=IOResult;
      if (DResult <> 0) then begin
         PrintMissionGoal('missions\brief'+MissionNameString);
      end;
   end;
   Close(IOFile); DResult:=IOResult;
   { vypise cile mise }
   for J:=0 to MaxRace do
     for I:=0 to MaxRaceTaskGroups do begin
       if ((I <= 7) or (I = 10))
       then RacesTGInfo^[J,I].MaxAirPct:=Rand(RndUk)*5+40
       else RacesTGInfo^[J,I].MaxAirPct:=100;
   end;
   ScreenOn;
   CursorOn;
end;

{ ***** }
procedure Saving;
{ ulozi hru
}
label K;
begin
   Assign(CheckFile,'save\'+SavePath+'check'); ReWrite(CheckFile,1); DResult:=IOResult;
   Close(CheckFile);
   { existence souboru check znaci OK, jinak jde o chybu }
   Graph257_save; {1 x}
   Data_save;     {2 x}
   Grafika_save;  {3 x}
   Grafika2_save; {4 x}
   Grafika3_save; {5 x}
   Grafika4_save; {6 x}
   _units_save;   {7 x}
   _units2_save;  {8 x}
   _units3_save;  {9 x}
   _buildin_save; {10x}
   Buttons_save;  {11x}
   Buttons2_save; {12x}
   _shot_save;    {13x}
   _races_save;   {14x}
   Mouse_save;    {15x}
   AI_save;       {16x}
   AI2_save;      {17x}
   SBSound_save;  {18x}
   _units4_save;  {21x}
   {+ manazer.save: }
   Reset(CheckFile,1); DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   { existence souboru check znaci OK, jinak jde o chybu }
   Assign(IOFile,'save\'+SavePath+'20'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Speed,SizeOf(Speed));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,GAMETIME,SizeOf(GAMETIME));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,POMTIME,SizeOf(POMTIME));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
   Close(IOFile); Close(CheckFile); DResult:=IOResult;
   if (DResult <> 0) then OutBigMsg(255,'CHYBA PRI UKLADANI HRY!');
end;

{ ***** }
procedure Loading;
{ nahraje hru
}
label K;
begin
   { pozn. Building_types se neuklada !!!! }
{   Disband_units; {}
{   Finish_shots;{}
 {  Destroy_buildings;{}

   Assign(CheckFile,'save\'+SavePath+'check');
   Graph257_load; {1 x}
   Reset(CheckFile,1); DResult:=IOResult; { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then Error(0,'Chyba pri nahravani hry - 1');
   Data_load;     {2 x}
   Reset(CheckFile,1); DResult:=IOResult; { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then Error(0,'Chyba pri nahravani hry - 2');
   Grafika_load;  {3 x}
   Grafika2_load; {4 x}
   Grafika3_load; {5 x}
   Grafika4_load; {6 x}
   Reset(CheckFile,1); DResult:=IOResult; { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then Error(0,'Chyba pri nahravani hry - 3');
   _units_load;   {7 x}
   _units2_load;  {8 x}
   _units3_load;  {9 x}
   _buildin_load; {10x}
   Reset(CheckFile,1); DResult:=IOResult; { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then Error(0,'Chyba pri nahravani hry - 4');
   Buttons_load;  {11x}
   Buttons2_load; {12x}
   _shot_load;    {13x}
   _races_load;   {14x}
   Reset(CheckFile,1); DResult:=IOResult; { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then Error(0,'Chyba pri nahravani hry - 5');
   Mouse_load;    {15x}
   AI_load;       {16x}
   AI2_load;      {17x}
   SBSound_load;  {18x}
   _units4_load;  {21x}
   {+ manazer.load: }
   Reset(CheckFile,1); DResult:=IOResult; { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then Error(0,'Chyba pri nahravani hry- 6');
   Assign(IOFile,'save\'+SavePath+'20'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Speed,SizeOf(Speed));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GAMETIME,SizeOf(GAMETIME));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,POMTIME,SizeOf(POMTIME));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

  GetMaxRes(MaxRes);
   case (MaxRes) of
     0 : begin
            if (XResolution > 640) then begin
              XResolution:=640; YResolution:=480;
            end;
         end;
     1 : begin
            if (XResolution > 800) then begin
              XResolution:=800; YResolution:=600;
            end;
         end;
     2 : begin
           if (XResolution > 1024) then begin
              XResolution:=1024; YResolution:=768;
            end;
         end;
     3 : begin { maximum, bez omezeni }
         end;
   else
     XResolution:=640; YResolution:=480;
   end;
   New_graphics_mode(XResolution,YResolution);{}
   Print_game_time(True); {SetActionLevel(ActionLevel);{}
K:
   Close(IOFile); Close(CheckFile);  DResult:=IOResult;
   if (DResult <> 0) then OutBigMsg(255,'CHYBA PRI NAHRAVANI HRY!');
{   Assign(ErFile,'unit.log'); Reset(ErFile,1); IO_Result:=IOResult;
   BlockRead(ErFile,Units[289]^,SizeOf(Units[289]^)); IO_Result:=IOResult;
   Close(ErFile);{}
end;

{ ***** }
procedure DebugMsg;
var Ret:String;
begin
{   if (Debug) then begin
     Str(GlobalStep,Ret);
     OutBigMsg(255,'GLOBALSTEP: '+Ret);
   end;{}
end;

{ ***** }
procedure Play_game;
{ realizuje vlastni hru
}
var Character,A,B:Byte;
    I,J,K,Index:Word;
    Pom, Pomocn:LongInt;
    X,Y:Word;
    Ret, Ret2:String;
    Max1, Max2, Max3, Max4:Word;
begin
   TimeSlot:=256;
   EndOfGame:=False; EndOfGameChanged:=False;

   RealTimeScroll:=False;
   MyRaceType:=Races[MyRace].RaceType;

   Print_material(1,Races[MyRace].Building_credits);
   Print_material(2,Races[MyRace].Plastic_credits);
   Print_material(3,Races[MyRace].Electric_energy);
   Print_material(4,Races[MyRace].Battle_experience);
   GlobalStep:=30000; Globa_eval; GlobalStep:=30000;

   { nyni nulovani modifikatoru moralky }
    for I:=0 to IInfoArraySize-1 do
     for J:=0 to IInfoArraySize-1 do begin
       for K:=0 to MaxRace do  MapInfo^[I,J].MoraleModifier[K]:=0;
     end;
   { * }

   { vypocteni prumerne ceny }
   for J:=0 to MaxRace do with Races[J] do begin
       BPUnitCostAver:=0; PLUnitCostAver:=0; EEUnitCostAver:=0; EXUnitCostAver:=0;
       BPBuildCostAver:=0; PLBuildCostAver:=0; EEBuildCostAver:=0; EXBuildCostAver:=0;
       { nasledujici promenne "odfiltruji" maximalni hodnoty }
       Max1:=0; Max2:=0; Max3:=0; Max4:=0;
       Index:=0;
       for I:=1 to MaxTypesOfUnits do if (PermittedUnits[I]) then
       with (Unit_types[I,1]) do begin
         if ((BP <> 0) or (PL <> 0) or (EE <> 0) or (EX <> 0)) then begin
           if (BP > Max1) then Max1:=BP; if (PL > Max2) then Max2:=PL;
           if (EE > Max3) then Max3:=EE; if (Ex > Max4) then Max4:=Ex;
           Inc(BPUnitCostAver,BP);  Inc(PLUnitCostAver,PL);
           Inc(EEUnitCostAver,EE);  Inc(EXUnitCostAver,EX);
           Inc(Index);
         end;
       end;
       Dec(Index);
       if (Index <> 0) then BPUnitCostAver:=(BPUnitCostAver-Max1) div Index;
       if (Index <> 0) then PLUnitCostAver:=(PLUnitCostAver-Max2) div Index;
       if (Index <> 0) then EEUnitCostAver:=(EEUnitCostAver-Max3) div Index;
       if (Index <> 0) then ExUnitCostAver:=(ExUnitCostAver-Max4) div Index;

       Index:=0;
       Max1:=0; Max2:=0; Max3:=0; Max4:=0;
       for I:=1 to MaxTypesOfBuildings do if (PermittedBuildings[I]) then
       with (Building_types[I]) do begin
         if ((BP <> 0) or (PL <> 0) or (EE <> 0) or (EX <> 0)) then begin
           if (BP > Max1) then Max1:=BP; if (PL > Max2) then Max2:=PL;
           if (EE > Max3) then Max3:=EE; if (Ex > Max4) then Max4:=Ex;
           Inc(BPBuildCostAver,BP);  Inc(PLBuildCostAver,PL);
           Inc(EEBuildCostAver,EE);  Inc(EXBuildCostAver,EX);
           Inc(Index);
         end;
       end;
       if (Index <> 0) then BPBuildCostAver:=(BPBuildCostAver-Max1) div Index;
       if (Index <> 0) then PLBuildCostAver:=(PLBuildCostAver-Max2) div Index;
       if (Index <> 0) then EEBuildCostAver:=(EEBuildCostAver-Max3) div Index;
       if (Index <> 0) then ExBuildCostAver:=(ExBuildCostAver-Max4) div Index;
   end;
   { ------------------------------------------------- }

   Inc(TimeSlot);
   GetSpecKeysState;

   RadarBlinkTimming:=1;
   {"OCHRANNA BARIERA"}
   PutMemory(5,SPom,OPom);

   PlaySound(7,0,0,0);

   { *** }
   if (not Debug) then begin
      DResult:=IOResult;
      Assign(IOFile,'save\'+PlayerId+'\continue'); Reset(IOFile,1); DResult:=IOResult;
      if ((MissionNumber < 100) and (DResult = 0) and (ParamCount < 3)) then begin{}
        Close(IOFile); DResult:=IOResult; Erase(IOFile); DResult:=IOResult;
        SavePath:=PlayerId+'\'+'cont\';
        LoadGame:=0;
        Loading;
        SavePath:='';
      end else begin
        Close(IOFile); DResult:=IOResult;
        Erase(IOFile); DResult:=IOResult;
      end;{}
   end;
   { *** }
   if (not Debug) then begin
      DResult:=IOResult;
      Assign(IOFile,'save\'+PlayerId+'\$$$'); Reset(IOFile,1); DResult:=IOResult;
      if ((DResult = 0) and (ParamCount < 3)) then begin{}
        Close(IOFile); DResult:=IOResult; Erase(IOFile); DResult:=IOResult;
        SavePath:=PlayerId+'\'+'autosave\';
        LoadGame:=0;
        Loading;
        SavePath:='';
      end else begin
        Close(IOFile); DResult:=IOResult;
        Erase(IOFile); DResult:=IOResult;
      end;{}
   end;
   { *** }
   Assign(IOFile,'save\'+PlayerId+'\$$$'); Rewrite(IOFile,1); DResult:=IOResult; Close(IOFile); DResult:=IOResult;
   { *** }

   while (not EndOfGame) do begin
       {if (TimeSlot = 600) then Halt(2);{}
       if (TimeSlot < 65535) then Inc(TimeSlot) else TimeSlot:=257;
       { preskocime cislo, ktere je mozne splest si s recover }
       TimerOn;

       if (RadarBlinkTimming = 1) then begin
         GetRGB(Races[MyRace].RaceColor,R,G,B);
         SetRGB(RadarBlinkColor,R,G,B);
       end else
          if (RadarBlinkTimming = 2) then begin
            SetRGB(RadarBlinkColor,63,20,20);
          end else
             if (RadarBlinkTimming = 3) then
               SetRGB(RadarBlinkColor,0,0,0)
             else
               if (RadarBlinkTimming = 5) then
                 SetRGB(RadarBlinkColor,63,63,63)
               else
                 if (RadarBlinkTimming = 7) then RadarBlinkTimming:=0;
       Inc(RadarBlinkTimming); {}
       GlobalStep:=65535; DebugMsg;{x}
       IBegPom:=IBeg; JBegPom:=JBeg;
       {x}
       {if (TimeSlot = 42588) then begin
         New(Units[21]);
         Assign(ErFile,'unit.log'); Reset(ErFile,1); IO_Result:=IOResult;
         BlockRead(ErFile,Units[21]^,SizeOf(Units[21]^)); IO_Result:=IOResult;
         Close(ErFile);
       end;{}
       if (Slow and (TimeSlot mod 2 = 0)) then Unit_manager_only_draw
       else Unit_manager;
       {x}GlobalStep:=1;DebugMsg;{x}
       for I:=0 to MaxRace do begin
          Races[I].GlobalMorale:=Races[I].GlobalMoraleTemp;
          Races[I].GlobalMoraleTemp:=0;
          { kazdych 5 minut trochu dopomuzeme pocitaci s plasty }
          if ((I <> MyRace) and (Min_game_time mod 5 = 0) and
              (Sec_game_time = 0) and (Races[I].Plastic_credits <= 25))
          then Races[I].Plastic_credits:=Races[I].Plastic_credits+20;
       end;
       { nyni nulovani globalnich modifikatoru moralky }
       { >> neco se nachazi v AI.AI_manager }
       if (Slow and (TimeSlot mod 2 = 0)) then
       else Shot_manager; {x}GlobalStep:=2;DebugMsg;{x}
       if (Slow and (TimeSlot mod 2 = 0)) then Building_manager_only_draw
       else Building_manager;
       {x}GlobalStep:=3;DebugMsg;{x}
       MaintainMsg; {x}GlobalStep:=4;DebugMsg;{x}
       DebrisManager;{}  {x}GlobalStep:=5;DebugMsg;{x}
       SetTerminator_fighterParams(True);
       AI_manager;{} {x}GlobalStep:=7;DebugMsg;{x}
       SetTerminator_fighterParams(False);
       Mouse_keyboard_manager; {x}GlobalStep:=6;DebugMsg;{x}
       Ok_atack_cursor_mark_manager;  {x}GlobalStep:=8;DebugMsg;{x}
       Unit_building_shadow_manager; {} {x}GlobalStep:=9;DebugMsg;{x}
       PrintRealTime; {x}GlobalStep:=10;DebugMsg;{x}
       ReinfoManager; {} {x}GlobalStep:=11;DebugMsg;{x}
       ExecutePlaySound; {x}GlobalStep:=12;DebugMsg;{x}
       BuildingSoundManager; {x}GlobalStep:=17;DebugMsg;{x}
       VictoryConditionManager; {x}GlobalStep:=13;DebugMsg;{x}
       RepairQueue^.Work; { unita AI3 }  {x}GlobalStep:=14;DebugMsg;{x}
       GraphQueue.Work; { unita grafika } {x}GlobalStep:=15;DebugMsg;{x}
       GraphQueue.Transfer; { unita grafika }  {x}GlobalStep:=16;DebugMsg;{x}
       if (AnimatedCursor > 0) then CursorManager;{} {x}GlobalStep:=171;DebugMsg;{x}
       MissionSpecManager; {x}GlobalStep:=172;
       {if (ChangeRGB = 3) then begin
         SetRGB(241,0,0,0);
         SetRGB(242,0,0,0);
       end else begin
         if (ChangeRGB >= 6) then begin
           SetRGB(241,64,64,64);
           SetRGB(242,64,64,64);
           ChangeRGB:=0;
         end;
       end;
       Inc(ChangeRGB);{}

       if (Slow and (TimeSlot mod 2 = 0)) then
       else begin
         if (GameTimming = 0) then Inc(Flag_game_time,2)
         else Inc(Flag_game_time);
       end;
       Print_game_time(False);
       if (PressedKey = $78) then begin  { alt 1 - restore }
          Altpress;{}
       end else
         if (PressedKey = $01) then begin
            EndOfGame:=True;
            Assign(IOFile,'save\'+PlayerId+'\continue'); Rewrite(IOFile,1); DResult:=IOResult;
            BlockWrite(IOFile,Game,SizeOf(Game)); DResult:=IOResult;{}
            Close(IOFile); DResult:=IOResult;
            SavePath:=PlayerId+'\'+'cont\';
            EndOfGame:=False; Saving; EndOfGame:=True;
            SavePath:='';
         end else
           if (PressedKey = $68) then begin
           { alt F1 - REFRESH }
             New_graphics_mode(XResolution,YResolution);
            end else
             if (PressedKey = $72) then SaveScreen { ctrl+PrtScr }
             else {if (PressedKey = $17) then begin { I = info }
                  {   GetXYMouse(X,Y);
                     X:=((X-XScreenBeg) shr XCellShl+IBeg) div IInfoDiv;
                     Y:=((Y-YScreenBeg) shr YCellShl+JBeg) div JInfoDiv;
                     Str(X,Ret2); Ret:=Ret2;
                     Str(Y,Ret2); Ret:=Ret+' x '+Ret2;
                     OutBigMsg(255,'POZICE: '+Ret);
                     Frame2(XRadarRealBeg+X*IInfoDiv,YRadarRealBeg+Y*JInfoDiv,
                                XRadarRealBeg+(X+1)*IInfoDiv,YRadarRealBeg+(Y+1)*JInfoDiv,48);
                  end else {}
                    if (ALT and Debug) then begin { Alt }
                      for I:=0 to IInfoArraySize-1 do
                        for J:=0 to JInfoArraySize-1 do with (MapInfo^[I,J]) do begin
                           if (not (Pruchozi)) then begin
                              Frame2(XRadarRealBeg+I*IInfoDiv,YRadarRealBeg+J*JInfoDiv,
                                     XRadarRealBeg+(I+1)*IInfoDiv,YRadarRealBeg+(J+1)*JInfoDiv,32);
                           end;
                        end;
                    end;

      if (PressedKey = $17) then SpecialUnitInfo;
      if ((PressedKey >= $3b) and (PressedKey <= $40) and Debug) then begin
      { info o rasach }
        case (PressedKey-$3b) of
           0 : if (ThisCompRace1 <> 255) then begin
                  OutBigMsg(255,'MATERIALY RASY 1'); MaterInfoSwitch:=1;
               end;
           1 : if (ThisCompRace2 <> 255) then begin
                  OutBigMsg(255,'MATERIALY RASY 2'); MaterInfoSwitch:=2;
               end;
           2 : if (ThisCompRace3 <> 255) then begin
                  OutBigMsg(255,'MATERIALY RASY 3'); MaterInfoSwitch:=3;
               end;
           3 : if (ThisCompRace4 <> 255) then begin
                  OutBigMsg(255,'MATERIALY RASY 4'); MaterInfoSwitch:=4;
               end;
                          4 : if (ThisCompRace5 <> 255) then begin
                  OutBigMsg(255,'MATERIALY RASY 5'); MaterInfoSwitch:=5;
               end;
           5 : begin
                  OutBigMsg(255,'MATERIALY ME RASY'); MaterInfoSwitch:=0;
               end;
        end;
      end;

      {if (UpdateEEEnergy) then Print_material(3,Races[MyRace].Electric_energy);
      if (UpdatePL) then Print_material(2,Races[MyRace].Plastic_credits);
      if (UpdateBP) then Print_material(1,Races[MyRace].Building_credits);
      if (UpdateEXP) then Print_material(4,Races[MyRace].Battle_experience);{}
      { UVIDIME MATERIAL RASY, RIZENE UMELOU INTELIGENCI }
      Print_material(3,Races[MaterInfoSwitch].Electric_energy);
      Print_material(2,Races[MaterInfoSwitch].Plastic_credits);
      Print_material(1,Races[MaterInfoSwitch].Building_credits);
      Print_material(4,Races[MaterInfoSwitch].Battle_experience);{}

      PressedKey:=0;
      UpdateEEEnergy:=False; UpdatePL:=False; UpdateBP:=False; UpdateEXP:=False;

     for I:=0 to IInfoArraySize-1 do
       for J:=0 to JInfoArraySize-1 do with (MapInfo^[I,J]) do begin
            SAVE1:=i; Save2:=J;
            for K:=0 to 2 do if (VLLight[K] > 200) then VLLight[K]:=0;
            for K:=0 to 2 do if (VLight[K] > 200) then VLight[K]:=0;
            for K:=0 to 2 do if (VHeavy[K] > 200) then VHeavy[K]:=0;
            for K:=0 to 2 do if (VAir[K] > 200) then VAir[K]:=0;
            for K:=0 to 2 do if (VAAttack[K] > 200) then VAAttack[K]:=0;

            for K:=0 to 2 do if (HLLight[K] > 200) then HLLight[K]:=0;
            for K:=0 to 2 do if (HLight[K] > 200) then HLight[K]:=0;
            for K:=0 to 2 do if (HHeavy[K] > 200) then HHeavy[K]:=0;
            for K:=0 to 2 do if (HAir[K] > 200) then HAir[K]:=0;
            for K:=0 to 2 do if (HAAttack[K] > 200) then HAAttack[K]:=0;

            for K:=0 to 2 do if (EnemyVLLight[K] > 200) then EnemyVLLight[K]:=0;
            for K:=0 to 2 do if (EnemyVLight [K] > 200) then EnemyVLight [K]:=0;
            for K:=0 to 2 do if (EnemyVHeavy [K] > 200) then EnemyVHeavy [K]:=0;
            for K:=0 to 2 do if (EnemyVAir   [K] > 200) then EnemyVAir   [K]:=0;
            for K:=0 to 2 do if (EnemyVAAttack[K] > 200) then EnemyVAAttack[K]:=0;

            for K:=0 to 2 do if (EnemyHLLight [K] > 200) then EnemyHLLight [K]:=0;
            for K:=0 to 2 do if (EnemyHLight  [K] > 200) then EnemyHLight  [K]:=0;
            for K:=0 to 2 do if (EnemyHHeavy  [K] > 200) then EnemyHHeavy  [K]:=0;
            for K:=0 to 2 do if (EnemyHAir    [K] > 200) then EnemyHAir    [K]:=0;
            for K:=0 to 2 do if (EnemyHAAttack[K] > 200) then EnemyHAAttack[K]:=0;

            {if (FriendlyBuildingsNum > 200) then Error(I+100*J,'blee 21');
            if (FriendlyBuildingsWeight > 60000) then Error(I+100*J,'blee 22');
            if (EnemyVBuildingsNum   > 200) then Error(I+100*J,'blee 23');
            if (EnemyVBuildingsWeight   > 60000) then Error(I+100*J,'blee 24');
            if (EnemyHBuildingsNum   > 200) then Error(I+100*J,'blee 25');
            if (EnemyHBuildingsWeight   > 60000) then Error(I+100*J,'blee 26');{}
       end;{}

     if (AUTOSAVE > 0) then begin
        if (Debug{}) then begin
             if (TimeSlot mod 70 = 0) then begin
                SavePath:=PlayerId+'\'+'autosave\';
                Saving;
                SavePath:='';
             end;
        end else begin
           if (AUTOSAVE = 1) then begin { rychle }
             if ((TimeSlot mod 1500 = 0) or ((not Debug) and (TimeSlot = 257))) then begin
                 SavePath:=PlayerId+'\'+'autosave\';
                 Saving;
                 SavePath:='';
             end;
           end else begin
             if ((TimeSlot mod 2500 = 0) or ((not Debug) and (TimeSlot = 257))) then begin
                SavePath:=PlayerId+'\'+'autosave\';
                Saving;
                SavePath:='';
             end;
           end;
        end;
     end;{}

     GlobalStep:=34;DebugMsg;{x}

     {x}
     Inc(GameStopCountTimmer);
     if (GameStopCountTimmer > 2500) then begin
       Inc(GameStopCount);
       if (GameStopCount > 3) then GameStopCount:=3
       else begin
         Str(GameStopCount,Ret);
         ButtonText(StopButton,15,'('+Ret+')');
         CursorOff;
         SetActive(StopButton);
         Release(StopButton);
         CursorOn;
       end;
       GameStopCountTimmer:=0;
     end;
     GlobalStep:=35; DebugMsg;{x}
     if (EndOfGameTimmer > 0) then begin
       if (Random(RndUk) < 7) then
          EndOfGameTimmer:=EndOfGameTimmer+1;
       if (EndOfGameTimmer > 40) then EndOfGame:=True;
     end;
     GlobalStep:=36; DebugMsg;{x}

     { SYNCHRONIZACE }
     { SYNCHRONIZACE }
     { SYNCHRONIZACE }

     TimerWait; { synchronizace }

     { SYNCHRONIZACE }
     { SYNCHRONIZACE }
     { SYNCHRONIZACE }

     while (GameStopped) do begin
       TimerOn;
       Unit_manager_only_draw;
       Building_manager_only_draw;
       Ok_atack_cursor_mark_manager;
       Unit_building_shadow_manager;
       Mouse_keyboard_manager;
       ExecutePlaySound; {x}
       RepairQueue^.Work; { unita AI3 }
       GraphQueue.Work; { unita grafika }
       GraphQueue.Transfer; { unita grafika }
       if (AnimatedCursor > 0) then CursorManager;{}
       TimerWait;{}
     end;

     if (MenuActive) then begin
        MenuActive:=False;
        StopSound(10);
        MenuOptions; { unita Grafika2 }
        if (EndOfGameChanged) then begin
           Assign(IOFile,'save\'+PlayerId+'\continue'); Rewrite(IOFile,1); DResult:=IOResult;
           BlockWrite(IOFile,Game,SizeOf(Game)); DResult:=IOResult;{}
           Close(IOFile); DResult:=IOResult;
           SavePath:=PlayerId+'\'+'cont\';
           EndOfGame:=False; Saving; EndOfGame:=True;
           SavePath:='';
        end;
        SaveGameCfg;
        PlaySound(7,0,0,0);
        if (SaveGame > 0) then begin
           if (SaveGame = 255) then SavePath:=PlayerId+'\'+'autosave\'
           else SavePath:=PlayerId+'\';
           SaveGame:=0;
           Saving;
           SavePath:='';
        end;
        if (LoadGame > 0) then begin
           if (LoadGame = 255) then SavePath:=PlayerId+'\'+'autosave\'
           else SavePath:=PlayerId+'\';
           LoadGame:=0;
           Loading;
           SavePath:='';
        end;
     end;
     if (Retreat) then begin
       if (RetreatTimmer = 0) then EndOfGame:=True
       else Dec(RetreatTimmer);
     end;
   end;
end;

{ ************************************************************************ }
begin
   asm
     mov Ah,03h
     mov Al,5h
     mov Bl,0 { typematic rate }
     mov Bh,0 { delay rate }
     int 16h
   end;

   if ((ParamCount > 2) or (ParamCount < 1)) then MissionNameString:='0'
   else begin
      MissionNameString:=ParamStr(1);
   end;
   Val(MissionNameString,MissionNumber,J);
   if (J <> 0) then begin
     Writeln('!! CHYBA V CISLE MISE !!');
     Halt;
   end;
   if (ParamCount = 2) then PlayerId:=ParamStr(2) else PlayerId:='SINGLE';

   { xxxxxxxxxxxxxxxxxxxxxx INICIALIZACNI DATA xxxxxxxxxxxxxxxxxxxxxxxxxxxxx }
   {!!!}Debug:=False; { True pro ladici verzi; zapne ladici informace }
   {!!!}Production_time_plus:=1; {cheat!! nasobek urychleni stavby
                                  za tah (1=1bez zrychleni) }
   {!!!}Production_order:=True; { True, pokud je produkce svazana
        pravidly (napr. recyklaci lze vyrobit az po elektrarne apod.);
        False pokud je vsude veskera produkce dostupna }
   {!!!}InternalCache := True; { True, ma-li se pouzit cache; cache potrebuje
   asi 500Kb pameti konstanta MaxCacheMemory), ale zrychluje asi
   o 50% nahravani dat (bez ohledu na pouziti vnejsi diskove cache) }
   {xxx}
   {!!!}CtrlChangeLevel:=True; { pokud je True, vzdusna uroven se
      nastavuje stiskem control a uvolnenim se ztraci; pro False je mozne
      pouzit klasicke nastaveni mysi }
   {xxx}
   {\\\}GameSpeed := 0; { 0.. hrube casovani pomoci hodin; <> 0 pouzije
                              jemny casovac (ms), ktery ale kouse Windows }
   if (GameSpeed = 1) then MissileMoveAdd := 12
   else MissileMoveAdd := 16; { ridi rychlost raket (ne vetsi nez 16) }

   { rychlost hry: 2..nejpomalejsi varianta; 1..nejrychlejsi varianta: }
   if (GameSpeed = 1) then Delay1 := 2
   else Delay1 := 1;
   SetDelay(Delay1); GameTimming:=1;
   {xxx}
   {\\\}Disorder := True; { = True .. jednotky, ktere nic nedelaji a
                           pritom jsou videt se pro oziveni sceny ruzne nataci;
                           False .. tento rys je zakazan
   {xxx}
   {!!!}MaxSearchingRange := 7; { aktivni prohledavaci uroven pocitace; kazda
   jednotka pocitace hleda nepritele ne do limitu sveho dostrelu, ale
   do teto vzdalenosti, aby se simulovalo "inteligentni" chovani - obecne
   by melo jit o hodnotu na urovni dostrelu jednotky s max. dostrelem
   je-li tato hodnota = 0 a zaroven IntelliSearching=False, pak kazda
   jednotka prohledava pouze do vzdalenosti sveho max. dostrelu
   }
   {xxx}
   {!!!}IntelliSearching := True; { True = inteligentni hledani cile; t.j. pocitac
   si vybere v okoli MaxSearchingRange vsechny dostupne cile a podle
   urcitych kriterii si vybere ten nejvyhodnejsi }
   {xxx}
   {!!!}MyIntelliSearching := True; { True = inteligentni hledani cile; t.j.
   pocitac si vybere v okoli MaxSearchingRange vsechny dostupne cile a podle
   urcitych kriterii si vybere ten nejvyhodnejsi - PRO ME JEDNOTKY }
   {xxx}
   MaxDepth := 4; { max. hloubka pri prohledavani okoli jednotky pro vypocet
                    optimalni cesty pri presunu (vice jako 5 je risk) }
   {xxx}
   {\\\}if (Debug) then EnemyStatus:=True else EnemyStatus:=False;
   { pokud je tato promenna nastavena na True, potom je mozne ve hre videt
     charakteristiky nepratelskych jednotek tak, jako by byly pratelske }
   {xxx}
   {!!!}IntelliAttackMovement:=True; { True, ma-li taskgrupa inteligentne obchazet
   prekazky }
   {xxx}
   { nasledujici 2 promenne se nedoporucuje prilis menit: }
   TaskGroupIntelliAttackMoveCyclesForward:=8; {8}
   { cim vyssi cislo, tim vyssi narocnost, ale i inteligence utocicich
     skupin pocitace }
   TaskGroupIntelliAttackMoveCyclesBackward:=8; {8}
   { cim vyssi cislo, tim vyssi narocnost, ale i inteligence utocicich
     skupin pocitace }
   { nasledujici promennou lze menit; cim vyssi cislo, tim lepe (a dele) }
   {!!!}TaskGroupIntelliAttackMoveCyclesRepeat:=6; {8}
   { minimalne 4, urcuje pocet optimalizacnich opakovani vypoctu cesty;
     zvysovani napr. na 10 ma velmi priznive dopady na optimalnost cesty
     v narocnejsich pripadech }
   {xxx}
   {\\\}Fog_of_war:=True; { True = je zapnuta "mlha",t.j. zatemneni mist,
                            ktera nevidim }
   {\\\}Smooth_fog_of_war:=True; { True = "mlha" ma "zarovnane" obrysy }
   {\\\}Unknown_terrain:=False; { True = neprozkoumany teren je cerny }
   {xxx}
   {\\\}AnimatedBuilding:=TRUE; { maji se u budov stridat faze ?? }
   {xxx}
   {\\\}AnimatedCursor:=1; { 0..normalni kurzor, 1..animovany kurzor }
   {xxx}
   {\\\}AUTOSAVE:=1; {0..bez autosave; 1..rychly autosave; 2..pomaly autosave }
   {xxx}
   ScreenShot:=True; { navic pamet pro savescreen * nechat na TRUE ! * }
   {xxx}
   War2Scroll:=True;  { True, pokud rolovat jako war2 }
   {xxx}
   FriendlySpecialUnitsPresent:=False;
   EnemySpecialUnitsPresent:=False;
   EnemySpecialReinforcementPresent:=False; { True pro pritomnost
   specialnich nepratelskych posil }
   {xxx}
   Kadence[0]:=100;
   Kadence[1]:=30; Kadence[2]:=26; Kadence[3]:=22; Kadence[4]:=19;
   Kadence[5]:=17; Kadence[6]:=15; Kadence[7]:=12; Kadence[8]:=9;
   Kadence[9]:=6; Kadence[10]:=0;
   Races[0].RaceName:='BLACKDEATH'; Races[1].RaceName:='PETR';
   Races[2].RaceName:='COMP2'; Races[3].RaceName:='COMP3';
   Races[4].RaceName:='COMP4'; Races[5].RaceName:='COMP5';
   {xxx }
   MyRace:=0; { SIT = MA RASA }

   { xxxxxxxxxxxxxxxxxxx KONEC INICIALIZACNICH DAT xxxxxxxxxxxxxxxxxxxxxxxxx }
   Pom:=Kadence[0];
   {for I:=0 to 9 do KadenceCompare[I]:=Pom/Kadence[I];
   KadenceCompare[10]:=30; { kvuli napr. Intelli_searching_for_attack }

   ThisCompRace1:=255;{ skutecny init pri nahravani z mapy }
   ThisCompRace2:=255;{ skutecny init pri nahravani z mapy }
   ThisCompRace3:=255;{ skutecny init pri nahravani z mapy }
   ThisCompRace4:=255;{ skutecny init pri nahravani z mapy }
   ThisCompRace5:=255;{ skutecny init pri nahravani z mapy }

   {///}MaterInfoSwitch:=0;{///}
   ChangeRGB:=0;
   {PlayerId:='SINGLE';{}
   {PlayerId:='HRAC1';{}
   Game:=255; Campaign:=255; TimeSlot:=0;

   _56MsCounter:=0;
   Del1:=1;
   TimerOn;
   while (not TimerOk) do begin
     for I:=0 to 1000 do ;
     Inc(_56MsCounter);
   end;

   OldExitProc:=ExitProc;
   ExitProc:=@FinishGame;

   {xxxxxxxxx}
{   New(Units[1]);
   Assign(ErFile,'unit.log'); Reset(ErFile,1); IO_Result:=IOResult;
   BlockRead(ErFile,Units[1]^,SizeOf(Units[1]^)); IO_Result:=IOResult;
   Close(ErFile);
   Dispose(Units[1]); Units[1]:=Nil;{}
   {xxxxxxxxx}
   Init_game;
   {}
   Play_game;{}
   {Finish_game;{}
   Assign(IOFile,'save\'+PlayerId+'\$$$'); Erase(IOFile); DResult:=IOResult;
   if (MissionNumber >= 100) then begin
     Assign(IOFile,'save\'+PlayerId+'\continue'); Erase(IOFile); DResult:=IOResult;
   end else begin
     Assign(IOFile,'save\'+PlayerId+'\continue'); Reset(IOFile); DResult:=IOResult;
     if (DResult = 0) then begin
        DialogBox(' DO HRY SE VRaTeTE PfES VOLBU "POKRAbOVAT" NA HLAVNe OBRAZOVCE.',_YES);
     end;
   end;
   {Writeln('verze 1.35 - 15');{}
end.