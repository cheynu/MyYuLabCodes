function EventTime = ExtractEvents(r)

if ~isfield(r, 'PSTH')
    PSTH = Spikes.SRT.SRTSpikes(r, 1); % so we don't rely on r having a PSTH field anymore
else
    PSTH = r.PSTH;
end

EventTime.Presses        =         PSTH.Events.Presses;  
EventTime.Releases      =         PSTH.Events.Releases;  
EventTime.Triggers        =         PSTH.Events.Triggers;  
EventTime.Pokes           =         PSTH.Events.Pokes;  

EventTime.PressTimes_ms                          =         cell2mat(EventTime.Presses.Time(5)');
EventTime.Releases_ms                              =         cell2mat(EventTime.Releases.Time');
EventTime.Triggers_ms                                =         cell2mat(EventTime.Triggers.Time');
EventTime.RewardPokes_ms                       =          transpose(cell2mat(EventTime.Pokes.RewardPoke.Time));

if ~iscell(EventTime.Pokes.NonrewardPoke.Time)
    EventTime.NonRewardPokes_ms                =          transpose(EventTime.Pokes.NonrewardPoke.Time);
else
    EventTime.NonRewardPokes_ms                =          transpose(cell2mat(EventTime.Pokes.NonrewardPoke.Time));
end
