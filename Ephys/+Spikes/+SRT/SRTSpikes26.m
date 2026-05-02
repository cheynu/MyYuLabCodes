function PSTH = SRTSpikes26(r, ind, varargin)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port.
% V5: add poke events following an unsuccesful release

% SRTSpikes(r, 13, 'FRrange', [0 35])

% ind can be singular or a vector

% 8.9.2020
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

% 5/7/2023 revised to adopt new FP schedule (e.g., 500 1000 1500)

% 08/21/2025 consider probe trials

% 12.18.2025 adapted for reward probability experiments



set_matlab_default;
takeall = 0;

if nargin<2
    ind = [];
end

if isempty(ind)
    ind =  (1:length(r.Units.SpikeTimes));
    takeall =1;
else
    if ischar(ind)
        % ind = 'Nasha_20250418_Ch227_Unit1'
        % Use regexp to find all sequences of digits
        numbers = regexp(ind, '\d+', 'match');

        % Extract the third and fourth numbers (corresponding to 227 and 1)
        ch_number = numbers{2};  % '227'
        unit_number = numbers{3}; % '1'

        ch = str2double(ch_number);
        unit = str2double(unit_number);
        ind = find(r.Units.SpikeNotes(:, 1)==ch & r.Units.SpikeNotes(:, 2)==unit);
    else
        if length(ind) ==2
            ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
            ind = ind_unit;
    end
    end
end
ku_all = ind; % ind is used in different places

tic
ComputeRange = [];  % this is the range where time is extracted. Event times outside of this range will be discarded. Empty means taking everything

PressTimeDomain = [2500 2500]; % default
ReleaseTimeDomain = [1000 2000];
RewardTimeDomain = [2000 2000];
TriggerTimeDomain = [250 1000];
reward_col = [237, 43, 42]/255;
ToSave = 'on';
r_name=[];
by_time = 0; % order the raster by time in a session

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            %             case 'FRrange'
            %                 FRrange = varargin{i+1};
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ReleaseTimeDomain'
                ReleaseTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ComputeRange'
                ComputeRange = varargin{i+1}*1000; % convert to ms
            case 'ToSave'
                ToSave = varargin{i+1};
            case 'r_name'
                r_name = varargin{i+1};
            case 'by_time'
                by_time = varargin{i+1};               
            otherwise
                errordlg('unknown argument')
        end
    end
end

rb                            =       r.Behavior;
% all FPs
if isfield(r, 'BehaviorClass')
    if length(r.BehaviorClass)>1
        r.BehaviorClass = r.BehaviorClass{1};
    end
    MixedFPs                =       r.BehaviorClass.MixedFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
    Subject = r.BehaviorClass.Subject;
    SessionInfo = r.BehaviorClass.Date;
else
    MixedFPs = Spikes.findFP(r);
    Subject = r.Meta(1).Subject;
    SessionInfo = strrep( r.Meta(1).DateTime(1:11), '-', '_');
end

nFPs                        =       length(MixedFPs);

%% Check if opto is applied
if isfield(r, 'Analog') && isfield(r.Analog, 'Opto')
    t_opto = r.Analog.Opto(:, 1);
    opto     = r.Analog.Opto(:, 2);
    opto_threshold = max(opto)*0.5;
    t_separation = 1*1000;
    % begs of opto stim
    opto_above = find(opto > opto_threshold);
    ind_seps = find(diff(opto_above)>t_separation);
    opto_begs = [opto_above(1); opto_above(ind_seps+1)];
    opto_ends = [opto_above(ind_seps); opto_above(end)];
    
    t_opto_begs = t_opto(opto_begs);
    t_opto_ends = t_opto(opto_ends);
else
    t_opto_begs = [];
    t_opto_ends = [];
end
%% Extract event times
if ~isfield(r, 'EventTable')
    [event_table] = Spikes.SRT.rEventTableRewardProb(r);
else
    event_table = r.EventTable;
