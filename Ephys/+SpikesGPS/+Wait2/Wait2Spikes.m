function PSTHOut = Wait2Spikes(r, ind, varargin)
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
CentOutTimeDomain = [1500 1000];
ChoiceTimeDomain  = [1000 2000];
TriggerTimeDomain = [500  500];
InitInTimeDomain  = [1000 1500];
InitOutTimeDomain = [750 5000];

ToSave = 'on';

rb = r.Behavior;
% all FPs
if length(r.BehaviorClass) > 1
    r.BehaviorClass = r.BehaviorClass{1};
end

TargetFP = 1.5; % s

Stages    = logical([0 1]);
NumStages = length(Stages);

Ports    = r.BehaviorClass.LeftRight;
NumPorts = length(Ports);

rb.Stage = rb.Foreperiods==TargetFP;

%% 1 Align to different events
%% 1.1 Align to cent-in and cent-out

ind_cent_in  = find(strcmp(rb.Labels, 'PokeCentIn'));
t_cent_in    = shape_it(rb.EventTimings(rb.EventMarkers==ind_cent_in));

ind_cent_out = find(strcmp(rb.Labels, 'PokeCentOut'));
t_cent_out   = shape_it(rb.EventTimings(rb.EventMarkers==ind_cent_out));

disp(['Number of Cent poke-in is ' num2str(length(t_cent_in))]);

% 1.1.1 Correct trials

% index and time of correct cent_in
% get correct response
ind_correct        = find(strcmp(rb.Outcome, 'Correct'));
t_cent_in_correct  = t_cent_in(ind_correct);
t_cent_out_correct = t_cent_out(ind_correct);
Stage_correct = shape_it(rb.Stage(ind_correct));
Port_correct  = shape_it(rb.PortCorrect(ind_correct));

FP_correct = shape_it(rb.Foreperiods(ind_correct));
RT_correct = t_cent_out_correct - t_cent_in_correct - FP_correct*1000;

% initialize sorted cells, sorted by FPs and Ports, ordered by reaction time
t_cent_in_correct_sort  = cell(NumStages, NumPorts);
t_cent_out_correct_sort = cell(NumStages, NumPorts);
RT_correct_sort         = cell(NumStages, NumPorts);
FP_correct_sort         = cell(NumStages, NumPorts);
for i = 1:NumStages
    for j = 1:NumPorts
        % find this condition
        ind_ij = find(Stage_correct==Stages(i) & Port_correct==Ports(j));

        t_cent_in_correct_sort{i,j}  = t_cent_in_correct(ind_ij);
        t_cent_out_correct_sort{i,j} = t_cent_out_correct(ind_ij);
        RT_correct_sort{i,j}         = RT_correct(ind_ij);
        FP_correct_sort{i,j}         = FP_correct(ind_ij);

        % sort order by hold duration
        if ~isempty(FP_correct_sort{i,j})
            [~, ind_sort] = sortrows([FP_correct_sort{i,j}, RT_correct_sort{i,j}], [1 2]);
        else
            ind_sort = [];
        end

        %         [RT_correct_sort{i,j}, ind_sort] = sort(RT_correct_sort{i,j});

        t_cent_in_correct_sort{i,j}  = t_cent_in_correct_sort{i,j}(ind_sort);
        t_cent_out_correct_sort{i,j} = t_cent_out_correct_sort{i,j}(ind_sort);
        RT_correct_sort{i,j} = RT_correct_sort{i,j}(ind_sort);
        FP_correct_sort{i,j} = FP_correct_sort{i,j}(ind_sort);
    end
end
RT_cent_in_correct_sort  = RT_correct_sort;
RT_cent_out_correct_sort = RT_correct_sort;
FP_cent_in_correct_sort  = FP_correct_sort;
FP_cent_out_correct_sort = FP_correct_sort;

% 1.1.2 Premature trials

% Premature responses
ind_premature        = find(strcmp(rb.Outcome, 'Premature'));
t_cent_in_premature  = t_cent_in(ind_premature);
t_cent_out_premature = t_cent_out(ind_premature);
Stage_premature = shape_it(rb.Stage(ind_premature));
Port_premature  = shape_it(rb.PortCorrect(ind_premature));

FP_premature = shape_it(rb.Foreperiods(ind_premature));
HD_premature = t_cent_out_premature - t_cent_in_premature;

