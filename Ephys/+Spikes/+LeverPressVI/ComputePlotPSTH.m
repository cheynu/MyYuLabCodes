function PSTH = ComputePlotPSTH(r, ku, varargin)
%   Jianing Yu, 2023-05-08
%   Yue Huang, 2023-06-26 (faster raster plotting)
%   Updated 2025-12-18 (reward probability / reward history structure)
%   LeverPressVI version, Yu Chen, 2026-02

PSTH.UnitID = sprintf('%s_%s_Ch%d_Unit%d', r.BehaviorClass.Subject, r.BehaviorClass.Date, r.Units.SpikeNotes(ku, 1), r.Units.SpikeNotes(ku, 2));

ToSave = 'on';
by_rank = 0;
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
            case 'by_rank'
                by_rank = varargin{i+1};
            case 'ToSave'
                ToSave = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
end

% For PSTH and raster plots
% color
cBlack = [0 0 0];
cWhite = [1 1 1];
cTab10 = [  0.090196078431373	0.466666666666667	0.701960784313725
            0.960784313725490	0.498039215686275	0.137254901960784
            0.152941176470588	0.631372549019608	0.278431372549020
            0.843137254901961	0.149019607843137	0.172549019607843
            0.564705882352941	0.403921568627451	0.674509803921569
            0.549019607843137	0.337254901960784	0.290196078431373
            0.847058823529412	0.474509803921569	0.698039215686275
            0.501960784313726	0.501960784313726	0.501960784313726
            0.737254901960784	0.745098039215686	0.196078431372549
            0.113725490196078	0.737254901960784	0.803921568627451];
cBlue = 'b'; %cTab10(1,:);
cOrange = cTab10(2,:);
cGreen = 'g'; %cTab10(3,:);
cRed = cTab10(4,:);
cPurple = cTab10(5,:);
cBrown = cTab10(6,:);
cPink = cTab10(7,:);
cGray = cTab10(8,:);
cYellow = cTab10(9,:);
cCyan = cTab10(10,:);
cBlueMatlab = [0.0660 0.4430 0.7450];

press_col = [5 191 219]/255;
trigger_col = [242 182 250]/255;
release_col = [87, 108, 188]/255;
reward_col = [164, 208, 164]/255;

good_col = [0 0 0];
bad_col = [0.9 0.4 0.1];
late_col = [0.6 0.6 0.6];
% rank_cols = [167, 39, 3; 252, 181, 59; 255, 231, 151;132, 153, 79]/255;
rank_cols = [167, 39, 3; 252, 181, 59; 132, 153, 79]/255;
printsize = [0.5 2 25 30];
%% PSTHs for press and release
params_press.pre        = 5000; % take a longer pre-press activity so we can compute z score easily later.
params_press.post       = PressTimeDomain(2);
params_press.binwidth   = 20;

% All presses (this is used for computing pre-press activity versus time)
% Prepare all presses
t_presses   =   r.EventTable.t_press;
t_releases  =   r.EventTable.t_release;
hold_dur    =   t_releases - t_presses;
press_rank  =   r.EventTable.press_rank;

[psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_presses, params_press);
psth_press = smoothdata(psth_press, 'gaussian', 5);
PSTH.Press.All.tPSTH        = ts_press;
PSTH.Press.All.PSTH         = psth_press;
PSTH.Press.All.tSpikeMat    = tspkmat_press;
PSTH.Press.All.SpikeMat     = trialspxmat_press;
PSTH.Press.All.tEvents      = t_presses;
PSTH.Press.All.HoldDuration = hold_dur(ind_);
PSTH.Press.All.PressRank    = press_rank(ind_);

params_release.pre          = ReleaseTimeDomain(1);
params_release.post         = ReleaseTimeDomain(2);
params_release.binwidth     = 20;

[psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
    t_releases, params_release);
psth_release = smoothdata(psth_release, 'gaussian', 5);
PSTH.Release.All.tPSTH            =           ts_release;
PSTH.Release.All.PSTH             =           psth_release;
PSTH.Release.All.tSpikeMat        =           tspkmat_release;
PSTH.Release.All.SpikeMat         =           trialspxmat_release;
PSTH.Release.All.tEvents          =           t_releases;
PSTH.Release.All.HoldDuration     =           hold_dur(ind_);
PSTH.Release.All.PressRank        =           press_rank(ind_);

% Press/release PSTH (rank x outcome)
ranks = unique(r.EventTable.press_rank);
nRanks = length(ranks);
rankBoundry = findBestCut(r.EventTable.press_rank);
iGroupRank = {1:rankBoundry(1),...
              rankBoundry(1)+1:rankBoundry(2),...
              rankBoundry(2)+1:nRanks};
nGroupRanks = length(iGroupRank);
beh_outcome = {'Good','Bad'};

typesPressRelease = {'Rank_Low','Rank_Mid','Rank_High'};
for i=0:nGroupRanks
    if i==0
        type_ = 'Rank_All';
    else
        type_ = typesPressRelease{i};
    end
    PSTH.Press.(type_)      = struct('Good', [], 'Bad', []);
    PSTH.Release.(type_)    = struct('Good', [], 'Bad', []);

    for j=1:length(beh_outcome)       
        outcome_    = beh_outcome{j};
        % Press times of this kind (this rank and this outcome)
        if i==0
            ind = strcmp(r.EventTable.outcome, outcome_);
        else
            ind = ismember(r.EventTable.press_rank, iGroupRank{i}) & strcmp(r.EventTable.outcome, outcome_);
        end
        t_presses   = r.EventTable.t_press(ind);
        t_releases  = r.EventTable.t_release(ind);
        hold_dur    = t_releases - t_presses;
        press_rank  = r.EventTable.press_rank(ind);
        [psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
            t_presses, params_press);
        psth_press = smoothdata(psth_press, 'gaussian', 5);
        PSTH.Press.(type_).(outcome_).tPSTH           =   ts_press;
        PSTH.Press.(type_).(outcome_).PSTH            =   psth_press;
        PSTH.Press.(type_).(outcome_).tSpikeMat       =   tspkmat_press;
        PSTH.Press.(type_).(outcome_).SpikeMat        =   trialspxmat_press;
        PSTH.Press.(type_).(outcome_).tEvents         =   t_presses;
        PSTH.Press.(type_).(outcome_).HoldDuration    =   hold_dur(ind_);
        PSTH.Press.(type_).(outcome_).PressRank       =   press_rank(ind_);
        
        [psth_release, ts_release, trialspxmat_release, tspkmat_release, t_releases, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
            t_releases, params_release);
        psth_release = smoothdata(psth_release, 'gaussian', 5);
        PSTH.Release.(type_).(outcome_).tPSTH           =   ts_release;
        PSTH.Release.(type_).(outcome_).PSTH            =   psth_release;
        PSTH.Release.(type_).(outcome_).tSpikeMat       =   tspkmat_release;
        PSTH.Release.(type_).(outcome_).SpikeMat        =   trialspxmat_release;
        PSTH.Release.(type_).(outcome_).tEvents         =   t_releases;
        PSTH.Release.(type_).(outcome_).HoldDuration    =   hold_dur(ind_);
        PSTH.Release.(type_).(outcome_).PressRank       =   press_rank(ind_);
    end
