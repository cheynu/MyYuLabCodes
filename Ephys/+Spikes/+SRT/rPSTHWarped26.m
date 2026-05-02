function warpOut = rPSTHWarped26(r, id)

% 3.9.2024 plot a simple version of PSTH
% 4/23/2024 Plot warped PSTH
% 2025.6.5 revised from PlotPSTHLiteWarped to simply the code
% 2025.08.11 We should also warp sdf for each FPs, aligned to press time. 
% 2025.08.13 add code to extract firing rate dynamics when there is no
% actiivty (10 seconds of activity in the absence of any behavioral events)
% This is useful for computing z score. 
% 2025.09.04 add an event table for further references. 

% 2025.12.31 new revision: remove the need to take data from r.PopPSTH (we
% have retired that field). Add 26. JY

% figure out which unit it is
spk_note =r.Units.SpikeNotes;

if length(id) == 2
    ind_unit = find(spk_note(:, 1)==id(1) & spk_note(:, 2)==id(2));
else
    ind_unit = id;
    id = [spk_note(id, 1) spk_note(id, 2)];
end
warpOut.subject                     =       r.BehaviorClass.Subject;
warpOut.session                     =       r.BehaviorClass.Date;
warpOut.unit_id                     =       [warpOut.subject '_' warpOut.session '_Ch' num2str(r.Units.SpikeNotes(ind_unit, 1)) '_Unit' num2str(r.Units.SpikeNotes(ind_unit, 2))];
warpOut.unit.index                  =       ind_unit;
warpOut.unit.ch                     =       [r.Units.SpikeNotes(ind_unit, 1) r.Units.SpikeNotes(ind_unit, 2)];
warpOut.events                      =       r.EventTable;
beh_tab                             =       r.EventTable; % give it a simple name
FPs                                 =       r.BehaviorClass.MixedFP;
warpOut.fps                         =       FPs;
%extract spike wave forms, spikes times, and conver spike times to 0 and 1
warpOut.unit.waves = r.Units.SpikeTimes(ind_unit).wave;

if size(warpOut.unit.waves, 1)>50
    warpOut.unit.waves = warpOut.unit.waves(randperm(size(warpOut.unit.waves, 1), 50), :);
end

if isfield(r.Units.SpikeTimes(ind_unit), 'wave_mean') % for Neuropixels recordings, this are all the waves.
    warpOut.unit.wave_mean = r.Units.SpikeTimes(ind_unit).wave_mean;
end

if isfield(r, 'ChanMap')
    wave_out = Spikes.waveLoc(r, r.Units.SpikeNotes(ind_unit, 1), r.Units.SpikeNotes(ind_unit, 2));
    warpOut.unit.wave_location = wave_out;
end

spktimes = r.Units.SpikeTimes(ind_unit).timings; % in ms
[tSpk, spkVec] = spike_to_sparse(spktimes); % this generates a sparse vector representing the spike train
[ar, lags]=xcorr(full(spkVec), 25, 'unbiased');
ar(lags==0)=0;
nFPs = length(FPs);

