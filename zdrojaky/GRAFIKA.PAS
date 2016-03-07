{ V PROCEDURE REAL_DRAW2 JE ODKAZ NA SIRKU OBRAZKU AKTIVNI OBRANY PRIMO
  CISLEM ! (12)
}
unit Grafika;
{$C FIXED PRELOAD PERMANENT}
interface
uses Graph257, Mouse, Data, Crt;

type TGraphArray = array[0..IMaxSize+1,0..JMaxSize+1] of record
                     Draw_second:Boolean; { True, ma-li se v danem poli
                     vykreslit nejhorejsi 2.uroven objektu do pameti }
                     Draw:Boolean; { True, ma-li se dane pole transferovat
                     na obrazovku }
                   end;
     TGraphQueue = object
                  private
                    Q:^TGraphArray;
                  public
                  { zarazovani pozadavku do fronty }
                  procedure Insert(I,J,I2,J2:Word; Typ:Word);
                  procedure Work; { vlozeni dat do pameti }
                  procedure Transfer; { presun na obrazovku }
                  constructor Initialize; { inicilaizace }
                  procedure Clear; { cisti pole }
              end;

var GraphQueue:TGraphQueue;

procedure SetAnimCursorType(CursorType:Word);
procedure SetCursor(CursorType:Word);
procedure CursorManager;
procedure Draw_place(IPos,JPos:Word);
procedure Draw_map_frame(I1,I2,J1,J2:Word);
procedure Draw_screen(I,J,XOffset,YOffset:Word);
procedure DrawSpecStatusBar(X,Y,XSize,Damage,DefenceStrength:Word; Core:Boolean; Color:Byte);
procedure Draw_flash(X,Y,S,O:Word);
procedure DrawBck(I,J,I2,J2:Word; Draw2:Boolean);
procedure Transfer_map_frame(I,J,I2,J2:Word);
procedure Draw_unit(_unit:PUnit);
procedure Erase_unit(_unit:PUnit; Draw : Boolean);
procedure ReDraw_unit(_unit:PUnit; Draw : Boolean);
procedure Redraw_unit_with_flash(_unit:PUnit; XX,YY,S,O:Word);
procedure Draw_shot(Shot:PShots);
procedure Erase_shot(Shot:PShots; Draw:Boolean);
procedure Draw_explosion_shot(Shot:PShots);
procedure Draw_building(Building:PBuilding);
procedure Erase_building(Building:PBuilding);
procedure ReDraw_building(Building:PBuilding; Draw:Boolean);
procedure Force_draw_unit(_unit:PUnit);
procedure Force_erase_unit(_unit:PUnit);
procedure Force_redraw_unit(_unit:PUnit);
procedure Grafika_save;
procedure Grafika_load;

{ xxx } procedure Altpress; { * ZRUSIT * }

implementation
uses _Shot, _units, _units2, Grafika2, Grafika3;

const OvrSize = 6;
      FrameAdd = 1;

var XWin1,YWin1,XWin2,YWin2:Word; { skutecne souradnice pozadovaneho vyrezu }
    WindowActivity:Boolean; { je nejaky vyrez aktivni ?- pro kresleni
    okoli jednotky }
    XMouse,YMouse:Word;
    Temporary:Word; { pomocna }

{ +++++ }
procedure TransferX(I,J:Word); forward;
procedure Real_draw_bullet(X,Y:Word; Direction, AttackPicture, Phase:Byte); forward;
procedure DrawFlyingObjects(I,J:Word); forward;

{ +++++ }
constructor TGraphQueue.Initialize;
{}
var I,J:Word;
begin
   New(Q);
   for I:=0 to IMaxSize do
     for J:=0 to JMaxSize do with (GraphQueue.Q^[I,J]) do begin
        Draw_second:=False; Draw:=False;
     end;
end;

{ +++++ }
procedure TGraphQueue.Clear;
{}
var I,J:Word;
begin
 for I:=0 to IMaxSize do
   for J:=0 to JMaxSize do with (GraphQueue.Q^[I,J]) do begin
      Draw_second:=False; Draw:=False;
   end;
end;

{ +++++ }
procedure TGraphQueue.Insert(I,J,I2,J2:Word; Typ:Word);
{ vlozi do fronty prvek; Typ udava typ prispevku:
  0 .. tyka se nejhorejsi druhe urovne (letouny, strely)
  1 .. pro transfer pole na obrazovku
}
var K,L:Word;
begin
   save1:=666;
   case (Typ) of
      0 : for K:=I to I2 do
            for L:=J to J2 do
              if ((K <= (IBeg+IScreenSize+1)) and ((K+1) >= IBeg) and
                  (L <= (JBeg+JScreenSize+1)) and ((L+1) >= JBeg))
              then begin
                Q^[K,L].Draw_second:=True; { je to na obrazovce }
                Q^[K,L].Draw:=True; { soucasne vykresli }
              end;
      1 : for K:=I to I2 do
            for L:=J to J2 do
              if ((K <= (IBeg+IScreenSize)) and (K >= IBeg) and
                  (L <= (JBeg+JScreenSize)) and (L >= JBeg))
              then Q^[K,L].Draw:=True;
   end;
end;

