function PSTHOut = SpikesPSTH(r, ind, varargin)
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
by_rank = 0; % order the raster by time in a session

savepath = pwd;
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
            case 'path' % add by WXN 20250417
                savepath = varargin{i+1};
            case 'by_time'
                by_rank = varargin{i+1};     
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
%% Presses
ind_press           = find(strcmp(rb.Labels, 'LeverPress'));
t_presses           = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_press));
disp(['Number of presses is ' num2str(length(t_presses))])
% index and time of correct presses
t_correct_presses   = t_presses(rb.CorrectIndex);

%% Release
ind_release         = find(strcmp(rb.Labels, 'LeverRelease'));
t_releases          = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_release));
t_correct_releases  = t_releases(rb.CorrectIndex);
%% Presses during VI
ind_premature           = find(strcmp(r.Behavior.Outcome, 'Premature'));
t_presses_premature     = t_presses(ind_premature);
t_releases_premature    = t_releases(ind_premature);
%% Presses between rewarded press to next trial(VI)
ind_late        = find(strcmp(r.Behavior.Outcome, 'Late'));
t_presses_late  = t_presses(ind_late);
t_releases_late = t_releases(ind_late);
%%  Rewards
ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
t_rewards   = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_rewards));
move_time   = zeros(1, length(t_rewards));
tmax        = 10000; % allow at most 10 second between a successful release and poke

for i =1:length(t_rewards)
    dt = t_rewards(i)-t_correct_releases;
    dt = dt(dt>0 & dt<tmax); % reward must be collected within 2 sec after a correct release
    if ~isempty(dt)
        move_time(i) = dt(end);
    else
        move_time(i) = NaN;
    end
end

t_rewards = t_rewards(~isnan(move_time));
move_time = move_time(~isnan(move_time));

% Find out the reward pokes (last poke before valve.)
% port access, t_portin and t_portout
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_portin));
% have a look at the difference between poke and trigger (looks like there
% might be some contamination)
t_reward_pokes  = [];
dt              = []; % poke leading to reward

for i=1:length(t_rewards)
    t_portin_this = t_portin(t_portin >t_rewards(i)-1000 & t_portin<t_rewards(i)+100);
    if ~isempty(t_portin_this)
        t_reward_pokes(i) = t_portin_this(1);
        dt = [dt t_reward_pokes(i)-t_rewards(i)];
        %             disp(dt);
    else
        t_reward_pokes(i) = NaN;
    end
end

% due to technical error, pokes that occured 200 ms after reward is not
% real, should be corrected. (I don' t see this actually. Omitted for now 5/3/2023)
% check poke after reward
t_rewards_prime = t_rewards';
dt1=zeros(1, length(t_rewards_prime));
for i =1:length(t_rewards_prime)
    %     disp(i)
    
    indx = find(t_portin>t_rewards_prime(i), 1, 'first');
    if ~isempty(indx)
        dt1(i) = t_portin(indx) - t_rewards_prime(i);
    end
end

move_time_nonreward = [];
t_nonreward_pokes = [];
ind_badpoke = find(strcmp(rb.Labels, 'BadPoke'));
t_badpoke = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_badpoke)); % trigger time in ms.

for i=1:length(t_badpoke)
    t_releases_badpoke = t_releases_premature(find(t_releases_premature<t_badpoke(i),1,'last'));
    mt_nonreward = t_badpoke(i) - t_releases_badpoke;
    if mt_nonreward<5000 % MT < 5 second
        move_time_nonreward = [move_time_nonreward; mt_nonreward];
        t_nonreward_pokes = [t_nonreward_pokes; t_badpoke(i)];
    end
    
end

%% Trigger
ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
t_triggers = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_triggers)); % trigger time in ms.

triggers_types = cell(1, length(t_triggers));
triggers_RTs  = NaN*ones(1, length(t_triggers)); % reaction time (used for ranking later)

for i =1:length(t_triggers)
    it_trigger = t_triggers(i);
    % find the most recent press
    ind_recent_press = find(t_presses<it_trigger, 1, 'last');
    if ~isempty(ind_recent_press) && abs(t_presses(ind_recent_press)-it_trigger)<2500
        % check the condition
        triggers_types{i} = r.Behavior.Outcome{ind_recent_press};
        ind_following_releases = find(t_releases>it_trigger, 1, 'first');
        if ~isempty(ind_following_releases)
            triggers_RTs(i) = t_releases(ind_following_releases) - it_trigger;
        end
    else
        triggers_types{i} = 'NaN';
    end
end
%% Summarize

PSTHOut.ANM_Session         = {Subject, SessionInfo};

PSTHOut.Presses.Labels      = {'Correct', 'Premature', 'Late', 'All'};
PSTHOut.Presses.TimeCell    = {t_correct_presses, t_presses_premature, t_presses_late, t_presses};
PSTHOut.Presses.Time        = t_presses;

PSTHOut.Releases.Labels      = {'Correct', 'Premature', 'Late', 'All'};
PSTHOut.Releases.TimeCell    = {t_correct_releases, t_releases_premature, t_releases_late, t_releases};
PSTHOut.Releases.Time        = t_releases;

PSTHOut.Pokes.Time                      = t_portin;
PSTHOut.Pokes.RewardPoke.Time           = t_reward_pokes; % it is a cell now!
PSTHOut.Pokes.RewardPoke.Move_Time      = move_time;         % it is a cell now!
PSTHOut.Pokes.NonrewardPoke.Time        = t_nonreward_pokes;
PSTHOut.Pokes.NonrewardPoke.Move_Time   = move_time_nonreward;

PSTHOut.Triggers.Types  = triggers_types;
PSTHOut.Triggers.Time   = t_triggers;
PSTHOut.Triggers.RT     = triggers_RTs;

PSTHOut.Rewards.Time    = t_rewards;

PSTHOut.SpikeNotes      = r.Units.SpikeNotes;
%% Check how many units we need to compute
close all;
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
    
    PSTHOut.PSTH(iku) = Spikes.LeverPressVI.ComputePlotPSTH(r, PSTHOut, ku,...
        'PressTimeDomain', PressTimeDomain, ...
        'ReleaseTimeDomain', ReleaseTimeDomain, ...
        'RewardTimeDomain', RewardTimeDomain,...
        'TriggerTimeDomain', TriggerTimeDomain,...
        'ToSave', ToSave);
end

if takeall
    
    r.PSTH.Events.Presses             = PSTHOut.Presses;
    r.PSTH.Events.Releases            = PSTHOut.Releases;
    r.PSTH.Events.Pokes               = PSTHOut.Pokes;
    r.PSTH.Events.Triggers            = PSTHOut.Triggers;
    % r.PSTH.Events.OptoEpochs          = PSTHOut.OptoEpochs;
    % r.PSTH.Events.Presses             = PSTHOut.Presses;
    r.PSTH.PSTHs                         = PSTHOut.PSTH;

    % r_name = Spikes.r_name;
    

    if isempty(r_name)
        r_name = ['RTarray_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '.mat'];
    end
    
    save(r_name, 'r', '-v7.3');
    psth_new_name             =      [Subject, '_', SessionInfo, '_PSTHs.mat'];
    save(psth_new_name, 'PSTHOut', '-v7.3');

    % C:\Users\jiani\OneDrive\00_Work\03_Projects\05_Physiology\PSTHs
    % thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'PETHs', Subject);
    % if ~exist(thisFolder, 'dir')
    %     mkdir(thisFolder);
    % end
    % copyfile(psth_new_name, thisFolder);

end

