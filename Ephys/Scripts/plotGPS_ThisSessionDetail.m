pathOri = pwd;

%%
clearvars -except pathOri; close all; % for loop

% load r
r_file = dir('RTArray*.mat');
disp(r_file.name);
load(r_file.name, 'r');

% get unit information
clusterSpikes(r, 'PeakTrough', 0);
getUnitLocation(r);

% warp
SpikesGPS.SRT.PopulationSDFWarped(r);
clear r;
load(r_file.name, 'r');

% pca
SpikesGPS.SRT.showPCA(r);

% coding direction
r.CodingDir = SpikesGPS.SRT.showCodingDirection(r);
r_name = 'RTarray_'+r.BehaviorClass.Subject+'_'+r.BehaviorClass.Session+'.mat';
save(r_name, 'r');

% neural distance
SpikesGPS.SRT.showNeuralDistance(r);

% non-param test
SpikesGPS.SRT.testNonParam(r);


