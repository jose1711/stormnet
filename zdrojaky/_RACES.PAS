unit _races;
{$C FIXED PRELOAD PERMANENT}
interface

uses _units2;
const L=0; T=1; L_T=2; U=3; N=4; AA=5; Turret=6;

procedure Init_races;
procedure Init_races2;
procedure UpdateRaceBattlePoints(Race,UnitType:Byte; Building:Boolean;
                                 DamageBonus,LAttackBonus1,HAttackBonus1,
                                 AAttackBonus1:Integer);
procedure UpdateScore(Race,UnitType:Byte; Building,Destroyed:Boolean;
                      DamageBonus,LAttackBonus1,HAttackBonus1,AAttackBonus1:Integer;
                      Lost:Boolean);
function GetMoraleModif(Race,UnitType:Byte; Building:Boolean;
                        DamageBonus,LAttackBonus1,HAttackBonus1,
                        AAttackBonus1:Integer):Double;
function UnitProductionPossible(Race, UnitType:Byte):Boolean;
function BuildingProductionPossible(Race, BuildingType:Byte):Boolean;
procedure SetActionLevel(ActionLev:Byte);
procedure _races_save;
procedure _races_load;
function Get_unit_anti_weight(Race, UnitTyp, Category:Word; Class,AAClass:Byte):Single;
function GetProdPrioB(ElementType,Prior:Word):Word;
function GetProdPrioU(Prior:Word):Word;
function GetBuildingPlaceRequest(BuildingType:Byte):Byte;
function GetUnitPlaceRequest(UnitType:Byte):Byte;

implementation
uses Data, Grafika2, _buildings, Graph257;

var I,J,K:Word;

procedure Init_races;
{ inicializuje udaje o jednotlivych rasach
}
var I,J,K:Word;
    Racex:TPermittedUnits;
    UnitType:Byte;
    Pom, Speed : Double;
    Target:Byte;
    Result,ShootRange:Word;
