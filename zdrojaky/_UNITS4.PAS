unit _Units4;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, Grafika2, Grafika3, Grafika4, AI, _units;

const MaxInf = 8; { max. pocet jednotek v posile }
      MaxReinforcement = 19; { max. pocet posil }
type TSingleReinforcementRecord = record
                               Material:Boolean; { True, jde-li o matros }
                               UnitType:Byte; { typ jednotky/budovy }
                               Name:String[15]; { jmeno }
                               Experience:Byte; { zkusenost 0-12 }
                               Build:Byte; { 0..jednotka, 1..slozena budova }
                               TGNumber:Byte; { cislo cilove TG }
                               _BP,_PL,_EE,_EXP:Word; { material }
                               Unused:Word; { nepouzito }
                             end;
     TSingleReinforcement = object
                        ActivityTime:LongInt;
                        Race:Byte;
                        Inf: array[0..MaxInf] of TSingleReinforcementRecord;
                        MaxUsedInf:Byte; { posledni pouzity index pole Inf;
                                           255 = nepouzito }
                        Seen:Byte; { 0..posila nebyla poprve zpracovana }
                        Spec:Boolean; { True, jde-li o spec. posilu, rizenou
                        priznakem z globalni strategie }
                        Core:Boolean; { True, jde-li o mou posilu jadrem }
                        Validity:Boolean;
                       public
                        { inicializace: }
                        procedure Init(Rac:Byte; ActivityTim:LongInt;
                                       RndFactor:Byte; Special,Cor:Boolean);
                        { vlozeni noveho prvku: }
                        procedure NewMember(UnitTyp:Byte; Nam:String;
                                            Rank:Byte; Buil,TGNum:Byte);
                        procedure NewMemberMat(B,P,E,X:Word);
                        procedure Activate; { testovani aktivace teto posily
                                              a pripadne provedeni, pokud
                                              nadesel jeji cas }
                      end;

     TReinforcement = array [0..MaxReinforcement] of TSingleReinforcement;

procedure ReinfoManager;
procedure MissionSpecManager;
procedure ReadProductionSpeed(Num:Word);
function AnalyzeMap:Boolean;
procedure RecoverMap;

const Ws : set of Byte = [$0d,$20,$0a];
var ProductionCfgFile:file;
    ProductionCfgFileWay:String;
    IO_Result:Word;
    {x}
    Reinforcement: ^TReinforcement;
    MaxUsedReinforcement:Byte; { posledni pouzity index posil;
                                 255 = nepouzito  }
    Pom:Word;

procedure Set_placex(I, J :Word; _unit:PUnit);
procedure _units4_save;
procedure _units4_load;

implementation

uses _units3, buttons, mouse;

procedure TSingleReinforcement.Init(Rac:Byte; ActivityTim:LongInt;
                                    RndFactor:Byte; Special,Cor:Boolean);
{ inicializace posily pro rasu Race, casu aktivity ActivityTime a
  faktoru rozptylu RndFactor:
}
var S:Single;
begin
   MaxUsedInf:=255; Validity:=True; Seen:=0; Core:=Cor;
   if (MaxUsedReinforcement = 255) then MaxUsedReinforcement:=0
   else Inc(MaxUsedReinforcement);
   if (MaxUsedReinforcement > MaxReinforcement)
   then Error(0,'Prekrocen max pocet posil - unita _units4, procedura Init');

   with (Reinforcement^[MaxUsedReinforcement]) do begin
      ActivityTime:=ActivityTim;
      Race:=Rac; Spec:=Special;
      case (RndFactor) of
        0 : begin { 0% }
               ActivityTime:=ActivityTime;
            end;
        1 : begin { +-3% }
               S:=ActivityTime; S:=(S/100)*3;
               S:=Random(Round(S)+1); if (Rand(RndUk) mod 2 = 0) then S:=-S;
               ActivityTime:=ActivityTime+Round(S);
            end;
        2 : begin { +-5% }
               S:=ActivityTime; S:=(S/100)*5;
               S:=Random(Round(S)+1); if (Rand(RndUk) mod 2 = 0) then S:=-S;
               ActivityTime:=ActivityTime+Round(S);
            end;
        3 : begin { +-10% }
               S:=ActivityTime; S:=(S/100)*10;
               S:=Random(Round(S)+1); if (Rand(RndUk) mod 2 = 0) then S:=-S;
               ActivityTime:=ActivityTime+Round(S);
            end;
        4 : begin { +-15% }
               S:=ActivityTime; S:=(S/100)*15;
               S:=Random(Round(S)+1); if (Rand(RndUk) mod 2 = 0) then S:=-S;
               ActivityTime:=ActivityTime+Round(S);
            end;
        5 : begin { +3% }
               S:=ActivityTime; S:=(S/100)*3;
               S:=Random(Round(S)+1); ActivityTime:=ActivityTime+Round(S);
            end;
        6 : begin { +5% }
               S:=ActivityTime; S:=(S/100)*5;
               S:=Random(Round(S)+1); ActivityTime:=ActivityTime+Round(S);
            end;
        7 : begin { +10% }
               S:=ActivityTime; S:=(S/100)*10;
               S:=Random(Round(S)+1); ActivityTime:=ActivityTime+Round(S);
            end;
        8 : begin { +15% }
               S:=ActivityTime; S:=(S/100)*15;
               S:=Random(Round(S)+1); ActivityTime:=ActivityTime+Round(S);
            end;
      end;
   end;
