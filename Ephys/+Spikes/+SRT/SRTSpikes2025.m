function PSTHOut = SRTSpikes2025(r, ind, varargin)
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
TriggerTimeDomain = [1000 2000];
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
[event_table, t_poke_all] = Spikes.SRT.rEventTable(r);

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
 
%% Presses
t_correct_presses            =       cell(1, nFPs);
t_correct_releases           =        cell(1, nFPs);
rt_correct_presses           =       cell(1, nFPs);

t_correct_presses_sorted      =       cell(1, nFPs);
t_correct_releases_sorted     =        cell(1, nFPs);
rt_correct_presses_sorted     =       cell(1, nFPs);

for i =1:nFPs
    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, 'Correct') & event_table.FP == MixedFPs(i);
    t_correct_presses{i}    =   event_table.t_press(index);
    rt_correct_presses{i}   =    event_table.rt(index);
    t_correct_releases{i}    =    event_table.t_release(index);
    [rt_correct_presses_sorted{i}, indsort]  =          sort(rt_correct_presses{i});
    t_correct_presses_sorted{i}                 =          t_correct_presses{i}(indsort);
    t_correct_releases_sorted{i}                =          t_correct_releases{i}(indsort);
end

% These are the probe trials
index = strcmp(event_table.type, 'Probe');
t_probe_presses            =       event_table.t_press(index);
t_probe_releases           =       event_table.t_release(index);
hd_probe = t_probe_releases-t_probe_presses;
[hd_probe_sorted, ind_sort] = sort(hd_probe);
t_probe_presses_sorted = t_probe_presses(ind_sort);
t_probe_releases_sorted = t_probe_releases(ind_sort);
 
%% Premature responses
t_premature_presses                     =       cell(1, nFPs);
t_premature_releases                    =        cell(1, nFPs);
t_premature_presses_sorted              =       cell(1, nFPs);
t_premature_releases_sorted             =        cell(1, nFPs);

hd_premature              =       cell(1, nFPs);
hd_premature_sorted             =        cell(1, nFPs);

FP_premature                            =        cell(1, nFPs);
FP_premature_sorted                     =        cell(1, nFPs);

% sort using hold time
indsort_premature = cell(1, nFPs);

for i =1:nFPs
    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, 'Premature') & event_table.FP == MixedFPs(i);
    t_premature_presses{i}    =   event_table.t_press(index);
    t_premature_releases{i}    =    event_table.t_release(index);
    FP_premature{i} = event_table.FP(index);
    hd_premature{i} = t_premature_releases{i}-t_premature_presses{i};
    [hd_premature_sorted{i}, indsort_premature{i}]         =          sort(hd_premature{i});
    t_premature_presses_sorted{i}     =          t_premature_presses{i}(indsort_premature{i});
    t_premature_releases_sorted{i}    =          t_premature_releases{i}(indsort_premature{i});
    FP_premature_sorted{i}            =          FP_premature{i}(indsort_premature{i});
end

%% Late response
t_late_presses            =       cell(1, nFPs);
t_late_releases           =        cell(1, nFPs);
t_late_presses_sorted            =       cell(1, nFPs);
t_late_releases_sorted           =        cell(1, nFPs);
hd_late = cell(1, nFPs);
hd_late_sorted = cell(1, nFPs);
FP_late                           =        cell(1, nFPs);
FP_late_sorted                     =        cell(1, nFPs);

for i =1:nFPs
    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, 'Late') & event_table.FP == MixedFPs(i);
    t_late_presses{i}    =     event_table.t_press(index);
    t_late_releases{i}    =    event_table.t_release(index);
    hd_late{i} = event_table.t_release(index)-event_table.t_press(index);
    FP_late{i} = event_table.FP(index);
    [hd_late_sorted{i}, indsort_late]         =          sort(hd_late{i});
    t_late_presses_sorted{i}     =          t_late_presses{i}(indsort_late);
    t_late_releases_sorted{i}    =          t_late_releases{i}(indsort_late);
    FP_late_sorted{i}            =          FP_late{i}(indsort_late);
end


%%  Rewards
t_poke                  =       cell(1, nFPs);
retrieval_duration      =       cell(1, nFPs);
t_poke_sorted            =       cell(1, nFPs);
retrieval_duration_sorted =       cell(1, nFPs);
for i =1:nFPs
    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, 'Correct') & event_table.FP == MixedFPs(i);
    t_poke{i}    =     event_table.t_poke(index);
    retrieval_duration{i} = event_table.t_poke(index)-event_table.t_release(index);
end

% sort using retrieval duration
indsort_poke = cell(1, nFPs);
for i =1:nFPs
    [retrieval_duration_sorted{i}, indsort_poke{i}]         =          sort(retrieval_duration{i});
    t_poke_sorted{i}             =          t_poke{i}(indsort_poke{i});
end

%% Trigger
t_triggers = cell(1, nFPs);
RT_triggers = cell(1, nFPs);
t_triggers_late = cell(1, nFPs);
RT_triggers_late = cell(1, nFPs);