end

% Specifically design bad_stay / bad_switch / good_switch release
types = {'Bad_Stay', 'Bad_Switch', 'Good_Switch'};

for i =1:length(types)
    itype = types{i};
    switch itype
        case 'Bad_Stay'
            ind = strcmp(r.EventTable.outcome, 'Bad') & r.EventTable.is_stay;
        case 'Bad_Switch'
            ind = strcmp(r.EventTable.outcome, 'Bad') & strcmp(r.EventTable.reward,'Bad');
        case 'Good_Switch'
            ind = strcmp(r.EventTable.outcome, 'Good') & ~r.EventTable.is_stay;
    end

    t_presses   =   r.EventTable.t_press(ind);
    t_releases  =   r.EventTable.t_release(ind);
    hold_dur    =   t_releases - t_presses;

    [psth_press, ts_press, trialspxmat_press, tspkmat_press, t_presses, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
            t_presses, params_press);
    psth_press = smoothdata(psth_press, 'gaussian', 5);
    PSTH.Press.(itype).tPSTH           =   ts_press;
    PSTH.Press.(itype).PSTH            =   psth_press;
    PSTH.Press.(itype).tSpikeMat       =   tspkmat_press;
    PSTH.Press.(itype).SpikeMat        =   trialspxmat_press;
    PSTH.Press.(itype).tEvents         =   t_presses;
    PSTH.Press.(itype).HoldDuration    =   hold_dur(ind_);
        
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

% here i also compute the recent-reward vs distant-reward history
% Press/release PSTH
params_press_.pre           = 2000; % take a longer pre-press activity so we can compute z score easily later.
params_press_.post          = 500;
params_press_.binwidth      = 20;

params_release_.pre         = 500;
params_release_.post        = 500;
params_release_.binwidth    = 20;

types = {'Recent','Distant'};
prcThre = [40 60];
thres_reward_history = [prctile(r.EventTable.time_from_last_reward,prcThre)]; % recent reward history / distant reward history
for j =1:length(types)
    type_ = types{j};
    switch type_
        case 'Recent'
            ind = r.EventTable.time_from_last_reward<=thres_reward_history(1)...
                & ~isnan(r.EventTable.t_poke_first)...
                & strcmp(r.EventTable.outcome, 'Good');
        case 'Distant'
            ind = r.EventTable.time_from_last_reward>=thres_reward_history(2)...
                & ~isnan(r.EventTable.t_poke_first)...
                & strcmp(r.EventTable.outcome, 'Good');
    end

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
end

%% Poke-related activity (this might be complicated)
% Note that in
% use t_reward_poke and move_time to construct reward_poke PSTH
% reward PSTH
params_poke.pre             =       RewardTimeDomain(1);
params_poke.post            =       RewardTimeDomain(2);
params_poke.binwidth        =       20;

poke_types = {'Rewarded', 'Omitted', 'Bad', 'All'};
% Rewarded: rewarded poke following a correct (good) response
% Omitted: correct (good) response, but not rewarded
% Bad: poke after incorrect (bad) responses

spk_table = table;
pre_poke_win = 500; % pre-poke window
post_poke_win = 500;

PSTH.Poke = struct('Rewarded', [], 'Omitted', [], 'Bad', [], 'All', []);
for j=1:length(poke_types)
    j_poke_type = poke_types{j};
    % look for index
    switch j_poke_type
        case 'Rewarded'
            ind = ~isnan(r.EventTable.t_poke_first) & strcmp(r.EventTable.reward, 'Rewarded');
        case 'Bad'
            ind = ~isnan(r.EventTable.t_poke_first) & strcmp(r.EventTable.reward, 'Bad');
        case 'Omitted'
            ind = ~isnan(r.EventTable.t_poke_first) & strcmp(r.EventTable.reward, 'Omitted');
        case 'All'
            ind = ~isnan(r.EventTable.t_poke_first);
    end

    if ~isempty(ind)
        t_poke              =       r.EventTable.t_poke_first(ind);
        t_portout           =       r.EventTable.t_port_exit(ind);
        t_releases          =       r.EventTable.t_release(ind);
        move_dur            =       t_poke - t_releases;
        port_dur            =       t_portout - t_poke;

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
        PSTH.Poke.(j_poke_type).PortDuration       =   port_dur(ind_);

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
if any(strcmp(spk_table.RewardType, 'Omitted')) && sum(strcmp(spk_table.RewardType, 'Omitted'))>5 && any(strcmp(spk_table.RewardType, 'Rewarded')) && sum(strcmp(spk_table.RewardType, 'Rewarded'))>5
    tbl = spk_table;
    % make types consistent
    tbl.RewardType = categorical(string(tbl.RewardType));
    tbl.RewardType = reordercats(tbl.RewardType, {'Rewarded', 'Omitted'});  % pick your baseline
    
    % Here is a GLM model to model spk number
    % add trial id (pairing index)
    tbl.Trial = (1:height(tbl))';
    
    % long format
    long = stack(tbl, {'Pre','Post'}, ...
        'NewDataVariableName','SpkNum', ...
        'IndexVariableName','Event');
    
    long.Event = categorical(long.Event, {'Pre','Post'}); % baseline Pre
    long.RewardType = categorical(string(long.RewardType));
    long.RewardType = reordercats(long.RewardType, {'Rewarded','Omitted'}); % baseline Rewarded
    glm_mdl = fitlm(long, 'SpkNum ~ Event*RewardType');
end


