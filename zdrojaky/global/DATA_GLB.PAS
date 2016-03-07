{ NASLEDUJICI VECI JE TREBA MENIT:
  * ZKUSENOSTI: *

}
{ Tato unita poskytuje vsem ostanim programum vsechny obecne deklarace

  TERMINOLOGIE:
  - kreslici obrazovka ... cast obrazovky s vykreslenymi jednotkami a
                           pozadim
  - policko ... blok na obrazovce (v pameti) o velikosti
                XCellSize x YCellSize bodu
  - casovy cyklus ... zakladni casova smycka, behem ktere probiha
                      veskere vykreslovani a vypocty

POCET POLICEK V MAPE MUSI BYT SUDE CISLO !!!!
ZBRANE : bud existuje pouze zbran 1, nebo existuje-li zbran2, musi jeji
dostrel vyplnit oblast:  minimalni dostrel zbrane1 - 1
TAHY: U JEMNEHO CASOVANI SE POTREBNE TAHY NAPR. K PRODUKCI PRIPOCITAVAJI
      PO 1, U HRUBEHO PO 2 !!
}

unit DATA_GLB;
{$C FIXED PRELOAD PERMANENT}
interface
uses Dos, winapi, Mouse, SBSound, Crt;

const { * CACHE * }
      MaxCacheMemory = 524288;
