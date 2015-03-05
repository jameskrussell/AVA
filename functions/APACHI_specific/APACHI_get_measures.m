function [wave, measure] = APACHI_get_measures(meas_filename, wave, measure)
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
% comment out when called as a function
%  matDir = 'C:\Users\Heemun\Documents\Research\pleth\data\Jim_030314\';  %processed mat files
%   case_dir = 'MUV009.33';
%   load([matDir case_dir '\ABP.mat'])
%   load([matDir case_dir '\trans.mat'])  
%   wave = ABP;
%   wave.trans = trans.ABP;
%   wave.x = wave.T;  %for debug
%   wave.meas = struct(...
%          'label', {'maximum', 'minimum', 'median'}, ...
%          'color', {'red', 'blue', 'green'}, ...
%          'yview', {'ystd', 'ystd', 'ystd'}...
%      );  %from default_wave_param
%   
 
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
    if any(strcmp(wave.trans{j,2}, {'occluded', 'artifact', 'blood draw', 'Start wave'}))
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
  end_pt = start_pt + wave.sps * epoch_t;
  
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
            clip = y(start_pt:end_pt) * 1000; 
            for k = 1:size(wave.meas, 2)
               wave.meas(k).x(ind) = wave.x(end_pt); 
               switch wave.meas(k).label
                   case 'maximum'
                       wave.meas(k).y(ind) = max(clip);
                   case 'minimum'
                       wave.meas(k).y(ind) = min(clip);                       
                   case 'median'
                       wave.meas(k).y(ind) = median(clip);                                              
               end               
            end           
          end
          start_pt = start_pt + wave.sps;  %advance one second
          end_pt = start_pt + wave.sps * epoch_t; 
      end
  end
  
%% standardize
for k = 1:length(wave.meas)
   wave.meas(k).ystd = (wave.meas(k).y - mean(wave.meas(k).y)) / std(wave.meas(k).y);
%%%   wave.meas(k).ystd = (wave.meas(k).y);% - mean(wave.meas(k).y)) / std(wave.meas(k).y);
end

measure.(wave.file) = wave.meas;
save(meas_filename, 'measure')     
  
end

