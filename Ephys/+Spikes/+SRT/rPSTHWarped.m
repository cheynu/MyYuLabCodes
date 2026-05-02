function warpOut = rPSTHWarped(r, id, opts)
% 3.9.2024 plot a simple version of PSTH
% 4/23/2024 Plot warped PSTH
% 2025.6.5 revised from PlotPSTHLiteWarped to simply the code
% 2025.08.11 We should also warp sdf for each FPs, aligned to press time. 
% 2025.08.13 add code to extract firing rate dynamics when there is no
% actiivty (10 seconds of activity in the absence of any behavioral events)
% This is useful for computing z score. 
% 2025.09.04 add an event table for further references. 
% 2025.11.21, Yu Chen, optimize speed and storage size

arguments
    r
    id
    opts.event_table = table;
end

% figure out which unit it is
spk_note =r.Units.SpikeNotes;

if length(id) == 2
    ind_unit = find(spk_note(:, 1)==id(1) & spk_note(:, 2)==id(2));
else
    ind_unit = id;
    id = [spk_note(id, 1) spk_note(id, 2)];
end

warpOut.subject                     =   r.BehaviorClass.Subject;
warpOut.session                     =   r.BehaviorClass.Date;
warpOut.unit.ch                     =   [r.Units.SpikeNotes(ind_unit, 1) r.Units.SpikeNotes(ind_unit, 2)];
warpOut.unit.index                  =   ind_unit;
warpOut.unit.cell_id = [warpOut.subject '_' warpOut.session '_Ch' num2str(warpOut.unit.ch(1)) '_Unit' num2str(warpOut.unit.ch(2))];

if isempty(opts.event_table)  % optimize
    [event_table, ~] = Spikes.SRT.rEventTable(r);
    warpOut.events = event_table;
else
    warpOut.events = opts.event_table;
end

FPs                                 =   r.PopPSTH.FPs;
warpOut.FPs                         =   FPs;

%extract spike wave forms, sikes times, and conver spike times to 0 and 1
warpOut.unit.waves = r.Units.SpikeTimes(ind_unit).wave;
if isfield(r.Units.SpikeTimes(ind_unit), 'wave_mean')
    warpOut.unit.wave_mean = r.Units.SpikeTimes(ind_unit).wave_mean;
end

spktimes = r.Units.SpikeTimes(ind_unit).timings; % in ms
spktimes = spktimes(spktimes>0);
[tSpk, spkVec] = spike_to_sparse(spktimes); % this generates a sparse vector representing the spike train
[ar, lags]=xcorr(full(spkVec), 25, 'unbiased');
ar(lags==0)=0;

press_col = [5 5 5]/255;
trigger_col = [242 182 250]/255;
release_col = [87, 108, 188]/255;
poke_col = [164, 208, 164]/255;
nFPs = length(FPs);

if nFPs == 2
    FP_cols = [192, 127, 0; 76, 61, 61]/255;
else
    FP_cols = [255, 217, 90; 192, 127, 0; 76, 61, 61]/255;
end

