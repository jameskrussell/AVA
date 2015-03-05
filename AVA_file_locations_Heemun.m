function [matDir, lock_filedir, CaseListFile, folder_string, config_function, measures_function] = AVA_file_locations()
% project
APACHI = 0;
CLIP = 1;

%% APACHE
if APACHI
%matDir = 'C:\Users\heemun\Documents\Research\pleth\data\jim_031314\';  
matDir = 'C:\Users\Heemun\Dropbox\APACHI\Data\AVA-Technical\';
%matDir = 'C:\Users\Heemun\Dropbox\APACHI\Data\AVA\';

  %director of data folders (one folder per case)
addpath(genpath(matDir))  
lock_filedir = [matDir 'lock\'];  %backup directory of locked transition matrices
CaseListFile = [matDir 'CaseList.mat'];  %this file contains spreadsheet of cases; 
%automatically created in matDir, so should not be edited
folder_string = 'MU*.??';  %pattern for data folder names

config_function = @APACHI_default_wave_parameters;  
%config_file = @APACHI_default_wave_parameters_jim;  
%   %configuration file; must be preceded by @;
measures_function = @APACHI_get_measures;

end


%% CLIP
if CLIP
    
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