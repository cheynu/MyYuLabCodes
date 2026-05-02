function PSTH = ComputePlotPSTH26(r, ku, varargin)

% ComputePlotPSTHRewardProb26  Compute and plot PSTHs/raster for SRT session with reward-history grouping.
%
%   PSTH = ComputePlotPSTHRewardProb26(r, PSTHOut, ku)
%   PSTH = ComputePlotPSTHRewardProb26(..., 'Name', Value, ...)
%
%   This function computes peristimulus time histograms (PSTHs) and spike rasters
%   aligned to multiple task events (press, release, trigger, poke) for a single unit
%   (index ku) in a session represented by r. It produces a multi-panel figure
%   containing:
%       - Press- and release-aligned PSTHs and rasters split by FP and outcome
%         (Correct / Premature / Late)
%       - Probe and Dark trial PSTHs and rasters
%       - Poke-aligned PSTHs and rasters split by Rewarded / Omitted / Unrewarded
%       - Trigger-aligned PSTHs and rasters split by Correct / Late
%       - Reward-history modulation: PSTHs split by reward_level ('High' vs 'Low')
%         defined from recent reward probability (stored in r.EventTable.reward_level)
%       - Pre-press baseline firing vs time-in-session regression
%       - Spike waveform and ISI violation / autocorrelation summaries
%
%   Inputs
%   ------
%   r        : session struct/object containing:
%              - r.EventTable with fields: type, FP, outcome, reward, reward_level,
%                t_press, t_release, t_trigger, t_poke
%              - r.Units.SpikeTimes(ku).timings (ms) and waveform fields
%   PSTHOut  : (currently unused) placeholder for output configuration
%   ku       : unit index into r.Units.SpikeTimes / r.Units.SpikeNotes
%
%   Name-Value options
%   ------------------
%   'PressTimeDomain'    : [pre post] ms, time window around press (used for PSTH/raster)
%   'ReleaseTimeDomain'  : [pre post] ms, time window around release
%   'TriggerTimeDomain'  : [pre post] ms, time window around trigger
%   'RewardTimeDomain'   : [pre post] ms, time window around poke (reward port entry)
%   'by_time'            : 0 (default) sort rasters by duration; 1 keep trial order
%   'ToSave'             : 'on'/'off' (default 'on'); save .mat and .png into ./Fig
%   'UniformPSTHYLim'    : 'on'/'off' (default 'on'); apply a common y-limit to all PSTHs
%   'PSTHYLim'           : [y0 y1] numeric; manual y-limits for all PSTH panels if provided
%
%   Output
%   ------
%   PSTH : struct containing PSTHs, rasters, event times, durations, waveform and ISI metrics.
%
%   Notes
%   -----
%   - PSTHs are computed using Spikes.jpsth and smoothed with smoothdata(...,'gaussian',5).
%   - Reward-history grouping assumes r.EventTable.reward_level is precomputed per trial.
%
%   Jianing Yu, 2023-05-08
%   Yue Huang, 2023-06-26 (faster raster plotting)
%   Updated 2025-12-18 (reward probability / reward history structure)
PSTH.UnitID       = sprintf('%s_%s_Ch%d_Unit%d', r.BehaviorClass.Subject, r.BehaviorClass.Date, r.Units.SpikeNotes(ku, 1),r.Units.SpikeNotes(ku, 2));
by_time = 0;

UniformPSTHYLim = 'on';

if nargin>3
    for i=1:2:size(varargin,2)
        switch varargin{i}
            %             case 'FRrange'
            %                 FRrange = varargin{i+1};
            case 'PressTimeDomain'
                PressTimeDomain = varargin{i+1}; % PSTH time domain
            case 'ReleaseTimeDomain'
                ReleaseTimeDomain = varargin{i+1}; % PSTH time domain
            case 'RewardTimeDomain'
                RewardTimeDomain = varargin{i+1};
            case 'TriggerTimeDomain'
                TriggerTimeDomain = varargin{i+1};
            case 'by_time'
                by_time = varargin{i+1};
            case 'ToSave'
                ToSave = varargin{i+1};
            case 'UniformPSTHYLim'
                UniformPSTHYLim = varargin{i+1};
            case 'PSTHYLim'
                PSTHYLim = varargin{i+1};   % e.g. [0 30]
            otherwise
                errordlg('unknown argument')
        end
    end
end

% For PSTH and raster plots
press_col = [5 191 219]/255;
trigger_col = [242 182 250]/255;
release_col = [87, 108, 188]/255;
reward_col = [164, 208, 164]/255;

if isfield(r, 'BehaviorClass')
    MixedFPs = r.BehaviorClass.MixedFP;
else
    MixedFPs = Spikes.findFP(r);
end
nFPs = length(MixedFPs);

if nFPs == 2
    FP_cols = [192, 127, 0; 76, 61, 61]/255;
else
    FP_cols = [167, 39, 3; 252, 181, 59; 255, 231, 151;132, 153, 79]/255;
end
premature_col = [0.9 0.4 0.1];
late_col = [0.6 0.6 0.6];
printsize = [2 2 25 26];
probe_color = 'm';

%% PSTHs for press and release
params_press.pre            =             5000; % take a longer pre-press activity so we can compute z score easily later.
params_press.post          =              PressTimeDomain(2);
params_press.binwidth    =              20;

params_release.pre         =              ReleaseTimeDomain(1);
params_release.post        =              ReleaseTimeDomain(2);
params_release.binwidth    =              20;

params_trigger.pre          = TriggerTimeDomain(1);
params_trigger.post         = TriggerTimeDomain(2);
params_trigger.binwidth     =              20;

% All presses (this is used for computing pre-press activity versus time)
% Prepare all presses
t_presses   =   r.EventTable.t_press(~strcmp(r.EventTable.type, 'Dark'));
t_releases  =   r.EventTable.t_release(~strcmp(r.EventTable.type, 'Dark'));
hold_dur    =   t_releases - t_presses;
FPs_All     =   r.EventTable.FP(~strcmp(r.EventTable.type, 'Dark'));

[psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_presses, params_press);
psth_press = smoothdata(psth_press, 'gaussian', 5);
PSTH.Press.All.tPSTH           =   ts_press;
PSTH.Press.All.PSTH            =   psth_press;
PSTH.Press.All.tSpikeMat       =   tspkmat_press;
PSTH.Press.All.SpikeMat        =   trialspxmat_press;
PSTH.Press.All.tEvents         =   t_presses;
PSTH.Press.All.HoldDuration    =   hold_dur(ind_);
PSTH.Press.All.FP              =   FPs_All(ind_);

params_release.pre         =              ReleaseTimeDomain(1);
params_release.post        =              ReleaseTimeDomain(2);
params_release.binwidth    =              20;

[psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_releases, params_release);

psth_release = smoothdata(psth_release, 'gaussian', 5);

PSTH.Release.All.tPSTH            =           ts_release;
PSTH.Release.All.PSTH             =           psth_release;
PSTH.Release.All.tSpikeMat        =           tspkmat_release;
PSTH.Release.All.SpikeMat         =           trialspxmat_release;
PSTH.Release.All.tEvents          =           t_releases;
PSTH.Release.All.HoldDuration     =           hold_dur(ind_);
PSTH.Release.All.FP               =           FPs_All(ind_);

% Press/release PSTH (corrected, sorted)
FPs = unique(r.EventTable.FP(~strcmp(r.EventTable.type, 'WarmUp')));
nFPs = length(FPs);
beh_outcome = {'Correct', 'Premature', 'Late'};

typesPressRelease = {};

for i =1:nFPs
    iFP                     =   FPs(i);
    type_                   =   sprintf('FP_%d', iFP);
    typesPressRelease       =   [typesPressRelease type_];
    PSTH.Press.(type_)      =   struct('Correct', [], 'Premature', [], 'Late', []);
    PSTH.Release.(type_)    =   struct('Correct', [], 'Premature', [], 'Late', []);
    PSTH.Trigger.(type_)    =   struct('Correct', [], 'Late', []);

    for j =1:length(beh_outcome)
        outcome_ = beh_outcome{j};
        % Press times of this kind (this FP and this outcome)
        ind = strcmp(r.EventTable.type, 'Normal') & r.EventTable.FP == iFP & strcmp(r.EventTable.outcome, outcome_);
        t_presses   =   r.EventTable.t_press(ind);
        t_releases  =   r.EventTable.t_release(ind);
        hold_dur    =   t_releases - t_presses;
        [psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
            t_presses, params_press);
        psth_press = smoothdata(psth_press, 'gaussian', 5);
        PSTH.Press.(type_).(outcome_).tPSTH           =   ts_press;
        PSTH.Press.(type_).(outcome_).PSTH            =   psth_press;
        PSTH.Press.(type_).(outcome_).tSpikeMat       =   tspkmat_press;
        PSTH.Press.(type_).(outcome_).SpikeMat        =   trialspxmat_press;
        PSTH.Press.(type_).(outcome_).tEvents         =   t_presses;
        PSTH.Press.(type_).(outcome_).HoldDuration    =   hold_dur(ind_);

        [psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
            t_releases, params_release);
        psth_release = smoothdata(psth_release, 'gaussian', 5);
        PSTH.Release.(type_).(outcome_).tPSTH           =   ts_release;
        PSTH.Release.(type_).(outcome_).PSTH            =   psth_release;
        PSTH.Release.(type_).(outcome_).tSpikeMat       =   tspkmat_release;
        PSTH.Release.(type_).(outcome_).SpikeMat        =   trialspxmat_release;
        PSTH.Release.(type_).(outcome_).tEvents         =   t_releases;
        PSTH.Release.(type_).(outcome_).HoldDuration    =   hold_dur(ind_);

        if strcmp(outcome_, 'Correct') || strcmp(outcome_, 'Late')
            t_trigger  =   r.EventTable.t_trigger(ind);
            t_release  =   r.EventTable.t_release(ind);
            rt          =   t_release - t_trigger;
            [psth_trigger, ts_trigger, trialspxmat_trigger, tspkmat_trigger, t_trigger, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
                t_trigger, params_trigger);
            psth_trigger = smoothdata(psth_trigger, 'gaussian', 5);
            PSTH.Trigger.(type_).(outcome_).tPSTH           =   ts_trigger;
            PSTH.Trigger.(type_).(outcome_).PSTH            =   psth_trigger;
            PSTH.Trigger.(type_).(outcome_).tSpikeMat       =   tspkmat_trigger;
            PSTH.Trigger.(type_).(outcome_).SpikeMat        =   trialspxmat_trigger;
            PSTH.Trigger.(type_).(outcome_).tEvents         =   t_trigger;
            PSTH.Trigger.(type_).(outcome_).HoldDuration    =   hold_dur(ind_);
            PSTH.Trigger.(type_).(outcome_).ReactionTime    =   rt(ind_);
        end
    end