% initialize sorted cells, sorted by FPs and Ports, ordered by hold duration
t_cent_in_premature_sort  = cell(NumStages, NumPorts);
t_cent_out_premature_sort = cell(NumStages, NumPorts);
HD_premature_sort = cell(NumStages, NumPorts);
FP_premature_sort = cell(NumStages, NumPorts);
Stage_premature_sort = cell(NumStages, NumPorts);
for i = 1:NumStages
    for j = 1:NumPorts
        % find this condition
        ind_ij = find(Stage_premature==Stages(i) & Port_premature==Ports(j));

        t_cent_in_premature_sort{i,j}  = t_cent_in_premature(ind_ij);
        t_cent_out_premature_sort{i,j} = t_cent_out_premature(ind_ij);

        FP_premature_sort{i,j} = FP_premature(ind_ij);
        HD_premature_sort{i,j} = HD_premature(ind_ij);
        Stage_premature_sort{i,j} = Stage_premature(ind_ij);

        % sort order by hold duration
        [HD_premature_sort{i,j}, ind_sort] = sort(HD_premature_sort{i,j});

        t_cent_in_premature_sort{i,j}  = t_cent_in_premature_sort{i,j}(ind_sort);
        t_cent_out_premature_sort{i,j} = t_cent_out_premature_sort{i,j}(ind_sort);
        FP_premature_sort{i,j} = FP_premature_sort{i,j}(ind_sort);
        Stage_premature_sort{i,j} = Stage_premature_sort{i,j}(ind_sort);
    end
end

% gather data in sorted order, sorted again by hold duration for pooled data, grouped by ports
t_cent_in_premature  = cell(1, NumPorts);
t_cent_out_premature = cell(1, NumPorts);
HD_cent_in_premature  = cell(1, NumPorts);
HD_cent_out_premature = cell(1, NumPorts);
FP_cent_in_premature  = cell(1, NumPorts);
FP_cent_out_premature = cell(1, NumPorts);
Stage_cent_in_premature  = cell(1, NumPorts);
Stage_cent_out_premature = cell(1, NumPorts);

for j = 1:NumPorts
    t_cent_in_premature{j}   = cell2mat(t_cent_in_premature_sort(:,j));
    t_cent_out_premature{j}  = cell2mat(t_cent_out_premature_sort(:,j));
    HD_cent_in_premature{j}  = cell2mat(HD_premature_sort(:,j));
    HD_cent_out_premature{j} = cell2mat(HD_premature_sort(:,j));
    FP_cent_in_premature{j}  = cell2mat(FP_premature_sort(:,j));
    FP_cent_out_premature{j} = cell2mat(FP_premature_sort(:,j));
    Stage_cent_in_premature{j}  = cell2mat(Stage_premature_sort(:,j));
    Stage_cent_out_premature{j} = cell2mat(Stage_premature_sort(:,j));

    [~, ind_sort] = sort(HD_cent_in_premature{j});

    t_cent_in_premature{j}   = t_cent_in_premature{j}(ind_sort);
    t_cent_out_premature{j}  = t_cent_out_premature{j}(ind_sort);
    HD_cent_in_premature{j}  = HD_cent_in_premature{j}(ind_sort);
    HD_cent_out_premature{j} = HD_cent_out_premature{j}(ind_sort);
    FP_cent_in_premature{j}  = FP_cent_in_premature{j}(ind_sort);
    FP_cent_out_premature{j} = FP_cent_out_premature{j}(ind_sort);
    Stage_cent_in_premature{j}  = Stage_cent_in_premature{j}(ind_sort);
    Stage_cent_out_premature{j} = Stage_cent_out_premature{j}(ind_sort);
end

% 1.1.3 Late trials

% Late response
ind_late        = find(strcmp(rb.Outcome, 'Late'));
t_cent_in_late  = t_cent_in(ind_late);
t_cent_out_late = t_cent_out(ind_late);
Stages_late = shape_it(rb.Stage(ind_late));
Ports_late  = shape_it(rb.PortCorrect(ind_late));

FP_late = shape_it(rb.Foreperiods(ind_late));
HD_late = t_cent_out_late - t_cent_in_late;

