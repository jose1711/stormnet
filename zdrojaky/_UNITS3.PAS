unit _Units3;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, Grafika2, Grafika3, AI, _units4;

procedure Init_units;
procedure Init_units2;
procedure Load_cfg(Way:String);
procedure VictoryConditionManager;
function GetRaceName(Race:Byte):String;
function GetBuildingName(BuildingType:Byte):String;
procedure Raise_group_morale(Group:Byte);
function Range_check(XThis, YThis, XTarget, YTarget : Word; Range : Byte) : Boolean;
procedure Set_move_active_group(I,J:Word; MoveTargetLevel:Byte; GoInsid:Boolean;
                                ClickStatus, Rac:Byte);
procedure Set_move_unit(I,J:Word; var _unit:PUnit; MoveTargetLevel:Byte; BlockMov,Load:Boolean);
procedure Stop_unit(var _unit:PUnit; ManageAirUnits,ManageSpecAirUnits:Boolean);
function Best_direction(IPos, JPos, IAim, JAim : Integer):Byte;
function Best_direction2(IPos, JPos, IAim, JAim : Integer):Byte;
procedure GetBestCarrierLoadPos(var IPs,JPs:Word; IPos,JPos,IHomePos,JHomePos:Word; UnitType:Byte);
function UnBlock_place(I1,J1,I2,J2:Word; Rac:Byte; var _unit:PUnit):Byte;
procedure Get_free_places(var FreePlaces:TFreePlaces; var MaxIndex:Word; IPos,JPos:Word; ISize,JSize:Word);
procedure RepairGroup(Group:Byte);
procedure RepairEnemy(Rac:Byte; Building:PBuilding; Un:PUnit);
procedure Unit_manager;
procedure Unit_manager_only_draw;
procedure _units3_save;
procedure _units3_load;

implementation

uses _units, _units2, buttons2, _shot, _races, AI3, Grafika4;

const Ws : set of Byte = [$0d,$20,$0a];
      Speed : array[0..6] of TSpeedArray =
            ((1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,1,1,1,1,1,1,1,1,1),
             (2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1),
             (2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,1,1,1,1,1,1,1,1,1,1),
             (3,3,3,3,3,3,3,3,3,3,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (5,6,5,5,6,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1));

var MapCfgFile:File;
    IO_Result:Word;
    Character:Char;
    MapCfgFileWay:String;
    MapTxtFile:File;
    MapTxtFileWay:String;

{ ************************************************************************* }
procedure Init_units;
{ provede uvodni inicializaci jednotek, jejich seznamu
}
const X = 5.0;
var I, J:Integer;
begin
   I:=1;
   with Unit_types[I,0] do begin { 1 - NAKLADNI AUTOMOBIL }
      Name := 'NaKLADNe AUTO'; Production_time:=X/15;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=8; { zabira misto } Capacity:=8;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=6; FlashPos[2].X:=10;FlashPos[2].Y:=2;
      FlashPos[3].X:=18;FlashPos[3].Y:=0; FlashPos[4].X:=26;FlashPos[4].Y:=6;
      FlashPos[5].X:=28;FlashPos[5].Y:=16; FlashPos[6].X:=22;FlashPos[6].Y:=24;
      FlashPos[7].X:=12;FlashPos[7].Y:=24; FlashPos[8].X:=6;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 2 - ODPADKOVY HARVESTER }
      Name:= 'RECYKLaTOR';  Production_time:=X/25;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 3 - CIVILISTA }
      Name:= 'CIVILISTA'; Production_time:=X/10;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=40; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=1; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 4 - OSOBNI AUTOMOBIL }
      Name:= 'OSOBNe AUTO';  Production_time:=X/15;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=4; { zabira misto } Capacity:=2;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 5 - SAMOPALNIK }
      Name:= 'PdCHOTA';  Production_time:=X/20;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=15; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=513;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=9;FlashPos[1].Y:=0; FlashPos[2].X:=18;FlashPos[2].Y:=0;
      FlashPos[3].X:=24;FlashPos[3].Y:=6; FlashPos[4].X:=25;FlashPos[4].Y:=15;
      FlashPos[5].X:=18;FlashPos[5].Y:=21; FlashPos[6].X:=7;FlashPos[6].Y:=21;
      FlashPos[7].X:=1;FlashPos[7].Y:=14; FlashPos[8].X:=3;FlashPos[8].Y:=6;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 6 - TANKOBORNIK }
      Name:= 'TdkKa PdCHOTA';  Production_time:=X/21;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=10; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 7 - VYSADKAR }
      Name:= 'VjSADKaf';  Production_time:=X/25;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=12; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=20; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=770;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=6;FlashPos[1].Y:=0; FlashPos[2].X:=14;FlashPos[2].Y:=0;
      FlashPos[3].X:=21;FlashPos[3].Y:=0; FlashPos[4].X:=26;FlashPos[4].Y:=8;
      FlashPos[5].X:=20;FlashPos[5].Y:=16; FlashPos[6].X:=13;FlashPos[6].Y:=19;
      FlashPos[7].X:=0;FlashPos[7].Y:=18; FlashPos[8].X:=0;FlashPos[8].Y:=7;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 8 - JEEP }
      Name:= 'JEEP'; Production_time:=X/20;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=9;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=4; { zabira misto } Capacity:=3;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 9 - VYSADKARSKY TANK }
      Name:= 'AT-24 DEVIL'; Production_time:=X/30;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=15; AirAttack1:=5; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1026;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=3; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=6;FlashPos[1].Y:=9; FlashPos[2].X:=15;FlashPos[2].Y:=6;
      FlashPos[3].X:=22;FlashPos[3].Y:=4; FlashPos[4].X:=26;FlashPos[4].Y:=10;
      FlashPos[5].X:=27;FlashPos[5].Y:=20; FlashPos[6].X:=20;FlashPos[6].Y:=26;
      FlashPos[7].X:=10;FlashPos[7].Y:=24; FlashPos[8].X:=7;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 10 - RAKETOVE VOZIDLO }
      Name:= 'gKORPION'; Production_time:=X/35;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=10; AirAttack1:=10; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1283;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=4; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=3; FlashPos[2].X:=12;FlashPos[2].Y:=0;
      FlashPos[3].X:=30;FlashPos[3].Y:=6; FlashPos[4].X:=30;FlashPos[4].Y:=15;
      FlashPos[5].X:=22;FlashPos[5].Y:=19; FlashPos[6].X:=15;FlashPos[6].Y:=21;
      FlashPos[7].X:=3;FlashPos[7].Y:=18; FlashPos[8].X:=0;FlashPos[8].Y:=12;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 11 - TRANSPORTER }
      Name:= 'ALIGaTOR';  Production_time:=X/27;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 12 - BVP }
      Name:= 'BVP'; Production_time:=X/26;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=9; { zabira misto } Capacity:=6;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 13 - TANK }
      Name:= 'T-90 SIBERIA'; Production_time:=X/38;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=20; AirAttack1:=0; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=6;FlashPos[1].Y:=12; FlashPos[2].X:=12;FlashPos[2].Y:=7;
      FlashPos[3].X:=21;FlashPos[3].Y:=6; FlashPos[4].X:=27;FlashPos[4].Y:=12;
      FlashPos[5].X:=26;FlashPos[5].Y:=18; FlashPos[6].X:=17;FlashPos[6].Y:=24;
      FlashPos[7].X:=8;FlashPos[7].Y:=24; FlashPos[8].X:=5;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 14 - SAMOCHODKA }
      Name:= 'MC MAMUT'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=25; AirAttack1:=5; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1795;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=130; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=3;FlashPos[1].Y:=9; FlashPos[2].X:=12;FlashPos[2].Y:=5;
      FlashPos[3].X:=23;FlashPos[3].Y:=7; FlashPos[4].X:=27;FlashPos[4].Y:=16;
      FlashPos[5].X:=22;FlashPos[5].Y:=21; FlashPos[6].X:=20;FlashPos[6].Y:=24;
      FlashPos[7].X:=9;FlashPos[7].Y:=21; FlashPos[8].X:=5;FlashPos[8].Y:=14;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 15 - COMMANDOS }
      Name:= 'KOMANDOS'; Production_time:=X/44;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=1; HeavyAttack1:=1; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=2049;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=50; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=3;FlashPos[1].Y:=0; FlashPos[2].X:=15;FlashPos[2].Y:=0;
      FlashPos[3].X:=24;FlashPos[3].Y:=3; FlashPos[4].X:=26;FlashPos[4].Y:=13;
      FlashPos[5].X:=20;FlashPos[5].Y:=19; FlashPos[6].X:=9;FlashPos[6].Y:=23;
      FlashPos[7].X:=3;FlashPos[7].Y:=16; FlashPos[8].X:=0;FlashPos[8].Y:=8;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 16 - TEZKY TANK }
      Name:= 'A2M3 HROCH'; Production_time:=X/48;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=20; AirAttack1:=0; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1538;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=130; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=12; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=7;FlashPos[1].Y:=7; FlashPos[2].X:=15;FlashPos[2].Y:=6;
      FlashPos[3].X:=24;FlashPos[3].Y:=8; FlashPos[4].X:=25;FlashPos[4].Y:=14;
      FlashPos[5].X:=27;FlashPos[5].Y:=22; FlashPos[6].X:=15;FlashPos[6].Y:=27;
      FlashPos[7].X:=7;FlashPos[7].Y:=24; FlashPos[8].X:=6;FlashPos[8].Y:=14;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 17 - VYSADKOVY LETOUN }
      Name:= 'PARA LETOUN';  Production_time:=X/30;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=55; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=12;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=0; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 18 - STIHAC }
      Name:= 'EURO EF-2005'; Production_time:=X/50;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=10; HeavyAttack1:=10; AirAttack1:=50; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1281;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=1;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=2;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=0; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 19 - Protizemni stihac - Terminator}
      Name:= 'TERMINaTOR'; Production_time:=X/50;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=100; HeavyAttack1:=60; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1281;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=1;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=2;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=0; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 20 - LEHKA PEVNOST }
      Name:= 'LEHKa PEVNOST'; Production_time:=X/40;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=30; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=20; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=1283;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=24;  ShootSpeed2:=21; { kadence strelby }
      DefenceStrength:=160; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=20; { zabira misto } Capacity:=3;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=1;FlashPos[1].Y:=5; FlashPos[2].X:=9;FlashPos[2].Y:=1;
      FlashPos[3].X:=24;FlashPos[3].Y:=6; FlashPos[4].X:=23;FlashPos[4].Y:=12;
      FlashPos[5].X:=21;FlashPos[5].Y:=18; FlashPos[6].X:=9;FlashPos[6].Y:=18;
      FlashPos[7].X:=3;FlashPos[7].Y:=17; FlashPos[8].X:=1;FlashPos[8].Y:=11;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
end;