end

% Specifically design rewarded versus unrewarded release.
types = {'Rewarded', 'Unrewarded'};

for i =1:length(types)
    itype                   =   types{i};
    switch itype
        case 'Rewarded'
            ind = strcmp(r.EventTable.outcome, 'Correct') & strcmp(r.EventTable.reward, 'Rewarded');
        case 'Unrewarded'
            ind = ~strcmp(r.EventTable.outcome, 'Dark') & strcmp(r.EventTable.reward, 'NaN');
    end

    t_presses   =   r.EventTable.t_press(ind);
    t_releases  =   r.EventTable.t_release(ind);
    hold_dur    =   t_releases - t_presses;

    [psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_releases, params_release);
    psth_release = smoothdata(psth_release, 'gaussian', 5);
    PSTH.Release.(itype).tPSTH           =   ts_release;
    PSTH.Release.(itype).PSTH            =   psth_release;
    PSTH.Release.(itype).tSpikeMat       =   tspkmat_release;
    PSTH.Release.(itype).SpikeMat        =   trialspxmat_release;
    PSTH.Release.(itype).tEvents         =   t_releases;
    PSTH.Release.(itype).HoldDuration    =   hold_dur(ind_);
end

% Probe trials
PSTH.Press.Probe     =   struct();
PSTH.Release.Probe   =   struct();
ind                 =   strcmp(r.EventTable.type, 'Probe');
t_presses   =   r.EventTable.t_press(ind);
t_releases  =   r.EventTable.t_release(ind);
hold_dur    =   t_releases - t_presses;
[psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_presses, params_press);
psth_press = smoothdata(psth_press, 'gaussian', 5);
PSTH.Press.Probe.tPSTH           =   ts_press;
PSTH.Press.Probe.PSTH            =   psth_press;
PSTH.Press.Probe.tSpikeMat       =   tspkmat_press;
PSTH.Press.Probe.SpikeMat        =   trialspxmat_press;
PSTH.Press.Probe.tEvents         =   t_presses;
PSTH.Press.Probe.HoldDuration    =   hold_dur(ind);

[psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_releases, params_release);
psth_release = smoothdata(psth_release, 'gaussian', 5);
PSTH.Release.Probe.tPSTH           =   ts_release;
PSTH.Release.Probe.PSTH            =   psth_release;
PSTH.Release.Probe.tSpikeMat       =   tspkmat_release;
PSTH.Release.Probe.SpikeMat        =   trialspxmat_release;
PSTH.Release.Probe.tEvents         =   t_releases;
PSTH.Release.Probe.HoldDuration    =   hold_dur(ind);

% Dark presses
PSTH.Press.Dark     =   struct();
PSTH.Release.Dark   =   struct();
ind                 =   strcmp(r.EventTable.outcome, 'Dark');
t_presses   =   r.EventTable.t_press(ind);
t_releases  =   r.EventTable.t_release(ind);
hold_dur    =   t_releases - t_presses;
[psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_presses, params_press);
psth_press = smoothdata(psth_press, 'gaussian', 5);
PSTH.Press.Dark.tPSTH           =   ts_press;
PSTH.Press.Dark.PSTH            =   psth_press;
PSTH.Press.Dark.tSpikeMat       =   tspkmat_press;
PSTH.Press.Dark.SpikeMat        =   trialspxmat_press;
PSTH.Press.Dark.tEvents         =   t_presses;
PSTH.Press.Dark.HoldDuration    =   hold_dur(ind);

[psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_releases, params_release);
psth_release = smoothdata(psth_release, 'gaussian', 5);
PSTH.Release.Dark.tPSTH           =   ts_release;
PSTH.Release.Dark.PSTH            =   psth_release;
PSTH.Release.Dark.tSpikeMat       =   tspkmat_release;
PSTH.Release.Dark.SpikeMat        =   trialspxmat_release;
PSTH.Release.Dark.tEvents         =   t_releases;
PSTH.Release.Dark.HoldDuration    =   hold_dur(ind);

% here i also compute the low-rewarded block vs high-reward block
% Press/release PSTH (high-rewarded or low-rewarded trials)
params_press_.pre            =             2000; % take a longer pre-press activity so we can compute z score easily later.
params_press_.post           =              500;
params_press_.binwidth       =              20;

params_release_.pre            =             500; % take a longer pre-press activity so we can compute z score easily later.
params_release_.post           =             500;
params_release_.binwidth       =             20;

types = {'High', 'Low'};
for j =1:length(types)
    type_ = types{j};
    % These are the trials with previous reward history of type_ (high or
    % low, defined by calculated reward probability and a threshold of 0.5)
    ind = strcmp(r.EventTable.type, 'Normal') & strcmp(r.EventTable.outcome, 'Correct') & strcmp(r.EventTable.reward_level, type_);
    t_presses   =   r.EventTable.t_press(ind);
    t_releases  =   r.EventTable.t_release(ind);
    hold_dur    =   t_releases - t_presses;
    [psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_presses, params_press_);
    psth_press = smoothdata(psth_press, 'gaussian', 5);
    PSTH.Press.(type_).tPSTH           =   ts_press;
    PSTH.Press.(type_).PSTH            =   psth_press;
    PSTH.Press.(type_).tSpikeMat       =   tspkmat_press;
    PSTH.Press.(type_).SpikeMat        =   trialspxmat_press;
    PSTH.Press.(type_).tEvents         =   t_presses;
    PSTH.Press.(type_).HoldDuration    =   hold_dur(ind_);

    [psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_releases, params_release_);
    psth_release = smoothdata(psth_release, 'gaussian', 5);
    PSTH.Release.(type_).tPSTH           =   ts_release;
    PSTH.Release.(type_).PSTH            =   psth_release;
    PSTH.Release.(type_).tSpikeMat       =   tspkmat_release;
    PSTH.Release.(type_).SpikeMat        =   trialspxmat_release;
    PSTH.Release.(type_).tEvents         =   t_releases;
    PSTH.Release.(type_).HoldDuration    =   hold_dur(ind_);

    % Here we extract trigger related activity
    ind = strcmp(r.EventTable.type, 'Normal') & ismember(r.EventTable.outcome, {'Correct'}) & strcmp(r.EventTable.reward_level, type_);
    t_trigger  =   r.EventTable.t_trigger(ind);
    t_release  =   r.EventTable.t_release(ind);
    rt          =   t_release - t_trigger;
    [psth_trigger, ts_trigger, trialspxmat_trigger, tspkmat_trigger, t_trigger, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_trigger, params_trigger);
    psth_trigger = smoothdata(psth_trigger, 'gaussian', 5);
    PSTH.Trigger.(type_).tPSTH           =   ts_trigger;
    PSTH.Trigger.(type_).PSTH            =   psth_trigger;
    PSTH.Trigger.(type_).tSpikeMat       =   tspkmat_trigger;
    PSTH.Trigger.(type_).SpikeMat        =   trialspxmat_trigger;
    PSTH.Trigger.(type_).tEvents         =   t_trigger;
    PSTH.Trigger.(type_).ReactionTime    =   rt(ind_);
end

%% Poke-related activity (this might be complicated)
% Note that in
% use t_reward_poke and move_time to construct reward_poke PSTH
% reward PSTH
params_poke.pre             =       RewardTimeDomain(1);
params_poke.post            =       RewardTimeDomain(2);
params_poke.binwidth        =       20;

poke_types = {'Rewarded', 'Omitted', 'Unrewarded', 'All'};
% Rewarded: rewarded poke following a correct response
% Omitted: correct response, but not rewarded
% Unrewarded: poke after incorrect responses

spk_table = table;
pre_poke_win = 500; % pre-poke window
post_poke_win = 500;

PSTH.Poke = struct('Rewarded', [], 'Omitted', [], 'Unrewarded', [], 'All', []);
for j=1:length(poke_types)
    j_poke_type = poke_types{j};
    % look for index
    switch j_poke_type
        case 'Rewarded'
            ind = ~isnan(r.EventTable.t_poke) & ~strcmp(r.EventTable.type, 'WarmUp') & strcmp(r.EventTable.outcome, 'Correct') & strcmp(r.EventTable.reward, 'Rewarded');
        case 'Unrewarded'
            ind = ~isnan(r.EventTable.t_poke) & ~strcmp(r.EventTable.type, 'WarmUp') & ~strcmp(r.EventTable.outcome, 'Correct');
        case 'Omitted'
            ind = ~isnan(r.EventTable.t_poke) & ~strcmp(r.EventTable.type, 'WarmUp') & strcmp(r.EventTable.outcome, 'Correct') & strcmp(r.EventTable.reward, 'Omitted');
        case 'All'
            ind = ~isnan(r.EventTable.t_poke) & ~strcmp(r.EventTable.type, 'WarmUp');
    end

    if ~isempty(ind)
        t_poke              =       r.EventTable.t_poke(ind);
        t_releases          =       r.EventTable.t_release(ind);
        move_dur            =       t_poke - t_releases;

        more_pokes = cell(1, length(ind));
        if any(strcmp(r.EventTable.Properties.VariableNames, 't_pokes_more'))
            more_pokes          =       r.EventTable.t_pokes_more(ind);
            for k =1:length(more_pokes)
                more_pokes{k} = more_pokes{k} - t_poke(k);
            end
        end

        [psth_poke, ts_poke, trialspxmat_poke, tspkmat_poke, t_poke, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
            t_poke, params_poke);

        psth_poke = smoothdata(psth_poke, 'gaussian', 5);
        PSTH.Poke.(j_poke_type).tPSTH              =   ts_poke;
        PSTH.Poke.(j_poke_type).PSTH               =   psth_poke;
        PSTH.Poke.(j_poke_type).tSpikeMat          =   tspkmat_poke;
        PSTH.Poke.(j_poke_type).SpikeMat           =   trialspxmat_poke;
        PSTH.Poke.(j_poke_type).tEvents            =   t_poke;
        PSTH.Poke.(j_poke_type).MovementDuration   =   move_dur(ind_);
        PSTH.Poke.(j_poke_type).MovementDuration   =   move_dur(ind_);
        PSTH.Poke.(j_poke_type).MorePokes          =   more_pokes(ind_);

        if ismember(j_poke_type, {'Rewarded', 'Omitted'})
            % pre-poke
            ind_pre     =   find(tspkmat_poke>=-pre_poke_win & tspkmat_poke<0);
            ind_post    =   find(tspkmat_poke>=0 & tspkmat_poke<post_poke_win);

            num_pre = sum(trialspxmat_poke(ind_pre, :), 1);
            num_post = sum(trialspxmat_poke(ind_post, :), 1);

            this_row = table(repmat({j_poke_type}, length(num_pre), 1), ...
                num_pre', num_post', ...
                'VariableNames', {'RewardType', 'Pre', 'Post'});
            spk_table = [spk_table; this_row];
        end
    end
