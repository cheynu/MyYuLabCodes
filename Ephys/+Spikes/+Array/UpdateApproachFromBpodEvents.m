function EventOut = UpdateApproachFromBpodEvents(EventOut, BpodEvents)
% revised 4/2/2023 Jianing Yu
% Update Poke events in EventOut based on BpodEvents
% 5/30/3023 JY
% Update Approach events in EventOut from BpodEvents. 


N_events = length(EventOut.EventsLabels);
% all pokes in bpod
approach_time_bpod = BpodEvents.Approach*1000; 
% good release (medttl) in bpod
press_bpod = BpodEvents.AllPress*1000; % in ms
press_ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')}; % in ms

% align release_time_blackrock and relese_time_bpod
seqmom = press_bpod;
seqson = press_ephys;
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
    press_ephys_new                 =   seqson(~isnan(Indout)); % press in ephys not including nan
    press_ephys_new_toBpod    =   seqmom(Indout(~isnan(Indout)));
else
    press_ephys_new                    =            [];
    press_ephys_new_toBpod      =             [];
end;

approach_time_mapped2blackrock =  to_align(approach_time_bpod, press_ephys_new_toBpod, press_ephys_new);
approach_time_mapped2blackrock = approach_time_mapped2blackrock(approach_time_mapped2blackrock>0 & approach_time_mapped2blackrock < press_ephys(end)+1000);

if sum(strcmp(EventOut.EventsLabels, 'Approach'))==0
    n_labels = length(EventOut.EventsLabels);
    EventOut.Onset{n_labels+1} = approach_time_mapped2blackrock;
    EventOut.Offset{n_labels+1} = [];
    EventOut.EventsLabels{n_labels+1}= 'Approach';
end
 
function alignout = to_align(t_domain1, t_domain1_ref, t_domain2_ref)
% map time in domain 1 to time in domain 2 using the reference time
alignout = zeros(length(t_domain1), 1);
for i =1:length(t_domain1)
    it = t_domain1(i);
    % nearest ref
    [~, indref] = min(abs(it - t_domain1_ref));
    alignout(i) = it - t_domain1_ref(indref) + t_domain2_ref(indref);
end;