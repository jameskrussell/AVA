function [nWave, Version] = zNormalize(Wavestruct,varargin)
% [nWave Version] = zNormalize(Wavestruct,varargin)
% normalizes Wavestruct.waveform with zscore
% Trims after normalization values outside +/- zTrimLimit in standard
% deviations.  Trimming consists of replacing with NaN
% Optionally plots normalized results.
% nWave is normalized waveform (not entire struct)
% Jim Russell, Philips, 2/26/2014

Version = '1.0';

param = inputParser;
param.addParamValue('verbose',false,@(x)islogical(x));
param.addParamValue('visualize',false,@(x)islogical(x));
param.addParamValue('zTrim',true,@(x)islogical(x));
param.addParamValue('zTrimLimit',3,@(x)isnumeric(x)); % 3 stdevs
param.parse(varargin{:});

verbose = param.Results.verbose;
visualize = param.Results.visualize;

zTrim = param.Results.zTrim;

if visualize
    if exist(Wavestruct.T)
        eval(['T=' Wavestruct.T ';']);
        eval(['clear ' Wavestruct.T]);
    else
        if exist([Wavestruct.T '.mat']) == 2
            load(Wavestruct.T);
            eval(['T=' Wavestruct.T ';']);
            eval(['clear ' Wavestruct.T]);
        else
            if verbose
                disp([Wavestruct.T ' missing, making T from waveform length, sps'])
            end
            T = (1:length(Wavestruct.waveform))/Wavestruct.sps;
        end
    end
end
    
    if isfield(Wavestruct,'Valid')
        BlankIdxs = find(Wavestruct.Valid ~=1);
        vWave = Wavestruct.waveform;
        vWave(BlankIdxs) = NaN;
        iWave = naninterp(vWave);
        nWave = zscore(iWave);
        nWave(BlankIdxs) = NaN;
        if zTrim
            TrimBlanks = find(abs(nWave) > zTrim);
            nWave(TrimBlanks) = NaN;
        end
        if visualize
            plot(T,nWave);
        end
    end
    
    
    
%% Detailed documentation    
% nWave = zNormalize(Wavestruct,varargin)
% 
% Restores NaNs in source Wavestruct.waveform after normalizing (so they won't plot,
% and thus won't ruin the vertical scale), and optionally supplements them with more NaNs 
% for normalized values outside a limited range, by default 3 standard deviations.  
% The default is to do the post-normalization trimming.
% 
% You can turn post-normalization trimming off with 
%  nWave = zNormalize(Wavestruct,'zTrim',false);
% 
% You can set the trim level in standard deviations at your pleasure with: 
% nWave = zNormalize(Wavestruct, 'zTrimLevel',desired_value);
% 
% You can have the function make the plot itself with: 
% nWave = zNormalize(Wavestruct,'visualize',true (and any other options - e.g. nWave = zNormalize(Wavestruct,'visualize,true,'zTrimLevel',1);
% 
% The defaults are set in the section: 
% param.addParamValue('visualize',false,@(x)islogical(x));
% param.addParamValue('zTrim',true,@(x)islogical(x));
% param.addParamValue('zTrimLimit',3,@(x)isnumeric(x)); % 3 stdevs