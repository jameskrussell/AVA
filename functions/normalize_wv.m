function wave_normalized = normalize_wv(wave, epoch)
%2/26/14
%ptile = percentile for normalization (50 if median-normalized)
%modification of normalize_wave.m and validWave.m
%median normalization for easy viewing, but not for analysis
%epoch is moving window in seconds to either side
%returns nx1 double (must take transpose at end
ptile = 50;
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

wave_normalized = zeros(1, length(clean_wave));

for i=1:length(clean_wave)
    left = max(1,i-samples);
    right = min(length(clean_wave),left + samples);    
    wave_normalized(i) = clean_wave(i)/prctile(clean_wave(left:right),ptile);
end

wave_normalized = wave_normalized';

end
