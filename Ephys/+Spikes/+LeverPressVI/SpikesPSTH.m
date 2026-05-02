function PSTHOut = SpikesPSTH(r, ind, opts)
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

% 12/4/2025 revised to adopt leverpressVI task

arguments
    r
    ind = []
    opts.PressTimeDomain = [2500 2500];
    opts.ReleaseTimeDomain = [1000 2000];
    opts.RewardTimeDomain = [2000 2000];
    opts.TriggerTimeDomain = [1000 2000];
    opts.ComputeRange = [];
    opts.ToSave = 'on';
    opts.by_rank = 0;
end

PressTimeDomain = opts.PressTimeDomain;
ReleaseTimeDomain = opts.ReleaseTimeDomain;
RewardTimeDomain = opts.RewardTimeDomain;
TriggerTimeDomain = opts.TriggerTimeDomain;

ComputeRange = opts.ComputeRange.*1000; % convert to ms
ToSave = opts.ToSave;
by_rank = opts.by_rank;

if isempty(ind)
    ind = (1:length(r.Units.SpikeTimes));
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

%% Extract event times
if ~isfield(r, 'EventTable')
    [event_table] = Spikes.LeverPressVI.rEventTable(r);
else
    event_table = r.EventTable;
end
%        anm_session           press_index    BPOD_index    press_rank    time_from_last_reward     t_press      t_release     outcome     is_stay    t_poke_first     t_valve      t_port_exit       reward       valve_time
% _________________________    ___________    __________    __________    _____________________    __________    __________    ________    _______    ____________    __________    ___________    ____________    __________
% 
% {'Maddy_20251123_162632'}          1             1             1                  NaN                 21757         21997    {'Good'}     false           23248          23248         34802     {'Rewarded'}       180    
% {'Maddy_20251123_162632'}          2             2             1                16358                 39607         39877    {'Bad' }     true              NaN            NaN           NaN     {'NaN'     }       NaN    
% {'Maddy_20251123_162632'}          3             3             2                21328                 44577         44807    {'Bad' }     true              NaN            NaN           NaN     {'NaN'     }       NaN    
% {'Maddy_20251123_162632'}          4             4             3                22378                 45627         45917    {'Bad' }     true              NaN            NaN           NaN     {'NaN'     }       NaN    
% {'Maddy_20251123_162632'}          5             5             4                24428                 47676         48137    {'Bad' }     true              NaN            NaN           NaN     {'NaN'     }       NaN    
%% Check ComputeRange 
if ~isempty(ComputeRange)
    ind_beg = find(event_table.t_press>=ComputeRange(1), 1, 'first');
    ind_end = find(event_table.t_release<=ComputeRange(1), 1, 'last');
    event_table((ind_beg:ind_end), :) = [];
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
        PSTH = Spikes.LeverPressVI.ComputePlotPSTH(r, ku,...
            'PressTimeDomain', PressTimeDomain, ...
            'ReleaseTimeDomain', ReleaseTimeDomain, ...
            'RewardTimeDomain', RewardTimeDomain,...
            'TriggerTimeDomain', TriggerTimeDomain,...
            'by_rank', by_rank, ...
            'ToSave', ToSave);
    else
        PSTH(ku) = Spikes.LeverPressVI.ComputePlotPSTH(r, ku,...
            'PressTimeDomain', PressTimeDomain, ...
            'ReleaseTimeDomain', ReleaseTimeDomain, ...
            'RewardTimeDomain', RewardTimeDomain,...
            'TriggerTimeDomain', TriggerTimeDomain,...
            'by_rank', by_rank, ...
            'ToSave', ToSave);
    end
end

PSTHOut = PSTH;

end