{ ***** }
procedure Init_units2;
{
}
const X = 5.0;
var I, J:Integer;
begin
   I:=21;
   with Unit_types[I,0] do begin { 21 - TEZKA PEVNOST }
      Name:= 'TdkKa PEVNOST'; Production_time:=X/50;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=20; AirAttack1:=5; { sila utoku }
      LightAttack2:=20; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=1795;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=27;  ShootSpeed2:=21; { kadence strelby }
      DefenceStrength:=220; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=25; { zabira misto } Capacity:=4;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=5;FlashPos[1].Y:=9; FlashPos[2].X:=12;FlashPos[2].Y:=4;
      FlashPos[3].X:=29;FlashPos[3].Y:=8; FlashPos[4].X:=28;FlashPos[4].Y:=15;
      FlashPos[5].X:=21;FlashPos[5].Y:=20; FlashPos[6].X:=12;FlashPos[6].Y:=20;
      FlashPos[7].X:=10;FlashPos[7].Y:=21; FlashPos[8].X:=4;FlashPos[8].Y:=15;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 22 - ROBOT }
      Name:= 'BOJOVj ROBOT'; Production_time:=X/25;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=15; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=513;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=11;FlashPos[1].Y:=5; FlashPos[2].X:=17;FlashPos[2].Y:=4;
      FlashPos[3].X:=22;FlashPos[3].Y:=5; FlashPos[4].X:=24;FlashPos[4].Y:=10;
      FlashPos[5].X:=21;FlashPos[5].Y:=15; FlashPos[6].X:=16;FlashPos[6].Y:=18;
      FlashPos[7].X:=11;FlashPos[7].Y:=16; FlashPos[8].X:=8;FlashPos[8].Y:=9;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 23 - KAMIKADZE }
      Name:= 'AUTODETONaTOR'; Production_time:=X/40;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=80; HeavyAttack1:=80; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=257;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=5; AttackLevel2:=5; { specialni atribut utoku }
      Picture1:=7; Picture2:=7; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 24 - MECHWARRIOR }
      Name:= 'M1 MECHWARRIOR'; Production_time:=X/42;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=4; Picture2:=4; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 25 - VZNASEDLO }
      Name:= 'LEHKc VZNagEDLO'; Production_time:=X/34;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=8; { zabira misto } Capacity:=4;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=2; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 26 - TEZKE VZNASEDLO }
      Name:= 'TdkKc VZNagEDLO'; Production_time:=X/38;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=160; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=9; { zabira misto } Capacity:=7;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=2; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 27 - TANK }
      Name:= 'LEOPARD'; Production_time:=X/36;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=20; HeavyAttack1:=25; AirAttack1:=0; { sila utoku }
      LightAttack2:=12; HeavyAttack2:=7; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=9; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=7;FlashPos[1].Y:=11; FlashPos[2].X:=13;FlashPos[2].Y:=7;
      FlashPos[3].X:=25;FlashPos[3].Y:=10; FlashPos[4].X:=25;FlashPos[4].Y:=17;
      FlashPos[5].X:=22;FlashPos[5].Y:=22; FlashPos[6].X:=18;FlashPos[6].Y:=23;
      FlashPos[7].X:=10;FlashPos[7].Y:=22; FlashPos[8].X:=7;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 28 - RAKETOMET }
      Name:= 'MLRS';  Production_time:=X/35;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=20; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=2051;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=3; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 29 - MUTANT }
      Name:= 'BOJOVj MUTANT'; Production_time:=X/24;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=5; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=2051;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=3; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 30 - LETAJICI TALIR }
      Name:= 'ROBO HAWK'; Production_time:=X/41;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=10; HeavyAttack1:=15; AirAttack1:=10; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=10;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 31 - RAKETOVA VEZ }
      Name:= 'RAKETOVa Vdk'; Production_time:=X/47;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=15; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=10; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=1539;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=12; { kadence strelby }
      DefenceStrength:=150; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=15; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=4; Picture2:=0; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=11;FlashPos[1].Y:=6; FlashPos[2].X:=17;FlashPos[2].Y:=6;
      FlashPos[3].X:=23;FlashPos[3].Y:=6; FlashPos[4].X:=22;FlashPos[4].Y:=11;
      FlashPos[5].X:=22;FlashPos[5].Y:=16; FlashPos[6].X:=16;FlashPos[6].Y:=17;
      FlashPos[7].X:=11;FlashPos[7].Y:=16; FlashPos[8].X:=10;FlashPos[8].Y:=11;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 32 - INFRA SAM }
      Name:= 'PVO BATERIE'; Production_time:=X/42;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=20; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=30;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=150; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=15; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=4; Picture2:=4; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 33 - BUDOVA VE FORME VOZIDLA }
      Name:= 'TRUCK'; Production_time:=X/39;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 34 - HELIKOPTERA }
      Name:= 'AH-70 SIOUX'; Production_time:=X/39;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=15; HeavyAttack1:=15; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1025;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 35 - LEHKY KANON }
      Name:= 'MC TERMIT';  Production_time:=X/27;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=20; HeavyAttack1:=20; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1795;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=50; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 36 - ANTITANK }
      Name:= 'TIGER'; Production_time:=X/32;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=5; HeavyAttack1:=30; AirAttack1:=0; { sila utoku }
      LightAttack2:=5; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=12; { kadence strelby }
      DefenceStrength:=90; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=9;FlasHPos[1].Y:=9; FlashPos[2].X:=11;FlashPos[2].Y:=7;
      FlashPos[3].X:=18;FlashPos[3].Y:=7; FlashPos[4].X:=23;FlashPos[4].Y:=13;
      FlashPos[5].X:=28;FlashPos[5].Y:=7; FlashPos[6].X:=18;FlashPos[6].Y:=18;
      FlashPos[7].X:=12;FlashPos[7].Y:=16; FlashPos[8].X:=8;FlashPos[8].Y:=14;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);

   with Unit_types[I,0] do begin { 37 - HELIKOPTERA NA ZEMI }
      Name:= 'CHINOOK'; Production_time:=X/40;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);

   with Unit_types[I,0] do begin { 38 - OSPREY NA ZEMI }
      Name:= 'OSPREY'; Production_time:=1.2;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=95; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=12;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 39 - LIKVIDATOR }
      Name:= 'M2 LIKVIDaTOR'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 40 - TERORISTA }
      Name:= 'TERORISTA'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types[I,0] do begin { 41 - Centrum Posil }
      Name:= 'CENTRUM POSIL'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=250; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=255;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end;  Inc(I);
   with Unit_types[I,0] do begin { 42 - GUNBOAT }
      Name:= 'DdLOVj bLUN'; Production_time:=X/60;
      BP:=1; PL:=1; EE:=1; EX:=1;
      TargetTyp:=2;
      LightAttack1:=100; HeavyAttack1:=120; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=8 shl 8;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=3;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=250; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=255; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=4; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      SpeedLevel:=3;
      MovementAdding:=Speed[SpeedLevel];
      Parent:=14; Autorepair:=0;
   end;  Inc(I);
   with Unit_types[I,0] do begin { 43 - MISSILE BOAT }
      Name:= 'RAKETOVj bLUN'; Production_time:=X/60;
      BP:=1; PL:=1; EE:=1; EX:=1;
      TargetTyp:=2;
      LightAttack1:=80; HeavyAttack1:=150; AirAttack1:=40; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=7 shl 8;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=3;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=280; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=5; Picture2:=0; { obrazky strel }
      UnitLevel:=4; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      SpeedLevel:=4;
      MovementAdding:=Speed[SpeedLevel];
      Parent:=14; Autorepair:=0;
   end;  Inc(I);
   with Unit_types[I,0] do begin { 44 - DESTROYER }
      Name:= 'DESTROYER'; Production_time:=X/60;
      BP:=1; PL:=1; EE:=1; EX:=1;
      TargetTyp:=2;
      LightAttack1:=120; HeavyAttack1:=120; AirAttack1:=20; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=10 shl 8;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=5;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=380; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=4;  { kapacita jednotky }
      _Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=4; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      SpeedLevel:=2;
      MovementAdding:=Speed[SpeedLevel];
      Parent:=14; Autorepair:=0;
   end;

   for I:=1 to MaxTypesOfUnits do Unit_types[I,1]:=Unit_types[I,0];

   { NYNI SE PROVEDE VYNULOVANI POLE JEDNOTEK A STREL }
   for I:=1 to (MaxRaceUnits+1)*(MaxRace+1) do Units[I]:=Nil;
   Number_of_units:=0;
   for I:=1 to MaxMovingObjects do Shots[I]:=Nil;
   { VYNULOVANI ULOZENYCH SKUPIN }
   for I:=0 to MaxGroups do with Groups[I] do begin
      Count:=0; ClickStatus:=0; GroupLevel:=0;
      for J:=0 to MaxGroupUnits-1 do Un[J]:=Nil;
      Building:=Nil;
   end;

   for I:=0 to MaxGroupUnits-1 do with GroupsBck[I] do begin
      Active:=False;
   end;
   ActiveGroup:=255;
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
   ReadWord(IBeg); ReadWord(JBeg);
   { nejprve zdroje ras: RASAx BP= xxx PL = xxx EE= xxx Exp= xxx }
   for I:=0 to MaxRace do with (Races[I]) do begin
      ReadString(Ret);
      ReadString(Ret); ReadWord(Word(Building_credits));
      ReadString(Ret); ReadWord(Word(Plastic_credits));
      ReadString(Ret); ReadWord(Word(Electric_energy));
      ReadString(Ret); ReadWord(Word(Battle_experience));
      ReadString(Ret); ReadWord(Num);
      Harvester_credits_plus:=Num;
      Harvester_credits_plus:=Harvester_credits_plus/100;
      ReadString(Ret); ReadWord(Num);
      EE_credits_plus:=Num;
      EE_credits_plus:=EE_credits_plus/100;
   end;

   { nyni definujeme cisla jednotek, ktere je mozne vyrabet }
   for I:=0 to MaxRace do with (Races[I]) do begin
      { nejprve jednotky }
      ReadString(Ret);
      ReadWord(Num); J:=1;
      while (Num <> 255) do begin
        PermittedUnits[Num]:=True;
        ReadWord(Num);
        Inc(J);
      end;
      { nyni budovy }
      ReadString(Ret);
      ReadWord(Num); J:=1;
      while (Num <> 255) do begin
        PermittedBuildings[Num]:=True;
        ReadWord(Num);
        Inc(J);
      end;{}
   end;

   { nyni nazvy ras: }
   for I:=0 to MaxRace do with (Races[I]) do begin
      ReadString(Ret); ReadString(RaceName);
   end;

   { nyni vstupni opravarenska kapacita: }
   for I:=0 to MaxRace do with (Races[I]) do begin
      ReadString(Ret); ReadWord(MaxRepairCapacity);
      RepairsAvailable:=MaxRepairCapacity;
   end;

   { nyni odvaha Ras: }
   for I:=0 to MaxRace do with (Races[I]) do begin
      ReadString(Ret); { nazev rasy }
      ReadString(Ret); { TGNum }
      ReadWord(AttackTGNum); ReadWord(DefenceTGNum); ReadWord(SaboteurTGNum);
      {x} { utocna TG1 }
      ReadString(Ret); { utocna TG1 }
      ReadWord(RacesTGInfo^[I,0].LeaderCourageLow); RacesTGInfo^[I,2].LeaderCourageLow:=RacesTGInfo^[I,0].LeaderCourageLow;
      ReadWord(RacesTGInfo^[I,0].LeaderCourageHigh);RacesTGInfo^[I,2].LeaderCourageHigh:=RacesTGInfo^[I,0].LeaderCourageHigh;
      ReadWord(RacesTGInfo^[I,0].MoveCourageNormal);RacesTGInfo^[I,2].MoveCourageNormal:=RacesTGInfo^[I,0].MoveCourageNormal;
      ReadWord(RacesTGInfo^[I,0].IHomeTaskGroupInfoPos); RacesTGInfo^[I,2].TGAtt:=RacesTGInfo^[I,0].IHomeTaskGroupInfoPos;
      ReadWord(RacesTGInfo^[I,0].JHomeTaskGroupInfoPos); RacesTGInfo^[I,2].TGAtt:=RacesTGInfo^[I,0].JHomeTaskGroupInfoPos;
      ReadWord(A); ReadWord(B);
      RacesTGInfo^[I,0].ActivityGameTime:=LongInt(A)*60+B;
      RacesTGInfo^[I,2].ActivityGameTime:=RacesTGInfo^[I,0].ActivityGameTime;
      ReadWord(Temp); ReadWord(Temp);
      ReadString(Ret); { utocna TG2 }
      ReadWord(RacesTGInfo^[I,1].LeaderCourageLow); RacesTGInfo^[I,3].LeaderCourageLow:=RacesTGInfo^[I,1].LeaderCourageLow;
      ReadWord(RacesTGInfo^[I,1].LeaderCourageHigh);RacesTGInfo^[I,3].LeaderCourageHigh:=RacesTGInfo^[I,1].LeaderCourageHigh;
      ReadWord(RacesTGInfo^[I,1].MoveCourageNormal);RacesTGInfo^[I,3].MoveCourageNormal:=RacesTGInfo^[I,1].MoveCourageNormal;
      ReadWord(RacesTGInfo^[I,1].IHomeTaskGroupInfoPos); RacesTGInfo^[I,3].TGAtt:=RacesTGInfo^[I,1].IHomeTaskGroupInfoPos;
      ReadWord(RacesTGInfo^[I,1].JHomeTaskGroupInfoPos); RacesTGInfo^[I,3].TGAtt:=RacesTGInfo^[I,1].JHomeTaskGroupInfoPos;
      ReadWord(A); ReadWord(B);
      RacesTGInfo^[I,1].ActivityGameTime:=LongInt(A)*60+B;
      RacesTGInfo^[I,3].ActivityGameTime:=RacesTGInfo^[I,1].ActivityGameTime;
      ReadWord(Temp); ReadWord(Temp);
      {x} { obranna TG }
      ReadString(Ret); { obranna TG1 }
      ReadWord(RacesTGInfo^[I,4].LeaderCourageLow); RacesTGInfo^[I,6].LeaderCourageLow:=RacesTGInfo^[I,4].LeaderCourageLow;
      ReadWord(RacesTGInfo^[I,4].LeaderCourageHigh);RacesTGInfo^[I,6].LeaderCourageHigh:=RacesTGInfo^[I,4].LeaderCourageHigh;
      ReadWord(RacesTGInfo^[I,4].MoveCourageNormal);RacesTGInfo^[I,6].MoveCourageNormal:=RacesTGInfo^[I,4].MoveCourageNormal;
      ReadWord(RacesTGInfo^[I,4].TGAtt); RacesTGInfo^[I,6].TGAtt:=RacesTGInfo^[I,4].TGAtt;
      ReadWord(RacesTGInfo^[I,4].IHomeTaskGroupInfoPos); RacesTGInfo^[I,6].TGAtt:=RacesTGInfo^[I,4].IHomeTaskGroupInfoPos;
      ReadWord(RacesTGInfo^[I,4].JHomeTaskGroupInfoPos); RacesTGInfo^[I,6].TGAtt:=RacesTGInfo^[I,4].JHomeTaskGroupInfoPos;
      ReadWord(Temp);
      if (Temp = 0) then RacesTGInfo^[I,4].TGDefenseLimitModif:=10
      else RacesTGInfo^[I,4].TGDefenseLimitModif:=(1.0*Temp)/10;
      RacesTGInfo^[I,6].TGDefenseLimitModif:=RacesTGInfo^[I,4].TGDefenseLimitModif;
      ReadWord(Temp);
      ReadString(Ret); { obranna TG2 }
      ReadWord(RacesTGInfo^[I,5].LeaderCourageLow); RacesTGInfo^[I,7].LeaderCourageLow:=RacesTGInfo^[I,5].LeaderCourageLow;
      ReadWord(RacesTGInfo^[I,5].LeaderCourageHigh);RacesTGInfo^[I,7].LeaderCourageHigh:=RacesTGInfo^[I,5].LeaderCourageHigh;
      ReadWord(RacesTGInfo^[I,5].MoveCourageNormal);RacesTGInfo^[I,7].MoveCourageNormal:=RacesTGInfo^[I,5].MoveCourageNormal;
      ReadWord(RacesTGInfo^[I,5].TGAtt); RacesTGInfo^[I,7].TGAtt:=RacesTGInfo^[I,5].TGAtt;
      ReadWord(RacesTGInfo^[I,5].IHomeTaskGroupInfoPos); RacesTGInfo^[I,7].TGAtt:=RacesTGInfo^[I,5].IHomeTaskGroupInfoPos;
      ReadWord(RacesTGInfo^[I,5].JHomeTaskGroupInfoPos); RacesTGInfo^[I,7].TGAtt:=RacesTGInfo^[I,5].JHomeTaskGroupInfoPos;
      ReadWord(Temp);
      if (Temp = 0) then RacesTGInfo^[I,5].TGDefenseLimitModif:=10
      else RacesTGInfo^[I,5].TGDefenseLimitModif:=(1.0*Temp)/10;
      RacesTGInfo^[I,7].TGDefenseLimitModif:=RacesTGInfo^[I,5].TGDefenseLimitModif;
      ReadWord(Temp);
      {x} { sabotazni TG1 }
      for J:=8 to 9 do begin
         ReadString(Ret); { sabotazni TG1 }
         ReadWord(RacesTGInfo^[I,J].LeaderCourageLow); ReadWord(RacesTGInfo^[I,J].LeaderCourageHigh);
         ReadWord(RacesTGInfo^[I,J].MoveCourageSabot); ReadWord(RacesTGInfo^[I,J].IHomeTaskGroupInfoPos);
         ReadWord(RacesTGInfo^[I,J].JHomeTaskGroupInfoPos);
         ReadWord(Temp);
         case ((Temp and 192) shr 6) of { zaporna odchylka }
           0 : RacesTGInfo^[I,J].TimmerMinus:=0;
           1 : RacesTGInfo^[I,J].TimmerMinus:=10;
           2 : RacesTGInfo^[I,J].TimmerMinus:=25;
           3 : RacesTGInfo^[I,J].TimmerMinus:=33;
         end;
         case ((Temp and 48) shr 4) of { kladna odchylka }
           0 : RacesTGInfo^[I,J].TimmerPlus:=0;
           1 : RacesTGInfo^[I,J].TimmerPlus:=10;
           2 : RacesTGInfo^[I,J].TimmerPlus:=25;
           3 : RacesTGInfo^[I,J].TimmerPlus:=33;
         end;
         case ((Temp and 12) shr 2) of { kladna odchylka }
           0 : RacesTGInfo^[I,J].SaboteurType:=100;
           1 : RacesTGInfo^[I,J].SaboteurType:=75;
           2 : RacesTGInfo^[I,J].SaboteurType:=50;
           3 : RacesTGInfo^[I,J].SaboteurType:=25;
         end;
         case (Temp and 3) of { pevne intervaly }
           0 : begin RacesTGInfo^[I,J].Timmer1:=1000; RacesTGInfo^[I,J].Timmer2:=100; end;
           1 : begin RacesTGInfo^[I,J].Timmer1:=2000; RacesTGInfo^[I,J].Timmer2:=800; end;
           2 : begin RacesTGInfo^[I,J].Timmer1:=2500; RacesTGInfo^[I,J].Timmer2:=1500;end;
           3 : begin RacesTGInfo^[I,J].Timmer1:=3000; RacesTGInfo^[I,J].Timmer2:=2200;end;
         end;
         { Timmer1 - od vytvoreni 1. jednotky sabotazni TG }
         { Timmer2 - od zniceni posledni jednotky sabotazni TG }
         ReadWord(A); ReadWord(B);
         RacesTGInfo^[I,J].ActivityGameTime:=LongInt(A)*60+B;
      end;
      {x} { zalozni TG }
      ReadString(Ret); { zalozni TG }
      ReadWord(RacesTGInfo^[I,10].LeaderCourageLow);
      ReadWord(RacesTGInfo^[I,10].LeaderCourageHigh);
      ReadWord(RacesTGInfo^[I,10].MoveCourageNormal);
      ReadWord(RacesTGInfo^[I,10].TGAtt);
      ReadWord(RacesTGInfo^[I,10].IHomeTaskGroupInfoPos);
      ReadWord(RacesTGInfo^[I,10].JHomeTaskGroupInfoPos);
      ReadWord(Temp);
      if (Temp = 0) then RacesTGInfo^[I,10].TGDefenseLimitModif:=1
      else RacesTGInfo^[I,10].TGDefenseLimitModif:=Temp;
      ReadWord(Temp);
   end;

   for I:=0 to MaxRace do with (Races[I]) do begin
      ReadString(Ret); { nazev rasy }
      ReadString(Ret); { xx }
      ReadWord(OverStrengthEnemy);
      if (I = 0) then TerrainCondition:=OverStrengthEnemy and 15;
      ReadString(Ret); { xx }
      ReadWord(DefInstalPriority); ReadWord(Temp); ReadWord(Temp);
      ReadWord(Temp); ReadWord(Temp); ReadWord(ParaEnabled);
      ReadString(Ret); { xx }
      ReadWord(MaxRecyclatorNum); ReadWord(InitUnitLevel); ReadWord(Temp);
      if (Temp <> 0) then ChangeOnVisib:=True else ChangeOnVisib:=False;
   end;

   { unknown terrain, fog of war }
   ReadString(Ret);
   ReadString(Ret); if (Ret = 'TRUE') then Fog_of_war:=True
                    else Fog_of_war:=False;
   ReadString(Ret);
   ReadString(Ret); if (Ret = 'TRUE') then AllyFog:=True
                    else AllyFog:=False;
   ReadString(Ret);
   ReadString(Ret); if (Ret = 'TRUE') then Unknown_terrain:=True
                    else Unknown_terrain:=False;

   { seznam posil }
   ReadString(Ret);
   ReadString(Ret); ReadWord(Num); { pocet posil }
   for I:=1 to Num do begin
      ReadString(Ret);
      ReadWord(Race); { rasa }
      ReadWord(A); ReadWord(B); Time:=LongInt(A)*60+B;
      ReadWord(RndFact); ReadWord(ReinfoTyp);
      ReadWord(Temp);

      Ok:=(ReinfoTyp and 128 = 128) and (Races[Race].Ally = 0);
      Core:=(ReinfoTyp and 128 = 128) and (Race = MyRace);
      if (ReinfoTyp and 128 = 128) then ReinfoTyp:=ReinfoTyp-128;
      Reinforcement^[I-1].Init(Race,Time,RndFact,Ok,Core);

      if (ReinfoTyp = 0) then begin
        for J:=1 to Temp do begin { zaznamy posil jednotek }
           ReadWord(Typ); ReadString(Ret); ReadWord(Rank);
           ReadWord(A); ReadWord(TGNum);
           Reinforcement^[I-1].NewMember(Typ,Ret,Rank,A,TGNum);
        end;
      end else begin
        for J:=1 to Temp do begin { zaznamy posil materialu }
           ReadWord(B); ReadWord(P); ReadWord(E); ReadWord(X);
           Reinforcement^[I-1].NewMemberMat(B,P,E,X);
        end;
      end;
   end;

   {nyni seznam "zakazaneho" terenu: }
   ReadString(Ret);
   ReadString(Ret); ReadWord(Num);
   ReadString(Ret);
   for I:=1 to Num do begin
      ReadWord(A); ReadWord(B);
      MapInfo^[A,B].Pruchozi:=False;
   end;

   Close(MapCfgFile); I:=IOResult;