begin
   { nyni nastaveni vyrobnich vzoru pro jednotlive rasy }
   { 0..OSN; 1..Odboj; 2..Kolaboranti; 3..Roboti;
     4..OSNNeutral; 5..RobotiNeutral; 6..RobotiOSN }
   for I:=1 to MaxTypesOfUnits do Racex[I]:=False;

   { * }

   { init nahodnych cisel }
   Randomize;
   for I:=0 to MaxRandomArrayIndex do RandomArray[I]:=Random(10);

   Races[0].RaceColor:=176; Races[1].RaceColor:=181;  Races[2].RaceColor:=154;
   Races[3].RaceColor:=144; Races[4].RaceColor:=149; Races[5].RaceColor:=186;

   { nastaveni typu ras pro jednotlive hrace }
   Races[0].RaceType:=0; Races[1].RaceType:=1;  Races[2].RaceType:=2;
   Races[3].RaceType:=3; Races[4].RaceType:=0; Races[5].RaceType:=0;
   { 0..OSN; 1..Odboj; 2..Kolaboranti; 3..Roboti;
     4..OSNNeutral; 5..RobotiNeutral; 6..RobotiOSN }

   for I:=0 to MaxRace do with Races[I] do begin
     HelpRace:=True;
     GlobalMorale:=0; GlobalMoraleTemp:=0;
     Harvester_credits_plus:=0;
     EE_credits_plus:=0;
     for J:=0 to MaxRace do Friend[J]:=0;

     for J:=1 to MaxTypesOfBuildings do PermittedBuildings[J]:=False;
     PermittedUnits:=Racex;
     Score:=0;
     { vsechny budovy jsou povoleny }
     I_free_airport_space_max_index:=255; { neplatna hodnota }
     LastRecyklatorBuildInfoIndex:=MaxRecyklatorBuildInfoIndex+1;
     RecyklatorBuildInfoCount:=0;
     MaxRepairCapacity:=0; { udava celkovou opravarenskou kapacitu }
     RepairsAvailable:=0;
     EECapacity:=0;
     Number_of_race_units:=0;
     BPShortage:=0; PLShortage:=0; EEShortage:=0; EXPShortage:=0;
     AccumulatorShortage:=0; Base2Shortage:=0; BarrackShortage:=0;
     HeavyFactoryShortage:=0; SpecialFactoryShortage:=0;
     DefenceFactoryShortage:=0; RepairFactoryShortage:=0;
     LightFactoryShortage:=0; CentrumPosilShortage:=0;
     {x}
     BPShortageForbid:=0; PLShortageForbid:=0; EEShortageForbid:=0;
     EXPShortageForbid:=1; AccumulatorShortageForbid:=0;
     Base2ShortageForbid:=0; BarrackShortageForbid:=0;
     HeavyFactoryShortageForbid:=0; SpecialFactoryShortageForbid:=0;
     DefenceFactoryShortageForbid:=0; RepairFactoryShortageForbid:=0;
     LightFactoryShortageForbid:=0; CentrumPosilShortageForbid:=0;
     RadarShortageForbid:=0; AirPortShortageForbid:=0;
     ActualFreeStructures:=0;
   end;

   { budovy jsou implicitne povoleny vsechny }
   with (Races[0]) do begin
      Building_credits:=0; Plastic_credits:=0;
      Electric_energy:=0;  Battle_experience:=0;
      Harvester_credits_plus:=0; { zvyhodneni pri vykladani harvesteru;
      prida se tato hodnota * kapacita harvesteru }
      EE_credits_plus:=0;
      { jde o koeficient, ktery se prida k produkci elektrarny
        (EE_credits_plus*EEProduction) }
   end;

   with (Races[1]) do begin
      Building_credits:=0; Plastic_credits:=0;
      Electric_energy:=0;  Battle_experience:=0;
      Harvester_credits_plus:=0; { zvyhodneni pri vykladani harvesteru;
      prida se tato hodnota * kapacita harvesteru }
      EE_credits_plus:=0;
      { jde o koeficient, ktery se prida k produkci elektrarny
        (EE_credits_plus*EEProduction) }
   end;

   with (Races[2]) do begin
      Building_credits:=0; Plastic_credits:=0;
      Electric_energy:=0;  Battle_experience:=0;
      Harvester_credits_plus:=0; { zvyhodneni pri vykladani harvesteru;
      prida se tato hodnota * kapacita harvesteru }
      EE_credits_plus:=0;
      { jde o koeficient, ktery se prida k produkci elektrarny
        (EE_credits_plus*EEProduction) }
   end;

   with (Races[3]) do begin { POCITAC }
      Building_credits:=0; Plastic_credits:=0;
      Electric_energy:=0;  Battle_experience:=0;
      Harvester_credits_plus:=0.2; { zvyhodneni pri vykladani harvesteru;
      prida se tato hodnota * kapacita harvesteru }
      EE_credits_plus:=0.2;
      { jde o koeficient, ktery se prida k produkci elektrarny
        (EE_credits_plus*EEProduction) }
   end;

   with (Races[4]) do begin
      Building_credits:=0; Plastic_credits:=0;
      Electric_energy:=0;  Battle_experience:=0;
      Harvester_credits_plus:=0; { zvyhodneni pri vykladani harvesteru;
      prida se tato hodnota * kapacita harvesteru }
      EE_credits_plus:=0;
      { jde o koeficient, ktery se prida k produkci elektrarny
        (EE_credits_plus*EEProduction) }
   end;

   with (Races[5]) do begin { jako Races[0] }
      Building_credits:=0; Plastic_credits:=0;
      Electric_energy:=0;  Battle_experience:=0;
      Harvester_credits_plus:=0; { zvyhodneni pri vykladani harvesteru;
      prida se tato hodnota * kapacita harvesteru }
      EE_credits_plus:=0;
      { jde o koeficient, ktery se prida k produkci elektrarny
        (EE_credits_plus*EEProduction) }
   end;
end;

{ ***** }
procedure Init_races2;
{
}
var UnitType:Byte;
    Pom, Speed : Single;
    Target:Byte;
    Result,ShootRange:Word;