end

glm_mdl = [];
if any(strcmp(spk_table.RewardType, 'Omitted')) && sum(strcmp(spk_table.RewardType, 'Omitted'))>10
    glm_mdl = Spikes.GLM_RewardProb(spk_table);
end

types = {'High', 'Low'};
for j =1:length(types)
    type_ = types{j};
    % Here we extract reward-orienting related activity
    ind = strcmp(r.EventTable.type, 'Normal') & ismember(r.EventTable.outcome, {'Correct'}) & strcmp(r.EventTable.reward_level, type_);
    ind = ind & ~isnan(r.EventTable.t_poke);
    t_poke      =   r.EventTable.t_poke(ind);
    t_releases  =   r.EventTable.t_release(ind);
    move_dur    =   t_poke - t_releases;

    [psth_poke, ts_poke, trialspxmat_poke, tspkmat_poke, t_poke, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_poke, params_poke);
    psth_poke = smoothdata(psth_poke, 'gaussian', 5);

    PSTH.Poke.(type_).tPSTH              =   ts_poke;
    PSTH.Poke.(type_).PSTH               =   psth_poke;
    PSTH.Poke.(type_).tSpikeMat          =   tspkmat_poke;
    PSTH.Poke.(type_).SpikeMat           =   trialspxmat_poke;
    PSTH.Poke.(type_).tEvents            =   t_poke;
    PSTH.Poke.(type_).MovementDuration   =   move_dur(ind_);
end

%% Check for PSTH range
% ---------- helper: safe max ----------
safeMax = @(x) max([0; x(:)], [], 'omitnan');

n_min = 10;                 % you already have this
% ---------- Press ----------
FRMaxPress = 5;  % floor
% Correct
for i = 1:numel(typesPressRelease)
    FRMaxPress = max(FRMaxPress, safeMax(PSTH.Press.(typesPressRelease{i}).Correct.PSTH));
end
% Premature + Late (only if enough trials)
for i = 1:numel(typesPressRelease)
    if numel(PSTH.Press.(typesPressRelease{i}).Premature.tEvents) > n_min
        FRMaxPress = max(FRMaxPress, safeMax(PSTH.Press.(typesPressRelease{i}).Premature.PSTH));
    end
    if numel(PSTH.Press.(typesPressRelease{i}).Late.tEvents) > n_min
        FRMaxPress = max(FRMaxPress, safeMax(PSTH.Press.(typesPressRelease{i}).Late.PSTH));
    end
end
% Dark
if numel(PSTH.Press.Dark.tEvents) > n_min
    FRMaxPress = max(FRMaxPress, safeMax(PSTH.Press.Dark.PSTH));
end

% ---------- Release ----------
FRMaxRelease = 5;
for i = 1:numel(typesPressRelease)
    FRMaxRelease = max(FRMaxRelease, safeMax(PSTH.Release.(typesPressRelease{i}).Correct.PSTH));
end
for i = 1:numel(typesPressRelease)
    if numel(PSTH.Release.(typesPressRelease{i}).Premature.tEvents) > n_min
        FRMaxRelease = max(FRMaxRelease, safeMax(PSTH.Release.(typesPressRelease{i}).Premature.PSTH));
    end
    if numel(PSTH.Release.(typesPressRelease{i}).Late.tEvents) > n_min
        FRMaxRelease = max(FRMaxRelease, safeMax(PSTH.Release.(typesPressRelease{i}).Late.PSTH));
    end
end
if numel(PSTH.Release.Dark.tEvents) > n_min
    FRMaxRelease = max(FRMaxRelease, safeMax(PSTH.Release.Dark.PSTH));
end

% ---------- Poke ----------
FRMaxPoke = 5;
if isfield(PSTH,'Poke') && isfield(PSTH.Poke,'Rewarded')
    FRMaxPoke = max(FRMaxPoke, safeMax(PSTH.Poke.Rewarded.PSTH));
end
% if isfield(PSTH,'Poke') && isfield(PSTH.Poke,'Unrewarded')
%     FRMaxPoke = max(FRMaxPoke, safeMax(PSTH.Poke.Unrewarded.PSTH));
% end

% ---------- Trigger ----------
FRMaxTrigger = 5;
for i = 1:numel(typesPressRelease)
    FRMaxTrigger = max(FRMaxTrigger, safeMax(PSTH.Trigger.(typesPressRelease{i}).Correct.PSTH));
    FRMaxTrigger = max(FRMaxTrigger, safeMax(PSTH.Trigger.(typesPressRelease{i}).Late.PSTH));
end

% FRMaxTrigger = max(FRMaxTrigger, safeMax(PSTH.Trigger.Cue.Late.PSTH));

% optional: round up nicely
roundUp = @(v,step) step*ceil(v/step);
FRMaxPress   = roundUp(FRMaxPress,   1);
FRMaxRelease = roundUp(FRMaxRelease, 1);
FRMaxPoke    = roundUp(FRMaxPoke,    1);
FRMaxTrigger = roundUp(FRMaxTrigger, 1);
FRMax = 1.1*max([FRMaxPress FRMaxRelease FRMaxPoke FRMaxTrigger]);

%% Plot raster and spks
hf=27;
figure(hf); clf(hf)
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')
height_psth = 1.2;

width_release = 6*sum(ReleaseTimeDomain)/sum(PressTimeDomain);
xrange_release = [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)];
x_release = 8.25;

