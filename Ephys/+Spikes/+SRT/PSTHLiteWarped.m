function WarpOut = PSTHLiteWarped(r, id)
% 3.9.2024 plot a simple version of PSTH
% 4/23/2024 Plot warped PSTH
% 4/25/2024 revised such that activity between [0 FP] is not warped
% same as PlotPSTHLiteWarped but no plotting

% figure out which unit it is
spk_note =r.Units.SpikeNotes;
ind_unit = find(spk_note(:, 1)==id(1) & spk_note(:, 2)==id(2));
spkwave = r.Units.SpikeTimes(ind_unit).wave;
spktimes = r.Units.SpikeTimes(ind_unit).timings; % in ms
spktimes_ = zeros(1, ceil(max(spktimes)));
spktimes_(round(spktimes)) = 1;
[ar, lags]=xcorr(spktimes_, 25);
ar(lags==0)=0;
FPs = r.PopPSTH.FPs;

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


%% Plot press
sdf_press_mean = cell(1,nFPs);
sdf_press_ci = cell(1, nFPs);
pre_  = 2; % 3 sec before press
post_ = 5; % 2 sec after poke
post_keep = 2;

warped_time_points = cell(1, nFPs);
for ind_FP = 1:nFPs
    press_times              =  sort(r.PSTH.Events.Presses.Time{ind_FP});
    release_times           =  sort(r.PSTH.Events.Releases.Time{ind_FP});
    poke_times               =  sort(r.PSTH.Events.Pokes.RewardPoke.Time{ind_FP});
    reaction_times         = r.PSTH.PSTHs(ind_unit).Presses{ind_FP}{6};
    iFP                               = FPs(ind_FP);
    % press times and release times should be matched in num. this is what
    % we stretch
    press_pairs = [(press_times) (release_times)];
    prp_seq = [];
    prp_spktimes = {};
    prp_sdfs = {};    
    % check if a poke follows release time, if not, we won't include it
    for j =1:size(press_pairs, 1)
        j_release = press_pairs(j, 2);
        % where is the poke
        j_poke = poke_times(find(poke_times>j_release, 1, 'first'));
        if ~isempty(j_poke) && isempty(find(press_times>j_release & press_times<j_poke, 1))
            prp_seq  = [prp_seq; press_pairs(j, :) j_poke];
            total_dur = round(j_poke-press_pairs(j, 1))+pre_*1000+post_*1000; % the unit is ms
            this_spk_train = spktimes(spktimes>=press_pairs(j, 1)-pre_*1000 & spktimes<=j_poke+post_*1000);
            prp_spktimes = [prp_spktimes {this_spk_train}];
            if ~isempty(this_spk_train)
                this_spk_train = this_spk_train-(press_pairs(j, 1));
                % convert the spike train to sdf
                tspk = (0:total_dur-1)-pre_*1000; % in ms
                spkmat = zeros(1, total_dur);
                [~, ind_spikes]=intersect(round(tspk), round(this_spk_train)); 
                spkmat(ind_spikes) = 1;
                spkout=sdf(tspk/1000, spkmat, 20);  %  spkout=sdf(tspk, spkin, kernel_width)
                prp_sdfs = [prp_sdfs [tspk; spkout']];
            else
                tspk = (0:total_dur-1)-pre_*1000; % in ms
                spkmat = zeros(1, total_dur);
                spkout=sdf(tspk/1000, spkmat, 20);  %  spkout=sdf(tspk, spkin, kernel_width)
                prp_sdfs = [prp_sdfs [tspk; spkout']];
            end
        end
    end    
    % let's warp this thing
    median_hold_duration     = median(prp_seq(:,2)-prp_seq(:,1)); % median, in ms
    median_movement_time = median(prp_seq(:,3)-prp_seq(:,2)); % median, in ms
    % jt_template has the following structures: end of FP, median hold
    % duration, median poke time
    jt_template = [0 iFP median_hold_duration median_movement_time+median_hold_duration];
    warped_time_points{ind_FP} = jt_template;
    dt=1; % 1 ms
    jt_target_time = (0:dt:median_movement_time+median_hold_duration);
    sprintf('Critical time points are %2.2f\n',jt_template(1), jt_template(2), jt_template(3),jt_template(4));
    % 
    t_warptarget_first = jt_target_time(jt_target_time>=iFP& jt_target_time<jt_template(3)); % from tone to release
    t_warptarget_second = jt_target_time(jt_target_time>=jt_template(3)& jt_target_time<jt_template(4)); % from press to release
    prp_spk_warped{ind_FP} = [];
    
    for j =1:size(prp_seq,1)
        % jt is [press, release, poke]
        jt = prp_seq(j, :)-prp_seq(j, 1);   % normalize so that the first point is time 0
        jsdf = prp_sdfs{j};
        tsdf = jsdf(1, :);                              % this is the time of sdf, defined previously as   tspk = (0:total_dur-1)-pre_*1000; % in ms
        jsdf = jsdf(2, :);                              % this is the sdf
        not_warped = jsdf(tsdf<iFP);
        %        sprintf('pre-press duration is %2.2f ms', length(not_warped))
        towarp_first = jsdf(tsdf>=iFP& tsdf<jt(2)); % from FP to release
        t_towarp_first = tsdf(tsdf>=iFP& tsdf<jt(2)); % from FP to release
        towarp_second = jsdf(tsdf>=jt(2)& tsdf<jt(3)); % from release to poke
        t_towarp_second = tsdf(tsdf>=jt(2)& tsdf<jt(3)); % from press to release
        not_warped2 = jsdf(tsdf>jt(3));
        %        sprintf('post-poke duration is %2.2f ms', length(not_warped2))
        not_warped2= not_warped2(1:post_keep*1000); % max 1 sec after first poke

        dt = 1; % 1 ms
        sdf_warped_first            = Spikes.SRT.warp_sdf(t_towarp_first, towarp_first, t_warptarget_first); % input is V, X, and duration to warp
        sdf_warped_second       = Spikes.SRT.warp_sdf(t_towarp_second, towarp_second,  t_warptarget_second);
        new_sdf = [not_warped sdf_warped_first sdf_warped_second not_warped2];
        prp_spk_warped{ind_FP} = [ prp_spk_warped{ind_FP};  new_sdf]; 
    end

    t_warped{ind_FP} = (-pre_*1000:dt:length(new_sdf)-pre_*1000-dt);
    spkmat = r.PSTH.PSTHs(ind_unit).Presses{ind_FP}{3};
    t_spkmat = r.PSTH.PSTHs(ind_unit).Presses{ind_FP}{4};
     
end

sdf_warped_ci =cell(1, length(FPs));
sdf_warped_mean =cell(1, length(FPs));
for i =1:length(FPs)   
    sdf_warped_ci{i} = bootci(1000, @mean,prp_spk_warped{i});
  %  plotshaded(t_warped{i}, sdf_warped_ci{i}, [.6 .6 .6])
    sdf_warped_mean{i} = mean(prp_spk_warped{i}, 1);
   % plot(t_warped{i}, sdf_warped_mean{i}, 'linewidth', 2, 'color', FP_cols{i})
end
% xlabel('Time from press (ms)')
% ylabel('Spike rate (Hz)')
%%

this_unit = [r.BehaviorClass.Subject '|Session'  r.BehaviorClass.Date '|Ch' num2str(id(1)) '|Unit' num2str(id(2))];
% uicontrol('Style', 'text', 'unit', 'normalized', 'Position', [.01 .9 .8 .08], 'String', this_unit, 'Fontname', 'dejavu sans',...
%     'fontsize', 12, 'fontweight', 'bold', 'backgroundcolor', 'w')

%  Pack output
WarpOut.twarp         = t_warped;
WarpOut.sdf_all        = prp_spk_warped;
WarpOut.sdf_avg      = sdf_warped_mean;
WarpOut.sdf_ci          = sdf_warped_ci;
WarpOut.TimePoints = warped_time_points;
WarpOut.PrePost       = [pre_ post_ post_keep];
WarpOut.Meta            = this_unit;

