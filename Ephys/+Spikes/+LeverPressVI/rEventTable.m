function [event_table, t_portin] = rEventTable(r, vb)
%REVENTTABLELEVERPRESSVI 此处显示有关此函数的摘要
%   r: ephys info of the session
%   vb: leverpressVi Behavior processed data

arguments
    r
    vb = []
end

if isempty(vb)
    dirVB = dir('vb_*.mat');
    dirBPOD = dir('*LeverPressVI*.mat');
    if ~isempty(dirVB)
        load(dirVB.name,'vb');
    elseif ~isempty(dirBPOD)
        vb = Behavior.LeverPressVI.track_training(dirBPOD.name);
    else
        error('LeverPressVI behavior data needed!');
    end
end

rb = r.Behavior;
bt = vb.EventTable; % behavior table
%% EventTime in Ephys
% Presses
ind_press = find(strcmp(rb.Labels, 'LeverPress'));
t_presses = shape_it(rb.EventTimings(rb.EventMarkers == ind_press));
disp(['Number of presses is ' num2str(length(t_presses))])
% Release
ind_release = find(strcmp(rb.Labels, 'LeverRelease'));
t_releases = Spikes.SRT.shape_it(rb.EventTimings(rb.EventMarkers == ind_release));
% Poke-in
ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
t_portin = shape_it(rb.EventTimings(rb.EventMarkers == ind_portin));
% Valve
ind_valve = find(strcmp(rb.Labels, 'ValveOnset'));
t_valve = shape_it(rb.EventTimings(rb.EventMarkers == ind_valve));

ind_valveoff = find(strcmp(rb.Labels, 'ValveOffset'));
t_valveoff = shape_it(rb.EventTimings(rb.EventMarkers == ind_valveoff));

if isempty(t_portin)
    t_portin = t_valve;
end
%% EventTime in Bpod
t_presses_bpod = bt.t_press;
t_releases_bpod = bt.t_release;
ht_bpod = bt.t_release-bt.t_press;
idxPokeFirst = find(~isnan(bt.t_poke_first));
idxPortExit = find(~isnan(bt.t_port_exit));
t_pokefirst_bpod = bt.t_poke_first(idxPokeFirst);
t_portexit_bpod = bt.t_port_exit(idxPortExit);
%% Match press & construct the basic event_table
t_presses_ephys = t_presses./1000; % to second
ind_press_matched = findseqmatchrev(t_presses_bpod, t_presses_ephys, 0, 0, 0);
ind_bpodrow_matched = ind_press_matched(~isnan(ind_press_matched));

t_presses_ephys_matched = t_presses_ephys(~isnan(ind_press_matched)).*1000;
% get matched events in bpod
t_presses_bpod_matched = t_presses_bpod(ind_bpodrow_matched);
t_releases_bpod_matched = t_releases_bpod(ind_bpodrow_matched);
ht_bpod_matched = ht_bpod(ind_bpodrow_matched);

idxPokeFirst = idxPokeFirst(ismember(idxPokeFirst, ind_bpodrow_matched));
idxPortExit = idxPortExit(ismember(idxPortExit, ind_bpodrow_matched));
t_pokefirst_bpod_matched = bt.t_poke_first(idxPokeFirst);
t_portexit_bpod_matched = bt.t_port_exit(idxPortExit);
t_pokein_bpod_matched = cell2mat(bt.t_pokein_all(idxPokeFirst));
t_pokeout_bpod_matched = cell2mat(bt.t_pokeout_all(idxPortExit));

