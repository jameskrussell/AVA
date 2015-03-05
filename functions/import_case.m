function [wvs, wv_loaded, wv_label, max_time, patient, measure, trans, shifts, ...
    trans_filename, shifts_filename, meas_filename] = import_case(case_dir, case_id, wvs, wv_files, ...
    wv_fields_import, meas_fields_import, epoch_mean_center, epoch_norm, patient, patient_variables_import,...
    measure, auto_code)
%2/10/2014

%
%inputs:
% case_dir = case-specific folder
% wvs (field have default parameters)
% wv_files = wvs to load, if they exist (defined in default_wave_parameters.m)
% wv_fields_import = fields of wvs struct to load, if exist (defined in default_wave_parameters.m)
% measure and meas_fields_import
% epoch_mean_center, epoch_norm, auto_code are passed on to
% patient struct (with default parameters) and patient_variables_import

%also makes max_time variable

%% nested functions

    function  [x_valid, x_invalid] = separate_wave_X_by_validity(wave_x, wave_valid)
        x_valid = wave_x;
        invalidIdxs = wave_valid ~=1;
        x_valid(invalidIdxs) = NaN;
        
        x_invalid = wave_x;
        validIdxs = wave_valid ==1;
        x_invalid(validIdxs) = NaN;
    end

    function  [y_valid, y_invalid] = separate_wave_Y_by_validity(wave_y, wave_valid)
        y_valid = wave_y;
        invalidIdxs = wave_valid ~=1;
        y_valid(invalidIdxs) = NaN;
        
        y_invalid = wave_y;
        validIdxs = wave_valid ==1;
        y_invalid(validIdxs) = NaN;
    end


%%
wv_loaded = [];  %clears wv_loaded
wv_label = cell(1, length(wv_files));


%% load  measure file that contains trans and measure fields for all waves and
%patient
trans_filename = [case_dir 'trans_' case_id '.mat'];  
if exist(trans_filename, 'file')
  load(trans_filename);  %load trans struct
end

shifts_filename = [case_dir 'shifts_' case_id '.mat'];  
if exist(shifts_filename, 'file')
  load(shifts_filename);  %load trans struct
else
  shifts = struct;   
end

meas_filename = [case_dir 'measures_' case_id '.mat'];  
if exist(meas_filename, 'file')
  M = load(meas_filename);  %load measure struct into M
end
    
    
%% load patient variables
for i = 1: length(patient_variables_import)
   var_filename = [case_dir patient_variables_import{i} '.mat']; 
   if exist(var_filename, 'file')
      P= load(var_filename);
      patient.(patient_variables_import{i}) = P.(patient_variables_import{i});
   end
end




%% to load waves: (1) import fields from wave mat file; (2) make trans array 

function [trans] = make_default_trans(wave, auto_code)  
% creates default trans cell array for a given wave
% Start wave and End wave created at beginning and end, as long as not empty
    trans = cell(2, 4);  
    if ~isempty(wave)     
      trans(1, 1:4) = {0, 'Start wave', 'menu', auto_code};
      trans(2, 1:4) = {wave.T(end), 'End wave', 'menu',  auto_code};
    end
end