warpOut.unit.spike_times_ms    =      spktimes;
warpOut.unit.spike_sparse_ms   =      [tSpk' spkVec]; % sparse matrix representing spikes

warpOut.unit.times_ms =spktimes;
warpOut.unit.vector_sparse =[tSpk' spkVec];
warpOut.unit.auto_correlation = [lags' ar];

%% Added on 8/13/2025 find out periods without any behavioral engagement
% these are all the event times
event_times = sort([beh_tab.t_press; beh_tab.t_trigger; beh_tab.t_release; beh_tab.t_poke]);

tmin = min(spktimes);
tmax = max(spktimes);

tstep = 5*1000; % 5 sec step
twin = 10*1000; % 10 sec window
sigma_kernel = 50; % gaussian kernel to make spike density function
dt = 1; % time bins, 1 ms

tnow = tmin;
baseline_sdf = [];
t_baseline_sdf = [];
baseline_timing = [];

while tnow +twin<tmax
    this_win = [tnow tnow+twin];
    if any(event_times>(this_win(1)) & event_times<(this_win(2)))
        tnow = tnow + tstep;
    else
        spktimes_this   =   spktimes(spktimes>this_win(1) & spktimes>this_win(1)<this_win(2));
        [spkout, tspk]  =   sdf25(spktimes_this, this_win, sigma_kernel, dt);  %  spkout=sdf(tspk, spkin, kernel_width
        baseline_sdf    =   [baseline_sdf; spkout];
        t_baseline_sdf  =   [t_baseline_sdf; tspk];
        baseline_timing =   [baseline_timing mean(this_win)];
        tnow            =   tnow+twin;
    end
end

warpOut.baseline.description            = 'these were extracted from 10 s of data when rats are not doing the task';
warpOut.baseline.sdf                    = baseline_sdf;
warpOut.baseline.t_sdf                  = t_baseline_sdf;
warpOut.baseline.mean                   = mean(baseline_sdf);
warpOut.baseline.t_mean                 = t_baseline_sdf(1, :)-t_baseline_sdf(1,1);
warpOut.baseline.timing                 = baseline_timing;
warpOut.baseline.timing_description     = 'these are the times of the extracted segments';

%% added 4/28/2025
% revised 1/1/2026
% we should make a sdf for each row in the event table and label them in
% terms of outcome, reaction time, etc. 

% Type 1: all successful behavioral event chain: press, trigger, release,
% poke. Look for these events in EventTable. 
% We collect 2.75 s before press to 

% Trigger-Release-Poke sequence.
% 500 ms before trigger, then trigger, Trigger-Release (RT, need warping to
% median RT), Release to Poke (also needs to be warped)
% code initially written in cal_spk_out.m

% warp psth in this way: approach to press: no change; press to
% press+750 ms, no change. trigger-250 ms to release: warp; release to
% poke: warp;
% function warp_out=warp_srt_sdfs_pooled(prp_sequence, prp_sdfs, toplot)
% all poke times
% if  size(r.PSTH.Events.Pokes.RewardPoke.Time{1}, 1) == 1
%     all_pokes                   =  sort(cell2mat(r.PSTH.Events.Pokes.RewardPoke.Time));
% else
%     all_pokes                   =  transpose(sort(cell2mat(r.PSTH.Events.Pokes.RewardPoke.Time')));
% end

pre = struct();
post = struct();

pre.press           =   5000; % before press
post.press          =   10000; % post press
pre.trigger         =   750; % pre trigger
post.trigger        =   1000; % post trigger
pre.poke            =   1500; % pre poke
post.poke           =   1500; % post trigger
sigma_kernel        =   50; % gaussian kernel to make spike density function
dt                  =   1; % time bins, 1 ms

% store spike raster and warped sdf
seq_tab = table();
FPdata = repmat(struct('fp', [], 'spk_trains', [], 'sdfs', [], 'behavior_tab', []), 1, nFPs);

for ind_FP =1:nFPs
    FPdata(ind_FP).fp =  FPs(ind_FP);
    % find good sequence
    % good sequences are defined as: press, trigger, release, and poke are
    % all present
    ind_selected            =       beh_tab.FP == FPs(ind_FP) & strcmp(beh_tab.type, 'Normal') & ~isnan(beh_tab.t_trigger) & ~isnan(beh_tab.t_poke) & strcmp(beh_tab.outcome, 'Correct');
    press_times             =       beh_tab.t_press(ind_selected);
    trigger_times           =       beh_tab.t_trigger(ind_selected);
    release_times           =       beh_tab.t_release(ind_selected);
    poke_times              =       beh_tab.t_poke(ind_selected);

    fps_selected            =       beh_tab.FP(ind_selected);
    reaction_times          =       release_times-trigger_times;
    retrieval_durs          =       poke_times-release_times;
    ind_included            =       ~isoutlier(retrieval_durs, 'ThresholdFactor', 10) & reaction_times>100; % make sure only responses with RT over 100 ms are counted
    press_times_            =       press_times(ind_included);
    release_times_          =       release_times(ind_included);
    trigger_times_          =       trigger_times(ind_included);
    fps_selected_           =       fps_selected(ind_included);
    poke_times_             =       poke_times(ind_included);
    reaction_times_         =       reaction_times(ind_included);
    retrieval_durs_         =       retrieval_durs(ind_included);

    seq_tab_FP = table(fps_selected_, press_times_, ...
        trigger_times_, release_times_, reaction_times_, poke_times_, retrieval_durs_,...
        'VariableNames',{'fp', 't_press', 't_trigger', 't_release', 'rt', 't_poke', 'retrieval_dur'});
    % Go through these events and make sdf out of it.

    sdfs                    =       struct('press', cell(1, height(seq_tab_FP)), ...
        'trigger', cell(1, height(seq_tab_FP)), 'poke', cell(1, height(seq_tab_FP)));
    spk_trains              =       struct('press', cell(1, height(seq_tab_FP)), ...
        'trigger', cell(1, height(seq_tab_FP)), 'poke', cell(1, height(seq_tab_FP)));

    k_hat = 0;
    ind_included            =       ones(1, height(seq_tab_FP));

    for k =1:height(seq_tab_FP)
        % these are the events
        tk = struct();
        tk.press     =       seq_tab_FP.t_press(k);
        tk.trigger   =       seq_tab_FP.t_trigger(k);
        tk.release   =       seq_tab_FP.t_release(k);
        tk.poke      =       seq_tab_FP.t_poke(k);

        if tk.press-pre.press<0 || tk.press+post.press>max(spktimes) || tk.poke+post.trigger>max(spktimes)
            ind_included(k) = 0;
            continue
        end

        k_hat = k_hat+1;
        % extract spk times and construct sdf for this trial (press-,
        % trigger-aligned)
        events = {'press', 'trigger', 'poke'};
        for m =1:length(events)
            event_m = events{m};
            % 1 | pre and post press (pre = 2750 ms, post = 5000 ms)
            % 2 | pre and post trigger (pre = 750 ms, post = 1000 ms)
            t_range                      =       [tk.(event_m)-pre.(event_m) tk.(event_m)+post.(event_m)];
            k_spktimes                   =       spktimes(spktimes>=t_range(1) & spktimes<=t_range(2));
            k_spktimes                   =       k_spktimes-tk.(event_m); %  aligned to press time
            prepost_range                =       [-pre.(event_m) post.(event_m)];
            % spk train saved to a cell array.
            spk_trains(k).(event_m)       =       k_spktimes;
            % compute sdf
            [spkout, tspk]                =       sdf25(k_spktimes, prepost_range, sigma_kernel, dt);
            sdfs(k).(event_m)             =       [tspk' spkout'];
        end
    end
    spk_trains = spk_trains(logical(ind_included));
    sdfs = sdfs(logical(ind_included));
    seq_tab_FP = seq_tab_FP(logical(ind_included), :);
    FPdata(ind_FP).spk_trains       =       spk_trains;
    FPdata(ind_FP).sdfs             =       sdfs;
    FPdata(ind_FP).behavior_tab     =       seq_tab_FP;
end

warpOut.raster_sdf = FPdata; % this covers all!

% e.g., 
% >> FPdata(1)
% fp: 750
% spk_trains: [1×240 struct]
% sdfs: [1×240 struct]
% behavior_tab: [240×7 table]
% Compute sdf with pooled press, trigger, or poke data from both FPs

% Make a simplified version
events          =       {'press', 'trigger', 'poke'};
events          =       {'press'}; % to simplify, won't include trigger or poke (2026.1.10)

sub_struct      =       struct('t', [], 'data', []);
for ifp =1:length(warpOut.raster_sdf)
    sdfs_lite       =       struct('press', sub_struct, 'trigger', sub_struct, 'poke', sub_struct);
    sdfs            =       warpOut.raster_sdf(ifp).sdfs;
    for k =1:length(events)
        event = events{k};
        sdfs_lite.(event).t = sdfs(1).(event)(:, 1);
        for i = 1:length(sdfs)
            sdfs_lite.(event).data = [sdfs_lite.(event).data sdfs(i).(event)(:, 2)];
        end
    end
    warpOut.raster_sdf(ifp).sdfs = sdfs_lite; % remove this field to save space
end

SDF_pooled = struct();

for ie = 1:numel(events)
    event = events{ie};
    FR_all = [];   % [nTime x nTrialsTotal]
    for iFP = 1:numel(FPdata)
        sdfs = FPdata(iFP).sdfs;
        for k = 1:numel(sdfs)
            FR_all(:, end+1) = sdfs(k).(event)(:,2);
        end
    end
    % time axis (take from first trial)
    t = FPdata(1).sdfs(1).(event)(:,1);
    % stats
    n = size(FR_all, 2);
    meanFR = mean(FR_all, 2);
    seFR   = std(FR_all, 0, 2) ./ sqrt(n);
    alpha = 0.05;                 % 95% CI
    tval  = tinv(1 - alpha/2, n-1);
    SDF_pooled.(event).t      = t;
    SDF_pooled.(event).mean   = meanFR;
    SDF_pooled.(event).se     = seFR;
    SDF_pooled.(event).ci_lo  = meanFR - tval .* seFR;
    SDF_pooled.(event).ci_hi  = meanFR + tval .* seFR;
    SDF_pooled.(event).nTrial = n;
end
warpOut.sdf.pooled = SDF_pooled; % this covers all pooled sdfs aligned to press or trigger

% Warp sdf for each FPs, aligned to press time, and warp the trigger to
% release, and release to reward retrieval
warpOut.sdf.warped = [];
pre_press_win = 2500; % in seconds
post_poke_win = 1000;

for i =1:nFPs
    % behavior table of this fp
    event_tab_fp            =       warpOut.raster_sdf(i).behavior_tab;
    n_trials                =       height(event_tab_fp);

    % median reaction time
    ind = (strcmp(r.EventTable.outcome, 'Correct') & ~isnan(r.EventTable.t_trigger) & ~isnan(r.EventTable.t_release) & r.EventTable.FP == FPs(i));
    
    % figure out a common rt and retrieval to warp to
    rt_med                  =       median(r.EventTable.rt(ind), 'omitnan');
    retrieval_dur_med       =       median(r.EventTable.t_poke(ind) - r.EventTable.t_release(ind), 'omitnan');
    
    % start warping all trials
    sdf_warped_collective = [];     
    t_sdf = warpOut.raster_sdf(i).sdfs.press.t;

    for j = 1:n_trials

        j_sdf = warpOut.raster_sdf(i).sdfs.press.data(:,j);
        j_rt  = event_tab_fp.rt(j);
        j_retrieval = event_tab_fp.retrieval_dur(j);

        % given time and sdf of this trial, rt and retrieval of this trial
        % the sdf will be warped to a target reference time frame: target_t_template
        % based on target_rt and target_poke
        params.fp = FPs(i);
        params.pre_press = pre_press_win;
        params.post_poke = post_poke_win;

        wdata.current.t = t_sdf;
        wdata.current.sdf = j_sdf;
        wdata.current.rt = j_rt;
        wdata.current.retrieval = j_retrieval;
        wdata.target.rt = rt_med;
        wdata.target.retrieval = retrieval_dur_med;
        [wout, wdata] = Spikes.warpSdfSRT(wdata, params);
        wdata.current = rmfield(wdata.current, 't');
        wdata.current = rmfield(wdata.current, 'sdf');

        if j == 1
            warpOut.raster_sdf(i).sdfs.press_warped.current_event_time = wdata.current;
            warpOut.raster_sdf(i).sdfs.press_warped.target_event_time = wdata.target;
            warpOut.raster_sdf(i).sdfs.press_warped.t = wdata.t_warped;
            warpOut.raster_sdf(i).sdfs.press_warped.data = wdata.sdf_warped;
        else
            warpOut.raster_sdf(i).sdfs.press_warped.data = [warpOut.raster_sdf(i).sdfs.press_warped.data; wdata.sdf_warped];
        end

        if isempty(sdf_warped_collective)
            sdf_warped_collective = wout.sdf;
        else
            if size(sdf_warped_collective, 2) == length(wout.sdf)
                sdf_warped_collective = [sdf_warped_collective; wout.sdf];
            else
                sdf_warped_collective = [sdf_warped_collective; NaN(1, size(sdf_warped_collective, 2))];
            end
        end
    end

    warpOut.sdf.warped(i).fp = FPs(i);
    warpOut.sdf.warped(i).t = wout.t;
    % warpOut.sdf.warped(i).sdfs = sdf_warped_collective; % won't include
    % this since this increases the size of the data and is redundant
    warpOut.sdf.warped(i).rt = rt_med;
    warpOut.sdf.warped(i).retrieval_dur = retrieval_dur_med;

    n = size(sdf_warped_collective(~isnan(sdf_warped_collective(:, 1))), 1);
    meanSDF = mean(sdf_warped_collective, 1, 'omitnan');
    seSDF   = std(sdf_warped_collective, 0, 1, 'omitnan') ./ sqrt(n);
    alpha = 0.05;                 % 95% CI
    tval  = tinv(1 - alpha/2, n-1);

    warpOut.sdf.warped(i).sdf_mean  =   meanSDF;
    warpOut.sdf.warped(i).se        =   seSDF;
    warpOut.sdf.warped(i).ci_lo     =   meanSDF - tval .* seSDF;
    warpOut.sdf.warped(i).ci_hi     =   meanSDF + tval .* seSDF;
    warpOut.sdf.warped(i).nTrial    =   n;
end

% Compute event modulation

[stat_out, stat_table, spk_count_table] = Spikes.rPSTH_glme26(warpOut);

warpOut.glm_results.stat_out        =   stat_out;
warpOut.glm_results.table           =   stat_table;
warpOut.glm_results.spk_count       =   spk_count_table;

warpOut.meta.date                   =       datetime;
warpOut.meta.pwd                    =       pwd;
warpOut.meta.code                   =       sprintf('Spikes.SRT.rPSTHWarped26(r, [%d, %d])', r.Units.SpikeNotes(ind_unit, 1), r.Units.SpikeNotes(ind_unit, 2));
