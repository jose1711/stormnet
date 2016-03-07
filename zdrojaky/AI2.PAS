unit AI2;
{$C FIXED PRELOAD PERMANENT}
{ jednotka pro obsluhu umele inteligence }
interface
uses Data;

procedure TG_Reinfo_Execute(Race:Byte);
procedure UnitParamsInit;
procedure Globa_eval;
procedure SetAttackFlagForPlaceForBuilding(Race:Byte; IP,JP:Word);
function NotEnoughFreePlaces(Race:Byte; Request:Byte):Boolean;
function TGEmptyCarriers(Race,TGNum:Byte):Byte;
function TGCarriers(Race,TGNum:Byte):Byte;
procedure AI2_save;
procedure AI2_load;

{ ********** }
implementation

uses _units2, _races, AI, AI3;
const L=0; T=1; L_T=2; U=3; N=4; AA=5; Turret=6;

{ ***** }
procedure UnitParamsInit;
{ inicializuje pole UnitParams
}
const MaxClass = 20;
     BPdiv=100/MaxClass; PLdiv=25/MaxClass;
     EEdiv=100/MaxClass; EXdiv=10/MaxClass;
     { jsou to delitele jednotlivych materialu tak, aby se materialova
       narocnost vesla do kategorii 1 - 20; je to odvozeno od maximalni
       ceny }
var I,J:Word;
    BPom,PPom,EPom,XPom : Single;
    OutFile:File;
    Ret:String;
begin
  { RADEK NIZE ODREMOVAT ! }
 { Assign(OutFile,'param.dat');
  ReWrite(OutFile,1);
  Ret:='Cislo-nazev         L    T    A    defen range  All  BP PL EE EX Mat.Typ';
  BlockWrite(OutFile,Ret[1],Length(Ret));
  Ret[1]:=Chr($0D); Ret[2]:=Chr($0A);
  BlockWrite(OutFile,Ret[1],2); {}
  for I:=1 to MaxTypesOfUnits do
  with (Unit_types[I,0]) do with (UnitParams[I]) do begin
    LAttack:=Round(LightAttack1*GetKadence(0,ShootSpeed1,I)/5);
    TAttack:=Round(HeavyAttack1*GetKadence(0,ShootSpeed1,I)/5);
    AAttack:=Round(AirAttack1*GetKadence(0,ShootSpeed1,I)/5);
    Defence:=3*DefenceStrength div 15;
    if (I = 29)
    then begin { trosku navysime mutanta }
       LAttack:=Round(2*LAttack); TAttack:=LAttack;
       Defence:=Round(2.0*Defence);
    end;
    if (TargetTyp = 3) then begin
      Defence:=Defence shl 1; { navysim letecke jednotky }
      AirUnit:=True;
    end else AirUnit:=False;
    Range:=Hi(ShootRange1){-Lo(ShootRange2)){}*10;
    {x}
    BPom:=BP; PPom:=PL; EPom:=EE; XPom:=Ex;
    B:=Round(BPom/BPdiv); if (B > MaxClass) then B:=MaxClass;
    P:=Round(PPom/PLdiv); if (P > MaxClass) then P:=MaxClass;
    E:=Round(EPom/EEdiv); if (E > MaxClass) then E:=MaxClass;
    X:=Round(XPom/Exdiv); if (X > MaxClass) then X:=MaxClass;
    {x}
    if ((BPom*2 + PPom*5 + EPom + Ex*20)/150 > 3) then MatClass:=4
    else MatClass:=Round((BPom*2 + PPom*5 + EPom + Ex*20)/150);
    {x}
    if (LAttack > (TAttack+TAttack div 2)) then Capability:=L
    else
      if (TAttack > (LAttack+LAttack div 2)) then Capability:=T
      else if (LAttack > 0) then Capability:=L_T else Capability:=N;
    if (AAttack <> 0) then Capability2:=U
    else Capability2:=Capability;

    if (Unit_types[I,0].UnitLevel = 255) then begin
      Capability:=Turret; Capability2:=Turret;
    end;
    { veze, pevnosti }
    {x}
    { RADEK NIZE ODREMOVAT ! }
{    if ((I <> 37) and (I <> 38)) then begin
        Str(I,Ret); Ret:=Ret+'_'+Name; for J:=Length(Ret)+1 to 20 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(LAttack,Ret); Ret:=Ret; for J:=Length(Ret)+1 to 5 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(TAttack,Ret); Ret:=Ret; for J:=Length(Ret)+1 to 5 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(AAttack,Ret); Ret:=Ret; for J:=Length(Ret)+1 to 6 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(Defence,Ret); Ret:=Ret; for J:=Length(Ret)+1 to 7 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(Range,Ret);   Ret:=Ret; for J:=Length(Ret)+1 to 5 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(LAttack+TAttack+AAttack+Defence+Range,Ret);
        for J:=Length(Ret)+1 to 5 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));

        Str(B,Ret); Ret:=Ret;   for J:=Length(Ret)+1 to 3 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(P,Ret); Ret:=Ret;   for J:=Length(Ret)+1 to 3 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(E,Ret); Ret:=Ret;   for J:=Length(Ret)+1 to 3 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(X,Ret); Ret:=Ret;   for J:=Length(Ret)+1 to 4 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        Str(MatClass,Ret); Ret:=Ret; for J:=Length(Ret)+1 to 3 do Ret:=Ret+' ';
        BlockWrite(OutFile,Ret[1],Length(Ret));
        case (Capability) of
           L  : Ret:='L';
           T  : Ret:='T';
           L_T: Ret:='L+T';
           U  : Ret:='U';
           N  : Ret:='-';
        end;
        BlockWrite(OutFile,Ret[1],Length(Ret));
        case (Capability2) of
           L  : Ret:=',L';
           T  : Ret:=',T';
           L_T: Ret:=',L+T';
           U  : Ret:=',U';
           N  : Ret:=',-';
        end;
        BlockWrite(OutFile,Ret[1],Length(Ret));

        Ret[1]:=Chr($0D); Ret[2]:=Chr($0A);
        BlockWrite(OutFile,Ret[1],2);
    end; {}
  end;
  Close(OutFile);{}
  I:=IOResult;
end;

{ ***** }
function Prepare_production(Race:Byte; Category,Preference,Material,Priority,TGNum,LockType:Byte):Boolean;
{ vybere jednotku k vyrobe a vyrobu zrealizuje
  --Category nabyva hodnot: (ucinnost v kategorii ... )
  L, T, U, Turret, N
  --Preference nabyva hodnot:
  0 ..viceucelova jednotka (napr. L+T v kategorii L nebo T)
  1 ..pechota
  2 ..nejlepsi komplexni hodnota
  3 ..nejlepsi vykon v kategorii
  4 ..nahodny vyber
  5 ..maximalni PVO schopnost
  6 ..carrier
  7 ..mutant
  8 ..autodetonator
  9 ..pro turret lehka pevnost
  10..pro turret AASam
  11..pro turret tezka pevnost
  12..pro turret raketova vez
  13..letecka jednotka
  14..preferuje letecky carrier
  15..para
  16..vysadkovy letoun
  17..stihac
  18..terminator
  --Material nabyva hodnot:
  0..nejlevnejsi
  1..
  2..
  3..
  4..nejdrazsi
  --Priority je priorita vyroby:
  ProductionPriorityLow, ProductionPriorityMedium,ProductionPriorityHi,
  ProductionPriorityVeryHi, ProductionPriorityAutomatic
  --TGNum:
     je cislo TG, do ktere se produkt po vyrobeni zaradi
  -funkce vraci True, pokud se podarilo nejakou jednotku vybrat
  --LockType: udava typ locku taskgrupy, ktery se pri vyrobe nastavi
  0..AA
  1..A
  2..L
  3..H
  4..Carrier
}
label Skip;
var I, UnitType:Word;
    Category2:Byte;
    Cost, OldCost:Single;

    MaxAvailEE:Word;
    Request, Request2:Word;
    RandArray: array[1..MaxTypesOfUnits] of Byte;
    RandArrayUk:Byte;

