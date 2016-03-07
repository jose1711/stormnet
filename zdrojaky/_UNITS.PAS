unit _Units;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, _Shot;

function New_unit(IPosic, JPosic:Word; UnitTyp,Rac:Byte; ExperiencLevel,Kill: Byte;
                  Visibilit:Boolean; Send:Boolean; BuildType:Byte):Word;
procedure Disband_unit(var _unit:PUnit; Era : Boolean; Destruct : Boolean);
procedure Disband_units;
procedure Prepare_disband_unit(_unit:PUnit);
function Above(Index,TerrainType:Word):Boolean;
function BelowEqual(Index,TerrainType:Word):Boolean;
function Free_place(I, J, ISize, JSize:Word; _unit:PUnit):Boolean;
function Free_place_two(I, J, ISize, JSize:Word; UnitType:Byte):Boolean;
function Free_place_three(I, J, ISize, JSize:Word; Levl:Byte; _unit:PUnit):Boolean;
function Free_place_three2(I, J, ISize, JSize:Word; Levl:Byte; _unit:PUnit):Boolean;
function Free_place3(I, J, ISize, JSize:Word; _unit:PUnit):Boolean;
procedure Move_unit(var _unit:PUnit);
procedure Turn_unit(_unit:PUnit);
function Move(IThis,JThis,ITar,JTar : Word; Direction : Byte;
              var _unit:PUnit; var Distance:Word):Boolean;
procedure _units_save;
procedure _units_load;

implementation

uses Mouse, Buttons, Grafika2, Grafika3, _units2, _units3, _units4, _races, AI;
const TopUk = 1;
      AttackDepth = 2;
var WeightMoveDir : Word;
    ITarg, JTarg, XUnSize, YUnSize : Word;
    Obstacle:Boolean; { prekazka na ceste }
    Ban1, Ban2, Ban3 : Byte; { pripadne zakazane smery }
    Place : array[1..128] of Word;
    FreePlace2 : array[1..128] of Boolean;
    IAdd, JAdd : Word;
    Dir : array[1..128] of Byte;
    I,J:Word;
    RealDistance:Word;

{ ************************************************************************** }

function New_unit(IPosic, JPosic:Word; UnitTyp,Rac:Byte; ExperiencLevel,Kill:Byte;
                   Visibilit:Boolean; Send:Boolean; BuildType:Byte):Word;
{ vytvori novou jednotku rasy Rac a typu UnitType na pozici IPosic, JPosic a
  ulozi jeji ukazatel do pole Units; Visibilit urcuje, zda je jednotka videt
  nebo ne;
  sama fce pak vraci index do pole Units nove vytvorene jednotky
  Send = True ...  jednotka se NEUMISTI do mapy s pomoci SetPlace
       = False ... jednotka se posadi do mapy s pomoci SetPlace
  pro UnitType = 33, 255 BuildingType udava typ budovy
  pozn. 33 .. jedna se o slozenou budovu
        255 .. jedna se o slozenou jednotku (raketova vez ...)
}
var I, J, Limit:Word;
    UnitTyp2:Byte;
    PomClass:Byte;
    PUk, PUkFather:PUnit;
