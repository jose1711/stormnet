unit AI;
{ jednotka pro obsluhu umele inteligence }
{$C FIXED PRELOAD PERMANENT}
interface
uses Data,_units, Grafika2, Buttons, Buttons2;
type
      TProductionList = array[0..MaxProductionListIndex,
                              0..MaxProductionListPriority,
                              0..MaxRace] of record
                         TaskGrp:Byte; { cislo taskgrupy, do ktere se vyrobek
                                         zaradi; 255 = nova taskgrupa }
                         TaskCom:Byte; { cislo taskgrupy, do ktere se vyrobek
                                         zaradi; 255 = nova taskgrupa }
                         BuilderType:Byte; { typ vyrobni tovarny }
                         ProductType:Byte; { typ vyrobku (jeho cislo); jde-li
                         o plastarnu a maji se produkovat plasty, pak 255
                         znaci zastaveni produkce plastu, jinak zahajeni }
                         Validity:Boolean; { True, je-li tato slozka fronty
                                             platna! }
                         Counter:Word; { pocitadlo }
                         LockTyp:Byte; { typ locku taskrupy: (ucinnost proti)
                            0..AA
                            1..A
                            2..L
                            3..H
                            4..Carrier
                         }
                       end;

      TProductionManager= object
                          public
                            P:^TProductionList;
                          public
                            procedure Init;
                            procedure Insert(Race,Priority:Byte;
                                             TaskGr, TaskComm,
                                             BuilderTyp, ProductTyp,LockType:Byte);
                            procedure Execute(Race:Byte);
                            procedure Reorganize(Race:Byte);
                            procedure ClearAllTGProduction(Race,TaskGr:Byte);
                        end;

var ProductionManager : TProductionManager;

function Production_ai_manager(Race,BuilderType,ProductType,TaskGrp,TaskCom,LockTyp:Byte):Boolean;
function GetFreePlaceForBuilding(Race:Byte; var IP,JP:Word; Request:Byte; Get:Boolean):Boolean;
procedure AddFreePlaceForBuilding(Race:Byte; IP,JP:Word; Request,Dir:Byte);
function CreateNewTaskGroup(Race,Num:Byte; var _unit:PUnit):Byte;
procedure AssignTaskGroup(Race,TaskGroupNum:Byte; var _unit:PUnit);
procedure InvalidateTaskGroup(Race,TaskGrp:Byte);
procedure TaskGroupCommand(Race,TaskGrp,TaskCommand,Level,Mode:Byte; IP,JP:Word;
                           IgnoreCoeff:Double);
procedure ExecuteTaskGroupCommand(var _unit:PUnit);
procedure CheckExecuteTaskGroupCommand(var _unit:PUnit);
procedure AI_manager;
procedure AI_save;
procedure AI_load;

{ ********** }
implementation
uses _units2, _units3, _races, Graph257, AI2,  AI3;

const Build_weigth_div = 30; { v podstate se touto hodnotou deli vaha
                               nepratelskych budov, abychom ziskali
                               urcite vztazne hodnoty; }
type TOptiInfo = array[0..IInfoArraySize-1,0..JInfoArraySize-1] of record
                 { pro optimalizaci operaci vyhledavani cesty pocitacem
                   (uchova se zde Get_surroundings) }
                     Valid:Boolean;
                     Value:Single;
                 end;
var MainZero:Boolean;
    I,J,IPom:Word;
    OptiINfo:^TOptiInfo;
    TGActiveSearching: record
    { taskgrupa, ktere ma byt v tomto cyklu inteligentne pridelen cil
       pro utok }
                          Validity:Boolean; { platnost }
                          Race:Byte;
                          TGNumber:BYte;
                       end;
    SurrPct :Single;  { pri inteligentnim hledani cile je to vaha, kterou se
                      nasobi sila nepratel v bezprostrednim okoli
                      (vlastni pole ma vahu 1) }

{ ************************************************************************** }
{ xxx }
procedure TProductionManager.Init;
{ inicializace objektu
}
var I,J,K:Word;
begin
   New(P);
   for K:=0 to MaxRace do begin
     for I:=0 to MaxProductionListIndex do
       for J:=0 to MaxProductionListPriority do begin
          P^[I,J,K].Validity:=False;
       end;
   end;
end;

