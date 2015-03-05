function [wvs, wv_files, wv_fields_import, meas_fields_import, epoch_mean_center, epoch_norm, ...
    patient, patient_variables_import, measure, auto_code, default_initial_wvs,...
    cpr_uicontrol, wv_enable_shift, wv_enable_measure, plot_valid, min_xrange] =...
     clip_default_wave_parameters()
% identifies waveforms and default parameters
% these parameters are the same for every case
% there will be a different version, depending upon data source, eg MRX v pleth
% also identifies fields of waveform structs to import from raw data files

%% Misc
  cpr_uicontrol = 'h_annot_cpr_clip'; 
  plot_valid = 0;
  min_xrange = 10;
  
%% patient:
 annot_intervent = {{'Shock', 'Epinephrine', 'Lidocaine', 'Amiodarone', 'ETI unsuccessful' 'ETI successful'}};
 annot_cpr = {{}};
 color_cpr = {{}};  %order same as annot_cpr
 patient_variables_import =  {'events', 'ClinData'}; 
 patient = struct('annot_intervent', annot_intervent, 'annot_cpr', annot_cpr, 'color_cpr', color_cpr);


%% wavestructs
wv_files = {'ECG1', 'PCI', 'FORC'};
wv_fields_import =  {'T', 'waveform', 'sps',  'shifts'};

meas_fields_import = {'x', 'y', 'ystd'};
epoch_mean_center = 20;  %for detrending and mean-centering waves
epoch_norm = 20;  %for median normalization
auto_code = 'auto';  %label for automatic annotation; pass to pleth_import_case -> Valid_to_trans_v1
default_initial_wvs = (1:3);  %numbers refer to wv_files index
wv_enable_shift = (3);
wv_enable_measure = (1);
%parameters: color, fill, annotation options, yview, default y limit 
    %yview options = 'raw', 'zeromean', 'median_norm', 'nonlinear_norm', 'log_median_norm',
    ir_limits = [1e04 1e06];
    median_norm_limits = [0.97 1.03];
    nonlinear_norm_limits = [-3 3];

  
%ECG1
  color_ECG1 = 'blue';
  label_ECG1 = 'ECG';
  annot_opts_ECG1 = {'VT','VF', 'Asystole-vf','Asystole-20','Asystole-other', 'Org Vent Act', ...
      'NonPerfusingActivity','Rhythm Unknown', 'ECG Artifact'};
  fill_ECG1 = struct(...
     'red', {{'VF', 'VT'}},...
      'cyan', {{}},...
      'magenta', {{'NonPerfusingActivity'}},...
     'green', {{'Organized','Org Vent Act'}}, ...
     'yellow', {{'Asystole','Asystole-20', 'Asystole-org', 'Asystole-vf', 'Asystole-other', 'Asystole-NOS'}}, ...
     'black', {{'Shock Start'}}, ...
     'white', {{ 'Start wave', 'Shock End', 'End wave'}}, ...
     'blue', {{'Rhythm Unknown','ECG Artifact'}}); %note double brackets to make struct with cell array as field
  yview_ECG1 = 'raw'; 
  ylimit_def_ECG1 = [-2 2];  
  may_shift_ECG1 = 0;
  meas_ECG1 = struct(...
         'label', {'flats', 'clas', 'pk2pk', 'shock dec NN', 'shock prob NN'}, ...
         'color', {'black', 'blue', 'magenta', 'red', 'red'}, ...
         'marker', {'+', '*', '.', 'x', 'o'}, ...
         'yview', {'ystd', 'ystd', 'ystd', 'y', 'y'}...
     );  %from default_wave_param
 
%PCI
  color_PCI = 'red';
  label_PCI = 'impedence';
  annot_opts_PCI = { 'CPR', 'No CPR', 'CPR Artifact'};
  fill_PCI = struct(...
     'red', {{'CPR'}},...
     'cyan', {{}},...
     'magenta', {{}},...
     'green', {{'No CPR'}}, ...
     'yellow', {{}}, ...
     'black', {{'Shock Start'}}, ...
     'white', {{'End wave', 'Shock End'}}, ...
     'blue', {{'CPR Artifact', 'Start wave'}});  
  yview_PCI = 'raw';  ylimit_def_PCI = [0 10000];  
%  yview_PCI = 'zeromean_slow'; ylimit_def_PCI = [-5000 5000];    
%  yview_PCI = 'median_norm'; ylimit_def_PCI = median_norm_limits;    
  may_shift_PCI = 0;
  meas_PCI =   struct(...
         'label', {'maximum', 'minimum', 'median'}, ...
         'color', {'red', 'blue', 'green'}, ...
         'marker', {'+', '*', '.'}, ...
         'yview', {'ystd', 'ystd', 'ystd'}...
     );  

% FORC
  color_FORC = 'magenta';
  label_FORC = 'accelerometer';
  annot_opts_FORC = { 'CPR', 'No CPR', 'CPR Artifact'};
  fill_FORC = fill_PCI; 
  yview_FORC = 'raw'; ylimit_def_FORC = [0 50000];  
%  yview_FORC = 'zeromean_slow'; ylimit_def_FORC = [-10000 50000];  
%  yview_FORC = 'median_norm'; ylimit_def_FORC = median_norm_limits;  
  may_shift_FORC = 0;
  meas_FORC =   struct(...
         'label', {'maximum', 'minimum', 'median'}, ...
         'color', {'red', 'blue', 'green'}, ...
         'marker', {'+', '*', '.'}, ...
         'yview', {'ystd', 'ystd', 'ystd'}...
     );  
 
 
% put all waves into a struct          
  wv_ylimit_default = {ylimit_def_ECG1, ylimit_def_PCI, ylimit_def_FORC};
  wv_color = {color_ECG1, color_PCI, color_FORC};  
  wv_fill = {fill_ECG1, fill_PCI, fill_FORC};
  wv_annot_opts = {annot_opts_ECG1, annot_opts_PCI, annot_opts_FORC};
  wv_yview = {yview_ECG1, yview_PCI, yview_FORC};
  wv_may_shift = {may_shift_ECG1, may_shift_PCI, may_shift_FORC};
  wv_meas = {meas_ECG1, meas_PCI, meas_FORC};
  wv_labels = {label_ECG1, label_PCI, label_FORC};
  
 wvs = struct('file', wv_files, 'label', wv_labels, 'color', wv_color, 'fill', wv_fill, ...
     'annot_opts', wv_annot_opts, 'ylimit_def', wv_ylimit_default,...
     'yview', wv_yview, 'may_shift', wv_may_shift, 'meas', wv_meas);


 for i = 1:length(wv_files)
    measure.(wv_files{i}) = wv_meas{i};
 end
 
end