end;

{ ***** }
procedure VictoryConditionManager;
{ testuje, zda byly (ne)splneny vsechny podminky pro konec hry
  dulezite promenne: Victory,EndOfGame
}
var I,J,K,L,Pom:Word;
    OSNZero, RobotsZero:Boolean; { True, je dana strana zcela vybita }
    AllTrue, Tag:Boolean; { True, jsou-li dane podminky splneny }
    RacesInfo: array[0..MaxRace] of Byte;
    RacesInfo2: array[0..MaxRace] of Byte;
begin
 {if (not Retreat) then begin{}
   { nejprve testujeme, zda se nepratele nevybili }
   OSNZero:=True; RobotsZero:=True; Pom:=0;
   for K:=0 to MaxRace do with (Races[K]) do begin
      I:=0; J:=1;  { I = indikator poctu existujicich objektu }
      L:=0; { L = indikator poctu existujicich budov }
      while ((I = 0) and (J <= MaxTypesOfUnits)) do begin
         I:=ExistUnits[J]; Inc(J);
      end;
      {x}
      if (I > 0) then begin
        if ((Friend[MyRace] = 0) and (not Neutral)) then Pom:=Pom+I;
      end;
      {x}
      J:=1;
      while ((I = 0) or (L = 0)) and (J <= MaxTypesOfBuildings) do begin
         if (I = 0) then I:=ExistBuildings[J];
         L:=ExistBuildings[J]; Inc(J);
      end;
      {x}
      if (I > 0) then begin
        if ((Friend[MyRace] = 2) and (not Neutral)) then OSNZero:=False;
        if ((Friend[MyRace] = 0) and (not Neutral)) then RobotsZero:=False;
      end;
      {}
      RacesInfo[K]:=I; { existence objektu rasy K }
      RacesInfo2[K]:=L; { existence budov rasy K }
   end;
   if ((L = 0) and (Pom <= 3) and (TimeSlot mod 100 = 0) and AnalyzeMap) then RobotsZero:=True;{}
   if (OSNZero) then begin
     if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
     Victory:=-1;
   end;
   if (RobotsZero) then begin
      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
      Victory:=1;
   end;
   { vitezstvi se dale muze prekvalifikovat na remizu, pokud byly
     deklarovany ale nesplneny nejake podminky pro ukonceni mise }
   if (OSNZero and RobotsZero) then begin
      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
      Victory:=0;
   end;
   { xxx }
   { nyni testovani ostatnich podminek: }
   AllTrue:=False;
   if (CondUk > -1) then begin
      AllTrue:=True;
      for I:=0 to CondUk do with (VictoryConditions^[I]) do
      if (Result < 1) then begin
        case (Condition) of
           1 : begin { alespon 1 jednotka dorazi na policko Num1, Num2 }
                 if (Num1 > IMax) then Result:=1;
                 if (Num2 > JMax) then Result:=1;
                 Tag:=False;
                 with (Map^[Num1,Num2]) do begin
                   if ((First_level <> 0) and (Level_type and 128 = 0)) then
                     if (Units[First_level]^.Race = MyRace) then Tag:=True;
                   if (Second_level <> 0) then
                     if (Units[Second_level]^.Race = MyRace) then Tag:=True;
                 end;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) >
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                      FailedCondition:=I; AllTrue:=False;
                      EndOfGame:=True;
                      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                      Victory:=-1;
                    end;
                 end;
                 if (not Tag) then AllTrue:=False else Result:=1;
                 if (AllTrue = False) then begin
                 { sice jsem vybil nepratele, ale cile mise nesplnil-
                   cekam }
                   if (RobotsZero) then begin
                      if (EndOfGameTimmer > 0) then EndOfGameTimmer:=0;
                      Victory:=0;
                   end;
                 end;
               end;
           2 : begin { znicit vsechny jednotky spec. cisla x }
                 if (SpecNumList^[Num1].Count > 0) then AllTrue:=False
                 else Result:=1;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) >
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                      FailedCondition:=I; AllTrue:=False;
                      EndOfGame:=True;
                      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                      Victory:=-1;
                    end;
                 end;
               end;
           3 : with (Races[Num2]) do begin { znicit vsechny budovy typu x rasy y }
                 if (Num1 = 255) then
                   { musi byt zniceny vsechny budovy rasy y }
                   if (RacesInfo2[Num2] > 0) then AllTrue:=False
                   else Result:=1
                 else
                   if (ExistBuildings[Num1] > 0) then AllTrue:=False
                   else Result:=1;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) >
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                      FailedCondition:=I; AllTrue:=False;
                      EndOfGame:=True;
                      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                      Victory:=-1;
                    end;
                 end;
               end;
           4 : begin { jednotka se sepc. cislem dorazi na policko Num1,Num2 }
                 if (Num1 > IMax) then Result:=1;
                 if (Num2 > JMax) then Result:=1;
                 Tag:=False;
                 with (Map^[Num1,Num2]) do begin
                   if ((First_level <> 0) and (Level_type and 128 = 0)) then
                     if ((Units[First_level]^.Race = MyRace) and
                         (Units[First_level]^.SpecNumber <> 0))
                     then Tag:=True;
                   if (Second_level <> 0) then
                     if ((Units[Second_level]^.Race = MyRace) and
                         (Units[Second_level]^.SpecNumber <> 0))
                     then Tag:=True;
                 end;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) >
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                      FailedCondition:=I; AllTrue:=False;
                      EndOfGame:=True;
                      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                      Victory:=-1;
                    end;
                 end;
                 if (not Tag) then AllTrue:=False else Result:=1;
                 if (AllTrue = False) then begin
                 { sice jsem vybil nepratele, ale cile mise nesplnil-
                   cekam }
                   if (RobotsZero) then begin
                      if (EndOfGameTimmer > 0) then EndOfGameTimmer:=0;
                      Victory:=0;
                   end;
                 end;
               end;
           5 : begin { nesmi by znicena zadna jednotka spec. cisla x }
                 Tag:=False;
                 if (SpecNumList^[Num1].Destr) then begin
                    Tag:=True;
                 end;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) <
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                       if (Tag) then begin
                       { a jednotka znicena }
                         FailedCondition:=I; AllTrue:=False;
                         EndOfGame:=True;
                         if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                         Victory:=-1;
                       end else begin
                          AllTrue:=False; { cekame na casovy limit }
                          Result:=0;
                       end;
                    end else Result:=1;
                 end else begin
                 { bez kontroly casu }
                    if (Tag) then begin
                    { jednotka znicena }
                       FailedCondition:=I; AllTrue:=False;
                       EndOfGame:=True;
                       if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                       Victory:=-1;
                    end else Result:=0; { cekame na casovy limit }
                 end;
               end;
           6 : begin { musi prezit alespon jedna jednotka spec. cisla x }
                 Tag:=False;
                 if (SpecNumList^[Num1].Count = 0) then begin
                    Tag:=True;
                 end;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) <
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                       if (Tag) then begin
                       { a jednotka znicena }
                         FailedCondition:=I; AllTrue:=False;
                         EndOfGame:=True;
                         if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                         Victory:=-1;
                       end else begin
                          AllTrue:=False; { cekame na casovy limit }
                          Result:=0;
                       end;
                    end else Result:=1;
                 end else begin
                 { bez kontroly casu }
                    if (Tag) then begin
                    { jednotka znicena }
                       FailedCondition:=I; AllTrue:=False;
                       EndOfGame:=True;
                       if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                       Victory:=-1;
                    end else Result:=0; { cekame na casovy limit }
                 end;
               end;
           7 : with (Races[Num2]) do begin { nesmi byt znicena zadna budova
                                             typu x rasy y }
                 Tag:=False;
                 if ((ProducedBuildings[Num1]-ExistBuildings[Num1]) <> 0)
                 then Tag:=True;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) <
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                       if (Tag) then begin
                       { a nejaka budova znicena }
                         FailedCondition:=I; AllTrue:=False;
                         EndOfGame:=True;
                         if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                         Victory:=-1;
                       end else begin
                          AllTrue:=False; { cekame na casovy limit }
                          Result:=0;
                       end;
                    end else Result:=1;
                 end else begin
                 { bez kontroly casu }
                    if (Tag) then begin
                    { jednotka znicena }
                       FailedCondition:=I; AllTrue:=False;
                       EndOfGame:=True;
                       if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                       Victory:=-1;
                    end else Result:=0; { cekame na casovy limit }
                 end;
               end;
           8 : with (Races[Num2]) do begin { musi prezit alespon jedna budova
                                             typu x rasy y }
                 Tag:=False;
                 if (ExistBuildings[Num1] = 0) then Tag:=True;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) <
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                       if (Tag) then begin
                       { a budovy zniceny }
                         FailedCondition:=I; AllTrue:=False;
                         EndOfGame:=True;
                         if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                         Victory:=-1;
                       end else begin
                          AllTrue:=False; { cekame na casovy limit }
                          Result:=0;
                       end;
                    end else Result:=1;
                 end else begin
                 { bez kontroly casu }
                    if (Tag) then begin
                    { jednotka znicena }
                       FailedCondition:=I; AllTrue:=False;
                       EndOfGame:=True;
                       if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                       Victory:=-1;
                    end else Result:=0; { cekame na casovy limit }
                 end;
               end;
           9 : with (Races[MyRace]) do begin { postavit budovu typu x o poctu y }
                 if (ProducedBuildings[Num1] < Num2) then AllTrue:=False
                 else Result:=1;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) >
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                      FailedCondition:=I; AllTrue:=False;
                      EndOfGame:=True;
                      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                      Victory:=-1;
                    end;
                 end;
                 if (AllTrue = False) then begin
                 { sice jsem vybil nepratele, ale cile mise nesplnil-
                   cekam }
                   if (RobotsZero) then begin
                      if (EndOfGameTimmer > 0) then EndOfGameTimmer:=0;
                      Victory:=0;
                   end;
                 end;
               end;
           10: begin { musi byt znicena rasa x }
                 if (RacesInfo[Num1] > 0) then AllTrue:=False
                 else Result:=1;
                 if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
                 { kontrola casu }
                    if ((Min_game_time*60 + Sec_game_time) >
                        (Word(TimeMin)*60 + TimeSec)) then begin
                    { nedodrzen casovy limit }
                      FailedCondition:=I; AllTrue:=False;
                      EndOfGame:=True;
                      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
                      Victory:=-1;
                    end;
                 end;
               end;
        else
           Error(0,'unita _units3, VictoryConditionManager');
        end;
      end;
   end;

   if ((AllTrue) and (not EndOfGame)) then begin
   { ok, vsechny podminky jsou spleneny }
      EndOfGame:=True;
      if (EndOfGameTimmer = 0) then EndOfGameTimmer:=1;
      Victory:=1;
   end;
   if (EndOfGameTimmer > 0) then begin
      if (Retreat) then begin
         Retreat:=False;
         EndOfGameTimmer:=255;
      end;
   end;
end;

{ ***** }
function GetRaceName(Race:Byte):String;
{ vraci nazev dane rasy, jakoz i v zavorce barvu.
  pr. OSN (bili)
}
var Ret:String;
begin
   Ret:=Races[Race].RaceName;
   case (Races[Race].RaceColor) of
     176 : Ret:=Ret+' (BeLj)';
     181 : Ret:=Ret+' (kLUTj)';
     154 : Ret:=Ret+' (MODRj)';
     144 : Ret:=Ret+' (bERVENj)';
     149 : Ret:=Ret+' (ZELENj)';
     186 : Ret:=Ret+' (ORANkOVj)';
   else
   end;
   GetRaceName:=Ret;
end;

{ ***** }
function GetBuildingName(BuildingType:Byte):String;
{ procedura vrati nazev budov
}
begin
   GetBuildingName:=Building_types[BuildingType].Name;
end;

{ ***** }
procedure Send_recyklator_home(_unit:PUnit);
{ posle recyklator _unit k nejblizsi budove recyklace
}
var FreePlac:TFreePlaces;
    IP,JP,IAdd,JAdd,IPosic,JPosic,Delta,K,PomDelta, PomDelta2:Word;
    MaxIndex:Word;
    I, J:Word;
