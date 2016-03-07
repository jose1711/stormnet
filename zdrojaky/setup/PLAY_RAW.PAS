program play_raw;
uses Crt,Dos,Detect,Raw_test;
var R1,R2:String;
begin
   if (ParamCount = 1) then begin
     if (SoundTest(R1,R2)) then begin
        if (TestingSound) then
        else Writeln('CHYBA !');
     end else Writeln('CHYBA - '+R1+R2);
   end else begin
     Writeln('Pouziti: play_raw  sound.raw');
   end;
end.