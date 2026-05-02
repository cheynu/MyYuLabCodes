function WarpOut = ComputeSDFWarped(r, id)
% 3.9.2024 plot a simple version of PSTH
% 4/23/2024 Plot warped PSTH
% 5/15/2025 

%%
% figure out which unit it is
spk_note = r.Units.SpikeNotes;
ind_unit = find(spk_note(:, 1)==id(1) & spk_note(:, 2)==id(2));
spkwave  = r.Units.SpikeTimes(ind_unit).wave;
spktimes = r.Units.SpikeTimes(ind_unit).timings; % in ms
spktimes_ = zeros(1, ceil(max(spktimes)));
spktimes_(round(spktimes)) = 1;
[ar, lags]  = xcorr(spktimes_, 25);
ar(lags==0) = 0;

FPs    = r.BehaviorClass.TargetFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
FPs    = FPs(FPs>0);
NumFPs = length(FPs);

Ports    = r.BehaviorClass.LeftRight;
NumPorts = length(Ports);

%% Plot press
% the whole duration of time warp
pre_  = 2.5; % 2.5 sec before cent-in, about the lower boundary of shuttle time
post_ = 3; % 2.5 sec after choice
post_keep = 2.5;

warped_time_points = cell(NumFPs, NumPorts);

spikes_trials = cell(1000, 4); % contains most data, 1:[cent-in cent-out choice]; 2:spike times in this duration; 3:iFP; 4:iPort
n_count = 0;
latency = 2.5; % max cent-out to choice latency (max movement time)