begin
   { posli recyklator k budove recyklace }
   with (_unit^) do with (Races[Race]) do begin
     if (RecyklatorBuildInfoCount = 0)
     then {OutBigMsg('RECYKLaTOR - NEEXISTUJE BUDOVA RECYKLACE'){}
     else begin
        { nejaka budova recyklace existuje }
        IPosic:=65535; JPosic:=65535; Delta:=65535;
        { hledame nejblizsi budovu recyklace }
        for K:=0 to LastRecyklatorBuildInfoIndex do
        with (RecyklatorBuildInfo[K]) do begin
          if ((IP <> 65535) and (JP <> 65535)) then begin
             Get_free_places(FreePlac,MaxIndex,IP,JP,Building_types[4].IBuildingSize,
                             Building_types[4].JBuildingSize);
             I:=1;
             while (I <= MaxIndex) do with (FreePlac[I]) do begin
               if (Free) then begin
                 if (Free_place_two(IP,JP,1,1,2)) then begin
                   PomDelta:=GetDistance(IPos,JPos,IP,JP);
                   if (PomDelta < Delta) then begin
                     IPosic:=IP; JPosic:=JP; Delta:=PomDelta;
                   end;
                 end;
               end;
               Inc(I);
             end;
          end;
        end;
        if (Above(MapBck^[IPos,JPos].BckType,Field) and
            BelowEqual(MapBck^[IPos,JPos].BckType,Resrc)) then begin
        { ulozeni informace o nalezisti, pouze pokud tu nejake naleziste je }
            ITarget:=IPos; JTarget:=JPos;
        end;
        ADefModeSteps:=0;
        if ((Delta = 65535) or (IPosic = 65535) or (JPosic = 65535)) then
           Error(0,'unita _units2, procedura Send_recyklator_home')
        else begin
          WayPointMax:=0; WayPointUk:=0;
          Set_move_unit(IPosic,JPosic,_unit,0,False,False);
        end;
     end;
   end;
end;

{ ***** }
procedure Raise_group_morale(Group:Byte);
{ jednotkam ve skupine Group zvedne moralku
  pozn. automaticky se predpoklada, ze ve skupine NENI budova
}
var I: Word;
    Pom,DMG,DMGStrength:Double;
    Rac:Byte;
begin
   with (Groups[Group]) do begin
     for I:=0 to MaxGroupUnits-1 do
      if ((Un[I] <> Nil) and (Un[I]^.UnitType <> 2) and
          (Un[I]^.UnitType <> 33)) then with (Un[I]^) do begin
        Rac:=Race;
        Pom:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength;
        Pom:=(Pom/100)*RaiseMoraleDamage;
        DMG:=Pom;
        if ((Damage > DMG) and ((Morale+RaiseMoraleBonus) <= MaxMorale)) then begin
        { zvednuti moralky se nedopusti, pokud by znicilo jednotku;
          v pripade, ze jednotka prejde do "red damage", moralku ji to
          nesnizi! }
           Dec(Damage,Round(DMG));
           DMGStrength:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
           DMGStrength:=DMGStrength/100; DMG:=Damage; DMG:=DMG/DMGStrength;
           if (DMG <= 35) then { kriticke poskozeni - nastav kour }
             if ((FirePhase = 0) and FireAllowed) then FirePhase:=1;
           Inc(Morale,RaiseMoraleBonus);
           Change_unit_experience_morale(Un[I]);
           Un[I]^.RequestDraw:=True;
           if ((Group = ActiveGroup) and
               ((Races[MyRace].Friend[Race] = 2) or EnemyStatus))
           then begin UpdateDmg:=True; end;
        end; { if (Damage > DMG) }
     end; { for }
   end; { with Groups[...] }
end;

{ ***** }
function Range_check(XThis, YThis, XTarget, YTarget : Word; Range : Byte) : Boolean;
{ funkce vraci True, pokud XTarget, YTarget lezi v kruznici o stredu
  XThis, YThis a polomeru Range.
  Princip:
  plati: abs(XTHis - XTarget) + abs(YTHis - YTarget) = Range+1;
  vyjimka : if (XThis = XTarget) or (YThis = YTarget) then
               expression = Range;
}
var I,J:Word;
begin
   I:= abs(Integer(XTHis) - XTarget); J:=abs(Integer(YTHis) - YTarget);
   if ((I > Range) or (J > Range)) then Range_check:=False
   else begin
      Inc(I,16); Inc(J,16);
      if (Range > MaxRangeCheckArray) then begin
         Range:=Range; { error trap }
         Error(0,'unita _units2, procedura Range_check, chybny range');{}
      end;
      if (Range_check_array^[Range].Rng[I,J]) then Range_check:=True
      else Range_check:=False;
   end;
end;

{ ***** }
procedure Set_move_active_group(I,J:Word; MoveTargetLevel:Byte; GoInsid:Boolean;
                                ClickStatus, Rac:Byte);
{ nastavi presun jednotek v aktivni skupine  na pozici I,J na urovni
  MoveTargetLevel:
  0 .. pozemni
  1 .. vzdusna
  GoInsid = True, pokud se ma jednotka nakladat
  ClickStatus nabyva hodnot:
  0 : nic se nedeje
  1 : skupina je "namacknuta"
  2 : stisknuto tlacitka "nalozit" (GoInsid se pepise na TRUE )
  3 : stisknuto tlacitko "patrola"
  254 : namacknuta pratelska jednotka
  255 : namacknuta nepratelska jednotka
}
var K : Word;
begin
 if (Rac = MyRace) then with (Groups[ActiveGroup]) do begin
  if (I > IMax) then I:=IMax; if (J > JMax) then J:=JMax;
  for K:=0 to MaxGroupUnits-1 do if (Un[K] <> NIL) then with (Un[K]^) do begin
     if (Check_place_surroundings_free(IPos,JPos,
         Unit_types[UnitType,Races[Race].Ally].IUnitSize,
         Unit_types[UnitType,Races[Race].Ally].IUnitSize, UnitType) = 0)
     then GroupMoveBlock:=4;
     if ((GroupMoveBlock <> 0) and
         (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
         (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0))
     then GroupMoveBlock:=0;
     Rac:=Race;
     WayPoint[WayPointUk].IAim:=I;
     WayPoint[WayPointUk].JAim:=J;
     BanDir:=0; First_mov:=True; SlashCount:=0; SlashDir:=0;
     GroupMove:=True;
     Stop_:=False;
     GoInside:=GoInsid;
     if (ClickStatus = 2) then GoInside:=True; { nakladani }
     if ((Status < 1) or (Status > 128)) then begin
        Status:=Direction;
        MoveUk:=0;
     end;
     if (ClickStatus = 3) then begin { patrola }
        MoveStatus:=1;
     end else MoveStatus:=0;
     BanDir:=0; First_mov:=True;
     SlashCount:=0; SlashDir:=0;
     CheckGroupMoveDistance:=False;
     GroupMoveSteps:=0;
     Move_target_level:=MoveTargetLevel;
     if (Rac = MyRace) then Click_on_group(ActiveGroup);
  end;
 end;
end;

{ ***** }
procedure Set_move_unit(I,J:Word; var _unit:PUnit; MoveTargetLevel:Byte; BlockMov,Load:Boolean);
{ nastavi presun jednotky _unit na pozici I,J na urovni MoveTargetLevel:
  0 .. pozemni
  1 .. vzdusna
 BlockMov = True, ma-li se pouzit "blokovy presun"; t.j. cilem vlastne neni
 zadne konkretni misto, ale blok o velikosti (IInfoArraySize x JInfoArraySize);
 potom I,J je souradnice bloku!
 je-li Load = True, jednotka se bude nakladat
}
var Pom:Byte;
begin
  if (_unit^.Activity) then with (_unit^) do begin
   if ((XOffset = 0) and (YOffset = 0) and
       ((Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 3) or
        (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0) or
        (GroupMoveBlock = 0)){}) then begin
     if (BlockMov) then begin
        BlockMove:=True; IBlock:=I; JBlock:=J;
        WayPoint[WayPointUk].IAim:=I*(IInfoDiv)+IInfoDiv shr 1;
        if (WayPoint[WayPointUk].IAim > IMax) then
          WayPoint[WayPointUk].IAim:=IMax;
        WayPoint[WayPointUk].JAim:=J*(JInfoDiv)+JInfoDiv shr 1;
        if (WayPoint[WayPointUk].JAim > JMax) then
          WayPoint[WayPointUk].JAim:=JMax;
     end else begin
        BlockMove:=False;
        if (I > IMax) then I:=IMax; if (J > JMax) then J:=JMax;
        WayPoint[WayPointUk].IAim:=I;
        WayPoint[WayPointUk].JAim:=J;
     end;
     if ((GroupMoveBlock <> 0) and
         (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
         (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0))
     then GroupMoveBlock:=0;

     {if (Awaiting_for_further_orders) then begin
     { pokud jednotka v taskgrupe nesplnila rozkaz = bloudi; neni dobre
       nicit jeji First_mov a pod. - muze potom cyklit }
       First_mov:=True; SlashCount:=0; SlashDir:=0;
     {end;{}
     BanDir:=0;
     if ((Status < 1) or (Status > 128)) then begin
          Status:=Direction;
          MoveUk:=0;
     end;
     GroupMove:=True;
     Stop_:=False;
     GoInside:=Load;
     MoveStatus:=0;
     CheckGroupMoveDistance:=False;
     GroupMoveSteps:=0;
     Move_target_level:=MoveTargetLevel;
     if (Return_to_base) then Pom:=1 else Pom:=0;

     if ((Race = MyRace) and (Group = ActiveGroup))
     then Click_on_unit(_unit);

   end;
  end;
end;

{ ***** }
procedure Stop_unit(var _unit:PUnit; ManageAirUnits,ManageSpecAirUnits:Boolean);
{ pri skonceni pohybu nainicializuje "pohybove" promenne jednotky
  MangeAirUnits = True ... jde-li o letecke jednotky, provede se
                           poslani na letiste nebo (helikoptery)
                           pristani
                  False ... letecke jednotky se nijak zvlast nespravuji
}
var PomType, GroundType:Byte;
begin
   if (_unit^.Activity) then with (_unit^) do begin
      Status:=0; if (TargetType <= 1) then Phase:=0;
      GroupMoveSteps:=0; GroupMoveBlock:=0; BlockMove:=False;
      CheckGroupMoveDistance:=False;
      GroupMove:=True;
      First_mov:=True; SlashCount:=0; SlashDir:=0;
      Stop_:=False;
      GoInside:=False;
      if (Repair) then  begin
         Inc(Races[Race].RepairsAvailable,UnitRepairCapacityNeed);
         if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
         DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
         {BPRepairRemainder:=0; PLRepairRemainder:=0;
         EERepairRemainder:=0; EXRepairRemainder:=0;{}
         RepairRemainder:=0;
         Repair:=False;
      end;

      WayPointUk:=255; WayPointMax:=255;
      if ((Race = MyRace) and (Group = ActiveGroup))
      then Click_on_unit(_unit);

      if ((ManageSpecAirUnits) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
          (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) and
          (not Return_to_base) and ((IPos <> IAirport) or (JPos <> JAirport)))
      then begin
      { letadlo priletelo na misto urceni - posli je zpet na letiste }
         Status:=0; Return_to_base:=True;
         WayPointUk:=0; WayPointMax:=0;
         WayPoint[WayPointUk].IAim:=IAirport;
         WayPoint[WayPointUk].JAim:=JAirport;
         {if (AirportPos = 0) then else
           if (AirportPos = 2) then Dec(WayPoint[WayPointUk].JAim)
           else
             if (AirportPos = 3) then begin
               Dec(WayPoint[WayPointUk].IAim);
               Dec(WayPoint[WayPointUk].JAim);
             end;{}
         Set_move_unit(WayPoint[WayPointUk].IAim,
                       WayPoint[WayPointUk].JAim,_unit,1,False,False);
         if (UnitsInsideNum <> 0) then UnLoad(_unit);
         { vyloz pripadny naklad }
      end;
      if (ManageAirUnits) then begin
         if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
             (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0) and
             (Move_target_level = 0) and
             (Free_place_two(IPos,JPos,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                             Unit_types[UnitType,Races[Race].Ally].JUnitSize,5)))
         then begin { helikoptera pristava }
             Set_place(IPos, JPos, _unit, False, True);
             _unit^.TargetType:=2; { z leteckeho se stava tezky cil }
             Set_place(IPos, JPos, _unit, True, True);
             PomType:=_unit^.UnitType;
             SetFog(IPos,JPos,Sight,Race,False);
             Sight:=Unit_types[UnitType,Races[Race].Ally]._Sight-1;
             SetFog(IPos,JPos,Sight,Race,True);
             _unit^.Phase:=1;
             _unit^.RequestDraw:=True;
             GroupMoveBlock:=10;
         end;
      end;
   end;
end;

{ ***** }
function Best_direction(IPos, JPos, IAim, JAim : Integer):Byte;
{ pro jednotku na pozici IPos, JPos zjisti optimalni natoceni
  na cilove pole IAim, JAim
}
var Pom : Byte;
    XDistance, YDistance : Integer;
    Slash : Boolean;
begin
{ inicializace pole s vahami }
   XDistance:=abs(IPos - IAim);
   YDistance:=abs(JPos - JAim);
   Slash:=(abs(XDistance - YDistance) < ((XDistance + YDistance) shr 1));
   { urcuje, zda je mozne pouzit sikmy smer }
   if (IAim < IPos) then
     if (JAim > JPos) then { vlevo dole }
       if (Slash) then Pom:=64 else { sikmo }
          if (XDistance > YDistance) then { vlevo }
             Pom:=128
          else Pom:=32 { dole }
     else { vlevo nahore }
       if (Slash) then Pom:=1 else { sikmo }
         if (XDistance > YDistance) then { vlevo }
            Pom:=128
         else Pom:=2 { nahore }
   else
     if (JAim > JPos) then { vpravo dole }
       if (Slash) then Pom:=16 else { sikmo }
          if (XDistance > YDistance) then { vpravo }
             Pom:=8
          else Pom:=32 { dole }
     else { vpravo nahore }
       if (Slash) then Pom:=4 else { sikmo }
          if (XDistance > YDistance) then { vpravo }
             Pom:=8
          else Pom:=2; { nahore }
Best_direction:=Pom;
end;

{ ***** }
function Best_direction2(IPos, JPos, IAim, JAim : Integer):Byte;
{ pro strelbu jednotky z pozice IPos, JPos zjisti optimalni natoceni
  na cilove pole IAim, JAim
}
var Pom : Byte;
    XDistance, YDistance, XYPom : Integer;
    Slash : Boolean;
begin
{ inicializace pole s vahami }
   XDistance:=abs(IPos - IAim);
   YDistance:=abs(JPos - JAim);
   if (XDistance > YDistance) then XYPom:=XDistance else XYPom:=YDistance;
   XYPom:=XYPom shr 1;
   Slash:=((XDistance > XYPom) and (YDistance > XYPom));
   { urcuje, zda je mozne pouzit sikmy smer }
   if (IAim < IPos) then
     if (JAim > JPos) then { vlevo dole }
       if (Slash) then Pom:=64 else { sikmo }
          if (XDistance > YDistance) then { vlevo }
             Pom:=128
          else Pom:=32 { dole }
     else { vlevo nahore }
       if (Slash) then Pom:=1 else { sikmo }
         if (XDistance > YDistance) then { vlevo }
            Pom:=128
         else Pom:=2 { nahore }
   else
     if (JAim > JPos) then { vpravo dole }
       if (Slash) then Pom:=16 else { sikmo }
          if (XDistance > YDistance) then { vpravo }
             Pom:=8
          else Pom:=32 { dole }
     else { vpravo nahore }
       if (Slash) then Pom:=4 else { sikmo }
          if (XDistance > YDistance) then { vpravo }
             Pom:=8
          else Pom:=2; { nahore }
Best_direction2:=Pom;
end;

{ ***** }
procedure GetBestCarrierLoadPos(var IPs,JPs:Word; IPos,JPos,IHomePos,JHomePos:Word; UnitType:Byte);
{ vrati nejlepsi misto, na ktere je mozne se smerovat, aby se
  jednotka bezproblemove nalozila do carrieru o pozici IPos, JPos;
  domovska pozice je na IHomePos, JHomePos
}
label Konec;
var FreePlaces:TFreePlaces;
    MaxIndex:Word;
    I, J, Val, PomVal,Dist,PomDist : Word;
begin
   IPs:=IPos; JPs:=JPos; Val:=0; Dist:=65535;
   if (GetDistance(IHomePos,JHomePos,IPos,JPos) = 1) then GoTo Konec;
   { jednotka se uz nachazi na vhodnem poli }

   Get_free_places(FreePlaces,MaxIndex,IPs,JPs,1,1);
   I:=1;
   while (I <= MaxIndex) do with (FreePlaces[I]) do begin
     if (Free) then begin
        if (Free_place_two(IP,JP,1,1,UnitType)) then begin
           PomVal:=Check_place_surroundings_free(IP,JP,1,1,UnitType);
           PomDist:=GetDistance(IHomePos,JHomePos,IP,JP);
           if ((PomVal > 0) and (PomDist < Dist) or
               (PomDist = Dist) and (PomVal > Val))
           then begin
             IPs:=IP; JPs:=JP; Val:=PomVal; Dist:=PomDist;
           end;
        end;
     end;
     Inc(I);
   end;
Konec:
end;

{ ***** }
function UnBlock_place(I1,J1,I2,J2:Word; Rac:Byte; var _unit:PUnit):Byte;
{ procedura, volana rasou Race se pokusi uvolni oblast I1-I2,J1-J2 (vcetne)
  od vsech pozemnich jednotek. Dela to tak, ze vsechny pratelske jednotky
  se snazi odsunout. Vraci:
  0 .. misto je neuvolnitelne
  1 .. probiha uvolnovani
  2 .. misto je volne
  Je-li _unit <> Nil, pak jednotku _unit odsouvat NEBUDE!

  Algoritmus:
  - je-li treba jednotku odsunout, prohledava se "ramecek" kolem oblasti
  I1,I2,J1,J2. Jde-li o misto pro jednotku dostupne, presune se tam

!! POZOR !! oblast I1-1 az I2+1, J1-1 az J2+1 MUSI byt na mape (nekontroluje se)
}
label Kanec;
var I,J,K,L,X,Y, Count, Count2: Word;
    Result : Byte;
    Free, Konec:Boolean;
    { promenna Count pocita pocet pridelenych fleku odsunovanym jednotkam a
      Count2 pocita pro kazdou jednotku pocet vhodnych mist. Protoze se
      vzdy prideli 1. misto, pak pro prvni jednotku Count2 = 1, pro
      druhou Count2 = 1 (stejne misto), coz my nechcem. Proto pro
      prvni jednotku a Count2 = 1 nastavime Count:=1; druhe jednotce se pak
      prideli misto az Count2 = 2, nebot musi platit (Count <> Count2).
      pozn. kolize nastanou pro dve jednotky s odliznym terennim pristupem
    }
begin
   Result:=0; Free:=True; Count2:=0; Count:=0;
   if ((I1 = 0) or (J1 = 0) or (I2 = IMax) or (J2 = JMax)) then GoTo Kanec;
   with (Races[Rac]) do begin
     for I:=I1 to I2 do
       for J:=J1 to J2 do with (Map^[I,J]) do begin
          if (First_level <> 0) then begin { je zde prekazka }
             Free:=False;
             if (Level_type and 128 = 128) then Result:=0 { budova }
             else
             if (Units[First_level] <> _unit) then
             with (Units[First_level]^) do begin { jednotka }
               if (Friend[Race] <> 2) then Result:=0 { neni pratelska }
               else begin { pratelska jednotka, zkus ji odsunout }
                  if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) then
                     Result:=0 { nepohybliva jednotka (vez) }
                  else
                    if ((Activity) and (Status = 0)) then begin
                    { jednotka je aktivni a stoji - ODSUNUJ }
                       Konec:=False; Count2:=1;
                       K:=I1-1; L:=J1-1; { nejpve horni oblast }
                       while ((K <= (I2+1)) and (not Konec)) do begin
                         if (Free_place3(K,L,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                         Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                         Units[First_level])) then begin
                            if (Count <> Count2) then begin
                              Konec:=True;
                              X:=K; Y:=L;
                            end;
                            Inc(Count2);
                         end;
                         Inc(K);
                       end;
                       K:=I1-1; L:=J2+1; { nejpve dolni oblast }
                       while ((K <= (I2+1)) and (not Konec)) do begin
                         if (Free_place3(K,L,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                         Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                         Units[First_level])) then begin
                            if (Count <> Count2) then begin
                              Konec:=True;
                              X:=K; Y:=L;
                            end;
                            Inc(Count2);
                         end;
                         Inc(K);
                       end;
                       K:=I1-1; L:=J1; { leva krajni oblast }
                       while ((L <= (J2)) and (not Konec)) do begin
                         if (Free_place3(K,L,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                         Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                         Units[First_level])) then begin
                            if (Count <> Count2) then begin
                              Konec:=True;
                              X:=K; Y:=L;
                            end;
                            Inc(Count2);
                         end;
                         Inc(L);
                       end;
                       K:=I2+1; L:=J1; { prava krajni oblast }
                       while ((L <= (J2)) and (not Konec)) do begin
                         if (Free_place3(K,L,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                         Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                         Units[First_level])) then begin
                            if (Count <> Count2) then begin
                              Konec:=True;
                              X:=K; Y:=L;
                            end;
                            Inc(Count2);
                         end;
                         Inc(L);
                       end;

                       if (Konec) then begin { vlastni odsun }
                          WayPointMax:=0; WayPointUk:=0;
                          Set_move_unit(X,Y,Units[First_level],0,False,False);
                          Result:=1; Inc(Count);
                       end else Result:=0;
                    end else Result:=1; { jednotka vybuchuje nebo
                    se presouva nebo utoci }
               end;
             end; { with (Units[First_level]^) do begin (jednotka)  }
          end;
       end;

   end; { with (Races[Race]) do begin }
   if (Free) then Result:=2;
Kanec:
   UnBlock_place:=Result;
end;

{ ***** }
procedure Get_free_places(var FreePlaces:TFreePlaces; var MaxIndex:Word; IPos,JPos:Word; ISize,JSize:Word);
{  od pozice IPos, JPos jednotky o velikosti ISize, JSize policek zjisti
   volna mista v tesnem okoli jednotky a ulozi je do pole FreePlaces;
   max. pouzity index je v MaxIndex;
   POZOR! zjistuje pouze volnost vzhledem ke krajum mapy, ne tu fyzickou,
   t.j. je-li na policku nejaka jednotka
}
var I,J:Integer;
begin
   MaxIndex:=0;
   for J:=Integer(JPos)-1 to JPos+JSize do
     for I:=Integer(IPos)-1 to IPos+ISize do begin
        if ((I >= 0) and (J >= 0) and (I <= IMax) and (J <= JMax) and
            ((I < IPos) or (J < JPos) or
             (I >= (IPos+ISize)) or (J >= (JPos+JSize))))
        then begin
           Inc(MaxIndex); FreePlaces[MaxIndex].Free:=True;
           FreePlaces[MaxIndex].IP:=I; FreePlaces[MaxIndex].JP:=J;
        end;
     end;

   for I:=MaxIndex+1 to Places do FreePlaces[I].Free:=False;
end;

{ ***** }
procedure RepairGroup(Group:Byte);
{ provede se oprava poskozenych jednotek ve skupine Group
}
var I:Word;
    Rac:Byte;
begin
   with (Groups[Group]) do begin
     if (Building <> Nil) then with (Building^) do with (Races[Race]) do begin
     { opravovat se bude budova }
       if ((Damage < Building_types[BuildingType].DefenceStrength) and
           (not Repair)) then begin { budova opravu skutecne potrebuje }
         if (RepairsAvailable >= BuildingRepairCapacityNeed) then begin
            Repair:=True;
            Dec(RepairsAvailable,BuildingRepairCapacityNeed);
            DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
            {BPRepairRemainder:=0; PLRepairRemainder:=0;
            EERepairRemainder:=0; EXRepairRemainder:=0;{}
            RepairRemainder:=0;
            Rac:=Race;
            { zrus produkci }
          if (Production_type <> 0) then begin
          { budova vyrabi }
            if (Building_types[BuildingType].ProductionType < 2) then begin
            { budovy, jednotky }
               if (Building_types[BuildingType].ProductionType = 0) then
               with (Unit_types[Building_types[BuildingType].Production[Production_type-1],Races[Race].Ally]) do begin
               { PRODUKCE ZASTAVENA ! }
               { odalokovani materialu }
                 Inc(Races[Rac].Building_credits,BP);
                 Inc(Races[Rac].Plastic_credits,PL);
                 Inc(Races[Rac].Electric_energy,EE);
                 Inc(Races[Rac].Battle_experience,EX);
                 if (BP <> 0) then Print_material(1,Races[Rac].Building_credits);
                 if (PL <> 0) then Print_material(2,Races[Rac].Plastic_credits);
                 if (EE <> 0) then Print_material(3,Races[Rac].Electric_energy);
                 if (EX <> 0) then Print_material(4,Races[Rac].Battle_experience);
                 Production_phase:=0; Production_percentage:=0; Production_type:=0;
                 Production_count:=0;
               end else
               with (Building_types[Building_types[BuildingType].Production[Production_type-1]])
               do begin { budovy odalokovani materialu }
                  Inc(Races[Rac].Building_credits,BP);
                  Inc(Races[Rac].Plastic_credits,PL);
                  Inc(Races[Rac].Electric_energy,EE);
                  Inc(Races[Rac].Battle_experience,EX);
                  if (BP <> 0) then Print_material(1,Races[Rac].Building_credits);
                  if (PL <> 0) then Print_material(2,Races[Rac].Plastic_credits);
                  if (EE <> 0) then Print_material(3,Races[Rac].Electric_energy);
                  if (EX <> 0) then Print_material(4,Races[Rac].Battle_experience);
                  Production_phase:=0; Production_percentage:=0; Production_type:=0;
                  Production_count:=0;
               end;
            end else if (Building_types[BuildingType].ProductionType = 2) then begin
           { PRODUKCE PLASTU }
                Production_phase:=0; Production_percentage:=0; Production_type:=0;
                Production_count:=0;
            end; { produkce plastu }
          end; { BUDOVA PRODUKUJE }
          if ((Building^.Race = MyRace) and
              (Building_types[Building^.BuildingType].ProductionType < 3) and
              (BuildPhase > 3) and (Group = ActiveGroup)) then begin
           { zrus produkcni sloty }
                Clear_group_slots;
                Click_on_group(ActiveGroup);
          end;
         end else if (Race = MyRace) then OutBigMsg(8,'NEDOSTATEK OPRAVaRENSKc KAPACITY');
       end;
     end else begin
     { opravovat se bude jednotka }
        for I:=0 to MaxGroupUnits-1 do
          if (Un[I] <> Nil) then with (Un[I]^) do  with (Races[Race]) do begin
            if ((Damage < (Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus)) and
                (not Repair)) then begin { jednotka opravu skutecne potrebuje }
               if (RepairsAvailable >= UnitRepairCapacityNeed) then begin
                 Repair:=True;
                 Dec(RepairsAvailable,UnitRepairCapacityNeed);
                 DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                 {BPRepairRemainder:=0; PLRepairRemainder:=0;
                 EERepairRemainder:=0; EXRepairRemainder:=0;{}
                 RepairRemainder:=0; Rac:=Race;
               end else if (Race = MyRace) then OutBigMsg(8,'NEDOSTATEK OPRAVaRENSKc KAPACITY');
            end;
          end;
     end;

  end; { with }
end;

{ ***** }
procedure RepairEnemy(Rac:Byte; Building:PBuilding; Un:PUnit);
{ provede se oprava poskozenych jednotek nebo budov rasy Race -
  - pro pouziti pocitace
}
begin
   bebex:=500;
   with (Races[Rac]) do begin
     if (Building <> Nil) then with (Building^) do begin
     { opravovat se bude budova }
       bebex:=501;
       if ((Damage < Building_types[BuildingType].DefenceStrength) and
           (not Repair)) then begin { budova opravu skutecne potrebuje }
          bebex:=502;
          if (RepairsAvailable >= BuildingRepairCapacityNeed) then begin
            bebex:=503;
            Repair:=True;
            Dec(RepairsAvailable,BuildingRepairCapacityNeed);
            DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
            BPRepairRemainder:=0; PLRepairRemainder:=0;
            EERepairRemainder:=0; EXRepairRemainder:=0;
            RepairRemainder:=0; CompRepairFlag:=0;
            BPRepair:=BPRepair + RepairCost*((1.0*Building_types[BuildingType].BP)/100);
            PLRepair:=PLRepair + RepairCost*((1.0*Building_types[BuildingType].PL)/100);
            EERepair:=EERepair + RepairCost*((1.0*Building_types[BuildingType].EE)/100);
            ExpRepair:=ExpRepair + RepairCost*((1.0*Building_types[BuildingType].Ex)/100);
            if (RepairFactoryShortage > 20*BuildingRepairCapacityNeed) then
               Dec(RepairFactoryShortage,20*BuildingRepairCapacityNeed)
            else RepairFactoryShortage:=0;
         end else begin { kapacita nestaci }
           bebex:=504;
           if (BuildingProductionPossible(Race,13) and (RepairFactoryShortageForbid = 0) and
               (ExistBuildings[13] < 3))
           then Inc(RepairFactoryShortage);
           bebex:=505;
         end;
       end;
     end else if (Un <> Nil) then begin
      { opravovat se bude jednotka }
        bebex:=506;
        with (Un^) do begin
            bebex:=507;
            if ((Damage < (Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus)) and
                (not Repair)) then begin { jednotka opravu skutecne potrebuje }
               bebex:=508;
               if (RepairsAvailable >= UnitRepairCapacityNeed) then begin
                 bebex:=509;
                 Repair:=True;
                 Dec(RepairsAvailable,UnitRepairCapacityNeed);
                 DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                 BPRepairRemainder:=0; PLRepairRemainder:=0;
                 EERepairRemainder:=0; EXRepairRemainder:=0;
                 RepairRemainder:=0; CompRepairFlag:=0;
                 BPRepair:=BPRepair + RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].BP)/100);
                 PLRepair:=PLRepair + RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].PL)/100);
                 EERepair:=EERepair + RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].EE)/100);
                 ExpRepair:=ExpRepair + RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].Ex)/100);
                 if (RepairFactoryShortage > 20*UnitRepairCapacityNeed) then
                    Dec(RepairFactoryShortage,20*UnitRepairCapacityNeed)
                 else RepairFactoryShortage:=0;
                 bebex:=510;
               end else begin { kapacita nestaci }
                 bebex:=511;
                 if (BuildingProductionPossible(Race,13) and (RepairFactoryShortageForbid = 0) and
                     (ExistBuildings[13] < 3))
                 then Inc(RepairFactoryShortage);
                 bebex:=512;
               end;
            end
        end; { opravovat se bude jednotka }
     end;
  end; { with }
