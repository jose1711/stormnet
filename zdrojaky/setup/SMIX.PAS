{       SMIX is Copyright 1995 by Ethan Brodsky.  All rights reserved.       }

unit SMix; {Version 1.15}
 {$X+} {$G+} {$R-}
  interface

    const
      MaxSoundArrayIndex = 350;
      BlockLength   = 512;      {Size of digitized sound block               }
      Voices        = 10;        {Number of available voices                  }
    {If you change this, you also must change a constant in ExpandRange  }
    type
      PSound = ^TSound;
      TSound =
        record
          Segment: word;
          Uk:Pointer;
          StartOfs:  Word;
          SoundSize: Word;
        end;
      SndArray = array [0..MaxSoundArrayIndex] of PSound;
      PSoundArray = ^SndArray;


      var IOBase:Word;
          SoundArray:PSoundArray; { seznam nahranych zvuku }
          SoundInfoArray:array [0..12,0..2,0..1] of record
          { Cathegory, SoundType((very) light,air unit), Race }
                           Index, Sounds:Word;
                           { Index prvniho zvuku + pocet zvuku dane kategorie }
                         end;
          BaseIO: word; IRQ, DMA, DMA16: byte;



    function InitSB(BaseIO: word; IRQ: byte; DMA, DMA16: byte): boolean;
      {Initializes control parameters, resets DSP, and installs int. handler }
      {Parameters: (Can be found using GetSettings procedure in Detect)      }
      {  BaseIO:   Sound card base IO address                                }
      {  IRQ:      Sound card IRQ setting                                    }
      {  DMA:      Sound card 8-bit DMA channel                              }
      {  DMA16:    Sound card 16-bit DMA channel (0 if not supported)        }
      {Returns:                                                              }
      {  TRUE:     Sound card successfully initialized (Maybe)               }
      {  FALSE:    Sound card could not be initialized                       }
    procedure ShutdownSB;
      {Removes interrupt handler and resets DSP                              }

    procedure InitMixing;
      {Allocates internal buffers and starts digitized sound output          }
    procedure ShutdownMixing;
      {Deallocates internal buffers and stops digitized sound output         }

    function  InitXMS: boolean;
      {Attempts to intialize extended memory                                 }
      {Returns:                                                              }
      {  TRUE:     Extended memory successfully initialized                  }
      {  FALSE:    Extended memory could not be initialized                  }

    procedure LoadSound(var Sound: PSound; var UsedIndex:Word; FileName: string);
      {Allocates an extended memory block and loads a sound from a file      }
      {Parameters:                                                           }
      {  Sound:    Unallocated pointer to sound data structure               }
      {  FileName: File to load sound from (Raw signed digitized sound data) }
    procedure FreeSound(var Sound: PSound);
      {Deallocates extended memory and destroys sound data structure         }
      {Parameters:                                                           }
      {  Sound:    Unallocated pointer to sound data structure               }

    procedure StartSound(Sound: PSound; Volum:Byte; Index: byte; Loop: boolean);
      {Starts playing a sound                                                }
      {Parameters:                                                           }
      {  Sound:    Pointer to sound data structure                           }
      {  Index:    A number to keep track of the sound with (Used to stop it)}
      {  Loop:     Indicates whether the sound should be continuously looped }
      {  Volume:    0..100%
                    1..50%
                    2..25%
                    3..12%}

    procedure StopSound(Index: byte);
      {Stops playing sound                                                   }
      {Parameters:                                                           }
      {  Index:    Index of sound to stop (All with given index are stopped) }

    function VoiceUsage(Index: Byte):Boolean;
      { Vraci True, je-li dany kanal obsazen
      }
    var
      IntCount   : LongInt;  {Number of sound interrupts that have occured   }
      DSPVersion : real;     {Contains the version of the installed DSP chip }
      AutoInit   : boolean;  {Tells Auto-initialized DMA transfers are in use}
      SixteenBit : boolean;  {Tells whether 16-bit sound output is occuring  }
      VoiceCount : byte;     {Number of voices currently in use              }

    var
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

      OldIntVector     : pointer;

      HandlerInstalled : boolean;

  implementation

    uses
      CRT, DOS;
    const
      BufferLength = BlockLength * 2;

    function XMSAllocate(var Segment,Offsets: word; var Uk:Pointer; Size: word): boolean;
    begin
       GetMem(Uk,Size+16);
       if (Uk <> Nil) then begin
           XMSAllocate:=True;
           Segment:=Seg(Uk^);
           Offsets:=Ofs(Uk^);
       end else begin
           XMSAllocate:=False;
       end;
    end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
   function GetDosMemory(var Segment,Offsets,Selector:Word; Size:Word):Pointer;
   { naalokuje v chranenem rezimu DOS pamet;
     vraci Nil pri neuspechu
   }
   var A,B,C:Word;
       Error:Boolean;
   begin
      Error:=False;
      Size:=Size shr 4; { paragraf = 16b }
      asm
        mov Ax,0100h
        mov Bx,Size
        int 31h
        jnc @OK
        { allocation Error }
        mov Al,True
        mov Error,Al
        jmp @end
