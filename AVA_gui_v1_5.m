function AVA_gui_v1_5
%View and annotate longitudinal data

%% File management
close all
%clear all 
clearvars -EXCEPT annot_Team;
addpath(genpath(pwd))       %adds current directory (pwd) to path; make sure current
%directory = this file's directory by right-clicking file tab.

[matDir, lock_filedir, CaseListFile, folder_string, config_function, measures_function] = AVA_file_locations();
[CaseList, N_case, activeindex] = loadCaseList(matDir, CaseListFile, lock_filedir, folder_string);
[invalidList, lockList, unlockList] = updateSubLists(CaseList, N_case);
%run this after loading CaseList

global case_dir

%% Waveform and measure characteristics
global wvs...  %defined in default_wave_parameters
    wv_label...
    wv_select...  %wave selected for annotation or shifting
    wv_enable_shift...%wave that can be shifted
    wv_enable_measure...
    wv_loaded...  %indexes of wv_files that are loaded for active case
    patient...    %patient annotations
    measure...    %measures
    trans...      %transitions for patient and waveforms
    trans_filename shifts_filename meas_filename... %case-specific names of trans, shifts and meas file   
    shifts...
    auto_code...  %string for automatically generated annotations
    plot_valid    %whether to plot valid field generated automatically

user = getenv('USERNAME');  %windows user name

% i_wv*: index of wave corresponding to wave A/B/C/D;
% i_meas*_p is the index of Parent wave for measure *
% i_meas* is index of measure A/B/C/D

global i_wvA i_wvB i_wvC i_wvD... %wave indexes;
    i_measM1_p i_measM2_p i_measM3_p i_measM4_p ... %measure PARENT indexes
    i_measM1 i_measM2 i_measM3 i_measM4 ...  %measure indexes
    wv_opts_A wv_opts_B wv_opts_C wv_opts_D ...
    measM1_p_opts measM2_p_opts measM3_p_opts measM4_p_opts...
    measM1_opts measM2_opts measM3_opts measM4_opts

%% figure defaults

%main figure window and position (as percentage of screen)
fig_ht = 0.85 ;  %ht
fig_w = 1;   %width
figure_f_pos = [0, 0, fig_w, fig_ht];  %bottom left corner (x,y), fig wd, fig ht;
%units normalized to percentage of SCREEN SIZE
f = figure('Visible','on', 'Units','normalized', 'Name', matDir,...
    'Position', figure_f_pos, 'WindowScrollWheelFcn', @scrollwheel_callback,...
    'WindowKeyPressFcn',@dispkeyevent);   %creates figure
%assigns mouse functions
%'WindowButtonDownFcn', @wbd_callback,...
movegui(f,'north')


%Positions for windows that will hold different tables (tables are inside figure windows)
%relative to SCREEN SIZE
figure_table_A_pos  = [0.1, 0.5, 0.22, 0.4];
figure_table_B_pos  = [0.35, 0.5, 0.22, 0.4];
figure_table_C_pos = [0.6, 0.5, 0.22, 0.4];
figure_table_D_pos = [0.8, 0.5, 0.22, 0.4];
figure_case_summary_pos = [0.35, 0.3, 0.22, 0.25];
figure_table_segments_pos = [0.5,0.2,0.5,0.5];
figure_patient_pos = [0.35, 0.3, 0.22, 0.25];

%% Other graphics parameters
set(0,'defaultuicontrolunits','normalized');   %change default units for gui controls = normalized, which is is percentage of FIGURE size
u = 0.05;  % my unit size for buttons, etc.; this is u% of figure
myalpha = 0.3; %transparency of fill
fill_scale = 0.33; %proportion of fill:y range
scaling_factor = 3/4;  %change in zoom
vert_factor = 0.2;  %vertical change in y-axis with "up" and "down" keys

% coordinates for gui components
text_offset_gen = 1.05;   %proportion above top plot for text annotations
global y_patient_text
wavetype_x = 18.2 * u;  %x position for wavetype label/listbox
y_wvA = 18*u;
y_wvB = 16*u;
y_wvC = 14*u;
y_wvD = 12*u;
y_measM1 = 6*u;
y_measM2 = 5*u;
y_measM3 = 4*u;
y_measM4 = 3*u;
y_update_measures = 2*u;
zoom_x = 1.5 * u;    %x position for "zoom" buttons
up_down_x = 1.9 * u;    %x position for up and down buttons

%x axis/time related globals
global x_offset xrange max_time cursor_time time_shift time_shift_index

%annotation globals
global h_target_wv h_target_axes

% Handles
global haxes_wvA haxes_wvB haxes_wvC haxes_wvD ... %handles for wave subplot axes
    haxes_top ... %handle for top wave subplot; useful for plotting pt events
    haxes_meas ... %handle for measure subplot axis
    h_wvA h_wvB h_wvC h_wvD...  %handles for waves
    h_measM1 h_measM2 h_measM3 h_measM4 ...%handles for measures
    h_annotate_panel  %annotation panel


%% Load cases: h_newcase, h_casetype_popup, h_case_popop, case_initialize
%newcase: opens up casetype popup, which then opens up case popup

h_newcase = uicontrol(f,'Style','pushbutton','String','New Case',...
    'Position',[0,19*u,u,u],...
    'Callback',{@newcase_Callback});

h_casetype_popup = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'CASE TYPE', 'Unlocked (valid)', 'Locked (valid)', 'Not Valid', 'All'},...
    'Position',[0,13*u,2*u,6*u],...
    'Visible', 'off',...
    'Callback',{@casetype_popup_Callback});

h_case_popup = uicontrol(f, 'Style','popupmenu',...
    'Position',[0,12*u,2*u,6*u],...
    'Visible', 'off', ...  %not visible unless casetype selected
    'Callback',{@case_popup_Callback});
