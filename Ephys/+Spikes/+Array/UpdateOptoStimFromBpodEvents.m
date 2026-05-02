function EventOut = UpdateOptoStimFromBpodEvents(EventOut, BpodEvents)
% revised 4/2/2023 Jianing Yu
% Update Poke events in EventOut based on BpodEvents
% 5/30/3023 JY
% Update OptoStim events in EventOut from BpodEvents. we have opto data
% form analog input but this can be used for insanity check

N_events = length(EventOut.EventsLabels);
% all pokes in bpod
% events.OptoStimOn = [events.OptoStimOn t_trial + LaserTime(1)];
% events.OptoStimOff = [events.OptoStimOff t_trial + LaserTime(2)];
opto_on_bpod = BpodEvents.OptoStimOn*1000;
opto_off_bpod = BpodEvents.OptoStimOff*1000;
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

opto_on_mapped2blackrock =  to_align(opto_on_bpod, press_ephys_new_toBpod, press_ephys_new);
opto_off_mapped2blackrock =  to_align(opto_off_bpod, press_ephys_new_toBpod, press_ephys_new);

ind_include = find(opto_on_mapped2blackrock>0 & opto_off_mapped2blackrock < press_ephys(end)+1000);
opto_on_mapped2blackrock = opto_on_mapped2blackrock(ind_include);
opto_off_mapped2blackrock = opto_off_mapped2blackrock(ind_include);



if sum(strcmp(EventOut.EventsLabels, 'OptoStim'))==0
    n_labels = length(EventOut.EventsLabels);
    EventOut.Onset{n_labels+1} = opto_on_mapped2blackrock;
    EventOut.Offset{n_labels+1} = opto_off_mapped2blackrock;
    EventOut.EventsLabels{n_labels+1}= 'OptoStim';
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