function [SDFAll, SDFTable] = ComputeSDFAll(r, id)
%
% figure out which unit it is
spk_note = r.Units.SpikeNotes;
ind_unit = find(spk_note(:, 1)==id(1) & spk_note(:, 2)==id(2));
switch spk_note(ind_unit, 3)
    case 1
        spk_quality = 'SU';
    case 2
        spk_quality = 'MU';
end

spkwave  = r.Units.SpikeTimes(ind_unit).wave;
spktimes = r.Units.SpikeTimes(ind_unit).timings; % in ms
spktimes_ = zeros(1, ceil(max(spktimes)));
spktimes_(round(spktimes)) = 1;
[ar, lags]  = xcorr(spktimes_, 25);
ar(lags==0) = 0;

spks = spkwave;
tspk = (1:size(spks, 2))/30; % in ms
spk_mean = mean(spks, 1);
spk_std  = std(spks, 0, 1);

%% Gather all
rb = r.Behavior;

id_initin  = find(strcmp(rb.Labels, 'PokeInitIn'));
id_initout = find(strcmp(rb.Labels, 'PokeInitOut'));
id_centin  = find(strcmp(rb.Labels, 'PokeCentIn'));
id_trigger = find(strcmp(rb.Labels, 'Trigger'));
id_centout = find(strcmp(rb.Labels, 'PokeCentOut'));
id_choice  = find(strcmp(rb.Labels, 'PokeChoiceIn'));

% event times in original order
t_initin  = rb.EventTimings(rb.EventMarkers==id_initin);
t_initout = rb.EventTimings(rb.EventMarkers==id_initout);
t_centin  = rb.EventTimings(rb.EventMarkers==id_centin);
t_trigger = rb.EventTimings(rb.EventMarkers==id_trigger);
t_centout = rb.EventTimings(rb.EventMarkers==id_centout);
t_choice  = rb.EventTimings(rb.EventMarkers==id_choice);

% trial information
trial_id = rb.TrialID;
outcome  = rb.Outcome;
FP       = rb.Foreperiods;
port     = rb.PortCorrect;
FP(outcome=="Probe") = Inf;

% align t_trigger and t_choice to correspond t_cent_in
n_trials = length(t_centin);
t_choice_aligned  = nan(n_trials, 1);
t_trigger_aligned = nan(n_trials, 1);
for i = 1:n_trials
    % choice
    if i < n_trials
        % choice poke should occur between cent-out and next init-in
        i_choice = find(t_choice>t_centout(i) & t_choice<t_initin(i+1), 1, 'first');
        if ~isempty(i_choice)
            t_choice_aligned(i) = t_choice(i_choice);
        end
    else
        % in the last trial, choice poke should occur after cent-out
        i_choice = find(t_choice>t_centout(i), 1, 'first');
        if ~isempty(i_choice)
            t_choice_aligned(i) = t_choice(i_choice);
        end
    end

    % trigger should occur between cent-in and cent-out
    i_trigger = find(t_trigger>t_centin(i) & t_trigger<t_centout(i), 1, 'first');
    if ~isempty(i_trigger)
        t_trigger_aligned(i) = t_trigger(i_trigger);
    end
end
t_choice  = t_choice_aligned;
t_trigger = t_trigger_aligned;

% get behavior times (in ms)
ST = t_centin - t_initout;
RT = t_centout - t_trigger;
HD = t_centout - t_centin;
MT = t_choice - t_centout;

%% get sdf of the whole trial
% from .5 sec before init-out, to 2.5 sec after choice (2.5 sec after cent-out in case there was no choice)
% the whole duration of time warp
pre_  = .5; % 0.5 sec before init-out
pre_max = 10; % if the rat took very long time for shuttling, trim it to 10 sec
pre_min = 2.5; % if the rat was too fast, set it to 2.5 sec
post_ = 3; % take 3 sec after choice/cent-out at first

t_spk_times = cell(n_trials, 1);
t_sdf_trial = cell(n_trials, 1);
sdf_trial   = cell(n_trials, 1);

for i = 1:n_trials
    i_pre = min([ST(i)/1000 + pre_, pre_max]);
    i_pre = max([i_pre, pre_min]);
    i_pre = round(i_pre*1000);

    if ~isnan(t_choice(i))
        total_dur = i_pre + round(t_choice(i)-t_centin(i)) + post_*1000; % the unit is ms, [pre, from cent-in to choice, post]
        this_spk_train = spktimes(spktimes>=t_centout(i)-i_pre & spktimes<=t_choice(i)+post_*1000);
    else
        total_dur = i_pre + round(t_centout(i)-t_centin(i)) + post_*1000; % the unit is ms, [pre, from cent-in to cent-out, post]
        this_spk_train = spktimes(spktimes>=t_centout(i)-i_pre & spktimes<=t_centout(i)+post_*1000);
    end

    % map spike times to spike matrix, then calculate spike density function
    tsdf = (0:total_dur-1) - i_pre; % in ms
    spkmat = zeros(1, total_dur); % each entry represents for 1 ms
    if ~isempty(this_spk_train)
        % align to cent-in
        this_spk_train = this_spk_train - t_centin(i);
        [~, ind_spikes] = intersect(round(tsdf), round(this_spk_train));
        spkmat(ind_spikes) = 1;
    end
    % convert the spike train to sdf
    sdfout = sdf(tsdf/1000, spkmat, 20); % spkout = sdf(tspk, spkin, kernel_width)

    t_spk_times{i} = this_spk_train;
    t_sdf_trial{i} = tsdf;
    sdf_trial{i}   = sdfout';
end

%% save whole trial sdf to strcut SDFOut
SDFAll.trial_id = trial_id;

SDFAll.t_initin  = t_initin;
SDFAll.t_initout = t_initout;
SDFAll.t_centin  = t_centin;
SDFAll.t_trigger = t_trigger;
SDFAll.t_centout = t_centout;
SDFAll.t_choice  = t_choice;

SDFAll.FP = FP;
SDFAll.Port = port;
SDFAll.Outcome = outcome;
SDFAll.ST = ST;
SDFAll.RT = RT;
SDFAll.HD = HD;
SDFAll.MT = MT;

SDFAll.t_spk_times = t_spk_times;
SDFAll.t_sdf = t_sdf_trial;
SDFAll.sdf = sdf_trial;

SDFTable = struct2table(SDFAll);

% basal information
this_unit = r.BehaviorClass.Subject + '|Session' + r.BehaviorClass.Session + '|Ch' + num2str(id(1)) + '|Unit' + num2str(id(2));
fprintf('\n*** %s ***\n', this_unit);

SDFAll.meta.unit_name = this_unit;
SDFAll.meta.subject   = r.BehaviorClass.Subject;
SDFAll.meta.session   = r.BehaviorClass.Session;
SDFAll.meta.Channel   = num2str(id(1));
SDFAll.meta.Unit      = num2str(id(2));
SDFAll.meta.Quality   = spk_quality;

SDFAll.spike_waveform.tspk     = tspk;
SDFAll.spike_waveform.spk_mean = spk_mean;
SDFAll.spike_waveform.spk_std  = spk_std;

end % ComputeSDFWarped