% initialize sorted cells, sorted by FPs and Ports
t_cent_in_late_sort  = cell(NumStages, NumPorts);
t_cent_out_late_sort = cell(NumStages, NumPorts);
FP_late_sort = cell(NumStages, NumPorts);
HD_late_sort = cell(NumStages, NumPorts);
Stage_late_sort = cell(NumStages, NumPorts);

for i = 1:NumStages
    for j = 1:NumPorts
        % find this condition
        ind_ij = find(Stages_late==Stages(i) & Ports_late==Ports(j));

        t_cent_in_late_sort{i,j}  = t_cent_in_late(ind_ij);
        t_cent_out_late_sort{i,j} = t_cent_out_late(ind_ij);

        FP_late_sort{i,j} = FP_late(ind_ij);
        HD_late_sort{i,j} = HD_late(ind_ij);
        Stage_late_sort{i,j} = Stages_late(ind_ij);

        % sort by hold duration
        if ~isempty(FP_late_sort{i,j})
            [~, ind_sort] = sortrows([FP_late_sort{i,j}, HD_late_sort{i,j}], [1 2]);
        else
            ind_sort = [];
        end

        t_cent_in_late_sort{i,j}  = t_cent_in_late_sort{i,j}(ind_sort);
        t_cent_out_late_sort{i,j} = t_cent_out_late_sort{i,j}(ind_sort);
        HD_late_sort{i,j}    = HD_late_sort{i,j}(ind_sort);
        FP_late_sort{i,j}    = FP_late_sort{i,j}(ind_sort);
        Stage_late_sort{i,j} = Stage_late_sort{i,j}(ind_sort);
    end
end

% gather data in sorted order, grouped by ports
t_cent_in_late   = cell(1, NumPorts);
t_cent_out_late  = cell(1, NumPorts);
HD_cent_in_late  = cell(1, NumPorts);
HD_cent_out_late = cell(1, NumPorts);
FP_cent_in_late  = cell(1, NumPorts);
FP_cent_out_late = cell(1, NumPorts);
Stage_cent_in_late  = cell(1, NumPorts);
Stage_cent_out_late = cell(1, NumPorts);

for j = 1:NumPorts
    t_cent_in_late{j}  = cell2mat(t_cent_in_late_sort(:,j));
    t_cent_out_late{j} = cell2mat(t_cent_out_late_sort(:,j));
    HD_cent_in_late{j}  = cell2mat(HD_late_sort(:,j));
    HD_cent_out_late{j} = cell2mat(HD_late_sort(:,j));
    FP_cent_in_late{j}  = cell2mat(FP_late_sort(:,j));
    FP_cent_out_late{j} = cell2mat(FP_late_sort(:,j));
    Stage_cent_in_late{j}  = cell2mat(Stage_late_sort(:,j));
    Stage_cent_out_late{j} = cell2mat(Stage_late_sort(:,j));
end

%% 1.2 Align to choice-in

% Choice
tmin = 200; % allow at least 0.2 second between a successful cent_out and poke
tmax = 2500; % allow at most 2 second between a successful cent_out and poke

ind_choice = find(strcmp(rb.Labels, 'PokeChoiceIn'));
t_choice   = shape_it(rb.EventTimings(rb.EventMarkers==ind_choice));
disp(['Number of Choice poke-in is ' num2str(length(t_choice))]);

% 1.2.1 Rewarded choice poke (correct trials)

Stage_choice_correct = nan(1, length(t_choice)); % find out choice_in FP associated with each reward
Port_choice_correct  = nan(1, length(t_choice)); % find out choice_in Port associated with each reward
MT_correct           = nan(1, length(t_choice));

for i = 1:length(t_choice)
    dt = t_choice(i) - t_cent_out_correct;
    dt = dt(dt>tmin & dt<tmax); % reward must be collected within 2 sec after a correct cent_out (not limited in task)
    if ~isempty(dt)
        MT_correct(i) = dt(1);
        ind = find(t_cent_out_correct==t_choice(i)-dt(end)); % find this trial number
        if ~isempty(ind)
            Stage_choice_correct(i) = Stage_correct(ind);
            Port_choice_correct(i)  = Port_correct(ind);
        else
            disp('Not found')
        end
    end
end

