function EventSpike = getSpikeCount(r, tEvent, Window, id)

if nargin<4
    ku = 1:length(r.Units.SpikeTimes);
else
    switch length(id)
        case 1
            ku = id;
        case 2
            ku = find(r.Units.SpikeNotes(:,1)==id(1) & r.Units.SpikeNotes(:,2)==id(2));
    end
end

n_trials = height(r.EphysTable);

EventSpike = struct();
EventSpike.Window = Window; % ms
EventSpike.Count  = zeros(n_trials, length(ku));

for i = 1:n_trials
    EventSpike.Count(i,:) = arrayfun(@(x) sum(x.timings>r.EphysTable.(tEvent)(i)+Window(1) & x.timings<=r.EphysTable.(tEvent)(i)+Window(2)), r.Units.SpikeTimes(ku));
end

end