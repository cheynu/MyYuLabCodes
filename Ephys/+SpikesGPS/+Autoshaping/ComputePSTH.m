function PSTH = ComputePSTH(r, PSTHOut, ku, varargin)

% Jianing Yu 5/8/2023
% For plotting PSTHs under SRT condition.
% Extracted from SRTSpikes

% Modified by Yue Huang on 6/26/2023
% Change the way of making raster plots to run faster

% 5/21/2025
% Revised from ComputePlotPSTH.m
% Remove plot part

% close all;
PSTH.UnitID = ku;
PSTH.ANM_Session = PSTHOut.ANM_Session;

CentInTimeDomain  = PSTHOut.TimeDomain.CentIn;
CentOutTimeDomain = PSTHOut.TimeDomain.CentOut;
ChoiceTimeDomain  = PSTHOut.TimeDomain.Choice;
InitInTimeDomain  = PSTHOut.TimeDomain.InitIn;
InitOutTimeDomain = PSTHOut.TimeDomain.InitOut;

Ports    = r.BehaviorClass.LeftRight;
NumPorts = length(Ports);

%% PSTHs for CentIn, CentOut and Choice
PSTH.CentInLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDur', 'MovementTime', 'ChoiceTime'};

params_cent_in.pre      = 5000; % take a longer pre-press activity so we can compute z score easily later.
params_cent_in.post     = CentInTimeDomain(2);
params_cent_in.binwidth = 20;

t_cent_in = PSTHOut.CentIn.Time{end};
hd_cent_in = PSTHOut.CentIn.Time{end};
mt_cent_in = PSTHOut.CentIn.Time{end};
ct_cent_in = PSTHOut.CentIn.Time{end};
[psth_cent_in_all, ts_cent_in_all, trialspxmat_cent_in_all, tspkmat_cent_in_all, t_correct_cent_in_all, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_cent_in, params_cent_in);
psth_cent_in_all = smoothdata(psth_cent_in_all, 'gaussian', 5);

hd_cent_in = hd_cent_in(ind);
mt_cent_in = mt_cent_in(ind);
ct_cent_in = ct_cent_in(ind);

PSTH.CentInAll = {psth_cent_in_all, ts_cent_in_all, trialspxmat_cent_in_all, tspkmat_cent_in_all, t_correct_cent_in_all, hd_cent_in, mt_cent_in, ct_cent_in};

% CentIn PSTH
% Correct, sorted
params_cent_in.pre      = CentInTimeDomain(1);
params_cent_in.post     = CentInTimeDomain(2);
params_cent_in.binwidth = 20;

t_cent_in_correct           = cell(1, NumPorts);
psth_cent_in_correct        = cell(1, NumPorts);
ts_cent_in_correct          = cell(1, NumPorts);
trialspxmat_cent_in_correct = cell(1, NumPorts);
tspkmat_cent_in_correct     = cell(1, NumPorts);
hd_cent_in_correct_sorted   = cell(1, NumPorts);
mt_cent_in_correct_sorted   = cell(1, NumPorts);
ct_cent_in_correct_sorted   = cell(1, NumPorts);

ind_correct = PSTHOut.CentIn.Labels=="Correct";
for j = 1:NumPorts
    t_j = PSTHOut.CentIn.Time{ind_correct}{j};
    [psth_cent_in_correct{j}, ts_cent_in_correct{j}, trialspxmat_cent_in_correct{j}, tspkmat_cent_in_correct{j}, t_cent_in_correct{j}, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_j, params_cent_in);
    psth_cent_in_correct{j} = smoothdata(psth_cent_in_correct{j}, 'gaussian', 5);

    hd_cent_in_correct_sorted{j} = PSTHOut.CentIn.HoldDur{ind_correct}{j};
    hd_cent_in_correct_sorted{j} = hd_cent_in_correct_sorted{j}(ind);

    mt_cent_in_correct_sorted{j} = PSTHOut.CentIn.MovementTime{ind_correct}{j};
    mt_cent_in_correct_sorted{j} = mt_cent_in_correct_sorted{j}(ind);

    ct_cent_in_correct_sorted{j} = PSTHOut.CentIn.ChoiceTime{ind_correct}{j};
    ct_cent_in_correct_sorted{j} = ct_cent_in_correct_sorted{j}(ind);

    PSTH.CentIn.Correct{j} = {psth_cent_in_correct{j}, ts_cent_in_correct{j}, trialspxmat_cent_in_correct{j}, tspkmat_cent_in_correct{j}, t_cent_in_correct{j}, hd_cent_in_correct_sorted{j}, mt_cent_in_correct_sorted{j}, ct_cent_in_correct_sorted{j}};
