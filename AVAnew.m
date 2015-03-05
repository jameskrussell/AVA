function status = AVA_new(varargin)
global annot_Team;
param = inputParser;

param.addParamValue('annot_Team','Clinical',@(x)isstr(x));

param.parse(varargin{:});

annot_Team = param.Results.annot_Team;




breakpoints = dbstatus;
dbclear ALL; % suppresses debugging to avoid opening Editor on errors
warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid');




%AVA_gui_v1_4;
AVA_gui_v1_5;

%dbstop(breakpoints); % restore breakpoints (including 'if error') if there were any

status = 1;
end