{ +++++ }
procedure TGraphQueue.Work;
{ zpracuje udaje ve fronte
}
var ISize, JSize, XSize, YSize, I, J, K ,L ,I2 ,J2 ,X ,Y:Word;
begin
   { * nejprve strely 1. urovne * }
   I:=1; J:=1;
   while ((I <= Number_of_shots) and (J <= MaxMovingObjects)) do begin
    if ((Shots[J] <> Nil) and (Shots[J]^.First > 1)) then with Shots[J]^ do begin
      if (TargetMovementLevel = 0) then begin
         { vloz tento bod na vykresleni }
         I2:=IPos; J2:=JPos;
         if ((XPos+XMaxShot) shr XCellShl <> IPos) then Inc(I2);
         if ((YPos+YMaxShot) shr YCellShl <> JPos) then Inc(J2);
         GraphQueue.Insert(IPos,JPos,I2,J2,1);
         {x test na vykresleni x}
         if ((MapBckTemp^[IPos,JPos].Visibilit and Races[MyRace].VisMask = 0) and
             (Visibility)) then Visibility:=False;
         ISize:=1; JSize:=1;
         if (AttackLevel > 4) then begin
            XSize:=Explosions[AttackPicture].XShot; YSize:=Explosions[AttackPicture].YShot;
         end else begin
            XSize:=XMaxShot; YSize:=YMaxShot;
         end;
         X:=XPos; Y:=YPos; XOffset:=X mod XCellSize; YOffset:=Y mod YCellSize;
         if ((XOffset + XSize) > XCellSize) then Inc(ISize);
         if ((YOffset + YSize) > YCellSize) then Inc(JSize); {}
         if (Visibility and (AttackLevel > 0) and
             (IPos < (IBeg+IScreenSize)) and (JPos < (JBeg+JScreenSize)) and
             ((IPos+ISize) > IBeg) and ((JPos+JSize) > JBeg)) then begin
         { pokud vykreslovany objekt lezi na obrazovce, delej :}
           X:=(XPos+XMemBeg)-IBeg shl XCellShl;
           Y:=(YPos+YMemBeg)-JBeg shl YCellShl;
           if ((AttackLevel > 0) and Visibility) then begin
           { nejde o strelu od pechoty nebo spec. zbrani }
             if (Status = 0) then
               { if (WindowActivity) then
                   Real_draw_bullet2(XPos,YPos,Direction,AttackPicture,Phase)
                else{}
                Real_draw_bullet(XPos,YPos,Direction,AttackPicture,Phase)
             else begin
                {if (not WindowActivity) then{}
                SpeedPutImage2Mem(X,Y,S,O);
             end;
           end; { vykresleni }
         end;
      end;
      Inc(I);
    end; { strela na danem indexu existuje }
    Inc(J);
   end;

   { * nyni letouny * }
   if (IBeg > 0) then K:=IBeg-1 else K:=IBeg;
   if (JBeg > 0) then L:=JBeg-1 else L:=JBeg;
   for I:=K to IBeg + IScreenSize + 1 do
     for J:=L to JBeg + JScreenSize + 1 do with (Q^[I,J]) do begin
        if (Draw_second) then begin  { prenest tuto cast na obrazovku }
           Draw_second:=False;
           DrawFlyingObjects(I,J);
        end;
     end;

   { * ... a strely 2. urovne * }
   I:=1; J:=1;
   while ((I <= Number_of_shots) and (J <= MaxMovingObjects)) do begin
    if (Shots[J] <> Nil) then with Shots[J]^ do begin
      if (TargetMovementLevel = 1) then begin
         { vloz tento bod na vykresleni }
         I2:=IPos; J2:=JPos;
         if ((XPos+XMaxShot) shr XCellShl <> IPos) then Inc(I2);
         if ((YPos+YMaxShot) shr YCellShl <> JPos) then Inc(J2);
         GraphQueue.Insert(IPos,JPos,I2,J2,1);
         {x test na vykresleni x}
         if ((MapBckTemp^[IPos,JPos].Visibilit and Races[MyRace].VisMask  = 0) and (Visibility)) then Visibility:=False;
         ISize:=1; JSize:=1;
         if (AttackLevel > 4) then begin
            XSize:=Explosions[AttackPicture].XShot; YSize:=Explosions[AttackPicture].YShot;
         end else begin
            XSize:=XMaxShot; YSize:=YMaxShot;
         end;
         X:=XPos; Y:=YPos; XOffset:=X mod XCellSize; YOffset:=Y mod YCellSize;
         if ((XOffset + XSize) > XCellSize) then Inc(ISize);
         if ((YOffset + YSize) > YCellSize) then Inc(JSize); {}
         if (Visibility and (AttackLevel > 0) and
             (IPos < (IBeg+IScreenSize)) and (JPos < (JBeg+JScreenSize)) and
             ((IPos+ISize) > IBeg) and ((JPos+JSize) > JBeg)) then begin
         { pokud vykreslovany objekt lezi na obrazovce, delej :}
           X:=(XPos+XMemBeg)-IBeg shl XCellShl;
           Y:=(YPos+YMemBeg)-JBeg shl YCellShl;
           if ((AttackLevel > 0) and Visibility) then begin
           { nejde o strelu od pechoty nebo spec. zbrani }
             if (Status = 0) then
               { if (WindowActivity) then
                   Real_draw_bullet2(XPos,YPos,Direction,AttackPicture,Phase)
                else{}
                   Real_draw_bullet(XPos,YPos,Direction,AttackPicture,Phase)
             else begin
                {if (not WindowActivity) then{}
                SpeedPutImage2Mem(X,Y,S,O);
             end;
           end; { vykresleni }
         end;
      end;
      Inc(I);
    end; { strela na danem indexu existuje }
    Inc(J);
   end; { while }
end;

{ +++++ }
procedure TGraphQueue.Transfer;
{ zpracuje udaje ve fronte
}
var ISize, JSize, XSize, YSize, I,J,I2,J2,X,Y:Word;
begin
   { * nyni prenos na obrazovku * }
   for J:=JBeg to JBeg+JScreenSize do
     for I:=IBeg to IBeg+IScreenSize do with (Q^[I,J]) do begin
        if Draw then begin  { prenest tuto cast na obrazovku }
           Draw:=False;
           TransferX(I,J);
        end;
     end;
end;

{ ***** }
procedure SetAnimCursorType(CursorType:Word);
{
}
var Pom, Load:Boolean;
    K,I,J,Pomocna:Word;
    Id:Byte;
begin
   bebex:=20000; bebey:=CursorType;
   case (CursorType) of
      AttackCursor : if ((ActiveGroup >= 254) or
                         (Groups[ActiveGroup].ClickStatus >= 254))
                     then CursorType:=NormalCursor
                     else begin
                        I:=Mouse.XMouse; J:=Mouse.YMouse;
                        Dec(I,XScreenBeg); I:=I shr XCellShl+IBeg;
                        Dec(J,YScreenBeg); J:=J shr YCellShl+JBeg;
                        bebex:=20001;
                        if (not Prepare_attack_group2(I,J,8,MyRace,ClickLevel))
                        then begin
                          CursorType:=NormalCursor; CursorPhase:=0;
                        end;
                     end;
      MoveCursor : if ((ActiveGroup >= 254) or
                       (Groups[ActiveGroup].Building <> Nil) or
                       (Groups[ActiveGroup].ClickStatus >= 254))
                   then begin
                      CursorType:=NormalCursor; CursorPhase:=0;
                   end else begin
                   { POKUS O PRESUN }
                       Pom:=True;
                       I:=Mouse.XMouse; J:=Mouse.YMouse;
                       Dec(I,XScreenBeg); I:=I shr XCellShl+IBeg;
                       Dec(J,YScreenBeg); J:=J shr YCellShl+JBeg;
                       if ((I < 0) or (J < 0) or (I > IMax) or (J > JMax))
                       then begin
                          CursorType:=NormalCursor; CursorPhase:=0;
                       end else with (Groups[ActiveGroup]) do begin
                          for K:=0 to MaxGroupUnits-1 do
                            if (Un[K] <> Nil) then with (Un[K]^) do begin
                            { testuje dostupnost cile pro vsechny jednotky }
                               Pom:=Pom and Free_place_three(I,J,
                                            Unit_types[UnitType,Races[Race].Ally].IUnitSize,
                                            Unit_types[UnitType,Races[Race].Ally].JUnitSize,
                                            ClickLevel,Un[K]) and (not Un[K]^.Return_to_base);
                               { pozemni nemohou na vzdusnou uroven }
                               if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel <> 3) and
                                   (ClickLevel <> 0)) then Pom:=False;
                               { letadla nemohou na zem }
                               if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                                   (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) and
                                   (ClickLevel = 0)) then Pom:=False;

                             end;
                          {if (MapBckTemp^[I,J].Visibilit = 0) then Pom:=False;{}
                          if (Pom) then begin
                          { OK, cil je dostupny pro vsechny}
                          end else begin
                            CursorType:=NormalCursor; CursorPhase:=0;
                          end;
                       end;
                   end;
      GoInsideCursor : if (ActiveGroup >= 254) then CursorType:=NormalCursor;
      GroupingCursor : begin
                         I:=Mouse.XMouse; J:=Mouse.YMouse;
                         Dec(I,XScreenBeg); I:=I shr XCellShl+IBeg;
                         Dec(J,YScreenBeg); J:=J shr YCellShl+JBeg;
                         if ((ActiveGroup < 254) and
                             (Groups[ActiveGroup].ClickStatus = 2))
                         then begin
                           if ((Map^[I,J].First_level <> 0) and
                               (Map^[I,J].Level_type and 128 <> 128))
                           then with (Units[Map^[I,J].First_level]^) do
                           with (Groups[ActiveGroup]) do begin
                               Id:=255; Pomocna:=0;
                               for K:=0 to MaxGroupUnits-1 do begin
                               { zjisti naroky jednotek na misto }
                                 if (Un[K] <> NIL) then begin
                                   Inc(Pomocna,Unit_types[Un[K]^.UnitType,Races[Un[K]^.Race].Ally].NeedPlace);
                                   if ((Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                                       (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0) and
                                       (Un[K]^.UnitType <> 7) and (Un[K]^.UnitType <> 9) and
                                       (Un[K]^.UnitType <> 15))
                                   then Inc(Pomocna,255); { do vysadkovych letadel
                                   lze nalozit jen vysadkare - u ostatnich jednotek
                                   umele zvys jejich naroky na misto a tak zabran
                                   nalozeni }
                                   if ((Unit_types[UnitType,Races[Race].Ally].TargetTyp < 3) and
                                       (Un[K]^.TargetType > 1))
                                   then Inc(Pomocna,255);
                                   { do pozemnich vozidel nelze nalozit tezkou
                                     jednotku }
                                   if (Id = 255) then Id:=Unit_types[UnitType,Races[Race].Ally].TargetTyp;
                                 end;
                               end;
                               if (((Pomocna+UnitsInsidePlace) <= Unit_types[UnitType,Races[Race].Ally].Capacity) and
                                   (UnitsInsideNum < (MaxGroupUnits-1))) then
                               begin  { LZE NALOZIT!! }
                                 CursorType:=LoadCursor;
                               end;
                           end;
                         end;
                       end;
   end;
   if (AnimCursorType <> CursorType) then CursorPhase:=0;
   AnimCursorType:=CursorType;
end;

{ ***** }
procedure SetCursor(CursorType:Word);
{ procedura nastavi kurzor mysi do zadaneho tvaru;
  lze pouzit tyto konstanty :
  WaitCursor   .. nastavi presypaci hodiny
  NormalNormalCursor .. nastavi klasickou sipku
  GroupingCursor .. nastavi maly obdelnicek pro grupovani shift+left button
  OkCursor .. nastavi "fajfku"
  NoCursor .. nastavi znacku zakaz vjezdu
  GoInsideCursor .. nastavi kurzor "nalozit"
  NormalCursor .. nastavi dle promenne ClickLevel bud sipku urovne 1
  nebo urovne 2
}
begin
 LastCursor:=PomCursor;
 ActuallCursor:=CursorType;
 if (AnimatedCursor = 0) then CursorOff;
   case CursorType of
     WaitCursor     : begin
                        if (AnimatedCursor = 0) then
                          SetCursorPicture(Cursors[WaitCursor].Mem[0].S,Cursors[WaitCursor].Mem[0].O)
                        else begin
                          CursorOff;
                          SetCursorPicture(Cursors[WaitCursor].Mem[0].S,Cursors[WaitCursor].Mem[0].O);
                          SetCursorSize(XCursorSize-1,YCursorSize-1);
                          CursorOn;
                        end;
                      end;
     GroupingCursor : begin
                        if (ActiveGroup < 254) then
                        with (Groups[ActiveGroup]) do begin
                          if (ClickStatus = 2) then ClickStatus:=1;
                        end;
                        if ((ActiveGroup <= MaxGroups) and
                            (Groups[ActiveGroup].ClickStatus = 2)) then
                           Groups[ActiveGroup].ClickStatus:=1;
                        if (LastCursor = GoInsideCursor) then
                           LastCursor:=NormalCursor;
                        if (AnimatedCursor = 0) then begin
                          if (ClickLevel = 0) then { 1. uroven }
                             SetCursorPicture(Cursors[NormalCursor].Mem[0].S,Cursors[NormalCursor].Mem[0].O)
                          else
                             SetCursorPicture(Cursors[NormalCursor].Mem2[0].S,Cursors[NormalCursor].Mem2[0].O);
                        end;
                        PomCursor:=CursorType;
                      end;
     NoCursor       : begin
                         if (AnimatedCursor = 0) then
                            SetCursorPicture(Cursors[NoCursor].Mem[0].S,Cursors[NoCursor].Mem[0].O);
                      end;
     GoInsideCursor : begin
                        if (AnimatedCursor = 0) then
                           SetCursorPicture(Cursors[GoInsideCursor].Mem[0].S,Cursors[GoInsideCursor].Mem[0].O);
                        PomCursor:=NormalCursor;
                      end;
     NormalCursor   : begin
                        if (ActiveGroup < 254) then
                          with (Groups[ActiveGroup]) do begin
                            if (ClickStatus = 2) then ClickStatus:=1;
                          end;
                        if (WayPointDef = 0) then begin
                           if (AnimatedCursor = 0) then
                              if (ClickLevel = 0) then { 1. uroven }
                                SetCursorPicture(Cursors[NormalCursor].Mem[0].S,Cursors[NormalCursor].Mem[0].O)
                              else
                                SetCursorPicture(Cursors[NormalCursor].Mem2[0].S,Cursors[NormalCursor].Mem2[0].O);
                        end else begin
                           if (AnimatedCursor = 0) then
                              if (ClickLevel = 0) then { 1. uroven }
                                SetCursorPicture(Cursors[WayPointRecCursor].Mem[0].S,Cursors[WayPointRecCursor].Mem[0].O)
                              else
                                SetCursorPicture(Cursors[WayPointRecCursor].Mem2[0].S,Cursors[WayPointRecCursor].Mem2[0].O);
                        end;
                        PomCursor:=CursorType;
                      end;
     AttackCursor   : begin
                        {if (AnimatedCursor = 0) then
                            SetCursorPicture(SegAttackCursor,OffsAttackCursor);
                        if ((ActiveGroup <= MaxGroups) and
                            (Groups[ActiveGroup].ClickStatus = 2)) then
                           Groups[ActiveGroup].ClickStatus:=1;
                        if (LastCursor = GoInsideCursor) then
                           LastCursor:=NormalCursor;{}
                      end;
     NoAttackCursor : begin
                        if (AnimatedCursor = 0) then
                          SetCursorPicture(Cursors[NoAttackCursor].Mem[0].S,Cursors[NoAttackCursor].Mem[0].O);
                        if ((ActiveGroup <= MaxGroups) and
                            (Groups[ActiveGroup].ClickStatus = 2)) then
                           Groups[ActiveGroup].ClickStatus:=1;
                        if (LastCursor = GoInsideCursor) then
                           LastCursor:=NormalCursor;
                      end;
   else
     Error(0, 'pokus nastavit chybny tvar kurzoru mysi');
   end;
   if (AnimatedCursor = 0) then begin
     SetCursorSize(XCursorSize-1,YCursorSize-1);
     CursorOn;
   end;
end;

{ ***** }
procedure CursorManager;
{
}
var I,J:Integer;
    LastVisibility:Word;
begin
   LastVisibility:=CursorVisibility;
   BlockMouse:=True; CursorVisibility:=0;

   if (Grouping) then AnimCursorType:=GroupingCursor;
   if (WayPointDef > 0) then begin
     AnimCursorType:=WayPointRecCursor;
   end;
   case (AnimCursorType) of
     GoInsideCursor : begin
                         if (CursorPhase > Cursors[GoInsideCursor].MaxPhase) then
                            CursorPhase:=0;
                         SetCursorPicture(Cursors[GoInsideCursor].Mem[CursorPhase].S,
                                          Cursors[GoInsideCursor].Mem[CursorPhase].O);
                         Inc(CursorPhase);
                         if (CursorPhase > Cursors[GoInsideCursor].MaxPhase) then
                            CursorPhase:=0;
                      end;
     AttackCursor   : begin
                         I:=Mouse.XMouse; J:=Mouse.YMouse;
                         Dec(I,XScreenBeg); I:=I shr XCellShl+IBeg;
                         Dec(J,YScreenBeg); J:=J shr YCellShl+JBeg;

                         if ((I < 0) or (J < 0) or (I > IMax) or (J > JMax) or
                             (ClickLevel = 0) and (Map^[I,J].First_level = 0) or
                             (ClickLevel = 1) and (Map^[I,J].Second_level = 0))
                         then begin
                            AnimCursorType:=NormalCursor;
                            SetAnimCursorType(MoveCursor);
                         end else begin
                            if (CursorPhase > Cursors[AttackCursor].MaxPhase) then
                               CursorPhase:=0;
                            if (ClickLevel = 0) then { 1. uroven }
                              SetCursorPicture(Cursors[AttackCursor].Mem[CursorPhase].S,
                                               Cursors[AttackCursor].Mem[CursorPhase].O)
                            else
                              SetCursorPicture(Cursors[AttackCursor].Mem2[CursorPhase].S,
                                               Cursors[AttackCursor].Mem2[CursorPhase].O);
                            Inc(CursorPhase);
                            if (CursorPhase > Cursors[AttackCursor].MaxPhase) then
                               CursorPhase:=0;
                         end;
                      end;
     MoveCursor     : begin
                         if (CursorPhase > Cursors[MoveCursor].MaxPhase) then
                            CursorPhase:=0;
                         if (ClickLevel = 0) then { 1. uroven }
                           SetCursorPicture(Cursors[MoveCursor].Mem[CursorPhase].S,
                                            Cursors[MoveCursor].Mem[CursorPhase].O)
                         else
                           SetCursorPicture(Cursors[MoveCursor].Mem2[CursorPhase].S,
                                            Cursors[MoveCursor].Mem2[CursorPhase].O);
                         Inc(CursorPhase);
                         if (CursorPhase > Cursors[MoveCursor].MaxPhase) then
                            CursorPhase:=0;
                      end;
     GroupingCursor : begin
                         if (CursorPhase > Cursors[GroupingCursor].MaxPhase) then
                            CursorPhase:=0;
                         if (ClickLevel = 0) then { 1. uroven }
                           SetCursorPicture(Cursors[GroupingCursor].Mem[CursorPhase].S,
                                            Cursors[GroupingCursor].Mem[CursorPhase].O)
                         else
                           SetCursorPicture(Cursors[GroupingCursor].Mem2[CursorPhase].S,
                                            Cursors[GroupingCursor].Mem2[CursorPhase].O);

                         Inc(CursorPhase);
                         if (CursorPhase > Cursors[GroupingCursor].MaxPhase) then
                            CursorPhase:=0;
                      end;
     WaitCursor     : begin
                         if (CursorPhase > Cursors[WaitCursor].MaxPhase) then
                            CursorPhase:=0;
                         if (ClickLevel = 0) then { 1. uroven }
                           SetCursorPicture(Cursors[WaitCursor].Mem[CursorPhase].S,
                                            Cursors[WaitCursor].Mem[CursorPhase].O)
                         else
                           SetCursorPicture(Cursors[WaitCursor].Mem2[CursorPhase].S,
                                            Cursors[WaitCursor].Mem2[CursorPhase].O);
                         Inc(CursorPhase);
                         if (CursorPhase > Cursors[WaitCursor].MaxPhase) then
                            CursorPhase:=0;
                      end;
     WayPointRecCursor : begin
                            if (CursorPhase > Cursors[WayPointRecCursor].MaxPhase) then
                               CursorPhase:=0;
                            if (ClickLevel = 0) then { 1. uroven }
                              SetCursorPicture(Cursors[WayPointRecCursor].Mem[CursorPhase].S,
                                               Cursors[WayPointRecCursor].Mem[CursorPhase].O)
                            else
                              SetCursorPicture(Cursors[WayPointRecCursor].Mem2[CursorPhase].S,
                                               Cursors[WayPointRecCursor].Mem2[CursorPhase].O);
                            Inc(CursorPhase);
                            if (CursorPhase > Cursors[WayPointRecCursor].MaxPhase) then
                               CursorPhase:=0;
                         end;
     NormalCursor   : begin
                         if (CursorPhase > Cursors[NormalCursor].MaxPhase) then
                            CursorPhase:=0;
                         if (ClickLevel = 0) then { 1. uroven }
                           SetCursorPicture(Cursors[NormalCursor].Mem[CursorPhase].S,
                                            Cursors[NormalCursor].Mem[CursorPhase].O)
                         else
                           SetCursorPicture(Cursors[NormalCursor].Mem2[CursorPhase].S,
                                            Cursors[NormalCursor].Mem2[CursorPhase].O);
                         Inc(CursorPhase);
                         if (CursorPhase > Cursors[NormalCursor].MaxPhase) then
                            CursorPhase:=0;
                      end;
    LoadCursor     : begin
                         if (CursorPhase > Cursors[LoadCursor].MaxPhase) then
                            CursorPhase:=0;
                         SetCursorPicture(Cursors[LoadCursor].Mem[CursorPhase].S,
                                          Cursors[LoadCursor].Mem[CursorPhase].O);
                         Inc(CursorPhase);
                         if (CursorPhase > Cursors[LoadCursor].MaxPhase) then
                            CursorPhase:=0;
                      end;

   else
   end;
   ChangeCursor(XCursorSize-1,YCursorSize-1);
   CursorVisibility:=LastVisibility; BlockMouse:=False;
end;

{ ***** }
procedure Draw_ground_objects(IPos,JPos,I2,J2:Word; Flag:Boolean); forward;
procedure Draw_flying_objects(IPos,JPos,I2,J2:Word; Draw:Byte); forward;

{ ***** }
procedure Draw_place(IPos,JPos:Word);
{ vykresli jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  XSize, YSize (v polickach), natoceni Direction a predloha je v poli
  Unit_picures; procedura kontroluje, zda je jednotka na obrazovce;
  pokud ne, tak ji nevykresli, jinak vykresli jeji viditelnou cast
}
var IBegin, JBegin, X, Y, XPom, YPom, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem, Ind: Word;
    { pro potreby vykreslovani }
    Level:Byte;
begin
  IBegin:=IBeg; JBegin:=JBeg;
  ISize:=1; JSize:=1;
  XSize:=XCellSize; YSize:=YCellSize;
  X:=IPos shl XCellShl; Y:=JPos shl YCellShl;
  if ((IPos < (IBegin+IScreenSize)) and
      (JPos < (JBegin+JScreenSize)) and
      ((IPos+ISize) > IBegin) and ((JPos+JSize) > JBegin)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}

{ ** ODSTRANENI PRIPADNYCH LETAJICICH OBJEKTU Z POZADI }
      { provede se automaticky prekreslenim pozadi }
      XPom:=(X+XMemBeg)-IBeg shl XCellShl;
      YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
      DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, True);
      Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);

      { ** PRENOS HOTOVEHO OBRAZKU Z PAMETI NA OBRAZOVKU }
      GraphQueue.Insert(IPos,JPos,IPos,JPos,1);
   end;
end;

{ ***** }
procedure Force_draw_shot(Shot:PShots); forward;

{ ***** }
procedure Draw_map_frame(I1,I2,J1,J2:Word);
{ Naplni na mape obdelnik o souradnicich I1,J1,I2,J2 vsemi
  pohyblivymi objekty (strelami, jednotkami), pokud tam patri.
  Pouziva se pro ucely rolovani obrazovky.
}
var I, J, ISiz, JSiz, K, L : Word;
    Pom:Byte;
begin
   if (I2 > IMax) then I2:=IMax; if (J2 > JMax) then J2:=JMax;
   for J:=J1 to J2 do
    for I:=I1 to I2 do with (Map^[I,J]) do begin
    { vykresleni objektu }
       save1:=I; save2:=J; bebex:=50000;
       DrawBck(I,J,I+1,J+1, True);
       bebex:=50001;
       if (First_level <> 0) then begin
          bebex:=50002;
       { vykresli se vsechny objekty }
          case (Level_type and 128) of
            0 : if ((Units[First_level]^.Temp = 0) and
                    (Units[First_level]^.Visibility)) then
                with (Units[First_level]^) do begin { pozemni jednotka }
                  bebex:=50006;
                  Force_draw_unit(Units[First_level]);
                  {Units[First_level]^.Temp:=1;}
                end;
            128 : ; { budova se nevykresluje }
          end;
       end else begin { if (First_level <> 0) then begin }
       { vekresli se letecke + strely }
         bebex:=50003;
         if (Second_level <> 0) then begin
            bebex:=50004;
            if ((Units[Second_level]^.Temp = 0) and
                (Units[Second_level]^.Visibility)) then
            with (Units[Second_level]^) do begin { letecka jednotka }
                 bebex:=50005;
                 Force_draw_unit(Units[Second_level]);
                 {Units[Second_level]^.Temp:=1;}
            end;
         end else begin { if (Second_level <> 0) then begin }
         { vykresli se jen strely }
           bebex:=50007;
           Pom:= Level_Type and 127;
           if ((Pom <> 0) and (Shots[Pom]^.Temp = 0) and
               (Shots[Pom]^.Visibility)) then begin { strela }
               bebex:=50008;
               Force_draw_shot(Shots[Pom]);{}
               Shots[Pom]^.Temp:=1;
           end;{}
         end;
       end;
    end;

    { smazani Tempu }
    bebex:=50009;
    for J:=J1 to J2 do
     for I:=I1 to I2 do with (Map^[I,J]) do begin
       if (First_level <> 0) then begin
          case (Level_type and 128) of
            0 : if ((Units[First_level] <> Nil) and
                    (Units[First_level]^.Temp <> 0)) then begin { jednotka }
                  Units[First_level]^.Temp:=0;
                end;
            128 : ; { budova se neodstranuje }
          end;
       end; { if (First_level <> 0) then begin }
       bebex:=50010;
       if ((Second_level <> 0) and (Units[Second_level] <> Nil)) then begin
          if (Units[Second_level]^.Temp <> 0) then begin { jednotka }
              Units[Second_level]^.Temp:=0;
          end;
       end; { if (Second_level <> 0) then begin }
       Pom:= Level_Type and 127;
       bebex:=50011;
       if ((Pom <> 0) and (Shots[Pom] <> Nil) and
           (Shots[Pom]^.Temp <> 0)) then begin { strela }
           bebex:=50012;
           Shots[Pom]^.Temp:=0;
       end;
     end;
end;

{ ***** }
procedure Draw_screen(I,J,XOffset,YOffset:Word);
{ Vykresli obrazovku, jejiz levy horni roh ma v mape souradnice I,J
}
var X,Y:Word;
begin
   Locate:='Draw_screen1';
   X:=(I shl XCellShl+XMemBeg)-IBeg shl XCellShl+XOffset;
   Locate:='Draw_screen2';
   Y:=(J shl YCellShl+YMemBeg)-JBeg shl YCellShl+YOffset;
   Locate:='Draw_screen3';
   Transfer2(X,Y,XScreenBeg,YScreenBeg,XScreenSize,YScreenSize);{}
   Locate:='';
end;

{ ***** }
procedure Intersection(var X1,Y1,X2,Y2:Word; var A,B,C,D:Word);
{ v parametrech A,B,C,D vrati prunik obdelniku
  X1-X2, Y1-Y2 a obdelniku A-C, B-D
  ( a to relativne vuci A,B),
  v X1,Y1 pak levy horni roh pruniku
}
var I,J,K,L:Word;
begin
   if ((X1 <= C) and (X2 >= A) and
       (Y1 <= D) and (Y2 >= B)) then begin { intersection existst }
      if (X1 < A) then begin I:=0; X1:=A; end else I:=X1-A;
      if (X2 < C) then J:=X2-A else J:=C-A;
      if (Y1 < B) then begin K:=0; Y1:=B; end else K:=Y1-B;
      if (Y2 < D) then L:=Y2-B else L:=D-B;
   end else begin
     I:=0; J:=0; K:=0; L:=0;
   end;
   A:=I; B:=K; C:=J; D:=L;
end;

{ ***** }
procedure DrawBck2(I,J:Word);
{ v danem ramci prekresli obrazovku obrazky pozadi
}
label Skip;
var K, L, X, Y, XP,YP, ISize, JSize, Pom:Word;
    A,B,C,D,XW1,XW2,YW1,YW2:Word;
    Color:Byte;
begin
   L:=J; K:=I; XW1:=XWin1; XW2:=XWin2; YW1:=YWin1; YW2:=YWin2;
   if ((K <= IMax) and (L <= JMax)) then with (Map^[K,L]) do begin
     if ((Level_type and 128 = 128) and (First_level <> 0) and
         (Buildings[First_level]^.Visibility)) then
     with (Buildings[First_level]^) do begin
     { budova }
        bebex:=13000;
        if (Activity) then begin
         bebex:=13001;
         with (Building_types[BuildingType]) do begin
           bebex:=13002;
           XP:=K shl XCellShl; YP:=L shl YCellShl;
           A:=XP; B:=YP; C:=XP+XCellSize - 1; D:=YP+YCellSize - 1;
           bebex:=13003;
           Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
           bebex:=13004;
           if (((XW1+XMemBeg) < IBeg shl XCellShl) or
               ((YW1+YMemBeg) < JBeg shl YCellShl))
           then GoTo Skip;
           X:=(XW1+XMemBeg)-IBeg shl XCellShl;
           Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
           bebex:=13005;
           with (Background[MapBck^[K,L].BckType]) do begin
              SpecSpeedPutImageMem(X,Y,Segment,Offsets,A,B,C,D);
           end;
           bebex:=13006;
           ISize:=IBuildingSize; JSize:=JBuildingSize;
           XP:=IPos shl XCellShl; YP:=JPos shl YCellShl;
           A:=XP; B:=YP;
           C:=XP+ISize shl XCellShl - 1; D:=YP+JSize shl YCellShl - 1;
           bebex:=13007;
           Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
           X:=(XW1+XMemBeg)-IBeg shl XCellShl;
           Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
           Color:=Races[Race].RaceColor;
           bebex:=13008;
           case (BuildPhase) of
             1 : begin
                    SpecSpeedPutImageMemUnit(X,Y,S1,O1,A,B,C,D,Color);
                 end;
             2 : begin
                    SpecSpeedPutImageMemUnit(X,Y,S2,O2,A,B,C,D,Color);
                 end;
             3 : begin
                    SpecSpeedPutImageMemUnit(X,Y,S3,O3,A,B,C,D,Color);
                 end;
             4 : begin
                   with (SO[BuildAnimPhase]) do
                      SpecSpeedPutImageMemUnit(X,Y,S,O,A,B,C,D,Color);
                 end;
             5 : begin
                   with (SO[BuildAnimPhase]) do
                      SpecSpeedPutImageMemUnit(X,Y,S,O,A,B,C,D,Color);
                 end;
             6 : begin
                    SpecSpeedPutImageMemUnit(X,Y,S6,O6,A,B,C,D,Color);
                 end;
             7 : begin
                    SpecSpeedPutImageMemUnit(X,Y,S7,O7,A,B,C,D,Color);
                 end;
           end;
           bebex:=13009;
         end;
         bebex:=13010; save1:=IPos; save2:=JPos;
         if (((IPos shl XCellShl+XMemBeg) < IBeg shl XCellShl) or
              ((JPos shl XCellShl+YMemBeg) < JBeg shl YCellShl))
         then GoTo Skip;
         XP:=(IPos shl XCellShl+XMemBeg)-IBeg shl XCellShl;
         YP:=(JPos shl YCellShl+YMemBeg)-JBeg shl YCellShl;
         bebex:=13050;
         if (Races[MyRace].Friend[Race] = 0) then Color:=80
         else if (Races[MyRace].Friend[Race] = 1) then Color:=67
              else Color:=240;
         bebex:=13051;  save1:=XP; save2:=YP; bebey:=ISize;
         if ((Group = ActiveGroup) and (Activity)) then
             FrameMem2(XP,YP+6,XP+ISize shl XCellShl-1,YP+JSize shl YCellShl-1,(ISize shl XCellShl) shr 3+FrameAdd,Color);
         bebex:=13011;
        end else with (Explosions2) do begin
        { budova exploduje - ruzne faze exploze }
          bebex:=13012;
          with (Building_types[BuildingType]) do begin
            ISize:=IBuildingSize; JSize:=JBuildingSize;
          end;
          XP:=K shl XCellShl; YP:=L shl YCellShl;
          A:=XP; B:=YP; C:=XP+XCellSize - 1; D:=YP+YCellSize - 1;
          Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
          if (((XW1+XMemBeg) < IBeg shl XCellShl) or
              ((YW1+YMemBeg) < JBeg shl YCellShl))
          then GoTo Skip;
          X:=(XW1+XMemBeg)-IBeg shl XCellShl;
          Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
          with (Background[MapBck^[K,L].BckType]) do begin
            SpecSpeedPutImage2Mem(X,Y,Segment,Offsets,A,B,C,D);
          end;
          XP:=IPos shl XCellShl; YP:=JPos shl YCellShl;
          A:=XP; B:=YP;
          C:=XP+ISize shl XCellShl - 1; D:=YP+JSize shl YCellShl - 1;
          Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
          X:=(XW1+XMemBeg)-IBeg shl XCellShl;
          Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
          Color:=Races[Race].RaceColor;
          {x}
          if (JSize < 2) then
            if (ISize > 1) then begin
               SpecSpeedPutImage2Mem(X+XCellSize,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
               SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
            end else
               SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D)
          else
            if (JSize = 2) then
              SpecSpeedPutImage2Mem(X,Y,Medium[Phase].S,Medium[Phase].O,A,B,C,D)
            else
              if (JSize = 3) then SpecSpeedPutImage2Mem(X,Y,Big[Phase].S,Big[Phase].O,A,B,C,D)
        end;
     end else begin
     { skutecne pozadi }
       bebex:=13013;
       with (Background[MapBck^[K,L].BckType]) do begin
         bebex:=13014;
         XP:=K shl XCellShl; YP:=L shl YCellShl;
         A:=XP; B:=YP; C:=XP+XCellSize - 1; D:=YP+YCellSize - 1;
         Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
         if (((XW1+XMemBeg) < IBeg shl XCellShl) or
             ((YW1+YMemBeg) < JBeg shl YCellShl))
         then GoTo Skip;
         X:=(XW1+XMemBeg)-IBeg shl XCellShl;
         Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
         bebex:=13015;
         if ((A <> 0) or (B <> 0) or (C <> 0) or (D <> 0)) then
           SpecSpeedPutImageMem(X,Y,Segment,Offsets,A,B,C,D);
         { nyni debris }
         bebex:=13016;
         with (MapBck^[K,L]) do begin
           bebex:=13017;
           if ((BelowEqual(BckType,Field) or Above(BckType,Resrc)) and
                (Info <> 255)) then with (DebrisInfo^[Info]) do begin
             if (DebrisTimmer <> 0) then begin { trosky existuji }
                bebex:=13018;
                with (DebrisPicture[DebrisType]) do
                   SpecSpeedPutImage2Mem(X,Y,DebrisSegment,Offsets,A,B,C,D);
             end;
             bebex:=13019;
             if (FireTimmer <> 0) then begin { trosky existuji }
                bebex:=13020;
                with (DebrisPicture[DebrisFireIndex + FirePhase shr 1]) do
                    SpecSpeedPutImage2Mem(X+XDebrisFireAdd,Y+YDebrisFireAdd,
                                          DebrisSegment,Offsets,A,B,C,D);
              end;
           end; { with (DebrisInfo[Info]) do begin }
         end; { with (MapBck[K,L]) do begin }
       end;
     end;
     with (MapBck^[K,L]) do
       if (Fog_of_war) then begin
         Temporary:=Get_fog_index(K,L);
         if (A >= XCellSize) then A:=XCellSize-1;
         if (B >= YCellSize) then B:=YCellSize-1;
         if (C >= XCellSize) then C:=XCellSize-1;
         if (D >= YCellSize) then D:=YCellSize-1;
         if (Temporary < 255) then
           SpecSpeedPutImage2Mem(X,Y,Grids[Temporary].GridSeg,
                                 Grids[Temporary].GridOfs,A,B,C,D);
       end;
   end; { with }
Skip:
end;

{ ***** }
procedure Real_draw2(_unit:PUnit; X, Y, ISize, JSize:Word; Ind:Byte; DrawBackground:Boolean);
{ provede skutecne vykresleni jednotky na pozici X, Y (v pameti);
  pokud je DrawBackground = True, prvne nakresli pozadi, jinak ne
  PRO VYKRESLOVANI PRESAHU JEDNOTKY NA SOUSEDNI POLICKO
}
label KOnec;
var Color:Byte;
    A,B,C,D,XW1,XW2,YW1,YW2,XZ,YZ:Word;
begin
 with (_unit^) do with (Unit_pictures[Ind]) do begin
 { ** VYKRESLENI JEDNOTKY }
    { vykresleni pozadi }
    XZ:=X; YZ:=Y;
    XW1:=XWin1; XW2:=XWin2; YW1:=YWin1; YW2:=YWin2;
    A:=X; B:=Y; C:=X+Unit_types[UnitType,Races[Race].Ally].XUnitSize-1;
    D:=Y+Unit_types[UnitType,Races[Race].Ally].YUnitSize-1;
    Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
    X:=(XW1+XMemBeg)-IBeg shl XCellShl;
    Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
    Color:=Races[Race].RaceColor;

    if (Activity) then begin
      case (Direction) of
      1 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S1,O1,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S9,O9,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S17,O17,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S25,O25,A,B,C,D,Color);
              end;
            end;
        2 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S2,O2,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S10,O10,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S18,O18,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S26,O26,A,B,C,D,Color);
              end;
            end;
        4 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S3,O3,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S11,O11,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S19,O19,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S27,O27,A,B,C,D,Color);
              end;
            end;
        8 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S4,O4,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S12,O12,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S20,O20,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S28,O28,A,B,C,D,Color);
              end;
            end;
        16 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S5,O5,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S13,O13,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S21,O21,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S29,O29,A,B,C,D,Color);
              end;
            end;
        32 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S6,O6,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S14,O14,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S22,O22,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S30,O30,A,B,C,D,Color);
              end;
            end;
        64 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S7,O7,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S15,O15,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S23,O23,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S31,O31,A,B,C,D,Color);
              end;
            end;
        128 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpecSpeedPutImageMemUnit(X,Y,S8,O8,A,B,C,D,Color);
              end else begin
                if (Phase < 4) then SpecSpeedPutImageMemUnit(X,Y,S16,O16,A,B,C,D,Color)
                else
                  if (Phase < 6) then SpecSpeedPutImageMemUnit(X,Y,S24,O24,A,B,C,D,Color)
                  else SpecSpeedPutImageMemUnit(X,Y,S32,O32,A,B,C,D,Color);
              end;
            end;
      end;
      if ((ActiveDefence) and (Race = MyRace)) then begin
         XW1:=XWin1; XW2:=XWin2; YW1:=YWin1; YW2:=YWin2;
         A:=XZ; B:=YZ; C:=XZ+12-1; D:=YZ+12-1;
         Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
         X:=(XW1+XMemBeg)-IBeg shl XCellShl;
         Y:=(YW1+YMemBeg)-JBeg shl YCellShl;
         SpecSpeedPutImage2Mem(X+3,Y+1,DefModeSegment,DefModeOffset,A,B,C,D);
      end;
      X:=(XZ+XMemBeg)-IBeg shl XCellShl;
      Y:=(YZ+YMemBeg)-JBeg shl YCellShl;
      if (SpecStatusBar) then
         DrawSpecStatusBar(X,Y,Unit_types[UnitType,Races[Race].Ally].XUnitSize,
                           Damage,Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus,
                           UniqueNumber <> 65535,Races[Race].RaceColor);
    end else with (Explosions2) do begin
      { jednotka exploduje - ruzne faze exploze }
      if (A >= XCellSize) then A:=XCellSize-1; if (B >= YCellSize) then B:=YCellSize-1;
      if (C >= XCellSize) then C:=XCellSize-1; if (D >= YCellSize) then D:=YCellSize-1;
      case (Phase) of
         1 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S1,O1,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         2 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S2,O2,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         3 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S3,O3,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         4 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S4,O4,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         5 : begin
                if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S5,O5,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         6 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S6,O6,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         7 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S7,O7,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
         8 : begin
               if (DestroyEffect) then SpecSpeedPutImage2Mem(X,Y,S8,O8,A,B,C,D)
               else SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
             end;
      else
        if ((Phase > 0) and (Phase < MaxSmallExplosPhase) and
             (Unit_types[UnitType,Races[Race].Ally].TargetTyp <> 0)) then
          SpecSpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O,A,B,C,D);
      end;
    end;
 end; { with }