% PSTH of correct press trials
yshift_row1 = 10;
vspacing = 0.5;
ha_press_psth =  axes('unit', 'centimeters', 'position', [1.25 yshift_row1 6 height_psth], 'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);
yshift_row2 = yshift_row1+height_psth+vspacing;
for i =1:nFPs
    field = sprintf('FP_%d', FPs(i));
    t       = PSTH.Press.(field).Correct.tPSTH;
    ipsth   = PSTH.Press.(field).Correct.PSTH;
    plot(t, ipsth, 'color', FP_cols(i, :),  'linewidth', 1.5);
    xline(ha_press_psth, FPs(i), 'color', trigger_col, 'linestyle', '-.', 'linewidth', 1);
end
lockPsthAxis(ha_press_psth, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Correct', 'corner', 'topleft');

xlabel('Time from press (ms)')
ylabel ('Spks per s')

% Add release panel
ha_release_psth =  axes('unit', 'centimeters', ...
    'position', [x_release yshift_row1 width_release height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_release);
for i =1:nFPs
    field = sprintf('FP_%d', FPs(i));
    t       = PSTH.Release.(field).Correct.tPSTH;
    ipsth   = PSTH.Release.(field).Correct.PSTH;
    plot(t, ipsth, 'color', FP_cols(i, :),  'linewidth', 1.5);
end
lockPsthAxis(ha_release_psth, FRMax, 0, release_col);
xlabel('Time from release (ms)')

% PSTH of probe trials (press)
ha_press_psth_probe =  axes('unit', 'centimeters', 'position', [1.25 yshift_row2 6 height_psth], ...
    'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'xtick', []);
probe_col = '#412B6B';
field = 'Probe';
t       = PSTH.Press.(field).tPSTH;
ipsth   = PSTH.Press.(field).PSTH;
plot(t, ipsth, 'color', probe_col,  'linewidth', 1.5);
lockPsthAxis(ha_press_psth_probe, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Probe', 'corner', 'topleft');

% Add release
ha_release_psth_probe =  axes('unit', 'centimeters', ...
    'position', [x_release yshift_row2 width_release height_psth], ...
    'nextplot', 'add', 'xlim', xrange_release, 'xtick', []);
yshift_row2 = yshift_row2+height_psth+vspacing;

field = 'Probe';
t       = PSTH.Release.(field).tPSTH;
ipsth   = PSTH.Release.(field).PSTH;
plot(t, ipsth, 'color', probe_col,  'linewidth', 1.5);
lockPsthAxis(ha_release_psth_probe, FRMax, 0, release_col);
% PSTH of error trials (premature and late)
ha_press_psth_error =  axes('unit', 'centimeters', 'position', [1.25 yshift_row2 6 height_psth], 'nextplot', 'add',...
    'xlim',  [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'xticklabel', []);
n_min = 5;
for i = 1:nFPs
    field = sprintf('FP_%d', FPs(i));
    % premature
    t       =   PSTH.Press.(field).Premature.tPSTH;
    ipsth   =   PSTH.Press.(field).Premature.PSTH;
    n       =   numel(PSTH.Press.(field).Premature.tEvents);
    if n > n_min
        plot(t, ipsth, 'color', premature_col,...
            'linewidth', 1.5, 'linestyle', '-');
    end
    % late
    t       =   PSTH.Press.(field).Late.tPSTH;
    ipsth   =   PSTH.Press.(field).Late.PSTH;
    n       =   numel(PSTH.Press.(field).Late.tEvents);
    if n > n_min
        plot(t, ipsth, 'color', late_col,...
            'linewidth', 1.5, 'linestyle', '-');
     end
end
lockPsthAxis(ha_press_psth_error, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Incorrect', 'corner', 'topleft');

% PSTH of error trials (release)
ha_release_psth_error =  axes('unit', 'centimeters', ...
    'position', [x_release yshift_row2 width_release height_psth], 'nextplot', 'add',...
    'xlim',  xrange_release, 'xticklabel', []);

n_min = 5;
for i = 1:nFPs
    field = sprintf('FP_%d', FPs(i));
    % premature
    t       =   PSTH.Release.(field).Premature.tPSTH;
    ipsth   =   PSTH.Release.(field).Premature.PSTH;
    n       =   numel(PSTH.Release.(field).Premature.tEvents);
    if n > n_min
        plot(t, ipsth, 'color', premature_col,...
            'linewidth', 1.5, 'linestyle', '-');
    end
    % late
    t       =   PSTH.Release.(field).Late.tPSTH;
    ipsth   =   PSTH.Release.(field).Late.PSTH;
    n       =   numel(PSTH.Release.(field).Late.tEvents);
    if n > n_min
        plot(t, ipsth, 'color', late_col,...
            'linewidth', 1.5, 'linestyle', '-');
     end
end
lockPsthAxis(ha_release_psth_error, FRMax, 0, release_col);

% PSTH of dark trials
yshift_row2_ = yshift_row2 + height_psth+vspacing;
ha_press_psth_dark =  axes('unit', 'centimeters', 'position', [1.25 yshift_row2_ 6 height_psth], 'nextplot', 'add',...
    'xlim',  [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'xticklabel', []);
yshift_row3 = yshift_row2_ +height_psth+vspacing;
t       =   PSTH.Press.Dark.tPSTH;
ipsth   =   PSTH.Press.Dark.PSTH;
n       =   numel(PSTH.Press.Dark.tEvents);
dark_color = '#1B211A';
if n > n_min
    plot(t, ipsth, 'color', dark_color,...
        'linewidth', 1, 'linestyle', '-');
end
lockPsthAxis(ha_press_psth_dark, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Dark', 'corner', 'topleft');

% Add release
ha_release_psth_dark =  axes('unit', 'centimeters', ...
    'position', [x_release yshift_row2_ width_release height_psth], ...
    'nextplot', 'add',...
    'xlim',  xrange_release, 'xticklabel', []);
yshift_row3 = yshift_row2_ +height_psth+vspacing;
t       =   PSTH.Release.Dark.tPSTH;
ipsth   =   PSTH.Release.Dark.PSTH;
n       =   numel(PSTH.Release.Dark.tEvents);
dark_color = '#1B211A';
if n > n_min
    plot(t, ipsth, 'color', dark_color,...
        'linewidth', 1, 'linestyle', '-');
end
lockPsthAxis(ha_release_psth_dark, FRMax, 0, release_col);
%% Plot spike raster of correct trials (all FPs)
n_presses = numel(PSTH.Press.All.tEvents);
rasterheight = 0.02*100/n_presses;

if by_time == 0
    ntrials_press = 0;
    nFP_i = zeros(1, nFPs);
    for i =1:nFPs
        field = sprintf('FP_%d', FPs(i));
        nFP_i(i) = numel(PSTH.Press.(field).Correct.tEvents);
        ntrials_press = ntrials_press + nFP_i(i);
    end
    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row3 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row4 = yshift_row3+ntrials_press*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    for m =1:nFPs
        field = sprintf('FP_%d', FPs(m));
        ap_mat = PSTH.Press.(field).Correct.SpikeMat;
        t_mat = PSTH.Press.(field).Correct.tSpikeMat;
        hold_dur = PSTH.Press.(field).Correct.HoldDuration'; % make sure it is 1 x nTrial
        % sort hold_dur (if needed)
        if by_time == 0
            [hold_dur, ind_sort] = sort(hold_dur);
            ap_mat = ap_mat(:, ind_sort);
        end
        fp_color = trigger_col;
        fp_dur = FPs(m);
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur, fp_dur, fp_color);
    end
    xline(-PressTimeDomain(1), 'color', 'k', 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Correct',ntrials_press), 'corner', 'topleft');
    axis off

    % Add release
    ntrials_press = 0;
    nFP_i = zeros(1, nFPs);
    for i =1:nFPs
        field = sprintf('FP_%d', FPs(i));
        nFP_i(i) = numel(PSTH.Release.(field).Correct.tEvents);
        ntrials_press = ntrials_press + nFP_i(i);
    end

    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row3 width_release ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_press 1], 'box', 'on');
    % Paint the foreperiod
    k=0;
    for m =1:nFPs
        field = sprintf('FP_%d', FPs(m));
        ap_mat = PSTH.Release.(field).Correct.SpikeMat;
        t_mat = PSTH.Release.(field).Correct.tSpikeMat;
        hold_dur = PSTH.Release.(field).Correct.HoldDuration;
        n_trial = size(ap_mat, 2);

        % sort hold_dur (if needed)
        if by_time == 0
            [hold_dur, ind_sort] = sort(hold_dur);
            ap_mat = ap_mat(:, ind_sort);
        end

        fp_color = trigger_col;
        fp_dur = FPs(m);
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    end
    xline(-ReleaseTimeDomain(1), 'color', 'k', 'linewidth', 2);
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off

    % Plot spike raster of probe trials
    ntrials_press = numel(PSTH.Press.Probe.tEvents);
    ax=axes('unit', 'centimeters', 'position', [1.25 yshift_row4 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    % Paint the foreperiod
    k=0;
    ap_mat = PSTH.Press.Probe.SpikeMat;
    t_mat = PSTH.Press.Probe.tSpikeMat;
    hold_dur = PSTH.Press.Probe.HoldDuration;
    % sort hold_dur (if needed)
    if by_time == 0
        [hold_dur, ind_sort] = sort(hold_dur);
        ap_mat = ap_mat(:, ind_sort);
    end

    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur);
    xline(-PressTimeDomain(1), 'color', probe_col, 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Probe',ntrials_press), 'corner', 'topleft');
    axis off

    % Plot spike raster of probe trials (release)
    ntrials_press = numel(PSTH.Release.Probe.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row4 width_release ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row4 = yshift_row4+ntrials_press*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    ap_mat = PSTH.Release.Probe.SpikeMat;
    t_mat = PSTH.Release.Probe.tSpikeMat;
    hold_dur = PSTH.Release.Probe.HoldDuration;
    % sort hold_dur (if needed)
    if by_time == 0
        [hold_dur, ind_sort] = sort(hold_dur);
        ap_mat = ap_mat(:, ind_sort);
    end
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    xline(-ReleaseTimeDomain(1), 'color', probe_col, 'linewidth', 2);
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off

    % Plot spike raster of premature trials (all FPs)
    ntrials_press = 0;
    nFP_i = zeros(1, nFPs);
    for i =1:nFPs
        field = sprintf('FP_%d', FPs(i));
        nFP_i(i) = numel(PSTH.Press.(field).Premature.tEvents);
        ntrials_press = ntrials_press + nFP_i(i);
    end

    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row4 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row5 = yshift_row4+ntrials_press*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    for m =1:nFPs
        field = sprintf('FP_%d', FPs(m));
        ap_mat = PSTH.Press.(field).Premature.SpikeMat;
        t_mat = PSTH.Press.(field).Premature.tSpikeMat;
        hold_dur = PSTH.Press.(field).Premature.HoldDuration;
        n_trial = size(ap_mat, 2);
        % sort hold_dur (if needed)
        if by_time == 0
            [hold_dur, ind_sort] = sort(hold_dur);
            ap_mat = ap_mat(:, ind_sort);
        end
        fp_color = trigger_col;
        fp_dur = FPs(m);
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur, fp_dur,fp_color);
    end
    xline(-PressTimeDomain(1), 'color', premature_col, 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Premature',ntrials_press), 'corner', 'topleft');
    axis off

    % release
    % Plot spike raster of premature trials (all FPs) Release
    ntrials_press = 0;
    nFP_i = zeros(1, nFPs);
    for i =1:nFPs
        field = sprintf('FP_%d', FPs(i));
        nFP_i(i) = numel(PSTH.Release.(field).Premature.tEvents);
        ntrials_press = ntrials_press + nFP_i(i);
    end

    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row4 width_release ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_press 1], 'box', 'on');
    % Paint the foreperiod
    k=0;
    for m =1:nFPs
        field = sprintf('FP_%d', FPs(m));
        ap_mat = PSTH.Release.(field).Premature.SpikeMat;
        t_mat = PSTH.Release.(field).Premature.tSpikeMat;
        hold_dur = PSTH.Release.(field).Premature.HoldDuration;
        n_trial = size(ap_mat, 2);
        % sort hold_dur (if needed)
        if by_time == 0
            [hold_dur, ind_sort] = sort(hold_dur);
            ap_mat = ap_mat(:, ind_sort);
        end
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    end
    xline(-ReleaseTimeDomain(1), 'color', premature_col, 'linewidth', 2);
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off

    % Plot spike raster of late trials (all FPs)
    ntrials_press = 0;
    nFP_i = zeros(1, nFPs);
    for i =1:nFPs
        field = sprintf('FP_%d', FPs(i));
        nFP_i(i) = numel(PSTH.Press.(field).Late.tEvents);
        ntrials_press = ntrials_press + nFP_i(i);
    end
    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row5 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row6 = yshift_row5+ntrials_press*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    for m =1:nFPs
        field = sprintf('FP_%d', FPs(m));
        ap_mat = PSTH.Press.(field).Late.SpikeMat;
        t_mat = PSTH.Press.(field).Late.tSpikeMat;
        hold_dur = PSTH.Press.(field).Late.HoldDuration;
        n_trial = size(ap_mat, 2);
        % sort hold_dur (if needed)
        if by_time == 0
            [hold_dur, ind_sort] = sort(hold_dur);
            ap_mat = ap_mat(:, ind_sort);
        end
        fp_color = trigger_col;
        fp_dur = FPs(m);
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur, fp_dur, fp_color);
    end
    xline(-PressTimeDomain(1), 'color', late_col, 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Late',ntrials_press), 'corner', 'topleft');
    axis off

    % Release
    % Plot spike raster of late trials (all FPs) Release
    ntrials_press = 0;
    nFP_i = zeros(1, nFPs);
    for i =1:nFPs
        field = sprintf('FP_%d', FPs(i));
        nFP_i(i) = numel(PSTH.Release.(field).Late.tEvents);
        ntrials_press = ntrials_press + nFP_i(i);
    end

    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row5 width_release ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_press 1], 'box', 'on');
    % Paint the foreperiod
    k=0;
    for m =1:nFPs
        field = sprintf('FP_%d', FPs(m));
        ap_mat = PSTH.Release.(field).Late.SpikeMat;
        t_mat = PSTH.Release.(field).Late.tSpikeMat;
        hold_dur = PSTH.Release.(field).Late.HoldDuration;
        n_trial = size(ap_mat, 2);
        % sort hold_dur (if needed)
        if by_time == 0
            [hold_dur, ind_sort] = sort(hold_dur);
            ap_mat = ap_mat(:, ind_sort);
        end

        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    end
    xline(-ReleaseTimeDomain(1), 'color', late_col, 'linewidth', 2);
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off

else % plot byTime, use All data

    ntrials_press = numel(PSTH.Press.All.tEvents);
    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row3 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row4 = yshift_row3+ntrials_press*rasterheight+0.5;
    yshift_row6 = yshift_row4;
    % Paint the foreperiod
    k=0;
    ap_mat      =   PSTH.Press.All.SpikeMat;
    t_mat       =   PSTH.Press.All.tSpikeMat;
    hold_dur    =   PSTH.Press.All.HoldDuration'; % make sure it is 1 x nTrial
    fp_mat      =   PSTH.Press.All.FP;

    for i =1:length(fp_mat)
        line([0 fp_mat(i)], [1-i 1-i]+k, 'color', trigger_col);
    end

    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur);
    xline(-PressTimeDomain(1), 'color', 'k', 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','All',ntrials_press), 'corner', 'topleft');
    axis off

    % Add release
    ntrials_release = numel(PSTH.Release.All.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row3 width_release ntrials_release*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_release 1], 'box', 'on');
    % Paint the foreperiod
    k=0;

    % Paint the foreperiod
    k=0;
    ap_mat      =   PSTH.Release.All.SpikeMat;
    t_mat       =   PSTH.Release.All.tSpikeMat;
    hold_dur    =   PSTH.Release.All.HoldDuration'; % make sure it is 1 x nTrial
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    xline(-ReleaseTimeDomain(1), 'color', 'k', 'linewidth', 2);
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off
end

% Dark press raster plot
n_press_types = size(PSTH.Press.Dark.SpikeMat, 2);
ntrial_dark = n_press_types;
ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row6 6 ntrial_dark*rasterheight],...
    'nextplot', 'add',...
    'xlim', [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'ylim', [-ntrial_dark-2 1], 'box', 'on');
yshift_row7    =      yshift_row6 + vspacing + ntrial_dark*rasterheight;
k=0;
ap_mat  = PSTH.Press.Dark.SpikeMat;
t_mat   = PSTH.Press.Dark.tSpikeMat;
hold_dur = PSTH.Press.Dark.HoldDuration;
% sort hold_dur
if by_time == 0
    [hold_dur, ind_sort] = sort(hold_dur);
    ap_mat = ap_mat(:, ind_sort);
end
[h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur);

xline(-PressTimeDomain(1), 'color', dark_color, 'linewidth', 2);
xline(0, 'color', press_col, 'linewidth', 1);
axis off
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Dark', ntrial_dark), 'corner', 'topleft');

% Dark release
n_press_types = size(PSTH.Release.Dark.SpikeMat, 2);
ntrial_dark = n_press_types;
ax = axes('unit', 'centimeters', ...
    'position', [x_release yshift_row6 width_release ntrial_dark*rasterheight],...
    'nextplot', 'add',...
    'xlim', xrange_release, 'ylim', [-ntrial_dark-2 1], 'box', 'on');
k=0;

ap_mat  = PSTH.Release.Dark.SpikeMat;
t_mat   = PSTH.Release.Dark.tSpikeMat;
hold_dur = PSTH.Release.Dark.HoldDuration;

% sort hold_dur
if by_time == 0
    [hold_dur, ind_sort] = sort(hold_dur);
    ap_mat = ap_mat(:, ind_sort);
end

[h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);

xline(-ReleaseTimeDomain(1), 'color', dark_color, 'linewidth', 2);
xline(0, 'color', press_col, 'linewidth', 1);
axis off

% this is the position of last panel
% Add information
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[0.5 yshift_row7 10 0.5], ...
    'String','A. Press/Release-related activity', ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',10, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');


switch r.Units.SpikeNotes(ku, 3)
    case 1
        type_unit = 'SU';
    case 2
        type_unit = 'MU';
    otherwise
end
if by_time == 0
    headerStr = sprintf('#%d | %s | %s', ku, PSTH.UnitID, type_unit);
else
    headerStr = sprintf('#%d | %s | %s | by time', ku, PSTH.UnitID, type_unit);
end
pos = [0.5 yshift_row7+0.6 14 0.5];
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',pos, ...
    'String',headerStr, ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',11, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');


%% B | Poke-related activity
x_poke = 13.5;
width_poke = 6*sum(RewardTimeDomain)/sum(PressTimeDomain);
xrange_poke = [-RewardTimeDomain(1) RewardTimeDomain(2)];

% Rewarded and omitted pokes:
ha_poke =  axes('unit', 'centimeters', ...
    'position', [x_poke yshift_row1 width_poke height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_poke, 'xtick', (-1000:1000:1000), 'xticklabelrotation', 0);
xlabel('Time from poke (ms)')
ylabel ('Spks per s')
types = {'Rewarded', 'Omitted'};
lines = {'-', ':'};

for i =1:length(types)
    itype = types{i};
    if strcmp(itype, 'Omitted') && isempty(glm_mdl)
        continue
    end
    t       = PSTH.Poke.(itype).tPSTH;
    ipsth   = PSTH.Poke.(itype).PSTH;
    plot(t, ipsth, 'color', 'k',  'linewidth', 1.5, 'linestyle', lines{i});
end

if ~isempty(glm_mdl)
    [bEvent,pEvent,bInt,pInt, str] = Spikes.extract_event_and_interaction(glm_mdl);
    text(ha_poke, 0.8, 1, str, ...
        'Units','normalized', ...
        'HorizontalAlignment','left', 'VerticalAlignment','top', ...
        'FontSize',7, 'FontWeight','bold', 'FontAngle', 'italic', ...
        'Color', 'r', ...
        'Interpreter','tex');   % or 'none' if you want literal characters
end

lockPsthAxis(ha_poke, FRMax, 0, reward_col);

ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Rew/Omit(dots)', 'corner', 'topleft');

yshift_row2 = yshift_row1+2+vspacing;
ha_poke_nonreward =  axes('unit', 'centimeters', ...
    'position', [x_poke yshift_row2 width_poke height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_poke, 'xticklabel', []);
t       = PSTH.Poke.Unrewarded.tPSTH;
ipsth   = PSTH.Poke.Unrewarded.PSTH;
plot(t, ipsth, 'color', [.6 .6 .6], ...
    'linewidth', 0.75, 'linestyle', '-');

lockPsthAxis(ha_poke_nonreward, FRMax, 0, reward_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Unrewarded', 'corner', 'topleft');

%% Make raster plot
% Rewarded trials
yshift_row3 = yshift_row2+height_psth+vspacing;

if by_time == 0
    n = length(PSTH.Poke.Rewarded.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_poke yshift_row3 width_poke n*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_poke, 'ylim', [-n-2 1], 'box', 'on');
    % Paint the foreperiod
    k=0;
    ap_mat          =       PSTH.Poke.Rewarded.SpikeMat;
    t_mat           =       PSTH.Poke.Rewarded.tSpikeMat;
    move_dur        =       PSTH.Poke.Rewarded.MovementDuration;
    more_pokes      =       PSTH.Poke.Rewarded.MorePokes;

    % sort hold_dur
    if by_time == 0
        [move_dur, ind_sort] = sort(move_dur);
        ap_mat = ap_mat(:, ind_sort);
        more_pokes = more_pokes(ind_sort);
    end
    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);

    % add more pokes
    Spikes.plotMoreTicks(ax, k0, more_pokes, 'b');

    line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('Rewarded (n=%d)', n), 'corner', 'topleft');
    axis off

    % Add Omitted trials
    yshift_row3 = yshift_row3+n*rasterheight+vspacing;
    n = length(PSTH.Poke.Omitted.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_poke yshift_row3 width_poke n*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_poke, 'ylim', [-n-2 1], 'box', 'on');
    yshift_row4 = yshift_row3+n*rasterheight+vspacing;

    % Paint the foreperiod
    k=0;
    ap_mat          =       PSTH.Poke.Omitted.SpikeMat;
    t_mat           =       PSTH.Poke.Omitted.tSpikeMat;
    move_dur        =       PSTH.Poke.Omitted.MovementDuration;
    more_pokes      =       PSTH.Poke.Omitted.MorePokes;

    % sort hold_dur
    if by_time == 0
        [move_dur, ind_sort] = sort(move_dur);
        ap_mat = ap_mat(:, ind_sort);
        more_pokes = more_pokes(ind_sort);
    end
    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);

    % add more pokes
    Spikes.plotMoreTicks(ax, k0, more_pokes, 'b');

    % sort hold_dur
    if by_time == 0
        [move_dur, ind_sort] = sort(move_dur);
        ap_mat = ap_mat(:, ind_sort);
    end

    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);
    line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('Omitted (n=%d)', n), 'corner', 'topleft');
    axis off

    % Add unrewarded trials
    n = length(PSTH.Poke.Unrewarded.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_poke yshift_row4 width_poke n*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_poke, 'ylim', [-n-2 1], 'box', 'on');

    yshift_row5 = yshift_row4+n*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    ap_mat  = PSTH.Poke.Unrewarded.SpikeMat;
    t_mat   = PSTH.Poke.Unrewarded.tSpikeMat;
    move_dur = PSTH.Poke.Unrewarded.MovementDuration;

    % sort hold_dur
    if by_time == 0
        [move_dur, ind_sort] = sort(move_dur);
        ap_mat = ap_mat(:, ind_sort);
    end

    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);
    line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('Unrewarded (n=%d)', n), 'corner', 'topleft');
    axis off

