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

unit DATA;
{$C FIXED PRELOAD PERMANENT}
interface
uses Graph257, winapi,Mouse, Dos, SBSound;

const { * CACHE * }
      MaxCacheMemory = 550000;
const { * DATA O OBRAZOVCE * }
      IMaxSize = 113; JMaxSize = 113;
      { maximalni velikost mapy v polickach -1 }
      { nyni souradnice pro pole MapInfo, pouzivane AI }
      IInfoDiv = 10; JInfoDiv = 10;
      IInfoArraySize = IMaxSize div IInfoDiv + 1;
      JInfoArraySize = JMaxSize div JInfoDiv + 1;
      XCellSize = 32; YCellSize = 32; { velikost policka }
      X2xCellSize = 2*XCellSize; Y2xCellSize = 2*YCellSize;
      XCellShl = 5; YCellShl = 5; { pocet rotaci doleva, abych z polickoveho
      vyjadreni dostal bodove }

      { * DATA Dialogoveho boxu * }
      _YES = 0; _YES_NO = 1; _YES_NO_CANCEL = 2;
      YES = 0;
      NO  = 1;
      CANCEL = 2;

      { * FONT * }
      XFontSize = 8; { velikost pouziteho fontu }
      YFontSize = 10;

      { * SPECIALNI PANELY * }
      TempPictureMemory = 17000; { pro ukladani pomocnych veci - TempSeg }
      XWindow1Size = 320; YWindow1Size = 300;
      XInfoSize = 400; YInfoSize = 300; { velikost info panelu }
      { rozmery systemoveho (menu) okna }
      Window1Memory = 2*1024*64;{ zarovnano na nasobek 64KB }
      { maximalni rozmery a pamet vyuzitelneho okna }
      MaxXWindowSize = 600; MaxYWindowSize = 430;
      WindowMemory = 6*1024*64; { zarovnano na nasobek 64kB }
      MaxXWindowChrs = MaxXWindowSize div XFontSize;
      MaxYWindowChrs = MaxYWindowSize div YFontSize;

      { ! FORWARD ! } SmallButtonXSize = 44;

       { * VICTORY CONDITIONS * }
      const MaxCond = 5;

      { * SPEC * }
      { !!!!! } ActiveTargetSearch = True; { = True .. pokud jednotka
      nic nedela, testuje si, zda v dostrelu neni nejaky cil }
      IdleLimit = 110; { doba, po niz se muze jednotka nachazet ve stavu
      129 (cekani na odblokovani cesty; pokud se do teto doby nic nestane,
      prijde pokus o odblokovani) }
      IdleWait = 10; { je to v podstate doba, po kterou se jednotka nachazi
      ve stavu "odblokuj cestu", i kdyz nema Status = 129; jde o to, aby
      odblokovani bylo ucinne, a proto musi nejakou dobu trvat
      vice viz _units.Move2, _units.Free_place3,4 a _units2.Unit_manager }
      SpecAirUnitBlock = 200; { doba cekani na "doplneni paliva" u spec.
                                leteckych jednotek }

      { * TYP JEDNOTEK * }
      MaxTypesOfUnits = 44; { max. pocet typu jednotek ve hre }

      { * JEDNOTKY * }
      MaxUnits = 800; { maximalni pocet jednotek }
      MaxRaceUnits = 229; { maximalni pocet jednotek dane rasy -1 }
      MaxRace = 5; { udava po pricteni +1 pocet ruznych ras }
      MaxDist = 21; { max. velikost okoli*2 + 1 jednotky pro vypocet
      nejlepsi cesty presunu }
      Max_units_explosion_phase = 16;

      { * RECYKLATOR * }
      HarvestingSpeed = 0.4; { pocet naplneni recyklatoru/1 tah }
      HarvesterCapacity = 50; { kapacita recyklatoru }
      BPperMove = HarvestingSpeed*2;
      { odpocet materialu pri tezbe ze skladky / 1 tah }
      HarvesterUnloadSpeed = 2; { pocet procent vyprazdneni recyklatoru/1 tah }
      BPperMoveUnload = 1; { mnozstvi vylozeneho BP materialu z recyklatoru/1 tah}

      { * STRELY * }
      MaxMovingObjects = 127; { maximalni pocet pohyblivych objektu typu
                                strela  }

      { * TYP BUDOV * }
      MaxTypesOfBuildings = 25;

      { * BUDOVY * }
      MaxBuildings = 350; { maximalni pocet budov }
      MaxRaceBuildings = 179; { maximalni pocet budov dane rasy -1 }
      MaxBuildingPhase = 10; { maximalni pocet animacnich fazi jedne budovy }
      { !!!!! }BuildSpeed = 20; { po tomto case se postavi dalsi faze budovy }
      BuildPhaseSpeed = 5; { stridani fazi 4 a 5 u budov }
      {BuildingProductionSpeed = 4; { pocet tahu, po nichz se pripocitaji
      vyrobni procenta, pokud budova vyrabi ( vice viz:
      Building_types[BuildingType].Production_speed) }
      ECapacity = 60; { kapacita elektrarny }
      AcumulatorCapacity = 80; { kapacita akumulatoru }
      {}
      EEProductionDecrease = 5; { o kolik procent snizi vsechny elektrarny
      objem produkovane elektriny za kazdych celych EEProductionDecreaseVal
      hodnot naakumulovane elektriny v zasobe }
      EEProductionDecreaseVal = 140; { viz predchozi }
      {}
      EEProduction = 20; { kolik elektrarna vygeneruje EE energie
      behem jedne produkce }
      EEProductionSpeed = 40; { doba v tazich, po ktere dojde k pripocteni
      elektricke energie EEProduction (sude cislo) }
      PLProduction = 1; { kolik plastarna vyrobi plastu behem jedne produkce }
      PLProductionSpeed = 35; { doba v tazich, po ktere dojde k pripocteni
      plastu PLProduction (sude cislo) }
      PLProductionBPNeed = 1; { kolik je treba na vyrobu 1 varky plastu
      stavebniho materialu }
      PLProductionEENeed = 6; { kolik je treba na vyrobu 1 varky plastu
      elektricke energie }
      EEConsumption = 2; { spotreba el. energie u kazde budovy za dobu
      EEConsumptionSpeed }
      EEConsumptionSpeed = 20; { musi byt sude cislo }
      EELackDamage = 5.0; { pokud se po dobe EEConsumptionSpeed zjisti,
      ze je nedostatek elektricke energie, snizi se damage budovy
      o hodnotu EELackDamage  }

      { * POZADI * }
      Way = 0;  { maximalni index daneho terenu  - cesty }
      Grass = 1;{69;  { trava }
      Field = 2;{79;  { pole = trava }
      Resrc = 3;{94; { resource - "skladka" materialu }
      Desert = 4;{134; { poust = neexistuje }
      Hill = 5;   { kopec }
      Wather = 6;{189; { voda }
      Wood = 7;   { les }
      Airport = 8; { letiste }
      { nyni obrazky letiste }
      Airport1 =251; Airport2 =252; Airport3 =253; Airport4 =254;

      Clear = 0; Sand = 2; Snow = 1; Night = 3; Rain = 4; { pro TerrainCondition }

      { * USTUP * }
      RetreatTimmerValue = 1000; { doba trvani ustupu }

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
      MaxWarningBlingValue = 75; { doba blikani jednotky, je-li na ni utoceno }

      { * DEBRIS * }
      MaxDebris = 48; { max. pocet obrazku }
      DebrisPictureSize = 1028; { velikost trosek v pameti (32*32+4) }
      DebrisGiveUpIndex = 38; { 1. index v poli Debris, patrici symbolu vzdani se }
      DebrisFireIndex = 41; { 1. index v poli Debris, patrici kouri }
      DebrisFireSize = 1028; { misto, zabirajici debris kour }
      MaxDebrisInfoIndex = 200; { velikost-1 pole DebrisInfo }
      DebrisFireTimmerValue = 600; { po kolika casovych slotech zmizi kour }
      DebrisTimmerValue = 2500;{ po kolika casovych slotech zmizi trosky}
      HalfDebrisTimmerValue = 300; { po tomto intervalu trosky ztmavnou }
      { pozn. pri hrubem casovani se odecitaji 2, jinak 1}
      XDebrisFireAdd = 0; { vycentrovani koure }
      YDebrisFireAdd = 0;

      { * KURZOR MYSI * }
      XCursorSize = 32; { velikost kurzoru mysi }
      YCursorSize = 20;
      MaxCursorPhase = 8; { max. pocet fazi animovaneho kurzoru }

      WaitCursor        = 1; { typy kurzoru mysi - pro potrebu SetCursor }
      GroupingCursor    = 2;
      MoveCursor        = 3;
      GoInsideCursor    = 4;
      AttackCursor      = 5;
      WayPointRecCursor = 6;
      NormalCursor      = 7;
      NoCursor          = 8;
      NoAttackCursor    = 9;
      LoadCursor        = 10;
      LastCursorType    = 10; { posledni cislo kurzoru }

      { * TLACITKA * }
      { SmallButtonXSize = 38; *** deklarovano v predchozim textu }
      SmallButtonYSize = 16;{ velikost maleho tlacitka}
      BigButtonXSize = 200; BigButtonYSize = 25;{ velikost velkeho tlacitka}
      Button3XSize = 32; Button3YSize = 32;{ velikost specialniho tlacitka}
      MenuButton = 1;  { cislo tlacitka, vyvolavajiciho menu }
      StopButton = 2;  { cislo tlacitka, zastavujiciho hru }
      Stop = 3;    { cislo tlacitka, zastavujiciho jednotku }
      Patrol = 4;    { cislo tlacitka, zastavujiciho jednotku }
      Nalozit = 5; { cislo tlacitka, ktere provede nalozeni jednotky nekam }
      Vylozit = 6; { cislo tlacitka, ktere provede vylozeni obsahu }
      TabButton = 7; { tlacitko, umoznujici zpristupnit dalsi tlacitka }
      Rozlozit = 8; { rozlozi jednotku-budovu }
      Opravit = 9; { opravi jednotku }
      ZvednoutMoralku = 10; { zvedne moralku }
      RadarModButton = 21;  { prepinani modu radaru }
      SellButton = 22;  { prodani objektu }
      { * }
      _Grafika = 11; _Zvuk = 12; _Hra = 13; _NahratHru = 14;
      _UlozitHru = 15; _UkoncitHru = 16; _Zpet = 17;
      _Rozliseni = 11; _Rolovani = 12; _RealTimeScroll = 13;
      _CitlivostMysi = 14; _RychlostHry = 15; _Autosave = 16;
      _640x480 = 11; _800x600 = 12; _1024x768 = 13; _1200x1024 = 14;
      _1 = 11; _2 = 12; _4 =13; _8 = 14; _16 = 15; _32 = 16;
      _DOOMY = 13; _Ustup = 14; _Info = 15;
      _VelmiNizka = 11; _Nizka = 12; _Normalni = 13;
      _Vysoka = 15; _VelmiVysoka = 16;
      _Temp1 = 11; _Temp2 = 12; _Temp3 = 13; _Temp4 = 14; _Temp5 = 15;
      _Temp6 = 16; _Temp7 = 17; _Temp8 = 18; _Temp9 = 19; _Temp10 = _Temp7;
      _Ano = 11; _Ne = 12;
      _CD = 11; _SBBlaster = 12;

      { * FOG_OF_WAR * }
      MaxGrids = 50; { pocet ruznych tvaru "mlhy" }
      GridAdd = 24; { pocet ruznych tvaru "mlhy" }

      { * RANGE_CHECK * }
      MaxRangeCheckArray = 15;

      { * GROUPS * }
      MaxGroups = 10; { max. pocet ulozenych skupin }
      MaxGroupUnits = 10; { max. jednotek skupiny }

      { * RESOURCE * }
      MaxResourceIndex = 90; { maximalni pocet "skladek" s materialem }
      MaxResource = 30000; { maximalni pocet materialu (BP) ve skladce }
      MaxRecyklatorBuildInfoIndex = 15; { maximalni index do pole
                                          RecyklatorBuildInfo }

      { * STRELY A ZABLESKY A OHNE * }
      MaxShotTypes = 8; { pocet ruznych typu strel a zablesku :}
      { 0..pechota, 1..kanon slabsi, 2..kanon silnejsi, 3..raketa nejslabsi
        4..raketa silnejsi , 5..raketa nejvetsi raze, 6.. kamikadze
        7..ND raketomet, 8.. laserovy znackovac }

      XMaxShot = 16; YMaxShot = 16; { rozmery nejvetsiho obrazku }
      XMaxShotdiv2 = 8; YMaxShotdiv2 = 8;
      MaxShotMemorySize = XMaxShot*YMaxShot + 4;

      MaxSmallExplosPhase = 16; { viz tez Max_units_explosion_phase }
      MaxMediumExplosPhase = 16;
      MaxBigExplosPhase = 26;

      { * INFO O JEDNOTCE * }
      { pozn. kvuli Rectangle a Frame musi byt X-ove delky deklarovany
        o 1 bod mensi}
      FrameColor = 70;
      XPictureSize = 33; YPictureSize = 33;
      {}
      SmallXBarSize = 33; SmallYBarSize = 5;
      SmallProcent = 3.226; { pocet procent na 1 bod }

      { * WAYPOINTy * }
      MaxWayPoint = 9;

      { * ZKUSENOST * }
      StandardExperience = 0; { inicializacni zkusenost jednotek }
      MaxExperienceSerie = 3; { pocet ruznych komponent pro
      vystavbu vojenske hodnosti }
      SerieMembers = 4; { pocet hodnosti v serii }
      MaxExperienceLevel = MaxExperienceSerie*SerieMembers+1;

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
      Experience8 = 844; Kills8 = 22;
      Experience9 = 1084; Kills9 = 30;
      Experience10 = 1450; Kills10 = 40;
      Experience11 = 1950; Kills11 = 50;
      Experience12 = 2757; Kills12 = 75;

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

      { prirustky zkusenosti pro jednotlive akce: }
      BuildingHitExp  = 2; { zasah do budovy }
      UnitHitExp      = 2; { zasah do jednotky }
      HitExp          = 2; { zasah od nepritele }
      UnitKillExp     = 15; { likvidace jednotky }
      BuildingKillExp = 20; { likvidace budovy }

      { nyni modifikator pro bojovou zkusenost: }
      { nasleduji modifikatory, kterymi se dle typu cile vynasobi vyse
      ziskane body bojove zkusenosti : }
      InfantryBEModifier = 0.9;
      LightUnitBEModifier = 1.0;
      HeavyUnitBEModifier = 1.0;
      AirUnitBEModifier = 1.1;
      BuildingBEModifier = 1.2;

      XBeginAdd = 1; { posun zacatku hodnostni "prymky" }
      { SERIE 1}
      Serie1 = SerieMembers;
      XSerie1Begin = 2; YSerie1Begin = 1; XSerie1Space = 1;
      XSerie1 = 6; YSerie1 = 6;
      { SERIE 2}
      Serie2 = SerieMembers*2;
      XSerie2Begin = 3; YSerie2Begin = 2; XSerie2Space = 3;
      XSerie2 = 4; YSerie2 = 4;
      { SERIE 3}
      Serie3 = SerieMembers*3;
      XSerie3Begin = 2; YSerie3Begin = 2; XSerie3Space = 3;
      XSerie3 = 5; YSerie3 = 4;

      { * MORALKA * }
      AverageMorale = 550; { normalni moralka jednotek }
      MaxMorale = 2*AverageMorale;
      MinMorale = 85; { moralka, pri niz se jednotka vzda }
      { modifikatory parametru jednotek v zavislosti na moralce (v procentech) }
      MoraleDefenceModifier = 0;
      PlusMoraleAttackModifier = 2.1; MinusMoraleAttackModifier = 3;
      MoraleStepModifier = 31; { udava, o kolik se musi zmenit moralka,
      aby se provedla zmena parametru jednotky }

      Single_morale_eval_div = 30; { vysledek procedury GetMoraleModif
      (unita _races) se vydeli touto hodnotou pro konkretni jednotku, ktera
      prave znicila cil }
      Global_morale_eval_div = 30; { od moralky v patricnem poli MapInfo
      se odecte ExperienceLevel*5 procent hodnoty MapInfo a vysledek
      se vydeli Global_morale_eval_div }

      { prirustky moralky pro jednotlive akce: }
      { POZOR!!!! pri zmenach hodnot zkontrolovat unitu _Shot !!! - zde se
        dane ubytky kompenzuji hodnosti jednotky }
      BuildingHitMorale  = 1; { zasah do budovy }
      UnitHitMorale      = 3; { zasah do jednotky }
      HitDeprivator      = -14; { zasah DO deprivatora }
      HitMorale          = -5; { zasah od nepritele }
      { - nasledujici hodnoty se vypocitavaji dle kvality znicene jednotky: }
      {UnitKillMorale     = 15; { likvidace zacilene nepratelske jednotky }
      {BuildingKillMorale = 20; { likvidace zacilene nepratelske budovy }
      RedDamage          = -85; { jednotka je kriticky poskozena - kouri }
      NewExperienceLevelMorale = 25; { jednotka je povysena }
      { - nasledujici hodnoty se vypocitavaji dle kvality znicene jednotky: }
      {MyUnitDestroyed = -10; { nejaka moje jednotka byla znicena }
      {MyBuildingDestroyed = -15; { nejaka moje budova byla znicena }
      {EnemyUnitDestroyed = 10; { nejaka nepratelska jednotka byla znicena }
      {EnemyBuildingDestroyed = 15; { nejaka nepratelska budova byla znicena }
      DeprivatorHitMorale =  -24; { zasah mutantem-deprivatorem }
      SkillLevelMoraleBonusSpeed = 400; {!!!!!! VYRAZENO Z PROVOZU !!!!!!}
      { doba v cyklech (pro nejrychlejsi variantu hry), po ktere se k moralce jednotky, je-li pod 100%,
      pripocte hodnostni uroven jednotky (0-12) }

      { * nyni udaje ohledne umeleho zvednuti moralky * }
      RaiseMoraleBonus = 110; { o kolik se 1 inijekci zvedne moralka }
      RaiseMoraleDamage = 9; { o kolik procent se 1 inijekci snizi damage }

      { * WEAROUT - OPOTREBENI * }
      MinWearOut = 200; { inicializacni opotrebeni (v procentech) }
      WearOutDefenceModifier = 0;
      WearOutPlusAttackModifier = 8; { procentualni prirustek
      bojovych schopnosti dle aktualniho opotrebeni (nad 100%) }
      WearOutMinusAttackModifier = 5.5; { procentualni pokles
      bojovych schopnosti dle aktualniho opotrebeni (pod 100%) }
      {x}
      WearOutLimitDecrease = 10; { o kolik klesne maximalni hranice, do niz
      lze obnovovat opotrebeni; inicializacne je hranice na hodnote
      MinWearOut, pote se po kazdych WearOutLimitDecreaseStep hodnotach
      opotrebeni snizi o WearOutLimitDecrease }
      WearOutLimitDecreaseStepUp150 = 45; { opotrebeni, po nemz se snizi maximalni
      hranice o WearOutLimitDecrease pro Limit > 150 }
      WearOutLimitDecreaseStepBelow150 = 35; { opotrebeni, po nemz se snizi maximalni
      hranice o WearOutLimitDecrease pro Limit <= 150 }
      MinWearOutLimitDecrease = 125; { toto je dolni hranice, pod niz
      nemuze maximalni hranice klesnout }
      {x}
      WearOutStepModifier = 10; { udava, o kolik se musi zmenit opotrebeni,
      aby se provedla zmena parametru jednotky }
      WearOutMove1 = 3.5; { opotrebeni po zdolani dalsiho policka presunem,
      je-li opotrebeni 200-170% }
      WearOutMove2 = 3.5; { opotrebeni po zdolani dalsiho policka presunem,
      je-li opotrebeni 170-150% }
      WearOutMove3 = 1.3;  { opotrebeni po zdolani dalsiho policka presunem,
      je-li opotrebeni 150-120% }
      WearOutMove4 = 1;  { opotrebeni po zdolani dalsiho policka presunem,
      je-li opotrebeni 120-80% }
      WearOutMove5 = 2;  { opotrebeni po zdolani dalsiho policka presunem,
      je-li opotrebeni 80-50% }
{!1!} WearOutMove6 = 2;  { opotrebeni po zdolani dalsiho policka presunem,
      je-li opotrebeni 50-0% }
      WearOutShot1 = 10; { opotrebeni po vystrelu, je-li opotrebeni 200-170% }
      WearOutShot2 = 4.5; { opotrebeni po vystrelu, je-li opotrebeni 170-150% }
      WearOutShot3 = 1.8; { opotrebeni po vystrelu, je-li opotrebeni 150-120% }
      WearOutShot4 = 1.1; { opotrebeni po vystrelu, je-li opotrebeni 120-80% }
      WearOutShot5 = 1.2; { opotrebeni po vystrelu, je-li opotrebeni 80-50% }
      WearOutShot6 = 1.5; { opotrebeni po vystrelu, je-li opotrebeni 50-0% }
      CriticalWearOut = 18; { po dosazeni teto hodnoty je jednotka sesrotovana }
      WearOutRestLimit = 60; { toto je limit, pod nejz kdyz klesne opotrebeni,
                               jednotka se automaticky zablokuje a ceka
                                na zlepseni }
      WearOutRepair1 = 2; { o kolik se zlepsi opotrebeni za dobu
                           WearOutRepairSpeed; 200-170% }
      WearOutRepair2 = 2; {o kolik se zlepsi opotrebeni pro stavajici 170-150%}
      WearOutRepair3 = 3.5; {o kolik se zlepsi opotrebeni pro stavajici 150-120%}
      WearOutRepair4 = 6; {o kolik se zlepsi opotrebeni pro stavajici 120-80%}
      WearOutRepair5 = 4; {o kolik se zlepsi opotrebeni pro stavajici 80-50%}
      WearOutRepair6 = 2; {o kolik se zlepsi opotrebeni pro stavajici 50-0%}
      WearOutRepairSpeed = 5; { doba v tazich, po ktere dojde k pripocteni
      WearOutRepair k hodnote opotrebeni (jednotka se dava do kupy) - MUSI
      jit o sude cislo }

      { * REPAIRS (OPRAVY) * }
      RepairFacilityCapacity = 5; { udava opravarenskou kapacitu jednoho
      opravarenskeho centra }
      BuildingRepairCapacityNeed = 4; { udava, kolik opravarenske kapacity
      potrebuje 1 budova pri oprave }
      UnitRepairCapacityNeed = 1; { udava, kolik opravarenske kapacity
      potrebuje 1 jednotka pri oprave }
      RepairValue = 0.75; { pocet procent, o nechz se jednotka/budova opravi }
      RepairCost = 0.75; { pocet procent materialu (z celkove ceny jednotky),
      ktery je treba pri oprave o RepairValue procent; u elektricke
      energie je  spotreba specialne 2*RepairCost }
      RepairSpeed = 20; { pocet cyklu, po nich se k hodnote Damage pripocte
      RepairValue procent - SUDE CISLO }
      CompRepairFlagLimit = 3; { doba, po ktere se zrusi oprava objektu
                                 pocitace - aby se dala sance i jinym }
      MaxRepairPhase = 15; { pocet cyklu, po nich probehne cyklus symbolu opravy  }

      SpeciallWearOutRepair = 2; { o kolik se zlepsi opotrebeni, provadi-li
                                   se oprava (t.j. za cas RepairSpeed)}

      { * INFORMACE O LETISTICH * }
      MaxAirportSpace = 20;

      { * GENEROVANI NAHODNYCH CISEL * }
      MaxRandomArrayIndex = 199;

      { * POMOCNA HODNOTA * }
      Places = 16;
      Price_bck_X_size = Round(8.5*XFontSize);
      Price_bck_Y_size = 4*YFontSize;
      Price_bck_memory = Price_bck_X_size*Price_bck_Y_size+4;

      { * PROPOJENI PO SITI * }

      { ************************  AI *************************************** }
      IntelliSearching_for_attack_limit = 10; { urcuje pocet casovych
      cyklu, po nichz jednotka provede inteligentni vyber cile z okoli }
      { podle nasledujicich limitu se stanovuje trida nebezpecnosti
        jednotky (0-7): (jednotka je ve tride 1, pokud je < DANGER1)}
      DangerLimit0 = 399; DangerLimit1 = 550; DangerLimit2 = 800;  {1}
      DangerLimit3 = 1000; DangerLimit4 = 1150; DangerLimit5 = 1300; {2}
      DangerLimit6 = 1600; DangerLimit7 = 20000;                    {3}

      { kategorie nebezpecnosti PVO (0-2) }
      ADangerLimit0 = 150; ADangerLimit1 = 300; ADangerLimit2 = 2550;

      { nyni pro prepocitavani hodnot z ruznych kategorii nebezpecnosti
        do jedne kategorie - vahy pro jednotlive kategorie; pozn.
        kategorie 0 ma automaticky koeficient 1 }
      DangerLimit1Coeff=1.4; DangerLimit2Coeff=1.8;
      { nyni prepocty mezi kategorii nebezpecnosti velmi lehke, lehke,
        tezke a vzdusne jednotky }
      DangerLimitLLCoef=0.8; DangerLimitLCoef=1.0; DangerLimitHCoef=1.2;
      DangerLimitACoef=1.2; DangerLimitAACoef=1.0;

      { pole ProductionList struktury Races: }
      MaxProductionListIndex = 50; MaxProductionListPriority = 3;
      InvalidProductionListIndex = 255;
      ProductionPriorityLow = 0; ProductionPriorityMedium = 1;
      ProductionPriorityHi = 2; ProductionPriorityVeryHi = 3;
      ProductionPriorityAutomatic = 255; { pro ucely AI2, Prepare_production;
      tato konstanta znaci, ze se priorita vybere automaticky }

      { sednuti AI vzdusneho carrieru za ucelem nalozeni jednotek -
        - dostatecne volne misto v okoli pro nalozeni }
      LoadOkFreePlaces = 4;

      { pro pole TaskGroups }
      MaxRaceTaskGroups = 55;
      InvalidTaskGroupNumber = 254; { neplatne cislo TaskGrupy }
      CreateNewTaskGroupNumber = 255; { vytvor novou TaskGrupu }

      MaxTGAttackInfo = 3; { 4 informace o cilech, na nez utoci TG - pro
                              ucely jednotek, ktere nemaji cil }
      { PRIKAZY STRUKTURY TASKGROUP }
      WithoutCom = 0; { zadny prikaz }
      AttackCom = 1; { prikaz utoku }
      MoveCom = 2; { prikaz presunu }
      BlockMoveCom = 3; { prikaz blokoveho presunu }
      MoveBuildCom = 4; { presun + rozlozeni budovy }
      HarvestCom = 5; { harvestovani }
      LoadCom = 6; { nakladani }
      SetAttackModeCom = 7; { nastavi prislusny utocny rezim skupiny }
      RestCom = 8; { odpocinek }
      PrepareCom = 9; { pro MasterCommand; v podstate ma TG vyhlednuty
      cil a doplnuje se pro utok }
      MergeCom = 10; { spojeni dvou TG }
      JoinCom = 11; { fyzicke spojeni dvou TG }
      WaitCom = 12; { cekani na mergovaci grupu }
      UnLoadCom = 13; { vykladani }
      RemakeCom = 14; { reorganizace obranne TG }
      { typy TaskGrup }
      TGDefence = 0; TGAttack = 1; TGSaboteur = 2; TGPlus{bojova zaloha} = 3;
      TGRecon = 4; TGPara = 5;
      TGInvalid = 255; { neplatna hodnota; slouzi napr. pro harvestery,
      jednotky a budovy atd.; takova TG nevyhledava utocny cil }
      { cas pro cyklus aktivniho vyhledavani cile (nejrychlejsi varianta): }
      ActiveSearchingTGTimeLimit = 40;

      { pro pole FreePlaces: (struktura Races) }
      MaxFreePlaces = 79; { udava pocet polozek-1 (volnych mist pro staveni) }
      MaxFreeStructures = 3; { udava pocet ruznych oblasti , ktere
      lze pouzit pro stavbu struktur; pozn. oblasti se nesmi prekryvat }

      { * jadro * }
      MaxCoreUnits = 15;

type  TWayPoint = array [0..MaxWayPoint] of record { pozice cilu pri presunu }
                     IAim, JAim : Word; { pozice cile pri presunu }
                     Level:Byte;
                  end;

      PPUnit = ^PUnit;
      PPBuilding = ^PBuilding;

      { * BUDOVY * }
      PBuilding = ^Building_;
      Building_ = object { objekt, reprezentujici konkretni budovu }
                     Next:PBuilding; { ukazatel na stejnou budovu daneho typu }
                     XXX:Word; { pro ucely save/load }
                     Activity:Boolean; { True, je-li budova aktivni, t.j.
                     lze ji zobrazovat a pracovat s ni }
                     BuildingType:Byte; { identifikacni cislo }
                     { jde o pristupovy index do pole Building_types }
                     Phase:Byte; { faze prislusneho vybuchu }
                     RandomUk:Byte; { ukazatel do pole nahodnych cisel }
                     Pom:ShortInt; { slouzi pro pripad vybuchu }
                     Index:Word; { index budovy v poli Buildings }
                     Race:Byte; { prislusnost budovy }
                     Damage:Word; { stupen poskozeni; na zacatku se nainicializuje
                      napr. na 100 a kazdym zasahem se bude snizovat }
                     IPos, JPos : Word; { pozice leveho horniho bodu budovy }
                     Visibility : Boolean; { viditelnost budovy }
                     EnemyVisibility : Boolean; { viditelnost budovy neprateli }
                     FireFlag:Byte; { fazovani koure }
                     FirePhase:Byte; { 0.. nic
                                       1-4 .. ruzne faze "kourici budovy"  }
                     FireState:Byte; { 0 .. nic
                                       1 .. "maly ohen"
                                       2 .. " velky ohen"}
                     Production_percentage:Single; { 0-100, udava procento
                                                     hotove vyroby }
                     Production_type:Byte; { 0 .. nic se neprodukuje }
                     { index prave produkovane jednotky (v poli Production) }
                     Production_slot:Byte; { cislo slotu, v nemz je vyrabejici se jednotka }
                     Production_phase:Byte;
                     { faze produkce; po BuildingProductionSpeed tazich se
                       spotrebovava energie a generuji se procenta; nebo je
                       zde ulozena doba, po niz se vygeneruji plasty/el.
                       energie }
                     Sold:Boolean; { True, byla-li budova prodana }
                     Production_count:Byte; { pocet objektu, ktere se maji
                     vyrobit }
                     EEConsumption_phase:Byte; { zde se dekrementuje hodnota,
                     po niz se odpocita elektricka energie }
                     Group : Byte; { cislo skupiny, v niz je budova ulozena;
                     pokud se Group = ActiveGroup, pak se kolem ni vykresli
                     "selectovaci" ramecek; 254 = neni v zadne skupine; pokud
                     je budova "naclicknuta", automaticky se prirazuje
                     do specialni skupiny cislo MaxGroups }
                     { nasledujici je pro ucely nepratelskych skupin pri
                       propojeni siti } Group2 : Byte;

                     RequestDraw:Boolean; { True = budova se ma v tomto
                     cyklu vykreslit }
                     Repair:Boolean; { True = budova je opravovana }
                     DrawRepair:Boolean; { True, ma-li se nad budovou
                                           zobrazovat symbol opravy }
                     RepairFlag:Byte; { casovani vlastni opravy }
                     DrawRepairFlag:Byte; { casovani pro ucely DrawRepair }
                     BPRepairRemainder, PLRepairRemainder,
                     EERepairRemainder, EXRepairRemainder : Word;
                     RepairRemainder:Word;
                     { hodnoty pro praci s opravou }
                     CompRepairFlag : Word;
                     WarningBlingFlag:Byte; { normalne je na nule,
                     pokud se na budovu zautoci, nastavi se na hodnotu
                     MaxWarningBlingValue - tato budova, je-li vlastni
                     pak na radaru MaxWarningBlingValue cyklu blika
                     }

                     BuildPhase:Byte;
                     {  BuildPhase urcuje fazi, ve ktere se ma budova
                        vykreslit:
                        1-3 .. stavebni faze
                        4,5 .. hotove faze
                        6,7 .. poskozena budova }
                     BuildAnimPhase:Byte; { animacni faze budov }
                     BuildTemp:Byte;
                     { pro staveci faze 1-3 se inkrementuje az po hodnotu
                       BuildingSpeed; pak se preklopi do dalsi faze }

                     { nasledujici waypointy se priradi kazde nove
                       vyrobene jednotce: }
                     WayPoint : TWayPoint;
                     WayPointMax : Byte; { max vyuzita pozice; 255 = prazdne pole }
                     WayPointUk  : Byte; { aktualni ukazatel; 255 = prazdne pole }

                     TaskGrp:Byte; { cislo taskgrupy, do ktere se vyrobek
                     zaradi }
                     TaskCommand:Byte; { prikaz pro taskgrupu TaskGrp,
                     ktery se ji priradi po vyrobeni jednotky }
                     LockType:Byte; { LockType taskgrupy, jez si vyrobu zadala
                                     viz AI/TProductionList}
                     XXXTemp:array[0..99] of Byte; { rezerva }
                  end;

      { * JEDNOTKY * }
      PUnit = ^OUnit;
      OUnit = object { objekt, reprezentujici konkretni jednotku }
               UnitType : Byte; { identifikacni cislo }
               TargetType : Byte; { typ     : 0..lehky - da se prejet,
                                              1..lehky - neda se prejet,
                                              2..tezky, 3..vzdusny,
                                              4..namorni }
               Race : Byte; { rasa jednotky }
               Activity : Boolean; { True, je-li jednotka aktivni, t.j.
               lze ji zobrazovat a hybat s ni }
               DestroyEffect:Boolean; { True, pokud jednotka nevybuchne,
                                         ale "otoci se" }
               SpecNumber:Byte; { specialni cislo jednotky }
               Sight:Byte; { dohled jednotky }
               Destroyed : Boolean; { JE JEDNOTKA ZNICENA ? }
               Index : Word; { index jednotky v poli Units }
               IPos, JPos : Word; { pozice v polickach na mape }
               Move_target_level : Byte; { uroven cile presunu :
                             0 .. presunuj se na pozemni uroven
                             1 .. cil je v druhe vrstve
               }
               CompRepairFlag:Word;
               IAirport, JAirport:Word; AirportPos:Byte;
               { souradnice prislusejiciho letiste spec. letajici jednotky }
               WayPoint : TWayPoint; { pozice cilu pri presunu; na prvnim
               indexu tez muze byt ulozena souradnice utoku na budovu }
               WayPointMax : Byte; { max vyuzita pozice; 255 = prazdne pole }
               WayPointUk  : Byte; { aktualni ukazatel; 255 = prazdne pole }
               XOffset, YOffset : Word; { offset pozice uvnitr policka 32x32 }
               Target : PPUnit; { ukazatel na cil-jednotku pri utoku }
               BTarget : PPBuilding; { ukazatel na cil-budovu pri utoku }
               { pozn. jde o ukazatel na ukazatel, t.j. je vzdy treba pro
                 praci provest pocatecni prirazeni do pomocne promenne:
               _unit = Target^ }
               First_attack:Boolean; { True, pokud se nachazime casovy slot
               tesne po vystrelu nebo na zacatku utoku }
               ITarget, JTarget : Word; { pouziva se pro ulozeni rezervni
               informace o puvodni pozici pri modu aktivni obrany }
               ADefModeSteps:Word; { pocet kroku pri modu aktivni obrany }
               IAim, JAim :Word; { uklada se zde souradnice utoku }
               ShootFlag : Byte; { pomocna promenna,
               ktera se bude kazdym casovym cyklem snizovat; bude-li rovna
               0, jednotka vystreli }
               FlashFlag : Byte; { = 2 vykresli se zakladni zablesk u
               jednotky (po vystrelu); = 4 vykresli se druhy zablesk;
               = 6 smaz zablesk; = 0 zadny zablesk se nekresli }
               RandomUk : Byte;  { ukazatel do tabulky nahodnych cisel }
               AttackL : Byte; { pro potreby vykresleni zablesku }
               Damage:Word; { stupen poskozeni; na zacatku se nainicializuje
               napr. na 100 a kazdym zasahem se bude snizovat }
               DamageBonus:Integer; { extra navyseni DefenceStrength }
               LAttackBonus1,HAttackBonus1,AAttackBonus1:Integer;
               LAttackBonus2,HAttackBonus2,AAttackBonus2:Integer;
               { modifikatory utoku v zavislosti na aktualni moralce
                a zkusenosti }
               Experience:Word; { aktualni zkusenost jednotky }
               ExperienceLevel:Byte; { aktualni hodnost jednotky }
               Kills:Word; { pocet znicenych nepratel }
               Sold:Boolean; { True, byla-li jednotka prodana }
               Morale:Integer; { aktualni moralka pro lidske jednotky }
               WearOut:Single; { opotrebeni (v procentech) robotske
               jednotky }
               WearOutFlag:Byte; { pro ucely zlepsovani opotrebeni }
               WearOutLimitDecreaseFlag:Single; { pro ucely snizovani
               horni hranice opotrebeni }
               MinimalWearOut:Word; { horni hranice doplneni opotrebeni }
               ShootTypeFlag1, ShootDelayFlag1,
               ShootTypeFlag2, ShootDelayFlag2 :Word; { pro potreby
               zpozdovani zbrane; nektere zbrane mohou po nekolika
               vystrelech (PauseType) "zamrznout" na dobu PauseDelay }
               Visibility:Boolean; { viditelnost; True, je-li videt }
               EnemyVisibility:Boolean; { viditelnost neprateli }
               VisibilityChange:Boolean;      { pro potreby Set_place }
               EnemyVisibilityChange:Boolean; { pro potreby Set_place }
               ActiveWeapon:Byte; { zbran pripravena k vystrelu:
                                    0 .. zadna zbran; 1 .. zbran 1;
                                    2 .. zbran 2 }
               Cargo:Single; { u recyklatoru procentuelne vyjadruje naplneni
               BP materialem; narust procent / 1 tah vyjadruje konstanta
               HarvestingSpeed }
               HarvestPhase:Byte; { faze tezby (u "jemnejsiho" casovani se
               odpocet provede jednou za dva tahy) }
               ActivityFlag:Word; { pokud jenotka nic nedela, pak
               se tento flag inkrementuje a po jiste dobe se jednotvce
               zada nejaka cinnost (natoceni) }
               IdleFlag:Word; { tato hodnota se zvysuje, pokud se jednotka
               nachazi ve stavu 129; po urcite dobe, znamenajici pravdepodobne
               uvaznuti, se provede "pokus o vyprosteni" }
               TurnFlag:Word; { tato hodnota se zvysuje, pokud je jednotka
               na miste a otaci se; pokud je zde hodnota vetsi nez 4, pak
               jde "uvaznuti" => pokus o vyprosteni }
               RequestDraw:Boolean; { = True, ma-li se pri nejblizsi
               prilezitosti v UnitManageru prekreslit }
               UpdateDmg,UpdateMoralWearOut,UpdateLev:Boolean;
               { True, maji-li se v danem tahu prekreslit dotycne
                 charakteristiky }
               RandomFlag:Word; { pro ucely nataceni flakajicich se jednotek }
               SearchingFlag:Byte; { pro ucely automatickeho vyhledavani
               nepratelskeho cile; kazdym tahem se testuje jeden okruh
               v dostrelu; posledni je ulozen prave v teto promenne }
               FireFlag:Byte; { fazovani koure }
               FirePhase:Byte; { 0.. nic
                                 1-4 .. ruzne faze "kourici jednotky"  }
               SkillLevelMoraleBonusFlag:Byte; { viz SkillLevelMoraleBonusSpeed }
               Repair:Boolean; { True = jednotka je opravovana }
               DrawRepair:Boolean; { True, ma-li se nad jednotkou
               zobrazovat symbol opravy }
               RepairFlag:Byte; { casovani vlastni opravy }
               DrawRepairFlag:Byte; { casovani pro ucely DrawRepair }
               BPRepairRemainder, PLRepairRemainder,
               EERepairRemainder, EXRepairRemainder : Word;
               RepairRemainder:Word;
               { hodnoty pro praci s opravou }
               { je-li napr. jednotka ve smeru 128 a smer 32 nebo 2 je o
                 hodnotu az "MaxDepth" vyhodnejsi nez smer 64 nebo 1, umele
                 zvyhodnime smery 64 nebo 1 (snazime se, aby zmeny kurzu
                 nebyly zbytecne radikalni) }
               SlashCount:Byte; { pocita dobu od posledniho zvyhodneni -
               - behem teto doby nelze dalsi zvyhodneni provest }
               SlashDir1, SlashDir2, SlashDir:Byte;
               { prvni dve promenne jsou spise pomocne; SlashDir udava
                 "zvyhodneny smer"; pokud je SlashCount <> 0, tento smer
                 se umele drzi "zvyhodneny" pred ostatnimi }
               Attacking:Boolean;  { True, pokud jednotka naposledy utocila }
               Status:Byte; { stav jednotky :
                              0..hlida
                              1-128 .. nataci se (zadany smer natoceni), nebo
                                       je-li rovno Direction, pak se presouva
                              129 .. presouva se, nyni vsak ceka
                              255 .. utoci bez presunu nebo
                                     je-li Activity = False, pak jednotka
                                     vybuchuje
               }
               Direction:Byte; { smer natoceni :
                       SMER NATOCENI JEDNOTEK:
                            1     2     4
                               \   |   /
                          128 -       - 8
                              /   |   \
                            64    32   16
               }
               MoveStatus:Byte; { urcuje typ cinnosti:
               0 .. normalni presun, 1 .. patroluje
               8 .. "tvrdy utok s presunem" - v teto variante se
                    ignoruje pripadny mod aktivni obrany a probiha
                    neomezene utocne presunovani
               16 .. utok s moznym presunem,
               32 .. utok bez moznosti presunu
               64 .. viz 32, ale cil neni v dostrelu
                     (utok lze tedy zacilit i jinam, je-li moznost)
               }
               BlockMove:Boolean; { True, je-li nastaven blokovy presun;
               t.j. cilem je velke pole (IInfoArraySize x JInfoArraySize)
               o souradnici IBlock, JBlock; nezavisle na presnem umisteni
               jednotky se pak po dosazeni bloku aktivuje hodnota
               CheckGroupMoveDistance }
               IBlock,JBlock:Word;
               ActiveDefence : Boolean; { True, je-li jednotka v modu
               aktivni obrany }
               ActiveDefenceRange: Word; { vzdalenost, pouzivana pri
               nastaveni aktivni obrany }
               Return_to_base : Boolean; { = True, pokud vzdusna jednotka,
               potrebujici letiste se na letiste vraci; pak s ni nelze
               manipulovat }
               STOP_:Boolean; { True - pokud se jednotka presunuje tak jakmile
               dojede na cele pole, musi se zastavit }
               CheckGroupMoveDistance:Boolean; { nastavi se na True, pokud
               pri posunu jednotka narazi na dalsi jednotku, ktera stoji, ale
               ma stejny cil presunu; nebo se dostane do tesne blizkosti
               cile (2 pole); pak se bude jednotka presouvat do te doby,
               dokud se nebude zvetsovat jeji vzdalenost od cile }
               GroupMove:Boolean; { = True, presunuje-li se cela skupina }
               GroupMoveBlock:Byte; { pokud ma jednotka utocit nebo presouvat,
               je zde hodnota, kolik casovych cyklu ma jednotka pockat, nez
               se zacne presunovat }

               Phase:Byte; { faze pohybu - strida se 0-x; jde-li o vybuch,
               citaji se zde faze explozi 1..Max_units_explosion_phase }
               MovementAddingPhase:Byte; { vybira se aktualni MovementAdding }
               MoveDir : Byte;
               { v teto promenne je ulozena predem propocitana trasa presunu
                jednotky }
               MoveUk : Byte; { aktualni ukazatel do pole MoveDir; pokud je
               zde hodnota 0, jsou informace v poli neplatne }
               BanDir : Byte; { zakazany smer pohybu }
               First_mov : Boolean; { True na zacatku pohybu; predpocita se
               optimalni smer }

               Group : Byte; { cislo skupiny, v niz je jednotka ulozena;
               pokud se Group = ActiveGroup, pak se kolem ni vykresli
               "selectovaci" ramecek; 254 = neni v zadne skupine; pokud je
               jednotka "naclicknuta", automaticky se prirazuje
               do specialni skupiny cislo MaxGroups }
               GroupOrder : Byte; { index jednotky ve skupine; 0 je prvni? }

               UniqueNumber:Word; { pro ucely jednotek jadra;
                                    65535 = neni clenem jadra }
               { ***** }

               GroupMoveSteps : Byte; { pokud CheckGroupMoveDistance = True,
               pak dovoli posun maximalne o dalsich 6 policek, nebo pokud
               by se mela zvetsit vzdalenost od cile }
               GoInside : Boolean; { True, ma-li se jednotka nalozit }
               Temp : Byte; { pomocna promenna }
               UnitsInsideNum : Byte; { pocet nalozenych jednotek }
               UnitsInsidePlace : Byte; { misto obsazene nalozenymi jednotkami }
               UnitsInside : array[0..MaxGroupUnits-2] of Word;
               { indexy do pole Units nalozenych jednotek }
               Selected:Boolean; { True, je-li uvnitr jine jednotky a
               byla-li navolena pro vylozeni }
               WarningBlingFlag:Byte; { normalne je na nule,
               pokud se na jednotku zautoci, nastavi se na hodnotu
               MaxWarningBlingValue - tato jednotka, je-li vlastni
               pak na radaru MaxWarningBlingValue cyklu blika }
               Working:Boolean; { True, pokud harvester neco dela (podili se
               na recyklaci); False, pokud necinne stoji }
               Name : String[15]; { jmeno jednotky }
               BuildingType : Byte; { typ budovy, jde-li o jednotku 33 }
               _building:Boolean; { pouze pro jednotku cislo 33;
               True (pokud predstavuje budovu); False, predstavuje-li
               jednotku (napr. i raketova vez) }
               Eras:Boolean; { priznak, pokud jednotka prejizdi z pasma
               viditelnosti do pasma "mlhy", ze se ma objekt s jiz nastavenou
               Visibility = False jeste naposledy smazat }

               { ************************************************** }
               { ****** nasledujici data jsou pro potreby AI ****** }
               HarvesterWait:Word; { pro potreby procedury CheckExecuteTaskGroupCommand}
               IntelliSearching_for_attack_flag:Integer;
               { tato promenna se inkrementuje a az dosahne hodnoty
                 IntelliSearching_for_attack_limit, provede se inteligentni
                 vyber cile z okoli MaxSearchingRange
               }
               DangerClass : Byte; { trida nebezpecnosti jednotky vzhledem
               k jejim parametrum - vuci pozem. cilum
               (pouzivano umelou inteligenci)
               rozmezi: 0 .. 7
               neplatna hodnota: 255;
               }
               ADangerClass : Byte; { trida nebezpecnosti jednotky vzhledem
               k jejim parametrum - vzdusna (pouzivano umelou inteligenci)
               rozmezi: 0 .. 2
               neplatna hodnota: 255;
               }
               IInfoPos, JInfoPos : Byte; { pozice jednotky v poli MapInfo }
               AIAttackType : Byte;  { typ utocneho zamereni jednotky:
                 0..specialni budova AIAttackBuilding
                 1..specialni jednotka AIAttackUnit
                 2..jednotky
                 3..budovy
                 4..zaskodnictvi
               }
               AIAttackBuilding:PPBuilding; AIAttackUnit:PPUnit;
               KamikadzeMod:Boolean; { True = jednotka jde tvrde za
                                       splnenim cile TG bez ohledu na ztraty}
               Next:PUnit; { zretezeny seznam jednotek v TaskGrupe, do
               kterych lze neco nalozit }
               XXX,XXX1,XXX2,XXX3,XXX4 : Word; { pro ucely save/load }
               Down:Byte; { inicializacne 0; tyka se jen leteckych carrieru:
                 1..pouze sedni
                 2..sedni a vyloz
               }
               Load_flag:Word; { zabrani, aby se u pocitace cyklicky
                                 nakladaly-vykladaly jednotky, pokud
                                 se jednotka dostane do boje
                                 v "nevhodnou dobu" }

               TaskGroup:Byte; { cislo taskgrupy, do ktere jednotka patri-
               InvalidTaskGroupNumber = neplatna hodnota }
               CommandNum:Byte; { poradove cislo prikazu taskgrupy,
               provedenych jednotkou units - s pomoci tohoto pocitalda
               jednotka z taskgrupy zjistuje, zda jiz prikaz provedla }
               Awaiting_for_further_orders:Boolean;
               { True, pokud jednotka uspesne provedla vsechny prikazy
                 taskgrupy a nyni ceka na pripadne dalsi }
               Free_attack:Boolean; { True, muze-li jednotka svobodne
               vyhledavat cile, False pri utocnem presunu, pokud nechceme,
               aby se taskgrupa rozptylovala }
               WearOutRest:Boolean; { True, pokud je nutno cekat, aby se
                                       jednotce doplnil wearout }
               CivilianMoveFlag:LongInt;
               CivilianMoveLimit:LongInt;
               XXXTemp:array[0..19] of Byte; { rezerva }
              end;

       { * STRELY * }
       PShots = ^OShot;
       OShot = object { objekt, reprezentujici konkretni strelu }
                  { data pro vypocet pohybu strely po usecce: }
                  DeltaX, DeltaY:Integer;
                  Delka:Word;
                  XAdd, YAdd :Integer; { prirustek pro konvencni strelu }
                  { data pro vypocet pohybu rakety: }
                  Dir1, Dir2, Dir3 : Byte; { jednotliva natoceni pro
                  jednotlive faze pohybu rakety }
                  Steps1, Steps2 : Word; { pocet "kroku" strely pro fazi
                  1 a 2 pohybu; tyto hodnoty urcuji, kdy dojde k prepnuti
                  faze; aktualni faze se indikuje podle pripadne
                  nulovosti techto hodnot; napr. Steps1=0 a Steps2 = 5 urcuje
                  probihajici druhou fazi }

                  Target : PPUnit; { ukazatel na cil-jednotku pri utoku }
                  BTarget : PPBuilding; { ukazatel na cil-budovu pri utoku }
                  { pozn. jde o ukazatel na ukazatel, t.j. je vzdy treba pro
                    praci provest pocatecni prirazeni do pomocne promenne:
                   _unit = Target^ }
                  Visibility:Boolean; { True = je projektil videt }
                  Next : PShots; { ukazatel na dalsi strelu (na 1 policku
                  se muze nachazet vice strel) }
                  Father : PPUnit; { ukazatel na zdrojovou jednotku strely }
                  { pozn. jde o ukazatel na ukazatel, t.j. je vzdy treba pro
                    praci provest pocatecni prirazeni do pomocne promenne:
                    _unit = Father^ }
                  TargetMovementLevel:Byte; { pohybova uroven strely }
                  Index:Byte; { index strely v poli Shots }
                  ShotRace:Byte; { prislusnost strely (pro priznani battle
                  points pri zniceni cile) }
                  First:Byte; { value < 2 = pro prvni souradnici strely;
                  pro tuto situaci se neprovadi Erase_shot }
                  Direction : Byte; { natoceni strely }
                  ITarget, JTarget : Word; { souradnice cile na mape }
                  IPos, JPos : Word; { aktualni souradnice strely }
                  IPosOld,JPosOld : Word; { stare hodnoty }
                  XOffset,YOffset : Word; { offset uvnitr policka strely }
                  XPos, YPos : Integer; { bodova souradnice strely }
                  XPosOld,YPosOld : Word; { stare hodnoty }
                  Status : Word;  { jedna se o status strely:
                                     0    .. normalni pohyb strely
                                     <> 0 .. ruzne faze vybuchu
                                     255  .. strelu je treba kompletne
                                             odalokovat }
                  Phase : Byte; { faze pohybu strely ; 0 nebo 1 }
                  AttackLevel:Byte; { specialni atribut utoku :
                                  0..utok pechoty (nestrili pres kopce...)
                                  (nasledujici zbrane mohou strilet pres
                                   prekazky); nezobrazuje se
                                  1..pechota, zobrazuje se
                                  2..normalni zbran
                                  5..kamikadze
                  }
                  AttackPicture:Byte; { obrazek strely:
                                  1..kanon1 (slabsi projektil)
                                  2..kanon2 (silnejsi projektil)
                                  3..raketa1 (nejslabsi projektil)
                                  4..raketa1 (stredni projektil)
                                  5..raketa2 (nejsilnejsi projektil)
                  }
                  Level : Byte; { pohybova uroven strely; 0..pozemni, 1..vzdusna}
                  LightAttack, HeavyAttack, AirAttack:Word; { sila utoku }
                  Guided:Boolean; { True, je-li strela rizena }
                  Temp:Byte; { pomocna promenna }
                  S,O:Word; { segment, offset aktualniho obrazku vybuchu strely }
                  Missile:Boolean; { True, jde-li o raketu }
                  XXX1,XXX2,XXX3,XXX4 : Word; { pro potreby save/load }
               end;
       UnitInfo = record
                     Active:Boolean;
                     UnitType:Byte;
                     Experience:Word;
                     Kills:Word;
                     Level:Byte;
                     Name:String[15];
                     UniqueNumber:Word;
                  end;


       MapArray = array [0..IMaxSize,0..JMaxSize] of record
               First_level:Word; { info o jednotce na 1. urovni - index
               jednotky v poli Units; 0 = zadna jednotka(budova) }
               Second_level:Word; { info o letecke jednotce - index
               jednotky v poli Units; 0 = zadna jednotka }
               Level_type:Byte; { nejvyznamejsi bit :
               nastaven - jde o budovu na 1. urovni, jinak je na 1.
               urovni jenotka; ostatni bity = index do pole Shots }
            end;

       MapBckTempArray = array[0..IMaxSize,0..JMaxSize] of record
                           Temp:Byte; {
                            bit 1 (nejmene vyznamny) .. pro potreby Fog_of_war
                            bit 2 (2.nejmene vyznamny) .. pro Unknown_terrain
                                 (nastaven = prozkoumana oblast)
                            bit 3 .. nastaven, pokud se tato oblast ma vykreslit
                                     zamlzena, ale ne cerna!
                             }
                            Visibilit: Word; { vzdalenost nejblizsi vlastni nebo
                            pratelske jednotky od policka; 0 = neni videt}
                            EnemyVisibilit: Word; { vzdalenost nejblizsi cizi
                            (nepratelske) jednotky od policka; 0 = neni videt}
                         end;
       MapBckArray = array[0..IMaxSize,0..JMaxSize] of record
                       BckType:Word; { typ pozadi :
                       ? .. cesta
                       ? .. trava
                       ? .. pole
                       ? .. poust
                       ? .. hory
                       ? .. voda
                       ? .. les
                       ? .. letiste
                       }
                       Info:Byte;  { je-li na policku zdroj, jedna se o index
                                     do pole ResourceInfo, jinak trosky
                                     zlikvidovane jednotky;
                                     255 je prazdna hodnota }
                       XX,YY: Byte;
                     end;
       TMapInfo = array[0..IInfoArraySize-1,0..JInfoArraySize-1] of record
       { pole s informacemi nepratelskeho pocitace (!Z JEHO POHLEDU!)
         POZOR! MOJE spojenecke jednotky "neuznavaji" FOG OF WAR pro budovy,
         t.j. stale vidi vsechny budovy nepritele !
         pozn. Air kategorie vypovida a PROTIPOZEMNICH schopnostech LETECKYCH
               jednotek; AAttack pak a PVO schopnostech VSECH jednotek
               NEUTRALNI jednotky ve statistice NEJSOU !
       }
                      { INFO O VLASTNICH JEDNOTKACH }
                      { NEJPRVE VLASTNI, VIDITELNE POCITACEM }
                      VLLight: array[0..2] of Byte;{ 3 kategorie lehkych0 }
                      VLight:  array[0..2] of Byte;{ 3 kategorie lehkych1 }
                      VHeavy:  array[0..2] of Byte;{ 3 kategorie tezkych }
                      VAir:    array[0..2] of Byte;{ 3 kategorie vzdusnych }
                      VAAttack:array[0..2] of Byte;{ 3 kategorie PVO }
                      VTotall : Byte; { pocet vsech jednotek }
                      VSpecial :Byte; { specialni - harvester }

                      { INFO O SKRYTYCH, POCITACI PRATELSKYCH JEDNOTKACH }
                      HLLight: array[0..2] of Byte;{ 3 kategorie lehkych0 }
                      HLight:  array[0..2] of Byte;{ 3 kategorie lehkych1 }
                      HHeavy:  array[0..2] of Byte;{ 3 kategorie tezkych }
                      HAir:    array[0..2] of Byte;{ 3 kategorie vzdusnych }
                      HAAttack:array[0..2] of Byte;{ 3 kategorie PVO }
                      HTotall : Byte; { pocet vsech jednotek }
                      HSpecial :Byte; { specialni - harvester }

                      { INFO O VIDITELNYCH NEPRATELSKYCH (MYCH) JEDNOTKACH }
                      EnemyVLLight: array[0..2] of Byte;
                      EnemyVLight:  array[0..2] of Byte;
                      EnemyVHeavy:  array[0..2] of Byte;
                      EnemyVAir:    array[0..2] of Byte;
                      EnemyVAAttack:array[0..2] of Byte;
                      EnemyVTotall : Byte; { pocet vsech nepr. vid. jednotek }
                      EnemyVSpecial :Byte;

                      { INFO O SKRYTYCH NEPRATELSKYCH (MYCH) JEDNOTKACH }
                      EnemyHLLight: array[0..2] of Byte;
                      EnemyHLight:  array[0..2] of Byte;
                      EnemyHHeavy:  array[0..2] of Byte;
                      EnemyHAir:    array[0..2] of Byte;
                      EnemyHAAttack:array[0..2] of Byte;
                      EnemyHTotall : Byte; { pocet vsech nepr. skryt. jednotek }
                      EnemyHSpecial :Byte;

                      { INFO O BUDOVACH }
                      FriendlyBuildingsNum : Byte; { pocet pr. budov }
                      FriendlyBuildingsWeight : Word; { vaha pr. budov }
                      EnemyVBuildingsNum :Byte;{ pocet nepr. viditelnych budov}
                      EnemyVBuildingsWeight : Word; { vaha nepr. vidit. budov }
                      EnemyHBuildingsNum :Byte;{ pocet nepr. skrytych budov }
                      EnemyHBuildingsWeight : Word; { vaha nepr. skryt. budov }

                      MoraleModifier:array[0..MaxRace] of Single;
                      { udava kazde kolo, jak se ma zmenit moralka kazde
                      jednotky dane rasy; jde o hodnoty z predchoziho
                      kola za ztratu nejake jednotky\budovy }
                      MoraleModifierTemp:array[0..MaxRace] of Single;
                      { udava kazde kolo, jak se ma zmenit moralka kazde
                      jednotky dane rasy; jde o hodnoty z predchoziho
                      kola za ztratu nejake jednotky\budovy }

                      Pruchozi:Boolean; { True, pokud je dane pole pro AI
                      pocitace pruchodne, False pokud ne }
                   end;

       { 255..prazdne; jinak cislo rasy, ktera ma na tomto miste budovu;
         jedna se o udaje, ktere "vidim": }
       TBuildRadar = array [0..IMaxSize,0..JMaxSize] of record
                        B: Byte;
                        P: Boolean; { True, videl-li jsem toto misto }
                     end;

       { * POMOCNE POLE * }
       TFreePlaces = array [1..Places] of record
                        IP,JP : Word; { pozice mista }
                        Free : Boolean; { je misto volne ? }
                     end;

       TPermittedUnits = array[1..MaxTypesOfUnits] of Boolean;
       TRange_check_array = array[0..MaxRangeCheckArray] of record
                              X,Y:Word; { X-ova a Y-ova velikost }
                              Rng:array[0..32,0..32] of Boolean;
                              { pole dostrelu }
                            end;

      { * SEZNAM SPECIALNICH CISEL * }
      type TSpecNumList = array[0..16] of record
                             Count:Word; { pocet existujicich specialnich
                             cisel ve hre }
                             Destr:Boolean; { True, pokud byla alespon
                             jedna jednotka tohoto spec. cisla znicena }
                          end;

      type TKategorieArray = array[0..2] of Byte;

      { * VICTORY CONDITIONS * }
      type TVictoryCond = record
                     Condition:Byte; { typ podminky pro ukonceni hry }
                     Num1:Byte; { spec. cislo nebo typ jednotky - dle Condition }
                     Num2:Byte; { rasa budovy }
                     Result:Integer; {
                        -1 .. dana podminka neni splnena
                         0 .. podminka se plni (zachranit alespon 1
                                                jednotku cisla ...)
                         1 .. podminka splnena
                     }
                     TimeMin:Byte; { casovy limit (je-li <> 0) v minutach }
                     TimeSec:Byte; { casovy limit v sekundach }
                    end;
           TVCond =  array[0..MaxCond] of TVictoryCond;

      { * TASKGROUPS * }
      TReinfo = record
      { pokud se zjisti, ze cil pro utok je silnejsi nez je akceptovatelne,
       jsou v tomto poli analyticke informace o sile nepratel; dale
       jsou zde informace o sile budov a spec. cilu (harvester,
       slozena budova) v oblasti }
                 LLight,Light,Heavy,Air,AAttack:Word; { sila nepratel
                 v jednotlivych kategoriich }
                 EnemyBuildingsWeight:Single; { dulezitost nepr. budov }
                 FriendlyBuildingsWeight:Single; { dulezitost vlastnich budov }
                 SpecTargets:Single; { pocet specialnich cilu }
                 Difference:Single; { udava procentuelni silu nepratel,
                 pokud 100% je sily me taskgrupy }
                 OverStrength:Boolean; { True, pokud se jedna
                 o "falesne" slabsi TG - t.j. sila TG je pod minimalnim
                 limitem }
               end;

      TTaskGroups = array[0..MaxRaceTaskGroups] of record
                       Validity:Boolean; { True, je-li tato polozka
                       platna }
                       GroupType:Byte; { Typ TaskGrupy:
                        TGDefence,TGAttack,TGSaboteur,TGPlus(zaloha),
                        TGPara }
                       TrueSaboteur:Boolean; { True, pokud se jedna o
                        "skutecnou" sabotazni skupinu (APC+pechota), False
                        pokud jde o mixovanou skupinu }
                       ActiveSearchingFlag:Integer; { je-li jednotka ve
                       stavu necinnosti, vzdy po dobe
                       ActiveSearchingTGTimeLimit se provede vytypovani
                       cile }
                       { * }
                       MasterCommand:Byte; { bud AttackCom nebo
                       WithoutCom nebo PrepareCom }
                       MasterPhase:Byte;
                       MasterITarg, MasterJTarg : Word;
                       { do MasterCommand se ulozi nejaka globalni
                         akce, napr. utok na dany sektor; tato faze
                         se vsak sklada z nekolika podfazi, ktere se
                         pocitaji v promenne MasterPhase; kod aktualni
                         podfaze je v Command;  }
                       Command:Byte; { aktualni prikazy pro skupinu }
                       ITargPlace, JTargPlace : Word; { cil skupiny }
                       Flag:Byte; { pomocna promenna:
                       - je-li clenem skupiny budova-jednotka na
                         rozlozeni, obsahuje typ volneho mista,
                         ktere chce pridelit; viz FreePlaces-PlaceType }
                       CommandNum:Byte; { poradove cislo prikazu Command -
                       - s pomoci tohoto pocitadla jednotka z taskgrupy
                       zjistuje, zda jiz prikaz provedla }
                       Carriers:PUnit; { zretezeny seznam jednotek
                       taskgrupy, do kterych lze neco nalozit }
                       MoveLevel:Byte; { utocna nebo presunova uroven
                       (0 .. pozemni,1 .. vzdusna) }
                       Lock:Word; { kazda jednotka, pridelena taskgrupe
                       taskgrupu "uzamkne" Inc(Lock); kazda jednotka,
                       vyclenena z taskgrupy ji "odemkne" Dec(Lock);
                       je-li Lock = 0, pak je taskgrupa nepouzita -
                       - v podstate udava pocet jednotek v taskgrupe
                       }
                       CommandLock:Byte; { prikaz je splnen, splni-li
                       ho Lock jednotek; aktualni pocet splnenych
                       prikazu(jednotek) je v CommandLock }
                       CommandLockFlag:Integer; { kazde kolo se
                       tato promenna inkrementuje; pokud se do
                       doby CommandLockFlagLimit nedosahne rovnosti
                       CommandLock >= Lock, bez ohledu na soucasny stav
                       se pro aktivni MasterCommand nastavi dalsi podfaze}
                       CommandLockFlagLimit:Integer; { viz predchozi }
                       AirUnitsCount:Word; { pocet leteckych jednotek v TG }
                       ITaskGroupInfoPos, JTaskGroupInfoPos:Word;
                       { urcuje aktualni umisteni (ctverec) TaskGrupy }

                       AIAttackMode : Byte;  { typ utocneho zamereni TG:
                            0..specialni budova AIAttackBuilding
                            1..specialni jednotka AIAttackUnit
                            2..jednotky
                            3..budovy
                            4..zaskodnictvi
                          }
                       KamikadzeMode:Boolean; { True = jednotka jde tvrde za
                                                splnenim cile TG bez ohledu na ztraty}
                       UnderAttack:Boolean; { pro potreby KamikadzeMode, pokud
                                              se na skupinu utoci }
                       LLightTG: TKategorieArray;{ 3 kategorie lehkych0 }
                       LightTG:  TKategorieArray;{ 3 kategorie lehkych1 }
                       HeavyTG:  TKategorieArray;{ 3 kategorie tezkych }
                       AirTG:    TKategorieArray;{ 3 kategorie vzdusnych }
                       AAttackTG:TKategorieArray;{ 3 kategorie PVO }
                       { nyni obdobny seznam, ale ucinnosti PROTI }
                       AntiLightTG: Single;{ kategorie proti-lehkych}
                       AntiHeavyTG: Single;{ kategorie proti-tezkych }
                       AntiAirTG  : Single;{ kategorie proti-vzdusnych }
                       TGCapacityNeed : LongInt;
                       { celkova POTREBA kapacity carrieru }

                       { * nyni promenne pro potreby utocneho presunu * }
                       Direction:Byte;
                       DirectTarget:Boolean;
                       IgnoreCoefficient:Single;  { udava, jaka sila
                       nepratel se bude pri vypoctu trasy taskgrupy
                       ignorovat; hodnota udava % ze sily taskgrupy;
                       napr. pro 25 = ignorovat silu o hodnote jedne
                       ctvrtiny sily (25%) taskgrupy }

                       { * pro potreby doplneni skupiny: * }
                       Reinfo:TReinfo;

                       { * pro obecne pouziti * }
                       Special:Byte;
                       JoinGrp:Byte; { pro merge com }
                       GrpFree_attack:Boolean; { free_attack pro celou skupinu }
                       AttackInfo: array[0..MaxTGAttackInfo] of record
                           Validity:Boolean; { True, pokud je polozka platna }
                           IAttack, JAttack:Word; { pokud je GrpFree_attack
                           roven True, pak se do techto promennych zaznamena
                           policko, na nez utoci nektera z jednotek TG; pokud
                           nektera jednotka TG necinne "stoji", nebot nema
                           v dosahu cil, zada se ji tato souradnice, aby se
                           i ona do boje zapojila; POUZE PRO POZEMNI UROVEN! }
                           IAirAttack, JAirAttack:Word; { pokud je GrpFree_attack
                           roven True, pak se do techto promennych zaznamena
                           policko, na nez utoci nektera z jednotek TG; pokud
                           nektera jednotka TG necinne "stoji", nebot nema
                           v dosahu cil, zada se ji tato souradnice, aby se
                           i ona do boje zapojila; POUZE PRO VZDUSNOU UROVEN!}
                       end;
                       Fighters, Terminators:Byte; { pocet vzdusnych stihacu a
                                                     protipozemnich stihacu }
                       NoAttackTimming:Word; { casovani utoku }
                       x:Byte;
                       XXX:Word; { pro ucely save/load }
                    end;
      TRacesTGInfo = array[0..MaxRace, 0..MaxRaceTaskGroups] of record
      { informace o jednotlivych TG }
            ActivityGameTime:LongInt;
            IHomeTaskGroupInfoPos, JHomeTaskGroupInfoPos:Word;
            { urcuje aktualni umisteni (ctverec) TaskGrupy }
            LeaderCourageLow,LeaderCourageHigh:Word; { jde o odvahu utoku
            dane rasy; v podstate se jedna o rozmezi procent vlastni sily,
            vzhledem k nepratelum, na nez bude skupina utocit; slabsi skupinu
            ignoruje a silnejsi se boji; napr. hodnoty 80,100 znaci, ze TG
            si bude vybirat nepratele o sile 80%-100% ze sily vlastni TG }
            MoveCourageNormal, MoveCourageSabot:Word; { jde o odvahu presunu
            dane rasy; v podstate se jedna procenta vlastni sily, ktere TG
            pri utocnem presunu ignoruje; t.j. pro MoveCourageNormal =100
            bude TG obchazet vsechny TG, ktere jsou silnejsi a pres ostatni
            "projede"; MoveCourageNormal je pro klasicke utoky,
            MoveCourageSabot se tykaji utoku sabotazni grupy
            }
            TGAtt : Word; { atribut TG:
                           - pro obrannou TG je to okruh (v info polich),
                             ve kterem se provede aktivni vyhledavani cile;
                             napr. pro hodnotu 1 se budou nepratele
                             detekovat pouze v bezprostrednim okoli;
                             Default = 2
                           }

            Lock:Word; { je zde ulozen pocet pozadavku na vyrobu jednotky pro
            danou TG; pokud je pocet <> 0, nesmi se pro danou TG vyrabet
            dalsi jednotky }
            SpecialLock:Word; { uzamyka se pro sabotazni TG tak, aby
                                se vyrabely jen jednou za cas }
            TGMinLimit :Single; { minimalni limit pro TG; mensi vaha
                                  nepritele nez je tato povede k tomu,
                                  ze se nepritel bude brat jako slabsi }
            TGDefenseLimitModif :Single; { z teto hodnoty se pocita sila
                                            obranne TG }
            MaxAirPct:Single;  { maximalni podil vzdusnych jednotek (%) na
                                 sile cele TaskGrupy }
            AALock,ALock,LLock,HLock,CLock:Word; { locky pro produkci pocitace,
                                                   prazdny lock ma hodnotu "1"}
            { nasledujici hodnoty plati pro sabotazni TG: }
            Timmer1, Timmer2, TimmerPlus, TimmerMinus, SaboteurType : Word;
      end;
      TUnitParams = array[1..MaxTypesOfUnits] of record
                       AAttack,LAttack,TAttack:Word; { ruzne typy utoku }
                       Defence, Range:Word;
                       B,P,E,X,MatClass:Word; { udaje o materialu }
                       Capability,Capability2:Word;
                       { dva druhy schopnosti - viz konstanty }
                       AirUnit:Boolean; { True, jde-li o letadlo }
                    end;
      TTFreePlaces = array[0..MaxFreePlaces,0..MaxFreeStructures] of record
                           X,Y:Word; { pozice leveho horniho rohu volneho
                           mista; pro polozku 0,Y je zde souradnice stredu
                           cele prohledavane plochy }
                           PlaceType:Byte;
                    { 1..velikost 64x64, vhodne pro tovarny
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
                      16..velikost 96x96, specialne pro harvestrarny
                      17..velikost 32x32 pro centrum posil
                      255..info o stredu cele plochy (polozka s indexem 0)
                           }
                    end;
      TSpeedArray = array[0..31] of Byte;
      TDebrisInfo = array[0..MaxDebrisInfoIndex] of record
      { informace o pozustatcich a kouri na polickach po znicenych jednotkach }
                      IP,JP : Word; { souradnice policka }
                      FirePhase : Byte; { faze koure (0,2,4,6,8,10) }
                      FireTimmer : Word; { kazdy casovy slot se hodnota
                      dekrementuje; pri 0 kour zmizi (DebrisFireTimmerValue) }
                      DebrisTimmer : Word; { kazdy casovy slot se hodnota
                      dekrementuje; pri 0 kour zmizi (DebrisTimmerValue) }
                      GiveUpTimmer : Byte; { casovani mavani vzdavaci vlajky }
                      DebrisType : Byte; { udava typ obrazku :
                        0,1 .. lide
                        2,3 .. roboti
                        4,5 .. lehka vozidla
                        6,7 .. tezka vozidla
                        8,9 .. letouny
                        14,15 .. kour z trosek
                      }
                   end;
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
                      _Sight:Byte;  { dohled }
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
     TUnitInfo = record
                     Active, Destroyed:Boolean;
                     UnitType:Byte;
                     Experience:Word;
                     Kills:Word;
                     Level:Byte;
                     Name:String[15];
                     UniqueNumber:Word; { pokud je <> 65535, jde o platnou
                     polozku }
                  end;

     TGlobalModify = record { neukladat save/load }
                      { globalni modifikace pro misi }
                         PlayerId:String[8]; { identifikace hrace }
                         Game,Campaign:Byte; { identifikace hry }
                         { modifikace typu jednotek: }
                         UnitTypes:TUnit_types;
                         { nasledujici promenne urcuji pritomnost jednotek
                           s nastavenym nejvyssim bitem SpecNumber: }
                         { seznam jednotek, ktere nevyrabim ja: }
                         MyUnitsForMission:array [1..MaxTypesOfUnits] of Boolean;
                         FriendlySpecialUnitsPresent:Boolean;
                         EnemySpecialUnitsPresent:Boolean;
                         { True pro pritomnost spec. nepratelskych posil }
                         EnemySpecialReinforcementPresent:Boolean;
                         ActionLevel:Byte; { typ hry }
                         GameLevel:Byte;   { obtiznost hry }
                         { nyni schema pro nasledujici hodnoty:
                           0..False, 1..True, > 1..nezmeneno }
                         UnknownTerrain, FogOfWar, AllyFog:Byte;
                         { modifikatory typu rasy:
                           bud hodnota, nebo 255=zustat nezmenene }
                         RaceTypeModifiers: array[0..MaxRace] of Byte;
                         { modifikatory materialu v misi :
                           bud hodnota zmeny v %, nebo MaxInt=zustat nezmenene }
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

var   Locate:String[78];
      BuildingsSold:Word; { pocet prodanych budov me rasy }
      UnitsSold:Word; { pocet prodanych jednotek me rasy }
      TimeOverflow:Boolean;
      Slow:Boolean; { True pro pomalou verzi hry }
      ErrorString:String;
      OldExitProc:Pointer;
      Zrada:Boolean; { True, doslo-li ke zrade - pouze pro misi 54 }
      GameUniqueNumber:LongInt;
      _56MsCounter:LongInt;
      GlobalModify:^TGlobalModify;
      Pictures128:array[0..11] of record { obrazky 128x128 }
                      S,O:Word;
                      Max:BYte; { max. pouzita faze, plati pouze u indexu 0! }
                  end;
      { * Info * }
      UnitsInfoRecord : record
                           Rec:array[1..MaxTypesOfUnits] of Byte;
                           MaxIndex:Byte;
                        end;
      BuildingsInfoRecord : record
                              Rec:array[1..MaxTypesOfBuildings] of Byte;
                              MaxIndex:Byte;
                            end;
      UnAvailUnits: set of 1..MaxTypesOfUnits; { nevyzkoumane jednotky }
      CoreInfo:array[0..MaxCoreUnits-1] of TUnitInfo;
      {teren:}
      TerrainCondition:Byte; {Clear,Sand,Snow,Night,Rain}

    { pomocne promenne _units4, ukladaji a incializuji se taky tam }
    MissionSpecManagerTag:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag1:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag2:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag3:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag4:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag5:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag6:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag7:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag8:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag9:Word; { pomocna promenna, inicializace na 0 }
    MissionSpecManagerTag10:Word; { pomocna promenna, inicializace na 0 }

      Debug:Boolean; { True, pokud se jedna o debug verzi }

      GlobalStep, GlobalJ, bebex, bebey,save1,save2:Word; { ladici informace }

      MissionNameString:String; { cislo, ktere se prida ke standardnimu
                                  nazvu misi }
      MissionNumber:Word; { cislo mise }
{!!!!}ScreenShot:Boolean; {True = navic 2.5MB pameti pro ulozeni obrazku }
      SScreen,OScreen:Word; { pamet pro screenshot }
      SaveScreenMemory:LongInt; { pamet pro screenshot }
{!!!!}Production_time_plus:Single; { urychleni stavby objektu }
{!!!!}Production_order:Boolean; { True, pokud je produkce svazana
      pravidly (napr. recyklaci lze vyrobit az po elektrarne apod.); False
      pokud je vsude veskera produkce dostupna }
{!!!!}SaveGame, LoadGame:Byte; { <> 0, ma-li se hra ulozit/nahrat;
                                 255 autosave }
      DResult:Word; { vysledek IO operaci }
      SavePath:String; { cesta pro ucely ukladani }
      AUTOSAVE:Byte;{ 0..bez autosave; 1..rychly autosave; 2..pomaly autosave }

      { nasledujici promenne urcuji pritomnost jednotek
        s nastavenym nejvyssim bitem SpecNumber:
        (pouze pro potrebu inicializace, neukladat save/load) }
      FriendlySpecialUnitsPresent:Boolean;
      EnemySpecialUnitsPresent:Boolean;
      { True pro pritomnost spec. nepratelskych posil: }
      EnemySpecialReinforcementPresent:Boolean;

      GameStopCount, GameStopCountTimmer:Word; { rizeni stop tlacitka }
      BckSoundTimmer, BckSoundSoundNotUsed : Word;  { BckSoundTimmer pocita
      cas od posledniho pouziti bck zvuku a BckSoundSoundNotUsed dobu,
      po kterou nebyl pouzit ZADNY zvuk }
      IOFile : File;
      CheckFile : File;
      DefendChangeValue, AttackChangeValue, KadenceChangeValue,
      CostChangeValue, UnitProdSpeedChangeValue,BuildProdSpeedChangeValue : Single;
      ActionLevel:Byte;
      { tyto hodnoty globalne meni utocne/obranne schopnosti jednotek,
        coz umoznuje nastavit akcnost hry }
      Retreat:Boolean; { True = aktivovany ustup ze hry }
      RetreatTimmer:Word; { az je na nule, ustup (hra) konci }
      Victory:Integer; { 0..remiza, 1..vitezstvi, -1..porazka }
      EndOfGame : Boolean; { True pro konec aktualni hry }
      EndOfGameChanged:Boolean;  { True pro ukoncovani pres menu }
      EndOfGameTimmer:Word; { casovani ukonceni hry }
      FailedCondition : Integer; { index podminky, na jsem prohral, -1..byl jsem
                                   vybit }
      GameLevel:Byte; { obtiznost hry }
      InDrawResult:Boolean; { pri ukonceni hry }
      SPom, OPom:Word; { pracovni promenna }
      KillMode:Boolean; { True = budou se zobrazovat info o killech }
      OkMarkIPos, OkMarkJPos, OkMarkFlag:Word; OkMarkLevel:Byte;
      OkMarkFlagLimit, OkMarkPhase:Word;
      { znacka presunu na pozici ..IPos, ..JPos, uroven ..Level;
        delka trvani se pocita ve ..Flag; maximalni delka trvani
        je ulozena ve ..FlagLimit; aktualni faze je v OkMarkPhase }
      AttackMarkUnit:PPunit; AttackMarkBuilding:PPBuilding;
      AttackMarkFlag, AttackMarkFlagLimit, AttackMarkPhase:Word;
      { znacka utoku na jednotku/budovu, danou AttackMarkUnit,
       AttackMarkBuilding;  delka trvani se pocita ve ..Flag;
       maximalni delka trvani je ulozena ve ..FlagLimit;
       aktualni faze je v OkMarkPhase }
      IShadowPos1,JShadowPos1,IShadowPos2,JShadowPos2:Word;
      { levy horni a pravy dolni roh obdelniku, do nejz se muze rozlozit
        slozena budova a v nemz se indikacne na kratkou dobu zmeni pozadi }
      BckShadowType:array[0..8] of Word;
      { ulozene puvodni pozadi od leveho horniho rohu po radcich }
      ShadowFlagLimit, ShadowFlag ,ShadowFlagPhase:Word;
      {delka trvani se pocita ve ..Flag;
       maximalni delka trvani je ulozena ve ..FlagLimit;
       aktualni faze je v ShadowFlagPhase }

      { * WayPointy * }
      WayPointDef:Byte; { 0 .. normalni rezim; 1 .. rezim definice waypointu }
      TempWayPoint : TWayPoint; { pomocne pole, pouzivane pri definici
      waypointu }
      TempWayPointMax : Byte; { max vyuzita pozice; 255 = prazdne pole }
      {}
      { zde nalseduje pole pro waypointy ulozene s pomoci F5-F8 }
      SavedWayPoints: array[0..3] of TWayPoint;
      { max vyuzita pozice; 255 = prazdne pole }
      SavedWayPointsMax : array[0..3] of Byte;

      { * VICTORY CONDITIONS * }
      VictoryConditions : ^TVCond;
      CondUk:ShortInt;
      VICTORYPOINTS, POINTS:LongInt;

      { * FOG OF WAR * }
{ !!!!! }  Fog_of_war:Boolean; { True = zapnuta "mlha" }
{ !!!!! }  Smooth_fog_of_war:Boolean; { True = "mlha" ma "zarovnane" obrysy }
{ !!!!! }  Unknown_terrain:Boolean; { True = neprozkoumany teren je cerny }
{ !!!!! }  AllyFog:Boolean; { True, pokud nevidim jednotky kamaradu }
      Grids:array[0..MaxGrids] of record
                  GridSeg, GridOfs : Word; { bitova predloha "mlhy" }
            end;


      { * RANGE CHECK * }
      Range_check_array:^TRange_check_array;

      { * PARAMETRY JEDNOTEK * }
      UnitParams : TUnitParams;

      BattleExperienceDiv:Single;
      ScoreDiv:Single;

      { * CACHE * }
{ !!!!! } InternalCache:Boolean; { True, pouzije-li se interni cache }
      SCache,OCache:Word; { vnitrni cache }
      SCacheUk,OCacheUk:Word; { ukazatel do vnitrni cache }
      CacheValidity:Boolean; { je obsah cache platny? }
      CacheFile:String[80];
      CacheUk:Pointer;
      CachePos,CacheSize:LongInt; { informace o velikosti a pozici v cache }

      { * DATA AI * }
      MaxSearchingRange:Word; { aktivni prohledavaci uroven pocitace }
      MaxDepth:Word; { max. hloubka pri prohledavani okoli jednotky pro presun}
      { True=inteligentni hledani cilu pro utok: }
      IntelliSearching, MyIntelliSearching:Boolean;
      IntelliAttackMovement:Boolean; { True, ma-li taskgrupa inteligentne
                                       obchazet prekazky }
      TaskGroupIntelliAttackMoveCyclesForward:Word;
      { cim vyssi cislo, tim vyssi narocnost, ale i inteligence utocicich
        skupin pocitace }
      TaskGroupIntelliAttackMoveCyclesBackward:Word;
      { cim vyssi cislo, tim vyssi narocnost, ale i inteligence utocicich
        skupin pocitace }
      TaskGroupIntelliAttackMoveCyclesRepeat:Word;
      { minimalne 4, urcuje pocet optimalizacnich opakovani vypoctu cesty;
        zvysovani napr, na 10 ma velmi priznive dopady na optimalnost cesty
        v narocnejsich pripadech }
      GlobalComp, GlobalFriend:Single; { ve GlobalFriend a GlobalComp jsou
                                       souhrne informace o sile mne+spojencu
                                       a pocitace }
      TotalRobotRaces, TotalOSNRaces:Word; { celkovy pocet ras robotu a OSN }
      { globalni sily nepratel }
      GlobalCompLLight,GlobalCompLight,GlobalCompHeavy,
      GlobalCompAir,GlobalCompAAttack:Single; { globalni sila pocitace+friends }
      GlobalFriendLLight,GlobalFriendLight,GlobalFriendHeavy,
      GlobalFriendAir,GlobalFriendAAttack:Single; { globalni sila OSN+friends }
      GlobalCompGroundPct, GlobalFriendGroundPct:Single; { globalni
      procentualni zastoupeni pozemnich jednotek na celkove armade }

      { * DATA O OBRAZOVCE * }
      MaxRes:Word; { udava maximalni pouzite rozliseni ve hre:
      0 .. 640x480; 1 .. 800x600; 2..1024x768; 3..1280x1024 }
      XResolution,YResolution :Word;
      XScreenBeg,YScreenBeg:Word;
      { zacatek leveho horniho rohu kreslici obrazovky }
      XScreenSize,YScreenSize :Word; { velikost kreslici obrazovky }
      XScreenEnd,YScreenEnd :Word;
      { souradnice konce kreslici obrazovky }
      IScreenSize,JScreenSize,IScreenSizeShr2,JScreenSizeShr2:Word;
      { velikost kreslici obrazovky v polickach }
      IMax, JMax : Word; { maximalni souradnice prvku na mape
                           (velikost mapy -1)}
      IBeg, JBeg : Word; { zacatek kreslici obrazovky v polickach
                           (vzhledem k pocatku mapy [0,0]) }
      IBegPom, JBegPom : Word; { pomocna promenna }
      XRes, YRes : Word; { aktualni graficke rozliseni }
      XMemBeg, YMemBeg : Word; { zacatek pracovni EMS pameti pro pozadi
      (inicializacne X2xCellSize+IScreenSize shl XCellShl;
       Y2xCellSize+JScreenSize shl YCellShl;) }
      IMemPom, JMemPom : Word; { zacatek obrazovky v pameti
      (inicializacne IScreenSize, JScreenSize) - pro ucely rolovani }
      IMem1,JMem1:Word;
      IMem2,JMem2:Word;  { krajni souradnice leveho horniho rohu obrazovky
      (polickove) v  EMS pameti(pro ukladani zobrazovane obrazovky
      (velikost 3x3 obrazovky)) }

      XP, YP : Word; { posledni znama pozice kurzoru mysi }
      DrawXORFrame : Boolean; { je mysi povoleno kreslit XorFrame? }
      YInfoBegin : Word; { zacatek info obrazku a dat "naclicknute"
      skupiny jednotek na panelu obrazovky }
      Win1Seg,Win1Ofs,Win1BckSeg,Win1BckOfs:Word;
      { ukazatel na predlohu systemoveho (menu) okna a na ulozene pozadi }
      TempSeg, TempOfs:Word; { pro ukladani pomocnych veci, velikost
      TempPictureMemory }
      TempSeg2, TempOfs2:Word; { pro ukladani pomocnych veci, velikost
      Window1Memory }

      { * SLOTY PRO VYPIS ZPRAV * }
      SmallXBeginConst,SmallYBeginConst:Word;  { zacatek maleho textu }
      BigXBeginConst, BigYBeginConst:Word;  { zacatek velkeho textu }
      SmallMsgLen, BigMsgLen :Word; { delka zpravy ve znacich }
      SmallMsgMem,BigMsgMem :LongInt;
      SmallYMsgDistance:Integer; { rozdil mezi dvema malymi sloty zprav }

      { ***** }
      Disorder:Boolean; { = True .. jednotky, ktere nic nedelaji a pritom
                          jsou videt se pro oziveni sceny ruzne nataci;
                          False .. tento rys je zakazan
{ !!!!! } EnemyStatus : Boolean; { True = je mozne po naclicknuti nepratelske
      jednotky videt vsechny jeji parametry; False = zobrazi se pouze neco }
{ !!!!! } CtrlChangeLevel : Boolean; { pokud je True, vzdusna uroven se
      nastavuje stiskem control a uvolnenim se ztraci; pro False je mozne
      pouzit klasicke nastaveni mysi }

      { * PROBIHA ROLOVANI * }
      ActiveScrolling:Boolean;
      { * ROLOVANI * }
{ !!!!! }ScrollSpeed:Byte;
      { 1 .. rolovani po 64 bodech  !! NEPOUZIVAT !!
        2 .. rolovani po 32 bodech
        3 .. rolovani po 16 bodech
        4 .. rolovani po 8 bodech
        5 .. rolovani po 4 bodech
        6 .. rolovani po 2 bodech
        7 .. rolovani po 1 bodu
      }
      War2Scroll:Boolean;  { True, pokud rolovat jako war2 }

      { * BUDOVY * }
      UpdateEEEnergy:Boolean; { ma se v danem tahu prepsat stav
      elektricke energie ? }
      UpdatePL:Boolean; { ma se v danem tahu prepsat stav plastu ? }
      UpdateBP:Boolean; { ma se v danem tahu prepsat stav materialu ? }
      UpdateEXP:Boolean; { ma se v danem tahu prepsat stav bojove zkusenosti?}
{ !!!!! } AnimatedBuilding:Boolean; { maji se u budov stridat faze 4 a 5 ?}

      { * PROMENNE PRO STAV KLAVESNICE (jednotka Buttons) * }
      SHIFT, CTRL, ALT : Boolean; { po volani funkce GetSpecKeysState
      nastavuje promenne na True (False), jsou-li (nejsou-li) stisknuty }
      PressedKey : Byte; { scan kod prave stisknute klavesy }

      ActuallCursor : Word; { aktualni aktivni typ kurzoru mysi }

      { * PROMENNE PRO POUZITI S TLACITKY * }
      { <>0 (True), bylo-li dane tlacitko stisknuto }
      StopPressed:Byte;
      NalozitPressed:Byte;
      VylozitPressed:Byte;
      PatrolPressed:Byte;
      RozlozitPressed:Byte;
      OpravitPressed:Byte;
      ZvednoutMoralkuPressed:Byte;
      MenuPressed:Boolean;
      RadarModButtonPressed:Boolean;
      SellButtonPressed:Boolean;
      StopGamePressed:Boolean;
      GameStopped:Boolean; { True, je-li hra "pauznuta" }
      MenuActive:Boolean; { True, je-li hra v modu "vybirej z menu" }
      ButtonsBckSeg, ButtonsBckOfs:Word; { podklad pod funkcni tlacitka }

      { * FONT * }
      FontSegment, FontOffsets : Word; { ulozena predloha s fontem }

      bleX, bleY : Word;

      { * INFO O MATERIALECH * }
      First_material_segment, First_material_offset : Word;
      Second_material_segment, Second_material_offset : Word;
      Third_material_segment, Third_material_offset : Word;
      Fourth_material_segment, Fourth_material_offset : Word;

      { * POMOCNE * }
      AirNotReady0Seg,AirNotReady0Ofs : Word; { znak nepripravenosti letadel }
      AirNotReady1Seg,AirNotReady1Ofs : Word; { znak nepripravenosti letadel }
      AirNotReady2Seg,AirNotReady2Ofs : Word; { znak nepripravenosti letadel }
      AirNotReady3Seg,AirNotReady3Ofs : Word; { znak nepripravenosti letadel }
      CrossSegment, CrossOffsets : Word; { zaskrtnuti vybranych slotu }
      PlastyProductSegment, PlastyProductOffset:Word;
      PlastyProductSegment2, PlastyProductOffset2:Word;
      { pro produkci plastu }
{ !!!!! } SpecStatusBar:Boolean; { = True .. u kazde jednotky
      se objevi obdelnicek se stavem poskozeni }
      MarbleSegment, MarbleOffset:Word; { pozadi }
      { obrazky nastaveni vzdalenosti aktivni obrany }
      ADMSeg1,ADMOfs1, ADMSeg2,ADMOfs2, ADMSeg3,ADMOfs3,
      ADMSeg4,ADMOfs4, ADMSeg5,ADMOfs5 : Word;

      { * RESOURCE * }
      { info o "skladkach" s materialem }
      ResourceInfo : array[0..MaxResourceIndex] of record
                       IResourPos, JResourPos : Word; { pozice na mape }
                       Resource : Single;
                       { zasoba na nalezisti*4; max. mozna zasoba je
                         ulozena v konstante MaxResource; nasobeni 4-mi
                         se provadi kvuli snadnejsimu odpoctu, nebot pri
                         recyklaci se zasoba snizuje kazdy casovy slot }
                     end;
      LastUsedResource : Byte; { posledni uzity index pole ResourceInfo }

      { * KURZOR MYSI * }
      NormCursor : Byte; { je-li roven 0, ignoruje se; pokud je <> 0,
      dekrementuje se a pri dekrementaci na 0 se nastavi normalni kurzor }
      LastCursor : Byte; { typ predposledniho typu kurzoru; nastavuje
      jednotka grafika.tpu }
      PomCursor : Byte; { pomocna promenna pro nastavovani predchozi promenne}
      ClickLevel : Byte; { = 0, pracuje se s jednotkami na ClickLevelBase
      urovni; jinak se pracuje s jednotkami opacne urovne }
      ClickLevelBase : Byte; { = 0, pracuje se s jednotkami na 1. urovni; jinak
      se pracuje s jednotkami leteckymi; jedna se o nastavenou uroven pomoci
      mezerniku }
      AnimatedCursor:Byte; { 0..normalni kurzor, 1..animovany kurzor }
      CursorPhase:Byte; { animacni faze kurzoru }
      AnimCursorType:Byte; { typ animovaneho kyrzoru:
       -GoInsideCursor
       -AttackCursor
       -MoveCursor
       -GroupingCursor
       -WaitCursor
       -WayPointRecCursor
       -NormalCursor
      }
      Cursors:array[0..LastCursorType] of record { jednotlive kurzory}
                Mem : array[0..MaxCursorPhase] of record
                { faze kurzoru pro pozemni uroven }
                         S,O:Word;
                      end;
                Mem2 : array[0..MaxCursorPhase] of record
                { faze kurzoru pro vzdusnou uroven }
                         S,O:Word;
                      end;
                MaxPhase : Byte;
              end;


      RepairL1Segment, RepairL1Offset:Word; { obrazek opravy zive jednotky }
      RepairL2Segment, RepairL2Offset:Word;
      RepairL3Segment, RepairL3Offset:Word;
      RepairL4Segment, RepairL4Offset:Word;
      RepairL5Segment, RepairL5Offset:Word;
      RepairH1Segment, RepairH1Offset:Word; { obrazek opravy budovy/jednotky }
      RepairH2Segment, RepairH2Offset:Word;
      RepairH3Segment, RepairH3Offset:Word;
      RepairH4Segment, RepairH4Offset:Word;
      RepairH5Segment, RepairH5Offset:Word;

      DefModeSegment,DefModeOffset:Word; { obrazek modu aktivni obrany }
      SegOk1Cursor,OffsOk1Cursor : Word; { nyni pomocne obrazky }
      SegOk2Cursor,OffsOk2Cursor : Word;
      SegOkAir1Cursor,OffsOkAir1Cursor : Word;
      SegOkAir2Cursor,OffsOkAir2Cursor : Word;
      SegAttack1Cursor,OffsAttack1Cursor : Word;
      SegAttack2Cursor,OffsAttack2Cursor : Word;

      { * SEZNAM SPECIALNICH CISEL * }
      SpecNumList:^TSpecNumList; { pocet existujicich jednotek s danymi
                                   spec. cisly }

      { * CASOVANI HRY * }
{ !!!!! } GameTimming : Byte; { 0 .. "hruba", jinak "jemna" (2x casteji) varianta
                                behu programu }
{ !!!!! } GameSpeed : Byte; { 0.. hrube casovani pomoci hodin; <> 0 pouzije
                              jemny casovac (ms), ktery ale kouse Windows }
{ !!!!! } RealTimeScroll : Boolean; { = True .. pri rolovani se hra nezastavi
      (NUTNE NASTAVENI PRO SITOVOU VERZI); = False .. hra se zastavi }

      Del1,Del2 : Word; { pro proceduru TimerOn }
      Delay1 :Word; { pro proceduru TimerOn, TimerWait }
      Min_game_time, Sec_game_time : Word; { pro realne herni hodiny,
      zobrazovane v pravem hornim rohu }
      Flag_game_time:Byte; { v kazdem cyklu se inkrementuje; po dosazeni
      hodnoty 20 se inkrementuje Sec_game_time }
      Timer_flag:Byte; { pro casovani casovych slotu cele hry }
      RadarBlinkTimming:Byte; { pouzito pro casovani blikani na radaru }
      Timer_flag_seg, Timer_flag_selector:Word;

      { * GAME_TIME KONSTANTY * }
      { tykaji se "hodinoveho ramecku" v pravem hornim rohu }
      Game_timeXBeg,Game_timeYBeg:Word;
      Game_timeXLength,Game_timeYLength:Word;
      MaxFlag_game_time:Word; { po kolikati cyklech se inkrementuje
      herni sekunda }
      { nyni mereni realneho casu }
      RealHourMin, LastRealHourMin:Word; { realny cas }
      RealHourMinX1, RealHourMinY1, RealHourMinX2, RealHourMinY2:Word;

      { * RADAR * }
      XRadarRealBeg, YRadarRealBeg : Word; { skutecny zacatek radaru na obrazovce }
      XRadarRealEnd, YRadarRealEnd : Word; { skutecny konec radaru na obrazovce }
      XRadarBeg,YRadarBeg, XRadarEnd,YRadarEnd:Word;
      { souradnice obrazovky radaru }
      RdrawRadarFrame:Boolean; { True, je-li treba prekreslit i ramecek raadru }

      { * MATERIALS * }
      XMaterialSlotSize, YMaterialSlotSize, XMaterialNumberLength:Word;
      { prvni material }
      XMaterialPicture1, YMaterialPicture1, XMaterialNumber1,
      YMaterialNumber1 :Word;
      { druhy material }
      XMaterialPicture2, YMaterialPicture2, XMaterialNumber2,
      YMaterialNumber2:Word;
      { treti material }
      XMaterialPicture3, YMaterialPicture3, XMaterialNumber3,
      YMaterialNumber3:Word;
      { ctvrty material }
      XMaterialPicture4, YMaterialPicture4, XMaterialNumber4,
      YMaterialNumber4:Word;

      { * STRELY A ZABLESKY * }
      MissileMoveAdd: Word; { ridi rychlost raket }
      Kadence : array[0..10] of Byte; { jednotlive rychlosti strelby }
      {KadenceCompare : array[0..10] of Single;{}
      { porovnani jednotlivych rychlosti strelby vuci max. rychlosti }
      Bullets : array[0..MaxShotTypes] of record
                  S1,O1,S2,O2,S3,O3,S4,O4,S5,O5,S6,O6,S7,O7,S8,O8,
                  S9,O9,S10,O10,S11,O11,S12,O12,S13,O13,S14,O14,S15,O15,S16,O16 : Word;
                  { 8 natoceni strely + totez v druhe fazi }
                  XSize, YSize:Word;
                end;
      Flashs : array[0..MaxShotTypes] of record
                  S1,O1,S2,O2,S3,O3,S4,O4,S5,O5,S6,O6,S7,O7,S8,O8,
                  S9,O9,S10,O10,S11,O11,S12,O12,S13,O13,S14,O14,S15,O15,S16,O16 : Word;
                  { 8 natoceni zablesku + totez v druhe fazi }
                  XSize, YSize:Word;
               end;
      Explosions : array[0..MaxShotTypes] of record
                     S1,O1,S2,O2,S3,O3,S4,O4,S5,O5,S6,O6,S7,O7,S8,O8: Word;
                     { 8 animaci maleho vybuchu (vybuchu strely) }
                     MaxPhase:Word; { pocet animacnich fazi vybuchu u dane strely }
                     XShot, YShot :Word; { rozmery  obrazku }
                     ShotMemory:LongInt;
                   end;
      Explosions2 : record
                       { exploze jednotky 32x32 }
                       Small:array[1..MaxSmallExplosPhase] of record
                                S,O:Word;
                             end;
                       { exploze budovy 64x64 }
                       Medium:array[1..MaxMediumExplosPhase] of record
                                S,O:Word;
                              end;
                       { exploze budovy 96x96 }
                       Big:array[1..MaxBigExplosPhase] of record
                                S,O:Word;
                              end;
                    end;

      Fire : record { nekolik fazi ohne }
                S1,O1,S2,O2,S3,O3,S4,O4:Word; { 3 faze koure pozemni jednotky }
                S21,O21,S22,O22,S23,O23,S24,O24:Word; { 3 faze koure letecke jednotky }
                SB1,OB1,SB2,OB2,SB3,OB3,SB4,OB4:word; { 3 faze koure budovy }
             end;
      { !!!!! } FireAllowed:Boolean; { je-li dovoleno koureni jednotek }

      { * AI * }
      Global_eval_flag : Word;
      LocalStep : Word;

      { * POMOCNY PROSTOR * }
      Price_bck_segment, Price_bck_offset:Word;
      Price_segment, Price_offset : Word;

      { * VYTVARENI SKUPIN * }
      Groups : array[0..MaxGroups] of record
      { pole s ulozenymi skupinami }
                  Count : Byte;  { pocet obsazenych poli }
                  ClickStatus : Byte; { "tlacitkovy status" skupiny :
                  0 : nic se nedeje
                  1 : jednotka je "namacknuta"
                  2 : stisknuto tlacitka "nalozit"
                  3 : stisknuto tlacitko "patrola"
                  254 : namacknuta pratelska jednotka
                  255 : namacknuta nepratelska jednotka
                  }
                  GroupLevel : Byte; { 0 .. skupina pozemnich jednotek
                                       <> 0 .. skupina leteckych jednotek }
                  Un : array [0..MaxGroupUnits-1] of PUnit; { ulozene jednotky }
                  Building : PBuilding; { pokud je naclicknuta budova }
                  U2 : array [0..MaxGroupUnits-1] of Word;
                  { pro potreby save/load game }
                  B2 : Word; { pro potreby save/load game }
                  ADefRng:Word; { active defence range }
               end;
      ActiveGroup : Byte; { index aktivni skupiny; 255 = zadna neni aktivni }
      BckSegment: Word; { pro ucely GroupsBck }
      GroupsBckXSize, GroupsBckYSize :Word; { sirka celeho 1-ho info slotu }
      GroupsBck : array[0..MaxGroupUnits-1] of record  { ulozene pozadi }
                     Active : Boolean; { je-li polozka obsazena }
                     Typ : Byte; { 0 .. jde o jednotku; 1 .. jde o budovu;
                                   2 .. plasty start; 3 .. plasty stop }
                     _unit : PUnit; { ukazatel na ulozenou jednotku }
                     Building : PBuilding; { ukazatel  na pripadnou budovu }
                     ElementType : Byte; { typ bud budovy nebo jednotky }
                     X,Y: Word; { pozice okenka na obrazovce }
                     X1,Y1: Word; {pozice prvniho info "prouzku" na obrazovce}
                     X2,Y2: Word; {pozice druheho info "prouzku" na obrazovce}
                     X3,Y3: Word; {pozice tretiho info "prouzku" na obrazovce}
                     Offsets:Word; { offset v segmentu BckSegment }
                     ProductType:Byte; { pouze pro jednotky v menu vyrobni
                                         budovy }
                     XXX1, XXX2:Word; { pro potreby savegame }
                  end;

      { * INFORMACE O MAPE * }
      MapBck : ^MapBckArray;
      MapBckTemp : ^MapBckTempArray;

      Map : ^MapArray;

      { * INFORMACE O TYPU JEDNOTEK * }
      Unit_pictures : array[1..MaxTypesOfUnits] of record
                         O1, O2, O3, O4, O5, O6, O7, O8:Word;
                         S1, S2, S3, S4, S5, S6, S7, S8 : Word;
                         S9, S10, S11, S12, S13, S14, S15, S16 : Word;
                         O9, O10, O11, O12, O13, O14, O15, O16:Word;
                         O17, O18, O19, O20, O21, O22, O23, O24:Word;
                         S17, S18, S19, S20, S21, S22, S23, S24 : Word;
                         S25, S26, S27, S28, S29, S30, S31, S32 : Word;
                         O25, O26, O27, O28, O29, O30, O31, O32 :Word;
                      end;
      UnitSpeedPct : array[0..6] of Byte;

      Unit_types : TUnit_types;

      { * JEDNOTKY * }
      Units : array[1..(MaxRaceUnits+1)*(MaxRace+1)] of PUnit;
      { pole informaci o kazde vyrobene jednotce }
      Number_of_units : Word; { pocet aktualnich jednotek }

      {  * STRELY * }
      Shots : array[1..MaxMovingObjects] of PShots;
      { pole informaci o kazde vypustene strele }
      Number_of_shots : Word; { pocet aktualnich strel }

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

      { * BUDOVY * }
      Buildings : array[1..(MaxRaceBuildings+1)*(MaxRace+1)] of PBuilding;
      { pole informaci o kazde postavene budove }
      Number_of_buildings : Word; { pocet aktualnich budov }

      { * POZADI * }
      Background : array[0..511] of record
      { zde jsou ulozeny obrazky pozadi }
                                      Segment:Word; { segment }
                                      Offsets:Word; { offset }
                                    end;
      { * VOJENSKE HODNOSTI * }
      ExperienceLevel : array[0 .. MaxExperienceSerie] of record
                           Segment, Offsets : Word;
                           { obrazky s vojenskymi hodnostmi; 0 je zakl.
                             hodnost - pozadi }
                        end;
      { * TROSKY * }
      { !!!!! } Debris:Boolean; { = True .. po kazde vybuchle jednotce
      zbydou trosky }
      DebrisPicture : array[0 .. MaxDebris] of record
                         DebrisSegment,Offsets : Word;
                         { obrazek pozustatku; jde o nasledujici schema:
                           0 .. people1   1 .. people2
                           2 .. robots1   3 .. robots2
                           4 .. light1    5 .. light2
                           6 .. heavy1    7 .. heavy2
                           8 .. air1      9 .. air2
                           fire1,2 .. kour
                           10-11 .. budova 1x1
                           12-19 .. komponenty budovy 2x2
                           giveup1,2,3 .. jednotka se vzdala
                           kour1-6
                         }
                      end;
      DebrisInfo : ^TDebrisInfo;
      DebrisInfoIndex : Byte;
      { ukazuje na 1. volnou polozku v poli DebrisInfo; index pracuje s metodou
        preteceni (MaxDebrisInfoIndex -> 0) }
      LowDebrisInfoIndex : Byte;
      { ukazuje na 1. pouzitou polozku v poli DebrisInfo }
      { 255 MUSI BYT NEPLATNY INDEX }

      { * SLOTY PRO VYPIS TEXTU * }
      MsgStruct : record
                    SmallMsgBckSeg, SmallMsgBckOffs : Word;
                    SmallMsgBckSeg2,SmallMsgBckOffs2:Word;
                    { pozadi maleho textu }
                    BigMsgBckSeg, BigMsgBckOffs : Word;
                    { pozadi velke hlasky }
                    SmallXBegin, SmallYBegin : Word; { zacatek maleho textu }
                    BigXBegin, BigYBegin : Word; { zacatek velkeho textu }
                    SmallTimeHourMin: Word;  SmallTimeSec : Byte;
                    { v pripade, ze promenne maji hodnotu 0, je dany slot
                      nepouzit; jinak jde o hodnotu, po dasazeni ktere
                      hodinami realneho casu se slot vynuluje }
                    BigTimeHourMin : Word;  BigTimeSec : Byte;
                    { v pripade, ze promenne maji hodnotu 0, je dany slot
                      nepouzit; jinak jde o hodnotu, po dasazeni ktere
                      hodinami realneho casu se slot vynuluje }
                  end;

      { * INFORMACE O RASE * }
      RacesTGInfo : ^TRacesTGInfo;

      Races: array[0..MaxRace] of record
           RRGB, GRGB, BRGB:Byte;
           InitUnitLevel:Word; { inicializacni vyrobni hodnost }
           ChangeOnVisib:Boolean; { True, ma-li se rasa zmenit na me
                                  jednotky, je-li objekt mnou viden }
           GSBuild:Boolean; { True, by-li jednou postaven Gen. stab }
           MaxRecyclatorNum:Word;
           Neutral:Boolean; { True, je-li rasa neutralni }
           HelpRace:Boolean; { True, pokud je rasa pomocna, t.j. jejim
           jedinym objektem je prekazka; tato rasa nebude ve skore }
           RaceName:String[15];
           RaceColor:Byte; { barva rasy }
           RaceType:Byte; { typ rasy :
           { 0..OSN; 1..Odboj; 2..Kolaboranti; 3..Roboti;
             4..OSNNeutral; 5..RobotiNeutral; 6..RobotiOSN }
           Friend: array[0..MaxRace] of Byte;
           { pro danou rasu je to "pole pratelstvi" s ostatnimi rasami:
             0..nepritel
             1..neutral (jednotky na sebe neutoci)
             2..pritel (vidi si vsechny atributy jednotek, vidi navzajem
                sve viditelne casti mapy)
           }
           Ally:Byte; { 0..nepritel (pocitac), 1..kamarad }
           VisMask:Word; { maska pro visibility }
           GlobalMorale:Single; { globalni zmeny moralky }
           GlobalMoraleTemp:Single;
           Harvester_credits_plus:Single;
           { jde o koeficient, ktery se prida k nakladu harvesteru pri jeho
             vylozeni (Harvester_credits_plus*HarvesterCapacity) }
           EE_credits_plus:Single;
           { jde o koeficient, ktery se prida k produkci elektrarny
             (EE_credits_plus*EEProduction) }
           Score:LongInt;
           Number_of_race_units : Word;
           Number_of_race_buildings : Word;
           PermittedUnits: TPermittedUnits;
           { priznak, zda muze dana rasa danou jednotku vyrabet: }
           PermittedBuildings: array[1..MaxTypesOfBuildings] of Boolean;
           { priznak, zda muze dana rasa danou budovu vyrabet: }
           Building_credits, Plastic_credits, Electric_energy,
           Battle_experience : Integer;
           { materialove zdroje jednotlivych ras }
           EECapacity : Word; { kapacita akumulatoru a elektraren }
           { * INFORMACE O LETISTICH * }
           Free_airport_space : array[0..MaxAirportSpace] of record
                                  IFree, JFree : Word;
                                  Pos:Byte; { pozice policka uvnitr letiste:
                                                 0 1
                                                 2 3
                                  }
                                end;
           I_free_airport_space_max_index : Byte; { posl. obsazeny index }
           { souradnice volnych mist pro pristani letadel }
           RecyklatorBuildInfo : array[0..MaxRecyklatorBuildInfoIndex] of record
           { informace o recyklacnich budovach dane rasy }
                                    IP, JP :Word; { souradnice budovy - recyklatoru }
                                 end;
           LastRecyklatorBuildInfoIndex:Byte; { posledni pouzity index;
           hodnota MaxRecyklatorBuildInfoIndex+1 znamena, ze je neplatny }
           RecyklatorBuildInfoCount:Byte; { pocet budov recyklace }

           MaxRepairCapacity : Word; { udava celkovou opravarenskou kapacitu }
           RepairsAvailable : Integer; { udava volnou opravarenskou kapacitu,
           zaporne cislo znaci nutnost zastavit nejakou probihajici opravu }

           Recyclators : Byte; { pocet recyklatoru }
           UnpackedBuildings : Word; { pocet rozlozenych budov -
           pro snizeni poctu znicenych jednotek v glob. statistikach }
           { seznam existujicich budov dane rasy: }
           ExistBuildings : array[1..MaxTypesOfBuildings] of Word;
           { seznam celkove vyrobenych budov dane rasy: }
           ProducedBuildings : array[1..MaxTypesOfBuildings] of Word;

           { seznam existujicich jednotek dane rasy: }
           ExistUnits : array[1..MaxTypesOfUnits] of Word;
           { seznam celkove vyrobenych jednotek dane rasy: }
           ProducedUnits : array[1..MaxTypesOfUnits] of Word;

           { seznam znicenych jednotek danou rasou: }
           KilledUnits : array[1..MaxTypesOfUnits] of Word;
           { seznam znicenych jednotek danou rasou: }
           KilledBuildings : array[1..MaxTypesOfBuildings] of Word;

           { ukazatel na seznam existujicich exemplaru danych typu budov: }
           PointerToBuildings : array[1..MaxTypesOfBuildings] of PBuilding;
           { pro ucely save/load: }
           PTB2 : array[1..MaxTypesOfBuildings] of Word;
           CentraPosil:PUnit; { seznam center posil }
           PTCP:Word;

           _ProducedUnitsAll, _InGameProducedUnits,
           _ProducedBuildingsAll, _InGameProducedBuildings,
           _KilledUnits, _KilledBuildings,
           _LostBuildings, _LostUnits : Single;

           TG_Reinfo_ExecuteFlag:Word; { je-li rovno 0, provede se
           procedura TG_Reinfo_Execute }

           TGPlusActivity:Word; { 0 = nema se doplnovat grupa TGPlus;
                                  1 = doplnovani je pro utocne TG
                                  2 = doplnovani je pro obranne TG }

           DefendLock:Word; { je zde ulozen pocet pozadavku na vyrobu obrannych
           instalaci pro danou rasu; pokud je pocet <> 0, nesmi se pro danou
           TG vyrabet dalsi jednotky }

           OverStrengthEnemy:Word; { urcuje, kolik procent ze sily
           nepratelske TG se ma pro ucely AI zapocitat; napr. pro
           OverStrengthEnemy=110 se kazda nepratelska sila zapocita
           o 10% silnejsi }

           DruhaPlastarnaVeVyrobe:Boolean;
           BPShortage, PLShortage, EEShortage, EXPShortage,
           AccumulatorShortage, Base2Shortage, BarrackShortage,
           HeavyFactoryShortage, SpecialFactoryShortage,
           DefenceFactoryShortage, RepairFactoryShortage,
           LightFactoryShortage, CentrumPosilShortage,
           RadarShortage, AirportShortage:Word;
           { <> 0 .. je zde problem s nedostatkem prislusne suroviny,
             energie,budovy ... }
           BPShortageForbid, PLShortageForbid, EEShortageForbid,
           EXPShortageForbid, AccumulatorShortageForbid,
           Base2ShortageForbid, BarrackShortageForbid,
           HeavyFactoryShortageForbid, SpecialFactoryShortageForbid,
           DefenceFactoryShortageForbid,RepairFactoryShortageForbid,
           LightFactoryShortageForbid, RadarShortageForbid,
           AirportShortageForbid, CentrumPosilShortageForbid:Integer;
           { <> 0 .. je zakazano reagovat na xxShortage (pracuje se
           na odstraneni problemu) }
           PLHiNeed:Integer;
           Forbid:Boolean; { True = je zakazano vyrabet jakoukoli produkci
           vyjma te, ktera podporuje vyrobu materialu }

           { v techto promennych bude ulozena prumerna cena jednotky a
             budovy: }
           BPUnitCostAver,PLUnitCostAver,EEUnitCostAver,EXUnitCostAver,
           BPBuildCostAver,PLBuildCostAver,EEBuildCostAver,EXBuildCostAver:Word;

           { seznam aktualnich naroku na opravy: }
           BPRepair, PLRepair, EERepair, ExpRepair:Single;

           { seznam volnych mist pro staveni }
           FreePlaces : ^TTFreePlaces;
           ActualFreeStructures:Byte; { prvni volny index do pole FreePlaces }

           { inicializacni pocet potrebnych instalaci }
           GndDefNeedInit, AADefNeedInit:Single;
           DefInstalPriorityFlag:Byte; { flag pro pocitani viz nize }
           DefInstalPriority:Word;  { priorita vyberu obrannych instalaci:
                                      0..100%
                                      1..50%
                                      2..33%
                                      3..25%
                                      4..20%
                                      5..16%
                                      6..14%
                                      7..12%
                                      atd.
                                      19..5%

                                      bit 128: nastaven - vyssi priorita vyroby
                                                          (33% vezi se vyrobi
                                                           s vyssi prioritou)
                                               nulovy - normalni priorita vyroby
                                    }
           { NYNI INFORMACE O TASKGRUPACH }
           ParaEnabled:Word; { <> 0 pro vzdusneho utocnika }
           TaskGroups : ^TTaskGroups;
           { nyni minimalni pocty taskgroup pro jednotlive kategorie
             (je-li aktivnich TG mene, AI pocitace je doplni) }
           AttackTGNum, DefenceTGNum, SaboteurTGNum : Word;
           FighterTimmer, TerminatorTimmer:Word;
      end; { * RACES  * }
      MyRace : Byte; { cislo me rasy (0-MaxRace) }
      MyRaceType :Byte; { skutecny typ me rasy :
      0 .. OSN, 1.. odboj, 2.. kolaboranti, 3..roboti }
      ThisCompRace1, ThisCompRace2, ThisCompRace3, ThisCompRace4,
      ThisCompRace5 : Byte; { cisla ras, ovladanych timto pocitacem
      (dulezite pri hre po siti) }

      { * DATA PRO AI * }
      IMapInfoMax, JMapInfoMax:Word; { maximalni skutecne  vyuzitelne indexy
                                       pole MapInfo }
      MapInfo : ^TMapInfo;
      BuildRadar : ^TBuildRadar;
      BuildRadarMod : Boolean; { True, pokud jsou na radaru informace o budovach }

      { * NAHODNA CISLA * }
      RandomArray:array[0..MaxRandomArrayIndex] of Byte;
      RndUk:Byte;

      PlayerId:String[8]; { identifikace hrace }
      Game,Campaign:Byte; { identifikace hry }

      { * ODCHYTANI CHYB * }
      TimeSlot:Word; { cislo slotu }
      Counter1, Counter2:Word;

      { PRO POTREBY AI, AI3}
      GlobalInfo:array[0..1] of record
                  { pole pro globalni strategii; index 0 je pro vlastni
                    pozici; index 1 je soucet okoli }
                  { nejprve pocet nepratelskych a pratelskych
                    pozemnich jednotek}
                  EnemyAirCount, EnemyGroundCount:Word;
                  FriendlyAirCount, FriendlyGroundCount:Word;
                  { nyni jejich sila }
                  FriendlyAirStrength,FriendlyGroundStrength:Single;
                  EnemyAirStrength,EnemyGroundStrength:Single;
                  { a nyni info o budovach a spec. cilech nepritele }
                  EnemyBuildings:Word;
                  FriendlyBuildings:Word;
                  EnemySpecial:Word;
                  EnemyLLight,EnemyLight,EnemyHeavy,EnemyAir,EnemyAAttack:Word;
               end;
    GlobalInfoCount : Word; { pocet aktivnich (nenulovych) sousedu }


function Rand(var RandomUk:Byte):Byte;
procedure InvalidateCache;
function CacheDataInvalid(Way:String):Boolean;
function CacheInit:Boolean;
function CacheFetch(FileName:String):Word;
procedure CacheSeek(var InFile:File; Pos:LongInt);
function CacheEof(var InFile:File):Boolean;
procedure CacheBlockRead(var InFile:File; Place:Pointer; Count:Word);
procedure New_task_group_carrier(Race,TaskGroupNum:Byte; var C:PUnit);
procedure Delete_task_group_carrier(Race,TaskGroupNum:Byte; var C:PUnit);
procedure Close_gr_mode;
procedure GetSpecKeysState;
function ReadKeys(var Scan:Byte):Byte;
function ReadKeys2(var Scan:Byte):Byte;
procedure ClearKeyboardBuffer;
procedure SetDelay(Delay:Byte);
function GetAccurateDelay(Del:Word):word;
function GetDistance(IThis, JThis, ITar, JTar : Word): Word;
procedure SetAttackTGInfo(Race,TaskGroup,Level:Byte; IAim,JAim:Word);
procedure ClearAttackTGInfo(Race,TaskGroup:Byte);
procedure ClearActiveAttackTGInfoXY(Race,TaskGroup,Level:Byte; IAim,JAim:Word);
function GetActiveAttackTGInfo(Race,TaskGroup,Level:Byte; IPos,JPos:Word; var IAim,JAim:Word):Boolean;
function GetCoreNum:Byte;
function GetCoreUnit(UnitType:Word; var TUI:TUnitInfo):Boolean;
procedure DestroyCoreUnit(UniqueNumber:Word);
procedure SetTerminator_fighterParams(LowPrice:Boolean);
procedure SaveGameCfg;
procedure LoadGameCfg;
procedure Data_save;
procedure Data_load;

{ ************************************************************************* }
implementation

var I,J,K:Word;

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
   if ((not CacheValidity) or (SCache = 0) or (not InternalCache))
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
   Pom:={GlobalCompact({}MaxCacheMemory{){}; { pokus najit souvisly pas pameti }
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
label Konec, Skip, Skip2;
var InFile:File;
    Result:Word;
    I,Delka1, Delka2,S,O:Word;
    PomUk:Pointer;
begin
   Result:=0; PomUk:=CacheUk; CacheFile:=FileName; CacheValidity:=False;
   Assign(InFile,FileName);
   Reset(InFile,1); Result:=IOResult; if (Result <> 0) then GoTo Konec;
   if (not InternalCache) then GoTo Skip2;{}

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
   CacheValidity:=True;
   SCacheUk:=SCache; OCacheUk:=OCache;
   GoTo Skip;
Konec:
   CacheValidity:=False;
Skip:
   Close(InFile);
Skip2:
   CachePos:=0;
   CacheFetch:=Result;
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
procedure New_task_group_carrier(Race,TaskGroupNum:Byte; var C:PUnit);
{ priradi do TaskGrupy vozidlo, ktere ma nejakou kapacitu pro prevoz vojska
}
begin
 with (Races[Race]) do begin
   if (TaskGroups^[TaskGroupNum].Validity) then
   with (TaskGroups^[TaskGroupNum]) do begin
      if (Carriers = Nil) then begin { zadny neni ve skupine }
        Carriers:=Units[C^.Index]; C^.Next:=Nil;
      end else begin { neco tu jiz je }
        Units[C^.Index]^.Next:=Carriers;
        Carriers:=Units[C^.Index];
      end;
   end;
 end; { with (Races[Race]) do begin }
end;

{ ***** }
procedure Delete_task_group_carrier(Race,TaskGroupNum:Byte; var C:PUnit);
{ vyhodi z TaskGrupy vozidlo, ktere ma nejakou kapacitu pro prevoz vojska
}
var Pom:PUnit;
begin
 with (Races[Race]) do begin
   if (TaskGroups^[TaskGroupNum].Validity) then
   with (TaskGroups^[TaskGroupNum]) do begin
      Pom:=Carriers;
      if (Pom = C) then Carriers:=Carriers^.Next
      else begin
        while ((Pom <> Nil) and (Pom^.Next <> Units[C^.Index])) do
          Pom:=Pom^.Next;
        if ((Pom <> Nil) and (Pom^.Next = C)) then begin
          Pom^.Next:=Pom^.Next^.Next;
        end;
      end;
   end;
 end; { with (Races[Race]) do begin }
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
  v klidovem stavu vraci Scan 255, Ascii 0
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
procedure ClearKeyboardBuffer;
{ vycisti buffer klavesnice
}
var Scan:Byte;
begin
   while (ReadKeys(Scan) <> 0) do;
end;

{ ***** }
procedure SetDelay(Delay:Byte);
{
}
begin
   case (Delay) of
     {5 : begin Del1:=5; Del2:=0; end;
     4 : begin Del1:=4; Del2:=20000; end;{}
     3 : begin if (GameSpeed= 0) then Del1:=3 else Del1:=1; Del2:=20000; end;
     2 : begin if (GameSpeed= 0) then Del1:=2 else Del1:=0; Del2:=50000; end;
     1 : begin if (GameSpeed= 0) then Del1:=1 else Del1:=0; Del2:=30000; end;
     { nejrychlejsi }
   else
   end;
end;

{ ***** }
function GetAccurateDelay(Del:Word):Word;
{ procedura prepocita zpozdeni, pocitane na maximalni rychlost, na aktualni
  rychlost
}
const Modif1 = 0.2; Modif2 = 0.25; Modif3 = 0.4; Modif4 = 0.65; Modif5 = 1.0;
var Pom:Single;
begin
   Pom:=Del; if (GameSpeed = 1) then Pom:=Pom*1.2;
   case (Delay1) of
     5 : begin Pom:=Pom*Modif1; GetAccurateDelay:=Round(Pom); end;
     4 : begin Pom:=Pom*Modif2; GetAccurateDelay:=Round(Pom);  end;
     3 : begin Pom:=Pom*Modif3; GetAccurateDelay:=Round(Pom);  end;
     2 : begin Pom:=Pom*Modif4; GetAccurateDelay:=Round(Pom);  end;
     1 : begin Pom:=Pom*Modif5; GetAccurateDelay:=Round(Pom);  end;
   else
   end;
   if (Round(Pom) = 0) then GetAccurateDelay:=1;
end;

{ ***** }
function GetDistance(IThis, JThis, ITar, JTar : Word): Word;
{ vraci vzdalenost z bodu IThis, JThis do ITar, JTar
}
var Pom1, Pom2 : Word;
begin
   Pom1:= abs(Integer(ITar)-Integer(IThis));
   Pom2:=abs(Integer(JTar)-Integer(JThis));
   if (Pom1 > Pom2) then GetDistance:=Pom1
   else GetDistance:=Pom2;
end;

{ ***** }
procedure SetAttackTGInfo(Race,TaskGroup,Level:Byte; IAim,JAim:Word);
{ procedura nastavi dany cil do pameti aktualnich cilu TG
}
var I:Word;
begin
 with (Races[Race]) do with (TaskGroups^[TaskGroup]) do begin
   I:=0;
   while ((I <= MaxTGAttackInfo) and (AttackInfo[I].Validity)) do Inc(I);
   if (I <= MaxTGAttackInfo) then
     if (Level = 0) then begin
       AttackInfo[I].IAttack:=IAim;
       AttackInfo[I].JAttack:=JAim;
       AttackInfo[I].Validity:=True;
     end else begin
       AttackInfo[I].IAirAttack:=IAim;
       AttackInfo[I].JAirAttack:=JAim;
       AttackInfo[I].Validity:=True;
   end;
 end;
end;

{ ***** }
procedure ClearAttackTGInfo(Race,TaskGroup:Byte);
{ procedura vymaze pamet taskgrupy
}
var I:Word;
begin
 with (Races[Race]) do with (TaskGroups^[TaskGroup]) do begin
   for I:=0 to MaxTGAttackInfo do with (AttackInfo[I]) do begin
     Validity:=False;
     IAttack:=65535; JAttack:=65535;
     IAirAttack:=65535; JAirAttack:=65535;
   end;
 end;
end;

{ ***** }
procedure ClearActiveAttackTGInfoXY(Race,TaskGroup,Level:Byte; IAim,JAim:Word);
{ vymaze z pameti TG souradnici IAim, JAim (je-li tam)
}
var I:Word;
    Distance:Word;
begin
 Distance:=65535;
 with (Races[Race]) do with (TaskGroups^[TaskGroup]) do begin
   for I:=0 to MaxTGAttackInfo do with (AttackInfo[I]) do begin
     if (Validity and
        ((Level = 1) and (IAirAttack = IAim) and (JAirAttack = JAim) or
         (Level = 0) and (IAttack = IAim) and (JAttack = JAim)))
     then begin
       Validity:=False;
       IAttack:=65535; JAttack:=65535;
       IAirAttack:=65535; JAirAttack:=65535;
     end;
   end;
 end;
end;

{ ***** }
function GetActiveAttackTGInfo(Race,TaskGroup,Level:Byte; IPos,JPos:Word; var IAim,JAim:Word):Boolean;
{ procedura vrati True, pokud je k dispozici nejaky cil na urovni Level
  a vraci k nemu souradnice IAim, JAim
}
var I:Word;
    Distance:Word;
begin
 Distance:=65535;
 with (Races[Race]) do with (TaskGroups^[TaskGroup]) do begin
   GetActiveAttackTGInfo:=False;
   for I:=0 to MaxTGAttackInfo do with (AttackInfo[I]) do begin
     if (Validity and
        ((Level = 1) and (IAirAttack <> 65535) and (JAirAttack <> 65535) or
         (Level = 0) and (IAttack <> 65535) and (JAttack <> 65535)))
     then begin
     { vhodny adept }
        if (Level = 0) then begin
           if (GetDistance(IPos,JPos,IAttack,JAttack) < Distance) then begin
              Distance:=GetDistance(IPos,JPos,IAttack,JAttack);
              IAim:=IAttack; JAim:=JAttack;
              GetActiveAttackTGInfo:=True;
           end;
        end else begin
           if (GetDistance(IPos,JPos,IAirAttack,JAirAttack) < Distance) then begin
              Distance:=GetDistance(IPos,JPos,IAirAttack,JAirAttack);
              IAim:=IAirAttack; JAim:=JAirAttack;
              GetActiveAttackTGInfo:=True;
           end;
        end;
     end;
   end;
 end;
end;

{ ***** }
function GetCoreNum:Byte;
{ vrati pocet aktivnich jednotek jadra
}
var I,Count:Byte;
begin
  Count:=0;
  for I:=0 to MaxCoreUnits-1 do
    if (CoreInfo[I].Active) then Inc(Count);
  GetCoreNum:=Count;
end;

{ ***** }
function GetCoreUnit(UnitType:Word; var TUI:TUnitInfo):Boolean;
{ vraci jednotku jadra, ktera alespon trochu odpovida jednotce UnitType;
  jednotku vraci v promenne TUI, sama vraci uspesnost operace
}
var I,J:Word;
begin
  bebex:=2000; save2:=UnitType;
  GetCoreUnit:=False; J:=255;
  for I:=0 to MaxCoreUnits-1 do
  if (CoreInfo[I].Active) then begin
    bebex:=2002;
    if (J = 255) then J:=I;
    bebex:=2004;
    if (UnitType = CoreInfo[I].UnitType) then begin
       save1:=CoreInfo[I].UnitType;
       bebex:=2003;
       CoreInfo[I].Active:=False; GetCoreUnit:=True; TUI:=CoreInfo[I]; Exit;
    end;
    bebex:=2005;
    if (Unit_types[UnitType,1].TargetTyp = Unit_types[CoreInfo[I].UnitType,1].TargetTyp)
    then begin
       J:=I;
    end;
  end;
  bebex:=2001;
  if (J <> 255) then begin
    CoreInfo[J].Active:=False; GetCoreUnit:=True; TUI:=CoreInfo[J];
  end;
end;

{ ***** }
procedure DestroyCoreUnit(UniqueNumber:Word);
{ rusi jednotku jadra daneho UniqueNumber
}
var I:Word;
begin
   for I:=0 to MaxCoreUnits-1 do begin
      if (CoreInfo[I].UniqueNumber = UniqueNumber)
      then CoreInfo[I].Destroyed:=True;
   end;
end;

{ ***** }
procedure SetTerminator_fighterParams(LowPrice:Boolean);
{ procedura nastavi odlisne parametry a cenu vyroby stihace a terminatora
  LowPrice=cena pro pocitac
}
begin
   { STIHAC }
   bebex:=1;
   with (Unit_types[18,0]) do begin
     LightAttack1:=250; HeavyAttack1:=215; AirAttack1:=270;
     BP:=280; PL:=35; EE:=200; EX:=40 div 3;
   end;
   with (Unit_types[18,1]) do begin
     LightAttack1:=250; HeavyAttack1:=215; AirAttack1:=270;
     if (LowPrice) then begin
       BP:=280; PL:=35; EE:=200; EX:=40 div 3;
     end else begin
       BP:=380; PL:=75; EE:=200; EX:=40;
     end;
   end;
   { TERMINATOR }
   with (Unit_types[19,0]) do begin
     LightAttack1:=380; HeavyAttack1:=540; AirAttack1:=50;
     BP:=250; PL:=40; EE:=195; EX:=45 div 3;
   end;
   with (Unit_types[19,1]) do begin
     LightAttack1:=380; HeavyAttack1:=540; AirAttack1:=50;
     if (LowPrice) then begin
       BP:=250; PL:=40; EE:=195; EX:=45 div 3;
     end else begin
       BP:=350; PL:=80; EE:=195; EX:=45;
     end;
   end;
   bebex:=2;
end;

{ ***** }
procedure SaveGameCfg;
{ ulozi nektera nastaveni hry
}
begin
  Assign(IOFile,'game.cfg'); ReWrite(IOFile,1);
  DResult:=IOResult;

   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,SoundSettings,SizeOf(SoundSettings)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,AUTOSAVE,SizeOf(AUTOSAVE)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,Delay1,SizeOf(Delay1)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,MovementStep,SizeOf(MovementStep)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,War2Scroll,SizeOf(War2Scroll)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,XResolution,SizeOf(XResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,YResolution,SizeOf(YResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,ScrollSpeed,SizeOf(ScrollSpeed)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,Slow,SizeOf(Slow)); DResult:=IOResult;
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
  Assign(IOFile,'game.cfg'); Reset(IOFile,1);
  DResult:=IOResult;
  if (DResult = 2) then
    GoTo K { soubor neexistuje, nic se neprovede }
  else ;

   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,SoundSettings,SizeOf(SoundSettings)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,AUTOSAVE,SizeOf(AUTOSAVE)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,Delay1,SizeOf(Delay1)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
   SetDelay(Delay1);
{x}BlockRead(IOFile,MovementStep,SizeOf(MovementStep)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,War2Scroll,SizeOf(War2Scroll)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,XResolution,SizeOf(XResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,YResolution,SizeOf(YResolution)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,ScrollSpeed,SizeOf(ScrollSpeed)); DResult:=IOResult;
   if (DResult<>0) then begin Writeln('ERROR game.cfg - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockRead(IOFile,Slow,SizeOf(Slow)); DResult:=IOResult;
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
procedure Data_save;
{ pro potreby ulozeni hry
}
label K;
var UnitsPom : array[1..(MaxRaceUnits+1)*(MaxRace+1)] of Boolean;
    ShotsPom : array[1..MaxMovingObjects] of Boolean;
    BuildingsPom : array[1..(MaxRaceBuildings+1)*(MaxRace+1)] of Boolean;
    I:Word;
begin
  Assign(IOFile,'save\'+SavePath+'2'); ReWrite(IOFile,1); DResult:=IOResult;if(DResult<>0)
  then begin Erase(CheckFile);GoTo K;end;
   if (DResult<>0) then begin Writeln('ERROR save 2 - diskova chyba ',DResult); Close(IOFile); Erase(IOFile); Halt; end;
{x}BlockWrite(IOFile,BuildingsSold,SizeOf(BuildingsSold));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,UnitsSold,SizeOf(UnitsSold));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{xxx}
{x}BlockWrite(IOFile,TimeOverflow,SizeOf(TimeOverflow));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GameUniqueNumber,SizeOf(GameUniqueNumber));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,UnitsInfoRecord,SizeOf(UnitsInfoRecord));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BuildingsInfoRecord,SizeOf(BuildingsInfoRecord));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TerrainCondition,SizeOf(TerrainCondition));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MissionNameString,SizeOf(MissionNameString));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BattleExperienceDiv,SizeOf(BattleExperienceDiv));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ScoreDiv,SizeOf(ScoreDiv));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Production_time_plus,SizeOf(Production_time_plus));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Production_order,SizeOf(Production_order));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,DefendChangeValue,SizeOf(DefendChangeValue));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AttackChangeValue,SizeOf(AttackChangeValue));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,KadenceChangeValue,SizeOf(KadenceChangeValue));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Retreat,SizeOf(Retreat));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,RetreatTimmer,SizeOf(RetreatTimmer));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ActionLevel,SizeOf(ActionLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Victory,SizeOf(Victory));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,EndOfGame,SizeOf(EndOfGame));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,EndOfGameTimmer,SizeOf(EndOfGameTimmer));DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GameLevel,SizeOf(GameLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,KillMode,SizeOf(KillMode));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OkMarkIPos,SizeOf(OkMarkIPos));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OkMarkJPos,SizeOf(OkMarkJPos));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OkMarkFlag,SizeOf(OkMarkFlag));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OkMarkLevel,SizeOf(OkMarkLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OkMarkFlagLimit,SizeOf(OkMarkFlagLimit));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,OkMarkPhase,SizeOf(OkMarkPhase));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AttackMarkFlag,SizeOf(AttackMarkFlag));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AttackMarkFlagLimit,SizeOf(AttackMarkFlagLimit));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AttackMarkPhase,SizeOf(AttackMarkPhase));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IShadowPos1,SizeOf(IShadowPos1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IShadowPos2,SizeOf(IShadowPos2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JShadowPos1,SizeOf(JShadowPos1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JShadowPos2,SizeOf(JShadowPos2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BckShadowType,SizeOf(BckShadowType));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ShadowFlagLimit,SizeOf(ShadowFlagLimit));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ShadowFlag,SizeOf(ShadowFlag));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ShadowFlagPhase,SizeOf(ShadowFlagPhase));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * WAYPOINTY * }
{x}BlockWrite(IOFile,WayPointDef,SizeOf(WayPointDef));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TempWayPoint,SizeOf(TempWayPoint));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TempWayPointMax,SizeOf(TempWayPointMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,SavedWayPoints,SizeOf(SavedWayPoints));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,SavedWayPointsMax,SizeOf(SavedWayPointsMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * VICTORY CONDITIONS * }
{x}BlockWrite(IOFile,VictoryConditions^,SizeOf(VictoryConditions^));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,CondUk,SizeOf(CondUk));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * FOG_OF_WAR * }
{x}BlockWrite(IOFile,Fog_of_war,SizeOf(Fog_of_war));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Smooth_fog_of_war,SizeOf(Smooth_fog_of_war));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Unknown_terrain,SizeOf(Unknown_terrain));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AllyFog,SizeOf(AllyFog));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * DATA PRO AI * }
{x}BlockWrite(IOFile,MaxSearchingRange,SizeOf(MaxSearchingRange));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MaxDepth,SizeOf(MaxDepth));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IntelliSearching,SizeOf(IntelliSearching));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IntelliAttackMovement,SizeOf(IntelliAttackMovement));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TaskGroupIntelliAttackMoveCyclesForward,SizeOf(TaskGroupIntelliAttackMoveCyclesForward));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TaskGroupIntelliAttackMoveCyclesBackward,SizeOf(TaskGroupIntelliAttackMoveCyclesBackward));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TaskGroupIntelliAttackMoveCyclesRepeat,SizeOf(TaskGroupIntelliAttackMoveCyclesRepeat));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{xxxxxxx}
{x}BlockWrite(IOFile,GlobalCompLLight,SizeOf(GlobalCompLLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalCompLight,SizeOf(GlobalCompLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalCompHeavy,SizeOf(GlobalCompHeavy));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalCompAir,SizeOf(GlobalCompAir));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalCompAAttack,SizeOf(GlobalCompAAttack));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriendLLight,SizeOf(GlobalFriendLLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriendLight,SizeOf(GlobalFriendLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriendHeavy,SizeOf(GlobalFriendHeavy));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriendAir,SizeOf(GlobalFriendAir));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriendAAttack,SizeOf(GlobalFriendAAttack));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalCompGroundPct,SizeOf(GlobalCompGroundPct));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriendGroundPct,SizeOf(GlobalFriendGroundPct));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * DATA O OBRAZOVCE * }
{x}BlockWrite(IOFile,XResolution,SizeOf(XResolution));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YResolution,SizeOf(YResolution));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,XScreenBeg,SizeOf(XScreenBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YScreenBeg,SizeOf(YScreenBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,XScreenSize,SizeOf(XScreenSize));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YScreenSize,SizeOf(YScreenSize));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,XScreenEnd,SizeOf(XScreenEnd));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YScreenEnd,SizeOf(YScreenEnd));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IMax,SizeOf(IMax));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JMax,SizeOf(JMax));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IBeg,SizeOf(IBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JBeg,SizeOf(JBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IBegPom,SizeOf(IBegPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JBegPom,SizeOf(JBegPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,XRes,SizeOf(XRes));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YRes,SizeOf(YRes));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,XMemBeg,SizeOf(XMemBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YMemBeg,SizeOf(YMemBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,IMemPom,SizeOf(IMemPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JMemPom,SizeOf(JMemPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,YInfoBegin,SizeOf(YInfoBegin));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * OBECNE  * }
{x}BlockWrite(IOFile,Disorder,SizeOf(Disorder));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,EnemyStatus,SizeOf(EnemyStatus));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,CtrlChangeLevel,SizeOf(CtrlChangeLevel));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AUTOSAVE,SizeOf(AUTOSAVE));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GameStopCount,SizeOf(GameStopCount));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GameStopCountTimmer,SizeOf(GameStopCountTimmer));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BckSoundTimmer,SizeOf(BckSoundTimmer));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BckSoundSoundNotUsed,SizeOf(BckSoundSoundNotUsed));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,EnemySpecialReinforcementPresent,SizeOf(EnemySpecialReinforcementPresent));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,CoreInfo,SizeOf(CoreInfo));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * PROBIHA ROLOVANI * }
{x}BlockWrite(IOFile,ActiveScrolling,SizeOf(ActiveScrolling));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ScrollSpeed,SizeOf(ScrollSpeed));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,War2Scroll,SizeOf(War2Scroll));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * BUDOVY * }
{x}BlockWrite(IOFile,AnimatedBuilding,SizeOf(AnimatedBuilding));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * PROMENNE PRO STAV KLAVESNICE (jednotka Buttons) * }
{x}BlockWrite(IOFile,ActuallCursor,SizeOf(ActuallCursor));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * PROMENNE PRO POUZITI S TLACITKY * }
{ * FONT * }
{ * INFO O MATERIALECH * }
{x}BlockWrite(IOFile,SpecStatusBar,SizeOf(SpecStatusBar));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * POMOCNE * }
{ * RESOURCE * }
{x}BlockWrite(IOFile,ResourceInfo,SizeOf(ResourceInfo));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,LastUsedResource,SizeOf(LastUsedResource));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * KURZOR MYSI * }
{x}BlockWrite(IOFile,NormCursor,SizeOf(NormCursor));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,LastCursor,SizeOf(LastCursor));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ClickLevel,SizeOf(ClickLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ClickLevelBase,SizeOf(ClickLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AnimatedCursor,SizeOf(AnimatedCursor));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,CursorPhase,SizeOf(CursorPhase));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,AnimCursorType,SizeOf(AnimCursorType));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * CASOVANI HRY * }
{x}BlockWrite(IOFile,GameTimming,SizeOf(GameTimming));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,RealTimeScroll,SizeOf(RealTimeScroll));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Del1,SizeOf(Del1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Del2,SizeOf(Del2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Delay1,SizeOf(Delay1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Min_game_time,SizeOf(Min_game_time));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Sec_game_time,SizeOf(Sec_game_time));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Flag_game_time,SizeOf(Flag_game_time));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Timer_flag,SizeOf(Timer_flag));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,RadarBlinkTimming,SizeOf(RadarBlinkTimming));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * GAME_TIME KONSTANTY * }
{ * RADAR * }
{ * MATERIALS * }
{ * STRELY A ZABLESKY * }
{x}BlockWrite(IOFile,Kadence,SizeOf(Kadence));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * VYTVARENI SKUPIN * }
{x}BlockWrite(IOFile,ActiveGroup,SizeOf(ActiveGroup));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O MAPE * }
{x}BlockWrite(IOFile,MapBck^,SizeOf(MapBck^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MapBckTemp^,SizeOf(MapBckTemp^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Map^,SizeOf(Map^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,BuildRadar^,SizeOf(BuildRadar^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O TYPU JEDNOTEK * }
{x}BlockWrite(IOFile,Unit_types,SizeOf(Unit_types));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * JEDNOTKY * }
{x}BlockWrite(IOFile,Number_of_units,SizeOf(Number_of_units));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,UnitParams,SizeOf(UnitParams));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{  * STRELY * }
{x}BlockWrite(IOFile,Number_of_shots,SizeOf(Number_of_shots));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O TYPU BUDOV * }
{ * BUDOVY * }
{x}BlockWrite(IOFile,Number_of_buildings,SizeOf(Number_of_buildings));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * POZADI * }
{ * VOJENSKE HODNOSTI * }
{ * TROSKY * }
{x}BlockWrite(IOFile,Debris,SizeOf(Debris));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,DebrisInfo^,SizeOf(DebrisInfo^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,DebrisInfoIndex,SizeOf(DebrisInfoIndex));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,LowDebrisInfoIndex,SizeOf(LowDebrisInfoIndex));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * SLOTY PRO VYPIS TEXTU * }
{x}BlockWrite(IOFile,MsgStruct.SmallTimeHourMin,SizeOf(MsgStruct.SmallTimeHourMin));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MsgStruct.SmallTimeSec,SizeOf(MsgStruct.SmallTimeSec));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MsgStruct.BigTimeHourMin,SizeOf(MsgStruct.BigTimeHourMin));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MsgStruct.BigTimeSec,SizeOf(MsgStruct.BigTimeSec));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O RASE * }
   for J:=0 to MaxRace do with (Races[J]) do begin
     for I:=1 to MaxTypesOfBuildings do
       if (PointerToBuildings[I] <> Nil) then PTB2[I]:=PointerToBuildings[I]^.Index
       else PTB2[I]:=65535;

     for I:=0 to MaxRaceTaskGroups do with TaskGroups^[I] do
       if ((TaskGroups^[I].Validity) and (Carriers <> Nil)) then XXX:=Carriers^.Index
       else XXX:=65535;

     if (CentraPosil <> Nil) then PTCP:=CentraPosil^.Index
     else PTCP:=65535;
   end;
{x}BlockWrite(IOFile,Races,SizeOf(Races));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   for I:=0 to MaxRace do begin
   {x}BlockWrite(IOFile,Races[I].TaskGroups^,SizeOf(Races[I].TaskGroups^));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {x}BlockWrite(IOFile,Races[I].FreePlaces^,SizeOf(Races[I].FreePlaces^));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;
{x}BlockWrite(IOFile,RacesTGInfo^,SizeOf(RacesTGInfo^));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MyRace,SizeOf(MyRace));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MyRaceType,SizeOf(MyRaceType));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ThisCompRace1,SizeOf(ThisCompRace1));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ThisCompRace2,SizeOf(ThisCompRace2));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ThisCompRace3,SizeOf(ThisCompRace3));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ThisCompRace4,SizeOf(ThisCompRace4));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,ThisCompRace5,SizeOf(ThisCompRace5));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * DATA PRO AI * }
{x}BlockWrite(IOFile,IMapInfoMax,SizeOf(IMapInfoMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,JMapInfoMax,SizeOf(JMapInfoMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,MapInfo^,SizeOf(MapInfo^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalComp,SizeOf(GlobalComp));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,GlobalFriend,SizeOf(GlobalFriend));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,TotalRobotRaces,SizeOf(TotalRobotRaces));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);
   GoTo K;end;
{x}BlockWrite(IOFile,TotalOSNRaces,SizeOf(TotalOSNRaces));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);
   GoTo K;end;
{ * NAHODNA CISLA * }
{x}BlockWrite(IOFile,RandomArray,SizeOf(RandomArray));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,RndUk,SizeOf(RndUk));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * IDENTIFIKACE HRY * }
{x}BlockWrite(IOFile,PlayerId,SizeOf(PlayerId));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Game,SizeOf(Game));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Campaign,SizeOf(Campaign));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * ODCHYTANI CHYB * }
{x}BlockWrite(IOFile,TimeSlot,SizeOf(TimeSlot));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Counter1,SizeOf(Counter1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,Counter2,SizeOf(Counter2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ ---------- }
{ * ZBYTKY * }
{ ---------- }
{ * SEZNAM SPECIALNICH CISEL * }
{x}BlockWrite(IOFile,SpecNumList^,SizeOf(SpecNumList^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * JEDNOTKY, STRELY, BUDOVY * }
{x}BlockWrite(IOFile,MissileMoveAdd,SizeOf(MissileMoveAdd));DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   {}
   for I:=1 to (MaxRaceUnits+1)*(MaxRace+1) do
       UnitsPom[I]:=Units[I] <> Nil;
{x}BlockWrite(IOFile,UnitsPom,SizeOf(UnitsPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   for I:=1 to MaxMovingObjects do
       ShotsPom[I]:=Shots[I] <> Nil;
{x}BlockWrite(IOFile,ShotsPom,SizeOf(ShotsPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   for I:=1 to (MaxRaceBuildings+1)*(MaxRace+1) do
       BuildingsPom[I]:=Buildings[I] <> Nil;
{x}BlockWrite(IOFile,BuildingsPom,SizeOf(BuildingsPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

   { jednotky }
   for I:=1 to (MaxRaceUnits+1)*(MaxRace+1) do if (Units[I] <> Nil) then with (Units[I]^) do begin
      if (Next = Nil) then XXX:=65535 else XXX:=Next^.Index;
      if ((Target = Nil) or (Target^ = Nil)) then XXX1:=65535
      else XXX1:=Target^^.Index;
      if ((BTarget = Nil) or (BTarget^ = Nil)) then XXX2:=65535
      else XXX2:=BTarget^^.Index;
      if ((AIAttackUnit = Nil) or (AIAttackUnit^ = Nil)) then XXX3:=65535
      else XXX3:=AIAttackUnit^^.Index;
      if ((AIAttackBuilding = Nil) or (AIAttackBuilding^ = Nil)) then XXX4:=65535
      else XXX4:=AIAttackBuilding^^.Index;
   {x}BlockWrite(IOFile,Units[I]^,SizeOf(Units[I]^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;
   { budovy }
   for I:=1 to (MaxRaceBuildings+1)*(MaxRace+1) do if (Buildings[I] <> Nil) then begin
      if (Buildings[I]^.Next = Nil) then Buildings[I]^.XXX:=65535 else Buildings[I]^.XXX:=Buildings[I]^.Next^.Index;
   {x}BlockWrite(IOFile,Buildings[I]^,SizeOf(Buildings[I]^));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;
   { strely }
   for I:=1 to MaxMovingObjects do if (Shots[I] <> Nil) then with (Shots[I]^) do begin
      if ((Target = Nil) or (Target^ = Nil)) then XXX1:=65535
      else XXX1:=Target^^.Index;
      if ((BTarget = Nil) or (BTarget^ = Nil)) then XXX2:=65535
      else XXX2:=BTarget^^.Index;
      if (Next = Nil) then XXX3:=65535 else XXX3:=Next^.Index;
      if ((Father = Nil) or (Father^ = Nil)) then XXX4:=65535
      else XXX4:=Father^^.Index;
   {x}BlockWrite(IOFile,Shots[I]^,SizeOf(Shots[I]^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;

   { * WAYPOINTS * }
   if ((AttackMarkUnit = Nil) or (AttackMarkUnit^ = Nil)) then begin
      I:=65535;
   {x}BlockWrite(IOFile,I,SizeOf(I));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end else begin
   {x}BlockWrite(IOFile,AttackMarkUnit^^.Index,SizeOf(AttackMarkUnit^^.Index));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;

   if ((AttackMarkBuilding = Nil) or (AttackMarkBuilding^ = Nil)) then begin
      I:=65535;
   {x}BlockWrite(IOFile,I,SizeOf(I));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end else begin
   {x}BlockWrite(IOFile,AttackMarkBuilding^^.Index,SizeOf(AttackMarkBuilding^^.Index));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;

{ * VYTVARENI SKUPIN * }
   for I:=0 to MaxGroupUnits-1 do with (GroupsBck[I]) do begin
     if (_unit = Nil) then XXX1:=65535 else XXX1:=_unit^.Index;
     if (Building = Nil) then XXX2:=65535 else XXX2:=Building^.Index
   end;
{x}BlockWrite(IOFile,GroupsBck,SizeOf(GroupsBck));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

   for I:=0 to MaxGroups do with (Groups[I]) do begin
     for J:=0 to MaxGroupUnits-1 do
       if (Un[J] <> Nil) then U2[J]:=Un[J]^.Index else U2[J]:=65535;
     if (Building <> Nil) then B2:=Building^.Index else B2:=65535;
   end;
{x}BlockWrite(IOFile,Groups,SizeOf(Groups));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Data_load;
{ pro potreby ulozeni hry
}
label K;
var UnitsPom : array[1..(MaxRaceUnits+1)*(MaxRace+1)] of Boolean;
    ShotsPom : array[1..MaxMovingObjects] of Boolean;
    BuildingsPom : array[1..(MaxRaceBuildings+1)*(MaxRace+1)] of Boolean;
    I:Word;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'2'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BuildingsSold,SizeOf(BuildingsSold));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,UnitsSold,SizeOf(UnitsSold));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{xxx}
{x}BlockRead(IOFile,TimeOverflow,SizeOf(TimeOverflow));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GameUniqueNumber,SizeOf(GameUniqueNumber));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,UnitsInfoRecord,SizeOf(UnitsInfoRecord));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BuildingsInfoRecord,SizeOf(BuildingsInfoRecord));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TerrainCondition,SizeOf(TerrainCondition));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MissionNameString,SizeOf(MissionNameString));
   DResult:=IOResult; if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BattleExperienceDiv,SizeOf(BattleExperienceDiv));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ScoreDiv,SizeOf(ScoreDiv));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Production_time_plus,SizeOf(Production_time_plus));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Production_order,SizeOf(Production_order));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,DefendChangeValue,SizeOf(DefendChangeValue));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AttackChangeValue,SizeOf(AttackChangeValue));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,KadenceChangeValue,SizeOf(KadenceChangeValue));
  DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Retreat,SizeOf(Retreat));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,RetreatTimmer,SizeOf(RetreatTimmer));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ActionLevel,SizeOf(ActionLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Victory,SizeOf(Victory));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,EndOfGame,SizeOf(EndOfGame));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,EndOfGameTimmer,SizeOf(EndOfGameTimmer));DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GameLevel,SizeOf(GameLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,KillMode,SizeOf(KillMode));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OkMarkIPos,SizeOf(OkMarkIPos));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OkMarkJPos,SizeOf(OkMarkJPos));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OkMarkFlag,SizeOf(OkMarkFlag));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OkMarkLevel,SizeOf(OkMarkLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OkMarkFlagLimit,SizeOf(OkMarkFlagLimit));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,OkMarkPhase,SizeOf(OkMarkPhase));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AttackMarkFlag,SizeOf(AttackMarkFlag));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AttackMarkFlagLimit,SizeOf(AttackMarkFlagLimit));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AttackMarkPhase,SizeOf(AttackMarkPhase));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IShadowPos1,SizeOf(IShadowPos1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IShadowPos2,SizeOf(IShadowPos2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JShadowPos1,SizeOf(JShadowPos1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JShadowPos2,SizeOf(JShadowPos2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BckShadowType,SizeOf(BckShadowType));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ShadowFlagLimit,SizeOf(ShadowFlagLimit));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ShadowFlag,SizeOf(ShadowFlag));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ShadowFlagPhase,SizeOf(ShadowFlagPhase));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * WAYPOINTY * }
{x}BlockRead(IOFile,WayPointDef,SizeOf(WayPointDef));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TempWayPoint,SizeOf(TempWayPoint));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TempWayPointMax,SizeOf(TempWayPointMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,SavedWayPoints,SizeOf(SavedWayPoints));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,SavedWayPointsMax,SizeOf(SavedWayPointsMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * VICTORY CONDITIONS * }
{x}BlockRead(IOFile,VictoryConditions^,SizeOf(VictoryConditions^));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,CondUk,SizeOf(CondUk));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * FOG_OF_WAR * }
{x}BlockRead(IOFile,Fog_of_war,SizeOf(Fog_of_war));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Smooth_fog_of_war,SizeOf(Smooth_fog_of_war));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Unknown_terrain,SizeOf(Unknown_terrain));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AllyFog,SizeOf(AllyFog));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * DATA PRO AI * }
{x}BlockRead(IOFile,MaxSearchingRange,SizeOf(MaxSearchingRange));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MaxDepth,SizeOf(MaxDepth));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IntelliSearching,SizeOf(IntelliSearching));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IntelliAttackMovement,SizeOf(IntelliAttackMovement));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TaskGroupIntelliAttackMoveCyclesForward,SizeOf(TaskGroupIntelliAttackMoveCyclesForward));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TaskGroupIntelliAttackMoveCyclesBackward,SizeOf(TaskGroupIntelliAttackMoveCyclesBackward));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TaskGroupIntelliAttackMoveCyclesRepeat,SizeOf(TaskGroupIntelliAttackMoveCyclesRepeat));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ xxxxx }
{x}BlockRead(IOFile,GlobalCompLLight,SizeOf(GlobalCompLLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalCompLight,SizeOf(GlobalCompLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalCompHeavy,SizeOf(GlobalCompHeavy));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalCompAir,SizeOf(GlobalCompAir));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalCompAAttack,SizeOf(GlobalCompAAttack));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriendLLight,SizeOf(GlobalFriendLLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriendLight,SizeOf(GlobalFriendLight));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriendHeavy,SizeOf(GlobalFriendHeavy));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriendAir,SizeOf(GlobalFriendAir));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriendAAttack,SizeOf(GlobalFriendAAttack));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalCompGroundPct,SizeOf(GlobalCompGroundPct));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriendGroundPct,SizeOf(GlobalFriendGroundPct));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * DATA O OBRAZOVCE * }
{x}BlockRead(IOFile,XResolution,SizeOf(XResolution));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YResolution,SizeOf(YResolution));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,XScreenBeg,SizeOf(XScreenBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YScreenBeg,SizeOf(YScreenBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,XScreenSize,SizeOf(XScreenSize));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YScreenSize,SizeOf(YScreenSize));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,XScreenEnd,SizeOf(XScreenEnd));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YScreenEnd,SizeOf(YScreenEnd));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IMax,SizeOf(IMax));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JMax,SizeOf(JMax));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IBeg,SizeOf(IBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JBeg,SizeOf(JBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IBegPom,SizeOf(IBegPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JBegPom,SizeOf(JBegPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,XRes,SizeOf(XRes));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YRes,SizeOf(YRes));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,XMemBeg,SizeOf(XMemBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YMemBeg,SizeOf(YMemBeg));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,IMemPom,SizeOf(IMemPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JMemPom,SizeOf(JMemPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,YInfoBegin,SizeOf(YInfoBegin));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * OBECNE  * }
{x}BlockRead(IOFile,Disorder,SizeOf(Disorder));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,EnemyStatus,SizeOf(EnemyStatus));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,CtrlChangeLevel,SizeOf(CtrlChangeLevel));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AUTOSAVE,SizeOf(AUTOSAVE));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GameStopCount,SizeOf(GameStopCount));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GameStopCountTimmer,SizeOf(GameStopCountTimmer));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BckSoundTimmer,SizeOf(BckSoundTimmer));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BckSoundSoundNotUsed,SizeOf(BckSoundSoundNotUsed));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,EnemySpecialReinforcementPresent,SizeOf(EnemySpecialReinforcementPresent));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,CoreInfo,SizeOf(CoreInfo));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * PROBIHA ROLOVANI * }
{x}BlockRead(IOFile,ActiveScrolling,SizeOf(ActiveScrolling));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ScrollSpeed,SizeOf(ScrollSpeed));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,War2Scroll,SizeOf(War2Scroll));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * BUDOVY * }
{x}BlockRead(IOFile,AnimatedBuilding,SizeOf(AnimatedBuilding));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * PROMENNE PRO STAV KLAVESNICE (jednotka Buttons) * }
{x}BlockRead(IOFile,ActuallCursor,SizeOf(ActuallCursor));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * PROMENNE PRO POUZITI S TLACITKY * }
{ * FONT * }
{ * INFO O MATERIALECH * }
{x}BlockRead(IOFile,SpecStatusBar,SizeOf(SpecStatusBar));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * POMOCNE * }
{ * RESOURCE * }
{x}BlockRead(IOFile,ResourceInfo,SizeOf(ResourceInfo));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,LastUsedResource,SizeOf(LastUsedResource));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * KURZOR MYSI * }
{x}BlockRead(IOFile,NormCursor,SizeOf(NormCursor));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,LastCursor,SizeOf(LastCursor));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ClickLevel,SizeOf(ClickLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ClickLevelBase,SizeOf(ClickLevel));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AnimatedCursor,SizeOf(AnimatedCursor));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,CursorPhase,SizeOf(CursorPhase));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,AnimCursorType,SizeOf(AnimCursorType));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * CASOVANI HRY * }
{x}BlockRead(IOFile,GameTimming,SizeOf(GameTimming));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,RealTimeScroll,SizeOf(RealTimeScroll));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Del1,SizeOf(Del1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Del2,SizeOf(Del2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Delay1,SizeOf(Delay1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Min_game_time,SizeOf(Min_game_time));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Sec_game_time,SizeOf(Sec_game_time));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Flag_game_time,SizeOf(Flag_game_time));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Timer_flag,SizeOf(Timer_flag));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,RadarBlinkTimming,SizeOf(RadarBlinkTimming));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * GAME_TIME KONSTANTY * }
{ * RADAR * }
{ * MATERIALS * }
{ * STRELY A ZABLESKY * }
{x}BlockRead(IOFile,Kadence,SizeOf(Kadence));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * VYTVARENI SKUPIN * }
{x}BlockRead(IOFile,ActiveGroup,SizeOf(ActiveGroup));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O MAPE * }
{x}BlockRead(IOFile,MapBck^,SizeOf(MapBck^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MapBckTemp^,SizeOf(MapBckTemp^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Map^,SizeOf(Map^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BuildRadar^,SizeOf(BuildRadar^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O TYPU JEDNOTEK * }
{x}BlockRead(IOFile,Unit_types,SizeOf(Unit_types));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * JEDNOTKY * }
{x}BlockRead(IOFile,Number_of_units,SizeOf(Number_of_units));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,UnitParams,SizeOf(UnitParams));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{  * STRELY * }
{x}BlockRead(IOFile,Number_of_shots,SizeOf(Number_of_shots));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O TYPU BUDOV * }
{ * BUDOVY * }
{x}BlockRead(IOFile,Number_of_buildings,SizeOf(Number_of_buildings));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * POZADI * }
{ * VOJENSKE HODNOSTI * }
{ * TROSKY * }
{x}BlockRead(IOFile,Debris,SizeOf(Debris));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,DebrisInfo^,SizeOf(DebrisInfo^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,DebrisInfoIndex,SizeOf(DebrisInfoIndex));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,LowDebrisInfoIndex,SizeOf(LowDebrisInfoIndex));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * SLOTY PRO VYPIS TEXTU * }
{x}BlockRead(IOFile,MsgStruct.SmallTimeHourMin,SizeOf(MsgStruct.SmallTimeHourMin));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MsgStruct.SmallTimeSec,SizeOf(MsgStruct.SmallTimeSec));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MsgStruct.BigTimeHourMin,SizeOf(MsgStruct.BigTimeHourMin));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MsgStruct.BigTimeSec,SizeOf(MsgStruct.BigTimeSec));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * INFORMACE O RASE * }
   for I:=0 to MaxRace do if (Races[I].TaskGroups <> Nil) then begin
     Dispose(Races[I].TaskGroups); Races[I].TaskGroups:=Nil;
     Dispose(Races[I].FreePlaces); Races[I].FreePlaces:=Nil;
   end;
{x}BlockRead(IOFile,Races,SizeOf(Races));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   for I:=0 to MaxRace do begin
      New(Races[I].TaskGroups);
   {x}BlockRead(IOFile,Races[I].TaskGroups^,SizeOf(Races[I].TaskGroups^));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
      New(Races[I].FreePlaces);
   {x}BlockRead(IOFile,Races[I].FreePlaces^,SizeOf(Races[I].FreePlaces^));
      DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   end;
{x}BlockRead(IOFile,RacesTGInfo^,SizeOf(RacesTGInfo^));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MyRace,SizeOf(MyRace));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MyRaceType,SizeOf(MyRaceType));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ThisCompRace1,SizeOf(ThisCompRace1));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ThisCompRace2,SizeOf(ThisCompRace2));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ThisCompRace3,SizeOf(ThisCompRace3));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ThisCompRace4,SizeOf(ThisCompRace4));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ThisCompRace5,SizeOf(ThisCompRace5));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * DATA PRO AI * }
{x}BlockRead(IOFile,IMapInfoMax,SizeOf(IMapInfoMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,JMapInfoMax,SizeOf(JMapInfoMax));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,MapInfo^,SizeOf(MapInfo^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalComp,SizeOf(GlobalComp));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,GlobalFriend,SizeOf(GlobalFriend));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,TotalRobotRaces,SizeOf(TotalRobotRaces));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);
   GoTo K;end;
{x}BlockRead(IOFile,TotalOSNRaces,SizeOf(TotalOSNRaces));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);
   GoTo K;end;
{ * NAHODNA CISLA * }
{x}BlockRead(IOFile,RandomArray,SizeOf(RandomArray));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,RndUk,SizeOf(RndUk));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * IDENTIFIKACE HRY * }
{x}BlockRead(IOFile,PlayerId,SizeOf(PlayerId));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Game,SizeOf(Game));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Campaign,SizeOf(Campaign));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ * ODCHYTANI CHYB * }
{x}BlockRead(IOFile,TimeSlot,SizeOf(TimeSlot));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Counter1,SizeOf(Counter1));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,Counter2,SizeOf(Counter2));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{ ---------- }
{ * ZBYTKY * }
{ ---------- }
{ * SEZNAM SPECIALNICH CISEL * }
{x}BlockRead(IOFile,SpecNumList^,SizeOf(SpecNumList^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

{ * JEDNOTKY, STRELY, BUDOVY * }
{x}BlockRead(IOFile,MissileMoveAdd,SizeOf(MissileMoveAdd));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,UnitsPom,SizeOf(UnitsPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,ShotsPom,SizeOf(ShotsPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,BuildingsPom,SizeOf(BuildingsPom));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

   for I:=1 to (MaxRaceUnits+1)*(MaxRace+1) do begin
     if (Units[I] <> Nil) then begin
        Dispose(Units[I]); Units[I]:=Nil;
     end;
     if (UnitsPom[I]) then begin
       New(Units[I]);
       BlockRead(IOFile,Units[I]^,SizeOf(Units[I]^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     end;
   end;
   {x}
   for I:=1 to (MaxRaceBuildings+1)*(MaxRace+1) do begin
     if (Buildings[I] <> Nil) then begin
        Dispose(Buildings[I]); Buildings[I]:=Nil;
     end;
     if (BuildingsPom[I]) then begin
       New(Buildings[I]);
       BlockRead(IOFile,Buildings[I]^,SizeOf(Buildings[I]^));
       DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     end;
   end;
   { vsechny budovy jsou inicializovane }
   for I:=1 to (MaxRaceBuildings+1)*(MaxRace+1) do begin
     if (BuildingsPom[I]) then begin
       if (Buildings[I]^.XXX = 65535) then Buildings[I]^.Next:=Nil else Buildings[I]^.Next:=Buildings[Buildings[I]^.XXX];
     end;
   end;
   { vsechny _units jsou inicializovane }
   for I:=1 to (MaxRaceUnits+1)*(MaxRace+1) do begin
     if (UnitsPom[I]) then with (Units[I]^) do begin
       if (XXX = 65535) then Next:=Nil else Next:=Units[XXX];
       if (XXX1 = 65535) then Target:=Nil else Target:=@Units[XXX1];
       if (XXX2 = 65535) then BTarget:=Nil else BTarget:=@Buildings[XXX2];
       if (XXX3 = 65535) then AIAttackUnit:=Nil else AIAttackUnit:=@Units[XXX3];
       if (XXX4 = 65535) then AIAttackBuilding:=Nil else AIAttackBuilding:=@Buildings[XXX4];
     end;
   end;

   for I:=1 to MaxMovingObjects do begin
     if (Shots[I] <> Nil) then begin
       Dispose(Shots[I]); Shots[I]:=Nil;
     end;
     if (ShotsPom[I]) then begin
       New(Shots[I]);
       BlockRead(IOFile,Shots[I]^,SizeOf(Shots[I]^));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
     end;
   end;
   { vsechny budovy jsou inicializovane }
   for I:=1 to MaxMovingObjects do begin
     if (ShotsPom[I]) then begin
       with (Shots[I]^) do begin
          if (XXX1 = 65535) then Target:=Nil else Target:=@Units[XXX1];
          if (XXX2 = 65535) then BTarget:=Nil else BTarget:=@Buildings[XXX2];
          if (XXX3 = 65535) then Next:=Nil else Next:=Shots[XXX3];
          if (XXX4 = 65535) then Father:=Nil else Father:=@Units[XXX4];
       end;
     end;
   end;

   {x}BlockRead(IOFile,I,SizeOf(I));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   if (I = 65535) then AttackMarkUnit := Nil
   else AttackMarkUnit:=@Units[I];
   {x}BlockRead(IOFile,I,SizeOf(I));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   if (I = 65535) then AttackMarkBuilding := Nil
   else AttackMarkBuilding:=@Buildings[I];

{ * VYTVARENI SKUPIN * }
{x}BlockRead(IOFile,GroupsBck,SizeOf(GroupsBck));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   for I:=0 to MaxGroupUnits-1 do with (GroupsBck[I]) do begin
     if (XXX1 = 65535) then _unit := Nil else _unit:=Units[XXX1];
     if (XXX2 = 65535) then Building := Nil else Building:=Buildings[XXX2];
   end;

{x}BlockRead(IOFile,Groups,SizeOf(Groups));DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
   for I:=0 to MaxGroups do with (Groups[I]) do begin
     for J:=0 to MaxGroupUnits-1 do
       if (U2[J] = 65535) then Un[J]:=Nil else Un[J]:=Units[U2[J]];
     if (B2 = 65535) then Building:=Nil else Building:=Buildings[B2];
   end;

   { races }
   for J:=0 to MaxRace do with (Races[J]) do begin
     for I:=1 to MaxTypesOfBuildings do
       if (PTB2[I] = 65535) then PointerToBuildings[I]:=Nil
       else PointerToBuildings[I]:=Buildings[PTB2[I]];

     for I:=0 to MaxRaceTaskGroups do with TaskGroups^[I] do
       if (XXX = 65535) then Carriers:=Nil else Carriers:=Units[XXX];

     if (PTCP = 65535) then CentraPosil:=Nil
     else CentraPosil:=Units[PTCP];
   end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;


{ ************************************************************************** }
begin
   StopPressed:=0;
   PatrolPressed:=0;
   NalozitPressed:=0;
   VylozitPressed:=0;
   OpravitPressed:=0;
   ZvednoutMoralkuPressed:=0;
   PomCursor:=NormalCursor; ActiveScrolling:=False;
   New(Map); New(MapBck); New(MapBckTemp); New(MapInfo); New(SpecNumList);
   New(BuildRadar); New(DebrisInfo); New(RacesTGInfo); New(GlobalModify);
   if ((Map = Nil) or (MapBck = Nil) or (MapBckTemp = Nil) or
       (MapInfo = Nil) or (SpecNumList = Nil) or (BuildRadar = Nil) or
       (DebrisInfo = Nil) or (RacesTGInfo = Nil) or (GlobalModify = Nil))
   then begin
      Writeln('Chyba - nedostatek pameti');
      Halt(0);
   end;

   BuildRadarMod:=False;
   ClickLevel:=0;
   ClickLevelBase:=0;
   GameTimming:=1; RndUk:=0;
   LastUsedResource:=MaxResourceIndex+1;
   DebrisInfoIndex:=0; LowDebrisInfoIndex:=255;
   UpdateEEEnergy:=False; UpdatePL:=False; UpdateBP:=False; UpdateEXP:=False;

   for J:=0 to (JInfoArraySize-1) do begin
     for I:=0 to (IInfoArraySize-1) do with (MapInfo^[I,J]) do begin
        VLLight[0]:=0; VLLight[1]:=0; VLLight[2]:=0;{ 3 kategorie lehkych0 }
        VLight[0]:=0; VLight[1]:=0; VLight[2]:=0; { 3 kategorie lehkych1 }
        VHeavy[0]:=0; VHeavy[1]:=0; VHeavy[2]:=0; { 3 kategorie tezkych }
        VAir[0]:=0; VAir[1]:=0; VAir[2]:=0; { 3 kategorie vzdusnych }
        VAAttack[0]:=0; VAAttack[1]:=0; VAAttack[2]:=0; { 3 kategorie PVO }
        VTotall:=0;  { pocet vsech jednotek }
        VSpecial:=0;  { specialni - harvester }

        HLLight[0]:=0; HLLight[1]:=0; HLLight[2]:=0;{ 3 kategorie lehkych0 }
        HLight[0]:=0; HLight[1]:=0; HLight[2]:=0; { 3 kategorie lehkych1 }
        HHeavy[0]:=0; HHeavy[1]:=0; HHeavy[2]:=0; { 3 kategorie tezkych }
        HAir[0]:=0; HAir[1]:=0; HAir[2]:=0; { 3 kategorie vzdusnych }
        HAAttack[0]:=0; HAAttack[1]:=0; HAAttack[2]:=0; { 3 kategorie PVO }
        HTotall:=0;  { pocet vsech jednotek }
        HSpecial:=0;  { specialni - harvester }

        EnemyVLLight[0]:=0; EnemyVLLight[1]:=0; EnemyVLLight[2]:=0;
        EnemyVLight[0]:=0; EnemyVLight[1]:=0; EnemyVLight[2]:=0;
        EnemyVHeavy[0]:=0; EnemyVHeavy[1]:=0; EnemyVHeavy[2]:=0;
        EnemyVAir[0]:=0; EnemyVAir[1]:=0; EnemyVAir[2]:=0;
        EnemyVAAttack[0]:=0; EnemyVAAttack[1]:=0; EnemyVAAttack[2]:=0;
        EnemyVTotall:=0;  { pocet vsech nepr. vid. jednotek }
        EnemyVSpecial:=0;

        EnemyHLLight[0]:=0; EnemyHLLight[1]:=0; EnemyHLLight[2]:=0;
        EnemyHLight[0]:=0; EnemyHLight[1]:=0; EnemyHLight[2]:=0;
        EnemyHHeavy[0]:=0; EnemyHHeavy[1]:=0; EnemyHHeavy[2]:=0;
        EnemyHAir[0]:=0; EnemyHAir[1]:=0; EnemyHAir[2]:=0;
        EnemyHAAttack[0]:=0; EnemyHAAttack[1]:=0; EnemyHAAttack[2]:=0;
        EnemyHTotall:=0;  { pocet vsech nepr. skryt. jednotek }
        EnemyHSpecial:=0;

        FriendlyBuildingsNum:=0;  { pocet pr. budov }
        FriendlyBuildingsWeight:=0;  { vaha pr. budov }
        EnemyVBuildingsNum:=0; { pocet nepr. viditelnych budov}
        EnemyVBuildingsWeight:=0;  { vaha nepr. vidit. budov }
        EnemyHBuildingsNum:=0; { pocet nepr. skrytych budov }
        EnemyHBuildingsWeight:=0;  { vaha nepr. skryt. budov }

        for K:=0 to MaxRace do begin
          MoraleModifierTemp[K]:=0; MoraleModifier[K]:=0;
        end;

        Pruchozi:=True;
     end;
   end;

   for I:=0 to MaxRace do
     for J:=0 to MaxRaceTaskGroups do with (RacesTGInfo^[I,J]) do begin
        LeaderCourageLow:=0; LeaderCourageHigh:=100;
        MoveCourageNormal:=100; MoveCourageSabot:=90;
        TGAtt:=2; Lock:=0; TGMinLimit:=0;
     end;

   CacheValidity:=False; SCacheUk:=0; SCache:=0; GameStopped:=False;
   MenuActive:=False; Debris:=True; FireAllowed:=True;
   SpecStatusBar:=True; ScrollSpeed:=5;
   Counter1:=0; Counter2:=0;

   for J:=0 to 16 do with (SpecNumList^[J]) do begin
     Count:=0; Destr:=False;
   end;

   Global_eval_flag:=0;
   WayPointDef:=0;
   SavedWayPointsMax[0]:=255; SavedWayPointsMax[1]:=255;
   SavedWayPointsMax[2]:=255; SavedWayPointsMax[3]:=255;
   New(Range_check_array); New(VictoryConditions);
   Victory:=0; InDrawResult:=False; KillMode:=False;
   SaveGame:=0; LoadGame:=0;
   GlobalComp:=0; GlobalFriend:=0;
   { globalni sila pocitace+friends: }
   GlobalCompLLight:=0; GlobalCompLight:=0; GlobalCompHeavy:=0;
   GlobalCompAir:=0; GlobalCompAAttack:=0;
   { globalni sila OSN+friends: }
   GlobalFriendLLight:=0; GlobalFriendLight:=0; GlobalFriendHeavy:=0;
   GlobalFriendAir:=0; GlobalFriendAAttack:=0;
   {x}
   GlobalCompGroundPct:=0; GlobalFriendGroundPct:=0;
   RdrawRadarFrame:=False;

   UnitSpeedPct[0]:=0; UnitSpeedPct[1]:=27; UnitSpeedPct[2]:=50;
   UnitSpeedPct[3]:=57; UnitSpeedPct[4]:=63; UnitSpeedPct[5]:=75;
   UnitSpeedPct[6]:=80;
   TimeSLot:=0;
   BattleExperienceDiv:=0; ScoreDiv:=0;
   GameStopCount:=1; GameStopCountTimmer:=0;
   BckSoundSoundNotUsed:=0;
   BckSoundTimmer:=100+Random(200);
   EndOfGameTimmer:=0;
   for I:=1 to MaxTypesOfUnits do UnitsInfoRecord.Rec[I]:=0;
   for I:=1 to MaxTypesOfBuildings do BuildingsInfoRecord.Rec[I]:=0;
   UnitsInfoRecord.MaxIndex:=0; BuildingsInfoRecord.MaxIndex:=0;
   UnAvailUnits:=[]; TerrainCondition:=Clear;
   GameUniqueNumber:=-255;
   Zrada:=False;
   ErrorString:='';
   Slow:=False;
   TimeOverflow:=False;
   BuildingsSold:=0;
   UnitsSold:=0;
   Locate:='';
   AttackMarkUnit:=Nil; AttackMarkBuilding:=Nil;
end.