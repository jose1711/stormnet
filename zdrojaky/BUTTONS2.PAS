{}
unit Buttons2;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Mouse;

function Rozloz_unit(Send:Boolean; _unit:PUnit):Boolean;
procedure UnLoad(_unit:PUnit);
procedure SellActiveGroup;
procedure ChangeUnitToMyRace(_unit:PUnit);
procedure ChangeBuildingToMyRace(Build:PBuilding);
procedure Civilian_move(_unit:PUnit);
procedure Buttons2_save;
procedure Buttons2_load;

implementation

uses Grafika, Grafika2, _units, _units2, _units3, Grafika3, Grafika4,
     Buttons, _Buildings, AI;

{ ***** }
function Rozloz_unit(Send:Boolean; _unit:PUnit):Boolean;
{ najde v aktivni skupine jednotku-budovu a pokusi se ji rozlozit;
  jestlize Send = True, hleda v aktivni skupine ; je-li Send =
  = False pouzije se jednotka _unit
}
var K, L, M, N, IP, JP, ISize, JSize, X, Y, Damag, Ind :Word;
    Place:Boolean;
    _build, Unit_building, Load, Visibilit : Boolean;
    BuildingTyp, Rac, Experienc : Byte;
    DMG, Pom1, Pom2:Double;
    Size:String;