else
    n = length(PSTH.Poke.All.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_poke yshift_row3 width_poke n*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_poke, 'ylim', [-n-2 1], 'box', 'on');
    yshift_row5 = yshift_row3+n*rasterheight+vspacing;
    % Paint the foreperiod
    k=0;
    ap_mat          =       PSTH.Poke.All.SpikeMat;
    t_mat           =       PSTH.Poke.All.tSpikeMat;
    move_dur        =       PSTH.Poke.All.MovementDuration;

    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);

    line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('All (n=%d)', n), 'corner', 'topleft');
    axis off
end

% Add information
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[x_poke-0.5 yshift_row5 5 0.5], ...
    'String','B. Poke activity', ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'Color','k', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',10, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');

y_beh = yshift_row5+ 2; % this is for behavior data

%% C | Trigger-related activity
x_trigger = 20;
width_trigger = 3;
xrange_trigger = [-100 500];

ha_trigger =  axes('unit', 'centimeters', ...
    'position', [x_trigger yshift_row1 width_trigger height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_trigger, 'xtick', (0:200:400), ...
    'xticklabelrotation', 0);

% Plot correct trials
for i =1:nFPs
    field = sprintf('FP_%d', FPs(i));
    t       = PSTH.Trigger.(field).Correct.tPSTH;
    ipsth   = PSTH.Trigger.(field).Correct.PSTH;
    plot(t, ipsth, 'color', FP_cols(i, :),  'linewidth', 1.5);
end
xlabel('Time from trigger (ms)')
ylabel ('Spks per s')
lockPsthAxis(ha_trigger, FRMax, 0, trigger_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Correct', 'corner', 'topleft');

% Plot late trials
ha_trigger_late =  axes('unit', 'centimeters', ...
    'position', [x_trigger yshift_row2 width_trigger height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_trigger, 'xtick', (0:200:400), ...
    'xticklabelrotation', 0);
for i =1:nFPs
    field = sprintf('FP_%d', FPs(i));
    t       = PSTH.Trigger.(field).Late.tPSTH;
    ipsth   = PSTH.Trigger.(field).Late.PSTH;
    plot(t, ipsth, 'color', FP_cols(i, :),  'linewidth', 1.5, 'linestyle', '-.');
end
lockPsthAxis(ha_trigger_late, FRMax, 0, trigger_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Late', 'corner', 'topleft');

% Add raster plot now
yshift_row3 = yshift_row2+height_psth+vspacing;
% Plot spike raster of late trials (all FPs)
ntrials_trigger = 0;
nFP_i = zeros(1, nFPs);
for i =1:nFPs
    field = sprintf('FP_%d', FPs(i));
    nFP_i(i) = numel(PSTH.Trigger.(field).Correct.tEvents);
    ntrials_trigger = ntrials_trigger + nFP_i(i);
end

ax = axes('unit', 'centimeters', ...
    'position', [x_trigger yshift_row3 width_trigger ntrials_trigger*rasterheight],...
    'nextplot', 'add',...
    'xlim', xrange_trigger, ...
    'ylim', [-ntrials_trigger 1], 'box', 'on');
yshift_row4 = yshift_row3+ntrials_trigger*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nFPs
    field = sprintf('FP_%d', FPs(m));
    ap_mat = PSTH.Trigger.(field).Correct.SpikeMat;
    t_mat = PSTH.Trigger.(field).Correct.tSpikeMat;
    hold_dur = PSTH.Trigger.(field).Correct.HoldDuration;
    n_trial = size(ap_mat, 2);
    % sort hold_dur (if needed)
    if by_time == 0
        [hold_dur, ind_sort] = sort(hold_dur);
        ap_mat = ap_mat(:, ind_sort);
    end
    text(xrange_trigger(1)-200, -k-round(n_trial*0.5), sprintf('%1.0d ms (%1.0d)', FPs(m), n_trial), 'fontsize', 7)
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur-FPs(m));
end
xline(0, 'color', trigger_col, 'linewidth', 1);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, sprintf('Correct (n=%d)', ntrials_trigger), 'corner', 'topleft');
axis off

% Plot late trigger trials
ntrials_trigger = 0;
nFP_i = zeros(1, nFPs);
for i =1:nFPs
    field = sprintf('FP_%d', FPs(i));
    nFP_i(i) = numel(PSTH.Trigger.(field).Late.tEvents);
    ntrials_trigger = ntrials_trigger + nFP_i(i);
end

ax = axes('unit', 'centimeters', ...
    'position', [x_trigger yshift_row4 width_trigger ntrials_trigger*rasterheight],...
    'nextplot', 'add',...
    'xlim', xrange_trigger, ...
    'ylim', [-ntrials_trigger 1], 'box', 'on');
yshift_row5 = yshift_row4+ntrials_trigger*rasterheight+0.5;
% Paint the foreperiod
k=0;
for m =1:nFPs
    field = sprintf('FP_%d', FPs(m));
    ap_mat = PSTH.Trigger.(field).Late.SpikeMat;
    t_mat = PSTH.Trigger.(field).Late.tSpikeMat;
    hold_dur = PSTH.Trigger.(field).Late.HoldDuration;
    % sort hold_dur (if needed)
    if by_time == 0
        [hold_dur, ind_sort] = sort(hold_dur);
        ap_mat = ap_mat(:, ind_sort);
    end
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur-FPs(m));
end
xline(0, 'color', trigger_col, 'linewidth', 1);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, sprintf('Late (n=%d)', ntrials_trigger), 'corner', 'topleft');
axis off

