
unit _Units2;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, Grafika2, Grafika3, _Shot, _units,
     Buttons, Buttons2, Mouse, _units3;

procedure Change_unit_wear_out(var _unit:PUnit);
procedure Change_unit_experience_morale(var _unit:PUnit);
function GetKadence(Race,ShootSpeed,UnitType:Byte):Double;
function SetAttack(var _unit:PUnit):Boolean;
function Prepare_attack_group2(I,J:Word; AttackType, Race, Level:Byte):Boolean;
procedure Prepare_attack_group(I,J:Word; AttackType, Race, Level:Byte);
procedure Prepare_attack_unit(var TargetUnit:PUnit; var TargetBuilding:PBuilding;
                              AttackType:Byte; var _unit:PUnit; Level:Byte);
procedure Searching_for_attack(_unit:PUnit);
procedure Intelli_searching_for_attack(_unit:PUnit);
procedure Attack_unit(_unit:PUnit);
function Check_place_surroundings(var IPos,JPos : Word; ISize,JSize:Word;
                                  Building:Boolean; ElementType,Race:Byte):Boolean;
function Check_place_surroundings_free(var IPos,JPos : Word; ISize,JSize:Word;
                                       UnitType:Byte):Byte;
function CheckAttack(TargetTyp:Word; Race:Byte) : Boolean;
function CheckAttackUnit(TargetTyp:Word; _unit:PUnit) : Boolean;
procedure Set_place(I, J :Word; _unit:PUnit; Sets,SetMapInfo:Boolean);
procedure _units2_save;
procedure _units2_load;

implementation
uses _races;

{ ************************************************************************* }
function GetKadence(Race,ShootSpeed,UnitType:Byte):Double;
{ funkce vrati pomernou hodnotu kadence i vzhledem k typu jednotky UnitType
  a jejim PauseDelay
}
var Pom:Double;
begin
  with (Unit_types[UnitType,Races[Race].Ally]) do begin
    if ((ShootType1 <> 0) and (UnitType <> 29)) then begin
      Pom:=Kadence[0];
      if ((((Kadence[ShootSpeed]*(ShootType1 shl 1)+ShootDelay1) div (ShootType1 shl 1)) > 0) and
          (ShootSpeed < 10))
      { vyloucim  max. cislo kadence 10, nebot GetKadence muze vracet
        velka numera (Kadence[10]=0, delitel Pom je tedy maly); coz vede
        v procedure Change_unit_danger_class k chybe }
      then
        GetKadence:=Pom / ((Kadence[ShootSpeed] * (ShootType1 shl 1)+ShootDelay1) div (ShootType1 shl 1))
      else GetKadence:=5;
    end else
      if (UnitType = 29) then GetKadence:=10 else GetKadence:=1;
      { mutant se vyresi takto, aby vysel jako dostatecne nebezpecny cil }
  end;
end;

{ ***** }
procedure Change_unit_danger_class(_unit:PUnit);
{ vypocita nebezpecnost jednotky - vzhledem ke zmene modifikatoru
  zmenou zkusenosti, moralky, opotrebeni; pokud skutecne dojde ke zmene,
  preskupi jednotku v globalni tabulce MapInfo
  pozn. neutralni jednotky se v tabulce MapInfo neukladaji !!!
}
var LastClass, LastAClass, PomClass, PomClass2 : Byte;
    Danger, ADanger, IP, JP : Word;
begin
  if (not Races[_unit^.Race].Neutral) then with (_unit^) do begin
     LastClass:=DangerClass; LastAClass:=ADangerClass;
     with (Unit_types[UnitType,Races[Race].Ally]) do begin
       if ((UnitType = 33) or (UnitType = 2)) then Danger:=0
       { recyklator, slozena budova }
       else begin
         { zmensena vaha dostrelu - kompenzuje GuidedMissile }
         Danger:=Round(((LightAttack1+LAttackBonus1)+(HeavyAttack1+HAttackBonus1))*
                         GetKadence(Race,ShootSpeed1,UnitType)+
                         DefenceStrength shr 1 + Hi(ShootRange1)*20);
         if (GuidedMissile) then Inc(Danger,Hi(ShootRange1)*10);
         { lepsi proti pohyblivym cilum zejmena na vetsi vzdalenost -
           - pridej tedy bonus }
       end;

       if ((UnitType = 33) or (UnitType = 2)) then ADanger:=0
       { recyklator, slozena budova }
       else
       { zde se pocita s hodnotou pouze vzdusneho utoku, proto snizuji
         vahu obranyschopnosti a dostrelu v konecnem vysledku }
         ADanger:=Round((AirAttack1+AAttackBonus1)*GetKadence(Race,ShootSpeed1,UnitType)+
                         DefenceStrength div 3 + Hi(ShootRange1)*5);
       { GuidedMissile se proti letadlum vyplaci vice nez proti pozemnim
         cilum - zvys vahu }
       if (GuidedMissile) then Inc(Danger,Hi(ShootRange1)*10);

       { nyni pozemni nebezpecnost }
       if (Danger = 0) then DangerClass:=255 else
        if (Danger <= DangerLimit0) then DangerClass:=0 else
         if (Danger <= DangerLimit1) then DangerClass:=1 else
          if (Danger <= DangerLimit2) then DangerClass:=2 else
           if (Danger <= DangerLimit3) then DangerClass:=3 else
            if (Danger <= DangerLimit4) then DangerClass:=4 else
             if (Danger <= DangerLimit5) then DangerClass:=5 else
              if (Danger <= DangerLimit6) then DangerClass:=6 else
               if (Danger <= DangerLimit7) then DangerClass:=7;

       { a PVO nebezpecnost }
       if (AirAttack1 = 0) then ADangerClass:=255 else
        if (ADanger <= ADangerLimit0) then ADangerClass:=0 else
         if (ADanger <= ADangerLimit1) then ADangerClass:=1 else
          if (ADanger <= ADangerLimit2) then ADangerClass:=2;

       { porovnej starou a novou tridu }
       if (LastClass = 255) then PomClass:=255 else
        if (LastClass <= 2) then PomClass:=0 else
         if (LastClass <= 5) then PomClass:=1 else
          if (LastClass <= 7) then PomClass:=2 else
           Error(0,'unita _units2, procedura Change_unit_danger_class, bod 1');
       if (DangerClass = 255) then PomClass2:=255 else
        if (DangerClass <= 2) then PomClass2:=0 else
         if (DangerClass <= 5) then PomClass2:=1 else
          if (DangerClass <= 7) then PomClass2:=2 else
            Error(0,'unita _units2, procedura Change_unit_danger_class, bod 1');

       { nyni se jednotka vyhodi ze stare tridy a zaradi se do nove }
       IP:=IInfoPos; JP:=JInfoPos;
       if ((PomClass <> PomClass2) and ((PomClass = 255) or
            (PomClass2 = 255))) then with (MapInfo^[IP,JP]) do begin
       { * specialni jednotky }
          if (PomClass <> 255) then
          { zkus je zrusit ze spatne kategorie }
            if (Races[Race].Friend[MyRace] = 0) then { jde o pro mne nepratelskou jednotku }
              if (Visibility) then Dec(VHeavy[PomClass])
              else Dec(HHeavy[PomClass])
            else { jde o mne nebo o spojence }
              if (EnemyVisibility) then Dec(EnemyVHeavy[PomClass])
              else Dec(EnemyHHeavy[PomClass]);
          { zarad je do specialni kategorie }
          if (Races[Race].Friend[MyRace] = 0) then { jde o pro mne nepratelskou jednotku }
             Inc(Special)
          else { jde o mne nebo o spojence }
             if (EnemyVisibility) then Inc(EnemyVSpecial)
             else Inc(EnemyHSpecial);
       end else
       { * skutecne bojove jednotky }
        if (PomClass <> PomClass2) then begin
           if (TaskGroup <> InvalidTaskGroupNumber) then
           with (Races[Race].TaskGroups^[TaskGroup]) do begin
             AntiLightTG:=AntiLightTG-Get_unit_anti_weight(Race,UnitType,L,PomClass,LastAClass);
             AntiLightTG:=AntiLightTG+Get_unit_anti_weight(Race,UnitType,L,PomClass2,LastAClass);
             AntiHeavyTG:=AntiHeavyTG-Get_unit_anti_weight(Race,UnitType,T,PomClass,LastAClass);
             AntiHeavyTG:=AntiHeavyTG+Get_unit_anti_weight(Race,UnitType,T,PomClass2,LastAClass);
             AntiAirTG:=AntiAirTG-Get_unit_anti_weight(Race,UnitType,AA,PomClass,LastAClass);
             AntiAirTG:=AntiAirTG+Get_unit_anti_weight(Race,UnitType,AA,PomClass2,ADangerClass);
          end;
          case (TargetTyp) of
            0 : with (MapInfo^[IP,JP]) do begin
                  if (Races[Race].Friend[MyRace] = 0) then begin
                  { jde o pro mne nepratelskou jednotku }
                     if (Visibility) then begin
                       Dec(VLLight[PomClass]); Inc(VLLight[PomClass2]);
                     end else begin
                       Dec(HLLight[PomClass]); Inc(HLLight[PomClass2]);
                     end;
                  end else begin
                  { jde o mne nebo o spojence }
                     if (EnemyVisibility) then begin
                        Dec(EnemyVLLight[PomClass]); Inc(EnemyVLLight[PomClass2]);
                     end else begin
                        Dec(EnemyHLLight[PomClass]); Inc(EnemyHLLight[PomClass2]);
                     end;
                  end;
                  { - prekvalifikovani jednotky uvnitr taskgrupy - }
                  if (TaskGroup <> InvalidTaskGroupNumber) then
                  with (Races[Race].TaskGroups^[TaskGroup]) do begin
                    Dec(LLightTG[PomClass]); Inc(LLightTG[PomClass2]);
                  end;
                end;
            1 : with (MapInfo^[IP,JP]) do begin
                  if (Races[Race].Friend[MyRace] = 0) then begin
                  { jde o pro mne nepratelskou jednotku }
                     if (Visibility) then begin
                        Dec(VLight[PomClass]); Inc(VLight[PomClass2]);
                     end else begin
                        Dec(HLight[PomClass]); Inc(HLight[PomClass2]);
                     end;
                  end else begin
                  { jde o mne nebo o spojence }
                     if (EnemyVisibility) then begin
                        Dec(EnemyVLight[PomClass]); Inc(EnemyVLight[PomClass2]);
                     end else begin
                        Dec(EnemyHLight[PomClass]); Inc(EnemyHLight[PomClass2]);
                     end;
                  end;
                  { - prekvalifikovani jednotky uvnitr taskgrupy - }
                  if (TaskGroup <> InvalidTaskGroupNumber) then
                  with (Races[Race].TaskGroups^[TaskGroup]) do begin
                     Dec(LightTG[PomClass]); Inc(LightTG[PomClass2]);
                  end;
                end;
            2 : with (MapInfo^[IP,JP]) do begin
                  if (Races[Race].Friend[MyRace] = 0) then begin
                  { jde o pro mne nepratelskou jednotku }
                     if (Visibility) then begin
                        Dec(VHeavy[PomClass]); Inc(VHeavy[PomClass2]);
                     end else begin
                        Dec(HHeavy[PomClass]); Inc(HHeavy[PomClass2]);
                     end;
                  end else begin
                  { jde o mne nebo o spojence }
                     if (EnemyVisibility) then begin
                        Dec(EnemyVHeavy[PomClass]); Inc(EnemyVHeavy[PomClass2]);
                     end else begin
                        Dec(EnemyHHeavy[PomClass]); Inc(EnemyHHeavy[PomClass2]);
                     end;
                  end;
                  { - prekvalifikovani jednotky uvnitr taskgrupy - }
                  if (TaskGroup <> InvalidTaskGroupNumber) then
                  with (Races[Race].TaskGroups^[TaskGroup]) do begin
                     Dec(HeavyTG[PomClass]); Inc(HeavyTG[PomClass2]);
                  end;
                end;
            3 : with (MapInfo^[IP,JP]) do begin
                  if (Races[Race].Friend[MyRace] = 0) then begin
                  { jde o pro mne nepratelskou jednotku }
                     if (Visibility) then begin
                        Dec(VAir[PomClass]); Inc(VAir[PomClass2]);
                     end else begin
                        Dec(HAir[PomClass]); Inc(HAir[PomClass2]);
                     end;
                  end else begin
                  { jde o mne nebo o spojence }
                     if (EnemyVisibility) then begin
                        Dec(EnemyVAir[PomClass]); Inc(EnemyVAir[PomClass2]);
                     end else begin
                        Dec(EnemyHAir[PomClass]); Inc(EnemyHAir[PomClass2]);
                     end;
                  end;
                  { - prekvalifikovani jednotky uvnitr taskgrupy - }
                  if (TaskGroup <> InvalidTaskGroupNumber) then
                  with (Races[Race].TaskGroups^[TaskGroup]) do begin
                     Dec(AirTG[PomClass]); Inc(AirTG[PomClass2]);
                  end;
                end;
            4 : ;
          else
          end;
        end;

       { porovnej starou a novou tridu - PVO schopnosti }
       { nyni se jednotka vyhodi ze stare tridy a zaradi se do nove }
       if (LastAClass <> ADangerClass) then with (MapInfo^[IP,JP]) do begin
          if (Races[Race].Friend[MyRace] = 0) then begin
          { jde o pro mne nepratelskou jednotku }
             if (Visibility) then begin
                if (LastAClass <> 255) then Dec(VAAttack[LastAClass]);
                Inc(VAAttack[ADangerClass]);
             end else begin
                if (LastAClass <> 255) then Dec(HAAttack[LastAClass]);
                Inc(HAAttack[ADangerClass]);
             end;
          end else begin
          { jde o mne nebo o spojence }
             if (EnemyVisibility) then begin
                if (LastAClass <> 255) then Dec(EnemyVAAttack[LastAClass]);
                Inc(EnemyVAAttack[ADangerClass]);
             end else begin
                if (LastAClass <> 255) then Dec(EnemyHAAttack[LastAClass]);
                Inc(EnemyHAAttack[ADangerClass]);
             end;
          end;
       end;
       { - prekvalifikovani jednotky uvnitr taskgrupy - }
       if (TaskGroup <> InvalidTaskGroupNumber) then
       with (Races[Race].TaskGroups^[TaskGroup]) do begin
         if (LastAClass < 255) then begin
           Dec(AAttackTG[LastAClass]); Inc(AAttackTG[ADangerClass]);
         end;
       end;

     end; { with Unit_types[UnitType] do begin }
  end;
end;

{ ***** }
procedure Change_unit_wear_out(var _unit:PUnit);
{ zmenilo-li se opotrebeni, propocitaji se nove parametry jednotky
}
label Konec;
var WearOutModif,WearOutDefenceModif,WearOutAttackModif : Double;
    Pom:Double;
begin
  with (_unit^) do if (Activity) then begin
    if ((UnitType = 2) or (Races[Race].RaceType <> 3) and
        (Races[Race].RaceType <> 6)) then begin
    { recyklator nebo nejde o roboty }
      WearOut:=MinWearOut;
      GoTo Konec;
    end;
       if (WearOut > MinimalWearOut) then WearOut:=MinimalWearOut;
       { vypocteme vliv opotrebeni na bojove parametry }
       if ((MinimalWearOut > 150) and
           (WearOutLimitDecreaseFlag >= WearOutLimitDecreaseStepUp150) or
           (MinimalWearOut <= 150) and
           (WearOutLimitDecreaseFlag >= WearOutLimitDecreaseStepBelow150))
       then begin
          WearOutLimitDecreaseFlag:=0;
          if (MinimalWearOut > MinWearOutLimitDecrease)
          then Dec(MinimalWearOut,WearOutLimitDecrease);
       end;
       WearOutModif:=WearOut;
       WearOutModif:=WearOutModif/WearOutStepModifier;
       WearOutModif:=WearOutModif-100/WearOutStepModifier;
       WearOutDefenceModif:=WearOutModif*WearOutDefenceModifier;
       { vypocitany procentuelni modifikatory }
       { nyni vypocteme skutecne prirustky obrany }
       Pom:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength;
       Pom:=(Pom/100)*WearOutDefenceModif; DamageBonus:=Round(Pom);
       { nyni vypocteme skutecne prirustky utoku }
       if (WearOutModif < 0) then
         WearOutAttackModif:=WearOutModif*WearOutMinusAttackModifier
       else
         WearOutAttackModif:=WearOutModif*WearOutPlusAttackModifier;
       Pom:=Unit_types[UnitType,Races[Race].Ally].LightAttack1; { zbran 1 }
       Pom:=(Pom/100)*WearOutAttackModif; LAttackBonus1:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].HeavyAttack1;
       Pom:=(Pom/100)*WearOutAttackModif; HAttackBonus1:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].AirAttack1;
       Pom:=(Pom/100)*WearOutAttackModif; AAttackBonus1:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].LightAttack2; { zbran 2 }
       Pom:=(Pom/100)*WearOutAttackModif; LAttackBonus2:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].HeavyAttack2;
       Pom:=(Pom/100)*WearOutAttackModif; HAttackBonus2:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].AirAttack2;
       Pom:=(Pom/100)*WearOutAttackModif; AAttackBonus2:=Round(Pom);

       if ((Group = ActiveGroup) and
           ((Races[MyRace].Friend[Race] = 2) or EnemyStatus))
       then UpdateMoralWearOut:=True;
  end;
Konec:
  if ((Races[_unit^.Race].RaceType = 3) or (Races[_unit^.Race].RaceType = 6))
  then Change_unit_danger_class(_unit);
end;

{ ***** }
procedure Change_unit_experience_morale(var _unit:PUnit);
{ zmenily se hodnoty Experience nebo kills nebo moralky - vypocitaji se
  nove hodnoty
}
label Konec;
var UnLevel:Byte;
    MoraleModif,MoraleDefenceModif,MoraleAttackModif : Double;
    ExpModif, ExpDefenceModif, ExpAttackModif:Double;
    Pom:Double;
