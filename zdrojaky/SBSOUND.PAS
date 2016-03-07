unit SBSound;
{$C FIXED PRELOAD PERMANENT}
{ * }
interface
const QLength = 10;
type TQueue = object
                private
                  Q:array[0..QLength] of Byte;
                  FrontUk, BackUk:Byte;
                public
                  procedure Insert(Element:Byte);
                  function Front:Byte;
                  function Empty:Boolean;
                  procedure Init;
              end;

procedure SoundInit;
procedure Shutdown;
procedure PlaySound(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
procedure PreparePlaySound(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
procedure ExecutePlaySound;
procedure PlayBuildingSound(BuildingType:Word; X,Y:Word);
procedure StopBuildingSound;
procedure BuildingSoundManager;
procedure SetSoundVariables(VariableType:Byte; Setting:Boolean);
function GetSoundVariables(VariableType:Byte):Boolean;
function GetVolume(IPos,JPos:Word):Byte;
procedure SBSound_save;
procedure SBSound_load;

var
    SoundSettings: array[0..7] of Boolean; { povoluje/zakazuje ruzne zvuky
          0: veskery zvuk
          1: hlasy jednotek
          2: vystrely
          3: exploze strel
          4: exploze budov
          5: systemove hlasky
          6: zvuky pozadi
          7: pernamentni zvuky pozadi
    }

implementation

{ * }
  uses
    CRT,
    Dos,
    SMix,
    Data;
  const
    XMSRequired   = 190;    {velikost XMS v kB pro nahrani vsech zvuku}
    NumSounds = 6; {pocet nahravanych zvuku}
    MaxGunSound = 7;
    MaxSysSound = 11; { pocet zvuku-1 }
    MaxExplosioSound = 25;
    MaxBckSound = 23; { max pocet zvuku pozadi }
    MaxBckNoWinterSound = 7; { max pocet zvuku pozadi NE V ZIME }
    MaxBckNightSound = 9; { max pocet zvuku pozadi noci }
    MaxPernamentBckSound = 2; { max pocet pernamentnich zvuku pozadi }
  var
    MasterVolume:Byte;
    GunSound: array[0..MaxGunSound] of PSound;
    SysSound: array[0..MaxSysSound] of PSound;
    ExplosioSound: array[0..MaxExplosioSound] of PSound;
    BckSound: array[0..MaxBckSound+MaxBckNoWinterSound+MaxBckNightSound] of PSound;
    PernamentBckSound: array[0..MaxPernamentBckSound] of PSound;
    FactorySound: array[0..MaxTypesOfBuildings] of PSound;
    ActualBckSound:Word;
    ActualBuildingSound:Boolean; { True, je-li aktivni nejaka budova }
    ActualBuildingType:Word;  { typ aktualni budovy  }
    ActualBuildingX,ActualBuildingY:Word; { pozice budovy }

    GunSoundQueue: array[0..MaxGunSound] of record
    { fronta zvuku, pripravenych pro zahrani }
                      Vol:Byte; { hlasitost }
                      Used:Boolean; { vyuziti }
                   end;
    ClickSound: PSound; { zvuk clicku mysi }

    SysSoundQueue:TQueue; { pro systemove hlasky }
    BuildingExplos:Byte; { cislo explodujici budovy }
    BuildingExplosVolume:Byte; { hlasitost explodujici budovy }

    SpeechIndex1, SpeechIndex2, SpeechVolume, SpeechRace : Byte;
    { parametry toho hlaseni jednotek, ktery se ma provest }
    LastSpeechIndex1, LastSpeechIndex2, LastSpeechCounter:Byte;
    { pojistka proti opakovani zvuku}

    SpeechIndex21, SpeechIndex22, SpeechVolume2, SpeechRace2 : Byte;
    { nepovinne zvuky (umirani..) }

    BaseIO: word; IRQ, DMA, DMA16: byte;
    i: byte;
    Counter: LongInt;
    InKey: char;
    Stop: boolean;
    Num: byte;
    Temp: integer;
    Pomocna:Word;
    Snd:File;
    SoundDetected:Boolean;
    PartialSound:Byte;

    A,B,C:Word;

{ +++++ }
procedure TQueue.Insert(Element:Byte);
{ vlozi do fronty prvek; je-li fronta plna, vyjme jeden prvek ze zacatku;
  prvek se ulozi do fronty jen tehdy, pokud je ruzny od predchoziho
}
begin
   if (((BackUk+1) = FrontUk) or ((BackUk = QLength) and (FrontUk = 0))) then
   begin { fronta je plna, vyjmeme prvni prvek }
     Front;
   end;
   if ((Empty) or (Q[FrontUk] <> Element)) then begin
     Q[BackUk]:=Element;
     Inc(BackUk); if (BackUk > QLength) then BackUk:=0;
   end;
end;

{ +++++ }
function TQueue.Front:Byte;
{ vymaze z fronty prvni prvek a vrati ho; je-li fronta prazdna, nic se nedeje,
  ele vraceny prvek neni spravny
}
begin
   if (not Empty) then begin
      Front:=Q[FrontUk];
      Inc(FrontUk); if (FrontUk > QLength) then FrontUk:=0;
   end;
end;

{ +++++ }
procedure TQueue.Init;
{
}
begin
   FrontUk:=0; BackUk:=0;
end;

{ +++++ }
function TQueue.Empty:Boolean;
{
}
begin
   if (FrontUk = BackUk) then Empty:=True else Empty:=False;
end;

{ ***** }
function UpcaseStr(Str: string): string;
var
  i: byte;
  Temp: string;
begin
  Temp[0] := Str[0];
  for i := 1 to Length(Str) do
    Temp[i] := Upcase(Str[i]);
  UpcaseStr := Temp;
end;
{ ***** }
function GetSetting(Str: string; ID: char; Hex: boolean): word;
var
  Temp : string;
  Num  : word;
  Code : integer;
begin
  Temp := Str;
  if Pos(ID, Temp) <> 0
    then
      begin
        Delete(Temp, 1, Pos(ID, Temp));
        Delete(Temp, Pos(' ', Temp), 255);
        if Hex then Insert('$', Temp, 1);
        Val(Temp, Num, Code);
        if Code = 0
          then GetSetting := Num
          else GetSetting := 0;
      end
    else
      GetSetting := 0;
end;

{ ***** }
function reset_dsp(base : word) : boolean;

var dsp_reset        : word;
    dsp_read_data    : word;
    dsp_write_data   : word;
    dsp_write_status : word;
    dsp_data_avail   : word;
begin
 base := base * $10;

 { calculate the port addresses }
 dsp_reset        := base + $206;
 dsp_read_data    := base + $20a;
 dsp_write_data   := base + $20c;
 dsp_write_status := base + $20c;
 dsp_data_avail   := base + $20e;

 { reset the dsp, and give some nice long delays just to }
 { be safe }
 port[dsp_reset] := 1;
 delay(5);

 port[dsp_reset] := 0;
 delay(5);

 reset_dsp := (port[dsp_data_avail] and $80 = $80) and
              (port[dsp_read_data] = $aa);
end;

{ ***** }
function GetSettings(var BaseIO: word; var IRQ: byte; var DMA: byte;var DMA16: byte): boolean;
{Gets sound card settings from BLASTER environment variable            }
{Parameters:                                                           }
{  BaseIO:  Sound card base IO address                                 }
{  IRQ:     Sound card IRQ                                             }
{  DMA:     Sound card 8-bit DMA channel                               }
{  DMA16:   Sound card 16-bit DMA channel (0 if none)                  }
{Returns:                                                              }
{  TRUE:    Sound card settings found successfully                     }
{  FALSE:   Sound card settings could not be found                     }
var
  BLASTER: string;
  A:Word;
begin
  BLASTER := UpcaseStr(GetEnv('BLASTER'));
  BaseIO :=0;
  for a := 1 to 5 do
    if reset_dsp(a) then begin
       BaseIO:=a * $10 + $200;
       break;
    end;
  IRQ    := GetSetting(BLASTER, 'I', false); {Decimal}
  DMA    := GetSetting(BLASTER, 'D', false); {Decimal}
  DMA16  := 0; {Decimal}

  GetSettings := true;
  if BLASTER = '' then GetSettings := false;
  if BaseIO  = 0  then GetSettings := false;
  if IRQ     = 0  then GetSettings := false;
  {if DMA     = 0  then GetSettings := false;
  {We can survive if there isn't a DMA16 channel}
end;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

function HexW(W: word): string; {Word}
const
  HexChars: array [0..$F] of Char = '0123456789ABCDEF';
begin
  HexW :=
    HexChars[(W and $F000) shr 12] +
    HexChars[(W and $0F00) shr 8]  +
    HexChars[(W and $00F0) shr 4]  +
    HexChars[(W and $000F)];
end;

{ ***** }
procedure SoundInit;
label Konec;
var I,J,UsedIndex:Word;
    Cathegory, SoundType, Race : Word;
    Pom:String;
    Modulo:Byte;
    Value:Byte;
begin
 if (not SoundDetected) then GoTo Konec;
  ClrScr;{}
  Writeln('Volna pamet: ',MemAvail);
  Randomize;
  writeln;
  {if (not GetSettings(BaseIO, IRQ, DMA, DMA16)) then begin
    writeln('Chyba inicializace:  spatne nastaveni v autoexec.bat (SET BLASTER = )');
    Halt(1);
  end else begin{}
    if (not InitSB(BaseIO, IRQ, DMA, DMA16)) then begin
         writeln('Chyba inicializace zvukove karty');
         writeln('Spatna IO adresa, karta neni instalovana, nebo je nekompatibilni se SB');
         Halt(2);
    end;
  {end;{}
{  Port[BaseIO+4]:=$22; Delay(1);
  MasterVolume:=Port[BaseIO+5]; Delay(1);
  Port[BaseIO+4]:=$22; Delay(1);
  Port[BaseIO+5]:=14 shl 2 + 14; Delay(1);{}

  begin
       New(SoundArray);
       if (SoundArray = Nil) then begin
         writeln('Nedostatek pameti pro inicializaci pole (64kb)');
         Halt(4);
       end;
       {for I:=0 to MaxSoundArrayIndex do begin
          New(SoundArray^[I]);
          if (SoundArray^[I] = Nil) then begin
             writeln('Nedostatek pameti pro inicializaci pole (64kb)');
             Halt(4);
          end;
       end;
       Writeln('Konec pametove inicializace');{}

       Writeln('Nahravani zvuku:'); UsedIndex:=0;
       { nejprve systemove zvuky a zvuky strelby }
       for I:=0 to MaxGunSound do begin
         Str(I+1,Pom); Pom:='sound\shot'+Pom+'.raw';
         {New(GunSound[I]);
         if (GunSound[I] = Nil) then begin
            writeln('Nedostatek pameti pro inicializaci'); Halt(4);
         end;{}
         LoadSound(GunSound[I],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk1:           ');
         GotoXY(17,4); Writeln(I,'%');
       end;
       { * }
       for I:=0 to MaxSysSound do begin
         Str(I+1,Pom); Pom:='sound\sys'+Pom+'.raw';
         {New(SysSound[I]);
         if (SysSound[I] = Nil) then begin
            writeln('Nedostatek pameti pro inicializaci'); Halt(4);
         end;{}
         LoadSound(SysSound[I],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk2:           ');
         GotoXY(17,4); Writeln(I,'%');
       end;
       { * }
       for I:=0 to MaxExplosioSound do begin
         Str(I+1,Pom); Pom:='sound\explos'+Pom+'.raw';
         {New(ExplosioSound[I]);
         if (ExplosioSound[I] = Nil) then begin
            writeln('Nedostatek pameti pro inicializaci'); Halt(4);
         end;{}
         LoadSound(ExplosioSound[I],UsedIndex,Pom);
       end;
       { * }
       {New(ClickSound);
       if (ClickSound = Nil) then begin
            writeln('Nedostatek pameti pro inicializaci'); Halt(4);
       end;{}
       if (PartialSound = 1) then J:=(MaxBckSound-1) div 2 else J:=MaxBckSound-1;
       for I:=0 to J do begin
         Str(I+1,Pom); Pom:='sound\bck'+Pom+'.raw';
         LoadSound(BckSound[I],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk3:           ');
         GotoXY(17,4); Writeln(I,'%');
       end;
       for I:=0 to MaxBckNoWinterSound-1 do begin
         Str(I+1,Pom); Pom:='sound\bck'+Pom+'ne_z.raw';
         LoadSound(BckSound[I+MaxBckSound],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk3:           ');
         GotoXY(17,4); Writeln(I+MaxBckSound,'%');
       end;
       for I:=0 to MaxBckNightSound-1 do begin
         Str(I+1,Pom); Pom:='sound\bck'+Pom+'_n.raw';
         LoadSound(BckSound[I+MaxBckSound+MaxBckNoWinterSound],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk3:           ');
         GotoXY(17,4); Writeln(I+MaxBckSound+MaxBckNoWinterSound,'%');
       end;
       {x}
       for I:=0 to MaxPernamentBckSound-1 do begin
         Str(I+1,Pom); Pom:='sound\loopbck'+Pom+'.raw';
         LoadSound(PernamentBckSound[I],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk4:           ');
         GotoXY(17,4); Writeln(I,'%');
       end;
       { ***** }
       for I:=0 to MaxTypesOfBuildings do begin
         Str(I+1,Pom); Pom:='sound\tov'+Pom+'.raw';
         FactorySound[I]:=Nil;
         LoadSound(FactorySound[I],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zvuk5:           ');
         GotoXY(17,4); Writeln(I,'%');
       end;

       LoadSound(ClickSound,UsedIndex,'sound\click.raw');

       Modulo:=8;
       { nyni zvuky ve hre } UsedIndex:=0;
       Cathegory:=0; SoundType:=0; Race:=0;
       for I:=1 to 1000 do begin
         case (I) of
            1..99 : begin
                          { zacatek nove kategorie }
                          if ((I-1) mod Modulo = 0) then begin
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Sounds:=UsedIndex-Index;
                             end;
                             Cathegory:=(I-1) div Modulo;
                             SoundType:=0;
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Index:=UsedIndex;
                             end;
                          end;
                          J:=(I-1) mod 8;
                    end;
            100..199 : begin { zacatek nove kategorie }
                          if ((I-100) mod Modulo = 0) then begin
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Sounds:=UsedIndex-Index;
                             end;
                             Cathegory:=(I-100) div Modulo;
                             SoundType:=1;
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Index:=UsedIndex;
                             end;
                          end;
                          J:=(I-100) mod 8;
                       end;
            200..299 : begin { zacatek nove kategorie }
                          if ((I-200) mod Modulo = 0) then begin
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Sounds:=UsedIndex-Index;
                             end;
                             Cathegory:=(I-200) div Modulo;
                             SoundType:=2;
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Index:=UsedIndex;
                             end;
                          end;
                          J:=(I-200) mod 8;
                       end;
            500..599 : begin { zacatek nove kategorie }
                          if ((I-500) mod Modulo = 0) then begin
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Sounds:=UsedIndex-Index;
                             end;
                             Cathegory:=(I-500) div Modulo;
                             SoundType:=0; Race:=1;
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Index:=UsedIndex;
                             end;
                          end;
                          J:=(I-500) mod 8;
                       end;
            600..699 : begin { zacatek nove kategorie }
                          if ((I-600) mod Modulo = 0) then begin
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Sounds:=UsedIndex-Index;
                             end;
                             Cathegory:=(I-600) div Modulo;
                             SoundType:=1; Race:=1;
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Index:=UsedIndex;
                             end;
                          end;
                          J:=(I-600) mod 8;
                       end;
            700..799 : begin { zacatek nove kategorie }
                          if ((I-700) mod Modulo = 0) then begin
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Sounds:=UsedIndex-Index;
                             end;
                             Cathegory:=(I-700) div Modulo;
                             SoundType:=2; Race:=1;
                             with (SoundInfoArray[Cathegory, SoundType, Race]) do begin
                                Index:=UsedIndex;
                             end;
                          end;
                          J:=(I-700) mod 8;
                       end;
         end;
         Str(I,Pom); Pom:='sound\'+Pom+'.raw';
         if (PartialSound = 1) then begin { jen cast zvuku }
           if (J div 2 = 0) then { jen 2 zvuky od kategorie }
              LoadSound(SoundArray^[UsedIndex],UsedIndex,Pom);
         end else { cele zvuky }
           LoadSound(SoundArray^[UsedIndex],UsedIndex,Pom);
         GotoXY(10,4); Writeln('Zbytek:           ');
         GotoXY(17,4); Writeln(I div 10,'%');
       end; {}

       { nyni zvuky ve hre }{ UsedIndex:=0;
       for I:=0 to 1000 do begin
         Str(I,Pom); Pom:='sound\'+Pom+'.raw';
         LoadSound(SoundArray^[UsedIndex],UsedIndex,Pom);
         GotoXY(10,4); Writeln('       ');
         GotoXY(10,4); Writeln(I div 10,'%');
       end; {}
  end;
  InitMixing;
  { Dalsi inicializace }
  for I:=0 to MaxGunSound do with (GunSoundQueue[I]) do begin
     Used:=False;
  end;
  Writeln('Volna pamet: ',MemAvail);
Konec:
end;

{ ***** }
procedure Shutdown;
begin
  if (HandlerInstalled) then begin
{    Port[BaseIO+4]:=$22;
    Delay(2);
    Port[BaseIO+5]:=MasterVolume;
    Delay(2);{}

    if (SoundDetected) then begin
       for i := 0 to NumSounds-1 do
          StopSound(i);{}
       Delay(10);
       ShutdownMixing;
       ShutdownSB;
    end;
  end;
end;

{ ***** }
procedure PlaySound(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
{ zahraje zvuk
  SoundType: 0 .. zvuk lidi (Index1=typ hlasky, Index2=typ jednotky (lehka...))
             1 .. zvuk robotu (Index1=typ hlasky, Index2=typ jednotky (lehka...))
             2 .. zvuk vystrelu (Index1 = index zbrane, Index2 se ignoruje)
             3 .. zvuk exploze strely (Index1 = index zbrane, Index2 se ignoruje)
                  // 3 = not used
             4 .. zvuk exploze budovy (Index1 = typ budovy (32x32=0,
                                       64x32=1, jinak 2), Index2 se ignoruje)
             5 .. system sound (Index1 = index zvuku, Index2 se ignoruje)
             6 .. bck sound (Index1 = index zvuku, Index2 se ignoruje)
             7 .. pernament bck sound
  Volume:  0..100%
           1..50%
           2..25%
           3..12%
  zvuky lidi-robotu ... kanal 1
  zvuky vystrelu ... kanal 2
  zvuky explozi ... kanal 4
  systemove hlasky ... kanal 3
  kanal 4 rezervovan (clicknuti mysi)
  zvuk pozadi ... kanal 5
  neplati: pernamentni zvuk pozadi ... kanal 10
}
label Konec;
var R:Word;
    Channel:Byte;
begin
   if ((not SoundDetected) or (not SoundSettings[0])) then GoTo Konec;
   case SoundType of
     0 : if (SoundSettings[1]) then begin { zvuky lidi }
          with (SoundInfoArray[Index1,Index2,0]) do begin
           if (Sounds > 0) then begin
             R:=Random(Sounds);
             {if ((Index1 <= 2) or (Index1 = 8) or (Index1 = 9))
             then Channel:=1 else Channel:=2;{}
             Channel:=1;
             StartSound(SoundArray^[Index+R],Volume,Channel,False);
           end; { if }
          end;
         end;
     1 : if (SoundSettings[1]) then begin { zvuky robotu }
          with (SoundInfoArray[Index1,Index2,1]) do begin
           if (Sounds > 0) then begin
             R:=Random(Sounds);
             {if ((Index1 <= 2) or (Index1 = 8) or (Index1 = 9))
             then Channel:=1 else Channel:=2;{}
             Channel:=1;
             StartSound(SoundArray^[Index+R],Volume,Channel,False);
           end; { if }
          end;
         end;
     2:  if (SoundSettings[2]) then begin { zvuk vystrelu }
            {if (not VoiceUsage(5)) then Channel:=5
            else if (not VoiceUsage(6)) then Channel:=6
            else Channel:=5+IntCount mod 2;{}
            Channel:=2;
            StartSound(GunSound[Index1],Volume,2,False);
         end;
     3:  if (SoundSettings[3]) then begin { zvuk exploze strely }
            StartSound(ExplosioSound[Index1],Volume,4,False);
         end;
     4:  if (SoundSettings[4]) then begin { zvuk exploze budovy }
            { neni-li dost kanalu, zastav vystrely: }
            if (VoiceCount = Voices) then StopSingleSound(2);
            Channel:=4;
            StartSound(ExplosioSound[19+Index1],Volume,Channel,False);
         end;
     5:  if (SoundSettings[5]) then begin { zvuk systemove hlasky }
            StartSound(SysSound[Index1],Volume,3,False);
         end;
     6:  if (SoundSettings[6]) then begin { zvuk pozadi }
            StartSound(BckSound[Index1],Volume,5,False);
         end;
     7:  if (SoundSettings[7]) then begin { pernamentni zvuk pozadi }
            {StartSound(PernamentBckSound[ActualBckSound],1,4,True);{}
         end;
   end;
Konec:
end;

{ ***** }
procedure PreparePlaySound(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
{ do fronty ulozi zvuk:
  SoundType: 0 .. zvuk lidi (Index1=typ hlasky, Index2=typ jednotky (lehka...))
             1 .. zvuk robotu (Index1=typ hlasky, Index2=typ jednotky (lehka...))
             2 .. zvuk vystrelu (Index1 = index zbrane, Index2 se ignoruje)
             3 .. zvuk exploze strely (Index1 = index zbrane, Index2 se ignoruje)
                   // 3 = not used
             4 .. zvuk exploze budovy (Index1 = typ budovy (32x32=0,
                                       64x32=1, jinak 2), Index2 se ignoruje)
             5 .. system sound (Index1 = index zvuku, Index2 se ignoruje)
             6 .. primo zahraje clicknuti mysi
  Volume:  0..100%
           1..50%
           2..25%
           3..12%
  ExecutePlaySound realizuje vlastni zahrani
}
begin
   case SoundType of
     0 : begin { zvuky lidi }
            case (Index1) of
              0..2: begin { nutne hlasky }
                       SpeechIndex1:=Index1; SpeechIndex2:=Index2;
                       SpeechVolume:=Volume; SpeechRace:=0;
                    end;
              8..9: begin { nutne hlasky }
                       SpeechIndex1:=Index1; SpeechIndex2:=Index2;
                       SpeechVolume:=Volume; SpeechRace:=0;
                    end;
            else { nepovinne hlasky }
               if ((SpeechIndex21 < 255) and (IntCount mod 2 = 1) or
                   (SpeechIndex21 = 255) or (SpeechIndex21 = Index1)) then begin
               { nejaky zvuk jiz existuje, nahodne zvolime, zda jej prepsat
                 nebo zadny zvuk neni }
                  if (SpeechIndex21 = Index1) then begin
                  { jde o stejny typ - zvolime hlasitejsi variantu }
                    if (Volume > SpeechVolume2) then begin
                      SpeechIndex21:=Index1; SpeechIndex22:=Index2;
                      SpeechVolume2:=Volume; SpeechRace2:=0;
                    end;
                  end else begin
                    SpeechIndex21:=Index1; SpeechIndex22:=Index2;
                    SpeechVolume2:=Volume; SpeechRace2:=0;
                  end;
               end;
            end;
         end;
     1 : begin { zvuky robotu }
            case (Index1) of
              0..2: begin { nutne hlasky }
                       SpeechIndex1:=Index1; SpeechIndex2:=Index2;
                       SpeechVolume:=Volume; SpeechRace:=1;
                    end;
              8..9: begin { nutne hlasky }
                       SpeechIndex1:=Index1; SpeechIndex2:=Index2;
                       SpeechVolume:=Volume; SpeechRace:=1;
                    end;
            else { nepovinne hlasky }
               if ((SpeechIndex21 < 255) and (IntCount mod 2 = 1) or
                   (SpeechIndex21 = 255) or (SpeechIndex21 = Index1)) then begin
               { nejaky zvuk jiz existuje, nahodne zvolime, zda jej prepsat
                 nebo zadny zvuk neni }
                  if (SpeechIndex21 = Index1) then begin
                  { jde o stejny typ - zvolime hlasitejsi variantu }
                    if (Volume > SpeechVolume2) then begin
                      SpeechIndex21:=Index1; SpeechIndex22:=Index2;
                      SpeechVolume2:=Volume; SpeechRace2:=1;
                    end;
                  end else begin
                    SpeechIndex21:=Index1; SpeechIndex22:=Index2;
                    SpeechVolume2:=Volume; SpeechRace2:=1;
                  end;
               end;
            end;
         end;
     2:  begin { zvuk vystrelu }
            with (GunSoundQueue[Index1]) do begin
               Vol:=Volume;
               Used:=True;
            end;
         end;
     3:  begin { zvuk exploze strely }
            {StartSound(ExplosioSound[Index1],Volume,4,False);{}
         end;
     4:  begin { zvuk exploze budovy; ulozi se pouze prvni }
            if (BuildingExplos = 255) then begin
              BuildingExplos:=Index1; BuildingExplosVolume:=Volume;
            end;
         end;
     5:  begin { zvuk systemove hlasky }
            SysSoundQueue.Insert(Index1);
         end;
     6:  StartSound(ClickSound,Volume,4,False);
   end;
end;

{ ***** }
procedure ExecutePlaySound;
{ spusti zvuky z pripravenych front
}
label Konec;
var I, Counter:Word;
    Used:Byte;
begin
  if ((not SoundDetected) or (not SoundSettings[0])) then GoTo Konec;
  {BckSoundTimmer:=0; BckSoundSoundNotUsed{}
  Used:=0;
  for I := 0 to Voices-1 do
     if (VoiceUsage(I)) then Used:=Used+1;
  if (Used > 0) then BckSoundSoundNotUsed:=0 else Inc(BckSoundSoundNotUsed);
  if (BckSoundTimmer > 0) then Dec(BckSoundTimmer);
  if ((BckSoundTimmer = 0) and (Used <= 1)
      {or (BckSoundSoundNotUsed > GetAccurateDelay(10)){})
  then begin { zahraj hlas pozadi }
     BckSoundTimmer:=GetAccurateDelay(80+Random(400));{}
     if (TerrainCondition = Snow) then I:=Random(MaxBckSound)
     else
      if (TerrainCondition <> Night) then I:=Random(MaxBckSound+MaxBckNoWinterSound)
      else I:=Random(MaxBckSound+MaxBckNoWinterSound+MaxBckNightSound);
     PlaySound(6,0,I,0);
  end;

  { * RECI JEDNOTEK * }
  if ((SoundSettings[1]) and (SpeechIndex1 < 255) and (not VoiceUsage(3)) and
      ((LastSpeechIndex1 <> SpeechIndex1) or (LastSpeechIndex2 <> SpeechIndex2)))
  then begin { zvuky lidi }
     if (SpeechRace = 0) then
        PlaySound(0,SpeechVolume,SpeechIndex1,SpeechIndex2)
     else
        PlaySound(1,SpeechVolume,SpeechIndex1,SpeechIndex2);
     LastSpeechIndex1:=SpeechIndex1; LastSpeechIndex2:=SpeechIndex2;
     SpeechIndex1:=255; SpeechIndex2:=255;
     LastSpeechCounter:=Byte(GetAccurateDelay(7));
  end else begin
    if (LastSpeechCounter = 0) then LastSpeechIndex1:=255
    else Dec(LastSpeechCounter);
    SpeechIndex1:=255; SpeechIndex2:=255;
  end;

  {if (SpeechIndex21 < 255) then Inc(A);{}
  if ((SoundSettings[1]) and (SpeechIndex21 < 255) and
      (not VoiceUsage(1)) {and (not VoiceUsage(2)){} and (not VoiceUsage(3)))
  then begin
  { nepovinne zvuky (umirani...) }
    {Inc(B);{}
    if (SpeechRace2 = 0) then
        PlaySound(0,SpeechVolume2,SpeechIndex21,SpeechIndex22)
     else
        PlaySound(1,SpeechVolume2,SpeechIndex21,SpeechIndex22);
    SpeechIndex21:=255; SpeechIndex22:=255;
  end else SpeechIndex21:=255;


  { * ZVUK VYSTRELU * }
  if (SoundSettings[2]) then begin { zvuk vystrelu }
     { soucasne se zahraji max. 2 zvuky; proto nahodne prochazime pole
       sestupne nebo vzestupne, aby se paleta zvuku co nejvice menila }
     Counter:=0;
     if (IntCount mod 2 = 0) then begin
       for I:=0 to MaxGunSound do with (GunSoundQueue[I]) do begin
         if (Used and (Counter < 2)) then begin PlaySound(2,Vol,I,0); Inc(Counter); end;
       end;
     end else begin
       for I:=MaxGunSound downto 0 do with (GunSoundQueue[I]) do begin
         if (Used and (Counter < 2)) then begin PlaySound(2,Vol,I,0); Inc(Counter); end;
       end;
     end;
  end;

  { * EXPLOZE BUDOV * }
  { soucasne se rozezni exploze pouze jedne (prvni) budovy }
  if (SoundSettings[4]) then begin { zvuk exploze budovy }
     if (BuildingExplos <> 255) then begin
       PlaySound(4,BuildingExplosVolume,BuildingExplos,0);
       BuildingExplos:=255;
     end;
  end;

  { * SYSTEMOVY ZVUK * }
  if (SoundSettings[5]) then begin { zvuk systemove hlasky }
    if ((not SysSoundQueue.Empty) and (not VoiceUsage(3))) then
       PlaySound(5,0,SysSoundQueue.Front,0); Inc(Counter);
  end;

  { zaverecne inicializace }
  for I:=0 to MaxGunSound do with (GunSoundQueue[I]) do begin
     Used:=False;
  end;

Konec:
end;

{ ***** }
procedure SetSoundVariables(VariableType:Byte; Setting:Boolean);
{ povoluje/zakazuje zvuky danych typu: (dle VariableType)
  0: veskery zvuk
  1: hlasy jednotek
  2: vystrely
  3: exploze strel //not used
  4: exploze budov
  5: systemove hlasky
  6: zvuky pozadi

pozn. Settind = True pro povoleni; inicializacne je vse povoleno
}
begin
   SoundSettings[VariableType]:=Setting;
end;

{ ***** }
function GetSoundVariables(VariableType:Byte):Boolean;
{ vraci stav povoleni(True)\zakazani(False) zvuky danych typu:
  (dle VariableType):
  0: veskery zvuk
  1: hlasy jednotek
  2: vystrely
  3: exploze strel //not used
  4: exploze budov
  5: systemove hlasky
}
begin
   GetSoundVariables:=SoundSettings[VariableType];
end;

{ ***** }
procedure PlayBuildingSound(BuildingType:Word; X,Y:Word);
{ ovlada zvuky budovy
}
begin
  if ((not ActualBuildingSound) or
      (ActualBuildingType <> BuildingType)) then begin
    ActualBuildingSound:=True;
    ActualBuildingType:=BuildingType;
    ActualBuildingX:=X; ActualBuildingY:=Y;

    if (VoiceCount = Voices) then StopSingleSound(2);
    StartSound(FactorySound[BuildingType-1],GetVolume(X,Y),6,False);
  end;
end;

{ ***** }
procedure StopBuildingSound;
{ ovlada zvuky budovy
}
begin
   StopSound(6);
   ActualBuildingSound:=False; ActualBuildingType:=0;
end;

{ ***** }
procedure BuildingSoundManager;
{ ovlada zvuky naclicknute budovy
}
begin
  if (ActualBuildingSound) then begin
     {SoundVolume(6,GetVolume(ActualBuildingX,ActualBuildingY));{}
  end;
end;

{ ***** }
function GetVolume(IPos,JPos:Word):Byte;
{ funkce na zaklade pozice prvku (IPos,JPos) a pozice obrazovky vypocte
  doporucenou hlasitost jeho projevu; pasma:
  - uvnitr obrazovky = 0 (max. hlasitost)
  - 15 poli od okraju obrazovky = 1 (hlasitost 50 %)
  - do 35-ti poli od okraju obrazovky = 2 (hlasitost 25 %)
  - vice = 3 (hlasitost 12%)
}
var I,J,K,L:Word;

function Test(X,Y,XBeg,YBeg,XEnd,YEnd:Word):Boolean;
{ vraci True, nachazi-li se X,Y v danem obdelniku
}
begin
   if ((X >= XBeg) and (XEnd >= X) and
       (Y >= YBeg) and (YEnd >= Y)) then begin
     Test:=True;
   end else Test:=False;
end;
{}
begin
   I:=IBeg; K:=IBeg+IScreenSize; J:=JBeg; L:=JBeg+JScreenSize;
   if (Test(IPos,JPos,I,J,K,L)) then GetVolume:=0
   else begin
     if (I > 15) then Dec(I,15) else I:=0;
     if (J > 15) then Dec(J,15) else J:=0;
     Inc(K,15); Inc(L,15);
     if (Test(IPos,JPos,I,J,K,L)) then GetVolume:=1
     else begin
       if (I > 20) then Dec(I,20) else I:=0;
       if (J > 20) then Dec(J,20) else J:=0;
       Inc(K,20); Inc(L,20);
       if (Test(IPos,JPos,I,J,K,L)) then GetVolume:=2
       else GetVolume:=3;
     end;
   end;
end;

{ ***** }
procedure SBSOUND_save;
{ pro potreby ulozeni hry
}
label K;

begin
   SMIX_save; {x}
   Assign(IOFile,'save\'+SavePath+'18'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockWrite(IOFile,SoundSettings,SizeOf(SoundSettings));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
{x}BlockWrite(IOFile,MasterVolume,SizeOf(MasterVolume));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure SBSOUND_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  SMIX_load; {x}
  Assign(IOFile,'save\'+SavePath+'18'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}BlockRead(IOFile,SoundSettings,SizeOf(SoundSettings));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
{x}BlockRead(IOFile,MasterVolume,SizeOf(MasterVolume));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;

  { ***** }
  SysSoundQueue.Init;
  BuildingExplos:=255;
  SpeechIndex1:=255; SpeechIndex2:=255;
  LastSpeechIndex1:=255; LastSpeechIndex2:=0; LastSpeechCounter:=0;
  SpeechIndex21:=255; SpeechIndex22:=255;
  ActualBckSound:=Random(MaxPernamentBckSound);
  for I:=0 to MaxGunSound do with (GunSoundQueue[I]) do begin
     Used:=False;
  end;
  ActualBuildingSound:=False; ActualBuildingType:=0;
end;

{ ************************************************************************** }
begin
     C:=IOResult;
     Assign(Snd,'sound.cfg'); Reset(Snd,1);
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     BlockRead(Snd,SoundDetected,SizeOf(Boolean));
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     BlockRead(Snd,PartialSound,SizeOf(Byte));
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     BlockRead(Snd,BaseIO,SizeOf(BaseIO));
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     BlockRead(Snd,IRQ,SizeOf(IRQ));
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     BlockRead(Snd,DMA,SizeOf(DMA));
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     BlockRead(Snd,DMA16,SizeOf(DMA16));
     if ((IOResult <> 0) or (DosError <> 0)) then begin
       Writeln('Chyba pri cteni ze souboru sound.cfg');
       SoundDetected:=False;
       PartialSound:=0;
     end;
     Close(Snd);
     { ***** }
     SoundSettings[0]:=True; SoundSettings[1]:=True;
     SoundSettings[2]:=True; SoundSettings[3]:=True;
     SoundSettings[4]:=True; SoundSettings[5]:=True;
     SoundSettings[6]:=True; SoundSettings[7]:=True;
     if (PartialSound = 0) then SoundDetected:=False;
     SysSoundQueue.Init;
     BuildingExplos:=255;
     SpeechIndex1:=255; SpeechIndex2:=255;
     LastSpeechIndex1:=255; LastSpeechIndex2:=0; LastSpeechCounter:=0;
     SpeechIndex21:=255; SpeechIndex22:=255;
     A:=0; B:=0;
     Randomize;
     ActualBckSound:=Random(MaxPernamentBckSound);
     ActualBuildingSound:=False; ActualBuildingType:=0;
end.