const { * FONT * }
      XFontSize = 8; { velikost pouziteho fontu }
      YFontSize = 16;

      { * MISE * }
      VPointsPerMission = 1; { tyto hodnoty je treba mit ke startu do dalsi mise }
      PointsPerMission = 950;
      MaxBestOfTable = 21;

      { * TYP JEDNOTEK * }
      MaxTypesOfUnits = 44; { max. pocet typu jednotek ve hre }
      { identifikacni cisla jednotek - cisla mensi nez 100 jsou lide }

      { * JEDNOTKY * }
      MaxUnits = 500; { maximalni pocet jednotek }
      MaxRaceUnits = 199; { maximalni pocet jednotek dane rasy -1 }
      MaxRace = 5; { udava po pricteni +1 pocet ruznych ras }

      { * TYP BUDOV * }
      MaxTypesOfBuildings = 25;

      { * BUDOVY * }
      MaxBuildings = 250; { maximalni pocet budov }
      MaxRaceBuildings = 99; { maximalni pocet budov dane rasy -1 }
      MaxBuildingPhase = 10; { maximalni pocet animacnich fazi jedne budovy }

      { * POZADI * }
      Way = 46;{39;  { maximalni index daneho terenu  - cesty }
      Grass = 156;{69;  { trava }
      Field = 156;{79;  { pole = trava }
      Resrc = 168;{94; { resource - "skladka" materialu }
      Desert = 168;{134; { poust = neexistuje }
      Hill = 195;   { kopec }
      Wather = 201;{189; { voda }
      Wood = 249;   { les }
      Airport = 250; { letiste }
      { nyni obrazky letiste }
      Airport1 =251; Airport2 =252; Airport3 =253; Airport4 =254;

      { * BARVY RADARU * }
      WayColor = 74;
      GrassColor = 38;
      FieldColor = 38;
      ResrcColor = 48; {!! MELA BY V BUDOUCNU BLIKAT !!}
      DesertColor = 52;
      HillColor = 54;
      WatherColor = 104;
      WoodColor = 41;
      AirFieldColor = 76;
      RadarBlinkColor = 248;
      { blikajici barva na radaru, signalizujici utok na vlastni jednotku }
      MaxWarningBlingValue = 55; { doba blikani jednotky, je-li na ni utoceno }

      { * KURZOR MYSI * }
      XCursor = 32; { velikost kurzoru mysi }
      YCursor = 32;

      { * TLACITKA * }
      TextColor= 160;
      SmallButtonXSize = 44; SmallButtonYSize = 18;{ velikost maleho tlacitka}
      BigButtonXSize = 168; BigButtonYSize = 25;{ velikost velkeho tlacitka}
      Button3XSize = 32; Button3YSize = 32;{ velikost specialniho tlacitka}
      ResearchButton = 1;  { }
      CoreButton = 2;  { }
      InfoButton = 3;  { }
      OptionButton = 4; {}
      SaveButton = 5;  { }
      LoadButton = 6;  { }
      EndButton = 7;  { }
      StartButton = 8;  { }
      DalsiTydenButton = 9;  { }
      _Ano = 10; _Ne = 11;
      _Temp1 = 12; _Temp2 = 13; _Temp3 = 14; _Temp4 = 15; _Temp5 = 16;
      _Temp6 = 17; _Temp7 = 18; _Temp8 = 19; _Temp9 = 20; _Temp10 = 21;
      _640x480 = 17; _800x600 = 18; _1024x768 = 19; _1200x1024 = 20;

      { * NAHODNA CISLA * }
      MaxRandomArrayIndex = 100;

      { * ZKUSENOSTI: * }
      { nyni budou vypsany pozadavky zkusenosti a poctu killu na dosazeni
        dane hodnosti }
      Experience0 = 0; Kills0 = 0;
      Experience1 = 25; Kills1 = 0;
      Experience2 = 49; Kills2 = 1;
      Experience3 = 74; Kills3 = 2;
      Experience4 = 145; Kills4 = 4;
      Experience5 = 278; Kills5 = 7;
      Experience6 = 400; Kills6 = 10;
      Experience7 = 612; Kills7 = 16;
      Experience8 = 744; Kills8 = 22;
      Experience9 = 900; Kills9 = 30;
      Experience10 = 1380; Kills10 = 40;
      Experience11 = 1900; Kills11 = 50;
      Experience12 = 2657; Kills12 = 75;

      { modifikatory obrany/utoku pri povyseni (v procentech) }
      Experience0DefenceModifier = 0;  Experience0AttackModifier = 0;
      Experience1DefenceModifier = 3.9;  Experience1AttackModifier = 4.8;
      Experience2DefenceModifier = 9.2;  Experience2AttackModifier = 10.7;
      Experience3DefenceModifier = 14.4;  Experience3AttackModifier = 17.2;
      Experience4DefenceModifier = 20.1;  Experience4AttackModifier = 25.0;
      Experience5DefenceModifier = 23.7;  Experience5AttackModifier = 29.1;
      Experience6DefenceModifier = 30.2;  Experience6AttackModifier = 36.2;
      Experience7DefenceModifier = 39.8;  Experience7AttackModifier = 43.6;
      Experience8DefenceModifier = 47.2;  Experience8AttackModifier = 52.9;
      Experience9DefenceModifier = 60.0;  Experience9AttackModifier = 70.1;
      Experience10DefenceModifier = 72.5;  Experience10AttackModifier = 85.3;
      Experience11DefenceModifier = 85.0;  Experience11AttackModifier = 101.2;
      Experience12DefenceModifier = 100;  Experience12AttackModifier = 120.4;

      { * ANIMOVANY TEXT * }
      MaxAnimTextRows = 30;
      MissionScreenMemory = 400000; { pro obrazek dane mise }
      YAnimAdd = 1; { pocet bodu, o nez se provede animace }
      YRowAdd = 4; { rozdily mezi jednotlivymi radky animovaneho textu }

      { * VYZKUM * }
      MaxResearch = 36;
      MaxResearchRecquired = 3; { maximalni pocet vyzkoumanych polozek,
                                  ktere umozni vyzkum jine veci }
      MaxResearchHate = 3; { maximalni pocet polozek, se kterymi se dany
                             vyzkum nesnasi (nelze je kombinovat) }
      P = 100; L = 101; T = 102; A = 103; V = 104;  { kategorie jednotek }
      XResearchInfoSize = 620;
      YResearchInfoSize = 440; { velikost info panelu }

      { * PRO UCELY ULOZENI POZADI * }
      WindowMemory = 640*480+4;
      Window1Memory = 640*480+4;
      XGetStringSize = 300; YGetStringSize = YFontSize*5;
      { NASLEDUJICI UDAJ O PAMETI MUSI BYT MENSI NEZ 64kb }
      GetStringBckMemory = (XGetStringSize*YGetStringSize)+4;
      XInfoSize = 400; YInfoSize = 300; { velikost info panelu }
      TempPictureMemory = 17000; { pro ukladani pomocnych veci - TempSeg }
      XWindow1Size = 320; YWindow1Size = 300;

      { * jadro * }
      MaxCoreUnits = 15;

type   TUnitsForMission = array [1..MaxTypesOfUnits] of Boolean;
       TAnimRec = record { pole pro animaci textu }
                   X1,Y1,X2,Y2 : Word;  { velikost pracovniho obdelniku }
                   ITextSize,JTextSize:Word; { velikost datoveho pole }
                   AnimText:array[0..MaxAnimTextRows] of String[80]; { text }
                   AnimTextMem:array[0..MaxAnimTextRows] of record
                   { hotovy text v pameti }
                                 S,O:Word;
                               end;
                   XFirstPos, YFirstPos : Integer; { pozice zacatku textu
                                                     v pameti }
                   S,O:Word; { pracovni plocha }
                   Speed:Boolean; { True, pokud se plocha vejde do 64kb }
                   SpaceBetweenRows:Word; { vzdalenost (v bodech) mezi radky }
                 end;
      TUnitCtg = 0..104;
      TResearch = array[1..MaxResearch] of record
                    Validity:Boolean; { True, pokud je polozka platna }
                    Name:String[10]; { nazev vyzkumu }
                    Descr: String[80]; { kratka charakteristika vyzkumu }
                    { podrobny popis vyzkumu: }
                    Descript:array[0..4] of String[75];
                    PercState : Single; { procentuelni stav vyzkumu:
                                          0=0%, 100=100% - vyzkoumano }
                    Recq:array[0..MaxResearchRecquired] of Byte;
                    { hodnoty "0" znaci neplatna cisla, jinak jsou zde
                      cisla polozek, ktere jsou treba pro vyzkum }
                    EnabledFor:set of TUnitCtg;
                    { mnozina kategorii jednotek, pro nez je vyzkum povolen:
                      P(echota),L(ehke),T(ezke),A(ir),V(eze) }
                    Hate:array[0..MaxResearchHate] of Byte;
                    { hodnoty "0" znaci neplatna cisla, jinak jsou zde
                      cisla polozek, se kterymi se tento vyzkum nesnasi }
                    Cost:Single; { cena vyzkumu v bodech }
                    VCost:Single; { cena vyzkumu ve viteznych bodech }
                    ResearchTime:Word; { doba, potrebna pro vyzkum }
                    u,o,k,lu,tu,au,r,d,h,s,BP,EE,PL,Ex : Single; { modifikatory
                    jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
                    tu(tezky utok), au(air utok), r(ychlost), d(ostrel),
                    h(odnost), s(ight), BP,EE,PL,Ex - modifikatory ceny }
                    Tag:Byte; { pouziti zbrane:
                                0..utocne;  1..obranne;  2..dohled;
                                3..pohon;   4..specialni; }
                    Temp:Byte; { pomocna promenna }
                  end;
      TUnitInfo = record
                     { Destroyed pro potreby real-time simulace }
                     Active,Destroyed:Boolean;
                     UnitType:Byte;
                     Experience:Word;
                     Kills:Word;
                     Level:Byte;
                     Name:String[15];
                     UniqueNumber:Word;
                  end;
      TReinfo = object
                   private
                      CoreInfo:array[0..MaxCoreUnits-1] of TUnitInfo;
                      Uk:Byte; { pro ucel prochazeni seznamu }
                   public
                      procedure Init;
                      procedure First;
                      procedure Next;
                      function  GetActive(var TUI:TUnitInfo):Boolean;
                      function  GetUnique(UniqueNum:Word; var TUI:TUnitInfo):Boolean;
                      function  Invalid:Boolean;
                      procedure Insert(TUI:TUnitInfo);
                      procedure Delete(UniqueNum:Word);
                      procedure Update(UniqueNum:Word; TUI:TUnitInfo);
                      function GetThisUnitTypeCount(UnitType:Byte):Byte;
                      function Full:Boolean;
                end;
      TSpeedArray = array[0..31] of Byte;
      TUnit_types = array[1..MaxTypesOfUnits,0..1] of record
      { ulozene informace o kazdem typu jednotky; indexem je
       identifikacni cislo jednotky;
       druhy index 0 = nepratele
                   1 = spojenci
      }
                      Production_time:Single; { za jeden tah se pri vyrobe
                      vyrobi Production_time procent jednotky }
                      MaxPhase : Byte; { max. faze pohybu }
                      BP,PL,EE,EX : Word;
                      { materialy, potrebne k vyrobe jednotky }
                      Name:String[15]; { nazev jednotky }
                      TargetTyp :Byte;
                      { typ cilu: 0..lehky - da se prejet,
                                  1..lehky - neda se prejet,
                                  2..tezky, 3..vzdusny, 4..namorni }
                      { pozor - max. dostrel ma zbran1, zbran2 je slabsi
                        (doplnujici) }
                      LightAttack1, HeavyAttack1, AirAttack1:Word; { sila utoku }
                      LightAttack2, HeavyAttack2, AirAttack2:Word; { sila utoku }
                      ShootRange1 : Word; { ve tvaru Hi(ShootRange1)-maximalni
                      a Low(ShootRange1) - minimalni dostrel zbrane 1 }
                      ShootRange2 : Word; { ve tvaru Hi(ShootRange2)-maximalni
                      a Low(ShootRange2) - minimalni dostrel zbrane 2 }
                      { horni byt je max. dostrel, dolni pak min. dostrel }
                      ShootSpeed1:Byte; { kadence strelby }
                      ShootSpeed2:Byte; { kadence strelby }
                      DefenceStrength:Word; { sila obrany }
                      SpeedLevel:Byte;
                      MovementAdding:TSpeedArray;
                      { 3. posunovy bodovy prirustek - "jemna varianta" }
                      NeedPlace:Byte; { zabira misto }
                      Capacity:Byte;  { kapacita jednotky }
                      Sight:Byte;  { dohled }
                      AttackLevel1:Byte; { atribut utoku pro zbran1:
                                  0..utok pechoty (nestrili pres kopce...)
                                  (nasledujici zbrane mohou strilet pres
                                   prekazky); nezobrazuje se
                                  1..pechota, zobrazuje se
                                  2..normalni zbran
                                  3..kamikadze
                      }
                      AttackLevel2:Byte; { atribut utoku pro zbran2:
                                  0..utok pechoty (nestrili pres kopce...)
                                  (nasledujici zbrane mohou strilet pres
                                   prekazky); nezobrazuje se
                                  1..pechota, zobrazuje se
                                  2..normalni zbran
                                  3..kamikadze
                      }
                      Picture1:Byte; { obrazek strely pro zbran1:
                                  1..kanon1 (slabsi projektil)
                                  2..kanon2 (silnejsi projektil)
                                  3..raketa1 (nejslabsi projektil)
                                  4..raketa1 (stredni projektil)
                                  5..raketa2 (nejsilnejsi projektil)
                      }
                      Picture2:Byte; { obrazek strely pro zbran2:
                                  1..kanon1 (slabsi projektil)
                                  2..kanon2 (silnejsi projektil)
                                  3..raketa1 (nejslabsi projektil)
                                  4..raketa1 (stredni projektil)
                                  5..raketa2 (nejsilnejsi projektil)
                      }
                      GuidedMissile : Boolean; { pro AttackLevel = 3..5
                      udava, zda je raketa samonavadena (True) nebo ne }
                      UnitLevel:Byte; { pohybova uroven jednotky :
                                  0..pozemni - nemuze na vodu, do lesa,do hor
                                  1..pozemni - nemuze na vodu, do lesa
                                  2..pozemni - nemuze do lesa
                                  3..vzdusny
                                  4..namorni - smi pouze po vode
                                  255..nemuze se pohybovat
                      }
                      SpecAirLevel:Byte; { spec. atribut vzdusne jednotky :
                                  0..potrebuje letiste
                                  1..nepotrebuje letiste
                      }
                      ShootType1,ShootDelay1,ShootType2,ShootDelay2:Word;
                      { je to specialni atribut pro zbrane; zbran se vzdy po
                        PauseType vystrelech (mezi nimi je normalni prodleva
                        kadence) odmlci na PauseDelay cyklu
                      }
                      Special:Byte; { ?? nevyuzito ?? }
                      PictureIndex:Byte; { index do pole obrazku;
                      kazdy obrazek muze mit nekolik variant podle toho,
                      komu nalezi (lidem, robotum ...); podle toho se
                      k tomuto indexu pripocita jeste specialni pridavek
                      Race (rasa) konkretni jednotky.
                      }
                      IUnitSize, JUnitSize:Byte; { velikost jednotky v POLICH}
                      XUnitSize, YUnitSize:Byte; { velikost jednotky v bodech}
                      Presah:Byte; { presah obrazku do dalsiho policka }
                      Build:Boolean; { jde o budovu ? - nektere budovy
                      jako napr. raketove veze budou brany jako
                      nepohyblive jednotky}
                      FlashPos : array[1..8] of record
                      { pro 8 smeru natoceni udava souradnice uvnitr
                        obrazku, od kterych se vykresli zablesk; jedna se
                        o Offset uvnitr obrazku oproti levemu hornimu
                        rohu jednotky; Offset je vztazen k levemu
                        hornimu rohu obrazku zablesku

                      }
                                   X,Y : Word;
                                 end;
                      Parent : Byte; { index materske tovarny }
                      Autorepair :Byte; { urcuje pocet procent poskozeni,
                      ktere je jednotka sama schopna opravit (zdarma);
                      napr. pro hodnotu 5 se automaticky opravi jakekoli
                      poskozeni pro DefenceStrength >= 95% }
                   end;
      PBackRecord = record { ukazatel na velikost back }
                       X,Y:Word;
                    end;
      TBestOfTable = record
                        Name:String[30];
                        PlayerUniqueNum, TOTALPOINTS, LOSTB, LOSTU,
                        KILLEDB, KILLEDU, VICTORYNUM, CORELOST:LongInt;
                        MissionNum:Word;
                     end;
var  Demo:Boolean;
     PlayerName:String[30];
     BestOfTable:array[0..MaxBestOfTable] of TBestOfTable;
     BestOfTableOrder:array[0..MaxBestOfTable] of Integer;
     PlayerUniqueNum, TOTALPOINTS, LOSTB, LOSTU,
     KILLEDB, KILLEDU, VICTORYNUM, CORELOST:LongInt;
     ResearchRandom:Word; { nahodne generovani; souvisi s nasledujici promennou }
     ResearchRandomStep:Word; { 0..k nicemu nedoslo; 1.. prvni varovani
                                (sila nepratel); 2..varovani o ubytku
                                finacnich prostredku}
     ErrorString:String;
     Zrada:Boolean; { True pro zradu v misi 54 }
     Pictures128:array[0..11] of record { obrazky 128x128 }
                      S,O:Word;
                      Max:BYte; { max. pouzita faze, plati pouze u indexu 0! }
                  end;
      Debug:Boolean;
      GameUniqueNum:LongInt;
      Blue,DarkBlue,Yellow,DarkYellow,White:Byte; { barvy pro pouziti }
      LastButton:Word; { pro potreby buttons2 }
      { nevyzkoumane jednotky, nepouzivat v save/load: }
      UnAvailUnits: set of 1..MaxTypesOfUnits;
      MissionNum:Word; { pocet absolvovanych misi+1 }
      Week:Word; { pocet absolvovanych tahu }
      { pro potreby kresleni: }
      SBack, OBack:Word;
      EnemyRaces:Set of 0..MaxRace; {seznam nepratelskych ras}
      Temp, CancelGame:Boolean;
      PathStr, PathStrGlobal:String[10]; { POMOCNE }
      XTable,YTable,XBeginMission, YBeginMission, XSingle, YSingle,
      XPokracovat, YPokracovat, XKonec, YKonec, XLoadGlobal, YLoadGlobal:Word;
      Core:TReinfo;
      LastUniqueNumber:Word; { posledni pouzite Unique cislo }
      MovementStep:Word;     { jemnost pohybu mysi - pro mouse.pas }
      {*pro _researc} TextMode:Boolean;  { True, jsou-li informace o vyzkumu
                                           v modu textu }
      {*pro _researc} OldRetLength:Byte; { posledni delka retezce-cisla
                                           procentualniho narustu vyzkumu }
      OSNPlayer:Boolean; { True, hraje-li hrac za OSN }
      MissionNameString:String;
      AnimRec : TAnimRec;
      SMissionScreen, OMissionScreen:Word; { pro obrazek mise }
      SScreen, OScreen:Word; { pro ulozeni pozadi }
{!!!!} ScreenShot:Boolean; {True = navic 1.4MB pameti pro ulozeni obrazku }
      EndOfGame : Boolean; { True pro konec aktualni hry }
      FailedCondition : Integer; { index podminky, na jsem prohral, -1..byl jsem
                                   vybit }
      Del1,Del2 : Word; { pro proceduru TimerOn }
      Win1BckSeg,Win1BckOfs : Word;  { pro ucely ukladani pozadi }
      GetStringBckSeg,GetStringBckOfs : Word;  { pro ucely spec.
                                                 dialogu GetString }
      { * Typ jednotek * }
      Unit_types : ^TUnit_types;
      MyUnitsForMission : TUnitsForMission;
      OtherUnitsForMission : TUnitsForMission;

      { * budovy * }
      BuildingsForMission : array [1..MaxTypesOfBuildings] of Boolean;

      { * Info * }
      UnitsInfoRecord : record
                           Rec:array[1..MaxTypesOfUnits] of Byte;
                           MaxIndex:Byte;
                        end;
      BuildingsInfoRecord : record
                              Rec:array[1..MaxTypesOfBuildings] of Byte;
                              MaxIndex:Byte;
                            end;
      { * CACHE * }
{ !!!!! } InternalCache:Boolean; { True, pouzije-li se interni cache }
      SCache,OCache:Word; { vnitrni cache }
      SCacheUk,OCacheUk:Word; { ukazatel do vnitrni cache }
      CacheValidity:Boolean; { je obsah cache platny? }
      CacheFile:String[80];
      CacheUk:Pointer;
      CachePos,CacheSize:LongInt; { informace o velikosti a pozici v cache }

      { * DATA O OBRAZOVCE * }
      MaxRes:Word; { udava maximalni pouzite rozliseni ve hre:
      0 .. 640x480; 1 .. 800x600; 2..1024x768; 3..1280x1024 }
      XResolution,YResolution :Word;

      { * PROMENNE PRO STAV KLAVESNICE (jednotka Buttons) * }
      SHIFT, CTRL, ALT : Boolean; { po volani funkce GetSpecKeysState
      nastavuje promenne na True (False), jsou-li (nejsou-li) stisknuty }
      PressedKey : Byte; { scan kod prave stisknute klavesy }

      { * OKNA * }
      TempSeg, TempOfs:Word; { pro ukladani pomocnych veci, velikost
                               TempPictureMemory }
      TempSeg2, TempOfs2:Word; { pro ukladani pomocnych veci, velikost
                                 Window1Memory }
      Win1Seg, Win1Ofs:Word;   { pozadi pod tlacitka }

      { * GLOBALNI STAV * }
      Points, VictoryPoints:Single; { stav bodu a viteznych bodu ve hre }
      Point, VictoryPoint:Single; { pro potreby pokracovani hry }

      { * VYZKUM * }
      Research : ^TResearch;
      GlobalSelectedResearch:Byte; { cislo aktivniho vyzkumu }
      X1RsrchInfo, Y1RsrchInfo, X2RsrchInfo, Y2RsrchInfo:Word; { informace
                     o obdelniku, v nemz se nachazi popis aktualniho vyzkumu }
      XResearchLeftTopText, YResearchLeftTopText:Word; { zacatek nazvu
                                                         aktualniho vyzkumu }
      X1ResearchFrame, Y1ResearchFrame:Word; { levy horni bod prubehu aktualniho
                                               vyzkumu }
      X2ResearchFrame, Y2ResearchFrame:Word; { pravy dolni bod prubehu
                                               aktualniho vyzkumu}
      ReserchInfoBckSeg, ReserchInfoBckOfs:Word; { ulozene pozadi }
      ReserchInfoBckMemory:LongInt; { pamet pro pozadi }
      ReserchTextBckSeg, ReserchTextBckOfs:Word; { ulozene pozadi pod textem }

      { * TLACITKA * }
      ResearchPressed, DalsiTydenPressed, CorePressed, InfoPressed,
      OptionPressed, SavePressed, LoadPressed, EndPressed, StartPressed : Byte;
      { <> 0, bylo-li tlacitko v minulych cyklech stisknuto }

      { * FONT * }
      FontSegment, FontOffsets : Word; { ulozena predloha s fontem }

      { * BODY A VITEZNE BODY * }
      PointsSeg, PointsOfs : Word; { obrazek ikony bodu }
      X1Points, Y1Points : Word; { umisteni ikony bodu }
      { souradnice okenka s prehledem bodu: }
      X1PointsInfo, Y1PointsInfo, X2PointsInfo, Y2PointsInfo : Word;
      VictoryPointsSeg, VictoryPointsOfs : Word; { obrazek ikony viteznych
                                                   bodu }
      X1VictoryPoints, Y1VictoryPoints : Word; { umisteni ikony viteznych bodu }
      { souradnice okenka s prehledem viteznych bodu: }
      X1VictoryPointsInfo, Y1VictoryPointsInfo,
      X2VictoryPointsInfo, Y2VictoryPointsInfo : Word;
      PointsBckSeg, PointsBckOfs : Word; { obrazek ikony bodu }
      VictoryPointsBckSeg, VictoryPointsBckOfs : Word; { obrazek ikony bodu }

      { * KURZORY MYSI * }
      NormalCursorSeg, NormalCursorOfs : Word;
      ActuallCursor : Word; { aktualni aktivni typ kurzoru mysi }

      { * NAHODNA CISLA * }
      RandomArray:array[0..MaxRandomArrayIndex] of Byte;
      RndUk:Byte;

      { * ODCHYTANI CHYB * }
      TimeSlot:Word; { cislo slotu }

      { * SAVE/LOAD *}
      SavePath:String;
      SaveSlotId:String;
      IOFile : File;
      CheckFile : File;
      DResult:Word;

      { * * }
      CoreStruct:array[0..MaxCoreUnits-1] of record
      { pro potreby tlacitka "Jadro" }
      { Neukladat tyto promenne:
         X1,Y1,X2,Y2:Word;
         XPicture,YPicture,XName,YName,XRank,YRank:Word;}
               Activity:Boolean;  { platnost }
               UniqueNumber:Word; { typ jednotky }
               X1,Y1,X2,Y2:Word;  { souradnice obdelniku }
               XPicture,YPicture,XName,YName,XRank,YRank:Word;
               Selected:Boolean;
               { souradnice dat }
             end;
      CoreSelectedCount:Byte; { pocet zvolenych jednotek jadra }

      { * JEDNOTKY * }
      ReserchAssign : array[1..MaxTypesOfUnits,0..1] of record
                         UnitAvail:Byte; { 0 pokud neni k dispozici
                                           (napr. neni vyzkoumana) }
                         ForPlayer:Boolean; { True - hrac muze tuto zbran
                                              pouzit k prirazeni vyzkumu }
                         { nyni prirazeni vynalezu k jednotlivym kategoriim
                           (0 znamena nic neprirazeno }
                         Attack1,Attack2:Byte;
                         Defence1,Defence2:Byte;
                         Sight1,Sight2:Byte;
                         Engine1,Engine2:Byte;
                         Special1, Special2:Byte;
                         _u,_o,_k,_lu,_tu,_au,_r,_d,_h,_s,_BP,_EE,_PL,_Ex:Single;
                      end;

      Kdce,Kadence : array[0..10] of Byte; { jednotlive rychlosti strelby }
      Unit_pictures : array[1..MaxTypesOfUnits] of record
                         S,O:Word;
                      end;
      Unit_target_types : array[1..MaxTypesOfUnits] of TUnitCtg;

      { * INFORMACE O TYPU BUDOV * }
      Building_types : array[1..MaxTypesOfBuildings] of record
      { ulozene informace o kazdem typu budovy; indexem je
       identifikacni cislo budovy; k nemu se pak pricita Rasa, k niz
       budova patri }
                      Production_time:Single; { za jeden tah se pri vyrobe
                      vyrobi Production_time procent budovy }
                      BP,PL,EE,EX : Word;
                      { materialy, potrebne k vyrobe budovy }
                      S1,O1,S2,O2,S3,O3,S6,O6,S7,O7: Word;
                      { segment+offset; prvni 3 obrazky jsou obrazky
                        stavici se budovy; obrazky 4 a 5 jsou hotove
                        budovy, ktere se po fazich stridaji;
                        faze 6 a 7 jsou polorozborene budovy }
                      {S:Word; { Segment predloh budov }
                      SO:array[0..MaxBuildingPhase] of record
                            S,O:Word; { animacni faze }
                         end;
                      MaxBuildPhase:Byte;
                      SBurn, OBurn : Word;
                      { ulozena informace o predloze budov v pameti
                        ve tvaru Segment-Offset; jde o obrazek poskozene
                        budovy (s kourem) }
                      XBuildingSize, YBuildingSize:Word;
                      { velikost budovy v bodech }
                      IBuildingSize, JBuildingSize:Word;
                      { velikost budovy v polich }
                      DefenceStrength:Word; { sila obrany }
                      Name : String[15]; { nazev }
                      ProductionType : Byte; { typ produkce :
                      0 .. jednotky, 1 .. budova, 2 .. plasty,
                      3 .. elektricka energie, 4 .. nic }
                      Production : array[0..8] of Byte;
                      { indexy do pole Unit_types nebo Building_types
                        jednotek (budov), ktere je mozne vyrabet }
                      MaxIndex : Byte; { index posledni obsazene polozky
                      pole Production }
                      SmallPictS, SmallPictO : Word; { Segment, Offset
                      maleho informacniho obrazku budovy }
                      Sight : Byte; { dohled budovy }
                      Parent : Byte; { typ materske budovy }
                      Autorepair :Byte; { urcuje pocet procent poskozeni,
                      ktere je jednotka sama schopna opravit (zdarma);
                      napr. pro hodnotu 5 se automaticky opravi jakekoli
                      poskozeni pro DefenceStrength >= 95% }
                   end;

       PlayerId:String[8]; { identifikace hrace }
       Game,Campaign:Byte; { identifikace hry }
       MaxMissionCoreUnits:Byte; { max. pocet jednotek jadra pro misi }
       _GameLevel:Byte;    { obtiznost hry 0.. nizka, 4..vysoka}

       TempGM,GlobalModify : record { neukladat save/load }
                      { globalni modifikace pro misi }
                         PlayerId:String[8]; { identifikace hrace }
                         Game,Campaign:Byte; { identifikace hry }
                         { modifikace typu jednotek: }
                         UnitTypes:TUnit_types;
                         { seznam jednotek, ktere nevyrabim ja: }
                         MyUnitsForMission:TUnitsForMission;
                         { nasledujici promenne urcuji pritomnost jednotek
                           s nastavenym nejvyssim bitem SpecNumber: }
                         FriendlySpecialUnitsPresent:Boolean;
                         EnemySpecialUnitsPresent:Boolean;
                         { True pro pritomnost spec. nepratelskych posil }
                         EnemySpecialReinforcementPresent:Boolean;
                         ActionLevel:Byte; { typ hry }
                         GameLevel:Byte;   { obtiznost hry 0.. nizka, 2..vysoka}
                         { nyni schema pro nasledujici hodnoty:
                           0..False, 1..True, > 1..nezmeneno }
                         UnknownTerrain, FogOfWar, AllyFog:Byte;
                         { modifikatory typu rasy:
                           bud hodnota, nebo 255=zustat nezmenene }
                         RaceTypeModifiers: array[0..MaxRace] of Byte;
                         { modifikatory materialu v misi :
                           bud hodnota zmeny v %, nebo MaxInt=zustat nezmenene
                           pozn. TYTO procenta se PRICTOU NAVIC k puvodni
                           hodnote }
                         RaceMaterialModifiers: array[0..MaxRace] of record
                                                   BPModif, PLModif,
                                                   EEModif, ExpMOdif:Integer;
                                                 end;
                         { modifikatory inicializacni vyrobni hodnosti rasy:
                           bud prirustek k hodnote, nebo 255=zustat nezmenene}
                         RaceInitLevelModifier: array[0..MaxRace] of Byte;
                         CoreInfo:array[0..MaxCoreUnits-1] of TUnitInfo;
                         { nyni pomocne hodnoty, inicializovane na 255 }
                         Temp1, Temp2, Temp3 :Word;
                         Temp4 : array[0..20] of Word;
                      end;

    { * data, pouzivana mezi misemi * }
    CoreInfo:array[0..MaxCoreUnits-1] of TUnitInfo;
    Victory:Integer; { 0..remiza, 1..vitezstvi, -1..porazka }
    POI, VICTORYPOI:LongInt; { result z real-time }

procedure Error(Result : Word; Msg : String );
procedure SoundPlay(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
function Rand(var RandomUk:Byte):Byte;
procedure InvalidateCache;
function CacheDataInvalid(Way:String):Boolean;
function CacheInit:Boolean;
function CacheFetch(FileName:String):Word;
procedure CacheSeek(var InFile:File; Pos:LongInt);
function CacheEof(var InFile:File):Boolean;
procedure CacheBlockRead(var InFile:File; Place:Pointer; Count:Word);
procedure Close_gr_mode;
procedure GetSpecKeysState;
function ReadKeys(var Scan:Byte):Byte;
function ReadKeys2(var Scan:Byte):Byte;
procedure SetDelay(Delay:Byte);
function GetAccurateDelay(Del:Word):Word;
procedure SetTerminator_fighterParams(LowPrice:Boolean);
procedure SaveGameCfg;
procedure LoadGameCfg;
procedure SaveMain;
procedure GLB_save(Path:String);
procedure GLB_load(Path:String);

{ ************************************************************************* }
implementation

uses Graph257;{}

var I,J,K:Word;

procedure TReinfo.Init;
{ inicializace
}
var I:Word;
begin
   for I:=0 to MaxCoreUnits-1 do begin
      CoreInfo[I].Active:=False; CoreInfo[I].Level:=255;
      CoreInfo[I].Experience:=0; CoreInfo[I].Kills:=0;
      CoreInfo[I].Destroyed:=False;
   end; Uk:=0;
end;

{ ***** }
procedure TReinfo.First;
{ nmastaveni na prvni prvek prochazeni
}
begin
   Uk:=0;
   if (not CoreInfo[Uk].Active) then Uk:=255;
end;

{ ***** }

procedure TReinfo.Next;
{ presune se na nasledujici polozku
}
begin
   Inc(Uk);
   if ((Uk > (MaxCoreUnits-1)) or
       (not CoreInfo[Uk].Active))
   then Uk:=255;
end;

{ ***** }
function TReinfo.GetActive(var TUI:TUnitInfo):Boolean;
{ vrati aktivni prvek + uspech operace
}
begin
   if (UK <> 255) then begin
     TUI:=CoreInfo[Uk];
     GetActive:=True;
   end else GetActive:=False;
end;

function TReinfo.GetUnique(UniqueNum:Word; var TUI:TUnitInfo):Boolean;
{
}
var I:Word;
    Konec:Boolean;
begin
   I:=0; Konec:=False; GetUnique:=False;
   while ((I < MaxCoreUnits) and (not Konec)) do begin
      if ((CoreInfo[I].Active) and (CoreInfo[I].UniqueNumber = UniqueNum))
      then begin
         Konec:=True; TUI:=CoreInfo[I]; GetUnique:=True;
      end else Inc(I);
   end;
end;

{ ***** }
function  TReinfo.Invalid:Boolean;
{
}
begin
   if (Uk = 255) then Invalid:=True else Invalid:=False;
end;

{ ***** }
procedure TReinfo.Insert(TUI:TUnitInfo);
{ pro Level = 255 vypocita novou Level uroven z Experience, Kills
}
var I:Word;
    Konec:Boolean;
begin
   I:=0; Konec:=False;
   while ((I < MaxCoreUnits) and (not Konec)) do begin
      if (not CoreInfo[I].Active) then begin
        Konec:=True;
        CoreInfo[I]:=TUI; CoreInfo[I].Active:=True; CoreInfo[I].Destroyed:=False;
        if (CoreInfo[I].Level = 255) then with (CoreInfo[I]) do begin
           Level:=0;
           { vypocitame novou hodnost }
           if ((Experience >= Experience12) and (Kills >= Kills12)) then begin
             Experience:=Experience12; {Kills:=Kills12;{}
             Level:=12;
           end else
            if ((Experience >= Experience11) and (Kills >= Kills11)) then begin
              Level:=11;
            end else
             if ((Experience >= Experience10) and (Kills >= Kills10)) then begin
               Level:=10;
             end else
              if ((Experience >= Experience9) and (Kills >= Kills9)) then begin
                Level:=9;
              end else
               if ((Experience >= Experience8) and (Kills >= Kills8)) then begin
                 Level:=8;
               end else
                if ((Experience >= Experience7) and (Kills >= Kills7)) then begin
                  Level:=7;
                end else
                 if ((Experience >= Experience6) and (Kills >= Kills6)) then begin
                   Level:=6;
                 end else
                  if ((Experience >= Experience5) and (Kills >= Kills5)) then begin
                    Level:=5;
                  end else
                   if ((Experience >= Experience4) and (Kills >= Kills4)) then begin
                     Level:=4;
                   end else
                    if ((Experience >= Experience3) and (Kills >= Kills3)) then begin
                      Level:=3;
                    end else
                     if ((Experience >= Experience2) and (Kills >= Kills2)) then begin
                       Level:=2;
                     end else
                      if ((Experience >= Experience1) and (Kills >= Kills1)) then begin
                        Level:=1;
                      end else Level:=0;
        end else
        if ((CoreInfo[I].Level > 0) and (CoreInfo[I].Experience = 0))
        then with (CoreInfo[I]) do begin
        { dle hodnosti ohodnotime experience a kills }
           case (Level) of
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
             Experience:= 0; Kills:= 0;
           end;
        end;
        Inc(LastUniqueNumber);
        CoreInfo[I].UniqueNumber:=LastUniqueNumber;
      end else Inc(I);
   end;
end;

{ ***** }
procedure TReinfo.Delete(UniqueNum:Word);
{
}
var I,J:Word;
    Konec:Boolean;
begin
   I:=0; Konec:=False;
   while ((I < MaxCoreUnits) and (not Konec)) do begin
      if ((CoreInfo[I].Active) and (CoreInfo[I].UniqueNumber = UniqueNum))
      then begin
        Konec:=True;
        for J:=I+1 to MaxCoreUnits-1 do begin
           CoreInfo[J-1]:=CoreInfo[J];
        end;
        if (J >= MaxCoreUnits) then J:=I;
        CoreInfo[J].Active:=False;
        CoreInfo[J].Level:=255;
        if (Uk = J) then Uk:=255;

      end else Inc(I);
   end;
end;

{ ***** }
procedure TReinfo.Update(UniqueNum:Word; TUI:TUnitInfo);
{ pro Level = 255 vypocita novou Level uroven z Experience, Kills
}
var I:Word;
    Konec:Boolean;
begin
   I:=0; Konec:=False;
   while ((I < MaxCoreUnits) and (not Konec)) do begin
      if ((CoreInfo[I].Active) and (CoreInfo[I].UniqueNumber = UniqueNum))
      then begin
        Konec:=True;
        CoreInfo[I]:=TUI;
        if (CoreInfo[I].Level = 255) then with (CoreInfo[I]) do begin
           Level:=0;
           { vypocitame novou hodnost }
           if ((Experience >= Experience12) and (Kills >= Kills12)) then begin
             Experience:=Experience12; {Kills:=Kills12;{}
             Level:=12;
           end else
            if ((Experience >= Experience11) and (Kills >= Kills11)) then begin
              Level:=11;
            end else
             if ((Experience >= Experience10) and (Kills >= Kills10)) then begin
               Level:=10;
             end else
              if ((Experience >= Experience9) and (Kills >= Kills9)) then begin
                Level:=9;
              end else
               if ((Experience >= Experience8) and (Kills >= Kills8)) then begin
                 Level:=8;
               end else
                if ((Experience >= Experience7) and (Kills >= Kills7)) then begin
                  Level:=7;
                end else
                 if ((Experience >= Experience6) and (Kills >= Kills6)) then begin
                   Level:=6;
                 end else
                  if ((Experience >= Experience5) and (Kills >= Kills5)) then begin
                    Level:=5;
                  end else
                   if ((Experience >= Experience4) and (Kills >= Kills4)) then begin
                     Level:=4;
                   end else
                    if ((Experience >= Experience3) and (Kills >= Kills3)) then begin
                      Level:=3;
                    end else
                     if ((Experience >= Experience2) and (Kills >= Kills2)) then begin
                       Level:=2;
                     end else
                      if ((Experience >= Experience1) and (Kills >= Kills1)) then begin
                        Level:=1;
                      end else Level:=0;
        end;
      end else Inc(I);
   end;
end;

{ ***** }
function TReinfo.GetThisUnitTypeCount(UnitType:Byte):Byte;
{ vrati pocet jednotek daneho typu v jadru
}
var Return:Byte;
    Konec:Boolean;
    I:Word;
begin
   I:=0; Konec:=False; Return:=0;
   while ((I < MaxCoreUnits) and (not Konec)) do begin
     if ((CoreInfo[I].Active) and (CoreInfo[I].UniqueNumber <> 65535)) then begin
        if (CoreInfo[I].UnitType = UnitType) then Inc(Return);
     end;
     Inc(I);
   end;
   GetThisUnitTypeCount:=Return;
end;

{ ***** }
function TReinfo.Full:Boolean;
{ vraci True, je-li v jadru plno
}
var Return:Boolean;
    I:Word;
begin
   I:=0; Return:=True;
   while (I < MaxCoreUnits) do begin
     if ((CoreInfo[I].Active) and (CoreInfo[I].UniqueNumber <> 65535)) then begin
     end else Return:=False;
     Inc(I);
   end;
   Full:=Return;
end;

{ ************************************************************************** }
procedure InvalidateCache;
{ znehodnoti data v cache
}
begin
   CacheValidity:=False;
end;

{ ***** }
function CacheDataInvalid(Way:String):Boolean;
{ vraci True, jsou-li data v cache neplatna
}
begin
   if ((not CacheValidity) or (SCache = 0))
   then CacheDataInvalid:=True
   else CacheDataInvalid:=False;
end;

{ ***** }
function CacheInit:Boolean;
{ provede inicializaci cache a sama vraci uspesnost operace
}
var I:Word;
    Result:Boolean;
    Pom:LongInt;
begin
   Result:=True; I:=0;
   Pom:=GlobalCompact(MaxCacheMemory); { pokus najit souvisly pas pameti }
   if (Pom >= MaxCacheMemory) then begin { pokus se zdaril }
      CacheUk:=GlobalAllocPtr(GMEM_FIXED,MaxCacheMemory);
      if (CacheUk <> Nil) then begin { allocation success }
        SCache:=Seg(CacheUk^); OCache:=Ofs(CacheUk^);
        SCacheUk:=SCache; OCacheUk:=OCache;
      end else Result:=False;
   end else Result:=False;
   CachePos:=0; CacheSize:=0;
   CacheInit:=Result;
end;

{ ***** }
function CacheFetch(FileName:String):Word;
{ funkce natahne soubor FileName do cache; sama funkce pak vraci vysledek
  operace; vraci-li 65535, je cachovany soubor prilis velky
}
label Konec, Skip;
var InFile:File;
    Result:Word;
    I,Delka1, Delka2,S,O:Word;
    PomUk:Pointer;
begin
   Result:=0; PomUk:=CacheUk;
   Assign(InFile,FileName);
   Reset(InFile,1); Result:=IOResult; if (Result <> 0) then GoTo Konec;
   CacheSize:=FileSize(InFile);
   if (CacheSize> MaxCacheMemory) then begin Result:=65535; GoTo Konec; end;
   { nyni rozdelime vstup na bloky po MaxCacheBlockSize bytu }
   Delka1:=CacheSize div 65535; Delka2:=CacheSize mod 65535;
   S:=Seg(PomUk); O:=Ofs(PomUk);
   for I:=1 to Delka1 do begin
      BlockRead(InFile,PomUk^,65535);
      Result:=IOResult; if (Result <> 0) then GoTo Konec;
      {asm  { zvyseni ukazatele v PomUk^ }
      {  mov Ax,S; mov Es,Ax; mov Di,O;
        mov Ax,65535; mov Es:[Di],Ax; { zvys offset }
      {end;
      BlockRead(InFile,PomUk^,1);
      Result:=IOResult; if (Result <> 0) then GoTo Konec;{}
      asm  { zvyseni ukazatele v PomUk^ }
        mov Ax,S; mov Es,Ax; mov Di,O;
        mov Ax,0; mov Es:[Di],Ax; add Di,2
        mov Ax,Es:[Di]; add Ax,SelectorInc; mov Es:[Di],Ax
      end;
   end;
   BlockRead(InFile,PomUk^,Delka2);
   Result:=IOResult; if (Result <> 0) then GoTo Konec;
   CacheFile:=FileName; CacheValidity:=True;
   SCacheUk:=SCache; OCacheUk:=OCache;
   GoTo Skip;
Konec:
   CacheValidity:=False;
Skip:
   CachePos:=0;
   CacheFetch:=Result;
   Close(InFile);
end;

{ ***** }
procedure CacheSeek(var InFile:File; Pos:LongInt);
{ pokud jsou data v cache, provede seek v cache, jinak v souboru InFile
}
label Konec;
begin
   if CacheDataInvalid(CacheFile) then begin { provede se klasicky }
      Seek(InFile,Pos);
      IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   end else begin { pouzije se cache }
      SCacheUk:=SCache + (Pos div 65535)*SelectorInc;
      OCacheUk:=Pos mod 65535;
      CachePos:=Pos;
   end;
Konec:
end;

{ ***** }
function CacheEof(var InFile:File):Boolean;
{
}
begin
  if CacheDataInvalid(CacheFile) then begin { provede se klasicky }
     CacheEof:=Eof(InFile);
     IO_Result:=IOResult;
  end else begin { pouzije se cache }
     if (CachePos >= CacheSize) then CacheEof:=True else CacheEof:=False;
  end;
end;

{ ***** }
procedure CacheBlockRead(var InFile:File; Place:Pointer; Count:Word);
{ pokud jsou data v cache, provede seek v cache, jinak v souboru InFile
}
label Konec;
var I,S,O,Pom,IncSelector:Word;
    Suda:Word;
begin
   if CacheDataInvalid(CacheFile) then begin { provede se klasicky }
     BlockRead(InFile,Place^,Count);
     IO_Result:=IOResult; if (IO_Result <> 0) then GoTo Konec;
   end else begin { pouzije se cache }
     Inc(CachePos,Count);
     if (Count <> 2) then begin { cokoli, jen ne word }
       S:=Seg(Place^); O:=Ofs(Place^);
       IncSelector:=SelectorInc;
       if ((Count > 9) and ((65535-OCacheUk) >= Count) and ((Count shr 1) shl 1 = Count))
       then asm { preneseme po slovech }
          mov Cx,Count { pocet prenesenych bytu }
          shr Cx,1
          mov Ax,S
          mov Es,Ax
          mov Di,O  { adresa cile }
          mov Ax,SCacheUk
          mov Si,OCacheUk
          push Ds
          mov Ds,Ax { adresa zdroje }
          cld
@again:
          movsw
          loop @again
@end:
          mov Ax,Ds         { obnova cache ukazatelu }
          pop Ds
          mov SCacheUk,Ax
          mov OCacheUk,Si
       end else asm  { preneseme po bytech }
          mov Cx,Count { pocet prenesenych bytu }
          mov Ax,S
          mov Es,Ax
          mov Di,O  { adresa cile }
          mov Ax,SCacheUk
          mov Si,OCacheUk
          push Ds
          mov Ds,Ax { adresa zdroje }
          cld
@again:
          movsb
          cmp Si,65535
          je @SelectorInc
          loop @again
          jmp @end
@SelectorInc:
          mov Ax,Ds; add Ax,IncSelector; mov Ds,Ax; mov Si,0
          loop @again
@end:
          mov Ax,Ds         { obnova cache ukazatelu }
          pop Ds
          mov SCacheUk,Ax
          mov OCacheUk,Si
       end;
     end else begin { prenasi se slovo - je treba nahrat poradi Lo-Hi }
       S:=Seg(Place^); O:=Ofs(Place^);
       IncSelector:=SelectorInc;
       asm  { Inc(Place) }
          mov Cx,Count { pocet prenesenych bytu }
          mov Ax,S
          mov Es,Ax
          mov Di,O  { adresa cile }
          mov Ax,SCacheUk
          mov Si,OCacheUk
          push Ds
          mov Ds,Ax { adresa zdroje }
          cld
@again:
          mov Al,Ds:[Si]
          inc Si
          cmp Si,65535
          jne @1
          mov Ax,Ds; add Ax,IncSelector; mov Ds,Ax; mov Si,0
@1:
          mov Ah,Ds:[Si]
          inc Si
          cmp Si,65535
          jne @2
          mov Ax,Ds; add Ax,IncSelector; mov Ds,Ax; mov Si,0
@2:
          mov Es:[Di],Ax

          mov Ax,Ds         { obnova cache ukazatelu }
          pop Ds
          mov SCacheUk,Ax
          mov OCacheUk,Si
       end;
     end;
   end;
Konec:
end;

{ ***** }
function Rand(var RandomUk:Byte):Byte;
{ vraci nahodne cislo z rozmezi 0-9
}
begin
   Rand:=RandomArray[RandomUk];
   Inc(RandomUk);
   if (RandomUk > MaxRandomArrayIndex) then RandomUk:=0;
end;

{ ***** }
procedure Close_gr_mode;
{ ukonci graficky rezim a odalokuje vsechny data z pameti
}
begin
   {GlobalDosFree(Timer_flag_selector);{}
   FinishMouse;
   CloseGraph;
end;

{ ***** }
procedure GetSpecKeysState;
{ Nacita stav specialnich klaves (shift, ctrl atd.) a dle toho
  nastavuje promenne SHIFT, CTRL, ALT na True (False) dle toho, jsou-li
  aktivni
}
var State,S,C,A : Word;
begin
   asm
     mov Ah,12h
     int 16h
     mov State,Ax
     and Ax,3
     mov S, Ax  { SHIFT }
     mov Ax,State
     and Ax,4
     mov C, Ax  { CTRL }
     mov Ax,State
     and Ax,8
     mov A, Ax  { ALT }
   end;
   SHIFT:=(S <> 0);
   CTRL:=(C <> 0);
   ALT:=(A <> 0);
end;

{ ***** }
function ReadKeys(var Scan:Byte):Byte;
{ vraci aktualni stav klavesnice+pripadnou hodnotu v a.tvaru
  (scan je parametr); pokud je stisknuta klavesa, rutina soucastne
  odstrani znak z bufferu
  v klidovem stavu vraci 0
}
var Scans:Byte;
begin
    asm
      mov Scans,0
      mov Ah,11h
      Int 16h
      jz @empty
      mov @Result,Al
      mov Scans,Ah
      mov Ah,10h
      Int 16h
      jmp @end
@empty:
      mov Scans,0
      mov @Result,0
@end:
    end;
    Scan:=Scans;
end;

{ ***** }
function ReadKeys2(var Scan:Byte):Byte;
{ rutina ceka na stisk klavesy
}
var Scans:Byte;
begin
    asm
      mov Ah,10h
      Int 16h
      mov @Result,Al
      mov Scans,Ah
    end;
    Scan:=Scans;
end;

{ ***** }
procedure Error(Result : Word; Msg : String );
{ ukonci program s chybou
  je-li promenna Result = 0, vypise se pouze retezec Msg
  je-li promenna Result <> 0 a zaroven je Result v rozmezi 30..45
  (chyby pri praci s GRAPH256), vypise se cislo chyby Result a
  specifikace chyby IO_ResultString
  jinak se vypise cislo chyby Result a retezec Msg
}
var Pom:Byte;
    I:Word;
    PomStr:String;
begin
   I:=IOResult;
   for I:=1 to Length(Msg) do Msg[I]:=Upcase(Msg[I]);
   Str(Result,PomStr);
   if (Result <> 0) then begin
      if ((Result >= 30) and (Result <= 45)) then ErrorString:='CHYBA '+Msg
      else ErrorString:='CHYBA '+Msg+' - DISKOVA CHYBA CISLO '+ PomStr;
   end else begin
      ErrorString:='CHYBA - '+ Msg;
   end;
   Halt(65535);
end;

{ **** }
procedure SoundPlay(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
{ zahraje zvuk
}
begin
   PlaySound(SoundType,Volume+1,Index1,Index2);
end;

{ ***** }
procedure SetDelay(Delay:Byte);
{
}
begin
   case (Delay) of
     3 : begin  Del1:=3;  Del2:=20000; end;
     2 : begin  Del1:=2;  Del2:=50000; end;
     1 : begin  Del1:=1;  Del2:=30000; end;
     { nejrychlejsi }
   else
   end;
end;

{ ***** }
function GetAccurateDelay(Del:Word):Word;
{ procedura prepocita zpozdeni, pocitane na maximalni rychlost, na aktualni
  rychlost
}
const Modif3 = 0.4; Modif4 = 0.65; Modif5 = 1.0;
var Pom:Double;
begin
   Pom:=Del;
   case (Del1) of
     3 : begin Pom:=Pom*Modif3; GetAccurateDelay:=Round(Pom);  end;
     2 : begin Pom:=Pom*Modif4; GetAccurateDelay:=Round(Pom);  end;
     1 : begin Pom:=Pom*Modif5; GetAccurateDelay:=Round(Pom);  end;
   else
     Pom:=0;
   end;
   if (Round(Pom) = 0) then GetAccurateDelay:=1;
end;

{ ***** }
procedure SetTerminator_fighterParams(LowPrice:Boolean);
{ procedura nastavi odlisne parametry a cenu vyroby stihace a terminatora
  LowPrice=cena pro pocitac
}
begin
   { STIHAC }
   with (Unit_types^[18,0]) do begin
     LightAttack1:=250; HeavyAttack1:=215; AirAttack1:=270;
     BP:=280; PL:=35; EE:=200; EX:=40 div 3;
   end;
   with (Unit_types^[18,1]) do begin
     LightAttack1:=250; HeavyAttack1:=215; AirAttack1:=270;
     if (LowPrice) then begin
       BP:=280; PL:=35; EE:=200; EX:=40 div 3;
     end else begin
       BP:=380; PL:=75; EE:=200; EX:=40;
     end;
   end;
   { TERMINATOR }
   with (Unit_types^[19,0]) do begin
     LightAttack1:=380; HeavyAttack1:=540; AirAttack1:=50;
     BP:=250; PL:=40; EE:=195; EX:=45 div 3;
   end;
   with (Unit_types^[19,1]) do begin
     LightAttack1:=380; HeavyAttack1:=540; AirAttack1:=50;
     if (LowPrice) then begin
       BP:=250; PL:=40; EE:=195; EX:=45 div 3;
     end else begin
       BP:=350; PL:=80; EE:=195; EX:=45;
     end;
   end;
end;

{ ***** }
procedure SaveGameCfg;
{ ulozi nektera nastaveni hry
}
begin
  Assign(IOFile,PathStrGlobal+'game.cfg'); ReWrite(IOFile,1);
  DResult:=IOResult;
     if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;

{x}BlockWrite(IOFile,XResolution,SizeOf(XResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,YResolution,SizeOf(YResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;

  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure LoadGameCfg;
{ nahraje nektera nastaveni hry
}
label K;
var MaxRes:Word;
begin
  XResolution:=640; YResolution:=480;
  Assign(IOFile,PathStrGlobal+'game.cfg'); Reset(IOFile,1);
  DResult:=IOResult;
  if (DResult = 2) then
    GoTo K { soubor neexistuje, nic se neprovede }
  else
    if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;

{x}BlockRead(IOFile,XResolution,SizeOf(XResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,YResolution,SizeOf(YResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;

   GetMaxRes(MaxRes);
   case (MaxRes) of
     0 : begin
            if (XResolution > 640) then begin
              XResolution:=640; YResolution:=480;
            end;
         end;
     1 : begin
            if (XResolution > 800) then begin
              XResolution:=800; YResolution:=600;
            end;
         end;
     2 : begin
           if (XResolution > 1024) then begin
              XResolution:=1024; YResolution:=768;
            end;
         end;
     3 : begin { maximum, bez omezeni }
         end;
   else
     XResolution:=640; YResolution:=480;
   end;

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure SaveMain;
{ ulozi main informace
}
var IOFile:File;
begin
   Assign(IOFile,PathStr+'main.cfg'); ReWrite(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then Error(DResult,'chyba pri ukladani "main.cfg"');
{x}BlockWrite(IOFile,CancelGame,SizeOf(CancelGame));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "main.cfg"');
{x}BlockWrite(IOFile,Game,SizeOf(Game));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "main.cfg"');
{x}BlockWrite(IOFile,PlayerId,SizeOf(PlayerId));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "main.cfg"');
{x}BlockWrite(IOFile,GameUniqueNum,SizeOf(GameUniqueNum));
   DResult:=IOResult;if(DResult<>0)then Error(DResult,'chyba pri ukladani "main.cfg"');

   Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure GLB_save(Path:String);
{ pro potreby ulozeni hry
}
label K;

begin
  Assign(CheckFile,PathStr+'save\'+SavePath+'\check.glb'); ReWrite(CheckFile,1); DResult:=IOResult;
  Close(CheckFile); DResult:=IOResult;
  Assign(IOFile,PathStr+'save\'+SavePath+'\'+Path); ReWrite(IOFile,1); DResult:=IOResult;
  if (DResult<>0) then begin Erase(CheckFile);GoTo K;end;

{x}BlockWrite(IOFile,PlayerName,SizeOf(PlayerName));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,PlayerUniqueNum,SizeOf(PlayerUniqueNum));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TOTALPOINTS,SizeOf(TOTALPOINTS));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,LOSTB,SizeOf(LOSTB));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,LOSTU,SizeOf(LOSTU));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,KILLEDB,SizeOf(KILLEDB));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,KILLEDU,SizeOf(KILLEDU));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,VICTORYNUM,SizeOf(VICTORYNUM));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,CORELOST,SizeOf(CORELOST));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{x}BlockWrite(IOFile,ResearchRandom,SizeOf(ResearchRandom));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ResearchRandomStep,SizeOf(ResearchRandomStep));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalModify,SizeOf(GlobalModify));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * DATA O ROZLISENI  * }
{x}BlockWrite(IOFile,XResolution,SizeOf(XResolution));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YResolution,SizeOf(YResolution));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ *  * }
{x}BlockWrite(IOFile,Core,SizeOf(Core));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,LastUniqueNumber,SizeOf(LastUniqueNumber));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MovementStep,SizeOf(MovementStep));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TextMode,SizeOf(TextMode));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OldRetLength,SizeOf(OldRetLength));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OSNPlayer,SizeOf(OSNPlayer));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  {!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
{x}BlockWrite(IOFile,MissionNameString,SizeOf(MissionNameString));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  {!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
{x}BlockWrite(IOFile,Del1,SizeOf(Del1));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Del2,SizeOf(Del2));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MyUnitsForMission,SizeOf(MyUnitsForMission));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OtherUnitsForMission,SizeOf(OtherUnitsForMission));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BuildingsForMission,SizeOf(BuildingsForMission));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * GLOBALNI STAV * }
{x}BlockWrite(IOFile,Points,SizeOf(Points));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,VictoryPoints,SizeOf(VictoryPoints));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * VYZKUM * }
{x}BlockWrite(IOFile,GlobalSelectedResearch,SizeOf(GlobalSelectedResearch));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Research^,SizeOf(Research^));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * NAHODNA CISLA * }
{x}BlockWrite(IOFile,RandomArray,SizeOf(RandomArray));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,RndUk,SizeOf(RndUk));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * ODCHYTANI CHYB * }
{x}BlockWrite(IOFile,TimeSlot,SizeOf(TimeSlot));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * JADRO * }
{x}BlockWrite(IOFile,CoreSelectedCount,SizeOf(CoreSelectedCount));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  for I:=0 to MaxCoreUnits-1 do begin
     BlockWrite(IOFile,CoreStruct[I].Activity,SizeOf(CoreStruct[I].Activity));
     DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     BlockWrite(IOFile,CoreStruct[I].UniqueNumber,SizeOf(CoreStruct[I].UniqueNumber));
     DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     BlockWrite(IOFile,CoreStruct[I].Selected,SizeOf(CoreStruct[I].Selected));
     DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  end;
{ * JEDNOTKY * }
{x}BlockWrite(IOFile,ReserchAssign,SizeOf(ReserchAssign));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Kadence,SizeOf(Kadence));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Unit_types^,SizeOf(Unit_types^));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Unit_target_types,SizeOf(Unit_target_types));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O MISI * }
{x}BlockWrite(IOFile,PlayerId,SizeOf(PlayerId));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Game,SizeOf(Game));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Campaign,SizeOf(Campaign));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MaxMissionCoreUnits,SizeOf(MaxMissionCoreUnits));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MissionNum,SizeOf(MissionNum));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GameUniqueNum,SizeOf(GameUniqueNum));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Week,SizeOf(Week));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,EnemyRaces,SizeOf(EnemyRaces));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,_GameLevel,SizeOf(_GameLevel));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O TYPU BUDOV * }
   for I:=1 to MaxTypesOfBuildings do with (Building_types[I]) do begin
   {x}BlockWrite(IOFile,Production_time,SizeOf(Production_time));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,BP,SizeOf(BP));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,PL,SizeOf(PL));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,EE,SizeOf(EE));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,EX,SizeOf(EX));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MaxBuildPhase,SizeOf(MaxBuildPhase));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,XBuildingSize,SizeOf(XBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,YBuildingSize,SizeOf(YBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,IBuildingSize,SizeOf(IBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,JBuildingSize,SizeOf(JBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,DefenceStrength,SizeOf(DefenceStrength));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Name,SizeOf(Name));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,ProductionType,SizeOf(ProductionType));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Production,SizeOf(Production));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,MaxIndex,SizeOf(MaxIndex));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Sight,SizeOf(Sight));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Parent,SizeOf(Parent));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Autorepair,SizeOf(Autorepair));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;

