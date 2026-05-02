function EventTime = ExtractEventsTable(r)

% 2025.12.24 JY
%    r.EventTable = Spikes.SRT.rEventTableRewardProb(r);

EventTable = Spikes.SRT.rEventTableRewardProb(r);

ind = ~strcmp(EventTable.type, 'Dark');
EventTime.Presses        =         EventTable.t_press(ind);  
EventTime.Releases      =         EventTable.t_release(ind);  
EventTime.Triggers        =        EventTable.t_trigger(ind);

ind = ~strcmp(EventTable.type, 'Dark') & strcmp(EventTable.outcome, 'Correct') ;
EventTime.Pokes           =        EventTable.t_poke(ind);

EventTime.PressTimes_ms                          =        EventTime.Presses;
EventTime.Releases_ms                              =        EventTime.Releases;
EventTime.Triggers_ms                                =       EventTime.Triggers ;
EventTime.RewardPokes_ms                       =        EventTime.Pokes ;

ind = ~strcmp(EventTable.type, 'Dark') & ~strcmp(EventTable.outcome, 'Correct') ;
EventTime.NonRewardPokes_ms                       =         EventTable.t_poke(ind);