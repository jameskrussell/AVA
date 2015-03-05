function status = AVA(varargin)
global annot_Team;
param = inputParser;

param.addParamValue('annot_Team','sandbox',@(x)isstr(x));

param.parse(varargin{:});

annot_Team = param.Results.annot_Team;

if strcmp(computer,'MACI64')
%    dbclear all; % syntax different on Mac - go figure
else
    dbclear ALL; % suppresses debugging to avoid opening Editor on errors
end
warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid');




%AVA_gui_v1_4;
AVA_gui_v1_5;

%dbstop(breakpoints); % restore breakpoints (including 'if error') if there were any

status = 1;
end