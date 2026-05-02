function Stat = testNonParam(r, id)

if nargin<2
    ku = 1:size(r.Units.SpikeNotes, 1);
    take_all = 1;
else
    take_all = 0;
    switch length(id)
        case 1
            ku = id;
        case 2
            ku = find(r.Units.SpikeNotes(:,1)==id(1) & r.Units.SpikeNotes(:,2)==id(2));
    end
end

thres = .01;
n_units = length(ku);

%% Set events and time windows
Events = ["InitIn", "InitOut", "CentIn", "Trigger", "CentOut", "Choice"];
Window.InitIn.Pre   = [-150, 0];
Window.InitIn.Post  = [0, 150];
Window.InitOut.Pre  = [-150, 0];
Window.InitOut.Post = [0, 150];
Window.CentIn.Pre   = [-150, 0];
Window.CentIn.Post  = [0, 150];
Window.Trigger.Pre  = [-150, 0];
Window.Trigger.Post = [0, 150];
Window.CentOut.Pre  = [-150, 0];
Window.CentOut.Post = [0, 150];
Window.Choice.Pre   = [-150, 0];
Window.Choice.Post  = [0, 150];

SpkRate = struct();
%%
for i = 1:length(Events)
    fprintf('\nGet spike rate around %s\n', Events(i));

    if take_all
        count_pre  = getSpikeCount(r, "t"+Events(i), Window.(Events(i)).Pre);
        count_post = getSpikeCount(r, "t"+Events(i), Window.(Events(i)).Post);
        SpkRate.(Events(i)).Pre  = count_pre.Count * 1000 / diff(Window.(Events(i)).Pre);
        SpkRate.(Events(i)).Post = count_post.Count * 1000 / diff(Window.(Events(i)).Post);
    else
        count_pre  = getSpikeCount(r, "t"+Events(i), Window.(Events(i)).Pre, ku);
        count_post = getSpikeCount(r, "t"+Events(i), Window.(Events(i)).Post, ku);
        SpkRate.(Events(i)).Pre  = count_pre.Count * 1000 / diff(Window.(Events(i)).Pre);
        SpkRate.(Events(i)).Post = count_post.Count * 1000 / diff(Window.(Events(i)).Post);
    end
end


%%
Stat = struct();
Stat.UnitID = ku';

%% test event-related modulation
for n = 1:n_units
    for i = 1:length(Events)
        switch Events(i)
            case {"InitIn", "InitOut", "CentIn"}
                id_trial = find(r.EphysTable.Stage==1); 
            case {"Trigger", "CentOut", "Choice"}
                id_trial = find(r.EphysTable.Stage==1 & r.EphysTable.Outcome=="Correct");
            otherwise
                continue;
        end

        if n==1
            Stat.(Events(i)+"_p") = zeros(n_units, 1);
            Stat.(Events(i)+"_h") = false(n_units, 1);
            Stat.(Events(i)+"_dir") = zeros(n_units, 1);
        end

        pre = SpkRate.(Events(i)).Pre(id_trial,n);
        post = SpkRate.(Events(i)).Post(id_trial,n);

        p = signrank(pre, post);
        d = sign(median(post) - median(pre));

        Stat.(Events(i)+"_p")(n) = p;
        Stat.(Events(i)+"_h")(n) = p<thres;
        Stat.(Events(i)+"_dir")(n) = d;
    end
end

%% test ramping
for n = 1:n_units

    if n==1
        Stat.Ramp_p = zeros(n_units, 1);
        Stat.Ramp_h = false(n_units, 1);
        Stat.Ramp_dir = zeros(n_units, 1);
    end

    id_trial = find(r.EphysTable.Stage==1 & r.EphysTable.Outcome=="Correct");

    early = SpkRate.CentIn.Post(id_trial,n);
    late  = SpkRate.Trigger.Pre(id_trial,n);

    p = signrank(early, late);
    d = sign(mean(late) - mean(early));

    Stat.Ramp_p(n) = p;
    Stat.Ramp_h(n) = p<thres;
    Stat.Ramp_dir(n) = d;
end

%% test side
for n = 1:n_units
    id_contra = find(r.EphysTable.Stage==1 & r.EphysTable.Outcome=="Correct" & r.EphysTable.PortCorrect==1);
    id_ipsi   = find(r.EphysTable.Stage==1 & r.EphysTable.Outcome=="Correct" & r.EphysTable.PortCorrect==2);

    % Hold
    if n==1
        Stat.SideHold_p = zeros(n_units, 1);
        Stat.SideHold_h = false(n_units, 1);
        Stat.SideHold_dir = zeros(n_units, 1);
    end

    contra = SpkRate.Trigger.Pre(id_contra, n);
    ipsi   = SpkRate.Trigger.Pre(id_ipsi, n);

    p = ranksum(contra, ipsi);
    d = sign(mean(contra) - mean(ipsi));

    Stat.SideHold_p(n) = p;
    Stat.SideHold_h(n) = p<thres;
    Stat.SideHold_dir(n) = d;

    % Response
    if n==1
        Stat.SideTrigger_p = zeros(n_units, 1);
        Stat.SideTrigger_h = false(n_units, 1);
        Stat.SideTrigger_dir = zeros(n_units, 1);
    end

    contra = SpkRate.Trigger.Post(id_contra, n);
    ipsi   = SpkRate.Trigger.Post(id_ipsi, n);

    p = ranksum(contra, ipsi);
    d = sign(mean(contra) - mean(ipsi));

    Stat.SideTrigger_p(n) = p;
    Stat.SideTrigger_h(n) = p<thres;
    Stat.SideTrigger_dir(n) = d;

    % Turn
    if n==1
        Stat.SideTurn_p = zeros(n_units, 1);
        Stat.SideTurn_h = false(n_units, 1);
        Stat.SideTurn_dir = zeros(n_units, 1);
    end

    contra = SpkRate.CentOut.Post(id_contra, n);
    ipsi   = SpkRate.CentOut.Post(id_ipsi, n);

    p = ranksum(contra, ipsi);
    d = sign(mean(contra) - mean(ipsi));

    Stat.SideTurn_p(n) = p;
    Stat.SideTurn_h(n) = p<thres;
    Stat.SideTurn_dir(n) = d;

    % Reward
    if n==1
        Stat.SideReward_p = zeros(n_units, 1);
        Stat.SideReward_h = false(n_units, 1);
        Stat.SideReward_dir = zeros(n_units, 1);
    end

    contra = SpkRate.Choice.Pre(id_contra, n);
    ipsi   = SpkRate.Choice.Pre(id_ipsi, n);

    p = ranksum(contra, ipsi);
    d = sign(mean(contra) - mean(ipsi));

    Stat.SideReward_p(n) = p;
    Stat.SideReward_h(n) = p<thres;
    Stat.SideReward_dir(n) = d;

end

%
Stat = struct2table(Stat);


%%
vars = Stat.Properties.VariableNames;
for i = 1:length(vars)
    if strcmp(vars{i}(end-1:end), '_p')
        i_event = vars{i}(1:end-2);

        p_vals = Stat.(vars{i});
        p_critic = BH_method(p_vals, thres);

        Stat.([i_event '_h']) = Stat.(vars{i}) < p_critic;
        fprintf('\n%s - %.1f%%', i_event, 100*sum(Stat.([i_event '_h']))/n_units);
    end
end
fprintf('\n');

stat_file = sprintf('Stat_%s_%s', r.BehaviorClass.Subject, r.BehaviorClass.Session);
save(stat_file, 'Stat');

