unit VESA_EMM;
{$C FIXED PRELOAD PERMANENT}
interface

const IntNum = $7f;
var VRam:Word;
    StoredBanka:Byte;
    MaxResolution:Word;
    MaxResolutionHi:Word;

function InitG(X,Y,MaxX:Word):Word;
procedure CloseGraphics;
procedure vesa_emm_save;
procedure vesa_emm_load;

implementation
uses Dos, Crt;
label Konec;
var
    Pole:array[1..256] of Byte;
    VESAPresent:Boolean;
    Granularity,Segm,Offs, Pom:Word;
    Retezec:String;
    VRAMControl, InterruptVector:Pointer;
    CfgFile:File;

procedure IntStandardVGA; interrupt;
begin
end;

{ ***** }
procedure Int_64Kb_Granularity; interrupt; assembler;
{ Dx - nastavovana VRAM banka }
asm
   push Bx      { okno A }
   mov Bx,0
   xor Dh,Dh
   mov Ax,4f05h
   int 10h
   mov Bl,1     { okno B }
   mov Ax,4f05h
   int 10h
   pop Bx
end;

{ ***** }
procedure Int_xxKb_Granularity; interrupt; assembler;
{ Dx - aktualni VRAM banka }
asm
   push Bx
   mov Bx,0     { okno A }
   mov Ax,Granularity
   mul Dl
   mov Dx,Ax
   mov Ax,4f05h
   int 10h
   mov Bl,1     { okno B }
   mov Ax,4f05h
   int 10h
   pop Bx
end;

{ ***** }
procedure Int_64Kb_GranularityDir; interrupt; assembler;
{ Dx - nastavovana VRAM banka }
asm
   cli
   push Bx      { okno A }
   mov Bx,0
   xor Dh,Dh
   push Dx
   call [VRAMControl]
   pop Dx
   mov Bl,1     { okno B }
   call [VRAMControl]
   pop Bx
   sti
end;

{ ***** }
procedure Int_xxKb_GranularityDir; interrupt; assembler;
{ Dx - aktualni VRAM banka }
asm
   cli
   push Bx
   mov Bx,0     { okno A }
   mov Ax,Granularity
   mul Dl
   mov Dx,Ax
   push Dx
   call [VRAMControl]
   pop Dx
   mov Bl,1     { okno B }
   call [VRAMControl]
   pop Bx
   sti
end;

{ ***** }
procedure Int_Get_64Kb_Granularity; interrupt; assembler;
{ Dx - aktualni VRAM banka }
asm
   push Bx      { okno A }
   mov Bh,1
   mov Bl,0
   mov Ax,4f05h
   int 10h
   mov StoredBanka,Dl
   pop Bx
end;

{ ***** }
procedure Int_Get_xxKb_Granularity; interrupt; assembler;
{ Dx - nastavovana VRAM banka }
asm
   push Bx
   mov Bh,1
   mov Bl,0 { okno A }
   mov Ax,4f05h
   int 10h
   mov Ax,Dx
   mov Dx,Granularity
   div Dx
   mov Dx,Ax
   mov StoredBanka,Dl
   pop Bx
end;

{ ***** }
function InitG(X,Y,MaxX:Word):Word;
{ v X,Y jsou souradnice pozadovaneho rozliseni
  MaxX je skutecna X-ova delka
  Sama fce vraci 0, je-li vse v poradku
  _ || _  _ || _  1, nejde-li o adapter VESA (vyjma modu 320x200, 256 barev)
  _ || _  _ || _  2, pokud adapter VESA dane rozliseni nepodporuje
  _ || _  _ || _  3, pokud jde o jinou chybu
}
var GrMod:Word;
    Result:Word;