ind_valid = ~isnan(MT_correct) & ~isnan(Stage_choice_correct) & ~isnan(Port_choice_correct);
MT_correct           = MT_correct(ind_valid);
t_choice_correct     = t_choice(ind_valid);
Stage_choice_correct = Stage_choice_correct(ind_valid);
Port_choice_correct  = Port_choice_correct(ind_valid);

% Check movement time distribution
Edges = (0:50:2500);
figure(45); clf; set(gcf, 'Units', 'Centimeters', 'Position', [5 5 6 4]);
histogram(MT_correct, Edges);
xlabel('Movement time (ms)');
ylabel('Count');

% group choice according to FP and Port, order by MT
t_choice_correct_sort  = cell(NumStages, NumPorts);
MT_correct_sort        = cell(NumStages, NumPorts);
for i = 1:NumStages
    for j = 1:NumPorts
        ind_ij = find(Stage_choice_correct==Stages(i) & Port_choice_correct==Ports(j));
        t_choice_correct_sort{i,j} = t_choice_correct(ind_ij);
        MT_correct_sort{i,j}       = MT_correct(ind_ij);

        % rank them
        [MT_correct_sort{i,j}, ind_sort] = sort(MT_correct_sort{i,j});
        t_choice_correct_sort{i,j}  = t_choice_correct_sort{i,j}(ind_sort);
    end
end
MT_correct = MT_correct_sort;
t_choice_correct  = t_choice_correct_sort;

% 1.2.2 Non-rewarded choice poke (wrong or probe trials)

ind_noreward          = find(~strcmp(rb.Outcome, 'Correct'));
Stage_choice_noreward = nan(1, length(t_choice)); % find out choice_in FP associated with each reward
Port_choice_noreward  = nan(1, length(t_choice)); % find out choice_in Port associated with each reward

t_cent_out_noreward = t_cent_out(ind_noreward);
Stage_noreward      = shape_it(rb.Foreperiods(ind_noreward));
Port_noreward       = shape_it(rb.PortChosen(ind_noreward));

MT_noreward         = nan(1, length(t_choice));

for i = 1:length(t_choice)
    dt = t_choice(i) - t_cent_out_noreward;
    dt = dt(dt>tmin & dt<tmax); % reward must be collected within 2 sec after a noreward cent_out
    if ~isempty(dt)
        MT_noreward(i) = dt(1);
        ind = find(t_cent_out_noreward==t_choice(i)-dt(end));
        if ~isempty(ind)
            Stage_choice_noreward(i) = Stage_noreward(ind);
            Port_choice_noreward(i)  = Port_noreward(ind);
        else
            disp('Not found')
        end
    end
end

ind_valid = ~isnan(MT_noreward) & ~isnan(Stage_choice_noreward) & ~isnan(Port_choice_noreward);
MT_noreward           = MT_noreward(ind_valid);
t_choice_noreward     = t_choice(ind_valid);
Stage_choice_noreward = Stage_choice_noreward(ind_valid);
Port_choice_noreward  = Port_choice_noreward(ind_valid);

% Check movement time distribution
Edges = (0:50:2500);
figure(45); clf; set(gcf, 'Units', 'Centimeters', 'Position', [5 5 6 4]);
histogram(MT_noreward, Edges);
xlabel('Movement time (ms)');
ylabel('Count');

% sort by movement time
% rank them
% group choice according to Port
t_choice_noreward_sort = cell(1, NumPorts);
MT_noreward_sort       = cell(1, NumPorts);
Stage_choice_noreward_sort = cell(1, NumPorts);
for j = 1:NumPorts
    ind_j = find(Port_choice_noreward==Ports(j));
    t_choice_noreward_sort{j} = t_choice_noreward(ind_j);
    MT_noreward_sort{j}       = MT_noreward(ind_j);
    Stage_choice_noreward_sort{j} = Stage_choice_noreward(ind_j);

    % rank them
    [MT_noreward_sort{j}, ind_sort] = sort(MT_noreward_sort{j});
    t_choice_noreward_sort{j}       = t_choice_noreward_sort{j}(ind_sort);
    Stage_choice_noreward_sort{j}   = Stage_choice_noreward_sort{j}(ind_sort);
end
MT_noreward = MT_noreward_sort;
t_choice_noreward     = t_choice_noreward_sort;
Stage_choice_noreward = Stage_choice_noreward_sort;