K:
  Close(IOFile); DResult:=IOResult;{}
end;

{ ***** }
procedure GLB_load(Path:String);
{ pro potreby ulozeni hry
}
label K;
var Pom:Word;
begin
  Assign(CheckFile,PathStr+'save\'+SavePath+'\check.glb');
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);

  Assign(IOFile,PathStr+'save\'+SavePath+'\'+Path); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0) then begin Erase(CheckFile);GoTo K;end;

{x}BlockRead(IOFile,PlayerName,SizeOf(PlayerName));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,PlayerUniqueNum,SizeOf(PlayerUniqueNum));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TOTALPOINTS,SizeOf(TOTALPOINTS));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,LOSTB,SizeOf(LOSTB));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,LOSTU,SizeOf(LOSTU));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,KILLEDB,SizeOf(KILLEDB));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,KILLEDU,SizeOf(KILLEDU));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,VICTORYNUM,SizeOf(VICTORYNUM));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,CORELOST,SizeOf(CORELOST));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{x}BlockRead(IOFile,ResearchRandom,SizeOf(ResearchRandom));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ResearchRandomStep,SizeOf(ResearchRandomStep));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalModify,SizeOf(GlobalModify));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * DATA O ROZLISENI  * }
   GetMaxRes(MaxRes);
{x}BlockRead(IOFile,XResolution,SizeOf(XResolution));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YResolution,SizeOf(YResolution));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  case (MaxRes) of
     0 : begin
            if (XResolution > 640) then begin
              XResolution:=640; YResolution:=480;
            end;
         end;
     1 : begin
            if (XResolution > 800) then begin
              XResolution:=800; YResolution:=600;
            end;
         end;
     2 : begin
           if (XResolution > 1024) then begin
              XResolution:=1024; YResolution:=768;
            end;
         end;
     3 : begin { maximum, bez omezeni }
         end;
  else
     XResolution:=640; YResolution:=480;
  end;
{x}BlockRead(IOFile,Core,SizeOf(Core));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,LastUniqueNumber,SizeOf(LastUniqueNumber));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MovementStep,SizeOf(MovementStep));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TextMode,SizeOf(TextMode));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OldRetLength,SizeOf(OldRetLength));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OSNPlayer,SizeOf(OSNPlayer));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  {!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
{x}BlockRead(IOFile,MissionNameString,SizeOf(MissionNameString));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  {!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
{x}BlockRead(IOFile,Del1,SizeOf(Del1));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Del2,SizeOf(Del2));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MyUnitsForMission,SizeOf(MyUnitsForMission));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OtherUnitsForMission,SizeOf(OtherUnitsForMission));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BuildingsForMission,SizeOf(BuildingsForMission));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * GLOBALNI STAV * }
{x}BlockRead(IOFile,Points,SizeOf(Points));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,VictoryPoints,SizeOf(VictoryPoints));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * VYZKUM * }
{x}BlockRead(IOFile,GlobalSelectedResearch,SizeOf(GlobalSelectedResearch));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Research^,SizeOf(Research^));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * NAHODNA CISLA * }
{x}BlockRead(IOFile,RandomArray,SizeOf(RandomArray));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,RndUk,SizeOf(RndUk));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * ODCHYTANI CHYB * }
{x}BlockRead(IOFile,TimeSlot,SizeOf(TimeSlot));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * JADRO * }
{x}BlockRead(IOFile,CoreSelectedCount,SizeOf(CoreSelectedCount));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  for I:=0 to MaxCoreUnits-1 do begin
     BlockRead(IOFile,CoreStruct[I].Activity,SizeOf(CoreStruct[I].Activity));
     DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     BlockRead(IOFile,CoreStruct[I].UniqueNumber,SizeOf(CoreStruct[I].UniqueNumber));
     DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     BlockRead(IOFile,CoreStruct[I].Selected,SizeOf(CoreStruct[I].Selected));
     DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
  end;
{ * JEDNOTKY * }
{x}BlockRead(IOFile,ReserchAssign,SizeOf(ReserchAssign));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Kadence,SizeOf(Kadence));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Unit_types^,SizeOf(Unit_types^));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Unit_target_types,SizeOf(Unit_target_types));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O MISI * }
{x}BlockRead(IOFile,PlayerId,SizeOf(PlayerId));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Game,SizeOf(Game));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Campaign,SizeOf(Campaign));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MaxMissionCoreUnits,SizeOf(MaxMissionCoreUnits));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MissionNum,SizeOf(MissionNum));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GameUniqueNum,SizeOf(GameUniqueNum));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Week,SizeOf(Week));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,EnemyRaces,SizeOf(EnemyRaces));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,_GameLevel,SizeOf(_GameLevel));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O TYPU BUDOV * }
   for I:=1 to MaxTypesOfBuildings do with (Building_types[I]) do begin
   {x}BlockRead(IOFile,Production_time,SizeOf(Production_time));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,BP,SizeOf(BP));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,PL,SizeOf(PL));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,EE,SizeOf(EE));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,EX,SizeOf(EX));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,MaxBuildPhase,SizeOf(MaxBuildPhase));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,XBuildingSize,SizeOf(XBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,YBuildingSize,SizeOf(YBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,IBuildingSize,SizeOf(IBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,JBuildingSize,SizeOf(JBuildingSize));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,DefenceStrength,SizeOf(DefenceStrength));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,Name,SizeOf(Name));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,ProductionType,SizeOf(ProductionType));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,Production,SizeOf(Production));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,MaxIndex,SizeOf(MaxIndex));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,Sight,SizeOf(Sight));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,Parent,SizeOf(Parent));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockRead(IOFile,Autorepair,SizeOf(Autorepair));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;

K:
  Close(IOFile); Close(CheckFile); Pom:=IOResult;
end;


{ ************************************************************************** }
begin
   CacheValidity:=False; SCacheUk:=0; SCache:=0;
   TimeSlot:=255;
   New(Research); New(Unit_types);
   if ((Research = Nil) or (Unit_types =Nil))
   then begin Writeln('Chyba - nedostatek pameti pro alokaci objektu'); Halt; end;
   for I:=1 to MaxResearch do Research^[I].Validity:=False;
   GlobalSelectedResearch:=0;
   ReserchInfoBckSeg:=0;
   Points:=0; VictoryPoints:=0;
   LastUniqueNumber:=0;
   Randomize;
   for I:=0 to MaxRandomArrayIndex do RandomArray[I]:=Random(10);
   LastButton:=255;
   Blue:=98; DarkBlue:=108; Yellow:=160; DarkYellow:=165; White:=66;
   Zrada:=False; ErrorString:='';
   ResearchRandomStep:=0; ResearchRandom:=0;
   PlayerName:='UNKNOWN';
end.