begin
 UnitType:=255; RandArrayUk:=0;
 UnitParams[37].Capability:=N; UnitParams[37].Capability2:=N;
 if (((Preference = 6) or (Preference = 14)) and
     ((TGNum < 10) or (Rand(RndUk) = 9))) then begin
    UnitParams[37].Capability:=L_T; UnitParams[37].Capability2:=L_T;
 end;
 {X}
 with (Races[Race]) do begin
   {*****}
   if (Building_types[5].IBuildingSize = 2) then Request:=2 else Request:=14;
   Request2:=3; { akumulator }
   if ((not NotEnoughFreePlaces(Race,Request)) and
       BuildingProductionPossible(Race,5) or
       (not NotEnoughFreePlaces(Race,Request2)) and
       BuildingProductionPossible(Race,6))
   then
     MaxAvailEE:=1000 { elektrina je neomezena }
   else { maximalni kapacita je omezena hodnotou MaxAvailEE }
     MaxAvailEE:=ExistBuildings[5]*ECapacity+ExistBuildings[6]*AcumulatorCapacity;

   {*****}
   for I:=1 to MaxTypesOfUnits do with (UnitParams[I]) do
   if (UnitProductionPossible(Race,I) and
       (ExistBuildings[Unit_types[I,Races[Race].Ally].Parent] > 0) and
       (Unit_types[I,Races[Race].Ally].EE <= MaxAvailEE))
   then begin { jednotku je mozne produkovat + existuje producent a
                jsou k dispozici dostatecne zdroje EE }
     if ((Category = L) or (Category = T)) then Category2:=L_T
     else Category2:=Category;
     if ((Capability = Category) or (Capability = Category2) or
         (Capability2 = Category) or (Capability2 = Category2)) then begin
     { odpovida kategorie ucinnosti proti danemu cili }
       if ((I = 18) and ((Races[Race].ExistUnits[18] >= 1) or
           (FighterTimmer > TimeSlot)) and (Race <> MyRace))
       then GoTo Skip;
       if ((I = 19) and ((Races[Race].ExistUnits[19] >= 1) or
           (TerminatorTimmer > TimeSlot)) and (Race <> MyRace))
       then GoTo Skip;
       if (MatClass <= Material) then begin
       { odpovida trida materialu }
          case (Preference) of
             0 : begin { viceucelova jednotka (napr. L+T v kategorii L nebo T)}
                   if (Capability = Category2) then begin
                      if (UnitType = 255) then UnitType:=I
                      else { je novy nalez vyhodnejsi? }
                        if ((AAttack+LAttack+TAttack+Defence+Range) >
                            (UnitParams[UnitType].AAttack+UnitParams[UnitType].LAttack+
                             UnitParams[UnitType].TAttack+UnitParams[UnitType].Defence+
                             UnitParams[UnitType].Range))
                        then UnitType:=I; { ano! }
                   end else if (UnitType = 255) then UnitType:=I; { nouzovka,
                   nepujde o univerzalni, ale jednoucelovy typ }
                 end;
             1 : begin { pechota }
                   case (Category) of
                     L : if (Unit_types[I,Races[Race].Ally].TargetTyp = 0) then begin
                           if (UnitType = 255) then UnitType:=I
                           else begin
                             if (LAttack > UnitParams[UnitType].LAttack)
                             then UnitType:=I; { ano! }
                           end;
                         end;
                     T : if (Unit_types[I,Races[Race].Ally].TargetTyp = 0) then begin
                           if (UnitType = 255) then UnitType:=I
                           else begin
                             if (TAttack > UnitParams[UnitType].TAttack)
                             then UnitType:=I; { ano! }
                           end;
                         end;
                     U : if (Unit_types[I,Races[Race].Ally].TargetTyp = 0) then begin
                           if (UnitType = 255) then UnitType:=I
                           else begin
                              if ((AAttack+LAttack+TAttack+Defence+Range) >
                                  (UnitParams[UnitType].AAttack+UnitParams[UnitType].LAttack+
                                   UnitParams[UnitType].TAttack+UnitParams[UnitType].Defence+
                                   UnitParams[UnitType].Range))
                              then UnitType:=I; { ano! }
                           end;
                         end;
                   end;
                 end;
             2 : begin { nejlepsi komplexni hodnota }
                    if (UnitType = 255) then UnitType:=I
                    else { je novy nalez vyhodnejsi? }
                      if ((AAttack+LAttack+TAttack+Defence+Range) >
                          (UnitParams[UnitType].AAttack+UnitParams[UnitType].LAttack+
                           UnitParams[UnitType].TAttack+UnitParams[UnitType].Defence+
                           UnitParams[UnitType].Range))
                      then UnitType:=I; { ano! }
                 end;
             3 : begin { nejlepsi vykon v kategorii }
                   case (Category) of
                     L : begin
                           if (UnitType = 255) then UnitType:=I
                           else begin
                             if (LAttack > UnitParams[UnitType].LAttack)
                             then UnitType:=I; { ano! }
                           end;
                         end;
                     T : begin
                           if (UnitType = 255) then UnitType:=I
                           else begin
                             if (TAttack > UnitParams[UnitType].TAttack)
                             then UnitType:=I; { ano! }
                           end;
                         end;
                     U : begin
                           if (UnitType = 255) then UnitType:=I
                           else begin
                              if ((AAttack+LAttack+TAttack+Defence+Range) >
                                  (UnitParams[UnitType].AAttack+UnitParams[UnitType].LAttack+
                                   UnitParams[UnitType].TAttack+UnitParams[UnitType].Defence+
                                   UnitParams[UnitType].Range))
                              then UnitType:=I; { ano! }
                           end;
                         end;
                   end;
                 end;
             4 : begin { nahodny vyber }
                    Inc(RandArrayUk); RandArray[RandArrayUk]:=I;
                 end;
             5 : begin { maximalni PVO schopnost }
                    if ((UnitType = 255) and (AAttack > 0)) then UnitType:=I
                    else { je novy nalez vyhodnejsi? }
                      if ((UnitType <> 255) and (AAttack > UnitParams[UnitType].AAttack))
                      then UnitType:=I; { ano! }
                 end;
             6 : begin { carrier }
                    if ((UnitType = 255) and (Unit_types[I,Races[Race].Ally].Capacity > 0))
                    then UnitType:=I
                    else
                      if ((UnitType <> 255) and (Unit_types[UnitType,Races[Race].Ally].Capacity > 0) and
                          (Unit_types[I,Races[Race].Ally].Capacity > 0)) then
                        { zvol nahodny carrier }
                        if (Rand(RndUk) < 5) then UnitType:=I;
                        { 50% pravdepodobnost }
                 end;
             7 : begin { mutant }
                    if (I = 29) then begin
                      UnitType:=I;
                    end;
                 end;
             8 : begin { autodetonator }
                    if (I = 23) then begin
                       UnitType:=I;
                    end;
                 end;
             9 : begin { lehka pevnost  }
                    if (I = 20) then begin
                       UnitType:=I;
                    end;
                 end;
             10 : begin { AA sam }
                    if (I = 32) then begin
                       UnitType:=I;
                    end;
                 end;
             11 : begin { tezka pevnost }
                    if (I = 21) then begin
                       UnitType:=I;
                    end;
                 end;
             12 : begin { raketova vez }
                    if (I = 31) then begin
                       UnitType:=I;
                    end;
                 end;
             13 : begin { viceucelova jednotka (napr. L+T v kategorii L nebo T)}
                   if (AirUnit) then begin
                      if (UnitType = 255) then UnitType:=I
                      else { je novy nalez vyhodnejsi? }
                        if ((AAttack+LAttack+TAttack+Defence+Range) >
                            (UnitParams[UnitType].AAttack+UnitParams[UnitType].LAttack+
                             UnitParams[UnitType].TAttack+UnitParams[UnitType].Defence+
                             UnitParams[UnitType].Range))
                        then UnitType:=I; { ano! }
                   end;
                 end;
              14: begin { preferuje letecky carrier}
                    if ((UnitType = 255) and (Unit_types[I,Races[Race].Ally].Capacity > 0))
                    then UnitType:=I
                    else
                      if ((UnitType <> 255) and (Unit_types[UnitType,Races[Race].Ally].Capacity > 0) and
                          (Unit_types[I,Races[Race].Ally].Capacity > 0)) then
                        if (AirUnit) then UnitType:=I; { ano! }
                  end;
              15 : begin { para }
                    if ((I = 7) or (I = 9)) then begin
                       if (UnitType = 255) then UnitType:=I;
                       if (Rand(RndUk) mod 2 = 0) then UnitType:=I;
                    end;
                  end;
              16 : begin { vysadkovy letoun  }
                    if ((I = 17) and (TimeSlot > 350)) then begin
                       UnitType:=I; Priority:=ProductionPriorityHi;
                    end;
                  end;
              17 : begin { stihac  }
                    if (I = 18) then begin
                       UnitType:=I;
                    end;
                  end;
              18 : begin { terminator  }
                    if (I = 19) then begin
                       UnitType:=I;
                    end;
                  end;
          end;
