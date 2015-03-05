function [wvs, wv_files, wv_fields_import, meas_fields_import, epoch_mean_center, epoch_norm, ...
    patient, patient_variables_import, measure, auto_code, default_initial_wvs, ...
    cpr_uicontrol, wv_enable_shift, wv_enable_measure, plot_valid, min_xrange] =...
     APACHI_default_wave_parameters()
% identifies waveforms and default parameters
% these parameters are the same for every case
% there will be a different version, depending upon data source, eg MRX v
%pleth
% also identifies fields of waveform structs to import from raw data files

% notes for editors:
% Every waveform type must be declared in wv_files, and have declarations
% for wv_ylimit_default, wv_color, wv_fill, wv_annot_opts, wv_yview,
% wv_may_shift, wv_meas, and these must be placed into the wvs struct at
% the end of this file.  The order the files are loaded controls the order
% in which they appear in the dropdown menu for Wave in the GUI (so, put
% the ones you'll use most early in the list).  The same order must be used
% in wv_files as in wvs.

%annot_Team = 'Technical';

global annot_Team;

if ~exist('annot_Team','var')
    error('annot_Team undefined');
    return
end
%% Misc
cpr_uicontrol = 'h_annotate_cpr_ava';
plot_valid = 0;
min_xrange = 10;
%min_xrange = 1; % as used in v.1.4

%% patient:
annot_intervent = {{'Shock', 'ECLS', 'Epinephrine', 'Lidocaine', 'Dopamine'}};
 annot_cpr = {{'CPR', 'No CPR', 'CPR unknown'}};
 color_cpr = {{'red', 'white', 'blue'}};  %order same as annot_cpr
 patient_variables_import =  {};  
 patient = struct('annot_intervent', annot_intervent, 'annot_cpr', annot_cpr, 'color_cpr', color_cpr);


annot_Team
%% wavestructs
if strcmp(annot_Team,'Clinical')
    wv_files = {'ABP', 'ECG', 'CO2', 'IPleth','NPleth'};
elseif strcmp(annot_Team,'Technical')
    wv_files = {'ABP','NicoIR','Oxy1IR', 'Oxy2IR', 'ECG', 'CO2', 'IPleth', 'NPleth', 'Oxy1R', 'Oxy2R', 'NicoR'};
elseif strcmp(annot_Team,'UBC')
    wv_files = {'ABP','ECG', 'CO2', 'Flow', 'Pressure', 'Volume','IPleth','NPleth'};
else
    error('annot_Team unrecognized')
end

wv_fields_import =  {'waveform', 'waveform_n', 'sps', 'T', 'Valid', 'label'};
meas_fields_import = {'x', 'y', 'ystd'};
epoch_mean_center = 10;  %for detrending and mean-centering waves
epoch_norm = 10;  %for median normalization
auto_code = 'auto';  %label for automatic annotation; pass to pleth_import_case -> Valid_to_trans_v1
if strcmp(annot_Team,'Clinical')
    default_initial_wvs = (1:4);  %numbers refer to wv_files index
else
    default_initial_wvs = (1:4);  %numbers refer to wv_files index
end
wv_enable_shift = (2:4);
wv_enable_measure = (1:4);


%parameters: color, fill, annotation options, yview, default y limit
%yview options = 'raw', 'zeromean', 'median_norm', 'nonlinear_norm', 'log_median_norm',
rawPPG_limits = [1e04 1e06];
median_norm_limits = [0.97 1.03];
nonlinear_norm_limits = [-3 3];
zeromean_limits = [-1000 1000];

%ABP
color_ABP = 'blue';
annot_opts_ABP = { 'valid', 'occluded', 'artifact', 'blood draw'};
%fill_ABP = struct('blue', {{'occluded', 'artifact', 'blood draw', 'Start wave'}},... % was in v.1.4
fill_ABP = struct('blue', {{'occluded', 'artifact', 'blood draw'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
         'cyan', {{}},...
         'magenta', {{}},...
    'black', {{'not valid'}},...
    'white', {{}});  %note double brackets to make struct with cell array as field

yview_ABP = 'raw';
%ylimit_def_ABP = [0 200];
ylimit_def_ABP = [-10 200]; % jkr
may_shift_ABP = 0;
meas_ABP =   struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                         'marker', {'+', '*', '.'}, ... %%%
    'yview', {'ystd', 'ystd', 'ystd'}...
    );

%CO2
color_CO2 = 'b';
annot_opts_CO2 = {'valid', 'artifact'};
fill_CO2 = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
         'cyan', {{}},...
         'magenta', {{}},...
    'black', {{'not valid'}},...
    'white', {{}});
yview_CO2 = 'raw';
ylimit_def_CO2 = [0 60];
may_shift_CO2 = 0;
meas_CO2 =  struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                     'marker', {'+', '*', '.'}, ... % v.1.4 required this
    'yview', {'ystd', 'ystd', 'ystd'}...
    );

%%%%%%
%Flow
color_Flow = 'b';
     %label_Flow = 'Flow';
annot_opts_Flow = {'valid', 'artifact'};
fill_Flow = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
             'cyan', {{}},...
         'magenta', {{}},...   
    'black', {{'not valid'}},...
    'white', {{}});