end;

{ ***** }
procedure TSingleReinforcement.NewMember(UnitTyp:Byte; Nam:String;
                                         Rank:Byte; Buil,TGNum:Byte);
{ zalozi noveho clena posily - jednotku
}
begin
   if (MaxUsedInf = 255) then MaxUsedInf:=0
   else Inc(MaxUsedInf);
   if (MaxUsedInf > MaxInf)
   then Error(0,'Prekrocen max pocet clenu posily - unita _units4, procedura NewMember');

   with (Inf[MaxUsedInf]) do begin
     Material:=False; Experience:=Rank; Build:=Buil; TGNumber:=TGNum;
     UnitType:=UnitTyp;
     if (Nam = '$') then Name:='' else Name:=Nam;
   end;
end;

{ ***** }
procedure TSingleReinforcement.NewMemberMat(B,P,E,X:Word);
{ zalozi noveho clena posily - material
}
begin
   if (MaxUsedInf = 255) then MaxUsedInf:=0
   else Inc(MaxUsedInf);
   if (MaxUsedInf > MaxInf)
   then Error(0,'Prekrocen max pocet clenu posily - unita _units4, procedura NewMember');

   with (Inf[MaxUsedInf]) do begin
     Material:=True;
     _BP:=B; _PL:=P; _EE:=E; _EXP:=X;
   end;
end;

{ ***** }
procedure TSingleReinforcement.Activate;
{ detekuje, zda tento clen posily neni aktivni a pripadne se pokusi
  posily realizovat
}
var J,Ind:Word;
    Ok:Boolean;
    PUk:PUnit;
    I,Count:Integer;
    TUI:TUnitInfo;
