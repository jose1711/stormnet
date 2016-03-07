program temp;

uses Graph257, Data, Crt;

var N1,N2,X,I,J,K,S,O,S2,O2:Word;
    Pom:array[0..5] of Integer;
    Ret:String;
{ ***** }
begin
   if (ParamCount <> 2) then begin
     Writeln('Pouziti RENUM X Y  (pouze pro soubor bck, ktery musi byt v adresari!)');
     Writeln('Kde:');
     Writeln('X je puvodni cislo');
     Writeln('Y je nove cislo');
     Writeln('pr. RENUM 2 15');
     Writeln('Cislo 1 a 16..255 ponecha');
     Writeln('Cisla 3..15 posune o pozici vlevo (na 2..14)');
     Writeln('Cislo 2 prejmenuje na 15');
     Halt;
   end else begin
     Val(ParamStr(1),N1,X); if (X <> 0) then begin Writeln('chyba v ciselnem formatu parametru'); Halt; end;
     Val(ParamStr(2),N2,X); if (X <> 0) then begin Writeln('chyba v ciselnem formatu parametru'); Halt; end;

     GraphInit(320,200,320,200);
     LoadRGB(0,'Paleta1.rgb');
     OpenImage('bck',NoCreateNew);
     GetMemory(2000,S,O); GetMemory(2000,S2,O2);
     for I:=0 to 255 do begin
       Str(I,Ret); J:=I; if (J > 0) then Dec(J);
       if ((I < N1) or (I > N2)) then begin
       { nic se nedeje }
          LoadImageGBM(S,O,Ret,0);
          SaveImageGBM(S,O,Ret);
       end else
         if (I = N1) then LoadImageGBM(S2,O2,Ret,0)
         else begin
         { posun vlevo }
           LoadImageGBM(S,O,Ret,0);
           Str(J,Ret);
           SaveImageGBM(S,O,Ret);
           if (I = N2) then begin
           { ulozeni N1 }
             Str(I,Ret);
             SaveImageGBM(S2,O2,Ret);
           end;
         end;
       ColorPixel(I,10,15);
     end;{}
   end;

   ReadKey;
end.