yview_Flow = 'raw';
ylimit_def_Flow = [0 60];
may_shift_Flow = 0;
meas_Flow =  struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                 'marker', {'+', '*', '.'}, ...
    'yview', {'ystd', 'ystd', 'ystd'}...
    );
%Pressure
color_Pressure = 'b';
%     label_Pressure = 'Pressure';
annot_opts_Pressure = {'valid', 'artifact'};
fill_Pressure = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
             'cyan', {{}},...
         'magenta', {{}},...   
    'black', {{'not valid'}},...
    'white', {{}});
yview_Pressure = 'raw';
ylimit_def_Pressure = [0 60];
may_shift_Pressure = 0;
meas_Pressure =  struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                 'marker', {'+', '*', '.'}, ...
    'yview', {'ystd', 'ystd', 'ystd'}...
    );
%Volume
color_Volume = 'b';
%     label_Volume = 'Volume';
annot_opts_Volume = {'valid', 'artifact'};
fill_Volume = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
             'cyan', {{}},...
         'magenta', {{}},...   
    'black', {{'not valid'}},...
    'white', {{}});
yview_Volume = 'raw';
ylimit_def_Volume = [0 60];
may_shift_Volume = 0;
meas_Volume =  struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                 'marker', {'+', '*', '.'}, ...
    'yview', {'ystd', 'ystd', 'ystd'}...
    );



%%%%%%

%IPleth (the finger oximeter from the Intellivue - processed, not raw,
%waveforms
color_IPleth = 'b';
annot_opts_IPleth = {'valid', 'artifact'};
fill_IPleth = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
         'cyan', {{}},...
         'magenta', {{}},...
    'black', {{'not valid'}},...
    'white', {{}});
yview_IPleth = 'raw';
ylimit_def_IPleth = [0 4500];
may_shift_IPleth = 0;
meas_IPleth =  struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                     'marker', {'+', '*', '.'}, ... %%%
    'yview', {'ystd', 'ystd', 'ystd'}...
    );

%NPleth (the finger oximeter from the NICO - processed, not raw,
%waveforms
color_NPleth = 'b';
annot_opts_NPleth = {'valid', 'artifact'};
fill_NPleth = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
             'cyan', {{}},...
         'magenta', {{}},...
    'black', {{'not valid'}},...
    'white', {{}});
yview_NPleth = 'raw';
ylimit_def_NPleth = [0 100];
may_shift_NPleth = 0;
meas_NPleth =  struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                     'marker', {'+', '*', '.'}, ... %%%
    'yview', {'ystd', 'ystd', 'ystd'}...
    );