% Add information
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[x_trigger-0.5 yshift_row5 5 0.5], ...
    'String','C. Trigger activity', ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'Color','k', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',10, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');

%% Plot behavior data on the top:
xnow = 13;
ynow = y_beh+1; % computed above
types = {'Probe', 'Dark'};
width_beh = 2;
height_beh = 2;
xrange = [r.EventTable.t_press(1)-1000*10 r.EventTable.t_press(end)+10*1000]/1000;
h_spacing = 0.25;
marker_size = 16;
tab = r.EventTable;
colors = struct('correct', '#628141', 'dark', '#1B211A', 'error', '#CF0F0F');

for i =1:length(types)
    indi = find(strcmp(tab.outcome, types{i}) | strcmp(tab.type, types{i}));
    if any(indi)
        ha_press_beh =  axes('unit', 'centimeters', ...
            'position', [xnow ynow width_beh height_beh], 'nextplot', 'add', ...
            'xlim', xrange, 'ylim', [0 3], 'xtick', (0:1000:3600), 'xticklabelrotation', 45);
        if i == 1
            ylabel('Hold duration (s)');
            xlabel('Time in a session (s)');
        else
            set(ha_press_beh, 'YTickLabel', []);
        end
        title(types{i}, 'fontsize', 9);
        xnow = xnow + width_beh + h_spacing;

        for k =1:length(indi)
            t_press_k       =   tab.t_press(indi(k))/1000;
            t_release_k     =   tab.t_release(indi(k))/1000;
            t_poke_k        =   tab.t_poke(indi(k))/1000;
            hold_dur        =   (t_release_k - t_press_k);
            move_dur        =   t_poke_k-t_release_k;
            outcome_k       =   tab.outcome{indi(k)};
            switch outcome_k
                case 'Correct'
                    scatter(ha_press_beh, t_press_k, hold_dur, 'MarkerFaceColor',colors.correct, 'MarkerEdgeColor', 'w', 'SizeData', marker_size);
                case {'Dark', 'NaN'}
                    scatter(ha_press_beh, t_press_k, hold_dur, 'MarkerFaceColor',colors.dark, 'MarkerEdgeColor', 'w', 'SizeData', marker_size);
                case {'Premature', 'Late'}
                    scatter(ha_press_beh, t_press_k, hold_dur, 'MarkerFaceColor',colors.error, 'MarkerEdgeColor', 'w', 'SizeData', marker_size);
                otherwise
                    scatter(ha_press_beh, t_press_k, hold_dur, 'MarkerFaceColor',colors.dark, 'MarkerEdgeColor', 'w', 'SizeData', marker_size);
            end
        end
    end
end

xnow = xnow +1;

for i =1:nFPs
    ha_press_beh =  axes('unit', 'centimeters', ...
        'position', [xnow ynow width_beh height_beh], 'nextplot', 'add', ...
        'xlim', xrange, 'ylim', [0 3], 'xtick', (0:1000:3600), 'xticklabelrotation', 45);
    if i > 1
        set(ha_press_beh, 'YTickLabel', []);
    else
        xlabel('Time (s)');
        ylabel('Hold duration (s)')
    end
    yline(ha_press_beh, MixedFPs(i)/1000, 'color', trigger_col, 'linestyle', '-.', 'linewidth', 2)
    title(sprintf('%.d ms', FPs(i)), 'fontsize', 9);
    xnow = xnow + width_beh + h_spacing;
    indi = find(strcmp(tab.type, 'Normal') & tab.FP == FPs(i));

    if any(indi)
        for k =1:length(indi)
            t_press_k       =   tab.t_press(indi(k))/1000;
            t_release_k     =   tab.t_release(indi(k))/1000;
            t_poke_k        =   tab.t_poke(indi(k))/1000;
            hold_dur        =   (t_release_k - t_press_k);
            move_dur        =   t_poke_k-t_release_k;
            outcome_k       =   tab.outcome{indi(k)};
            rew_history_k   =   tab.reward_level{indi(k)};

            % This marks the reward probability history
            switch rew_history_k
                case 'High'
                    line(ha_press_beh, [1 1]*t_press_k, [0 .5], 'color', 'k', 'linewidth', .5);
                case 'Low'
                    line(ha_press_beh, [1 1]*t_press_k, [0 0.25], 'color', [.75 .75 .75], 'linewidth', .5);
            end

            switch outcome_k
                case 'Correct'
                    scatter(ha_press_beh, t_press_k, hold_dur, 'MarkerFaceColor',colors.correct, 'MarkerEdgeColor', 'w', 'SizeData', marker_size);
                case {'Premature', 'Late'}
                    scatter(ha_press_beh, t_press_k, hold_dur, 'MarkerFaceColor',colors.error, 'MarkerEdgeColor', 'w', 'SizeData', marker_size);
            end
        end
    end
end

% Plot response density
ha_release_beh =  axes('unit', 'centimeters', ...
    'position', [xnow+1.25 ynow width_beh height_beh], 'nextplot', 'add', ...
    'xlim', [-1 1], 'ylim', [0 3],...
    'xtick', (-1:0.5:1), 'xticklabelrotation', 45);

plotshaded([.1 1], [0 0;10 10], [0 .8 .1])

% compute release time relative to FP
ind = tab.FP>1000;
release_time_corrected = 0.001*(tab.t_release(ind)-tab.t_press(ind)-tab.FP(ind));
release_time_corrected = release_time_corrected(release_time_corrected>-1 & release_time_corrected<3);
bin_size = 0.05;
bins = (-1:bin_size:3);
f_density = ksdensity(release_time_corrected, bins, 'Bandwidth',0.075);
hbar = bar(ha_release_beh, bins, f_density, 'facecolor', 'k');
ha_release_beh.YLim = [0 max(f_density)*1.1];
ha_release_beh.XTickLabelRotation = 0;
xline(0, 'color', trigger_col, 'linewidth', 1, 'linestyle', '-.');
% compute responses that are within [0.1 1]
integral = sum(f_density(bins>=0.1 & bins<=1))*bin_size;
total_mass = sum(f_density) * bin_size;
integral_norm = integral / total_mass;

% check sknewness
release_time_corrected_ = release_time_corrected(release_time_corrected>=-1 & release_time_corrected<=3);
sk = skewness(release_time_corrected_);

% fit the curve with a Gaussian model
f_density_ = f_density;
bins_ = bins;
gauss_fun = @(p, x) normpdf(x, p(1), p(2));
mu0 = bins(f_density_ == max(f_density_));  % initial guess at peak
sigma0 = 0.3;
p0 = [mu0(1), sigma0];
opts = optimoptions('lsqcurvefit','Display','off');
p_hat = lsqcurvefit( ...
    gauss_fun, p0, bins_, f_density_, ...
    [min(bins), 0], [max(bins), Inf], opts);
mu_hat    = p_hat(1);
sigma_hat = p_hat(2);

g_fit = normpdf(bins, mu_hat, sigma_hat);
g_fit = g_fit / sum(g_fit * bin_size);

eps_val = 1e-10;

% compute kl divergence
KL = sum(f_density .* log((f_density + eps_val) ./ (g_fit + eps_val))) * bin_size;

plot(ha_release_beh, bins, g_fit, 'r', 'linewidth', 1.5)

sse = sum((f_density - g_fit).^2);

s = sprintf('integral=%2.2f\nsigma=%2.2fs\nmu=%2.2fs',...
    integral_norm, sigma_hat, mu_hat);