end;

{ ***** }
procedure Manager_part_2(_unit:PUnit);
var J:Word;
    IntelliSearchOK:boolean;
    TGPom:Byte;
    PomDangerClass:Word;
    Ix,Jx:Word;
begin
  with (_unit^) do begin
     J:=Index;

     bebex:=98;
     IntelliSearchOK:=False;
     if ((TaskGroup < 8) or (TaskGroup > 9)) then IntelliSearchOK:=True;
     if (TaskGroup <> InvalidTaskGroupNumber) then
     with (Races[Race].TaskGroups^[TaskGroup]) do begin
         bebex:=99;
         if (Validity and
             (GrpFree_attack or (MasterCommand = WithoutCom) or
              (MasterPhase >= 10)))
         then IntelliSearchOK:=True;
     end;

     bebex:=130;
     {* umela inteligence *}
     if (Activity and (GroupMoveBlock = 0) and (not Return_to_base) and
         (((Race = ThisCompRace1) or
           (Race = ThisCompRace2) or (Race = ThisCompRace3) or
           (Race = ThisCompRace4) or (Race = ThisCompRace5)) and
          IntelliSearching and (not WearOutRest) and IntelliSearchOK or
          (Race = MyRace) and MyIntelliSearching and
          ActiveDefence and (MoveStatus <> 8)))
          { vlastni jednotky vyhledavaji cile pouze v klidu }
     then begin { inteligentni vyhledavani cile }
        { vyhledavame pouze tehdy, pokud se utocne nepresouvame }
          bebex:=101;
          Inc(IntelliSearching_for_attack_flag);
          if (IntelliSearching_for_attack_flag >= IntelliSearching_for_attack_limit)
          then begin
            bebex:=102;
            { pro nahodnejsi rozlozeni "pricarujeme" nejaka nahodna cisla }
            IntelliSearching_for_attack_flag:=-J mod 3+TimeSlot mod 4;
            bebex:=103;
            Intelli_searching_for_attack(Units[J]);
          end;
     end;

     bebex:=104;
     { VYKRESLENI }
     if ((Activity) and (Units[J] <> Nil) and
         (UpdateDmg or UpdateMoralWearOut or UpdateLev)) then begin
        bebex:=105;
        if (Races[MyRace].Friend[Race] <> 2) then begin
           UpdateMoralWearOut:=False; UpdateLev:=False;
        end;
        bebex:=106;
        Update_unit_char(Units[J],UpdateDmg,UpdateMoralWearOut,UpdateLev);
     end;
     UpdateDmg:=False; UpdateMoralWearOut:=False; UpdateLev:=False;

     bebex:=107;
     { OVLADANI TASKGROUPS }
     if ((Activity) and ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
         (Race = ThisCompRace3) or (Race = ThisCompRace4) or
         (Race = ThisCompRace5)) and (TaskGroup <> InvalidTaskGroupNumber))
     then with (Races[Race]) do begin { jednotka patri pocitaci }
         bebex:=108;
         if ((TaskGroups^[TaskGroup].Validity) and
             ((UnitType <> 18) and (UnitType <> 19) or (TaskGroup = 12)) and
             (TaskGroups^[TaskGroup].CommandNum <> CommandNum) and
             (MoveStatus <= 1) and (XOffset = 0) and (YOffset = 0) and
             (not WearOutRest or (TaskGroups^[TaskGroup].Command = JoinCom)))
         then begin
         { je treba provest prikaz taskgrupy (jednotka neutoci) }
             bebex:=109;
             ExecuteTaskGroupCommand(Units[J]);
         end else begin
           bebex:=111;
           if ((TaskGroups^[TaskGroup].Validity) and
               ((UnitType <> 18) and (UnitType <> 19) or (TaskGroup = 12)) and
               (TaskGroups^[TaskGroup].CommandNum = CommandNum) and
               (Status = 0) and (MoveStatus <= 1) and
               (not WearOutRest or (TaskGroups^[TaskGroup].Command = JoinCom)))
           then begin
           { je treba zkontrolovat provedeni prikazu taskgrupy }
              bebex:=110;
              CheckExecuteTaskGroupCommand(Units[J]);{}
           end;
         end;

         bebex:=112;
         if ((Units[J] <> Nil) and (Units[J]^.TaskGroup <> InvalidTaskGroupNumber))
         then begin { Nil = napr. budova se rozlozila }
           { ** }
           bebex:=113;
           if (TaskGroups^[TaskGroup].Validity and (UnitType <> 18) and (UnitType <> 19) and
               (XOffset = 0) and (YOffset = 0) and (TaskGroup < 10) and
               (TaskGroups^[TaskGroup].Lock > 1) and
               (TaskGroups^[TaskGroup].NoAttackTimming >= 100) and{}
               (GetDistance(IInfoPos,JInfoPos,
                            TaskGroups^[TaskGroup].ITaskGroupInfoPos,
                            TaskGroups^[TaskGroup].JTaskGroupInfoPos) > 1) and
               ((UnitType < 17) or (UnitType > 19)))
           then with TaskGroups^[TaskGroup] do begin
           { pokud se TG "odtrhla" od sve skupiny, pomuze se ji skupinu
             dostihnout (ne pro cerstve vzniklou TG) }
           { ** nejprve odstranime jednotku od puvodni TG ** }
               bebex:=114;
               TGPom:=TaskGroup;
               Dec(Lock);
               if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
               then Dec(AirUnitsCount);
               if ((Unit_Types[UnitType,Races[Race].Ally].NeedPlace <= 5) or
                   (TaskGroup = 12) and (UnitType = 9))
               then Dec(TGCapacityNeed,Unit_Types[UnitType,Races[Race].Ally].NeedPlace);
               bebex:=115;
               if (Unit_types[UnitType,Races[Race].Ally].Capacity <> 0) then
                  Delete_task_group_carrier(Race,TaskGroup,Units[J]);
               if (Lock = 0) then InvalidateTaskGroup(Race,TaskGroup);
               {x}
               bebex:=116;
               if (DangerClass <= 2) then PomDangerClass:=0 else
                if (DangerClass <= 5) then PomDangerClass:=1 else
                 if (DangerClass <= 7) then PomDangerClass:=2 else
                  if (DangerClass = 255) then PomDangerClass:=255;
               case (Unit_types[UnitType,Races[Race].Ally]).TargetTyp of
                 0 : if (PomDangerClass <> 255) then Dec(LLightTG[PomDangerClass]);
                 1 : if (PomDangerClass <> 255) then Dec(LightTG[PomDangerClass]);
                 2 : if (PomDangerClass <> 255) then Dec(HeavyTG[PomDangerClass]);
                 3 : if (PomDangerClass <> 255) then Dec(AirTG[PomDangerClass]);
                 4 : if (PomDangerClass <> 255) then Dec(HeavyTG[PomDangerClass]);
               else
               end;
               if (ADangerClass <> 255) then Dec(AAttackTG[ADangerClass]);
               AntiLightTG:=AntiLightTG-Get_unit_anti_weight(Race,UnitType,L,PomDangerClass,ADangerClass);
               AntiHeavyTG:=AntiHeavyTG-Get_unit_anti_weight(Race,UnitType,T,PomDangerClass,ADangerClass);
               AntiAirTG:=AntiAirTG-Get_unit_anti_weight(Race,UnitType,AA,PomDangerClass,ADangerClass);
           { ** nyni priradime zatoulanou jednotku do pomocne TG ** }
               bebex:=119;
               if (CreateNewTaskGroup(Race,InvalidTaskGroupNumber,Units[J]) <> InvalidTaskGroupNumber)
               then begin
                   bebex:=117;
                   if (TaskGroups^[TGPom].Validity) then
                      TaskGroupCommand(Race,TaskGroup,MergeCom,0,TGPom,
                                       TaskGroups^[TGPom].ITaskGroupInfoPos,
                                       TaskGroups^[TGPOm].JTaskGroupInfoPos,100)
                   else
                      TaskGroupCommand(Race,TaskGroup,MergeCom,0,TGPom,
                                       RacesTGInfo^[Race,TGPom].IHomeTaskGroupInfoPos,
                                       RacesTGInfo^[Race,TGPom].JHomeTaskGroupInfoPos,100);
               end else begin { zarad TG zpatky }
                  bebex:=118;
                  AssignTaskGroup(Race,TGPom,Units[J]);
               end;
           end;
           { ** }

           bebex:=120;
           { nyni nastavujeme volny utok; u utocneho presunu je to tehdy,
             kdyz se nekdo pokusi na jednotku taskgrupy utocit; prepina-li se
             volny utok na True, soucasne se nastavi priznak inteligentniho
             utoceni jednotky tak, aby hned hledala cil }
           if (TaskGroups^[TaskGroup].Validity and (not WearOutRest)) then
           with (TaskGroups^[TaskGroup]) do begin
              bebex:=121;
              if ((not Free_attack) and (GrpFree_attack)) then begin
                 if (IntelliSearching_for_attack_flag < IntelliSearching_for_attack_limit)
                 then
                   IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit;
                 Free_attack:=GrpFree_attack;
              end;
              bebex:=122;
              {x}
              if ((Status = 0) and (MoveStatus=0) and Free_attack and
                   (not Return_to_base) and
                   (IntelliSearching_for_attack_flag < IntelliSearching_for_attack_limit) and
                   (Command <> PrepareCom) and ((TaskGroup <> 12) or
                    (UnitType <> 17) or (UnitsInsideNum > 0)))
              then begin
              { pokud jednotka necinne stoji, ale TG utoci, prirad
                jednotce cil jine jednotky }
                bebex:=123;
                if ((ADangerClass <> 255) and
                    GetActiveAttackTGInfo(Race,TaskGroup,1,IPos,JPos,Ix,Jx))
                then begin
                { vzdusna uroven }
                      bebex:=124;
                      if ((GetDistance(IPos,JPos,Ix,Jx) < 20) or
                          (UnitType = 18))
                      then begin
                      { cil se vybere jen tehdy, pokud neni vzdalen vice
                        jak 19 policek }
                        bebex:=125;
                        WayPointUk:=0;
                        if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then
                        { letecka jednotka }
                          Set_move_unit(Ix,Jx,Units[J],1,False,False)
                        else
                        { pozemni jednotka }
                          Set_move_unit(Ix,Jx,Units[J],0,False,False);
                      end;
                 end else begin
                 { pozemni uroven - stihac ne ! }
                   bebex:=126;
                   if (GetActiveAttackTGInfo(Race,TaskGroup,0,IPos,JPos,Ix,Jx) and
                       (UnitType <> 18)) then begin
                       if ((GetDistance(IPos,JPos,Ix,Jx) < 20) or
                           (UnitType = 19))
                       then begin
                       { cil se vybere jen tehdy, pokud neni vzdalen vice
                         jak 19 policek }
                         bebex:=127;
                         WayPointUk:=0;
                         if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then
                         { letecka jednotka }
                           Set_move_unit(Ix,Jx,Units[J],1,False,False)
                         else
                         { pozemni jednotka }
                           Set_move_unit(Ix,Jx,Units[J],0,False,False);
                       end;
                    end;
                 end;
              end;
           end;
         end; {if (Units[J] <> Nil) then begin}
     end;

  end;
