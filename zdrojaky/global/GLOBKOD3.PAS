unit GlobKod3;
{$C FIXED PRELOAD PERMANENT}
interface

function SelectMission3:Boolean;
function ComputeTotalPoints(Score,Time,MyLostU,MyLostB,CORELOST:LongInt):LongInt;
procedure SaveBestTable;
function LoadBestTable:Boolean;
procedure DrawBestTable;

implementation
uses Crt, Data_glb, GlobGraf, Specgraf, Buttons, Mouse, Graph257,GlobalKod;

{ ***** }
function SelectMission3:Boolean;
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
       36: begin
              if (Victory = 1) then begin
                GlobalInfoStr[0]:='   DeKY VAgEMU hSPdCHU NA TcTO baSTI FRONTY LZE feCI, kE JSME ZVeTdZILI.';
                GlobalInfoStr[1]:='PfED SEBOU MaME Uk JEN LIKVIDACI MENgeCH SKUPINEK NEPfaTEL, KTERc SE STaLE';
                GlobalInfoStr[2]:='NECHTdJe VZDaT. JE NA VaS, NA KTERcM hSEKU SE ZAPOJeTE.';
                MaxUsedGlobalInfo:=2;
              end else begin
                GlobalInfoStr[0]:='   I PfES DeLbe NEhSPdCH NA VAge baSTI FRONTY LZE feCI, kE JSME ZVeTdZILI.';
                GlobalInfoStr[1]:='PfED SEBOU MaME Uk JEN LIKVIDACI MENgeCH SKUPINEK NEPfaTEL, KTERc SE STaLE';
                GlobalInfoStr[2]:='NECHTdJe VZDaT. JE NA VaS, NA KTERcM hSEKU SE ZAPOJeTE.';
                MaxUsedGlobalInfo:=2;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              Mission1InfoStr[0]:='ZNIbENe ZaKLADNY';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='PRiZKUMNa OPERACE';{}
              MaxUsedMission2Info:=0;
              if (DrawMissionSelect = 1) then begin
                MaxMissionCoreUnits:=15; { max. pocet jednotek jadra do mise }
                MissionNameString:='37';
                Game:=37; Campaign:=1; EnemyRaces:=[3];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (660+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(660+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE ABY MdL SPOJENEC V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-660-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[1].BPModif:=100;
                     GlobalModify.RaceMaterialModifiers[1].ExpModif:=100;
                     GlobalModify.RaceMaterialModifiers[1].PLModif:=100;
                     GlobalModify.RaceMaterialModifiers[1].EEModif:=100;
                   end;
                end;
              end else begin
                MaxMissionCoreUnits:=4; { max. pocet jednotek jadra do mise }
                MissionNameString:='38';
                Game:=38; Campaign:=1; EnemyRaces:=[3];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (560+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(560+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE ABY MdL SPOJENEC V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-560-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[1].BPModif:=50;
                     GlobalModify.RaceMaterialModifiers[1].ExpModif:=50;
                     GlobalModify.RaceMaterialModifiers[1].PLModif:=50;
                     GlobalModify.RaceMaterialModifiers[1].EEModif:=50;
                   end;
                end;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       37,38: begin
              if (Victory = 1) then begin
                 GlobalInfoStr[0]:='   ZVeTdZILI JSME, NEPfaTELc BYLI PORAkENI. LIDc SI ODDECHLI, HROZNc';
                 GlobalInfoStr[1]:='VaLEbNc BdSNdNe KONEbNd POMINULO. V JEDNOTLIVjCH ZEMeCH ZAbeNAJe FUNGOVAT';
                 GlobalInfoStr[2]:='PROGRAMY OBNOVY HOSPODafSTVe. V RADd OSN ZATeM PROBeHAJe HOREbNATa JEDNaNe.';
                 GlobalInfoStr[3]:='Uk NIKDY SE NESMe STaT, ABY SE TECHNIKA, URbENa PRO OBRANU MeRU, OBRaTILA';
                 GlobalInfoStr[4]:='PROTI LIDEM ...';
                 MaxUsedGlobalInfo:=4;
                 Return:=False;
              end else begin
                 GlobalInfoStr[0]:='   PROTOkE JSTE V POSLEDNeM BOJI NEOBSTaL, MUSELO OSN POVOLAT bERSTVc';
                 GlobalInfoStr[1]:='ODDeLY A TY SI PROTIVNeKY KONEbNd PORADILY.';
                 GlobalInfoStr[2]:='   ZVeTdZILI JSME, NEPfaTELc BYLI PORAkENI. LIDc SI ODDECHLI, HROZNc';
                 GlobalInfoStr[3]:='VaLEbNc BdSNdNe KONEbNd POMINULO. V JEDNOTLIVjCH ZEMeCH ZAbeNAJe FUNGOVAT';
                 GlobalInfoStr[4]:='PROGRAMY OBNOVY HOSPODafSTVe. V RADd OSN ZATeM PROBeHAJe HOREbNATa JEDNaNe.';
                 GlobalInfoStr[5]:='Uk NIKDY SE NESMe STaT, ABY SE TECHNIKA, URbENa PRO OBRANU MeRU, OBRaTILA';
                 GlobalInfoStr[6]:='PROTI LIDEM ...';
                 MaxUsedGlobalInfo:=6;
                 Return:=False;
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
      52 : begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=2; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   JIk fADU LET JE NEJKRITIbTdJgeM MeSTEM EVROPY TERITORIUM BjVALc JUGOSLaVIE.';
              GlobalInfoStr[1]:='ANI PfES SNAHU MEZINaRODNeHO SPOLEbENSTVe SE NEPODAfILO V OBLASTI BALKaNU';
              GlobalInfoStr[2]:='ZAJISTIT TRVALj MeR. I NADaLE POKRAbUJe NaSILNOSTI, VRAkDY A NENaVIST MEZI';
              GlobalInfoStr[3]:='PfISLUgNeKY JEDNOTLIVjCH NaRODNOSTe. JIk NdKOLIKRaT DOgLO K POKUSiM O';
              GlobalInfoStr[4]:='ROZgefENe KONFLIKTU DO DALgICH MeST V EVROPd.';
              GlobalInfoStr[5]:='   PROTO SE RADA BEZPEbNOSTI OSN, PODPOROVANa NATO A RUSKEM ROZHODLA';
              GlobalInfoStr[6]:='SESTAVIT SPECIaLNe ARMaDNe SBOR (ISAF), JEHOk hKOLEM BUDE SITUACI ZKLIDNIT.';
              GlobalInfoStr[7]:='JAKO MLADj A NADdJNj DiSTOJNeK JSTE BYL VYBRaN ZA VELITELE 3.SPECIaLNe';
              GlobalInfoStr[8]:='BRIGaDY OSN, KTERa PONESE HLAVNe TeHU NA PObaTKU OPERACE.';
              GlobalInfoStr[9]:='   hSPdCH V TcTO KAMPANI MikE VjRAZNd OVLIVNIT VAgI DALge KARIcRU.';
              GlobalInfoStr[10]:='                               HODNd gTdSTe !';
              MaxUsedGlobalInfo:=10;
              Mission1InfoStr[0]:='BUDOVaNe ZaKLADNY SIL OSN V OBLASTI BjVALc JUGOSLaVIE';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='1';
                Game:=1; Campaign:=1; EnemyRaces:=[5];
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=1;{}
                {Error(0,'Chybny vyber mise - SelectMission, case0'); {}
              end;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;

       50: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory >= 0) then begin
                 GlobalInfoStr[0]:='       VELITELI, DdKUJEME ZA DOBfE PROVEDENOU PRaCI. S VAge POMOCe JSME';
                 GlobalInfoStr[1]:='ZACHRaNILI HODNd LIDSKjCH kIVOTi. BOHUkEL, TATO OPERACE NaS PfIgLA VELMI';
                 GlobalInfoStr[2]:='DRAHO. OBYVATELc VE bLENSKjCH ZEMeCH SE ZAbeNAJe BOUfIT - NECHTdJe, ABY';
                 GlobalInfoStr[3]:='JEJICH DdTI UMeRALY NdKDE NA DRUHcM KONCI SVdTA PRO VdCI, KTERc SE JICH';
                 GlobalInfoStr[4]:='ZDaNLIVd NETjKAJe. JESTLI SE BUDE SITUACE I NADaLE TAKTO VYVeJET, JE' ;
                 GlobalInfoStr[5]:='BUDOUCNOST VOJENSKjCH SLOkEK OSN SILNd OHROkENA.';
                 GlobalInfoStr[6]:='        NYNe VaS ALE POTfEBUJEME ZPdT NA BALKaNd. SITUACE SE ZKOMPLIKOVALA.';
                 GlobalInfoStr[7]:='TENTOKRaT SE DO OHROkENe DOSTALI NAgI CIVILNe POZOROVATELc. PROTO DOSTANETE';
                 GlobalInfoStr[8]:='K DISPOZICI SPECIaLNe VOJENSKc LETADLO, KTERc VaS CO NEJRYCHLEJI DOPRAVe';
                 GlobalInfoStr[9]:='K VAge BRIGaDd.';
                 MaxUsedGlobalInfo:=9;
                 Mission1InfoStr[0]:='EVAKUACE CIVILNeCH PRACOVNeKi OSN';{}
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';
                 MaxUsedMission2Info:=255;

                 if (DrawMissionSelect = 1) then begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='6'; Game:=6; Campaign:=1;{} EnemyRaces:=[5];
                 end else begin
                    {Error(0,'Chybny vyber mise - SelectMission, case50'); {}
                 end;
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
              end else begin
                 GlobalInfoStr[0]:='       VELITELI, NEhSPdCH OPERACE NENe PfePUSTNj. POTfEBUJEME ZeSKAT bAS,';
                 GlobalInfoStr[1]:='TAKkE MaTE MOkNOST OPERACI ZOPAKOVAT.';
                 MaxUsedGlobalInfo:=2;
                 if (DrawMissionSelect = 1) then begin
                    MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                    MissionNameString:='50';
                    Game:=50; Campaign:=1; EnemyRaces:=[4];
                    GlobalModify.FriendlySpecialUnitsPresent:=True;
                 end else begin
                    {Error(0,'Chybny vyber mise - SelectMission, case50'); {}
                 end;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
      51: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              if (Victory = 1) then begin
                MaxMissionCoreUnits:=4; { max. pocet jednotek jadra do mise }
                GlobalInfoStr[0]:='       VeTaME VaS ZPdT V BjVALc JUGOSLaVII. BdHEM VAgEHO POBYTU V JEMENU';
                GlobalInfoStr[1]:='SE SITUACE ZKOMPLIKOVALA. PODROBNOSTI VaM BUDOU SDdLENY NA BRIEFINGU. ';
                MaxUsedGlobalInfo:=1;
                Mission1InfoStr[0]:='OCHRANA CIVILNeCH OBJEKTi PfED TERORISTICKjMI hTOKY.';
                MaxUsedMission1Info:=0;
                Mission2InfoStr[0]:='';{}
                MaxUsedMission2Info:=255;
                if (DrawMissionSelect = 1) then begin
                  MissionNameString:='7';
                  Game:=7; Campaign:=1; EnemyRaces:=[5];
                  if ((POINTS >= 750) and (VICTORYPOINTS >= 0)) then begin
                    Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                    Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                    if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                      'CENA: KREDITY: 750,  PRESTIk: 0',
                                      Str2,_YES_NO)=YES)
                    then begin
                      POINTS:=POINTS-750; VICTORYPOINTS:=VICTORYPOINTS-0;
                      with (GlobalModify.RaceMaterialModifiers[0]) do begin
                         BPModif:=50; PLModif:=50; EEModif:=50; ExpMOdif:=50;
                      end;
                    end;
                  end;
                  if ((POINTS >= 420) and (VICTORYPOINTS >= 0)) then begin
                    Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                    Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                    if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE O TERcNU?',
                                      'CENA: KREDITY: 420,  PRESTIk: 0',
                                      Str2,_YES_NO)=YES)
                    then begin
                      POINTS:=POINTS-420; VICTORYPOINTS:=VICTORYPOINTS-0;
                      GlobalModify.UnknownTerrain:=0;
                    end;
                  end;
                end else begin
                  {Error(0,'Chybny vyber mise - SelectMission, case51'); {}
                end;
              end else begin { VICTORY <> 1 }
                MaxMissionCoreUnits:=1; { max. pocet jednotek jadra do mise }
                GlobalInfoStr[0]:='     V JEMENU MUSeME USPdT ZA KAkDOU CENU. LEVNOU ROPU POTfEBUJEME ZEJMcNA';
                GlobalInfoStr[1]:='PRO NAgE BOJOVc OPERACE NA BALKaNd. ZKUSTE gTdSTe ZNOVU.';
                MaxUsedGlobalInfo:=2;
                Mission1InfoStr[0]:='VYVOLaNe VZPOURY PROTI DIKTaTORSKcMU REkIMU';
                MaxUsedMission1Info:=0;
                Mission2InfoStr[0]:='';{}
                MaxUsedMission2Info:=255;
                if (DrawMissionSelect = 1) then begin
                  MissionNameString:='51';
                  Game:=51; Campaign:=1; EnemyRaces:=[5];
                  if ((POINTS >= 600) and (VICTORYPOINTS >= 0)) then begin
                    Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                    Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                    if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                      'CENA: KREDITY: 600,  PRESTIk: 0',
                                      Str2,_YES_NO)=YES)
                    then begin
                      POINTS:=POINTS-600; VICTORYPOINTS:=VICTORYPOINTS-0;
                      GlobalModify.FriendlySpecialUnitsPresent:=True;
                    end;
                  end;
                end else begin
                  {Error(0,'Chybny vyber mise - SelectMission, case51'); {}
                end;
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
          end;

       54: begin
              if (Victory = 1) then begin
                  VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI*2;
                  POINTS:=POINTS+POI+1;
                  if (Zrada) then begin
                     MaxMissionCoreUnits:=2; { max. pocet jednotek jadra do mise }
                     GlobalInfoStr[0]:='   GRATULUJEME VELITELI, PfIDAL JSTE SE NA SPRaVNOU STRANU. VAgI POMOC';
                     GlobalInfoStr[1]:='BUDE UNIE V BOJI S ARMaDAMI OSN POTfEBOVAT. NYNe JE NUTNc, ABY JSTE NA';
                     GlobalInfoStr[2]:='SVOU STRANU ZeSKAL CO NEJVeCE BjVALjCH SPOLUBOJOVNeKi.';
                     MaxUsedGlobalInfo:=2;
                     Mission1InfoStr[0]:='   ZeSKaNe VeCE JEDNOTEK NA NAgI STRANU';
                     MaxUsedMission1Info:=0;
                     Mission2InfoStr[0]:='';{}
                     MaxUsedMission2Info:=255;
                     if (DrawMissionSelect = 1) then begin
                       MissionNameString:='65';
                       Game:=65; Campaign:=2; EnemyRaces:=[4,2];
                     end else begin
                       {MissionNameString:='1';
                       Game:=1; Campaign:=1; EnemyRaces:=[5];{}
                       {Error(0,'Chybny vyber mise - SelectMission, case54 - 2'); {}
                     end;
                  end else begin
                     MaxMissionCoreUnits:=3; { max. pocet jednotek jadra do mise }
                     GlobalInfoStr[0]:='   GRATULUJEME. KAkDcHO ZRaDCE bEKa PfESNd TAKOVj OSUD. NA CESTd K VeTdZTVe';
                     GlobalInfoStr[1]:='MUSeME BjT NELeTOSTNe.';
                     GlobalInfoStr[2]:='   JIk DELge DOBU PROBeHAJe INTENZIVNe PRaCE NA TAJNcM PROJEKTU "METHEOR."';
                     GlobalInfoStr[3]:='PROJEKTU SE hbASTNe NAgI NEJLEPge VdDCI. PfED SEBOU MaME NdKOLIK hKOLi:';
                     GlobalInfoStr[4]:='- ZNOVUPfEVZETe KONTROLY NAD JEDNOTKAMI ROBOTi';
                     GlobalInfoStr[5]:='- ZKOUMaNe SYSTcMi, UPRAVENjCH ROBOTY';
                     GlobalInfoStr[6]:='- OVdfENe TEORIe O HIERARCHII feDeCeCH CENTER';
                     GlobalInfoStr[7]:='- HLEDaNe ZPiSOBi OCHROMENe KOMUNIKAbNe SeTd';
                     MaxUsedGlobalInfo:=7;
                     Mission1InfoStr[0]:='   OCHRANA VdDECKcHO TjMU';
                     MaxUsedMission1Info:=0;
                     Mission2InfoStr[0]:='';{}
                     MaxUsedMission2Info:=255;
                     if (DrawMissionSelect = 1) then begin
                       MissionNameString:='33';
                       Game:=33; Campaign:=1; EnemyRaces:=[3];
                       {X}
                       TempValue:=Random(50);  if (TempValue > 25) then TempValue:=TempValue-50;
                       TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                       if ((POINTS >= (300+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                          Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                          Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                          Str(300+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                          if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI SILNdJge SPOJENCE?',
                                            Str3,Str2,_YES_NO)=YES)
                          then begin
                            POINTS:=POINTS-300-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                            GlobalModify.FriendlySpecialUnitsPresent:=True;
                          end;
                       end;
                     end else begin
                       {MissionNameString:='1';
                       Game:=1; Campaign:=1; EnemyRaces:=[5]; {}
                       {Error(0,'Chybny vyber mise - SelectMission, case54-1'); {}
                     end;
                  end;
              end else begin
                 VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
                 POINTS:=POINTS+POI;
                 MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
                 GlobalInfoStr[0]:='   GENERaL MUSe BjT ZABIT ZA KAkDOU CENU. NESMe UNIKNOUT.';
                 MaxUsedGlobalInfo:=0;
                 Mission1InfoStr[0]:='   DALge POKUS O LIKVIDACI ZRaDCOVSKcHO GENERaLA';
                 MaxUsedMission1Info:=0;
                 Mission2InfoStr[0]:='';{}
                 MaxUsedMission2Info:=255;
                 if (DrawMissionSelect = 1) then begin
                   MissionNameString:='54';
                   Game:=54; Campaign:=1; EnemyRaces:=[5];
                 end else begin
                   {MissionNameString:='1';
                   Game:=1; Campaign:=1; EnemyRaces:=[5]; {}
                   {Error(0,'Chybny vyber mise - SelectMission, case54'); {}
                 end;
              end;

              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
      60 : begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              GlobalInfoStr[0]:='   PfI NAgEM POSTUPU NaS ZASTAVIL PaS HOR. BOJ O STRATEGICKj PRiSMYK UKakE,';
              GlobalInfoStr[1]:='ZDA UDRkeME INICIATIVU NEBO DaME ROBOTiM bAS, ABY ZNOVU NABRALI DECH.';
              MaxUsedGlobalInfo:=1;
              Mission1InfoStr[0]:='BOJ O STRATEGICKj PRiSMYK';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
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
                {Error(0,'Chybny vyber mise - SelectMission, case60'); {}
              end;

              if (Victory = 1) then begin
                 OfferSpecialCoreUnit(15,4,'CARABINIER');
              end;
              if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;{}
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       65: begin
               VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
               POINTS:=POINTS+POI;
               MaxMissionCoreUnits:=6; { max. pocet jednotek jadra do mise }
               GlobalInfoStr[0]:='   NA JEDNOM Z febNeCH OSTRiVKi (MeSTO ZNaME BOHUkEL JEN PfIBLIkNd)';
               GlobalInfoStr[1]:='SE NACHaZe ZAJATECKj TaBOR OSN. JE TAM ZADRkOVaN JEDEN Z PfEDNeCH VELITELi';
               GlobalInfoStr[2]:='UNIE GENERaL ATTILA. MUSeME HO OSVOBODIT. BUDETE DOPRAVENI DO BLeZKOSTI';
               GlobalInfoStr[3]:='PfEDPOKLaDANcHO MeSTA VRTULNeKY. ZBYTEK JE NA VaS.';
               MaxUsedGlobalInfo:=3;
               Mission1InfoStr[0]:='ZaCHRANA GENERaLA ATTILY';
               MaxUsedMission1Info:=0;
               Mission2InfoStr[0]:='';{}
               MaxUsedMission2Info:=255;
               if (DrawMissionSelect = 1) then begin
                 MissionNameString:='53';
                 Game:=53; Campaign:=2; EnemyRaces:=[3,5];
                 {X}
                 TempValue:=Random(10);  if (TempValue > 5) then TempValue:=TempValue-10;
                 TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                 if ((POINTS >= (20+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                    Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                    Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                    Str(20+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                    if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI OSLABIT JEDNU NEPfaTELSKOU STRANU?',
                                      Str3,Str2,_YES_NO)=YES)
                    then begin
                      POINTS:=POINTS-20-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                      GlobalModify.RaceMaterialModifiers[3].BPModif:=-10;
                      GlobalModify.RaceMaterialModifiers[3].ExpModif:=-10;
                      GlobalModify.RaceMaterialModifiers[3].PLModif:=-10;
                      GlobalModify.RaceMaterialModifiers[3].EEModif:=-10;
                    end;
                 end;
                 {X}
                 TempValue:=Random(40);  if (TempValue > 20) then TempValue:=TempValue-40;
                 TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                 if ((POINTS >= (250+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                    Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                    Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                    Str(250+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                    if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI OSLABIT DRUHOU NEPfaTELSKOU STRANU?',
                                      Str3,Str2,_YES_NO)=YES)
                    then begin
                      POINTS:=POINTS-250-TempValue; VICTORYPOINTS:=VICTORYPOINTS;
                      GlobalModify.RaceMaterialModifiers[5].BPModif:=-10;
                      GlobalModify.RaceMaterialModifiers[5].ExpModif:=-10;
                      GlobalModify.RaceMaterialModifiers[5].PLModif:=-10;
                      GlobalModify.RaceMaterialModifiers[5].EEModif:=-10;
                    end;
                 end;
               end else begin
                 {MissionNameString:='1';
                 Game:=1; Campaign:=2; EnemyRaces:=[5];{}
                 {Error(0,'Chybny vyber mise - SelectMission, case65'); {}
               end;

              {if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;{}
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;{}
           end;
       53: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
              if (Victory = 1) then begin
                GlobalInfoStr[0]:='   ZaCHRANA GENERaLA SE SKUTEbNd VYPLATILA. V NaLEDUJeCe MISI NaM JEHO';
                GlobalInfoStr[1]:='NEJLEPge MUkI POMOHOU.';
                GlobalInfoStr[2]:='   SITUACE NA FRONTd JE NEUSPOKOJIVa. NAgI SPOJENCI SE POTjKAJe S PROBLcMY.';
                GlobalInfoStr[3]:='feDeCe CENTRA JSOU baSTEbNd ZNIbENa, PROTO SE NaM DOSTALO NEJVYgge CTI';
                GlobalInfoStr[4]:='OSOBNd feDIT ROBOTIZOVANc ODDeLY.';
                MaxUsedGlobalInfo:=4;
                GlobalMOdify.FriendlySpecialUnitsPresent:=True;
              end else begin
                GlobalInfoStr[0]:='   SITUACE NA FRONTd JE NEUSPOKOJIVa. NAgI SPOJENCI SE POTjKAJe S PROBLcMY.';
                GlobalInfoStr[1]:='feDeCe CENTRA JSOU baSTEbNd ZNIbENa, PROTO SE NaM DOSTALO NEJVYgge CTI';
                GlobalInfoStr[2]:='OSOBNd feDIT ROBOTIZOVANc ODDeLY.';
                MaxUsedGlobalInfo:=2;
              end;
              Mission1InfoStr[0]:='BOJ PROTI SILaM OSN';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='30';
                Game:=30; Campaign:=2; EnemyRaces:=[1,4];
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (400+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(400+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI POSeLIT SPOJENCE ?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-400-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.RaceMaterialModifiers[3].BPModif:=15;
                     GlobalModify.RaceMaterialModifiers[3].ExpModif:=15;
                     GlobalModify.RaceMaterialModifiers[3].PLModif:=15;
                     GlobalModify.RaceMaterialModifiers[3].EEModif:=15;
                   end;
                end;
                {X}
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=2; EnemyRaces:=[5]; {}
                {Error(0,'Chybny vyber mise - SelectMission, case53'); {}
              end;

              {if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;{}
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       30: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   SITUACE SE ZHORgUJE KAkDjM DNEM. OSN PROVEDLO TAJNOU OPERACI, JEJeMk';
              GlobalInfoStr[1]:='VjSLEDKEM JE DALge OCHROMENe KOMUNIKACE MEZI CENTRY ROBOTi. Nag ODPOR';
              GlobalInfoStr[2]:='JE STaLE ZOUFALEJge. TdkKO feCI, JAK DLOUHO SE JEgTd UDRkeME.';
              MaxUsedGlobalInfo:=2;
              Mission1InfoStr[0]:='   BOJ O PfEkITe';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='66';
                Game:=66; Campaign:=2; EnemyRaces:=[1,4];
                {X}
                TempValue:=Random(10);  if (TempValue > 5) then TempValue:=TempValue-10;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (520+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(520+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI OSLABIT NEPfaTELE A POSeLIT SEBE?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-520-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceMaterialModifiers[1].BPModif:=-15;
                     GlobalModify.RaceMaterialModifiers[1].ExpModif:=-15;
                     GlobalModify.RaceMaterialModifiers[1].PLModif:=-15;
                     GlobalModify.RaceMaterialModifiers[1].EEModif:=-15;
                     GlobalModify.RaceMaterialModifiers[4].BPModif:=-15;
                     GlobalModify.RaceMaterialModifiers[4].ExpModif:=-15;
                     GlobalModify.RaceMaterialModifiers[4].PLModif:=-15;
                     GlobalModify.RaceMaterialModifiers[4].EEModif:=-15;
                     GlobalModify.RaceMaterialModifiers[0].ExpModif:=33;
                   end;
                end;

              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=2; EnemyRaces:=[5]; {}
                {Error(0,'Chybny vyber mise - SelectMission, case30'); {}
              end;
              {if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;{}
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       66: begin
              VICTORYPOINTS:=VICTORYPOINTS+VICTORYPOI;
              POINTS:=POINTS+POI;
              MaxMissionCoreUnits:=0; { max. pocet jednotek jadra do mise }
              GlobalInfoStr[0]:='   JE ROZHODNUTO. OBRANA SE ZCELA ROZPADLA. SeLY OSN JIk OBSADILY TcMdf';
              GlobalInfoStr[1]:='CELc hZEMe UNIE. EXISTUJE POUZE NdKOLIK OSTRiVKi ODPORU, I TY VgAK VYDRke';
              GlobalInfoStr[2]:='NdKOLIK HODIN, MAXIMaLNd DNi. JEDINOU MOkNOSTe JE hTdK DO MaLO OBYDLENjCH';
              GlobalInfoStr[3]:='MeST JIkNe AMERIKY.';
              MaxUsedGlobalInfo:=3;
              Mission1InfoStr[0]:='   POSLEDNe MISE';
              MaxUsedMission1Info:=0;
              Mission2InfoStr[0]:='';{}
              MaxUsedMission2Info:=255;
              if (DrawMissionSelect = 1) then begin
                MissionNameString:='67';
                Game:=67; Campaign:=2; EnemyRaces:=[1,4];
                {X}
                TempValue:=Random(300);  if (TempValue > 150) then TempValue:=TempValue-300;
                TempValue:=TempValue+Random(abs(Round(POINTS / 15)));
                if ((POINTS >= (9000+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(9000+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI VjRAZNd OSLABIT NEPfaTELE?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-9000-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalMOdify.EnemySpecialUnitsPresent:=False;
                   end;
                end;
              end else begin
                {MissionNameString:='1';
                Game:=1; Campaign:=2; EnemyRaces:=[5]; {}
                {Error(0,'Chybny vyber mise - SelectMission, case66'); {}
              end;
              {if (Return and (Rand(RndUk) < 8)) then OfferNewCoreUnit;
              if (Return and (Rand(RndUk) mod 3 = 0)) then OfferNewCoreUnit;{}
              VICTORYPOINTS:=VICTORYPOINTS+VPointsPerMission;
              POINTS:=POINTS+PointsPerMission;
           end;
       67 : begin
               if (Victory = 1) then begin
                 GlobalInfoStr[0]:='   GRATULUJEME. PODAfILO SE VaM UNIKNOUT DO AMAZONSKjCH PRALESi, KDE';
                 GlobalInfoStr[1]:='VaS MEZI DOMORODjMI OBYVATELI NIKDO HLEDAT NEBUDE. HODNd gTdSTe.';
                 MaxUsedGlobalInfo:=1;
               end else begin
                 GlobalInfoStr[0]:='   BRaNIL JSTE SE STATEbNd, AVgAK BEZ hSPdCHU. VAgI VdRNe BYLI DO JEDNOHO';
                 GlobalInfoStr[1]:='POBITI. VY SaM JSTE BYL ZAJAT. BdHEM NdKOLIKA DNe VaS PfEVEZLI DO NIZOZEMe,';
                 GlobalInfoStr[2]:='KDE BUDETE V MEZINaRODNeM VdZENe PYKAT ZA SVOU ZRADU.';
                 MaxUsedGlobalInfo:=2;
               end;

               Return:=False;
            end;
     end;
  end;
  SelectMission3:=Return;
end;

{ ***** }
function ComputeTotalPoints(Score,Time,MyLostU,MyLostB,CORELOST:LongInt):LongInt;
{ na zaklade Score vypocte skutecny max. pocet bodu
}
var Temp:Single;
begin
   if (Victory = 1) then begin { za vitezstvi je vice }
     Temp:=1.0*Score / 2.4;
   end else begin
     Temp:=1.0*Score / 3;
   end;
   Temp:=Temp-(Temp/3600)*Time;
   Temp:=Temp-MyLostU*10-MYLostB*22-CORELOST*40;

   ComputeTotalPoints:=Round(Temp);
end;

{ ***** }
procedure BestTableSort;
{  seradi pole
}
var I:Word;
    PomTable:TBestOfTable;
    Change:Boolean;
begin
  { zesortovani tabulky }
  Change:=True;
  while (Change) do begin
    Change:=False;
    for I:=1 to MaxBestOfTable do
      if  ((BestOfTableOrder[I] >= 0) and (BestOfTableOrder[I-1] >= 0) and
           (BestOfTable[BestOfTableOrder[I]].TOTALPOINTS >
            BestOfTable[BestOfTableOrder[I-1]].TOTALPOINTS))
      then begin
         Change:=True;
         PomTable:=BestOfTable[BestOfTableOrder[I]];
         BestOfTable[BestOfTableOrder[I]]:=BestOfTable[BestOfTableOrder[I-1]];
         BestOfTable[BestOfTableOrder[I-1]]:=PomTable;
      end;
  end;
end;

{ ***** }
procedure SaveBestTable;
{ ulozit prubezne vysledky na disk
}
var IOFile:File;
    I,J,K:Word;
    Pom:LongInt;
    Free:Integer;
begin
   if (not LoadBestTable) then begin
     for I:=0 to MaxBestOfTable do BestOfTableOrder[I]:=-1;
   end;
   { * DOPLNIT AKTUALNI UPDATE * }
   J:=255;
   for I:=0 to MaxBestOfTable do begin
     if (J = 255) then begin
       if (BestOfTableOrder[I]=-1) then J:=I;
       if ((BestOfTableOrder[I] <> -1) and
           (BestOfTable[BestOfTableOrder[I]].PlayerUniqueNum = PlayerUniqueNum))
       then J:=I;
     end else begin
       if ((BestOfTableOrder[I] <> -1) and
           (BestOfTable[BestOfTableOrder[I]].PlayerUniqueNum = PlayerUniqueNum))
       then J:=I;
     end;
   end;
   if (J = 255) then begin { overwrite existing }
      J:=MaxBestOfTable;
      BestOfTable[BestOfTableOrder[J]].Name:=PlayerName;
      BestOfTable[BestOfTableOrder[J]].PlayerUniqueNum:=PlayerUniqueNum;
   end;

   if (BestOfTableOrder[J] = -1) then begin
     Free:=-1;
     for I:=0 to MaxBestOfTable do begin
       Pom:=I;
       for K:=0 to MaxBestOfTable do begin
          if (BestOfTableOrder[K] = Pom) then Pom:=-1;
       end; if (Pom > -1) then Free:=Pom;
     end;
     if (Free = -1) then Free:=MaxBestOfTable;
     BestOfTableOrder[J]:=Free;
     BestOfTable[BestOfTableOrder[J]].Name:=PlayerName;
     BestOfTable[BestOfTableOrder[J]].PlayerUniqueNum:=PlayerUniqueNum;
   end;

   BestOfTable[BestOfTableOrder[J]].TOTALPOINTS:=TOTALPOINTS;
   BestOfTable[BestOfTableOrder[J]].LOSTB:=LOSTB;
   BestOfTable[BestOfTableOrder[J]].LOSTU:=LOSTU;
   BestOfTable[BestOfTableOrder[J]].KILLEDB:=KILLEDB;
   BestOfTable[BestOfTableOrder[J]].KILLEDU:=KILLEDU;
   BestOfTable[BestOfTableOrder[J]].VICTORYNUM:=VICTORYNUM;
   BestOfTable[BestOfTableOrder[J]].CORELOST:=CORELOST;
   BestOfTable[BestOfTableOrder[J]].MissionNum:=MissionNum;

   { * UKLaDaNe NA DISK * }
   Assign(IOFile,PathStrGlobal+'hiscore'); Rewrite(IOFile,1);
   DResult:=IOResult;
   if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES); Exit; end;
   for I:=0 to MaxBestOfTable do if (BestOfTableOrder[I] <> -1) then
   with (BestOfTable[BestOfTableOrder[I]]) do begin
      {x}BlockWrite(IOFile,Name,SizeOf(Name)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,PlayerUniqueNum,SizeOf(PlayerUniqueNum)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,TOTALPOINTS,SizeOf(TOTALPOINTS)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,LOSTB,SizeOf(LOSTB)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,LOSTU,SizeOf(LOSTU)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,KILLEDB,SizeOf(KILLEDB)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,KILLEDU,SizeOf(KILLEDU)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,VICTORYNUM,SizeOf(VICTORYNUM)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,CORELOST,SizeOf(CORELOST)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
      {x}BlockWrite(IOFile,MissionNum,SizeOf(MissionNum)); DResult:=IOResult;
      if(DResult<>0) then begin DialogBox('CHYBA PfI UKLaDaNe HISCORE-V TABULCE NEBUDOU U HRabE SPRaVNc',_YES);Exit; end;
   end;
   Close(IOFile); DResult:=IOResult;
end;

{ ***** }
function LoadBestTable:Boolean;
{ nahrat prubezne vysledky z disku
}
var IOFile:File;
    I,J:Word;
begin
   for I:=0 to MaxBestOfTable do BestOfTableOrder[I]:=-1;
   J:=0; LoadBestTable:=True;
   Assign(IOFile,PathStrGlobal+'hiscore'); Reset(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
   while (not Eof(IOFile)) do with (BestOfTable[J]) do begin
      {x}BlockRead(IOFile,Name,SizeOf(Name));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,PlayerUniqueNum,SizeOf(PlayerUniqueNum));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,TOTALPOINTS,SizeOf(TOTALPOINTS));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,LOSTB,SizeOf(LOSTB));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,LOSTU,SizeOf(LOSTU));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,KILLEDB,SizeOf(KILLEDB));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,KILLEDU,SizeOf(KILLEDU));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,VICTORYNUM,SizeOf(VICTORYNUM));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,CORELOST,SizeOf(CORELOST));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      {x}BlockRead(IOFile,MissionNum,SizeOf(MissionNum));
      DResult:=IOResult; if(DResult<>0) then begin LoadBestTable:=False; Exit; end;
      BestOfTableOrder[J]:=J;
      Inc(J);
   end; Close(IOFile); DResult:=IOResult;
   BestTableSort;{}
end;

{ ***** }
procedure DrawBestTable;
{ vykresli prubezne vysledky
}
var I,J:Integer;
    MissionNum,Num:Word;
    PomStr, Str1, Str2, Str3:String;
    Return:Boolean;
    Pom:Byte;
    TempValue:Integer;
    ITextSize, JTextSize:Integer;
    X,Y, XSize, YSize:Word;
    Konec:Boolean;
    Button,Scan,Ascii:Word;
begin
 if (LoadBestTable) then begin
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
   { ********* UZITECNY KOD ********* }
{   BestOfTableOrder[0]:=0;
   with (BestOfTable[0]) do begin
     Name:='PAJAJAJA';
   end;{}

   X:=(XResolution-640) shr 1+2; Y:=(YResolution-480) shr 1;
   OutTextColor(X+1,Y+1,DarkYellow,'                                 ZTRACENc      NEPfeTELI ZNIbENc        ZTRaTY');
   OutTextColor(X,Y,Yellow,'                                 ZTRACENc      NEPfeTELI ZNIbENc        ZTRaTY'); Inc(Y,YFontSize);
   OutTextColor(X+1,Y+1,DarkYellow,' NaZEV HRabE    BODi    MISe  BUDOVY JEDNOTKY   BUDOVY JEDNOTKY  VeTdZ  JaDRA');
   OutTextColor(X,Y,Yellow,' NaZEV HRabE    BODi    MISe  BUDOVY JEDNOTKY   BUDOVY JEDNOTKY  VeTdZ  JaDRA');
   {x}
   Inc(Y,YFontSize+8);
   for I:=0 to MaxBestOfTable do if (BestOfTableOrder[I] <> -1) then
   with (BestOfTable[BestOfTableOrder[I]]) do begin
      X:=(XResolution-640) shr 1+4;
      OutTextColor(X,Y,Blue,Name); Inc(X,16*XFontSize);
      {x}
      Str(TOTALPOINTS,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,9*XFontSize);
      {x}
      Str(MissionNum,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,7*XFontSize);
      {x}
      Str(LOSTB,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,7*XFontSize);
      {x}
      Str(LOSTU,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,11*XFontSize);
      {x}
      Str(KILLEDB,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,7*XFontSize);
      {x}
      Str(KILLEDU,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,9*XFontSize);
      {x}
      Str(VICTORYNUM,PomStr); PomStr:=PomStr+'x';
      OutTextColor(X,Y,Blue,PomStr); Inc(X,8*XFontSize);
      {x}
      Str(CORELOST,PomStr);
      OutTextColor(X,Y,Blue,PomStr); Inc(X,6*XFontSize);

      Inc(Y,YFontSize);
   end;

   X:=(XResolution-BigButtonXSize) shr 1; Y:=(YResolution-480) shr 1 + (MaxBestOfTable+6)*YFontSize;
   CreateButton(X,Y,0,0,False,_Temp1); ButtonText(_Temp1,TextColor,'ZPdT');
   Release(_Temp1); SetActive(_Temp1);
   CursorOn;
   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         _Temp1     : begin { nova kampan }
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_Temp1,256);

   { **** KONEC UZITECNEHO KODU  **** }
   CursorOff;
   ClearScreen;
   LoadRGB(0,PathStrGlobal+'data\paleta1.rgb');
   Blue:=98; DarkBlue:=108; Yellow:=160; DarkYellow:=165; White:=66;
   InvalidateCache;
   OpenImage(PathStrGlobal+'data\buttons.glb',NoCreateNew);
   LoadImageGBM(On1Seg,On1Offs,'on1',0);
   LoadImageGBM(Off1Seg,Off1Offs,'off1',0);
   {X}
   OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
   LoadImageGBM(CursorSegment,CursorOffsets,'normal',0);
   {X}
   CursorOn;

 end; {if (LoadBestTable) then begin}
end;

{ ************************************************************************* }
BEGIN
END.
