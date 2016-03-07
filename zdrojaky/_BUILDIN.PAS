
unit _Buildings;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, Buttons, SBSound;

procedure Init_buildings;
procedure Destroy_building(var Build:PBuilding; Eras:Boolean);
procedure Prepare_destroy_building(Building:PBuilding);
procedure Destroy_buildings;
function New_building(IPosic, JPosic:Word; BuildingTyp,Rac:Byte; Visibilit:Boolean; BuildPhas:Byte; Send:Boolean):Word;
procedure Set_place_building(I, J :Word; Building:PBuilding; Sets:Boolean);
function GetBuildingWeight(BuildingType:Word):Word;
procedure Building_manager;
procedure Building_manager_only_draw;
procedure _buildin_save;
procedure _buildin_load;

implementation
uses Mouse, _units, _units2, Grafika2, Grafika3, Grafika4, AI,_races, AI3,
     _units3, Buttons2;
var ElectricShortageDelay,AccumulatorShortageDelay:Word;
{ prodlevy mezi vypsanimm hlasek o nedostatku matrose }

{ ***** }
procedure Init_buildings;
{ inicializace budov
}
const Y = 2.0;
var I :Word;
begin
   I:=1;
   { Zakladna }
   with (Building_types[I]) do begin
      BP:=400; PL:=80; EE:=150; EX:=25; Production_time:=Y/30;
      DefenceStrength:=3130; { sila obrany }
      Name:='ZaKLADNA'; { nazev } Inc(I);
      ProductionType:=1;  MaxIndex:=8;
      Production[0]:=2;
      Production[1]:=3; Production[2]:=4;
      Production[3]:=5; Production[4]:=6; Production[5]:=7;
      Production[6]:=8; Production[7]:=1; Production[8]:=9;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Kasarna }
   with (Building_types[I]) do begin
      BP:=120; PL:=12; EE:=60; EX:=2; Production_time:=Y/22;
      DefenceStrength:=1080; { sila obrany }
      Name:='KASaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=3;
      Production[0]:=5; Production[1]:=6; Production[2]:=7;
      Production[3]:=15; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=1;
      Parent:=1; Autorepair:=0;
   end;
   { Lehka tovarna }
   with (Building_types[I]) do begin
      BP:=180; PL:=0; EE:=30; EX:=0; Production_time:=Y/23;
      DefenceStrength:=1285; { sila obrany }
      Name:='LEHKa TOVaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=8;
      Production[0]:=4; Production[1]:=8; Production[2]:=1;
      Production[3]:=10; Production[4]:=35; Production[5]:=28;
      Production[6]:=25; Production[7]:=26; Production[8]:=2;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Recyklace }
   with (Building_types[I]) do begin
      BP:=100; PL:=10; EE:=20; EX:=0; Production_time:=Y/20;
      DefenceStrength:=1223; { sila obrany }
      Name:='RECYKLACE'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Elektrarna }
   with (Building_types[I]) do begin
      BP:=450; PL:=0; EE:=0; EX:=0; Production_time:=Y/26;
      DefenceStrength:=1200; { sila obrany }
      Name:='ELEKTRaRNA'; { nazev } Inc(I);
      ProductionType:=3;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Akumulator }
   with (Building_types[I]) do begin
      BP:=200; PL:=40; EE:=35; EX:=1; Production_time:=Y/18;
      DefenceStrength:=1950; { sila obrany }
      Name:='AKUMULaTOR'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { generalni stab }
   with (Building_types[I]) do begin
      BP:=350; PL:=90; EE:=100; EX:=30; Production_time:=Y/27;
      DefenceStrength:=3000; { sila obrany }
      Name:='GENERaLNe gTaB'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Vyroba plastu}
   with (Building_types[I]) do begin
      BP:=300; PL:=0; EE:=40; EX:=0; Production_time:=Y/21;
      DefenceStrength:=1920; { sila obrany }
      Name:='VjROBA PLASTi'; { nazev } Inc(I);
      ProductionType:=2;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Zakladna 2}
   with (Building_types[I]) do begin
      BP:=250; PL:=75; EE:=90; EX:=15; Production_time:=Y/35;
      DefenceStrength:=2530; { sila obrany }
      Name:='HITECH ZaKLADNA'; { nazev } Inc(I);
      ProductionType:=1;  MaxIndex:=5;
      Production[0]:=21; Production[1]:=10; Production[2]:=11;
      Production[3]:=12; Production[4]:=13; Production[5]:=14;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Tezka tovarna }
   with (Building_types[I]) do begin
      BP:=500; PL:=55; EE:=150; EX:=10; Production_time:=Y/28;
      DefenceStrength:=2400; { sila obrany }
      Name:='TdkKa TOVaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=7;
      Production[0]:=11; Production[1]:=12; Production[2]:=13;
      Production[3]:=9; Production[4]:=16; Production[5]:=27;
      Production[6]:=36; Production[7]:=14; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Letiste }
   with (Building_types[I]) do begin
      BP:=555;  PL:=108;  EE:=200;  EX:=35; Production_time:=Y/45;
      DefenceStrength:=150; { sila obrany }
      Name:='LETIgTd'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Spec. tovarna }
   with (Building_types[I]) do begin
      BP:=420; PL:=60; EE:=40; EX:=40; Production_time:=Y/29;
      DefenceStrength:=1710; { sila obrany }
      Name:='SPEC. TOVaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=6;
      Production[0]:=17; Production[1]:=34; Production[2]:=18;
      Production[3]:=19; Production[4]:=29; Production[5]:=30;
      Production[6]:=37; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Centrum oprav }
   with (Building_types[I]) do begin
      BP:=250; PL:=35; EE:=100; EX:=0; Production_time:=Y/25;
      DefenceStrength:=2250; { sila obrany }
      Name:='CENTRUM OPRAV'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Obranne centrum }
   with (Building_types[I]) do begin
      BP:=330; PL:=10; EE:=95; EX:=3; Production_time:=Y/31;
      DefenceStrength:=2040; { sila obrany }
      Name:='OBRANNc CENTRUM'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=4;
      Production[0]:=20; Production[1]:=21; Production[2]:=31;
      Production[3]:=32; Production[4]:=41; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Montazni linka }
   with (Building_types[I]) do begin
      BP:=125; PL:=11; EE:=55; EX:=2; Production_time:=Y/22;
      DefenceStrength:=1200; { sila obrany }
      Name:='MONTakNe LINKA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=3;
      Production[0]:=22; Production[1]:=23; Production[2]:=24;
      Production[3]:=39; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=500; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=1020; { sila obrany }
      Name:='bISTIbKA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=420; { sila obrany }
      Name:='STODOLA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=640; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=640; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=400; PL:=30; EE:=70; EX:=10; Production_time:=Y/20;
      DefenceStrength:=1000; { sila obrany }
      Name:='RADAR'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=550; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=440; { sila obrany }
      Name:='STODOLA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=200; { sila obrany }
      Name:='STUDNA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=5000; { sila obrany }
      Name:='PfEKakKA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=0;
      Parent:=0; Autorepair:=0;
   end;
end;

{ ***** }
procedure GenStaffBuild(Rac:Byte);
{ byl postaven gen stab. - povys vsechny existujici vojiny na svobodniky
}
var I, J, Limit:Word;
begin
  if ((Races[Rac].RaceType <> 3) and (Races[Rac].RaceType <> 6)) then begin
     { zvysime inicializacni vyrobni hodnost }
     if (Races[Rac].InitUnitLevel = 0) then
       Races[Rac].InitUnitLevel:=1;
     { povyseni vsech existujicich vojinu, svobodniku, desatniku a cetaru }
     I:=Rac*MaxRaceUnits+1; Limit:=I+MaxRaceUnits;
     while (I < Limit) do begin
       if (Units[I] <> Nil) then with (Units[I]^) do begin
         case (ExperienceLevel) of
           0: begin
                if (Experience <  Experience1) then Experience:=Experience1;
                if (Kills < Kills1) then Kills:=Kills1;
              end;
           1: begin
                if (Experience <  Experience2) then Experience:=Experience2;
                if (Kills < Kills2) then Kills:=Kills2;
              end;
           2: begin
                if (Experience <  Experience3) then Experience:=Experience3;
                if (Kills < Kills3) then Kills:=Kills3;
              end;
           3: begin
                if (Experience <  Experience4) then Experience:=Experience4;
                if (Kills < Kills4) then Kills:=Kills4;
              end;
         end;
         if (Morale < (AverageMorale+MaxMorale div 20))
         then Morale:=AverageMorale+MaxMorale div 20;
         Change_unit_experience_morale(Units[I]);
       end;
       Inc(I);
     end;
  end;
end;

{ ***** }
function New_building(IPosic, JPosic:Word; BuildingTyp,Rac:Byte; Visibilit:Boolean; BuildPhas:Byte; Send:Boolean):Word;
{ vytvori novou budovu rasy Rac a typu BuildingType na pozici IPosic, JPosic a
  ulozi jeji ukazatel do pole Buildings; Visibilit urcuje, zda je jednotka
  videt nebo ne;
  BuildPhase urcuje fazi, ve ktere se ma budova vykreslit:
  1-3 .. stavebni faze
  4,5 .. hotove faze
  Send = True ... je-li rezim hry po siti, info o nove jednotce se
  posle ostanim pocitacum
       = False ... nic se posilat nebude
}
var I,K,L,Limit:Word;
    PUk,PUKFather:PBuilding;