types = {'Recent','Distant'};
prcThre = [40 60];
thres_reward_history = [prctile(r.EventTable.time_from_last_reward,prcThre)]; % recent reward history / distant reward history
for j =1:length(types)
    type_ = types{j};
    switch type_
        case 'Recent'
            ind = r.EventTable.time_from_last_reward<=thres_reward_history(1)...
                & ~isnan(r.EventTable.t_poke_first)...
                & strcmp(r.EventTable.outcome, 'Good')...
                & strcmp(r.EventTable.reward, 'Rewarded');
        case 'Distant'
            ind = r.EventTable.time_from_last_reward>=thres_reward_history(2)...
                & ~isnan(r.EventTable.t_poke_first)...
                & strcmp(r.EventTable.outcome, 'Good')...
                & strcmp(r.EventTable.reward, 'Rewarded');
    end
    
    t_poke      = r.EventTable.t_poke_first(ind);
    t_portout   = r.EventTable.t_port_exit(ind);
    t_releases  = r.EventTable.t_release(ind);
    move_dur    = t_poke - t_releases;
    port_dur    = t_portout - t_poke;

    [psth_poke, ts_poke, trialspxmat_poke, tspkmat_poke, t_poke, ind_] = Spikes.jpsth(r.Units.SpikeTimes(ku).timings,...
        t_poke, params_poke);
    psth_poke = smoothdata(psth_poke, 'gaussian', 5);

    PSTH.Poke.(type_).tPSTH              =   ts_poke;
    PSTH.Poke.(type_).PSTH               =   psth_poke;
    PSTH.Poke.(type_).tSpikeMat          =   tspkmat_poke;
    PSTH.Poke.(type_).SpikeMat           =   trialspxmat_poke;
    PSTH.Poke.(type_).tEvents            =   t_poke;
    PSTH.Poke.(type_).MovementDuration   =   move_dur(ind_);
    PSTH.Poke.(type_).PortDuration       =   port_dur(ind_);
end
%% Check for PSTH range
% ---------- helper: safe max ----------
safeMax = @(x) max([0; x(:)], [], 'omitnan');

n_min = 5;                 % you already have this
% ---------- Press ----------
FRMaxPress = 5;  % floor
% Good
for i = 1:numel(typesPressRelease)
    FRMaxPress = max(FRMaxPress, safeMax(PSTH.Press.(typesPressRelease{i}).Good.PSTH));
end
% Bad (only if enough trials)
for i = 1:numel(typesPressRelease)
    if numel(PSTH.Press.(typesPressRelease{i}).Bad.tEvents) > n_min
        FRMaxPress = max(FRMaxPress, safeMax(PSTH.Press.(typesPressRelease{i}).Bad.PSTH));
    end
end

% ---------- Release ----------
FRMaxRelease = 5;
for i = 1:numel(typesPressRelease)
    FRMaxRelease = max(FRMaxRelease, safeMax(PSTH.Release.(typesPressRelease{i}).Good.PSTH));
end
for i = 1:numel(typesPressRelease)
    if numel(PSTH.Release.(typesPressRelease{i}).Bad.tEvents) > n_min
        FRMaxRelease = max(FRMaxRelease, safeMax(PSTH.Release.(typesPressRelease{i}).Bad.PSTH));
    end
end

% ---------- Poke ----------
FRMaxPoke = 5;
if isfield(PSTH,'Poke') && isfield(PSTH.Poke,'Rewarded')
    FRMaxPoke = max(FRMaxPoke, safeMax(PSTH.Poke.Rewarded.PSTH));
end
if isfield(PSTH,'Poke') && isfield(PSTH.Poke,'Bad')
    FRMaxPoke = max(FRMaxPoke, safeMax(PSTH.Poke.Bad.PSTH));
end

% optional: round up nicely
roundUp = @(v,step) step*ceil(v/step);
FRMaxPress   = roundUp(FRMaxPress,   1);
FRMaxRelease = roundUp(FRMaxRelease, 1);
FRMaxPoke    = roundUp(FRMaxPoke,    1);
FRMax = 1.1*max([FRMaxPress FRMaxRelease FRMaxPoke]);

%% Plot raster and spks
hf=27;
figure(hf); clf(hf)
set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w',...
    'ToolBar','none')
height_psth = 1.2;

width_release = 6*sum(ReleaseTimeDomain)/sum(PressTimeDomain);
xrange_release = [-ReleaseTimeDomain(1) ReleaseTimeDomain(2)];
x_release = 8.25;

