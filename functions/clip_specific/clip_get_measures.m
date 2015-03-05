function [wave, measure] = clip_get_measures(meas_filename, wave, measure)
%wave.meas = 1 x n struct with fields label, color, yview, x, y, and ystd
%default_wave_parameters assigns label, color, and yview
%import_case imports meas_fields_import = {'x', 'y', 'ystd'}, from
%measures_CASENO.mat, if it exists
%this function calculates x, y and ystd

%calculates measures for ECG only
%calculates VF measures for entire waveform (except NaN), regardless of
%CPR or true rhythm.  This is faster than calculating segments, etc
%A different script, not part of AVA, will be used to
%divide ECG into segments based upon CPR presence and true underlying rhythm
%(I forget how I did this, but either MRX_rhythm_predict or ExtractECGSegments or GetVWMs.

%adapted from GetVWMs, but unlike GetVWMs, does not use trans, but need to
%exclude artifact.

%% Load case for debugging
%comment out when called as a function
% matDir = 'C:\Users\Heemun\Documents\Research\VF\clip\Data\CASS_matfiles_v1\';
%   case_dir = '1_120517';
%   load([matDir case_dir '\ECG1.mat'])
%   load([matDir case_dir '\trans_' case_dir '.mat'])
%   wave = ECG1;
%   wave.x = wave.T';  %for debug
%   wave.meas = struct(...
%          'label', {'flats', 'clas', 'pk2pk'}, ...
%          'color', {'red', 'blue', 'green'}, ...
%          'yview', {'ystd', 'ystd', 'ystd'}...
%      );  %from default_wave_param
%  wave.trans = trans.ECG1;
% addpath(genpath(pwd))

%%
epoch_t = 3.8; %epoch_t in seconds

wave.trans = sortrows(wave.trans, 1);
n_trans = size(wave.trans, 1);

%make temp x and y vectors
x = wave.x;
%start with n x 1 vector, since x is nx1. make sure to work on original waveform
if size(wave.waveform, 1) == 1  %horizontal vector
    y = wave.waveform';
else
    y = wave.waveform;
end

%change artifacted or shock sections to NaN.
for j = 1:(n_trans-1)
    if any(strcmp(wave.trans{j,2}, {'Start wave',  'End wave', 'Shock Start', 'ECG Artifact'}))
        start_t = wave.trans{j, 1};
        end_t = wave.trans{j+1, 1};
        start_index = find(x >= start_t, 1, 'first');
        end_index = find(x < end_t, 1, 'last');
        y(start_index:end_index) = NaN;
        x(start_index:end_index) = NaN;
    end
end
x(end) = NaN;  %set last value to missing, because this point is not changed by above loop
y(end) = NaN;


%% march by 1 second intervals,
start_pt = find(~isnan(x), 1, 'first');
end_pt = start_pt + wave.sps * epoch_t - 1;  %exactly 950 points
if isempty(start_pt)
    for k = 1:size(wave.meas, 2)
        wave.meas(k).x = [];
        wave.meas(k).y = [];
    end
else
    ind = 0;
    while end_pt < length(x)
        if isempty(find(isnan(x(start_pt:end_pt)), 1))   %check if any nan within this epoch
            ind = ind + 1;
            clip = y(start_pt:end_pt);
            for k = 1:size(wave.meas, 2)   %step through all measures
                wave.meas(k).x(ind) = wave.x(end_pt);
                switch wave.meas(k).label
                    case 'clas'
                        clas = CLAS_mV(clip);
                        wave.meas(k).y(ind) = clas;
                    case 'flats'
                        [flats, ~] = FLATS_mV(clip);
                        wave.meas(k).y(ind) = log10(flats);
                    case 'pk2pk'
                        [pka, ~] = pk2pk_mV(clip);
                        wave.meas(k).y(ind) = log10(pka);
                    case 'shock dec ART'
                        [shockdec, ~] = Rule_Philips102(flats, clas, pka);
                        if shockdec==1  
                          wave.meas(k).y(ind) = 3;  %rather than 0,1, plots SD at -3 and 3 for better visibility.
                        else
                          wave.meas(k).y(ind) = -3;
                        end
                    case 'shock prob NN'
                        [~, shockProb] = prob_ART_nn(clip);
                        wave.meas(k).y(ind) = (shockProb - 0.5) * 6;  %convert to scale 
                             %from -3 to 3 to match shockdec  
                    case 'shock dec NN'
                        [shockdec, ~] = prob_ART_nn(clip);
                        if shockdec==1  
                          wave.meas(k).y(ind) = 3;  %rather than 0,1, plots SD at -3 and 3 for better visibility.
                        else
                          wave.meas(k).y(ind) = -3;
                        end                                                 
                end
            end
        end
        start_pt = start_pt + wave.sps;  %advance one second
        end_pt = start_pt + wave.sps * epoch_t - 1;
    end
end

%% standardize
for k = 1:length(wave.meas)
    wave.meas(k).ystd = (wave.meas(k).y - mean(wave.meas(k).y)) / std(wave.meas(k).y);
end

measure.(wave.file) = wave.meas;
save(meas_filename, 'measure')

end