begin
   GetIntVec(IntNum,InterruptVector);
   InitG:=0;
   if X=320 then begin
      SetIntVec(IntNum,@IntStandardVGA); { standartni VGA 320x200 }
      asm
        mov Ax,4f02h      { inicializace grafickeho rezimu}
        mov Bx,13h
        int 10h
      end;
   end else begin
     if not VesaPresent then InitG:=1 { VESA neni k dispozici }
     else begin  { VESA je k dispozici }
      if (X=320) and (Y=400) then GrMod:=$0155
      else
        if (X=368) and (Y=240) then GrMod:=$0157
        else
          if (X=368) and (Y=400) then GrMod:=$0158
          else
            if (X=640) and (Y=350) then GrMod:=$011c
            else
               if (X=640) and (Y=400) then GrMod:=$100
               else
                 if (X=640) and (Y=480) then GrMod:=$101
                 else
                   if (X=800) and (Y=600) then GrMod:=$103
                   else
                     if (X=1024) and (Y=768) then GrMod:=$105
                     else
                       if (X=1280) and (Y=1024) then GrMod:=$107
                       else GrMod:=IntNum;  { nesmyslny gr. mod }
{        asm
           mov Result,0
           mov Ax,4f01h
           mov Cx,GrMod
           mov Bx,Segm
           mov Es,Bx
           mov Di,Offs
           int 10h
           cmp Al,4fh     { testovani uspesnosti inicializace gr. modu }
{           jne @notSuccesfull
           cmp Ah,0
           jne @notSuccesfull
           jmp @Succesfull
@notSuccesfull:
           mov Result,2
@Succesfull:
        end;{}
        Result:=0;
        if Result=0 then begin { inicializace byla uspesna }
           Result:=0; VRAMControl:=Nil;

           if (Granularity <> 64) then begin  { test na Granularity }
             Granularity:=64 div Granularity;
             SetIntVec(IntNum,@Int_xxKb_Granularity);
           end else
             SetIntVec(IntNum,@Int_64Kb_Granularity);

           asm
              mov Ax,4f02h   { inicializace grafickeho rezimu}
              mov Bx,GrMod
              add Bx,32768
              int 10h
           end;
           if (X<>MaxX) then begin
             asm               { nastaveni delky scanline }
                mov Ax,4f06h
                mov Bl,0
                mov Cx,MaxX
                int 10h
             end;
           end;

        end;
        if (Result = 3) then Result:=4;
        InitG:=Result;
     end;
   end;
end;

{ ***** }
procedure CloseGraphics;
{ ukonci graficky rezim
}
var I:Word;
begin
   SetIntVec(IntNum,InterruptVector);
   {asm
     mov Ax,3h
     Int 10h
   end;{}
   I:=IOResult;
   Writeln; TextMode(CO80);
end;

{ ***** }
procedure vesa_emm_save;
{ pro potreby ulozeni hry
}
begin
end;

{ ***** }
procedure vesa_emm_load;
{ pro potreby ulozeni hry
}
begin
end;

{ ************************************************************************** }
begin
   VesaPresent:=False;
   VRam:=SegA000;
   Segm:=Seg(Pole);
   Offs:=Ofs(Pole);

   Pom:=IOResult;
   Granularity:=64;
   Retezec:='vesa.cfg';
   Assign(CfgFile,Retezec);{}
   Reset(CfgFile,1); if (IOResult <> 0) then GoTo Konec;
   BlockRead(CfgFile,MaxResolution,2);
   if (IOResult <> 0) then begin
     MaxResolution:=0;
     Granularity:=64;
     GoTo Konec;
   end;
  { BlockRead(CfgFile,MaxResolutionHi,2);
   if (IOResult <> 0) then begin
     MaxResolution:=0;
     Granularity:=64;
     GoTo Konec;
   end;{}
   BlockRead(CfgFile,VesaPresent,1);
   if (IOResult <> 0) then begin
     VesaPresent:=False;
     Granularity:=64;
     GoTo Konec;
   end;
   BlockRead(CfgFile,Granularity,2);
   if (IOResult <> 0) then begin
     VesaPresent:=False;
     Granularity:=64;
     GoTo Konec;
   end;

   Close(CfgFile); Pom:=IOResult;
Konec:
end.