begin
   UnitType:=16;
   with (Unit_types[UnitType,Races[MyRace].Ally]) do begin { jednotka }
      ShootRange:=(2*Hi(ShootRange1)-Lo(ShootRange1))*10;
      if (SpeedLevel > 6) then Speed:=0
      else Speed:=UnitSpeedPct[SpeedLevel];
      Pom:=DefenceStrength+
           (LightAttack1+HeavyAttack1+AirAttack1)*GetKadence(MyRace,ShootSpeed1,UnitType) +
            ShootRange+Speed;
      Target:=TargetTyp;
   end;
   case (Target) of
      0 : Pom:=Pom*0.9;
      1 : Pom:=Pom*1;
      2 : Pom:=Pom*1.1;
      3 : Pom:=Pom*1.1;
   else
      Error(0,'unita _races, procedura Init_races');{}
   end;
   { nasledujici operace se provede pouze 1* za hru }
   ScoreDiv:=Pom/90; if (ScoreDiv = 0) then Error(0,'unita _races, procedura Init_races');{}
   BattleExperienceDiv:=Pom/9;
   if (BattleExperienceDiv = 0) then Error(0,'unita _races, procedura Init_races');{}
end;

{ ***** }
procedure UpdateRaceBattlePoints(Race,UnitType:Byte; Building:Boolean;
                                 DamageBonus,LAttackBonus1,HAttackBonus1,
                                 AAttackBonus1:Integer);
{ Rase Race pripocita BattlePoints za zniceni jednotky typu UnitType
  nebo budovy UnitType (dle nastaveni Building)
}
var Pom, Speed : Double;
    Target:Byte;
    Result,ShootRange:Word;
begin
   if (Building) then with (Building_types[UnitType]) do begin { budova }
     if (UnitType <> 25) then begin { nesmi jit o budovu-prekazku }
       Pom:=DefenceStrength;
       Pom:=Pom*BuildingBEModifier;
       Pom:=(Pom/100)*GetBuildingWeight(UnitType);
       Target:=2;
     end else Pom:=0;
   end else with (Unit_types[UnitType,Races[Race].Ally]) do begin { jednotka }
      ShootRange:=(2*Hi(ShootRange1)-Lo(ShootRange1))*10;
      if (SpeedLevel > 6) then Speed:=0
      else Speed:=UnitSpeedPct[SpeedLevel];
      Pom:=DefenceStrength+DamageBonus+
           (LightAttack1+HeavyAttack1+AirAttack1+LAttackBonus1+
            HAttackBonus1+AAttackBonus1)*GetKadence(Race,ShootSpeed1,UnitType) +
            ShootRange+Speed;
      Target:=TargetTyp;
   end;
   case (Target) of
      0 : Pom:=Pom*InfantryBEModifier;
      1 : Pom:=Pom*LightUnitBEModifier;
      2 : Pom:=Pom*HeavyUnitBEModifier;
      3 : Pom:=Pom*AirUnitBEModifier;
   else
      Pom:=0;
   end;

   if (BattleExperienceDiv > 0) then begin
     Pom:=Pom / BattleExperienceDiv;
   end else Pom:=0;
   if (Race <> MyRace) then begin
     case (GameLevel) of
        0 : Pom:=Pom*1.2;
        1 : Pom:=Pom*1.3;
        2 : Pom:=Pom*1.6;
        3 : Pom:=Pom*1.7;
        4 : Pom:=Pom*2.0;
     end;
   end else begin
     if (Races[MyRace].Battle_experience < 50) then Pom:=Pom*0.6
     else
       if (Races[MyRace].Battle_experience < 100) then Pom:=Pom*0.5
       else
        if (Races[MyRace].Battle_experience < 150) then Pom:=Pom*0.45
        else
         if (Races[MyRace].Battle_experience < 200) then Pom:=Pom*0.3;
   end;
   Result:=Round(Pom);
   Inc(Races[Race].Battle_experience,Result);
   if (Race = MyRace) then UpdateEXP:=True;
end;