end

% Wrong, sorted
params_cent_in.pre      = CentInTimeDomain(1);
params_cent_in.post     = CentInTimeDomain(2);
params_cent_in.binwidth = 20;

t_cent_in_wrong           = cell(1, NumPorts);
psth_cent_in_wrong        = cell(1, NumPorts);
ts_cent_in_wrong          = cell(1, NumPorts);
trialspxmat_cent_in_wrong = cell(1, NumPorts);
tspkmat_cent_in_wrong     = cell(1, NumPorts);
hd_cent_in_wrong_sorted   = cell(1, NumPorts);
mt_cent_in_wrong_sorted   = cell(1, NumPorts);
ct_cent_in_wrong_sorted   = cell(1, NumPorts);

ind_wrong = PSTHOut.CentIn.Labels=="Wrong";
for j = 1:NumPorts
    t_j = PSTHOut.CentIn.Time{ind_wrong}{j};
    [psth_cent_in_wrong{j}, ts_cent_in_wrong{j}, trialspxmat_cent_in_wrong{j}, tspkmat_cent_in_wrong{j}, t_cent_in_wrong{j}, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_j, params_cent_in);
    psth_cent_in_wrong{j} = smoothdata(psth_cent_in_wrong{j}, 'gaussian', 5);

    hd_cent_in_wrong_sorted{j} = PSTHOut.CentIn.HoldDur{ind_wrong}{j};
    hd_cent_in_wrong_sorted{j} = hd_cent_in_wrong_sorted{j}(ind);

    mt_cent_in_wrong_sorted{j} = PSTHOut.CentIn.MovementTime{ind_wrong}{j};
    mt_cent_in_wrong_sorted{j} = mt_cent_in_wrong_sorted{j}(ind);

    ct_cent_in_wrong_sorted{j} = PSTHOut.CentIn.ChoiceTime{ind_wrong}{j};
    ct_cent_in_wrong_sorted{j} = ct_cent_in_wrong_sorted{j}(ind);

    PSTH.CentIn.Wrong{j} = {psth_cent_in_wrong{j}, ts_cent_in_wrong{j}, trialspxmat_cent_in_wrong{j}, tspkmat_cent_in_wrong{j}, t_cent_in_wrong{j}, hd_cent_in_wrong_sorted{j}, mt_cent_in_wrong_sorted{j}, ct_cent_in_wrong_sorted{j}};
end

% CentOut PSTH
PSTH.CentOutLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDur', 'MovementTime', 'ChoiceTime'};
% Correct, sorted
params_cent_out.pre      = CentOutTimeDomain(1);
params_cent_out.post     = CentOutTimeDomain(2);
params_cent_out.binwidth = 20;

t_cent_out_correct           = cell(1, NumPorts);
psth_cent_out_correct        = cell(1, NumPorts);
ts_cent_out_correct          = cell(1, NumPorts);
trialspxmat_cent_out_correct = cell(1, NumPorts);
tspkmat_cent_out_correct     = cell(1, NumPorts);
hd_cent_out_correct_sorted   = cell(1, NumPorts);
mt_cent_out_correct_sorted   = cell(1, NumPorts);
ct_cent_out_correct_sorted   = cell(1, NumPorts);

