function [shockDec, shockProb] = prob_ART_nn(inputEcg)
%**************************************************************************
%Title:             prob_ART_nn
%Summary:           Machine Learning-based Shock/Noshock for With-CPR ECG
%                   Slightly modified from shockNoShock
%Created:           4/3/2014
%Last modified:     4/3/2014
%Author:            Jason Coult, Larry Sherman
%
%INPUTS: 
%          (data) ECG Signal (3.8 seconds at 250Hz = 950 pts) in mV
%          Should be either VF, Organized, or Asystole with CPR
%
%           (vers) Version is between 1-4 and indicates how specific it is
%
%
%OUTPUTS: 
%          (shockDec) 1 if shockable, 0 if non-shockable
%          (shockProb) value between 0 and 1 indicating liklihood of VF
%
%3/1/13: Each version uses the same algorithm with a different probability
%threshold (.2, .4, .6, or .8)
%**************************************************************************

%decision thresholds for probailities, for each of the versions
decisionThresh = 0.6;


shockDec = 0; %default no shock

%check input
if length(inputEcg) ~= 950 
    error('Input must be 950 points (3.8seconds at 250Hz)')
end

%calculate parameters
[clas, invClas, flats, qpks, pkaAmp, stdAmp, P2PAmp]  = calcParams(inputEcg); 

%send parameters to machine learning decision rule and get prediction
p = predict([clas invClas flats qpks pkaAmp stdAmp P2PAmp]); 

if p > decisionThresh    %if VF probability is over threshold
    shockDec = 1; %call it shockable and return
end

shockProb = p; %return probability also





end
