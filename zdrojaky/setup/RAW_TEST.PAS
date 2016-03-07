unit Raw_test;
interface

function TestingSound:Boolean;

implementation
  uses
    CRT,
    Detect,
    SMix;
  const
    XMSRequired   = 190;    {velikost XMS v kB pro nahrani vsech zvuku}
    NumSounds = 6; {pocet nahravanych zvuku}
  var
    BaseIO: word; IRQ, DMA, DMA16: byte;
    Sound: array[0..NumSounds-1] of PSound;
    i: byte;
    Counter: LongInt;
    InKey: char;
    Stop: boolean;
    Num: byte;
    Temp: integer;
    OldExitProc: pointer;
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

  procedure OurExitProc; far;
   {Tato procedure je volana vzdy pred ukonceni programu, aby se regulerne}
   {odalokovala pamet}
    var
      i: byte;
    begin
      for i := 0 to NumSounds-1 do
        if Sound[i] <> nil then FreeSound(Sound[i]);
      ExitProc := OldExitProc; {Chain to next exit procedure}
    end;

  procedure Init;
  begin
      Ok:=True;
      if not(GetSettings(BaseIO, IRQ, DMA, DMA16)) then begin
        Ok:=False;
      end else begin
        if not(InitSB(BaseIO, IRQ, DMA, DMA16)) then begin
          Ok:=False;
        end;
      end;
      if (not(InitXMS) or (not OK)) then Ok:=False
      else begin
        if GetFreeXMS < XMSRequired then Ok:=False
        else begin
          Ok:=LoadSound(Sound[0],ParamStr(1));
          OldExitProc := ExitProc;
          ExitProc := @OurExitProc;
          InitMixing;
        end
     end;
  end;

  procedure Shutdown;
    begin
      ShutdownMixing;
      ShutdownSB;

      for i := 0 to NumSounds-1 do
        if (Sound[i] <> Nil) then FreeSound(Sound[i]);
    end;

{ ***** }
function TestingSound:Boolean;
{ TSound =
        record
          Segment: word;
          Uk:Pointer;
          StartOfs:  Word;
          SoundSize: Word;
        end;
}
VAR i:wORD;
    P:^Byte;
begin
   Init;
   TestingSound:=Ok;
   if (Ok) then begin
     for I:=0 to Sound[0]^.SoundSize-1 do
     with (Sound[0]^) do begin
       P:=Ptr(Segment,StartOfs+I);
       if (P^ > 55) then P^:=P^-55 else P^:=0;{}
     end;

     StartSound(Sound[0],0,0,False);
     while (VoiceUsage(0)) do ;
     StopSound(1);
     Shutdown;
   end;
end;

begin
end.
