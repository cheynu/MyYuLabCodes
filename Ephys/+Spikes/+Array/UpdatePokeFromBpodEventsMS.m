function EventOut = UpdatePokeFromBpodEventsMS(EventOut, BpodEvents)
% revised 4/2/2023 Jianing Yu
% Update Poke events in EventOut based on BpodEvents
% revised from UpdatePokeFromBpodEvents for multiple sessions seperated by
% hours
% BpodEvents is now a cell structure

Gap = 3600*5*1000; % gap 5 hours. (This is not important. It is just there to seperate sessoins)
N_events = length(EventOut.EventsLabels);

% get events from bpod
badpokein_time_bpod = [];
badpokeout_time_bpod = [];
allpokein_time_bpod = [];
allpokeout_time_bpod = [];
press_bpod= [];
onset_time = [];
reward_in_bpod = [];
reward_out_bpod = [];

time_first_session_bpod = 0;
press_ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')}; % in ms

for i = 1:length(BpodEvents)

        itime = split(BpodEvents{i}.SessionStartTime, ':');
        onset_time(i) = str2num(itime{1})*3600 + str2num(itime{2})*60 + str2num(itime{3}); 

        if i ==1
            time_first_session_bpod=onset_time(i);
        end

        badpokein_time_bpod             =           [badpokein_time_bpod BpodEvents{i}.BadPokeInFirst*1000+onset_time(i)*1000-time_first_session_bpod*1000];
        badpokeout_time_bpod           =           [badpokeout_time_bpod BpodEvents{i}.BadPokeOutFirst*1000+onset_time(i)*1000-time_first_session_bpod*1000];
        allpokein_time_bpod                =           [allpokein_time_bpod BpodEvents{i}.AllPokeIns*1000+onset_time(i)*1000-time_first_session_bpod*1000];
        allpokeout_time_bpod              =           [allpokeout_time_bpod BpodEvents{i}.AllPokeOuts*1000+onset_time(i)*1000-time_first_session_bpod*1000];
        press_bpod                              =           [press_bpod BpodEvents{i}.AllPress*1000+onset_time(i)*1000-time_first_session_bpod*1000];
        reward_in_bpod                       =           [reward_in_bpod BpodEvents{i}.Reward(1, :)*1000+onset_time(i)*1000-time_first_session_bpod*1000];
        reward_out_bpod                     =           [reward_out_bpod BpodEvents{i}.Reward(2, :)*1000+onset_time(i)*1000-time_first_session_bpod*1000];

end;
 

% check if the data are seperated by more than 60 min. If so, we will have
% to align each segment seperately.

t_critical = 30*60*1000; % this is the critical checking point, in ms
seg = 0;

