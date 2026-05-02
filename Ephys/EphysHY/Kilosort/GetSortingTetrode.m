function GetSortingTetrode(nTetrode)
% This is to read sorting result from Kilosort. Some modification might
% have been done in Phy. 
% Based on Huang Yue's BuildSpikeTable
% Jianing Yu, 3/27/2023

if ~isempty(dir('kilosort3_output'))
    thisFolder = pwd;
    dir_output = fullfile('kilosort3_output', 'sorter_output');
    addpath(dir_output)
    
    mkdir(fullfile(thisFolder, dir_output, 'Wave'))
else
    error('Go to the main folder')
end;

if nargin==0
    nTetrode = 8;
end;

if nTetrode == 8
    TetrodesMap = [
        1 3 5 7               % tetrode 1
        2 4 6 8               % tetrode 2
        9 11 13 15          % tetrode 3
        10 12 14 16        % tetrode 4
        17 19 21 23 	% tetrode 5
        18 20 22 24 	% tetrode 6
        25 27 29 31 	% tetrode 7
        26 28 30 32 	% tetrode 8
        ];
end;

load ops.mat

% read and add spike times
spike_times = readNPY('spike_times.npy');               % time of each spike
spike_clusters = readNPY('spike_clusters.npy');        % cluster id of each spike, it starts from 0 and ends with n_cluster-1
spike_templates = readNPY('spike_templates.npy');

% spike_clusters      658325x1             2633300  uint32              
% spike_times         658325x1             5266600  uint64             
n_unit = length(unique(spike_clusters));
tetrode_wavforms = cell(1, n_unit);
nsample = 64; % samples per channel
tetrode_wavformavg = zeros(nsample, n_unit);
 [b, a]=butter(4, 250*2/30000, 'high'); % filter
% read spike waveforms
for k = 0:n_unit-1

    [filepath,name,ext]                   =         fileparts(ops.fproc);
    gwfparams.dataDir                  =          filepath;    % KiloSort/Phy output folder
    gwfparams.fileName                =         [name, ext];         % .dat file containing the raw 
    gwfparams.dataType                =          'int16';      % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh                        =          ops.Nchan;                      % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin                     =           [-31 32];              % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf                        =          length(spike_clusters == k);                  % Number of waveforms per unit to pull out
    gwfparams.spikeTimes             =          spike_times(spike_clusters == k);  % Vector of cluster spike times (in samples) same length as .spikeClusters
    gwfparams.spikeClusters         =           k*ones(1, sum(spike_clusters == k)); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
    wf                                              =           Kilosort.getWaveforms(gwfparams);
%    wf 
%    struct with fields:% 
%     unitIDs: 0
%    spikeTimeKeeps: [1002192 1002203 1002211 1002217 … ]
%     waveForms: [1×658325×32×64 double]
%     waveFormsMean: [1×32×64 double]
   wf_avg                                         =            squeeze(wf.waveFormsMean); %   wf_avg                   32x64                  16384  double
   for ich =1:size(wf_avg, 1)
       wf_avg(ich, :) = filtfilt(b, a, wf_avg(ich, :));
   end;
   % check max amplitudes
   wf_amplitudes                                =           max(wf_avg, [], 1) - min(wf_avg, [], 1);
   % max-amplitude channel 
   [~, ch_max_amp]                           =            max(wf_amplitudes);
   % identify tetrode ID
   [tetrode_id, ~ ]                                =           find(TetrodesMap == ch_max_amp);
   tetrode_wavforms{k+1}                   =          squeeze(wf.waveForms(1, :, TetrodesMap(tetrode_id, :), :));
   tetrode_wavformavg(:, k+1)           =           wf_avg(TetrodesMap(tetrode_id, :), :);
  []
end

spikeTable.waveforms = waveforms_tbl;
spikeTable.waveforms_mean = waveforms_mean_tbl;
spikeTable.ch = ch_tbl;
spikeTable = sortrows(spikeTable,{'ch','group'});


tbl_spike_times = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    tbl_spike_times{k} = spike_times(spike_clusters==spikeTable(k,:).cluster_id);
end
spikeTable.spike_times = tbl_spike_times;

%% extract waveform from temp_wh.dat
waveforms_tbl = cell(height(spikeTable),1);
waveforms_mean_tbl = cell(height(spikeTable),1);
ch_tbl = cell(height(spikeTable),1);
for k = 1:height(spikeTable)
    tic
    [filepath,name,ext] = fileparts(ops.fproc);
    gwfparams.dataDir = filepath;    % KiloSort/Phy output folder
    gwfparams.fileName = [name, ext];         % .dat file containing the raw 
    gwfparams.dataType = 'int16';            % Data type of .dat file (this should be BP filtered)
    gwfparams.nCh = ops.Nchan;                      % Number of channels that were streamed to disk in .dat file
    gwfparams.wfWin = [-31 32];              % Number of samples before and after spiketime to include in waveform
    gwfparams.nWf = length(spikeTable(k,:).spike_times{1});                    % Number of waveforms per unit to pull out
    gwfparams.spikeTimes =    spikeTable(k,:).spike_times{1}; % Vector of cluster spike times (in samples) same length as .spikeClusters
    gwfparams.spikeClusters = ones(length(spikeTable(k,:).spike_times{1}),1); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes

    wf = getWaveforms(gwfparams);
    
    amp_ch = max(squeeze(wf.waveFormsMean),[],2)-min(squeeze(wf.waveFormsMean),[],2);
    [~, ch_amp_largest] = max(amp_ch);
    ch_tbl{k} = ch_amp_largest;
    
    waveforms_tbl{k} = squeeze(wf.waveForms(:,:,ch_amp_largest,:));
    waveforms_mean_tbl{k} = squeeze(wf.waveFormsMean);
    
    toc
