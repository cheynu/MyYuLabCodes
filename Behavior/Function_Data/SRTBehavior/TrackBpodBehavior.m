function out = TrackBpodBehavior(SessionData, BpodProtocol)

% hbWang, 19/Apr/2023

% This function get behavior time from SessionData for MedOptoRecording and
% MedLick protocols, derived from @Bpod_Events_MedOptoRecording (JY, 10/4/2022)
% Updated for multiple SRT training stages and fixed some bugs:
%   GoodRelease, GoodPokeIn and Reward: MEDTTL(+) --> RewardDelivery(+);
%   BadPokes and BadPokeFirst: get same-trial-bad-pokes included

arguments
    SessionData
    BpodProtocol string {mustBeMember(BpodProtocol, ...
        ["MedOptoRecording", "MedLick", "MedLickRecording"])} = "MedOptoRecording"
end

switch BpodProtocol
    case {"MedOptoRecording"}
        RewardState = "RewardDelivery";  BadPortState = "BadPortEntry";
    case {"MedLick", "MedLickRecording"}
        RewardState = "RewardDelivery";  BadPortState = "InvalidEntry";
end

GoodRelease = [];  % Time of a successful lever release
GoodPokeIn  = [];  % Poke time after a GoodRelease
Reward      = [];  % 2*N, (1,:) ~ valve open, (2,:) ~ valve close
AllPokeIns  = [];
AllPokeOuts = [];
AllPress    = [];
BadPress    = [];
BadPokeIn   = [];
BadPokeOut  = [];
BadPokeInFirst  = [];
BadPokeOutFirst = [];

nTrials = SessionData.nTrials;
t0 = SessionData.TrialStartTimestamp(1);
for i = 1:nTrials
    iStartTime = SessionData.TrialStartTimestamp(i); % in seconds
    iStates = SessionData.RawEvents.Trial{i}.States;
    iEvents = SessionData.RawEvents.Trial{i}.Events;

    if isfield(iEvents, 'AnalogIn1_1')
        AllPress = [AllPress iStartTime + iEvents.AnalogIn1_1]; %#ok<*AGROW> 
    end
    if isfield(iEvents, 'Port1In')
        AllPokeIns = [AllPokeIns iStartTime + iEvents.Port1In];
    end
    if isfield(iEvents, 'Port1Out')
        AllPokeOuts = [AllPokeOuts iStartTime + iEvents.Port1Out];
    end

    % GoodPress: RewardDelivery(+)  (previous code: MEDTTL(+))
    if ~isnan(iStates.(RewardState)(1))
        GoodRelease = [GoodRelease iStartTime + iStates.WaitForMedTTL(end)];
        GoodPokeIn  = [GoodPokeIn  iStartTime + iStates.(RewardState)(1)];
        Reward      = [Reward      iStartTime + iStates.RewardDelivery'];
    else % RewardDelivery(-)
        switch BpodProtocol
            case "MedOptoRecording"
                % For MedOptoRecording protocol, RewardDelivery(-) ~ BadPress
                % In some trials, GoodPress->Wait4PokeIn->BadPress, there will be multiple rows of MEDTTL
                % I defined these Bpod trials as no-reward trials, and record the last BadPress(Wait4MEDTTL(end,1))
                tPress = iStartTime + iStates.WaitForMedTTL(end,1); % fixed by hbWang
                BadPress = [BadPress tPress];

                % hbWang 18/Apr/2023 (for MedOptoRecording protocol)
                % BadPokes  occurred in two conditions: 
                %   1. BadPress in #i trial and poke before this bpod trial ended
                %   2. BadPress in #i-1 trial and in #i trial before press (JY)

                % Condition 1
                if isfield(iEvents, 'Port1In')
                    idxBadPokeIn = find(iEvents.Port1In > iStates.WaitForMedTTL(end,1),1);
                    if ~isempty(idxBadPokeIn)
                        BadPokeIn = [BadPokeIn; iEvents.Port1In(idxBadPokeIn)];
                    end
                end
                if isfield(iEvents, 'Port1Out')
                    idxBadPokeOut = find(iEvents.Port1Out > iStates.WaitForMedTTL(end,1),1);
                    if ~isempty(idxBadPokeOut)
                        BadPokeOut = [BadPokeOut; iEvents.Port1Out(idxBadPokeOut)];
                    end
                end

            case {"MedLick", "MedLickRecording"}
                % For MedLick protocol, RewardDelivery(-) ~ BadPoke
                iBadPokes = iStates.(BadPortState);
                BadPokeIn  = [BadPokeIn;  iStartTime+iBadPokes(:,1)];
                BadPokeOut = [BadPokeOut; iStartTime+iBadPokes(:,2)];
                BadPokeInFirst  = [BadPokeInFirst;  iStartTime+iBadPokes(1,1)];
                BadPokeOutFirst = [BadPokeOutFirst; iStartTime+iBadPokes(1,2)];
        end
    end

    if BpodProtocol == "MedOptoRecording"
        % Condition 2
        if i > 1 && isnan(SessionData.RawEvents.Trial{i-1}.States.(RewardState)(1))
            iBadPokes = iStates.(BadPortState); % Bad poke entries of current trial
            idxPrePress = find(iBadPokes(:,1) < iStates.WaitForMedTTL(1));
            if ~isempty(idxPrePress)
                iBadPokes  = iBadPokes(idxPrePress,:);
                BadPokeIn  = [BadPokeIn;  iStartTime+iBadPokes(:,1)];
                BadPokeOut = [BadPokeOut; iStartTime+iBadPokes(:,2)];
            end
        end
    end
end

BadPokeIn  = sort(BadPokeIn);
BadPokeOut = sort(BadPokeOut);

% relative timing with respect to the first trial
out.GoodRelease = GoodRelease - t0;
out.GoodPokeIn  = GoodPokeIn  - t0;
out.Reward      = Reward      - t0;
out.BadPokeIn   = BadPokeIn   - t0;
out.BadPokeOut  = BadPokeOut  - t0;
out.BadPress    = BadPress    - t0;
out.AllPokeIns  = AllPokeIns  - t0;
out.AllPokeOuts = AllPokeOuts - t0;
out.AllPress    = AllPress    - t0;

% Add BadPokeIn/OutFirst for MedOptoRecording protocol
if BpodProtocol == "MedOptoRecording"
    for i = 1:length(out.BadPress)
        iBadPress = out.BadPress(i);
        iBadPokeInFirst  = out.BadPokeIn(find(out.BadPokeIn>iBadPress, 1, 'first'));
        iBadPokeOutFirst = out.BadPokeOut(find(out.BadPokeOut>iBadPress, 1, 'first'));
        if i < length(out.BadPress)
            iBadPressNext = out.BadPress(i+1);
            if iBadPokeInFirst > iBadPressNext
                continue;
            end
        end
        BadPokeInFirst  = [BadPokeInFirst  iBadPokeInFirst];
        BadPokeOutFirst = [BadPokeOutFirst iBadPokeOutFirst];
    end
end

out.BadPokeInFirst  = BadPokeInFirst;
out.BadPokeOutFirst = BadPokeOutFirst; 