begin
  with (_unit^) do if (Activity) then begin
    if ((UnitType = 2) or (Races[Race].RaceType = 3) or
        (Races[Race].RaceType = 6)) then begin
    { recyklator nebo roboti }
      Morale:=AverageMorale; Experience:=0; {Kills:=0;{}
      ExperienceLevel:=0; GoTo Konec;
    end;
    if (Morale > MaxMorale) then Morale:=MaxMorale;
    UnLevel:=ExperienceLevel;
    { vypocitame novou hodnost }
    if ((Experience >= Experience12) and (Kills >= Kills12)) then begin
      Experience:=Experience12; {Kills:=Kills12;{}
      UnLevel:=12;
    end else
     if ((Experience >= Experience11) and (Kills >= Kills11)) then begin
       UnLevel:=11;
     end else
      if ((Experience >= Experience10) and (Kills >= Kills10)) then begin
        UnLevel:=10;
      end else
       if ((Experience >= Experience9) and (Kills >= Kills9)) then begin
         UnLevel:=9;
       end else
        if ((Experience >= Experience8) and (Kills >= Kills8)) then begin
          UnLevel:=8;
        end else
         if ((Experience >= Experience7) and (Kills >= Kills7)) then begin
           UnLevel:=7;
         end else
          if ((Experience >= Experience6) and (Kills >= Kills6)) then begin
            UnLevel:=6;
          end else
           if ((Experience >= Experience5) and (Kills >= Kills5)) then begin
             UnLevel:=5;
           end else
            if ((Experience >= Experience4) and (Kills >= Kills4)) then begin
              UnLevel:=4;
            end else
             if ((Experience >= Experience3) and (Kills >= Kills3)) then begin
               UnLevel:=3;
             end else
              if ((Experience >= Experience2) and (Kills >= Kills2)) then begin
                UnLevel:=2;
              end else
               if ((Experience >= Experience1) and (Kills >= Kills1)) then begin
                 UnLevel:=1;
               end else UnLevel:=0;
    if (UnLevel >= ExperienceLevel) then begin
    { povyseni nebo zmena moralky }
       { vypocteme vliv moralky na bojove parametry }
       if (UnLevel > ExperienceLevel) then
          Inc(Morale,NewExperienceLevelMorale);
       MoraleModif:=Morale;
       MoraleModif:=(MoraleModif-AverageMorale)/MoraleStepModifier;
       MoraleDefenceModif:=MoraleModif*MoraleDefenceModifier;
       if (MoraleModif > 0) then
          MoraleAttackModif:=MoraleModif*PlusMoraleAttackModifier
       else MoraleAttackModif:=MoraleModif*MinusMoraleAttackModifier;
       { vypocteme vliv nove hodnosti na bojove parametry }
       ExpModif:=UnLevel;
       {}
       case (UnLevel) of
         0:begin
             ExpDefenceModif:=Experience0DefenceModifier;
             ExpAttackModif:=Experience0AttackModifier;
           end;
         1:begin
             ExpDefenceModif:=Experience1DefenceModifier;
             ExpAttackModif:=Experience1AttackModifier;
           end;
         2:begin
             ExpDefenceModif:=Experience2DefenceModifier;
             ExpAttackModif:=Experience2AttackModifier;
           end;
         3:begin
             ExpDefenceModif:=Experience3DefenceModifier;
             ExpAttackModif:=Experience3AttackModifier;
           end;
         4:begin
             ExpDefenceModif:=Experience4DefenceModifier;
             ExpAttackModif:=Experience4AttackModifier;
           end;
         5:begin
             ExpDefenceModif:=Experience5DefenceModifier;
             ExpAttackModif:=Experience5AttackModifier;
           end;
         6:begin
             ExpDefenceModif:=Experience6DefenceModifier;
             ExpAttackModif:=Experience6AttackModifier;
           end;
         7:begin
             ExpDefenceModif:=Experience7DefenceModifier;
             ExpAttackModif:=Experience7AttackModifier;
           end;
         8:begin
             ExpDefenceModif:=Experience8DefenceModifier;
             ExpAttackModif:=Experience8AttackModifier;
           end;
         9:begin
             ExpDefenceModif:=Experience9DefenceModifier;
             ExpAttackModif:=Experience9AttackModifier;
           end;
         10:begin
             ExpDefenceModif:=Experience10DefenceModifier;
             ExpAttackModif:=Experience10AttackModifier;
           end;
         11:begin
             ExpDefenceModif:=Experience11DefenceModifier;
             ExpAttackModif:=Experience11AttackModifier;
           end;
         12:begin
             ExpDefenceModif:=Experience12DefenceModifier;
             ExpAttackModif:=Experience12AttackModifier;
           end;
       end;
       {}
       { vypocitany procentuelni modifikatory }
       if (UniqueNumber <> 65535) then begin
          case (UnitType) of
            14 : ExpDefenceModif:=ExpDefenceModif+ExpDefenceModif/4;
            15 : ExpDefenceModif:=ExpDefenceModif+ExpDefenceModif/4;
            16 : ExpDefenceModif:=ExpDefenceModif+ExpDefenceModif/2;
          else
            ExpDefenceModif:=ExpDefenceModif*2;
          end;
       end;

       ExpDefenceModif:=ExpDefenceModif+MoraleDefenceModif;
       ExpAttackModif:=ExpAttackModif+MoraleAttackModif;
       { nyni vypocteme skutecne prirustky obrany }
       Pom:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength;
       Pom:=(Pom/100)*ExpDefenceModif; DamageBonus:=Round(Pom);
       {Pom:=Damage; Pom:=(Pom/100)*ExpDefenceModif; Damage:=Damage+Round(Pom);{}
       { nyni vypocteme skutecne prirustky utoku }
       Pom:=Unit_types[UnitType,Races[Race].Ally].LightAttack1; { zbran 1 }
       Pom:=(Pom/100)*ExpAttackModif; LAttackBonus1:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].HeavyAttack1;
       Pom:=(Pom/100)*ExpAttackModif; HAttackBonus1:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].AirAttack1;
       Pom:=(Pom/100)*ExpAttackModif; AAttackBonus1:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].LightAttack2; { zbran 2 }
       Pom:=(Pom/100)*ExpAttackModif; LAttackBonus2:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].HeavyAttack2;
       Pom:=(Pom/100)*ExpAttackModif; HAttackBonus2:=Round(Pom);
       Pom:=Unit_types[UnitType,Races[Race].Ally].AirAttack2;
       Pom:=(Pom/100)*ExpAttackModif; AAttackBonus2:=Round(Pom);

       if ((Race = MyRace) and (UnLevel > ExperienceLevel))
       then OutBigMsg(255,'JEDNOTKA POVjgENA');
       if ((Group = ActiveGroup) and
           ((Races[MyRace].Friend[Race] = 2) or EnemyStatus))
       then begin
          if (UnLevel > ExperienceLevel) then begin
             ExperienceLevel:=UnLevel;
             UpdateDmg:=True; UpdateMoralWearOut:=True; UpdateLev:=True;
          end else UpdateMoralWearOut:=True;
       end else if (Group = ActiveGroup) then UpdateDmg:=True;
       ExperienceLevel:=UnLevel;
    end else
      if (UnLevel < ExperienceLevel) then begin { degradace }
         { vypocteme vliv moralky na bojove parametry }
         MoraleModif:=Morale;
         MoraleModif:=(MoraleModif-AverageMorale)/MoraleStepModifier;
         MoraleDefenceModif:=MoraleModif*MoraleDefenceModifier;
         if (MoraleModif > 0) then
            MoraleAttackModif:=MoraleModif*PlusMoraleAttackModifier
         else MoraleAttackModif:=MoraleModif*MinusMoraleAttackModifier;
         { vypocteme vliv nove hodnosti na bojove parametry }
         ExpModif:=UnLevel;
         {}
         case (UnLevel) of
           0:begin
               ExpDefenceModif:=Experience0DefenceModifier;
               ExpAttackModif:=Experience0AttackModifier;
             end;
           1:begin
               ExpDefenceModif:=Experience1DefenceModifier;
               ExpAttackModif:=Experience1AttackModifier;
             end;
           2:begin
               ExpDefenceModif:=Experience2DefenceModifier;
               ExpAttackModif:=Experience2AttackModifier;
             end;
           3:begin
               ExpDefenceModif:=Experience3DefenceModifier;
               ExpAttackModif:=Experience3AttackModifier;
             end;
           4:begin
               ExpDefenceModif:=Experience4DefenceModifier;
               ExpAttackModif:=Experience4AttackModifier;
             end;
           5:begin
               ExpDefenceModif:=Experience5DefenceModifier;
               ExpAttackModif:=Experience5AttackModifier;
             end;
           6:begin
               ExpDefenceModif:=Experience6DefenceModifier;
               ExpAttackModif:=Experience6AttackModifier;
             end;
           7:begin
               ExpDefenceModif:=Experience7DefenceModifier;
               ExpAttackModif:=Experience7AttackModifier;
             end;
           8:begin
               ExpDefenceModif:=Experience8DefenceModifier;
               ExpAttackModif:=Experience8AttackModifier;
             end;
           9:begin
               ExpDefenceModif:=Experience9DefenceModifier;
               ExpAttackModif:=Experience9AttackModifier;
             end;
           10:begin
               ExpDefenceModif:=Experience10DefenceModifier;
               ExpAttackModif:=Experience10AttackModifier;
             end;
           11:begin
               ExpDefenceModif:=Experience11DefenceModifier;
               ExpAttackModif:=Experience11AttackModifier;
             end;
           12:begin
               ExpDefenceModif:=Experience12DefenceModifier;
               ExpAttackModif:=Experience12AttackModifier;
             end;
         end;
         {}
         { vypocitany procentuelni modifikatory }
         if (UniqueNumber <> 65535) then begin
            case (UnitType) of
              14 : ExpDefenceModif:=ExpDefenceModif+ExpDefenceModif/4;
              15 : ExpDefenceModif:=ExpDefenceModif+ExpDefenceModif/4;
              16 : ExpDefenceModif:=ExpDefenceModif+ExpDefenceModif/2;
            else
              ExpDefenceModif:=ExpDefenceModif*2;
            end;
         end;
         ExpDefenceModif:=ExpDefenceModif+MoraleDefenceModif;
         ExpAttackModif:=ExpAttackModif+MoraleAttackModif;
         { nyni vypocteme skutecne prirustky obrany }
         Pom:=Unit_types[UnitType,Races[Race].Ally].DefenceStrength;
         Pom:=(Pom/100)*ExpDefenceModif; DamageBonus:=Round(Pom);
         Pom:=Damage; Pom:=(Pom/100)*ExpDefenceModif; Damage:=Damage+Round(Pom);
         { nyni vypocteme skutecne prirustky utoku }
         Pom:=Unit_types[UnitType,Races[Race].Ally].LightAttack1; { zbran 1 }
         Pom:=(Pom/100)*ExpAttackModif; LAttackBonus1:=Round(Pom);
         Pom:=Unit_types[UnitType,Races[Race].Ally].HeavyAttack1;
         Pom:=(Pom/100)*ExpAttackModif; HAttackBonus1:=Round(Pom);
         Pom:=Unit_types[UnitType,Races[Race].Ally].AirAttack1;
         Pom:=(Pom/100)*ExpAttackModif; AAttackBonus1:=Round(Pom);
         Pom:=Unit_types[UnitType,Races[Race].Ally].LightAttack2; { zbran 2 }
         Pom:=(Pom/100)*ExpAttackModif; LAttackBonus2:=Round(Pom);
         Pom:=Unit_types[UnitType,Races[Race].Ally].HeavyAttack2;
         Pom:=(Pom/100)*ExpAttackModif; HAttackBonus2:=Round(Pom);
         Pom:=Unit_types[UnitType,Races[Race].Ally].AirAttack2;
         Pom:=(Pom/100)*ExpAttackModif; AAttackBonus2:=Round(Pom);

         if (Race = MyRace) then OutBigMsg(255,'JEDNOTKA DEGRADOVaNA');
         if ((Group = ActiveGroup) and
             ((Races[MyRace].Friend[Race] = 2) or EnemyStatus))
         then begin
            UpdateDmg:=True; UpdateMoralWearOut:=True; UpdateLev:=True;
         end else if (Group = ActiveGroup) then UpdateDmg:=True;
         ExperienceLevel:=UnLevel;
      end;
    if (Morale < MinMorale) then begin { jednotka se vzda }
      { implementovano v jednotce Units }
    end;
  end;
Konec:
  if ((Races[_unit^.Race].RaceType <> 3) and (Races[_unit^.Race].RaceType <> 6))
  then Change_unit_danger_class(_unit);
end;

{ ***** }
function SetAttack(var _unit:PUnit):Boolean;
{ zjisti, zda je jednotka v utocnem rezimu; pokud ano, neni-li cil
  v dostrelu, zajisti presun jednotky k cili
  Sama fce vraci True, pokud je cil v dostrelu
  Jednotka musi byt bud v modu "utok s moznym presunem" .. MoveStatus = 8,16
  nebo v modu "utok pouze z mista" .. MoveStatus = 32,64
}
label Konec, Attack_end;
var PomTarget : PUnit; { ukazatel na cil-jednotku pri utoku }
    PomBTarget : PBuilding; { ukazatel na cil-budovu pri utoku }
    Range, Range2, I, J, ISize, JSize : Word;
    Result,RangeResult,ADefRangeCheckFail: Boolean;
begin
   if (_unit^.Return_to_base) then
   else
   if ((_unit^.MoveStatus = 16)  or (_unit^.MoveStatus = 32) or
       (_unit^.MoveStatus = 64) or (_unit^.MoveStatus = 8)) then with (_unit^) do begin
   { jednotka utoci, je povolen presun pro MoveStatus = 16 }
      ADefRangeCheckFail:=False;
      if ((MoveStatus <> 8) and ActiveDefence and (Race = MyRace) and
          (GetDistance(IPos,JPos,ITarget,JTarget) > ActiveDefenceRange))
      then ADefRangeCheckFail:=True;
      CheckGroupMoveDistance:=False;
      GroupMoveSteps:=0; Stop_:=False;
      if (Target <> Nil) then PomTarget:=Target^;
      if (BTarget <> Nil) then PomBTarget:=BTarget^;
      if ((Target = Nil) or (PomTarget = Nil)) then begin
      { cilem je budova }
        if ((BTarget = Nil) or (PomBTarget = Nil)) then begin
        { chyba - obe jednotky jsou Nil }
Attack_end:
           MoveStatus:=0; Result:=False;
           ITarget:=IPos; JTarget:=JPos; ADefModeSteps:=0;
           IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
           if ((not Return_to_base) and (MoveStatus <> 8) and ActiveDefence and
               (Race = MyRace))
           then begin
           { je-li jednotka v modu aktivni obrany a nejde o
             nasilny utok, vrat jednotku do puvodni pozice }
              ADefModeSteps:=0;
              if (TargetType = 3) then begin
                 if (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) then begin
                    Status:=0; Return_to_base:=True;
                    ITarget:=IAirport; JTarget:=JAirport;
                 end;
                 WayPointMax:=0; WayPointUk:=0;
                 Set_move_unit(ITarget,JTarget,Units[Index],1,False,False)
              end else begin
                 WayPointMax:=0; WayPointUk:=0;
                 Set_move_unit(ITarget,JTarget,Units[Index],0,False,False);
              end;
           end else Stop_unit(_unit,False,True);
           GoTo Konec;
        end;
        if (not PomBTarget^.Activity) then GoTo Attack_end;
        { budova neni aktivni, nelze na ni utocit }
        Range:=Unit_types[UnitType,Races[Race].Ally].ShootRange1;
        asm { nyni vytahneme max. dostrel }
          mov Ax,Range
          xor Bx,Bx
          mov Bl,Al
          mov Al,Ah
          xor Ah,Ah
          mov Range,Ax
          mov Range2,Bx
          cmp Range2,0
          je @Konec
          dec Range2 { hranice dostrelu slabsi zbrane }
@Konec:
        end;
        ISize:=Building_types[PomBTarget^.BuildingType].IBuildingSize-1;
        JSize:=Building_types[PomBTarget^.BuildingType].JBuildingSize-1;
        { nyni se otestuje dostrel k nejblizsi casti cile }
        RangeResult:=False;
        for I:=PomBTarget^.IPos to PomBTarget^.IPos+ISize do
          for J:=PomBTarget^.JPos to PomBTarget^.JPos+JSize do
             RangeResult:=RangeResult or Range_check(IPos, JPos,I,J,Range);

        if ((not RangeResult) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255))
        then begin Result:=False; GoTo Konec; end;
        if (not RangeResult and (Range <> 0)) then begin
        { budova neni v dostrelu - budeme se presunovat }
          if (ADefRangeCheckFail) then begin
          { prekrocen limit pronasledovani u modu aktivni obrany - vrat se
            do puvodni pozice }
            if (not Return_to_base) then
              if (TargetType = 3) then begin
                 if (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) then begin
                    Status:=0; Return_to_base:=True;
                    ITarget:=IAirport; JTarget:=JAirport; ADefModeSteps:=0;
                 end;
                 WayPointMax:=0; WayPointUk:=0;
                 Set_move_unit(ITarget,JTarget,_unit,1,False,False);
              end else begin
                 WayPointMax:=0; WayPointUk:=0;
                 Set_move_unit(ITarget,JTarget,_unit,0,False,False);
              end;
          end else
            if ((MoveStatus = 16) or (MoveStatus = 8)) then begin
              WayPointUk:=0; WayPointMax:=0;
              WayPoint[WayPointUk].IAim:=PomBTarget^.IPos;
              WayPoint[WayPointUk].JAim:=PomBTarget^.JPos;
              Stop_:=False;
              if ((Status < 1) or (Status > 128)) then begin
                 Status:=Direction;
                 MoveUk:=0;
              end;
              Stop_:=False; {GroupMoveSteps:=0;} CheckGroupMoveDistance:=False;
              if (TargetType = 3) then Move_target_level:=1
              else Move_target_level:=0;
            end;
          Result:=False;
        end else begin
        { cil je v dostrelu - zastav se }
           if ((Range2 <> 0) and Range_check(IPos, JPos,I,J,Range2))
           then begin { je nutno pouzit slabsi zbran 2 }
              if (Unit_types[UnitType,Races[Race].Ally].ShootRange2 = 0) then begin
                 ActiveWeapon:=0; { zbran2 neexistuje }
                 Stop_:=True; Result:=False; GoTo Konec;
              end else begin
                 ActiveWeapon:=2;
              end;
           end else begin
              if (Unit_types[UnitType,Races[Race].Ally].ShootRange1 = 0) then begin
                 ActiveWeapon:=0; { zbran1 neexistuje }
                 Stop_:=True; Result:=False; GoTo Konec;
              end else begin
              { pouzije se zbran 1 }
                 ActiveWeapon:=1;
              end;
           end;
           Stop_:=True; Result:=True;
        end;
      end else begin
         if (BTarget = Nil) then begin
         { cilem je jednotka }
            if (not PomTarget^.Activity) then GoTo Attack_end;
            { jednotka neni aktivni, nelze na ni utocit }
            Range:=Unit_types[UnitType,Races[Race].Ally].ShootRange1;
            asm { nyni vytahneme max. dostrel }
              mov Ax,Range
              xor Bx,Bx
              mov Bl,Al
              mov Al,Ah
              xor Ah,Ah
              mov Range,Ax
              mov Range2,Bx
              cmp Range2,0
              je @Konec
              dec Range2 { hranice dostrelu slabsi zbrane }