Konec:
end;

{ ***** }
procedure Real_draw_bullet2(X,Y:Word; Direction, AttackPicture, Phase:Byte);
{ provede skutecne vykresleni strely typu AttackLevel a natoceni
  Direction na pozici X, Y (v pameti);
  PRO VYKRESLOVANI PRESAHU JEDNOTKY NA SOUSEDNI POLICKO
}
var Color:Byte;
    A,B,C,D,XW1,XW2,YW1,YW2:Word;
begin
   with (Bullets[AttackPicture]) do begin
   { ** VYKRESLENI STRELY }
      { vykresleni pozadi }
      XW1:=XWin1; XW2:=XWin2; YW1:=YWin1; YW2:=YWin2;
      A:=X; B:=Y; C:=X+Bullets[AttackPicture].XSize-1;
      D:=Y+Bullets[AttackPicture].YSize-1;
      Intersection(XW1,YW1,XW2,YW2,A,B,C,D);
      X:=(XW1+XMemBeg)-IBeg shl XCellShl;
      Y:=(YW1+YMemBeg)-JBeg shl YCellShl;

      case (Direction) of
        1 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S1,O1,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S9,O9,A,B,C,D);
              end;
            end;
        2 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S2,O2,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S10,O10,A,B,C,D);
              end;
            end;
        4 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S3,O3,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S11,O11,A,B,C,D);
              end;
            end;
        8 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S4,O4,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S12,O12,A,B,C,D);
              end;
            end;
        16 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S5,O5,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S13,O13,A,B,C,D);
              end;
            end;
        32 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S6,O6,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S14,O14,A,B,C,D);
              end;
            end;
        64 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S7,O7,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S15,O15,A,B,C,D);
              end;
            end;
        128 : begin
              { vykresleni strely }
              if (Phase < 1) then begin
                  SpecSpeedPutImage2Mem(X,Y,S8,O8,A,B,C,D);
              end else begin
                  SpecSpeedPutImage2Mem(X,Y,S16,O16,A,B,C,D);
              end;
            end;
      end;
   end; { with }
end;

{ ***** }
procedure Draw_portion(I,J,Locality,Size:Word; Typ:Byte);
{ vykresli ze ctverce I,J pouze cast:
- Locality:
  0 .. horni cast       4 .. pravy horni roh
  1 .. pravou cast      5 .. pravy dolni roh
  2 .. spodni cast      6 .. levy dolni roh
  3 .. levou cast       7 .. levy horni roh

- Size .. sirka casti
- Typ:
   0 .. vykresli JEN pozadi
   1 .. vykresli se jen pozemni jednotky
   2 .. vykresli se jen vzdusne jednotky
   3 .. vykresli se oba typy
}

begin
   { nyni zjistime souradnice vyrezu }
   bebex:=8000; bebey:=Size; save1:=I; save2:=J;
   case (Locality) of
     0 : begin XWin1:=I shl XCellShl; YWin1:=J shl YCellShl;
               XWin2:=XWin1+XCellSize+Size-1; YWin2:=YWin1+(Size-1);
               end;
     1 : begin XWin1:=(I+1) shl XCellShl; YWin1:=J shl YCellShl;
               XWin2:=XWin1+(Size-1); YWin2:=YWin1+YCellSize+Size-1;
               end;
     2 : begin XWin1:=I shl XCellShl; YWin1:=(J+1) shl YCellShl;
               XWin2:=XWin1+XCellSize+Size-1; YWin2:=YWin1+(Size-1);
               end;
     3 : begin XWin1:=I shl XCellShl; YWin1:=J shl YCellShl;
               XWin2:=XWin1+(Size-1); YWin2:=YWin1+YCellSize+Size-1;
               end;
     4 : begin XWin1:=(I+1) shl XCellShl; YWin1:=J shl YCellShl;
               XWin2:=XWin1+Size-1; YWin2:=YWin1+Size-1;
               end;
     5 : begin XWin1:=(I+1) shl XCellShl; YWin1:=(J+1) shl YCellShl;
               XWin2:=XWin1+(Size-1); YWin2:=YWin1+(Size-1);
               end;
     6 : begin XWin1:=I shl XCellShl; YWin1:=(J+1) shl YCellShl;
               XWin2:=XWin1+Size-1; YWin2:=YWin1+YCellSize-1;
               end;
     7 : begin XWin1:=I shl XCellShl; YWin1:=J shl YCellShl;
               XWin2:=XWin1+Size-1; YWin2:=YWin1+Size-1;
               end;
   end;
   WindowActivity:=True; bebex:=8001;

   { nyni zkousime kreslit: }
   if (Typ = 0) then begin { pozadi }
      bebex:=8002;
      DrawBck2(I,J);
   end else begin
      bebex:=8003;
      if ((Typ = 1) or (Typ = 3)) then Draw_ground_objects(I,J,I+1,J+1,False);
      bebex:=8004;
      if ((Typ = 2) or (Typ = 3)) then Draw_flying_objects(I,J,I+1,J+1,3);
   end;

   WindowActivity:=False;
end;

procedure Draw_surroundings_for_bck(I,J,XOffset,YOffset,Size:Word); forward;

{ ***** }
procedure DrawSpecStatusBar(X,Y,XSize,Damage,DefenceStrength:Word; Core:Boolean; Color:Byte);
{ Procedura vykresli do pameti ramecek se stavem poslozeni. Levy horni
  roh objektu, ktereho se to tyka  je dan X,Y; jeho sirka pak XSize
}
var DMGStrength, DMG, BarSizeWeight:Double;
    BarSize,DamageBarSize:Word;
begin
   if (Damage > DefenceStrength) then Damage:=DefenceStrength;
   DMGStrength:=DefenceStrength; DMGStrength:=DMGStrength/100;
   DMG:=Damage; DMG:=DMG/DMGStrength;
   BarSize:=XSize-13-4;
   DMGStrength:=DefenceStrength;
   BarSizeWeight:=BarSize; BarSizeWeight:=100/BarSizeWeight;
   DamageBarSize:=Round(DMG/BarSizeWeight);
   if (DamageBarSize mod 2 <> 0) then Dec(DamageBarSize);
   if (DamageBarSize < 1) then DamageBarSize:=1;
   X:=X+(XSize-DamageBarSize) shr 1;
   Dec(X,2); Inc(Y,3); Color:=Color;

   if (Core) then Color:=98;
   FrameMem2(X,Y+1,X+DamageBarSize+4,Y+2,2,Color+4);{}
   FrameMem2(X,Y,X+DamageBarSize+4,Y+1,2,Color);{}
end;

{ ***** }
procedure Draw_flash(X,Y,S,O:Word);
{ vykresli zablesk s obrazkem na S:O a na bodove pozici na obrazovce X,Y
}
begin
   X:=(X+XMemBeg)-IBeg shl XCellShl;
   Y:=(Y+YMemBeg)-JBeg shl YCellShl;
   SpeedPutImage2Mem(X,Y,S,O);
end;

{ ***** }
procedure DrawBck(I,J,I2,J2:Word; Draw2:Boolean);
{ v danem ramci prekresli obrazovku obrazky pozadi
  Draw2 = True, maji-li se vykreslit i presahy jednotek z vedlejsich policek
}
var K, L, X, Y, XP,YP, ISize, JSize, XSize, YSize:Word;
    Pomocna:Word;
    Draw:Boolean;
    Color:Byte;