for i = 1:length(wv_files)
    filename = [case_dir wv_files{i} '.mat'];
  
    if exist(filename, 'file')
        S = load(filename);
        
        for j = 1:length(wv_fields_import)    %loop over fields to import
            if isfield(S.(wv_files{i}), wv_fields_import{j})
                wvs(i).(wv_fields_import{j}) = S.(wv_files{i}).(wv_fields_import{j});
            end
        end

        %time vector
        if size(wvs(i).T, 1) == 1  %horizontal vector
          wvs(i).x = wvs(i).T';
        else
          wvs(i).x = wvs(i).T;
        end
        
        %make trans field if it doesn't exist already or is empty (otherwise will overwrite)
            if exist('trans', 'var')
                if isfield(trans, wv_files{i})
                    if isempty(trans.(wv_files{i}))
                        overwrite_trans_wv = 1;
                    else overwrite_trans_wv = 0;
                    end
                else overwrite_trans_wv = 1;
                end
            else overwrite_trans_wv = 1;
            end
            
            if overwrite_trans_wv                
                [trans.(wv_files{i})] = make_default_trans(wvs(i), auto_code);  
            end
            wvs(i).trans = trans.(wv_files{i});
        
        %make field: y
            switch wvs(i).yview
                case 'raw'
                    if size(wvs(i).waveform, 1) == 1  %horizontal vector
                      wvs(i).y = wvs(i).waveform';
                    else
                      wvs(i).y = wvs(i).waveform;
                    end  
                case 'zeromean_quick' 
                    y = wvs(i).waveform;
                    y(isnan(y)) = 0;
                    wvs(i).y = ConvertWV_zeromean_quick(y, epoch_mean_center, wvs(i).sps);  
                case 'zeromean_slow' 
                    wvs(i).y = ConvertWV_zeromean_slow(wvs(i), epoch_mean_center);                   
                case 'median_norm'
                    wvs(i).y = normalize_wv(wvs(i), epoch_norm);
                case 'nonlinear_norm'
                    wvs(i).y = wvs(i).waveform_n;
                case 'log_median_norm'
                    wave_norm = normalize_wv(wvs(i), epoch_norm);
                    wvs(i).y = log(wave_norm);
            end

        % make y_valid, x_valid, x_invalid    
        if isfield(wvs(i), 'Valid')
            [wvs(i).x_valid, wvs(i).x_invalid] = separate_wave_X_by_validity(wvs(i).x, wvs(i).Valid);
            [wvs(i).y_valid, wvs(i).y_invalid] = separate_wave_Y_by_validity(wvs(i).y, wvs(i).Valid);
        end
            
            
        %if this wave may be shifted, then incorporate tabulated shifts into y
        if exist('shifts', 'var')
           if isfield(shifts, wv_files{i})
            shift1 = shifts.(wv_files{i});
            for j=1:size(shift1, 1)
                time_shift(1) = shift1{j,1};
                time_shift(2) = shift1{j,2};
                
                x1 = find(wvs(i).x <= time_shift(1), 1, 'last');  %closest index to 1st time
                x2 = find(wvs(i).x <= time_shift(2), 1, 'last');
                
                npts = abs(x2 - x1);  %take absolute value
                len = length(wvs(i).y);
                if x2 > x1
                    wvs(i).y(x2:len) = wvs(i).y(x1:(len-npts));
                    wvs(i).y(x1:(x2-1)) = wvs(i).y(x1-1) * ones(1, npts);
                    %repeats last value before x1 for npts
                else  % x2 < x1
                    temp = wvs(i).y(x1:len);
                    wvs(i).y(x2:(x2 + length(temp)-1)) = temp;
                    wvs(i).y((x2 + length(temp)) : len) = wvs(i).y(len-npts) * ones(1, npts);
                    %repeats last value for npts
                end
            end
           end  
        end
          
        % load measures from M.measure, if it exists, and combine with
        % measure struct defaults
        % otherwise add empty fields            
            if exist('M', 'var')
                if isfield(M.measure, wvs(i).file)
                   load_meas = 1;
                else load_meas = 0;
                end
            else load_meas = 0;
            end
            
            if load_meas
            for j = 1:length(meas_fields_import)    %loop over fields, eg x, y, ystd
                for k = 1:length(wvs(i).meas)       %loop over each measure, eg median, max, min
                  %next 2 lines find index of M.measure that matches with wvs.meas, if any  
                  match = strcmp(wvs(i).meas(k).label, {M.measure.(wvs(i).file).label}); 
                  which = find(match, 1, 'first');
                  if load_meas && ~isempty(which) && isfield(wvs(i).meas(k), meas_fields_import{j}) 
                      if ~isempty(wvs(i).meas(k).(meas_fields_import{j}))
                        measure.(wvs(i).file)(k).(meas_fields_import{j}) = M.measure.(wvs(i).file)(which).(meas_fields_import{j});
                      else
                        measure.(wvs(i).file)(k).(meas_fields_import{j}) = []; 
                      end
                  else
                      measure.(wvs(i).file)(k).(meas_fields_import{j}) = [];
                  end                      
                  wvs(i).meas(k).(meas_fields_import{j}) = measure.(wvs(i).file)(k).(meas_fields_import{j});
                end
            end
            end
            
        % save
        wv_loaded = [wv_loaded i];
        wv_label{i} = wvs(i).label;
        clear S SS  overwrite_trans_wv load_meas
    end
end

all_times = vertcat(wvs(1:length(wv_files)).x);
max_time = max(all_times);


%% Load or create trans field of patient 
% must place after loading waves, because requires max_time

   
if exist('trans', 'var')   
    if isfield(trans, 'patient')
        if isempty(trans.patient)
            overwrite_trans_pt = 1;
        else overwrite_trans_pt = 0;
        end
    else overwrite_trans_pt = 1;
    end
else overwrite_trans_pt = 1;
end

    if overwrite_trans_pt   %add a start and end
        trans.patient = cell(0,4);
        trans.patient{1,1} = 0;
        trans.patient{1,2} = 'No CPR';
        trans.patient{1,3} = 'cpr';
        trans.patient{1,4} = auto_code;
        
        trans.patient{2,1} = max_time;
        trans.patient{2,2} = 'No CPR';
        trans.patient{2,3} = 'cpr';
        trans.patient{2,4} = auto_code;           
    end
    
patient.trans = trans.patient;
clear overwrite_trans_pt







end