%% 1.3 Align to trigger stimulus

%% Trigger
ind_trig = find(strcmp(rb.Labels, 'Trigger'));
t_trig   = shape_it(rb.EventTimings(rb.EventMarkers==ind_trig)); % trigger time in ms.

Type_trig  = cell(length(t_trig), 1);
Stage_trig = nan(length(t_trig), 1);
Port_trig  = nan(length(t_trig), 1);
RT_trig    = nan(length(t_trig), 1); % reaction time (used for ranking later)
FP_trig    = nan(length(t_trig), 1);

for i = 1:length(t_trig)
    % find the most recent cent_in
    ind_cent_in_recent = find(t_cent_in<t_trig(i), 1, 'last');
    if ~isempty(ind_cent_in_recent) && t_trig(i)-t_cent_in(ind_cent_in_recent)<2500
        % check the condition
        Type_trig{i}  = rb.Outcome{ind_cent_in_recent};
        Stage_trig(i) = rb.Stage(ind_cent_in_recent);
        Port_trig(i)  = rb.PortCorrect(ind_cent_in_recent);
        FP_trig(i)    = rb.Foreperiods(ind_cent_in_recent);
        ind_cent_out_following = find(t_cent_out>t_trig(i), 1, 'first');
        if ~isempty(ind_cent_out_following)
            RT_trig(i) = t_cent_out(ind_cent_out_following) - t_trig(i);
        end
    else
        Type_trig{i} = 'NaN';
    end
end

% 1.3.1 Correct trigger response
% trigger according to FPs
t_trig_correct_sort  = cell(NumStages, NumPorts);
RT_trig_correct_sort = cell(NumStages, NumPorts);
FP_trig_correct_sort = cell(NumStages, NumPorts);

for i = 1:NumStages
    for j = 1:NumPorts
        % sort trigger (to plot)
        t_trig_correct_sort{i,j}  = t_trig(strcmp(Type_trig, 'Correct') & Stage_trig==Stages(i) & Port_trig==Ports(j));
        RT_trig_correct_sort{i,j} = RT_trig(strcmp(Type_trig, 'Correct') & Stage_trig==Stages(i) & Port_trig==Ports(j));
        FP_trig_correct_sort{i,j} = FP_trig(strcmp(Type_trig, 'Correct') & Stage_trig==Stages(i) & Port_trig==Ports(j));
        % sort according to reaction time
        %         [RT_trig_correct_sort{i,j}, ind_sort] = sort(RT_trig_correct_sort{i,j});

        if ~isempty(FP_trig_correct_sort{i,j})
            [~, ind_sort] = sortrows([FP_trig_correct_sort{i,j}, RT_trig_correct_sort{i,j}], [1 2]);
        else
            ind_sort = [];
        end

        t_trig_correct_sort{i,j}  = t_trig_correct_sort{i,j}(ind_sort);
        RT_trig_correct_sort{i,j} = RT_trig_correct_sort{i,j}(ind_sort);
        FP_trig_correct_sort{i,j} = FP_trig_correct_sort{i,j}(ind_sort);
    end
end

% 1.3.2 Late trigger response
t_trig_late     = cell(1, NumPorts);
RT_trig_late    = cell(1, NumPorts);
Stage_trig_late = cell(1, NumPorts);
FP_trig_late    = cell(1, NumPorts);

for j = 1:NumPorts
    % group trigger (to plot)
    t_trig_late{j}     = t_trig(strcmp(Type_trig, 'Late') & Port_trig==Ports(j));
    RT_trig_late{j}    = RT_trig(strcmp(Type_trig, 'Late') & Port_trig==Ports(j));
    Stage_trig_late{j} = Stage_trig(strcmp(Type_trig, 'Late') & Port_trig==Ports(j));
    FP_trig_late{j}    = FP_trig(strcmp(Type_trig, 'Late') & Port_trig==Ports(j));
    % order according to reaction time
    %     [RT_trig_late{j}, ind_sort] = sort(RT_trig_late{j});
    if ~isempty(FP_trig_late{j})
        [~, ind_sort] = sortrows([FP_trig_late{j}, RT_trig_late{j}], [1 2]);
    else
        ind_sort = [];
    end
    t_trig_late{j}     = t_trig_late{j}(ind_sort);
    RT_trig_late{j}    = RT_trig_late{j}(ind_sort);
    Stage_trig_late{j} = Stage_trig_late{j}(ind_sort);
    FP_trig_late{j}    = FP_trig_late{j}(ind_sort);
