unit AI3;
{$C FIXED PRELOAD PERMANENT}
interface

uses Data;

const MaxQueue = 1;
type TRepairQueue = object
                      procedure Init; { vycisteni }
                      procedure Insert(var _u:PUnit; var B:PBuilding);
                      procedure Work; { zpracovani }
                      private
                      Queue: array[0..MaxRace,0..MaxQueue] of record
                               { komponenta opravy: }
                               UnitIndex:Word; BuildingIndex:Word;
                               Priority:Single; { priorita komponenty }
                               Validity:Boolean;
                             end;
                    end;

var RepairQueue : ^TRepairQueue;

function Find_resource_for_recyklator(var IPos,JPos:Word):Boolean;
function Find_resource_for_recyklator2(var IPos,JPos:Word):Boolean;
function Find_resource_for_recyklator3(var IPos,JPos:Word):Boolean;
function HarvesterWaitLimit(IAim,JAim:Word):Word;
function Calcul_max_recykl_num(Race:Byte):Word;
function Get_task_group_carrier(Race,TaskGroupNum:Byte; var C, _unit:PUnit;
                                Cargo:Byte):PUnit;
function Find_free_place_for_landing(var IP,JP:Word; FreOk:Byte):Boolean;
procedure SetNewTGNumberForUnitsInside(_unit:PUNit; NewTG:Byte);
function Get_task_group_strength(Race,TaskGrp:Byte; EnemyGroundPct:Single):Single;
function Get_task_group_strength_without_air(Race,TaskGrp:Byte; EnemyGroundPct:Single):Single;
procedure GetMapInfo(IP,JP:Word; Friend:Boolean; Center:Boolean);
procedure RemakeDefenceTG(Race,TGNum:Byte);

implementation

uses AI,_units,_units2, _units3, _Buildings, Grafika2;

{ ***** }
procedure TRepairQueue.Init;
{ inicializace "fronty oprav"
}
var I,J:Word;
begin
  for I:=0 to MaxRace do
    for J:=0 to MaxQueue do
      Queue[I,J].Validity:=False;
end;

{ xxx }
procedure TRepairQueue.Insert(var _u:PUnit; var B:PBuilding);
{ vlozi kandidata na opravu do fronty; provede se 1x za 4 tahy
}
var PomPriority:Word;
    I:Word;
    DMG:Single;
begin
 bebex:=200;
 if (TimeSlot mod 4 = 0) then begin { 1x za 4 tahy }
   bebex:=201;
   if (_u <> Nil) then with (_u^) do begin  { jde o opravu jednotky}
     bebex:=202;
     if (DangerClass <> 255) then PomPriority:=DangerClass*15
     else PomPriority:=0;
     if (ADangerClass <> 255) then PomPriority:=PomPriority+ADangerClass*10
     else ;
     if (UnitType = 2) then Inc(PomPriority,50); { recyklator }
     {x}
     DMG:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
     DMG:=DMG/100;
     DMG:=100-(1.0*Damage)/DMG; { z kolika % je budova poskozena }
     DMG:=DMG/2;
     Inc(PomPriority,Round(DMG));
     bebex:=203;
     I:=0;
     while (I <= MaxQueue) do with (Queue[Race,I]) do begin
       bebex:=207;
       if (Validity and (PomPriority > Priority) or (not Validity)) then begin
          Validity:=True; UnitIndex:=_u^.Index; BuildingIndex:=0;
          Priority:=PomPriority; I:=MaxQueue+1;
       end;
       Inc(I);
     end;
   end else
     if (B <> Nil) then with (B^) do begin { jde o opravu budovy}
        bebex:=204;
        PomPriority:=GetBuildingWeight(BuildingType);
        if (BuildingType = 5) then Inc(PomPriority,30); { elektrarna }
        DMG:=Building_types[BuildingType].DefenceStrength; DMG:=DMG/100;
        DMG:=100-(1.0*Damage)/DMG; { z kolika % je budova poskozena }
        DMG:=DMG/2;
        Inc(PomPriority,Round(DMG));
        {xxx}
        bebex:=205;
        I:=0;
        while (I <= MaxQueue) do with (Queue[Race,I]) do begin
          bebex:=206;
          if (Validity and (PomPriority > Priority) or (not Validity)) then begin
             Validity:=True; UnitIndex:=0; BuildingIndex:=B^.Index;
             Priority:=PomPriority; I:=MaxQueue+1;
          end;
          Inc(I);
        end;
     end;
 end;
end;

{ xxx }
procedure TRepairQueue.Work;
{
}
label Skip;
var Race,I,J,K,L:Word;
    Delta,PomDelta:Word;
    Konec:Boolean;
    B,P,E,X:Single;
    _unit:PUnit;
    Building:PBuilding;
