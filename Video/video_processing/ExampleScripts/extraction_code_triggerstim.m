%% trigger stim
filename = dir('BClass_*.mat');
load(filename.name);
filename = dir('BpodMEDTable_*.csv');
thisTable = readtable(filename.name);
% extract trigger-stim trials (only correct trials since we want to examine
% release-to-poke events
indEvents = strcmp(thisTable.OptoStimTypes,'TriggerStim') ;
indTrialsMED = thisTable.Trials_MED(indEvents);
tEventsBpod                 = thisTable.TriggerTime(indEvents); % this is time in bpod
tEventsMED                 = obj.ToneTime(indTrialsMED); % this is time in bpod
tEvents                         =            tEventsMED;

disp(tEvents)
eventName = 'TriggerStim';
figure; plot(tEvents, 'ko-')

