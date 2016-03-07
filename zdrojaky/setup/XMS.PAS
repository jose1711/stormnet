{       SMIX is Copyright 1994 by Ethan Brodsky.  All rights reserved.       }
unit XMS;
  interface
   {Initialization}
    function XMSInstalled: boolean;
    procedure XMSInit;

   {Informational}
    function XMSGetVersion: word;
    function XMSGetFreeMem: word;

   {Allocation and deallocation}
    function XMSAllocate(var Segment,Offsets: word; var Uk:Pointer; Size: word): boolean;
    function GetDosMemory(var Segment,Offsets,Selector:Word; Size:Word):Pointer;
    function XMSFree(Handle: word): boolean;

  implementation  {ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}
    var
      XMSDriver: pointer;

{ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

    function XMSInstalled: boolean; assembler;
      asm
        mov    al, TRUE
      end;

{ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ}

    procedure XMSInit; assembler;
      asm
      end;

{ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

    function XMSGetVersion: word; assembler;
      asm
        mov Ax,0
      end;

{ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ}

    function XMSGetFreeMem: word; assembler;
      asm
        mov Ax,200
      end;

{ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

    function XMSAllocate(var Segment,Offsets: word; var Uk:Pointer; Size: word): boolean;
    begin
       GetMem(Uk,Size+16);
       if (Uk <> Nil) then begin
           XMSAllocate:=True;
           Segment:=Seg(Uk^);
           Offsets:=Ofs(Uk^);
       end else begin
           XMSAllocate:=False;
       end;
    end;

{ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ}

    function XMSFree(Handle: word): boolean; assembler;
      asm
         mov Al,True
      end;
{ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ}
   function GetDosMemory(var Segment,Offsets,Selector:Word; Size:Word):Pointer;
   { naalokuje v chranenem rezimu DOS pamet;
     vraci Nil pri neuspechu
   }
   var A,B,C:Word;
       Error:Boolean;
   begin
      Error:=False;
      Size:=Size shr 4; { paragraf = 16b }
      asm
        mov Ax,0100h
        mov Bx,Size
        int 31h
        jnc @OK
        { allocation Error }
        mov Al,True
        mov Error,Al
        jmp @end
@OK:
        mov A,Ax
        mov B,0
        mov C,Dx
@end:
      end;
      Segment:=A; Offsets:=B; Selector:=C;
      if (not Error) then
         GetDosMemory:=Ptr(Selector,0)
      else GetDosMemory:=Nil;
   end;

{ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ}

  end.  {ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ}3