@Konec:
            end;
            { nyni se otestuje dostrel k nejblizsi casti cile }
            ISize:=Unit_types[PomTarget^.UnitType,Races[Race].Ally].IUnitSize-1;
            JSize:=Unit_types[PomTarget^.UnitType,Races[Race].Ally].JUnitSize-1;
            { pokud se jednotka hybe, je na vice polich }
            if (PomTarget^.XOffset <> 0) then Inc(ISize);
            if (PomTarget^.YOffset <> 0) then Inc(JSize);
            RangeResult:=False;
            for I:=PomTarget^.IPos to PomTarget^.IPos+ISize do
              for J:=PomTarget^.JPos to PomTarget^.JPos+JSize do
                RangeResult:=RangeResult or Range_check(IPos, JPos,I,J,Range);

            if ((not RangeResult) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255))
            then begin Result:=False; GoTo Konec; end;
            if (not RangeResult and (Range <> 0)) then begin
            { jednotka neni v dostrelu - bude se presunovat }
              if (ADefRangeCheckFail) then begin
              { prekrocen limit pronasledovani u modu aktivni obrany - vrat se
                do puvodni pozice }
                if (not Return_to_base) then
                  if (TargetType = 3) then begin
                    if (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) then begin
                      Status:=0; Return_to_base:=True;
                      ITarget:=IAirport; JTarget:=JAirport; ADefModeSteps:=0;
                    end;
                    WayPointMax:=0; WayPointUk:=0;
                    Set_move_unit(ITarget,JTarget,_unit,1,False,False)
                  end else begin
                    WayPointMax:=0; WayPointUk:=0;
                    Set_move_unit(ITarget,JTarget,_unit,0,False,False);
                  end;
              end else
                if ((MoveStatus = 16) or (MoveStatus = 8)) then begin
                  WayPointUk:=0; WayPointMax:=0;
                  WayPoint[WayPointUk].IAim:=PomTarget^.IPos;
                  WayPoint[WayPointUk].JAim:=PomTarget^.JPos;
                  if ((Status < 1) or (Status > 128)) then begin
                     Status:=Direction;
                     MoveUk:=0;
                  end;
                  CheckGroupMoveDistance:=False; GroupMoveSteps:=0; Stop_:=False;
                  if (TargetType = 3) then Move_target_level:=1
                  else Move_target_level:=0;
                end;
              Result:=False;
            end else begin
              { cil je v dostrelu - zastav se }
              if ((Range2 <> 0) and Range_check(IPos, JPos,I,J,Range2))
              then begin { je nutno pouzit slabsi zbran 2 }
                 if (Unit_types[UnitType,Races[Race].Ally].ShootRange2 = 0) then begin
                    ActiveWeapon:=0; { zbran2 neexistuje }
                    Stop_:=True; Result:=False; GoTo Konec;
                 end else begin
                    ActiveWeapon:=2;
                 end;
              end else begin
                 if (Unit_types[UnitType,Races[Race].Ally].ShootRange1 = 0) then begin
                    ActiveWeapon:=0; { zbran1 neexistuje }
                    Stop_:=True; Result:=False; GoTo Konec;
                 end else begin
                    { pouzije se zbran 1 }
                    ActiveWeapon:=1;
                 end;
              end;
              Stop_:=True; Result:=True;
            end;
         end;
      end;
   end; { if (_unit^.MoveStatus = ...) }
Konec:
   SetAttack:=Result;
end;

{ ***** }
function SetAttack2(var _unit:PUnit; Targ:PUnit; BTarg:PBuilding):Boolean;
{ Sama fce vraci True, pokud je cil v dostrelu
}
label Konec, Attack_end;
var PomTarget : PUnit; { ukazatel na cil-jednotku pri utoku }
    PomBTarget : PBuilding; { ukazatel na cil-budovu pri utoku }
    Range, Range2, I, J, ISize, JSize : Word;
    RangeResult,ADefRangeCheckFail: Boolean;
begin
   with (_unit^) do begin
      if (Targ <> Nil) then PomTarget:=Targ;
      if (BTarg <> Nil) then PomBTarget:=BTarg;
      if ((Targ = Nil) or (PomTarget = Nil)) then begin
      { cilem je budova }
        if ((BTarg = Nil) or (PomBTarget = Nil)) then begin
        { chyba - obe jednotky jsou Nil }
Attack_end:
           SetAttack2:=False; GoTo Konec;
        end;
        if (not PomBTarget^.Activity) then GoTo Attack_end;
        { budova neni aktivni, nelze na ni utocit }
        Range:=Unit_types[UnitType,Races[Race].Ally].ShootRange1;
        asm { nyni vytahneme max. dostrel }
          mov Ax,Range
          xor Bx,Bx
          mov Bl,Al
          mov Al,Ah
          xor Ah,Ah
          mov Range,Ax
          mov Range2,Bx
          cmp Range2,0
          je @Konec
          dec Range2 { hranice dostrelu slabsi zbrane }
@Konec:
        end;
        ISize:=Building_types[PomBTarget^.BuildingType].IBuildingSize-1;
        JSize:=Building_types[PomBTarget^.BuildingType].JBuildingSize-1;
        { nyni se otestuje dostrel k nejblizsi casti cile }
        RangeResult:=False;
        for I:=PomBTarget^.IPos to PomBTarget^.IPos+ISize do
          for J:=PomBTarget^.JPos to PomBTarget^.JPos+JSize do
             RangeResult:=RangeResult or Range_check(IPos, JPos,I,J,Range);

        if ((not RangeResult) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255))
        then begin SetAttack2:=False; GoTo Konec; end;
        if (not RangeResult and (Range <> 0)) then begin
        { budova neni v dostrelu  }
          SetAttack2:=False;
        end else begin
        { cil je v dostrelu - zastav se }
           if ((Range2 <> 0) and Range_check(IPos, JPos,I,J,Range2))
           then begin { je nutno pouzit slabsi zbran 2 }
              if (Unit_types[UnitType,Races[Race].Ally].ShootRange2 = 0) then begin
                 SetAttack2:=False; GoTo Konec;
              end else begin
              end;
           end else begin
              if (Unit_types[UnitType,Races[Race].Ally].ShootRange1 = 0) then begin
                 SetAttack2:=False; GoTo Konec;
              end else begin
              { pouzije se zbran 1 }
              end;
           end;
           SetAttack2:=True;
        end;
      end else begin
         if (BTarget = Nil) then begin
         { cilem je jednotka }
            if (not PomTarget^.Activity) then GoTo Attack_end;
            { jednotka neni aktivni, nelze na ni utocit }
            Range:=Unit_types[UnitType,Races[Race].Ally].ShootRange1;
            asm { nyni vytahneme max. dostrel }
              mov Ax,Range
              xor Bx,Bx
              mov Bl,Al
              mov Al,Ah
              xor Ah,Ah
              mov Range,Ax
              mov Range2,Bx
              cmp Range2,0
              je @Konec
              dec Range2 { hranice dostrelu slabsi zbrane }
@Konec:
            end;
            { nyni se otestuje dostrel k nejblizsi casti cile }
            ISize:=Unit_types[PomTarget^.UnitType,Races[Race].Ally].IUnitSize-1;
            JSize:=Unit_types[PomTarget^.UnitType,Races[Race].Ally].JUnitSize-1;
            { pokud se jednotka hybe, je na vice polich }
            if (PomTarget^.XOffset <> 0) then Inc(ISize);
            if (PomTarget^.YOffset <> 0) then Inc(JSize);
            RangeResult:=False;
            for I:=PomTarget^.IPos to PomTarget^.IPos+ISize do
              for J:=PomTarget^.JPos to PomTarget^.JPos+JSize do
                RangeResult:=RangeResult or Range_check(IPos, JPos,I,J,Range);

            if ((not RangeResult) and (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255))
            then begin SetAttack2:=False; GoTo Konec; end;
            if (not RangeResult and (Range <> 0)) then begin
            { jednotka neni v dostrelu - bude se presunovat }
              SetAttack2:=False;
            end else begin
              { cil je v dostrelu - zastav se }
              if ((Range2 <> 0) and Range_check(IPos, JPos,I,J,Range2))
              then begin { je nutno pouzit slabsi zbran 2 }
                 if (Unit_types[UnitType,Races[Race].Ally].ShootRange2 = 0) then begin
                    SetAttack2:=False; GoTo Konec;
                 end else begin
                 end;
              end else begin
                 if (Unit_types[UnitType,Races[Race].Ally].ShootRange1 = 0) then begin
                    SetAttack2:=False; GoTo Konec;
                 end else begin
                    { pouzije se zbran 1 }
                 end;
              end;
              SetAttack2:=True;
            end;
         end;
      end;
   end; { if (_unit^.MoveStatus = ...) }
Konec:
end;

{ ***** }
function Prepare_attack_group2(I,J:Word; AttackType, Race, Level:Byte):Boolean;
{ procedura zkusi utok rasy Race na pozici I,J a uroven Level.
  Level .. 0 - utok na pozemni uroven
           1 - utok na vzdusnou uroven
  AttackType .. 16 - utok s moznym presunem
                32 - utok pouze z mista
  vraci True, je-li utok mozny
}
label Not_succes1, Not_succes2, Not_succes3, Not_succes4, Not_succes5,
      Not_succes6;

var Pom, SetAttackResult : Boolean;
    Targ, K, L:Word;
    PU:PPUnit; PB:PPBuilding;
begin
 Prepare_attack_group2:=False; bebex:=30000;
 if (Race = MyRace) then begin
   with (Map^[I,J]) do with (Groups[ActiveGroup]) do begin
     if (Level = 0) then begin { utok na pozemni urovni }
          Pom:=False;
          if (Level_type and 128 = 0) then begin
          { cilem je jednotka }
             Targ:=First_level; if ((Targ = 0) or (Units[Targ] = Nil)) then GoTo Not_succes1;
             if (CheckAttack(Units[First_level]^.TargetType,Race) and
                 (Races[Race].Friend[Units[First_level]^.Race] = 0))
             then begin
                Prepare_attack_group2:=True; SetAttackResult:=False;
                for K:=0 to MaxGroupUnits-1 do begin
                { nastaveni atributu utoku clenum skupiny }
                  if (Un[K] <> Nil) then with (Un[K]^) do begin
                    First_attack:=True;
                    SetAttackResult:=SetAttackResult or
                                     SetAttack2(Un[K],Units[Targ],Nil) or
                                     (Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 255);
                  end; { if Un[K] <> Nil }
                end; { for }
                if (not SetAttackResult) then begin
                   Prepare_attack_group2:=False;
                end;
             end else begin
Not_succes1:    Prepare_attack_group2:=False;
             end;
          end else begin { cilem je budova }
            if ((First_level <> 0) or (Buildings[First_level] <> Nil) and
                (Races[Race].Friend[Buildings[First_level]^.Race] = 0))
            then begin { budova je nepratelska }
               Targ:=First_level;
               if (CheckAttack(2,Race)) then begin
                  Prepare_attack_group2:=True; SetAttackResult:=False;
                  for K:=0 to MaxGroupUnits-1 do begin
                  { nastaveni atributu utoku clenum skupiny }
                    if (Un[K] <> Nil) then with (Un[K]^) do begin
                      First_attack:=True;
                      SetAttackResult:=SetAttackResult or
                                       SetAttack2(Un[K],Nil,Buildings[Targ]) or
                                       (Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 255);
                    end; { if Un[K] <> Nil }
                  end; { for }
                  if (not SetAttackResult) then begin
                     Prepare_attack_group2:=False;
                  end;
               end else begin { utok se nezdaril }
Not_succes2:       Prepare_attack_group2:=False;
               end;
            end; { budova je nepratelska }
          end; { cilem je budova }

     end else begin { utok na vzdusne urovni}
        if ((Second_level = 0) or (Units[Second_level] = Nil)) then GoTo Not_succes3;
        Targ:=Units[Second_level]^.TargetType;
        if (CheckAttack(Targ,Race) and
            (Races[Race].Friend[Units[Second_level]^.Race] = 0))
        then begin { mozno utocit }
          Targ:=Second_level;
          if (CheckAttack(Units[Second_level]^.TargetType,Race) and
              (Races[Race].Friend[Units[Second_level]^.Race] = 0))
          then begin
             Prepare_attack_group2:=True; SetAttackResult:=False;
             for K:=0 to MaxGroupUnits-1 do begin
             { nastaveni atributu utoku clenum skupiny }
               if (Un[K] <> Nil) then with (Un[K]^) do begin
                 First_attack:=True;
                 SetAttackResult:=SetAttackResult or
                                  SetAttack2(Un[K],Units[Targ],Nil) or
                                  (Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 255);
               end; { if Un[K] <> Nil }
             end; { for }
             if (not SetAttackResult) then begin
                Prepare_attack_group2:=False;
             end;
          end;
        end else begin { nemozno utocit }
Not_succes3:
           Prepare_attack_group2:=False;
        end;
     end; { utok na vzdusne urovni }
   end; { with }
 end;
end;

{ ***** }
procedure Prepare_attack_group(I,J:Word; AttackType, Race, Level:Byte);
{ procedura zkusi nastavit utok rasy Race na pozici I,J a uroven Level.
  Level .. 0 - utok na pozemni uroven
           1 - utok na vzdusnou uroven
  AttackType .. 16 - utok s moznym presunem
                32 - utok pouze z mista
}
label Not_succes1, Not_succes2, Not_succes3, Not_succes4, Not_succes5,
      Not_succes6;

var Pom, SetAttackResult : Boolean;
    Targ, K, L:Word;
    PU:PPUnit; PB:PPBuilding;
