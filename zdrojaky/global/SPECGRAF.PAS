{ ZMENIT KONSTANTY X,Y
  ZMENIT INICIALIZACI JEDNOTEK A BUDOV
}
unit SpecGraf;
{$C FIXED PRELOAD PERMANENT}
{x}
interface
uses Crt,data_glb, graph257, mouse;
const _YES = 0; _YES_NO = 1; _YES_NO_CANCEL = 2;
      YES = 0;
      NO  = 1;
      CANCEL = 2;

procedure CreateMenuInfo;
procedure OpenMapTxtFile(Way:String);
function ReadTxtString(var Ret:String):Boolean;
function DialogBox(Msg:String; DlgType:Byte):Byte;
function WideDialogBox(Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
function WideDialogBoxX(Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
function SpecWideDialogBox(UnitType:Word; Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
procedure ReadTxtWord(var Num:Word);
function SelectSingleMission:Boolean;
procedure DrawPoints;
procedure DrawVictoryPoints;
procedure InitReasearchAssign;
procedure Load_unit_picture;
function GetString(MaxChars:Byte; var Ret:String):Boolean;

implementation

uses Buttons, GlobGraf, GlobalKod;

const Ws : set of Byte = [$0d,$0a];
      X = 5.0;
      Y = 2.0;
const Speed : array[0..6] of TSpeedArray =
            ((1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,1,1,1,1,1,1,1,1,1),
             (2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1),
             (2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,2,3,1,1,1,1,1,1,1,1,1,1),
             (3,3,3,3,3,3,3,3,3,3,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (4,4,4,4,4,4,4,4,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
             (5,6,5,5,6,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1));

var Character:Char;
    MapTxtFile:File;
    MapTxtFileWay:String;
    I, J:Integer;

{ ****** }
procedure OpenMapTxtFile(Way:String);
{
}
begin
   MapTxtFileWay:=Way; InvalidateCache;
   IO_Result:=CacheFetch(Way);
   if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
end;

{ ****** }
function ReadTxtString(var Ret:String):Boolean;
{
}
begin
  if (CacheEof(MapTxtFile)) then ReadTxtString:=False
  else begin
     Ret:='';
     while ((Ord(Character) in Ws) and (not CacheEof(MapTxtFile))) do begin
       CacheBlockRead(MapTxtFile,@Character,1);
       if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
     end;

     if (CacheEof(MapTxtFile)) then ReadTxtString:=False
     else begin
       repeat
         Ret:=Ret+Character;
         CacheBlockRead(MapTxtFile,@Character,1);
         if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
       until ((Ord(Character) in Ws) or (CacheEof(MapTxtFile)));
     end;

     if (CacheEof(MapTxtFile)) then ReadTxtString:=False
     else ReadTxtString:=True;
  end;
end;

{ ****** }
procedure ReadTxtWord(var Num:Word);
{
}
begin
   Num:=0;
   while (not ((Character in ['0'..'9']) or (CacheEof(MapTxtFile)))) do begin
     CacheBlockRead(MapTxtFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
   end;

   repeat
     Num:=Num*10+(Ord(Character)-Ord('0'));
     CacheBlockRead(MapTxtFile,@Character,1);
     if (IO_Result <> 0) then Error(IO_Result,'soubor '+MapTxtFileWay);
   until ((not (Character in ['0'..'9'])) or (CacheEof(MapTxtFile)));
end;

{ ***** }
function GetKadence(Ally,ShootSpeed,UnitType:Byte):Double;
{ funkce vrati pomernou hodnotu kadence i vzhledem k typu jednotky UnitType
  a jejim PauseDelay
}
var Pom:Double;
begin
  with (GlobalModify.UnitTypes[UnitType,Ally]) do begin
    if ((ShootType1 <> 0) and (UnitType <> 29)) then begin
      Pom:=Kadence[0];
      if ((((Kadence[ShootSpeed]*(ShootType1 shl 1)+ShootDelay1) div (ShootType1 shl 1)) > 0) and
          (ShootSpeed < 10))
      { vyloucim  max. cislo kadence 10, nebot GetKadence muze vracet
        velka numera (Kadence[10]=0, delitel Pom je tedy maly); coz vede
        v procedure Change_unit_danger_class k chybe }
      then
        GetKadence:=Pom / ((Kadence[ShootSpeed] * (ShootType1 shl 1)+ShootDelay1) div (ShootType1 shl 1))
      else GetKadence:=5;
    end else
      if (UnitType = 29) then GetKadence:=10 else GetKadence:=0;
      { mutant se vyresi takto, aby vysel jako dostatecne nebezpecny cil }
  end;
end;

{ ***** }
procedure CreateMenuInfo;
{ vytvori obrazovku s informacemi
}
const PictureSize = 128;
var I, X,Y,X2,Y2,YAdd:Word;
    Konec:Boolean;
    Num:Word;
    Button,Scan,Ascii:Word;
    Index:Integer;
    Building:Boolean;
    Temp:Single;
    AverageLAttack,AverageTAttack,AverageAAttack:Single;
    AverageLAttackCount,AverageTAttackCount,AverageAAttackCount,
    AverageDefence, AverageDefenceCount:Single;
    AverageBuildingDefence, AverageBuildingDefenceCount:Single;
    Phase:BYte;

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
   CreateButton(X2,Y2,0,0,False,_Temp7); ButtonText(_Temp7,TextColor,'NaVRAT ZPdT');
   SetActive(_Temp7); Release(_Temp7);

   { VLASTNI VYPIS TEXTU }
   X:=(XResolution-XInfoSize) div 2;
   Y:=(YResolution-YInfoSize) div 2;
   Str(Index,Ret);
   if (Building) then begin
     with (Building_types[Index]) do begin
       OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+10,48,Name);
     end;
     OpenMapTxtFile(PathStr+'info\b'+Ret+'.txt');
   end else begin
     with (GlobalModify.UnitTypes[Index,1]) do begin
       OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+10,48,Name);
     end;
     OpenMapTxtFile(PathStr+'info\'+Ret+'.txt');
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
                        SoundPlay(0,0,0,0);
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
   Release(_Temp4); Release(_Temp5); Release(_Temp6);

   if (Building) then begin
   { info o budove }
     {*obrazek*}
     Str(Id,Ret);
     OutTextColor(X2-Length(Ret+'  ')*XFontSize,Y+4,66,Ret);
     Str(Index,Ret);
     Ret:=PathStr+'info\b'+Ret+'.bmp';
     OpenImage(Ret,NoCreateNew);
     if (IO_Result <> 0) then begin
       { animovane }
       for I:=0 to 11 do begin
         Str(Index,Ret2); Ret:=PathStr+'info\b'+Ret2;
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
     if (Index = 11) then Ret:='-'; { letiste }
     OutTextColor(X,Y,64,'DOHLED  :');
        OutText(X+Length('DOHLED  : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+8);
     {*cena*}
     with (Building_types[Index]) do begin
        OutTextColor(X,Y,64,'CENA:  BP     PL     EE     EXP  '); Inc(Y,4+YFontSize+1);
        Ret:='      '; Str(BP,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(PL,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(EE,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(Ex,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        OutText(X,Y,Ret); Inc(Y,4+YFontSize+1);
     end;
   end else begin
   { info o jednotce }
     {*obrazek*}
     if (not MyUnitsForMission[Index]) then Side:=0;
     Str(Id,Ret);
     OutTextColor(X2-Length(Ret+'  ')*XFontSize,Y+4,66,Ret);
     Str(Index,Ret);
     Ret:=PathStr+'info\'+Ret+'.bmp';
     OpenImage(Ret,NoCreateNew);
     if (IO_Result <> 0) then begin
       { animovane }
       for I:=0 to 11 do begin
         Str(Index,Ret2); Ret:=PathStr+'info\'+Ret2;
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
     with (GlobalModify.UnitTypes[Index,Side]) do begin
       OutTextColor(X+(XInfoSize-Length(Name)*XFontSize) shr 1,Y+8,48,Name);
     end;
     Inc(X,PictureSize+12); Inc(Y,4+YFontSize+15);
     {*sila utoku *}
     with (GlobalModify.UnitTypes[Index,Side]) do begin
       OutTextColor(X,Y,64,'SeLA hTOKU:'); Inc(Y,4+YFontSize+1);
       {}
       Temp:=LightAttack1; Temp:=Temp*GetKadence(1,ShootSpeed1,Index);{}
       Temp:=Temp/AverageLAttack; Str(Round(Temp),Ret);
       Temp:=LightAttack2; Temp:=Temp*GetKadence(1,ShootSpeed2,Index);{}
       Temp:=Temp/AverageLAttack; Str(Round(Temp),Ret2);
       if (Length(Ret) = 1) then Ret:=Ret+'    ' else Ret:=Ret+'   ';
       OutText(X,Y,' NA LEHKj CeL   :  '+Ret+Ret2); Inc(Y,4+YFontSize+1);
       {}
       Temp:=HeavyAttack1; Temp:=Temp*GetKadence(1,ShootSpeed1,Index);{}
       Temp:=Temp/AverageTAttack; Str(Round(Temp),Ret);
       Temp:=HeavyAttack2; Temp:=Temp*GetKadence(1,ShootSpeed2,Index);{}
       Temp:=Temp/AverageTAttack; Str(Round(Temp),Ret2);
       if (Length(Ret)) = 1 then Ret:=Ret+'    ' else Ret:=Ret+'   ';
       OutText(X,Y,' NA TdkKj CeL   :  '+Ret+Ret2); Inc(Y,4+YFontSize+1);
       {}
       if (Index = 18) then begin { stihac, pocitej ho jinak }
         Temp:=AirAttack1; Temp:=Temp*2.9;{}
       end else begin
         Temp:=AirAttack1; Temp:=Temp*GetKadence(1,ShootSpeed1,Index);{}
       end;
       Temp:=Temp/AverageAAttack; Str(Round(Temp),Ret);
       Temp:=AirAttack2; Temp:=Temp*GetKadence(1,ShootSpeed2,Index);{}
       Temp:=Temp/AverageAAttack; Str(Round(Temp),Ret2);
       if (Length(Ret)) = 1 then Ret:=Ret+'    ' else Ret:=Ret+'   ';
       OutText(X,Y,' NA VZDUgNj CeL :  '+Ret+Ret2); Inc(Y,4+YFontSize+1);
     end;
     {*dostrel*}
     Ret:='';
     Pom1:=Hi(GlobalModify.UnitTypes[Index,Side].ShootRange1); Pom2:=Lo(GlobalModify.UnitTypes[Index,Side].ShootRange1);
     if (Pom1 > 0) then begin
        Str(Pom1,Ret2); Ret:=Ret+Ret2+'-'; Str(Pom2,Ret2); Ret:=Ret+Ret2+'  ';
     end;
     Pom1:=Hi(GlobalModify.UnitTypes[Index,Side].ShootRange2); Pom2:=Lo(GlobalModify.UnitTypes[Index,Side].ShootRange2);
     if (Pom1 > 0) then begin
        Str(Pom1,Ret2); Ret:=Ret+Ret2+'-'; Str(Pom2,Ret2); Ret:=Ret+Ret2;
     end;
     OutTextColor(X,Y,64,'DOSTfEL :');
        OutText(X+Length('DOSTfEL         : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+1);
     {*typ obrany *}
     with (GlobalModify.UnitTypes[Index,Side]) do begin
       if (TargetTyp < 2) then Ret:='LEHKj'
       else
         if (TargetTyp = 2) then Ret:='TdkKj'
         else
           if (TargetTyp = 3) then Ret:='VZDUgNj'
           else Ret:='NaMOfNe';
     end;
     OutTextColor(X,Y,64,'TYP     :');
        OutText(X+Length('TYP     : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+1);
     {*sila obrany *}
     with (GlobalModify.UnitTypes[Index,Side]) do begin
       Temp:=DefenceStrength;Temp:=Temp/AverageDefence;
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
     Inc(Y,4+YFontSize+1);
     {*dohled*}
     Str(GlobalModify.UnitTypes[Index,Side].Sight,Ret);
     OutTextColor(X,Y,64,'DOHLED  :');
        OutText(X+Length('DOHLED  : ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+1);
     {*rychlost pohybu*}
     with (GlobalModify.UnitTypes[Index,Side]) do begin
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
       7 : Ret:='8';
     else
       Ret:='STATICKa';
     end;
     OutTextColor(X,Y,64,'RYCHLOST:');
        OutText(X+Length('RYCHLOST: ')*XFontSize,Y,Ret);
     Inc(Y,4+YFontSize+1);
     {*cena*}
     with (GlobalModify.UnitTypes[Index,Side]) do begin
        OutTextColor(X,Y,64,'CENA:  BP     PL     EE     EXP  '); Inc(Y,2+YFontSize);
        Ret:='      '; Str(BP,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(PL,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(EE,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        Ret:=Ret+'    '; Str(Ex,Ret2);
        case (Length(Ret2)) of 1 : Ret:=Ret+'  '; 2 : Ret:=Ret+' '; end; Ret:=Ret+Ret2;
        OutText(X,Y,Ret); Inc(Y,2+YFontSize+1);
     end;
     with (GlobalModify.UnitTypes[Index,Side]) do begin
        {*specialni vlastnosti*}
        Y:=(YResolution-YInfoSize) shr 1 + 45 + PictureSize+SmallButtonYSize+6;
        if (cAPACITY > 0) then begin
          OutTextColor(X-PictureSize-6,Y,48,'-LZE NALOkIT'); Inc(Y,YFontSize+1);
        end;
        if ((SpecAirLevel = 0) and (TargetTyp = 3)) then begin
          OutTextColor(X-PictureSize-6,Y,48,'-kaDa LETIgTd'); Inc(Y,YFontSize+1);
        end;
        if (GuidedMissile) then begin
          OutTextColor(X-PictureSize-6,Y,48,'-NAVaDdNc RAKETY'); Inc(Y,YFontSize+1);
        end;
        if (Index = 29) then begin { mutant }
          OutTextColor(X-PictureSize-6,Y,48,'-SNIkUJE MORaLKU'); Inc(Y,YFontSize+1);
        end;
        if ((Index = 15) or (Index = 39)) then begin { likvidator, commandos }
          OutTextColor(X-PictureSize-6,Y,48,'-ELITNe SeLY'); Inc(Y,YFontSize+1);
        end;
        if ((Index = 9) or (Index = 7)) then begin { vysadkar, vysadkovy tank  }
          OutTextColor(X-PictureSize-6,Y,48,'-VZDUgNc VjSADKY'); Inc(Y,YFontSize+1);
        end;
        if (Index = 23) then begin { autodetonator }
          OutTextColor(X-PictureSize-6,Y,48,'-SEBEVRAkEDNj'); Inc(Y,YFontSize+1);
          OutTextColor(X-PictureSize-6,Y,48,'-PROTI BUDOVaM'); Inc(Y,YFontSize+1);
        end;
        if ((Index = 18) or (Index = 19)) then begin { stihac, terminator }
          OutTextColor(X-PictureSize-6,Y,48,'-JEDEN VjSTfEL'); Inc(Y,YFontSize+1);
        end;
     end;
   end;
   CursorOn;
end;

{ xxx }
begin
   { ziskani statistickych informaci: }
   BuildInfoRecord;
   TempGM:=GlobalModify; Kdce:=Kadence;
   SetGlobalModif;
   SetActionLevel(GlobalModify.ActionLevel);
{   AverageLAttack:=0; AverageTAttack:=0; AverageAAttack:=0;
   AverageLAttackCount:=0; AverageTAttackCount:=0; AverageAAttackCount:=0;
   AverageDefence:=0; AverageDefenceCount:=0;
   AverageBuildingDefence:=0; AverageBuildingDefenceCount:=0;
   for I:=1 to MaxTypesOfUnits do with (Unit_types^[I,1]) do begin
     if (LightAttack1 > 0) then begin
        Temp:=LightAttack1; Temp:=Temp*GetKadence(1,ShootSpeed1,I);
        AverageLAttack:=AverageLAttack+Temp;
        AverageLAttackCount:=AverageLAttackCount+1;
     end;
     if (LightAttack2 > 0) then begin
        Temp:=LightAttack2; Temp:=Temp*GetKadence(1,ShootSpeed2,I);
        AverageLAttack:=AverageLAttack+Temp;
        AverageLAttackCount:=AverageLAttackCount+1;
     end;
     {}
{     if (HeavyAttack1 > 0) then begin
        Temp:=HeavyAttack1; Temp:=Temp*GetKadence(1,ShootSpeed1,I);
        AverageTAttack:=AverageTAttack+Temp;
        AverageTAttackCount:=AverageTAttackCount+1;
     end;
     if (HeavyAttack2 > 0) then begin
        Temp:=HeavyAttack2; Temp:=Temp*GetKadence(1,ShootSpeed2,I);
        AverageTAttack:=AverageTAttack+Temp;
        AverageTAttackCount:=AverageTAttackCount+1;
     end;
     {}
{     if (AirAttack1 > 0) then begin
        Temp:=AirAttack1; Temp:=Temp*GetKadence(1,ShootSpeed1,I);
        AverageAAttack:=AverageAAttack+Temp;
        AverageAAttackCount:=AverageAAttackCount+1;
     end;
     if (AirAttack2 > 0) then begin
        Temp:=AirAttack2; Temp:=Temp*GetKadence(1,ShootSpeed2,I);
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
   AverageBuildingDefence:=(AverageBuildingDefence/AverageBuildingDefenceCount)/5;{}
   AverageLAttack:=100;
   AverageTAttack:=90;
   AverageAAttack:=50;
   AverageDefence:=205;
   AverageBuildingDefence:=740;

   X:=(XResolution-XWindow1Size) shr 1; Y:=(YResolution-YWindow1Size) shr 1;

   X:=(XResolution-XInfoSize) div 2; X2:=X+XInfoSize-1;
   Y:=(YResolution-YInfoSize) div 2; Y2:=Y+YInfoSize-1;
   ShowInfoPanel(X,Y,X2,Y2,0);
   CursorOff;
   GetImage(X,Y,X2,Y2,TempSeg2,TempOfs2,NormalDirect);
   CursorOn;

   X:=(XResolution-XInfoSize) shr 1 + (PictureSize-SmallButtonXSize) shr 1;
   Y:=(YResolution-YInfoSize) shr 1 + 40 + PictureSize;
   CreateButton(X,Y,1,0,False,_Temp5); ButtonText(_Temp5,TextColor,'TEXT');
   {}
   X:=(XResolution-XInfoSize) shr 1; Y:=(YResolution-YInfoSize) shr 1;
   Y:=Y+YInfoSize-2*SmallButtonYSize;
   X2:=(XInfoSize-5*SmallButtonXSize) div 6;
   Inc(X,X2);
   CreateButton(X,Y,1,0,False,_Temp1); ButtonText(_Temp1,TextColor,'<<');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp2); ButtonText(_Temp2,TextColor,'<');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp6); ButtonText(_Temp6,TextColor,'ZPdT');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp3); ButtonText(_Temp3,TextColor,'>');
   Inc(X,X2); Inc(X,SmallButtonXSize);
   CreateButton(X,Y,1,0,False,_Temp4); ButtonText(_Temp4,TextColor,'>>');

   Release(_Temp1); Release(_Temp2); Release(_Temp3);
   Release(_Temp4); Release(_Temp5); Release(_Temp6);
   SetActive(_Temp1); SetActive(_Temp2); SetActive(_Temp3);
   SetActive(_Temp4); SetActive(_Temp5); SetActive(_Temp6);
   { ** vlastni prace s informacnim panelem ** }
   Building:=False; Index:=1;
   if (Building) then
     DrawInfo(BuildingsInfoRecord.Rec[Index],Index,1,Building)
    else
     DrawInfo(UnitsInfoRecord.Rec[Index],Index,1,Building);

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
                         SoundPlay(0,0,0,0);
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
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,1,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,1,Building);
                      end;
         _Temp2     : begin  { 1 krok dozadu }
                         SoundPlay(0,0,0,0);
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
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,1,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,1,Building);
                      end;
         _Temp3     : begin  { 1 krok dopredu }
                         SoundPlay(0,0,0,0);
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
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,1,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,1,Building);
                      end;
         _Temp4     : begin  { rychle pretoceni dopredu }
                         SoundPlay(0,0,0,0);
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
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,1,Building)
                         else
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,1,Building);
                      end;
         _Temp5     : begin  { vytisknuti textu o objektu }
                         SoundPlay(0,0,0,0);
                         if (Building) then begin
                           DrawText(BuildingsInfoRecord.Rec[Index],Building);
                           DrawInfo(BuildingsInfoRecord.Rec[Index],Index,1,Building);
                         end else begin
                           DrawText(UnitsInfoRecord.Rec[Index],Building);
                           DrawInfo(UnitsInfoRecord.Rec[Index],Index,1,Building);
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
   GlobalModify:=TempGM;
   Kadence:=Kdce;
end;

{ ***** }
procedure DrawPoints;
{ vytiskne aktualni stav "bodu"
}
var Ret:String;
    X,Y:Word;
    Mous:Boolean;
begin
   Mous:=TestMouse(X1Points,Y1Points,X2PointsInfo,Y1Points+32);
   if (Mous) then CursorOff;

   SpeedPutImage(X1Points, Y1Points,PointsSeg, PointsOfs);
   SpeedPutImage(X1PointsInfo+1,Y1PointsInfo+1,PointsBckSeg,PointsBckOfs);
   Str(Round(Points),Ret);
   X:=X1PointsInfo+(X2PointsInfo-X1PointsInfo-Length(Ret)*XFontSize) shr 1;
   Y:=Y1PointsInfo+(Y2PointsInfo-Y1PointsInfo-YFontSize) shr 1;
   OutTextColor(X+1,Y+1,75,Ret);
   OutTextColor(X,Y,64,Ret);

   if (Mous) then CursorOn;
end;

{ ***** }
procedure DrawVictoryPoints;
{ vytiskne aktualni stav "viteznych bodu"
}
var Ret:String;
    X,Y:Word;
    Mous:Boolean;
begin
   Mous:=TestMouse(X1VictoryPoints,Y1VictoryPoints,X2VictoryPointsInfo,Y1VictoryPoints+32);
   if (Mous) then CursorOff;
   SpeedPutImage(X1VictoryPoints, Y1VictoryPoints,VictoryPointsSeg, VictoryPointsOfs);
   SpeedPutImage(X1VictoryPointsInfo+1,Y1VictoryPointsInfo+1,
                 VictoryPointsBckSeg,VictoryPointsBckOfs);
   Str(Round(VictoryPoints),Ret);
   X:=X1VictoryPointsInfo+(X2VictoryPointsInfo-X1VictoryPointsInfo-Length(Ret)*XFontSize) shr 1;
   Y:=Y1VictoryPointsInfo+(Y2VictoryPointsInfo-Y1VictoryPointsInfo-YFontSize) shr 1;
   OutTextColor(X+1,Y+1,75,Ret);
   OutTextColor(X,Y,64,Ret);

   if (Mous) then CursorOn;
end;

{ ***** }
function DialogBox(Msg:String; DlgType:Byte):Byte;
{ vypise dialogovy box se zpravou Msg; muze byt nekolika typu:
  _YES, _YES_NO, _YES_NO_CANCEL a vraci kod stisknuteho tlacitka:
  YES - tlacitko Ano
  NO  - tlacitko Ne
  CANCEL  - tlacitko Storno
}
const XSpace = 35;
var X,Y,I,XLen,YLen:Word;
    Num, Button, Scan, Ascii:Word;
    Konec:Boolean;
begin
   XLen:=Length(Msg)*XFontSize;
   YLen:=YFontSize+SmallButtonYSize+4*YFontSize;

   case (DlgType) of
     _YES           : begin
                        if (XLen < SmallButtonXSize) then XLen:=SmallButtonXSize;
                        XLen:=XLen+2*SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-SmallButtonXSize) shr 1,Y+3*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                      end;
     _YES_NO        : begin
                        if (XLen < 2*SmallButtonXSize) then XLen:=2*SmallButtonXSize;
                        XLen:=XLen+2*SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1,Y+3*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+3*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                      end;
     _YES_NO_CANCEL : begin
                        if (XLen < 3*SmallButtonXSize) then XLen:=3*SmallButtonXSize;
                        XLen:=XLen+2*SmallButtonXSize;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;

                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1,Y+3*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+3*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+2*SmallButtonXSize+2*XSpace,
                                     Y+3*YFontSize,1,0,False,_Temp10);
                        ButtonText(_Temp10,TextColor,'ZRUg');
                      end;
   end;

   CursorOff;
   ShowInfoPanel(X,Y,X+XLen-1,Y+YLen,1);
   CursorOff;
   OutTextColor(X+(XLen-Length(Msg)*XFontSize) shr 1,Y+YFontSize,66,Msg);
   case (DlgType) of
     _YES           : begin
                        SetActive(_Temp8); Release(_Temp8);
                      end;
     _YES_NO        : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                      end;
     _YES_NO_CANCEL : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                        SetActive(_Temp10); Release(_Temp10);
                      end;
   end;
   ScreenOn; CursorOn;

   { ZPRACOVANI }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0         : if ((Scan = $01) and (DlgType = _YES_NO_CANCEL))
                     then begin
                        SoundPlay(0,0,0,0);
                        DialogBox:=Cancel;
                        Konec:=True; { Esc }
                     end;
        _Temp8     : begin  { OK }
                        SoundPlay(0,0,0,0);
                        DialogBox:=YES;
                        Konec:=True;
                     end;
        _Temp9     : begin  { NO }
                        SoundPlay(0,0,0,0);
                        DialogBox:=No;
                        Konec:=True;
                     end;
        _Temp10     : begin  { CANCEL }
                        SoundPlay(0,0,0,0);
                        DialogBox:=Cancel;
                        Konec:=True;
                     end;
      end;
   end;

   ScreenOff; CursorOff;
   case (DlgType) of
     _YES           : begin
                        DeleteButton(_Temp8,256);
                      end;
     _YES_NO        : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                      end;
     _YES_NO_CANCEL : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                        DeleteButton(_Temp10,256);
                      end;
   end;
   CloseInfoPanel;
   ScreenOn; CursorOn;
   Delay(250);
end;

{ ***** }
function WideDialogBox(Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
{ vypise dialogovy box se zpravou Msg; muze byt nekolika typu:
  _YES, _YES_NO, _YES_NO_CANCEL a vraci kod stisknuteho tlacitka:
  YES - tlacitko Ano
  NO  - tlacitko Ne
  CANCEL  - tlacitko Storno
  (pro 3 samostatne retezce)
}
const XSpace = 40;
var X,Y,I,XLen,YLen:Word;
    Num, Button, Scan, Ascii:Word;
    Konec:Boolean;
begin
   XLen:=Length(Msg)*XFontSize;
   YLen:=3*YFontSize+SmallButtonYSize+3*YFontSize;

   case (DlgType) of
     _YES           : begin
                        if (XLen < SmallButtonXSize) then XLen:=SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;{}
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-SmallButtonXSize) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                      end;
     _YES_NO        : begin
                        if (XLen < 2*SmallButtonXSize) then XLen:=2*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;{}
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                      end;
     _YES_NO_CANCEL : begin
                        if (XLen < 3*SmallButtonXSize) then XLen:=3*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;{+2*XSpace;{}
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;

                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+2*SmallButtonXSize+2*XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp10);
                        ButtonText(_Temp10,TextColor,'ZRUg');
                      end;
   end;

   CursorOff;
   ShowInfoPanel2(X,Y,X+XLen-1,Y+YLen,1);
   CursorOff;
   OutTextColor(X+(XLen-Length(Msg)*XFontSize) shr 1,Y+YFontSize,98,Msg);
   OutTextColor(X+(XLen-Length(Msg1)*XFontSize) shr 1,Y+2*YFontSize,66,Msg1);
   OutTextColor(X+(XLen-Length(Msg2)*XFontSize) shr 1,Y+3*YFontSize,66,Msg2);
   case (DlgType) of
     _YES           : begin
                        SetActive(_Temp8); Release(_Temp8);
                      end;
     _YES_NO        : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                      end;
     _YES_NO_CANCEL : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                        SetActive(_Temp10); Release(_Temp10);
                      end;
   end;
   CursorOn;

   { ZPRACOVANI }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0         : if ((Scan = $01) and (DlgType = _YES_NO_CANCEL))
                     then begin
                        SoundPlay(0,0,0,0);
                        WideDialogBox:=Cancel;
                        Konec:=True; { Esc }
                     end;
        _Temp8     : begin  { OK }
                        SoundPlay(0,0,0,0);
                        WideDialogBox:=YES;
                        Konec:=True;
                     end;
        _Temp9     : begin  { NO }
                        SoundPlay(0,0,0,0);
                        WideDialogBox:=No;
                        Konec:=True;
                     end;
        _Temp10     : begin  { CANCEL }
                        SoundPlay(0,0,0,0);
                        WideDialogBox:=Cancel;
                        Konec:=True;
                     end;
      end;
   end;

   CursorOff;
   case (DlgType) of
     _YES           : begin
                        DeleteButton(_Temp8,256);
                      end;
     _YES_NO        : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                      end;
     _YES_NO_CANCEL : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                        DeleteButton(_Temp10,256);
                      end;
   end;
   CloseInfoPanel;
   CursorOn;
   Delay(250);
end;

{ ***** }
function WideDialogBoxX(Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
{ vypise dialogovy box se zpravou Msg; muze byt nekolika typu:
  _YES, _YES_NO, _YES_NO_CANCEL a vraci kod stisknuteho tlacitka:
  YES - tlacitko Ano
  NO  - tlacitko Ne
  CANCEL  - tlacitko Storno
  (pro 3 samostatne retezce)
}
const XSpace = 40;
var X,Y,I,XLen,YLen:Word;
    Num, Button, Scan, Ascii:Word;
    Konec:Boolean;
begin
   XLen:=Length(Msg)*XFontSize;
   YLen:=3*YFontSize+SmallButtonYSize+3*YFontSize;

   case (DlgType) of
     _YES           : begin
                        if (XLen < SmallButtonXSize) then XLen:=SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;{}
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-SmallButtonXSize) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                      end;
     _YES_NO        : begin
                        if (XLen < 2*SmallButtonXSize) then XLen:=2*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;{}
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                      end;
     _YES_NO_CANCEL : begin
                        if (XLen < 3*SmallButtonXSize) then XLen:=3*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize;{+2*XSpace;{}
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;

                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+2*SmallButtonXSize+2*XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp10);
                        ButtonText(_Temp10,TextColor,'ZRUg');
                      end;
   end;

   CursorOff;
   ShowInfoPanel2(X,Y,X+XLen-1,Y+YLen,1);
   CursorOff;
   OutTextColor(X+(XLen-Length(Msg)*XFontSize) shr 1,Y+YFontSize,66,Msg);
   OutTextColor(X+(XLen-Length(Msg1)*XFontSize) shr 1,Y+2*YFontSize,66,Msg1);
   OutTextColor(X+(XLen-Length(Msg2)*XFontSize) shr 1,Y+3*YFontSize,66,Msg2);
   case (DlgType) of
     _YES           : begin
                        SetActive(_Temp8); Release(_Temp8);
                      end;
     _YES_NO        : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                      end;
     _YES_NO_CANCEL : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                        SetActive(_Temp10); Release(_Temp10);
                      end;
   end;
   CursorOn;

   { ZPRACOVANI }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0         : if ((Scan = $01) and (DlgType = _YES_NO_CANCEL))
                     then begin
                        SoundPlay(0,0,0,0);
                        WideDialogBoxX:=Cancel;
                        Konec:=True; { Esc }
                     end;
        _Temp8     : begin  { OK }
                        SoundPlay(0,0,0,0);
                        WideDialogBoxX:=YES;
                        Konec:=True;
                     end;
        _Temp9     : begin  { NO }
                        SoundPlay(0,0,0,0);
                        WideDialogBoxX:=No;
                        Konec:=True;
                     end;
        _Temp10     : begin  { CANCEL }
                        SoundPlay(0,0,0,0);
                        WideDialogBoxX:=Cancel;
                        Konec:=True;
                     end;
      end;
   end;

   CursorOff;
   case (DlgType) of
     _YES           : begin
                        DeleteButton(_Temp8,256);
                      end;
     _YES_NO        : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                      end;
     _YES_NO_CANCEL : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                        DeleteButton(_Temp10,256);
                      end;
   end;
   CloseInfoPanel;
   CursorOn;
   Delay(250);
end;

{ ***** }
function SpecWideDialogBox(UnitType:Word; Msg,Msg1,Msg2:String; DlgType:Byte):Byte;
{ vypise dialogovy box se zpravou Msg a zobrazi obrazek jednotky;
  muze byt nekolika typu:
  _YES, _YES_NO, _YES_NO_CANCEL a vraci kod stisknuteho tlacitka:
  YES - tlacitko Ano
  NO  - tlacitko Ne
  CANCEL  - tlacitko Storno
  (pro 3 samostatne retezce)
}
const XSpace = 40;
var X,Y,I,XLen,YLen:Word;
    Num, Button, Scan, Ascii:Word;
    Konec:Boolean;
begin
   XLen:=Length(Msg)*XFontSize;
   YLen:=3*YFontSize+SmallButtonYSize+3*YFontSize;

   case (DlgType) of
     _YES           : begin
                        if (XLen < SmallButtonXSize) then XLen:=SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize+48;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-SmallButtonXSize) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                      end;
     _YES_NO        : begin
                        if (XLen < 2*SmallButtonXSize) then XLen:=2*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize+XSpace+48;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-2*SmallButtonXSize-XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                      end;
     _YES_NO_CANCEL : begin
                        if (XLen < 3*SmallButtonXSize) then XLen:=3*SmallButtonXSize;
                        XLen:=XLen+SmallButtonXSize+2*XSpace+48;
                        if (XLen mod 4 <> 0) then XLen:=((XLen+4) div 4)*4;
                        X:=(XResolution-XLen) shr 1;
                        Y:=(YResolution-YLen) shr 1;

                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1,Y+5*YFontSize,1,0,False,_Temp8);
                        ButtonText(_Temp8,TextColor,'ANO');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+SmallButtonXSize+XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp9);
                        ButtonText(_Temp9,TextColor,'NE');
                        CreateButton(X+(XLen-3*SmallButtonXSize-2*XSpace) shr 1+2*SmallButtonXSize+2*XSpace,
                                     Y+5*YFontSize,1,0,False,_Temp10);
                        ButtonText(_Temp10,TextColor,'ZRUg');
                      end;
   end;

   CursorOff;
   ShowInfoPanel2(X,Y,X+XLen-1,Y+YLen,1);
   CursorOff;
   Frame2(X+10,Y+(YLen-38) shr 1,X+10+38,Y+(YLen-38) shr 1+38,72);
   SpecSpeedPutImage3(X+10+1,Y+(YLen-38) shr 1+1,
                      Unit_pictures[UnitType].S,Unit_pictures[UnitType].O,
                      0,0,37,37,176);
   OutTextColor(X+(XLen-Length(Msg)*XFontSize) shr 1,Y+YFontSize,98,Msg);
   OutTextColor(X+(XLen-Length(Msg1)*XFontSize) shr 1,Y+2*YFontSize,66,Msg1);
   OutTextColor(X+(XLen-Length(Msg2)*XFontSize) shr 1,Y+3*YFontSize,66,Msg2);
   case (DlgType) of
     _YES           : begin
                        SetActive(_Temp8); Release(_Temp8);
                      end;
     _YES_NO        : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                      end;
     _YES_NO_CANCEL : begin
                        SetActive(_Temp8); Release(_Temp8);
                        SetActive(_Temp9); Release(_Temp9);
                        SetActive(_Temp10); Release(_Temp10);
                      end;
   end;
   CursorOn;

   { ZPRACOVANI }
   Konec:=False;
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0         : if ((Scan = $01) and (DlgType = _YES_NO_CANCEL))
                     then begin
                        SoundPlay(0,0,0,0);
                        SpecWideDialogBox:=Cancel;
                        Konec:=True; { Esc }
                     end;
        _Temp8     : begin  { OK }
                        SoundPlay(0,0,0,0);
                        SpecWideDialogBox:=YES;
                        Konec:=True;
                     end;
        _Temp9     : begin  { NO }
                        SoundPlay(0,0,0,0);
                        SpecWideDialogBox:=No;
                        Konec:=True;
                     end;
        _Temp10     : begin  { CANCEL }
                        SoundPlay(0,0,0,0);
                        SpecWideDialogBox:=Cancel;
                        Konec:=True;
                     end;
      end;
   end;

   CursorOff;
   case (DlgType) of
     _YES           : begin
                        DeleteButton(_Temp8,256);
                      end;
     _YES_NO        : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                      end;
     _YES_NO_CANCEL : begin
                        DeleteButton(_Temp8,256);
                        DeleteButton(_Temp9,256);
                        DeleteButton(_Temp10,256);
                      end;
   end;
   CloseInfoPanel;
   CursorOn;
   Delay(250);
end;

{ ***** }
function SelectSinglMission(var MissionNumber:Word):Boolean;
{ osetri konkretni nabidku mise
}
var Ret, Ret1:String;
    I,J,Limit:Word;
    MissionsList : array [0..100] of record
                      MNum:Word;
                      Name:String[40];
                      X1,Y1,X2,Y2:Word;
                   end;
    MaxIndex:Integer;
    PomFile:File;
    Num,X,Y,Button,Scan,Ascii:Word;
    Konec:Boolean;
    Selected, PomSelected:Byte;

procedure Select(Index:Byte);
{
}
begin
  CursorOff;
  with (MissionsList[Index]) do begin
    if (Selected <> 255) then with (MissionsList[Selected]) do begin
      OutTextColor(X1+1,Y1+4+1,DarkBlue,Name);
      OutTextColor(X1,Y1+4,Blue,Name);
    end;
    Selected:=Index;
    OutTextColor(X1+1,Y1+4+1,DarkYellow,Name);
    OutTextColor(X1,Y1+4,Yellow,Name);
  end;
  CursorOn;
end;

{ *}
begin
   MaxIndex:=-1; SelectSinglMission:=True; MissionNumber:=100;
   for I:=100 to 200 do begin
      Str(I,Ret1);
      Assign(PomFile,PathStr+'missions\mapa'+Ret1+'.inf');
      Reset(PomFile,1); J:=IOResult; Close(PomFile); IO_Result:=IOResult;
      if (J  = 0) then begin
         OpenMapTxtFile(PathStr+'missions\mapa'+Ret1+'.inf');
         ReadTxtString(Ret1); ReadTxtString(Ret1); { prvni a druhy radek je komentar }
         ReadTxtWord(J); ReadTxtWord(J);
         Inc(MaxIndex);
         ReadTxtString(MissionsList[MaxIndex].Name);
         with (MissionsList[MaxIndex]) do begin
           MNum:=I;
           X1:=20; Y1:=10+MaxIndex*(YFontSize+8)-4;
           Limit:=(YResolution-BigButtonYSize*3-10) div (YFontSize+8);
           if (MaxIndex > Limit) then begin
              X1:=20+40*XFontSize; Y1:=10+I*((MaxIndex-Limit-1)*(YFontSize+8))-4;
           end;
           X2:=X1+36*XFontSize; Y2:=Y1+YFontSize+8;
         end;
      end;
   end;
   for I:=0 to MaxIndex do with (MissionsList[I]) do begin
     OutTextColor(X1+1,Y1+4+1,DarkBlue,Name);
     OutTextColor(X1,Y1+4,Blue,Name);
   end;

   { VYTVORENI TLACITEK }
   Y:=YResolution-BigButtonYSize shl 1;
   X:=(XResolution-(BigButtonXSize shl 1+100)) shr 1;
   CursorOff;
   CreateButton(X,Y,0,0,False,_Temp1);
   ButtonText(_Temp1,TextColor,'OK');
   Inc(X,BigButtonXSize+100);
   CreateButton(X,Y,0,0,False,_Temp2);
   ButtonText(_Temp2,TextColor,'ZPdT');
   Release(_Temp1); SetActive(_Temp1);
   Release(_Temp2); SetActive(_Temp2);
   CursorOn;
   Konec:=False; Selected:=255; Select(0);
   while not (Konec) do begin
      Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
      case Num of
         0          : if (Scan = 0) then begin { pouze mys }
                        for I:=0 to MaxIndex do with (MissionsList[I]) do begin
                           if ((X >= X1) and (X <= X2) and (Y>=Y1) and (Y <=Y2))
                           then Select(I);
                        end;
                      end;
         _Temp1     : begin { OK }
                        SoundPlay(0,0,0,0);
                        SelectSinglMission:=True;
                        MissionNumber:=MissionsList[Selected].MNum;
                        Konec:=True;
                      end;
         _Temp2     : begin { Escape }
                       SoundPlay(0,0,0,0);
                       SelectSinglMission:=False;
                       Konec:=True;
                     end;
      end;
   end;
   CursorOff; DeleteButton(_Temp1,256); DeleteButton(_Temp2,256);
   CursorOn;
end;

{ ***** }
function SelectSingleMission:Boolean;
{ zvoli si single misi; vraci false, pokud byl vyber prerusen
}
var I,J:Integer;
    MissionNum,Num:Word;
    PomStr, Str1, Str2, Str3:String;
    Return:Boolean;
    Pom:Byte;
    TempValue:Integer;
    ITextSize, JTextSize:Integer;
    X,Y, XSize, YSize:Word;
    KOnec:Boolean;
    Button,Scan,Ascii:Word;
    MissionText:array[0..MaxAnimTextRows] of String[80]; { text }
    MaxIndex:Word; { PRVNI NEPOUZITA POLOZKA }
begin
  CursorOff;
  Pom:=Random(6)+1;{}{ Pom:=Random(2)+5;{}
  Str(Pom,PomStr);
  ClearScreen;
  OpenImage(PathStrGlobal+'data\obr'+PomStr+'.bmp',NoCreateNew);
  GetXYImageCoordinatesBMP(XSize,YSize);
  LoadImageBMP(SScreen,OScreen,NoRGB);
  LoadRGB(0,PathStrGlobal+'data\paleta1'+PomStr+'.rgb');
  if (IO_Result = 0) then
    PutImage((XResolution-XSize) shr 1,(YResolution-YSize) shr 1,SScreen,OScreen,ReverseDirect);
  InvalidateCache;
  OpenImage(PathStrGlobal+'data\buttons.glb',NoCreateNew);
  LoadImageGBM(On1Seg,On1Offs,'on1_'+PomStr,0);
  LoadImageGBM(Off1Seg,Off1Offs,'off1_'+PomStr,0);
  {X}
  OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
  LoadImageGBM(CursorSegment,CursorOffsets,'normal'+PomStr,0);
  {X}
  InvalidateCache;
  case (Pom) of
    1: begin Blue:=149; DarkBlue:=207; Yellow:=136; DarkYellow:=122; White:=5; end;
    2: begin Blue:=210; DarkBlue:=251; Yellow:=207; DarkYellow:=197; White:=6; end;
    3: begin Blue:=242; DarkBlue:=249; Yellow:=218; DarkYellow:=185; White:=12;end;
    4: begin Blue:=160; DarkBlue:=168; Yellow:=136; DarkYellow:=123; White:=11;end;
    5: begin Blue:=224; DarkBlue:=244; Yellow:=181; DarkYellow:=155; White:=12;end;
    6: begin Blue:=166; DarkBlue:=234; Yellow:=153; DarkYellow:=144; White:=8;end;
  end;
  CursorOn;

  if (SelectSinglMission(MissionNum)) then begin
  { volba se povedla }
      CursorOff;
      ClearScreen;
      PutImage((XResolution-XSize) shr 1,(YResolution-YSize) shr 1,SScreen,OScreen,ReverseDirect);
      Str(MissionNum, Str1);
      OpenMapTxtFile(PathStr+'missions\mapa'+Str1+'.inf');
      ReadTxtString(Str1); ReadTxtString(Str1); { prvni a druhy radek je komentar }
      { nasleduji 2 wordy velikosti}
      ReadTxtWord(Word(ITextSize)); ReadTxtWord(Word(JTextSize)); Dec(JTextSize,1);{}
      ReadTxtString(Str1); I:=0; { vynechame nadpis }
      while ReadTxtString(MissionText[I]) do begin
        Inc(I);
      end;{}
      MaxIndex:=I;
      {x}
      if ((MaxIndex > 0) and (JTextSize > 0)) then begin
         Y:=(YResolution-JTextSize*YFontSize) shr 1+16;
         X:=(XResolution-ITextSize*XFontSize) shr 1;
         for I:=0 to MaxIndex-1 do begin
            OutTextColor(X+1,Y+1,DarkBlue,MissionText[I]);
            OutTextColor(X,Y,Blue,MissionText[I]);
            Inc(Y,YFontSize);
         end;
      end;

      { VYTVORENI TLACITEK }
      Y:=YResolution-BigButtonYSize shl 1;
      X:=(XResolution-BigButtonXSize) shr 1;
      CreateButton(X,Y,0,0,False,_Temp1);
      ButtonText(_Temp1,TextColor,'START MISE');
      Release(_Temp1); SetActive(_Temp1); CursorOn;
      Konec:=False;
      while not (Konec) do begin
         Num:=MousKeybClick(X,Y,Button,Scan,Ascii);
         case Num of
            _Temp1     : begin { mise a) }
                           SoundPlay(0,0,0,0);
                           Konec:=True;
                         end;
         end;
      end;
      CursorOff; DeleteButton(_Temp1,256);  CursorOn;
      Game:=MissionNum;
      SelectSingleMission:=True;
  end else begin
      SelectSingleMission:=False;
      ClearScreen;
      LoadRGB(0,PathStrGlobal+'data\paleta1.rgb');
      Blue:=98; DarkBlue:=108; Yellow:=160; DarkYellow:=165; White:=66;
      InvalidateCache;
      OpenImage(PathStrGlobal+'data\buttons.glb',NoCreateNew);
      LoadImageGBM(On1Seg,On1Offs,'on1',0);
      LoadImageGBM(Off1Seg,Off1Offs,'off1',0);
      {X}
      OpenImage(PathStrGlobal+'data\cursors.glb',NoCreateNew);
      LoadImageGBM(CursorSegment,CursorOffsets,'normal',0);
      {X}
      CursorOn;
  end;
end;

{ ***** }
procedure Init1;
const X = 5.0;
var I, J:Integer;
begin
   I:=1;
   with Unit_types^[I,0] do begin { 1 - NAKLADNI AUTOMOBIL }
      Name := 'NaKLADNe AUTO'; Production_time:=X/15;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=8; { zabira misto } Capacity:=8;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=6; FlashPos[2].X:=10;FlashPos[2].Y:=2;
      FlashPos[3].X:=18;FlashPos[3].Y:=0; FlashPos[4].X:=26;FlashPos[4].Y:=6;
      FlashPos[5].X:=28;FlashPos[5].Y:=16; FlashPos[6].X:=22;FlashPos[6].Y:=24;
      FlashPos[7].X:=12;FlashPos[7].Y:=24; FlashPos[8].X:=6;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 2 - ODPADKOVY HARVESTER }
      Name:= 'RECYKLaTOR';  Production_time:=X/25;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 3 - CIVILISTA }
      Name:= 'CIVILISTA'; Production_time:=X/10;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=40; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=1; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 4 - OSOBNI AUTOMOBIL }
      Name:= 'OSOBNe AUTO';  Production_time:=X/15;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=4; { zabira misto } Capacity:=2;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 5 - SAMOPALNIK }
      Name:= 'PdCHOTA';  Production_time:=X/20;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=15; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=513;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=9;FlashPos[1].Y:=0; FlashPos[2].X:=18;FlashPos[2].Y:=0;
      FlashPos[3].X:=24;FlashPos[3].Y:=6; FlashPos[4].X:=25;FlashPos[4].Y:=15;
      FlashPos[5].X:=18;FlashPos[5].Y:=21; FlashPos[6].X:=7;FlashPos[6].Y:=21;
      FlashPos[7].X:=1;FlashPos[7].Y:=14; FlashPos[8].X:=3;FlashPos[8].Y:=6;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 6 - TANKOBORNIK }
      Name:= 'TdkKa PdCHOTA';  Production_time:=X/21;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=10; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 7 - VYSADKAR }
      Name:= 'VjSADKaf';  Production_time:=X/25;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=12; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=20; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=770;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=6;FlashPos[1].Y:=0; FlashPos[2].X:=14;FlashPos[2].Y:=0;
      FlashPos[3].X:=21;FlashPos[3].Y:=0; FlashPos[4].X:=26;FlashPos[4].Y:=8;
      FlashPos[5].X:=20;FlashPos[5].Y:=16; FlashPos[6].X:=13;FlashPos[6].Y:=19;
      FlashPos[7].X:=0;FlashPos[7].Y:=18; FlashPos[8].X:=0;FlashPos[8].Y:=7;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 8 - JEEP }
      Name:= 'JEEP'; Production_time:=X/20;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=9;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=4; { zabira misto } Capacity:=3;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 9 - VYSADKARSKY TANK }
      Name:= 'AT-24 DEVIL'; Production_time:=X/30;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=15; AirAttack1:=5; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1026;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=3; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=6;FlashPos[1].Y:=9; FlashPos[2].X:=15;FlashPos[2].Y:=6;
      FlashPos[3].X:=22;FlashPos[3].Y:=4; FlashPos[4].X:=26;FlashPos[4].Y:=10;
      FlashPos[5].X:=27;FlashPos[5].Y:=20; FlashPos[6].X:=20;FlashPos[6].Y:=26;
      FlashPos[7].X:=10;FlashPos[7].Y:=24; FlashPos[8].X:=7;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 10 - RAKETOVE VOZIDLO }
      Name:= 'gKORPION'; Production_time:=X/35;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=10; AirAttack1:=10; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1283;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=4; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=3; FlashPos[2].X:=12;FlashPos[2].Y:=0;
      FlashPos[3].X:=30;FlashPos[3].Y:=6; FlashPos[4].X:=30;FlashPos[4].Y:=15;
      FlashPos[5].X:=22;FlashPos[5].Y:=19; FlashPos[6].X:=15;FlashPos[6].Y:=21;
      FlashPos[7].X:=3;FlashPos[7].Y:=18; FlashPos[8].X:=0;FlashPos[8].Y:=12;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 11 - TRANSPORTER }
      Name:= 'ALIGaTOR';  Production_time:=X/27;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=70; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 12 - BVP }
      Name:= 'BVP'; Production_time:=X/26;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=9; { zabira misto } Capacity:=6;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 13 - TANK }
      Name:= 'T-90 SIBERIA'; Production_time:=X/38;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=20; AirAttack1:=0; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=6;FlashPos[1].Y:=12; FlashPos[2].X:=12;FlashPos[2].Y:=7;
      FlashPos[3].X:=21;FlashPos[3].Y:=6; FlashPos[4].X:=27;FlashPos[4].Y:=12;
      FlashPos[5].X:=26;FlashPos[5].Y:=18; FlashPos[6].X:=17;FlashPos[6].Y:=24;
      FlashPos[7].X:=8;FlashPos[7].Y:=24; FlashPos[8].X:=5;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 14 - SAMOCHODKA }
      Name:= 'MC MAMUT'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=25; AirAttack1:=5; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1795;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=130; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=3;FlashPos[1].Y:=9; FlashPos[2].X:=12;FlashPos[2].Y:=5;
      FlashPos[3].X:=23;FlashPos[3].Y:=7; FlashPos[4].X:=27;FlashPos[4].Y:=16;
      FlashPos[5].X:=22;FlashPos[5].Y:=21; FlashPos[6].X:=20;FlashPos[6].Y:=24;
      FlashPos[7].X:=9;FlashPos[7].Y:=21; FlashPos[8].X:=5;FlashPos[8].Y:=14;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 15 - COMMANDOS }
      Name:= 'KOMANDOS'; Production_time:=X/44;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=1; HeavyAttack1:=1; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=2049;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=50; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=3;FlashPos[1].Y:=0; FlashPos[2].X:=15;FlashPos[2].Y:=0;
      FlashPos[3].X:=24;FlashPos[3].Y:=3; FlashPos[4].X:=26;FlashPos[4].Y:=13;
      FlashPos[5].X:=20;FlashPos[5].Y:=19; FlashPos[6].X:=9;FlashPos[6].Y:=23;
      FlashPos[7].X:=3;FlashPos[7].Y:=16; FlashPos[8].X:=0;FlashPos[8].Y:=8;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 16 - TEZKY TANK }
      Name:= 'A2M3 HROCH'; Production_time:=X/48;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=20; AirAttack1:=0; { sila utoku }
      LightAttack2:=15; HeavyAttack2:=5; AirAttack2:=0; { sila utoku }
      ShootRange1:=1538;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=6; { kadence strelby }
      DefenceStrength:=130; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=12; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=7;FlashPos[1].Y:=7; FlashPos[2].X:=15;FlashPos[2].Y:=6;
      FlashPos[3].X:=24;FlashPos[3].Y:=8; FlashPos[4].X:=25;FlashPos[4].Y:=14;
      FlashPos[5].X:=27;FlashPos[5].Y:=22; FlashPos[6].X:=15;FlashPos[6].Y:=27;
      FlashPos[7].X:=7;FlashPos[7].Y:=24; FlashPos[8].X:=6;FlashPos[8].Y:=14;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 17 - VYSADKOVY LETOUN }
      Name:= 'PARA LETOUN';  Production_time:=X/30;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=55; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=12;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=0; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 18 - STIHAC }
      Name:= 'EURO EF-2005'; Production_time:=X/50;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=10; HeavyAttack1:=10; AirAttack1:=50; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1281;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=1;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=2;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=0; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 19 - Protizemni stihac - Terminator}
      Name:= 'TERMINaTOR'; Production_time:=X/50;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=100; HeavyAttack1:=60; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1281;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=1;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=2;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=0; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 20 - LEHKA PEVNOST }
      Name:= 'LEHKa PEVNOST'; Production_time:=X/40;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=30; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=20; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=1283;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=24;  ShootSpeed2:=21; { kadence strelby }
      DefenceStrength:=160; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=20; { zabira misto } Capacity:=3;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=1;FlashPos[1].Y:=5; FlashPos[2].X:=9;FlashPos[2].Y:=1;
      FlashPos[3].X:=24;FlashPos[3].Y:=6; FlashPos[4].X:=23;FlashPos[4].Y:=12;
      FlashPos[5].X:=21;FlashPos[5].Y:=18; FlashPos[6].X:=9;FlashPos[6].Y:=18;
      FlashPos[7].X:=3;FlashPos[7].Y:=17; FlashPos[8].X:=1;FlashPos[8].Y:=11;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