begin
  bebex:=300;
  for Race:=0 to MaxRace do begin
    if (Race <> MyRace) then SetTerminator_fighterParams(True);
    bebey:=Race;
    for I:=0 to MaxQueue do with (Queue[Race,I]) do with (Races[Race]) do
    if (Validity) then begin
       if (UnitIndex <> 0) then _unit:=Units[UnitIndex] else _unit:=Nil;
       if (BuildingIndex <> 0) then Building:=Buildings[BuildingIndex] else Building:=Nil;
       bebex:=301;
       Konec:=False;
       Validity:=False;
       if ((Building <> Nil) and
           (Building_types[Building^.BuildingType].ProductionType = 0))
       then begin
       { budova pro produkci jednotek }
          bebex:=302;
          { nejprve nalezneme nejblizsi vhodnou oblast pro stavbu }
          if (ActualFreeStructures = 0) then
          else begin
            bebex:=303;
            K:=0; Delta:=65535;
            for L:=0 to (ActualFreeStructures-1) do with (FreePlaces^[0,L]) do begin
              bebex:=304;
              PomDelta:=abs((Integer(X)-Building^.IPos)+
                            (Integer(Y)-Building^.JPos));
              if (PomDelta < Delta) then begin
                 Delta:=PomDelta; K:=L;
              end;{}
            end;
            bebex:=305;
            { nalezen seznam s nejblizsi polohou (promenna J) }
            if (FreePlaces^[0,K].PlaceType = 80) then begin
               Konec:=True;  { na zakladnu se utoci a jde o budovu pro
                               produkci jednotek - neopravuj }
            end;
          end; { if (ActualFreeStructures = 0) then ... else ... }
       end;
       bebex:=306;
       if (_unit <> Nil) then with (_unit^) do begin
          bebex:=307;
          bebey:=UnitType;
          if (Destroyed) then save1:=0 else save1:=1;
          save2:=Race;
          B:=RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].BP)/100);
          bebex:=317;
          P:=RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].PL)/100);
          bebex:=318;
          E:=RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].EE)/100);
          bebex:=319;
          X:=RepairCost*((1.0*Unit_types[UnitType,Races[Race].Ally].Ex)/100);
          bebex:=320;
       end else
         if (Building <> Nil) then with (Building^) do begin
            bebex:=308;
            B:=RepairCost*((1.0*Building_types[BuildingType].BP)/100);
            P:=RepairCost*((1.0*Building_types[BuildingType].PL)/100);
            E:=RepairCost*((1.0*Building_types[BuildingType].EE)/100);
            X:=RepairCost*((1.0*Building_types[BuildingType].Ex)/100);
         end;

       bebex:=309;
       { nyni zajistime setreni materialem }
       if ((((Building_credits - BPRepair - B) < 50) or
            ((Plastic_credits - PLRepair - P) < 10) or
            ((Electric_energy - EERepair - E) < 20) or
            ((Battle_experience - ExpRepair - X) < 2)) and
           (Priority < 150))
       then Konec:=True;
       bebex:=310;
       if (not Konec) then RepairEnemy(Race,Building,_unit);
       bebex:=311;
Skip:
    end;
  end;
  SetTerminator_fighterParams(False);
end;

{ ***** }
function Find_resource_for_recyklator(var IPos,JPos:Word):Boolean;
{ najde pro recyklator vhodny zdroj; vraci True, pokud se operace zdarila,
  jinak False; v pripade uspechu vraci v IPos,JPos pozici zdroje
}
var Result:Boolean;
    I,J, IPom, JPom:Word;
begin
   Result:=False; IPom:=MaxInt; JPom:=MaxInt;
   if (LastUsedResource <= MaxResourceIndex) then begin
     for I:=0 to LastUsedResource do with ResourceInfo[I] do begin
        if (Resource > 0) then begin
        { nejaky zdroj tam je }
           if ((abs(Integer(IPom) - IPos) + abs(Integer(JPom) - JPos)) >
               (abs(Integer(IResourPos) - IPos) + abs(Integer(JResourPos) - JPos))) then begin
              IPom:=IResourPos; JPom:=JResourPos;
              Result:=True;
           end;
        end;
     end;
   end;
   if (Result) then begin IPos:=IPom; JPos:=JPom; end;
   Find_resource_for_recyklator:=Result;
end;

{ ***** }
function Find_resource_for_recyklator2(var IPos,JPos:Word):Boolean;
{ najde pro recyklator vhodny zdroj; vraci True, pokud se operace zdarila,
  jinak False; v pripade uspechu vraci v IPos,JPos pozici zdroje;
  - rozdil od Find_resource_for_recyklator:
  ! Prohledava se misto 5 policek okolo IPos,JPos na VOLNY zdroj,t.j.
  bez pritomnosti jakekoliv jednotky !
}
var Result:Boolean;
    I,J, IPom, JPom,I2,J2:Word;
    Konec:Boolean;