begin
 if (Race = MyRace) then begin
   with (Map^[I,J]) do with (Groups[ActiveGroup]) do begin
     if (Level = 0) then begin { utok na pozemni urovni }
          Pom:=False;
          if (Level_type and 128 = 0) then begin
          { cilem je jednotka }
             Targ:=Units[First_level]^.TargetType;
             if (CheckAttack(Targ,Race) and
                 (Races[Race].Friend[Units[First_level]^.Race] = 0))
             then begin
                for K:=0 to MaxGroupUnits-1 do begin
                { nastaveni atributu utoku clenum skupiny }
                  if (Un[K] <> Nil) then with (Un[K]^) do begin
                    if ((GroupMoveBlock <> 0) and
                        (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                        (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0))
                    then GroupMoveBlock:=0;
                    First_attack:=True; Attacking:=True;
                    ITarget:=IPos; JTarget:=JPos; TurnFlag:=0; ADefModeSteps:=0;
                    BTarget:=Nil;
                    Target:=@Units[First_level];
                    MoveStatus:=AttackType;
                    { nyni se osetri vyjimka - naclicknuta je jen 1 jednotka, jedna
                      se o jednotku nepohyblivou (napr. pevnost) a cil neni
                      v dostrelu = NELZE utocit }
                    SetAttackResult:=SetAttack(Un[K]);
                    if ((Count = 1) and
                        (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) and
                        not SetAttackResult) then begin
                      Target:=Nil; MoveStatus:=0;
                      GoTo Not_succes1;
                    end;
                    if (not SetAttackResult and (Stop_)) then begin
                      Target:=Nil; MoveStatus:=0;
                      GoTo Not_succes1;
                    end;
                    if ((not SetAttackResult) and (MoveStatus = 32))
                    then MoveStatus:=64;
                    if ((MoveStatus < 8) or (MoveStatus > 32)) then
                      if (ActiveWeapon = 1) then begin
                        ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                        if (GameTimming = 1) then begin
                           ShootFlag:=ShootFlag shl 1;
                           Inc(ShootFlag, ShootDelayFlag1);
                        end else
                           Inc(ShootFlag, ShootDelayFlag1 shr 1);
                      end else if (ActiveWeapon > 1) then begin
                        ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                        { pozn. zda zbran2 skutecne existuje se zjistuje az
                          pri strelbe }
                        if (GameTimming = 1) then begin
                           ShootFlag:=ShootFlag shl 1;
                           Inc(ShootFlag, ShootDelayFlag2);
                        end else
                           Inc(ShootFlag, ShootDelayFlag2 shr 1);
                      end;
                    BanDir:=0; First_mov:=True;
                    if ((Status > 0) and (Status <= 129)) then Stop_:=True
                    else begin
                      if (not Stop_) then begin
                         Stop_unit(Un[K],False,True);
                         if (AttackType = 16) then Status:=Direction;
                      end;
                    end;
                  end; { if Un[K] <> Nil }
                end; { for }
                PB:=Nil; PU:=@Units[First_level];
                Set_attack_cursor_mark(PU,PB);
                {SetCursor(AttackCursor);{}
             end else begin
Not_succes1:    NormCursor := GetAccurateDelay(4);{ utok se nepodaril }
                SetCursor(NoAttackCursor);
             end;
          end else begin { cilem je budova }
            if (Races[Race].Friend[Buildings[First_level]^.Race] = 0)
            then begin { budova je nepratelska }
               Targ:=2; { budova je tezky cil }
               if (CheckAttack(Targ,Race)) then begin
                 for K:=0 to MaxGroupUnits-1 do
                 { nastaveni atributu utoku clenum skupiny }
                   if (Un[K] <> Nil) then with (Un[K]^) do begin
                      First_attack:=True;  Attacking:=True;
                      ITarget:=IPos; JTarget:=JPos; TurnFlag:=0; ADefModeSteps:=0;
                      BTarget:=@Buildings[First_level];
                      Target:=Nil; MoveStatus:=AttackType;
                      if ((Count = 1) and
                          (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) and
                          not SetAttack(Un[K])) then begin
                         BTarget:=Nil; MoveStatus:=0;
                         GoTo Not_succes2;
                      end;
                      SetAttack(Un[K]);
                      if ((MoveStatus < 8) or (MoveStatus > 32)) then
                         if (ActiveWeapon = 1) then begin
                            ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                            if (GameTimming = 1) then begin
                              ShootFlag:=ShootFlag shl 1;
                              Inc(ShootFlag, ShootDelayFlag1);
                            end else
                              Inc(ShootFlag, ShootDelayFlag1 shr 1);
                         end else if (ActiveWeapon > 1) then begin
                           ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                           if (GameTimming = 1) then begin
                              ShootFlag:=ShootFlag shl 1;
                              Inc(ShootFlag, ShootDelayFlag2);
                           end else
                              Inc(ShootFlag, ShootDelayFlag2 shr 1);
                         end;
                      { pozn. zda zbran2 skutecne existuje se zjistuje az
                        pri strelbe }
                      BanDir:=0; First_mov:=True;
                      if ((Status > 0) and (Status <= 129)) then Stop_:=True
                      else begin
                        if (not Stop_) then begin
                          Stop_unit(Un[K],False,True);
                          if (AttackType = 16) then Status:=Direction;
                        end;
                      end;
                   end; { if Un[K] <> Nil }
                   NormCursor := 2;
                   PB:=@Buildings[First_level]; PU:=Nil;
                   Set_attack_cursor_mark(PU,PB);
                 end else begin { utok se nezdaril }
Not_succes2:        NormCursor := GetAccurateDelay(4);
                    SetCursor(NoAttackCursor);
                 end;
            end; { budova je nepratelska }
          end; { cilem je budova }

     end else begin { utok na vzdusne urovni}
        Targ:=Units[Second_level]^.TargetType;
        if (CheckAttack(Targ,Race) and
            (Races[Race].Friend[Units[Second_level]^.Race] = 0))
        then begin { mozno utocit }
           for K:=0 to MaxGroupUnits-1 do
             if (Un[K] <> Nil) then with (Un[K]^) do begin
             { nastaveni atributu utoku clenum skupiny }
                First_attack:=True;  Attacking:=True;
                ITarget:=IPos; JTarget:=JPos; TurnFlag:=0; ADefModeSteps:=0;
                Target:=@Units[Second_level]; BTarget:=Nil;
                MoveStatus:=AttackType; BanDir:=0; First_mov:=True;
                SetAttackResult:=SetAttack(Un[K]);
                if ((Count = 1) and
                    (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) and
                     not SetAttackResult) then begin
                  Target:=Nil; MoveStatus:=0;
                  GoTo Not_succes3;
                end;
                if ((not SetAttackResult) and (MoveStatus = 32))
                    then MoveStatus:=64;
                if ((MoveStatus < 8) or (MoveStatus > 32)) then
                  if (ActiveWeapon = 1) then begin
                     ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                     if (GameTimming = 1) then begin
                        ShootFlag:=ShootFlag shl 1;
                        Inc(ShootFlag, ShootDelayFlag1);
                     end else
                       Inc(ShootFlag, ShootDelayFlag1 shr 1);
                  end else if (ActiveWeapon > 1) then begin
                     ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                     if (GameTimming = 1) then begin
                       ShootFlag:=ShootFlag shl 1;
                       Inc(ShootFlag, ShootDelayFlag2);
                     end else
                       Inc(ShootFlag, ShootDelayFlag2 shr 1);
                  end;
                {pozn. zda zbran2 skutecne existuje se zjistuje az pri strelbe }
                if ((Status > 0) and (Status <= 129)) then Stop_:=True
                else begin
                  if (not Stop_) then begin
                     Stop_unit(Un[K],False,True);
                     if (AttackType = 16) then Status:=Direction;
                  end;
                end;
             end; { if (Un[K] <> Nil }
             NormCursor := 2;
             PU:=@Units[Second_level]; PB:=Nil;
             Set_attack_cursor_mark(PU,PB);
        end else begin { nemozno utocit }
Not_succes3:
           NormCursor := GetAccurateDelay(4);
           SetCursor(NoAttackCursor);
        end;
     end; { utok na vzdusne urovni }
   end; { with }
 end;
end;

{ ***** }
procedure Prepare_attack_unit(var TargetUnit:PUnit; var TargetBuilding:PBuilding;
                              AttackType:Byte; var _unit:PUnit; Level:Byte);
{ procedura zkusi nastavit utok jednotky _unit na pozici I,J a uroven Level.
  Level .. 0 - utok na pozemni uroven
           1 - utok na vzdusnou uroven
  AttackType .. 16 - utok s moznym presunem
                32 - utok pouze z mista
}
label Not_succes1, Not_succes2, Not_succes3;

var Pom, SetAttackResult: Boolean;
    K, L:Word;
    Targ:Word;
begin
   if (_unit^.Activity) then with (_unit^) do begin
     if ((GroupMoveBlock <> 0) and
         (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
         (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel <> 0))
     then GroupMoveBlock:=0;
     TurnFlag:=0; First_attack:=True;
     if ((TargetUnit <> Nil) and (Target <> Nil) and (Target^ = TargetUnit))
     then else begin { stejna jednotka se nepocita }
       ITarget:=IPos; JTarget:=JPos; ADefModeSteps:=0;
     end;

     if (Level = 0) then begin { utok na pozemni urovni }
          Pom:=False;
          if (TargetBuilding = Nil) then begin
          { cilem je jednotka }
             if (TargetUnit = Nil) then
                Error(0,'unita _units2, procedura Prepare_attack_unit, bod 2');
             Targ:=TargetUnit^.TargetType;
             if (CheckAttackUnit(Targ,_unit) and
                 (Races[Race].Friend[TargetUnit^.Race] = 0))
             then begin
                 BTarget:=Nil;
                 Target:=@TargetUnit;
                 MoveStatus:=AttackType;
                 { nyni se osetri vyjimka - naclicknuta je jen 1 jednotka, jedna
                   se o jednotku nepohyblivou (napr. pevnost) a cil neni
                   v dostrelu = NELZE utocit }
                 SetAttackResult:=SetAttack(_unit);
                 if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) and
                     not SetAttackResult) then begin
                     Target:=Nil; MoveStatus:=0;
                     GoTo Not_succes1;
                 end;
                 if (not SetAttackResult and Stop_) then begin
                   Target:=Nil; MoveStatus:=0;
                   GoTo Not_succes1;
                 end;
                 Attacking:=True;
                 if ((not SetAttackResult) and (MoveStatus = 32))
                 then MoveStatus:=64;
                 if ((MoveStatus < 8) or (MoveStatus > 32)) then
                   if (ActiveWeapon = 1) then begin
                     ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                     if (GameTimming = 1) then begin
                        ShootFlag:=ShootFlag shl 1;
                        Inc(ShootFlag, ShootDelayFlag1);
                     end else
                        Inc(ShootFlag, ShootDelayFlag1 shr 1);
                   end else if (ActiveWeapon > 1) then begin
                     ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                     if (GameTimming = 1) then begin
                        ShootFlag:=ShootFlag shl 1;
                        Inc(ShootFlag, ShootDelayFlag2);
                     end else
                        Inc(ShootFlag, ShootDelayFlag2 shr 1);
                   { pozn. zda zbran2 skutecne existuje se zjistuje az
                     pri strelbe }
                   end;
                 BanDir:=0; First_mov:=True;
                 if ((Status > 0) and (Status <= 129)) then Stop_:=True
                 else begin
                   if (not Stop_) then begin
                      Stop_unit(_unit,False,True);
                      if (AttackType = 16) then Status:=Direction;
                   end;
                 end;
             end else begin
Not_succes1:    { utok se nepodaril }
                IntelliSearching_for_attack_flag:=0;
             end;
          end else begin { cilem je budova }
            if (Races[Race].Friend[TargetBuilding^.Race] = 0)
            then begin { budova je nepratelska }
               Targ:=2; { budova je tezky cil }
               if (CheckAttackUnit(Targ,_unit)) then begin
                 BTarget:=@TargetBuilding;
                 Target:=Nil; MoveStatus:=AttackType;
                 if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) and
                     not SetAttack(_unit)) then begin
                   BTarget:=Nil; MoveStatus:=0;
                   GoTo Not_succes2;
                 end;
                 if (not SetAttack(_unit) and (Stop_)) then begin
                   Target:=Nil; MoveStatus:=0;
                   GoTo Not_succes2;
                 end;
                 if ((MoveStatus < 8) or (MoveStatus > 32)) then
                   if (ActiveWeapon = 1) then begin
                      ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                      if (GameTimming = 1) then begin
                        ShootFlag:=ShootFlag shl 1;
                        Inc(ShootFlag, ShootDelayFlag1);
                      end else
                        Inc(ShootFlag, ShootDelayFlag1 shr 1);
                   end else if (ActiveWeapon > 1) then begin
                      ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                      if (GameTimming = 1) then begin
                        ShootFlag:=ShootFlag shl 1;
                        Inc(ShootFlag, ShootDelayFlag2);
                      end else
                        Inc(ShootFlag, ShootDelayFlag2 shr 1);
                   { pozn. zda zbran2 skutecne existuje se zjistuje az
                     pri strelbe }
                   end;
                 Attacking:=True;
                 BanDir:=0; First_mov:=True;
                 if ((Status > 0) and (Status <= 129)) then Stop_:=True
                 else begin
                   if (not Stop_) then begin
                     Stop_unit(_unit,False,True);
                     if (AttackType = 16) then Status:=Direction;
                   end;
                 end;

               end else begin { utok se nezdaril }
Not_succes2:
                  IntelliSearching_for_attack_flag:=0;
               end;
            end; { budova je nepratelska }
          end; { cilem je budova }

     end else begin { utok na vzdusne urovni}
        if (TargetUnit = Nil) then
           Error(0,'unita _units2, procedura Prepare_attack_unit, bod 3');
        Targ:=TargetUnit^.TargetType;
        if (CheckAttackUnit(Targ,_unit) and
            (Races[Race].Friend[TargetUnit^.Race] = 0))
        then begin { mozno utocit }
           BTarget:=Nil;
           Target:=@TargetUnit;
           MoveStatus:=AttackType; BanDir:=0; First_mov:=True;
           if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 255) and
               not SetAttack(_unit)) then begin
              Target:=Nil; MoveStatus:=0;
              GoTo Not_succes3;
           end;
           if (not SetAttack(_unit) and (Stop_)) then begin
              Target:=Nil; MoveStatus:=0;
              GoTo Not_succes1;
           end;
           if ((MoveStatus < 8) or (MoveStatus > 32)) then
             if (ActiveWeapon = 1) then begin
                ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                if (GameTimming = 1) then begin
                   ShootFlag:=ShootFlag shl 1;
                   Inc(ShootFlag, ShootDelayFlag1);
                end else
                   Inc(ShootFlag, ShootDelayFlag1 shr 1);
             end else if (ActiveWeapon > 1) then begin
                ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                if (GameTimming = 1) then begin
                   ShootFlag:=ShootFlag shl 1;
                   Inc(ShootFlag, ShootDelayFlag2);
                end else
                   Inc(ShootFlag, ShootDelayFlag2 shr 1);
                {pozn. zda zbran2 skutecne existuje se zjistuje az pri strelbe }
             end;
           Attacking:=True;
           if ((Status > 0) and (Status <= 129)) then Stop_:=True
           else begin
             if (not Stop_) then begin
               Stop_unit(_unit,False,True);
               if (AttackType = 16) then Status:=Direction;
             end;
           end;

        end else begin { nemozno utocit }
Not_succes3:
            IntelliSearching_for_attack_flag:=0;
        end;
     end; { utok na vzdusne urovni }
   end else begin { with }
      Error(0,'unita _units2, procedura Prepare_attack_unit, pokus utocit neaktivni jednotkou');
   end;
end;


{ ***** }
procedure Searching_for_attack(_unit:PUnit);
{ procedura okolo jednotky _unit prohleda aktualni okruh a narazi-li
  na nepratelskou jednotku, zkusi Prepare_attack_unit
  Priority:
  1. letecky cil
  2. pozemni cil
  3. budova
}
var Range,Range2,AirRange,AirRange2:Word;
    AirAttack:Boolean;
    I,K,L,M,N:Word;
    { K,L udava levy horni a M,N pravy dolni bod ctyruhelniku, jehoz obvod
      se bude prohledavat; obecne jde o ctverec, ktery vsak muze byt
      deformovan okrajem mapy }
    AirUnit, GroundUnit, PomUnit : PUnit; { nalezene cile }
    Build, PomBuilding : PBuilding; { nalezena nepratelska budova v dostrelu }
    Computer, MyFriend:Boolean;
begin
  if (_unit^.Activity) then with (_unit^) do begin
    if ((Race = ThisCompRace1) or (Race = ThisCompRace2) or
         (Race = ThisCompRace3) or (Race = ThisCompRace4) or
         (Race = ThisCompRace5)) then
       Computer:=True else Computer:=False;
     MyFriend:=Races[Race].Friend[MyRace] = 2;
     AirUnit:=Nil; GroundUnit:=Nil; Build:=Nil;
     Range:=Unit_types[UnitType,Races[Race].Ally].ShootRange1; AirAttack:=False;
     AirRange:=0; AirRange2:=0;
     asm { nyni vytahneme max. dostrel }
        mov Ax,Range
        xor Bx,Bx
        mov Bl,Al
        mov Al,Ah
        xor Ah,Ah
        mov Range,Ax { max. dostrel zbrane 1 }
        mov Range2,Bx
        cmp Range2,0
        je @Konec
        dec Range2 { max. dostrel zbrane 2 }
@Konec:
     end;
     if (Unit_types[UnitType,Races[Race].Ally].AirAttack1 <> 0) then begin { PVO dostrel }
        AirRange:=Range; AirRange2:=Range2;
     end;
     if ((Unit_types[UnitType,Races[Race].Ally].ShootRange2 <> 0) or (Range2 = 0))
     then Range2:=1; { zjisti spodni hranici dostrelu }
     if (Unit_types[UnitType,Races[Race].Ally].AirAttack2 <> 0) then begin { PVO dostrel }
        AirRange2:=Range2;
     end;
     if (UnitType = 18) then begin { stihac }
        AirRange:=10; AirRange2:=1;
        Range:=10; Range2:=1;
     end;

     if ((Computer) and (MaxSearchingRange <> 0) or (ActiveDefence))
     then begin { pocitac nebo jednotka v modu aktivni obrany vidi daleko }
        if (AirRange <> 0) then AirRange:=MaxSearchingRange;
        if (Range <> 0) then Range:=MaxSearchingRange;
     end;

     { nyni si zjistime aktualni prohledavaci uroven }
     if (SearchingFlag < Range2) then SearchingFlag:=Range
     else begin
        Dec(SearchingFlag);
        if (SearchingFlag < Range2) then SearchingFlag:=Range;
     end;
     if ((SearchingFlag <= AirRange) and (SearchingFlag >= AirRange2) and
         (SearchingFlag <> 0)) then AirAttack:=True;  { mozno letecky utocit }

     if (SearchingFlag <> 0) then begin
       { nyni si vypocteme souradnice pro prohledavani }
       if (SearchingFlag > IPos) then K:=0 else K:=IPos-SearchingFlag;
       if (SearchingFlag > JPos) then L:=0 else L:=JPos-SearchingFlag;
       if ((SearchingFlag+IPos) > IMax) then
          M:=IMax else M:=IPos+SearchingFlag;
       if ((SearchingFlag+JPos) > JMax) then
          N:=JMax else N:=JPos+SearchingFlag;

       for I:=K to M do begin { horni, spodni cara }
          if (Range_check(IPos,JPos,I,L,Range)) then
          with (Map^[I,L]) do begin  { HORNI }
             if ((AirAttack) and (Second_level <> 0) and (AirUnit = Nil) and
                 (Races[Race].Friend[Units[Second_level]^.Race] = 0) and
                 (Units[Second_level]^.Activity) and
                 (MyFriend and (Units[Second_level]^.Visibility) or
                  (not MyFriend) and (Units[Second_level]^.EnemyVisibility)))
             then
                AirUnit:=Units[Second_level]; { vzdusna jednotka }
             if (First_level <> 0) then { budova nebo jednotka }
               if (Level_type and 128 = 128) then begin
               { budova }
                  if ((Races[Race].Friend[Buildings[First_level]^.Race] = 0) and
                      (Build = Nil) and (Buildings[First_level]^.Activity) and
                      (MyFriend and (Buildings[First_level]^.Visibility) or
                       (not MyFriend) and (Buildings[First_level]^.EnemyVisibility)))
                  then Build:=Buildings[First_level];
               end else
               { jednotka }
                  if ((Races[Race].Friend[Units[First_level]^.Race] = 0) and
                      (GroundUnit = Nil) and (Units[First_level]^.Activity) and
                      (MyFriend and (Units[First_level]^.Visibility) or
                       (not MyFriend) and (Units[First_level]^.EnemyVisibility)))
                  then GroundUnit:=Units[First_level];
          end;
          if (Range_check(IPos,JPos,I,N,Range)) then
          with (Map^[I,N]) do begin  { SPODNI }
             if ((AirAttack) and (Second_level <> 0) and (AirUnit = Nil) and
                 (Races[Race].Friend[Units[Second_level]^.Race] = 0) and
                 (Units[Second_level]^.Activity) and
                 (MyFriend and (Units[Second_level]^.Visibility) or
                  (not MyFriend) and (Units[Second_level]^.EnemyVisibility))) then
                AirUnit:=Units[Second_level]; { vzdusna jednotka }
             if (First_level <> 0) then { budova nebo jednotka }
               if (Level_type and 128 = 128) then begin
               { budova }
                  if ((Races[Race].Friend[Buildings[First_level]^.Race] = 0) and
                      (Build = Nil) and (Buildings[First_level]^.Activity) and
                      (MyFriend and (Buildings[First_level]^.Visibility) or
                       (not MyFriend) and (Buildings[First_level]^.EnemyVisibility)))
                  then Build:=Buildings[First_level];
               end else
               { jednotka }
                  if ((Races[Race].Friend[Units[First_level]^.Race] = 0) and
                      (GroundUnit = Nil) and (Units[First_level]^.Activity) and
                      (MyFriend and (Units[First_level]^.Visibility) or
                       (not MyFriend) and (Units[First_level]^.EnemyVisibility)))
                  then GroundUnit:=Units[First_level];
          end;
       end;
       for I:=L+1 to N-1 do begin { leva, prava cara }
          if (Range_check(IPos,JPos,K,I,Range)) then
          with (Map^[K,I]) do begin  { LEVA }
             if ((AirAttack) and (Second_level <> 0) and (AirUnit = Nil) and
                 (Races[Race].Friend[Units[Second_level]^.Race] = 0) and
                 (Units[Second_level]^.Activity) and
                 (MyFriend and (Units[Second_level]^.Visibility) or
                  (not MyFriend) and (Units[Second_level]^.EnemyVisibility))) then
                AirUnit:=Units[Second_level]; { vzdusna jednotka }
             if (First_level <> 0) then { budova nebo jednotka }
               if (Level_type and 128 = 128) then begin
               { budova }
                  if ((Races[Race].Friend[Buildings[First_level]^.Race] = 0) and
                      (Build = Nil) and (Buildings[First_level]^.Activity) and
                      (MyFriend and (Buildings[First_level]^.Visibility) or
                       (not MyFriend) and (Buildings[First_level]^.EnemyVisibility)))
                  then Build:=Buildings[First_level];
               end else
               { jednotka }
                  if ((Races[Race].Friend[Units[First_level]^.Race] = 0) and
                      (GroundUnit = Nil) and (Units[First_level]^.Activity) and
                      (MyFriend and (Units[First_level]^.Visibility) or
                       (not MyFriend) and (Units[First_level]^.EnemyVisibility)))
                  then GroundUnit:=Units[First_level];
          end;
          if (Range_check(IPos,JPos,M,I,Range)) then
          with (Map^[M,I]) do begin  { PRAVA }
             if ((AirAttack) and (Second_level <> 0) and (AirUnit = Nil) and
                 (Races[Race].Friend[Units[Second_level]^.Race] = 0) and
                 (Units[Second_level]^.Activity) and
                 (MyFriend and (Units[Second_level]^.Visibility) or
                  (not MyFriend) and (Units[Second_level]^.EnemyVisibility))) then
                AirUnit:=Units[Second_level]; { vzdusna jednotka }
             if (First_level <> 0) then { budova nebo jednotka }
               if (Level_type and 128 = 128) then begin
               { budova }
                  if ((Races[Race].Friend[Buildings[First_level]^.Race] = 0) and
                      (Build = Nil) and (Buildings[First_level]^.Activity) and
                      (MyFriend and (Buildings[First_level]^.Visibility) or
                       (not MyFriend) and (Buildings[First_level]^.EnemyVisibility)))
                  then Build:=Buildings[First_level];
               end else
               { jednotka }
                  if ((Races[Race].Friend[Units[First_level]^.Race] = 0) and
                      (GroundUnit = Nil) and (Units[First_level]^.Activity) and
                      (MyFriend and (Units[First_level]^.Visibility) or
                       (not MyFriend) and (Units[First_level]^.EnemyVisibility)))
                  then GroundUnit:=Units[First_level];
          end;
       end;
     end; { if (SearchingFlag <> 0) then }
     PomUnit:=Nil; PomBuilding:=Nil;
     if (UnitType = 18) then begin { stihac - jen na vzdusne cile }
        Build:=Nil; GroundUnit:=Nil;
     end;
     if (AirUnit <> Nil) then begin
       if ((not ActiveDefence) and (not Computer)) then
         Prepare_attack_unit(Units[AirUnit^.Index],PomBuilding,32,_unit,1)
       else Prepare_attack_unit(Units[AirUnit^.Index],PomBuilding,16,_unit,1);
     end else
       if (GroundUnit <> Nil) then begin
           if ((not ActiveDefence) and (not Computer)) then
             Prepare_attack_unit(Units[GroundUnit^.Index],PomBuilding,32,_unit,0)
           else  Prepare_attack_unit(Units[GroundUnit^.Index],PomBuilding,16,_unit,0);
       end else
         if (Build <> Nil) then begin
           if ((not ActiveDefence) and (not Computer)) then
              Prepare_attack_unit(PomUnit,Buildings[Build^.Index],32,_unit,0)
           else Prepare_attack_unit(PomUnit,Buildings[Build^.Index],16,_unit,0);
         end;
  end;
