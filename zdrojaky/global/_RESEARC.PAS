unit _research;
{$C FIXED PRELOAD PERMANENT}
interface

const AROAttack=0; ARODefence=1; AROSight=2; AROEngine=3; AROSpecial=4;
      MaxItem=9;

type TAssignResearchObject =
         object
          private
            XName,YName:Word;
            YPrice,XPrice1,XPrice2,XPrice3,XPrice4:Word;
            SPriceBck, OPriceBck:Word;
            XPicture,YPicture:Word; { souradnice spec. obrazku }
            XPictureSize, YPictureSize:Word; { velikost spec. obrazku }
            SPictureBck, OPictureBck:Word;
            AssignStruct:array[0..4] of record { obrazovka prirad vyzkum
            konkretni jednotce, netreba ukladat save/load}
            { AROAttack, ARODefence, AROSight, AROEngine, AROSpecial }
               XName,YName:Word;  { nazev }
               { nyni policka vybranych vynalezu }
               XSelect1,YSelect1,X2Select1,Y2Select1:Word;
               XSelect2,YSelect2,X2Select2,Y2Select2:Word;
               X1Avail,Y1Avail,X2Avail,Y2Avail:Word; { pole volnych vynalezu }
               SAvail,OAvail:Word; { ulozene pozadi }
               ItemArray:array[0..MaxItem] of RECORD
                           X,Y,X2,Y2:Word;
                           V:Byte;
                         end;
               { seznam moznych vyzkumu pro prirazeni }
            end;
          public
            procedure Init; { inicializace }
            procedure InitItem; { inicializace }
            procedure GetAvailItems(Index:Byte); { inicializace }
            procedure InitDraw(Index:Word);
            procedure Draw(Index:Word);
            procedure MoveMouse(X,Y:Word); { mys se posunula na pozici X,Y }
            procedure ClickMouse(X,Y:Word; Button,Index:Byte);
         end;


procedure OSNResearchInit;
procedure RobotResearchInit;
procedure ResearchPanel;
procedure Draw_active_research(Rsrch:Byte; Proceed:Single; NewRsrch:Boolean);
procedure ResearchStep;

var AssignResearchObject : TAssignResearchObject;

implementation

uses Crt, Data_glb, GlobGraf, Specgraf, Buttons, Mouse, Graph257;

const YLineAdd = 2;
      ResearchXBoxSize = XResearchInfoSize-16;
      ResearchYBoxSize = (YFontSize+YLineAdd)*8+8;
      MaxResearchInfoBoxIndex = 1; { max. pocet boxu s informacemi
                                     o vyzkumu - 1 }
      MaxInfoStruct = 17;

var  ResearchAvail : array [1..MaxResearch] of Byte;
     MaxResearchAvailIndex:Byte; { maximalni dostupny vyzkum }
     CurrentResearchAvailIndex:Byte; { pomocna promenna }
     SelectedResearch:Byte; { zvoleny vyzkum }
     I, J:Word;
     ResearchInfoBox : array[0..MaxResearchInfoBoxIndex] of record
                         X,Y:Word; { Souradnice zacatku boxu }
                         RsrchId:Byte; { namapovane cislo vyzkumu }
                       end;
    InfoStruct:array[0..MaxInfoStruct] of record
    { pro potreby assign reserch, netreba ukladat save/load }
                 Activity:Boolean; { platnost }
                 Index:Byte; { typ jednotky }
                 X1,Y1,X2,Y2:Word; { souradnice obdelniku }
                 XPicture,YPicture,XText,YText:Word; { souradnice dat }
               end;

{ ***************************** PROCEDURY OBJEKTU ************************** }

procedure TAssignResearchObject.InitItem;
{
}
var I,J:Word;
begin
  for I:=0 to 4 do with (AssignStruct[I]) do begin
     for J:=0 to MaxItem do ItemArray[J].V:=0;
  end;
end;

{ ***** }
procedure TAssignResearchObject.GetAvailItems(Index:Byte); { inicializace }
{
}
var I,J,Row,K_:Word;
    Availab:Boolean;
    A:Byte;
begin
  for I:=0 to 4 do with (AssignStruct[I]) do begin
     for J:=0 to MaxItem do begin
       ItemArray[J].V:=0; ItemArray[J].X:=0; ItemArray[J].Y:=0;
       ItemArray[J].X2:=0; ItemArray[J].Y2:=0;
     end;
  end;
  {x}
  for I:=0 to 4 do with (AssignStruct[I]) do
  with (ReserchAssign[Index,1]) do begin
    case (I) of
      0 : begin { utok }
            Row:=0;
            for K_:=1 to MaxResearch do with (Research^[K_]) do
            if (Validity and (PercState=100) and (Tag = 0) and
                ((Unit_target_types[Index] in EnabledFor) or
                 (Index in EnabledFor)) and
                (K_ <> Attack1) and (K_ <> Attack2)) then begin
              Availab:=True;
              for J:=0 to MaxResearchHate do begin
                if ((Attack1 > 0) and (Hate[J] = Attack1) or
                    (Attack2 > 0) and (Hate[J] = Attack2)) then Availab:=False;
              end;
              A:=Lo(K_);
              if (Availab) then begin ItemArray[Row].V:=A; Inc(Row); end;{}
            end;
          end;
      1 : begin { obrana }
            Row:=0;
            for K_:=1 to MaxResearch do with (Research^[K_]) do
            if (Validity and (PercState=100) and (Tag = 1) and
                ((Unit_target_types[Index] in EnabledFor) or
                 (Index in EnabledFor)) and
                (K_ <> Defence1) and (K_ <> Defence2)) then begin
              Availab:=True;
              for J:=0 to  MaxResearchHate do begin
                if ((Defence1 > 0) and (Hate[J] = Defence1) or
                    (Defence2 > 0) and (Hate[J] = Defence2)) then Availab:=False;
              end; A:=Lo(K_);
              if (Availab) then begin ItemArray[Row].V:=A; Inc(Row); end;{}
            end;
          end;
      2 : begin { dohled }
            Row:=0;
            for K_:=1 to MaxResearch do with (Research^[K_]) do
            if (Validity and (PercState=100) and (Tag = 2) and
                ((Unit_target_types[Index] in EnabledFor) or
                 (Index in EnabledFor)) and
                (K_ <> Sight1) and (K_ <> Sight2)) then begin
              Availab:=True;
              for J:=0 to MaxResearchHate do begin
                if ((Sight1 > 0) and (Hate[J] = Sight1) or
                    (Sight2 > 0) and (Hate[J] = Sight2)) then Availab:=False;
              end; A:=Lo(K_);
              if (Availab) then begin ItemArray[Row].V:=A; Inc(Row); end;{}
            end;
          end;
      3 : begin { pohon }
            Row:=0;
            for K_:=1 to MaxResearch do with (Research^[K_]) do
            if (Validity and (PercState=100) and (Tag = 3) and
                ((Unit_target_types[Index] in EnabledFor) or
                 (Index in EnabledFor)) and
                (K_ <> Engine1) and (K_ <> Engine2)) then begin
              Availab:=True;
              for J:=0 to MaxResearchHate do begin
                if ((Engine1 > 0) and (Hate[J] = Engine1) or
                    (Engine2 > 0) and (Hate[J] = Engine2)) then Availab:=False;
              end; A:=Lo(K_);
              if (Availab) then begin ItemArray[Row].V:=A; Inc(Row); end;{}
            end;
          end;
      4 : begin { specialni }
            Row:=0;
            for K_:=1 to MaxResearch do with (Research^[K_]) do
            if (Validity and (PercState=100) and (Tag = 4) and
                ((Unit_target_types[Index] in EnabledFor) or
                 (Index in EnabledFor)) and
                (K_ <> Special1) and (K_ <> Special2)) then begin
              Availab:=True;
              for J:=0 to MaxResearchHate do begin
                if ((Special1 > 0) and (Hate[J] = Special1) or
                    (Special2 > 0) and (Hate[J] = Special2)) then Availab:=False;
              end; A:=Lo(K_);
              if (Availab) then begin ItemArray[Row].V:=A; Inc(Row); end;{}
            end;
          end;
    end;
  end;
end;

{ ***** }
procedure TAssignResearchObject.Init;
{
}
const XAssignResearchObjectSize = XResearchInfoSize;
      YAssignResearchObjectSize = YResearchInfoSize;
      XSize = XAssignResearchObjectSize div 5;
var I,X,Y,YSize:Word;
    M:LongInt;
begin
  InitItem;
  YSize:=(YResolution-YAssignResearchObjectSize) shr 1;
  X:=(XResolution-XAssignResearchObjectSize) shr 1 + 10;
  XName:=X+(XAssignResearchObjectSize-15*XFontSize) shr 1 - 12;
  YName:=YSize+8;
  XPictureSize:=XResearchInfoSize-8*XFontSize;
  XPicture:=X-10+(XResearchInfoSize-XPictureSize) shr 1;
  YPicture:=YSize+YFontSize*3-10; YPictureSize:=48;
  M:=LongInt(XPictureSize+1)*(YPictureSize+1)+4;
  GetMemory(M,SPictureBck, OPictureBck);
  if (SPictureBck = 0) then Error(0,'Nedostatek pameti');
  for I:=0 to 4 do with (AssignStruct[I]) do begin
     { nazev: }
     XName:=I*XSize+X; YName:=YPicture+10+YPictureSize;
     { nyni policka vybranych vynalezu: }
     XSelect1:=I*XSize+X; YSelect1:=YName+YFontSize+16;
     XSelect2:=XSelect1+13*XFontSize; YSelect2:=YSelect1+YFontSize+2;
     X2Select1:=I*XSize+X; Y2Select1:=YSelect2+8;
     X2Select2:=X2Select1+13*XFontSize; Y2Select2:=Y2Select1+YFontSize+2;
     { pole volnych vynalezu: }
     X1Avail:=I*XSize+X; Y1Avail:=Y2Select2+YFontSize shl 1 - 8;
     X2Avail:=X1Avail+13*XFontSize; Y2Avail:=Y1Avail+9*(YFontSize+2);
     M:=LongInt(X2Avail-X1Avail+1)*(Y2Avail-Y1Avail+1)+4;
     GetMemory(M,SAvail,OAvail);
     if (SAvail = 0) then Error(0,'Nedostatek pameti');
  end;
  YPrice:=AssignStruct[0].Y2Avail+YFontSize;
  X:=X+XSize-XFontSize*3;
  XPrice1:=X; XPrice2:=X+XSize;
  XPrice3:=X+XSize*2; XPrice4:=X+XSize*3;
  M:=LongInt(XPrice4+10*XFontSize-XPrice1+1)*(YFontSize+1)+4;
  GetMemory(M,SPriceBck, OPriceBck);
  if (SPriceBck = 0) then Error(0,'Nedostatek pameti');
end;

{ ***** }
procedure SetResearchAssignResult(Index:Word; Friend:Byte);
{ nastavi vliv prirazenych vynalezu na bojove parametry a cenu
  Friend = 0 pro nepratele a 1 pro mne
}
var I:Word;
    Ret:String;