end
 %       anm_session        press_index    MED_index       type        t_press      t_trigger     t_release       t_poke       FP       rt        outcome  
 %    __________________    ___________    _________    __________    __________    __________    __________    __________    ____    ______    ___________
 % 
 %    {'Nasha_20250415'}          1             3       {'WarmUp'}        183.24           NaN        703.48           NaN    1000       NaN    {'Dark'   }
 %    {'Nasha_20250415'}          2             4       {'WarmUp'}        1983.3           NaN        6643.4           NaN    1000       NaN    {'Dark'   }
 %    {'Nasha_20250415'}          3             5       {'WarmUp'}        7843.1           NaN         10413           NaN    1000       NaN    {'Dark'   }
 %    {'Nasha_20250415'}          4             6       {'WarmUp'}         11223           NaN         11543           NaN    1000       NaN    {'Dark'   }
 %    {'Nasha_20250415'}          5             7       {'WarmUp'}         20053         21053         21573         22529    1000    520.14    {'Correct'}

 %% Check ComputeRange 
 if ~isempty(ComputeRange)
     ind_beg = find(event_table.t_press>=ComputeRange(1), 1, 'first');
     ind_end = find(event_table.t_release<=ComputeRange(1), 1, 'last');
     event_table((ind_beg:ind_end), :) = [];
 end

 %% Check opto, use a large range, 5000 ms, to cover events that are affected by lasers
 if ~isempty(t_opto_begs)
     for i = 1:length(t_opto_begs)
         ind_beg = find(event_table.t_press>=t_opto_begs(i)-5000, 1, 'first');
         ind_end = find(event_table.t_release<=t_opto_ends(i)+5000, 1, 'last');
         event_table((ind_beg:ind_end), :) = [];
     end
 end
 r.EventTable = event_table;
 %% For neuropixels recordings, get the unit location info
 if isfield(r, 'ChanMap')
     ChanMap = r.ChanMap;
     n_unit = length(r.Units.SpikeTimes);
     common_chan_locs = [ChanMap.xcoords(ChanMap.connected) ChanMap.ycoords(ChanMap.connected)];
     shanks = ChanMap.kcoords(ChanMap.connected);
     amplitudes_all = zeros(size(common_chan_locs, 1), n_unit);
     n_nearest = 15;
     % nearest = knnsearch(common_chan_locs, common_chan_locs, 'K', n_nearest); % this is index
     unit_table = table();
     wave_out = struct;
     for i =1:n_unit
         i_session           =   r.BehaviorClass.Date;
         ich                 =   r.Units.SpikeNotes(i, 1);
         iunit               =   r.Units.SpikeNotes(i, 2);
         itype               =   r.Units.SpikeNotes(i, 3);
         ind_unit_i          =   i;
         % this is the waveform
         i_waveform          =   r.Units.SpikeTimes(ind_unit_i).wave_mean;
         i_shank             =   ChanMap.kcoords;
         i_x                 =   ChanMap.xcoords;
         i_y                 =   ChanMap.ycoords;
         i_map               =   ChanMap;
         wave1 = struct();
         wave1.unit_id               =   [r.BehaviorClass.Subject '_' i_session '_Ch' num2str(ich) '_Unit' num2str(iunit)];
         wave1.wave_matrix           =   i_waveform;
         wave1.shank                 =   i_shank;
         wave1.chan_locs             =   [i_x i_y];
         wave1.chan_map              =   i_map;
         wave1.type = itype;
         waveform_1 = i_waveform;
         amplitudes = max(waveform_1, [], 2) - min(waveform_1, [], 2);
         amplitudes_all(:, i) = amplitudes;
         % Find the max channel
         ind_max = find(amplitudes == max(amplitudes));
         wave1.max_amp = amplitudes(ind_max);
         wave1.max_loc = common_chan_locs(ind_max, :);
         max_shank = shanks(ind_max);
         % channels of this shank
         common_chan_locs_shank = common_chan_locs(shanks == max_shank, :);
         amplitudes_shank = amplitudes(shanks == max_shank);
         ind_max = find(amplitudes_shank == max(amplitudes_shank));
         nearest = knnsearch(common_chan_locs_shank, common_chan_locs_shank, 'K', n_nearest); % this is index
         % Find the nearest channels
         ind_nearest_unit1 = nearest(ind_max, :); % index
         % waves of this shank
         waves_shank = waveform_1(shanks == max_shank, :);
         wave1.nearest_locs =common_chan_locs_shank(ind_nearest_unit1, :);
         wave1.nearest_waves = waves_shank(ind_nearest_unit1, :);
         wave1.max_amp_surrounding = max(abs(wave1.nearest_waves), [], 2);

         this_row = table({wave1.unit_id}, ind_max, wave1.max_loc(1), ...
             wave1.max_loc(2), wave1.max_amp, {ind_nearest_unit1'}, max_shank, {wave1.nearest_locs(:,1)}, ...
             {wave1.nearest_locs(:,2)}, {wave1.max_amp_surrounding}, wave1.type, ...
             'VariableNames',{'unit', 'ind', 'x', 'y', 'amp', 'nearby_ind', 'shank', ...
             'nearby_x', 'nearby_y', 'nearby_amp', ...
             'type'});

         unit_table =[unit_table; this_row];
     end
     r.PixelTable = unit_table;
 end
%% Check how many units we need to compute
% derive PSTH from these
% go through each units if necessary
for iku =1:length(ku_all)
    ku = ku_all(iku);
    if ku>length(r.Units.SpikeTimes)
        disp('##########################################')
        disp('########### That is all you have ##############')
        disp('##########################################')
        return
    end
    disp('##########################################')
    disp(['Computing this unit: ' num2str(ku)])
    disp('##########################################')

    if ku == 1
        PSTH      = Spikes.SRT.ComputePlotPSTH26(r, ku,...
            'PressTimeDomain', PressTimeDomain, ...
            'ReleaseTimeDomain', ReleaseTimeDomain, ...
            'RewardTimeDomain', RewardTimeDomain,...
            'TriggerTimeDomain', TriggerTimeDomain,...
            'by_time', by_time, ...
            'ToSave', ToSave);
    else
        PSTH(ku)      = Spikes.SRT.ComputePlotPSTH26(r, ku,...
            'PressTimeDomain', PressTimeDomain, ...
            'ReleaseTimeDomain', ReleaseTimeDomain, ...
            'RewardTimeDomain', RewardTimeDomain,...
            'TriggerTimeDomain', TriggerTimeDomain,...
            'by_time', by_time, ...
            'ToSave', ToSave);
    end

end

end