begin
   Result:=False; IPom:=MaxInt; JPom:=MaxInt; I2:=IPos; J2:=JPos;
   if (I2 >= 4) then Dec(I2,4) else I2:=0;
   if (J2 >= 4) then Dec(J2,4) else J2:=0;
   I:=0; Konec:=False;

   while ((LastUsedResource <= MaxResourceIndex) and (I <= LastUsedResource) and
          (not Konec)) do with ResourceInfo[I] do begin
      if (Resource > 0) then with (Map^[IResourPos,JResourPos]) do begin
      { nejaky zdroj tam je }
         if ((First_level = 0) and
             (IResourPos >= I2) and (IResourPos <= (I2+8)) and
             (JResourPos >= J2) and (JResourPos <= (J2+8)))
         then begin
         { a navic volny ! }
            if ((abs(Integer(IPom) - IPos) + abs(Integer(JPom) - JPos)) >
                (abs(Integer(IResourPos) - IPos) + abs(Integer(JResourPos) - JPos)))
            then begin
               Result:=True; Konec:=True; IPom:=IResourPos; JPom:=JResourPos;
            end;
         end;
      end;
      Inc(I);
   end;
   if (Result) then begin IPos:=IPom; JPos:=JPom; end;
   Find_resource_for_recyklator2:=Result;
end;

{ ***** }
function Find_resource_for_recyklator3(var IPos,JPos:Word):Boolean;
{ najde pro recyklator z pozice IPos,JPos vhodny zdroj; vraci True, pokud se
  operace zdarila, jinak False; v pripade uspechu vraci v IPos,JPos pozici
  zdroje; na rozdil od Find_resource_for_recyklator testuje, zda je policko
  ZCELA volne
}
var Result:Boolean;
    I,J, IPom, JPom:Word;
begin
   Result:=False; IPom:=MaxInt; JPom:=MaxInt;
   if (LastUsedResource <= MaxResourceIndex) then
      for I:=0 to LastUsedResource do with ResourceInfo[I] do begin
         if (Resource > 0) then with (Map^[IResourPos,JResourPos]) do begin
         { nejaky zdroj tam je }
            if (First_level = 0) then
            { volno nebo recyklator }
              if ((abs(Integer(IPom) - IPos) + abs(Integer(JPom) - JPos)) >
                  (abs(Integer(IResourPos) - IPos) + abs(Integer(JResourPos) - JPos)))
              then begin
                 IPom:=IResourPos; JPom:=JResourPos;
                 Result:=True;
              end;
         end;
      end;
   if (Result) then begin IPos:=IPom; JPos:=JPom; end;
   Find_resource_for_recyklator3:=Result;
end;

{ ***** }
function HarvesterWaitLimit(IAim,JAim:Word):Word;
{ harvester je zacilen na pozici IAim, JAim; vypocita se nejblizsi volny
  zdroj a jeho vzdalenost od IAim, JAim; dle toho se nastavi doba cekani;
  v podstate jde o to, zda se vyplati u blokovaneho zdroje cekat na odjezd
  teziciho harvesteru,nebo prejet na nejblizsi volny zdroj
}
var IPom, JPom, Distance, Pom:Word;
begin
   IPom:=IAim; JPom:=JAim;
   if (Find_resource_for_recyklator3(IPom,JPom)) then begin
   { nalezen nejblizsi zdroj }
     Distance:=GetDistance(IAim,JAim,IPom,JPom);
     with (Unit_types[2,1]) do begin { recyklator }
       Pom:=16; { delka prejeti 1 pole recyklatorem - !! nekorektni!!
                  odpovida rychlosti 3
                }
       Distance:=Distance*Pom; { narocnost cesty ke 2. zdroji }
       if (Distance > (HarvestingSpeed*100)) then
         Distance:=Round(HarvestingSpeed*100); { umele omezeni cekani }
     end;
   end else Distance:=65000; { neexistuje zadna alternativa }

   HarvesterWaitLimit:=Distance;
end;

{ ***** }
function Calcul_max_recykl_num(Race:Byte):Word;
{ vypocita maximalni optimalni pocet recyklatoru pro danou rasu na
  zaklade poctu a mocnosti zdroju, jejich vzdalenosti
}
const MaxRecyclators = 6; { maximalni pocet soucasne existujicich
      jednotek-recyklatoru; pozadavky na vyrobu dalsich se budou rusit }
var I,J:Word;
    PomDistance, Distance, MinDistance:Word;
    PomValue, Value, Weight, Num:Single;
