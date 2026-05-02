function EventTime = ExtractEvents_LeverPressVI(r, reExtract)

arguments
    r
    reExtract = false
end

if reExtract || ~isfield(r, 'EventTable')
    bpoddir = dir('*LeverPressVI*.mat');
    meddir = dir('*_Subject*.txt');
    vb = Behavior.LeverPressVI.track_training(bpoddir.name, meddir.name);
    r.EventTable = Spikes.LeverPressVI.rEventTable(r, vb);
end
tab = r.EventTable;
%%
EventTime.EventTable = tab;

EventTime.Presses = tab.t_press;
EventTime.Releases = tab.t_release;
EventTime.Triggers = EventTime.Presses;
EventTime.Pokes = tab.t_poke_first(~isnan(tab.t_poke_first));

% Approach onset & offset
RewardedPokeRow = find(contains(tab.reward,'Rewarded'));
OmittedPokeRow = find(contains(tab.reward,'Omitted'));
BadPokeRow = find(contains(tab.reward,'Bad'));

idxPortExit = find(~isnan(tab.t_port_exit));
idxApproachPress = idxPortExit+1;

idxUse = find(idxApproachPress<=size(tab,1));
idxPortExit = idxPortExit(idxUse); % index of this press row
idxApproachPress = idxApproachPress(idxUse); % index of next press row

idxRewarded = find(ismember(idxPortExit,RewardedPokeRow));
idxOmitted = find(ismember(idxPortExit,OmittedPokeRow));
idxBadPoke = find(ismember(idxPortExit,BadPokeRow));

EventTime.Approach.Type = {'Bad', 'Rewarded', 'Omitted'};
EventTime.Approach.Idx = {idxBadPoke, idxRewarded, idxOmitted};
EventTime.Approach.PortExit = tab.t_port_exit(idxPortExit);
EventTime.Approach.Presses = tab.t_press(idxApproachPress);
EventTime.Approach.Intervals = EventTime.Approach.Presses - EventTime.Approach.PortExit;

% Retrieval onset & offset
idxPokeFirst = find(~isnan(tab.t_poke_first));
idxRetrievalRelease = idxPokeFirst;

idxGoodRelease = find(ismember(idxPokeFirst, [RewardedPokeRow(:); OmittedPokeRow(:)]));
idxBadRelease = find(ismember(idxPokeFirst, BadPokeRow));

EventTime.Retrieval.Type = {'Bad', 'Good'};
EventTime.Retrieval.Idx = {idxBadRelease, idxGoodRelease};
EventTime.Retrieval.Releases = tab.t_release(idxRetrievalRelease);
EventTime.Retrieval.Pokes = tab.t_poke_first(idxPokeFirst);
EventTime.Retrieval.Intervals = EventTime.Retrieval.Pokes - EventTime.Retrieval.Releases;

% Press-Poke-Press period
EventTime.PressPokeCycle.Type = {'Bad','Rewarded','Omitted'};
EventTime.PressPokeCycle.Idx = {idxBadPoke, idxRewarded, idxOmitted};
EventTime.PressPokeCycle.PressesThis = tab.t_press(idxPortExit);
EventTime.PressPokeCycle.Releases = tab.t_release(idxPortExit);
EventTime.PressPokeCycle.PokeFirst = tab.t_poke_first(idxPortExit);
EventTime.PressPokeCycle.PortExit = tab.t_port_exit(idxPortExit);
EventTime.PressPokeCycle.PressesNext = tab.t_press(idxApproachPress);
EventTime.PressPokeCycle.MovementTime = EventTime.PressPokeCycle.PokeFirst - EventTime.PressPokeCycle.Releases;
EventTime.PressPokeCycle.RestartTime = EventTime.PressPokeCycle.PressesNext - EventTime.PressPokeCycle.PortExit;

end