%h_case_popup 'String' and 'Value' are set by casetype_popup_Callback
%h_case_popup 'String' is the caselist

    function newcase_Callback(hObject, eventdata, ~)
        figure(f)
        hold off
        %plot(0,0)  %this makes a blank plot, erasing previous case
        set(h_casetype_popup, 'Visible', 'on', 'Value', 1)
        [invalidList, lockList, unlockList] = updateSubLists(CaseList, N_case);
    end

    function casetype_popup_Callback(source,eventdata)
        index_selected = get(source,'Value');  %casetype index
        list = get(source,'String');  %list of casetypes
        casetype = list{index_selected};
        
        switch casetype   %if isfield checks to see if sublist has any elements
            %exists doesn't give right answer, since struct exists.
            %however, struct has no fields if sublist has no elements
            %if sublist is empty, then make select caselist again
            
            case 'CASE TYPE'
                set(h_case_popup,'Visible', 'off')
                set(h_casetype_popup, 'Value', 1)
            case 'All'
                set(h_case_popup, 'String', {'CASE', CaseList.id}, 'Visible', 'on' )
            case 'Not Valid'
                if isfield(invalidList, 'id')
                    set(h_case_popup, 'String',{'CASE', invalidList.id}, 'Visible', 'on' )
                else
                    set(h_case_popup,'Visible', 'off')
                    set(h_casetype_popup, 'Value', 1)   %returns to 'Select case type'
                end
            case 'Unlocked (valid)'
                if isfield(unlockList, 'id')  %are there any nonlock cases
                    set(h_case_popup, 'String', {'CASE', unlockList.id}, 'Visible', 'on' )
                else  %if there is no locklist, then change selection to CaseList
                    set(h_case_popup, 'Visible', 'off')
                    set(h_casetype_popup, 'Value', 1)
                end
            case 'Locked (valid)'
                if isfield(lockList, 'id')  %are there any lock cases?
                    set(h_case_popup, 'String', {'CASE', lockList.id}, 'Visible', 'on' )
                else  %if there is no locklist, then change selection to CaseList
                    set(h_case_popup, 'Visible', 'off')
                    set(h_casetype_popup, 'Value', 1)
                end
        end
        
        set(h_case_popup, 'Value', 1);
    end

    function case_popup_Callback(source,eventdata)
        index_selected = get(source,'Value');  %list index
        list = get(source,'String');  %caselist (may be CaseList or a subList)
        case_id = list{index_selected};  % casename, eg '120xxx'
        
        if index_selected == 1   % index 1 = 'CASE'
            set(h_case_popup, 'Visible', 'off')
            set(h_casetype_popup, 'Value', 1)
        else
            activeindex = find(strcmp({CaseList.id}, case_id));  %this finds index by comparing casename to full CaseList
           % case_dir = [matDir case_id '\'];
            case_dir = [matDir case_id filesep]; % jkr - make flexible to Mac
            uistack(hWarning, 'top')
            set(hWarning, 'Visible','on', 'String', 'Loading Case')
            
            [wvs, wv_files, wv_fields_import, meas_fields_import, epoch_mean_center, epoch_norm, ...
                patient, patient_variables_import, measure, auto_code, default_initial_wvs, ...
                cpr_uicontrol, wv_enable_shift, wv_enable_measure, plot_valid, min_xrange] = ...
                feval(config_function);  %resets wvs; place BEFORE importing specific case data
            %calls appropriate config_function
            
            switch cpr_uicontrol
                case 'h_annot_cpr_clip'
                    set(h_annot_cpr_clip, 'Visible', 'On')
                    set(h_annotate_cpr_ava, 'Visible', 'Off')
                case'h_annotate_cpr_ava'
                    set(h_annotate_cpr_ava, 'Visible', 'On')
                    set(h_annot_cpr_clip, 'Visible', 'Off')
            end
            
            [wvs, wv_loaded, wv_label, max_time, patient, measure, trans, shifts,...
                trans_filename,  shifts_filename, meas_filename] = ...
                import_case(case_dir, case_id, wvs, wv_files, wv_fields_import, meas_fields_import, epoch_mean_center, epoch_norm,...
                patient, patient_variables_import, measure, auto_code);
            
            set(hWarning, 'Visible','off')
            
            case_initialize(default_initial_wvs, min_xrange)
            figure(f)
            hold off     %this will overwrite existing plot
            plot_case()  %plots new case from start
        end
    end

    function case_initialize(default_initial_wvs, min_xrange)
        %sets default parameters prior to NEW case
        %called by case_popup_Callback when new case is selected
        
        C = intersect(wv_loaded, default_initial_wvs); % default initial waves that are loaded
        switch length(C)
            case 0
                i_wvA = []; i_wvB = []; i_wvC = []; i_wvD = [];
            case 1
                i_wvA = C(1); i_wvB = []; i_wvC = []; i_wvD = [];
            case 2
                i_wvA = C(1); i_wvB = C(2); i_wvC = []; i_wvD = [];
            case 3
                i_wvA = C(1); i_wvB = C(2); i_wvC = C(3); i_wvD = [];
            case 4
                i_wvA = C(1); i_wvB = C(2); i_wvC = C(3); i_wvD = C(4);
            otherwise
                i_wvA = []; i_wvB = []; i_wvC = []; i_wvD = [];
        end
        
        function [wv_opts] = initialize_waves(h_popup_wv, hradio_trans, figure_table, i_wv, ...
                h_zoom_in_wv, h_zoom_out_wv, h_up_wv, h_down_wv, h_center_wv, h_autocenter_wv)
            wv_opts = {'WAVE', wvs(wv_loaded).label};
            set(hradio_trans, 'Value', 0)      %button to off position
            set(h_autocenter_wv, 'Value', 0)      %button to off position
            set(figure_table, 'Visible','off')   %close all tables
            if isempty(i_wv)
                set(h_popup_wv, 'Value', 1, 'String', wv_opts, 'ForegroundColor', 'black')
                set(hradio_trans, 'Visible','off', 'ForegroundColor', 'black')
                set(h_zoom_in_wv, 'Visible', 'off')
                set(h_zoom_out_wv, 'Visible', 'off')
                set(h_up_wv, 'Visible', 'off')
                set(h_down_wv, 'Visible', 'off')
                set(h_center_wv, 'Visible', 'off')
                set(h_autocenter_wv, 'Visible', 'off')
            else
                set(h_popup_wv, 'Value', i_wv+1, 'String', wv_opts, 'ForegroundColor', wvs(i_wv).color)
                set(hradio_trans, 'Visible', 'on', 'String', wvs(i_wv).label, 'ForegroundColor', wvs(i_wv).color)
                if isfield(wvs(i_wv), 'Valid') && plot_valid
                    %[y_valid, ~] = separate_wave_Y_by_validity(wvs(i_wv).y, wvs(i_wv).Valid);
                    y_valid = wvs(i_wv).y_valid(~isnan(wvs(i_wv).y_valid)); %remove missing data
                    wvs(i_wv).ylimit = quantile(y_valid, [0 1]);  %y ranger is 0-100%
                else
                    wvs(i_wv).ylimit = wvs(i_wv).ylimit_def;
                end
            end
        end
        
        [wv_opts_A] = initialize_waves(h_popup_wvA, hradio_trans_A, figure_table_A, i_wvA, ...
            h_zoom_in_wvA, h_zoom_out_wvA, h_up_wvA, h_down_wvA, h_center_wvA, h_autocenter_wvA);
        [wv_opts_B] = initialize_waves(h_popup_wvB, hradio_trans_B, figure_table_B, i_wvB, ...
            h_zoom_in_wvB, h_zoom_out_wvB, h_up_wvB, h_down_wvB, h_center_wvB, h_autocenter_wvB);
        [wv_opts_C] = initialize_waves(h_popup_wvC, hradio_trans_C, figure_table_C, i_wvC, ...
            h_zoom_in_wvC, h_zoom_out_wvC, h_up_wvC, h_down_wvC, h_center_wvC, h_autocenter_wvC);
        [wv_opts_D] = initialize_waves(h_popup_wvD, hradio_trans_D, figure_table_D, i_wvD, ...
            h_zoom_in_wvD, h_zoom_out_wvD, h_up_wvD, h_down_wvD, h_center_wvD, h_autocenter_wvD);
        
        
        %Measures
        function [meas_p_opts, meas_opts, i_meas_p, i_meas] = initialize_measures(h_popup_meas_parent, h_popup_meas)
            options = intersect(wv_loaded, wv_enable_measure);  %wave must be loaded and measures must be enabled
            if isempty(options)
                meas_p_opts = {'WAVE'};
            else
                meas_p_opts = {'WAVE', wvs(options).label};
            end
            set(h_popup_meas_parent, 'Value', 1, 'String', meas_p_opts, 'ForegroundColor', 'black')
            i_meas_p = [];
            meas_opts = {'MEASURE'};
            set(h_popup_meas, 'Value', 1, 'String', meas_opts, 'ForegroundColor', 'black')
            i_meas = [];
        end
        
        [measM1_p_opts, measM1_opts, i_measM1_p, i_measM1] = initialize_measures(h_popup_measM1_parent, h_popup_measM1);
        [measM2_p_opts, measM2_opts, i_measM2_p, i_measM2] = initialize_measures(h_popup_measM2_parent, h_popup_measM2);
        [measM3_p_opts, measM3_opts, i_measM3_p, i_measM3] = initialize_measures(h_popup_measM3_parent, h_popup_measM3);
        [measM4_p_opts, measM4_opts, i_measM4_p, i_measM4] = initialize_measures(h_popup_measM4_parent, h_popup_measM4);
                
        %set defaults for gui controls
        x_offset = 0;
        xrange = max_time;  %initial value for xstep is max_time
        set(h_x_offset_step,  'Min', 0, 'Max', max_time, 'SliderStep', [10/max_time 60/max_time],...
            'Value', x_offset)
        set(h_time_step, 'Min', min_xrange, 'Max', max_time, 'SliderStep', [10/max_time 120/max_time],...
            'Value', max_time)
        %sets slider to max_time to show whole case
        time_shift = [0 0]; time_shift_index = 0;  %vectors for changing offset
        
        set(hLockCase, 'Value', CaseList(activeindex).lock,  'Visible', 'on');
        %sets initial value for "locked" button to its value in CaseList
        LockCase_Callback(hLockCase, 0)   %0 is dummy variable
        
        set(hValidCase, 'Value', CaseList(activeindex).valid,  'Visible', 'on');
        
        if isfield(patient, 'ClinData')
            if ~isempty(patient.ClinData)
                set(hradio_case_summary,  'Visible', 'on', 'Value', 0);
            end
        end
        
        set(h_case_popup, 'Visible', 'off' )  %closes case popup
        set(h_casetype_popup, 'Visible', 'off' )  %closes casetype (only open when select new case)
        
        %      set(hradio_table_segments, 'Value',0)
        %      set(hradio_table_segments, 'Visible','on')
        set(hupdate_meas, 'Visible','on')
        
        
        opts = vertcat('Interventions', patient.annot_intervent(:));
        set(h_annotate_patient_event, 'String', opts)
        opts = vertcat('Compressions', patient.annot_cpr(:));
        set(h_annotate_cpr_ava, 'String', opts)
        
        set(f, 'Name', case_dir)  %adds cass id to figure title
        
    end


%% LockCase and ValidCase
%LockCase:
%if locked:
%update CaseList with current date
%dcm is not enabled (therefore cannot annotate);
%trans_A, etc are backed up
hLockCase = uicontrol(f,'Style','radiobutton',...
    'String','Lock case',...
    'Value',0,...         %must be initialized with each new case
    'Position',[0,15*u,1.5*u,u],...
    'Visible', 'off',...
    'Callback',{@LockCase_Callback});

    function LockCase_Callback(source,eventdata)
        CaseList(activeindex).lock = get(source,'Value'); %1=locked, 0=not lock
        
        if CaseList(activeindex).lock
            CaseList(activeindex).date = datestr(now, 'ddmmyy');  %current date
            save(CaseListFile, 'CaseList')
            save([lock_filedir  CaseList(activeindex).id '_lock_' CaseList(activeindex).date '.mat'], 'trans')
            
            set(table_A, 'ColumnEditable', false(1,2,3,4))  %tables are not editable
            set(table_B, 'ColumnEditable', false(1,2,3,4))
            set(table_C, 'ColumnEditable', false(1,2,3,4))
            set(table_D, 'ColumnEditable', false(1,2,3,4))
        else  %unlock
            CaseList(activeindex).date = '';
            save(CaseListFile, 'CaseList')
            set(table_A, 'ColumnEditable', [true, false, false, false])
            set(table_B, 'ColumnEditable', [true, false, false, false])  %tables are editable
            set(table_C, 'ColumnEditable', [true, false, false, false])
            set(table_D, 'ColumnEditable', [true, false, false, false])
        end
        [invalidList, lockList, unlockList] = updateSubLists(CaseList, N_case);
        
    end


hValidCase = uicontrol(f,'Style','radiobutton',...
    'String','Valid case',...
    'Value',0,...         %must be initialized with each new case
    'Position',[0,14*u,1.5*u,u],...
    'Visible', 'off',...
    'Callback',{@ValidCase_Callback});

    function ValidCase_Callback(source,eventdata)
        CaseList(activeindex).valid= get(source,'Value'); %1=locked, 0=not lock
        save(CaseListFile, 'CaseList')
        [invalidList, lockList, unlockList] = updateSubLists(CaseList, N_case);
    end


%% Select waves and measures to display

h_popup_wvA = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_wvA, u, u],...
    'Visible', 'on',...
    'Callback',{@popup_wv_Callback});
h_popup_wvB = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_wvB, u, u],...
    'Visible', 'on',...
    'Callback',{@popup_wv_Callback});
h_popup_wvC = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_wvC, u, u],...
    'Visible', 'on',...
    'Callback',{@popup_wv_Callback});
h_popup_wvD = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_wvD, u, u],...
    'Visible', 'on',...
    'Callback',{@popup_wv_Callback});

h_popup_measM1_parent = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_measM1, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_parent_Callback});
h_popup_measM2_parent = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_measM2, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_parent_Callback});
h_popup_measM3_parent = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_measM3, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_parent_Callback});
h_popup_measM4_parent = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'WAVE'},...
    'Position',[wavetype_x, y_measM4, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_parent_Callback});

h_popup_measM1 = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'MEASURE'},...
    'Position',[wavetype_x + u, y_measM1, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_Callback, });

h_popup_measM2 = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'MEASURE'},...
    'Position',[wavetype_x + u, y_measM2, 0.75*u,u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_Callback});

h_popup_measM3 = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'MEASURE'},...
    'Position',[wavetype_x + u, y_measM3, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_Callback});

