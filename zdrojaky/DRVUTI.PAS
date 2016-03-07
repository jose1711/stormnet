{ DiskFree
  FindFirst, FindNext
  FSplit
  SetFAttr, GetFAttr
  RmDir
  MkDir
}
unit DrvUti;

interface
uses Crt, Dos;

type TDiskList = array['C'..'Z'] of Boolean;

procedure GetDiskList(var DiskList:TDiskList; Memory:LongInt);
procedure GetStormnetDrive(var Ch:Char);
procedure GetCDStormnetDrive(var Ch:Char);
function IsCD(Ch:Char):Boolean;
function DeleteDirectory(Path:String):Word;
function PrepareDirectory(Path:String):Word;
function CopyDir(Source, Dest:String):Word;

var TotalMemory,ActualMemory:LongInt;

implementation

var IOFile,InFile,OutFile:File;
    DResult,Result:Word;

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


procedure GetDiskList(var DiskList:TDiskList; Memory:LongInt);
{ vrati seznam disku, ktere jsou k dispozici, na ktere lze zapisovat
  a ktere maji nejmene Memory volneho mista
}
var I:Char;
begin
  for I:='C' to 'Z' do begin
    DiskList[I]:=False;
    Assign(IOFile,I+':\$$$tmp.$$$');
    Rewrite(IOFile,1); Result:=IOResult;
    Close(IOFile); Erase(IOFile); DResult:=IOResult;
    if (Result = 0) then begin
    { zapisovatelny disk }
       if (DiskFree(Ord(I)-Ord('C')+3) > Memory) then DiskList[I]:=True;
    end;
  end;
end;

{ ***** }
procedure GetStormnetDrive(var Ch:Char);
{ vrati stormnet drive
  vraci mezeru pri neuspechu
}
var I:Char;
    Rec:SearchRec;
    Path:String;
    Res:Boolean;
begin
  Ch:=' ';
  for I:='C' to 'Z' do begin
     Path:=I+':\GILIATH\STORMNET';
     FindFirst(Path,Directory,Rec);
     if ((DosError = 0) and (not IsCD(I))) then begin
       Ch:=I;
     end;
  end;
end;

{ ***** }
procedure GetCDStormnetDrive(var Ch:Char);
{ vrati CD rom stormnet drive
  vraci mezeru pri neuspechu
}
var I:Char;
    Rec:SearchRec;
    Path:String;
    Res:Boolean;
begin
  Ch:=' ';
  for I:='C' to 'Z' do begin
     Path:=I+':\GILIATH\STORMNET';
     FindFirst(Path,Directory,Rec);
     if (DosError = 0) then begin
       Res:=True;
       FindFirst(I+':\*',Directory,Rec);
       repeat
          if (Rec.Name <> 'GILIATH') then Res:=False;
          FindNext(Rec);
       until (DosError <> 0);
       if ((Res) and (IsCD(I))) then Ch:=I;
     end;
  end;
end;

{ ***** }
function IsCD(Ch:Char):Boolean;
{ vrati True, je-li drive CD
  funguje pouze pro disk, ktery ma prvni adresar neprazny (jsou tam soubory)
  nebo ma nejaky soubor v koreni
}
var Attr:Word;
    Rec:SearchRec;
    Path:String;
