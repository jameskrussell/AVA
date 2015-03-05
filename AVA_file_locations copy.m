function [matDir, lock_filedir, CaseListFile, folder_string, config_function, measures_function] = AVA_file_locations()
% comment/uncomment for each project
% project
APACHI = 1;
CLIP = 0;

if APACHI
%% Annotation Team
global annot_Team;
if ~exist('annot_Team','var')
    error('annot_Team undefined');
end


%% APACHI
%%%if strcmp(annot_Team,'Clinical')
if strcmp(annot_Team,'sandbox')
    matDir = 'E:\Sync\sandbox\APACHI\AVA\'; % jkr's - add your own as needed
else
    if exist('C:\Dropbox\APACHI\Data\AVA','dir')
        matDir = 'C:\Dropbox\APACHI\Data\AVA\'; % note: trailing '\' is required
    elseif exist('C:\Users\heemun\Documents\Research\pleth\data\jim_031314','dir')
        matDir = 'C:\Users\heemun\Documents\Research\pleth\data\jim_031314\';    
    elseif exist('E:\Dropbox\APACHI\Data\AVA','dir')
        matDir = 'E:\Dropbox\APACHI\Data\AVA\';
    elseif exist('C:\Users\Admin\Dropbox\APACHI\Data\AVA','dir')
        matDir = 'C:\Users\Admin\Dropbox\APACHI\Data\AVA\';
    elseif exist('S:\APACHI\Data\AVA','dir')
        matDir = 'S:\APACHI\Data\AVA\';
        
    else
        disp('APACHI AVA directory unknown - seek your geek'); % this disp does not actually happen under error condition, but an error is thrown elsewhere
        return
    end
end
%%%else
%%%    if exist('C:\Dropbox\APACHI\Data\AVA','dir')
%%%        matDir = 'C:\Dropbox\APACHI\Data\AVA-Technical\'; % note: trailing '\' is required
        
%%%    elseif exist('E:\Dropbox\APACHI\Data\AVA','dir')
%%%        matDir = 'E:\Dropbox\APACHI\Data\AVA-Technical\';
%%%    elseif exist('C:\Users\Admin\Dropbox\APACHI\Data\AVA','dir')
%%%        matDir = 'C:\Users\Admin\Dropbox\APACHI\Data\AVA-Technical\';
        
%%%    else
%%%        disp('APACHI AVA directory unknown - seek your geek'); % this disp does not actually happen under error condition, but an error is thrown elsewhere
%%%        return
%%%    end
%%%end

if strcmp(annot_Team,'UBC')
       matDir = 'E:\Dropbox\APACHI_UBC\Data\AVA\'; % note: trailing '\' is required
end

addpath(genpath(matDir))
lock_filedir = [matDir 'lock\'];  %backup directory of locked transition matrices
CaseListFile = [matDir 'CaseList.mat'];  %this file contains spreadsheet of cases;
%automatically created in matDir, so should not be edited
folder_string = 'MU*.??';  %pattern for data folder names



config_function = @APACHI_default_wave_parameters;
measures_function = @APACHI_get_measures;
% these must be preceded by @;

end


%% CLIP
if CLIP % carried forward from Heemun, but inactive here as CLIP is set to 0 above
    
matDir = 'C:\Users\Heemun\Documents\Research\VF\clip\Data\CASS_matfiles_v1\'; 
%matDir = 'C:\Users\Heemun\Dropbox\clip\CASS_matfiles_v1\HK\';
  %director of data folders (one folder per case)
addpath(genpath(matDir))  
lock_filedir = [matDir 'lock\'];  %backup directory of locked transition matrices
CaseListFile = [matDir 'CaseList.mat'];  %this file contains spreadsheet of cases; 
%automatically created in matDir, so should not be edited
folder_string = '1_12*';  %pattern for data folder names

config_function = @clip_default_wave_parameters;  
%   %configuration file; must be preceded by @;
measures_function = @clip_get_measures;

end
end