h_popup_measM4 = uicontrol(f, 'Style','popupmenu',...
    'Value', 1, ...
    'String', {'MEASURE'},...
    'Position',[wavetype_x + u, y_measM4, 0.75*u, u],...
    'Visible', 'on',...
    'Callback',{@popup_meas_Callback});


    function popup_wv_Callback(source,eventdata)
        index_selected = get(source,'Value');
        list = get(source,'String');
        str_selected = list(index_selected);
        
        switch source
            case h_popup_wvA
                hradio = hradio_trans_A;
            case h_popup_wvB
                hradio = hradio_trans_B;
            case h_popup_wvC
                hradio = hradio_trans_C;
            case h_popup_wvD
                hradio = hradio_trans_D;
        end
        
        if index_selected == 1   %no wave
            set(source, 'ForegroundColor', 'black')
            set(hradio, 'Visible','off')
            switch source
                case h_popup_wvA
                    i_wvA = [];
                case h_popup_wvB
                    i_wvB = [];
                case h_popup_wvC
                    i_wvC = [];
                case h_popup_wvD
                    i_wvD = [];
            end
        else
            nwv = find(strcmp(wv_label, str_selected));
            wvs(nwv).ylimit = wvs(nwv).ylimit_def;
            set(source, 'ForegroundColor', wvs(nwv).color)
            switch source
                case h_popup_wvA
                    i_wvA = nwv;
                case h_popup_wvB
                    i_wvB = nwv;
                case h_popup_wvC
                    i_wvC = nwv;
                case h_popup_wvD
                    i_wvD = nwv;
            end
            set(hradio, 'String', wvs(nwv).label, 'ForegroundColor', wvs(nwv).color)
            set(hradio, 'Value', 0)
            set(hradio, 'Visible', 'on')
        end
        plot_case()
    end


    function popup_meas_parent_Callback(source,eventdata)
        index_selected = get(source,'Value');
        list = get(source,'String');
        meas_parent = list{index_selected};
        
        if index_selected == 1   %no wave
            set(source, 'ForegroundColor', 'black')
            switch source
                case h_popup_measM1_parent
                    i_measM1_p = [];
                case h_popup_measM2_parent
                    i_measM2_p = [];
                case h_popup_measM3_parent
                    i_measM3_p = [];
                case h_popup_measM4_parent
                    i_measM4_p = [];
            end
        else
            nwv = index_selected-1;
            set(source, 'ForegroundColor', wvs(nwv).color)
            switch source
                case h_popup_measM1_parent
                    i_measM1_p = nwv;
                    if isfield(wvs(i_measM1_p), 'meas')
                        measM1_opts = {'MEASURE', wvs(i_measM1_p).meas(:).label};
                    else
                        measM1_opts = {'MEASURE'};
                    end
                    set(h_popup_measM1, 'String', measM1_opts)
                case h_popup_measM2_parent
                    i_measM2_p = nwv;
                    if isfield(wvs(i_measM2_p), 'meas')
                        measM2_opts = {'MEASURE', wvs(i_measM2_p).meas(:).label};
                    else
                        measM2_opts = {'MEASURE'};
                    end
                    set(h_popup_measM2, 'String', measM2_opts)
                case h_popup_measM3_parent
                    i_measM3_p = nwv;
                    if isfield(wvs(i_measM3_p), 'meas')
                        measM3_opts = {'MEASURE', wvs(i_measM3_p).meas(:).label};
                    else
                        measM3_opts = {'MEASURE'};
                    end
                    set(h_popup_measM3, 'String', measM3_opts)
                case h_popup_measM4_parent
                    i_measM4_p = nwv;
                    if isfield(wvs(i_measM4_p), 'meas')
                        measM4_opts = {'MEASURE', wvs(i_measM4_p).meas(:).label};
                    else
                        measM4_opts = {'MEASURE'};
                    end
                    set(h_popup_measM4, 'String', measM4_opts)
            end
        end
        
    end


    function popup_meas_Callback(source,eventdata)
        index_selected = get(source,'Value');
        list = get(source,'String');
        str_selected = list(index_selected);
        
        if index_selected == 1
            set(source, 'ForegroundColor', 'black')
            switch source
                case h_popup_measM1
                    i_measM1 = [];
                    set(h_measM1, 'Visible','off')
                case h_popup_measM2
                    i_measM2 = [];
                    set(h_measM2, 'Visible','off')
                case h_popup_measM3
                    i_measM3 = [];
                    set(h_measM3, 'Visible','off')
                case h_popup_measM4
                    i_measM4 = [];
                    set(h_measM4, 'Visible','off')
                    
            end
        else
            auto_refresh = get(hauto_refresh_meas,'Value');
            if auto_refresh
                update_meas_Callback('dummy','dummy')
            end
            
            nmeas = index_selected-1;  %set label color and calculate measures if measures value empty
            switch source
                case h_popup_measM1
                    i_measM1 = nmeas;
                    set(source, 'ForegroundColor', wvs(i_measM1_p).meas(nmeas).color)
                    if ~isfield(wvs(i_measM1_p).meas(nmeas), 'x')
                       update_meas_Callback('dummy','dummy')
                    else
                       if isempty(wvs(i_measM1_p).meas(nmeas).x)
                          update_meas_Callback('dummy','dummy') 
                       end
                    end
                case h_popup_measM2
                    i_measM2 = nmeas;
                    set(source, 'ForegroundColor', wvs(i_measM2_p).meas(nmeas).color)
                    if ~isfield(wvs(i_measM2_p).meas(nmeas), 'x')
                       update_meas_Callback('dummy','dummy')
                    else
                       if isempty(wvs(i_measM2_p).meas(nmeas).x)
                          update_meas_Callback('dummy','dummy') 
                       end
                    end
                case h_popup_measM3
                    i_measM3 = nmeas;
                    set(source, 'ForegroundColor', wvs(i_measM3_p).meas(nmeas).color)
                    if ~isfield(wvs(i_measM3_p).meas(nmeas), 'x')
                       update_meas_Callback('dummy','dummy')
                    else
                       if isempty(wvs(i_measM3_p).meas(nmeas).x)
                          update_meas_Callback('dummy','dummy') 
                       end
                    end
                case h_popup_measM4
                    i_measM4 = nmeas;
                    set(source, 'ForegroundColor', wvs(i_measM4_p).meas(nmeas).color)
                    if ~isfield(wvs(i_measM4_p).meas(nmeas), 'x')
                       update_meas_Callback('dummy','dummy')
                    else
                       if isempty(wvs(i_measM4_p).meas(nmeas).x)
                          update_meas_Callback('dummy','dummy') 
                       end                       
                    end
            end
        end
        plot_case()
    end