begin
   save1:=111;
   for L:=J to J2-1 do
     for K:=I to I2-1 do begin
        X:=(K shl XCellShl+XMemBeg)-IBeg shl XCellShl;
        Y:=(L shl YCellShl+YMemBeg)-JBeg shl YCellShl;
        with (Map^[K,L]) do
          if ((Level_type and 128 = 128) and (First_level <> 0) and
              (Buildings[First_level]^.Visibility)) then
          with (Buildings[First_level]^) do begin
          { budova }
             if (Activity) then begin
               with (Building_types[BuildingType]) do begin
                 ISize:=IBuildingSize; JSize:=JBuildingSize;
                 XP:=(IPos shl XCellShl+XMemBeg)-IBeg shl XCellShl;
                 YP:=(JPos shl YCellShl+YMemBeg)-JBeg shl YCellShl;
                 Draw:=False;
                 if  ((ISize = 3) and (JSize = 3)) then begin
                   if ((IPos = K) and (JPos = L) or
                       ((IPos+2) = K) and ((JPos+2) = L) and (FireState = 2))
                   then Draw:=True;{}
                 end else
                   if ((ISize = 2) and (JSize = 2)) then begin
                     if ((IPos = K) and (JPos = L) or
                         ((IPos+1) = K) and ((JPos+1) = L) and (FireState = 2))
                     then Draw:=True;
                   end else
                     if ((ISize = 2) and (JSize = 1)) then begin
                        if ((IPos = K) and (JPos = L) or
                            ((IPos+1) = K) and (JPos = L) and (FireState = 2))
                        then Draw:=True;
                     end else begin
                        Draw:=True;
                     end;

                 XSize:=ISize shl XCellShl - XCellSize;
                 { K vyjadruje X, L vyjadruje Y }
                 Pomocna:=(K-IPos) shl XCellShl;
                 Pomocna:=Pomocna+((L-JPos) shl YCellShl)*(ISize shl XCellShl);
                 with (Background[MapBck^[K,L].BckType]) do begin
                   SpeedPutImageMem(X,Y,Segment,Offsets);
                 end;
                 case (BuildPhase) of
                   1 : begin
                          SpeedPutImageMemBuildings(X,Y,S1,O1,XSize,Pomocna,
                                                    Races[Race].RaceColor);
                       end;
                   2 : begin
                          SpeedPutImageMemBuildings(X,Y,S2,O2,XSize,Pomocna,
                                                    Races[Race].RaceColor);
                       end;
                   3 : begin
                          SpeedPutImageMemBuildings(X,Y,S3,O3,XSize,Pomocna,
                                                    Races[Race].RaceColor);
                       end;
                   4 : begin
                          with (SO[BuildAnimPhase]) do
                            SpeedPutImageMemBuildings(X,Y,S,O,XSize,Pomocna,
                                                      Races[Race].RaceColor);
                       end;
                   5 : begin
                         with (SO[BuildAnimPhase]) do
                            SpeedPutImageMemBuildings(X,Y,S,O,XSize,Pomocna,
                                                    Races[Race].RaceColor);
                       end;
                   6 : begin
                          SpeedPutImageMemBuildings(X,Y,S6,O6,XSize,Pomocna,
                                                    Races[Race].RaceColor);
                       end;
                   7 : begin
                          SpeedPutImageMemBuildings(X,Y,S7,O7,XSize,Pomocna,
                                                    Races[Race].RaceColor);
                       end;
                 end;
               end;
               if ((FirePhase <> 0) and (Draw)) then
                 case (FirePhase) of
                   1 : SpeedPutImage2Mem(X,Y,Fire.SB1,Fire.OB1);
                   2 : SpeedPutImage2Mem(X,Y,Fire.SB2,Fire.OB2);
                   3 : SpeedPutImage2Mem(X,Y,Fire.SB3,Fire.OB3);
                   4 : SpeedPutImage2Mem(X,Y,Fire.SB4,Fire.OB4);
                 end;
               if (Races[MyRace].Friend[Race] = 0) then Color:=80
               else if (Races[MyRace].Friend[Race] = 1) then Color:=67
                   else Color:=240;
               if ((Group = ActiveGroup) and (Activity)) then
                 FrameMem2(XP,YP+6,XP+ISize shl XCellShl-1,YP+JSize shl YCellShl-1,(ISize shl XCellShl) shr 3+FrameAdd,Color);
               if ((Repair) and (DrawRepair)) then
                  case (DrawRepairFlag) of
                     0..2: SpeedPutImage2Mem(X,Y,RepairH1Segment,RepairH1Offset);
                     3..5: SpeedPutImage2Mem(X,Y,RepairH2Segment,RepairH2Offset);
                     6..8: SpeedPutImage2Mem(X,Y,RepairH3Segment,RepairH3Offset);
                     9..11: SpeedPutImage2Mem(X,Y,RepairH4Segment,RepairH4Offset);
                     12..14: SpeedPutImage2Mem(X,Y,RepairH5Segment,RepairH5Offset);
                  else
                    Error(0,'unita grafika, faze opravy');
                  end;
               if (Draw2) then Draw_surroundings_for_bck(K,L,0,0,OvrSize);
               { vykresleni znacky utoku }
               if ((AttackMarkBuilding <> Nil)and(AttackMarkBuilding^ = Buildings[First_level])) then begin
                 if (AttackMarkPhase = 0) then SpeedPutImage2Mem(X,Y,SegAttack1Cursor,OffsAttack1Cursor)
                 else SpeedPutImage2Mem(X,Y,SegAttack2Cursor,OffsAttack2Cursor);
              end;
             end else with (Explosions2) do begin
             { budova exploduje - ruzne faze exploze }
                ISize:=Building_types[BuildingType].IBuildingSize;
                JSize:=Building_types[BuildingType].JBuildingSize;
                XP:=(IPos shl XCellShl)+XMemBeg-IBeg shl XCellShl;
                YP:=(JPos shl YCellShl)+YMemBeg-JBeg shl YCellShl;
                X:=XP;
                Y:=YP;
                with (Background[MapBck^[K,L].BckType]) do begin
                  SpeedPutImageMem(X,Y,Segment,Offsets);
                end;

                if (JSize < 2) then
                  if (ISize > 1) then begin
                     SpeedPutImage2Mem(X+XCellSize,Y,Small[Phase].S,Small[Phase].O);
                     SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O);
                  end else
                     SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
                else
                  if (JSize = 2) then
                    SpeedPutImage2Mem(X,Y,Medium[Phase].S,Medium[Phase].O)
                  else
                    if (JSize = 3) then SpeedPutImage2Mem(X,Y,Big[Phase].S,Big[Phase].O);

                if (Draw2) then Draw_surroundings_for_bck(K,L,0,0,OvrSize);
             end;
          end else begin
          { skutecne pozadi }
             with (Background[MapBck^[K,L].BckType]) do begin
               SpeedPutImageMem(X,Y,Segment,Offsets);
               { nyni debris }
                  with (MapBck^[K,L]) do begin
                    if ((BelowEqual(BckType,Field) or Above(BckType,Resrc)) and
                        (Info <> 255))
                    then with (DebrisInfo^[Info]) do begin
                       if (DebrisTimmer <> 0) then begin { trosky existuji }
                          with (DebrisPicture[DebrisType]) do
                            SpeedPutImage2Mem(X,Y,DebrisSegment,Offsets);
                       end;
                       if (FireTimmer <> 0) then begin { trosky existuji }
                          with (DebrisPicture[DebrisFireIndex + FirePhase shr 1]) do
                            SpeedPutImage2Mem(X+XDebrisFireAdd,
                                              Y+YDebrisFireAdd,
                                              DebrisSegment,Offsets);
                       end;
                    end; { with (DebrisInfo[Info]) do begin }
                    if (Draw2) then Draw_surroundings_for_bck(K,L,0,0,OvrSize);{}
                  end; { with (MapBck[K,L]) do begin }
             end;
          end;
          with (MapBck^[K,L]) do
          if (Fog_of_war) then begin
            Temporary:=Get_fog_index(K,L);
            if (Temporary < 255) then
              SpeedPutImage2Mem(X,Y,Grids[Temporary].GridSeg,
                                Grids[Temporary].GridOfs);
          end;
     end;
end;

{ ***** }
procedure DrawBck_without_buildings(I,J,I2,J2:Word; Draw:Boolean);
{ v danem ramci prekresli obrazovku obrazky POUZE pozadi (bez budov)
  Draw = True, maji-li se vykreslit i presahy jednotek z vedlejsich policek
}
var K, L, X, Y, XP,YP, ISize, JSize, Pom:Word;
begin
   for L:=J to J2-1 do
     for K:=I to I2-1 do begin
        X:=(K shl XCellShl+XMemBeg)-IBeg shl XCellShl;
        Y:=(L shl YCellShl+YMemBeg)-JBeg shl YCellShl;
        with (Map^[K,L]) do
          with (Background[MapBck^[K,L].BckType]) do begin
            SpeedPutImageMem(X,Y,{}{(K-I) shl XcellShl,(L-J) shl YCellShl,{}Segment,Offsets);
            { nyni debris }
            with (MapBck^[K,L]) do begin
              if ((BelowEqual(BckType,Field) or Above(BckType,Resrc)) and
                  (Info <> 255))
              then with (DebrisInfo^[Info]) do begin
                 if (DebrisTimmer <> 0) then begin { trosky existuji }
                    with (DebrisPicture[DebrisType]) do
                      SpeedPutImage2Mem(X,Y,DebrisSegment,Offsets);
                 end;
                 if (FireTimmer <> 0) then begin { trosky existuji }
                    with (DebrisPicture[DebrisFireIndex + FirePhase shr 1]) do
                      SpeedPutImage2Mem(X+XDebrisFireAdd,
                                        Y+YDebrisFireAdd,
                                        DebrisSegment,Offsets);
                 end;
              end; { with (DebrisInfo[Info]) do begin }
              if (Draw) then Draw_surroundings_for_bck(K,L,0,0,OvrSize);
              if (Fog_of_war) then begin
                 Temporary:=Get_fog_index(K,L);
                 if (Temporary < 255) then
                   SpeedPutImage2Mem(X,Y,{}{(K-I) shl XcellShl,(L-J) shl YCellShl,{}
                                     Grids[Temporary].GridSeg,
                                     Grids[Temporary].GridOfs);
              end;
            end; { with (MapBck[K,L]) do begin }
          end;
     end;
end;

{ ***** }
procedure Draw_surroundings(I,J,XOffset,YOffset,Size:Word; Typ:Byte);
{ vykresli okoli jednotky na pozici I, J s presahem Size;
  XOffset a YOffset <> 0, pokud objekt presahuje jedno policko;
  tato procedura se vola PRED vykreslenim vlastni jednotky
}
begin
   if (XOffset = 0) then begin
      if (J > 0) then Draw_portion(I+1,J-1,6,Size,Typ);
   end else begin
      if (J > 0) then Draw_portion(I+2,J-1,6,Size,Typ);
   end;

   if (J > 0) then Draw_portion(I,J-1,2,Size,Typ);
   if (XOffset = 0) then begin
      Draw_portion(I+1,J,3,Size,Typ);
      if (YOffset <> 0) then Draw_portion(I+1,J+1,3,Size,Typ);
   end else begin
      if (J > 0) then Draw_Portion(I+1,J-1,2,Size,Typ);
   end;
   if ((XOffset + Size + 32) > 64) then Draw_portion(I+2,J,3,Size,Typ);
   if (((XOffset + Size + 32) > 64) and (YOffset > 0)) then
      Draw_portion(I+2,J+1,3,Size,Typ);

   if ((I > 0) and (J > 0)) then Draw_portion(I-1,J-1,5,Size,Typ);
end;

{ ***** }
procedure Draw_surroundings2(I,J,XOffset,YOffset,Size:Word; Typ:Byte);
{ vykresli okoli jednotky na pozici I, J s presahem Size;
  XOffset a YOffset <> 0, pokud objekt presahuje jedno policko;
  tato procedura se vola PO vykreslenim vlastni jednotky
}
begin
   { nyni vsechny pozemni jednotky }
   if (XOffset = 0) then begin
     if (YOffset <> 0) then Draw_portion(I+1,J+2,7,Size,Typ)
     else Draw_portion(I+1,J+1,7,Size,Typ);
   end else
     if (YOffset <> 0) then Draw_portion(I+2,J+2,7,Size,Typ);

   if ((YOffset = 0) and (XOffset <> 0)) then Draw_portion(I+2,J+1,7,Size,Typ);
   if (I > 0) then Draw_portion(I-1,J,1,Size,Typ);

   if ((YOffset + Size + 32) > 64) then Draw_portion(I,J+2,0,Size,Typ);
   if ((XOffset > 0) and ((YOffset + Size + 32) > 64)) then
      Draw_portion(I+1,J+2,0,Size,Typ);

   if (YOffset = 0) then begin
      Draw_portion(I,J+1,0,Size,Typ);
      if (XOffset <> 0) then Draw_portion(I+1,J+1,0,Size,Typ);
   end else begin
     if (I > 0) then Draw_portion(I-1,J+1,1,Size,Typ);
   end;
   if (YOffset = 0) then begin
      if (I > 0) then Draw_portion(I-1,J+1,4,Size,Typ);
   end else begin
     if (I > 0) then Draw_portion(I-1,J+2,4,Size,Typ);
   end;
end;

{ ***** }
procedure Draw_surroundings_for_bck(I,J,XOffset,YOffset,Size:Word);
{ vykresli okoli policka na pozici I, J s presahem Size;
  XOffset a YOffset <> 0, pokud objekt presahuje jedno policko;
  tato procedura se vola PRED vykreslenim budovy na policku
}
begin
   if (J > 0) then Draw_portion(I,J-1,2,Size,1);
   if (XOffset <> 0) then begin
     if (J > 0) then Draw_Portion(I+1,J-1,2,Size,1);
   end;
   if ((I > 0) and (J > 0)) then Draw_portion(I-1,J-1,5,Size,1);
   { part two }
   if (I > 0) then Draw_portion(I-1,J,1,Size,1);
   if (YOffset <> 0) then begin
     if (I > 0) then Draw_portion(I-1,J+1,1,Size,1);
   end;

   { part three }
   if (J > 0) then Draw_portion(I,J-1,2,Size,2);
   if (XOffset <> 0) then begin
     if (J > 0) then Draw_Portion(I+1,J-1,2,Size,2);
   end;
   if ((I > 0) and (J > 0)) then Draw_portion(I-1,J-1,5,Size,2);
   { part four }
   if (I > 0) then Draw_portion(I-1,J,1,Size,2);
   if (YOffset <> 0) then begin
     if (I > 0) then Draw_portion(I-1,J+1,1,Size,2);
   end;
end;

{ ***** }
procedure Clear_surroundings(I,J,XOffset,YOffset,Size:Word);
{ smaze okoli jednotky na pozici I, J s presahem Size;
  XOffset a YOffset <> 0, pokud objekt presahuje jedno policko
}
begin
   save1:=I; save2:=J; Locate:='Clear_surroundings';
   bebex:=50000;
   if (XOffset = 0) then begin
      if (J > 0) then Draw_portion(I+1,J-1,6,Size,0);
      bebex:=50001;
   end else begin
      bebex:=50002;
      if (J > 0) then Draw_portion(I+2,J-1,6,Size,0);
   end;
   bebex:=50003;
   if (J > 0) then Draw_portion(I,J-1,2,Size,0);
   if (XOffset = 0) then begin
      bebex:=50004;
      Draw_portion(I+1,J,3,Size,0);
      if (YOffset <> 0) then Draw_portion(I+1,J+1,3,Size,0);
   end else begin
      bebex:=50005;
      if (J > 0) then Draw_Portion(I+1,J-1,2,Size,0);
   end;
   bebex:=50006;
   if ((XOffset + Size + 32) > 64) then Draw_portion(I+2,J,3,Size,0);
   bebex:=50007;
   if (((XOffset + Size + 32) > 64) and (YOffset > 0)) then begin
      bebex:=50008;
      Draw_portion(I+2,J+1,3,Size,0);
   end;

   bebex:=50009;
   if ((I > 0) and (J > 0)) then Draw_portion(I-1,J-1,5,Size,0);

   bebex:=50010;
   if (XOffset = 0) then begin
     if (YOffset <> 0) then begin
        bebex:=50011;
        if ((YOffset + Size + 32) > 64) then Draw_portion(I+1,J+2,7,Size,0);
     end else begin
        bebex:=50012;
        Draw_portion(I+1,J+1,7,Size,0);
     end;
   end else begin
     bebex:=50013;
     if (YOffset <> 0) then Draw_portion(I+2,J+2,7,Size,0);
   end;
   bebex:=50014;
   if ((YOffset = 0) and (XOffset <> 0)) then Draw_portion(I+2,J+1,7,Size,0);
   bebex:=50015;
   if (I > 0) then Draw_portion(I-1,J,1,Size,0);
   bebex:=50016;
   if ((YOffset + Size + 32) > 64) then Draw_portion(I,J+2,0,Size,0);
   bebex:=50017;
   if ((XOffset > 0) and ((YOffset + Size + 32) > 64)) then
      Draw_portion(I+1,J+2,0,Size,0);{}
   bebex:=50018;
   if (YOffset = 0) then begin
      bebex:=50019;
      Draw_portion(I,J+1,0,Size,0);
      if (XOffset <> 0) then Draw_portion(I+1,J+1,0,Size,0);
   end else begin
     bebex:=50020;
     if (I > 0) then Draw_portion(I-1,J+1,1,Size,0);
   end;
   bebex:=50021;
   if (YOffset = 0) then begin
      bebex:=50022;
      if (I > 0) then Draw_portion(I-1,J+1,4,Size,0);
   end else begin
     bebex:=50023;
     if (I > 0) then Draw_portion(I-1,J+2,4,Size,0);
   end;

   bebex:=50024;
   { nyni znovuvykresli pozemni jednotky }
   if (XOffset = 0) then begin
      bebex:=50025;
      if (J > 0) then Draw_portion(I+1,J-1,6,Size,1);
   end else begin
      bebex:=50026;
      if (J > 0) then Draw_portion(I+2,J-1,6,Size,1);
   end;
   bebex:=50027;
   if (J > 0) then Draw_portion(I,J-1,2,Size,1);
   bebex:=50028;
   if (XOffset = 0) then begin
      bebex:=50029;
      Draw_portion(I+1,J,3,Size,1);
      bebex:=50030;
      if (YOffset <> 0) then Draw_portion(I+1,J+1,3,Size,1);
   end else begin
      bebex:=50031;
      if (J > 0) then Draw_Portion(I+1,J-1,2,Size,1);
   end;
   bebex:=50032;
   if ((XOffset + Size + 32) > 64) then Draw_portion(I+2,J,3,Size,1);
   bebex:=50033;
   if (((XOffset + Size + 32) > 64) and (YOffset > 0)) then
      Draw_portion(I+2,J+1,3,Size,1);
   bebex:=50034;
   if ((I > 0) and (J > 0)) then Draw_portion(I-1,J-1,5,Size,1);
   bebex:=50035;
   if (XOffset = 0) then begin
     bebex:=50036;
     if (YOffset <> 0) then begin
       bebex:=50037;
       if ((YOffset + Size + 32) > 64) then Draw_portion(I+1,J+2,7,Size,1);
     end else begin
       bebex:=50038;
       Draw_portion(I+1,J+1,7,Size,1);
     end;
   end else begin
     bebex:=50039;
     if (YOffset <> 0) then Draw_portion(I+2,J+2,7,Size,1);
   end;
   bebex:=50040;
   if ((YOffset = 0) and (XOffset <> 0)) then Draw_portion(I+2,J+1,7,Size,1);
   bebex:=50041;
   if (I > 0) then Draw_portion(I-1,J,1,Size,1);
   bebex:=50042;
   if ((YOffset + Size + 32) > 64) then Draw_portion(I,J+2,0,Size,1);
   bebex:=50043;
   if ((XOffset > 0) and ((YOffset + Size + 32) > 64)) then begin
      bebex:=50044;
      Draw_portion(I+1,J+2,0,Size,1);{}
   end;
   bebex:=50045;
   if (YOffset = 0) then begin
      bebex:=50046;
      Draw_portion(I,J+1,0,Size,1);
      bebex:=50047;
      if (XOffset <> 0) then Draw_portion(I+1,J+1,0,Size,1);
   end else begin
     bebex:=50048;
     if (I > 0) then Draw_portion(I-1,J+1,1,Size,1);
   end;
   bebex:=50049;
   if (YOffset = 0) then begin
      bebex:=50050;
      if (I > 0) then Draw_portion(I-1,J+1,4,Size,1);
   end else begin
     bebex:=50051;
     if (I > 0) then Draw_portion(I-1,J+2,4,Size,1);
   end;
   bebex:=50052;
   { nyni vzdusne jednotky }
   if (XOffset = 0) then begin
      bebex:=50053;
      if (J > 0) then Draw_portion(I+1,J-1,6,Size,2);
   end else begin
      bebex:=50054;
      if (J > 0) then Draw_portion(I+2,J-1,6,Size,2);
   end;
   bebex:=50055;
   if (J > 0) then Draw_portion(I,J-1,2,Size,2);
   bebex:=50056;
   if (XOffset = 0) then begin
      bebex:=50057;
      Draw_portion(I+1,J,3,Size,2);
      bebex:=50058;
      if (YOffset <> 0) then Draw_portion(I+1,J+1,3,Size,2);
   end else begin
      bebex:=50059;
      if (J > 0) then Draw_Portion(I+1,J-1,2,Size,2);
   end;
   bebex:=50060;
   if ((XOffset + Size + 32) > 64) then Draw_portion(I+2,J,3,Size,2);
   bebex:=50061;
   if (((XOffset + Size + 32) > 64) and (YOffset > 0)) then
      Draw_portion(I+2,J+1,3,Size,2);
   bebex:=50062;
   if ((I > 0) and (J > 0)) then Draw_portion(I-1,J-1,5,Size,2);
   bebex:=50063;
   if (XOffset = 0) then begin
     if (YOffset <> 0) then begin
       bebex:=50064;
       if ((YOffset + Size + 32) > 64) then Draw_portion(I+1,J+2,7,Size,2);
       bebex:=50065;
     end else begin Draw_portion(I+1,J+1,7,Size,2); bebex:=50066; end;
   end else begin
     bebex:=50067;
     if (YOffset <> 0) then Draw_portion(I+2,J+2,7,Size,2);
   end;
   bebex:=50068;
   if ((YOffset = 0) and (XOffset <> 0)) then Draw_portion(I+2,J+1,7,Size,2);
   bebex:=50069;
   if (I > 0) then Draw_portion(I-1,J,1,Size,2);
   bebex:=50070;
   if ((YOffset + Size + 32) > 64) then Draw_portion(I,J+2,0,Size,2);
   bebex:=50071;
   if ((XOffset > 0) and ((YOffset + Size + 32) > 64)) then
      Draw_portion(I+1,J+2,0,Size,2);{}
   bebex:=50072;
   if (YOffset = 0) then begin
      bebex:=50073;
      Draw_portion(I,J+1,0,Size,2);
      bebex:=50074;
      if (XOffset <> 0) then Draw_portion(I+1,J+1,0,Size,2);
   end else begin
     bebex:=50075;
     if (I > 0) then Draw_portion(I-1,J+1,1,Size,2);
   end;
   bebex:=50076;
   if (YOffset = 0) then begin
      bebex:=50077;
      if (I > 0) then Draw_portion(I-1,J+1,4,Size,2);
   end else begin
     bebex:=50078;
     if (I > 0) then Draw_portion(I-1,J+2,4,Size,2);
   end;
   Locate:='';
end;

{ ***** }
procedure Real_draw(_unit:PUnit; X, Y, ISize, JSize:Word; Ind:Byte; DrawBackground:Boolean);
{ provede skutecne vykresleni jednotky na pozici X, Y (v pameti);
  pokud je DrawBackground = True, prvne nakresli pozadi, jinak ne
}
var Color:Byte;
    Presah2:Byte;
    Typ:Byte;
begin
 save1:=222;
 with (_unit^) do with (Unit_pictures[Ind]) do begin
 { ** VYKRESLENI JEDNOTKY }
    { vykresleni pozadi }
    if (DrawBackGround) then DrawBck(IPos,JPos,IPos+ISize,JPos+JSize,False);
    X:=(X+XMemBeg)-IBeg shl XCellShl;
    Y:=(Y+YMemBeg)-JBeg shl YCellShl;
    Color:=Races[Race].RaceColor;
    Presah2:=OvrSize; if (TargetType = 3) then Typ:=2 else Typ:=1;
    if (Typ = 1) then Draw_surroundings(IPos,JPos,XOffset,YOffset,Presah2,3)
    else begin
      Draw_surroundings(IPos,JPos,XOffset,YOffset,Presah2,1);
      Draw_surroundings2(IPos,JPos,XOffset,YOffset,Presah2,1);
      Draw_surroundings(IPos,JPos,XOffset,YOffset,Presah2,2)
    end;

    if (Activity) then begin
      case (Direction) of
        1 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S1,O1,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S9,O9,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S17,O17,Color)
                  else SpeedPutImageMemUnit(X,Y,S25,O25,Color);
              end;
            end;
        2 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S2,O2,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S10,O10,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S18,O18,Color)
                  else SpeedPutImageMemUnit(X,Y,S26,O26,Color);
              end;
            end;
        4 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S3,O3,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S11,O11,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S19,O19,Color)
                  else SpeedPutImageMemUnit(X,Y,S27,O27,Color);
              end;
            end;
        8 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S4,O4,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S12,O12,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S20,O20,Color)
                  else SpeedPutImageMemUnit(X,Y,S28,O28,Color);
              end;
            end;
        16 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S5,O5,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S13,O13,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S21,O21,Color)
                  else SpeedPutImageMemUnit(X,Y,S29,O29,Color);
              end;
            end;
        32 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S6,O6,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S14,O14,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S22,O22,Color)
                  else SpeedPutImageMemUnit(X,Y,S30,O30,Color);
              end;
            end;
        64 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S7,O7,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S15,O15,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S23,O23,Color)
                  else SpeedPutImageMemUnit(X,Y,S31,O31,Color);
              end;
            end;
        128 : begin
              { vykresleni jednotky }
              if (Phase < 2) then begin
                  SpeedPutImageMemUnit(X,Y,S8,O8,Color);
              end else begin
                if (Phase < 4) then SpeedPutImageMemUnit(X,Y,S16,O16,Color)
                else
                  if (Phase < 6) then SpeedPutImageMemUnit(X,Y,S24,O24,Color)
                  else SpeedPutImageMemUnit(X,Y,S32,O32,Color);
              end;
            end;
      end;
      {x}
      if ((GroupMoveBlock > 0) and
          (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
          (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0))
      then begin
        if (GroupMoveBlock > (SpecAirUnitBlock-SpecAirUnitBlock div 3)) then
          SpeedPutImage2Mem(X+1,Y+1,AirNotReady0Seg,AirNotReady0Ofs)
        else
          if (GroupMoveBlock > (SpecAirUnitBlock-2*SpecAirUnitBlock div 3)) then
            SpeedPutImage2Mem(X+1,Y+1,AirNotReady1Seg,AirNotReady1Ofs)
          else
            if ((GroupMoveBlock <= (SpecAirUnitBlock-2*SpecAirUnitBlock div 3)) and
                (GroupMoveBlock > SpecAirUnitBlock shr 3)) then
              SpeedPutImage2Mem(X+1,Y+1,AirNotReady2Seg,AirNotReady2Ofs)
            else
              SpeedPutImage2Mem(X+1,Y+1,AirNotReady3Seg,AirNotReady3Ofs)
      end;

      {x}
      if ((ActiveDefence) and (Race = MyRace)) then SpeedPutImage2Mem(X+3,Y+1,DefModeSegment,DefModeOffset);
      {x}
      if (SpecStatusBar) then
        DrawSpecStatusBar(X,Y,Unit_types[UnitType,Races[Race].Ally].XUnitSize,
                          Damage,Unit_types[UnitType,Races[Race].Ally].DefenceStrength+DamageBonus,
                          UniqueNumber <> 65535,Races[Race].RaceColor);
      {x}
      if ((Repair) and (DrawRepair) {and (Race = MyRace){}) then begin
        if ((TargetType = 0) and (Races[Race].RaceType <> 3) and
            (Races[Race].RaceType <> 6)) then
           case (DrawRepairFlag) of
              0..2: SpeedPutImage2Mem(X,Y,RepairL1Segment,RepairL1Offset);
              3..5: SpeedPutImage2Mem(X,Y,RepairL2Segment,RepairL2Offset);
              6..8: SpeedPutImage2Mem(X,Y,RepairL3Segment,RepairL3Offset);
              9..11: SpeedPutImage2Mem(X,Y,RepairL4Segment,RepairL4Offset);
              12..14: SpeedPutImage2Mem(X,Y,RepairL5Segment,RepairL5Offset);
           else
             Error(0,'unita grafika, faze opravy');
           end
        else
           case (DrawRepairFlag) of
              0..2: SpeedPutImage2Mem(X,Y,RepairH1Segment,RepairH1Offset);
              3..5: SpeedPutImage2Mem(X,Y,RepairH2Segment,RepairH2Offset);
              6..8: SpeedPutImage2Mem(X,Y,RepairH3Segment,RepairH3Offset);
              9..11: SpeedPutImage2Mem(X,Y,RepairH4Segment,RepairH4Offset);
              12..14: SpeedPutImage2Mem(X,Y,RepairH5Segment,RepairH5Offset);
           else
             Error(0,'unita grafika, faze opravy');
           end;
      end;
      { vykresleni znacky utoku }
      if ((AttackMarkUnit <> Nil) and (AttackMarkUnit^ <> Nil) and
          (AttackMarkUnit^^.Index = _unit^.Index)) then begin
         if (AttackMarkPhase = 0) then
             SpeedPutImage2Mem(X,Y,SegAttack1Cursor,OffsAttack1Cursor)
          else
            SpeedPutImage2Mem(X,Y,SegAttack2Cursor,OffsAttack2Cursor);
      end;
    end else with (Explosions2) do begin
    { jednotka exploduje - ruzne faze exploze }
      case (Phase) of
         1 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S1,O1)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O);
             end;
         2 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S2,O2)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
         3 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S3,O3)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
         4 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S4,O4)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
         5 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S5,O5)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
         6 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S6,O6)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
         7 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S7,O7)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
         8 : begin
               if (DestroyEffect) then SpeedPutImage2Mem(X,Y,S8,O8)
               else SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O)
             end;
      else
         if ((Phase > 0) and (Phase < MaxSmallExplosPhase) and
             (Unit_types[UnitType,Races[Race].Ally].TargetTyp <> 0)) then
           SpeedPutImage2Mem(X,Y,Small[Phase].S,Small[Phase].O);
      end;
    end;
    if (Typ = 1) then Draw_surroundings2(IPos,JPos,XOffset,YOffset,Presah2,3)
    else Draw_surroundings2(IPos,JPos,XOffset,YOffset,Presah2,2);
 end; { with }