begin
  if (Number_of_units = MaxUnits) then Error(0,'prekrocen max. pocet jednotek ve hre')
  else begin
  { nejprve vyhledame volny slot }
     I:=Rac*MaxRaceUnits+1; Limit:=I+MaxRaceUnits;
     while ((Units[I] <> Nil) and (I < Limit)) do Inc(I);
     if (I = Limit) then Error(0,'prekrocen max. pocet jednotek daneho hrace');
     { volny slot nalezen }
     Races[Rac].HelpRace:=False;
     UnitTyp2:=UnitTyp;
     if (UnitTyp = 255) then New(Units[I])
     else New(Units[I]);
     if (Units[I] = Nil) then Error(0, 'chyba pri alokaci konvencni pameti');
     Inc(Number_of_units);
     with (Units[I]^) do begin
        Destroyed:=False; DestroyEffect:=False; Race:=Rac;
        Index:=I; UnitType:=UnitTyp; First_attack:=True;
        IInfoPos:=255; JInfoPos:=255; ITarget:=65535; JTarget:=65535;
        if (UnitTyp <> 255) then Name:=Unit_types[UnitTyp,Races[Race].Ally].Name;
        BuildingType:=0;
        _building:=False;
        if (UnitTyp = 33) then begin
        { jednotka - budova }
          Name:=Building_types[BuildType].Name;
          BuildingType:=BuildType;
          _building:=True;
        end else
          if (UnitTyp = 255) then begin
          { jednotka - slozena jednotka }
             Name:=Unit_types[BuildType,Races[Race].Ally].Name;
             BuildingType:=BuildType;
             _building:=False;
             UnitTyp:=33; UnitType:=UnitTyp;
          end;
        with (Unit_types[UnitTyp,Races[Race].Ally]) do begin
           DamageBonus:=0;
           Damage:=DefenceStrength+DamageBonus;
           TargetType:=TargetTyp;
           Sight:=_Sight;
        end;

        Inc(Races[Rac].Number_of_race_units);
        Inc(Races[Rac].ExistUnits[UnitTyp]);
        Inc(Races[Rac].ProducedUnits[UnitTyp]);

        WayPointMax:=255;
        WayPointUk:=255;
        SpecNumber:=0;
        RandomUk:=1;
        Activity:=True;
        ActivityFlag:=0;
        RequestDraw:=False;
        WearOutLimitDecreaseFlag:=0;
        SearchingFlag:=Hi(Unit_types[UnitTyp,Races[Race].Ally].ShootRange1);
        WarningBlingFlag:=0;
        if (Disorder) then begin
          if (GameTimming = 0) then else RandomFlag:=(Random(15)+5) shl 4;
        end else RandomFlag:=100;
        IPos:=IPosic; JPos:=JPosic;
        {WayPointUk:=0; WayPointMax:=0;
        WayPoint[WayPointUk].IAim:=IPos;
        WayPoint[WayPointUk].JAim:=JPos;{}
        XOffset:=0; YOffset:=0;
        MoveUk:=0; BanDir:=0; Return_to_base:=False;
        Attacking:=False;
        Move_target_level:=0;
        BTarget:=Nil; { pozice cile, je-li pevny pri utoku }
        Target:=Nil; { ukazatel na pohyblivy cil pri utoku }
        Stop_:=False;
        Cargo:=0; HarvestPhase:=0;
        SlashCount:=0; SlashDir:=0;
        FlashFlag:=0;
        SkillLevelMoraleBonusFlag:=0;
        Repair:=False;
        DrawRepair:=False; RepairFlag:=0; DrawRepairFlag:=0;
        BPRepairRemainder:=0; PLRepairRemainder:=0;
        EERepairRemainder:=0; EXRepairRemainder:=0;
        RepairRemainder:=0;
        Visibility:=Visibilit;
        VisibilityChange:=False;
        EnemyVisibilityChange:=False;
        ActiveWeapon:=0; ShootFlag:=0;
        ShootTypeFlag1:=0; ShootDelayFlag1:=0;
        ShootTypeFlag2:=0; ShootDelayFlag2:=0;
        FirePhase:=0; FireFlag:=0;
        First_mov:=True;
        MoveStatus:=0;
        BlockMove:=False;
        Sold:=False;
        IBlock:=65535; JBlock:=65535;
        ActiveDefenceRange:=8;
        CheckGroupMoveDistance:=False;
        GroupMove:=False;
        GroupMoveBlock:=0;
        Status:=0;
        Direction:=2;
        IdleFlag:=0; TurnFlag:=0;
        ActiveDefence:=False;
        if (Rac <> MyRace) then begin { jednotky pocitace }
           ActiveDefence:=True; ActiveDefenceRange:=255;
        end; {}
        ADefModeSteps:=0;
        Phase:=0;
        MovementAddingPhase:=0;
        Temp:=0; Load_flag:=0;
        Group:=254;
        GroupOrder:=0;
        GroupMoveSteps:=0;
        UniqueNumber:=65535;
        UnitsInsideNum:=0; { pocet nalozenych jednotek }
        UnitsInsidePlace:=0; { misto obsazene nalozenymi jednotkami }
        Next:=Nil;
        TaskGroup:=InvalidTaskGroupNumber;
        CommandNum:=0;
        Awaiting_for_further_orders:=False;
        Selected:=False;
        Working:=False; HarvesterWait:=0;
        UpdateDmg:=False; UpdateMoralWearOut:=False; UpdateLev:=False;
        CivilianMoveFlag:=0;
        CivilianMoveLimit:=Random(150); { limit = pocet time slotu }
        Morale:=AverageMorale;
        LAttackBonus1:=0; HAttackBonus1:=0; AAttackBonus1:=0;
        LAttackBonus2:=0; HAttackBonus2:=0; AAttackBonus2:=0;
        WearOutRest:=False;
        Kills:=Kill; { pocet znicenych nepratel }
        if ((Races[Race].RaceType = 3) or (Races[Race].RaceType = 6))
        then ExperienceLevel:=0
        else begin
           ExperienceLevel:=ExperiencLevel; { aktualni hodnost (0-12) }
           if ((ExperienceLevel = 0) and (TimeSlot > 256))
           then ExperienceLevel:=Races[Rac].InitUnitLevel;
        end;
        case (ExperienceLevel) of
          0 : begin Experience:=Experience0; Kills:=Kills0; end;
          1 : begin Experience:=Experience1; Kills:=Kills1; end;
          2 : begin Experience:=Experience2; Kills:=Kills2; end;
          3 : begin Experience:=Experience3; Kills:=Kills3; end;
          4 : begin Experience:=Experience4; Kills:=Kills4; end;
          5 : begin Experience:=Experience5; Kills:=Kills5; end;
          6 : begin Experience:=Experience6; Kills:=Kills6; end;
          7 : begin Experience:=Experience7; Kills:=Kills7; end;
          8 : begin Experience:=Experience8; Kills:=Kills8; end;
          9 : begin Experience:=Experience9; Kills:=Kills9; end;
          10: begin Experience:=Experience10; Kills:=Kills10; end;
          11: begin Experience:=Experience11; Kills:=Kills11; end;
          12: begin Experience:=Experience12; Kills:=Kills12; end;
        else
          Error(0,'unita_units, procedura New_unit, chybne cislo hodnosti');
        end;
        Eras:=False;
        IntelliSearching_for_attack_flag:=IPos mod IntelliSearching_for_attack_limit;
        Group:=254;
        if (Unit_types[UnitTyp,Races[Race].Ally].UnitLevel = 255)
        then MinimalWearOut:=MinWearOut-MinWearOut shr 1+MinWearOut shr 3
        else MinimalWearOut:=MinWearOut;
        WearOut:=MinimalWearOut;
        DangerClass:=0; ADangerClass:=255;
        AIAttackType:=4; AIAttackBuilding:=Nil; AIAttackUnit:=Nil;
        Free_attack:=True; Down:=0;
        KamikadzeMod:=False;
        if (not Send) then Set_place(IPosic, JPosic, Units[I], True, True)
        else begin
          Set_placex(IPosic, JPosic, Units[I]);
          {IInfoPos:=IPos div IInfoDiv; JInfoPos:=JPos div JInfoDiv;{}
        end;
        if ((Races[Rac].RaceType = 3) or (Races[Rac].RaceType = 6)) then
          Change_unit_wear_out(Units[I]) { roboti - opotrebeni }
        else
          Change_unit_experience_morale(Units[I]); { lide - moralka + hodnosti }

        if (GameTimming = 0) then WearOutFlag:=WearOutRepairSpeed shr 1
        else WearOutFlag:=WearOutRepairSpeed;

        with (Unit_types[UnitTyp,Races[Race].Ally]) do begin
           Damage:=DefenceStrength+DamageBonus;
        end;
        { ULOZENI INFORMACI DO GLOBALNICH STATISTIK }
        with (Races[Rac]) do begin
          if (DangerClass = 255) then PomClass:=255 else
           if (DangerClass <= 2) then PomClass:=0 else
            if (DangerClass <= 5) then PomClass:=1 else
             if (DangerClass <= 7) then PomClass:=2;
          if (PomClass = 255) then begin
          { specialni jednotky - slozena budova nebo recyklator }
            if (UnitTyp = 2) then begin
              Inc(Recyclators);
            end else begin
              {Inc(ExistUnits.PackedBuildings); Inc(ProducedUnits.PackedBuildings);{}
            end;
          end else ;
        end;

        { * }
        if (UnitTyp = 41) then with (Races[Rac]) do begin
         PUk:=CentraPosil;
         if (PUk = Nil) then CentraPosil:=Units[I]
         else begin
            while (PUk <> Nil) do begin
              PUkFather:=PUk; PUk:=PUk^.Next;
            end;
            PUkFather^.Next:=Units[I];
         end;
       end;
       { * }

        { pokracuj v inicializaci }
        for J:=0 to MaxGroupUnits-2 do UnitsInside[J]:=0;
        if ((Unit_types[UnitTyp,Races[Race].Ally].UnitLevel = 3) and
            (Unit_types[UnitTyp,Races[Race].Ally].SpecAirLevel = 0)) then
        with (Races[Rac]) do begin
        { prirazeni letiste spec. letecke jednotce }
           if (I_free_airport_space_max_index > MaxAirportSpace) then
              Error(0,'nedostatek letistni kapacity pro vzdusne jednotky')
           else begin
             with (Free_airport_space[I_free_airport_space_max_index]) do begin
               IAirport:=IFree;
               JAirport:=JFree;
               AirportPos:=Pos;
             end;
             if (Races[Rac].I_free_airport_space_max_index = 0)
             then Races[Rac].I_free_airport_space_max_index:=255
             else Dec(Races[Rac].I_free_airport_space_max_index);
           end;
        end;
        UpdateScore(Race,UnitType,False,False,DamageBonus,LAttackBonus1,
                    HAttackBonus1,AAttackBonus1,False);
        for J:=0 to 19 do XXXTemp[J]:=0;
    end; { with }
    { vykresleni jednotky }
    if ((Visibilit) and (not Send)) then Draw_unit(Units[I]);
    if (not Send) then SetFog(IPosic,JPosic,Units[I]^.Sight,Rac,True);
  end;
  New_unit:=I;
end;

{ ***** }
procedure Disband_unit(var _unit:PUnit; Era : Boolean; Destruct : Boolean);
{ zrusi jednotku _unit a je-li Era = True, take ji smaze
  Destruct = True .. jedna se o zniceni vybuchem, t.j. vykresli trosky
  Destruct = False .. trosky nevykresluj
}
var I,K,L,M,Ind:Word;
    Base : Byte;
    IPo, JPo : Word;
    Draw_bck : Boolean;
    PomClass:Byte;
    Visib:Boolean;
    PomValue:Double;
    Flag:Byte;
    PomDangerClass:Word;
    Lev:Byte;
    PUk,PUkFather:PUnit;
begin
  if (_unit <> Nil) then begin
      with (_unit^) do begin
        {XXX}
        { odalokovani jednotky jadra }
        if (UniqueNumber <> 65535) then DestroyCoreUnit(UniqueNumber);
        { odalokovani jednotky ze seznamu }
        if (UnitType = 41) then with (Races[Race]) do begin
          PUk:=CentraPosil;
          if (PUk = _unit) then CentraPosil:=_unit^.Next
          else begin
             while (PUk <> _unit) do begin
                PUkFather:=PUk; PUk:=PUk^.Next;
                if (PUk = Nil) then Error(0,'Chyba v unite _units, procedura Disband_unit');
             end;
             PUkFather^.Next:=PUk^.Next; { vylouceni ze seznamu }
          end;
        end;
        {XXX}
        if (Destruct) then
          UpdateScore(Race,UnitType,False,True,DamageBonus,LAttackBonus1,
                      HAttackBonus1,AAttackBonus1,True);

        if (Group <= MaxGroups) then with Groups[Group] do begin
           if (Group = ActiveGroup) then begin
              Clear_unit_slot(_unit);
              if (Count = 1) then begin
              { je to posl. jednotka - zrus grupu }
                 Deselect_group(ActiveGroup);
                 if (Active(Stop)) then SetPasive(Stop,256);
                 if (Active(Patrol)) then SetPasive(Patrol,256);
                 if (Active(Nalozit)) then SetPasive(Nalozit,256);
                 if (Active(Vylozit)) then SetPasive(Vylozit,256);
                 if (Active(Opravit)) then SetPasive(Opravit,256);
                 if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                 ClearActiveDefenceRangeSlots;
              end;
           end;
        end;
        { odalokovani jednotky z ulozenych skupin }
        for L:=0 to MaxGroups do
          for K:=0 to (MaxGroupUnits-1) do with (Groups[L]) do
            if (Un[K] = _unit) then begin
                Un[K]:=Nil;
                Dec(Count);
            end;

        { smazani jednotky ze seznamu cilu }
        if (TargetType = 3) then Lev:=1 else Lev:=0;
        for L:=0 to MaxRace do with (Races[L]) do begin
          for K:=0 to 9 do with (TaskGroups^[K]) do begin
            if (Validity) then begin
               ClearActiveAttackTGInfoXY(L,K,Lev,IPos,JPos);
            end;
          end;
        end;

        Activity:=False; Visib:=Visibility;
        Dec(Races[Race].ExistUnits[UnitType]);
        if ((SpecNumber > 0) and (not Races[Race].ChangeOnVisib)) then begin
          Dec(SpecNumList^[SpecNumber].Count);
          SpecNumList^[SpecNumber].Destr:=True;
        end;
        if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
            (Race = ThisCompRace3) or (Race = ThisCompRace4) or
            (Race = ThisCompRace5)) then with Races[Race] do begin
            if (TaskGroup <> InvalidTaskGroupNumber) then
            with TaskGroups^[TaskGroup] do begin
            { vymazat z tasgrupy }
               if (Validity) then begin
                  Dec(Lock);
                  if (UnitType = 18) then Dec(Fighters);
                  if (UnitType = 19) then Dec(Terminators);
                  if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                  then Dec(AirUnitsCount);
                  if ((Unit_Types[UnitType,Races[Race].Ally].NeedPlace <= 5) or
                      (TaskGroup = 12) and (UnitType = 9))
                  then Dec(TGCapacityNeed,Unit_Types[UnitType,Races[Race].Ally].NeedPlace);
                  if (Unit_types[UnitType,Races[Race].Ally].Capacity <> 0) then
                     Delete_task_group_carrier(Race,TaskGroup,_unit);
                  if (Lock = 0) then InvalidateTaskGroup(Race,TaskGroup);
                  {x}
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
               end;
            end;
            if ((_building) and (UnitType = 33) and Destruct) then begin
            { jde-li o slozenou budovu urcitych typu, sniz zamek na
              zakazu reagovat na nedostatek dotycne suroviny }
              case (BuildingType) of
              { odstranit zakaz pro danou komoditu }
                 2  :if (BarrackShortageForbid > 0)  { kasarna }
                     then Dec(BarrackShortageForbid);
                 3  :if (LightFactoryShortageForbid > 0) { lehka tovarna }
                     then Dec(LightFactoryShortageForbid);
                 4  :if ((BPShortageForbid > 0) and
                         (ExistBuildings[4] = 0)) { recyklace }
                     then Dec(BPShortageForbid);
                 5  :if (EEShortageForbid > 0)  { elektrarna }
                     then Dec(EEShortageForbid);
                 6  :if (AccumulatorShortageForbid > 0) {akumulator}
                     then Dec(AccumulatorShortageForbid);
                 8 : begin
                       if (PLShortageForbid > 0)  { plastarna }
                       then Dec(PLShortageForbid);
                       if (DruhaPlastarnaVeVyrobe) then DruhaPlastarnaVeVyrobe:=False;
                     end;
                 9  :if (Base2ShortageForbid > 0)  { zakladna2 }
                     then Dec(Base2ShortageForbid);
                 10 :if (HeavyFactoryShortageForbid > 0) { tezka tovarna }
                     then Dec(HeavyFactoryShortageForbid);
                 11 : if (AirportShortageForbid > 0) { letiste }
                      then Dec(AirportShortageForbid);
                 12 :if (SpecialFactoryShortageForbid > 0)
                     { specialni tovarna }
                     then Dec(SpecialFactoryShortageForbid);
                 13 :if (RepairFactoryShortageForbid > 0)
                     { centrum oprav }
                     then Dec(RepairFactoryShortageForbid);
                 14 :if (DefenceFactoryShortageForbid > 0)
                     { obranne centrum }
                     then Dec(DefenceFactoryShortageForbid);
                 15 :if (BarrackShortageForbid > 0) { montazni linka}
                     then Dec(BarrackShortageForbid);
                 21 : if (RadarShortageForbid > 0) { radar }
                      then Dec(RadarShortageForbid);
              end;
              { nyni se vrati pridelene misto pro rozlozeni: }
              with TaskGroups^[TaskGroup] do begin
                if (Command = MoveBuildCom) then
                   AddFreePlaceForBuilding(Race,ITargPlace,JTargPlace,Flag,0);
              end;
            end else begin
               Flag:=0;
               { nyni se vrati pridelene misto pro rozlozeni: }
               if ((UnitType = 32) or (UnitType = 21)) then Flag:=8
               { SAM nebo tezka pevnost, priorita 2 }
               else
                 if ((UnitType = 31) or (UnitType = 20)) then Flag:=11
                 { raketova vez nebo lehka pevnost, priorita 2}
                 else if (UnitType = 41) then Flag:=17;
               if ((Flag <> 0) and (Flag <> 17)) then
                 AddFreePlaceForBuilding(Race,IPos,JPos,Flag,0)
               else
                 if (Flag = 17) then
                   AddFreePlaceForBuilding(Race,IPos,JPos,Flag,1);
            end;
        end;
        Dec(Number_of_units);
        Dec(Races[Race].Number_of_race_units);
        if (not Selected) then begin
        { Selected = True pro jednotku ulozenou uvnitr jine }
          if (XOffset <> 0) then Set_place(IPos+1,JPos, _unit, False, False);
          if (YOffset <> 0) then Set_place(IPos,JPos+1, _unit, False, False);
          if ((XOffset <> 0) and (YOffset <> 0)) then
             Set_place(IPos+1,JPos+1, _unit, False, False);
          Set_place(IPos,JPos, _unit, False, True);
          { nyni fog of war }
          if ((XOffset <> 0) or (YOffset <> 0)) then begin
             case (Status) of
             { v Prepare_disband_unit se prekopiruje Direction -> Status }
               1:   SetFog(IPos,JPos,Sight,Race,False);
               2:   SetFog(IPos,JPos,Sight,Race,False);
               4:   SetFog(IPos+1,JPos,Sight,Race,False);
               8:   SetFog(IPos+1,JPos,Sight,Race,False);
               16:  SetFog(IPos+1,JPos+1,Sight,Race,False);
               32:  SetFog(IPos,JPos+1,Sight,Race,False);
               64:  SetFog(IPos,JPos+1,Sight,Race,False);
               128: SetFog(IPos,JPos,Sight,Race,False);
             end
           end else SetFog(IPos,JPos,Sight,Race,False);
        end;

        Ind:=Index;
        if (Repair) then Inc(Races[Race].RepairsAvailable,UnitRepairCapacityNeed);
        { ULOZENI INFORMACI DO GLOBALNICH STATISTIK }
        with (Races[Race]) do begin
          if (DangerClass = 255) then PomClass:=255 else
           if (DangerClass <= 2) then PomClass:=0 else
            if (DangerClass <= 5) then PomClass:=1 else
             if (DangerClass <= 7) then PomClass:=2;
          if (PomClass = 255) then begin
          { specialni jednotky - slozena budova nebo recyklator }
            if (UnitType = 2) then Dec(Recyclators)
            else {Dec(ExistUnits.PackedBuildings){};
          end else ;
          {  if (Unit_types[UnitType].TargetTyp = 0) then Inc(ExistUnits.LLightUn[PomClass])
            else
              if (Unit_types[UnitType].TargetTyp = 1) then Inc(ExistUnits.LightUn[PomClass])
              else
                if (Unit_types[UnitType].TargetTyp = 2) then Inc(ExistUnits.HeavyUn[PomClass])
                else
                  if (Unit_types[UnitType].TargetTyp = 3) then Inc(ExistUnits.AirUn[PomClass]);
          if (ADangerClass <> 255) then Inc(ExistUnits.AAtackUn[ADangerClass]);
          {}
        end;

        if ((Destroyed) and (UnitType <> 23) and (not Sold))
        { ne autodetonator, prodana jednotka }
        then with (MapInfo^[IInfoPos,JInfoPos]) do begin
          PomValue:=GetMoraleModif(Race,UnitType,False,DamageBonus,LAttackBonus1,
                                   HAttackBonus1,AAttackBonus1);
          for I:=0 to MaxRace do begin
            if (Races[I].Friend[Race] = 0) then begin
               MoraleModifierTemp[I]:=MoraleModifierTemp[I]+PomValue;
               if (I = MyRace) then
                 Races[I].GlobalMoraleTemp:=Races[I].GlobalMoraleTemp+PomValue/8.2
               else
                 Races[I].GlobalMoraleTemp:=Races[I].GlobalMoraleTemp+PomValue/8.2;
            end;
            if (Races[I].Friend[Race] = 2) then begin
               MoraleModifierTemp[I]:=MoraleModifierTemp[I]-PomValue;
               if (I = MyRace) then
                 Races[I].GlobalMoraleTemp:=Races[I].GlobalMoraleTemp-PomValue/8.2
               else
                 Races[I].GlobalMoraleTemp:=Races[I].GlobalMoraleTemp-PomValue/8.2;
            end;
          end;
        end;

        { * nyni vytvorime trosky * }
        Draw_bck:=False;
        IPo:=IPos; JPo:=JPos;
        if (Debris and (Destruct or not(Destroyed)) and (UnitType <> 33) and
            (not Sold) and
            ((MapBck^[IPo,JPo].Info < 10) or (MapBck^[IPo,JPo].Info > 37))) then begin
          if ((XOffset = 0) and (YOffset = 0)) then Draw_bck:=False
          else Draw_bck:=True;
          if (XOffset > 16) then Inc(IPo);
          if (YOffset > 16) then Inc(JPo);
          if (not Destroyed) then with (MapBck^[IPo,JPo]) do begin
          { jednotka se vzdala nebo opotrebovala }
             if (LowDebrisInfoIndex = 255) then LowDebrisInfoIndex:=0;
             Base:=DebrisGiveUpIndex;
             Info:=DebrisInfoIndex;
             with (DebrisInfo^[DebrisInfoIndex]) do begin
                GiveUpTimmer:=0;
                DebrisType:=Base;
                IP:=IPo;
                JP:=JPo;
                FireTimmer:=0; DebrisTimmer:=GetAccurateDelay(HalfDebrisTimmerValue);
             end;
             Inc(DebrisInfoIndex);
             if (DebrisInfoIndex > MaxDebrisInfoIndex) then DebrisInfoIndex:=0;
          end else begin
          { "normalni smrt" }
              case (TargetType) of
               0 : with (MapBck^[IPo,JPo]) do begin { lehky - pechota }
                     if (Race <> 3) then Base:=0
                     else Base:=2;
                     if BelowEqual(BckType,Hill) then begin
                        Info:=DebrisInfoIndex;
                        with (DebrisInfo^[DebrisInfoIndex]) do begin
                           DebrisType:=Base; FirePhase:=0;
                           IP:=IPo;
                           JP:=JPo;
                           FireTimmer:=0; DebrisTimmer:=GetAccurateDelay(DebrisTimmerValue);
                        end;
                        if (LowDebrisInfoIndex = 255) then LowDebrisInfoIndex:=0;
                        Inc(DebrisInfoIndex);
                        if (DebrisInfoIndex > MaxDebrisInfoIndex) then
                          DebrisInfoIndex:=0;
                     end;
                   end;
               1 : with (MapBck^[IPo,JPo]) do begin { lehky - vozidla }
                      Base:=4;
                      if BelowEqual(BckType,Hill) then begin
                         Info:=DebrisInfoIndex;
                         with (DebrisInfo^[DebrisInfoIndex]) do begin
                            DebrisType:=Base; FirePhase:=0;
                            IP:=IPo;
                            JP:=JPo;
                            FireTimmer:=DebrisFireTimmerValue shr 2; FirePhase:=0;
                            DebrisTimmer:=GetAccurateDelay(DebrisTimmerValue);
                         end;
                         if (LowDebrisInfoIndex = 255) then LowDebrisInfoIndex:=0;
                         Inc(DebrisInfoIndex);
                         if (DebrisInfoIndex > MaxDebrisInfoIndex) then
                            DebrisInfoIndex:=0;
                      end;
                   end;
               2 : with (MapBck^[IPo,JPo]) do begin { tezky }
                      Base:=6;
                      if (BelowEqual(BckType,Hill) and
                          (BelowEqual(BckType,Field) or
                           Above(BckType,Resrc))) then begin
                         Info:=DebrisInfoIndex;
                         with (DebrisInfo^[DebrisInfoIndex]) do begin
                            DebrisType:=Base; FirePhase:=0;
                            IP:=IPo;
                            JP:=JPo;
                            FireTimmer:=DebrisFireTimmerValue shr 2; FirePhase:=0;
                            DebrisTimmer:=GetAccurateDelay(DebrisTimmerValue);
                         end;
                         if (LowDebrisInfoIndex = 255) then LowDebrisInfoIndex:=0;
                         Inc(DebrisInfoIndex);
                         if (DebrisInfoIndex > MaxDebrisInfoIndex) then
                           DebrisInfoIndex:=0;
                      end;
                   end;
               3 : with (MapBck^[IPo,JPo]) do begin { vzdusny }
                      Base:=8;
                      if (BelowEqual(BckType,Hill) and
                          (BelowEqual(BckType,Field) or
                           Above(BckType,Resrc))) then begin
                         if (Map^[IPo,JPo].Level_type and 128 <> 128) then
                            Info:=DebrisInfoIndex;
                         with (DebrisInfo^[DebrisInfoIndex]) do begin
                            DebrisType:=Base; FirePhase:=0;
                            IP:=IPo;
                            JP:=JPo;
                            FireTimmer:=DebrisFireTimmerValue shr 2; FirePhase:=0;
                            DebrisTimmer:=GetAccurateDelay(DebrisTimmerValue);
                         end;
                         if (LowDebrisInfoIndex = 255) then LowDebrisInfoIndex:=0;
                         Inc(DebrisInfoIndex);
                         if (DebrisInfoIndex > MaxDebrisInfoIndex) then
                            DebrisInfoIndex:=0;
                      end;
                   end;
               4 : begin { namorni }
                   end;
              else
                Error(0,'unita _units, procedura Disband_unit');
              end;
          end;
        end;
        if (Visib and Era) then Erase_unit(_unit,True);
        if (Draw_bck) then Transfer_map_frame(IPo,JPo,IPo,JPo);

        { uvolneni letiste }
        if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
            (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0))
        then with (Races[Race]) do begin
            if (I_free_airport_space_max_index = 255) then
               I_free_airport_space_max_index:=0
            else Inc(I_free_airport_space_max_index);
            Free_airport_space[I_free_airport_space_max_index].IFree:=IAirport;
            Free_airport_space[I_free_airport_space_max_index].JFree:=JAirport;
            Free_airport_space[I_free_airport_space_max_index].Pos:=AirportPos;
        end;
      end;

      Dispose(_unit);
      Units[Ind]:=Nil;
      _unit:=Nil;
  end;
end;

{ ***** }
procedure Prepare_disband_unit(_unit:PUnit);
{ rozanimuje vybuch jednotky a nakonec ji zlikviduje
}
var PomPhase:Word;
begin
   with (_unit^) do begin
      if (DestroyEffect) then PomPhase:=8
      else PomPhase:=MaxSmallExplosPhase;
      Destroyed:=True;
      if (GameTimming = 0) then Inc(Direction,2) else Inc(Direction);
      if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 0) then Phase:=Max_units_explosion_phase+1;
      FirePhase:=0;
      if (Direction > 1) then Direction:=0;
      if (Direction = 0) then begin
        {jedna z fazi vybuchu }
        Inc(Phase);
        if (Phase > PomPhase) then begin
        { likvidace jednotky }
          Disband_unit(_unit,True,True);
        end else Redraw_unit(_unit,True);
      end;
   end;
end;

{ ***** }
procedure Disband_units;
{ zrusi vsechny existujici jednotky
}
var I:Word;
begin
  for I:=1 to (MaxRaceUnits+1)*(MaxRace+1) do begin
    if (Units[I] <> Nil) then with (Units[I]^) do begin
        Dispose(Units[I]);
        Units[I]:=Nil;
    end;
  end;{}
  Number_of_units:=0;
end;{}

{ ***** }
function Above(Index,TerrainType:Word):Boolean;
{ vraci True, je-li index vetsi nez indexy terenu typu TerrainType
}
const Way1    = 46;  { maximalni index daneho terenu  - cesty }
      Grass1  = 156; { trava }
      Field1  = 156; { pole = trava }
      Resrc1  = 168; { resource - "skladka" materialu }
      Desert1 = 168; { poust = neexistuje }
      Hill1   = 195; { kopec }
      Wather1 = 201; { voda }
      Wood1   = 249; { les }
      Airport1= 250; { letiste }
      {*}
      Way2    = 256+9;   { maximalni index daneho terenu  - cesty }
      Grass2  = 256+61;  { trava }
      Field2  = 256+83;  { pole = trava }
      Resrc2  = 256+84;  { resource - "skladka" materialu }
      Desert2 = 256+ 83; { poust = neexistuje }
      Hill2   = 256+97;  { kopec }
      Wather2 = 256+109; { voda }
      Wood2   = 256+255; { les }
      Airport2= 256+255; { letiste }
      {*}
var Result:Boolean;
begin
   Result:=False;
   case (TerrainType) of
    Way    : if ((Index < 256) and (Index > Way1) or
                 (Index > 255) and (Index > Way2)) then Result:=True;
    Grass  : if ((Index < 256) and (Index > Grass1) or
                 (Index > 255) and (Index > Grass2)) then Result:=True;
    Field  : if ((Index < 256) and (Index > Field1) or
                 (Index > 255) and (Index > Field2)) then Result:=True;
    Resrc  : if ((Index < 256) and (Index > Resrc1) or
                 (Index > 255) and (Index > Resrc2)) then Result:=True;
    Desert : if ((Index < 256) and (Index > Desert1) or
                 (Index > 255) and (Index > Desert2)) then Result:=True;
    Hill   : if ((Index < 256) and (Index > Hill1) or
                 (Index > 255) and (Index > Hill2)) then Result:=True;
    Wather : if ((Index < 256) and (Index > Wather1) or
                 (Index > 255) and (Index > Wather2)) then Result:=True;
    Wood   : if ((Index < 256) and (Index > Wood1) or
                 (Index > 255) and (Index > Wood2)) then Result:=True;
    Airport: if ((Index < 256) and (Index > Airport1) or
                 (Index > 255) and (Index > Airport2)) then Result:=True;
   else
   end;

   Above:=Result;
end;

{ ***** }
function BelowEqual(Index,TerrainType:Word):Boolean;
{ vraci True, je-li index mensi nez indexy terenu typu TerrainType
}
const Way1    = 46;  { maximalni index daneho terenu  - cesty }
      Grass1  = 156; { trava }
      Field1  = 156; { pole = trava }
      Resrc1  = 168; { resource - "skladka" materialu }
      Desert1 = 168; { poust = neexistuje }
      Hill1   = 195; { kopec }
      Wather1 = 201; { voda }
      Wood1   = 249; { les }
      Airport1= 250; { letiste }
      {*}
      Way2    = 256+9;   { maximalni index daneho terenu  - cesty }
      Grass2  = 256+61;  { trava }
      Field2  = 256+83;  { pole = trava }
      Resrc2  = 256+84;  { resource - "skladka" materialu }
      Desert2 = 256+ 83; { poust = neexistuje }
      Hill2   = 256+97;  { kopec }
      Wather2 = 256+109; { voda }
      Wood2   = 256+255; { les }
      Airport2= 256+255; { letiste }
      {*}
var Result:Boolean;
begin
   Result:=False;
   case (TerrainType) of
    Way    : if ((Index < 256) and (Index <= Way1) or
                 (Index > 255) and (Index <= Way2)) then Result:=True;
    Grass  : if ((Index < 256) and (Index <= Grass1) or
                 (Index > 255) and (Index <= Grass2)) then Result:=True;
    Field  : if ((Index < 256) and (Index <= Field1) or
                 (Index > 255) and (Index <= Field2)) then Result:=True;
    Resrc  : if ((Index < 256) and (Index <= Resrc1) or
                 (Index > 255) and (Index <= Resrc2)) then Result:=True;
    Desert : if ((Index < 256) and (Index <= Desert1) or
                 (Index > 255) and (Index <= Desert2)) then Result:=True;
    Hill   : if ((Index < 256) and (Index <= Hill1) or
                 (Index > 255) and (Index <= Hill2)) then Result:=True;
    Wather : if ((Index < 256) and (Index <= Wather1) or
                 (Index > 255) and (Index <= Wather2)) then Result:=True;
    Wood   : if ((Index < 256) and (Index <= Wood1) or
                 (Index > 255) and (Index <= Wood2)) then Result:=True;
    Airport: if ((Index < 256) and (Index <= Airport1) or
                 (Index > 255) and (Index <= Airport2)) then Result:=True;
   else
   end;

   BelowEqual:=Result;
end;

{ ***** }
function Free_place(I, J, ISize, JSize:Word; _unit:PUnit):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize-1,J+JSize-1 a na urovni jednotky
  jsou policka volna; pak vraci True, jinak False
  pozn. pohybova uroven jednotky muze nabyvat hodnot :
  0..pozemni - nemuze na vodu, do lesa,do hor
  1..pozemni - nemuze na vodu, do lesa
  2..pozemni - nemuze do lesa
  3..vzdusny
  4..namorni - smi pouze po vode
  MIMO recyklatoru ZADNA pozemni jednotka NEMUZE na zdroj (resource)
}
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level:Byte;
begin
 Level:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel;
 if (Level < 255) then begin
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   for K:=I to I2 do
     for L:=J to J2 do
       if (Level < 3) then begin{ pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
              if (Above(BckType,Desert) or
                  (First_level <> 0)) then Pom:=False;
            end
         else { pozemni 2,3 }
           if (Level = 1) then { pozemni 2 }
              with (Map^[K,L]) do with (MapBck^[K,L]) do begin
                if (Above(BckType,Hill) or
                    (First_level <> 0)) then Pom:=False;
              end
           else
             with (Map^[K,L]) do with (MapBck^[K,L]) do begin  { pozemni 3 }
               if (Above(BckType,Wather) or
                   (First_level <> 0)) then Pom:=False;
             end;

         with (Map^[K,L]) do with (MapBck^[K,L]) do begin
         { na zdroj muze pouze recyklator }
           if (Above(BckType,Field) and BelowEqual(BckType,Resrc) and
               (_unit^.UnitType <> 2)) then Pom:=False;
         end;
       end else
         if (Level = 3) then begin { vzdusny }
            if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
         end else { namorni }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
               if (BelowEqual(BckType,Hill) or Above(BckType,Wather) or
                   (First_level <> 0)) then Pom:=False;{ prekazka }
            end;
   Free_place:=Pom;
 end else Free_place:=False;
end;

{ ***** }
function Free_place_three(I, J, ISize, JSize:Word; Levl:Byte; _unit:PUnit):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize-1,J+JSize-1 jsou policka volna;
  pak vraci True, jinak False
  pozn. pohybova uroven jednotky muze nabyvat hodnot :
  0..pozemni - nemuze na vodu, do lesa,do hor
  1..pozemni - nemuze na vodu, do lesa
  2..pozemni - nemuze do lesa
  3..vzdusny
  4..namorni - smi pouze po vode
  Levl urcuje pozici cile:
  0 .. pozemni
  1 .. vzdusny
  MIMO recyklatoru ZADNA pozemni jednotka NEMUZE na zdroj (resource)
}
label Ground_level_1;
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level:Byte;
begin
 Level:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel;
 if (Level < 255) then begin
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   for K:=I to I2 do
     for L:=J to J2 do
       if (Level < 3) then begin { pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
              if (Above(BckType,Desert) or
                  (First_level <> 0)) then Pom:=False;
            end
         else { pozemni 2,3 }
           if (Level = 1) then { pozemni 2 }
Ground_level_1:
              with (Map^[K,L]) do with (MapBck^[K,L]) do begin
                if (Above(BckType,Hill) or (First_level <> 0)) then Pom:=False;
              end
           else
             with (Map^[K,L]) do with (MapBck^[K,L]) do begin  { pozemni 3 }
               if (Above(BckType,Wather) or (First_level <> 0)) then Pom:=False;
             end;

         with (Map^[K,L]) do with (MapBck^[K,L]) do begin
         { na zdroj muze pouze recyklator }
           if (Above(BckType,Field) and BelowEqual(BckType,Resrc) and
               (_unit^.UnitType <> 2)) then Pom:=False;
         end;
       end else
         if (Level = 3) then begin { vzdusny }
            if (Levl = 0) then begin { cil je na zemi }
              if (Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].SpecAirLevel = 0) then
                 Pom:=False { potrebuje letiste }
              else GoTo Ground_level_1;
            end else begin { cil je ve vzduchu }
              if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
            end;
         end else { namorni }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
               if (BelowEqual(BckType,Hill) or Above(BckType,Wather) or
                   (First_level <> 0)) then Pom:=False;{ prekazka }
            end;
   Free_place_three:=Pom;
 end else Free_place_three:=False;
end;

{ ***** }
function Free_place_three2(I, J, ISize, JSize:Word; Levl:Byte; _unit:PUnit):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize-1,J+JSize-1 jsou policka volna;
  pak vraci True, jinak False
  pozn. pohybova uroven jednotky muze nabyvat hodnot :
  0..pozemni - nemuze na vodu, do lesa,do hor
  1..pozemni - nemuze na vodu, do lesa
  2..pozemni - nemuze do lesa
  3..vzdusny
  4..namorni - smi pouze po vode
  Levl urcuje pozici cile:
  0 .. pozemni
  1 .. vzdusny
  MIMO recyklatoru ZADNA pozemni jednotka NEMUZE na zdroj (resource)
  NA ROZDIL OD PREDCHOZI NETESTUJE PRITOMNOST CIZICH JEDNOTEK NA POLICKU
}
label Ground_level_1;
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level:Byte;
begin
 Level:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel;
 if (Level < 255) then begin
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   for K:=I to I2 do
     for L:=J to J2 do
       if (Level < 3) then begin { pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
              if (Above(BckType,Desert)) then Pom:=False;
            end
         else { pozemni 2,3 }
           if (Level = 1) then { pozemni 2 }
Ground_level_1:
              with (Map^[K,L]) do with (MapBck^[K,L]) do begin
                if (Above(BckType,Hill)) then Pom:=False;
              end
           else
             with (Map^[K,L]) do with (MapBck^[K,L]) do begin  { pozemni 3 }
               if (Above(BckType,Wather)) then Pom:=False;
             end;

         with (Map^[K,L]) do with (MapBck^[K,L]) do begin
         { na zdroj muze pouze recyklator }
           if (Above(BckType,Field) and BelowEqual(BckType,Resrc) and
               (_unit^.UnitType <> 2)) then Pom:=False;
         end;
       end else
         if (Level = 3) then begin { vzdusny }
            if (Levl = 0) then begin { cil je na zemi }
              if (Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].SpecAirLevel = 0) then
                 Pom:=False { potrebuje letiste }
              else GoTo Ground_level_1;
            end else begin { cil je ve vzduchu }
              {if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
            end;
         end else { namorni }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
               if (BelowEqual(BckType,Hill) or Above(BckType,Wather))
               then Pom:=False;{ prekazka }
            end;
   Free_place_three2:=Pom;
 end else Free_place_three2:=False;
end;


{ ***** }
function Free_place_two(I, J, ISize, JSize:Word; UnitType:Byte):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize-1,J+JSize-1 a na urovni jednotky
  jsou policka volna; pak vraci True, jinak False
  UnitType je typ dane jednotky
  MIMO recyklatoru ZADNA pozemni jednotka NEMUZE na zdroj (resource)
}
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level:Byte;
begin
 Level:=Unit_types[UnitType,0].UnitLevel;
 if (Level < 255) then begin
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   for K:=I to I2 do
     for L:=J to J2 do
       if (Level < 3) then begin{ pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
              if (Above(BckType,Desert) or (First_level <> 0)) then Pom:=False;
            end
         else { pozemni 2,3 }
           if (Level = 1) then { pozemni 2 }
              with (Map^[K,L]) do with (MapBck^[K,L]) do begin
                if (Above(BckType,Hill) or (First_level <> 0)) then Pom:=False;
              end
           else
             with (Map^[K,L]) do with (MapBck^[K,L]) do begin  { pozemni 3 }
               if (Above(BckType,Wather) or (First_level <> 0)) then Pom:=False;
             end;

         with (Map^[K,L]) do with (MapBck^[K,L]) do begin
         { na zdroj muze pouze recyklator }
           if (Above(BckType,Field) and BelowEqual(BckType,Resrc) and
               (UnitType <> 2)) then Pom:=False;
         end;
       end else
         if (Level = 3) then begin { vzdusny }
            if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
         end else { namorni }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
               if (BelowEqual(BckType,Hill) or Above(BckType,Wather) or
                   (First_level <> 0)) then Pom:=False;{ prekazka }
            end;
   Free_place_two:=Pom;
 end else Free_place_two:=False;
end;

{ ***** }
function Free_place2(I, J, ISize, JSize:Word; _unit:PUnit):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize,J+JSize a na urovni Level
  neni nejaka jednotka; teren netestuje
}
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level:Byte;
begin
   Level:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel;
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   for K:=I to I2 do
     for L:=J to J2 do
       if (Level < 3) then { pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do begin
              if ((First_level <> 0)) then Pom:=False;
            end
         else { pozemni 2 }
            with (Map^[K,L]) do begin
              if ((First_level <> 0)) then Pom:=False;
            end
       else
         if (Level = 3) then begin { vzdusny }
            if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
         end else { namorni }
            with (Map^[K,L]) do begin
               if (First_level <> 0) then Pom:=False;{ prekazka }
            end;
   Free_place2:=Pom;
end;

{ ***** }
function Free_place3(I, J, ISize, JSize:Word; _unit:PUnit):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize,J+JSize a na urovni Level
  jsou policka volna; jako volne oznaci i pole, na nemz je presunujici se
  jednotka.
  pozn. je-li u _unit (IdleFlag >= IdleLimit), pak se jednotka
  se Statusem 129 bere jako prekazka
  je-li vse OK, vraci True, jinak False
  pozn. pohubova uroven muze nabyvat hodnot :
  0..pozemni - nemuze na vodu, do lesa,do hor
  1..pozemni - nemuze na vodu, do lesa
  2..pozemni - nemuze do lesa
  3..vzdusny
  4..namorni - smi pouze po vode
  MIMO recyklatoru ZADNA pozemni jednotka NEMUZE na zdroj (resource)
}
label Konec;
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level, Dir1, Dir2, Dir3:Byte;
begin
   Level:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel;
   Dir1:=_unit^.Direction;
   asm  rol Dir1,4; end;
   Dir2:=Dir1; Dir3:=Dir1;
   asm rol Dir2,1; ror Dir3,1; end;
   { v pripade, ze je v oblasti cekajici jednotka, nesmi byt natocena
     na smer Dir1, Dir2, Dir3, mame-li ji jako prekazku ignorovat }
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;

   for K:=I to I2 do
     for L:=J to J2 do begin

       if (Level < 3) then begin { pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
              if (Above(BckType,Desert) or (First_level <> 0) and
                  (Units[First_level] <> Nil) and (Level_type and 128 = 0) and
                  ((Units[First_level]^.Status = 0) or
                   (_unit^.IdleFlag >= IdleLimit) or
                   (Units[First_level]^.Status = 129) and
                   ((Units[First_level]^.Direction = Dir1) or
                    (Units[First_level]^.Direction = Dir2) or
                    (Units[First_level]^.Direction = Dir3))) or
                  (First_level <> 0) and
                  ((Level_type and 128 = 128) or
                   (Units[First_level]^.Status > 129)))
                 then Pom:=False;
            end
         else { pozemni 2,3 }
           if (Level = 1) then { pozemni 2 }
              with (Map^[K,L]) do with (MapBck^[K,L]) do begin
                if (Above(BckType,Hill) or (First_level <> 0) and
                    (Units[First_level] <> Nil) and (Level_type and 128 = 0) and
                    ((Units[First_level]^.Status = 0) or
                     (_unit^.IdleFlag >= IdleLimit) or
                     (Units[First_level]^.Status = 129) and
                     ((Units[First_level]^.Direction = Dir1) or
                      (Units[First_level]^.Direction = Dir2) or
                      (Units[First_level]^.Direction = Dir3))) or
                    (First_level <> 0) and
                    ((Level_type and 128 = 128) or
                     (Units[First_level]^.Status > 129)))
                    then Pom:=False;
              end
           else
             with (Map^[K,L]) do with (MapBck^[K,L]) do begin  { pozemni 3 }
               if (Above(BckType,Wather) or (First_level <> 0) and
                   (Units[First_level] <> Nil)  and (Level_type and 128 = 0) and
                   ((Units[First_level]^.Status = 0) or
                    (_unit^.IdleFlag >= IdleLimit) or
                    (Units[First_level]^.Status = 129) and
                    ((Units[First_level]^.Direction = Dir1) or
                     (Units[First_level]^.Direction = Dir2) or
                     (Units[First_level]^.Direction = Dir3))) or
                   (First_level <> 0) and
                    ((Level_type and 128 = 128) or
                     (Units[First_level]^.Status > 129)))
                   then Pom:=False;
             end;

         with (Map^[K,L]) do with (MapBck^[K,L]) do begin
         { na zdroj muze pouze recyklator }
           if (Above(BckType,Field) and BelowEqual(BckType,Resrc) and
               (_unit^.UnitType <> 2)) then Pom:=False;
         end;
       end else
         if (Level = 3) then begin { vzdusny }
            if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
         end else { namorni }
            with (Map^[K,L]) do with (MapBck^[K,L]) do begin
               if (BelowEqual(BckType,Hill) or Above(BckType,Wather) or
                  (First_level <> 0) and (Units[First_level] <> Nil) and
                  (Level_type and 128 = 0) and
                  ((Units[First_level]^.Status = 0) or
                   (_unit^.IdleFlag >= IdleLimit) or
                   (Units[First_level]^.Status = 129) and
                   ((Units[First_level]^.Direction = Dir1) or
                    (Units[First_level]^.Direction = Dir2) or
                    (Units[First_level]^.Direction = Dir3))) or
                  (First_level <> 0) and
                  ((Level_type and 128 = 128) or
                   (Units[First_level]^.Status > 129)))
                  then Pom:=False;
            end;
     end; { for }
   Free_place3:=Pom;
Konec:
end;

{ ***** }
function Free_place4(I, J, ISize, JSize:Word; _unit:PUnit):Boolean;
{ zjisti, zda v obdelniku I,J,I+ISize,J+JSize a na urovni Level
  neni nejaka jednotka, ktera ceka nebo se nehybe; teren netestuje
}
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Level, Dir1, Dir2, Dir3:Byte;
begin
   Level:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel;
   Dir1:=_unit^.Direction; Dir2:=Dir1; Dir3:=Dir1;
   asm  rol Dir2,1; ror Dir3,1; end;
   { v pripade, ze je v oblasti cekajici jednotka, nesmi byt natocena
     na smer Dir1, Dir2, Dir3, mame-li ji jako prekazku ignorovat }
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   for K:=I to I2 do
     for L:=J to J2 do
       if (Level < 3) then { pozemni }
         if (Level = 0) then { pozemni 1 }
            with (Map^[K,L]) do begin
              if ((First_level <> 0) and (Units[First_level] <> Nil) and
                  (Level_type and 128 = 0) and
                  ((Units[First_level]^.Status = 0) or
                   (_unit^.IdleFlag >= IdleLimit) or{}
                   (Units[First_level]^.Status = 129) and
                   ((Units[First_level]^.Direction = Dir1) or
                    (Units[First_level]^.Direction = Dir2) or
                    (Units[First_level]^.Direction = Dir3)) or
                   (Units[First_level]^.Status > 129)) or
                  (First_level <> 0) and (Level_type and 128 = 128))
                 then Pom:=False;
            end
         else { pozemni 2,3 }
           if (Level = 1) then { pozemni 2 }
              with (Map^[K,L]) do begin
                if ((First_level <> 0) and (Units[First_level] <> Nil) and
                    (Level_type and 128 = 0) and
                    ((Units[First_level]^.Status = 0) or
                     (_unit^.IdleFlag >= IdleLimit) or{}
                     (Units[First_level]^.Status = 129) and
                     ((Units[First_level]^.Direction = Dir1) or
                      (Units[First_level]^.Direction = Dir2) or
                      (Units[First_level]^.Direction = Dir3)) or
                     (Units[First_level]^.Status > 129)) or
                    (First_level <> 0) and (Level_type and 128 = 128))
                    then Pom:=False;
              end
           else
             with (Map^[K,L]) do begin  { pozemni 3 }
               if ((First_level <> 0) and (Units[First_level] <> Nil) and
                   (Level_type and 128 = 0) and
                   ((Units[First_level]^.Status = 0) or
                    (_unit^.IdleFlag >= IdleLimit) or{}
                    (Units[First_level]^.Status = 129) and
                    ((Units[First_level]^.Direction = Dir1) or
                     (Units[First_level]^.Direction = Dir2) or
                     (Units[First_level]^.Direction = Dir3)) or
                    (Units[First_level]^.Status > 129)) or
                   (First_level <> 0) and (Level_type and 128 = 128))
                   then Pom:=False;
             end
       else
         if (Level = 3) then begin { vzdusny }
            if (Map^[K,L].Second_level <> 0) then Pom:=False; { prekazka }
         end else { namorni }
            with (Map^[K,L]) do begin
               if ((First_level <> 0)  and (Units[First_level] <> Nil) and
                   (Level_type and 128 = 0) and
                  ((Units[First_level]^.Status = 0) or
                   (_unit^.IdleFlag >= IdleLimit) or{}
                   (Units[First_level]^.Status = 129) and
                   ((Units[First_level]^.Direction = Dir1) or
                    (Units[First_level]^.Direction = Dir2) or
                    (Units[First_level]^.Direction = Dir3)) or
                   (Units[First_level]^.Status > 129)) or
                  (First_level <> 0) and (Level_type and 128 = 128))
                  then Pom:=False;
            end;
   Free_place4:=Pom;
end;

{ ***** }
function Moving_unit_on_place(I,J,ISize,JSize : Word; _unit:PUnit):Boolean;
{ zjisti, zda v dane pozemni oblasti neni presunujici se jednotka (vraci True),
  jinak vraci False
}
label OutSide;
var K, L, I2, J2 : Word;
    Pom:Boolean;
    Dir1, Dir2, Dir3:Byte;
begin
   Dir1:=_unit^.Direction; Dir2:=Dir1; Dir3:=Dir1;
   asm  rol Dir1,3; rol Dir2,4; rol Dir3,5; end;
   { v pripade, ze je v oblasti cekajici jednotka, nesmi byt natocena
     na smer Dir1, Dir2, Dir3, mame-li ji jako prekazku ignorovat }
   I2:=I+ISize-1; J2:=J+JSize-1; Pom:=True;
   if (_unit^.TargetType <> 3) then begin { pozemni }
     for K:=I to I2 do
       for L:=J to J2 do with (Map^[K,L]) do begin
          Pom:=Pom and ((First_level <> 0) and (Level_type and 128 = 0));
          if (Pom) then with (Units[First_level]^) do
             Pom:=Pom and ((Status > 0) and (Status < 129) or
                           (Status = 129) and (Direction <> Dir1) and
                           (Direction <> Dir2) and (Direction <> Dir3))
          else GoTo OutSide;
       end;
   end else begin
      for K:=I to I2 do
       for L:=J to J2 do with (Map^[K,L]) do begin
          Pom:=Pom and ((Second_level <> 0) and (Level_type and 128 = 0));
          if (Pom) then with (Units[Second_level]^) do
             Pom:=Pom and ((Status > 0) and (Status < 129) or
                           (Status = 129) and (Direction <> Dir1) and
                           (Direction <> Dir2) and (Direction <> Dir3))
          else GoTo OutSide;
       end;
   end;
OutSide:
   Moving_unit_on_place:=Pom;
end;

{ ***** }
procedure Draw_move(_unit:PUnit);
{ presune jednotku z aktualni pozice na nasledujici pozici
  dle prirustku MovementAdding. Provede vykresleni, zmeni data, oznacujici
  pozici. UVOLNUJE priznaky obsazenosti jednotlivych policek v pripade,
  ze byl dokoncen pohyb na nove policko (XOffset i YOffset se po presunu = 0).
  Testuje tez dokonceni pohybu; je-li test uspesny, nastavi jednotku do
  polohy "cekej".
}
var MovementAdding:Byte;
    MaxGroupMoveSteps:Byte;
    I,J:Word;
    Result:Boolean;
begin
 bebex:=19000;
 if (_unit = Nil) then bebey:=100 else bebey:=0;
 with (_unit^) do begin
   bebex:=20000;
   Erase_unit(_unit,False);
   bebex:=20001;
   if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) then MaxGroupMoveSteps:=2
   else
     if (BlockMove) then MaxGroupMoveSteps:=2
     else MaxGroupMoveSteps:=4;

   bebex:=20002; bebey:=UnitType; save1:=MovementAddingPhase; save2:=Race;
   MovementAdding:=Unit_types[UnitType,Races[Race].Ally].MovementAdding[MovementAddingPhase];
   Inc(MovementAddingPhase);

   bebex:=20003; bebey:=Direction;
   case (Direction) of
    { nastavi nove hodnoty XOffsets, YOffsets }
       1 : begin { vlevo nahoru \ }
             Dec(XOffset,MovementAdding);
             Dec(YOffset,MovementAdding);
           end;
       2 : begin { nahoru | }
             Dec(YOffset,MovementAdding);
           end;
       4 : begin { vpravo nahoru / }
             Inc(XOffset,MovementAdding);
             if (XOffset >= XCellSize) then begin
               Inc(IPos); Dec(XOffset,XCellSize);
             end;
             Dec(YOffset,MovementAdding);
           end;
       8 : begin { vpravo - }
             Inc(XOffset,MovementAdding);
             if (XOffset >= XCellSize) then begin
               Inc(IPos); Dec(XOffset,XCellSize);
             end;
           end;
       16 : begin { vpravo dolu \ }
             Inc(XOffset,MovementAdding);
             if (XOffset >= XCellSize) then begin
               Inc(IPos); Dec(XOffset,XCellSize);
             end;
             Inc(YOffset,MovementAdding);
             if (YOffset >= YCellSize) then begin
               Inc(JPos); Dec(YOffset,YCellSize);
             end;
           end;
       32 : begin { dolu | }
             Inc(YOffset,MovementAdding);
             if (YOffset >= YCellSize) then begin
               Inc(JPos); Dec(YOffset,YCellSize);
             end;
           end;
       64 : begin { vlevo dolu / }
             if (XOffset = 0) then begin
               XOffset:=XOffset;
             end;
             Dec(XOffset,MovementAdding);
             Inc(YOffset,MovementAdding);
             if (YOffset >= YCellSize) then begin
               Inc(JPos); Dec(YOffset,YCellSize);
             end;
           end;
       128 : begin { vlevo - }
             Dec(XOffset,MovementAdding);
           end;
     end; { case }
     if (XOffset > XCellSize) then
        XOffset:=0;
     if (YOffset > YCellSize) then
        YOffset:=0;

   bebex:=20004;
   if ((XOffset = 0) and (YOffset = 0)) then begin
     if ((BlockMove) and (IPos div IInfoDiv = IBlock) and
         (JPos div JInfoDiv = JBlock)) then begin
     { osetren blokovy presun }
        BlockMove:=False; CheckGroupMoveDistance:=True;
        bebex:=20005;
     end;
     if ((Races[Race].RaceType = 3) or (Races[Race].RaceType = 6))
     then begin { roboti - opotrebeni }
       bebex:=20006;
       if (WearOut <= 50) then
       begin WearOut:=WearOut-WearOutMove6;
             WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutMove6;
       end else
         if (WearOut <= 80) then
         begin WearOut:=WearOut-WearOutMove5;
               WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutMove5;
         end else
           if (WearOut <= 120) then
           begin WearOut:=WearOut-WearOutMove4;
                 WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutMove4;
           end else
             if (WearOut <= 150) then
             begin WearOut:=WearOut-WearOutMove3;
                   WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutMove3;
             end else
              if(WearOut <= 170) then
              begin WearOut:=WearOut-WearOutMove2;
                    WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutMove2;
              end else begin
                  WearOut:=WearOut-WearOutMove1;
                  WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutMove1;
              end;
        bebex:=20007;
        Change_unit_wear_out(_unit);
        bebex:=20008;
     end;

     if ((Race <> MyRace) and ActiveDefence and (MoveStatus <> 8)) then
       if (ADefModeSteps < 65535) then Inc(ADefModeSteps) else ADefModeSteps:=0;
     bebex:=20009;
     if (not Return_to_base) then SetAttack(_unit); { nastavi se pouze pro MoveStatus =8,16,32,64 }
     bebex:=20010;
     MovementAddingPhase:=0;
     if ((CheckGroupMoveDistance) and
         (MoveStatus <> 1)) then Inc(GroupMoveSteps);

     if ((GroupMoveSteps >= MaxGroupMoveSteps) or (Stop_)) then begin
        bebex:=20011;
        if ((MoveStatus > 1) and (not Return_to_base))
        then Stop_unit(_unit,False,False)
        else Stop_unit(_unit,False,True);
     end;
     bebex:=20012;

     { nastaveni viditelnosti }
     Eras:=False;
     {X}
     bebex:=20013; save1:=IPos; save2:=JPos; bebey:=Direction;
     case (Direction) of
    { zrusi priznaky obsazenosti na polickach, ktere jednotka prave opustila }
       1 : begin { vlevo nahoru \ }
              Set_place(IPos, JPos+1, _unit, False,False);
              Set_place(IPos+1, JPos, _unit, False,False);
              Set_place(IPos+1, JPos+1, _unit, False,True);
              {SetFog2(IPos+1,JPos+1,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       2 : begin { nahoru | }
              Set_place(IPos, JPos+1, _unit, False, True);
              {SetFog2(IPos,JPos+1,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       4 : begin { vpravo nahoru / }
              Set_place(IPos, JPos+1, _unit, False,False);
              Set_place(IPos-1, JPos, _unit, False,False);
              Set_place(IPos-1, JPos+1, _unit, False, True);
              {SetFog2(IPos-1,JPos+1,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       8 : begin { vpravo - }
              Set_place(IPos-1, JPos, _unit, False, True);
              {SetFog2(IPos-1,JPos,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       16 : begin { vpravo dolu \ }
              Set_place(IPos, JPos-1, _unit, False,False);
              Set_place(IPos-1, JPos, _unit, False,False);
              Set_place(IPos-1, JPos-1, _unit, False, True);
              {SetFog2(IPos-1,JPos-1,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       32 : begin { dolu | }
              Set_place(IPos, JPos-1, _unit, False, True);
              {SetFog2(IPos,JPos-1,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       64 : begin { vlevo dolu / }
              Set_place(IPos, JPos-1, _unit, False,False);
              Set_place(IPos+1, JPos, _unit, False,False);
              Set_place(IPos+1, JPos-1, _unit, False, True);
              {SetFog2(IPos+1,JPos-1,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
       128 : begin { vlevo - }
              Set_place(IPos+1, JPos, _unit, False, True);
              {SetFog2(IPos+1,JPos,IPos,JPos,Unit_types[UnitType].Sight,Races[Race].Friend[MyRace],False);{}
           end;
     end; { case }
   end;

   bebex:=20100;
   if ((XOffset = 0) and (YOffset = 0) and
       (WayPointUk <= MaxWayPoint) and
       (IPos = WayPoint[WayPointUk].IAim) and
       (JPos = WayPoint[WayPointUk].JAim))
   then begin { jsme v cili ! }
      bebex:=20101;
      I:=WayPointUk; J:=WayPointMax;
      if ((Move_target_level = 0) and (TargetType = 3)) then begin
         bebex:=20102;
         Stop_unit(_unit,True,True);
      end else
         Stop_unit(_unit,False,True);
      bebex:=20103;
      Draw_unit(_unit);
      bebex:=20104;
      if (not Return_to_base) then begin
         bebex:=20105;
         WayPointUk:=I; WayPointMax:=J;
         Inc(WayPointUk);
         if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
             (WayPointMax = 255)) then begin
         { konec cesty }
            WayPointUk:=255; WayPointMax:=255;
         end else begin
         { pokracuj na dalsi waypoint }
           bebex:=20106;
           Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                         _unit,WayPoint[WayPointUk].Level,False,False);

         end;
      end;
      bebex:=20107;
   end else Draw_unit(_unit){};
 end; { with }
end;

{ ***** }
procedure Best_direction2(IPos, JPos, IAim, JAim : Integer);
{ pro jednotku na pozici IPos, JPos zjisti optimalni natoceni
  na cilove pole IAim, JAim; nastavuje primo polozky pole Dir
  (cim mensi cislo, tim lepsi)
}
var Pom, Right : Byte;
    XDistance, YDistance : Word;
    Slash : Boolean;
begin
{ inicializace pole s vahami }
   XDistance:=abs(Integer(IPos) - Integer(IAim));
   YDistance:=abs(Integer(JPos) - Integer(JAim));
   Slash:=(abs(Integer(XDistance) - Integer(YDistance)) <
           ((XDistance + YDistance) div 2));
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

   { nyni se zjisti, zda je mozne preferovat smer vice vpravo od idealniho
     nebo spise vice vlevo :
     Right = 0 .. vlevo
     Right = 1 .. ani jeden
     Right = 2 .. vpravo
   }
   case (Pom) of
     1   :  { vlevo nahoru }
            if (XDistance = YDistance) then Right:=1
            else if (XDistance < YDistance) then Right:=2
                 else Right:=0;
     2   :  { nahoru }
            if (IPos = IAim) then Right:=1
            else if (IPos < IAim) then Right:=2
                 else Right:=0;
     4   :  { vpravo nahoru }
            if (XDistance = YDistance) then Right:=1
            else if (XDistance < YDistance) then Right:=0
                 else Right:=2;
     8   :  { vpravo }
            if (JPos = JAim) then Right:=1
            else if (JPos < JAim) then Right:=2
                 else Right:=0;
     16  :  { vpravo dolu }
            if (XDistance = YDistance) then Right:=1
            else if (XDistance < YDistance) then Right:=2
                 else Right:=0;
     32  :  { dolu }
            if (IPos = IAim) then Right:=1
            else if (IPos < IAim) then Right:=0
                 else Right:=2;
     64  :  { vlevo dolu }
            if (XDistance = YDistance) then Right:=1
            else if (XDistance < YDistance) then Right:=0
                 else Right:=2;
     128 :  { vlevo }
            if (JPos = JAim) then Right:=1
            else if (JPos < JAim) then Right:=0
                 else Right:=2;
   end;

   { nastaveni Dir }
   Dir[Pom]:=0; { cim mensi cislo, tim lepsi }
   asm ror Pom,1; end;
   if (Right <= 1) then Dir[Pom]:=1 else Dir[Pom]:=2;
   asm rol Pom,2; end; Dir[Pom]:=1;
   if (Right >= 1) then Dir[Pom]:=1 else Dir[Pom]:=2;
   asm ror Pom,3; end;
   if (Right <= 1) then Dir[Pom]:=3 else Dir[Pom]:=4;
   asm rol Pom,4; end;
   if (Right >= 1) then Dir[Pom]:=3 else Dir[Pom]:=4;
   asm ror Pom,5; end;
   if (Right <= 1) then Dir[Pom]:=5 else Dir[Pom]:=6;
   asm rol Pom,6; end;
    if (Right >= 1) then Dir[Pom]:=5 else Dir[Pom]:=6;
   asm ror Pom,7; end; Dir[Pom]:=7; {}
end;

{ ***** }
procedure Compute_best_direction(IThis,JThis,ITar,JTar:Word; var _unit:PUnit);
{ od pozice IThis, JThis prohledava do vzdalenosti
  ve vsech smerech moznost pristupu a dle toho nastavuje pole Place
  pro vyuziti procedurou Move2
}
var Distance:Word;
    Plac:array[0..MaxDist,0..MaxDist] of record
            Distanc:Word;
            XOrigin, YOrigin, Steps:Word;
         end;
    ISize,JSize,I,J,K,IPom, JPom:Word;
    XW1,YW1,XW2,YW2,X1,Y1,X2,Y2,X,Y,Pom1,Pom2,Pom3,Pom4,PomX,PomY:Word;
    PomDir, PomDir2:Byte;
    Dist, Dist2:Word;
    Depth:Word;

function Inside(I,J,Depth:Word; Dir:Byte):Boolean;
{ mejme obdelnik, ktery ma stranu 2*Depth+1; Obdelnik je rozdelen, primkou,
  k niz je kolmy smer Dir; lezi dana souradnice I,J v teto polovine?
}
begin
   case (Dir) of
     1   : begin
              if ((I+J) < (2*Depth)) then Inside:=True else Inside:=False;
           end;
     2   : begin
              if (J < Depth) then Inside:=True else Inside:=False;
           end;
     4   : begin
              if (I > J) then Inside:=True else Inside:=False;
           end;
     8   : begin
              if (I > Depth) then Inside:=True else Inside:=False;
           end;
     16  : begin
              if ((I+J) > (2*Depth)) then Inside:=True else Inside:=False;
           end;
     32  : begin
              if (J > Depth) then Inside:=True else Inside:=False;
           end;
     64  : begin
              if (J > I) then Inside:=True else Inside:=False;
           end;
     128 : begin
              if (I < Depth) then Inside:=True else Inside:=False;
           end;
   else
     Inside:=False;
   end;
end;
{ * }
begin
  ISize:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].IUnitSize;
  JSize:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].JUnitSize;

  Depth:=MaxDepth;
  if (_unit^.GoInside) then Depth:=1;
  if (_unit^.MoveStatus > 1) then Depth:=AttackDepth;
  Distance:=Depth;

  {if (_unit^.CheckGroupMoveDistance) then Distance:=1;
  { orezani prohledavaciho okoli o pripadne okraje obrazovky }
  if ((IThis) < Distance) then Distance:=IThis;
  if ((JThis) < Distance) then Distance:=JThis;
  if ((IThis+Distance) > IMax) then Distance:=IMax-IThis;
  if ((JThis+Distance) > JMax) then Distance:=JMax-JThis;

  if (Distance <= 1) then begin
  {* OTESTOVANI DOSTUPNOSTI VSECH SMERU *}
     if ((IThis > 0) and (JThis > 0)) then begin { ok, mozno VLEVO NAHORU }
       if (not Free_place3(IThis-1, JThis-1, ISize, JSize,_unit)) then Place[1]:=65535
       else Place[1]:=GetDistance(IThis-1, JThis-1, ITar, JTar);
       FreePlace2[1]:=Free_place4(IThis-1, JThis-1, ISize, JSize,_unit);
     end else Place[1]:=65535;
     if (JThis > 0) then begin { ok, mozno NAHORU }
       if (not Free_place3(IThis, JThis-1, ISize, JSize,_unit)) then Place[2]:=65535
       else Place[2]:=GetDistance(IThis, JThis-1, ITar, JTar);
       FreePlace2[2]:=Free_place4(IThis, JThis-1, ISize, JSize,_unit);
     end else Place[2]:=65535;
     if ((IThis < IMax) and (JThis > 0)) then begin { ok, mozno VPRAVO NAHORU }
       if (not Free_place3(IThis+1, JThis-1, ISize, JSize,_unit)) then Place[4]:=65535
       else Place[4]:=GetDistance(IThis+1, JThis-1, ITar, JTar);
       FreePlace2[4]:=Free_place4(IThis+1, JThis-1, ISize, JSize,_unit);
     end else Place[4]:=65535;
     if (IThis < IMax) then begin { ok, VPRAVO }
       if (not Free_place3(IThis+1, JThis, ISize, JSize,_unit)) then Place[8]:=65535
       else Place[8]:=GetDistance(IThis+1, JThis, ITar, JTar);
       FreePlace2[8]:=Free_place4(IThis+1, JThis, ISize, JSize,_unit);
     end else Place[8]:=65535;
     if ((IThis < IMax) and (JThis < JMax)) then begin { ok, mozno VPRAVO DOLU }
       if (not Free_place3(IThis+1, JThis+1, ISize, JSize,_unit)) then Place[16]:=65535
       else Place[16]:=GetDistance(IThis+1, JThis+1, ITar, JTar);
       FreePlace2[16]:=Free_place4(IThis+1, JThis+1, ISize, JSize,_unit);
     end else Place[16]:=65535;
     if (JThis < JMax) then begin { DOLU }
       if (not Free_place3(IThis, JThis+1, ISize, JSize,_unit)) then Place[32]:=65535
       else Place[32]:=GetDistance(IThis, JThis+1, ITar, JTar);
       FreePlace2[32]:=Free_place4(IThis, JThis+1, ISize, JSize,_unit);
     end else Place[32]:=65535;
     if ((IThis > 0) and (JThis < JMax)) then begin { VLEVO DOLU }
       if (not Free_place3(IThis-1, JThis+1, ISize, JSize,_unit)) then Place[64]:=65535
       else Place[64]:=GetDistance(IThis-1, JThis+1, ITar, JTar);
       FreePlace2[64]:=Free_place4(IThis-1, JThis+1, ISize, JSize,_unit);
     end else Place[64]:=65535;
     if (IThis > 0) then begin { VLEVO }
       if (not Free_place3(IThis-1, JThis, ISize, JSize,_unit)) then Place[128]:=65535
       else Place[128]:=GetDistance(IThis-1, JThis, ITar, JTar);
       FreePlace2[128]:=Free_place4(IThis-1, JThis, ISize, JSize,_unit);
     end else Place[128]:=65535;
  end else begin { prohledavani sirsi }
  { xxxxxxxxxx }
     PomDir:=_unit^.Direction; asm rol PomDir,4; end;
     { vymezime "penalizovane" smery; jsou to ty, ktere jsou opacne
       k aktualnimu pohybu +- 1 smer }
     if (_unit^.First_mov) then PomDir:=0;
     Dist2:=GetDistance(IThis,JThis,ITar,JTar);
     { Dist2 = vzdalenost aktualni pozice od cile }
     X1:=IThis-Distance;Y1:=JThis-Distance;
     X2:=IThis+Distance;Y2:=JThis+Distance;
     XW1:=1; YW1:=1; XW2:=X2-X1-1; YW2:=Y2-Y1-1;
     { nejprve cele pole Plac naplnime hodnotami }
     for J:=0 to (Y2-Y1) do
       for I:=0 to (X2-X1) do with (Plac[I,J]) do begin
          IPom:=I+X1; JPom:=J+Y1;
          if (not Free_place3(IPom,JPom,ISize,JSize,_unit))
          then Distanc:=65535
          else begin
             Distanc:=GetDistance(IPom,JPom,ITar,JTar);
             { nyni penalizace nezadoucich smeru }
              if (Inside(I,J,Depth,PomDir)) then begin
                 if (Dist2 > Distanc) then begin
                   Distanc:=Dist2;
                 end;
              end;{}
          end;
          XOrigin:=IPom; YOrigin:=JPom; Steps:=0;
       end;

     { nyni VLASTNI ALGORITMUS }
     { xxxxx }

     for K:=1 to (Distance-1) do begin
     { projiti vsech vnitrnich oblasti }
        { ** HORNI CARA ** }
        for I:=XW1 to (XW2-1) do with (Plac[I,YW1]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
            if (Plac[I-1,YW1].Distanc < Plac[I,YW1-1].Distanc) then begin
              if (Plac[I-1,YW1].Distanc < 65535) then
                Distanc:=Plac[I-1,YW1].Distanc else Distanc:=65000;
              XOrigin:=Plac[I-1,YW1].XOrigin; YOrigin:=Plac[I-1,YW1].YOrigin;
              Steps:=Plac[I-1,YW1].Steps; Inc(Steps);
            end else begin
              if (Plac[I,YW1-1].Distanc < 65535) then
                Distanc:=Plac[I,YW1-1].Distanc else Distanc:=65000;
              XOrigin:=Plac[I,YW1-1].XOrigin; YOrigin:=Plac[I,YW1-1].YOrigin;
              Steps:=Plac[I,YW1-1].Steps; Inc(Steps);
            end;
        end; { for }

        { ** PRAVY HORNI ROH ** }
        if ((Plac[XW2,YW1].Distanc < 65535) and (Plac[XW2,YW1].Distanc > 0)) then begin
          Pom1:=Plac[XW2,YW1-1].Distanc; Pom2:=Plac[XW2+1,YW1].Distanc;
          Pom3:=Plac[XW2-1,YW1].Distanc;
          if ((Pom1 <= Pom2) and (Pom1 <= Pom3)) then with (Plac[XW2,YW1]) do begin
             if (Pom1 < 65535) then
                Distanc:=Pom1 else Distanc:=65000;
             XOrigin:=Plac[XW2,YW1-1].XOrigin; YOrigin:=Plac[XW2,YW1-1].YOrigin;
             Steps:=Plac[XW2,YW1-1].Steps; Inc(Steps);
          end else
            if ((Pom2 <= Pom1) and (Pom2 <= Pom3)) then with (Plac[XW2,YW1]) do begin
              if (Pom2 < 65535) then
                Distanc:=Pom2 else Distanc:=65000;
              XOrigin:=Plac[XW2+1,YW1].XOrigin; YOrigin:=Plac[XW2+1,YW1].YOrigin;
              Steps:=Plac[XW2+1,YW1].Steps; Inc(Steps);
            end else with (Plac[XW2,YW1]) do begin
              if (Pom3 < 65535) then
                Distanc:=Pom3 else Distanc:=65000;
              XOrigin:=Plac[XW2-1,YW1].XOrigin; YOrigin:=Plac[XW2-1,YW1].YOrigin;
              Steps:=Plac[XW2-1,YW1].Steps; Inc(Steps);
            end;
        end;

        { ** LEVA CARA ** }
        for J:=YW1+1 to (YW2-1) do with (Plac[XW1,J]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
             if (Plac[XW1,J-1].Distanc < Plac[XW1-1,J].Distanc) then begin
               if (Plac[XW1,J-1].Distanc < 65535) then
                 Distanc:=Plac[XW1,J-1].Distanc else Distanc:=65000;
               XOrigin:=Plac[XW1,J-1].XOrigin; YOrigin:=Plac[XW1,J-1].YOrigin;
               Steps:=Plac[XW1,J-1].Steps; Inc(Steps);
             end else begin
               if (Plac[XW1-1,J].Distanc < 65535) then
                 Distanc:=Plac[XW1-1,J].Distanc else Distanc:=65000;
               XOrigin:=Plac[XW1-1,J].XOrigin; YOrigin:=Plac[XW1-1,J].YOrigin;
               Steps:=Plac[XW1-1,J].Steps; Inc(Steps);
             end;
        end; { for }

        { ** PRAVA CARA ** }
        for J:=YW1+1 to (YW2-1) do with (Plac[XW2,J]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
             if (Plac[XW2,J-1].Distanc < Plac[XW2+1,J].Distanc) then begin
               if (Plac[XW2,J-1].Distanc < 65535) then
                  Distanc:=Plac[XW2,J-1].Distanc else Distanc:=65000;
               XOrigin:=Plac[XW2,J-1].XOrigin; YOrigin:=Plac[XW2,J-1].YOrigin;
               Steps:=Plac[XW2,J-1].Steps; Inc(Steps);
             end else begin
               if (Plac[XW2+1,J].Distanc < 65535) then
                  Distanc:=Plac[XW2+1,J].Distanc else Distanc:=65000;
               XOrigin:=Plac[XW2+1,J].XOrigin; YOrigin:=Plac[XW2+1,J].YOrigin;
               Steps:=Plac[XW2+1,J].Steps; Inc(Steps);
             end;
        end; { for }

        { ** LEVY DOLNI ROH ** }
        if ((Plac[XW1,YW2].Distanc < 65535) and (Plac[XW1,YW2].Distanc > 0)) then begin
          Pom1:=Plac[XW1-1,YW2].Distanc; Pom2:=Plac[XW1,YW2+1].Distanc;
          Pom3:=Plac[XW1,YW2-1].Distanc;
          if ((Pom1 <= Pom2) and (Pom1 <= Pom3)) then with (Plac[XW1,YW2]) do begin
             if (Pom1 < 65535) then
                Distanc:=Pom1 else Distanc:=65000;
             XOrigin:=Plac[XW1-1,YW2].XOrigin; YOrigin:=Plac[XW1-1,YW2].YOrigin;
             Steps:=Plac[XW1-1,YW2].Steps; Inc(Steps);
          end else
            if ((Pom2 <= Pom1) and (Pom2 <= Pom3)) then with (Plac[XW1,YW2]) do begin
              if (Pom2 < 65535) then
                 Distanc:=Pom2 else Distanc:=65000;
              XOrigin:=Plac[XW1,YW2+1].XOrigin; YOrigin:=Plac[XW1,YW2+1].YOrigin;
              Steps:=Plac[XW1,YW2+1].Steps; Inc(Steps);
            end else with (Plac[XW1,YW2]) do begin
              if (Pom3 < 65535) then
                 Distanc:=Pom3 else Distanc:=65000;
              XOrigin:=Plac[XW1,YW2-1].XOrigin; YOrigin:=Plac[XW1,YW2-1].YOrigin;
              Steps:=Plac[XW1,YW2-1].Steps; Inc(Steps);
            end;
        end;

        { ** SPODNI CARA ** }
        for I:=XW1+1 to (XW2-1) do with (Plac[I,YW2]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
            if (Plac[I-1,YW2].Distanc < Plac[I,YW2+1].Distanc) then begin
              if (Plac[I-1,YW2].Distanc < 65535) then
                 Distanc:=Plac[I-1,YW2].Distanc else Distanc:=65000;
              XOrigin:=Plac[I-1,YW2].XOrigin; YOrigin:=Plac[I-1,YW2].YOrigin;
              Steps:=Plac[I-1,YW2].Steps; Inc(Steps);
            end else begin
              if (Plac[I,YW2+1].Distanc < 65535) then
                  Distanc:=Plac[I,YW2+1].Distanc else Distanc:=65000;
              XOrigin:=Plac[I,YW2+1].XOrigin; YOrigin:=Plac[I,YW2+1].YOrigin;
              Steps:=Plac[I,YW2+1].Steps; Inc(Steps);
            end;
        end; { for }

        { ** PRAVY DOLNI ROH ** }
        if ((Plac[XW2,YW2].Distanc < 65535) and (Plac[XW2,YW2].Distanc > 0)) then begin
          Pom1:=Plac[XW2,YW2+1].Distanc; Pom2:=Plac[XW2+1,YW2].Distanc;
          Pom3:=Plac[XW2,YW2-1].Distanc; Pom4:=Plac[XW2-1,YW2].Distanc;
          if (Pom1 < Pom2) then PomX:=Pom1 else PomX:=Pom2;
          if (Pom3 < Pom4) then PomY:=Pom3 else PomY:=Pom4;
          if (PomY < PomX) then PomX:=PomY;
          with (Plac[XW2,YW2]) do begin
             if (PomX < 65535) then
                 Distanc:=PomX else Distanc:=65000;
             if (PomX = Pom1) then begin
                XOrigin:=Plac[XW2,YW2+1].XOrigin;
                YOrigin:=Plac[XW2,YW2+1].YOrigin;
                Steps:=Plac[XW2,YW2+1].Steps; Inc(Steps);
             end else
               if (PomX = Pom2) then begin
                  XOrigin:=Plac[XW2+1,YW2].XOrigin;
                  YOrigin:=Plac[XW2+1,YW2].YOrigin;
                  Steps:=Plac[XW2+1,YW2].Steps; Inc(Steps);
               end else
                 if (PomX = Pom3) then begin
                    XOrigin:=Plac[XW2,YW2-1].XOrigin;
                    YOrigin:=Plac[XW2,YW2-1].YOrigin;
                    Steps:=Plac[XW2,YW2-1].Steps; Inc(Steps);
                 end else begin
                   XOrigin:=Plac[XW2-1,YW2].XOrigin;
                   YOrigin:=Plac[XW2-1,YW2].YOrigin;
                   Steps:=Plac[XW2-1,YW2].Steps; Inc(Steps);
                 end;
          end;
        end;

        { NYNI VSE PROJDEME REVERZNE NAZPET }
        { ** PRAVA CARA ** }
        for J:=YW2-1 downto YW1 do with (Plac[XW2,J]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
             if (Plac[XW2,J+1].Distanc < Distanc) then begin
               Distanc:=Plac[XW2,J+1].Distanc;
               XOrigin:=Plac[XW2,J+1].XOrigin; YOrigin:=Plac[XW2,J+1].YOrigin;
               Steps:=Plac[XW2,J+1].Steps; Inc(Steps);
             end;
        end; { for }

        { ** SPODNI CARA ** }
        for I:=XW2-1 downto XW1 do with (Plac[I,YW2]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
            if (Plac[I+1,YW2].Distanc < Distanc) then begin
              Distanc:=Plac[I+1,YW2].Distanc;
              XOrigin:=Plac[I+1,YW2].XOrigin; YOrigin:=Plac[I+1,YW2].YOrigin;
              Steps:=Plac[I+1,YW2].Steps; Inc(Steps);
            end;
        end; { for }

        { ** HORNI CARA ** }
        for I:=XW2-1 downto XW1 do with (Plac[I,YW1]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
            if (Plac[I+1,YW1].Distanc < Distanc) then begin
              Distanc:=Plac[I+1,YW1].Distanc;
              XOrigin:=Plac[I+1,YW1].XOrigin; YOrigin:=Plac[I+1,YW1].YOrigin;
              Steps:=Plac[I+1,YW1].Steps; Inc(Steps);
            end;
        end; { for }

        { ** LEVA CARA ** }
        for J:=YW2-1 downto YW1 do with (Plac[XW1,J]) do begin
          if ((Distanc < 65535) and (Distanc > 0)) then
             if (Plac[XW1,J+1].Distanc < Distanc) then begin
               Distanc:=Plac[XW1,J+1].Distanc;
               XOrigin:=Plac[XW1,J+1].XOrigin; YOrigin:=Plac[XW1,J+1].YOrigin;
               Steps:=Plac[XW1,J+1].Steps; Inc(Steps);
             end;
        end; { for }

        Inc(XW1); Inc(YW1); Dec(XW2); Dec(YW2);
     { * }
     end; { for K:=1 to (Distance-1) do begin = projiti vsech vnitrnich oblasti }

     { xxxxx }
     { KONECNE KOPIROVANI }
     I:=Distance; J:=Distance;
     with (Plac[I-1,J-1]) do begin
       if (Distanc < 65535) then
         Place[1]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[1]:=Distanc;
     end;
     with (Plac[I,J-1]) do begin
       if (Distanc < 65535) then
         Place[2]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[2]:=Distanc;
     end;
     with (Plac[I+1,J-1]) do begin
       if (Distanc < 65535) then
         Place[4]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[4]:=Distanc;
     end;
     with (Plac[I+1,J]) do begin
       if (Distanc < 65535) then
         Place[8]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[8]:=Distanc;
     end;
     with (Plac[I+1,J+1]) do begin
       if (Distanc < 65535) then
         Place[16]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[16]:=Distanc;
     end;
     with (Plac[I,J+1]) do begin
       if (Distanc < 65535) then
         Place[32]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[32]:=Distanc;
     end;
     with (Plac[I-1,J+1]) do begin
       if (Distanc < 65535) then
         Place[64]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[64]:=Distanc;
     end;
     with (Plac[I-1,J]) do begin
       if (Distanc < 65535) then
         Place[128]:=Distanc+GetDistance(XOrigin,YOrigin,ITar,JTar)+Steps
       else Place[128]:=Distanc;
     end;
     FreePlace2[1]:=Free_place4(IThis-1, JThis-1, ISize, JSize,_unit);
     FreePlace2[2]:=Free_place4(IThis, JThis-1, ISize, JSize,_unit);
     FreePlace2[4]:=Free_place4(IThis+1, JThis-1, ISize, JSize,_unit);
     FreePlace2[8]:=Free_place4(IThis+1, JThis, ISize, JSize,_unit);
     FreePlace2[16]:=Free_place4(IThis+1, JThis+1, ISize, JSize,_unit);
     FreePlace2[32]:=Free_place4(IThis, JThis+1, ISize, JSize,_unit);
     FreePlace2[64]:=Free_place4(IThis-1, JThis+1, ISize, JSize,_unit);
     FreePlace2[128]:=Free_place4(IThis-1, JThis, ISize, JSize,_unit);
  { xxxxxxxxxx }
   _unit^.SlashDir1:=0; _unit^.SlashDir2:=0;
   if (_unit^.SlashCount  = 0) then begin
     { je-li napr. jednotka ve smeru 128 a smer 32 nebo 2 je o hodnotu
       "Depth" vyhodnejsi nez smer 64 nebo 1, lehce zvyhodnime smery
       64 nebo 1 (snazime se, aby zmeny kurzu nebyly zbytecne radikalni) }
     PomDir:=_unit^.Direction; asm rol PomDir,1; end;
     PomDir2:=_unit^.Direction; asm rol PomDir2,2; end;
     if ((Place[PomDir] >= Depth) and (Place[PomDir] > Place[PomDir2]) and
         ((Place[PomDir]-Depth) <= Place[PomDir2]))
     then begin Place[PomDir]:=Place[PomDir2]; _unit^.SlashDir1:=PomDir; end;
     PomDir:=_unit^.Direction; asm ror PomDir,1; end;
     PomDir2:=_unit^.Direction; asm ror PomDir2,2; end;
     if ((Place[PomDir] >= Depth) and (Place[PomDir] > Place[PomDir2]) and
         ((Place[PomDir]-Depth) <= Place[PomDir2]))
     then begin Place[PomDir]:=Place[PomDir2]; _unit^.SlashDir2:=PomDir; end;
     _unit^.SlashDir:=0;
   end else begin
      Dec(_unit^.SlashCount);
      if ((_unit^.SlashDir <> 0) and (Place[_unit^.SlashDir] > Depth) and
          (Place[_unit^.SlashDir] < 1000)) then with (_unit^) do begin
         Dec(Place[SlashDir],Depth);
      end;
   end;

   with (_unit^) do if (BanDir <> 0) then begin
   { zvyhodnime opacny smer nez BanDir; nutime tim jednotku, ktere byla diky
     prekazce nucena jit doleva, aby hned, jak to jde, zahnula doprava }
     PomDir:=BanDir;  asm rol PomDir,4; end;
     if ((Place[PomDir] < 1000) and (Place[PomDir] > 2)) then
       Place[PomDir]:=1;
     asm rol PomDir,1; end;
     if ((Place[PomDir] < 1000) and (Place[PomDir] > 2)) then
       Place[PomDir]:=2;
     asm ror PomDir,2; end;
     if ((Place[PomDir] < 1000) and (Place[PomDir] > 2)) then
       Place[PomDir]:=2;
   end
  { XXXXXXXXXXXX }
  end; { prohledavani sirsi nez 1 }
end;

{ ***** }
procedure Move2(IThis,JThis,ITar,JTar : Word; var Direction : Byte;
                var _unit:PUnit);
{ Procedura nastavi v poli Place u kazdeho smeru vzdalenost od cile
  vcetne zohledneni BanDir atd.
}
label Skip;
var I, J, I1, J1, ISize, JSize, PomDistance: Word;
    BestDir, PomDir, ObstacleDir:Byte;
    ScreenEnd : Boolean;

procedure SetCheckGroupMoveDistance(I,J:Word; var _unit:PUnit);
{ zjisti, zda se na danem policku nenachazi jednotka, ktera ma stejny
  cil presunu, jako jednotka dana parametrem procedury
}
begin
   with (Map^[I,J]) do with (_unit^) do begin
     if (Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 3) then begin
         { pozemni, namorni }
         if ((First_level <> 0) and (Level_type and 128 = 0))  then Temp:=1;
         {if ((First_level <> 0) and (Level_type and 128 = 0) and
             (Units[First_level]^.IAim = ITar) and
             (Units[First_level]^.JAim = JTar) and
             (Units[First_level]^.Status = 0)) then
             {CheckGroupMoveDistance:=True{};
     end else begin{}
         if (Second_level <> 0) then Temp:=1;
         { vzdusna }
         if ((Second_level <> 0) and
             (Units[Second_level]^.WayPoint[WayPointUk].IAim = ITar) and
             (Units[Second_level]^.WayPoint[WayPointUk].JAim = JTar) and
             (Units[Second_level]^.Status = 0)) then
            CheckGroupMoveDistance:=True;
     end;
   end;
end;
{ * }
begin
   ISize:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].IUnitSize;
   JSize:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].JUnitSize;

   { * NASTAVENI INICIALIZACNICH HODNOT * }
   FreePlace2[1]:=False; FreePlace2[2]:=False; FreePlace2[4]:=False;
   FreePlace2[8]:=False; FreePlace2[16]:=False; FreePlace2[32]:=False;
   FreePlace2[64]:=False; FreePlace2[128]:=False;

   {* OTESTOVANI DOSTUPNOSTI VSECH SMERU *}
   Compute_best_direction(IThis,JThis,ITar,JTar,_unit);

   {* DODATECNE OTESTOVANI SIKMYCH SMERU *}
   { vlevo nahore }
   if ((Place[2] = 65535) or (Place[128] = 65535)) then Place[1]:=65535;
   { vpravo nahore }
   if ((Place[2] = 65535) or (Place[8] = 65535)) then Place[4]:=65535;
   { vpravo dole }
   if ((Place[8] = 65535) or (Place[32] = 65535)) then Place[16]:=65535;
   { vlevo dole }
   if ((Place[32] = 65535) or (Place[128] = 65535)) then Place[64]:=65535;

   {* DODATECNE OTESTOVANI BANDIR *}
   Obstacle:=False; ScreenEnd:=False;
   ObstacleDir:=0; { pokud jednotka sikmo narazi na prekazku, zvyhodni se
   smer podel prekazky ve smeru pohybu }
      if (Place[Direction] = 65535)
      then begin
      { narazili jsme na prekazku - vynulujeme zakazany smer,
        ale jen tehdy, chceme-li v tomto smeru pokracovat
      { v pripade, se prekazkou je stojici jednotka se stejnym cilem
        jako my, tak se nastavi promenna CheckGroupMoveDistance }
      { narazime-li na okraj obrazovky, do PomDistance ulozime vzdalenost
        OD SOUCASNEHO MISTA; je-li mensi nez u ostanich smeru, t.j. vyplatil
        by se, pak jednotku otocime o 180 stupnu }
        case (Direction) of
          1  : if ((IThis > 0) and (JThis > 0)) then begin { VLEVO NAHORU }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis-1)) + abs(Integer(JTar)-Integer(JThis-1));
                 SetCheckGroupMoveDistance(IThis-1,JThis-1,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis-1,JThis,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis,JThis-1,_unit);
                 ObstacleDir:=2;
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis))+1;
                 ScreenEnd:=True;
               end;
         2  : if (JThis > 0) then begin { NAHORU }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis-1));
                 SetCheckGroupMoveDistance(IThis,JThis-1,_unit);
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis));
                 ScreenEnd:=True;
               end;
          4  : if ((IThis < IMax) and (JThis > 0)) then begin { VPRAVO NAHORU }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis+1)) + abs(Integer(JTar)-Integer(JThis-1));
                 SetCheckGroupMoveDistance(IThis,JThis-1,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis+1,JThis-1,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis+1,JThis,_unit);
                 ObstacleDir:=2;
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis))+1;
                 ScreenEnd:=True;
               end;
          8  : if (IThis < IMax) then begin { VPRAVO }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis+1)) + abs(Integer(JTar)-Integer(JThis));
                 SetCheckGroupMoveDistance(IThis+1,JThis,_unit);
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis));
                 ScreenEnd:=True;
               end;
          16 : if ((IThis < IMax) and (JThis < JMax)) then begin { VPRAVO DOLU }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis+1)) + abs(Integer(JTar)-Integer(JThis+1));
                 SetCheckGroupMoveDistance(IThis+1,JThis,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis+1,JThis+1,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis,JThis+1,_unit);
                 ObstacleDir:=32;
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis))+1;
                 ScreenEnd:=True;
               end;
          32 : if (JThis < JMax) then begin { DOLU }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis+1));
                 SetCheckGroupMoveDistance(IThis,JThis+1,_unit);
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis));
                 ScreenEnd:=True;
               end;
          64 : if ((IThis > 0) and (JThis < JMax)) then begin  { VLEVO DOLU }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis-1)) + abs(Integer(JTar)-Integer(JThis+1));
                 SetCheckGroupMoveDistance(IThis,JThis+1,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis-1,JThis+1,_unit);
                 if (not _unit^.CheckGroupMoveDistance) then SetCheckGroupMoveDistance(IThis-1,JThis,_unit);
                 ObstacleDir:=32;
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis))+1;
                 ScreenEnd:=True;
               end;
          128: if (IThis > 0) then begin { VLEVO }
                 PomDistance:=abs(Integer(ITar)-Integer(IThis-1)) + abs(Integer(JTar)-Integer(JThis));
                 SetCheckGroupMoveDistance(IThis-1,JThis,_unit);
               end else begin
                 PomDistance:=abs(Integer(ITar)-Integer(IThis)) + abs(Integer(JTar)-Integer(JThis));
                 ScreenEnd:=True;
               end;
        end;

        { nyni otestuj, zda-li by pro jednotku bylo
        skutecne nejvyhodnejsi pokracovat smerem do prekazky; potom
        nastav BanDir }
        if (_unit^.Temp = 1) then _unit^.Temp:=0
          { prekazka je jednotka - neplati BanDir }
        else begin
          Ban1:=Direction; Ban2:=Direction; { promenne Banx jsou nyni pomocne }
          asm rol Ban1,1; rol Ban2,2; end;
          if ((PomDistance < Place[Ban1]) and (PomDistance < Place[Ban2])) then begin
             Ban1:=Direction; Ban2:=Direction; { promenne Banx jsou nyni pomocne }
             asm ror Ban1,1; ror Ban2,2; end;
             if ((PomDistance < Place[Ban1]) and (PomDistance < Place[Ban2])) then begin
                Obstacle:=True; _unit^.BanDir:=0;
                if (ScreenEnd) then begin
                  { jde o konec obrazovky, doporuc otocit jednotku o 180 stupnu }
                  Ban1:=Direction; { promenna Ban1 je nyni pomocna }
                  asm rol Ban1,4 end; Place[Ban1]:=1; Direction:=Ban1;
                 _unit^.BanDir:=0;
                end;
             end;
          end;
        end;

      end; { if (Place[Direction] = 65535) }
      { nastaveni BanDir }
      if (_unit^.BanDir <> 0) then begin
         Ban1:=_unit^.BanDir; Ban2:=_unit^.BanDir; Ban3:=_unit^.BanDir;
         asm ror Ban1,1 end; asm rol Ban3,1 end;
         if (((Ban1 = 1) or (Ban2 = 1) or (Ban3 = 1)) and (Place[1] < 65535))
         then Place[1]:=65534;
         if (((Ban1 = 2) or (Ban2 = 2) or (Ban3 = 2)) and (Place[2] < 65535))
         then Place[2]:=65534;
         if (((Ban1 = 4) or (Ban2 = 4) or (Ban3 = 4)) and (Place[4] < 65535))
         then Place[4]:=65534;
         if (((Ban1 = 8) or (Ban2 = 8) or (Ban3 = 8)) and (Place[8] < 65535))
         then Place[8]:=65534;
         if (((Ban1 = 16) or (Ban2 = 16) or (Ban3 = 16)) and (Place[16] < 65535))
         then Place[16]:=65534;
         if (((Ban1 = 32) or (Ban2 = 32) or (Ban3 = 32)) and (Place[32] < 65535))
         then Place[32]:=65534;
         if (((Ban1 = 64) or (Ban2 = 64) or (Ban3 = 64)) and (Place[64] < 65535))
         then Place[64]:=65534;
         if (((Ban1 = 128) or (Ban2 = 128) or (Ban3 = 128)) and (Place[128] < 65535))
         then Place[128]:=65534;
      end else begin
         Ban1:=0; Ban2:=0; Ban3:=0;
      end;

   {* ZAJISTENI, ABY SE JEDNOTKA ZBYTECNE NEVRACELA NA MINULE POLICKO *}
   if (Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].UnitLevel = 3) then GoTo Skip;
   PomDir:=Direction; asm rol PomDir,4; end;
   PomDistance:=Place[PomDir];
   { v PomDir je smer opacny k aktualnimu pohybu }
   if ((Place[PomDir] < 65534) and (not _unit^.First_mov)) then begin
   { nejprve shora }
     if ((Place[PomDir] > 0) and FreePlace2[PomDir]) then
        Place[PomDir]:=65532;
     asm rol PomDir,1; end;
     if ((Place[PomDir] < 65534) and (Place[PomDir] > 0) and
         (Place[PomDir] >= (PomDistance)) and FreePlace2[PomDir]) then begin
        Place[PomDir]:=65533;
        asm rol PomDir,1; end;
        if ((Place[PomDir] < 65534) and  (Place[PomDir] > 0) and
            (Place[PomDir] >= (PomDistance)) and FreePlace2[PomDir]) then begin
           Place[PomDir]:=65531;
           asm rol PomDir,1; end;
           if ((Place[PomDir] < 65534) and  (Place[PomDir] > 0) and
               (Place[PomDir] >= (PomDistance)) and FreePlace2[PomDir]) then begin
              Place[PomDir]:=65533;
           end;
        end;
     end;

     { nyni zdola }
     PomDir:=Direction; asm rol PomDir,4; end;
     if ((Place[PomDir] > 0) and FreePlace2[PomDir]) then
        Place[PomDir]:=65532;
     asm ror PomDir,1; end;
     if ((Place[PomDir] < 65534) and (Place[PomDir] > 0) and
         (Place[PomDir] >= (PomDistance)) and FreePlace2[PomDir]) then begin
        Place[PomDir]:=65533;
        asm ror PomDir,1; end;
        if ((Place[PomDir] < 65534) and (Place[PomDir] > 0) and
            (Place[PomDir] >= (PomDistance)) and FreePlace2[PomDir]) then begin
           Place[PomDir]:=65531;
           asm ror PomDir,1; end;
           if ((Place[PomDir] < 65534) and (Place[PomDir] > 0) and
               (Place[PomDir] >= (PomDistance)) and
               FreePlace2[PomDir]) then begin
               Place[PomDir]:=65533;
           end;
        end;
     end;
   end; { if (PomDistance] < 65534) then }
   if ((ObstacleDir > 0) and (Place[ObstacleDir] > 7) and
       (Place[ObstacleDir] < 65535))
   then  Dec(Place[ObstacleDir],7);