%% Plot: fill_phase, plot_case, plot_patient, plot_wave, plot_EV_cc, plot_patient.vent

    function plot_case()
        figure(f);  %make sure we are on figure f
        n_meas = sum([~isempty(i_measM1) ~isempty(i_measM2) ~isempty(i_measM3) ~isempty(i_measM4)]);
        n_plot = sum([~isempty(i_wvA) ~isempty(i_wvB) ~isempty(i_wvC) ~isempty(i_wvD) n_meas~=0]) ;
        count_plot = 0;
        ycontrols_disappear(h_zoom_in_wvA, h_zoom_out_wvA, h_up_wvA, h_down_wvA, h_center_wvA, h_autocenter_wvA)
        ycontrols_disappear(h_zoom_in_wvB, h_zoom_out_wvB, h_up_wvB, h_down_wvB, h_center_wvB, h_autocenter_wvB)
        ycontrols_disappear(h_zoom_in_wvC, h_zoom_out_wvC, h_up_wvC, h_down_wvC, h_center_wvC, h_autocenter_wvC)
        ycontrols_disappear(h_zoom_in_wvD, h_zoom_out_wvD, h_up_wvD, h_down_wvD, h_center_wvD, h_autocenter_wvD)
        
        if (get(h_popup_wvA, 'Value') ~= 1)
            [count_plot, haxes_wvA, h_wvA] = plot_wave(count_plot, n_plot, i_wvA, ...
                h_zoom_in_wvA, h_zoom_out_wvA, h_up_wvA, h_down_wvA, h_center_wvA, h_autocenter_wvA);
        end
        
        if (get(h_popup_wvB, 'Value') ~= 1)
            [count_plot, haxes_wvB, h_wvB] = plot_wave(count_plot, n_plot, i_wvB, ...
                h_zoom_in_wvB, h_zoom_out_wvB, h_up_wvB, h_down_wvB, h_center_wvB, h_autocenter_wvB);
        end
        
        if (get(h_popup_wvC, 'Value') ~= 1)  %Value = 1 if plot, Value=0 if no plot
            [count_plot, haxes_wvC, h_wvC] = plot_wave(count_plot, n_plot, i_wvC, ...
                h_zoom_in_wvC, h_zoom_out_wvC, h_up_wvC, h_down_wvC, h_center_wvC, h_autocenter_wvC);
        end
        
        if (get(h_popup_wvD, 'Value') ~= 1)  %Value = 1 if plot, Value=0 if no plot
            [count_plot, haxes_wvD, h_wvD] = plot_wave(count_plot, n_plot, i_wvD, ...
                h_zoom_in_wvD, h_zoom_out_wvD, h_up_wvD, h_down_wvD, h_center_wvD, h_autocenter_wvD);
        end
        
        % Measures
        
        if n_meas > 0
            count_plot = count_plot + 1;
            haxes_meas = subplot(n_plot, 1, count_plot, 'replace');
            
            if (get(h_popup_measM1, 'Value') ~= 1)
                h_measM1 = plot_measure(i_measM1_p, i_measM1);
            end
            
            if (get(h_popup_measM2, 'Value') ~= 1)
                h_measM2 = plot_measure(i_measM2_p, i_measM2);
            end
            
            if (get(h_popup_measM3, 'Value') ~= 1)
                h_measM3 = plot_measure(i_measM3_p, i_measM3);
            end
            
            if (get(h_popup_measM4, 'Value') ~= 1)
                h_measM4 = plot_measure(i_measM4_p, i_measM4);
            end
            
            set(haxes_meas, 'XLimMode', 'manual', 'YLimMode', 'manual');
            set(haxes_meas, 'XLim', [x_offset x_offset+xrange])
            set(haxes_meas, 'YLim', [-4 4]);
            m1_ticklabels = {'-4SD' '-3SD' '-2SD' '-SD' 'Mean' '+SD' '+2SD' '+3SD' '+4SD'};            
            m1_ticks = (-4:1:4);
            set(haxes_meas, 'YTick', m1_ticks, 'YTickLabel', m1_ticklabels);
            set(haxes_meas, 'HitTest', 'off');
        end
        
        %Patient data
        if n_plot>=1
            hplots = findobj(gcf,'type','axes');
            haxes_top = hplots(n_plot);
            linkaxes(hplots(1:n_plot), 'x')
            
            %add text annotations
            my_y_limits = get(haxes_top, 'YLim');
            y_patient_text = my_y_limits(1) + range(my_y_limits) * text_offset_gen;
            plot_patient(patient.trans, '')
        end
        
        set(dcm_obj, 'Enable', 'off')  %set dcm_obj to off, because default, whenver plot is opened, is to set to on
    end

    function [count_plot, haxes_wv, h_wv] = plot_wave(count_plot, n_plot, i_wv, h_zoom_in_wv, h_zoom_out_wv, ...
            h_up_wv, h_down_wv, h_center_wv, h_autocenter_wv)
        count_plot = count_plot + 1;
        haxes_wv = subplot(n_plot, 1, count_plot, 'replace', 'align');
        
        if isfield(wvs(i_wv), 'Valid') && plot_valid
            h_wv = plot(haxes_wv, wvs(i_wv).x_valid, wvs(i_wv).y_valid, 'Color', wvs(i_wv).color, 'linewidth', 1, 'LineStyle', '-');
            hold on;
            plot(haxes_wv, wvs(i_wv).x_invalid, wvs(i_wv).y_invalid, 'Color', wvs(i_wv).color, 'linewidth', 1, 'LineStyle', '-.');
        else
            h_wv = plot(haxes_wv, wvs(i_wv).x, wvs(i_wv).y, 'Color', wvs(i_wv).color, 'linewidth', 1);
        end
        
        title(wvs(i_wv).label, 'FontWeight', 'bold', 'Color', wvs(i_wv).color)
        set(haxes_wv, 'XLimMode', 'manual', 'YLimMode', 'manual');
        set(haxes_wv, 'XLim', [x_offset x_offset+xrange])
        set(haxes_wv,'XGrid', 'on')  %shows gridlines only for x-axis=time
        
        %y limits
        if get(h_autocenter_wv, 'Value')
          [wvs(i_wv).ylimit] = set_ylimit_centered(i_wv, haxes_wv);
        else
          set(haxes_wv, 'YLim', wvs(i_wv).ylimit);
        end
        set(haxes_wv, 'HitTest', 'off');
        fill_phase(i_wv, haxes_wv);
        plot_cpr(haxes_wv);
        plot_wave_freetext(wvs(i_wv).trans, haxes_wv)
        
        coor = get(haxes_wv, 'Position');
        center = coor(2)+0.5*coor(4);
        set(h_zoom_in_wv, 'Visible', 'on', 'Position', [zoom_x, center, 0.4*u, 0.4*u])
        set(h_zoom_out_wv, 'Visible', 'on', 'Position', [zoom_x, center-0.5*u, 0.4*u, 0.4*u])
        set(h_up_wv, 'Visible', 'on', 'Position', [up_down_x, center, 0.4*u, 0.4*u])
        set(h_down_wv, 'Visible', 'on', 'Position', [up_down_x, center-0.5*u, 0.4*u, 0.4*u])
        set(h_center_wv, 'Visible', 'on', 'Position', [zoom_x, center+u, 0.7*u, 0.4*u])
        set(h_autocenter_wv, 'Visible', 'on', 'Position', [zoom_x, center+0.5*u, 0.7*u, 0.4*u])
    end

    function [ylimit_new] = set_ylimit_centered(i_wv, haxes_wv)
        xlimit = get(haxes_wv, 'XLim');
        ylimit = get(haxes_wv, 'YLim');
        i1 = find(wvs(i_wv).x >= xlimit(1), 1, 'first');   %index for 1st time
        i2 = find(wvs(i_wv).x <= xlimit(2), 1, 'last');   %index for 2nd time
        
        if isfield(wvs(i_wv), 'Valid') && plot_valid;
            y = wvs(i_wv).y_valid(i1:i2);
            y = y(~isnan(y));  %remove missing data
        else
            y = wvs(i_wv).y(i1:i2);
            y = y(~isnan(y));  %remove missing data
        end
        if ~isempty(y) && range(y)~=0
            ylimit_new = quantile(y, [0 1]);  %y ranger is 0-100%
            set(haxes_wv, 'YLim', ylimit_new);
        else
            ylimit_new = ylimit;
        end
    end


    function [h_meas] = plot_measure(i_meas_p, i_meas)
        h_meas = plot(haxes_meas, wvs(i_meas_p).meas(i_meas).x, wvs(i_meas_p).meas(i_meas).(wvs(i_meas_p).meas(i_meas).yview),...
            'Marker', wvs(i_meas_p).meas(i_meas).marker, 'LineStyle', 'none', ...
            'Color', wvs(i_meas_p).meas(i_meas).color);
        hold(haxes_meas, 'on')
    end

    function [Csub] = subset_cell_array(C, str_cond, include)
        %Cs = cellfun(f, C)
        %   - C:            the source cell array
        %   - f:            the predicate function handle
        %   - Cs:           the cell array of selected elements (same size as C)
        % C(cellfun(f, C) )  returns only those matching elements
        % eg, cellfun(@(x) length(x) > 3, C)
        Cs = cellfun(@(x) strcmp(x, str_cond), C);
        [rownum, colnum] = find(Cs == 1);
        if include
            Csub = C(rownum, :);
        else
            n = size(C, 1);
            Csub = C(setdiff(1:n, rownum), :);
        end
    end

    function ycontrols_disappear(h_zoom_in_wv, h_zoom_out_wv, h_up_wv, h_down_wv, h_center_wv, h_autocenter_wv)
        set(h_zoom_in_wv, 'Visible', 'off')
        set(h_zoom_out_wv, 'Visible', 'off')
        set(h_up_wv, 'Visible', 'off')
        set(h_down_wv, 'Visible', 'off')
        set(h_center_wv, 'Visible', 'off')
        set(h_autocenter_wv, 'Visible', 'off')  %, 'Value', 0
    end

    function fill_phase(wvnum, haxes) %fills colors according to phase
        axes(haxes)
        my_ylim = wvs(wvnum).ylimit;
        y = mean(my_ylim);
        fill_width = (my_ylim(2) - my_ylim(1)) * 0.5 * fill_scale;
        Y = [y-fill_width,y-fill_width,y+fill_width,y+fill_width];
        %trans1 = wvs(wvnum).trans;
        trans1 = subset_cell_array(wvs(wvnum).trans, 'menu', 1);
        
        if ~isempty(trans1)
            for i = 1:size(trans1,1)-1
                t1 = trans1{i,1};   %time
                t2 = trans1{i+1,1}; %time
                X = [t1, t2, t2, t1];
                
                switch trans1{i,2}  %phase name
                    case wvs(wvnum).fill.red
                        mycolor='r';
                    case wvs(wvnum).fill.green                        
                        mycolor='g';
                    case wvs(wvnum).fill.yellow
                        mycolor='y';
                    case wvs(wvnum).fill.black
                        mycolor = 'black';
                    case wvs(wvnum).fill.white
                        mycolor='w';
                    case wvs(wvnum).fill.blue
                        mycolor='blue';
                    case wvs(wvnum).fill.cyan
                        mycolor='cyan';
                    case wvs(wvnum).fill.magenta
                        mycolor='magenta';
                    otherwise
                        mycolor='w';
                end
                
                hold on
                hfill_wv = fill(X, Y, mycolor, 'Parent', haxes);
                alpha(hfill_wv, myalpha);
                set(hfill_wv, 'HitTest', 'off');  %cannot select with mouseclick
            end  %for i trans
        end  %isempty
    end   %fill_phase

    function plot_cpr(haxes_wv)
        axes(haxes_wv)
        my_ylim = get(haxes_wv, 'YLim');
        fill_width = (my_ylim(2) - my_ylim(1)) * 0.025;
        
        [cpr_subset] = subset_cell_array(patient.trans, 'cpr', 1);
        
        for i = 1:size(cpr_subset,1)-1
            t1 = cpr_subset{i,1};   %time
            t2 = cpr_subset{i+1,1}; %time
            X = [t1, t2, t2, t1];
            Y = [my_ylim(2)-fill_width,my_ylim(2)-fill_width,my_ylim(2)+fill_width,my_ylim(2)+fill_width];
            index = strcmp(cpr_subset{i,2}, patient.annot_cpr(:));
            hold on
            fill(X, Y, patient.color_cpr{index})
            %fill(X, Y, mycolor);
        end
    end

    function plot_patient(my_cell_array, mylabel)
        axes(haxes_top)  %this sets current axis to top plot
        noncpr_subset = subset_cell_array(my_cell_array, 'cpr', 0);
        nrow = size(noncpr_subset, 1);
        if nrow>0
            for i=1:nrow
                if length(noncpr_subset{i,1}) == 1    %time has entry
                    longlabel = [mylabel ' ' num2str(noncpr_subset{i,2})];
                    text(noncpr_subset{i,1}, y_patient_text, longlabel)
                end
            end
        end
    end

    function plot_wave_freetext(my_cell_array, haxes_wv)
        axes(haxes_wv)
        my_ylim = get(haxes_wv, 'YLim');
        y_text = my_ylim(1) + range(my_ylim) * text_offset_gen;
        freetext_array = subset_cell_array(my_cell_array, 'freetext', 1);
        nrow = size(freetext_array, 1);
        if nrow>0
            for i=1:nrow
                if length(freetext_array{i,1}) == 1    %time has entry
                    longlabel = [num2str(freetext_array{i,2})];
                    text(freetext_array{i,1}, y_text, longlabel)
                end
            end
        end
    end


%% X Axis (time) controls


%forward button
hForward  = uicontrol(f, 'Style','pushbutton',...
    'String','Forward','Position',[17*u,0, u, u],...
    'Callback',{@Forward_Callback});

    function Forward_Callback(~,~)
        % Display Forward plot of the currently selected data.
        if (x_offset + xrange) < max_time    %only advances if not at end of case
            x_offset = x_offset + xrange * 0.90;
        else
            x_offset = max_time - xrange;
        end        
        xlim([x_offset x_offset+xrange]);
        set(h_x_offset_step, 'Value', x_offset)
        autocenter_all_waves()
    end

%back button
hBackward  = uicontrol(f,'Style','pushbutton',...
    'String','Backward','Position',[16*u, 0, u, u],...
    'Callback',{@Backward_Callback});

    function Backward_Callback(~,~)
        % Display Backward plot of the currently selected data.
        new_offset = x_offset - xrange * 0.90;
        if  new_offset > 0
            x_offset = new_offset;
        else
            x_offset = 0;
        end
        xlim([x_offset x_offset+xrange]);
        set(h_x_offset_step, 'Value', x_offset)
        autocenter_all_waves()
    end

h_time_step = uicontrol(f,'Style','slider', 'Position', [9*u, 0, 2*u , u/2],...
    'Callback',{@time_step_Callback});
%this is initialized in case_initialize:

    function time_step_Callback(source,~)
        xrange = get(source,'Value');
        xlim([x_offset x_offset+xrange]) ;
        autocenter_all_waves()
    end

h_x_offset_step = uicontrol(f, 'Style','slider', 'Position', [4*u, 0, 2*u , u/2],...
    'Callback', {@x_offset_step_Callback});

    function x_offset_step_Callback(source,~)
        x_offset = get(source,'Value');
        xlim([x_offset x_offset+xrange]) ;
        autocenter_all_waves()
    end

%goto button with label
htext  = uicontrol(f, 'Style','text','String','Go to time:',...
    'Position',[2*u,0,0.75*u,u/2]);
hGoto = uicontrol(f, 'Style','edit',...
    'String','','Position',[3*u,0,u/2,u/2],...
    'Callback',{@Goto_Callback});

    function Goto_Callback(source,~)
        time_str = get(source,'String');
        x_offset = str2double(time_str);
        xlim([x_offset x_offset+xrange]);
        set(hGoto, 'String', '')  %erases entry
        set(h_x_offset_step, 'Value', x_offset)
        autocenter_all_waves()
    end

