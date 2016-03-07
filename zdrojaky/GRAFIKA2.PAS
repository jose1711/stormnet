{ $Q-}
unit Grafika2;
{$C FIXED PRELOAD PERMANENT}
interface
uses Data, Grafika, SBSound, SMIX;

procedure Error(Result : Word; Msg : String );
procedure Init_graphics_variables(XR,YR:Word);
procedure Init_gr_mode(X,Y:Word);
procedure GetSlotsInfo;
procedure MsgInit;
procedure Materials_info_init;
procedure ActiveDefenceRangeSlotsInit;
procedure SetActiveDefenceRangeSlotsActivity(Slot:Byte);
procedure ClearActiveDefenceRangeSlots;
function  TestActiveDefenceRangeSlots(XX,YY:Word):Byte;
procedure Init_price_bck_rectangle(X,Y,BP,PL,EE,EXP:Word);
procedure Draw_price_bck_rectangle(A,B,C,D:Word; DrawBck, GetBck:Boolean);
procedure Erase_price_bck_rectangle;
function Price_bck_rectangle_is_active:Boolean;
procedure Invalidate_price_bck_rectangle;
procedure New_resource(IPos,JPos,Resourc:Word);
function ReadRealTime(var HourMin : Word; var Second : Byte):Boolean;
procedure OutSmallMsg(Msg:String);
procedure OutBigMsg(Number:Byte; Msg:String);
procedure Print_game_time(Print:Boolean);
procedure RadarInit;
procedure DrawRadar;
procedure DrawRadarPixel(I,J:Word);
procedure RedrawRadarFrame(IPom,JPom:Word);
procedure ClearRadarFrame(IPom,JPom:Word);
procedure SetPixel(X,Y:Word; Color:Byte);
function GetPixelColor(X,Y : Word):Byte;
procedure SetFrame(A,B,C,D:Word; Color:Byte);
procedure Update_unit_char(_unit:PUnit; Damg,Moral,Exper:Boolean);
procedure Update_building_char(Build:PBuilding);
procedure Draw_building_production(Building : PBuilding);
procedure Update_building_production(Building : PBuilding; Ind:Byte);
procedure Select_group(Group:Byte);
procedure Deselect_group(Group:Byte);
procedure Select_unit(_unit:PUnit);
procedure Deselect_unit(_unit:PUnit);
procedure Click_on_group(Group : Byte);
procedure Click_on_unit(_unit:PUnit);
procedure Click_on_enemy_unit(_unit2:PUnit);
procedure Click_on_storage_unit(_unit2:PUnit);
procedure Select_slot(Slot:Byte; Flag:Boolean);
procedure Clear_group_slots;
procedure Clear_unit_slot(_unit:PUnit);
procedure Set_ok_cursor_mark(IC,JC:Word; Level:Byte);
procedure Ok_atack_cursor_mark_manager;
procedure Set_unit_building_shadow(IC,JC,ISize,JSize:Word);
procedure Set_attack_cursor_mark(UnitTarget:PPUnit; BuildingTarget:PPBuilding);
procedure Unit_building_shadow_manager;
procedure New_graphics_mode(XR,YR:Word);
procedure CreateMenuInfo(Index:Integer; Side:Word; Building:Boolean);
procedure MenuOptions;
procedure Grafika2_save;
procedure Grafika2_load;

var Price_bck_is_active : Boolean; { True .. obrazek s cenami je na obrazovce }
    X_price_bck_pos, Y_price_bck_pos : Word; { pozice leveho horniho rohu }
    Mous:Boolean; { pro potreby xxxMsg }
    UINfo : record { pomocna struktura pro info o jednotkach }
           Ind:Byte;
           Valid:Boolean;
           LA1,HA1,AA1,LA2,HA2,AA2:Word;
           Name:String;
           Rank:BYte;
           DAMAGE:WORD;
        end;


implementation
uses Graph257, Mouse, Buttons, _units, _units2, _units3, _shot, Grafika4,
    _races, Dos, Crt, _buildings;
var ActiveDefenceStruct : record
        Active:Byte; { aktivni slot; 255 = neaktivni }
        Present:Boolean; { je tato struktura na obrazovce ? }
        XB,YB,Segment,Offsets:Word; { zacatek celeho zaznamu + ulozene pozadi }
        Boxes:array[0..4] of record { info o jednotlivych okynkach }
                               X1,Y1,X2,Y2:Word;
                             end;
    end;
    Skip:Boolean;

    X_PBR, Y_PBR, BP_PBR, PL_PBR, EE_PBR, EXP_PBR :Word;

{ ***** }
procedure Error(Result : Word; Msg : String );
{ ukonci program s chybou
  je-li promenna Result = 0, vypise se pouze retezec Msg
  je-li promenna Result <> 0 a zaroven je Result v rozmezi 30..45
  (chyby pri praci s GRAPH256), vypise se cislo chyby Result a
  specifikace chyby IO_ResultString
  jinak se vypise cislo chyby Result a retezec Msg
}
var Pom:Byte;
    I:Word;
    PomStr:String;
begin
   InvalidateCache;
   if (not InDrawResult) then DrawResult;
   for I:=1 to Length(Msg) do Msg[I]:=Upcase(Msg[I]);
   Str(Result,PomStr);
   if (Result <> 0) then begin
      if ((Result >= 30) and (Result <= 45)) then ErrorString:='CHYBA '+Msg
      else ErrorString:='CHYBA '+Msg+' - DISKOVA CHYBA CISLO '+ PomStr;
   end else begin
      ErrorString:='CHYBA - '+ Msg;
   end;
   Halt(MaxInt);
end;

{ ***** }
procedure Init_gr_mode(X,Y:Word);
{ nainicializuje graficky rezim v rozliseni X*Y; pokud dojde k chybe
  pri detekci SVGA karty nebo EMS manazeru, nahlasi chybu a ukonci program
}
var Result:Word;
begin
   if (Debug) then Result:=GraphInit(X,Y,X,Y)
   else Result:=GraphInit(X,Y,X+40,Y);
   XRes:=X; YRes:=Y;
   if (Result = 1) then Error(0,' videokarta nepodporuje VESA standard');
   if (Result = 2) then Error(0,' videokarta dane rozliseni nepodporuje');
   if (Result > 2) then Error(0,' nespecifikovana chyba pri graficke inicializaci');
   if (not InitMouse(X,Y)) then Error(0,' neuspesna inicializace mysi');
   ClearScreen;
   Init_graphics_variables(X,Y);
   SetCursorRange(0,0,X-4,Y-4);
end;

{ ***** }
procedure GetSlotsInfo;
{ nacte informace o pozadi na miste informacnich slotu
}
var Offs, X, Y, YAdd : Word;
    I, J:Integer;
begin
   Offs:=0;
   case (XResolution) of
     640 : begin
             GroupsBckXSize:=35; GroupsBckYSize:=60;
             with (GroupsBck[0]) do begin
               X:=52; Y:=124; X1:=51; Y1:=158; X2:=51; Y2:=164; X3:=51; Y3:=169; end;
             with (GroupsBck[1]) do begin
               X:=7; Y:=165; X1:=7; Y1:=199; X2:=7; Y2:=205; X3:=7; Y3:=210; end;
             with (GroupsBck[2]) do begin
               X:=52; Y:=183; X1:=51; Y1:=217; X2:=51; Y2:=223; X3:=51; Y3:=228; end;
             with (GroupsBck[3]) do begin
               X:=95; Y:=165; X1:=95; Y1:=199; X2:=95; Y2:=205; X3:=95; Y3:=210; end;
             with (GroupsBck[4]) do begin
               X:=7; Y:=224; X1:=7; Y1:=258; X2:=7; Y2:=264; X3:=7; Y3:=269; end;
             with (GroupsBck[5]) do begin
               X:=52; Y:=242; X1:=51; Y1:=276; X2:=51; Y2:=282; X3:=51; Y3:=287; end;
             with (GroupsBck[6]) do begin
               X:=95; Y:=224; X1:=95; Y1:=258; X2:=95; Y2:=264; X3:=95; Y3:=269; end;
             with (GroupsBck[7]) do begin
               X:=7; Y:=283; X1:=7; Y1:=317; X2:=7; Y2:=323; X3:=7; Y3:=328; end;
             with (GroupsBck[8]) do begin
               X:=52; Y:=301; X1:=51; Y1:=335; X2:=51; Y2:=341; X3:=51; Y3:=346; end;
             with (GroupsBck[9]) do begin
               X:=95; Y:=283; X1:=95; Y1:=317; X2:=95; Y2:=323; X3:=95; Y3:=328; end;
           end;
     800 : begin
             GroupsBckXSize:=35; GroupsBckYSize:=60;
             with (GroupsBck[0]) do begin
               X:=52+11; Y:=124+61; X1:=51+12; Y1:=158+62; X2:=51+12; Y2:=164+62; X3:=51+12; Y3:=169+62; end;
             with (GroupsBck[1]) do begin
               X:=7+11; Y:=165+61; X1:=7+12; Y1:=199+62; X2:=7+12; Y2:=205+62; X3:=7+12; Y3:=210+62; end;
             with (GroupsBck[2]) do begin
               X:=52+11; Y:=183+61; X1:=51+12; Y1:=217+62; X2:=51+12; Y2:=223+62; X3:=51+12; Y3:=228+62; end;
             with (GroupsBck[3]) do begin
               X:=95+12; Y:=165+62; X1:=95+12; Y1:=199+62; X2:=95+12; Y2:=205+62; X3:=95+12; Y3:=210+62; end;
             with (GroupsBck[4]) do begin
               X:=7+11; Y:=224+61; X1:=7+12; Y1:=258+62; X2:=7+12; Y2:=264+62; X3:=7+12; Y3:=269+62; end;
             with (GroupsBck[5]) do begin
               X:=52+11; Y:=242+61; X1:=51+12; Y1:=276+62; X2:=51+12; Y2:=282+62; X3:=51+12; Y3:=287+62; end;
             with (GroupsBck[6]) do begin
               X:=95+12; Y:=224+62; X1:=95+12; Y1:=258+62; X2:=95+12; Y2:=264+62; X3:=95+12; Y3:=269+62; end;
             with (GroupsBck[7]) do begin
               X:=7+11; Y:=283+61; X1:=7+12; Y1:=317+62; X2:=7+12; Y2:=323+62; X3:=7+12; Y3:=328+62; end;
             with (GroupsBck[8]) do begin
               X:=52+11; Y:=301+61; X1:=51+12; Y1:=335+62; X2:=51+11; Y2:=341+62; X3:=51+12; Y3:=346+62; end;
             with (GroupsBck[9]) do begin
               X:=95+12; Y:=283+62; X1:=95+12; Y1:=317+62; X2:=95+11; Y2:=323+62; X3:=95+12; Y3:=328+62; end;
           end;
     1024: begin
             GroupsBckXSize:=35; GroupsBckYSize:=60; YAdd:=94;
             with (GroupsBck[0]) do begin
               X:=52+14; Y:=124+61+YAdd; X1:=51+15; Y1:=158+62+YAdd; X2:=51+14; Y2:=164+62+YAdd; X3:=51+15;Y3:=169+62+YAdd;end;
             with (GroupsBck[1]) do begin
               X:=7+14; Y:=165+61+YAdd; X1:=7+15; Y1:=199+62+YAdd; X2:=7+14; Y2:=205+62+YAdd; X3:=7+15; Y3:=210+62+YAdd; end;
             with (GroupsBck[2]) do begin
               X:=52+14; Y:=183+61+YAdd; X1:=51+15; Y1:=217+62+YAdd; X2:=51+14; Y2:=223+62+YAdd; X3:=51+15;Y3:=228+62+YAdd;end;
             with (GroupsBck[3]) do begin
               X:=95+15; Y:=165+62+YAdd; X1:=95+15; Y1:=199+62+YAdd; X2:=95+14; Y2:=205+62+YAdd; X3:=95+15;Y3:=210+62+YAdd;end;
             with (GroupsBck[4]) do begin
               X:=7+14; Y:=224+61+YAdd; X1:=7+15; Y1:=258+62+YAdd; X2:=7+14; Y2:=264+62+YAdd; X3:=7+15; Y3:=269+62+YAdd; end;
             with (GroupsBck[5]) do begin
               X:=52+14; Y:=242+61+YAdd; X1:=51+15; Y1:=276+62+YAdd; X2:=51+14; Y2:=282+62+YAdd; X3:=51+15;Y3:=287+62+YAdd;end;
             with (GroupsBck[6]) do begin
               X:=95+15; Y:=224+62+YAdd; X1:=95+15; Y1:=258+62+YAdd; X2:=95+14; Y2:=264+62+YAdd; X3:=95+15;Y3:=269+62+YAdd;end;
             with (GroupsBck[7]) do begin
               X:=7+14; Y:=283+61+YAdd; X1:=7+15; Y1:=317+62+YAdd; X2:=7+14; Y2:=323+62+YAdd; X3:=7+15; Y3:=328+62+YAdd; end;
             with (GroupsBck[8]) do begin
               X:=52+14; Y:=301+61+YAdd; X1:=51+15; Y1:=335+62+YAdd; X2:=51+13; Y2:=341+62+YAdd; X3:=51+15;Y3:=346+62+YAdd;end;
             with (GroupsBck[9]) do begin
               X:=95+15; Y:=283+62+YAdd; X1:=95+15; Y1:=317+62+YAdd; X2:=95+13; Y2:=323+62+YAdd; X3:=95+15;Y3:=328+62+YAdd;end;
           end;
     1280 :begin
           end;
   end;

   for I:=0 to MaxGroupUnits-1  do begin
     GroupsBck[I].Offsets:=Offs;
     with (GroupsBck[I]) do
        SpeedGetImage(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize,BckSegment,Offs);
     Inc(Offs,(GroupsBckXSize+1)*(GroupsBckYSize+1)+4);
   end;

end;

