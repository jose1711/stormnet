
unit _Shot;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, Grafika2;
procedure Init_shots;
procedure New_shot(IPosic,JPosic,IAim,JAim:Word; Dir,Lev,Weapon,UnitType:Byte;
                   var _unit:PUnit; Targe:PPUnit; BTarge:PPBuilding);
procedure Destroy_shot(var Shot:PShots);
procedure Finish_shots;
procedure Flash(_unit:PUnit; X1,Y1:Word; OnlyFlash:Boolean);
procedure Set_place_shot(I, J :Word; Shot:PShots; Sets:Boolean);
procedure Shot_manager;
procedure _shot_save;
procedure _shot_load;

implementation
uses _units, _units2, _units3, _Buildings, Buttons, Graph257, _races, AI2,
     SBSound, Buttons2;

procedure Program_shot(Shot:PShots; Missile:Boolean);
{ "naprogramuje" drahu strely podle toho, jestli jde o raketu
  (Missile = True) nebo o "normalni" projektil
}
var X, Y, XTarget, YTarget : Integer;
    A,B:Single;
    Direct:Byte;
begin
  Shot^.Missile:=Missile;
  with (Shot^) do if ((ITarget <> IPos) or (JTarget <> JPos)) then begin
    XTarget:=ITarget shl XCellShl + XCellSize shr 1;
    YTarget:=JTarget shl YCellShl + YCellSize shr 1;
    if (Missile) then begin
    { jde o raketu }
       Dir1:=0; Dir2:=0; Dir3:=0; Steps1:=0; Steps2:=0;
       A:=XTarget - XPos; B:=YTarget - YPos;
       X:=abs(Round(A/MissileMoveAdd)); Y:=abs(Round(B/MissileMoveAdd));
       { X, Y = pocet kroku do cile }
       Direct:=Best_direction2(IPos,JPos,ITarget,JTarget);
       case (Direct) of
         1  : begin
                 if (X = Y) then begin
                   Dir1:=Direct; Steps1:=X; Steps2:=0;
                 end else
                   {if (abs(X-Y) > 4) then begin
                     Dir2:=Direct;
                     if (X < Y) then begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=2; Steps2:=X; Dir3:=2;
                     end else begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=128;Steps2:=Y; Dir3:=128;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (X < Y) then begin
                       Steps1:=X; Dir2:=2; Steps2:=abs(X-Y);
                     end else begin
                       Steps1:=Y; Dir2:=128; Steps2:=abs(X-Y);
                     end;
                   end;
              end;
         2  : begin
                 if (X = 0) then begin
                   Dir1:=Direct; Steps1:=Y; Steps2:=0;
                 end else
                   {if (X > 4) then begin
                     Dir2:=Direct;
                     if (XTarget < XPos) then begin
                       Steps1:=X shr 1; Dir1:=1; Steps2:=abs(X-Y); Dir3:=1;
                     end else begin
                       Steps1:=X shr 1; Dir1:=4; Steps2:=abs(X-Y); Dir3:=4;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (XTarget < XPos) then begin
                       Steps1:=abs(X-Y); Dir2:=1; Steps2:=X;
                     end else begin
                       Steps1:=abs(X-Y); Dir2:=4; Steps2:=X;
                     end;
                   end;
              end;
         4  : begin
                 if (X = Y) then begin
                   Dir1:=Direct; Steps1:=X; Steps2:=0;
                 end else
                   {if (abs(X-Y) > 4) then begin
                     Dir2:=Direct;
                     if (X < Y) then begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=2; Steps2:=X; Dir3:=2;
                     end else begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=8; Steps2:=Y; Dir3:=8;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (X < Y) then begin
                       Steps1:=X; Dir2:=2; Steps2:=abs(X-Y);
                     end else begin
                       Steps1:=Y; Dir2:=8; Steps2:=abs(X-Y);
                     end;
                   end;
              end;
         8  : begin
                 if (Y = 0) then begin
                   Dir1:=Direct; Steps1:=X; Steps2:=0;
                 end else
                   {if (Y > 4) then begin
                     Dir2:=Direct;
                     if (YTarget < YPos) then begin
                       Steps1:=Y shr 1; Dir1:=4; Steps2:=abs(X-Y); Dir3:=4;
                     end else begin
                       Steps1:=Y shr 1; Dir1:=16; Steps2:=abs(X-Y); Dir3:=16;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (YTarget < YPos) then begin
                       Steps1:=abs(X-Y); Dir2:=4; Steps2:=Y;
                     end else begin
                       Steps1:=abs(X-Y); Dir2:=16; Steps2:=Y;
                     end;
                   end;
              end;
         16 : begin
                 if (X = Y) then begin
                   Dir1:=Direct; Steps1:=X; Steps2:=0;
                 end else
                   {if (abs(X-Y) > 4) then begin
                     Dir2:=Direct;
                     if (X < Y) then begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=32; Steps2:=X; Dir3:=32;
                     end else begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=8; Steps2:=Y; Dir3:=8;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (X < Y) then begin
                       Steps1:=X; Dir2:=32; Steps2:=abs(X-Y);
                     end else begin
                       Steps1:=Y; Dir2:=8; Steps2:=abs(X-Y);
                     end;
                   end;
              end;
         32 : begin
                 if (X = 0) then begin
                   Dir1:=Direct; Steps1:=Y; Steps2:=0;
                 end else
                   {if (X > 4) then begin
                     Dir2:=Direct;
                     if (XTarget < XPos) then begin
                       Steps1:=X shr 1; Dir1:=64; Steps2:=abs(X-Y); Dir3:=64;
                     end else begin
                       Steps1:=X shr 1; Dir1:=16; Steps2:=abs(X-Y); Dir3:=16;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (XTarget < XPos) then begin
                       Steps1:=abs(X-Y); Dir2:=64; Steps2:=X;
                     end else begin
                       Steps1:=abs(X-Y); Dir2:=16; Steps2:=X;
                     end;
                   end;
              end;
         64 : begin
                 if (X = Y) then begin
                   Dir1:=Direct; Steps1:=X; Steps2:=0;
                 end else
                   {if (abs(X-Y) > 4) then begin
                     Dir2:=Direct;
                     if (X < Y) then begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=32; Steps2:=X; Dir3:=32;
                     end else begin
                       Steps1:=abs(X-Y) shr 1; Dir1:=128; Steps2:=Y; Dir3:=128;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (X < Y) then begin
                       Steps1:=X; Dir2:=32; Steps2:=abs(X-Y);
                     end else begin
                       Steps1:=Y; Dir2:=128; Steps2:=abs(X-Y);
                     end;
                   end;
              end;
         128: begin
                 if (Y = 0) then begin
                   Dir1:=Direct; Steps1:=X; Steps2:=0;
                 end else
                   {if (Y > 4) then begin
                     Dir2:=Direct;
                     if (YTarget < YPos) then begin
                       Steps1:=Y shr 1; Dir1:=1; Steps2:=abs(X-Y); Dir3:=1;
                     end else begin
                       Steps1:=Y shr 1; Dir1:=64; Steps2:=abs(X-Y); Dir3:=64;
                     end;
                   end else{} begin
                     Dir1:=Direct;
                     if (YTarget < YPos) then begin
                       Steps1:=abs(X-Y); Dir2:=1; Steps2:=Y;
                     end else begin
                       Steps1:=abs(X-Y); Dir2:=64; Steps2:=Y;
                     end;
                   end;
              end;
       end;
    end else begin
    { nejde o raketu }
       if (DeltaX > DeltaY) then begin
         XAdd:=MissileMoveAdd;
         A:=XTarget - XPos; A:=A/MissileMoveAdd;
         B:=YTarget-YPos;
         YAdd:=Abs(Round(B/A));
       end else
         if (DeltaX < DeltaY) then begin
            YAdd:=MissileMoveAdd;
            A:=YTarget - YPos; A:=A/MissileMoveAdd;
            B:=XTarget-XPos;
            XAdd:=Abs(Round(B/A));
         end else begin
            XAdd:=MissileMoveAdd; YAdd:=MissileMoveAdd;
         end;
       {x}
       if (XPos > XTarget) then XAdd:=-XAdd;
       if (YPos > YTarget) then YAdd:=-YAdd;
    end;
  end else begin
  { jde o cil }
     Dir1:=Direction; Steps1:=1;
  end;
end;

{ ***** }
procedure Init_shots;
{ provedou se potrebne inicializace
}
var I:Integer;
begin
   for I:=1 to MaxMovingObjects do Shots[I]:=Nil;
   Number_of_shots:=0;
end;

{ ***** }
procedure New_shot(IPosic,JPosic,IAim,JAim:Word; Dir,Lev,Weapon,UnitType:Byte;
                   var _unit:PUnit; Targe:PPUnit; BTarge:PPBuilding);
{ procedura vytvori novou strelu o smeru Direction, pozici materske jednotky
  _unit IPosic, JPosic, cili IAim, JAim, pohybove urovni cile Lev
  a typu strely dle jednotky UnitType a zbrane Weapon;
  Lev = 0 .. pozemni cil
      = 1 .. vzdusny cil
  Weapon = 1 .. zbran 1
         = 2 .. zbran 2
  Targe, BTarge jsou ukazatele na cil
}
var I, J, IPom, JPom, Dist:Word;
begin
  if (Number_of_shots = MaxMovingObjects) then Error(0,'prekrocen max. pocet strel ve hre')
  else begin
  { nejprve vyhledame volny slot }
     if (_unit^.race <> MyRace) then begin
        Inc(Counter1);
     end else Inc(Counter2);

     I:=1; while (Shots[I] <> Nil) do Inc(I);
     { volny slot nalezen }
     New(Shots[I]);
     if (Shots[I] = Nil) then Error(0, 'chyba pri alokaci konvencni pameti');
     Inc(Number_of_shots);

     with (Shots[I]^) do begin
        Next:=Nil;
        Father:= @Units[_unit^.Index]; { ukazatel na zdrojovou jednotku strely }
        { pozn. jde o ukazatel na ukazatel, t.j. je vzdy treba pro
          praci provest pocatecni prirazeni do pomocne promenne:
          _unit = Father^ }
        ShotRace:=_unit^.Race;
        Target:=Targe; BTarget:=BTarge;
        TargetMovementLevel:=Lev;  S:=0; O:=0;
        Index:=I;
        ITarget:=IAim; JTarget:=JAim; { souradnice cile na mape }
        IPos:=IPosic; JPos:=JPosic; { aktualni souradnice strely }
        XPos:=IPos shl XCellShl+XCellSize shr 1; YPos:=JPos shl YCellShl+YCellSize shr 1;
        case (Dir) of
          1  : begin First:=0; XPos:=XPos-(16-MissileMoveAdd); YPos:=YPos-(16-MissileMoveAdd); end;
          2  : begin First:=0; YPos:=YPos-(16-MissileMoveAdd); end;
          4  : begin First:=0; XPos:=XPos+(16-MissileMoveAdd); YPos:=YPos-(16-MissileMoveAdd); end;
          8  : begin First:=0; XPos:=XPos+(16-MissileMoveAdd); end;
          16 : begin First:=0; XPos:=XPos+(16-MissileMoveAdd); YPos:=YPos+(16-MissileMoveAdd); end;
          32 : begin First:=0; YPos:=YPos+(16-MissileMoveAdd); end;
          64 : begin First:=0; XPos:=XPos-(16-MissileMoveAdd); YPos:=YPos+(16-MissileMoveAdd); end;
          128: begin First:=0; XPos:=XPos-(16-MissileMoveAdd); end;
        end;
        if (Weapon = 1) then with (Unit_types[UnitType,Races[ShotRace].Ally]) do begin
          AttackLevel:=AttackLevel1;
          AttackPicture:=Picture1;
          PreparePlaySound(2,GetVolume(IPosic,JPosic),Picture1,0);
        end else with (Unit_types[UnitType,Races[ShotRace].Ally]) do begin
          AttackLevel:=AttackLevel2;
          AttackPicture:=Picture2;
          PreparePlaySound(2,GetVolume(IPosic,JPosic),Picture1,0);
        end;
        if (AttackLevel = 5) then
        with (Unit_types[UnitType,Races[ShotRace].Ally]) do begin
        { u spec. zbrani se projevi nova strela ihned na cili }
          IPosic:=IAim; JPosic:=JAim;
          IPos:=IPosic; JPos:=JPosic; { aktualni souradnice strely }
          XPos:=IPos shl XCellShl+XCellSize shr 1; YPos:=JPos shl YCellShl+YCellSize shr 1;
          Status:=1;
          S:=Explosions[AttackPicture].S1; O:=Explosions[AttackPicture].O1;
        end else begin
          Status:=0;
          Direction:=Best_direction2(IPosic,JPosic,IAim,JAim);
        end;

        if ((AttackLevel < 5) and (Unit_types[UnitType,Races[ShotRace].Ally].GuidedMissile))
        then Guided:=True else Guided:=False;
        XOffset:=XPos mod XCellSize;
        YOffset:=YPos mod YCellSize;
        Phase:=0;
        if (Weapon = 1) then begin
        { zbran 1 }
           LightAttack:=Unit_types[UnitType,Races[ShotRace].Ally].LightAttack1+_unit^.LAttackBonus1;
           HeavyAttack:=Unit_types[UnitType,Races[ShotRace].Ally].HeavyAttack1+_unit^.HAttackBonus1;
           AirAttack:=Unit_types[UnitType,Races[ShotRace].Ally].AirAttack1+_unit^.AAttackBonus1;
        end else begin
        { zbran 2 }
           LightAttack:=Unit_types[UnitType,Races[ShotRace].Ally].LightAttack2+_unit^.LAttackBonus2;
           HeavyAttack:=Unit_types[UnitType,Races[ShotRace].Ally].HeavyAttack2+_unit^.HAttackBonus2;
           AirAttack:=Unit_types[UnitType,Races[ShotRace].Ally].AirAttack2+_unit^.AAttackBonus2;
        end;
        if ((_unit^.UnitType = 18) or (_unit^.UnitType = 19)) then begin
        { stihac, terminator se posili }
           Dist:=GetDistance(IPos,JPos,ITarget,JTarget);
           if (Dist < 8) then Dist:=0 else Dist:=Dist-8;
           LightAttack:=LightAttack+Round((1.2*LightAttack/100)*Dist);
           HeavyAttack:=HeavyAttack+Round((1.2*HeavyAttack/100)*Dist);
           AirAttack:=AirAttack+Round((0.7*AirAttack/90)*Dist);
        end;
        {X}
        _unit^.AttackL:=AttackLevel;
        if (AttackLevel = 0) then Flash(_unit,65535,65535,False); { zablesk }
        if (AttackLevel = 5) then  Level:=Lev;
        if (AttackLevel = 5) then Temp:=0 else Temp:=1; { pomocna promenna }

        { vypocitavani parametru pro pohyb strely }
        DeltaX:=abs(Integer(IAim)-IPos);
        DeltaY:=abs(Integer(JAim)-JPos);
        { konec uvodni inicializace }
        if (DeltaX >= DeltaY) then begin
          Delka:=abs(Integer(IAim)-IPos); { jeste inicializace }
        end else begin
          Delka:=abs(Integer(JAim)-JPos); { jeste inicializace }
        end;
        if ((DeltaX = 0) and (DeltaY = 0)) then Delka:=0;

        IPosOld:=IPos; JPosOld:=JPos;
        if ((AttackPicture >= 3) and (AttackPicture <= 5)) then
        { jde o raketu }
           Program_shot(Shots[I],True)
        else { nejde o raketu }  Program_shot(Shots[I],False);
     end; { with (Shots[I]^) do }
     Set_place_shot(IPosic, JPosic, Shots[I], True);

     if (Shots[I]^.AttackLevel = 5) then begin
        { AUTODETONATOR }
        _unit^.Destroyed:=True;
        Disband_unit(_unit,True,False);
        Shots[I]^.Father:=Nil;
     end;
  end;
end;

{ ***** }
procedure Destroy_shot(var Shot:PShots);
{
}
var I:Word;
begin
   if (Shot <> Nil) then begin
      with (Shot^) do begin
        Dec(Number_of_Shots);
        Set_place_shot(IPos,JPos, Shot, False);
        Shot^.Visibility:=True; { kazdopadne zruseni zbytku }
        if (AttackLevel > 0) then Erase_shot(Shot,True);{}
        I:=Shot^.Index;
        Dispose(Shot);
        Shot:=Nil;
        Shots[I]:=Nil;
      end;
   end;
end;

{ ***** }
procedure Prepare_destroy_shot(var Shot:PShots);
{ procedura projevi ucinky strely na cili
}
label Konec;
var _unit, PomUnit:PUnit;
    Build:PBuilding;
    Level, Rac:Byte;
    I,J,Attack:Word;
    DrawFire:Boolean;
    PomBuilding:PBuilding;
    Id:Byte;
    DMGStrength, DMG:Double;
begin
   if (Shot <> Nil) then begin
      with (Shot^) do begin
        DrawFire:=True;
        { nyni se projevi poskozeni na cili }
        with (Map^[IPos,JPos]) do begin
          if (TargetMovementLevel = 0) then begin
          { pozemni cil }
            if (First_level <> 0) then begin { je zde nejaky cil }
              if (Level_type and 128 = 0) then begin
              { jde o pozemni jednotku }
                 _unit:=Units[First_level];
                 if (not _unit^.Activity) then GoTo Konec;
                 case (_unit^.TargetType) of
                   0 : begin { lehky }
                          Attack:=LightAttack;
                          DrawFire:=False;
                       end;
                   1 : begin { lehky }
                          Attack:=LightAttack;
                          DrawFire:=True;
                       end;
                   2 : begin { tezky }
                          Attack:=HeavyAttack;
                          DrawFire:=True;
                       end;
                   3 : begin { vzdusny }
                          Attack:=AirAttack;
                          DrawFire:=True;
                       end;
                   4 : begin { namorni = tezky }
                          Attack:=HeavyAttack;
                          DrawFire:=True;
                       end;
                 end;
                 if (_unit^.Damage <= Attack) then with (_unit^) do begin
                 { ZNIC JEDNOTKU }
                   if (Activity) then begin
                    _unit^.Destroyed:=True;
                    UpdateRaceBattlePoints(ShotRace,UnitType,False,DamageBonus,
                                           LAttackBonus1,HAttackBonus1,AAttackBonus1);
                    UpdateScore(ShotRace,UnitType,False,True,DamageBonus,
                                LAttackBonus1,HAttackBonus1,AAttackBonus1,False);
                    Inc(Races[ShotRace].KilledUnits[UnitType]);
                    if ((Father <> Nil) and (Father^ <> Nil)) then
                    with ((Father^)^) do begin
                    { uprava moralky a hodnosti }
                      Inc(Experience,UnitHitExp); Inc(Experience,UnitKillExp);
                      Morale:=Morale+Round(
                              GetMoraleModif(Race,_unit^.UnitType,False,
                                  _unit^.DamageBonus,_unit^.LAttackBonus1,
                                  _unit^.HAttackBonus1,_unit^.AAttackBonus1)/
                              Single_morale_eval_div);
                      Inc(Kills);
                      Change_unit_experience_morale(Father^);
                      IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
                      case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                        0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                      end;
                      if (TimeSlot mod 3 <> 0) then
                       if ((Races[Race].RaceType <> 3) and (Races[Race].RaceType <> 6))
                       then begin
                          if ((Race = MyRace) or (TimeSlot mod 2 = 0)) then
                            PreparePlaySound(0,GetVolume(IPos,JPos),4,Id)
                       end else begin
                          if ((Race = MyRace) or (TimeSlot mod 2 = 0)) then
                            PreparePlaySound(1,GetVolume(IPos,JPos),4,Id);
                       end;
                    end;
                    Activity:=False;
                    if ((Rand(RndUk) > 6) and (TargetType = 0))
                    then DestroyEffect:=True else DestroyEffect:=False;
                    Status:=Direction;
                    Direction:=0;
                    MoveStatus:=0;
                    if (_unit^.TargetType = 0) then Phase:=Max_units_explosion_phase+1
                    else Phase:=0;
                    if (Visibility) then Erase_unit(_unit,True);
                    if (UnitsInsideNum <> 0) then begin
                    { pokud jsou uvnitr nalozeny nejake jednotky }
                       for I:=0 to MaxGroupUnits-2 do begin
                         if ((UnitsInside[I] <> 0) and
                             (Units[UnitsInside[I]] <> Nil) and
                             (UnitsInsideNum > 0)) then
                         with (Units[UnitsInside[I]]^) do begin
                            { zapocteni nakladu do bodu }
                            UpdateRaceBattlePoints(ShotRace,UnitType,False,
                               DamageBonus,LAttackBonus1,HAttackBonus1,AAttackBonus1);
                            UpdateScore(ShotRace,UnitType,False,True,DamageBonus,
                               LAttackBonus1,HAttackBonus1,AAttackBonus1,False);
                            Inc(Races[ShotRace].KilledUnits[UnitType]);
                            {}
                            Selected:=True;
                            Destroyed:=True;{}
                            IInfoPos:=_unit^.IInfoPos;
                            JInfoPos:=_unit^.JInfoPos;
                            if (_unit^.Group = ActiveGroup) then
                               Clear_unit_slot(Units[_unit^.UnitsInside[I]]);
                            Disband_unit(Units[_unit^.UnitsInside[I]],True,False);{}
                            Dec(_unit^.UnitsInsideNum);
                         end;
                       end;
                    end;
                    if (Group <= MaxGroups) then with Groups[Group] do begin
                        if (Group = ActiveGroup) then begin
                          Clear_unit_slot(_unit);
                          Deselect_unit(_unit);
                          Dec(Count);
                          I:=GroupOrder;
                          Un[I]:=Nil;
                          if (Count = 0) then begin
                            Deselect_group(ActiveGroup);
                            if (Active(Stop)) then SetPasive(Stop,256);
                            if (Active(Patrol)) then SetPasive(Patrol,256);
                            if (Active(Nalozit)) then SetPasive(Nalozit,256);
                            if (Active(Vylozit)) then SetPasive(Vylozit,256);
                            if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                            if (Active(Opravit)) then SetPasive(Opravit,256);
                            if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                            ClearActiveDefenceRangeSlots;
                          end;
                        end else begin
                          Dec(Count);
                          I:=GroupOrder;
                          Un[I]:=Nil;
                        end;
                        Group:=254;
                    end;
                    case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                        0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                    end;
                    if ((Races[Race].RaceType <> 3) and (Races[Race].RaceType <> 6)) then
                      PreparePlaySound(0,GetVolume(IPos,JPos),3,Id)
                    else
                      PreparePlaySound(1,GetVolume(IPos,JPos),3,Id);
                   end; { if (Activity) }
                 end else with (_unit^) do begin
                 { *** POUZE SE ZMENI JEJI POSKOZENI *** }
                    if ((Father <> Nil) and (Father^ <> Nil)) then
                    with ((Father^)^) do begin
                    { uprava moralky a hodnosti }
                      Inc(Experience,UnitHitExp);
                      if (_unit^.UnitType = 29) then begin
                         Inc(Morale,HitDeprivator);
                      end else Inc(Morale,UnitHitMorale);
                      Change_unit_experience_morale(Father^);
                      if (UnitType = 29) then Inc(_unit^.Morale,DeprivatorHitMorale);
                    end;
                    if (Race = MyRace) then WarningBlingFlag:=MaxWarningBlingValue
                    else WarningBlingFlag:=Kadence[5];
                    Dec(Damage,Attack);
                    DMGStrength:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
                    DMGStrength:=DMGStrength/100; DMG:=Damage; DMG:=DMG/DMGStrength;
                    if (DMG <= 35) then
                      if ((FirePhase = 0) and FireAllowed and DrawFire)
                      then begin
                         FirePhase:=1;
                         Inc(Morale,RedDamage+ExperienceLevel shl 2);
                         case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                           0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                         end;
                         if (TimeSlot mod 2 = 0) then
                           if ((Races[Race].RaceType <> 3) and (Races[Race].RaceType <> 6)) then
                             PreparePlaySound(0,GetVolume(IPos,JPos),6,Id)
                           else
                             PreparePlaySound(1,GetVolume(IPos,JPos),6,Id);
                      end;
                    _unit^.RequestDraw:=True;
                    Inc(Experience,HitExp);
                    Inc(Morale,HitMorale+ExperienceLevel shr 2);
                    Change_unit_experience_morale(_unit);

                    { utoci se na jednotku, rizenou AI - nastav taskgrupu
                     do stavu "volny utok", at muze opetovat; zaroven zvys
                     "Timeout" pro splneni prikazu; navic jde-li o carrier,
                     zkus naklad vylozit }
                    with (Races[Race]) do
                    if ((TaskGroup <> InvalidTaskGroupNumber) and
                        (TaskGroups^[TaskGroup].Validity))
                    then with (TaskGroups^[TaskGroup]) do begin
                      if (KamikadzeMode) then begin
                        if (MasterCommand = AttackCom) then UnderAttack:=True;
                      end else begin
                         GrpFree_attack:=True; CommandLockFlagLimit:=1000;
                         if ((UnitsInsideNum <> 0) and
                            ((TaskGroup <> 12) and (DMG < 63) or
                             (TaskGroup = 12) and (DMG < 50)))
                         then begin
                            Unload(_unit);
                            if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then Down:=2;
                            if (UnitType = 17) then _unit^.STOP_:=True;
                         end;
                      end;
                    end;

                    if (Group = ActiveGroup) then
                      UpdateDmg:=True;
                    { nyni zkus opetovat utok }
                    if ((Status = 0) and ((MoveStatus <= 1) or (MoveStatus = 64)) and
                        (not KamikadzeMod) and
                        ((Race = MyRace) or (Race = ThisCompRace1) or
                         (Race = ThisCompRace2) or (Race = ThisCompRace3) or
                         (Race = ThisCompRace4) or (Race = ThisCompRace5)))
                    then begin
                    { jednotka musi byt v klidu nebo patrolovat }
                        if ((Father <> Nil) and (Father^ <> Nil) and
                            (Father^^.Activity)) then begin
                        { cil existuje a je aktivni }
                           PomUnit:=Father^;
                           if ((ActiveDefence) or (Race <> MyRace))
                           then Attack:=16 else Attack:=32;
                           if (PomUnit^.TargetType = 3) then Level:=1
                           else Level:=0;
                           PomBuilding:=Nil;
                           Prepare_attack_unit(Units[PomUnit^.Index],PomBuilding,Attack,_unit,Level);
                        end;
                    end;
                 end;
              end else begin  { jde o budovu }
                  Build:=Buildings[First_level];
                  if (not Build^.Activity) then GoTo Konec;
                  Attack:=HeavyAttack;
                  if (AttackLevel = 5) then Attack:=Attack + Attack div 3;{}
                  { zvysena ucinnost autodetonatoru vuci budovam }
                  if (Build^.Damage <= Attack) then with (Build^) do begin
                  { ZNIC BUDOVU }
                   if (Activity) then begin
                     SetAttackFlagForPlaceForBuilding(Race,IPos,JPos);
                     UpdateRaceBattlePoints(ShotRace,BuildingType,True,0,0,0,0);
                     UpdateScore(ShotRace,BuildingType,True,True,0,0,0,0,False);
                     Inc(Races[ShotRace].KilledBuildings[BuildingType]);
                     if ((Father <> Nil) and (Father^ <> Nil)) then
                     with ((Father^)^) do begin
                     { uprava moralky a hodnosti }
                       Inc(Experience,BuildingHitExp);
                       Inc(Experience,BuildingKillExp);
                       Morale:=Morale+Round(
                                    GetMoraleModif(Race,Build^.BuildingType,False,
                                             0,0,0,0)/Single_morale_eval_div);
                       Inc(Kills);
                       Change_unit_experience_morale(Father^);
                       IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
                       {case (Unit_types[UnitType].TargetTyp) of
                         0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                       end;
                       if (Races[Race].RaceType <> 3) then
                         PreparePlaySound(0,GetVolume(IPos,JPos),4,Id)
                       else
                         PreparePlaySound(1,GetVolume(IPos,JPos),4,Id);{}
                     end;
                     Activity:=False;
                     Set_place_building(IPos,JPos, Build, False);
                     if (Visibility) then Erase_building(Build);
                     Set_place_building(IPos,JPos, Build, True);{}
                     Pom:=-127; Phase:=1;
                     if (Group = ActiveGroup) then with Groups[Group] do begin
                        if (Active(Opravit)) then SetPasive(Opravit,256);
                        if (Active(Stop)) then SetPasive(Stop,256);
                        Clear_group_slots;
                        Deselect_group(ActiveGroup);
                        ActiveGroup:=255;
                     end;
                     Group:=254;
                   end; { if (Activity) }
                  end else with (Build^) do begin
                  { *** POUZE SE ZMENI JEJI POSKOZENI *** }
                     if ((Father <> Nil) and (Father^ <> Nil)) then
                     with ((Father^)^) do begin
                     { uprava moralky a hodnosti }
                       Inc(Experience,BuildingHitExp);
                       Inc(Morale,BuildingHitMorale);
                       Change_unit_experience_morale(Father^);
                     end;
                     if (Race = MyRace) then WarningBlingFlag:=GetAccurateDelay(MaxWarningBlingValue)
                     else WarningBlingFlag:=Kadence[5];
                     SetAttackFlagForPlaceForBuilding(Race,IPos,JPos);
                     Dec(Damage,Attack);
                     if (Group = ActiveGroup) then
                       Update_building_char(Build);
                     with (Building_types[BuildingType]) do begin
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
                        if ((FirePhase = 0) and FireAllowed and DrawFire and
                            (FireState <> 0)) then FirePhase:=1;
                        if ((IBuildingSize = 1) and (JBuildingSize = 1) and
                            (FireState = 2)) then FireState:=1;
                     end;
                  end;
              end;  { jde o budovu }
            end; { na pozmeni urovni neco existuje }

          end else begin { vzdusny cil }
             if (Second_level <> 0) then begin { je zde nejaky cil }
                _unit:=Units[Second_level];
                if (not _unit^.Activity) then GoTo Konec;
                Attack:=AirAttack; DrawFire:=True;
                {I:=_unit^.XOffset*_unit^.YOffset; J:=XCellSize*YCellSize;
                if (I <= J div 10) then Attack:=Attack shr 1
                else
                   if (I <= J div 4) then Attack:=(Attack shr 2)*3;{}
                if (_unit^.Damage <= Attack) then  with (_unit^) do begin
                { ZNIC JEDNOTKU }
                 if (Activity) then begin
                   _unit^.Destroyed:=True;
                   UpdateRaceBattlePoints(ShotRace,UnitType,False,DamageBonus,
                                          LAttackBonus1,HAttackBonus1,AAttackBonus1);
                   UpdateScore(ShotRace,UnitType,False,True,DamageBonus,
                                LAttackBonus1,HAttackBonus1,AAttackBonus1,False);
                   Inc(Races[ShotRace].KilledUnits[UnitType]);
                   if ((Father <> Nil) and (Father^ <> Nil)) then
                   with ((Father^)^) do begin
                   { uprava moralky a hodnosti }
                     Inc(Experience,UnitHitExp); Inc(Experience,UnitKillExp);
                     Morale:=Morale+Round(
                              GetMoraleModif(Race,_unit^.UnitType,False,
                                  _unit^.DamageBonus,_unit^.LAttackBonus1,
                                  _unit^.HAttackBonus1,_unit^.AAttackBonus1)/
                              Single_morale_eval_div);
                     Inc(Kills);
                     Change_unit_experience_morale(Father^);
                     IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
                     case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                        0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                     end;
                     if (TimeSlot mod 3 <> 0) then
                       if ((Races[Race].RaceType <> 3) and (Races[Race].RaceType <> 6))
                       then begin
                          if ((Race = MyRace) or (TimeSlot mod 2 = 0)) then
                            PreparePlaySound(0,GetVolume(IPos,JPos),4,Id)
                       end else begin
                          if ((Race = MyRace) or (TimeSlot mod 2 = 0)) then
                            PreparePlaySound(1,GetVolume(IPos,JPos),4,Id);
                       end;
                   end;
                   Status:=Direction;
                   Direction:=0;
                   Activity:=False;
                   if ((Rand(RndUk) > 6) and (TargetType = 0))
                   then DestroyEffect:=True else DestroyEffect:=False;
                   MoveStatus:=0;
                   if (_unit^.TargetType = 0) then Phase:=Max_units_explosion_phase+1
                   else Phase:=0;
                   if (Visibility) then Erase_unit(_unit,True);
                   if (UnitsInsideNum <> 0) then begin
                   { pokud jsou uvnitr nalozeny nejake jednotky }
                       for I:=0 to MaxGroupUnits-2 do begin
                         if ((UnitsInside[I] <> 0) and
                             (Units[UnitsInside[I]] <> Nil) and
                             (UnitsInsideNum > 0)) then
                         with (Units[UnitsInside[I]]^) do begin
                            { zapocteni nakladu do bodu }
                            UpdateRaceBattlePoints(ShotRace,UnitType,False,
                               DamageBonus,LAttackBonus1,HAttackBonus1,AAttackBonus1);
                            UpdateScore(ShotRace,UnitType,False,True,DamageBonus,
                               LAttackBonus1,HAttackBonus1,AAttackBonus1,False);
                            Inc(Races[ShotRace].KilledUnits[UnitType]);
                            {}
                            Selected:=True;
                            Destroyed:=True;
                            IInfoPos:=_unit^.IInfoPos;
                            JInfoPos:=_unit^.JInfoPos;
                            if (_unit^.Group = ActiveGroup) then
                               Clear_unit_slot(Units[_unit^.UnitsInside[I]]);
                            Disband_unit(Units[_unit^.UnitsInside[I]],True,False);
                            Dec(_unit^.UnitsInsideNum);
                         end;
                       end;
                   end;
                   if (Group <= MaxGroups) then with Groups[Group] do begin
                        if (Group = ActiveGroup) then begin
                          Clear_unit_slot(_unit);
                          Deselect_unit(_unit);
                          Dec(Count);
                          I:=GroupOrder;
                          Un[I]:=Nil;
                          if (Count = 0) then begin
                            Deselect_group(ActiveGroup);
                            if (Active(Stop)) then SetPasive(Stop,256);
                            if (Active(Patrol)) then SetPasive(Patrol,256);
                            if (Active(Nalozit)) then SetPasive(Nalozit,256);
                            if (Active(Vylozit)) then SetPasive(Vylozit,256);
                            if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                            if (Active(Opravit)) then SetPasive(Opravit,256);
                            if (Active(ZvednoutMoralku)) then SetPasive(ZvednoutMoralku,256);
                            ClearActiveDefenceRangeSlots;
                          end;
                        end else begin
                          Dec(Count);
                          I:=GroupOrder;
                          Un[I]:=Nil;
                        end;
                        Group:=254;
                   end;
                   case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                     0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                   end;
                   if ((Races[Race].RaceType <> 3) and (Races[Race].RaceType <> 6)) then
                     PreparePlaySound(0,GetVolume(IPos,JPos),3,Id)
                   else
                     PreparePlaySound(1,GetVolume(IPos,JPos),3,Id);
                 end; { if (Activity) }
                end else with (_unit^) do begin
                { *** POUZE SE ZMENI JEJI POSKOZENI *** }
                   if ((Father <> Nil) and (Father^ <> Nil)) then
                   with ((Father^)^) do begin
                   { uprava moralky a hodnosti }
                     Inc(Experience,UnitHitExp);
                     Inc(Morale,UnitHitMorale);
                     Change_unit_experience_morale(Father^);
                     if (UnitType = 29) then Inc(_unit^.Morale,DeprivatorHitMorale);
                   end;
                   if (Race = MyRace) then WarningBlingFlag:=MaxWarningBlingValue
                   else WarningBlingFlag:=Kadence[5];
                   Dec(Damage,Attack);
                   DMGStrength:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus;
                   DMGStrength:=DMGStrength/100; DMG:=Damage; DMG:=DMG/DMGStrength;
                   if (DMG <= 35) then
                      if ((FirePhase = 0) and FireAllowed and DrawFire)
                      then begin
                         FirePhase:=1;
                         Inc(Morale,RedDamage+ExperienceLevel shl 2);
                         case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                           0:Id:=0; 1:Id:=1; 2:Id:=1; 3:Id:=2;
                         end;
                         if (TimeSlot mod 2 = 0) then
                           if ((Races[Race].RaceType <> 3) and (Races[Race].RaceType <> 6)) then
                             PreparePlaySound(0,GetVolume(IPos,JPos),6,Id)
                           else
                             PreparePlaySound(1,GetVolume(IPos,JPos),6,Id);
                      end;
                   _unit^.RequestDraw:=True;
                   Inc(Experience,HitExp);
                   Inc(Morale,HitMorale+ExperienceLevel shr 2);
                   { utoci se na jednotku, rizenou AI - nastav taskgrupu
                     do stavu "volny utok", at muze opetovat; zaroven zvys
                     "Timeout" pro splneni prikazu; navic jde-li o carrier,
                     zkus naklad vylozit }
                   with (Races[Race]) do
                   if ((TaskGroup <> InvalidTaskGroupNumber) and
                       (TaskGroups^[TaskGroup].Validity))
                   then with (TaskGroups^[TaskGroup]) do begin
                     if (KamikadzeMode) then begin
                       if (MasterCommand = AttackCom) then UnderAttack:=True;
                     end else begin
                        GrpFree_attack:=True; CommandLockFlagLimit:=1000;
                        if ((UnitsInsideNum <> 0) and
                            ((TaskGroup <> 12) or (TaskGroup = 12) and
                             (DMG < 50)))
                        then begin
                           Unload(_unit);
                           if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then Down:=2;
                           if (UnitType = 17) then _unit^.STOP_:=True;
                        end;
                     end;
                   end;

                   Change_unit_experience_morale(_unit);
                   if (Group = ActiveGroup) then
                     UpdateDmg:=True;
                   if ((Status = 0) and ((MoveStatus <= 1) or (MoveStatus = 64)) and
                       (not KamikadzeMod) and
                       ((Race = MyRace) or (Race = ThisCompRace1) or
                         (Race = ThisCompRace2) or (Race = ThisCompRace3) or
                         (Race = ThisCompRace4) or (Race = ThisCompRace5))) then begin
                   { jednotka musi byt v klidu nebo patrolovat }
                        if ((Father <> Nil) and (Father^ <> Nil) and
                            (Father^^.Activity)) then begin
                        { cil existuje a je aktivni }
                           PomUnit:=Father^;
                           if ((ActiveDefence) or (Race <> MyRace))
                           then Attack:=16 else Attack:=32;
                           if (PomUnit^.TargetType = 3) then Level:=1
                           else Level:=0;
                           PomBuilding:=Nil;
                           Prepare_attack_unit(Units[PomUnit^.Index],PomBuilding,Attack,_unit,Level);
                        end;
                   end;
                end;
             end;
          end; { vzdusny cil }
        end; { with (Map^[IPos,JPos]) do begin }
      end;
  end;
Konec:
end;

{ ***** }
procedure Finish_shots;
{ zrusi vsechny strely, ktere existuji
}
var I, J : Word;
begin
    I:=1; J:=1;
    while ((I <= Number_of_shots) and (J <= MaxMovingObjects)) do begin
      if (Shots[J] <> Nil) then begin
        Dispose(Shots[J]);
        Shots[J]:=Nil;
        Inc(I);
      end;
      Inc(J);
    end;{}
end;

{ ***** }
procedure Flash(_unit:PUnit; X1,Y1:Word; OnlyFlash:Boolean);
{ procedura zajisti vykresleni zablesku jednotky _unit, patrici
  zbrani o urovni AttackLevel a majici bodovou pozici na
  obrazovce X1,Y1 (jen pro OnlyFlash = True; pro = False neplatna
  hodnota)
  OnlyFlash = True .. procedura je volana z pohybujici se jednotky,
                      staci tedy vykreslit jen zablesk
  OnlyFlash = False.. procedura je volana ze stojici jednotky
                      a tu je nutne celou prekreslit
                      ()
  pozn. volat jen tehdy, pokud se ma pracovat se zableskem (ne naplano!!!!)
}
var XX,YY: Word;
begin
   bebex:=0;
   with (_unit^) do begin
      bebex:=1; if (Activity) then bebey:=0 else bebey:=1;
      if (FlashFlag = 0) then begin
      { nova,prvni faze zablesku }
         FlashFlag:=2;
         with (Flashs[AttackL]) do begin
           save1:=Direction;
           case (Direction) of
              1   : if (S1 <> 0) then begin
                      bebex:=2;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[1]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=3;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S1,O1)
                      else Redraw_unit_with_flash(_unit,XX,YY,S1,O1);
                    end;
              2   : if (S2 <> 0) then begin
                      bebex:=4;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[2]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=5;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S2,O2)
                      else Redraw_unit_with_flash(_unit,XX,YY,S2,O2);
                    end;
              4   : if (S3 <> 0) then begin
                      bebex:=6;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[3]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=7;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S3,O3)
                      else Redraw_unit_with_flash(_unit,XX,YY,S3,O3);
                    end;
              8   : if (S4 <> 0) then begin
                      bebex:=8;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[4]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=9;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S4,O4)
                      else Redraw_unit_with_flash(_unit,XX,YY,S4,O4);
                    end;
              16  : if (S5 <> 0) then begin
                      bebex:=10;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[5]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=11;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S5,O5)
                      else Redraw_unit_with_flash(_unit,XX,YY,S5,O5);
                    end;
              32  : if (S6 <> 0) then begin
                      bebex:=12;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[6]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=13;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S6,O6)
                      else Redraw_unit_with_flash(_unit,XX,YY,S6,O6);
                    end;
              64  : if (S7 <> 0) then begin
                      bebex:=14;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[7]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=15;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S7,O7)
                      else Redraw_unit_with_flash(_unit,XX,YY,S7,O7);
                    end;
              128 : if (S8 <> 0) then begin
                      bebex:=16;
                      with (Unit_types[UnitType,Races[Race].Ally].FlashPos[8]) do begin
                         XX:=X; YY:=Y;
                      end;
                      bebex:=17;
                      if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S8,O8)
                      else Redraw_unit_with_flash(_unit,XX,YY,S8,O8);
                    end;
           end;
         end; { with (Flashs[AttackLevel]) do begin }
      end else begin
      { existujici vystrel }
         bebex:=18;
         if (GameTimming <> 0) then Inc(FlashFlag,1) { "jemna" varianta }
         else Inc(FlashFlag,2); { "hruba" varianta }
         bebex:=19;
         if (FlashFlag = 4) then begin { druha faze zablesku }
            bebex:=20;
            with (Flashs[AttackL]) do begin
              save1:=Direction;
              case (Direction) of
                 1   : if (S9 <> 0) then begin
                         bebex:=21;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[1]) do begin
                           XX:=X; YY:=Y;
                         end;
                          bebex:=22;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S9,O9)
                         else Redraw_unit_with_flash(_unit,XX,YY,S9,O9);
                       end;
                 2   : if (S10 <> 0) then begin
                          bebex:=23;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[2]) do begin
                           XX:=X; YY:=Y;
                         end;
                          bebex:=24;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S10,O10)
                         else Redraw_unit_with_flash(_unit,XX,YY,S10,O10);
                       end;
                 4   : if (S11 <> 0) then begin
                         bebex:=25;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[3]) do begin
                           XX:=X; YY:=Y;
                         end;
                          bebex:=26;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S11,O11)
                         else Redraw_unit_with_flash(_unit,XX,YY,S11,O11);
                       end;
                 8   : if (S12 <> 0) then begin
                          bebex:=27;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[4]) do begin
                           XX:=X; YY:=Y;
                         end;
                          bebex:=28;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S12,O12)
                         else Redraw_unit_with_flash(_unit,XX,YY,S12,O12);
                       end;
                 16  : if (S13 <> 0) then begin
                         bebex:=29;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[5]) do begin
                           XX:=X; YY:=Y;
                         end;
                         bebex:=30;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S13,O13)
                         else Redraw_unit_with_flash(_unit,XX,YY,S13,O13);
                       end;
                 32  : if (S14 <> 0) then begin
                         bebex:=31;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[6]) do begin
                           XX:=X; YY:=Y;
                         end;
                          bebex:=32;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S14,O14)
                         else Redraw_unit_with_flash(_unit,XX,YY,S14,O14);
                       end;
                 64  : if (S15 <> 0) then begin
                          bebex:=33;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[7]) do begin
                           XX:=X; YY:=Y;
                         end;
                         bebex:=34;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S15,O15)
                         else Redraw_unit_with_flash(_unit,XX,YY,S15,O15);
                       end;
                 128 : if (S16 <> 0) then begin
                         bebex:=35;
                         with (Unit_types[UnitType,Races[Race].Ally].FlashPos[8]) do begin
                           XX:=X; YY:=Y;
                         end;
                          bebex:=36;
                         if (OnlyFlash) then Draw_flash(X1+XX,Y1+YY,S16,O16)
                         else Redraw_unit_with_flash(_unit,XX,YY,S16,O16);
                       end;
              end;
            end; { with (Flashs[AttackLevel]) do begin }
         end else
           if (FlashFlag = 6) then begin { smazani zablesku}
             bebex:=37;
             FlashFlag:=0;
             if ((Flashs[AttackL].S1 <> 0) and (not OnlyFlash))
             then ReDraw_unit(_unit,True);
           end;
      end;
   end;