% ynow width_beh height_beh
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[xnow+1 ynow+height_beh+0.5 width_beh+0.25 .75], ...
    'String',s, ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',8, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle');

xlabel('Time since cue (s)')
ylabel('Density')

%% Look at reward probability modulation or error trials
xnow = 1.25;
ynow = 5.5;

% Press
yshift_row1 = ynow;
vspacing2 = 2;
hspacing2 = 1.5;
height_psth = 2;
width_press = 3;
press_range = [-500 500];
tick_color = [.7 .7 .7];
n_low = length(PSTH.Press.Low.tEvents);

if n_low >10
    types = {'High', 'Low'};
    line_styles = {'-', ':'};
    annotation('textbox', ...
        'Units', 'centimeters', ... % Set units to centimeters
        'Position', [1, ynow+height_psth+0.5, 8, 0.7], ... % Normalize to figure units
        'String', 'High (—) vs Low (⋯) reward history', ...
        'Interpreter', 'none', ... % Prevent underscores from being treated as subscripts
        'BackgroundColor', 'w', ... % White background
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontName', 'DejaVu Sans', ... % Note: MATLAB uses 'DejaVu Sans' (case-sensitive)
        'EdgeColor', 'none'); % No border, similar to uicontrol default
else
    types = {'High'};
    line_styles = {'-'};
    annotation('textbox', ...
        'Units', 'centimeters', ... % Set units to centimeters
        'Position', [1, ynow+height_psth+0.5, 8, 0.7], ... % Normalize to figure units
        'String', 'Release: Correct (—) vs Error (...)', ...
        'Interpreter', 'none', ... % Prevent underscores from being treated as subscripts
        'BackgroundColor', 'w', ... % White background
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontName', 'DejaVu Sans', ... % Note: MATLAB uses 'DejaVu Sans' (case-sensitive)
        'EdgeColor', 'none'); % No border, similar to uicontrol default
end

ha_press_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow yshift_row1 width_press height_psth], ...
    'nextplot', 'add', 'xlim', press_range, 'color', 'none');
xlabel('Time from press (ms)')
ylabel ('Spks per s')
yshift_row2 = yshift_row1-height_psth-vspacing2;

% add overlaid spikes
n = 20;
pos = ha_press_psth_rew.Position;
ax =  axes('unit', 'centimeters', ...
    'position', pos, ...
    'nextplot', 'add', 'xlim', press_range, ...
    'ylim', [-2*n 0], 'color', 'none', 'yaxislocation', 'right');
k = 0;
for i =1:length(types)
    type = types{i};
    t       = PSTH.Press.(type).tSpikeMat;
    spk   = PSTH.Press.(type).SpikeMat;
    spk = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color);
end
axis off

for i =1:length(types)
    type = types{i};
    t       = PSTH.Press.(type).tPSTH;
    ipsth   = PSTH.Press.(type).PSTH;
    plot(ha_press_psth_rew, t, ipsth, 'color', 'r',  'linewidth', 1.5, 'linestyle', line_styles{i});
end
lockPsthAxis(ha_press_psth_rew, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Press', 'corner', 'topleft');

% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_press_psth_rew,'top'); % make explicit

% Trigger
height_psth = 2;
width_press = 3;
trigger_range = [-100 500];
ha_trigger_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow yshift_row2 width_press height_psth], ...
    'nextplot', 'add', 'xlim', trigger_range, 'color', 'none');
xlabel('Time from trigger (ms)')
ylabel ('Spks per s')
% add overlaid spikes
n = 20;
pos = ha_trigger_psth_rew.Position;
ax =  axes('unit', 'centimeters', ...
    'position', pos, ...
    'nextplot', 'add', 'xlim', trigger_range, 'ylim', [-2*n 0], 'color', 'none');
k = 0;
for i =1:length(types)
    type = types{i};
    t       = PSTH.Trigger.(type).tSpikeMat;
    spk   = PSTH.Trigger.(type).SpikeMat;
    spk = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color);
end
axis off

for i =1:length(types)
    type = types{i};
    t       = PSTH.Trigger.(type).tPSTH;
    ipsth   = PSTH.Trigger.(type).PSTH;
    plot(ha_trigger_psth_rew, t, ipsth, 'color', 'r',  'linewidth', 1.5, 'linestyle', line_styles{i});
end
lockPsthAxis(ha_trigger_psth_rew, FRMax, 0, trigger_col);

ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Trigger', 'corner', 'topleft');
% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_trigger_psth_rew,'top'); % make explicit

if n_low >10
    types_ = {'High', 'Low'};
    line_styles_ = {'-', ':'};
    colors = {'r', 'r'};
else
    types_ = {'Rewarded', 'Unrewarded'};
    line_styles_ = {'-', '-'};
    colors = {'r', 'c'};
end

% Release
height_psth = 2;
width_press = 3;
release_range = [-250 1000];
ha_release_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow+width_press+hspacing2 yshift_row1 width_press height_psth], ...
    'nextplot', 'add', 'xlim', release_range, 'color', 'none');
xlabel('from release (ms)')
ylabel ('Spks per s')

% add overlaid spikes
n = 20;
pos = ha_release_psth_rew.Position;
ax =  axes('unit', 'centimeters', ...
    'position', pos, ...
    'nextplot', 'add', 'xlim', release_range, 'ylim', [-2*n 0], 'color', 'none');
k = 0;

for i =1:length(types_)
    type = types_{i};
    t       = PSTH.Release.(type).tSpikeMat;
    spk   = PSTH.Release.(type).SpikeMat;
    spk = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color/i);
end
axis off

for i =1:length(types_)

    type = types_{i};
    t       = PSTH.Release.(type).tPSTH;
    ipsth   = PSTH.Release.(type).PSTH;
    plot(ha_release_psth_rew, t, ipsth, 'color', colors{i},  'linewidth', 2, ...
        'linestyle', line_styles_{i});

end
lockPsthAxis(ha_release_psth_rew, FRMax, 0, release_col);
h = addAxisCornerLabel(ax, 'Release (correct[r] vs error[c])', 'corner', 'topleft');
% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_release_psth_rew,'top'); % make explicit

% Poke
height_psth = 2;
width_press = 3;
poke_range = [-1000 500];
ha_poke_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow+width_press+hspacing2 yshift_row2 width_press height_psth], ...
    'nextplot', 'add', 'xlim', poke_range, 'color', 'none');
xlabel('from poke (ms)')
ylabel ('Spks per s')

% add overlaid spikes
n = 20;
pos = ha_poke_psth_rew.Position;
ax =  axes('unit', 'centimeters', ...
    'position', pos, ...
    'nextplot', 'add', 'xlim', poke_range, 'ylim', [-2*n 0], 'color', 'none');
k = 0;
for i =1:length(types)

    type = types{i};
    t       = PSTH.Poke.(type).tSpikeMat;
    spk   = PSTH.Poke.(type).SpikeMat;
    spk = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color);

end
axis off

for i =1:length(types)
    type = types{i};
    t       = PSTH.Poke.(type).tPSTH;
    ipsth   = PSTH.Poke.(type).PSTH;
    plot(ha_poke_psth_rew, t, ipsth, 'color', 'r',  'linewidth', 1.5, 'linestyle', line_styles{i});
end
lockPsthAxis(ha_poke_psth_rew, FRMax, 0, reward_col);
h = addAxisCornerLabel(ax, 'Poke', 'corner', 'topleft');
% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_poke_psth_rew,'top'); % make explicit

%% plot pre-press activity vs trial num or time
xnow = 10.5;
ynow = 2;

t_presses = PSTH.Press.All.tEvents/1000;
ha10=axes('unit', 'centimeters', 'position', [xnow ynow 3 3], ...
    'nextplot', 'add', 'xlim', [min(t_presses) max(t_presses)]);
ind_prepress    = find(PSTH.Press.All.tSpikeMat<0);
spkmat_prepress =  PSTH.Press.All.SpikeMat(ind_prepress, :);
t_count = PSTH.Press.All.tSpikeMat(ind_prepress);

dur_prepress = abs(t_count(end)-t_count(1))/1000; % total time
rate_prepress = sum(spkmat_prepress, 1)/dur_prepress; % spk rate across time

% t_presses, rate_prepress are vectors (same length)
x = t_presses(:);
y = rate_prepress(:);

% (optional) remove NaNs
ok = isfinite(x) & isfinite(y);
x = x(ok);
y = y(ok);

% Fit linear model: y = b0 + b1*x
mdl = fitlm(x, y);

% Extract slope (beta) and p-value for the slope term
beta = mdl.Coefficients.Estimate(2);   % slope
pval = mdl.Coefficients.pValue(2);     % p-value for slope
r2   = mdl.Rsquared.Ordinary;
scatter(ha10, x, y, 12, 'filled');

% Plot fitted line
xdata = linspace(min(x), max(x), 200)';
yhat  = predict(mdl, xdata);
plot(xdata, yhat, 'LineWidth', 2, 'color', 'r');

xlabel('Time in session (s)')
ylabel('Pre-press spiking rate (hz)')
% Show the model on the plot
xl = ha10.XLim; yl = ha10.YLim;
stats_str = sprintf('\\beta = %.3g\np = %.3g\nR^2 = %.3g', beta, pval, r2);

text(xl(1) + 0.03*range(xl), yl(2) + 0.4*range(yl), stats_str, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','top', ...
    'FontSize', 10, 'FontWeight', 'bold');

annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[xnow-0.5 ynow+5.5 4 0.5], ...
    'String','Activity vs time', ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'Color','k', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',10, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle');

%% Add spike information
xnow = 14;
ynow = 5.5;

thiscolor = [0 0 0];
Lspk = size(r.Units.SpikeTimes(ku).wave, 2);
% this is spike waveform
ha0=axes('unit', 'centimeters', 'position', [xnow ynow 1.25 2], ...
    'nextplot', 'add', 'xlim', [0 Lspk], 'ytick', -500:100:200, 'xticklabel', []);
set(ha0, 'nextplot', 'add');
ylabel('uV')
allwaves = r.Units.SpikeTimes(ku).wave/4;
if size(allwaves, 1)>100
    nplot = randperm(size(allwaves, 1), 100);
else
    nplot=1:size(allwaves, 1);
end
wave2plot = allwaves(nplot, :);
plot(1:Lspk, wave2plot, 'color', [0.8 .8 0.8]);
plot(1:Lspk, mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)
axis([0 Lspk min(wave2plot(:)) max(wave2plot(:))])
set (gca, 'ylim', [min(mean(allwaves, 1))*1.25 max(mean(allwaves, 1))*1.25])
axis tight
line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
PSTH.SpikeWave = mean(allwaves, 1);
% plot autocorrelation
kutime = round(r.Units.SpikeTimes(ku).timings);
kutime2 = zeros(1, max(kutime));
kutime2(kutime)=1;
[c, lags] = xcorr(kutime2, 100); % max lag 100 ms
c(lags==0)=0;
%% Here we compute inter-spike interval violation
out = Spikes.isi_violation_metrics(kutime);  % compute only
%%
ha00= axes('unit', 'centimeters', ...
    'position', [xnow+2.5 ynow 2.2 2], 'nextplot', 'add', 'xlim', [-20 20]);
