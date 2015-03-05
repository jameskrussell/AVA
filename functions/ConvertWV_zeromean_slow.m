function wave_zeromean = ConvertWV_zeromean_slow(wave, epoch)
%2/26/14
%ptile = percentile for normalization (50 if median-normalized)
%modification of normalize_wave.m and validWave.m
%median normalization for easy viewing, but not for analysis
%epoch is moving window in seconds to either side
%returns nx1 double (must take transpose at end
%load('lp60.mat')
samples = epoch * wave.sps / 2;  %epoch in pts. each epoch centered around each point.

vWave = wave.waveform; %valid wave

% tidy up beginning, end before naninterp to avoid meaningless filter disruptions
    % set leading NaNs to first valid value
    firstgood = find(~isnan(vWave),1,'first');
    vWave(1:firstgood) = vWave(firstgood);
    % set (now, possibly) leading 0's to 1st non-0 value
    firstgood = find(vWave,1,'first');
    vWave(1:firstgood) = vWave(firstgood);

% tidy up end
    % set trailing NaNs to last valid value
    lastgood = find(~isnan(vWave),1,'last');
    vWave(lastgood:end) = vWave(lastgood);
    % set (now, possibly) trailing 0's to last non-0 value (avoids filter disruption)
    lastgood = find(vWave,1,'last');
    vWave(lastgood:end) = vWave(lastgood);

function X = naninterp(X)
% Interpolate over NaNs
    X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)), 'cubic');
end

clean_wave = naninterp(vWave);

wave_zeromean = zeros(1, length(clean_wave));

for i=1:length(clean_wave)
    left = max(1,i-samples);
    right = min(length(clean_wave),left + samples);  
    epoch_mean = mean(clean_wave(left:right));
    wave_zeromean(i) = clean_wave(i) - epoch_mean;
    
    %wave_zeromean(i) = clean_wave(i)/prctile(clean_wave(left:right),ptile);
end

wave_zeromean = wave_zeromean';

end


%     load('lp60.mat')
% 
%     wv_out=filtfilt(lp60.Numerator, 1, wv_in); %zero-phase filtering
%     X = time_epoch * sampleRate;  %length of epoch in pts;
%     nEPOCH = floor(length(wv_out)/X);  %number of epochs
% 
%         for k=0:nEPOCH-1 % so we don't run over the end 
%            meanEPOCH = nanmean(wv_out(1+k*X:(k+1)*X )); 
%            WVzm(1+k*X:(k+1)*X) = wv_out(1+k*X:(k+1)*X) - meanEPOCH; %subtract mean
%            WVzm(1+k*X:(k+1)*X) = detrend(WVzm(1+k*X:(k+1)*X)); %detrend
%         end
% 
%         WVzm(1+nEPOCH*X:length(wv_out)) = wv_out(1+nEPOCH*X:length(wv_out)) ;
%           %add on leftover points
% 
%     WVzm = WVzm';  %need to take transverse


