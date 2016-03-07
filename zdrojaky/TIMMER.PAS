{$M 1024,0,0}
program Timmer;

uses Dos;
var Flag:Byte;

procedure SetTimmer; interrupt; assembler;
asm
  { Bx = 0..setup else waiting
    Cx,Dx ..interval
  }
  mov Ax,Bx
  cmp Al,0
  je @Set_up
{ pouze cekame na uplynuti intervalu }
@again:
  sti
  mov Al,Flag
  cmp Al,0
  je @again
  jmp @end
@Set_up:
{ nastavujeme casovac }
  mov Flag,0
  mov Al,1
  mov Ah,83h
  int 15h
  {}
  mov Ah,83h
  mov Al,0
  mov Flag,Al
  mov Bx,Seg Flag
  mov Es,Bx
  mov Bx,Offset Flag
  int 15h
@end:
end;

{ xxxx }
begin
   SetIntVec($7e,@SetTimmer);
   Flag:=0;
   Keep(0);
end.