%% added 8/13/2025 find out periods without any behavioral engagement
% also, add the starting time. 
press_times_all = r.PSTH.Events.Presses.Time{5}; % all press times are in '5'. 
release_times_all = cell2mat(r.PSTH.Events.Releases.Time'); % all release times .
poke_times_all = r.PSTH.Events.Pokes.Time;
trigger_times_all = cell2mat(r.PSTH.Events.Triggers.Time');
event_times = sort([press_times_all; release_times_all; poke_times_all; trigger_times_all]);

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
        spktimes_this   =   spktimes(spktimes>this_win(1) & spktimes<this_win(2));
        [spkout, tspk]  =   sdf25(spktimes_this, this_win, sigma_kernel, dt);  %  spkout=sdf(tspk, spkin, kernel_width
        baseline_sdf = [baseline_sdf; spkout];
        t_baseline_sdf = [t_baseline_sdf; tspk];
        baseline_timing = [baseline_timing mean(this_win)];
        tnow = tnow+twin;
    end
end

warpOut.baseline.description = 'these were extracted from 10 s of data when rats are not doing the task';
warpOut.baseline.sdf = single(baseline_sdf); % optimize
warpOut.baseline.t_sdf = uint32(t_baseline_sdf); % optimize
warpOut.baseline.mean = mean(baseline_sdf);
warpOut.baseline.t_mean = t_baseline_sdf(1, :)-t_baseline_sdf(1,1);
warpOut.baseline.timing = baseline_timing;
warpOut.baseline.timing_description = 'these are the times of the extracted segments';

%% added 4/28/2025
% Trigger-Release-Poke sequence.
% 500 ms before trigger, then trigger, Trigger-Release (RT, need warping to
% median RT), Release to Poke (also needs to be warped)
% code initially written in cal_spk_out.m

% warp psth in this way: approach to press: no change; press to
% press+750 ms, no change. trigger-250 ms to release: warp; release to
% poke: warp;
% function warp_out=warp_srt_sdfs_pooled(prp_sequence, prp_sdfs, toplot)

% all poke times
if  size(r.PSTH.Events.Pokes.RewardPoke.Time{1}, 1) == 1
    all_pokes                   =  sort(cell2mat(r.PSTH.Events.Pokes.RewardPoke.Time));
else
    all_pokes                   =  transpose(sort(cell2mat(r.PSTH.Events.Pokes.RewardPoke.Time')));
end
pre = struct();
post = struct();

pre.press           =   2.75; % before press
post.press          =   5; % post press
pre.trigger         =   0.75; % pre trigger
post.trigger        =   1; % post trigger
pre.poke            =   1; % pre poke
post.poke           =   1.5; % post trigger

% store spike raster and warped sdf
press_spktrains_all = cell(1, length(FPs));
press_sdfs_all      = cell(1, length(FPs));
release_sdfs_all      = cell(1, length(FPs));
press_release_seqs_all = cell(1, length(FPs));

release_event_seqs_all = [];
release_spktrains_all = cell(1, length(FPs));

for ind_FP =1:nFPs
    % find a few good sequence
    press_times              =  sort(r.PSTH.Events.Presses.Time{ind_FP});
    trigger_times            =  press_times + FPs(ind_FP);
    release_times            =  sort(r.PSTH.Events.Releases.Time{ind_FP});
    trigger_times_   = [];
    release_times_    = [];
    poke_times_     = [];
    for m =1:length(release_times)
        if ~isempty(find(all_pokes>release_times(m), 1, 'first'))
            poke_times_     = [poke_times_; all_pokes((find(all_pokes>release_times(m), 1, 'first')))];
            release_times_  = [release_times_; release_times(m)];
            trigger_times_  = [trigger_times_; trigger_times(m)];
        end
    end

    reaction_times_        =      release_times_  -   trigger_times_;
    retrieval_durs           =      poke_times_     -   release_times_;
    ind_included            =      ~isoutlier(retrieval_durs, 'ThresholdFactor', 10) & reaction_times_>100; % make sure only responses with RT over 100 ms are counted

    release_times_=release_times_(ind_included);
    trigger_times_=trigger_times_(ind_included);
    poke_times_=poke_times_(ind_included);
    % also get rid of press times that are not coupled to a sequence
    press_times_ = zeros(size(trigger_times_));
    for m =1:length(trigger_times_)
        press_times_(m) = press_times(find(press_times<trigger_times_(m), 1, 'last'));
    end
    % here, number of presses is likely larger than the number of
    % trigger-release-poke sequence
    press_release_seqs = [press_times_ trigger_times_ release_times_ poke_times_]; % warping required.
    
    % Go through these events and make sdf out of it.
    sigma_kernel = 50; % gaussian kernel to make spike density function
    dt = 1; % time bins, 1 ms
    press_sdfs =  {};
    press_spktrains = {};
    press_release_seqs_= [];
    % Go through each trigger-release-poke sequence
    release_spktrains = {};
    release_sdfs = {};

    k_ = 0;
    for k =1:size(press_release_seqs, 1)
        k_press     =       press_release_seqs(k, 1);
        k_trigger   =       press_release_seqs(k, 2);
        k_release   =       press_release_seqs(k, 3);
        k_poke      =       press_release_seqs(k, 4);
        if k_press-pre.press*1000>0 && k_press+post.press*1000<max(spktimes) && k_trigger-pre.trigger*1000>0 && k_poke+post.trigger*1000<max(spktimes)
            k_                           =       k_+1;
            press_release_seqs_(k_, :)   =       press_release_seqs(k, :);
            t_range                      =       [k_press-pre.press*1000 k_press+post.press*1000];
            k_spktimes                   =       spktimes(spktimes>=t_range(1) & spktimes<=t_range(2));
            k_spktimes                   =       k_spktimes-k_press; %  time aligned to press time
            t_range                      =       t_range-k_press;
            press_spktrains{k_}          =       k_spktimes; % spk train saved to a cell array.
            [spkout, tspk]               =       sdf25(k_spktimes, t_range, sigma_kernel, dt);  %  spkout=sdf(tspk, spkin, kernel_width
            press_sdfs{k_}               =       single([tspk' spkout']); % optimize
            t_range                      =      [k_trigger-pre.trigger*1000 k_poke+post.poke*1000];
            k_spktimes                   =      spktimes(spktimes>=t_range(1) & spktimes<=t_range(2));
            k_spktimes                   =      k_spktimes-k_trigger; %  time aligned to trigger time
            release_spktrains{k_}        =      k_spktimes; % spk train saved to a cell array.
            % document the relative timings
            rel_timing                   =      [0 k_release-k_trigger k_poke-k_release];
            release_event_seqs_all       =      [release_event_seqs_all; rel_timing];
            [spkout, tspk]               =      sdf25(k_spktimes, t_range-k_trigger, sigma_kernel, dt);  %  spkout=sdf(tspk, spkin, kernel_width)
            release_sdfs                 =      [release_sdfs, single([tspk' spkout'])]; % optimize
        end
    end

    press_spktrains_all{ind_FP}          =      press_spktrains;
    press_sdfs_all{ind_FP}               =      press_sdfs;
    press_release_seqs_all{ind_FP}       =      press_release_seqs_;
    release_spktrains_all{ind_FP}        =      release_spktrains;
    release_sdfs_all{ind_FP}             =      release_sdfs;
    
end
warpOut.unit.times =spktimes;
warpOut.unit.vector ={uint32(tSpk), spkVec'}; % optimize
warpOut.unit.autoCorrelation = {lags, ar'};

warpOut.raster.eventSequenceLabels          =   {'press', 'trigger', 'release', 'poke'};
warpOut.raster.eventSequence                =    press_release_seqs_all;
warpOut.raster.explained                    =      'These are press-related spike trains and sdfs, each cell is a FP';
warpOut.raster.press                        =     press_spktrains_all;
warpOut.raster.trigger                      =     release_spktrains_all;
warpOut.sdf.code                            =      {'sdf25(k_spktimes, t_range-k_trigger, sigma_kernel, dt);'};

warpOut.sdf.sigma = sigma_kernel;
warpOut.sdf.binSize = dt;
warpOut.sdf.press.all                       =     press_sdfs_all;
warpOut.sdf.trigger.all                     =     release_sdfs_all;

press_sdf_FPs                               =           cell(1, length(press_sdfs_all));
press_sdf_FPs_mean_ci                       =           cell(1, length(press_sdfs_all));
press_sdf_pooled = [];

% press sdf can be pooled across different FPs (it doesn't matter since the
% event stays the same for short or long FP)
for ii =1:length(press_sdfs_all)
    for jj = 1:length(press_sdfs_all{ii})
        press_sdf_pooled = [press_sdf_pooled press_sdfs_all{ii}{jj}(:, 2)];
        press_sdf_FPs{ii} = [press_sdf_FPs{ii} press_sdfs_all{ii}{jj}(:, 2)];
     end
    press_sdf_FPs_mean_ci{ii} = [press_sdfs_all{ii}{1}(:, 1)/1000 mean(press_sdf_FPs{ii}, 2) transpose(bootci(1000, @mean, press_sdf_FPs{ii}'))];
end

 warpOut.sdf.press.mean                      =       press_sdf_FPs_mean_ci;
 warpOut.sdf.press.meanLabels                =       {'time (s)', 'mean', '95% ci'};

 warpOut.sdf.press.pooled.all                =       single(press_sdf_pooled); % optimize
 warpOut.sdf.press.pooled.time               =      press_sdfs_all{1}{1}(:, 1)/1000;
 warpOut.sdf.press.pooled.mean               =    mean(press_sdf_pooled, 2);
 warpOut.sdf.press.pooled.ci                 =          transpose(bootci(1000, @mean, press_sdf_pooled'));
 
% 2025.08.11 We should also warp sdf for each FPs, aligned to press time. 
warpOut.sdf.warped = [];

pre_press = 2.5; % in seconds
post_poke = 1.5;

for i =1:length(warpOut.sdf.press.all)
    i_event_sequence = warpOut.raster.eventSequence{i};
    i_sdf_thisFP = warpOut.sdf.press.all{i};
    t_sdf = warpOut.sdf.press.mean{i}(:, 1);

    % compute median value of trigger-to-release latency, and
    % release-to-poke latency

    rt_median                           =       round(median(i_event_sequence(:, 3)-i_event_sequence(:, 2)));
    retrieval_median                    =       round(median(i_event_sequence(:, 4)-i_event_sequence(:, 3)));

    sdf_before_trigger_warped_collected =       []; % we don't warp this part
    sdf_trigger_release_warped_collected =      [];

    target_time_rt                       =       (1:rt_median)+FPs(i); % warp to this time timeplate
    sdf_release_poke_warped_collected    =      [];
    target_time_poke                     =       (rt_median+1:rt_median+retrieval_median)+FPs(i); % warp to this time timeplate
    sdf_after_poke_warped_collected      =      [];
    target_time = [-pre_press*1000:FPs(i) target_time_rt target_time_poke rt_median+retrieval_median+FPs(i)+1:rt_median+retrieval_median+FPs(i)+post_poke*1000];

    event_times = [];
    % for each trial (sdf), warp to this median time:
    for j =1:length(i_sdf_thisFP)

        sdf_j   = i_sdf_thisFP{j}(:, 2);
        t_sdf_j = i_sdf_thisFP{j}(:, 1);
        % reaction time and retrieval duration of this trial
        rt_j = diff(i_event_sequence(j, [2 3]));
        retrieval_j = diff(i_event_sequence(j, [2 4])); % from trigger to retrieval 

        % before trigger, no warping necessary
        if t_sdf_j(1)>-pre_press*1000 || t_sdf_j(end)<diff(i_event_sequence(j, [1 4]))+post_poke*1000
            continue
        end

        ind = t_sdf_j<= FPs(i)& t_sdf_j>=-pre_press*1000;
        sdf_before_trigger = sdf_j(ind);
        t_before_trigger = t_sdf_j(ind);
        sdf_before_trigger_warped_collected = [sdf_before_trigger_warped_collected; sdf_before_trigger'];

        % from trigger to release, warp
        ind = t_sdf_j>FPs(i) & t_sdf_j<=FPs(i)+rt_j;
        sdf_trigger_release = sdf_j(ind);
        t_trigger_release = t_sdf_j(ind);
        sdf_trigger_release_warped = Spikes.SRT.warp_sdf(t_trigger_release, sdf_trigger_release, target_time_rt);
        sdf_trigger_release_warped_collected = [sdf_trigger_release_warped_collected; sdf_trigger_release_warped];

        % from release to poke, warp
        ind = t_sdf_j>FPs(i)+rt_j & t_sdf_j<=FPs(i)+retrieval_j;

        sdf_release_poke = sdf_j(ind);
        t_release_poke = t_sdf_j(ind);
        sdf_release_poke_warped = Spikes.SRT.warp_sdf(t_release_poke, sdf_release_poke, target_time_poke);
        sdf_release_poke_warped_collected = [sdf_release_poke_warped_collected; sdf_release_poke_warped];

        % after poke (1 sec inlcuded), no warping necessary
        ind = t_sdf_j> diff(i_event_sequence(j, [1 4])) & t_sdf_j<= diff(i_event_sequence(j, [1 4]))+post_poke*1000;
        sdf_after_poke = sdf_j(ind);
        t_after_poke = t_sdf_j(ind);

        sdf_after_poke_warped_collected = [sdf_after_poke_warped_collected; sdf_after_poke'];

        event_times = [event_times; rt_j retrieval_j];
    end

    sdf_warped = [sdf_before_trigger_warped_collected sdf_trigger_release_warped_collected sdf_release_poke_warped_collected sdf_after_poke_warped_collected];

    warpOut.sdf.warped(i).FP = FPs(i);
    warpOut.sdf.warped(i).sdf_all = single(sdf_warped); % optimize
    warpOut.sdf.warped(i).event_times_all = event_times;
    warpOut.sdf.warped(i).t_sdf = target_time;
    warpOut.sdf.warped(i).sdf_mean = mean(sdf_warped, 1);
    warpOut.sdf.warped(i).sdf_ci = bootci(1000, @mean, sdf_warped);
    warpOut.sdf.warped(i).rt_median_ms = rt_median;
    warpOut.sdf.warped(i).retrieval_median_ms = retrieval_median;
    warpOut.sdf.warped(i).pre_press_ms = 1000*pre_press;
    warpOut.sdf.warped(i).post_poke_ms = 1000*post_poke;

end

% merge different FPs for activity coupled to trigger
% these should be the same size
release_spktrains_all = horzcat(release_spktrains_all{:});
release_sdfs_all = horzcat(release_sdfs_all{:});
% Calculate the median value of trigger-to-release latency and
% release-to-poke latency
post.poke = 1.5;

rt_median                           =       round(median(release_event_seqs_all(:, 2)));
retrieval_median                    =       round(median(release_event_seqs_all(:, 3)));
target_time_trigger                 =       (-pre.trigger*1000:-1);
target_time_rt                      =       (0:rt_median);
target_time_retreival               =       (rt_median+1:retrieval_median+rt_median);
target_time_postpoke                =       (retrieval_median+rt_median+1:retrieval_median+rt_median+post.poke*1000);
target_time                         =       [target_time_trigger target_time_rt target_time_retreival target_time_postpoke];
release_sdfs_warped                 =       [];

for ii =1:length(release_sdfs_all)
    t_ii                =   release_sdfs_all{ii}(:, 1);
    sdf_ii              =   release_sdfs_all{ii}(:, 2);
    ii_rt               = release_event_seqs_all(ii, 2);
    ii_retrieval        = release_event_seqs_all(ii, 3);
    ind_preTrigger      = find(t_ii<=target_time_trigger(end));
    sdf_ii_preTrigger   = sdf_ii(ind_preTrigger); % won't warp
    ind_Release         = find(t_ii>=0 & t_ii<=ii_rt);
    t_ii_Release        = t_ii(ind_Release);
    sdf_ii_Release      = sdf_ii(ind_Release); % warp to target_time_rt
    % function vw = warp_sdf(t1, v1, tw)
    sdf_ii_Release_warped = Spikes.SRT.warp_sdf(t_ii_Release, sdf_ii_Release, target_time_rt);
    ind_Poke            = find(t_ii>=ii_rt+1 & t_ii<=ii_rt+ii_retrieval);
    t_ii_Poke           = t_ii(ind_Poke);
    sdf_ii_Poke         = sdf_ii(ind_Poke); % warp to target_time_rt
    % function vw = warp_sdf(t1, v1, tw)
    sdf_ii_Poke_warped = Spikes.SRT.warp_sdf(t_ii_Poke, sdf_ii_Poke, target_time_retreival);
    % post poke activity, not warped.
    ind_PostPoke            = find(t_ii>(ii_retrieval+ii_rt));
    ind_PostPoke            = ind_PostPoke(1:length(target_time_postpoke));
    sdf_ii_PostPoke         = sdf_ii(ind_PostPoke); % warp to target_time_rt
    % put them together
    sdf_ii_warped = [sdf_ii_preTrigger; sdf_ii_Release_warped'; sdf_ii_Poke_warped'; sdf_ii_PostPoke];
    release_sdfs_warped = [release_sdfs_warped sdf_ii_warped];
end

warpOut.sdf.trigger.pooled.warped.time                     = target_time'/1000;
warpOut.sdf.trigger.pooled.warped.all                       = single(release_sdfs_warped); % optimize
warpOut.sdf.trigger.pooled.warped.mean                  = mean(release_sdfs_warped, 2); % mean(release_sdfs_warped, 2)‘;
warpOut.sdf.trigger.pooled.warped.ci                        = transpose(bootci(1000, @mean, release_sdfs_warped'));
warpOut.sdf.trigger.pooled.warped.rt_retrieval           =  [rt_median, retrieval_median];

end