end;

{ ***** }
procedure Intelli_searching_for_attack(_unit:PUnit);
{ procedura okolo jednotky _unit prohleda aktualni okruh a narazi-li
  na nepratelskou jednotku, zkusi Prepare_attack_unit
}
label Konec;
var Distanc,Range,Range2,RangeEnd,Range2End,AirRange,AirRangeEnd:Word;
    I,J,K,L,M,N:Word;
    TargetUnit:PUnit;
    TargetBuilding:PBuilding;
    AirAttacker, GroundAttacker, MyFriend:Boolean;
    RangeStatus,TargetWeight, PomTargetWeight:Integer;
    PomW:Single;
begin
  { RangeStatus : 0 .. jednotka neni v dostrelu-je prilis blizko
                  1 .. cil je v dostrelu zbrane2; 2 .. cil je v dostrelu
                  zbrane1; 3 .. cil neni v dostrelu-je prilis daleko }
  if (_unit^.Activity) then with (_unit^) do with (Unit_types[UnitType,Races[Race].Ally]) do begin
     MyFriend:=Races[Race].Friend[MyRace] = 2;
     TargetWeight:=0; PomTargetWeight:=0;
     TargetUnit:=Nil; TargetBuilding:=Nil;
     AirAttacker:=False;
     Range:=Unit_types[UnitType,Races[Race].Ally].ShootRange1; RangeEnd:=0;
     Range2:=Unit_types[UnitType,Races[Race].Ally].ShootRange2; Range2End:=0;
     AirRange:=0; AirRangeEnd:=0;
     asm { nyni vytahneme max. dostrel }
        mov Ax,Range
        mov Cl,Ah
        xor Ch,Ch
        xor Ah,Ah
        mov Range,Cx { max. dostrel zbrane 1 }
        mov RangeEnd,Ax { min. dostrel zbrane 1 }

        mov Ax,Range2
        mov Cl,Ah
        xor Ch,Ch
        xor Ah,Ah
        mov Range2,Cx { max. dostrel zbrane 2 }
        mov Range2End,Ax { min. dostrel zbrane 2 }
@Konec:
     end;
     if ((Range = 0) and (Range2 = 0)) then GoTo Konec;
     if (Unit_types[UnitType,Races[Race].Ally].AirAttack1 <> 0) then begin { PVO dostrel }
        AirRange:=Range; AirRangeEnd:=RangeEnd; AirAttacker:=True;
     end;
     if (Unit_types[UnitType,Races[Race].Ally].AirAttack2 <> 0) then begin { PVO dostrel }
        if (AirRange = 0) then AirRange:=Range2;
        AirRangeEnd:=Range2End; AirAttacker:=True;
     end;
     if (UnitType = 23) then AIAttackType:=3; { autodetonator - priorita
                                                budovy}
     with (Unit_types[UnitType,Races[Race].Ally]) do begin
       GroundAttacker:=(LightAttack1 <> 0) or (HeavyAttack1 <> 0) or
                       (LightAttack2 <> 0) or (HeavyAttack2 <> 0);
     end;
     {x}
     if ((MaxSearchingRange >= Range) and (MaxSearchingRange >= AirRange))
     then SearchingFlag:=MaxSearchingRange
     else
       if (Range >= AirRange) then SearchingFlag:=Range else SearchingFlag:=AirRange;
     {x}
     if ((UnitType = 18) or (UnitType = 19)) then SearchingFlag:=13;

     if (Range2 = 0) then Range2End := RangeEnd;
     if (Range2End = 0) then Range2End:=1; { testujeme misto Range2End-1
     kvuli eventualni mezere mezi 0 a min. dostrelem zbrane2 }

     { nyni si vypocteme souradnice pro prohledavani }
     if (SearchingFlag > IPos) then K:=0 else K:=IPos-SearchingFlag;
     if (SearchingFlag > JPos) then L:=0 else L:=JPos-SearchingFlag;
     if ((SearchingFlag+IPos) > IMax) then
        M:=IMax else M:=IPos+SearchingFlag;
     if ((SearchingFlag+JPos) > JMax) then
        N:=JMax else N:=JPos+SearchingFlag;

     for I:=K to M do begin
      for J:=L to N do begin
        with (Map^[I,J]) do begin
          if ((Second_level <> 0) and (Units[Second_level] <> Nil) and
              (AirAttacker) and (Races[Race].Friend[Units[Second_level]^.Race] = 0) and
              (Units[Second_level]^.Activity) and
              (MyFriend and (Units[Second_level]^.Visibility) or
              (MyFriend and (MapBckTemp^[Units[Second_level]^.IPos,Units[Second_level]^.JPos].Visibilit and
               Races[Race].VisMask <> 0)) or
              (not MyFriend) and (Units[Second_level]^.EnemyVisibility)))
          then begin
          { NALEZEN VZDUSNY CIL! }
             { zhodnot nalezeny cil }
             if (Range_check(IPos,JPos,I,J,Range2End-1)) then
               RangeStatus:=0
             else
              if (Range_check(IPos,JPos,I,J,Range2)) then
                RangeStatus:=1
              else
                if (Range_check(IPos,JPos,I,J,Range)) then
                  RangeStatus:=2
                else RangeStatus:=3;
             case (RangeStatus) of
               0 : begin { uvnitr min. dostrelu - ignorujeme }
                      PomTargetWeight:=-10;
                   end;
               1 : begin { zbran2 - pridame bonus }
                     PomW:=Units[Second_level]^.Damage;
                     if (AirAttack2 > 0) then
                       PomTargetWeight:=Round((PomW * 2) /
                                              (GetKadence(Race,ShootSpeed2,UnitType)*(AirAttack2+AAttackBonus2)))
                     else PomTargetWeight:=0;
                     if (PomTargetWeight > 20) then PomTargetWeight:=0
                     else PomTargetWeight:=20-PomTargetWeight;
                     Inc(PomTargetWeight,5);
                     { bonus za to, ze se na cil jiz strili }
                      if ((Units[Second_level]^.WarningBlingFlag <> 0) or
                          ((Target <> Nil) and (Target^ <> Nil) and
                           (Target^ = Units[Second_level]))) then
                        Inc(PomTargetWeight,3);
                   end;
               2 : begin { zbran1 - pridame bonus }
                      PomW:=Units[Second_level]^.Damage;
                      if (AirAttack1 > 0) then
                        PomTargetWeight:=Round((PomW * 2) /
                                               (GetKadence(Race,ShootSpeed1,UnitType)*(AirAttack1+AAttackBonus1)))
                      else PomTargetWeight:=0;
                      if (PomTargetWeight > 20) then PomTargetWeight:=0
                      else PomTargetWeight:=20-PomTargetWeight;
                      Inc(PomTargetWeight,5);
                      { bonus za to, ze se na cil jiz strili }
                      if ((Units[Second_level]^.WarningBlingFlag <> 0) or
                          ((Target <> Nil) and (Target^ <> Nil) and
                           (Target^ = Units[Second_level]))) then
                        Inc(PomTargetWeight,3);
                   end;
               3 : begin { mimo dostrel }
                     PomW:=Units[Second_level]^.Damage;
                     if (AirAttack1 > 0) then
                        PomTargetWeight:=Round((PomW * 2) /
                                            (GetKadence(Race,ShootSpeed1,UnitType)*(AirAttack1+AAttackBonus1)))
                     else PomTargetWeight:=0;
                     if (PomTargetWeight > 20) then PomTargetWeight:=0
                     else PomTargetWeight:=20-PomTargetWeight;
                     { zaporny bonus za kazde policko mimo dostrel je roven
                       1 na kazde policko }
                     Distanc:=GetDistance(IPos,JPos,I,J);
                     if (Distanc >= Range) then Dec(Distanc,Range){} else Distanc:=0;
                     if (Distanc <= 2) then Distanc:=1
                       else if (Distanc <= 3) then Distanc:=2
                            else if (Distanc <= 5) then Distanc:=4
                                 else Distanc:=8;
                     if (PomTargetWeight >= Distanc) then
                        Dec(PomTargetWeight,Distanc)
                     else PomTargetWeight:=0;

                     { bonus za to, ze se na cil jiz strili }
                     if ((Target <> Nil) and (Target^ <> Nil) and
                         (Target^ = Units[Second_level]))
                     then Inc(PomTargetWeight) else
                       if (Units[Second_level]^.WarningBlingFlag <> 0) then
                         Inc(PomTargetWeight,2);
                   end;
             end;
             with (Units[Second_level]^) do begin
                if (ADangerClass < 255) then Inc(PomTargetWeight,ADangerClass);
                if (DangerClass < 255) then Inc(PomTargetWeight,DangerClass);
             end;
             { nyni bonusy za utocne ukoly }
             if (AIAttackType = 2) then Inc(PomTargetWeight,10)
             else
               if ((AIAttackType = 1) and (AIAttackUnit <> Nil) and
                   (AIAttackUnit^ = Units[Second_level]))
               then Inc(PomTargetWeight,100);
             { utok na vzdusny cil ma vyssi prioritu nez jine cile: }
             Inc(PomTargetWeight,3);
             { stihac at utoci spise na vzdusne cile: }
             if (_unit^.UnitType = 18) then Inc(PomTargetWeight,5);

             if ((RangeStatus = 3) and (Race = MyRace) and (not ActiveDefence))
             then PomTargetWeight:=0;

             if (PomTargetWeight > TargetWeight) then with (Races[Race]) do begin
                if ((not Free_attack) and
                    ((Units[Second_level]^.IInfoPos = IInfoPos) and
                     (Units[Second_level]^.JInfoPos = JInfoPos) or
                     (TaskGroup <> InvalidTaskGroupNumber) and
                     (TaskGroups^[TaskGroup].Validity) and
                     (TaskGroups^[TaskGroup].MasterCommand = AttackCom) and
                     (Units[Second_level]^.IInfoPos = TaskGroups^[TaskGroup].MasterITarg) and
                     (Units[Second_level]^.IInfoPos = TaskGroups^[TaskGroup].MasterJTarg)))
                then  Free_attack:=True;
                if (Free_attack or (_unit^.UnitType = 18) or (_unit^.UnitType = 19))
                then begin
                   TargetWeight:=PomTargetWeight; TargetUnit:=Units[Second_level];
                   TargetBuilding:=Nil;
                end;
             end;
          end;
          {xxx}
          if ((First_level <> 0) and (GroundAttacker)) then
          { budova nebo jednotka }
          if (Level_type and 128 = 128) then begin
           if ((Races[Race].Friend[Buildings[First_level]^.Race] = 0) and
               (Buildings[First_level]^.Activity) and
               (MyFriend and (Buildings[First_level]^.Visibility) or
               (MyFriend and (MapBckTemp^[Buildings[First_level]^.IPos,Buildings[First_level]^.JPos].Visibilit and
                Races[Race].VisMask <> 0)) or
               (not MyFriend) and (Buildings[First_level]^.EnemyVisibility)))
           then begin
           { NALEZENA BUDOVA! }
              if (Range_check(IPos,JPos,I,J,Range2End-1)) then
                RangeStatus:=0
              else
               if (Range_check(IPos,JPos,I,J,Range2)) then
                 RangeStatus:=1
               else
                 if (Range_check(IPos,JPos,I,J,Range)) then
                   RangeStatus:=2
                 else RangeStatus:=3;
               case (RangeStatus) of
                 0 : begin { uvnitr min. dostrelu - ignorujeme }
                      PomTargetWeight:=-10;
                     end;
                 1 : begin { zbran2 - pridame bonus }
                       PomW:=Buildings[First_level]^.Damage;
                       if (HeavyAttack2 > 0) then
                         PomTargetWeight:=Round((PomW) /
                                                (GetKadence(Race,ShootSpeed2,UnitType)*(HeavyAttack2+HAttackBonus2)))
                       else PomTargetWeight:=0;
                       if (PomTargetWeight > 40) then PomTargetWeight:=0
                       else PomTargetWeight:=(40-PomTargetWeight) shr 1;
                       Inc(PomTargetWeight,5);
                       { bonus za to, ze se na cil jiz strili }
                       if ((Buildings[First_level]^.WarningBlingFlag <> 0) or
                          ((BTarget <> Nil) and (BTarget^ <> Nil) and
                           (BTarget^ = Buildings[First_level]))) then
                         Inc(PomTargetWeight,3);
                     end;
                 2 : begin { zbran1 - pridame bonus }
                       PomW:=Buildings[First_level]^.Damage;
                       if (HeavyAttack1 > 0) then
                         PomTargetWeight:=Round((PomW) /
                                                (GetKadence(Race,ShootSpeed1,UnitType)*(HeavyAttack1+HAttackBonus1)))
                       else PomTargetWeight:=0;
                       if (PomTargetWeight > 40) then PomTargetWeight:=0
                       else PomTargetWeight:=(40-PomTargetWeight) shr 1;
                       Inc(PomTargetWeight,5);
                       { bonus za to, ze se na cil jiz strili }
                       if ((Buildings[First_level]^.WarningBlingFlag <> 0) or
                          ((BTarget <> Nil) and (BTarget^ <> Nil) and
                           (BTarget^ = Buildings[First_level]))) then
                         Inc(PomTargetWeight,3);
                    end;
                 3 : begin { mimo dostrel }
                       PomW:=Buildings[First_level]^.Damage;
                       if (HeavyAttack1 > 0) then
                         PomTargetWeight:=Round((PomW) /
                                                (GetKadence(Race,ShootSpeed1,UnitType)*(HeavyAttack1+HAttackBonus1)))
                       else PomTargetWeight:=0;
                       if (PomTargetWeight > 40) then PomTargetWeight:=0
                       else PomTargetWeight:=(40-PomTargetWeight) shr 1;
                       { zaporny bonus za kazde policko mimo dostrel }
                       Distanc:=GetDistance(IPos,JPos,I,J);
                       if (Distanc >= Range) then Dec(Distanc,Range){} else Distanc:=0;
                       if (Distanc <= 2) then Distanc:=1
                       else if (Distanc <= 3) then Distanc:=2
                            else if (Distanc <= 5) then Distanc:=4
                                 else Distanc:=8;
                       if (PomTargetWeight >= Distanc) then
                         Dec(PomTargetWeight,Distanc)
                       else PomTargetWeight:=0;

                       { bonus za to, ze se na cil jiz strili }
                       if ((BTarget <> Nil) and (BTarget^ <> Nil) and
                           (BTarget^ = Buildings[First_level]))
                       then Inc(PomTargetWeight) else
                         if (Buildings[First_level]^.WarningBlingFlag <> 0) then
                           Inc(PomTargetWeight,2);
                     end;
               end;
               { nyni bonusy za utocne ukoly }
               if (AIAttackType = 3) then Inc(PomTargetWeight,10)
               else
                 if ((AIAttackType = 0) and (AIAttackBuilding <> Nil) and
                     (AIAttackBuilding^ = Buildings[First_level]))
                 then Inc(PomTargetWeight,100);

               case (Buildings[First_level]^.BuildingType) of
               { zvyhodnime ruzne typy budov }
                  1  : Inc(PomTargetWeight,1); { zakladna }
                  4  : Inc(PomTargetWeight,1); { recyklace}
                  5  : Inc(PomTargetWeight,10); { elektrarna }
                  13 : Inc(PomTargetWeight,3); { centrum oprav }
                  21 : Inc(PomTargetWeight,2); { radar }
               end;

               if ((RangeStatus = 3) and (Race = MyRace) and (not ActiveDefence))
               then PomTargetWeight:=0;

               if (PomTargetWeight > TargetWeight) then with (Races[Race]) do begin
                 if ((not Free_attack) and
                     ((Buildings[First_level]^.IPos div IInfoDiv= IInfoPos) and
                      (Buildings[First_level]^.JPos div JInfoDiv= JInfoPos) or
                      (TaskGroup <> InvalidTaskGroupNumber) and
                      (TaskGroups^[TaskGroup].Validity) and
                      (TaskGroups^[TaskGroup].MasterCommand = AttackCom) and
                      (Buildings[First_level]^.IPos div IInfoDiv = TaskGroups^[TaskGroup].MasterITarg) and
                      (Buildings[First_level]^.JPos div JInfoDiv = TaskGroups^[TaskGroup].MasterJTarg)))
                 then  Free_attack:=True;
                 if (Free_attack) then begin
                    TargetWeight:=PomTargetWeight; TargetBuilding:=Buildings[First_level];
                    TargetUnit:=Nil;
                 end;
               end;
           end;
          {xxx}
          end else
           if ((Races[Race].Friend[Units[First_level]^.Race] = 0) and
               (Units[First_level]^.Activity) and
               (MyFriend and (Units[First_level]^.Visibility) or
               (MyFriend and (MapBckTemp^[Units[First_level]^.IPos,Units[First_level]^.JPos].Visibilit and
                Races[Race].VisMask <> 0)) or
               (not MyFriend) and (Units[First_level]^.EnemyVisibility)))
           then begin
           { NALEZENA JEDNOTKA! }
              if (Range_check(IPos,JPos,I,J,Range2End-1)) then
                RangeStatus:=0
              else
               if (Range_check(IPos,JPos,I,J,Range2)) then
                 RangeStatus:=1
               else
                 if (Range_check(IPos,JPos,I,J,Range)) then
                   RangeStatus:=2
                 else RangeStatus:=3;
               case (RangeStatus) of
                 0 : begin { uvnitr min. dostrelu - ignorujeme }
                      PomTargetWeight:=-10;
                     end;
                 1 : begin { zbran2 - pridame bonus }
                       PomW:=Units[First_level]^.Damage;
                       case (Units[First_level]^.TargetType) of {typ cilu}
                       0..1 : if (LightAttack2 > 0) then
                                PomTargetWeight:=Round((PomW * 2) / { lehky }
                                                       (GetKadence(Race,ShootSpeed2,UnitType)*(LightAttack2+LAttackBonus2)))
                              else PomTargetWeight:=0;
                          2 : if (HeavyAttack2 > 0) then
                                PomTargetWeight:=Round((PomW * 2) / { tezky }
                                                       (GetKadence(Race,ShootSpeed2,UnitType)*(HeavyAttack2+HAttackBonus2)))
                              else PomTargetWeight:=0;
                       else {jiny?}
                          if (HeavyAttack2 > 0) then
                             PomTargetWeight:=Round((PomW * 2) / { tezky }
                                                    (GetKadence(Race,ShootSpeed2,UnitType)*(HeavyAttack2+HAttackBonus2)))
                          else PomTargetWeight:=0;
                       end;
                       if (PomTargetWeight > 20) then PomTargetWeight:=0
                       else PomTargetWeight:=20-PomTargetWeight;
                       Inc(PomTargetWeight,5);
                       { bonus za to, ze se na cil jiz strili }
                       if ((Units[First_level]^.WarningBlingFlag <> 0) or
                           ((Target <> Nil) and (Target^ <> Nil) and
                            (Target^ = Units[First_level]))) then
                         Inc(PomTargetWeight,3);
                     end;
                 2 : begin { zbran1 - pridame bonus }
                       PomW:=Units[First_level]^.Damage;
                       case (Units[First_level]^.TargetType) of {typ cilu}
                       0..1 : if (LightAttack1 > 0) then
                                PomTargetWeight:=Round((PomW * 2) / { lehky }
                                                       (GetKadence(Race,ShootSpeed1,UnitType)*(LightAttack1+LAttackBonus1)))
                              else PomTargetWeight:=0;
                          2 : if (HeavyAttack1 > 0) then
                                PomTargetWeight:=Round((PomW * 2) / { tezky }
                                                       (GetKadence(Race,ShootSpeed1,UnitType)*(HeavyAttack1+HAttackBonus1)))
                              else PomTargetWeight:=0;
                       else {jiny?}
                           if (HeavyAttack1 > 0) then
                              PomTargetWeight:=Round((PomW * 2) / { jiny }
                                                     (GetKadence(Race,ShootSpeed1,UnitType)*(HeavyAttack1+HAttackBonus1)))
                           else PomTargetWeight:=0;
                       end;
                       if (PomTargetWeight > 20) then PomTargetWeight:=0
                       else PomTargetWeight:=20-PomTargetWeight;
                       Inc(PomTargetWeight,5);
                       { bonus za to, ze se na cil jiz strili }
                       if ((Units[First_level]^.WarningBlingFlag <> 0) or
                           ((Target <> Nil) and (Target^ <> Nil) and
                            (Target^ = Units[First_level]))) then
                         Inc(PomTargetWeight,3);
                    end;
                 3 : begin { mimo dostrel }
                       PomW:=Units[First_level]^.Damage;
                       case (Units[First_level]^.TargetType) of {typ cilu}
                       0..1 : if (LightAttack1 > 0) then
                                PomTargetWeight:=Round((PomW * 2) / { lehky }
                                                       (GetKadence(Race,ShootSpeed1,UnitType)*(LightAttack1+LAttackBonus1)))
                              else PomTargetWeight:=0;
                          2 : if (HeavyAttack1 > 0) then
                                PomTargetWeight:=Round((PomW * 2) / { tezky }
                                                       (GetKadence(Race,ShootSpeed1,UnitType)*(HeavyAttack1+HAttackBonus1)))
                              else PomTargetWeight:=0;
                       else {jiny?}
                           if (HeavyAttack1 > 0) then
                              PomTargetWeight:=Round((PomW * 2) / { jiny }
                                                     (GetKadence(Race,ShootSpeed1,UnitType)*(HeavyAttack1+HAttackBonus1)))
                           else PomTargetWeight:=0;
                       end;
                       if (PomTargetWeight > 20) then PomTargetWeight:=0
                       else PomTargetWeight:=20-PomTargetWeight;
                       { zaporny bonus za kazde policko mimo dostrel }
                       Distanc:=GetDistance(IPos,JPos,I,J);
                       if (Distanc >= Range) then Dec(Distanc,Range){} else Distanc:=0;
                       if (Distanc <= 2) then Distanc:=1
                       else if (Distanc <= 3) then Distanc:=2
                            else if (Distanc <= 5) then Distanc:=4
                                 else Distanc:=8;
                       if (PomTargetWeight >= Distanc) then
                          Dec(PomTargetWeight,Distanc)
                       else PomTargetWeight:=0;

                       { bonus za to, ze se na cil jiz strili }
                       if ((Target <> Nil) and (Target^ <> Nil) and
                           (Target^ = Units[First_level]))
                       then Inc(PomTargetWeight) else
                         if (Units[First_level]^.WarningBlingFlag <> 0) then
                           Inc(PomTargetWeight,2);
                     end;
               end;
               with (Units[First_level]^) do begin
                 if (ADangerClass < 255) then Inc(PomTargetWeight,ADangerClass);
                 if (DangerClass < 255) then Inc(PomTargetWeight,DangerClass);
               end;

               { nyni bonusy za utocne ukoly }
               if (AIAttackType = 2) then Inc(PomTargetWeight,10)
               else
                 if ((AIAttackType = 1) and (AIAttackUnit <> Nil) and
                     (AIAttackUnit^ = Units[First_level]))
                 then Inc(PomTargetWeight,100);

               case (Units[First_level]^.UnitType) of
               { zvyhodnime ruzne typy jednotek }
                   2  : Inc(PomTargetWeight); { recyklator }
                  19  : if (TargetType = 3) then { terminator }
                          Inc(PomTargetWeight,15); { utocime-li letadlem,
                         pak je terminator bezbranny! }
                  18  : if (TargetType <> 3) then { stihac }
                          Inc(PomTargetWeight,15); { neutocime-li letadlem,
                         pak je letoun na zemi snadny cil! }
                  33  : Inc(PomTargetWeight,10); { slozena budova }
                  32  : if (TargetType <> 3) then { infra SAM }
                          Inc(PomTargetWeight,5); { neutocime-li letadlem,
                         jsou PVO rakety neskodne }
               end;

               if ((RangeStatus = 3) and (Race = MyRace) and (not ActiveDefence))
               then PomTargetWeight:=0;

               if (PomTargetWeight > TargetWeight) then with (Races[Race]) do begin
                 if ((not Free_attack) and
                     ((Units[First_level]^.IInfoPos = IInfoPos) and
                      (Units[First_level]^.JInfoPos = JInfoPos) or
                      (TaskGroup <> InvalidTaskGroupNumber) and
                      (TaskGroups^[TaskGroup].Validity) and
                      (TaskGroups^[TaskGroup].MasterCommand = AttackCom) and
                      (Units[First_level]^.IInfoPos = TaskGroups^[TaskGroup].MasterITarg) and
                      (Units[First_level]^.IInfoPos = TaskGroups^[TaskGroup].MasterJTarg)))
                 then  Free_attack:=True;
                 if (Free_attack or (_unit^.UnitType = 18) or (_unit^.UnitType = 19)) then begin
                   TargetWeight:=PomTargetWeight; TargetUnit:=Units[First_level];
                   TargetBuilding:=Nil;
                 end;
               end;
           end;
        end; { with ... }
      end; { for J:=L to N do ... }
     end; { for I:=K to M do ... }

     { xxx }
     { NYNI ZANALYZUJEME VYSLEDKY }
     with (Unit_types[UnitType,Races[Race].Ally]) do begin
       if (UnitLevel <> 255) then begin
          RangeStatus:=Round((1.0*UnitSpeedPct[SpeedLevel])/10);
          if (RangeStatus > 0) then
            RangeStatus:=(32 div RangeStatus)
          else RangeStatus:=10;
       end else RangeStatus:=0;
     end;
     if (TargetUnit <> Nil) then begin
       Prepare_attack_unit(Units[TargetUnit^.Index],TargetBuilding,16,_unit,0);
       { dejme jednotce moznost alespon 1x na cil vystrelit }
       IntelliSearching_for_attack_flag:=-(3*RangeStatus);
     end else
       if (TargetBuilding <> Nil) then begin
         Prepare_attack_unit(TargetUnit,Buildings[TargetBuilding^.Index],16,_unit,0);
         { dejme jednotce moznost alespon 1x na cil vystrelit }
         IntelliSearching_for_attack_flag:=-(3*RangeStatus);
       end;
  end;
