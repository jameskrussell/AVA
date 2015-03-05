function [CLAS] = CLAS_mV(SIG) 

%Must be in mV, not uV (Larry's version)
%Sig must be 950 pts or more, it will be zero padded below
% CLAS estimates VF vs ORG  
%--------------
SIG = SIG * 1000; %convert to uV

SIG2=SIG(1:950);
SIG2(951:1024)=0;
% this is the zero padding
%SIG2 will be changed to ySIG below
WAV = 'cmor1-1'; 
scales=([8.13625304968462;
    8.50447636482757;
    8.88936440376745;
    9.29167136377478;
    9.71218557491040;
    10.1517310447770;
    10.6111690731815;
    11.0913999398727;
    11.5933646686608;
    12.1180468713759;
    12.6664746752786;
    13.2397227377005;
    13.8389143518598;
    14.4652236479822;
    15.1198778940360;
    15.8041599005936;
    16.5194105345290;
    17.2670313464784;
    18.0484873172123;
    18.8653097282995;
    19.7190991626906;
    20.6115286410978;
    21.5443469003188;
    22.5193818199288;
    23.5385440040530;
    24.6038305252418;]);





% Place Signal in ySIG array, make xSIG and set stepSIG to 1;
%--------------

    ySIG    = SIG2;
    lenSIG  = length(ySIG);
    xSIG    = (1:lenSIG);
    stepSIG = 1;
    
% now load the wavelet.
%---------------

    precis = 10; % precis = 15;
    [val_WAV,xWAV] = intwave(WAV,precis);
    stepWAV = xWAV(2)-xWAV(1);
    val_WAV = conj(val_WAV); 

    xWAV = xWAV-xWAV(1);
    xMaxWAV = xWAV(end);

    ySIG   = ySIG(:)';
    nb_SCALES = length(scales);
    
    ind  = 1;

    for k = 1:nb_SCALES
        a = scales(k);
        a_SIG = a/stepSIG;

        j = 1+floor((0:a_SIG*xMaxWAV)/(a_SIG*stepWAV));  
        
        if length(j)==1 , j = [1 1]; end
              
        f  =   fliplr(real(val_WAV(j)));
               
        coefs_raw(ind,:) =  -sqrt(a)*wkeep1(diff(wconv1(ySIG,f)),lenSIG);
        ind = ind+1;
        
    end
    
    %%% coeffs calculated, now we only need 13 to match the JM_code for the
    %%% chip
    
numbands =13;
cliplen = 28;
coefs = coefs_raw(:,((1+cliplen):(1024-cliplen)));
coefs = (abs(coefs)).^2; 

%normalize each frequency so total area under each curve is same
for i = 1:length(coefs(:,1))
   coefs_band(i,:) = length(coefs(i,:)).*(coefs(i,:)./sum(coefs(i,:))); 
end

% now calculate the sums under the cutoff (note the cutoff is adjusted form
% matlab calcs, higher then the 0.012 used on the Ccode for the chip. Every
% other scale for a total of 13
for (a=1:2:25)
    lowamp_sum_band(a)=0;
    lowamp_sum_band(a+1)=0;% to zero the empty one
    for (i=1:894)
        if (coefs_band(a,i)<0.0132)  % USING 0,132 instead of 0.012 to match ccode
            lowamp_sum_band(a)=lowamp_sum_band(a)+1;
            
        end
    end
end
        


% sum those below the threshold
lowamp_sum = sum(lowamp_sum_band(:));


%make output proportional to the length of the input signal so that input
%signal length will not change the threshold cutoff, as well as
%proportional to the number of wavelet scales. This is because of the use
%of an absolute count rather than ratio of amplitudes. 
proportion_scaler = (10000/894/13);
lowamp_sum = lowamp_sum.*proportion_scaler;

%put output into log scale for easier viewing
if lowamp_sum > 0 %prevent taking log of 0
    CLAS=log(lowamp_sum);
    %LOGlowamp_sum(i2) = log(lowamp_sum); %take the log
else
    CLAS=0;
end

end
%

%----------------------------------------------------------------------