end;

{ ***** }
procedure Real_draw_bullet(X,Y:Word; Direction, AttackPicture, Phase:Byte);
{ provede skutecne vykresleni strely typu AttackLevel a natoceni
  Direction na pozici X, Y (v pameti);

}
var Color:Byte;
begin
   with (Bullets[AttackPicture]) do begin
   { ** VYKRESLENI STRELY }
      { vykresleni pozadi }
      X:=(X+XMemBeg)-IBeg shl XCellShl;
      Y:=(Y+YMemBeg)-JBeg shl YCellShl;

      case (Direction) of
        1 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S1,O1);
              end else begin
                  SpeedPutImage2Mem(X,Y,S9,O9);
              end;
            end;
        2 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S2,O2);
              end else begin
                  SpeedPutImage2Mem(X,Y,S10,O10);
              end;
            end;
        4 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S3,O3);
              end else begin
                  SpeedPutImage2Mem(X,Y,S11,O11);
              end;
            end;
        8 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S4,O4);
              end else begin
                  SpeedPutImage2Mem(X,Y,S12,O12);
              end;
            end;
        16 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S5,O5);
              end else begin
                  SpeedPutImage2Mem(X,Y,S13,O13);
              end;
            end;
        32 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S6,O6);
              end else begin
                  SpeedPutImage2Mem(X,Y,S14,O14);
              end;
            end;
        64 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S7,O7);
              end else begin
                  SpeedPutImage2Mem(X,Y,S15,O15);
              end;
            end;
        128 : begin
              { vykresleni jednotky }
              if (Phase < 1) then begin
                  SpeedPutImage2Mem(X,Y,S8,O8);
              end else begin
                  SpeedPutImage2Mem(X,Y,S16,O16);
              end;
            end;
      end;
   end; { with }
end;

{ ***** }
procedure Draw_flying_objects(IPos,JPos,I2,J2:Word; Draw:Byte);
{ Od pozice IPos,JPos do pozice I2, J2 vykresli vsechny letajici objekty
}
begin
   Dec(I2); Dec(J2);
   if (Draw and 2 = 2) then GraphQueue.Insert(IPos,JPos,I2,J2,0);
end;

{ ***** }
procedure DrawFlyingObjects(I,J:Word);
{ na pozici IPos,JPos vykresli vsechny letouny
}
label Skip;
var Ind, ISize, JSize, XSize,YSize, X, Y, XPom, YPom : Word;
    Color:Byte;
begin
   if ((OkMarkIPos = I) and (OkMarkJPos = J) and (OkMarkLevel = 0))
   then begin
   { potvrzeni presunu }
     X:=I shl XCellShl; Y:=J shl YCellShl;
     XPom:=(X+XMemBeg)-IBeg shl XCellShl; YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
     if (OkMarkPhase = 0) then
        SpeedPutImage2Mem(XPom,YPom,SegOk1Cursor,OffsOk1Cursor)
     else
        SpeedPutImage2Mem(XPom,YPom,SegOk2Cursor,OffsOk2Cursor);
   end;

   with (Map^[I,J]) do begin
      { nyni vlastni letecke jednotky }
      if ((Second_level <> 0) and (Units[Second_level] <> Nil)) then
      with (Units[Second_level]^) do begin
         if (Visibility) then begin
         { jednotka }
             { chyba pozice - oprav ji}
             XPom:=IPos; YPom:=JPos; X:=IPos; Y:=JPos;
             if (XOffset <> 0) then Inc(X);
             if (YOffset <> 0) then Inc(Y);
             if (Status <> 0) then begin
               case (Status) of
                 1: begin if (XPom > 0) then Dec(XPom); if (YPom > 0) then Dec(YPom); end;
                 2: begin if (YPom > 0) then Dec(YPom); end;
                 4: begin if (XPom < IMax) then Inc(X); if (YPom > 0) then Dec(YPom); end;
                 8: begin if (XPom < IMax) then Inc(X); end;
                 16:begin if (XPom < IMax) then Inc(X); if (YPom < JMax) then Inc(Y); end;
                 32:begin if (YPom < JMax) then Inc(Y); end;
                 64:begin if (XPom > 0) then Dec(XPom); if (YPom < JMax) then Inc(Y); end;
                 128:begin if (XPom > 0) then Dec(XPom);end;
               end;
             end;
             if (I < XPom) or (I > X) or (J < YPOm) or (J > Y) then begin
             { CHYBA!!! - oprav ji }
               Second_level:=0; GoTo Skip;
             end;

             with Unit_types[UnitType,Races[Race].Ally] do begin
               ISize:=IUnitSize; JSize:=JUnitSize;
               XSize:=XUnitSize; YSize:=YUnitSize;
               Ind:=PictureIndex;
             end;
             X:=IPos shl XCellShl + XOffset; Y:=JPos shl YCellShl + YOffset;
             if (((X+XMemBeg) < IBeg shl XCellShl) or
                 ((Y+YMemBeg) < JBeg shl YCellShl))
             then GoTo Skip;
             XPom:=(X+XMemBeg)-IBeg shl XCellShl; YPom:=Y+YMemBeg-JBeg shl YCellShl;
             if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
             na zacatku policka a tim zasahuje i do policka dalsiho }
             if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
             na zacatku policka a tim zasahuje i do policka dalsiho }
             if (WindowActivity) then
                Real_Draw2(Units[Second_level],X,Y,ISize,JSize,Ind,False)
             else
                Real_Draw(Units[Second_level],X,Y,ISize,JSize,Ind,False);

             if ((FirePhase <> 0) and (not WindowActivity)) then
              if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
              { pozemni jednotka }
                case (FirePhase) of
                  1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                  2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                  3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                  4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
                end;
              end else begin { letecka jednotka }
                case (FirePhase) of
                  1 : SpeedPutImage2Mem(XPom,YPom,Fire.S21,Fire.O21);
                  2 : SpeedPutImage2Mem(XPom,YPom,Fire.S22,Fire.O22);
                  3 : SpeedPutImage2Mem(XPom,YPom,Fire.S23,Fire.O23);
                  4 : SpeedPutImage2Mem(XPom,YPom,Fire.S24,Fire.O24);
                end;
              end;
              { if (FirePhase <> 0) then }
              if (Races[MyRace].Friend[Race] = 0) then Color:=80
              else if (Races[MyRace].Friend[Race] = 1) then Color:=67
                   else Color:=240;
              if (UniqueNumber <> 65535) then Color:=98;
              if (Group = ActiveGroup) then
                 FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,XSize shr 3+FrameAdd,Color);
         end;
      end;  { if (Second_level <> 0) then begin }
Skip:
   end; { with }


   if ((OkMarkIPos = I) and (OkMarkJPos = J) and (OkMarkLevel = 1))
   then begin
   { potvrzeni presunu }
      X:=I shl XCellShl; Y:=J shl YCellShl;
      XPom:=(X+XMemBeg)-IBeg shl XCellShl; YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
      if (OkMarkPhase = 0) then
         SpeedPutImage2Mem(XPom,YPom,SegOkAir1Cursor,OffsOkAir1Cursor)
      else
         SpeedPutImage2Mem(XPom,YPom,SegOkAir2Cursor,OffsOkAir2Cursor);
   end;
end;

{ ***** }
procedure Draw_ground_objects(IPos,JPos,I2,J2:Word; Flag:Boolean);
{ Od pozice IPos,JPos do pozice I2, J2 vykresli vsechny pozemni objekty;
  k zapamatovani jednoky, ktera jiz byla vykreslena slouzi nastavovani
  promenne Temp dane jednotky;
  Flag = True ... vymaz po skonceni Temp;
  Flag = False ... nemaz po skonceni Temp;
}
label Skip;
var I, J, Ind, ISize, JSize, XSize,YSize, XPom, YPom, X, Y : Word;
    Color:Byte;
begin
   Dec(I2); Dec(J2);
   for J:=JPos to J2 do
    for I:=IPos to I2 do with (Map^[I,J]) do begin
    { smazani objektu }
       if (First_level <> 0) then begin
          case (Level_type and 128) of
            0 :
               with (Units[First_level]^) do
               if (Activity or Destroyed) then begin  { pozemni jednotka }
                  bebex:=22000;  save1:=I; save2:=J;
                  { zjistime skutecnou pozici }
                  XPom:=IPos; YPom:=JPos; X:=IPos; Y:=JPos;
                  if (XOffset <> 0) then Inc(X); if (YOffset <> 0) then Inc(Y);
                  if (Status <> 0) then begin
                    case (Status) of
                      1: begin if (XPom > 0) then Dec(XPom); if (YPom > 0) then Dec(YPom); end;
                      2: begin if (YPom > 0) then Dec(YPom); end;
                      4: begin if (XPom < IMax) then Inc(X); if (YPom > 0) then Dec(YPom); end;
                      8: begin if (XPom < IMax) then Inc(X); end;
                      16:begin if (XPom < IMax) then Inc(X); if (YPom < JMax) then Inc(Y); end;
                      32:begin if (YPom < JMax) then Inc(Y); end;
                      64:begin if (XPom > 0) then Dec(XPom); if (YPom < JMax) then Inc(Y); end;
                      128:begin if (XPom > 0) then Dec(XPom);end;
                    end;
                  end;
                  bebex:=22001;
                  if (I < XPom) or (I > X) or (J < YPOm) or (J > Y) then begin
                  { CHYBA!!! - oprav ji }
                    First_level:=0; GoTo Skip;{}
                  end;
                  Inc(Temp);
                  if ((Temp = 1) and (Visibility)) then begin
                  { jednotka }
                      bebex:=22002;
                      with Unit_types[UnitType,Races[Race].Ally] do begin
                         ISize:=IUnitSize; JSize:=JUnitSize;
                         XSize:=XUnitSize; YSize:=YUnitSize;
                         Ind:=PictureIndex;
                      end;
                      bebex:=22003; save1:=IPos; save2:=JPos;
                      X:=IPos shl XCellShl + XOffset; Y:=JPos shl YCellShl + YOffset;
                      bebex:=22013;
                      if (((X+XMemBeg) < IBeg shl XCellShl) or
                          ((Y+YMemBeg) < JBeg shl YCellShl))
                      then GoTo Skip;
                      XPom:=(X+XMemBeg)-IBeg shl XCellShl; YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
                      bebex:=22014;
                      if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
                      na zacatku policka a tim zasahuje i do policka dalsiho }
                      if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
                      na zacatku policka a tim zasahuje i do policka dalsiho }
                      bebex:=22004;
                      if (WindowActivity) then
                        Real_Draw2(Units[First_level],X,Y,ISize,JSize,Ind,False)
                      else
                        Real_Draw(Units[First_level],X,Y,ISize,JSize,Ind,False);
                     bebex:=22005;
                     if ((FirePhase <> 0) and (not WindowActivity)) then
                      if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
                      { pozemni jednotka }
                         case (FirePhase) of
                           1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                           2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                           3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                           4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
                         end;
                      end else begin { letecka jednotka }
                         case (FirePhase) of
                            1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                            2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                            3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                            4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
                          end;
                      end;
                      { if (FirePhase <> 0) then }
                      bebex:=22006;
                      if (Races[MyRace].Friend[Race] = 0) then Color:=80
                      else if (Races[MyRace].Friend[Race] = 1) then Color:=67
                           else Color:=240;
                      if (UniqueNumber <> 65535) then Color:=98;
                      bebex:=22007;
                      if (Group = ActiveGroup) then
                         FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,
                                   XSize shr 3 + FrameAdd,Color);
                  end;
                end;
            128 : ; { budovy se vykresluji v ramci pozadi }
          end; { case }
