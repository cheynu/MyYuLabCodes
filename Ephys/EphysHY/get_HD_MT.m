function [medianHD, medianMT] = get_HD_MT(r, unit_of_interest, is_only_first_session)
    t_start = NaN;
    t_end = NaN;

    if isempty(unit_of_interest)
        medianHD = [];
        medianMT = [];
        return
    end

    if is_only_first_session
        t_start = get_t_start_session(r,1);
        t_end = get_t_end_session(r,1);
    end

    if isnan(t_start)
        t_start = get_t_start_session(r, 1);
    end
    if isnan(t_end)
        t_end = get_t_end_session(r, length(r.Meta));
    end

    FPs = r.BehaviorClass.MixedFP;
    FP = max(FPs);

    % pick correct trials and separate long-FP/short-FP trials
    ind_press = find(strcmp(r.Behavior.Labels, 'LeverPress'));
    t_presses = round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_press));
    ind_release = find(strcmp(r.Behavior.Labels, 'LeverRelease'));
    t_releases = round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_release));
    ind_rewards = find(strcmp(r.Behavior.Labels, 'ValveOnset'));
    t_rewards= round(r.Behavior.EventTimings(r.Behavior.EventMarkers == ind_rewards));

    idx_correct = r.Behavior.CorrectIndex;
    idx_in_time_range = find(t_presses > t_start & t_presses < t_end);
    idx_uncued = find(r.Behavior.CueIndex(:,2)==0);

    idx_included = intersect(idx_correct, idx_in_time_range);
    idx_included = sort(intersect(idx_included, idx_uncued));

    HD_all = [];
    MT_all = [];
    for k = 1:length(idx_included)
        idx_this = idx_included(k);
        t_press_this = t_presses(idx_this);
        t_release_this = t_releases(idx_this);
        t_foreperiod = t_press_this + FP;

        if t_release_this<t_foreperiod
            disp(t_release_this-t_foreperiod);
            warning('Wrong release time!');
            continue
        end

        t_reward_this = t_rewards(find(t_rewards>t_release_this, 1));
        if isempty(t_reward_this)
            continue
        end
        if idx_this < length(t_presses) && t_reward_this > t_presses(idx_this + 1)
            continue
        end

        if t_reward_this-t_release_this > 3000
            continue
        end
        
        HD_all = [HD_all, t_release_this-t_press_this];
        MT_all = [MT_all, t_reward_this-t_release_this];
    end

    medianHD = median(HD_all)*ones(1,length(unit_of_interest));
    medianMT = median(MT_all)*ones(1,length(unit_of_interest));
end