function [FLATS, stdecg] = FLATS_mV(ECG)
%**************************************************************************
%Title:             Wavelet Low Amplitude Sum FINAL
%Created:           8/10/2011
%Last modified:     8/14/2011
%Author:            Jason Coult
%
%Accepts a 5-second 250Hz ECG signal and uses the number of points below a 
%low amplitude threshold. 
%Takes scaling ratios with length and number of bands
%in attempt to compensate for allowing varied input clip lengths and number
%of bands examined, to save pause time and analysis time. 
%requires: cwt_1002

%**************************************************************************
%load data3.mat

stdecg=std(ECG);

WAVELET = 'cmor1-1'; %wavelet type

coefs_raw = cwt_1002(ECG,7,WAVELET); %32 scales is default

if (stdecg<.500)
coefs_raw2=((coefs_raw))*700;  
else
coefs_raw2=((coefs_raw))*700*0.4/stdecg;
end             %adjust only if very high amplitude

        abscoefs=abs(coefs_raw2(30:885));
        
        flatCNT=0;
       for j=1:856
           if (abscoefs(j)<0.375)  %using the 0.375 threshold
               flatCNT=flatCNT+1;
           end
       end
                   if flatCNT==0; % so that taking the log10 will give zero, not error
                       flatCNT=1;
                   end
       
         FLATSraw=flatCNT;
          FLATS=log10(FLATSraw);
        
end %function end