Konec:
end;

{ ***** }
procedure Attack_unit(_unit:PUnit);
{ jednotka je v modu utoceni - zajistuje pronasledovani, strelbu
}
label Skip;
var Pom, Moving:Boolean;
    Dir,Modulo:Byte;
    PomTarget:PUnit;
    PomBTarget:PBuilding;
    Level, RandomNum, RndNum, RndNum2:Byte;
    ISize, JSize, IP, JP, Ix, Jx, Distanc, I, J:Word;

   { ***** }
    function GetDistance2(IThis, JThis, ITar, JTar : Word): Word;
    { vraci vzdalenost z bodu IThis, JThis do ITar, JTar; vraci vizualne
      nejblizsi misto (i kdyz z hlediska pohybu jich muze vyjit vice stejnych;
      v tomto pripade jakoby uvazujeme, ze se jednotky nemouhou pohybovat sikmo )
    }
    begin
       GetDistance2:=abs(Integer(ITar)-Integer(IThis))+abs(Integer(JTar)-Integer(JThis));
    end;

{ XXX }
begin
 with (_unit^) do begin
   if (ActiveDefence and (MoveStatus <> 8) and
       ((GetDistance(IPos,JPos,ITarget,JTarget) > ActiveDefenceRange) or
        (ADefModeSteps > (ActiveDefenceRange+ActiveDefenceRange shr 1))))
   then begin
    { prekrocen limit pronasledovani u modu aktivni obrany - vrat se
      do puvodni pozice }
       Target:=Nil; BTarget:=Nil;
       if (not Return_to_base) then begin
         if (TargetType = 3) then begin
            if (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) then begin
               Status:=0; Return_to_base:=True;
               ITarget:=IAirport; JTarget:=JAirport; ADefModeSteps:=0;
            end;
            WayPointMax:=0; WayPointUk:=0;
            Set_move_unit(ITarget,JTarget,_unit,1,False,False);
         end else begin
            WayPointMax:=0; WayPointUk:=0;
            Set_move_unit(ITarget,JTarget,_unit,0,False,False);
         end;
         if (IntelliSearching_for_attack_flag > (-40))
         then IntelliSearching_for_attack_flag := -40;
       end;
   end;

   if ((Status = 0) and (not Return_to_base)) then begin
      Pom:=SetAttack(_unit);
      if ((Race <> MyRace) and (Target <> Nil) and (Target^ <> Nil))
      then begin
          if (Target^^.Status = 0) then ActiveDefenceRange:=255
          else
            if ((UnitType < 17) or (UnitType >19)) then ActiveDefenceRange:=12;
       end;
      { prokontroluj vzdalenost od cile (stoji-li jednotka) }
      if (Pom) then begin { jednotka je v dostrelu ! }
         if (MoveStatus = 64) then MoveStatus := 32;
         if (Target <> Nil) then PomTarget:=Target^ else PomTarget:=Nil;
         if (BTarget <> Nil) then PomBTarget:=BTarget^ else PomBTarget:=Nil;
         if (BTarget <> Nil) then begin
         { cilem je budova }
           { zvoleni cile }
           First_attack:=False;
           IP:=PomBTarget^.IPos; JP:=PomBTarget^.JPos;
           IAim:=IP; JAim:=JP;
           ISize:=Building_types[PomBTarget^.BuildingType].IBuildingSize;
           JSize:=Building_types[PomBTarget^.BuildingType].JBuildingSize;
           { nyni se zvoli nejblizsi cast cile }
           Distanc:=65535; Ix:=IP; Jx:=JP;
           for I:=IP to IP+ISize-1 do
             for J:=JP to JP+JSize-1 do
               if (GetDistance2(IPos,JPos,I,J) < Distanc) then begin
                  Distanc:=GetDistance2(IPos,JPos,I,J); Ix:=I; Jx:=J;
               end;

           IAim:=Ix; JAim:=Jx;{}

           Level:=0; { pozemni }
         end else begin
           if (Target <> Nil) then begin { cilem je jednotka }
             { zvoleni cile }
             if ((First_attack) or (ShootFlag = 2)) then begin
                 First_attack:=False;
                 IAim:=PomTarget^.IPos; JAim:=PomTarget^.JPos;
                 IP:=PomTarget^.IPos; JP:=PomTarget^.JPos;
                 ISize:=Unit_types[PomTarget^.UnitType,Races[Race].Ally].IUnitSize;
                 JSize:=Unit_types[PomTarget^.UnitType,Races[Race].Ally].JUnitSize;
                 { pokud se jednotka hybe, je na vice polich }
                 if (PomTarget^.XOffset <> 0) then Inc(ISize);
                 if (PomTarget^.YOffset <> 0) then Inc(JSize);
                 { nyni se nahodne zvoli cast cile }
                 RndNum:=Rand(RandomUk);
                 RndNum2:=Rand(RandomUk);
                 if (MissileMoveAdd >= 16) then Modulo:=2 else Modulo:=3;

                 case (PomTarget^.Status) of
                 { nastavime jisty zasah }
                    1 : begin
                          if (Rand(RandomUk) mod Modulo <> 0) then begin
                             RndNum:=0; RndNum2:=0;
                          end;
                        end;
                    2 : begin 
                          if ((MissileMoveAdd < 16) and
                              (Rand(RandomUk) mod Modulo <> 0)) then begin
                             RndNum:=0; RndNum2:=0;
                          end;
                        end;
                    4 : begin
                          if (Rand(RandomUk) mod Modulo <> 0) then begin
                             RndNum:=1; RndNum2:=0;
                          end;
                        end;
                    8 : begin
                          if ((MissileMoveAdd < 16) and
                              (Rand(RandomUk) mod Modulo <> 0)) then begin
                             RndNum:=1; RndNum2:=0;
                          end;
                        end;
                    16: begin
                          if (Rand(RandomUk) mod Modulo <> 0) then begin
                             RndNum:=1; RndNum2:=1;
                          end;
                        end;
                    32 : begin
                           if ((MissileMoveAdd < 16) and
                               (Rand(RandomUk) mod Modulo <> 0)) then begin
                              RndNum:=0; RndNum2:=1;
                           end;
                         end;
                    64: begin
                          if (Rand(RandomUk) mod Modulo <> 0) then begin
                             RndNum:=0; RndNum2:=1;
                          end;
                        end;
                    128 : begin
                            if ((MissileMoveAdd < 16) and
                                (Rand(RandomUk) mod Modulo <> 0)) then begin
                               RndNum:=0; RndNum2:=0;
                            end;
                          end;
                 end;

                 if (ISize > 1) then RandomNum:=RndNum mod ISize else RandomNum:=0;
                 Inc(IAim,RandomNum);
                 if (JSize > 1) then RandomNum:=RndNum2 mod JSize else RandomNum:=0;
                 Inc(JAim,RandomNum);
             end;
             if (PomTarget^.TargetType = 3)
             then Level:=1 { vzdusna }
             else Level:=0; { pozemni }
             if (not CheckAttackUnit(PomTarget^.TargetType,_unit)) then begin
                if (MoveStatus = 32) then MoveStatus:=64;
                GoTo Skip;
             end;
           end else Error(0,'unita _units, procedura Attack_unit');
           { chyba - obe jednotky jsou Nil}
         end;

         Dir:=Best_direction2(IPos, JPos,IAim,JAim);
         if (Direction <> Dir) then begin
         { jednotka neni natocena smerem k cili - provede natoceni }
            Status:=Dir; First_attack:=True;
            WayPointUk:=0; WayPointMax:=0;
            WayPoint[WayPointUk].IAim:=IPos;
            WayPoint[WayPointUk].JAim:=JPos;
         end else begin
         { !!! OK, MOZNO STRILET !!! }
            WayPointUk:=0; WayPointMax:=0;
            WayPoint[WayPointUk].IAim:=IAim;
            WayPoint[WayPointUk].JAim:=JAim;

            if (ActiveWeapon <> 0) then begin
              if ((IntelliSearching_for_attack_limit-IntelliSearching_for_attack_flag)
                  <= ShootFlag) then
                  IntelliSearching_for_attack_flag :=
                           IntelliSearching_for_attack_limit-ShootFlag-2;
              { AI vylozi na zacatku utoku carrier }
              if ((ShootFlag shr 1 = Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1]) or
                  (ShootFlag shr 1 = Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2])) then
              with (Races[Race]) do
                 if ((TaskGroup <> InvalidTaskGroupNumber) and
                     (TaskGroups^[TaskGroup].Validity))
                 then begin
                   if (UnitsInsideNum <> 0) then begin
                      UnLoad(_unit);
                      if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then Down:=2;
                   end;
                 end;
              { AI vylozi na zacatku utoku carrier - end - }

              if (ShootFlag <> 0) then Dec(ShootFlag)
              else begin
              { skutecna moznost strelby }
                 if ((Races[Race].RaceType = 3) or (Races[Race].RaceType = 6))
                 then begin { roboti - opotrebeni }
                   if (WearOut <= 50) then
                   begin WearOut:=WearOut-WearOutShot6;
                         WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutShot6;
                   end else
                     if (WearOut <= 80) then
                     begin WearOut:=WearOut-WearOutShot5;
                           WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutShot5;
                     end else
                       if (WearOut <= 120) then
                       begin WearOut:=WearOut-WearOutShot4;
                             WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutShot4;
                       end else
                         if (WearOut <= 150) then
                         begin WearOut:=WearOut-WearOutShot3;
                               WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutShot3;
                         end else
                          if(WearOut <= 170) then
                          begin WearOut:=WearOut-WearOutShot2;
                                WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutShot2;
                          end else begin
                              WearOut:=WearOut-WearOutShot1;
                              WearOutLimitDecreaseFlag:=WearOutLimitDecreaseFlag+WearOutShot1;
                          end;
                    Change_unit_wear_out(_unit);
                 end;

                 { jde-li o carrier, zkus naklad vylozit }
                  with (Races[Race]) do
                  if ((TaskGroup <> InvalidTaskGroupNumber) and
                      (TaskGroups^[TaskGroup].Validity))
                  then begin
                    if (UnitsInsideNum <> 0) then begin
                       UnLoad(_unit);
                       if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then Down:=2;
                    end;
                    { nastaveni cile utoku }
                    SetAttackTGInfo(Race,TaskGroup,Level,IAim,JAim);
                    TaskGroups^[TaskGroup].NoAttackTimming:=0;
                  end;

                 if (ActiveWeapon = 1) then  begin
                 { **** STRELBA ZBRANI 1 **** }
                    Inc(ShootTypeFlag1);
                    if (ShootTypeFlag1 = Unit_types[UnitType,Races[Race].Ally].ShootType1) then begin
                       ShootDelayFlag1:=Unit_types[UnitType,Races[Race].Ally].ShootDelay1;
                       ShootTypeFlag1:=0;
                    end;
                    First_attack:=True;
                    ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed1];
                    if (GameTimming = 1) then begin
                      ShootFlag:=ShootFlag shl 1;
                      Inc(ShootFlag, ShootDelayFlag1);
                    end else
                      Inc(ShootFlag, ShootDelayFlag1 shr 1);

                    New_shot(IPos,JPos,IAim,JAim,Direction,Level,1,UnitType,
                             _unit,Target,BTarget);
                    IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
                 end else begin
                 { *** STRELBA ZBRANI 2 *** }
                    if (ShootTypeFlag2 = Unit_types[UnitType,Races[Race].Ally].ShootType2) then begin
                       ShootDelayFlag2:=Unit_types[UnitType,Races[Race].Ally].ShootDelay2;
                       ShootTypeFlag2:=0;
                    end;
                    First_attack:=True;
                    ShootFlag:=Kadence[Unit_types[UnitType,Races[Race].Ally].ShootSpeed2];
                    if (GameTimming = 1) then begin
                      ShootFlag:=ShootFlag shl 1;
                      Inc(ShootFlag, ShootDelayFlag2);
                    end else
                      Inc(ShootFlag, ShootDelayFlag2 shr 1);
                    New_shot(IPos,JPos,IAim,JAim,Direction,Level,2,UnitType,
                             _unit,Target,BTarget);
                    { pozn. zbran2 je vzdy pechotni }
                    IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_limit+1;
                 end; { STRELBA ZBRANI 2 }

                 if ((_unit <> Nil) and
                 { autodetonator je v teto chvili odalokovan }
                     (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                     (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0)) then begin
                 { spec. letecke jednotky se po prvnim utoku vraci zpet na
                   zakladnu }
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
                     Set_move_unit(WayPoint[WayPointUk].IAim,WayPoint[WayPointUk].JAim,_unit,1,False,False);
                 end;
              end; { ShootFlag = 0 }

            end; { if (ActiveWeapon <> 0) then begin }
         end; { !!! OK, MOZNO STRILET !!! }
      end else begin
         if (MoveStatus = 32) then MoveStatus := 64;
         { utocne se pohybujeme, nechame tedy flag "stagnovat"}
         {IntelliSearching_for_attack_flag:=IntelliSearching_for_attack_flag-1;{}
      end;
   end else begin { XXXXXXXXXX  if (Status = 0) then ... else ... XXXXXXXXXX }
      { jednotka se pohybuje; prodleva mezi vystrely se bude odecitat,
        jen kdyz se pohybuje i cil }
      {if (Pom) then begin { jednotka je v dostrelu ! }
         Moving:=False;
         if (Race <> MyRace) then
           if ((UnitType < 17) or (UnitType >19)) then ActiveDefenceRange:=19;
         if (Target <> Nil) then PomTarget:=Target^ else PomTarget:=Nil;
         if (BTarget <> Nil) then PomBTarget:=BTarget^ else PomBTarget:=Nil;
         if (BTarget <> Nil) then begin
         { cilem je budova }
           Moving:=False;
         end else begin
           if ((Target <> Nil) and (Target^ <> Nil)) then begin
           { cilem je jednotka }
             { zvoleni cile }
             if (CheckAttackUnit(PomTarget^.TargetType,_unit) and
                 (PomTarget^.Status > 0) and (PomTarget^.Status <= 129))
             then begin { cil se hybe, sniz hranici ActiveDefenceRange }
                Moving:=True;
                if (Race <> MyRace) then
                  if ((UnitType < 17) or (UnitType > 19)) then ActiveDefenceRange:=10;
             end;
           end;
         end;
         { !!! OK, MOZNO STRILET !!! }
         if (Moving) then begin
            if (ActiveWeapon <> 0) then begin
              if (ShootFlag <> 0) then Dec(ShootFlag);
            end; { if (ActiveWeapon <> 0) then begin }
         end; { if (Moving) then ... !!! OK, MOZNO STRILET !!! }
   end;
 end; { with (_unit^) do begin }
Skip:
end;

{ ***** }
function Check_place_surroundings(var IPos,JPos : Word; ISize,JSize:Word;
                                  Building:Boolean; ElementType,Race:Byte):Boolean;
{ zkontroluje, zda se v okoli pole IPos, JPos o velikosti ISize, JSize
  nachazi budova (Building = True) nebo jednotka (Building = False)
  typu ElementType a rasy Race; vraci souradnici PRVNIHO nalezeneho objektu;
  Sama funkce pak vraci uspesnost hledani
  PRACUJE POUZE S PRVNI (POZEMNI) UROVNI
}
var FreePlaces:TFreePlaces;
    MaxIndex:Word;
    I, J : Word;
    Proceed:Boolean;
begin
   Get_free_places(FreePlaces,MaxIndex,IPos,JPos,ISize,JSize);
   I:=1; Proceed:=True;
   if (Building) then begin
   { budovy }
      while ((I <= MaxIndex) and (Proceed)) do with (FreePlaces[I]) do
      if (Free) then with (Map^[IP,JP]) do begin
        if ((First_level <> 0) and
            (Level_type and 128 = 128) and
            (Buildings[First_level]^.Race = Race) and
            (Buildings[First_level]^.BuildingType = ElementType)) then
           Proceed:=False
        else Inc(I);
      end else Inc(I);
      if (not Proceed) then begin
         Check_place_surroundings:=True;
         IPos:=FreePlaces[I].IP; JPos:=FreePlaces[I].JP;
      end else Check_place_surroundings:=False;
   end else begin
   { jednotky na 1. urovni }
      while ((I <= MaxIndex) and (Proceed)) do with (FreePlaces[I]) do
      if (Free) then with (Map^[IP,JP]) do begin
        if ((First_level <> 0) and
            (Level_type and 128 = 0) and
            (Units[First_level]^.Race = Race) and
            (Units[First_level]^.UnitType = ElementType)) then
           Proceed:=False
        else Inc(I);
      end else Inc(I);
      if (not Proceed) then begin
         Check_place_surroundings:=True;
         IPos:=FreePlaces[I].IP; JPos:=FreePlaces[I].JP;
      end else Check_place_surroundings:=False;
   end;
end;

{ ***** }
function Check_place_surroundings_free(var IPos,JPos : Word; ISize,JSize:Word;
                                       UnitType:Byte):Byte;
{ zkontroluje, zda se v okoli pole IPos, JPos o velikosti ISize, JSize
  jednotky typu UnitType nachazi volne misto.
  Sama funkce vraci pocet volnych mist v okoli
}
var FreePlaces:TFreePlaces;
    MaxIndex:Word;
    I, J : Word;
begin
   Get_free_places(FreePlaces,MaxIndex,IPos,JPos,ISize,JSize);
   I:=1;
   J:=0; { pocet volnych mist v okoli }
   while (I <= MaxIndex) do with (FreePlaces[I]) do begin
     if (Free) then begin
        if (Free_place_two(IP,JP,ISize,JSize,UnitType)) then Inc(J);
     end;
     Inc(I);
   end;
   Check_place_surroundings_free:=J;
end;

{ ***** }
function CheckAttack(TargetTyp:Word; Race:Byte) : Boolean;
{ procedura zkontroluje, zda jednotky ve skupine ActiveGroup mohou
  (alespon jedna) utocit na cil s atributem TargetTyp
}
var K, I : Word;
    Pom, HardPom : Boolean;
begin
   Pom:=False; K:=0; HardPom:=True;
   if (Race = MyRace) then begin
     while (K < MaxGroupUnits) do with (Groups[ActiveGroup]) do begin
       if ((Un[K] <> Nil) and
           (not Un[K]^.Return_to_base)) then
       with (Un[K]^) do begin
          case (TargetTyp) of
            0 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].LightAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].LightAttack2 <> 0);
            1 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].LightAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].LightAttack2 <> 0);
            2 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].HeavyAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].HeavyAttack2 <> 0);
            3 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].AirAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].AirAttack2 <> 0);
            4 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].HeavyAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].HeavyAttack2 <> 0);
          end;
       end else { if }
          if ((Un[K] <> Nil) and (Un[K]^.Return_to_base))
          then HardPom:=False; { if }
       Inc(K);
     end; { while }
   end else begin
     CheckAttack:=False;
   end; { if }
   CheckAttack:=Pom and HardPom;