end

%% 1.4 Align to init-in and init-out
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

%
% % Init-In, ordered by drinking duration in init-port (InitDur)
% % pre-correct
% t_init_in_precor = t_init_in(ismember(PreType, 'Correct'));
% dur_init_precor  = InitDur(ismember(PreType, 'Correct'));
% [dur_init_precor_sort, ind_sort] = sort(dur_init_precor);
% t_init_in_precor_sort  = t_init_in_precor(ind_sort);
% % pre-error
% t_init_in_preerr  = t_init_in(ismember(PreType, {'Wrong', 'Late', 'Premature'}));
% dur_init_preerr   = InitDur(ismember(PreType, {'Wrong', 'Late', 'Premature'}));
% [dur_init_preerr_sort, ind_sort] = sort(dur_init_preerr);
% t_init_in_preerr_sort  = t_init_in_preerr(ind_sort);
% % all trials
% [InitDur_sort, ind_sort] = sort(InitDur);
% t_init_in_sort  = t_init_in(ind_sort);

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
%     % Premature trials
%     to_remove_premature = find(t_cent_in_premature<ComputeRange(1) | t_cent_in_premature>ComputeRange(2) | t_cent_out_premature<ComputeRange(1) | t_cent_out_premature>ComputeRange(2));
%     t_cent_in_premature(to_remove_premature)         = [];
%     HD_cent_in_premature(to_remove_premature)  = [];
%     FP_cent_in_premature(to_remove_premature)       = [];
%     t_cent_out_premature(to_remove_premature)        = [];
%     HD_cent_out_premature(to_remove_premature) = [];
%     FP_cent_out_premature(to_remove_premature)      = [];
%
%     % Late trials
%     to_remove_late = find(t_cent_in_late<ComputeRange(1) | t_cent_in_late>ComputeRange(2) | t_cent_out_late<ComputeRange(1) | t_cent_out_late>ComputeRange(2));
%     t_cent_in_late(to_remove_late)         = [];
%     late_duration_cent_in(to_remove_late)  = [];
%     FPs_late_cent_in(to_remove_late)       = [];
%     t_cent_out_late(to_remove_late)        = [];
%     late_duration_cent_out(to_remove_late) = [];
%     FPs_late_cent_out(to_remove_late)      = [];
%
%     % Probe trials
%
%     % Choice
%     % Correct trials
%     for i=1:NumFPs
%         to_remove_rewardpokes =  find(t_reward_pokes{i}<ComputeRange(1) | t_reward_pokes{i}>ComputeRange(2));
%         t_reward_pokes{i}(to_remove_rewardpokes) = [];
%         MT_correct{i}(to_remove_rewardpokes) = [];
%     end
%
%     % Non-rewarded trials (Error or Probe trials)
%     to_remove_nonrewardpokes = find(t_nonreward_pokes<ComputeRange(1) | t_nonreward_pokes>ComputeRange(2));
%     t_nonreward_pokes(to_remove_nonrewardpokes) = [];
%     move_time_nonreward(to_remove_nonrewardpokes) = [];
%
%     % Trigger
%     % Correct trials
%     for i = 1:NumFPs
%         to_remove = find(t_trig_correct_sort{i}<ComputeRange(1) | t_trig_correct_sort{i}>ComputeRange(2));
%         t_trig_correct_sort{i}(to_remove) = [];
%         RT_trig_correct_sort{i}(to_remove) = [];
%     end
%
%     % Late trials
%     to_remove_trigger_late = find(t_trig_late<ComputeRange(1) | t_trig_late>ComputeRange(2));
%     t_trig_late(to_remove_trigger_late) = [];
%     RT_trig_late(to_remove_trigger_late) = [];
%     FP_trig_late(to_remove_trigger_late) = [];
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
PSTHOut.TimeDomain.Trigger = TriggerTimeDomain;
PSTHOut.TimeDomain.InitIn  = InitInTimeDomain;
PSTHOut.TimeDomain.InitOut = InitOutTimeDomain;

%% 3.1 Cent-In
PSTHOut.CentIn.Labels = ["Correct", "Premature", "Late", "All"];