ind_correct = r.PSTH.Events.CentIn.Labels=="Correct";
for i = 1:NumFPs
    i_fp = FPs(i);
    for j = 1:NumPorts
        j_port = Ports(j);

        % order by behavior time
        trial_id      = sort(r.PSTH.Events.CentIn.TrialID{ind_correct}{i,j});
        centin_times  = sort(r.PSTH.Events.CentIn.Time{ind_correct}{i,j});
        centout_times = sort(r.PSTH.Events.CentOut.Time{ind_correct}{i,j});
        choice_times  = sort(r.PSTH.Events.ChoiceIn.RewardPoke.Time{i,j});

        % cent-in times and cent-out times should be matched in num. this is what
        % we stretch
        hold_pairs = [(centin_times), (centout_times)];
        ioc_seq = []; % n*3 matrix, cent(I)n - cent(O)ut - (C)hoice sequence (each row represents a trial)
        ioc_spktimes = {}; % 1*n cell, each entry is a matrix of spike times within warping range
        ioc_sdfs = {}; % 1*n cell, each 
    
        ind_valid = false(length(centin_times), 1);
        % check if a choice-poke follows cent-out time, if not, we won't include it
        for k = 1:size(hold_pairs, 1)
            k_centout = hold_pairs(k, 2);
            % where is the choice poke
            k_choice = choice_times(find(choice_times>k_centout, 1, 'first'));

            if ~isempty(k_choice) && isempty(find(centin_times>k_centout & centin_times<k_choice, 1)) && (k_choice-k_centout<latency*1000)
                % if there is a choice poke after cent-out && there is no
                % cent-in between cent-out and choice poke && there is a
                % choice poke within a certain latency after cent-out
                ind_valid(k) = true;

                ioc_seq   = [ioc_seq; hold_pairs(k,:) k_choice];
                total_dur = round(k_choice-hold_pairs(k,1)) + pre_*1000 + post_*1000; % the unit is ms, [pre, from cent-in to choice, post]
                this_spk_train = spktimes(spktimes>=hold_pairs(k,1)-pre_*1000 & spktimes<=k_choice+post_*1000);
                ioc_spktimes = [ioc_spktimes {this_spk_train}];

                % save this sequence
                n_count = n_count + 1;
                spikes_trials(n_count,:) = {ioc_seq(k,:), this_spk_train, i_fp, j_port};
    
                % map spike times to spike matrix, then calculate spike density function
                tsdf = (0:total_dur-1) - pre_*1000; % in ms
                spkmat = zeros(1, total_dur); % each entry represents for 1 ms
                if ~isempty(this_spk_train)
                    % align to cent-in
                    this_spk_train = this_spk_train - (hold_pairs(k,1));
                    [~, ind_spikes] = intersect(round(tsdf), round(this_spk_train));
                    spkmat(ind_spikes) = 1;
                end
                % convert the spike train to sdf
                sdfout   = sdf(tsdf/1000, spkmat, 20); % spkout = sdf(tspk, spkin, kernel_width)
                ioc_sdfs = [ioc_sdfs [tsdf; sdfout']]; % ioc_sdfs is a cell
            end
        end
    
        % let's warp this thing
        median_hold_duration = median(ioc_seq(:,2)-ioc_seq(:,1)); % median, in ms
        median_movement_time = median(ioc_seq(:,3)-ioc_seq(:,2)); % median, in ms
    
        % jt_template has the following structures: end of FP, median hold
        % duration, median movement time
        jt_template = [0 i_fp*1000 median_hold_duration median_movement_time+median_hold_duration]; % [cent-in, trigger, cent-out, choice] in ms
        warped_time_points{i, j} = jt_template;
        dt = 1; % 1 ms
        jt_target_time = (0:dt:median_movement_time+median_hold_duration);
        sprintf('Critical time points are %2.2f\n', jt_template(1), jt_template(2), jt_template(3), jt_template(4));
        t_warptarget_first  = jt_target_time(jt_target_time>=i_fp*1000 & jt_target_time<jt_template(3)); % from trigger to cent-out
        t_warptarget_second = jt_target_time(jt_target_time>=jt_template(3) & jt_target_time<jt_template(4)); % from cent-out to choice

        ioc_spk_warped{i, j} = [];
        for k = 1:size(ioc_seq) % for each trial
            % jt is [cent-in, cent-out, choice]
            jt = ioc_seq(k, :) - ioc_seq(k, 1); % normalize so that the first point is time 0
            jsdf = ioc_sdfs{k};
            tsdf = jsdf(1, :); % this is the time of sdf, defined previously as: tspk = (0:total_dur-1)-pre_*1000; % in ms
            jsdf = jsdf(2, :); % this is the sdf

            not_warped = jsdf(tsdf<i_fp*1000);

            towarp_first   = jsdf(tsdf>=i_fp*1000 & tsdf<jt(2)); % from trigger to cent-out
            t_towarp_first = tsdf(tsdf>=i_fp*1000 & tsdf<jt(2)); % from trigger to cent-out
            towarp_second   = jsdf(tsdf>=jt(2) & tsdf<jt(3)); % from cent-out to choice
            t_towarp_second = tsdf(tsdf>=jt(2) & tsdf<jt(3)); % from cent-out to choice

            not_warped2 = jsdf(tsdf>=jt(3));
            not_warped2 = not_warped2(1:post_keep*1000); % max 2.5 sec after choice poke
    
            dt = 1; % 1 ms
            if ~isempty(t_towarp_first) && ~isempty(t_towarp_second)
                sdf_warped_first  = SpikesGPS.SRT.warp_sdf(t_towarp_first, towarp_first, t_warptarget_first); % input is V, X, and duration to warp
                sdf_warped_second = SpikesGPS.SRT.warp_sdf(t_towarp_second, towarp_second, t_warptarget_second);
                new_sdf = [not_warped, sdf_warped_first, sdf_warped_second, not_warped2];
                ioc_spk_warped{i, j} = [ioc_spk_warped{i, j}; new_sdf];
            end
        end
    
        t_warped{i, j} = (-pre_*1000:dt:length(new_sdf)-pre_*1000-dt);
    end
end

spks = spkwave;
tsdf = (1:size(spks, 2))/30; % in ms
spk_mean = mean(spks, 1);
spk_std = std(spks, 0, 1);

sdf_warped_ci = cell(NumFPs, NumPorts);
sdf_warped_mean = cell(NumFPs, NumPorts);
for i = 1:NumFPs
    for j = 1:NumPorts
        if size(ioc_spk_warped{i,j}, 1)>10
            sdf_warped_ci{i,j} = bootci(1000, @mean, ioc_spk_warped{i,j});
        end
        sdf_warped_mean{i,j} = mean(ioc_spk_warped{i,j}, 1);
    end
end

%%
this_unit = r.BehaviorClass.Subject + '|Session' + r.BehaviorClass.Session + '|Ch' + num2str(id(1)) + '|Unit' + num2str(id(2));

% Pack output
WarpOut.meta.unit_name = this_unit;
WarpOut.meta.subject   = r.BehaviorClass.Subject;
WarpOut.meta.session   = r.BehaviorClass.Session;
WarpOut.meta.Channel   = num2str(id(1));
WarpOut.meta.Unit      = num2str(id(2));
% press_psth = {t_spkmat, sdf_press_mean, sdf_press_ci};
% psth_info_explained = 'time, sdf_mean, sdf_ci';
% WarpOut.psth_explained = psth_info_explained;
% WarpOut.press_psth = press_psth;
% WarpOut.press_raster = centin_raster;
% WarpOut.release_psth = release_psth;
% WarpOut.release_raster = release_raster;
% WarpOut.poke_psth = poke_psth;
% WarpOut.poke_raster = poke_raster;
WarpOut.spike_waveform        = {tsdf, tsdf, spk_mean, spk_std};
WarpOut.spikes_trials         = spikes_trials;
WarpOut.spike_train_explained = {'[cent-in, cent-out, choice] times', 'spk times', 'FPs', 'Ports'};
WarpOut.twarp                 = t_warped;
WarpOut.sdf_all               = ioc_spk_warped;
WarpOut.sdf_avg               = sdf_warped_mean;
WarpOut.sdf_ci                = sdf_warped_ci;
WarpOut.median_time_points    = warped_time_points;
WarpOut.pre_post_durations    = [pre_, post_, post_keep];
% WarpOut.warp2 = warp_out;

end