ind_correct = PSTHOut.CentOut.Labels=="Correct";
for j = 1:NumPorts
    t_j = PSTHOut.CentOut.Time{ind_correct}{j};
    [psth_cent_out_correct{j}, ts_cent_out_correct{j}, trialspxmat_cent_out_correct{j}, tspkmat_cent_out_correct{j}, t_cent_out_correct{j}, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_j, params_cent_out);
    psth_cent_out_correct{j} = smoothdata(psth_cent_out_correct{j}, 'gaussian', 5);

    hd_cent_out_correct_sorted{j} = PSTHOut.CentOut.HoldDur{ind_correct}{j};
    hd_cent_out_correct_sorted{j} = hd_cent_out_correct_sorted{j}(ind);

    mt_cent_out_correct_sorted{j} = PSTHOut.CentOut.MovementTime{ind_correct}{j};
    mt_cent_out_correct_sorted{j} = mt_cent_out_correct_sorted{j}(ind);

    ct_cent_out_correct_sorted{j} = PSTHOut.CentOut.ChoiceTime{ind_correct}{j};
    ct_cent_out_correct_sorted{j} = ct_cent_out_correct_sorted{j}(ind);

    PSTH.CentOut.Correct{j} = {psth_cent_out_correct{j}, ts_cent_out_correct{j}, trialspxmat_cent_out_correct{j}, tspkmat_cent_out_correct{j}, t_cent_out_correct{j}, hd_cent_out_correct_sorted{j}, mt_cent_out_correct_sorted{j}, ct_cent_out_correct_sorted{j}};
end

% Wrong, sorted
params_cent_out.pre      = CentInTimeDomain(1);
params_cent_out.post     = CentInTimeDomain(2);
params_cent_out.binwidth = 20;

t_cent_out_wrong           = cell(1, NumPorts);
psth_cent_out_wrong        = cell(1, NumPorts);
ts_cent_out_wrong          = cell(1, NumPorts);
trialspxmat_cent_out_wrong = cell(1, NumPorts);
tspkmat_cent_out_wrong     = cell(1, NumPorts);
hd_cent_out_wrong_sorted   = cell(1, NumPorts);
mt_cent_out_wrong_sorted   = cell(1, NumPorts);
ct_cent_out_wrong_sorted   = cell(1, NumPorts);

ind_wrong = PSTHOut.CentOut.Labels=="Wrong";
for j = 1:NumPorts
    t_j = PSTHOut.CentOut.Time{ind_wrong}{j};
    [psth_cent_out_wrong{j}, ts_cent_out_wrong{j}, trialspxmat_cent_out_wrong{j}, tspkmat_cent_out_wrong{j}, t_cent_out_wrong{j}, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_j, params_cent_out);
    psth_cent_out_wrong{j} = smoothdata(psth_cent_out_wrong{j}, 'gaussian', 5);

    hd_cent_out_wrong_sorted{j} = PSTHOut.CentOut.HoldDur{ind_wrong}{j};
    hd_cent_out_wrong_sorted{j} = hd_cent_out_wrong_sorted{j}(ind);

    mt_cent_out_wrong_sorted{j} = PSTHOut.CentOut.MovementTime{ind_wrong}{j};
    mt_cent_out_wrong_sorted{j} = mt_cent_out_wrong_sorted{j}(ind);

    ct_cent_out_wrong_sorted{j} = PSTHOut.CentOut.ChoiceTime{ind_wrong}{j};
    ct_cent_out_wrong_sorted{j} = ct_cent_out_wrong_sorted{j}(ind);

    PSTH.CentOut.Wrong{j} = {psth_cent_out_wrong{j}, ts_cent_out_wrong{j}, trialspxmat_cent_out_wrong{j}, tspkmat_cent_out_wrong{j}, t_cent_out_wrong{j}, hd_cent_out_wrong_sorted{j}, mt_cent_out_wrong_sorted{j}, ct_cent_out_wrong_sorted{j}};
end