PSTHOut.CentIn.Time = cell(1, length(PSTHOut.CentIn.Labels));
PSTHOut.CentIn.Time{1} = t_cent_in_correct_sort;
PSTHOut.CentIn.Time{2} = t_cent_in_premature;
PSTHOut.CentIn.Time{3} = t_cent_in_late;
PSTHOut.CentIn.Time{4} = t_cent_in;

PSTHOut.CentIn.Stage             = {repmat(Stages', 1, 2), Stage_cent_in_premature, Stage_cent_in_late, rb.Stage};
PSTHOut.CentIn.Port              = {repmat(Ports, 2, 1), Ports, Ports, rb.PortCorrect};
PSTHOut.CentIn.FP                = {FP_cent_in_correct_sort, FP_cent_in_premature, FP_cent_in_late, rb.Foreperiods};
PSTHOut.CentIn.RT_Correct        = RT_cent_in_correct_sort;
PSTHOut.CentIn.HoldDur.Premature = HD_cent_in_premature;
PSTHOut.CentIn.HoldDur.Late      = HD_cent_in_late;

%% 3.2 Cent-Out
PSTHOut.CentOut.Labels = ["Correct", "Premature", "Late"];

PSTHOut.CentOut.Time = cell(1, length(PSTHOut.CentOut.Labels));
PSTHOut.CentOut.Time{1} = t_cent_out_correct_sort;
PSTHOut.CentOut.Time{2} = t_cent_out_premature;
PSTHOut.CentOut.Time{3} = t_cent_out_late;

PSTHOut.CentOut.Stage             = {repmat(Stages', 1, 2), Stage_cent_out_premature, Stage_cent_out_late};
PSTHOut.CentOut.Port              = {repmat(Ports, 2, 1), Ports, Ports};
PSTHOut.CentOut.FP                = {FP_cent_out_correct_sort, FP_cent_out_premature, FP_cent_out_late};
PSTHOut.CentOut.RT_Correct        = RT_cent_out_correct_sort;
PSTHOut.CentOut.HoldDur.Premature = HD_cent_out_premature;
PSTHOut.CentOut.HoldDur.Late      = HD_cent_out_late;

%% 3.3 Choice-In
PSTHOut.ChoiceIn.Time                   = t_choice;
PSTHOut.ChoiceIn.RewardPoke.Time        = t_choice_correct; % it is a cell now!
PSTHOut.ChoiceIn.RewardPoke.MoveTime    = MT_correct;       % it is a cell now!
PSTHOut.ChoiceIn.NonrewardPoke.Time     = t_choice_noreward;
PSTHOut.ChoiceIn.NonrewardPoke.MoveTime = MT_noreward;

%% 3.4 Trigger
PSTHOut.Triggers.Labels  = ["Correct", "Late"];
PSTHOut.Triggers.Time    = cell(1, length(PSTHOut.Triggers.Labels));
PSTHOut.Triggers.Time{1} = t_trig_correct_sort;
PSTHOut.Triggers.Time{2} = t_trig_late;

PSTHOut.Triggers.RT      = {RT_trig_correct_sort, RT_trig_late};
PSTHOut.Triggers.Stage   = {repmat(Stages', 1, 2), Stage_trig_late};
PSTHOut.Triggers.Port    = {repmat(Ports, 3, 1), Ports};
PSTHOut.Triggers.FP      = {FP_trig_correct_sort, FP_trig_late};

%% 3.5 InitIn & InitOut
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

    PSTH = SpikesGPS.Wait2.ComputePSTH(r, PSTHOut, ku);
    SpikesGPS.Wait2.PlotRasterPSTH(r, PSTHOut, PSTH, ku);
    PSTHOut.PSTH(iku) = PSTH;
end

%%
if takeall
    r.PSTH.ANM_Session     = {r.BehaviorClass.Subject, r.BehaviorClass.Session};
    r.PSTH.TimeDomain      = PSTHOut.TimeDomain;
    r.PSTH.Events.CentIn   = PSTHOut.CentIn;
    r.PSTH.Events.CentOut  = PSTHOut.CentOut;
    r.PSTH.Events.ChoiceIn = PSTHOut.ChoiceIn;
    r.PSTH.Events.Triggers = PSTHOut.Triggers;
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