{ ***** }
procedure UpdateScore(Race,UnitType:Byte; Building,Destroyed:Boolean;
                      DamageBonus,LAttackBonus1,HAttackBonus1,AAttackBonus1:Integer;
                      Lost:Boolean);
{ Rase Race pripocita score za zniceni nepratelske (nebo vytvoreni sve
  Destroyed=False) jednotky typu UnitType nebo budovy UnitType
  (dle nastaveni Building)
  Lost = True, pokud dany objekt rasa ztratila
}
var Pom,Speed : Double;
    Target:Byte;
    Result,ShootRange:Word;
begin
   if (Building) then with (Building_types[UnitType]) do begin { budova }
     if (UnitType <> 25) then begin { nesmi jit o budovu-prekazku }
       Pom:=(DefenceStrength/100)*GetBuildingWeight(UnitType);
       Target:=2;
     end else begin
       Pom:=0; Target:=2;
     end;
   end else with (Unit_types[UnitType,Races[Race].Ally]) do begin { jednotka }
      ShootRange:=(2*Hi(ShootRange1)-Lo(ShootRange1))*10;
      if (SpeedLevel > 6) then Speed:=0
      else Speed:=UnitSpeedPct[SpeedLevel];
      Pom:=DefenceStrength+DamageBonus+
           (LightAttack1+HeavyAttack1+AirAttack1+LAttackBonus1+
            HAttackBonus1+AAttackBonus1)*GetKadence(Race,ShootSpeed1,UnitType) +
            ShootRange+Speed;
      Target:=TargetTyp;
   end;
   case (Target) of
      0 : Pom:=Pom*0.9;
      1 : Pom:=Pom*1;
      2 : Pom:=Pom*1.1;
      3 : Pom:=Pom*1.1;
   else
      Error(0,'unita _races, procedura UpdateScore');{}
   end;

   if (ScoreDiv > 0) then begin
     Pom:=Pom / ScoreDiv;
   end else Pom:=0;

   { PROMENNE PRO VYPOCET HERNICH BODU }

   with (Races[Race]) do begin
      if (not Destroyed) then begin { vytvoreni }
         if (Building) then begin
           _ProducedBuildingsAll:=_ProducedBuildingsAll+Pom;
           if (TimeSlot > 256) then
              _InGameProducedBuildings:=_InGameProducedBuildings+Pom;
         end else begin
           _ProducedUnitsAll:=_ProducedUnitsAll+Pom;
           if (TimeSlot > 256) then
              _InGameProducedUnits:=_InGameProducedUnits+Pom;
         end;
      end else begin { likvidace }
        if (not Lost) then begin  { kill }
           if (Building) then begin
              _KilledBuildings:=_KilledBuildings+Pom;
           end else begin
              _KilledUnits:=_KilledUnits+Pom;
           end;
        end else begin { ztrata }
           if (Building) then begin
              _LostBuildings:=_LostBuildings+Pom;
           end else begin
              _LostUnits:=_LostUnits+Pom;
           end;
        end;
      end;
   end; { with (Races[Race]) do begin }

   { NYNI BODY DO TABULKY }
   if (not Lost) then begin
      { vytvoreni objektu je pouze 50% bodoveho hodnoceni }
      if (not Destroyed) then Pom:=Pom*0.5 else Pom:=Pom;
      Result:=Round(Pom);
      if ((1000000-Result) <= Races[Race].Score) then Races[Race].Score:=1000000
      else Inc(Races[Race].Score,Result);
   end;
end;

{ ***** }
function GetMoraleModif(Race,UnitType:Byte; Building:Boolean;
                        DamageBonus,LAttackBonus1,HAttackBonus1,
                        AAttackBonus1:Integer):Double;
{ vypocita zmenu moralky po zniceni jednotky typu UnitType nebo budovy
  UnitType (dle nastaveni Building)
}
var Pom,Speed : Double;
    Target:Byte;
    Result,ShootRange:Word;
