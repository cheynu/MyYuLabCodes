function EventOut = hbAlignBpod2BR(EventOut, BpodEvents, BpodProtocol, AlignByGoodRelease)

% Apr 2023, Hanbo Wang
% Adapted for Naive, Wait and MultiFP states
% Change reference sequences to more general names (tBpod_ref & tEphys_ref)
% Use PRESS for non-naive stages and MEDTTL for naive stages to align

% revised from @UpdatePokeFromBpodEvents by Jianing Yu Apr 2023
% Update Poke events in EventOut based on BpodEvents

arguments
    EventOut    % DIOEvent output of DIO_Events4(NEV) (or combined version)
    BpodEvents  % BpodEvents output of TrackBpodBehavior(SessionData)
    BpodProtocol string {mustBeMember(BpodProtocol, ...
        ["MedOptoRecording", "MedLick", "MedLickRecording"])} = "MedOptoRecording"
    AlignByGoodRelease = 0
end

if AlignByGoodRelease
    % Use MEDTTL signal to align Bpod events
    seqmom = BpodEvents.GoodRelease*1000; % ms
    seqson = EventOut.Onset{strcmp(EventOut.EventsLabels, 'GoodRelease')};
else
    switch BpodProtocol
        case {"MedOptoRecording"}
            % BpodEvents of TrackBpodBehavior(SessionData) for WAIT States
            %     GoodRelease: [371.5145 435.7315 464.0002 … ]
            %      GoodPokeIn: [372.5472 436.8580 465.1454 … ]
            %          Reward: [2×118 double]
            %       BadPokeIn: [31×1 double]
            %      BadPokeOut: [31×1 double]
            %        BadPress: [301.7685 339.4966 408.5937 … ]
            %      AllPokeIns: [223.9332 224.2145 239.2835 … ]
            %     AllPokeOuts: [224.2070 226.2758 239.4315 … ]
            %        AllPress: [301.7685 302.5185 339.4966 … ]
            %  BadPokeInFirst: [308.9953 346.3772 1.0022e+03 … ]
            % BadPokeOutFirst: [309.0058 346.5452 1.0025e+03 … ]
            
            % Use Press signal to align Bpod events
            seqmom = BpodEvents.AllPress*1000; % ms
            seqson = EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')};
        case {"MedLick", "MedLickRecording"}
            % BpodEvents of TrackBpodBehavior(SessionData) for NAIVE States
            %     GoodRelease: [393.6648 406.2042 442.9025 470.0712 … ]
            %      GoodPokeIn: [393.6748 406.2142 442.9125 470.0812 … ]
            %          Reward: [2×162 double]
            %       BadPokeIn: [328×1 double]
            %      BadPokeOut: [328×1 double]
            %        BadPress: []
            %      AllPokeIns: [313.8094 344.9321 345.1377 345.2413 … ]
            %     AllPokeOuts: [313.9594 345.0990 345.1499 345.4304 … ]
            %        AllPress: []
            %  BadPokeInFirst: [71×1 double]
            % BadPokeOutFirst: [71×1 double]
    
            % Use MEDTTL signal to align Bpod events
            seqmom = BpodEvents.GoodRelease*1000; % ms
            seqson = EventOut.Onset{strcmp(EventOut.EventsLabels, 'GoodRelease')};
    end
end

if length(seqson) >= 3
    idxMatch = findseqmatchrev(seqmom, seqson, 0, 0);
    tBpod_ref  = seqmom(idxMatch(~isnan(idxMatch)));
    tEphys_ref = seqson(~isnan(idxMatch)); % press in ephys not including nan
else
    tBpod_ref  = [];
    tEphys_ref = [];
end

% Update poke time
tAllPokeIn_Bpod  = BpodEvents.AllPokeIns*1000;
tAllPokeOut_Bpod = BpodEvents.AllPokeOuts*1000;
tRewardIn_Bpod   = BpodEvents.Reward(1,:)*1000;
tRewardOut_Bpod  = BpodEvents.Reward(2,:)*1000;

tAllPokeIn_Ephys  = to_align(tAllPokeIn_Bpod,  tBpod_ref, tEphys_ref);
tAllPokeIn_Ephys  = tAllPokeIn_Ephys(tAllPokeIn_Ephys>0 & tAllPokeIn_Ephys<tEphys_ref(end)+2000);
tAllPokeOut_Ephys = to_align(tAllPokeOut_Bpod, tBpod_ref, tEphys_ref);
tAllPokeOut_Ephys = tAllPokeOut_Ephys(tAllPokeOut_Ephys>0 & tAllPokeOut_Ephys<tEphys_ref(end)+2000);

tRewardIn_Ephys  = to_align(tRewardIn_Bpod, tBpod_ref, tEphys_ref);
tRewardIn_Ephys  = tRewardIn_Ephys(tRewardIn_Ephys>0 & tRewardIn_Ephys<tEphys_ref(end)+1000);
tRewardOut_Ephys = to_align(tRewardOut_Bpod, tBpod_ref, tEphys_ref);
tRewardOut_Ephys = tRewardOut_Ephys(tRewardOut_Ephys>0 & tRewardOut_Ephys<tEphys_ref(end)+1000);

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')}  = tAllPokeIn_Ephys;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = tAllPokeOut_Ephys;

EventOut.Onset{strcmp(EventOut.EventsLabels, 'Valve')}  = tRewardIn_Ephys;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'Valve')} = tRewardOut_Ephys;

% add bad poke (may not be that useful)
tBadPokeIn_Bpod  = BpodEvents.BadPokeInFirst*1000;
tBadPokeOut_Bpod = BpodEvents.BadPokeOutFirst*1000;

nEvents = length(EventOut.EventsLabels);
EventOut.EventsLabels{nEvents+1} = 'BadPoke';

tBadPokeIn_Ephys  = to_align(tBadPokeIn_Bpod,  tBpod_ref, tEphys_ref);
tBadPokeIn_Ephys  = tBadPokeIn_Ephys(tBadPokeIn_Ephys>0 & tBadPokeIn_Ephys<tEphys_ref(end)+5000);
tBadPokeOut_Ephys = to_align(tBadPokeOut_Bpod, tBpod_ref, tEphys_ref);
tBadPokeOut_Ephys = tBadPokeOut_Ephys(tBadPokeOut_Ephys>0 & tBadPokeOut_Ephys<tEphys_ref(end)+5000);

EventOut.Onset{nEvents+1}  = tBadPokeIn_Ephys;
EventOut.Offset{nEvents+1} = tBadPokeOut_Ephys;

function alignout = to_align(t_domain1, t_domain1_ref, t_domain2_ref)
% map time in domain 1 to time in domain 2 using the reference time
alignout = zeros(length(t_domain1), 1);
for i = 1:length(t_domain1)
    it = t_domain1(i);
    % nearest ref
    [~, indref] = min(abs(it - t_domain1_ref));
    alignout(i) = it - t_domain1_ref(indref) + t_domain2_ref(indref);
end