begin
 if (BuildingTyp = 11) then begin
 { letiste }
    Races[Rac].HelpRace:=False;
    UpdateScore(Rac,11,True,False,0,0,0,0,False);
    IShadowPos1:=65535; JShadowPos1:=65535;
    ShadowFlag := ShadowFlagLimit+1;
    MapBck^[IPosic,JPosic].BckType:=Airport1;
    MapBck^[IPosic+1,JPosic].BckType:=Airport2;
    MapBck^[IPosic,JPosic+1].BckType:=Airport3;
    MapBck^[IPosic+1,JPosic+1].BckType:=Airport4;
    Transfer_map_frame(IPosic,JPosic,IPosic+1,JPosic+1); { !! IF VISIBLE !! }
    with Races[Rac] do begin { ulozeni souradnic volnych mist }
       if (I_free_airport_space_max_index = 255) { 1. misto }
       then I_free_airport_space_max_index:=0
       else Inc(I_free_airport_space_max_index);
       if (I_free_airport_space_max_index > MaxAirportSpace) then
         Error(0,'prekrocen max. pocet letist ve hre');
       Free_airport_space[I_free_airport_space_max_index].IFree:=IPosic;
       Free_airport_space[I_free_airport_space_max_index].JFree:=JPosic;
       Free_airport_space[I_free_airport_space_max_index].Pos:=0;
       Inc(I_free_airport_space_max_index); { 2. misto }
       if (I_free_airport_space_max_index > MaxAirportSpace) then
         Error(0,'prekrocen max. pocet letist ve hre');
       Free_airport_space[I_free_airport_space_max_index].IFree:=IPosic;
       Free_airport_space[I_free_airport_space_max_index].JFree:=JPosic+1;
       Free_airport_space[I_free_airport_space_max_index].Pos:=2;
       Inc(I_free_airport_space_max_index); { 3. misto }
       if (I_free_airport_space_max_index > MaxAirportSpace) then
         Error(0,'prekrocen max. pocet letist ve hre');
       Free_airport_space[I_free_airport_space_max_index].IFree:=IPosic+1;
       Free_airport_space[I_free_airport_space_max_index].JFree:=JPosic+1;
       Free_airport_space[I_free_airport_space_max_index].Pos:=3;
    end;
    { NYNI ZAPIS DO GLOBALNI CHARAKTERISTIKY }
    {Inc(Races[Rac].ExistBuildings[BuildingTyp]);{}
    { seznam celkove vyrobenych budov dane rasy }
    {Inc(Races[Rac].ProducedBuildings[BuildingTyp]);{}
 end else begin
       if (Number_of_buildings = MaxBuildings) then Error(0,'prekrocen max. pocet budov ve hre')
       else begin
       { nejprve vyhledame volny slot }
         I:=Rac*MaxRaceBuildings+1; Limit:=I+MaxRaceBuildings;
         while ((Buildings[I] <> Nil) and (I < Limit)) do Inc(I);
         if (I = Limit) then Error(0,'prekrocen max. pocet budov daneho hrace');
         { volny slot nalezen }
         if (BuildingTyp <> 25) then Races[Rac].HelpRace:=False;
         Inc(Races[Rac].Number_of_race_buildings);
         New(Buildings[I]);
         if (Buildings[I] = Nil) then Error(0, 'chyba pri alokaci konvencni pameti');
         Inc(Number_of_buildings);

         with Buildings[I]^ do begin
            UpdateScore(Rac,BuildingTyp,True,False,0,0,0,0,False);
            Activity:=True;
            WayPointUk:=255; WayPointMax:=255;
            Phase:=0;
            Index:=I;
            BuildingType:=BuildingTyp;
            Race:=Rac;
            IPos:=IPosic; JPos:=JPosic;
            Visibility:=Visibilit;
            FirePhase:=0; FireFlag:=0;
            FireState:=0;
            RandomUk:=1;
            WarningBlingFlag:=0;
            Damage:=Building_types[BuildingType].DefenceStrength;
            Production_percentage:=0;
            Production_type:=0; Production_phase:=0;
            if (Building_types[BuildingTyp].ProductionType = 3) then { EE }
               Production_phase:=EEProductionSpeed;
            EEConsumption_phase:=Random(EEConsumptionSpeed shl 1);
            Group:=254; Sold:=False;
            BuildPhase:=BuildPhas;
            BuildAnimPhase:=0; { animacni faze budov }
            BuildTemp:=Random(BuildPhaseSpeed);
            Repair:=False;
            DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
            BPRepairRemainder:=0; PLRepairRemainder:=0;
            EERepairRemainder:=0; EXRepairRemainder:=0;
            RepairRemainder:=0;
            Next:=Nil;
            Production_count:=0;
            TaskGrp:=InvalidTaskGroupNumber;

            if ((BuildingTyp = 5) or (BuildingTyp = 6)) then begin
            { elektrarna, akumulator }
              if (BuildingTyp = 5) then
                 Inc(Races[Rac].EECapacity,ECapacity)
              else Inc(Races[Rac].EECapacity,AcumulatorCapacity);
            end;

            if (BuildingTyp = 13) then with (Races[Race]) do begin
               Inc(MaxRepairCapacity,RepairFacilityCapacity);
               Inc(RepairsAvailable,RepairFacilityCapacity);
            end;

            if (BuildingType = 4) then with Races[Rac] do begin
            { ulozeni souradnic nove recyklace }
              Inc(Races[Rac].RecyklatorBuildInfoCount);
              if (LastRecyklatorBuildInfoIndex > MaxRecyklatorBuildInfoIndex) then begin
              { index byl jeste nepouzit }
                LastRecyklatorBuildInfoIndex:=0;
                RecyklatorBuildInfo[LastRecyklatorBuildInfoIndex].IP:=IPos;
                RecyklatorBuildInfo[LastRecyklatorBuildInfoIndex].JP:=JPos;
              end else begin
                K:=0;
                while ((K <= LastRecyklatorBuildInfoIndex) and
                       (RecyklatorBuildInfo[K].IP < 65535))
                do Inc(K);
                if (K > LastRecyklatorBuildInfoIndex) then begin
                { novy index }
                   Inc(LastRecyklatorBuildInfoIndex);
                   if (LastRecyklatorBuildInfoIndex > MaxRecyklatorBuildInfoIndex)
                   then Error(0,'unita _buildin, prekrocen max. pocet recyklatoru ve hre');
                   RecyklatorBuildInfo[LastRecyklatorBuildInfoIndex].IP:=IPos;
                   RecyklatorBuildInfo[LastRecyklatorBuildInfoIndex].JP:=JPos;
                end else begin
                { nejaky index uvnitr je volny }
                   RecyklatorBuildInfo[K].IP:=IPos;
                   RecyklatorBuildInfo[K].JP:=JPos;
                end;
              end;
            end; { if (BuildingType = 4) then ... }
            { NYNI ZAPIS DO GLOBALNI CHARAKTERISTIKY }
            Inc(Races[Rac].ExistBuildings[BuildingTyp]);
            { seznam celkove vyrobenych budov dane rasy }
            Inc(Races[Rac].ProducedBuildings[BuildingTyp]);
         end; { with }
         { vykresleni jednotky }
         if (Visibilit) then Draw_building(Buildings[I]);
         Set_place_building(IPosic, JPosic, Buildings[I], True);
         with (Building_types[BuildingTyp]) do begin
           SetFog(IPosic,JPosic,Sight,Rac,True);
           if (IBuildingSize = 2) then
             SetFog(IPosic+1,JPosic,Sight,Rac,True)
           else if (IBuildingSize > 2) then
                   SetFog(IPosic+2,JPosic,Sight,Rac,True);
           if (JBuildingSize = 2) then begin
             SetFog(IPosic,JPosic+1,Sight,Rac,True);
             SetFog(IPosic+1,JPosic+1,Sight,Rac,True);
           end else
             if (JBuildingSize > 2) then begin
               SetFog(IPosic,JPosic+2,Sight,Rac,True);
               SetFog(IPosic+2,JPosic+2,Sight,Rac,True);
             end
         end;
       end;
       { * }
       with (Races[Rac]) do begin
         PUk:=PointerToBuildings[BuildingTyp];
         if (PUk = Nil) then PointerToBuildings[BuildingTyp]:=Buildings[I]
         else begin
            while (PUk <> Nil) do begin
              PUkFather:=PUk; PUk:=PUk^.Next;
            end;
            PUkFather^.Next:=Buildings[I];
         end;
       end;
       { * }
   end;

 if (BuildingTyp = 7) then begin
   if (not Races[Rac].GSBuild) then begin
      Races[Rac].GSBuild:=True;
      GenStaffBuild(Rac);
   end;
 end;
 New_building:=I;
end;

{ ***** }
procedure Destroy_building(var Build:PBuilding; Eras:Boolean);
{ zrusi budovu Building a je-li Eras = True, take ji smaze
}
var I,J,K,L,M,N,ISize,JSize:Word;
    RandomNum, Base:Byte;
    PUk,PUkFather:PBuilding;
    Flag:Byte;
    PomValue:Double;
begin
  if (Build <> Nil) then begin
      with (Build^) do begin
        if (not Sold) then UpdateScore(Race,BuildingType,True,True,0,0,0,0,True);

        Dec(Number_of_buildings);
        { odalokovani budovy ze seznamu }
        with (Races[Race]) do begin
          PUk:=PointerToBuildings[BuildingType];
          if (PUk = Build) then PointerToBuildings[BuildingType]:=Build^.Next
          else begin
             while (PUk <> Build) do begin
                PUkFather:=PUk; PUk:=PUk^.Next;
                if (PUk = Nil) then Error(0,'Chyba v unite _buildin, procedura Destroy_building');
             end;
             PUkFather^.Next:=PUk^.Next; { vylouceni ze seznamu }
          end;
        end;
        ISize:=Building_types[BuildingType].IBuildingSize-1;
        JSize:=Building_types[BuildingType].JBuildingSize-1;
        { smazani jednotky ze seznamu cilu }
        for L:=0 to MaxRace do with (Races[L]) do begin
          for K:=0 to 9 do with (TaskGroups^[K]) do begin
            if (Validity) then begin
              for M:=IPos to IPos+ISize do
                for N:=JPos to JPos+JSize do
                  ClearActiveAttackTGInfoXY(L,K,0,M,N);
            end;
          end;
        end;

        if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
            (Race = ThisCompRace3) or (Race = ThisCompRace4) or
            (Race = ThisCompRace5)) then with Races[Race] do begin
          { nyni se vrati pridelene misto pro rozlozeni: }
          with (Building_types[BuildingType]) do begin
             if (ProductionType < 2) then begin
                  if (IBuildingSize < 3) then
                    Flag:=1 { velikost 64x64, vhodne pro tovarny }
                  else Flag:=13 { velikost 96x96, vhodne pro tovarny }
               end else
                 if (BuildingType = 11) then Flag:=5 {64x64, rezerv. pro letiste}
                 else
                   if (BuildingType = 21) then Flag:=6 {64x64, rezerv. pro letiste}
                   else
                     if (IBuildingSize = 3)  and (JBuildingSize = 3)
                     then Flag:=14 { velikost 96x96, vhodne pro nevyrobni objekty }
                     else
                        if (IBuildingSize = 2)  and (JBuildingSize = 2)
                        then Flag:=2 { velikost 64x64, vhodne pro nevyrobni objekty }
                        else
                          if (IBuildingSize = 2)  and (JBuildingSize = 1)
                          then Flag:=3 { velikost 64x32 }
                          else
                            if (IBuildingSize = 1)  and (JBuildingSize = 1)
                            then Flag:=4  { velikost 32x32 }
                            else Error(0,'unita AI, procedura  CreateNewTaskGroup, bod 1');
          end;{ with (Building_types[BuildingType]) do begin}
          if (BuildingType = 5) then Flag:=15;  { elektrarna }
          if (BuildingType = 4) then Flag:=16;  { harvestrarna }
          AddFreePlaceForBuilding(Race,IPos,JPos,Flag,1);
        end;

        { NYNI ZAPIS DO GLOBALNI CHARAKTERISTIKY }
        Dec(Races[Race].ExistBuildings[BuildingType]);
        Dec(Races[Race].Number_of_race_buildings);
        if (Group = ActiveGroup) then with Groups[Group] do begin
           Clear_group_slots;
           Deselect_group(ActiveGroup);
           if (Active(Opravit)) then SetPasive(Opravit,256);
           if (Active(Stop)) then SetPasive(Stop,256);
        end;
        for L:=0 to MaxGroups do with (Groups[L]) do
          if (Building = Build) then begin
             Building:=Nil;
             Dec(Count);
          end;
        Set_place_building(IPos,JPos, Build, False);
        if (Repair) then Inc(Races[Race].RepairsAvailable,BuildingRepairCapacityNeed);

        with (Building_types[BuildingType]) do begin
           SetFog(IPos,JPos,Sight,Race,False);
           if (IBuildingSize = 2) then
             SetFog(IPos+1,JPos,Sight,Race,False)
           else if (IBuildingSize > 2) then
                   SetFog(IPos+2,JPos,Sight,Race,False);
           if (JBuildingSize = 2) then begin
             SetFog(IPos,JPos+1,Sight,Race,False);
             SetFog(IPos+1,JPos+1,Sight,Race,False);
           end else
             if (JBuildingSize > 2) then begin
               SetFog(IPos,JPos+2,Sight,Race,False);
               SetFog(IPos+2,JPos+2,Sight,Race,False);
             end
        end;

        if (not Sold) then with (MapInfo^[IPos div IInfodiv,JPos div JInfodiv]) do begin
          PomValue:=GetMoraleModif(Race,BuildingType,True,0,0,0,0);
          for I:=0 to MaxRace do begin
            if (Races[I].Friend[Race] = 0) then begin
               MoraleModifierTemp[I]:=MoraleModifierTemp[I]+PomValue;
               Races[I].GlobalMoraleTemp:=Races[I].GlobalMoraleTemp+PomValue/10;
            end;
            if (Races[I].Friend[Race] = 2) then begin
               MoraleModifierTemp[I]:=MoraleModifierTemp[I]-PomValue;
               Races[I].GlobalMoraleTemp:=Races[I].GlobalMoraleTemp-PomValue/10;
            end;
          end;
        end;

        { * nyni vytvorime trosky * }
        if (not Sold) then if (Debris) then begin
        { IPos,JPos}
          for J:=JPos to JPos+JSize do
            for I:=IPos to IPos+ISize do begin
               MapBck^[I,J].Info:=DebrisInfoIndex;
               with (DebrisInfo^[DebrisInfoIndex]) do begin
                 case (JSize) of
                    0:DebrisType:=10;
                    1:DebrisType:=12+(I-IPos)*2+(J-JPos)*4;
                    2:DebrisType:=20+(I-IPos)*2+(J-JPos)*6;
                 end;
                 IP:=I; JP:=J; DebrisTimmer:=DebrisTimmerValue;
                 if (Rand(RndUk) mod 2 = 0) then begin
                   FireTimmer:=DebrisFireTimmerValue;
                   FirePhase:=Rand(RndUk);
                 end else begin
                   FireTimmer:=0; FirePhase:=0;
                 end;
               end; Inc(DebrisInfoIndex);
               if (LowDebrisInfoIndex = 255) then LowDebrisInfoIndex:=0;
               if (DebrisInfoIndex > MaxDebrisInfoIndex) then DebrisInfoIndex:=0;
            end;
        end; { if (Debris) }

        if (Visibility and Eras) then Erase_building(Build);

        if (BuildingType = 4) then with Races[Race] do begin
        { vypusteni recyklatoru ze seznamu }
            K:=0; Dec(Races[Race].RecyklatorBuildInfoCount);
            while ((K <= LastRecyklatorBuildInfoIndex) and
                   ((RecyklatorBuildInfo[K].IP <> IPos) or
                   (RecyklatorBuildInfo[K].JP <> JPos)))
            do Inc(K);
            if (K <= LastRecyklatorBuildInfoIndex) then begin
            { misto v seznamu nalezeno! }
              RecyklatorBuildInfo[K].IP:=65535;
              RecyklatorBuildInfo[K].JP:=65535;
            end else
              Error(0,'unita _buildin, procedura Destroy_building - recyklator neni v seznamu');
        end; { if (BuildingType = 4) then ... }

        if ((BuildingType = 5) or (BuildingType = 6)) then
        with (Races[Race]) do begin
        { elektrarna, akumulator }
          if (BuildingType = 5) then
             Dec(EECapacity,ECapacity)
          else Dec(EECapacity,AcumulatorCapacity);
          if (Electric_energy > EECapacity) then begin
            Electric_energy := EECapacity;
            if (Race = MyRace) then UpdateEEEnergy:=True;
          end;
        end;

        if (BuildingType = 13) then with (Races[Race]) do begin
           Dec(MaxRepairCapacity,RepairFacilityCapacity);
           Dec(RepairsAvailable,RepairFacilityCapacity)
        end;
        if (BuildingType = 8) then begin { recyklace }
          if (Races[Race].DruhaPlastarnaVeVyrobe)
          then Races[Race].DruhaPlastarnaVeVyrobe:=False;
        end;

        Buildings[Index]:=Nil;
      end;
      Dispose(Build);
      Build:=Nil;
  end;
end;

{ ***** }
procedure Prepare_destroy_building(Building:PBuilding);
{ rozanimuje vybuch budovy a nakonec ji zlikviduje
}
var Size:Word;
    PomPhase:Word;
begin
   with (Building^) do with (Building_types[BuildingType]) do begin
      if (JBuildingSize < 2) then
         PomPhase:=MaxSmallExplosPhase
      else
        if (JBuildingSize = 2) then
          PomPhase:=MaxMediumExplosPhase
        else
          PomPhase:=MaxBigExplosPhase;

      if ((Phase < 1) or (Pom = -127)) then begin
         Size:=Building_types[BuildingType].XBuildingSize div 32 +
               Building_types[BuildingType].YBuildingSize div 32;
         case (Size) of
            2: PreparePlaySound(4,GetVolume(IPos,JPos),0,0);
            4: PreparePlaySound(4,GetVolume(IPos,JPos),1,0);
            6: PreparePlaySound(4,GetVolume(IPos,JPos),2,0);
         else
            PreparePlaySound(4,GetVolume(IPos,JPos),0,0);
         end;
         Phase:=0; Pom:=-1;
      end;
      FirePhase:=0;
      if (GameTimming = 0) then Inc(Pom,2) else Inc(Pom);
      if (Pom > 1) then Pom:=0;
      if (Pom = 0) then begin
        { jedna z fazi vybuchu }
        Inc(Phase);
        if (Phase > PomPhase) then begin
        { likvidace jednotky }
          Destroy_building(Building,True);{}
        end else Draw_building(Building);
      end;
   end;
end;

{ ***** }
procedure Destroy_buildings;
{ zrusi vsechny existujici budovy z pameti
}
var I:Word;
begin
  for I:=1 to (MaxRaceBuildings+1)*(MaxRace+1) do begin
    if (Buildings[I] <> Nil) then with (Buildings[I]^) do begin
        Dispose(Buildings[I]);
        Buildings[I]:=Nil;
    end;
  end;
  Number_of_buildings:=0;
end;

{ ***** }
procedure Set_place_building(I, J :Word; Building:PBuilding; Sets:Boolean);
{ budova je urcena ukazatelem Building;
  procedura nastavi u policka I,J na sirku budovy priznak obsazenosti
  dle promenne Sets (True = obsazeno)
}
var M, N, K, L, I2, J2, ISize, JSize, IP, JP : Word;
    Color : Byte;
    Pom, MouseObstacle : Boolean;
    XMouse,YMouse:Word;
    Result, Result2:Boolean;
begin
   with Building^ do begin
     with Building_types[BuildingType] do begin
       ISize:=IBuildingSize; JSize:=JBuildingSize;
     end;
     M:=I; N:=J;
     {}
     Result:=False; Result2:=False;
     if ((Races[Race].Friend[MyRace] = 2) and (not AllyFog) or (Race = MyRace))
     then Result:=True;
     if (Races[Race].Friend[MyRace] = 0) then Result2:=True;
     for J:=N to (N+JSize-1) do
       for I:=M to (M+ISize-1) do with (MapBck^[I,J]) do
       with (MapBckTemp^[I,J]) do begin
         if ((not Fog_of_war) or (Visibilit and Races[MyRace].VisMask  > 0)) then Result:=True;
         if ((not Fog_of_war) or (EnemyVisibilit > 0)) then Result2:=True;
       end;
     {}
     Visibility:=Result; EnemyVisibility:=Result2;
     for J:=N to (N+JSize-1) do
       for I:=M to (M+ISize-1) do  with (Map^[I,J]) do with (MapBck^[I,J]) do begin
         K:=I+XRadarRealBeg; L:=J+YRadarRealBeg;
         GetXYMouse(XMouse,YMouse);
         if ((XMouse < (K+1)) and (YMouse < (L+1)) and
             ((XMouse+XCursorSize) >= K) and
             ((YMouse+YCursorSize) >= L)) then
            MouseObstacle:=True
         else MouseObstacle:=False;

         if (Sets) then begin { budova se nastavi }
             if (Visibility) then begin
                BuildRadar^[I,J].B:=Race;
                BuildRadar^[I,J].P:=True;
             end;

             First_level:=Index;
             Level_type:=Level_type and 127;
             Level_type:=Level_type+128;
             if (Visibility) then begin
               { vykresli budovu na mape }
                 if (MouseObstacle) then CursorOff;
                 if ((J < (N+2)) and (I < (M+2))) then
                 { na mape je to pouze 2x2 obdelnik }
                    DrawRadarPixel(I,J);
                 if (MouseObstacle) then CursorOn;
             end; { if (Visibility) }
             { nastaveni informaci do  pole MapInfo - pro AI }
             if ((I = IPos) and (J = JPos)) then begin
               IP:=IPos div IInfoDiv; JP:=JPos div JInfoDiv;
               with (MapInfo^[IP,JP]) do begin
                 if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                 { jde o pro mne nepratelskou jednotku }
                    Inc(FriendlyBuildingsNum);
                    Inc(FriendlyBuildingsWeight,GetBuildingWeight(BuildingType));
                 end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                 { jde o mne nebo o spojence }
                    if (EnemyVisibility) then begin
                      Inc(EnemyVBuildingsNum);
                      Inc(EnemyVBuildingsWeight,GetBuildingWeight(BuildingType));
                    end else begin
                      Inc(EnemyHBuildingsNum);
                      Inc(EnemyHBuildingsWeight,GetBuildingWeight(BuildingType));
                    end;
                 end;
               end;
             end;
         end else begin { budova se smaze }
             if (Visibility) then BuildRadar^[I,J].B:=255;
             First_level:=0;
             Level_type:=Level_type and 127;
             if (Visibility) then begin
             { smaz budovu na mape }
               if ((J <= (N+1)) and (I <= (M+1))) then begin
               { na mape je to pouze 2x2 obdelnik }
                  if (((I = IBeg) or (I = (IBeg+IScreenSize-1))) and
                      (J >= JBeg) and (J < JBeg+JScreenSize) or
                      ((J = JBeg) or (J = (JBeg+JScreenSize-1))) and
                      (I >= IBeg) and (I < IBeg+IScreenSize))
                  then begin { bily obdelnik }
                      if (MouseObstacle) then CursorOff;
                      DrawRadarPixel(I,J);
                      if ((Building_types[BuildingType].JBuildingSize = 1) and
                          (Building_types[BuildingType].IBuildingSize = 2))
                      then
                         DrawRadarPixel(I,J+1);
                      {DrawRadarPixel(I+1,J);
                      DrawRadarPixel(I,J+1);
                      DrawRadarPixel(I+1,J+1);}
                      SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                               YRadarRealBeg+JScreenSize+JBeg-1,65);
                      if (MouseObstacle) then CursorOn;
                  end else begin
                     if (MouseObstacle) then CursorOff;
                     DrawRadarPixel(I,J);
                     if ((Building_types[BuildingType].JBuildingSize = 1) and
                          (Building_types[BuildingType].IBuildingSize = 2))
                     then
                        DrawRadarPixel(I,J+1);
                     {DrawRadarPixel(I+1,J);
                     DrawRadarPixel(I,J+1);
                     DrawRadarPixel(I+1,J+1);{}
                     if (MouseObstacle) then CursorOn;
                  end;
               end;
             end; { if ( Visibility) then }
             { vyjmuti informaci z pole MapInfo - pro AI }
             if ((I = IPos) and (J = JPos)) then begin
               IP:=IPos div IInfoDiv; JP:=JPos div JInfoDiv;
               with (MapInfo^[IP,JP]) do begin
                 if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                 { jde o pro mne nepratelskou jednotku }
                    Dec(FriendlyBuildingsNum);
                    Dec(FriendlyBuildingsWeight,GetBuildingWeight(BuildingType));
                 end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                 { jde o mne nebo o spojence }
                    if (EnemyVisibility) then begin
                      Dec(EnemyVBuildingsNum);
                      Dec(EnemyVBuildingsWeight,GetBuildingWeight(BuildingType));
                    end else begin
                      Dec(EnemyHBuildingsNum);
                      Dec(EnemyHBuildingsWeight,GetBuildingWeight(BuildingType));
                    end;
                 end;
               end;
             end;
         end; { if (Sets) then ... else ... }
      end; { for }
   end; { with (Building^) }
end;

{ ***** }
function GetBuildingWeight(BuildingType:Word):Word;
{ parametrem je typ budovy; funkce vraci jeji vahu (neboli uroven
  dulezitosti pro hrace )

  !!! DALE VIZ UNITA AI, PROCEDURA AI_MANAGER + KORENOVA KONSTANTA !!!!
  !!! JSOU TO KONSTANTY, KTERE MAJI K NIZE UVEDENYM HODNOTAM UZKY VZTAH !!!
}
begin
   case (BuildingType) of
     1  : GetBuildingWeight:=150; { zakladna }
     2  : GetBuildingWeight:=30; { kasarna }
     3  : GetBuildingWeight:=50; { lehka tovarna }
     4  : GetBuildingWeight:=80; { recyklace }
     5  : GetBuildingWeight:=130; { elektrarna }
     6  : GetBuildingWeight:=40; { akumulator }
     7  : GetBuildingWeight:=10; { generalni stab }
     8  : GetBuildingWeight:=80; { vyroba plastu }
     9  : GetBuildingWeight:=80; { zakladna2 }
     10 : GetBuildingWeight:=70; { tezka tovarna }
     11 : GetBuildingWeight:=0; { letiste - nelze znicit }
     12 : GetBuildingWeight:=70; { spec. tovarna }
     13 : GetBuildingWeight:=110; { centrum oprav }
     14 : GetBuildingWeight:=90; { obranne centrum }
     15 : GetBuildingWeight:=30; { montazni linka }
     21 : GetBuildingWeight:=100; { radar }
   else { civilni a jine "nedulezite" budovy }
      GetBuildingWeight:=0; { xxx }
   end;
end;

{ ***** }
procedure Building_manager;
{ procedura zabezpecuje cinnost budov, jejich exploze ...
}
label UnAlloc, Kanec;
var I, J, K, L, ISize, JSize : Integer;
    FreePlaces : TFreePlaces;
    MaxIndex, Ind:Word;
    ProductIndex:Byte;
    OK:Boolean;
    Rac,Experienc:Byte;
    Visibilit, Bool:Boolean;
    DMG,DMGStrength,BP2,PL2,EE2,EX2,PomVal:Single;
    BPPom,PLPom,EEPom,EXPom,DmgPom:Word;
    _unit:PUnit;
begin
 I:=1; J:=1;
 while ((I <= Number_of_buildings) and (J <= (MaxRaceBuildings+1)*(MaxRace+1))) do begin
{1}if (Buildings[J] <> Nil) then with Buildings[J]^ do begin
   { budova na danem indexu existuje }
      GlobalJ:=J; bebex:=1;
      if (Race <> MyRace) then SetTerminator_fighterParams(True);
      Inc(I);
      bebex:=2;
      if (Races[Race].ChangeOnVisib and Visibility) then begin
         ChangeBuildingToMyRace(Buildings[J]);
         GoTo Kanec;
      end;
      bebex:=3;

      if (FirePhase <> 0) then begin { budova "kouri" }
        Inc(FireFlag);
        if (FireFlag > 1) then begin
          FireFlag:=0;
          Inc(FirePhase);
          if (FirePhase > 4) then FirePhase:=1;
          RequestDraw:=True;
        end;
      end;

      bebex:=4;
  {2} if (Activity) then begin
      { budova je cinna }
         { PRIPADNE BLIKANI NA RADARU }
         bebex:=5;
         if (WarningBlingFlag=GetAccurateDelay(MaxWarningBlingValue))
         then begin
         { nastav barvu budovy na radaru blikavou barvou }
            DrawRadarPixel(IPos,JPos);
            DrawRadarPixel(IPos,JPos+1);
            DrawRadarPixel(IPos+1,JPos);
            DrawRadarPixel(IPos+1,JPos+1);
         end;
         bebex:=6;
         if (WarningBlingFlag <> 0) then begin
           Dec(WarningBlingFlag);
           if (WarningBlingFlag = 0) then begin
           { nastav barvu jednotky na radaru na normalni }
              DrawRadarPixel(IPos,JPos);
              DrawRadarPixel(IPos,JPos+1);
              DrawRadarPixel(IPos+1,JPos);
              DrawRadarPixel(IPos+1,JPos+1);
           end;
         end;

     {3} if (Production_type <> 0) then begin
          { budova vyrabi }
          bebex:=7;
      {4} if (Building_types[BuildingType].ProductionType < 2) then begin
           { budovy, jednotky }
             bebex:=8;
             Production_phase:=0;
             with (Building_types[BuildingType]) do begin
               bebex:=9;
               DMGStrength:=DefenceStrength; DMGStrength:=DMGStrength/100;
               DMG:=Damage; DMG:=Abs(100-DMG/DMGStrength);
               { budova je na DMG procent normalu poskozena }
               DMG:=DMG/2;
               if (ProductionType = 0) then
                 DMGStrength:=Unit_types[Production[Production_type-1],Races[Race].Ally].Production_time
               else
                 DMGStrength:=Building_types[Production[Production_type-1]].Production_time;
               DMG:=DMGStrength-DMG*(DMGStrength/100);
               { za kazde 1% procento poskozeni se produkce zpomali o 0.5% }
             end;
             bebex:=10;
             with (Building_types[BuildingType]) do
               Production_percentage:=Production_percentage+DMG*
                                      Production_time_plus;
             if ((Group = ActiveGroup) and ((Race = MyRace) or Debug)) then
                  Update_building_production(Buildings[J],Production_slot);
             bebex:=11;
         {5} if (Production_percentage >= 100) then begin
             { produkce je hotova - umisti vyrobek }
                bebex:=12;
                if ((BuildingType = 1) and (Building_types[BuildingType].Production[Production_type-1] = 2) and
                    (Races[Race].PermittedBuildings[15]))
                then ProductIndex:=15
                else{} ProductIndex:=Building_types[BuildingType].Production[Production_type-1];

                bebex:=13;
                Rac:=Race; Experienc:=0;
                Visibilit:=True;

                Production_phase:=0;
                Production_percentage:=0;
                bebex:=14;
                if ((Group = ActiveGroup) and ((Race = MyRace) or Debug)) then
                   Update_building_production(Buildings[J],Production_slot);
                Ok:=False; K:=1;
                bebex:=15;
                Get_free_places(FreePlaces,MaxIndex,IPos,JPos,
                                Building_types[BuildingType].IBuildingSize,
                                Building_types[BuildingType].JBuildingSize);
                bebex:=16;
            {6} if (Building_types[BuildingType].ProductionType = 0) then begin
                { *** jednotky }
                    bebex:=17;
                    if (Unit_types[ProductIndex,Races[Race].Ally].UnitLevel =255) then Ind:=33
                    else Ind:=ProductIndex;
                    while ((not OK) and (K <= MaxIndex)) do  { hledej misto pro vylozeni }
                    with (FreePlaces[K]) do begin
                       bebex:=18;
                       if (Free and Free_place_two(IP,JP,Unit_types[ProductIndex,Races[Race].Ally].IUnitSize,
                                               Unit_types[ProductIndex,Races[Race].Ally].JUnitSize,
                                               Ind))
                       then begin { flek nalezen }
                          bebex:=19;
                          if (Unit_types[ProductIndex,Races[Race].Ally].UnitLevel =255)
                          then begin
                             bebex:=20;
                          { * jednotka-budova (napr. raketova vez) }
                             MaxIndex:=New_unit(IP,JP,255,Rac,Experienc,0,Visibilit,False,ProductIndex);
                             Units[MaxIndex]^._building:=False;

                             { odstraneni "locku" }
                             if (Races[Race].DefendLock > 0)
                             then Dec(Races[Race].DefendLock);
                             bebex:=21;
                             if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
                                 (Race = ThisCompRace3) or (Race = ThisCompRace4) or
                                 (Race = ThisCompRace5)) then begin
                             { prirad novou jednotku do TaskGroup }
                                  TaskGroupCommand(Race,CreateNewTaskGroup(Race,TGInvalid,Units[MaxIndex]),
                                                   MoveBuildCom,0,4,0,0,0);
                             end;
                             bebex:=22;
                             if (Rac = MyRace) then
                               OutBigMsg(2,'BUDOVA VYROBENA');
                             {x}
                             Dec(Production_count);
                             if (Buildings[J]^.Group = ActiveGroup) then
                               Draw_building_production(Buildings[J]);
                             bebex:=23;
                             if ((Production_count > 0) and (Race = MyRace) and
                                 (UnitProductionPossible(Race,ProductIndex)))
                             then begin
                             { zahaj dalsi vyrobu v rade }
                               bebex:=24;
                               with (Unit_types[ProductIndex,Races[Race].Ally]) do begin
                               { vyroba jednotek }
                                 bebex:=25;
                                 if ((BP <= Races[MyRace].Building_credits) and
                                     (PL <= Races[MyRace].Plastic_credits) and
                                     (EE <= Races[MyRace].Electric_energy) and
                                     (EX <= Races[MyRace].Battle_experience)) then begin
                                 { material staci! }
                                    if (UnitLevel = 3) and (SpecAirLevel = 0) and
                                       (Races[MyRace].I_free_airport_space_max_index = 255)
                                    then begin
                                    { chybi letiste pro vzdusnou jednotku }
                                      OutBigMsg(9,'NELZE VYRaBdT-NEDOSTATEK LETIgTNe KAPACITY');
                                      Production_count:=0; Production_type:=0;
                                      if (Buildings[J]^.Group = ActiveGroup) then
                                        Draw_building_production(Buildings[J]);
                                      {x}
                                    end else begin
                                      bebex:=26;
                                      Dec(Races[MyRace].Building_credits,BP);
                                      Dec(Races[MyRace].Plastic_credits,PL);
                                      Dec(Races[MyRace].Electric_energy,EE);
                                      Dec(Races[MyRace].Battle_experience,EX);
                                      if (BP <> 0) then UpdateBP:=True;
                                      if (PL <> 0) then UpdatePL:=True;
                                      if (EE <> 0) then UpdateEEEnergy:=True;
                                      if (EX <> 0) then UpdateEXP:=True;
                                    end;
                                 end else begin
                                 { nedostatek materialu }
                                    bebex:=27;
                                    OutBigMsg(5,'NEDOSTATEK MATERIaLU !');
                                    Production_count:=0; Production_type:=0;
                                    if (Buildings[J]^.Group = ActiveGroup) then
                                       Draw_building_production(Buildings[J]);
                                    {x}
                                 end;
                               end;
                             end else begin Production_type:=0; Production_count:=0; end;
                             {x}
                          end else begin
                          { * klasicka jednotka }
                             bebex:=28;
                             if ((Unit_types[ProductIndex,Races[Race].Ally].UnitLevel = 3) and
                                 (Unit_types[ProductIndex,Races[Race].Ally].SpecAirLevel = 0) and
                                 (Races[Rac].I_free_airport_space_max_index = 255))
                             then begin
                             { chybi letiste pro vzdusnou jednotku }
                                bebex:=29;
                                if (Rac = MyRace) then
                                   OutBigMsg(9,'NELZE UMeSTIT-NEDOSTATEK LETIgTNe KAPACITY');
                                   {Inc(Races[Rac].AirportShortage);{}
                                   {x}
                                 Production_count:=0;
                                 if (Buildings[J]^.Group = ActiveGroup) then
                                     Draw_building_production(Buildings[J]);
                                 Production_type:=0;
                                 {x}
                                 GoTo UnAlloc;
                             end else begin
                                { odstraneni "locku" }
                                bebex:=30;
                                if ((TaskGrp <= MaxRaceTaskGroups) and
                                    (RacesTGInfo^[Race,TaskGrp].Lock > 0))
                                then Dec(RacesTGInfo^[Race,TaskGrp].Lock);
                                bebex:=31;
                                case (LockType) of
                                    0 : if ((TaskGrp <= 12) and (RacesTGInfo^[Race,TaskGrp].AALock > 1))
                                        then Dec(RacesTGInfo^[Race,TaskGrp].AALock);
                                    1 : if ((TaskGrp <= 12) and (RacesTGInfo^[Race,TaskGrp].ALock > 1))
                                        then Dec(RacesTGInfo^[Race,TaskGrp].ALock);
                                    2 : if ((TaskGrp <= 12) and (RacesTGInfo^[Race,TaskGrp].LLock > 1))
                                        then Dec(RacesTGInfo^[Race,TaskGrp].LLock);
                                    3 : if ((TaskGrp <= 12) and (RacesTGInfo^[Race,TaskGrp].HLock > 1))
                                        then Dec(RacesTGInfo^[Race,TaskGrp].HLock);
                                    4 : if ((TaskGrp <= 12) and (RacesTGInfo^[Race,TaskGrp].CLock > 1))
                                        then Dec(RacesTGInfo^[Race,TaskGrp].CLock);
                                 end;
                                 bebex:=32;
                                 with (Races[Race]) do case (ProductIndex) of
                                   { odstranit zakaz pro danou komoditu }
                                     2 : if (BPShortageForbid > 0) { recyklator }
                                         then Dec(BPShortageForbid);
                                 end;{}
                                 bebex:=33;
                                 Ind:=New_unit(IP,JP,ProductIndex,Rac,Experienc,0,Visibilit,False,0);
                                 bebex:=34;
                                 if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
                                     (Race = ThisCompRace3) or (Race = ThisCompRace4) or
                                     (Race = ThisCompRace5)) then begin
                                 { prirad novou jednotku do TaskGroup }
                                    if (TaskGrp < InvalidTaskGroupNumber) then begin
                                        if (not Races[Race].TaskGroups^[TaskGrp].Validity) then
                                          TaskGroupCommand(Race,CreateNewTaskGroup(Race,TaskGrp,Units[Ind]),
                                                           TaskCommand,0,4,0,0,0)
                                        else
                                          AssignTaskGroup(Race,TaskGrp,Units[Ind]);
                                    end;
                                 end;
                                 bebex:=35;
                                 if (Rac = MyRace) then
                                   OutBigMsg(1,'JEDNOTKA VYROBENA');
                                 {x}
                                 Dec(Production_count);
                                 bebex:=36;
                                 if (Buildings[J]^.Group = ActiveGroup) then
                                    Draw_building_production(Buildings[J]);
                                 bebex:=37;
                                 if ((Production_count > 0) and (Race = MyRace) and
                                     (UnitProductionPossible(Race,ProductIndex)))
                                 then begin
                                 { zahaj dalsi vyrobu v rade }
                                   bebex:=38;
                                   with (Unit_types[ProductIndex,Races[Race].Ally]) do begin
                                   { vyroba jednotek }
                                     bebex:=39;
                                     if ((BP <= Races[MyRace].Building_credits) and
                                         (PL <= Races[MyRace].Plastic_credits) and
                                         (EE <= Races[MyRace].Electric_energy) and
                                         (EX <= Races[MyRace].Battle_experience)) then begin
                                     { material staci! }
                                        bebex:=40;
                                        if (UnitLevel = 3) and (SpecAirLevel = 0) and
                                           (Races[MyRace].I_free_airport_space_max_index = 255)
                                        then begin
                                        { chybi letiste pro vzdusnou jednotku }
                                          bebex:=41;
                                          OutBigMsg(9,'NEDOSTATEK LETIgTNe KAPACITY !');
                                          Production_count:=0; Production_type:=0;
                                          if (Buildings[J]^.Group = ActiveGroup) then
                                             Draw_building_production(Buildings[J]);
                                          {x}
                                        end else begin
                                          bebex:=42;
                                          Dec(Races[MyRace].Building_credits,BP);
                                          Dec(Races[MyRace].Plastic_credits,PL);
                                          Dec(Races[MyRace].Electric_energy,EE);
                                          Dec(Races[MyRace].Battle_experience,EX);
                                          if (BP <> 0) then UpdateBP:=True;
                                          if (PL <> 0) then UpdatePL:=True;
                                          if (EE <> 0) then UpdateEEEnergy:=True;
                                          if (EX <> 0) then UpdateEXP:=True;
                                        end;
                                     end else begin
                                     { nedostatek materialu }
                                        bebex:=43;
                                        OutBigMsg(5,'NEDOSTATEK MATERIaLU !');
                                        Production_count:=0; Production_type:=0;
                                        if (Buildings[J]^.Group = ActiveGroup) then
                                           Draw_building_production(Buildings[J]);
                                        {x}
                                     end;
                                   end;
                                 end else begin Production_type:=0; Production_count:=0; end;
                                 {x}
                                 if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
                                     (Race = ThisCompRace3) or (Race = ThisCompRace4) or
                                     (Race = ThisCompRace5)) then begin
                                 { prirad novou jednotku do TaskGroup }
                                    bebex:=44;
                                    if (TaskGrp = CreateNewTaskGroupNumber) then
                                        TaskGroupCommand(Race,CreateNewTaskGroup(Race,255,Units[Ind]),
                                                         TaskCommand,0,4,0,0,0)
                                    else {Error(0,'unita _buildin, procedura Building_manager, bod 0')};
                                 end;
                                 bebex:=45;
                                 if ((Unit_types[ProductIndex,Races[Race].Ally].UnitLevel = 3) and
                                     (Unit_types[ProductIndex,Races[Race].Ally].SpecAirLevel = 0))
                                 then with (Units[Ind]^) do begin
                                 { posli vzdusnou jednotku na letiste }
                                     bebex:=46;
                                     WayPointUk:=0; WayPointMax:=0;
                                     WayPoint[WayPointUk].IAim:=IAirport;
                                     WayPoint[WayPointUk].JAim:=JAirport;
                                     Return_to_base:=True;
                                     WayPointMax:=0; WayPointUk:=0;
                                     Set_move_unit(WayPoint[WayPointUk].IAim,
                                                   WayPoint[WayPointUk].JAim,Units[Ind],1,False,False);
                                 end else if ((WayPointMax <> 255) and
                                              (WayPointUk <> 255)) then begin
                                   Bool:=True;
                                   for I:=0 to WayPointMax do
                                   with (WayPoint[I]) do begin
                                   { testuje dostupnost cile  }
                                      bebex:=47;
                                      Bool:=Bool and Free_place_three2(IAim,JAim,
                                           Unit_types[Units[Ind]^.UnitType,Races[Race].Ally].IUnitSize,
                                           Unit_types[Units[Ind]^.UnitType,Races[Race].Ally].JUnitSize,
                                           Level,Units[Ind]);
                                   end;
                                   if (Bool) then begin
                                   { OK, waypoint mozne priradit }
                                     bebex:=48;
                                     with (Units[Ind]^) do begin
                                       WayPointUk:=0;
                                       WayPointMax:=Buildings[J]^.WayPointMax;
                                       WayPoint:=Buildings[J]^.WayPoint;
                                     end;
                                     with (WayPoint[0]) do begin
                                       bebex:=49;
                                       Set_move_unit(IAim,JAim,Units[Ind],Level,False,False);
                                     end;
                                   end;
                                 end;
                              end;
                          end;
                          OK:=True; Free:=False;
                       end else begin  { volne misto nenalezeno }
                          Inc(K);
                       end;
                    end; { with }
                    bebex:=50;
                    if (not OK) then with (Unit_types[ProductIndex,Races[Race].Ally]) do begin
                    { VOLNE MISTO NENALEZENO ! }
                       bebex:=51;
                       if (Rac = MyRace) then
                          OutBigMsg(10,'NENALEZENO VOLNc MeSTO PRO JEDNOTKU');
