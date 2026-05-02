function PSTHOut = ChoiceSpikes(r, ind, varargin)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port.
% V5: add poke events following an unsuccesful release

% SRTSpikes(r, 13, 'FRrange', [0 35])

% ind can be singular or a vector

% 8.9.2020
% sort out spikes trains according to reaction time

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

% 5/7/2023 revised to adopt new FP schedule (e.g., 500 1000 1500)

% 5/21/2025
% Change the way to assign event labels

set_matlab_default;
takeall = 0;

if isempty(ind)
    ind = 1:length(r.Units.SpikeTimes);
    takeall = 1;
else
    if length(ind) == 2
        ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
        ind = ind_unit;
    end
end
ku_all = ind; % ind is used in different places

tic
ComputeRange = [];  % this is the range where time is extracted. Event times outside of this range will be discarded. Empty means taking everything

CentInTimeDomain  = [1000 2500]; % default
CentOutTimeDomain = [500 3000];
ChoiceTimeDomain  = [2500 1000];
InitInTimeDomain  = [1000 1500];
InitOutTimeDomain = [750 5000];

ToSave = 'on';

rb = r.Behavior;
% all FPs
if length(r.BehaviorClass) > 1
    r.BehaviorClass = r.BehaviorClass{1};
end

Ports    = r.BehaviorClass.LeftRight;
NumPorts = length(Ports);

%% 1 Align to different events
%% 1.1 Align to cent-in, cent-out and choice

ind_cent_in  = find(strcmp(rb.Labels, 'PokeCentIn'));
t_cent_in    = shape_it(rb.EventTimings(rb.EventMarkers==ind_cent_in));

ind_cent_out = find(strcmp(rb.Labels, 'PokeCentOut'));
t_cent_out   = shape_it(rb.EventTimings(rb.EventMarkers==ind_cent_out));

ind_choice = find(strcmp(rb.Labels, 'PokeChoiceIn'));
t_choice   = shape_it(rb.EventTimings(rb.EventMarkers==ind_choice));

hd = t_cent_out - t_cent_in;
mt = t_choice - t_cent_out;
ct = t_choice - t_cent_in;

disp(['Number of Cent poke-in is ' num2str(length(t_cent_in))]);

% 1.1.1 Correct trials

% index and time of correct cent_in
% get correct response
ind_correct        = find(strcmp(rb.Outcome, 'Correct'));
t_cent_in_correct  = t_cent_in(ind_correct);
t_cent_out_correct = t_cent_out(ind_correct);
t_choice_correct   = t_choice(ind_correct);
Port_correct       = shape_it(rb.PortChosen(ind_correct));

hd_correct = t_cent_out_correct - t_cent_in_correct;
mt_correct = t_choice_correct - t_cent_out_correct;
ct_correct = t_choice_correct - t_cent_in_correct;

% initialize sorted cells, sorted by FPs and Ports, ordered by reaction time
t_cent_in_correct_sort  = cell(1, NumPorts);
t_cent_out_correct_sort = cell(1, NumPorts);
t_choice_correct_sort   = cell(1, NumPorts);

hd_correct_sort = cell(1, NumPorts);
mt_correct_sort = cell(1, NumPorts);
ct_correct_sort = cell(1, NumPorts);
for j = 1:NumPorts
    % find this condition
    ind_j = find(Port_correct==Ports(j));

    t_cent_in_correct_sort{j}  = t_cent_in_correct(ind_j);
    t_cent_out_correct_sort{j} = t_cent_out_correct(ind_j);
    t_choice_correct_sort{j}   = t_choice_correct(ind_j);

    hd_correct_sort{j} = hd_correct(ind_j);
    mt_correct_sort{j} = mt_correct(ind_j);
    ct_correct_sort{j} = ct_correct(ind_j);

    % sort order by hold duration
    [ct_correct_sort{j}, ind_sort] = sort(ct_correct_sort{j});

    t_cent_in_correct_sort{j}  = t_cent_in_correct_sort{j}(ind_sort);
    t_cent_out_correct_sort{j} = t_cent_out_correct_sort{j}(ind_sort);
    t_choice_correct_sort{j}   = t_choice_correct_sort{j}(ind_sort);
    hd_correct_sort{j} = hd_correct_sort{j}(ind_sort);
    mt_correct_sort{j} = mt_correct_sort{j}(ind_sort);