% Choice
PSTH.ChoiceLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'HoldDur', 'MovementTime', 'ChoiceTime'};
params_choice.pre      = ChoiceTimeDomain(1);
params_choice.post     = ChoiceTimeDomain(2);
params_choice.binwidth = 20;

% Correct, sorted
t_choice_correct           = cell(1, NumPorts);
psth_choice_correct        = cell(1, NumPorts);
ts_choice_correct          = cell(1, NumPorts);
trialspxmat_choice_correct = cell(1, NumPorts);
tspkmat_choice_correct     = cell(1, NumPorts);
hd_choice_correct_sorted   = cell(1, NumPorts);
mt_choice_correct_sorted   = cell(1, NumPorts);
ct_choice_correct_sorted   = cell(1, NumPorts);

ind_correct = PSTHOut.Choice.Labels=="Correct";
for j = 1:NumPorts
    t_j = PSTHOut.Choice.Time{ind_correct}{j};
    [psth_choice_correct{j}, ts_choice_correct{j}, trialspxmat_choice_correct{j}, tspkmat_choice_correct{j}, t_choice_correct{j}, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_j, params_choice);
    psth_choice_correct{j} = smoothdata(psth_choice_correct{j}, 'gaussian', 5);

    hd_choice_correct_sorted{j} = PSTHOut.CentIn.HoldDur{ind_correct}{j};
    hd_choice_correct_sorted{j} = hd_choice_correct_sorted{j}(ind);

    mt_choice_correct_sorted{j} = PSTHOut.CentIn.MovementTime{ind_correct}{j};
    mt_choice_correct_sorted{j} = mt_choice_correct_sorted{j}(ind);

    ct_choice_correct_sorted{j} = PSTHOut.CentIn.ChoiceTime{ind_correct}{j};
    ct_choice_correct_sorted{j} = ct_choice_correct_sorted{j}(ind);

    PSTH.Choice.Correct{j} = {psth_choice_correct{j}, ts_choice_correct{j}, trialspxmat_choice_correct{j}, tspkmat_choice_correct{j}, t_choice_correct{j}, hd_choice_correct_sorted{j}, mt_choice_correct_sorted{j}, ct_choice_correct_sorted{j}};
end

% Wrong, sorted
params_choice.pre      = CentInTimeDomain(1);
params_choice.post     = CentInTimeDomain(2);
params_choice.binwidth = 20;

t_choice_wrong           = cell(1, NumPorts);
psth_choice_wrong        = cell(1, NumPorts);
ts_choice_wrong          = cell(1, NumPorts);
trialspxmat_choice_wrong = cell(1, NumPorts);
tspkmat_choice_wrong     = cell(1, NumPorts);
hd_choice_wrong_sorted   = cell(1, NumPorts);
mt_choice_wrong_sorted   = cell(1, NumPorts);
ct_choice_wrong_sorted   = cell(1, NumPorts);

ind_wrong = PSTHOut.Choice.Labels=="Wrong";
for j = 1:NumPorts
    t_j = PSTHOut.Choice.Time{ind_wrong}{j};
    [psth_choice_wrong{j}, ts_choice_wrong{j}, trialspxmat_choice_wrong{j}, tspkmat_choice_wrong{j}, t_choice_wrong{j}, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_j, params_choice);
    psth_choice_wrong{j} = smoothdata(psth_choice_wrong{j}, 'gaussian', 5);

    hd_choice_wrong_sorted{j} = PSTHOut.CentIn.HoldDur{ind_wrong}{j};
    hd_choice_wrong_sorted{j} = hd_choice_wrong_sorted{j}(ind);

    mt_choice_wrong_sorted{j} = PSTHOut.CentIn.MovementTime{ind_wrong}{j};
    mt_choice_wrong_sorted{j} = mt_choice_wrong_sorted{j}(ind);

    ct_choice_wrong_sorted{j} = PSTHOut.CentIn.ChoiceTime{ind_wrong}{j};
    ct_choice_wrong_sorted{j} = ct_choice_wrong_sorted{j}(ind);

    PSTH.Choice.Wrong{j} = {psth_choice_wrong{j}, ts_choice_wrong{j}, trialspxmat_choice_wrong{j}, tspkmat_choice_wrong{j}, t_choice_wrong{j}, hd_choice_wrong_sorted{j}, mt_choice_wrong_sorted{j}, ct_choice_wrong_sorted{j}};