end

spikeTable.waveforms = waveforms_tbl;
spikeTable.waveforms_mean = waveforms_mean_tbl;
spikeTable.ch = ch_tbl;
spikeTable = sortrows(spikeTable,{'ch','group'});
%% Get real spike time
% Read NS6 file.
ns6_files = dir('*.ns6');
if ~isempty(ns6_files)
    for i =1:length(ns6_files)
        if i == 1
            openNSx(ns6_files(i).name, 'read', 'report')
            NS6all= NS6;
        else
            openNSx(ns6_files(i).name, 'read', 'report')
            NS6all(i)= NS6;
        end
    end
else
    error('No .ns6 files!')
end

% Define channels
EphysChs = 1:ops.Nchan;
Fs = ops.fs; % this is the sampling rate

% Extract ephys data

index =[];
for k = 1:length(NS6all)
    NS6 = NS6all(k);
    if k>1
        dt_i =NS6all(k).MetaTags.DateTimeRaw-NS6all(1).MetaTags.DateTimeRaw; % start time of this session relative to the first session
        dBlockOnset=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % convert time to ms
    else
        dBlockOnset=0; % define the starting time of the first session as 0
    end
    if iscell(NS6.Data)
        for j =1:length(NS6.Data)
            % this is time in ms
            index_k = (0:length(double(NS6.Data{j}(1, :)))-1)*1000/Fs+NS6.MetaTags.Timestamp(j)*1000/Fs+dBlockOnset;
            % skip first 102 frame (zeropad by blackrock?)
            index_k(1:102) = [];
            if k==1
                index = [index index_k];
            else
                % this is to take care of an old issue
                index_k = index_k(index_k> index(end)+0.03);
                index = [index index_k];
            end
        end
    else
        index_k = (0:length(double(NS6.Data(1, :)))-1)*1000/Fs+NS6.MetaTags.Timestamp*1000/Fs+dBlockOnset;
        % skip first 102 frame (zeropad by blackrock?)
        index_k(1:102) = [];        
        index = [index index_k];
    end
end

savefile = 'index.mat'; % name of raw data files
save(savefile, 'index');
%%
% first 102 frame in Kilosort is skipped (Blackrock zeropad the data)
% kilosort add 0 at the end of data

spike_times_r = cell(height(spikeTable),1);

for k = 1:height(spikeTable)
    spike_times_r{k} = index(spikeTable(k,:).spike_times{1});
end

spikeTable.spike_times_r = spike_times_r;
disp(spikeTable)


%%
chanMap = load('chanMap.mat');
KilosortOutput = KilosortOutputClass(spikeTable, chanMap, ops);
KilosortOutput.save();

%% Uncommenented correspoding segment to build R

% % For 2FPs (750/1500): 
% KilosortOutput.buildR(...
%     'KornblumStyle', false,...
%     'Subject', 'West',...
%     'blocks', {'datafile001.nev','datafile002.nev'},...
%     'Version', 'Version4',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'HY');

% % For 2FPs (500/1000): 
% KilosortOutput.buildR(...
%     'KornblumStyle', false,...
%     'Subject', 'West',...
%     'blocks', {'datafile001.nev','datafile002.nev'},...
%     'Version', 'Version5',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'HY');

% % For Kormblum: 
% KilosortOutput.buildR(...
%     'KornblumStyle', true,...
%     'Subject', 'West',...
%     'blocks', {'datafile001.nev','datafile002.nev'},...
%     'Version', 'Version5',...
%     'BpodProtocol', 'OptoRecording',...
%     'Experimenter', 'HY');
%% Uncommenented correspoding segment to plot PSTHs
clear
load RTarrayAll.mat

% % For 2FPs (500/1000):
% for k = 1:length(r.Units.SpikeTimes)
%     SRTSpikesV5_unsorted(r,k,'FP_long',1000,'FP_short',500);
%     SRTSpikesV5(r,k,'FP_long',1000,'FP_short',500);
% end

% % For 2FPs (750/1500):
% for k = 1:length(r.Units.SpikeTimes)
%     SRTSpikesV5_unsorted(r,k);
%     SRTSpikesV5(r,k);
% end

% % For Kormblum: 
% for k = 1:length(r.Units.SpikeTimes)
%     KornblumSpikesUnsorted(r,k);
%     KornblumSpikes(r,k);
% end