{ *** }
procedure TProductionManager.Insert(Race,Priority:Byte; TaskGr,TaskComm,BuilderTyp,
                                    ProductTyp,LockType:Byte);
{ vlozi danou polozku do pole, priorita Priority.
  TaskGr je cislo TaskGrupy pro prideleni, BuilderTyp je typ tovarny,
  v niz se ma produkt ProductTyp vyrabet. Je-li BuilderTyp = plastarna,
  vyrabi se plasty.
}
var I:Word;
begin
   I:=0;
   with (Races[Race]) do begin
     if (Building_types[BuilderTyp].ProductionType = 1) then begin
     { * pokus o vyrobu budov - jedna pozice ze tri }
        while ((I <= MaxProductionListIndex) and
               P^[I,Priority,Race].Validity) do Inc(I,3);

        if (I > MaxProductionListIndex) then  { chyba - neni volne misto }
           Error(0,'unita Ai, procedura ProductionListInsert, bod 1')
        else with (P^[I,Priority,Race]) do begin{ zarad prvek do seznamu }
           Validity:=True; TaskGrp:=TaskGr; TaskCom:=TaskComm;{}
           BuilderType:=BuilderTyp; ProductType:=ProductTyp; Counter:=0;
           LockTyp:=255;
        end;
     end else
       if (Building_types[BuilderTyp].ProductionType = 0) then begin
       { ** pokus o vyrobu jednotek }
         if (Unit_types[ProductTyp,Races[Race].Ally].UnitLevel = 255) then begin
         { obranne instalace - veze, pevnosti... - tam kde je misto }
           if (Race = 1) then
                Race:=Race;

           while ((I <= MaxProductionListIndex) and
                  P^[I,Priority,Race].Validity) do Inc(I);

           if (I > MaxProductionListIndex) then  { chyba - neni volne misto }
              Error(0,'unita Ai, procedura ProductionListInsert, bod 3')
           else with (P^[I,Priority,Race]) do begin{ zarad prvek do seznamu }
              Validity:=True; TaskGrp:=TaskGr; TaskCom:=TaskComm;{}
              BuilderType:=BuilderTyp; ProductType:=ProductTyp; Counter:=0;
              LockTyp:=255;
           end;
         end else begin
         { * pokus o vyrobu normalnich jednotek - tam kde je misto }
            while ((I <= MaxProductionListIndex) and
                   P^[I,Priority,Race].Validity) do Inc(I);

            if (I > MaxProductionListIndex) then  { chyba - neni volne misto }
               Error(0,'unita Ai, procedura ProductionListInsert, bod 3')
            else with (P^[I,Priority,Race]) do begin{ zarad prvek do seznamu }
               Validity:=True; TaskGrp:=TaskGr; TaskCom:=TaskComm;{}
               BuilderType:=BuilderTyp; ProductType:=ProductTyp; Counter:=0;
               LockTyp:=LockType;
               case (LockTyp) of
                   0 : if (TaskGrp <= 12)
                       then Inc(RacesTGInfo^[Race,TaskGrp].AALock);
                   1 : if (TaskGrp <= 12)
                       then Inc(RacesTGInfo^[Race,TaskGrp].ALock);
                   2 : if (TaskGrp <= 12)
                       then Inc(RacesTGInfo^[Race,TaskGrp].LLock);
                   3 : if (TaskGrp <= 12)
                       then Inc(RacesTGInfo^[Race,TaskGrp].HLock);
                   4 : if (TaskGrp <= 12)
                       then Inc(RacesTGInfo^[Race,TaskGrp].CLock);
               end;
            end;
         end;
       end else begin
       { vyroba plastu, hleda se klasicky volne misto }
           while ((I <= MaxProductionListIndex) and
                  P^[I,Priority,Race].Validity {and
                  (P^[I,Priority,Race].ProductType <> ProductTyp){}) do Inc(I);

           if (I > MaxProductionListIndex) then  { chyba - neni volne misto }
              Error(0,'unita Ai, procedura ProductionListInsert, bod 4')
           else with (P^[I,Priority,Race]) do begin{ zarad prvek do seznamu }
              Validity:=True; TaskGrp:=TaskGr; TaskCom:=TaskComm;{}
              BuilderType:=BuilderTyp; ProductType:=ProductTyp; Counter:=0;
              LockTyp:=255;
           end;
       end;
   end;
end;

{ *** }
procedure TProductionManager.Execute(Race:Byte);
{ realizuje vyrobu dane rasy
}
var I,J:Word;
    Limit:Word;
    BP,PL,EE,EX,B,Py,E,X:Integer;
begin
  with (Races[Race]) do begin
    BP:=0; PL:=0; EE:=0; EX:=0; PLHiNeed:=0;
    { v techto promennych se zazalohuji skutecne stavy materialu; pokud
      pak nelze vyrobit nejakou produkci, nedojde ke blokovani dalsi
      produkce pri dostatecnem mnozstvi materialu }
    for J:=ProductionPriorityVeryHi downto ProductionPriorityLow do begin
       for I:=0 to MaxProductionListIndex do
       with (P^[I,J,Race]) do if (Validity) then begin
       { platny udaj v tabulce }
           EXPShortage:=0;
           if (not Production_ai_manager(Race,BuilderType,ProductType,TaskGrp,TaskCom,LockTyp))
           then begin
             Inc(PLHiNeed,PL); Inc(Counter); Limit:=800;
             if ((Building_types[BuilderType].ProductionType = 0) and
                 (ProductType <> 2)) then Limit:=500; {jednotky at cekaji mene}
             { pokud jde o nedostatek ve zkusenosti, nepujde ho jen tak
               odstranit (sniz dobu cekani, aby nedochazelo ke zbytecnemu
               blokovani) }
             if (EXPShortage <> 0) then Limit:=100;
             if ((Building_types[BuilderType].ProductionType = 1) and
                 (ProductType = 5)) { elektrarna ma vetsi limit }
             then Limit:=1000;
             if (Building_types[BuilderType].ProductionType = 2)
             then Limit:=10; { plasty se vyrazuji rychle }
             {XXX}
             if (Counter > Limit) then begin
             { * vyrazeni pozadavku z fronty  * }
                Validity:=False;
                if (Building_types[BuilderType].ProductionType = 0) then begin
                { neuspesny pokus o vyrobu jednotek }
                   if ((TaskGrp <= MaxRaceTaskGroups) and (RacesTGInfo^[Race,TaskGrp].Lock > 0))
                   then Dec(RacesTGInfo^[Race,TaskGrp].Lock);
                   case (ProductType) of
                   { odstranit zakaz pro danou komoditu }
                       2 : if (BPShortageForbid > 0){ recyklator }
                           then Dec(BPShortageForbid);
                       20 :if(DefendLock > 0)then Dec(DefendLock);{ lehka pevnost }
                       21 :if(DefendLock > 0)then Dec(DefendLock);{ tezka pevnost }
                       31 :if(DefendLock > 0)then Dec(DefendLock);{ raketova vez }
                       32 :if(DefendLock > 0)then Dec(DefendLock);{ SAM }
                       41 :if(CentrumPosilShortage > 0)then Dec(CentrumPosilShortage);
                   end;{}
                   case (LockTyp) of
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
                end else
                  if (Building_types[BuilderType].ProductionType = 1) then begin
                  { neuspesny pokus o vyrobu budov }
                       case (ProductType) of
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
                       end;{}
                  end else
                    if (Building_types[BuilderType].ProductionType = 2) then begin
                    { neuspesny pokus o vyrobu plastu }
                       if (PLShortageForbid > 0) then Dec(PLShortageForbid);
                    end;
             end else begin {if (Counter > xxx) then .. else }
                { *  pokud se vyroba nerealizovala, zalohujeme pro ni
                     material a umoznime vyrobu (staci-li zbytek materialu)
                     produktu s nizsi prioritou  * }
                B:=0; Py:=0; E:=0; X:=0;
                if (Building_types[BuilderType].ProductionType = 0) then
                with (Unit_types[ProductType,Races[Race].Ally]) do begin
                {  vyroba jednotek }
                   B:=BP; Py:=PL; E:=EE; X:=EX;
                end else
                  if (Building_types[BuilderType].ProductionType = 1) then
                  with (Building_types[ProductType]) do begin
                  { vyroba budov }
                    B:=BP; Py:=PL; E:=EE; X:=EX;
                  end else
                    if (Building_types[BuilderType].ProductionType = 2) then begin
                    { vyroba plastu }
                      B:=PLProductionBPNeed*10; E:=PLProductionEENeed*10;
                    end;
                { k pozadavkum pripocteme "bezpecnostnich" 5% }
                B:=B+B div 20; Py:=Py+Py div 20; E:=E; X:=X+X div 20;

                Dec(Building_credits,B); Dec(Plastic_credits,Py);
                Dec(Battle_experience,X);

                { rezervace EE vzhledem k prioritam:
                  maximalni priorita rezervuje 50% pozadovane EE,
                  prumerna priorita pak 12.5%
                }
                E:=E shr (ProductionPriorityVeryHi+1-J);

                Dec(Electric_energy,E);{}
                Inc(EE,E);{}

                Inc(BP,B); Inc(PL,Py); Inc(Ex,X);
             end;
           end else begin
           { * vyroba se realizovala * }
             Validity:=False; Reorganize(Race);
           end;
       end; { for I:=0 to MaxProductionListIndex do }
    end; { for J:=ProductionPriorityVeryHi downto ProductionPriorityLow do begin }
    Inc(Building_credits,BP); Inc(Plastic_credits,PL);
    Inc(Electric_energy,EE);{}  Inc(Battle_experience,Ex);
  end;
end;

{ ***** }
procedure TProductionManager.Reorganize(Race:Byte);
{ toto reorganizovani zajisti, aby se zajistilo spravne poradi vyroby
  objektu
}
var I,J:Word;
    FreeIndex:array[0..MaxProductionListIndex] of Byte;
    FreeIndexUk:Byte; { ukazatel na prvni zapsanou polozku }
    LastFreeIndexUk:Byte; { ukazatel na prvni volnou polozku }
begin
  with (Races[Race]) do begin
    for J:=ProductionPriorityVeryHi downto ProductionPriorityLow do begin
       FreeIndexUk:=InvalidProductionListIndex;
       LastFreeIndexUk:=0;

       for I:=0 to MaxProductionListIndex do
       with (P^[I,J,Race]) do
       if (Validity) then begin
         if ((FreeIndexUk <> InvalidProductionListIndex) and
             (FreeIndexUk < LastFreeIndexUk)) then begin
           if (Building_types[BuilderType].ProductionType = 1) then begin
           { VYROBA BUDOV }
             if ((Counter > 40) and (Counter < 150)) then begin
             { pokud neni budova ve fronte dostatecne dlouho tak
               presuneme produkci ob pozici }
               { presun dat: }
               if ((FreeIndexUk+1) < LastFreeIndexUk) then begin
                  P^[FreeIndex[FreeIndexUk+1],J,Race]:=P^[I,J,Race];
                  FreeIndex[FreeIndexUk+1]:=FreeIndex[FreeIndexUk];
                  Inc(FreeIndexUk);
                  { zneplatneni aktualni pozice }
                  P^[I,J,Race].Validity:=False;
                  { vratime uvolnene misto do seznamu: }
                  FreeIndex[LastFreeIndexUk]:=I; Inc(LastFreeIndexUk);
               end;
             end else
                if (Counter >= 150) then begin
                { pokud neni budova ve fronte dostatecne dlouho tak nepresouvat }
                  { presun dat: }
                  P^[FreeIndex[FreeIndexUk],J,Race]:=P^[I,J,Race];
                  Inc(FreeIndexUk);
                  { zneplatneni aktualni pozice }
                  P^[I,J,Race].Validity:=False;
                  { vratime uvolnene misto do seznamu: }
                  FreeIndex[LastFreeIndexUk]:=I; Inc(LastFreeIndexUk);
                end;
           end else begin
             { presun dat: }
             P^[FreeIndex[FreeIndexUk],J,Race]:=P^[I,J,Race];
             Inc(FreeIndexUk);
             { zneplatneni aktualni pozice }
             P^[I,J,Race].Validity:=False;
             { vratime uvolnene misto do seznamu: }
             FreeIndex[LastFreeIndexUk]:=I; Inc(LastFreeIndexUk);
           end;
         end;
       end else begin
       { volne misto }
         FreeIndex[LastFreeIndexUk]:=I; Inc(LastFreeIndexUk);
         if (FreeIndexUk = InvalidProductionListIndex) then FreeIndexUk:=0;
       end;
    end;
  end;
end;

{ ***** }
procedure TProductionManager.ClearAllTGProduction(Race,TaskGr:Byte);
{ tato procedura odstrani z fronty vsechny pozadavky na vyrobu objektu pro
  taskgrupu TaskGr; hodi se napr. tehdy, pokud TG zacne utocit a my nechceme,
  aby se dodatecne dovyrobene jednotky "trousily" za nami.
}
var I,J:Word;
begin
  with (Races[Race]) do begin
    for J:=ProductionPriorityVeryHi downto ProductionPriorityLow do begin
       for I:=0 to MaxProductionListIndex do
       with (P^[I,J,Race]) do if (Validity) then begin
          if (TaskGr = TaskGrp) then begin
          { ostraneni pozadavku }
              Validity:=False;
              if (Building_types[BuilderType].ProductionType = 0) then begin
              { neuspesny pokus o vyrobu jednotek }
                 if ((TaskGrp <= MaxRaceTaskGroups) and (RacesTGInfo^[Race,TaskGrp].Lock > 0))
                 then Dec(RacesTGInfo^[Race,TaskGrp].Lock);
                 case (ProductType) of
                 { odstranit zakaz pro danou komoditu }
                     2  :if (BPShortageForbid > 0) { recyklator }
                         then Dec(BPShortageForbid);
                     20 :if(DefendLock > 0)then Dec(DefendLock);{ lehka pevnost }
                     21 :if(DefendLock > 0)then Dec(DefendLock);{ tezka pevnost }
                     31 :if(DefendLock > 0)then Dec(DefendLock);{ raketova vez }
                     32 :if(DefendLock > 0)then Dec(DefendLock);{ SAM }
                     41 :if(CentrumPosilShortageForbid > 0)
                         then Dec(CentrumPosilShortageForbid);
                 end;{}
              end else
                if (Building_types[BuilderType].ProductionType = 1) then begin
                { neuspesny pokus o vyrobu budov }
                     case (ProductType) of
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
                        8 : if (PLShortageForbid > 0)  { plastarna }
                            then Dec(PLShortageForbid);
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
                     end;{}
                end else
                  if (Building_types[BuilderType].ProductionType = 2) then begin
                  { neuspesny pokus o vyrobu plastu }
                     if (PLShortageForbid > 0) then Dec(PLShortageForbid);
                  end;
          end;
       end;
    end;
  end;
end;

{ ***** }
function InfoPoleValidity(I,J:Word; AirGroup:Boolean):Boolean;
{ vraci True, je-li policko pruchodne a False, neni-li
  AirGroup =True, pokud jde o ciste leteckou TG (ignoruje PRUCHOZI = False)
}
begin
   if (((I > IMax) or (J > JMax)) or
       (not MapInfo^[I,J].Pruchozi) and (not AirGroup))
   then InfoPoleValidity:=False
   else InfoPoleValidity:=True;
end;

{ ***** }
procedure Get_taskgroup_path(IP,JP,ITar,JTar:Word; var IMov,JMov:Word;
                             var Direction:Byte; Race,TaskGrp:Byte;
                             IgnoreCoeff:Single; DirectTarget:Boolean;
                             Friend:Boolean);
{ ziska pro TaskGrupu na pozici IP,JP a o cili ITar, JTar (blokove)
  dalsi sektor pro presun (IMov, JMov)
  Direction je smer predchoziho pohybu (1-128)
  Level = 0 ... nebudou se brat v uvahu PVO schopnosti (ground level)
        = 1 ... budou se brat v uvahu PVO schopnosti
  IgnoreCoeff je sila, kterou je mozne pri presunu ignorovat
  je-li DirectTarget = False, jde se nejlepsi cestou, jinak co nejprimeji
  za cilem
  Friend = True, je-li to muj spojenec
}
label Konec;
var PomArray:array[0..4,0..4] of Single;
{ v tomto poli jsou vahy pro vyhodnoceni okoli bodu;
    aktualni pozice je 2,2 }
    DirWeight:array[0..128] of Single;
{ vahy jednotlivych smeru }
    K,L,M,N,I,J,IBeg,JBeg:Word;
    L1,M1,K1,K2,K3,K4:Single;
    BestWeight:Single;
    IBestPos,JBestPos:Word;
    BestDir,Dir:Byte;
    AirGroup:Boolean;

{ * pomocna procedura * }
function GetSurroundings(IP,JP,ITar,JTar:Word; Friend,AirGroup:Boolean):Single;
{ k poctu jednotek na tomto policku pricte vahy okoli a vse vrati jako
  parametr; je-li policko =ITar,JTar, automaticky vraci 0 (nejvyhodnejsi
  vysledek)
  Friend = True, je-li to muj spojenec
  AirGroup =True, pokud jde o ciste leteckou TG (ignoruje PRUCHOZI = False)
}
label Konec;
var Count2:Word;
    EnemyGroundPct, FriendlyGroundPct:Single; { procentuelni zastoupeni
    pozemnich jednotek ze vsech sil nepritele (spojence) na vlastnim poli }
    EnemyGroundPct2, FriendlyGroundPct2:Single; { procentuelni zastoupeni
    pozemnich jednotek ze vsech sil nepritele (spojence) v okoli vlastniho
    pole }
    Pom, Temp:Single;
    IgnoreCoefficient:Single;
begin
 if ((IP < IInfoArraySize) and (JP < JInfoArraySize)) then with (OptiInfo^[IP,JP]) do
 { optimalizace }
   if (Valid) then begin
     GetSurroundings:=Value; GoTo Konec;{}
   end;

 if (not InfoPoleValidity(IP,JP,AirGroup)) then Pom:=65535
 else begin
   { Count2 = pocet mist mimo obrazovku okolo policka
   }
   Count2:=0; EnemyGroundPct:=0; FriendlyGroundPct:=0;
   EnemyGroundPct2:=0; FriendlyGroundPct2:=0;
   GlobalInfoCount:=0;
   with (GlobalInfo[0]) do begin
      EnemyAirCount:=0; EnemyGroundCount:=0;
      FriendlyAirCount:=0; FriendlyGroundCount:=0;
      FriendlyAirStrength:=0; FriendlyGroundStrength:=0;
      EnemyAirStrength:=0; EnemyGroundStrength:=0;
      EnemyLLight:=0; EnemyLight:=0; EnemyHeavy:=0;
      EnemyAir:=0; EnemyAAttack:=0;
      EnemyBuildings:=0; FriendlyBuildings:=0; EnemySpecial:=0;
   end;
   with (GlobalInfo[1]) do begin
      EnemyAirCount:=0; EnemyGroundCount:=0;
      FriendlyAirCount:=0; FriendlyGroundCount:=0;
      FriendlyAirStrength:=0; FriendlyGroundStrength:=0;
      EnemyAirStrength:=0; EnemyGroundStrength:=0;
      EnemyLLight:=0; EnemyLight:=0; EnemyHeavy:=0;
      EnemyAir:=0; EnemyAAttack:=0;
      EnemyBuildings:=0; FriendlyBuildings:=0; EnemySpecial:=0;
   end;

   { vypocet okoli }
   GetMapInfo(IP,JP,Friend,True);
   if (JP > 0) then begin
      Pom:=0;
      if (IP > 0) then begin
        if (InfoPoleValidity(IP-1,JP-1,AirGroup)) then GetMapInfo(IP-1,JP-1,Friend,False);
      end else Inc(Count2);
      if (InfoPoleValidity(IP,JP-1,AirGroup)) then GetMapInfo(IP,JP-1,Friend,False);
      if (IP < IMapInfoMax) then begin
        if (InfoPoleValidity(IP+1,JP-1,AirGroup)) then GetMapInfo(IP+1,JP-1,Friend,False);
      end else Inc(Count2);
   end else Inc(Count2,3);
   if (IP > 0) then begin
     if (InfoPoleValidity(IP-1,JP,AirGroup)) then GetMapInfo(IP-1,JP,Friend,False);
   end else Inc(Count2);
   if (IP < IMapInfoMax) then begin
      if (InfoPoleValidity(IP+1,JP,AirGroup)) then GetMapInfo(IP+1,JP,Friend,False)
   end else Inc(Count2);
   if (JP < JMapInfoMax) then begin
      if (IP > 0) then begin
        if (InfoPoleValidity(IP-1,JP+1,AirGroup)) then GetMapInfo(IP-1,JP+1,Friend,False)
      end else Inc(Count2);
      if (InfoPoleValidity(IP,JP+1,AirGroup)) then GetMapInfo(IP,JP+1,Friend,False);
      if (IP < IMapInfoMax) then begin
        if (InfoPoleValidity(IP+1,JP+1,AirGroup)) then GetMapInfo(IP+1,JP+1,Friend,False);
      end else Inc(Count2);
   end else Inc(Count2,3);{}

   {xxx}
   with (GlobalInfo[0]) do begin
     Pom:=EnemyGroundCount; EnemyGroundPct:=EnemyGroundCount+EnemyAirCount;
     if (EnemyGroundPct > 0) then
       EnemyGroundPct:=Pom/(EnemyGroundPct/100);
     Pom:=FriendlyGroundCount; FriendlyGroundPct:=FriendlyGroundCount+FriendlyAirCount;
     if (FriendlyGroundPct > 0) then
       FriendlyGroundPct:=Pom/(FriendlyGroundPct/100);
     { * vlastni vypocty * }
     EnemyAirStrength:=EnemyAirStrength*((100-EnemyGroundPct) / 100);
     EnemyGroundStrength:=EnemyGroundStrength*(EnemyGroundPct / 100);
     FriendlyAirStrength:=FriendlyAirStrength*((100-FriendlyGroundPct) / 100);
     FriendlyGroundStrength:=FriendlyGroundStrength*(FriendlyGroundPct / 100);
   end;
   with (GlobalInfo[1]) do begin
     Pom:=EnemyGroundCount; EnemyGroundPct2:=EnemyGroundCount+EnemyAirCount;
     if (EnemyGroundPct2 > 0) then
       EnemyGroundPct2:=Pom/(EnemyGroundPct2/100);
     Pom:=FriendlyGroundCount; FriendlyGroundPct2:=FriendlyGroundCount+FriendlyAirCount;
     if (FriendlyGroundPct2 > 0) then
       FriendlyGroundPct2:=Pom/(FriendlyGroundPct2/100);
     { * vlastni vypocty * }
     EnemyAirStrength:=EnemyAirStrength*((100-EnemyGroundPct2) / 100);
     EnemyGroundStrength:=EnemyGroundStrength*(EnemyGroundPct2 / 100);
     FriendlyAirStrength:=FriendlyAirStrength*((100-FriendlyGroundPct2) / 100);
     FriendlyGroundStrength:=FriendlyGroundStrength*(FriendlyGroundPct2 / 100);
   end;
   {x}
   with (GlobalInfo[0]) do begin
     Pom:=EnemyGroundStrength+EnemyAirStrength-
          FriendlyGroundStrength-FriendlyAirStrength;
   end;
   with (GlobalInfo[1]) do begin
     Count2:=Count2 shr 1;
     Inc(GlobalInfoCount,Count2);
     { 2 okolni policka mimo mapu = 1 pritezujici okolnost vlastnimu poli }
     case (GlobalInfoCount) of
       1 : begin
              Pom:=Pom+1;
           end;
       2 : begin
              Pom:=Pom+(EnemyGroundStrength+EnemyAirStrength-
                        FriendlyGroundStrength-FriendlyAirStrength)/2;
              { nizsi vaha okoli }
              EnemyGroundPct:=(EnemyGroundPct*2+EnemyGroundPct2)/3;
           end;
     else
       Pom:=Pom+(EnemyGroundStrength+EnemyAirStrength-
                 FriendlyGroundStrength-FriendlyAirStrength);
       { priblizny odhad  EnemyGroundPct pro cele okoli }
       EnemyGroundPct:=(EnemyGroundPct+EnemyGroundPct2)/2;
     end;
   end;
   {x}
   IgnoreCoefficient:=(Get_task_group_strength(Race,TaskGrp,EnemyGroundPct)
                       /100)*IgnoreCoeff;
   { nyni zapocitame "ignorovani" urcitych cilu }
   if (GlobalInfoCount = 0) then begin
     if (Pom < IgnoreCoefficient) then Pom:=0
     else Pom:=Pom-IgnoreCoefficient;
   end else begin
     Temp:=IgnoreCoefficient+GlobalInfoCount*(IgnoreCoefficient/2);
     if (Pom < Temp) then Pom:=0
     else Pom:=Pom-Temp;
   end;

   if ((IP = ITar) and (JP = JTar)) then Pom:=0;

 end;
 GetSurroundings:=Pom;

 if ((IP < IInfoArraySize) and (JP < JInfoArraySize)) then with (OptiInfo^[IP,JP]) do
   if (not Valid) then begin
     Valid:=True; Value:=Pom;
   end;

Konec:
end;

{ --- }
begin
   { True, jde-li ciste o leteckou skupinu }
   AirGroup:=Races[Race].TaskGroups^[TaskGrp].AirUnitsCount =
             Races[Race].TaskGroups^[TaskGrp].Lock;

   if (GetDistance(IP,JP,ITar,JTar) <= 1) then begin
   { jsme-li pobliz cile, konec }
      IMov:=ITar; JMov:=JTar; Direction:=0; Goto Konec;
   end;

   { inicializace poli }
   for I:=0 to 4 do
     for J:=0 to 4 do PomArray[I,J]:=0; { inicializace }
   DirWeight[1]:=0; DirWeight[2]:=0; DirWeight[4]:=0; DirWeight[8]:=0;
   DirWeight[16]:=0; DirWeight[32]:=0; DirWeight[64]:=0; DirWeight[128]:=0;

   { zapocteni sil na policku tesne vedle aktualniho }
   if (JP > 0) then begin
     if (IP > 0) then begin
        DirWeight[1]:=DirWeight[1]+GetSurroundings(IP-1,JP-1,ITar,JTar,Friend,AirGroup);
     end else DirWeight[1]:=5000;
     DirWeight[2]:=DirWeight[2]+GetSurroundings(IP,JP-1,ITar,JTar,Friend,AirGroup);
     if (IP < IMapInfoMax) then begin
        DirWeight[4]:=DirWeight[4]+GetSurroundings(IP+1,JP-1,ITar,JTar,Friend,AirGroup);
     end else DirWeight[4]:=5000;
   end else begin
      DirWeight[1]:=5000; DirWeight[2]:=5000; DirWeight[4]:=5000;
   end;
   if (IP > 0) then DirWeight[128]:=DirWeight[128]+GetSurroundings(IP-1,JP,ITar,JTar,Friend,AirGroup)
   else DirWeight[128]:=5000;
   if (IP < IMapInfoMax) then DirWeight[8]:=DirWeight[8]+GetSurroundings(IP+1,JP,ITar,JTar,Friend,AirGroup)
   else DirWeight[8]:=5000;
   if (JP < JMapInfoMax) then begin
      if (IP > 0) then begin
        DirWeight[64]:=DirWeight[64]+GetSurroundings(IP-1,JP+1,ITar,JTar,Friend,AirGroup);
      end else DirWeight[64]:=5000;
      DirWeight[32]:=DirWeight[32]+GetSurroundings(IP,JP+1,ITar,JTar,Friend,AirGroup);
      if (IP < IMapInfoMax) then begin
        DirWeight[16]:=DirWeight[16]+GetSurroundings(IP+1,JP+1,ITar,JTar,Friend,AirGroup);
      end else DirWeight[16]:=5000;
   end else begin
      DirWeight[64]:=5000; DirWeight[32]:=5000; DirWeight[16]:=5000;
   end;

   { nyni inicializacni vahy jednotlivych smeru pohybu VZHLEDEM K CILI }
   BestDir:=Best_direction(IP,JP,ITar,JTar); {DirWeight[BestDir]:=0;{}
   asm rol BestDir,1 end; if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+10
                                            else DirWeight[BestDir]:=DirWeight[BestDir]+2;
   asm ror BestDir,2 end; if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+10
                                            else DirWeight[BestDir]:=DirWeight[BestDir]+2;
   asm rol BestDir,3 end; if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+300
                                            else DirWeight[BestDir]:=DirWeight[BestDir]+3;
   asm ror BestDir,4 end; if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+300
                                            else DirWeight[BestDir]:=DirWeight[BestDir]+3;
   asm rol BestDir,5 end; if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+1000
                                            else DirWeight[BestDir]:=DirWeight[BestDir]+300;
   asm ror BestDir,6 end; if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+1000
                                            else DirWeight[BestDir]:=DirWeight[BestDir]+300;
   asm ror BestDir,1 end;  if (DirectTarget) then DirWeight[BestDir]:=DirWeight[BestDir]+2000
                                             else DirWeight[BestDir]:=DirWeight[BestDir]+1000;

   { nyni inicializacni vahy jednotlivych smeru pohybu VZHLEDEM
     K PREDCHOZIMU POHYBU }
   if (Direction = 0) then Direction:=Best_direction(IP,JP,ITar,JTar);
   if (Direction <> 0) then begin
      BestDir:=Direction;
      asm rol BestDir,1 end; DirWeight[BestDir]:=DirWeight[BestDir]+1;
      asm ror BestDir,2 end; DirWeight[BestDir]:=DirWeight[BestDir]+1;
      asm rol BestDir,3 end; DirWeight[BestDir]:=DirWeight[BestDir]+2;
      asm ror BestDir,4 end; DirWeight[BestDir]:=DirWeight[BestDir]+2;
      asm rol BestDir,5 end; DirWeight[BestDir]:=DirWeight[BestDir]+200;
      asm ror BestDir,6 end; DirWeight[BestDir]:=DirWeight[BestDir]+200;
      asm ror BestDir,1 end; DirWeight[BestDir]:=DirWeight[BestDir]+1000;
   end;

   { zjisteni dostupnych souradnic }
   if (2 > IP) then begin
     K:=0; IBeg:=2-IP;
   end else begin
     K:=IP-2; IBeg:=0;
   end;
   if (2 > JP) then begin
     L:=0; JBeg:=2-JP;
   end else begin
     L:=JP-2; JBeg:=0;
   end;
   if ((2+IP) > IMapInfoMax) then M:=IMapInfoMax else M:=IP+2;
   if ((2+JP) > JMapInfoMax) then N:=JMapInfoMax else N:=JP+2;
   { horni linka }
   if (JP > 1) then
    for I:=K to M do begin
       if (InfoPoleValidity(I,JP-2,AirGroup)) then
          PomArray[I-K+IBeg,0]:=GetSurroundings(I,JP-2,ITar,JTar,Friend,AirGroup)
       else PomArray[I-K+IBeg,0]:=0;
    end;
   { spodni linka }
   if ((JP+2) <= JMapInfoMax) then
    for I:=K to M do begin
       if (InfoPoleValidity(I,JP+2,AirGroup)) then
          PomArray[I-K+IBeg,4]:=GetSurroundings(I,JP+2,ITar,JTar,Friend,AirGroup)
       else PomArray[I-K+IBeg,4]:=0;
    end;
   { leva linka }
   if (IP > 1) then
    for J:=L to N do begin
       if (InfoPoleValidity(IP-2,J,AirGroup)) then
         PomArray[0,J-L+JBeg]:=GetSurroundings(IP-2,J,ITar,JTar,Friend,AirGroup)
       else PomArray[0,J-L+JBeg]:=0;
    end;
   { prava linka }
   if ((IP+2) <= IMapInfoMax) then
    for J:=L to N do begin
       if (InfoPoleValidity(IP+2,J,AirGroup)) then
         PomArray[4,J-L+JBeg]:=GetSurroundings(IP+2,J,ITar,JTar,Friend,AirGroup)
       else PomArray[4,J-L+JBeg]:=0;
    end;

  { nyni vyhodnotime }
  PomArray[1,1]:=PomArray[0,0]+PomArray[0,1]+PomArray[1,0]+DirWeight[1];
  PomArray[2,1]:=PomArray[1,0] / 2+PomArray[2,0]+PomArray[3,0] / 2+DirWeight[2];
  PomArray[3,1]:=PomArray[3,0]+PomArray[4,0]+PomArray[4,1]+DirWeight[4];
  PomArray[3,2]:=PomArray[4,1] / 2+PomArray[4,2]+PomArray[4,3] / 2+DirWeight[8];
  PomArray[3,3]:=PomArray[4,3]+PomArray[4,4]+PomArray[3,4]+DirWeight[16];
  PomArray[2,3]:=PomArray[3,4] / 2+PomArray[2,4]+PomArray[1,4] / 2+DirWeight[32];
  PomArray[1,3]:=PomArray[1,4]+PomArray[0,4]+PomArray[0,3]+DirWeight[64];
  PomArray[1,2]:=PomArray[0,3] / 2+PomArray[0,2]+PomArray[0,1] / 2+DirWeight[128];

  { nyni omezime okraje sirenim maximalni hodnoty }
  K1:=0; K2:=0; K3:=0; K4:=0;
  if (IP <= 1) then begin
     K1:=PomArray[1,1]; L1:=PomArray[1,2]; M1:=PomArray[1,3];
     if (K1 >= 5000) then K1:=0;
     if (K1 < L1) then K1:=L1; if ((K1 < M1) and (M1 < 5000)) then K1:=M1;
  end;
  if (JP <= 1) then begin
     K2:=PomArray[1,1]; L1:=PomArray[2,1]; M1:=PomArray[3,1];
     if (K2 >= 5000) then K2:=0;
     if (K2 < L1) then K2:=L1; if ((K2 < M1) and (M1 < 5000)) then K2:=M1;
  end;
  if ((IP+1) >= IMapInfoMax) then begin
     K3:=PomArray[3,1]; L1:=PomArray[3,2]; M1:=PomArray[3,3];
     if (K3 >= 5000) then K3:=0;
     if (K3 < L1) then K3:=L1; if ((K3 < M1) and (M1 < 5000)) then K3:=M1;
  end;
  if ((JP+1) >= JMapInfoMax) then begin
     K4:=PomArray[1,3]; L1:=PomArray[2,3]; M1:=PomArray[3,3];
     if (K4 >= 5000) then K4:=0;
     if (K4 < L1) then K4:=L1; if ((K4 < M1) and (M1 < 5000)) then K4:=M1;
  end;
  if (K1 > 0) then begin
     if (K1 > PomArray[1,1]) then PomArray[1,1]:=K1;
     if (K1 > PomArray[1,2]) then PomArray[1,2]:=K1;
     if (K1 > PomArray[1,3]) then PomArray[1,3]:=K1;
  end;
  if (K2 > 0) then begin
     if (K2 > PomArray[1,1]) then PomArray[1,1]:=K2;
     if (K2 > PomArray[2,1]) then PomArray[2,1]:=K2;
     if (K2 > PomArray[3,1]) then PomArray[3,1]:=K2;
  end;
  if (K3 > 0) then begin
     if (K3 > PomArray[3,1]) then PomArray[3,1]:=K3;
     if (K3 > PomArray[3,2]) then PomArray[3,2]:=K3;
     if (K3 > PomArray[3,3]) then PomArray[3,3]:=K3;
  end;
  if (K4 > 0) then begin
     if (K4 > PomArray[1,3]) then PomArray[1,3]:=K4;
     if (K4 > PomArray[2,3]) then PomArray[2,3]:=K4;
     if (K4 > PomArray[3,3]) then PomArray[3,3]:=K4;
  end;

  { nyni vyhodnotime }
  PomArray[1,1]:=PomArray[1,1]+DirWeight[1];
  PomArray[2,1]:=PomArray[2,1]+DirWeight[2];
  PomArray[3,1]:=PomArray[3,1]+DirWeight[4];
  PomArray[3,2]:=PomArray[3,2]+DirWeight[8];
  PomArray[3,3]:=PomArray[3,3]+DirWeight[16];
  PomArray[2,3]:=PomArray[2,3]+DirWeight[32];
  PomArray[1,3]:=PomArray[1,3]+DirWeight[64];
  PomArray[1,2]:=PomArray[1,2]+DirWeight[128];

  BestWeight:=PomArray[1,1]; IBestPos:=1; JBestPos:=1; Direction:=1;
  if (BestWeight > PomArray[2,1]) then begin
    BestWeight:=PomArray[2,1]; IBestPos:=2; JBestPos:=1; Direction:=2;
  end;
  if (BestWeight > PomArray[3,1]) then begin
    BestWeight:=PomArray[3,1]; IBestPos:=3; JBestPos:=1; Direction:=4;
  end;
  if (BestWeight > PomArray[3,2]) then begin
    BestWeight:=PomArray[3,2]; IBestPos:=3; JBestPos:=2; Direction:=8;
  end;
  if (BestWeight > PomArray[3,3]) then begin
    BestWeight:=PomArray[3,3]; IBestPos:=3; JBestPos:=3; Direction:=16;
  end;
  if (BestWeight > PomArray[2,3]) then begin
    BestWeight:=PomArray[2,3]; IBestPos:=2; JBestPos:=3; Direction:=32;
  end;
  if (BestWeight > PomArray[1,3]) then begin
    BestWeight:=PomArray[1,3]; IBestPos:=1; JBestPos:=3; Direction:=64;
  end;
  if (BestWeight > PomArray[1,2]) then begin
    BestWeight:=PomArray[1,2]; IBestPos:=1; JBestPos:=2; Direction:=128;
  end;

  { A VYSLEDEK: }
  IMov:=IP+IBestPos-2; JMov:=JP+JBestPos-2;
Konec:
end;

{ ***** }
procedure TaskGroupMovement(var INext,JNext:Word; var Direction:Byte; ITarg,JTarg:Word;
                            Race,TaskGrp:Byte; IgnoreCoeff:Single; var DirectTarget:Boolean;
                            Friend:Boolean);
{ tato procedura vypocita dalsi pole presunu z INext,JNext do ITarg,JTarg
  a hodnotu ulozi do INext, JNext
  Friend = True, jde-li o pratelskou taskgrupu
}
label Again;
var X1,Y1,X2,Y2,X3,Y3,XPom,YPom,I,J,K,Pom:Word;
    ICompute,JCompute:Word;
    Dir,CompDir1,CompDir2,PomDirection:Byte;
    Counter:Byte;
begin
    {SetRGB(64,0,0,0);{}

    Counter:=0;
    for J:=0 to (JInfoArraySize-1) do
     for I:=0 to (IInfoArraySize-1) do with (OptiInfo^[I,J]) do begin
        Valid:=False;
     end;

Again:
    Inc(Counter); { counter hlida, aby se znovupocitani (viz konec procedury)
    nejak nezacyklilo  }
    ICompute:=INext; JCompute:=JNext;
    CompDir1:=Direction;{} asm ror CompDir1,4; end;
    CompDir2:=Direction;{}
    XPom:=INext; YPom:=JNext; PomDirection:=0;
    for K:=1 to TaskGroupIntelliAttackMoveCyclesRepeat do begin
       X3:=ICompute; Y3:=JCompute; X2:=65535; Y2:=65535;
       X1:=ITarg; Y1:=JTarg; Dir:=CompDir1; asm rol Dir,4; end;
       for I:=1 to TaskGroupIntelliAttackMoveCyclesBackward do begin
       { zkusime nekolik kroku dopredu, pokud dojde k nejake zbytecne
         klicce, tak ji vypustime }
       { NEJPRVE ZKUSIME SMER OD CILE K SOUCASNE POZICI }
         Get_taskgroup_path(X1,Y1,X3,Y3,X1,Y1,Dir,Race,TaskGrp,
                            IgnoreCoeff,DirectTarget,Friend);
         if (GetDistance(ICompute,JCompute,X1,Y1) = 1) then begin
         { nasli jsme vyhodny smer }
           if (X2 = 65535) then begin { pokud nic nenalezeno, delej: }
           { preferuje se 1. nalezena varianta, na rozdil od "normalniho chodu" }
             X2:=X1; Y2:=Y1; CompDir1:=Dir;
           end;
         end;
       end;{}

       if (X2 = 65535) then begin
       { PREDCHOZI CYKLUS NENASEL RESENI }
          X1:=ICompute; Y1:=JCompute; Dir:=CompDir2; X2:=65535; Y2:=65535;
          for I:=1 to TaskGroupIntelliAttackMoveCyclesForward do begin
          { zkusime nekolik kroku dopredu, pokud dojde k nejake zbytecne
            klicce, tak ji vypustime }
          { NYNI NAOPAK PROJDEME NEKOLIK KROKU SMEREM K CILI }
            Get_taskgroup_path(X1,Y1,ITarg,JTarg,X1,Y1,Dir,Race,TaskGrp,
                               IgnoreCoeff,DirectTarget,Friend);
            if (GetDistance(ICompute,JCompute,X1,Y1) = 1) then begin
            { nasli jsme vyhodny smer }
              X2:=X1; Y2:=Y1; CompDir2:=Dir;
            end;
          end;
       end;
       if ((X2 <> 65535) and (Y2 <> 65535)) then begin
         ICompute:=X2; JCompute:=Y2;
       end;
       PomDirection:=Best_direction(INext,JNext,ICompute,JCompute);

       Pom:=GetDistance(ICompute,JCompute,INext,JNext);
       if (Pom = 1) then begin
          XPom:=ICompute; YPom:=JCompute;
       end else { pokud se taskgrupa zacykluje, udelej tomu tvrdou pritrz }
         if (Pom = 0) then DirectTarget:=True;
    end;

    if (Counter < 2) then begin
      { nejprve testujeme smer k cili }
      Dir:=Best_direction(INext,JNext,ITarg,JTarg);
      { vysledek je obrat o 180 stupnu - zrus ho a znovu vypocti pri
        DirectTarget = True: }
      asm rol Dir,4; end;
      if (PomDirection = Dir) then begin DirectTarget:=True; GoTo again; end;

      { vysledek je negativni obrat - zrus aktualni Direction (lepsi navedeni
        na cil) a zkus vse znovu vypocist: }
      asm rol Dir,1; end;
      if (PomDirection = Dir) then begin Direction:=0; GoTo again; end;
      asm ror Dir,2; end;
      if (PomDirection = Dir) then begin Direction:=0; GoTo again; end;

      { nyni testujeme vzhledem k puvodnimu smeru }
      Dir:=Direction;
      { vysledek je obrat o 180 stupnu - zrus ho a znovu vypocti pri
        DirectTarget = True: }
      asm rol Dir,4; end;
      if (PomDirection = Dir) then begin DirectTarget:=True; GoTo again; end;

      { vysledek je negativni obrat - zrus aktualni Direction (lepsi navedeni
        na cil) a zkus vse znovu vypocist: }
      asm rol Dir,1; end;
      if (PomDirection = Dir) then begin Direction:=0; GoTo again; end;
      asm ror Dir,2; end;
      if (PomDirection = Dir) then begin Direction:=0; GoTo again; end;
    end else
      if (Counter = 2) then begin DirectTarget:=True; GoTo again; end;

    INext:=XPom; JNext:=YPom; Direction:=PomDirection;

    {SetRGB(64,63,63,63); {}
end;

{ ***** }
procedure Production_ai_planning(Race:Byte);
{ provede naplanovani vyroby dle nedotatku surovin ...
}
const BPLowLimit = 350; { limity, po nichz se nastavi nedostatek daneho mater. }
      PLLowLimit = 50;
      EELowLimit = 10;
      EXPLowLimit = 0;
      BPHiLimit = 1000; { limity, po nichz se zcela zrusi nedostatek daneho}
      PLHiLimit = 150;   { mater. }
      EEHiLimit = 100;
      EXPHiLimit = 20;

      PLHighestLimit = 80; { pozadavek PLHiNeed nikdy nebude vetsi nez tato
                             hodnota }

      EEReserve = 40; { pokud se odpocte od produkce elektraren udrzba vsech
      budov, zbyde tkzv. rezerva (pouzitelna napr. na vyrobu). V teto
      konstante je hodnota minimalni rezervy na 200 casovych cyklu;
      neni-li rezerva dodrzena, vyrobi se dalsi elektrarna.
      pozn. standardni rychlost je asi 18 cyklu na 1 sekundu
      }

      MaxAccumulators = 2; { maximalni pocet soucasne existujicich
      akumulatoru; pozadavky na vyrobu dalsich se budou rusit }

var BPPom, PLPom, I,J,K,L,Limit,IP,JP:LongInt;
    Pom,BuildCount,PowerPlantCount:Single;
    Max_recykl_num, Index:Word;
    Priority,Request:Byte;
    EEProd:Single;
    Avail:Boolean;
begin
   { !!!!!!!!!!! ODDELAT XXXSHORTAGEFORBID PO ROZBALENI BUDOVY !!!!!!!!!!!!!!}
   with (Races[Race]) do begin
      Max_recykl_num:=Calcul_max_recykl_num(Race);

      { XXXXX ELEKTRICKA ENERGIE XXXXX }
      { zkusime predpovedet spotrebu EE na zaklade poctu budov + nutna
        rezerva }
      K:=0; L:=0;
      for I:=1 to MaxTypesOfBuildings do
        if ((I <> 5) and (I <> 25)) then Inc(K,ExistBuildings[I])
        else
          if (I = 5) then L:=ExistBuildings[I]; { elektrarna }
        { prekazka se nepocita }

      BuildCount:=K; PowerPlantCount:=L;
      EEProd:= EEProduction - Round((EEProduction / 100) *
                                    ((Electric_energy div EEProductionDecreaseVal)*
                                     EEProductionDecrease));
      PowerPlantCount:=(PowerPlantCount*(EEProd+EEProd*EE_credits_plus))/EEProductionSpeed;
      BuildCount:=(BuildCount*EEConsumption) / EEConsumptionSpeed;
      Pom:=(PowerPlantCount - BuildCount)*200;
      { v Pom je nyni udaj o produkci elektriny (+ cislo = prebytek ee,
        - cislo = nedostatek ee) za dobu 200 cyklu, coz je v nejrychlejsim
        rezimu bez casovace asi 10s }
      { EE - zareagujeme za 4*doba produkce obecne elektrarny }
      if (GameTimming = 0) then Limit:=EEProductionSpeed shl 1
      else Limit:=EEProductionSpeed shl 4;
      { mozna prechodny nedostatek }
      if (Electric_energy < EELowLimit) then Inc(EEShortage) else
         if (EEShortage > 0) then Dec(EEShortage);{}
      { trvaly nedostatek }
      if (Pom <= 0) then EEShortage:=Limit+1
      else
        if (Pom < EEReserve) then Inc(EEShortage,10)
        else begin
           if (EEShortage > 0) then Dec(EEShortage);
           if (Electric_energy > EEHiLimit) then EEShortage:=0;
           if (ExistBuildings[6] = 0) then Inc(AccumulatorShortage);{}
        end;

      if ((EEShortage > 5000) or (EEShortageForbid <> 0) or
          (not BuildingProductionPossible(Race,5))) then EEShortage:=0;

      { Pokus eventuelne vyrobit elektrarnu }
      {if (Building_types[5].IBuildingSize = 2) then Request:=2 else Request:=14;{}
      if ((EEShortage > Limit) and (EEShortageForbid = 0) and
          (not NotEnoughFreePlaces(Race,15)) and
          BuildingProductionPossible(Race,5)) then begin
         ProductionManager.Insert(Race,GetProdPrioB(5,ProductionPriorityVeryHi),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[5].Parent,5,255);
         Inc(EEShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX STAVEBNI BODY XXXXX }
      { BP - zareagujeme za 4*dobu vylozeni 1 harvesteru }
      if (GameTimming = 0) then Limit:=Round(HarvestingSpeed*100)
      else Limit:=Round(HarvestingSpeed*100) shl 1;
      if ((ExistBuildings[4] > 0) and (Recyclators > Max_recykl_num shr 1))
      then if (GameTimming = 0) then Limit:=Round(HarvestingSpeed*200)
           else Limit:=Round(HarvestingSpeed*200) shl 1;

      { zvysovani/snizovani nedostatku }
      if (Building_credits < BPLowLimit) then Inc(BPShortage) else
        if (BPShortage > 0) then Dec(BPShortage);
      if ((BPShortage > 5000) or (BPShortageForbid <> 0){ or
          (not BuildingProductionPossible(Race,4)){}) then BPShortage:=0;

      BPPom:=0; PLPom:=0;
      { chybi recyklace }
      if (((ExistBuildings[4] = 0) or (not NotEnoughFreePlaces(Race,20))) and
          BuildingProductionPossible(Race,4))
      then begin
         Inc(BPPom,Building_types[4].BP); Inc(BPShortage,2);
         Inc(PLPom,Building_types[4].PL);
      end;
      { chybi lehka tovarna }
      if ((ExistBuildings[3] = 0) and (BuildingProductionPossible(Race,3)))
      then begin
          Inc(LightFactoryShortage);
      end;
      { chybi recyklator }
      if ((Recyclators = 0) and (Max_recykl_num > 0) and
          (UnitProductionPossible(Race,2)) ) then begin
         Inc(BPPom,Unit_types[2,Races[Race].Ally].BP); Inc(BPShortage,3);
         Inc(PLPom,Building_types[2].PL);
      end;
      { nyni vyhodnotime, zda se prioritne nemaji postavit budovy pro
        podporu materialu a zda je pro ne dost zdroju }
      if ((BPPom >= Building_credits) and ((BPPom+100) < Building_credits) and
          (PLPom >= Plastic_credits) and (Max_recykl_num > 0))
      then begin
          Inc(BPShortage,Limit);
          Forbid:=True; { jdi jen na vyrobu materialu }
      end else begin
        if ((Building_credits > BPHiLimit) and (ExistBuildings[4] > 0) and
            (Recyclators >= Max_recykl_num))
        then BPShortage:=0;
        Forbid:=False;
      end;

      { -- NEDOSTATEK BP }
      if ((BPShortage > Limit) and (BPShortageForbid = 0)) then begin
      { !!! DO BUDOUCNA KONTROLA DOSTUPNYCH ZDROJU !!! }
         { nejprve zjistime, zda je je dostatek budov recyklace }
         { - mela by stacit 1 - }
         Request:=16;
         Avail:=((ExistBuildings[3] > 0) and (ExistUnits[2] > 1) and
                 ((ExistBuildings[10] > 0) or (not PermittedBuildings[10]) and
                  (ExistBuildings[9] > 0)));
         if (((ExistBuildings[4] = 0) or (not NotEnoughFreePlaces(Race,20)) and
              Avail) and (not NotEnoughFreePlaces(Race,Request)) and
             BuildingProductionPossible(Race,4))
         then begin
         { vyrob budovu recyklace }
            ProductionManager.Insert(Race,GetProdPrioB(4,ProductionPriorityVeryHi),CreateNewTaskGroupNumber,
                                     MoveBuildCom,Building_types[4].Parent,4,255);
            Inc(BPShortageForbid);
         end else begin
         { zkus vyrobit dalsi recyklator - do max. poctu MaxRecyclators;
           navic jen tehdy, existuje-li volny zdroj }
            if ((Recyclators < Max_recykl_num) or (ExistBuildings[3] = 0))
            then begin
            { vyprodukuj recyklator }
               if (Building_types[3].IBuildingSize = 2) then Request:=1 else Request:=13;
               if ((ExistBuildings[3] = 0) and (not NotEnoughFreePlaces(Race,Request)) and
                   BuildingProductionPossible(Race,3))
               then begin
               { neexistuje lehka tovarna - vyrobi se ve sve sekci }
               end else if (UnitProductionPossible(Race,2) and
                            (Recyclators < Max_recykl_num)) then begin
               { produkce recyklatoru }
                  if (Recyclators <= Max_recykl_num shr 1) then begin
                  { prvni se stavi vzdy s velkou prioriotou}
                     if (Recyclators = 0) then
                       ProductionManager.Insert(Race,ProductionPriorityVeryHi,
                                                CreateNewTaskGroupNumber,HarvestCom,
                                                Unit_types[2,Races[Race].Ally].Parent,2,255)
                     else
                       ProductionManager.Insert(Race,ProductionPriorityHi,
                                                CreateNewTaskGroupNumber,HarvestCom,
                                                Unit_types[2,Races[Race].Ally].Parent,2,255);
                     Inc(BPShortageForbid);
                  end else
                    { pri zakazu plytvani smim postavit recyklator jen tehdy,
                      pokud jeste zadny neni k dispozici }
                    if (not Forbid) then begin
                      if (Recyclators <= (Max_recykl_num-Max_recykl_num shr 2)) then begin
                      { je-li recyklatoru mnohem mene nez doporucene
                        mnozstvi, pouzije se normalni, jinak nizka priorita }
                          ProductionManager.Insert(Race,ProductionPriorityMedium,
                                                   CreateNewTaskGroupNumber,HarvestCom,
                                                   Unit_types[2,Races[Race].Ally].Parent,2,255);
                          Inc(BPShortageForbid);
                      end else if (Recyclators < Max_recykl_num) then begin
                          ProductionManager.Insert(Race,ProductionPriorityLow,
                                                   CreateNewTaskGroupNumber,HarvestCom,
                                                   Unit_types[2,Races[Race].Ally].Parent,2,255);
                          Inc(BPShortageForbid);
                      end;
                    end;
               end;
            end;
         end;
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX PLASTY XXXXX }
      if (ExistBuildings[8] = 0) then begin
        if (GameTimming = 0) then Limit:=100
        else Limit:=100 shl 1;
      end else begin
        if (GameTimming = 0) then Limit:=15
        else Limit:=15 shl 1;
      end;

      if (PLHiNeed <= 0) then PLHiNeed:=PLLowLimit+1;
      if (PLHiNeed > PLHighestLimit) then PLHiNeed:=PLHighestLimit;

      if (Plastic_credits < PLLowLimit) then Inc(PLShortage) else
        {if (PLShortage > 0) then Dec(PLShortage){};

      if (((Plastic_credits > PLHiLimit) and (PLHiLimit >= PLHiNeed) or
           (Plastic_credits > PLHiNeed) and (PLHiNeed > PLLowLimit)) and
          (PLShortageForbid <> 0) and (ExistBuildings[8] > 0)) then begin
         PLShortage:=0;
         { zastav pripadnou vyrobu plastu }
         ProductionManager.Insert(Race,ProductionPriorityVeryHi,CreateNewTaskGroupNumber,
                                  MoveBuildCom,8,255,255);
         if (PLShortageForbid <> 0) then Dec(PLShortageForbid);
      end;
      if ((PLShortage > 3000) or (PLShortageForbid > 0)) then begin
         PLShortage:=0;
      end;
      { pokud budova plastarny neexistuje, jej jeji priorita vysoka }
      if ((BuildingProductionPossible(Race,8)) and (ExistBuildings[8] = 0))
      then Inc(PLShortage);

      { -- NEDOSTATEK PL }
      if ((PLShortage > Limit)) then begin
         if (Building_types[8].IBuildingSize = 2) then Request:=2 else Request:=14;
         if (((ExistBuildings[8] = 0) and (PLShortageForbid = 0) or
              (ExistBuildings[8] = 1) and (not DruhaPlastarnaVeVyrobe)) and
             (not NotEnoughFreePlaces(Race,Request)) and
             (BuildingProductionPossible(Race,8)) and (not Forbid))
         then begin   { plastarna neexistuje }
            if (ExistBuildings[8] = 0) then begin
                ProductionManager.Insert(Race,GetProdPrioB(8,ProductionPriorityHi),CreateNewTaskGroupNumber,
                                         MoveBuildCom,Building_types[8].Parent,8,255);
                Inc(PLShortageForbid);
            end else begin
               Avail:=((ExistBuildings[13] > 0) and (ExistBuildings[10] > 0) or
                       (not PermittedBuildings[13]) and (ExistBuildings[12] > 0) or
                       (not PermittedBuildings[13]) and (not PermittedBuildings[12]) and
                       (ExistBuildings[10] > 0) or
                       (not PermittedBuildings[13]) and (not PermittedBuildings[12]) and
                       (not PermittedBuildings[10]) and (ExistBuildings[3] > 0) and
                       ((ExistBuildings[2] > 0) or (ExistBuildings[15] > 0)));
               if ((not DruhaPlastarnaVeVyrobe) and Avail) then begin
                  ProductionManager.Insert(Race,GetProdPrioB(8,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                           MoveBuildCom,Building_types[8].Parent,8,255);
                  DruhaPlastarnaVeVyrobe:=True;
               end;
            end;
         end;
         if (ExistBuildings[8] > 0) then begin
         { plastarna existuje - rozjed vyrobu plastu }
            if (PLShortageForbid < ExistBuildings[8]) then begin
              ProductionManager.Insert(Race,ProductionPriorityHi,CreateNewTaskGroupNumber,
                                       MoveBuildCom,8,0,255);
              Inc(PLShortageForbid);
            end;
         end;
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX BOJOVA ZKUSENOST XXXXX }
      if (Battle_experience < EXPLowLimit) then Inc(EXPShortage) else
         if (EXPShortage > 0) then Dec(EXPShortage);
      { zruseni nedostatku }
      if (Battle_experience > EXPHiLimit) then EXPShortage:=0;
      { odstraneni neuspokojitelnych pozadavku }
      if ((EXPShortage > 250) or (EXPShortageForbid <> 0)) then EXPShortage:=0;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX  AKUMULATOR  XXXXX }
      if (GameTimming = 0) then Limit:=EEProductionSpeed shl ((3+ExistBuildings[6]) shr 1)
      else
         if (ExistBuildings[6] = 0) then Limit:=EEProductionSpeed shl 2
         else Limit:=EEProductionSpeed shl (3+ExistBuildings[6]);

      { -- NEDOSTATEK ACCUM. }

      if ((AccumulatorShortage > 60000) or (AccumulatorShortageForbid <> 0) or
          (ExistBuildings[6] >= MaxAccumulators) or Forbid or
          (not BuildingProductionPossible(Race,6)))
      then AccumulatorShortage:=0;

      { snizime priznak nedostatku; pokud je malo materialu
        (akumulator) lze ozelet }
      if (((Building_credits < (BPUnitCostAver+BPBuildCostAver)) or
           (Plastic_credits < (PLUnitCostAver+PLBuildCostAver))) and
          (ExistBuildings[6] > 1) and (AccumulatorShortage > 0))
      then Dec(AccumulatorShortage);
      if ((AccumulatorShortage > Limit) and (not NotEnoughFreePlaces(Race,3)) and
          (BuildingProductionPossible(Race,6)) and
          (AccumulatorShortageForbid = 0))
      then begin
          if (ExistBuildings[6] = 0) then begin { vyroba akumulatoru }
            ProductionManager.Insert(Race,GetProdPrioB(6,ProductionPriorityVeryHi),CreateNewTaskGroupNumber,
                                     MoveBuildCom,Building_types[6].Parent,6,255);
            Inc(AccumulatorShortageForbid)
          end else begin
            ProductionManager.Insert(Race,GetProdPrioB(6,ProductionPriorityLow),CreateNewTaskGroupNumber,
                                     MoveBuildCom,Building_types[6].Parent,6,255);
            Inc(AccumulatorShortageForbid);
          end;
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX KASARNA XXXXX }
      { nyni rozhodneme, zda jde o roboty nebo o lidi }
      if ((RaceType = 3) or (RaceType > 4)) then Index:=15 else{} Index:=2;

      if (GameTimming = 0) then Limit:=80
      else Limit:=80 shl 1;

      if ((BarrackShortage > 60000) or (BarrackShortageForbid <> 0) or
            Forbid or (not BuildingProductionPossible(Race,Index)))
      then BarrackShortage:=0;

      if (BuildingProductionPossible(Race,Index) and (BarrackShortageForbid = 0) and
          (ExistBuildings[Index] = 0))
      then Inc(BarrackShortage);

      if (Building_types[Index].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((BarrackShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,Index)) and
          (BarrackShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(2,ProductionPriorityHi),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[Index].Parent,2,255);
         Inc(BarrackShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX CENTRUM POSIL XXXXX }
      if (GameTimming = 0) then Limit:=140
      else Limit:=140 shl 1;

      Index:=41;
      if ((CentrumPosilShortage > 60000) or (CentrumPosilShortageForbid <> 0) or
            Forbid or (not UnitProductionPossible(Race,Index)))
      then CentrumPosilShortage:=0;

      if (UnitProductionPossible(Race,Index) and (CentrumPosilShortageForbid = 0) and
          (ExistUnits[Index] = 0))
      then Inc(CentrumPosilShortage);

      Request:=17;
      if ((CentrumPosilShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (UnitProductionPossible(Race,Index)) and
          (CentrumPosilShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioU(ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Unit_types[Index,Races[Race].Ally].Parent,Index,255);
         Inc(CentrumPosilShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX LEHKA TOVARNA XXXXX }
      if (GameTimming = 0) then Limit:=100
      else Limit:=100 shl 1;
      if ((LightFactoryShortage > 60000) or (LightFactoryShortageForbid <> 0) or
          (not BuildingProductionPossible(Race,3)))
      then LightFactoryShortage:=0;
      if ((ExistBuildings[3] = 0) and (BuildingProductionPossible(Race,3)))
      then begin
        Inc(LightFactoryShortage);
      end;
      if (Building_types[3].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((LightFactoryShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,3)) and
          (LightFactoryShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(3,ProductionPriorityVeryHi),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[3].Parent,3,255);
         Inc(LightFactoryShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX ZAKLADNA2  XXXXX }
      if (GameTimming = 0) then Limit:=100
      else Limit:=100 shl 1;

      if ((Base2Shortage > 60000) or (Base2ShortageForbid <> 0) or
            Forbid or (not BuildingProductionPossible(Race,9)))
      then Base2Shortage:=0;
      {.}
      if (BuildingProductionPossible(Race,9) and (Base2ShortageForbid = 0) and
          (ExistBuildings[9] = 0))
      then Inc(Base2Shortage);
      {.}
      if (Building_types[9].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((Base2Shortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,9)) and
          (Base2ShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(9,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[9].Parent,9,255);
         Inc(Base2ShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX TEZKA TOVARNA XXXXX }
      if (GameTimming = 0) then Limit:=150
      else Limit:=150 shl 1;

      if ((HeavyFactoryShortage > 60000) or (HeavyFactoryShortageForbid <> 0) or
            Forbid or (not BuildingProductionPossible(Race,10)))
      then HeavyFactoryShortage:=0;

      if (BuildingProductionPossible(Race,10) and (HeavyFactoryShortageForbid = 0) and
          (ExistBuildings[10] = 0))
      then Inc(HeavyFactoryShortage);

      if (Building_types[10].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((HeavyFactoryShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,10)) and
          (HeavyFactoryShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(10,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[10].Parent,10,255);
         Inc(HeavyFactoryShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX SPECIALNI TOVARNA XXXXX }
      if (GameTimming = 0) then Limit:=150
      else Limit:=150 shl 1;

      if ((SpecialFactoryShortage > 60000) or (SpecialFactoryShortageForbid <> 0) or
            Forbid or (not BuildingProductionPossible(Race,12)))
      then SpecialFactoryShortage:=0;

      if (BuildingProductionPossible(Race,12) and (SpecialFactoryShortageForbid = 0) and
          (ExistBuildings[12] = 0))
      then Inc(SpecialFactoryShortage);

      if (Building_types[12].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((SpecialFactoryShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,12)) and
          (SpecialFactoryShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(12,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[12].Parent,12,255);
         Inc(SpecialFactoryShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX OBRANNE CENTRUM XXXXX }
      if (GameTimming = 0) then Limit:=150
      else Limit:=150 shl 1;

      if ((DefenceFactoryShortage > 60000) or (DefenceFactoryShortageForbid <> 0) or
            Forbid or (not BuildingProductionPossible(Race,14)))
      then DefenceFactoryShortage:=0;

      if (BuildingProductionPossible(Race,14) and (DefenceFactoryShortageForbid = 0) and
          (ExistBuildings[14] = 0))
      then Inc(DefenceFactoryShortage);

      if (Building_types[14].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((DefenceFactoryShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,14)) and
          (DefenceFactoryShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(14,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[14].Parent,14,255);
         Inc(DefenceFactoryShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX CENTRUM OPRAV XXXXX }
      if (GameTimming = 0) then Limit:=150
      else Limit:=150 shl 1;

      if ((RepairFactoryShortage > 60000) or (RepairFactoryShortageForbid <> 0) or
            Forbid or (not BuildingProductionPossible(Race,13)))
      then RepairFactoryShortage:=0;

      if (BuildingProductionPossible(Race,13) and (RepairFactoryShortageForbid = 0) and
          (ExistBuildings[13] = 0))
      then Inc(RepairFactoryShortage);

      if (Building_types[13].IBuildingSize = 2) then Request:=1 else Request:=13;
      if ((RepairFactoryShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,13)) and
          (RepairFactoryShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(13,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[13].Parent,13,255);
         Inc(RepairFactoryShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX LETISTE XXXXX }
      if (GameTimming = 0) then Limit:=100
      else Limit:=100 shl 1;
      if ((AirportShortage > 60000) or (AirportShortageForbid <> 0) or
          (not BuildingProductionPossible(Race,11)))
      then AirportShortage:=0;
      if ((ExistBuildings[11] = 0) and (BuildingProductionPossible(Race,11)))
      then begin
        Inc(AirportShortage);
      end;
      Request:=5;
      if ((AirportShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,11)) and
          (AirportShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(11,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[11].Parent,11,255);
         Inc(AirportShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }

      { XXXXX RADAR XXXXX }
      if (GameTimming = 0) then Limit:=100
      else Limit:=100 shl 1;
      if ((RadarShortage > 60000) or (RadarShortageForbid <> 0) or
          (not BuildingProductionPossible(Race,21)))
      then RadarShortage:=0;
      if ((ExistBuildings[21] = 0) and (BuildingProductionPossible(Race,21)))
      then begin
        Inc(RadarShortage);
      end;
      Request:=6;
      if ((RadarShortage > Limit) and (not NotEnoughFreePlaces(Race,Request)) and
          (BuildingProductionPossible(Race,21)) and
          (RadarShortageForbid = 0))
      then begin
         ProductionManager.Insert(Race,GetProdPrioB(21,ProductionPriorityMedium),CreateNewTaskGroupNumber,
                                  MoveBuildCom,Building_types[21].Parent,21,255);
         Inc(RadarShortageForbid);
      end;
      { XXXXXXXXXXXXXXXXXXXX }
   end;
end;

{ *************************************** }
function Production_ai_manager(Race,BuilderType,ProductType,TaskGrp,
                               TaskCom,LockTyp:Byte):Boolean;
{ z pole ProductionList vyjme komponenty a pokusi se je vyrobit
  vraci True, pokud vyroba probehla uspesne;
}
var I,J,K,IP,JP:Word;
    ProdType:Byte;
    BuildingType:Byte;
    PUk, PVybranyUk:PBuilding;
    Request:Byte;
    X1,X2,X3,X4:Word;
    PomDistance, Distance:Word;
begin
 Production_ai_manager:=False;
 with (Races[Race]) do begin
    if ((BuilderType = 8) and (ProductType = 255)) then begin
    { zrus vyrobu plastu }
       PUk:=PointerToBuildings[BuilderType];
       while (PUk <> Nil) do with (PUk^) do begin { prohledej vsechny plastarny }
        if (Production_type <> 0) then begin { pokud produkuji plasty, pak .. }
          if (Building_types[BuildingType].ProductionType = 2) then begin
          { vyrabejici se plasty - zastav vyrobu }
            Production_ai_manager:=True;
            Production_phase:=0;
            Production_percentage:=0;
            Production_type:=0; Production_slot:=0;
            Inc(Building_credits,PLProductionBPNeed);
            Inc(Electric_energy,PLProductionEENeed);
            if (PLShortageForbid > 0) then Dec(PLShortageForbid);
          end;
        end else begin
          if (PLShortageForbid > 0) then Dec(PLShortageForbid);
        end;
        PUk:=PUk^.Next;
       end;
    end else begin { zahajeni nejake vyroby }
       PUk:=PointerToBuildings[BuilderType];
       { nyni budeme hledat volnou tovarnu pro uspokojeni pozadavku }
       PVybranyUk:=Nil; Distance:=65534;

       while (PUk <> Nil) do begin
          if (Building_types[BuilderType].ProductionType = 0) then begin
          { jednotky }
            if ((PUk^.Production_type = 0) and (PUk^.BuildPhase >= 4))
            then begin
               if (TaskGrp < InvalidTaskGroupNumber) then
               with (RacesTGInfo^[Race,TaskGrp]) do begin
                  if (Races[Race].TaskGroups^[TaskGrp].Validity) then
                  with ((Races[Race].TaskGroups^[TaskGrp])) do begin
                      PomDistance:=GetDistance(ITaskGroupInfoPos, JTaskGroupInfoPos,PUk^.IPos,PUk^.JPos);
                  end else
                    if ((IHomeTaskGroupInfoPos < 65535) and
                        (JHomeTaskGroupInfoPos < 65535))
                    then PomDistance:=GetDistance(IHomeTaskGroupInfoPos,JHomeTaskGroupInfoPos,PUk^.IPos,PUk^.JPos)
                    else begin
                       if (PVybranyUk = Nil) then PVybranyUk:=PUk;
                       PomDistance:=65535;
                    end;
                  { vyhodnoceni PomDistance: }
                  if (PomDistance < Distance) then begin
                     PVybranyUk:=PUk; Distance:=PomDistance;
                  end;
               end else begin
                  if (GetUnitPlaceRequest(ProductType) <> 255) then begin
                  { jednotky-budovy }
                      Request:=GetUnitPlaceRequest(ProductType);
                      if (GetFreePlaceForBuilding(Race,IP,JP,Request,False)) then begin
                         PomDistance:=GetDistance(IP,JP,PUk^.IPos,PUk^.JPos);
                         { vyhodnoceni PomDistance: }
                         if (PomDistance < Distance) then begin
                            PVybranyUk:=PUk; Distance:=PomDistance;
                         end;
                      end else begin
                         if (PVybranyUk = Nil) then PVybranyUk:=PUk;
                      end;
                  end else
                    if (PVybranyUk = Nil) then PVybranyUk:=PUk;
               end;
             end;
             PUk:=PUk^.Next;
          end else
            if (Building_types[BuilderType].ProductionType = 1) then begin
            { budovy }
                if ((PUk^.Production_type = 0) and (PUk^.BuildPhase >= 4))
                then begin
                  Request:=GetBuildingPlaceRequest(ProductType);
                  if (GetFreePlaceForBuilding(Race,IP,JP,Request,False)) then begin
                     PomDistance:=GetDistance(IP,JP,PUk^.IPos,PUk^.JPos);
                     { vyhodnoceni PomDistance: }
                     if (PomDistance < Distance) then begin
                        PVybranyUk:=PUk; Distance:=PomDistance;
                     end;
                  end else begin
                     if (PVybranyUk = Nil) then PVybranyUk:=PUk;
                  end;
                end;
                PUk:=PUk^.Next;
            end else begin
               if ((PUk^.Production_type = 0) and (PUk^.BuildPhase >= 4)) then
                 if (PVybranyUk = Nil) then PVybranyUk:=PUk;
               PUk:=PUk^.Next;
            end;
       end;
       PUk:=PVybranyUk;

       if (PUk <> Nil) then begin
         PUk^.TaskGrp:=TaskGrp;
         PUk^.TaskCommand:=TaskCom;
         PUk^.LockType:=LockTyp;
       end;
       if (PUk <> Nil) then with (PUk^) do begin
       { --- VHODNA TOVARNA NALEZENA --- }
         ProdType:=255;
         with (Building_types[BuildingType]) do begin
            for J:=0 to 8 do
              if (Production[J] = ProductType) then ProdType:=J+1;
              { index jednotky v poli Production + 1 }
         end;
         BuildingType:=BuilderType; { typ vyrobni budovy }
         if (Building_types[BuildingType].ProductionType = 0)
         then with (Unit_types[Building_types[BuildingType].Production[ProdType-1],Races[Race].Ally]) do begin
         { XXXXXXXXX vyroba jednotek XXXXXXXXX }
            X1:=BP; X2:=PL; X3:=EE; X4:=Ex;
            if ((BP <= Races[Race].Building_credits) and
                (PL <= Races[Race].Plastic_credits) and
                ((EE <= Races[Race].Electric_energy) or (EE = 0)) and
                (EX <= Races[Race].Battle_experience)) then begin
            {  material staci! }
               if ((UnitLevel = 3) and (SpecAirLevel = 0) and
                   (Races[Race].I_free_airport_space_max_index = 255)) then begin
               { chybi letiste pro vzdusnou jednotku }
                   {XXXXXXXXXXXXXXX  DOPLNIT XXXXXXXXXXXXXXXXXXXXXXX}
               end else begin
                   Production_ai_manager:=True;
                   Dec(Races[Race].Building_credits,BP);
                   Dec(Races[Race].Plastic_credits,PL);
                   Dec(Races[Race].Electric_energy,EE);
                   Dec(Races[Race].Battle_experience,EX);
                   if (BP <> 0) then UpdateBP:=True;
                   if (PL <> 0) then UpdatePL:=True;
                   if (EE <> 0) then UpdateEEEnergy:=True;
                   if (EX <> 0) then UpdateEXP:=True;
                   Production_slot:=1; { INVALID VALUE ! }
                   Production_percentage:=0;
                   Production_type:=ProdType;
                   Production_phase:=0;
               end;
            end else begin
            { nedostatek materialu }
             {XXXXXXXXXXXXXXX  DOPLNIT XXXXXXXXXXXXXXXXXXXXXXX}
               { - nastavime priznak nedostatku materialu - }
               if (BP > Races[Race].Building_credits) then
                  Inc(BPShortage);
               if (PL > Races[Race].Plastic_credits) then begin
                  Inc(PLShortage,2); Inc(PLHiNeed,PL);
               end;
               if (EE > Races[Race].Electric_energy) then
                  Inc(EEShortage);
               if (EX > Races[Race].Battle_experience) then
                  Inc(ExpShortage);
            end;
         end else
            if (Building_types[BuildingType].ProductionType = 1) then
            with (Building_types[Building_types[BuildingType].Production[ProdType-1]]) do begin
            { XXXXXXXXX vyroba budov XXXXXXXXXX }
              X1:=BP; X2:=PL; X3:=EE; X4:=Ex;
              Request:=GetBuildingPlaceRequest(Building_types[BuildingType].Production[ProdType-1]);
              {x}
              if ((BP <= Races[Race].Building_credits) and
                  (PL <= Races[Race].Plastic_credits) and
                  ((EE <= Races[Race].Electric_energy) or (EE = 0)) and
                  (EX <= Races[Race].Battle_experience) and
                  (not NotEnoughFreePlaces(Race,Request))) then begin
              { material staci! }
                 LockType:=255;
                 Production_ai_manager:=True;
                 Dec(Races[Race].Building_credits,BP);
                 Dec(Races[Race].Plastic_credits,PL);
                 Dec(Races[Race].Electric_energy,EE);
                 Dec(Races[Race].Battle_experience,EX);
                 if (BP <> 0) then UpdateBP:=True;
                 if (PL <> 0) then UpdatePL:=True;
                 if (EE <> 0) then UpdateEEEnergy:=True;
                 if (EX <> 0) then UpdateEXP:=True;
                 Production_slot:=1; { INVALID VALUE }
                 Production_percentage:=0;
                 Production_type:=ProdType;
                 Production_phase:=0;
              end else begin
              { nedostatek materialu }
              {XXXXXXXXXXXXXXX  DOPLNIT XXXXXXXXXXXXXXXXXXXXXXX}
                 { - nastavime priznak nedostatku materialu - }
                 if (BP > Races[Race].Building_credits) then
                    Inc(BPShortage);
                 if (PL > Races[Race].Plastic_credits) then begin
                    Inc(PLShortage,2);  Inc(PLHiNeed,PL);
                 end;
                 if (EE > Races[Race].Electric_energy) then
                    Inc(EEShortage);
                 if (EX > Races[Race].Battle_experience) then
                    Inc(ExpShortage);
              end;
            end else
              if (Building_types[BuildingType].ProductionType = 2)
              then begin
              { produkce plastu }
                 if ((PLProductionBPNeed > Building_credits) or
                     (PLProductionEENeed > Electric_energy)) then begin
                 { nemozno produkovat - nedostatek energie }
                     Production_phase:=0;
                     Production_percentage:=0;
                     Production_type:=0;
                     Production_slot:=1; { INVALID VALUE }
                     { DOPLNIT REAKCI NA NEDOSTATEK MATERIALU }
                     {XXXXXXXXXXXXXXX  DOPLNIT XXXXXXXXXXXXXXXXXXXXXXX}
                     {if (PLShortageForbid > 0) then Dec(PLShortageForbid);{}
                 end else begin
                 { lze produkovat dale }
                     Production_ai_manager:=True;
                     Dec(Building_credits,PLProductionBPNeed);
                     Dec(Electric_energy,PLProductionEENeed);
                     { XXX vymazat XXX }
                     UpdateBP:=True;
                     UpdateEEEnergy:=True;
                     { XXX vymazat XXX }
                     Production_slot:=1; { INVALID VALUE }
                     Production_percentage:=0;
                     Production_type:=1;
                 end;
              end;
       end else begin
       { XXXXXXXXXXXXXXXXXXXXXXXXXXXX }
       { vhodna tovarna nenalezena !! }
       end;
    end;
 end; { with (Races) do }
end;

{ ***** }
function GetSurroundings(IP,JP:Word; Friend:Boolean; var EnemyGroundPct,FriendStrength:Single;
                         var Reinf:TReinfo; Race:Byte):Single; forward;

{ *************************************** }
{ ***************************************************************** }
function GetFreePlaceForBuilding(Race:Byte; var IP,JP:Word; Request:Byte; Get:Boolean):Boolean;
{ pro rasu Race zkusi najit vhodny flek pro budovu-jednotku na pozici
  IP,JP a v techto promennych tez vraci pripadne nalezene misto;
  Request je typ alokovaneho mista :
  1..velikost 64x64, vhodne pro tovarny (nouzove lze nahradit typem 2)
  2..velikost 64x64, vhodne pro nevyrobni objekty (nouzove lze nahradit typem 1)
  3..velikost 64x32 (nouzove lze nahradit typem 2, nejhure 1)
  4..velikost 32x32 (nouzove lze nahradit typem 3, vyjmecne 2, nejhure 1)
  NASLEDUJICI BODY NELZE NAHRADIT! :
  5..64x64, rezerv. pro letiste
  6..64x64, rezerv. pro radar
  7..SAM (tezka pevnost), priorita 1 (nejvyssi)
  8..SAM (tezka pevnost), priorita 2
  9..SAM (tezka pevnost), priorita 3 (nejnizsi)
  10..Raketova vez (lehka pevnost), priorita 1 (nejvyssi)
  11..Raketova vez (lehka pevnost), priorita 2
  12..Raketova vez (lehka pevnost), priorita 3 (nejnizsi)
  13..velikost 96x96, vhodne pro tovarny (nouzove lze nahradit cislem 14)
  14..velikost 96x96, vhodne pro nevyrobni objekty  (nouzove lze nahradit cislem 13)
  15..velikost 96x96, specialne pro elektrarny
  16..velikost 96x96, specialne pro recyklaci
  17..velikost 32x32 pro centrum posil
  255..info o stredu cele plochy (polozka s indexem 0)
  Get..True pro likvidaci polozky v seznamu;
       False .. pouze se zjisti nejblizsi misto pro dany pozadavek
  Sama fce pak vraci True, probehla-li operace uspesne
}
label AGAIN;
const ExchangeDistance1_2 = 10; { jedna se minimalni vzdalenost, o kterou
     musi byt volne pole v kategorii 2 blizsi k pozici budovy nez pole
     zatim vybrane typu 1 (chceme 1), aby se mu dala prednost }
      ExchangeDistance2_1 = 10; { viz nahore pro vymenu pole 2 za 1 }
      ExchangeDistance3_x = 10; { viz nahore pro vymenu pole 3 za 1,2}
      Priority1_2 = 3; { pro request 3 vezmu radeji o 5 poli typ 2 nez 1 }
      Priority2_3 = 3; { pro request 4 vezmu radeji o 3 pole typ 3 nez 2 }
      ExchangeDistance4_x = 6; { viz nahore pro vymenu pole 4 za 1,2,3 }
var I,J, IAdept, JAdept, AdeptPlaceType, Delta, PomDelta:Word;
    Konec:Boolean;
    Surr, PomSurr:Single;
    EnemyGroundPct,FriendStrength:Single;
    Reinf:TReinfo;
begin
AGAIN:
  with (Races[Race]) do begin
  { nejprve nalezneme nejblizsi vhodnou oblast }
    if (ActualFreeStructures = 0) then GetFreePlaceForBuilding:=False
    else with (Races[Race]) do begin
      IAdept:=65535; JAdept:=65535; Delta:=65535; AdeptPlaceType:=0; Surr:=1000000;
      for J:=0 to ActualFreeStructures-1 do
        {if (FreePlaces^[0,J].PlaceType = 0) then{}
        for I:=0 to MaxFreePlaces do with (FreePlaces^[I,J]) do begin
           if ((PlaceType > 0) and (I > 0)) then begin
           { jde o platnou polozku }
              PomDelta:=GetDistance(IP,JP,X,Y);
              PomSurr:=GetSurroundings(X div IInfoDiv,Y div JInfoDiv,
                                       Races[MyRace].Friend[Race] > 0,
                                       EnemyGroundPct,FriendStrength,Reinf,Race);
              {PomSurr:=GlobalInfo[0].FriendlyAirStrength+GlobalInfo[0].FriendlyGroundStrength+
                       GlobalInfo[1].FriendlyAirStrength/2+GlobalInfo[1].FriendlyGroundStrength/2;{}
              case (Request) of
                 1 : begin { zadost: 64x64, vyrobni }
                       case (PlaceType) of
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((PomSurr < Surr) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 2) and
                                   (PomDelta < (Delta+ExchangeDistance1_2)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 2) and (PomSurr < Surr) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 1) and
                                   ((PomDelta+ExchangeDistance1_2) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 2 : begin { zadost: 64x64, nevyrobni }
                       case (PlaceType) of
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((PomSurr < Surr) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 1) and
                                   (PomDelta < (Delta+ExchangeDistance2_1)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomSurr < Surr)or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 2) and
                                   ((PomDelta+ExchangeDistance2_1) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 3 : begin { zadost: 64x32 }
                       case (PlaceType) of
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomSurr < Surr) or
                                   (AdeptPlaceType = 2)and((PomDelta+Priority1_2) < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 3) and
                                   ((PomDelta+ExchangeDistance3_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < (Delta+Priority1_2)) or
                                    (AdeptPlaceType = 2)and(PomSurr < Surr) or
                                    (AdeptPlaceType = 0) or
                                    (AdeptPlaceType = 3) and
                                    ((PomDelta+ExchangeDistance3_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                          3 : begin { PlaceType zpracovavaneho pole }
                               if ((PomSurr < Surr) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType < 3) and
                                   (PomDelta < (Delta+ExchangeDistance3_x)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 4 : begin { zadost: 32x32 }
                       case (PlaceType) of
                         1 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomSurr < Surr) or
                                   (AdeptPlaceType = 2)and((PomDelta+Priority1_2) < Delta) or
                                   (AdeptPlaceType = 3)and((PomDelta++Priority1_2+Priority2_3) < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 4) and
                                   ((PomDelta+ExchangeDistance4_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                         2 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < (Delta+Priority1_2)) or
                                   (AdeptPlaceType = 2)and(PomSurr < Surr) or
                                   (AdeptPlaceType = 3)and((PomDelta+Priority2_3) < Delta) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 4) and
                                   ((PomDelta+ExchangeDistance4_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                          3 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 1)and(PomDelta < (Delta+Priority1_2+Priority2_3)) or
                                   (AdeptPlaceType = 2)and(PomDelta < (Delta+Priority2_3)) or
                                   (AdeptPlaceType = 3)and(PomSurr < Surr) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 4) and
                                   ((PomDelta+ExchangeDistance4_x) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                          4 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 0) or
                                   (AdeptPlaceType < 4)and(PomDelta < (Delta+ExchangeDistance4_x)) or
                                   (PomSurr < Surr))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 5 : begin { zadost: 64x64, letiste }
                       if ((PlaceType = 5) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 6 : begin { zadost: 64x64, radar }
                       if ((PlaceType = 6) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 7 : begin { zadost: SAM-tezka pevnost, priorita 1 }
                       if ((PlaceType = 7) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 8 : begin { zadost: SAM-tezka pevnost, priorita 2 }
                       if ((PlaceType = 8) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 9 : begin { zadost: SAM-tezka pevnost, priorita 3 }
                       if ((PlaceType = 9) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 10: begin { zadost: Raketova vez-lehka pevnost, priorita 1 }
                       if ((PlaceType = 10) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 11: begin { zadost: Raketova vez-lehka pevnost, priorita 2 }
                       if ((PlaceType = 11) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 12: begin { zadost: Raketova vez-lehka pevnost, priorita 3 }
                       if ((PlaceType = 12) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 13 : begin { zadost: 96x96, vyrobni }
                       case (PlaceType) of
                         13 : begin { PlaceType zpracovavaneho pole }
                               if ((PomSurr < Surr) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 14) and
                                   (PomDelta < (Delta+ExchangeDistance1_2)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                         14 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 14) and(PomSurr < Surr) or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 13) and
                                   ((PomDelta+ExchangeDistance1_2) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                       end;
                     end;
                 { XXXXXXXXXXXXXXXXX }
                 14 : begin { zadost: 96x96, nevyrobni }
                       case (PlaceType) of
                         14 : begin { PlaceType zpracovavaneho pole }
                               if ((PomSurr < Surr) or (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 13) and
                                   (PomDelta < (Delta+ExchangeDistance2_1)))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                         13 : begin { PlaceType zpracovavaneho pole }
                               if ((AdeptPlaceType = 13)and(PomSurr < Surr)or
                                   (AdeptPlaceType = 0) or
                                   (AdeptPlaceType = 14) and
                                   ((PomDelta+ExchangeDistance2_1) < Delta))
                               then begin
                                 IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                                 Delta:=PomDelta; Surr:=PomSurr;
                               end;
                             end;
                       end;
                     end;
                 15 : begin { zadost: elektrarny }
                       if ((PlaceType = 15) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 16 : begin { zadost: recyklace }
                       if ((PlaceType = 16) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;
                 17 : begin { zadost: centrum posil }
                       if ((PlaceType = 17) and (PomSurr < Surr)) then begin
                          IAdept:=I; JAdept:=J; AdeptPlaceType:=PlaceType;
                          Delta:=PomDelta; Surr:=PomSurr;
                       end;
                     end;

              end;{ case }
           end;
        end; { posledniho for }

        if (AdeptPlaceType <> 0) then with (FreePlaces^[IAdept,JAdept]) do begin
        { uspech ! }
           GetFreePlaceForBuilding:=True;
           if (Get) then begin
              case (Request) of
                1 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                2 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                3 : begin
                      IP:=X; JP:=Y; PlaceType:=0;
                      if (AdeptPlaceType < 3) then begin
                      { pole 64x64 rozpulit }
                         Inc(Y); PlaceType:=3;
                      end;
                    end;
                4 : begin
                      IP:=X; JP:=Y; PlaceType:=0;
                      if (AdeptPlaceType < 3) then begin
                      { pole 64x64 rozdelit na 2x 32x32 a 64x32 }
                         AddFreePlaceForBuilding(Race,X+1,Y,4,0);
                         Inc(Y); PlaceType:=3;
                      end else
                        if (AdeptPlaceType = 3) then begin
                        { pole 64x32 rozpulit }
                          Inc(X); PlaceType:=4;
                        end;
                    end;
                5 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                6 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                7 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                8 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                9 : begin IP:=X; JP:=Y; PlaceType:=0; end;
                10: begin IP:=X; JP:=Y; PlaceType:=0; end;
                11: begin IP:=X; JP:=Y; PlaceType:=0; end;
                12: begin IP:=X; JP:=Y; PlaceType:=0; end;
                13: begin IP:=X; JP:=Y; PlaceType:=0; end;
                14: begin IP:=X; JP:=Y; PlaceType:=0; end;
                15: begin IP:=X; JP:=Y; PlaceType:=0; end;
                16: begin IP:=X; JP:=Y; PlaceType:=0; end;
                17: begin IP:=X; JP:=Y; PlaceType:=0; end;
              else
                GetFreePlaceForBuilding:=False;
              end;
           end else begin { pouze zjisti flek, ale nerus ho }
              IP:=X; JP:=Y;
           end;
        end else begin
          if (Request = 15) then begin { elektrarny lze uspokojit i jinak }
            Request:=14; GoTo AGAIN;
          end;
          if (Request = 16) then begin { recyklaci lze uspokojit i jinak }
            Request:=13; GoTo AGAIN;
          end;
          GetFreePlaceForBuilding:=False;
        end;
    end; { if (ActualFreeStructures = 0) then ... else ... }
  end; { with (Races[Race]) do begin }
end;

{ ************************************************************************** }
{ *************************** UTILITY BEGIN  ******************************* }
{ ************************************************************************** }

procedure AddFreePlaceForBuilding(Race:Byte; IP,JP:Word; Request,Dir:Byte);
{ pro rasu Race zkusi ulozit do tabulky volny flek na pozici
  IP,JP ; Request je typ alokovaneho mista :
  1..velikost 64x64, vhodne pro tovarny
  2..velikost 64x64, vhodne pro nevyrobni objekty
  3..velikost 64x32
  4..velikost 32x32
  5..64x64, rezerv. pro letiste
  6..64x64, rezerv. pro radar
  7..SAM (tezka pevnost), priorita 1 (nejvyssi)
  8..SAM (tezka pevnost), priorita 2
  9..SAM (tezka pevnost), priorita 3 (nejnizsi)
  10..Raketova vez (lehka pevnost), priorita 1 (nejvyssi)
  11..Raketova vez (lehka pevnost), priorita 2
  12..Raketova vez (lehka pevnost), priorita 3 (nejnizsi)
  13..velikost 96x96, vhodne pro tovarny
  14..velikost 96x96, vhodne pro nevyrobni objekty
  15..velikost 96x96, specialne pro elektrarny
  16..velikost 96x96, specialne pro recyklaci
  17..velikost 32x32 pro centrum posil
  Sama fce pak vraci True, probehla-li operace uspesne
  Dir udava smer ukladani:
  0 .. normalne, hledej prvni volne misto od zacatku
  1 .. obracene, hledej prvni volne misto od konce
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
        PomDelta:=abs((Integer(X)-IP)+(Integer(Y)-JP));
        if (PomDelta < Delta) then begin
           Delta:=PomDelta; J:=I;
        end;
      end;
      { nalezen seznam s nejblizsi polohou (promenna J) }
      Konec:=False;
      if (Dir = 0) then begin { od zacatku }
         { nyni 1. volnou pozici }
         I:=1;
         while ((not Konec) and (I <= MaxFreePlaces)) do
         with (FreePlaces^[I,J]) do begin
           if (PlaceType = 0) then begin { pozice nalezena! }
              PlaceType:=Request; X:=IP; Y:=JP; Konec:=True;
           end;
           Inc(I);
         end;
      end else begin { od konce }
         { nyni 1. volnou pozici }
         I := MaxFreePlaces;
         while ((not Konec) and (I > 0)) do
         with (FreePlaces^[I,J]) do begin
           if (PlaceType = 0) then begin { pozice nalezena! }
              PlaceType:=Request; X:=IP; Y:=JP; Konec:=True;
           end;
           Dec(I);
         end;
      end;

    end; { if (ActualFreeStructures = 0) then ... else ... }
  end; { with (Races[Race]) do begin }
end;

{ ************************************************************************** }
{ **************************** UTILITY END  ******************************** }
{ ************************************************************************** }

function CreateNewTaskGroup(Race,Num:Byte; var _unit:PUnit):Byte;
{ funkce vytvori novou TaskGrupu a priradi do ni jednotku _unit;
  sama vraci pridelene cislo TaskGrupy;
  Num je navrh na cislo TG; pokud je tento index volny, pouzije se
  pozn. _unit je povinny parametr!
}
var I:Byte;
    PomDangerClass:Byte;
    TGType:Byte;
begin
 with (Races[Race]) do begin
   I:=0;
   if (Num <= 3) then TGType:=TGAttack else
     if (Num <= 7) then TGType:=TGDefence else
       if (Num <= 9) then TGType:=TGSaboteur else
         if (Num <= 11) then TGType:=TGPlus else
           if (Num = 12) then TGType:=TGPara else begin
              TGType:=TGInvalid;
           end;
   { hledej volne misto v poli TaskGroups }
   if ((Num <= MaxRaceTaskGroups) and (not TaskGroups^[Num].Validity)) then
      I:=Num
   else begin
      case (TGType) of
         TGInvalid : begin
                       I:=13; { pro tento typ TG je to od 13-ti }
                       while ((I <= MaxRaceTaskGroups) and (TaskGroups^[I].Validity))
                       do Inc(I);
                     end;
         TGAttack  : begin
                       I:=0; { pro tento typ TG je to od 0 }
                       while ((TaskGroups^[I].Validity) and (I <= 3)) do Inc(I);
                       if (I > 3) then I:=MaxRaceTaskGroups+1;
                     end;
         TGDefence : begin
                       I:=4; { pro tento typ TG je to od 4}
                       while ((TaskGroups^[I].Validity) and (I <= 7)) do Inc(I);
                       if (I > 7) then I:=MaxRaceTaskGroups+1;
                     end;
         TGSaboteur: begin
                       I:=8; { pro tento typ TG je to od 8 }
                       while ((TaskGroups^[I].Validity) and (I <= 9)) do Inc(I);
                       if (I > 9) then I:=MaxRaceTaskGroups+1;
                     end;
         TGPlus    : begin
                       I:=10; { pro tento typ TG je to od 10 }
                       while ((TaskGroups^[I].Validity) and (I <= 11)) do Inc(I);
                       if (I > 11) then I:=MaxRaceTaskGroups+1;
                     end;
         TGPara    : begin
                       I:=12; { pro tento typ TG je to od 12 }
                       while ((TaskGroups^[I].Validity) and (I <= 12)) do Inc(I);
                       if (I > 12) then I:=MaxRaceTaskGroups+1;
                     end;
      else
        I:=MaxRaceTaskGroups+1;
      end;
   end;

   if ((I > MaxRaceTaskGroups) or (TaskGroups^[I].Validity)) then begin
   { misto nenalezeno nebo jiz obsazeno }
     I:=InvalidTaskGroupNumber;
     {Error(0,'unita AI, procedura CreateNewTaskGroup-chybne cislo TG');{}
   end else with (TaskGroups^[I]) do begin { nova TaskGrupa }
     GroupType:=TGType; KamikadzeMode:=False;
     case (GroupType) of
        TGDefence : AIAttackMode:=2; { jednotky }
        TGAttack  : begin
                      if ((Rand(RndUk)+1) mod 2 = 0) then
                         AIAttackMode:=4 { 50% zaskodnik }
                      else
                        if ((Rand(RndUk)+1) mod 5 = 0) then
                           AIAttackMode:=3 { 10% budovy }
                        else
                           AIAttackMode:=2; { 40% jednotky }
                    end;
        TGSaboteur: begin
                      if ((Rand(RndUk)+1) mod 3 = 0) then
                         AIAttackMode:=3 { 33% budovy }
                      else AIAttackMode:=4; { 66% zaskodnik }
                      if ((Rand(RndUk)+1) mod 3 = 0) then
                        KamikadzeMode:=True;
                    end;
        TGPlus    : begin
                      if ((Rand(RndUk)+1) mod 2 = 0) then
                         AIAttackMode:=4 { 50% zaskodnik }
                      else
                        if ((Rand(RndUk)+1) mod 2 = 0) then
                           AIAttackMode:=3 { 25% budovy }
                        else
                           AIAttackMode:=2; { 25% jednotky }
                    end;
        TGPara    : AIAttackMode:=4; { zaskodnik }
     else
        AIAttackMode:=4;
     end;

     LLightTG[0] :=0; LLightTG[1] :=0; LLightTG[2] :=0;
     LightTG[0]  :=0; LightTG[1]  :=0; LightTG[2]  :=0;
     HeavyTG[0]  :=0; HeavyTG[1]  :=0; HeavyTG[2]  :=0;
     AirTG[0]    :=0; AirTG[1]    :=0; AirTG[2]    :=0;
     AAttackTG[0]:=0; AAttackTG[1]:=0; AAttackTG[2]:=0;
     AntiLightTG:=0; AntiHeavyTG:=0; AntiAirTG:=0;
     TGCapacityNeed:=0;
     with (RacesTGInfo^[Race,I]) do begin
       AALock:=1; ALock:=1; LLock:=1; HLock:=1; CLock:=1;
     end;

     with (Reinfo) do begin
       LLight:=0; Light:=0; Heavy:=0; Air:=0; AAttack:=0;
       EnemyBuildingsWeight:=0; SpecTargets:=0; Difference:=0;
       FriendlyBuildingsWeight:=0;
     end;

     if (Random(100) < RacesTGInfo^[Race,I].SaboteurType) then TrueSaboteur:=True
     else TrueSaboteur:=False;
     {}
     ActiveSearchingFlag:={Random({}ActiveSearchingTGTimeLimit-1{){};
     {}
     Validity:=True; CommandNum:=0; Lock:=0; AirUnitsCount:=0;
     CommandLock:=0; Command:=WithoutCom; MasterCommand:=WithoutCom;
     MasterPhase:=0; MasterITarg:=0; MasterJTarg:=0;
     CommandLockFlagLimit:=0; CommandLockFlag:=0; Special:=0;
     Carriers:=Nil; GrpFree_attack:=True; IgnoreCoefficient:=0;
     NoAttackTimming:=255; { casovani utoku }
     JoinGrp:=255; UnderAttack:=False;
     Fighters:=0; Terminators:=0;
     if (IntelliAttackMovement) then
        DirectTarget:=False
     else DirectTarget:=True;
        Direction:=0;
     {x}
     ClearAttackTGInfo(Race,I);
     {x}
     if (_unit <> Nil) then with (_unit^) do begin
        if (UnitType = 18) then Inc(Fighters);
        if (UnitType = 19) then Inc(Terminators);
        KamikadzeMod:=KamikadzeMode;
        if ((Unit_Types[UnitType,Races[Race].Ally].NeedPlace <= 5) or
            (TaskGroup = 12) and (UnitType = 9))
        then Inc(TGCapacityNeed,Unit_Types[UnitType,Races[Race].Ally].NeedPlace);
        TaskGroup:=I; { prirazeni jednotky }
        ITargPlace:=IInfoPos; JTargPlace:=JInfoPos; Inc(Lock);
        if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
        then Inc(AirUnitsCount);
        with (RacesTGInfo^[Race,I]) do begin
          if ((IHomeTaskGroupInfoPos = 65535) or
              (JHomeTaskGroupInfoPos = 65535) or (I > 10)) then begin
            IHomeTaskGroupInfoPos:=IInfoPos; JHomeTaskGroupInfoPos:=JInfoPos;
          end else begin
          end;
          ITaskGroupInfoPos:=IHomeTaskGroupInfoPos; JTaskGroupInfoPos:=JHomeTaskGroupInfoPos;
        end;

        if (I < 13)
        then with (RacesTGInfo^[Race,I]) do begin
        { jedna se o bojove TG }
          if (TargetType <> 3) then begin
            WayPointMax:=0; WayPointUk:=0;
            Set_move_unit(IHomeTaskGroupInfoPos,JHomeTaskGroupInfoPos,_unit,0,True,False);
          end else begin
            if (not Return_to_base) then begin
              WayPointMax:=0; WayPointUk:=0;
              Set_move_unit(IHomeTaskGroupInfoPos,JHomeTaskGroupInfoPos,_unit,1,True,False);
            end;
          end;
        end;

        Free_attack:=False;
        if (DangerClass <= 2) then PomDangerClass:=0 else
         if (DangerClass <= 5) then PomDangerClass:=1 else
          if (DangerClass <= 7) then PomDangerClass:=2 else
           if (DangerClass = 255) then PomDangerClass:=255;
        case (Unit_types[UnitType,Races[Race].Ally]).TargetTyp of
           0 : if (PomDangerClass <> 255) then Inc(LLightTG[PomDangerClass]);
           1 : if (PomDangerClass <> 255) then Inc(LightTG[PomDangerClass]);
           2 : if (PomDangerClass <> 255) then Inc(HeavyTG[PomDangerClass]);
           3 : if (PomDangerClass <> 255) then Inc(AirTG[PomDangerClass]);
           4 : if (PomDangerClass <> 255) then Inc(HeavyTG[PomDangerClass]);
        else
           Error(0,'unita AI, procedura CreateNewTaskGroup');
        end;
        if (ADangerClass <> 255) then Inc(AAttackTG[ADangerClass]);
        AntiLightTG:=AntiLightTG+Get_unit_anti_weight(Race,UnitType,L,PomDangerClass,ADangerClass);
        AntiHeavyTG:=AntiHeavyTG+Get_unit_anti_weight(Race,UnitType,T,PomDangerClass,ADangerClass);
        AntiAirTG:=AntiAirTG+Get_unit_anti_weight(Race,UnitType,AA,PomDangerClass,ADangerClass);

        CommandNum:=0;
        if (_building) then begin { slozena budova }
          Flag:=GetBuildingPlaceRequest(BuildingType);
        end else begin { if (_building) then begin { slozena budova }
        { normalni jednotka }
          Flag:=254;
        end;
        if (Unit_types[UnitType,Races[Race].Ally].Capacity <> 0) then
          New_task_group_carrier(Race,TaskGroup,_unit);
     end else Error(0,'unita AI, procedura  CreateNewTaskGroup zadana neplatna jednotka');
   end;
   CreateNewTaskGroup:=I;
 end;
end;

{ *************************************************** }
procedure AssignTaskGroup(Race,TaskGroupNum:Byte; var _unit:PUnit);
{ procedura prideli jednotku _unit do taskgrupy TaskGroupNum
}
label Skip;
var I, J:Byte;
    PomDangerClass:Byte;
begin
 with (Races[Race]) do begin
   I:=0;
   { hledej volne misto v poli TaskGroups }
   if (TaskGroups^[TaskGroupNum].Validity) then
   with (TaskGroups^[TaskGroupNum]) do begin
     if ((TaskGroupNum < 10) and
         (GetDistance(ITaskGroupInfoPos,JTaskGroupInfoPos,
                      _unit^.IInfoPos,_unit^.JInfoPos) > 2))
     then begin { cilova TG je prilis daleko - proved blokovy presun za
                  vyuziti pomocne taskgrupy }
        J:=CreateNewTaskGroup(Race,TGInvalid,_unit);
        if ((J = TGInvalid) or (J = InvalidTaskGroupNumber))
        then GoTo Skip; { nedostatek volnych TG }
        TaskGroupCommand(Race,J,MergeCom,0,TaskGroupNum,
                         TaskGroups^[TaskGroupNum].ITaskGroupInfoPos,
                         TaskGroups^[TaskGroupNum].JTaskGroupInfoPos,100);
     end else
Skip:
     with (_unit^) do begin
        TaskGroup:=TaskGroupNum; { prirazeni jednotky }
        KamikadzeMod:=KamikadzeMode;
        if (UnitType = 18) then Inc(Fighters);
        if (UnitType = 19) then Inc(Terminators);
        Inc(Lock);
        if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
        then Inc(AirUnitsCount);
        CommandNum:=TaskGroups^[TaskGroupNum].CommandNum;
        if ((Unit_Types[UnitType,Races[Race].Ally].NeedPlace <= 5) or
            (TaskGroup = 12) and (UnitType = 9))
        then Inc(TGCapacityNeed,Unit_Types[UnitType,Races[Race].Ally].NeedPlace);
        { pri utocnem presunu omezime moznost utoceni }
        Free_attack:=False;
        if (DangerClass <= 2) then PomDangerClass:=0 else
         if (DangerClass <= 5) then PomDangerClass:=1 else
          if (DangerClass <= 7) then PomDangerClass:=2 else
           if (DangerClass = 255) then PomDangerClass:=255;
        case (Unit_types[UnitType,Races[Race].Ally]).TargetTyp of
           0 : if (PomDangerClass <> 255) then Inc(LLightTG[PomDangerClass]);
           1 : if (PomDangerClass <> 255) then Inc(LightTG[PomDangerClass]);
           2 : if (PomDangerClass <> 255) then Inc(HeavyTG[PomDangerClass]);
           3 : if (PomDangerClass <> 255) then Inc(AirTG[PomDangerClass]);
           4 : if (PomDangerClass <> 255) then Inc(HeavyTG[PomDangerClass]);
        else
           Error(0,'unita AI, procedura AssignTaskGroup');
        end;
        if (ADangerClass <> 255) then Inc(AAttackTG[ADangerClass]);
        AntiLightTG:=AntiLightTG+Get_unit_anti_weight(Race,UnitType,L,PomDangerClass,ADangerClass);
        AntiHeavyTG:=AntiHeavyTG+Get_unit_anti_weight(Race,UnitType,T,PomDangerClass,ADangerClass);
        AntiAirTG:=AntiAirTG+Get_unit_anti_weight(Race,UnitType,AA,PomDangerClass,ADangerClass);

        with (RacesTGInfo^[Race,TaskGroupNum]) do begin
          if ((IHomeTaskGroupInfoPos = 65535) or (JHomeTaskGroupInfoPos = 65535))
          then begin
            IHomeTaskGroupInfoPos:=IInfoPos; JHomeTaskGroupInfoPos:=JInfoPos;
          end;
        end;

        if ((Command = WithoutCom) or (Command = PrepareCom))  then begin
        { pokud je TG v klidu, presun jednotku na materskou pozici, jinak
          ji nech plnit rozkazy TG }
           if (TargetType <> 3) then begin
             WayPointMax:=0; WayPointUk:=0;
             Set_move_unit(ITaskGroupInfoPos,JTaskGroupInfoPos,_unit,0,True,False);
           end else begin
             if (not Return_to_base) then begin
                WayPointMax:=0; WayPointUk:=0;
                Set_move_unit(ITaskGroupInfoPos,JTaskGroupInfoPos,_unit,1,True,False);
             end;
           end;
        end;

        if (Unit_types[UnitType,Races[Race].Ally].Capacity <> 0) then
          New_task_group_carrier(Race,TaskGroup,_unit);
     end; { with (_unit^) do begin }
   end;
 end; { with Races[]... }
end;

{ ***** }
procedure InvalidateTaskGroup(Race,TaskGrp:Byte);
{ provede "zneplatneni" taskgrupy TaskGroup
}
var PomVal:Integer;
begin
  with (Races[Race]) do with (TaskGroups^[TaskGrp]) do
  with (RacesTGInfo^[Race,TaskGrp]) do begin
     Validity:=False;
     if ((TaskGrp >= 8) and (TaskGrp <= 9) and (SpecialLock < Timmer2))
     then begin
       if (((Rand(RndUk) mod 2 = 0) or (TimmerPlus = 0)) and
           (TimmerMinus > 0))
       then begin { zaporna  }
         PomVal:=-(Timmer2 div 100)*Random(TimmerMinus);
       end else begin { kladna }
         PomVal:=(Timmer2 div 100)*Random(TimmerPlus);
       end;
       SpecialLock:=Timmer2+PomVal;
     end;
  end;
end;

{ ***** }
procedure Work_on_master_command2(Race,TaskGrp:Byte);
{ je-li aktivni nejaky "MasterCommand", nastavi jako Command TaskGrupy
  nasledujici podfazi
  Mode je mod utoku skupiny (prioritni jednotky, budovy ... )
  PRO PARA SKUPINY !!!!!!!!!!!!!!
}
var _friend:Boolean;

begin
 with (Races[Race]) do begin
   _friend:=(Races[MyRace].Friend[Race] = 2);
   if ((TaskGrp > MaxRaceTaskGroups) or (TaskGrp = InvalidTaskGroupNumber) or
       (not TaskGroups^[TaskGrp].Validity)) then
     Error(0,'unita Ai, procedura Work_on_master_command2')
   else with (TaskGroups^[TaskGrp]) do begin
      case (MasterCommand) of
        AttackCom, MoveCom{ XXXXXXXX  UTOCENI+GROUPMERGE XXXXXXX }
          :begin { nekam se utoci }
             case (MasterPhase) of
             { jednotlive rozpracovane faze }
                0 : begin { nalozeni }
                       Inc(MasterPhase); CommandLock:=0;
                       CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(300);
                       {* inicializace vykonnych prikazu *}
                       Command:=LoadCom;
                       ClearAttackTGInfo(Race,TaskGrp);
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
                1 : begin { nalozeni }
                       if (TGEmptyCarriers(Race,TaskGrp) < TGCarriers(Race,TaskGrp))
                       then Inc(MasterPhase);
                       CommandLock:=0;
                       CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(150);
                       {* inicializace vykonnych prikazu *}
                       Command:=LoadCom;
                       ClearAttackTGInfo(Race,TaskGrp);
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
                2 : begin { preprava }
                       ITargPlace:=ITaskGroupInfoPos; JTargPlace:=JTaskGroupInfoPos;
                       MasterPhase:=10; CommandLock:=0; CommandLockFlag:=0;
                       CommandLockFlagLimit:=GetAccurateDelay(300);
                       ClearAttackTGInfo(Race,TaskGrp);
                       ITargPlace:=MasterITarg; JTargPlace:=MasterJTarg;
                       Command:=BlockMoveCom;
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
               10 : begin { navrat na puvodni pozici, je-li treba }
                      if (NoAttackTimming >= 400) then begin
                       if ((ITaskGroupInfoPos <> RacesTGInfo^[Race,TaskGrp].IHomeTaskGroupInfoPos) or
                            (JTaskGroupInfoPos <> RacesTGInfo^[Race,TaskGrp].JHomeTaskGroupInfoPos))
                       then begin
                         ITargPlace:=RacesTGInfo^[Race,TaskGrp].IHomeTaskGroupInfoPos;
                         JTargPlace:=RacesTGInfo^[Race,TaskGrp].JHomeTaskGroupInfoPos;
                         CommandLock:=0; MasterCommand:=MoveCom;
                         CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(300);
                         ClearAttackTGInfo(Race,TaskGrp);
                         TaskGroupMovement(ITaskGroupInfoPos,JTaskGroupInfoPos,
                                           Direction, ITargPlace,JTargPlace,
                                           Race,TaskGrp,IgnoreCoefficient,
                                           DirectTarget,_friend);
                         Command:=BlockMoveCom;
                         ClearAttackTGInfo(Race,TaskGrp);
                         if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       end else begin
                       end;
                       MasterPhase:=100; GrpFree_attack:=False;
                      end else ;
                    end;
              100 : begin { konec }
                       GrpFree_attack:=False; UnderAttack:=False;
                       ITaskGroupInfoPos:=ITargPlace; JTaskGroupInfoPos:=JTargPlace;
                       TaskGroupCommand(Race,TaskGrp,WithoutCom,0,0,0,0,0);
                       ClearAttackTGInfo(Race,TaskGrp);
                       MasterCommand:=WithoutCom;
                    end;
             end; { case (MasterPhase) of }
           end; { AttackCom  XXXXXXXX  UTOCENI XXXXXXX }
      end; { case (MasterCommand) of }
   end; { else with (TaskGroups[TaskGrp]) do begin }

 end; { with (Races[Race]) do begin }
end;


{ ***** }
procedure Work_on_master_command(Race,TaskGrp:Byte);
{ je-li aktivni nejaky "MasterCommand", nastavi jako Command TaskGrupy
  nasledujici podfazi
  Mode je mod utoku skupiny (prioritni jednotky, budovy ... )
}
var _friend:Boolean;

begin
 with (Races[Race]) do begin
   _friend:=(Races[MyRace].Friend[Race] = 2);
   if ((TaskGrp > MaxRaceTaskGroups) or (TaskGrp = InvalidTaskGroupNumber) or
       (not TaskGroups^[TaskGrp].Validity)) then
     Error(0,'unita Ai, procedura Work_on_master_command')
   else with (TaskGroups^[TaskGrp]) do begin
      case (MasterCommand) of
        AttackCom, MergeCom { XXXXXXXX  UTOCENI+GROUPMERGE XXXXXXX }
          :begin { nekam se utoci }
             case (MasterPhase) of
             { jednotlive rozpracovane faze }
                0 : begin { soustredeni }
                       if ((MasterCommand = MergeCom) and
                           (TaskGroups^[JoinGrp].Validity))
                       then begin
                         TaskGroups^[JoinGrp].CommandLockFlagLimit:=GetAccurateDelay(300);
                         TaskGroups^[JoinGrp].CommandLockFlag:=0;
                       end;
                       Inc(MasterPhase); CommandLock:=0;
                       CommandLockFlag:=0;
                       CommandLockFlagLimit:=GetAccurateDelay(400);
                       if (GroupType = TGSaboteur) then
                         CommandLockFlagLimit:=GetAccurateDelay(500);
                       {* inicializace vykonnych prikazu *}
                       Command:=BlockMoveCom;
                       ITargPlace:=ITaskGroupInfoPos;
                       JTargPlace:=JTaskGroupInfoPos;
                       ClearAttackTGInfo(Race,TaskGrp);
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
                1 : begin { SetAttackMode }
                       if (MasterCommand = MergeCom) then
                         if (TaskGroups^[JoinGrp].Validity) then begin
                            TaskGroups^[JoinGrp].CommandLockFlag:=0;
                            MasterITarg:=TaskGroups^[JoinGrp].ITaskGroupInfoPos;
                            MasterJTarg:=TaskGroups^[JoinGrp].JTaskGroupInfoPos;
                         end else begin
                            TaskGroups^[JoinGrp].CommandLockFlag:=0;
                            MasterITarg:=RacesTGInfo^[Race,JoinGrp].IHomeTaskGroupInfoPos;
                            MasterJTarg:=RacesTGInfo^[Race,JoinGrp].JHomeTaskGroupInfoPos;
                         end;
                       Inc(MasterPhase); CommandLock:=0;
                       CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(5);
                       {* inicializace vykonnych prikazu *}
                       Command:=SetAttackModeCom;
                       ITargPlace:=ITaskGroupInfoPos;
                       JTargPlace:=JTaskGroupInfoPos;
                       ClearAttackTGInfo(Race,TaskGrp);
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
                2 : begin { nalozeni }
                       Inc(MasterPhase); CommandLock:=0;
                       CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(300);
                       {* inicializace vykonnych prikazu *}
                       Command:=LoadCom;
                       ClearAttackTGInfo(Race,TaskGrp);
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
                3 : begin { odpocinek }
                       if (MasterCommand = MergeCom) then
                         if (TaskGroups^[JoinGrp].Validity) then begin
                            TaskGroups^[JoinGrp].CommandLockFlag:=0;
                            MasterITarg:=TaskGroups^[JoinGrp].ITaskGroupInfoPos;
                            MasterJTarg:=TaskGroups^[JoinGrp].JTaskGroupInfoPos;
                         end else begin
                            TaskGroups^[JoinGrp].CommandLockFlag:=0;
                            MasterITarg:=RacesTGInfo^[Race,JoinGrp].IHomeTaskGroupInfoPos;
                            MasterJTarg:=RacesTGInfo^[Race,JoinGrp].JHomeTaskGroupInfoPos;
                         end;
                       Inc(MasterPhase); CommandLock:=0;
                       CommandLockFlag:=0;
                       if (UnderAttack and KamikadzeMode) then begin
                          CommandLockFlagLimit:=0;
                          UnderAttack:=False;
                       end else CommandLockFlagLimit:=
                                     WearOutRepairSpeed*Round(100.0 / WearOutRepair3);
                       {* inicializace vykonnych prikazu *}
                       Command:=RestCom;
                       ClearAttackTGInfo(Race,TaskGrp);
                       if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       GrpFree_attack:=False;
                    end;
                4 : begin{ preprava - prvni presun - ujasni se pozice taskgrupy }
                       if (MasterCommand = MergeCom) then
                         if (TaskGroups^[JoinGrp].Validity) then begin
                            TaskGroups^[JoinGrp].CommandLockFlag:=0;
                            MasterITarg:=TaskGroups^[JoinGrp].ITaskGroupInfoPos;
                            MasterJTarg:=TaskGroups^[JoinGrp].JTaskGroupInfoPos;
                         end else begin
                            MasterITarg:=RacesTGInfo^[Race,JoinGrp].IHomeTaskGroupInfoPos;
                            MasterJTarg:=RacesTGInfo^[Race,JoinGrp].JHomeTaskGroupInfoPos;
                         end;
                       ITargPlace:=ITaskGroupInfoPos;
                       JTargPlace:=JTaskGroupInfoPos;
                       if ((ITaskGroupInfoPos = MasterITarg) and
                           (JTaskGroupInfoPos = MasterJTarg))
                       then MasterPhase:=10
                       else begin
                          MasterPhase:=7;
                          CommandLock:=0;
                          CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(250);
                          ClearAttackTGInfo(Race,TaskGrp);
                          TaskGroupMovement(ITargPlace,JTargPlace,Direction,
                                            MasterITarg,MasterJTarg,Race,TaskGrp,
                                            IgnoreCoefficient,DirectTarget,_friend);
                          Command:=BlockMoveCom;
                          if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                          GrpFree_attack:=False;
                       end;
                    end;
                5 : begin{ preprava - dalsi presuny -
                           aktualizace pozice taskgrupy z I,JTargPlace }
                       if ((MasterCommand = MergeCom) and
                           (TaskGroups^[JoinGrp].Validity)) then
                       with (TaskGroups^[JoinGrp]) do
                       { trochu zmensime flag }
                          if (CommandLockFlag > 0) then begin
                            if (CommandLockFlag < CommandLockFlagLimit shr 1)
                            then CommandLockFlag:=CommandLockFlag-CommandLockFlag shr 2
                            else CommandLockFlag:=CommandLockFlagLimit shr 1;
                          end;
                       if ((MasterCommand = MergeCom) and
                           (TaskGroups^[JoinGrp].Validity) and
                           ((TaskGroups^[JoinGrp].Command = WithoutCom) or
                            (TaskGroups^[JoinGrp].Command = PrepareCom)))
                       { flag jen jen pro klidnou TG }
                       then TaskGroups^[JoinGrp].CommandLockFlag:=0;
                       if (MasterCommand = MergeCom) then
                         if (TaskGroups^[JoinGrp].Validity) then begin
                            MasterITarg:=TaskGroups^[JoinGrp].ITaskGroupInfoPos;
                            MasterJTarg:=TaskGroups^[JoinGrp].JTaskGroupInfoPos;
                         end else begin
                            MasterITarg:=RacesTGInfo^[Race,JoinGrp].IHomeTaskGroupInfoPos;
                            MasterJTarg:=RacesTGInfo^[Race,JoinGrp].JHomeTaskGroupInfoPos;
                         end;
                       ITaskGroupInfoPos:=ITargPlace;
                       JTaskGroupInfoPos:=JTargPlace;
                       Inc(MasterPhase);
                       if ((ITaskGroupInfoPos = MasterITarg) and
                           (JTaskGroupInfoPos = MasterJTarg))
                       then MasterPhase:=10
                       else begin
                          CommandLock:=0;
                          CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(250);
                          ITargPlace:=ITaskGroupInfoPos;
                          JTargPlace:=JTaskGroupInfoPos;
                          ClearAttackTGInfo(Race,TaskGrp);
                          TaskGroupMovement(ITargPlace,JTargPlace,Direction,
                                            MasterITarg,MasterJTarg,Race,TaskGrp,
                                            IgnoreCoefficient,DirectTarget,_friend);
                          Command:=BlockMoveCom;
                          if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       end;
                       GrpFree_attack:=False;
                       {if ((ITargPlace = MasterITarg) and
                           (JTargPlace = MasterJTarg))
                       then begin
                          MasterPhase:=10;
                          GrpFree_attack:=True;
                       end;{}
                    end;
                6 : begin { nalozeni }
                       if (MasterCommand = MergeCom) then
                         if (TaskGroups^[JoinGrp].Validity) then begin
                            MasterITarg:=TaskGroups^[JoinGrp].ITaskGroupInfoPos;
                            MasterJTarg:=TaskGroups^[JoinGrp].JTaskGroupInfoPos;
                         end else begin
                            MasterITarg:=RacesTGInfo^[Race,JoinGrp].IHomeTaskGroupInfoPos;
                            MasterJTarg:=RacesTGInfo^[Race,JoinGrp].JHomeTaskGroupInfoPos;
                         end;
                       Inc(MasterPhase);
                       ITaskGroupInfoPos:=ITargPlace;
                       JTaskGroupInfoPos:=JTargPlace;
                       if ((ITaskGroupInfoPos = MasterITarg) and
                           (JTaskGroupInfoPos = MasterJTarg))
                       then MasterPhase:=10 else begin
                         {* inicializace vykonnych prikazu *}
                         CommandLock:=0;
                         CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(300);
                         Command:=LoadCom;
                         ClearAttackTGInfo(Race,TaskGrp);
                         if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                         GrpFree_attack:=False;
                       end;
                    end;
                7 : begin { odpocinek }
                       if ((MasterCommand = MergeCom) and
                           (TaskGroups^[JoinGrp].Validity)) then
                       with (TaskGroups^[JoinGrp]) do
                       { trochu zmensime flag }
                          if (CommandLockFlag > 0) then begin
                            if (CommandLockFlag < CommandLockFlagLimit shr 1)
                            then CommandLockFlag:=CommandLockFlag-CommandLockFlag shr 2
                            else CommandLockFlag:=CommandLockFlagLimit shr 1;
                          end;
                       if (MasterCommand = MergeCom) then
                         if (TaskGroups^[JoinGrp].Validity) then begin
                            MasterITarg:=TaskGroups^[JoinGrp].ITaskGroupInfoPos;
                            MasterJTarg:=TaskGroups^[JoinGrp].JTaskGroupInfoPos;
                         end else begin
                            MasterITarg:=RacesTGInfo^[Race,JoinGrp].IHomeTaskGroupInfoPos;
                            MasterJTarg:=RacesTGInfo^[Race,JoinGrp].JHomeTaskGroupInfoPos;
                         end;
                       MasterPhase:=5;
                       ITaskGroupInfoPos:=ITargPlace;
                       JTaskGroupInfoPos:=JTargPlace;
                       if ((ITaskGroupInfoPos = MasterITarg) and
                           (JTaskGroupInfoPos = MasterJTarg))
                       then MasterPhase:=10 else begin
                         CommandLockFlag:=0; CommandLock:=0;
                         if (UnderAttack and KamikadzeMode) then begin
                            CommandLockFlagLimit:=0;
                            UnderAttack:=False;
                         end else
                            CommandLockFlagLimit:=Round(WearOutRepairSpeed*(100.0 /
                                                        ((WearOutRepair1+WearOutRepair2+
                                                         WearOutRepair3+WearOutRepair4+
                                                         WearOutRepair5+WearOutRepair6)/6)));
                         {* inicializace vykonnych prikazu *}
                         Command:=RestCom;
                         ClearAttackTGInfo(Race,TaskGrp);
                         if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                         GrpFree_attack:=False;
                       end;
                    end;
               10 : begin { navrat na puvodni pozici, je-li treba }
                      if (NoAttackTimming >= 100) then begin
                       if (((ITaskGroupInfoPos <> RacesTGInfo^[Race,TaskGrp].IHomeTaskGroupInfoPos) or
                            (JTaskGroupInfoPos <> RacesTGInfo^[Race,TaskGrp].JHomeTaskGroupInfoPos)) and
                           ((GroupType = TGDefence) or (GroupType = TGSaboteur) or
                            (GroupType = TGPlus)) and (MasterCommand <> MergeCom))
                       then begin
                         ITargPlace:=RacesTGInfo^[Race,TaskGrp].IHomeTaskGroupInfoPos;
                         JTargPlace:=RacesTGInfo^[Race,TaskGrp].JHomeTaskGroupInfoPos;
                         CommandLock:=0;
                         CommandLockFlag:=0; CommandLockFlagLimit:=GetAccurateDelay(300);
                         ClearAttackTGInfo(Race,TaskGrp);
                         TaskGroupMovement(ITaskGroupInfoPos,JTaskGroupInfoPos,
                                           Direction, ITargPlace,JTargPlace,
                                           Race,TaskGrp,IgnoreCoefficient,
                                           DirectTarget,_friend);
                         Command:=BlockMoveCom;
                         ClearAttackTGInfo(Race,TaskGrp);
                         if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       end else begin
                       end;
                       MasterPhase:=100; GrpFree_attack:=False;
                       if (MasterCommand = MergeCom) then begin
                         Command:=UnLoadCom;
                         ClearAttackTGInfo(Race,TaskGrp);
                         if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                       end;
                      end else ;
                    end;
              100 : begin { konec }
                       GrpFree_attack:=False; UnderAttack:=False;
                       ITaskGroupInfoPos:=ITargPlace;
                       JTaskGroupInfoPos:=JTargPlace;
                       if (MasterCommand = MergeCom) then begin
                          TaskGroupCommand(Race,TaskGrp,JoinCom,0,JoinGrp,0,0,0);
                          if (TaskGroups^[JoinGrp].Validity)
                          then TaskGroups^[JoinGrp].CommandLockFlag:=
                               TaskGroups^[JoinGrp].CommandLockFlagLimit - 2;
                       end else
                          TaskGroupCommand(Race,TaskGrp,WithoutCom,0,0,0,0,0);
                       ClearAttackTGInfo(Race,TaskGrp);
                       MasterCommand:=WithoutCom;
                    end;
             end; { case (MasterPhase) of }
           end; { AttackCom  XXXXXXXX  UTOCENI XXXXXXX }
      end; { case (MasterCommand) of }
   end; { else with (TaskGroups[TaskGrp]) do begin }

 end; { with (Races[Race]) do begin }
end;

{ ************************************************* }
procedure TaskGroupCommand(Race,TaskGrp,TaskCommand,Level,Mode:Byte; IP,JP:Word;
                           IgnoreCoeff:Double);
{ TaskGrupe TaskGrp rasy Race priradi prikaz TaskCommand;
  IP, JP se pouziva jako cil presunu pro prikaz presunu;
  - pro MoveBuildCom se vyhleda v poli FreePlaces volne misto
  a priradi se grupe jako cil presunu (predpoklada se 1 jednotka v grupe)
  - pro HarvestCom se vyhleda nejblizsi zdroj a priradi jako cil harvesteru
  Level udava uroven presunu (0..pozemni, 1..vzdusna)
  Mode udava pro utok typ utocne aktivity (priority):
      0..specialni budova AIAttackBuilding
      1..specialni jednotka AIAttackUnit
      2..jednotky
      3..budovy
      4..zaskodnictvi
  IgnoreCoeff slouzi pro utok:
  -udava, jaka sila nepratel se bude pri vypoctu trasy taskgrupy ignorovat;
  hodnota udava % ze sily taskgrupy; napr. pro 25 = ignorovat silu o hodnote
  jedne ctvrtiny sily taskgrupy
}
begin
 with (Races[Race]) do begin
   if ((TaskGrp > MaxRaceTaskGroups) or (TaskGrp = InvalidTaskGroupNumber) or
       (not TaskGroups^[TaskGrp].Validity)) then
     Error(0,'unita Ai, procedura TaskGroupCommand'){}
     {IP:=IP{}
   else
   if ((TaskCommand <> MergeCom) or (TaskCommand <> TaskGroups^[TaskGrp].MasterCommand))
   then with (TaskGroups^[TaskGrp]) do begin
      Command:=TaskCommand; MoveLevel:=Level;
      ClearAttackTGInfo(Race,TaskGrp);
      case (Command) of
         AttackCom    : begin
                           MasterCommand:=AttackCom; UnderAttack:=False;
                           MasterPhase:=0;
                           MasterITarg:=IP; MasterJTarg:=JP;
                           CommandLock:=0; Command:=WithoutCom;
                           if (IntelliAttackMovement) then
                             DirectTarget:=False
                           else DirectTarget:=True;
                           Direction:=0;
                           Special:=Mode; GrpFree_attack:=False;
                           IgnoreCoefficient:=IgnoreCoeff;
                           if (TaskGrp <> 12) then
                             Work_on_master_command(Race,TaskGrp)
                           else
                             Work_on_master_command2(Race,TaskGrp);
                        end;
         MoveCom      : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           ITargPlace:=IP; JTargPlace:=JP;
                           Special:=Mode; GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         BlockMoveCom : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           ITargPlace:=IP; JTargPlace:=JP;
                           Special:=Mode; GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         MoveBuildCom : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom; Special:=Mode;
                           if ((Flag < 254) and GetFreePlaceForBuilding(Race,
                                                 ITargPlace,JTargPlace, Flag,True))
                           then begin
                           { misto nalezeno ! }
                           end else
                             if (Flag < 254) then begin
                             { nenalezeno misto pro rozlozeni budovy a nejde
                               o jednotku-budovu }
                              Command:=WithoutCom;{}
                             end;
                           GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         HarvestCom  : begin
                          { nezname ukazatel na harvester - nemozno nic
                            v teto fazi delat }
                          if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                          MasterCommand:=WithoutCom;
                          Special:=Mode;
                          GrpFree_attack:=True;
                          IgnoreCoefficient:=IgnoreCoeff;
                        end;
         LoadCom      : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           Special:=Mode;
                           GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         SetAttackModeCom: begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           AIAttackMode:=Mode;
                           GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         RestCom      : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         PrepareCom   : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           ITargPlace:=IP; JTargPlace:=JP;
                           MasterCommand:=WithoutCom;
                           GrpFree_attack:=False;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         MergeCom     : begin
                        { pozn. v "MERGE" modu je TG nepouzitelna a musi se
                          zrusit }
                           if (TaskGrp < 10) then
                              ProductionManager.ClearAllTGProduction(Race,TaskGrp);
                           JoinGrp:=Mode;
                           if ((TaskGroups^[Mode].Validity) and
                               ((TaskGroups^[Mode].Command = WithoutCom) or
                                (TaskGroups^[Mode].Command = PrepareCom)))
                           then TaskGroupCommand(Race,Mode,WaitCom,MoveLevel,0,0,0,0);
                           MasterCommand:=MergeCom;
                           MasterPhase:=0;
                           MasterITarg:=IP; MasterJTarg:=JP;
                           CommandLock:=0; Command:=WithoutCom;
                           if (IntelliAttackMovement) then
                             DirectTarget:=False
                           else DirectTarget:=True;
                           Direction:=0;
                           Special:=Mode; GrpFree_attack:=False;
                           IgnoreCoefficient:=IgnoreCoeff;
                           Work_on_master_command(Race,TaskGrp);
                        end;
         JoinCom       : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           GrpFree_attack:=True;
                           Special:=Mode; { cilova TG }
                         end;
         WaitCom       : begin
                            if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                            CommandLockFlagLimit:=GetAccurateDelay(300);
                            CommandLockFlag:=0;
                         end;
         WithoutCom    : begin
                            if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                         end;
         UnLoadCom     : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           Special:=Mode;
                           GrpFree_attack:=True;
                           IgnoreCoefficient:=IgnoreCoeff;
                        end;
         RemakeCom    : begin
                           if (CommandNum = 255) then CommandNum:=1 else Inc(CommandNum);
                           MasterCommand:=WithoutCom;
                           GrpFree_attack:=True;
                           JoinGrp:=Mode; { cilova TG }
                        end;
      end;
   end;
 end;
end;

{ ***** }
procedure ExecuteTaskGroupCommand(var _unit:PUnit);
{ pro jednotku _unit provede prikaz jeji taskgrupy
}
label Konec;
var ISiz,IP,JP:Word;
    PomUnit, PomUnit2:PUnit;
    Request:Byte;
    Success:Boolean;
    PomDangerClass:Word;
begin
  with (_unit^) do with (Races[Race]) do begin
     if ((_unit^.UnitType = 37) and (TargetType = 3) and (Down = 0) and
         (UnitsInsideNum > 0) and ((TaskGroups^[TaskGroup].MasterCommand <> WithoutCom) and
         ((TaskGroups^[TaskGroup].GrpFree_attack) or
          (TaskGroups^[TaskGroup].MasterPhase = 10) or
          (TaskGroups^[TaskGroup].MasterPhase = 100) { and
          (TaskGroups^[TaskGroup].ITaskGroupInfoPos = TaskGroups^[TaskGroup].MasterITarg) and
          (TaskGroups^[TaskGroup].JTaskGroupInfoPos = TaskGroups^[TaskGroup].MasterJTarg){})))
     then begin
     { DONUT CHINOOK SEDNOUT }
         Unload(_unit); Down:=2;
{         IP:=IPos; JP:=JPos;  Attacking:=False;
         if (Down = 2) then ISiz:=UnitsInsideNum else ISiz:=LoadOkFreePlaces;
         if (Find_free_place_for_landing(IP,JP,ISiz)) then begin
         { nalezeno volne misto pro pristani }
{           WayPointMax:=0; WayPointUk:=0;
           Set_move_unit(IP,JP,_unit,0,False,False);
         end else Down:=0;{}
         GoTo Konec;
     end else begin
       if ((_unit^.UnitType = 37) and (Down = 2))
       then GoTo KOnec;
     end;
     {X}
     Load_flag:=0;
     if ((TaskGroup = 12) and
         (((TGEmptyCarriers(Race,TaskGroup)+TaskGroups^[TaskGroup].Fighters+
            TaskGroups^[TaskGroup].Terminators) = TaskGroups^[TaskGroup].Lock) or
          (TGCarriers(Race,TaskGroup) = 0)) and
         (TaskGroups^[TaskGroup].MasterCommand <> WithoutCom)) then begin
     { para TG bez vysadkaru nebo paraletounu - vse stopni }
        TaskGroupCommand(Race,TaskGroup,WithoutCom,0,0,0,0,0);
        TaskGroups^[TaskGroup].MasterCommand:=WithoutCom;
     end;

     CommandNum:=TaskGroups^[TaskGroup].CommandNum; Attacking:=False;
     if (not Return_to_base) then with (TaskGroups^[TaskGroup]) do begin
        ClearAttackTGInfo(Race,TaskGroup);
        case (Command) of
           AttackCom    : begin
                          end;
           MoveCom      : begin
                            WayPointMax:=0; WayPointUk:=0; Down:=0;
                            if (Unit_types[_unit^.UnitType,Races[Race].Ally].TargetTyp = 3) then
                            { letecky }
                              Set_move_unit(ITargPlace,JTargPlace,_unit,1,False,False)
                            else
                            { jinak }
                              Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False)
                          end;
           BlockMoveCom : begin
                            if ((TaskGroup <> 12) or
                                (MasterCommand = AttackCom) and
                                (Unit_types[_unit^.UnitType,Races[Race].Ally].TargetTyp = 3) and
                                (Unit_types[_unit^.UnitType,Races[Race].Ally].SpecAirLevel = 0) and
                                (not Return_to_base) or
                                (MasterCommand <> AttackCom) and
                                ((Unit_types[_unit^.UnitType,Races[Race].Ally].TargetTyp <> 3) or
                                 (Unit_types[_unit^.UnitType,Races[Race].Ally].SpecAirLevel > 0)))
                            then begin
                                if (Unit_types[_unit^.UnitType,Races[Race].Ally].TargetTyp = 3) then begin
                                { letecky }
                                  if (TaskGroup <> 12) then begin
                                    if ((IInfoPos <> ITargPlace) or (JInfoPos <> JTargPlace) or
                                        (MasterPhase < 4)) then begin
                                      WayPointMax:=0; WayPointUk:=0; Down:=0;
                                      Set_move_unit(ITargPlace,JTargPlace,_unit,1,True,False);
                                    end;
                                  end else begin { TG 12 - nahodny rozptyl }
                                      IP:=ITargPlace; JP:=JTargPlace;
                                      IP:=IP*(IInfoDiv)+IInfoDiv shr 2+(Rand(RndUk)+3) shr 1;
                                      if (IP >= IMax) then IP:=IMax-1;
                                      JP:=JP*(JInfoDiv)+JInfoDiv shr 2+(Rand(RndUk)+3) shr 1;
                                      if (JP >= JMax) then JP:=JMax-1;
                                      WayPointMax:=0; WayPointUk:=0; Down:=0;
                                      Set_move_unit(IP,JP,_unit,1,False,False);
                                  end;
                                end else begin
                                { jinak }
                                  if ((IInfoPos <> ITargPlace) or (JInfoPos <> JTargPlace) or
                                      (MasterPhase < 4)) then begin
                                    WayPointMax:=0; WayPointUk:=0; Down:=0;
                                    Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,True,False);
                                  end;
                                end;
                            end;
                          end;
           MoveBuildCom : begin
                            Success:=True;
                            if ((_unit^.UnitType = 33) and (not _unit^._building))
                            then begin { jednotka-budova }
                              case (BuildingType) of
                                20 : Request:= 10; { lehka pevnost }
                                21 : Request:= 7; { tezka pevnost }
                                31 : Request:= 10; { raketova vez }
                                32 : Request:= 7; { infra SAM }
                                41 : Request:= 17; { centrum posil }
                              else
                                while True do { chybka, zde se to zastavi }
                                  Request:=Request;
                              end;
                              if (not GetFreePlaceForBuilding(Race,ITargPlace,JTargPlace,Request,True)) then
                               if (not GetFreePlaceForBuilding(Race,ITargPlace,JTargPlace,Request+1,True)) then
                                 if (not GetFreePlaceForBuilding(Race,ITargPlace,JTargPlace,Request+2,True)) then
                                   Success:=False;
                            end;
                            if (Success) then begin
                              WayPointMax:=0; WayPointUk:=0;
                              Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                            end;
                          end;
           HarvestCom   : begin
                            { zkus najit zdroj }
                            IP:=IPos; JP:=JPos;
                            if (Find_resource_for_recyklator(IP,JP)) then begin
                            { zdroj nalezen! }
                              ITargPlace:=IP; JTargPlace:=JP; MoveLevel:=0;
                              WayPointMax:=0; WayPointUk:=0;
                              Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                            end;
                          end;
           LoadCom     : begin { nalozeni }
                           if ((Unit_types[UnitType,Races[Race].Ally].NeedPlace <= 5) or
                               (UnitType = 35) or (UnitType = 9))
                           then begin
                           { jednotka s minimalnimi naroky na misto nebo
                             lehky kanon - zkusime je nalozit }
                              PomUnit2:=Nil;
                              PomUnit:=Get_task_group_carrier(Race,TaskGroup,
                                       PomUnit2,_unit,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                              if (PomUnit <> Nil) then begin
                              { vhodny carrier nalezen }
                                if (PomUnit^.TargetType = 3) then begin
                                { letajici carrier at si sedne }
                                   PomUnit^.Down:=1;
                                { dokud si nesedne, neposleme do nej nic }
                                end else begin
                                  GetBestCarrierLoadPos(IP,JP,PomUnit^.IPos,PomUnit^.JPos,IPos,JPos,UnitType);
                                  MoveLevel:=0;
                                  _unit^.GoInside:=True;
                                  WayPointMax:=0; WayPointUk:=0;
                                  Set_move_unit(IP,JP,_unit,MoveLevel,False,True);
                                end;
                              end;
                           end;
                        end;
           SetAttackModeCom: begin { nastaveni modu utoceni }
                               AIAttackType:=AIAttackMode;{}
                             end;
           RestCom      : begin
                          end;
           PrepareCom   : begin
                          end;
           MergeCom     : begin { provede Merge }
                          end;
           JoinCom     : begin { provede join }
                            Dec(Lock);
                            if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                            then Dec(AirUnitsCount);
                            if (Unit_types[UnitType,Races[Race].Ally].Capacity <> 0) then
                               Delete_task_group_carrier(Race,TaskGroup,_unit);
                            if (Lock = 0) then
                               InvalidateTaskGroup(Race,TaskGroup);
                            if (TaskGroups^[JoinGrp].Validity) then
                              AssignTaskGroup(Race,JoinGrp,_unit)
                            else
                              CreateNewTaskGroup(Race,JoinGrp,_unit);

                            if (UnitsInsideNum > 0) then
                              SetNewTGNumberForUnitsInside(_unit,JoinGrp);
                          end;
           RemakeCom    : begin
                            if (Rand(RndUk) < 5) then begin
                            { pouze pro nektere jednotky }
                               Dec(Lock);
                               if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                               then Dec(AirUnitsCount);
                               if (Unit_Types[UnitType,Races[Race].Ally].NeedPlace <= 5)
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

                               if (TaskGroups^[JoinGrp].Validity) then
                                 AssignTaskGroup(Race,JoinGrp,_unit)
                               else
                                 CreateNewTaskGroup(Race,JoinGrp,_unit);

                               if (UnitsInsideNum > 0) then
                                 SetNewTGNumberForUnitsInside(_unit,JoinGrp);
                            end;
                           end;
           WaitCom       : begin
                           end;
           WithoutCom    : begin
                           { po provedeni master command se zastavime }
                              if ((Status <> 0) and (MoveStatus <= 1))
                              then STOP_:=True;
                           end;
           UnLoadCom     : begin
                              if (UnitsInsideNum > 0) then UnLoad(_unit);
                              if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then Down:=2;
                           end;

        end; { case }
     end; { with (TaskGroups[TaskGroup]) do begin }
     Awaiting_for_further_orders:=False;
  end;
Konec:
end;

{ ***** }
procedure CheckExecuteTaskGroupCommand(var _unit:PUnit);
{ zkontroluje provedeni prikazu taskgrupy, respektive jej dokonci pro
  konkretni jednotku;
}
var Pom,BuildingTyp:Byte;
    ISiz,JSiz,IP,JP:Word;
    PomUnit, PomUnit2:PUnit;
    Done:Boolean;
begin
  PomUnit:=Nil;
  with (_unit^) do with (Races[Race]) do begin
     if ((_unit^.UnitType = 37) and (TargetType = 3) and (Down = 0) and
         (UnitsInsideNum > 0) and ((TaskGroups^[TaskGroup].MasterCommand <> WithoutCom) and
         ((TaskGroups^[TaskGroup].GrpFree_attack) or
          (TaskGroups^[TaskGroup].MasterPhase = 10) or
          (TaskGroups^[TaskGroup].MasterPhase = 100) { and
          (TaskGroups^[TaskGroup].ITaskGroupInfoPos = TaskGroups^[TaskGroup].MasterITarg) and
          (TaskGroups^[TaskGroup].JTaskGroupInfoPos = TaskGroups^[TaskGroup].MasterJTarg){})))
     then begin
     { DONUT CHINOOK SEDNOUT }
         Unload(_unit); Down:=2;
     end;
     {xxx}
     if ((TaskGroup = 12) and
         (((TGEmptyCarriers(Race,TaskGroup)+TaskGroups^[TaskGroup].Fighters+
            TaskGroups^[TaskGroup].Terminators) = TaskGroups^[TaskGroup].Lock) or
          (TGCarriers(Race,TaskGroup) = 0)) and
         (TaskGroups^[TaskGroup].MasterCommand <> WithoutCom)) then begin
     { para TG bez vysadkaru - vse stopni }
        TaskGroupCommand(Race,TaskGroup,WithoutCom,0,0,0,0,0);
        TaskGroups^[TaskGroup].MasterCommand:=WithoutCom;
     end;
     {xxx}
     if ((Down > 0) and (TargetType = 3)) then begin
     { letecka jednotka - sedni si }
         IP:=IPos; JP:=JPos;  Attacking:=False;
         if (Down = 2) then ISiz:=UnitsInsideNum else ISiz:=LoadOkFreePlaces;
         if (Find_free_place_for_landing(IP,JP,ISiz)) then begin
         { nalezeno volne misto pro pristani }
           WayPointMax:=0; WayPointUk:=0;
           Set_move_unit(IP,JP,_unit,0,False,False);
         end else Down:=0;
     end else begin
        with (TaskGroups^[TaskGroup]) do begin
           case (Command) of
              AttackCom    : begin
                               if (MasterCommand <> WithoutCom) then begin
                               { zkontroluj provedeni kazde z podfazi }
                                 if (not Awaiting_for_further_orders) then begin
                                   Inc(CommandLock);
                                   Awaiting_for_further_orders:=True;
                                 end;
                                 if ((CommandLock >= Lock) or
                                     (CommandLockFlag >= CommandLockFlagLimit))
                                 then begin
                                   if (TaskGroup <> 12) then
                                     Work_on_master_command(Race,TaskGroup)
                                   else
                                     Work_on_master_command2(Race,TaskGroup);
                                 end;
                               end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
              MoveCom      : begin
                               if (MasterCommand <> WithoutCom) then begin
                               { zkontroluj provedeni kazde z podfazi }
                                 if (not Awaiting_for_further_orders) then begin
                                   Inc(CommandLock);
                                   Awaiting_for_further_orders:=True;
                                 end;
                                 if ((CommandLock >= Lock) or
                                     (CommandLockFlag >= CommandLockFlagLimit))
                                 then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                    then Work_on_master_command2(Race,TaskGroup)
                                    else Work_on_master_command(Race,TaskGroup);
                                 end;
                               end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
              BlockMoveCom : begin
                               if (MasterCommand <> WithoutCom) then begin
                               { zkontroluj provedeni kazde z podfazi }
                                 if ((ITargPlace = MasterITarg) and
                                     (JTargPlace = MasterJTarg))
                                 then Free_attack:=True;{}
                                 if (not Awaiting_for_further_orders) then begin
                                   Inc(CommandLock);
                                   Awaiting_for_further_orders:=True;
                                 end;
                                 if ((CommandLock >= Lock) or
                                     (CommandLockFlag >= CommandLockFlagLimit))
                                 then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                   then Work_on_master_command2(Race,TaskGroup)
                                   else Work_on_master_command(Race,TaskGroup);
                                 end;
                               end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
              MoveBuildCom : begin
                               if (_building) then begin
                               { budova }
                                 ISiz:=Building_types[BuildingType].IBuildingSize;
                                 JSiz:=Building_types[BuildingType].JBuildingSize;
                               end else begin
                               { jednotka typu raketova vez }
                                 ISiz:=Unit_types[UnitType,Races[Race].Ally].IUnitSize;
                                 JSiz:=Unit_types[UnitType,Races[Race].Ally].JUnitSize;
                               end;
                               if (IPos = ITargPlace) and (JPos = JTargPlace) then begin
                               { jednotka dorazila na misto - rozloz ji }
                                  BuildingTyp:=BuildingType;
                                  if (Rozloz_unit(False,_unit)) then begin
                                     {case (BuildingTyp) of
                                     { odstranit zakaz pro danou komoditu }
                                     {   4 : if (BPShortageForbid > 0)
                                            then Dec(BPShortageForbid);
                                        5 : if (EEShortageForbid > 0)
                                            then Dec(EEShortageForbid);
                                        6 : if (AccumulatorShortageForbid > 0)
                                            then Dec(AccumulatorShortageForbid);
                                     end;{}
                                     Dec(Lock);
                                     if (Lock = 0) then InvalidateTaskGroup(Race,TaskGroup);
                                  end else begin
                                  { nemozno rozlozit - pravdepodobne nedostatek
                                    mista }
                                     if (UnBlock_place(IPos,JPos,
                                         IPos+ISiz,JPos+JSiz,Race,_unit) = 1) then begin
                                     { OK, chyba se resi - zadny kod }
                                     end else begin
                                     { neprekonatelna prekazka - vyber novy flek }
                                        TaskGroupCommand(Race,TaskGroup,MoveBuildCom,0,4,0,0,IgnoreCoefficient);
                                     { PUVODNI MISTO SE UZ NIKDY NEPOUZIJE ! }
                                     end;
                                  end;
                               end else begin
                               { jednotka z neznamych duvodu nedorazila na misto }
                                   if (UnBlock_place(ITargPlace,JTargPlace,
                                       ITargPlace+ISiz,JTargPlace+JSiz,Race,PomUnit) = 1)
                                   then begin
                                   { OK, chyba se resi }
                                     WayPointMax:=0; WayPointUk:=0;
                                     Set_move_unit(ITargPlace,JTargPlace,
                                     _unit,0,False,False);
                                   end else begin
                                   { neprekonatelna prekazka - vyber novy flek }
                                     TaskGroupCommand(Race,TaskGroup,MoveBuildCom,0,4,0,0,IgnoreCoefficient);
                                   { PUVODNI MISTO SE UZ NIKDY NEPOUZIJE ! }
                                   end;
                               end;
                             end;
              HarvestCom   : begin
                                IP:=IPos; JP:=JPos;
                                if (not Working) then
                                { harvester necinne stoji }
                                  if (WayPointUk <= MaxWayPoint) then begin
                                      { testujeme pripadnou prekazku v cili! }
                                      with (WayPoint[WayPointUk]) do
                                      with (Map^[IAim,JAim]) do
                                      with (MapBck^[IAim,JAim]) do begin
                                        if (Above(BckType,Field) and
                                            BelowEqual(BckType,Resrc)) then begin
                                        { v cili je ZDROJ, zjisti, zda neni obsazen }
                                           if ((First_level <> 0) and
                                               (Level_type and 128 = 0) and
                                               (Units[First_level]^.UnitType = 2)) then begin
                                           { recyklator neodsunuj ! - vyber dalsi misto pobliz }
                                               if (Find_resource_for_recyklator2(IAim,JAim))
                                               then begin { nasli jsme volny zdroj pobliz }
                                                  ITargPlace:=IAim; JTargPlace:=JAim; MoveLevel:=0;
                                                  WayPointMax:=0; WayPointUk:=0;
                                                  Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                                               end else begin
                                                 { hledame nejblizsi volny zdroj;
                                                   nejprve chvili pockame na uvolneni
                                                   tech blizsich }
                                                 Inc(HarvesterWait);
                                                 if (HarvesterWait > HarvesterWaitLimit(IAim,JAim)) then begin
                                                   HarvesterWait:=0;
                                                   if (Find_resource_for_recyklator3(IAim,JAim))
                                                   then begin { nasli jsme volny zdroj }
                                                      ITargPlace:=IAim; JTargPlace:=JAim; MoveLevel:=0;
                                                      WayPointMax:=0; WayPointUk:=0;
                                                      Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                                                   end;
                                                 end;
                                               end;
                                           end else begin { if (First_level <> 0) }
                                           { misto je volne - posli tam harvester }
                                               ITargPlace:=IAim; JTargPlace:=JAim; MoveLevel:=0;
                                               WayPointMax:=0; WayPointUk:=0;
                                               Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                                           end;
                                        end else begin
                                        { v cili neni zdroj, pridel NEJAKY recyklatoru }
                                           if (Find_resource_for_recyklator(IP,JP)) then begin
                                           { zdroj nalezen! }
                                              ITargPlace:=IP; JTargPlace:=JP; MoveLevel:=0;
                                              WayPointMax:=0; WayPointUk:=0;
                                              Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                                           end;
                                        end;
                                      end; { with  (Map^[IAim,JAim]) do begin }
                                  end else begin
                                     if (Find_resource_for_recyklator(IP,JP)) then begin
                                     { zdroj nalezen! }
                                        ITargPlace:=IP; JTargPlace:=JP; MoveLevel:=0;
                                        WayPointMax:=0; WayPointUk:=0;
                                        Set_move_unit(ITargPlace,JTargPlace,_unit,MoveLevel,False,False);
                                     end;
                                  end;
                             end;
              LoadCom      : begin { nakladani }
                              Done:=False;
                              if (((Unit_types[UnitType,Races[Race].Ally].NeedPlace <= 5) or
                                   (UnitType = 35) or (UnitType = 9)) and (Load_flag < 3))
                              then begin
                              { jednotka s minimalnimi naroky na misto -
                                zkusime ji nalozit }
                                 PomUnit2:=Nil;
                                 PomUnit:=Get_task_group_carrier(Race,TaskGroup,
                                          PomUnit2,_unit,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                                 if (PomUnit <> Nil) then begin
                                 { vhodny carrier nalezen }
                                   if (PomUnit^.TargetType = 3) then begin
                                   { letajici carrier at si sedne }
                                      PomUnit^.Down:=1;
                                   { dokud si nesedne, neposleme do nej nic }
                                   end else begin
                                     IP:=PomUnit^.IPos; JP:=PomUnit^.JPos;
                                     MoveLevel:=0;
                                     _unit^.GoInside:=True;
                                     WayPointMax:=0; WayPointUk:=0;
                                     Set_move_unit(IP,JP,_unit,MoveLevel,False,True);
                                   end;
                                 end else Done:=True;
                              end else Done:=True;
                              if ((MasterCommand <> WithoutCom) and Done) then begin
                              { zkontroluj provedeni kazde z podfazi }
                                 if (not Awaiting_for_further_orders) then begin
                                   Inc(CommandLock);
                                   Awaiting_for_further_orders:=True;
                                 end;
                                 if ((CommandLock >= Lock) or
                                     (CommandLockFlag >= CommandLockFlagLimit))
                                 then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                    then Work_on_master_command2(Race,TaskGroup)
                                    else Work_on_master_command(Race,TaskGroup);
                                 end;
                              end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
              SetAttackModeCom: begin
                                if (MasterCommand <> WithoutCom) then begin
                                { zkontroluj provedeni kazde z podfazi }
                                  if (not Awaiting_for_further_orders) then begin
                                    Inc(CommandLock);
                                    Awaiting_for_further_orders:=True;
                                  end;
                                  if ((CommandLock >= Lock) or
                                      (CommandLockFlag >= CommandLockFlagLimit))
                                  then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                    then Work_on_master_command2(Race,TaskGroup)
                                    else Work_on_master_command(Race,TaskGroup);
                                  end;
                               end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
               RestCom     : begin { odpocinek }
                                if (UnderAttack and KamikadzeMode) then begin
                                   CommandLockFlagLimit:=0;
                                   UnderAttack:=False;
                                end;
                                if ((MasterCommand <> WithoutCom) and
                                    (((Races[Race].RaceType = 3) or
                                      (Races[Race].RaceType = 6)) and
                                     (WearOut > (MinimalWearOut-2)) or
                                     (Races[Race].RaceType mod 3 <> 0)) and
                                     (not Repair))
                                then begin
                                { je-li opotrebeni nejmene (horni hranice-2) }
                                { zkontroluj provedeni kazde z podfazi }
                                  if (not Awaiting_for_further_orders) then begin
                                    Inc(CommandLock);
                                    Awaiting_for_further_orders:=True;
                                  end;
                                  if ((CommandLock >= Lock) or
                                      (CommandLockFlag >= CommandLockFlagLimit))
                                  then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                    then Work_on_master_command2(Race,TaskGroup)
                                    else Work_on_master_command(Race,TaskGroup);
                                  end;
                                end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
               WithoutCom   :begin { cekani na konec utoku }
                                if (MasterCommand <> WithoutCom) then begin
                                   if (((MasterCommand = AttackCom) or
                                        (MasterCommand = MoveCom)) and
                                       (TaskGroup = 12))
                                   then Work_on_master_command2(Race,TaskGroup)
                                   else Work_on_master_command(Race,TaskGroup);
                                end else begin {if (MasterCommand <> WithoutCom) then begin}
                                   if (UnitType = 33) then begin
                                   { rozloz budovu !! }
                                      TaskGroupCommand(Race,TaskGroup,MoveBuildCom,0,4,0,0,0);
                                   end;
                                   if (UnitType = 2) then begin
                                   { recyklator !! }
                                      TaskGroupCommand(Race,TaskGroup,HarvestCom,0,4,0,0,0);
                                   end;
                                end;
                             end;
               MergeCom     : begin { provede merge }
                                if (MasterCommand <> WithoutCom) then begin
                                { zkontroluj provedeni kazde z podfazi }
                                  if (not Awaiting_for_further_orders) then begin
                                    Inc(CommandLock);
                                    Awaiting_for_further_orders:=True;
                                  end;
                                  if ((CommandLock >= Lock) or
                                      (CommandLockFlag >= CommandLockFlagLimit))
                                  then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                    then Work_on_master_command2(Race,TaskGroup)
                                    else Work_on_master_command(Race,TaskGroup);
                                  end;
                                end; {if (MasterCommand <> WithoutCom) then begin}
                             end;
              JoinCom     : begin { provede Merge }
                               Dec(Lock);
                               if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                               then Dec(AirUnitsCount);
                               if (Unit_types[UnitType,Races[Race].Ally].Capacity <> 0) then
                                  Delete_task_group_carrier(Race,TaskGroup,_unit);
                               if (Lock = 0) then
                                  InvalidateTaskGroup(Race,TaskGroup);
                               if (TaskGroups^[JoinGrp].Validity) then
                                 AssignTaskGroup(Race,JoinGrp,_unit)
                               else
                                 CreateNewTaskGroup(Race,JoinGrp,_unit);
                               if (UnitsInsideNum > 0) then
                                  SetNewTGNumberForUNitsInside(_unit,JoinGrp);
                             end;
              WaitCom       : begin
                              end;
              UnLoadCom     : begin
                                if (UnitsInsideNum > 0) then UnLoad(_unit);
                                if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3) then Down:=2;
                                if ((MasterCommand <> WithoutCom) and
                                    (UnitsInsideNum = 0)) then begin
                                { zkontroluj provedeni kazde z podfazi }
                                  if (not Awaiting_for_further_orders) then begin
                                    Inc(CommandLock);
                                    Awaiting_for_further_orders:=True;
                                  end;
                                  if ((CommandLock >= Lock) or
                                      (CommandLockFlag >= CommandLockFlagLimit))
                                  then begin
                                    if (((MasterCommand = AttackCom) or
                                         (MasterCommand = MoveCom)) and
                                        (TaskGroup = 12))
                                    then Work_on_master_command2(Race,TaskGroup)
                                    else Work_on_master_command(Race,TaskGroup);
                                  end;
                                end; {if (MasterCommand <> WithoutCom) then begin}
                              end;
              RemakeCom     : begin
                              end;

           end; { case }
        end; { with (TaskGroups[TaskGroup]) do begin }
     end; { if (Down > 0) then ... else ... }
  end;
end;

{ ********************* }
{ * pomocna procedura * }
function GetSurroundings(IP,JP:Word; Friend:Boolean; var EnemyGroundPct,FriendStrength:Single;
                         var Reinf:TReinfo; Race:Byte):Single;
{ k poctu jednotek na tomto policku pricte vahy okoli a vse vrati jako
  parametr;
  Friend = True, je-li to muj spojenec
  EnemyGroundPct viz nize
  Reinf viz vyse
}
var Count2:Word;
    FriendlyGroundPct:Single; { procentuelni zastoupeni
    pozemnich jednotek ze vsech sil spojence (nepritel = parametr funkce) na
    vlastnim poli }
    EnemyGroundPct2, FriendlyGroundPct2:Single; { procentuelni zastoupeni
    pozemnich jednotek ze vsech sil nepritele (spojence) v okoli vlastniho
    pole }
    Pom,A,B:Single;
begin
   { Count2 = pocet mist mimo obrazovku okolo policka
   }
   SurrPct:=0.6; FriendStrength:=0;
   Count2:=0; EnemyGroundPct:=0; FriendlyGroundPct:=0;
   EnemyGroundPct2:=0; FriendlyGroundPct2:=0;
   GlobalInfoCount:=0;
   with (GlobalInfo[0]) do begin
      EnemyAirCount:=0; EnemyGroundCount:=0;
      FriendlyAirCount:=0; FriendlyGroundCount:=0;
      FriendlyAirStrength:=0; FriendlyGroundStrength:=0;
      EnemyAirStrength:=0; EnemyGroundStrength:=0;
      EnemyLLight:=0; EnemyLight:=0; EnemyHeavy:=0;
      EnemyAir:=0; EnemyAAttack:=0;
      EnemyBuildings:=0; FriendlyBuildings:=0; EnemySpecial:=0;
   end;
   with (GlobalInfo[1]) do begin
      EnemyAirCount:=0; EnemyGroundCount:=0;
      FriendlyAirCount:=0; FriendlyGroundCount:=0;
      FriendlyAirStrength:=0; FriendlyGroundStrength:=0;
      EnemyAirStrength:=0; EnemyGroundStrength:=0;
      EnemyLLight:=0; EnemyLight:=0; EnemyHeavy:=0;
      EnemyAir:=0; EnemyAAttack:=0;
      EnemyBuildings:=0; FriendlyBuildings:=0; EnemySpecial:=0;
   end;
   { vypocet okoli }
   GetMapInfo(IP,JP,Friend,True);
   if (JP > 0) then begin
      Pom:=0;
      if (IP > 0) then GetMapInfo(IP-1,JP-1,Friend,False)
      else Inc(Count2);
      GetMapInfo(IP,JP-1,Friend,False);
      if (IP < IMapInfoMax) then GetMapInfo(IP+1,JP-1,Friend,False)
      else Inc(Count2);
   end else Inc(Count2,3);
   if (IP > 0) then GetMapInfo(IP-1,JP,Friend,False)
   else Inc(Count2);
   if (IP < IMapInfoMax) then GetMapInfo(IP+1,JP,Friend,False) else Inc(Count2);
   if (JP < JMapInfoMax) then begin
      if (IP > 0) then GetMapInfo(IP-1,JP+1,Friend,False) else Inc(Count2);
      GetMapInfo(IP,JP+1,Friend,False);
      if (IP < IMapInfoMax) then GetMapInfo(IP+1,JP+1,Friend,False) else Inc(Count2);
   end else Inc(Count2,3);{}

   with (GlobalInfo[0]) do begin
     { * navyseni/snizeni sily nepratel * }
     with (Races[Race]) do begin
       EnemyAirStrength:=(EnemyAirStrength/100)*OverStrengthEnemy;
       EnemyGroundStrength:=(EnemyGroundStrength/100)*OverStrengthEnemy;
     end;

     Pom:=EnemyGroundCount; EnemyGroundPct:=EnemyGroundCount+EnemyAirCount;
     if (EnemyGroundPct > 0) then
       EnemyGroundPct:=Pom/(EnemyGroundPct/100)
     else EnemyGroundPct:=100;
     Pom:=FriendlyGroundCount; FriendlyGroundPct:=FriendlyGroundCount+FriendlyAirCount;
     if (FriendlyGroundPct > 0) then
       FriendlyGroundPct:=Pom/(FriendlyGroundPct/100)
     else FriendlyGroundPct:=100;
     { * vlastni vypocty * }
     EnemyAirStrength:=EnemyAirStrength*((100-EnemyGroundPct) / 100);
     EnemyGroundStrength:=EnemyGroundStrength*(EnemyGroundPct / 100);
     FriendlyAirStrength:=FriendlyAirStrength*((100-FriendlyGroundPct) / 100);
     FriendlyGroundStrength:=FriendlyGroundStrength*(FriendlyGroundPct / 100);
   end;
   with (GlobalInfo[1]) do begin
     { * navyseni/snizeni sily nepratel * }
     with (Races[Race]) do begin
       EnemyAirStrength:=(EnemyAirStrength/100)*OverStrengthEnemy;
       EnemyGroundStrength:=(EnemyGroundStrength/100)*OverStrengthEnemy;
     end;

     Pom:=EnemyGroundCount; EnemyGroundPct2:=EnemyGroundCount+EnemyAirCount;
     if (EnemyGroundPct2 > 0) then
       EnemyGroundPct2:=Pom/(EnemyGroundPct2/100)
     else EnemyGroundPct2:=100;
     Pom:=FriendlyGroundCount; FriendlyGroundPct2:=FriendlyGroundCount+FriendlyAirCount;
     if (FriendlyGroundPct2 > 0) then
       FriendlyGroundPct2:=Pom/(FriendlyGroundPct2/100)
     else FriendlyGroundPct2:=100;
     { * vlastni vypocty * }
     EnemyAirStrength:=EnemyAirStrength*((100-EnemyGroundPct2) / 100);
     EnemyGroundStrength:=EnemyGroundStrength*(EnemyGroundPct2 / 100);
     FriendlyAirStrength:=FriendlyAirStrength*((100-FriendlyGroundPct2) / 100);
     FriendlyGroundStrength:=FriendlyGroundStrength*(FriendlyGroundPct2 / 100);
   end;
   { zaverecny odhad EnemyGroundPct pro vlastni pole i okoli; provadi se
     metodou aritmetickeho prumeru }
   EnemyGroundPct:=(EnemyGroundPct+EnemyGroundPct2)/2;
   {x}
   MainZero:=True;
   if (((GlobalInfo[0].EnemyGroundStrength + GlobalInfo[0].EnemyAirStrength) > 0) or
       ((GlobalInfo[1].EnemyGroundStrength + GlobalInfo[1].EnemyAirStrength) > 0){})
   then begin{}
      A:=GlobalInfo[0].EnemyGroundStrength+GlobalInfo[0].EnemyAirStrength;
      B:=GlobalInfo[1].EnemyGroundStrength+GlobalInfo[1].EnemyAirStrength;
      { vypocet SurrPct }
      if (A <> 0) then MainZero:=False;
      if (A = 0) then SurrPct:=0.01 { pokud neni nic na vlastnim poli, pocitame }
      else                          { mensi vahu }
        if (A > (B*2)) then SurrPct:=0.66
        else
          if (A > B) then SurrPct:=0.8
          else
            if ((A*2) > B) then SurrPct:=0.9
            else SurrPct:=1.0;
      {x}
      with (GlobalInfo[0]) do begin
        Pom:=EnemyGroundStrength+EnemyAirStrength-
             FriendlyGroundStrength-FriendlyAirStrength;
        FriendStrength:=FriendlyGroundStrength+FriendlyAirStrength;
      end;
      with (GlobalInfo[1]) do begin
      { okoli se hodnoti 60-ti procenty, nebot nemusi byt bezprostrednim
        ohrozenim (SurrPct) }
        GetSurroundings:=Pom+(EnemyGroundStrength+EnemyAirStrength-
                              FriendlyGroundStrength-FriendlyAirStrength)*SurrPct;
        FriendStrength:=FriendStrength+(FriendlyGroundStrength+FriendlyAirStrength)*SurrPct;
      end;
   end else GetSurroundings:=0; { kdyz zde nic neni, okoli se nepocita }

   { * nyni vahy budov a specialnich cilu }
   { pozn. okoli se zapocita pouze 33%, ale jen tehdy, pokud je alespon neco
     na vlastnim poli }
   if (GlobalInfo[0].EnemyBuildings > 0) then begin
      Pom:=GlobalInfo[1].EnemyBuildings; Pom:=Pom*0.33;
   end else Pom:=0;
   Reinf.EnemyBuildingsWeight:=GlobalInfo[0].EnemyBuildings+Round(Pom);
   { pozn. okoli pratelskych budov se zapocita 50% }
   Pom:=GlobalInfo[1].FriendlyBuildings; Pom:=Pom*0.5;
   Reinf.FriendlyBuildingsWeight:=GlobalInfo[0].FriendlyBuildings+Round(Pom);

   if (GlobalInfo[0].EnemySpecial > 0) then begin
     Pom:=GlobalInfo[1].EnemySpecial; Pom:=Pom*0.33;
   end else Pom:=0;
   Reinf.SpecTargets:=GlobalInfo[0].EnemySpecial+Round(Pom);

   { * nyni naplneni pole Reinf }
   with (Reinf) do begin
     with (GlobalInfo[0]) do begin
       LLight:=EnemyLLight; Light:=EnemyLight;
       Heavy:=EnemyHeavy; Air:=EnemyAir; AAttack:=EnemyAAttack;
     end;
     { okoli se hodnoti 60-ti procenty, nebot nemusi byt bezprostrednim
        ohrozenim }
     with (GlobalInfo[1]) do begin
       Pom:=EnemyLLight; Inc(LLight,Round(Pom*SurrPct));
       Pom:=EnemyLight;  Inc(Light,Round(Pom*SurrPct));
       Pom:=EnemyHeavy;  Inc(Heavy,Round(Pom*SurrPct));
       Pom:=EnemyAir;    Inc(Air,Round(Pom*SurrPct));
       Pom:=EnemyAAttack; Inc(AAttack,Round(Pom*SurrPct));
     end;
   end;
end;


{ ***** }
function TGActiveSearchingProc(Race,TGNumber:Byte; IP,JP,CourageL,CourageH:Word;
                               var Reinf:TReinfo):Word;
{ pro konkretni TG testuje vyhodnost cile na info poli IP,JP vzhledem
  k predchozim hodnotam a urovni odvahy; vahu vraci jako svou hodnotu:
  - 0..15 = sila nepratelske obrany, na kterou LZE utocit; 0 odpovida
            nejslabsi akceptovatelne sile (CourageL), 10 naopak nejsilnejsi
            akceptovatelne (CourageH)
  - 0..15 s nastavenym bitem o vaze 16 = nepratelska obrana je SLABA, takze se
          utok nevyplati; 0..totalne "salatova" obrana, 15 = temer minimalni
          hranice (CourageL)
  - nastaveny bit o vaze 32 = nepratelska obrana je SILNA, takze se neodvazujeme
                            utocit; v poli Reinfo jsou pak informace o
                            nutnosti posil
  - 255 = zadna sila nepratel

  * TReinfo ma podobu:
  LLight,Light,Heavy,Air,AAttack:Word =  sila nepratel v jednotlivych
                                         kategoriich
  EnemyBuildingsWeight =  dulezitost nepr. budov
  FriendlyBuildingsWeight = dulezitost pratelskych budov
  SpecTargets =  pocet specialnich cilu
  Difference:Single;  kolikrat je nepritel silnejsi nez moje TG
}

label Konec;
var TGStrength,TGStrength2,EnemyStrength,EnemyGroundPct,Pom,Pom2:Single;
    FriendStrength:Single;

{ *** }
{ ************** vlastni telo procedury TGActiveSearchingProc ************** }
begin
  with (Races[Race].TaskGroups^[TGNumber]) do begin
     Reinf.OverStrength:=False;
     EnemyStrength:=GetSurroundings(IP,JP,Races[MyRace].Friend[Race] > 0,
                                    EnemyGroundPct,FriendStrength,Reinf,Race);
     TGActiveSearchingProc:=255;

     { nyni vypocet sily vlastni TG }
     TGStrength:=Get_task_group_strength(Race,TGNumber,EnemyGroundPct);
     {x}
     if (EnemyStrength <> 0) then
        if ((IP = ITaskGroupInfoPos) and (JP = JTaskGroupInfoPos)) then begin
        { jde o materskou pozici TG, odecti tedy jeji silu od vysledku
          prohledavani }
          if (FriendStrength < TGStrength) then
             EnemyStrength:=EnemyStrength + FriendStrength
          else EnemyStrength:=EnemyStrength + TGStrength;
        end else
          if (GetDistance(IP,JP,ITaskGroupInfoPos,JTaskGroupInfoPos) = 1) then begin
          { jde o materskou pozici TG, odecti tedy (redukovane) jeji silu od
            vysledku prohledavani }
            if (FriendStrength < SurrPct*TGStrength) then
               EnemyStrength:=EnemyStrength + FriendStrength
            else EnemyStrength:=EnemyStrength + SurrPct*TGStrength;
          end;
     {x}
     if ((EnemyStrength <= 0) and
         (Reinf.EnemyBuildingsWeight = 0)) then Goto Konec;
     {x}
     if (TGStrength <> 0) then Reinf.Difference:=EnemyStrength/(TGStrength/100)
     else Reinf.Difference:=0;
     {x}
     if (TGStrength < RacesTGInfo^[Race,TGNumber].TGMinLimit)
     then begin
       Reinf.OverStrength:=True;
     end;
     {x}
     TGStrength2:=(TGStrength/100)*CourageL; { spodni hranice }
     TGStrength:=(TGStrength/100)*CourageH; { horni hranice }
     {x}
     if (Reinf.OverStrength) then begin
     { nase sila je pod minimalni hranici, "oslabime se" }
       if (TGStrength2 < EnemyStrength) then TGStrength2:=EnemyStrength+1;
       if (TGStrength <= TGStrength2) then TGStrength:=TGStrength2+1;
     end;

     { nyni vypocet podle typu taskgrup }
     case (Races[Race].TaskGroups^[TGNumber].GroupType) of
        TGDefence,TGPlus
                  : begin
                       if (GetDistance(IP,JP,RacesTGInfo^[Race,TGNumber].IHomeTaskGroupInfoPos,
                                       RacesTGInfo^[Race,TGNumber].JHomeTaskGroupInfoPos)
                           <= RacesTGInfo^[Race,TGNumber].TGAtt) then begin
                       { obranna TG reaguje jen do okruhu TGAtt }
                          if ((EnemyStrength > TGStrength2) and
                              (EnemyStrength <= TGStrength)) then begin
                          { * OK, na tuto oblast lze utocit }
                             Pom:=(TGStrength-TGStrength2)/15;
                             if (Pom <> 0) then
                               TGActiveSearchingProc:=Round((EnemyStrength-TGStrength2)/Pom)
                             else
                               if (Reinf.EnemyBuildingsWeight = 0)
                               then TGActiveSearchingProc:=255
                               else TGActiveSearchingProc:=16;
                          end else
                            if (EnemyStrength <= TGStrength2) then begin
                            { * nepritel je na nas prilis slaby }
                              Pom:=TGStrength2/15;
                              if (Pom <> 0) then
                                Pom:=EnemyStrength/Pom
                              else Pom:=0;
                              TGActiveSearchingProc:=Round(Pom) or 16;
                            end else begin
                            { * nepritel je prili silny }
                              TGActiveSearchingProc:=32;
                            end;
                       end else TGActiveSearchingProc:=255;
                    end;
        TGAttack  : begin
                       if ((EnemyStrength > TGStrength2) and
                           (EnemyStrength <= TGStrength)) then begin
                       { * OK, na tuto oblast lze utocit }
                          Pom:=(TGStrength-TGStrength2)/15;
                          if (Pom <> 0) then
                            TGActiveSearchingProc:=Round((EnemyStrength-TGStrength2)/Pom)
                          else
                            if (Reinf.EnemyBuildingsWeight = 0)
                            then TGActiveSearchingProc:=255
                            else TGActiveSearchingProc:=16;
                       end else
                         if (EnemyStrength <= TGStrength2) then begin
                         { * nepritel je na nas prilis slaby }
                           Pom:=TGStrength2/15;
                           if (Pom <> 0) then
                             Pom:=EnemyStrength/Pom
                           else Pom:=0;
                           TGActiveSearchingProc:=Round(Pom) or 16;
                         end else begin
                         { * nepritel je prili silny }
                           TGActiveSearchingProc:=32;
                         end;
                    end;
        TGSaboteur: begin
                       if ((EnemyStrength > TGStrength2) and
                           (EnemyStrength <= TGStrength)) then begin
                       { * OK, na tuto oblast lze utocit }
                          Pom:=(TGStrength-TGStrength2)/15;
                          if (Pom <> 0) then
                            TGActiveSearchingProc:=Round((EnemyStrength-TGStrength2)/Pom)
                          else
                            if (Reinf.EnemyBuildingsWeight = 0)
                            then TGActiveSearchingProc:=255
                            else TGActiveSearchingProc:=16;
                          { za kazdy spec. cil se oblast zatraktivni }
                          Reinf.EnemyBuildingsWeight:=
                                             Reinf.EnemyBuildingsWeight+
                                             Reinf.SpecTargets*Build_weigth_div;
                       end else
                         if (EnemyStrength <= TGStrength2) then begin
                         { * nepritel je na nas prilis slaby }
                           Pom:=TGStrength2/15;
                           if (Pom <> 0) then
                             Pom:=EnemyStrength/Pom
                           else Pom:=0;
                           TGActiveSearchingProc:=Round(Pom) or 16;
                           { za kazdy spec. cil se oblast zatraktivni }
                           Reinf.EnemyBuildingsWeight:=
                                              Reinf.EnemyBuildingsWeight+
                                              Reinf.SpecTargets*Build_weigth_div;
                         end else begin
                         { * nepritel je prili silny - nebrat!!! }
                           if (EnemyStrength <= RacesTGInfo^[Race,TGNumber].TGMinLimit)
                           then begin
                              TGActiveSearchingProc:=32;
                           end;
                         end;
                    end;
        TGPlus    : begin { tento typ TG by se sem vubec nemel dostat }
                    end;
        TGPara    : begin
                       if (Reinf.EnemyBuildingsWeight <> 0) then begin
                       { Ano, jsou zde budovy }
                          if ((EnemyStrength > TGStrength2) and
                              (EnemyStrength <= TGStrength)) then begin
                          { * OK, na tuto oblast lze utocit }
                             Pom:=(TGStrength-TGStrength2)/15;
                             if (Pom <> 0) then
                               TGActiveSearchingProc:=Round((EnemyStrength-TGStrength2)/Pom)
                             else
                               if (Reinf.EnemyBuildingsWeight = 0)
                               then TGActiveSearchingProc:=255
                               else TGActiveSearchingProc:=16;
                             { za kazdy spec. cil se oblast zatraktivni }
                             Reinf.EnemyBuildingsWeight:=
                                                Reinf.EnemyBuildingsWeight+
                                                Reinf.SpecTargets*Build_weigth_div;
                          end else
                            if (EnemyStrength <= TGStrength2) then begin
                            { * nepritel je na nas prilis slaby }
                              Pom:=TGStrength2/15;
                              if (Pom <> 0) then
                                Pom:=EnemyStrength/Pom
                              else Pom:=0;
                              TGActiveSearchingProc:=Round(Pom) or 16;
                              { za kazdy spec. cil se oblast zatraktivni }
                              Reinf.EnemyBuildingsWeight:=
                                                 Reinf.EnemyBuildingsWeight+
                                                 Reinf.SpecTargets*Build_weigth_div;
                            end else begin
                            { * nepritel je prili silny }
                              if (EnemyStrength <= RacesTGInfo^[Race,TGNumber].TGMinLimit)
                              then begin
                                 TGActiveSearchingProc:=32;
                                 Reinf.Difference:=10-Reinf.EnemyBuildingsWeight;
                              end;
                            end;
                       end else begin
                       { nejsou zde zadne budovy }
                           TGActiveSearchingProc:=32;
                           Reinf.Difference:=10;
                       end;
                    end;
     else
     end;
  end;
Konec:
end;

{ ***************** }
procedure AI_manager;
{
}
const Build_weigth_div = 50; { v podstate se touto hodnotou deli vaha
                               nepratelskych budov, abychom ziskali
                               urcite vztazne hodnoty; }
      Build_diff = 0;     { je-li rozdil vah nepratelskych budov (po vydeleni
                             Build_weigth_div) o tuto hodnotu vyssi nez u
                             zatim nalezeneho reseni, preferuj tuto variantu
                             (stejne vyhodna puvodni - stejne vyhodna nova)
                           }
      Build_diff1 = -2; { prechod na normalni }
      Build_diff2 = 2.0; { prechod na slabou }
      Build_diff3 = 10.0; { prechod na silnou }

      {x}
      Buildxx_diff = 0; { je-li rozdil vah vlastnich budov (po vydeleni
                             Build_weigth_div) o tuto hodnotu vyssi nez u
                             zatim nalezeneho reseni, preferuj tuto variantu
                             (stejne vyhodna puvodni - stejne vyhodna nova)
                        }
      Buildxx_diff1 = -1; { prechod na normalni }
      Buildxx_diff2 = 2.0; { prechod na slabou }
      Buildxx_diff3 = 6.0; { prechod na silnou }

var I,J,K,L : Word;
    M:Integer;
    Weight : Word;
    Pom :  record
              X,Y:Word;
              Weight2:Single;
              Reinf:TReinfo;
              Tag:Byte; { 0.. nepritel je prilis slaby
                          1.. na nepritele muzeme utocit
                          2.. nepritel je silny - viz Reinf
                          255 .. neplatna hodnota
                        }
           end;

    Reinfo2:TReinfo;  { popis viz definice typu }
    Accept:Boolean;
    Limit:Word;
    Temp:Single;
    Distance, Dist2:Word;

    NewEnemy_w, OldEnemy_w, NewFriendly_w, OldFriendly_w:Single;
begin
   if (Global_eval_flag > 0) then Dec(Global_eval_flag);
      if (Global_eval_flag = 0) then begin
        Globa_eval;{}
        Global_eval_flag:=50;
      end;

   {*}
   TGActiveSearching.Validity:=False;
   for I:=0 to MaxRace do
   if (((I = ThisCompRace1) or (I = ThisCompRace2) or (I = ThisCompRace3) or
        (I = ThisCompRace4) or (I = ThisCompRace5)) and
       (not Races[I].Neutral)) then begin
   { I je pocitacem ovladana rasa }
      {x}Production_ai_planning(Byte(I));
      if (Races[I].TG_Reinfo_ExecuteFlag > 0) then Dec(Races[I].TG_Reinfo_ExecuteFlag);
      if (Races[I].TG_Reinfo_ExecuteFlag = 0) then begin
         {x}ProductionManager.Execute(Byte(I)); { rizeni produkce }
         {x}TG_Reinfo_Execute(Byte(I)); { doplneni TG }
         Races[I].TG_Reinfo_ExecuteFlag:=8;
      end;

      { nyni vymazani flagu utoceni: }
      with (Races[I]) do
        for M:=0 to ActualFreeStructures-1 do
          if (FreePlaces^[0,M].PlaceType > 0) then Dec(FreePlaces^[0,M].PlaceType);


      with (Races[I]) do begin
      { prace s TG }
        for J:=0 to MaxRaceTaskGroups do begin
          if (RacesTGInfo^[I,J].SpecialLock > 0)
          then Dec(RacesTGInfo^[I,J].SpecialLock);
          with TaskGroups^[J] do if (Validity) then begin
             if (MasterCommand <> WithoutCom) then begin
               Inc(CommandLockFlag);
               {if ((CommandLockFlag = CommandLockFlagLimit-
                                     CommandLockFlagLimit shr 1) and
                   (Command <> RestCom))
               then Inc(CommandLock,Round(10*(1.0*Lock)/100));{}
               if ((CommandLockFlag = CommandLockFlagLimit-
                                     CommandLockFlagLimit shr 2) and
                   (Command <> RestCom))
               then Inc(CommandLock,Round(15*(1.0*Lock)/100));
               { pokud je flag na urcite urovni (75% z FlagLimit), zvedni
                 CommandLock o 20% Lock a zkus tim urychlit presun TG }
               if ((CommandLock >= Lock) or
                   (CommandLockFlag >= CommandLockFlagLimit))
               then begin
                  if (Command = WaitCom) then begin
                     Command:=WithoutCom;
                     MasterCommand:=WithoutCom;
                     ClearAttackTGInfo(I,J);
                  end else begin
                    if (((MasterCommand = AttackCom) or
                         (MasterCommand = MoveCom)) and (J = 12))
                    then Work_on_master_command2(I,J)
                    else Work_on_master_command(I,J);
                  end;
               end;
             end else begin
             { TG je necinna }
               if ((J > 3) and (J < 8) and (TimeSlot mod (1800+I*100) = 0)) then begin
               { obranna TG s limitem pro reorganizaci}
                 RemakeDefenceTG(I,J);
               end;
             end;

             if (NoAttackTimming < 50000) then Inc(NoAttackTimming);

             { nyni priprav globalni hledani cile }
             if (((MasterCommand = WithoutCom) or (Command = PrepareCom)) and
                 {(Command <> WaitCom) and{}
                 ((GroupType = TGDefence) or (GroupType = TGAttack) or
                  (GroupType = TGSaboteur) or (GroupType = TGPlus) or
                  (GroupType = TGPara)))
             then begin
               { xx }
               Inc(ActiveSearchingFlag);
               { xx }
               if ((GroupType = TGDefence) or (GroupType = TGPlus)) then
               { OBRANNE TG REAGUJI RYCHLEJI !!! }
                  Limit:=ActiveSearchingTGTimeLimit
               else Limit:=ActiveSearchingTGTimeLimit shl 1;
               { "pripravujici" se TG reaguje pomaleji }
               if (Command = PrepareCom) then Limit:=Limit + Limit shr 1;
               {}
               if (ActiveSearchingFlag > GetAccurateDelay(Limit))
               then begin
                  { hledej aktivne cil }
                  if (not TGActiveSearching.Validity) then begin
                  { volno, zarad TG na zpracovani }
                     ActiveSearchingFlag:=0;
                     TGActiveSearching.Validity:=True;
                     TGActiveSearching.Race:=I;
                     TGActiveSearching.TGNumber:=J;
                     { "vynulovani" souradnic cile utoku }
                     MasterITarg:=ITargPlace; { ZDE BYLA CHYBA !!! }
                     MasterJTarg:=JTargPlace;
                     with (Reinfo2) do begin { inicializace }
                       LLight:=0; Light:=0; Heavy:=0;
                       Air:=0; AAttack:=0;
                       EnemyBuildingsWeight:=0;
                       FriendlyBuildingsWeight:=0;
                       SpecTargets:=0;
                       Difference:=0;
                     end;
                  end else { TG musi cekat na uvolneni zaznamu };
               end;
             end;
          end;
        end;

      end; { with (Races[I]) do }
   end;
   { nyni globalni ovladani utocnych TG vcetne nulovani globalnich
     modifikatoru moralky }
   Pom.Weight2:=255; Pom.Tag:=255;
   {XXXX}
   for I:=0 to IInfoArraySize-1 do
     for J:=0 to JInfoArraySize-1 do begin
        for K:=0 to MaxRace do with (Races[K]) do begin
          { nejprve nulujeme moralku }
          MapInfo^[I,J].MoraleModifier[K]:=MapInfo^[I,J].MoraleModifierTemp[K];
          MapInfo^[I,J].MoraleModifierTemp[K]:=0;
        end;
        { zjisteni globalnich hodnot }

        with (TGActiveSearching) do
        if ((Validity) and ((MapInfo^[I,J].Pruchozi) or
            (Races[Race].TaskGroups^[TGNumber].AirUnitsCount =
             Races[Race].TaskGroups^[TGNumber].Lock))) then begin
        { hledej cil pro TG  - bud je pole globalne pruchozi, nebo se
          TG sklada se samych leteckych jednotek }
          Weight:=TGActiveSearchingProc(Race,TGNumber,I,J,
                                        RacesTGInfo^[Race,TGNumber].LeaderCourageLow,
                                        RacesTGInfo^[Race,TGNumber].LeaderCourageHigh,
                                        Reinfo2);
          if ((Reinfo2.EnemyBuildingsWeight/Build_weigth_div = 0) and
              (MainZero)) then Weight:=255;

          if (Weight <> 255) then with (Pom) do begin
          {XXXXXXXXX}
          { NYNI VYHODNOT, ZDA JE VYBRANY CIL VYHODNEJSI, NEZ POSLEDNE
            VYBRANY }
          {XXXXXXXXX}
            Accept:=False; { True, pokud se nove nalezeny cil prijme }
            {x}
            if (Tag = 255) then Accept:=True
            { zadna ulozena hodnota - prvni zaznamenej }
            else begin
            { novou hodnotu zaznamenej, jen pokud je vyhodnejsi }
            { REINFO jsou ulozene hodnoty
              REINFO2 jsou hodnoty na prave propocitanem poli }
              NewEnemy_w:=Reinfo2.EnemyBuildingsWeight/Build_weigth_div;
              OldEnemy_w:=Reinf.EnemyBuildingsWeight/Build_weigth_div;
              NewFriendly_w:=Reinfo2.FriendlyBuildingsWeight/Build_weigth_div;
              OldFriendly_w:=Reinf.FriendlyBuildingsWeight/Build_weigth_div;

              Distance:=GetDistance(I,J,Races[Race].TaskGroups^[TGNumber].ITaskGroupInfoPos,
                                        Races[Race].TaskGroups^[TGNumber].JTaskGroupInfoPos);
              if ((Reinfo2.Difference < 100) and (Reinfo2.Difference > 0))
              then begin
                 Dist2:=Round(10 - (100.0-Reinfo2.Difference)/10);
                 if (Dist2 > 5) then Dist2:=5;
                 if (Dist2 < 2) then Dist2:=2;
              end else Dist2:=255;
              if (Distance < Dist2) then Distance:=1 else Distance:=0;
              { Distance > 0, pokud je vzdalenost TG akceptovatelna }

              case (Tag) of
                 0 : begin { zatim vybrana slabsi grupa }
                      if (Weight and 32 = 32) then begin { novy cil je silnejsi }
                        if (((NewEnemy_w - OldEnemy_w) >= 5) and
                            (((NewFriendly_w - OldFriendly_w) > 0) or
                            (OldFriendly_w <= 0)))
                        then Accept:=True; {???????????????????}
                        { je-li na novem cili vice budov}
                      end else
                        if (Weight and 16 = 16) then begin { novy cil je slabsi }
                          if (((Weight and 15 > Weight2) or
                               ((NewEnemy_w - OldEnemy_w) > 0) {and
                                (TGNumber > 7) and (TGNumber < 10){}) and
                               ((NewFriendly_w - OldFriendly_w) >= Buildxx_diff) or
                              ((NewFriendly_w - OldFriendly_w) >= 2) and
                               (not MainZero))
                          then Accept:=True;
                        end else begin { novy cil je normalni }
                           if (((NewEnemy_w - OldEnemy_w) > 0) and
                               (((NewFriendly_w - OldFriendly_w) > 0) or
                                (OldFriendly_w <= 0)))
                           then Accept:=True;
                        end;
                     end;
                 1 : begin { zatim vybrana akceptovatelna grupa }
                        if (Weight and 32 = 32) then begin{ novy cil je silnejsi }
                          if (((NewEnemy_w - OldEnemy_w) > Build_diff3) and
                              (((NewFriendly_w - OldFriendly_w) >= Buildxx_diff3) or
                               (OldFriendly_w <= 0)))
                          then Accept:=True;
                        end else
                          if (Weight and 16 = 16) then begin{ novy cil je slabsi }
                             if (((NewEnemy_w-OldEnemy_w) > 0) and
                                 ((NewFriendly_w - OldFriendly_w) >= 0)  and
                                 (not MainZero) or
                                 ((NewFriendly_w - OldFriendly_w) >= Buildxx_diff2) and
                                  (Distance = 1))
                             then Accept:=True;
                          end else begin { novy cil je normalni }
                             if (((Weight > Weight2) or
                                  ((NewEnemy_w - OldEnemy_w) > Build_diff)) and
                                 (((NewFriendly_w - OldFriendly_w) >= Buildxx_diff1) or
                                  (OldFriendly_w <= 0)) or
                                 ((NewFriendly_w - OldFriendly_w) >= Buildxx_diff2))
                             then Accept:=True;
                          end;
                     end;
                 2 : begin { zatim vybrana silnejsi grupa }
                        if (Weight and 32 = 32) then begin{ novy cil je silnejsi }
                           if (Races[Race].TaskGroups^[TGNumber].GroupType = TGSaboteur)
                           then Temp:=0 else Temp:=1;
                           if (((Reinfo2.Difference < Reinf.Difference) or
                                (NewEnemy_w > Temp)) and
                               (((NewFriendly_w - OldFriendly_w) >= Buildxx_diff) or
                                (OldFriendly_w <= 0)))
                           then Accept:=True;
                        end else
                          if (Weight and 16 = 16) then begin { novy cil je slabsi }
                             if (((NewEnemy_w-OldEnemy_w) > 0) and
                                 ((NewFriendly_w - OldFriendly_w) >= 0)  and
                                 (not MainZero) or
                                 ((NewFriendly_w - OldFriendly_w) >= 2) and
                                  (Distance = 1) and (not MainZero))
                             then Accept:=True;
                          end else begin { novy cil je normalni }
                             if ((((NewEnemy_w - OldEnemy_w) > Build_diff1) or
                                  (OldEnemy_w = 0) or (NewEnemy_w > Build_diff3) or
                                  ((NewFriendly_w - OldFriendly_w) >= Buildxx_diff2)) and
                                 (((NewFriendly_w - OldFriendly_w) >= Buildxx_diff1) or
                                  (OldFriendly_w <= 0)))
                             then Accept:=True;
                          end;
                     end;
              else
                 Error(0,'unita AI, procedura AI_manager');
              end;
            end;

            if (Accept) then begin
              X:=I; Y:=J;
              if (Weight and 32 = 32) then Tag:=2 else
                if (Weight and 16 = 16) then Tag:=0
                else Tag:=1;
              Weight2:=Weight and 15;  Reinf:=Reinfo2;
            end;
            Weight:=0;
          end;
        end;
     end;

   { * }
   with (TGActiveSearching) do if (Validity) then begin
     with (Races[Race].TaskGroups^[TGNumber]) do begin
        if (Pom.Tag <> 255) then begin
        { cil byl globalne nalezen, proved utok ! }
           { zmen uroven cile, pokud se nejedna o "obrannou akci" }
           if ((Pom.Reinf.OverStrength) and
               (Pom.Reinf.FriendlyBuildingsWeight/Build_weigth_div < 2))
           then Pom.Tag:=2;
           if (Pom.Tag < 2) then with (Pom) do begin
           { nepritel je "vhodny k utoku" }
             if (RacesTGInfo^[Race,TGNumber].ActivityGameTime <=
                 (LongInt(Min_game_time)*60+Sec_game_time))
             then begin { odpovida nacasovani utoku ? }
                if (GroupType = TGSaboteur) then begin { sabotazni skupina }
                  TaskGroupCommand(Race,TGNumber,AttackCom,0,2,X,Y,RacesTGInfo^[Race,TGNumber].MoveCourageSabot);
                  { predposledni dve hodnoty jsou souradnice cile; posledni je % ignorace }
                  ProductionManager.ClearAllTGProduction(Race,TGNumber);
                end else begin { klasicka skupina }
                  if ((GroupType = TGPara) and ((Carriers = Nil) or
                      ((Races[Race].ParaEnabled and 48) shr 4 <= Fighters) or
                      ((Races[Race].ParaEnabled and 192) shr 6 <= Terminators)))
                  then
                  { TGPara bez carrieru se nepouzije }
                     TaskGroupCommand(Race,TGNumber,PrepareCom,0,2,X,Y,RacesTGInfo^[Race,TGNumber].MoveCourageNormal)
                  else begin
                     TaskGroupCommand(Race,TGNumber,AttackCom,0,2,X,Y,RacesTGInfo^[Race,TGNumber].MoveCourageNormal);
                     { predposledni dve hodnoty jsou souradnice cile; posledni je % ignorace }
                     ProductionManager.ClearAllTGProduction(Race,TGNumber);
                  end;
                end;
             end;
           end else begin
           { nepritel je silnejsi, posiluj -  }
               if ((GetDistance(RacesTGInfo^[Race,TGNumber].IHomeTaskGroupInfoPos,
                               RacesTGInfo^[Race,TGNumber].JHomeTaskGroupInfoPos,
                               ITaskGroupInfoPos,JTaskGroupInfoPos) > 3) and
                   (GroupType <> TGPara))
                  { odpovida nacasovani utoku ? }
               { Presun TG do domovske pozice, nebot TG je daleko }
               then
                 TaskGroupCommand(Race,TGNumber,AttackCom,0,2,
                                  RacesTGInfo^[Race,TGNumber].IHomeTaskGroupInfoPos,
                                  RacesTGInfo^[Race,TGNumber].JHomeTaskGroupInfoPos,
                                  RacesTGInfo^[Race,TGNumber].MoveCourageNormal)
               else
               { vzdalenost je OK, posiluj }
                 TaskGroupCommand(Race,TGNumber,PrepareCom,0,2,Pom.X,Pom.Y,RacesTGInfo^[Race,TGNumber].MoveCourageNormal);
               Reinfo:=Pom.Reinf;
           end;
        end else begin
        { globalni cil nenalezen;
          v Pom.Reinfo jsou informace o sile nepritele
        }
        end;
     end;
     Validity:=False;
   end;
end;

{ ***** }
procedure AI_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'16'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ProductionManager.P^,SizeOf(ProductionManager.P^));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure AI_load;
{ pro potreby ulozeni hry
}
label K;

begin
   Reset(CheckFile,1); DResult:=IOResult;
   { existence souboru check znaci OK, jinak jde o chybu }
   if (DResult <> 0) then GoTo K;
   Close(CheckFile);
   Assign(IOFile,'save\'+SavePath+'16'); Reset(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{x}BlockRead(IOFile,ProductionManager.P^,SizeOf(ProductionManager.P^));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************** }
begin
   ProductionManager.Init;
   New(OptiInfo);
   for J:=0 to (JInfoArraySize-1) do
     for I:=0 to (IInfoArraySize-1) do with (OptiInfo^[I,J]) do begin
        Valid:=False;
     end;
end.