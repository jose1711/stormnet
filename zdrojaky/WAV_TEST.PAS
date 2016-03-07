program MixTest;
  uses SBSound,Crt;
  var
    i: byte;
    Pomocna,A,B,C:Word;
    Stop:Boolean;
    Counter:Word;

{ ***** }
  begin
    {SetSoundVariables(5,False);{}
    Writeln('Volna pamet: ',MemAvail);
    Init;
    Writeln('Volna pamet: ',MemAvail);

    writeln('Press:');
    writeln('number between 0-11, 0-2, 0-1 = messages');
    writeln('number between 500-',507,' = gun sounds');
    writeln('number between 600-',610,' = system messages');
    writeln('number between 700-',707,' = explosion sounds');
    writeln('number between 800-',802,' = explosion sounds of buildings');
    writeln('1000  Quit');
    Stop := false;
    Counter := 0;

    repeat
     {Start a sound if a key is pressed}
      if KeyPressed then begin
         Readln(Pomocna,A,B);
         case (Pomocna) of
           0..10 : begin
                     if (B = 0) then { lide }
                       PlaySound(0,0,Pomocna,A)
                     else PlaySound(1,0,Pomocna,A);
                     writeln('Press:');
                     writeln('number between 0-11, 0-2, 0-1 = messages');
                     writeln('number between 500-',507,' = gun sounds');
                     writeln('number between 600-',610,' = system messages');
                     writeln('number between 700-',707,' = explosion sounds');
                     writeln('number between 800-',802,' = explosion sounds of buildings');
                     writeln('1000  Quit');
                  end;
           500..507 : PlaySound(2,0,Pomocna-500,0);
           600..610 : PlaySound(5,0,Pomocna-600,0); { sysound!! }
           700..707 : PlaySound(3,0,Pomocna-700,0);
           800..802 : PlaySound(4,0,Pomocna-800,0);
           1000   : Stop:=True;
         end;
      end;
    until Stop;

    Shutdown;
  end.