end

% 1.1.2 Wrong trials

% index and time of wrong cent_in
% get wrong response
ind_wrong        = find(strcmp(rb.Outcome, 'Wrong'));
t_cent_in_wrong  = t_cent_in(ind_wrong);
t_cent_out_wrong = t_cent_out(ind_wrong);
t_choice_wrong   = t_choice(ind_wrong);
Port_wrong       = shape_it(rb.PortChosen(ind_wrong));

hd_wrong = t_cent_out_wrong - t_cent_in_wrong;
mt_wrong = t_choice_wrong - t_cent_out_wrong;
ct_wrong = t_choice_wrong - t_cent_in_wrong;

% initialize sorted cells, sorted by FPs and Ports, ordered by reaction time
t_cent_in_wrong_sort  = cell(1, NumPorts);
t_cent_out_wrong_sort = cell(1, NumPorts);
t_choice_wrong_sort   = cell(1, NumPorts);

hd_wrong_sort = cell(1, NumPorts);
mt_wrong_sort = cell(1, NumPorts);
ct_wrong_sort = cell(1, NumPorts);
for j = 1:NumPorts
    % find this condition
    ind_j = find(Port_wrong==Ports(j));

    t_cent_in_wrong_sort{j}  = t_cent_in_wrong(ind_j);
    t_cent_out_wrong_sort{j} = t_cent_out_wrong(ind_j);
    t_choice_wrong_sort{j}   = t_choice_wrong(ind_j);

    hd_wrong_sort{j} = hd_wrong(ind_j);
    mt_wrong_sort{j} = mt_wrong(ind_j);
    ct_wrong_sort{j} = ct_wrong(ind_j);

    % sort order by hold duration
    [ct_wrong_sort{j}, ind_sort] = sort(ct_wrong_sort{j});

    t_cent_in_wrong_sort{j}  = t_cent_in_wrong_sort{j}(ind_sort);
    t_cent_out_wrong_sort{j} = t_cent_out_wrong_sort{j}(ind_sort);
    t_choice_wrong_sort{j}   = t_choice_wrong_sort{j}(ind_sort);
    hd_wrong_sort{j} = hd_wrong_sort{j}(ind_sort);
    mt_wrong_sort{j} = mt_wrong_sort{j}(ind_sort);
end

%% 1.2 Align to init-in and init-out
ind_init_in  = find(strcmp(rb.Labels, 'PokeInitIn'));
t_init_in    = shape_it(rb.EventTimings(rb.EventMarkers==ind_init_in));

ind_init_out = find(strcmp(rb.Labels, 'PokeInitOut'));
t_init_out   = shape_it(rb.EventTimings(rb.EventMarkers==ind_init_out));

disp(['Number of Init poke-in is ' num2str(length(t_init_in))]);

% grouped by outcome of previous trial
PreType = cell(1, length(t_init_in));
% find outcome of previous trial
for i = 1:length(t_init_in)
    ind_last_cent_in = find(t_cent_in<t_init_in(i), 1, 'last');
    if ~isempty(ind_last_cent_in)
        % check the condition
        PreType{i} = rb.Outcome{ind_last_cent_in};
    else
        PreType{i} = 'NaN';
    end
end

InitDur         = t_init_out - t_init_in;
dur_init_precor = InitDur(ismember(PreType, 'Correct'));
dur_init_preerr = InitDur(ismember(PreType, {'Wrong', 'Late', 'Premature'}));

ShuttleTime         = t_cent_in - t_init_out;
shuttle_time_precor = ShuttleTime(ismember(PreType, 'Correct'));
shuttle_time_preerr = ShuttleTime(ismember(PreType, {'Wrong', 'Late', 'Premature'}));

% pre-correct
t_init_in_precor  = t_init_in(ismember(PreType, 'Correct'));
t_init_out_precor = t_init_out(ismember(PreType, 'Correct'));
[shuttle_time_precor_sort, ind_sort] = sort(shuttle_time_precor);
t_init_in_precor_sort  = t_init_in_precor(ind_sort);
t_init_out_precor_sort = t_init_out_precor(ind_sort);
dur_init_precor_sort   = dur_init_precor(ind_sort);

