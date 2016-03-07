unit Detect;
interface

function SoundTest(var R1,R2:String):Boolean;
function GetSettings(var BaseIO: word; var IRQ: byte; var DMA: byte;var DMA16: byte): byte;

{var
      ResetPort        : word;
      ReadPort         : word;
      WritePort        : word;
      PollPort         : word;
      AckPort          : word;

      PICRotatePort    : word;
      PICMaskPort      : word;

      DMAMaskPort      : word;
      DMAClrPtrPort    : word;
      DMAModePort      : word;
      DMABaseAddrPort  : word;
      DMACountPort     : word;
      DMAPagePort      : word;

      IRQStartMask     : byte;
      IRQStopMask      : byte;
      IRQIntVector     : byte;

      DMAStartMask     : byte;
      DMAStopMask      : byte;
      DMAMode          : byte;
      DMALength        : word;

      IntCount   : LongInt;  {Number of sound interrupts that have occured   }
{      DSPVersion : real;     {Contains the version of the installed DSP chip }
{      AutoInit   : boolean;  {Tells Auto-initialized DMA transfers are in use}
{      SixteenBit : boolean;  {Tells whether 16-bit sound output is occuring  }
 {     VoiceCount : byte;     {Number of voices currently in use              }
 {     BaseIO: word; IRQ, DMA, DMA16: byte;{}


implementation
uses Crt, DOS, Wav_test, SMIX;

var GUARDTIME:LongInt;
    Sound: array[0..0] of PSound;

procedure TimerOn;
{ nastartuje mereni casoveho intervalu
}
var T1,T2:Word;
begin
  asm
    mov Ah,00h
    int 1ah
    mov T1,Dx
    mov T2,Cx
  end;
  GUARDTIME:=LongInt(T2)*65535+T1;
end;

function Timer:Boolean;
{ nastartuje mereni casoveho intervalu
}
var T1,T2:Word;
begin
  asm
    mov Ah,00h
    int 1ah
    mov T1,Dx
    mov T2,Cx
  end;
  if (LongInt(T2)*65535+T1-GUARDTIME) > 8 then Timer:=True else Timer:=False;
end;

{ ***** }
    function Convert_to_str(Num:Word):String;
    {
    }
    var Pom:String;
    begin
        Str(Num,Pom);
        Convert_to_str:=Pom;
    end;

    { ***** }
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
    procedure WriteDSP(Value: byte);
    begin
      repeat until (Port[WritePort] and $80) = 0;
      Port[WritePort] := Value;
    end;

    { ***** }
    function ReadDSP: byte;
    begin
      repeat until (Port[PollPort] and $80) <> 0;
      ReadDSP := Port[ReadPort];
    end;

    { ***** }
    function ResetDSP: boolean;
    var
      i: byte;
    begin
      Port[ResetPort] := 1;
      Delay(1);                              {One millisecond}
      Port[ResetPort] := 0;
      i := 100;
      while (ReadDSP <> $AA) and (i > 0) do Dec(i);
      if i > 0 then ResetDSP := true
      else ResetDSP := false;
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
        if Pos(ID, Temp) <> 0 then begin
          Delete(Temp, 1, Pos(ID, Temp));
          Delete(Temp, Pos(' ', Temp), 255);
          if Hex then Insert('$', Temp, 1);
          Val(Temp, Num, Code);
          if Code = 0 then GetSetting := Num
          else GetSetting := 0;
        end else GetSetting := 255;
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
function GetSettings(var BaseIO: word; var IRQ: byte; var DMA: byte;var DMA16: byte): byte;
{Gets sound card settings from BLASTER environment variable            }
{Parameters:                                                           }
{  BaseIO:  Sound card base IO address                                 }
{  IRQ:     Sound card IRQ                                             }
{  DMA:     Sound card 8-bit DMA channel                               }
{  DMA16:   Sound card 16-bit DMA channel (0 if none)                  }
{Returns:                                                              }
{  0:    Sound card settings found successfully                        }
{  1:   Sound card settings could not be found                         }
{  2:   Sound card settings could not be found, but sound card found   }
var
  BLASTER: string;
  A:Word;
begin
  BLASTER := UpcaseStr(GetEnv('BLASTER'));
  BaseIO := GetSetting(BLASTER, 'A', True); {Decimal}
  if (BaseIO  = 255)  then
    for a := 1 to 5 do
      if reset_dsp(a) then begin
         BaseIO:=a * $10 + $200;
         break;
      end;
  IRQ    := GetSetting(BLASTER, 'I', false); {Decimal}
  DMA    := GetSetting(BLASTER, 'D', false); {Decimal}
  DMA16  := 0; {Decimal}

  GetSettings := 0;
  if BLASTER = '' then GetSettings := 2;
  if IRQ     = 255 then GetSettings := 2;
  if DMA     = 255 then GetSettings := 2;
  if BaseIO  = 255  then GetSettings := 1;
  {We can survive if there isn't a DMA16 channel}
end;

{ ***** }
function SoundTest(var R1,R2:String):Boolean;
var Pom:String;
    OK:Boolean;
    I,J:Word;
begin
   R1:=''; R2:=''; Ok:=False;
   ShutDown;
   case (GetSettings(BaseIO, IRQ, DMA, DMA16)) of
     0 : Ok:=True;
     1 : Ok:=False;
     2 : begin {AUTODETEKCE}
            Ok:=False;
            LoadSound(Sound[0],I,'TEST2.RAW');
            if (True{LoadSound(Sound[0], 'TEST2.RAW')}) then begin
               DMA:=0;
               while ((DMA < 4) and (not Ok)) do begin
                 IRQ:=2; if (DMA = 2) then DMA:=3;
                 while ((IRQ < 16) and (not Ok)) do begin
                    if (InitSB(BaseIO, IRQ, DMA, DMA16)) then begin
                       InitMixing; TimerOn;
                       StartSound(Sound[0],0,0,False);
                       while (VoiceUsage(0) and (not Timer)) do ;
                       if (not Timer) then begin {uspech!}
                          Ok:=True;
                       end;
                       Shutdown;
                    end;
                    if (not OK) then begin
                       Inc(IRQ);
                       if (IRQ < 5) then IRQ:=5;
                       if (IRQ = 8) then Inc(IRQ);
                       if (IRQ > 12) then IRQ:=16;
                    end;
                 end;
                 if (not OK) then Inc(DMA);
               end;
            end;
         end;
   end;

   if (not OK) then begin
      SoundTest:=False;
      R1:='Chyba : zrejme spatne nastaveni v autoexec.bat: SET BLASTER = ...';
   end else begin
      if not (InitSB(BaseIO, IRQ, DMA, DMA16)) then begin
         SoundTest:=False;
         R1:='Chyba inicializace zvukove karty';
         R2:='Spatna IO adresa, karta neni instalovana, nebo je nekompatibilni se SB';
      end;
      SoundTest:=True;
      if SixteenBit then R1:='BaseIO ='+HexW(BaseIO)+ 'h   IRQ'+ Convert_to_str(IRQ)+
                             '  DMA8='+ Convert_to_str(DMA)+ '   DMA16='+ Convert_to_str(DMA16)
      else R1:='BaseIO='+ HexW(BaseIO)+ 'h   IRQ'+ Convert_to_str(IRQ) +
                       '   DMA8='+ Convert_to_str(DMA);

      Str(DSPVersion:0:2,Pom);
      R2:='DSP verze '+ Pom+ ':  ';
      if SixteenBit then R2:=R2+'16-bitova, '
      else R2:=R2+'8-bitova, ';
      if AutoInit then R2:=R2+'auto-inicializace'
      else R2:=R2+'single-cycle';
      {Shutdown;{}
  end;
end;

{ ************************************************************************** }
  begin
     if (GetSettings(BaseIO, IRQ, DMA, DMA16) = 0) then InitSB(BaseIO, IRQ, DMA, DMA16);
  end.