Skip:

   {* ZJISTENI BESTDIR *}
   if (Obstacle) then Best_direction2(IThis, JThis, ITarg, JTarg)
   else Best_direction2(IThis, JThis, ITarg, JTarg);
end;

{ ***** }
function PomSearch(IThis,JThis : Word; PomDirection : Byte; _unit:PUnit;
                   var Distance:Word):Boolean;
{ provede prohledavani v aktualnim smeru PomDirection (viz fce Move)
}
var Pom : Boolean;
    ITar, JTar:Word;
begin
  Pom:=False;

  with _unit^ do begin
    ITar:=WayPoint[WayPointUk].IAim; JTar:=WayPoint[WayPointUk].JAim;
    case (PomDirection) of
        1 : begin  { vlevo nahoru }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis-1,JThis-1,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis-1,JThis-1,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
        2 : begin  { nahoru }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis,JThis-1,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis,JThis-1,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
        4 : begin  { vpravo nahoru }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis+1,JThis-1,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis+1,JThis-1,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
        8 : begin  { vpravo }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis+1,JThis,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis+1,JThis,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
       16 : begin  { vpravo dolu }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis+1,JThis+1,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis+1,JThis+1,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
       32 : begin  { dolu }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis,JThis+1,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis,JThis+1,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
       64 : begin  { vlevo dolu }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis-1,JThis+1,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis-1,JThis+1,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
      128 : begin  { vlevo }
                  Distance:=Place[PomDirection];
                  if (Distance < 65535) then begin
                  { testovani probehlo uspesne, zkus je zaznamenat }
                      if (WeightMoveDir > Distance) then begin
                      { optimalni reseni }
                         MoveDir:=PomDirection;
                         WeightMoveDir:=Distance;
                         RealDistance:=GetDistance(IThis-1,JThis,ITar,JTar);
                      end else
                        if ((WeightMoveDir = Distance) and
                            (WeightMoveDir > 0)) then begin
                        { vybere se ten smer, ktery je blizsi cili nebo
                          ten, ktery predstavuje zmenu oproti soucasnemu }
                          if ((Dir[PomDirection] < Dir[MoveDir]) or
                              (Dir[PomDirection] = Dir[MoveDir]) and
                              (MoveDir = Direction)) then begin
                          { novy smer je blizsi cili }
                             MoveDir:=PomDirection; {}
                             RealDistance:=GetDistance(IThis-1,JThis,ITar,JTar);
                          end;
                        end;
                      Pom:=True;
                  end;
                  Distance:=WeightMoveDir;
            end;
      end; { case }
  end; { with }
  PomSearch:=Pom;