% PSTH of good press trials (port-light on after press)
yshift_row1 = 10;
vspacing = 0.5;
ha_press_psth =  axes('unit', 'centimeters', 'position', [1.25 yshift_row1 6 height_psth], 'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);
yshift_row2 = yshift_row1+height_psth+vspacing;

if ~by_rank % i.e., by time
    typesPressRelease = {'Rank_All'};
end

for i =1:numel(typesPressRelease)
    field = typesPressRelease{i};
    t       = PSTH.Press.(field).Good.tPSTH;
    ipsth   = PSTH.Press.(field).Good.PSTH;
    plot(t, ipsth, 'color', rank_cols(i, :),  'linewidth', 1.5);
end

lockPsthAxis(ha_press_psth, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Good', 'corner', 'topleft');

xlabel('Time from press (ms)')
ylabel ('Spks per s')

% Add release panel
ha_release_psth =  axes('unit', 'centimeters', ...
    'position', [x_release yshift_row1 width_release height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_release);
for i =1:numel(typesPressRelease)
    field = typesPressRelease{i};
    t       = PSTH.Release.(field).Good.tPSTH;
    ipsth   = PSTH.Release.(field).Good.PSTH;
    plot(t, ipsth, 'color', rank_cols(i, :),  'linewidth', 1.5);
end
lockPsthAxis(ha_release_psth, FRMax, 0, release_col);
xlabel('Time from release (ms)')

% PSTH of bad press trials (no external cue appears after press)
ha_press_psth_error =  axes('unit', 'centimeters', 'position', [1.25 yshift_row2 6 height_psth], 'nextplot', 'add',...
    'xlim',  [-PressTimeDomain(1)-25 PressTimeDomain(2)], 'xticklabel', []);
n_min = 5;
for i =1:numel(typesPressRelease)
    field = typesPressRelease{i};
    t       = PSTH.Press.(field).Bad.tPSTH;
    ipsth   = PSTH.Press.(field).Bad.PSTH;
    n       = numel(PSTH.Press.(field).Bad.tEvents);
    if n>n_min
        plot(t, ipsth, 'color', rank_cols(i, :),  'linewidth', 1.5);
    end
end

lockPsthAxis(ha_press_psth_error, FRMax, 0, press_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Bad', 'corner', 'topleft');

ha_release_psth_error =  axes('unit', 'centimeters', ...
    'position', [x_release yshift_row2 width_release height_psth], 'nextplot', 'add',...
    'xlim',  xrange_release, 'xticklabel', []);

n_min = 5;
for i =1:numel(typesPressRelease)
    field = typesPressRelease{i};
    t       = PSTH.Release.(field).Bad.tPSTH;
    ipsth   = PSTH.Release.(field).Bad.PSTH;
    n       = numel(PSTH.Release.(field).Bad.tEvents);
    if n>n_min
        plot(t, ipsth, 'color', rank_cols(i, :),  'linewidth', 1.5);
    end
end
lockPsthAxis(ha_release_psth_error, FRMax, 0, release_col);

% yshift_row2_ = yshift_row2 + height_psth+vspacing;
% yshift_row3 = yshift_row2_ +height_psth+vspacing;
yshift_row2_ = yshift_row2;
yshift_row3 = yshift_row2_ +height_psth+vspacing;
%% Plot spike raster of good trials (all ranks)
n_presses = numel(PSTH.Press.All.tEvents);
rasterheight = 0.04*100/n_presses;

if by_rank
    % Plot spike raster of Good trials (all ranks)
    ntrials_press = 0;
    nRank_i = zeros(1, nGroupRanks);
    for i =1:nGroupRanks
        field = typesPressRelease{i};
        nRank_i(i) = numel(PSTH.Press.(field).Good.tEvents);
        ntrials_press = ntrials_press + nRank_i(i);
    end
    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row3 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row4 = yshift_row3+ntrials_press*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    for m =1:nGroupRanks
        field = typesPressRelease{m};
        ap_mat = PSTH.Press.(field).Good.SpikeMat;
        t_mat = PSTH.Press.(field).Good.tSpikeMat;
        hold_dur = PSTH.Press.(field).Good.HoldDuration'; % make sure it is 1 x nTrial
        press_rank = PSTH.Press.(field).Good.PressRank';
        
        % sort hold_dur
        [hold_dur, ind_sort] = sort(hold_dur);
        press_rank = press_rank(ind_sort);
        ap_mat = ap_mat(:, ind_sort);
        
        % sort press_rank
        % [press_rank, ind_sort] = sort(press_rank);
        % hold_dur = hold_dur(ind_sort);
        % ap_mat = ap_mat(:, ind_sort);

        fp_color = trigger_col;
        fp_dur = 0;
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur, fp_dur, fp_color);
    end
    thisylim = ylim;
    ini = thisylim(2);
    for m=1:nGroupRanks
        line(repmat(-PressTimeDomain(1),[1 2]),[ini ini-nRank_i(m)],...
            'color', rank_cols(m,:), 'linewidth', 3);
        ini = ini-nRank_i(m);
    end
    % xline(-PressTimeDomain(1), 'color', 'k', 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Good', ntrials_press), 'corner', 'topleft');
    axis off
    
    % Add release
    ntrials_press = 0;
    nRank_i = zeros(1, nGroupRanks);
    for i =1:nGroupRanks
        field = typesPressRelease{i};
        nRank_i(i) = numel(PSTH.Release.(field).Good.tEvents);
        ntrials_press = ntrials_press + nRank_i(i);
    end
    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row3 width_release ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_press 1], 'box', 'on');
    % Paint the foreperiod
    k=0;
    for m =1:nGroupRanks
        field = typesPressRelease{m};
        ap_mat = PSTH.Release.(field).Good.SpikeMat;
        t_mat = PSTH.Release.(field).Good.tSpikeMat;
        hold_dur = PSTH.Release.(field).Good.HoldDuration'; % make sure it is 1 x nTrial
        press_rank = PSTH.Release.(field).Good.PressRank';
        
        % sort hold_dur first
        [hold_dur, ind_sort] = sort(hold_dur);
        press_rank = press_rank(ind_sort);
        ap_mat = ap_mat(:, ind_sort);
        
        % sort press_rank
        % [press_rank, ind_sort] = sort(press_rank);
        % hold_dur = hold_dur(ind_sort);
        % ap_mat = ap_mat(:, ind_sort);

        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    end
    thisylim = ylim;
    ini = thisylim(2);
    for m=1:nGroupRanks
        line(repmat(-ReleaseTimeDomain(1),[1 2]),[ini ini-nRank_i(m)],...
            'color', rank_cols(m,:), 'linewidth', 3);
        ini = ini-nRank_i(m);
    end
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off
    
    % yshift_row4 = yshift_row4+ntrials_press*rasterheight+0.5;

    % Plot spike raster of bad trials (all ranks)
    ntrials_press = 0;
    nRank_i = zeros(1, nGroupRanks);
    for i =1:nGroupRanks
        field = typesPressRelease{i};
        nRank_i(i) = numel(PSTH.Press.(field).Bad.tEvents);
        ntrials_press = ntrials_press + nRank_i(i);
    end
    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row4 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');

    % Paint the foreperiod
    k=0;
    for m =1:nGroupRanks
        field = typesPressRelease{m};
        ap_mat = PSTH.Press.(field).Bad.SpikeMat;
        t_mat = PSTH.Press.(field).Bad.tSpikeMat;
        hold_dur = PSTH.Press.(field).Bad.HoldDuration'; % make sure it is 1 x nTrial
        press_rank = PSTH.Press.(field).Bad.PressRank';

        % sort hold_dur first
        [hold_dur, ind_sort] = sort(hold_dur);
        press_rank = press_rank(ind_sort);
        ap_mat = ap_mat(:, ind_sort);
        
        % sort press_rank
        % [press_rank, ind_sort] = sort(press_rank);
        % hold_dur = hold_dur(ind_sort);
        % ap_mat = ap_mat(:, ind_sort);

        fp_color = trigger_col;
        fp_dur = 0;
        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, hold_dur, fp_dur, fp_color);
    end
    thisylim = ylim;
    ini = thisylim(2);
    for m=1:nGroupRanks
        ha_rank(m) = line(repmat(-PressTimeDomain(1),[1 2]),[ini ini-nRank_i(m)],...
            'color', rank_cols(m,:), 'linewidth', 3);
        ini = ini-nRank_i(m);
    end
    % xline(-PressTimeDomain(1), 'color', 'k', 'linewidth', 2);
    xline(0, 'color', press_col, 'linewidth', 1);
    
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('%s(n=%d)','Bad', ntrials_press), 'corner', 'topleft');
    axis off

    le = legend(ha_rank,{'Low','Mid','High'},'Box','off',...
        'Units','centimeters','Position',[0.25 yshift_row4 1 1]);
    le.Title.String = 'Rank';
    le.ItemTokenSize(1) = 5;

    % Add release
    ntrials_press = 0;
    nRank_i = zeros(1, nGroupRanks);
    for i =1:nGroupRanks
        field = typesPressRelease{i};
        nRank_i(i) = numel(PSTH.Release.(field).Bad.tEvents);
        ntrials_press = ntrials_press + nRank_i(i);
    end
    ax = axes('unit', 'centimeters', ...
        'position', [x_release yshift_row4 width_release ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_release, 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row5 = yshift_row4+ntrials_press*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    for m =1:nGroupRanks
        field = typesPressRelease{m};
        ap_mat = PSTH.Release.(field).Bad.SpikeMat;
        t_mat = PSTH.Release.(field).Bad.tSpikeMat;
        hold_dur = PSTH.Release.(field).Bad.HoldDuration'; % make sure it is 1 x nTrial
        press_rank = PSTH.Release.(field).Bad.PressRank';
        
        % sort hold_dur first
        [hold_dur, ind_sort] = sort(hold_dur);
        press_rank = press_rank(ind_sort);
        ap_mat = ap_mat(:, ind_sort);
        
        % sort press_rank
        % [press_rank, ind_sort] = sort(press_rank);
        % hold_dur = hold_dur(ind_sort);
        % ap_mat = ap_mat(:, ind_sort);

        [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -hold_dur);
    end
    thisylim = ylim;
    ini = thisylim(2);
    for m=1:nGroupRanks
        ha_rank(m) = line(repmat(-ReleaseTimeDomain(1),[1 2]),[ini ini-nRank_i(m)],...
            'color', rank_cols(m,:), 'linewidth', 3);
        ini = ini-nRank_i(m);
    end
    xline(0, 'color', release_col, 'linewidth', 1);
    axis off

else % by_time, use all data
    ntrials_press = numel(PSTH.Press.All.tEvents);
    ax = axes('unit', 'centimeters', 'position', [1.25 yshift_row3 6 ntrials_press*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrials_press 1], 'box', 'on');
    yshift_row4 = yshift_row3+ntrials_press*rasterheight+0.5;
    yshift_row5 = yshift_row4;
    % Paint the foreperiod
    k=0;
    ap_mat      =   PSTH.Press.All.SpikeMat;
    t_mat       =   PSTH.Press.All.tSpikeMat;
    hold_dur    =   PSTH.Press.All.HoldDuration'; % make sure it is 1 x nTrial

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

% this is the position of last panel
% Add information
annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[0.5 yshift_row5 10 0.5], ...
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
if by_rank == 0
    headerStr = sprintf('#%d | %s | %s | by time', ku, PSTH.UnitID, type_unit);
else
    headerStr = sprintf('#%d | %s | %s | by rank', ku, PSTH.UnitID, type_unit);
end
pos = [0.5 yshift_row5+0.6 11 0.5];
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
    % if strcmp(itype, 'Omitted') && isempty(glm_mdl)
    %     continue
    % end
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
h = addAxisCornerLabel(ax, 'Reward/Omit(dots)', 'corner', 'topleft');

yshift_row2 = yshift_row1+2+vspacing;
ha_poke_nonreward = axes('unit', 'centimeters', ...
    'position', [x_poke yshift_row2 width_poke height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_poke, 'xticklabel', []);
t     = PSTH.Poke.Bad.tPSTH;
ipsth = PSTH.Poke.Bad.PSTH;
plot(t, ipsth, 'color', [.6 .6 .6], ...
    'linewidth', 0.75, 'linestyle', '-');

lockPsthAxis(ha_poke_nonreward, FRMax, 0, reward_col);
ax = gca;  % or the handle returned from axes(...)
h = addAxisCornerLabel(ax, 'Bad', 'corner', 'topleft');

%% Make raster plot
% Rewarded trials
yshift_row3 = yshift_row2+height_psth+vspacing;

if by_rank
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
    % more_pokes      =       PSTH.Poke.Rewarded.MorePokes;
    port_exit       =       PSTH.Poke.Rewarded.PortDuration;

    % sort hold_dur
    [move_dur, ind_sort] = sort(move_dur);
    ap_mat = ap_mat(:, ind_sort);
    % more_pokes = more_pokes(ind_sort);
    port_exit = num2cell(port_exit(ind_sort)');

    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);
    
    % add the time exiting the port
    Spikes.plotMoreTicks(ax, k0, port_exit, 'b');

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
    % more_pokes      =       PSTH.Poke.Omitted.MorePokes;
    port_exit       =       PSTH.Poke.Omitted.PortDuration;

    % sort hold_dur
    [move_dur, ind_sort] = sort(move_dur);
    ap_mat = ap_mat(:, ind_sort);
    % more_pokes = more_pokes(ind_sort);
    port_exit = num2cell(port_exit(ind_sort)');

    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);

    % add the time exiting the port
    Spikes.plotMoreTicks(ax, k0, port_exit, 'b');

    % sort hold_dur
    [move_dur, ind_sort] = sort(move_dur);
    ap_mat = ap_mat(:, ind_sort);

    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);
    line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('Omitted (n=%d)', n), 'corner', 'topleft');
    axis off

    % Add bad trials
    n = length(PSTH.Poke.Bad.tEvents);
    ax = axes('unit', 'centimeters', ...
        'position', [x_poke yshift_row4 width_poke n*rasterheight],...
        'nextplot', 'add',...
        'xlim', xrange_poke, 'ylim', [-n-2 1], 'box', 'on');

    yshift_row5 = yshift_row4+n*rasterheight+0.5;
    % Paint the foreperiod
    k=0;
    ap_mat  = PSTH.Poke.Bad.SpikeMat;
    t_mat   = PSTH.Poke.Bad.tSpikeMat;
    move_dur = PSTH.Poke.Bad.MovementDuration;
    port_exit = PSTH.Poke.Bad.PortDuration;

    % sort hold_dur
    [move_dur, ind_sort] = sort(move_dur);
    ap_mat = ap_mat(:, ind_sort);
    port_exit = num2cell(port_exit(ind_sort)');
    
    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);
    
    % add the time exiting the port
    Spikes.plotMoreTicks(ax, k0, port_exit, 'b');

    line([0 0], get(gca, 'ylim'), 'color', reward_col, 'linewidth', 1);
    ax = gca;  % or the handle returned from axes(...)
    h = addAxisCornerLabel(ax, sprintf('Bad (n=%d)', n), 'corner', 'topleft');
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
    port_exit       =       PSTH.Poke.All.PortDuration;
    
    port_exit       =       num2cell(port_exit');

    k0 = k;
    [h, k] = Spikes.plotRasterFast(ax, ap_mat, t_mat, k, -move_dur);
    
    % add the time exiting the port
    Spikes.plotMoreTicks(ax, k0, port_exit, 'b');

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

y_beh = yshift_row5+ 3.5; % this is for behavior data

%% Plot behavior data
xnow = 13;
ynow = y_beh; % computed above

% %%%%%%%%%%%% Raw progress data
width_beh = 8.5;
height_beh = 3;

rateLim = [-10 20]; rateTicks = 0:5:rateLim(2);
probLim = [-abs(rateLim(1))/(rateLim(2)) 1]; probTicks = 0:0.2:1;
pressLineBottom = -10; pressLineLen = 2;
pokeLineBottom = -6; pokeLineLen = 2;

fontsize_label = 8;

% calculate event time
tab = r.EventTable;
xrange = [floor(tab.t_press(1)/10000)*10 ceil(tab.t_press(end)/10000)*10];

pressRate = size(tab,1)./diff(xrange).*60;

step = 60;
edgesT = xrange(1):step:xrange(2)+step;
N_rate = histcounts(tab.t_press./1000, edgesT, 'Normalization', 'count');
t_rate = edgesT(1:end-1)+diff(edgesT)./2;
N_rate_smooth = movmean(N_rate, 3); % 3 min smooth

% plot behavior
ha_progress = axes('unit', 'centimeters', ...
            'position', [xnow ynow width_beh height_beh], 'nextplot', 'add', ...
            'xlim', xrange, 'xtick', (0:600:3600), 'xticklabelrotation', 0,...
            'xticklabels',string(0:10:60));
xlabel('Time in Ephys (min)');
ylim(probLim);
line(xlim, zeros([1 2]), 'Color', 'k', 'linewidth', 0.5, 'LineStyle', '-.');
line(xlim, repmat(pressRate,[1 2]), 'Color', 'k', 'linewidth', 2, 'LineStyle', '-');

isBadPress = strcmp(tab.outcome,'Bad');
t_BadPress = tab.t_press(isBadPress)./1000;
if ~isempty(t_BadPress)
    line(repmat(t_BadPress,[1 2]),[0 pressLineLen]+pressLineBottom, 'color', 'k', 'linewidth', 0.5, 'LineStyle', '-', 'Marker', 'none');
end
isBadPoke = contains(tab.reward,{'Bad'});
t_BadPokeFirst = tab.t_poke_first(isBadPoke)./1000;
if ~isempty(t_BadPokeFirst)
    line(repmat(t_BadPokeFirst,[1 2]),[0 pokeLineLen]+pokeLineBottom, 'color', 'k', 'linewidth', 0.5, 'LineStyle', '-', 'Marker', 'none');
end
isGoodPress = strcmp(tab.outcome,'Good');
t_GoodPress = tab.t_press(isGoodPress)./1000;
if ~isempty(t_GoodPress)
    line(repmat(t_GoodPress,[1 2]),[0 pressLineLen*2]+pressLineBottom, 'color', cGreen, 'linewidth', 0.5, 'LineStyle', '-', 'Marker', 'none');
end
isGoodPoke = contains(tab.reward,{'Rewarded','Omitted'});
t_GoodPokeFirst = tab.t_poke_first(isGoodPoke)./1000;
if ~isempty(t_GoodPokeFirst)
    line(repmat(t_GoodPokeFirst,[1 2]),[0 pokeLineLen*2]+pokeLineBottom, 'color', cBlue, 'linewidth', 0.5, 'LineStyle', '-', 'Marker', 'none');
end
isOmitPoke = contains(tab.reward,'Omitted');
t_OmitPokeFirst = tab.t_poke_first(isOmitPoke)./1000;
if ~isempty(t_OmitPokeFirst)
    line(repmat(t_OmitPokeFirst,[1 2]),[0 pokeLineLen*2]+pokeLineBottom, 'color', cRed, 'linewidth', 0.5, 'LineStyle', '-', 'Marker', 'none');
end

% Press rate
plot(t_rate, N_rate, '-k', 'LineWidth', 1);
plot(t_rate, N_rate, 'vk', 'LineWidth', 0.5, 'LineStyle', 'none',...
    'MarkerSize', 4, 'MarkerEdgeColor', 'w', 'MarkerFaceColor', 'k');
plot(t_rate, N_rate_smooth, '-','color', cRed, 'LineWidth', 2);

text(xrange(2),pressRate,sprintf(' Mean=%.1f',pressRate),...
    'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',fontsize_label)
text(xrange(2),pressLineBottom,sprintf(' Press  %d/%d',length(t_GoodPress),length(t_GoodPress)+length(t_BadPress)),...
    'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',fontsize_label);
text(xrange(2),pokeLineBottom,sprintf(' Poke1st  %d/%d',length(t_GoodPokeFirst),length(t_GoodPokeFirst)+length(t_BadPokeFirst)),...
    'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',fontsize_label);
ylabel('Press rate (min^{-1})');
ylim(rateLim);
yticks(rateTicks);

% %%%%%%%%%%% Movement time x Good/Bad poke
x_MT = 20;
width_MT = 3;
xrange_MT = [0 9];
mtTicks = xrange_MT(1):3:xrange_MT(2);

mt_bad = (tab.t_poke_first(isBadPoke)-tab.t_release(isBadPoke))./1000;
mt_good = (tab.t_poke_first(isGoodPoke)-tab.t_release(isGoodPoke))./1000;
mtEdges = xrange_MT(1):1/3:xrange_MT(2);
pdf_mt_bad = movmean([mtEdges(1) histcounts(mt_bad, mtEdges,'Normalization','pdf')],3);
pdf_mt_good = movmean([mtEdges(1) histcounts(mt_good, mtEdges,'Normalization','pdf')],3);

ha_MT = axes('unit', 'centimeters', ...
    'position', [x_MT yshift_row1 width_MT height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_MT, 'xtick', xrange_MT(1):3:xrange_MT(2), ...
    'xticklabelrotation', 0,...
    'YGrid','on');
ha_bad_mt = plot(mtEdges, pdf_mt_bad, 'Color', 'k', 'LineWidth', 1.5);
ha_good_mt = plot(mtEdges, pdf_mt_good, 'Color', cBlue, 'LineWidth', 1.5);

N_Lim = ylim;
N_Lim(1) = 0;
N_Lim(2) = max(1, N_Lim(2));
ylim(N_Lim);

xlabel('Movement time (s)');
xticks(mtTicks);
ylabel('pdf');

le_MT = legend([ha_bad_mt ha_good_mt],{'Bad','Good'},'Box','off', 'FontSize',fontsize_label,...
    'Units','centimeters','Position',[x_MT+width_MT yshift_row1 1.5 height_psth]);
le_MT.Title.String = 'Poke';
le_MT.ItemTokenSize(1) = 7;

% %%%%%%%%%%% N-rank distribution & P(Stay)
x_nRank = x_MT;
y_nRank = yshift_row1 + height_psth + 1.2;
width_nRank = width_MT;

% Probability of staying press when port-light off (bad press)
% tab_bad = tab(contains(tab.outcome,'Bad') & contains(tab.reward,{'NaN','Bad'}),:);
% tab_good = tab(contains(tab.outcome,'Good'),:);

rankinfo = groupsummary(tab, 'press_rank', 'mean', 'is_stay');
i_rank = rankinfo.press_rank;
N_rank = rankinfo.GroupCount;
pStay_rank = rankinfo.mean_is_stay;

% rankinfo_good = groupsummary(tab_good, 'press_rank');
% i_rank_good = rankinfo_good.press_rank;
% N_rank_good = rankinfo_good.GroupCount;

ul_rank = min(8, max(i_rank));
i_rank = i_rank(1:ul_rank);
N_rank = N_rank(1:ul_rank);
pStay_rank = pStay_rank(1:ul_rank);
% i_rank_good = i_rank_good(1:ul_rank);
% N_rank_good = N_rank_good(1:ul_rank);

xrange_nRank = [i_rank(1)-0.5 i_rank(end)+0.5];

ha_Rank = axes('unit', 'centimeters', ...
    'position', [x_nRank y_nRank width_nRank height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_nRank, 'xtick', i_rank(1):i_rank(end), ...
    'ytick', 0:20:200,...
    'xticklabelrotation', 0);

colororder([cBlack;cBrown])

yyaxis left;
% plot(i_rank_good, N_rank_good, 'color', cGreen, 'LineStyle', '-', 'LineWidth', 1);
plot(i_rank, N_rank, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
plot(i_rank, N_rank, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);
N_Lim = ylim;
N_Lim(1) = 0;
N_Lim(2) = max(20,N_Lim(2));
ylim(N_Lim);
ylabel('N(Press)');
xlabel('Press rank');


yyaxis right;
plot(i_rank, pStay_rank, 'color', cBrown, 'LineStyle', '-', 'LineWidth', 1);
plot(i_rank, pStay_rank, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBrown, 'MarkerEdgeColor', cWhite);
ylabel('P(Stay)');
ylim([0 1]);

% %%%%%%%%%%% N(bad poke) cdf - corresponding press rank
y_nRank = y_nRank + height_psth + 0.8;

tab_bad_poke = tab(contains(tab.reward,{'Bad'}),:);
rankinfo_badpoke = groupsummary(tab_bad_poke, 'press_rank');
i_rank_badpoke = rankinfo_badpoke.press_rank;
N_rank_badpoke = rankinfo_badpoke.GroupCount;
cdf_rank_badpoke = cumsum(N_rank_badpoke / sum(N_rank_badpoke));

tab_good_poke = tab(contains(tab.reward,{'Rewarded','Omitted'}),:);
rankinfo_goodpoke = groupsummary(tab_good_poke, 'press_rank');


i_rank_badpoke = i_rank_badpoke(i_rank_badpoke<=ul_rank);
N_rank_badpoke = N_rank_badpoke(i_rank_badpoke<=ul_rank);
cdf_rank_badpoke = cdf_rank_badpoke(i_rank_badpoke<=ul_rank);

xrange_nRank_badpoke = [0.5 i_rank_badpoke(end)+0.5];

ha_BadPokeRank = axes('unit', 'centimeters', ...
    'position', [x_nRank y_nRank width_nRank height_psth], ...
    'nextplot', 'add', ...
    'xlim', xrange_nRank_badpoke, 'xtick', 1:i_rank_badpoke(end), ...
    'ytick', 0:0.25:1, 'ygrid', 'on',...
    'xticklabelrotation', 0);

plot(i_rank_badpoke, cdf_rank_badpoke, 'color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
plot(i_rank_badpoke, cdf_rank_badpoke, 'lineStyle','none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);
ylim([0 1]);
ylabel('cdf');
title('Rank of bad poke');

% %%%%%%%%%%% Event rate - Session time (5-min binned)
y_rate = y_nRank + height_psth + 1.5;
x_rate = x_nRank;
width_rate = width_nRank;
height_rate = y_beh - y_rate - 0.5;

min2bin = 5; % 5-min binned
stepEpoch = 60*min2bin;
nEpoch = floor(0.2+diff(xrange)/stepEpoch); % 30 seconds gap is allowed
edgesEpoch = xrange(1):stepEpoch:xrange(1)+nEpoch*stepEpoch;
ticksEpoch = 1:nEpoch;
N_press_Epoch = histcounts(tab.t_press./1000, edgesEpoch, 'Normalization', 'count')./min2bin;
N_badpoke_Epoch = histcounts(t_BadPokeFirst, edgesEpoch, 'Normalization', 'count')./min2bin;

haRateProgress = axes('unit', 'centimeters',...
    'position',[x_rate y_rate width_rate height_rate], 'nextplot', 'add');

plot(ticksEpoch, N_press_Epoch, 'Color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
ha_pressE = plot(ticksEpoch, N_press_Epoch, 'lineStyle', 'none', 'LineWidth', 0.5,...
    'Marker', 'v', 'MarkerSize', 6, 'MarkerFaceColor', cBlack, 'MarkerEdgeColor', cWhite);
xticks(ticksEpoch);
xlim([ticksEpoch(1)-0.5 ticksEpoch(end)+0.5]);
N_Lim = ylim;
N_Lim(1) = 0;
ylim(N_Lim);
ylabel('N per min');
xlabel(sprintf('%d-min bins',min2bin));

plot(ticksEpoch, N_badpoke_Epoch, 'Color', cBlack, 'LineStyle', '-', 'LineWidth', 1);
ha_badpokeE = plot(ticksEpoch, N_badpoke_Epoch, 'lineStyle', 'none', 'LineWidth', 1.2,...
    'Marker', 'o', 'MarkerSize', 5, 'MarkerFaceColor', cWhite, 'MarkerEdgeColor', cBlack);

le_rateE = legend([ha_pressE ha_badpokeE],{'Press','BadPoke'},...
    'Location','southeastoutside', 'FontSize',fontsize_label,...
    'Units','Centimeters','Position', [x_rate+width_rate y_rate 1.5 height_rate]);
legend('box', 'off');
%% Look at reward history modulation
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

types = {'Recent', 'Distant'};
line_styles = {'-', ':'};
annotation('textbox', ...
    'Units', 'centimeters', ... % Set units to centimeters
    'Position', [1, ynow+height_psth+0.5, 10, 0.7], ... % Normalize to figure units
    'String', 'Recent (—) vs Distant (⋯) reward history', ...
    'Interpreter', 'none', ... % Prevent underscores from being treated as subscripts
    'BackgroundColor', 'w', ... % White background
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'FontName', 'DejaVu Sans', ... % Note: MATLAB uses 'DejaVu Sans' (case-sensitive)
    'EdgeColor', 'none'); % No border, similar to uicontrol default

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
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color/i);
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
h = addAxisCornerLabel(ax, 'Press (Good)', 'corner', 'topleft');

% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_press_psth_rew,'top'); % make explicit

% Poke
height_psth = 2;
width_press = 3;
poke_range = [-1000 500];
ha_poke_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow+width_press+hspacing2 yshift_row1 width_press height_psth], ...
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
    t     = PSTH.Poke.(type).tSpikeMat;
    spk   = PSTH.Poke.(type).SpikeMat;
    spk   = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color/i);

end
axis off

for i =1:length(types)
    type = types{i};
    t       = PSTH.Poke.(type).tPSTH;
    ipsth   = PSTH.Poke.(type).PSTH;
    plot(ha_poke_psth_rew, t, ipsth, 'color', 'r',  'linewidth', 1.5, 'linestyle', line_styles{i});
end
lockPsthAxis(ha_poke_psth_rew, FRMax, 0, reward_col);
h = addAxisCornerLabel(ax, 'Poke (Rewarded)', 'corner', 'topleft');
% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_poke_psth_rew,'top'); % make explicit

%% Look at good switch / bad switch
ynow = yshift_row2;

annotation('textbox', ...
    'Units', 'centimeters', ... % Set units to centimeters
    'Position', [1, ynow+height_psth+0.4, 8, 0.7], ... % Normalize to figure units
    'String', 'Good/Bad Switch & Bad Switch/Stay', ...
    'Interpreter', 'none', ... % Prevent underscores from being treated as subscripts
    'BackgroundColor', 'w', ... % White background
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'FontName', 'DejaVu Sans', ... % Note: MATLAB uses 'DejaVu Sans' (case-sensitive)
    'EdgeColor', 'none'); % No border, similar to uicontrol default

% Release (1)
types = {'Good_Switch', 'Bad_Switch'};
line_styles = {'-', '-'};
colors = {'r', 'c'};

height_psth = 2;
width_press = 3;
release_range = [-250 1000];
ha_release_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow yshift_row2 width_press height_psth], ...
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

for i =1:length(types)
    type = types{i};
    t       = PSTH.Release.(type).tSpikeMat;
    spk   = PSTH.Release.(type).SpikeMat;
    spk = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color/i);
end
axis off

for i =1:length(types)
    type = types{i};
    t       = PSTH.Release.(type).tPSTH;
    ipsth   = PSTH.Release.(type).PSTH;
    plot(ha_release_psth_rew, t, ipsth, 'color', colors{i},  'linewidth', 2, ...
        'linestyle', line_styles{i});
end
lockPsthAxis(ha_release_psth_rew, FRMax, 0, release_col);
h = addAxisCornerLabel(ax, 'Good[r] vs Bad[c]', 'corner', 'topleft');
% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_release_psth_rew,'top'); % make explicit

