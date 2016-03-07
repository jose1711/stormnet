                GlobalInfoStr[3]:='   ZPRaVA TAJNc SLUkBY:';
                GlobalInfoStr[4]:='PODLE INFORMACe, KTERc JSME ZeSKALI OD INFORMaTORi, NASADe NAgI NEPfaTELc';
                GlobalInfoStr[5]:='V NaSLEDUJeCeCH BOJeCH VYLEPgENj TYP "ALIGaTOR". HLAVNe ZMdNY SPObeVAJe';
                GlobalInfoStr[6]:='V MONTakI LEPgeHO PANCefE A KVALITNdJgeCH ZBRANe.';
                {X}
                GlobalInfoStr[2]:='   ZPRaVA TAJNc SLUkBY:';
                GlobalInfoStr[3]:='PODLE UKOfISTdNjCH DOKUMENTi JSME ZJISTILI, kE NAgI NEPfaTELc NASADe ';
                GlobalInfoStr[4]:='V NaSLEDUJeCeCH BOJeCH ZDOKONALENj TYP "ALIGaTOR". HLAVNe ZMdNY SPObeVAJe';
                GlobalInfoStr[5]:='V MONTakI LEPgeHO PANCefE A KVALITNdJgeCH ZBRANe.';
                {X}
                GlobalInfoStr[2]:='   ZPRaVA TAJNc SLUkBY:';
                GlobalInfoStr[3]:='ZPRaVY NAgICH PRiZKUMNeKi NAZNAkUJe, kE NEPfaTELc V NEJBLIkge DOBd NASADe';
                GlobalInfoStr[4]:='VYLEPgENj TYP "ALIGaTOR". OD PiVODNeHO TYPU SE LIge ZEJMcNA LEPgeM PANCefEM';
                GlobalInfoStr[5]:='A KVALITNdJgeMI ZBRANdMI.';


                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                if ((POINTS >= (600+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(600+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE O TERcNU?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-600-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.UnknownTerrain:=1;
                  end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                if ((POINTS >= (700+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                  Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                  Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                  Str(700+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                  if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI LEPge INFORMACE OD SPOJENCi?',
                                    Str3,Str2,_YES_NO)=YES)
                  then begin
                    POINTS:=POINTS-700-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                    GlobalModify.AllyFog:=1;
                  end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                if ((POINTS >= (500+TempValue)) and (VICTORYPOINTS >= 0)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(500+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 0';
                   if (WideDialogBox('CHCETE BjT V NaSLEDUJeCe MISI SILNdJge?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-500-TempValue; VICTORYPOINTS:=VICTORYPOINTS-0;
                     GlobalModify.FriendlySpecialUnitsPresent:=True;
                   end;
                end;
                {X}
                TempValue:=Random(100);  if (TempValue > 50) then TempValue:=TempValue-100;
                if ((POINTS >= (260+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(260+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE MATERIaLi?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-260-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceMaterialModifiers[0].BPModif:=100;
                     GlobalModify.RaceMaterialModifiers[0].ExpModif:=100;
                     GlobalModify.RaceMaterialModifiers[0].PLModif:=100;
                     GlobalModify.RaceMaterialModifiers[0].EEModif:=100;
                   end;
                end;
                {X}
                TempValue:=Random(10);  if (TempValue > 5) then TempValue:=TempValue-10;
                if ((POINTS >= (20+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(20+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE MeT V NaSLEDUJeCe MISI VeCE NdKTERjCH MATERIaLi?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-20-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceMaterialModifiers[0].BPModif:=100;
                     GlobalModify.RaceMaterialModifiers[0].ExpModif:=100;
                     GlobalModify.RaceMaterialModifiers[0].PLModif:=100;
                     GlobalModify.RaceMaterialModifiers[0].EEModif:=100;
                   end;
                end;

                {X}
                TempValue:=Random(10);  if (TempValue > 5) then TempValue:=TempValue-10;
                if ((POINTS >= (20+TempValue)) and (VICTORYPOINTS >= 1)) then begin
                   Str(Round(POINTS),Str1); Str2:='MaTE: KREDITY: '+Str1+',  ';
                   Str(Round(VICTORYPOINTS),Str1); Str2:=Str2+'PRESTIk: '+Str1;
                   Str(20+TempValue,Str1); Str3:='CENA: KREDITY: '+Str1+',  PRESTIk: 1';
                   if (WideDialogBox('CHCETE V NaSLEDUJeCe MISI OSLABIT NEPfaTELE?',
                                     Str3,Str2,_YES_NO)=YES)
                   then begin
                     POINTS:=POINTS-20-TempValue; VICTORYPOINTS:=VICTORYPOINTS-1;
                     GlobalModify.RaceMaterialModifiers[0].BPModif:=-100;
                     GlobalModify.RaceMaterialModifiers[0].ExpModif:=-100;
                     GlobalModify.RaceMaterialModifiers[0].PLModif:=-100;
                     GlobalModify.RaceMaterialModifiers[0].EEModif:=-100;
                   end;
                end;