%Advanced mouse controls

    function scrollwheel_callback(~,event)
        scroll_pct = 0.03;
        if event.VerticalScrollCount > 0   %forward
            if (x_offset + xrange) < max_time    %only advances if not at end of case
                x_offset = x_offset + xrange * scroll_pct;
                xlim([x_offset x_offset+xrange]);
                set(h_x_offset_step, 'Value', x_offset)
                %autocenter_all_waves()
            end
        elseif event.VerticalScrollCount < 0   %backward
            new_offset = x_offset - xrange * scroll_pct;
            if  new_offset > 0
                x_offset = new_offset;
            else
                x_offset = 0;
            end
            xlim([x_offset x_offset+xrange]);
            set(h_x_offset_step, 'Value', x_offset)
            %autocenter_all_waves()
        end
    end

    function wbd_callback(src,evnt)
        if strcmp(get(src,'SelectionType'),'normal')  %left click
            Backward_Callback(999, 999)  %999 is dummy
        elseif strcmp(get(src,'SelectionType'),'alt')  %right click
            Forward_Callback(999,999)
        end
    end
% to activate this function, must add the following line to figure f definition:
% 'WindowButtonDownFcn', @wbd_callback,...
% right now, it is not activated, because it creates more problems


%% Y Axis controls: zoom_in, zoom_out

h_zoom_in_wvA   = uicontrol(f, 'Style','pushbutton',...
    'Visible', 'off',...
    'String','Z+',...
    'Callback',{@scale_wv_Callback, scaling_factor});
h_zoom_out_wvA  = uicontrol(f, 'Style','pushbutton','Visible', 'off',...
    'String','Z-',...
    'Callback',{@scale_wv_Callback, 1/scaling_factor});

h_zoom_in_wvB   = uicontrol(f,'Style','pushbutton','Visible', 'off',...
    'String','Z+',...
    'Callback',{@scale_wv_Callback, scaling_factor});
h_zoom_out_wvB  = uicontrol(f,'Style','pushbutton','Visible', 'off',...
    'String','Z-',...
    'Callback',{@scale_wv_Callback, 1/scaling_factor});

h_zoom_in_wvC   = uicontrol(f, 'Style','pushbutton','Visible', 'off',...
    'String','Z+',...
    'Callback',{@scale_wv_Callback, scaling_factor});
h_zoom_out_wvC  = uicontrol(f, 'Style','pushbutton','Visible', 'off',...
    'String','Z-',...
    'Callback',{@scale_wv_Callback, 1/scaling_factor});

h_zoom_in_wvD   = uicontrol(f, 'Style','pushbutton','Visible', 'off',...
    'String','Z+',...
    'Callback',{@scale_wv_Callback, scaling_factor});
h_zoom_out_wvD  = uicontrol(f, 'Style','pushbutton','Visible', 'off',...
    'String','Z-',...
    'Callback',{@scale_wv_Callback, 1/scaling_factor});

    function scale_wv_Callback(source,eventdata, factor)
        switch source
            case {h_zoom_in_wvA, h_zoom_out_wvA}
                wvnum = i_wvA;
                haxes_wv = haxes_wvA;
            case {h_zoom_in_wvB, h_zoom_out_wvB}
                wvnum = i_wvB;
                haxes_wv = haxes_wvB;
            case {h_zoom_in_wvC, h_zoom_out_wvC}
                wvnum = i_wvC;
                haxes_wv = haxes_wvC;
            case {h_zoom_in_wvD, h_zoom_out_wvD}
                wvnum = i_wvD;
                haxes_wv = haxes_wvD;
        end  %switch
        current_y = get(haxes_wv, 'YLim');
        %wvs(wvnum).ylimit(2) =  wvs(wvnum).ylimit(1) + range(current_y) * factor;
        half_range = range(current_y)/2;
        midpt = mean(current_y);
        wvs(wvnum).ylimit = [(midpt - half_range * factor)  (midpt + half_range * factor)];
        set(haxes_wv, 'YLim', wvs(wvnum).ylimit)
        replot_subplot(haxes_wv, wvnum)
    end

    function replot_subplot(haxes_wv, wvnum)
        handles = get(haxes_wv, 'Children');
        if isfield(wvs(wvnum), 'Valid') && plot_valid
            n_lines = 2; %valid + invalid
        else
            n_lines = 1; %only 1 line/wave
        end
        delete(handles(1:(length(handles)-n_lines)))  %deletes all objects assoc with this subplot except line
        plot_cpr(haxes_wv)
        fill_phase(wvnum, haxes_wv)
    end

h_up_wvA   = uicontrol(f, 'Style','pushbutton', 'String', 'Up', 'Visible', 'off',...
    'Position',[up_down_x, y_wvA, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, -1});
h_down_wvA  = uicontrol(f, 'Style','pushbutton', 'Visible', 'off',...
    'String','Down','Position',[up_down_x,y_wvA - 0.4*u, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, 1});

h_up_wvB   = uicontrol(f, 'Style','pushbutton', 'String', 'Up', 'Visible', 'off',...
    'Position',[up_down_x, y_wvB, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, -1});
h_down_wvB  = uicontrol(f, 'Style','pushbutton', 'Visible', 'off',...
    'String','D','Position',[up_down_x,y_wvB - 0.4*u, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, 1});

h_up_wvC   = uicontrol(f, 'Style','pushbutton', 'String', 'Up', 'Visible', 'off',...
    'Position',[up_down_x, y_wvC, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, -1});
h_down_wvC  = uicontrol(f, 'Style','pushbutton', 'Visible', 'off',...
    'String','D','Position',[up_down_x,y_wvC - 0.4*u, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, 1});

h_up_wvD   = uicontrol(f, 'Style','pushbutton', 'String', 'Up', 'Visible', 'off',...
    'Position',[up_down_x, y_wvD, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, -1});
h_down_wvD  = uicontrol(f, 'Style','pushbutton', 'Visible', 'off',...
    'String','D','Position',[up_down_x,y_wvD - 0.4*u, 0.4*u, 0.4*u],...
    'Callback',{@up_down_wv_Callback, 1});

    function up_down_wv_Callback(source,~, factor)
        switch source
            case {h_up_wvA, h_down_wvA}
                wvnum = i_wvA;
                haxes_wv = haxes_wvA;
            case {h_up_wvB, h_down_wvB}
                wvnum = i_wvB;
                haxes_wv = haxes_wvB;
            case {h_up_wvC, h_down_wvC}
                wvnum = i_wvC;
                haxes_wv = haxes_wvC;
            case {h_up_wvD, h_down_wvD}
                wvnum = i_wvD;
                haxes_wv = haxes_wvD;
        end  %switch
        current_y = get(haxes_wv, 'YLim');
        stepsize = factor * range(current_y) * vert_factor;
        wvs(wvnum).ylimit = current_y + stepsize;
        set(haxes_wv, 'YLim', wvs(wvnum).ylimit)
        replot_subplot(haxes_wv, wvnum)
    end


h_center_wvA   = uicontrol(f, 'Style','pushbutton', 'String', 'Center', 'Visible', 'off',...
    'Position',[up_down_x, y_wvA + 0.4*u, u, 0.4*u],...
    'Callback',{@center_wv_Callback});
h_center_wvB   = uicontrol(f, 'Style','pushbutton', 'String', 'Center', 'Visible', 'off',...
    'Position',[up_down_x, y_wvB + 0.4*u, u, 0.4*u],...
    'Callback',{@center_wv_Callback});
h_center_wvC   = uicontrol(f, 'Style','pushbutton', 'String', 'Center', 'Visible', 'off',...
    'Position',[up_down_x, y_wvC + 0.4*u, u, 0.4*u],...
    'Callback',{@center_wv_Callback});
h_center_wvD   = uicontrol(f, 'Style','pushbutton', 'String', 'Center', 'Visible', 'off',...
    'Position',[up_down_x, y_wvD + 0.4*u, u, 0.4*u],...
    'Callback',{@center_wv_Callback});

    function center_wv_Callback(source,~)
        switch source
            case {h_center_wvA}
                wvnum = i_wvA;
                haxes_wv = haxes_wvA;
            case {h_center_wvB}
                wvnum = i_wvB;
                haxes_wv = haxes_wvB;
            case {h_center_wvC}
                wvnum = i_wvC;
                haxes_wv = haxes_wvC;
            case {h_center_wvD}
                wvnum = i_wvD;
                haxes_wv = haxes_wvD;
        end  %switch
        
        xlimit = get(haxes_wv, 'XLim');
        i1 = find(wvs(wvnum).x >= xlimit(1), 1, 'first');   %index for 1st time
        i2 = find(wvs(wvnum).x <= xlimit(2), 1, 'last');   %index for 2nd time
        
        if isfield(wvs(wvnum), 'Valid') && plot_valid
            %[y_valid, ~] = separate_wave_Y_by_validity(wvs(wvnum).y, wvs(wvnum).Valid);
            y = wvs(wvnum).y_valid(i1:i2);
            y = y(~isnan(y));  %remove missing data
        else
            y = wvs(wvnum).y(i1:i2);
            y = y(~isnan(y));  %remove missing data
        end
        if ~isempty(y) && range(y)~=0
            wvs(wvnum).ylimit = quantile(y, [0 1]);  %y ranger is 0-100%
        end
        set(haxes_wv, 'YLim', wvs(wvnum).ylimit)
        replot_subplot(haxes_wv, wvnum)
    end

h_autocenter_wvA = uicontrol(f, 'Style', 'radiobutton', 'String', 'Auto', 'Visible', 'off',...
    'Value', 0);
h_autocenter_wvB = uicontrol(f, 'Style', 'radiobutton', 'String', 'Auto', 'Visible', 'off',...
    'Value', 0);
h_autocenter_wvC = uicontrol(f, 'Style', 'radiobutton', 'String', 'Auto', 'Visible', 'off',...
    'Value', 0);
h_autocenter_wvD = uicontrol(f, 'Style', 'radiobutton', 'String', 'Auto', 'Visible', 'off',...
    'Value', 0);

    function autocenter_all_waves()
          if ~isempty(i_wvA) && get(h_autocenter_wvA, 'Value')
            [wvs(i_wvA).ylimit] = set_ylimit_centered(i_wvA, haxes_wvA);
            replot_subplot(haxes_wvA, i_wvA)
          end
          if ~isempty(i_wvB) && get(h_autocenter_wvB, 'Value')
            [wvs(i_wvB).ylimit] = set_ylimit_centered(i_wvB, haxes_wvB);
            replot_subplot(haxes_wvB, i_wvB)
          end
          if ~isempty(i_wvC) && get(h_autocenter_wvC, 'Value')
            [wvs(i_wvC).ylimit] = set_ylimit_centered(i_wvC, haxes_wvC);
            replot_subplot(haxes_wvC, i_wvC)
          end
          if ~isempty(i_wvD) && get(h_autocenter_wvD, 'Value')
            [wvs(i_wvD).ylimit] = set_ylimit_centered(i_wvD, haxes_wvD);
            replot_subplot(haxes_wvD, i_wvD)
          end        
    end

