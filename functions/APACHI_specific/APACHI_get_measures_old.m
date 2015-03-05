function [wave, measure] = APACHE_get_measures(meas_filename, wave, measure)

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
 
%% get measures as long as there is > 3.8 sec of valid waveform 




















valid_rows = find(strcmp(wave.trans(:,2), 'valid'));
c = 1; %counter across all rows

for j = 1:(length(valid_rows) - 1)
   row1 = valid_rows(j);
   row2 = row1 + 1;
   starttime = wave.trans{row1,1};
   endtime = min([wave.trans{row2,1} max(wave.x)]); 
   
   if (endtime - starttime >= 3.8)  
          n_epoch = floor(endtime-starttime-3.8) + 1;  %rounds down
          epoch_end_t = starttime + 3.8;

          for i = 1:n_epoch
             epoch_end_pt = find(wave.x <= epoch_end_t, 1, 'last'); 
             epoch_start_pt = epoch_end_pt - wave.sps * 3.8;

             clip = wave.waveform(epoch_start_pt:epoch_end_pt);
             for k = 1:length(wave.meas)
               wave.meas(k).x(c) = epoch_end_t;
               switch wave.meas(k).label
                   case 'maximum'
                       wave.meas(k).y(c) = max(clip);
                   case 'minimum'
                       wave.meas(k).y(c) = min(clip);                       
                   case 'median'
                       wave.meas(k).y(c) = median(clip);                                              
               end    
               
             end
             epoch_end_t = epoch_end_t + 1;  %march forward 1 sec
             c = c + 1;
          end          
   end
end

%% standardize
for k = 1:length(wave.meas)
   wave.meas(k).ystd = (wave.meas(k).y - mean(wave.meas(k).y)) / std(wave.meas(k).y);
end

measure.(wave.file) = wave.meas;
save([case_dir '\measure'], 'measure')     


%end

       
  



%%        

%     function calculate_measures(starttime, endtime, wave)
%         endtime2 = min([endtime max(wave.x)]);   %smaller of end of wave.x and endtime
% 
%         if endtime2-starttime >= 3.8
%           n_epoch = floor(endtime2-starttime-3.8) + 1;  %rounds down
%           meas_table_1 = zeros(n_epoch,5);  %{endtime, map, sbp, dbp}
% 
%           epoch_end_t = starttime + 3.8;
% 
%           for i = 1:n_epoch
%              epoch_end_pt = find(wave.x <= epoch_end_t, 1, 'last');  %end of 3.8 sec clip in points
%                %epoch_end_pt = round(epoch_end_t * 250); 
%              epoch_start_pt = epoch_end_pt - wave.sps * 3.8;  %start of 950 pt clip in points
% 
%              clip = wave.waveform(epoch_start_pt:epoch_end_pt);
% 
%               map = median(clip); 
%               sbp = max(clip);
%               dbp = min(clip);
% 
%               meas_table_1(i,:) = [epoch_end_t, map, sbp, dbp];  %assigns row
%               epoch_end_t = epoch_end_t + 1;  %march forward 1 sec
%           end
% 
%           meas_table_4 = meas_table_1(1:4:end, : );  %gets every 4th value starting with the 1st
% 
%         else
%            meas_table_1 = [];
%            meas_table_4 = [];
%         end
% 
%     end

%end