end;

{ ***** }
procedure Set_place_shot(I, J :Word; Shot:PShots; Sets:Boolean);
{ strela je urcena ukazatelem Shot; procedura nastavi u policka I,J
  priznak obsazenosti dle promenne Sets (True = obsazeno)
}
var K, L : Word;
    Pom: Boolean;
    Nextt, Preview:PShots;
begin
   with (Shot^) do with (Map^[I,J]) do with (MapBck^[I,J]) do
   with (MapBckTemp^[I,J]) do begin
      if (Sets) then begin { jednotka se nastavi }
          if (Level_type and 127 = 0) then { zadna strela na policku }
            Level_type:=Level_type + Index
          else begin  { nejaka strela na policku jiz je }
             Preview:=Shots[Level_type and 127];
             Nextt:=Preview^.Next;
             while (Nextt <> Nil) do begin
               Preview:=Nextt;
               Nextt:=Nextt^.Next;
             end;
             { zarad prvek do seznamu }
             Preview^.Next:=Shot;
             if ((Visibilit and Races[MyRace].VisMask  > 0) or (not Fog_of_war))
             then Visibility:=True else Visibility:=False;
          end;
      end else begin { projektil se smaze }
          if (Level_type and 127 = Index) then begin
            { strela na mape odpovida odalokovane }
             Level_type:=Level_type and 128;
             { nyni zkus do mapy zaradit dalsi strelu v poradi (je-li) }
             if (Next <> Nil) then
                 Level_type:=Level_type + Next^.Index;
          end else begin
             { vymazani strely v seznamu (neni prvni, t.j. neni zaznamenana
               na mape) }
             Preview:=Shots[Level_type and 127];
             Nextt:=Preview^.Next;
             while ((Nextt <> Shot) and (Nextt <> Nil)) do begin
               Preview:=Nextt;
               Nextt:=Nextt^.Next;
             end;
             if (Nextt = Nil) then Error(0,'units Shots, procedure Set_place_shot');
             { nyni vyradime prvek ze seznamu }
             Preview^.Next:=Next;
          end;
          Next:=Nil;
      end;

   end; { with (Shot^) }
