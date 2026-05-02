function EventOut = UpdatePokeFromBpodEventsMedLick(EventOut, BpodEvents)
% revised 4/2/2023 Jianing Yu
% Update Poke events in EventOut based on BpodEvents
% 7/72023 MedLick program doesn's store pres s info so we use GoodRelease
% to align data

N_events = length(EventOut.EventsLabels);
% all pokes in bpod
allpokein_time_bpod = BpodEvents.AllPokeIns*1000;
allpokeout_time_bpod = BpodEvents.AllPokeOuts*1000;

% good release (medttl) in bpod: events.GoodRelease
good_release_bpod = BpodEvents.GoodRelease*1000; % in ms
good_release_ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'GoodRelease')}; % in ms

% align release_time_blackrock and relese_time_bpod
seqmom = good_release_bpod;
seqson = good_release_ephys;
% 
% seqmom = press_ephys;
% seqson = press_bpod;

man = 0;
toprint = 0;
toprintname = [];

if isempty(seqson)
    []
end;

if length(seqson)>=3
    Indout = findseqmatchrev(seqmom, seqson, man, toprint, toprintname);
    good_release_ephys_new                 =   seqson(~isnan(Indout)); % press in ephys not including nan
    good_release_ephys_new_toBpod    =   seqmom(Indout(~isnan(Indout)));
else
    good_release_ephys_new                    =            [];
    good_release_ephys_new_toBpod      =             [];
end;

allpokein_time_mapped2blackrock = to_align(allpokein_time_bpod, good_release_ephys_new_toBpod, good_release_ephys_new);
allpokein_time_mapped2blackrock = allpokein_time_mapped2blackrock(allpokein_time_mapped2blackrock>0 & allpokein_time_mapped2blackrock < good_release_ephys(end)+1000);
allpokeout_time_mapped2blackrock = to_align(allpokeout_time_bpod,  good_release_ephys_new_toBpod, good_release_ephys_new);
allpokeout_time_mapped2blackrock = allpokeout_time_mapped2blackrock(allpokeout_time_mapped2blackrock>0 & allpokeout_time_mapped2blackrock < good_release_ephys(end)+1000);

reward_in_fromBpod =  to_align(BpodEvents.Reward(1, :)*1000,  good_release_ephys_new_toBpod, good_release_ephys_new);
reward_in_fromBpod = reward_in_fromBpod(reward_in_fromBpod>0 & reward_in_fromBpod < good_release_ephys(end)+2000);
reward_out_fromBpod =  to_align(BpodEvents.Reward(2, :)*1000, good_release_ephys_new_toBpod, good_release_ephys_new);
reward_out_fromBpod = reward_out_fromBpod(reward_out_fromBpod>0 & reward_out_fromBpod < good_release_ephys(end)+2000);

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = allpokein_time_mapped2blackrock;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = allpokeout_time_mapped2blackrock;

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Valve')} = reward_in_fromBpod;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Valve')} = reward_out_fromBpod;

function alignout = to_align(t_domain1, t_domain1_ref, t_domain2_ref)
% map time in domain 1 to time in domain 2 using the reference time
alignout = zeros(length(t_domain1), 1);
for i =1:length(t_domain1)
    it = t_domain1(i);
    % nearest ref
    [~, indref] = min(abs(it - t_domain1_ref));
    alignout(i) = it - t_domain1_ref(indref) + t_domain2_ref(indref);
end;