end;

{ ***** }
function Move(IThis,JThis,ITar,JTar : Word; Direction : Byte;
              var _unit:PUnit; var Distance:Word):Boolean;
{ funkce propatrava cestu jednotky _unit z uzlu IThis, JThis do
  uzlu ITar, JTar; zacina smerem Direction a zkousi vejirovite dalsi
  varianty; celkem 2 smery vlevo a 2 vpravo  ( _ \ | / _ )
                                                   ^Direction
  funkce vraci True, byla-li cesta nalezena, jinak false;
  Distance znamena soucet X-ove a Y-ove vzdalenosti od cile; vybira se
  varianta nejlepsi ( s nejmensi Distance )
}
label Konec;
var PomDirection, PomDirection2:Byte;
    Result:Boolean;
    BestDir:Byte;
    PomDistance:Word;
begin
 PomDirection:=Direction; Result:=False;
 with (_unit^) do begin
   ITarg:=ITar;
   JTarg:=JTar;
   XUnSize:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
   YUnSize:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
   PomDistance:=GetDistance(IThis,JThis,ITar,JTar);
   if (GroupMove and (PomDistance <= 2) and (not GoInside))
   then CheckGroupMoveDistance:=True
   else
     if (GroupMove and (PomDistance <= 1) and GoInside) then
       CheckGroupMoveDistance:=True;

   if (GoInside and (abs(Integer(ITar)-Integer(IThis)) <=1) and
       (abs(Integer(JTar)-Integer(JThis)) <=1) and (XOffset = 0) and
       (YOffset = 0)) then begin
      Distance:=0;
      GoTo Konec;
   end;

   Move2(IThis,JThis,ITarg,JTarg,PomDirection,_unit);

   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,1; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm rol PomDirection,2; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,3; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm rol PomDirection,4; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,5; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm rol PomDirection,6; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,7; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   Move:=Result;
   if (CheckGroupMoveDistance and GroupMove and
       (PomDistance < RealDistance) and (MoveStatus <> 1))
   then begin
      Move:=False; Goto Konec;
   end;

   if ((Obstacle) and (not First_mov)) then begin
   { jednotka nyni kvuli prekazce zatocila; dokud nenarazi znova na
     prekazku nebo nezmeni smer, zakaze se ji dalsi otoceni v tomto
     smyslu (mohla by se vracet a cyklit)
   }
      if (((MoveDir = 128) or (MoveDir = 8))
           and (Direction = 2)) then
        BanDir:=32
      else
       if (((MoveDir = 128) or (MoveDir = 8))
            and (Direction = 32)) then
         BanDir:=2
       else
         if (((MoveDir = 2) or (MoveDir = 32))
           and (Direction = 128)) then
           BanDir:=8
         else
           if (((MoveDir = 2) or (MoveDir = 32))
              and (Direction = 8)) then
              BanDir:=128
           else _unit^.BanDir:=0;

      PomDirection:=MoveDir; asm rol PomDirection,4 end;
      if (PomDirection = Direction) then begin
      { vyjimka - pri otoceni o 180 stupnu se nic nezakaze }
        BanDir:=0;
      end;
   end else begin
   { natoceni jednotky na jiny nez puvodni smer; pokud je jednotka
     natocena smerem k cili \ | / , zrus zakazany smer, jinak ne }
     if (BanDir <> 0) then begin
       BestDir:=Best_direction(IThis, JThis, ITarg, JTarg);
       if (MoveDir <> Direction) then
          if (MoveDir = BestDir) then BanDir:=0
          else begin
             asm rol BestDir,1; end;
             if (MoveDir = BestDir) then BanDir:=0
             else begin
               asm ror BestDir,2; end;
               if (MoveDir = BestDir) then BanDir:=0
               else begin { BanDir plati - upravime jej pro novy smer }
                  BestDir:=MoveDir; PomDirection:=BanDir;
                  while (BestDir <> Direction) do
                     asm ror BestDir,1; rol PomDirection,1; end;
                  BanDir:=PomDirection;
               end;{}
             end;
          end;
     end; { if (_unit^.BanDir <> 0) }
   end;
 end; { with }
