program VesaTest;
uses CRT;
label Konec;
var
    Pole:array[1..256] of Byte;
    VESAPresent:Boolean;
    Granularity,Segm,Offs,S,O:Word;
    Retezec:String;
    VRAMControl, InterruptVector:Pointer;
    CfgFile:File;
    GrMod:Word;
    Result:Word;
    Uk:PChar;
    Memory:Word;

begin
   TextColor(15); TextBackGround(0); S:=Seg(Uk); O:=Ofs(Uk);
   VesaPresent:=True;
   Assign(CfgFile,'vesa.$$$');
   ReWrite(CfgFile,1);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     GoTo Konec;
   end;

   asm  { volani fce 0 .. vraci informace o SVGA adapteru }
     mov Ah,4fh
     mov Al,0h
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     Int 10h

     cmp Al,4fh     { testovani pritomnosti VESy }
     jne @notPresent
     cmp Ah,0
     jne @notPresent
     { ukazatel na OEM retezec }
     mov Bx,seg Pole
     mov Si,offset Pole
     mov Di,O
     mov Ax,S
     mov Es,Ax
     push Ds
     mov Ds,Bx
     add Si,6
     cld
     movsw
     movsw
     pop Ds

     jmp @End
@notPresent:
     mov VesaPresent,0
@End:
   end;
   { testovani pritomnosti VESy }
   if not (Chr(Pole[1])='V') then VesaPresent:=False;
   if not (Chr(Pole[2])='E') then VesaPresent:=False;
   if not (Chr(Pole[3])='S') then VesaPresent:=False;
   if not (Chr(Pole[4])='A') then VesaPresent:=False;
   Memory:=Word(Pole[20])*256+Pole[19];
   if (VesaPresent) then begin
     Result:=1;
   end else Result:=0;

   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;
   BlockWrite(CfgFile,Memory,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;
   BlockWrite(CfgFile,Uk^,80);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;
   BlockWrite(CfgFile,Pole[6],1);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;
   BlockWrite(CfgFile,Pole[5],1);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;

   { 640x480, 256 barev }
   GrMod:=$101; { 640x480, 256 barev }
   S:=Seg(Uk); O:=Ofs(Uk); Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
   asm
     mov Ax,Es:[Di+4]
     mov Granularity,Ax
     { zjisteni adresy prime funkce nastaveni videobanky }
     les Di,Es:[Di+12]
     cmp Di,0
     jne @OK
     mov Ax,Es
     cmp Ax,0
     jne @OK
     { neuspesne zjistena adresa }
     mov Result,1

@OK:  { uspesne zjistena adresa }
     mov word ptr [VRAMControl],Di
     mov word ptr [VRAMControl+2],Es
   end;
   BlockWrite(CfgFile,Granularity,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;

   { 640x480, HICOLOR }
   GrMod:=$110; { 640x480, HICOLOR }
   S:=Seg(Uk); O:=Ofs(Uk); Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
   asm
     mov Ax,Es:[Di+4]
     mov Granularity,Ax
     { zjisteni adresy prime funkce nastaveni videobanky }
     les Di,Es:[Di+12]
     cmp Di,0
     jne @OK
     mov Ax,Es
     cmp Ax,0
     jne @OK
     { neuspesne zjistena adresa }
     mov Result,1

@OK:  { uspesne zjistena adresa }
     mov word ptr [VRAMControl],Di
     mov word ptr [VRAMControl+2],Es
   end;
   BlockWrite(CfgFile,Granularity,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;


   { 800x600, 256 barev }
   GrMod:=$103; { 800x600, 256 barev }
   S:=Seg(Uk); O:=Ofs(Uk);  Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;

   { 800x600, HICOLOR }
   GrMod:=$113; { 800x600, HICOLOR }
   S:=Seg(Uk); O:=Ofs(Uk);  Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;


   { 1024x768, 256 barev }
   GrMod:=$105; { 1024x768, 256 barev }
   S:=Seg(Uk); O:=Ofs(Uk);  Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;

   { 1024x768, HICOLOR }
   GrMod:=$105; { 1024x768, HICOLOR }
   S:=Seg(Uk); O:=Ofs(Uk);  Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;


   { 1200x1024, 256 barev }
   GrMod:=$107; { 1200x1024, 256 barev }
   S:=Seg(Uk); O:=Ofs(Uk);  Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;

   { 1200x1024, HICOLOR }
   GrMod:=$107; { 1200x1024, HICOLOR }
   S:=Seg(Uk); O:=Ofs(Uk);  Result:=0;
   asm
     mov Ax,4f01h
     mov Cx,GrMod
     mov Bx,seg Pole
     mov Es,Bx
     mov Di,offset Pole
     int 10h
     cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
     jne @notSuccesfull
     cmp Ah,0
     jne @notSuccesfull
     jmp @Succesfull
@notSuccesfull:
     mov Result,2
@Succesfull:
   end;
   if Result=0 then { inicializace byla uspesna }
     Result:=1
   else Result:=0;
   BlockWrite(CfgFile,Result,2);
   if (IOResult <> 0) then begin
     Writeln('Chyba pri zapisu souboru vesa.$$$ !');
     Halt(0);
   end;

   Close(CfgFile);
Konec:
end.