begin
  Calcul_max_recykl_num:=Races[Race].MaxRecyclatorNum;
  if (Races[Race].MaxRecyclatorNum = 0) then begin
     Value:=0; Num:=0;
     with (Races[Race]) do begin
       if ((LastUsedResource <= MaxResourceIndex) and (ActualFreeStructures > 0))
       then begin
         for I:=0 to LastUsedResource do with ResourceInfo[I] do
           if (Resource > 0) then begin
           { nejaky zdroj zde je }
              Distance:=65535; MinDistance:=65535;
              { vypocitame nejkratsi vzdalenost od stredu nejake zakladny rasy }
              for J:=0 to (ActualFreeStructures-1) do begin
                 PomDistance:=GetDistance(IResourPos,JResourPos,FreePlaces^[0,J].X,FreePlaces^[0,J].Y);
                 if (Distance > PomDistance) then Distance:=PomDistance;
              end;
              { nyni "znehodnotime" dane misto dle vyskytu nepratel }
              Weight:=1;
              with (MapInfo^[IResourPos div IInfoDiv,JResourPos div JInfoDiv]) do begin
                 if ((Friend[MyRace] = 2) and (not Neutral)) then begin
                    Weight:=Weight - 0.2*FriendlyBuildingsNum;{ budovy }
                    Weight:=Weight - 0.2*(HSpecial+VSpecial); { recyklatory }
                 end else
                   if ((Friend[MyRace] = 0) and (not Neutral)) then begin
                      { budovy }
                      Weight:=Weight - 0.2*(EnemyVBuildingsNum+EnemyHBuildingsNum);
                      { recyklatory a slozene budovy }
                      Weight:=Weight - 0.2*(EnemyHSpecial+EnemyVSpecial);
                   end;
              end;
              Distance:=Distance div IInfoDiv;
              if (MinDistance > Distance) then MinDistance:=Distance;
              if (Distance > 0) then Dec(Distance);
              Weight:=Weight - 0.2*Distance;
              if (Weight < 0) then Weight:=0;
              { Weight se pohybuje mezi 0 a 1 a urcuje vyuzitelnost zdroje
                pro ucely rasy (1 = maximalni vyuzitelnost, 0 = nepouzitelny) }

              PomValue:=Resource;
              PomValue:=PomValue / Unit_types[2,Races[Race].Ally].BP;
              { PomValue udava, kolik recyklatoru lze vyrobit z tohoto zdroje }
              Value:=Value+PomValue*Weight;
              Num:=Num+Weight; { Num udava pocet pouzitelnych zdroju }
           end;
           { aby se zdroj vyplatil, musi zaplatit recyklator + minimalne cena
             dvou nahoru, t.j. je treba delit tremi }
           if (Value/3 < Num) then Num:=Value/3;

           { pokud je nejblizsi zdroj daleko, je treba k jeho "cerpani" vice
             recyklatoru, nebot cesta je dlouha => pripocist kladny bonus
             pro vetsi vzdalenost }
           Num:=Num + 0.15*MinDistance;

           if (Num > MaxRecyclators) then Num:=MaxRecyclators;
           Calcul_max_recykl_num:=Round(Num);
       end else Calcul_max_recykl_num:=0;
     end;{}
  end;
end;

{ ***** }
function Get_task_group_carrier(Race,TaskGroupNum:Byte; var C, _unit:PUnit;
                                Cargo:Byte):PUnit;
{ funkce zkusi nalezt v taskgrupe takove nakladni vozidlo, ktere
  je nejbliz jednotce _unit a vleze se do nej minimalne naklad Cargo;
  pri hledani se VYNECHA jednotka "C"
}
var Pom,Result:PUnit;
    PomDistance,Distance:Word;
    Pomocna:Word;