%% Case summary
figure_case_summary = figure('Visible','off','Units','normalized', 'Name','Case Summary',...
    'Position', figure_case_summary_pos);  %figure window

hradio_case_summary = uicontrol(f, 'Style','radiobutton',...
    'String','Case summary',...
    'Visible', 'off',...
    'Value',0,...         %default is no table
    'Position',[0*u,16*u,1.5*u,u],...
    'Callback',{@radio_case_summary_Callback});

    function radio_case_summary_Callback(source,eventdata)
        on = get(source,'Value');  %1 if selected
        if on
                    line0 = ['CASS: ' num2str(patient.ClinData.id)];
                    line1 = ['Age: ' num2str(patient.ClinData.age)];
                    line2 = ['Male: ' num2str(patient.ClinData.male)];
                    line3 = ['Arrest No: ' num2str(patient.ClinData.arrestno)];
                    line4 = ['Location: ' patient.ClinData.location];
                    line5 = ['Witnessed: ' patient.ClinData.witness_cat];
                    line6 = ['Bystander CPR: ' num2str(patient.ClinData.byCPR)];
                    line7 = ['Initial rhythm: ' patient.ClinData.rhythm];
                    line8 = ['Presumed cardiac: ' num2str(patient.ClinData.cardiac)];
                    line9 = ['Response time: ' num2str(patient.ClinData.RTFirst)];
                    line10 = ['ROSC: ' num2str(patient.ClinData.rosc)];
                    line11 = ['Survival to admission: ' num2str(patient.ClinData.survival_admit)];
                    line12 = ['Survival to hospital discharge: ' num2str(patient.ClinData.survival_dc)];
                    string_array = {line0 line1 line2 line3 line4 line5 line6 line7...
                        line8 line9 line10 line11 line12};
                    set(hcase_summary, 'String', string_array)
                    set(figure_case_summary, 'Visible','on')            
                    figure(figure_case_summary)  %brings figure to front         
        else
            set(figure_case_summary, 'Visible','off')
            figure(f)  %go to main window
        end
    end  %function

hcase_summary  = uicontrol(figure_case_summary, 'Style','text',...
    'HorizontalAlignment', 'left', 'Position',[0,0,1,1]);
%string will be added when case is loaded


%% tables of transition matrices for waves
%figure_table_A is the figure window that holds table_A
%table A contains data from wv(i_wvA).trans, which is a cell array

h_table_panel = uipanel('Parent', f, 'Title', 'Tables',...
    'Visible', 'on',...
    'Position', [0*u,6*u,1.5*u,7*u]);
%panel for table radio buttons: hradio_transA/B/C

figure_table_A = figure('Visible','off','Units','normalized', ...
    'Position', figure_table_A_pos);

table_A = uitable(figure_table_A, ...
    'ColumnName', {'Time', 'Phase', 'Type', 'User'},...
    'Units', 'normalized', 'Position', [0,0,1,1], ...%table fills entire fig window
    'ColumnFormat',{'shortg','char', 'char', 'char'},...  %avoid scientific notation
    'CellEditCallback', {@table_Callback});
%'ColumnEditable', [true, false],... %makes all columns editable

hradio_trans_A = uicontrol('Parent', h_table_panel, 'Style','radiobutton',...
    'Value',0,...         %default is no table
    'Visible', 'off',...
    'Position',[0, 0.8, 1, 0.1],...
    'Callback',{@radio_trans_Callback});

figure_table_B = figure('Visible','off','Units','normalized', ...
    'Position', figure_table_B_pos);

table_B = uitable(figure_table_B,...
    'ColumnName', {'Time', 'Phase', 'Type', 'User'},...
    'Units', 'normalized', 'Position', [0,0,1,1], ...%fills entire fig window
    'ColumnFormat',{'shortg','char', 'char', 'char'},...
    'CellEditCallback',  {@table_Callback});

hradio_trans_B = uicontrol('Parent', h_table_panel, 'Style','radiobutton',...
    'Value',0,...         %default is no table
    'Visible', 'off',...
    'Position',[0, 0.7, 1, 0.1],...
    'Callback', {@radio_trans_Callback});

figure_table_C = figure('Visible','off','Units','normalized', ...
    'Position', figure_table_C_pos);

table_C = uitable(figure_table_C, ...
    'ColumnName', {'Time', 'Phase', 'Type', 'User'},...
    'Units', 'normalized', 'Position', [0,0,1,1], ...%fills entire fig window
    'ColumnFormat',{'shortg','char', 'char', 'char'},...
    'CellEditCallback', {@table_Callback});

hradio_trans_C = uicontrol('Parent', h_table_panel, 'Style','radiobutton',...
    'Value',0,...         %default is no table
    'Visible', 'off',...
    'Position',[0, 0.6, 1, 0.1],...
    'Callback',{@radio_trans_Callback});

figure_table_D = figure('Visible','off','Units','normalized', ...
    'Position', figure_table_D_pos);

table_D = uitable(figure_table_D, ...
    'ColumnName', {'Time', 'Phase', 'Type', 'User'},...
    'Units', 'normalized', 'Position', [0,0,1,1], ...%fills entire fig window
    'ColumnFormat',{'shortg','char', 'char', 'char'},...
    'CellEditCallback', {@table_Callback});

hradio_trans_D = uicontrol('Parent', h_table_panel, 'Style','radiobutton',...
    'Value',0,...         %default is no table
    'Visible', 'off',...
    'Position',[0, 0.5, 1, 0.1],...
    'Callback',{@radio_trans_Callback});

% table editing callback functions
    function table_Callback(hObject, eventdata)
        %hObject = handle of calling object, eg table_A
        indices = eventdata.Indices;  %indices(1) is row, indices(2) is col of edited cell
        
        switch hObject
            case table_A
                haxes = haxes_wvA;
                wvnum = i_wvA;
                fighandle = figure_table_A;
            case table_B
                haxes = haxes_wvB;
                wvnum = i_wvB;
                fighandle = figure_table_B;
            case table_C
                haxes = haxes_wvC;
                wvnum = i_wvC;
                fighandle = figure_table_C;
            case table_D
                haxes = haxes_wvD;
                wvnum = i_wvD;
                fighandle = figure_table_D;
        end
        
        if strcmp(wvs(wvnum).trans(indices(1), 4), auto_code) %can't edit if user (4th col) = auto
            set(hObject,'Data', wvs(wvnum).trans)   %this reprints table without any changes
        else
            if indices(2)==1    %edit time=1st col;
                if isnan(eventdata.NewData)
                    wvs(wvnum).trans(indices(1),:) = [];
                    set(hObject,'Data', wvs(wvnum).trans)    %reprint table
                else wvs(wvnum).trans{indices(1), indices(2)} = eventdata.NewData;
                end
            end
            
            %sort and save
            wvs(wvnum).trans = sortrows(wvs(wvnum).trans, 1);
            trans.(wvs(wvnum).file) = wvs(wvnum).trans;
            save(trans_filename, 'trans')
            
            %replot
            replot_subplot(haxes, wvnum)
            %plot_case()           %replot to show edits
            figure(fighandle)  %makes table window active
            
        end
    end  %table_Callback

    function radio_trans_Callback(source, eventdata)
        on = get(source,'Value');  %1 if selected
        %first figure out which wave this is.
        %can't pass wvnum directly with function callback
        switch source
            case hradio_trans_A
                wvnum = i_wvA;
                myfigure_handle = figure_table_A;
                table_handle = table_A;
            case hradio_trans_B
                wvnum = i_wvB;
                myfigure_handle = figure_table_B;
                table_handle = table_B;
            case hradio_trans_C
                wvnum = i_wvC;
                myfigure_handle = figure_table_C;
                table_handle = table_C;
            case hradio_trans_D
                wvnum = i_wvD;
                myfigure_handle = figure_table_D;
                table_handle = table_D;
        end
        if on
            if ~isempty(wvnum)
                set(myfigure_handle, 'Visible','on')
                figure(myfigure_handle)  %brings table figure to front
                set(table_handle, 'Data', wvs(wvnum).trans)
            end
        else
            set(myfigure_handle, 'Visible','off')
            figure(f)  %go to main window
        end
    end  %function


%% measures

hupdate_meas   = uicontrol(f, 'Style', 'pushbutton',...
    'String','Calculate measures', 'Position', [wavetype_x, y_update_measures, 1.5*u, u],...
    'Visible', 'off',...
    'Callback',{@update_meas_Callback});

hauto_refresh_meas = uicontrol(f, 'Style', 'radiobutton',...
    'String', 'Auto-refresh measures',...
    'Value', 0,...         %must be initialized with each new case
    'Position',[wavetype_x, y_update_measures - u, 1.5*u, u],...
    'Visible', 'on');

hWarning = uicontrol(f, 'Style','text','String','', ...
    'Position',[10*u,10*u,3*u,3*u], 'Visible', 'off',...
    'FontSize',14);

    function update_meas_Callback(~,~)
        set(hWarning, 'Visible','on', 'String', 'Calculating measures')
        pause(0.1)
        for i = 1:length(wv_loaded)
            if any(wv_loaded(i) == wv_enable_measure)
                [wvs(wv_loaded(i)), measure] = feval(measures_function, meas_filename, wvs(wv_loaded(i)), measure);
            end
        end
        set(hWarning, 'Visible','off')
        pause(0.1)
    end



%% Cursor Control: annotation and correcting offsets
dcm_obj = datacursormode(f);
set(dcm_obj, 'Enable', 'off', 'DisplayStyle','datatip', 'SnapToDataVertex','on','UpdateFcn', @annotate_fxn)
%Calls annotate_fxn when clicked if enabled
%keep disabled except when to annotate, because otherwise prevents
%WindowScrollWheelFcn

    function dispkeyevent(~, event)  %enables annotation if case not locked
        specialkey = event.Modifier;   %eg 'shift', 'alt', 'control'
        if ~isempty(specialkey)  %must be a modifier key
            if CaseList(activeindex).lock
                set(hWarning, 'Visible','on', 'String', 'Unlock case to edit')
                pause(1)
                set(hWarning, 'Visible','off')
            else
                if strcmp(specialkey, 'control')
                    set(dcm_obj, 'Enable','on', 'UpdateFcn', @annotate_fxn)
                    pause(0.1)  %makes matlab perform above statement
                elseif strcmp(specialkey, 'alt')
                    set(h_shift_wave_panel, 'Visible', 'on')
                    uistack(h_shift_wave_panel, 'top')
                    set(h_shift_wave_text, 'String', 'Click point to move')
                    set(dcm_obj, 'Enable','on', 'UpdateFcn', @shift_wave_fxn)
                    pause(0.01) %makes matlab perform above statement
                end
            end
        end
    end