% pre-error
t_init_in_preerr  = t_init_in(ismember(PreType, {'Wrong', 'Late', 'Premature'}));
t_init_out_preerr = t_init_out(ismember(PreType, {'Wrong', 'Late', 'Premature'}));
[shuttle_time_preerr_sort, ind_sort] = sort(shuttle_time_preerr);
t_init_in_preerr_sort  = t_init_in_preerr(ind_sort);
t_init_out_preerr_sort = t_init_out_preerr(ind_sort);
dur_init_preerr_sort   = dur_init_preerr(ind_sort);

% all trials
[ShuttleTime_sort, ind_sort] = sort(ShuttleTime);
t_init_in_sort  = t_init_in(ind_sort);
t_init_out_sort = t_init_out(ind_sort);
InitDur_sort    = InitDur(ind_sort);

%% 2 Check compute range (to be revised, not be used now for computing the whole range)
%
% % Check ComputeRange
% if ~isempty(ComputeRange)
%     t_cent_in(t_cent_in<ComputeRange(1) | t_cent_in>ComputeRange(2))=[];
%
%     % Cent-In and Cent-Out
%     % Correct trials
%     for i = 1:NumFPs
%         to_remove = find(t_cent_in_correct_sort{i}<ComputeRange(1) | t_cent_in_correct_sort{i}>ComputeRange(2) | t_cent_out_correct_sort{i}<ComputeRange(1) | t_cent_out_correct_sort{i}>ComputeRange(2));
%         t_cent_out_correct_sort{i}(to_remove) = [];
%         RT_cent_out_correct_sort{i}(to_remove)        = [];
%         t_cent_in_correct_sort{i}(to_remove)  = [];
%         RT_cent_in_correct_sort{i}(to_remove)         = [];
%     end
%
%     % Init-In and Init-Out
%     % Pre-Correct trials
%
%     % Pre-Error trials
%
% end

%% 3 Summerize

%% Summarize
PSTHOut.ANM_Session = {r.BehaviorClass.Subject, r.BehaviorClass.Session};
PSTHOut.SpikeNotes  = r.Units.SpikeNotes;

PSTHOut.TimeDomain.CentIn  = CentInTimeDomain;
PSTHOut.TimeDomain.CentOut = CentOutTimeDomain;
PSTHOut.TimeDomain.Choice  = ChoiceTimeDomain;
PSTHOut.TimeDomain.InitIn  = InitInTimeDomain;
PSTHOut.TimeDomain.InitOut = InitOutTimeDomain;

%% 3.1 Cent-In
PSTHOut.CentIn.Labels = ["Correct", "Wrong", "All"];

PSTHOut.CentIn.Time = cell(1, length(PSTHOut.CentIn.Labels));
PSTHOut.CentIn.Time{1} = t_cent_in_correct_sort;
PSTHOut.CentIn.Time{2} = t_cent_in_wrong_sort;
PSTHOut.CentIn.Time{3} = t_cent_in;

PSTHOut.CentIn.PortChosen   = {Ports, Ports, rb.PortChosen};
PSTHOut.CentIn.ChoiceTime   = {ct_correct_sort, ct_wrong_sort, ct};
PSTHOut.CentIn.HoldDur      = {hd_correct_sort, hd_wrong_sort, hd};
PSTHOut.CentIn.MovementTime = {mt_correct_sort, mt_wrong_sort, mt};

%% 3.2 Cent-Out
PSTHOut.CentOut.Labels = ["Correct", "Wrong", "All"];

PSTHOut.CentOut.Time = cell(1, length(PSTHOut.CentOut.Labels));
PSTHOut.CentOut.Time{1} = t_cent_out_correct_sort;
PSTHOut.CentOut.Time{2} = t_cent_out_wrong_sort;
PSTHOut.CentOut.Time{3} = t_cent_out;

PSTHOut.CentOut.PortChosen   = {Ports, Ports, rb.PortChosen};
PSTHOut.CentOut.ChoiceTime   = {ct_correct_sort, ct_wrong_sort, ct};
PSTHOut.CentOut.HoldDur      = {hd_correct_sort, hd_wrong_sort, hd};
PSTHOut.CentOut.MovementTime = {mt_correct_sort, mt_wrong_sort, mt};

%% 3.3 Choice-In
PSTHOut.Choice.Labels = ["Correct", "Wrong", "All"];