end;

{ ***** }
procedure Unit_manager;
{ procedura prochazi pole jednotek a vsechny podle potreby ovlada
  ( zabezpecuje objizdeni, utoceni atd. )
}
label Skip, Kanec;
var Ix,Jx,I,J,K,L,IAim1,JAim1,IP,JP : Word;
    Dir, Pom, PomType, GroundType:Byte;
    RequestNewPhase:Boolean;
    ISize,JSize,IPosic,JPosic:Word;
    DMG,BP2,PL2,EE2,EX2,PomVal,DMGStrength:Double;
    BPPom,PLPom,EEPom,EXPom,DmgPom:Word;
    Buil:PBuilding;
    PomDangerClass:Word;
    Change:Boolean;
    MountainLevel:Byte; {0..trava, jinak (1,2,3) uroven kopce }
begin
   I:=1; J:=1;
   while ((I <= Number_of_units) and (J <= (MaxRaceUnits+1)*(MaxRace+1))) do begin
      if (Units[J] <> Nil) then with Units[J]^ do begin
      { jednotka na danem indexu existuje }
        {XXX}
        if (Damage > (Unit_types[UnitType,Races[Race].Ally].DefenceStrength + DamageBonus))
        then Damage:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength + DamageBonus;
        if ((XOffset > 32) or (XOffset > 32) or (UnitType = 0) or
            (UnitType > MaxTypesOfUnits) or (Race > MaxRace) or
            (Sight > 14) or (Direction mod 2 <> 0) and (Direction <> 1))
        then begin
        { recover mapy, pokud je nejaka chyba }
          if (WideDialogBox('DETEKOVaNA VakNa CHYBA PROGRAMU. MhkETE SPUSTIT OPRAVU. POKUD JI',
                            'NESTPUSTeTE, PROGRAM BUDE ZfEJMd UKONbEN S CHYBOU.',
                            'CHCETE SPUSTIT OPRAVU?',_YES_NO) = YES) then begin
            Dispose(Units[J]); Units[J]:=Nil;
            RecoverMap;
            GoTo Kanec;
          end;
        end;
        {XXX}
        if ((Status = 0) and ((XOffset <> 0) or (YOffset <> 0))) then begin
           XOffset:=0; YOffset:=0;
        end;
        {x}
        if (Race <> MyRace) then SetTerminator_fighterParams(True);
        GlobalJ:=J; bebex:=1;
        if (Races[Race].ChangeOnVisib and Visibility) then begin
          bebex:=2;
          ChangeUnitToMyRace(Units[J]);
          GoTo Kanec;
        end;
        {X}
        bebex:=3;
        Inc(I); RequestNewPhase:=False;

        {X nyni pripadna zmena dohledu v souvislosti s kopci X}
        MountainLevel:=0;
        if ((XOffset = 0) and (YOffset = 0)) then begin
          bebex:=4;
          case (MapBck^[IPos,JPos].BckType) of
            12,169 : MountainLevel:=1;
            13,170 : MountainLevel:=2;
            14,171 : MountainLevel:=3;
            15     : MountainLevel:=4;
          else
            if (BelowEqual(MapBck^[IPos,JPos].BckType,Hill) and
                Above(MapBck^[IPos,JPos].BckType,Desert))
            then MountainLevel:=255; { nejaky kopec - beze zmeny }
          end;
          bebex:=5;
          with (Unit_types[UnitType,Races[Race].Ally]) do case (MountainLevel) of
             0 : if ((Sight <> _Sight) and (TargetTyp <> 3)) then begin
                   SetFog(IPos,JPos,Sight,Race,False);
                   Sight:=_Sight; SetFog(IPos,JPos,Sight,Race,True);
                 end;
             1 : if ((Sight <> (_Sight+1)) and (TargetTyp <> 3)) then begin
                   SetFog(IPos,JPos,Sight,Race,False);
                   Sight:=_Sight+1; SetFog(IPos,JPos,Sight,Race,True);
                 end;
             2 : if ((Sight <> (_Sight+2)) and (TargetTyp <> 3)) then begin
                   SetFog(IPos,JPos,Sight,Race,False);
                   Sight:=_Sight+2; SetFog(IPos,JPos,Sight,Race,True);
                 end;
             3 : if ((Sight <> (_Sight+3)) and (TargetTyp <> 3)) then begin
                   SetFog(IPos,JPos,Sight,Race,False);
                   Sight:=_Sight+3; SetFog(IPos,JPos,Sight,Race,True);
                 end;
             4 : if ((Sight <> (_Sight+4)) and (TargetTyp <> 3)) then begin
                   SetFog(IPos,JPos,Sight,Race,False);
                   Sight:=_Sight+4; SetFog(IPos,JPos,Sight,Race,True);
                 end;
             255: if ((Sight = _Sight) and (TargetTyp <> 3)) then begin
                    SetFog(IPos,JPos,Sight,Race,False);
                    Sight:=_Sight+1; SetFog(IPos,JPos,Sight,Race,True);
                  end;
          end;
          bebex:=6666;
          {************************}
          { osetreni pohybu civilu }
          if (((UnitType = 3) or (UnitType = 4)) and (Race <> MyRace) and
              (SpecNumber = 0) and (Activity) and (not Destroyed)) then
            if (CivilianMoveFlag >= CivilianMoveLimit) then begin
            { s civilisty neco udelej }
               bebex:=6667;
               Civilian_move(Units[J]);
            end else CivilianMoveFlag:=CivilianMoveFlag+1;

        end;
        {X KONEC pripadne zmeny dohledu v souvislosti s kopci X}

        bebex:=6;
        if (FirePhase <> 0) then begin { jednotka "kouri" }
          Inc(FireFlag);
          if (FireFlag > 1) then begin
            FireFlag:=0;
            Inc(FirePhase);
            if (FirePhase > 4) then FirePhase:=1;
            RequestDraw:=True;
          end;
        end;
        {x} bebex:=7;
        if (GroupMoveBlock > 0) then begin
          Dec(GroupMoveBlock);
          if (GroupMoveBlock = 0) then begin
            RequestDraw:=True;
            if (Group = ActiveGroup) then Click_on_group(ActiveGroup);
          end;
        end;
        {x}
        bebex:=8;
        if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
            (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0))
        then begin
           bebex:=9;
           Down:=0;  { tyka se jen specialni letecke techniky }
           if ((Return_to_base) and (UnitsInsideNum <> 0))
           then UnLoad(Units[J]);
           bebex:=10;
           if (GroupMoveBlock > 0) then begin
              RequestDraw:=True;
              if (Group = ActiveGroup) then Click_on_unit(Units[J]);
           end;
        end;
        {x}
        bebex:=11;
        if ((Down = 2) and (Activity)) then begin
        { letecka jednotka - sedni si a vyloz}
          if (TargetType = 3) then begin
          { nejprve sedni na zem }
            bebex:=12;
            IP:=IPos; JP:=JPos;
            if (Find_free_place_for_landing(IP,JP,UnitsInsideNum)) then begin
            { nalezeno volne misto pro pristani }
              IntelliSearching_for_attack_flag:=-6*GetDistance(IPos,JPos,IP,JP);
              WayPointMax:=0; WayPointUk:=0;
              Set_move_unit(IP,JP,Units[J],0,False,False);
            end else Down:=0;
          end else begin
          { je na zemi, vyloz se }
             bebex:=13;
             Unload(Units[J]); Down:=0;
             IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit-2;
          end;
        end;
        {}
        bebex:=14;
        if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
            (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) and Activity) then begin
           { Specialni letecke jednotky }
           if ((Return_to_base) and (Status = 0)) then begin
           { letadlo pristava - presun je do boxu }
              bebex:=15;
              Erase_unit(Units[J],True);
              Set_place(IPos, JPos, Units[J], False,True);
              Units[J]^.TargetType:=2; { z leteckeho se stava tezky cil }
              SetFog(IPos,JPos,Sight,Race,False);
              IPos:=IAirport; JPos:=JAirport;
              Set_place(IPos, JPos, Units[J], True,True);
              SetFog(IPos,JPos,Sight,Race,True);
              Draw_unit(Units[J]);
              Return_to_base:=False;
              if (GameTimming = 0) then GroupMoveBlock:=SpecAirUnitBlock shr 1
              else GroupMoveBlock:=SpecAirUnitBlock;
              RequestDraw:=True;
              if (Group = ActiveGroup) then Click_on_group(ActiveGroup);
           end else begin
              if ((Status <> 0) and (not Return_to_base) and
                  (IPos = IAirport) and (JPos = JAirport) and
                  (TargetType <> 3)) then begin
              { letadlo vzleta }
                  { ZJISTI SE PRITOMNOST RADARU }
                  bebex:=16;
                  IAim1:=IAirport;
                  JAim1:=JAirport;
                  if (AirportPos = 0) then else
                    if (AirportPos = 2) then Dec(JAim1) else
                      if (AirportPos = 3) then begin
                        Dec(JAim1); Dec(IAim1);
                      end;
                  { zjisti, zda je v okoli letiste radar }
                  if (not Check_place_surroundings(IAim1,JAim1,2,2,True,21,Race))
                  then if (GroupMoveBlock = 0) then GroupMoveBlock:=2;
                  { nyni vlastni ovladani vzletu }
                  if (Free_place_two(IPos,JPos,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                     Unit_types[UnitType,Races[Race].Ally].JUnitSize,UnitType) and
                      (GroupMoveBlock = 0))
                  then begin
                    bebex:=17;
                    if ((Status = 130) and (GroupMoveBlock = 0))
                    then Status:=Direction;
                    SetFog(IPos,JPos,Sight,Race,False);
                    Set_place(IPos, JPos, Units[J], False,True);
                    TargetType:=3; { vzlet }
                    Set_place(IPos, JPos, Units[J], True,True);
                    SetFog(IPos,JPos,Sight,Race,True);
                  end else begin
                     Status:=130;
                  end;
              end;
           end;
        end else
          if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
              (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0) and
              ((Status <> 0) or (MoveStatus <> 0)) and
              (TargetType = 2)) then begin
           { helikoptera vzleta }
              if (Free_place_two(IPos,JPos,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                 Unit_types[UnitType,Races[Race].Ally].JUnitSize,UnitType) and
                  (GroupMoveBlock = 0))
              then begin
                 bebex:=18;
                 if (Status = 130) then Status:=Direction;
                 Set_place(IPos, JPos, Units[J], False,True);
                 TargetType:=3; { vzlet }
                 Set_place(IPos, JPos, Units[J], True,True);
                 PomType:=UnitType;
                 SetFog(IPos,JPos,Sight,Race,False);
                 Sight:=Unit_types[UnitType,Races[Race].Ally]._Sight;
                 SetFog(IPos,JPos,Sight,Race,True);
              end else begin
                Status:=130;
                if (GroupMoveBlock > 0) then Dec(GroupMoveBlock);
              end;
           end;

        bebex:=19;
        if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
            (TargetType = 3)) then begin
           bebex:=20;
           RequestNewPhase:=True;
           RequestDraw:=True;
        end;

        bebex:=21;
        if ((Status > 0) and (Status <= 129) and Activity) then begin
          { je-li jednotka na ceste, provede se presun }
          if ((UnitType = 2) and (Cargo <> 0) and (not Stop_)) then begin
          { RECYKLATOR }
          { zkus vylozit recyklator }
              bebex:=22;
              IPosic:=IPos; JPosic:=JPos;
              ISize:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
              JSize:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
              if (Check_place_surroundings(IPosic,JPosic,ISize,JSize,True,4,Race) and
                  (IPosic = WayPoint[WayPointUk].IAim) and
                  (JPosic = WayPoint[WayPointUk].JAim)) then Stop_:=True
              else GoTo Skip;
          end else begin
