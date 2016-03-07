unit SBSound;
{$C FIXED PRELOAD PERMANENT}
{ * }
interface
const QLength = 10;

procedure SoundInit;
procedure Shutdown;
procedure PlaySound(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);

{ ***** }
var
    SoundSettings: array[0..7] of Boolean; { povoluje/zakazuje ruzne zvuky
          0: veskery zvuk
          1: hlasy jednotek
          2: vystrely
          3: exploze strel
          4: exploze budov
          5: systemove hlasky
          6: zvuky pozadi
          7:pernamentni zvuky pozadi
    }

implementation

{ * }
  uses
    Dos, CRT, SMix, Data_glb;
  const
    XMSRequired   = 190;    {velikost XMS v kB pro nahrani vsech zvuku}
    NumSounds = 6; {pocet nahravanych zvuku}
    MaxGunSound = 7;
    MaxSysSound = 11; { pocet zvuku-1 }
    MaxExplosioSound = 25;
    MaxBckSound = 24; { max pocet zvuku pozadi }
    MaxPernamentBckSound = 2; { max pocet pernamentnich zvuku pozadi }
  var
    MasterVolume:Byte;
    GunSound: array[0..MaxGunSound] of PSound;
    SysSound: array[0..MaxSysSound] of PSound;
    ExplosioSound: array[0..MaxExplosioSound] of PSound;
    BckSound: array[0..MaxBckSound] of PSound;
    PernamentBckSound: array[0..MaxPernamentBckSound] of PSound;
    ActualBckSound:Word;

    GunSoundQueue: array[0..MaxGunSound] of record
    { fronta zvuku, pripravenych pro zahrani }
                      Vol:Byte; { hlasitost }
                      Used:Boolean; { vyuziti }
                   end;
    ClickSound: PSound; { zvuk clicku mysi }

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
    OldExitProc: pointer;
    Pomocna:Word;
    Snd:File;
    SoundDetected:Boolean;
    PartialSound:Byte;

    A,B,C:Word;

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
procedure OurExitProc; far;
{Tato procedure je volana vzdy pred ukonceni programu, aby se regulerne
 odalokovala pamet }
var
  i: byte;
begin
   ExitProc := OldExitProc; {Chain to next exit procedure}
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
    if (not InitSB(BaseIO, IRQ, DMA, DMA16)) then begin
         writeln('Chyba inicializace zvukove karty');
         writeln('Spatna IO adresa, karta neni instalovana, nebo je nekompatibilni se SB');
         Halt(2);
    end;
  {end;{}
  Port[BaseIO+4]:=$22;
  Delay(1);
  MasterVolume:=Port[BaseIO+5];
  Delay(1);
  Port[BaseIO+4]:=$22;
  Delay(1);
  Port[BaseIO+5]:=14 shl 4 + 14;
  Delay(1);

  LoadSound(ClickSound,UsedIndex,'sound\click.raw');
  OldExitProc := ExitProc;
  ExitProc := @OurExitProc;

  InitMixing;
  { Dalsi inicializace }
  for I:=0 to MaxGunSound do with (GunSoundQueue[I]) do begin
     Used:=False;
  end;
Konec:
end;

{ ***** }
procedure Shutdown;
begin
    Port[BaseIO+4]:=$22;
    Delay(1);
    Port[BaseIO+5]:=MasterVolume;
    Delay(1);

    if (SoundDetected) then begin
       for i := 0 to NumSounds-1 do
          StopSound(i);{}
        ShutdownMixing;
        ShutdownSB;
    end;
end;

{ ***** }
procedure PlaySound(SoundType:Byte; Volume:Byte; Index1,Index2:Byte);
{ zahraje zvuk
  SoundType: 0 .. click mysi
  Volume:  0..100%
           1..50%
           2..25%
           3..12%
  Index1, Index2 neopouzito
}
label Konec;
var R:Word;
    Channel:Byte;
begin
   if ((not SoundDetected) or (not SoundSettings[0])) then GoTo Konec;
   case (SoundType) of
     0 : StartSound(ClickSound,Volume,4,False);
   end;
Konec:
end;

{ ************************************************************************** }
begin
     C:=IOResult;
     Assign(Snd,PathStr+'sound.cfg'); Reset(Snd,1);
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
     BuildingExplos:=255;
     SpeechIndex1:=255; SpeechIndex2:=255;
     LastSpeechIndex1:=255; LastSpeechIndex2:=0; LastSpeechCounter:=0;
     SpeechIndex21:=255; SpeechIndex22:=255;
     A:=0; B:=0;
     Randomize;
     ActualBckSound:=Random(MaxPernamentBckSound);
end.
