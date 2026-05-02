function BMTLearning

MEDFile = dir('*Subject*.txt');
% MEDFilePostAnalysis = dir('B_*.mat');

%% Extract behavior times from MED

% if isempty(MEDFilePostAnalysis)
    b = track_training_progress_advanced(MEDFile.name);
    b = UpdateWaitB(b); % add FP 
% else
%     load(MEDFilePostAnalysis.name)
% end

% 3. load Bpod data
FindBpodFile = dir('*MedOpto*.mat');

if ~isempty(FindBpodFile)
    BpodFile = FindBpodFile.name;
    load(BpodFile); %#ok<LOAD> 
else
    disp('No Bpod file or what?')
    return
end


% EventMat         =      [];
PressTime        =      NaN*ones(1, SessionData.nTrials); % NaN, no press within 4 sec
ReleaseTime      =      NaN*ones(1, SessionData.nTrials); 
% This is the trigger time for the tone (important for video alignment)
TriggerTime      =      NaN*ones(1, SessionData.nTrials); 


for i =1:SessionData.nTrials

    iStates         =    SessionData.RawEvents.Trial{(i)}.States;
    iEvents         =    SessionData.RawEvents.Trial{(i)}.Events;
    t_thistrial     =    SessionData.TrialStartTimestamp(i);
    iPressTime      =    []; % time of lever press
    iReleaseTime    =    0;
    iTriggerTime    =    0;

    % Now check if there is lever press (This now works great)
    if isfield(iEvents, 'AnalogIn1_1') && ismember(iStates.WaitForMedTTL(1), iEvents.AnalogIn1_1)
        iPressTime = iStates.WaitForMedTTL(1);
    elseif iStates.WaitForPress(end) == iStates.WaitForPortExit(1)
        iPressTime = 0;
    end

    % Check if there is lever release
    if ~isnan(iStates.WaitForMedTTL(1)) || ~isnan(iStates.WaitForMedTTLStim(1))
        
%         iTriggerTime = [iStates.WaitForMedTTL(1) iStates.WaitForMedTTLStim(1)]; 
%         iTriggerTime = iTriggerTime(~isnan(iTriggerTime)); % trigger time

        if ~isnan(iStates.WaitForPokedIn(1))
            iReleaseTime = iStates.WaitForPokedIn(1);
        end
        % Note that there is no way to know release time from Bpod if it is
        % an incorrect release events
    end


    if iTriggerTime ~= 0
        TriggerTime(i) = iTriggerTime + t_thistrial;
    else
        TriggerTime(i) = iTriggerTime;
    end

    if iPressTime ~=0
        PressTime(i) = iPressTime + t_thistrial;
    else
        PressTime(i) = iPressTime;
    end

    if iReleaseTime ~=0
        ReleaseTime(i) = iReleaseTime + t_thistrial;
    else
        ReleaseTime(i) = iReleaseTime;
    end

end


% Make a useful table. 

TrialsBpod       =      (1:SessionData.nTrials)';
tPress           =      PressTime';
tRelease         =      ReleaseTime';
tTrigger         =      TriggerTime';

RatName          =      repmat(b.Metadata.SubjectName, SessionData.nTrials, 1);
Date             =      repmat(SessionData.Info.SessionDate, SessionData.nTrials, 1);
ExpTime          =      repmat(SessionData.Info.SessionStartTime_UTC, SessionData.nTrials, 1);
MEDProtocolName  =      repmat(b.Metadata.ProtocolName, SessionData.nTrials, 1);
MEDFileName      =      repmat(MEDFile.name, SessionData.nTrials, 1);
BpodFileName     =      repmat('bpod.mat', SessionData.nTrials, 1);

% map each trial that contains a press time to b

tPress2          =      tPress(tPress~=0);
IndBpodInMed     =      findseqmatchrev(b.PressTime, tPress2, 0 , 1);
IndTrials        =      zeros(size(tPress));
IndTrials(tPress~=0)   =   IndBpodInMed;
IndTrials(tPress==0)   =   NaN;     

IndBpod2MED = IndTrials;

FPs = NaN*ones(length(TrialsBpod), 1);
FPs(~isnan(IndBpod2MED)) = b.FPs(IndBpod2MED(~isnan(IndBpod2MED)));

% fullfill some missing release time
for j = 1:length(tRelease)
    if tPress(j)~=0 && tRelease(j) == 0
        indMED = IndBpod2MED(j);
        tRelease(j) = b.ReleaseTime(indMED) - b.PressTime(indMED) + tPress(j);
    end
end

Performance = cell(length(TrialsBpod), 1);

for i =1:length(IndBpod2MED)
    if ~isnan(IndBpod2MED(i))
        if ismember(IndBpod2MED(i), b.Correct)
            Performance{i} = 'Correct';
            tTrigger(i) = tPress(i) + FPs(i)/1000;
        elseif ismember(IndBpod2MED(i), b.Premature)
            Performance{i} = 'Premature';
        elseif ismember(IndBpod2MED(i), b.Late)
            Performance{i} = 'Late';
            tTrigger(i) = tPress(i) + FPs(i)/1000;
        elseif  ismember(IndBpod2MED(i), b.Dark)
            Performance{i} = 'Dark';
        else
            Performance{i} = 'Unknown';
        end
    end
end

figure; plot(IndTrials, 'gx')
figure; plot(FPs, 'k*')

btable        =     table(RatName, Date, TrialsBpod, IndBpod2MED, FPs, Performance, ...
    tPress, tTrigger, tRelease, MEDProtocolName, MEDFileName, BpodFileName, ExpTime);
aGoodName     =     ['BpodMEDTable' '_' b.Metadata.SubjectName, '_' b.Metadata.Date '.csv'];

writetable(btable, aGoodName);

end