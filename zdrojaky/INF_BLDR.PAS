
program info_o_jednotkach_a_budovach;
uses crt;
var c: char;
    f,g: text;
    i:integer;
    IO_Result:Byte;
    nazev : string;

function Male2Velke(ch:char):char;
begin
  if (ch>='a') and (ch<='z') then ch:=chr(ord(ch)-32) else
  case ch of
   ' ': ch:='a';
   'Ÿ': ch:='b';
   '‚': ch:='c';
   'Ø': ch:='d';
   '¡': ch:='e';
   'ı': ch:='f';
   'ç': ch:='g';
   '£': ch:='h';
   '…': ch:='i';
   'ì': ch:='j';
   '§': ch:='k';
  end;
  Male2Velke:=ch;
end;

function Int2Str(I: integer): String;
var
 S: string;
begin
 Str(I, S);
 Int2Str := S;
end;
{jednotky}
begin
  IO_Result:=0;
  for i := 1 to 41 do begin
    assign(f,Int2Str(i)+'.txt');
    reset(f);
    if IOResult=2 then IO_Result:=255 else IO_Result:=0;
    if IO_Result = 0 then begin
      assign(g,Int2Str(i)+'.txx');
      rewrite(g);
      while not eof(f) do begin
        read(f,c);
        write(g,Male2Velke(c));
      end;
      close(g);
    end else IO_Result:=0;
    close(f);
  end;
{budovy}
  for i := 1 to 25 do begin
    assign(f,'b'+Int2Str(i)+'.txt');
    reset(f);
    if IOResult=2 then IO_Result:=255 else IO_Result:=0;
    if IO_Result = 0 then begin
      assign(g,'b'+Int2Str(i)+'.txx');
      rewrite(g);
      while not eof(f) do begin
        read(f,c);
        write(g,Male2Velke(c));
      end;
      close(g);
    end else IO_Result:=0;
    close(f);
  end;

end.