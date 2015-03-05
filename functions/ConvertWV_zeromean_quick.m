function [ WVzm ] = ConvertWV_zeromean_quick(wv_in, time_epoch, sampleRate)
% 
% use low pass filter to remove 60 Hz
% mean center, and detrend
% wv_in is sampled at sampleRate; WVzm is same length as wv_in
% subtract the mean to give it a zero mean for display purposes. 
% Do this for "time_epoch" epochs to produce
% smoothing and in the process these epochs will be detrended for smoothing
% as well. 

    load('lp60.mat')

    wv_out=filtfilt(lp60.Numerator, 1, wv_in); %zero-phase filtering
    X = time_epoch * sampleRate;  %length of epoch in pts;
    nEPOCH = floor(length(wv_out)/X);  %number of epochs

        for k=0:nEPOCH-1 % so we don't run over the end 
           meanEPOCH = nanmean(wv_out(1+k*X:(k+1)*X )); 
           WVzm(1+k*X:(k+1)*X) = wv_out(1+k*X:(k+1)*X) - meanEPOCH; %subtract mean
           WVzm(1+k*X:(k+1)*X) = detrend(WVzm(1+k*X:(k+1)*X)); %detrend
        end

        WVzm(1+nEPOCH*X:length(wv_out)) = wv_out(1+nEPOCH*X:length(wv_out)) ;
          %add on leftover points

    WVzm = WVzm';  %need to take transverse
  
end