procedure MsgInit;
{ inicializuje malou i velkou oblast pro vypis retezce
}
begin
   with (MsgStruct) do begin
      GetMemory(SmallMsgMem, SmallMsgBckSeg, SmallMsgBckOffs);
      GetMemory(SmallMsgMem, SmallMsgBckSeg2, SmallMsgBckOffs2);
      { pozadi maleho textu }
      GetMemory(BigMsgMem, BigMsgBckSeg, BigMsgBckOffs);
      { pozadi velke hlasky }
      if (SmallMsgBckSeg = 0) then Error(0,'nedostek pameti');
      if (SmallMsgBckSeg2 = 0) then Error(0,'nedostek pameti');
      if (BigMsgBckSeg = 0) then Error(0,'nedostek pameti');

      SmallXBegin:=SmallXBeginConst;
      SmallYBegin:=SmallYBeginConst;  { zacatek maleho textu }
      BigXBegin:=BigXBeginConst;
      BigYBegin:=BigYBeginConst; { zacatek velkeho textu }
      { nyni uchovani pozadi }
      SpeedGetImage(SmallXBegin,SmallYBegin,
                    SmallXBegin+SmallMsgLen*XFontSize+3,SmallYBegin+YFontSize,
                    SmallMsgBckSeg, SmallMsgBckOffs);
      if (SmallYMsgDistance <> 0) then
        SpeedGetImage(SmallXBegin,SmallYBegin+SmallYMsgDistance,
                      SmallXBegin+SmallMsgLen*XFontSize+3,SmallYBegin+YFontSize+SmallYMsgDistance,
                      SmallMsgBckSeg2, SmallMsgBckOffs2);
      SpeedGetImage(BigXBegin,BigYBegin,
                    BigXBegin+BigMsgLen*XFontSize+3,BigYBegin+YFontSize,
                    BigMsgBckSeg, BigMsgBckOffs);
      {Frame2(BigXBegin-4,BigYBegin-4, BigXBegin+BigMsgLen*XFontSize+5,
            BigYBegin+YFontSize+5,15);
      Frame2(BigXBegin-3,BigYBegin-3, BigXBegin+BigMsgLen*XFontSize+4,
            BigYBegin+YFontSize+4,15);{}

      SmallTimeHourMin:=0; SmallTimeSec:=0;
      BigTimeHourMin:=0; BigTimeSec:=0;
   end;
end;

{ ***** }
procedure Materials_info_pom;
{ patri procedure Materials_info_init
}
var X, Y, Pom: Word;
begin
   { 1. slot  - stavebni kredity }
   SpeedPutImage2(XMaterialPicture1,YMaterialPicture1,First_material_segment, First_material_offset);
   Rectangle2(XMaterialNumber1,YMaterialNumber1,XMaterialNumber1+XMaterialNumberLength,YMaterialNumber1+YMaterialSlotSize,0);
   { 2. slot  - plasty }
   SpeedPutImage2(XMaterialPicture2,YMaterialPicture2,Second_material_segment, Second_material_offset);
   Rectangle2(XMaterialNumber2,YMaterialNumber2,XMaterialNumber2+XMaterialNumberLength,YMaterialNumber2+YMaterialSlotSize,0);
   { 3. slot  - elektricka energie }
   SpeedPutImage2(XMaterialPicture3,YMaterialPicture3,Third_material_segment, Third_material_offset);
   Rectangle2(XMaterialNumber3,YMaterialNumber3,XMaterialNumber3+XMaterialNumberLength,YMaterialNumber3+YMaterialSlotSize,0);
   { 4. slot  - zkusenost }
   SpeedPutImage2(XMaterialPicture4,YMaterialPicture4,Fourth_material_segment, Fourth_material_offset);
   Rectangle2(XMaterialNumber4,YMaterialNumber4,XMaterialNumber4+XMaterialNumberLength,YMaterialNumber4+YMaterialSlotSize,0);
end;

{ ***** }
procedure Materials_info_init;
{ inicializuje sloty s udaji o dostupnych materialech
}
var X, Y, Pom: Word;
    Size:LongInt;
begin
   { nahrani obrazku }
   OpenImage('.\data\hlp',NoCreateNew);  {  }
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   GetXYIMageCoordinatesGBM(X,Y,'buildpoi');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Size:=LongInt(X)*Y+4;
   GetMemory(Size,First_material_segment, First_material_offset);
   if (First_material_segment = 0) then Error(0,'nedostatek pameti');
   GetMemory(Size,Second_material_segment, Second_material_offset);
   if (Second_material_segment = 0) then Error(0,'nedostatek pameti');
   GetMemory(Size,Third_material_segment, Third_material_offset);
   if (Third_material_segment = 0) then Error(0,'nedostatek pameti');
   GetMemory(Size,Fourth_material_segment, Fourth_material_offset);
   if (Fourth_material_segment = 0) then Error(0,'nedostatek pameti');

   LoadImageGBM(First_material_segment, First_material_offset,'buildpoi',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(Second_material_segment, Second_material_offset,'plast',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(Third_material_segment, Third_material_offset,'energy',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   LoadImageGBM(Fourth_material_segment, Fourth_material_offset,'experien',0);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor .\data\hlp');
   Materials_info_pom;
end;

{ ***** }
procedure ActiveDefenceRangeSlotsInit;
{ inicializuje sloty s volbou vzdalenosti aktivni obrany
}
var X,Y,X2,Y2:Word;
    Mem:LongInt;
begin with (ActiveDefenceStruct) do begin
   Active:=255; Present:=False;
   case (XResolution) of  { ! DOPLN ! }
     640 : begin
              X:=4; X2:=127;
              Y:=452; Y2:=479;
           end;
     800 : begin
              X:=17; X2:=140;
              Y:=574; Y2:=599;
           end;
     1024 :begin
              X:=20; X2:=143;
              Y:=742; Y2:=778;
           end;
     1280 :begin
              X:=4; X2:=127;
              Y:=452; Y2:=479;
           end;
    end;

   XB:=X; YB:=Y;
   Mem:={(X2-X+1)*(Y2-Y+1)+4{}10000;
   if (Segment = 0) then GetMemory(Mem,Segment,Offsets);
   SpeedGetImage(X,Y,X2,Y2,Segment,Offsets);

   Boxes[0].X1:=11+X; Boxes[0].Y1:=0+Y;
   Boxes[0].X2:=37+X; Boxes[0].Y2:=25+Y;
   {*}
   Boxes[1].X1:=38+X; Boxes[1].Y1:=0+Y;
   Boxes[1].X2:=53+X; Boxes[1].Y2:=25+Y;
   {*}
   Boxes[2].X1:=54+X; Boxes[2].Y1:=0+Y;
   Boxes[2].X2:=76+X; Boxes[2].Y2:=25+Y;
   {*}
   Boxes[3].X1:=77+X; Boxes[3].Y1:=0+Y;
   Boxes[3].X2:=97+X; Boxes[3].Y2:=25+Y;
   {*}
   Boxes[4].X1:=98+X; Boxes[4].Y1:=0+Y;
   Boxes[4].X2:=117+X; Boxes[4].Y2:=25+Y;
   {*}
end; end;

{ ***** }
procedure SetActiveDefenceRangeSlotsActivity(Slot:Byte);
{ nastavi slot Slot jako aktivni
}
var I:Word;
begin with (ActiveDefenceStruct) do begin
   if (not Present) then begin
   { je treba vykreslit celou strukturu }
      Present:=True;
      Active:=Slot;
      CursorOff;
      case (Slot) of
        0 : SpeedPutImage2(XB,YB,ADMSeg1,ADMOfs1);
        1 : SpeedPutImage2(XB,YB,ADMSeg2,ADMOfs2);
        2 : SpeedPutImage2(XB,YB,ADMSeg3,ADMOfs3);
        3 : SpeedPutImage2(XB,YB,ADMSeg4,ADMOfs4);
        4 : SpeedPutImage2(XB,YB,ADMSeg5,ADMOfs5);
      end;
      CursorOn;
   end else begin
   { premaz pouze aktualni nastaveni }
      Present:=True;
      Active:=Slot;
      CursorOff;
      case (Slot) of
        0 : SpeedPutImage2(XB,YB,ADMSeg1,ADMOfs1);
        1 : SpeedPutImage2(XB,YB,ADMSeg2,ADMOfs2);
        2 : SpeedPutImage2(XB,YB,ADMSeg3,ADMOfs3);
        3 : SpeedPutImage2(XB,YB,ADMSeg4,ADMOfs4);
        4 : SpeedPutImage2(XB,YB,ADMSeg5,ADMOfs5);
      end;
      CursorOn;
   end;
end; end;

{ ***** }
procedure ClearActiveDefenceRangeSlots;
{ zrusi sloty
}
begin with (ActiveDefenceStruct) do begin
   if (Present) then begin
   { je treba vykreslit celou strukturu }
      Present:=False; Active:=255;
      CursorOff;
      SpeedPutImage(XB,YB,Segment,Offsets);
      CursorOn;
   end;
end; end;

{ ***** }
function TestActiveDefenceRangeSlots(XX,YY:Word):Byte;
{ otestuje, zda se souradnice X,Y nachazi uvnitr nejakeho slotu;
  pri uspechu vraci cislo daneho slotu, pri neuspechu pak 255
}
var Number,Slot:Byte;
    Konec:Boolean;
begin
  with (ActiveDefenceStruct) do if (Present) then begin
    Number:=0; Konec:=False; Slot:=255;
    while (not Konec) do begin
      with (Boxes[Number]) do begin
        if ((X1<=XX) and (X2>=XX) and (Y1<=YY) and (Y2>=YY)) then begin
           Konec:=True;
           Slot:=Number;
        end else begin
          Inc(Number);
          Konec:=(Number > 4);
        end;
      end;   { with }
    end;   { while }
  end else Slot:=255;
  TestActiveDefenceRangeSlots:=Slot
end;

{ ***** }
procedure Init_price_bck_rectangle(X,Y,BP,PL,EE,EXP:Word);
{ od pozice X,Y inicializuje ramecek
}
var Ret:String;
    I:Word;
begin
   X_PBR:=X; Y_PBR:=Y; BP_PBR:=BP; PL_PBR:=PL;
   EE_PBR:=EE; EXP_PBR:=EXP;
   Price_bck_is_active:=True;

   Mous:=TestMouse(X_PBR,Y_PBR,X_PBR+Price_bck_X_size-1,Y_PBR+Price_bck_Y_size-1) and
         (CursorVisibility > 0);
   if (Mous) then CursorOff;
   SpeedGetImage(X_PBR,Y_PBR,X_PBR+Price_bck_X_size-1,Y_PBR+Price_bck_Y_size-1,
                 Price_bck_segment,Price_bck_offset);
   X_price_bck_pos:=X_PBR; Y_price_bck_pos:=Y_PBR;
{   Frame(X_PBR,Y_PBR,X_PBR+Price_bck_X_size-1,Y_PBR+Price_bck_Y_size-1,FrameColor-2);
   Frame(X_PBR+1,Y_PBR+1,X_PBR+Price_bck_X_size-2,Y_PBR+Price_bck_Y_size-2,FrameColor+2);{}
   Rectangle(X_PBR+2,Y_PBR+2,X_PBR+Price_bck_X_size-3,Y_PBR+Price_bck_Y_size-3,{205}0);{}
   X:=X_PBR+2; Y:=Y_PBR;
   {Inc(X,6); Inc(Y,4);{}
   Str(BP_PBR,Ret);
   if (Length(Ret) < 3) then
     for I:=1 to 3-Length(Ret) do Ret:=Ret+' ';
   OutTextColorBlackBck(X,Y,64,' SM: '+Ret); Inc(Y,YFontSize);
   Str(PL_PBR,Ret);
   if (Length(Ret) < 3) then
     for I:=1 to 3-Length(Ret) do Ret:=Ret+' ';
   OutTextColorBlackBck(X,Y,64,' PL: '+Ret); Inc(Y,YFontSize);
   Str(EE_PBR,Ret);
   if (Length(Ret) < 3) then
     for I:=1 to 3-Length(Ret) do Ret:=Ret+' ';
   OutTextColorBlackBck(X,Y,64,' EE: '+Ret); Inc(Y,YFontSize);
   Str(Exp_PBR,Ret);
   if (Length(Ret) < 3) then
     for I:=1 to 3-Length(Ret) do Ret:=Ret+' ';
   OutTextColorBlackBck(X,Y,64,' ZK: '+Ret);
   SpeedGetImage(X_PBR,Y_PBR,X_PBR+Price_bck_X_size-1,Y_PBR+Price_bck_Y_size-1,
                 Price_segment,Price_offset);
   SpeedPutImage(X_price_bck_pos, Y_price_bck_pos,Price_bck_segment,Price_bck_offset);
   SpeedPutImage2(X_PBR,Y_PBR,Price_segment,Price_offset);
   if (Mous) then CursorOn;
end;

{ ***** }
procedure Draw_price_bck_rectangle(A,B,C,D:Word; DrawBck,GetBck:Boolean);
{ od pozice X,Y vykresli ramecek s cenami BP,PL,EE,EXP
  A,B,C,D jsou souradnice prekreslovane plochy
  DrawBck = True, pokud se ma vykreslit jen puvodni pozadi
          = False - ulozi se puvodni pozadi a ramecek se znovu vykresli
  GetBck = True - ulozi se i pozadi
}
var Ret:String[10];
    Mous : Boolean;
    X,Y:Word;

function Test:Boolean;
{
}
begin
   if ((A <= (X_PBR+Price_bck_X_size)) and
       (C >= X_PBR) and
       (B <= (Y_PBR+Price_bck_Y_size)) and (D >= Y_PBR)) then begin
     Test:=True;
   end else Test:=False;
end;
{*** }
begin
  if (Price_bck_is_active and Test) then begin
     Mous:=TestMouse(X_PBR,Y_PBR,X_PBR+Price_bck_X_size-1,Y_PBR+Price_bck_Y_size-1) and
           (CursorVisibility > 0);
     if (Mous) then CursorOff;
     if (DrawBck) then SpeedPutImage(X_price_bck_pos, Y_price_bck_pos,Price_bck_segment,Price_bck_offset)
     else begin
        if (GetBck) then
           SpeedGetImage(X_PBR,Y_PBR,X_PBR+Price_bck_X_size-1,Y_PBR+Price_bck_Y_size-1,
                         Price_bck_segment,Price_bck_offset);
        SpeedPutImage2(X_PBR,Y_PBR,Price_segment,Price_offset);
     end;
     if (Mous) then CursorOn;
  end;
end;

{ ***** }
procedure Erase_price_bck_rectangle;
{ smaze ramecek s cenami na pozici X_price_bck_pos, Y_price_bck_pos
}
var Mous : Boolean;
begin
  if (Price_bck_is_active) then begin
     Mous:=(TestMouse(X_price_bck_pos,Y_price_bck_pos,
                     X_price_bck_pos+Price_bck_X_size-1,
                     Y_price_bck_pos+Price_bck_Y_size-1) and
            (CursorVisibility > 0));
     if (Mous) then CursorOff;
     SpeedPutImage(X_price_bck_pos, Y_price_bck_pos,Price_bck_segment,Price_bck_offset);
     if (Mous) then CursorOn;
  end;
end;

function Price_bck_rectangle_is_active:Boolean;
{
}
begin
   Price_bck_rectangle_is_active:=Price_bck_is_active;
end;

{ ***** }
procedure Invalidate_price_bck_rectangle;
{
}
begin
   Price_bck_is_active:=False;
end;

{ ***** }
procedure New_resource(IPos,JPos,Resourc:Word);
{ procedura vytvori na policku IPos,JPos zdroj o mocnosti Resource a
  zobrazi jej na obrazovce (je-li viditelny)
}
const Way    = 46;  { maximalni index daneho terenu  - cesty }
      Grass  = 156; { trava }
      Field  = 156; { pole = trava }
      Resrc  = 168; { resource - "skladka" materialu }
      Desert = 168; { poust = neexistuje }
      Hill   = 195; { kopec }
      Wather = 201; { voda }
      Wood   = 249; { les }
      Airport= 250; { letiste }
var Pom1:Single;
    Pom:Word;
begin
   if (LastUsedResource = MaxResourceIndex) then
      Error(0,'unita grafika2 - prekrocen maximalni pocet zdroju')
   else begin
      if (LastUsedResource = MaxResourceIndex+1) then
         LastUsedResource:=0
      else
         Inc(LastUsedResource);
      with (ResourceInfo[LastUsedResource]) do begin
        IResourPos:=IPos; JResourPos:=JPos;
        Resource:=Resourc;
        Resource:=Resource*4; { krat 4 pro lepsi vypocet }
        MapBck^[IPos,JPos].Info:=LastUsedResource;
        Pom1:=MaxResource / (Resource / 4);
        if (Pom1 <= 1) then Pom:=Resrc-3 { 100% az 51% max. hodnoty zdroje }
        else
          if (Pom1 = 2) then Pom:=Field+1+4 { 50% az 33% max. hodnoty zdroje}
          else
            Pom:=Field+1;  { mene nez 33% maximalni hodnoty zdroje }
        { v dane ctverici se nahodne vygeneruje 1 obrazek }

        MapBck^[IPos,JPos].BckType:=Byte(Pom+(Round(Resource) mod 4) shr 1);
        Transfer_map_frame(IPos,JPos,IPos+1,JPos+1); { !! IF VISIBLE !! }
        {if (NetType = 1) then begin
           IPX_SendByte(18);
           IPX_SendWord(IPos); IPX_SendWord(JPos); IPX_SendWord(Resourc);
           IPX_SendByte(Pom+Pom1);
        end;{}
      end;
   end;
end;

{ ***** }
function ReadRealTime(var HourMin : Word; var Second : Byte):Boolean;
{ vraci True, je-li cteni casu OK
 v HourMin vraci vyssi - hodiny, nizsi - minuty, v Second vteriny
}
var Pom1 : Word;
    Pom2 : Byte;
begin
   asm
     mov Ah,02h
     int 1ah
     jc @NotSuccesfull { hodiny realneho casu nepracuji dobre }

     xor Ah,Ah
     mov Al,Dh
     shl Ax,4
     shr Al,4
     aad
     mov Pom2, Al

     xor Ah,Ah
     mov Al,Cl
     shl Ax,4
     shr Al,4
     aad
     mov Dl,Al
     xor Ah,Ah
     mov Al,Ch
     shl Ax,4
     shr Al,4
     aad
     mov Dh,Al

     mov Pom1, Dx
     mov @Result,1
     jmp @end
@NotSuccesfull:
     mov @Result,0
@end:
   end;
   HourMin:=Pom1;
   Second:=Pom2;
end;

{ ***** }
procedure OutSmallMsg(Msg:String);
{ procedura vypise malou hlasku
}
const TimerAdd = 59; { v podstate delka (ve vterinach), se kterou hlaska
                       vydrzi na obrazovce }
begin
   with (MsgStruct) do begin
      Mous:= TestMouse(SmallXBegin,SmallYBegin,
                       SmallXBegin+SmallMsgLen*XFontSize,SmallYBegin+YFontSize) or
             TestMouse(SmallXBegin,SmallYBegin+SmallYMsgDistance,
                       SmallXBegin+SmallMsgLen*XFontSize,SmallYBegin+YFontSize+SmallYMsgDistance);
      if (Mous) then CursorOff;
      Draw_price_bck_rectangle(SmallXBegin,SmallYBegin,
                               SmallXBegin+SmallMsgLen*XFontSize,
                               SmallYBegin+YFontSize,True,False);
      if ((SmallTimeHourMin > 0) or (SmallTimeSec > 0)) then begin
      { vymaz puvodni hlasku }
         SpeedPutImage(SmallXBegin,SmallYBegin,
                       SmallMsgBckSeg, SmallMsgBckOffs);
         if (SmallYMsgDistance <> 0) then
           SpeedPutImage(SmallXBegin,SmallYBegin+SmallYMsgDistance,
                         SmallMsgBckSeg2, SmallMsgBckOffs2);
      end;
      if (Msg <> '') then begin
        Rectangle2(SmallXBegin,SmallYBegin,SmallXBegin+SmallMsgLen*XFontSize-3,
                   SmallYBegin+YFontSize,0);
        if (SmallYMsgDistance <> 0) then
           Rectangle2(SmallXBegin,SmallYBegin+SmallYMsgDistance,SmallXBegin+SmallMsgLen*XFontSize-3,
                      SmallYBegin+YFontSize+SmallYMsgDistance,0);

      end;
      OutTextColor(SmallXBegin,SmallYBegin,162,Msg);
      if (SmallYMsgDistance <> 0) then
         OutTextColor(SmallXBegin,SmallYBegin+SmallYMsgDistance,162,Msg);
      Draw_price_bck_rectangle(SmallXBegin,SmallYBegin,
                               SmallXBegin+SmallMsgLen*XFontSize,
                               SmallYBegin+YFontSize,False,True);
      if (Mous) then CursorOn;

      if (ReadRealTime(SmallTimeHourMin, SmallTimeSec)) then begin
      { OK, nastav cas vymazu }
         if ((SmallTimeSec + TimerAdd) >  59) then begin
            Inc(SmallTimeHourMin,(SmallTimeSec + TimerAdd) div 60);
            SmallTimeSec:=(SmallTimeSec + TimerAdd) mod 60;
         end else Inc(SmallTimeSec, TimerAdd);
      end else Error(0,'Chyba pri cteni hodin realneho casu');
   end;
end;

{ ***** }
procedure OutBigMsg(Number:Byte; Msg:String);
{ procedura vypise velkou hlasku;
  je-li Number = 255, pak nic, jinak se hlasku zahlasi zvukove
}
const TimerAdd = 4; { v podstate delka (ve vterinach), se kterou hlaska
                       vydrzi na obrazovce }
begin
   if (Number < 255) then begin
   { zvukova hlaska }
     PreparePlaySound(5,0,Number-1,0);
   end;
   with (MsgStruct) do begin
      Mous:=TestMouse(BigXBegin,BigYBegin,
                      BigXBegin+BigMsgLen*XFontSize,BigYBegin+YFontSize);
      if (Mous) then CursorOff;
      if ((BigTimeHourMin > 0) or (BigTimeSec > 0)) then begin
      { vymaz puvodni hlasku }
         SpeedPutImage(BigXBegin,BigYBegin,
                       BigMsgBckSeg, BigMsgBckOffs);
      end;
      OutTextColor(BigXBegin,BigYBegin,14,Msg);
      if (Mous) then CursorOn;

      if (ReadRealTime(BigTimeHourMin, BigTimeSec)) then begin
      { OK, nastav cas }
         if ((BigTimeSec + TimerAdd) > 59) then begin
            Inc(BigTimeHourMin,(BigTimeSec + TimerAdd) div 60);
            BigTimeSec:=(BigTimeSec + TimerAdd) mod 60;
         end else Inc(BigTimeSec, TimerAdd);
      end else Error(0,'Chyba pri cteni hodin realneho casu');
   end; { with (MsgStruct) do begin }
end;

{ ***** }
procedure Print_game_time(Print:Boolean);
{ udrzuje "realne herni hodiny"
  je-li False, vypise cas pouze pri zmene hodin
}
var Pom, Pom2 : String;
    Mous:Boolean;
begin
   if (Retreat) then begin
   { ustup, hodiny budou zobrazovat cas do konce ustupu }
      if (RetreatTimmer mod 4 = 0) then Str(RetreatTimmer div 4,Pom)
      else Pom:='';
      if ((Pom <> '') or Print) then begin
         Mous:=TestMouse(Game_timeXBeg,Game_timeYBeg,
                         Game_timeXBeg+Game_timeXLength,
                         Game_timeYBeg+Game_timeYLength);
         if (Mous) then CursorOff;
         Rectangle(Game_timeXBeg+1,Game_timeYBeg+1,
                   Game_timeXBeg+Game_timeXLength-1 ,
                   Game_timeYBeg+Game_timeYLength-1,0);
         OutTextColor(Game_timeXBeg+(Game_timeXLength-Length(Pom)*XFontSize) shr 1,
                      Game_timeYBeg+(Game_timeYLength-YFontSize) shr 1,80,Pom);
         if (Mous) then CursorOn;
      end;
   end else begin
      if (Flag_game_time >= MaxFlag_game_time) then begin
         Inc(Sec_game_time);
         if (Sec_game_time >= 60) then begin
           Sec_game_time:=0;
           Inc(Min_game_time);
           if (Min_game_time >= 60) then begin
             Min_game_time:=0;
             if (TimeSlot >= 255) then TimeOverflow:=True;
           end;
         end;
      end;
      if ((Flag_game_time >= MaxFlag_game_time) or Print) then begin
         Flag_game_time:=0;
         Str(Min_game_time,Pom);
         if (Min_game_time < 10) then Pom:='0'+Pom;
         Str(Sec_game_time,Pom2);
         if (Sec_game_time < 10) then Pom2:='0'+Pom2;
         Pom:=Pom+':'+Pom2;
         Mous:=TestMouse(Game_timeXBeg,Game_timeYBeg,
                         Game_timeXBeg+Game_timeXLength,
                         Game_timeYBeg+Game_timeYLength);
         if (Mous) then CursorOff;
         Rectangle(Game_timeXBeg+1,Game_timeYBeg+1,
                   Game_timeXBeg+Game_timeXLength-1 ,
                   Game_timeYBeg+Game_timeYLength-1,0);
         OutText(Game_timeXBeg+5,
                 Game_timeYBeg+(Game_timeYLength-YFontSize) shr 1,Pom);
         if (Mous) then CursorOn;
      end;
   end;
end;

{ ***** }
function EqualPos(I,J,IPos,JPos,XOffset,YOffset:Word; Status,Direction:Byte):Boolean;
{ vraci True, pokud se pozice jednotky IPos,JPos a parametrech pohybu
  Status, Direction rovna I,J
}
begin
  if ((Status = Direction) and (Status >= 4) and (Status <= 64) and
      ((XOffset <> 0) or (YOffset <> 0))) then begin
  { jednotka se pohybuje urcitym smerem }
    case (Status) of
      4 : if ((I = (IPos+1)) and (J = JPos)) then EqualPos:=True else EqualPos:=False;
      8 : if ((I = (IPos+1)) and (J = JPos)) then EqualPos:=True else EqualPos:=False;
      16: if ((I = (IPos+1)) and (J = (JPos+1))) then EqualPos:=True else EqualPos:=False;
      32: if ((I = IPos) and (J = (JPos+1))) then EqualPos:=True else EqualPos:=False;
      64: if ((I = IPos) and (J = (JPos+1))) then EqualPos:=True else EqualPos:=False;
    end;
  end else
    if ((I = IPos) and (J = JPos)) then EqualPos:=True else EqualPos:=False;
end;


{ ***** }
function PomDrawRadarPixel2(K,L,I,J:Word):Boolean;
{ jde o pozici na mape I,J a na radaru K,L. Na teto pozici se ma vykreslit
  pozadi. Funkce zkouma okoli I-1 az I, J-1 az J, nenachazi-li se zde
  nejaka jednotka; pokud ano, vykresli ji na pozici K,L na radaru a
  vraci True; neni-li zadna jednotka(budova) vykreslena, vraci False
}
begin
 PomDrawRadarPixel2:=False;
 if (MapBckTemp^[I,J].Visibilit and Races[MyRace].VisMask > 0) then begin
   if ((I > 0) and (J > 0)) then with (Map^[I-1,J-1]) do begin
   { levy horni roh }
      if ((Second_level <> 0) and (Units[Second_level] <> Nil)) then
      with (Units[Second_level]^) do begin
        if (Visibility and EqualPos(I-1,J-1,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
          PomDrawRadarPixel2:=True; ;
          if ((WarningBlingFlag <> 0) and (Race = MyRace)) then
             SetPixel(K,L,RadarBlinkColor)
          else
             SetPixel(K,L,Races[Race].RaceColor);
        end;
      end else
        if ((First_level <> 0) and (Level_type and 128 <> 0) and
            (Buildings[First_level] <> Nil))
        then with (Buildings[First_level]^) do begin
          if (Visibility and (IPos = (I-1)) and (JPos = (J-1))) then begin
            PomDrawRadarPixel2:=True;
            if ((WarningBlingFlag <> 0) and (Race = MyRace) and
                (BuildingType <> 25)) then
               SetPixel(K,L,RadarBlinkColor)
            else
               SetPixel(K,L,Races[Race].RaceColor);
          end;
        end else
          if ((First_level <> 0) and (Level_type and 128 = 0) and
              (Units[First_level] <> Nil))
          then with (Units[First_level]^) do begin
            if (Visibility and EqualPos(I-1,J-1,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
              PomDrawRadarPixel2:=True;
              if ((WarningBlingFlag <> 0) and (Race = MyRace)) then
                 SetPixel(K,L,RadarBlinkColor)
              else
                 SetPixel(K,L,Races[Race].RaceColor);
            end;
          end;
   end;
   if (I > 0) then with (Map^[I-1,J]) do begin
   { vlevo }
      if ((Second_level <> 0) and (Units[Second_level] <> Nil)) then
      with (Units[Second_level]^) do begin
        if (Visibility and EqualPos(I-1,J,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
          PomDrawRadarPixel2:=True;
          if ((WarningBlingFlag <> 0) and (Race = MyRace)) then
             SetPixel(K,L,RadarBlinkColor)
          else
             SetPixel(K,L,Races[Race].RaceColor);
        end;
      end else
        if ((First_level <> 0) and (Level_type and 128 <> 0) and
            (Buildings[First_level] <> Nil))
        then with (Buildings[First_level]^) do begin
          if (Visibility and (IPos = (I-1)) and (JPos = J)) then begin
            PomDrawRadarPixel2:=True;
            if ((WarningBlingFlag <> 0) and (Race = MyRace) and
                (BuildingType <> 25)) then
               SetPixel(K,L,RadarBlinkColor)
            else
               SetPixel(K,L,Races[Race].RaceColor);
          end;
        end else
          if ((First_level <> 0) and (Level_type and 128 = 0) and
              (Units[First_level] <> Nil))
          then with (Units[First_level]^) do begin
            if (Visibility and EqualPos(I-1,J,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
                PomDrawRadarPixel2:=True;
               if ((WarningBlingFlag <> 0) and (Race = MyRace)) then
                  SetPixel(K,L,RadarBlinkColor)
               else
                  SetPixel(K,L,Races[Race].RaceColor);
            end;
          end;
   end;
   if (J > 0) then with (Map^[I,J-1]) do begin
   { nahore }
      if ((Second_level <> 0) and (Units[Second_level] <> Nil)) then
      with (Units[Second_level]^) do begin
        if (Visibility and EqualPos(I,J-1,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
          PomDrawRadarPixel2:=True;
          if ((WarningBlingFlag <> 0) and (Race = MyRace)) then
             SetPixel(K,L,RadarBlinkColor)
          else
             SetPixel(K,L,Races[Race].RaceColor);
        end;
      end else
        if ((First_level <> 0) and (Level_type and 128 <> 0) and
            (Buildings[First_level] <> Nil))
        then with (Buildings[First_level]^) do begin
          if (Visibility and (IPos = I) and (JPos = (J-1))) then begin
            PomDrawRadarPixel2:=True;
            if ((WarningBlingFlag <> 0) and (Race = MyRace) and
                 (BuildingType <> 25)) then
              SetPixel(K,L,RadarBlinkColor)
            else
              SetPixel(K,L,Races[Race].RaceColor);
          end;
        end else
          if ((First_level <> 0) and (Level_type and 128 = 0) and
              (Units[First_level] <> Nil))
          then with (Units[First_level]^) do begin
            if (Visibility and EqualPos(I,J-1,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
               PomDrawRadarPixel2:=True;
               if ((WarningBlingFlag <> 0) and (Race = MyRace)) then
                  SetPixel(K,L,RadarBlinkColor)
               else
                  SetPixel(K,L,Races[Race].RaceColor);
            end;
          end;
   end;
 end;
end;

{ ***** }
procedure DrawRadarPixel(I,J:Word);
{ na pozici radaru I, J vykresli
  1) letajici jednotku; neni-li, pak
  2) pozemni jednotku; neni-li, pak
  3) pozadi
}
var A,B,K,L:Word;
    Add:Byte;
begin
 if ((I <= IMax) and (J <= JMax)) then begin
  if (BuildRadarMod) then begin
     K:=I+XRadarRealBeg;
     L:=J+YRadarRealBeg;
     case (BuildRadar^[I,J].B) of
       0 : ColorPixel(K,L,Races[0].RaceColor);
       1 : ColorPixel(K,L,Races[1].RaceColor);
       2 : ColorPixel(K,L,Races[2].RaceColor);
       3 : ColorPixel(K,L,Races[3].RaceColor);
       4 : ColorPixel(K,L,Races[4].RaceColor);
       5 : ColorPixel(K,L,Races[5].RaceColor);
     else
       if (BuildRadar^[I,J].P) then ColorPixel(K,L,41)
       else ColorPixel(K,L,0);
     end;
     if (I > 0) then A:=I-1 else A:=I;
     if (J > 0) then B:=J-1 else B:=J;

     if (((A = IBeg) or (I = IBeg) or (A = (IBeg+IScreenSize-1)) or
          (I = (IBeg+IScreenSize-1))) and
         (J >= JBeg) and (B <= (JBeg+JScreenSize)) or
         ((B = JBeg) or (J = JBeg)  or (B = (JBeg+JScreenSize-1)) or
          (J = (JBeg+JScreenSize-1))) and
         (I >= IBeg) and (A <= (IBeg+IScreenSize)))
     then { prusecik s RadarFrame } RdrawRadarFrame:=True;
  end else begin
     if (I > 0) then A:=I-1 else A:=I;
     if (J > 0) then B:=J-1 else B:=J;

     if (((A = IBeg) or (I = IBeg) or (A = (IBeg+IScreenSize-1)) or
          (I = (IBeg+IScreenSize-1))) and
         (J >= JBeg) and (B <= (JBeg+JScreenSize)) or
         {x}
         ((B = JBeg) or (J = JBeg)  or (B = (JBeg+JScreenSize-1)) or
          (J = (JBeg+JScreenSize-1))) and
         (I >= IBeg) and (A <= (IBeg+IScreenSize)))
     then { prusecik s RadarFrame } RdrawRadarFrame:=True;

     K:=I+XRadarRealBeg;
     L:=J+YRadarRealBeg;
     with (Map^[I,J]) do with (MapBck^[I,J]) do
     with (MapBckTemp^[I,J]) do begin
        if ((Visibilit and Races[MyRace].VisMask  = 0) and (Fog_of_war)) then Add:=3 else Add:=0;
        if (not PomDrawRadarPixel2(K,L,I,J)) then begin
            if ((Second_level <> 0) and Units[Second_level]^.Visibility and
                (Visibilit and Races[MyRace].VisMask > 0)) then
            with (Units[Second_level]^) do begin
                  if ((WarningBlingFlag <> 0) and (Race = MyRace)) then begin
                    ColorPixel(K,L,RadarBlinkColor);
                    if (EqualPos(I,J,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
                      if ((MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask > 0) and
                          (I < IMax)) then ColorPixel(K+1,L,RadarBlinkColor);
                      if ((MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                          (J < JMax)) then ColorPixel(K,L+1,RadarBlinkColor);
                      if ((MapBckTemp^[I+1,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                          (I < IMax) and (J < JMax)) then ColorPixel(K+1,L+1,RadarBlinkColor);
                    end;{}
                  end else begin
                    ColorPixel(K,L,Races[Race].RaceColor);
                    if (EqualPos(I,J,IPos,JPos,XOffset,YOffset,Status,Direction)) then
                    with (Races[Race]) do begin
                      if ((MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask > 0) and
                          (I < IMax)) then ColorPixel(K+1,L,RaceColor);
                      if ((MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                          (J < JMax)) then ColorPixel(K,L+1,RaceColor);
                      if ((MapBckTemp^[I+1,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                          (I < IMax) and (J < JMax)) then ColorPixel(K+1,L+1,RaceColor);
                    end;{}
                  end;
            end else
                 if ((First_level <> 0) and (Level_type and 128 = 0) and
                      Units[First_level]^.Visibility and
                      (Visibilit and Races[MyRace].VisMask > 0)) then
                 with (Units[First_level]^) do begin
                   if ((WarningBlingFlag <> 0) and (Race = MyRace)) then begin
                     ColorPixel(K,L,RadarBlinkColor);
                     if (EqualPos(I,J,IPos,JPos,XOffset,YOffset,Status,Direction)) then begin
                        if ((MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask > 0) and
                            (I < IMax)) then ColorPixel(K+1,L,RadarBlinkColor);
                        if ((MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                            (J < JMax)) then ColorPixel(K,L+1,RadarBlinkColor);
                        if ((MapBckTemp^[I+1,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                            (I < IMax) and (J < JMax)) then ColorPixel(K+1,L+1,RadarBlinkColor);
                     end;{}
                   end else begin
                     ColorPixel(K,L,Races[Race].RaceColor);
                     if (EqualPos(I,J,IPos,JPos,XOffset,YOffset,Status,Direction)) then
                     with (Races[Race]) do begin
                       if ((MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask > 0) and
                           (I < IMax)) then ColorPixel(K+1,L,RaceColor);
                       if ((MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                           (J < JMax)) then ColorPixel(K,L+1,RaceColor);
                       if ((MapBckTemp^[I+1,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                           (I < IMax) and (J < JMax)) then ColorPixel(K+1,L+1,RaceColor);
                     end;{}
                   end;
                 end else
                   if ((First_level <> 0) and (Level_type and 128 = 128) and
                        (Visibilit and Races[MyRace].VisMask > 0) and
                        Buildings[First_level]^.Visibility and
                        (Buildings[First_level]^.BuildingType <> 25) and
                        (Buildings[First_level]^.IPos = I) and
                        (Buildings[First_level]^.JPos = J))
                   then with (Buildings[First_level]^) do begin
                        if ((WarningBlingFlag <> 0) and (Race = MyRace)) then begin
                          ColorPixel(K,L,RadarBlinkColor);
                          if ((I = IPos) and (J = JPos)) then begin
                            if ((MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask > 0) and
                                (I < IMax)) then ColorPixel(K+1,L,RadarBlinkColor);
                            if ((MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                                (J < JMax)) then ColorPixel(K,L+1,RadarBlinkColor);
                            if ((MapBckTemp^[I+1,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                                (I < IMax) and (J < JMax)) then ColorPixel(K+1,L+1,RadarBlinkColor);
                          end;
                        end else begin
                          ColorPixel(K,L,Races[Race].RaceColor);
                          if ((I = IPos) and (J = JPos)) then begin
                             if ((MapBckTemp^[I+1,J].Visibilit and Races[MyRace].VisMask > 0) and
                                 (I < IMax)) then ColorPixel(K+1,L,Races[Race].RaceColor);
                             if ((MapBckTemp^[I,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                                 (J < JMax)) then ColorPixel(K,L+1,Races[Race].RaceColor);
                             if ((MapBckTemp^[I+1,J+1].Visibilit and Races[MyRace].VisMask > 0) and
                                 (I < IMax) and (J < JMax)) then ColorPixel(K+1,L+1,Races[Race].RaceColor);
                          end;
                        end;
                   end else
                      if ((Unknown_terrain) and (MapBckTemp^[I,J].Temp and 2 = 0))
                      then ColorPixel(K,L,78) else
                        if BelowEqual(BckType,Way) then ColorPixel(K,L,WayColor+Add)
                        else
                         if BelowEqual(BckType,Grass) then ColorPixel(K,L,GrassColor+Add)
                         else
                           if BelowEqual(BckType,Field) then ColorPixel(K,L,FieldColor+Add)
                           else
                             if BelowEqual(BckType,Resrc) then ColorPixel(K,L,ResrcColor+Add)
                             else
                               if BelowEqual(BckType,Desert) then ColorPixel(K,L,DesertColor+Add)
                               else
                                 if BelowEqual(BckType,Hill) then ColorPixel(K,L,HillColor+Add)
                                 else
                                   if BelowEqual(BckType,Wather) then ColorPixel(K,L,WatherColor+Add)
                                   else
                                     if BelowEqual(BckType,Wood) then ColorPixel(K,L,WoodColor+Add)
                                     else
                                       if BelowEqual(BckType,Airport) then ColorPixel(K,L,AirfieldColor+Add);
            end;
        end;
  end;
 end;
end;

{ ***** }
procedure RedrawRadarFrame(IPom,JPom:Word);
{ provede se prekresleni ramecku na novou pozici dle vysledku rolovani
}
var K,L:Word;
begin
   { odstran horni vodorovnou caru }
   L:=JPom;
   for K:=IPom to IPom+IScreenSize-1 do DrawRadarPixel(K, L);
   { odstran spodni vodorovnou caru }
   L:=JPom+JScreenSize-1;
   for K:=IPom to IPom+IScreenSize-1 do DrawRadarPixel(K, L);
   { odstran levou svislou caru }
   K:=IPom;
   for L:=JPom to JPom+JScreenSize-1 do DrawRadarPixel(K, L);
   { odstran pravou svislou caru }
   K:=IPom+IScreenSize-1;
   for L:=JPom to JPom+JScreenSize-1 do DrawRadarPixel(K, L);
   { novy ramecek }
   IPom:=XRadarRealBeg+IBeg; JPom:=YRadarRealBeg+JBeg;
   Frame2(IPom,JPom,IPom+IScreenSize-1,JPom+JScreenSize-1,65);
end;

{ ***** }
procedure ClearRadarFrame(IPom,JPom:Word);
{ provede se smazani
}
var K,L:Word;
begin
    { odstran horni vodorovnou caru }
    L:=JPom;
    for K:=IPom to IPom+IScreenSize-1 do DrawRadarPixel(K, L);
    { odstran spodni vodorovnou caru }
    L:=JPom+JScreenSize-1;
    for K:=IPom to IPom+IScreenSize-1 do DrawRadarPixel(K, L);
    { odstran levou svislou caru }
    K:=IPom;
    for L:=JPom to JPom+JScreenSize-1 do DrawRadarPixel(K, L);
    { odstran pravou svislou caru }
    K:=IPom+IScreenSize-1;
    for L:=JPom to JPom+JScreenSize-1 do DrawRadarPixel(K, L);
end;

{ ***** }
procedure SetPixel(X,Y : Word; Color:Byte);
{
}
begin
   ColorPixel(X,Y,Color);
end;

{ ***** }
function GetPixelColor(X,Y : Word):Byte;
{
}
begin
   GetPixelColor:=GetPixel(X,Y);
end;

{ ***** }
procedure SetFrame(A,B,C,D:Word; Color:Byte);
{
}
begin
   Frame2(A,B,C,D,Color);
end;

{ ****** }
procedure RadarInit;
{ vykresli ramecek radaru a jeho inicializacni obsah
}
var I, J, X, Y : Word;
    Color:Byte;
begin
    XRadarRealBeg:=(XRadarEnd-XRadarBeg-IMax) div 2 + XRadarBeg;
    YRadarRealBeg:=(YRadarEnd-YRadarBeg-JMax) div 2 + YRadarBeg;
    XRadarRealEnd:=XRadarRealBeg + IMax;
    YRadarRealEnd:=YRadarRealBeg + JMax;

    X:=XRadarRealBeg; Y:=YRadarRealBeg;
    for J:=0 to JMax{} do begin
      for I:=0 to IMax{} do with (Map^[I,J]) do with (MapBck^[I,J]) do begin
        DrawRadarPixel(I,J);
      end;
      X:=XRadarRealBeg;
      Inc(Y);
    end;

    for J:=0 to JMax+1 do SetPixel(IMax+1+XRadarRealBeg,J+YRadarRealBeg,GrassColor);
    for I:=0 to IMax+1 do SetPixel(I+XRadarRealBeg,JMax+YRadarRealBeg+1,GrassColor);

    Frame2(XRadarRealBeg+IBeg,YRadarRealBeg+JBeg,XRadarRealBeg+IBeg+IScreenSize-1,
           YRadarRealBeg+JBeg+JScreenSize-1,67);
    Frame2(XRadarRealBeg-1,YRadarRealBeg-1,XRadarRealEnd+1,YRadarRealEnd+1,73);{}
end;

{ ****** }
procedure DrawRadar;
{ vykresli ramecek radaru a jeho obsah
}
var I, J : Word;
    Color:Byte;
    IPom, JPom:Word;
begin
    for J:=0 to JMax{} do begin
      for I:=0 to IMax{} do with (Map^[I,J]) do with (MapBck^[I,J]) do begin
        DrawRadarPixel(I,J);
      end;
    end;

    for J:=0 to JMax+1 do SetPixel(IMax+1+XRadarRealBeg,J+YRadarRealBeg,GrassColor);
    for I:=0 to IMax+1 do SetPixel(I+XRadarRealBeg,JMax+YRadarRealBeg+1,GrassColor);

    IPom:=XRadarRealBeg+IBeg; JPom:=YRadarRealBeg+JBeg;
    Frame2(IPom,JPom,IPom+IScreenSize-1,JPom+JScreenSize-1,65);
end;

{ ***** }
procedure Select_group(Group:Byte);
{ u vsech vozidel skupiny Group (budovy) vykresli "selectovaci" ramecek
  a nastavi tez ActiveGroup
}
var I: Integer;
    DrawButton:Boolean;
begin
  ActiveGroup:=Group; DrawButton:=False;
  with (Groups[Group]) do
    if ((Building <> Nil) and (Building^.Activity)) then begin
       Building^.RequestDraw:=True;
       if (Building^.Race = MyRace) then begin
         DrawButton:=True;
         PlayBuildingSound(Building^.BuildingType,Building^.IPos,Building^.JPos);
       end;
    end else
     for I:=0 to MaxGroupUnits-1 do begin
       if (Un[I] <> Nil) then begin
          if (Un[I]^.Activity) then Un[I]^.RequestDraw:=True;{}
          if (Un[I]^.Race = MyRace) then DrawButton:=True;
       end;
     end;
   if (DrawButton) then begin
     CursorOff;
     ButtonText(SellButton,15,'$');
     SetActive(SellButton); Release(SellButton);
     CursorOn;
   end else if (Active(SellButton)) then begin
     CursorOff;
     ButtonText(SellButton,15,'');
     Release(SellButton); SetPasive(SellButton,256);
     CursorOn;
   end;
end;

{ ***** }
procedure Select_unit(_unit:PUnit);
{ u jednotky _unit vykresli "selectovaci" ramecek
}
var I: Integer;
begin
   if (_unit^.Activity) then begin
      _unit^.RequestDraw:=True;
   end;
   if (_unit^.Race = MyRace) then begin
     CursorOff;
     ButtonText(SellButton,15,'$');
     SetActive(SellButton); Release(SellButton);
     CursorOn;
   end else if (Active(SellButton)) then begin
     CursorOff;
     ButtonText(SellButton,15,'');
     Release(SellButton); SetPasive(SellButton,256);
     CursorOn;
   end;
end;

{ ***** }
procedure Deselect_group(Group:Byte);
{ u vsech vozidel skupiny Group smaze "selectovaci" ramecek a ActiveGroup
  nastavi na 255;
}
var I: Integer;
begin
  ActiveGroup:=255;
   with (Groups[Group]) do
     if (Building <> Nil) then begin
        Building^.RequestDraw:=True; {Redraw_building(Building,True){}
        StopBuildingSound;
     end else
       for I:=0 to MaxGroupUnits-1 do
         if ((Un[I] <> Nil) and (Un[I]^.Activity))
         then Un[I]^.RequestDraw:=True;{Redraw_unit(Un[I],True);{}
  if (Active(SellButton)) then begin
     CursorOff;
     ButtonText(SellButton,15,'');
     Release(SellButton); SetPasive(SellButton,256);
     CursorOn;
  end;
end;

{ ***** }
procedure Deselect_unit(_unit:PUnit);
{ u jednotky _unit smaze "selectovaci" ramecek
}
var I: Integer;
begin
   if (_unit^.Activity) then _unit^.RequestDraw:=True;
end;

{ ***** }
procedure Draw_damage(X,Y : Word; _unit:PUnit);
{ vykresli jednotce aktualni obdelnice s poskozenim na pozici X, Y
  Small = True pro jeden z 9-ti mensich obrazku
          False pro 1. obrazek
}
var PomDamage, PomDamage2 : Double;
    Color : Byte;
    Pom:Word;
    S:String;
begin
   Color:=32;
   PomDamage:=Unit_types[_unit^.UnitType,Races[_unit^.Race].Ally].DefenceStrength+_unit^.DamageBonus;
   PomDamage2:=_unit^.Damage;
   PomDamage:=Round(PomDamage2 / (PomDamage / 100)); { procenta }
   if ((PomDamage <= 50) and (PomDamage > 35)) then begin  { kriticke poskozeni }
      Color:=163; { zluta }
   end else
     if (PomDamage <= 35) then begin  { kriticke poskozeni }
        Color:=112; { red }
     end;

   PomDamage:=PomDamage / SmallProcent; { delka sloupku }
   Pom:=Round(PomDamage); if ((Pom mod 2 = 0) and (Pom <> 0)) then Dec(Pom);
   {Frame(X,Y,X+SmallXBarSize,Y+SmallYBarSize,FrameColor);{}
   Inc(X); Inc(Y);
   Rectangle2(X{+Pom},Y,X+SmallXBarSize-2,Y+SmallYBarSize-2,0);
   Rectangle2(X,Y,X+Pom,Y+SmallYBarSize-2,Color);
end;

{ ***** }
procedure Draw_building_damage(X,Y : Word; Building:PBuilding);
{ vykresli jednotce aktualni obdelnice s poskozenim na pozici X, Y
}
var PomDamage, PomDamage2 : Double;
    Color : Byte;
    Pom : Word;
begin
   Color:=32;
   PomDamage:=Building_types[Building^.BuildingType].DefenceStrength;
   PomDamage2:=Building^.Damage;
   PomDamage:=PomDamage2 / (PomDamage / 100); { procenta }
   if (PomDamage <= 35) then begin  { kriticke poskozeni }
      Color:=16;
   end;
   PomDamage:=PomDamage / SmallProcent; { delka sloupku }
   Pom:=Round(PomDamage); if ((Pom mod 2 = 0) and (Pom <> 0)) then Dec(Pom);
   Inc(X); Inc(Y);
   Rectangle2(X{+Pom},Y,X+SmallXBarSize-2,Y+SmallYBarSize-2,0);
   Rectangle2(X,Y,X+Pom,Y+SmallYBarSize-2,Color);
end;

{ ***** }
procedure Draw_morale(X,Y : Word; _unit:PUnit);
{ vykresli jednotce aktualni obdelnice s moralkou na pozici X, Y
  Small = True pro jeden z 9-ti mensich obrazku
          False pro 1. obrazek
}
var PomDamage, PomDamage2 : Double;
    Color : Byte;
    Pom : Integer;
begin
  if (_unit^.UnitType = 2) then begin
  { u recyklatoru neni moralka, ale procentuelni naplneni materialem }
     Color:=66;
     PomDamage:=_unit^.Cargo; { procenta }

     PomDamage:=PomDamage / SmallProcent; { delka sloupku }
     Pom:=Round(PomDamage); if ((Pom mod 2 = 0) and (Pom <> 0)) then Dec(Pom);
     {Frame(X,Y,X+SmallXBarSize,Y+SmallYBarSize,FrameColor);{}
     Inc(X); Inc(Y);
     Rectangle(X{+Pom},Y,X+SmallXBarSize-2,Y+SmallYBarSize-2,0);
     Rectangle(X,Y,X+Pom,Y+SmallYBarSize-2,Color);
  end else begin { jina jednotka nez recyklator }
    if ((Races[_unit^.Race].RaceType <> 3) and
        (Races[_unit^.Race].RaceType <> 6)) then begin
    { LIDE - MORALKA}
       PomDamage:=MaxMorale;
       PomDamage2:=_unit^.Morale;
       PomDamage:=PomDamage2 / (PomDamage / 100); { procenta }
       if (PomDamage > 100) then PomDamage:=100;
       {}
       if (PomDamage <= 13) then Color:=3
       else
         if (PomDamage <= 26) then Color:=5
         else
           if (PomDamage <= 39) then Color:=50
           else
             if (PomDamage <= 50) then Color:=48
             else
               if (PomDamage <= 65) then Color:=100
               else
                 if (PomDamage <= 80) then Color:=98
                 else Color:=96;
       {}
       PomDamage:=PomDamage / SmallProcent; { delka sloupku }
       Pom:=Round(PomDamage); if ((Pom mod 2 = 0) and (Pom <> 0)) then Dec(Pom);
       {Frame(X,Y,X+SmallXBarSize,Y+SmallYBarSize,FrameColor);{}
       Inc(X); Inc(Y);
       Rectangle(X{+Pom},Y,X+SmallXBarSize-2,Y+SmallYBarSize-2,0);
       Rectangle(X,Y,X+Pom,Y+SmallYBarSize-2,Color);
    end else begin { roboti - opotrebeni }
       PomDamage:=MinWearOut;
       PomDamage2:=_unit^.WearOut;
       PomDamage:=PomDamage2 / (PomDamage / 100); { procenta }
       if (PomDamage > 100) then PomDamage:=100;
       if (PomDamage <= 20) then Color:=186
       else if (PomDamage <= 40) then Color:=184
         else if (PomDamage <= 60) then Color:=182
           else if (PomDamage <= 80) then Color:=180
              else Color:=178;
       PomDamage:=PomDamage / SmallProcent; { delka sloupku }
       Pom:=Round(PomDamage); if ((Pom mod 2 = 0) and (Pom <> 0)) then Dec(Pom);
       {Frame(X,Y,X+SmallXBarSize,Y+SmallYBarSize,FrameColor);{}
       Inc(X); Inc(Y);
       Rectangle(X{+Pom},Y,X+SmallXBarSize-2,Y+SmallYBarSize-2,0);
       Rectangle(X,Y,X+Pom,Y+SmallYBarSize-2,Color);
    end;
  end; { jina jednotka nez recyklator }
end;

{ ***** }
procedure Draw_experience(X,Y : Word; _unit:PUnit);
{ vykresli jednotce aktualni obdelnice s poskozenim na pozici X, Y
  pozn.  pro roboty  se nic nevykresli
}
var Pom, I : Word;
begin
 if ((Races[_unit^.Race].RaceType <> 3) and
     (Races[_unit^.Race].RaceType <> 6)) then begin
 { pro roboty  se nic nevykresli }
   Inc(X,XBeginAdd);
   with (ExperienceLevel[0]) do
      SpeedPutImage2(X,Y+1,Segment,Offsets);{}
   Pom:= _unit^.ExperienceLevel;
   if (Pom > 0) then begin
     if (Pom <= Serie1) then begin
     { prymky }
        Inc(X,XSerie1Begin); Inc(Y,YSerie1Begin);
        for I:=1 to Pom do with (ExperienceLevel[1]) do begin
          SpeedPutImage2(X,Y,Segment,Offsets);
                  Inc(X,XSerie1+XSerie1Space);
        end;
     end else begin
       if (Pom <= Serie2) then begin
       { prymky }
         Inc(X,XSerie2Begin); Inc(Y,YSerie2Begin);
         for I:=Serie1+1 to Pom do with (ExperienceLevel[2]) do begin
           SpeedPutImage2(X,Y,Segment,Offsets);
           Inc(X,XSerie2+XSerie2Space);
         end;
       end else begin
         if (Pom <= Serie3) then begin
         { prymky }
           Inc(X,XSerie3Begin); Inc(Y,YSerie3Begin);
           for I:=Serie2+1 to Pom do with (ExperienceLevel[3]) do begin
             SpeedPutImage2(X,Y,Segment,Offsets);
             Inc(X,XSerie3+XSerie3Space);
           end;
         end;
       end;
     end;
   end; { if (Pom > 0) then begin }
 end;
end;

{ ***** }
procedure Update_unit_char(_unit:PUnit; Damg,Moral,Exper:Boolean);
{ prekresli charakteristiky jednotky _unit dle ostatnich promennych:
  Damg = True .. prekresli se poskozeni
  Moral = True .. prekresli se moralka (opotrebeni)
  Exper = True .. prekresli se zkusenost
}
var K, I, XX, YY : Word;
    Mouse:Boolean;
begin
   I:=_unit^.GroupOrder;
   if ((I >= MaxGroupUnits) or (_unit^.Group <> ActiveGroup)) then begin
   { chyba - nic nevykresluj !! }
   end else begin
      GroupsBck[I]._unit:=_unit;
      with (GroupsBck[I]) do begin
          Active:=True; Building:=NIL; ElementType:=_unit^.UnitType;
          Typ:=0;
      end;
      with (_unit^) do with (GroupsBck[I]) do begin
         { zbyle jednotky }
           XX:=X; YY:=Y;
           Mouse:=TestMouse(XX,YY,XX+GroupsBckXSize,YY+GroupsBckYSize);
           if (Mouse) then CursorOff;
           if (Damg) then Draw_damage(X1,Y1,_unit);
           if (Moral) then Draw_morale(X2,Y2,_unit);
           if (Exper) then Draw_experience(X3,Y3,_unit);
           if (Mouse) then CursorOn;
     end; { if (I = 1) then .. else }
   end;
end;

{ ***** }
procedure Update_building_char(Build:PBuilding);
{ prekresli charakteristiky budovy Build
}
var K, I, X, Y : Word;
    Mouse:Boolean;
begin
   with (Build^) do with (GroupsBck[0]) do begin
      { 1. jednotka }
      Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
      if (Mouse) then CursorOff;
      Draw_building_damage(X1,Y1,Build);
      if (Mouse) then CursorOn;
  end;
end;

{ ***** }
procedure Draw_production_proceed(X,Y:Word; Production_percentage:Byte);
{ vykresli hotove procento vyroby
}
var PomProduction, PomProduction2 : Double;
    Pom, Color : Byte;
begin
   Color:=102;
   if (Production_percentage > 100) then Production_percentage:=100;
   PomProduction:=Production_percentage;
   if (PomProduction <= 33) then Color:=16;
   PomProduction:=PomProduction / SmallProcent; { delka sloupku }
   Pom:=Round(PomProduction);
   if ((Pom = 0) and (Production_percentage > 0)) then Pom:=1;
   Inc(X); Inc(Y);
   if (Pom = 0) then
      Draw_price_bck_rectangle(X,Y,X+SmallXBarSize,Y+SmallYBarSize,True,False);
   Rectangle2(X+Pom,Y,X+SmallXBarSize-2,Y+SmallYBarSize-2,0);
   if (Pom <> 0) then Rectangle2(X,Y,X+Pom,Y+SmallYBarSize-2,Color);
   if (Pom = 0) then
     Draw_price_bck_rectangle(X,Y,X+SmallXBarSize,Y+SmallYBarSize,False,True)
   else Draw_price_bck_rectangle(X,Y,X+SmallXBarSize,Y+SmallYBarSize,False,False);
end;

{ ***** }
procedure Draw_building_production(Building : PBuilding);
{ vykresli produkci budovy Building
}
label Konec;
var I,J:Word;
    Mouse:Boolean;
    Ret:String;
begin
 I:=1;
 with (Building^) do if (Race = MyRace) then{}
 with (Building_types[BuildingType]) do begin
  if (Repair) then GoTo Konec;
  if (Building_types[BuildingType].ProductionType = 0) then begin
  { jednotky }
    for J:=0 to MaxIndex do
    if (UnitProductionPossible(MyRace,Production[J])) then
    with (GroupsBck[J+1]) do begin
       Active:=True; _unit:=Nil; Building:=Nil;
       Typ:=0; ElementType:=Production[J]; ProductType:=J;
       Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
       if (Mouse) then CursorOff;
       with (Unit_pictures[Unit_types[Production[J],Races[Race].Ally].PictureIndex]) do begin
          with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
          SpecSpeedPutImage3(X+1,Y+1,S1,O1,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);
       end;
       Str(Production_count,Ret);
       if (((J+1) = Production_type) and (Production_count > 0)) then
         OutText(X+1,Y+1,Ret);
       if ((J+1) = Production_type) then Draw_production_proceed(X1,Y1,Round(Production_percentage))
       else Draw_production_proceed(X1,Y1,0);
       if (Mouse) then CursorOn;
       Inc(I);
    end;
  end else begin { budovy }
   if (Building_types[BuildingType].ProductionType = 1) then begin
     for J:=0 to MaxIndex do
     if (BuildingProductionPossible(MyRace,Production[J])) then
     with (GroupsBck[J+1]) do begin
       Active:=True; _unit:=Nil; Building:=Nil; Typ:=1;
       if ((BuildingType = 1) and (J = 0) and ((Races[Race].RaceType = 3) or
           (Races[Race].RaceType = 6))) then ElementType:=15
       else ElementType:=Production[J];
       ProductType:=J;
       Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
       if (Mouse) then CursorOff;
       with (Building_types[Production[J]]) do begin
          with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
          SpecSpeedPutImage3(X+1,Y+1,SmallPictS,SmallPictO,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);{}
       end;
       if ((J+1) = Production_type) then Draw_production_proceed(X1,Y1,Round(Production_percentage))
       else Draw_production_proceed(X1,Y1,0);
       if (Mouse) then CursorOn;
       Inc(I);
     end;
   end else if (Building_types[BuildingType].ProductionType = 2) then begin
      if (Production_type = 0) then with (GroupsBck[1]) do begin
      { produkce plastu  - START TLACITKO }
          Active:=True; _unit:=Nil; Building:=Nil; Typ:=2; ElementType:=0;
          ProductType:=0;
          Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
          if (Mouse) then CursorOff;
          with (Building_types[BuildingType]) do
             SpeedPutImage2(X+1,Y+1,PlastyProductSegment, PlastyProductOffset);{}
          if (Mouse) then CursorOn;
      end else with (GroupsBck[1]) do begin
          if (Active) then begin { vymaz slot }
            Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
            if (Mouse) then CursorOff;
            SpeedPutImage(X,Y,BckSegment,Offsets);
            if (Mouse) then CursorOn;
          end;
      end;
      if (Production_type <> 0) then with (GroupsBck[3]) do begin
      { produkce plastu - STOP TLACITKO }
          Active:=True; _unit:=Nil; Building:=Nil; Typ:=3; ElementType:=0;
          ProductType:=0;
          Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
          if (Mouse) then CursorOff;
          with (Building_types[BuildingType]) do
             SpeedPutImage2(X+1,Y+1,PlastyProductSegment2, PlastyProductOffset2);{}
          if (Mouse) then CursorOn;
      end else with (GroupsBck[3]) do begin
          if (Active) then begin { vymaz slot }
            Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
            if (Mouse) then CursorOff;
            SpeedPutImage(X,Y,BckSegment,Offsets);
            if (Mouse) then CursorOn;
          end;
      end;
   end;
  end; { end else (budovy) }
 end; { with }
Konec:
end;

{ ***** }
procedure Update_building_production(Building : PBuilding; Ind:Byte);
{ u probihajici produkce budovy Building vykresli prirustek na indexu Index
}
var Mouse:Boolean;
begin
  if ((Building^.Race = MyRace) or Debug) then begin
    with (Building^) do  with (Building_types[BuildingType]) do
    with (GroupsBck[Ind]) do begin
       Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
       if (Mouse) then CursorOff;
       Draw_production_proceed(X1,Y1,Round(Production_percentage));
       if (Mouse) then CursorOn;
    end;
  end;
end;

{ ***** }
procedure Click_on_group(Group : Byte);
{ doslo ke kliknuti na skupinu Group; procedura zobrazi charakteristiky
  jejich jednotek (nebo budovy)
}
var K,Ind : Word;
    Mouse:Boolean;
    Ret:String;
begin
  with (Groups[Group]) do begin
    if (Building <> Nil) then with (GroupsBck[0]) do begin
       Building:=Groups[Group].Building;
       Active:=True; _unit:=NIL; ElementType:=Building^.BuildingType; Typ:=1;
       with (Building^) do begin
          { budova }
          Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
          if (Mouse) then CursorOff;
          with (Building_types[BuildingType]) do begin
            with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
            SpecSpeedPutImage3(X+1,Y+1,SmallPictS,SmallPictO,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);{}
          end;
          if ((WayPointUk <> 255) and (WayPointMax <> 255) and
              (Race = MyRace))
          then OutText(X+2,Y+2,'W');
          Draw_building_damage(X1,Y1,Building);
          if (Mouse) then CursorOn;
          if ((Building^.Race = MyRace) and
              (Building_types[Building^.BuildingType].ProductionType < 3)
              and (BuildPhase > 3))
          then Draw_building_production(Building);
       end;
    end else begin
       for K:=0 to MaxGroupUnits-1 do begin
          if (Un[K] <> Nil) then with (Un[K]^) do begin
            Ind:=GroupOrder;
            with (GroupsBck[Ind]) do begin
               Active:=True; Building:=NIL; ElementType:=Un[K]^.UnitType;
               Typ:=0; _unit:=Un[K];
               Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
               if (Mouse) then CursorOff;
               with (Unit_pictures[Unit_types[UnitType,Races[Race].Ally].PictureIndex]) do begin
                   with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
                   SpecSpeedPutImage3(X+1,Y+1,S1,O1,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);
                   if ((WayPointUk <> 255) and (WayPointMax <> 255) and
                       (Race = MyRace) and (MoveStatus < 8))
                   then OutText(X+2,Y+2,'W');
                   if ((GroupMoveBlock > 0) and
                       (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
                       (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0))
                   then begin
                     if (GroupMoveBlock > (SpecAirUnitBlock-SpecAirUnitBlock div 3)) then
                       SpeedPutImage2(X+1,Y+1,AirNotReady0Seg,AirNotReady0Ofs)
                     else
                       if (GroupMoveBlock > (SpecAirUnitBlock-2*SpecAirUnitBlock div 3)) then
                         SpeedPutImage2(X+1,Y+1,AirNotReady1Seg,AirNotReady1Ofs)
                       else
                         if ((GroupMoveBlock <= (SpecAirUnitBlock-2*SpecAirUnitBlock div 3)) and
                             (GroupMoveBlock > SpecAirUnitBlock shr 3)) then
                           SpeedPutImage2(X+1,Y+1,AirNotReady2Seg,AirNotReady2Ofs)
                         else
                           SpeedPutImage2(X+1,Y+1,AirNotReady3Seg,AirNotReady3Ofs)
                   end;

                   {*** POMOCNE ***}
                   if (Debug) then begin
                      Str(Index,Ret);
                      OutTextColor(X+6,Y+12,64,Ret);
                      if (TaskGroup < InvalidTaskGroupNumber) then begin
                        Str(TaskGroup,Ret);
                        OutTextColor(X+6,Y+22,32,Ret);
                      end;
                   end;
                   {*** POMOCNE KONEC ***}

               end;
               Draw_damage(X1,Y1,Un[K]);
               Draw_morale(X2,Y2,Un[K]);
               Draw_experience(X3,Y3,Un[K]);
               if (Mouse) then CursorOn;
            end;
          end; { if + with Un[K]^ }
      end; { for }
    end; { if (Building <> 0) then .. else .. }
  end;
end;

{ ***** }
procedure Click_on_unit(_unit:PUnit);
{ doslo ke kliknuti na jednotku _unit; procedura zobrazi jeji charakteristiky
  pozn. jednotka musi byt v aktivni skupine !!!
}
var I : Word;
    Mouse:Boolean;
    Ret:String;
begin
   I:=_unit^.GroupOrder;
   if (I >= MaxGroupUnits) then begin
      { chyba, zkus recover!! }
      OutBigMsg(255,'CHYBA V UMeSTdNe JEDNOTKY VE SKUPINd - RECOVER');
      _unit^.GroupOrder:=0;
   end;
   GroupsBck[I]._unit:=_unit;
   with (_unit^) do with (GroupsBck[I]) do begin
      Active:=True; Building:=NIL; ElementType:=_unit^.UnitType; Typ:=0;

      Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
      if (Mouse) then CursorOff;
      with (Unit_pictures[Unit_types[UnitType,Races[Race].Ally].PictureIndex]) do begin
         with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
         SpecSpeedPutImage3(X+1,Y+1,S1,O1,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);
         if ((WayPointUk <> 255) and (WayPointMax <> 255) and
             (Race = MyRace) and (MoveStatus < 8))
         then OutText(X+2,Y+2,'W');
         if ((GroupMoveBlock > 0) and
             (Unit_types[UnitType,Races[Race].Ally].UnitLevel = 3) and
             (Unit_types[UnitType,Races[Race].Ally].SpecAirLevel = 0))
         then begin
           if (GroupMoveBlock > (SpecAirUnitBlock-SpecAirUnitBlock div 3)) then
             SpeedPutImage2(X+1,Y+1,AirNotReady0Seg,AirNotReady0Ofs)
           else
             if (GroupMoveBlock > (SpecAirUnitBlock-2*SpecAirUnitBlock div 3)) then
               SpeedPutImage2(X+1,Y+1,AirNotReady1Seg,AirNotReady1Ofs)
             else
               if ((GroupMoveBlock <= (SpecAirUnitBlock-2*SpecAirUnitBlock div 3)) and
                   (GroupMoveBlock > SpecAirUnitBlock shr 3)) then
                 SpeedPutImage2(X+1,Y+1,AirNotReady2Seg,AirNotReady2Ofs)
               else
                 SpeedPutImage2(X+1,Y+1,AirNotReady3Seg,AirNotReady3Ofs)
         end;

         {*** POMOCNE ***}
         if (Debug) then begin
           Str(Index,Ret);
           OutTextColor(X+6,Y+12,64,Ret);
           if (TaskGroup < InvalidTaskGroupNumber) then begin
             Str(TaskGroup,Ret);
             OutTextColor(X+6,Y+22,32,Ret);
           end;
         end;
         {*** POMOCNE KONEC ***}

      end;
      Draw_damage(X1,Y1,_unit);
      Draw_morale(X2,Y2,_unit);
      Draw_experience(X3,Y3,_unit);
      if (Mouse) then CursorOn;
   end; { with }
end;

{ ***** }
procedure Click_on_enemy_unit(_unit2:PUnit);
{ doslo ke kliknuti na jednotku _unit; procedura zobrazi
  jenom NEKTERE charakteristiky (nepratelska jednotka)
  pozn. jednotka musi byt v aktivni skupine !!!
}
var I : Word;
    Mouse:Boolean;
    Ret:String;
begin
   I:=_unit2^.GroupOrder;
   if (I >= MaxGroupUnits) then begin
      { chyba, zkus recover!! }
      OutBigMsg(255,'CHYBA V UMeSTdNe JEDNOTKY VE SKUPINd - RECOVER');
      _unit2^.GroupOrder:=0;
   end;
   with (_unit2^) do with (GroupsBck[I]) do  begin
     Active:=True; Building:=NIL; ElementType:=_unit2^.UnitType;
     Typ:=0; _unit:=_unit2;

     Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
     if (Mouse) then CursorOff;
     with (Unit_pictures[Unit_types[UnitType,Races[Race].Ally].PictureIndex]) do begin
       with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
       SpecSpeedPutImage3(X+1,Y+1,S1,O1,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);


       {*** POMOCNE ***}
       if (Debug) then begin
         Str(Index,Ret);
         OutTextColor(X+6,Y+12,64,Ret);
         if (TaskGroup < InvalidTaskGroupNumber) then begin
           Str(TaskGroup,Ret);
           OutTextColor(X+6,Y+22,32,Ret);
         end;
       end;
       {*** POMOCNE KONEC ***}

     end;
     Draw_damage(X1,Y1,_unit);
     if (Mouse) then CursorOn;
   end; { with }
end;

{ ***** }
procedure Click_on_storage_unit(_unit2:PUnit);
{ doslo ke kliknuti na jednotku _unit, ktera ma nalozeny jine jednotky;
  procedura zobrazi obrazky obsazenych jednotek
}
var K, I : Word;
    Mouse:Boolean;
begin
  I:=1;
  with (_unit2^) do for K:=0 to (MaxGroupUnits-2) do begin
    if (UnitsInside[K] <> 0) then begin
       if (Units[UnitsInside[K]] <> Nil) then with (Units[UnitsInside[K]]^) do
       with (GroupsBck[I]) do begin
         { jednotky }
         _unit:=Units[_unit2^.UnitsInside[K]];
         Units[_unit2^.UnitsInside[K]]^.GroupOrder:=I;
         Active:=True; Building:=NIL; ElementType:=_unit^.UnitType; Typ:=0;

         Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
         if (Mouse) then CursorOff;
         with (Unit_pictures[Unit_types[UnitType,Races[Race].Ally].PictureIndex]) do begin
            with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
            SpecSpeedPutImage3(X+1,Y+1,S1,O1,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);
            if (Selected) then SpeedPutImage2(X+1,Y+1,CrossSegment,CrossOffsets);
         end;
         Draw_damage(X1,Y1,Units[_unit2^.UnitsInside[K]]);
         Draw_morale(X2,Y2,Units[_unit2^.UnitsInside[K]]);
         Draw_experience(X3,Y3,Units[_unit2^.UnitsInside[K]]);
         if (Mouse) then CursorOn;
         Inc(I);
       end; { if + with Un[K]^ }
    end; { if }
  end; { with + for }
end;

{ ***** }
procedure Select_slot(Slot:Byte; Flag:Boolean);
{ je-li Flag=True, pak obsazeny slot Slot "oznaci", jinak (Flag=False)
  obsazeny slot Slot prekresli jako neoznaceny
}
var K, I, X, Y : Word;
    Mouse:Boolean;
begin
   I:=Slot;
   with (GroupsBck[I]) do with (_unit^) do begin
     Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
     if (Mouse) then CursorOff;
     if (Flag) then begin
       SpeedPutImage2(X+1,Y+1,CrossSegment,CrossOffsets);
     end else
        with (Unit_pictures[Unit_types[UnitType,Races[Race].Ally].PictureIndex]) do begin
           with (Background[52]) do SpeedPutImage(X+1,Y+1,Segment,Offsets);
           SpecSpeedPutImage3(X+1,Y+1,S1,O1,0,0,XCellSize-1,YCellSize-1,Races[Race].RaceColor);
        end;
     if (Mouse) then CursorOn;
  end; { if (I = 0) then .. else }
end;

{ ***** }
procedure Clear_group_slots;
{ smaze oblast leveho panel obrazovky, urceneho pro zobrazeni "naclicknute"
  jednotky (jednotek)
}
var K : Word;
    Mouses:Boolean;
begin
  if (ActiveGroup < 254) then with (Groups[ActiveGroup]) do begin
    for K:=0 to MaxGroupUnits-1 do begin
        with (GroupsBck[K]) do begin
          if (Active) then begin
             Mouses:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
             if (Mouses) then CursorOff;
             SpeedPutImage(X,Y,BckSegment,Offsets);
             if (Mouses) then CursorOn;
          end;
          Active:=False; _unit:=NIL; Building:=NIL; ElementType:=0;
        end;
    end;
  end;
end;

{ ***** }
procedure Clear_unit_slot(_unit:PUnit);
{ Vymaze slot na levem panelu obrazovky, na nemz je jednotka _unit
  pozn. jednotka musi byt v aktivni skupine !!!
}
var K, I, X, Y : Word;
    Mouse:Boolean;
begin
   I:=_unit^.GroupOrder;
   if (I >= MaxGroupUnits) then begin
      { chyba, zkus recover!! }
      OutBigMsg(255,'CHYBA V UMeSTdNe JEDNOTKY VE SKUPINd - RECOVER');
      _unit^.GroupOrder:=0;
   end;
   with (GroupsBck[I]) do begin
     if (Active) then begin
       Mouse:=TestMouse(X,Y,X+GroupsBckXSize,Y+GroupsBckYSize);
       if (Mouse) then CursorOff;
       SpeedPutImage(X,Y,BckSegment,Offsets);
       if (Mouse) then CursorOn;
     end else begin
       {Error(0,'unita Grafika2, procedura Clear_unit_slot');{}
     end;
     Active:=False; _unit:=NIL; Building:=NIL; ElementType:=0;
   end;
end;

{ ***** }
procedure Set_ok_cursor_mark(IC,JC:Word; Level:Byte);
{ nastavi znacku potvrzeni presunu na misto I,J a uroven Level
  (0..pozemni uroven, 1..vzdusna uroven)
}
var I,J:Word;
begin
   I:=OkMarkIPos; J:=OkMarkJPos;
   OkMarkIPos:=65535; OkMarkJPos:=65535;
   if ((I <> 65535) and (J <> 65535))
   then Draw_place(I,J);
   OkMarkIPos:=IC; OkMarkJPos:=JC; OkMarkLevel:=Level;
   OkMarkPhase:=0;
   case (Delay1) of
     5 : OkMarkFlagLimit:=8;
     4 : OkMarkFlagLimit:=8;
     3 : OkMarkFlagLimit:=12;
     2 : OkMarkFlagLimit:=12;
     1 : OkMarkFlagLimit:=16;
   else
   end;
   OkMarkFlag:=0;
end;

{ ***** }
procedure Set_attack_cursor_mark(UnitTarget:PPUnit; BuildingTarget:PPBuilding);
{ nastavi znacku utoku bud na jednotku (UnitTarget^)^ nebo
  budovu (BuildingTarget^)^
}
begin
   { "uklizeni" starych znacek }
   if ((AttackMarkUnit <> Nil) and (AttackMarkUnit^ <> Nil)) then
     (AttackMarkUnit^)^.RequestDraw:=True;
   if ((AttackMarkBuilding <> Nil) and (AttackMarkBuilding^ <> Nil)) then
     (AttackMarkBuilding^)^.RequestDraw:=True;

   AttackMarkUnit:=UnitTarget; AttackMarkBuilding:=BuildingTarget;
   AttackMarkPhase:=0;
   case (Delay1) of
     5 : AttackMarkFlagLimit:=8;
     4 : AttackMarkFlagLimit:=8;
     3 : AttackMarkFlagLimit:=12;
     2 : AttackMarkFlagLimit:=12;
     1 : AttackMarkFlagLimit:=16;
   else
   end;
   AttackMarkFlag:=0;
end;

{ ***** }
procedure Ok_atack_cursor_mark_manager;
{ osetruje trvani a faze znacky presunu/utoku
}
var I,J:Word;
begin
   I:=OkMarkIPos; J:=OkMarkJPos;
   Inc(OkMarkFlag);
   if (OkMarkFlag > OkMarkFlagLimit) then begin
      OkMarkFlag:=0; OkMarkIPos:=65535; OkMarkJPos:=65535;
   end;

   Inc(AttackMarkFlag);
   if (AttackMarkFlag > AttackMarkFlagLimit) then begin
      if ((AttackMarkUnit <> Nil) and (AttackMarkUnit^ <> Nil)) then
        (AttackMarkUnit^)^.RequestDraw:=True;
      if ((AttackMarkBuilding <> Nil) and (AttackMarkBuilding^ <> Nil)) then
        (AttackMarkBuilding^)^.RequestDraw:=True;
      AttackMarkUnit:=Nil; AttackMarkBuilding:=Nil;
      AttackMarkFlag:=0;
   end;

   case (Delay1) of
     5 : begin
            if (OkMarkFlag mod 1 = 0) then{}
              if (OkMarkPhase = 0) then OkMarkPhase:=1 else OkMarkPhase:=0;
            if (AttackMarkFlag mod 1 = 0) then{}
              if (AttackMarkPhase = 0) then AttackMarkPhase:=1 else AttackMarkPhase:=0;
         end;
     4 : begin
           if (OkMarkFlag mod 1 = 0) then{}
              if (OkMarkPhase = 0) then OkMarkPhase:=1 else OkMarkPhase:=0;
           if (AttackMarkFlag mod 1 = 0) then{}
              if (AttackMarkPhase = 0) then AttackMarkPhase:=1 else AttackMarkPhase:=0;
         end;
     3 : begin
           if (OkMarkFlag mod 1 = 0) then{}
              if (OkMarkPhase = 0) then OkMarkPhase:=1 else OkMarkPhase:=0;
           if (AttackMarkFlag mod 1 = 0) then{}
              if (AttackMarkPhase = 0) then AttackMarkPhase:=1 else AttackMarkPhase:=0;
         end;
     2 : begin
           if (OkMarkFlag mod 2 = 0) then{}
              if (OkMarkPhase = 0) then OkMarkPhase:=1 else OkMarkPhase:=0;
           if (AttackMarkFlag mod 2 = 0) then{}
              if (AttackMarkPhase = 0) then AttackMarkPhase:=1 else AttackMarkPhase:=0;
         end;
     1 : begin
           if (OkMarkFlag mod 3 = 0) then{}
              if (OkMarkPhase = 0) then OkMarkPhase:=1 else OkMarkPhase:=0;
           if (AttackMarkFlag mod 3 = 0) then{}
              if (AttackMarkPhase = 0) then AttackMarkPhase:=1 else AttackMarkPhase:=0;
         end;
   else
   end;

   if ((I <> 65535) and (J <> 65535))
   then Draw_place(I,J);

   if ((AttackMarkUnit <> Nil) and (AttackMarkUnit^ <> Nil)) then
     (AttackMarkUnit^)^.RequestDraw:=True;
   if ((AttackMarkBuilding <> Nil) and (AttackMarkBuilding^ <> Nil)) then
     (AttackMarkBuilding^)^.RequestDraw:=True;
end;

{ ***** }
procedure Set_unit_building_shadow(IC,JC,ISize,JSize:Word);
{ na pozici IC,JC se nachazi slozena budova o budouci velikosti ISize,
  JSize; tato jednotka byla naclicknuta, proto se misto jejiho
  rozlozeni oznaci kratkou zmenou pozadi
}
var I,J:Word;
    Index:Byte;
begin
   { nejprve pripadne odstraneni predchozi znacky }
   if ((IShadowPos1 <> 65535) and (JShadowPos1 <> 65535)) then begin
     Index:=0;
     for I:=IShadowPos1 to IShadowPos2 do
       for J:=JShadowPos1 to JShadowPos2 do with (MapBck^[I,J]) do begin
         BckType:=BckShadowType[Index];
         Draw_place(I,J);
         Inc(Index);
       end;
   end;

   IShadowPos1:=IC; JShadowPos1:=JC;
   IShadowPos2:=IC+ISize-1; JShadowPos2:=JC+JSize-1;
   ShadowFlag:=0; ShadowFlagPhase:=0; Index:=0;
   for I:=IShadowPos1 to IShadowPos2 do
     for J:=JShadowPos1 to JShadowPos2 do with (MapBck^[I,J]) do begin
       BckShadowType[Index]:=BckType;
       BckType:=256;
       Draw_place(I,J);
       Inc(Index);
     end;

   ShadowFlagLimit:=GetAccurateDelay(18);
end;

{ ***** }
procedure Unit_building_shadow_manager;
{ osetruje trvani a faze "stinu" slozene budovy - mista, kam je ji
  mozne rozlozit
}
var I,J:Word;
    Draw:Boolean;
    Index:Byte;
begin
   Inc(ShadowFlag); Draw:=False;
   if (ShadowFlag > ShadowFlagLimit) then begin { zruseni stinu }
      if ((IShadowPos1 <> 65535) and (JShadowPos1 <> 65535)) then begin
        Index:=0;
        for I:=IShadowPos1 to IShadowPos2 do
          for J:=JShadowPos1 to JShadowPos2 do with (MapBck^[I,J]) do begin
            BckType:=BckShadowType[Index];
            Draw_place(I,J);
            Inc(Index);
          end;
      end;
      ShadowFlag:=0; IShadowPos1:=65535; JShadowPos1:=65535;
   end;

   case (Delay1) of
     5 : begin
            if (ShadowFlag mod 2 = 0) then begin
              if (ShadowFlagPhase = 0) then ShadowFlagPhase:=1
              else ShadowFlagPhase:=0;
              Draw:=True;
            end;
         end;
     4 : begin
           if (ShadowFlag mod 2 = 0) then begin
              if (ShadowFlagPhase = 0) then ShadowFlagPhase:=1
              else ShadowFlagPhase:=0;
              Draw:=True;
           end;
         end;
     3 : begin
           if (ShadowFlag mod 3 = 0) then begin
              if (ShadowFlagPhase = 0) then ShadowFlagPhase:=1
              else ShadowFlagPhase:=0;
              Draw:=True;
           end;
         end;
     2 : begin
           if (ShadowFlag mod 4 = 0) then begin
              if (ShadowFlagPhase = 0) then ShadowFlagPhase:=1
              else ShadowFlagPhase:=0;
              Draw:=True;
           end;
         end;
     1 : begin
           if (ShadowFlag mod 6 = 0) then begin
              if (ShadowFlagPhase = 0) then ShadowFlagPhase:=1
              else ShadowFlagPhase:=0;
              Draw:=True;
           end;
         end;
   else
   end;

   if ((Draw) and (IShadowPos1 <> 65535) and (JShadowPos1 <> 65535)) then
     if (ShadowFlagPhase = 1) then begin
        Index:=0;
        for I:=IShadowPos1 to IShadowPos2 do
          for J:=JShadowPos1 to JShadowPos2 do with (MapBck^[I,J]) do begin
            BckType:=BckShadowType[Index];
            Draw_place(I,J);
            Inc(Index);
          end;
     end else begin
        Index:=0;
        for I:=IShadowPos1 to IShadowPos2 do
          for J:=JShadowPos1 to JShadowPos2 do with (MapBck^[I,J]) do begin
            BckType:=256;
            Draw_place(I,J);
            Inc(Index);
          end;
     end;
end;

{ ***** }
procedure Init_graphics_variables(XR,YR:Word);
{ na zaklade rozliseni XR,YR nadefinuje graficke promenne
}
begin
    XResolution := XR; YResolution := YR;
    XRes := XR; YRes := YR;
    { zacatek leveho horniho rohu kreslici obrazovky a
      velikost kreslici obrazovky: }
    RealHourMin:=0; LastRealHourMin:=65535; { realny cas }
    case (XResolution) of  { ! DOPLN ! }
     640 : begin
              XScreenBeg :=140; YScreenBeg :=26;
              XScreenSize:=480; YScreenSize:=416;
              { souradnice obrazovky radaru }
              XRadarBeg := 11; YRadarBeg := 1; XRadarEnd := 125; YRadarEnd := 115;
              { * GAME_TIME KONSTANTY * }
              { tykaji se "hodinoveho ramecku" v pravem hornim rohu }
              Game_timeXLength := 45;
              Game_timeYLength := 14;
              Game_timeXBeg := 589;
              Game_timeYBeg := 4;
              { * SLOTY PRO VYPIS ZPRAV * }
              { zacatek velkeho textu }
              BigXBeginConst:=238; BigYBeginConst:=5;
              { zacatek maleho textu }
              SmallXBeginConst:=10; SmallYBeginConst:=361;
              SmallYMsgDistance:=0;
              SmallMsgLen := 15; { delka zpravy ve znacich }
              BigMsgLen := 41;

              { * MATERIALS * }
              XMaterialSlotSize:=90; YMaterialSlotSize:=12;
              { material1 }
              XMaterialPicture1:=140; YMaterialPicture1:=454;
              XMaterialNumber1:=172; YMaterialNumber1:=460;
              XMaterialNumberLength:=55;
              { material2 }
              XMaterialPicture2:=255; YMaterialPicture2:=454;
              XMaterialNumber2:=287; YMaterialNumber2:=460;
              { material3 }
              XMaterialPicture3:=366; YMaterialPicture3:=454;
              XMaterialNumber3:=398; YMaterialNumber3:=460;
              { material4 }
              XMaterialPicture4:=469; YMaterialPicture4:=454;
              XMaterialNumber4:=501; YMaterialNumber4:=460;
              { HODINY REALNEHO CASU }
              RealHourMinX1:=588; RealHourMinY1:=457;
              RealHourMinX2:=635; RealHourMinY2:=470;
           end;
     800 : begin
              XScreenBeg := 156; YScreenBeg := 35;
              XScreenSize:=608; YScreenSize:=512;
              { souradnice obrazovky radaru }
              XRadarBeg := 21; YRadarBeg := 14; XRadarEnd := 134; YRadarEnd := 128;
              { * GAME_TIME KONSTANTY * }
              { tykaji se "hodinoveho ramecku" v pravem hornim rohu }
              Game_timeXLength := 47;
              Game_timeYLength := 14;
              Game_timeXBeg := 723;
              Game_timeYBeg := 10;
              { * SLOTY PRO VYPIS ZPRAV * }
              { zacatek velkeho textu }
              BigXBeginConst:=264; BigYBeginConst:=12;
              { zacatek maleho textu }
              SmallXBeginConst:=21; SmallYBeginConst:=483;
              SmallMsgLen := 15; { delka zpravy ve znacich }
              SmallYMsgDistance:=-327;
              BigMsgLen := 41;

              { * MATERIALS * }
              XMaterialSlotSize:=90; YMaterialSlotSize:=12;
              { material1 }
              XMaterialPicture1:=139+32; YMaterialPicture1:=455+109;
              XMaterialNumber1:=171+33; YMaterialNumber1:=460+108;
              XMaterialNumberLength:=48;
              { material2 }
              XMaterialPicture2:=266+32; YMaterialPicture2:=455+109;
              XMaterialNumber2:=298+33; YMaterialNumber2:=460+108;
              { material3 }
              XMaterialPicture3:=393+32; YMaterialPicture3:=455+109;
              XMaterialNumber3:=425+33; YMaterialNumber3:=460+108;
              { material4 }
              XMaterialPicture4:=519+32; YMaterialPicture4:=455+109;
              XMaterialNumber4:=551+33; YMaterialNumber4:=460+108;
              { HODINY REALNEHO CASU }
              RealHourMinX1:=722; RealHourMinY1:=566;
              RealHourMinX2:=770; RealHourMinY2:=582;
           end;
     1024 :begin
              XScreenBeg := 161; YScreenBeg := 39;
              XScreenSize:=832; YScreenSize:=672;
              { souradnice obrazovky radaru }
              XRadarBeg := 25; YRadarBeg := 14; XRadarEnd := 138; YRadarEnd := 128;
              { * GAME_TIME KONSTANTY * }
              { tykaji se "hodinoveho ramecku" v pravem hornim rohu }
              Game_timeXLength := 47;
              Game_timeYLength := 14;
              Game_timeXBeg := 942;
              Game_timeYBeg := 16;
              { * SLOTY PRO VYPIS ZPRAV * }
              { zacatek velkeho textu }
              BigXBeginConst:=324; BigYBeginConst:=17;
              { zacatek maleho textu }
              SmallXBeginConst:=22; SmallYBeginConst:=652;
              SmallMsgLen := 15; { delka zpravy ve znacich }
              SmallYMsgDistance:=-497;
              BigMsgLen := 41;

              { * MATERIALS * }
              XMaterialSlotSize:=90; YMaterialSlotSize:=12;
              { material1 }
              XMaterialPicture1:=139+150; YMaterialPicture1:=455+276;
              XMaterialNumber1:=171+151; YMaterialNumber1:=460+276;
              XMaterialNumberLength:=48;
              { material2 }
              XMaterialPicture2:=266+150; YMaterialPicture2:=455+276;
              XMaterialNumber2:=298+151; YMaterialNumber2:=460+276;
              { material3 }
              XMaterialPicture3:=393+150; YMaterialPicture3:=455+276;
              XMaterialNumber3:=425+151; YMaterialNumber3:=460+276;
              { material4 }
              XMaterialPicture4:=519+150; YMaterialPicture4:=455+276;
              XMaterialNumber4:=551+151; YMaterialNumber4:=460+276;
              { HODINY REALNEHO CASU }
              RealHourMinX1:=942; RealHourMinY1:=738;
              RealHourMinX2:=990; RealHourMinY2:=753;
           end;
     1280 :begin
           end;
    end;
    XScreenEnd := XScreenBeg + XScreenSize - 1;
    YScreenEnd := YScreenBeg + YScreenSize - 1;
    { souradnice konce kreslici obrazovky }
    IScreenSize := XScreenSize shr XCellShl;
    JScreenSize := YScreenSize shr YCellShl;
    IScreenSizeShr2 := IScreenSize shr 2;
    JScreenSizeShr2 := JScreenSize shr 2;

    { velikost kreslici obrazovky v polickach }
    IMem1:=0; JMem1:=0;
    IMem2:=2*IScreenSize; JMem2:=2*JScreenSize;  { krajni souradnice
    leveho horniho rohu obrazovky (polickove) v pameti (memorymapa)
     (pro ukladani zobrazovane obrazovky (velikost 3x3 obrazovky)) }

    { * GAME_TIME KONSTANTY * }
    MaxFlag_game_time := 80; { po kolikati cyklech se inkrementuje
    herni sekunda }

    { * SLOTY PRO VYPIS ZPRAV * }
    { delka zpravy ve znacich }
    SmallMsgMem := (LongInt(SmallMsgLen+1)*XFontSize+3)*(YFontSize+1)+10;
    BigMsgMem := LongInt(BigMsgLen+1)*(XFontSize+1)*YFontSize+10;
end;

{ ***** }
procedure New_graphics_mode(XR,YR:Word);
{ provede kompletni refresh obrazovky
}
var X,X2,Y,Y2,XPos,YPos,XPom,YPom,I,J,K:Word;
    IPom, JPom:Word;
    Mem:LongInt;
    Pom:Byte;
    Ret:String;
begin
   Clear_group_slots;
   if (ActiveGroup < 254) then begin
      Pom:=ActiveGroup;
      Deselect_group(ActiveGroup);
      for K:=0 to MaxGroupUnits-1 do with (Groups[Pom]) do begin
        if (Un[K] <> NIL) then begin
          Un[K]^.Group:=254; Un[K]:=NIL;
        end;
        if (Building <> Nil) then Building^.Group:=254;
        Building:=NIL;
      end;
   end;
   for I:=1 to MaxButtons do DeleteButton(I,256);

   if (YR <= 600) then EMS_line_adding:=4096 else EMS_line_adding:=4096;
   CursorOff;
   Init_graphics_variables(XR,YR);
   if (Debug) then GraphInitLight(XR,YR,XR,YR)
   else GraphInitLight(XR,YR,XR+40,YR);
   SetCursorRange(0,0,XR-4,YR-4);

   { * NAHRANI PALETY * }
   if (TerrainCondition <> Night) then
     LoadRGB(0,'data\paleta1.rgb')
   else
     LoadRGB(0,'data\paleta2.rgb');
   if (IO_Result <> 0) then Error(IO_Result,'- soubor data\paleta?.rgb');
   SetRGB(250,0,0,0);

   { * NAHRANI POZADI * }
   case (XR) of
      640  : OpenImage('data\640x480.bmp',NoCreateNew);
      800  : OpenImage('data\800x600.bmp',NoCreateNew);
      1024 : OpenImage('data\1024x768.bmp',NoCreateNew);
      1280 : OpenImage('data\1280x1024.bmp',NoCreateNew);
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor data\obr. desktop');
   LoadImageBMP(SScreen,OScreen,NoRGB);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor data\obr. desktop');
   PutImage(0,0,SScreen,OScreen,ReverseDirect);

   { tlacitka }
   case (XResolution) of
     640 : begin
              I:=19; J:=383;
              CreateButton(I,J,2,1,False,Stop); Inc(I,Button3XSize+2);
              CreateButton(I,J,2,2,False,Patrol); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,3,False,Nalozit); I:=19; J:=382+Button3YSize+4;
              CreateButton(I,J,2,4,False,Vylozit); CreateButton(I,J,2,5,False,Rozlozit);
              Inc(I,Button3XSize+2);
              CreateButton(I,J,2,6,False,Opravit); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,7,False,ZvednoutMoralku);
              {x}
              CreateButton(135,3,0,0,False,MenuButton);
              CreateButton(184,3,0,0,False,StopButton);
              CreateButton(93,124,0,0,False,RadarModButton);
              CreateButton(6,124,0,0,False,SellButton);
              ButtonText(SellButton,15,'');
              ButtonText(MenuButton,15,'MENU');
              Str(GameStopCount,Ret);
              ButtonText(StopButton,15,'('+Ret+')');
              ButtonText(RadarModButton,15,'MOD');
           end;
     800 : begin
              I:=30; J:=504;
              CreateButton(I,J,2,1,False,Stop); Inc(I,Button3XSize+2);
              CreateButton(I,J,2,2,False,Patrol); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,3,False,Nalozit);
              I:=30; J:=504+Button3YSize+3;
              CreateButton(I,J,2,4,False,Vylozit); CreateButton(I,J,2,5,False,Rozlozit);
              Inc(I,Button3XSize+2);
              CreateButton(I,J,2,6,False,Opravit); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,7,False,ZvednoutMoralku);
              {x}
              CreateButton(164,11,0,0,False,MenuButton);
              CreateButton(213,11,0,0,False,StopButton);
              CreateButton(110,190,0,0,False,RadarModButton);
              CreateButton(12,190,0,0,False,SellButton);
              ButtonText(SellButton,15,'');
              {CreateButton(I,J,1,0,False,TabButton);{}
              ButtonText(MenuButton,15,'MENU');
              Str(GameStopCount,Ret);
              ButtonText(StopButton,15,'('+Ret+')');
              ButtonText(RadarModButton,15,'MOD');{}
           end;
     1024: begin
              I:=32; J:=673;
              CreateButton(I,J,2,1,False,Stop); Inc(I,Button3XSize+2);
              CreateButton(I,J,2,2,False,Patrol); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,3,False,Nalozit);
              I:=32; J:=673+Button3YSize+3;
              CreateButton(I,J,2,4,False,Vylozit); CreateButton(I,J,2,5,False,Rozlozit);
              Inc(I,Button3XSize+2);
              CreateButton(I,J,2,6,False,Opravit); Inc(I,Button3XSize+3);
              CreateButton(I,J,2,7,False,ZvednoutMoralku);
              {x}
              CreateButton(214,16,0,0,False,MenuButton);
              CreateButton(263,16,0,0,False,StopButton);
              CreateButton(110,290,0,0,False,RadarModButton);
              CreateButton(12,290,0,0,False,SellButton);
              ButtonText(SellButton,15,'');
              {CreateButton(I,J,1,0,False,TabButton);{}
              ButtonText(MenuButton,15,'MENU');
              Str(GameStopCount,Ret);
              ButtonText(StopButton,15,'('+Ret+')');
              ButtonText(RadarModButton,15,'MOD');{}
           end;
   end;

   { pozadi }
   YInfoBegin:=YRes-YFontSize;

   { RAMECEK OKOLO HRACI PLOCHY NAHRAN }
   { ZBYTEK INICIALIZACI }
   I:=IBeg; J:=JBeg;  { centrovani leveho horniho rohu }
   if ((I+IScreenSize) > IMax) then I:=IMax-IScreenSize+1;
   if ((J+JScreenSize) > JMax) then J:=JMax-JScreenSize+1;
   if (J mod 2 = 1) then Dec(J);
   if (I mod 2 = 1) then Dec(I);
   { nyni se obrazovka precvakne }
   IMemPom:=IScreenSize; JMemPom:=JScreenSize;
   XMemBeg:=X2xCellSize+IScreenSize shl XCellShl;
   YMemBeg:=Y2xCellSize+JScreenSize shl YCellShl;
   IPom:=IBeg; JPom:=JBeg;
   JBeg:=J; IBeg:=I;
   Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);

   RadarInit;
   ClearRadarFrame(0,0);
   RedrawRadarFrame(IBeg,JBeg);{}

   { DALSI INICIALIZACE }
   GetSlotsInfo;
   Materials_info_pom;

   { OPET TLACITKA }
   SetActive(MenuButton); SetActive(StopButton); SetActive(RadarModButton);
   Release(MenuButton); Release(StopButton); Release(RadarModButton);
   Release(SellButton); SetPasive(SellButton,256);
   SetPasive(Stop,256); SetPasive(Patrol,256);
   SetPasive(Nalozit,256); SetPasive(Vylozit,256);
   SetPasive(Rozlozit,256); SetPasive(Opravit,256);
   SetPasive(ZvednoutMoralku,256);

   with (MsgStruct) do PutMemory(SmallMsgMem, SmallMsgBckSeg, SmallMsgBckOffs);
   with (MsgStruct) do PutMemory(BigMsgMem, BigMsgBckSeg, BigMsgBckOffs);
   MsgInit;
   ActiveDefenceRangeSlotsInit;
   Print_game_time(False);
   Print_material(3,Races[MyRace].Electric_energy);
   Print_material(2,Races[MyRace].Plastic_credits);
   Print_material(1,Races[MyRace].Building_credits);
   Print_material(4,Races[MyRace].Battle_experience);{}

   Draw_screen(IBeg,JBeg,0,0);
   CursorOn;
   SetCursor(NormalCursor);
end;

{ ************************ MENU GRAFIKA ************************************ }
{ ***** }
procedure CreateMenuRolovani;
{ vytvori s volbami rolovani
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*6 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*6) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 6 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-11*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'ROLOVaNe PO'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+11*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_1); ButtonText(_1,15,'1 BODU');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_2); ButtonText(_2,15,'2 BODECH');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_4); ButtonText(_4,15,'4 BODECH');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_8); ButtonText(_8,15,'8 BODECH');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_16); ButtonText(_16,15,'16 BODECH');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_32); ButtonText(_32,15,'32 BODECH');

   if (not RealTimeScroll) then begin
     Release(_1); Release(_2); Release(_4); Release(_8); Release(_16); Release(_32);
     SetActive(_1); SetActive(_2); SetActive(_4);
     SetActive(_8); SetActive(_16); SetActive(_32);
   end else begin
      Release(_32);
      SetActive(_32);
   end;
   CursorOff;
   if (ScrollSpeed = 7) then ButtonFrame(_1,64)
   else
     if (ScrollSpeed = 6) then ButtonFrame(_2,64)
     else
       if (ScrollSpeed = 5) then ButtonFrame(_4,64)
       else
         if (ScrollSpeed = 4) then ButtonFrame(_8,64)
         else
           if (ScrollSpeed = 3) then ButtonFrame(_16,64)
           else
             if (ScrollSpeed = 2) then ButtonFrame(_32,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0    : if (Scan = $01) then Konec:=True; { Esc }
         _1   : begin
                  Konec:=True;
                  ScrollSpeed:=7;
                end;
         _2   : begin
                  Konec:=True;
                  ScrollSpeed:=6;
                end;
         _4  : begin
                  Konec:=True;
                  ScrollSpeed:=5;
               end;
         _8  : begin
                  Konec:=True;
                  ScrollSpeed:=4;
               end;
         _16 : begin
                  Konec:=True;
                  ScrollSpeed:=3;
               end;
         _32 : begin
                  Konec:=True;
                  ScrollSpeed:=2;
               end;
      end;
   end;
   DeleteButton(_1,256); DeleteButton(_2,256); DeleteButton(_4,256);
   DeleteButton(_8,256); DeleteButton(_16,256); DeleteButton(_32,256);
end;

{ ***** }
procedure CreateMenuRozliseni;
{ vytvori obrazovku s prvnim menu
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*(MaxRes+1) <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*(MaxRes+1)) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 4 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-10*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'ROZLIgENe:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+10*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_640x480); ButtonText(_640x480,15,'640 x 480');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_800x600); ButtonText(_800x600,15,'800 x 600');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_1024x768); ButtonText(_1024x768,15,'1024 x 768');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_1200x1024); ButtonText(_1200x1024,15,'1280 x 1024');

   if (MaxRes >= 0) then Release(_640x480);
   if (MaxRes >= 1) then Release(_800x600);
   if (MaxRes >= 2) then Release(_1024x768);
   if (MaxRes >= 3) then Release(_1200x1024);
   if (MaxRes >= 0) then SetActive(_640x480);
   if (MaxRes >= 1) then SetActive(_800x600);
   if (MaxRes >= 2) then SetActive(_1024x768);
   if (MaxRes >= 3) then SetActive(_1200x1024);
   CursorOff;
   if (XResolution = 640) then ButtonFrame(_640x480,64)
   else
     if (XResolution = 800) then ButtonFrame(_800x600,64)
     else
       if (XResolution = 1024) then ButtonFrame(_1024x768,64)
       else
         if (XResolution = 1280) then ButtonFrame(_1200x1024,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _640x480   : begin
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
                         New_graphics_mode(640,480);
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);
                         CursorOn;
                      end;
         _800x600   : begin
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
                         New_graphics_mode(800,600);
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);
                         CursorOn;
                      end;
         _1024x768  : begin
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
                         New_graphics_mode(1024,768);
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);
                         CursorOn;
                      end;
         _1200x1024 : begin
                         Konec:=True;
                         CursorOff;
                         PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
                         New_graphics_mode(1280,1024);
                         CursorOff;
                         X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
                         GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);
                         CursorOn;
                      end;
      end;
   end;
   DeleteButton(_640x480,256); DeleteButton(_800x600,256); DeleteButton(_1024x768,256);
   DeleteButton(_1200x1024,256);
end;

{ ***** }
procedure CreateMenuCitlivostMysi;
{ vytvori obrazovku s prvnim menu
}
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*5 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*5) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 5 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-14*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'NASTAVENe MYgI:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+14*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Nizka); ButtonText(_Nizka,15,'CITLIVOST NeZKa');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Normalni); ButtonText(_Normalni,15,'CITLIVOST NORMaLNe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Vysoka); ButtonText(_Vysoka,15,'CITLIVOST VYSOKa');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp7); ButtonText(_Temp7,15,'ANIMOVAT');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Temp8); ButtonText(_Temp8,15,'NEANIMOVAT');

   Release(_Nizka); Release(_Normalni); Release(_Vysoka);
   Release(_Temp7); Release(_Temp8);
   SetActive(_Nizka); SetActive(_Normalni); SetActive(_Vysoka);
   SetActive(_Temp7); SetActive(_Temp8);
   CursorOff;
   if (MovementStep = 4) then ButtonFrame(_Nizka,64)
   else
     if (MovementStep = 3) then ButtonFrame(_Normalni,64)
     else
       if (MovementStep = 2) then ButtonFrame(_Vysoka,64);

   if (AnimatedCursor = 1) then ButtonFrame(_Temp7,64)
   else ButtonFrame(_Temp8,64);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Nizka     : begin
                         CursorOff;
                         FinishMouse;
                         MovementStep:=4;
                         InitMouse(XResolution,YResolution);
                         SetCursorRange(0,0,XResolution-4,YResolution-4);
                         if (AnimatedCursor = 0) then SetCursor(NormalCursor)
                         else begin
                           AnimCursorType:=NormalCursor;
                           SpeedGetImage(XMouse,YMouse,XMouse+XCursorSize, YMouse+YCursorSize,
                                         SegBackground,OffsBackground);{}
                           CursorManager;{}
                         end;
                         New_graphics_mode(XResolution,YResolution);
                         CursorOn;{}
                         Konec:=True;
                      end;
         _Normalni  : begin
                         CursorOff;
                         FinishMouse;
                         MovementStep:=3;
                         InitMouse(XResolution,YResolution);
                         SetCursorRange(0,0,XResolution-4,YResolution-4);
                         if (AnimatedCursor = 0) then SetCursor(NormalCursor)
                         else begin
                           AnimCursorType:=NormalCursor;
                           SpeedGetImage(XMouse,YMouse,XMouse+XCursorSize, YMouse+YCursorSize,
                                         SegBackground,OffsBackground);{}
                           CursorManager;{}
                         end;
                         New_graphics_mode(XResolution,YResolution);
                         CursorOn;
                         Konec:=True;
                      end;
         _Vysoka    : begin
                         CursorOff;
                         FinishMouse;
                         MovementStep:=2;
                         InitMouse(XResolution,YResolution);
                         SetCursorRange(0,0,XResolution-4,YResolution-4);
                         if (AnimatedCursor = 0) then SetCursor(NormalCursor)
                         else begin
                           AnimCursorType:=NormalCursor;
                           SpeedGetImage(XMouse,YMouse,XMouse+XCursorSize, YMouse+YCursorSize,
                                         SegBackground,OffsBackground);{}
                           CursorManager;{}
                         end;
                         New_graphics_mode(XResolution,YResolution);
                         CursorOn;
                         Konec:=True;
                      end;
         _Temp7     : begin
                         CursorOff;
                         AnimatedCursor:=1;
                         CursorOn;{}
                         Konec:=True;
                      end;
         _Temp8     : begin
                         CursorOff;
                         AnimatedCursor:=0;
                         CursorOn;{}
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_Nizka,256); DeleteButton(_Normalni,256); DeleteButton(_Vysoka,256);
   DeleteButton(_Temp7,256); DeleteButton(_Temp8,256);
end;

{ ***** }
procedure CreateMenuGrafika;
{ vytvori obrazovku s prvnim menu
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
Again:
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*7 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*7) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 6 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-14*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'NASTAVENe HRY:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+14*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Rozliseni); ButtonText(_Rozliseni,15,'GRAFICKc ROZLIgENe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Rolovani); ButtonText(_Rolovani,15,'ROLOVaNe OBRAZOVKY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_RealTimeScroll); ButtonText(_RealTimeScroll,15,'OVLaDaNe ROLOVaNe');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_CitlivostMysi); ButtonText(_CitlivostMysi,15,'NASTAVENe MYgI');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_RychlostHry); ButtonText(_RychlostHry,15,'RYCHLOST HRY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Autosave); ButtonText(_Autosave,15,'AUTOSAVE');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Zpet); ButtonText(_Zpet,15,'ZPdT');
   Release(_Rozliseni); Release(_Rolovani); Release(_RealTimeScroll); Release(_Zpet);
   Release(_CitlivostMysi); Release(_RychlostHry); Release(_Autosave);
   SetActive(_Rozliseni); SetActive(_RealTimeScroll); SetActive(_Rolovani);
   SetActive(_CitlivostMysi); SetActive(_RychlostHry); SetActive(_Autosave);
   SetActive(_Zpet);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Rozliseni : begin
                         DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
                         DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
                         DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
                         DeleteButton(_Autosave,256);
                         CreateMenuRozliseni;
                         Konec:=True;
                      end;
         _Rolovani  : begin
                         DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
                         DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
                         DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
                         DeleteButton(_Autosave,256);
                         CreateMenuRolovani;
                         Konec:=True;
                      end;
         _RealTimeScroll : begin
                         DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
                         DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
                         DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
                         DeleteButton(_Autosave,256);
                         CreateMenuRealTimeScroll;
                         Konec:=True;
                      end;
         _CitlivostMysi: begin
                         DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
                         DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
                         DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
                         DeleteButton(_Autosave,256);
                         CreateMenuCitlivostMysi;{}
                         Konec:=True;
                      end;
         _RychlostHry : begin
                         DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
                         DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
                         DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
                         DeleteButton(_Autosave,256);
                         CreateMenuRychlostHry;{}
                         Konec:=True;
                        end;
         _Autosave  : begin
                        DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
                         DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
                         DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
                         DeleteButton(_Autosave,256);
                         CreateMenuAutosave;{}
                         Konec:=True;
                      end;
         _Zpet      : begin
                         Konec:=True;
                      end;
      end;
   end;
   DeleteButton(_Rozliseni,256); DeleteButton(_Rolovani,256);
   DeleteButton(_Zpet,256); DeleteButton(_RealTimeScroll,256);
   DeleteButton(_CitlivostMysi,256); DeleteButton(_RychlostHry,256);
   DeleteButton(_Autosave,256);
end;
{ ************************ MENU GRAFIKA ************************************ }

{ **************************** MENU HRA ************************************ }
{ ***** }
procedure CreateCileMise;
{ toto menu zobrazi splene a nesplnene cile mise
}
const YSpace = 3; { mezery mezi jednotlivymi radky }
      XOdsaz = 20; { x-ove odsazeni textu od kraje }
      YOdsaz = 10; { y-ove odsazeni od vrchu a od odspodu }
      YButtonOdsaz = 15; { y-ove odsazeni od buttonu }
var I,J,X,Y,XP,YP,Uk:Word;
    MissionInfo:array[0..MaxCond] of record
                  Done:Boolean;
                  Describe:string[80];
                end;
    N1,N2:String;
    Num:Word;
    Scan,Ascii:Word;
begin
   { ukonceni menu }
   DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
   DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
   DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
   DeleteButton(_Hra,256);
   X:=(XResolution-XWindow1Size) shr 1{}; Y:=(YResolution-YWindow1Size) shr 1{};
   CursorOff;
   PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
   if (DrawScreen) then begin
      Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
      Draw_screen(IBeg,JBeg,0,0);
   end;
   { zhodnoceni a zobrazeni cilu: }
   Uk:=0; X:=0; Y:=0;
   if (CondUk < 0) then begin
   { zadne zadane hodnoty}
      MissionInfo[Uk].Done:=False;
      MissionInfo[Uk].Describe:='JE NUTNc ZNIbIT VgECHNY NEPfaTELE';
      X:=Length(MissionInfo[Uk].Describe)*XFontSize;
      Inc(Uk);
   end else begin
      for I:=0 to CondUk do with (VictoryConditions^[I]) do begin
        Str(Num1,N1); Str(Num2,N2);
        case (Condition) of
           1 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='ALESPON 1 JEDNOTKA DOJEDE NA URbENc MISTO';
                  Inc(Uk);
               end;
           2 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='MUSe BjT ZNIbENY VgECHNY ZADANc JEDNOTKY';
                  Inc(Uk);
               end;
           3 : begin
                  if (not Races[Num2].ChangeOnVisib) then begin
                     MissionInfo[Uk].Done:=Result = 1;
                     if (Num1 <> 255) then begin
                         if ((Num1 = 7) or (Num1 = 6) or (Num1 = 21)) then
                           MissionInfo[Uk].Describe:='MUSe BjT ZNIbEN KAkDj '+GetBuildingName(Num1)+
                                                      ' - '+GetRaceName(Num2)
                         else
                           if ((Num1 = 13) or (Num1 = 14)) then
                             MissionInfo[Uk].Describe:='MUSe BjT ZNIbENO KAkDc '+GetBuildingName(Num1)+
                                                       ' - '+GetRaceName(Num2)
                           else
                             MissionInfo[Uk].Describe:='MUSe BjT ZNIbENA KAkDa '+GetBuildingName(Num1)+
                                                        ' - '+GetRaceName(Num2);
                     end else
                        MissionInfo[Uk].Describe:='MUSe BjT ZNIbENY VgECHNY BUDOVY - '+GetRaceName(Num2);
                     Inc(Uk);
                  end else
                    if (CondUk = 0) then begin
                        MissionInfo[Uk].Done:=False;
                        MissionInfo[Uk].Describe:='JE NUTNc ZNIbIT VgECHNY NEPfaTELE';
                        X:=Length(MissionInfo[Uk].Describe)*XFontSize;
                        Inc(Uk);
                    end;
               end;
           4 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='URbENa JEDNOTKA DOJEDE NA ZADANc MeSTO';
                  Inc(Uk);
               end;
           5 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='NESMe BjT ZNIbENA kaDNa ZE ZADANjCH JEDNOTEK';
                  Inc(Uk);
               end;
           6 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='MUSe PfEkeT ALESPON 1 ZADANa JEDNOTKA';
                  Inc(Uk);
               end;
           7 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  if ((Num1 = 7) or (Num1 = 6) or (Num1 = 21)) then
                    MissionInfo[Uk].Describe:='NESMe BjT ZNIbEN kaDNj '+GetBuildingName(Num1)+
                                               ' - '+GetRaceName(Num2)
                  else
                    if ((Num1 = 13) or (Num1 = 14)) then
                      MissionInfo[Uk].Describe:='NESMe BjT ZNIbEN kaDNc '+GetBuildingName(Num1)+
                                                ' - '+GetRaceName(Num2)
                    else
                      MissionInfo[Uk].Describe:='NESMe BjT ZNIbENA kaDNa '+GetBuildingName(Num1)+
                                                 ' - '+GetRaceName(Num2);
                  Inc(Uk);
               end;
           8 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='MUSe PfEkeT ALESPON 1 '+GetBuildingName(Num1)+
                                            ' - '+GetRaceName(Num2);
                  Inc(Uk);
               end;
           9 : begin
                  MissionInfo[Uk].Done:=Result = 1;
                  MissionInfo[Uk].Describe:='MUSe BjT VYROBENA BUDOVA: '+GetBuildingName(Num1)+' - PObET: '+N2;
                  Inc(Uk);
               end;
           10: begin
                  if (not Races[Num1].ChangeOnVisib) then begin
                    MissionInfo[Uk].Done:=Result = 1;
                    MissionInfo[Uk].Describe:='MUSe BjT ZNIbENA STRANA: '+GetRaceName(Num1);
                    Inc(Uk);
                  end else
                    if (CondUk = 0) then begin
                        MissionInfo[Uk].Done:=False;
                        MissionInfo[Uk].Describe:='JE NUTNc ZNIbIT VgECHNY NEPfaTELE';
                        X:=Length(MissionInfo[Uk].Describe)*XFontSize;
                        Inc(Uk);
                    end;
               end;
        else
           Error(0,'Grafika2, procedura CreateCileMise, chybna hodnota v case');
        end;
        if ((TimeMin <> 0) or (TimeSec <> 0)) then begin
           Str(TimeMin,N1); Str(TimeSec,N2);
           MissionInfo[Uk-1].Describe:=MissionInfo[Uk-1].Describe +
                                        ' - LIMIT '+N1+':'+N2;
        end;
        if (MissionInfo[Uk-1].Done) then
           MissionInfo[Uk-1].Describe:='*  '+MissionInfo[Uk-1].Describe
        else MissionInfo[Uk-1].Describe:='   '+MissionInfo[Uk-1].Describe;

        if (Length(MissionInfo[Uk-1].Describe)*XFontSize > X)
        then X:=Length(MissionInfo[Uk-1].Describe)*XFontSize;
      end; { for }
   end; { if (CondUk < 0) then ... else ... }
   { * ZOBRAZENI * }
   if (X < BigButtonXSize) then X:=BigButtonXSize+50
   else X:=X+XOdsaz*2;
   Y:=BigButtonYSize+Uk*(YFontSize+YSpace)+2*YOdsaz+YButtonOdsaz;
   XP:=(XResolution-X) shr 1; YP:=(YResolution-Y) shr 1;
   if (XP mod 2 <> 0) then Dec(XP);
   ShowInfoPanel(XP,YP,XP+X-1,YP+Y-1);
   CursorOff;
   for I:=0 to Uk-1 do begin
      OutTextColor(XP+XOdsaz,YP+YOdsaz+I*(YFontSize+YSpace),65,MissionInfo[I].Describe);
   end;
   Inc(YP,YOdsaz+Uk*(YFontSize+YSpace)+YButtonOdsaz);
   XP:=XP+(X-BigButtonXSize) shr 1;
   CreateButton(XP,YP,1,0,False,_Ano); ButtonText(_Ano,15,'OK');
   Release(_Ano); SetActive(_Ano);
   CursorOn;

   repeat
     Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
   until (Num = _Ano);
   DeleteButton(_Ano,256);
   CloseInfoPanel;
end;

{ ***** }
procedure CreateMenuInfo(Index:Integer; Side:Word; Building:Boolean);
{ vytvori obrazovku s informacemi
}
const PictureSize = 128;
var I, X,Y,X2,Y2,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
    Temp:Single;
    AverageLAttack,AverageTAttack,AverageAAttack:Single;
    AverageLAttackCount,AverageTAttackCount,AverageAAttackCount,
    AverageDefence, AverageDefenceCount:Single;
    AverageBuildingDefence, AverageBuildingDefenceCount:Single;
    Phase:Byte;

{ XXX }
procedure DrawText(Index:Word; Building:Boolean);
{ vykresli textove info o objektu typu Index; Building = True,
  pokud je objekt budova (jinak jde o jednotku)
}
var Ret:String;
    X,Y,X2,Y2,XPom,YPom:Word;
    Konec:Boolean;
begin
   X:=(XResolution-XInfoSize) div 2; X2:=X+XInfoSize-1;
   Y:=(YResolution-YInfoSize) div 2; Y2:=Y+YInfoSize-1;
   CursorOff;
   PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
   SetPasive(_Temp1,256); SetPasive(_Temp2,256); SetPasive(_Temp3,256);
   SetPasive(_Temp4,256); SetPasive(_Temp5,256); SetPasive(_Temp6,256);

   Y2:=Y+YInfoSize-2*BigButtonYSize;
   X2:=(XInfoSize-BigButtonXSize) shr 1;
   Inc(X2,X);
   CreateButton(X2,Y2,1,0,False,_Temp7); ButtonText(_Temp7,65,'NaVRAT ZPdT');
   SetActive(_Temp7); Release(_Temp7);

   { VLASTNI VYPIS TEXTU }
   X:=(XResolution-XInfoSize) div 2;
   Y:=(YResolution-YInfoSize) div 2;
   Str(Index,Ret);
   if (Building) then begin
     with (Building_types[Index]) do begin
       OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+10,48,Name);
     end;
     OpenMapTxtFile('info\b'+Ret+'.txt');
   end else begin
     with (Unit_types[Index,1]) do begin
       OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+10,48,Name);
     end;
     OpenMapTxtFile('info\'+Ret+'.txt');
   end;
   ReadTxtString(Ret); { prvni radek je komentar }
   ReadTxtString(Ret); { druhy radek je komentar }

   X:=X+(XInfoSize-48*XFontSize) shr 1;
   Y:=Y+(YInfoSize-12*(YFontSize+4)) shr 1;

   I:=0;
   while ReadTxtString(Ret) do begin
      OutTextColor(X,Y,65,Ret);{}
      Inc(Y,YFontSize+4);
      Inc(I);
   end;{}
   InvalidateCache;
   { konec tisku informaci }

   CursorOn;
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
        _Temp7     : begin  { navrat zpet }
                        Konec:=True;
                     end;
      end;
   end;

   DeleteButton(_Temp7,256);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3);
   SetActive(_Temp4); SetActive(_Temp5); SetActive(_Temp6);
end;

{ XXX }
procedure DrawInfo(Index,Id,Side:Word; Building:Boolean);
{ vykresli info o objektu typu Index; Building = True, pokud je objekt
  budova (jinak jde o jednotku)
}
var Ret, Ret2:String;
    I,X,Y,X2,Y2,XPom,YPom:Word;
    Pom1, Pom2:Byte;
begin
   X:=(XResolution-XInfoSize) div 2; X2:=X+XInfoSize-1;
   Y:=(YResolution-YInfoSize) div 2; Y2:=Y+YInfoSize-1;
   CursorOff;
   PutImage(X,Y,TempSeg2,TempOfs2,NormalDirect);
   Release(_Temp1); Release(_Temp2); Release(_Temp3);
   Release(_Temp4); Release(_Temp5);{} Release(_Temp6);

   if (Building) then begin
   { info o budove }
     {*obrazek*}
     Str(Id,Ret);
     OutTextColor(X2-Length(Ret+'  ')*XFontSize,Y+4,66,Ret);
     Str(Index,Ret);
     Ret:='info\b'+Ret+'.bmp';
     OpenImage(Ret,NoCreateNew);
     if (IO_Result <> 0) then begin
       { animovane }
       for I:=0 to 11 do begin
         Str(Index,Ret2); Ret:='info\b'+Ret2;
         Str(I+1,Ret2); Ret:=Ret+'_'+Ret2+'.bmp';
         OpenImage(Ret,NoCreateNew); if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
         LoadImageBMP(Pictures128[I].S,Pictures128[I].O,NoRGB);
         if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
       end; Pictures128[0].Max:=11;
     end else begin
       { neanimovane }
       LoadImageBMP(Pictures128[0].S,Pictures128[0].O,NoRGB);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
       Pictures128[0].Max:=0;
     end;
     PutImage(X+4,Y+20,Pictures128[0].S,Pictures128[0].O,ReverseDirect);

     {*nazev*}
     with (Building_types[Index]) do begin
        OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+10,48,Name);
     end;
     Inc(X,PictureSize+12); Inc(Y,4+YFontSize+55);
     {*sila obrany *}
     with (Building_types[Index]) do begin
       Temp:=DefenceStrength;Temp:=Temp/AverageBuildingDefence;
       case (Round(Temp)) of
         0..2 : Ret:='0';
         3    : Ret:='1';
         4    : Ret:='2';
         5    : Ret:='3';
         6    : Ret:='4';
         7..8 : Ret:='5';
       else
          Ret:='6';
       end;
       if (Index = 11) then Ret:='-'; { letiste }
     end;
     OutTextColor(X,Y,64,'ODOLNOST:');
        OutText(X+Length('ODOLNOST: ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+10);
     {*dohled*}
     Str(Building_types[Index].Sight,Ret);
     OutTextColor(X,Y,64,'DOHLED  :');
        OutText(X+Length('DOHLED  : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+10);
     {*cena*}
     with (Building_types[Index]) do begin
        OutTextColor(X,Y,64,'CENA:  BP     PL     EE     EXP  '); Inc(Y,4+YFontSize+4);
        Ret:='      '; Str(BP,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(PL,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(EE,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(Ex,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        OutText(X,Y,Ret); Inc(Y,4+YFontSize+10);
     end;
   end else begin
   { info o jednotce }
     {*obrazek*}
     if (Side = 255) then begin { vetsina volani mimo stisk "i" nad
     konkretni jednotkou }
       Side:=1;
       if (not GlobalModify^.MyUnitsForMission[Index]) then Side:=0;
     end;
     if ((not UInfo.Valid) or (Index <> UInfo.Ind)) then with (UINfo) do begin
        Name:=Unit_types[Index,Side].Name;
        LA1:=Unit_types[Index,Side].LightAttack1;
        LA2:=Unit_types[Index,Side].LightAttack2;
        HA1:=Unit_types[Index,Side].HeavyAttack1;
        HA2:=Unit_types[Index,Side].HeavyAttack2;
        AA1:=Unit_types[Index,Side].AirAttack1;
        AA2:=Unit_types[Index,Side].AirAttack2;
        Rank:=0;
        DAMAGE:=Unit_types[Index,Side].DefenceStrength;
     end else
       if (UInfo.Valid and (Index = UInfo.Ind)) then with (UINfo) do begin
          case (Rank) of
           0: Name:=Name+' - VOJeN';
           1: Name:=Name+' - SVOBODNeK';
           2: Name:=Name+' - DESaTNeK';
           3: Name:=Name+' - SERkANT';
           4: Name:=Name+' - gTaBNe SERkANT';
           5: Name:=Name+' - PODPORUbeK';
           6: Name:=Name+' - PORUbeK';
           7: Name:=Name+' - NADPORUbeK';
           8: Name:=Name+' - KAPITaN';
           9: Name:=Name+' - MAJOR';
           10: Name:=Name+' - PODPLUKOVNeK';
           11: Name:=Name+' - PLUKOVNeK';
           12: Name:=Name+' - GENERaL';
          end;
       end;
     Str(Id,Ret);
     OutTextColor(X2-Length(Ret+'  ')*XFontSize,Y+4,66,Ret);
     Str(Index,Ret);
     Ret:='info\'+Ret+'.bmp';
     OpenImage(Ret,NoCreateNew);
     if (IO_Result <> 0) then begin
       { animovane }
       for I:=0 to 11 do begin
         Str(Index,Ret2); Ret:='info\'+Ret2;
         Str(I+1,Ret2); Ret:=Ret+'_'+Ret2+'.bmp';
         OpenImage(Ret,NoCreateNew); if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
         LoadImageBMP(Pictures128[I].S,Pictures128[I].O,NoRGB);
         if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
       end; Pictures128[0].Max:=11;
     end else begin
       { neanimovane }
       LoadImageBMP(Pictures128[0].S,Pictures128[0].O,NoRGB);
       if (IO_Result <> 0) then Error(IO_Result,'- soubor '+Ret);
       Pictures128[0].Max:=0;
     end;
     PutImage(X+4,Y+20,Pictures128[0].S,Pictures128[0].O,ReverseDirect);

     {*nazev*}
     with (Unit_types[Index,Side]) do begin
       OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+10,48,UInfo.Name);
     end;
     Inc(X,PictureSize+12); Inc(Y,4+YFontSize+25);
     {*sila utoku *}
     with (Unit_types[Index,Side]) do begin
       OutTextColor(X,Y,64,'SeLA hTOKU:'); Inc(Y,4+YFontSize+4);
       {}
       Temp:=UInfo.LA1; Temp:=Temp*GetKadence(MyRace,ShootSpeed1,Index);{}
       Temp:=Temp/AverageLAttack; Str(Round(Temp),Ret);
       Temp:=UInfo.LA2; Temp:=Temp*GetKadence(MyRace,ShootSpeed2,Index);{}
       Temp:=Temp/AverageLAttack; Str(Round(Temp),Ret2);
       if (Length(Ret) = 1) then Ret:=Ret+'    ' else Ret:=Ret+'   ';
       OutText(X,Y,' NA LEHKj CeL   :  '+Ret+Ret2); Inc(Y,4+YFontSize+4);
       {}
       Temp:=UInfo.HA1; Temp:=Temp*GetKadence(MyRace,ShootSpeed1,Index);{}
       Temp:=Temp/AverageTAttack; Str(Round(Temp),Ret);
       Temp:=UInfo.HA2; Temp:=Temp*GetKadence(MyRace,ShootSpeed2,Index);{}
       Temp:=Temp/AverageTAttack; Str(Round(Temp),Ret2);
       if (Length(Ret)) = 1 then Ret:=Ret+'    ' else Ret:=Ret+'   ';
       OutText(X,Y,' NA TdkKj CeL   :  '+Ret+Ret2); Inc(Y,4+YFontSize+4);
       {}
       if (Index = 18) then begin { stihac, pocitej ho jinak }
         Temp:=UInfo.AA1; Temp:=Temp*2.9;{}
       end else begin
         Temp:=UInfo.AA1; Temp:=Temp*GetKadence(MyRace,ShootSpeed1,Index);{}
       end;
       Temp:=Temp/AverageAAttack; Str(Round(Temp),Ret);
       Temp:=UInfo.AA2; Temp:=Temp*GetKadence(MyRace,ShootSpeed2,Index);{}
       Temp:=Temp/AverageAAttack; Str(Round(Temp),Ret2);
       if (Length(Ret)) = 1 then Ret:=Ret+'    ' else Ret:=Ret+'   ';
       OutText(X,Y,' NA VZDUgNj CeL :  '+Ret+Ret2); Inc(Y,4+YFontSize+6);
     end;
     {*dostrel*}
     Ret:='';
     Pom1:=Hi(Unit_types[Index,Side].ShootRange1); Pom2:=Lo(Unit_types[Index,Side].ShootRange1);
     if (Pom1 > 0) then begin
        Str(Pom1,Ret2); Ret:=Ret+Ret2+'-'; Str(Pom2,Ret2); Ret:=Ret+Ret2+'  ';
     end;
     Pom1:=Hi(Unit_types[Index,Side].ShootRange2); Pom2:=Lo(Unit_types[Index,Side].ShootRange2);
     if (Pom1 > 0) then begin
        Str(Pom1,Ret2); Ret:=Ret+Ret2+'-'; Str(Pom2,Ret2); Ret:=Ret+Ret2;
     end;
     OutTextColor(X,Y,64,'DOSTfEL :');
        OutText(X+Length('DOSTfEL         : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+6);
     {*typ obrany *}
     with (Unit_types[Index,Side]) do begin
       if (TargetTyp < 2) then Ret:='LEHKj'
       else
         if (TargetTyp = 2) then Ret:='TdkKj'
         else
           if (TargetTyp = 3) then Ret:='VZDUgNj'
           else Ret:='NaMOfNe';
     end;
     OutTextColor(X,Y,64,'TYP     :');
        OutText(X+Length('TYP     : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+6);
     {*sila obrany *}
     with (Unit_types[Index,Side]) do begin
       Temp:=UInfo.DAMAGE;Temp:=Temp/AverageDefence;
       case (Round(Temp)) of
         0..1 : Ret:='0';
         2    : Ret:='1';
         3    : Ret:='2';
         4    : Ret:='3';
         5    : Ret:='4';
         6    : Ret:='5';
         7    : Ret:='6';
         8    : Ret:='7';
       else
          Ret:='8';
       end;
     end;
     OutTextColor(X,Y,64,'ODOLNOST:');
        OutText(X+Length('ODOLNOST: ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+6);
     {*dohled*}
     Str(Unit_types[Index,Side]._Sight,Ret);
     OutTextColor(X,Y,64,'DOHLED  :');
        OutText(X+Length('DOHLED  : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+6);
     {*rychlost pohybu*}
     with (Unit_types[Index,Side]) do begin
       Pom1:=SpeedLevel;
       if (UnitLevel = 255) then Pom1:=255;
     end;
     case (Pom1) of
       0 : Ret:='1';
       1 : Ret:='2';
       2 : Ret:='3';
       3 : Ret:='4';
       4 : Ret:='5';
       5 : Ret:='6';
       6 : Ret:='7';
     else
       Ret:='STATICKa';
     end;
     OutTextColor(X,Y,64,'RYCHLOST:');
        OutText(X+Length('RYCHLOST: ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+6);
     {*cena*}
     with (Unit_types[Index,Side]) do begin
        OutTextColor(X,Y,64,'CENA:  BP     PL     EE     EXP  '); Inc(Y,4+YFontSize+4);
        Ret:='      '; Str(BP,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(PL,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(EE,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(Ex,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        OutText(X,Y,Ret); Inc(Y,4+YFontSize+6);
     end;
     with (Unit_types[Index,Side]) do begin
        {*specialni vlastnosti*}
        Y:=(YResolution-YInfoSize) shr 1 + 45 + PictureSize+SmallButtonYSize+6;
        if (Capacity > 0) then begin
          OutTextColor(X-PictureSize-6,Y,48,'-LZE NALOkIT'); Inc(Y,YFontSize+6);
        end;
        if ((SpecAirLevel = 0) and (TargetTyp = 3)) then begin
          OutTextColor(X-PictureSize-6,Y,48,'-kaDa LETIgTd'); Inc(Y,YFontSize+6);
        end;
        if (GuidedMissile) then begin
          OutTextColor(X-PictureSize-6,Y,48,'-NAVaDdNc RAKETY'); Inc(Y,YFontSize+6);
        end;
        if (Index = 29) then begin { mutant }
          OutTextColor(X-PictureSize-6,Y,48,'-SNIkUJE MORaLKU'); Inc(Y,YFontSize+6);
        end;
        if ((Index = 15) or (Index = 39)) then begin { likvidator, commandos }
          OutTextColor(X-PictureSize-6,Y,48,'-ELITNe SeLY'); Inc(Y,YFontSize+6);
        end;
        if ((Index = 9) or (Index = 7)) then begin { vysadkar, vysadkovy tank  }
          OutTextColor(X-PictureSize-6,Y,48,'-VZDUgNc VjSADKY'); Inc(Y,YFontSize+6);
        end;
        if (Index = 23) then begin { autodetonator }
          OutTextColor(X-PictureSize-6,Y,48,'-SEBEVRAkEDNj'); Inc(Y,YFontSize+6);
          OutTextColor(X-PictureSize-6,Y,48,'-PROTI BUDOVaM'); Inc(Y,YFontSize+6);
        end;
        if ((Index = 18) or (Index = 19)) then begin { stihac, terminator }
          OutTextColor(X-PictureSize-6,Y,48,'-JEDEN VjSTfEL'); Inc(Y,YFontSize+6);
        end;
     end;
   end;
   CursorOn;
   UInfo.Valid:=False;
end;

{ xxx }
begin
   { ziskani statistickych informaci: }
{   AverageLAttack:=0; AverageTAttack:=0; AverageAAttack:=0;
   AverageLAttackCount:=0; AverageTAttackCount:=0; AverageAAttackCount:=0;
   AverageDefence:=0; AverageDefenceCount:=0;
   AverageBuildingDefence:=0; AverageBuildingDefenceCount:=0;
   for I:=1 to MaxTypesOfUnits do with (Unit_types[I,1]) do begin
     if (LightAttack1 > 0) then begin
        Temp:=LightAttack1; Temp:=Temp*GetKadence(MyRace,ShootSpeed1,I);
        AverageLAttack:=AverageLAttack+Temp;
        AverageLAttackCount:=AverageLAttackCount+1;
     end;
     if (LightAttack2 > 0) then begin
        Temp:=LightAttack2; Temp:=Temp*GetKadence(MyRace,ShootSpeed2,I);
        AverageLAttack:=AverageLAttack+Temp;
        AverageLAttackCount:=AverageLAttackCount+1;
     end;
     {}
{     if (HeavyAttack1 > 0) then begin
        Temp:=HeavyAttack1; Temp:=Temp*GetKadence(MyRace,ShootSpeed1,I);
        AverageTAttack:=AverageTAttack+Temp;
        AverageTAttackCount:=AverageTAttackCount+1;
     end;
     if (HeavyAttack2 > 0) then begin
        Temp:=HeavyAttack2; Temp:=Temp*GetKadence(MyRace,ShootSpeed2,I);
        AverageTAttack:=AverageTAttack+Temp;
        AverageTAttackCount:=AverageTAttackCount+1;
     end;
     {}
{     if (AirAttack1 > 0) then begin
        Temp:=AirAttack1; Temp:=Temp*GetKadence(MyRace,ShootSpeed1,I);
        AverageAAttack:=AverageAAttack+Temp;
        AverageAAttackCount:=AverageAAttackCount+1;
     end;
     if (AirAttack2 > 0) then begin
        Temp:=AirAttack2; Temp:=Temp*GetKadence(MyRace,ShootSpeed2,I);
        AverageAAttack:=AverageAAttack+Temp;
        AverageAAttackCount:=AverageAAttackCount+1;
     end;
     AverageDefence:=AverageDefence+DefenceStrength;
     AverageDefenceCount:=AverageDefenceCount+1;
   end;
   for I:=1 to MaxTypesOfBuildings do with (Building_types[I]) do begin
     if (I <> 25) then begin { nejde o prekazku }
{       AverageBuildingDefence:=AverageBuildingDefence+DefenceStrength;
       AverageBuildingDefenceCount:=AverageBuildingDefenceCount+1;
     end;
   end;
   AverageLAttack:=(AverageLAttack/AverageLAttackCount)/5;
   AverageTAttack:=(AverageTAttack/AverageTAttackCount)/5;
   AverageAAttack:=(AverageAAttack/AverageAAttackCount)/5;
   AverageDefence:=(AverageDefence/AverageDefenceCount)/5;
   AverageBuildingDefence:=(AverageBuildingDefence/AverageBuildingDefenceCount)/5; {}
   AverageLAttack:=100;
   AverageTAttack:=90;
   AverageAAttack:=50;
   AverageDefence:=205;
   AverageBuildingDefence:=740;

   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   CursorOff;
   PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
   CursorOn;

   X:=(XResolution-XInfoSize) div 2; X2:=X+XInfoSize-1;
   Y:=(YResolution-YInfoSize) div 2; Y2:=Y+YInfoSize-1;
   ShowInfoPanel(X,Y,X2,Y2);
   CursorOff;
   GetImage(X,Y,X2,Y2,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;

   X:=(XResolution-XInfoSize) shr 1 + (PictureSize-SmallButtonXSize) shr 1;
   Y:=(YResolution-YInfoSize) shr 1 + 40 + PictureSize;
   CreateButton(X,Y,0,0,False,_Temp5); ButtonText(_Temp5,65,'TEXT');
   {}
   X:=(XResolution-XInfoSize) shr 1; Y:=(YResolution-YInfoSize) shr 1;
   Y:=Y+YInfoSize-2*SmallButtonYSize;
   X2:=(XInfoSize-5*SmallButtonXSize) div 6;
   Inc(X,X2);
   CreateButton(X,Y,0,0,False,_Temp1); ButtonText(_Temp1,65,'<<');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,0,0,False,_Temp2); ButtonText(_Temp2,65,'<');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,0,0,False,_Temp6); ButtonText(_Temp6,65,'ZPdT');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,0,0,False,_Temp3); ButtonText(_Temp3,65,'>');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,0,0,False,_Temp4); ButtonText(_Temp4,65,'>>');

   Release(_Temp1); Release(_Temp2); Release(_Temp3);
   Release(_Temp4); Release(_Temp5); Release(_Temp6);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3);
   SetActive(_Temp4); SetActive(_Temp5); SetActive(_Temp6);

   { ** vlastni prace s informacnim panelem ** }
   if (Building) then
     DrawInfo(BuildingsInfoRecord.Rec[Index],Index,Side,Building)
   else
     DrawInfo(UnitsInfoRecord.Rec[Index],Index,Side,Building);

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Phase:=0;
      X2:=(XResolution-XInfoSize) div 2; Y2:=(YResolution-YInfoSize) div 2;
      repeat
        Num:=MousKeybClick2(X,Y,Button,Scan,Ascii);
        Inc(Phase); if (Phase > Pictures128[0].Max) then Phase:=0;
        CursorOff;
        PutImage(X2+4,Y2+20,Pictures128[Phase].S,Pictures128[Phase].O,ReverseDirect);
        CursorOn;
      until (Num <> 255);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Temp1     : begin  { rychle pretoceni dozadu }
                         Dec(Index,10);
                         if (Building) then begin
                           if (Index < 1) then begin
                             Building:=False;
                             Index:=UnitsInfoRecord.MaxIndex;
                           end;
                         end else begin
                           if (Index < 1) then begin
                             Building:=True;
                             Index:=BuildingsInfoRecord.MaxIndex;
                           end;
                         end;
                         if (Building) then
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,Side,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,Side,Building);
                      end;
         _Temp2     : begin  { 1 krok dozadu }
                         Dec(Index);
                         if (Building) then begin
                           if (Index < 1) then begin
                             Building:=False;
                             Index:=UnitsInfoRecord.MaxIndex;
                           end;
                         end else begin
                           if (Index < 1) then begin
                             Building:=True;
                             Index:=BuildingsInfoRecord.MaxIndex;
                           end;
                         end;
                         if (Building) then
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,Side,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,Side,Building);
                      end;
         _Temp3     : begin  { 1 krok dopredu }
                         Inc(Index);
                         if (Building) then begin
                           if (Index > BuildingsInfoRecord.MaxIndex) then begin
                             Building:=False;
                             Index:=1;
                           end;
                         end else begin
                           if (Index > UnitsInfoRecord.MaxIndex) then begin
                             Building:=True;
                             Index:=1;
                           end;
                         end;
                         if (Building) then
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,Side,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,Side,Building);
                      end;
         _Temp4     : begin  { rychle pretoceni dopredu }
                         Inc(Index,10);
                         if (Building) then begin
                           if (Index > BuildingsInfoRecord.MaxIndex) then begin
                             Building:=False;
                             Index:=1;
                           end;
                         end else begin
                           if (Index > UnitsInfoRecord.MaxIndex) then begin
                             Building:=True;
                             Index:=1;
                           end;
                         end;
                         if (Building) then
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,Side,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,Side,Building);
                      end;
         _Temp5     : begin  { vytisknuti textu o objektu }
                         if (Building) then begin
                           DrawText(BuildingsInfoRecord.Rec[Index],Building);
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,Side,Building);
                         end else begin
                           DrawText(UnitsInfoRecord.Rec[Index],Building);
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,Side,Building);
                         end;
                      end;
         _Temp6     : Konec:=True; { Esc }
      end;
   end;
   { ** konec prace s informacnim panelem ** }
   DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   DeleteButton(_Temp3,256); DeleteButton(_Temp4,256);
   DeleteButton(_Temp5,256); DeleteButton(_Temp6,256);

   CloseInfoPanel;

   CursorOff;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);{}
   CursorOn;
end;

{ ***** }
procedure CreateMenuHra;
{ vytvori obrazovku s menu Hra
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
Again:
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*4 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*4) shr 1
   else YAdd:=0;
   { !!!!!!!!!! pozn. 4 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-10*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'INFORMACE:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+10*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Doomy); ButtonText(_Doomy,15,'CeLE MISE');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Ustup); ButtonText(_Ustup,15,'hSTUP');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Info); ButtonText(_Info,15,'INFO O OBJEKTECH');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Zpet); ButtonText(_Zpet,15,'ZPdT');

   Release(_Doomy); Release(_Ustup); Release(_Info); Release(_Zpet);
   SetActive(_CitlivostMysi); SetActive(_Doomy); SetActive(_RychlostHry);
   SetActive(_Ustup); SetActive(_Info);SetActive(_Zpet);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Doomy     : begin { ! cile mise ! }
                         DeleteButton(_Zpet,256); DeleteButton(_Doomy,256);
                         DeleteButton(_Info,256); DeleteButton(_Ustup,256);
                         CreateCileMise; Skip:=True;
                         Konec:=True;
                      end;
         _Ustup     : begin { USTUP Z BOJE }
                         DeleteButton(_Zpet,256); DeleteButton(_Doomy,256);
                         DeleteButton(_Info,256); DeleteButton(_Ustup,256);
                         CreateMenuUstup; Skip:=True;
                         Konec:=True;
                      end;
         _Info      : begin { INFO }
                         DeleteButton(_Zpet,256); DeleteButton(_Doomy,256);
                         DeleteButton(_Info,256); DeleteButton(_Ustup,256);
                         CreateMenuInfo(1,255,False);
                         GoTo Again;
                      end;
         _Zpet      : begin
                         Konec:=True;
                      end;
      end;
   end;
   if (not Skip) then begin
     DeleteButton(_Zpet,256); DeleteButton(_Doomy,256);
     DeleteButton(_Info,256); DeleteButton(_Ustup,256);
   end;
end;

{ **************************** MENU HRA ************************************ }
{ ***** }
procedure CreateMenu;
{ vytvori obrazovku s prvnim menu
}
label Again;
var X,Y,X1,Y1,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
begin
   { vlastni vytvoreni }
   Scan:=0;
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   if (Word(BigButtonYSize+YFontSize)*7 <= (YWindow1Size-YFontSize shl 2))
   then
     YAdd:=((YWindow1Size-YFontSize shl 2) - Word(BigButtonYSize+YFontSize)*7) shr 1+Scan
   else YAdd:=0;
   { !!!!!!!!!! pozn. 7 = POCET TLACITEK !!!!!!!!!! }
   CursorOff;
   GetImage(X,Y,X+XWindow1Size-1,Y+YWindow1Size-1,Win1BckSeg,Win1BckOfs,NormalDirect);{}
Again:
   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   PutImage2(X,Y,Win1Seg,Win1Ofs,NormalDirect);
   X1:=X+(XWindow1Size-5*XFontSize) shr 1;
   Y1:=Y+YFontSize; Inc(Y,8+YFontSize shl 1);
   OutTextColor(X1,Y1,11,'MENU:'); SetColor(11);
   NLine(X1,Y1+YFontSize,X1+5*XFontSize,Y1+YFontSize);
   Inc(Y,YAdd);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Grafika); ButtonText(_Grafika,15,'NASTAVENe HRY');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Zvuk); ButtonText(_Zvuk,15,'ZVUK/HUDBA');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Hra); ButtonText(_Hra,15,'INFORMACE');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_NahratHru); ButtonText(_NahratHru,15,'NAHRaT HRU');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_UlozitHru); ButtonText(_UlozitHru,15,'ULOkIT HRU');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_UkoncitHru); ButtonText(_UkoncitHru,15,'UKONbIT HRU');
   Inc(Y,BigButtonYSize+YFontSize);
   X1:=X; Y1:=Y;
   Inc(X1,(XWindow1Size-BigButtonXSize) shr 1);
   CreateButton(X1,Y1,1,0,False,_Zpet); ButtonText(_Zpet,15,'ZPdT');
   Inc(Y,BigButtonYSize+YFontSize);
   Release(_Grafika); Release(_NahratHru); Release(_UlozitHru);
   Release(_UkoncitHru); Release(_Zpet); Release(_Zvuk); Release(_Hra);
   SetActive(_Grafika); SetActive(_Zvuk); SetActive(_Hra);
   SetActive(_NahratHru); SetActive(_UlozitHru); SetActive(_UkoncitHru);
   SetActive(_Zpet); SetActive(_Grafika);
   CursorOn;

   { nyni reakce na akci }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = $01) then Konec:=True; { Esc }
         _Grafika   : begin
                         DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
                         DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
                         DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
                         DeleteButton(_Hra,256);
                         CreateMenuGrafika;
                         CursorOff; Goto Again;
                      end;
         _Zvuk      : begin
                         DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
                         DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
                         DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
                         DeleteButton(_Hra,256);
                         CreateMenuZvukHudba;
                         CursorOff; Goto Again;
                      end;
         _Hra       : begin
                         DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
                         DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
                         DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
                         DeleteButton(_Hra,256);
                         Skip:=False;
                         CreateMenuHra;{}
                         if (Skip) then Konec:=True
                         else begin
                            CursorOff; Goto Again;
                         end;
                      end;
         _NahratHru : begin
                         DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
                         DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
                         DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
                         DeleteButton(_Hra,256);
                         LoadDialog;
                         Konec:=True;
                      end;
         _UlozitHru : begin
                         DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
                         DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
                         DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
                         DeleteButton(_Hra,256);
                         SaveGame:=1; Konec:=True;
                      end;
         _UkoncitHru: begin
                         DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
                         DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
                         DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
                         DeleteButton(_Hra,256);
                         CreateMenuExit;
                         CursorOff; Konec:=True;
                      end;
         _Zpet      : begin
                         Konec:=True;
                         {Exec('c:\vc.com','');{}
                      end;
      end;
   end;
   if (not Skip) then begin
     DeleteButton(_Grafika,256); DeleteButton(_NahratHru,256);
     DeleteButton(_UlozitHru,256); DeleteButton(_UkoncitHru,256);
     DeleteButton(_Zpet,256); DeleteButton(_Zvuk,256);
     DeleteButton(_Hra,256);
   end;
end;

{ ***** }
procedure MenuOptions;
{ umozni volit z menu
}
var X,Y,X1,Y1:Word;
begin
   DrawScreen:=False;
   {X:=XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;
   {SetCursorRange(X,Y,X+XWindow1Size,Y+YWindow1Size);{}
   CreateMenu;
   { ukonceni menu }
   if (not Skip) then begin
      X:=(XResolution-XWindow1Size) shr 1{}; Y:=(YResolution-YWindow1Size) shr 1{};
      CursorOff;
      PutImage2(X,Y,Win1BckSeg,Win1BckOfs,NormalDirect);
      if (DrawScreen) then begin
         Draw_map_frame(IBeg,IBeg+IScreenSize-1,JBeg,JBeg+JScreenSize-1);
         Draw_screen(IBeg,JBeg,0,0);
      end;
      CursorOn;
   end;
   Skip:=False;
end;

{ ***** }
procedure Grafika2_save;
{ pro potreby ulozeni hry
}
label K;

begin
{   Assign(IOFile,'save\'+SavePath+'4'); ReWrite(IOFile,1); DResult:=IOResult;
   if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;
{x}{BlockWrite(IOFile,ActiveDefenceStruct,SizeOf(ActiveDefenceStruct));
   DResult:=IOResult;if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}

K:
  {Close(IOFile); DResult:=IOResult;{}
end;

{ ***** }
procedure Grafika2_load;
{ pro potreby ulozeni hry
}
label K;

begin
{  Reset(CheckFile,1); DResult:=IOResult;
  { existence souboru check znaci OK, jinak jde o chybu }
{  if (DResult <> 0) then GoTo K;
  Close(CheckFile);
  Assign(IOFile,'save\'+SavePath+'4'); Reset(IOFile,1); DResult:=IOResult;
  if(DResult<>0)then begin Erase(CheckFile);GoTo K;end;{}
  Price_bck_is_active:=False;
  ActiveDefenceStruct.Present:=False;

K:
  {Close(IOFile); Close(CheckFile); DResult:=IOResult;{}
end;

{ ************************************************************************** }
begin
   ActiveDefenceStruct.Segment:=0;
   Price_bck_is_active:=False;
   OkMarkIPos:=65535; OkMarkJPos:=65535;
   IShadowPos1:=65535; JShadowPos1:=65535;
   Skip:=False; UINfo.Valid:=False;
end.