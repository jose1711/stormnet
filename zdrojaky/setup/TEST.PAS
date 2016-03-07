program Test;
uses Crt, DRVUti;

var DiskList:TDiskList;
    Ch:Char;
    Memory:LongInt;
    I:Word;
begin
   ClrScr;
   Memory:=43000000;
   GetDiskList(DiskList,Memory);
   Writeln('Seznam disku, na kterych je alespon ',Memory div 1024,'KB mista:');
   for Ch:='C' to 'Z' do
     if (DiskList[Ch]) then Write(Ch+' - ');
   Writeln; Writeln;

   GetStormnetDrive(Ch);
   Write('Stormnet disk: ');
   if (Ch <> ' ') then Writeln(Ch) else Writeln('zadny');
   Writeln; Writeln;

   for Ch:='C' to 'Z' do
      if (IsCD(Ch)) then begin
        Writeln('CD DRIVE: '+Ch);
      end;
   Writeln; Writeln;

   {Writeln('Kopirovani ...');
   I:=CopyDir('C:\GILIATH','C:\ZBSW');
   if (I <> 0) then Writeln('Chyba! ',I);{}

   I:=DeleteDirectory('C:\GILIATH\PAJA');
   if (I <> 0) then Writeln('Chyba mazani adresare! ',I)
   else Writeln('Mazani bylo uspesne ! ');{}
end.