begin
   K:=1; L:=0; Rozloz_unit:=False;
   { nyni zjistime vyskyt jednotek-budov ve skupine }

   if ((Send) and (ActiveGroup <> 255)) then
   with (Groups[ActiveGroup]) do begin
     while ((K <= MaxGroupUnits) and (L < Count)) do begin
        if ((Un[K-1] <> Nil) and (Un[K-1]^.Activity))
        then with (Un[K-1]^) do begin
           Inc(L);
           if (UnitType = 33) then L:=1000;
        end;
        Inc(K);
     end;

     if ((L >= 1000) and (Un[K-2]^.XOffset = 0) and (Un[K-2]^.YOffset = 0))
     then  begin
      with (Un[K-2]^) do begin
      { rozloz jednotku-budovu }
       Place:=False;
       if (_building) then begin
         ISize:=Building_types[BuildingType].IBuildingSize;
         JSize:=Building_types[BuildingType].JBuildingSize;
       end else begin
         ISize:=Unit_types[BuildingType,Races[Race].Ally].IUnitSize;
         JSize:=Unit_types[BuildingType,Races[Race].Ally].JUnitSize;
       end;
       if (ISize = 1) and (JSize = 1) then begin
       { 1x1 }
          Place:=True;
          Size:='1x1';
       end else
         if (ISize = 2) and (JSize = 1) then begin
         { 2x1 }
            M:=IPos; N:=JPos;
            Set_place(IPos, JPos, Un[K-2], False, True);
            if ((M < IMax) and Free_place_two(M,N,ISize,JSize,14))
            then Place:=True;
            Set_place(IPos, JPos, Un[K-2], True, True);
            Size:='2x1';
         end else begin
         { 2x2 }
            if (ISize = 2) then begin
               M:=IPos; N:=JPos;
               Set_place(IPos, JPos, Un[K-2], False, True);
               if ((M < IMax) and (N < JMax) and
                  Free_place_two(M,N,ISize,JSize,14))
               then Place:=True;
               Set_place(IPos, JPos, Un[K-2], True, True);
               Size:='2x2';
            end else begin
               M:=IPos; N:=JPos;
               Set_place(IPos, JPos, Un[K-2], False, True);
               if ((M < IMax) and (N < JMax) and
                  Free_place_two(M,N,ISize,JSize,14))
               then Place:=True;
               Set_place(IPos, JPos, Un[K-2], True, True);
               Size:='3x3';
            end;
         end;
       IP:=IPos; JP:=JPos;
       BuildingTyp:=BuildingType; Rac:=Race; Visibilit:=True; Experienc:=0;
       Ind:=Index;
       { nyni zjistime procentualni poskozeni jednotky-budovy }
       Pom1:=Damage; Pom2:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
       DMG:=Pom1 / (Pom2 / 100);
      end; { with }

      if (Place) then with (Units[Ind]^) do begin
      { stavi se !! }
         { odstran jednotku ze skupiny }
          Dec(Count);
          Clear_unit_slot(Units[Ind]);
          Group:=254;
          Deselect_unit(Units[Ind]);
          K:=1; L:=0;
          { nyni zjistime vyskyt jednotek-budov respektive
            nalozenych transporteru ve skupine }
          Unit_building:=False; Load:=False;
          while ((K <= MaxGroupUnits) and (L < Count)) do begin
            if (Un[K-1] <> Nil) then with (Un[K-1]^) do begin
              Inc(L);
              if (UnitType = 33) then Unit_building:=True;
              if (UnitsInsideNum <> 0) then Load:=True;
            end;
            Inc(K);
          end;

          if (Count = 0) then begin
             ActiveGroup:=255;
             if (Rac = MyRace) then begin
               CursorOff;
               if (Active(Stop)) then SetPasive(Stop,256);
               if (Active(Patrol)) then SetPasive(Patrol,256);
               if (Active(Nalozit)) then SetPasive(Nalozit,256);
               if (Active(Vylozit)) then SetPasive(Vylozit,256);
               if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
               if (Active(Opravit)) then SetPasive(Opravit,256);
               if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
               ClearActiveDefenceRangeSlots;
               CursorOn;
             end;
          end else begin
             Error(0,'unita buttons, procedura Rozloz_unit, bod 0');
          end;

          Un[GroupOrder]:=NIL;
          _build:=_building;
          Status:=Direction;
          Disband_unit(Units[Ind],True,False);
          if (_build) then begin
             Damag:=Building_types[BuildingTyp].DefenceStrength;
             Pom1:=Damag;
             Damag:=Round((Pom1 / 100) * DMG);
             Inc(Races[Rac].UnpackedBuildings);
             Ind:=New_building(IP,JP, BuildingTyp, Rac, Visibilit,1,False);{}
             if (BuildingTyp <> 11) then with (Buildings[Ind]^) do begin
             { nejde o letiste }
               Damage:=Damag;
               Pom2:=Damag;
               if (Pom2 <= Pom1 / 2) then
                  FireState:=1;
               if (Pom2 <= Pom1 / 3) then
                  FireState:=2;
               if ((FirePhase = 0) and FireAllowed and
                   (FireState <> 0))
               then FirePhase:=1;
             end;
             Rozloz_unit:=True;
          end else begin
             Damag:=Unit_types[BuildingTyp,Races[Rac].Ally].DefenceStrength;
             Pom1:=Damag;
             Damag:=Round((Pom1 / 100) * DMG);
             Inc(Races[Rac].UnpackedBuildings);
             Ind:=New_unit(IP,JP, BuildingTyp, Rac, Experienc,0, Visibilit,False,0);{}
             with (Units[Ind]^) do begin
               Damage:=Damag;
               Pom2:=Damag;
               if (Pom2 <= (Pom1 / 3)) then
                 if ((FirePhase = 0) and FireAllowed) then
                 { predpokladame, ze nemuze jit o pechotu (ta kourit nesmi) }
                   FirePhase:=1;
             end;
             Rozloz_unit:=True;
          end;
      end else OutBigMsg(11,'NEDOSTATEK VOLNcHO MeSTA - '+Size); { if (Place) }
    end else OutBigMsg(255,'JEDNOTKA MUSe STaT NA MeSTd');