begin
  Ok:=True; bebex:=666; save2:=Race;
  if (Validity and (ActivityTime <= (LongInt(Min_game_time)*60+Sec_game_time)) and
      (not Spec or (Races[Race].Ally = 1) or EnemySpecialReinforcementPresent))
  then with (Races[Race]) do begin { pracuj na posile }
    if (Inf[0].Material) then begin
    { MATERIAL }
      for I:=0 to MaxUsedInf do with (Inf[I]) do begin
         bebex:=667; bebey:=I;
         Building_credits:=Building_credits+_BP;
         Plastic_credits:=Plastic_credits+_PL;
         Electric_energy:=Electric_energy+_EE;
         Battle_experience:=Battle_experience+_EXP;
      end;
      {x}
      save2:=Race; bebex:=1667;
      if (Race = MyRace) then
         DialogBox('ZPRaVA PRO VELITELE: DOSTALI JSME POSILY - MATERIaLNe ZDROJE',_YES)
      else
         DialogBox('ZPRaVA ROZVdDKY: STRANA '+GetRaceName(RACE)+' OBDRkELA POSILY',_YES);
    end else begin
    { JEDNOTKY }
      bebex:=670;
      Count:=MaxUsedInf+1;
      if (Core) then Count:=GetCoreNum;
      if (Count > (MaxUsedInf+1)) then Count:=MaxUsedInf+1;
      save1:=Count;
      {x}
      PUk:=CentraPosil; { nejprve ziskame vhodne centrum posil }
      if (PUk = Nil) then Ok:=False
      else begin
        while ((PUk <> Nil) and ((MaxGroupUnits-PUk^.UnitsInsideNum-1) <= Count)) do begin
           PUk:=PUk^.Next;
        end;
        if (PUk <> Nil) then else Ok:=False;
      end;
      {x}
      bebex:=671;
      if (Ok) then begin
        if (Core) then begin { jadro }
          for I:=0 to Count-1 do
          if (GetCoreUnit(Rand(RndUk) shl 1+1,TUI)) then begin
              bebex:=672; bebey:=I;
              Ind:=New_unit(PUk^.IPos,PUK^.JPos,TUI.UnitType,Race,TUI.Level,0,
                            True,True,TUI.UnitType);
              bebex:=675;
              Units[Ind]^.Name:=TUI.Name;
              Units[Ind]^.UniqueNumber:=TUI.UniqueNumber;
              Units[Ind]^.Experience:=TUI.Experience;
              Units[Ind]^.Kills:=TUI.Kills;
              if (Race = MyRace) then with (Units[Ind]^) do begin
              { MOJE JEDNOTKY }
                   bebex:=701;
                   Activity:=False;
                   IInfoPos:=255; JInfoPos:=255; MovementAddingPhase:=0;
                   Inc(PUk^.UnitsInsideNum);
                   Inc(PUk^.UnitsInsidePlace,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                   J:=0;
                   { nyni se jednotka ulozi dovnitr cilove }
                   with (PUk^) do begin
                      bebex:=702;
                      while ((J <= MaxGroupUnits-2) and (UnitsInside[J] <> 0))
                      do Inc(J);
                      if (J > (MaxGroupUnits-2)) then
                        Error(0,'Chyba v jednotce _units4 - nakladani posil');
                      Units[Ind]^.GroupOrder:=(J+1);
                      Units[Ind]^.Status:=0; Units[Ind]^.MoveStatus:=0;
                      { poradi ulozeni uvnitr cilove jednotky + 1 }
                      UnitsInside[J]:=Ind;
                      bebex:=704;
                      if ((Group = ActiveGroup) and
                          (Groups[ActiveGroup].Count = 1)) then begin
                      { cilova jednotka je naclicknuta - zobraz
                        jednotky uvnitr na levy panel }
                        bebex:=703;
                        Click_on_Storage_unit(PUk);
                        CursorOff;
                        if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                        if (not Active(Vylozit)) then SetActive(Vylozit);
                        CursorOn;
                      end;
                   end;
              end;
          end;
        end else begin
            for I:=0 to MaxUsedInf do with (Inf[I]) do begin
               bebex:=680; bebey:=I;
               if (Build > 0) then
                 Ind:=New_unit(PUk^.IPos,PUK^.JPos,33,Race,Experience,0,
                               True,True,UnitType)
               else begin
                 bebex:=681;
                 if (Unit_types[UnitType,Ally].UnitLevel = 255) then begin
                    Ind:=New_unit(PUk^.IPos,PUK^.JPos,255,Race,Experience,0,
                                  True,True,UnitType);
                    Units[Ind]^._building:=False;
                 end else
                    Ind:=New_unit(PUk^.IPos,PUK^.JPos,UnitType,Race,Experience,0,
                                  True,True,UnitType);
               end;
               bebex:=682;
               if (Name <> '') then Units[Ind]^.Name:=Name;
               if (Race = MyRace) then with (Units[Ind]^) do begin
               { MOJE JEDNOTKY }
                   bebex:=683;
                   Activity:=False;
                   IInfoPos:=255; JInfoPos:=255; MovementAddingPhase:=0;
                   Inc(PUk^.UnitsInsideNum);
                   Inc(PUk^.UnitsInsidePlace,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                   J:=0;
                   { nyni se jednotka ulozi dovnitr cilove }
                   with (PUk^) do begin
                      bebex:=684;
                      while ((J <= MaxGroupUnits-2) and (UnitsInside[J] <> 0))
                      do Inc(J);
                      if (J > (MaxGroupUnits-2)) then
                        Error(0,'Chyba v jednotce _units4 - nakladani posil');
                      Units[Ind]^.GroupOrder:=(J+1);
                      Units[Ind]^.Status:=0; Units[Ind]^.MoveStatus:=0;
                      { poradi ulozeni uvnitr cilove jednotky + 1 }
                      UnitsInside[J]:=Ind;
                      if ((Group = ActiveGroup) and
                          (Groups[ActiveGroup].Count = 1)) then begin
                      { cilova jednotka je naclicknuta - zobraz
                        jednotky uvnitr na levy panel }
                        Click_on_Storage_unit(PUk);
                        CursorOff;
                        if (Active(Rozlozit)) then SetPasive(Rozlozit,256);
                        if (not Active(Vylozit)) then SetActive(Vylozit);
                        CursorOn;
                      end;
                   end;
               end else with (Units[Ind]^) do begin
               { CIZI JEDNOTKY }
                   bebex:=690;
                   if (TGNumber < InvalidTaskGroupNumber) then begin
                      if (TaskGroups^[TGNumber].Validity) then
                         AssignTaskGroup(Race,TGNumber,Units[Ind])
                      else
                        CreateNewTaskGroup(Race,TGNumber,Units[Ind]);
                     { jednotka se nalozila - odpocti ji od pocitadla
                       jednotek v jeji taskgrupe }
                      Dec(TaskGroups^[TaskGroup].Lock);
                      if (Unit_types[UnitType,Races[Race].Ally].TargetTyp = 3)
                      then Dec(TaskGroups^[TaskGroup].AirUnitsCount);
                   end;
                   bebex:=691;

                   { odstraneni jednotky z mapy i obrazovky }
                   Activity:=False;
                   IInfoPos:=255; JInfoPos:=255; MovementAddingPhase:=0;
                   { jsme v cili }
                   Inc(PUk^.UnitsInsideNum);
                   Inc(PUk^.UnitsInsidePlace,Unit_types[UnitType,Races[Race].Ally].NeedPlace);
                   J:=0; bebex:=692;
                   { nyni se jednotka ulozi dovnitr cilove }
                   with (PUk^) do begin
                      while ((J <= MaxGroupUnits-2) and (UnitsInside[J] <> 0))
                      do Inc(J);
                      if (J > (MaxGroupUnits-2)) then
                        Error(0,'Chyba v jednotce _units4 - zarazeni posil 2');
                      Units[Ind]^.GroupOrder:=(J+1);
                      Units[Ind]^.Status:=0; Units[Ind]^.MoveStatus:=0;
                      { poradi ulozeni uvnitr cilove jednotky + 1 }
                      UnitsInside[I]:=Ind;
                   end;
                   bebex:=693;
               end;
            end;
        end;
        Validity:=False;
        {}
        bebex:=700;
        if (Count > 0) then begin
          save2:=Race; bebex:=1693;
          if (Race = MyRace) then
             DialogBox('ZPRaVA PRO VELITELE: V CENTRU POSIL JSOU K DISPOZICI NOVc JEDNOTKY',_YES)
          else
             DialogBox('ZPRaVA ROZVdDKY: STRANA '+GetRaceName(RACE)+' OBDRkELA POSILY',_YES);
        end;
      end else
        if ((Race = MyRace) and (Seen = 0) and (Count > 0))
        then DialogBox('ZPRaVA PRO VELITELE: POSILY bEKAJe NA MOkNOST PfeJEZDU',_YES);
    end;

    {xxx}
    if (Ok) then begin
      Validity:=False; MaxUsedInf:=255;{}
    end;
    if (Seen = 0) then Seen:=1;
  end;
end;

{ ***** }
procedure ReinfoManager;
{ provadi kontrolu posil
}
var I:Word;
begin
  bebex:=65535; bebey:=65535; save1:=65535;
  if (MaxUsedReinforcement <= MaxReinforcement) then
    for I:=0 to MaxUsedReinforcement do begin
      Reinforcement^[I].Activate; save1:=I;
    end;
end;

{ ***** }
procedure MissionSpecManager;
{ u misi osetruje specialni pripady
}
var I,J,Pom:Word;
begin
  Val(MissionNameString,Pom,J);
  case (Pom{GlobalMOdify^.Game{}) of
    1 : begin
           if ((Min_game_time = 0) and (Sec_game_time = 1) and
               (MissionSpecManagerTag = 0)) then begin
             WideDialogBox('  PODeVEJTE SE NA CeLE MISE V MENU/INFORMACE/CeLE MISE. BUDOVAT MikETE',
                           'TAK, kE SI NAVOLeTE STISKEM TLAbeTKA MYgI ZaKLADNU (BUDOVA V LEVcM ',
                           'HORNeM ROHU) A STISKEM TLAbeTKA MYgI AKTIVUJE VjROBU Z NABeDKY.',
                           _YES);
             MissionSpecManagerTag:=1;
           end;
           if ((Min_game_time = 0) and (Sec_game_time = 2) and
               (MissionSpecManagerTag2 = 0)) then begin
             WideDialogBox('  NA PROHLeDKU OKOLe MaTE K DISPOZICI DVd JEDNOTKY. NAVOLTE SI JE DO',
                           'SKUPINY A OPATRNd PROPaTRaVEJTE OKOLe. V HORNe POLOVINd MAPY JSOU',
                           'NEPfaTELc SLABe A ROZPTjLENe.',
                           _YES);
             MissionSpecManagerTag2:=1;
           end;
           if ((Min_game_time = 0) and (Sec_game_time = 30) and
               (MissionSpecManagerTag3 = 0)) then begin
             WideDialogBox('  DO CENTRA POSIL VaM DORAZIL RECYKLaTOR. VYLOkTE JEJ A PfIKAkTE MU',
                           'PfESUN NA ZDROJ. ZDROJ SE NACHaZe VPRAVO NAHOfE, KOUSEK OD CENTRA POSIL.',
                           'RECYKLaTOR BUDE NATdkENj MATERIaL AUTOMATICKY VOZIT DO BUDOVY RECYKLACE.',
                           _YES);
             MissionSpecManagerTag3:=1;
           end;
           if ((Units[1147] <> Nil) and (Units[1147]^.Visibility) and (MissionSpecManagerTag1 = 0)) then begin
              WideDialogBox('  PRaVd JSTE SE DOSTAL NA DOHLED K VELMI NEBEZPEbNc JEDNOTCE - LEHKc',
                            'PEVNOSTI. K JEJeMU ZNIbENe VaM JEDNA JEDNOTKA STAbIT NEBUDE. ZKUSTE',
                            'POUkeT SKUPINU TANKOBORNeKi, NALOkENjCH V JEEPECH.',
                           _YES);
              MissionSpecManagerTag1:=1;
           end;
        end;
   52,110 : begin
           if ((Min_game_time = 0) and (Sec_game_time = 1) and
               (MissionSpecManagerTag = 0)) then begin
             WideDialogBox('  BUDOVAT MikETE TAK, kE SI NAJEDETE KURZOREM MYgI NAD ZaKLADNU',
                           '(BUDOVA V LEVcM HORNeM ROHU),VYBERETE SI JI STISKEM TLAbeTKA A',
                           'DALgeM STISKEM TLAbeTKA MYgI AKTIVUJE VjROBU Z NABeDKY.', _YES);
             MissionSpecManagerTag:=1;
           end;
           if ((Min_game_time = 0) and (Sec_game_time = 3) and
               (MissionSpecManagerTag1 = 0)) then begin
             WideDialogBox('  NYNe ZKUSTE STISKNOUT KLaVESU SHIFT A LEVc TLAbeTKO MYgI. DRkTE JE',
                           'STISKNUTc A TaHNdTE MYge. TAKTO NAVOLeTE VgECHNY JEDNOTKY UVNITf ',
                           'VZNIKLcHO OBDcLNeKU DO AKTIVNe SKUPINY.', _YES);
             MissionSpecManagerTag1:=1;
           end;
           if ((Min_game_time = 0) and (Sec_game_time >= 4) and
               (MissionSpecManagerTag2 = 0) and (ActiveGroup = MaxGroups) and
               (Groups[ActiveGroup].ClickStatus <= 4) and
               (Groups[ActiveGroup].Building = Nil))
           then begin
             WideDialogBox('  VjBORNd. S AKTIVNe SKUPINOU MikETE PROVaDdT fADU AKCe. ZADAT hTOK,',
                           'PfESUN ... VkDY NAJETeM KURZORU MYgI NAD PATfIbNc MeSTO A STISKEM',
                           'PRAVcHO TLAbeTKA MYgI. ZA CHVeLI SI ZKUSeME, JAK SE ZADaVAJe WAYPOINTY.', _YES);
             MissionSpecManagerTag2:=1;
           end;
           if ((Min_game_time = 0) and (Sec_game_time >= 8) and
               (MissionSpecManagerTag3 = 0) and (ActiveGroup = MaxGroups) and
               (Groups[ActiveGroup].ClickStatus <= 4) and
               (Groups[ActiveGroup].Building = Nil))
           then begin
             WideDialogBox('  ZADaVaNe WAYPOINTi SE ZAHAJUJE STISKEM KLaVESY "W". NA KURZORU',
                           'SE OBJEVe NaPIS "R". POTc PRAVjM TLAbeTKEM MYgI ZADaVaME TRASU',
                           'PfESUNU. ENTER ODEgLE SKUPINU PO TRASE, BCKSPACE VgE ZRUge.', _YES);
             MissionSpecManagerTag3:=1;
           end;
           if ((Min_game_time = 0) and (Sec_game_time >= 13) and
               (MissionSpecManagerTag4 = 0)) then begin
             WideDialogBox('  VeTE, kE STEJNjM ZPiSOBEM JAKO U JEDNOTEK LZE ZADAT WAYPOINT I PRO',
                           'VjROBNe BUDOVU? (PRODUKUJeCe JEDNOTKY). POTOM SE KAkDcMU VYROBENcMU ',
                           'OBJEKTU ZADANa TRASA PfIDdLe. VYZKOUgEJTE SI TENTO POSTUP U KASaREN.', _YES);
             MissionSpecManagerTag4:=1;
           end;{}
           if ((Min_game_time = 0) and (Sec_game_time >= 23) and
               (MissionSpecManagerTag5 = 0)) then begin
             WideDialogBox('  JAK JSTE SI JISTd VgIMLI, PO NAJETe KURZORU NAD NdJAKj OBJEKT SE',
                           'V INFORMAbNeM OKcNKU NAD TLAbeTKY OBJEVe KRaTKj POPIS. JE-LI OBJEKTEM',
                           'TLAbeTKO, JE V ZaVORCE UVEDENA "HORKa" (AKTIVAbNe) KLAVESA.', _YES);
             MissionSpecManagerTag5:=1;
           end;{}

           {if ((Min_game_time = 0) and (Sec_game_time = 4) and
               (MissionSpecManagerTag1 = 0)) then begin
             WideDialogBox('',
                           '',
                           '', _YES);
             MissionSpecManagerTag1:=1;
           end;{}
        end;
   54 : begin
           I:=3*MaxRaceUnits+1;
           if ((Units[I] <> Nil) and (MissionSpecManagerTag = 0)) then
            if (Units[I]^.Visibility) then begin
               if (WideDialogBox('  JAK JSTE SE PfIBLekIL, GENERaL K VaM PROMLUVIL: "NEZABeJEJTE MNE. ',
                                 'NABeZeM VaM MOkNOST PfIDAT SE NA NAgI STRANU. NEBUDE TO DLOUHO TRVAT',
                                 'A ZNIbeME VaS. MaTE POSLEDNe MOkNOST PfIDAT SE K BUDOUCeM VeTdZiM." ',
                                 _YES_NO) = YES) then begin
               { ZRADA ! }
                 EndOfGameTimmer:=100;
                 Victory:=1; Zrada:=True;
               { CHYBI ZDE ZMENY V GLOBAL MODIFY !!! }
               end else
                 DialogBox('  NIKDY! ZAHYNEg TY ZRaDCOVSKa BESTIE!',_YES);
               MissionSpecManagerTag := 1;
            end;
        end;
   61 : begin
          if ((Units[230] <> Nil) and (Units[230]^.Visibility) and (MissionSpecManagerTag1 = 0)) then begin
              WideDialogBox('  JAK VaS CIVILISTA SPATfIL, ZAbAL DIVOCE GESTIKULOVAT. PfaTELc, RADdJI',
                            'SE OTObTE, JINAK NESPLNeTE SViJ hKOL. hTeKaM OD POZIC ROBOTi, ABYCH VaS',
                            'VAROVAL. SPATfIL JSEM JE, JAK FORMUJe SILNj hTOK SMdREM NA VAgI ZaKLADNU.',
                           _YES);
              Inc(MissionSpecManagerTag1);
           end;
           if ((Units[230] <> Nil) and (Units[230]^.Visibility) and (MissionSpecManagerTag1 = 1)) then begin
              WideDialogBox('  ARMaDU ROBOTi MhkETE bEKAT ZA NdKOLIK MINUT. ',
                            '',
                            '',
                           _YES);
              Inc(MissionSpecManagerTag1);
           end;
        end;
   65 :begin
         if ((Units[4] <> Nil) and (Units[4]^.Visibility) and
             (MissionSpecManagerTag1 = 0)) then begin
             WideDialogBox('   TO, CO JSTE SPATfIL VaS gOKOVALO. PO VAgEM PfECHODU NA STRANU UNIE',
                           'SE V 5.BRIGaDd ROZPOUTAL BRATROVRAkEDNj BOJ. VAgE PfeTOMNOST JEDNOTKY',
                           'OPdT STMELILA. PiVODNd JICH BYLO 90. KOLIK ALE HRiZNj BOJ PfEkILO?', _YES);
             MissionSpecManagerTag1:=1;
           end;{}
       end;
  end;
end;

{ ***** }
procedure Set_placex(I, J :Word; _unit:PUnit);
{ jednotka je urcena ukazatelem _unit;
  SetMapInfo = True, ma-li se jednotka prepsat v poli MapInfo !
}
var K, L, I2, J2, IP, JP: Word;
    Color, PomDangerClass : Byte;
    Pom, MouseObstacle, SetMapInfo : Boolean;
    IModif, JModif:Integer;
    XMouse, YMouse : Word;
begin
   RdrawRadarFrame:=False; SetMapInfo:=True;
   with (_unit^) do with (MapBck^[I,J]) do
   with (MapBckTemp^[I,J]) do begin
     if (DangerClass <= 2) then PomDangerClass:=0 else
      if (DangerClass <= 5) then PomDangerClass:=1 else
       if (DangerClass <= 7) then PomDangerClass:=2 else
        if (DangerClass = 255) then PomDangerClass:=255;

     if (TargetType <> 3) then begin { jiny nez vzdusny cil }
       if (Visibilit and Races[MyRace].VisMask  = 0) then begin
         if (Visibility) then Eras:=True else Eras:=False;
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

{ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX }
     end else begin { vzdusny cil }
       if (Visibilit and Races[MyRace].VisMask  = 0) then begin
         if (Visibility) then Eras:=True else Eras:=False;
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
     end;

     if (SetMapInfo) then VisibilityChange:=False;
     if (SetMapInfo) then EnemyVisibilityChange:=False;
   end; { with (_unit^) }
end;

{ ****** }
procedure OpenProductionCfgFile;
{
}
var Way:String;
begin
   Way:='product.spd';
   InvalidateCache; Assign(ProductionCfgFile,Way); ProductionCfgFileWay:=Way;

   if (InternalCache) then begin
     IO_Result:=CacheFetch(Way);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + +ProductionCfgFileWay);
   end else begin
     Reset(ProductionCfgFile,1); IO_Result:=IOResult;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + +ProductionCfgFileWay);
   end;
end;

{ ****** }
procedure ReadComment;
{
}
var Character:Char;
begin
  if (not CacheEof(ProductionCfgFile)) then begin
    CacheBlockRead(ProductionCfgFile,@Character,1);
    if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
    while ((not CacheEof(ProductionCfgFile)) and (Character <> ';')) do begin
      CacheBlockRead(ProductionCfgFile,@Character,1);
      if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
    end;
  end;
end;

{ ***** }
function ReadWord:Word;
{ vraci 65535 pri konci souboru
}
var Character:Char;
    Num:Word;
begin
   Num:=0;
   if (CacheEof(ProductionCfgFile)) then begin
     ReadWord:=65535; Exit;
   end;
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);

   while ((not CacheEof(ProductionCfgFile)) and (not (Character in ['0'..'9']))) do begin
     CacheBlockRead(ProductionCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   end;

   if (CacheEof(ProductionCfgFile)) then begin
     ReadWord:=65535; Exit;
   end;

   repeat
     Num:=Num*10+(Ord(Character)-Ord('0'));
     CacheBlockRead(ProductionCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   until (CacheEof(ProductionCfgFile) or (not (Character in ['0'..'9'])));

   if (CacheEof(ProductionCfgFile)) then begin
     ReadWord:=65535; Exit;
   end;
   ReadWord:=Num;
end;

{ ***** }
function ReadSingle:Single;
{
}
var Character:Char;
    Num:Single;
begin
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);

   while ((not CacheEof(ProductionCfgFile)) and (not (Character in ['0'..'9']))) do begin
     CacheBlockRead(ProductionCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   end;

   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;

   Num:=10.0*(Ord(Character)-Ord('0'));
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   Num:=Num+Ord(Character)-Ord('0');
   { vynechame desetinnou tecku }
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   Num:=Num+0.1*(Ord(Character)-Ord('0'));

   ReadSingle:=Num;
end;

{ ****** }
procedure ReadProductionSpeed(Num:Word);
{ nacte a nastavi Production_time_plus
}
var P:Word;
begin
   OpenProductionCfgFile; Production_time_plus:=1;
   ReadComment;
   Production_time_plus:=Production_time_plus*ReadSingle;
   ReadComment; ReadComment;
   P:=ReadWord;
   while ((P <> 65535) and (P <> Num)) do begin
      ReadComment;
      P:=ReadWord;
   end;
   if ((P = Num) and (P <> 65535)) then begin
     Production_time_plus:=Production_time_plus*ReadSingle;
   end else begin
      Error(0,'spatny dotaz nebo chyba v souboru product.spd');
   end;
   Production_time_plus:=Round(Production_time_plus*100)/100;
end;

{ ***** }
function AnalyzeMap:Boolean;
{ vraci True, pokud nepratele nemaji na mape zadnou jednotku
}
var RacesInfo:array[0..MaxRace] of record
               Living:Integer;     { korektni pocet na mape }
               LivingBuildings:Integer; { korektni pocet budov na mape }
               Death:Integer;      { mrtve jednotky na mape }
               OutOfBound:Integer; { jednotky mimo mapu }
             end;
    Unrecognized:Integer;          { nezjistitelne zbytky na mape }
    UnrecognizedOutOfBound:Integer;  { nezjistitelne zbytky mimo mapu }
    I,J,K:Word;
    Result:Boolean;
begin
   Unrecognized:=0; UnrecognizedOutOfBound:=0; AnalyzeMap:=False;
   for K:=0 to MaxRace do with (RacesInfo[K]) do begin
      Living:=0; Death:=0; OutOfBound:=0; LivingBuildings:=0;
   end;
   {XXX}
   for J:=0 to JMaxSize do
     for I:=0 to IMaxSize do with (Map^[I,J]) do begin
       if (First_level <> 0) then begin
         if (Level_type and 128 = 128) then begin
         { budova }
            if (Buildings[First_level] = Nil) then
            else Inc(RacesInfo[Buildings[First_level]^.Race].LivingBuildings);
         end else begin
         { jednotka }
            if (Units[First_level] = Nil) then begin
              if ((I > IMax) or (J > JMax)) then
                Inc(UnrecognizedOutOfBound)
              else Inc(Unrecognized);
            end else with (Units[First_level]^) do begin
               if ((I > IMax) or (J > JMax)) then begin
                  Inc(RacesInfo[Race].OutOfBound);
               end else begin
                 if (Destroyed) then Inc(RacesInfo[Race].Death)
                 else Inc(RacesInfo[Race].Living);
               end;
            end;
         end;
       end;
       if (Second_level <> 0) then begin
       {letoun}
          if (Units[Second_level] = Nil) then begin
            if ((I > IMax) or (J > JMax)) then
              Inc(UnrecognizedOutOfBound)
            else Inc(Unrecognized);
          end else with (Units[Second_level]^) do begin
             if ((I > IMax) or (J > JMax)) then begin
                Inc(RacesInfo[Race].OutOfBound);
             end else begin
               if (Destroyed) then Inc(RacesInfo[Race].Death)
               else Inc(RacesInfo[Race].Living);
             end;
          end;
       end;
     end;
    {x}
    Result:=True;
    for K:=0 to MaxRace do
    if ((Races[K].Friend[MyRace] = 0) and (not Races[K].Neutral)) then
    with (RacesInfo[K]) do begin
       Result:=Result and (Living = 0) and (Death = 0);
    end;
    AnalyzeMap:=Result;
end;

{ ***** }
procedure RecoverMap;
{ snaha o recover mapy
}
var I,J,K:Word;
begin
   {XXX}
   for J:=0 to JMaxSize do
     for I:=0 to IMaxSize do with (Map^[I,J]) do begin
       if (First_level <> 0) then begin
         if (Level_type and 128 = 128) then begin
         { budova }
            if (Buildings[First_level] = Nil) then begin
               First_level:=0; Level_type:=Level_type and 127;
            end;
         end else begin
         { jednotka }
            if (Units[First_level] = Nil) then begin
              First_level:=0;
            end;
         end;
       end;
       if (Second_level <> 0) then begin
       {letoun}
         if (Units[Second_level] = Nil) then begin
           Second_level:=0;
         end;
       end;
     end;
    {x}
end;

{ ***** }
procedure _units4_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'21'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
   then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Reinforcement^,SizeOf(Reinforcement^));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MaxUsedReinforcement,SizeOf(MaxUsedReinforcement));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag,SizeOf(MissionSpecManagerTag));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag1,SizeOf(MissionSpecManagerTag1));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag2,SizeOf(MissionSpecManagerTag2));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag3,SizeOf(MissionSpecManagerTag3));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag4,SizeOf(MissionSpecManagerTag4));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag5,SizeOf(MissionSpecManagerTag5));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag6,SizeOf(MissionSpecManagerTag6));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag7,SizeOf(MissionSpecManagerTag7));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag8,SizeOf(MissionSpecManagerTag8));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag9,SizeOf(MissionSpecManagerTag9));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MissionSpecManagerTag10,SizeOf(MissionSpecManagerTag10));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure _units4_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'21'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,Reinforcement^,SizeOf(Reinforcement^));DResult:=IOResult;
     if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MaxUsedReinforcement,SizeOf(MaxUsedReinforcement));DResult:=IOResult;
     if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag,SizeOf(MissionSpecManagerTag));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag1,SizeOf(MissionSpecManagerTag1));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag2,SizeOf(MissionSpecManagerTag2));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag3,SizeOf(MissionSpecManagerTag3));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag4,SizeOf(MissionSpecManagerTag4));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag5,SizeOf(MissionSpecManagerTag5));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag6,SizeOf(MissionSpecManagerTag6));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag7,SizeOf(MissionSpecManagerTag7));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag8,SizeOf(MissionSpecManagerTag8));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag9,SizeOf(MissionSpecManagerTag9));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;
  {x}BlockRead(IOFile,MissionSpecManagerTag10,SizeOf(MissionSpecManagerTag10));DResult:=IOResult;
      if (DResult <> 0) then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************** }
begin
  MaxUsedReinforcement:=255;
  New(Reinforcement);
  if (Reinforcement = Nil) then begin
     Writeln('Chyba - nedostatek pameti');
     Halt(0);
  end;
  for Pom:=0 to MaxReinforcement do with (Reinforcement^[Pom]) do begin
     Validity:=False;
  end;
  MissionSpecManagerTag:=0; MissionSpecManagerTag1:=0; MissionSpecManagerTag2:=0;
  MissionSpecManagerTag3:=0; MissionSpecManagerTag4:=0;
  MissionSpecManagerTag5:=0; MissionSpecManagerTag6:=0;
  MissionSpecManagerTag7:=0; MissionSpecManagerTag8:=0;
  MissionSpecManagerTag9:=0; MissionSpecManagerTag10:=0;
end.