@OK:
        mov A,Ax
        mov B,0
        mov C,Dx
@end:
      end;
      Segment:=A; Offsets:=B; Selector:=C;
      if (not Error) then
         GetDosMemory:=Ptr(Selector,0)
      else GetDosMemory:=Nil;
    end;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
    procedure WriteDSP(Value: byte);
      begin
        repeat until (Port[WritePort] and $80) = 0;
        Port[WritePort] := Value;
        Delay(1);
      end;

    function ReadDSP: byte;
      begin
        repeat until (Port[PollPort] and $80) <> 0;
        ReadDSP := Port[ReadPort];
        Delay(1);
      end;

{ ***** }
function resetdsp : boolean;

var dsp_reset        : word;
    dsp_read_data    : word;
    dsp_write_data   : word;
    dsp_write_status : word;
    dsp_data_avail   : word;
begin
 { calculate the port addresses }
 dsp_reset        := IOBase + $6;
 dsp_read_data    := IOBase + $a;
 dsp_write_data   := IOBase + $c;
 dsp_write_status := IOBase + $c;
 dsp_data_avail   := IOBase + $e;

 { reset the dsp, and give some nice long delays just to }
 { be safe }
 port[dsp_reset] := 1;
 delay(5);

 port[dsp_reset] := 0;
 delay(5);

 resetdsp := (port[dsp_data_avail] and $80 = $80) and
              (port[dsp_read_data] = $aa);
