function  [SD, slice]=Rule_Philips102(FLATS,CLAS,PKA  )
% Will return the Decision based on the FLATS, CLAS and the PKA
% which is an amplitude measure. This rule is designed for cases in which
% CPR is being performed and would be modified for cases without CPR being
% performed. 
%
% The heuristic is that the FLATS is used to stratisfy the data into
% regions which are of thickness 0.05. These "slices" through the FLATS
% axis of the 3 dimensional plot of data (FLATS, CLAS, and PKA) are the
% analyzed one slice at a time. In each slice the two dimensional CLAS and
% PKA form a two dimension plot that cutoffs may be used to separate out
% the VF cases from the non shockable cases (Asystole and Organized). This
% separation is based primarily on the CLAS, but the PKA is used to a
% lesser extent to improve the yield. Other strategies could be used and
% this is one of several we have developed.
% SD is "ShockDecision", and '1' is for Shockable (VF), '0' is for
% NonShockable (Asystole and Organized rhythms).
%
i=0;
slice=1; %initial value to avoid crash

SD = 0; % No Shock is the default. 

% Determine the slice of FLATS that the data point lies within
    for j=0:45
        if ((FLATS>=(0.75+(j*.05))) && (FLATS<((0.75+(j*.05))+.05))); % this is the 'slice'
                  i=j; % Here we set the i variable which indicates the slice
                  slice=i; % to record the slice as well for reference
                  break
        end
    end
    
 % Next find the slice (it is the corresponding 'i') and evaluate the CLAS and PKA to 
 % determine the probability of VF or Org/Asys classifications which is the
 % Shock Decision (SD) and is returned
 %

                           if(i<13)
                                    if CLAS>7.75
                                        SD=0; % SD is "ShockDecision" and '1' is "shockable", '0' is No Shock
                                    elseif CLAS<7.4
                                        SD=1;
                                    else
                                        SD=0;
                                    end
                                
                           elseif(i>50)
                                        SD=0;
                                
                           elseif(i<14)
                                    if CLAS>7.75
                                        SD=0;
                                    elseif ( (PKA>3.25) && (CLAS<7.5) )
                                        SD=1;
                                    elseif CLAS<7.4
                                        SD=1;
                                    else
                                        SD=0;
                                    end
                                   
                                
                           elseif(i<16)
                                           
                                    if CLAS>7.75
                                        SD=0;
                                    elseif((PKA>3.0)&& (CLAS<7.32))
                                        SD=1;    
                                    elseif CLAS<7.3  
                                        SD=1;
                                    else
                                        SD=0;
                                    end
                                  
                          elseif(i<24)
                                                if CLAS>7.3
                                                    SD=0;
                                                else                                                    
                                                    SD=1;
                                                end
                                             
                          elseif(i<26)
                                                    if CLAS>7.17
                                                        SD=0;
                                                    else                                                    
                                                        SD=1;
                                                    end
                                                   
                                                    
                          elseif(i<27)
                                                    if CLAS>7.15
                                                        SD=0;
                                                    else                                                    
                                                        SD=1;
                                                    end
                                                    
                          elseif(i<34)
                                                    if ((CLAS<7.75)&& (PKA>3.42))
                                                        SD=1;
                                                    else                                                    
                                                        SD=0;
                                                    end
                                                                       
                          elseif(i<44)
                                                 
                                                 SD=0;
                                                         if(0) % this is a variation to be tested later
                                                            if CLAS<=7.05
                                                                SD=1;
                                                            elseif ((PKA<2.7)&&(CLAS<7.4))
                                                                SD=1;
                                                            elseif CLAS>7.75
                                                                SD=0;
                                                            elseif ((CLAS>7.05)&&(PKA>3.2))
                                                                SD=1;

                                                            else 
                                                                SD=0;
                                                            end
                                                         end
                                                        
                          else
                                               SD=0; % all of these above 32 are ORG (almost all)
                               
                                
                          end % if i<12 

  end
                  
      