% common values for rawPPG signals (NicoIR, NicoR, Oxy1IR, Oxy1R, Oxy2IR,
% Oxy2R
annot_opts_rawPPG = {'valid', 'artifact'};
fill_rawPPG = struct('blue', {{'artifact'}},...
    'green', {{'valid'}}, ...
    'red', {{}},...
    'yellow', {{}},...
             'cyan', {{}},...
         'magenta', {{}},...
    'black', {{'not valid'}},...
    'white', {{}});
yview_rawPPG = 'raw';
ylimit_def_rawPPG = rawPPG_limits;
meas_rawPPG = struct(...
    'label', {'maximum', 'minimum', 'median'}, ...
    'color', {'red', 'blue', 'green'}, ...
                 'marker', {'+', '*', '.'}, ... %%%
    'yview', {'ystd', 'ystd', 'ystd'}...
    );

%NicoIR (FingerIR)
color_NicoIR = 'm';
%     label_NicoIR = 'FingerIR'; %%%
annot_opts_NicoIR = annot_opts_rawPPG;
fill_NicoIR = fill_rawPPG;
yview_NicoIR = yview_rawPPG;
ylimit_def_NicoIR = ylimit_def_rawPPG;
may_shift_NicoIR = 0;
meas_NicoIR =  meas_rawPPG;

%NicoR (FingerR)
color_NicoR = 'r';
%     label_NicoR = 'FingerR'; %%%
annot_opts_NicoR = annot_opts_rawPPG;
fill_NicoR = fill_rawPPG;
yview_NicoR = yview_rawPPG;
ylimit_def_NicoR = ylimit_def_rawPPG;
may_shift_NicoR = 0;
meas_NicoR =  meas_rawPPG;

%Oxy1IR (NoseIR)
color_Oxy1IR = 'm';
%     label_Oxy1IR = 'NoseIR'; %%%
annot_opts_Oxy1IR = annot_opts_rawPPG;
fill_Oxy1IR = fill_rawPPG;
yview_Oxy1IR = yview_rawPPG;
ylimit_def_Oxy1IR = ylimit_def_rawPPG;
may_shift_Oxy1IR = 0;
meas_Oxy1IR =  meas_rawPPG;

%Oxy1R (NoseR)
color_Oxy1R = 'r';
%     label_Oxy1R = 'NoseR'; %%%
annot_opts_Oxy1R = annot_opts_rawPPG;
fill_Oxy1R = fill_rawPPG;
yview_Oxy1R = yview_rawPPG;
ylimit_def_Oxy1R = ylimit_def_rawPPG;
may_shift_Oxy1R = 0;
meas_Oxy1R =  meas_rawPPG;


%Oxy2IR (EarIR)
color_Oxy2IR = 'm';
%     label_Oxy2IR = 'EarIR'; %%%
annot_opts_Oxy2IR = annot_opts_rawPPG;
fill_Oxy2IR = fill_rawPPG;
yview_Oxy2IR = yview_rawPPG;
ylimit_def_Oxy2IR = ylimit_def_rawPPG;
may_shift_Oxy2IR = 0;
meas_Oxy2IR =  meas_rawPPG;

%Oxy2R (EarR)
color_Oxy2R = 'r';
%     label_Oxy2R = 'EarR'; %%%
annot_opts_Oxy2R = annot_opts_rawPPG;
fill_Oxy2R = fill_rawPPG;
yview_Oxy2R = yview_rawPPG;
ylimit_def_Oxy2R = ylimit_def_rawPPG;
may_shift_Oxy2R = 0;
meas_Oxy2R =  meas_rawPPG;



%ECG (note that for clip, this is called ECG1)
  color_ECG = 'blue';
%  label_ECG = 'ECG';
  annot_opts_ECG = {'VT','VF', 'Asystole-vf','Asystole-20','Asystole-other', 'Org Vent Act', ...
      'NonPerfusingActivity','Rhythm Unknown', 'ECG Artifact'};
  fill_ECG = struct(...
     'red', {{'VF', 'VT'}},...
      'cyan', {{}},...
      'magenta', {{'NonPerfusingActivity'}},...
     'green', {{'Organized','Org Vent Act'}}, ...
     'yellow', {{'Asystole','Asystole-20', 'Asystole-org', 'Asystole-vf', 'Asystole-other', 'Asystole-NOS'}}, ...
     'black', {{'Shock Start'}}, ...
     'white', {{ 'Start wave', 'Shock End', 'End wave'}}, ...
     'blue', {{'Rhythm Unknown','ECG Artifact'}}); %note double brackets to make struct with cell array as field 
  yview_ECG = 'raw'; 
  ylimit_def_ECG = [-2 2];  
  may_shift_ECG = 0;
  meas_ECG = struct(...
         'label', {'flats', 'clas', 'pk2pk', 'shock dec NN', 'shock prob NN'}, ...
         'color', {'black', 'blue', 'magenta', 'red', 'red'}, ...
         'marker', {'+', '*', '.', 'x', 'o'}, ...
         'yview', {'ystd', 'ystd', 'ystd', 'y', 'y'}...
     );  %from default_wave_param
 
 
% put all waves into a struct
%if strcmp(annot_Team,'Clinical')
%    wv_ylimit_default = {ylimit_def_ABP,ylimit_def_ECG, ylimit_def_CO2, ylimit_def_IPleth, ylimit_def_NPleth};
%    wv_color = {color_ABP, color_ECG, color_CO2, color_IPleth, color_NPleth};
%    wv_fill = {fill_ABP, fill_ECG, fill_CO2, fill_IPleth, fill_NPleth};
%    wv_annot_opts = {annot_opts_ABP,annot_opts_ECG, annot_opts_CO2, annot_opts_IPleth, annot_opts_NPleth};
%    wv_yview = {yview_ABP, yview_ECG, yview_CO2, yview_IPleth, yview_NPleth};
%    wv_may_shift = {may_shift_ABP, may_shift_ECG, may_shift_CO2, may_shift_IPleth, may_shift_NPleth};
%    wv_meas = {meas_ABP, meas_ECG, meas_CO2, meas_IPleth, meas_NPleth};
%    
%elseif strcmp(annot_Team,'Technical')
%    wv_ylimit_default = {ylimit_def_ABP, ylimit_def_NicoIR,ylimit_def_Oxy1IR, ylimit_def_Oxy2IR,ylimit_def_ECG, ylimit_def_CO2, ylimit_def_IPleth, ylimit_def_NPleth,  ylimit_def_Oxy1R, ylimit_def_Oxy2R, ylimit_def_NicoR };
%    wv_color = {color_ABP, color_NicoIR,color_Oxy1IR,  color_Oxy2IR,color_ECG, color_CO2, color_IPleth, color_NPleth,  color_Oxy1R, color_Oxy2R, color_NicoR};
%    wv_fill = {fill_ABP,fill_NicoIR,  fill_Oxy1IR, fill_Oxy2IR,fill_ECG, fill_CO2, fill_IPleth, fill_NPleth,  fill_Oxy1R, fill_Oxy2R, fill_NicoR};
%    wv_annot_opts = {annot_opts_ABP,annot_opts_NicoIR,annot_opts_Oxy1IR, annot_opts_Oxy2IR,annot_opts_ECG, annot_opts_CO2, annot_opts_IPleth, annot_opts_NPleth,  annot_opts_Oxy1R, annot_opts_Oxy2R,annot_opts_NicoR};
%    wv_yview = {yview_ABP, yview_NicoIR, yview_Oxy1IR, yview_Oxy2IR, yview_ECG, yview_CO2, yview_IPleth,yview_NPleth, yview_Oxy1R, yview_Oxy2R, yview_NicoR};
%    wv_may_shift = {may_shift_ABP,may_shift_NicoIR,may_shift_Oxy1IR, may_shift_Oxy2IR, may_shift_ECG, may_shift_CO2, may_shift_IPleth, may_shift_NPleth,  may_shift_Oxy1R, may_shift_Oxy2R,may_shift_NicoR};
%    wv_meas = {meas_ABP, meas_NicoIR,meas_Oxy1IR, meas_Oxy2IR, meas_ECG, meas_CO2, meas_IPleth, meas_NPleth,  meas_Oxy1R, meas_Oxy2R, meas_NicoR};
if strcmp(annot_Team,'Clinical')
    wv_ylimit_default = {ylimit_def_ABP,ylimit_def_ECG, ylimit_def_CO2, ylimit_def_IPleth, ylimit_def_NPleth};
%      wv_labels = {label_ABP, label_ECG, label_CO2, label_IPleth, label_NPleth};
    wv_color = {color_ABP, color_ECG, color_CO2, color_IPleth, color_NPleth};
    wv_fill = {fill_ABP, fill_ECG, fill_CO2, fill_IPleth, fill_NPleth};
    wv_annot_opts = {annot_opts_ABP,annot_opts_ECG, annot_opts_CO2, annot_opts_IPleth, annot_opts_NPleth};
    wv_yview = {yview_ABP, yview_ECG, yview_CO2, yview_IPleth, yview_NPleth};
    wv_may_shift = {may_shift_ABP, may_shift_ECG, may_shift_CO2, may_shift_IPleth, may_shift_NPleth};
    wv_meas = {meas_ABP, meas_ECG, meas_CO2, meas_IPleth, meas_NPleth};
    
elseif strcmp(annot_Team,'Technical')
    wv_ylimit_default = {ylimit_def_ABP, ylimit_def_NicoIR,ylimit_def_Oxy1IR, ylimit_def_Oxy2IR,ylimit_def_ECG, ylimit_def_CO2, ylimit_def_IPleth, ylimit_def_NPleth,  ylimit_def_Oxy1R, ylimit_def_Oxy2R, ylimit_def_NicoR };
%      wv_labels = {label_ABP, label_NicoIR, label_Oxy1IR, label_Oxy2IR,label_ECG, label_CO2, label_IPleth, label_NPleth, label_Oxy1R, label_Oxy2R, label_NicoR};
    wv_color = {color_ABP, color_NicoIR,color_Oxy1IR,  color_Oxy2IR,color_ECG, color_CO2, color_IPleth, color_NPleth,  color_Oxy1R, color_Oxy2R, color_NicoR};
    wv_fill = {fill_ABP,fill_NicoIR,  fill_Oxy1IR, fill_Oxy2IR,fill_ECG, fill_CO2, fill_IPleth, fill_NPleth,  fill_Oxy1R, fill_Oxy2R, fill_NicoR};
    wv_annot_opts = {annot_opts_ABP,annot_opts_NicoIR,annot_opts_Oxy1IR, annot_opts_Oxy2IR,annot_opts_ECG, annot_opts_CO2, annot_opts_IPleth, annot_opts_NPleth,  annot_opts_Oxy1R, annot_opts_Oxy2R,annot_opts_NicoR};
    wv_yview = {yview_ABP, yview_NicoIR, yview_Oxy1IR, yview_Oxy2IR, yview_ECG, yview_CO2, yview_IPleth,yview_NPleth, yview_Oxy1R, yview_Oxy2R, yview_NicoR};
    wv_may_shift = {may_shift_ABP,may_shift_NicoIR,may_shift_Oxy1IR, may_shift_Oxy2IR, may_shift_ECG, may_shift_CO2, may_shift_IPleth, may_shift_NPleth,  may_shift_Oxy1R, may_shift_Oxy2R,may_shift_NicoR};
    wv_meas = {meas_ABP, meas_NicoIR,meas_Oxy1IR, meas_Oxy2IR, meas_ECG, meas_CO2, meas_IPleth, meas_NPleth,  meas_Oxy1R, meas_Oxy2R, meas_NicoR};
elseif strcmp(annot_Team,'UBC')
    wv_ylimit_default = {ylimit_def_ABP, ylimit_def_ECG,ylimit_def_CO2, ylimit_def_Flow,ylimit_def_Pressure, ylimit_def_Volume, ylimit_def_IPleth, ylimit_def_NPleth};
%      wv_labels = {label_ABP, label_ECG, label_CO2, label_Flow,label_Pressure, label_Volume, label_IPleth, label_NPleth};
    wv_color = {color_ABP, color_ECG,color_CO2,  color_Flow,color_Pressure, color_Volume, color_IPleth, color_NPleth};
    wv_fill = {fill_ABP,fill_ECG,  fill_CO2, fill_Flow,fill_Pressure, fill_Volume, fill_IPleth, fill_NPleth};
    wv_annot_opts = {annot_opts_ABP,annot_opts_ECG,annot_opts_CO2, annot_opts_Flow,annot_opts_Pressure, annot_opts_Volume, annot_opts_IPleth, annot_opts_NPleth};
    wv_yview = {yview_ABP, yview_ECG, yview_CO2, yview_Flow, yview_Pressure, yview_Volume, yview_IPleth,yview_NPleth};
    wv_may_shift = {may_shift_ABP,may_shift_ECG,may_shift_CO2, may_shift_Flow, may_shift_Pressure, may_shift_Volume, may_shift_IPleth, may_shift_NPleth};
    wv_meas = {meas_ABP, meas_ECG,meas_CO2, meas_Flow, meas_Pressure, meas_Volume, meas_IPleth, meas_NPleth};
else
    error('annot_Team unrecognized')
end
wvs = struct('file', wv_files, 'color', wv_color, 'fill', wv_fill, ...
    'annot_opts', wv_annot_opts, 'ylimit_def', wv_ylimit_default,...
    'yview', wv_yview, 'may_shift', wv_may_shift, 'meas', wv_meas);
%wvs = struct('file', wv_files,'label', wv_labels,  'color', wv_color, 'fill', wv_fill, ...
%    'annot_opts', wv_annot_opts, 'ylimit_def', wv_ylimit_default,...
%    'yview', wv_yview, 'may_shift', wv_may_shift, 'meas', wv_meas);


for i = 1:length(wv_files)
    measure.(wv_files{i}) = wv_meas{i};
end

end

