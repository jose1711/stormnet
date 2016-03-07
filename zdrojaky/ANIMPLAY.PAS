{ program je nutne prekladat v tomto rezimu:
  * realny mod
  * vypnute jakekoli range-check kontroly a debugg informace
  * stack size 32000
  * min heap size 0
  * max heap size 0
}
program Animplay;
uses Dos,Crt,DrvUti;
const MaxCoreUnits = 15;
type  TUnitInfo = record
                     { Destroyed pro potreby real-time simulace }
                     Active,Destroyed:Boolean;
                     UnitType:Byte;
                     Experience:Word;
                     Kills:Word;
                     Level:Byte;
                     Name:String[15];
                     UniqueNumber:Word;
                  end;
var  PomFile:File;
     Drive:Char;
     I:Word;
     Game:Byte;
     DResult:Word;
     PlayerId:String[8]; { identifikace hrace }
     Campaign:Byte; { identifikace hry }
     CancelGame:Boolean;
     GameUniqueNum:LongInt;
     P:POINTER;
     Victory:Integer; { 0..remiza, 1..vitezstvi, -1..porazka }
     POI, VICTORYPOI:LongInt; { result z real-time }
     Zrada:Boolean;
     CoreInfo:array[0..MaxCoreUnits-1] of TUnitInfo;

{ ***** }
procedure Hide; assembler;
{ Ukryje kurzor }
asm
   mov Ah,02
   mov Bh,0h
   mov Dh,25
   mov Dl,0
   Int 10h
end;

{ ***** }
procedure LoadMissionResult;
{ nahraje vysledek mise z disku
}
var IOFile:File;
    Temp1, Temp2:Word;
begin
   Assign(IOFile,'global\result'); Reset(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,PlayerId,SizeOf(PlayerId));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,Game,SizeOf(Game));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,Campaign,SizeOf(Campaign));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,Victory,SizeOf(Victory));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,POI,SizeOf(POI));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,VICTORYPOI,SizeOf(VICTORYPOI));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,CoreInfo,SizeOf(CoreInfo));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,GameUniqueNum,SizeOf(GameUniqueNum));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,Temp1,SizeOf(Temp1));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
{x}BlockRead(IOFile,Temp2,SizeOf(Temp2));
   DResult:=IOResult; if(DResult<>0) then Halt(0);
   if ((Game = 54) and (Temp1 <> 0)) then begin
      Zrada:=True;
   end;

   Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Sabotage; interrupt; assembler;
asm
  mov Ax,$B800
  mov Es,Ax
  mov Di,0
  mov Cx,1650
  mov Ax,0
rep stosw
end;

{ ************************************************************************** }
begin
   Assign(PomFile,'animace');
   Reset(PomFile,1); I:=IOResult;
   if (I = 0) then begin
      GetIntVec($1c,P);
      SetIntVec($1c,@Sabotage);{}

      if (ParamCount = 1) then begin
        GetCDStormnetDrive(Drive);
        if (Drive = ' ') then begin
          Hide; Exec('others\intro','/E6000000 /G'); Exec('others\intro2','/E6000000 /G');ClrScr;{}
        end else
          begin
            Exec(Drive+':\giliath\stormnet\others\intro','/E6000000 /G');ClrScr;{}
            Exec(Drive+':\giliath\stormnet\others\intro2','/E6000000 /G');ClrScr;{}
          end;
      end else begin
        if (ParamCount = 2) then begin
           GetCDStormnetDrive(Drive);
           if (Drive = ' ') then begin
             Hide; Exec('others\credits','/E6000000 /G');ClrScr;Hide;{}
           end else
             begin
               Exec(Drive+':\giliath\stormnet\others\credits','/E6000000 /G');ClrScr;{}
               ClrScr;Hide;{}
             end;
           SetIntVec($1c,P);{} Halt(0);
        end else begin
            Zrada:=False;
            LoadMissionResult; {}
            case (Game) of
             10: begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\8','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\8','/E6000000 /G');ClrScr;{}
                  end;
             20,26,27,34,35:
                  if (Victory < 1) then begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\6','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\6','/E6000000 /G');ClrScr;{}
                  end else
                    if ((Game = 26) or (Game = 27)) then  begin
                      GetCDStormnetDrive(Drive);
                      if (Drive = ' ') then begin
                        Hide;{}Exec('others\3','/E6000000 /G');ClrScr;{}
                      end else
                        Exec(Drive+':\giliath\stormnet\others\3','/E6000000 /G');ClrScr;{}
                    end;
              24: begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\11','/E6000000 /G');ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\11','/E6000000 /G');ClrScr;{}
                  end;
              62: if (Victory = 1) then begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\1','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\1','/E6000000 /G');ClrScr;{}
                  end;
              30: begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\2','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\2','/E6000000 /G');ClrScr;{}
                  end;
              61,62,63,64: if (Victory < 1) then begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\2','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\2','/E6000000 /G');ClrScr;{}
                  end;
              32: begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\10','/E6000000 /G');ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\10','/E6000000 /G');ClrScr;{}
                  end;
             37,38: begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\5','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\5','/E6000000 /G');ClrScr;{}
                  end;
             52: begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\9','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\9','/E6000000 /G');ClrScr;{}
                  end;
             54: if (Zrada) then begin
                    GetCDStormnetDrive(Drive);
                    if (Drive = ' ') then begin
                      Hide;{}Exec('others\7','/E6000000 /G'); ClrScr;{}
                    end else
                      Exec(Drive+':\giliath\stormnet\others\7','/E6000000 /G');ClrScr;{}
                  end;
            end;
        end;
      end;

      SetIntVec($1c,P);{}
      Hide;{}
   end;
end.