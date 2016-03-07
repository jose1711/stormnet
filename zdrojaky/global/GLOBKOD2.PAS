unit GlobKod2;
{$C FIXED PRELOAD PERMANENT}
interface

function SelectMission:Boolean;

implementation
uses Crt, Data_glb, GlobGraf, Specgraf, Buttons, Mouse, Graph257,GlobalKod,
     GlobKod3;

{ ***** }

function SelectMission2:Boolean; forward;

{ ***** }
function SelectMission:Boolean;
{
  provede volbu mise; vraci True pri porazce
}
var PomStr, Str1, Str2, Str3:String;
    Return:Boolean;
    Pom:Byte;
    TempValue:Integer;
    XSize, YSize:Word;
begin
  CursorOff;
  Pom:=Random(6)+1;{}{ Pom:=Random(2)+5;{}
  Str(Pom,PomStr);
  ClearScreen;
  OpenImage(PathStrGlobal+'data\obr'+PomStr+'.bmp',NoCreateNew);
  GetXYImageCoordinatesBMP(XSize,YSize);
  LoadImageBMP(SScreen,OScreen,NoRGB);
  LoadRGB(0,PathStrGlobal+'data\paleta1'+PomStr+'.rgb');
  if (IO_Result = 0) then
    PutImage((XResolution-XSize) shr 1,(YResolution-YSize) shr 1,SScreen,OScreen,ReverseDirect);
  InvalidateCache;
  OpenImage(PathStrGlobal+'data\buttons.glb',NoCreateNew);
  LoadImageGBM(On1Seg,On1Offs,'on1_'+PomStr,0);
  LoadImageGBM(Off1Seg,Off1Offs,'off1_'+PomStr,0);
  {X}
  OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
  LoadImageGBM(CursorSegment,CursorOffsets,'normal'+PomStr,0);
  {X}
  InvalidateCache;
  case (Pom) of
    1: begin Blue:=149; DarkBlue:=207; Yellow:=136; DarkYellow:=122; White:=5; end;
    2: begin Blue:=210; DarkBlue:=251; Yellow:=207; DarkYellow:=197; White:=6; end;
    3: begin Blue:=242; DarkBlue:=249; Yellow:=218; DarkYellow:=185; White:=12;end;
    4: begin Blue:=160; DarkBlue:=168; Yellow:=136; DarkYellow:=123; White:=11;end;
    5: begin Blue:=224; DarkBlue:=244; Yellow:=181; DarkYellow:=155; White:=12;end;
    6: begin Blue:=166; DarkBlue:=234; Yellow:=153; DarkYellow:=144; White:=8;end;
  end;
  CursorOn;

  VICTORYPOINTS:=VICTORYPOINTS-VPointsPerMission;
  POINTS:=POINTS-PointsPerMission;
  ResearchRandomStep:=0; ResearchRandom:=Random(3);

  Return:=True; Inc(MissionNum);

  if (Campaign<=2) then begin
    case (Game) of
       0 : begin { uvodni mise }
              MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   VeTaME VaS VE VjCVIKOVcM STfEDISKU MeROVjCH SIL OSN, FORT BRAGG, USA.';
              GlobalInfoStr[1]:='JE PRaVd 21.feJNA 2009, NdKOLIK DNe PfED VYfAZENeM PRVNeCH KADETi.';
              MaxUsedGlobalInfo:=1;
              Mission1InfoStr[0]:='VjCVIKOVc STfEDISKO OSN';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='52';
                Game:=52; Campaign:=1; EnemyRaces:=[4,5];
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{}
                {Error(0,'Chybny vyber mise - SelectMission, case0'); {}
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       1 : begin
              if (Victory < 1) then begin
                  Return:=False;
              end else begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                  GlobalInfoStr[0]:='';
                  MaxUsedGlobalInfo:=255;
                  Mission1InfoStr[0]:='LIKVIDACE TaBORA POLOVOJENSKjCH ODDeLi';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='';{}
                  MaxUsedMission2Info:=255;
                  if (DrawMissionSelect = 1) then begin
                    MissionNameString:='2';
                    Game:=2; Campaign:=1; EnemyRaces:=[5];
                  end else begin
                    {MissionNameString:='1';
                    Game:=1; Campaign:=1;{}
                    {Error(0,'Chybny vyber mise - SelectMission, case1'); {}
                  end;
              end;
              if (Return) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 <> 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       2 : begin
              { X NOVE TECHNOLOGIE X}
              Pom:=Rand(RndUk) mod 2; Research^[33+Pom].Validity:=True;
              { X NOVE TECHNOLOGIE X}
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI*2.5;
                  POINTS:=POINTS+POI*2.5;
                  GlobalInfoStr[0]:='   PROTOkE JSTE SE OSVdDbIL, NABeZeME VaM MOkNOST ZhbASTNIT SE SPOLU';
                  GlobalInfoStr[1]:='S NEJLEPgeMI UNIKaTNe OPERACE - LIKVIDACE IRaCKcHO DIKTaTORA. DaVaTE VgAK';
                  GlobalInfoStr[2]:='LECCOS V SaZKU - NEhSPdCH VaS MikE STaT URbITc FINANbNe PROSTfEDKY. JINAK';
                  GlobalInfoStr[3]:='MikETE POKRAbOVAT V OPERACeCH NA BALKaNd.';
                  MaxUsedGlobalInfo:=3;
                  Mission1InfoStr[0]:='NEPOVINNa MISE - LIKVIDACE SADDaMA HUSSAINA';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='EVAKUACE CIVILNeCH PRACOVNeKi OSN';{}
                  MaxUsedMission2Info:=0;
                  if (DrawMissionSelect = 1) then begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='5'; Game:=5; Campaign:=1; EnemyRaces:=[5];
                    if ((POINTS >= 755) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 755,  PRESTIk: 0',Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-755; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=50;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=50;
                      end;
                    end;
                  end else begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='6'; Game:=6; Campaign:=1; EnemyRaces:=[5];
                    if ((POINTS >= 320) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 320,  PRESTIk: 1',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-320; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].PLModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].EEModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=20;
                      end;
                    end;
                    if ((POINTS >= 800) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                        'CENA: KREDITY: 800,  PRESTIk: 0',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-800; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.AllyFog:=1;
                      end;
                    end;
                    {Error(0,'Chybny vyber mise - SelectMission, case2'); {}
                  end;
              end else begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  MaxMissionCoreUnits:=2; { max. pocet jednotek jadra do mise }
                  GlobalInfoStr[0]:='';
                  MaxUsedGlobalInfo:=255;
                  Mission1InfoStr[0]:='DRUHj POKUS O LIKVIDACI TaBORA POLOVOJENSKjCH ODDeLi';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='';{}
                  MaxUsedMission2Info:=255;
                  if (DrawMissionSelect = 1) then begin
                    MissionNameString:='3';
                    Game:=3; Campaign:=1; EnemyRaces:=[5];
                  end else begin
                    if ((POINTS >= 500) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 500,  PRESTIk: 0',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-500; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=30;
                        GlobalModify.RaceMaterialModifiers[0].PLModif:=30;
                        GlobalModify.RaceMaterialModifiers[0].EEModif:=30;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=30;
                      end;
                    end;
                    {MissionNameString:='1';
                    Game:=1; Campaign:=1;{}
                    {Error(0,'Chybny vyber mise - SelectMission, case2'); {}
                  end;
              end;
              if (Return) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       3 : begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  GlobalInfoStr[0]:='   PROTOkE JSTE SE OSVdDbIL, NABeZeME VaM MOkNOST ZhbASTNIT SE SPOLU';
                  GlobalInfoStr[1]:='S NEJLEPgeMI UNIKaTNe OPERACE - LIKVIDACE IRaCKcHO DIKTaTORA. DaVaTE VgAK';
                  GlobalInfoStr[2]:='LECCOS V SaZKU - NEhSPdCH VaS MikE STaT URbITc FINANbNe PROSTfEDKY. JINAK';
                  GlobalInfoStr[3]:='MikETE POKRAbOVAT V OPERACeCH NA BALKaNd.';
                  MaxUsedGlobalInfo:=3;
                  Mission1InfoStr[0]:='NEPOVINNa MISE - LIKVIDACE SADDaMA HUSSAINA';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='EVAKUACE CIVILNeCH PRACOVNeKi OSN';{}
                  MaxUsedMission2Info:=0;
                  if (DrawMissionSelect = 1) then begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='5'; Game:=5; Campaign:=1; EnemyRaces:=[5];
                    if ((POINTS >= 755) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 755,  PRESTIk: 0',Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-755; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=50;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=50;
                      end;
                    end;
                  end else begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='6'; Game:=6; Campaign:=1;{} EnemyRaces:=[5];
                    if ((POINTS >= 320) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 320,  PRESTIk: 1',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-320; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].PLModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].EEModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=20;
                      end;
                    end;
                    if ((POINTS >= 800) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                        'CENA: KREDITY: 800,  PRESTIk: 0',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-800; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.AllyFog:=1;
                      end;
                    end;
                    {Error(0,'Chybny vyber mise - SelectMission, case2'); {}
                  end;
              end else begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  MaxMissionCoreUnits:=4; { max. pocet jednotek jadra do mise }
                  GlobalInfoStr[0]:='';
                  MaxUsedGlobalInfo:=255;
                  Mission1InfoStr[0]:='POSLEDNe POKUS O LIKVIDACI TaBORA POLOVOJENSKjCH ODDeLi';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='';{}
                  MaxUsedMission2Info:=255;
                  if (DrawMissionSelect = 1) then begin
                    MissionNameString:='4';
                    Game:=4; Campaign:=1; EnemyRaces:=[5];
                  end else begin
                    if ((POINTS >= 1300) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 1300,  PRESTIk: 0',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1300; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=30;
                        GlobalModify.RaceMaterialModifiers[0].PLModif:=30;
                        GlobalModify.RaceMaterialModifiers[0].EEModif:=30;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=30;
                      end;
                    end;
                    {MissionNameString:='1';
                    Game:=1; Campaign:=1;{}
                    {Error(0,'Chybny vyber mise - SelectMission, case3'); {}
                  end;

              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       4 : begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  GlobalInfoStr[0]:='   PROTOkE JSTE SE OSVdDbIL, NABeZeME VaM MOkNOST ZhbASTNIT SE SPOLU';
                  GlobalInfoStr[1]:='S NEJLEPgeMI UNIKaTNe OPERACE - LIKVIDACE IRaCKcHO DIKTaTORA. DaVaTE VgAK';
                  GlobalInfoStr[2]:='LECCOS V SaZKU - NEhSPdCH VaS MikE STaT URbITc FINANbNe PROSTfEDKY. JINAK';
                  GlobalInfoStr[3]:='MikETE POKRAbOVAT V OPERACeCH NA BALKaNd.';
                  MaxUsedGlobalInfo:=3;
                  Mission1InfoStr[0]:='NEPOVINNa MISE - LIKVIDACE SADDaMA HUSSAINA';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='EVAKUACE CIVILNeCH PRACOVNeKi OSN';{}
                  MaxUsedMission2Info:=0;
                  if (DrawMissionSelect = 1) then begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='5'; Game:=5; Campaign:=1; EnemyRaces:=[5];
                    if ((POINTS >= 755) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 755,  PRESTIk: 0',Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-755; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=50;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=50;
                      end;
                    end;
                  end else begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='6'; Game:=6; Campaign:=1;{} EnemyRaces:=[5];
                    if ((POINTS >= 320) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                        'CENA: KREDITY: 320,  PRESTIk: 1',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-320; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.RaceMaterialModifiers[0].BPModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].PLModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].EEModif:=20;
                        GlobalModify.RaceMaterialModifiers[0].ExpModif:=20;
                      end;
                    end;
                    if ((POINTS >= 800) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                        'CENA: KREDITY: 800,  PRESTIk: 0',
                                        Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-800; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.AllyFog:=1;
                      end;
                    end;
                    {Error(0,'Chybny vyber mise - SelectMission, case4'); {}
                  end;

              end else begin
                  Return:=False;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       5 : begin
              if (Victory < 0) then VICTORYPOINTS:=VICTORYPOINTS-1; { penalizace }
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='     Nag ZaSAH PROTI IRaKU BOHUkEL VYVOLAL BOUfI NEVOLE MEZI ARABSKjMI';
              GlobalInfoStr[1]:='STaTY. NENaVIST PROTI ZaPADNeMU SVdTU SE JEgTd VeCE PROHLOUBILA. ZDa SE,';
              GlobalInfoStr[2]:='kE JSME DOSLOVA PeCHLI DO VOSeHO HNeZDA. NAgI ANALYTICI SITUACI ODHADLI';
              GlobalInfoStr[3]:='CHYBNd A NYNe MUSeME bELIT NaSLEDKiM. TISeCE DOBROVOLNeKi MUSLIMSKc VeRY';
              GlobalInfoStr[4]:='SE HLaSe DO "ODDeLi ODPLATY". STALO SE VdCe HRDOSTI BOJOVAT PROTI VELKcMU';
              GlobalInfoStr[5]:='SATANOVI, TEDY NaM. NAgIM SILaM NEZBjVa NIC JINcHO, NEk URYCHLENa EVAKUACE.';
              GlobalInfoStr[6]:='PROTOkE JSME S TOUTO SITUACe NEPObeTALI, POTfEBUJEME ZeSKAT NdJAKj bAS.';
              GlobalInfoStr[7]:='VAgeM hKOLEM BUDE UDRkET PfeVAL MUSLIMSKjCH BOJOVNeKi DO Tc DOBY, NEk SE';
              GlobalInfoStr[8]:='JEDNOTKY OSN DOSTANOU NA EVAKUAbNe LODd.';
              MaxUsedGlobalInfo:=8;
              Mission1InfoStr[0]:='BOJ S ISLaMSKjMI FUNDAMENTALISTY';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='50';
                Game:=50; Campaign:=1; EnemyRaces:=[4];
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1; EnemyRaces:=[5]; {}
                {Error(0,'Chybny vyber mise - SelectMission, case5'); {}
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       6 : begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=1; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='     LITUJEME VELITELI, ALE OPdT VaS MUSeME ODVOLAT OD VAgICH hKOLi NA JINj';
              GlobalInfoStr[1]:='KONEC PLANETY. EXILOVa VLaDA JEMENU NaS POkADALA, ABYCHOM Je POMOHLI';
              GlobalInfoStr[2]:='SVRHNOUT SOUbASTNj DIKTaTORSKj REkIM. MaME INFORMACE, kE NYNdJge VEDENe';
              GlobalInfoStr[3]:='HRUBd PORUgUJE LIDSKa PRaVA. MIMOTO JSOU ZDE ZNAbNa NALEZIgTd ROPY. JELIKOk';
              GlobalInfoStr[4]:='SE JEDNa O VELMI DELIKaTNe OPERACI, NEBUDETE VYSTUPOVAT POD OFICIaLNe';
              GlobalInfoStr[5]:='HLAVIbKOU OSN.';
              MaxUsedGlobalInfo:=5;
              Mission1InfoStr[0]:='VYVOLaNe VZPOURY PROTI DIKTaTORSKcMU REkIMU';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='51';
                Game:=51; Campaign:=1; EnemyRaces:=[5];
                if ((POINTS >= 500) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                    'CENA: KREDITY: 500,  PRESTIk: 0',
                                    Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-500; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.FriendlySpecialUnitsPresent:=True;
                  end;
                end;
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{} EnemyRaces:=[5];
                {Error(0,'Chybny vyber mise - SelectMission, case6'); {}
              end;

              { X NOVE TECHNOLOGIE X}
              if (not Research^[33].Validity) then Research^[33].Validity:=True;
              if (not Research^[34].Validity) then Research^[34].Validity:=True;
              { X NOVE TECHNOLOGIE X}
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       7 : begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=1; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='     SITUACE SE ZHORgUJE. ZTRaTY V fADaCH OSN DOSaHLY KRITICKOU MEZ.';
              GlobalInfoStr[1]:='POLITICI VE bLENSKjCH STaTECH JEN S OBTekEMI VYSVdTLUJe VEfEJNOSTI NUTNOST';
              GlobalInfoStr[2]:='OPERACe SPOJENjCH NaRODi. ROZHODLI JSME SE K RAZANTNeMU KROKU. Z NAgEHO';
              GlobalInfoStr[3]:='"ARIZONA RESEARCH CENTER" PRaVd VYJekDe NOVa, REVOLUbNe TECHNICKa ZAfeZENe.';
              GlobalInfoStr[4]:='     BYL JSTE POVdfEN JEJeM TESTOVaNeM NA POMdRNd KLIDNc DEMARKAbNe LINII';
              GlobalInfoStr[5]:='NA OSTROVd KYPR.';
              MaxUsedGlobalInfo:=5;
              Mission1InfoStr[0]:='SEZNaMENe S NOVOU TECHNIKOU';
              MaxUsedMission1Info:=1;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='8';
                Game:=8; Campaign:=1; EnemyRaces:=[5];
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{} EnemyRaces:=[5];
                {Error(0,'Chybny vyber mise - SelectMission, case7'); {}
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       8 : begin
              { X NOVE TECHNOLOGIE X}
              Research^[35].Validity:=True;
              { X NOVE TECHNOLOGIE X}
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=5; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='';
              MaxUsedGlobalInfo:=255;
              Mission1InfoStr[1]:='OBRANA POZIC OSN NA KYPRU';
              MaxUsedMission1Info:=1;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='9';
                Game:=9; Campaign:=1; EnemyRaces:=[4,5];
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{} EnemyRaces:=[5];
                {Error(0,'Chybny vyber mise - SelectMission, case8'); {}
              end;
              if (Return and (Rand(RndUk) < 9)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       9 : begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory = 1) then begin
                GlobalInfoStr[0]:='   Nag VOJENSKj TLAK PfINESL OVOCE. JAK TURECKO, TAK I fECKO SE ZAVaZALO';
                GlobalInfoStr[1]:='DODRkOVAT KLID ZBRANe A RESPEKTOVAT MeROVOU ROLI VOJSK OSN. TAKkE MaME';
                GlobalInfoStr[2]:='VOLNc RUCE K DALgeM AKCeM NA TERIRORIU BjVALc JUGOSLaVIE.';
                GlobalInfoStr[4]:='   ZPRaVA TAJNc SLUkBY:';
                GlobalInfoStr[5]:='  PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, NASADe NEPfaTELc';
                GlobalInfoStr[6]:='V NaSLEDUJeCeCH BOJeCH VYLEPgENj TYP "ALIGaTOR". HLAVNe ZMdNY SPObeVAJe';
                GlobalInfoStr[7]:='V MONTakI LEPgeHO PANCefE A KVALITNdJgeCH ZBRANe.';
                MaxUsedGlobalInfo:=7;
                Mission1InfoStr[0]:='POKRAbOVaNe V hSPdgNcM TESTOVaNe ROBOTi';
                MaxUsedMission1Info:=0;
                Mission2InfoStr[0]:='';{}
                MaxUsedMission2Info:=255;
              end else begin
                GlobalInfoStr[0]:='   I PfES NEhSPdCH PfEDCHOZe OPERACE VaM DaME NA VjBdR. MikETE SE';
                GlobalInfoStr[1]:='ZhbASTNIT OBNOVENe POZIC NA KYPRU, NEBO POKRAbOVAT V TESTOVaNe NOVc';
                GlobalInfoStr[2]:='TECHNIKY.';
                MaxUsedGlobalInfo:=2;
                Mission1InfoStr[0]:='POKRAbOVaNe V TESTOVaNe ROBOTi';
                MaxUsedMission1Info:=0;
                Mission2InfoStr[0]:='OBRANA OBNOVENjCH POZIC NA KYPRU';{}
                MaxUsedMission2Info:=0;
              end;

              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                MissionNameString:='10';
                Game:=10; Campaign:=1; EnemyRaces:=[4,5];
                ReserchAssign[28,1].UnitAvail:=1;
                ReserchAssign[28,1].ForPlayer:=True;
              end else begin
                MaxMissionCoreUnits:=5; { max. pocet jednotek jadra do mise }
                MissionNameString:='9';
                Game:=9; Campaign:=1; EnemyRaces:=[4,5];
              end;
              if (Return and ((Rand(RndUk) < 8) or (Game = 10))) then OfferNewCoreUnit;
              if (Return and ((Rand(RndUk) mod 3 = 0) or (Game = 10))) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       10: begin
              if (Victory = 1) then begin
                 VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                 POINTS:=POINTS+POI;
                 GlobalModify.RaceMaterialModifiers[0].BPModif:=33;
              end else begin
                 VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                 POINTS:=POINTS+POI;
              end;
              GlobalInfoStr[0]:='       DOSTALI JSME ZAJeMAVOU NABeDKU OD SPfaTELENjCH ODDeLi. POKUD JIM';
              GlobalInfoStr[1]:='POMikEME ZLIKVIDOVAT VaLEbNcHO ZLObINCE, KTERj SE PODeLEL NA VRAkDdNe';
              GlobalInfoStr[2]:='MeSTNeHO OBYVATELSTVA, MikEME V BUDOUCNU PObeTAT S JEJICH PODPOROU.';
              GlobalInfoStr[3]:='TATO MISE JE VELMI NEBEZPEbNa, PROTO JE hbAST V Ne DOBROVOLNa.';
              MaxUsedGlobalInfo:=3;
              Mission1InfoStr[0]:='LIKVIDACE VaLEbNcHO ZLObINCE';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='POKRAbOVAT V TESTOVaNe PLNd AUTOMATIZOVANjCH ROBOTi';{}
              MaxUsedMission2Info:=0;
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=10; { max. pocet jednotek jadra do mise }
                MissionNameString:='11';
                Game:=11; Campaign:=1; EnemyRaces:=[5];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (700+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(700+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-700-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.AllyFog:=1;
                  end;
                end;
              end else begin
                MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
                MissionNameString:='12';
                Game:=12; Campaign:=1; EnemyRaces:=[4,5];
                {X}
                TempValue:=Random(100); if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (600+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(600+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE O TERcNU?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-600-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.UnknownTerrain:=1;
                  end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (700+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(700+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-700-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.AllyFog:=1;
                  end;
                end;
              end;
              if (Game = 12) then OfferSpecialCoreUnit(24,0,'MECH KILLER');
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       11: begin
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
              case (Victory) of
                 1 : begin
                       GlobalModify.RaceMaterialModifiers[0].ExpModif:=30;
                       GlobalModify.RaceTypeModifiers[1]:=1;
                     end;
                 0 : GlobalModify.RaceMaterialModifiers[0].ExpModif:=-10;
                -1 : GlobalModify.RaceMaterialModifiers[0].ExpModif:=-50;
              else
                 {Error(0,'Chybny vysledek mise - SelectMission, case11'); {}
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='';
              MaxUsedGlobalInfo:=255;
              Mission1InfoStr[0]:='POKRAbOVAT V TESTOVaNe PLNd AUTOMATIZOVANjCH ROBOTi';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='12';
                Game:=12; Campaign:=1; EnemyRaces:=[5];
                {X}
                TempValue:=Random(100); if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (600+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(600+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE O TERcNU?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-600-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.UnknownTerrain:=1;
                  end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (700+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(700+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-700-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.AllyFog:=1;
                  end;
                end;
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{} EnemyRaces:=[4,5];
                {Error(0,'Chybny vyber mise - SelectMission, case11'); {}
              end;
              if (Game = 12) then OfferSpecialCoreUnit(24,0,'MECH KILLER');
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       12: begin
              if (Victory >= 0) then begin
                  if (Victory = 1) then begin
                    VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                    POINTS:=POINTS+POI;
                  end else begin
                    VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI/2;
                    POINTS:=POINTS+POI/2;
                  end;
                  MaxMissionCoreUnits:=4; { max. pocet jednotek jadra do mise }
                  GlobalInfoStr[0]:='   MAJORE, OKAMkITd SE DOSTAVTE K VELITELI. DOgLO K NEObEKaVANc KATASTROFd.';
                  GlobalInfoStr[1]:='NA BRIEFINGU VaM BUDOU VYSVdTLENY PODROBNOSTI.';
                  GlobalInfoStr[3]:='   ZPRaVA TAJNc SLUkBY:';
                  GlobalInfoStr[4]:='  PODLE UKOfISTdNjCH DOKUMENTi JSME ZJISTILI, kE NAgI NEPfaTELc NASADe ';
                  GlobalInfoStr[5]:='V NaSLEDUJeCeCH BOJeCH KVALITNdJge Pdge JEDNOTKY. VOJaCI JSOU VYBAVENI';
                  GlobalInfoStr[6]:='LEPge NEPRiSTfELNOU VESTOU A MODERNdJgeMI ZBRANdMI.';
                  MaxUsedGlobalInfo:=6;
                  Mission1InfoStr[0]:='PROBLcM NA ZaKLADNd';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='';{}
                  MaxUsedMission2Info:=255;
                  if (DrawMissionSelect = 1) then begin
                    MissionNameString:='20';
                    Game:=20; Campaign:=1; EnemyRaces:=[3];
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (260+TempValue)) and (VICTORYPOINTS >= 2)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(260+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 2';
                       if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-260-TempValue; VICTORYPOINTS:=VICTORYPOINTS-2;
                         GlobalModify.RaceMaterialModifiers[0].BPModif:=100;
                         GlobalModify.RaceMaterialModifiers[0].ExpModif:=100;
                         GlobalModify.RaceMaterialModifiers[0].PLModif:=100;
                         GlobalModify.RaceMaterialModifiers[0].EEModif:=100;
                       end;
                    end;
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (500+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                       if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                         GlobalModify.FriendlySpecialUnitsPresent:=True;
                       end;
                    end;
                  end else begin
                    {MissionNameString:='1';
                    Game:=1; Campaign:=1; EnemyRaces:=[5];{}
                    {Error(0,'Chybny vyber mise - SelectMission, case12'); {}
                  end;
              end else begin
                  Return:=False;
              end;

              { X NOVE TECHNOLOGIE X}
              if (not Research^[35].Validity) then Research^[35].Validity:=True;
              { X NOVE TECHNOLOGIE X}
              if (Return) then OfferNewCoreUnit;
              if (Return) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       20: begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  GlobalInfoStr[0]:='   VRCHNe VELENe SE PfESVdDbILO O VAgICH KVALITaCH. DaVa VaM PROTO NA';
                  GlobalInfoStr[1]:='VYBRANOU OBLAST, VE KTERc BUDETE ZASAHOVAT.';
                  GlobalInfoStr[3]:='   ZPRaVA VOJENSKc ZPRAVODAJSKc SLUkBY:';
                  GlobalInfoStr[4]:='  V NEJBLIkgeCH HODINaCH ObEKaVaME NASAZENe NOVc NEPfaTELSKc TECHNIKY.';
                  GlobalInfoStr[5]:='NOVj TYP SE JMENUJE "TdkKc VZNagEDLO". MdL BY BjT ZDOKONALENeM LEHKcHO';
                  GlobalInfoStr[6]:='VZNagEDLA, SETROJENcHO JEgTd LIDSKjMI INkENjRY.';
                  MaxUsedGlobalInfo:=6;
                  Mission1InfoStr[0]:='NEPOVINNa (VELMI RISKANTNe) MISE OBRANY ZaKLADNY';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='DALge BOJE S ROBOTY';{}
                  MaxUsedMission2Info:=0;
                  if (DrawMissionSelect = 1) then begin
                    {X}
                    TempValue:=Random(10);  if (TempValue > 5) then TempValue:=TempValue-10;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (20+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(20+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                       if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE NdKTERjCH MATERIaLi?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-20-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                         {GlobalModify.RaceMaterialModifiers[0].BPModif:=100;{}
                         GlobalModify.RaceMaterialModifiers[0].ExpModif:=40;
                         GlobalModify.RaceMaterialModifiers[0].PLModif:=25;
                         {GlobalModify.RaceMaterialModifiers[0].EEModif:=100;{}
                       end;
                    end;
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='21';
                    Game:=21; Campaign:=1; EnemyRaces:=[3,4];
                  end else begin
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (860+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(860+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE O TERcNU?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-860-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.UnknownTerrain:=1;
                      end;
                    end;
                    MaxMissionCoreUnits:=2; { max. pocet jednotek jadra do mise }
                    MissionNameString:='23';
                    Game:=23; Campaign:=1;{} EnemyRaces:=[3,4];
                  end;
              end else begin
                  Return:=False;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       21: begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI*2;
                  POINTS:=POINTS+POI*1.5;
                  MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
              end else begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
              end;
              GlobalInfoStr[0]:='   ABYCHOM UPEVNILI SVOJE POZICE, MUSeME VYBUDOVAT NdKOLIK NOVjCH ZaKLADEN.';
              GlobalInfoStr[1]:='POSeLaME VaS DO OBLASTI, VE KTERc ObEKaVaME NEJVdTge PROBLcMY.';
              MaxUsedGlobalInfo:=1;
              Mission1InfoStr[0]:='BUDOVaNe NOVc ZaKLADNY';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                 MissionNameString:='22';
                 Game:=22; Campaign:=1; EnemyRaces:=[3];
              end else begin
                 {MissionNameString:='1';
                 Game:=1; Campaign:=1;{} EnemyRaces:=[5];
                 {Error(0,'Chybny vyber mise - SelectMission, case21'); {}
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       22: begin
              if (Victory = 1) then begin
                 GlobalMOdify.FriendlySpecialUnitsPresent:=True;
                 GlobalInfoStr[0]:='   DeKY VAge ODVAZE PfI OBRANd ZaKLADNY JSME MdLI DOSTATEK bASU NA PfePRAVU';
                 GlobalInfoStr[1]:='OBRANY. NAgE VjCHOZe POZICE V TcTO BITVd JE ZCELA JISTd LEPge NEk POZICE';
                 GlobalInfoStr[2]:='ROBOTi. PfI NAgEM POSTUPU NaS ZASTAVIL PaS HOR. BOJ O STRATEGICKj PRiSMYK';
                 GlobalInfoStr[3]:='UKakE, ZDA UDRkeME INICIATIVU NEBO DaME ROBOTiM bAS, ABY ZNOVU NABRALI DECH.';
                 GlobalInfoStr[4]:='   ITALSKa VLaDA NaS POkADALA, ZDA BYCHOM Je NEPOSKYTLI VOJaKY PRO OCHRANU';
                 GlobalInfoStr[5]:='DiLEkITcHO SVdDKA. MOHL BY VNcST SVdTLO DO ZATeM ZaHADNcHO PROPOJENe ROBOTi';
                 GlobalInfoStr[6]:='S LIDSKjMI ZRaDCI. TATO OPERACE BUDE KRaTKa, TAKkE CHCETE-LI, MikETE SE Je';
                 GlobalInfoStr[7]:='ZhbASTNIT JEgTd PfED ZAPObETeM BOJi O PRiSMYK.';
                 GlobalInfoStr[9]:='   ZPRaVA TAJNc SLUkBY:';
                 GlobalInfoStr[10]:='  ZPRaVY NAgICH PRiZKUMNeKi NAZNAbUJe, kE NEPfaTELc V NEJBLIkge DOBd NASADe';
                 GlobalInfoStr[11]:='ZDOKONALENj TYP "ROBOT" A "gKORPION". OD PiVODNeCH STROJi SE LIge LEPgeMI';
                 GlobalInfoStr[12]:='hTObNjMI PARAMETRY. NAVeC LZE bEKAT NASAZENe NOVc NEPfaTELSKc TECHNIKY.';
                 GlobalInfoStr[13]:='  PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, ROBOTI ZDOKONALILI';
                 GlobalInfoStr[14]:='SViJ SYSTcM feDeCeCH CENTER. TO SE PRAVDdPODOBNd PROJEVe ZLEPgENOU hTObNOU';
                 GlobalInfoStr[15]:='A ZEJMcNA OBRANNOU SILOU ROBOTIZOVANjCH VOJSK.';
                 MaxUsedGlobalInfo:=15;
              end else begin
                 GlobalInfoStr[0]:='   PfI NAgEM POSTUPU NaS ZASTAVIL PaS HOR. BOJ O STRATEGICKj PRiSMYK UKakE,';
                 GlobalInfoStr[1]:='ZDA UDRkeME INICIATIVU NEBO DaME ROBOTiM bAS, ABY ZNOVU NABRALI DECH.';
                 GlobalInfoStr[2]:='   ITALSKa VLaDA NaS POkADALA, ZDA BYCHOM Je NEPOSKYTLI VOJaKY PRO OCHRANU';
                 GlobalInfoStr[3]:='DiLEkITcHO SVdDKA. MOHL BY VNcST SVdTLO DO ZATeM ZaHADNcHO PROPOJENe ROBOTi';
                 GlobalInfoStr[4]:='S LIDSKjMI ZRaDCI. TATO OPERACE BUDE KRaTKa, TAKkE CHCETE-LI, MikETE SE Je';
                 GlobalInfoStr[5]:='ZhbASTNIT JEgTd PfED ZAPObETeM BOJi O PRiSMYK.';
                 GlobalInfoStr[7]:='   ZPRaVA TAJNc SLUkBY:';
                 GlobalInfoStr[8]:='  ZPRaVY NAgICH PRiZKUMNeKi NAZNAbUJe, kE NEPfaTELc V NEJBLIkge DOBd NASADe';
                 GlobalInfoStr[9]:='ZDOKONALENj TYP "ROBOT" A "gKORPION". OD PiVODNeCH STROJi SE LIge LEPgeMI';
                 GlobalInfoStr[10]:='hTObNjMI PARAMETRY. NAVeC LZE bEKAT NASAZENe NOVc NEPfaTELSKc TECHNIKY.';
                 GlobalInfoStr[11]:='  PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, ROBOTI ZDOKONALILI';
                 GlobalInfoStr[12]:='SViJ SYSTcM feDeCeCH CENTER. TO SE PRAVDdPODOBNd PROJEVe ZLEPgENOU hTObNOU';
                 GlobalInfoStr[13]:='A ZEJMcNA OBRANNOU SILOU ROBOTIZOVANjCH VOJSK.';
                 MaxUsedGlobalInfo:=13;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              Mission1InfoStr[0]:='BOJ O STRATEGICKj PRiSMYK';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='DOPRAVA SVdDKA K HELIKOPTcfE';{}
              MaxUsedMission2Info:=0;
              if (DrawMissionSelect = 1) then begin
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (450+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(450+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-450-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.FriendlySpecialUnitsPresent:=True;
                   end;
                end;
                {X}
                MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
                MissionNameString:='24';
                Game:=24; Campaign:=1; EnemyRaces:=[3,4];
              end else begin
                {X}
                TempValue:=Random(50);  if (TempValue > 25) then TempValue:=TempValue-50;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (460+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(460+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE SI ZAJISTIT OSLABENe NEPfaTEL?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-460-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[3].BPModif:=-20;
                     GlobalModify.RaceMaterialModifiers[3].ExpModif:=-20;
                     GlobalModify.RaceMaterialModifiers[3].PLModif:=-20;
                     GlobalModify.RaceMaterialModifiers[3].EEModif:=-20;
                   end;
                end;
                {X}
                MaxMissionCoreUnits:=2; { max. pocet jednotek jadra do mise }
                MissionNameString:='60';
                Game:=60; Campaign:=1; EnemyRaces:=[3,4,5];
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       23: begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  GlobalInfoStr[0]:='   PfI NAgEM POSTUPU NaS ZASTAVIL PaS HOR. BOJ O STRATEGICKj PRiSMYK UKakE,';
                  GlobalInfoStr[1]:='ZDA UDRkeME INICIATIVU NEBO DaME ROBOTiM bAS, ABY ZNOVU NABRALI DECH.';
                  GlobalInfoStr[2]:='   ITALSKa VLaDA NaS POkADALA, ZDA BYCHOM Je NEPOSKYTLI VOJaKY PRO OCHRANU';
                  GlobalInfoStr[3]:='DiLEkITcHO SVdDKA. MOHL BY VNcST SVdTLO DO ZATeM ZaHADNcHO PROPOJENe ROBOTi';
                  GlobalInfoStr[4]:='S LIDSKjMI ZRaDCI. TATO OPERACE BUDE KRaTKa, TAKkE CHCETE-LI, MikETE SE Je';
                  GlobalInfoStr[5]:='ZhbASTNIT JEgTd PfED ZAPObETeM BOJi O PRiSMYK.';
                  GlobalInfoStr[7]:='   ZPRaVA TAJNc SLUkBY:';
                  GlobalInfoStr[8]:='  ZPRaVY NAgICH PRiZKUMNeKi NAZNAbUJe, kE NEPfaTELc V NEJBLIkge DOBd NASADe';
                  GlobalInfoStr[9]:='ZDOKONALENj TYP "ROBOT" A "gKORPION". OD PiVODNeCH STROJi SE LIge LEPgeMI';
                  GlobalInfoStr[10]:='hTObNjMI PARAMETRY. NAVeC LZE bEKAT NASAZENe NOVc NEPfaTELSKc TECHNIKY.';
                  GlobalInfoStr[11]:='   PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, ROBOTI ZDOKONALILI';
                  GlobalInfoStr[12]:='SViJ SYSTcM feDeCeCH CENTER. TO SE PRAVDdPODOBNd PROJEVe ZLEPgENOU hTObNOU';
                  GlobalInfoStr[13]:='A ZEJMcNA OBRANNOU SILOU ROBOTIZOVANjCH VOJSK.';
                  MaxUsedGlobalInfo:=13;
              end else begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  GlobalInfoStr[0]:='   ZaKLADNU JSME NEBYLI SCHOPNI UDRkET. TA PADLA DO RUKOU ZRaDCOVSKjM ODDeLiM';
                  GlobalInfoStr[1]:='I S DRTIVOU VdTgINOU TAMNeHO VYBAVENe. ZCELA JISTd HO BRZY POUkIJe PROTI NaM.';
                  GlobalInfoStr[2]:='   PfI NAgEM POSTUPU NaS ZASTAVIL PaS HOR. BOJ O STRATEGICKj PRiSMYK UKakE,';
                  GlobalInfoStr[3]:='ZDA UDRkeME INICIATIVU NEBO DaME ROBOTiM bAS, ABY ZNOVU NABRALI DECH.';
                  GlobalInfoStr[4]:='   ITALSKa VLaDA NaS POkADALA, ZDA BYCHOM Je NEPOSKYTLI VOJaKY PRO OCHRANU';
                  GlobalInfoStr[5]:='DiLEkITcHO SVdDKA. MOHL BY VNcST SVdTLO DO ZATeM ZaHADNcHO PROPOJENe ROBOTi';
                  GlobalInfoStr[6]:='S LIDSKjMI ZRaDCI. TATO OPERACE BUDE KRaTKa, TAKkE CHCETE-LI, MikETE SE Je';
                  GlobalInfoStr[7]:='ZhbASTNIT JEgTd PfED ZAPObETeM BOJi O PRiSMYK.';
                  GlobalInfoStr[9]:='   ZPRaVA TAJNc SLUkBY:';
                  GlobalInfoStr[10]:='  ZPRaVY NAgICH PRiZKUMNeKi NAZNAbUJe, kE NEPfaTELc V NEJBLIkge DOBd NASADe';
                  GlobalInfoStr[11]:='ZDOKONALENj TYP "ROBOT" A "gKORPION". OD PiVODNeCH STROJi SE LIge LEPgeMI';
                  GlobalInfoStr[12]:='hTObNjMI PARAMETRY. NAVeC LZE bEKAT NASAZENe NOVc NEPfaTELSKc TECHNIKY.';
                  GlobalInfoStr[13]:='   PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, ROBOTI ZDOKONALILI';
                  GlobalInfoStr[14]:='SViJ SYSTcM feDeCeCH CENTER. TO SE PRAVDdPODOBNd PROJEVe ZLEPgENOU hTObNOU';
                  GlobalInfoStr[15]:='A ZEJMcNA OBRANNOU SILOU ROBOTIZOVANjCH VOJSK.';
                  MaxUsedGlobalInfo:=15;
                  GlobalModify.EnemySpecialReinforcementPresent:=True;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              Mission1InfoStr[0]:='BOJ O STRATEGICKj PRiSMYK';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='DOPRAVA SVdDKA K HELIKOPTcfE';{}
              MaxUsedMission2Info:=0;
              if (DrawMissionSelect = 1) then begin
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (450+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(450+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-450-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.FriendlySpecialUnitsPresent:=True;
                   end;
                end;
                {X}
                MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
                MissionNameString:='24';
                Game:=24; Campaign:=1; EnemyRaces:=[3,4];
              end else begin
                {X}
                TempValue:=Random(50);  if (TempValue > 25) then TempValue:=TempValue-50;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (460+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(460+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE SI ZAJISTIT OSLABENe NEPfaTEL?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-460-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[3].BPModif:=-20;
                     GlobalModify.RaceMaterialModifiers[3].ExpModif:=-20;
                     GlobalModify.RaceMaterialModifiers[3].PLModif:=-20;
                     GlobalModify.RaceMaterialModifiers[3].EEModif:=-20;
                   end;
                end;
                {X}
                MaxMissionCoreUnits:=2; { max. pocet jednotek jadra do mise }
                MissionNameString:='60';
                Game:=60; Campaign:=1; EnemyRaces:=[3,4,5];
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
    else
       Return:=SelectMission2;
    end;
  end;

  if ((VICTORYPOINTS < VPointsPerMission) or
      (POINTS < PointsPerMission)) then begin
    Return:=False;
  end else begin
    if (Game > 1) then begin
      VICTORYPOINTS:=VICTORYPOINTS-VPointsPerMission;
      POINTS:=POINTS-PointsPerMission;
    end;
  end;
  SelectMission:=Return;
end;

{ ***** }
function SelectMission2:Boolean;
{
  provede volbu mise; vraci True pri porazce
}
var PomStr, Str1, Str2, Str3:String;
    Return:Boolean;
    Pom:Byte;
    TempValue:Integer;
    XSize, YSize:Word;
begin
  Return:=True;
  if (Campaign<=2) then begin
     case (Game) of
       24: begin
              if (Victory = 0) then begin
                 GlobalModify.RaceMaterialModifiers[3].BPModif:=20;
                 GlobalModify.RaceMaterialModifiers[3].ExpModif:=20;
                 GlobalModify.RaceMaterialModifiers[3].PLModif:=20;
                 GlobalModify.RaceMaterialModifiers[3].EEModif:=20;
              end else if (Victory = -1) then begin
                 GlobalModify.RaceMaterialModifiers[3].BPModif:=50;
                 GlobalModify.RaceMaterialModifiers[3].ExpModif:=50;
                 GlobalModify.RaceMaterialModifiers[3].PLModif:=50;
                 GlobalModify.RaceMaterialModifiers[3].EEModif:=50;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              GlobalInfoStr[0]:='   V SOUbASTNc CHVeLI MaME MOkNOST ZAhTObIT NA DVOU FRONTaCH. PODLE VRCHNeHO';
              GlobalInfoStr[1]:='VELITELE BYCHOM MdLI VYSLAT VjSADKOVc SKUPINY NA POMOC OBLEkENc VESNICI. OSUD';
              GlobalInfoStr[2]:='ZDEJgeHO OBYVATELSTVA ZaVISe POUZE NA NaS.';
              GlobalInfoStr[3]:='   VE STEJNc CHVeLI NaS POkaDALY SKUPINY ODBOJE O POMOC. hTObe NA SILNOU';
              GlobalInfoStr[4]:='ZaKLADNU ROBOTi. PODLE VgEHO BUDOU BEZ NAge POMOCI ZTRACENI.';
              GlobalInfoStr[6]:='   ZPRaVA VOJENSKc ZPRAVODAJSKc SLUkBY:';
              GlobalInfoStr[7]:='  V NEJBLIkgeCH HODINaCH ObEKaVaME NASAZENe NOVc NEPfaTELSKc TECHNIKY. NOVj';
              GlobalInfoStr[8]:='TYP SE JMENUJE "BOJOVj MUTANT". PODLE TOHO, CO JSME SE DOZVdDdLI, JDE O JEDEN';
              GlobalInfoStr[9]:='Z NEJZRiDNdJgeCH VYNaLEZi V HISTORII LIDSTVA. ZAJATCiM BYLY ODOPEROVaNY JISTc';
              GlobalInfoStr[10]:='kIVOTNd DiLEkITc PARTIE A BYLY ZAKOMPONOVaNY DO ZVLagTNeHO STROJE, PODOBNcHO';
              GlobalInfoStr[11]:='PAVOUKOVI. FAKTICKa hbINNOST "BOJOVcHO MUTANTA" NENe PfeLIg VYSOKa, fADA';
              GlobalInfoStr[12]:='OBVODi NENe ZATeM TECHNICKY DOfEgENA. AVgAK POUHj POHLED NA TOTO "STVOfENe"';
              GlobalInfoStr[13]:='Ma PfeMO DEVASTUJeCe hbINEK NA LIDSKOU MORaLKU.';
              MaxUsedGlobalInfo:=13;
              Mission1InfoStr[0]:='VjSADEK U OBLEkENc VESNICE';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='SPOLUPRaCE S ODBOJEM';{}
              MaxUsedMission2Info:=0;
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=4; { max. pocet jednotek jadra do mise }
                MissionNameString:='27';
                Game:=27; Campaign:=1; EnemyRaces:=[3];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (765+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(765+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI POSeLIT ODBOJ?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-765-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[1].BPModif:=60;
                     GlobalModify.RaceMaterialModifiers[1].ExpModif:=60;
                     GlobalModify.RaceMaterialModifiers[1].PLModif:=60;
                     GlobalModify.RaceMaterialModifiers[1].EEModif:=60;
                   end;
                end;
              end else begin
                MaxMissionCoreUnits:=9; { max. pocet jednotek jadra do mise }
                MissionNameString:='25';
                Game:=25; Campaign:=1;{} EnemyRaces:=[3];
                if (WideDialogBox('MaTE MOkNOST KOUPIT SI LEPge POZICI PRO SEBE NEBO PRO SPOJENCE.',
                              'POSeLeTE SEBE?','', _YES_NO) = YES) then begin
                { posileni sebe }
                  TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                  TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                  if ((POINTS >= (765+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                     Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                     Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                     Str(765+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                     if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI LEPge MATERIaLNe POZICI?',
                                       Str3,Str2,_YES_NO)=YES)
                     then begin
                       POINTS:=POINTS-765-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                       GlobalModify.RaceMaterialModifiers[0].BPModif:=100;
                       GlobalModify.RaceMaterialModifiers[0].ExpModif:=100;
                       GlobalModify.RaceMaterialModifiers[0].PLModif:=100;
                       GlobalModify.RaceMaterialModifiers[0].EEModif:=100;
                     end;
                  end;
                end else begin
                { posileni nepratel }
                  TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                  TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                  if ((POINTS >= (565+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                     Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                     Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                     Str(565+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                     if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI POSeLIT ODBOJ?',
                                       Str3,Str2,_YES_NO)=YES)
                     then begin
                       POINTS:=POINTS-565-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                       GlobalModify.RaceMaterialModifiers[1].BPModif:=100;
                       GlobalModify.RaceMaterialModifiers[1].ExpModif:=100;
                       GlobalModify.RaceMaterialModifiers[1].PLModif:=100;
                       GlobalModify.RaceMaterialModifiers[1].EEModif:=100;
                     end;
                  end;
                end;
              end;
              if (Return) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       25: begin
              if (Victory = 1) then begin
                 GlobalModify.RaceInitLevelModifier[1]:=3;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   KONEbNd SE DOSTaVaME K VjSADKU NA PODPORU CIVILNeHO OBYVATELSTVA. POKUD';
              GlobalInfoStr[1]:='SI NEPOSPegeME, BUDE POZDd. VZHLEDEM K PRODLEVd, ZPiSOBENc POMOCe ODBOJI,';
              GlobalInfoStr[2]:='MUSeME ObEKaVAT TUkge ODPOR.';
              MaxUsedGlobalInfo:=2;
              Mission1InfoStr[0]:='VjSADEK NA PODPORU OBLEkENc VESNICE';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='26';
                Game:=26; Campaign:=1; EnemyRaces:=[3];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (765+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(765+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI POSeLIT ODBOJ?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-765-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[1].BPModif:=45;
                     GlobalModify.RaceMaterialModifiers[1].ExpModif:=45;
                     GlobalModify.RaceMaterialModifiers[1].PLModif:=45;
                     GlobalModify.RaceMaterialModifiers[1].EEModif:=45;
                   end;
                end;
              end else begin
                {Error(0,'Chybny vyber mise - SelectMission, case25'); {}
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       26,27: begin
              if (Victory < 1) then begin
                  Return:=False;
              end else begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  GlobalInfoStr[0]:='   NAgE PRiZKUMNc LETOUNY OBJEVILY ODLEHLOU ZaKLADNU VZBOUfENjCH ROBOTi.';
                  GlobalInfoStr[1]:='CHRaNdNI PaSEM PEVNOSTe CeTe SE ROBOTI BEZPEbNe. JE ZDE JEDINEbNa MOkNOST';
                  GlobalInfoStr[2]:='PfEKVAPIT JE. TO JE hKOL PRO NAgE SPECIaLNe JEDNOTKY.';
                  GlobalInfoStr[3]:='   PROTOkE SE STABILIZOVALA FRONTA, NASTAL TAKc VHODNj bAS NA PROTIhTOK.';
                  GlobalInfoStr[4]:='OPdT MaTE K DISPOZICI VOLBU DALgeHO POSTUPU.';
                  GlobalInfoStr[6]:='   ZPRaVA TAJNc SLUkBY:';
                  GlobalInfoStr[7]:='  PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, NASADe NAgI NEPfaTELc';
                  GlobalInfoStr[8]:='V NaSLEDUJeCeCH BOJeCH ZDOKONALENj TYP "MLRS". PROVEDENc KONSTRUKbNe ZMdNY';
                  GlobalInfoStr[9]:='UMOkNILY VYgge RYCHLOSTe STfELBY.';
                  GlobalInfoStr[10]:='   ZPRaVA VOJENSKc ZPRAVODAJSKc SLUkBY:';
                  GlobalInfoStr[11]:='  V BRZKc DOBd ObEKaVaME NASAZENe NOVc NEPfaTELSKc TECHNIKY. BOHUkEL, NIC';
                  GlobalInfoStr[12]:='BLIkgeHO ZATeM NEVeME, POUZE SE Ma JEDNAT O DOSUD NEVIDdNOU LETECKOU';
                  GlobalInfoStr[13]:='JEDNOTKU.';
                  {X}
                  MaxUsedGlobalInfo:=13;
                  Mission1InfoStr[0]:='SPECIaLNe OPERACE PROTI NEPfaTELSKc ZaKLADNd (NEPOVINNa)';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='VELKj PROTIhTOK';{}
                  MaxUsedMission2Info:=0;
                  if (DrawMissionSelect = 1) then begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='28';
                    Game:=28; Campaign:=1; EnemyRaces:=[3];
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (365+TempValue)) and (VICTORYPOINTS >= 2)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(365+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 2';
                       if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge NA hKOR NEPfaTEL?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-365-TempValue; VICTORYPOINTS:=VICTORYPOINTS-2;
                         GlobalModify.RaceMaterialModifiers[0].PLModif:=40;
                         GlobalModify.RaceMaterialModifiers[3].BPModif:=-20;
                         GlobalModify.FriendlySpecialUnitsPresent:=True;
                       end;
                    end;
                  end else begin
                    MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
                    MissionNameString:='29';
                    Game:=29; Campaign:=1; EnemyRaces:=[3,4];
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (700+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(700+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-700-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.AllyFog:=1;
                      end;
                    end;
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (260+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(260+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                       if (WideDialogBox('CHCETE V NaSLEDUJeCe BITVd OSLABIT NEPfaTELE?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-260-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                         GlobalModify.RaceMaterialModifiers[4].BPModif:=-10;
                         GlobalModify.RaceMaterialModifiers[3].ExpModif:=-20;
                       end;
                    end;
                  end;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       28: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   PROTOkE SE STABILIZOVALA SITUACE, NASTAL VHODNj bAS NA PROTIhTOK. MaME';
              GlobalInfoStr[1]:='JEDINEbNOU gANCI POSUNOUT FRONTOVOU LINII O NdKOLIK DESeTEK KILOMETRi VPfED.';
              GlobalInfoStr[3]:='   ZPRaVA TAJNc SLUkBY:';
              GlobalInfoStr[4]:='  PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, NASADe NAgI NEPfaTELc';
              GlobalInfoStr[5]:='V NaSLEDUJeCeCH BOJeCH ZDOKONALENj TYP "MLRS". PROVEDENc KONSTRUKbNe ZMdNY';
              GlobalInfoStr[6]:='SE hDAJNd PROJEVUJe VYgge RYCHLOSTe STfELBY.';
              GlobalInfoStr[8]:='   ZPRaVA VOJENSKc ZPRAVODAJSKc SLUkBY:';
              GlobalInfoStr[9]:='  V NEJBLIkgeCH HODINaCH DOJDE K NASAZENe NOVc NEPfaTELSKc TECHNIKY. JAK';
              GlobalInfoStr[10]:='JSME VaS JIk baSTEbNd INFORMOVALI, PiJDE O LETECKOU JEDNOTKU UNIKaTNe';
              GlobalInfoStr[11]:=' KONSTRUKCE.';
              MaxUsedGlobalInfo:=11;
              Mission1InfoStr[0]:='VELKj PROTIhTOK';{}
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
                MissionNameString:='29';
                Game:=29; Campaign:=1; EnemyRaces:=[3,4];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (700+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(700+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-700-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.AllyFog:=1;
                  end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (260+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(260+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe BITVd OSLABIT NEPfaTELE?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-260-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceMaterialModifiers[4].BPModif:=-10;
                     GlobalModify.RaceMaterialModifiers[3].ExpModif:=-20;
                   end;
                end;
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{}
                {Error(0,'Chybny vyber mise - SelectMission, case28'); {}
              end;
              if (Victory = 1) then begin
                OfferSpecialCoreUnit(14,1,'BLACK DEATH');
              end else begin
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       29: begin
              if (Victory = 1) then begin
                GlobalModify.FriendlySpecialUnitsPresent:=True;
              end else begin
                if (Victory = 0) then begin
                   GlobalModify.RaceMaterialModifiers[0].BPModif:=-5;
                   GlobalModify.RaceMaterialModifiers[0].ExpModif:=-5;
                   GlobalModify.RaceMaterialModifiers[0].PLModif:=-5;
                   GlobalModify.RaceMaterialModifiers[0].EEModif:=-5;
                end else begin
                   GlobalModify.RaceMaterialModifiers[0].BPModif:=-10;
                   GlobalModify.RaceMaterialModifiers[0].ExpModif:=-10;
                   GlobalModify.RaceMaterialModifiers[0].PLModif:=-10;
                   GlobalModify.RaceMaterialModifiers[0].EEModif:=-10;
                end;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              GlobalInfoStr[0]:='   NYNe SE NAgE SeLY BUDOU ANGAkOVAT V OPERACI S KRYCeM NaZVEM "PARASTORM".';
              GlobalInfoStr[1]:='PRVNeM hKOLEM JE ZaCHRANA DiLEkITcHO AGENTA.';
              GlobalInfoStr[3]:='   ZPRaVA TAJNc SLUkBY:';
              GlobalInfoStr[4]:='  PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, ROBOTI ZDOKONALILI';
              GlobalInfoStr[5]:='SViJ SYSTcM feDeCeCH CENTER. TO SE PRAVDdPODOBNd PROJEVe ZLEPgENOU hTObNOU';
              GlobalInfoStr[6]:='A ZEJMcNA OBRANNOU SILOU ROBOTIZOVANjCH VOJSK.';
              GlobalInfoStr[8]:='   ZPRaVA VOJENSKc ZPRAVODAJSKc SLUkBY:';
              GlobalInfoStr[9]:='  V NEJBLIkgeCH HODINaCH ObEKaVaME NASAZENe NOVc NEPfaTELSKc TECHNIKY.';
              GlobalInfoStr[10]:='ROBOTiM SE VE SPOLUPRaCI S VdDCI UNIE PODAfILO ZDOKONALIT NECHVALNd PROSLULcHO';
              GlobalInfoStr[11]:='"MECHVARRIORA". POKUD INFORMACE NELkOU, STOJe PROTI NaM NEJLEPge BOJOVj';
              GlobalInfoStr[12]:='STROJ, JAKj KDY TATO ZEMd SPATfILA.';
              MaxUsedGlobalInfo:=12;
              Mission1InfoStr[0]:='DOPRAVA AGENTA DO BEZPEbe';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                MissionNameString:='61';
                Game:=61; Campaign:=1; EnemyRaces:=[3,5];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (500+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.FriendlySpecialUnitsPresent:=True;
                   end;
                end;
                {X}
                TempValue:=Random(10);  if (TempValue > 5) then TempValue:=TempValue-10;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (150+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(150+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LcPE VYCVIbENc VOJaKY?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-150-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceInitLevelModifier[0]:=1;
                   end;
                end;
              end else begin
                {Error(0,'Chybny vyber mise - SelectMission, case29'); {}
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              WideDialogBoxX(' ZPRaVA Z VjZKUMNcHO CENTRA:                                              ',
                             'DeKY TECHNOLOGIeM, KTERc SE NAgEMU SPECIaLNeMU KOMANDU PODAfILO UKOfISTIT',
                             'NA ZaKLADNd ROBOTi, JSME PROVEDLI VYLEPgENe TYPi EUROFIGHTER A TERMINaTOR.',_YES);
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       61: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory = 1) then begin
                 GlobalInfoStr[0]:='   GRATULUJEME, DeKY VAgEMU hSPdCHU OPERACE ZDaRNd POKRAbUJE DALge FaZe.';
                 MaxUsedGlobalInfo:=0;
                 Mission1InfoStr[0]:='PARASTORM baST II';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                   MissionNameString:='62';
                   Game:=62; Campaign:=1;{} EnemyRaces:=[3,4];
                   {X}
                   TempValue:=Random(50);  if (TempValue > 25) then TempValue:=TempValue-50;
                   TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (220+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(220+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                      if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI OSLABIT NEPfaTELE?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-220-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                        GlobalModify.RaceMaterialModifiers[4].BPModif:=-50;
                        GlobalModify.RaceMaterialModifiers[4].ExpModif:=-50;
                        GlobalModify.RaceMaterialModifiers[4].PLModif:=-50;
                        GlobalModify.RaceMaterialModifiers[4].EEModif:=-50;
                      end;
                   end;
                   {X}
                 end else begin
                   {Error(0,'Chybny vyber mise - SelectMission, case61'); {}
                 end;
              end else begin
                 GlobalInfoStr[0]:='   BUHUkEL, DeKY NEhSPdCHU V POSLEDNe BITVd SKONbILA OPERACE "PARASTORM"';
                 GlobalInfoStr[1]:='DfeVE, NEk MOHLA PfEJeT DO DALge FaZE. gKODA.';
                 GlobalInfoStr[2]:='   V NaSLEDUJeCeCH DNECH NaS bEKa VELKc STfETNUTe S NEPfaTELI. ODBOJ SE';
                 GlobalInfoStr[3]:='ROZHODL NASADIT MAXIMaLNe SeLY, ABY NaM ULEHbIL SLOkITOU POZICI.';
                 MaxUsedGlobalInfo:=3;
                 Mission1InfoStr[0]:='VELKa BITVA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MaxMissionCoreUnits:=8; { max. pocet jednotek jadra do mise }
                   MissionNameString:='31';
                   Game:=31; Campaign:=1;{} EnemyRaces:=[3,4,5];
                   {X}
                   TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                   TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (1200+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(1200+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VjRAZNd SILNdJgeHO SPOJENCE?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1200-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.FriendlySpecialUnitsPresent:=True;
                      end;
                   end;
                   {X}
                   if (WideDialogBoxX('  PRaVd K VaM PfIgEL PLUKOVNeK HILL, ZaSTUPCE JEDNc Z VOJENSKjCH FRAKCe',
                                     'ODBOJE. VELITELI, OSLOVIL VaS, SYMPATIZUJEME SE SILAMI OSN, ALE NECeTeME',
                                     'SE DOSTATEbNd SILNe. POMOHLO BY, KDYBY JSTE NaM POSKYTLI FINANbNe POMOC.',
                                     _YES_NO)=YES) then begin
                   { nakup pomocne rasy }
                      TempValue:=Random(200);  if (TempValue > 100) then TempValue:=TempValue-200;
                      TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                      if ((POINTS >= (1500+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                         Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                         Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                         Str(1500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI PODPORU PLUKOVNeKA HILLA?',
                                           Str3,Str2,_YES_NO)=YES)
                         then begin
                           POINTS:=POINTS-1500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                           GlobalMOdify.RaceTypeModifiers[2]:=1;
                         end;
                      end;
                   end;
                   {X}
                 end else begin
                   {Error(0,'Chybny vyber mise - SelectMission, case61'); {}
                 end;
              end;

              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       62: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory = 1) then begin
                 GlobalInfoStr[0]:='   VjBORNd. PfIPRAVILI JSME SI DOBROU VjCHOZe POZICI PRO MASIVNe VjSADKOVOU';
                 GlobalInfoStr[1]:='OPERACI.';
                 MaxUsedGlobalInfo:=1;
                 Mission1InfoStr[0]:='PARASTORM baST III';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MaxMissionCoreUnits:=7; { max. pocet jednotek jadra do mise }
                   MissionNameString:='63';
                   Game:=63; Campaign:=1;{} EnemyRaces:=[3,4,5];
                   {X}
                   TempValue:=Random(200);  if (TempValue > 100) then TempValue:=TempValue-200;
                   TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (1480+TempValue)) and (VICTORYPOINTS >= 2)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(1480+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 2';
                      if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1480-TempValue; VICTORYPOINTS:=VICTORYPOINTS-2;
                        GlobalModify.FriendlySpecialUnitsPresent:=True;
                      end;
                   end;
                   {X}
                 end else begin
                   {Error(0,'Chybny vyber mise - SelectMission, case62'); {}
                 end;
              end else begin
                 GlobalInfoStr[0]:='   BUHUkEL, DeKY NEhSPdCHU V POSLEDNe BITVd SKONbILA OPERACE "PARASTORM"';
                 GlobalInfoStr[1]:='DfeVE, NEk MOHLA PfEJeT DO DALge FaZE. gKODA.';
                 GlobalInfoStr[2]:='   V NaSLEDUJeCeCH DNECH NaS bEKa VELKc STfETNUTe S NEPfaTELI. ODBOJ SE';
                 GlobalInfoStr[3]:='ROZHODL NASADIT MAXIMaLNe SeLY, ABY NaM ULEHbIL SLOkITOU POZICI.';
                 MaxUsedGlobalInfo:=3;
                 Mission1InfoStr[0]:='VELKa BITVA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MaxMissionCoreUnits:=8; { max. pocet jednotek jadra do mise }
                   MissionNameString:='31';
                   Game:=31; Campaign:=1;{} EnemyRaces:=[3,4,5];
                   {X}
                   TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                   TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (1200+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(1200+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VjRAZNd SILNdJgeHO SPOJENCE?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1200-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.FriendlySpecialUnitsPresent:=True;
                      end;
                   end;
                   {X}
                   if (WideDialogBoxX('  PRaVd K VaM PfIgEL PLUKOVNeK HILL, ZaSTUPCE JEDNc Z VOJENSKjCH FRAKCe',
                                     'ODBOJE. VELITELI, OSLOVIL VaS, SYMPATIZUJEME SE SILAMI OSN, ALE NECeTeME',
                                     'SE DOSTATEbNd SILNe. POMOHLO BY, KDYBY JSTE NaM POSKYTLI FINANbNe POMOC.',
                                     _YES_NO)=YES) then begin
                   { nakup pomocne rasy }
                      TempValue:=Random(200);  if (TempValue > 100) then TempValue:=TempValue-200;
                      TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                      if ((POINTS >= (1500+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                         Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                         Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                         Str(1500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                         if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI PODPORU PLUKOVNeKA HILLA?',
                                           Str3,Str2,_YES_NO)=YES)
                         then begin
                           POINTS:=POINTS-1500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                           GlobalMOdify.RaceTypeModifiers[2]:=1;
                         end;
                      end;
                   end;
                   {X}

                 end else begin
                   {Error(0,'Chybny vyber mise - SelectMission, case62'); {}
                 end;
              end;

              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       63: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory = 1) then begin
                 GlobalInfoStr[0]:='   BLeke SE ZaVdREbNa FaZE OPERACE "PARASTORM". ZVeTdZeME-LI I V NaSLEDUJeCe';
                 GlobalInfoStr[1]:='BITVd, ODPOR NEPfaTEL BUDE DEFINITIVNd ZLOMEN.';
                 MaxUsedGlobalInfo:=1;
                 Mission1InfoStr[0]:='PARASTORM baST IV';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MaxMissionCoreUnits:=9; { max. pocet jednotek jadra do mise }
                   MissionNameString:='64';
                   Game:=64; Campaign:=1;{} EnemyRaces:=[3,4,5];
                 end else begin
                   {Error(0,'Chybny vyber mise - SelectMission, case62'); {}
                 end;
              end else begin
                 GlobalInfoStr[0]:='   BUHUkEL, DeKY NEhSPdCHU V POSLEDNe BITVd SKONbILA OPERACE "PARASTORM"';
                 GlobalInfoStr[1]:='DfeVE, NEk MOHLA PfEJeT DO DALge FaZE. gKODA.';
                 GlobalInfoStr[2]:='   V NaSLEDUJeCeCH DNECH NaS bEKa VELKc STfETNUTe S NEPfaTELI. ODBOJ SE';
                 GlobalInfoStr[3]:='ROZHODL NASADIT MAXIMaLNe SeLY, ABY NaM ULEHbIL SLOkITOU POZICI.';
                 MaxUsedGlobalInfo:=3;
                 Mission1InfoStr[0]:='VELKa BITVA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MaxMissionCoreUnits:=8; { max. pocet jednotek jadra do mise }
                   MissionNameString:='31';
                   Game:=31; Campaign:=1;{} EnemyRaces:=[3,4,5];
                   {X}
                   TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                   TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (1200+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(1200+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VjRAZNd SILNdJgeHO SPOJENCE?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1200-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.FriendlySpecialUnitsPresent:=True;
                      end;
                   end;
                   {X}
                   if (WideDialogBoxX('  PRaVd K VaM PfIgEL PLUKOVNeK HILL, ZaSTUPCE JEDNc Z VOJENSKjCH FRAKCe',
                                     'ODBOJE. VELITELI, OSLOVIL VaS, SYMPATIZUJEME SE SILAMI OSN, ALE NECeTeME',
                                     'SE DOSTATEbNd SILNe. POMOHLO BY, KDYBY JSTE NaM POSKYTLI FINANbNe POMOC.',
                                     _YES_NO)=YES) then begin
                   { nakup pomocne rasy }
                      TempValue:=Random(200);  if (TempValue > 100) then TempValue:=TempValue-200;
                      TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                      if ((POINTS >= (1500+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                         Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                         Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                         Str(1500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                         if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI PODPORU PLUKOVNeKA HILLA?',
                                           Str3,Str2,_YES_NO)=YES)
                         then begin
                           POINTS:=POINTS-1500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                           GlobalMOdify.RaceTypeModifiers[2]:=1;
                         end;
                      end;
                   end;
                   {X}

                 end else begin
                   {Error(0,'Chybny vyber mise - SelectMission, case62'); {}
                 end;
              end;

              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       64: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory = 1) then begin
                 GlobalInfoStr[0]:='   DeKY VAgEMU TALENTU A SKVdLjM VELITELSKjM SCHOPNOSTEM SLAVe OSN DALge';
                 GlobalInfoStr[1]:='TRIUMF. JAK SE ZDa, POMALE ZeSKaVaME PfEVAHU NA BOJIgTI. bEKa NaS VgAK JEgTd';
                 GlobalInfoStr[2]:='MNOHO PRaCE, NEk DOCeLeME KONEbNcHO VeTdZTVe.';
                 GlobalInfoStr[3]:='   V NaSLEDUJeCeCH DNECH NaS bEKa VELKc STfETNUTe S NEPfaTELI. ODBOJ SE';
                 GlobalInfoStr[4]:='ROZHODL NASADIT MAXIMaLNe SeLY, ABY NaM ULEHbIL SLOkITOU POZICI.';
                 MaxUsedGlobalInfo:=4;
                 Mission1InfoStr[0]:='VELKa BITVA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
              end else begin
                 GlobalInfoStr[0]:='   BUHUkEL, DeKY NEhSPdCHU V POSLEDNe BITVd SKONbILA OPERACE "PARASTORM"';
                 GlobalInfoStr[1]:='DfeVE, NEk MOHLA PfINcST UkITEK PRO Nag DALge POSTUP. gKODA.';
                 GlobalInfoStr[2]:='   V NaSLEDUJeCeCH DNECH NaS bEKa VELKc STfETNUTe S NEPfaTELI. ODBOJ SE';
                 GlobalInfoStr[3]:='ROZHODL NASADIT MAXIMaLNe SeLY, ABY NaM ULEHbIL SLOkITOU POZICI.';
                 MaxUsedGlobalInfo:=3;
                 Mission1InfoStr[0]:='VELKa BITVA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;
              end;
              {X}
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=8; { max. pocet jednotek jadra do mise }
                MissionNameString:='31';
                Game:=31; Campaign:=1;{} EnemyRaces:=[3,4,5];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (1200+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(1200+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VjRAZNd SILNdJgeHO SPOJENCE?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1200-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalModify.FriendlySpecialUnitsPresent:=True;
                      end;
                   end;
                {X}
                if (WideDialogBoxX('  PRaVd K VaM PfIgEL PLUKOVNeK HILL, ZaSTUPCE JEDNc Z VOJENSKjCH FRAKCe',
                                  'ODBOJE. VELITELI, OSLOVIL VaS, SYMPATIZUJEME SE SILAMI OSN, ALE NECeTeME',
                                  'SE DOSTATEbNd SILNe. POMOHLO BY, KDYBY JSTE NaM POSKYTLI FINANbNe POMOC.',
                                  _YES_NO)=YES) then begin
                { nakup pomocne rasy }
                   TempValue:=Random(200);  if (TempValue > 100) then TempValue:=TempValue-200;
                   TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                   if ((POINTS >= (1500+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                      Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                      Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                      Str(1500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                      if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI PODPORU PLUKOVNeKA HILLA?',
                                        Str3,Str2,_YES_NO)=YES)
                      then begin
                        POINTS:=POINTS-1500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                        GlobalMOdify.RaceTypeModifiers[2]:=1;
                      end;
                   end;
                end;
                {X}
              end else begin
                {Error(0,'Chybny vyber mise - SelectMission, case64'); {}
              end;

              if (Victory = 1) then begin
                OfferSpecialCoreUnit(28,3,'POSEL SMRTI');
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       31: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              GLobalModify.EnemySpecialReinforcementPresent:=True;
              MaxMissionCoreUnits:=7; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   JAK SE ZDa, V TdCHTO CHVeLeCH SE ROZHODUJE O OSUDU CELc VaLKY. OBd STRANY';
              GlobalInfoStr[1]:='VRHAJe DO BOJi SVc NEJLEPge JEDNOTKY V MAXIMaLNeCH PObTECH. PORAkENj Uk ZfEJMd';
              GlobalInfoStr[2]:='NEBUDE MeT DOST SIL, ABY NAHRADIL VZNIKLc ZTRaTY.';
              GlobalInfoStr[4]:='   ZPRaVA TAJNc SLUkBY:';
              GlobalInfoStr[5]:='  ZPRaVY NAgICH PRiZKUMNeKi NAZNAbUJe, kE NEPfaTELc V NEJBLIkge DOBd NASADe';
              GlobalInfoStr[6]:='VYLEPgENj TYP "A2M3 HROCH". OD PiVODNeHO TYPU SE LIge NAMONTOVANjM KANONEM';
              GlobalInfoStr[7]:='S PODSTATNd VYgge RYCHLOSTe STfELBY.';
              MaxUsedGlobalInfo:=7;
              Mission1InfoStr[0]:='   VELKj hTOK OSN A SPOJENCi';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='32';
                Game:=32; Campaign:=1; EnemyRaces:=[3,4];
                {X}
                TempValue:=Random(50);  if (TempValue > 25) then TempValue:=TempValue-50;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (280+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(280+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE LcPE VYCVIbIT VOJaKY ODBOJE PRO NaSLEDUJeCe MISI?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-280-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceInitLevelModifier[1]:=2;
                   end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (650+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(650+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI OSLABIT NEPfaTELE?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-650-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GLobalModify.EnemySpecialReinforcementPresent:=False;
                   end;
                end;
                {X}
                TempValue:=Random(50);  if (TempValue > 25) then TempValue:=TempValue-50;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (440+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(440+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE NdKTERjCH MATERIaLi?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-440-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[0].BPModif:=50;
                     GlobalModify.RaceMaterialModifiers[0].ExpModif:=0;
                     GlobalModify.RaceMaterialModifiers[0].PLModif:=0;
                     GlobalModify.RaceMaterialModifiers[0].EEModif:=0;
                   end;
                end;
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1; EnemyRaces:=[3,4];{}
                {Error(0,'Chybny vyber mise - SelectMission, case31'); {}
              end;

              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       32: begin
              if (Victory < 1) then begin
                  Return:=False;
              end else begin
                 VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                 POINTS:=POINTS+POI;
                 MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
                 GlobalInfoStr[0]:='   Nag GENERaLNe gTaB JIk DLOUHO PaTRa PO PfebINd hNIKU TAJNjCH INFORMACe.';
                 GlobalInfoStr[1]:='NdKOLIKRaT SE STALO, kE PfeSNd TAJNa OPERACE SKONbILA NEhSPdCHEM, PROTOkE';
                 GlobalInfoStr[2]:='SE NEPfaTELc NAPROSTO NEObEKaVANd OBJEVILI NA NEJMcNd VHODNcM MeSTd. NYNe';
                 GlobalInfoStr[3]:='SE ZaHADA OBJASNILA - JEDEN Z NAgICH GENERaLi ZRADIL A PfEDaVAL PLaNY';
                 GlobalInfoStr[4]:='ROBOTiM A KOLABORANTiM. PRaVd JE NA hTdKU. MUSeTE HO ZLIKVIDOVAT.';
                 MaxUsedGlobalInfo:=4;
                 Mission1InfoStr[0]:='   LIKVIDACE ZRaDCOVSKcHO GENERaLA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';{}
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MissionNameString:='54';
                   Game:=54; Campaign:=1; EnemyRaces:=[5];
                 end else begin
                   {MissionNameString:='1';
                   Game:=1; Campaign:=1; EnemyRaces:=[5]; {}
                   {Error(0,'Chybny vyber mise - SelectMission, case32'); {}
                 end;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       33: begin
              if (Victory = 1) then begin
                VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                POINTS:=POINTS+POI;
                GlobalModify.FriendlySpecialUnitsPresent:=True;
                GlobalInfoStr[0]:='   PROJEKT "METHEOR" SE CHjLe KE KONCI. MaME DVd MOkNOSTI DALgeHO POSTUPU:';
                GlobalInfoStr[1]:='"METHEOR 1)" - LIKVIDACE POSLEDNeHO DiLEkITcHO feDeCeHO CENTRA ROBOTi.';
                GlobalInfoStr[2]:='               VjSLEDKEM BUDE ZNAbNc OCHROMENe ROBOTIZOVANjCH VOJSK.';
                GlobalInfoStr[3]:='"METHEOR 2)" - ZNIbENe POLOOPUgTdNc VOJENSKc STANICE, KTEROU ROBOTI ';
                GlobalInfoStr[4]:='               POUkeVAJe K ZESILOVaNe SIGNaLU MEZI DVdMI IZOLOVANjMI';
                GlobalInfoStr[5]:='               OBLASTMI. TAK ODPOR ROBOTi ROZTfegTeME.';
                MaxUsedGlobalInfo:=5;
              end else begin
                VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                POINTS:=POINTS+POI;
                GlobalInfoStr[0]:='   NEhSPdCH V TcTO MISI JE PRO NaS FINANbNd NEPfeJEMNj. PROJEKT "METHEOR"';
                GlobalInfoStr[1]:='VgAK POKRAbUJE DaLE. NYNe MaME DVd MOkNOSTI DALgeHO POSTUPU:';
                GlobalInfoStr[2]:='"METHEOR 1)" - LIKVIDACE POSLEDNeHO DiLEkITcHO feDeCeHO CENTRA ROBOTi.';
                GlobalInfoStr[3]:='               VjSLEDKEM BUDE OCHROMENe ROBOTIZOVANjCH VOJSK.';
                GlobalInfoStr[4]:='"METHEOR 2)" - ZNIbENe POLOOPUgTdNc VOJENSKc STANICE, KTEROU ROBOTI ';
                GlobalInfoStr[5]:='               POUkeVAJe K ZESILOVaNe SIGNaLU MEZI DVdMI IZOLOVANjMI';
                GlobalInfoStr[6]:='               OBLASTMI. TAK ROZTfegTeME ODPOR ROBOTi.';
                MaxUsedGlobalInfo:=6;
              end;
              Mission1InfoStr[0]:='METHEOR 1)';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='METHEOR 2)';{}
              MaxUsedMission2Info:=0;
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=15; { max. pocet jednotek jadra do mise }
                MissionNameString:='34';
                Game:=34; Campaign:=1; EnemyRaces:=[3];
                {x}
                TempValue:=Random(80);  if (TempValue > 40) then TempValue:=TempValue-80;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (300+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(300+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-300-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                    GlobalModify.AllyFog:=1;
                  end;
                end;
                {X}
              end else begin
                MaxMissionCoreUnits:=8; { max. pocet jednotek jadra do mise }
                MissionNameString:='35';
                Game:=35; Campaign:=1; EnemyRaces:=[3,4,5];
                {X}
                TempValue:=Random(80);  if (TempValue > 40) then TempValue:=TempValue-80;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (280+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(280+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-280-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceMaterialModifiers[0].BPModif:=25;
                     GlobalModify.RaceMaterialModifiers[0].ExpModif:=25;
                     GlobalModify.RaceMaterialModifiers[0].PLModif:=25;
                     GlobalModify.RaceMaterialModifiers[0].EEModif:=25;
                   end;
                end;
              end;

              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       34,35: begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                  POINTS:=POINTS+POI;
                  MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
                  GlobalInfoStr[0]:='  JAK SE ZDa, GLOBaLNe ODPOR ROBOTi JE ZLOMEN. JIk NEMAJe kaDNc PROSTfEDKY';
                  GlobalInfoStr[1]:='NA NaHRADU ZNIbENjCH feDeCeCH CENTER. V fADaCH ZRaDCOVSKjCH VOJSK SE gefe';
                  GlobalInfoStr[2]:='PANIKA. VELKa baST SI VgAK UVdDOMUJE, JAKj OSUD JE bEKa. PROTO SE BUDOU';
                  GlobalInfoStr[3]:='BRaNIT DO POSLEDNeHO MUkE. bEKa NaS POSLEDNe VELKa BITVA TcTO VaLKY.';
                  MaxUsedGlobalInfo:=3;
                  Mission1InfoStr[0]:='   LIKVIDACE POSLEDNeHO VELKcHO OHNISKA ODPORU';
                  MaxUsedMission1Info:=0;
                  Mission2InfoStr[0]:='';{}
                  MaxUsedMission2Info:=255;
                  if (DrawMissionSelect = 1) then begin
                    MissionNameString:='36';
                    Game:=36; Campaign:=1; EnemyRaces:=[3,4,5];
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (500+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                       if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI SILNdJge SPOJENCE?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                         GlobalModify.FriendlySpecialUnitsPresent:=True;
                       end;
                    end;
                    {X}
                    TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                    TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                    if ((POINTS >= (230+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                       Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                       Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                       Str(230+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                       if (WideDialogBox('CHCETE, ABY MdLI SPOJENCI V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                         Str3,Str2,_YES_NO)=YES)
                       then begin
                         POINTS:=POINTS-230-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                         GlobalModify.RaceMaterialModifiers[1].BPModif:=20;
                         GlobalModify.RaceMaterialModifiers[1].ExpModif:=20;
                         GlobalModify.RaceMaterialModifiers[1].PLModif:=20;
                         GlobalModify.RaceMaterialModifiers[1].EEModif:=20;
                       end;
                    end;
                    {X}
                  end else begin
                    {MissionNameString:='1';
                    Game:=1; Campaign:=1; EnemyRaces:=[5];{}
                    {Error(0,'Chybny vyber mise - SelectMission, case34,35'); {}
                  end;
              end else begin
                 Return:=False;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
     else
       Return:=SelectMission3;
     end;
   end;
   SelectMission2:=Return;
end;

{ ************************************************************************* }
begin
end.