end;

{ ***** }
procedure Draw_move_shot(Shot:PShots);
{ presune strelu ze stare pozice na nasledujici pozici,
  provede vykresleni, zmeni data, oznacujici pozici.
  UVOLNUJE priznaky obsazenosti jednotlivych policek v pripade,
  ze byl dokoncen pohyb na nove policko.
  IPosOld -> IPos; JPosOld -> JPos
}
var MovementAdding:Byte;
    A,B,C,D:Word;
begin
 with (Shot^) do begin
   if (First < 2) then Inc(First);
   if (First > 1) then begin
      A:=IPos; B:=JPos; C:=XPos; D:=YPos;
      IPos:=IPosOld; JPos:=JPosOld; XPos:=XPosOld; YPos:=YPosOld;
      Erase_shot(Shot,False);
      IPos:=A; JPos:=B; XPos:=C; YPos:=D;
   end else begin
      Temp:=0;
   end;
   Inc(Phase); if (Phase > 1) then Phase:=0;
   if ((IPosOld <> IPos) or (JPosOld <> JPos)) then begin
   { odstranit priznaky obsazenosti }
      Set_place_shot(IPosOld,JPosOld,Shot,False);
      Set_place_shot(IPos,JPos,Shot,True);
   end;
   if ((MapBckTemp^[IPos,JPos].Visibilit and Races[MyRace].VisMask  > 0) or (not Fog_of_war))
   then Visibility:=True else Visibility:=False;

   if (First > 1) then begin
     Draw_shot(Shot);
   end else {Inc(First){};
 end; { with }
end;

{ ***** }
procedure ShotLine(Shot:PShots);
{ dle zadanych parametru vypocita novy posun pozice strely
}
{ XXXXX }
var I:Word;
begin
 with (Shot^) do begin
   if ((IPos = ITarget) and (JPos = JTarget)) then Delka:=0
   else begin
      if (Missile) then begin
      { jde o raketu }
        case (Direction) of
           1  : begin
                   Dec(XPos,MissileMoveAdd); Dec(YPos,MissileMoveAdd);
                end;
           2  : begin
                   Dec(YPos,MissileMoveAdd);
                end;
           4  : begin
                   Inc(XPos,MissileMoveAdd); Dec(YPos,MissileMoveAdd);
                end;
           8  : begin
                   Inc(XPos,MissileMoveAdd);
                end;
           16 : begin
                   Inc(XPos,MissileMoveAdd); Inc(YPos,MissileMoveAdd);
                end;
           32 : begin
                   Inc(YPos,MissileMoveAdd);
                end;
           64 : begin
                   Dec(XPos,MissileMoveAdd); Inc(YPos,MissileMoveAdd);
                end;
           128: begin
                   Dec(XPos,MissileMoveAdd);
                end;
        end;
        {x}
        if (Steps1 > 0) then begin
          Direction:=Dir1;
          if ((Steps1 = 1) and (Steps2 <> 0)) then Direction:=Dir2;
          Dec(Steps1);
        end else
          if (Steps2 > 0) then begin
            Direction:=Dir2;
            if ((Steps2 = 1) and (Dir3 <> 0)) then Direction:=Dir3;
            Dec(Steps2);
          end else begin
            Direction:=Dir3;
          end;
      end else begin { if (Missile) then ... }
      { jde o "normalni" projektil }
        Inc(XPos,XAdd); Inc(YPos,YAdd);
      end;
      if (XPos < 0) then XPos:=XCellSize shr 2;
      if (YPos < 0) then YPos:=YCellSize shr 2;

      IPos:=XPos shr XCellShl; JPos:=YPos shr YCellShl;
      if (IPos > IMax) then begin
        IPos:=IMax; XPos:=IPos shl XCellShl+XCellSize shr 1+XCellSize shr 2;
      end;
      if (JPos > JMax) then begin
        JPos:=JMax; YPos:=JPos shl YCellShl+YCellSize shr 1+YCellSize shr 2;
      end;

   end; { if ((IPos = ITarget) and (JPos = JTarget)) then ... else }
 end; { with (Shot^) do }
end;

{ ***** }
procedure Shot_manager;
{ udrzuje strely a realizuje jejich exploze
}
label _Next, Explos, TargetDestroyed;
var I, J, P : Integer;
    PomX, PomY, PomX2, PomY2, XSize, YSize : Word;
    IPom, JPom:Word;
    PomTarget:PUnit;
    PomBTarget:PBuilding;
    XS,YS:Word;
begin
   I:=1; J:=1;
   while ((I <= Number_of_shots) and (J <= MaxMovingObjects)) do begin
      if (Shots[J] <> Nil) then with Shots[J]^ do begin
      { strela na danem indexu existuje }
        if (Status = 0) then begin { pohyb strely }
          if (Target <> Nil) then PomTarget:=Target^ else PomTarget:=Nil;
          if (BTarget <> Nil) then PomBTarget:=BTarget^ else PomBTarget:=Nil;

          if (Guided) then begin
          { rizena raketa }
             if ((PomTarget = Nil) and (PomBTarget = Nil)) then begin
                Delka:=0;
                GoTo TargetDestroyed;
             end;
             if (BTarget <> Nil) then begin
             { cilem je budova }
               {ITarget:=PomBTarget^.IPos; JTarget:=PomBTarget^.JPos;{}
               TargetMovementLevel:=0;
             end else begin
               if ((Target <> Nil) and (PomTarget <> Nil) and
                   (PomTarget^.Activity)) then begin
               { zvoleni cile }
                 ITarget:=PomTarget^.IPos; JTarget:=PomTarget^.JPos;
                 if ((PomTarget^.XOffset <> 0) and
                     (PomTarget^.Direction > 2) and
                     (PomTarget^.Direction < 32)) then
                    Inc(ITarget);
                 if ((PomTarget^.YOffset <> 0) and
                     (PomTarget^.Direction > 8) and
                     (PomTarget^.Direction < 128)) then
                    Inc(JTarget);
                 if (PomTarget^.TargetType = 3) then
                    TargetMovementLevel:=1
                 else
                    TargetMovementLevel:=0;
                 Program_shot(Shots[J],True);
               end else begin
                 Delka:=0;
                 GoTo TargetDestroyed;
               end;
             end;
          end;{ else begin}
TargetDestroyed:
          if (Delka = 0) then begin
            IPosOld:=IPos; JPosOld:=JPos; XPosOld:=XPos; YPosOld:=YPos;
            GoTo Explos;
          end;
          IPosOld:=IPos; JPosOld:=JPos; XPosOld:=XPos; YPosOld:=YPos;
          ShotLine(Shots[J]);
          XOffset:=XPos mod XCellSize; YOffset:=YPos mod YCellSize;

          if (AttackLevel = 0) then begin
          { pechotni zbran - nestrili pres stromy a baraky }
             with (MapBck^[IPosOld,JPosOld]) do begin
                if (Above(BckType,Wather) and BelowEqual(BckType,Wood) or
                    (Map^[IPosOld,JPosOld].Level_type and 128 = 128)) then begin
                  Delka:=0; IPos:=IPosOld; JPos:=JPosOld;
                end;
             end;{}
          end;
         { VYKRESLI STRELU }
         if (Delka <> 0) then Draw_move_shot(Shots[J])
         else begin
Explos:
           if ((MapBckTemp^[IPos,JPos].Visibilit and Races[MyRace].VisMask  > 0) or (not Fog_of_war))
           then Visibility:=True else Visibility:=False;
           if (First > 1) then Erase_shot(Shots[J],True);{}
           Status:=1; Phase:=0;
           if (AttackPicture < 6) then begin
             with (Bullets[AttackPicture]) do begin
               XS:=XSize; YS:=YSize;
               PomX2:=Explosions[AttackPicture].XShot; PomY2:=Explosions[AttackPicture].YShot;
               if (XS > PomX2) then XS:=XS-PomX2; if (YS > PomY2) then YS:=YS-PomY2;{}
               case (Direction) of
                1  : begin
                       if (XOffset <= XS) then if (XOffset=0)then XS:=0 else XS:=XOffset-1; Dec(XPos,XS);
                       if (YOffset <= YS) then if (YOffset=0)then YS:=0 else YS:=YOffset-1; Dec(YPos,YS);
                     end;
                2  : begin if (YOffset <= YS) then if (YOffset=0)then YS:=0 else YS:=YOffset-1; Dec(YPos,YS); end;
                4  : begin
                       if ((XCellSize-XOffset) <= XS) then XS:=XCellSize-XOffset-1;
                       Inc(XPos,XS);
                       if (YOffset <= YS) then if (YOffset=0)then YS:=0 else YS:=YOffset-1; Dec(YPos,YS);
                     end;
                8  : begin if ((XCellSize-XOffset) <= XS) then XS:=XCellSize-XOffset-1;  Inc(XPos,XS); end;
                16 : begin
                       if ((XCellSize-XOffset) <= XS) then XS:=XCellSize-XOffset-1; Inc(XPos,XS);
                       if ((YCellSize-YOffset) <= YS) then YS:=YCellSize-YOffset-1; Inc(YPos,YS);
                     end;
                32 : begin if ((YCellSize-YOffset) <= YS) then YS:=YCellSize-YOffset-1;  Inc(YPos,YS); end;
                64 : begin
                       if (XOffset <= XS) then if (XOffset=0)then XS:=0 else XS:=XOffset-1; Dec(XPos,XS);
                       if ((YCellSize-YOffset) <= YS) then YS:=YCellSize-YOffset-1; Inc(YPos,YS);
                     end;
                128: begin if (XOffset <= XS) then if (XOffset=0)then XS:=0 else XS:=XOffset-1; Dec(XPos,XS); end;
               end;{}
             end;
             XOffset:=XPos mod XCellSize; YOffset:=YPos mod YCellSize;
             PomX:=XCellSize-XS; PomY:=YCellSize-YS;
             if (IPos = IMax) then PomX:=0;
             if (JPos = JMax) then PomY:=0;
             if (XOffset > PomX) then begin
               XPos:=XPosOld; YPos:=YPosOld;
             end;
             if (YOffset > PomY) then begin
                XPos:=XPosOld; YPos:=YPosOld;
             end;
             if (XOffset < 5) then begin
               XPos:=XPos+5-XOffset; XOffset:=XPos mod XCellSize;
             end;
             if (YOffset < 5) then begin
               YPos:=YPos+5-YOffset; YOffset:=YPos mod YCellSize;
             end;
             Set_place_shot(IPos,JPos,Shots[J],False);
             IPos:=XPos shr XCellShl; JPos:=YPos shr YCellShl;
             if (IPos > IMax) then begin
               IPos:=IMax; XPos:=IPos shl XCellShl+XCellSize shr 1; XOffset:=XPos mod XCellSize;
             end;
             if (JPos > JMax) then begin
               JPos:=JMax; YPos:=JPos shl YCellShl+YCellSize shr 1; YOffset:=YPos mod YCellSize;
             end;
             Set_place_shot(IPos,JPos,Shots[J],True);
           end;
           GoTo _Next;
         end;
        end else begin { ruzne faze vybuchu }
_Next:
           with (Explosions[AttackPicture]) do begin
           { exploze }
              if (Status <= MaxPhase) then begin
              { ruzne faze vybuchu }
                 if (Phase > 1) then Phase:=0;
                 if (Phase = 0) then begin { vlastni vykresleni }
                    if (Status = 1) then begin
                       S:=S1; O:=O1;
                    end else
                      if (Status = 2) then begin
                         S:=S2; O:=O2;
                      end else
                        if (Status = 3) then begin
                           S:=S3; O:=O3;
                           Prepare_destroy_shot(Shots[J]);
                        end else
                          if (Status = 4) then begin
                             S:=S4; O:=O4;
                          end else
                            if (Status = 5) then begin
                               S:=S5; O:=O5;
                            end else
                              if (Status = 6) then begin
                                 S:=S6; O:=O6;
                              end else
                                if (Status = 7) then begin
                                   S:=S7; O:=O7;
                                end else
                                   if (Status = 8) then begin
                                      S:=S8; O:=O8;
                                   end else
                                     Error(0,'Chyba v unite _Shot, procedura Shot_manager');
                    {if (Status <> 1) then Erase_shot(Shots[J],False);{}
                    if ((MapBckTemp^[IPos,JPos].Visibilit and Races[MyRace].VisMask  > 0) or (not Fog_of_war))
                    then Visibility:=True else Visibility:=False;
                    {}
                    Draw_explosion_shot(Shots[J]);{}
                    if (First < 2) then First:=2;
                    Inc(Status);
                 end;
                 if (GameTimming = 0) then Inc(Phase,2) else Inc(Phase,2);
                 { u "jemneho" casovani je mezi vybuchy jedna casova mezera }
              end else begin
              { strela se kompletene znici }
                if ((MapBckTemp^[IPos,JPos].Visibilit and Races[MyRace].VisMask  > 0) or (not Fog_of_war))
                then Visibility:=True else Visibility:=False;
                if (AttackLevel = 0) then Prepare_destroy_shot(Shots[J]);
                Destroy_shot(Shots[J]);
                Dec(I);
              end;
           end;
        end;

        Inc(I);
      end; { strela na danem indexu existuje }
      Inc(J);
   end; { while }
end;

{ ***** }
procedure _shot_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'13'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _shot_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'13'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************** }
begin
end.