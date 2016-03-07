program temp;

uses Graph257, Crt, vesa_emm;

const MaxX = 640;
      MaxTextArray = 9;
      Ws : set of Byte = [$0d,$0a];

var I,J,X,Y,X2,Y2,K,S,O:Word;
    Data:array[0..MaxTextArray] of record
            Seg,Offs:Word;
         end;
    Color:Byte;
    Character:Char;
    MapTxtFile:File;
    MapTxtFileWay:String;

{ ****** }
procedure OpenMapTxtFile(Way:String);
{
}
begin
   MapTxtFileWay:=Way;
   Assign(MapTxtFile,MapTxtFileWay);
   Reset(MapTxtFile,1);
   IO_Result:=IOResult;
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
end;

{ ****** }
function ReadTxtString(var Ret:String):Boolean;
{
}
begin
  if (Eof(MapTxtFile)) then ReadTxtString:=False
  else begin
     Ret:='';
     while ((Ord(Character) in Ws) and (not CacheEof(MapTxtFile))) do begin
       BlockRead(MapTxtFile,Character,1); IO_Result:=IOResult;
       if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
     end;

     if (Eof(MapTxtFile)) then ReadTxtString:=False
     else begin
       repeat
         Ret:=Ret+Character;
         CacheBlockRead(MapTxtFile,Character,1); IO_Result:=IOResult;
         if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
       until ((Ord(Character) in Ws) or (CacheEof(MapTxtFile)));
     end;

     if (Eof(MapTxtFile)) then ReadTxtString:=False
     else ReadTxtString:=True;
  end;
end;

{ ****** }
procedure ReadTxtWord(var Num:Word);
{
}
begin
   Num:=0;
   while (not ((Character in ['0'..'9']) or (Eof(MapTxtFile)))) do begin
     BlockRead(MapTxtFile,Character,1); IO_Result:=IOResult;
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
   end;

   repeat
     Num:=Num*10+(Ord(Character)-Ord('0'));
     BlockRead(MapTxtFile,Character,1); IO_Result:=IOResult;
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
   until ((not (Character in ['0'..'9'])) or (Eof(MapTxtFile)));
end;

{ ***** }
procedure PrintMissionGoal(Way:String);
{ nahraje konfiguracni data
}
const YSpace = 2; XPlus = 50; YPlus = 100;
var Ret:String;
    I,J:Word;
    XP,YP,X,Y:Word;
    XOdsaz, YOdsaz, YButtonOdsaz:Word;
    Num,Scan,Ascii, Button:Word;
begin
   OpenMapTxtFile(Way);
   ReadTxtString(Ret); { prvni radek je komentar }
   ReadTxtString(Ret); { druhy radek je komentar }
   { nasleduji 2 wordy velikosti}
   ReadTxtWord(X); ReadTxtWord(Y);
   X:=X*XFontSize+XPlus; Y:=Y*(YFontSize+YSpace)+YPlus;
   CursorOff;{}

   I:=0;
   while ReadTxtString(Ret) do begin
      OutTextColor(XP+XOdsaz,YP+YOdsaz+I*(YFontSize+YSpace),65,Ret);{}
      Inc(I);
   end;{}

   I:=IOResult;
end;


{ ***** }
begin
   GraphInit(640,480,640,480);
   LoadRGB(0,'data\paleta1.rgb');{}
   if (not AllocateGlobalMemory(500000))
   then begin CloseGraph; Writeln('Nedostatek pameti'); Halt; end;
   ClearScreen;
   GetMemory(500000,S,O);
   if (S = 0) then begin CloseGraph; Writeln('Nedostatek pameti'); Halt; end;
   OpenImage('instal.bmp',NoCreateNew);
   if (IO_Result <> 0) then begin CloseGraph; Writeln('Chyba pri nahravani obrazku'); Halt; end;
   LoadImageBMP(S,O,RGB);
   if (IO_Result <> 0) then begin CloseGraph; Writeln('Chyba pri nahravani obrazku'); Halt; end;
   PutImage(0,0,S,O,ReverseDirect);
   PrintMissionGoal('missions\mapa0.inf');

   ReadKey;
end.