begin
  with (ReserchAssign[Index,Friend]) do begin
    _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
    _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
  end;
  for I:=0 to 4 do with (AssignResearchObject.AssignStruct[I]) do
  with (ReserchAssign[Index,Friend]) do begin
     case (I) of
      0 : begin
            if (Attack1 > 0) then with (Research^[Attack1]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
            if (Attack2 > 0) then with (Research^[Attack2]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
          end;
      1 : begin
            OutTextColor(XName,YName,64,'   OBRANA    '); {}
            if (Defence1 > 0) then with (Research^[Defence1]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
            if (Defence2 > 0) then with (Research^[Defence2]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
          end;
      2 : begin
            if (Sight1 > 0) then with (Research^[Sight1]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
            if (Sight2 > 0) then with (Research^[Sight2]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
          end;
      3 : begin
            if (Engine1 > 0) then with (Research^[Engine1]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
            if (Engine2 > 0) then with (Research^[Engine2]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
          end;
      4 : begin
            if (Special1 > 0) then with (Research^[Special1]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
            if (Special2 > 0) then with (Research^[Special2]) do begin
               _u:=_u+u; _o:=_o+o; _k:=_k+k; _lu:=_lu+lu+u; _tu:=_tu+tu+u;
               _au:=_au+au+u; _r:=_r+r; _d:=_d+d; _h:=_h+h; _s:=_s+s;
               _BP:=_BP+BP; _EE:=_EE+EE; _PL:=_PL+PL; _Ex:=_Ex+Ex;
            end;
          end;
     end;
  end;

end;

{ ***** }
procedure TAssignResearchObject.InitDraw(Index:Word);
{
}
var I,J,X,Y,Row:Word;
    Ret:String;
    A:Single;
begin
   GetAvailItems(Index);
   SetResearchAssignResult(Index,1);
   CursorOff;
   X:=(15*XFontSize-Length(Unit_types^[Index,1].Name)*XFontSize) shr 1;
   OutTextColor(XName+X,YName,160,Unit_types^[Index,1].Name);
   SetColor(64);
   NLine(XName+X,YName+YFontSize,XName+Length(Unit_types^[Index,1].Name)*XFontSize+X,YName+YFontSize);
   Frame2(XPicture,YPicture,XPicture+XPictureSize,YPicture+YPictureSize,67);
   GetImage(XPicture,YPicture,XPicture+XPictureSize,YPicture+YPictureSize,SPictureBck,OPictureBck,NormalDirect);
   {x}
   Inc(XPicture,10); Inc(YPicture,4);
   with (ReserchAssign[Index,1]) do begin
       A:=_lu; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture,YPicture,64,'LU      +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture,YPicture,64,'LU       '+Ret+'%');{}
       A:=_tu; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+18*XFontSize,YPicture,64,'TU      +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture+18*XFontSize,YPicture,64,'TU       '+Ret+'%');{}
       A:=_au; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+36*XFontSize,YPicture,64,'AU      +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture+36*XFontSize,YPicture,64,'AU       '+Ret+'%');{}
       A:=_d; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+54*XFontSize,YPicture,64,'DOSTfEL +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture+54*XFontSize,YPicture,64,'DOSTfEL '+Ret+'%');{}
       {}
       A:=_o; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture,YPicture+YFontSize+2,64,'OBRANA  +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture,YPicture+YFontSize+2,64,'OBRANA  '+Ret+'%');{}
       A:=_s; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+18*XFontSize,YPicture+YFontSize+2,64,'DOHLED  +'+Ret)
       else if (A < 0) then OutTextColor(XPicture+18*XFontSize,YPicture+YFontSize+2,64,'DOHLED  '+Ret);{}
       A:=_k; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+36*XFontSize,YPicture+YFontSize+2,64,'KADENCE +'+Ret)
       else if (A < 0) then OutTextColor(XPicture+36*XFontSize,YPicture+YFontSize+2,64,'KADENCE '+Ret);{}
       A:=_r; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+54*XFontSize,YPicture+YFontSize+2,64,'RYCHLOST +'+Ret)
       else if (A < 0) then OutTextColor(XPicture+54*XFontSize,YPicture+YFontSize+2,64,'RYCHLOST '+Ret);{}
   end; Dec(XPicture,10); Dec(YPicture,4);
   {x}
   for I:=0 to 4 do with (AssignStruct[I]) do
   with (ReserchAssign[Index,1]) do begin
     { nazev: }
     Rectangle2(XSelect1,YSelect1,XSelect2,YSelect2,0);
     Rectangle2(X2Select1,Y2Select1,X2Select2,Y2Select2,0);
     case (I) of
         0 : begin
               OutTextColor(XName,YName,64,'    hTOK     '); {}
               if (Attack1 > 0) then with (Research^[Attack1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Attack1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Attack2 > 0) then with (Research^[Attack2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Attack2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         1 : begin
               OutTextColor(XName,YName,64,'   OBRANA    '); {}
               if (Defence1 > 0) then with (Research^[Defence1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Defence1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Defence2 > 0) then with (Research^[Defence2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Defence2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         2 : begin
               OutTextColor(XName,YName,64,'   DOHLED    '); {}
               if (Sight1 > 0) then with (Research^[Sight1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Sight1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Sight2 > 0) then with (Research^[Sight2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Sight2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         3 : begin
               OutTextColor(XName,YName,64,'    POHON    '); {}
               if (Engine1 > 0) then with (Research^[Engine1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Engine1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Engine2 > 0) then with (Research^[Engine2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Engine2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         4 : begin
               OutTextColor(XName,YName,64,'  SPECIaLNe  '); {}
               if (Special1 > 0) then
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Special1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Research^[Special1].Name);
               if (Special2 > 0) then
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Special2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Research^[Special2].Name);
             end;
     end;
     { nyni policka vybranych vynalezu: }
     Frame2(XSelect1,YSelect1,XSelect2,YSelect2,64);
     Frame2(X2Select1,Y2Select1,X2Select2,Y2Select2,64);
     Frame2(X1Avail,Y1Avail,X2Avail,Y2Avail,64);
     GetImage(X1Avail,Y1Avail,X2Avail,Y2Avail,SAvail,OAvail,NormalDirect);
     Row:=0;
     for J:=0 to MaxItem do begin
        if (ItemArray[J].V > 0) then with (ItemArray[J]) do begin
           X:=X1Avail+(X2Avail-X1Avail-Length(Research^[ItemArray[J].V].Name)*XFontSize) shr 1;
           Y:=Y1Avail+Row * (YFontSize+2);
           X2:=X+Length(Research^[ItemArray[J].V].Name)*XFontSize;
           Y2:=Y+YFontSize;
           OutTextColor(X,Y,64,Research^[ItemArray[J].V].Name);
           Inc(Row);
        end;
     end;
   end;
   with (ReserchAssign[Index,1]) do begin
      GetImage(XPrice1,YPrice,XPrice4+10*XFontSize,YPrice+YFontSize,SPriceBck,OPriceBck,NormalDirect);
      A:=_BP; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice1,YPrice,64,'BP: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice1,YPrice,64,'BP: '+Ret+'%');
      A:=_PL; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice2,YPrice,64,'PL: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice2,YPrice,64,'PL: '+Ret+'%');
      A:=_EE; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice3,YPrice,64,'EE: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice3,YPrice,64,'EE: '+Ret+'%');
      A:=_Ex; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice4,YPrice,64,'EX: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice4,YPrice,64,'EX: '+Ret+'%');
   end;
   CursorOn;
end;

{ ***** }
procedure TAssignResearchObject.Draw(Index:Word);
{
}
var I,J,X,Y,Row:Word;
    Ret:String;
    A:Single;
begin
   GetAvailItems(Index);
   SetResearchAssignResult(Index,1);
   CursorOff;
   { souradnice spec. obrazku: }
   PutImage(XPicture,YPicture,SPictureBck,OPictureBck,NormalDirect);{}
   {x}
   Inc(XPicture,10); Inc(YPicture,4);
   with (ReserchAssign[Index,1]) do begin
       A:=_lu; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture,YPicture,64,'LU      +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture,YPicture,64,'LU       '+Ret+'%');{}
       A:=_tu; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+18*XFontSize,YPicture,64,'TU      +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture+18*XFontSize,YPicture,64,'TU       '+Ret+'%');{}
       A:=_au; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+36*XFontSize,YPicture,64,'AU      +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture+36*XFontSize,YPicture,64,'AU       '+Ret+'%');{}
       A:=_d; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+54*XFontSize,YPicture,64,'DOSTfEL +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture+54*XFontSize,YPicture,64,'DOSTfEL '+Ret+'%');{}
       {}
       A:=_o; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture,YPicture+YFontSize+2,64,'OBRANA  +'+Ret+'%')
       else if (A < 0) then OutTextColor(XPicture,YPicture+YFontSize+2,64,'OBRANA  '+Ret+'%');{}
       A:=_s; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+18*XFontSize,YPicture+YFontSize+2,64,'DOHLED  +'+Ret)
       else if (A < 0) then OutTextColor(XPicture+18*XFontSize,YPicture+YFontSize+2,64,'DOHLED  '+Ret);{}
       A:=_k; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+36*XFontSize,YPicture+YFontSize+2,64,'KADENCE +'+Ret)
       else if (A < 0) then OutTextColor(XPicture+36*XFontSize,YPicture+YFontSize+2,64,'KADENCE '+Ret);{}
       A:=_r; Str(A:3:0,Ret); if (A > 0) then OutTextColor(XPicture+54*XFontSize,YPicture+YFontSize+2,64,'RYCHLOST +'+Ret)
       else if (A < 0) then OutTextColor(XPicture+54*XFontSize,YPicture+YFontSize+2,64,'RYCHLOST '+Ret);{}
   end; Dec(XPicture,10); Dec(YPicture,4);
   {x}
   for I:=0 to 4 do with (AssignStruct[I]) do
   with (ReserchAssign[Index,1]) do begin
     { nazev: }
     Rectangle2(XSelect1,YSelect1,XSelect2,YSelect2,0);
     Rectangle2(X2Select1,Y2Select1,X2Select2,Y2Select2,0);
     Frame2(XSelect1,YSelect1,XSelect2,YSelect2,64);
     Frame2(X2Select1,Y2Select1,X2Select2,Y2Select2,64);
     { nyni policka vybranych vynalezu: }
     PutImage(X1Avail,Y1Avail,SAvail,OAvail,NormalDirect);{}
     case (I) of
          0 : begin
               {OutTextColor(XName,YName,64,'    hTOK     '); {}
               if (Attack1 > 0) then with (Research^[Attack1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Attack1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Attack2 > 0) then with (Research^[Attack2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Attack2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         1 : begin
               {OutTextColor(XName,YName,64,'   OBRANA    '); {}
               if (Defence1 > 0) then with (Research^[Defence1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Defence1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Defence2 > 0) then with (Research^[Defence2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Defence2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         2 : begin
               {OutTextColor(XName,YName,64,'   DOHLED    '); {}
               if (Sight1 > 0) then with (Research^[Sight1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Sight1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Sight2 > 0) then with (Research^[Sight2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Sight2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         3 : begin
               {OutTextColor(XName,YName,64,'    POHON    '); {}
               if (Engine1 > 0) then with (Research^[Engine1]) do begin
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Engine1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Name);
               end;
               if (Engine2 > 0) then with (Research^[Engine2]) do begin
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Engine2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Name);
               end;
             end;
         4 : begin
               {OutTextColor(XName,YName,64,'  SPECIaLNe  '); {}
               if (Special1 > 0) then
                  OutTextColor(XSelect1+(XSelect2-XSelect1-Length(Research^[Special1].Name)*XFontSize) shr 1,
                               YSelect1+(YSelect2-YSelect1-YFontSize) shr 1,
                               160,Research^[Special1].Name);
               if (Special2 > 0) then
                  OutTextColor(X2Select1+(X2Select2-X2Select1-Length(Research^[Special2].Name)*XFontSize) shr 1,
                               Y2Select1+(Y2Select2-Y2Select1-YFontSize) shr 1,
                               160,Research^[Special2].Name);
             end;
     end;
     Row:=0;
     for J:=0 to MaxItem do begin
        if (ItemArray[J].V > 0) then with (ItemArray[J]) do begin
           X:=X1Avail+(X2Avail-X1Avail-Length(Research^[ItemArray[J].V].Name)*XFontSize) shr 1;
           Y:=Y1Avail+Row * (YFontSize+2);
           X2:=X+Length(Research^[ItemArray[J].V].Name)*XFontSize;
           Y2:=Y+YFontSize;
           OutTextColor(X,Y,64,Research^[ItemArray[J].V].Name);
           Inc(Row);
        end;
     end;
     PutImage(XPrice1,YPrice,SPriceBck,OPriceBck,NormalDirect);
  end;
  with (ReserchAssign[Index,1]) do begin
      PutImage(XPrice1,YPrice,SPriceBck,OPriceBck,NormalDirect);
      A:=_BP; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice1,YPrice,64,'BP: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice1,YPrice,64,'BP: '+Ret+'%');
      A:=_PL; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice2,YPrice,64,'PL: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice2,YPrice,64,'PL: '+Ret+'%');
      A:=_EE; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice3,YPrice,64,'EE: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice3,YPrice,64,'EE: '+Ret+'%');
      A:=_Ex; Str(A:3:0,Ret);
      if (A > 0) then OutTextColor(XPrice4,YPrice,64,'EX: +'+Ret+'%')
      else if (A < 0) then OutTextColor(XPrice4,YPrice,64,'EX: '+Ret+'%');
   end;

  CursorOn;
end;

{ ***** }
procedure TAssignResearchObject.MoveMouse(X,Y:Word);
{
}
begin
end;

{ ***** }
procedure TAssignResearchObject.ClickMouse(X,Y:Word; Button,Index:Byte);
{
}
var I,J :Word;
    DrawIt:Boolean;
    Continue:Boolean;
begin
   DrawIt:=False;
   for I:=0 to 4 do with (AssignStruct[I]) do
   with (ReserchAssign[Index,1]) do begin
     case (I) of
         0 : begin
               if (Attack1 > 0) then begin
                 if (TestMouse(XSelect1,YSelect1,XSelect2,YSelect2)) then begin
                   Attack1:=0; DrawIt:=True;
                 end;
               end;
               if (Attack2 > 0) then begin
                 if (TestMouse(X2Select1,Y2Select1,X2Select2,Y2Select2)) then begin
                   Attack2:=0; DrawIt:=True;
                 end;
               end;
               {xxx}
               J:=0; Continue:=True;
               while ((J <= MaxItem) and Continue) do
               with (ItemArray[J]) do begin
                 if ((V > 0) and (TestMouse(X,Y,X2,Y2))) then begin
                    if (Attack1 = 0) then begin
                      Attack1:=V;  DrawIt:=True; Continue:=False;
                    end else
                      if (Attack2 = 0) then begin
                        Attack2:=V;  DrawIt:=True; Continue:=False;
                      end;
                 end;  Inc(J);
               end;
             end;
         1 : begin
               if (Defence1 > 0) then begin
                 if (TestMouse(XSelect1,YSelect1,XSelect2,YSelect2)) then begin
                   Defence1:=0; DrawIt:=True;
                 end;
               end;
               if (Defence2 > 0) then begin
                 if (TestMouse(X2Select1,Y2Select1,X2Select2,Y2Select2)) then begin
                   Defence2:=0; DrawIt:=True;
                 end;
               end;
               {xxx}
               J:=0; Continue:=True;
               while ((J <= MaxItem) and Continue) do
               with (ItemArray[J]) do begin
                 if ((V > 0) and (TestMouse(X,Y,X2,Y2))) then begin
                    if (Defence1 = 0) then begin
                      Defence1:=V;  DrawIt:=True; Continue:=False;
                    end else
                      if (Defence2 = 0) then begin
                        Defence2:=V;  DrawIt:=True; Continue:=False;
                      end;
                 end;  Inc(J);
               end;
             end;
         2 : begin
               if (Sight1 > 0) then begin
                  if (TestMouse(XSelect1,YSelect1,XSelect2,YSelect2)) then begin
                    Sight1:=0; DrawIt:=True;
                  end;
               end;
               if (Sight2 > 0) then begin
                  if (TestMouse(X2Select1,Y2Select1,X2Select2,Y2Select2)) then begin
                    Sight2:=0; DrawIt:=True;
                  end;
               end;
               {xxx}
               J:=0; Continue:=True;
               while ((J <= MaxItem) and Continue) do
               with (ItemArray[J]) do begin
                 if ((V > 0) and (TestMouse(X,Y,X2,Y2))) then begin
                    if (Sight1 = 0) then begin
                      Sight1:=V;  DrawIt:=True; Continue:=False;
                    end else
                      if (Sight2 = 0) then begin
                        Sight2:=V;  DrawIt:=True; Continue:=False;
                      end;
                 end;  Inc(J);
               end;
             end;
         3 : begin
               if (Engine1 > 0) then begin
                  if (TestMouse(XSelect1,YSelect1,XSelect2,YSelect2)) then begin
                    Engine1:=0; DrawIt:=True;
                  end;
               end;
               if (Engine2 > 0) then begin
                  if (TestMouse(X2Select1,Y2Select1,X2Select2,Y2Select2)) then begin
                    Engine2:=0; DrawIt:=True;
                  end;
               end;
               {xxx}
               J:=0; Continue:=True;
               while ((J <= MaxItem) and Continue) do
               with (ItemArray[J]) do begin
                 if ((V > 0) and (TestMouse(X,Y,X2,Y2))) then begin
                    if (Engine1 = 0) then begin
                      Engine1:=V;  DrawIt:=True; Continue:=False;
                    end else
                      if (Engine2 = 0) then begin
                        Engine2:=V;  DrawIt:=True; Continue:=False;
                      end;
                 end;  Inc(J);
               end;
             end;
         4 : begin
               if (Special1 > 0) then begin
                  if (TestMouse(XSelect1,YSelect1,XSelect2,YSelect2)) then begin
                    Special1:=0; DrawIt:=True;
                  end;
               end;
               if (Special2 > 0) then begin
                  if (TestMouse(X2Select1,Y2Select1,X2Select2,Y2Select2)) then begin
                    Special2:=0; DrawIt:=True;
                  end;
               end;
               {xxx}
               J:=0; Continue:=True;
               while ((J <= MaxItem) and Continue) do
               with (ItemArray[J]) do begin
                 if ((V > 0) and (TestMouse(X,Y,X2,Y2))) then begin
                    if (Special1 = 0) then begin
                      Special1:=V;  DrawIt:=True; Continue:=False;
                    end else
                      if (Special2 = 0) then begin
                        Special2:=V;  DrawIt:=True; Continue:=False;
                      end;
                 end;  Inc(J);
               end;
             end;
     end;

   end;
   SetResearchAssignResult(Index,1);
   if (DrawIt) then Draw(Index);
end;

{ ************************************************************************** }
procedure OSNResearchInit;
{ inicializace vyzkumu
}
var I,J:Word;
begin
  I:=1;
  with (Research^[I]) do begin { 1 - P2 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='P2'; { nazev vyzkumu }
     Descr:='VYLEPgENc STfELIVO PRO PdgaKY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='MeSTO KLASICKcHO STfELNcHO PRACHU BUDE MOkNO POUkeVAT MeRNd hbINNdJge';
     Descript[1]:='VjBUgNc SMdSI NA BaZI HOfbeKU A MdDI.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=2; Hate[1]:=3; Hate[2]:=5;

     Cost:=1500; { cena vyzkumu }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=3; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=7; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; EE:=0; PL:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 2 - KAL200 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='KAL200'; { nazev vyzkumu }
     Descr:='VYLEPgENj SAMOPAL S LASER. ZAMdfOVAbEM'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='NA POUkeVANc PdCHOTNe ZBRANd JE MOkNO NAMONTOVAT OPTICKc ZAMdfOVACe';
     Descript[1]:='ZAfeZENe NA BaZI LASERU, DeKY KTERcMU SE ZVjge PfESNOST ZaSAHU, HORge';
     Descript[2]:='MANIPULACE VgAK VEDE KE SNekENe OBRANYSCHOPNOSTI.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=1;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=1; Hate[1]:=3; Hate[2]:=5;

     Cost:=2500; { cena vyzkumu v bodech }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=13; o:=-8; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=10; EE:=10; PL:=3; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 3 - LAS G2 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='LAS G2'; { nazev vyzkumu }
     Descr:='PdCHOTNe LASEROVa ZBRAN'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='DEKY ZKUgENOSTEM S LASEROVjM ZAMdfOVaNeM BYL VYVINUT LASER S TAK';
     Descript[1]:='NeZKOU SPOTfEBOU ENERGIE, kE JE HO MOkNc POUkeT I JAKO ZBRAN.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=2;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=1; Hate[1]:=2; Hate[2]:=5;

     Cost:=4200; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=15; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=10; EE:=15; PL:=5; Ex:=20;
  end; Inc(I);
  with (Research^[I]) do begin { 4 - LASG3 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='LAS G3'; { nazev vyzkumu }
     Descr:='LASEROVa ZBRAN PRO VOZIDLA'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='STRUKTUROU JE SHODNa S PdCHOTNe LASEROVOU PUgKOU, DeKY POKRObILEJge';
     Descript[1]:='TECHNOLOGIe JE VgAK LEHbe A MENge.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=3;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=6; Hate[1]:=7; Hate[2]:=8;

     Cost:=3800; { cena vyzkumu }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=12; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=10; EE:=10; PL:=5; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 5 - LPEC }
     Validity:=True; { True, pokud je polozka platna }
     Name:='LPEC'; { nazev vyzkumu }
     Descr:='PULZNe EMITOR baSTIC PRO PdCHOTU'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='LOGICKc POKRAbOVaNe LASEROVc TECHNOLOGIE. DeKY MOkNOSTI KONTROLOVAT';
     Descript[1]:='ATOMOVc MIKROREAKCE SE NASKYTLA MOkNOST VYZAfOVANc baSTICE USMdRNOVAT';
     Descript[2]:='A DOCeLIT VYggcHO DOSTfELU.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=3;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=1; Hate[1]:=2; Hate[2]:=3;

     Cost:=5900; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=8; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=22; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=1; h:=0; s:=0;
     BP:=15; EE:=15; PL:=20; Ex:=20;
  end; Inc(I);
  with (Research^[I]) do begin { 6 - TPEC }
     Validity:=True; { True, pokud je polozka platna }
     Name:='TPEC'; { nazev vyzkumu }
     Descr:='PULZNe EMITOR baSTIC PRO VOZIDLA'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='TECHNOLOGICKY SHODNj S LPEC, PROVEDENA ADAPTACE NA VdTge VOZIDLA.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=5;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=4; Hate[1]:=7; Hate[2]:=8;

     Cost:=8000; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=15; tu:=18; au:=9; r:=0; d:=0; h:=0; s:=0;
     BP:=10; EE:=15; PL:=10; Ex:=16;
  end; Inc(I);
  with (Research^[I]) do begin { 7 - AERO P7P }
     Validity:=True; { True, pokud je polozka platna }
     Name:='AERO P7P'; { nazev vyzkumu }
     Descr:='KAPKOVa STfELA DO KANONU PRiRAZNa'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='TATO STfELA DeKY NOVcMU AERODYNAMICKcMU TVARU DOSAHUJE VYgge RYCHLOSTI,';
     Descript[1]:='TeM I VYggeHO DOLETU A hbINKU. SPECIaLNd TVRZENa HLAVICE Ma VYNIKAJeCe';
     Descript[2]:='hbINEK PROTI TdkKjM CeLiM.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[9,12,13,16];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=4; Hate[1]:=6; Hate[2]:=8;

     Cost:=3000; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=15; au:=0; r:=0; d:=1; h:=0; s:=0;
     BP:=8; EE:=5; PL:=10; Ex:=0;
  end; Inc(I);
   with (Research^[I]) do begin { 8 - AERO P7T }
     Validity:=True; { True, pokud je polozka platna }
     Name:='AERO P7T'; { nazev vyzkumu }
     Descr:='KAPKOVa STfELA DO KANONU TfegTIVa'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='TAKc TYP AERO, TfISTIVa NaPLN HLAVICE JE URbENA SPECIaLNd PROTI';
     Descript[1]:='PdCHOTd A LEHKjM CeLiM.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=7;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[9,12,13,16];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=4; Hate[1]:=6; Hate[2]:=7;

     Cost:=3100; { cena vyzkumu }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=17; tu:=0; au:=0; r:=0; d:=1; h:=0; s:=0;
     BP:=8; EE:=5; PL:=10; Ex:=0;
  end; Inc(I);
   with (Research^[I]) do begin { 9 - LA 12 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='LA 12'; { nazev vyzkumu }
     Descr:='RAKETA SE ZDOKONALENjMI MOTORY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYLEPgENc ZBRANd PRO LETECKOU TECHNIKU; hSPORNdJge MOTORY A VdTge';
     Descript[1]:='ZaSOBA PALIVA ZACHOVaVAJe RYCHLOST PfI VjZNAMNcM ZVjgENe DOLETU. ';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[34,10];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=10; Hate[1]:=12; Hate[2]:=0;

     Cost:=2600; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=3; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=1; h:=0; s:=0;
     BP:=5; EE:=5; PL:=5; Ex:=0;
  end; Inc(I);
   with (Research^[I]) do begin { 10 - ALAMO }
     Validity:=True; { True, pokud je polozka platna }
     Name:='ALAMO'; { nazev vyzkumu }
     Descr:='VYLEPgENa HLAVICE PRO RAKETY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYLEPgENc ZBRANd PRO LETECKOU TECHNIKU; NOVa NaLOk VE HLAVICI STfELY';
     Descript[1]:='ZVYgUJE JEJe hbINNOST PROTI VgEM DRUHiM CeLi.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=9;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[34,10];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=9; Hate[1]:=12; Hate[2]:=0;

     Cost:=2500; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=3; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=14; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=5; EE:=2; PL:=3; Ex:=8;
  end; Inc(I);
  with (Research^[I]) do begin { 11 - GUIDMIS }
     Validity:=True; { True, pokud je polozka platna }
     Name:='GUIDMIS'; { nazev vyzkumu }
     Descr:='SYSTcM feZENe PROJEKTILi'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='AUTONAVaDdNe PROJEKTILi PRO VYBRANc JEDNOTKY.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=10;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[8,9];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3200; { cena vyzkumu }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=4; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=5; EE:=5; PL:=5; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 12 - EAGLE 4B }
     Validity:=True; { True, pokud je polozka platna }
     Name:='EAGLE 4B'; { nazev vyzkumu }
     Descr:='feZENc STfELY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYLEPgENc ZBRANd PRO LETECKOU TECHNIKU. INTELIGENTNe feZENc STfELY,';
     Descript[1]:='KTERc DOKake IDENTIFIKOVAT NEJCITLIVdJge MeSTO NEPfeTELE, A KTERc ';
     Descript[2]:='NaSLEDNd ZASaHNOU S PfESNOSTe NA 10 CM';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=2; Recq[1]:=10;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[A];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=9; Hate[1]:=10; Hate[2]:=0;

     Cost:=2800; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=2; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=15; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=8; EE:=8; PL:=8; Ex:=10;
  end; Inc(I);
  Inc(I); { 13 - CHYBI }
  with (Research^[I]) do begin { 14 - CHEETAH }
     Validity:=True; { True, pokud je polozka platna }
     Name:='CHEETAH'; { nazev vyzkumu }
     Descr:='PfeDAVNj ROTAbNe KULOMET DO PEVNOSTI'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='NA ZAKLADd ZKUgENOSTe V BOJI S LEHKjMI JEDNOTKAMI JE NYNe MOkNO DO';
     Descript[1]:='Vdke MONTOVAT PfeDAVNc RYCHLOPALNc KULOMETY TYPU CHEETAH. JEJICH';
     Descript[2]:='hbINNOST PROTI PdCHOTE A LEHKjM CILiM JE VYgge NEk U DOSAVADNeCH';
     Descript[3]:='SYSTEMi. CHEETAH JSOU VgAK POUkITELNc I NA OSTATNe CeLE.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; {Recq[0]:=2;{}

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[V];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=4200; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=6; { doba, potrebna pro vyzkum }
     Tag:=0; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=15; tu:=9; au:=25; r:=0; d:=0; h:=0; s:=0;
     BP:=15; EE:=10; PL:=15; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 15 - plastic - prerekvizita }
     Validity:=True; { True, pokud je polozka platna }
     Name:='PLASTIC'; { nazev vyzkumu }
     Descr:='VjZKUM PLASTi'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='PLASTICKc MATERIaLY NaM UMOkNe KONSTRUKCI VeCE ODOLNjCH JEDNOTEK.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=4000; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=255; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }


     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; EE:=0; PL:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 16 - REX2 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='REX2'; { nazev vyzkumu }
     Descr:='PLASTOVa ZBROJ PRO PdCHOTU'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='DeKY TcTO TECHNOLOGII BY MdLY ZTRaTY PdCHOTY BjT Ak O 8% NIkge.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=15;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=17; Hate[1]:=0; Hate[2]:=0;

     Cost:=2600; { cena vyzkumu }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=2; { doba, potrebna pro vyzkum }
     Tag:=1; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=8; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; EE:=0; PL:=10; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 17 - REX3D }
     Validity:=True; { True, pokud je polozka platna }
     Name:='REX3'; { nazev vyzkumu }
     Descr:='PLASTOVa ZBROJ SE SPECIaLNeM POVRCHEM'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYLEPgENj REX2 POSKYTUJE JEgTd LEPge OCHRANU V BOJOVjCH PODMeNKaCH.';
     Descript[1]:='LEHKa, POHODLNa VESTA SI Uk VE ZKUgEBNeCH TESTECH ZeSKALA VELKOU';
     Descript[2]:='OBLIBU PdCHOTY.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0; Recq[0]:=16;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=16; Hate[1]:=0; Hate[2]:=0;

     Cost:=5000; { cena vyzkumu }
     VCost:=3; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=1; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=20; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=10; EE:=20; PL:=25; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 18 - REX4 AT }
     Validity:=True; { True, pokud je polozka platna }
     Name:='REX3 PLUS'; { nazev vyzkumu }
     Descr:='PECHOTNI SILOVE POLE'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYTVARI NA POVRCHU ZBROJE SILNE ELMAG VLNENI, KTERE DOKAZE SNIZIT';
     Descript[1]:='UCINKY ZASAHU PRIBLIZNE O 15%. ZARIZENI JE BOHUZEL DOSTI ROZMERNE,';
     Descript[2]:='TAKZE SNIZUJE POHYBLIVOST A TIM I UTOCNOU SILU ODDILU.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=16; Recq[1]:=2; Recq[2]:=1;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=4100; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=1; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=-5; o:=15; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=5; EE:=20; PL:=5; Ex:=5;
  end; Inc(I);
  with (Research^[I]) do begin { 19 - HEAVY REX }
     Validity:=True; { True, pokud je polozka platna }
     Name:='HEAVY REX'; { nazev vyzkumu }
     Descr:='TEkKj PANCef PRO JEDNOTKY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='KLASICKj PANCEf BYL ROZVRSTVEN A ZESeLEN, beMk SE ZVjgILA ODOLNOST';
     Descript[1]:='PROTI STfELaM TdkKcHO KALIBRU, BOHUkEL SE SNekILA RYCHLOST.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=16; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[L,T,A];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=5300; { cena vyzkumu }
     VCost:=0; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=3; { doba, potrebna pro vyzkum }
     Tag:=1; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=20; k:=0; lu:=0; tu:=0; au:=0; r:=-1; d:=0; h:=0; s:=0;
     BP:=20; PL:=10; EE:=5; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 20 - AUTOREP3 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='AUTOREPX'; { nazev vyzkumu }
     Descr:='VELMI POKRObILc AUTOOPRAVNc SYSTcMY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='APLIKACE NOVjCH MATERIaLi UMOkNUJE AUTOMATICKc A BEZPLATNc REGENEROVaNe';
     Descript[1]:='POgKOZENe V ROZSAHU 0-15%';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=32; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P,L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=31; Hate[1]:=32; Hate[2]:=0;

     Cost:=8800; { cena vyzkumu }
     VCost:=6; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=7; { doba, potrebna pro vyzkum }
     Tag:=4; { prizrak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=35; PL:=35; EE:=35; Ex:=15;
  end;  Inc(I);
  Inc(I); { 21 - CHYBI }
  with (Research^[I]) do begin { 22 - REX PLUS }
     Validity:=True; { True, pokud je polozka platna }
     Name:='REX PLUS'; { nazev vyzkumu }
     Descr:='SILOVc POLE PRO VOZIDLA'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='JDE O VYLEPgENj TYP SILOVcHO POLE PRO PdCHOTU, JE HO MOkNc KOMBINOVAT';
     Descript[1]:='S OSTATNeMI TYPY REX.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=18; Recq[1]:=6; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3250; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=1; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=10; k:=0; lu:=-5; tu:=-5; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=2; PL:=3; EE:=20; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 23 - ENGINE }
     Validity:=True; { True, pokud je polozka platna }
     Name:='ENGINE'; { nazev vyzkumu }
     Descr:='PROJEKT NOVcHO MOTORU'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='UMOkNe KONSTRUKCE NOVjCH, EKOLOGICKjCH A USPORNjCH TYPi POHONi.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=0; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=6000; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=2; { doba, potrebna pro vyzkum }
     Tag:=255; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; PL:=0; EE:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 24 - VAMPIR 2003 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='VAMPIR 2003'; { nazev vyzkumu }
     Descr:='MOTOR'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='PfEVRATNa TECHNOLOGIE, KTERa VYUkeVa ROZDeLi TEPLOT OKOLe, JE UPLATNdNa';
     Descript[1]:='V NOVcM VjKONNcM MOTORU. VjROBNe NaKLADY VOZIDLA S TeMTO POHONEM JSOU';
     Descript[2]:='Ak O 10% NIkge';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=23; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=27; Hate[1]:=0; Hate[2]:=0;

     Cost:=3900; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=3; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=-10; PL:=-10; EE:=0; Ex:=-5;
  end; Inc(I);
  with (Research^[I]) do begin { 25 - SVP }
     Validity:=True; { True, pokud je polozka platna }
     Name:='SVP'; { nazev vyzkumu }
     Descr:='SPECIaLNe VjCVIK PdCHOTY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='NOVc VjCVIKOVc METODY, VYUkeVAJeCe HLAVNd DRIL A SEBEKONTROLU, DOKake';
     Descript[1]:='Z bLOVdKA VYTVOfIT OPRAVDOVj NaSTROJ ZKaZY. VOJaK, KTERj PROJDE TeMTO';
     Descript[2]:='NaRObNjM VjCVIKEM SE DOKakE LcPE POHYBOVAT NA BOJIgTI, LcPE STfeLe A';
     Descript[3]:='JEHO MORaLKA JE TRVALE NA VYSOKc hROVNI. hTOK VgAK PROBeHa Z MNOHEM ';
     Descript[4]:='MENge VZDaLENOSTI A PROTO JE I O NdCO VYgge PROCENTO ZTRaT.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=3; Recq[1]:=16; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=6400; { cena vyzkumu }
     VCost:=5; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=8; { doba, potrebna pro vyzkum }
     Tag:=4; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=-5; k:=1; lu:=0; tu:=0; au:=0; r:=0; d:=-1; h:=0; s:=0;
     BP:=150; PL:=100; EE:=80; Ex:=80;
  end; Inc(I);
  with (Research^[I]) do begin { 26 - ANTI M6 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='ANTI M6'; { nazev vyzkumu }
     Descr:='PROTOTYP PULZNeHO MOTORU'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='OPdT DALge VYUkITe PULZNe EMISE, TENTOKRaT POUkITa VE VjZKUMU NOVc';
     Descript[1]:='POHONNc JEDNOTKY ANTI.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=24; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3000; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=6; { doba, potrebna pro vyzkum }
     Tag:=3; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; PL:=0; EE:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 27 - ANTI PM12 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='ANTI PM12'; { nazev vyzkumu }
     Descr:='PULZNe MOTOR'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='JEDNa SE O ODLEHbENOU VERZI PROTOTYPU M6, DeKY KTERc SE RAPIDNd SNeke';
     Descript[1]:='NdKTERc NaKLADY NA VjROBU. LEPge CELKOVc MANEVROVACe SCHOPNOSTI A TeM';
     Descript[2]:='I ZVjgENe hTObNc A OBRANNc SeLY bINe Z ANTI PM12 VELMI PLATNOU';
     Descript[3]:='KOMPONENTU NAgICH OBRNdNjCH JEDNOTEK.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=26; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[13,9,12];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=24; Hate[1]:=0; Hate[2]:=0;

     Cost:=3500; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=9; { doba, potrebna pro vyzkum }
     Tag:=3; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=5; o:=5; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=-20; PL:=-20; EE:=10; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 28 - DDP4 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='DD'; { nazev vyzkumu }
     Descr:='SYSTcMY DETEKCE POHYBU'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VjZKUM V TcTO KATEGORII UMOkNe VYBAVIT JEDNOTKY SYSTcMY, ZVYgUJeCeMI';
     Descript[1]:='JEJICH PfEHLED NA BOJIgTI. ZKUgENOSTI Z TERcNU NaM UKAZUJe, kE PRaVd';
     Descript[2]:='VYgge DOHLED MikE VjRAZNd OVLIVNIT VjSLEDEK BOJE.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=0; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=2300; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=3; { doba, potrebna pro vyzkum }
     Tag:=2; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; PL:=0; EE:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 29 - DDP4 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='DDP4'; { nazev vyzkumu }
     Descr:='DaLKOVj DETEKTOR POHYBU'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='PfeSTROJ ZVYgUJE DOHLED O "1".';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=28; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P,L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3600; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=2; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=1;
     BP:=5; PL:=5; EE:=10; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 30 - GNS 120 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='GNS 120'; { nazev vyzkumu }
     Descr:='GLOBaLNe NAVIGAbNe SYSTcM'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='JDE O VOJENSKOU VERZI CIVILNeHO GPS. ZVYgUJE DOHLED. GNS 120 JE MOkNc';
     Descript[1]:='KOMBINOVAT S TYPEM DDP4.';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=29; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[T,A,V];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=5200; { cena vyzkumu }
     VCost:=2; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=2; { prizrak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=1;
     BP:=15; PL:=10; EE:=20; Ex:=10;
  end; Inc(I);
  with (Research^[I]) do begin { 31 - AUTOREP }
     Validity:=True; { True, pokud je polozka platna }
     Name:='AUTOREP'; { nazev vyzkumu }
     Descr:='AUTOOPRAVNc SYSTcMY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='APLIKACE NOVjCH MATERIaLi UMOkNUJE AUTOMATICKc A BEZPLATNc REGENEROVaNe';
     Descript[1]:='POgKOZENe V ROZSAHU 0-5%';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=18; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[L,T,A];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=32; Hate[1]:=20; Hate[2]:=0;

     Cost:=3850; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=4; { doba, potrebna pro vyzkum }
     Tag:=4; { prizrak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=10; PL:=10; EE:=10; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 32 - AUTOREP2 }
     Validity:=True; { True, pokud je polozka platna }
     Name:='AUTOREP2'; { nazev vyzkumu }
     Descr:='POKRObILc AUTOOPRAVNc SYSTcMY'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='APLIKACE NOVjCH MATERIaLi UMOkNUJE AUTOMATICKc A BEZPLATNc REGENEROVaNe';
     Descript[1]:='POgKOZENe V ROZSAHU 0-10%';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=31; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[P,L,T];

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=31; Hate[1]:=20; Hate[2]:=0;

     Cost:=5800; { cena vyzkumu }
     VCost:=3; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=6; { doba, potrebna pro vyzkum }
     Tag:=4; { prizrak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=15; PL:=15; EE:=15; Ex:=5;
  end; Inc(I);
  with (Research^[I]) do begin { 33 - RAKETOVE VOZIDLO }
     Validity:=FALSE; { True, pokud je polozka platna }
     Name:='gKORPION'; { nazev vyzkumu }
     Descr:='VjVOJ NOVjCH SYSTcMi'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYNALcZaNe NOVjCH ZBRANe - VjKONNc RAKETOVc VOZIDLO.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=0; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];
     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3800; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=255; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; PL:=0; EE:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 34 - HOUFNICE }
     Validity:=FALSE; { True, pokud je polozka platna }
     Name:='HOUFNICE'; { nazev vyzkumu }
     Descr:='VjVOJ NOVjCH SYSTcMi'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYNALcZaNe NOVjCH ZBRANe - RYCHLOPALNj KANON.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=0; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];
     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3800; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=255; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; PL:=0; EE:=0; Ex:=0;
  end; Inc(I);
  with (Research^[I]) do begin { 35 - TEZKY TANK }
     Validity:=FALSE; { True, pokud je polozka platna }
     Name:='TdkKj TANK'; { nazev vyzkumu }
     Descr:='VjVOJ NOVjCH SYSTcMi'; { kratka charakteristika vyzkumu }
     { podrobny popis vyzkumu: }
     Descript[0]:='VYNALcZaNe NOVjCH ZBRANe - VjKONNdJge A LcPE PANCcfOVANj TANK.';
     Descript[1]:='';
     PercState:=0; { procentuelni stav vyzkumu: 0=0%, 100=100% - vyzkoumano }

     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, ktere jsou treba pro vyzkum : }
     for J:=0 to MaxResearchRecquired do Recq[J]:=0;
     Recq[0]:=0; Recq[1]:=0; Recq[2]:=0;

     { mnozina kategorii jednotek, pro nez je vyzkum povolen:
       P(echota),L(ehke),T(ezke),A(ir),V(eze): }
     EnabledFor:=[];
     { hodnoty "0" znaci neplatna cisla, jinak jsou zde
       cisla polozek, se kterymi se tento vyzkum nesnasi: }
     for J:=0 to MaxResearchHate do Hate[J]:=0;
     Hate[0]:=0; Hate[1]:=0; Hate[2]:=0;

     Cost:=3800; { cena vyzkumu }
     VCost:=1; { cena vyzkumu ve viteznych bodech }
     ResearchTime:=5; { doba, potrebna pro vyzkum }
     Tag:=255; { priznak pouziti zbrane:
               0..utocne;  1..obranne;  2..dohled;  3..pohon;  4..specialni }

     { modifikatory jednotek : u(tok), o(brana), k(adence), lu(lehky utok),
      tu(tezky utok), au(air utok), r(ychlost), d(ostrel), h(odnost),
      s(ight); BP,EE,PL,Ex - modifikatory ceny }
     u:=0; o:=0; k:=0; lu:=0; tu:=0; au:=0; r:=0; d:=0; h:=0; s:=0;
     BP:=0; PL:=0; EE:=0; Ex:=0;
  end;
end;

{ ***** }
procedure RobotResearchInit;
{ inicializace vyzkumu robotu
}
begin
end;

{ ***** }
procedure PrintResearch1(Rsrch:Byte; InfoBox:Byte);
{ vytiskne informace o vyzkumu Rsrch do boxu InfoBox
}
const YLineAdd = 3;
var I,J,X,Y:Word;
    Ret:String;
    XBase,YBase:Word;
begin
  with (ResearchInfoBox[InfoBox]) do begin
    XBase:=X; YBase:=Y;
    RsrchId:=Rsrch;
  end;
  with (Research^[Rsrch]) do if ((Validity) and (PercState <= 100)) then begin
     Temp:=InfoBox;
     CursorOff;
     if (Rsrch <> SelectedResearch) then begin
       Frame2(XBase,YBase,XBase+ResearchXBoxSize-1,YBase+ResearchYBoxSize-1,69);{}
       Frame2(XBase+1,YBase+1,XBase+ResearchXBoxSize-2,YBase+ResearchYBoxSize-2,72);{}
     end else begin
       Frame2(XBase,YBase,XBase+ResearchXBoxSize-1,YBase+ResearchYBoxSize-1,160);{}
       Frame2(XBase+1,YBase+1,XBase+ResearchXBoxSize-2,YBase+ResearchYBoxSize-2,164);{}
     end;
     XPutImage(XBase+2,YBase+2,ResearchXBoxSize-5,ResearchYBoxSize-5,SBack,OBack);
     {Rectangle(XBase+2,YBase+2,XBase+ResearchXBoxSize-3,YBase+ResearchYBoxSize-3,77);{}

     Inc(XBase,3*XFontSize);

     X:=XBase+XFontSize; Y:=YBase+YFontSize shr 1;
     Inc(X,(ResearchXBoxSize-XFontSize*(Length(Name))-12*XFontSize) shr 1);
     SetColor(67);
     NLine(X,Y+YFontSize,X+XFontSize*(Length(Name)),Y+YFontSize);
     {OutTextColor(X,Y,48,'NaZEV: '); Inc(X,XFontSize*7);{}
     OutTextColor(X,Y,97,Name); Inc(X,XFontSize*(Length(Name)));

     X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd);
     Inc(X,(ResearchXBoxSize-XFontSize*Length(Descr)-12*XFontSize) shr 1);
     OutTextColor(X,Y,97,''+Descr+'');{}

     X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd+2);
     OutTextColor(X,Y,48,'VLIV TECHNOLOGIE: '); ; Inc(X,XFontSize*18);{}
     if (u <> 0) then begin
       OutTextColor(X,Y,67,'hTOK '); Inc(X,XFontSize*5);
       if (u > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(u)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     end;
     if (o <> 0) then begin
       OutTextColor(X,Y,67,'OBRANA '); Inc(X,XFontSize*7);
       if (o > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(o)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     end;
     if (k <> 0) then begin
       OutTextColor(X,Y,67,'KADENCE '); Inc(X,XFontSize*8);
       if (k > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(k)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'  '); Inc(X,XFontSize*2);
     end;
     if (lu <> 0) then begin
       OutTextColor(X,Y,67,'LEHKj hTOK '); Inc(X,XFontSize*11);
       if (lu > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(lu)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     end;
     if (tu <> 0) then begin
       OutTextColor(X,Y,67,'TdkKj hTOK '); Inc(X,XFontSize*11);
       if (tu > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(tu)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     end;
     if (au <> 0) then begin
       OutTextColor(X,Y,67,'VZDUgNj hTOK '); Inc(X,XFontSize*13);
       if (au > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(au)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     end;
     if (r <> 0) then begin
       OutTextColor(X,Y,67,'RYCHLOST '); Inc(X,XFontSize*9);
       if (r > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(r)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'  '); Inc(X,XFontSize*2);
     end;
     if (d <> 0) then begin
       OutTextColor(X,Y,67,'DOSTfEL '); Inc(X,XFontSize*8);
       if (d > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(d)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'  '); Inc(X,XFontSize*2);
     end;
     if (h <> 0) then begin
       OutTextColor(X,Y,67,'HODNOST '); Inc(X,XFontSize*8);
       if (h > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(h)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'  '); Inc(X,XFontSize*2);
     end;
     if (s <> 0) then begin
       OutTextColor(X,Y,67,'DOHLED '); Inc(X,XFontSize*7);
       if (s > 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
       Inc(X,XFontSize);
       Str(abs(Round(s)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
       OutTextColor(X,Y,64,'  '); Inc(X,XFontSize*2);
     end;
     {x}
     X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd);
     OutTextColor(X,Y,48,'KREDITi: '); Inc(X,XFontSize*9);
     Str((Cost):4:0,Ret);
     OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*(Length(Ret)+2));
     OutTextColor(X,Y,48,'PRESTIkE: '); Inc(X,XFontSize*10);
     Str((VCost):1:0,Ret);
     OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*(Length(Ret)+2));
     OutTextColor(X,Y,48,'DOBA VjZKUMU (TjDNY): '); Inc(X,XFontSize*22);
     Str(ResearchTime,Ret);
     OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*(Length(Ret)+2));
     OutTextColor(X,Y,48,'VYZKOUMaNO: '); Inc(X,XFontSize*13);
     Str(Round(PercState),Ret);
     OutTextColor(X,Y,64,Ret+'%');
     {x}
     X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd);
     OutTextColor(X,Y,48,'URbENO PRO: '); Inc(X,XFontSize*12);
     if (P in EnabledFor) then begin
       OutTextColor(X,Y,64,'PdCHOTU; '); Inc(X,XFontSize*9);
     end;
     if (L in EnabledFor) then begin
       OutTextColor(X,Y,64,'LEHKc CeLE; '); Inc(X,XFontSize*12);
     end;
     if (T in EnabledFor) then begin
       OutTextColor(X,Y,64,'TdkKc CeLE; '); Inc(X,XFontSize*12);
     end;
     if (A in EnabledFor) then begin
       OutTextColor(X,Y,64,'LETECTVO; '); Inc(X,XFontSize*10);
     end;
     if (V in EnabledFor) then begin
       OutTextColor(X,Y,64,'VdkE; '); Inc(X,XFontSize*7);
     end;
     for I:=1 to MaxTypesOfUnits do begin
        if (I in EnabledFor) then begin
           OutTextColor(X,Y,64,Unit_types^[I,1].Name+'; ');
           Inc(X,XFontSize*(Length(Unit_types^[I,1].Name)+2));
        end;
     end;
     {x}
     X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd);
     Inc(X,(ResearchXBoxSize-XFontSize*42-12*XFontSize) shr 1);
     OutTextColor(X,Y,48,'TECHNOLOGIE ZMdNe CENU JEDNOTEK V MISeCH: ');

     X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd-1);
      OutTextColor(X,Y,67,'MATERIaL '); Inc(X,XFontSize*9);
      if (BP >= 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
      Inc(X,XFontSize);
      Str(abs(Round(BP)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
      OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     OutTextColor(X,Y,67,'PLASTY '); Inc(X,XFontSize*7);
     if (PL >= 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
     Inc(X,XFontSize);
     Str(abs(Round(PL)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
     OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
      OutTextColor(X,Y,67,'EL.ENERGIE '); Inc(X,XFontSize*11);
      if (EE >= 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
      Inc(X,XFontSize);
      Str(abs(Round(EE)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
      OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);
     OutTextColor(X,Y,67,'ZKUgENOST '); Inc(X,XFontSize*10);
     if (Ex >= 0) then OutTextColor(X,Y,64,'+') else OutTextColor(X,Y,64,'-');
     Inc(X,XFontSize);
     Str(abs(Round(Ex)),Ret); OutTextColor(X,Y,64,Ret); Inc(X,XFontSize*Length(Ret));
     OutTextColor(X,Y,64,'%  '); Inc(X,XFontSize*3);

     CursorOn;
  end;
end;

{ ***** }
procedure PrintResearch2(Rsrch:Byte; InfoBox:Byte);
{ vytiskne informace o vyzkumu Rsrch do boxu InfoBox
}
const YLineAdd = 3;
var X,Y:Word;
    Ret:String;
    XBase,YBase,I:Word;
begin
  with (ResearchInfoBox[InfoBox]) do begin
    XBase:=X; YBase:=Y;
    RsrchId:=Rsrch;
  end;
  with (Research^[Rsrch]) do if ((Validity) and (PercState <= 100)) then begin
     Temp:=InfoBox;
     CursorOff;
     if (Rsrch <> SelectedResearch) then begin
       Frame2(XBase,YBase,XBase+ResearchXBoxSize-1,YBase+ResearchYBoxSize-1,69);{}
       Frame2(XBase+1,YBase+1,XBase+ResearchXBoxSize-2,YBase+ResearchYBoxSize-2,72);{}
     end else begin
       Frame2(XBase,YBase,XBase+ResearchXBoxSize-1,YBase+ResearchYBoxSize-1,160);{}
       Frame2(XBase+1,YBase+1,XBase+ResearchXBoxSize-2,YBase+ResearchYBoxSize-2,164);{}
     end;
     XPutImage(XBase+2,YBase+2,ResearchXBoxSize-5,ResearchYBoxSize-5,SBack,OBack);
     {Rectangle(XBase+2,YBase+2,XBase+ResearchXBoxSize-3,YBase+ResearchYBoxSize-3,77);{}

     X:=XBase+XFontSize; Y:=YBase+YFontSize shr 1;
     Inc(X,(ResearchXBoxSize-XFontSize*(Length(Name))) shr 1);
     SetColor(67);
     NLine(X,Y+YFontSize,X+XFontSize*(Length(Name)),Y+YFontSize);
     {OutTextColor(X,Y,48,'NaZEV: '); Inc(X,XFontSize*7);{}
     OutTextColor(X,Y,97,Name); Inc(X,XFontSize*(Length(Name)));

     for I:=0 to 4 do begin
       if (Descript[I] <> '') then begin
         X:=XBase+XFontSize; Inc(Y,YFontSize+YLineAdd);
         Inc(X,(ResearchXBoxSize-XFontSize*Length(Descript[I])) shr 1);
         OutTextColor(X,Y,67,''+Descript[I]+'');{}
       end;
    end;

     CursorOn;
  end;
end;

{ ***** }
procedure PrintResearch(Rsrch:Byte; InfoBox:Byte);
{ vytiskne informace o vyzkumu Rsrch do boxu InfoBox
}
const YLineAdd = 3;
var X,Y:Word;
    Ret:String;
    XBase,YBase:Word;
begin
  if (TextMode) then PrintResearch2(Rsrch,InfoBox)
  else PrintResearch1(Rsrch,InfoBox);
end;

{ ***** }
procedure SelectResearch(NewRsrch:Boolean);
{ informace po stisknuti tlacitka "VYZKUM"
  NewRsrch =True pro novy vyzkum
           =False pro panel "jiz vyzkoumane"
}
var X,Y,X2,Y2:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
    I:Word;
    Pom:Byte;
    LastClick:Word;

function PanelClick(XX,YY:Word):Byte;
{ vrati cislo panelu, nad nimz bylo stisknuto tlacitko mysi;
  vraci 255, pokud doslo ke stisku jinde
}
var I:Word;
begin
  PanelClick:=255;
  for I:=0 to MaxResearchInfoBoxIndex do with (ResearchInfoBox[I]) do
    if ((XX <= (X+ResearchXBoxSize)) and (XX >= X) and
        (YY <= (Y+ResearchYBoxSize)) and (YY >= Y) and
        (MaxResearchAvailIndex > 0)) then
      PanelClick:=I;
end;

{ xxx }
begin
   LastClick:=0; SelectedResearch:=0;

   ScreenOff;
   X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
   Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
   CursorOff;
   PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;

   X:=(XResolution-XResearchInfoSize) div 2;
   Y:=(YResolution-YResearchInfoSize) div 2+YResearchInfoSize-1;
   Y:=Y-3*SmallButtonYSize;
   X2:=(XResearchInfoSize-5*SmallButtonXSize) div 6;
   Inc(X,X2);
   CreateButton(X,Y,1,0,False,_Temp1); ButtonText(_Temp1,65,'<');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp2); ButtonText(_Temp2,65,'>');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp3); ButtonText(_Temp3,65,'ZPdT');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp4); ButtonText(_Temp4,65,'OK');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp5); ButtonText(_Temp5,65,'TEXT');

   CursorOff;
   Release(_Temp1); Release(_Temp2); Release(_Temp3);
   Release(_Temp4); Release(_Temp5);
   CursorOn;
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3);
   SetActive(_Temp4); SetActive(_Temp5);
   ScreenOn;
   { ** vlastni prace s informacnim panelem ** }

   for I:=0 to MaxResearchInfoBoxIndex do with (ResearchInfoBox[I]) do begin
      if (I = 0) then begin
         X:=(XResolution-XResearchInfoSize) div 2+8;
         Y:=(YResolution-YResearchInfoSize) div 2+16;
      end else begin
         X:=ResearchInfoBox[I-1].X;
         Y:=ResearchInfoBox[I-1].Y + 24 + ResearchYBoxSize;
      end;
   end;

   if ((CurrentResearchAvailIndex <= MaxResearchAvailIndex) and
       (CurrentResearchAvailIndex > 0))
   then begin
      PrintResearch(ResearchAvail[CurrentResearchAvailIndex],0);
   end;
   if (CurrentResearchAvailIndex < MaxResearchAvailIndex) then begin
      Inc(CurrentResearchAvailIndex);
      PrintResearch(ResearchAvail[CurrentResearchAvailIndex],1);
      Dec(CurrentResearchAvailIndex);
   end;

   { nyni reakce na akci: }
   X2:=(XResolution-XResearchInfoSize) div 2;
   Y2:=(YResolution-YResearchInfoSize) div 2;
   Konec:=False;
   while not (Konec) do begin
      Button:=0;
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin  { 1 krok dozadu }
                         SoundPlay(0,0,0,0);
                         CursorOff;
                         SelectedResearch:=0;
                         if (CurrentResearchAvailIndex  > 1) then begin
                           PutImage(X2,Y2,TempSeg2,TempOfs2,NormalDirect);
                           Release(_Temp1); Release(_Temp2); Release(_Temp3);
                           Release(_Temp4); Release(_Temp5); Release(_Temp6);
                         end;
                         if (CurrentResearchAvailIndex  > 1) then begin
                            {Dec(CurrentResearchAvailIndex);{}
                            PrintResearch(ResearchAvail[CurrentResearchAvailIndex],1);
                         end;
                         if (CurrentResearchAvailIndex  > 1) then begin
                            Dec(CurrentResearchAvailIndex);
                            PrintResearch(ResearchAvail[CurrentResearchAvailIndex],0);
                         end;
                         CursorOn;
                      end;
         _Temp2     : begin  { 1 krok dopredu }
                         SoundPlay(0,0,0,0);
                         CursorOff;
                         SelectedResearch:=0;
                         if (CurrentResearchAvailIndex < MaxResearchAvailIndex) then begin
                            PutImage(X2,Y2,TempSeg2,TempOfs2,NormalDirect);
                            Release(_Temp1); Release(_Temp2); Release(_Temp3);
                            Release(_Temp4); Release(_Temp5); Release(_Temp6);
                         end;
                         if (CurrentResearchAvailIndex < MaxResearchAvailIndex) then begin
                            Inc(CurrentResearchAvailIndex);
                            PrintResearch(ResearchAvail[CurrentResearchAvailIndex],0);
                         end;
                         if (CurrentResearchAvailIndex < MaxResearchAvailIndex) then begin
                            Inc(CurrentResearchAvailIndex);
                            PrintResearch(ResearchAvail[CurrentResearchAvailIndex],1);
                            Dec(CurrentResearchAvailIndex);
                         end;
                         CursorOn;
                      end;
         _Temp3     : begin  { zrus okno }
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                      end;
         _Temp4     : begin  { vyber }
                        SoundPlay(0,0,0,0);
                        if (NewRsrch) then
                           if (SelectedResearch <> 0) then
                             GlobalSelectedResearch:=SelectedResearch;
                        Konec:=True;
                      end;
         _Temp5     : begin  { vytisknuti textu o objektu }
                         SoundPlay(0,0,0,0);
                         if (TextMode) then TextMode:=False
                         else TextMode:=True;
                         if ((CurrentResearchAvailIndex <= MaxResearchAvailIndex) and
                             (CurrentResearchAvailIndex > 0))
                         then begin
                            PrintResearch(ResearchAvail[CurrentResearchAvailIndex],0);
                         end;
                         if (CurrentResearchAvailIndex < MaxResearchAvailIndex) then begin
                            Inc(CurrentResearchAvailIndex);
                            PrintResearch(ResearchAvail[CurrentResearchAvailIndex],1);
                            Dec(CurrentResearchAvailIndex);
                         end;
                      end;
      end;
      if (LastClick > 0) then begin
        Dec(LastClick);
      end;
      if ((Button <> 0) and (LastClick = 0)) then begin
         Num:=PanelClick(X,Y);
         if ((Num <> 255) and (NewRsrch) and
             ((SelectedResearch <> ResearchInfoBox[Num].RsrchId) or
              (SelectedResearch = 0)))
         then begin
            SoundPlay(0,0,0,0);
            if (SelectedResearch <> 0) then begin
               Pom:=SelectedResearch;
               SelectedResearch:=0;
               PrintResearch(Pom,Research^[Pom].Temp);
            end;
            SelectedResearch:=ResearchInfoBox[Num].RsrchId;
            PrintResearch(SelectedResearch,Num);
            Mouse.Button:=0; Mouse.ButtonClick:=0; LastClick:=1;
         end;
      end;
   end;
   { ** konec prace s informacnim panelem ** }
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   DeleteButton(_Temp5,256);
end;

{ ***** }
procedure SetAvailResearch(Tag:Boolean);
{ nastavi seznam dostupneho vyzkumu dle priznaku Tag:
  True  = pouze nevyzkoumane veci
  False = pouze vyzkoumane veci
}
var I,J:Word;
    Valid:Boolean;
begin
   MaxResearchAvailIndex:=0;
   CurrentResearchAvailIndex:=0;

   if (Tag) then begin { nevyzkoumane }
     for I:=1 to MaxResearch do begin
       if ((Research^[I].Validity) and (Research^[I].PercState < 100))
       then begin
          Valid:=True;
          for J:=0 to MaxResearchRecquired do
             if ((Research^[I].Recq[J] > 0) and
                 (Research^[Research^[I].Recq[J]].PercState < 100))
             then Valid:=False;
          if (Valid) then begin
            Inc(MaxResearchAvailIndex);
            ResearchAvail[MaxResearchAvailIndex]:=I;
          end;
       end;
     end; { for I:=1 to MaxResearch do begin }
   end else begin { vyzkoumane }
     for I:=1 to MaxResearch do begin
       if (Research^[I].PercState >= 100) then begin
          Inc(MaxResearchAvailIndex);
          ResearchAvail[MaxResearchAvailIndex]:=I;
       end;
     end; { for I:=1 to MaxResearch do begin }
   end;

   if (MaxResearchAvailIndex > 0) then CurrentResearchAvailIndex:=1;
end;

{ ***** }
procedure Work_on_assign_slot(Slot:Byte);
{ umoznuje pridelovat konkretni jednotce vynalezy
}
var X,Y, LastMouseX, LastMouseY:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
    I,J:Word;
begin
   CursorOff;
   Release(_Temp1);
   LastMouseX:=XMouse; LastMouseY:=YMouse;

   X:=(XResolution-XResearchInfoSize) shr 1 + (XResearchInfoSize-BigButtonXSize) shr 1;
   Y:=(YResolution-YResearchInfoSize) shr 1;
   Y:=Y+YResearchInfoSize-BigButtonYSize-YFontSize;
   CreateButton(X,Y,0,0,False,_Temp1); ButtonText(_Temp1,65,'KONEC');
   CursorOff;
   SetActive(_Temp1); Release(_Temp1);
   CursorOn;

   { ** vlastni prace s informacnim panelem ** }
   AssignResearchObject.InitItem;
   Konec:=False; AssignResearchObject.InitDraw(InfoStruct[Slot].Index);
   while not (Konec) do begin
      Button:=0; Num:=0;
      GetMouseClick(X,Y,Button); Keyb(Scan,Ascii);
      while (Button = 0) and (Scan = 0) do begin
         GetMouseClick(X,Y,Button); { cekani na stisk }
         Keyb(Scan,Ascii);
         if ((LastMouseX <> XMouse) or  (LastMouseY <> YMouse)) then
           AssignResearchObject.MoveMouse(XMouse,YMouse);
         LastMouseX:=XMouse; LastMouseY:=YMouse;
      end;
      if (Scan = 0) then begin { stisknut button mysi }
         TestButton(X,Y,Byte(Num));
      end else Num:=0;

      case Num of
         0          : begin
                         if (Scan = $01) then Konec:=True { Esc }
                         else begin
                           if ((Scan = $22{???}) or (Button and 2 = 2)) then
                           { delete, prave tlacitko mysi }
                              AssignResearchObject.ClickMouse(X,Y,2,InfoStruct[Slot].Index);
                         end;
                         if (Button and 1 = 1) then
                           AssignResearchObject.ClickMouse(X,Y,1,InfoStruct[Slot].Index);
                      end;

         _Temp1     : begin  { konec }
                         Konec:=True;
                         PushDown(_Temp1);
                         Delay(150);
                         Release(_Temp1);
                      end;
      end;
   end;
   DeleteButton(_Temp1,256);
end;

{ ***** }
procedure AssignResearch;
{ informace po stisknuti tlacitka "APLIKACE"
}
label Again;
const XSize = 22*XFontSize-1; YSize = 43;
var X,Y,X2,Y2,XSpace,YSpace:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
    I,J,Slot:Word;

{+}{ xxx }
{+}procedure DrawAssignReserchInfo(UnitType,Slot:Word);
{+}{ vykresli nazev jednotky UnitType do slotu Slot
   }
{+}begin
{+}  with (InfoStruct[Slot]) do begin
{+}    Activity:=True;
{+}    Index:=UnitType;
{+}    OutTextColor(XText,YText,66,Unit_types^[UnitType,1].Name);
{+}    if (MyUnitsForMission[UnitType]) then begin
{+}       Frame(X1+1,Y1+1,X2+1,Y2+1,164); Frame(X1,Y1,X2,Y2,160);
{+}    end else begin
{+}       Frame(X1+1,Y1+1,X2+1,Y2+1,72); Frame(X1,Y1,X2,Y2,68);
{+}    end;
{+}    Rectangle(XPicture,YPicture,XPicture+37,YPicture+37,75);
{+}    Frame(XPicture,YPicture,XPicture+37,YPicture+37,72);
{+}    SpecSpeedPutImage3(XPicture,YPicture,
{+}                       Unit_pictures[UnitType].S,Unit_pictures[UnitType].O,
{+}                       0,0,37,37,176);
{+}  end;
{+}end;

{xxx}
{+}function TestSlots(X,Y:Word):Byte;
{+}{ vraci 255 pro neuspech, jinak cislo slotu, ktery je uvnitr pozice X,Y
   }
{+}var I:Word;
{+}begin
{+}  TestSlots:=255;
{+}  for I:=0 to MaxInfoStruct do with (InfoStruct[I]) do
{+}  if (Activity) then begin
{+}     if ((X >= X1) and (X <= X2) and (Y >= Y1) and (Y <= Y2))
{+}     then TestSlots:=I;
{+}  end;
{+}end;

{ xxx }
begin
   ScreenOff;
   X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
   Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
   CursorOff;
   PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;

   XSpace:=(X2-X-40-3*XSize) shr 1;
   YSpace:=(Y2-Y-70-(MaxInfoStruct div 3 + 1)*YSize) div (MaxInfoStruct div 3);
   Inc(X,20); Inc(Y,16);
   for I:=0 to MaxInfoStruct div 3 do begin
      with (InfoStruct[I*3]) do begin
         Activity:=False;
         X1:=X; X2:=X1+XSize; Y1:=Y; Y2:=Y1+YSize;
         XPicture:=X1+4; YPicture:=Y1+3;
         XText:=XPicture+48; YText:=Y1+(YSize-YFontSize) shr 1;
      end;
      with (InfoStruct[I*3+1]) do begin
         Activity:=False;
         X1:=X+XSpace+XSize; X2:=X1+XSize; Y1:=Y; Y2:=Y1+YSize;
         XPicture:=X1+4; YPicture:=Y1+3;
         XText:=XPicture+48; YText:=Y1+(YSize-YFontSize) shr 1;
      end;
      with (InfoStruct[I*3+2]) do begin
         Activity:=False;
         X1:=X+2*XSpace+2*XSize; X2:=X1+XSize; Y1:=Y; Y2:=Y1+YSize;
         XPicture:=X1+4; YPicture:=Y1+3;
         XText:=XPicture+48; YText:=Y1+(YSize-YFontSize) shr 1;
      end;
      Inc(Y,YSize+YSpace);
   end;
Again:
   J:=0;
   CursorOff;
   for I:=1 to MaxTypesOfUnits do with (ReserchAssign[I,1]) do begin
     if ((UnitAvail > 0) and ForPlayer) then begin
        DrawAssignReserchInfo(I,J);
        Inc(J);
     end;
   end;
   CursorOn;

   X:=(XResolution-XResearchInfoSize) shr 1 + (XResearchInfoSize-BigButtonXSize) shr 1;
   Y:=(YResolution-YResearchInfoSize) shr 1;
   Y:=Y+YResearchInfoSize-2*BigButtonYSize+4;
   CreateButton(X,Y,0,0,False,_Temp1); ButtonText(_Temp1,65,'KONEC');
   CursorOff;
   SetActive(_Temp1); Release(_Temp1);
   CursorOn;

   { ** vlastni prace s informacnim panelem ** }
   Konec:=False;
   while not (Konec) do begin
      Button:=0;
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      if ((Button <> 0) and (TestSlots(X,Y) <> 255)) then begin
         SoundPlay(0,0,0,0);
         Slot:=TestSlots(X,Y);
         ScreenOff;
         X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
         Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
         CursorOff;
         PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
         CursorOn;

         DeleteButton(_Temp1,256);
         Work_on_assign_slot(Slot);

         ScreenOff;
         X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
         Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
         CursorOff;
         PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
         CursorOn;
         GoTo Again;
      end;

      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin  { konec }
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                      end;
      end;
   end;

   DeleteButton(_Temp1,256);
end;

{ ***** }
procedure ResearchPanel;
{ informace po stisknuti tlacitka "VYZKUM"
}
label Again;
var X,Y,X2,Y2:Word;
    Konec:Boolean;
    Num, Button, Scan, Ascii:Word;
    I:Word;

{ xxx }
begin
   SetPasive(ResearchButton,256); SetPasive(DalsiTydenButton,256);
   SetPasive(CoreButton,256);     SetPasive(InfoButton,256);
   SetPasive(OptionButton,256);   SetPasive(SaveButton,256);
   SetPasive(LoadButton,256);     SetPasive(EndButton,256);
   SetPasive(StartButton,256);
   SelectedResearch:=0;

   ScreenOff;
   X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
   Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
   ShowInfoPanel(X,Y,X2,Y2,0); ScreenOff;
   CursorOff;
   GetImage(X,Y,X2,Y2,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;

Again:
   X:=(XResolution-XResearchInfoSize) shr 1 + (XResearchInfoSize-BigButtonXSize) shr 1;
   Y:=(YResolution-YResearchInfoSize) shr 1;
   Y:=Y+2*BigButtonYSize;
   Y2:=(YResearchInfoSize-4*BigButtonYSize-BigButtonYSize*4) div 5;
   Inc(Y,Y2);
   CreateButton(X,Y,0,0,False,_Temp1); ButtonText(_Temp1,65,'NEVYZKOUMaNO');
   Inc(Y,Y2); Inc(Y,SmallButtonYSize);
   CreateButton(X,Y,0,0,False,_Temp2); ButtonText(_Temp2,65,'VYZKOUMaNO');
   Inc(Y,Y2); Inc(Y,SmallButtonYSize);
   CreateButton(X,Y,0,0,False,_Temp3); ButtonText(_Temp3,65,'APLIKACE');
   Inc(Y,Y2); Inc(Y,SmallButtonYSize);
   CreateButton(X,Y,0,0,False,_Temp4); ButtonText(_Temp4,65,'KONEC');

   CursorOff;
   Release(_Temp1); Release(_Temp2); Release(_Temp3);
   Release(_Temp4);
   CursorOn;
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3);
   SetActive(_Temp4);
   ScreenOn;
   { ** vlastni prace s informacnim panelem ** }
   Konec:=False;
   while not (Konec) do begin
      Button:=0;
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin  { vyzkum }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);

                         SetAvailResearch(True);
                         SelectResearch(True);

                         X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
                         Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
                         CursorOff;
                         PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                         GoTo Again;
                      end;
         _Temp2     : begin  { vyzkoumane }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);

                         SetAvailResearch(False);
                         SelectResearch(False);

                         X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
                         Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
                         CursorOff;
                         PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                         GoTo Again;
                      end;
         _Temp3     : begin  { prirazeni technologii }
                         SoundPlay(0,0,0,0);
                         DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
                         DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
                         AssignResearch;
                         X:=(XResolution-XResearchInfoSize) div 2; X2:=X+XResearchInfoSize-1;
                         Y:=(YResolution-YResearchInfoSize) div 2; Y2:=Y+YResearchInfoSize-1;
                         CursorOff;
                         PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
                         CursorOn;
                         GoTo Again;
                      end;
         _Temp4     : begin  { vyber }
                         SoundPlay(0,0,0,0);
                         Konec:=True;
                      end;
      end;
   end;
   { ** konec prace s informacnim panelem ** }
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   CloseInfoPanel;
   if (GlobalSelectedResearch > 0) then begin
     Draw_active_research(GlobalSelectedResearch,
                          Research^[GlobalSelectedResearch].PercState,
                          True);
   end;

   SetActive(ResearchButton);
   SetActive(DalsiTydenButton);
   SetActive(CoreButton);
   SetActive(InfoButton);
   SetActive(OptionButton);
   SetActive(SaveButton);
   SetActive(LoadButton);
   SetActive(EndButton);
   SetActive(StartButton);
end;

{ ***** }
procedure Draw_active_research(Rsrch:Byte; Proceed:Single; NewRsrch:Boolean);
{ vytiskne informace o aktualnim vyzkumu Rsrch s procentualnim dokoncenim
 Proceed; NewRsrch = False pouze pro zmenu procent, True pro
 prekresleni vseho
}
var Ret:String;
    X,Y:Word;
    Mous:Boolean;
begin
 Mous:=TestMouse(X1RsrchInfo, Y1RsrchInfo, X2RsrchInfo, Y2RsrchInfo);
 if (Mous) then CursorOff;
 if (Rsrch > 0) then begin
   if (NewRsrch) then begin
   { vsechno inicializuj }
     if (ReserchInfoBckMemory < 65000) then
       PutImage(X1RsrchInfo,Y1RsrchInfo,ReserchInfoBckSeg,ReserchInfoBckOfs,NormalDirect)
     else
       PutImage(X1RsrchInfo,Y1RsrchInfo,ReserchInfoBckSeg,ReserchInfoBckOfs,
                NormalDirect);
{     Frame2(XResearchLeftTopText-4,YResearchLeftTopText-1,
            XResearchLeftTopText+8{Length(Research^[Rsrch].Name)*XFontSize+4,
            YResearchLeftTopText+YFontSize+1,68);{}
     OutTextColor(XResearchLeftTopText+2,YResearchLeftTopText+2,75,
                  Research^[Rsrch].Name);
     OutTextColor(XResearchLeftTopText,YResearchLeftTopText,64,
                  Research^[Rsrch].Name);

{     Frame2(X1ResearchFrame,Y1ResearchFrame,X2ResearchFrame,Y2ResearchFrame,64);
     {x}
     Str(Round(Proceed),Ret); Ret:=Ret+'%'; OldRetLength:=Length(Ret);
     X:=X2ResearchFrame-X1ResearchFrame-2;
     X:=X1ResearchFrame+1+Round(Proceed*((1.0*X)/100));
     Rectangle2(X1ResearchFrame+1,Y1ResearchFrame+1,X,Y2ResearchFrame-1,106);
     {x}
     X:=X1ResearchFrame+1+(X2ResearchFrame-X1ResearchFrame-Length(Ret)*XFontSize-2) shr 1;
     Y:=Y1ResearchFrame+1+(Y2ResearchFrame-Y1ResearchFrame-YFontSize-2) shr 1;
     { ulozeni pozadi pod textem }
     GetImage(X,Y,X+5*XFontSize,Y+YFontSize,
                   ReserchTextBckSeg, ReserchTextBckOfs,NormalDirect);
     OutTextColor(X+1,Y+1,75,Ret);
     OutTextColor(X,Y,64,Ret);
   end else begin
   { inicializuj pouze procenta }
     { obnova pozadi pod textem }
     Str(Round(Proceed),Ret); Ret:=Ret+'%';
     X:=X1ResearchFrame+1+(X2ResearchFrame-X1ResearchFrame-OldRetLength*XFontSize-2) shr 1;
     Y:=Y1ResearchFrame+1+(Y2ResearchFrame-Y1ResearchFrame-YFontSize-2) shr 1;
     PutImage(X,Y,ReserchTextBckSeg, ReserchTextBckOfs,NormalDirect);
     X:=X2ResearchFrame-X1ResearchFrame-2;
     X:=X1ResearchFrame+1+Round(Proceed*((1.0*X)/100));
     Rectangle2(X1ResearchFrame+1,Y1ResearchFrame+1,X,Y2ResearchFrame-1,106);
     {x}
     X:=X1ResearchFrame+1+(X2ResearchFrame-X1ResearchFrame-Length(Ret)*XFontSize-2) shr 1;
     Y:=Y1ResearchFrame+1+(Y2ResearchFrame-Y1ResearchFrame-YFontSize-2) shr 1;
     { ulozeni pozadi pod textem }
     GetImage(X,Y,X+5*XFontSize,Y+YFontSize,
                   ReserchTextBckSeg, ReserchTextBckOfs,NormalDirect);
     OutTextColor(X+1,Y+1,75,Ret);
     OutTextColor(X,Y,64,Ret);
     OldRetLength:=Length(Ret);
   end;
 end else begin
 { zadny globalni vyzkum nebyl vybran }
   if (ReserchInfoBckMemory < 65000) then
     PutImage(X1RsrchInfo,Y1RsrchInfo,ReserchInfoBckSeg,ReserchInfoBckOfs,NormalDirect)
   else
     PutImage(X1RsrchInfo,Y1RsrchInfo,ReserchInfoBckSeg,ReserchInfoBckOfs,
              NormalDirect);
 end;
 if (Mous) then CursorOn;
end;

{ ***** }
procedure ResearchStep;
{ provede krok ve vyzkumu; neni-li dost financi, zastavi vyzkum a upozorni,
  jinak ve vyzkumu pokracuje; pri dokonceni vyzkumu tez informuje
}
label Konec;
var Break:Boolean; { True, je-li vyzkum "breaknuty" }
    Str1, Str2, Str3, Ret:String;
begin
  if ((GlobalSelectedResearch = 0) or
      (Research^[GlobalSelectedResearch].PercState >=100))
  then begin
    if (DialogBox('NEMaTE ALOKOVaN kaDNj VjZKUM. CHCETE POKRAbOVAT?',_YES_NO) = NO)
    then Goto Konec;
  end;

  Break:=False;
  if ((ResearchRandomStep=2) and (Week >= (14+ResearchRandom))) then begin
    DialogBox('DcLE NEMikEME bEKAT !',_YES);
    Goto Konec;
  end;
  if ((ResearchRandomStep=1) and (Week >= (8+ResearchRandom))) then begin
    if (DialogBox('DALge bEKaNe NaS BUDE STaT FINANbNe PROSTfEDKY. POKRAbOVAT?',_YES_NO) = NO)
    then Goto Konec;
    ResearchRandomStep:=2; ResearchRandom:=Random(3);
  end;
  {x}
  if ((ResearchRandomStep=0) and (Week >= (4+ResearchRandom))) then begin
    if (DialogBox('DALge bEKaNe MikE VjRAZNd POSeLIT NEPfaTELE. POKRAbOVAT?',_YES_NO) = NO)
    then Goto Konec;
    ResearchRandomStep:=1; ResearchRandom:=Random(3);
  end;
  {x}
  if (GlobalSelectedResearch > 0) then
  with (Research^[GlobalSelectedResearch]) do begin
    if (PercState < 100) then begin
       if (Cost/ResearchTime > Points) then begin
          DialogBox('NEDOSTATEK BODi',_YES); Break:=True;
       end;
       if (not Break) then begin
         if (VCost/ResearchTime > VictoryPoints) then begin
             DialogBox('NEDOSTATEK VeTdZNjCH BODi',_YES); Break:=True;
         end;
       end;
       if (not Break) then begin
         if (((VICTORYPOINTS-VCost/ResearchTime) < VPointsPerMission) and
             (VICTORYPOINTS > 0) or
             ((POINTS-Cost/ResearchTime) < PointsPerMission) and
             (POINTS > 0))
         then begin
             Str(PointsPerMission,Str1); Str2:='CENA PfegTe MISE: KREDITY: '+Str1+',  ';
             Str(VPointsPerMission,Str1); Str2:=Str2+'PRESTIk: '+Str1;
             Str(Round(Cost/ResearchTime),Str1); Str3:='CENA VjZKUMU: KREDITY: '+Str1+',  ';
             Str(Round(VCost/ResearchTime),Str1); Str3:=Str3+'PRESTIk: '+Str1;
             if (WideDialogBox('BODY MOHOU BjT TfEBA PRO DALge MISI - CHCETE POKRAbOVAT?',
                               Str2,Str3,_YES_NO)=No)
             then begin
                Break:=True;
             end;
         end;
       end;

       if (not Break) then begin
          if (Week > (8+ResearchRandom)) then POINTS:=POINTS-100; DrawPoints;
          Inc(Week); Str(Week+1,Ret); ButtonText(DalsiTydenButton,TextColor,Ret+'. TjDEN');
          CursorOff; Release(DalsiTydenButton); CursorOn;
          {xxx}
          PercState:=PercState+100.0/ResearchTime;
          Points:=Points-Cost/ResearchTime;
          VictoryPoints:=VictoryPoints-VCost/ResearchTime;
          Draw_active_research(GlobalSelectedResearch,PercState,False);
          DrawPoints; DrawVictoryPoints;
       end;

       if (Round(PercState) >= 100) then begin
          PercState:=100;
          DialogBox('VjZKUM hSPdgNd UKONbEN',_YES);
          case (GlobalSelectedResearch) of
             33: ReserchAssign[10,1].UnitAvail:=1; {sakal}
             34: ReserchAssign[35,1].UnitAvail:=1; {houfnice}
             35: ReserchAssign[16,1].UnitAvail:=1; {tezky tank}
          end;
          GlobalSelectedResearch:=0;
          Draw_active_research(GlobalSelectedResearch,PercState,False);
       end;
    end else begin
      if (Week > (8+ResearchRandom)) then POINTS:=POINTS-100; DrawPoints;
      Inc(Week); Str(Week+1,Ret); ButtonText(DalsiTydenButton,TextColor,Ret+'. TjDEN');
      CursorOff; Release(DalsiTydenButton); CursorOn;
      {xxx}
    end;
  end else begin
     if (Week > (8+ResearchRandom)) then POINTS:=POINTS-100; DrawPoints;
     Inc(Week); Str(Week+1,Ret); ButtonText(DalsiTydenButton,TextColor,Ret+'. TjDEN');
     CursorOff; Release(DalsiTydenButton); CursorOn;
     {xxx}
  end;
Konec:
end;

{ ************************************************************************* }
begin
   MaxResearchAvailIndex:=MaxResearch;
   CurrentResearchAvailIndex:=1;
   SelectedResearch:=0;
   for I:=1 to MaxResearch do begin
     Research^[I].Validity:=False;
     ResearchAvail[I]:=I;
     for J:=0 to 4 do Research^[I].Descript[J]:='';
   end;
   GetMemory(LongInt(6*XFontSize*YFontSize)+4,ReserchTextBckSeg, ReserchTextBckOfs);
   if (ReserchTextBckSeg = 0) then begin
      Writeln('Chyba - nedostatek pameti'); Halt;
   end;
   TextMode:=False;
end.