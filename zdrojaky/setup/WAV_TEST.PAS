unit wav_test;
interface

function TestingSound:Boolean;
procedure Shutdown;

implementation
  uses
    CRT,
    Detect,
    SMix;
  const
    XMSRequired   = 190;    {velikost XMS v kB pro nahrani vsech zvuku}
    NumSounds = 6; {pocet nahravanych zvuku}
  var
    Sound: array[0..NumSounds-1] of PSound;
    i: byte;
    Counter: LongInt;
    InKey: char;
    Stop: boolean;
    Num: byte;
    Temp: integer;
    Ok:Boolean;

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
  procedure Shutdown;
    begin
      if (HandlerInstalled) then begin
        ShutdownMixing;
        ShutdownSB;

        for i := 0 to NumSounds-1 do
          if (Sound[i] <> Nil) then FreeSound(Sound[i]);
       end;
    end;

{ ***** }
function TestingSound:Boolean;
{
}
var IJK:Word;
begin
   Ok:=True; IJK:=0;
   LoadSound(Sound[0],IJK,'TEST.RAW');
   if (InitSB(BaseIO, IRQ, DMA, DMA16)) then begin
     if (Ok) then begin
       InitMixing;
       StartSound(Sound[0],0,0,False);
       while (VoiceUsage(0) and (not KeyPressed)) do ;
       {Shutdown;{}
     end;
   end;
end;

begin
end.