end;

{ ***** }
procedure Init_units2;
{
}
const X = 5.0;
var I, J:Integer;
begin
   I:=21;
   with Unit_types^[I,0] do begin { 21 - TEZKA PEVNOST }
      Name:= 'TdkKa PEVNOST'; Production_time:=X/50;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=25; HeavyAttack1:=20; AirAttack1:=5; { sila utoku }
      LightAttack2:=20; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=1795;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=27;  ShootSpeed2:=21; { kadence strelby }
      DefenceStrength:=220; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=25; { zabira misto } Capacity:=4;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=5;FlashPos[1].Y:=9; FlashPos[2].X:=12;FlashPos[2].Y:=4;
      FlashPos[3].X:=29;FlashPos[3].Y:=8; FlashPos[4].X:=28;FlashPos[4].Y:=15;
      FlashPos[5].X:=21;FlashPos[5].Y:=20; FlashPos[6].X:=12;FlashPos[6].Y:=20;
      FlashPos[7].X:=10;FlashPos[7].Y:=21; FlashPos[8].X:=4;FlashPos[8].Y:=15;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 22 - ROBOT }
      Name:= 'BOJOVj ROBOT'; Production_time:=X/25;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=15; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=513;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=6;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=11;FlashPos[1].Y:=5; FlashPos[2].X:=17;FlashPos[2].Y:=4;
      FlashPos[3].X:=22;FlashPos[3].Y:=5; FlashPos[4].X:=24;FlashPos[4].Y:=10;
      FlashPos[5].X:=21;FlashPos[5].Y:=15; FlashPos[6].X:=16;FlashPos[6].Y:=18;
      FlashPos[7].X:=11;FlashPos[7].Y:=16; FlashPos[8].X:=8;FlashPos[8].Y:=9;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 23 - KAMIKADZE }
      Name:= 'AUTODETONaTOR'; Production_time:=X/40;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=80; HeavyAttack1:=80; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=257;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=1; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=5; AttackLevel2:=5; { specialni atribut utoku }
      Picture1:=7; Picture2:=7; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 24 - MECHWARRIOR }
      Name:= 'M1 MECHWARRIOR'; Production_time:=X/42;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=4; Picture2:=4; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 25 - VZNASEDLO }
      Name:= 'LEHKc VZNagEDLO'; Production_time:=X/34;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=10; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=8; { zabira misto } Capacity:=4;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=2; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 26 - TEZKE VZNASEDLO }
      Name:= 'TdkKc VZNagEDLO'; Production_time:=X/38;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=25; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=160; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=9; { zabira misto } Capacity:=7;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=2; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 27 - TANK }
      Name:= 'LEOPARD'; Production_time:=X/36;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=20; HeavyAttack1:=25; AirAttack1:=0; { sila utoku }
      LightAttack2:=12; HeavyAttack2:=7; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=9; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=7;FlashPos[1].Y:=11; FlashPos[2].X:=13;FlashPos[2].Y:=7;
      FlashPos[3].X:=25;FlashPos[3].Y:=10; FlashPos[4].X:=25;FlashPos[4].Y:=17;
      FlashPos[5].X:=22;FlashPos[5].Y:=22; FlashPos[6].X:=18;FlashPos[6].Y:=23;
      FlashPos[7].X:=10;FlashPos[7].Y:=22; FlashPos[8].X:=7;FlashPos[8].Y:=17;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 28 - RAKETOMET }
      Name:= 'MLRS';  Production_time:=X/35;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=20; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=2051;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=3; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 29 - MUTANT }
      Name:= 'BOJOVj MUTANT'; Production_time:=X/24;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=5; HeavyAttack1:=5; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=2051;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=15;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=100; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=3; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 30 - LETAJICI TALIR }
      Name:= 'ROBO HAWK'; Production_time:=X/41;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=10; HeavyAttack1:=15; AirAttack1:=10; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=10;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 31 - RAKETOVA VEZ }
      Name:= 'RAKETOVa Vdk'; Production_time:=X/47;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=15; HeavyAttack1:=15; AirAttack1:=0; { sila utoku }
      LightAttack2:=10; HeavyAttack2:=10; AirAttack2:=0; { sila utoku }
      ShootRange1:=1539;  ShootRange2:=513; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=12; { kadence strelby }
      DefenceStrength:=150; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=15; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=4; Picture2:=0; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=11;FlashPos[1].Y:=6; FlashPos[2].X:=17;FlashPos[2].Y:=6;
      FlashPos[3].X:=23;FlashPos[3].Y:=6; FlashPos[4].X:=22;FlashPos[4].Y:=11;
      FlashPos[5].X:=22;FlashPos[5].Y:=16; FlashPos[6].X:=16;FlashPos[6].Y:=17;
      FlashPos[7].X:=11;FlashPos[7].Y:=16; FlashPos[8].X:=10;FlashPos[8].Y:=11;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 32 - INFRA SAM }
      Name:= 'PVO BATERIE'; Production_time:=X/42;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=20; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=30;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=150; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=15; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=4; Picture2:=4; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 33 - BUDOVA VE FORME VOZIDLA }
      Name:= 'TRUCK'; Production_time:=X/39;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=80; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 34 - HELIKOPTERA }
      Name:= 'AH-70 SIOUX'; Production_time:=X/39;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=15; HeavyAttack1:=15; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1025;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=60; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 35 - LEHKY KANON }
      Name:= 'MC TERMIT';  Production_time:=X/27;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=20; HeavyAttack1:=20; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1795;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=21;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=50; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=5; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=3; Autorepair:=0;
   end; Inc(I);