{ ************************************************ }
  end else
   if (_unit <> Nil) then with (_unit^) do begin
     if ((_unit^.XOffset = 0) and (_unit^.YOffset = 0)) then begin
      with (_unit^) do begin
      { rozloz jednotku-budovu }
       Place:=False;
       if (_building) then begin
         ISize:=Building_types[BuildingType].IBuildingSize;
         JSize:=Building_types[BuildingType].JBuildingSize;
       end else begin
         ISize:=Unit_types[BuildingType,Races[Race].Ally].IUnitSize;
         JSize:=Unit_types[BuildingType,Races[Race].Ally].JUnitSize;
       end;
       if (ISize = 1) and (JSize = 1) then begin
       { 1x1 }
          Place:=True;
          Size:='1x1';
       end else
         if (ISize = 2) and (JSize = 1) then begin
         { 2x1 }
            M:=IPos; N:=JPos;
            Set_place(IPos, JPos, _unit, False, True);
            if ((M < IMax) and Free_place_two(M,N,ISize,JSize,14))
            then Place:=True;
            Set_place(IPos, JPos, _unit, True, True);
            Size:='2x1';
         end else begin
         { 2x2 }
            M:=IPos; N:=JPos;
            Set_place(IPos, JPos, _unit, False, True);
            if ((M < IMax) and (N < JMax) and
               Free_place_two(M,N,ISize,JSize,14))
            then Place:=True;
            Set_place(IPos, JPos, _unit, True, True);
            Size:='2x2';
         end;
       IP:=IPos; JP:=JPos;
       BuildingTyp:=BuildingType; Rac:=Race; Visibilit:=True; Experienc:=0;
       Ind:=Index;
       { nyni zjistime procentualni poskozeni jednotky-budovy }
       Pom1:=Damage; Pom2:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
       DMG:=Pom1 / (Pom2 / 100);
      end; { with }

      if (Place) then with (Units[Ind]^) do begin
      { stavi se !! }
          K:=1; L:=0;
          { nyni zjistime vyskyt jednotek-budov respektive
            nalozenych transporteru ve skupine }
          Unit_building:=False; Load:=False;

          _unit:=NIL;
          _build:=_building;
          Status:=Direction;
          Disband_unit(Units[Ind],True,False);
          if (_build) then begin
             with (Races[Rac]) do case (BuildingTyp) of
             { odstranit zakaz pro danou komoditu }
               2 : if (BarrackShortageForbid > 0)  { kasarna }
                   then Dec(BarrackShortageForbid);
               3 : if (LightFactoryShortageForbid > 0) { lehka tovarna }
                   then Dec(LightFactoryShortageForbid);
               4 : if (BPShortageForbid > 0) { recyklace }
                   then Dec(BPShortageForbid);
               5 : if (EEShortageForbid > 0)  { elektrarna }
                   then Dec(EEShortageForbid);
               6 : if (AccumulatorShortageForbid > 0) { akumulator }
                   then Dec(AccumulatorShortageForbid);
               9 : if (Base2ShortageForbid > 0)  { zakladna2 }
                   then Dec(Base2ShortageForbid);
               8 : if (PLShortageForbid > 0)  { plastarna }
                   then Dec(PLShortageForbid);
               10 :if (HeavyFactoryShortageForbid > 0) { tezka tovarna }
                   then Dec(HeavyFactoryShortageForbid);
               11 : if (AirportShortageForbid > 0) { letiste }
                      then Dec(AirportShortageForbid);
               12 :if (SpecialFactoryShortageForbid > 0) { specialni tovarna }
                   then Dec(SpecialFactoryShortageForbid);
               13 :if (RepairFactoryShortageForbid > 0) { centrum oprav }
                   then Dec(RepairFactoryShortageForbid);
               14 :if (DefenceFactoryShortageForbid > 0) { obranne centrum }
                   then Dec(DefenceFactoryShortageForbid);
               15 : if (BarrackShortageForbid > 0)  { montazni linka }
                   then Dec(BarrackShortageForbid);
               21 : if (RadarShortageForbid > 0) { radar }
                    then Dec(RadarShortageForbid);
             end;{}
             Damag:=Building_types[BuildingTyp].DefenceStrength;
             Pom1:=Damag;
             Damag:=Round((Pom1 / 100) * DMG);
             Inc(Races[Rac].UnpackedBuildings);
             Ind:=New_building(IP,JP, BuildingTyp, Rac, Visibilit,1,False);{}
             if (BuildingTyp <> 11) then with (Buildings[Ind]^) do begin
             { nejde o letiste }
               Damage:=Damag;
               Pom2:=Damag;
               if (Pom2 <= Pom1 / 2) then
                  FireState:=1;
               if (Pom2 <= Pom1 / 3) then
                  FireState:=2;
               if ((FirePhase = 0) and FireAllowed and
                   (FireState <> 0))
               then FirePhase:=1;
             end;
             Rozloz_unit:=True;
          end else begin { jednotka }
             with (Races[Rac]) do case (BuildingTyp) of
               41 : if (CentrumPosilShortageForbid > 0)  { centrum posil }
                    then Dec(CentrumPosilShortageForbid);
             end;
             Damag:=Unit_types[BuildingTyp,Races[Rac].Ally].DefenceStrength;
             Pom1:=Damag;
             Damag:=Round((Pom1 / 100) * DMG);
             Inc(Races[Rac].UnpackedBuildings);
             Ind:=New_unit(IP,JP, BuildingTyp, Rac, Experienc,0, Visibilit,False,0);{}
             with (Units[Ind]^) do begin
               Damage:=Damag;
               Pom2:=Damag;
               if (Pom2 <= (Pom1 / 3)) then
                 if ((FirePhase = 0) and FireAllowed) then
                 { predpokladame, ze nemuze jit o pechotu (ta kourit nesmi) }
                   FirePhase:=1;
             end;
             Rozloz_unit:=True;
          end;
      end else Rozloz_unit:=False; { if (Place) }
    end;
{ ************************************************ }
  end;