Konec:
end;

{ ***** }
function Move_air_unit(IThis,JThis,ITar,JTar : Word; Direction : Byte;
                       _unit:PUnit; var Distance:Word):Boolean;
{ funkce propatrava cestu jednotky _unit z uzlu IThis, JThis do
  uzlu ITar, JTar; zacina smerem Direction a zkousi vejirovite dalsi
  varianty; celkem 2 smery vlevo a 2 vpravo  ( _ \ | / _ )
                                                   ^Direction
  funkce vraci True, byla-li cesta nalezena, jinak false;
  Distance znamena soucet X-ove a Y-ove vzdalenosti od cile; vybira se
  varianta nejlepsi ( s nejmensi Distance )
}
label Konec;
var PomDirection, PomDirection2:Byte;
    Result:Boolean;
    BestDir:Byte;
    PomDistance:Word;
begin
 PomDirection:=Direction; Result:=False;
 with (_unit^) do begin
   ITarg:=ITar;
   JTarg:=JTar;
   XUnSize:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
   YUnSize:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
   PomDistance:=GetDistance(IThis,JThis,ITar,JTar);
   if (GroupMove and (PomDistance <= 1)) then CheckGroupMoveDistance:=True;

   if (GoInside and (abs(Integer(ITar)-Integer(IThis)) <=1) and
       (abs(Integer(JTar)-Integer(JThis)) <=1) and (XOffset = 0) and
       (YOffset = 0)) then begin
      Distance:=0;
      GoTo Konec;
   end;

   Move2(IThis,JThis,ITarg,JTarg,PomDirection,_unit);

   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,1; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm rol PomDirection,2; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,3; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm rol PomDirection,4; end;
   Result:=PomSearch(IThis,JThis,PomDirection,_unit,Distance) or Result;
   asm ror PomDirection,5; end;
   Result:=Result or PomSearch(IThis,JThis,PomDirection,_unit,Distance);
   asm rol PomDirection,6; end;
   Result:=Result or PomSearch(IThis,JThis,PomDirection,_unit,Distance);
   asm ror PomDirection,7; end;
   Result:=Result or PomSearch(IThis,JThis,PomDirection,_unit,Distance);
   Move_air_unit:=Result;
   if (CheckGroupMoveDistance and GroupMove and
      (PomDistance < RealDistance) and (MoveStatus <> 1))
   then begin
      Move_air_unit:=False; Goto Konec;
   end;

   begin
   { natoceni jednotky na jiny nez puvodni smer; pokud je jednotka
     natocena smerem k cili \ | / , zrus zakazany smer, jinak ne }
     if (BanDir <> 0) then begin
       BestDir:=Best_direction(IThis, JThis, ITarg, JTarg);
       if (MoveDir <> Direction) then
          if (MoveDir = BestDir) then BanDir:=0
          else begin
             asm rol BestDir,1; end;
             if (MoveDir = BestDir) then BanDir:=0
             else begin
               asm ror BestDir,2; end;
               if (MoveDir = BestDir) then BanDir:=0
               else begin { BanDir plati - upravime jej pro novy smer }
                  BestDir:=MoveDir; PomDirection:=BanDir;
                  while (BestDir <> Direction) do
                     asm ror BestDir,1; rol PomDirection,1; end;
                  BanDir:=PomDirection;
               end;{}
             end;
          end;
     end; { if (_unit^.BanDir <> 0) }
   end;
 end; { with }