Skip:
          { !!! strely se nevykresluji !!! }

       end; { if (First_level <> 0) then begin }
    end;
    bebex:=22008;
    { smazani Tempu }
    for J:=JPos to J2 do
      for I:=IPos to I2 do with (Map^[I,J]) do begin
         if (First_level <> 0) then begin
            case (Level_type and 128) of
              0 : with (Units[First_level]^) do begin  { pozemni jednotka }
                    if (Temp <> 0) then begin { jednotka }
                       if (Flag) then Temp:=0 else Dec(Temp);
                    end;
                  end;
              128 : ; { budovy se vykresluji v ramci pozadi }
            end; { case }

            { !!! strely zatim chybi !!! }
         end; { if (First_level <> 0) then begin }
      end;
end;

{ ***** }
procedure Transfer_map_frame(I,J,I2,J2:Word);
{ presune danou oblast mapy na obrazovku (je-li ve viditelne casti)
}
var IBegin, JBegin, X, Y, XPom, YPom, XSize, YSize, ISize, JSize, IPos, JPos: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    Ind:Word;
    Level:Byte;
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
begin
  IBegin:=IBeg; JBegin:=JBeg;
  ISize:=I2-I+1; JSize:=J2-J+1;
  XSize:=ISize shl XCellshl; YSize:=JSize shl XCellShl;
  IPos:=I; JPos:=J;
  X:=IPos shl XCellShl; Y:=JPos shl YCellShl;
  if ((IPos < (IBegin+IScreenSize)) and (JPos < (JBegin+JScreenSize)) and
      ((IPos+ISize-1) >= IBegin) and ((JPos+JSize-1) >= JBegin)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}

      { provede se automaticky prekreslenim pozadi }
      DrawBck(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);

      GraphQueue.Insert(I,J,I2,J2,1);
  end;
end;

{ ***** }
procedure TransferX(I,J:Word);
{ presune dany ctverec na obrazovku (je-li ve viditelne casti)
}
var IBegin, JBegin, X, Y, XPom, YPom, XSize, YSize, ISize, JSize, IPos, JPos: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    X2, Y2:Word;
    Ind:Word;
    Level:Byte;
    MouseOff, XORFrameOff:Boolean; { True, je-li treba smazat kurzor mysi }
begin
  IBegin:=IBeg; JBegin:=JBeg;
  ISize:=1; JSize:=1;
  XSize:=ISize shl XCellshl; YSize:=JSize shl XCellShl;
  IPos:=I; JPos:=J;
  X:=IPos shl XCellShl; Y:=JPos shl YCellShl;
  if ((IPos < (IBegin+IScreenSize)) and (JPos < (JBegin+JScreenSize)) and
      ((IPos+ISize-1) >= IBegin) and ((JPos+JSize-1) >= JBegin)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}
      { * nejprve otestujeme, zda objekt nepresahuje obrazovku zleva }
      if (IPos  < IBegin) then begin
      { objekt neni zcela na obrazovce }
         XVRAM:=XScreenBeg;
         asm
             mov Ax,0
             mov Ax,IBegin;
             shl Ax,XCellShl;
             mov XMem,Ax;
         end;
         XSizeMem:=XSize+X-XMem;
      end else  begin
      { objekt je zleva cely na obrazovce }
        { * nyni otestujeme, zda objekt nepresahuje obrazovku zprava }
        if ((IPos+ISize) > (IBegin+IScreenSize)) then begin
        { objekt neni zcela na obrazovce }
           XVRAM:=(IPos-IBegin) shl XCellShl + XScreenBeg;
           XMem:=X;
           XSizeMem:=(IBegin+IScreenSize-IPos) shl XCellShl;
        end else  begin
        { objekt je cely na obrazovce }
           XVRAM:=(IPos-IBegin) shl XCellShl + XScreenBeg;
           XMem:=X;
           XSizeMem:=XSize;
        end;
      end;

      { * nejprve otestujeme, zda objekt nepresahuje obrazovku shora }
      if (JPos  < JBegin) then begin
      { objekt neni zcela na obrazovce }
         YVRAM:=YScreenBeg;
         asm mov Ax,JBegin; shl Ax,YCellShl; mov YMem,Ax; end;
         YSizeMem:=YSize+Y-YMem;
      end else  begin
      { objekt je shora cely na obrazovce }
        { * nyni otestujeme, zda objekt nepresahuje obrazovku zdola }
        if ((JPos+JSize) > (JBegin+JScreenSize)) then begin
        { objekt neni zcela na obrazovce }
           YVRAM:=(JPos-JBegin) shl YCellShl + YScreenBeg;
           YMem:=Y;
           YSizeMem:=(JBegin+JScreenSize-JPos) shl YCellShl;
        end else  begin
        { objekt je cely na obrazovce }
           YVRAM:=(JPos-JBegin) shl YCellShl + YScreenBeg;
           YMem:=Y;
           YSizeMem:=YSize;
        end;
      end;

      { ** PRENOS HOTOVEHO OBRAZKU Z PAMETI NA OBRAZOVKU }
      GetXYMouse(XMouse,YMouse);
      if (TestMouse(XVRAM,YVRAM,XVRAM+XSizeMem,YVRAM+YSizeMem))
      then MouseOff:=True else MouseOff:=False;
      {x}
      XMem:=(XMem+XMemBeg)-IBeg shl XCellShl;
      YMem:=(YMem+YMemBeg)-JBeg shl YCellShl;
      {x}
      X2:=XVRAM+XSizeMem; Y2:=YVRAM+YSizeMem;
      XORFrameOff:=(XVRAM <= XGroup) and (X2 >= XGroup) or
                   (XVRAM <= XP) and (X2 >= XP) or
                   (YVRAM <= YGroup) and (Y2 >= YGroup) or
                   (YVRAM <= YP) and (Y2 >= YP);
      {x}
      if (MouseOff) then CursorOff;
      if (Grouping) then begin
          BlockMouse:=True;{} DrawXORFRame:=False;{}
          if (XORFrameOff) then XORFrame(XGroup,YGroup,XP,YP,XorColor);{}
      end;
      if (XSizeMem and 1 = 0) then Transfer2(XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem)
      else Transfer(XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem);
      if (Grouping) then begin
          if (XORFrameOff) then XORFrame(XGroup,YGroup,XP,YP,XorColor);
          DrawXORFRame:=True; BlockMouse:=False;{}
      end;
      if (MouseOff) then CursorOn;
  end;
end;

{ ***** }
procedure Transfer_map_frame2(I,J,I2,J2:Word);
{ presune danou oblast mapy na obrazovku (je-li ve viditelne casti)
}
var IBegin, JBegin, X, Y, XPom, YPom, XSize, YSize, ISize, JSize, IPos, JPos: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    Ind:Word;
    Level:Byte;
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
begin
  IBegin:=IBeg; JBegin:=JBeg;
  ISize:=I2-I+1; JSize:=J2-J+1;
  XSize:=ISize shl XCellshl; YSize:=JSize shl XCellShl;
  IPos:=I; JPos:=J;
  X:=IPos shl XCellShl; Y:=JPos shl YCellShl;
  if ((IPos < (IBegin+IScreenSize)) and (JPos < (JBegin+JScreenSize)) and
      ((IPos+ISize-1) >= IBegin) and ((JPos+JSize-1) >= JBegin)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}

      { provede se automaticky prekreslenim pozadi }
      DrawBck_without_buildings(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);

      GraphQueue.Insert(I,J,I2,J2,1);
  end;
end;


{ ***** }
procedure Draw_unit(_unit:PUnit);
{ vykresli jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  XSize, YSize (v polickach), natoceni Direction a predloha je v poli
  Unit_picures; procedura kontroluje, zda je jednotka na obrazovce;
  pokud ne, tak ji nevykresli, jinak vykresli jeji viditelnou cast
}
var IBegin, JBegin, X, Y, XPom, YPom, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem, Ind: Word;
    { pro potreby vykreslovani }
    Level:Byte;
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    ISizeAdd, JSizeAdd:Word;
    Color:Byte;
begin
 IBegin:=IBeg; JBegin:=JBeg;
 with (_unit^) do begin
  with Unit_types[UnitType,Races[Race].Ally] do begin
     ISize:=IUnitSize; JSize:=JUnitSize;
     XSize:=XUnitSize; YSize:=YUnitSize;
     if (XSize > ISize shl XCellShl) then ISizeAdd:=1 else ISizeAdd:=0;
     if (YSize > JSize shl YCellShl) then JSizeAdd:=1 else JSizeAdd:=0;
     Ind:=PictureIndex;
     Level:=TargetType;
  end;
  X:=IPos shl XCellShl + XOffset; Y:=JPos shl YCellShl + YOffset;
  if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
  na zacatku policka a tim zasahuje i do policka dalsiho }
  if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
  na zacatku policka a tim zasahuje i do policka dalsiho }
  if (Visibility and (X < (IBeg+IScreenSize) shl XCellShl) and
      (Y < (JBeg+JScreenSize) shl XCellShl) and
      ((X+XSize) >= IBeg shl XCellShl) and
      ((Y+YSize) >= JBeg shl YCellShl)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}

{ ** ODSTRANENI PRIPADNYCH LETAJICICH OBJEKTU Z POZADI }
      { provede se automaticky prekreslenim pozadi }
      XPom:=(X+XMemBeg)-IBeg shl XCellShl;
      YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
      if (Level <> 3) then begin
         DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, False);{}
         Real_Draw(_unit,X,Y,ISize,JSize,Ind,False);{}
         if (FlashFlag <> 0) then Flash(_unit,X,Y,True);
         if (FirePhase <> 0) then
           if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
           { pozemni jednotka }
             case (FirePhase) of
                 1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                 2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                 3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                 4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
               end;
           end else begin { letecka jednotka }
              case (FirePhase) of
                   1 : SpeedPutImage2Mem(XPom,YPom,Fire.S21,Fire.O21);
                   2 : SpeedPutImage2Mem(XPom,YPom,Fire.S22,Fire.O22);
                   3 : SpeedPutImage2Mem(XPom,YPom,Fire.S23,Fire.O23);
                   4 : SpeedPutImage2Mem(XPom,YPom,Fire.S24,Fire.O24);
               end;
           end;
         { if (FirePhase <> 0) then }
         if (Races[MyRace].Friend[Race] = 0) then Color:=80
         else if (Races[MyRace].Friend[Race] = 1) then Color:=67
              else Color:=240;
         if (UniqueNumber <> 65535) then Color:=98;
         if (Group = ActiveGroup) then
            FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,XSize shr 3 + FrameAdd,Color);
         Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
      end else begin
         Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
         if (FlashFlag <> 0) then Flash(_unit,X,Y,True);
      end;

      { ** PRENOS HOTOVEHO OBRAZKU Z PAMETI NA OBRAZOVKU }
      GraphQueue.Insert(IPos,JPos,IPos+ISize+ISizeAdd-1,JPos+JSize+JSizeAdd-1,1);{}
   end;
  end; { with }
end;

{ ***** }
procedure Erase_unit(_unit : PUnit; Draw : Boolean);
{ smaze jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  ISize, JSize (v polickach); procedura kontroluje, zda je jednotka na
  obrazovce; pokud ne, tak ji nevykresli, jinak vykresli jeji viditelnou
  cast;
  Promenna Draw urcuje, zda se obraz prenese z pameti na obrazovku nebo ne
}
var X, Y, XSize, YSize, ISize, JSize, Ind : Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    Level, Presah2 : Byte;
    ISizeAdd,JSizeAdd : Word;
begin
  with (_unit^) do begin
    Locate:='Erase_unit'; save2:=0;
    with Unit_types[UnitType,Races[Race].Ally] do begin
       ISize:=IUnitSize; JSize:=JUnitSize;
       XSize:=XUnitSize; YSize:=YUnitSize;
       if (XSize > ISize shl XCellShl) then ISizeAdd:=1 else ISizeAdd:=0;
       if (YSize > JSize shl YCellShl) then JSizeAdd:=1 else JSizeAdd:=0;
       Ind:=PictureIndex;
       Level:=TargetType;
       Presah2:=OvrSize;
    end; save2:=1;
    X:=IPos shl XCellShl+XOffset; Y:=JPos shl YCellShl+YOffset;
    if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
    na zacatku policka a tim zasahuje i do policka dalsiho }
    if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
    na zacatku policka a tim zasahuje i do policka dalsiho }
    save2:=2; Locate:='Erase_unit';
    if ((Visibility or Eras) and (X < (IBeg+IScreenSize) shl XCellShl) and
        (Y < (JBeg+JScreenSize) shl XCellShl) and
        ((X+XSize) >= IBeg shl XCellShl) and
        ((Y+YSize) >= JBeg shl YCellShl)) then begin
     { obrazek je na obrazovce }
       { ** smazani jednotky }
       Eras:=False;
       { vykresleni pozadi }
       Inc(Temp);
       save2:=3; Locate:='Erase_unit';
       DrawBck(IPos,JPos,IPos+ISize,JPos+JSize,True);
       save2:=4; Locate:='Erase_unit';
       Clear_surroundings(IPos,JPos,XOffset,YOffset,Presah2);{}{}
       save2:=5; Locate:='Erase_unit';
       Dec(Temp);
       if (Level <> 3) then begin
         save2:=6; Locate:='Erase_unit';
         Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
       end else begin
         Inc(Temp); save2:=7; Locate:='Erase_unit';
         Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);{}
         Dec(Temp);
         save2:=8; Locate:='Erase_unit';
         Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,1);
       end;
       save2:=9; Locate:='Erase_unit';
       GraphQueue.Insert(IPos,JPos,IPos+ISize-1,JPos+JSize-1,1);
    end;
  end; { with }
  Locate:=''; save2:=0;
end;

{ ***** }
procedure ReDraw_unit(_unit:PUnit; Draw:Boolean);
{ prekresli jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  ISize, JSize (v polickach), natoceni Direction a predloha je v poli
  Unit_picures; procedura kontroluje, zda je jednotka na obrazovce;
  pokud ne, tak ji nevykresli, jinak vykresli jeji viditelnou cast.
  Tuto proceduru je vhodne pouzit pro prekresleni jednotky na stejne pozici.
  >>? Pokud je Draw=True, vykresli se vse, jinak se vykresli pouze
  "selectovaci" obdelnik okolo jednotky (je-li v aktivni skupine) ?<<
  DRAW NEMA ZADNY VLIV!
}
var X, Y, XPom, YPom, XSize, YSize, ISize, JSize, Ind : Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    Level,Presah2 : Byte;
    ISizeAdd,JSizeAdd:Word;
    Color:Byte;
begin
 with (_unit^) do begin
   bebex:=40000;
   with Unit_types[UnitType,Races[Race].Ally] do begin
      ISize:=IUnitSize; JSize:=JUnitSize;
      XSize:=XUnitSize; YSize:=YUnitSize;
      if (XSize > ISize shl XCellShl) then ISizeAdd:=1 else ISizeAdd:=0;
      if (YSize > JSize shl YCellShl) then JSizeAdd:=1 else JSizeAdd:=0;
      Ind:=PictureIndex;
      Level:=TargetType;
      Presah2:=OvrSize;
   end;
   bebex:=40001;
   X:=IPos shl XCellShl+XOffset; Y:=JPos shl YCellShl+YOffset;
   if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
   na zacatku policka a tim zasahuje i do policka dalsiho }
   if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
   na zacatku policka a tim zasahuje i do policka dalsiho }
   bebex:=40002;
     if (Visibility and (X < (IBeg+IScreenSize) shl XCellShl) and
         (Y < (JBeg+JScreenSize) shl XCellShl) and
         ((X+XSize) >= IBeg shl XCellShl) and
         ((Y+YSize) >= JBeg shl YCellShl)) then begin
     bebex:=40003;
     { ** vykresleni jednotky }
     XPom:=(X+XMemBeg)-IBeg shl XCellShl;
     YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
     Draw:=True;
     if (Draw) then begin
        bebex:=40004;
        if (Level <> 3) then begin
           bebex:=40005;
           DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, False);
           bebex:=40006;
           Inc(Temp);
           Clear_surroundings(IPos,JPos,XOffset,YOffset,Presah2);
           bebex:=40007;
           Dec(Temp);
           Real_Draw(_unit,X,Y,ISize,JSize,Ind,False);
           if (FlashFlag <> 0) then Flash(_unit,X,Y,True);
           bebex:=40008;
           if (FirePhase <> 0) then
             if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
             { pozemni jednotka }
               case (FirePhase) of
                  1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                  2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                  3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                  4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
                end;
             end else begin { letecka jednotka }
                case (FirePhase) of
                   1 : SpeedPutImage2Mem(XPom,YPom,Fire.S21,Fire.O21);
                   2 : SpeedPutImage2Mem(XPom,YPom,Fire.S22,Fire.O22);
                   3 : SpeedPutImage2Mem(XPom,YPom,Fire.S23,Fire.O23);
                   4 : SpeedPutImage2Mem(XPom,YPom,Fire.S24,Fire.O24);
                 end;
             end;
           { if (FirePhase <> 0) then }
           if (Races[MyRace].Friend[Race] = 0) then Color:=80
           else if (Races[MyRace].Friend[Race] = 1) then Color:=67
                else Color:=240;
           if (UniqueNumber <> 65535) then Color:=98;
           bebex:=40009;
           if (Group = ActiveGroup) then
               FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,XSize shr 3 + FrameAdd,Color);
           bebex:=40010;
           Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
        end else begin
           bebex:=40011;
           DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, True);
           Inc(Temp);
           bebex:=40012;
           Clear_surroundings(IPos,JPos,XOffset,YOffset,Presah2);
           bebex:=40013;
           Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
           Temp:=0;
           bebex:=40014;
           Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
           if (FlashFlag <> 0) then Flash(_unit,X,Y,True);
        end;
      end else begin
        bebex:=40015;
        if (Races[MyRace].Friend[Race] = 0) then Color:=80
           else if (Races[MyRace].Friend[Race] = 1) then Color:=67
                else Color:=240;
        if (UniqueNumber <> 65535) then Color:=98;
        bebex:=40016;
        if (Group = ActiveGroup) then
           FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,XSize shr 3 + FrameAdd,Color);
      end;
      bebex:=40017;
      GraphQueue.Insert(IPos,JPos,IPos+ISize+ISizeAdd-1,JPos+JSize+JSizeAdd-1,1);
    end; { if }
  end; { with }