%% Annotate function and make annotate options
h_annotate_panel = uipanel('Parent', f, 'Visible', 'off', 'Position', [10*u, 10*u, 3*u, 9*u]);

    function txt = annotate_fxn(~,event_obj)
        % Customizes text of data tips; update function for dcm for annotation
        set(dcm_obj, 'Enable','off')
        datacursormode off  %prevents cursor from moving
        pos = get(event_obj,'Position');   %position relative to figure axes
        txt = {['Time: ',num2str(pos(1))]};
        make_annotate_box()  %adds options to annotation box

    end

    function make_annotate_box()
        %choices for annotation, depending upon which waveform is selected
        %positions annotation panel next to cursor
        c_info = getCursorInfo(dcm_obj);
        cursor_time = c_info.Position(1);
        h_target_wv = c_info.Target;  %handle of data object
        
        %update annotate panel
        set(h_annotate_panel, 'Visible', 'on')
        uistack(h_annotate_panel, 'top')
        
        switch h_target_wv
            case h_wvA
                h_target_axes = haxes_wvA;
                wv_select = i_wvA;
                set(h_annotate_panel, 'Title', wvs(i_wvA).label)
                opts = vertcat('WAVE', wvs(i_wvA).annot_opts(:));
                set(h_annot_wave, 'String', opts)
                
            case h_wvB
                h_target_axes = haxes_wvB;
                wv_select = i_wvB;
                set(h_annotate_panel, 'Title', wvs(i_wvB).label)
                opts = vertcat('WAVE', wvs(i_wvB).annot_opts(:));
                set(h_annot_wave, 'String', opts)
                
            case h_wvC
                h_target_axes = haxes_wvC;
                wv_select = i_wvC;
                set(h_annotate_panel, 'Title', wvs(i_wvC).label)
                opts = vertcat('WAVE', wvs(i_wvC).annot_opts(:));
                set(h_annot_wave, 'String', opts)
                
            case h_wvD
                h_target_axes = haxes_wvD;
                wv_select = i_wvD;
                set(h_annotate_panel, 'Title', wvs(i_wvD).label)
                opts = vertcat('WAVE', wvs(i_wvD).annot_opts(:));
                set(h_annot_wave, 'String', opts)
        end
    end


%% annotate wave

h_annot_wave = uicontrol('Parent', h_annotate_panel, 'Style','popupmenu',...
    'Value', 1, 'String', {''}, ...
    'Position',[0,0.8,1,0.2],...
    'Visible', 'on',...
    'Callback',{@annot_wv_Callback});

h_annot_cpr_clip = uicontrol('Parent', h_annotate_panel, 'Style','popupmenu',...
    'Value', 1, ...
    'Visible', 'off', ...
    'String', {'Compressions: force AND imped','CPR','No CPR', 'CPR Artifact'} ,...
    'Position',[0, 0.8, 1, 0.1],...
    'Callback',{@annot_wv_Callback});

h_annotate_text_wave = uicontrol(h_annotate_panel, 'Style', 'edit', ...
    'String','', 'Visible', 'off',...
    'FontSize', 9, 'HorizontalAlignment', 'left', ...
    'Position',[0, 0.5, 1, 0.07], ...
    'Callback',{@annotate_enter_text_wave_Callback});

h_annotate_open_textbox_wave = uicontrol('Parent', h_annotate_panel, 'Style','pushbutton',...
    'String','Wave free text', 'Visible', 'on',...
    'Position',[0, 0.5, 1, 0.07],...
    'Callback',{@hannot_open_textbox_Callback, h_annotate_text_wave});

    function annot_wv_Callback(hObject, eventdata)
        %hObject is either h_annot_wave or h_annot_cpr_pci_forc
        index_selected = get(hObject,'Value');  %number of item in list
        list = get(hObject,'String');  %vector options
        item_selected = list{index_selected}; % Convert from cell array
        
        switch wv_select
            case i_wvA
                tab_handle = table_A;
            case i_wvB
                tab_handle = table_B;
            case i_wvC
                tab_handle = table_C;
            case i_wvD
                tab_handle = table_D;
        end
        
        if hObject == h_annot_cpr_clip
            run_other_cpr_pci_forc = 1;
        else run_other_cpr_pci_forc = 0;
        end
        
        if index_selected ~= 1
            my_row = size(wvs(wv_select).trans, 1) + 1;
            wvs(wv_select).trans{my_row,1} = cursor_time;  %time
            wvs(wv_select).trans{my_row,2} = item_selected;
            wvs(wv_select).trans{my_row,3} = 'menu';
            wvs(wv_select).trans{my_row,4} = user;
            wvs(wv_select).trans = sortrows(wvs(wv_select).trans, 1);  %sorts ascending order by 1st col=time
            
            trans.(wvs(wv_select).file) = wvs(wv_select).trans;
            save(trans_filename, 'trans')
            set(tab_handle, 'Data',  wvs(wv_select).trans);
            %replot_subplot(h_target_axes, wv_select)
            
            if run_other_cpr_pci_forc
                switch wvs(wv_select).label
                    case 'impedence'
                        wvnum = find(strcmp(wv_label, 'accelerometer'));
                    case 'accelerometer'
                        wvnum = find(strcmp(wv_label, 'impedence'));
                end
                
                switch wvnum
                    case i_wvA
                        tab_handle2 = table_A;
                        axes_handle2 = haxes_wvA;
                    case i_wvB
                        tab_handle2 = table_B;
                        axes_handle2 = haxes_wvB;
                    case i_wvC
                        tab_handle2 = table_C;
                        axes_handle2 = haxes_wvC;
                    case i_wvD
                        tab_handle2 = table_D;
                        axes_handle2 = haxes_wvD;
                end
                
                my_row = size(wvs(wvnum).trans, 1) + 1;
                wvs(wvnum).trans{my_row,1} = cursor_time;  %time
                wvs(wvnum).trans{my_row,2} = item_selected;
                wvs(wvnum).trans{my_row,3} = 'menu';
                wvs(wvnum).trans{my_row,4} = user;
                wvs(wvnum).trans = sortrows(wvs(wvnum).trans, 1);  %sorts ascending order by 1st col=time
                
                trans.(wvs(wvnum).file) = wvs(wvnum).trans;
                save(trans_filename, 'trans')
                set(tab_handle2, 'Data',  wvs(wvnum).trans);
                %replot_subplot(axes_handle2, wvnum)
            end
        end
                        
        set(hObject, 'Value', 1)
        set(h_annotate_panel, 'Visible', 'off')    %make annotate box disappear
        set(dcm_obj, 'Enable','off')
        plot_case()
    end

    function annotate_enter_text_wave_Callback(source,~)
        textstr = get(source,'String');
        %wv_select
        
        nrow = size(wvs(wv_select).trans, 1) + 1;
        wvs(wv_select).trans{nrow,1} = cursor_time;  %time
        wvs(wv_select).trans{nrow,2} = textstr;
        wvs(wv_select).trans{nrow,3} = 'freetext';
        wvs(wv_select).trans{nrow,4} = user;
        wvs(wv_select).trans = sortrows(wvs(wv_select).trans, 1);
        
        trans.(wvs(wv_select).file) = wvs(wv_select).trans;
        save(trans_filename, 'trans')
        set(h_annotate_text_wave, 'String', '', 'Visible', 'off')
        set(h_annotate_panel, 'Visible', 'off')
        plot_case()
        %replot_subplot(h_target_axes, wv_select)
    end

%% Annotate patient events, CPR

h_annotate_patient_event = uicontrol('Parent', h_annotate_panel, 'Style','popupmenu',...
    'Value', 1,  'String', {'Event'},...
    'Position',[0, 0.7, 1, 0.1],...
    'Visible', 'on',...
    'Callback',{@annotate_pt_event_Callback, 'intervent'});

h_annotate_cpr_ava = uicontrol('Parent', h_annotate_panel, 'Style', 'popupmenu',...
    'Value', 1,  'String', {'Compressions'},...
    'Visible', 'off', ...
    'Position',[0, 0.6, 1, 0.1],...
    'Callback',{@annotate_pt_event_Callback, 'cpr'});

h_annotate_text_event = uicontrol(h_annotate_panel, 'Style', 'edit', ...
    'String','', 'Visible', 'off',...
    'FontSize', 9, 'HorizontalAlignment', 'left', ...
    'Position',[0, 0.4, 1, 0.07], ...
    'Callback',{@annotate_enter_text_event_Callback});

h_annotate_open_textbox_event = uicontrol('Parent', h_annotate_panel, 'Style','pushbutton',...
    'String','Patient event free text', 'Visible', 'on',...
    'Position',[0, 0.4, 1, 0.07],...
    'Callback',{@hannot_open_textbox_Callback, h_annotate_text_event});

    function annotate_pt_event_Callback(hObject, ~, mytype)
        index_selected = get(hObject,'Value');  %number of item in list
        list = get(hObject,'String');  %vector options
        textstr = list{index_selected};
        
        if index_selected ~= 1
            nrow = size(patient.trans, 1) + 1;
            patient.trans{nrow,1} = cursor_time;  %time
            patient.trans{nrow,2} = textstr;
            patient.trans{nrow,3} = mytype;
            patient.trans{nrow,4} = user;
            patient.trans = sortrows(patient.trans, 1);
            
            trans.patient = patient.trans;
            save(trans_filename, 'trans')
            
            set(hObject, 'Value', 1)
            plot_patient(patient.trans, '')            
        end
        set(h_annotate_panel, 'Visible', 'off')
        plot_case()
    end

    function hannot_open_textbox_Callback(~,~, textbox)
        set(textbox, 'Visible', 'on')
        uicontrol(textbox)
    end

    function annotate_enter_text_event_Callback(source,~)
        textstr = get(source,'String');
        nrow = size(patient.trans, 1) + 1;
        patient.trans{nrow,1} = cursor_time;  %time
        patient.trans{nrow,2} = textstr;
        patient.trans{nrow,3} = 'freetext';
        patient.trans{nrow,4} = user;
        patient.trans = sortrows(patient.trans, 1);
        
        trans.patient = patient.trans;
        save(trans_filename, 'trans')
        set(h_annotate_text_event, 'String', '', 'Visible', 'off')
        set(h_annotate_panel, 'Visible', 'off')
        plot_patient(patient.trans, '')
        plot_case()
    end

%% Annotate: cancel entry, edit_left and edit_right
hannot_no_entry = uicontrol('Parent', h_annotate_panel, 'Style','pushbutton',...
    'String','Cancel',...
    'Visible', 'on',...
    'Position',[0.25, 0, 0.5, 0.1],...
    'Callback',{@hannot_no_entry_Callback});