UnAlloc:
                       { odalokovani materialu }
                       Inc(Races[Rac].Building_credits,BP);
                       Inc(Races[Rac].Plastic_credits,PL);
                       Inc(Races[Rac].Electric_energy,EE);
                       Inc(Races[Rac].Battle_experience,EX);
                       if (BP <> 0) then Print_material(1,Races[Rac].Building_credits);
                       if (PL <> 0) then Print_material(2,Races[Rac].Plastic_credits);
                       if (EE <> 0) then Print_material(3,Races[Rac].Electric_energy);
                       if (EX <> 0) then Print_material(4,Races[Rac].Battle_experience);
                       {x}
                       Production_count:=0; Production_type:=0;
                       bebex:=52;
                       if (Buildings[J]^.Group = ActiveGroup) then
                         Draw_building_production(Buildings[J]);
                       {x}
                    end;
                end else begin {6}
                { *** budovy }
                    bebex:=53;
                    Production_type:=0;
                    while ((not OK) and (K <= MaxIndex)) do  { hledej misto pro vylozeni }
                    with (FreePlaces[K]) do begin
                       if (Free and Free_place_two(IP,JP,Unit_types[33,Races[Race].Ally].IUnitSize,
                                               Unit_types[33,Races[Race].Ally].JUnitSize,33))
                       then begin { flek nalezen }
                          bebex:=54;
                          OK:=True; Free:=False;
                          Ind:=New_unit(IP,JP,33,Rac,0,Experienc,Visibilit,False,ProductIndex);
                          if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
                              (Race = ThisCompRace3) or (Race = ThisCompRace4) or
                              (Race = ThisCompRace5)) then begin
                          { prirad novou budovu do TaskGroup }
                               bebex:=55;
                               TaskGroupCommand(Race,CreateNewTaskGroup(Race,CreateNewTaskGroupNumber,Units[Ind]),
                                                MoveBuildCom,0,4,0,0,0)
                          end;
                          bebex:=56;
                          if (Rac = MyRace) then
                             OutBigMsg(2,'BUDOVA VYROBENA');
                       end else begin  { volne misto nenalezeno }
                          Inc(K);
                       end;
                    end; { with (FreePlaces[K]) do begin }
                    bebex:=57;
                    if (not OK) then with (Building_types[ProductIndex]) do begin
                       { VOLNE MISTO NENALEZENO ! }
                       bebex:=58;
                       if (Rac = MyRace) then
                         OutBigMsg(10,'NENALEZENO VOLNc MeSTO PRO JEDNOTKU');
                       { odalokovani materialu }
                       Inc(Races[Rac].Building_credits,BP);
                       Inc(Races[Rac].Plastic_credits,PL);
                       Inc(Races[Rac].Electric_energy,EE);
                       Inc(Races[Rac].Battle_experience,EX);
                       if (BP <> 0) then Print_material(1,Races[Rac].Building_credits);
                       if (PL <> 0) then Print_material(2,Races[Rac].Plastic_credits);
                       if (EE <> 0) then Print_material(3,Races[Rac].Electric_energy);
                       if (EX <> 0) then Print_material(4,Races[Rac].Battle_experience);
                    end;
                end; {6}
             end; {5}
          end else if (Building_types[BuildingType].ProductionType = 2) then begin
          {4}
          { PRODUKCE PLASTU }
              bebex:=59;
              if (GameTimming = 0) then Inc(Production_phase,2)
              else Inc(Production_phase);
              if (Production_phase >= PLProductionSpeed) then
              with (Races[Race]) do begin
                 bebex:=60;
                 Production_phase:=0;
                 Inc(Plastic_credits,PLProduction);
                 if (Race = MyRace) then UpdatePL:=True;
                 if ((PLProductionBPNeed > Building_credits) or
                     (PLProductionEENeed > Electric_energy) or
                     (Race <> MyRace) and
                     (PLProductionEENeed*3 > Electric_energy)) then begin
                 { nemozno produkovat - nedostatek energie; u pocitace dame
                   trochu rezervy (at nemuze vycerpat EE az k nule) }
                    bebex:=61;
                    Production_phase:=0;
                    Production_percentage:=0;
                    Production_type:=0;
                    if (Race = MyRace) then
                       OutBigMsg(255,'PRODUKCE PLASTi AUTOMATICKY UKONbENA');
                    if (PLProductionBPNeed > Building_credits) then
                       Inc(BPShortage);
                    if (PLProductionEENeed > Electric_energy) then
                       Inc(EEShortage);
                    if (PLShortageForbid > 0) then Dec(PLShortageForbid);
                    if (Group = ActiveGroup) then Click_on_group(ActiveGroup);
                 end else begin
                 { lze produkovat dale }
                    bebex:=62;
                    Dec(Building_credits,PLProductionBPNeed);
                    Dec(Electric_energy,PLProductionEENeed);
                    if (Race = MyRace) then UpdateBP:=True;
                    if (Race = MyRace) then UpdateEEEnergy:=True;
                 end;
              end;
          end; { produkce plastu } {4}
         end else begin { BUDOVA PRODUKUJE } {3}
         { budova neprodukuje }
            bebex:=63;
            if ((Building_types[BuildingType].ProductionType = 3) and
                (not Repair)) then begin
             { vyroba elektricke energie }
               bebex:=64;
               if (GameTimming = 0) then Dec(Production_phase,2)
               else Dec(Production_phase);
               if (Production_phase <= 0) then begin
                  Production_phase:=EEProductionSpeed;
                  bebex:=65;
                  with (Races[Race]) do begin
                     bebex:=66;
                     if ((Electric_energy + EEProduction -
                          ((EEProduction / 100) *
                           ((Electric_energy div EEProductionDecreaseVal)*
                             EEProductionDecrease)) +
                         Round(EE_credits_plus*EEProduction)) > EECapacity)
                     then begin { nedostatek kapacity akumulatoru }
                        bebex:=67;
                        Electric_energy:=EECapacity;
                        if (Race = MyRace) then begin
                           bebex:=68;
                           if (AccumulatorShortageDelay = 0) then begin
                             OutBigMsg(4,'NEDOSTATEbNa KAPACITA AKUMULaTORi');
                             AccumulatorShortageDelay:=GetAccurateDelay(300);
                           end else Dec(AccumulatorShortageDelay);
                        end;
                        Inc(AccumulatorShortage);
                     end else begin
                        bebex:=69;
                        Inc(Electric_energy,EEProduction -
                            Round((EEProduction / 100) *
                                  ((Electric_energy div EEProductionDecreaseVal)*
                                  EEProductionDecrease)));
                        Inc(Electric_energy,Round(EE_credits_plus*
                            (EEProduction - ((EEProduction / 100) *
                             ((Electric_energy div EEProductionDecreaseVal)*
                              EEProductionDecrease)))));
                     end;
                     bebex:=70;
                     if (Race = MyRace) then UpdateEEEnergy:=True;
                  end;
               end;
            end;
         end; {3}
         bebex:=71;
         Dec(EEConsumption_phase);
     {7} if ((EEConsumption_phase <= 0) and
             (BuildingType <> 5) and (BuildingType <> 6) and
             ((BuildingType < 16) or (BuildingType > 25) or (BuildingType = 21)))
         then begin
         { odpocti spotrebu EE energie; prekazka, elektrarna a
           akumulator energii necerpaji }
            bebex:=72;
            EEConsumption_phase:=EEConsumptionSpeed;
            with (Races[Race]) do begin
              if (Electric_energy < -10{EEConsumption}) then begin
              { nedostatek elektricke energie - poskod budovu -
                - dovolime nejakou "vypujcku" }
                 bebex:=73;
                 if (Electric_energy > -ECapacity) then
                    Dec(Electric_energy,EEConsumption);
                 if (Race = MyRace) then
                   if (ElectricShortageDelay = 0) then begin
                      OutBigMsg(3,'NEDOSTATEK ELEKTRICKc ENERGIE');
                      ElectricShortageDelay:=GetAccurateDelay(300);
                   end else Dec(ElectricShortageDelay);
                 if (GameTimming = 0) then Inc(EEShortage)
                 else Inc(EEShortage);
                 {DMGStrength:=Building_types[BuildingType].DefenceStrength;{}
                 DMGStrength:=EELackDamage;
                 DMG:=Damage;
                 bebex:=74;
                 if (DMG <= DMGStrength) then begin { znic budovu }
                    bebex:=75;
                    Phase:=0; Activity:=False;
                    Set_place_building(IPos,JPos,Buildings[J], False);
                    if (Visibility) then Erase_building(Buildings[J]);
                    Set_place_building(IPos,JPos,Buildings[J], True);{}
                    if (Group = ActiveGroup) then with Groups[Group] do begin
                      Clear_group_slots;
                      Deselect_group(ActiveGroup);
                      ActiveGroup:=255;
                    end;
                    Group:=254;
                    Prepare_destroy_building(Buildings[J]);
                 end else begin
                 { pouze poskozeni }
                    bebex:=76;
                    Dec(Damage,Round(DMGStrength));
                    if (Group = ActiveGroup) then
                      Update_building_char(Buildings[J]);
                    with (Building_types[BuildingType]) do begin
                        bebex:=77;
                        if (Damage <= DefenceStrength div 3) then begin
                          FireState:=2;
                          if (BuildPhase <> 7) then begin
                            BuildPhase:=7; RequestDraw:=True;
                          end;
                        end else
                          if (Damage <= DefenceStrength shr 1) then begin
                            FireState:=1;
                            if (BuildPhase <> 6) then begin
                              BuildPhase:=6; RequestDraw:=True;
                            end;
                          end;

                        if ((FirePhase = 0) and FireAllowed and
                            (FireState <> 0)) then FirePhase:=1;
                        if ((IBuildingSize = 1) and (JBuildingSize = 1) and
                            (FireState = 2)) then FireState:=1;
                    end;
                 end;
              end else { dostatek elektricke energie }
                 Dec(Electric_energy,EEConsumption);
            end; {with (Races[Race]) do begin}
            if (Race = MyRace) then UpdateEEEnergy:=True;
         end; {7}
         bebex:=78;
         { proved opravu budov pocitace }
         if (Activity) then with (Building_types[BuildingType]) do begin
           DMG:=DefenceStrength;
           bebex:=79;
           if ((Autorepair > 0) and ((100-1.0*Damage/(DMG/100)) <= Autorepair) and
               (WarningBlingFlag = 0))
           then begin { automaticka oprava }
              bebex:=80;
              Damage:=Round(DMG);
              if ((Damage > DefenceStrength div 2) and (FireState <> 0) and
                  FireAllowed)
              then begin
                 bebex:=81;
                 FireState:=0; FirePhase:=0; RequestDraw:=True;
                 if (BuildPhase = 6) then begin
                   BuildPhase:=4; RequestDraw:=True;
                 end;
              end else
                if ((Damage > DefenceStrength div 3) and (FireState <> 0) and
                    FireAllowed) then  begin
                   bebex:=82;
                   FireState:=1; RequestDraw:=True;
                   if (BuildPhase = 7) then begin
                      BuildPhase:=6; RequestDraw:=True;
                   end;
                end;

              bebex:=83;
              if (Group = ActiveGroup) then
                 Update_building_char(Buildings[J]);
           end;

           if ((Damage < DMG) and (Race <> MyRace) and (not Repair)) then begin
           { zarad budovu do fronty na opravu }
              _unit:=Nil;
              bebex:=84;
              RepairQueue^.Insert(_unit,Buildings[J]);
           end;
         end;
         bebex:=85;
         if (BuildPhase < 4) then begin { budova se stavi }
            bebex:=86;
            if (GameTimming = 0) then Inc(BuildTemp,2)
            else Inc(BuildTemp);
            if (BuildTemp >= GetAccurateDelay(BuildSpeed)) then begin
               BuildTemp:=0;
               Inc(BuildPhase);
               Draw_building(Buildings[J]);
               if ((BuildPhase = 4) and (Race = MyRace) and
                   (Group = ActiveGroup)) then { budova je hotova }
                 Click_on_group(ActiveGroup);
            end;
         end else
           if ((BuildPhase < 6) and (AnimatedBuilding)) then begin
           { zmena fazi budov }
              bebex:=87;
              Inc(BuildTemp);
              if (BuildTemp > BuildPhaseSpeed) then begin
                bebex:=88;
                BuildTemp:=0;
                Inc(BuildAnimPhase);
                if (BuildAnimPhase > Building_types[BuildingType].MaxBuildPhase)
                then BuildAnimPhase:=0;
                RequestDraw:=True;
              end;
           end;
         { OPRAVA }
         bebex:=89;
         if (Activity and Repair)
         then with (Races[Race]) do begin
           bebex:=90;
     {8} { pokracuj v oprave }
       {9} if (RepairsAvailable < 0) then begin
           { nedostatek opravarenske kapacity - zrus opravu }
              bebex:=91;
              Repair:=False; CompRepairFlag:=0;
              Inc(RepairsAvailable,BuildingRepairCapacityNeed);
              if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
              DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
              BPRepairRemainder:=0; PLRepairRemainder:=0;
              EERepairRemainder:=0; EXRepairRemainder:=0;
              BPRepair:=BPRepair - RepairCost*((1.0*Building_types[BuildingType].BP)/100);
              PLRepair:=PLRepair - RepairCost*((1.0*Building_types[BuildingType].PL)/100);
              EERepair:=EERepair - RepairCost*((1.0*Building_types[BuildingType].EE)/100);
              ExpRepair:=ExpRepair - RepairCost*((1.0*Building_types[BuildingType].Ex)/100);
           end else begin {9}
           { NORMALNI OPRAVA }
              bebex:=92;
              if (GameTimming = 0) then Inc(RepairFlag,2) else Inc(RepairFlag);
              if (GameTimming = 0) then Inc(DrawRepairFlag,2) else Inc(DrawRepairFlag);
              DrawRepair:=True;
              RequestDraw:=True;
              if (DrawRepairFlag >= MaxRepairPhase) then begin
              { preklopeni priznaku o kresleni specialniho symbolu }
                 DrawRepairFlag:=0;
              end;
         {10} if (RepairFlag >= RepairSpeed) then with (Building_types[BuildingType]) do begin
              { vlastni oprava}
                 bebex:=93;
                 RepairFlag:=0;
                 PomVal:=BPRepairRemainder;
                 BP2:=BP; BP2:=(BP2/100)*RepairCost+PomVal/1000;
                 BPPom:=Trunc(BP2);
                 BPRepairRemainder:=Round(BP2*1000)-Trunc(BP2)*1000;
                 {}
                 PomVal:=PLRepairRemainder;
                 PL2:=PL; PL2:=(PL2/100)*RepairCost+PomVal/1000;
                 PLPom:=Trunc(PL2);
                 PLRepairRemainder:=Round(PL2*1000)-Trunc(PL2)*1000;
                 {}
                 PomVal:=EERepairRemainder;
                 EE2:=EE; EE2:=(EE2/100)*RepairCost*2+PomVal/1000;
                 EEPom:=Trunc(EE2);
                 EERepairRemainder:=Round(EE2*1000)-Trunc(EE2)*1000;
                 {}
                 PomVal:=EXRepairRemainder;
                 EX2:=EX; EX2:=(EX2/100)*RepairCost+PomVal/1000;
                 EXPom:=Trunc(EX2);
                 EXRepairRemainder:=Round(EX2*1000)-Trunc(EX2)*1000;
                 if ((Building_credits < BPPom) or (Plastic_credits < PLPom) or
                     (Electric_energy < EEPom) or (Battle_experience < EXPom) or
                     (BP > 0) and (Building_credits <= 0) or
                     (PL > 0) and (Plastic_credits <= 0) or
                     (EX > 0) and (Battle_experience <= 0) or
                     (EE > 0) and (Electric_energy <= 0) or
                     (CompRepairFlag > CompRepairFlagLimit) and (Race <> MyRace))
            {11} then begin { nedostatek materialu - zastav opravu }
                    bebex:=94;
                    Repair:=False; CompRepairFlag:=0;
                    Inc(RepairsAvailable,BuildingRepairCapacityNeed);
                    if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
                    DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                    BPRepairRemainder:=0; PLRepairRemainder:=0;
                    EERepairRemainder:=0; EXRepairRemainder:=0;
                    RepairRemainder:=0;
                    BPRepair:=BPRepair - RepairCost*((1.0*Building_types[BuildingType].BP)/100);
                    PLRepair:=PLRepair - RepairCost*((1.0*Building_types[BuildingType].PL)/100);
                    EERepair:=EERepair - RepairCost*((1.0*Building_types[BuildingType].EE)/100);
                    ExpRepair:=ExpRepair - RepairCost*((1.0*Building_types[BuildingType].Ex)/100);
                    if (Race = MyRace) then
                      OutBigMsg(5,'NEDOSTATEK MATERIaLU NA OPRAVU');
                    if (Building_credits < BPPom) then Inc(BPShortage);
                    if (Plastic_credits < PLPom) then Inc(PLShortage);
                    if (Electric_energy < EEPom) then Inc(EEShortage);
                    if (Battle_experience < EXPom) then Inc(EXPShortage);
                 end else begin { oprava OK } {11}
                    bebex:=95;
                    PomVal:=RepairRemainder;
                    DMG:=DefenceStrength;
                    PomVal:=(DMG/100)*RepairValue+PomVal/1000;
                    RepairRemainder:=Round(PomVal*1000)-Trunc(PomVal)*1000;
                    DmgPom:=Trunc(PomVal);
                    if ((Damage+DmgPom) >= DMG) then begin
                       bebex:=96;
                       Damage:=Trunc(DMG); { HOTOVO ! }
                       Repair:=False; CompRepairFlag:=0;
                       Inc(RepairsAvailable,BuildingRepairCapacityNeed);
                       if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
                       DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                       BPRepairRemainder:=0; PLRepairRemainder:=0;
                       EERepairRemainder:=0; EXRepairRemainder:=0;
                       RepairRemainder:=0;
                       BPRepair:=BPRepair - RepairCost*((1.0*Building_types[BuildingType].BP)/100);
                       PLRepair:=PLRepair - RepairCost*((1.0*Building_types[BuildingType].PL)/100);
                       EERepair:=EERepair - RepairCost*((1.0*Building_types[BuildingType].EE)/100);
                       ExpRepair:=ExpRepair - RepairCost*((1.0*Building_types[BuildingType].Ex)/100);
                       if ((Race = MyRace) and
                           (Building_types[BuildingType].ProductionType < 3) and
                           (BuildPhase > 3) and (Group = ActiveGroup)) then begin
                       { obnov produkcni sloty }
                          Clear_group_slots;
                          Click_on_group(ActiveGroup);
                       end;
                    end else Damage:=Damage+DmgPom;
                    bebex:=97;
                    if ((Damage > DefenceStrength div 2) and (FireState <> 0) and
                        FireAllowed)
                    then begin
                       bebex:=98;
                       FireState:=0; FirePhase:=0; RequestDraw:=True;
                       if (BuildPhase = 6) then begin
                         BuildPhase:=4; RequestDraw:=True;
                       end;
                    end else
                      if ((Damage > DefenceStrength div 3) and (FireState <> 0) and
                          FireAllowed) then  begin
                         FireState:=1; RequestDraw:=True;
                         if (BuildPhase = 7) then begin
                            BuildPhase:=6; RequestDraw:=True;
                         end;
                      end;
                    bebex:=99;
                    Dec(Building_credits,BPPom); Dec(Plastic_credits,PLPom);
                    Dec(Electric_energy,EEPom); Dec(Battle_experience,EXPom);
                    if (Group = ActiveGroup) then
                       Update_building_char(Buildings[J]);
                    if (Race = MyRace) then begin
                       UpdateEEEnergy:=True; UpdatePL:=True; UpdateBP:=True;
                       UpdateEXP:=True;
                    end;
                 end; {11}
              end; {10}
           end; {9}
         end else {8}
           if ((not Activity) and Repair) then with (Races[Race]) do begin
           { probiha oprava, budova neni aktivni - zrus opravu }
              bebex:=100;
              Repair:=False; CompRepairFlag:=0;
              Inc(RepairsAvailable,BuildingRepairCapacityNeed);
              if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
              DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
              BPRepairRemainder:=0; PLRepairRemainder:=0;
              EERepairRemainder:=0; EXRepairRemainder:=0;
              RepairRemainder:=0;
              BPRepair:=BPRepair - RepairCost*((1.0*Building_types[BuildingType].BP)/100);
              PLRepair:=PLRepair - RepairCost*((1.0*Building_types[BuildingType].PL)/100);
              EERepair:=EERepair - RepairCost*((1.0*Building_types[BuildingType].EE)/100);
              ExpRepair:=ExpRepair - RepairCost*((1.0*Building_types[BuildingType].Ex)/100);
           end;
           bebex:=101;
           if (RequestDraw and Activity) then Draw_building(Buildings[J]);
           RequestDraw:=False;

      end else begin { 2 }
        { budova exploduje }
        bebex:=102;
        Prepare_destroy_building(Buildings[J]);
      end;

   end; {1}
Kanec:
   Inc(J);
 end; {while}
 bebex:=103;
 SetTerminator_fighterParams(False);
end;

{ ***** }
procedure Building_manager_only_draw;
{ procedura zabezpecuje cinnost budov, jejich exploze ...
}
label UnAlloc;
var I, J: Integer;
begin
 I:=1; J:=1;
 while ((I <= Number_of_buildings) and (J <= (MaxRaceBuildings+1)*(MaxRace+1))) do begin
{1}if (Buildings[J] <> Nil) then with Buildings[J]^ do begin
   { budova na danem indexu existuje }
      Inc(I);
      if (Activity) then begin
      { budova je cinna }
         if (RequestDraw and Activity) then Draw_building(Buildings[J]);
         RequestDraw:=False;
      end;
   end; {1}
   Inc(J);
 end;
end;

{ ***** }
procedure _buildin_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'10'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
   BlockWrite(IOFile,ElectricShortageDelay,SizeOf(ElectricShortageDelay));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
   BlockWrite(IOFile,AccumulatorShortageDelay,SizeOf(AccumulatorShortageDelay));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _buildin_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'10'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)
  then begin Erase(CheckFile);GoTo K;end;
  BlockRead(IOFile,ElectricShortageDelay,SizeOf(ElectricShortageDelay));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
  BlockRead(IOFile,AccumulatorShortageDelay,SizeOf(AccumulatorShortageDelay));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************* }
begin
  ElectricShortageDelay:=0; AccumulatorShortageDelay:=0;
end.