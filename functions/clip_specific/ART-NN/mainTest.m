%**************************************************************************
%Title:             Test main script that calls shock noshock
%Created:           2/21/2013
%Last Modified:     2/28/2013
%Author:            Jason Coult
%
%Shows how to call shock/noshock
%
%shockNoShock Function:
%Pass in the ECG, and how specific you want it to be (1 = most sensitive
%and 4 = most specific). 

%The shock decision is returned, as well as the shock probability meeasure
%if you want to make your own ROC curve 
%**************************************************************************


clear all; close all; clc;

orgEcg = dlmread('orgTest.txt');
vfEcg = dlmread('vfTest.txt');

[shockDec1 shockProb1] = shockNoShock(orgEcg,2) %call shock noshock version with higher sensitivity
[shockDec2 shockProb2] = shockNoShock(vfEcg,4) %call shock noshock version with higher specificity