if find(diff(press_ephys)>t_critical)  % multiple segments
    seg =1;
    % Track bpod
    ind_breakpoint = find(diff(press_ephys)>t_critical);
    disp( press_ephys(ind_breakpoint))
    disp( press_ephys(ind_breakpoint+1))
    disp( (press_ephys(ind_breakpoint+1)- press_ephys(ind_breakpoint)))

    % press before [1 ind_breakpoint(i)], [ind_breakpoint(i)+1
    % ind_breakpoint(i+1)], ..., [ind_breakpoint(end)+1 end]

    ind_segments_beg =[1 ind_breakpoint'+1];
    ind_segments_end = [ind_breakpoint' length(press_ephys)];

else
    ind_segments_beg = 1;
    ind_segments_end = length(press_ephys);
end;

press_ephys_new = [];                 % all press events recorded in ephys that can be matched to bpod events. 
% press_ephys_new should be the same as press_ephys unless some strange events cannot be matched. 
press_ephys_new_toBpod = [];    % the matched bpod events of press_ephys_new

for k =1:length(ind_segments_beg) 
    k_press_ephys = press_ephys(ind_segments_beg(k):ind_segments_end(k));
    % align release_time_blackrock and relese_time_bpod
    seqmom = press_bpod;
    seqson =   k_press_ephys;

    man = 0;
    toprint = 0;
    toprintname = [];
 
    if length(seqson)>=3
        Indout = findseqmatchrev(seqmom, seqson, man, toprint, toprintname);
        Indout(find(diff(Indout)==0)+1) = NaN;
        k_press_ephys_new                 =   seqson(~isnan(Indout)); % press in ephys not including nan
        k_press_ephys_new_toBpod    =   transpose(seqmom(Indout(~isnan(Indout))));

        press_ephys_new = [press_ephys_new; k_press_ephys_new];
        press_ephys_new_toBpod = [press_ephys_new_toBpod; k_press_ephys_new_toBpod];
    else
        k_press_ephys_new                    =            [];
        k_press_ephys_new_toBpod      =             [];
    end;

end;

figure(22); clf(22)
plot(press_ephys_new_toBpod, 3, 'k*')
hold on
plot(press_ephys_new, 4, 'rx')
set(gca, 'ylim', [2 9])
line([press_ephys_new_toBpod press_ephys_new], [3.1 3.9], 'color', 'c')
text(allpokein_time_bpod(1), 2.8, 'press time bpod')
text(allpokein_time_bpod(1), 4.2, 'press time in blackrock')
% Update poke time
% Map poke time
allpokein_time_mapped2blackrock = to_align(allpokein_time_bpod, press_ephys_new_toBpod, press_ephys_new);
plot(allpokein_time_bpod, 5, 'ko')
hold on
plot(allpokein_time_mapped2blackrock, 6, 'r+')
set(gca, 'ylim', [2 9])
line([allpokein_time_bpod' allpokein_time_mapped2blackrock], [5.1 5.9], 'color', 'c')
text(allpokein_time_bpod(1), 4.8, 'poke time')
text(allpokein_time_bpod(1), 6.2, 'poke time mapped to blackrock')
allpokein_time_mapped2blackrock = allpokein_time_mapped2blackrock(allpokein_time_mapped2blackrock>0 & allpokein_time_mapped2blackrock < press_ephys(end)+1000);

allpokeout_time_mapped2blackrock = to_align(allpokeout_time_bpod, press_ephys_new_toBpod, press_ephys_new);
allpokeout_time_mapped2blackrock = allpokeout_time_mapped2blackrock(allpokeout_time_mapped2blackrock>0 & allpokeout_time_mapped2blackrock < press_ephys(end)+1000);

% Map reward time
reward_in_bpod_mapped2blackrock =  to_align(reward_in_bpod, press_ephys_new_toBpod, press_ephys_new);
plot(reward_in_bpod, 7, 'k^')
hold on
plot(reward_in_bpod_mapped2blackrock, 8, 'rd')
set(gca, 'ylim', [2 9])
line([reward_in_bpod' reward_in_bpod_mapped2blackrock], [7.1 7.9], 'color', 'c')
text(allpokein_time_bpod(1), 6.8, 'reward time')
text(allpokein_time_bpod(1), 8.2, 'reward time mapped to blackrock')
reward_in_bpod_mapped2blackrock = reward_in_bpod_mapped2blackrock(reward_in_bpod_mapped2blackrock>0 & reward_in_bpod_mapped2blackrock < press_ephys(end)+2000);

reward_out_bpod =  to_align(reward_out_bpod, press_ephys_new_toBpod, press_ephys_new);
reward_out_bpod_mapped2blackrock = reward_out_bpod(reward_out_bpod>0 & reward_out_bpod < press_ephys(end)+2000);

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = allpokein_time_mapped2blackrock;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = allpokeout_time_mapped2blackrock;

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Valve')} = reward_in_bpod_mapped2blackrock;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Valve')} = reward_out_bpod_mapped2blackrock;

% add bad poke (may not be that useful)
EventOut.EventsLabels{N_events+1} = 'BadPoke';

EventOut.Onset{N_events+1} = to_align(badpokein_time_bpod, press_ephys_new_toBpod, press_ephys_new);
EventOut.Offset{N_events+1} = to_align(badpokeout_time_bpod, press_ephys_new_toBpod, press_ephys_new);

function alignout = to_align(t_domain1, t_domain1_ref, t_domain2_ref)
% map time in domain 1 to time in domain 2 using the reference time
alignout = zeros(length(t_domain1), 1);
for i =1:length(t_domain1)
    it = t_domain1(i);
    % nearest ref
    [~, indref] = min(abs(it - t_domain1_ref));
    alignout(i) = it - t_domain1_ref(indref) + t_domain2_ref(indref);
end;