end;

{ ***** }
procedure Redraw_unit_with_flash(_unit:PUnit; XX,YY,S,O:Word);
{ procedura prikresli k jednotce zablesky z S:O a vnitrnim posunem
  oproti levemu hornimu rohu XX,YY
}
var X, Y, XPom, YPom, XSize, YSize, ISize, JSize, Ind : Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    Level : Byte;
    ISizeAdd, JSizeAdd:Word;
    Color:Byte;
begin
 with (_unit^) do begin
   with Unit_types[UnitType,Races[Race].Ally] do begin
      ISize:=IUnitSize; JSize:=JUnitSize;
      XSize:=XUnitSize; YSize:=YUnitSize;
      if (XSize > ISize shl XCellShl) then ISizeAdd:=1 else ISizeAdd:=0;
      if (YSize > JSize shl YCellShl) then JSizeAdd:=1 else JSizeAdd:=0;
      Ind:=PictureIndex;
      Level:=TargetType;
   end;
   X:=IPos shl XCellShl+XOffset; Y:=JPos shl YCellShl+YOffset;
   if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
   na zacatku policka a tim zasahuje i do policka dalsiho }
   if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
   na zacatku policka a tim zasahuje i do policka dalsiho }

   if (Visibility and (X < (IBeg+IScreenSize) shl XCellShl) and
       (Y < (JBeg+JScreenSize) shl XCellShl) and
       ((X+XSize) >= IBeg shl XCellShl) and
       ((Y+YSize) >= JBeg shl YCellShl)) then begin

     { ** vykresleni jednotky }
     XPom:=(X+XMemBeg)-IBeg shl XCellShl;
     YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
     if (Level <> 3) then begin
        DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, False);
        Real_Draw(_unit,X,Y,ISize,JSize,Ind,False);
        Draw_flash(X+XX,Y+YY,S,O);{}

        if (FirePhase <> 0) then
           if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
           { pozemni jednotka }
             case (FirePhase) of
               1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
               2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
               3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
               4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
             end;
           end else begin { letecka jednotka }
              case (FirePhase) of
                1 : SpeedPutImage2Mem(XPom,YPom,Fire.S21,Fire.O21);
                2 : SpeedPutImage2Mem(XPom,YPom,Fire.S22,Fire.O22);
                3 : SpeedPutImage2Mem(XPom,YPom,Fire.S23,Fire.O23);
                4 : SpeedPutImage2Mem(XPom,YPom,Fire.S24,Fire.O24);
              end;
           end;
           { if (FirePhase <> 0) then }
        if (Races[MyRace].Friend[Race] = 0) then Color:=80
        else if (Races[MyRace].Friend[Race] = 1) then Color:=67
             else Color:=240;
        if (UniqueNumber <> 65535) then Color:=98;
        if (Group = ActiveGroup) then
            FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,XSize shr 3 + FrameAdd,Color);
        Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
     end else begin
        DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, False);
        Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
        Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
        Draw_flash(X+XX,Y+YY,S,O);
     end;
     GraphQueue.Insert(IPos,JPos,IPos+ISize+ISizeAdd-1,JPos+JSize+JSizeAdd-1,1);{}
   end; { if }
 end; { with }
end;

{ ***** }
procedure Draw_shot(Shot:PShots);
{ vykresli strelu na nove pozici XPos, YPos
}
var X, Y, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem, Ind: Word;
    { pro potreby vykreslovani }
    Level:Byte;
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
begin
 with (Shot^) do begin
  ISize:=1; JSize:=1;
  if (AttackLevel > 4) then begin
     XSize:=Explosions[AttackPicture].XShot;
     YSize:=Explosions[AttackPicture].YShot;
  end else begin
     XSize:=XMaxShot; YSize:=YMaxShot;
  end;
  X:=XPos; Y:=YPos; XOffset:=X mod XCellSize; YOffset:=Y mod YCellSize;
  if ((XOffset + XSize) > XCellSize) then Inc(ISize);
  if ((YOffset + YSize) > YCellSize) then Inc(JSize); {}
  if ((ISize+IPos-1) > IMax) then ISize:=1;
  if ((JSize+JPos-1) > JMax) then JSize:=1;

  if (Visibility and (AttackLevel > 0) and
      (IPos < (IBeg+IScreenSize)) and (JPos < (JBeg+JScreenSize)) and
      ((IPos+ISize) > IBeg) and ((JPos+JSize) > JBeg)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}

      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,7);
      { s flying objects se vykresli i strela }

      GraphQueue.Insert(IPos,JPos,IPos+ISize-1,JPos+JSize-1,1);
  end;
 end; { with }
end;

{ ***** }
procedure Erase_shot(Shot:PShots;Draw:Boolean);
{ smaze strelu na aktualni pozici; je-li Draw = True, smaze ji i na
  obrazovce, jinak ji smaze jen v pameti
}
var X, Y, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
begin
  with (Shot^) do begin
    ISize:=1; JSize:=1;
    if (AttackLevel > 4) then begin
       XSize:=Explosions[AttackPicture].XShot;
       YSize:=Explosions[AttackPicture].YShot;
    end else begin
       XSize:=XMaxShot; YSize:=YMaxShot;
    end;
    X:=XPos; Y:=YPos; XOffset:=X mod XCellSize; YOffset:=Y mod YCellSize;
    if ((XOffset + XSize) > XCellSize) then Inc(ISize);
    if ((YOffset + YSize) > YCellSize) then Inc(JSize);{}
    if ((ISize+IPos-1) > IMax) then ISize:=1;
    if ((JSize+JPos-1) > JMax) then JSize:=1;

    if (Visibility and (AttackLevel > 0) and
        (IPos < (IBeg+IScreenSize)) and (JPos < (JBeg+JScreenSize)) and
        ((IPos+ISize) > IBeg) and ((JPos+JSize) > JBeg)) then begin
       { obrazek je na obrazovce }

      { ** smazani strely }
      Inc(Temp);
      DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, True);{}
      Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Dec(Temp);
      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,10);

      GraphQueue.Insert(IPos,JPos,IPos+ISize-1,JPos+JSize-1,1);
    end;
  end; { with }
end;

{ ***** }
procedure Draw_explosion_shot(Shot:PShots);
{ vykresli explozi strely Shot
}
var IBegin, JBegin, X, Y, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem, Ind: Word;
    { pro potreby vykreslovani }
    Level:Byte;
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
begin
 IBegin:=IBeg; JBegin:=JBeg;
 with (Shot^) do begin
  ISize:=1; JSize:=1;
  if (AttackLevel > 4) then begin
     XSize:=Explosions[AttackPicture].XShot;
     YSize:=Explosions[AttackPicture].YShot;
  end else begin
     XSize:=XMaxShot; YSize:=YMaxShot;
  end;
  X:=XPos; Y:=YPos; XOffset:=X mod XCellSize; YOffset:=Y mod YCellSize;
  if (XOffset+XSize > XCellSize) then Inc(ISize);
  if (YOffset+YSize > YCellSize) then Inc(JSize);{}
  if ((ISize+IPos-1) > IMax) then ISize:=1;
  if ((JSize+JPos-1) > JMax) then JSize:=1;

  if (Visibility and (AttackPicture > 0) and
      (IPos < (IBeg+IScreenSize)) and (JPos < (JBeg+JScreenSize)) and
      ((IPos+ISize) > IBeg) and ((JPos+JSize) > JBeg)) then begin
  { obrazek je na obrazovce }

{ ** VLASTNI VYKRESLENI ** }
      DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, True);{}
      Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,True);
      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,7);
      { s flying objects se vykresli i exploze }

      GraphQueue.Insert(IPos,JPos,IPos+ISize-1,JPos+JSize-1,1);
  end;
 end; { with }
end;

{ ***** }
procedure Draw_building(Building:PBuilding);
{ vykresli budovu na jeji pozici IPos, JPos; procedura kontroluje,
  zda je budova na obrazovce; pokud ne, tak ji nevykresli,
  jinak vykresli jeji viditelnou cast;
  BuildPhase urcuje fazi, ve ktere se ma budova vykreslit:
  1-3 .. stavebni faze
  4,5 .. hotove faze
  6,7 .. poskozena budova

}
var I,J,IBegin, JBegin, X, Y, XAdd, YAdd, XSize, YSize, ISize, JSize, Pom: Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    PomX, PomY : Word;
    Color:Byte;
begin
 IBegin:=IBeg; JBegin:=JBeg;
 with (Building^) do begin
  with Building_types[BuildingType] do begin
     ISize:=IBuildingSize; JSize:=JBuildingSize;
     XSize:=XBuildingSize; YSize:=YBuildingSize;
  end;
  X:=IPos shl XCellShl; Y:=JPos shl YCellShl;
  if ((ISize = 3) and (JSize = 3)) then begin
      XAdd:=XCellSize shl 1; YAdd:=YCellSize shl 1;
  end else
     if ((ISize = 2) and (JSize = 2)) then begin
        XAdd:=XCellSize; YAdd:=YCellSize;
     end else
       if ((ISize = 2) and (JSize = 1)) then begin
         XAdd:=XCellSize; YAdd:=0;
       end else begin
         XAdd:=0; YAdd:=0;
       end;

  if (Visibility and (IPos < (IBegin+IScreenSize)) and
     (JPos < (JBegin+JScreenSize)) and
     ((IPos+ISize) > IBegin) and ((JPos+JSize) > JBegin)) then begin
  { pokud vykreslovany objekt lezi na obrazovce, delej :}

      PomX:=(X+XMemBeg)-IBeg shl XCellShl;
      PomY:=(Y+YMemBeg)-JBeg shl YCellShl;

      with (Building_types[BuildingType]) do begin
         for J:=1 to JSize do
           for I:=1 to ISize do with (Background[MapBck^[IPos+I-1,JPos+J-1].BckType])
           do begin
             SpeedPutImageMem(PomX+XCellSize*(I-1),PomY+YCellSize*(J-1),Segment,Offsets);
             { nastav oblast za prozkoumanou! }
           end;

         if (Activity) then begin
           case (BuildPhase) of
             1 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S1,O1,Races[Race].RaceColor);
                 end;
             2 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S2,O2,Races[Race].RaceColor);
                 end;
             3 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S3,O3,Races[Race].RaceColor);
                 end;
             4 : begin
                   with (SO[BuildAnimPhase]) do
                     SpeedPutImageMemUnit(PomX,PomY,S,O,Races[Race].RaceColor);
                 end;
             5 : begin
                   with (SO[BuildAnimPhase]) do
                     SpeedPutImageMemUnit(PomX,PomY,S,O,Races[Race].RaceColor);
                 end;
             6 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S6,O6,Races[Race].RaceColor);
                 end;
             7 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S7,O7,Races[Race].RaceColor);
                 end;
           end;
           if (FirePhase <> 0) then
             if (FirePhase = 1) then begin
                SpeedPutImage2Mem(PomX,PomY,Fire.SB1,Fire.OB1);
                if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB2,Fire.OB2);
             end else
               if (FirePhase = 2) then begin
                  SpeedPutImage2Mem(PomX,PomY,Fire.SB2,Fire.OB2);
                  if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB3,Fire.OB3);
               end else
                 if (FirePhase = 3) then begin
                   SpeedPutImage2Mem(PomX,PomY,Fire.SB3,Fire.OB3);
                   if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB4,Fire.OB4);
                 end else begin
                   SpeedPutImage2Mem(PomX,PomY,Fire.SB4,Fire.OB4);
                   if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB1,Fire.OB1);
                 end;
           if ((Repair) and (DrawRepair)) then begin
              case (DrawRepairFlag) of
                 0..2: SpeedPutImage2Mem(PomX,PomY,RepairH1Segment,RepairH1Offset);
                 3..5: SpeedPutImage2Mem(PomX,PomY,RepairH2Segment,RepairH2Offset);
                 6..8: SpeedPutImage2Mem(PomX,PomY,RepairH3Segment,RepairH3Offset);
                 9..11: SpeedPutImage2Mem(PomX,PomY,RepairH4Segment,RepairH4Offset);
                 12..14: SpeedPutImage2Mem(PomX,PomY,RepairH5Segment,RepairH5Offset);
              else
                Error(0,'unita grafika, faze opravy');
              end;
              if (XAdd <> 0) then
                 case (DrawRepairFlag) of
                    0..2: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH1Segment,RepairH1Offset);
                    3..5: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH2Segment,RepairH2Offset);
                    6..8: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH3Segment,RepairH3Offset);
                    9..11: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH4Segment,RepairH4Offset);
                    12..14: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH5Segment,RepairH5Offset);
                 else
                   Error(0,'unita grafika, faze opravy');
                 end;
              if (YAdd <> 0) then
                  case (DrawRepairFlag) of
                     0..2: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH1Segment,RepairH1Offset);
                     3..5: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH2Segment,RepairH2Offset);
                     6..8: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH3Segment,RepairH3Offset);
                     9..11: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH4Segment,RepairH4Offset);
                     12..14: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH5Segment,RepairH5Offset);
                  else
                    Error(0,'unita grafika, faze opravy');
                  end;
              if ((XAdd <> 0) and (YAdd <> 0)) then
                  case (DrawRepairFlag) of
                    0..2: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH1Segment,RepairH1Offset);
                    3..5: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH2Segment,RepairH2Offset);
                    6..8: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH3Segment,RepairH3Offset);
                    9..11: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH4Segment,RepairH4Offset);
                    12..14: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH5Segment,RepairH5Offset);
                 else
                   Error(0,'unita grafika, faze opravy');
                 end;
           end;
           Draw_surroundings(IPos,JPos,XAdd,YAdd,OvrSize,1);
           Draw_surroundings2(IPos,JPos,XAdd,YAdd,OvrSize,1);
           Draw_surroundings(IPos,JPos,XAdd,YAdd,OvrSize,2);
           Draw_surroundings2(IPos,JPos,XAdd,YAdd,OvrSize,2);
         end else with (Explosions2) do begin
         { budova exploduje - ruzne faze exploze }
            DrawBck_without_buildings(IPos,JPos,IPos+ISize,JPos+JSize,True);{}
            if (JSize < 2) then
              if (ISize > 1) then begin
                 SpeedPutImage2Mem(PomX+XCellSize,PomY,Small[Phase].S,Small[Phase].O);
                 SpeedPutImage2Mem(PomX,PomY,Small[Phase].S,Small[Phase].O);
              end else
                 SpeedPutImage2Mem(PomX,PomY,Small[Phase].S,Small[Phase].O)
            else
              if (JSize = 2) then
                SpeedPutImage2Mem(PomX,PomY,Medium[Phase].S,Medium[Phase].O)
              else
                if (JSize = 3) then SpeedPutImage2Mem(PomX,PomY,Big[Phase].S,Big[Phase].O);

            PomX:=(X+XMemBeg)-IBeg shl XCellShl;
            PomY:=(Y+YMemBeg)-JBeg shl YCellShl;
         end;
         { * zneviditelneni neviditelnych casti * }
         for J:=1 to JSize do
           for I:=1 to ISize do with (MapBck^[IPos+I-1,JPos+J-1]) do begin
             if (Fog_of_war) then begin
                Temporary:=Get_fog_index(IPos+I-1,JPos+J-1);
                if (Temporary < 255) then
                  SpeedPutImage2Mem(PomX+XCellSize*(I-1),PomY+YCellSize*(J-1),
                                    Grids[Temporary].GridSeg,Grids[Temporary].GridOfs);
             end;
             if ((AttackMarkBuilding <> Nil)and(AttackMarkBuilding^ = Building)) then begin
                if (AttackMarkPhase = 0) then begin
                   SpeedPutImage2Mem(PomX+(I-1)*XCellSize,PomY+(J-1)*YCellSize,SegAttack1Cursor,OffsAttack1Cursor)
                end else begin
                   SpeedPutImage2Mem(PomX+(I-1)*XCellSize,PomY+(J-1)*YCellSize,SegAttack2Cursor,OffsAttack2Cursor);
                end;
             end;
           end;

         if (Races[MyRace].Friend[Race] = 0) then Color:=80
         else if (Races[MyRace].Friend[Race] = 1) then Color:=67
              else Color:=240;
         if ((Group = ActiveGroup) and (Activity)) then
            FrameMem2(PomX,PomY+6,PomX+XSize-1,PomY+YSize-1,(ISize shl XCellShl) shr 3 + FrameAdd,Color);
      end;
      Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);{}

      GraphQueue.Insert(IPos,JPos,IPos+ISize-1,JPos+JSize-1,1);
  end;
 end; { with }
end;

{ ***** }
procedure Erase_building(Building : PBuilding);
{ smaze budovu na jeji pozici IPos, JPos (polickove); jednotka ma rozmery
  ISize, JSize (v polickach); procedura kontroluje, zda je jednotka na
  obrazovce; pokud ne, tak ji nevykresli, jinak vykresli jeji viditelnou
  cast;
  pozn !!! Pred vymazanim je treba budovu odstranit z mapy !!!
}
var X, Y, XSize, YSize, ISize, JSize : Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    Color:Byte;
begin
  with (Building^) do begin
    with Building_types[BuildingType] do begin
       ISize:=IBuildingSize; JSize:=JBuildingSize;
       XSize:=XBuildingSize; YSize:=YBuildingSize;
    end;

    Transfer_map_frame2(IPos,JPos,IPos+ISize-1,JPos+JSize-1);
  end; { with }
end;

{ ***** }
procedure ReDraw_building(Building:PBuilding; Draw:Boolean);
{ prekresli budovu na jeji pozici IPos, JPos (polickove);
  jednotka ma rozmery  ISize, JSize (v polickach); procedura kontroluje,
  zda je budova na obrazovce; pokud ne, tak ji nevykresli,
  jinak vykresli jeji viditelnou cast. Tuto proceduru je vhodne pouzit pro
  prekresleni budovy na stejne pozici. Pokud je Draw=True, vykresli se vse,
  jinak se vykresli pouze "selectovaci" obdelnik okolo budovy
  (je-li v aktivni skupine)
}
var I, J, X, Y, XAdd, YAdd, PomX, PomY, XSize, YSize, ISize, JSize : Word;
    { pro potreby ulozeni v pameti }
    XMem, YMem, XVRAM, YVRAM, XSizeMem, YSizeMem: Word;
    { pro potreby vykreslovani }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    Color:Byte;