PSTHOut.Choice.Time = cell(1, length(PSTHOut.CentIn.Labels));
PSTHOut.Choice.Time{1} = t_choice_correct_sort;
PSTHOut.Choice.Time{2} = t_choice_wrong_sort;
PSTHOut.Choice.Time{3} = t_choice;

PSTHOut.Choice.PortChosen   = {Ports, Ports, rb.PortChosen};
PSTHOut.Choice.ChoiceTime   = {ct_correct_sort, ct_wrong_sort, ct};
PSTHOut.Choice.HoldDur      = {hd_correct_sort, hd_wrong_sort, hd};
PSTHOut.Choice.MovementTime = {mt_correct_sort, mt_wrong_sort, mt};

%% 3.4 InitIn & InitOut
PSTHOut.InitIn.Time        = t_init_in_sort;
PSTHOut.InitIn.ShuttleTime = ShuttleTime_sort;
PSTHOut.InitIn.InitDur     = InitDur_sort;
PSTHOut.InitIn.PreCor.Time        = t_init_in_precor_sort;
PSTHOut.InitIn.PreCor.ShuttleTime = shuttle_time_precor_sort;
PSTHOut.InitIn.PreCor.InitDur     = dur_init_precor_sort;
PSTHOut.InitIn.PreErr.Time        = t_init_in_preerr_sort;
PSTHOut.InitIn.PreErr.ShuttleTime = shuttle_time_preerr_sort;
PSTHOut.InitIn.PreErr.InitDur     = dur_init_preerr_sort;

PSTHOut.InitOut.Time        = t_init_out_sort;
PSTHOut.InitOut.ShuttleTime = ShuttleTime_sort;
PSTHOut.InitOut.PreCor.Time        = t_init_out_precor_sort;
PSTHOut.InitOut.PreCor.ShuttleTime = shuttle_time_precor_sort;
PSTHOut.InitOut.PreCor.InitDur     = dur_init_precor_sort;
PSTHOut.InitOut.PreErr.Time        = t_init_out_preerr_sort;
PSTHOut.InitOut.PreErr.ShuttleTime = shuttle_time_preerr_sort;
PSTHOut.InitOut.PreErr.InitDur     = dur_init_preerr_sort;

%% 4 Compute PSTH

%% Check how many units we need to compute
% derive PSTH from these
% go through each units if necessary
for iku = 1:length(ku_all)
    ku = ku_all(iku);
    if ku>length(r.Units.SpikeTimes)
        disp('##########################################')
        disp('########### That is all you have ##############')
        disp('##########################################')
        return
    end
    disp('##########################################')
    disp(['Computing this unit: ' num2str(ku)])
    disp('##########################################')

    PSTH = SpikesGPS.Autoshaping.ComputePSTH(r, PSTHOut, ku);
    SpikesGPS.Autoshaping.PlotRasterPSTH(r, PSTHOut, PSTH, ku);
    PSTHOut.PSTH(iku) = PSTH;
end

%%
if takeall
    r.PSTH.ANM_Session     = {r.BehaviorClass.Subject, r.BehaviorClass.Session};
    r.PSTH.TimeDomain      = PSTHOut.TimeDomain;
    r.PSTH.Events.CentIn   = PSTHOut.CentIn;
    r.PSTH.Events.CentOut  = PSTHOut.CentOut;
    r.PSTH.Events.Choice   = PSTHOut.Choice;
    r.PSTH.Events.InitIn   = PSTHOut.InitIn;
    r.PSTH.Events.InitOut  = PSTHOut.InitOut;
    r.PSTH.PSTHs           = PSTHOut.PSTH;

    r_name = 'RTarray_'+r.BehaviorClass.Subject+'_'+r.BehaviorClass.Session+'.mat';
    save(r_name, 'r');
    psth_new_name = r.BehaviorClass.Subject+'_'+r.BehaviorClass.Session+'_PSTHs.mat';
    save(psth_new_name, 'PSTHOut');
    try
        % C:\Users\jiani\OneDrive\00_Work\03_Projects\05_Physiology\PSTHs
        thisFolder = fullfile(findonedrive, '00_Work', '03_Projects', '05_Physiology', 'Data', 'PETHs', r.BehaviorClass.Subject);
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder);
        end
        copyfile(psth_new_name, thisFolder);
    end
end

end