begin
 with (Races[Race]) do begin
   if (TaskGroups^[TaskGroupNum].Validity) then
   with (TaskGroups^[TaskGroupNum]) do begin
      Result:=Nil; Distance:=65535;
      Pom:=Carriers;
      while (Pom <> Nil) do begin
        { zjisti naroky jednotek na misto }
        Pomocna:=Cargo;
        if ((C <> Nil) and (Pom = Units[C^.Index])) then Inc(Pomocna,255);
        if (not Pom^.Activity) then Inc(Pomocna,255);
        {Inc(Pomocna,Unit_types[_unit^.UnitType,Races[Race].Ally].NeedPlace);{}
        if ((Unit_types[Pom^.UnitType,Races[Race].Ally].UnitLevel = 3) and
            (Unit_types[Pom^.UnitType,Races[Race].Ally].SpecAirLevel = 0) and
            (_unit^.UnitType <> 7) and (_unit^.UnitType <> 9) and
            (_unit^.UnitType <> 15))
        then Inc(Pomocna,255); { do vysadkovych letadel lze nalozit jen
        vysadkare - u ostatnich jednotek umele zvys jejich naroky na
        misto a tak zabran nalozeni }
        if ((Unit_types[Pom^.UnitType,Races[Race].Ally].TargetTyp < 3) and
            (_unit^.TargetType > 1))
        then Inc(Pomocna,255);
        { do pozemnich vozidel nelze nalozit tezkou jednotku }
        if (((Pomocna+Pom^.UnitsInsidePlace) <= Unit_types[Pom^.UnitType,Races[Race].Ally].Capacity) and
             (Pom^.UnitsInsideNum < 9)) then begin
        { vhodne vozidlo - zkus porovnat s nejlepsi zatim nalezenym }
           if (Result = Nil) then begin
           { zatim nic nenalezeno }
             Result:=Pom;
             Distance:=GetDistance(_unit^.IPos,_unit^.JPos,Pom^.IPos,Pom^.JPos);{}
           end else begin
             PomDistance:=GetDistance(_unit^.IPos,_unit^.JPos,Pom^.IPos,Pom^.JPos);{}
             if (PomDistance < Distance) then begin
             { nalezena vyhodnejsi jednotka }
                Distance:=PomDistance;
                Result:=Pom;
             end;
           end;
        end;

        Pom:=Pom^.Next;
      end; { while (Pom <> Nil) do begin }
   end;  { with (TaskGroups[TaskGroupNum]) do begin }
 end; { with (Races[Race]) do begin }

 if (Result = Nil) then Get_task_group_carrier:=Nil
 else Get_task_group_carrier:=Units[Result^.Index];
end;

{ ***** }
function Find_free_place_for_landing(var IP,JP:Word; FreOk:Byte):Boolean;
{ snazi se najit v okoli IP,JP nejblizsi misto pro pristani; vybira flek
  s co nejvetsim poctem volnych mist okolo, dostacujici je vsak i hodnota
  FreOk.
}
const SearchRange = 3;
var I,J:Integer;
    Found:Boolean;
    Ix, Jx:Word;
    FreePlaces,Pom : Byte;
begin
   with (Map^[IP,JP]) do
   if ((First_level = 0) and
       (BelowEqual(MapBck^[IP,JP].BckType,Field) or
        BelowEqual(MapBck^[IP,JP].BckType,Hill) and
        Above(MapBck^[IP,JP].BckType,Resrc))) then begin
     Found:=True; Ix:=IP; Jx:=JP;
     FreePlaces:=Check_place_surroundings_free(IP,JP,1,1,24);
   end else begin
     Found:=False; Ix:=65535; Jx:=65535; FreePlaces:=0;
   end;
   for J:=Integer(JP)-SearchRange to JP+SearchRange do
     for I:=Integer(IP)-SearchRange to IP+SearchRange do
     if ((I >= 0) and  (J >= 0) and (I <= IMax) and (J <= JMax)) then begin
        if ((Map^[I,J].First_level = 0) and (Map^[I,J].Second_level = 0) and
            (BelowEqual(MapBck^[I,J].BckType,Field) or
             BelowEqual(MapBck^[I,J].BckType,Hill) and
             Above(MapBck^[I,J].BckType,Resrc)))
        then begin
           Found:=True;
           { otestujeme volne misto vuci typu 24 - mechwarrior }
           Pom:=Check_place_surroundings_free(Word(I),Word(J),1,1,24);
           if ((Pom > FreePlaces) and (FreePlaces < FreOk) or
               ((Pom = FreePlaces) or (FreOk <= Pom)) and
                (GetDistance(I,J,IP,JP) < GetDistance(Ix,Jx,IP,JP)))
           then begin Ix:=I; Jx:=J; FreePlaces:=Pom; end;
        end;
     end;
   if ((FreePlaces = 0) or (Ix = 65535) or (Jx = 65535)) then Found:=False;
   Find_free_place_for_landing:=Found; IP:=Ix; JP:=Jx;
end;

{ ***** }
procedure SetNewTGNumberForUnitsInside(_unit:PUNit; NewTG:Byte);
{ pro vsechny nalozene jednotky v carrieru _unit nastavi nove cislo materske
  taskgrupy NewTG
}
var I:Word;
begin
  with (_unit^) do begin
    for I:=0 to (MaxGroupUnits-2) do
      if ((UnitsInside[I] <> 0) and (Units[UnitsInside[I]] <> Nil)) then
      with (Units[UnitsInside[I]]^) do begin
         TaskGroup:=NewTG;
      end;
  end;
end;

{ ***** }
function Get_task_group_strength(Race,TaskGrp:Byte; EnemyGroundPct:Single):Single;
{ vrati zjednodusene vypocitanou silu taskgrupy;
  EnemyGroundPct vraci procentuelni zastoupeni nepratelskych pozemnich
  jednotek na celkove sile
}
var Pom,Pom2,Pom3:Single;
begin
  with (Races[Race]) do with (TaskGroups^[TaskGrp]) do begin
    Pom:=0;
    { nyni vypocet sily vlastni TG }
    Pom3:=0; Pom:=0;
    Pom3:=Pom3+LLightTG[0]; Pom2:=LLightTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=LLightTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitLLCoef; Pom3:=0;
    {}
    Pom3:=Pom3+LightTG[0]; Pom2:=LightTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=LightTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitLCoef; Pom3:=0;
    {}
    Pom3:=Pom3+HeavyTG[0]; Pom2:=HeavyTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=HeavyTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitHCoef; Pom3:=0;
    {}
    Pom3:=Pom3+AirTG[0]; Pom2:=AirTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=AirTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitACoef; Pom3:=0;
    { nyni vypocet AA sily: }
    Pom3:=0;
    Pom3:=Pom3+AAttackTG[0]; Pom2:=AAttackTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=AAttackTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom2:=Pom3*DangerLimitAACoef;
    { Pom = pozemni sila; Pom2 = PVO sila }

    Pom2:=Pom2*((100-EnemyGroundPct) / 100);
    Pom:=Pom*(EnemyGroundPct / 100);

    Get_task_group_strength:=Pom+Pom2;
  end;
end;

{ ***** }
function Get_task_group_strength_without_air(Race,TaskGrp:Byte; EnemyGroundPct:Single):Single;
{ vrati zjednodusene vypocitanou silu taskgrupy;
  EnemyGroundPct vraci procentuelni zastoupeni nepratelskych pozemnich
  jednotek na celkove sile
}
var Pom,Pom2,Pom3:Single;
begin
  with (Races[Race]) do with (TaskGroups^[TaskGrp]) do begin
    Pom:=0;
    { nyni vypocet sily vlastni TG }
    Pom3:=0; Pom:=0;
    Pom3:=Pom3+LLightTG[0]; Pom2:=LLightTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=LLightTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitLLCoef; Pom3:=0;
    {}
    Pom3:=Pom3+LightTG[0]; Pom2:=LightTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=LightTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitLCoef; Pom3:=0;
    {}
    Pom3:=Pom3+HeavyTG[0]; Pom2:=HeavyTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=HeavyTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom:=Pom+Pom3*DangerLimitHCoef; Pom3:=0;
    { nyni vypocet AA sily: }
    Pom3:=0;
    Pom3:=Pom3+AAttackTG[0]; Pom2:=AAttackTG[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
    Pom2:=AAttackTG[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
    Pom2:=Pom3*DangerLimitAACoef;
    { Pom = pozemni sila; Pom2 = PVO sila }

    Pom2:=Pom2*((100-EnemyGroundPct) / 100);
    Pom:=Pom*(EnemyGroundPct / 100);

    Get_task_group_strength_without_air:=Pom+Pom2;
  end;
end;


{ * pomocna procedura * }
procedure GetMapInfo(IP,JP:Word; Friend:Boolean; Center:Boolean);
{ vrati komplexni vahu z pozice IP,JP pole MapInfo
  Friend = True, je-li to muj spojenec
  Center = True, pokus jde o stred (plni se pole GlobalInfo[0]);
         = False, pokud se pocita okoli
}
var Pom,Pom2,Pom3:Single;
    Index:Word;
begin
   { ***** }
   if (Center) then Index:=0 else Index:=1;
   Pom:=0;
   with (MapInfo^[IP,JP]) do begin
     if (Friend) then begin
     { spojenecka taskgrupa }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3+VLLight[0]; Pom2:=VLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=VLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Inc(GlobalInfo[Index].EnemyLLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+VLight[0]; Pom2:=VLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=VLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Inc(GlobalInfo[Index].EnemyLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+VHeavy[0]; Pom2:=VHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=VHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Inc(GlobalInfo[Index].EnemyHeavy,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+VAir[0]; Pom2:=VAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=VAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Inc(GlobalInfo[Index].EnemyAir,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+HLLight[0]; Pom2:=HLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=HLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Inc(GlobalInfo[Index].EnemyLLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+HLight[0]; Pom2:=HLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=HLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Inc(GlobalInfo[Index].EnemyLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+HHeavy[0]; Pom2:=HHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=HHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Inc(GlobalInfo[Index].EnemyHeavy,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+HAir[0]; Pom2:=HAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=HAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Inc(GlobalInfo[Index].EnemyAir,Round(Pom3));
           Pom3:=0;

           with (GlobalInfo[Index]) do begin
             EnemyGroundStrength:=EnemyGroundStrength+Pom;
             EnemyAirCount:=EnemyAirCount+VAir[0]+VAir[1]+VAir[2]+HAir[0]+HAir[1]+HAir[2];
             EnemyGroundCount:=EnemyGroundCount+
                               VLLight[0]+VLLight[1]+VLLight[2]+
                               HLLight[0]+HLLight[1]+HLLight[2]+
                               VLight[0]+VLight[1]+VLight[2]+
                               HLight[0]+HLight[1]+HLight[2]+
                               VHeavy[0]+VHeavy[1]+VHeavy[2]+
                               HHeavy[0]+HHeavy[1]+HHeavy[2];
             if ((EnemyGroundCount <> 0) or (EnemyAirCount <> 0)) then Inc(GlobalInfoCount);
             EnemyBuildings:=EnemyBuildings+FriendlyBuildingsWeight;
             FriendlyBuildings:=FriendlyBuildings+EnemyVBuildingsWeight+EnemyHBuildingsWeight;
             EnemySpecial:=EnemySpecial+VSpecial+HSpecial;
           end;
           { XXX }
           { XXX nyni nacist jednotky "sve strany" XXX }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3-EnemyVLLight[0]; Pom2:=-EnemyVLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyVLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyVLight[0]; Pom2:=-EnemyVLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyVLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyVHeavy[0]; Pom2:=-EnemyVHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyVHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyVAir[0]; Pom2:=-EnemyVAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyVAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyHLLight[0]; Pom2:=-EnemyHLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyHLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyHLight[0]; Pom2:=-EnemyHLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyHLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyHHeavy[0]; Pom2:=-EnemyHHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyHHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyHAir[0]; Pom2:=-EnemyHAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyHAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Pom3:=0;
           with (GlobalInfo[Index]) do begin
             FriendlyGroundStrength:=FriendlyGroundStrength-Pom;
             FriendlyAirCount:=FriendlyAirCount+EnemyVAir[0]+EnemyVAir[1]+EnemyVAir[2]+EnemyHAir[0]+EnemyHAir[1]+EnemyHAir[2];
             FriendlyGroundCount:=FriendlyGroundCount+
                               EnemyVLLight[0]+EnemyVLLight[1]+EnemyVLLight[2]+
                               EnemyHLLight[0]+EnemyHLLight[1]+EnemyHLLight[2]+
                               EnemyVLight[0]+EnemyVLight[1]+EnemyVLight[2]+
                               EnemyHLight[0]+EnemyHLight[1]+EnemyHLight[2]+
                               EnemyVHeavy[0]+EnemyVHeavy[1]+EnemyVHeavy[2]+
                               EnemyHHeavy[0]+EnemyHHeavy[1]+EnemyHHeavy[2];
           end;
           { XXX AIR XXX }
           { * }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3+VAAttack[0]; Pom2:=VAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=VAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Inc(GlobalInfo[Index].EnemyAAttack,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+HAAttack[0]; Pom2:=HAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=HAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Inc(GlobalInfo[Index].EnemyAAttack,Round(Pom3));
           Pom3:=0;
           with (GlobalInfo[Index]) do begin
             EnemyAirStrength:=EnemyAirStrength+Pom;
           end;
           { XXX }
           { XXX nyni nacist jednotky "sve strany" XXX }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3-EnemyVAAttack[0]; Pom2:=-EnemyVAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyVAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Pom3:=0;
           { * }
           Pom3:=Pom3-EnemyHAAttack[0]; Pom2:=-EnemyHAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-EnemyHAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Pom3:=0;
           with (GlobalInfo[Index]) do begin
             FriendlyAirStrength:=FriendlyAirStrength-Pom;
           end;
     end else begin
     { jedna se o nepratelskou taskgrupu }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3+EnemyVLLight[0]; Pom2:=EnemyVLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyVLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Inc(GlobalInfo[Index].EnemyLLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyVLight[0]; Pom2:=EnemyVLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyVLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Inc(GlobalInfo[Index].EnemyLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyVHeavy[0]; Pom2:=EnemyVHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyVHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Inc(GlobalInfo[Index].EnemyHeavy,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=0;
           Pom3:=Pom3+EnemyVAir[0]; Pom2:=EnemyVAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyVAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Inc(GlobalInfo[Index].EnemyAir,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyHLLight[0]; Pom2:=EnemyHLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyHLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Inc(GlobalInfo[Index].EnemyLLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyHLight[0]; Pom2:=EnemyHLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyHLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Inc(GlobalInfo[Index].EnemyLight,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyHHeavy[0]; Pom2:=EnemyHHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyHHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Inc(GlobalInfo[Index].EnemyHeavy,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyHAir[0]; Pom2:=EnemyHAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyHAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Inc(GlobalInfo[Index].EnemyAir,Round(Pom3));
           Pom3:=0;
           with (GlobalInfo[Index]) do begin
             EnemyGroundStrength:=EnemyGroundStrength+Pom;
             EnemyAirCount:=EnemyAirCount+EnemyVAir[0]+EnemyVAir[1]+EnemyVAir[2]+EnemyHAir[0]+EnemyHAir[1]+EnemyHAir[2];
             EnemyGroundCount:=EnemyGroundCount+
                               EnemyVLLight[0]+EnemyVLLight[1]+EnemyVLLight[2]+
                               EnemyHLLight[0]+EnemyHLLight[1]+EnemyHLLight[2]+
                               EnemyVLight[0]+EnemyVLight[1]+EnemyVLight[2]+
                               EnemyHLight[0]+EnemyHLight[1]+EnemyHLight[2]+
                               EnemyVHeavy[0]+EnemyVHeavy[1]+EnemyVHeavy[2]+
                               EnemyHHeavy[0]+EnemyHHeavy[1]+EnemyHHeavy[2];
             if ((EnemyGroundCount <> 0) or (EnemyAirCount <> 0)) then Inc(GlobalInfoCount);
             EnemyBuildings:=EnemyBuildings+EnemyVBuildingsWeight+EnemyHBuildingsWeight;
             FriendlyBuildings:=FriendlyBuildings+FriendlyBuildingsWeight;
             EnemySpecial:=EnemySpecial+EnemyVSpecial+EnemyHSpecial;
           end;
           { XXX }
           { XXX nyni nacist jednotky "sve strany" XXX }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3-VLLight[0]; Pom2:=-VLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-VLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-VLight[0]; Pom2:=-VLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-VLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-VHeavy[0]; Pom2:=-VHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-VHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-VAir[0]; Pom2:=-VAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-VAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Pom3:=0;
           { * }
           Pom3:=Pom3-HLLight[0]; Pom2:=-HLLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-HLLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-HLight[0]; Pom2:=-HLight[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-HLight[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitLCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-HHeavy[0]; Pom2:=-HHeavy[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-HHeavy[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitHCoef; Pom3:=0;
           { * }
           Pom3:=Pom3-HAir[0]; Pom2:=-HAir[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-HAir[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
           Pom:=Pom+Pom3*DangerLimitACoef; Pom3:=0;
           with (GlobalInfo[Index]) do begin
             FriendlyGroundStrength:=FriendlyGroundStrength-Pom;
             FriendlyAirCount:=FriendlyAirCount+VAir[0]+VAir[1]+VAir[2]+HAir[0]+HAir[1]+HAir[2];
             FriendlyGroundCount:=FriendlyGroundCount+
                               VLLight[0]+VLLight[1]+VLLight[2]+
                               HLLight[0]+HLLight[1]+HLLight[2]+
                               VLight[0]+VLight[1]+VLight[2]+
                               HLight[0]+HLight[1]+HLight[2]+
                               VHeavy[0]+VHeavy[1]+VHeavy[2]+
                               HHeavy[0]+HHeavy[1]+HHeavy[2];
           end;
           { XXX }
           { XXX AIR XXX }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3+EnemyVAAttack[0]; Pom2:=EnemyVAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyVAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Inc(GlobalInfo[Index].EnemyAAttack,Round(Pom3));
           Pom3:=0;
           { * }
           Pom3:=Pom3+EnemyHAAttack[0]; Pom2:=EnemyHAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=EnemyHAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef;  Inc(GlobalInfo[Index].EnemyAAttack,Round(Pom3));
           Pom3:=0;
           with (GlobalInfo[Index]) do begin
             EnemyAirStrength:=EnemyAirStrength+Pom;
           end;
           { XXX }
           { XXX nyni nacist jednotky "sve strany" XXX }
           Pom:=0; Pom3:=0;
           Pom3:=Pom3-VAAttack[0]; Pom2:=-VAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-VAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Pom3:=0;
           { * }
           Pom3:=Pom3-HAAttack[0]; Pom2:=-HAAttack[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
           Pom2:=-HAAttack[2]; Pom3:=Pom3+(Pom2*(DangerLimit2Coeff+0.5));{}
           Pom:=Pom+Pom3*DangerLimitAACoef; Pom3:=0;
           with (GlobalInfo[Index]) do begin
             FriendlyAirStrength:=FriendlyAirStrength-Pom;
           end;
     end;
   end;
end;

{ ****** }
procedure RemakeDefenceTG(Race,TGNum:Byte);
{ reorganizuje obrannou TG }
var Result, Pom2:Single;
begin
  with (Races[Race]) do with (TaskGroups^[TGNum]) do begin
    if (Ally = 0) then Pom2:=GlobalFriendGroundPct else Pom2:=GlobalCompGroundPct;
    Result:=Get_task_group_strength(Race,TGNum,Pom2);

    Result:=Result;
    if (Result >= RacesTGInfo^[Race,TGNum].TGMinLimit) then begin
    { obranna TG je predimenzovana }
      TaskGroupCommand(Race,TGNum,RemakeCom,0,10,0,0,0);
    end;
  end;
end;


{ ************************************************************************** }
begin
   New(RepairQueue);
   if (RepairQueue = Nil) then begin
     Writeln('Chyba - nedostatek pameti');
     Halt(0);
   end;
   RepairQueue^.Init;
end.