hannot_edit_left = uicontrol('Parent', h_annotate_panel, 'Style','popupmenu',...
    'String',{'Edit transition to left', 'Move here', 'Delete'},...
    'Value', 1, ...
    'Visible', 'on',...
    'Position',[0,0.2,1,0.1],...
    'Callback',{@hannot_edit_adjacent_Callback, 'left'});

hannot_edit_right = uicontrol('Parent', h_annotate_panel, 'Style','popupmenu',...
    'String',{'Edit transition to right', 'Move here', 'Delete'},...
    'Value', 1, ...
    'Visible', 'on',...
    'Position',[0,0.1,1,0.1],...
    'Callback',{@hannot_edit_adjacent_Callback, 'right'});


    function hannot_no_entry_Callback(source,eventdata)
        set(h_annotate_text_wave, 'String', '', 'Visible', 'off')
        set(h_annotate_text_event, 'String', '', 'Visible', 'off')
        set(h_annotate_panel, 'Visible', 'off')
        plot_case()   %replots case
    end

    function hannot_edit_adjacent_Callback(source, eventdata, direction)
        index_selected = get(source,'Value');  %number of item in list
        
        if index_selected ~= 1   %1 is no selection
            switch wv_select
                case i_wvA
                    tab_handle = table_A;
                case i_wvB
                    tab_handle = table_B;
                case i_wvC
                    tab_handle = table_C;
                case i_wvD
                    tab_handle = table_D;
            end  %switch
            
            trans_menu = subset_cell_array(wvs(wv_select).trans, 'menu', 1);  %not freetext annotations
            timeVector_menu = cell2mat(trans_menu(:,1));
            timeVector_all = cell2mat(wvs(wv_select).trans(:,1));
            if strcmp(direction, 'left')
                row_trans_menu = find(timeVector_menu < cursor_time, 1, 'last');  %previous
                adj_row = find(timeVector_all == timeVector_menu(row_trans_menu), 1, 'last');
            elseif strcmp(direction, 'right')
                row_trans_menu = find(timeVector_menu > cursor_time, 1, 'first');  %previous
                adj_row = find(timeVector_all == timeVector_menu(row_trans_menu), 1, 'first');
                
                %adj_row = find(timeVector > cursor_time, 1, 'first');  %next
            end
            
            %if ~strcmp(wvs(wv_select).trans(adj_row, 4), auto_code)
                if index_selected==2      %move
                    wvs(wv_select).trans{adj_row,1} = cursor_time;
                elseif index_selected==3  %delete
                    wvs(wv_select).trans(adj_row,:) = [];
                end
                trans.(wvs(wv_select).file) = wvs(wv_select).trans;
                save(trans_filename, 'trans')
                set(tab_handle, 'Data',  wvs(wv_select).trans);
            %end
            set(h_annotate_panel, 'Visible', 'off')
            set(source, 'Value', 1)  %go to top of menu
            %replot_subplot(h_target_axes, wv_select)
            plot_case()
        end
        
    end


%% Edit patient struct in table
% tables to edit patient struct
figure_patient_text = figure('Visible','off','Units','normalized', 'Position', figure_patient_pos);

table_patient_text = uitable(figure_patient_text, ...
    'ColumnName', {'Time', 'Event', 'Type', 'User'},...
    'Units', 'normalized', 'Position', [0,0,1,1], ...%table fills entire fig window
    'ColumnFormat',{'shortg','char', 'char', 'char'},...  %avoid scientific notation
    'ColumnWidth', {'auto' 'auto' 'auto', 'auto'}, ...   %width must be pixels (96 pixels/in)
    'ColumnEditable', [true, true, false, false],...
    'CellEditCallback', {@table_patient_Callback});

hradio_patient_text = uicontrol('Parent', h_table_panel, 'Style','radiobutton',...
    'Value',0,  'String', 'Patient', ...
    'Visible', 'on',...
    'Position',[0, 0.2, 1, 0.25],...
    'Callback',{@radio_patient_Callback});

    function radio_patient_Callback(source, eventdata)
        on = get(source,'Value');  %1 if selected
        if on
            if isfield(patient, 'trans')
                set(figure_patient_text, 'Visible','on')
                figure(figure_patient_text)  %brings table figure to front
                set(table_patient_text, 'Data', patient.trans)
            end
        else
            set(figure_patient_text, 'Visible','off')
            figure(f)  %go to main window
        end
    end  %function

    function table_patient_Callback(hObject, eventdata)
        indices = eventdata.Indices;  %indices(1) is row, indices(2) is col of edited cell
        if strcmp(patient.trans(indices(1), 4), auto_code)
            set(hObject,'Data', patient.trans)   %this reprints table without any changes
        else
            if indices(2)==1    %edit time=1st col
                if isnan(eventdata.NewData)
                    patient.trans(indices(1),:) = [];
                    set(hObject,'Data', patient.trans)    %reprint table
                else patient.trans{indices(1), indices(2)} = eventdata.NewData;
                end
            else
                patient.trans{indices(1), indices(2)} = eventdata.NewData;
            end
            
            %sort and save
            patient.trans = sortrows(patient.trans, 1);
            trans.patient = patient.trans;
            save(trans_filename, 'trans')
            
            %replot
            plot_case()
            %plot_patient(patient.trans, '')
            
            figure(figure_patient_text)  %makes table window active
            
        end
    end  %table_Callback


%% Correcting wave offsets

%when make a change, best to call plot_case to reset
%hshift_position = [10*u, 0*u, 2*u, 4*u];
%set(h_shift_wave_panel, 'Position', [u, 10*u, 2*u, 4*u])

h_shift_wave_panel = uipanel('Parent', f, 'Title','', 'Visible', 'off',...
    'Position', [5*u, 8*u, 2*u, 4*u]);

h_shift_wave_text = uicontrol('Parent', h_shift_wave_panel, 'Style','text',...
    'Position', [0,0.8,1,0.2], 'FontSize', 10);

h_confirm_move = uicontrol('Parent', h_shift_wave_panel, 'Style','pushbutton',...
    'String', 'Confirm move wave',...
    'Position', [0,0.6,1,0.2], 'Visible', 'off',...
    'Callback',{@hconfirm_move_Callback} );

h_cancel_move = uicontrol('Parent', h_shift_wave_panel, 'Style','pushbutton',...
    'String', 'Cancel',...
    'Position', [0,0.2,1,0.2], 'Visible', 'on',...
    'Callback',{@hcancel_move_Callback} );

    function txt = shift_wave_fxn(~,event_obj)  %for tip;
        % Customizes text of data tips
        pos = get(event_obj,'Position');   %position relative to figure axes
        txt = {['time: ',num2str(pos(1))]};
        
        c_info = getCursorInfo(dcm_obj);
        h_target_wv = c_info.Target;
        cursor_time = c_info.Position(1);
        
        switch h_target_wv
            case h_wvA
                wv_select = i_wvA;
            case h_wvB
                wv_select = i_wvB;
            case h_wvC
                wv_select = i_wvC;
            case h_wvD
                wv_select = i_wvD;
        end
        
        if any(wv_select == wv_enable_shift)
            time_shift_index = time_shift_index + 1;
            
            if time_shift_index==1
                time_shift(time_shift_index) = pos(1);
                set(h_shift_wave_panel, 'Visible', 'on')
                uistack(h_shift_wave_panel, 'top')
                set(h_shift_wave_text, 'String', 'Click destination')
            elseif time_shift_index==2
                time_shift(time_shift_index) = pos(1);
                set(h_shift_wave_panel, 'Visible', 'on')
                uistack(h_shift_wave_panel, 'top')
                set(h_confirm_move, 'Visible', 'on')
            else
                set(h_shift_wave_panel, 'Visible', 'off')
                set(h_confirm_move, 'Visible', 'off')
                set(dcm_obj, 'Enable','off')
                time_shift_index = 0;
                %replot_subplot(h_target_axes, wv_select)
                plot_case()
            end
        else
            set(h_shift_wave_panel, 'Visible', 'off')
            set(h_confirm_move, 'Visible', 'off')
            time_shift_index = 0;
            set(hWarning, 'Visible','on', 'String', 'Cannot shift this wave')
            pause(2)
            set(hWarning, 'Visible','off')
            set(dcm_obj, 'Enable','off')
            plot_case()
            %replot_subplot(h_target_axes, wv_select)
        end
    end

    function hcancel_move_Callback(source,eventdata)
        set(h_shift_wave_panel, 'Visible', 'off')
        set(h_confirm_move, 'Visible', 'off')
        set(dcm_obj, 'Enable','off')
        time_shift_index = 0;
        plot_case()
    end


    function hconfirm_move_Callback(source,eventdata)
        % c_info = getCursorInfo(dcm_obj);
        %h_target_wv = c_info.Target;  %handle of data object
        
        x1 = find(wvs(wv_select).x==time_shift(1));   %index for 1st time
        x2 = find(wvs(wv_select).x==time_shift(2));   %index for 2nd time
        record_change(time_shift, x1, x2, wv_select);
        
        npts = abs(x2 - x1);  %take absolute value
        yshift = wvs(wv_select).y;  % local variable for convenience
        len = length(yshift);
        if x2 > x1
            yshift(x2:len) = yshift(x1:(len-npts));
            yshift(x1:(x2-1)) = yshift(x1-1) * ones(1, npts);
            %repeats last value before x1 for npts
        else  % x2 < x1
            temp = yshift(x1:len);
            yshift(x2:(x2 + length(temp)-1)) = temp;
            yshift((x2 + length(temp)) : len) = yshift(len-npts) * ones(1, npts);
            %repeats last value for npts
        end
        wvs(wv_select).y = yshift;
        
        set(h_shift_wave_panel, 'Visible', 'off')
        set(h_confirm_move, 'Visible', 'off')
        set(dcm_obj, 'Enable','off')
        time_shift_index = 0;
        plot_case()
        
    end

    function record_change(times, x1, x2, wavenum)
        if ~isfield(shifts, wvs(wavenum).file)   %make shifts array if necessary
            shifts.( wvs(wavenum).file) = cell(0,5);
        end
        %cols: old time, new time, old index, new index, wave
        shift_row = size(shifts.( wvs(wavenum).file), 1) + 1;
        shifts.( wvs(wavenum).file){shift_row,1} = times(1);  %time
        shifts.( wvs(wavenum).file){shift_row,2} = times(2);
        shifts.( wvs(wavenum).file){shift_row,3} = x1;  %time
        shifts.( wvs(wavenum).file){shift_row,4} = x2;
        shifts.( wvs(wavenum).file){shift_row,5} = wvs(wavenum).file;
        shifts.( wvs(wavenum).file) = sortrows(shifts.( wvs(wavenum).file), 1);
        save(shifts_filename, 'shifts')
    end


end %function pleth_viewer_gui