Konec:
end;

{ ***** }
procedure Turn_unit(_unit:PUnit);
{ procedura nataci jednotku do smeru Status (po jednotlivych fazich, t.j.
  je nutne volat ji vicekrat)
}
var Pom, Pom2 : Byte;
begin
 with (_unit^) do begin
   Pom:=Direction;
   asm ror Pom,1; end; Pom2:=Pom;
     if (Pom = Status) then begin { otaceni bude dekrementaci Direction }
        Direction:=Pom2;
     end else begin
       asm ror Pom,1; end;
       if (Pom = Status) then begin { otaceni bude dekrementaci Direction }
         Direction:=Pom2;
       end else begin
         asm ror Pom,1; end;
         if (Pom = Status) then begin { otaceni bude dekrementaci Direction }
           Direction:=Pom2;
         end else begin
            { otaceni bude inkrementaci Direction }
            asm rol Pom2,2; end;
            Direction:=Pom2;
         end;
       end;
     end;
     RequestDraw:=True; { natoc jednotku }
 end;
end;

{ ***** }
procedure Move_unit(var _unit:PUnit);
{ procedura provede posun jednotky a soucasne meni priznak obsazenosti
  jednotlivych policek
  Procedura funguje nasledovne:
  - zjisti, zda zadany smer (Status) je shodny se smerem aktualni (Direction)
    pokud ne, jednotka se pouze natoci
  - dale se zjisti, zda je pole MoveDir platne. Pokud ne, pak se predpocita.
  - pokud je jednotka v policku s Offsetem 0,0 a nesouhlasi aktualni smer
    a smer dany nasledujici polozkou pole MoveDir, provede se natoceni
    jednotky
  - pokud je Offset <> 0, dokonci se pohyb
  - jinak se postupuje na policko, dane aktualnim natocenim jednotky
}
label Turn, Calculation, Beg, Konec;
var Pom, Pom2, Unit_level : Byte;
    I, J : Integer;
    Distance, IUnSize, JUnSize : Word;
    Result, V:Boolean;
    Hlp : Single;
    Depth:Word;