begin
   if (Building) then with (Building_types[UnitType]) do begin { budova }
     if (UnitType <> 25) then begin { nesmi jit o budovu-prekazku }
       Pom:=DefenceStrength;
       Target:=2;
     end else Pom:=0;
   end else with (Unit_types[UnitType,Races[Race].Ally]) do begin { jednotka }
      ShootRange:=(2*Hi(ShootRange1)-Lo(ShootRange1))*10;
      if (SpeedLevel > 6) then Speed:=0
      else Speed:=UnitSpeedPct[SpeedLevel];
      Pom:=DefenceStrength+DamageBonus+
           (LightAttack1+HeavyAttack1+AirAttack1+LAttackBonus1+
            HAttackBonus1+AAttackBonus1)*GetKadence(Race,ShootSpeed1,UnitType) +
            ShootRange+Speed;
      Target:=TargetTyp;
   end;
   case (Target) of
      0 : Pom:=Pom*0.9;
      1 : Pom:=Pom*1;
      2 : Pom:=Pom*1.1;
      3 : Pom:=Pom*1.1;
   else
      Error(0,'unita _races, procedura GetMoraleModif');
   end;
   GetMoraleModif:=Pom;
end;

{ ***** }
function UnitProductionPossible(Race, UnitType:Byte):Boolean;
{ vraci True, pokud lze pri aktualni konfiguraci danou jednotku produkovat
}
begin
   with (Races[Race]) do case (UnitType) of
      1 : begin { nakladak }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      2 : begin { recyklator }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      3 : begin { civilista }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      4 : begin { osobni auto }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      5 : begin { samopalnik }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      6 : begin { tankobornik }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      7 : begin { vysadkar }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                 ((ExistBuildings[9] > 0) or (MissionNumber = 31) and (Race=MyRace)) and
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      8 : begin { jeep }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      9 : begin { vysadkarsky tank }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[21] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      10: begin { raketove vozidlo }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[8] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      11: begin { transporter }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      12: begin { BVP }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                ((ExistBuildings[2] > 0)  or (ExistBuildings[15] > 0)) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      13: begin { tank }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      14: begin { samohybne delo }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[14] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      15: begin { commandos }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[12] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      16: begin { tezky tank }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      17 : begin { vysadkovy letoun }
             if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[21] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      18 : begin { stihac }
             if ((PermittedUnits[UnitType]) and ((Race = MyRace) or (ExistUnits[18] < 1)) and
                (not Production_order or (ExistBuildings[21] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      19 : begin { terminator }
             if ((PermittedUnits[UnitType]) and ((Race = MyRace) or (ExistUnits[19] < 1)) and
                (not Production_order or (ExistBuildings[21] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      20 : begin { lehka pevnost }
             if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      21 : begin { tezka pevnost }
             if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      22 : begin { robot }
             if ((PermittedUnits[UnitType]) and
                 (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      23 : begin { autodetonator }
             if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[12] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      24 : begin { mechwarrior }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      25 : begin { lehke vznasedlo }
             if ((PermittedUnits[UnitType]) and
                 (not Production_order or (ExistBuildings[8] > 0) and
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      26 : begin { tezke vznasedlo }
             if ((PermittedUnits[UnitType]) and
                (not Production_order or
                ((ExistBuildings[2] > 0)  or (ExistBuildings[15] > 0)) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      27 : begin { tank }
             if ((PermittedUnits[UnitType]) and
                 (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
           end;
      28: begin { raketomet }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      29: begin { mutant }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      30: begin { letajici talir }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      31: begin { raketova vez }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      32: begin { SAM }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      33: begin { budova ve forme vozidla }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      34: begin { AH-66 Sioux }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      35: begin { lehky kanon }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[8] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      36: begin { antitank }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      37: begin { CHINOOK }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      38: begin { nic }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      39: begin { likvidator }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or (ExistBuildings[12] > 0) and
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      40: begin { terorista }
            if ((PermittedUnits[UnitType]) and
                (not Production_order or
                (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
            then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
      41: begin { centrum posil }
             if ((PermittedUnits[UnitType]) and
                 (not Production_order or
                 (ExistBuildings[Unit_types[UnitType,Races[Race].Ally].Parent] > 0)))
             then UnitProductionPossible:=True else UnitProductionPossible:=False;
          end;
       42: begin { gunboat }
             UnitProductionPossible:=False;
          end;
       43: begin { missile boat }
             UnitProductionPossible:=False;
           end;
       44: begin { destroyer }
             UnitProductionPossible:=False;
           end;
   else
     Error(0,'unita _races, procedura UnitProductionPossible, chybny typ jednotek');
   end;
end;

{ ***** }
function BuildingProductionPossible(Race, BuildingType:Byte):Boolean;
{ vraci True, pokud lze pri aktualni konfiguraci danou jednotku produkovat
}
begin
   with (Races[Race]) do case (BuildingType) of
      1 : begin { zakladna }
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      2 : begin { kasarna }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0) and
                  (ExistBuildings[8] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      3 : begin { lehka tovarna }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0) and
                  (ExistBuildings[4] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      4 : begin { recyklace }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      5 : begin { elektrarna }
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      6 : begin { akumulator }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0) and
                  (ExistBuildings[8] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      7 : begin { generalni stab }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0) and
                  (ExistBuildings[8] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      8 : begin { plastarna }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      9 : begin { zakladna2 }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[1] > 0) and
                  (ExistBuildings[5] > 0) and (ExistBuildings[4] > 0) and
                  (ExistBuildings[8] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      10: begin { tezka tovarna }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[9] > 0) and
                  (ExistBuildings[3] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      11: begin { letiste }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[9] > 0) and
                  (ExistBuildings[10] > 0) and (ExistBuildings[12] > 0) and
                  (ExistBuildings[21] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      12: begin { specialni tovarna }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[9] > 0) and
                  (ExistBuildings[10] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      13: begin { centrum oprav }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[9] > 0) and
                  (ExistBuildings[10] > 0) and (ExistBuildings[12] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      14: begin { obranne centrum }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[9] > 0) and
                  ((ExistBuildings[2] > 0) or (ExistBuildings[15] > 0))))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      15: begin { montazni linka }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[5] > 0) and
                  (ExistBuildings[8] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      16: begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
          end;
      17 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      18 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      19 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      20 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      21 : begin { radar }
             if ((PermittedBuildings[BuildingType]) and
                 (not Production_order or (ExistBuildings[9] > 0) and
                  (ExistBuildings[10] > 0) and (ExistBuildings[12] > 0)))
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      22 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      23 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      24 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
      25 : begin
             if (PermittedBuildings[BuildingType])
             then BuildingProductionPossible:=True else BuildingProductionPossible:=False;
           end;
   else
     Error(0,'unita _races, procedura BuildingProductionPossible, chybny typ jednotek');
   end;

end;

{ ***** }
function Get_unit_anti_weight(Race, UnitTyp, Category:Word; Class,AAClass:Byte):Single;
{ zjisti vahu jednotky v dane kategorii (napr. kategorie L znaci vahu
  ucinnosti proti lehkym cilum). Pouzitelne kategorie: L, T, AA
}
var Modifier:Single;
    AAModifier, M2:Single;

begin
 with (UnitParams[UnitTyp]) do begin
   case (Class) of
     0 : Modifier:=1;
     1 : Modifier:=DangerLimit1Coeff;
     2 : Modifier:=DangerLimit2Coeff;
   else
     Modifier:=0;
   end;
   case (AAClass) of
     0 : AAModifier:=1;
     1 : AAModifier:=DangerLimit1Coeff;
     2 : AAModifier:=DangerLimit2Coeff;
   else
     AAModifier:=0;
   end;
   case (Unit_types[UnitTyp,Races[Race].Ally].TargetTyp) of
     0 : Modifier:=Modifier*DangerLimitLLCoef;
     1 : Modifier:=Modifier*DangerLimitLCoef;
     2 : Modifier:=Modifier*DangerLimitHCoef;
     3 : Modifier:=Modifier*DangerLimitACoef;
   end;
   case (Category) of
      L : if ((TAttack > 0) and (LAttack > 0))
          then Get_unit_anti_weight:=Modifier/(TAttack/LAttack)
          else Get_unit_anti_weight:=0;
      T : if ((TAttack > 0) and (LAttack > 0))
          then Get_unit_anti_weight:=Modifier/(LAttack/TAttack)
          else Get_unit_anti_weight:=0;
      AA: Get_unit_anti_weight:=AAModifier;
   end;
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
begin
   SetTerminator_fighterParams(False);
   ActionLevel:=ActionLev;
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
             for I:= 0 to MaxRace do
               Races[I].EE_credits_plus:=Races[I].EE_credits_plus+0.1;
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
       KadenceChangeValue:=1.85;
       CostChangeValue:=1;
       UnitProdSpeedChangeValue:=1;
       BuildProdSpeedChangeValue:=1;
   end;

   for I:=0 to 10 do
     Kadence[I]:=Round(KadenceChangeValue*Kadence[I]);
   {x}
   for I:=1 to MaxTypesOfUnits do with (Unit_types[I,0]) do begin
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
     case (TerrainCondition) of
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
     end;
   end;
   {x}
   for I:=1 to MaxTypesOfUnits do with (Unit_types[I,1]) do begin
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
     case (TerrainCondition) of
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
     end;
   end;
   {x}
   for I:=1 to MaxTypesOfBuildings do with (Building_types[I]) do begin
     if (I <> 5) then Production_time:=BuildProdSpeedChangeValue*Production_time;{}
     BP:=Round(CostChangeValue*BP); PL:=Round(CostChangeValue*PL);
     {EE:=Round(CostChangeValue*EE);{} EX:=Round(CostChangeValue*EX);
     DefenceStrength:=Round((DefendChangeValue/6)*DefenceStrength*2);
   end;
end;

{ ***** }
function GetProdPrioB(ElementType,Prior:Word):Word;
{ vrati doporucenou prioritu pro budovu ElementType
}
begin
  case (ElementType) of
    1 : begin {zakladna}
          GetProdPrioB:=Prior;
        end;
    2 : begin {kasarna}
          GetProdPrioB:=Prior;
        end;
    3 : begin {lehka tovarna}
          GetProdPrioB:=Prior;
        end;
    4 : begin {recyklace}
          GetProdPrioB:=Prior;
        end;
    5 : begin {elektrarna}
          GetProdPrioB:=Prior;
        end;
    6 : begin {akumulator}
          GetProdPrioB:=Prior;
        end;
    7 : begin {generalni stab}
          GetProdPrioB:=Prior;
        end;
    8 : begin {vyroba plastu}
          GetProdPrioB:=Prior;
        end;
    9 : begin {zakladna2}
          GetProdPrioB:=Prior;
        end;
    10: begin {tezka tovarna}
          GetProdPrioB:=Prior;
        end;
    11: begin {letiste}
          GetProdPrioB:=Prior;
        end;
    12: begin {spec. tovarna}
          GetProdPrioB:=Prior;
        end;
    13: begin {centrum oprav}
          GetProdPrioB:=Prior;
        end;
    14: begin {obranne centrum}
          GetProdPrioB:=Prior;
        end;
    15: begin {montazni linka}
          GetProdPrioB:=Prior;
        end;
    21: begin {radar}
          GetProdPrioB:=Prior;
        end;
  else
  end;
end;

{ ***** }
function GetProdPrioU(Prior:Word):Word;
{ podle globalnich potreb meni zadanou prioritu Prior pro jednotky
}
begin
   GetProdPrioU:=Prior;
end;

{ ***** }
function GetBuildingPlaceRequest(BuildingType:Byte):Byte;
{ vrati request na misto budovy BuildingType
}
var Flag:Byte;
begin
   Flag:=255;
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
                     else Error(0,'unita _races, procedura GetBuildingPlaceRequest, bod 1');
   end;{ with (Building_types[BuildingType]) do begin}
   if (BuildingType = 5) then Flag:=15; { elektrarna }
   if (BuildingType = 4) then Flag:=16; { recyklace }

   GetBuildingPlaceRequest:=Flag;
end;

{ ***** }
function GetUnitPlaceRequest(UnitType:Byte):Byte;
{ vrati request na misto budovy BuildingType
}
var Flag:Byte;
begin
   Flag:=255;
   case (UnitType) of
      20 : Flag:= 7; { lehka pevnost }
      21 : Flag:= 10; { tezka pevnost }
      31 : Flag:= 10; { raketova vez }
      32 : Flag:= 7; { infra SAM }
      41 : Flag:= 17; { centrum posil }
   end;
   GetUnitPlaceRequest:=Flag;
end;

{ ***** }
procedure _races_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'14'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _races_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'14'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************* }
begin
   for J:=0 to MaxRace do with Races[J] do begin
       VisMask:=65535; DruhaPlastarnaVeVyrobe:=False;
       MaxRecyclatorNum:=0; InitUnitLevel:=0;
       BPRepair:=0; PLRepair:=0; EERepair:=0; ExpRepair:=0;
       Ally:=0; TGPlusActivity:=0;
       Forbid:=False; DefendLock:=0; PLHiNeed:=0;
       Recyclators:=0; UnpackedBuildings:=0; GSBuild:=False;
       { seznam existujicich budov dane rasy }
       for I:=1 to MaxTypesOfBuildings do ExistBuildings[I]:=0;
       { seznam celkove vyrobenych budov dane rasy }
       for I:=1 to MaxTypesOfBuildings do ProducedBuildings[I]:=0;
       { seznam existujicich jednotek dane rasy }
       for I:=1 to MaxTypesOfUnits do ExistUnits[I]:=0;
       { seznam celkove vyrobenych jednotek dane rasy }
       for I:=1 to MaxTypesOfUnits do ProducedUnits[I]:=0;
       { seznam celkove znicenych budov danou rasy }
       for I:=1 to MaxTypesOfBuildings do KilledBuildings[I]:=0;
       { seznam celkove znicenych jednotek danou rasou }
       for I:=1 to MaxTypesOfUnits do KilledUnits[I]:=0;

       _ProducedUnitsAll:=0; _InGameProducedUnits:=0;
       _ProducedBuildingsAll:=0; _InGameProducedBuildings:=0;
       _KilledUnits:=0; _KilledBuildings:=0;
       _LostBuildings:=0; _LostUnits:=0;

       for I:=1 to MaxTypesOfBuildings do PointerToBuildings[I]:=Nil;
       CentraPosil:=Nil;

       New(FreePlaces);
       if (FreePlaces = Nil) then begin
         Writeln('Chyba - nedostatek pameti');
         Halt(0);
       end;

       GndDefNeedInit:=65535; AADefNeedInit:=65535; DefInstalPriority:=5;
       DefInstalPriorityFlag:=0;

       for I:=0 to MaxFreePlaces do
        for K:=0 to MaxFreeStructures do FreePlaces^[I,K].PlaceType:=0;

      ParaEnabled:=0;
      AttackTGNum:=0; DefenceTGNum:=0; SaboteurTGNum:=0;
      TG_Reinfo_ExecuteFlag:=J shl 1;

      New(TaskGroups);
      for I:=0 to MaxRaceTaskGroups do with (RacesTGInfo^[J,I]) do begin
         TaskGroups^[I].Validity:=False; SpecialLock:=0;
         ActivityGameTime:=0;
         IHomeTaskGroupInfoPos:=65535;
         JHomeTaskGroupInfoPos:=65535;
         MaxAirPct:=100;
         AALock:=1; ALock:=1; LLock:=1; HLock:=1; CLock:=1;
      end;

      RacesTGInfo^[J,12].LeaderCourageLow:=0;
      RacesTGInfo^[J,12].LeaderCourageHigh:=1000;
      RacesTGInfo^[J,12].MoveCourageNormal:=1000;
      RacesTGInfo^[J,12].TGAtt:=2;
      RacesTGInfo^[J,12].IHomeTaskGroupInfoPos:=65535;
      RacesTGInfo^[J,12].JHomeTaskGroupInfoPos:=65535;
      FighterTimmer:=600; TerminatorTimmer:=600;
   end;
end.