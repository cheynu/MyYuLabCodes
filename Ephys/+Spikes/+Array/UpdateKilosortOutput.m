function UpdateKilosortOutput(obj)

% Jianing Yu 8/22/2023
% Sometimes I split cluster in matlab (SpikeChecker). This won't update the
% average waveforms from all channels automatically (because the avg
% waveform is computed from kilosort and it takes a long time)

% actually, it is helpful to re-compute waveforms for all clusters since
% the waveforms have been curated substantially through SpikeChecker. 

% we perform this computation here.

% This is the spike table that we need to update
SpikeTable = obj.SpikeTable;
% First, we ask for the location of the original kilosort data
dir_name = uigetdir(pwd, 'select the spike sorting folder ');
addpath(dir_name)
load ops.mat

%% extract waveform from temp_wh.dat
% This is the main step
n_cluster = height(SpikeTable);
waveforms_tbl = cell(n_cluster,1);
waveforms_mean_tbl = cell(n_cluster,1);
ch_tbl = cell(n_cluster,1);

for k = 1:n_cluster
    tic
    [filepath,name,ext] = fileparts(ops.fproc);
    % added by JY
    filepath = dir_name; % in case you move data around. the old filepathy won't apply.
    gwfparams.dataDir = filepath;    % KiloSort/Phy output folder
    gwfparams.fileName = [name, ext];         % .dat file containing the raw
    gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh = ops.Nchan;                      % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = length(SpikeTable(k,:).spike_times{1});                    % Number of waveforms per unit to pull out
    gwfparams.spikeTimes =    SpikeTable(k,:).spike_times{1}; % Vector of cluster spike times (in samples) same length as .spikeClusters
    gwfparams.spikeClusters = ones(length(SpikeTable(k,:).spike_times{1}),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
    wf = getWaveforms(gwfparams);
    amp_ch = max(squeeze(wf.waveFormsMean),[],2)-min(squeeze(wf.waveFormsMean),[],2);
    [~, ch_amp_largest] = max(amp_ch);
    ch_tbl{k} = ch_amp_largest;
    waveforms_tbl{k} = squeeze(wf.waveForms(:,:,ch_amp_largest,:));
    waveforms_mean_tbl{k} = squeeze(wf.waveFormsMean);
    toc
end

SpikeTable.waveforms = waveforms_tbl;
SpikeTable.waveforms_mean = waveforms_mean_tbl;
SpikeTable.ch = ch_tbl;
SpikeTable = sortrows(SpikeTable,{'ch','group'});

% save spikeTable
writetable(SpikeTable, 'KilosortSpikeTable.csv')
% save to KilosortOutput

chanMap = load('chanMap.mat');
KilosortOutput = Spikes.Array.KilosortOutputClass(SpikeTable, chanMap, ops);
KilosortOutput.save();