function events = Bpod_Events_LeverPressVI(vb)
% 1/27/2026
% extract data from processed data
% 12/1/2025
% revised for leverpress variable interval task
% 2/20/2021
% extract events from bpod's SessionData structure
% MedLick Recording
% 10/4/2022 add AllPokeIns and AllPokesOuts. 

arguments
    vb % LeverPressVI Behavior info
end

bt = vb.EventTable;

idxGoodPress = find(contains(bt.outcome,'Good'));
idxBadPress = find(contains(bt.outcome,'Bad'));
idxRewardedPoke = find(contains(bt.reward,'Rewarded'));

events.GoodPress = bt.t_press(idxGoodPress)'; % used in leverpressVI task
events.GoodRelease = bt.t_release(idxGoodPress)'; % time of a successful lever release
events.GoodPokeIn = bt.t_poke_first(idxRewardedPoke)'; % time of port poke after a succesful lever release (reward delivered immediately)
events.Reward = [bt.t_poke_first(idxRewardedPoke)'; bt.t_poke_first(idxRewardedPoke)'+bt.valve_time(idxRewardedPoke)']; % two-row matrix, first row valve open, second row valve close

idxPokeIn = find(contains(vb.ResponsesAll.Type,'PokeIn'));
idxPokeOut = find(contains(vb.ResponsesAll.Type,'PokeOut'));
idxBadPokeIn = find(contains(vb.ResponsesAll.Type,'BadPokeIn'));
idxBadPokeOut = find(contains(vb.ResponsesAll.Type,'BadPokeOut'));

events.AllPokeIns = vb.ResponsesAll.Time(idxPokeIn)';
events.AllPokeOuts = vb.ResponsesAll.Time(idxPokeOut)';
events.AllPress = bt.t_press';
events.AllPressTypeVI = str2double(string(categorical(bt.outcome,{'Good','Bad'},["1" "-1"])))'; % 1: rewarded press, -1: bad press

events.BadPress = bt.t_press(idxBadPress)';
events.BadPokeIn = vb.ResponsesAll.Time(idxBadPokeIn)';
events.BadPokeOut = vb.ResponsesAll.Time(idxBadPokeOut)';
events.BadPokeInFirst = bt.t_poke_first(contains(bt.reward,'Bad'))';
% idxBadPokeInFirst = find(ismember(round(vb.ResponsesAll.Time,4),round(events.BadPokeInFirst,4)));
idxBadPokeInFirst = find(ismembertol(vb.ResponsesAll.Time,events.BadPokeInFirst,1e-4,'DataScale',1));
events.BadPokeOutFirst = vb.ResponsesAll.Time(idxBadPokeInFirst+1)';
 
end