end;

{ ***** }
procedure UnLoad(_unit:PUnit);
{ procedura vylozi vsechny zvolene vojaky z vozidla _unit
}
var I, J: Word;
    FreePlaces : TFreePlaces;
    MaxIndex:Word;
    Pom, Ok:Boolean;
begin
  with (_unit^) do begin
    { Zjistime, zda jsou nejake jednotky zvoleny; pokud ne,
      zvoli se vsechny }
   if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
       (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 1) and
       (TargetType = 3))
   then begin
      if (Race = MyRace) then OutBigMsg(255,'JEDNOTKA MUSe BjT NA ZEMI');
   end else begin
    Pom:=False;
    for I:=0 to (MaxGroupUnits-2) do
       if ((UnitsInside[I] <> 0) and
           (Units[UnitsInside[I]]^.Selected)) then Pom:=Pom or True;
    if (Pom = False) then begin
    { zvolena nebyla zadna }
       for I:=0 to (MaxGroupUnits-2) do
          if (UnitsInside[I] <> 0) then
             Units[UnitsInside[I]]^.Selected:=True;
    end; { zvol vsechny }

    Get_free_places(FreePlaces,MaxIndex,IPos,JPos,1,1);

{2} for I:=0 to (MaxGroupUnits-2) do begin
    { projed vsechny jednotky }
      OK:=False; J:=1;
  {1} if ((UnitsInside[I] <> 0) and (Units[UnitsInside[I]]^.Selected))
      then with (Units[UnitsInside[I]]^) do begin { zkus vylozit jednotku }
         while ((not OK) and (J <= MaxIndex)) do  { hledej misto pro vylozeni }
         with (FreePlaces[J]) do begin
           if (Free and Free_place(IP,JP,Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                   Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                   Units[_unit^.UnitsInside[I]]))
      {4}  then begin { flek nalezen }
             OK:=True; Free:=False;
             Units[_unit^.UnitsInside[I]]^.MoveStatus:=0;
             Units[_unit^.UnitsInside[I]]^.WayPointUk:=255;
             Units[_unit^.UnitsInside[I]]^.WayPointMax:=255;
             Units[_unit^.UnitsInside[I]]^.Status:=0;
             if ((Race = MyRace) and (_unit^.Group = ActiveGroup)) then begin
                Clear_unit_slot(Units[_unit^.UnitsInside[I]]);
             end;
             Dec(_unit^.UnitsInsideNum);
             Dec(_unit^.UnitsInsidePlace,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
             Activity:=True;
             IPos:=IP; JPos:=JP;
             if (TaskGroup <> InvalidTaskGroupNumber) then begin
             { jednotka se vylozila - pripocti ji k pocitadlu
               jednotek v jeji taskgrupe }
                 Inc(Races[Race].TaskGroups^[TaskGroup].Lock);
                 if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                 then Inc(Races[Race].TaskGroups^[TaskGroup].AirUnitsCount);

                 IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
             end;

             Inc(Load_flag);

             {!!! NEKOREKTNI !!! }
             { predpokladam, ze nalozene jednotky nebudou vetsi nez
               1x1 pole (t.j vetsi nelze nalozit) }
             Set_place(IPos, JPos, Units[_unit^.UnitsInside[I]], True, True);
             Selected:=False;
             Status:=0; Direction:=2; Phase:=0; MovementAddingPhase:=0;
             Draw_unit(Units[_unit^.UnitsInside[I]]);
             SetFog(IPos,JPos,Units[_unit^.UnitsInside[I]]^.Sight,Race,True);
             if (Race <> MyRace) then begin
                if (UnitType = 2) then begin
                  { recyklatoru narid tezit skladky ! }
                  TaskGroupCommand(Race,CreateNewTaskGroup(Race,InvalidTaskGroupNumber,Units[_unit^.UnitsInside[I]]),
                                   HarvestCom,0,4,0,0,0)
                end;
                if (UnitType = 33) then begin
                  { recyklatoru narid tezit skladky ! }
                  TaskGroupCommand(Race,CreateNewTaskGroup(Race,TGInvalid,Units[_unit^.UnitsInside[I]]),
                                   MoveBuildCom,0,4,0,0,0);
                end;
             end;
             Stop_unit(Units[_unit^.UnitsInside[I]],True,True);
             _unit^.UnitsInside[I]:=0;
           end else begin  {4} { volne misto nenalezeno }
             Inc(J);
           end; {4}
         end;
      end; {1}
    end; {2}

    { nebyla zvolena zadna jednotka, zvolily se proto vsechny;
      pokud se nektere nevylozily, "odselectuj je" }
    if (Pom = False) then begin
       for I:=0 to (MaxGroupUnits-2) do
          if (UnitsInside[I] <> 0) then
             Units[_unit^.UnitsInside[I]]^.Selected:=False;
    end; { zvol vsechny }
   end;
  end; { with }
end;

{ ***** }
procedure SellActiveGroup;
{ proda aktivni skupinu
}
label Konec;
var B,P,E,X,DMG:Single;
    I,j:Word;
    FullPrice:Boolean; { True, pokud bude plna cena }
begin
  FullPrice:=False;
  if (Races[MyRace].ExistBuildings[9] > 0) then FullPrice:=True;
  if (Races[MyRace].ExistBuildings[14] > 0) then FullPrice:=True;
  if (Races[MyRace].ExistBuildings[10] > 0) then FullPrice:=True;
  if (Races[MyRace].ExistBuildings[12] > 0) then FullPrice:=True;
  if (Races[MyRace].ExistBuildings[21] > 0) then FullPrice:=True;
  if (Races[MyRace].ExistBuildings[13] > 0) then FullPrice:=True;
  if (Races[MyRace].ExistBuildings[11] > 0) then FullPrice:=True;

  if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do
    if ((Building <> Nil) and (Building^.Activity))
    then with (Building^) do with (Building_types[BuildingType]) do begin
       if (FullPrice) then begin
         if (DialogBox('CHCETE SKUTEbNd PRODAT BUDOVU?',_YES_NO) = NO) then GoTo Konec;
       end else begin
         if (DialogBox('BEZ TECHNOLOGIE HITECH ZaKLADNY BUDE PRODEJ ZA MAX. 10% CENY. PRODAT?',_YES_NO) = NO) then GoTo Konec;
       end;
       B:=1.0*BP/100; P:=1.0*PL/100; E:=1.0*EE/100; X:=1.0*EX/100;
       DMG:=Damage/((1.0*DefenceStrength)/100);
       if (FullPrice) then begin
         { za kazdou budovu je 80% puv. ceny - procento poskozeni/1.3 }
         B:=B*(80-(80-8*DMG/10)); P:=P*(80-(80-8*DMG/10));
         E:=E*(80-(80-8*DMG/10)); X:=X*(80-(80-8*DMG/10));
       end else begin
         { za kazdou budovu je 10% puv. ceny - procento poskozeni }
         B:=B*(10-(10-DMG/10)); P:=P*(10-(10-DMG/10));
         E:=E*(10-(10-DMG/10)); X:=X*(10-(10-DMG/10));
       end;
       Inc(Races[MyRace].Building_credits, Round(B));
       Inc(Races[MyRace].Plastic_credits, Round(P));
       Inc(Races[MyRace].Electric_energy, Round(E));
       Inc(Races[MyRace].Battle_experience, Round(X));
       Sold:=True;
       Destroy_building(Buildings[Index],True);
       Inc(BuildingsSold);
       Building:=Nil;
    end else begin
     if (FullPrice) then begin
       if (DialogBox('CHCETE SKUTEbNd PRODAT ZVOLENc JEDNOTKY ?',_YES_NO) = NO) then GoTo Konec;
     end else begin
       if (DialogBox('BEZ TECHNOLOGIE HITECH ZaKLADNY BUDE PRODEJ ZA MAX. 10% CENY. PRODAT?',_YES_NO) = NO) then GoTo Konec;
     end;
     {x}
     for J:=0 to MaxGroupUnits-1 do begin
       if ((Un[J] <> Nil) and (not Un[J]^.Destroyed))
       then with (Un[J]^) do with (Unit_types[UnitType,1]) do begin
           if (UnitsInsideNum <> 0) then begin
           { pokud jsou uvnitr nalozeny nejake jednotky }
               for I:=0 to MaxGroupUnits-2 do begin
                 if ((UnitsInside[I] <> 0) and
                     (Units[UnitsInside[I]] <> Nil) and
                     (UnitsInsideNum > 0)) then
                 with (Units[UnitsInside[I]]^) do begin
                    { zapocteni nakladu do bodu }
                    Selected:=True;
                    Destroyed:=True;
                    IInfoPos:=Un[J]^.IInfoPos;
                    JInfoPos:=Un[J]^.JInfoPos;
                    if (Un[J]^.Group = ActiveGroup) then
                       Clear_unit_slot(Units[Un[J]^.UnitsInside[I]]);
                    Disband_unit(Units[Un[J]^.UnitsInside[I]],True,False);
                    Dec(Un[J]^.UnitsInsideNum);
                    Inc(UnitsSold);
                 end;
               end;
           end;

           B:=1.0*BP/100; P:=1.0*PL/100; E:=1.0*EE/100; X:=1.0*EX/100;
           DMG:=Damage/((1.0*(DefenceStrength+DamageBonus))/100);
           { za kazdou jednotku je 80% - procento poskozeni/1.3 +
             + 5% za kazdy stupen hodnosti PUVODNI CENY}
           if (FullPrice) then begin
             { za kazdou budovu je 80% puv. ceny - procento poskozeni }
             B:=B*(80-(80-8*DMG/10)+ExperienceLevel*5);
             P:=P*(80-(80-8*DMG/10)+ExperienceLevel*5);
             E:=E*(80-(80-8*DMG/10)+ExperienceLevel*5);
             X:=X*(80-(80-8*DMG/10)+ExperienceLevel*5);
           end else begin
             { za kazdou budovu je 10% puv. ceny - procento poskozeni }
             B:=B*(10-(10-DMG/10)+ExperienceLevel);
             P:=P*(10-(10-DMG/10)+ExperienceLevel);
             E:=E*(10-(10-DMG/10)+ExperienceLevel);
             X:=X*(10-(10-DMG/10)+ExperienceLevel);
           end;
           Inc(Races[MyRace].Building_credits, Round(B));
           Inc(Races[MyRace].Plastic_credits, Round(P));
           Inc(Races[MyRace].Electric_energy, Round(E));
           Inc(Races[MyRace].Battle_experience, Round(X));
           Sold:=True;
           if (not Activity) then Disband_unit(Units[Index],False,False)
           else Disband_unit(Units[Index],True,False);
           Inc(UnitsSold);
           Un[J]:=Nil;
       end;
     end;
    end;

  Clear_group_slots;
  if (ActiveGroup < 254) then Deselect_group(ActiveGroup);
  if (Active(Stop)) then SetPasive(Stop,256);
  if (Active(Patrol)) then SetPasive(Patrol,256);
  if (Active(Nalozit)) then SetPasive(Nalozit,256);
  if (Active(Vylozit)) then SetPasive(Vylozit,256);
  if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
  if (Active(Opravit)) then SetPasive(Opravit,256);
  if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
  ClearActiveDefenceRangeSlots;
Konec:

end;

{ ***** }
procedure ChangeUnitToMyRace(_unit:PUnit);
{ zmeni jednotku na mou rasu }
var I,J,IP,JP:Word;
    UnitTyp,ExperiencLevel,SpecNum:Byte;
    Experienc,Kill,BuildType,Strength:Word;
    Nam:String[15];
    Pom:Word;
begin
  Val(MissionNameString,Pom,J);
  if ((Pom = 24) and (Units[230] <> Nil) and (Units[230]^.Visibility) and
      (MissionSpecManagerTag1 = 0) and (_unit <> Nil) and (_unit^.Index = 230))
      then begin
      WideDialogBox('   RaD VaS VIDeM PfaTELc. ORGANIZACE ZAbALA MeT PODEZfENe, TAKkE',
                    'JSEM MUSEL RYCHLE UPRCHNOUT. MaM VELMI ZAJeMAVc INFORMACE. ODDeLY,',
                    'SPOLUPRACUJeCe S ROBOTY, HODLAJe UZAVfeT VELKc SPOJENECTVe.', _YES);
      MissionSpecManagerTag1:=1;
  end;
  if ((Pom = 37) and (Units[1149] <> Nil) and (Units[1149]^.Visibility) and
      (MissionSpecManagerTag1 = 0) and (_unit <> Nil) and (_unit^.Index = 1149))
      then begin
      WideDialogBox('  VAgI MUkI PfED SEBOU SPATfILI NEHYBNOU JEDNOTKU. PO ROZPADU',
                    'feDeCeCH CENTER PfESTALI NdKTEfe ROBOTI DOSTaVAT feDeCe SIGNaLY.',
                    'ZA POMOCe PROSTfEDKi Z OPERACE "METHEOR" JSTE JE SCHOPNI OVLaDNOUT.', _YES);
      MissionSpecManagerTag1:=1;
  end;
  if ((Pom = 38) and (Units[1150] <> Nil) and (Units[1150]^.Visibility) and
      (MissionSpecManagerTag1 = 0) and (_unit <> Nil) and (_unit^.Index = 1150))
      then begin
      WideDialogBox('  VAgI MUkI PfED SEBOU SPATfILI NEHYBNOU JEDNOTKU. PO ROZPADU',
                    'feDeCeCH CENTER PfESTALI NdKTEfe ROBOTI DOSTaVAT feDeCe SIGNaLY.',
                    'ZA POMOCe PROSTfEDKi Z OPERACE "METHEOR" JSTE JE SCHOPNI OVLaDNOUT.', _YES);
      MissionSpecManagerTag1:=1;
  end;
  {}
  with (_unit^) do with (Unit_types[UnitType,1]) do begin
     I:=Index;
     IP:=IPos; JP:=JPos; UnitTyp:=UnitType; ExperiencLevel:=ExperienceLevel;
     Experienc:=Experience; Kill:=Kills; Nam:=_unit^.Name; BuildType:=BuildingType;
     SpecNum:=SpecNumber; Strength:=Damage;

     Sold:=True;
     if (not Activity) then Disband_unit(Units[Index],False,False)
     else Disband_unit(Units[Index],True,False);
     Units[I]:=Nil;

     I:=New_unit(IP,JP,UnitTyp,MyRace,ExperiencLevel,0,True,False,BuildType);
     Units[I]^.Name:=Nam; Units[I]^.Experience:=Experienc;
     Units[I]^.Kills:=Kill; Units[I]^.SpecNumber:=SpecNum;
     Units[I]^.Damage:=Strength; Units[I]^.RequestDraw:=True;
  end;
end;

{ ***** }
procedure ChangeBuildingToMyRace(Build:PBuilding);
{ zmeni jednotku na mou rasu }
var I,J,IP,JP:Word;
    BuildingTyp,Phas:Byte;
begin
  with (Build^) do begin
     I:=Index;
     IP:=IPos; JP:=JPos; BuildingTyp:=BuildingType; Phas:=Phase;

     Sold:=True;
     Destroy_building(Buildings[Index],True);
     Buildings[I]:=Nil;

     I:=New_building(IP,JP,BuildingTyp,MyRace,True,4,False);
  end;
end;

{ ***** }
procedure Civilian_move(_unit:PUnit);
{
}
var I,J:Integer;
    Level:Byte;
begin
  with (_unit^) do begin
    if ((Status = 0) and (Rand(RndUk) < 8)) then begin
    { stoji - zahaj pohyb }
      CivilianMoveFlag:=0;
      CivilianMoveLimit:=3+Random(10); { limit = urazene pole }
      I:=IPos; J:=JPos;
      if (Rand(RndUk) mod 2 = 0) then I:=I + Random(5)
      else I:=I - Random(5);
      if (Rand(RndUk) mod 2 = 0) then J:=J + Random(5)
      else J:=J - Random(5);
      if (I < 0) then I:=Random(4); if (J < 0) then J:=Random(4);
      if (I > IMax) then I:=IMax-Random(4); if (J > JMax) then J:=JMax-Random(4);
      WayPointUk:=0;
      Set_move_unit(I,J,_unit,0,False,False);
    end else begin
    { pohyb - zastav jednotku }
      CivilianMoveFlag:=0;
      CivilianMoveLimit:=Random(15)+Random(150); { limit = pocet time slotu }
      Stop_:=True;
    end;
  end;
end;

{ ***** }
procedure Buttons2_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'12'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Buttons2_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'12'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)
  then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************** }
begin
end.