begin
 with (Building^) do begin
   with Building_types[BuildingType] do begin
      ISize:=IBuildingSize; JSize:=JBuildingSize;
      XSize:=XBuildingSize; YSize:=YBuildingSize;
   end;
   X:=IPos shl XCellShl; Y:=JPos shl YCellShl;

   if (Visibility and (IPos < (IBeg+IScreenSize)) and
       (JPos < (JBeg+JScreenSize)) and
       ((IPos+ISize) > IBeg) and ((JPos+JSize) > JBeg) ) then begin

     { ** vykresleni budovy }
     PomX:=(X+XMemBeg)-IBeg shl XCellShl;
     PomY:=(Y+YMemBeg)-JBeg shl YCellShl;
     if ((ISize = 3) and (JSize = 3)) then begin
         XAdd:=XCellSize shl 1; YAdd:=YCellSize shl 1;
     end else
        if ((ISize = 2) and (JSize = 2)) then begin
           XAdd:=XCellSize; YAdd:=YCellSize;
        end else
          if ((ISize = 2) and (JSize = 1)) then begin
            XAdd:=XCellSize; YAdd:=0;
          end else begin
            XAdd:=0; YAdd:=0;
          end;


     if (Draw) then begin
       for J:=1 to JSize do
         for I:=1 to ISize do with (Background[MapBck^[IPos+I-1,JPos+J-1].BckType])
         do begin
           SpeedPutImageMem(PomX+XCellSize*(I-1),PomY+YCellSize*(J-1),Segment,Offsets);
           { nastav oblast za prozkoumanou! }
         end;

       with (Building_types[BuildingType]) do begin
         if (Activity) then begin
           case (BuildPhase) of
             1 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S1,O1,Races[Race].RaceColor);
                 end;
             2 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S2,O2,Races[Race].RaceColor);
                 end;
             3 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S3,O3,Races[Race].RaceColor);
                 end;
             4 : begin
                   with (SO[BuildAnimPhase]) do
                     SpeedPutImageMemUnit(PomX,PomY,S,O,Races[Race].RaceColor);
                 end;
             5 : begin
                   with (SO[BuildAnimPhase]) do
                     SpeedPutImageMemUnit(PomX,PomY,S,O,Races[Race].RaceColor);
                 end;
             6 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S6,O6,Races[Race].RaceColor);
                 end;
             7 : begin
                   SpeedPutImageMemUnit(PomX,PomY,S7,O7,Races[Race].RaceColor);
                 end;
           end;
           if (FirePhase <> 0) then
             if (FirePhase = 1) then begin
                SpeedPutImage2Mem(PomX,PomY,Fire.SB1,Fire.OB1);
                if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB2,Fire.OB2);
             end else
               if (FirePhase = 2) then begin
                  SpeedPutImage2Mem(PomX,PomY,Fire.SB2,Fire.OB2);
                  if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB3,Fire.OB3);
               end else
                 if (FirePhase = 3) then begin
                   SpeedPutImage2Mem(PomX,PomY,Fire.SB3,Fire.OB3);
                   if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB4,Fire.OB4);
                 end else begin
                   SpeedPutImage2Mem(PomX,PomY,Fire.SB4,Fire.OB4);
                   if (FireState = 2) then SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,Fire.SB1,Fire.OB1);
                 end;
           if ((Repair) and (DrawRepair)) then begin
              case (DrawRepairFlag) of
                 0..2: SpeedPutImage2Mem(PomX,PomY,RepairH1Segment,RepairH1Offset);
                 3..5: SpeedPutImage2Mem(PomX,PomY,RepairH2Segment,RepairH2Offset);
                 6..8: SpeedPutImage2Mem(PomX,PomY,RepairH3Segment,RepairH3Offset);
                 9..11: SpeedPutImage2Mem(PomX,PomY,RepairH4Segment,RepairH4Offset);
                 12..14: SpeedPutImage2Mem(PomX,PomY,RepairH5Segment,RepairH5Offset);
              else
                Error(0,'unita grafika, faze opravy');
              end;
              if (XAdd <> 0) then
                 case (DrawRepairFlag) of
                    0..2: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH1Segment,RepairH1Offset);
                    3..5: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH2Segment,RepairH2Offset);
                    6..8: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH3Segment,RepairH3Offset);
                    9..11: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH4Segment,RepairH4Offset);
                    12..14: SpeedPutImage2Mem(PomX+XAdd,PomY,RepairH5Segment,RepairH5Offset);
                 else
                   Error(0,'unita grafika, faze opravy');
                 end;
              if (YAdd <> 0) then
                  case (DrawRepairFlag) of
                     0..2: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH1Segment,RepairH1Offset);
                     3..5: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH2Segment,RepairH2Offset);
                     6..8: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH3Segment,RepairH3Offset);
                     9..11: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH4Segment,RepairH4Offset);
                     12..14: SpeedPutImage2Mem(PomX,PomY+YAdd,RepairH5Segment,RepairH5Offset);
                  else
                    Error(0,'unita grafika, faze opravy');
                  end;
              if ((XAdd <> 0) and (YAdd <> 0)) then
                  case (DrawRepairFlag) of
                    0..2: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH1Segment,RepairH1Offset);
                    3..5: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH2Segment,RepairH2Offset);
                    6..8: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH3Segment,RepairH3Offset);
                    9..11: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH4Segment,RepairH4Offset);
                    12..14: SpeedPutImage2Mem(PomX+XAdd,PomY+YAdd,RepairH5Segment,RepairH5Offset);
                 else
                   Error(0,'unita grafika, faze opravy');
                 end;
           end;
           Draw_surroundings(IPos,JPos,XAdd,YAdd,OvrSize,1);
           Draw_surroundings2(IPos,JPos,XAdd,YAdd,OvrSize,1);
           Draw_surroundings(IPos,JPos,XAdd,YAdd,OvrSize,2);
           Draw_surroundings2(IPos,JPos,XAdd,YAdd,OvrSize,2);{}
         end else with (Explosions2) do begin
         { budova exploduje - ruzne faze exploze }
            DrawBck_without_buildings(IPos,JPos,IPos+ISize,JPos+JSize,True);{}
            if (JSize < 2) then
              if (ISize > 1) then begin
                 SpeedPutImage2Mem(PomX+XCellSize,PomY,Small[Phase].S,Small[Phase].O);
                 SpeedPutImage2Mem(PomX,PomY,Small[Phase].S,Small[Phase].O);
              end else
                 SpeedPutImage2Mem(PomX,PomY,Small[Phase].S,Small[Phase].O)
            else
              if (JSize = 2) then
                SpeedPutImage2Mem(PomX,PomY,Medium[Phase].S,Medium[Phase].O)
              else
                if (JSize = 3) then SpeedPutImage2Mem(PomX,PomY,Big[Phase].S,Big[Phase].O);

            PomX:=(X+XMemBeg)-IBeg shl XCellShl;
            PomY:=(Y+YMemBeg)-JBeg shl YCellShl;
         end;
         { * zneviditelneni neviditelnych casti * }
         for J:=1 to JSize do
           for I:=1 to ISize do with (MapBck^[IPos+I-1,JPos+J-1]) do begin
             if (Fog_of_war) then begin
                Temporary:=Get_fog_index(IPos+I-1,JPos+J-1);
                if (Temporary < 255) then
                  SpeedPutImage2Mem(PomX+XCellSize*(I-1),PomY+YCellSize*(J-1),
                                    Grids[Temporary].GridSeg,Grids[Temporary].GridOfs);
             end;
             if ((AttackMarkBuilding <> Nil)and(AttackMarkBuilding^ = Building)) then begin
                if (AttackMarkPhase = 0) then begin
                   SpeedPutImage2Mem(PomX+(I-1)*XCellSize,PomY+(J-1)*YCellSize,SegAttack1Cursor,OffsAttack1Cursor)
                end else begin
                   SpeedPutImage2Mem(PomX+(I-1)*XCellSize,PomY+(J-1)*YCellSize,SegAttack2Cursor,OffsAttack2Cursor);
                end;
             end;
           end;

         if (Races[MyRace].Friend[Race] = 0) then Color:=80
         else if (Races[MyRace].Friend[Race] = 1) then Color:=67
              else Color:=240;
         if ((Group = ActiveGroup) and (Activity)) then
            FrameMem2(PomX,PomY+6,PomX+XSize-1,PomY+YSize-1,(ISize shl XCellShl) shr 3 + FrameAdd,Color);
       end;
       Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);{}
       GraphQueue.Insert(IPos,JPos,IPos+ISize-1,JPos+JSize-1,1);
     end else begin
        if (Races[MyRace].Friend[Race] = 0) then Color:=80
        else if (Races[MyRace].Friend[Race] = 1) then Color:=67
             else Color:=240;
        if (Group = ActiveGroup) then
           FrameMem2(PomX,PomY+6,PomX+XSize-1,PomY+YSize-1,(ISize shl XCellShl) shr 3 + FrameAdd,Color);
     end;
    end; { if }
  end; { with }
end;

{ ***** }
procedure Force_draw_unit(_unit:PUnit);
{ vykresli jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  ISize, JSize (v polickach), natoceni Direction a predloha je v poli
  Unit_picures; jednotka se do pameti vykresli nasilne cela; nevykresli
  se na obrazovku
}
var X, Y, XPom, YPom, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    Ind:Word;
    Level : Byte;
    Color:Byte;
begin
 if (_unit^.Visibility) then with (_unit^) do begin
     with Unit_types[UnitType,Races[Race].Ally] do begin
        ISize:=IUnitSize; JSize:=JUnitSize;
        XSize:=XUnitSize; YSize:=YUnitSize;
        Ind:=PictureIndex;
        Level:=TargetType;
     end;
     X:=IPos shl XCellShl+XOffset; Y:=JPos shl YCellShl+YOffset;
     if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
     na zacatku policka a tim zasahuje i do policka dalsiho }
     if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
     na zacatku policka a tim zasahuje i do policka dalsiho }

{ ** ODSTRANENI PRIPADNYCH LETAJICICH OBJEKTU Z POZADI }
      { provede se automaticky prekreslenim pozadi }
      XPom:=(X+XMemBeg)-IBeg shl XCellShl;
      YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
      if (Level <> 3) then begin
         DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, False);
         Real_Draw(_unit,X,Y,ISize,JSize,Ind,False);
         if (FlashFlag <> 0) then Flash(_unit,X,Y,True);

         if (FirePhase <> 0) then
           if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
           { pozemni jednotka }
              case (FirePhase) of
                1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
              end;
           end else begin { letecka jednotka }
              case (FirePhase) of
                 1 : SpeedPutImage2Mem(XPom,YPom,Fire.S21,Fire.O21);
                 2 : SpeedPutImage2Mem(XPom,YPom,Fire.S22,Fire.O22);
                 3 : SpeedPutImage2Mem(XPom,YPom,Fire.S23,Fire.O23);
                 4 : SpeedPutImage2Mem(XPom,YPom,Fire.S24,Fire.O24);
               end;
           end;
         { if (FirePhase <> 0) then }
         if (Races[MyRace].Friend[Race] = 0) then Color:=80
         else if (Races[MyRace].Friend[Race] = 1) then Color:=67
              else Color:=240;
         if (UniqueNumber <> 65535) then Color:=98;
         if (Group = ActiveGroup) then
             FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,XSize shr 3 + FrameAdd,Color);
         Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
      end else begin
         DrawBck(IPos,JPos,IPos+ISize,JPos+JSize,False);
         Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,False);
         Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
         if (FlashFlag <> 0) then Flash(_unit,X,Y,True);
      end;

  end; { with }
end;

{ ***** }
procedure Force_erase_unit(_unit : PUnit);
{ smaze jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  ISize, JSize (v polickach); jednotka se do pameti vykresli nasilne cela;
  nevykresli se vsak na obrazovku
}
var X, Y, XSize, YSize, ISize, JSize, Ind : Word;
    { pro potreby ulozeni v pameti }
    Level, Presah2 : Byte;
begin
  if (_unit^.Visibility or _unit^.Eras) then with (_unit^) do begin
      Eras:=False;
      with Unit_types[UnitType,Races[Race].Ally] do begin
         ISize:=IUnitSize; JSize:=JUnitSize;
         XSize:=XUnitSize; YSize:=YUnitSize;
         Ind:=PictureIndex;
         Level:=TargetType;
         Presah2:=OvrSize;
      end;
      X:=IPos shl XCellShl+XOffset; Y:=JPos shl YCellShl+YOffset;
      if (XOffset <> 0) then Inc(ISize); { jednotka diky offsetu nezacina
      na zacatku policka a tim zasahuje i do policka dalsiho }
      if (YOffset <> 0) then Inc(JSize); { jednotka diky offsetu nezacina
      na zacatku policka a tim zasahuje i do policka dalsiho }

     { ** smazani jednotky }
     { vykresleni pozadi }
     Inc(Temp);
     DrawBck(IPos,JPos,IPos+ISize,JPos+JSize,True);
     Clear_surroundings(IPos,JPos,XOffset,YOffset,Presah2);
     Dec(Temp);
     if (Level <> 3) then begin
        Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
     end else Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,False);

  end; { with }
end;

{ ***** }
procedure Force_redraw_unit(_unit:PUnit);
{ prekresli jednotku na jeji pozici IPos, JPos (polickove) s prihlednutim
  k offsetu XOffset, YOffset uvnitr policka (bodove); jednotka ma rozmery
  ISize, JSize (v polickach), natoceni Direction a predloha je v poli
  Unit_picures; jednotka se do pameti vykresli nasilne cela; nevykresli
  se vsak na obrazovku.
  Tuto proceduru je vhodne pouzit pro prekresleni jednotky na stejne pozici.
}
var X, Y, XPom, YPom, XSize, YSize, ISize, JSize, Ind : Word;
    { pro potreby ulozeni v pameti }
    MouseOff:Boolean; { True, je-li treba smazat kurzor mysi }
    Level, Presah2 : Byte;
    Color:Byte;
begin
 if (_unit^.Visibility) then with (_unit^) do begin
     with Unit_types[UnitType,Races[Race].Ally] do begin
        ISize:=IUnitSize; JSize:=JUnitSize;
        XSize:=XUnitSize; YSize:=YUnitSize;
        Ind:=PictureIndex;
        Level:=TargetType;
        Presah2:=OvrSize;
     end;
     X:=IPos shl XCellShl + XOffset; Y:=JPos shl YCellShl + YOffset;

     { ** odstraneni pripadnych letajicich objektu z pozadi }
     { provede se automaticky }

     { ** vykresleni jednotky }
     XPom:=(X+XMemBeg)-IBeg shl XCellShl;
     YPom:=(Y+YMemBeg)-JBeg shl YCellShl;
     if (Level <> 3) then begin
        DrawBck(IPos,JPos,IPos+ISize,JPos+JSize, False);
        Inc(Temp);
        Clear_surroundings(IPos,JPos,XOffset,YOffset,Presah2);
        Dec(Temp);
        Real_Draw(_unit,X,Y,ISize,JSize,Ind,False);
        if (FlashFlag <> 0) then Flash(_unit,X,Y,True);

        if (FirePhase <> 0) then
           if (Unit_Types[UnitType,Races[Race].Ally].TargetTyp <> 3) then begin
           { pozemni jednotka }
             case (FirePhase) of
                1 : SpeedPutImage2Mem(XPom,YPom,Fire.S1,Fire.O1);
                2 : SpeedPutImage2Mem(XPom,YPom,Fire.S2,Fire.O2);
                3 : SpeedPutImage2Mem(XPom,YPom,Fire.S3,Fire.O3);
                4 : SpeedPutImage2Mem(XPom,YPom,Fire.S4,Fire.O4);
              end;
           end else begin { letecka jednotka }
                 case (FirePhase) of
                1 : SpeedPutImage2Mem(XPom,YPom,Fire.S21,Fire.O21);
                2 : SpeedPutImage2Mem(XPom,YPom,Fire.S22,Fire.O22);
                3 : SpeedPutImage2Mem(XPom,YPom,Fire.S23,Fire.O23);
                4 : SpeedPutImage2Mem(XPom,YPom,Fire.S24,Fire.O24);
              end;
           end;
        { if (FirePhase <> 0) then }
        if (Races[MyRace].Friend[Race] = 0) then Color:=80
        else if (Races[MyRace].Friend[Race] = 1) then Color:=67
             else Color:=240;
        if (UniqueNumber <> 65535) then Color:=98;
        if (Group = ActiveGroup) then
           FrameMem2(XPom+OvrSize,YPom+OvrSize,XPom+XCellSize-1,YPom+YCellSize-1,
                     XSize shr 3 + FrameAdd,Color);
        Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
     end else begin
        DrawBck(IPos,JPos,IPos+ISize,JPos+JSize,False);
        Inc(Temp);
        Clear_surroundings(IPos,JPos,XOffset,YOffset,Presah2);
        Dec(Temp);
        Draw_ground_objects(IPos,JPos,IPos+ISize,JPos+JSize,False);
        Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
        if (FlashFlag <> 0) then Flash(_unit,X,Y,True);
     end;
     { ** vykresleni pripadnych letajicich objektu na pozadi }
  end; { with }
end;

{ ***** }
procedure Force_draw_shot(Shot:PShots);
{ vykresli strelu na jeji pozici IPos, JPos (polickove);
  strela se do pameti vykresli nasilne cela
}
var X, Y, XSize, YSize, ISize, JSize: Word;
    { pro potreby ulozeni v pameti }
    Ind:Word;
    Level : Byte;
begin
 if (Shot^.Visibility) then with (Shot^) do begin
   ISize:=1; JSize:=1;
   if (AttackLevel > 4) then begin
     XSize:=Explosions[AttackPicture].XShot;
     YSize:=Explosions[AttackPicture].YShot;
   end else begin
     XSize:=XMaxShot; YSize:=YMaxShot;
   end;
   X:=XPos; Y:=YPos; XOffset:=X mod XCellSize; YOffset:=Y mod YCellSize;
   if ((XOffset + XSize) > XCellSize) then Inc(ISize);
   if ((YOffset + YSize) > YCellSize) then Inc(JSize); {}

   Draw_flying_objects(IPos,JPos,IPos+ISize,JPos+JSize,3);
  end; { with }
end;

{ ***** }
procedure Altpress;
{ provede pomocne akce po znovuspusteni  breaknuteho programu
}
begin
   LoadRGB(0,'data\paleta1.rgb');
end;

{ ***** }
procedure Grafika_save;
{ pro potreby ulozeni hry
}
label K;

begin
   Assign(IOFile,'save\'+SavePath+'3'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); DResult:=IOResult;
end;

{ ***** }
procedure Grafika_load;
{ pro potreby ulozeni hry
}
label K;

begin
  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'3'); Reset(IOFile,1); DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;

K:
  Close(IOFile); Close(CheckFile); DResult:=IOResult;
end;

{ ************************************************************************* }
begin
   CursorPhase:=0; { animacni faze kurzoru }
   AnimCursorType:=NormalCursor;
   GraphQueue.Initialize;
end.