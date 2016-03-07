program readme;
uses Crt;
begin
   ClrScr;
   GoToXY(25,1);
   TExtColor(YELLOW); Write('STORMNET VYVOJOVA DEMOVERZE');
   GoToXY(1,4);
   TExtColor(White);
   Writeln('    V teto demo verzi budete mit k dispozici nekolik jednotlivych misi a');
   Writeln('3-4 uvodni mise  kampane. V plne  verzi vas ceka  temer 30 misi kampane.');
   Writeln('Popis ovladani a vsechno potrebne naleznete v souboru: ');
   TextColor(LightBlue);
   Writeln('dokumenty\manual.doc.');
   TextColor(White);
   GoToXY(30,10);
   TExtColor(LightGray+Blink);
   Write('stisknete klavesu');
   Delay(1000);
   ReadKey;
end.