end;

{ ***** }
function CheckAttackUnit(TargetTyp:Word; _unit:PUnit) : Boolean;
{ procedura zkontroluje, zda jednotka _unit muze utocit na cil
  s atributem TargetTyp
}
var K, I : Word;
    Pom : Boolean;
begin
   Pom:=False;
   if ((_unit <> Nil) and (not _unit^.Return_to_base)) then
     with (_unit^) do begin
          case (TargetTyp) of
            0 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].LightAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].LightAttack2 <> 0);
            1 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].LightAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].LightAttack2 <> 0);
            2 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].HeavyAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].HeavyAttack2 <> 0);
            3 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].AirAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].AirAttack2 <> 0);
            4 : Pom:=Pom or (Unit_types[UnitType,Races[Race].Ally].HeavyAttack1 <> 0) or
                     (Unit_types[UnitType,Races[Race].Ally].HeavyAttack2 <> 0);
          end;
       end; { if }
   CheckAttackUnit:=Pom;
end;

{ ***** }
procedure Set_place(I, J :Word; _unit:PUnit; Sets, SetMapInfo:Boolean);
{ jednotka je urcena ukazatelem _unit;
  procedura nastavi u policka I,J priznak obsazenosti dle promenne Sets
  (True = obsazeno)
  SetMapInfo = True, ma-li se jednotka prepsat v poli MapInfo !
}
var K, L, I2, J2, IP, JP: Word;
    Color, PomDangerClass : Byte;
    Pom, MouseObstacle : Boolean;
    IModif, JModif:Integer;
    XMouse, YMouse : Word;