for i =1:nFPs
    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, {'Correct'}) & event_table.FP == MixedFPs(i);
    % short trigger (to plot)
    t_triggers{i}       =        event_table.t_trigger(index);
    RT_triggers{i}      =        event_table.rt(index);

    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, {'Late'}) & event_table.FP == MixedFPs(i);
    % short trigger (to plot)
    t_triggers_late{i}       =        event_table.t_trigger(index);
    RT_triggers_late{i}      =        event_table.rt(index);
end

%%  Store data in a structure
PSTHOut.ANM_Session                                 =     {Subject, SessionInfo};
PSTHOut.Presses.Labels                              =     [repmat({'Correct'}, 1, length(t_correct_presses_sorted)),...
    repmat({'Premature'}, 1, 1),...
    repmat({'Late'}, 1, 1), 'All'];

PSTHOut.EventTable = event_table;

PSTHOut.Presses.FP                                  =     [num2cell(MixedFPs), {cell2mat(FP_premature_sorted')}, {cell2mat(FP_late_sorted')}];
PSTHOut.Presses.Time                                =     [t_correct_presses_sorted {cell2mat(t_premature_presses_sorted')} {cell2mat(t_late_presses_sorted')} event_table.t_press];
PSTHOut.Presses.RT_Correct                          =     rt_correct_presses_sorted;
PSTHOut.Presses.PressDur.Premature                  =     cell2mat(hd_premature_sorted');
PSTHOut.Presses.PressDur.Late                       =     cell2mat(hd_late_sorted');
PSTHOut.Presses.Probe.Time                          =     t_probe_presses_sorted;
PSTHOut.Presses.Probe.Duration                      =     hd_probe_sorted;

% design a new structure to store these variables (2025) 
PSTHOut.Presses.TimeStruct.All  = event_table.t_press;
PSTHOut.Presses.TimeStruct.Correct_Sorted  = t_correct_presses_sorted;
PSTHOut.Presses.TimeStruct.RT_Correct_Sorted  = rt_correct_presses_sorted;
PSTHOut.Presses.TimeStruct.Correct_Unsorted  = t_correct_presses;
PSTHOut.Presses.TimeStruct.RT_Correct_Unsorted  = rt_correct_presses;
PSTHOut.Presses.TimeStruct.Premature_Sorted  = t_premature_presses_sorted;
PSTHOut.Presses.TimeStruct.Premature_Unsorted  = t_premature_presses;
PSTHOut.Presses.TimeStruct.HoldDuration_Premature_Sorted  = hd_premature_sorted;
PSTHOut.Presses.TimeStruct.HoldDuration_Premature_Unsorted  = hd_premature;
PSTHOut.Presses.TimeStruct.Late_Sorted  = t_late_presses_sorted;
PSTHOut.Presses.TimeStruct.Late_Unsorted  = t_late_presses;
PSTHOut.Presses.TimeStruct.HoldDuration_Late_Sorted  = hd_late_sorted;
PSTHOut.Presses.TimeStruct.HoldDuration_Late_Unsorted  = hd_late;
PSTHOut.Presses.TimeStruct.Probe  = t_probe_presses_sorted;
PSTHOut.Presses.TimeStruct.ProbeDuration  = hd_probe_sorted;

PSTHOut.Releases.Labels                             =      [repmat({'Correct'}, 1, length(t_correct_releases_sorted)), 'Premature', 'Late'];
PSTHOut.Releases.FP                                  =     PSTHOut.Presses.FP;
PSTHOut.Releases.Time                                =     [t_correct_releases_sorted {cell2mat(t_premature_releases_sorted')} {cell2mat(t_late_releases_sorted')} event_table.t_release];
PSTHOut.Releases.RT_Correct                          =     rt_correct_presses_sorted;
PSTHOut.Releases.PressDur.Premature                  =     cell2mat(hd_premature_sorted');
PSTHOut.Releases.PressDur.Late                       =     cell2mat(hd_late_sorted');
PSTHOut.Releases.Probe.Time                          =     t_probe_releases_sorted;
PSTHOut.Releases.Probe.Duration                      =     hd_probe_sorted;

% design a new structure to store these variables (2025) 
PSTHOut.Releases.TimeStruct.All  = event_table.t_release;
PSTHOut.Releases.TimeStruct.Correct_Sorted  = t_correct_releases_sorted;
PSTHOut.Releases.TimeStruct.RT_Correct_Sorted  = rt_correct_presses_sorted;
PSTHOut.Releases.TimeStruct.Correct_Unsorted  = t_correct_releases;
PSTHOut.Releases.TimeStruct.RT_Correct_Unsorted  = rt_correct_presses;
PSTHOut.Releases.TimeStruct.Premature_Sorted  = t_premature_releases_sorted;
PSTHOut.Releases.TimeStruct.Premature_Unsorted  = t_premature_releases;
PSTHOut.Releases.TimeStruct.HoldDuration_Premature_Sorted  = hd_premature_sorted;
PSTHOut.Releases.TimeStruct.HoldDuration_Premature_Unsorted  = hd_premature;
PSTHOut.Releases.TimeStruct.Late_Sorted  = t_late_releases_sorted;
PSTHOut.Releases.TimeStruct.Late_Unsorted  = t_late_releases;
PSTHOut.Releases.TimeStruct.HoldDuration_Late_Sorted  = hd_late_sorted;
PSTHOut.Releases.TimeStruct.HoldDuration_Late_Unsorted  = hd_late;
PSTHOut.Releases.TimeStruct.Probe  = t_probe_releases;
PSTHOut.Releases.TimeStruct.ProbeDuration  = t_probe_releases-t_probe_presses;

PSTHOut.Pokes.Time                             =       t_poke_all;
PSTHOut.Pokes.RewardPoke.Time                  =       t_poke; % it is a cell now!
PSTHOut.Pokes.RewardPoke.Move_Time             =       retrieval_duration;         % it is a cell now!
PSTHOut.Pokes.NonrewardPoke.Time               =       [];
PSTHOut.Pokes.NonrewardPoke.Move_Time          =       [];


%% Trigger
t_triggers = cell(1, nFPs);
RT_triggers = cell(1, nFPs);
t_triggers_late = cell(1, nFPs);
RT_triggers_late = cell(1, nFPs);

FP_triggers = cell(1, nFPs);
FP_triggers_late = cell(1, nFPs);

for i =1:nFPs
    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, {'Correct'}) & event_table.FP == MixedFPs(i);
    % short trigger (to plot)
    t_triggers{i}       =        event_table.t_trigger(index);
    RT_triggers{i}      =        event_table.rt(index);
    FP_triggers{i}      =        event_table.FP(index);

    index = strcmp(event_table.type, 'Normal') & strcmp(event_table.outcome, {'Late'}) & event_table.FP == MixedFPs(i);
    % short trigger (to plot)
    t_triggers_late{i}       =        event_table.t_trigger(index);
    RT_triggers_late{i}      =        event_table.rt(index);
    FP_triggers_late{i}      =        event_table.FP(index);

end

PSTHOut.Triggers.Labels                                  =       {'TriggerTime_DifferentFPs' 'TriggerTime_Late'};
PSTHOut.Triggers.Time                                    =       [t_triggers {cell2mat(t_triggers_late')}];
PSTHOut.Triggers.RT                                      =       [RT_triggers, {cell2mat(RT_triggers_late')}];
PSTHOut.Triggers.FP                                      =       {MixedFPs, cell2mat(FP_triggers_late')};

PSTHOut.OptoEpochs.Begs                             =     t_opto_begs;
PSTHOut.OptoEpochs.Ends                             =     t_opto_ends;

PSTHOut.SpikeNotes                                       =      r.Units.SpikeNotes;
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

    if by_time == 0
        PSTHOut.PSTH(iku)       = Spikes.SRT.ComputePlotPSTH2025(r, PSTHOut, ku,...
            'PressTimeDomain', PressTimeDomain, ...
            'ReleaseTimeDomain', ReleaseTimeDomain, ...
            'RewardTimeDomain', RewardTimeDomain,...
            'TriggerTimeDomain', TriggerTimeDomain,...
            'ToSave', ToSave);
    else
        PSTHOut.PSTH(iku)       = Spikes.SRT.ComputePlotPSTHByTime2025(r, PSTHOut, ku,...
            'PressTimeDomain', PressTimeDomain, ...
            'ReleaseTimeDomain', ReleaseTimeDomain, ...
            'RewardTimeDomain', RewardTimeDomain,...
            'TriggerTimeDomain', TriggerTimeDomain,...
            'ToSave', ToSave);
    end
end

if takeall
    
    r.PSTH.Events.Presses             = PSTHOut.Presses;
    r.PSTH.Events.Releases            = PSTHOut.Releases;
    r.PSTH.Events.Pokes               = PSTHOut.Pokes;
    r.PSTH.Events.Triggers            = PSTHOut.Triggers;
    r.PSTH.Events.OptoEpochs          = PSTHOut.OptoEpochs;
    r.PSTH.Events.Presses             = PSTHOut.Presses;
    r.PSTH.PSTHs                      = PSTHOut.PSTH;

    % r_name = Spikes.r_name;

    if isempty(r_name)
        r_name = ['RTarray_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '.mat'];
    end
    save(r_name, 'r', '-v7.3');
    psth_new_name             =      [Subject, '_', SessionInfo, '_PSTHs.mat'];
    save(psth_new_name, 'PSTHOut');

    % C:\Users\jiani\OneDrive\00_Work\03_Projects\05_Physiology\PSTHs
    % thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'PETHs', Subject);
    % if ~exist(thisFolder, 'dir')
    %     mkdir(thisFolder);
    % end
    % copyfile(psth_new_name, thisFolder);

end