end;

    procedure InstallHandler; forward;
    procedure UninstallHandler; forward;

    function InitSB(BaseIO: word; IRQ: byte; DMA, DMA16: byte): boolean;
      begin
       {Sound card IO ports}
        ResetPort  := BaseIO + $6;
        ReadPort   := BaseIO + $A;
        WritePort  := BaseIO + $C;
        PollPort   := BaseIO + $E;
        IOBase:=BaseIO;

       {Reset DSP, get version, and pick output mode}
        if not(ResetDSP)
          then
            begin
              InitSB := false;
              Exit;
            end;
        WriteDSP($E1);  {Get DSP version number}
        DSPVersion := ReadDSP;  DSPVersion := DSPVersion + ReadDSP/100;
        AutoInit := DSPVersion > 2.0;
        SixteenBit := {(DSPVersion > 4.0) and (DMA16 <> 0){}False;

       {Compute interrupt ports and parameters}
        if IRQ <= 7 then begin
          IRQIntVector  := $08+IRQ;
          PICMaskPort   := $21;
        end else begin
          IRQIntVector  := $70+IRQ-8;
          PICMaskPort   := $A1;
        end;
        IRQStopMask  := 1 shl (IRQ mod 8);
        IRQStartMask := not(IRQStopMask);

       {Compute DMA ports and parameters}
        if SixteenBit
          then {Sixteen bit}
            begin
              DMAMaskPort     := $D4;
              DMAClrPtrPort   := $D8;
              DMAModePort     := $D6;
              DMABaseAddrPort := $C0 + 4*(DMA16-4);
              DMACountPort    := $C2 + 4*(DMA16-4);
              case DMA16
                of
                  5:  DMAPagePort := $8B;
                  6:  DMAPagePort := $89;
                  7:  DMAPagePort := $8A;
                end;
              DMAStopMask  := DMA16-4 + $04;   {000001xx}
              DMAStartMask := DMA16-4 + $00;   {000000xx}
              DMAMode      := DMA16-4 + $58;   {010110xx}
              AckPort := BaseIO + $F;
            end
          else {Eight bit}
            begin
              DMAMaskPort     := $0A;
              DMAClrPtrPort   := $0C;
              DMAModePort     := $0B;
              DMABaseAddrPort := $00 + 2*DMA;
              DMACountPort    := $01 + 2*DMA;
              case DMA
                of
                  0:  DMAPagePort := $87;
                  1:  DMAPagePort := $83;
                  2:  DMAPagePort := $81;
                  3:  DMAPagePort := $82;
                end;
              DMAStopMask  := DMA + $04;       {000001xx}
              DMAStartMask := DMA + $00;       {000000xx}
              if AutoInit
                then DMAMode := DMA + $58      {010110xx}
                else DMAMode := DMA + $48;     {010010xx}
              AckPort := BaseIO + $E;
            end;
          if AutoInit
            then DMALength := BufferLength
            else DMALength := BlockLength;
          InstallHandler;

          InitSB := true;
      end;

    procedure ShutdownSB;
      begin
        if (HandlerInstalled) then begin
          UninstallHandler;
          ResetDSP;
        end;
      end;

    function InitXMS: boolean;
      begin
        InitXMS := true;
      end;

   {Voice control}
    type
      PVoice = ^TVoice;
      TVoice =
        record
          Sound:     PSound;
          Index:     byte;
          CurPos:    LongInt;
          Loop:      boolean;
          Volume:Byte; { 0..100%
                         1..50%
                         2..25%
                         3..12%
                        }
        end;
    var
      VoiceInUse: array[0..Voices-1] of boolean;
      Voice:      array[0..Voices-1] of TVoice;
      CurBlock:   byte;
   {Sound buffer}
    var
      SoundBlock: array[1..BlockLength] of ShortInt;

   {Mixing buffers}
    type
      PMixingBlock = ^TMixingBlock;
      TMixingBlock = array[1..BlockLength] of integer;
    var
      MixingBlock  : TMixingBlock;

   {Output buffers}
    type {8-bit}
      POut8Block   = ^TOut8Block;
      TOut8Block   = array[1..BlockLength] of byte;
      POut8Buffer  = ^TOut8Buffer;
      TOut8Buffer  = array[1..2] of TOut8Block;
    type {16-bit}
      POut16Block  = ^TOut16Block;
      TOut16Block  = array[1..BlockLength] of integer;
      POut16Buffer = ^TOut16Buffer;
      TOut16Buffer = array[1..2] of TOut16Block;
    var
      OutMemArea  : pointer;
      Out8Buffer  : POut8Buffer;
      Out16Buffer : POut16Buffer;
    var
      BlockPtr    : array[1..2] of pointer;
      CurBlockPtr : pointer;
    var
     {For auto-initialized transfers (Whole buffer)}
      BufferAddr : LongInt;
      BufferPage : byte;
      BufferOfs  : word;
     {For single-cycle transfers (One block at a time)}
      BlockAddr  : array[1..2] of LongInt;
      BlockPage  : array[1..2] of byte;
      BlockOfs   : array[1..2] of word;

    {Clipping for 8-bit output}
     var
       Clip8 : array[-128*Voices..128*Voices] of byte;

    procedure StartDAC;
      begin
        Port[DMAMaskPort]     := DMAStopMask;  Delay(1);
        Port[DMAClrPtrPort]   := $00;          Delay(1);
        Port[DMAModePort]     := DMAMode;      Delay(1);
        Port[DMABaseAddrPort] := Lo(BufferOfs);Delay(1);
        Port[DMABaseAddrPort] := Hi(BufferOfs);Delay(1);
        Port[DMACountPort]    := Lo(DMALength-1);Delay(1);
        Port[DMACountPort]    := Hi(DMALength-1);Delay(1);
        Port[DMAPagePort]     := BufferPage;   Delay(1);
        Port[DMAMaskPort]     := DMAStartMask; Delay(1);

        if SixteenBit
          then {Sixteen bit: SB16 and up (DSP 4.xx)}
            begin
              WriteDSP($41);        {Set digitized sound output sampling rate}
              WriteDSP(Hi(22050));  {  Hi byte - $56     22050 HZ            }
              WriteDSP(Lo(22050));  {  Lo byte - $22                         }
              WriteDSP($B6);        {16-bit DMA command: D/A, Auto-Init, FIFO}
              WriteDSP($10);        {16-bit DMA mode:    Signed Mono         }
              WriteDSP(Lo(BlockLength - 1));
              WriteDSP(Hi(BlockLength - 1));
            end
          else {Eight bit}
            begin
              WriteDSP($D1);        {Turn on speaker                         }
              WriteDSP($40);        {Set digitized sound time constant       }
              WriteDSP(211);        { = 256 - (1000000 / SamplingRate)       }
              if AutoInit
                then {Eight bit auto-initialized: SBPro and up (DSP 2.00+)}
                  begin
                    WriteDSP($48);  {Set DSP block transfer size             }
                    WriteDSP(Lo(BlockLength - 1));
                    WriteDSP(Hi(BlockLength - 1));
                    WriteDSP($1C);  {8-bit auto-init DMA mono sound output   }
                  end
                else {Eight bit single-cycle: Sound Blaster (DSP 1.xx+)}
                  begin
                    WriteDSP($14);  {8-bit single-cycle DMA sound output     }
                    WriteDSP(Lo(BlockLength - 1));
                    WriteDSP(Hi(BlockLength - 1));
                  end;
            end;
      end;

    procedure StopDAC;
      begin
        if SixteenBit
          then {Sixteen bit}
            begin
              WriteDSP($D5);        {Pause 16-bit DMA sound I/O              }
            end
          else {Eight bit}
            begin
              WriteDSP($D0);        {Pause 8-bit DMA mode sound I/O          }
              WriteDSP($D3);        {Turn off speaker                        }
            end;
        Port[DMAMaskPort] := DMAStopMask;
        Delay(1);
      end;

   {Loading and freeing sounds}
    procedure LoadSound(var Sound: PSound; var UsedIndex:Word; FileName: string);
      label Konec;
      var
        f: file;
        Size, PomSize: LongInt;
        InSize,IO_result: word;
      begin
        Assign(f, FileName);  Reset(f, 1);
        IO_result:=IOResult;
        if (IO_Result = 2) then GoTo Konec; { file not found }
        if (IO_Result <> 0) then begin
           Writeln('Diskova chyba cislo ',IO_Result,' pri nahravani souboru ',FileName);
           Halt;
        end;

        New(Sound);
        if (Sound = Nil) then begin
           writeln('Nedostatek pameti pro inicializaci'); Halt(4);
        end;{}

        Size := FileSize(f);
        if (Size > 65530) then begin Writeln('Prilis veliky soubor'); Halt; end;
        { oriznuti 2% shora i dolu kvuli "praskani" }
        if (Size > 1000) then PomSize:=(Size div 100)*2 else PomSize:=0;
        Dec(Size,PomSize);
        if (not XMSAllocate(Sound^.Segment,Sound^.StartOfs,Sound^.Uk, Size + 1))
        then begin
          Writeln('Chyba - nedostatek pameti'); Halt;
        end;
        BlockRead(f,Sound^.Uk^,Size);
        { oriznuti 2% od zacatku }
        Dec(Size,PomSize);
        Sound^.SoundSize := Size;
        Inc(Sound^.StartOfs, PomSize);
        Sound^.Uk:=Ptr(Sound^.Segment,Sound^.StartOfs);

        IO_result:=IOResult;
        if (IO_result <> 0) then begin
           Writeln('Diskova chyba cislo ',IO_result,' pri nahravani souboru ',FileName);
           Halt;
        end;
        Inc(UsedIndex);
      Konec:
        Close(f);
        IO_result:=IOResult;
      end;

    procedure FreeSound(var Sound: PSound);
      begin
        Dispose(Sound); Sound := nil;
      end;

   {Voice maintainance}
    procedure DeallocateVoice(VoiceNum: byte);
      begin
        VoiceInUse[VoiceNum] := false;
        with Voice[VoiceNum] do
          begin
            Sound    := nil;
            Index    := 0;
            CurPos   := 0;
            Loop     := false;
            Volume   := 0;
          end;
      end;

    { ***** }
    procedure StartSound(Sound: PSound; Volum:Byte; Index: byte; Loop: boolean);
    { Volume:    0..100%
                 1..50%
                 2..25%
                 3..12%}
      label Konec;
      var
        i, Slot: byte;
      begin
        if (Sound = Nil) then GoTo Konec;
        Slot := $FF; i := 0;
        repeat
          if not(VoiceInUse[i]) then Slot := i;
          Inc(i);
        until ((Slot <> $FF) or (i=Voices));
        if Slot <> $FF then begin
              Inc(VoiceCount);
              Voice[Slot].Sound    := Sound;
              Voice[Slot].Index    := Index;
              Voice[Slot].CurPos   := 0;
              Voice[Slot].Loop     := Loop;
              Voice[Slot].Volume   := Volum;

              VoiceInUse[Slot] := true;
        end;
Konec:
      end;

    { ***** }
    procedure StopSound(Index: byte);
      var
        i: byte;
      begin
        for i := 0 to Voices-1 do
          if Voice[i].Index = Index then begin
                DeallocateVoice(i);
                Dec(VoiceCount);
          end;
      end;

    { ***** }
    function VoiceUsage(Index: byte):Boolean;
      { Vraci True, je-li dany kanal obsazen
      }
    var I:Word;
        Result:Boolean;
    begin
       Result:=False;
       for I := 0 to Voices-1 do
         if ((Voice[I].Index = Index) and (Voice[I].Sound <> Nil))
         then Result:=True;
       VoiceUsage:=Result;
    end;

    { ***** }
    procedure UpdateVoices;
      var
        VoiceNum: byte;
      begin
        for VoiceNum := 0 to Voices-1 do begin
            if VoiceInUse[VoiceNum] then
              if Voice[VoiceNum].CurPos >= Voice[VoiceNum].Sound^.SoundSize
              then begin
                DeallocateVoice(VoiceNum);
                Dec(VoiceCount);
              end;
        end;
      end;


   {Utility functions}
    procedure SetCurBlock(BlockNum: byte);
      begin
        CurBlock := BlockNum;
        CurBlockPtr := pointer(BlockPtr[BlockNum]);
      end;

    procedure ToggleBlock;
    begin
        if CurBlock = 1 then SetCurBlock(2)
        else SetCurBlock(1);
    end;

    procedure SilenceBlock;
    begin
        FillChar(MixingBlock, BlockLength*2, 0);  {FillChar uses REP STOSW}
    end;

    procedure InitClip8;
    var i, Value: integer;
    begin
        for i := -128*Voices to 128*Voices do begin
            Value := i;
            if (Value < -128) then Value := -128;
            if (Value > +127) then Value := +127;
            Clip8[i] := Value + 128;
        end;
    end;

    procedure InitMixing;
      var
        i: integer;
        S,O,Selector:Word;
        Adr:LongInt;

      begin
        for i := 0 to Voices-1 do DeallocateVoice(i);
        VoiceCount := 0;

         if SixteenBit then begin
             {Find a block of memory that does not cross a page boundary}
              {GetMem(OutMemArea, 4*BufferLength);{}
              OutMemArea:=GetDosMemory(S,O,Selector,4*BufferLength);
              Out16Buffer := OutMemArea;
              {S:=Seg(Out16Buffer^); O:=Ofs(Out16Buffer^);{}

              Adr:=LongInt(S)*16 + O;
              for i := 1 to 2 do
                BlockPtr[i] := Addr(Out8Buffer^[i]);

              BufferPage := Adr div 65536;
              BufferOfs  := Adr mod 65536;
              BlockPage[1] := Adr div 65536;
              BlockPage[2] := Adr div 65536;
              BlockOfs[1]  := Adr mod 65536;
              BlockOfs[2]  := Adr mod 65536 + BlockLength;

              FillChar(Out16Buffer^, BufferLength*2, $00);   {Signed   16-bit}
         end else begin
              {Find a block of memory that does not cross a page boundary}
              {GetMem(OutMemArea, 2*BufferLength);{}
              OutMemArea:=GetDosMemory(S,O,Selector,2*BufferLength);
              Out8Buffer := OutMemArea;
              {S:=Seg(Out8Buffer^); O:=Ofs(Out8Buffer^);{}

              Adr:=LongInt(S)*16 + O;
              for i := 1 to 2 do
                BlockPtr[i] := Addr(Out8Buffer^[i]);

              BufferPage := Adr div 65536;
              BufferOfs  := Adr mod 65536;
              BlockPage[1] := Adr div 65536;
              BlockPage[2] := Adr div 65536;
              BlockOfs[1]  := Adr mod 65536;
              BlockOfs[2]  := Adr mod 65536 + BlockLength;{}

              FillChar(Out8Buffer^, BufferLength, $80);      {Unsigned  8-bit}
              InitClip8;
         end;

         FillChar(MixingBlock, BlockLength*2, $00);

         SetCurBlock(1);
         IntCount := 0;
         StartDAC;
      end;

    procedure ShutdownMixing;
    begin
       StopDAC;

       if SixteenBit then FreeMem(OutMemArea, 4*BufferLength)
       else FreeMem(OutMemArea, 2*BufferLength);
    end;

    procedure CopySound(Sound: PSound; Volume:Byte;
                        var CurPos: LongInt; CopyLength: word; Loop: boolean);
      var
        SoundSize: LongInt;
        DestSegment, DestOffset, SourceSegment, SourceOffset, Length :Word;
        SetVolume:Byte;
      begin
        SetVolume:=Volume;
        SoundSize := Sound^.SoundSize;
        DestSegment:=Seg(MixingBlock{}{SoundBlock{});
        SourceSegment := Sound^.Segment;
        while CopyLength > 0 do begin
           {Compute max transfer size}
            if CopyLength < SoundSize-CurPos
              then Length := CopyLength
              else Length := SoundSize-CurPos;

           {Compute starting dest. offset and update offset for next block}
            SourceOffset := Sound^.StartOfs + CurPos;
            CurPos := CurPos + Length;
            if Loop then CurPos := CurPos mod SoundSize;

           {Compute starting source offset and update offset for next block}
            DestOffset := Ofs(MixingBlock{}{SoundBlock{});

           {Update remaining count for next iteration}
            CopyLength := 0;{CopyLength - Length;{}

           {Move block}
           asm
             mov Di,DestOffset
             mov Ax,DestSegment
             mov Es,Ax
             mov Si,SourceOffset
             mov Ax,SourceSegment
             mov Bx,Length
             mov Cl,SetVolume
{-----------------------------}
             push Ds
             mov Ds,Ax
             cld                         {Left-to-right string operation        }

 @MixSample:
            mov  al, [si]               {Load a sample from the sound block    }
            inc  si                     { increment pointer                    }
            cbw                         {Convert it to a 16-bit signed sample  }
            {sal Ax,1 {}
            sar Ax,Cl
            add  es:[di], ax            {Add it into the mixing buffer         }
            add  di, 2                  {Next word in mixing buffer            }
            dec  Bx                     {Loop for next sample                  }
            jnz  @MixSample
{------------------------------}
{             cld
             push Ds
             mov Ds,Ax
        rep  movsb {}
             pop Ds
           end;
        end;
      end;

    procedure MixVoice(VoiceNum: byte);
      var
        MixLength: word;
      begin
        with Voice[VoiceNum] do
          if Loop
            then
              MixLength := BlockLength
            else
              if BlockLength < Sound^.SoundSize-CurPos
                then MixLength := BlockLength
                else MixLength := Sound^.SoundSize-CurPos;
        CopySound(Voice[VoiceNum].Sound, Voice[VoiceNum].Volume,
                  Voice[VoiceNum].CurPos, MixLength, Voice[VoiceNum].Loop);
{        asm
{          lea  si, SoundBlock         {DS:SI -> Sound data (Source)          }
{          mov  ax, ds                 {ES:DI -> Mixing block (Destination)   }
{          mov  es, ax
          lea  di, MixingBlock
          mov  cx, MixLength          {CX = Number of samples to copy        }
{          cld                         {Left-to-right string operation        }

{         @MixSample:
          mov  al, [si]               {Load a sample from the sound block    }
{          inc  si                     { increment pointer                    }
{          cbw                         {Convert it to a 16-bit signed sample  }
{          add  es:[di], ax            {Add it into the mixing buffer         }
{          add  di, 2                  {Next word in mixing buffer            }
{          dec  cx                     {Loop for next sample                  }
{          jnz  @MixSample
        end;{}
      end;

    procedure MixVoices;
      var
        i: word;
      begin
        SilenceBlock;
        for i := 0 to Voices-1 do
          if VoiceInUse[i] then MixVoice(i);
      end;

    procedure CopyData16; assembler;
      asm
        push  ds

        lea   si, MixingBlock         {DS:SI -> 16-bit input block           }
        les   di, [CurBlockPtr]       {ES:DI -> 16-bit output block          }
        mov   cx, BlockLength         {CX = Number of samples to copy        }
        cld                           {Left-to-right string operation        }

       @CopySample:
        mov   ax, [si]                {Load a sample from the mixing block   }
        add   si, 2                   {Increment source pointer              }
        sal   ax, 5                   {Shift sample left to fill 16-bit range}
        mov   es:[di], ax             {Store sample in output block          }
        add   di, 2                   {Increment destination pointer         }
        dec   cx                      {Process the next sample               }
        jnz   @CopySample

        pop   ds
      end;

    procedure CopyData8; assembler;
      asm
        push  ds
        push  bp

        lea   si, Clip8               {DS:SI -> 8-bit clipping buffer        }
        add   si, 128*Voices          {DS:SI -> Center of clipping buffer    }

        lea   bp, MixingBlock         {DS:BP -> 16-bit input block           }
        les   di, [CurBlockPtr]       {ES:DI -> 8-bit output block           }
        mov   cx, BlockLength         {CX = Number of samples to copy        }
        cld                           {Left-to-right string operation        }

       @CopySample:
        mov   bx, ds:[bp]             {SI = Sample from mixing block         }
        add   bp, 2                   {Increment source pointer (BP)         }
        mov   al, [si+bx]             {AL = Clipped sample to output         }
        mov   es:[di], al             {Store sample in output block          }
        inc   di                      {Increment destination pointer (DI)    }
        dec   cx                      {Process the next sample               }
        jnz   @CopySample

        pop   bp
        pop   ds
      end;

    procedure CopyData;
      begin
        if SixteenBit
          then CopyData16
          else CopyData8;
      end;

    procedure StartBlock_SC; {Starts a single-cycle DMA transfer}
      begin
        Port[DMAMaskPort]     := DMAStopMask; Delay(1);
        Port[DMAClrPtrPort]   := $00;         Delay(1);
        Port[DMAModePort]     := DMAMode;     Delay(1);
        Port[DMABaseAddrPort] := Lo(BlockOfs[CurBlock]); Delay(1);
        Port[DMABaseAddrPort] := Hi(BlockOfs[CurBlock]); Delay(1);
        Port[DMACountPort]    := Lo(DMALength-1);        Delay(1);
        Port[DMACountPort]    := Hi(DMALength-1);        Delay(1);
        Port[DMAPagePort]     := BlockPage[CurBlock];    Delay(1);
        Port[DMAMaskPort]     := DMAStartMask;           Delay(1);
        WriteDSP($14);                {8-bit single-cycle DMA sound output   }
        WriteDSP(Lo(BlockLength - 1));
        WriteDSP(Hi(BlockLength - 1));
      end;

    procedure IntHandler; interrupt;
      var
        Temp: byte;
      begin
        Inc(IntCount); if (IntCount > 2147483640) then IntCount:=0;

        if not(AutoInit) {Start next block first if not using auto-init DMA}
          then
            begin
              StartBlock_SC;
              CopyData;
              ToggleBlock;
            end;

        UpdateVoices;
        MixVoices;

        if (AutoInit)
          then
            begin
              CopyData;
              ToggleBlock;
            end;

        Temp := Port[AckPort];
        Port[$A0] := $20;
        Port[$20] := $20;
      end;

    procedure EnableInterrupts;  InLine($FB); {STI}
    procedure DisableInterrupts; InLine($FA); {CLI}

    procedure InstallHandler;
      begin
        DisableInterrupts;
        Port[PICMaskPort] := Port[PICMaskPort] or IRQStopMask;
        Delay(1);
        GetIntVec(IRQIntVector, OldIntVector);
        SetIntVec(IRQIntVector, @IntHandler);
        Port[PICMaskPort] := Port[PICMaskPort] and IRQStartMask;
        EnableInterrupts;
        HandlerInstalled := true;
      end;

    procedure UninstallHandler;
      begin
        DisableInterrupts;
        Port[PICMaskPort] := Port[PICMaskPort] or IRQStopMask;
        SetIntVec(IRQIntVector, OldIntVector);
        EnableInterrupts;
        HandlerInstalled := false;
      end;

begin
  HandlerInstalled := false;
end.
