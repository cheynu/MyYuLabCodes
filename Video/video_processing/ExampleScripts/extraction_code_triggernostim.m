%% trigger nostim
filename = dir('BClass_*.mat');
load(filename.name);
filename = dir('BpodMEDTable_*.csv');
thisTable = readtable(filename.name);
% extract trigger-stim trials (only correct trials since we want to examine
% release-to-poke events
indEvents = strcmp(thisTable.OptoStimTypes,'NoStim') & strcmp(thisTable.Outcome,'Correct') ;
indTrialsMED = thisTable.Trials_MED(indEvents);
tEventsBpod                 = thisTable.TriggerTime(indEvents); % this is time in bpod
tEventsMED                 = obj.ToneTime(indTrialsMED); % this is time in bpod
tEvents                         =            tEventsMED;
tEvents = sort(tEvents(randperm(length(tEvents), 20))); % randomly select 20 trials

disp(tEvents)
eventName = 'TriggerNoStim';
figure; plot(tEvents, 'ko-')