% I_pokein_bpod_matched = repelem( (1:numel(bt.t_pokein_all(idxPokeFirst)))', cellfun(@numel, bt.t_pokein_all(idxPokeFirst)) );
% I_pokeout_bpod_matched = repelem( (1:numel(bt.t_pokeout_all(idxPortExit)))', cellfun(@numel, bt.t_pokeout_all(idxPortExit)) );
lens_pokein_bpod_matched = cellfun(@numel, bt.t_pokein_all(idxPokeFirst));
lens_pokeout_bpod_matched = cellfun(@numel, bt.t_pokeout_all(idxPortExit));
% verify index
% a = mat2cell(t_pokein_bpod_matched, lens_pokein_bpod_matched, 1);
% b = mat2cell(t_pokeout_bpod_matched, lens_pokeout_bpod_matched, 1);


% function out = map_event_time(t_domain1, t_ref_domain1, t_ref_domain2, varargin)
out_struct = Spikes.map_event_time(t_releases_bpod_matched, t_presses_bpod_matched, t_presses_ephys_matched,...
    'Extrapolation','linear');
t_releases_bpod2ephys = out_struct.t_domain2; % convert to ms

out_struct = Spikes.map_event_time(t_pokefirst_bpod_matched, t_presses_bpod_matched, t_presses_ephys_matched,...
    'Extrapolation','linear');
t_pokefirst_bpod2ephys = out_struct.t_domain2; % convert to ms

out_struct = Spikes.map_event_time(t_portexit_bpod_matched, t_presses_bpod_matched, t_presses_ephys_matched,...
    'Extrapolation','linear');
t_portexit_bpod2ephys = out_struct.t_domain2; % convert to ms

out_struct = Spikes.map_event_time(t_pokein_bpod_matched, t_presses_bpod_matched, t_presses_ephys_matched,...
    'Extrapolation','linear');
t_pokein_bpod2ephys = out_struct.t_domain2; % convert to ms
t_pokein_bpod2ephys_cell = mat2cell(t_pokein_bpod2ephys, lens_pokein_bpod_matched, 1);

out_struct = Spikes.map_event_time(t_pokeout_bpod_matched, t_presses_bpod_matched, t_presses_ephys_matched,...
    'Extrapolation','linear');
t_pokeout_bpod2ephys = out_struct.t_domain2; % convert to ms
t_pokeout_bpod2ephys_cell = mat2cell(t_pokeout_bpod2ephys, lens_pokeout_bpod_matched, 1);

event_table = bt;
event_table.Properties.VariableNames{'press_index'} = 'BPOD_index';
event_table.t_press(ind_bpodrow_matched) = t_presses_ephys_matched;
event_table.t_release(ind_bpodrow_matched) = t_releases_bpod2ephys;
event_table.t_poke_first(idxPokeFirst) = t_pokefirst_bpod2ephys;
event_table.t_port_exit(idxPortExit) = t_portexit_bpod2ephys;
event_table.t_pokein_all(idxPokeFirst) = t_pokein_bpod2ephys_cell;
event_table.t_pokeout_all(idxPortExit) = t_pokeout_bpod2ephys_cell;
event_table.valve_time = event_table.valve_time.*1000;
event_table = event_table(ind_bpodrow_matched,:); % 只保留匹配了的数据
event_table = addvars(event_table,t_presses_bpod_matched,...
    'Before','t_press','NewVariableNames', 't_press_BPOD');
event_table = addvars(event_table,(1:size(event_table,1))',...
    'Before','BPOD_index','NewVariableNames','press_index');
event_table = addvars(event_table,nan(size(event_table.t_poke_first)),...
    'After','t_poke_first','NewVariableNames','t_valve');

has_valve = contains(event_table.reward,'Rewarded');
t_poke_rewarded = event_table.t_poke_first(has_valve);
t_valve_fromPoke = event_table.t_valve; 
t_valve_fromPoke(has_valve) = t_poke_rewarded;
% event_table.t_valve(has_valve) = t_poke_rewarded;
%% Find the event time in ephys and replace the mapped time from bpod
search_win = 20; % 毫秒。如果 Ephys 信号在映射点 20ms 内，就认为它是对应的原始信号
search_win_loose = 1000; % for time_from_last_reward, using the loose rule

% 1. 替换 Release
% 逻辑：在原始 t_releases 序列里，找离 event_table.t_release 最近的点
[idx_release, dist_release] = knnsearch(t_releases, event_table.t_release); 
% knnsearch 是 MATLAB 寻找最近点最高效的函数
% idx 是 t_releases 的索引，dist 是距离（ms）
valid_rel = dist_release < search_win; % 只有偏差小于窗口的才认为是真的对上了
event_table.t_release(valid_rel) = t_releases(idx_release(valid_rel));

% 2. 替换 Poke (Ephys只有poke-in)
% 逻辑：同理，只替换那些有映射值且能找到原始对应点的
% (t_poke_first)
has_poke = ~isnan(event_table.t_poke_first);
% [idx_p, dist_p] = knnsearch(t_portin, event_table.t_poke_first);
% valid_poke = (dist_p < search_win) & has_poke;
% event_table.t_poke_first(valid_poke) = t_portin(idx_p(valid_poke));

[idx_p, dist_p] = knnsearch(t_portin, t_pokein_bpod2ephys);
valid_poke = dist_p < search_win;
t_pokein_bpod2ephys(valid_poke) = t_portin(idx_p(valid_poke));
t_pokein_bpod2ephys_cell2 = mat2cell(t_pokein_bpod2ephys, lens_pokein_bpod_matched, 1);
event_table.t_pokein_all(idxPokeFirst) = t_pokein_bpod2ephys_cell2;
event_table.t_poke_first(has_poke) = cellfun(@(x)x(1), event_table.t_pokein_all(has_poke));

% 3. 替换 Valve
% valve onset
[idx_p, dist_p] = knnsearch(t_valve, t_valve_fromPoke);
valid_valve = (dist_p < search_win) & has_valve;
event_table.t_valve(valid_valve) = t_valve(idx_p(valid_valve));

% 4. 替换 time_from_last_reward
t_valve_real = event_table.t_valve(~isnan(event_table.t_valve));

% 使用 interp1 的 'previous' 模式进行查找
% 它的逻辑是：对于每个 t_press，在 t_valve_real 中找到最后一个小于它的值
if ~isempty(t_valve_real)
    last_reward_time = interp1(t_valve_real, t_valve_real, event_table.t_press, 'previous');
    % 计算时间差
    % 如果 press 发生在第一个 reward 之前，结果会是 NaN
    time_from_last_reward_ephys = event_table.t_press - last_reward_time;
    time_from_last_reward_bpod = event_table.time_from_last_reward.*1000;
    isMatched_reward_history = abs(time_from_last_reward_bpod - time_from_last_reward_ephys)<search_win_loose; % 1 s内视为匹配
    
    time_from_last_reward = time_from_last_reward_bpod;
    time_from_last_reward(isMatched_reward_history) = time_from_last_reward_ephys(isMatched_reward_history);
    
    event_table.time_from_last_reward = time_from_last_reward;
end

end