begin
   bebex:=6000;
   if (_unit <> Nil) then with _unit^ do
   with (Unit_types[UnitType,Races[Race].Ally]) do begin
      bebex:=6001;
      IUnSize:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
      JUnSize:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
      if (GoInside or (MoveStatus > 1)) then Depth:=1 else Depth:=MaxDepth;
Beg:
      if ((Status <> Direction) and (Status <> 0) and (Status <129))
      then begin { jednotka se pouze otoci }
         bebex:=6002;
         { nejprve zjistime, jakym smerem je lepsi se natacet - vlevo
           nebo vpravo }
Turn:
         bebex:=6003;
         Turn_unit(_unit);
         if (Status = Direction) then Goto Beg;

      end else begin { jednotka se posune }
         bebex:=6004;
         if ((MoveUk = 0) and (XOffset = 0) and (YOffset = 0) or
             (Status = 129) and (IdleFlag = 65535)) then
         if (WayPointUk = 255) then GoTo Konec
         else with (WayPoint[WayPointUk]) do begin
         { nutno cestu predpocitat }
Calculation:
            bebex:=6005;
            if ((GetDistance(IPos,JPos,IAim,JAim) <= 1) and GoInside)
            then with (Map^[IAim,JAim]) do begin
            { jednotka se nalozi }
                 bebex:=6006;
                 GoInside:=False; Result:=False; if (First_mov) then First_mov:=False;
                 if ((First_level <> 0) and  (First_level <> _unit^.Index) and
                     (Level_type  and 128 = 0) and
                     (Units[First_level] <> nil) and
                     (Units[First_level]^.Race = MyRace) and
                     (Units[First_level]^.UnitType <> 41) and
                     ((Unit_types[Units[First_level]^.UnitType,
                       Races[MyRace].Ally].Capacity -
                       Units[First_level]^.UnitsInsidePlace) >=
                      Unit_types[UnitType,Races[MyRace].Ally].NeedPlace) and
                      (Units[First_level]^.UnitsInsideNum < 9) and
                      ((Unit_types[Units[First_level]^.UnitType,
                        Races[MyRace].Ally].TargetTyp > 2) or
                       (TargetType < 2)))
                 then begin
                 { OK, MOZNO NALOZIT }
                    bebex:=6007;
                    if (Group = ActiveGroup) then begin
                    { jednotka je v aktivni skupine - odstran ji ze slotu }
                       bebex:=6008;
                       Clear_unit_slot(_unit);
                       Group:=254; Selected:=False;
                       if (GroupOrder >= MaxGroupUnits) then begin
                       { chyba, zkus recover!! }
                        OutBigMsg(255,'CHYBA V UMeSTdNe JEDNOTKY VE SKUPINd - RECOVER');
                         GroupOrder:=0;
                       end;
                       Groups[ActiveGroup].Un[GroupOrder]:=NIL;
                       Dec(Groups[ActiveGroup].Count);
                       Deselect_unit(_unit);
                       if (Groups[ActiveGroup].Count = 0) then begin
                         Deselect_group(ActiveGroup);
                         if (Active(Stop)) then SetPasive(Stop,256);
                         if (Active(Patrol)) then SetPasive(Patrol,256);
                         if (Active(Nalozit)) then SetPasive(Nalozit,256);
                         if (Active(Vylozit)) then SetPasive(Vylozit,256);
                         if (Active(Opravit)) then SetPasive(Opravit,256);
                         if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                         ClearActiveDefenceRangeSlots;
                       end;
                    end;
                    if (Units[First_level]^.Group = ActiveGroup) then begin
                    { je-li naclicknuta jednotka, do ktere se ma cil nalozit
                      aktivni, nastav tlacitko vylozit }
                       bebex:=6009;
                       if (Groups[ActiveGroup].Count = 1) then begin
                          if (not Active(Vylozit)) then SetActive(Vylozit);
                       end;
                    end;
                    { odstraneni jednotky z mapy i obrazovky }
                    bebex:=6010;
                    Erase_unit(_unit, True);
                    Activity:=False;
                    bebex:=6011;
                    Set_place(IPos, JPos, _unit, False, True);
                    { jsme v cili }
                    IInfoPos:=255; JInfoPos:=255; MovementAddingPhase:=0;
                    SetFog(IPos,JPos,Sight,Race,False);
                    if (not Return_to_base) then Stop_unit(_unit,False,True);
                    Inc(Units[First_level]^.UnitsInsideNum);
                    Inc(Units[First_level]^.UnitsInsidePlace,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                    I:=0;
                    { nyni se jednotka ulozi dovnitr cilove }
                    bebex:=6012;
                    with (Units[First_level]^) do begin
                       bebex:=6013;
                       while ((I <= MaxGroupUnits-2) and (UnitsInside[I] <> 0))
                       do Inc(I);
                       if (I > (MaxGroupUnits-2)) then
                         Error(0,'Chyba v jednotce _units - presun jednotky');
                       _unit^.GroupOrder:=(I+1);
                       _unit^.Status:=0; _unit^.MoveStatus:=0;
                       { poradi ulozeni uvnitr cilove jednotky + 1 }
                       bebex:=6014;
                       UnitsInside[I]:=_unit^.Index;
                       if ((Group = ActiveGroup) and
                           (Groups[ActiveGroup].Count = 1)) then
                       { cilova jednotka je naclicknuta - zobraz
                         jednotky uvnitr na levy panel }
                         Click_on_Storage_unit(Units[First_level]);
                    end;
                    GoTo Konec;
                 end else begin
                 { NALOZ CIZI JEDNOTKY }
                    bebex:=6015; bebey:=First_level;
                    if ((First_level <> 0) and (First_level <> _unit^.Index) and
                        (Level_type  and 128 = 0) and
                        (Units[First_level] <> nil) and
                        (Units[First_level]^.Race = _unit^.Race) and
                        (Units[First_level]^.UnitType <> 41) and
                        ((Unit_types[Units[First_level]^.UnitType,
                          Races[Units[First_level]^.Race].Ally].Capacity -
                          Units[First_level]^.UnitsInsidePlace) >=
                         Unit_types[UnitType,Races[Race].Ally].NeedPlace) and
                         (Units[First_level]^.UnitsInsideNum < 9) and
                        ((Unit_types[Units[First_level]^.UnitType,
                          Races[Units[First_level]^.Race].Ally].TargetTyp > 2) or
                        (TargetType < 2)))
                    then with (Races[_unit^.Race]) do begin
                    { OK, MOZNO NALOZIT }
                       bebex:=6016; bebey:=First_level;
                       if (TaskGroup <> InvalidTaskGroupNumber) then begin
                       { jednotka se nalozila - odpocti ji od pocitadla
                         jednotek v jeji taskgrupe }
                          bebex:=6017;
                          Dec(TaskGroups^[TaskGroup].Lock);
                          if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                          then Dec(TaskGroups^[TaskGroup].AirUnitsCount);
                       end;  bebey:=First_level;

                       bebex:=6018;
                       if ((Group = ActiveGroup)) then begin
                          bebex:=6019;
                       { jednotka je v aktivni skupine - odstran ji ze slotu }
                          if (Group = ActiveGroup) then begin
                          { je i naclicknuta na tomto pocitaci }
                             bebex:=6020;
                             Clear_unit_slot(_unit);
                             Group:=254; Selected:=False;
                             if (GroupOrder >= MaxGroupUnits) then begin
                             { chyba, zkus recover!! }
                              OutBigMsg(255,'CHYBA V UMeSTdNe JEDNOTKY VE SKUPINd - RECOVER');
                              GroupOrder:=0;
                             end;
                             Groups[ActiveGroup].Un[GroupOrder]:=NIL;
                             Dec(Groups[ActiveGroup].Count);
                             bebex:=6021;
                             Deselect_unit(_unit);
                             if (Groups[ActiveGroup].Count = 0) then begin
                                Deselect_group(ActiveGroup);
                             end;
                          end;
                       end;
                       { odstraneni jednotky z mapy i obrazovky }
                       bebex:=6022;  bebey:=First_level;
                       Erase_unit(_unit, True);
                       Activity:=False;
                       bebex:=6023; bebey:=First_level;
                       Set_place(IPos,JPos,_unit,False,True);
                       IInfoPos:=255; JInfoPos:=255; MovementAddingPhase:=0;
                       { jsme v cili }
                       bebex:=6024; bebey:=First_level;
                       SetFog(IPos,JPos,Sight,Race,False);
                       if (not Return_to_base) then Stop_unit(_unit,False,True);
                       bebex:=6025;
                       bebey:=First_level;
                       if (Units[First_level] = nil) then bebey:=0 else bebey:=1000;
                       save1:=UnitType;
                       save2:=Race;
                       Inc(Units[First_level]^.UnitsInsideNum);
                       Inc(Units[First_level]^.UnitsInsidePlace,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                       I:=0;
                       bebex:=6026;
                       { nyni se jednotka ulozi dovnitr cilove }
                       with (Units[First_level]^) do begin
                          while ((I <= MaxGroupUnits-2) and (UnitsInside[I] <> 0))
                          do Inc(I);
                          bebex:=6027;
                          if (I > (MaxGroupUnits-2)) then
                            Error(0,'Chyba v jednotce _units - presun jednotky');
                          _unit^.GroupOrder:=(I+1);
                          _unit^.Status:=0; _unit^.MoveStatus:=0;
                          { poradi ulozeni uvnitr cilove jednotky + 1 }
                          UnitsInside[I]:=_unit^.Index;
                       end;
                       GoTo Konec;
                    end else begin
                   {  NE, NENI MOZNO NALOZIT }
                      Stop_:=True;
                      GoTo Konec;
                    end;
                 end;
            end else begin {}
              WeightMoveDir:=65535;  bebex:=6028;
              { inicializace pole s vahami }
              save1:=IAim; save2:=JAim;
              if (First_mov) then begin
                bebex:=6029;
                Pom:=Best_direction(IPos, JPos,IAim,JAim);
                bebey:=6;
              end else Pom:=Direction;
              bebey:=7;
              Distance:=65535;
              bebey:=8;
              if (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) then begin
                 Result:=Move_air_unit(IPos,JPos,IAim,JAim, Pom, _unit, Distance);
                 bebey:=9;
              end else begin
                 Result:=Move(IPos,JPos,IAim,JAim, Pom, _unit, Distance);
                 bebey:=10;
              end;
              bebey:=0;
            end;
            bebex:=6030;

            if (Result) then begin
            { existuje cesta dale }
               bebex:=6031;
               if (First_mov) then First_mov:=False;
               { jednotka normalne pokracuje v jizde }
               MoveUk:=1;
               Status:=MoveDir;
               if ((Status = SlashDir1) or (Status = SlashDir2)) then begin
                 Hlp:=Depth; Hlp:=Depth*Depth*2;
                 SlashCount:=Round(sqrt(Hlp));
                 SlashDir:=Status;
               end;
               if (Obstacle) then GoTo Konec;
               GoTo Beg;
            end else begin
               bebex:=6032;
               if (Return_to_base) then Return_to_base:=False;
               Stop_unit(_unit,True,True); { cesta z bodu neexistuje }
            end;

         end else begin { cesta je predpocitana }
            bebex:=6033;
            if ((XOffset <> 0) or (YOffset <> 0)) then begin
                bebex:=6034;
              { pokracuje se v zapocatem pohybu }
                 if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                 if (Phase >= MaxPhase) then Phase:=0;
                 bebex:=6035;
                 Draw_move(_unit);
            end else begin
               if ((Direction <> MoveDir) and (Status <> 129)) then begin
                 bebex:=6036;
                 Status:=MoveDir;
                 GoTo Turn;
                 { jednotka se natoci smerem, potrebnym pro dalsi presun }
              end else begin
              { jednotka se posune na policko, dane jejim aktualnim natocenim }
              { zacina se novy pohyb }
                 case (Direction) of
                   1 : begin  { vlevo nahoru \ }
                          bebex:=6037;
                          { musi byt volna policka vlevo, nahore a vlevo nahore }
                          if (IPos > 0) and (JPos > 0) and
                             (Free_place2(IPos,JPos-1,IUnSize,JUnSize,_unit) and
                              Free_place2(IPos-1,JPos-1,IUnSize,JUnSize,_unit) and
                              Free_place2(IPos-1,JPos,IUnSize,JUnSize,_unit)) then begin
                          { pruchodno }
                             bebex:=6038;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             bebex:=7038;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             bebex:=7039;
                             Dec(JPos); Dec(IPos); XOffset:=32; YOffset:=32;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             bebex:=7040;
                             Set_place(IPos+1,JPos,_unit,True,False);{nahore vpravo}
                             bebex:=7041;
                             Set_place(IPos,JPos+1,_unit,True,False);{vlevo dole}
                             bebex:=7042;
                             Set_place(IPos,JPos,_unit,True, True);{vlevo nahore }
                             bebex:=7043;
                             SetFog2(IPos,JPos,IPos+1,JPos+1,Sight,
                                     Race,True);
                             bebex:=7044;
                             MovementAddingPhase:=0;
                             save1:=IPos; save2:=JPos;
                             Draw_move(_unit);
                             bebex:=7045;
                          end else begin
                              bebex:=6039;
                             if (IPos > 0) and (JPos > 0) and
                                (Moving_unit_on_place(IPos,JPos-1,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos-1,JPos-1,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos-1,JPos,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6040;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6041;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                       bebex:=6042;
                                  { pokracuj na dalsi waypoint }
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                   2 : begin  { nahoru | }
                          { musi byt volne policko nahore }
                          bebex:=6043;
                          if (JPos > 0) and
                             (Free_place2(IPos,JPos-1,IUnSize,JUnSize,_unit)) then begin
                          { pruchodno }
                             bebex:=6044;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             Dec(JPos); XOffset:=0; YOffset:=32;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos,JPos,_unit,True,True);{nahore}
                             SetFog2(IPos,JPos,IPos,JPos+1,Sight,
                                     Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                          end else begin
                             bebex:=6045;
                             if (JPos > 0) and
                                (Moving_unit_on_place(IPos,JPos-1,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6046;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6047;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     bebex:=6048;
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                  { pokracuj na dalsi waypoint }
                                       bebex:=6049;
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                   4 : begin  { vpravo nahoru / }
                          { musi byt volna policka vpravo, nahore a vpravo nahore }
                          bebex:=6050;
                          if (IPos < IMax) and (JPos > 0) and
                             (Free_place2(IPos,JPos-1,IUnSize,JUnSize,_unit) and
                              Free_place2(IPos+1,JPos-1,IUnSize,JUnSize,_unit) and
                              Free_place2(IPos+1,JPos,IUnSize,JUnSize,_unit)) then begin
                          { pruchodno }
                             bebex:=6051;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             Dec(JPos); XOffset:=0; YOffset:=32;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos,JPos,_unit,True,False);{nahore}
                             Set_place(IPos+1,JPos+1,_unit,True,False);{vpravo dole}
                             Set_place(IPos+1,JPos,_unit,True,True);{vpravo nahore}
                             SetFog2(IPos+1,JPos,IPos,JPos+1,Sight,
                                     Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                          end else begin
                             bebex:=6052;
                             if (IPos < IMax) and (JPos > 0) and
                                (Moving_unit_on_place(IPos,JPos-1,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos+1,JPos-1,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos+1,JPos,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6053;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6054;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     bebex:=6055;
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                  { pokracuj na dalsi waypoint }
                                       bebex:=6056;
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                   8 : begin  { vpravo - }
                          { musi byt volne policko vpravo }
                          bebex:=6057;
                          if (IPos < IMax) and
                             (Free_place2(IPos+1,JPos,IUnSize,JUnSize,_unit)) then begin
                          { pruchodno }
                             bebex:=6058;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos+1,JPos,_unit,True,True);{vpravo}
                             SetFog2(IPos+1,JPos,IPos,JPos,Sight,
                                     Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                          end else begin
                             bebex:=6059;
                             if (IPos < IMax) and
                                (Moving_unit_on_place(IPos+1,JPos,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6060;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6061;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     bebex:=6062;
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                  { pokracuj na dalsi waypoint }
                                       bebex:=6063;
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                   16 : begin  { vpravo dolu \ }
                           bebex:=6064;
                           { musi byt volna policka vpravo, dole a vpravo dole }
                           if (IPos < IMax) and (JPos < JMax) and
                              (Free_place2(IPos+1,JPos,IUnSize,JUnSize,_unit) and
                               Free_place2(IPos,JPos+1,IUnSize,JUnSize,_unit) and
                               Free_place2(IPos+1,JPos+1,IUnSize,JUnSize,_unit)) then begin
                           { pruchodno }
                             bebex:=6065;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos+1,JPos,_unit,True,False);{vpravo}
                             Set_place(IPos,JPos+1,_unit,True,False);{dole}
                             Set_place(IPos+1,JPos+1,_unit,True,True);{vpravo dole}
                             SetFog2(IPos+1,JPos+1,IPos,JPos,Sight,
                                     Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                          end else begin
                             bebex:=6066;
                             if (IPos < IMax) and (JPos < JMax) and
                                (Moving_unit_on_place(IPos+1,JPos,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos,JPos+1,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos+1,JPos+1,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6067;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6068;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     bebex:=6070;
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                  { pokracuj na dalsi waypoint }
                                       bebex:=6069;
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                        end;
                   32 : begin  { dolu | }
                           { musi byt volne policko dole }
                           bebex:=6071;
                           if (JPos < JMax) and
                              (Free_place2(IPos,JPos+1,IUnSize,JUnSize,_unit)) then begin
                           { pruchodno }
                             bebex:=6072;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos,JPos+1,_unit,True,True);{dole}
                             SetFog2(IPos,JPos+1,IPos,JPos,Sight,Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                           end else begin
                             bebex:=6073;
                             if (JPos < JMax) and
                                (Moving_unit_on_place(IPos,JPos+1,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6074;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6075;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     bebex:=6076;
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                  { pokracuj na dalsi waypoint }
                                       bebex:=6077;
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                   64 : begin  { vlevo dolu / }
                           bebex:=6078;
                           { musi byt volna policka vlevo, dole a vlevo dole }
                           if (IPos > 0) and (JPos < JMax) and
                              (Free_place2(IPos,JPos+1,IUnSize,JUnSize,_unit) and
                               Free_place2(IPos-1,JPos,IUnSize,JUnSize,_unit) and
                               Free_place2(IPos-1,JPos+1,IUnSize,JUnSize,_unit)) then begin
                             bebex:=6079;
                           { pruchodno }
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             Dec(IPos); XOffset:=32;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos+1,JPos+1,_unit,True,False);{dole}
                             Set_place(IPos,JPos,_unit,True,False);{vlevo }
                             Set_place(IPos,JPos+1,_unit,True,True);{vlevo dole}
                             SetFog2(IPos,JPos+1,IPos+1,JPos,Sight,Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                          end else begin
                             bebex:=6080;
                             if (IPos > 0) and (JPos < JMax) and
                                (Moving_unit_on_place(IPos,JPos+1,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos-1,JPos,IUnSize,JUnSize,_unit) or
                                 Moving_unit_on_place(IPos-1,JPos+1,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6081;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6082;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                  { konec cesty }
                                     bebex:=6083;
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                      bebex:=6084;
                                  { pokracuj na dalsi waypoint }
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                   128 : begin  { vlevo - }
                           bebex:=6085;
                           { musi byt volna policka vlevo }
                           if (IPos > 0) and
                              (Free_place2(IPos-1,JPos,IUnSize,JUnSize,_unit)) then begin
                           { pruchodno }
                             bebex:=6086;
                             if (Status = 129) then Status:=MoveDir;
                             Inc(MoveUk); if (MoveUk > TopUk) then MoveUk:=0;
                             if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase);
                             if (Phase >= MaxPhase) then Phase:=0;
                             Dec(IPos); XOffset:=32;
                             { nastaveni obsazenosti }
                             V:=Visibility; Eras:=False;
                             Set_place(IPos,JPos,_unit,True,True);{vlevo }
                             SetFog2(IPos,JPos,IPos+1,JPos,Sight,Race,True);
                             MovementAddingPhase:=0;
                             Draw_move(_unit);
                           end else begin
                             bebex:=6087;
                             if (IPos > 0) and
                                (Moving_unit_on_place(IPos-1,JPos,IUnSize,JUnSize,_unit)) then
                                Status:=129
                             else begin { prekazka v ceste }
                                bebex:=6088;
                                if (not CheckGroupMoveDistance) then begin
                                   Status:=Direction;
                                   MoveUk:=0;
                                end else begin
                                  bebex:=6089;
                                  Status:=0;
                                  Inc(WayPointUk);
                                  if ((WayPointUk > WayPointMax) or (WayPointUk = 255) or
                                      (WayPointMax = 255)) then begin
                                     bebex:=6090;
                                  { konec cesty }
                                     WayPointUk:=255; WayPointMax:=255;
                                     if ((Race = MyRace) and (Group = ActiveGroup))
                                     then Click_on_unit(_unit);
                                  end else begin
                                  { pokracuj na dalsi waypoint }
                                       bebex:=6091;
                                       Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,
                                                    _unit,WayPoint[WayPointUk].Level,False,False);
                                  end;
                                end;
                             end;
                          end;
                       end;
                 end; { case }
              end; { if ((XSegment <> 0) or (XOffset <> 0)) then else }
            end;
         end;
      end; { if (Status <> Direction) then else  }
   end; { if - with }
Konec:
end;

{ ***** }
procedure _units_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'7'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _units_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'7'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************** }
begin
end.