begin
   RdrawRadarFrame:=False;
   with _unit^ do with (Map^[I,J]) do with (MapBck^[I,J]) do
   with (MapBckTemp^[I,J]) do begin
     if (DangerClass <= 2) then PomDangerClass:=0 else
      if (DangerClass <= 5) then PomDangerClass:=1 else
       if (DangerClass <= 7) then PomDangerClass:=2 else
        if (DangerClass = 255) then PomDangerClass:=255;

     K:=I+XRadarRealBeg; L:=J+YRadarRealBeg;
     MouseObstacle:=TestMouse(XRadarRealBeg,YRadarRealBeg,XRadarRealEnd,YRadarRealEnd);

     if (TargetType <> 3) then begin { jiny nez vzdusny cil }
        if (Sets) then begin { jednotka se nastavi }
           First_level:=Index;

           if (Visibilit and Races[MyRace].VisMask  = 0) then begin
             if (Visibility) then Eras:=True;{else Eras:=False;{}
             if (Visibility) then
                if (not VisibilityChange) then
                   VisibilityChange:=True
                else VisibilityChange:=False;
             Visibility:=False;
           end else begin
              if (not Visibility) then
                if (not VisibilityChange) then
                   VisibilityChange:=True
                else VisibilityChange:=False;
              Visibility:=True;
           end;

           if (EnemyVisibilit = 0) then begin
             if (EnemyVisibility) then
                if (not EnemyVisibilityChange) then
                   EnemyVisibilityChange:=True
                else EnemyVisibilityChange:=False;
             EnemyVisibility:=False;
           end else begin
             if (not EnemyVisibility) then
                if (not EnemyVisibilityChange) then
                   EnemyVisibilityChange:=True
                else EnemyVisibilityChange:=False;
             EnemyVisibility:=True;
           end;

           Level_type:=Level_type and 127;
           if (Visibility) then begin
           { vykresli jednotku na mape }
              {*** obsluha radaru ***}
              if (MouseObstacle) then CursorOff;
              if (SetMapInfo) then begin{}
                DrawRadarPixel(I,J); DrawRadarPixel(I+1,J);
                DrawRadarPixel(I,J+1); DrawRadarPixel(I+1,J+1);
              end;{}
              if (RdrawRadarFrame) then
                SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                         YRadarRealBeg+JScreenSize+JBeg-1,65);
              if (MouseObstacle) then CursorOn;
              RdrawRadarFrame:=False;
              {*** obsluha radaru ***}
           end;

           { nastaveni informaci do pole MapInfo - pro AI }
           IP:=IPos div IInfoDiv; JP:=JPos div JInfoDiv;
           if (SetMapInfo) then
           with (MapInfo^[IP,JP]) do begin
           { jedna se o levy horni roh jednotky }
              case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
                0 : begin
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                       { jde o pro mne nepratelskou jednotku }
                         if ((Visibility) or (not Fog_of_war)) then  begin
                           if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                              if (VisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].HLLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].VLLight[PomDangerClass]);
                           end;
                           if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(VLLight[PomDangerClass]);
                         end else begin
                           if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                              if (VisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].VLLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].HLLight[PomDangerClass]);
                           end;
                           if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(HLLight[PomDangerClass]);
                         end;
                       end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                       { jde o mne nebo o spojence }
                         if ((EnemyVisibility) or (not Fog_of_war)) then begin
                            if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                            then begin
                              if (EnemyVisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHLLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVLLight[PomDangerClass]);
                            end;
                            if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(EnemyVLLight[PomDangerClass])
                         end else begin
                           if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                           then begin
                              if (EnemyVisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVLLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHLLight[PomDangerClass]);
                           end;
                           if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                             Inc(EnemyHLLight[PomDangerClass]);
                         end;
                       end;
                    end;
                1 : begin
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                       { jde o pro mne nepratelskou jednotku }
                          if ((Visibility) or (not Fog_of_war)) then  begin
                           if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                              if (VisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].HLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].VLight[PomDangerClass]);
                           end;
                           if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(VLight[PomDangerClass]);
                         end else begin
                           if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                              if (VisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].VLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].HLight[PomDangerClass]);
                           end;
                           if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(HLight[PomDangerClass]);
                         end;
                       end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral))then begin
                       { jde o mne nebo o spojence }
                         if ((EnemyVisibility) or (not Fog_of_war)) then begin
                           if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                           then begin
                              if (EnemyVisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVLight[PomDangerClass]);
                           end;
                           if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(EnemyVLight[PomDangerClass])
                         end else begin
                           if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                           then begin
                              if (EnemyVisibilityChange) then
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVLight[PomDangerClass])
                              else
                                Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHLight[PomDangerClass]);
                           end;
                           if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                             Inc(EnemyHLight[PomDangerClass]);
                         end;
                       end;
                    end;
                2 : begin
                       if (PomDangerClass = 255) then begin
                          if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                          { jde o pro mne nepratelskou jednotku }
                            if ((Visibility) or (not Fog_of_war)) then  begin
                              if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                                if (VisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].HSpecial)
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].VSpecial);
                               end;
                              if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                 Inc(VSpecial);
                            end else begin
                              if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                                if (VisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].VSpecial)
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].HSpecial);
                               end;
                              if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                 Inc(HSpecial);
                            end;
                          end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                          { jde o mne nebo o spojence }
                            if ((EnemyVisibility) or (not Fog_of_war)) then begin
                              if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                              then begin
                                if (EnemyVisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHSpecial)
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVSpecial);
                               end;
                              if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(EnemyVSpecial);
                            end else begin
                              if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                              then begin
                                if (EnemyVisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVSpecial)
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHSpecial);
                               end;
                              if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(EnemyHSpecial);
                            end;
                          end;
                       end else
                         if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                         { jde o pro mne nepratelskou jednotku }
                           if ((Visibility) or (not Fog_of_war)) then  begin
                             if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                                if (VisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].HHeavy[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].VHeavy[PomDangerClass]);
                               end;
                             if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(VHeavy[PomDangerClass]);
                           end else begin
                             if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                                if (VisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].VHeavy[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].HHeavy[PomDangerClass]);
                             end;
                             if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(HHeavy[PomDangerClass]);
                           end;
                         end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                         { jde o mne nebo o spojence }
                           if ((EnemyVisibility) or (not Fog_of_war)) then begin
                              if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                              then begin
                                if (EnemyVisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHHeavy[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVHeavy[PomDangerClass]);
                             end;
                              if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(EnemyVHeavy[PomDangerClass]);
                           end else begin
                              if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                              then begin
                                if (EnemyVisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVHeavy[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHHeavy[PomDangerClass]);
                              end;
                              if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                 Inc(EnemyHHeavy[PomDangerClass]);
                           end;
                         end;
                    end;
                3 : begin { zde se obslouzi napr. stihac na zemi }
                       if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                       { jde o pro mne nepratelskou jednotku }
                          if ((Visibility) or (not Fog_of_war)) then  begin
                             if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                                if (VisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].HAir[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].VAir[PomDangerClass]);
                             end;
                             if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(VAir[PomDangerClass]);
                           end else begin
                             if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                                if (VisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].VAir[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].HAir[PomDangerClass]);
                             end;
                             if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                                Inc(HAir[PomDangerClass]);
                           end;
                       end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                       { jde o mne nebo o spojence }
                         if ((EnemyVisibility) or (not Fog_of_war)) then begin
                            if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                            then begin
                                if (EnemyVisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAir[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAir[PomDangerClass]);
                            end;
                            if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(EnemyVAir[PomDangerClass]);
                         end else begin
                            if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos)))
                            then begin
                                if (EnemyVisibilityChange) then
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAir[PomDangerClass])
                                else
                                  Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAir[PomDangerClass]);
                             end;
                            if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                              Inc(EnemyHAir[PomDangerClass]);
                         end;
                       end;
                    end;

              end;
              { zarazeni do tridy PVO schopnosti }
              if (ADangerClass <> 255) then
              { existuji PVO schopnosti }
                 if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral))then begin
                 { jde o pro mne nepratelskou jednotku }
                    if ((Visibility) or (not Fog_of_war)) then  begin
                      if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                        if (VisibilityChange) then
                          Dec(MapInfo^[IInfoPos,JInfoPos].HAAttack[ADangerClass])
                        else
                          Dec(MapInfo^[IInfoPos,JInfoPos].VAAttack[ADangerClass]);
                      end;
                      if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                         Inc(VAAttack[ADangerClass]);
                    end else begin
                      if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                        if (VisibilityChange) then
                          Dec(MapInfo^[IInfoPos,JInfoPos].VAAttack[ADangerClass])
                        else
                          Dec(MapInfo^[IInfoPos,JInfoPos].HAAttack[ADangerClass]);
                      end;
                      if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                         Inc(HAAttack[ADangerClass]);
                    end;
                 end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                 { jde o mne nebo o spojence }
                   if ((EnemyVisibility) or (not Fog_of_war)) then begin
                     if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                        if (EnemyVisibilityChange) then
                          Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAAttack[ADangerClass])
                        else
                          Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAAttack[ADangerClass]);
                      end;
                     if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                        Inc(EnemyVAAttack[ADangerClass])
                   end else begin
                      if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                        if (EnemyVisibilityChange) then
                          Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAAttack[ADangerClass])
                        else
                          Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAAttack[ADangerClass]);
                      end;
                     if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                        Inc(EnemyHAAttack[ADangerClass]);
                   end;
                 end;

              { nyni zvys celkovy pocet jednotek }
              if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                if ((Visibility) or (not Fog_of_war)) then begin
                  if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (VisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].HTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].VTotall);
                  end;
                  if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(VTotall);
                end else begin
                  if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (VisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].VTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].HTotall);
                  end;
                  if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(HTotall);
                end;
              end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
              { jde o mne nebo o spojence }
                if ((EnemyVisibility) or (not Fog_of_war)) then begin
                  if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (EnemyVisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVTotall);
                  end;
                  if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(EnemyVTotall);
                end else begin
                  if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (EnemyVisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHTotall);
                  end;
                  if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(EnemyHTotall);
                end;
              end;
              IInfoPos:=IP; JInfoPos:=JP;
           end; { if ((I = IPos) and (J = JPos) and .. ) then begin }

        end else begin
          First_level:=0;
          if (Visibility) then begin
             {*** obsluha radaru ***}
              if (MouseObstacle) then CursorOff;
              {if (SetMapInfo) then begin{}
                DrawRadarPixel(I,J); DrawRadarPixel(I+1,J);
                DrawRadarPixel(I,J+1); DrawRadarPixel(I+1,J+1);
              {end;{}
              if (RdrawRadarFrame) then
                SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                         YRadarRealBeg+JScreenSize+JBeg-1,65);
              if (MouseObstacle) then CursorOn;
              RdrawRadarFrame:=False;
              {*** obsluha radaru ***}
          end; { if ( Visibility) then }
          { vyjmuti informaci z pole MapInfo - pro AI }
          IP:=IInfoPos; JP:=JInfoPos;
          if (SetMapInfo and (not Activity)) then
          with (MapInfo^[IP,JP]) do begin
          { jedna se o levy horni roh jednotky }
             case (Unit_types[UnitType,Races[Race].Ally].TargetTyp) of
               0 : begin
                      if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                      { jde o pro mne nepratelskou jednotku }
                        if ((Visibility) or (not Fog_of_war)) then
                           Dec(VLLight[PomDangerClass])
                        else Dec(HLLight[PomDangerClass])
                      else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                      { jde o mne nebo o spojence }
                        if ((EnemyVisibility) or (not Fog_of_war)) then
                           Dec(EnemyVLLight[PomDangerClass])
                        else Dec(EnemyHLLight[PomDangerClass]);
                      end;
                   end;
               1 : begin
                      if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                      { jde o pro mne nepratelskou jednotku }
                        if ((Visibility) or (not Fog_of_war)) then
                           Dec(VLight[PomDangerClass])
                        else Dec(HLight[PomDangerClass])
                      else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                      { jde o mne nebo o spojence }
                        if ((EnemyVisibility) or (not Fog_of_war)) then
                           Dec(EnemyVLight[PomDangerClass])
                        else Dec(EnemyHLight[PomDangerClass]);
                      end;
                   end;
               2 : begin
                      if (PomDangerClass = 255) then begin
                          if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                          { jde o pro mne nepratelskou jednotku }
                            if ((Visibility) or (not Fog_of_war)) then
                              Dec(VSpecial)
                            else Dec(HSpecial)
                          else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                          { jde o mne nebo o spojence }
                            if ((EnemyVisibility) or (not Fog_of_war)) then
                               Dec(EnemyVSpecial)
                            else Dec(EnemyHSpecial);
                          end;
                       end else
                         if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                         { jde o pro mne nepratelskou jednotku }
                           if ((Visibility) or (not Fog_of_war)) then
                              Dec(VHeavy[PomDangerClass])
                           else Dec(HHeavy[PomDangerClass])
                         else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                         { jde o mne nebo o spojence }
                           if ((EnemyVisibility) or (not Fog_of_war)) then
                             Dec(EnemyVHeavy[PomDangerClass])
                           else Dec(EnemyHHeavy[PomDangerClass])
                         end;
                   end;
               3 : begin
                      if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
                      { jde o pro mne nepratelskou jednotku }
                         if ((Visibility) or (not Fog_of_war)) then
                           Dec(VAir[PomDangerClass])
                         else Dec(HAir[PomDangerClass])
                      else if ((Races[Race].Friend[MyRace] = 2)  and (not Races[Race].Neutral)) then begin
                      { jde o mne nebo o spojence }
                         if ((EnemyVisibility) or (not Fog_of_war)) then
                           Dec(EnemyVAir[PomDangerClass])
                         else Dec(EnemyHAir[PomDangerClass])
                      end;
                   end;
             end;
             { vyjmuti z tridy PVO  }
             if (ADangerClass <> 255) then
             { existuji PVO schopnosti }
               if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral))then
               { jde o pro mne nepratelskou jednotku }
                  if ((Visibility) or (not Fog_of_war)) then
                    Dec(VAAttack[ADangerClass])
                  else Dec(HAAttack[ADangerClass])
               else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
               { jde o mne nebo o spojence }
                  if ((EnemyVisibility) or (not Fog_of_war)) then
                     Dec(EnemyVAAttack[ADangerClass])
                  else Dec(EnemyHAAttack[ADangerClass]);
               end;

             { nyni sniz celkovy pocet jednotek }
             if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
               if ((Visibility) or (not Fog_of_war)) then
                  Dec(VTotall)
               else Dec(HTotall)
             else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
             { jde o mne nebo o spojence }
               if ((EnemyVisibility) or (not Fog_of_war)) then
                  Dec(EnemyVTotall)
               else Dec(EnemyHTotall);
             end;
          end; { if ((I = IPos) and (J = JPos)) then begin }
        end;

     end else begin { vzdusny cil }
        if (Sets) then begin
           if (Visibilit and Races[MyRace].VisMask  = 0) then begin
             if (Visibility) then Eras:=True;{ else Eras:=False;{}
             if (Visibility) then
                if (not VisibilityChange) then
                   VisibilityChange:=True
                else VisibilityChange:=False;
             Visibility:=False;
           end else begin
              if (not Visibility) then
                 if (not VisibilityChange) then
                   VisibilityChange:=True
                 else VisibilityChange:=False;
              Visibility:=True;
           end;

           if (EnemyVisibilit = 0) then begin
             if (EnemyVisibility) then
                if (not EnemyVisibilityChange) then
                  EnemyVisibilityChange:=True
                else EnemyVisibilityChange:=False;
             EnemyVisibility:=False;
           end else begin
             if (not EnemyVisibility) then
                if (not EnemyVisibilityChange) then
                  EnemyVisibilityChange:=True
                else EnemyVisibilityChange:=False;
             EnemyVisibility:=True;
           end;

           Second_level:=Index;
           if (Visibility) then begin
              {*** obsluha radaru ***}
              if (MouseObstacle) then CursorOff;
              if (SetMapInfo) then begin{}
                DrawRadarPixel(I,J); DrawRadarPixel(I+1,J);
                DrawRadarPixel(I,J+1); DrawRadarPixel(I+1,J+1);
              end;{}
              if (RdrawRadarFrame) then
                SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                         YRadarRealBeg+JScreenSize+JBeg-1,65);
              if (MouseObstacle) then CursorOn;
              RdrawRadarFrame:=False;
              {*** obsluha radaru ***}
           end;
           { nastaveni informaci do pole MapInfo - pro AI }
           IP:=IPos div IInfoDiv; JP:=JPos div JInfoDiv;
           if (SetMapInfo) then
           with (MapInfo^[IP,JP]) do begin
           { jedna se o levy horni roh jednotky }
              if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
              { jde o pro mne nepratelskou jednotku }
                if ((Visibility) or (not Fog_of_war)) then begin
                  if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                      if (VisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].HAir[PomDangerClass])
                      else
                        Dec(MapInfo^[IInfoPos,JInfoPos].VAir[PomDangerClass]);
                  end;
                  if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                    Inc(VAir[PomDangerClass]);
                end else begin
                  if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                      if (VisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].VAir[PomDangerClass])
                      else
                        Dec(MapInfo^[IInfoPos,JInfoPos].HAir[PomDangerClass]);
                  end;
                  if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                    Inc(HAir[PomDangerClass]);
                end;
              end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
              { jde o mne nebo o spojence }
                if ((EnemyVisibility) or (not Fog_of_war)) then begin
                  if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                      if (EnemyVisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAir[PomDangerClass])
                      else
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAir[PomDangerClass]);
                  end;
                  if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                    Inc(EnemyVAir[PomDangerClass]);
                end else begin
                  if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                      if (EnemyVisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAir[PomDangerClass])
                      else
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAir[PomDangerClass]);
                  end;
                  if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                    Inc(EnemyHAir[PomDangerClass]);
                end;
              end;
              { zarazeni do tridy PVO schopnosti }
              if (ADangerClass <> 255) then
              { existuji PVO schopnosti }
                 if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                 { jde o pro mne nepratelskou jednotku }
                    if ((Visibility) or (not Fog_of_war)) then begin
                      if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                         if (VisibilityChange) then
                            Dec(MapInfo^[IInfoPos,JInfoPos].HAAttack[ADangerClass])
                         else
                            Dec(MapInfo^[IInfoPos,JInfoPos].VAAttack[ADangerClass]);
                      end;
                      if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                        Inc(VAAttack[ADangerClass]);
                    end else begin
                      if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                         if (VisibilityChange) then
                            Dec(MapInfo^[IInfoPos,JInfoPos].VAAttack[ADangerClass])
                         else
                            Dec(MapInfo^[IInfoPos,JInfoPos].HAAttack[ADangerClass]);
                      end;
                      if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                        Inc(HAAttack[ADangerClass]);
                    end;
                 end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
                 { jde o mne nebo o spojence }
                   if ((EnemyVisibility) or (not Fog_of_war)) then begin
                     if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                         if (EnemyVisibilityChange) then
                            Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAAttack[ADangerClass])
                         else
                            Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAAttack[ADangerClass]);
                     end;
                     if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                       Inc(EnemyVAAttack[ADangerClass]);
                   end else begin
                     if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                       if (EnemyVisibilityChange) then
                          Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVAAttack[ADangerClass])
                       else
                          Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHAAttack[ADangerClass]);
                     end;
                     if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                       Inc(EnemyHAAttack[ADangerClass]);
                   end;
                 end;

              { nyni sniz celkovy pocet jednotek }
              if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then begin
                if ((Visibility) or (not Fog_of_war)) then begin
                   if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (VisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].HTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].VTotall);
                   end;
                   if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(VTotall);
                end else begin
                  if ((IInfoPos <> 255) and (VisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (VisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].VTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].HTotall);
                  end;
                  if (VisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(HTotall);
                end;
              end else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
              { jde o mne nebo o spojence }
                if ((EnemyVisibility) or (not Fog_of_war)) then begin
                   if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (EnemyVisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVTotall);
                   end;
                   if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(EnemyVTotall);
                end else begin
                  if ((IInfoPos <> 255) and (EnemyVisibilityChange or (IP <> IInfoPos) or (JP <> JInfoPos))) then begin
                     if (EnemyVisibilityChange) then
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyVTotall)
                     else
                        Dec(MapInfo^[IInfoPos,JInfoPos].EnemyHTotall);
                  end;
                  if (EnemyVisibilityChange or (IInfoPos = 255) or (IP <> IInfoPos) or (JP <> JInfoPos)) then
                     Inc(EnemyHTotall);
                end;
              end;

              IInfoPos:=IP; JInfoPos:=JP;
           end; { if ((I = IPos) and (J = JPos)) then begin }

        end else begin { jednotka se smaze }
          Second_level:=0;
          if (Visibility) then begin
          { smaz jednotku na mape }
              {*** obsluha radaru ***}
              if (MouseObstacle) then CursorOff;
              {if (SetMapInfo) then begin{}
                DrawRadarPixel(I,J); DrawRadarPixel(I+1,J);
                DrawRadarPixel(I,J+1); DrawRadarPixel(I+1,J+1);
              {end;{}
              if (RdrawRadarFrame) then
                SetFrame(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IScreenSize+IBeg-1,
                         YRadarRealBeg+JScreenSize+JBeg-1,65);
              if (MouseObstacle) then CursorOn;
              RdrawRadarFrame:=False;
              {*** obsluha radaru ***}
          end; { if (Visibility) then }

          { vyjmuti informaci z pole MapInfo - pro AI }
          IP:=IInfoPos; JP:=JInfoPos;
          if (SetMapInfo and (not Activity)) then
          with (MapInfo^[IP,JP]) do begin
          { jedna se o levy horni roh jednotky }
            if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
            { jde o pro mne nepratelskou jednotku }
              if ((Visibility) or (not Fog_of_war)) then
                Dec(VAir[PomDangerClass])
              else Dec(HAir[PomDangerClass])
            else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
            { jde o mne nebo o spojence }
              if ((EnemyVisibility) or (not Fog_of_war)) then
                Dec(EnemyVAir[PomDangerClass])
              else Dec(EnemyHAir[PomDangerClass]);
            end;
            { vyjmuti z tridy PVO  }
            if (ADangerClass <> 255) then
            { existuji PVO schopnosti }
              if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
              { jde o pro mne nepratelskou jednotku }
                 if ((Visibility) or (not Fog_of_war)) then
                   Dec(VAAttack[ADangerClass])
                 else Dec(HAAttack[ADangerClass])
              else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
              { jde o mne nebo o spojence }
                 if ((EnemyVisibility) or (not Fog_of_war)) then
                   Dec(EnemyVAAttack[ADangerClass])
                 else Dec(EnemyHAAttack[ADangerClass]);
              end;

            { nyni sniz celkovy pocet jednotek }
            if ((Races[Race].Friend[MyRace] = 0) and (not Races[Race].Neutral)) then
              if ((Visibility) or (not Fog_of_war)) then
                 Dec(VTotall)
              else Dec(HTotall)
            else if ((Races[Race].Friend[MyRace] = 2) and (not Races[Race].Neutral)) then begin
            { jde o mne nebo o spojence }
              if ((EnemyVisibility) or (not Fog_of_war)) then
                 Dec(EnemyVTotall)
              else Dec(EnemyHTotall);
            end;
          end; { if ((I = IPos) and (J = JPos)) then begin }
        end;
     end;

     if (SetMapInfo) then VisibilityChange:=False;
     if (SetMapInfo) then EnemyVisibilityChange:=False;
   end; { with (_unit^) }
end;

{ ***** }
procedure _units2_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'8'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _units2_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'8'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************* }
begin
end.