end

%% PSTH for init-in and init-out
% Init-In
params_initin.pre  = InitInTimeDomain(1);
params_initin.post = InitInTimeDomain(2);
params_initin.binwidth = 20;

PSTH.InitInLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'ShuttleTime', 'InitDur'};

% Init-In pre-correct
t_cor = PSTHOut.InitIn.PreCor.Time;
[psth_cor_initin, ts_cor_initin, trialspxmat_cor_initin, tspkmat_cor_initin, t_cor_initin, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_cor, params_initin);
psth_cor_initin = smoothdata(psth_cor_initin, 'gaussian', 5);

st_cor_initin  = PSTHOut.InitIn.PreCor.ShuttleTime(ind);
dur_cor_initin = PSTHOut.InitIn.PreCor.InitDur(ind);
PSTH.PreCorrectInitIn = {psth_cor_initin, ts_cor_initin, trialspxmat_cor_initin, tspkmat_cor_initin, t_cor_initin, st_cor_initin, dur_cor_initin};

% Init-In pre-error
t_err = PSTHOut.InitIn.PreErr.Time;
[psth_err_initin, ts_err_initin, trialspxmat_err_initin, tspkmat_err_initin, t_err_initin, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_err, params_initin);
psth_err_initin = smoothdata(psth_err_initin, 'gaussian', 5);

st_err_initin  = PSTHOut.InitIn.PreErr.ShuttleTime(ind);
dur_err_initin = PSTHOut.InitIn.PreErr.InitDur(ind);
PSTH.PreErrorInitIn = {psth_err_initin, ts_err_initin, trialspxmat_err_initin, tspkmat_err_initin, t_err_initin, st_err_initin, dur_err_initin};

% Init-Out
params_initout.pre  = InitOutTimeDomain(1);
params_initout.post = InitOutTimeDomain(2);
params_initout.binwidth = 20;

PSTH.InitOutLabels = {'PSTH', 'tPSTH', 'SpikeMat', 'tSpikeMat', 'tEvents', 'ShuttleTime', 'InitDur'};

% Init-Out pre-correct
t_cor = PSTHOut.InitOut.PreCor.Time;
[psth_cor_initout, ts_cor_initout, trialspxmat_cor_initout, tspkmat_cor_initout, t_cor_initout, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_cor, params_initout);
psth_cor_initout = smoothdata(psth_cor_initout, 'gaussian', 5);

st_cor_initout  = PSTHOut.InitOut.PreCor.ShuttleTime(ind);
dur_cor_initout = PSTHOut.InitOut.PreCor.InitDur(ind);
PSTH.PreCorrectInitOut = {psth_cor_initout, ts_cor_initout, trialspxmat_cor_initout, tspkmat_cor_initout, t_cor_initout, st_cor_initout, dur_cor_initout};

% Init-Out pre-error
t_err = PSTHOut.InitOut.PreErr.Time;
[psth_err_initout, ts_err_initout, trialspxmat_err_initout, tspkmat_err_initout, t_err_initout, ind] = jpsth(r.Units.SpikeTimes(ku).timings, t_err, params_initout);
psth_err_initout = smoothdata(psth_err_initout, 'gaussian', 5);

st_err_initout  = PSTHOut.InitOut.PreErr.ShuttleTime(ind);
dur_err_initout = PSTHOut.InitOut.PreErr.InitDur(ind);
PSTH.PreErrorInitOut = {psth_err_initout, ts_err_initout, trialspxmat_err_initout, tspkmat_err_initout, t_err_initout, st_err_initout, dur_err_initout};

end