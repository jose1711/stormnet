program Main;
{$C FIXED PRELOAD PERMANENT}
uses Dos,Crt;

const MaxCoreUnits = 15;
TYPE
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

var Ret:String;
    CancelGame:Boolean;
    Game:Byte;
    GameUniqueNum:LongInt;

    DResult:Word;
    VICTORYPOINTS, POINTS:LongInt;
    PlayerId:String[8]; { identifikace hrace }
    Campaign:Byte; { identifikace hry }
    CoreInfo:array[0..MaxCoreUnits-1] of TUnitInfo;
    Victory,Code:Integer;
    Sim:Byte;
    IOFile:File;
    Debug:Boolean;
    Msg:String;

{ ***** }
procedure SaveMissionResult;
{ ulozi vysledek mise na disk
}
var IOFile:File;
    Temp:Word;
    Score, MyLostB, MyLostU, MyKilledB, MyKilledU,Time:LongInt;
begin
   MyLostB:=0; MyLostU:=0; MyKilledB:=0; MyKilledU:=0; Score:=0; Time:=0;
   Assign(IOFile,'global\result'); Rewrite(IOFile,1);
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,PlayerId,SizeOf(PlayerId));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,Game,SizeOf(Game));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,Campaign,SizeOf(Campaign));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,Victory,SizeOf(Victory));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,POINTS,SizeOf(POINTS));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,VICTORYPOINTS,SizeOf(VICTORYPOINTS));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,CoreInfo,SizeOf(CoreInfo));
   DResult:=IOResult;
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
   {x}BlockWrite(IOFile,GameUniqueNum,SizeOf(GameUniqueNum));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;

{x}BlockWrite(IOFile,MyLostB,SizeOf(MyLostB));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,MyLostU,SizeOf(MyLostU));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,MyKilledB,SizeOf(MyKilledB));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,MyKilledU,SizeOf(MyKilledU));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,Score,SizeOf(Score));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;
{x}BlockWrite(IOFile,Time,SizeOf(Time));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('chyba pri ukladani "result"');Halt(100);end;

   Temp:=0;
   {x}BlockWrite(IOFile,Temp,SizeOf(Temp));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('simul.exe-chyba komunikace s diskem');Halt(100);end;
   {x}BlockWrite(IOFile,Temp,SizeOf(Temp));
   DResult:=IOResult;if(DResult<>0) then if(DResult<>0)then begin Writeln('simul.exe-chyba komunikace s diskem');Halt(100);end;

   Close(IOFile); DResult:=IOResult;
end;

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
procedure LoadMain;
{ ulozi main informace
}
var IOFile:File;
    DResult:Word;
begin
   Assign(IOFile,'main.cfg'); Reset(IOFile,1);
   DResult:=IOResult; if(DResult<>0) then begin Writeln('main.exe - chyba komunikace s diskem ',DResult); Halt(100); end;
{x}BlockRead(IOFile,CancelGame,SizeOf(CancelGame));
   DResult:=IOResult;if(DResult<>0)then begin Writeln('main.exe - chyba komunikace s diskem ',DResult); Halt(100); end;
{x}BlockRead(IOFile,Game,SizeOf(Game));
   DResult:=IOResult;if(DResult<>0)then begin Writeln('main.exe - chyba komunikace s diskem ',DResult); Halt(100); end;
{x}BlockRead(IOFile,PlayerId,SizeOf(PlayerId));
   DResult:=IOResult;if(DResult<>0)then begin Writeln('main.exe - chyba komunikace s diskem ',DResult); Halt(100); end;
{x}BlockRead(IOFile,GameUniqueNum,SizeOf(GameUniqueNum));
   DResult:=IOResult;if(DResult<>0)then begin Writeln('main.exe - chyba komunikace s diskem ',DResult); Halt(100); end;
   Close(IOFile); DResult:=IOResult;
   {Erase(IOFile); DResult:=IOResult;{}
end;

{ ************************************************************************** }
begin
   LoadMain; ClrScr; Debug:=False;
   if (not CancelGame) then begin
      if (Debug) then begin
         Str(Game,Ret);
         Writeln('CHCETE SIMULOVAT (0) anebo real-time (1) ?');
         Readln(Sim);
         if (Sim = 1) then begin
            {Writeln('Spoustim manazer');{}
            SwapVectors;
            Exec('manazer.exe',Ret+' '+PlayerId);
            {Writeln('Manazer korektne ukoncen'); Delay(500);{}
            SwapVectors;
         end else begin
            Writeln('MISE CISLO: ',Game);
            Writeln('zadejte vysledek teto mise: (-1 porazka, 0 remiza, 1 viteztvi)');
            Readln(Victory);
            Writeln('zadejte kredity, ziskane ve hre: ');
            Readln(POINTS);
            Writeln('zadejte prestiz: ');
            Readln(VICTORYPOINTS);
            SaveMissionResult;
            Assign(IOFile,'save\'+PlayerId+'\continue'); Erase(IOFile); DResult:=IOResult;
         end;
      end else begin
         Str(Game,Ret);
         SwapVectors;
         Exec('manazer.exe',Ret+' '+PlayerId);
         if ((DosError <> 0) or (DosExitCode <> 0)) then begin
            case (DosError) of
               2  : Msg:='File not found';
               3  : Msg:=' Path not found';
               5  : Msg:=' Access denied';
               6  : Msg:=' Invalid handle';
               8  : Msg:=' Not enough memory';
              10  : Msg:=' Invalid environment';
              11  : Msg:=' Invalid format';
              18  : Msg:=' No more files';
            else
              Msg:='unknown';
            end;
            ClrScr;
            GoToXY(10,5); TextColor(LightRed);
            Write('!! V PRUBEHU HRY DOSLO K CHYBE !!');
            GoToXY(1,10); TextColor(LightBlue);
            Write('Postup zotaveni:');
            GoToXY(1,12); TextColor(LightGray);
            Write('- v uvodnim menu hry si zvolte POKRACOVAT:');
            GoToXY(1,13); TextColor(LightGray);
            Write('- zde si zvolte sveho hrace');
            GoToXY(1,14); TextColor(LightGray);
            Write('- po zahajeni strategie dojde k automatickemu nahrani posledni pozice');
            GoToXY(1,15); TextColor(LightGray);
            Write('! Pokud doslo k chybe pri nabihani real-time strategie, zotaveni nefunguje!');
            GoToXY(1,16); TextColor(LightGray);
            Write('V takovem pripade misi znovu spustte z globalni casti strategie.');
            GoToXY(1,17); TextColor(White);
            Write('Samostatne mise spustte znovu, pricemz dojde k auto nahrani posledni pozice.');

            GoToXY(1,20); TextColor(DarkGray);
            Write('Kod chyby podrizeneho procesu: '+Msg);
            GoToXY(1,21); TextColor(DarkGray);
            Write('Deatailni popis chyb je v souborech error.log error.msg error.adr');
            Hide; ReadKey; ReadKey;
            {X}
            SwapVectors;
            Halt(100);
         end;
         SwapVectors;
      end;
      {XXX}
      Hide;{}
      if (Game >= 100) then Halt(2) else Halt(0);
   end;
   Hide;{} Halt(100);
end.