Skip:     { skutecny presun }
             bebex:=23;
             if ((Status  < 129) and (Status > 0) and
                 (XOffset = 0) and (YOffset = 0) and
                 (Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 255))
             then begin
                bebex:=24;
                if (MoveStatus < 32) then Inc(TurnFlag);
                if (TurnFlag > 7) then begin
                   bebex:=25;
                   Status:=129;
                   MoveDir:=Direction;
                   IdleFlag:=0;
                   TurnFlag:=0;
                end;
             end else TurnFlag:=0;
             bebex:=26;
             if (Status  = 129) then begin
                if (IdleFlag <= GetAccurateDelay(IdleLimit+IdleWait))
                then Inc(IdleFlag);
                if (IdleFlag = GetAccurateDelay(IdleLimit)) then
                   IdleFlag:=65535;
             end;
             bebex:=27;
             if (GroupMoveBlock <> 0) then Dec(GroupMoveBlock)
             else begin
               {if (((AttackMarkUnit = Nil) or (AttackMarkUnit^ = Nil) or
                    (Index <> AttackMarkUnit^^.Index)) and (FirePhase = 0))
               then RequestDraw:=False; {}
               bebex:=28;
               if ((WayPointUk <= MaxWayPoint) and (MaxWayPoint < 255) and
                   (IPos = WayPoint[WayPointUk].IAim) and
                   (JPos = WayPoint[WayPointUk].JAim) and (Status <> Direction) and
                   (Status < 129)) then begin
                  bebex:=29;
                  if ((XOffset = 0) and (YOffset = 0)) then Turn_unit(Units[J]);
                  if (Status = Direction) then Status:=0;
               end else begin
                  bebex:=30;
                  Move_unit(Units[J]);
               end;
             end;
             bebex:=31;
             if (Status <> 129) then begin
                if (IdleFlag = 65535) then
                  IdleFlag:=GetAccurateDelay(IdleLimit+IdleWait)
                else
                  if (IdleFlag >= GetAccurateDelay(IdleLimit)) then Dec(IdleFlag)
                  else IdleFlag:=0;
             end;
             bebex:=32;
          end;
        end else  begin
          bebex:=33;
          if ((FlashFlag <> 0) and Activity and (not Destroyed)) then begin
             Flash(Units[J],65535,65535,False);
             RequestDraw:=False;
          end;
        end;

        bebex:=34;
        if (((MoveStatus = 8) or (MoveStatus = 16) or (MoveStatus = 32) or
             (MoveStatus = 64) or (Status = 255)) and Activity) then begin
        { UTOK }
            bebex:=35;
            if (GroupMoveBlock <> 0) then Dec(GroupMoveBlock)
            else Attack_unit(Units[J]);
            if (Units[J] = Nil) then GoTo Kanec; { autodetonator se znicil }
        end else begin
           bebex:=36;
           if (Destroyed and (not Activity)) then begin
           { jednotka exploduje }
              bebex:=37;
              Prepare_disband_unit(Units[J]);
              if (Units[J] = Nil) then GoTo Kanec;
           end;
        end;

        bebex:=38;
        if ((Status = 0) and ((MoveStatus = 0) or (MoveStatus = 64)) and
            Activity) then begin
        { jednotka nic nedela }
           bebex:=39;
           if (UnitType = 2) then begin
           { RECYKLATOR }
              if (Cargo < 100) then begin
              { recyklator neni plny - recykluje ze " skladky" }
                 if (Above(MapBck^[IPos,JPos].BckType,Field) and
                     BelowEqual(MapBck^[IPos,JPos].BckType,Resrc)) then begin
                    bebex:=40;
                 { ano, pod recyklatorem je "skladka" }
                    Working:=True; HarvesterWait:=0;
                    if (GameTimming = 0) then Inc(HarvestPhase,2)
                    else Inc(HarvestPhase);
                    if (HarvestPhase > 1) then HarvestPhase:=0;
                    if (HarvestPhase = 0) then begin
                      bebex:=41;
                      Cargo:=Cargo+HarvestingSpeed;
                      if ((Group = ActiveGroup) and (Race = MyRace))
                      then UpdateMoralWearOut:=True;
                      with (ResourceInfo[MapBck^[IPos,JPos].Info]) do begin
                         if (Resource < BPperMove) then begin
                            bebex:=42;
                         { skladka je prazdna - zrus ji }
                            Resource:=0;
                            MapBck^[IPos,JPos].BckType:=54;
                            MapBck^[IPos,JPos].Info:=255;
                            OutBigMsg(6,'SKLaDKA MATERIaLU VYTdkENA');
                            Transfer_map_frame(IPos,JPos,IPos,JPos);
                            { a posli recyklator k budove recyklace }
                            Send_recyklator_home(Units[J]);
                            Working:=False;
                         end else begin
                         { normalni tezeni }
                            bebex:=43;
                            Resource:=Resource-BPperMove;
                            if (Cargo = 100) then begin
                               Send_recyklator_home(Units[J]);
                            end;
                         end;
                      end;
                    end;
                 end else
                 if (Cargo <> 0) then begin
                 { zkus vylozit recyklator - neni pod nim skladka }
                     bebex:=44;
                     IPosic:=IPos; JPosic:=JPos;
                     ISize:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
                     JSize:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
                     if (Check_place_surroundings(IPosic,JPosic,ISize,JSize,True,4,Race))
                     then begin
                     { vylozeni recyklatoru }
                         bebex:=45;
                         Working:=True; HarvesterWait:=0;
                         if (Cargo <= HarvesterUnloadSpeed) then begin
                           Cargo:=0;
                           { zvyhodneni hrace (pocitace) }
                           with (Races[Race]) do
                              Inc(Building_credits,
                                  Round(Harvester_credits_plus*HarvesterCapacity));
                           { nyni posleme recyklator zpet na naleziste }
                         end else Cargo:=Cargo-HarvesterUnloadSpeed;
                         if (Cargo = 0) then begin
                         { posli recyklator zpet na skladku }
                            bebex:=46;
                            WayPointMax:=0; WayPointUk:=0;
                            if ((Race <> MyRace) or (ActiveDefence)) then begin
                            { pocitac }
                              IP:=IPos; JP:=JPos; bebex:=47;
                              if (Find_resource_for_recyklator(IP,JP)) then begin
                                if (Find_resource_for_recyklator3(Ix,Jx)) then
                                else begin Ix:=65535; Jx:=65535; end;
                                if (GetDistance(IP,JP,Ix,Jx) <= 3) then begin
                                   IP:=Ix; JP:=Jx;
                                end;
                                bebex:=48;
                                ITarget:=IP; JTarget:=JP; ADefModeSteps:=0;
                                Set_move_unit(ITarget,JTarget,Units[J],0,False,False);
                              end;
                            end else begin
                            { lide }
                              bebex:=49;
                              if ((ITarget <= IMax) and (JTarget <= JMax))
                              then Set_move_unit(ITarget,JTarget,Units[J],0,False,False);
                            end;
                         end;
                         bebex:=50;
                         if ((Group = ActiveGroup) and (Race = MyRace))
                         then UpdateMoralWearOut:=True;
                         {!!! PROVIZORNI !!!}
                         Inc(Races[Race].Building_credits,BPperMoveUnload);
                         if (Race = MyRace) then UpdateBP:=True;
                         {!!! PROVIZORNI !!!}
                     end else Working:=False;
                 end else begin
                   bebex:=51;
                   { prazdny recyklator nekde stoji }
                   if (Race <> MyRace) then begin
                     bebex:=52;
                     Working:=False; IP:=IPos; JP:=JPos;
                     if (Find_resource_for_recyklator3(IP,JP)) then begin
                        bebex:=53;
                        ITarget:=IP; JTarget:=JP; ADefModeSteps:=0;
                        WayPointMax:=0; WayPointUk:=0;
                        Set_move_unit(ITarget,JTarget,Units[J],0,False,False);
                     end;
                   end;
                 end;
              end else begin
              { recyklator je plny - vraci se;zkus jej vylozit }
                 bebex:=54;
                 IPosic:=IPos; JPosic:=JPos;
                 ISize:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
                 JSize:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
                 if (Check_place_surroundings(IPosic,JPosic,ISize,JSize,True,4,Race))
                 then begin
                 { vylozeni recyklatoru }
                    bebex:=55;
                    Working:=True; HarvesterWait:=0;
                    if (Cargo <= HarvesterUnloadSpeed) then begin
                      bebex:=56;
                      Cargo:=0;
                      { zvyhodneni hrace (pocitace) }
                      with (Races[Race]) do
                        Inc(Building_credits,
                            Round(Harvester_credits_plus*HarvesterCapacity));
                      { nyni posleme recyklator zpet na naleziste }
                      WayPointMax:=0; WayPointUk:=0;
                      Set_move_unit(ITarget,JTarget,Units[J],0,False,False);
                    end else Cargo:=Cargo-HarvesterUnloadSpeed;
                    if ((Group = ActiveGroup) and (Race = MyRace))
                    then UpdateMoralWearOut:=True;
                    {!!! PROVIZORNI !!!}
                    Inc(Races[Race].Building_credits,BPperMoveUnload);
                    if (Race = MyRace) then UpdateBP:=True;
                    {!!! PROVIZORNI !!!}
                 end else begin bebex:=57; Send_recyklator_home(Units[J]); end;
              end;
           end;
           bebex:=58;
           { vyhledavani cilu a nahodne nataceni }
           if ((ActiveTargetSearch) and (Activity)) then
             if (Race = MyRace) then begin
               bebex:=59;
               if ((GroupMoveBlock = 0) and (not MyIntelliSearching or
                   not ActiveDefence) and (not Return_to_base))
               then Searching_for_attack(Units[J]);
             end else if (((Race = ThisCompRace1) or
                          (Race = ThisCompRace2) or (Race = ThisCompRace3) or
                          (Race = ThisCompRace4) or (Race = ThisCompRace5)) and
                          (not IntelliSearching) and (GroupMoveBlock = 0) and
                          (not Return_to_base))
                      then Searching_for_attack(Units[J]);
           bebex:=60;
           if (Disorder) then Inc(ActivityFlag);
           if (GameTimming = 0) then begin { "hruba varianta casovani" }
           end else begin { "jemna varianta casovani" }
              bebex:=61;
              if (ActivityFlag > RandomFlag) then begin { neco s ni delej }
                 bebex:=62;
                 ActivityFlag:=0;
                 RandomFlag:=(Random(15)+6) shl 4;
                 L:=Random(8)+1; { nahodne generovani }
                 Dir:=Direction;
                 asm
                    mov Al,Dir; mov Cx,L; ror Al,Cl; mov Dir,Al
                 end;
                 if (Disorder) then begin
                   Direction:=Dir;
                   {Redraw_unit(Units[J],True);{}
                   RequestDraw:=True;
                 end;
              end;
           end;
        end else ActivityFlag:=0;

        bebex:=63;
        if (Activity and (UnitType = 41) and (Race <> MyRace) and
            (UnitsInsideNum > 0)) then begin
           bebex:=64;
           UnLoad(Units[J]);
        end;

        bebex:=65;
        { proved opravu jednotek pocitace }
        if (Activity and (Status = 0) and ((MoveStatus = 0) or (MoveStatus = 64)))
        then with (Unit_types[UnitType,Races[Race].Ally]) do begin
           bebex:=66;
           DMG:=DefenceStrength+DamageBonus;
           if ((Autorepair > 0) and ((100-1.0*Damage/(DMG/100)) <= Autorepair) and
               (WarningBlingFlag = 0))
           then begin { automaticka oprava }
              bebex:=67;
              RequestDraw:=True; Damage:=Round(DMG);
              if ((1.0*Damage/(DMG/100) >= 35) and (FirePhase <> 0) and FireAllowed)
              then begin
                 FirePhase:=0; RequestDraw:=True; Inc(Morale,-RedDamage);
              end;
              if (Group = ActiveGroup) then UpdateDmg:=True;
           end;

           bebex:=68;
           if ((Damage < DMG) and (Race <> MyRace) and (not Repair)) then begin
           { zarad jednotku do fronty na opravu }
              bebex:=69;
              Buil:=Nil;
              RepairQueue^.Insert(Units[J],Buil);
           end;
        end;

        bebex:=70;
        { OPRAVA }
        if (Activity and (Status = 0) and ((MoveStatus = 0) or (MoveStatus = 64)) and
            Repair)
        then with (Races[Race]) do begin
        { pokracuj v oprave }
           bebex:=71;
           if (RepairsAvailable < 0) then begin
           { nedostatek opravarenske kapacity - zrus opravu }
              bebex:=72;
              Repair:=False; CompRepairFlag:=0;
              Inc(RepairsAvailable,UnitRepairCapacityNeed);
              if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
              DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
              {BPRepairRemainder:=0; PLRepairRemainder:=0;
              EERepairRemainder:=0; EXRepairRemainder:=0;{}
              BPRepair:=BPRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].BP)/100);
              PLRepair:=PLRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].PL)/100);
              EERepair:=EERepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].EE)/100);
              ExpRepair:=ExpRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].Ex)/100);
              if (UniqueNumber <> 65535) then
                 ExpRepair:=ExpRepair - RepairCost*((1*ExperienceLevel)/100);
           end else begin
           { NORMALNI OPRAVA }
              bebex:=73;
              if (GameTimming = 0) then Inc(RepairFlag,2) else Inc(RepairFlag);
              if (GameTimming = 0) then Inc(DrawRepairFlag,2) else Inc(DrawRepairFlag);
              DrawRepair:=True;
              RequestDraw:=True;
              if (DrawRepairFlag >= MaxRepairPhase) then begin
              { preklopeni priznaku o kresleni specialniho symbolu }
                 DrawRepairFlag:=0;
              end;
              if (RepairFlag >= GetAccurateDelay(RepairSpeed))
              then with (Unit_types[UnitType,Races[Race].Ally]) do begin
              { vlastni oprava}
                 bebex:=74;
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
                 EX2:=EX; if (UniqueNumber <> 65535) then EX2:=EX2+1*ExperienceLevel;
                 EX2:=(EX2/100)*RepairCost+PomVal/1000;
                 EXPom:=Trunc(EX2);
                 EXRepairRemainder:=Round(EX2*1000)-Trunc(EX2)*1000;
                 if ((Building_credits < BPPom) or (Plastic_credits < PLPom) or
                     (Electric_energy < EEPom) or (Battle_experience < EXPom) or
                     (BP > 0) and (Building_credits <= 0) or
                     (PL > 0) and (Plastic_credits <= 0) or
                     (EX > 0) and (Battle_experience <= 0) or
                     (EE > 0) and (Electric_energy <= 0) or
                     (CompRepairFlag >= CompRepairFlagLimit) and (Race <> MyRace))
                 then begin { nedostatek materialu - zastav opravu }
                    bebex:=75;
                    Repair:=False; CompRepairFlag:=0;
                    Inc(RepairsAvailable,UnitRepairCapacityNeed);
                    if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
                    DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                    {BPRepairRemainder:=0; PLRepairRemainder:=0;
                    EERepairRemainder:=0; EXRepairRemainder:=0;{}
                    RepairRemainder:=0;
                    BPRepair:=BPRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].BP)/100);
                    PLRepair:=PLRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].PL)/100);
                    EERepair:=EERepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].EE)/100);
                    ExpRepair:=ExpRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].Ex)/100);
                    if (UniqueNumber <> 65535) then
                      ExpRepair:=ExpRepair - RepairCost*((1*ExperienceLevel)/100);
                    if (Race = MyRace) then OutBigMsg(5,'NEDOSTATEK MATERIaLU NA OPRAVU');
                 end else begin { oprava OK }
                    bebex:=76;
                    PomVal:=RepairRemainder;
                    DMG:=DefenceStrength+DamageBonus;
                    PomVal:=(DMG/100)*RepairValue+PomVal/1000;
                    RepairRemainder:=Round(PomVal*1000)-Trunc(PomVal)*1000;
                    DmgPom:=Trunc(PomVal);
                    if (Race <> MyRace) then Inc(CompRepairFlag);
                    if ((Damage+DmgPom) >= DMG) then begin
                       bebex:=77;
                       Damage:=Trunc(DMG); { HOTOVO ! }
                       Repair:=False;
                       Inc(RepairsAvailable,UnitRepairCapacityNeed);
                       if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
                       DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
                       {PBPRepairRemainder:=0; PLRepairRemainder:=0;
                       EERepairRemainder:=0; EXRepairRemainder:=0;{}
                       RepairRemainder:=0;
                       BPRepair:=BPRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].BP)/100);
                       PLRepair:=PLRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].PL)/100);
                       EERepair:=EERepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].EE)/100);
                       ExpRepair:=ExpRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].Ex)/100);
                       if (UniqueNumber <> 65535) then
                          ExpRepair:=ExpRepair - RepairCost*((1*ExperienceLevel)/100);
                       CompRepairFlag:=0;
                    end else Damage:=Damage+DmgPom;

                    bebex:=78;
                    DMGStrength:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
                    DMGStrength:=DMGStrength/100; DMG:=Damage; DMG:=DMG/DMGStrength;
                    if ((DMG >= 35) and (FirePhase <> 0) and FireAllowed)
                    then begin
                       FirePhase:=0; RequestDraw:=True;
                       Inc(Morale,-RedDamage);
                    end;
                    Dec(Building_credits,BPPom); Dec(Plastic_credits,PLPom);
                    Dec(Electric_energy,EEPom); Dec(Battle_experience,EXPom);
                    if (Group = ActiveGroup) then
                       UpdateDmg:=True;
                    if (Race = MyRace) then begin
                       UpdateEEEnergy:=True; UpdatePL:=True; UpdateBP:=True;
                       UpdateEXP:=True;
                    end;
                    if (Activity and ((Races[Race].RaceType = 3) or
                        (Races[Race].RaceType = 6)) and
                        (WearOut < MinimalWearOut)) then begin
                    { zlepsuj opotrebeni }
                       bebex:=79;
                       WearOut:=WearOut+SpeciallWearOutRepair;
                       Change_unit_wear_out(Units[J]);
                    end;
                 end;
              end;
           end;
        end else
           if (((Status <> 0) or ((MoveStatus <> 0) and (MoveStatus <> 64)) or
                 not Activity) and Repair) then with (Races[Race]) do begin
           { probiha oprava, jednotka vyviji cinnost nebo neni
             aktivni - zrus opravu }
              bebex:=80;
              Repair:=False; CompRepairFlag:=0;
              Inc(RepairsAvailable,UnitRepairCapacityNeed);
              if (DrawRepair) then RequestDraw:=True; { smaz symbol opravy }
              DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
              {BPRepairRemainder:=0; PLRepairRemainder:=0;
              EERepairRemainder:=0; EXRepairRemainder:=0;{}
              RepairRemainder:=0;
              BPRepair:=BPRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].BP)/100);
              PLRepair:=PLRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].PL)/100);
              EERepair:=EERepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].EE)/100);
              ExpRepair:=ExpRepair - RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].Ex)/100);
           end;

        bebex:=81;
        { OPOTREBENI }
        if ((not Destroyed) and ((Races[Race].RaceType = 3) or
            (Races[Race].RaceType = 6)) and (Status = 0) and
            ((MoveStatus = 0) or (MoveStatus = 64)) and
            (WearOut < MinimalWearOut)) then begin
           bebex:=82;
        { zlepsuj opotrebeni }
           if (WearOutFlag <> 0) then begin
              if (GameTimming = 0) then Dec(WearOutFlag,2)
              else Dec(WearOutFlag);
           end else begin
              if (GameTimming = 0) then WearOutFlag:=WearOutRepairSpeed shr 1
              else WearOutFlag:=WearOutRepairSpeed;
              if (WearOut <= 50) then WearOut:=WearOut+WearOutRepair6
              else
                if (WearOut <= 80) then WearOut:=WearOut+WearOutRepair5
                else
                  if (WearOut <= 120) then WearOut:=WearOut+WearOutRepair4
                  else
                    if (WearOut <= 150) then WearOut:=WearOut+WearOutRepair3
                    else
                      if (WearOut <= 170) then WearOut:=WearOut+WearOutRepair2
                      else WearOut:=WearOut+WearOutRepair1;
              bebex:=83;
              Change_unit_wear_out(Units[J]);
           end;
        end;

        bebex:=84;
        { MORALKA }
        if ((Activity) and (UnitType <> 41) and
            ((MapInfo^[IInfoPos,JInfoPos].MoraleModifier[Race] <> 0) or
             (Races[Race].GlobalMorale <> 0)))
        then begin
            bebex:=85;
            with (MapInfo^[IInfoPos,JInfoPos]) do begin
             bebex:=86;
             PomVal:=MoraleModifier[Race];
             { globalne nesmi moralka klesnout pod 1/2 prumerne moralky: }
             if ((Races[Race].GlobalMorale >= 0) or
                 (Morale >= AverageMorale shr 1))
             then PomVal:=PomVal+Races[Race].GlobalMorale;
             if (PomVal < 0) then
             { snizujeme zaporny vliv moralky zkusenosti jednotky }
                PomVal:=PomVal-(PomVal/100)*ExperienceLevel*5
             else PomVal:=PomVal;
             PomVal:=PomVal/Global_morale_eval_div;

             Morale:=Morale+Round(PomVal);
             bebex:=87;
             Change_unit_experience_morale(Units[J]);
           end;
        end;

        bebex:=88;
        { nyni navyseni moralky dle aktualni hodnosti }
        if (GameTimming = 0) then Inc(SkillLevelMoraleBonusFlag,2)
        else Inc(SkillLevelMoraleBonusFlag);
        if (SkillLevelMoraleBonusFlag >=
            GetAccurateDelay(SkillLevelMoraleBonusSpeed)) then begin
           SkillLevelMoraleBonusFlag:=0;
        end;

        bebex:=89;
        if (Morale <= MinMorale) then begin
        { jednotka se vzda }
          bebex:=90;
          for K:=0 to MaxRace do
            if (Races[K].Friend[Race] = 0) then with (Units[J]^) do begin
            { pridaji se bitevni body }
               bebex:=91;
               UpdateRaceBattlePoints(K,UnitType,False,DamageBonus,LAttackBonus1,
                                      HAttackBonus1,AAttackBonus1);
            end;
          Status:=Direction; Destroyed:=False;
          if ( Race = MyRace) then OutBigMsg(255,'JEDNOTKA SE VZDALA!');
          if (UnitsInsideNum <> 0) then begin
          { pokud jsou uvnitr nalozeny nejake jednotky }
             for K:=0 to MaxGroupUnits-2 do begin
               if ((UnitsInside[K] <> 0) and
                   (Units[UnitsInside[K]] <> Nil) and
                   (UnitsInsideNum > 0)) then
               with (Units[UnitsInside[K]]^) do begin
                  { zapocteni nakladu do bodu }
                  Selected:=True; Destroyed:=True;{}
                  IInfoPos:=Units[J]^.IInfoPos; JInfoPos:=Units[J]^.JInfoPos;
                  if (Units[J]^.Group = ActiveGroup) then
                     Clear_unit_slot(Units[Units[J]^.UnitsInside[K]]);
                  Disband_unit(Units[Units[J]^.UnitsInside[K]],True,False);{}
                  Dec(Units[J]^.UnitsInsideNum);
               end;
             end;
          end;
          {x}
          Disband_unit(Units[J],True,False);
          GoTo Kanec;
        end;

        bebex:=92;
        if (Races[Race].RaceType mod 3 = 0) then begin { roboti }
           bebex:=93;
           if (WearOut <= CriticalWearOut) then begin
           { jednotka se da do srotu  }
             bebex:=94;
             for K:=0 to MaxRace do
               if (Races[K].Friend[Race] = 0) then with (Units[J]^) do begin
               { pridaji se bitevni body }
                 UpdateRaceBattlePoints(K,UnitType,False,DamageBonus,LAttackBonus1,
                                         HAttackBonus1,AAttackBonus1);
               end;
             Status:=Direction;
             Destroyed:=False;
             if ( Race = MyRace) then OutBigMsg(255,'JEDNOTKA POSLaNA DO gROTU!');
             if (UnitsInsideNum <> 0) then begin
             { pokud jsou uvnitr nalozeny nejake jednotky }
                for K:=0 to MaxGroupUnits-2 do begin
                  if ((UnitsInside[K] <> 0) and
                      (Units[UnitsInside[K]] <> Nil) and
                      (UnitsInsideNum > 0)) then
                  with (Units[UnitsInside[K]]^) do begin
                     { zapocteni nakladu do bodu }
                     Selected:=True; Destroyed:=True;{}
                     IInfoPos:=Units[J]^.IInfoPos; JInfoPos:=Units[J]^.JInfoPos;
                     if (Units[J]^.Group = ActiveGroup) then
                        Clear_unit_slot(Units[Units[J]^.UnitsInside[K]]);
                     Disband_unit(Units[Units[J]^.UnitsInside[K]],True,False);{}
                     Dec(Units[J]^.UnitsInsideNum);
                  end;
                end;
             end;
             {x}
             Disband_unit(Units[J],True,False);
             GoTo Kanec;
           end else
             if (Race <> MyRace) then
               if (WearOut <= WearOutRestLimit) then begin
                 bebex:=95;
                 WearOutRest:=True;
                 if ((XOffset = 0) and (YOffset = 0)) then begin
                    Stop_unit(Units[J],False,False);
                    MoveStatus:=0;
                 end;
               end else
                 if ((WearOut > (MinimalWearOut-5)) and WearOutRest) then begin
                    WearOutRest:=False;
                 end;
        end;

        { * PRO MOD AKTIVNI OBRANY * }
        {if (Activity and (Race <> MyRace) and Attacking and ActiveDefence and
            (Status = 0) and (MoveStatus <= 1) and (WayPointUk = 255) and
            (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0)) then
        begin { mod aktivni obrany }
        {  WayPointUk:=0; WayPointMax:=0; Attacking:=False;
          if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) then
             Set_move_unit(ITarget,JTarget,Units[Index],1,False,False)
          else
             Set_move_unit(ITarget,JTarget,Units[Index],0,False,False);
        end;{}

        bebex:=96;
        { PRIPADNE BLIKANI NA RADARU }
        if ((WarningBlingFlag=MaxWarningBlingValue) and (Race = MyRace)) then begin
        { nastav barvu jednotky na radaru blikavou barvou }
           DrawRadarPixel(IPos,JPos);
           DrawRadarPixel(IPos,JPos+1);
           DrawRadarPixel(IPos+1,JPos);
           DrawRadarPixel(IPos+1,JPos+1);
        end;
        if (WarningBlingFlag <> 0) then begin
          Dec(WarningBlingFlag);
          if ((WarningBlingFlag = 0) and (Race = MyRace)) then begin
          { nastav barvu jednotky na radaru na normalni }
             DrawRadarPixel(IPos,JPos);
             DrawRadarPixel(IPos,JPos+1);
             DrawRadarPixel(IPos+1,JPos);
             DrawRadarPixel(IPos+1,JPos+1);
          end;
        end;

        bebex:=97;
        { * * }
        if (ShootDelayFlag1 > 0) then Dec(ShootDelayFlag1);
        if (ShootDelayFlag2 > 0) then Dec(ShootDelayFlag2);

        bebex:=100;
        Manager_part_2(Units[J]);

        bebex:=128;
        { VYKRESLENI }
        if ((Units[J] <> Nil) and (RequestDraw) and (Activity))
        then begin
          if (RequestNewPhase) then begin
            if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
            if (Phase >= Unit_types[UnitType,Races[Race].Ally].MaxPhase) then Phase:=0;
          end;
          bebex:=129;
          Redraw_unit(Units[J],True);{}
          bebex:=1129;
        end;
        if (Units[J] <> Nil) then RequestDraw:=False;
      end; { jednotka na danem indexu existuje }
Kanec:
      Inc(J);
   end; { while }
   bebex:=130;
   GlobalJ:=65535; bebex:=0;
   SetTerminator_fighterParams(False);
end;

{ ***** }
procedure Unit_manager_only_draw;
{ provadi pouze vykresleni pro GAMESTOPPED
}
var I, J: Integer;
begin
 I:=1; J:=1;
 while ((I <= Number_of_units) and (J <= (MaxRaceUnits+1)*(MaxRace+1))) do begin
   if (Units[J] <> Nil) then with Units[J]^ do begin
      { jednotka na danem indexu existuje }
      Inc(I);
      { VYKRESLENI }
      if ((RequestDraw) and (Activity)) then begin
        Redraw_unit(Units[J],True);{}
      end;
      if (Units[J] <> Nil) then RequestDraw:=False;
   end;
   Inc(J);
 end; { while }
end;

{ ***** }
procedure _units3_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'9'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _units3_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'9'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************* }
begin
   FailedCondition:=-1;
end.