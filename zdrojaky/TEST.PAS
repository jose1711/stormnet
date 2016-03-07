program Test;
uses Data, Graph257,Crt;
const Ws : set of Byte = [$0d,$20,$0a];
var ProductionCfgFile:file;
    IO_Result:Word;
    ProductionCfgFileWay:String;
    Production_time_plus:Single;

procedure Error(IO:word; Txt:String);
begin
   Writeln; Write;
   Writeln('chyba: ',0,'  '+Txt);
   Halt;
end;

{ ****** }
procedure OpenProductionCfgFile;
{
}
var Way:String;
begin
   Way:='product.spd';
   InvalidateCache; Assign(ProductionCfgFile,Way); ProductionCfgFileWay:=Way;

   if (InternalCache) then begin
     IO_Result:=CacheFetch(Way);
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + +ProductionCfgFileWay);
   end else begin
     Reset(ProductionCfgFile,1); IO_Result:=IOResult;
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ' + +ProductionCfgFileWay);
   end;
end;

{ ****** }
procedure ReadComment;
{
}
var Character:Char;
begin
  if (not CacheEof(ProductionCfgFile)) then begin
    CacheBlockRead(ProductionCfgFile,@Character,1);
    if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
    while ((not CacheEof(ProductionCfgFile)) and (Character <> ';')) do begin
      CacheBlockRead(ProductionCfgFile,@Character,1);
      if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
    end;
  end;
end;

{ ***** }
function ReadWord:Word;
{ vraci 65535 pri konci souboru
}
var Character:Char;
    Num:Word;
begin
   Num:=0;
   if (CacheEof(ProductionCfgFile)) then begin
     ReadWord:=65535; Exit;
   end;
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);

   while ((not CacheEof(ProductionCfgFile)) and (not (Character in ['0'..'9']))) do begin
     CacheBlockRead(ProductionCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   end;

   if (CacheEof(ProductionCfgFile)) then begin
     ReadWord:=65535; Exit;
   end;

   repeat
     Num:=Num*10+(Ord(Character)-Ord('0'));
     CacheBlockRead(ProductionCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   until (CacheEof(ProductionCfgFile) or (not (Character in ['0'..'9'])));

   if (CacheEof(ProductionCfgFile)) then begin
     ReadWord:=65535; Exit;
   end;
   ReadWord:=Num;
end;

{ ***** }
function ReadSingle:Single;
{
}
var Character:Char;
    Num:Single;
begin
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);

   while ((not CacheEof(ProductionCfgFile)) and (not (Character in ['0'..'9']))) do begin
     CacheBlockRead(ProductionCfgFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   end;

   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;

   Num:=10.0*(Ord(Character)-Ord('0'));
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   Num:=Num+Ord(Character)-Ord('0');
   { vynechame desetinnou tecku }
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   CacheBlockRead(ProductionCfgFile,@Character,1);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+ProductionCfgFileWay);
   if (CacheEof(ProductionCfgFile)) then begin
     ReadSingle:=65535; Exit;
   end;
   Num:=Num+0.1*(Ord(Character)-Ord('0'));

   ReadSingle:=Num;
end;

{ ****** }
procedure ReadProductionSpeed(Num:Word);
{ nacte a nastavi Production_time_plus
}
var P:Word;
begin
   OpenProductionCfgFile; Production_time_plus:=1;
   ReadComment;
   Production_time_plus:=Production_time_plus*ReadSingle;
   ReadComment; ReadComment;
   P:=ReadWord;
   while ((P <> 65535) and (P <> Num)) do begin
      ReadComment;
      P:=ReadWord;
   end;
   if ((P = Num) and (P <> 65535)) then begin
     Production_time_plus:=Production_time_plus*ReadSingle;
   end else begin
      Error(0,'spatny dotaz nebo chyba v souboru product.spd');
   end;
   Production_time_plus:=Round(Production_time_plus*100)/100;
end;

{ ************************************************************************}
begin
   if (AllocateGlobalMemory(2000000)) then
     if (CacheInit) then begin
        ClrScr;
        GotoXY(0,5);
        ReadProductionSpeed(100);
        Writeln('Rychlost produkce u mise 100: ',Production_time_plus);
        ReadKey;
     end;
end.