% Release (2)
types = {'Bad_Switch', 'Bad_Stay'};
line_styles = {'-', '-'};
colors = {'c', 'm'};

ha_release_psth_rew =  axes('unit', 'centimeters', ...
    'position', [xnow+width_press+hspacing2 yshift_row2 width_press height_psth], ...
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

for i =1:length(types)
    type = types{i};
    t       = PSTH.Release.(type).tSpikeMat;
    spk   = PSTH.Release.(type).SpikeMat;
    spk = spk(:, randperm(size(spk, 2), min(n, size(spk, 2))));
    [~, k] = Spikes.plotRasterFast(ax, spk, t, k, [], [], [], tick_color/i);
end
axis off

for i =1:length(types)
    type = types{i};
    t       = PSTH.Release.(type).tPSTH;
    ipsth   = PSTH.Release.(type).PSTH;
    plot(ha_release_psth_rew, t, ipsth, 'color', colors{i},  'linewidth', 2, ...
        'linestyle', line_styles{i});
end
lockPsthAxis(ha_release_psth_rew, FRMax, 0, release_col);
h = addAxisCornerLabel(ax, 'Switch[c] vs Stay[m]', 'corner', 'topleft');
% Put raster axis UNDER the PSTH axis (stacking order)
uistack(ax, 'bottom');          % or: uistack(ax,'down',1)
uistack(ha_release_psth_rew,'top'); % make explicit

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
scatter(ha10, x, y, 12, cBlueMatlab, 'filled');

% Plot fitted line
xdata = linspace(min(x), max(x), 200)';
yhat  = predict(mdl, xdata);
plot(xdata, yhat, 'LineWidth', 2, 'color', 'r');

xlabel('Time in session (s)')
ylabel('Pre-press spiking rate (hz)')
% Show the model on the plot
xl = ha10.XLim; yl = ha10.YLim;
stats_str = sprintf('\\beta = %.3g\np = %.3g\nR^2 = %.3g', beta, pval, r2);

text(xl(1) + 0.03*range(xl), yl(2) + 0.4, stats_str, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','bottom', ...
    'FontSize', 10, 'FontWeight', 'bold');

annotation('textbox', ...
    'Units','centimeters', ...
    'Position',[xnow-0.5 ynow+5 3.5 0.5], ...
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
xnow = 14.5;
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

ha00= axes('unit', 'centimeters', ...
    'position', [xnow+2.2 ynow 2.2 2], 'nextplot', 'add', 'xlim', [-20 20]);
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

xnow  = xnow + 5;
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
end

%% Add unit location information for Neuropixels recordings
if isfield(r, 'PixelTable')
    xnow = xnow_aligned+2.2;
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

fig = figure(hf);
if by_rank
    fn = [tosavename2 '_byRank.png'];
else
    fn = [tosavename2 '_byTime.png'];
end

exportgraphics(fig, fn, 'Resolution', 150);  % 150 dpi is a good paper default

end
%% Functions
function best_cuts = findBestCut(data)
% N = length(data);
% target = N / 3; % 理想情况下每组的数量

unique_vals = unique(data);
best_diff = inf;
best_cuts = [1, 1];

% 暴力搜索两个切点 i 和 j (i < j)
for i = 1:length(unique_vals)-2
    for j = i+1:length(unique_vals)-1
        cut1 = unique_vals(i);
        cut2 = unique_vals(j);
        
        % 计算当前切点下的各组数量
        n1 = sum(data <= cut1);
        n2 = sum(data > cut1 & data <= cut2);
        n3 = sum(data > cut2);
        
        % 计算与理想值的偏差（使用标准差或绝对误差）
        current_diff = std([n1, n2, n3]);
        
        if current_diff < best_diff
            best_diff = current_diff;
            best_cuts = [cut1, cut2];
        end
    end
end
end

function lockPsthAxis(ax, FRMax, x0, x0color)
    ylim(ax, [0 FRMax]);
    box(ax,'off');
    if nargin >= 3 && ~isempty(x0)
        xline(ax, x0, 'Color', x0color, 'LineWidth', 1);
    end
end