end;

{ ***** }
procedure InitReasearchAssign;
{
}
var I,J:Word;
begin
 for J:=0 to 1 do begin
   I:=1;
   with (ReserchAssign[I,J]) do begin {*1*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     ForPlayer:=False; { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu }
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*2*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     ForPlayer:=False; { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu }
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*3*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     ForPlayer:=False; { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu }
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*4*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     ForPlayer:=False; { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu }
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*5*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*6*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*7*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*8*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*9*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*10*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*11*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*12*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*13*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*14*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*15*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*16*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*17*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     {if (OSNPlayer) then ForPlayer:=True else{} ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*18*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     {if (OSNPlayer) then ForPlayer:=True else{} ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*19*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     {if (OSNPlayer) then ForPlayer:=True else{} ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*20*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*21*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*22*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*23*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*24*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*25*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*26*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*27*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*28*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*29*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*30*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*31*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*32*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*33*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*34*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*35*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*36*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*37*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*38*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*39*}
     UnitAvail:=0; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     if (not OSNPlayer) then ForPlayer:=True else ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*40*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
   with (ReserchAssign[I,J]) do begin {*41*}
     UnitAvail:=1; { 0 pokud neni k dispozici (napr. neni vyzkoumana) }
     { True - hrac muze tuto zbran pouzit k prirazeni vyzkumu: }
     ForPlayer:=False;
     { nyni prirazeni vynalezu k jednotlivym kategoriim  (0 znamena nic):  }
     Attack1:=0;Attack2:=0;Defence1:=0;Defence2:=0;Sight1:=0;Sight2:=0;Engine1:=0;Engine2:=0;Special1:=0;Special2:=0;
     _u:=0;_o:=0;_k:=0;_lu:=0;_tu:=0;_au:=0;_r:=0;_d:=0;_h:=0;_s:=0;
     _BP:=0;_EE:=0;_PL:=0;_Ex:=0;
   end;Inc(I);
 end;
end;

{ ***** }
procedure Load_unit_picture;
{
}
var I,Index,X,Y:Word;
    Result:Word;
    Pom:String;
    Memory:LongInt;
begin
   { *** NAHRANI JEDNOTEK DO PAMETI *** }
   { nyni probehne nahravani obrazku lidi 1 }
   { nejprve pole vynulujeme }
   for I:=1 to MaxTypesOfUnits do with Unit_pictures[I] do begin
      S:=0; S:=0;
   end;
   { dale pole naplnime }
   OpenImage(PathStr+'data\units',NoCreateNew);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units');
   if (InternalCache) then begin
      Result:=CacheFetch(PathStr+'data\units');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units');
   for I:=1 to 20 do begin
     Str(I-1,Pom); Index:=I;
     { zjisteni existence a velikosti obrazku }
     GetXYImageCoordinatesGBM(X,Y,Pom+'_8');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units');
     Memory:=LongInt(X) * LongInt(Y) + 4;
     with (Unit_pictures[Index]) do begin
        GetMemory(Memory,S,O); if (S = 0) then Error(0,'Nedostatek pameti');
        LoadImageGBM(S,O,Pom+'_8',0);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units');
     end;
   end;
   InvalidateCache;

   OpenImage(PathStr+'data\units2',NoCreateNew);
   if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units2');
   if (InternalCache) then begin
      Result:=CacheFetch(PathStr+'data\units2');
      if (Result <> 0) then
        if (Result <> 65535) then Error(Result,'- chyba pri praci s cache');
   end;
   for I:=21 to MaxTypesOfUnits do begin
     Str(I-1,Pom);  Index:=I;
     { zjisteni existence a velikosti obrazku }
     GetXYImageCoordinatesGBM(X,Y,Pom+'_8');
     if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units2');
     Memory:=LongInt(X) * LongInt(Y) + 4;
     with (Unit_pictures[Index]) do begin
        { nahrani 1. obrazku }
        GetMemory(Memory,S,O); if (S = 0) then Error(0,'Nedostatek pameti');
        LoadImageGBM(S,O,Pom+'_8',0);
        if (IO_Result <> 0) then Error(IO_Result,'- soubor ..\data\units2');
     end;
   end;
   InvalidateCache;
   { *** JEDNOTKY NAHRANY *** }
end;

{ ***** }
function GetString(MaxChars:Byte; var Ret:String):Boolean;
{ Umozni uzivateli naeditovat retezec Ret
  -MaxChars udava maximalni pocet editovatelnych pismen
  -vraci True pri uspesnosti operace
}
var XPanel,YPanel,Scan,Ascii:Word;
    X,Y,X2,Y2:Word;
    RetPos:Byte;
    XRetPos,YRetPos:Word;
begin
   {!!!!!!!!!}GetString:=True;
   Ret:=''; RetPos:=1;

   X:=(XResolution-XGetStringSize) shr 1; Y:=(YResolution-YGetStringSize) shr 1;
   X2:=X+XGetStringSize-1; Y2:=Y+YGetStringSize-1;
   { Draw panel }
   XPanel:=X; YPanel:=Y;
   CursorOff; ScreenOff;
   GetImage(X,Y,X2,Y2,GetStringBckSeg,GetStringBckOfs,NormalDirect);
   {SpecMenu}Rectangle2(X+2,Y+2,X2-2,Y2-2,74);
   Frame(X+1,Y+1,X2-1,Y2-1,66);
   Frame(X,Y,X2,Y2,70);
   XRetPos:=X+(X2-X-XFontSize*MaxChars) shr 1;
   YRetPos:=Y+(Y2-Y-2*YFontSize) shr 1+YFontSize+YFontSize shr 1;
   OutTextColor(X+(X2-X-XFontSize*13) shr 1,Y+YFontSize,64,'ZADEJTE JMcNO:');
   Rectangle2(XRetPos,YRetPos,XRetPos+XFontSize*(MaxChars+1),YRetPos+YFontSize,0);
   ScreenOn; CursorOn;

   { end Draw panel }
   repeat
    repeat
      Keyb(Scan,Ascii);
    until (Scan <> 0);
    if (Scan <> $01) then begin
      if (Scan = $0e) then begin
         if (RetPos > 1) then begin
            Dec(RetPos); Ret[0]:=Chr(RetPos-1);
            CursorOff;
            Rectangle2(XRetPos,YRetPos,XRetPos+XFontSize,YRetPos+YFontSize,0);
            CursorOn;
            Dec(XRetPos,XFontSize);
         end;
      end else
         if (RetPos <= MaxChars) then begin
           case (Ascii) of
             32      : begin Ret[RetPos]:=Chr(Ascii); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             065..090: begin Ret[RetPos]:=Chr(Ascii); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             097..122: begin Ret[RetPos]:=Chr(Ascii-32); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             48..57  : begin Ret[RetPos]:=Chr(Ascii); Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             33      : begin Ret[RetPos]:='+'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             54      : begin Ret[RetPos]:='.'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             64      : begin Ret[RetPos]:='d'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             35      : begin Ret[RetPos]:='g'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             36      : begin Ret[RetPos]:='b'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             37      : begin Ret[RetPos]:='f'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             94      : begin Ret[RetPos]:='k'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             38      : begin Ret[RetPos]:='j'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             40      : begin Ret[RetPos]:='e'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             41      : begin Ret[RetPos]:='c'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             42      : begin Ret[RetPos]:='a'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             Ord('[') : begin Ret[RetPos]:='h'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
             Ord(';') : begin Ret[RetPos]:='i'; Inc(RetPos); Ret[0]:=Chr(RetPos-1); end;
           else
              Continue;
           end;
           Inc(XRetPos,XFontSize);
           CursorOff;
           OutTextColor(XRetPos,YRetPos,66,Ret[RetPos-1]);
           CursorOn;
         end;
    end;
   until ((Scan = $01) or (Scan = $1c) or (RetPos > MaxChars));

   if (Scan = $01) then GetString:=False;
   { Erase panel }
   CursorOff;
   PutImage(XPanel,YPanel,GetStringBckSeg,GetStringBckOfs,NormalDirect);
   CursorOn;
   { end Erase panel }
end;

{ ************************************************************************* }
begin
   { ************ }
   { * JEDNOTKY * }
   { ************ }
   Init1;
   Init_units2;
   I:=36;
   with Unit_types^[I,0] do begin { 36 - ANTITANK }
      Name:= 'TIGER'; Production_time:=X/32;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=5; HeavyAttack1:=30; AirAttack1:=0; { sila utoku }
      LightAttack2:=5; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=1282;  ShootRange2:=257; { dostrel }
      ShootSpeed1:=18;  ShootSpeed2:=12; { kadence strelby }
      DefenceStrength:=90; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=10; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=0; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=9;FlasHPos[1].Y:=9; FlashPos[2].X:=11;FlashPos[2].Y:=7;
      FlashPos[3].X:=18;FlashPos[3].Y:=7; FlashPos[4].X:=23;FlashPos[4].Y:=13;
      FlashPos[5].X:=28;FlashPos[5].Y:=7; FlashPos[6].X:=18;FlashPos[6].Y:=18;
      FlashPos[7].X:=12;FlashPos[7].Y:=16; FlashPos[8].X:=8;FlashPos[8].Y:=14;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=10; Autorepair:=0;
   end; Inc(I);

   with Unit_types^[I,0] do begin { 37 - HELIKOPTERA NA ZEMI }
      Name:= 'CHINOOK'; Production_time:=X/40;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=13; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);

   with Unit_types^[I,0] do begin { 38 - OSPREY NA ZEMI }
      Name:= 'OSPREY'; Production_time:=1.2;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=3;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=95; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=14; { zabira misto } Capacity:=12;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=0; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=0; Picture2:=0; { obrazky strel }
      UnitLevel:=3; { pohybova uroven jednotky }
      SpecAirLevel:=1; { specialni atribut vzdusne jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      Parent:=12; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 39 - LIKVIDATOR }
      Name:= 'M2 LIKVIDaTOR'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=1;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=15; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 40 - TERORISTA }
      Name:= 'TERORISTA'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=0;
      LightAttack1:=20; HeavyAttack1:=10; AirAttack1:=5; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=769;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=12;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=120; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=1; Picture2:=1; { obrazky strel }
      UnitLevel:=1; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=FALSE; { jde o budovu ? }
      Parent:=2; Autorepair:=0;
   end; Inc(I);
   with Unit_types^[I,0] do begin { 41 - Centrum Posil }
      Name:= 'CENTRUM POSIL'; Production_time:=X/60;
      BP:=200; PL:=1; EE:=1; EX:=0;
      TargetTyp:=2;
      LightAttack1:=0; HeavyAttack1:=0; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=0;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=0;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=250; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=255;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=2; { specialni atribut utoku }
      Picture1:=3; Picture2:=3; { obrazky strel }
      UnitLevel:=255; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=True;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=TRUE; { jde o budovu ? }
      Parent:=14; Autorepair:=0;
   end;  Inc(I);
   with Unit_types^[I,0] do begin { 42 - GUNBOAT }
      Name:= 'DdLOVj bLUN'; Production_time:=X/60;
      BP:=1; PL:=1; EE:=1; EX:=1;
      TargetTyp:=2;
      LightAttack1:=100; HeavyAttack1:=120; AirAttack1:=0; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=8 shl 8;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=3;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=250; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=255; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=1; Picture2:=0; { obrazky strel }
      UnitLevel:=4; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      SpeedLevel:=3;
      MovementAdding:=Speed[SpeedLevel];
      Parent:=14; Autorepair:=0;
   end;  Inc(I);
   with Unit_types^[I,0] do begin { 43 - MISSILE BOAT }
      Name:= 'RAKETOVj bLUN'; Production_time:=X/60;
      BP:=1; PL:=1; EE:=1; EX:=1;
      TargetTyp:=2;
      LightAttack1:=80; HeavyAttack1:=150; AirAttack1:=40; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=7 shl 8;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=3;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=280; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=0;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=5; Picture2:=0; { obrazky strel }
      UnitLevel:=4; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      SpeedLevel:=4;
      MovementAdding:=Speed[SpeedLevel];
      Parent:=14; Autorepair:=0;
   end;  Inc(I);
   with Unit_types^[I,0] do begin { 44 - DESTROYER }
      Name:= 'DESTROYER'; Production_time:=X/60;
      BP:=1; PL:=1; EE:=1; EX:=1;
      TargetTyp:=2;
      LightAttack1:=120; HeavyAttack1:=120; AirAttack1:=20; { sila utoku }
      LightAttack2:=0; HeavyAttack2:=0; AirAttack2:=0; { sila utoku }
      ShootRange1:=10 shl 8;  ShootRange2:=0; { dostrel }
      ShootSpeed1:=5;  ShootSpeed2:=0; { kadence strelby }
      DefenceStrength:=380; { sila obrany }
      { bodove pohybove prirustky }
      NeedPlace:=2; { zabira misto } Capacity:=4;  { kapacita jednotky }
      Sight:=4;  { dohled }
      AttackLevel1:=2; AttackLevel2:=0; { specialni atribut utoku }
      Picture1:=2; Picture2:=0; { obrazky strel }
      UnitLevel:=4; { pohybova uroven jednotky }
      ShootType1:=0; ShootDelay1:=0; ShootType2:=0; ShootDelay2:=0;

      GuidedMissile:=False;
      FlashPos[1].X:=0;FlashPos[1].Y:=0; FlashPos[2].X:=0;FlashPos[2].Y:=0;
      FlashPos[3].X:=0;FlashPos[3].Y:=0; FlashPos[4].X:=0;FlashPos[4].Y:=0;
      FlashPos[5].X:=0;FlashPos[5].Y:=0; FlashPos[6].X:=0;FlashPos[6].Y:=0;
      FlashPos[7].X:=0;FlashPos[7].Y:=0; FlashPos[8].X:=0;FlashPos[8].Y:=0;
      PictureIndex:=I; { index do pole obrazku }
      Build:=False; { jde o budovu ? }
      SpeedLevel:=2;
      MovementAdding:=Speed[SpeedLevel];
      Parent:=14; Autorepair:=0;
   end;

   for I:=1 to MaxTypesOfUnits do Unit_types^[I,1]:=Unit_types^[I,0];
   SetTerminator_fighterParams(False);

   { ************ }
   { *  BUDOVY  * }
   { ************ }
   I:=1;
   { Zakladna }
   with (Building_types[I]) do begin
      BP:=400; PL:=80; EE:=150; EX:=25; Production_time:=Y/30;
      DefenceStrength:=3130; { sila obrany }
      Name:='ZaKLADNA'; { nazev } Inc(I);
      ProductionType:=1;  MaxIndex:=8;
      Production[0]:=2; Production[1]:=3; Production[2]:=4;
      Production[3]:=5; Production[4]:=6; Production[5]:=7;
      Production[6]:=8; Production[7]:=1; Production[8]:=9;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Kasarna }
   with (Building_types[I]) do begin
      BP:=120; PL:=12; EE:=60; EX:=2; Production_time:=Y/22;
      DefenceStrength:=1080; { sila obrany }
      Name:='KASaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=3;
      Production[0]:=5; Production[1]:=6; Production[2]:=7;
      Production[3]:=15; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=1;
      Parent:=1; Autorepair:=0;
   end;
   { Lehka tovarna }
   with (Building_types[I]) do begin
      BP:=180; PL:=0; EE:=30; EX:=0; Production_time:=Y/23;
      DefenceStrength:=1285; { sila obrany }
      Name:='LEHKa TOVaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=8;
      Production[0]:=4; Production[1]:=8; Production[2]:=1;
      Production[3]:=10; Production[4]:=35; Production[5]:=28;
      Production[6]:=25; Production[7]:=26; Production[8]:=2;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Recyklace }
   with (Building_types[I]) do begin
      BP:=100; PL:=10; EE:=20; EX:=0; Production_time:=Y/20;
      DefenceStrength:=1223; { sila obrany }
      Name:='RECYKLACE'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Elektrarna }
   with (Building_types[I]) do begin
      BP:=450; PL:=0; EE:=0; EX:=0; Production_time:=Y/26;
      DefenceStrength:=1200; { sila obrany }
      Name:='ELEKTRaRNA'; { nazev } Inc(I);
      ProductionType:=3;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Akumulator }
   with (Building_types[I]) do begin
      BP:=200; PL:=40; EE:=35; EX:=1; Production_time:=Y/18;
      DefenceStrength:=1950; { sila obrany }
      Name:='AKUMULaTOR'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { generalni stab }
   with (Building_types[I]) do begin
      BP:=350; PL:=90; EE:=100; EX:=30; Production_time:=Y/27;
      DefenceStrength:=3000; { sila obrany }
      Name:='GENERaLNe gTaB'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Vyroba plastu}
   with (Building_types[I]) do begin
      BP:=300; PL:=0; EE:=40; EX:=0; Production_time:=Y/21;
      DefenceStrength:=1920; { sila obrany }
      Name:='VjROBA PLASTi'; { nazev } Inc(I);
      ProductionType:=2;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Zakladna 2}
   with (Building_types[I]) do begin
      BP:=250; PL:=75; EE:=90; EX:=15; Production_time:=Y/35;
      DefenceStrength:=2530; { sila obrany }
      Name:='HITECH ZaKLADNA'; { nazev } Inc(I);
      ProductionType:=1;  MaxIndex:=5;
      Production[0]:=21; Production[1]:=10; Production[2]:=11;
      Production[3]:=12; Production[4]:=13; Production[5]:=14;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   { Tezka tovarna }
   with (Building_types[I]) do begin
      BP:=500; PL:=55; EE:=150; EX:=10; Production_time:=Y/28;
      DefenceStrength:=2400; { sila obrany }
      Name:='TdkKa TOVaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=7;
      Production[0]:=11; Production[1]:=12; Production[2]:=13;
      Production[3]:=9; Production[4]:=16; Production[5]:=27;
      Production[6]:=36; Production[7]:=14; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Letiste }
   with (Building_types[I]) do begin
      BP:=555;  PL:=108;  EE:=200;  EX:=35; Production_time:=Y/45;
      DefenceStrength:=150; { sila obrany }
      Name:='LETIgTd'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Spec. tovarna }
   with (Building_types[I]) do begin
      BP:=420; PL:=60; EE:=40; EX:=40; Production_time:=Y/29;
      DefenceStrength:=1710; { sila obrany }
      Name:='SPEC. TOVaRNA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=6;
      Production[0]:=17; Production[1]:=34; Production[2]:=18;
      Production[3]:=19; Production[4]:=29; Production[5]:=30;
      Production[6]:=37; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Centrum oprav }
   with (Building_types[I]) do begin
      BP:=250; PL:=35; EE:=100; EX:=0; Production_time:=Y/25;
      DefenceStrength:=2250; { sila obrany }
      Name:='CENTRUM OPRAV'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Obranne centrum }
   with (Building_types[I]) do begin
      BP:=330; PL:=10; EE:=95; EX:=3; Production_time:=Y/31;
      DefenceStrength:=2040; { sila obrany }
      Name:='OBRANNc CENTRUM'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=4;
      Production[0]:=20; Production[1]:=21; Production[2]:=31;
      Production[3]:=32; Production[4]:=41; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   { Montazni linka }
   with (Building_types[I]) do begin
      BP:=125; PL:=11; EE:=55; EX:=2; Production_time:=Y/22;
      DefenceStrength:=1200; { sila obrany }
      Name:='MONTakNe LINKA'; { nazev } Inc(I);
      ProductionType:=0;  MaxIndex:=3;
      Production[0]:=22; Production[1]:=23; Production[2]:=24;
      Production[3]:=39; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=1; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=500; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=1020; { sila obrany }
      Name:='bISTIbKA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=420; { sila obrany }
      Name:='STODOLA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=640; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=640; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=400; PL:=30; EE:=70; EX:=10; Production_time:=Y/20;
      DefenceStrength:=1000; { sila obrany }
      Name:='RADAR'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=9; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=550; { sila obrany }
      Name:='DiM'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=440; { sila obrany }
      Name:='STODOLA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=200; { sila obrany }
      Name:='STUDNA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=2;
      Parent:=0; Autorepair:=0;
   end;
   with (Building_types[I]) do begin
      BP:=0; PL:=0; EE:=0; EX:=0; Production_time:=1.2;
      DefenceStrength:=5000; { sila obrany }
      Name:='PfEKakKA'; { nazev } Inc(I);
      ProductionType:=4;  MaxIndex:=0;
      Production[0]:=0; Production[1]:=0; Production[2]:=0;
      Production[3]:=0; Production[4]:=0; Production[5]:=0;
      Production[6]:=0; Production[7]:=0; Production[8]:=0;
      Sight:=0;
      Parent:=0; Autorepair:=0;
   end;

   for I:=1 to MaxTypesOfUnits do with (Unit_types^[I,1]) do begin
     if (TargetTyp = 0) then Unit_target_types[I]:=P;
     if (TargetTyp = 1) then Unit_target_types[I]:=L;
     if (TargetTyp = 2) then Unit_target_types[I]:=T;
     if (TargetTyp = 3) then Unit_target_types[I]:=A;
     if (UnitLevel = 255) then Unit_target_types[I]:=V;
   end;
end.