Skip:
       end; { if (MatClass <= Material) then begin }
     end; { if ((Capability = Category) or ... then begin }
   end; { for I:=1 to MaxTypesOfUnits do ... begin }
   if (Preference = 4) then begin
   { nahodny vyber }
     if (RandArrayUk > 0) then UnitType:=RandArray[Random(RandArrayUk)+1];
   end;

   if (UnitType <> 255) then
     if (Category = Turret) then begin
       ProductionManager.Insert(Race,GetProdPrioU(Priority),TGNum,MoveBuildCom,
                                Unit_types[UnitType,Races[Race].Ally].Parent,UnitType,LockType);{}
       Inc(Races[Race].DefendLock);
     end else begin
       if (UnitType = 18) then begin
          if (TimeSlot < 64000) then FighterTimmer := TimeSlot+1500
          else FighterTimmer := 65535;
       end;
       if (UnitType = 19) then begin
          if (TimeSlot < 64000) then TerminatorTimmer := TimeSlot+1500
          else TerminatorTimmer := 65535;
       end;
       ProductionManager.Insert(Race,GetProdPrioU(Priority),TGNum,PrepareCom,
                                Unit_types[UnitType,Races[Race].Ally].Parent,UnitType,LockType);
       Inc(RacesTGInfo^[Race,TGNum].Lock);
     end;
 end; { with (Races[Race]) do begin }

 Prepare_production:=UnitType <> 255; { UnitType = 255 ... neuspech }
end;

{ ***** }
procedure TG_Reinfo_Execute(Race:Byte);
{ provede doplneni pro jednotlive TG
}
const MaxSeznam = 2;
label Konec;
var ATGNum, DTGNum, STGNum, ATGFree, DTGFree, STGFree:Word;
    J,Limit:Integer;
    I,K:Word;
    GndDefNeed1, AADefNeed1, GndDefNeed2, AADefNeed2,
    GndDefNeed3, AADefNeed3 : Word;
    { udava potrebu vystavby jednotlivych obrannych instalaci pozemnich -
      GndDefNeed (raketova vez, tezka pevnost) a vzdusnych - AAdefNeed
      (SAM, lehka pevnost) a to pro tri priority ( 1 je nejnizsi priorita )
    }
    LLight2, Light2, Heavy2, Air2, AA2 : Word;
    _Air,_LL,_L,_H,_A,_AA,Carry,Spec:Integer;
    Pom2,Pom3, Pomer, Result : Single;
    AvailCapacity : Word;
    PomVal:Integer;
    Pom:PUnit;
    Seznam:array[0..MaxSeznam] of record { seznam pozadavku na vyrobu }
              Category:Byte; { katerorie, proti niz musime zvysit ucinnost:
              0..AA, 1..L, 2..T, 3..A, 4..Carrier }
              Weight:Single;
           end;
    Typ,Priority:Byte;
    RndNum:Byte;
    PomValue:Single;
    Validity, AllSame,GNDPriority:Boolean;
    Mat:Byte;
begin
  ATGNum:=0; DTGNum:=0; STGNum:=0; ATGFree:=255; DTGFree:=255; STGFree:=255;
  with (Races[Race]) do begin
  { nyni zkontrolujeme, zda-li je dostatecny pocet aktivnich TG }
    for I:=0 to 3 do begin
      if (TaskGroups^[I].Validity) then Inc(ATGNum)
      else if (ATGFree = 255) then ATGFree:=I;
    end;
    for I:=4 to 7 do begin
      if (TaskGroups^[I].Validity) then Inc(DTGNum)
      else if (DTGFree = 255) then DTGFree:=I;
    end;
    for I:=8 to 9 do begin
      if (TaskGroups^[I].Validity) then Inc(STGNum)
      else if (STGFree = 255) then STGFree:=I;
    end;

    { dovytvoreni chybejicich TG }
    if ((ATGNum < AttackTGNum) and (not Forbid)) then begin
       if ((TaskGroups^[10].Validity) and
           ((TaskGroups^[10].Command = PrepareCom) or
            (TaskGroups^[10].Command = WithoutCom)) and
           (TGPlusActivity = 1)) then
          { doplneni ze zalozni taskgrupy }
          TaskGroupCommand(Race,10,MergeCom,0,ATGFree,
                           RacesTGInfo^[Race,ATGFree].IHomeTaskGroupInfoPos,
                           RacesTGInfo^[Race,ATGFree].JHomeTaskGroupInfoPos,100)
       else
         if (RacesTGInfo^[Race,ATGFree].Lock = 0) then begin
           if (not Prepare_production(Race,U,4,4,ProductionPriorityHi,ATGFree,255))
           then Prepare_production(Race,L,4,3,ProductionPriorityHi,ATGFree,255);
         end;
    end;
    {*}
    if ((DTGNum < DefenceTGNum) and (not Forbid)) then begin
       if ((TaskGroups^[10].Validity) and
           ((TaskGroups^[10].Command = PrepareCom) or
            (TaskGroups^[10].Command = WithoutCom)) and
           (TGPlusActivity = 2)) then
          { doplneni ze zalozni taskgrupy }
          TaskGroupCommand(Race,10,MergeCom,0,DTGFree,
                           RacesTGInfo^[Race,DTGFree].IHomeTaskGroupInfoPos,
                           RacesTGInfo^[Race,DTGFree].JHomeTaskGroupInfoPos,100)
       else
         if (RacesTGInfo^[Race,DTGFree].Lock = 0) then begin
           if (not Prepare_production(Race,U,4,3,ProductionPriorityHi,DTGFree,255))
           then Prepare_production(Race,L,4,3,ProductionPriorityHi,DTGFree,255);
         end;
    end;
    {*}
    if ((STGNum < SaboteurTGNum) and (not Forbid) and
        (RacesTGInfo^[Race,STGFree].Lock = 0) and
        (RacesTGInfo^[Race,STGFree].SpecialLock = 0))
    then with (RacesTGInfo^[Race,STGFree]) do begin
       if (((Rand(RndUk) mod 2 = 0) or (TimmerPlus = 0)) and
           (TimmerMinus > 0))
       then begin { zaporna  }
         PomVal:=-(Timmer1 div 100)*Random(TimmerMinus);
       end else begin { kladna }
         PomVal:=(Timmer1 div 100)*Random(TimmerPlus);
       end;
       SpecialLock:=Timmer1+PomVal;
       if (not Prepare_production(Race,U,14,4,ProductionPriorityMedium,STGFree,255))
       then begin
         {SpecialLock:=SpecialLock+Timmer1 shr 2;{}
         if (not Prepare_production(Race,L,6,3,ProductionPriorityMedium,STGFree,255))
         then Prepare_production(Race,L_T,1,3,ProductionPriorityMedium,STGFree,255);
       end;
    end;
    {*}
    if ((not TaskGroups^[12].Validity) and (not Forbid)) then begin
       if (RacesTGInfo^[Race,12].Lock = 0) then begin
         if (not Prepare_production(Race,N,16,4,ProductionPriorityHi,12,255))
         then Prepare_production(Race,U,15,4,ProductionPriorityHi,12,255);
       end;
    end;

    { *** analyza obrannych instalaci *** }
    if ((Races[Race].DefendLock = 0) and (Races[Race].ActualFreeStructures > 0) and
        (DefInstalPriorityFlag > DefInstalPriority))
    then with (Races[Race]) do begin
    { lze uvazovat o vyrobe obrannych instalaci }
        DefInstalPriorityFlag:=0;
        GndDefNeed1:=0; AADefNeed1:=0; GndDefNeed2:=0; AADefNeed2:=0;
        GndDefNeed3:=0; AADefNeed3:=0;
        for J:=0 to (ActualFreeStructures-1) do
          for I:=1 to MaxFreePlaces do
          with (FreePlaces^[I,J]) do begin
             case (PlaceType) of
               7  : begin { SAM (tezka pevnost), priorita 1 (nejvyssi) }
                       Inc(AADefNeed1);
                    end;
               8  : begin { SAM (tezka pevnost), priorita 2 }
                       Inc(AADefNeed2);
                    end;
               9  : begin { SAM (tezka pevnost), priorita 3 (nejnizsi) }
                       Inc(AADefNeed3);
                    end;
               10 : begin { Raketova vez (lehka pevnost), priorita 1 (nejvyssi) }
                       Inc(GndDefNeed1);
                    end;
               11 : begin { Raketova vez (lehka pevnost), priorita 2 }
                       Inc(GndDefNeed2);
                    end;
               12 : begin { Raketova vez (lehka pevnost), priorita 3 (nejnizsi) }
                       Inc(GndDefNeed3);
                    end;
             end; { case }
          end; { with (FreePlaces[I,J]) do begin }

        { nyni zjistime, zda a jakou je treba vyrabet obrannou instalaci }
        Pom2:=GndDefNeed1+0.66*GndDefNeed2+0.33*GndDefNeed3;
        Pom3:=AADefNeed1+0.66*AADefNeed2+0.33*AADefNeed3;
        if (GndDefNeedInit = 65535) then GndDefNeedInit:=Pom2;
        if (AADefNeedInit = 65535) then AADefNeedInit:=Pom3;
        if (GndDefNeedInit = 0) then Pom2:=100
        else
           Pom2:=100-Pom2/(GndDefNeedInit/100); { kolik bylo vystaveno v % }
        if (AADefNeedInit = 0) then Pom3:=100
        else
           Pom3:=100-Pom3/(AADefNeedInit/100); { kolik bylo vystaveno v % }
        if (Pom3 = 0) then Pom3:=0.1; { pomucka pro zacatek }

        if (Ally = 1) then begin
          if (GlobalCompGroundPct <> 100)
          then Pomer:=GlobalCompGroundPct/(100-GlobalCompGroundPct)
          else Pomer:=100;
        end else begin
          if (GlobalFriendGroundPct <> 100)
          then Pomer:=GlobalFriendGroundPct/(100-GlobalFriendGroundPct)
          else Pomer:=100;
        end;
        { Pomer = kolikrat je pozemnich cilu vice nez vzdusnych }
        if (Pomer = 0) then begin
          if (Pom2 < Pom3) then  GNDPriority:=True else GNDPriority:=False;
        end else
          if (((Pom2/Pomer) < Pom3) or (Pom2 = 0) and (Pomer > 1))
          then GNDPriority:=True else GNDPriority:=False;

        Priority:=ProductionPriorityMedium;
        if (DefInstalPriority and 128 = 1) then begin
        { vyssi priorita }
           if (GNDPriority) then begin
             if (Pom2 < 33) then Priority:=ProductionPriorityHi
           end else
             if (Pom3 < 33) then Priority:=ProductionPriorityHi;
        end;

        if ((not GNDPriority) and (AADefNeedInit > 0)) then begin
        { PVO, tezke pevnosti }
           if (PermittedUnits[32]) then { SAM }
             Prepare_production(Race,Turret,10,4,Priority,TGInvalid,255)
           else
             Prepare_production(Race,Turret,11,4,Priority,TGInvalid,255)
        end else
          if (GndDefNeedInit > 0) then begin
             if (PermittedUnits[31]) then { raketova vez }
               Prepare_production(Race,Turret,12,4,Priority,TGInvalid,255)
             else
               Prepare_production(Race,Turret,9,4,Priority,TGInvalid,255);
          end;
    end; { ... then with (Races[Race]) do begin ... }
    { *** konec analyzy obrannych instalaci *** }


    for I:=4 to 12 do begin
    { obranne instalace a TGPara }
      { * ma se doplnit obranna nebo Para TG? * }
      if (((I <= 9) or (I = 12)) and (TaskGroups^[I].Validity)) then begin
        if (Ally = 0) then Pom2:=GlobalFriendGroundPct else Pom2:=GlobalCompGroundPct;
        if (I <> 12) then Result:=Get_task_group_strength(Race,I,Pom2)
        else Result:=Get_task_group_strength_without_air(Race,I,Pom2);
        if (Result >= RacesTGInfo^[Race,I].TGMinLimit)
        then begin
          if (I <= 7) then { obranna }
            TaskGroups^[I].Command:=WithoutCom
          else with (TaskGroups^[I]) do begin
          { Para muze utocit }
            if (((I <> 12) or (Carriers <> Nil) and
                ((Races[Race].ParaEnabled and 48) shr 4 <= Fighters) and
                ((Races[Race].ParaEnabled and 192) shr 6 <= Terminators)) and
                (MasterCommand = WithoutCom))
            then begin
              if (I = 12) then
                TaskGroupCommand(Race,I,AttackCom,0,2,ITargPlace,JTargPlace,RacesTGInfo^[Race,I].MoveCourageNormal)
              else begin
                if ((ITaskGroupInfoPos <> ITargPlace) or (JTaskGroupInfoPos <> JTargPlace)) then
                  TaskGroupCommand(Race,I,AttackCom,0,2,ITargPlace,JTargPlace,RacesTGInfo^[Race,I].MoveCourageSabot);
              end;
            end else begin
               if (TaskGroups^[I].Command = WithoutCom) then
                 TaskGroups^[I].Command:=PrepareCom;
            end;
          end;
        end else
          if (TaskGroups^[I].Command = WithoutCom) then
             TaskGroups^[I].Command:=PrepareCom;
      end;
    end;

    { *** nyni zjistime, zda doplnovat grupu TGPlus: }
    ATGNum:=254; DTGNum:=254;
    for I:=0 to 7 do begin
      if ((TaskGroups^[I].Validity) and
          (TaskGroups^[I].Command = PrepareCom))
      then begin
         if (I < 4) then ATGNum:=I else DTGNum:=I;
      end else begin
         if (TaskGroups^[I].Validity) then begin
           if (I < 4) then begin
             if (ATGNum = 254) then ATGNum:=255;
           end else begin
             if (DTGNum = 254) then DTGNum:=255;
           end;
         end;
      end;
    end;

    K:=9;
    if (AttackTGNum > 0) then begin
      if (ATGNum = 255) then begin
         { existuje alespon jedna utocna TG a je zamestnana - je mozne
            provest vyrobu taskgtrupy TGPlus }
         TGPlusActivity:=1; K:=10;
      end;
    end else
      if ((DefenceTGNum > 0) and (AttackTGNum = 0)) then begin
         if (DTGNum = 255) then begin
          { existuje alespon jedna obranna TG, je zamestnana a nelze vyrobit
            zadnou utocnou TG - je mozne provest vyrobu taskgtrupy TGPlus }
            TGPlusActivity:=2; K:=10;
         end;
      end;

    case (TGPlusActivity) of
       1 : with (TaskGroups^[10]) do begin { TGPlus pro utocne skupiny }
            if (not Validity) then begin {vytvor novou TGPlus}
              if (RacesTGInfo^[Race,10].Lock = 0) then
                 if (not Prepare_production(Race,L,6,3,ProductionPriorityHi,10,255))
                 then Prepare_production(Race,L,4,2,ProductionPriorityHi,10,255);
            end else
              if (Command = MergeCom) then begin
              { mod slucovani, prestan TGPlus posilovat  }
                 K:=9;
              end;
            { nyni "posilove informace" }
            with (Reinfo) do begin
              if (Ally=0) then LLight:=Round(GlobalFriendLLight) else LLight:=Round(GlobalCompLLight);
              if (Ally=0) then Light:=Round(GlobalFriendLight) else Light:=Round(GlobalCompLight);
              if (Ally=0) then Heavy:=Round(GlobalFriendHeavy) else Heavy:=Round(GlobalCompHeavy);
              if (Ally=0) then Air:=Round(GlobalFriendAir) else Air:=Round(GlobalCompAir);
              if (Ally=0) then AAttack:=Round(GlobalFriendAAttack) else AAttack:=Round(GlobalCompAAttack);
              {LLight:=LLight/3;  Light:=Light/3;
              Heavy:=Heavy/3;  Air:=Air/3;  AAttack:=AAttack/3; {}
              EnemyBuildingsWeight:=0; FriendlyBuildingsWeight:=0;
              SpecTargets:=0; Difference:=0;
            end;
           end;
       2 : with (TaskGroups^[10]) do begin { TGPlus pro obranne skupiny }
            if (not Validity) then begin {vytvor novou TGPlus}
              if (RacesTGInfo^[Race,10].Lock = 0) then
                 if (not Prepare_production(Race,L,6,3,ProductionPriorityHi,10,255))
                 then Prepare_production(Race,L,4,2,ProductionPriorityHi,10,255);
            end else
              if (Command = MergeCom) then begin
              { mod slucovani, prestan TGPlus posilovat  }
                 K:=9;
              end;
            { nyni "posilove informace" }
            with (Reinfo) do begin
              if (Ally=0) then LLight:=Round(GlobalFriendLLight) else LLight:=Round(GlobalCompLLight);
              if (Ally=0) then Light:=Round(GlobalFriendLight) else Light:=Round(GlobalCompLight);
              if (Ally=0) then Heavy:=Round(GlobalFriendHeavy) else Heavy:=Round(GlobalCompHeavy);
              if (Ally=0) then Air:=Round(GlobalFriendAir) else Air:=Round(GlobalCompAir);
              if (Ally=0) then AAttack:=Round(GlobalFriendAAttack) else AAttack:=Round(GlobalCompAAttack);
              {LLight:=LLight/10;  Light:=Light/10;
              Heavy:=Heavy/10;  Air:=Air/10;  AAttack:=AAttack/10;{}
              EnemyBuildingsWeight:=0; FriendlyBuildingsWeight:=0;
              SpecTargets:=0; Difference:=0;
            end;
           end;
    else
    end;

    { zkontroluj limit TGPlus }
    if ((TaskGroups^[10].Validity) and
        (TaskGroups^[10].MasterCommand = WithoutCom))
    then begin
      if (Ally = 0) then Pom2:=GlobalFriendGroundPct else Pom2:=GlobalCompGroundPct;
      if (Get_task_group_strength(Race,10,Pom2) >= RacesTGInfo^[Race,10].TGMinLimit)
      then begin
        TaskGroups^[10].Command:=WithoutCom;
      end else
        if (TaskGroups^[10].Command = WithoutCom) then
           TaskGroups^[10].Command:=PrepareCom;
    end;

    { *** doplneni existujicich TG *** }
    Limit:=4;
    for I:=0 to 12 do
    if ((TaskGroups^[I].Validity) and
        ((I <> 10) or (K = 10)) and
        ((TaskGroups^[I].Command = PrepareCom) or
         (TaskGroups^[I].GroupType = TGPlus) and
         (TaskGroups^[I].MasterCommand <> MergeCom) and
         (TaskGroups^[I].Command <> WithoutCom)) and
        (RacesTGInfo^[Race,I].Lock <= Limit)) then
    with (TaskGroups^[I]) do with (Reinfo) do begin
    { doplnovani po max. trojicich }
        Inc(DefInstalPriorityFlag);
        if (DefInstalPriorityFlag > 100) then DefInstalPriorityFlag:=0;

        if (TaskGroups^[10].Validity) then begin
        { doplneni aktualni TG zalozni taskgrupou }
          if ((I < 4) and (TGPlusActivity = 1)) then
             TaskGroupCommand(Race,10,MergeCom,0,I,
                              TaskGroups^[I].ITaskGroupInfoPos,
                              TaskGroups^[I].JTaskGroupInfoPos,100);
          if ((I > 3) and (I < 8) and (TGPlusActivity = 2)) then
             TaskGroupCommand(Race,10,MergeCom,0,I,
                              TaskGroups^[I].ITaskGroupInfoPos,
                              TaskGroups^[I].JTaskGroupInfoPos,100)
        end;

        if ((I > 3) and (I < 10) or (I = 12)) then begin
        { obranne instalace a sabotazni grupy }
          with (Reinfo) do begin
             if (Ally=0) then LLight:=Round(GlobalFriendLLight) else LLight:=Round(GlobalCompLLight);
             if (Ally=0) then Light:=Round(GlobalFriendLight) else Light:=Round(GlobalCompLight);
             if (Ally=0) then Heavy:=Round(GlobalFriendHeavy) else Heavy:=Round(GlobalCompHeavy);
             if (Ally=0) then Air:=Round(GlobalFriendAir) else Air:=Round(GlobalCompAir);
             if (Ally=0) then AAttack:=Round(GlobalFriendAAttack) else AAttack:=Round(GlobalCompAAttack);
             if ((LLight+Light+Heavy) <= 9) then begin
               LLight:=3; Light:=3; Heavy:=3;
             end;{}
             EnemyBuildingsWeight:=0; FriendlyBuildingsWeight:=0;
             SpecTargets:=0; Difference:=0;
          end;
        end;

        Pom3:=AirTG[0]; Pom2:=AirTG[1]; Pom3:=Pom3+(Pom2*DangerLimit1Coeff);
        Pom2:=AirTG[2]; Pom3:=Pom3+(Pom2*DangerLimit2Coeff);
        Air2:=Round(Pom3);
        {x}
        { nyni odhad vzdusnych sil nepritele }
        if (Races[Race].Ally = 1) then
          _Air:=Round((GlobalCompAir/TotalRobotRaces) / 1.4)
        else
          _Air:=Round((GlobalFriendAir/TotalOSNRaces) / 1.4);

        { nastaveni priorit vyroby vzdusnych objektu }
        if (GroupType = TGSaboteur) then begin
          Pom2:=2;
        end else begin
          { pripadne navysime vzdusne sily nepritele }
          Pom2:=Round(1.0*Air2/4 + 3); if (_Air > Air) then Air:=_Air;
        end;

        { nyni zjistime, kolik a ceho chybi }
        _AA:=Integer(Air)-Round(AntiAirTG);
        _A:=Integer(Air2)-AAttack+Round(Pom2);
        { zapocteni maximalniho procentualniho zastoupeni leteckych jednotek
          ze sily taskgrupy }
        Pom3:=Get_task_group_strength(Race,I,100);
        if ((Pom3 > 0) and
            (Air2/(Pom3/100) > RacesTGInfo^[Race,I].MaxAirPct) and
            (_A > 0)) then _A:=0; { prekroceno max. procento air jednotek
                                    v taskgrupe }
        { opak predchozich - cim mensi PVO obrana, tim vice air units produkuj}
        _LL:=Integer(LLight)-Round(AntiLightTG/2);
        _L:=Integer(Light)-Round(AntiLightTG/2);
        _H:=Integer(Heavy)-Round(AntiHeavyTG);
        if ((((Races[Race].ParaEnabled and 48) shr 4 > Fighters) or
             ((Races[Race].ParaEnabled and 192) shr 6 > Terminators)) and
            (I = 12)) then _A:=MaxInt;

        { pokud nemame alespon 33% potrebnych PVO kapacit, navysime
          zadost o PVO: }
        Pom2:=Air; Pom3:=AntiAirTG;
        if ((Pom2 <> 0) and (Pom3/(Pom2/100) < 33) and (_AA > 0)) then begin
          if ((_LL+_L) > _AA) then _AA:=_LL+_L;
          if (_H > _AA) then _AA:=_H;
        end;

        Special:=0;
        { zjistime stav CARRIERU: }
        AvailCapacity:=0; Pom:=Carriers;
        while (Pom <> Nil) do begin
          Inc(AvailCapacity,Unit_types[Pom^.UnitType,Races[Race].Ally].Capacity);
          Pom:=Pom^.Next;
        end; Pom:=Carriers;
        { spocitame potrebna mista plus 20% rezerva }
        Carry:=Integer(Round(1.2*TGCapacityNeed)) - AvailCapacity;
        {x}
        { nyni vybereme nejaktualnejsi pozadavky }
        for J:=0 to MaxSeznam do begin
          Seznam[J].Category:=255; Seznam[J].Weight:=0;
        end;
        {if (RacesTGInfo^[Race,I].CLock > 1) then PomValue:=PomValue/RacesTGInfo^[Race,I].CLock;{}
        if ((Carry > 1) and ((I <> 12) or
             (Pom = Nil) and (RacesTGInfo^[Race,I].CLock <= 1) or
             (ParaEnabled and 6 = 7) and (RacesTGInfo^[Race,I].Clock = 1) and
             ((Pom = Nil) or (Pom^.Next = Nil))))
        then begin
        { vloz carrier }
          if ((Carry > 10) or (I = 12)) then Carry:=255;
          Seznam[0].Category:=4;
          if ((_LL+_L) > Carry) then Carry:=_LL+_L;
          if (_A > Carry) then Carry:=_A;
          if (_H > Carry) then Carry:=_H;
          Seznam[0].Weight:=Carry;

          PomValue:=Carry;
          if (PomValue > 3) then PomValue:=PomValue - PomValue/2 else PomValue:=0;
          if (I <> 12) then begin
            Seznam[1].Weight:=PomValue; Seznam[1].Category:=4;
          end;
        end;

        if ((I <> 12) or
            (Get_task_group_strength_without_air(Race,12,100) < RacesTGInfo^[Race,12].TGMinLimit) or
            (_A = MaxInt))
        then begin
           { do pole vzdy zaradim pozadavek; je-li vetsi nez 3, pak snizim jeho
             hodnotu o 10% a pokracuji znovu }
           { *** nejprve AA *** }
           PomValue:=_AA;
           if (RacesTGInfo^[Race,I].AALock > 1) then PomValue:=PomValue/RacesTGInfo^[Race,I].AALock;
           if (RacesTGInfo^[Race,I].Lock <= 1) then Limit:=MaxSeznam else Limit:=0;
           if (I = 12) then begin
              if (RacesTGInfo^[Race,I].Lock > 0) then Limit:=-1
              else if (Seznam[0].Category = 4) then Limit:=1 else Limit:=0;
           end;
           for J:=0 to Limit do
             if (Seznam[J].Weight < PomValue) then begin
               Seznam[J].Weight:=PomValue; Seznam[J].Category:=0;
               if (PomValue > 3) then PomValue:=PomValue - PomValue/2
               else PomValue:=0;
             end;

           { *** nyni LL+L *** }
           PomValue:=_LL+_L;
           if (RacesTGInfo^[Race,I].LLock > 1) then PomValue:=PomValue/RacesTGInfo^[Race,I].LLock;
           if (RacesTGInfo^[Race,I].Lock <= 2) then Limit:=MaxSeznam else Limit:=0;
           if (I = 12) then begin
              if (RacesTGInfo^[Race,I].Lock > 0)  then Limit:=-1
              else if (Seznam[0].Category = 4) then Limit:=1 else Limit:=0;
           end;
           for J:=0 to Limit do
             if (Seznam[J].Weight < PomValue) then begin
               Seznam[J].Weight:=PomValue; Seznam[J].Category:=1;
               if (PomValue > 3) then PomValue:=PomValue - PomValue/2
               else PomValue:=0;
             end;

           { *** nyni H *** }
           PomValue:=_H;
           if (RacesTGInfo^[Race,I].HLock > 1) then PomValue:=PomValue/RacesTGInfo^[Race,I].HLock;
           if (RacesTGInfo^[Race,I].Lock <= 2) then Limit:=MaxSeznam else Limit:=0;
           if (I = 12) then begin
              if (RacesTGInfo^[Race,I].Lock > 0)  then Limit:=-1
              else if (Seznam[0].Category = 4) then Limit:=1 else Limit:=0;
           end;
           for J:=0 to Limit do
             if (Seznam[J].Weight < PomValue) then begin
               Seznam[J].Weight:=PomValue; Seznam[J].Category:=2;
               if (PomValue > 3) then PomValue:=PomValue - PomValue/2
               else PomValue:=0;
             end;

           { *** nyni A *** }
           PomValue:=_A;
           if (RacesTGInfo^[Race,I].ALock > 1) then PomValue:=PomValue/RacesTGInfo^[Race,I].ALock;
           if (RacesTGInfo^[Race,I].Lock <= 2) then Limit:=MaxSeznam else Limit:=0;
           if (I = 12) then begin
              if (RacesTGInfo^[Race,I].Lock > 0)  then Limit:=-1
              else if (Seznam[0].Category = 4) then Limit:=1 else Limit:=0;
           end;
           for J:=0 to Limit do
             if (Seznam[J].Weight < PomValue) then begin
               Seznam[J].Weight:=PomValue; Seznam[J].Category:=3;
               if (PomValue > 3) then PomValue:=PomValue - PomValue/2
               else PomValue:=0;
             end;
        end;

        { nyni ostraneni posledni polozky, je-li shodna s predchozimi
          (t.j. kopie tehoz typu) }
        AllSame:=True;
        for J:=1 to MaxSeznam do
          if (Seznam[J].Category <> Seznam[J-1].Category)
          then AllSame:=False;
        if ((AllSame) and (Seznam[MaxSeznam].Weight > 0))
        then Seznam[MaxSeznam].Weight:=0;

        case (GroupType) of
           TGDefence : begin Priority:=ProductionPriorityMedium; end;
           TGAttack  : begin Priority:=ProductionPriorityMedium; end;
           TGSaboteur: begin Priority:=ProductionPriorityMedium; end;
           TGPlus    : begin Priority:=ProductionPriorityMedium; end;
           TGRecon   : begin Priority:=ProductionPriorityMedium; end;
           TGPara    : begin Priority:=ProductionPriorityMedium; end;
        else
           Priority:=ProductionPriorityMedium;
        end;

        { nyni nahodne vygenerovani carrieru }
        RndNum:=Rand(RndUk) mod 3;
        if (RndNum = 0) then RndNum:=L else RndNum:=U;

        for J:=0 to MaxSeznam do with (Seznam[J]) do
        if (Weight > 0.5) then begin
           if (J > 0) then  begin  { posil flag obrannych instalaci }
             Inc(DefInstalPriorityFlag);
             if (DefInstalPriorityFlag > 100) then DefInstalPriorityFlag:=0;
           end;
           { normalni bojove typy mohou byt  0..4 }
           if (GroupType = TGSaboteur) then begin
              Mat:=4;
              if (TrueSaboteur) then Typ:=1 else Typ:=Rand(RndUk) mod 5;
              case (Category) of
                 0 : begin { _AA }
                       if (TrueSaboteur) then Typ:=13 else Typ:=Rand(RndUk) mod 6;
                       if (not Prepare_production(Race,U,13,Mat,Priority,I,0))
                       then begin
                          if (TrueSaboteur) then Typ:=5 else Typ:=Rand(RndUk) mod 6;
                          Prepare_production(Race,U,Typ,Mat,Priority,I,0);
                       end;
                     end;
                 1 : { _L }
                     if (not Prepare_production(Race,L,Typ,Mat,Priority,I,2))
                     then
                       if (not Prepare_production(Race,L_T,Typ,Mat,Priority,I,2))
                       then Prepare_production(Race,L,Rand(RndUk) mod 5,Mat,Priority,I,2);
                 2 : { _T }
                     if (not Prepare_production(Race,T,Typ,Mat,Priority,I,3))
                     then
                       if (not Prepare_production(Race,L_T,Typ,Mat,Priority,I,3))
                       then Prepare_production(Race,T,Rand(RndUk) mod 5,Mat,Priority,I,3);
                 3 : { _A }
                     if (not Prepare_production(Race,U,13,Mat,Priority,I,1))
                     then
                       if (not Prepare_production(Race,U,Typ,Mat,Priority,I,1))
                       then Prepare_production(Race,U,Rand(RndUk) mod 5,Mat,Priority,I,1);
                 4 : { carrier }
                     { preferujeme vzdusny carrier }
                      if (not Prepare_production(Race,U,14,Mat,Priority,I,4)) then
                        if (not Prepare_production(Race,L,6,Mat,Priority,I,4)) then
                           Prepare_production(Race,T,6,Mat,Priority,I,4);
              end;
           end else begin
              if (GroupType = TGPara) then begin
                  Mat:=4; Typ:=15; { para }
                  case (Category) of
                     0 : begin { _AA }
                           Prepare_production(Race,U,Typ,Mat,Priority,I,0);
                         end;
                     1 : { _L }
                           Prepare_production(Race,U,Typ,Mat,Priority,I,2);
                     2 : { _T }
                           Prepare_production(Race,U,Typ,Mat,Priority,I,3);
                     3 : { _A }
                           if ((Races[Race].ParaEnabled and 48) shr 4 > Fighters)
                           then Prepare_production(Race,L,17,Mat,Priority,I,1)
                           else
                             if ((Races[Race].ParaEnabled and 192) shr 6 > Terminators)
                             then Prepare_production(Race,L,18,Mat,Priority,I,1);{}
                     4 : { carrier }
                           Prepare_production(Race,N,16,Mat,Priority,I,4);
                  end;
              end else begin
                 Typ:=Rand(RndUk) mod 5;
                 if (Rand(RndUk) mod 5 = 0) then Mat:=1
                 else
                   if (Rand(RndUk) mod 3 = 0) then Mat:=2
                   else Mat:=4;

                 case (Category) of
                    0 : begin{ _AA }
                          Typ:=Rand(RndUk); if (Typ > 5) then Typ:=5;{}
                          if (not Prepare_production(Race,U,Typ,Mat,Priority,I,0))
                          then Prepare_production(Race,U,5,Mat,Priority,I,0);
                        end;
                    1 : { _L }
                        if (not Prepare_production(Race,L,Typ,Mat,Priority,I,2))
                        then
                          if (not Prepare_production(Race,L,Rand(RndUk) mod 5,Mat,Priority,I,2))
                          then
                            if (not Prepare_production(Race,L,Rand(RndUk) mod 5,Mat,Priority,I,2))
                            then Prepare_production(Race,L_T,Rand(RndUk) mod 5,Mat,Priority,I,2);
                    2 : { _T }
                        if (not Prepare_production(Race,T,Typ,Mat,Priority,I,3))
                        then
                          if (not Prepare_production(Race,T,Rand(RndUk) mod 5,Mat,Priority,I,3))
                          then
                            if (not Prepare_production(Race,T,Rand(RndUk) mod 5,Mat,Priority,I,3))
                            then Prepare_production(Race,L_T,Rand(RndUk) mod 5,Mat,Priority,I,3);
                    3 : { _A }
                        if (not Prepare_production(Race,U,13,Mat,Priority,I,1))
                        then
                          if (not Prepare_production(Race,U,Typ,Mat,Priority,I,1))
                          then
                            Prepare_production(Race,U,Rand(RndUk) mod 5,Mat,Priority,I,1);
                    4 : begin { carrier }
                          if (RndNum = U) then begin
                             if (Rand(RndUk) < 4) then Typ:=14 else Typ:=6
                          end else Typ:=6;
                          if (Rand(RndUk) mod 3 = 0) then Mat:=3
                          else Mat:=4;
                          if (not Prepare_production(Race,RndNum,Typ,Mat,Priority,I,4)) then
                            if (not Prepare_production(Race,U,6,Mat,Priority,I,4)) then
                               Prepare_production(Race,L_T,6,Mat,Priority,I,4);
                        end;
                 else
                 end;
              end;
           end;
        end;

        if ((_AA <= 0) and (_A <= 0) and (_LL <= 0) and (_L <= 0) and (_H <= 0) and
            (Command <> WaitCom))
        then begin { jsme silnejsi nez nepritel -> zautoc }
          if (RacesTGInfo^[Race,I].ActivityGameTime <=
              (LongInt(Min_game_time)*60+Sec_game_time))
          then begin { odpovida nacasovani utoku ? }
             if (GroupType = TGSaboteur) then begin { sabotazni skupina }
                TaskGroupCommand(Race,I,AttackCom,0,2,ITargPlace,JTargPlace,RacesTGInfo^[Race,I].MoveCourageSabot);
                { predposledni dve hodnoty jsou souradnice cile; posledni je % ignorace }
                ProductionManager.ClearAllTGProduction(Race,I);
             end else { klasicka skupina }
               if (GroupType = TGAttack){ or (GroupType = TGDefence)){} then begin
                 { normalni skupiny  }
                 TaskGroupCommand(Race,I,AttackCom,0,2,ITargPlace,JTargPlace,RacesTGInfo^[Race,I].MoveCourageNormal);
                 { predposledni dve hodnoty jsou souradnice cile; posledni je % ignorace }
                 ProductionManager.ClearAllTGProduction(Race,I);
               end;
          end;
        end;
    end;

    Validity:=False;
    for I:=0 to K do
      if ((TaskGroups^[I].Validity) or (RacesTGInfo^[Race,I].Lock <> 0))
      then Validity:=True;
    if (not Validity) then begin
    { pokud neexistuje zadna TG, preferuj vyrobu obrannych instalaci }
      Inc(DefInstalPriorityFlag);
      if (DefInstalPriorityFlag > 100) then DefInstalPriorityFlag:=0;
    end;
  end; { with (Races[Race]) do begin }
Konec:
end;

{ ***** }
procedure Globa_eval;
{ globalne zhodnoti nepratelske sily a vlastni sily a stanovi pomer mezi nimi
}
var I,J:Word;
    Pom2, Pom3:Single;
    RacStr: array[0..MaxRace] of Single;
    AverageFriendlyStr,AverageCompStr:Single;
    MaxFriendlyStr,MaxCompStr:Single;
    FriendlyCount, CompCount:Single;
begin
   GlobalComp:=0; GlobalFriend:=0;
   { globalni sila pocitace+friends: }
   GlobalCompLLight:=0; GlobalCompLight:=0; GlobalCompHeavy:=0;
   GlobalCompAir:=0; GlobalCompAAttack:=0;
   { globalni sila OSN+friends: }
   GlobalFriendLLight:=0; GlobalFriendLight:=0; GlobalFriendHeavy:=0;
   GlobalFriendAir:=0; GlobalFriendAAttack:=0;
   GlobalCompGroundPct:=0; GlobalFriendGroundPct:=0;

   for I:=0 to IInfoArraySize-1 do
     for J:=0 to JInfoArraySize-1 do with (MapInfo^[I,J]) do begin
        { * nejprve jednotky pocitace * }
        Pom3:=0; Pom3:=Pom3+VLLight[0]+HLLight[0];
        Pom2:=VLLight[1]+HLLight[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=VLLight[2]+HLLight[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalComp:=GlobalComp+Pom3*DangerLimitLLCoef;
        GlobalCompLLight:=GlobalCompLLight+Pom3*DangerLimitLLCoef;
        Pom3:=0; Pom3:=Pom3+VLight[0]+HLight[0];
        Pom2:=VLight[1]+HLight[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=VLight[2]+HLight[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalComp:=GlobalComp+Pom3*DangerLimitLCoef;
        GlobalCompLight:=GlobalCompLight+Pom3*DangerLimitLCoef;
        Pom3:=0; Pom3:=Pom3+VHeavy[0]+HHeavy[0];
        Pom2:=VHeavy[1]+HHeavy[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=VHeavy[2]+HHeavy[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalComp:=GlobalComp+Pom3*DangerLimitHCoef;
        GlobalCompHeavy:=GlobalCompHeavy+Pom3*DangerLimitHCoef;
        Pom3:=0; Pom3:=Pom3+VAir[0]+HAir[0];
        Pom2:=VAir[1]+HAir[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=VAir[2]+HAir[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalComp:=GlobalComp+Pom3*DangerLimitACoef;
        GlobalCompAir:=GlobalCompAir+Pom3*DangerLimitACoef;
        Pom3:=0; Pom3:=Pom3+VAAttack[0]+HAAttack[0];
        Pom2:=VAAttack[1]+HAAttack[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=VAAttack[2]+HAAttack[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalComp:=GlobalComp+Pom3*DangerLimitAACoef;
        GlobalCompAAttack:=GlobalCompAAttack+Pom3*DangerLimitAACoef;

        { * nyni jednotky moje a spojencu * }
        Pom3:=0; Pom3:=Pom3+EnemyVLLight[0]+EnemyHLLight[0];
        Pom2:=EnemyVLLight[1]+EnemyHLLight[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=EnemyVLLight[2]+EnemyHLLight[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalFriend:=GlobalFriend+Pom3*DangerLimitLLCoef;
        GlobalFriendLLight:=GlobalFriendLLight+Pom3*DangerLimitLLCoef;
        Pom3:=0; Pom3:=Pom3+EnemyVLight[0]+EnemyHLight[0];
        Pom2:=EnemyVLight[1]+EnemyHLight[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=EnemyVLight[2]+EnemyHLight[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalFriend:=GlobalFriend+Pom3*DangerLimitLCoef;
        GlobalFriendLight:=GlobalFriendLight+Pom3*DangerLimitLCoef;
        Pom3:=0; Pom3:=Pom3+EnemyVHeavy[0]+EnemyHHeavy[0];
        Pom2:=EnemyVHeavy[1]+EnemyHHeavy[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=EnemyVHeavy[2]+EnemyHHeavy[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalFriend:=GlobalFriend+Pom3*DangerLimitHCoef;
        GlobalFriendHeavy:=GlobalFriendHeavy+Pom3*DangerLimitHCoef;
        Pom3:=0; Pom3:=Pom3+EnemyVAir[0]+EnemyHAir[0];
        Pom2:=EnemyVAir[1]+EnemyHAir[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=EnemyVAir[2]+EnemyHAir[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalFriend:=GlobalFriend+Pom3*DangerLimitACoef;
        GlobalFriendAir:=GlobalFriendAir+Pom3*DangerLimitACoef;
        Pom3:=0; Pom3:=Pom3+EnemyVAAttack[0]+EnemyHAAttack[0];
        Pom2:=EnemyVAAttack[1]+EnemyHAAttack[1]; Pom3:=Pom3+Round(Pom2*DangerLimit1Coeff);
        Pom2:=EnemyVAAttack[2]+EnemyHAAttack[2]; Pom3:=Pom3+Round(Pom2*DangerLimit2Coeff);
        GlobalFriend:=GlobalFriend+Pom3*DangerLimitAACoef;
        GlobalFriendAAttack:=GlobalFriendAAttack+Pom3*DangerLimitAACoef;
     end;

     if (GlobalComp > 0) then
        GlobalCompGroundPct:=100-GlobalCompAir/(GlobalComp/100)
     else GlobalCompGroundPct:=100;
     if (GlobalFriend > 0) then
       GlobalFriendGroundPct:=100-GlobalFriendAir/(GlobalFriend/100)
     else GlobalFriendGroundPct:=100;
     { ve GlobalFriend a GlobalComp jsou souhrne informace o sile mne+spojencu a pocitace }

     AverageFriendlyStr:=0; AverageCompStr:=0;
     MaxFriendlyStr:=0; MaxCompStr:=0;
     for I:=0 to MaxRace do begin
       RacStr[I]:=0;
       for J:=1 to MaxTypesOfUnits do RacStr[I]:=RacStr[I]+Races[I].ExistUnits[J];
       { nyni nejake "civilni" jednotky vyhodime: }
       RacStr[I]:=RacStr[I]-Races[I].ExistUnits[2]; { recyklator }
       RacStr[I]:=RacStr[I]-Races[I].ExistUnits[3]; { civilista }
       RacStr[I]:=RacStr[I]-Races[I].ExistUnits[4]; { osobni auto }
       if ((I = MyRace) or (I = ThisCompRace1) or (I = ThisCompRace2) or
           (I = ThisCompRace3) or (I = ThisCompRace4) or (I = ThisCompRace5))
       then begin
          if (Races[I].Ally = 1) then begin
             AverageFriendlyStr:=AverageFriendlyStr+RacStr[I];
             if (MaxFriendlyStr < RacStr[I]) then
               MaxFriendlyStr:=RacStr[I];
          end else begin
             AverageCompStr:=AverageCompStr+RacStr[I];
             if (MaxCompStr < RacStr[I]) then
               MaxCompStr:=RacStr[I];
          end;
       end;
     end;
     {x}
     AverageCompStr:=AverageCompStr/TotalRobotRaces;
     AverageFriendlyStr:=AverageFriendlyStr/TotalOSNRaces;
     {x}
     if (AverageFriendlyStr <> 0) then
       FriendlyCount:=MaxFriendlyStr/AverageFriendlyStr
     else FriendlyCount:=1;
     if (FriendlyCount > TotalOSNRaces) then FriendlyCount:=TotalOSNRaces;
     FriendlyCount:=TotalOSNRaces/FriendlyCount;
     {}
     if (AverageCompStr <> 0) then
       CompCount:=MaxCompStr/AverageCompStr
     else CompCount:=1;
     if (CompCount > TotalRobotRaces) then CompCount:=TotalRobotRaces;
     CompCount:=TotalRobotRaces/CompCount;

     for I:=0 to MaxRace do begin
      for J:=0 to 12 do begin { utocne, obranne, sabotazni, doplnovaci a para TG }
         if ((not Races[I].Neutral) and (J <> 11)) then { nejde o neutrala }
         with (RacesTGInfo^[I,J]) do begin
           if (J > 3) then begin
           { obranne a sabotazni a para TG }
              if (J = 12) then begin { para TG }
                 case (Races[I].ParaEnabled and 6) of
                    0 : TGMinLimit:=4.0-0.05*Rand(RndUk);
                    2 : TGMinLimit:=6.0-0.05*Rand(RndUk);
                    4 : TGMinLimit:=8.0-0.05*Rand(RndUk);
                    6 : TGMinLimit:=10.0-0.05*Rand(RndUk);
                 else
                    TGMinLimit:=3.2-0.05*Rand(RndUk);
                 end;
              end else begin
                 if ((J > 7) and (J < 10)) then begin
                    TGMinLimit:=6.2-0.3*Rand(RndUk); { saboteur }
                 end else begin
                    if ((J = 10) and (TGDefenseLimitModif = 1)) then begin
                    { mene limitovana sila TG Plus }
                      if (Races[I].Ally = 1) then begin
                        if (GlobalComp/CompCount < 10) then
                          TGMinLimit:=GlobalComp/CompCount+10
                        else TGMinLimit:=GlobalComp/CompCount+5;
                      end else begin
                        if (GlobalFriend/FriendlyCount < 10) then
                          TGMinLimit:=GlobalFriend/FriendlyCount+10
                        else TGMinLimit:=GlobalFriend/FriendlyCount+5;
                      end;
                    end else begin
                    { normalne limitovana sila taskgroup }
                      if (Races[I].Ally = 1) then begin
                        if (TGDefenseLimitModif = 0) then
                          TGMinLimit:=(GlobalComp/CompCount)
                        else
                          TGMinLimit:=(GlobalComp/CompCount) / TGDefenseLimitModif
                      end else begin
                        if (TGDefenseLimitModif = 0) then
                          TGMinLimit:=(GlobalFriend/FriendlyCount)
                        else
                          TGMinLimit:=(GlobalFriend/FriendlyCount) / TGDefenseLimitModif;
                      end;
                    end;
                 end;
              end;
           end else begin
              { utocne TG }
              if (Races[I].Ally = 1) then
                TGMinLimit:=(GlobalComp/CompCount) / 3
              else
                TGMinLimit:=(GlobalFriend/FriendlyCount) / 3;
           end;
         end;
      end;
     end; {for I:=0 to MaxRace do begin}
end;

{ ***** }
procedure SetAttackFlagForPlaceForBuilding(Race:Byte; IP,JP:Word);
{ pro rasu Race najde nejblizsi stred k pozici IP,JP a nastavi u nej
  priznak, ze na zakladnu se "utoci"
}
var I,J,Delta,PomDelta:Word;
    Konec:Boolean;
begin
  with (Races[Race]) do begin
  { nejprve nalezneme nejblizsi vhodnou oblast }
    if (ActualFreeStructures = 0) then
    else begin
      J:=0; Delta:=65535;
      for I:=0 to (ActualFreeStructures-1) do with (FreePlaces^[0,I]) do begin
        {PomDelta:=abs((Integer(X)-IP)+(Integer(Y)-JP));
        if (PomDelta < Delta) then begin
           Delta:=PomDelta; J:=I;
        end;{}
        PlaceType:=80;
      end;
      { nalezen seznam s nejblizsi polohou (promenna J) }
      {FreePlaces[0,J].PlaceType:=80;{}

    end; { if (ActualFreeStructures = 0) then ... else ... }
  end; { with (Races[Race]) do begin }
end;

{ ***** }
function NotEnoughFreePlaces(Race:Byte; Request:Byte):Boolean;
{ vraci True, pokud neni dostatek volneho mista
}
label AGAIN;
const ExchangeDistance1_2 = 15; { jedna se minimalni vzdalenost, o kterou
     musi byt volne pole v kategorii 2 blizsi k pozici budovy nez pole
     zatim vybrane typu 1 (chceme 1), aby se mu dala prednost }
      ExchangeDistance2_1 = 12; { viz nahore pro vymenu pole 2 za 1 }
      ExchangeDistance3_x = 12; { viz nahore pro vymenu pole 3 za 1,2}
      Priority1_2 = 5; { pro request 3 vezmu radeji o 5 poli typ 2 nez 1 }
      Priority2_3 = 3; { pro request 4 vezmu radeji o 3 pole typ 3 nez 2 }
      ExchangeDistance4_x = 12; { viz nahore pro vymenu pole 4 za 1,2,3 }
var I,J, IP, JP, IAdept, JAdept, AdeptPlaceType, Delta, PomDelta:Word;
    Konec:Boolean;
begin
AGAIN:
  with (Races[Race]) do begin
  { nejprve nalezneme nejblizsi vhodnou oblast }
    if (ActualFreeStructures = 0) then NotEnoughFreePlaces:=True
    else with (Races[Race]) do begin
      IAdept:=65535; JAdept:=65535; Delta:=65535; AdeptPlaceType:=0;
      for J:=0 to ActualFreeStructures-1 do
        if (FreePlaces^[0,J].PlaceType = 0) then
        for I:=0 to MaxFreePlaces do with (FreePlaces^[I,J]) do begin
           if ((PlaceType > 0) and (I > 0)) then begin
           { jde o platnou polozku }
              IP:=FreePlaces^[0,J].X; JP:=FreePlaces^[0,J].Y;
              PomDelta:=GetDistance(IP,JP,X,Y);
              case (Request) of
                 1 : begin { zadost: 64x64, vyrobni }
                       case (PlaceType) of
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((PomDelta < Delta) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 2) and
                                   (PomDelta < (Delta+ExchangeDistance1_2)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 2) and(PomDelta < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 1) and
                                   ((PomDelta+ExchangeDistance1_2) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 2 : begin { zadost: 64x64, nevyrobni }
                       case (PlaceType) of
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((PomDelta < Delta) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 1) and
                                   (PomDelta < (Delta+ExchangeDistance2_1)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < Delta)or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 2) and
                                   ((PomDelta+ExchangeDistance2_1) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 3 : begin { zadost: 64x32 }
                       case (PlaceType) of
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < Delta) or
                                   (AdeptPlaceType = 2)and((PomDelta+Priority1_2) < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 3) and
                                   ((PomDelta+ExchangeDistance3_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < (Delta+Priority1_2)) or
                                    (AdeptPlaceType = 2)and(PomDelta < Delta) or
                                    (AdeptPlaceType = 0) or
                                    (AdeptPlaceType = 3) and
                                    ((PomDelta+ExchangeDistance3_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                          3 : begin { PlaceType zpracovavaneho pole }
                               if ((PomDelta < Delta) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType < 3) and
                                   (PomDelta < (Delta+ExchangeDistance3_x)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 4 : begin { zadost: 32x32 }
                       case (PlaceType) of
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < Delta) or
                                   (AdeptPlaceType = 2)and((PomDelta+Priority1_2) < Delta) or
                                   (AdeptPlaceType = 3)and((PomDelta+Priority1_2+Priority2_3) < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 4) and
                                   ((PomDelta+ExchangeDistance4_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < (Delta+Priority1_2)) or
                                   (AdeptPlaceType = 2)and(PomDelta < Delta) or
                                   (AdeptPlaceType = 3)and((PomDelta+Priority2_3) < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 4) and
                                   ((PomDelta+ExchangeDistance4_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                          3 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < (Delta+Priority1_2+Priority2_3)) or
                                   (AdeptPlaceType = 2)and(PomDelta < (Delta+Priority2_3)) or
                                   (AdeptPlaceType = 3)and(PomDelta < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 4) and
                                   ((PomDelta+ExchangeDistance4_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                          4 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 0) or
                                   (AdeptPlaceType < 4)and(PomDelta < (Delta+ExchangeDistance4_x)) or
                                   (PomDelta < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 5 : begin { zadost: 64x64, letiste }
                       if ((PlaceType = 5) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 6 : begin { zadost: 64x64, radar }
                       if ((PlaceType = 6) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 7 : begin { zadost: SAM-lehka pevnost, priorita 1 }
                       if ((PlaceType = 7) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 8 : begin { zadost: SAM-lehka pevnost, priorita 2 }
                       if ((PlaceType = 8) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 9 : begin { zadost: SAM-lehka pevnost, priorita 3 }
                       if ((PlaceType = 9) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 10: begin { zadost: Raketova vez-tezka pevnost, priorita 1 }
                       if ((PlaceType = 10) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 11: begin { zadost: Raketova vez-tezka pevnost, priorita 2 }
                       if ((PlaceType = 11) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 12: begin { zadost: Raketova vez-tezka pevnost, priorita 3 }
                       if ((PlaceType = 12) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 13 : begin { zadost: 96x96, vyrobni }
                       case (PlaceType) of
                         13 : begin { PlaceType zpracovavaneho pole }
                               if ((PomDelta < Delta) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 14) and
                                   (PomDelta < (Delta+ExchangeDistance1_2)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                         14 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 14) and(PomDelta < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 13) and
                                   ((PomDelta+ExchangeDistance1_2) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 14 : begin { zadost: 96x96, nevyrobni }
                       case (PlaceType) of
                         14 : begin { PlaceType zpracovavaneho pole }
                               if ((PomDelta < Delta) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 13) and
                                   (PomDelta < (Delta+ExchangeDistance2_1)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                         13 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 13)and(PomDelta < Delta)or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 14) and
                                   ((PomDelta+ExchangeDistance2_1) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta;
                               end;
                             end;
                       end;
                     end;
                 15: begin { zadost: elektrarny }
                       if ((PlaceType = 15) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 16: begin { zadost: recyklace }
                       if ((PlaceType = 16) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 17: begin { zadost: centrum posil }
                       if ((PlaceType = 17) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 20: begin { zadost: centrum posil }
                       if ((PlaceType = 16) and (PomDelta < Delta)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
              end;{ case }
           end;
        end; { posledniho for }

        if (AdeptPlaceType <> 0) then { uspech ! }
           NotEnoughFreePlaces:=False
        else begin
          if (Request = 15) then begin { elektrarny lze uspokojit i jinak }
            Request:=14; GoTo AGAIN;
          end;
          if (Request = 16) then begin { recyklaci lze uspokojit i jinak }
            Request:=13; GoTo AGAIN;
          end;
          NotEnoughFreePlaces:=True;
        end;
    end; { if (ActualFreeStructures = 0) then ... else ... }
  end; { with (Races[Race]) do begin }
end;

{ ***** }
function TGEmptyCarriers(Race,TGNum:Byte):Byte;
{ vraci pocet nenalozenych carrieru v taskgrupe
}
var Count:Byte;
    Pom:PUNit;
begin
   Count:=0;
   with (Races[Race]) do with (TaskGroups^[TGNum]) do if (Validity) then begin
      Pom:=Carriers;
      while (Pom <> Nil) do begin
        if (Pom^.UnitsInsideNum = 0) then Inc(Count);
        Pom:=Pom^.Next;
      end;
   end;
   TGEmptyCarriers:=Count;
end;

{ ***** }
function TGCarriers(Race,TGNum:Byte):Byte;
{ vraci pocet nenalozenych carrieru v taskgrupe
}
var Count:Byte;
    Pom:PUNit;
begin
   Count:=0;
   with (Races[Race]) do with (TaskGroups^[TGNum]) do if (Validity) then begin
      Pom:=Carriers;
      while (Pom <> Nil) do begin
        Inc(Count); Pom:=Pom^.Next;
      end;
   end;
   TGCarriers:=Count;
end;

{ ***** }
procedure AI2_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'17'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,UnitParams,SizeOf(UnitParams));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure AI2_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'17'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockRead(IOFile,UnitParams,SizeOf(UnitParams));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************** }
begin
   ProductionManager.Init;
end.