if median(c)>1
    set(ha00, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 median(c)]);
else
    set(ha00, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 1], 'ylim', [0 1]);
end

PSTH.AutoCorrelation = {lags, c};
hbar = bar(lags, c);
set(hbar, 'facecolor', 'k');
xlabel('Lag(ms)')

xnow_aligned = xnow; % for channel location data

xnow  = xnow + 5.5;
ha000= axes('unit', 'centimeters', ...
    'position', [xnow 5.5 5 1.5], ...
    'nextplot', 'add', 'xlim', [0 10], 'ylim', [0 10]);

stats_str = sprintf(['Raw ISI<%.1fms: %.3f%% (n_v=%d)\n' ...
    'Corrected: %.4f (%.3f%%)\n' ...
    'N=%d, T=%.2fs, FR=%.2f Hz'], ...
    3, out.raw_isi_violation_pct, out.n_v, ...
    out.corrected_ratio, out.corrected_pct, ...
    out.N, out.T, out.fr);

xl = [0 10]; yl = [0 10];
text(ha000, xl(1), yl(2)+1.5, stats_str, ...
    'HorizontalAlignment','left', 'VerticalAlignment','top', ...
    'FontSize', 10, 'Interpreter','none');
axis off


headerStr = sprintf('#%d | %s | %s', ku, PSTH.UnitID, type_unit);

annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[xnow-7 ynow+2.5 10 0.7], ...
    'String',headerStr, ...
    'Interpreter','none', ...
    'FitBoxToText','off', ...
    'BackgroundColor','w', ...
    'EdgeColor','none', ...
    'FontName','DejaVu Sans', ...
    'FontWeight','bold', ...
    'FontSize',11, ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

ynow = 0.5;

% Plot all waveforms if it is a polytrode
if isfield(r.Units.SpikeTimes(ku), 'wave_mean')
  
    ha_wave_poly = axes('unit', 'centimeters', 'position', ...
            [xnow+0.5 ynow 4 5], ...
            'nextplot', 'add');
    if ~isfield(r, 'PixelTable') % plot neuropixels spikes later 
        wave_form = r.Units.SpikeTimes(ku).wave_mean/4;
        wave_mean=mean(wave_form(:));
        wave_sd = std(wave_form(:));

        wave_form_z = (wave_form-wave_mean)/wave_sd;

        PSTH.SpikeWaveMean = wave_form;
        n_chs = size(wave_form, 1); % number of channels
        n_sample = size(wave_form, 2); % sample size per spike

        n_cols = 8;
        n_rows = n_chs/n_cols;
        max_x = 0;
        colors = [25, 167, 206]/255;
        if n_rows<1
            n_rows=1;
        end
        v_sep = 2;

        t_wave_all = [];
        t_wave_all_weak = [];
        wave_all = [];
        wave_all_weak = [];
        threshold = quantile(max(abs(wave_form_z), [], 2), 0.95);

        for i =1:n_rows
            for j=1:n_cols
                k = j+(i-1)*n_cols;
                max_amp = max(abs(wave_form_z(k, :)));
                if max_amp >threshold
                    wave_k = wave_form_z(k, :)+v_sep*(i-1);
                    t_wave = (1:n_sample)+n_sample*(j-1)+4;
                    t_wave_all = [t_wave_all, t_wave, NaN];
                    wave_all = [wave_all, wave_k, NaN];
                    max_x = max([max_x, max(t_wave)]);
                else
                    wave_k = wave_form_z(k, :)+v_sep*(i-1);
                    t_wave = (1:n_sample)+n_sample*(j-1)+4;
                    t_wave_all_weak = [t_wave_all_weak, t_wave, NaN];
                    wave_all_weak = [wave_all_weak, wave_k, NaN];
                    max_x = max([max_x, max(t_wave)]);
                end
            end
        end
        plot(ha_wave_poly, t_wave_all, wave_all, 'linewidth', 1, 'color', colors);
        plot(ha_wave_poly, t_wave_all_weak, wave_all_weak, 'linewidth', 0.2, 'color', [.75 .75 .75]);

        set(ha_wave_poly, 'xlim', [0 max_x], 'ylim', [-20  v_sep*(n_rows-1)+20]);
        axis off
        axis tight
    end

    yshift_row7 = yshift_row6+3;
else
    yshift_row7 = yshift_row6;
end

%% --- Uniform y-lims for all PSTH axes
% psthAxes = [ ...
%     ha_press_psth, ha_release_psth, ...
%     ha_press_psth_probe, ha_release_psth_probe, ...
%     ha_press_psth_error, ha_release_psth_error, ...
%     ha_press_psth_dark, ha_release_psth_dark, ...
%     ha_poke, ha_poke_nonreward, ...
%     ha_trigger, ha_trigger_late, ...
%     ha_press_psth_rew, ha_release_psth_rew, ha_trigger_psth_rew, ha_poke_psth_rew ...
% ];
% 
% % keep only valid handles (in case some panels were skipped)
% psthAxes = psthAxes(isgraphics(psthAxes, 'axes'));
% 
% % choose a global max (use FRMax you already tracked)
% Ymax = FRMax;
% if isempty(Ymax) || ~isfinite(Ymax) || Ymax <= 0
%     Ymax = 10; % fallback
% end
% Ymax = ceil(1.10 * Ymax); % 10% headroom, round up
% 
% if strcmpi(UniformPSTHYLim, 'on')
%     if ~isempty(PSTHYLim)
%         set(psthAxes, 'YLim', PSTHYLim, 'YLimMode', 'manual');
%     else
%         set(psthAxes, 'YLim', [0 Ymax], 'YLimMode', 'manual');
%     end
% end
%% Add unit location information for Neuropixels recordings
if isfield(r, 'PixelTable')
    xnow = xnow_aligned+2;
    ynow = 1.25;

    % plot all sites;
    ha_sites = axes('unit', 'centimeters', 'position', ...
        [xnow ynow 2, 2.5], ...
        'nextplot', 'add');

    marker_size = 10;
    x= r.ChanMap.xcoords;
    y= r.ChanMap.ycoords;
    scatter(x, y, 's', 'SizeData', marker_size, 'MarkerFaceColor', [.5 .5 .5], ...
        'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none')
    this_row = r.PixelTable(strcmp(r.PixelTable.unit, PSTH.UnitID), :);

    x_nearby    = [this_row.x; this_row.nearby_x{1}];
    y_nearby    = [this_row.y; this_row.nearby_y{1}];
    amp_nearby  = [this_row.amp; this_row.nearby_amp{1}];

    a = amp_nearby(:);
    xx = x_nearby(:);
    yy = y_nearby(:);

    sz = a - min(a);
    if all(sz == 0)
        sz = ones(size(sz));          % avoid zero-variance case
    else
        sz = normalize(sz, 'range');  % 0..1
    end
    sz = sz*marker_size + 5;          % pixel-ish marker area scaling

    scatter(ha_sites, xx, yy, sz, a, 'o', 'filled', ...
        'MarkerEdgeColor','k', 'LineWidth',0.5);   % or 'none' if you prefer
    set(ha_sites, 'xlim', [min(x_nearby)-50 max(x_nearby)+50])
    scatter(ha_sites, this_row.x, this_row.y, '^', ...
        'SizeData', 60, 'MarkerFaceColor','m');

    xlabel('x (um)')
    ylabel('y (um)')
    ax = ha_sites;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, 'Unit location', 'corner', 'topleft');

    all_waves = r.Units.SpikeTimes(ku).wave_mean/4;
    % Plot waveform to the right:

    cla(ha_wave_poly);
    axes(ha_wave_poly);
    set(ha_wave_poly, 'next', 'add', 'xlim',[min(x_nearby)-20 max(x_nearby)+20], ...
        'ylim', [min(y) max(y)])

    for i =1:length(xx)
        plotshaded(xx(i)+[-2.5 2.5], [yy(i)-2.5 yy(i)-2.5;yy(i)+2.5 yy(i)+2.5], ...
            [148, 180, 193]/255)
    end

    wave_scale = 200;
    ymin = [];
    ymax = [];
    for i =1:length(xx)
        ind_spike = find(x==xx(i) & y == yy(i));
        this_wave = all_waves(ind_spike, :);
        text(ha_wave_poly, xx(i)-10, yy(i)-2, ...
            sprintf('%d', r.ChanMap.chanMap(ind_spike)), 'fontsize', 7, 'color', 'r')
        % normalize this_wave
        this_wave = wave_scale*this_wave/max(this_row.amp);
        plot(ha_wave_poly, ((1:length(this_wave))-0.5*length(this_wave))*0.5+xx(i), ...
            this_wave+yy(i), 'k', 'linewidth', 1);

        if isempty(ymin)
            ymin = min(this_wave+yy(i));
            ymax = max(this_wave+yy(i));

        else
            ymin = min(ymin, min(this_wave+yy(i)));
            ymax = max(ymax, max(this_wave+yy(i)));
        end
    end
    set(ha_wave_poly, 'ylim', [ymin-10 ymax+10])
end


%%
styleAllAxesInFigurePSTH(hf);

% save to a folder
anm_name             =     r.BehaviorClass.Subject;
session              =     r.BehaviorClass.Date;

PSTH.ISI = out;
PSTH.ANM_Session = {anm_name, session};

thisFolder = fullfile(pwd, 'Fig');
if ~exist(thisFolder, 'dir')
    mkdir(thisFolder)
end
tosavename2= fullfile(thisFolder, PSTH.UnitID);
save([tosavename2 '.mat'], 'PSTH');

% if by_time == 1
%     print (gcf,'-dpng', [tosavename2 '_byTime']);
% else
%     print (gcf,'-dpng', tosavename2);
% end
fig = figure(hf);
if by_time == 1
    fn = [tosavename2 '_byTime.png'];
else
    fn = [tosavename2 '.png'];
end

exportgraphics(fig, fn, 'Resolution', 150);  % 150 dpi is a good paper default

end

function lockPsthAxis(ax, FRMax, x0, x0color)
    ylim(ax, [0 FRMax]);
    box(ax,'off');
    if nargin >= 3 && ~isempty(x0)
        xline(ax, x0, 'Color', x0color, 'LineWidth', 1);
    end
end