begin
   Path:=Ch+':\*.*';
   FindFirst(Path,AnyFile,Rec);
   if (DosError <> 0) then begin
     Path:=Ch+':\*';
     FindFirst(Path,Directory,Rec);
     if (DosError = 0) then
       FindFirst(Ch+':\'+Rec.Name,AnyFile,Rec)
     else Rec.Name:='*.*';
   end;
   Path:=Ch+':\'+Rec.Name; Assign(IOFile,Path);
   GetFAttr(IOFile,Attr);
   SetFAttr(IOFile,ReadOnly); Result:=DosError;
   SetFAttr(IOFile,Attr);
   if (DosError = 5) then IsCd:=True else IsCd:=False;
   if (DiskFree(Ord(Ch)-Ord('C')+3) <> 0) then IsCd:=False;
end;

{ ***** }
function DeleteDirectory(Path:String):Word;
{ vymaze adresar s cestou Path (bez lomitka na konci)
  sama fce vraci uspesnost operace
}
label Konec;
var Rec:SearchRec;
begin
   FindFirst(Path,Directory,Rec);
   DResult:=DosError;
   if ((DResult = 3) or (DResult = 18)) then begin
   { cesta neexistuje  }
      Result:=0;
   end else begin
     if ((DResult = 2) or (DResult = 0)) then begin
     { adresar existuje - vymaz ho }
       FindFirst(Path+'\*.*',AnyFile,Rec); DResult:=DosError;
       while (DResult = 0) do begin
         if ((Rec.Name <> '.') and (Rec.Name <> '..')) then begin
            Assign(IOFile,Path+'\'+Rec.Name);
            Erase(IOFile); DResult:=IOResult;
         end;
         FindNext(Rec); DResult:=DosError;
       end;
       RmDir(Path); Result:=IOResult;
     end else begin
     { nejaka chyba ! }
       Result:=DResult; GoTo KOnec;
     end;
   end;

Konec:
   DeleteDirectory:=Result;
end;


{ ***** }
function PrepareDirectory(Path:String):Word;
{ vytvori adresar s cestou Path (bez lomitka na konci)
  pokud adresar existuje, vymaze vsechny soubory uvnitr
  Sama fce vraci uspesnost operace
}
label KOnec;
var Rec:SearchRec;
begin
   FindFirst(Path,Directory,Rec);
   DResult:=DosError;
   if ((DResult = 3) or (DResult = 18)) then begin
   { cesta neexistuje - vytvor adrersar }
     MkDir(Path); Result:=IOResult;
   end else begin
     if ((DResult = 2) or (DResult = 0)) then begin
     { adresar existuje - vymaz ho }
       FindFirst(Path+'\*.*',AnyFile,Rec); DResult:=DosError;
       while (DResult = 0) do begin
         if ((Rec.Name <> '.') and (Rec.Name <> '..')) then begin
            Assign(IOFile,Path+'\'+Rec.Name);
            Erase(IOFile); DResult:=IOResult;
         end;
         FindNext(Rec); DResult:=DosError;
       end;
       Result:=0;
     end else begin
     { nejaka chyba ! }
       Result:=DResult; GoTo KOnec;
     end;
   end;

Konec:
   PrepareDirectory:=Result;
end;

{ ***** }
procedure DrawProceed;
{
}
var Proceed:Word;
    Ret:String;
begin
   Proceed:=ActualMemory div (TotalMemory div 100);
   Str(Proceed,Ret);
   GoToXY(38,10); Writeln('     '); Hide;
   GoToXY(39,10); Writeln(Ret+'%'); Hide;
end;

{ ***** }
function CopyDir(Source, Dest:String):Word;
{ prekopiruje soubory ze zdrojoveho do ciloveho adresare
  adresare nejsou zakonceny lomitkem, musi existovat.
  Vraci chybovost operace
}
label KOnec;
var I, BigBlocks, Remainder:Word;
    Size:LongInt;
    P:Pointer;
    Rec:SearchRec;
begin
   GetMem(P,65100);
   Source:=Source+'\'; Dest:=Dest+'\'; Result:=0;
   FindFirst(Source+'*.*',AnyFile,Rec);
   if (DosError = 0) then begin
      repeat
         if (Rec.Attr <> Directory) then begin
           Assign(InFile,Source+Rec.Name);
           { * zacatek kopirovani souboru * }
           Reset(InFile,1); Result:=IOResult; if (Result <> 0) then GoTo Konec;
           Size:=FileSize(InFile); Result:=IOResult; if (Result <> 0) then GoTo Konec;
           Assign(OutFile,Dest+Rec.Name);
           ReWrite(OutFile,1); Result:=IOResult; if (Result <> 0) then GoTo Konec;
           BigBlocks:=Size div 65000; Remainder:=Size mod 65000;
           for I:=1 to BigBlocks do begin
             BlockRead(InFile,P^,65000); Result:=IOResult; if (Result <> 0) then GoTo Konec;
             BlockWrite(OutFile,P^,65000); Result:=IOResult; if (Result <> 0) then GoTo Konec;
           end;
           if (Remainder > 0) then begin
             BlockRead(InFile,P^,Remainder); Result:=IOResult; if (Result <> 0) then GoTo Konec;
             BlockWrite(OutFile,P^,Remainder); Result:=IOResult; if (Result <> 0) then GoTo Konec;
           end;
           Close(InFile); DResult:=IOResult; Close(OutFile); DResult:=IOResult;
           { * konec kopirovani souboru * }
           ActualMemory:=ActualMemory+Size;
           DrawProceed;
         end;
         FindNext(Rec);
      until (DosError <> 0);
   end;

Konec:
   FreeMem(P,65100);
   Close(InFile); DResult:=IOResult; Close(OutFile); DResult:=IOResult;
   CopyDir:=Result;
end;

{ ************************************************************************* }
begin
end.